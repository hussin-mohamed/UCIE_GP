// ****************************************************************************
// *                                                                          *
// * Copyright (c) 2014-2015 Synopsys Inc. All rights reserved.               *
// *                                                                          *
// * Synopsys Proprietary and Confidential. This file contains confidential   *
// * information and the trade secrets of Synopsys Inc. Use, disclosure, or   *
// * reproduction is prohibited without the prior express written permission  *
// * of Synopsys, Inc.                                                        *
// *                                                                          *
// * Synopsys, Inc.                                                           *
// * 700 East Middlefield Road                                                *
// * Mountain View, California 94043                                          *
// * (800) 541-7737                                                           *
// *                                                                          *
// ****************************************************************************

`uvm_analysis_imp_decl(_rmblink)
`uvm_analysis_imp_decl(_ltsmc)

//---------------------------------------------------------------------------
//
// CLASS: rp_pred
//
// Predictor for the LTSM-to-link direction. It tracks state encodings and 
// uses behavioral models of the RX-Path (LFSR, Per-Lane ID, Lane-to-Byte) 
// to generate expected transactions for the comparators.
//
//---------------------------------------------------------------------------

class rp_pred extends uvm_component;
  `uvm_component_utils(rp_pred)

  // ------------------------------------------------------------------------
  // Ports and Exports
  // ------------------------------------------------------------------------
  uvm_analysis_imp_rmblink #(rmblink_seq_item, rp_pred) axp_in_rmblink;
  uvm_analysis_imp_ltsmc   #(ltsmc_seq_item, rp_pred)   axp_in_ltsmc;
  uvm_analysis_port        #(rdi_seq_item)              results_ap_rdi;
  uvm_analysis_port        #(ltsmc_seq_item)            results_ap_ltsmc;

  // ------------------------------------------------------------------------
  // Architectural Parameters
  // ------------------------------------------------------------------------
  localparam int pNUM_LANES  = 16;
  localparam int pDATA_WIDTH = 64;
  localparam int pNBYTES     = 256;
  localparam int pLFSR_TAPS  = 23;

  // ------------------------------------------------------------------------
  // Internal State & Block Variables
  // ------------------------------------------------------------------------
  int per_lane_pat_cnt [pNUM_LANES];
  int per_lane_iter_cnt;

  int l2b_iter_cnt;
  logic [pNBYTES-1:0][7:0] rdi_data_buffer;
  logic success_arr [pNUM_LANES];
  
  logic [pLFSR_TAPS-1:0] lfsr_state [pNUM_LANES-1:0];
  logic [pLFSR_TAPS-1:0] lfsr_last_state [pNUM_LANES-1:0];
  int lane_error_count [pNUM_LANES-1:0];
  logic expected_bit;
  int lfsr_train_iter_cnt;

  logic [pLFSR_TAPS-1:0] LANE_ID [0:7] = '{
    23'h1DBFBC, // Lanes 0,8
    23'h0607BB, // Lanes 1,9
    23'h1EC760, // Lanes 2,10
    23'h18C0DB, // Lanes 3,11
    23'h010F12, // Lanes 4,12
    23'h19CFC9, // Lanes 5,13
    23'h0277CE, // Lanes 6,14
    23'h1BB807  // Lanes 7,15
  };

  // Predictor Cache Memory
  rx_encoding_t     current_rx_encoding, t_rx_encoding;
  rx_encoding_t     previous_rx_encoding;
  lane_map_code_t   current_lane_map_code;
  logic [15:0]      current_error_threshold;

  bit is_d2c_PerLaneID_train_state, is_d2c_valid_train_state;

  // ------------------------------------------------------------------------
  // Constructor
  // ------------------------------------------------------------------------
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  // ------------------------------------------------------------------------
  // UVM Phases
  // ------------------------------------------------------------------------
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    axp_in_rmblink   = new("axp_in_rmblink", this);
    axp_in_ltsmc     = new("axp_in_ltsmc", this);
    results_ap_rdi   = new("results_ap_rdi", this);
    results_ap_ltsmc = new("results_ap_ltsmc", this);
  endfunction : build_phase

  virtual task pre_reset_phase(uvm_phase phase);
    super.pre_reset_phase(phase);
    
    // Clear all tracking logic variables upon system reset
    l2b_iter_cnt = 0;
    per_lane_iter_cnt = 0;
    lfsr_train_iter_cnt = 0;
    expected_bit = 1'b0;
    
    current_rx_encoding = RESET_Reset;
    previous_rx_encoding = RESET_Reset;
    current_error_threshold = 16'h0;
    rdi_data_buffer = '{default: 8'h0};
    
    for (int i = 0; i < pNUM_LANES; i++) begin
      per_lane_pat_cnt[i] = 0;
      lfsr_state[i] = 23'h0;
      lfsr_last_state[i] = 23'h0;
      lane_error_count[i] = 0;
    end
  endtask : pre_reset_phase

  // ------------------------------------------------------------------------
  // Export Implementations
  // ------------------------------------------------------------------------
  virtual function void write_ltsmc(ltsmc_seq_item t);
    ltsmc_seq_item out_item;

    t_rx_encoding = t.rx_encoding;


    // 1. Exclude Clock/Track/Valid Training States entirely
    if ((t.rx_encoding >= MBINIT_REPAIRCLK_RX_Init_Handshake && t.rx_encoding <= MBINIT_REPAIRCLK_RX_Done_Handshake) ||
        (t.rx_encoding >= MBINIT_REPAIRVAL_RX_Init_Handshake && t.rx_encoding <= MBINIT_REPAIRVAL_RX_Done_Handshake)) begin
      `uvm_info("PRD", "Discarding MBINIT.REPAIRCLK/MBINIT.REPAIRVAL input LTSM transaction. Fully modelled via SVAs.", UVM_DEBUG)
      return;
    end

    $display("%0t: t.rx_encoding        = %s", $time, t.rx_encoding.name());
    $display("%0t: previous_rx_encoding = %s", $time, previous_rx_encoding.name());

    

    if (is_d2c_valid_train_state) begin
      if (t.rx_encoding == Data_To_Clock_test_RX_LFSR_Clear_Handshake_RX_Init ||
          t.rx_encoding == Data_To_Clock_test_RX_Pattern_Detection_RX_Init) begin
        return;
      end
      if (t.rx_encoding == Data_To_Clock_test_RX_Result_Handshake_RX_Init) begin
        is_d2c_valid_train_state = 0;
        return;
      end
    end

    if (t.rx_encoding == RESET_Reset) begin
      // Clear all tracking logic variables upon system reset
      l2b_iter_cnt = 0;
      per_lane_iter_cnt = 0;
      lfsr_train_iter_cnt = 0;
      expected_bit = 1'b0;
      
      current_rx_encoding = RESET_Reset;
      previous_rx_encoding = RESET_Reset;
      current_error_threshold = 16'h0;
      rdi_data_buffer = '{default: 8'h0};
      
      for (int i = 0; i < pNUM_LANES; i++) begin
        per_lane_pat_cnt[i] = 0;
        lfsr_state[i] = 23'h0;
        lfsr_last_state[i] = 23'h0;
        lane_error_count[i] = 0;
      end
      return;
    end

    // 2. Cache State Configurations
    if (current_rx_encoding != t.rx_encoding) begin
      previous_rx_encoding = current_rx_encoding;
    end
    
    current_rx_encoding = t.rx_encoding;
    current_lane_map_code = t.lane_map_code;

    // Only update error threshold on INIT handshake
    if (t.rx_encoding == Data_To_Clock_test_RX_INIT_Handshake_TX_Init ||
        t.rx_encoding == Data_To_Clock_test_RX_INIT_Handshake_RX_Init) begin
      current_error_threshold = t.error_threshold;
    end

    // 3. Process LFSR Load Control States internally since link is idle
    if (t.rx_encoding == Data_To_Clock_test_RX_LFSR_Clear_Handshake_TX_Init || 
        t.rx_encoding == Data_To_Clock_test_RX_LFSR_Clear_Handshake_RX_Init ||
        t.rx_encoding == LINKINIT_RX_PL_Clk_Req_Handshake) begin
      
      logic [pDATA_WIDTH-1:0] dummy_data    [pNUM_LANES-1:0];
      logic                   dummy_success [pNUM_LANES-1:0];
      logic [pDATA_WIDTH-1:0] dummy_out     [pNUM_LANES-1:0];

      dummy_data = '{default: 64'h0};
      rx_lfsr(1'b0, 1'b1, dummy_data, current_error_threshold, dummy_success, dummy_out);
    end

    if (t.rx_encoding == Data_To_Clock_test_RX_INIT_Handshake_RX_Init &&
          (
            previous_rx_encoding == MBTRAIN_VALVREF_RX_Start_Handshake        ||  
            previous_rx_encoding == MBTRAIN_VALTRAINCENTER_RX_Start_Handshake ||
            previous_rx_encoding == MBTRAIN_VALTRAINVREF_RX_Start_Handshake
          )
    ) begin
      is_d2c_valid_train_state = 1;
      return;
    end

    // ========================================================================
    // Emit Predicted LTSMC Item in the Result Handshake States
    // ========================================================================
    if (t.rx_encoding == Data_To_Clock_test_RX_Result_Handshake_TX_Init  ||
        t.rx_encoding == Data_To_Clock_test_RX_Result_Handshake_RX_Init  ||
        t.rx_encoding == MBINIT_REVERSAL_RX_Result_Handshake) begin
      
      logic [pNUM_LANES-1:0] packed_success; // Intermediate packed vector
      
      // Fix SV Unpacked-to-Packed Conversion
      foreach (success_arr[i]) begin
        packed_success[i] = success_arr[i];
      end

      out_item = ltsmc_seq_item::type_id::create("out_item");
      out_item.lane_map_code = current_lane_map_code;
      out_item.rx_encoding = current_rx_encoding;
      out_item.error_threshold = current_error_threshold;
      out_item.half_rate = 1;
      
      // Now concatenation works perfectly
      out_item.rx_data_results = { {48{1'b1}}, packed_success };
      results_ap_ltsmc.write(out_item);
      
      // Reset tracking vars for next sequence
      lfsr_train_iter_cnt = 0; 
      per_lane_iter_cnt = 0;

      if (is_d2c_PerLaneID_train_state) begin
        is_d2c_PerLaneID_train_state = 0;
      end
    end

    if (current_rx_encoding  == Data_To_Clock_test_RX_INIT_Handshake_TX_Init && 
        previous_rx_encoding == MBINIT_REPAIRMB_RX_Init_Handshake) begin
      is_d2c_PerLaneID_train_state = 1;
    end
    
    `uvm_info("PRDDDDD", $sformatf("current state is %s", current_rx_encoding.name()), UVM_LOW) 
    `uvm_info("PRDDDDD", $sformatf("previous state is %s", previous_rx_encoding.name()), UVM_LOW) 
  endfunction : write_ltsmc

  virtual function void write_rmblink(rmblink_seq_item t);
    logic [(pDATA_WIDTH/16)-1:0][15:0] lanes [pNUM_LANES];
    
    logic [(pDATA_WIDTH/8)-1:0][7:0]   l2b_lanes [pNUM_LANES];
    logic [pDATA_WIDTH-1:0]            lfsr_out_data [pNUM_LANES-1:0];


    // ========================================================================
    // PER-LANE ID PATTERN DETECTION
    // ========================================================================
    if (current_rx_encoding == MBINIT_REVERSAL_RX_Per_Lane_ID_Det ||
       (current_rx_encoding == Data_To_Clock_test_RX_Pattern_Detection_TX_Init  && 
        is_d2c_PerLaneID_train_state)) begin

      // Repack array for 16-bit blocks
      for (int i = 0; i < pNUM_LANES; i++) begin
        for (int j = 0; j < pDATA_WIDTH/16; j++) begin
          lanes[i][j] = t.data[i][j*16 +: 16];
        end
      end

      get_per_lane_id_results(lanes, current_lane_map_code, success_arr);
    end 
    
    // ========================================================================
    // LFSR PATTERN DETECTION
    // ========================================================================
    else if ((current_rx_encoding == Data_To_Clock_test_RX_Pattern_Detection_TX_Init || 
              current_rx_encoding == Data_To_Clock_test_RX_Pattern_Detection_RX_Init) &&
             !is_d2c_PerLaneID_train_state) begin
      rx_lfsr(1'b1, 1'b0, t.data, current_error_threshold, success_arr, lfsr_out_data);
    end
    
    // ========================================================================
    // ACTIVE DATA DESCRAMBLING & LANE-TO-BYTE MAPPING
    // ========================================================================
    else if (current_rx_encoding == ACTIVE_RX_Active) begin
      
      // Descramble
      rx_lfsr(1'b0, 1'b0, t.data, current_error_threshold, success_arr, lfsr_out_data);

      // Repack 8-bit blocks for Lane2Byte mapper
      for (int i = 0; i < pNUM_LANES; i++) begin
        for (int j = 0; j < pDATA_WIDTH/8; j++) begin
          l2b_lanes[i][j] = lfsr_out_data[i][j*8 +: 8];
        end
      end

      lane2byte(l2b_lanes, current_lane_map_code, rdi_data_buffer);

      // Emit RDI item once 256 bytes are fully assembled
      if (l2b_iter_cnt == 0) begin
        rdi_seq_item rdi_item = rdi_seq_item::type_id::create("rdi_item");
        rdi_item.data = rdi_data_buffer;
        results_ap_rdi.write(rdi_item);
      end
    end
  endfunction : write_rmblink

  // ------------------------------------------------------------------------
  // Extracted Block Models
  // ------------------------------------------------------------------------
  
  function void get_per_lane_id_results(
      input  logic [(pDATA_WIDTH/16)-1:0][15:0] _lanes [pNUM_LANES],
      input  logic [2:0]                        _lane_map_code,
      output logic                              _lanes_success [pNUM_LANES]
  );
    int start_lane;
    int num_active_lanes;

    for (int i = 0; i < pNUM_LANES; i++) begin
      _lanes_success[i] = 1'b0;
    end

    case (_lane_map_code)
      3'b001: begin start_lane = 0; num_active_lanes = 8;  end // x8 lower
      3'b010: begin start_lane = 8; num_active_lanes = 8;  end // x8 upper
      3'b011: begin start_lane = 0; num_active_lanes = 16; end // x16 
      3'b100: begin start_lane = 0; num_active_lanes = 4;  end // x4 lower
      3'b101: begin start_lane = 4; num_active_lanes = 4;  end // x4 upper
      default: `uvm_fatal("PRD_PERLANE", $sformatf("Unsupported lane_map_code: %0b", _lane_map_code))
    endcase


    for (int lane_idx = start_lane; lane_idx < (start_lane + num_active_lanes); lane_idx++) begin
      for (int pat_idx = 0; pat_idx < pDATA_WIDTH/16; pat_idx++) begin
        logic [15:0] expected = {4'b1010, 8'(lane_idx), 4'b1010};
        if (_lanes[lane_idx][pat_idx] == expected) begin
          per_lane_pat_cnt[lane_idx]++;
        end else begin
          per_lane_pat_cnt[lane_idx] = 0;
        end
      end
    end

    foreach (per_lane_pat_cnt[lane_idx]) begin
      if (per_lane_pat_cnt[lane_idx] >= 16) begin
        _lanes_success[lane_idx] = 1;
      end else begin
        _lanes_success[lane_idx] = 0;
      end
    end

    // Debugging the counter logic
    if (per_lane_iter_cnt == ((128*16)/(pDATA_WIDTH))) begin
      per_lane_iter_cnt = 0;
    end else begin
      per_lane_iter_cnt++;
    end

    for (int i = 0; i < pNUM_LANES; i++) begin
      if (i < start_lane || i >= (start_lane + num_active_lanes)) begin
        _lanes_success[i] = 1'b1;
      end
    end
  endfunction : get_per_lane_id_results

  function void lane2byte(
     input  logic [(pDATA_WIDTH/8)-1:0][7:0] _lanes [pNUM_LANES],
     input  logic [2:0]                      _lane_map_code,
     ref    logic [pNBYTES-1:0][7:0]         _data
  );
    int data_byte_idx;
    int lane_byte_idx;
    int lane_idx;
    int start_lane;
    int byte_step;
    int num_iter;

    case (_lane_map_code)
      3'b001: begin start_lane = 0; byte_step = 8;  end 
      3'b010: begin start_lane = 8; byte_step = 8;  end 
      3'b011: begin start_lane = 0; byte_step = 16; end 
      3'b100: begin start_lane = 0; byte_step = 4;  end 
      3'b101: begin start_lane = 4; byte_step = 4;  end 
      default: `uvm_fatal("PRD_L2B", $sformatf("Unsupported lane_map_code: %0b", _lane_map_code))
    endcase

    for (int norm_idx = 0; norm_idx < byte_step; norm_idx++) begin
      logic [(pDATA_WIDTH/8)-1:0][7:0] lane;
      lane_idx = start_lane + norm_idx;
      lane = _lanes[lane_idx];

      for (int l_byte_idx = 0; l_byte_idx < (pDATA_WIDTH/8); l_byte_idx++) begin
        data_byte_idx = byte_step*(8*l2b_iter_cnt + l_byte_idx) + norm_idx;
        _data[data_byte_idx] = lane[l_byte_idx];
      end
    end

    num_iter = (pNBYTES/(8*byte_step)) - 1;

    if (l2b_iter_cnt == num_iter) begin
      l2b_iter_cnt = 0;
    end else begin
      l2b_iter_cnt++;
    end
  endfunction : lane2byte

  function void load_lfsr_state(int _bit_index, ref logic [pDATA_WIDTH-1:0] _out_data [pNUM_LANES-1:0]);
    for (int i = 0; i < pNUM_LANES; i++) begin
      lfsr_state[i] = LANE_ID[i % 8];
      _out_data[i][_bit_index] = lfsr_state[i][pLFSR_TAPS-1];
    end
  endfunction : load_lfsr_state

  function void train_detection(
     input  logic [pDATA_WIDTH-1:0] _data [pNUM_LANES-1:0],
     input  int                     _error_threshold,
     input  int                     _bit_index,
     output logic                   _success [pNUM_LANES-1:0],
     ref    logic [pDATA_WIDTH-1:0] _out_data [pNUM_LANES-1:0]
  );
    for (int i = 0; i < pNUM_LANES; i++) begin
      expected_bit = lfsr_state[i][pLFSR_TAPS-1];
      _out_data[i][_bit_index] = lfsr_state[i][pLFSR_TAPS-1];
      if (_data[i][_bit_index] !== expected_bit) begin
        lane_error_count[i]++;
      end
      if (lane_error_count[i] > _error_threshold) begin
        _success[i] = 1'b0;
      end else begin
        _success[i] = 1'b1;
      end
    end
  endfunction : train_detection

  function void update_lfsr_state(input bit load);
    if (!load) begin
      foreach (lfsr_state[i,j]) begin
        if ((j == 2) || (j == 5) || (j == 8) || (j == 16) || (j == 21)) begin
          lfsr_state[i][j] = lfsr_last_state[i][j-1] ^ lfsr_last_state[i][pLFSR_TAPS-1];
        end else if (j == 0) begin
          lfsr_state[i][j] = lfsr_last_state[i][pLFSR_TAPS-1];
        end else begin
          lfsr_state[i][j] = lfsr_last_state[i][j-1];
        end
      end
    end
    lfsr_last_state = lfsr_state;
  endfunction : update_lfsr_state

  function void descramble_data(
     input  logic [pDATA_WIDTH-1:0] _data [pNUM_LANES-1:0],
     input  int                     _bit_index,
     ref    logic [pDATA_WIDTH-1:0] _out_data [pNUM_LANES-1:0]
  );
    for (int i = 0; i < pNUM_LANES; i++) begin
      _out_data[i][_bit_index] = _data[i][_bit_index] ^ lfsr_state[i][pLFSR_TAPS-1];
    end
  endfunction : descramble_data
  
  function void rx_lfsr(
     input  bit                     _train,
     input  bit                     _load,
     input  logic [pDATA_WIDTH-1:0] _data [pNUM_LANES-1:0],
     input  int                     _error_threshold,
     output logic                   _success [pNUM_LANES-1:0],
     output logic [pDATA_WIDTH-1:0] _out_data [pNUM_LANES-1:0]
  );
    _out_data = '{default: 64'h0}; // Prevent X-propagation logic bugs
    for (int bit_index = 0; bit_index < pDATA_WIDTH; bit_index++) begin
      if (_load) begin
        load_lfsr_state(bit_index, _out_data);
        lane_error_count = '{default: 0};
      end else if (_train) begin
        train_detection(_data, _error_threshold, bit_index, _success, _out_data);
      end else begin
        descramble_data(_data, bit_index, _out_data);
      end
      update_lfsr_state(_load);
    end  
  endfunction : rx_lfsr

endclass : rp_pred