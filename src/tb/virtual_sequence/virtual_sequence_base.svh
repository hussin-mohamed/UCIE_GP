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
// CLASS: virtual_sequence_base
//
// The virtual_sequence_base class provides a virtual base for virtual sequences
// that coordinate multiple child sequences across different sequencers. It
// maintains handles to child sequencers and their associated sequences.
//
//------------------------------------------------------------------------------



class virtual_sequence_base extends uvm_sequence;
    `uvm_object_utils(virtual_sequence_base)

    virtual_sequencer                    v_seqr;
    rx_fsm_sb_sequencer #(rx_fsm_sb_sequence_item) rx_fsm_sb_seqr;
    tx_fsm_sb_sequencer #(tx_fsm_sb_sequence_item) tx_fsm_sb_seqr;
    LTSM_controllers_sqr #(LTSM_controllers_seq_item) LTSM_ctrl_seqr;


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
    rx_fsm_sb_seqr = v_seqr.rx_seqr;
    tx_fsm_sb_seqr = v_seqr.tx_seqr;
    LTSM_ctrl_seqr = v_seqr.LTSM_ctrl_seqr;
endtask : body