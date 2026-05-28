module counter_compare
  #(
    parameter pDATA_WIDTH = 64
  )
  (
    input pclk,                    // Clock input
    input i_reset,               // Active-low reset
    
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
        else if ((pattern==i_data_in)) begin
            if (counter == 13 || counter == 14 || counter == 15 )begin
                counter<=16;   
            end
            else begin
                counter<=counter+4;
            end
        end
        else if (pattern[15:0]==i_data_in[15:0] && pattern[63:16]!=i_data_in[63:16]) begin
            if (counter==15) begin
                counter<=16;    
            end
            else if (pattern[63:48]==i_data_in[63:48]) begin
            counter<=1;
            end
            else if (pattern[63:32]==i_data_in[63:32]) begin
                counter<=2;
            end
            else if (pattern[63:16]==i_data_in[63:16]) begin
                counter<=3;
            end
            else begin
                counter<=0;
            end
        end
        else if (pattern[31:0]==i_data_in[31:0] && pattern[63:32]!=i_data_in[63:32]) begin
            if (counter==14) begin
                counter<=16;    
            end
            else if (pattern[63:48]==i_data_in[63:48]) begin
            counter<=1;
            end
            else if (pattern[63:32]==i_data_in[63:32]) begin
                counter<=2;
            end
            else if (pattern[63:16]==i_data_in[63:16]) begin
                counter<=3;
            end
            else begin
                counter<=0;
            end
        end
        else if (pattern[47:0]==i_data_in[47:0] && pattern[63:48]!=i_data_in[63:48]) begin
            if (counter==13) begin
                counter<=16;    
            end
            else if (pattern[63:48]==i_data_in[63:48]) begin
            counter<=1;
            end
            else if (pattern[63:32]==i_data_in[63:32]) begin
                counter<=2;
            end
            else if (pattern[63:16]==i_data_in[63:16]) begin
                counter<=3;
            end
            else begin
                counter<=0;
            end
        end
        else if (pattern[63:48]==i_data_in[63:48]) begin
            counter<=1;
        end
        else if (pattern[63:32]==i_data_in[63:32]) begin
            counter<=2;
        end
        else if (pattern[63:16]==i_data_in[63:16]) begin
            counter<=3;
        end
        else begin
            counter<=0;
        end
    end
endmodule