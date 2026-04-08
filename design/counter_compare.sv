module counter_compare  (
    input pclk,i_reset_n,counter_reset,
    output o_laneid_success
);
    wire reset;
    reg [4:0] counter;
    assign o_laneid_success = counter[4];
    assign reset = i_reset_n & counter_reset;
    always @(posedge pclk or negedge reset) begin
        if (!reset) begin
            counter <= 0;
        end
        else begin
            counter <= counter+1;
        end
    end
endmodule