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

//---------------------------------------------------------------------------
//
// CLASS: sb_cmp_link2ltsm_rx
//
// Description: ...
//---------------------------------------------------------------------------

class sb_cmp_link2ltsm_rx extends sb_cmp_base #(ltsm_seq_item, "RX_LINK2LTSM_CMP");
  `uvm_component_utils(sb_cmp_link2ltsm_rx)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass
