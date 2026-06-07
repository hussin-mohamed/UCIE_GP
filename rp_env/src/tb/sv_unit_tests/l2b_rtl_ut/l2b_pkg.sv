//=============================================================================
// PACKAGE: l2b_pkg
//=============================================================================
package l2b_pkg;
  `include "uvm_macros.svh"
  import uvm_pkg::*;

  parameter pNUM_LANES  = 16;
  parameter pDATA_WIDTH = 64;
  parameter pNBYTES     = 256;

  int l2b_iter_cnt;

  function void lane2byte(
     input  logic [(pDATA_WIDTH/8)-1:0][7:0] _lanes [pNUM_LANES]
    ,input  logic [2:0]                      _lane_map_code
    ,output logic [pNBYTES-1:0][7:0]         _data
  );

    int data_byte_idx;
    int lane_byte_idx;
    int lane_idx;
    int start_lane;
    int byte_step;
    int num_iter;

    // Determine offset based on your lane map code
    case (_lane_map_code)
      3'b001: begin start_lane = 0; byte_step = 8;  end // x8 mode, lower lanes
      3'b010: begin start_lane = 8; byte_step = 8;  end // x8 mode, upper lanes
      3'b011: begin start_lane = 0; byte_step = 16; end // x16 mode
      3'b100: begin start_lane = 0; byte_step = 4;  end // x4 mode, lower lanes
      3'b101: begin start_lane = 4; byte_step = 4;  end // x4 mode, upper lanes
      
      default:
      begin
        `uvm_fatal("PRD_L2B", $sformatf("Unsupported lane_map_code: %0b, Supported codes are 001b...101b", _lane_map_code))
      end
    endcase // lane_map_code

    for (int norm_idx = 0; norm_idx < byte_step; norm_idx++) begin
      logic [(pDATA_WIDTH/8)-1:0][7:0] lane;
      lane_idx = start_lane + norm_idx;
      lane = _lanes[lane_idx];

      for (int lane_byte_idx = 0; lane_byte_idx < (pDATA_WIDTH/8); lane_byte_idx++) begin
        data_byte_idx = byte_step*(8*l2b_iter_cnt + lane_byte_idx) + norm_idx;
        _data[data_byte_idx] = lane[lane_byte_idx];
      end
    end

    num_iter = (pNBYTES/(8*byte_step)) - 1;

    if (l2b_iter_cnt == num_iter) begin
      l2b_iter_cnt = 0;
    end else begin
      l2b_iter_cnt++;
    end
  endfunction : lane2byte

endpackage : l2b_pkg