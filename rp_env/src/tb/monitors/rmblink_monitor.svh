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

//-----------------------------------------------------------------------------
//
// CLASS: rmblink_monitor
//
// RX-Path rmblink monitor for capturing transactions on the rmblink interface.
//
//-----------------------------------------------------------------------------

class rmblink_monitor extends rp_monitor_base #(
   .ITEM_T(rmblink_seq_item)
  ,.INTF_T(virtual rp_rmblink_bfm)
  ,.is_reactive(0)
  ,.collect_out(0)
  ,.collect_in(1)
);
  `uvm_component_utils(rmblink_monitor)


  // Function: new
  //
  // Creates a new rmblink_monitor instance with the given name and parent.

  extern function new(string name, uvm_component parent);


  // Task: collect_item_out
  //
  // Collects one rmblink item observed at the DUT output interface.

  extern virtual task collect_item_out(output rmblink_seq_item _item);

  // Task: collect_item_in
  //
  // Collects one rmblink item observed at the DUT input interface.

  extern virtual task collect_item_in(output rmblink_seq_item _item);

  // Task: monitor_items_in
  //
  // Overridden monitor_items_in task to handle aborted deserialization.

  extern virtual task monitor_items_in();

endclass : rmblink_monitor


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS: rmblink_monitor
//
//-----------------------------------------------------------------------------


// new
// ---

function rmblink_monitor::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new

// collect_item_out
// ----------------

task rmblink_monitor::collect_item_out(output rmblink_seq_item _item);
  _item = new();
endtask : collect_item_out


// collect_item_in
// ----------------

task rmblink_monitor::collect_item_in(output rmblink_seq_item _item);
  _item = new();
endtask : collect_item_in


// monitor_items_in
// ----------------

task rmblink_monitor::monitor_items_in();
  forever begin
    if (collect_in) begin
      bit success = 0;
      item_in = new();

      // Wait for a valid training or active state
      while (
        bfm.i_rx_encoding != MBINIT_REVERSAL_RX_Per_Lane_ID_Det               &&  
        bfm.i_rx_encoding != Data_To_Clock_test_RX_Pattern_Detection_TX_Init  &&  
        bfm.i_rx_encoding != Data_To_Clock_test_RX_Pattern_Detection_RX_Init  &&  
        bfm.i_rx_encoding != ACTIVE_RX_Active                                     
      ) begin
        @(posedge bfm.clk);
      end

      fork
        begin
          bfm.deserialize_data(
             ._data(item_in.data)
            ,._val_stream(item_in.val_stream)
          );
          success = 1;
        end

        begin
          @(bfm.i_rx_encoding);
        end
      join_any

      disable fork;

      if (success) begin
        in_ap.write(item_in);
        `uvm_info(get_type_name(), $sformatf("MONITORED item_in %s: \n%s", item_in.get_type_name(), item_in.sprint()), UVM_DEBUG)
        txn_in_cnt++;
      end else begin
        `uvm_info(get_type_name(), "deserialize_data was aborted because i_rx_encoding changed. Discarding transaction.", UVM_DEBUG)
      end
    end else begin
      #100;
    end
  end
endtask : monitor_items_in
