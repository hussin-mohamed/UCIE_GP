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

// CLASS: ltsm_reset_v_sequence
//
// This virtual sequence mimics the reset state sequence by starting the enter reset sequence first,
// then starting the reset exit TX and RX sequences in parallel.
//
//------------------------------------------------------------------------------

import shared_ltsm_pkg::*;

class ltsm_reset_v_sequence extends virtual_sequence_base;

  `uvm_object_utils(ltsm_reset_v_sequence)

  function new(string name = "ltsm_reset_v_sequence");
    super.new(name);
  endfunction

  virtual task body();
    ltsm_enter_reset enter_seq;
    ltsm_exit_reset_state_tx_sequence tx_exit;
    ltsm_exit_reset_state_rx_sequence rx_exit;
    nothing_rx nothing;

    super.body();
    enter_seq = ltsm_enter_reset::type_id::create("enter_seq");
    enter_seq.start(LTSM_ctrl_seqr);
    repeat((timeout/2)-6)begin
       fork
        begin
            tx_exit = ltsm_exit_reset_state_tx_sequence::type_id::create("tx_exit");
            tx_exit.start(LTSM_ctrl_seqr);
        end
      
        begin
            rx_exit = ltsm_exit_reset_state_rx_sequence::type_id::create("rx_exit");
            rx_exit.start(LTSM_ctrl_seqr);
        end
    join
    end
   
  endtask

endclass