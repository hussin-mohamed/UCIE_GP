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

`uvm_analysis_imp_decl(_phylink)
`uvm_analysis_imp_decl(_ltsm)

//---------------------------------------------------------------------------
//
// CLASS: sb_coverage_collector
//
// Coverage collector for sideband verification traffic. It samples monitored
// phylink transactions and provides the framework for collecting additional
// LTSM coverage in the future.
//
//---------------------------------------------------------------------------

class sb_coverage_collector extends uvm_component;
  `uvm_component_utils(sb_coverage_collector)

  uvm_analysis_imp_phylink #(phylink_seq_item, sb_coverage_collector) phylink_exp;
  uvm_analysis_imp_ltsm    #(ltsm_seq_item, sb_coverage_collector)    ltsm_exp;

  phylink_seq_item phylink_item;
  ltsm_seq_item    ltsm_item;


  //---------------------------------------------------------------------------
  //
  // COVERGROUP: cg_phylink
  //
  // Samples external ACTIVE-mode phylink traffic, including message validity,
  // routing fields, payload extremes, and selected cross coverage.
  //
  //---------------------------------------------------------------------------

  covergroup cg_phylink;
    option.per_instance = 1;
    option.name = "cg_phylink";

    // Message with/without error injection
    cp_valid_msg: coverpoint is_valid(phylink_item) iff (phylink_item.op_mode == ACTIVE) {
      bins valid_msg   = {1};
      bins invalid_msg = {0};
    }
    
    // Fullcodes (Message Code + Subcode)
    cp_fullcode: coverpoint phylink_item.fullcode iff (phylink_item.op_mode == ACTIVE) {
      bins supported_fullcodes[]   = cp_fullcode with (is_supported_fullcode(item));
      bins unsupported_fullcodes[] = cp_fullcode with (is_unsupported_existing_fullcode(item));
      bins corrupted_fullcodes     = default;
    }

    // Opcodes
    cp_opcode: coverpoint phylink_item.opcode iff (phylink_item.op_mode == ACTIVE) {
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
    cp_srcid: coverpoint phylink_item.srcid iff (phylink_item.op_mode == ACTIVE) {
      bins src_phy             = {SRC_PHY};
      bins unsupported_srcid[] = {SRC_D2D, SRC_MGT};
      bins corrupted_srcid     = default;
    }

    // Destination IDs
    cp_dstid: coverpoint phylink_item.dstid iff (phylink_item.op_mode == ACTIVE) {
      bins dst_phy             = {DST_PHY};
      bins unsupported_dstid[] = {DST_RSD, DST_D2D, DST_MGT};
      bins corrupted_dstid     = default;
    }

    // Data Extremes
    cp_data_extremes: coverpoint phylink_item.data iff (phylink_item.op_mode == ACTIVE) {
      bins data_all_zeros = {64'h0};
      bins data_all_ones  = {64'hFFFF_FFFF_FFFF_FFFF};
      bins data_others    = default;
    }

    // Info Extremes
    cp_info_extremes: coverpoint phylink_item.info iff (phylink_item.op_mode == ACTIVE) {
      bins info_all_zeros = {16'h0};
      bins info_all_ones  = {16'hFFFF};
      bins info_others    = default;
    }
    
    cx_msg_routing: cross cp_valid_msg, cp_fullcode, cp_srcid, cp_dstid iff (phylink_item.op_mode == ACTIVE) {
      bins grouped_unsupp_fullcodes = binsof(cp_fullcode.unsupported_fullcodes);
      bins grouped_unsupp_src       = binsof(cp_srcid.unsupported_srcid);
      bins grouped_unsupp_dst       = binsof(cp_dstid.unsupported_dstid);
    }

    cx_payloads: cross cp_opcode, cp_data_extremes, cp_info_extremes iff (phylink_item.op_mode == ACTIVE) {
      bins grouped_unsupp_opcodes = binsof(cp_opcode.unsupported_opcode);

      // Ignore data extremes that do not apply to header-only messages.
      ignore_bins ignore_invalid_data_extremes =
        !binsof(cp_opcode.w64b_data) &&
        binsof(cp_data_extremes.data_all_ones);
    }
  endgroup : cg_phylink


  // Function: new
  //
  // Creates the coverage collector and constructs its analysis implementations
  // and covergroups.

  extern function new(string name, uvm_component parent);

  // Function: write_phylink
  //
  // Receives one monitored phylink transaction, clones it into the collector's
  // local storage, and samples the phylink covergroup.

  extern virtual function void write_phylink(phylink_seq_item t);

  // Function: write_ltsm
  //
  // Receives one monitored LTSM transaction. The hook is kept for future LTSM
  // coverage expansion and is currently a placeholder.

  extern virtual function void write_ltsm(ltsm_seq_item t);
endclass

//---------------------------------------------------------------------------
// IMPLEMENTATION
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
//
// CLASS: sb_coverage_collector
//
//---------------------------------------------------------------------------

// new
// ---

function sb_coverage_collector::new(string name, uvm_component parent);
  super.new(name, parent);
  phylink_exp = new("phylink_exp", this);
  ltsm_exp    = new("ltsm_exp", this);

  cg_phylink = new();
  // cg_ltsm = new();
endfunction : new

// write_phylink
// -------------

function void sb_coverage_collector::write_phylink(phylink_seq_item t);
  if (t == null) begin
    `uvm_error("COV", "Null phylink_seq_item received")
    return;
  end

  $cast(phylink_item, t.clone());
  cg_phylink.sample();
endfunction : write_phylink

// write_ltsm
// ----------

function void sb_coverage_collector::write_ltsm(ltsm_seq_item t);
  // if (t == null) begin
  //   `uvm_error("COV", "Null ltsm_seq_item received")
  //   return;
  // end
  // $cast(ltsm_item, t.clone());
  // cg_ltsm.sample();
endfunction : write_ltsm
