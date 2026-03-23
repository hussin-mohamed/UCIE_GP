module rx_LFSR_detection #(
    parameter int pDATA_WIDTH = 32
) (
    input pclk,i_reset_n,
    input [pDATA_WIDTH-1:0] pattern,
    input [15:0] i_error_threshhold,
    output o_lane_success
);
    wire enable;
    reg [15:0] counter;
    assign enable = | pattern;
    always @(posedge pclk or negedge i_reset_n ) begin
        if (!i_reset_n) begin
            counter<=0;
        end
        else if (enable) begin
            counter<=counter+1;
        end
    end
    assign o_lane_success=(counter<i_error_threshhold)?1'b1:1'b0;
endmodule