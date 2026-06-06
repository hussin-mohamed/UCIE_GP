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
// CLASS: LTSM_coverage
//
// The LTSM_coverage class extends uvm_subscriber to collect functional coverage
// on LTSM transactions. It defines covergroups for transaction types, addresses,
// data values, and their cross-coverage combinations.
//
//------------------------------------------------------------------------------

class LTSM_coverage extends uvm_subscriber #(LTSM_sequence_item);
    `uvm_component_utils(LTSM_coverage)  
 
    


    // Function: new
    //
    // Creates a new LTSM_coverage instance and instantiates the covergroup.

    extern function new(string name = "LTSM_coverage", uvm_component parent = null);


    // Function: write
    //
    // Analysis port write method that samples the covergroup for each received
    // LTSM transaction.

    extern virtual function void write(LTSM_sequence_item t);

endclass : LTSM_coverage


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- LTSM_coverage
//
//------------------------------------------------------------------------------


// new
// ---

function LTSM_coverage::new(string name = "LTSM_coverage", uvm_component parent = null);
    super.new(name, parent);
    LTSM_cg = new();
endfunction : new

// write
// -----

function void LTSM_coverage::write(LTSM_sequence_item t);
    LTSM_cg.sample(t);
endfunction : write
