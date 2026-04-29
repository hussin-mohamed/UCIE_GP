module clk_valid_pattern_generation (
    input  logic        i_valid,       // Valid input signal
    input  logic        i_hclk,        // Half-rate clock input
    input  logic        i_halfrate,    // Mode select: 1 = half-rate, 0 = quarter-rate
    input  logic        i_reset,       // reset for the clock divider
    input  logic [1:0]  i_pattern_type,// Pattern type selector
    output logic        o_clk_p,         // Gated output clock phase 1
    output logic        o_clk_n,       // Gated output clock phase 2
    output logic        o_valid,       // Gated output valid
    output logic        o_track        // Track signal (mirrors output clock)
);
    // generating the quadrature with phase difference of 90 degree
    wire w_qclk_1,w_qclk_2;
    clock_divider ca (
        .i_clk(i_hclk),
        .i_enable(1'b1),
        .i_reset(i_reset),
        .o_clk(w_qclk_1)
    );
    clock_divider cb (
        .i_clk(!i_hclk),
        .i_enable(1'b1),
        .i_reset(i_reset),
        .o_clk(w_qclk_2)
    );
    // clock divider by 24 for each half rate clock and quadrature clock

    // half rate clock

    // wire w_hclk_2,w_hclk_4,w_hclk_8,w_hclk_24;

    // wire w_enable_1_h,w_enable_2_h;

    // wire div1_h,div2_h;

    // logic [1:0] counter_h;

    // clock_divider c1 (
    //     .i_clk(i_hclk),
    //     .i_enable(1'b1),
    //     .i_reset(i_reset),
    //     .o_clk(w_hclk_2)
    // );

    // clock_divider c2 (
    //     .i_clk(w_hclk_2),
    //     .i_enable(1'b1),
    //     .i_reset(i_reset),
    //     .o_clk(w_hclk_4)
    // );

    // clock_divider c3 (
    //     .i_clk(w_hclk_4),
    //     .i_enable(1'b1),
    //     .i_reset(i_reset),
    //     .o_clk(w_hclk_8)
    // );

    // always_ff @( posedge h_clk_8 ) begin 
    //     if(i_reset)begin
    //         counter_h <=0;
    //     end
    //     else if (counter_h = 2'b10) begin
    //         counter_h<=0
    //     end
    //     else begin
    //         counter_h <= counter+1;
    //     end
    // end

    // assign w_enable_1_h=(counter_h == 0)?1:0;
    // assign w_enable_2_h=(counter_h == 2)?1:0;

    // clock_divider c4 (
    //     .i_clk(w_hclk_8),
    //     .i_enable(w_enable_1_h),
    //     .i_reset(i_reset),
    //     .o_clk(div1_h)
    // );

    // clock_divider c5 (
    //     .i_clk(!w_hclk_8),
    //     .i_enable(w_enable_2_h),
    //     .i_reset(i_reset),
    //     .o_clk(div2_h)
    // );

    // assign w_hclk_24 = div1_h ^ div2_h;

    // quarter rate clock

    // wire w_qclk_2,w_qclk_4,w_qclk_8,w_qclk_24;

    // wire w_enable_1_q,w_enable_2_q;

    // wire div1_q,div2_q;

    // logic [1:0] counter_q;

    // clock_divider c1 (
    //     .i_clk(i_qclk),
    //     .i_enable(1'b1),
    //     .i_reset(i_reset),
    //     .o_clk(w_qclk_2)
    // );

    // clock_divider c2 (
    //     .i_clk(w_qclk_2),
    //     .i_enable(1'b1),
    //     .i_reset(i_reset),
    //     .o_clk(w_qclk_4)
    // );

    // clock_divider c3 (
    //     .i_clk(w_qclk_4),
    //     .i_enable(1'b1),
    //     .i_reset(i_reset),
    //     .o_clk(w_qclk_8)
    // );

    // always_ff @( posedge h_clk_8 ) begin 
    //     if(i_reset)begin
    //         counter_q <=0;
    //     end
    //     else if (counter_q = 2'b10) begin
    //         counter_q <=0
    //     end
    //     else begin
    //         counter_q <= counter_q+1;
    //     end
    // end

    // assign w_enable_1_q=(counter_q == 0)?1:0;
    // assign w_enable_2_q=(counter_q == 2)?1:0;

    // clock_divider c4 (
    //     .i_clk(w_qclk_8),
    //     .i_enable(w_enable_1_q),
    //     .i_reset(i_reset),
    //     .o_clk(div1_q)
    // );

    // clock_divider c5 (
    //     .i_clk(!w_qclk_8),
    //     .i_enable(w_enable_2_q),
    //     .i_reset(i_reset),
    //     .o_clk(div2_q)
    // );

    // assign w_qclk_24 = div1_q ^ div2_q;

    // this is analog modelling but implemented as pwm so we can verify it but in actualy the clock should be divided by 24 as implemented above and then passed to dll to adjust the duty cycle
    
    
    // pwm to modify the duty cycle of the half rate clock to be 16 cycles high and 8 loww of the original clock

    logic [4:0] counter_h;

    wire w_enable_h;

    always_ff @( posedge i_hclk ) begin 

        if(i_reset)begin

            counter_h<=0;

        end
        else if (counter_h == 23 || i_pattern_type != 2'b01) begin

            counter_h <=0;

        end
        else begin

            counter_h <= counter_h + 1;

        end
    end
    assign w_enable_h=(counter_h<16)?1:0;

    // pwm to modify the duty cycle of the quartere rate clock to be 16 cycles high and 8 loww of the original clock

    logic [4:0] counter_q_1;
    wire w_enable_q_1;
    always_ff @( posedge w_qclk_1 ) begin 
        if(i_reset)begin
            counter_q_1<=0;
        end
        else if (counter_q_1 == 23 || i_pattern_type != 2'b01) begin
            counter_q_1 <=0;
        end
        else begin
            counter_q_1 <= counter_q_1 + 1;
        end
    end
    assign w_enable_q_1=(counter_q_1<16)?1:0;

    logic [4:0] counter_q_2;
    wire w_enable_q_2;
    always_ff @( posedge w_qclk_2 ) begin 
        if(i_reset)begin
            counter_q_2<=0;
        end
        else if (counter_q_2 == 23 || i_pattern_type != 2'b01) begin
            counter_q_2 <=0;
        end
        else begin
            counter_q_2 <= counter_q_2 + 1;
        end
    end
    assign w_enable_q_2=(counter_q_2<16)?1:0;


    // pwm to modify the duty cycle of the result clock to be 16 cycles high and 8 loww of the original clock

    //-------------------------------------------------------------------------
    // Pattern Type Encoding
    //  2'b00 : Valid only      (no clock output)
    //  2'b01 : Clock only      (no valid output)
    //  2'b10 : active          (both enabled)
    //  2'b11 : Idle            (both disabled)
    //-------------------------------------------------------------------------

    // Track mirrors the output clock per UCIe spec
    
    assign o_track = o_clk_p;

    // Clock enable signals for half-rate and quarter-rate paths
    // Valid enable shared across both paths
    // These are intentionally inferred as latches:
    //   - Updated only on the low phase of the active clock
    //   - Hold their value on the high phase (clock gating safe update window)
    logic w_henable;   // Half-rate clock gate enable
    logic w_qenable_1,w_qenable_2;   // Quarter-rate clock gate enable
    logic w_venable;   // Valid gate enable

    //-------------------------------------------------------------------------
    // Enable Generation (Latch-based clock gating)
    // Enables are updated only when the active clock is LOW to ensure
    // glitch-free gating — this is the standard ICG (Integrated Clock Gate)
    // pattern where the enable is sampled on the low phase
    //-------------------------------------------------------------------------
    always @(*) begin

        if (i_halfrate) begin
            w_qenable_1 = 1'b0;
            w_qenable_2 =1'b0;
            // --- Half-Rate Path ---
            // Update enables only when half-rate clock is LOW (safe window)
            if (!i_hclk) begin
                case (i_pattern_type)
                    2'b00: begin
                        // Valid only: suppress clock, pass valid
                        w_henable = 1'b1;
                    end
                    2'b01: begin
                        // Clock only: pass clock, suppress valid
                        w_henable = w_enable_h;
                    end
                    2'b10: begin
                        // Clock + Valid: pass both
                        w_henable = 1'b1;
                    end
                    default: begin
                        // Idle: suppress both
                        w_henable = 1'b0;
                    end
                endcase
            end
            if(!i_valid)begin
                case (i_pattern_type)
                    2'b00: begin
                        // Valid only: suppress clock, pass valid
                        w_venable = 1'b1;
                    end
                    2'b01: begin
                        // Clock only: pass clock, suppress valid
                        w_venable = 1'b0;
                    end
                    2'b10: begin
                        // Clock + Valid: pass both
                        w_venable = 1'b1;
                    end
                    default: begin
                        // Idle: suppress both
                        w_venable = 1'b0;
                    end
                endcase
            end
            // When i_hclk is HIGH: enables hold their latched value (latch transparent on LOW)

            // Gate the half-rate clock with its enable
            o_clk_p = i_hclk & w_henable;
            o_clk_n = ~o_clk_p; // to produce 180 phase difference
        end else begin

            w_henable = 1'b0;
            // --- Quarter-Rate Path ---
            // Update enables only when quarter-rate clock is LOW (safe window)
            if (!w_qclk_1) begin
                case (i_pattern_type)
                    2'b00: begin
                        // Valid only: suppress clock, pass valid
                        w_qenable_1 = 1'b0;
                    end
                    2'b01: begin
                        // Clock only: pass clock, suppress valid
                        w_qenable_1 = w_enable_q_1;
                    end
                    2'b10: begin
                        // Clock + Valid: pass both
                        w_qenable_1 = 1'b1;
                    end
                    default: begin
                        // Idle: suppress both
                        w_qenable_1 = 1'b0;
                    end
                endcase
            end
            if (!w_qclk_2) begin
                case (i_pattern_type)
                    2'b00: begin
                        // Valid only: suppress clock, pass valid
                        w_qenable_2 = 1'b0;
                    end
                    2'b01: begin
                        // Clock only: pass clock, suppress valid
                        w_qenable_2 = w_enable_q_2;
                    end
                    2'b10: begin
                        // Clock + Valid: pass both
                        w_qenable_2 = 1'b1;
                    end
                    default: begin
                        // Idle: suppress both
                        w_qenable_2 = 1'b0;
                    end
                endcase
            end
            // When i_qclk is HIGH: enables hold their latched value (latch transparent on LOW)
            if(!i_valid)begin
                case (i_pattern_type)
                    2'b00: begin
                        // Valid only: suppress clock, pass valid
                        w_venable = 1'b1;
                    end
                    2'b01: begin
                        // Clock only: pass clock, suppress valid
                        w_venable = 1'b0;
                    end
                    2'b10: begin
                        // Clock + Valid: pass both
                        w_venable = 1'b1;
                    end
                    default: begin
                        // Idle: suppress both
                        w_venable = 1'b0;
                    end
                endcase
            end
            // Gate the quarter-rate clock with its enable
            o_clk_p = w_qclk_1 & w_qenable_1;
            o_clk_n = w_qclk_2 & w_qenable_2;
            
        end
    end
    //-------------------------------------------------------------------------
    // Valid Output Gating
    // o_valid is only asserted when both i_valid and the valid enable are high
    //-------------------------------------------------------------------------
    assign o_valid = i_valid & w_venable;

endmodule