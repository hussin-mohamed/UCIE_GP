module receivers #(
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
            o_clk_p = 1'b0;
            o_track = 1'b0;
            o_clk_n = 1'b0;
        end
        if (i_enable_valid) begin
            o_valid = i_valid;
        end
        else begin
            o_valid =1'b0;
        end
        // case (i_lane_map)
        //    3'b000 : o_lanes =16'b0;
        //    3'b001 : o_lanes = (i_enable_data)?{8'b0,8'b1111_1111}:16'b0;
        //    3'b010 : o_lanes = (i_enable_data)?{8'b1111_1111,8'b0}:16'b0;
        //    3'b011 : o_lanes = (i_enable_data)?16'b1:16'b0;
        //    3'b100 : o_lanes = (i_enable_data)?{8'b0,4'b0,4'b1111}:16'b0;
        //    3'b101 : o_lanes = (i_enable_data)?{8'b0,4'b1111,4'b0}:16'b0;
        //    default: o_lanes = 16'b0;
        // endcase
        case (i_lane_enable)
            16'hffff: o_lanes = i_lanes;
            16'h0000: o_lanes = 16'b0;
            16'h00ff: o_lanes = {8'b0,i_lanes[7:0]};
            16'hff00: o_lanes = {i_lanes[15:8],8'b0};
            16'h00f0: o_lanes = {12'b0,i_lanes[7:4],4'b0};
            16'h000f: o_lanes = {12'b0,4'b0,i_lanes[3:0]};
            default: o_lanes = 16'b0;
        endcase
    end
endmodule