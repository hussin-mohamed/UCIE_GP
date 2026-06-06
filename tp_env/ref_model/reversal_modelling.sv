//=============================================================================
// File       : reversal_modelling.sv
// Project    : UCIe 3.0 TX Logical PHY Verification
// Description: Lane reversal reference model — mirrors the RTL reversal.sv
//              behavior for the scoreboard/predictor.
//=============================================================================

package reversal_modelling_pkg;

    parameter int DATA_WIDTH  = 64;
    parameter int LANES_NUMBER = 16;

    // -------------------------------------------------------------------------
    // Task: apply_lane_reversal
    //
    // Description: Applies lane reversal based on control signal from TX
    //              controller. Reversal is done within the active lane group
    //              only, as specified by lane_map_code.
    //
    // Inputs:
    //   i_reverse    - Control signal (from o_tx_reverse of controller)
    //   i_lane_map   - Lane map code (3'b001: lanes 0-7, 3'b010: lanes 8-15, 3'b011: all lanes)
    //   i_lanes      - Input lane data [0:LANES_NUMBER-1]
    //
    // Outputs:
    //   o_lanes      - Reversed (or straight) lane data
    //
    // Behavior:
    //   When i_reverse = 0: o_lanes[i] = i_lanes[i]     (straight)
    //   When i_reverse = 1 and lane_map = 0-7:  o_lanes[0]=i_lanes[7], o_lanes[1]=i_lanes[6], etc.
    //   When i_reverse = 1 and lane_map = 8-15: o_lanes[8]=i_lanes[15], o_lanes[9]=i_lanes[14], etc.
    //   When i_reverse = 1 and lane_map = all:  o_lanes[0]=i_lanes[15], o_lanes[1]=i_lanes[14], etc.
    // -------------------------------------------------------------------------

    task static apply_lane_reversal (
        input  logic                             i_reverse,
        input  logic [2:0]                       i_lane_map,
        input  logic [DATA_WIDTH-1:0]            i_lanes [0:LANES_NUMBER-1],
        output logic [DATA_WIDTH-1:0]            o_lanes [0:LANES_NUMBER-1]
    );

        // First, pass through all lanes
        for (int i = 0; i < LANES_NUMBER; i++) begin
            o_lanes[i] = i_lanes[i];
        end

        // Apply reversal based on lane map
        if (i_reverse) begin
            case (i_lane_map)
                3'b001: begin // Lanes 0-7 only
                    for (int i = 0; i < 8; i++) begin
                        o_lanes[i] = i_lanes[7 - i];
                    end
                end
                3'b010: begin // Lanes 8-15 only
                    for (int i = 8; i < 16; i++) begin
                        o_lanes[i] = i_lanes[23 - i];  // 23-8=15, 23-15=8
                    end
                end
                3'b011: begin // All lanes
                    for (int i = 0; i < LANES_NUMBER; i++) begin
                        o_lanes[i] = i_lanes[LANES_NUMBER - 1 - i];
                    end
                end
                default: begin // No reversal for other codes
                    // Keep straight (already set above)
                end
            endcase
        end

    endtask

endpackage
