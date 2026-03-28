`include "../shared_pkg.sv"
import shared_pkg::*;
import uvm_pkg::*;
import svunit_uvm_mock_pkg::*;

`include "svunit_defines.svh"
`include "uvm_macros.svh"
`include "../sequence_items/ltsm_seq_item.svh"
`include "../sequence_items/phylink_seq_item.svh"
`include "../sequence_items/rdi_seq_item.svh"
`include "../sb_utils.svh"
`include "../scoreboard/sb_pred_ltsm2link.svh"

// Helper macro to easily compare unpacked phylink_seq_item fields
`define FAIL_UNLESS_PHY_EQUAL(ACT, EXP) \
  `FAIL_UNLESS_EQUAL(ACT.fullcode, EXP.fullcode) \
  `FAIL_UNLESS_EQUAL(ACT.opcode, EXP.opcode) \
  `FAIL_UNLESS_EQUAL(ACT.srcid, EXP.srcid) \
  `FAIL_UNLESS_EQUAL(ACT.dstid, EXP.dstid) \
  `FAIL_UNLESS_EQUAL(ACT.info, EXP.info) \
  `FAIL_UNLESS_EQUAL(ACT.data, EXP.data) \
  `FAIL_UNLESS_EQUAL(ACT.cp, EXP.cp) \
  `FAIL_UNLESS_EQUAL(ACT.dp, EXP.dp)

class sb_pred_ltsm2link_uvm_wrapper extends sb_pred_ltsm2link;

  `uvm_component_utils(sb_pred_ltsm2link_uvm_wrapper)
  
  uvm_tlm_analysis_fifo #(phylink_seq_item) out_fifo;

  function new(string name = "sb_pred_ltsm2link_uvm_wrapper", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    out_fifo = new("out_fifo", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    results_ap_phy.connect(out_fifo.analysis_export);
  endfunction
endclass

module sb_pred_ltsm2link_unit_test;
  import svunit_pkg::svunit_testcase;

  string name = "sb_pred_ltsm2link_ut";
  svunit_testcase svunit_ut;

  sb_pred_ltsm2link_uvm_wrapper my_sb_pred_ltsm2link;

  // Test variables
  ltsm_seq_item tx1, tx2, tx3;
  ltsm_seq_item rx1, rx2, rx3;
  phylink_seq_item out1, out2, out3, out4;

  //===================================
  // Build
  //===================================
  function void build();
    svunit_ut = new(name);
    my_sb_pred_ltsm2link = sb_pred_ltsm2link_uvm_wrapper::type_id::create("my_sb_pred_ltsm2link", null);
    svunit_deactivate_uvm_component(my_sb_pred_ltsm2link);
  endfunction

  //===================================
  // Setup
  //===================================
  task setup();
    svunit_ut.setup();
    
    // Initialize TX items
    tx1 = ltsm_seq_item::type_id::create("tx1"); 
    tx1.set_tx_encoding(SBINIT_TX_Out_Of_Reset_MSG);     
    
    tx2 = ltsm_seq_item::type_id::create("tx2"); 
    tx2.set_tx_encoding(MBINIT_PARAM_TX_Config_Handshake); 
    
    tx3 = ltsm_seq_item::type_id::create("tx3"); 
    tx3.set_tx_encoding(SBINIT_TX_Done_Handshake);         
    
    // Initialize RX items
    rx1 = ltsm_seq_item::type_id::create("rx1"); 
    rx1.set_rx_encoding(SBINIT_RX_Done_Handshake);         
    
    rx2 = ltsm_seq_item::type_id::create("rx2"); 
    rx2.set_rx_encoding(MBINIT_PARAM_RX_Send_RESP);        
    
    rx3 = ltsm_seq_item::type_id::create("rx3"); 
    rx3.set_rx_encoding(SBINIT_RX_Done_Handshake);         

    svunit_activate_uvm_component(my_sb_pred_ltsm2link);
    svunit_uvm_test_start();
  endtask

  //===================================
  // Teardown
  //===================================
  task teardown();
    svunit_ut.teardown();
    svunit_uvm_test_finish();
    svunit_deactivate_uvm_component(my_sb_pred_ltsm2link);
  endtask

  //===================================
  // SVUNIT TESTS
  //===================================
  `SVUNIT_TESTS_BEGIN

    //---------------------------------------------------------
    // Test 1: get_predicted_item (SBINIT_TX_Out_Of_Reset_MSG)
    //---------------------------------------------------------
    `SVTEST(get_predicted_item_tx_out_of_reset_test)
      tx1.info = 16'hAAAA;
      tx1.data = 64'h0;
      
      out1 = my_sb_pred_ltsm2link.get_predicted_item(tx1);
      
      `FAIL_UNLESS_EQUAL(out1.fullcode, SBINIT_out_of_Reset)
      `FAIL_UNLESS_EQUAL(out1.opcode, MSG_WO_DATA)
      `FAIL_UNLESS_EQUAL(out1.srcid, SRC_PHY)
      `FAIL_UNLESS_EQUAL(out1.dstid, DST_PHY)
      `FAIL_UNLESS_EQUAL(out1.info, 16'hAAAA)
      `FAIL_UNLESS_EQUAL(out1.data, 64'h0)
      
      // Verify dynamically calculated parity
      `FAIL_UNLESS_EQUAL(out1.cp, ^{out1.dstid, out1.info, out1.fullcode, out1.srcid, out1.opcode})
      `FAIL_UNLESS_EQUAL(out1.dp, ^out1.data)
    `SVTEST_END

    //---------------------------------------------------------
    // Test 2: get_predicted_item (SBINIT_TX_Done_Handshake)
    //---------------------------------------------------------
    `SVTEST(get_predicted_item_tx_done_handshake_test)
      tx3.info = 16'h5555;
      tx3.data = 64'h0;
      
      out3 = my_sb_pred_ltsm2link.get_predicted_item(tx3);
      
      `FAIL_UNLESS_EQUAL(out3.fullcode, SBINIT_done_req)
      `FAIL_UNLESS_EQUAL(out3.opcode, MSG_WO_DATA)
      `FAIL_UNLESS_EQUAL(out3.srcid, SRC_PHY)
      `FAIL_UNLESS_EQUAL(out3.dstid, DST_PHY)
      `FAIL_UNLESS_EQUAL(out3.info, 16'h5555)
      `FAIL_UNLESS_EQUAL(out3.data, 64'h0)
      
      // Verify dynamically calculated parity
      `FAIL_UNLESS_EQUAL(out3.cp, ^{out3.dstid, out3.info, out3.fullcode, out3.srcid, out3.opcode})
      `FAIL_UNLESS_EQUAL(out3.dp, ^out3.data)
    `SVTEST_END

    //---------------------------------------------------------
    // Test 3: get_predicted_item (MBINIT_PARAM_TX_Config_Handshake)
    //---------------------------------------------------------
    `SVTEST(get_predicted_item_tx_config_handshake_test)
      tx2.info = 16'h1234;
      tx2.data = 64'h11112222_33334444;
      
      out2 = my_sb_pred_ltsm2link.get_predicted_item(tx2);
      
      `FAIL_UNLESS_EQUAL(out2.fullcode, MBINIT_PARAM_configuration_req)
      `FAIL_UNLESS_EQUAL(out2.opcode, MSG_W_64B_DATA)
      `FAIL_UNLESS_EQUAL(out2.srcid, SRC_PHY)
      `FAIL_UNLESS_EQUAL(out2.dstid, DST_PHY)
      `FAIL_UNLESS_EQUAL(out2.info, 16'h1234)
      `FAIL_UNLESS_EQUAL(out2.data, 64'h11112222_33334444)
      
      // Verify dynamically calculated parity
      `FAIL_UNLESS_EQUAL(out2.cp, ^{out2.dstid, out2.info, out2.fullcode, out2.srcid, out2.opcode})
      `FAIL_UNLESS_EQUAL(out2.dp, ^out2.data)
    `SVTEST_END

    //---------------------------------------------------------
    // Test 4: get_predicted_item multiplexing for RX Item
    //---------------------------------------------------------
    `SVTEST(get_predicted_item_rx_mux_test)
      rx1.info = 16'hFFFF;
      rx1.data = 64'h0;
      
      out1 = my_sb_pred_ltsm2link.get_predicted_item(rx1);
      
      // Proves the NOP_TX logic cleanly routed to rx_messages
      `FAIL_UNLESS_EQUAL(out1.fullcode, SBINIT_done_resp)
      `FAIL_UNLESS_EQUAL(out1.info, 16'hFFFF)
      
      // Verify dynamically calculated parity
      `FAIL_UNLESS_EQUAL(out1.cp, ^{out1.dstid, out1.info, out1.fullcode, out1.srcid, out1.opcode})
      `FAIL_UNLESS_EQUAL(out1.dp, ^out1.data)
    `SVTEST_END

    //---------------------------------------------------------
    // Test 5: Drain TX items only
    //---------------------------------------------------------
    `SVTEST(tx_only_drain_test)
      my_sb_pred_ltsm2link.axp_in_tx.write(tx1);
      my_sb_pred_ltsm2link.axp_in_tx.write(tx2);
      
      #10;
      
      `FAIL_IF(my_sb_pred_ltsm2link.out_fifo.used() != 2)
      
      my_sb_pred_ltsm2link.out_fifo.get(out1);
      my_sb_pred_ltsm2link.out_fifo.get(out2);
      
      `FAIL_UNLESS_PHY_EQUAL(out1, my_sb_pred_ltsm2link.get_predicted_item(tx1))
      `FAIL_UNLESS_PHY_EQUAL(out2, my_sb_pred_ltsm2link.get_predicted_item(tx2))
    `SVTEST_END

    //---------------------------------------------------------
    // Test 6: Drain RX items only
    //---------------------------------------------------------
    `SVTEST(rx_only_drain_test)
      my_sb_pred_ltsm2link.axp_in_rx.write(rx1);
      my_sb_pred_ltsm2link.axp_in_rx.write(rx2);
      
      #10;
      
      `FAIL_IF(my_sb_pred_ltsm2link.out_fifo.used() != 2)
      
      my_sb_pred_ltsm2link.out_fifo.get(out1);
      my_sb_pred_ltsm2link.out_fifo.get(out2);
      
      `FAIL_UNLESS_PHY_EQUAL(out1, my_sb_pred_ltsm2link.get_predicted_item(rx1))
      `FAIL_UNLESS_PHY_EQUAL(out2, my_sb_pred_ltsm2link.get_predicted_item(rx2))
    `SVTEST_END

    //---------------------------------------------------------
    // Test 7: TX and RX Alternation (Start with TX)
    //---------------------------------------------------------
    `SVTEST(tx_rx_alternation_test)
      my_sb_pred_ltsm2link.axp_in_tx.write(tx1);
      my_sb_pred_ltsm2link.axp_in_rx.write(rx1);
      my_sb_pred_ltsm2link.axp_in_tx.write(tx2);
      my_sb_pred_ltsm2link.axp_in_rx.write(rx2);
      
      #10;
      
      `FAIL_IF(my_sb_pred_ltsm2link.out_fifo.used() != 4)
      
      my_sb_pred_ltsm2link.out_fifo.get(out1);
      my_sb_pred_ltsm2link.out_fifo.get(out2);
      my_sb_pred_ltsm2link.out_fifo.get(out3);
      my_sb_pred_ltsm2link.out_fifo.get(out4);

      `FAIL_UNLESS_PHY_EQUAL(out1, my_sb_pred_ltsm2link.get_predicted_item(tx1))
      `FAIL_UNLESS_PHY_EQUAL(out2, my_sb_pred_ltsm2link.get_predicted_item(rx1))
      `FAIL_UNLESS_PHY_EQUAL(out3, my_sb_pred_ltsm2link.get_predicted_item(tx2))
      `FAIL_UNLESS_PHY_EQUAL(out4, my_sb_pred_ltsm2link.get_predicted_item(rx2))
    `SVTEST_END

    //---------------------------------------------------------
    // Test 8: Unbalanced Alternation (TX Heavy: 2 TX, 1 RX)
    //---------------------------------------------------------
    `SVTEST(unbalanced_alternation_tx_heavy_test)
      my_sb_pred_ltsm2link.axp_in_tx.write(tx1);
      my_sb_pred_ltsm2link.axp_in_rx.write(rx1);
      my_sb_pred_ltsm2link.axp_in_tx.write(tx2);
      
      #10;
      
      `FAIL_IF(my_sb_pred_ltsm2link.out_fifo.used() != 3)
      
      my_sb_pred_ltsm2link.out_fifo.get(out1);
      my_sb_pred_ltsm2link.out_fifo.get(out2);
      my_sb_pred_ltsm2link.out_fifo.get(out3);

      `FAIL_UNLESS_PHY_EQUAL(out1, my_sb_pred_ltsm2link.get_predicted_item(tx1))
      `FAIL_UNLESS_PHY_EQUAL(out2, my_sb_pred_ltsm2link.get_predicted_item(rx1))
      `FAIL_UNLESS_PHY_EQUAL(out3, my_sb_pred_ltsm2link.get_predicted_item(tx2))
    `SVTEST_END

    //---------------------------------------------------------
    // Test 9: Unbalanced Alternation (RX Heavy: 1 TX, 2 RX)
    //---------------------------------------------------------
    `SVTEST(unbalanced_alternation_rx_heavy_test)
      my_sb_pred_ltsm2link.axp_in_tx.write(tx1);
      my_sb_pred_ltsm2link.axp_in_rx.write(rx1);
      my_sb_pred_ltsm2link.axp_in_rx.write(rx2); 
      
      #10;
      
      `FAIL_IF(my_sb_pred_ltsm2link.out_fifo.used() != 3)
      
      my_sb_pred_ltsm2link.out_fifo.get(out1);
      my_sb_pred_ltsm2link.out_fifo.get(out2);
      my_sb_pred_ltsm2link.out_fifo.get(out3);

      `FAIL_UNLESS_PHY_EQUAL(out1, my_sb_pred_ltsm2link.get_predicted_item(tx1))
      `FAIL_UNLESS_PHY_EQUAL(out2, my_sb_pred_ltsm2link.get_predicted_item(rx1))
      `FAIL_UNLESS_PHY_EQUAL(out3, my_sb_pred_ltsm2link.get_predicted_item(rx2))
    `SVTEST_END

  `SVUNIT_TESTS_END

endmodule