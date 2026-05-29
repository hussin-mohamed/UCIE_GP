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


module ucie_shift_register #(
    parameter pWIDTH_OUT = 128  // Output width (default 128 bits)
) (
    input  logic                    clk                         ,
    input  logic                    rst                         ,
    input  logic [63:0]             data_in                     ,
    output logic [pWIDTH_OUT-1:0]    data_out                   ,
    output logic                    data_valid
);
    
    // =========================================================================
    // Internal shift register (output width)
    // =========================================================================
    logic [pWIDTH_OUT-1:0] shift_reg                             ;               // Shift register to hold incoming data until we have enough for output
    logic [pWIDTH_OUT-1:0] shift_reg_next                        ;               // Next state of the shift register
    logic [7:0] count                                           ;               // Counter to track how many 64-bit words have been shifted in
    logic [7:0] count_next                                      ;               // Next state of the counter

    // =========================================================================
    // Calculate number of stages needed
    // =========================================================================
    localparam STAGES          =    (pWIDTH_OUT / 64)              ;       // Number of 64-bit stages




    // =========================================================================
    // Combinational logic for shifting
    // =========================================================================
    always_comb begin
        // Shift operation: input goes to LSB, data shifts left
        shift_reg_next = {data_in,shift_reg[pWIDTH_OUT-1:64]}   ;               // Shift left by 64 bits and insert new data at LSB
    end


    // =========================================================================
    // Output assignment (select upper pWIDTH_OUT bits)
    // =========================================================================
    assign data_out         =    shift_reg[pWIDTH_OUT-1:0]       ;



    always_comb begin
        if (count == STAGES+1) begin
            count_next  =   1'b1                                ;
            data_valid  =   1'b1                                ;
        end else begin
            count_next  =   count + 1'b1                        ;
            data_valid  =    1'b0                               ;
        end
    end


    // =========================================================================
    // Sequential logic
    // =========================================================================
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            shift_reg         <=    {pWIDTH_OUT{1'b0}}          ;
            count             <=   8'b0                         ;
        end 
        else begin
            shift_reg         <=    shift_reg_next              ;
            count             <=   count_next                   ;

        end
    end


endmodule
