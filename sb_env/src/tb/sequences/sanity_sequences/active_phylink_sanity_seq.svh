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

//-----------------------------------------------------------------------------
//
// CLASS: active_phylink_sanity_seq
//
// ACTIVE-mode phylink sequence used by the sanity flow to send a directed set
// of link-level messages with controlled randomization.
//
//-----------------------------------------------------------------------------

class active_phylink_sanity_seq extends sb_sequence_base #(phylink_seq_item);
  `uvm_object_utils(active_phylink_sanity_seq)


  // Function: new
  //
  // Creates a new active_phylink_sanity_seq instance with the given name.

  extern function new(string name = "active_phylink_sanity_seq");


  // Task: body
  //
  // Generates a bounded batch of ACTIVE phylink items for basic checking.

  extern task body();

endclass : active_phylink_sanity_seq


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS: active_phylink_sanity_seq
//
// Implements the ACTIVE phylink sanity stimulus.
//
//-----------------------------------------------------------------------------


// new
// ---

function active_phylink_sanity_seq::new(string name = "active_phylink_sanity_seq");
  super.new(name);
endfunction : new

// body
// ----
//
// Sends a moderate number of randomized ACTIVE phylink items to exercise the
// link-to-LTSM path without the longer stress-test runtime.

task active_phylink_sanity_seq::body();

  repeat(200) begin
    start_item(req);
    req.configure_randomization(ACTIVE);
    assert(req.randomize());
    finish_item(req);
  end

  // Additional directed debug cases for unsupported messages are kept below
  // as commented examples that can be re-enabled during focused bring-up.
  // start_item(req); // Unsupported fullcode
  // req.op_mode  = ACTIVE;
  // req.fullcode = Start_Tx_Init_D_to_C_point_test_resp;
  // req.opcode   = MSG_WO_DATA;
  // req.srcid    = SRC_PHY;
  // req.dstid    = DST_PHY;
  // req.info     = '0;
  // req.data     = '0;
  // req.cp       = '0;
  // req.dp       = '0;
  // req.idle_ui_cnt = 100;
  // req.rsvd1    = '0;
  // req.rsvd2    = '0;
  // req.rsvd3    = '0;
  // req.rsvd4    = '0;
  // finish_item(req);

  // start_item(req);
  // req.op_mode  = ACTIVE;
  // req.idle_ui_cnt = 100;
  // req.fullcode = Start_Tx_Init_D_to_C_eye_sweep_req;
  // req.opcode   = MSG_W_64B_DATA;
  // req.srcid    = SRC_PHY;
  // req.dstid    = DST_PHY;
  // req.info     = '0;
  // req.data     = '0;
  // req.rsvd1    = '0;
  // req.rsvd2    = '0;
  // req.rsvd3    = '0;
  // req.rsvd4    = '0;
  // calculate_parity_by_item(req, req.cp, req.dp);
  // finish_item(req);

  // start_item(req); // Unsupported opcode
  // req.op_mode  = ACTIVE;
  // req.idle_ui_cnt = 100;
  // req.fullcode = Start_Tx_Init_D_to_C_eye_sweep_req;
  // req.opcode   = MGT_MSG_WO_DATA;
  // req.srcid    = SRC_PHY;
  // req.dstid    = DST_PHY;
  // req.info     = '0;
  // req.data     = '0;
  // req.rsvd1    = '0;
  // req.rsvd2    = '0;
  // req.rsvd3    = '0;
  // req.rsvd4    = '0;
  // calculate_parity_by_item(req, req.cp, req.dp);
  // finish_item(req);

  // start_item(req);
  // req.op_mode  = ACTIVE;
  // req.idle_ui_cnt = 100;
  // req.fullcode = SBINIT_out_of_Reset;
  // req.opcode   = MSG_WO_DATA;
  // req.srcid    = SRC_PHY;
  // req.dstid    = DST_PHY;
  // req.info     = '0;
  // req.data     = '0;
  // req.rsvd1    = '0;
  // req.rsvd2    = '0;
  // req.rsvd3    = '0;
  // req.rsvd4    = '0;
  // calculate_parity_by_item(req, req.cp, req.dp);
  // finish_item(req);

  // start_item(req); // Unsupported srcid
  // req.op_mode  = ACTIVE;
  // req.idle_ui_cnt = 100;
  // req.fullcode = MBINIT_REPAIRCLK_init_req;
  // req.opcode   = MSG_WO_DATA;
  // req.srcid    = SRC_MGT;
  // req.dstid    = DST_PHY;
  // req.info     = '0;
  // req.data     = '0;
  // req.rsvd1    = '0;
  // req.rsvd2    = '0;
  // req.rsvd3    = '0;
  // req.rsvd4    = '0;
  // calculate_parity_by_item(req, req.cp, req.dp);
  // finish_item(req);

  // start_item(req);
  // req.op_mode  = ACTIVE;
  // req.idle_ui_cnt = 100;
  // req.fullcode = SBINIT_done_req;
  // req.opcode   = MSG_WO_DATA;
  // req.srcid    = SRC_PHY;
  // req.dstid    = DST_PHY;
  // req.info     = '0;
  // req.data     = '0;
  // req.rsvd1    = '0;
  // req.rsvd2    = '0;
  // req.rsvd3    = '0;
  // req.rsvd4    = '0;
  // calculate_parity_by_item(req, req.cp, req.dp);
  // finish_item(req);

  // start_item(req);
  // req.op_mode  = ACTIVE;
  // req.idle_ui_cnt = 100;
  // req.fullcode = MBINIT_PARAM_configuration_req;
  // req.opcode   = MSG_W_64B_DATA;
  // req.srcid    = SRC_PHY;
  // req.dstid    = DST_PHY;
  // req.info     = '0;
  // req.data     = '0;
  // req.rsvd1    = '0;
  // req.rsvd2    = '0;
  // req.rsvd3    = '0;
  // req.rsvd4    = '0;
  // calculate_parity_by_item(req, req.cp, req.dp);
  // finish_item(req);

  // start_item(req);
  // req.op_mode  = ACTIVE;
  // req.idle_ui_cnt = 'h80;
  // req.out_of_rst_ui_cnt = 'h0;
  // req.fullcode = MBTRAIN_RXDESKEW_exit_to_DATATRAINCENTER1_resp;
  // req.opcode   = MSG_WO_DATA;
  // req.srcid    = SRC_PHY;
  // req.dstid    = DST_PHY;
  // req.info     = 'ha010;
  // req.data     = 'h0;
  // req.cp       = 'h0;
  // req.dp       = 'h0;
  // req.rsvd1    = 'h0;
  // req.rsvd2    = 'h0;
  // req.rsvd3    = 'h0;
  // req.rsvd4    = 'h0;
  // // calculate_parity_by_item(req, req.cp, req.dp);
  // finish_item(req);

  // start_item(req);
  // req.op_mode  = ACTIVE;
  // req.idle_ui_cnt = 100;
  // req.fullcode = SBINIT_out_of_Reset;
  // req.opcode   = MSG_WO_DATA;
  // req.srcid    = SRC_PHY;
  // req.dstid    = DST_PHY;
  // req.info     = '0;
  // req.data     = '0;
  // req.rsvd1    = '0;
  // req.rsvd2    = '0;
  // req.rsvd3    = '0;
  // req.rsvd4    = '0;
  // calculate_parity_by_item(req, req.cp, req.dp);
  // finish_item(req);

  // start_item(req);
  // req.op_mode  = ACTIVE;
  // req.idle_ui_cnt = 100;
  // req.fullcode = SBINIT_done_resp;
  // req.opcode   = MSG_WO_DATA;
  // req.srcid    = SRC_PHY;
  // req.dstid    = DST_PHY;
  // req.info     = '0;
  // req.data     = '0;
  // req.rsvd1    = '0;
  // req.rsvd2    = '0;
  // req.rsvd3    = '0;
  // req.rsvd4    = '0;
  // calculate_parity_by_item(req, req.cp, req.dp);
  // finish_item(req);

  // start_item(req);
  // req.op_mode  = ACTIVE;
  // req.idle_ui_cnt = 100;
  // req.fullcode = Start_Tx_Init_D_to_C_eye_sweep_req;
  // req.opcode   = MSG_W_64B_DATA;
  // req.srcid    = SRC_PHY;
  // req.dstid    = DST_PHY;
  // req.info     = '0;
  // req.data     = '0;
  // req.rsvd1    = '0;
  // req.rsvd2    = '0;
  // req.rsvd3    = '0;
  // req.rsvd4    = '0;
  // calculate_parity_by_item(req, req.cp, req.dp);
  // finish_item(req);







  // start_item(req);
  // req.op_mode  = ACTIVE;
  // req.idle_ui_cnt = 'h80;
  // req.out_of_rst_ui_cnt = 'h0;
  // req.fullcode = MBTRAIN_RXCLKCAL_TCKN_L_shift_req;
  // req.opcode   = MSG_WO_DATA;
  // req.srcid    = SRC_PHY;
  // req.dstid    = DST_PHY;
  // req.info     = 'ha010;
  // req.data     = 'h0;
  // req.cp       = 'h0;
  // req.dp       = 'h0;
  // req.rsvd1    = 'h0;
  // req.rsvd2    = 'h0;
  // req.rsvd3    = 'h0;
  // req.rsvd4    = 'h0;
  // // calculate_parity_by_item(req, req.cp, req.dp);
  // finish_item(req);

  // start_item(req);
  // req.op_mode  = ACTIVE;
  // req.idle_ui_cnt = 100;
  // req.fullcode = SBINIT_out_of_Reset;
  // req.opcode   = MSG_WO_DATA;
  // req.srcid    = SRC_PHY;
  // req.dstid    = DST_PHY;
  // req.info     = '0;
  // req.data     = '0;
  // req.rsvd1    = '0;
  // req.rsvd2    = '0;
  // req.rsvd3    = '0;
  // req.rsvd4    = '0;
  // calculate_parity_by_item(req, req.cp, req.dp);
  // finish_item(req);

  // start_item(req);
  // req.op_mode  = ACTIVE;
  // req.idle_ui_cnt = 100;
  // req.fullcode = SBINIT_done_resp;
  // req.opcode   = MSG_WO_DATA;
  // req.srcid    = SRC_PHY;
  // req.dstid    = DST_PHY;
  // req.info     = '0;
  // req.data     = '0;
  // req.rsvd1    = '0;
  // req.rsvd2    = '0;
  // req.rsvd3    = '0;
  // req.rsvd4    = '0;
  // calculate_parity_by_item(req, req.cp, req.dp);
  // finish_item(req);

  start_item(req);
  req.op_mode  = ACTIVE;
  req.idle_ui_cnt = 100;
  req.fullcode = Start_Tx_Init_D_to_C_eye_sweep_req;
  req.opcode   = MSG_W_64B_DATA;
  req.srcid    = SRC_PHY;
  req.dstid    = DST_PHY;
  req.info     = '0;
  req.data     = '0;
  req.rsvd1    = '0;
  req.rsvd2    = '0;
  req.rsvd3    = '0;
  req.rsvd4    = '0;
  calculate_parity_by_item(req, req.cp, req.dp);
  finish_item(req);
endtask : body
