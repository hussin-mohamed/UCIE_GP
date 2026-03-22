//------------------------------------------------------------------------------
// Module: ucie_sideband_demux
// Description: ...
//------------------------------------------------------------------------------
module ucie_sideband_demux
(//---- PORT DECLARATIONS -----------------------------------------------------
  input  wire                   i_a
  ,input  wire                  i_sel
  ,output wire                  o_b
  ,output wire                  o_c
);

  //---- COMBINATIONAL LOGIC ---------------------------------------------------
  assign o_b = (i_sel)  ? i_a  : 1'b0;
  assign o_c = (i_sel)  ? 1'b0 : i_a;
endmodule