// Uncomment the line below to test the Synthesis (Hardware) logic
// `define SYNTHESIS


module ucie_timeout_timer #(

    parameter int SIM_8MS_CYCLES = 80000,
    parameter DECODING_WIDTH = 9;

    parameter real CLK_PERIOD_NS = 1.0 
) (
    input  logic i_clk,
    input  logic i_reset,      
    input [DECODING_WIDTH-1:0] o_tx_encoding, 
    
    output logic o_timer_1ms,   // Pulse when 1ms threshold reached
    output logic o_timer_4ms,   // Pulse when 4ms threshold reached
    output logic o_timer_8ms    // Pulse when 8ms threshold reached 
);

    // ==========================================================================
    // Threshold Calculation Logic (Conditional Compilation)
    // ==========================================================================
    
    localparam int CYCLES_1MS;
    localparam int CYCLES_4MS;
    localparam int CYCLES_8MS;

    `ifdef SYNTHESIS

        initial $display("UCIE_TIMER: Synthesizing for Hardware. Clk Period: %0fns", CLK_PERIOD_NS);
        
        localparam int NS_IN_1MS = 1_000_000;
        localparam int NS_IN_4MS = 4_000_000;
        localparam int NS_IN_8MS = 8_000_000;

        localparam int CYCLES_1MS = int'(1_000_000.0 / CLK_PERIOD_NS);
        localparam int CYCLES_4MS = int'(4_000_000.0 / CLK_PERIOD_NS);
        localparam int CYCLES_8MS = int'(8_000_000.0 / CLK_PERIOD_NS);

    `else

        initial $display("UCIE_TIMER: Simulation Mode. 8ms = %0d cycles", SIM_8MS_CYCLES);

        assign CYCLES_8MS = SIM_8MS_CYCLES;
        assign CYCLES_4MS = SIM_8MS_CYCLES / 2; // 4ms is half of 8ms
        assign CYCLES_1MS = SIM_8MS_CYCLES / 8; // 1ms is one-eighth of 8ms
    `endif

    // ==========================================================================
    // Counter Logic
    // ==========================================================================
    
    // Calculate required bits to hold the max count
    localparam int CNTR_WIDTH = $clog2(CYCLES_8MS + 1);
    
    logic [CNTR_WIDTH-1:0] r_counter;
    logic [DECODING_WIDTH-1:0] r_tx_encoding_prev;
    logic w_state_changed;

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

    always_ff @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            r_counter <= '0;
        end
        else if (w_state_changed) begin
            r_counter <= '0;
        end
        else begin
            // Reset counter if we hit the 8ms limit, otherwise increment
            if (r_counter >= CYCLES_8MS - 1) begin
                r_counter <= '0;
            end else begin
                r_counter <= r_counter + 1'b1;
            end
        end
    end

    // ==========================================================================
    // Output Pulse Generation
    // ==========================================================================
    // Generates a 1-clock-cycle high pulse when the specific count is reached
    
    assign o_timer_1ms = (r_counter == (CYCLES_1MS - 1));
    assign o_timer_4ms = (r_counter == (CYCLES_4MS - 1));
    assign o_timer_8ms = (r_counter == (CYCLES_8MS - 1));

endmodule