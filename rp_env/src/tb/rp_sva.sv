
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
);
  import rp_seq_pkg::*;

  // ============================================================================
  // Helper signals (NOT from RTL — internal to SVA checker)
  // ============================================================================
   pattern_type_t pattern_type;

   //valid pattern detection signals
   logic valid_pattern_detected   = 0;
   logic valid_pattern_running    = 0;
   logic valid_sample_pulse;
   logic valid_frame_timeout      = 0;

   //clk_p pattern detection
    logic pattern_detected_clk_p = 0;
    logic pattern_running_clk_p = 0;
    logic frame_timeout_clk_p = 0;

   //clk_n pattern detection
    logic pattern_detected_clk_n = 0;
    logic pattern_running_clk_n = 0;
    logic frame_timeout_clk_n = 0;

   //track pattern detection
    logic pattern_detected_track = 0;
    logic pattern_running_track = 0;
    logic frame_timeout_track = 0;

    // Generate a posedge pulse ONLY when the physical wires go high
    always @(posedge i_clk_p or posedge i_clk_n) begin
        valid_sample_pulse = 1'b1; // Drive high on the edge
        #1ps;                    // Wait a microscopic amount of time
        valid_sample_pulse = 1'b0; // Reset it so the SVA sees a clean posedge next time
    end

    // Generate timeout and pattern running signals based on the Valid signal's activity
    always @(posedge i_dclk) begin
        if (i_valid) begin
            valid_frame_timeout = 1'b0;
            @(negedge i_dclk);
            valid_pattern_running = 1'b1; // Start the pattern detection window
            
            // A frame is exactly 128 bytes * 8 cycles/byte = 1024 cycles
            repeat(1023) @(posedge i_dclk);
            
            // Frame is over! Fire the timeout pulse
            valid_frame_timeout = 1'b1; 
            valid_pattern_running = 1'b0; // End the pattern detection window
            if (valid_pattern_detected) valid_pattern_detected = 1'b0; // Reset for the next test
            @(posedge i_dclk);
            valid_frame_timeout = 1'b0; // Reset for the next test
        end
    end

    // Generate timeout and pattern running signals based on the clk_p signal's activity
    always @(negedge i_dclk) begin
        if (i_clk_p) begin
            frame_timeout_clk_p = 1'b0;
            @(posedge i_dclk);
            pattern_running_clk_p = 1'b1; // Start the pattern detection window
            
            // A frame is exactly 128 bytes * 8 cycles/byte = 1024 cycles
            repeat(6144) @(posedge i_dclk);
            
            // Frame is over! Fire the timeout pulse
            frame_timeout_clk_p = 1'b1; 
            pattern_running_clk_p = 1'b0; // End the pattern detection window
            if (pattern_detected_clk_p) pattern_detected_clk_p = 1'b0; // Reset for the next test
            @(negedge i_dclk);
            frame_timeout_clk_p = 1'b0; // Reset for the next test
        end
    end

    // Generate timeout and pattern running signals based on the clk_n signal's activity
    always @(negedge i_dclk) begin
        if (!i_clk_n) begin
            frame_timeout_clk_n = 1'b0;
            @(posedge i_dclk);
            pattern_running_clk_n = 1'b1; // Start the pattern detection window
            
            // A frame is exactly 128 bytes * 8 cycles/byte = 1024 cycles
            repeat(6144) @(posedge i_dclk);
            
            // Frame is over! Fire the timeout pulse
            frame_timeout_clk_n = 1'b1; 
            pattern_running_clk_n = 1'b0; // End the pattern detection window
            if (pattern_detected_clk_n) pattern_detected_clk_n = 1'b0; // Reset for the next test
            @(negedge i_dclk);
            frame_timeout_clk_n = 1'b0; // Reset for the next test
        end
    end

    // Generate timeout and pattern running signals based on the track signal's activity
    always @(negedge i_dclk) begin
        if (i_track) begin
            frame_timeout_track = 1'b0;
            @(posedge i_dclk);
            pattern_running_track = 1'b1; // Start the pattern detection window
            
            // A frame is exactly 128 bytes * 8 cycles/byte = 1024 cycles
            repeat(6144) @(posedge i_dclk);
            
            // Frame is over! Fire the timeout pulse
            frame_timeout_track = 1'b1; 
            pattern_running_track = 1'b0; // End the pattern detection window
            if (pattern_detected_track) pattern_detected_track = 1'b0; // Reset for the next test
            @(negedge i_dclk);
            frame_timeout_track = 1'b0; // Reset for the next test
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
        @(posedge i_dclk) disable iff(valid_pattern_detected)
         ($rose(i_valid) && !valid_pattern_running)|=> 

        reject_on(valid_frame_timeout)
        @(posedge valid_sample_pulse) // Sample on the generated valid sample pulse
            // first_match guarantees that once we find it, we stop checking 
            // parallel possibilities and immediately declare success.
            first_match(first_seq_16_consecutive or ##[0:896] seq_16_consecutive );
    endproperty

    // clk_p Property
    property clk_p_detect_16_in_128_window;
        @(negedge i_dclk) disable iff(pattern_detected_clk_p)
         ($rose(i_clk_p) && !pattern_running_clk_p)|-> 

        reject_on(frame_timeout_clk_p)
        first_match(##[0:5376] clk_p_seq_16_consecutive);
    endproperty

    // clk_n Property
     property clk_n_detect_16_in_128_window;
        @(negedge i_dclk) disable iff(pattern_detected_clk_n)
         ($fell(i_clk_n) && !pattern_running_clk_n)|-> 

        reject_on(frame_timeout_clk_n)
        first_match(##[0:5376] clk_n_seq_16_consecutive);
    endproperty

    // track Property
    property track_detect_16_in_128_window;
        @(negedge i_dclk) disable iff(pattern_detected_track)
         ($rose(i_track) && !pattern_running_track)|-> 

        reject_on(frame_timeout_track)
        first_match(##[0:5376] track_seq_16_consecutive);
    endproperty

  assert_valid_pattern_frame: assert property (valid_detect_16_in_128_window) begin
    // This executes only if the pattern is found (Pass)
    valid_pattern_detected = 1'b1;
    `uvm_info("Valid Pattern", "16 consecutive 11110000 patterns detected!", UVM_HIGH)
    
    end else begin
    // This executes if the pattern is not found within the window (Fail)
    valid_pattern_detected = 1'b0;
    `uvm_fatal("Valid Pattern", "Failed to detect 16 consecutive 11110000 patterns within 128-cycle window!")
    end
  assert_clk_p_pattern_frame: assert property (clk_p_detect_16_in_128_window) begin
    // This executes only if the pattern is found (Pass)
    pattern_detected_clk_p = 1'b1;
    `uvm_info("clk_p Pattern", "16 consecutive clk_p patterns detected!", UVM_HIGH)
    
    end else begin
    // This executes if the pattern is not found within the window (Fail)
    pattern_detected_clk_p = 1'b0;
    `uvm_fatal("clk_p Pattern", "Failed to detect 16 consecutive clk_p patterns within 128-frame window!")
    end

  assert_clk_n_pattern_frame: assert property (clk_n_detect_16_in_128_window) begin
    // This executes only if the pattern is found (Pass)
    pattern_detected_clk_n = 1'b1;
    `uvm_info("clk_n Pattern", "16 consecutive clk_n patterns detected!", UVM_HIGH)
    
    end else begin
    // This executes if the pattern is not found within the window (Fail)
    pattern_detected_clk_n = 1'b0;
    `uvm_fatal("clk_n Pattern", "Failed to detect 16 consecutive clk_n patterns within 128-frame window!")
    end

  assert_track_pattern_frame: assert property (track_detect_16_in_128_window) begin
    // This executes only if the pattern is found (Pass)
    pattern_detected_track = 1'b1;
    `uvm_info("track Pattern", "16 consecutive track patterns detected!", UVM_HIGH)
    
    end else begin
    // This executes if the pattern is not found within the window (Fail)
    pattern_detected_track = 1'b0;
    `uvm_fatal("track Pattern", "Failed to detect 16 consecutive track patterns within 128-frame window!")
    end

  


  always_comb
    if (i_reset) begin
        chk_async_reset: assert final (
          {
            
          } == '0
        );
    end


endinterface : rp_sva
