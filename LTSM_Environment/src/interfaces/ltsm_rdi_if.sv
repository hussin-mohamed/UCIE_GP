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


interface ltsm_rdi_if(
   //--------------------- Clock & Reset ---------------------
	input logic					clk
);
	
	//------------- Physical Layer to the Die-to-Die Adapter. ---------------
	logic [3:0]						o_pl_state_sts;
	logic							o_pl_inband_pres;
	logic							o_pl_phyinrecenter;
	logic							o_pl_stallreq;
	logic							o_pl_clk_req;
	logic							o_pl_wake_ack;
	logic							o_pl_lnk_cfg;
	logic [2:0]							o_pl_speedmode;
	logic							o_pl_max_speedmode;
	logic							o_pl_error;
	logic							o_pl_trainerror;
	logic							o_pl_cerror;
	logic							o_pl_nferror;

	//------------- Die-to-Die Adapter to Physical Layer ---------------
	logic [3:0]						i_lp_state_req;
	logic							i_lp_stallack;
	logic							i_lp_clk_ack;
	logic							i_lp_wake_req;
	logic							i_lp_linkerror;
	logic 							i_reset;

	string if_name = "ltsm_rdi_if";

	
endinterface : ltsm_rdi_if