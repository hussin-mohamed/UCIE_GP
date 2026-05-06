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


module ucie_mux_4_to_1 (
    input   logic [63:0]      i_lane_x      ,
    input   logic [63:0]      i_lane_y      ,
    input   logic [63:0]      i_lane_z      ,
    input   logic [1:0]       i_sel         ,
    output  logic [63:0]      o_lane
);

    // =========================================================================
    // 2-to-1 MUX logic
    // =========================================================================
    always_comb begin
        case (i_sel)
            2'b00:   o_lane  =   i_lane_x    ;                   // Select lane_x when i_sel is 0
            2'b01:   o_lane  =   i_lane_y    ;                   // Select lane_y when i_sel is 1
            2'b10:   o_lane  =   i_lane_z    ;                   // Select lane_z when i_sel is 2
            2'b11:   o_lane  =   {64{1'bz}}  ;                   // High impedance when i_sel is 3 (not used in this context)
            default: o_lane =   {64{1'bz}}   ;                   // Default case (should not occur)
        endcase
    end
    
endmodule
