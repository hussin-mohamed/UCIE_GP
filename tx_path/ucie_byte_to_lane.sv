
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


module ucie_byte_to_lane #(
    parameter pDATA_IN_WIDTH   = 2048                           ,   // Input width (default 2048 bits for 16 lanes × 128 bits each)
    parameter pDATA_OUT_WIDTH    = 64                               // Output width (default 64 bits per lane)   
)(
    //input data from RX LFSR and control signals
    input logic                            i_clk                ,
    input logic                           i_reset               ,
    input logic                           i_enable              ,
    input logic                           i_lp_irdy           ,
    input logic                           i_lp_valid           ,
    input logic [2:0]                     i_lane_map_code       ,
    input logic [pDATA_IN_WIDTH-1:0]      i_lp_data             ,
    //output data to shift registers
    output logic                              o_pl_trdy       ,
    output logic [pDATA_OUT_WIDTH-1:0]        o_lane_0          ,
    output logic [pDATA_OUT_WIDTH-1:0]        o_lane_1          ,
    output logic [pDATA_OUT_WIDTH-1:0]        o_lane_2          ,
    output logic [pDATA_OUT_WIDTH-1:0]        o_lane_3          ,
    output logic [pDATA_OUT_WIDTH-1:0]        o_lane_4          ,
    output logic [pDATA_OUT_WIDTH-1:0]        o_lane_5          ,
    output logic [pDATA_OUT_WIDTH-1:0]        o_lane_6          ,
    output logic [pDATA_OUT_WIDTH-1:0]        o_lane_7          ,
    output logic [pDATA_OUT_WIDTH-1:0]        o_lane_8          ,
    output logic [pDATA_OUT_WIDTH-1:0]        o_lane_9          ,
    output logic [pDATA_OUT_WIDTH-1:0]        o_lane_10         ,
    output logic [pDATA_OUT_WIDTH-1:0]        o_lane_11         ,
    output logic [pDATA_OUT_WIDTH-1:0]        o_lane_12         ,
    output logic [pDATA_OUT_WIDTH-1:0]        o_lane_13         ,
    output logic [pDATA_OUT_WIDTH-1:0]        o_lane_14         ,
    output logic [pDATA_OUT_WIDTH-1:0]        o_lane_15         
              

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
    logic                               x8_mode                 ;
    logic                               x4_mode                 ;
    logic                               x16_en                  ;
    logic                               x8_en                   ;
    logic                               x4_en                   ;

    // Internal lane array (collect individual inputs)
    logic  [pDATA_IN_WIDTH-1:0]           data_in               ;
    logic                               data_ready              ;
    
    // Mux output arrays for feeding into shift registers
    logic  [shift_register_X16_WIDTH-1:0] reg_x16_in [15:0]     ;
    logic  [shift_register_X8_WIDTH-1:0]  reg_x8_in [7:0]       ;
    logic  [shift_register_X4_WIDTH-1:0]  reg_x4_in [3:0]       ;
    
    // Shift register output arrays        
    logic  [pDATA_OUT_WIDTH-1:0]          reg_x16_out [15:0]    ;
    logic   [15:0]                              reg_x16_valid   ;
    logic  [pDATA_OUT_WIDTH-1:0]          reg_x8_out [7:0]      ;
    logic   [7:0]                              reg_x8_valid     ;
    logic  [pDATA_OUT_WIDTH-1:0]          reg_x4_out [3:0]      ;
    logic     [3:0]                             reg_x4_valid    ;

    logic [pDATA_OUT_WIDTH-1:0]          lane_out  [15:0]       ;
   

    // =========================================================================
    // decoder to decode lane map code and generate control signals
    // =========================================================================
    ucie_byte_to_lane_decoder u_decoder_inst (
        .i_lane_map_code(i_lane_map_code),
        .o_decoding(decoding)
    );


    // =========================================================================
    // X16 Mode Distribution (all 16 lanes active, stride 16)
    // Lane i gets bytes: {Bi, Bi+16, Bi+32, Bi+48, Bi+64, Bi+80, Bi+96, Bi+112, ...}
    // =========================================================================
    generate
        for (genvar lane = 0; lane < 16; lane++) begin : gen_x16_distribution
            for (genvar byte_idx = 0; byte_idx < 16; byte_idx++) begin : gen_x16_bytes
                assign reg_x16_in[lane][(byte_idx*8 + 7) -: 8] = extract_byte(data_in, lane + byte_idx * 16);
            end
        end
    endgenerate


    // =========================================================================
    // X8 Mode Distribution - both Upper and Lower (stride 8)
    // Lane i gets bytes: {Bi, Bi+8, Bi+16, Bi+24, Bi+32, ...}
    // =========================================================================
    generate
        for (genvar lane = 0; lane < 8; lane++) begin : gen_x8_distribution
            for (genvar byte_idx = 0; byte_idx < 32; byte_idx++) begin : gen_x8_bytes
                assign reg_x8_in[lane][(byte_idx*8 + 7) -: 8] = extract_byte(data_in, lane + byte_idx * 8);
            end
        end
    endgenerate

    // =========================================================================
    // X4 Mode Distribution - Lower Lanes (stride 4)
    // Lane i gets bytes: {Bi, Bi+4, Bi+8, Bi+12, Bi+16, ...}
    // =========================================================================
    generate
        for (genvar lane = 0; lane < 4; lane++) begin : gen_x4_distribution
            for (genvar byte_idx = 0; byte_idx < 64; byte_idx++) begin : gen_x4_bytes
                assign reg_x4_in[lane][(byte_idx*8 + 7) -: 8] = extract_byte(data_in, lane + byte_idx * 4);
            end
        end
    endgenerate


    // =========================================================================
    // Shift registers x16 - Generate block for 16 shift registers
    // =========================================================================
    generate
        for (genvar i = 0; i < 16; i++) begin : gen_shift_reg_x16
            ucie_shift_register #(
                .INPUT_WIDTH(shift_register_X16_WIDTH)
            ) 
            u_shift_reg_x16 (
                .clk(x16_clk)                                       ,
                .rst(i_reset)                                       ,
                .data_in(reg_x16_in[i])                             ,
                .data_in_valid(data_ready)                        ,
                .data_out(reg_x16_out[i])                           ,
                .b2l_ready(reg_x16_valid[i])
            );
        end
    endgenerate

    // =========================================================================
    // Shift registers x8 - Generate block for 8 shift registers
    // =========================================================================
    generate
        for (genvar i = 0; i < 8; i++) begin : gen_shift_reg_x8
            ucie_shift_register #(
                .INPUT_WIDTH(shift_register_X8_WIDTH)
            ) 
            u_shift_reg_x8 (
                .clk(x8_clk)                                        ,
                .rst(i_reset)                                       ,
                .data_in(reg_x8_in[i])                              ,
                .data_in_valid(data_ready)                        ,
                .data_out(reg_x8_out[i])                            ,
                .b2l_ready(reg_x8_valid[i])
            );
        end
    endgenerate

    // =========================================================================
    // Shift registers x4 - Generate block for 4 shift registers
    // =========================================================================
    generate
        for (genvar i = 0; i < 4; i++) begin : gen_shift_reg_x4
            ucie_shift_register #(
                .INPUT_WIDTH(shift_register_X4_WIDTH)
            ) 
            u_shift_reg_x4 (
                .clk(x4_clk)                                        ,
                .rst(i_reset)                                       ,
                .data_in(reg_x4_in[i])                              ,
                .data_in_valid(data_ready)                        ,
                .data_out(reg_x4_out[i])                            ,
                .b2l_ready(reg_x4_valid[i])
            );
        end
    endgenerate

    // =========================================================================
    // Output Multiplexing (select data from active shift registers)
    // =========================================================================
    generate
        for (genvar i = 0; i < 16; i++) begin : gen_output_multiplexing
            ucie_mux_4_to_1 u_mux_inst (
                .i_lane_x(reg_x16_out[i]),  // X16 mode output
                .i_lane_y(reg_x8_out[i % 8]), // X8 mode output (wrap around for 16 lanes)
                .i_lane_z(reg_x4_out[i % 4]), // X4 mode output (wrap around for 16 lanes)
                .i_sel({x8_mode,x4_mode}), // Select based on mode (X16 > X8 > X4)
                .o_lane(lane_out[i])         // Output to lane array
            );
            
        end
    endgenerate


    
    // =========================================================================
    //clock gating logic
    // =========================================================================
    always_comb begin  
        if(!i_clk)begin
            enable     =    i_enable && i_lp_irdy               ;
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
    
    assign x8_mode            =       decoding[4]               ;
    assign x4_mode            =       decoding[3]               ;
    assign x16_en             =       decoding[2]               ;
    assign x8_en              =       decoding[1]               ;
    assign x4_en              =       decoding[0]               ;
    
    // =========================================================================
    // Byte extraction helper function (extract 8-bit byte from input)
    // =========================================================================
    function logic [7:0] extract_byte(logic [pDATA_IN_WIDTH-1:0] data, int byte_idx);
        extract_byte = data[byte_idx*8 +: 8];
    endfunction



    // Input data
    assign data_in = i_lp_data;
    assign data_ready = i_lp_irdy && i_lp_valid && o_pl_trdy; // Data is ready when both ready and valid are asserted



    

    // =========================================================================
    // Assign outputs to individual lane outputs
    // =========================================================================
    assign o_lane_0 = lane_out[0];
    assign o_lane_1 = lane_out[1];
    assign o_lane_2 = lane_out[2];
    assign o_lane_3 = lane_out[3];
    assign o_lane_4 = lane_out[4];
    assign o_lane_5 = lane_out[5];
    assign o_lane_6 = lane_out[6];
    assign o_lane_7 = lane_out[7];
    assign o_lane_8 = lane_out[8];
    assign o_lane_9 = lane_out[9];
    assign o_lane_10 = lane_out[10];
    assign o_lane_11 = lane_out[11];
    assign o_lane_12 = lane_out[12];
    assign o_lane_13 = lane_out[13];
    assign o_lane_14 = lane_out[14];
    assign o_lane_15 = lane_out[15];
    assign o_pl_trdy = (x16_en) ? &reg_x16_valid : (x8_en) ? &reg_x8_valid : (x4_en) ? &reg_x4_valid : 1'b0;    

endmodule
