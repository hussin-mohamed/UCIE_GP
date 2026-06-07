package dut_per_lane_id_modelling_pkg;

    parameter LANES_NUMBER = 16;       //It defines the number of lanes in the system, which is 16 in this case (Lane 0 to Lane 15)

    task static dut_per_lane_id_modelling (
        input i_reset,
        input i_enable,
        output [63:0] o_lane [0:LANES_NUMBER-1]
        );

        if (!i_reset || !i_enable) begin
            foreach (o_lane[i]) begin
                o_lane[i] = 0;
            end
        end else begin
            foreach (o_lane[i]) begin
                o_lane[i] = {48'b0,4'b0101,i,4'b0101};
            end
        end
    endtask
endpackage
