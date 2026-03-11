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

`include "uvm_macros.svh"
import shared_pkg::*;
import uvm_pkg::*;


// Interface: sb_phylink_bfm
// Description: Serial sideband communication interface with partner UCIe die
//              (MDI - Module Die Interface)
//******************************************************************************

interface sb_phylink_bfm(
  input logic clk
 ,input logic reset
 ,input logic o_sb_ready
);
    
  bit clk_ser;

  initial begin
    forever begin
      #1 clk_ser = ~clk_ser;
    end
  end

  //============================================================================
  // From Partner Die Signals (Inputs to DUT)
  //============================================================================
  logic i_rx_sb_data;      // Serial data from partner
  logic i_rx_sb_clk;       // Serial clock from partner

  //============================================================================
  // To Partner Die Signals (Outputs from DUT)
  //============================================================================
  logic o_tx_sb_data;      // Serial data to partner
  logic o_tx_sb_clk;       // Serial clock to partner

  //============================================================================
  // Methods
  //============================================================================
  task serialize_pattern(
    input logic [63:0] _pattern,
    input int          _idle_ui_cnt
  );
    if (_idle_ui_cnt < 32) begin
      `uvm_fatal("PHYLINK_BFM", $sformatf("Invalid idle_ui_cnt: %0d, valid count range: 32 UI or more", _idle_ui_cnt))
    end
      
    // 64 UI Pattern Phase
    for (int i = 0; i < 64; i++) begin
      @(posedge clk_ser);
      i_rx_sb_data = _pattern[i];
      i_rx_sb_clk  = 1'b1; // Strobe high

      @(negedge clk_ser);
      i_rx_sb_clk  = 1'b0; // Strobe low
    end

    @(posedge clk_ser);

    // _idle_ui_cnt UI Low Phase
    i_rx_sb_data = 1'b0;
    i_rx_sb_clk  = 1'b0;
    
    // Wait for _idle_ui_cnt UI
    repeat(_idle_ui_cnt) @(posedge clk_ser);
  endtask : serialize_pattern

  task serialize_data(
    input logic [127:0] _data,
    input int           _idle_ui_cnt
  );
    opcode_t opcode;
    int      num_pkt;
    int      bit_idx;

    if (_idle_ui_cnt < 32) begin
      `uvm_fatal("PHYLINK_BFM", $sformatf("Invalid idle_ui_cnt: %0d, valid count range: 32 UI or more", _idle_ui_cnt))
    end

    opcode = opcode_t'(_data[4:0]);

    // Number of 64-bit packets
    num_pkt = (opcode == MSG_W_64B_DATA)? 2 : 1;

    for (int pkt = 0; pkt < num_pkt; pkt++) begin
      
      // 64 UI Data Phase
      for (int i = 0; i < 64; i++) begin
        bit_idx = (pkt * 64) + i; // Offset by 64 bits for the second packet

        @(posedge clk_ser);
        i_rx_sb_data = _data[bit_idx];
        i_rx_sb_clk  = 1'b1; // Strobe high

        @(negedge clk_ser);
        i_rx_sb_clk  = 1'b0; // Strobe low
      end

      @(posedge clk_ser);

      // _idle_ui_cnt UI Low Phase
      i_rx_sb_data = 1'b0;
      i_rx_sb_clk  = 1'b0;
      
      // Wait for _idle_ui_cnt UI
      repeat(_idle_ui_cnt) @(posedge clk_ser);
    end
  endtask : serialize_data

  task deserialize_data(output logic [127:0] _data);
    opcode_t opcode;

    @(posedge o_tx_sb_clk);

    for (int i = 0; i < 64; i++) begin
      @(negedge o_tx_sb_clk);
      _data[i] = o_tx_sb_data;
    end

    opcode = opcode_t'(_data[4:0]);


    if (opcode == MSG_W_64B_DATA) begin
      @(posedge o_tx_sb_clk);

      for (int i = 0; i < 64; i++) begin
        @(negedge o_tx_sb_clk);
        _data[i+64] = o_tx_sb_data;
      end
    end
  endtask : deserialize_data
endinterface : sb_phylink_bfm