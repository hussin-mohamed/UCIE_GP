module clk_valid_pattern_generation_tb (
    
);
    bit        i_valid;       // Valid input signal
    bit        i_dclk;        // Half-rate clock input
    logic       i_no_data;     // No data mode (used for idle pattern)
    logic        i_halfrate;    // Mode select: 1 = half-rate, 0 = quarter-rate
    logic        i_reset;       // reset for the clock divider
    logic [1:0]  i_pattern_type;// Pattern type selector
    logic        o_clk_p;         // Gated output clock phase 1
    logic        o_clk_n;       // Gated output clock phase 2
    logic        o_valid;       // Gated output valid
    logic        o_track;        // Track signal (mirrors output clock)

    clk_valid_pattern_generation dut(
        .i_no_data(i_no_data),
        .i_dclk(i_dclk),
        .i_halfrate(i_halfrate),
        .i_reset(i_reset),
        .i_pattern_type(i_pattern_type),
        .o_clk_p(o_clk_p),
        .o_clk_n(o_clk_n),
        .o_valid(o_valid),
        .o_track(o_track)
    );

    initial begin
        fork
            begin
                forever begin
                    #1;
                    i_dclk = ~i_dclk;
                end
            end
            begin
                forever begin
                    #4;
                    i_valid = ~i_valid;
                end
            end
        join
    end

    initial begin
        i_reset =1;
        i_halfrate =1;
        i_pattern_type=2'b11;
        @(posedge i_dclk);
        i_reset =0;
        i_no_data = 1'b1;
        repeat (24)
        @(posedge i_dclk);
        i_no_data = 1'b0;
        repeat (24)
        @(posedge i_dclk);

        i_pattern_type=2'b00;
        repeat (25)
        @(posedge i_dclk);

        i_pattern_type=2'b01;
        repeat (100)
        @(posedge i_dclk);

        i_pattern_type=2'b10;
        repeat (24)
        @(posedge i_dclk);

        i_reset =1;
        i_halfrate =0;
        
        @(posedge i_dclk);
        i_reset =0;
        i_pattern_type=2'b11;
        i_no_data = 1'b1;
        repeat (24)
        @(posedge i_dclk);
        i_no_data = 1'b0;
        repeat (24)
        @(posedge i_dclk);
        i_pattern_type=2'b00;
        repeat (24)
        @(posedge i_dclk);

        i_pattern_type=2'b01;
        repeat (300)
        @(posedge i_dclk);

        i_pattern_type=2'b10;
        repeat (24)
        @(posedge i_dclk);
        
        $stop;
    end
endmodule