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
// CLASS: rmblink_driver
//
// ...
//
//-----------------------------------------------------------------------------

class rmblink_driver extends rp_driver_base #(rmblink_seq_item, virtual rp_rmblink_bfm);
  `uvm_component_utils(rmblink_driver)


  // Function: new
  //
  // Creates a new rmblink_driver instance with the given name and parent.

  extern function new(string name, uvm_component parent);


  // Task: drive_item
  //
  // ...

  extern virtual task drive_item(inout rmblink_seq_item req, output rmblink_seq_item rsp);

endclass : rmblink_driver


//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS: rmblink_driver
//
//-----------------------------------------------------------------------------


// new
// ---

function rmblink_driver::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new

// drive_item
// -----

task rmblink_driver::drive_item(inout rmblink_seq_item req, output rmblink_seq_item rsp);
  if (req.rp_opmode == CLK_PATTERN) begin // CLK_PATTERN
    @(posedge bfm.clk);
    bfm.serialize_clk_pattern(
       ._clk_stream_p(req.clk_stream_p)
      ,._clk_stream_n(req.clk_stream_n)
      ,._track_stream(req.track_stream)
      ,._idle_ui_cnt(req.idle_ui_cnt)
    );
  end else if (req.rp_opmode == VAL_PATTERN) begin // VAL_PATTERN
    @(posedge bfm.clk);
    bfm.serialize_valid_pattern(
       ._val_stream(req.val_stream)
      ,._clk_stream_p(req.clk_stream_p)
      ,._clk_stream_n(req.clk_stream_n)
      ,._track_stream(req.track_stream)
    );
  end else begin // DATA_PATTERN or ACTIVE
    if (req.is_first_data_pat) begin
      @(posedge bfm.clk);
    end
    if (req.rp_opmode == ACTIVE) begin
      if (bfm.i_rx_encoding !== ACTIVE) begin
        wait(bfm.i_rx_encoding === ACTIVE);
      end
    end
    bfm.serialize_data(
       ._data(req.data)
      ,._val_stream(req.val_stream)
      ,._clk_stream_p(req.clk_stream_p)
      ,._clk_stream_n(req.clk_stream_n)
      ,._track_stream(req.track_stream)
      ,._idle_ui_cnt(req.idle_ui_cnt)
    );
  end
endtask : drive_item
