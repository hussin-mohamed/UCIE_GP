
`define SIM

module ucie_timeout_timer #(
    parameter int SIM_8MS_CYCLES = 80000,
    parameter DECODING_WIDTH = 9,
    parameter real CLK_PERIOD_NS = 1.0 
) (
    input  logic i_clk,
    input  logic i_reset,
    input  logic i_sim,
    input  [DECODING_WIDTH-1:0] o_tx_encoding, 
    
    output logic o_timer_1ms,
    output logic o_timer_4ms,
    output logic o_timer_8ms    
);
    // ==========================================================================
    // Threshold Calculation Logic
    // ==========================================================================

    // Synthesis thresholds 
    localparam int HW_CYCLES_1MS = int'(1_000_000.0 / CLK_PERIOD_NS);
    localparam int HW_CYCLES_4MS = int'(4_000_000.0 / CLK_PERIOD_NS);
    localparam int HW_CYCLES_8MS = int'(8_000_000.0 / CLK_PERIOD_NS);

    // Simulation thresholds 
    localparam int SIM_CYCLES_8MS = SIM_8MS_CYCLES;
    localparam int SIM_CYCLES_4MS = SIM_8MS_CYCLES / 2;
    localparam int SIM_CYCLES_1MS = SIM_8MS_CYCLES / 8;
    
    // Calculate required bits to hold the max count
    localparam CNTR_WIDTH = $clog2(HW_CYCLES_8MS + 1);

    logic [CNTR_WIDTH-1:0] CYCLES_1MS, CYCLES_4MS, CYCLES_8MS;
    logic [CNTR_WIDTH-1:0] r_counter_1ms, r_counter_4ms, r_counter_8ms;
    logic [DECODING_WIDTH-1:0] r_tx_encoding_prev;
    logic w_state_changed;

    // Runtime mux between sim and hw thresholds
    always_comb begin
        CYCLES_1MS = i_sim ? CNTR_WIDTH'(SIM_CYCLES_1MS) : CNTR_WIDTH'(HW_CYCLES_1MS);
        CYCLES_4MS = i_sim ? CNTR_WIDTH'(SIM_CYCLES_4MS) : CNTR_WIDTH'(HW_CYCLES_4MS);
        CYCLES_8MS = i_sim ? CNTR_WIDTH'(SIM_CYCLES_8MS) : CNTR_WIDTH'(HW_CYCLES_8MS);
    end
    

    // ==========================================================================
    // Edge Detection (State Change Logic)
    // ==========================================================================
    
    always_ff @(posedge i_clk or posedge i_reset) begin
        if(i_reset) begin
             r_tx_encoding_prev <= '0;
        end else begin
            r_tx_encoding_prev <= o_tx_encoding;
        end
    end

    // If current input != previous stored input, state changed.
    assign w_state_changed = (r_tx_encoding_prev != o_tx_encoding);


    // ==========================================================================
    // Counter Logic
    // ==========================================================================

    always_ff @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            r_counter_1ms <= '0;
            r_counter_4ms <= '0;
            r_counter_8ms <= '0;
        end
        else if (w_state_changed) begin
            r_counter_1ms <= '0;
            r_counter_4ms <= '0;
            r_counter_8ms <= '0;
        end
        else begin
            // Reset counter if we hit the 8ms limit, otherwise increment
            if (r_counter_8ms >= CYCLES_8MS - 1) begin
                r_counter_8ms <= '0;
            end else begin
                r_counter_8ms <= r_counter_8ms + 1'b1;
            end

            // Reset counter if we hit the 8ms limit, otherwise increment
            if (r_counter_4ms >= CYCLES_4MS - 1) begin
                r_counter_4ms <= '0;
            end else begin
                r_counter_4ms <= r_counter_4ms + 1'b1;
            end

            // Reset counter if we hit the 8ms limit, otherwise increment
            if (r_counter_1ms >= CYCLES_1MS - 1) begin
                r_counter_1ms <= '0;
            end else begin
                r_counter_1ms <= r_counter_1ms + 1'b1;
            end
        end
    end

    // ==========================================================================
    // Output Pulse Generation
    // ==========================================================================
    // Generates a 1-clock-cycle high pulse when the specific count is reached
    
    assign o_timer_1ms = (r_counter_1ms == (CYCLES_1MS - 1));
    assign o_timer_4ms = (r_counter_4ms == (CYCLES_4MS - 1));
    assign o_timer_8ms = (r_counter_8ms == (CYCLES_8MS - 1));


    // ==========================================================================
    // Assertions
    // ==========================================================================
    `ifdef SIM

        // SIM-mode output pulse checks
        property sim_timer_pulse_out (counter,cycles,divider,signal);
            @(posedge i_clk) disable iff(i_reset)
            i_sim && (counter == (cycles/divider) -1) |-> signal; 
        endproperty

        // 1ms pulse fires at SIM_8MS_CYCLES/8 - 1
        SIM_O_TIMER_1MS : assert property (sim_timer_pulse_out(r_counter_1ms, SIM_8MS_CYCLES, 8, o_timer_1ms))
            else $error("ASSERT FAIL [SIM_O_TIMER_1MS]: 1ms pulse missing at counter=%0d", r_counter_1ms);

        // 4ms pulse fires at SIM_8MS_CYCLES/2 - 1
        SIM_O_TIMER_4MS : assert property (sim_timer_pulse_out(r_counter_4ms, SIM_8MS_CYCLES, 2, o_timer_4ms))
            else $error("ASSERT FAIL [SIM_O_TIMER_4MS]: 4ms pulse missing at counter=%0d", r_counter_4ms);

        // 8ms pulse fires at SIM_8MS_CYCLES/1 - 1
        SIM_O_TIMER_8MS : assert property (sim_timer_pulse_out(r_counter_8ms, SIM_8MS_CYCLES, 1, o_timer_8ms))
            else $error("ASSERT FAIL [SIM_O_TIMER_8MS]: 8ms pulse missing at counter=%0d", r_counter_8ms);

        

        // HW-mode output pulse checks
        property hw_timer_pulse_out (counter,cycles,signal);
            @(posedge i_clk) disable iff(i_reset)
            !i_sim && (counter == cycles -1) |-> signal; 
        endproperty


        // HW 1ms pulse
        HW_O_TIMER_1MS : assert property (hw_timer_pulse_out(r_counter_1ms, HW_CYCLES_1MS, o_timer_1ms))
            else $error("ASSERT FAIL [HW_O_TIMER_1MS]: 1ms pulse missing at counter=%0d", r_counter_1ms);

        // HW 4ms pulse
        HW_O_TIMER_4MS : assert property (hw_timer_pulse_out(r_counter_4ms, HW_CYCLES_4MS, o_timer_4ms))
            else $error("ASSERT FAIL [HW_O_TIMER_4MS]: 4ms pulse missing at counter=%0d", r_counter_4ms);

        // HW 8ms pulse
        HW_O_TIMER_8MS : assert property (hw_timer_pulse_out(r_counter_8ms, HW_CYCLES_8MS, o_timer_8ms))
            else $error("ASSERT FAIL [HW_O_TIMER_8MS]: 8ms pulse missing at counter=%0d", r_counter_8ms);


       
        // Counters clears on encoding change
        property clear_on_state_change(counter);
            @(posedge i_clk) disable iff(i_reset)
            r_tx_encoding_prev != $past(r_tx_encoding_prev) |-> (counter == 0); 
        endproperty

        STATE_CHANGE_CLEAR_1MS : assert property (clear_on_state_change(r_counter_1ms))
            else $error("ASSERT FAIL [STATE_CHANGE_CLEAR]: counter_1ms not cleared after encoding change");

        STATE_CHANGE_CLEAR_4MS : assert property (clear_on_state_change(r_counter_4ms))
            else $error("ASSERT FAIL [STATE_CHANGE_CLEAR]: counter_4ms not cleared after encoding change");

        STATE_CHANGE_CLEAR_8MS : assert property (clear_on_state_change(r_counter_8ms))
            else $error("ASSERT FAIL [STATE_CHANGE_CLEAR]: counter_8ms not cleared after encoding change");



        // Counter clears on reset
        property clear_on_reset(counter);
            @(posedge i_clk) i_reset |=> (counter == 0);
        endproperty

        RESET_CLEARS_COUNTER_1MS : assert property (clear_on_reset(r_counter_1ms))
            else $error("ASSERT FAIL [RESET_CLEARS_COUNTER]: counter_1ms non-zero while reset asserted");

        RESET_CLEARS_COUNTER_4MS : assert property (clear_on_reset(r_counter_4ms))
            else $error("ASSERT FAIL [RESET_CLEARS_COUNTER]: counter_1ms non-zero while reset asserted");

        RESET_CLEARS_COUNTER_8MS : assert property (clear_on_reset(r_counter_8ms))
            else $error("ASSERT FAIL [RESET_CLEARS_COUNTER]: counter_1ms non-zero while reset asserted");


    `endif

endmodule