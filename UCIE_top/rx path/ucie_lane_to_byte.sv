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


module ucie_lane_to_byte #(
    parameter pDATA_IN_WIDTH    = 64                            ,  
    parameter pDATA_OUT_WIDTH   = 2048  
)(
    //input data from RX LFSR and control signals
    input logic                            i_clk                ,
    input logic                           i_reset               ,
    input logic                           i_enable              ,
    input logic [2:0]                     i_lane_map_code       ,
    input logic [pDATA_IN_WIDTH-1:0]        i_lane_0            ,
    input logic [pDATA_IN_WIDTH-1:0]        i_lane_1            ,
    input logic [pDATA_IN_WIDTH-1:0]        i_lane_2            ,
    input logic [pDATA_IN_WIDTH-1:0]        i_lane_3            ,
    input logic [pDATA_IN_WIDTH-1:0]        i_lane_4            ,
    input logic [pDATA_IN_WIDTH-1:0]        i_lane_5            ,
    input logic [pDATA_IN_WIDTH-1:0]        i_lane_6            ,
    input logic [pDATA_IN_WIDTH-1:0]        i_lane_7            ,
    input logic [pDATA_IN_WIDTH-1:0]        i_lane_8            ,
    input logic [pDATA_IN_WIDTH-1:0]        i_lane_9            ,
    input logic [pDATA_IN_WIDTH-1:0]        i_lane_10           ,
    input logic [pDATA_IN_WIDTH-1:0]        i_lane_11           ,
    input logic [pDATA_IN_WIDTH-1:0]        i_lane_12           ,
    input logic [pDATA_IN_WIDTH-1:0]        i_lane_13           ,
    input logic [pDATA_IN_WIDTH-1:0]        i_lane_14           ,
    input logic [pDATA_IN_WIDTH-1:0]        i_lane_15           ,
    
    //output data to RX controller
    output logic [pDATA_OUT_WIDTH-1:0]      o_data_out          ,
    output logic                            o_data_valid

);

    // =========================================================================
    // Local parameters for shift register widths based on modes
    // =========================================================================
    localparam  shift_register_X16_WIDTH  = 128                 ;
    localparam  shift_register_X8_WIDTH   = 256                 ;
    localparam shift_register_X4_WIDTH    = 512                 ;
    
    // =========================================================================
    // Internal signals   
    // =========================================================================
    wire                                p_clk                   ;
    wire                                x16_clk                 ;
    wire                                x8_clk                  ;
    wire                                x4_clk                  ;
    logic                               enable                  ;
    logic   [4:0]                       decoding                ;
    logic                               mux_8                   ;
    logic                               mux_4                   ;
    logic                               x16_en                  ;
    logic                               x8_en                   ;
    logic                               x4_en                   ;

    // Internal lane array (collect individual inputs)
    logic  [pDATA_IN_WIDTH-1:0]           lane_in [15:0]        ;
    
    // Mux output arrays for feeding into shift registers
    logic  [pDATA_IN_WIDTH-1:0]           reg_x8_in [7:0]       ;
    logic  [pDATA_IN_WIDTH-1:0]           reg_x4_in [3:0]       ;
    
    // Shift register output arrays        
    logic  [shift_register_X16_WIDTH-1:0] reg_x16_out [15:0]    ;
    logic   [15:0]                              reg_x16_valid   ;
    logic  [shift_register_X8_WIDTH-1:0]  reg_x8_out [7:0]      ;
    logic   [7:0]                              reg_x8_valid     ;
    logic  [shift_register_X4_WIDTH-1:0]  reg_x4_out [3:0]      ;
    logic     [3:0]                             reg_x4_valid    ;

    logic [pDATA_OUT_WIDTH-1:0]          data_out               ;
    logic                              data_valid               ;



    // =========================================================================
    // Collect individual lane inputs into array
    // =========================================================================
    assign lane_in[0]  = i_lane_0;
    assign lane_in[1]  = i_lane_1;
    assign lane_in[2]  = i_lane_2;
    assign lane_in[3]  = i_lane_3;
    assign lane_in[4]  = i_lane_4;
    assign lane_in[5]  = i_lane_5;
    assign lane_in[6]  = i_lane_6;
    assign lane_in[7]  = i_lane_7;
    assign lane_in[8]  = i_lane_8;
    assign lane_in[9]  = i_lane_9;
    assign lane_in[10] = i_lane_10;
    assign lane_in[11] = i_lane_11;
    assign lane_in[12] = i_lane_12;
    assign lane_in[13] = i_lane_13;
    assign lane_in[14] = i_lane_14;
    assign lane_in[15] = i_lane_15;

    // =========================================================================
    // decoder to decode lane map code and generate control signals
    // =========================================================================
    ucie_lane_to_byte_decoder u_decoder_inst (
        .i_lane_map_code(i_lane_map_code),
        .o_decoding(decoding)
    );


    // =========================================================================
    // Mux x8 - Generate block for 8 muxes
    // =========================================================================
    generate
        for (genvar i = 0; i < 8; i++) begin : gen_mux8
            ucie_mux_2_to_1 u_mux8_inst (
                .i_lane_x(lane_in[i])                               ,
                .i_lane_y(lane_in[i+8])                             ,
                .i_sel(mux_8)                                       ,
                .o_lane(reg_x8_in[i])
            );
        end
    endgenerate
    
    // =========================================================================
    // Mux x4 - Generate block for 4 muxes
    // =========================================================================
    generate
        for (genvar i = 0; i < 4; i++) begin : gen_mux4
            ucie_mux_2_to_1 u_mux4_inst (
                .i_lane_x(lane_in[i])                               ,
                .i_lane_y(lane_in[i+4])                             ,
                .i_sel(mux_4)                                       ,
                .o_lane(reg_x4_in[i])
            );
        end
    endgenerate

    // =========================================================================
    // Shift registers x16 - Generate block for 16 shift registers
    // =========================================================================
    generate
        for (genvar i = 0; i < 16; i++) begin : gen_shift_reg_x16
            ucie_shift_register #(
                .pWIDTH_OUT(shift_register_X16_WIDTH)
            ) 
            u_shift_reg_x16 (
                .clk(x16_clk)                                       ,
                .rst(i_reset)                                       ,
                .data_in(lane_in[i])                                ,
                .data_out(reg_x16_out[i])                           ,
                .data_valid(reg_x16_valid[i])
            );
        end
    endgenerate

    // =========================================================================
    // Shift registers x8 - Generate block for 8 shift registers
    // =========================================================================
    generate
        for (genvar i = 0; i < 8; i++) begin : gen_shift_reg_x8
            ucie_shift_register #(
                .pWIDTH_OUT(shift_register_X8_WIDTH)
            ) 
            u_shift_reg_x8 (
                .clk(x8_clk)                                        ,
                .rst(i_reset)                                       ,
                .data_in(reg_x8_in[i])                              ,
                .data_out(reg_x8_out[i])                            ,
                .data_valid(reg_x8_valid[i])
            );
        end
    endgenerate

    // =========================================================================
    // Shift registers x4 - Generate block for 4 shift registers
    // =========================================================================
    generate
        for (genvar i = 0; i < 4; i++) begin : gen_shift_reg_x4
            ucie_shift_register #(
                .pWIDTH_OUT(shift_register_X4_WIDTH)
            ) 
            u_shift_reg_x4 (
                .clk(x4_clk)                                        ,
                .rst(i_reset)                                       ,
                .data_in(reg_x4_in[i])                              ,
                .data_out(reg_x4_out[i])                            ,
                .data_valid(reg_x4_valid[i])
            );
        end
    endgenerate
    // =========================================================================
    // Reordering block to reorder bytes from shift registers into proper sequence based on mode
    // =========================================================================
    ucie_reordering_block #(
        .pDATA_OUT_WIDTH(pDATA_OUT_WIDTH)
    ) 
    u_reorder_inst (
        .i_clk(i_clk)                                           ,
        .i_reset(i_reset)                                       ,
        .i_mode_x16(x16_en)                                     ,
        .i_mode_x8(x8_en)                                       ,
        .i_mode_x4(x4_en)                                       ,
        .i_x16_lane_0(reg_x16_out[0])                           ,
        .i_x16_lane_1(reg_x16_out[1])                           ,
        .i_x16_lane_2(reg_x16_out[2])                           ,
        .i_x16_lane_3(reg_x16_out[3])                           ,
        .i_x16_lane_4(reg_x16_out[4])                           ,
        .i_x16_lane_5(reg_x16_out[5])                           ,
        .i_x16_lane_6(reg_x16_out[6])                           ,
        .i_x16_lane_7(reg_x16_out[7])                           ,
        .i_x16_lane_8(reg_x16_out[8])                           ,
        .i_x16_lane_9(reg_x16_out[9])                           ,
        .i_x16_lane_10(reg_x16_out[10])                         ,
        .i_x16_lane_11(reg_x16_out[11])                         ,
        .i_x16_lane_12(reg_x16_out[12])                         ,
        .i_x16_lane_13(reg_x16_out[13])                         ,
        .i_x16_lane_14(reg_x16_out[14])                         ,
        .i_x16_lane_15(reg_x16_out[15])                         ,
        .i_x8_lane_0(reg_x8_out[0])                             ,
        .i_x8_lane_1(reg_x8_out[1])                             ,
        .i_x8_lane_2(reg_x8_out[2])                             ,
        .i_x8_lane_3(reg_x8_out[3])                             ,
        .i_x8_lane_4(reg_x8_out[4])                             ,
        .i_x8_lane_5(reg_x8_out[5])                             ,
        .i_x8_lane_6(reg_x8_out[6])                             ,
        .i_x8_lane_7(reg_x8_out[7])                             ,
        .i_x4_lane_0(reg_x4_out[0])                             ,
        .i_x4_lane_1(reg_x4_out[1])                             ,
        .i_x4_lane_2(reg_x4_out[2])                             ,
        .i_x4_lane_3(reg_x4_out[3])                             ,
        .o_data_reordered(data_out)                             
    );

    // =========================================================================
    //clock gating logic
    // =========================================================================
    always_comb begin  
        if(!p_clk)begin
            enable     =    i_enable                            ;
        end
    end

    assign      p_clk      =    i_clk   &&  enable              ;                                       // Primary clock input
    assign      x16_clk    =    i_clk   &&  enable && x16_en    ;                                       // Gated clock for power saving when not enabled
    assign      x8_clk     =    i_clk   &&  enable && x8_en     ;
    assign      x4_clk     =    i_clk   &&  enable && x4_en     ;

    // =========================================================================
    //Generate control signals for muxes and lane enables based on decoding output
    // =========================================================================
                                       // Determine mux selection based on decoding signals
    assign mux_8            =       decoding[4]                 ;
    assign mux_4            =       decoding[3]                 ;
    assign x16_en           =       decoding[2]                 ;
    assign x8_en            =       decoding[1]                 ;
    assign x4_en            =       decoding[0]                 ;
    
    // =========================================================================
    // Data valid generation using reduction operators
    // =========================================================================
    assign data_valid       = (&reg_x16_valid) || (&reg_x8_valid) || (&reg_x4_valid) ;                                    
   
   
    // =========================================================================
    // Output assignment: Register the output data and valid signal
    // Pipeline: data fills shift regs -> reordering (combinatorial) -> register output
    // =========================================================================

    always @(posedge p_clk or posedge i_reset) begin
        if (i_reset) begin
            o_data_out     <=  {pDATA_OUT_WIDTH{1'b0}}          ;
            o_data_valid   <=  1'b0                             ;                       
        end 
        else if (i_enable) begin
            o_data_out     <=  data_out                         ;
            o_data_valid   <=  data_valid                       ;  // Use registered ready signal
            
        end
        
    end

endmodule
