//------------------------------------------------------------------------------
// Module: ucie_sideband_mux
// Description: ...
//------------------------------------------------------------------------------
module ucie_sideband_mux
(//---- PORT DECLARATIONS -----------------------------------------------------
  input  wire                   i_a
  ,input  wire                  i_b
  ,input  wire                  i_sel
  ,output wire                  o_c
);

  //---- COMBINATIONAL LOGIC ---------------------------------------------------
  assign o_c = (i_sel)  ? i_a : i_b;

endmodule