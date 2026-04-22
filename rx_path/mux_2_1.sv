module mux_2_1 #(
    parameter int pDATA_WIDTH = 32,
    parameter int pNUM_LANES  = 16
) (
    input  logic      sel,
    input  logic [pNUM_LANES-1:0][pDATA_WIDTH-1:0]      a,
    input  logic [pNUM_LANES-1:0][pDATA_WIDTH-1:0]      b,
    output logic [pNUM_LANES-1:0][pDATA_WIDTH-1:0]     y
);
    assign y = sel ? b : a;
endmodule