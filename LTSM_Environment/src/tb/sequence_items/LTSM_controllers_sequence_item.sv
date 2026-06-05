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

//------------------------------------------------------------------------------
//
// CLASS: LTSM_controllers_seq_item
//
// The LTSM_controllers_seq_item class represents LTSM controller transactions,
// containing both input and output fields for verification purposes.
//
//------------------------------------------------------------------------------
import uvm_pkg::*;
`include "uvm_macros.svh"

import shared_ltsm_pkg::*;
class LTSM_controllers_seq_item extends uvm_sequence_item;
  
  logic i_supply_stable;
  logic i_pll_stable;
  logic i_rx_error;
  logic i_rx_done;
  logic i_tx_done;
  static logic i_rx_valid_results;
  logic o_sbinit_start;
  logic i_sb_ready;
  logic o_t1_ms;
  static logic i_reset;
  logic i_sb_cur_msg_done;
  logic [8:0] o_tx_encoding;
  logic [8:0] o_rx_encoding;
  logic [3:0] o_lane_map_tx,o_lane_map_rx;
  logic [15:0] o_error_threshhold;
  static logic [2:0] i_speedreg,o_speedreg;
  logic [15:0] i_local_cap;
  logic i_par_check_done;
  static logic [63:0] i_rx_data_results; //i_rx_result
  logic [2:0] i_clk_results; //i_clk_result
  logic i_Runtime_Link_Test_status_register,o_Runtime_Link_Test_status_register;
  logic [36:0] i_Runtime_Link_Test_Control_register,o_Runtime_Link_Test_Control_register;
  logic [12:0] i_sim_cycles_8,i_sim_cycles_4,i_sim_cycles_1,i_sim_cycles_1_us,i_sim_cycles_2_us;

    `uvm_object_utils_begin(LTSM_controllers_seq_item)
        `uvm_field_int(i_supply_stable,  UVM_NORECORD)
        `uvm_field_int(i_pll_stable, UVM_NORECORD)
        `uvm_field_int(i_rx_error, UVM_NORECORD)
        `uvm_field_int(i_rx_done, UVM_NORECORD)
        `uvm_field_int(i_tx_done, UVM_NORECORD)
        `uvm_field_int(i_rx_valid_results, UVM_NORECORD)
        `uvm_field_int(i_rx_data_results, UVM_NORECORD)
        `uvm_field_int(o_tx_encoding, UVM_NORECORD)
        `uvm_field_int(o_rx_encoding, UVM_NORECORD)
        `uvm_field_int(i_speedreg, UVM_NORECORD)
        `uvm_field_int(o_speedreg, UVM_NORECORD)
        `uvm_field_int(i_local_cap, UVM_NORECORD)
        `uvm_field_int(i_Runtime_Link_Test_status_register, UVM_NORECORD)
        `uvm_field_int(o_Runtime_Link_Test_status_register, UVM_NORECORD)
        `uvm_field_int(i_Runtime_Link_Test_Control_register, UVM_NORECORD)
        `uvm_field_int(o_Runtime_Link_Test_Control_register, UVM_NORECORD)
        `uvm_field_int(i_sim_cycles_8, UVM_NORECORD)
        `uvm_field_int(i_sim_cycles_4, UVM_NORECORD)
        `uvm_field_int(i_sim_cycles_1, UVM_NORECORD)
        `uvm_field_int(i_sim_cycles_1_us, UVM_NORECORD)
        `uvm_field_int(i_sim_cycles_2_us, UVM_NORECORD)
    `uvm_object_utils_end


    // Function: new
    //
    // Creates a new LTSM_controllers_seq_item instance with the given name.

    extern function new(string name = "LTSM_controllers_seq_item");

endclass : LTSM_controllers_seq_item


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- LTSM_controllers_seq_item
//
//------------------------------------------------------------------------------


// new
// ---

function LTSM_controllers_seq_item::new(string name = "LTSM_controllers_seq_item");
    super.new(name);
endfunction
