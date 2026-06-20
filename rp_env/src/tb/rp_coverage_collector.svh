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
// * ****************************************************************************

`uvm_analysis_imp_decl(_rmblink_cg)
`uvm_analysis_imp_decl(_ltsm_cg)

//---------------------------------------------------------------------------
//
// CLASS: rp_coverage_collector
//
// Coverage collector for RX-Path verification traffic.
//
//---------------------------------------------------------------------------

class rp_coverage_collector extends uvm_component;
  `uvm_component_utils(rp_coverage_collector)

  uvm_analysis_imp_rmblink_cg #(rmblink_seq_item, rp_coverage_collector) rmblink_exp;
  uvm_analysis_imp_ltsm_cg    #(ltsmc_seq_item, rp_coverage_collector)   ltsm_exp;

  rmblink_seq_item rmblink_item;
  ltsmc_seq_item   ltsm_item;

  // High-level LTSM states for cleaner coverage transitions and crosses
  typedef enum {
    ST_RESET,
    ST_SBINIT,
    ST_PARAM,
    ST_CAL,
    ST_REPAIRCLK,
    ST_REPAIRVAL,
    ST_REVERSAL,
    ST_REPAIRMB,
    ST_TRAINERROR,
    ST_VALVREF,
    ST_DATAVREF,
    ST_DTC1,
    ST_RXCLKCAL,
    ST_VALTRAINCTR,
    ST_RXDESKEW,
    ST_DTC2,
    ST_LINKSPEED,
    ST_REPAIR,
    ST_SPEEDIDLE,
    ST_TXSELFCAL,
    ST_VALTRAINVREF,
    ST_DATATRAINVREF,
    ST_LINKINIT,
    ST_ACTIVE,
    ST_L1,
    ST_EXIT_HS,
    ST_D2C_TX,
    ST_D2C_RX
  } ltsm_state_e;

  // Tracking variables for coverage sampling
  rx_encoding_t          prev_encoding;
  rx_encoding_t          curr_encoding;
  lane_map_code_t        curr_lane_map;
  ltsm_state_e           curr_state;
  logic           [ 2:0] curr_clk_results;
  logic                  curr_valid_results;
  logic           [15:0] curr_data_results_16;

  //---------------------------------------------------------------------------
  //
  // COVERGROUP: cg_rmblink
  //
  //---------------------------------------------------------------------------
  covergroup cg_rmblink;
  // Empty for now
  endgroup : cg_rmblink

  //---------------------------------------------------------------------------
  //
  // COVERGROUP: cg_ltsm
  //
  //---------------------------------------------------------------------------
  covergroup cg_ltsm;

    // 1. All encoding values coverpoint
    cp_encoding: coverpoint curr_encoding {
      // Phase 00: Initialization
      bins reset = {RESET_Reset};
      bins sbinit[] = {SBINIT_RX_Wait_Out_Of_Reset, SBINIT_RX_Done_Handshake};
      bins param[] = {MBINIT_PARAM_RX_Wait_Config_REQ, MBINIT_PARAM_RX_Send_RESP};
      bins cal = {MBINIT_CAL_RX_Done_Handshake};
      bins repairclk[] = {MBINIT_REPAIRCLK_RX_Init_Handshake, MBINIT_REPAIRCLK_RX_Pattern_Detection,
                          MBINIT_REPAIRCLK_RX_Send_RESP,
                          MBINIT_REPAIRCLK_RX_Done_Handshake};
      bins repairval[] = {MBINIT_REPAIRVAL_RX_Init_Handshake, MBINIT_REPAIRVAL_RX_Valid_Pattern_Det
                          ,MBINIT_REPAIRVAL_RX_Send_Result_RESP,
                          MBINIT_REPAIRVAL_RX_Done_Handshake};
      bins reversal[] = {MBINIT_REVERSAL_RX_Init_Handshake, MBINIT_REVERSAL_RX_Clear_Log_Hnd,
                         MBINIT_REVERSAL_RX_Per_Lane_ID_Det, MBINIT_REVERSAL_RX_Result_Handshake,
                         MBINIT_REVERSAL_RX_Done_Handshake};
      bins repairmb[] = {MBINIT_REPAIRMB_RX_Init_Handshake, MBINIT_REPAIRMB_RX_Wait_Apply_Degrade, MBINIT_REPAIRMB_RX_Send_Degrade_Resp,
                         MBINIT_REPAIRMB_RX_Done_Handshake};
      bins trainerror[] = {TRAINERROR_RX_Handshake, TRAINERROR_RX_TrainError};

      // Phase 01: Training
      bins valvref[] = {MBTRAIN_VALVREF_RX_Start_Handshake, MBTRAIN_VALVREF_RX_End_Handshake};
      bins datavref[] = {MBTRAIN_DATAVREF_RX_Start_Handshake, MBTRAIN_DATAVREF_RX_End_Handshake};
      bins dtc1[] = {MBTRAIN_DTC1_RX_Start_Handshake, MBTRAIN_DTC1_RX_End_Handshake};
      bins rxclkcal[] = {MBTRAIN_RXCLKCAL_RX_Start_Handshake,
                         MBTRAIN_RXCLKCAL_RX_End_Handshake};
      bins valtrainctr[] = {MBTRAIN_VALTRAINCENTER_RX_Start_Handshake, MBTRAIN_VALTRAINCENTER_RX_End_Handshake};
      bins rxdeskew[] = {MBTRAIN_RXDESKEW_RX_Start_Handshake, MBTRAIN_RXDESKEW_RX_End_Handshake};
      bins dtc2[] = {MBTRAIN_DTC2_RX_Start_Handshake, MBTRAIN_DTC2_RX_End_Handshake};
      bins linkspeed[] = {MBTRAIN_LINKSPEED_RX_Start_Handshake, MBTRAIN_LINKSPEED_RX_LinksSpeed_Done_Hnd, 
                          MBTRAIN_LINKSPEED_RX_Exit_Repair_Hnd, MBTRAIN_LINKSPEED_RX_Exit_SpeedDegrade_Hnd};
      bins repair[] = {MBTRAIN_REPAIR_RX_Start_Handshake, MBTRAIN_REPAIR_RX_Apply_Degrade_Handshake,
                       MBTRAIN_REPAIR_RX_End_Handshake};
      bins speedidle[] = {MBTRAIN_SPEEDIDLE_RX_Speed_Transition};
      bins txselfcal = {MBTRAIN_TXSELFCAL_RX_End_Handshake};
      bins valtrainvref[] = {MBTRAIN_VALTRAINVREF_RX_Start_Handshake, MBTRAIN_VALTRAINVREF_RX_End_Handshake};
      bins datatrainvref[] = {MBTRAIN_DATATRAINVREF_RX_Start_Handshake, MBTRAIN_DATATRAINVREF_RX_End_Handshake};

      // Phase 10: Active & Low Power
      bins linkinit[] = {LINKINIT_RX_PL_Clk_Req_Handshake, LINKINIT_RX_LP_Wake_Req_Handshake,
                         LINKINIT_RX_State_Rsp_Handshake};
      bins active = {ACTIVE_RX_Active};

      // Phase 11: Data to Clock Sweep (D2C)
      bins d2c_tx[] = {Data_To_Clock_test_RX_INIT_Handshake_TX_Init,
                       Data_To_Clock_test_RX_LFSR_Clear_Handshake_TX_Init,
                       Data_To_Clock_test_RX_Pattern_Detection_TX_Init,
                       Data_To_Clock_test_RX_Result_Handshake_TX_Init,
                       Data_To_Clock_test_RX_End_Init_Handshake_TX_Init};
      bins d2c_rx[] = {Data_To_Clock_test_RX_INIT_Handshake_RX_Init,
                       Data_To_Clock_test_RX_LFSR_Clear_Handshake_RX_Init,
                       Data_To_Clock_test_RX_Pattern_Detection_RX_Init,
                       Data_To_Clock_test_RX_Result_Handshake_RX_Init,
                       Data_To_Clock_test_RX_Sweep_Result_Handshake,
                       Data_To_Clock_test_RX_End_Init_Handshake_RX_Init};
    }

    // 2. Lane map values coverpoint
    cp_lane_map: coverpoint curr_lane_map {
      bins x8_lower = {X8_LOWER_MODE};
      bins x8_upper = {X8_UPPER_MODE};
      bins x16 = {X16_MODE};
    }

    // 3. Coverpoint on high-level state for degradation states only
    cp_state_degrade: coverpoint curr_state {
      bins repairmb = {ST_REPAIRMB}; bins repair = {ST_REPAIR};
    }

    // 4. Cross: lane_map x high-level degradation states
    cx_state_x_lane_map: cross cp_state_degrade, cp_lane_map;

    // 5. State-level transitions (happy path transitions)
    cp_transitions: coverpoint curr_state {
      // Phase 00: Initialization happy path
      bins reset_to_sbinit = (ST_RESET => ST_SBINIT);
      bins sbinit_to_param = (ST_SBINIT => ST_PARAM);
      bins param_to_cal = (ST_PARAM => ST_CAL);
      bins cal_to_repairclk = (ST_CAL => ST_REPAIRCLK);
      bins repairclk_to_repairval = (ST_REPAIRCLK => ST_REPAIRVAL);
      bins repairval_to_reversal = (ST_REPAIRVAL => ST_REVERSAL);
      bins reversal_to_repairmb = (ST_REVERSAL => ST_REPAIRMB);
      bins repairmb_to_d2c_tx = (ST_REPAIRMB => ST_D2C_TX);

      // Phase 01: Training happy path
      bins repairmb_to_valvref = (ST_REPAIRMB => ST_VALVREF);
      bins valvref_to_d2c_rx = (ST_VALVREF => ST_D2C_RX);
      bins valvref_to_datavref = (ST_VALVREF => ST_DATAVREF);
      bins datavref_to_d2c_rx = (ST_DATAVREF => ST_D2C_RX);
      bins dtc1_to_d2c_rx = (ST_DTC1 => ST_D2C_RX);
      bins rxclkcal_to_valtrainctr = (ST_RXCLKCAL => ST_VALTRAINCTR);
      bins valtrainctr_to_d2c_rx = (ST_VALTRAINCTR => ST_D2C_RX);
      bins rxdeskew_to_dtc2 = (ST_RXDESKEW => ST_DTC2);
      bins dtc2_to_d2c_rx = (ST_DTC2 => ST_D2C_RX);
      bins linkspeed_to_d2c_tx = (ST_LINKSPEED => ST_D2C_TX);
      bins linkspeed_to_repair = (ST_LINKSPEED => ST_REPAIR);
      bins linkspeed_to_speedidle = (ST_LINKSPEED => ST_SPEEDIDLE);
      bins speedidle_to_txselfcal = (ST_SPEEDIDLE => ST_TXSELFCAL);
      bins speedidle_to_trainerror = (ST_SPEEDIDLE => ST_TRAINERROR);
      bins valtrainvref_to_d2c_rx = (ST_VALTRAINVREF => ST_D2C_RX);
      bins datatrainvref_to_d2c_rx = (ST_DATATRAINVREF => ST_D2C_RX);

      // D2C returns
      bins d2c_tx_to_repairmb = (ST_D2C_TX => ST_REPAIRMB);
      bins d2c_rx_to_dtc1 = (ST_D2C_RX => ST_DTC1);
      bins d2c_rx_to_valtrainctr = (ST_D2C_RX => ST_VALTRAINCTR);
      bins d2c_rx_to_dtc2 = (ST_D2C_RX => ST_DTC2);
      bins d2c_tx_to_linkspeed = (ST_D2C_TX => ST_LINKSPEED);
      bins d2c_rx_to_valtrainvref = (ST_D2C_RX => ST_VALTRAINVREF);
      bins d2c_rx_to_datatrainvref = (ST_D2C_RX => ST_DATATRAINVREF);
      bins d2c_rx_to_valvref = (ST_D2C_RX => ST_VALVREF);
      bins d2c_rx_to_datavref = (ST_D2C_RX => ST_DATAVREF);

      // Phase 10: Active
      bins linkinit_to_active = (ST_LINKINIT => ST_ACTIVE);

      // Any state → TRAINERROR
      bins to_trainerror[] = (
        ST_SBINIT, ST_PARAM, ST_CAL,
        ST_REPAIRCLK, ST_REPAIRVAL, ST_REVERSAL, ST_REPAIRMB,
        ST_VALVREF, ST_DATAVREF, ST_DTC1, ST_RXCLKCAL,
        ST_VALTRAINCTR, ST_DTC2,
        ST_REPAIR, ST_SPEEDIDLE, ST_TXSELFCAL,
        ST_VALTRAINVREF, ST_DATATRAINVREF,
        ST_D2C_TX, ST_D2C_RX
        => ST_TRAINERROR
      );

      // TRAINERROR → RESET
      bins trainerror_to_reset = (ST_TRAINERROR => ST_RESET);
    }

    // 6. Clock Results in Clock Repair state
    cp_clk_results: coverpoint curr_clk_results {
      bins values[] = {[3'b000 : 3'b111]};
    }
    cp_state_repairclk: coverpoint curr_state {bins repairclk = {ST_REPAIRCLK};}
    cx_clk_x_repairclk: cross cp_state_repairclk, cp_clk_results;

    // 7. Valid Results in Repair Valid / ValVref / ValTrainCenter states
    cp_valid_results: coverpoint curr_valid_results {
      bins zero = {1'b0}; bins one = {1'b1};
    }
    cp_state_valid_checks: coverpoint curr_state {
      bins states = {ST_REPAIRVAL, ST_VALVREF, ST_VALTRAINCTR};
    }
    cx_valid_x_state: cross cp_state_valid_checks, cp_valid_results;

    // 8. Data Results (first 16 bits) in Reversal and D2C states
    cp_data_results: coverpoint curr_data_results_16 {
      bins all_zeros = {16'h0000};
      bins all_ones = {16'hFFFF};
      bins first8_zeros_last8_ones = {16'hFF00};
      bins first8_ones_last8_zeros = {16'h00FF};
      bins alternating_5 = {16'h5555};
      bins alternating_A = {16'hAAAA};
    }
    cp_state_data_checks: coverpoint curr_state {bins states = {ST_D2C_TX, ST_D2C_RX, ST_REVERSAL};}
    cx_data_x_state: cross cp_state_data_checks, cp_data_results;

  endgroup : cg_ltsm


  // Function: new
  extern function new(string name, uvm_component parent);

  // Function: write_rmblink_cg
  extern virtual function void write_rmblink_cg(rmblink_seq_item t);

  // Function: write_ltsm_cg
  extern virtual function void write_ltsm_cg(ltsmc_seq_item t);

  // Function: report_phase
  extern virtual function void report_phase(uvm_phase phase);

  // Function: encoding_to_state
  extern function ltsm_state_e encoding_to_state(rx_encoding_t enc);

endclass : rp_coverage_collector

//---------------------------------------------------------------------------
// IMPLEMENTATION
//---------------------------------------------------------------------------

// new
function rp_coverage_collector::new(string name, uvm_component parent);
  super.new(name, parent);
  rmblink_exp          = new("rmblink_exp", this);
  ltsm_exp             = new("ltsm_exp", this);

  prev_encoding        = RESET_Reset;
  curr_encoding        = RESET_Reset;
  curr_state           = ST_RESET;
  curr_lane_map        = X16_MODE;
  curr_clk_results     = 3'b000;
  curr_valid_results   = 1'b0;
  curr_data_results_16 = 16'h0000;

  cg_rmblink           = new();
  cg_ltsm              = new();
endfunction : new

// write_rmblink_cg
function void rp_coverage_collector::write_rmblink_cg(rmblink_seq_item t);
  if (t == null) begin
    `uvm_error("COV", "Null rmblink_seq_item received")
    return;
  end
  $cast(rmblink_item, t.clone());
  cg_rmblink.sample();
endfunction : write_rmblink_cg

// write_ltsm_cg
function void rp_coverage_collector::write_ltsm_cg(ltsmc_seq_item t);
  if (t == null) begin
    `uvm_error("COV", "Null ltsmc_seq_item received")
    return;
  end
  $cast(ltsm_item, t.clone());

  prev_encoding        = curr_encoding;
  curr_encoding        = ltsm_item.rx_encoding;
  curr_lane_map        = ltsm_item.lane_map_code;
  curr_state           = encoding_to_state(curr_encoding);
  curr_clk_results     = ltsm_item.rx_clk_results;
  curr_valid_results   = ltsm_item.rx_valid_results;
  curr_data_results_16 = ltsm_item.rx_data_results[15:0];

  cg_ltsm.sample();
endfunction : write_ltsm_cg

// report_phase
function void rp_coverage_collector::report_phase(uvm_phase phase);
  super.report_phase(phase);
  `uvm_info("COVERAGE", $sformatf(
            {
              "\n============================================\n",
              "  RX LTSM COVERAGE SUMMARY\n",
              "  LTSM: %.1f%%\n",
              "============================================"
            },
            cg_ltsm.get_coverage()
            ), UVM_LOW)
endfunction : report_phase

// encoding_to_state mapping
function rp_coverage_collector::ltsm_state_e rp_coverage_collector::encoding_to_state(
    rx_encoding_t enc);
  case (enc)
    RESET_Reset: return ST_RESET;
    SBINIT_RX_Wait_Out_Of_Reset, SBINIT_RX_Done_Handshake: return ST_SBINIT;
    MBINIT_PARAM_RX_Wait_Config_REQ, MBINIT_PARAM_RX_Check_Parameters, MBINIT_PARAM_RX_Send_RESP:
    return ST_PARAM;
    MBINIT_CAL_RX_Done_Handshake: return ST_CAL;
    MBINIT_REPAIRCLK_RX_Init_Handshake, MBINIT_REPAIRCLK_RX_Pattern_Detection,
      MBINIT_REPAIRCLK_RX_Wait_Result_REQ, MBINIT_REPAIRCLK_RX_Send_RESP,
      MBINIT_REPAIRCLK_RX_Done_Handshake:
    return ST_REPAIRCLK;
    MBINIT_REPAIRVAL_RX_Init_Handshake, MBINIT_REPAIRVAL_RX_Valid_Pattern_Det,
      MBINIT_REPAIRVAL_RX_Wait_Result_REQ, MBINIT_REPAIRVAL_RX_Send_Result_RESP,
      MBINIT_REPAIRVAL_RX_Done_Handshake:
    return ST_REPAIRVAL;
    MBINIT_REVERSAL_RX_Init_Handshake, MBINIT_REVERSAL_RX_Clear_Log_Hnd,
      MBINIT_REVERSAL_RX_Per_Lane_ID_Det, MBINIT_REVERSAL_RX_Result_Handshake,
      MBINIT_REVERSAL_RX_Done_Handshake:
    return ST_REVERSAL;
    MBINIT_REPAIRMB_RX_Init_Handshake, MBINIT_REPAIRMB_RX_Wait_Apply_Degrade,
      MBINIT_REPAIRMB_RX_Degrade, MBINIT_REPAIRMB_RX_Send_Degrade_Resp,
      MBINIT_REPAIRMB_RX_Done_Handshake:
    return ST_REPAIRMB;
    TRAINERROR_RX_Handshake, TRAINERROR_RX_TrainError, TRAINERROR_RX_Reset: return ST_TRAINERROR;
    MBTRAIN_VALVREF_RX_Start_Handshake, MBTRAIN_VALVREF_RX_End_Handshake: return ST_VALVREF;
    MBTRAIN_DATAVREF_RX_Start_Handshake, MBTRAIN_DATAVREF_RX_End_Handshake: return ST_DATAVREF;
    MBTRAIN_DTC1_RX_Start_Handshake, MBTRAIN_DTC1_RX_End_Handshake: return ST_DTC1;
    MBTRAIN_RXCLKCAL_RX_Start_Handshake, MBTRAIN_RXCLKCAL_RX_Clock_Shifting_Op,
      MBTRAIN_RXCLKCAL_RX_End_Handshake:
    return ST_RXCLKCAL;
    MBTRAIN_VALTRAINCENTER_RX_Start_Handshake, MBTRAIN_VALTRAINCENTER_RX_End_Handshake:
    return ST_VALTRAINCTR;
    MBTRAIN_RXDESKEW_RX_Start_Handshake, MBTRAIN_RXDESKEW_RX_EQ_Preset_Handshake,
      MBTRAIN_RXDESKEW_RX_Deskew_Operation, MBTRAIN_RXDESKEW_RX_Datacenter_Handshake,
      MBTRAIN_RXDESKEW_RX_End_Handshake, MBTRAIN_RXDESKEW_RX_Train_Error_Handshake:
    return ST_RXDESKEW;
    MBTRAIN_DTC2_RX_Start_Handshake, MBTRAIN_DTC2_RX_End_Handshake: return ST_DTC2;
    MBTRAIN_LINKSPEED_RX_Start_Handshake, MBTRAIN_LINKSPEED_RX_LinksSpeed_Done_Hnd,
      MBTRAIN_LINKSPEED_RX_Error_REQ, MBTRAIN_LINKSPEED_RX_Phy_Retrain_Hnd,
      MBTRAIN_LINKSPEED_RX_Exit_Repair_Hnd, MBTRAIN_LINKSPEED_RX_Exit_SpeedDegrade_Hnd:
    return ST_LINKSPEED;
    MBTRAIN_REPAIR_RX_Start_Handshake, MBTRAIN_REPAIR_RX_Apply_Degrade_Handshake,
      MBTRAIN_REPAIR_RX_End_Handshake:
    return ST_REPAIR;
    MBTRAIN_SPEEDIDLE_RX_Speed_Transition, MBTRAIN_SPEEDIDLE_RX_End_Handshake: return ST_SPEEDIDLE;
    MBTRAIN_TXSELFCAL_RX_End_Handshake: return ST_TXSELFCAL;
    MBTRAIN_VALTRAINVREF_RX_Start_Handshake, MBTRAIN_VALTRAINVREF_RX_End_Handshake:
    return ST_VALTRAINVREF;
    MBTRAIN_DATATRAINVREF_RX_Start_Handshake, MBTRAIN_DATATRAINVREF_RX_End_Handshake:
    return ST_DATATRAINVREF;
    LINKINIT_RX_PL_Clk_Req_Handshake, LINKINIT_RX_LP_Wake_Req_Handshake,
      LINKINIT_RX_State_Rsp_Handshake:
    return ST_LINKINIT;
    ACTIVE_RX_Active: return ST_ACTIVE;
    L1_RX_Start_HS, L1_RX_L1_State, L1_RX_Wait1us, L1_RX_Refuse: return ST_L1;
    EXIT_HS_RX_Exit_Handshake: return ST_EXIT_HS;
    Data_To_Clock_test_RX_INIT_Handshake_TX_Init,
      Data_To_Clock_test_RX_LFSR_Clear_Handshake_TX_Init,
      Data_To_Clock_test_RX_Pattern_Detection_TX_Init,
      Data_To_Clock_test_RX_Result_Handshake_TX_Init,
      Data_To_Clock_test_RX_End_Init_Handshake_TX_Init:
    return ST_D2C_TX;
    Data_To_Clock_test_RX_INIT_Handshake_RX_Init,
      Data_To_Clock_test_RX_LFSR_Clear_Handshake_RX_Init,
      Data_To_Clock_test_RX_Pattern_Detection_RX_Init,
      Data_To_Clock_test_RX_Result_Handshake_RX_Init,
      Data_To_Clock_test_RX_Sweep_Result_Handshake,
      Data_To_Clock_test_RX_End_Init_Handshake_RX_Init:
    return ST_D2C_RX;
    default: return ST_RESET;
  endcase
endfunction : encoding_to_state
