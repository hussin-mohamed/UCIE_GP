
// -------------------------------------------------------------------------
// File: rp_sva.sv
// Description: SVA Checker Interface for UCIe RX-Path Block (SVAUnit Ready)
// -------------------------------------------------------------------------
// File: rp_sva.sv

package rp_seq_pkg;
  sequence valid_pn(untyped _clkp, untyped _clkn , untyped _valid);
    @(posedge _clkp) (_valid == 1'b1) @(posedge _clkn) (_valid == 1'b1) @(posedge _clkp) (_valid == 1'b1) @(posedge _clkn) (_valid == 1'b1) 
    @(posedge _clkp) (_valid == 1'b0) @(posedge _clkn) (_valid == 1'b0) @(posedge _clkp) (_valid == 1'b0) @(posedge _clkn) (_valid == 1'b0);
  endsequence : valid_pn
endpackage : rp_seq_pkg

interface rp_sva #(
   
)(
  // Clocks
   input logic clk
  ,input logic i_hclk
  ,input logic i_dclk
  ,input logic reset

  // Reset
  ,input logic i_reset

  // rmblink inputs
  ,input logic                  i_clk_p;
  ,input logic                  i_clk_n;
  ,input logic                  i_track;
  ,input logic [pNUM_LANES-1:0] i_data;
  ,input logic                  i_valid;
);
  import rp_seq_pkg::*;

  // ============================================================================
  // Helper signals (NOT from RTL — internal to SVA checker)
  // ============================================================================
   pattern_type_t pattern_type;
   bit pat_detected;

  // ============================================================================
  // Properties & Assertions
  // ============================================================================
  /*property p_pat_low();
    (!o_tx_sb_data)[*1:$] ##0 (tms%2 == 0);
  endproperty : p_pat_low*/

  valid_pattern_p : assert property(
    @(posedge i_dclk)
     disable iff(i_reset || (pattern_type != VAL_PATTERN))
     $rose(i_valid) |=> @(posedge i_clk_p) (); 
  );

  

  always_comb
    if (i_reset) begin
        chk_async_reset: assert final (
          {
            
          } == '0
        );
    end


endinterface : rp_sva
