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
// CLASS: sb_cmp_base
//
// Description: ...
//---------------------------------------------------------------------------

class sb_cmp_base #(type ITEM_T = uvm_sequence_item, string cmp_name = "sb_cmp") extends uvm_component;
  `uvm_component_param_utils(sb_cmp_base#(ITEM_T, cmp_name))

  uvm_analysis_export #(ITEM_T) axp_in_exp;
  uvm_analysis_export #(ITEM_T) axp_out_actual;

  uvm_tlm_analysis_fifo #(ITEM_T) expfifo;
  uvm_tlm_analysis_fifo #(ITEM_T) outfifo;

  int VECT_CNT, PASS_CNT, ERROR_CNT;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    axp_in_exp     = new("axp_in_exp", this);
    axp_out_actual = new("axp_out_actual", this);
    expfifo        = new("expfifo", this);
    outfifo        = new("outfifo", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    axp_in_exp.connect(expfifo.analysis_export);
    axp_out_actual.connect(outfifo.analysis_export);
  endfunction

  task run_phase(uvm_phase phase);
    ITEM_T exp_tr, out_tr;
    uvm_comparer comparer;
    string error_msg;

    super.run_phase(phase);

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
        PASS();
      end
    end
  endtask : run_phase

  function void PASS();
    VECT_CNT++;
    PASS_CNT++;
  endfunction : PASS
  
  function void ERROR();
    VECT_CNT++;
    ERROR_CNT++;
  endfunction : ERROR

  function void report_phase(uvm_phase phase); 
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
endclass
