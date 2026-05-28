module rx_LFSR_detection #(
    parameter int pDATA_WIDTH = 64
) (
    input pclk,
    input i_reset,
    input [pDATA_WIDTH-1:0] pattern,
    input [15:0] i_error_threshhold,
    output o_lane_success
);
    localparam pWIDTH = $clog2(pDATA_WIDTH);
    // Internal signals
    wire enable;
    reg [15:0] counter;
    logic [pWIDTH:0] count_ones; // Count of '1's in the pattern

    // Enable detection: check if any bit in pattern is high
    assign enable = | pattern;
    always_comb begin
    count_ones = '0;
    for (int i = 0; i < pDATA_WIDTH; i++) begin
        count_ones = count_ones + pattern[i];
    end
end

    // Counter logic: increment on each valid pattern detection
    always @(posedge pclk or posedge i_reset) begin
        if (i_reset) begin
            counter <= 16'b0;
        end
        else if (enable) begin
            counter <= counter + count_ones; // Increment by the number of '1's in the pattern
        end
    end

    // Output: assert success if error count is within threshold
    assign o_lane_success = (counter <= i_error_threshhold) ? 1'b1 : 1'b0;

endmodule