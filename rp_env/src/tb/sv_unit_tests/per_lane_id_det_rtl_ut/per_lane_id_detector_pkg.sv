// ============================================================================
// PACKAGE: per_lane_id_detector_pkg
// ============================================================================
package per_lane_id_detector_pkg;
  `include "uvm_macros.svh"
  import uvm_pkg::*;

  parameter pNUM_LANES  = 16;
  parameter pDATA_WIDTH = 64;
  parameter pNBYTES     = 256;

  int per_lane_pat_cnt [pNUM_LANES];
  int per_lane_iter_cnt;

  function void get_per_lane_id_results(
     input  logic [(pDATA_WIDTH/16)-1:0][15:0] _lanes         [pNUM_LANES]
    ,input  logic [2:0]                        _lane_map_code
    ,output logic                              _lanes_success [pNUM_LANES]
  );
    int start_lane;
    int num_active_lanes;

    // Initialize all success flags to 0
    for (int i = 0; i < pNUM_LANES; i++) begin
      _lanes_success[i] = 1'b0;
    end

    // Determine offset based on your lane map code
    case (_lane_map_code)
      3'b001: begin start_lane = 0; num_active_lanes = 8;  end // x8 mode, lower lanes
      3'b010: begin start_lane = 8; num_active_lanes = 8;  end // x8 mode, upper lanes
      3'b011: begin start_lane = 0; num_active_lanes = 16; end // x16 mode
      3'b100: begin start_lane = 0; num_active_lanes = 4;  end // x4 mode, lower lanes
      3'b101: begin start_lane = 4; num_active_lanes = 4;  end // x4 mode, upper lanes
      
      default:
      begin
        `uvm_fatal("PRD_PERLANE", $sformatf("Unsupported lane_map_code: %0b, Supported codes are 001b...101b", _lane_map_code))
      end
    endcase // lane_map_code

    for (int lane_idx = start_lane; lane_idx < (start_lane + num_active_lanes); lane_idx++) begin
      for (int pat_idx = 0; pat_idx < pDATA_WIDTH/16; pat_idx++) begin
        if (_lanes[lane_idx][pat_idx] == {4'b1010, 8'(lane_idx), 4'b1010}) begin
          per_lane_pat_cnt[lane_idx]++;
        end else begin
          per_lane_pat_cnt[lane_idx] = 0;
        end
      end
    end

    foreach (per_lane_pat_cnt[lane_idx]) begin
      if (per_lane_pat_cnt[lane_idx] >= 16) begin
        _lanes_success[lane_idx] = 1;
      end else begin
        _lanes_success[lane_idx] = 0;
      end
    end

    if (per_lane_iter_cnt == ((128*16)/(pDATA_WIDTH))) begin
      per_lane_iter_cnt = 0;
    end else begin
      per_lane_iter_cnt++;
    end
  endfunction : get_per_lane_id_results

endpackage : per_lane_id_detector_pkg