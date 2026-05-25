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


module ucie_mux_2_to_1 (
    input   logic [63:0]      i_lane_x      ,
    input   logic [63:0]      i_lane_y      ,
    input   logic             i_sel         ,
    output  logic [63:0]      o_lane
);

    // =========================================================================
    // 2-to-1 MUX logic
    // =========================================================================
    always_comb begin
        case (i_sel)
            1'b0:   o_lane  =   i_lane_x    ;                   // Select lane_x when i_sel is 0
            1'b1:   o_lane  =   i_lane_y    ;                   // Select lane_y when i_sel is 1
            default: o_lane =   64'b0       ;                   // Default case (should not occur)
        endcase
    end
    
endmodule
