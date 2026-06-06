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
// CLASS: rp_sequence_base
//
// The rp_sequence_base class provides a parameterized base implementation
// for RX-Path sequences. It includes request/response handles, print utilities,
// and enforces implementation of the body() task in derived classes.
//
// Type Parameters:
//   ITEM_T - Transaction item type for the sequence
//
//-----------------------------------------------------------------------------

class rp_sequence_base #(type ITEM_T) extends uvm_sequence #(ITEM_T);
  `uvm_object_param_utils(rp_sequence_base #(ITEM_T))

  ITEM_T req, rsp;


  // Function: new
  //
  // Creates a new rp_sequence_base instance with the given name.

  extern function new(string name = "rp_sequence_base");


  // Function: seq_print
  //
  // Utility function for printing sequence debug messages with medium verbosity.

  extern function void seq_print(string msg);


  // Task: pre_body
  //
  // Creates the request transaction object before sequence body execution.

  extern task pre_body();


  // Task: body
  //
  // Virtual method that must be overridden by derived classes to implement
  // sequence-specific transaction generation behavior.

  extern task body();

endclass : rp_sequence_base


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS: rp_sequence_base
//
// Base implementation of the shared sequence utilities.
//
//-----------------------------------------------------------------------------


// new
// ---

function rp_sequence_base::new(string name = "rp_sequence_base");
  super.new(name);
endfunction : new

// seq_print
// ---------

function void rp_sequence_base::seq_print(string msg);
  `uvm_info(get_type_name(), msg, UVM_MEDIUM)
endfunction

// pre_body
// --------

task rp_sequence_base::pre_body();
  seq_print("Entered sequence pre_body");
  req = ITEM_T::type_id::create("req");
endtask

// body
// ----
//
// Emits a fatal message when a derived sequence forgets to override body().

task rp_sequence_base::body();
  `uvm_fatal("BODY", "APB_BASE_SEQ - Base sequence's body is not implemented and must be overriden")
endtask : body
