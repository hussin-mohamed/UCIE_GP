module rx_LFSR #(
    parameter int pLANE_ID_SEED = 23'h1DBFBC,
    parameter int pDATA_WIDTH = 32,
) (
    input iclk,i_enable,i_reset_n,i_load,i_train,
    input [pDATA_WIDTH-1:0] i_data_in,
    input [15:0] i_error_threshhold,
    output o_lane_success,
    output [pDATA_WIDTH-1:0]o_data_out
);
    wire pclk;
    wire [pDATA_WIDTH-1:0] scrambled_data,pattern_out,pattern_tobechecked;
    assign pclk = i_clk & i_enable & o_lane_success ;
    assign scrambled_data = pattern_out ^ i_data_in ;
    always @(*) begin
        if(!i_train)begin
            pattern_tobechecked=scrambled_data;
            o_data_out=0;
        end
        else begin
            o_data_out=scrambled_data;
            pattern_tobechecked=0;
        end
    end
    LFSR_pattern_generator
    #(
        .pLANE_ID_SEED (pLANE_ID_SEED[i])
    ) gen(
        .plck(plck),
        .i_load(i_load),
        .pattern(pattern_out)
    );
    rx_LFSR_detection det (
        .pclk(pclk),
        .i_reset_n(i_reset_n),
        .pattern(pattern_tobechecked),
        .i_error_threshhold(i_error_threshhold),
        .o_lane_success(o_lane_success)
    );
endmodule