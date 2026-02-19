/***********************************************************************
 * Author : Amr El Batarny
 * File   : virtual_sequence_base.svh
 * Brief  : Base class for virtual sequences providing infrastructure
 *          for managing multiple child sequencers.
 * Note   : Documentation comments generated with AI assistance using
 *          the same format found in UVM source code.
 **********************************************************************/

//------------------------------------------------------------------------------
//
// CLASS: virtual_sequence_base
//
// The virtual_sequence_base class provides a virtual base for virtual sequences
// that coordinate multiple child sequences across different sequencers. It
// maintains handles to child sequencers and their associated sequences.
//
//------------------------------------------------------------------------------

typedef class APB_reactive_sequence_1;
typedef class APB_reactive_sequence_2;

class virtual_sequence_base extends uvm_sequence;
    `uvm_object_utils(virtual_sequence_base)

    virtual_sequencer                    v_seqr;
    APB_sequencer #(APB_sequence_item_1) apb_seqr_1;
    APB_sequencer #(APB_sequence_item_2) apb_seqr_2;

    APB_reactive_sequence_1 apb_seq_1;
    APB_reactive_sequence_2 apb_seq_2;


    // Function: new
    //
    // Creates a new virtual_sequence_base instance with the given name.

    extern function new(string name = "virtual_sequence_base");


    // Task: body
    //
    // Retrieves virtual sequencer handle and extracts child sequencer references
    // for use by derived sequence implementations.

    extern task body();

endclass : virtual_sequence_base


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- virtual_sequence_base
//
//------------------------------------------------------------------------------


// new
// ---

function virtual_sequence_base::new(string name = "virtual_sequence_base");
    super.new(name);
endfunction : new

// body
// ----

task virtual_sequence_base::body();
    $cast(v_seqr, m_sequencer);
    apb_seqr_1 = v_seqr.apb_seqr_1;
    apb_seqr_2 = v_seqr.apb_seqr_2;
endtask : body