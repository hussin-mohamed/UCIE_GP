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

//---------------------------------------------------------------------------
//
// CLASS: rp_cmp_base
//
// Generic scoreboard comparator base class that aligns expected and actual
// transactions, applies timeout handling, and reports pass/fail statistics.
//
//---------------------------------------------------------------------------

virtual class rp_cmp_base #(type ITEM_T = uvm_sequence_item, string cmp_name = "rp_cmp") extends uvm_component;
  `uvm_component_param_utils(rp_cmp_base#(ITEM_T, cmp_name))

  uvm_analysis_export #(ITEM_T) axp_in_exp;
  uvm_analysis_export #(ITEM_T) axp_out_actual;

  uvm_tlm_analysis_fifo #(ITEM_T) expfifo;
  uvm_tlm_analysis_fifo #(ITEM_T) outfifo;

  int VECT_CNT, PASS_CNT, ERROR_CNT;

  bit  txn_timeout;
  time max_allowable_latency;

  // Function: new
  //
  // Creates the comparator component.

  extern function new(string name, uvm_component parent);

  // Function: build_phase
  //
  // Constructs the analysis exports and the backing FIFOs.

  extern virtual function void build_phase(uvm_phase phase);

  // Function: connect_phase
  //
  // Connects the analysis exports to the expected and actual FIFOs.

  extern virtual function void connect_phase(uvm_phase phase);

  // Task: pre_reset_phase
  //
  // Flushes pending expected and actual items before the next run starts.

  extern virtual task pre_reset_phase(uvm_phase phase);

  // Function: set_timeout_val
  //
  // Computes the maximum latency allowed for a given expected item.

  pure virtual function void set_timeout_val(ITEM_T item);
    
  // Task: main_phase
  //
  // Compares each expected item against the corresponding actual item and
  // handles timeout, pass, and mismatch reporting.

  extern virtual task main_phase(uvm_phase phase);

  // Function: PASS
  //
  // Updates the pass-side accounting counters.

  extern function void PASS();
  
  // Function: ERROR
  //
  // Updates the error-side accounting counters.

  extern function void ERROR();

  // Function: report_phase
  //
  // Prints the final comparator statistics at the end of simulation.

  extern function void report_phase(uvm_phase phase);
endclass

//---------------------------------------------------------------------------
// IMPLEMENTATION
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
//
// CLASS: rp_cmp_base
//
//---------------------------------------------------------------------------

// new
// ---

function rp_cmp_base::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction

// build_phase
// -----------

function void rp_cmp_base::build_phase(uvm_phase phase);
  super.build_phase(phase);
  axp_in_exp     = new("axp_in_exp", this);
  axp_out_actual = new("axp_out_actual", this);
  expfifo        = new("expfifo", this);
  outfifo        = new("outfifo", this);
endfunction

// connect_phase
// -------------

function void rp_cmp_base::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  axp_in_exp.connect(expfifo.analysis_export);
  axp_out_actual.connect(outfifo.analysis_export);
endfunction

// pre_reset_phase
// ---------------

task rp_cmp_base::pre_reset_phase(uvm_phase phase);
  super.pre_reset_phase(phase);
  
  // Flush the FIFOs to prevent items of the old run from failing the next simulation run
  expfifo.flush();
  outfifo.flush();
endtask : pre_reset_phase

// main_phase
// ----------

task rp_cmp_base::main_phase(uvm_phase phase);
  ITEM_T exp_tr, out_tr;
  uvm_comparer comparer;
  string error_msg, pass_msg;
  bit get_exp_only;

  super.main_phase(phase);

  // Initialize and configure the UVM comparer
  comparer = new();
  
  // Force the comparer to evaluate all fields instead of stopping at the first mismatch
  comparer.show_max = 100; 


  forever begin
    expfifo.get(exp_tr);
    outfifo.get(out_tr);

    // Pass the custom comparer policy to the compare() method
    if (!out_tr.compare(exp_tr, comparer)) begin
      $display();
      $display();
      // Build the error message using string concatenation
      error_msg = {
        "\nTransaction Mismatch Detected!\n\n",
        "------------------------------------------------------------\n",
        "EXPECTED TRANSACTION (From Predictor):\n",
        "------------------------------------------------------------\n",
        exp_tr.sprint(), "\n",
        "------------------------------------------------------------\n",
        "ACTUAL TRANSACTION (From RTL Monitor):\n",
        "------------------------------------------------------------\n",
        out_tr.sprint(), "\n"
      };
      
      `uvm_error(cmp_name, error_msg)
      $display();
      ERROR();
    end else begin
      // Build the pass message showing both transactions
      pass_msg = {
        "\nTransaction Match Detected!\n\n",
        "------------------------------------------------------------\n",
        "EXPECTED TRANSACTION (From Predictor):\n",
        "------------------------------------------------------------\n",
        exp_tr.sprint(), "\n",
        "------------------------------------------------------------\n",
        "ACTUAL TRANSACTION (From RTL Monitor):\n",
        "------------------------------------------------------------\n",
        out_tr.sprint(), "\n"
      };
      
      `uvm_info(cmp_name, pass_msg, UVM_HIGH)
      PASS();
    end
  end
endtask : main_phase

// PASS
// ----

function void rp_cmp_base::PASS();
  VECT_CNT++;
  PASS_CNT++;
endfunction : PASS

// ERROR
// -----

function void rp_cmp_base::ERROR();
  VECT_CNT++;
  ERROR_CNT++;
endfunction : ERROR

// report_phase
// ------------

function void rp_cmp_base::report_phase(uvm_phase phase); 
  super.report_phase(phase);

  if (VECT_CNT && !ERROR_CNT)
    `uvm_info(get_type_name(),
    $sformatf("\n\n\n*** TEST PASSED - %0d vectors ran, %0d vectors passed ***\n",
               VECT_CNT, PASS_CNT), UVM_LOW)
  else
    `uvm_info(get_type_name(),
    $sformatf("\n\n\n*** TEST FAILED - %0d vectors ran, %0d vectors passed, %0d vectors failed ***\n",
               VECT_CNT, PASS_CNT, ERROR_CNT), UVM_LOW)
endfunction : report_phase
