`define SIM

module ucie_timeout_timer #(
    parameter int SIM_8MS_CYCLES = 80000,
    parameter DECODING_WIDTH = 9,
    parameter real CLK_PERIOD_NS = 1.0 
) (
    input  logic i_clk,
    input  logic i_reset,
    input  logic i_sim,
    input  logic wait_1us,
    input  [DECODING_WIDTH-1:0] o_rx_encoding, 
    
    output logic o_timer_1ms,
    output logic o_timer_4ms,
    output logic o_timer_8ms,
    output logic o_timer_1us,
    output logic o_timer_2us
);
    // ==========================================================================
    // Threshold Calculation Logic
    // ==========================================================================

    // Synthesis thresholds 
    localparam int HW_CYCLES_1MS  = int'(1_000_000.0 / CLK_PERIOD_NS);
    localparam int HW_CYCLES_4MS  = int'(4_000_000.0 / CLK_PERIOD_NS);
    localparam int HW_CYCLES_8MS  = int'(8_000_000.0 / CLK_PERIOD_NS);
    localparam int HW_CYCLES_1US  = int'(    1_000.0 / CLK_PERIOD_NS);
    localparam int HW_CYCLES_2US  = int'(    2_000.0 / CLK_PERIOD_NS);

    // Simulation thresholds 
    localparam int SIM_CYCLES_8MS = SIM_8MS_CYCLES;
    localparam int SIM_CYCLES_4MS = SIM_8MS_CYCLES / 2;
    localparam int SIM_CYCLES_1MS = SIM_8MS_CYCLES / 8;
    localparam int SIM_CYCLES_1US = SIM_8MS_CYCLES / 8000; // 1us = 8ms/8000
    localparam int SIM_CYCLES_2US = SIM_8MS_CYCLES / 4000; // 2us = 8ms/4000
    
    // Calculate required bits to hold the max count
    localparam CNTR_WIDTH = $clog2(HW_CYCLES_8MS + 1);

    logic [CNTR_WIDTH-1:0] CYCLES_1MS, CYCLES_4MS, CYCLES_8MS, CYCLES_2US, CYCLES_1US;
    logic [CNTR_WIDTH-1:0] r_counter_1ms, r_counter_4ms, r_counter_8ms, r_counter_2us, r_counter_1us;

    // Only the top 6 bits [8:3] identify the FSM state; bits [2:0] are
    // sub-state detail that must not reset the timers.
    logic [5:0] r_rx_encoding_msb_prev;
    logic       w_state_changed;

    // Runtime mux between sim and hw thresholds
    always_comb begin
        CYCLES_1MS = i_sim ? CNTR_WIDTH'(SIM_CYCLES_1MS) : CNTR_WIDTH'(HW_CYCLES_1MS);
        CYCLES_4MS = i_sim ? CNTR_WIDTH'(SIM_CYCLES_4MS) : CNTR_WIDTH'(HW_CYCLES_4MS);
        CYCLES_8MS = i_sim ? CNTR_WIDTH'(SIM_CYCLES_8MS) : CNTR_WIDTH'(HW_CYCLES_8MS);
        CYCLES_1US = i_sim ? CNTR_WIDTH'(SIM_CYCLES_1US) : CNTR_WIDTH'(HW_CYCLES_1US);
        CYCLES_2US = i_sim ? CNTR_WIDTH'(SIM_CYCLES_2US) : CNTR_WIDTH'(HW_CYCLES_2US);
    end
    

    // ==========================================================================
    // Edge Detection (State Change Logic)
    // Only bits [8:3] (top 6) are compared — bits [2:0] are sub-state detail
    // and must not cause a timer reset.
    // ==========================================================================
    
    always_ff @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
             r_rx_encoding_msb_prev <= '0;
        end else begin
            r_rx_encoding_msb_prev <= o_rx_encoding[8:3];
        end
    end

    assign w_state_changed = (r_rx_encoding_msb_prev != o_rx_encoding[8:3]);


    // ==========================================================================
    // Counter Logic
    // ==========================================================================

    always_ff @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            r_counter_1ms <= '0;
            r_counter_4ms <= '0;
            r_counter_8ms <= '0;
            r_counter_1us <= '0;
            r_counter_2us <= '0;
        end
        else if (w_state_changed) begin
            r_counter_1ms <= '0;
            r_counter_4ms <= '0;
            r_counter_8ms <= '0;
            r_counter_1us <= '0;
            r_counter_2us <= '0;
        end
        else begin
            // 8ms counter — wraps after each period
            if (r_counter_8ms >= CYCLES_8MS - 1)
                r_counter_8ms <= '0;
            else
                r_counter_8ms <= r_counter_8ms + 1'b1;

            // 4ms counter — wraps after each period
            if (r_counter_4ms >= CYCLES_4MS - 1)
                r_counter_4ms <= '0;
            else
                r_counter_4ms <= r_counter_4ms + 1'b1;

            // 1ms counter — wraps after each period
            if (r_counter_1ms >= CYCLES_1MS - 1)
                r_counter_1ms <= '0;
            else
                r_counter_1ms <= r_counter_1ms + 1'b1;

            // 2us counter — wraps after each period
            if (r_counter_2us >= CYCLES_2US - 1)
                r_counter_2us <= '0;
            else
                r_counter_2us <= r_counter_2us + 1'b1;

            // 1us counter — wraps after each period
            if (wait_1us) begin
                if (r_counter_1us >= CYCLES_1US - 1)
                    r_counter_1us <= '0;
                else
                    r_counter_1us <= r_counter_1us + 1'b1;
            end else r_counter_1us <= 0;
        end
    end

    // ==========================================================================
    // Output Pulse Generation
    // Generates a 1-clock-cycle high pulse when the specific count is reached
    // ==========================================================================
    
    assign o_timer_1ms = (r_counter_1ms == (CYCLES_1MS - 1));
    assign o_timer_4ms = (r_counter_4ms == (CYCLES_4MS - 6));
    assign o_timer_8ms = (r_counter_8ms == (CYCLES_8MS - 6));
    assign o_timer_2us = (r_counter_2us == (CYCLES_2US - 1));
    assign o_timer_1us = (r_counter_1us == (CYCLES_1US - 1));


    // ==========================================================================
    // Assertions
    // ==========================================================================
    // `ifdef SIM

    //     // SIM-mode output pulse checks
    //     property sim_timer_pulse_out (counter, cycles, divider, signal);
    //         @(posedge i_clk) disable iff(i_reset)
    //         i_sim && (counter == (cycles/divider) - 1) |-> signal; 
    //     endproperty

    //     // 1ms pulse fires at SIM_8MS_CYCLES/8 - 1
    //     SIM_O_TIMER_1MS : assert property (sim_timer_pulse_out(r_counter_1ms, SIM_8MS_CYCLES, 8, o_timer_1ms))
    //         else $error("ASSERT FAIL [SIM_O_TIMER_1MS]: 1ms pulse missing at counter=%0d", r_counter_1ms);

    //     // 4ms pulse fires at SIM_8MS_CYCLES/2 - 1
    //     SIM_O_TIMER_4MS : assert property (sim_timer_pulse_out(r_counter_4ms, SIM_8MS_CYCLES, 2, o_timer_4ms))
    //         else $error("ASSERT FAIL [SIM_O_TIMER_4MS]: 4ms pulse missing at counter=%0d", r_counter_4ms);

    //     // 8ms pulse fires at SIM_8MS_CYCLES/1 - 1
    //     SIM_O_TIMER_8MS : assert property (sim_timer_pulse_out(r_counter_8ms, SIM_8MS_CYCLES, 1, o_timer_8ms))
    //         else $error("ASSERT FAIL [SIM_O_TIMER_8MS]: 8ms pulse missing at counter=%0d", r_counter_8ms);

    //     // 2us pulse fires at SIM_8MS_CYCLES/4000 - 1
    //     SIM_O_TIMER_2US : assert property (sim_timer_pulse_out(r_counter_2us, SIM_8MS_CYCLES, 4000, o_timer_2us))
    //         else $error("ASSERT FAIL [SIM_O_TIMER_2US]: 2us pulse missing at counter=%0d", r_counter_2us);


    //     // HW-mode output pulse checks
    //     property hw_timer_pulse_out (counter, cycles, signal);
    //         @(posedge i_clk) disable iff(i_reset)
    //         !i_sim && (counter == cycles - 1) |-> signal; 
    //     endproperty

    //     // HW 1ms pulse
    //     HW_O_TIMER_1MS : assert property (hw_timer_pulse_out(r_counter_1ms, HW_CYCLES_1MS, o_timer_1ms))
    //         else $error("ASSERT FAIL [HW_O_TIMER_1MS]: 1ms pulse missing at counter=%0d", r_counter_1ms);

    //     // HW 4ms pulse
    //     HW_O_TIMER_4MS : assert property (hw_timer_pulse_out(r_counter_4ms, HW_CYCLES_4MS, o_timer_4ms))
    //         else $error("ASSERT FAIL [HW_O_TIMER_4MS]: 4ms pulse missing at counter=%0d", r_counter_4ms);

    //     // HW 8ms pulse
    //     HW_O_TIMER_8MS : assert property (hw_timer_pulse_out(r_counter_8ms, HW_CYCLES_8MS, o_timer_8ms))
    //         else $error("ASSERT FAIL [HW_O_TIMER_8MS]: 8ms pulse missing at counter=%0d", r_counter_8ms);

    //     // HW 2us pulse
    //     HW_O_TIMER_2US : assert property (hw_timer_pulse_out(r_counter_2us, HW_CYCLES_2US, o_timer_2us))
    //         else $error("ASSERT FAIL [HW_O_TIMER_2US]: 2us pulse missing at counter=%0d", r_counter_2us);


    //     // Counters clear on encoding [8:3] change
    //     property clear_on_state_change(counter);
    //         @(posedge i_clk) disable iff(i_reset)
    //         r_rx_encoding_msb_prev != $past(r_rx_encoding_msb_prev) |-> (counter == 0); 
    //     endproperty

    //     STATE_CHANGE_CLEAR_1MS : assert property (clear_on_state_change(r_counter_1ms))
    //         else $error("ASSERT FAIL [STATE_CHANGE_CLEAR]: counter_1ms not cleared after encoding change");

    //     STATE_CHANGE_CLEAR_4MS : assert property (clear_on_state_change(r_counter_4ms))
    //         else $error("ASSERT FAIL [STATE_CHANGE_CLEAR]: counter_4ms not cleared after encoding change");

    //     STATE_CHANGE_CLEAR_8MS : assert property (clear_on_state_change(r_counter_8ms))
    //         else $error("ASSERT FAIL [STATE_CHANGE_CLEAR]: counter_8ms not cleared after encoding change");

    //     STATE_CHANGE_CLEAR_2US : assert property (clear_on_state_change(r_counter_2us))
    //         else $error("ASSERT FAIL [STATE_CHANGE_CLEAR]: counter_2us not cleared after encoding change");


    //     // Counters clear on reset
    //     property clear_on_reset(counter);
    //         @(posedge i_clk) i_reset |=> (counter == 0);
    //     endproperty

    //     RESET_CLEARS_COUNTER_1MS : assert property (clear_on_reset(r_counter_1ms))
    //         else $error("ASSERT FAIL [RESET_CLEARS_COUNTER]: counter_1ms non-zero while reset asserted");

    //     RESET_CLEARS_COUNTER_4MS : assert property (clear_on_reset(r_counter_4ms))
    //         else $error("ASSERT FAIL [RESET_CLEARS_COUNTER]: counter_4ms non-zero while reset asserted");

    //     RESET_CLEARS_COUNTER_8MS : assert property (clear_on_reset(r_counter_8ms))
    //         else $error("ASSERT FAIL [RESET_CLEARS_COUNTER]: counter_8ms non-zero while reset asserted");

    //     RESET_CLEARS_COUNTER_2US : assert property (clear_on_reset(r_counter_2us))
    //         else $error("ASSERT FAIL [RESET_CLEARS_COUNTER]: counter_2us non-zero while reset asserted");

    // `endif

endmodule