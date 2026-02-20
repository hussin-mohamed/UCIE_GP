/***********************************************************************
 * Author : Amr El Batarny
 * File   : APB_sequence_base.svh
 * Brief  : Parameterized base class for APB sequences providing common
 *          sequence infrastructure and utility methods.
 * Note   : Documentation comments generated with AI assistance using
 *          the same format found in UVM source code.
 **********************************************************************/

//------------------------------------------------------------------------------
//
// CLASS: APB_sequence_base
//
// The APB_sequence_base class provides a parameterized base implementation
// for APB sequences. It includes request/response handles, print utilities,
// and enforces implementation of the body() task in derived classes.
//
// Type Parameters:
//   ITEM_T - Transaction item type for the sequence
//
//------------------------------------------------------------------------------

class APB_sequence_base #(type ITEM_T) extends uvm_sequence #(ITEM_T);
    `uvm_object_param_utils(APB_sequence_base #(ITEM_T))

    ITEM_T req, rsp;


    // Function: new
    //
    // Creates a new APB_sequence_base instance with the given name.

    extern function new(string name = "APB_sequence_base");


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

endclass : APB_sequence_base


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- APB_sequence_base
//
//------------------------------------------------------------------------------


// new
// ---

function APB_sequence_base::new(string name = "APB_sequence_base");
    super.new(name);
endfunction : new

// seq_print
// ---------

function void APB_sequence_base::seq_print(string msg);
    `uvm_info(get_type_name(), msg, UVM_MEDIUM)
endfunction

// pre_body
// --------

task APB_sequence_base::pre_body();
    seq_print("Entered sequence pre_body");
    req = ITEM_T::type_id::create("req");
endtask

// body
// ----

task APB_sequence_base::body();
    `uvm_fatal("BODY", "APB_BASE_SEQ - Base sequence's body is not implemented and must be overriden")
endtask : body