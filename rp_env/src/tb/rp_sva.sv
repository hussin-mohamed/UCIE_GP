// -------------------------------------------------------------------------
// File: rp_sva.sv
// Description: SVA Checker Interface for UCIe RX-Path Block (SVAUnit Ready)
// -------------------------------------------------------------------------

package rp_seq_pkg;
endpackage : rp_seq_pkg

interface rp_sva #(
   
)(
   // Clocks & resets
    input  logic                            i_clk_l,
    input  logic                            i_clk_p,
    input  logic                            i_clk_n,
    input  logic                            i_hclk,
    input  logic                            i_dclk,
    input  logic                            i_track,
    input  logic                            i_reset,
    // Data inputs
    input  logic [pNUM_LANES-1:0]           i_lanes,
    input  logic                            i_valid,
    input  logic                            i_halfrate,
    // Configuration
    input  logic [8:0]                      i_rx_encoding,
    input  logic [2:0]                      i_lane_map_code,
    input  logic [15:0]                     i_error_threshold,
    // Outputs
    input logic [pDATA_RDI_WIDTH-1:0]       o_pl_data,
    input logic                             o_pl_valid,
    input logic                             o_rx_done,
    input logic [63:0]                      o_rx_data_results,
    input logic                             o_rx_error,
    input logic [2:0]                       o_clk_results,
    input logic                             o_valid_results 
);

import rp_seq_pkg::*;

  // ============================================================================
  // Helper signals (NOT from RTL — internal to SVA checker)
  // ============================================================================

   //valid pattern detection signals
   logic valid_pattern_detected   = 0;
   logic valid_sample_pulse;
   logic valid_pattern_drive      = 0;
   logic valid_active_drive       = 0;

    int bit_idx;
    logic first;
    logic [7:0] expected_pattern;
    logic [15:0] error_counter;
    
    //clk_p pattern detection
    logic pattern_detected_clk_p = 0;


    //clk_n pattern detection
    logic pattern_detected_clk_n = 0;


    //track pattern detection
    logic pattern_detected_track = 0;


    //clk pattern detection
    logic clk_pattern_drive = 0; 
		logic [2:0] clk_results = 0;

    //encoding detector
    logic [8:0] previous_encoding;
    logic [8:0] current_enc_q;
    logic is_valid_pattern = 0;
	logic is_clk_pattern = 0;
    logic data_to_clk_test_armed = 0; // NEW: Sequence tracker flag



    logic pattern_burst_active;
    logic prev_clk_p;
    // ---------------------------------------------
    

		//=======================================
    // Valid  Pattern Detection Logic
    //=======================================

    // Generate a posedge pulse ONLY when the physical wires go high
    always @(posedge i_clk_p or posedge i_clk_n) begin
        valid_sample_pulse = 1'b1;
        // Drive high on the edge
        #1ps;
        // Wait a microscopic amount of time
        valid_sample_pulse = 1'b0;
        // Reset it so the SVA sees a clean posedge next time
    end
    

    // Watchdog to detect when the physical clock stops toggling 

    always @(posedge i_dclk) begin
        if (i_reset || (i_rx_encoding != Data_To_Clock_test_RX_Pattern_Detection_RX_Init)) begin
            pattern_burst_active <= 1'b1; // Assume active when we first enter the state
            prev_clk_p <= i_clk_p;
        end else begin
            prev_clk_p <= i_clk_p;
            
            // If the clock is toggling, keep the timeout cleared
            if (i_clk_p != prev_clk_p) begin
                pattern_burst_active <= '1;
            end 
            // If the clock is flat, start counting
            else begin
                pattern_burst_active <= '0;
            end

        end
    end

    // Detect when we enter a valid pattern state based on the encoding
    always @(posedge i_clk_l) begin
        if (i_reset) begin
            current_enc_q <= '0;
            previous_encoding <= '0;
            data_to_clk_test_armed <= 1'b0;
            is_valid_pattern <= 1'b0;
        end else begin
            // 1. Continuously track the 1-cycle delayed signal
            current_enc_q <= i_rx_encoding;

            // 2. Only update previous_encoding when the state ACTUALLY changes
            if (i_rx_encoding != current_enc_q) begin
                previous_encoding <= current_enc_q;
            end

            // 3. Arm the flag
            if ((i_rx_encoding == Data_To_Clock_test_RX_INIT_Handshake_RX_Init) &&
                ((previous_encoding == MBTRAIN_VALVREF_RX_Start_Handshake) ||
                 (previous_encoding == MBTRAIN_VALTRAINCENTER_RX_Start_Handshake) ||
                 (previous_encoding == MBTRAIN_VALTRAINVREF_RX_Start_Handshake))) begin
                
                data_to_clk_test_armed <= 1'b1;

            end else if ((i_rx_encoding != Data_To_Clock_test_RX_INIT_Handshake_RX_Init) &&
                         (i_rx_encoding != Data_To_Clock_test_RX_LFSR_Clear_Handshake_RX_Init) &&
                         (i_rx_encoding != Data_To_Clock_test_RX_Pattern_Detection_RX_Init)) begin
                
                data_to_clk_test_armed <= 1'b0;
            end

            // 4. Enable `is_valid_pattern` only in allowed states
            if (i_rx_encoding == MBINIT_REPAIRVAL_RX_Valid_Pattern_Det) begin
                is_valid_pattern <= 1'b1;
            end 
            else if (i_rx_encoding == ACTIVE_RX_Active) begin
                is_valid_pattern <= 1'b1;
            end 
            else if ((i_rx_encoding == Data_To_Clock_test_RX_Pattern_Detection_RX_Init) && data_to_clk_test_armed) begin
                is_valid_pattern <= 1'b1;
            end 
            else if (valid_pattern_drive) begin
                is_valid_pattern <= is_valid_pattern;
            end
            else begin
                is_valid_pattern <= 0;
            end
        end
    end


    always @(posedge i_dclk) begin
        if (!valid_pattern_drive) begin 
            if (i_rx_encoding == Data_To_Clock_test_RX_Pattern_Detection_RX_Init) begin
                    valid_pattern_detected = 1'b1;
                    valid_pattern_drive = 1'b1;
            end
            else if (i_rx_encoding == MBINIT_REPAIRVAL_RX_Valid_Pattern_Det) begin
                    valid_pattern_detected = 1'b0;
                    valid_pattern_drive = 1'b1;      
            end
        end
        else begin
            if ((i_rx_encoding == MBINIT_REPAIRVAL_RX_Done_Handshake) || (i_rx_encoding == Data_To_Clock_test_RX_End_Init_Handshake_RX_Init)) begin
                valid_pattern_detected = 1'b0;
                valid_pattern_drive = 1'b0; // Reset drive flag when we leave the states that control the pattern detection
            end
        end
    end

    always @(posedge i_dclk) begin
        if (!valid_active_drive) begin 
            if (i_rx_encoding == ACTIVE_RX_Active) begin
                    valid_pattern_detected = 1'b1;
                    valid_active_drive = 1'b1;
            end
        end
        else begin
            if (i_rx_encoding != ACTIVE_RX_Active) begin
                    valid_pattern_detected = 1'b0;
                    valid_active_drive = 1'b0;
            end
        end
    end

    always @(posedge valid_sample_pulse) begin

      if (is_valid_pattern && ((i_rx_encoding == Data_To_Clock_test_RX_Pattern_Detection_RX_Init) || (i_rx_encoding == ACTIVE_RX_Active))) begin
        /*if (!first) begin
          first = 1;
        end
        else begin*/
          
        expected_pattern = {expected_pattern[6:0], i_valid}; // Shift in the new bit
        bit_idx = bit_idx + 1; // Increment bit index

        if (i_rx_encoding == Data_To_Clock_test_RX_Pattern_Detection_RX_Init)begin

            if ((bit_idx == 8) && pattern_burst_active) begin // We have a full byte
              if (expected_pattern != 8'b11110000) begin
                error_counter++;
                `uvm_info("",$sformatf("[%0t] ERROR: Detected pattern %b does not match expected 11110000", $time, expected_pattern), UVM_LOW);
               if (error_counter > i_error_threshold) begin
               valid_pattern_detected = 1'b0; // Stop the test if we exceed the error threshold
               end
              end 
              bit_idx = 0; // Reset for the next byte
            end

        end else if (i_rx_encoding == ACTIVE_RX_Active) begin

            if (bit_idx == 8) begin // We have a full byte
              if (expected_pattern != 8'b00000000) begin

               if (expected_pattern != 8'b11110000) begin
                `uvm_info("ACTIVE",$sformatf("[%0t] ERROR: Detected pattern %b does not match expected 11110000 during active", $time, expected_pattern), UVM_LOW);
              
               valid_pattern_detected = 1'b0; // Stop the test if we exceed the error threshold

              end 

              end
              bit_idx = 0; // Reset for the next byte
            end
       // end
        end
      end

      else if (!is_valid_pattern) begin
        expected_pattern = 0;
        error_counter = 0;
        bit_idx = 0;
        first = 0;
      end
    end

	//=======================================
    // CLK Pattern Detection Logic
    //=======================================

		
	always @(posedge i_dclk) begin
        clk_results = {pattern_detected_track , pattern_detected_clk_n , pattern_detected_clk_p};
    end

	always @(posedge i_clk_l) begin
        if (i_reset) begin
            is_clk_pattern <= 1'b0;
        end else begin
            
            if (i_rx_encoding == MBINIT_REPAIRCLK_RX_Pattern_Detection) begin
                is_clk_pattern <= 1'b1;
            end 
            else begin
                is_clk_pattern <= 1'b0;
            end
        end
    end
	always @(posedge i_dclk) begin
        if (!clk_pattern_drive) begin 
            if (i_rx_encoding == MBINIT_REPAIRCLK_RX_Pattern_Detection) begin
                    pattern_detected_clk_p = 1'b0;
										pattern_detected_clk_n = 1'b0;
										pattern_detected_track = 1'b0;
                    clk_pattern_drive = 1'b1;
            end
        end
        else begin
            if (i_rx_encoding == MBINIT_REPAIRCLK_RX_Done_Handshake) begin
                		pattern_detected_clk_p = 1'b0;
										pattern_detected_clk_n = 1'b0;
										pattern_detected_track = 1'b0;
                		clk_pattern_drive = 1'b0; // Reset drive flag when we leave the states that control the pattern detection
            end
        end
    end


  // ============================================================================
  // Properties & Assertions
  // ============================================================================
   // The Valid 8-bit pattern: four 1s followed by four 0s
    sequence seq_8bit_pattern;
        i_valid[*4] ##1 (!i_valid)[*4];
    endsequence : seq_8bit_pattern

     sequence seq_16_consecutive;
        seq_8bit_pattern[*16];
    endsequence : seq_16_consecutive

    sequence first_seq_8bit_pattern;
        i_valid[*3] ##1 (!i_valid)[*4];
    endsequence : first_seq_8bit_pattern

     sequence first_seq_16_consecutive;
        first_seq_8bit_pattern ##1 seq_8bit_pattern[*15];
    endsequence : first_seq_16_consecutive


   // clk_p 32-bit pattern
    sequence clk_p_seq_32bit_pattern;
        (i_clk_p ##1 (!i_clk_p))[*16] ##1 (!i_clk_p)[*16];
    endsequence : clk_p_seq_32bit_pattern

     sequence clk_p_seq_16_consecutive;
        clk_p_seq_32bit_pattern[*16];
    endsequence : clk_p_seq_16_consecutive

    // clk_n 32-bit pattern
    sequence clk_n_seq_32bit_pattern;
        (!i_clk_n ##1 (i_clk_n))[*16] ##1 (i_clk_n)[*16];
    endsequence : clk_n_seq_32bit_pattern

     sequence clk_n_seq_16_consecutive;
        clk_n_seq_32bit_pattern[*16];
    endsequence : clk_n_seq_16_consecutive
    
    // track 32-bit pattern
     sequence track_seq_32bit_pattern;
        (i_track ##1 (!i_track))[*16] ##1 (!i_track)[*16];
    endsequence : track_seq_32bit_pattern

     sequence track_seq_16_consecutive;
        track_seq_32bit_pattern[*16];
    endsequence : track_seq_16_consecutive



  // Valid Property
    property valid_detect_16_in_128_window;
        @(posedge i_dclk) disable iff(valid_pattern_detected || (i_rx_encoding != MBINIT_REPAIRVAL_RX_Valid_Pattern_Det))
         ($rose(i_valid))|=> 

        @(posedge valid_sample_pulse) // Sample on the generated valid sample pulse
            // first_match guarantees that once we find it, we stop checking 
            // parallel possibilities and immediately declare success.
            first_match(first_seq_16_consecutive or ##[0:$] seq_16_consecutive);
    endproperty 

    property valid_active;
        @(posedge i_dclk) disable iff(i_rx_encoding != ACTIVE_RX_Active)
         ($fell(valid_pattern_detected) || $fell(o_valid_results)) |=> 
        @(posedge i_clk_l) ##3 ((o_valid_results == valid_pattern_detected));
    endproperty

    property valid_results_check;
        @(posedge i_clk_l) 
        (($rose((i_rx_encoding == MBINIT_REPAIRVAL_RX_Send_Result_RESP) || (i_rx_encoding == Data_To_Clock_test_RX_Result_Handshake_RX_Init))) && is_valid_pattern)
        |-> (o_valid_results == valid_pattern_detected);
    endproperty


    // clk_p Property
    property clk_p_detect_16_in_128_window;
        @(negedge i_dclk) disable iff(pattern_detected_clk_p || (i_rx_encoding != MBINIT_REPAIRCLK_RX_Pattern_Detection))
         ($rose(i_clk_p))|-> 
        first_match(##[0:$] clk_p_seq_16_consecutive);
    endproperty

    // clk_n Property
     property clk_n_detect_16_in_128_window;
        @(negedge i_dclk) disable iff(pattern_detected_clk_n || (i_rx_encoding != MBINIT_REPAIRCLK_RX_Pattern_Detection))
         ($fell(i_clk_n))|-> 

        first_match(##[0:$] clk_n_seq_16_consecutive);
    endproperty

    // track Property
    property track_detect_16_in_128_window;
        @(negedge i_dclk) disable iff(pattern_detected_track || (i_rx_encoding != MBINIT_REPAIRCLK_RX_Pattern_Detection))
         ($rose(i_track))|-> 

        first_match(##[0:$] track_seq_16_consecutive);
    endproperty

	property clk_results_check;
        @(posedge i_clk_l) 
        $rose((i_rx_encoding == MBINIT_REPAIRCLK_RX_Send_RESP))
        |-> (o_clk_results == clk_results);
    endproperty


   // Assertions

   assert_valid_pattern_16_frame: assert property (valid_detect_16_in_128_window) begin
    // This executes only if the pattern is found (Pass)
    valid_pattern_detected = 1'b1;
    //`uvm_info("Valid Pattern", "16 consecutive 11110000 patterns detected!", UVM_HIGH)
    
    end else begin
    `uvm_info("Valid Pattern", "Failed to detect 16 consecutive 11110000 patterns within 128-cycle window!", UVM_HIGH)
    end

   assert_valid_pattern_active_frame: assert property (valid_active) begin
    // This executes only if the pattern is found (Pass)
    //`uvm_info("Valid Pattern", "Right pattern detected!", UVM_HIGH)
    
    end else begin
    `uvm_info("Valid Pattern", "Wrong pattern detected in Active State!", UVM_HIGH)
    end
   
  assert_valid_pattern_result_check: assert property (valid_results_check) 
    //`uvm_info("Valid Pattern", "Test Passed!", UVM_HIGH)
		else begin
            `uvm_error("Valid Pattern", "FAIL: Output result does not match expected pattern detection state!")
        end
    
    

  assert_clk_p_pattern_frame: assert property (clk_p_detect_16_in_128_window) begin
    // This executes only if the pattern is found (Pass)
    pattern_detected_clk_p = 1'b1;
    //`uvm_info("clk_p Pattern", "16 consecutive clk_p patterns detected!", UVM_HIGH)
    
    end else begin
    `uvm_info("clk_p Pattern", "Failed to detect 16 consecutive clk_p patterns within 128-frame window!", UVM_HIGH)
    end

  assert_clk_n_pattern_frame: assert property (clk_n_detect_16_in_128_window) begin
    // This executes only if the pattern is found (Pass)
    pattern_detected_clk_n = 1'b1;
    //`uvm_info("clk_n Pattern", "16 consecutive clk_n patterns detected!", UVM_HIGH)
    
    end else begin
    `uvm_info("clk_n Pattern", "Failed to detect 16 consecutive clk_n patterns within 128-frame window!", UVM_HIGH)
    end

  assert_track_pattern_frame: assert property (track_detect_16_in_128_window) begin
    // This executes only if the pattern is found (Pass)
    pattern_detected_track = 1'b1;
    //`uvm_info("track Pattern", "16 consecutive track patterns detected!", UVM_HIGH)
    
    end else begin
    `uvm_info("track Pattern", "Failed to detect 16 consecutive track patterns within 128-frame window!", UVM_HIGH)
    end

		assert_clk_pattern_result_check: assert property (clk_results_check) 
    //`uvm_info("CLK Pattern", "Test Passed!", UVM_HIGH)
		else begin
            `uvm_error("CLK Pattern", "FAIL: Output result does not match expected pattern detection state!")
        end

  

  always_comb
    if (i_reset) begin
        chk_async_reset_zeros: assert final (
          {
            o_pl_data,
            o_pl_valid
          } == '0
        );
        chk_async_reset_ones: assert final (
          &{
            o_rx_done,
            o_rx_data_results,
            o_clk_results,
            o_valid_results
          } == 1'b1
        );
    end

	// ============================================================================
  // Functional Coverage Directives
  // ============================================================================
  
  cover_valid_pattern_16_frame:      cover property (valid_detect_16_in_128_window);
  cover_valid_pattern_active_frame:  cover property (valid_active);
  cover_valid_pattern_result_check:  cover property (valid_results_check);

  cover_clk_p_pattern_frame:         cover property (clk_p_detect_16_in_128_window);
  cover_clk_n_pattern_frame:         cover property (clk_n_detect_16_in_128_window);
  cover_track_pattern_frame:         cover property (track_detect_16_in_128_window);
  cover_clk_pattern_result_check:    cover property (clk_results_check);

endinterface : rp_sva