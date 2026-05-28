package LFSR_modelling_pkg;

parameter DATA_WIDTH = 64;         //It defines the width of the data input & output ports
parameter LFSR_STAGES = 23;        //It says the seed specified per lane
parameter LANES_NUMBER = 16;       //It defines the number of lanes in the system, which is 16 in this case (Lane 0 to Lane 15)

parameter integer LANE_ID [0:7] = '{
    23'h1DBFBC, // Lane 0,8
    23'h0607BB, // Lane 1,9
    23'h1EC760, // Lane 2,10
    23'h18C0DB, // Lane 3,11
    23'h010F12, // Lane 4,12
    23'h19CFC9, // Lane 5,13
    23'h0277CE, // Lane 6,14
    23'h1BB807  // Lane 7,15
};

    task static LFSR_update (
    input i_enable,
    input i_disable,
    input i_load,
    output lfsr_reg [0:LFSR_STAGES-1] [0:LANES_NUMBER-1]
    ); 

        logic lfsr_reg_old [0:LFSR_STAGES-1] [0:LANES_NUMBER-1];

        if ((i_enable && !i_disable) || i_load) begin
            if (i_load) begin
                foreach (lfsr_reg[i,j]) begin
                    lfsr_reg[i][j] = LANE_ID[j % 8][i];
                end
            end else begin
                foreach (lfsr_reg[i,j]) begin
                    if ((i == 2) || (i == 5) || (i == 8) || (i == 16) || (i == 21) || (i == 23)) begin
                        lfsr_reg[i][j] = lfsr_reg_old[i-1][j] ^ lfsr_reg_old[LFSR_STAGES-1][j];
                    end else if (i == 0) begin
                        lfsr_reg[i][j] = lfsr_reg_old[LFSR_STAGES-1][j];
                    end else begin
                        lfsr_reg[i][j] = lfsr_reg_old[i-1][j];
                    end
                end
            end
        end else begin
            foreach (lfsr_reg[i,j]) begin
                lfsr_reg[i][j] = lfsr_reg[i][j]; // Hold the current state
            end
        end

        lfsr_reg_old = lfsr_reg; // Update the old register with the new values for the next cycle
    endtask

    task static LFSR_modelling (
    input [DATA_WIDTH-1:0] i_data_in [0:LANES_NUMBER-1],
    input i_enable,
    input i_disable,
    input i_load,
    input i_train,
    output [DATA_WIDTH-1:0] o_data_out [0:LANES_NUMBER-1]
    );
        logic lfsr_reg [0:LFSR_STAGES-1] [0:LANES_NUMBER-1];
        for (int j=0; j<DATA_WIDTH; j++) begin
            if (i_load) begin
                foreach (o_data_out[i]) begin
                    o_data_out[i][j] = LANE_ID[i % 8][LFSR_STAGES-1];
                end
            end else if (i_train) begin
                foreach (o_data_out[i]) begin
                    o_data_out[i][j] = lfsr_reg[LFSR_STAGES-1][i];
                end
            end else begin
                foreach (o_data_out[i]) begin
                    o_data_out[i][j] = i_data_in[i][j] ^ lfsr_reg[LFSR_STAGES-1][i];
                end
            end
            LFSR_update(i_enable, i_disable, i_load, lfsr_reg);
        end
    endtask
endpackage