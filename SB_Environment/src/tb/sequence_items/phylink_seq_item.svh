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
// CLASS: phylink_seq_item
//
// Description: ...
//-----------------------------------------------------------------------------

class phylink_seq_item extends uvm_sequence_item;

  // Enum specifying the type of the current operation of the Sideband (INIT/ACTIVE)
  operation_t op_mode;

  // Randomizable fields
  rand logic [63:0]  pattern;           // SBINIT Pattern
  rand int           idle_ui_cnt;       // Low Gap Unit Intervals Count (Used for driving)
  rand int           out_of_rst_ui_cnt; // The delay between the SBINIT starting points of the local and remote dies
  rand fullcode_t    fullcode;          // Concatenated {MsgCode, MsgSubcode} for Link Training State Machine commands
  rand opcode_t      opcode;            // Opcode
  rand srcid_t       srcid;             // Source ID
  rand dstid_t       dstid;             // Destination ID
  rand logic [15:0]  info;              // Message Information
  rand logic [63:0]  data;              // Message Data
  rand logic         cp;                // Control Parity
  rand logic         dp;                // Data Parity

  // Flag used for response items to inform the sequence that the pattern is detected
  bit pat_detected;
  bit timeout_detected;

  `uvm_object_utils_begin(phylink_seq_item)
    `uvm_field_enum (operation_t, op_mode,  UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK)
    `uvm_field_int  (pattern,               UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK | UVM_NOCOMPARE)
    `uvm_field_int  (idle_ui_cnt,           UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK | UVM_NOCOMPARE)
    `uvm_field_enum (fullcode_t,  fullcode, UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK)
    `uvm_field_enum (opcode_t,    opcode,   UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK)
    `uvm_field_enum (srcid_t,     srcid,    UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK)
    `uvm_field_enum (dstid_t,     dstid,    UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK)
    `uvm_field_int  (info,                  UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK)
    `uvm_field_int  (data,                  UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK)
    `uvm_field_int  (cp,                    UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK)
    `uvm_field_int  (dp,                    UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK)
  `uvm_object_utils_end

  // Function: new
  //
  // Creates a new phylink_seq_item instance with the given name.
  extern function new(string name = "");
endclass : phylink_seq_item

//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS- phylink_seq_item
//
//-----------------------------------------------------------------------------

// new
// ---

function phylink_seq_item::new(string name = "");
  super.new(name);
endfunction
