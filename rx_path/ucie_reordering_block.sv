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


module ucie_reordering_block #(
    parameter pDATA_OUT_WIDTH   = 2048
)(
    input  logic                            i_clk               ,
    input  logic                            i_reset             ,
    input  logic                            i_mode_x16          ,  // 0=x16, 1=x8, 2=x4
    input  logic                            i_mode_x8           ,
    input  logic                            i_mode_x4           ,          
    // x16 mode inputs (16 lanes × pDATA_OUT_WIDTH/16 bits each)
    input  logic [pDATA_OUT_WIDTH/16-1:0]   i_x16_lane_0        ,
    input  logic [pDATA_OUT_WIDTH/16-1:0]   i_x16_lane_1        ,
    input  logic [pDATA_OUT_WIDTH/16-1:0]   i_x16_lane_2        ,
    input  logic [pDATA_OUT_WIDTH/16-1:0]   i_x16_lane_3        ,
    input  logic [pDATA_OUT_WIDTH/16-1:0]   i_x16_lane_4        ,
    input  logic [pDATA_OUT_WIDTH/16-1:0]   i_x16_lane_5        ,
    input  logic [pDATA_OUT_WIDTH/16-1:0]   i_x16_lane_6        ,
    input  logic [pDATA_OUT_WIDTH/16-1:0]   i_x16_lane_7        ,
    input  logic [pDATA_OUT_WIDTH/16-1:0]   i_x16_lane_8        ,
    input  logic [pDATA_OUT_WIDTH/16-1:0]   i_x16_lane_9        ,
    input  logic [pDATA_OUT_WIDTH/16-1:0]   i_x16_lane_10       ,
    input  logic [pDATA_OUT_WIDTH/16-1:0]   i_x16_lane_11       ,
    input  logic [pDATA_OUT_WIDTH/16-1:0]   i_x16_lane_12       ,
    input  logic [pDATA_OUT_WIDTH/16-1:0]   i_x16_lane_13       ,
    input  logic [pDATA_OUT_WIDTH/16-1:0]   i_x16_lane_14       ,
    input  logic [pDATA_OUT_WIDTH/16-1:0]   i_x16_lane_15       ,
    
    // x8 mode inputs (8 lanes × pDATA_OUT_WIDTH/8 bits each)
    input  logic [pDATA_OUT_WIDTH/8-1:0]    i_x8_lane_0         ,
    input  logic [pDATA_OUT_WIDTH/8-1:0]    i_x8_lane_1         ,
    input  logic [pDATA_OUT_WIDTH/8-1:0]    i_x8_lane_2         ,
    input  logic [pDATA_OUT_WIDTH/8-1:0]    i_x8_lane_3         ,
    input  logic [pDATA_OUT_WIDTH/8-1:0]    i_x8_lane_4         ,
    input  logic [pDATA_OUT_WIDTH/8-1:0]    i_x8_lane_5         ,
    input  logic [pDATA_OUT_WIDTH/8-1:0]    i_x8_lane_6         ,
    input  logic [pDATA_OUT_WIDTH/8-1:0]    i_x8_lane_7         ,
    
    // x4 mode inputs (4 lanes × pDATA_OUT_WIDTH/4 bits each)
    input  logic [pDATA_OUT_WIDTH/4-1:0]    i_x4_lane_0         ,
    input  logic [pDATA_OUT_WIDTH/4-1:0]    i_x4_lane_1         ,
    input  logic [pDATA_OUT_WIDTH/4-1:0]    i_x4_lane_2         ,
    input  logic [pDATA_OUT_WIDTH/4-1:0]    i_x4_lane_3         ,
    
    // Output
    output logic [pDATA_OUT_WIDTH-1:0]      o_data_reordered    
);

    // =========================================================================
    // Local parameters calculated from data output width
    // =========================================================================
    localparam TOTAL_BYTES = pDATA_OUT_WIDTH / 8                ;  // Total number of bytes

    // =========================================================================
    // Internal signals for byte reordering
    // =========================================================================
    logic [7:0]  x16_bytes [TOTAL_BYTES-1:0]                    ;  // Bytes for x16 mode (16 lanes × TOTAL_BYTES/16 bytes each)
    logic [7:0]  x8_bytes  [TOTAL_BYTES-1:0]                    ;  // Bytes for x8 mode (8 lanes × TOTAL_BYTES/8 bytes each)
    logic [7:0]  x4_bytes  [TOTAL_BYTES-1:0]                    ;  // Bytes for x4 mode (4 lanes × TOTAL_BYTES/4 bytes each)
    logic [7:0]  reordered_bytes [TOTAL_BYTES-1:0]              ;  // Reordered output bytes
    
    
    
    
    always_comb begin
    // =========================================================================
    // x16 Mode: Extract and reorder bytes from 16 lanes
    // First 16 bytes received are LSB, stored at MSB of lane
    // Extract from high bits downward: (TOTAL_BYTES/16-1-i)*8
    // =========================================================================
    x16_bytes = '{default: '0};
    x8_bytes  = '{default: '0};
    x4_bytes  = '{default: '0};
        if(i_mode_x16)begin
        for (int i = 0; i < TOTAL_BYTES/16; i++) begin
            x16_bytes[i*16 + 0]  = i_x16_lane_0[(i*8)+:8]       ;
            x16_bytes[i*16 + 1]  = i_x16_lane_1[(i*8)+:8]       ;
            x16_bytes[i*16 + 2]  = i_x16_lane_2[(i*8)+:8]       ;
            x16_bytes[i*16 + 3]  = i_x16_lane_3[(i*8)+:8]       ;
            x16_bytes[i*16 + 4]  = i_x16_lane_4[(i*8)+:8]       ;
            x16_bytes[i*16 + 5]  = i_x16_lane_5[(i*8)+:8]       ;
            x16_bytes[i*16 + 6]  = i_x16_lane_6[(i*8)+:8]       ;
            x16_bytes[i*16 + 7]  = i_x16_lane_7[(i*8)+:8]       ;
            x16_bytes[i*16 + 8]  = i_x16_lane_8[(i*8)+:8]       ;
            x16_bytes[i*16 + 9]  = i_x16_lane_9[(i*8)+:8]       ;
            x16_bytes[i*16 + 10] = i_x16_lane_10[(i*8)+:8]      ;
            x16_bytes[i*16 + 11] = i_x16_lane_11[(i*8)+:8]      ;
            x16_bytes[i*16 + 12] = i_x16_lane_12[(i*8)+:8]      ;
            x16_bytes[i*16 + 13] = i_x16_lane_13[(i*8)+:8]      ;
            x16_bytes[i*16 + 14] = i_x16_lane_14[(i*8)+:8]      ;
            x16_bytes[i*16 + 15] = i_x16_lane_15[(i*8)+:8]      ;
        end
        end

    // =========================================================================
    // x8 Mode: Extract and reorder bytes from 8 lanes
    // First bytes received are LSB, stored at MSB of lane
    // Extract from high bits downward: (TOTAL_BYTES/8-1-i)*8
    // =========================================================================
        else if(i_mode_x8)begin
            for (int i = 0; i < TOTAL_BYTES/8; i++) begin
            x8_bytes[i*8 + 0] = i_x8_lane_0[(i*8)+:8]           ;
            x8_bytes[i*8 + 1] = i_x8_lane_1[(i*8)+:8]           ;
            x8_bytes[i*8 + 2] = i_x8_lane_2[(i*8)+:8]           ;
            x8_bytes[i*8 + 3] = i_x8_lane_3[(i*8)+:8]           ;
            x8_bytes[i*8 + 4] = i_x8_lane_4[(i*8)+:8]           ;
            x8_bytes[i*8 + 5] = i_x8_lane_5[(i*8)+:8]           ;
            x8_bytes[i*8 + 6] = i_x8_lane_6[(i*8)+:8]           ;
            x8_bytes[i*8 + 7] = i_x8_lane_7[(i*8)+:8]           ;
       
        end
        end
    // =========================================================================
    // x4 Mode: Extract and reorder bytes from 4 lanes
    // First bytes received are LSB, stored at MSB of lane
    // Extract from high bits downward: (TOTAL_BYTES/4-1-i)*8
    // =========================================================================
        else if(i_mode_x4)begin
            for (int i = 0; i < TOTAL_BYTES/4; i++) begin
            x4_bytes[i*4 + 0] = i_x4_lane_0[(i*8)+:8]           ;
            x4_bytes[i*4 + 1] = i_x4_lane_1[(i*8)+:8]           ;
            x4_bytes[i*4 + 2] = i_x4_lane_2[(i*8)+:8]           ;
            x4_bytes[i*4 + 3] = i_x4_lane_3[(i*8)+:8]           ;
        end
        end
    end

    // =========================================================================
    // Mode selector: Choose which reordered bytes to output
    // =========================================================================
    always_comb begin
     
        if(i_mode_x16)begin
            reordered_bytes = x16_bytes                         ;   // x16 mode
        end    
        else if(i_mode_x8)begin
            reordered_bytes = x8_bytes                          ;   // x8 mode
        end
        else if(i_mode_x4)begin    
            reordered_bytes = x4_bytes                          ;   // x4 mode
        end
        else begin
            reordered_bytes = '{default:8'b0}                   ;   // Default case (should not occur)
        end

        
    end

    // =========================================================================
    // Concatenate reordered bytes to output
    // =========================================================================
    always_comb begin
        for (int i = 0; i < TOTAL_BYTES; i++) begin
            o_data_reordered[(i*8)+:8] = reordered_bytes[i]; 
        end
        
    end


endmodule

