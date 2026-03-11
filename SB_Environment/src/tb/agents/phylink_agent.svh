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

class phylink_agent extends agent_base #(
  .CFG_NAME("phylink_cfg"),
  .INTF_T(virtual sb_phylink_bfm),
  .ITEM_T(phylink_seq_item),
  .SEQR_T(phylink_sequencer),
  .DRVR_T(phylink_driver),
  .MNTR_T(phylink_monitor)
);
  `uvm_component_utils(phylink_agent)

  extern function new(string name, uvm_component parent);

endclass

function phylink_agent::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new