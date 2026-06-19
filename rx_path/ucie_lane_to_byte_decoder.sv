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


module ucie_lane_to_byte_decoder (
    input   logic   [2:0]        i_lane_map_code                ,
    output  logic   [4:0]        o_decoding
);

    // =========================================================================
    //typedef for lane map codes
    // =========================================================================
    typedef enum logic [2:0] {
        LANE_MAP_NONE        = 3'b000                           , // Degrade not possible
        LANE_MAP_0_TO_7      = 3'b001                           ,
        LANE_MAP_8_TO_15     = 3'b010                           ,
        LANE_MAP_0_TO_15     = 3'b011                           ,
        LANE_MAP_0_TO_3      = 3'b100                           ,
        LANE_MAP_4_TO_7      = 3'b101
    } lane_map_e;
    
    lane_map_e lane_map;
    assign lane_map = lane_map_e'(i_lane_map_code);

    // =========================================================================
    // Generate decoding signals based on lane map code
    // =========================================================================
    always_comb begin
        case (lane_map)
            LANE_MAP_NONE       : o_decoding    = 5'b00000    ; // No lane active
            LANE_MAP_0_TO_7     : o_decoding    = 5'b00010    ; // Lanes 0-7 active
            LANE_MAP_8_TO_15    : o_decoding    = 5'b10010    ; // Lanes 8-15 active (not used in this context)
            LANE_MAP_0_TO_15    : o_decoding    = 5'b00100    ; // Lanes 0-15 active
            LANE_MAP_0_TO_3     : o_decoding    = 5'b00001    ; // Lanes 0-3 active
            LANE_MAP_4_TO_7     : o_decoding    = 5'b01001    ; // Lanes 4-7 active
            
            default: o_decoding = 5'b00100                    ; // No lane active
        endcase
    end
    
endmodule
