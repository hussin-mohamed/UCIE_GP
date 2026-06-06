module pattern_generation_decoder (
    input [1:0] i_pattern_type,
    input i_empty,
    input i_done,
    input i_active,
    input i_clk,
    output logic o_no_data
);
    logic no_data ;
    logic no_data_reg ;
    always @(*) begin
        case (i_pattern_type)
        2'b00: o_no_data = 1'b1;
        2'b01: o_no_data = 1'b0;
        2'b10: o_no_data = 1'b0;
        default: begin
            if (i_empty) begin
                begin
                    if (i_done)
                     o_no_data= 1'b1;
                     else
                     o_no_data = no_data_reg;
                end
            end
            else begin
                o_no_data = no_data_reg;
            end
        end
    endcase
    end
    
    always @(posedge i_clk ) begin
        if (!i_empty) begin
            no_data_reg <= 0;
        end
        else begin
            no_data_reg <= o_no_data;
        end
    end
endmodule