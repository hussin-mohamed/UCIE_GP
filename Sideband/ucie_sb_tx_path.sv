module ucie_sb_tx_path (
    input  logic i_clk,             // System/Sideband Clock
    input  logic i_reset,           // Active Low Reset
    
    // Control Signals
    input  logic i_sb_init_start,   // High during initialization
    input  logic i_timer_1ms,       // Pulse every 1ms (from Timer module)
    input  logic i_rx_done,         // From RX Path (Pattern Detected)
    
    // Real Message Interface (for Muxing)
    input  logic i_data_msg,

    // Physical Outputs
    output logic o_tx_sb_data,
    output logic o_tx_sb_clk,
    output logic o_stop             // Pulse/High when initialization is fully done
);

    // --------------------------------------------------------
    // Internal States & Counters
    // --------------------------------------------------------
    localparam  IDLE        = 2'b00;
    localparam  CYCLING     = 2'b01;  // Alternating 1ms ON / 1ms OFF
    localparam  EXTRA_ITERS = 2'b10;  // Sending final 4 iterations
    localparam  DONE        = 2'b11;  // Initialization complete

    logic [1:0] current_state, next_state;

    // Pattern Counters
    // Total pattern length = 64 UI (Clk) + 32 UI (Low) = 96 UI
    logic [6:0] ui_counter;      // Counter 0 to 95
    logic [2:0] iter_counter;    // Counter 0 to 4 (for the extra iterations)
    
    // 1ms Toggle Logic
    logic r_1ms_active;          // 1: Generating, 0: Quiet (swaps every 1ms)

    // Generated Signals
    logic w_gen_data;
    logic w_gen_clk;
    logic w_pattern_running;     // High when we are actually shifting bits out

    // --------------------------------------------------------
    // 1ms Alternating Logic
    // --------------------------------------------------------
    always_ff @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            r_1ms_active <= 1'b1; // Start active
        end else if (current_state == IDLE) begin
            r_1ms_active <= 1'b1;
        end else if (i_timer_1ms && (current_state == CYCLING)) begin
            r_1ms_active <= ~r_1ms_active; // Toggle every 1ms
        end
    end

    // --------------------------------------------------------
    // Main FSM
    // --------------------------------------------------------
    always_ff @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    always_comb begin
        next_state = current_state;
        
        case (current_state)
            IDLE: begin
                if (i_sb_init_start)
                    next_state = CYCLING;
            end

            CYCLING: begin
                if (i_rx_done) begin
                    if (ui_counter == 95) 
                        next_state = EXTRA_ITERS;
                end
            end

            EXTRA_ITERS: begin
                if (iter_counter == 4)
                    next_state = DONE;
            end

            DONE: begin
                if (!i_sb_init_start)
                    next_state = IDLE;
            end
        endcase
    end

    // --------------------------------------------------------
    // Pattern Generator Logic (64 UI Clock + 32 UI Low)
    // --------------------------------------------------------

    assign w_pattern_running = (current_state == EXTRA_ITERS) || 
                               ((current_state == CYCLING) && r_1ms_active);

    always_ff @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            ui_counter   <= 0;
            iter_counter <= 0;
        end else begin
            if (w_pattern_running) begin
                if (ui_counter == 95)
                    ui_counter <= 0;
                else
                    ui_counter <= ui_counter + 1;
            end else begin
                if (current_state == CYCLING)
                    ui_counter <= 0;
            end

            if (current_state == IDLE) begin
                iter_counter <= 0;
            end else if (current_state == EXTRA_ITERS) begin
                if (ui_counter == 95)
                    iter_counter <= iter_counter + 1;
            end
        end
    end

    always_comb begin
        if (ui_counter < 64) begin
            // First 64 UIs: 
            w_gen_data = ~ui_counter[0]; 
            w_gen_clk  = ~ui_counter[0]; 
        end else begin
            // Next 32 UIs: Low
            w_gen_data = 1'b0;
            w_gen_clk  = 1'b0;
        end
    end

    // --------------------------------------------------------
    // Output Muxing
    // --------------------------------------------------------
    
    always_comb begin
        if (current_state == CYCLING || current_state == EXTRA_ITERS) begin
            if (w_pattern_running) begin
                o_tx_sb_data = w_gen_data;
                o_tx_sb_clk  = w_gen_clk;
            end else begin
                // During the 1ms "OFF" period
                o_tx_sb_data = 1'b0;
                o_tx_sb_clk  = 1'b0;
            end
        end else begin
            // IDLE or DONE: Pass through real data
            o_tx_sb_data = i_data_msg;
            o_tx_sb_clk  = i_clk_msg;
        end
    end

    assign o_stop = (current_state == DONE);

endmodule