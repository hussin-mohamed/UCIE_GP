module rx_LFSR_detection #(
    parameter int pDATA_WIDTH = 64
) (
    input pclk,
    input i_reset,
    input [pDATA_WIDTH-1:0] pattern,
    input [15:0] i_error_threshhold,
    output o_lane_success
);

    // Internal signals
    wire enable;
    reg [15:0] counter;

    // Enable detection: check if any bit in pattern is high
    assign enable = | pattern;

    // Counter logic: increment on each valid pattern detection
    always @(posedge pclk or posedge i_reset) begin
        if (i_reset) begin
            counter <= 16'b0;
        end
        else if (enable) begin
            counter <= counter + 1'b1;
        end
    end

    // Output: assert success if error count is within threshold
    assign o_lane_success = (counter <= i_error_threshhold) ? 1'b1 : 1'b0;

endmodule