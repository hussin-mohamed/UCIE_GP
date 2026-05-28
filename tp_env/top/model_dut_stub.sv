//=============================================================================
// File       : model_dut_stub.sv
// Description: Model-as-DUT stub. Calls the duplicated tx_predictor to
//              drive the physical tx2link output lanes.
//=============================================================================

`timescale 1ns/1ps

module model_dut_stub #(
  parameter NBYTES = 256,
  parameter DATA_WIDTH = 64,
  parameter LANES_NUMBER = 16
) (
  input  logic        clk,
  input  logic        ui_clk,
  input  logic        rst,
  
  // From RDI Interface
  input  logic [NBYTES-1:0][7:0] lp_data,
  input  logic        lp_valid,
  input  logic        lp_irdy,
  output logic        pl_trdy,
  
  // From LTSM Interface
  input  logic [8:0]  tx_encoding, // ltsm_encoding_e is a 9-bit logic under the hood
  input  logic [2:0]  lane_map,
  output logic        pll_stable,
  output logic        supply_stable,
  output logic        tx_done,
  
  // To TX2LINK Interface
  output logic        tx_data [0:15],
  output logic        tx_clkp,
  output logic        tx_clkn,
  output logic        tx_valid,
  output logic        tx_track
);

  // Import the duplicated predictor package explicitly
  import dut_tx_controller_modelling_pkg::*;
  import dut_tx_tb_pkg::*;

  // -------------------------------------------------------------------------
  //  RDI & LTSM Stub Outputs
  // -------------------------------------------------------------------------
  assign pl_trdy = 1'b1;
  
  initial begin
    pll_stable = 1'b0;
    supply_stable = 1'b0;
    tx_done = 1'b0;
    #50;
    pll_stable = 1'b1;
    supply_stable = 1'b1;
  end

  // Simulate tx_done handshaking
  always @(tx_encoding) begin
    tx_done = 1'b0;
    #20;
    tx_done = 1'b1;
    #10;
    tx_done = 1'b0;
  end

  // -------------------------------------------------------------------------
  //  Physical Side-bands
  // -------------------------------------------------------------------------
  assign tx_clkp = 1'bz;
  assign tx_clkn = 1'bz;
  assign tx_valid = 1'bz;
  assign tx_track = 1'bz;

  // -------------------------------------------------------------------------
  //  Predictor execution
  // -------------------------------------------------------------------------
  logic [DATA_WIDTH-1:0] o_lane [0:LANES_NUMBER-1];
  logic [7:0] unpacked_lp_data [0:NBYTES-1];

  // Controller state instance for DUT stub
  tx_controller_state_t ctrl_state;

  always_comb begin
    for (int i=0; i<NBYTES; i++) begin
      unpacked_lp_data[i] = lp_data[i];
    end
  end

  // Initialize controller state at time zero
  initial begin
    tx_controller_state_init(ctrl_state);
  end

  // Run duplicated predictor on posedge clk so o_lane is stable
  // before the serializer reads it at posedge ui_clk
  always @(posedge clk) begin
    dut_tx_predictor::predict(
      ctrl_state,
      rst,
      tx_encoding,
      lane_map,
      1'b0,
      unpacked_lp_data,
      o_lane
    );
  end

  // -------------------------------------------------------------------------
  //  Serializer (Time-major output)
  //  Shifts out o_lane[lane][ui_cnt] one bit per ui_clk, 64 cycles per chunk
  // -------------------------------------------------------------------------
  int ui_cnt = 0;
  int xd = 0;


  
  always @(posedge ui_clk) begin

      foreach (o_lane[lane]) begin
        if (o_lane[lane] || o_lane[lane] === 'bx) begin
          xd = 1;
        end else begin
          xd = 0;
        end
      end

    if (rst) begin
      ui_cnt <= 0;
      for (int i=0; i<LANES_NUMBER; i++) begin
        tx_data[i] <= 1'bz;
      end
    end else if (xd) begin 
      for (int i=0; i<LANES_NUMBER; i++) begin
        tx_data[i] <= o_lane[i][ui_cnt];
      end
      
      if (ui_cnt == DATA_WIDTH - 1)
        ui_cnt <= 0;
      else
        ui_cnt <= ui_cnt + 1;
    end
  end
  

endmodule
