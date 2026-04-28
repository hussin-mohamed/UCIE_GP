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

    // Internal registers for mux outputs to feed into shift registers
    logic  [pDATA_IN_WIDTH-1:0]           reg_x8_in0            ;
    logic  [pDATA_IN_WIDTH-1:0]           reg_x8_in1            ;
    logic  [pDATA_IN_WIDTH-1:0]           reg_x8_in2            ;
    logic  [pDATA_IN_WIDTH-1:0]           reg_x8_in3            ;
    logic  [pDATA_IN_WIDTH-1:0]           reg_x8_in4            ;
    logic  [pDATA_IN_WIDTH-1:0]           reg_x8_in5            ;
    logic  [pDATA_IN_WIDTH-1:0]           reg_x8_in6            ;
    logic  [pDATA_IN_WIDTH-1:0]           reg_x8_in7            ;
    logic  [pDATA_IN_WIDTH-1:0]           reg_x4_in0            ;
    logic  [pDATA_IN_WIDTH-1:0]           reg_x4_in1            ;
    logic  [pDATA_IN_WIDTH-1:0]           reg_x4_in2            ;
    logic  [pDATA_IN_WIDTH-1:0]           reg_x4_in3            ;
    
    // Shift register outputs        
    logic  [shift_register_X16_WIDTH-1:0] reg_x16_out0          ;
    logic  [shift_register_X16_WIDTH-1:0] reg_x16_out1          ;
    logic  [shift_register_X16_WIDTH-1:0] reg_x16_out2          ;
    logic  [shift_register_X16_WIDTH-1:0] reg_x16_out3          ;
    logic  [shift_register_X16_WIDTH-1:0] reg_x16_out4          ;
    logic  [shift_register_X16_WIDTH-1:0] reg_x16_out5          ;
    logic  [shift_register_X16_WIDTH-1:0] reg_x16_out6          ;
    logic  [shift_register_X16_WIDTH-1:0] reg_x16_out7          ;
    logic  [shift_register_X16_WIDTH-1:0] reg_x16_out8          ;
    logic  [shift_register_X16_WIDTH-1:0] reg_x16_out9          ;
    logic  [shift_register_X16_WIDTH-1:0] reg_x16_out10         ;
    logic  [shift_register_X16_WIDTH-1:0] reg_x16_out11         ;
    logic  [shift_register_X16_WIDTH-1:0] reg_x16_out12         ;
    logic  [shift_register_X16_WIDTH-1:0] reg_x16_out13         ;
    logic  [shift_register_X16_WIDTH-1:0] reg_x16_out14         ;
    logic  [shift_register_X16_WIDTH-1:0] reg_x16_out15         ;
    logic                                 reg_x16_valid_0       ;
    logic                                 reg_x16_valid_1       ;
    logic                                 reg_x16_valid_2       ;
    logic                                 reg_x16_valid_3       ;
    logic                                 reg_x16_valid_4       ;
    logic                                 reg_x16_valid_5       ;
    logic                                 reg_x16_valid_6       ;
    logic                                 reg_x16_valid_7       ;
    logic                                 reg_x16_valid_8       ;
    logic                                 reg_x16_valid_9       ;
    logic                                 reg_x16_valid_10      ;
    logic                                 reg_x16_valid_11      ;
    logic                                 reg_x16_valid_12      ;
    logic                                 reg_x16_valid_13      ;
    logic                                 reg_x16_valid_14      ;
    logic                                 reg_x16_valid_15      ;
    logic  [shift_register_X8_WIDTH-1:0]  reg_x8_out0           ;
    logic  [shift_register_X8_WIDTH-1:0]  reg_x8_out1           ;
    logic  [shift_register_X8_WIDTH-1:0]  reg_x8_out2           ;
    logic  [shift_register_X8_WIDTH-1:0]  reg_x8_out3           ;
    logic  [shift_register_X8_WIDTH-1:0]  reg_x8_out4           ;
    logic  [shift_register_X8_WIDTH-1:0]  reg_x8_out5           ;
    logic  [shift_register_X8_WIDTH-1:0]  reg_x8_out6           ;
    logic  [shift_register_X8_WIDTH-1:0]  reg_x8_out7           ;
    logic                                 reg_x8_valid_0        ;
    logic                                 reg_x8_valid_1        ;
    logic                                 reg_x8_valid_2        ;
    logic                                 reg_x8_valid_3        ;
    logic                                 reg_x8_valid_4        ;
    logic                                 reg_x8_valid_5        ;
    logic                                 reg_x8_valid_6        ;
    logic                                 reg_x8_valid_7        ;
    logic  [shift_register_X4_WIDTH-1:0]  reg_x4_out0           ;
    logic  [shift_register_X4_WIDTH-1:0]  reg_x4_out1           ;
    logic  [shift_register_X4_WIDTH-1:0]  reg_x4_out2           ;
    logic  [shift_register_X4_WIDTH-1:0]  reg_x4_out3           ;
    logic                                 reg_x4_valid_0        ;
    logic                                 reg_x4_valid_1        ;
    logic                                 reg_x4_valid_2        ;
    logic                                 reg_x4_valid_3        ;

    logic [pDATA_OUT_WIDTH-1:0]          data_out               ;
    logic                              data_valid               ;



    // =========================================================================
    //instantiate decoder to decode lane map code and generate control signals for muxes and lane enables
    // =========================================================================
    ucie_lane_to_byte_decoder u_decoder_inst (
        .i_lane_map_code(i_lane_map_code),
        .o_decoding(decoding)
    );


    // =========================================================================
    //mux x8
    // =========================================================================

    ucie_mux_2_to_1 u_mux8_inst_0 (
        .i_lane_x(i_lane_0)                                     ,
        .i_lane_y(i_lane_8)                                     ,
        .i_sel(mux_8)                                           ,
        .o_lane(reg_x8_in0)
    );
    ucie_mux_2_to_1 u_mux8_inst_1 (
        .i_lane_x(i_lane_1)                                     ,
        .i_lane_y(i_lane_9)                                     ,
        .i_sel(mux_8)                                           ,
        .o_lane(reg_x8_in1)
    );
    ucie_mux_2_to_1 u_mux8_inst_2 (
        .i_lane_x(i_lane_2)                                     ,
        .i_lane_y(i_lane_10)                                    ,
        .i_sel(mux_8)                                           ,
        .o_lane(reg_x8_in2)
    );
    ucie_mux_2_to_1 u_mux8_inst_3 (
        .i_lane_x(i_lane_3)                                     ,
        .i_lane_y(i_lane_11)                                    ,
        .i_sel(mux_8)                                           ,
        .o_lane(reg_x8_in3)
    );
    ucie_mux_2_to_1 u_mux8_inst_4 (
        .i_lane_x(i_lane_4)                                     ,
        .i_lane_y(i_lane_12)                                    ,
        .i_sel(mux_8)                                           ,
        .o_lane(reg_x8_in4)
    );
    ucie_mux_2_to_1 u_mux8_inst_5 (
        .i_lane_x(i_lane_5)                                     ,
        .i_lane_y(i_lane_13)                                    ,
        .i_sel(mux_8)                                           ,
        .o_lane(reg_x8_in5)
    );
    ucie_mux_2_to_1 u_mux8_inst_6 (
        .i_lane_x(i_lane_6)                                     ,
        .i_lane_y(i_lane_14)                                    ,
        .i_sel(mux_8)                                           ,
        .o_lane(reg_x8_in6)
    );
    ucie_mux_2_to_1 u_mux8_inst_7 (
        .i_lane_x(i_lane_7)                                     ,
        .i_lane_y(i_lane_15)                                    ,
        .i_sel(mux_8)                                           ,
        .o_lane(reg_x8_in7)
    );    
    
    // =========================================================================
    //mux x4
    // =========================================================================
    ucie_mux_2_to_1 u_mux4_inst_0 (
        .i_lane_x(i_lane_0)                                     ,
        .i_lane_y(i_lane_4)                                     ,
        .i_sel(mux_4)                                           ,
        .o_lane(reg_x4_in0)
    );
    ucie_mux_2_to_1 u_mux4_inst_1 (
        .i_lane_x(i_lane_1)                                     ,
        .i_lane_y(i_lane_5)                                     ,
        .i_sel(mux_4)                                           ,
        .o_lane(reg_x4_in1)
    );
    ucie_mux_2_to_1 u_mux4_inst_2 (
        .i_lane_x(i_lane_2)                                     ,
        .i_lane_y(i_lane_6)                                     ,
        .i_sel(mux_4)                                           ,
        .o_lane(reg_x4_in2)
    );
    ucie_mux_2_to_1 u_mux4_inst_3 (
        .i_lane_x(i_lane_3)                                     ,
        .i_lane_y(i_lane_7)                                     ,
        .i_sel(mux_4)                                           ,
        .o_lane(reg_x4_in3)
    );

    // =========================================================================
    //instantiate shift register to accumulate data and generate output data and valid signal x16
    // =========================================================================

    ucie_shift_register #(
        .pWIDTH_OUT(shift_register_X16_WIDTH)
    ) 
    u_shift_reg_x16_0 (
        .clk(x16_clk)                                           ,
        .rst(i_reset)                                           ,
        .data_in(i_lane_0)                                      ,
        .data_out(reg_x16_out0)                                 ,
        .data_valid(reg_x16_valid_0)
    );

    ucie_shift_register #(
        .pWIDTH_OUT(shift_register_X16_WIDTH)
    ) 
    u_shift_reg_x16_1 (
        .clk(x16_clk)                                           ,
        .rst(i_reset)                                           ,
        .data_in(i_lane_1)                                      ,
        .data_out(reg_x16_out1)                                 ,
        .data_valid(reg_x16_valid_1)
    );

    ucie_shift_register #(
        .pWIDTH_OUT(shift_register_X16_WIDTH)
    ) 
    u_shift_reg_x16_2 (
        .clk(x16_clk)                                           ,
        .rst(i_reset)                                           ,
        .data_in(i_lane_2)                                      ,
        .data_out(reg_x16_out2)                                 ,
        .data_valid(reg_x16_valid_2)
    );

    ucie_shift_register #(
        .pWIDTH_OUT(shift_register_X16_WIDTH)
    ) 
    u_shift_reg_x16_3 (
        .clk(x16_clk)                                           ,
        .rst(i_reset)                                           ,
        .data_in(i_lane_3)                                      ,
        .data_out(reg_x16_out3)                                 ,
        .data_valid(reg_x16_valid_3)
    );

    ucie_shift_register #(
        .pWIDTH_OUT(shift_register_X16_WIDTH)
    ) 
    u_shift_reg_x16_4 (
        .clk(x16_clk)                                           ,
        .rst(i_reset)                                           ,
        .data_in(i_lane_4)                                      ,
        .data_out(reg_x16_out4)                                 ,
        .data_valid(reg_x16_valid_4)
    );

    ucie_shift_register #(
        .pWIDTH_OUT(shift_register_X16_WIDTH)
    ) 
    u_shift_reg_x16_5 (
        .clk(x16_clk)                                           ,
        .rst(i_reset)                                           ,
        .data_in(i_lane_5)                                      ,
        .data_out(reg_x16_out5)                                 ,
        .data_valid(reg_x16_valid_5)
    );

    ucie_shift_register #(
        .pWIDTH_OUT(shift_register_X16_WIDTH)
    ) 
    u_shift_reg_x16_6 (
        .clk(x16_clk)                                           ,
        .rst(i_reset)                                           ,
        .data_in(i_lane_6)                                      ,
        .data_out(reg_x16_out6)                                 ,
        .data_valid(reg_x16_valid_6)
    );

    ucie_shift_register #(
        .pWIDTH_OUT(shift_register_X16_WIDTH)
    ) 
    u_shift_reg_x16_7 (
        .clk(x16_clk)                                           ,
        .rst(i_reset)                                           ,
        .data_in(i_lane_7)                                      ,
        .data_out(reg_x16_out7)                                 ,
        .data_valid(reg_x16_valid_7)
    );

    ucie_shift_register #(
        .pWIDTH_OUT(shift_register_X16_WIDTH)
    ) 
    u_shift_reg_x16_8 (
        .clk(x16_clk)                                           ,
        .rst(i_reset)                                           ,
        .data_in(i_lane_8)                                      ,
        .data_out(reg_x16_out8)                                 ,
        .data_valid(reg_x16_valid_8)
    );

    ucie_shift_register #(
        .pWIDTH_OUT(shift_register_X16_WIDTH)
    ) 
    u_shift_reg_x16_9 (
        .clk(x16_clk)                                           ,
        .rst(i_reset)                                           ,
        .data_in(i_lane_9)                                      ,
        .data_out(reg_x16_out9)                                 ,
        .data_valid(reg_x16_valid_9)
    );

    ucie_shift_register #(
        .pWIDTH_OUT(shift_register_X16_WIDTH)
    ) 
    u_shift_reg_x16_10 (
        .clk(x16_clk)                                           ,
        .rst(i_reset)                                           ,
        .data_in(i_lane_10)                                     ,
        .data_out(reg_x16_out10)                                ,
        .data_valid(reg_x16_valid_10)
    );

    ucie_shift_register #(
        .pWIDTH_OUT(shift_register_X16_WIDTH)
    ) 
    u_shift_reg_x16_11 (
        .clk(x16_clk)                                           ,
        .rst(i_reset)                                           ,
        .data_in(i_lane_11)                                     ,
        .data_out(reg_x16_out11)                                ,
        .data_valid(reg_x16_valid_11)
    );

    ucie_shift_register #(
        .pWIDTH_OUT(shift_register_X16_WIDTH)
    ) 
    u_shift_reg_x16_12 (
        .clk(x16_clk)                                           ,
        .rst(i_reset)                                           ,
        .data_in(i_lane_12)                                     ,
        .data_out(reg_x16_out12)                                ,
        .data_valid(reg_x16_valid_12)
    );

    ucie_shift_register #(
        .pWIDTH_OUT(shift_register_X16_WIDTH)
    ) 
    u_shift_reg_x16_13 (
        .clk(x16_clk)                                           ,
        .rst(i_reset)                                           ,
        .data_in(i_lane_13)                                     ,
        .data_out(reg_x16_out13)                                ,
        .data_valid(reg_x16_valid_13)
    );

    ucie_shift_register #(
        .pWIDTH_OUT(shift_register_X16_WIDTH)
    ) 
    u_shift_reg_x16_14 (
        .clk(x16_clk)                                           ,
        .rst(i_reset)                                           , 
        .data_in(i_lane_14)                                     ,
        .data_out(reg_x16_out14)                                ,
        .data_valid(reg_x16_valid_14)
    );

    ucie_shift_register #(
        .pWIDTH_OUT(shift_register_X16_WIDTH)
    ) 
    u_shift_reg_x16_15 (
        .clk(x16_clk)                                           ,
        .rst(i_reset)                                           ,
        .data_in(i_lane_15)                                     ,
        .data_out(reg_x16_out15)                                ,
        .data_valid(reg_x16_valid_15)
    );

    // =========================================================================
    // Shift registers for x8 mode (8 lanes)
    // =========================================================================

    ucie_shift_register #(
        .pWIDTH_OUT(shift_register_X8_WIDTH)
    ) 
    u_shift_reg_x8_0 (
        .clk(x8_clk)                                            ,
        .rst(i_reset)                                           , 
        .data_in(reg_x8_in0)                                    ,
        .data_out(reg_x8_out0)                                  ,
        .data_valid(reg_x8_valid_0)
    );

    ucie_shift_register #(
        .pWIDTH_OUT(shift_register_X8_WIDTH)
    ) 
    u_shift_reg_x8_1 (
        .clk(x8_clk)                                            ,
        .rst(i_reset)                                           ,
        .data_in(reg_x8_in1)                                    ,
        .data_out(reg_x8_out1)                                  ,
        .data_valid(reg_x8_valid_1)
    );

    ucie_shift_register #(
        .pWIDTH_OUT(shift_register_X8_WIDTH)
    ) 
    u_shift_reg_x8_2 (
        .clk(x8_clk)                                            ,
        .rst(i_reset)                                           ,
        .data_in(reg_x8_in2)                                    ,
        .data_out(reg_x8_out2)                                  ,
        .data_valid(reg_x8_valid_2)
    );

    ucie_shift_register #(
        .pWIDTH_OUT(shift_register_X8_WIDTH)
    ) 
    u_shift_reg_x8_3 (
        .clk(x8_clk)                                            ,
        .rst(i_reset)                                           ,
        .data_in(reg_x8_in3)                                    ,
        .data_out(reg_x8_out3)                                  ,
        .data_valid(reg_x8_valid_3)
    );

    ucie_shift_register #(
        .pWIDTH_OUT(shift_register_X8_WIDTH)
    ) 
    u_shift_reg_x8_4 (
        .clk(x8_clk)                                            ,
        .rst(i_reset)                                           ,
        .data_in(reg_x8_in4)                                    ,
        .data_out(reg_x8_out4)                                  ,
        .data_valid(reg_x8_valid_4)
    );

    ucie_shift_register #(
        .pWIDTH_OUT(shift_register_X8_WIDTH)
    ) 
    u_shift_reg_x8_5 (
        .clk(x8_clk)                                            ,
        .rst(i_reset)                                           , 
        .data_in(reg_x8_in5)                                    ,
        .data_out(reg_x8_out5)                                  ,
        .data_valid(reg_x8_valid_5)
    );

    ucie_shift_register #(
        .pWIDTH_OUT(shift_register_X8_WIDTH)
    ) 
    u_shift_reg_x8_6 (
        .clk(x8_clk)                                            ,
        .rst(i_reset)                                           , 
        .data_in(reg_x8_in6)                                    ,
        .data_out(reg_x8_out6)                                  ,
        .data_valid(reg_x8_valid_6)
    );

    ucie_shift_register #(
        .pWIDTH_OUT(shift_register_X8_WIDTH)
    ) 
    u_shift_reg_x8_7 (
        .clk(x8_clk)                                            ,
        .rst(i_reset)                                           ,
        .data_in(reg_x8_in7)                                    ,
        .data_out(reg_x8_out7)                                  ,
        .data_valid(reg_x8_valid_7)
    );

    // =========================================================================
    // Shift registers for x4 mode (4 lanes)
    // =========================================================================
    ucie_shift_register #(
        .pWIDTH_OUT(shift_register_X4_WIDTH)
    ) 
    u_shift_reg_x4_0 (
        .clk(x4_clk)                                            ,
        .rst(i_reset)                                           ,
        .data_in(reg_x4_in0)                                    ,
        .data_out(reg_x4_out0)                                  ,
        .data_valid(reg_x4_valid_0)
    );

    ucie_shift_register #(
        .pWIDTH_OUT(shift_register_X4_WIDTH)
    ) 
    u_shift_reg_x4_1 (
        .clk(x4_clk)                                            ,
        .rst(i_reset)                                           ,
        .data_in(reg_x4_in1)                                    ,
        .data_out(reg_x4_out1)                                  ,
        .data_valid(reg_x4_valid_1)
    );

    ucie_shift_register #(
        .pWIDTH_OUT(shift_register_X4_WIDTH)
    ) 
    u_shift_reg_x4_2 (
        .clk(x4_clk)                                            ,
        .rst(i_reset)                                           ,
        .data_in(reg_x4_in2)                                    ,
        .data_out(reg_x4_out2)                                  ,
        .data_valid(reg_x4_valid_2)
    );

    ucie_shift_register #(
        .pWIDTH_OUT(shift_register_X4_WIDTH)
    ) 
    u_shift_reg_x4_3 (
        .clk(x4_clk)                                            ,
        .rst(i_reset)                                           ,
        .data_in(reg_x4_in3)                                    ,
        .data_out(reg_x4_out3)                                  ,
        .data_valid(reg_x4_valid_3)
    );

    // =========================================================================
    // Reordering block to reorder bytes from shift registers into proper sequence based on mode
    // =========================================================================
    ucie_reordering_block #(
        .pDATA_OUT_WIDTH(pDATA_OUT_WIDTH)
    ) 
    u_reorder_inst (
        .i_clk(i_clk)                                           ,
        .i_reset(i_reset)                                       ,
        .i_mode_x16(x16_en)                                     ,  // Mode selection based on lane map code
        .i_mode_x8(x8_en)                                       ,
        .i_mode_x4(x4_en)                                       ,
        .i_x16_lane_0(reg_x16_out0)                             ,
        .i_x16_lane_1(reg_x16_out1)                             ,
        .i_x16_lane_2(reg_x16_out2)                             ,
        .i_x16_lane_3(reg_x16_out3)                             ,
        .i_x16_lane_4(reg_x16_out4)                             ,
        .i_x16_lane_5(reg_x16_out5)                             ,
        .i_x16_lane_6(reg_x16_out6)                             ,
        .i_x16_lane_7(reg_x16_out7)                             ,
        .i_x16_lane_8(reg_x16_out8)                             ,
        .i_x16_lane_9(reg_x16_out9)                             ,
        .i_x16_lane_10(reg_x16_out10)                           ,
        .i_x16_lane_11(reg_x16_out11)                           ,
        .i_x16_lane_12(reg_x16_out12)                           ,
        .i_x16_lane_13(reg_x16_out13)                           ,
        .i_x16_lane_14(reg_x16_out14)                           ,
        .i_x16_lane_15(reg_x16_out15)                           ,
        .i_x8_lane_0(reg_x8_out0)                               ,
        .i_x8_lane_1(reg_x8_out1)                               ,
        .i_x8_lane_2(reg_x8_out2)                               ,
        .i_x8_lane_3(reg_x8_out3)                               ,
        .i_x8_lane_4(reg_x8_out4)                               ,
        .i_x8_lane_5(reg_x8_out5)                               ,
        .i_x8_lane_6(reg_x8_out6)                               ,
        .i_x8_lane_7(reg_x8_out7)                               ,
        .i_x4_lane_0(reg_x4_out0)                               ,
        .i_x4_lane_1(reg_x4_out1)                               ,
        .i_x4_lane_2(reg_x4_out2)                               ,
        .i_x4_lane_3(reg_x4_out3)                               ,
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
    assign mux_8            =       decoding[4]                 ;                                        // Enable for 8-lane mux
    assign mux_4            =       decoding[3]                 ;                                        // Enable for 4-lane mux
    assign x16_en           =       decoding[2]                 ;                                        // Enable for 16-lane mode
    assign x8_en            =       decoding[1]                 ;                                        // Enable for 8-lane mode
    assign x4_en            =       decoding[0]                 ;
    assign data_valid       = (reg_x16_valid_0 && reg_x16_valid_1 && reg_x16_valid_2 && reg_x16_valid_3 && reg_x16_valid_4
                                && reg_x16_valid_5 && reg_x16_valid_6 && reg_x16_valid_7 && reg_x16_valid_8 && reg_x16_valid_9
                                && reg_x16_valid_10 && reg_x16_valid_11 && reg_x16_valid_12 && reg_x16_valid_13 && reg_x16_valid_14
                                && reg_x16_valid_15)
                                ||(reg_x8_valid_0 && reg_x8_valid_1 && reg_x8_valid_2 && reg_x8_valid_3 
                                && reg_x8_valid_4 && reg_x8_valid_5 && reg_x8_valid_6 && reg_x8_valid_7) 
                                ||(reg_x4_valid_0 && reg_x4_valid_1 && reg_x4_valid_2 && reg_x4_valid_3)  ;                                    
   
   
    // =========================================================================
    // Output assignment: Register the output data and valid signal
    // Pipeline: data fills shift regs -> reordering (combinatorial) -> register output
    // =========================================================================

    always @(posedge p_clk or posedge i_reset) begin
        if (i_reset) begin
            o_data_out     <=  {pDATA_OUT_WIDTH{1'b0}}          ;
            o_data_valid   <=  1'b0                             ;                       ;
        end 
        else if (i_enable) begin
            o_data_out     <=  data_out                         ;
            o_data_valid   <=  data_valid                       ;  // Use registered ready signal
            
        end
        
    end

endmodule
