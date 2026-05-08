module reversal #(
    parameter int pDATA_WIDTH = 32,
    parameter int pNUM_LANES  = 16
) (
    input  logic                                     sel,
    input  logic [pNUM_LANES-1:0][pDATA_WIDTH-1:0]  i_lanes,
    output logic [pNUM_LANES-1:0][pDATA_WIDTH-1:0]  o_lanes
);
    genvar i;
    generate
        for (i = 0; i < pNUM_LANES; i++) begin : mux_gen
            assign o_lanes[i] = mux(i_lanes[i],i_lanes[pNUM_LANES-1-i],sel);
        end
    endgenerate

    function logic [pDATA_WIDTH-1:0] mux (input logic [pDATA_WIDTH-1:0] a,b, input logic sel);
        mux= sel ? b : a;
        return mux;
    endfunction

endmodule
