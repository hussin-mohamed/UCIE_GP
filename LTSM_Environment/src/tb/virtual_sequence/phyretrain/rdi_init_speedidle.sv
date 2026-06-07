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


class phyretrain_rdi_init_speedidle extends virtual_sequence_base;
    `uvm_object_utils(phyretrain_rdi_init_speedidle)
    phyretrain_RDI_init tx_rdi_init_seq;
    phyretrain_stallack tx_stall_seq;
    phyretrain_tx_retr_hs tx_retrain_hs_seq ;
    phyretrain_reg_speedidle tx_sent_speedidle_seq ;
    phyretrain_tx_reqhs tx_req_hs_seq;
    // rx sequences
    phyretrain_rx_retr_hs rx_retrain_hs_seq ;
    phyretrain_stallack rx_stall_seq;
    phyretrain_reg_speedidle rx_sent_speedidle_seq ;
    phyretrain_rx_rsphs rx_rsp_hs_seq ;

    // Function: new
    //
    // Creates a new virtual_sequence instance with the given name.

    extern function new(string name = "phyretrain_rdi_init_speedidle");


    // Task: pre_body
    //
    // Creates instances of child reactive sequences before body execution.

    extern task pre_body();


    // Task: body
    //
    // Retrieves sequencer handles via base class, then starts both reactive
    // sequences on their respective sequencers sequentially.

    extern task body();

endclass : phyretrain_rdi_init_speedidle


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- virtual_sequence
//
//------------------------------------------------------------------------------


// new
// ---

function phyretrain_rdi_init_speedidle::new(string name = "phyretrain_rdi_init_speedidle");
    super.new(name);
endfunction : new

// pre_body
// --------

task phyretrain_rdi_init_speedidle::pre_body();
    // tx sequences
    tx_rdi_init_seq = phyretrain_RDI_init::type_id::create("tx_rdi_init_seq");
    tx_stall_seq = phyretrain_stallack::type_id::create("tx_stall_seq");
    tx_retrain_hs_seq = phyretrain_tx_retr_hs::type_id::create("tx_retrain_hs_seq");
    tx_sent_speedidle_seq = phyretrain_reg_speedidle::type_id::create("tx_sent_speedidle_seq");
    tx_req_hs_seq = phyretrain_tx_reqhs::type_id::create("tx_req_hs_seq");
    // rx sequences
    rx_retrain_hs_seq = phyretrain_rx_retr_hs::type_id::create("rx_retrain_hs_seq");
    rx_stall_seq = phyretrain_stallack::type_id::create("rx_stall_seq");
    rx_sent_speedidle_seq = phyretrain_reg_speedidle::type_id::create("rx_sent_speedidle_seq");
    rx_rsp_hs_seq = phyretrain_rx_rsphs::type_id::create("rx_rsp_hs_seq");
endtask

// body
// ----
// local die initiates the handshake by sending the L1 state request, then remote die responds with the L1 state response, then both sides enter L1
task phyretrain_rdi_init_speedidle::body();
    super.body();
    tx_rdi_init_seq.start(ltsm_rdi_seqr);
    tx_stall_seq.start(ltsm_rdi_seqr);
       fork
            begin
            tx_retrain_hs_seq.start(tx_fsm_sb_seqr);
            tx_sent_speedidle_seq.start(LTSM_ctrl_seqr);
            tx_req_hs_seq.start(tx_fsm_sb_seqr);
            end
            begin
            rx_retrain_hs_seq.start(rx_fsm_sb_seqr);
            rx_stall_seq.start(ltsm_rdi_seqr);
            rx_sent_speedidle_seq.start(LTSM_ctrl_seqr);
            rx_rsp_hs_seq.start(rx_fsm_sb_seqr);
            end
       join
       

endtask : body

