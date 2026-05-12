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
// CLASS: ltsm_rdi_sequence_item
//
// The ltsm_rdi_sequence_item class represents the output transaction
//
//------------------------------------------------------------------------------

class ltsm_rdi_sequence_item extends uvm_sequence_item;

    logic                           i_reset;
    logic [3:0]						i_lp_state_req;
	logic							i_lp_stallack;
	logic							i_lp_clk_ack;
	logic							i_lp_wake_req;
	logic							i_lp_linkerror;
    logic [3:0]						o_pl_state_sts;
	logic							o_pl_inband_pres;
	logic							o_pl_phyinrecenter;
	logic							o_pl_stallreq;
	logic							o_pl_clk_req;
	logic							o_pl_wake_ack;
	logic							o_pl_lnk_cfg;
	logic [2:0]							o_pl_speedmode;
	logic							o_pl_max_speedmode;
	logic							o_pl_error;
	logic							o_pl_trainerror;
	logic							o_pl_cerror;
	logic							o_pl_nferror;
    `uvm_object_utils_begin(ltsm_rdi_sequence_item)
        `uvm_field_int(i_lp_state_req, UVM_NORECORD)
        `uvm_field_int(i_lp_stallack, UVM_NORECORD)
        `uvm_field_int(i_lp_clk_ack, UVM_NORECORD)
        `uvm_field_int(i_lp_wake_req, UVM_NORECORD)
        `uvm_field_int(i_lp_linkerror, UVM_NORECORD)
        `uvm_field_int(o_pl_state_sts, UVM_NORECORD)
        `uvm_field_int(o_pl_inband_pres, UVM_NORECORD)
        `uvm_field_int(o_pl_phyinrecenter, UVM_NORECORD)
        `uvm_field_int(o_pl_stallreq, UVM_NORECORD)
        `uvm_field_int(o_pl_clk_req, UVM_NORECORD)
        `uvm_field_int(o_pl_wake_ack, UVM_NORECORD)
        `uvm_field_int(o_pl_lnk_cfg, UVM_NORECORD)
        `uvm_field_int(o_pl_speedmode, UVM_NORECORD)
        `uvm_field_int(o_pl_max_speedmode, UVM_NORECORD)
        `uvm_field_int(o_pl_error, UVM_NORECORD)
        `uvm_field_int(o_pl_trainerror, UVM_NORECORD)
        `uvm_field_int(o_pl_cerror, UVM_NORECORD)
        `uvm_field_int(o_pl_nferror, UVM_NORECORD)

    `uvm_object_utils_end


    // Function: new
    //
    // Creates a new ltsm_rdi_sequence_item instance with the given name.

    extern function new(string name = "ltsm_rdi_sequence_item");

endclass : ltsm_rdi_sequence_item


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- ltsm_rdi_sequence_item
//
//------------------------------------------------------------------------------


// new
// ---

function ltsm_rdi_sequence_item::new(string name = "ltsm_rdi_sequence_item");
    super.new(name);
endfunction