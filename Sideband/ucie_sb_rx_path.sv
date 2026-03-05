module ucie_sb_rx_path (
 
    input  logic i_rx_sb_clk,       
    
    input  logic i_reset,           

    // Control
    input  logic i_sb_init_start,   
    
    // Physical Sideband Input
    input  logic i_rx_sb_data,
    
    // Outputs
    output logic o_done             // High when 128 UI pattern is detected
);

    // --------------------------------------------------------
    // Pattern Detection Logic
    // --------------------------------------------------------

    
    logic [7:0] pattern_cnt;
    logic       r_prev_data;
    logic       r_detected_flag;

    always_ff @(posedge i_rx_sb_clk or posedge i_reset) begin
        if (i_reset) begin
            pattern_cnt     <= '0;
            r_prev_data     <= '0;
            r_detected_flag <= '0;
        end else begin
            if (i_sb_init_start) begin
                if (!r_detected_flag) begin
                    if (i_rx_sb_data != r_prev_data) begin
                        if (pattern_cnt < 128) begin
                            pattern_cnt <= pattern_cnt + 1'b1;
                        end
                    end else begin
                        pattern_cnt <= '0; 
                    end
                    
                    r_prev_data <= i_rx_sb_data;

                    if (pattern_cnt >= 127) begin 
                        r_detected_flag <= 1'b1;
                    end
                end
            end else begin
                pattern_cnt     <= '0;
                r_detected_flag <= '0;
            end
        end
    end

    assign o_done = r_detected_flag;

endmodule