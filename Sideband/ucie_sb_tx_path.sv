module ucie_sb_tx_path (

    input  logic i_clk,             // System / Control Clock
    input  logic i_s_clk,           // SerDes Clock  — pattern generation & output
    input  logic i_reset,           // Active-high asynchronous reset

    // Control inputs
    input  logic i_sb_init_start,   // High during sideband initialisation
    input  logic i_timer_1ms,       // Pulse every 1 ms (from Timer module)
    input  logic i_rx_done,         // From RX path — pattern detected

    // Physical outputs  (registered on i_s_clk)
    output logic o_tx_sb_data,
    output logic o_tx_sb_clk,

    // Control output  (combinational from i_clk domain
    output logic o_stop             // High when initialisation is fully done

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

    // Used to account for the time differences btw the slow clock and fast clock 
    // since when detection is done and ui_counter reaches 95 and rx_done is asserted 
    // we should go to Extra Iter state but we need to wait for the slow clock edge to come
    // and between that the ui counter might move to 0 again to start next iterations before 
    // the slow clock edge come --- That is why we need a flag to remeber this scene
    logic latch_flag;

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

    always_ff @(posedge i_s_clk or posedge i_reset) begin
        if (i_reset) begin
            latch_flag <= 0;
        end else begin
            if(ui_counter == 95 && i_rx_done && current_state == CYCLING)
                latch_flag <= 1;
            else if(current_state != CYCLING)
                latch_flag <= 0;
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

                if(latch_flag)
                    next_state = EXTRA_ITERS;
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

    assign w_pattern_running = ((current_state == EXTRA_ITERS) && r_1ms_active) || 
                               ((current_state == CYCLING) && r_1ms_active);

    always_ff @(posedge i_s_clk or posedge i_reset) begin
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
        end
    end

    assign o_stop = (current_state == DONE);

endmodule