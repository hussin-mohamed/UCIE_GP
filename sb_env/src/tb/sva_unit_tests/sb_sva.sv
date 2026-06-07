
// -------------------------------------------------------------------------
// File: sb_sva.sv
// Description: SVA Checker Interface for UCIe Sideband Block (SVAUnit Ready)
// -------------------------------------------------------------------------
// File: sb_sva.sv

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

  sequence q_succ_pat_det(o_tx_sb_data, pat_detected);
    q_pat_gen(o_tx_sb_data)[*1:$] ##0 pat_detected ##1 q_pat_gen(o_tx_sb_data)[*4];
  endsequence : q_succ_pat_det
endpackage : sb_seq_pkg

interface sb_sva #(
  parameter int PENCODING_WIDTH = 9,
  parameter int PINFO_WIDTH     = 16,
  parameter int PDATA_WIDTH     = 64
)(
  // Clocks remain as ports because they are driven continuously by tb_top
  input logic i_clk,
  input logic clk_800MHz
);
  import sb_seq_pkg::*;

  logic i_reset;

  // LTSM -> Sideband
  logic i_tx_sb_req;
  logic i_tx_sb_rsp;
  logic i_rx_sb_req;
  logic i_rx_sb_rsp;

  logic i_tx_sb_done;
  logic i_rx_sb_done;

  logic [PENCODING_WIDTH-1:0] i_tx_encoding;
  logic [PINFO_WIDTH-1:0]     i_tx_info;
  logic [PDATA_WIDTH-1:0]     i_tx_data;

  logic [PENCODING_WIDTH-1:0] i_rx_encoding;
  logic [PINFO_WIDTH-1:0]     i_rx_info;
  logic [PDATA_WIDTH-1:0]     i_rx_data;

  logic i_timer_1ms;
  logic i_sb_init_start;

  logic i_rx_sb_data;
  bit i_rx_sb_clk;

  // Sideband -> LTSM 
  logic [PENCODING_WIDTH-1:0] o_tx_decoding;
  logic [PINFO_WIDTH-1:0]     o_tx_info;
  logic [PDATA_WIDTH-1:0]     o_tx_data;
  logic                       o_tx_valid;

  logic [PENCODING_WIDTH-1:0] o_rx_decoding;
  logic [PINFO_WIDTH-1:0]     o_rx_info;
  logic [PDATA_WIDTH-1:0]     o_rx_data;
  logic                       o_rx_valid;

  logic o_sb_tx_req;
  logic o_sb_tx_rsp;
  logic o_sb_rx_req;
  logic o_sb_rx_rsp;

  logic o_sb_tx_done;
  logic o_sb_rx_done;

  logic o_sb_ready;

  logic o_tx_sb_data;
  logic o_tx_sb_clk;

  bit clk_1x, clk_2x, pat_detected, timeout;
  bit [2:0] tms;

  initial forever #2 clk_1x = ~clk_1x;
  initial forever #1 clk_2x = ~clk_2x;

  always @(negedge i_rx_sb_clk) begin
    wait(q_pat_det(i_rx_sb_data, i_rx_sb_clk).triggered);
    pat_detected = 1;
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

  property p_pat_gen();
    ##1 first_match(q_pat_gen(o_tx_sb_data)[*1:$] ##0 pat_detected ##1 q_pat_gen(o_tx_sb_data)[*4] ##1 @(posedge i_clk) $rose(o_sb_ready));
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
    @(posedge clk_1x iff (tms%2 == 0))
    p_pat_gen()
  ) pat_detected = 0;
  
  ap_pat_low : assert property(
    @(posedge clk_1x)
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
endinterface : sb_sva
