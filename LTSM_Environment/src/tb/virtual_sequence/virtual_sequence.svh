/***********************************************************************
 * Author : Amr El Batarny
 * File   : virtual_sequence.svh
 * Brief  : Parent sequence implementation that coordinates execution of
 *          multiple child APB sequences across different agents.
 * Note   : Documentation comments generated with AI assistance using
 *          the same format found in UVM source code.
 **********************************************************************/

//------------------------------------------------------------------------------
//
// CLASS: virtual_sequence
//
// The virtual_sequence class extends virtual_sequence_base to implement
// coordinated execution of reactive APB sequences on multiple sequencers,
// creating and starting child sequences in sequence.
//
//------------------------------------------------------------------------------

class virtual_sequence extends virtual_sequence_base;
    `uvm_object_utils(virtual_sequence)


    // Function: new
    //
    // Creates a new virtual_sequence instance with the given name.

    extern function new(string name = "virtual_sequence");


    // Task: pre_body
    //
    // Creates instances of child reactive sequences before body execution.

    extern task pre_body();


    // Task: body
    //
    // Retrieves sequencer handles via base class, then starts both reactive
    // sequences on their respective sequencers sequentially.

    extern task body();

endclass : virtual_sequence


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- virtual_sequence
//
//------------------------------------------------------------------------------


// new
// ---

function virtual_sequence::new(string name = "virtual_sequence");
    super.new(name);
endfunction : new

// pre_body
// --------

task virtual_sequence::pre_body();
    apb_seq_1   = APB_reactive_sequence_1::type_id::create("apb_seq_1");
    apb_seq_2   = APB_reactive_sequence_2::type_id::create("apb_seq_2");
endtask

// body
// ----

task virtual_sequence::body();
    super.body();
    apb_seq_1.start(apb_seqr_1);
    apb_seq_2.start(apb_seqr_2);
endtask : body