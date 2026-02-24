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

class scoreboard extends uvm_scoreboard;
    `uvm_component_utils(scoreboard)
    FSMContext cntxt;
    // Analysis infrastructure
    // (Export <-> FIFO) for transactions fed to the block as controllers transactions
    uvm_analysis_export #(LTSM_controllers_sequence_item) ap_controllers_in;
    uvm_tlm_analysis_fifo #(LTSM_controllers_sequence_item) fifo_controllers_in;
    // (Export <-> FIFO) for transactions produced by the block as rdi transactions
    uvm_analysis_export #(LTSM_rdi_sequence_item) ap_rdi_in;
    uvm_tlm_analysis_fifo #(LTSM_rdi_sequence_item) fifo_rdi_in;
    // (Export <-> FIFO) for transactions produced by the block as rx FSM sideband transactions
    uvm_analysis_export #(rx_fsm_sb_sequence_item) ap_rx_fsm_sb_in;
    uvm_tlm_analysis_fifo #(rx_fsm_sb_sequence_item) fifo_rx_fsm_sb_in;
    // (Export <-> FIFO) for transactions produced by the block as tx FSM sideband transactions
    uvm_analysis_export #(tx_fsm_sb_sequence_item) ap_tx_fsm_sb_in;
    uvm_tlm_analysis_fifo #(tx_fsm_sb_sequence_item) fifo_tx_fsm_sb_in;


     uvm_analysis_export #(LTSM_controllers_sequence_item) ap_controllers_out;
    uvm_tlm_analysis_fifo #(LTSM_controllers_sequence_item) fifo_controllers_out;
    // (Export <-> FIFO) for transactions produced by the block as rdi transactions
    uvm_analysis_export #(LTSM_rdi_sequence_item) ap_rdi_out;
    uvm_tlm_analysis_fifo #(LTSM_rdi_sequence_item) fifo_rdi_out;
    // (Export <-> FIFO) for transactions produced by the block as rx FSM sideband transactions
    uvm_analysis_export #(rx_fsm_sb_sequence_item) ap_rx_fsm_sb_out;
    uvm_tlm_analysis_fifo #(rx_fsm_sb_sequence_item) fifo_rx_fsm_sb_out;
    // (Export <-> FIFO) for transactions produced by the block as tx FSM sideband transactions
    uvm_analysis_export #(tx_fsm_sb_sequence_item) ap_tx_fsm_sb_out;
    uvm_tlm_analysis_fifo #(tx_fsm_sb_sequence_item) fifo_tx_fsm_sb_out;

    // Transaction handles
    // Transactions received by the driver and the monitor
    LTSM_controllers_sequence_item item_controllers_in,item_controllers_out;
    ltsm_rdi_sequence_item item_rdi_in,item_rdi_out;
    rx_fsm_sb_sequence_item item_rx_fsm_sb_in,item_rx_fsm_sb_out;
    tx_fsm_sb_sequence_item item_tx_fsm_sb_in,item_tx_fsm_sb_out;
    // Statistics tracking
    // Error and correct counts
    bit match;
    int error_count, correct_count;
    int total_count = correct_count + error_count;
    real pass_rate;
    string summary_msg;
    string status_msg;
    uvm_severity test_severity;
    
    

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

    extern virtual function void run_phase();

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
    ab_controllers_in = new("ab_controllers_in", this);
    fifo_controllers_in = new("fifo_controllers_in", this);
    ap_rdi_in = new("ap_rdi_in", this);
    fifo_rdi_in = new("fifo_rdi_in", this);
    ap_rx_fsm_sb_in = new("ap_rx_fsm_sb_in", this);
    fifo_rx_fsm_sb_in = new("fifo_rx_fsm_sb_in", this);
    ap_tx_fsm_sb_in = new("ap_tx_fsm_sb_in", this);
    fifo_tx_fsm_sb_in = new("fifo_tx_fsm_sb_in", this);
    ap_controllers_out = new("ap_controllers_out", this);
    fifo_controllers_out = new("fifo_controllers_out", this);
    ap_rdi_out = new("ap_rdi_out", this);
    fifo_rdi_out = new("fifo_rdi_out", this);
    ap_rx_fsm_sb_out = new("ap_rx_fsm_sb_out", this);
    fifo_rx_fsm_sb_out = new("fifo_rx_fsm_sb_out", this);
    ap_tx_fsm_sb_out = new("ap_tx_fsm_sb_out", this);
    fifo_tx_fsm_sb_out = new("fifo_tx_fsm_sb_out", this);
    cntxt = new(reset::instance());
endfunction : build_phase

// connect_phase
// -------------

function void scoreboard_base::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    ab_controllers_in.connect(fifo_controllers_in.analysis_export);
    ap_rdi_in.connect(fifo_rdi_in.analysis_export);
    ap_rx_fsm_sb_in.connect(fifo_rx_fsm_sb_in.analysis_export);
    ap_tx_fsm_sb_in.connect(fifo_tx_fsm_sb_in.analysis_export);
    ab_controllers_out.connect(fifo_controllers_out.analysis_export);
    ap_rdi_out.connect(fifo_rdi_out.analysis_export);
    ap_rx_fsm_sb_out.connect(fifo_rx_fsm_sb_out.analysis_export);
    ap_tx_fsm_sb_out.connect(fifo_tx_fsm_sb_out.analysis_export);
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

function void scoreboard_base::run_phase();
    super.run_phase();
    forever begin
        fifo_controllers_in.get(item_controllers_in);
        fifo_rdi_in.get(item_rdi_in);
        fifo_rx_fsm_sb_in.get(item_rx_fsm_sb_in);
        fifo_tx_fsm_sb_in.get(item_tx_fsm_sb_in);
        fifo_controllers_out.get(item_controllers_out);
        fifo_rdi_out.get(item_rdi_out);
        fifo_rx_fsm_sb_out.get(item_rx_fsm_sb_out);
        fifo_tx_fsm_sb_out.get(item_tx_fsm_sb_out);
        goldenmodel();

        match = cntxt.doAction(item_controllers_in, item_rdi_in, item_rx_fsm_sb_in, item_tx_fsm_sb_in, item_controllers_out, item_rdi_out, item_rx_fsm_sb_out, item_tx_fsm_sb_out);
        if (match) begin
            correct_count++;
        end else begin
            error_count++;
        end
    end
endfunction : run_phase
