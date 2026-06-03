
// -------------------------------------------------------------------------
// File: sb_sva.sv
// Description: SVA Checker Interface for UCIe Sideband Block (SVAUnit Ready)
// -------------------------------------------------------------------------
// File: sb_sva.sv

`timescale 1ns / 1ps

import uvm_pkg::*;
`include "uvm_macros.svh"

package sb_seq_pkg;
  sequence q_clk_tgl(untyped clk);
    ((clk == 1'b1) ##1 (clk == 1'b0))[*64];
  endsequence : q_clk_tgl

  sequence q_clk_low(untyped clk);
    ((clk == 1'b0) ##1 (clk == 1'b0))[*32];
  endsequence : q_clk_low

  sequence q_clk_gen(untyped clk);
    q_clk_tgl(clk) ##1 q_clk_low(clk);
  endsequence : q_clk_gen

  sequence q_pat_gen(d);
    (d ##1 !d)[*32] ##1 (!d)[*32];
  endsequence : q_pat_gen

  sequence q_pat_det(d, clk);
    @(negedge clk) (d ##1 !d)[*64];
  endsequence : q_pat_det
endpackage : sb_seq_pkg

interface sb_sva #(
   parameter int pENCODING_WIDTH = 9
  ,parameter int pINFO_WIDTH     = 16
  ,parameter int pDATA_WIDTH     = 64
)(
  // Clocks
   input logic i_clk
  ,input logic clk_800MHz

  // Reset
  ,input logic i_reset

  // TX path inputs
  ,input logic                       i_tx_sb_req
  ,input logic                       i_tx_sb_rsp
  ,input logic                       i_tx_sb_done
  ,input logic [pENCODING_WIDTH-1:0] i_tx_encoding
  ,input logic [pINFO_WIDTH-1:0]     i_tx_info
  ,input logic [pDATA_WIDTH-1:0]     i_tx_data

  // RX path inputs
  ,input logic                       i_rx_sb_req
  ,input logic                       i_rx_sb_rsp
  ,input logic                       i_rx_sb_done
  ,input logic [pENCODING_WIDTH-1:0] i_rx_encoding
  ,input logic [pINFO_WIDTH-1:0]     i_rx_info
  ,input logic [pDATA_WIDTH-1:0]     i_rx_data

  // LTSM control inputs
  ,input logic i_sb_init_start
  ,input logic i_timer_1ms

  // Physical link inputs
  ,input logic i_rx_sb_data
  ,input logic i_rx_sb_clk

  // TX path outputs
  ,input logic [pENCODING_WIDTH-1:0] o_tx_decoding
  ,input logic [pINFO_WIDTH-1:0]     o_tx_info
  ,input logic [pDATA_WIDTH-1:0]     o_tx_data
  ,input logic                       o_tx_valid

  // RX path outputs
  ,input logic [pENCODING_WIDTH-1:0] o_rx_decoding
  ,input logic [pINFO_WIDTH-1:0]     o_rx_info
  ,input logic [pDATA_WIDTH-1:0]     o_rx_data
  ,input logic                       o_rx_valid

  // Handshake outputs
  ,input logic o_sb_tx_req
  ,input logic o_sb_tx_rsp
  ,input logic o_sb_rx_req
  ,input logic o_sb_rx_rsp
  ,input logic o_sb_tx_done
  ,input logic o_sb_rx_done

  // Status and physical link outputs
  ,input logic o_sb_ready
  ,input logic o_tx_sb_data
  ,input logic o_tx_sb_clk
);
  import sb_seq_pkg::*;

  // ============================================================================
  // Helper signals (NOT from RTL — internal to SVA checker)
  // ============================================================================
  bit clk_2x, pat_detected, timeout;
  bit [2:0] tms;

  initial forever #1 clk_2x = ~clk_2x;

  always @(negedge i_rx_sb_clk) begin
    wait(q_pat_det(i_rx_sb_data, i_rx_sb_clk).triggered);
    pat_detected = 1;
  end

  always @(negedge o_sb_ready) begin
    pat_detected = 0;
  end

  always @(posedge i_clk) begin
    if (i_reset) begin
      tms <= 0;
    end else begin
      if (i_timer_1ms) begin
        tms <= tms + 1;
      end
    end
  end

  always @(posedge i_clk) begin
    if (tms == 7 && i_timer_1ms) begin
      timeout = 1;
    end
  end

  always @(posedge i_sb_init_start) begin
    timeout = 0;
  end

  // ============================================================================
  // Properties & Assertions
  // ============================================================================
  property p_pat_gen();
    ##1 first_match(q_pat_gen(o_tx_sb_data)[*1:$] ##0 pat_detected ##1 q_pat_gen(o_tx_sb_data)[*4] ##1 @(posedge i_clk) ##1 $rose(o_sb_ready));
  endproperty : p_pat_gen

  property p_pat_low();
    (!o_tx_sb_data)[*1:$] ##0 (tms%2 == 0);
  endproperty : p_pat_low

  property p_clk_gen();
    ##1 first_match(q_clk_gen(o_tx_sb_clk)[*1:$] ##0 pat_detected ##1 q_clk_gen(o_tx_sb_clk)[*4]);
  endproperty : p_clk_gen

  property p_clk_low();
    (!o_tx_sb_clk)[*1:$] ##0 (tms%2 == 0);
  endproperty : p_clk_low
  
  ap_pat_gen : assert property(
    @(posedge i_clk)
    disable iff(timeout || i_reset)
    $rose(i_sb_init_start)
    |=>
    @(posedge clk_800MHz iff (tms%2 == 0))
    p_pat_gen()
  ) pat_detected = 0;
  
  ap_pat_low : assert property(
    @(posedge clk_800MHz)
    disable iff(!i_sb_init_start || i_reset)
    ($changed(tms) && (tms%2 != 0))
    |->
    p_pat_low()
  );
  
  ap_clk_gen : assert property (
    @(posedge i_clk)
    disable iff(timeout || i_reset)
    $rose(i_sb_init_start)
    |=>
    @(posedge clk_2x iff (tms%2 == 0))
    p_clk_gen()
  );
  
  ap_clk_low : assert property(
    @(posedge clk_2x)
    disable iff(!i_sb_init_start || i_reset)
    ($changed(tms) && (tms%2 != 0))
    |->
    p_clk_low()
  );

  always_comb
    if (i_reset) begin
        chk_async_reset: assert final (
          {
            o_tx_decoding, 
            o_tx_info, 
            o_tx_data, 
            o_tx_valid, 
            o_rx_decoding, 
            o_rx_info, 
            o_rx_data, 
            o_rx_valid, 
            o_sb_tx_req, 
            o_sb_tx_rsp, 
            o_sb_rx_req, 
            o_sb_rx_rsp, 
            o_sb_tx_done, 
            o_sb_rx_done, 
            o_sb_ready, 
            o_tx_sb_data, 
            o_tx_sb_clk
          } == '0
        );
    end

  // Track the exact simulation time of the last transition
  time last_toggle_time = -1;

  always @(o_tx_sb_clk) begin
    // If the signal toggles again at the exact same simulation time
    if ($time == last_toggle_time) begin
      
      // Use an immediate assertion to flag the failure instantly
      chk_no_clk_glitch: assert(0) else begin
        `uvm_warning("SVA_GLITCH", $sformatf("Zero-time glitch detected on o_tx_sb_clk at time %0t!", $time))
      end
      
    end
    
    // Update the tracker for the next transition
    last_toggle_time = $time;
  end
endinterface : sb_sva
