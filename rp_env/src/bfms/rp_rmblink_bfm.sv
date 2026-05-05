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

`include "uvm_macros.svh"
import shared_pkg::*;
import uvm_pkg::*;


// Interface: rp_rmblink_bfm
// Description: Serial RX-Path communication interface with partner UCIe die
//              (RMBLINK - RX Mainband Link)
//******************************************************************************

interface rp_rmblink_bfm(
  input logic clk
 ,input logic i_hclk
 ,input logic i_dclk
 ,input logic reset
);

  logic                  i_clk_p;
  logic                  i_clk_n;
  logic                  i_track;
  logic [pNUM_LANES-1:0] i_data;
  logic                  i_valid;

  //============================================================================
  // Methods
  //============================================================================
  always @(posedge reset) begin
    i_clk_p <= 0;
    i_clk_n <= 1;
    i_track <= 0;
    i_data  <= 0;
    i_valid <= 0;
  end

  //============================================================================
  // Amr
  //============================================================================
  task serialize_data(
     input logic [pDATA_WIDTH-1:0] _data         [pNUM_LANES]
    ,input logic [7:0]             _val_stream   []
    ,input logic                   _clk_stream_p []
    ,input logic                   _clk_stream_n []
    ,input logic                   _track_stream []
    ,input int                     _idle_ui_cnt
  );
    bit [2:0] val_byte_idx, val_bit_idx;
    int val_num_bytes;

    val_num_bytes = pDATA_WIDTH / 8;
    
    if (_val_stream.size() != val_num_bytes) begin
      `uvm_fatal("RMBLINK_BFM", $sformatf("Invalid val_stream size: %0d, valid size must be: %0d", _val_stream.size(), val_num_bytes))
    end
    if (_clk_stream_p.size() != pDATA_WIDTH) begin
      `uvm_fatal("RMBLINK_BFM", $sformatf("Invalid clk_stream_p size: %0d, valid size must be: %0d", _clk_stream_p.size(), pDATA_WIDTH))
    end
    if (_clk_stream_n.size() != pDATA_WIDTH) begin
      `uvm_fatal("RMBLINK_BFM", $sformatf("Invalid clk_stream_n size: %0d, valid size must be: %0d", _clk_stream_n.size(), pDATA_WIDTH))
    end
    if (_track_stream.size() != pDATA_WIDTH) begin
      `uvm_fatal("RMBLINK_BFM", $sformatf("Invalid track_stream size: %0d, valid size must be: %0d", _track_stream.size(), pDATA_WIDTH))
    end

    // Iterate through each bit position (Time dimension)
    for (int dat_bit_idx = 0; dat_bit_idx < pDATA_WIDTH; dat_bit_idx++) begin
      
      @(posedge i_dclk);
      // At this specific time instant, iterate through all lanes (Space dimension)
      for (int lane_idx = 0; lane_idx < pNUM_LANES; lane_idx++) begin
        i_data[lane_idx] <= _data[lane_idx][dat_bit_idx];
      end
      val_byte_idx = dat_bit_idx / 8;
      i_valid      <= _val_stream[val_byte_idx][val_bit_idx];
      val_bit_idx++;

      @(negedge i_dclk);
      i_clk_p <= _clk_stream_p[dat_bit_idx];
      i_clk_n <= _clk_stream_n[dat_bit_idx];
      i_track <= _track_stream[dat_bit_idx];
    end

    // Deassert everything during the idle period
    @(negedge i_dclk);
    i_clk_p <= 1'b0;
    i_clk_n <= 1'b1;
    i_data  <= '0;
    i_valid <= 1'b0;
    
    // Wait for _idle_ui_cnt UI
    repeat(_idle_ui_cnt) @(posedge i_dclk);
  endtask : serialize_data

  task deserialize_data(
     output logic [pDATA_WIDTH-1:0] _data [pNUM_LANES]
    ,output logic [7:0]             _val_stream   []
  );
    bit [2:0] val_byte_idx, val_bit_idx;

    while (!i_valid) begin
      @(posedge i_clk_p);
    end

    _val_stream = new[pDATA_WIDTH/8];
    
    // Iterate through each bit position (Time dimension)
    for (int dat_bit_idx = 0; dat_bit_idx < pDATA_WIDTH; dat_bit_idx++) begin

      val_byte_idx = dat_bit_idx / 8;
        
      // At this specific time instant, iterate through all lanes (Space dimension)
      for (int lane_idx = 0; lane_idx < pNUM_LANES; lane_idx++) begin
        _data[lane_idx][dat_bit_idx] = i_data[lane_idx];
      end
      _val_stream[val_byte_idx][val_bit_idx] = i_valid;
      val_bit_idx++;
      
      if (dat_bit_idx == 63) begin
        break;
      end

      if (dat_bit_idx%2 == 0) begin
        @(posedge i_clk_n);
      end else begin
        @(posedge i_clk_p);
      end
    end
  endtask : deserialize_data

  //============================================================================
  // Araby
  //============================================================================
  task serialize_valid_pattern(
      input logic [7:0]                      _valid
     ,input logic                            _clk_stream_p []
     ,input logic                            _clk_stream_n []
     ,input pattern_type_t                   _pattern
  );
    if (_clk_stream_p.size() != _clk_stream_n.size()) begin
      `uvm_error("CLK_STREAM_SIZE_MISMATCH", "Clock stream arrays must be of the same size in serialize_valid_pattern.")
    end

    if (_clk_stream_p.size() != STREAM_LEN_HR_VALID_PAT || _clk_stream_n.size() != STREAM_LEN_HR_VALID_PAT) begin
        `uvm_error("CLK_STREAM_SIZE_HR", "Clock stream arrays must have exactly {STREAM_LEN_HR_VALID_PAT} elements for Half Rate (HR) mode in serialize_valid_pattern.")
    end

   if (_pattern != VAL_PATTERN) begin
      `uvm_error("INVALID_PATTERN_TYPE", "Pattern type must be VAL_PATTERN for serialize_valid_pattern.")
    end
    else begin
        `uvm_info("SERIALIZE_VALID_PATTERN", $sformatf("Serializing valid pattern with rate mode: %s, idle UI count: %0d, iteration count: %0d", (_rate == HR) ? "HR" : "QR", _idle_ui_cnt_val, _val_iter_cnt), UVM_MEDIUM)
      
      for (int t = 0; t < _val_iter_cnt; t++) begin
          for (int i = 0; i < _clk_stream_p.size(); i++) begin
            @(posedge i_dclk)
            i_clk_p    <= _clk_stream_p[i];
            i_clk_n    <= _clk_stream_n[i];
            i_valid    <= _valid[i];
          end
      end
    end
  endtask : serialize_valid_pattern

  task deserialize_valid_pattern(
      output logic [7:0]                      _valid
     ,input  int unsigned                     _val_iter_cnt;   
     ,input  pattern_type_t                   _pattern;        
  );

   if (_pattern != VAL_PATTERN) begin
      `uvm_error("INVALID_PATTERN_TYPE", "Pattern type must be VAL_PATTERN for deserialize_valid_pattern.")
    end
    else begin
        `uvm_info("DESERIALIZE_VALID_PATTERN", $sformatf("Deserializing valid pattern with rate mode: %s, idle UI count: %0d, iteration count: %0d", (_rate == HR) ? "HR" : "QR", _idle_ui_cnt_val, _val_iter_cnt), UVM_MEDIUM)
      
      for (int t = 0; t < _val_iter_cnt; t++) begin
          for (int i = 0; i < _clk_stream_p.size(); i++) begin
            @(posedge i_dclk)
            _valid[i]  = i_valid; // Capture valid bits from the clock stream
          end

          for (int j = 0; j < _idle_ui_cnt_val; j++) begin
            @(posedge i_dclk)
            i_clk_p[i] <= 0; // Drive idle (non-clock) for specified number of UIs
            i_clk_n[i] <= 0; // Drive idle (non-clock) for specified number of UIs
            i_valid <= 0; // Drive idle (non-valid) for specified number of UIs
          end
        end
    end
  endtask : deserialize_valid_pattern



  task serialize_clk_pattern(
     // ...
  );
    // ...
  endtask : serialize_clk_pattern
  

   task deserialize_clk_pattern(
     // ...
  );
    // ...
  endtask : deserialize_clk_pattern


endinterface : rp_rmblink_bfm
