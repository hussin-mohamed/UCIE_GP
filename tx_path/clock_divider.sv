module clock_divider (
    input i_clk,i_enable,i_reset,
    output logic o_clk
);
    always_ff @( posedge i_clk or posedge i_reset) begin 
        if(i_reset)begin
            o_clk=0;
        end
        else if (i_enable)begin
            o_clk=~o_clk;
        end
    end
endmodule