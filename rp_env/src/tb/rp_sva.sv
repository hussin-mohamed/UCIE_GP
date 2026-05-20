
// -------------------------------------------------------------------------
// File: rp_sva.sv
// Description: SVA Checker Interface for UCIe RX-Path Block (SVAUnit Ready)
// -------------------------------------------------------------------------
// File: rp_sva.sv

package rp_seq_pkg;

endpackage : rp_seq_pkg

interface rp_sva #(
   
)(
  // Clocks
   input logic clk
  ,input logic i_hclk
  ,input logic i_dclk
  ,input logic reset

  // Reset
  ,input logic i_reset

  // rmblink inputs
  ,input logic                  i_clk_p;
  ,input logic                  i_clk_n;
  ,input logic                  i_track;

  ,input logic                  i_valid;
  ,input logic                  i_error_threshold;

  ,output logic                 o_valid_results;
);
  import rp_seq_pkg::*;

  // ============================================================================
  // Helper signals (NOT from RTL — internal to SVA checker)
  // ============================================================================


   //valid pattern detection signals
   logic valid_pattern_detected   = 0;
   logic valid_pattern_running    = 0;
   logic valid_sample_pulse;
   logic valid_frame_timeout      = 0;
   logic valid_timeout_started = 0;

    int bit_idx;
    logic first;
    logic [7:0] expected_pattern;
    logic [15:0] error_counter;

    //clk_p pattern detection
    logic pattern_detected_clk_p = 0;
    logic pattern_running_clk_p = 0;
    logic frame_timeout_clk_p = 0;
    logic clk_p_timeout_started = 0;

    //clk_n pattern detection
    logic pattern_detected_clk_n = 0;
    logic pattern_running_clk_n = 0;
    logic frame_timeout_clk_n = 0;
    logic clk_n_timeout_started = 0;

    //track pattern detection
    logic pattern_detected_track = 0;
    logic pattern_running_track = 0;
    logic frame_timeout_track = 0;
    logic track_timeout_started = 0;

    // Generate a posedge pulse ONLY when the physical wires go high
    always @(posedge i_clk_p or posedge i_clk_n) begin
        valid_sample_pulse = 1'b1; // Drive high on the edge
        #1ps;                    // Wait a microscopic amount of time
        valid_sample_pulse = 1'b0; // Reset it so the SVA sees a clean posedge next time
    end

    // Generate timeout and pattern running signals based on the Valid signal's activity
always @(posedge i_dclk) begin
        if (pattern_type != idle) begin
            valid_frame_timeout = 1'b0;
            valid_timeout_started = 1'b1;
            @(posedge i_dclk);
            valid_timeout_started = 1'b0; // Start the timeout countdown

            // Spawn two parallel threads
            fork
                // Thread 1: The 1024-cycle timeout counter
                begin
                    repeat(1024) @(posedge i_dclk);
                end
                
                // Thread 2: The early-abort monitor
                begin
                    // 'wait' is level-sensitive and will catch the change immediately
                    wait (pattern_type == idle); 
                end
            join_any
            
            // Kill whichever thread didn't finish first
            disable fork; 

            // Determine WHY we exited the fork
            if (pattern_type != idle) begin
                // Thread 1 finished first -> It's a real timeout!
                valid_frame_timeout = 1'b1; 
                valid_pattern_running = 1'b0; // End the pattern detection window
                if (valid_pattern_detected) valid_pattern_detected = 1'b0; // Reset
                @(posedge i_dclk);
                valid_frame_timeout = 1'b0; // Reset for the next test
            end else begin
                // Thread 2 finished first -> Aborted early because it went to idle
                // (Add any necessary reset logic for early termination here)
                valid_pattern_running = 1'b0; 
                valid_frame_timeout = 1'b0; // Ensure timeout is reset
            end
        end
    end


    always @(posedge i_dclk) begin
        if ((pattern_type != idle) && !valid_frame_timeout && !valid_pattern_running) begin
            if (i_valid) begin
              valid_pattern_running = 1'b1; // Start the pattern detection window
            end
            else begin
              valid_pattern_running = 1'b0; // End the pattern detection window
            end
        end
    end

    always @(posedge i_dclk) begin
      if(pattern_type == error) begin
        if (!first) begin
          first = 1;
        end
        else begin
          
        expected_pattern = {expected_pattern[6:0], i_valid}; // Shift in the new bit
        bit_idx = bit_idx + 1; // Increment bit index

        if (bit_idx == 8) begin // We have a full byte
          if (expected_pattern != 8'b11110000) begin
            error_counter++;
            $display("[%0t] ERROR: Detected pattern %b does not match expected 11110000", $time, expected_pattern);
          end else begin
            $display("[%0t] INFO: Detected correct pattern 11110000", $time);
          end
          bit_idx = 0; // Reset for the next byte
      end

        end
      end
      else begin
        expected_pattern = 0;
        error_counter = 0;
        bit_idx = 0;
        first = 0;
      end
    end

    // Generate timeout and pattern running signals based on the clk_p signal's activity
    always @(negedge i_dclk) begin
        if (pattern_type != idle) begin
            frame_timeout_clk_p = 1'b0;
            clk_p_timeout_started = 1'b1;
            @(posedge i_dclk);
            clk_p_timeout_started = 1'b0; // Start the timeout countdown

            // Spawn two parallel threads
            fork
                // Thread 1: The 1024-cycle timeout counter
                begin
                    repeat(6144) @(posedge i_dclk);
                end
                
                // Thread 2: The early-abort monitor
                begin
                    // 'wait' is level-sensitive and will catch the change immediately
                    wait (pattern_type == idle); 
                end
            join_any
            
            // Kill whichever thread didn't finish first
            disable fork; 

            // Determine WHY we exited the fork
            if (pattern_type != idle) begin
                // Thread 1 finished first -> It's a real timeout!
                frame_timeout_clk_p = 1'b1; 
                pattern_running_clk_p = 1'b0; // End the pattern detection window
                if (pattern_detected_clk_p) pattern_detected_clk_p = 1'b0; // Reset
                @(posedge i_dclk);
                frame_timeout_clk_p = 1'b0; // Reset for the next test
            end else begin
                // Thread 2 finished first -> Aborted early because it went to idle
                // (Add any necessary reset logic for early termination here)
                pattern_running_clk_p = 1'b0; 
                frame_timeout_clk_p = 1'b0; // Ensure timeout is reset
            end
        end
    end
    always @(posedge i_dclk) begin
        if ((pattern_type != idle) && !frame_timeout_clk_p && !pattern_running_clk_p) begin
            if (i_clk_p) begin
              pattern_running_clk_p = 1'b1; // Start the pattern detection window
            end
            else begin
              pattern_running_clk_p = 1'b0; // End the pattern detection window
            end
        end
    end

    // Generate timeout and pattern running signals based on the clk_n signal's activity
     always @(negedge i_dclk) begin
        if (pattern_type != idle) begin
            frame_timeout_clk_n = 1'b0;
            clk_n_timeout_started = 1'b1;
            @(posedge i_dclk);
            clk_n_timeout_started = 1'b0; // Start the timeout countdown

            // Spawn two parallel threads
            fork
                // Thread 1: The 1024-cycle timeout counter
                begin
                    repeat(6144) @(posedge i_dclk);
                end
                
                // Thread 2: The early-abort monitor
                begin
                    // 'wait' is level-sensitive and will catch the change immediately
                    wait (pattern_type == idle); 
                end
            join_any
            
            // Kill whichever thread didn't finish first
            disable fork; 

            // Determine WHY we exited the fork
            if (pattern_type != idle) begin
                // Thread 1 finished first -> It's a real timeout!
                frame_timeout_clk_n = 1'b1; 
                pattern_running_clk_n = 1'b0; // End the pattern detection window
                if (pattern_detected_clk_n) pattern_detected_clk_n = 1'b0; // Reset
                @(posedge i_dclk);
                frame_timeout_clk_n = 1'b0; // Reset for the next test
            end else begin
                // Thread 2 finished first -> Aborted early because it went to idle
                // (Add any necessary reset logic for early termination here)
                pattern_running_clk_n = 1'b0; 
                frame_timeout_clk_n = 1'b0; // Ensure timeout is reset
            end
        end
    end
    always @(posedge i_dclk) begin
        if ((pattern_type != idle) && !frame_timeout_clk_n && !pattern_running_clk_n) begin
            if (!i_clk_n) begin
              pattern_running_clk_n = 1'b1; // Start the pattern detection window
            end
            else begin
              pattern_running_clk_n = 1'b0; // End the pattern detection window
            end
        end
    end

    // Generate timeout and pattern running signals based on the track signal's activity
    always @(negedge i_dclk) begin
        if (pattern_type != idle) begin
            frame_timeout_track = 1'b0;
            track_timeout_started = 1'b1;
            @(posedge i_dclk);
            track_timeout_started = 1'b0; // Start the timeout countdown

            // Spawn two parallel threads
            fork
                // Thread 1: The 1024-cycle timeout counter
                begin
                    repeat(6144) @(posedge i_dclk);
                end
                
                // Thread 2: The early-abort monitor
                begin
                    // 'wait' is level-sensitive and will catch the change immediately
                    wait (pattern_type == idle); 
                end
            join_any
            
            // Kill whichever thread didn't finish first
            disable fork; 

            // Determine WHY we exited the fork
            if (pattern_type != idle) begin
                // Thread 1 finished first -> It's a real timeout!
                frame_timeout_track = 1'b1; 
                pattern_running_track = 1'b0; // End the pattern detection window
                if (pattern_detected_track) pattern_detected_track = 1'b0; // Reset
                @(posedge i_dclk);
                frame_timeout_track = 1'b0; // Reset for the next test
            end else begin
                // Thread 2 finished first -> Aborted early because it went to idle
                // (Add any necessary reset logic for early termination here)
                pattern_running_track = 1'b0; 
                frame_timeout_track = 1'b0; // Ensure timeout is reset
            end
        end
    end
    always @(posedge i_dclk) begin
        if ((pattern_type != idle) && !frame_timeout_track && !pattern_running_track) begin
            if (i_track) begin
              pattern_running_track = 1'b1; // Start the pattern detection window
            end
            else begin
              pattern_running_track = 1'b0; // End the pattern detection window
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
        @(posedge i_dclk) disable iff(valid_pattern_detected || pattern_type != perlane || valid_frame_timeout)
         ($rose(i_valid) && !valid_pattern_running)|=> 

        @(posedge valid_sample_pulse) // Sample on the generated valid sample pulse
            // first_match guarantees that once we find it, we stop checking 
            // parallel possibilities and immediately declare success.
            first_match(first_seq_16_consecutive or ##[0:$] seq_16_consecutive);
    endproperty

  property valid_active;
        @(posedge i_dclk) disable iff(!valid_pattern_detected || pattern_type != active || valid_frame_timeout)
         $rose(i_valid) |=> 
        @(posedge valid_sample_pulse) // Sample on the generated valid sample pulse
            first_seq_8bit_pattern or  seq_8bit_pattern
    endproperty

  property valid_error_check;
        @(posedge i_dclk) disable iff (!valid_pattern_detected || pattern_type != error || valid_frame_timeout)
        // Check this condition continuously while running
        1'b1 |-> (error_counter <= i_error_threshold);
    endproperty



    // clk_p Property
    property clk_p_detect_16_in_128_window;
        @(negedge i_dclk) disable iff(pattern_detected_clk_p || pattern_type != test || frame_timeout_clk_p)
         ($rose(i_clk_p) && !pattern_running_clk_p)|-> 
        first_match(##[0:$] clk_p_seq_16_consecutive);
    endproperty

    // clk_n Property
     property clk_n_detect_16_in_128_window;
        @(negedge i_dclk) disable iff(pattern_detected_clk_n || pattern_type != test || frame_timeout_clk_n)
         ($fell(i_clk_n) && !pattern_running_clk_n)|-> 

        first_match(##[0:$] clk_n_seq_16_consecutive);
    endproperty

    // track Property
    property track_detect_16_in_128_window;
        @(negedge i_dclk) disable iff(pattern_detected_track || pattern_type != test || frame_timeout_track)
         ($rose(i_track) && !pattern_running_track)|-> 

        first_match(##[0:$] track_seq_16_consecutive);
    endproperty

   assert_valid_pattern_16_frame: assert property (valid_detect_16_in_128_window) begin
    // This executes only if the pattern is found (Pass)
    valid_pattern_detected = 1'b1;

    `uvm_info("Valid Pattern", "16 consecutive 11110000 patterns detected!", UVM_HIGH)
    
    end else begin
    // This executes if the pattern is not found within the window (Fail)
    valid_pattern_detected = 1'b0;

    `uvm_info("Valid Pattern", "Failed to detect 16 consecutive 11110000 patterns within 128-cycle window!", UVM_HIGH)
    end

   assert_valid_pattern_valid_frame: assert property (valid_active) begin
    // This executes only if the pattern is found (Pass)
    `uvm_info("Valid Pattern", "Right pattern detected!", UVM_HIGH)
    
    end else begin
    // This executes if the pattern is not found within the window (Fail)
    valid_pattern_detected = 1'b0;

    `uvm_info("Valid Pattern", "Wrong pattern detected!", UVM_HIGH)
    end

  assert_valid_pattern_error_check: assert property (valid_error_check) 
    else begin
            valid_pattern_detected = 1'b0; // Flag it as failed

            `uvm_info("Valid Pattern", "FAIL: Error threshold exceeded!", UVM_HIGH)
        end
    

  assert_valid_pattern_error_check_timeout: assert property (valid_error_check_timeout) begin
     
            valid_pattern_detected = 1'b1; // Flag it as passed
            `uvm_info("Valid Pattern", "PASS: Error threshold not exceeded at timeout!", UVM_HIGH)
      
    end

  assert_clk_p_pattern_frame: assert property (clk_p_detect_16_in_128_window) begin
    // This executes only if the pattern is found (Pass)
    pattern_detected_clk_p = 1'b1;
    `uvm_info("clk_p Pattern", "16 consecutive clk_p patterns detected!", UVM_HIGH)
    
    end else begin
    // This executes if the pattern is not found within the window (Fail)
    pattern_detected_clk_p = 1'b0;
    `uvm_info("clk_p Pattern", "Failed to detect 16 consecutive clk_p patterns within 128-frame window!", UVM_HIGH)
    end

  assert_clk_n_pattern_frame: assert property (clk_n_detect_16_in_128_window) begin
    // This executes only if the pattern is found (Pass)
    pattern_detected_clk_n = 1'b1;
    `uvm_info("clk_n Pattern", "16 consecutive clk_n patterns detected!", UVM_HIGH)
    
    end else begin
    // This executes if the pattern is not found within the window (Fail)
    pattern_detected_clk_n = 1'b0;
    `uvm_info("clk_n Pattern", "Failed to detect 16 consecutive clk_n patterns within 128-frame window!", UVM_HIGH)
    end

  assert_track_pattern_frame: assert property (track_detect_16_in_128_window) begin
    // This executes only if the pattern is found (Pass)
    pattern_detected_track = 1'b1;
    `uvm_info("track Pattern", "16 consecutive track patterns detected!", UVM_HIGH)
    
    end else begin
    // This executes if the pattern is not found within the window (Fail)
    pattern_detected_track = 1'b0;
    `uvm_info("track Pattern", "Failed to detect 16 consecutive track patterns within 128-frame window!", UVM_HIGH)
    end

  


  always_comb
    if (i_reset) begin
        chk_async_reset: assert final (
          {
            
          } == '0
        );
    end


endinterface : rp_sva
