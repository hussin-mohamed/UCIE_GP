module demux_1_2 #(
    parameter int pDATA_WIDTH = 64,
    parameter int pNUM_LANES  = 16
) (
    input  logic [pNUM_LANES-1:0][pDATA_WIDTH-1:0] din,
    input  logic sel,
    output logic [pNUM_LANES-1:0][pDATA_WIDTH-1:0] y0,
    output logic [pNUM_LANES-1:0][pDATA_WIDTH-1:0] y1
);
    genvar i;
    // y0 is output in case of sel = 0
    // y1 is output in case of sel = 1
    generate
        for (i = 0; i < pNUM_LANES; i++) begin : demux_lane
            assign y0[i] = (~sel) ? din[i] : '0;
            assign y1[i] = ( sel) ? din[i] : '0;
        end
    endgenerate

endmodule