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

typedef class agent_config;

// Agent configuration objects typedefs
typedef agent_config #(.INTF_T(virtual rp_rdi_bfm))     rdi_cfg_t;
typedef agent_config #(.INTF_T(virtual rp_ltsmc_bfm))  ltsmc_cfg_t;
typedef agent_config #(.INTF_T(virtual rp_rmblink_bfm)) rmblink_cfg_t;
