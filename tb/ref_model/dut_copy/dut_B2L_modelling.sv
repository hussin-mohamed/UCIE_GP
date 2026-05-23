package dut_B2L_modelling_pkg;

    parameter NBYTES = 256;
    parameter DATA_WIDTH = 64;         //It defines the width of the data input & output ports
    parameter LANES_NUMBER = 16;       //It defines the number of lanes in the system, which is 16 in this case (Lane 0 to Lane 15)
    
    localparam NONE = 3'b000;
    localparam LOGICAL_LANES_0_TO_7 = 3'b001;
    localparam LOGICAL_LANES_8_TO_15 = 3'b010;
    localparam ALL_LANES = 3'b011;

    task static dut_B2L_modelling (
        input [2:0] i_lane_map_code,
        input i_reset,
        input enable,
        input [7:0] i_lp_data [0:NBYTES-1],
        output [DATA_WIDTH-1:0] o_lane [0:LANES_NUMBER-1],
        output o_data_sent
        ); 
    
        logic [7:0] lane_data [$][0:NBYTES-1];
        logic [7:0] current_data [0:NBYTES-1];
    
        logic idle;
        int count_byte;
    
        if (!i_reset || !enable) begin
            lane_data.delete();
            current_data = '{default:0};
        end else begin
            lane_data.push_back(i_lp_data);
        end
    
        if ((lane_data.size() == 0)) begin
            idle = 1;
        end
    
        if ((idle || o_data_sent) && (lane_data.size() >= 1)) begin
            current_data = lane_data.pop_front();
            idle = 0;
        end
    
        if (!i_reset || !enable) begin
            foreach (o_lane[i]) begin
                o_lane[i] = 0;
            end
            o_data_sent = 0;
            count_byte = 0;
        end else begin
            case (i_lane_map_code)
                NONE: begin
                    foreach (o_lane[i]) begin
                        o_lane[i] = 0;
                    end
                    o_data_sent = 0;
                end
    
                LOGICAL_LANES_0_TO_7: begin
                    for (int i=0; i < 8; i++) begin
                        o_lane[i] = {current_data[i+(32*count_byte)], current_data[i+8+(32*count_byte)], current_data[i+16+(32*count_byte)], current_data[i+24+(32*count_byte)]};
                    end   
                    if ((count_byte+1)*4*(LANES_NUMBER/2) == NBYTES) begin
                        o_data_sent = 1;
                        count_byte = 0;
                    end else begin
                        o_data_sent = 0;
                        count_byte++;
                    end
                end
    
                LOGICAL_LANES_8_TO_15: begin
                    for (int i=8; i < 16; i++) begin
                        o_lane[i] = {current_data[i+(32*count_byte)], current_data[i+8+(32*count_byte)], current_data[i+16+(32*count_byte)], current_data[i+24+(32*count_byte)]};
                    end   
                    if ((count_byte+1)*4*(LANES_NUMBER/2) == NBYTES) begin
                        o_data_sent = 1;
                        count_byte = 0;
                    end else begin
                        o_data_sent = 0;
                        count_byte++;
                    end
                end
    
                ALL_LANES: begin
                    foreach (o_lane[i]) begin
                        o_lane[i] = {current_data[i+(64*count_byte)], current_data[i+16+(64*count_byte)], current_data[i+32+(64*count_byte)], current_data[i+48+(64*count_byte)]};
                    end   
                    if ((count_byte+1)*4*LANES_NUMBER == NBYTES) begin
                        o_data_sent = 1;
                        count_byte = 0;
                    end else begin
                        o_data_sent = 0;
                        count_byte++;
                    end
                end
            endcase
        end
    endtask
endpackage