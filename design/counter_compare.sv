module counter_compare
  #(
    parameter pDATA_WIDTH = 32
  )
  (
    input pclk,                    // Clock input
    input i_reset,               // Active-low reset
    input counter_reset,           // Counter reset signal
    input [pDATA_WIDTH-1:0] pattern, // Pattern to compare against
    input [pDATA_WIDTH-1:0] i_data_in, // Input data to compare
    output o_laneid_success        // Lane ID success flag (MSB of counter)
);
    // Internal signals
    wire reset;
    reg [4:0] counter;
    
    // Combinational logic
    assign o_laneid_success = counter[4];           // Output MSB of counter
    //assign reset = i_reset_n & counter_reset;       // Combined reset signal
    
    // Sequential logic - counter increment
    always @(posedge pclk or posedge i_reset) begin
        if (i_reset) begin
            counter <= 5'b0;                        // Asynchronous reset
        end
        else if ((|(pattern ^ i_data_in)))begin
            counter <= 5'b0;                        // Reset counter if pattern matches input
        end
        else begin
            counter <= counter + 1;                 // Increment counter
        end
    end
endmodule