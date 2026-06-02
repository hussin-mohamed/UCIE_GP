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


module ucie_shift_register_b2l #(
    parameter INPUT_WIDTH = 128                         // Input width: 128, 256, or 512 bits (default 128)
) (
    input  logic                        clk             ,
    input  logic                        rst             ,
    input  logic [INPUT_WIDTH-1:0]      data_in         ,
    input  logic                        data_in_valid   ,
    output logic [63:0]                 data_out        ,
    output logic                        b2l_ready
);

    // =========================================================================
    // Parameters
    // =========================================================================
    localparam OUTPUT_WIDTH = 64;                       // Always 64 bits (8 bytes)
    localparam NUM_STAGES = INPUT_WIDTH / OUTPUT_WIDTH  ; // Number of output cycles
    localparam COUNTER_WIDTH = $clog2(NUM_STAGES);

    // =========================================================================
    // Internal Signals
    // =========================================================================
    logic [INPUT_WIDTH-1:0]         shift_reg, shift_reg_next;
    logic [COUNTER_WIDTH-1:0]       stage_count, stage_count_next;
    logic                           active, active_next;
    logic                           data_sent;

    // =========================================================================
    // Combinational Logic
    // =========================================================================
    always_comb begin
    shift_reg_next   = shift_reg;
    stage_count_next = stage_count;
    active_next      = active;
    data_sent        = 1'b0;

    if (active) begin
        // Last chunk
        if (stage_count == (NUM_STAGES - 1)) begin
            data_sent = 1'b1;

            if (data_in_valid) begin
                shift_reg_next   = data_in;
                stage_count_next = 0;
                active_next      = 1'b1;
            end 
            else begin
                active_next = 1'b0;
            end
        end
        else begin
            // Shift data for next output chunk
            shift_reg_next   = shift_reg >> OUTPUT_WIDTH;
            stage_count_next = stage_count + 1;
            active_next      = 1'b1;
        end
    end
    else begin
        // Idle → load new data
        if (data_in_valid) begin
            shift_reg_next   = data_in;
            stage_count_next = 0;
            active_next      = 1'b1;
            end
        
        else begin
            active_next = 1'b0;
        end
        end
    end

    // =========================================================================
    // Output Assignment (LSB first)
    // =========================================================================
    assign data_out = shift_reg[OUTPUT_WIDTH-1:0];
    assign b2l_ready = !active; // Ready when not active (idle state)

    // =========================================================================
    // Sequential Logic
    // =========================================================================
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            shift_reg <= {INPUT_WIDTH{1'b0}};
            stage_count <= {COUNTER_WIDTH{1'b0}};
            active <= 1'b0;
        end else begin
            shift_reg <= shift_reg_next;
            stage_count <= stage_count_next;
            active <= active_next;
        end
    end

endmodule
