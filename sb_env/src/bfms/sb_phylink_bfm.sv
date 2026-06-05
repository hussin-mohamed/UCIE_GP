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
import sb_shared_pkg::*;
import uvm_pkg::*;


// Interface: sb_phylink_bfm
// Description: Serial Sideband communication interface with partner UCIe die
//              (MDI - Module Die Interface)
//******************************************************************************

interface sb_phylink_bfm(
  input logic clk
 ,input logic clk_800MHz
 ,input logic reset
 ,input logic o_sb_ready
);
    
  bit pat_detected;

  bit [2:0] tms;
  bit timeout;

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

  logic start;
  bit is_first_iteration;
  
  sequence q_pat_det(d, clk);
    @(negedge clk) (d ##1 !d)[*64];
  endsequence : q_pat_det

  always @(negedge o_tx_sb_clk) begin
    wait(q_pat_det(o_tx_sb_data, o_tx_sb_clk).triggered);
    pat_detected = 1;
  end

  always @(negedge o_sb_ready) begin
    pat_detected = 0;
  end

  always_comb begin
    if (tms%2) begin
      i_rx_sb_data <= 0;
      i_rx_sb_clk  <= 0;
    end
  end

  //============================================================================
  // Methods
  //============================================================================
  task clear();
    i_rx_sb_data <= 0;
    i_rx_sb_clk  <= 0;
    is_first_iteration = 1;
  endtask : clear

  task serialize_pattern(
    input logic [63:0] _pattern,
    input int          _idle_ui_cnt,
    input int          _delay_ui_cnt
  );

    if (_idle_ui_cnt < 32) begin
      `uvm_fatal("PHYLINK_BFM", $sformatf("Invalid idle_ui_cnt: %0d, valid count range: 32 UI or more", _idle_ui_cnt))
    end
    // $display("%0t: xxxxxxxxxxxxxxxxxxxxxxx", $time);
    if (is_first_iteration) begin
    // $display("%0t: ffffffffffffffff, %0d", $time, start);
      @(posedge start);
    // $display("%0t: yyyyyyyyyyyyyyyyyyyyyy", $time);
      @(posedge clk);
    // $display("%0t: zzzzzzzzzzzzzzzzzzzzzzzzz", $time);
      is_first_iteration = 0;
    end

    // $display("%0t: llllllllllllllllllllllllll", $time);
    if (_delay_ui_cnt != 0) begin
    // $display("%0t: mmmmmmmmmmmmmmmmmmmmm, clk_800MHz = %0d, _delay_ui_cnt = %0d", $time, clk_800MHz, _delay_ui_cnt);
      // repeat(10) @(posedge clk_800MHz);
    // $display("%0t: nnnnnnnnnnnnnnnnnnnnnnnnn", $time);
    end
    // 64 UI Pattern Phase
    for (int i = 0; i < 64; i++) begin
      @(posedge clk_800MHz iff (tms%2 == 0));
      // $display("%0t: oooooooooooooooooooooo", $time);
      i_rx_sb_data <= _pattern[i];
      i_rx_sb_clk  <= 1'b1; // Strobe high

      @(negedge clk_800MHz iff (tms%2 == 0));
      i_rx_sb_clk  <= 1'b0; // Strobe low
    end

    @(posedge clk_800MHz iff (tms%2 == 0));

    // _idle_ui_cnt UI Low Phase
    i_rx_sb_data <= 1'b0;
    i_rx_sb_clk  <= 1'b0;
    
    // Wait for _idle_ui_cnt UI
    repeat(_idle_ui_cnt-1) @(posedge clk_800MHz iff (tms%2 == 0));
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

        @(posedge clk_800MHz);
        i_rx_sb_data <= _data[bit_idx];
        i_rx_sb_clk  <= 1'b1; // Strobe high

        @(negedge clk_800MHz);
        i_rx_sb_clk  <= 1'b0; // Strobe low
      end

      @(posedge clk_800MHz);

      // _idle_ui_cnt UI Low Phase
      i_rx_sb_data <= 1'b0;
      i_rx_sb_clk  <= 1'b0;
      
      // Wait for _idle_ui_cnt UI
      repeat(_idle_ui_cnt) @(posedge clk_800MHz);
    end
  endtask : serialize_data

  task deserialize_data_out(output logic [127:0] _data);
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
    end else begin
      _data[127:64] = 0;
    end
  endtask : deserialize_data_out

  task deserialize_data_in(output logic [127:0] _data);
    opcode_t opcode;

    @(posedge i_rx_sb_clk);

    for (int i = 0; i < 64; i++) begin
      @(negedge i_rx_sb_clk);
      _data[i] = i_rx_sb_data;
    end

    opcode = opcode_t'(_data[4:0]);


    if (opcode == MSG_W_64B_DATA) begin
      @(posedge i_rx_sb_clk);

      for (int i = 0; i < 64; i++) begin
        @(negedge i_rx_sb_clk);
        _data[i+64] = i_rx_sb_data;
      end
    end else begin
      _data[127:64] = 0;
    end
  endtask : deserialize_data_in
endinterface : sb_phylink_bfm
