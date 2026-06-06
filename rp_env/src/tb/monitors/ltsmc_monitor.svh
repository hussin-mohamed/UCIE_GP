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
// CLASS: ltsmc_monitor
//
// RX-Path TX monitor for capturing transactions on the TX interface.
//
//-----------------------------------------------------------------------------

class ltsmc_monitor extends rp_monitor_base #(
   .ITEM_T(ltsmc_seq_item)
  ,.INTF_T(virtual rp_ltsmc_bfm)
  ,.is_reactive(0)
  ,.collect_out(1)
  ,.collect_in(1)
);
  `uvm_component_utils(ltsmc_monitor)


  // Function: new
  //
  // Creates a new ltsmc_monitor instance with the given name and parent.

  extern function new(string name, uvm_component parent);


  // Task: collect_item_out
  //
  // Collects one TX-side item observed at the DUT output interface.

  extern virtual task collect_item_out(output ltsmc_seq_item _item);

  // Task: collect_item_in
  //
  // Collects one TX-side item observed at the DUT input interface.

  extern virtual task collect_item_in(output ltsmc_seq_item _item);

endclass : ltsmc_monitor


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS: ltsmc_monitor
//
//-----------------------------------------------------------------------------


// new
// ---

function ltsmc_monitor::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new

// collect_item_out
// ----------------

task ltsmc_monitor::collect_item_out(output ltsmc_seq_item _item);
  _item = new();

  do begin
    @(bfm.i_rx_encoding);
  end while (bfm.i_rx_encoding !== MBINIT_REVERSAL_RX_Init_Handshake        &&       
             bfm.i_rx_encoding !== MBINIT_REPAIRMB_RX_Init_Handshake        &&       
             bfm.i_rx_encoding !== MBTRAIN_DATAVREF_RX_Start_Handshake      &&         
             bfm.i_rx_encoding !== MBTRAIN_DTC1_RX_Start_Handshake          &&     
             bfm.i_rx_encoding !== MBTRAIN_DATATRAINVREF_RX_Start_Handshake &&               
             bfm.i_rx_encoding !== MBTRAIN_DTC2_RX_Start_Handshake          &&     
             bfm.i_rx_encoding !== MBTRAIN_LINKSPEED_RX_Start_Handshake);

  if (bfm.i_rx_encoding == MBINIT_REVERSAL_RX_Init_Handshake) begin
    do begin
      @(bfm.i_rx_encoding);
    end while (bfm.i_rx_encoding !== MBINIT_REVERSAL_RX_Result_Handshake);
  end else begin
    do begin
      @(bfm.i_rx_encoding);
    end while (bfm.i_rx_encoding !== Data_To_Clock_test_RX_Result_Handshake_TX_Init &&
               bfm.i_rx_encoding !== Data_To_Clock_test_RX_Result_Handshake_RX_Init);
  end
  
  @(posedge bfm.clk);
  _item.lane_map_code   = bfm.i_lane_map_code;
  _item.rx_encoding     = bfm.i_rx_encoding;
  _item.error_threshold = bfm.i_error_threshold;
  _item.half_rate       = bfm.i_half_rate;
  _item.rx_data_results = bfm.o_rx_data_results;
endtask : collect_item_out

// collect_item_in
// ----------------

task ltsmc_monitor::collect_item_in(output ltsmc_seq_item _item);
  _item = new();
  @(bfm.i_rx_encoding);
  @(posedge bfm.clk);
  _item.lane_map_code   = bfm.i_lane_map_code;
  _item.rx_encoding     = bfm.i_rx_encoding;
  _item.error_threshold = bfm.i_error_threshold;
  _item.half_rate       = bfm.i_half_rate;
endtask : collect_item_in
