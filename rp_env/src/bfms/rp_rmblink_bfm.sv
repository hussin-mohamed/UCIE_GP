// ****************************************************************************
// *                                                                          *
// * Copyright (c) 2014-2015 Synopsys Inc. All rights reserved.               *
// *                                                                          *
// * Synopsys Proprietary and Confidential. This file contains confidential   *
// * information and the trade secrets of Synopsys Inc. Use, disclosure, or   *
// * reproduction is prohibited without the prior express written permission  *
// * of Synopsys, Inc.                                                        *
// *                                                                          *
// * Synopsys, Inc.                                                           *
// * 700 East Middlefield Road                                                *
// * Mountain View, California 94043                                          *
// * (800) 541-7737                                                           *
// *                                                                          *
// ****************************************************************************

`include "uvm_macros.svh"
import shared_pkg::*;
import uvm_pkg::*;


// Interface: rp_rmblink_bfm
// Description: Serial RX-Path communication interface with partner UCIe die
//              (RMBLINK - RX Mainband Link)
//******************************************************************************

interface rp_rmblink_bfm(
  input logic clk
 ,input logic i_hclk
 ,input logic i_dclk
 ,input logic reset
);

  logic                  i_clk_p;
  logic                  i_clk_n;
  logic                  i_track;
  logic [pNUM_LANES-1:0] i_data;
  logic                  i_valid;

  logic [8:0]            i_rx_encoding;

  //============================================================================
  // Methods
  //============================================================================
  always @(posedge reset) begin
    i_clk_p <= 0;
    i_clk_n <= 1;
    i_track <= 0;
    i_data  <= 0;
    i_valid <= 0;
  end

  //============================================================================
  // Amr
  //============================================================================
  task serialize_data(
     input logic [pDATA_WIDTH-1:0] _data         [pNUM_LANES]
    ,input logic [7:0]             _val_stream   []
    ,input logic                   _clk_stream_p []
    ,input logic                   _clk_stream_n []
    ,input logic                   _track_stream []
    ,input int                     _idle_ui_cnt
  );
    bit [2:0] val_byte_idx, val_bit_idx;
    int val_num_bytes;

    val_num_bytes = pDATA_WIDTH / 8;
    
    if (_val_stream.size() != val_num_bytes) begin
      `uvm_fatal("RMBLINK_BFM", $sformatf("Invalid val_stream size: %0d, valid size must be: %0d", _val_stream.size(), val_num_bytes))
    end
    if (_clk_stream_p.size() != pDATA_WIDTH) begin
      `uvm_fatal("RMBLINK_BFM", $sformatf("Invalid clk_stream_p size: %0d, valid size must be: %0d", _clk_stream_p.size(), pDATA_WIDTH))
    end
    if (_clk_stream_n.size() != pDATA_WIDTH) begin
      `uvm_fatal("RMBLINK_BFM", $sformatf("Invalid clk_stream_n size: %0d, valid size must be: %0d", _clk_stream_n.size(), pDATA_WIDTH))
    end
    if (_track_stream.size() != pDATA_WIDTH) begin
      `uvm_fatal("RMBLINK_BFM", $sformatf("Invalid track_stream size: %0d, valid size must be: %0d", _track_stream.size(), pDATA_WIDTH))
    end

    // Iterate through each bit position (Time dimension)
    for (int dat_bit_idx = 0; dat_bit_idx < pDATA_WIDTH; dat_bit_idx++) begin
      
      @(posedge i_dclk);
      // At this specific time instant, iterate through all lanes (Space dimension)
      for (int lane_idx = 0; lane_idx < pNUM_LANES; lane_idx++) begin
        i_data[lane_idx] <= _data[lane_idx][dat_bit_idx];
      end
      val_byte_idx = dat_bit_idx / 8;
      i_valid      <= _val_stream[val_byte_idx][val_bit_idx];
      val_bit_idx++;

      @(negedge i_dclk);
      i_clk_p <= _clk_stream_p[dat_bit_idx];
      i_clk_n <= _clk_stream_n[dat_bit_idx];
      i_track <= _track_stream[dat_bit_idx];
    end

    // Deassert everything during the idle period
    @(negedge i_dclk);
    i_clk_p <= 1'b0;
    i_clk_n <= 1'b1;
    i_data  <= '0;
    i_valid <= 1'b0;
    
    // Wait for _idle_ui_cnt UI
    repeat(_idle_ui_cnt) @(posedge i_dclk);
  endtask : serialize_data

  task deserialize_data(
     output logic [pDATA_WIDTH-1:0] _data [pNUM_LANES]
    ,output logic [7:0]             _val_stream   []
  );
    bit [2:0] val_byte_idx, val_bit_idx;

    while (!i_valid) begin
      @(posedge i_clk_p);
    end

    _val_stream = new[pDATA_WIDTH/8];
    
    // Iterate through each bit position (Time dimension)
    for (int dat_bit_idx = 0; dat_bit_idx < pDATA_WIDTH; dat_bit_idx++) begin

      val_byte_idx = dat_bit_idx / 8;
        
      // At this specific time instant, iterate through all lanes (Space dimension)
      for (int lane_idx = 0; lane_idx < pNUM_LANES; lane_idx++) begin
        _data[lane_idx][dat_bit_idx] = i_data[lane_idx];
      end
      _val_stream[val_byte_idx][val_bit_idx] = i_valid;
      val_bit_idx++;
      
      if (dat_bit_idx == 63) begin
        break;
      end

      if (dat_bit_idx%2 == 0) begin
        @(posedge i_clk_n);
      end else begin
        @(posedge i_clk_p);
      end
    end
  endtask : deserialize_data

  //============================================================================
  // Araby
  //============================================================================
  task serialize_valid_pattern(
      input logic        [7:0]               _val_stream   []
     ,input logic                            _clk_stream_p []
     ,input logic                            _clk_stream_n []
     ,input logic                            _track_stream []    
  );
    if (_clk_stream_p.size() != _clk_stream_n.size()) begin
      `uvm_fatal("CLK_STREAM_SIZE_MISMATCH", "Clock stream arrays must be of the same size in serialize_valid_pattern.")
    end

    if (_clk_stream_p.size() != CLK_STREAM_LEN_VALID_PAT || _clk_stream_n.size() != CLK_STREAM_LEN_VALID_PAT) begin
        `uvm_fatal("CLK_STREAM_SIZE_HR", "Clock stream arrays must have exactly {CLK_STREAM_LEN_VALID_PAT} elements for Half Rate (HR) mode in serialize_valid_pattern.")
    end

    if (_val_stream.size() != VALID_CLK_PATTERN_STREAM_LEN) begin
      `uvm_fatal("VALID_STREAM_SIZE_MISMATCH", "Valid stream arrays must be of size {VALID_CLK_PATTERN_STREAM_LEN} in serialize_valid_pattern.")
    end

      for (int t = 0; t < $size(_val_stream , 1); t++) begin
          for (int i = 0; i < $size(_val_stream , 2); i++) begin
            @(posedge i_dclk)
            i_valid    <= _val_stream[t][i];
            @(negedge i_dclk)
            i_clk_p    <= _clk_stream_p[(t * 8) + i];
            i_clk_n    <= _clk_stream_n[(t * 8) + i];
            i_track    <= _track_stream[(t * 8) + i];
          end
        end
  endtask : serialize_valid_pattern



  task serialize_clk_pattern(
      input logic                            _clk_stream_p []
     ,input logic                            _clk_stream_n []
     ,input logic                            _track_stream []
     ,input int unsigned                     _idle_ui_cnt       
  );
    if (_clk_stream_p.size() != _clk_stream_n.size()) begin
      `uvm_fatal("CLK_STREAM_SIZE_MISMATCH", "Clock stream arrays must be of the same size in serialize_clk_pattern.")
    end

    if (_clk_stream_p.size() != CLK_STREAM_LEN_CLK_PAT  || _clk_stream_n.size() != CLK_STREAM_LEN_CLK_PAT) begin
        `uvm_fatal("CLK_STREAM_SIZE_HR", "Clock stream arrays must have exactly {CLK_STREAM_LEN_CLK_PAT} elements for Half Rate (HR) mode in serialize_clk_pattern.")
    end

      for (int t = 0; t < VALID_CLK_PATTERN_STREAM_LEN; t++) begin
          for (int i = 0; i < CLK_STROBE_CLK_PAT; i++) begin
            @(posedge i_dclk)
            i_clk_p    <= _clk_stream_p[(t*CLK_STROBE_CLK_PAT) + i];
            i_clk_n    <= _clk_stream_n[(t*CLK_STROBE_CLK_PAT) + i];
            i_track    <= _track_stream[(t*CLK_STROBE_CLK_PAT) + i];
          end

          // Deassert everything during the idle period
          for (int d = 0; d < _idle_ui_cnt; d++) begin
            @(posedge i_dclk)
            i_clk_p <= 1'b0;
            i_clk_n <= 1'b1;
            i_track <= 1'b0;
          end
        end
  endtask : serialize_clk_pattern
  


endinterface : rp_rmblink_bfm
