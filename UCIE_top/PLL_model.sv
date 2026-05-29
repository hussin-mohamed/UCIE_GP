module PLL_model (
    input [2:0] i_sel,
    input i_clk_32,i_clk_24,i_clk_16,i_clk_12,i_clk_8,i_clk_4,i_reset,
    output logic o_clk_s, o_clk_h,o_clk_l
);
    logic clk_S,clk_h;
    always_comb begin
        case (i_sel)
            3'b000: clk_S = i_clk_4;
            3'b001: clk_S = i_clk_8;
            3'b010: clk_S = i_clk_12;
            3'b011: clk_S = i_clk_16;
            3'b100: clk_S = i_clk_24;
            3'b101: clk_S = i_clk_32;
            default: clk_S = i_clk_4; // Default to the lowest frequency clock
        endcase
    end
    clock_divider ch (
        .i_clk(clk_S),
        .i_enable(1'b1), // Always enable the clock divider
        .i_reset(i_reset), 
        .o_clk(clk_h)
    );
    logic clk_d4,clk_d8,clk_d16,clk_d32,clk_d64;

    clock_divider cd4 (
        .i_clk(clk_h),
        .i_enable(1'b1),
        .i_reset(i_reset),
        .o_clk(clk_d4)
    );
    clock_divider cd8 (
        .i_clk(clk_d4),
        .i_enable(1'b1),
        .i_reset(i_reset),
        .o_clk(clk_d8)
    );
    clock_divider cd16 (
        .i_clk(clk_d8),
        .i_enable(1'b1),
        .i_reset(i_reset),
        .o_clk(clk_d16)
    );
    clock_divider cd32 (
        .i_clk(clk_d16),
        .i_enable(1'b1),
        .i_reset(i_reset),
        .o_clk(clk_d32)
    );
    clock_divider cd64 (
        .i_clk(clk_d32),
        .i_enable(1'b1),
        .i_reset(i_reset),
        .o_clk(clk_d64)
    );

    assign o_clk_s = clk_S;
    assign o_clk_h = clk_h;
    assign o_clk_l = clk_d64;
endmodule

