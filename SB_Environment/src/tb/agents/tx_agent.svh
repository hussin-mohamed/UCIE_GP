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

class tx_agent extends agent_base #(
  .CFG_NAME("tx_cfg"),
  .INTF_T(virtual sb_tx_bfm),
  .ITEM_T(ltsm_seq_item),
  .SEQR_T(tx_sequencer),
  .DRVR_T(tx_driver),
  .MNTR_T(tx_monitor)
);
  `uvm_component_utils(tx_agent)

  extern function new(string name, uvm_component parent);

endclass

function tx_agent::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new