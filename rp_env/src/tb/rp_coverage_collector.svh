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
`uvm_analysis_imp_decl(_ltsm)

//---------------------------------------------------------------------------
//
// CLASS: rp_coverage_collector
//
// Coverage collector for sideband verification traffic. It samples monitored
// rmblink transactions and provides the framework for collecting additional
// LTSM coverage in the future.
//
//---------------------------------------------------------------------------

class rp_coverage_collector extends uvm_component;
  `uvm_component_utils(rp_coverage_collector)

  uvm_analysis_imp_rmblink #(rmblink_seq_item, rp_coverage_collector) rmblink_exp;
  uvm_analysis_imp_ltsm    #(ltsmc_seq_item, rp_coverage_collector)    ltsm_exp;

  rmblink_seq_item rmblink_item;
  ltsmc_seq_item    ltsm_item;


  //---------------------------------------------------------------------------
  //
  // COVERGROUP: cg_rmblink
  //
  // Samples external ACTIVE-mode rmblink traffic, including message validity,
  // routing fields, payload extremes, and selected cross coverage.
  //
  //---------------------------------------------------------------------------

  covergroup cg_rmblink;
    option.per_instance = 1;
    option.name = "cg_rmblink";

    // Message with/without error injection
    cp_valid_msg: coverpoint is_valid(rmblink_item) iff (rmblink_item.op_mode == ACTIVE) {
      bins valid_msg   = {1};
      bins invalid_msg = {0};
    }
    
    // Fullcodes (Message Code + Subcode)
    cp_fullcode: coverpoint rmblink_item.fullcode iff (rmblink_item.op_mode == ACTIVE) {
      bins supported_fullcodes[]   = cp_fullcode with (is_supported_fullcode(item));
      bins unsupported_fullcodes[] = cp_fullcode with (is_unsupported_existing_fullcode(item));
      bins corrupted_fullcodes     = default;
    }

    // Opcodes
    cp_opcode: coverpoint rmblink_item.opcode iff (rmblink_item.op_mode == ACTIVE) {
      bins wo_data              = {MSG_WO_DATA};
      bins w64b_data            = {MSG_W_64B_DATA};
      bins unsupported_opcode[] = {
                                    MEM_RD_32B, MEM_WR_32B, DMS_REG_RD_32B, DMS_REG_WR_32B,
                                    CFG_RD_32B, CFG_WR_32B, MEM_RD_64B, MEM_WR_64B, DMS_REG_RD_64B,
                                    DMS_REG_WR_64B, CFG_RD_64B, CFG_WR_64B, CPL_WO_DATA, CPL_W_32B_DATA,
                                    MGT_MSG_WO_DATA, MGT_MSG_W_DATA, CPL_W_64B_DATA, PRIORITY_PKT_0, PRIORITY_PKT_1
                                  };
      bins corrupted_opcode     = default;
    }

    // Source IDs
    cp_srcid: coverpoint rmblink_item.srcid iff (rmblink_item.op_mode == ACTIVE) {
      bins src_phy             = {SRC_PHY};
      bins unsupported_srcid[] = {SRC_D2D, SRC_MGT};
      bins corrupted_srcid     = default;
    }

    // Destination IDs
    cp_dstid: coverpoint rmblink_item.dstid iff (rmblink_item.op_mode == ACTIVE) {
      bins dst_phy             = {DST_PHY};
      bins unsupported_dstid[] = {DST_RSD, DST_D2D, DST_MGT};
      bins corrupted_dstid     = default;
    }

    // Data Extremes
    cp_data_extremes: coverpoint rmblink_item.data iff (rmblink_item.op_mode == ACTIVE) {
      bins data_all_zeros = {64'h0};
      bins data_all_ones  = {64'hFFFF_FFFF_FFFF_FFFF};
      bins data_others    = default;
    }

    // Info Extremes
    cp_info_extremes: coverpoint rmblink_item.info iff (rmblink_item.op_mode == ACTIVE) {
      bins info_all_zeros = {16'h0};
      bins info_all_ones  = {16'hFFFF};
      bins info_others    = default;
    }
    
    cx_msg_routing: cross cp_valid_msg, cp_fullcode, cp_srcid, cp_dstid iff (rmblink_item.op_mode == ACTIVE) {
      bins grouped_unsupp_fullcodes = binsof(cp_fullcode.unsupported_fullcodes);
      bins grouped_unsupp_src       = binsof(cp_srcid.unsupported_srcid);
      bins grouped_unsupp_dst       = binsof(cp_dstid.unsupported_dstid);
    }

    cx_payloads: cross cp_opcode, cp_data_extremes, cp_info_extremes iff (rmblink_item.op_mode == ACTIVE) {
      bins grouped_unsupp_opcodes = binsof(cp_opcode.unsupported_opcode);

      // Ignore data extremes that do not apply to header-only messages.
      ignore_bins ignore_invalid_data_extremes =
        !binsof(cp_opcode.w64b_data) &&
        binsof(cp_data_extremes.data_all_ones);
    }
  endgroup : cg_rmblink


  // Function: new
  //
  // Creates the coverage collector and constructs its analysis implementations
  // and covergroups.

  extern function new(string name, uvm_component parent);

  // Function: write_rmblink
  //
  // Receives one monitored rmblink transaction, clones it into the collector's
  // local storage, and samples the rmblink covergroup.

  extern virtual function void write_rmblink(rmblink_seq_item t);

  // Function: write_ltsm
  //
  // Receives one monitored LTSM transaction. The hook is kept for future LTSM
  // coverage expansion and is currently a placeholder.

  extern virtual function void write_ltsm(ltsmc_seq_item t);
endclass

//---------------------------------------------------------------------------
// IMPLEMENTATION
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
//
// CLASS: rp_coverage_collector
//
//---------------------------------------------------------------------------

// new
// ---

function rp_coverage_collector::new(string name, uvm_component parent);
  super.new(name, parent);
  rmblink_exp = new("rmblink_exp", this);
  ltsm_exp    = new("ltsm_exp", this);

  cg_rmblink = new();
  // cg_ltsm = new();
endfunction : new

// write_rmblink
// -------------

function void rp_coverage_collector::write_rmblink(rmblink_seq_item t);
  if (t == null) begin
    `uvm_error("COV", "Null rmblink_seq_item received")
    return;
  end

  $cast(rmblink_item, t.clone());
  cg_rmblink.sample();
endfunction : write_rmblink

// write_ltsm
// ----------

function void rp_coverage_collector::write_ltsm(ltsmc_seq_item t);
  // if (t == null) begin
  //   `uvm_error("COV", "Null ltsmc_seq_item received")
  //   return;
  // end
  // $cast(ltsm_item, t.clone());
  // cg_ltsm.sample();
endfunction : write_ltsm
