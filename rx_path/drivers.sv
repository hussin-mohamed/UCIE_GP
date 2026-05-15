module driver #(
    parameter int pNUM_LANES  = 16
) (
    input i_clk_p,i_clk_n,i_track,i_valid,i_enable_clk,i_enable_valid,i_enable_data,
    input [pNUM_LANES-1 :0] i_lanes,
    input [pNUM_LANES-1 :0] i_lane_enable,
    input [2:0] i_lane_map,
    output logic o_clk_p,o_clk_n,o_track,o_valid,
    output logic [pNUM_LANES-1 :0] o_lanes
);
    always @(*) begin
        if (i_enable_clk) begin
            o_clk_p = i_clk_p;
            o_track = i_track;
            o_clk_n = i_clk_n;
        end
        else begin
            o_clk_p = 1'bz;
            o_track = 1'bz;
            o_clk_n = 1'bz;
        end
        if (i_enable_valid) begin
            o_valid = i_valid;
        end
        else begin
            o_valid =1'bz;
        end
        // case (i_lane_map)
        //    3'b000 : o_lanes =16'bz;
        //    3'b001 : o_lanes = (i_enable_data)?{8'bz,8'b1111_1111}:16'bz;
        //    3'b010 : o_lanes = (i_enable_data)?{8'b1111_1111,8'bz}:16'bz;
        //    3'b011 : o_lanes = (i_enable_data)?16'b1:16'bz;
        //    3'b100 : o_lanes = (i_enable_data)?{8'bz,4'bz,4'b1111}:16'bz;
        //    3'b101 : o_lanes = (i_enable_data)?{8'bz,4'b1111,4'bz}:16'bz;
        //    default: o_lanes = 16'bz;
        // endcase
        case (i_lane_enable)
            16'hffff: o_lanes = i_lanes;
            16'h0000: o_lanes = 16'bz;
            16'h00ff: o_lanes = {8'bz,i_lanes[7:0]};
            16'hff00: o_lanes = {i_lanes[15:8],8'bz};
            16'h00f0: o_lanes = {12'bz,i_lanes[7:4],4'bz};
            16'h000f: o_lanes = {12'bz,4'bz,i_lanes[3:0]};
            default: o_lanes = 16'bz;
        endcase
    end
endmodule