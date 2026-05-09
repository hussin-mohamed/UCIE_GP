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

// CLASS: ltsm_sbinit_v_sequence
//
// This virtual sequence starts the SBINIT out of reset message TX first,
// then starts the SBINIT done handshakes for TX and RX in parallel.
//
//------------------------------------------------------------------------------

import shared_ltsm_pkg::*;

class ltsm_sbinit_v_sequence extends virtual_sequence_base;

  `uvm_object_utils(ltsm_sbinit_v_sequence)

  function new(string name = "ltsm_sbinit_v_sequence");
    super.new(name);
  endfunction

  virtual task body();
    ltsm_sbinit_out_of_reset_msg_tx out_reset_tx;
    ltsm_sbinit_done_handshake_tx done_tx;
    ltsm_sbinit_done_handshake_rx done_rx;
    ltsm_sbinit_sb_ready sb_ready;

    super.body();
    fork
      begin
        out_reset_tx = ltsm_sbinit_out_of_reset_msg_tx::type_id::create("out_reset_tx");
        out_reset_tx.start(tx_fsm_sb_seqr);
        fork
          begin
            sb_ready = ltsm_sbinit_sb_ready::type_id::create("sb_ready");
          sb_ready.start(LTSM_ctrl_seqr);
          end
          begin
            done_tx = ltsm_sbinit_done_handshake_tx::type_id::create("done_tx");
            done_tx.start(tx_fsm_sb_seqr);
          end
        join
        
        
        
      end

      begin
        done_rx = ltsm_sbinit_done_handshake_rx::type_id::create("done_rx");
        done_rx.start(rx_fsm_sb_seqr);
      end
    join
  endtask

endclass