module counter_compare  (
    input pclk,                    // Clock input
    input i_reset_n,               // Active-low reset
    input counter_reset,           // Counter reset signal
    output o_laneid_success        // Lane ID success flag (MSB of counter)
);
    // Internal signals
    wire reset;
    reg [4:0] counter;
    
    // Combinational logic
    assign o_laneid_success = counter[4];           // Output MSB of counter
    assign reset = i_reset_n & counter_reset;       // Combined reset signal
    
    // Sequential logic - counter increment
    always @(posedge pclk or negedge reset) begin
        if (!reset) begin
            counter <= 5'b0;                        // Asynchronous reset
        end
        else begin
            counter <= counter + 1;                 // Increment counter
        end
    end
endmodule