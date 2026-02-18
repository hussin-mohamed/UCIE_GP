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
// CLASS: scoreboard_base
//
// The scoreboard_base class provides a parameterized base implementation for 
// scoreboards in UVM testbenches. It includes analysis ports for receiving
// input and output transactions, automatic comparison capabilities using
// uvm_comparer, and built-in error tracking with summary reporting.
//
// Type Parameters:
//   ITEM_IN_T  - Transaction type for input stream
//   ITEM_OUT_T - Transaction type for output stream (may be same as ITEM_IN_T)
//
//------------------------------------------------------------------------------

class scoreboard_base extends uvm_scoreboard;
    `uvm_component_utils(scoreboard_base #(ITEM_IN_T, ITEM_OUT_T))

    // Analysis infrastructure
    // (Export <-> FIFO) for transactions fed to the block as input transactions
    uvm_analysis_export #(ITEM_IN_T) expt_in;
    uvm_tlm_analysis_fifo #(ITEM_IN_T) fifo_in;
    // (Export <-> FIFO) for transactions produced by the block as output transactions
    uvm_analysis_export #(ITEM_OUT_T) expt_out;
    uvm_tlm_analysis_fifo #(ITEM_OUT_T) fifo_out;

    // Transaction handles
    // Transactions received by the driver and the monitor
    ITEM_IN_T  item_in, item_in_copy;
    ITEM_OUT_T item_out, item_out_copy;
    ITEM_OUT_T item_ref;

    // Statistics tracking
    // Error and correct counts
    bit match;
    int error_count, correct_count;
    int total_count = correct_count + error_count;
    real pass_rate;
    string summary_msg;
    string status_msg;
    uvm_severity test_severity;
    
    // UVM Comparer
    uvm_comparer comparer;
    

    // Function: new
    //
    // Creates a new scoreboard_base instance with the given name and parent.

    extern function new(string name = "scoreboard_base", uvm_component parent = null);


    // Function: build_phase
    //
    // Creates the analysis exports and TLM FIFOs for input and output transaction
    // streams during the build phase.

    extern virtual function void build_phase(uvm_phase phase);


    // Function: connect_phase
    //
    // Connects the analysis exports to their corresponding FIFO analysis exports
    // to establish the transaction flow paths.

    extern virtual function void connect_phase(uvm_phase phase);


    // Function: report_phase
    //
    // Calculates test statistics and generates a comprehensive test summary report
    // including pass/fail status, transaction counts, and pass rate percentage.

    extern function void report_phase(uvm_phase phase);


    // Function: compare
    //
    // Compares the output transaction against the reference transaction using
    // the UVM comparer. Updates error_count on mismatch, correct_count on match.
    // Prints mismatch details when comparison fails.

    extern virtual function void compare();

endclass : scoreboard_base


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- scoreboard_base
//
//------------------------------------------------------------------------------


// new
// ---

function scoreboard_base::new(string name = "scoreboard_base", uvm_component parent = null);
    super.new(name, parent);
endfunction : new

// build_phase
// -----------

function void scoreboard_base::build_phase(uvm_phase phase);
    super.build_phase(phase);
    expt_in = new("expt_in", this);
    fifo_in = new("fifo_in", this);
    expt_out = new("expt_out", this);
    fifo_out = new("fifo_out", this);
endfunction : build_phase

// connect_phase
// -------------

function void scoreboard_base::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    expt_in.connect(fifo_in.analysis_export);
    expt_out.connect(fifo_out.analysis_export);
endfunction : connect_phase

// report_phase
// ------------

function void scoreboard_base::report_phase(uvm_phase phase);
    super.report_phase(phase);

    // Calculate totals
    total_count = correct_count + error_count;
    pass_rate = (total_count > 0) ? (real'(correct_count) / real'(total_count)) * 100.0 : 0.0;
    
    // Determine test status
    if (error_count == 0) begin
        status_msg = "PASSED";
        test_severity = UVM_INFO;
    end else begin
        status_msg = "FAILED";
        test_severity = UVM_ERROR;
    end
    
    // Build summary message
    summary_msg = {
        "\n",
        "===============================================\n",
        $sformatf("     TEST SUMMARY REPORT - %s\n", this.get_name()),
        "===============================================\n",
        $sformatf("Test Status       : %s\n", status_msg),
        $sformatf("Total Transactions: %0d\n", total_count),
        $sformatf("Correct Count     : %0d\n", correct_count),
        $sformatf("Error Count       : %0d\n", error_count),
        $sformatf("Pass Rate         : %.2f%%\n", pass_rate),
        "===============================================\n"
    };
    
    // Display summary
    `uvm_info("TEST_SUMMARY", summary_msg, UVM_LOW)
    
    // Final status message
    if (error_count == 0) begin
        `uvm_info("TEST_RESULT", "*** TEST PASSED ***", UVM_LOW)
    end else begin
        `uvm_error("TEST_RESULT", $sformatf("*** TEST FAILED with %0d errors ***", error_count))
    end
endfunction : report_phase

// compare
// -------

function void scoreboard_base::compare();
    match = item_out_copy.compare(item_ref, comparer);

    // Get detailed comparison with differences printed
    if (!match) begin
        `uvm_info("COMPARE", $sformatf("Miscompares: %0d", comparer.result), UVM_LOW)
        error_count++;
    end else begin
        correct_count++;
    end        
endfunction : compare
