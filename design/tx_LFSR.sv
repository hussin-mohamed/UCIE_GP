module tx_LFSR #(
    parameter int pLANE_ID_SEED = 23'h1DBFBC,
    parameter int pDATA_WIDTH = 32
) (
    input iclk,i_enable,i_load,i_train,
    input [pDATA_WIDTH-1:0] i_data_in,
    output [pDATA_WIDTH-1:0]o_data_out
);
    wire pclk;
    wire [pDATA_WIDTH-1:0] scrambled_data,pattern_out;
    assign pclk = i_clk & i_enable ;
    assign scrambled_data = pattern_out ^ i_data_in ;
    always @(*) begin
        if(!i_train)begin
            o_data_out=scrambled_data;
        end
        else begin
            o_data_out=pattern_out;
        end
    end
    LFSR_pattern_generator #(
        .pLANE_ID_SEED (pLANE_ID_SEED[i])
    ) gen(
        .plck(plck),
        .i_load(i_load),
        .pattern(pattern_out)
    );
endmodule