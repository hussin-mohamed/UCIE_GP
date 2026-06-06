module PLL_model (
    input [2:0] i_sel,
    input i_clk_32,i_clk_24,i_clk_16,i_clk_12,i_clk_8,i_clk_4,i_reset,
    output logic o_clk_s, o_clk_h,o_clk_l,
    output logic [12:0] o_sim_cycles_8,o_sim_cycles_4,o_sim_cycles_1,o_sim_cycles_1_us,o_sim_cycles_2_us
);
    parameter  CYCLES = 1000; 
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
    always_comb begin : blockName
        case (i_sel)
            3'b000: o_sim_cycles_8 = CYCLES;
            3'b001: o_sim_cycles_8 = CYCLES*2;
            3'b010: o_sim_cycles_8 = CYCLES*3;
            3'b011: o_sim_cycles_8 = CYCLES*4;
            3'b100: o_sim_cycles_8 = CYCLES*6;
            3'b101: o_sim_cycles_8 = CYCLES*8;
            default: o_sim_cycles_8 = CYCLES; // Default to the lowest frequency clock
        endcase
    end
    assign o_sim_cycles_4 = o_sim_cycles_8 / 2;
    assign o_sim_cycles_1 = o_sim_cycles_8 / 8;
    assign o_sim_cycles_1_us = o_sim_cycles_8 / 8000;
    assign o_sim_cycles_2_us = o_sim_cycles_8 /4000;
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

