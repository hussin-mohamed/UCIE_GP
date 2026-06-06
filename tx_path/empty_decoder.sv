module decoder #(
    parameter int pNUM_LANES  = 16
) (
    input [pNUM_LANES-1:0] i_empty_done,
    input [2:0] i_lane_map,
    output logic o_empty
);

    always @(*) begin
    case (i_lane_map)
           3'b000 : o_empty = 1'b1;
           3'b001 : o_empty = &i_empty_done[7:0];
           3'b010 : o_empty = &i_empty_done[15:8];
           3'b011 : o_empty = &i_empty_done;
           3'b100 : o_empty = &i_empty_done[3:0];
           3'b101 : o_empty = &i_empty_done[15:12];
           default: o_empty = 1'b1;
    endcase
    end
endmodule