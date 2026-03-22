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


module LTSM_top;
    import uvm_pkg::*;
    import LTSM_pkg::*;
    `include "uvm_macros.svh"
    // Clock Generation
    bit clk ;
    initial begin
        forever begin
            #10;
            clk=!clk;
        end
    end
   // instantite dut & interfaces

   ltsm_rdi_if ltsm_rdi_if_inst(.clk(clk), .rst_n(rst_n));
   TX_FSM_SB tx_fsm_sb_if(clk);
   RX_FSM_SB rx_fsm_sb_if(clk);
   LTSM_controllers_if vif(clk);
   regfile_interface regfile(clk);

   assert (regfile.o_speedreg=ltsm_rdi_if_inst.o_pl_speedmode) ;

   assign vif.o_rx_encoding = rx_fsm_sb_if.o_rx_encoding;
   assign vif.o_tx_encoding = tx_fsm_sb_if.o_tx_encoding;
   ucie_LTSM DUT (.clk(clk),
             .i_tx_decoding         (tx_fsm_sb_if.i_tx_decoding),
             .o_tx_encoding         (tx_fsm_sb_if.o_tx_encoding),
             .i_tx_data             (tx_fsm_sb_if.i_tx_data),
             .o_tx_data             (tx_fsm_sb_if.o_tx_data),
             .i_sb_tx_req           (tx_fsm_sb_if.i_sb_tx_req),
             .i_sb_tx_rsp           (tx_fsm_sb_if.i_sb_tx_rsp),
             .i_sb_tx_done          (tx_fsm_sb_if.i_sb_tx_done),
             .o_tx_sb_req           (tx_fsm_sb_if.o_tx_sb_req),
             .o_tx_sb_rsp           (tx_fsm_sb_if.o_tx_sb_rsp),
             .o_tx_sb_done          (tx_fsm_sb_if.o_tx_sb_done),
             .i_rx_decoding         (rx_fsm_sb_if.i_rx_decoding),
             .o_rx_encoding         (rx_fsm_sb_if.o_rx_encoding),
             .i_rx_data             (rx_fsm_sb_if.i_rx_data),
             .o_rx_data             (rx_fsm_sb_if.o_rx_data),
             .i_tx_info             (tx_fsm_sb_if.i_tx_info),
             .i_rx_info             (rx_fsm_sb_if.i_rx_info),
             .o_tx_info             (tx_fsm_sb_if.o_tx_info),
             .o_rx_info             (rx_fsm_sb_if.o_rx_info),
             .i_sb_rx_req           (rx_fsm_sb_if.i_sb_rx_req),
             .i_sb_rx_rsp           (rx_fsm_sb_if.i_sb_rx_rsp),
             .i_sb_rx_done          (rx_fsm_sb_if.i_sb_rx_done),
             .o_rx_sb_req           (rx_fsm_sb_if.o_rx_sb_req),
             .o_rx_sb_rsp           (rx_fsm_sb_if.o_rx_sb_rsp),
             .o_rx_sb_done          (rx_fsm_sb_if.o_rx_sb_done),
             .i_power           (vif.i_power),
             .i_pll_stable      (vif.i_pll_stable),
             .i_rx_error        (vif.i_rx_error),
             .i_rx_done         (vif.i_rx_done),
             .i_tx_done         (vif.i_tx_done),
             .i_val_error       (vif.i_val_error),
             .i_lane_error      (vif.i_lane_error),
             .o_sbinit_start    (vif.o_sbinit_start),
             .i_sb_ready        (vif.i_sb_ready),
             .o_t1_ms           (vif.o_t1_ms),
             .i_reset           (vif.i_reset),
             .i_sb_cur_msg_done (vif.i_sb_cur_msg_done),
             .o_lane_map_tx     (vif.o_lane_map_tx),
             .o_lane_map_rx     (vif.o_lane_map_rx)
             .pl_state_sts    (ltsm_rdi_if_inst.o_pl_state_sts),
             .pl_inband_pres  (ltsm_rdi_if_inst.o_pl_inband_pres),
             .pl_phyinrecenter(ltsm_rdi_if_inst.o_pl_phyinrecenter),
             .pl_stallreq     (ltsm_rdi_if_inst.o_pl_stallreq),
             .pl_clk_req      (ltsm_rdi_if_inst.o_pl_clk_req),
             .pl_wake_ack     (ltsm_rdi_if_inst.o_pl_wake_ack),
             .pl_lnk_cfg      (ltsm_rdi_if_inst.o_pl_lnk_cfg),
             .pl_speedmode    (ltsm_rdi_if_inst.o_pl_speedmode),
             .pl_max_speedmode(ltsm_rdi_if_inst.o_pl_max_speedmode),
             .pl_error        (ltsm_rdi_if_inst.o_pl_error),
             .pl_trainerror   (ltsm_rdi_if_inst.o_pl_trainerror),
             .pl_cerror       (ltsm_rdi_if_inst.o_pl_cerror),
             .pl_nferror      (ltsm_rdi_if_inst.o_pl_nferror),
             .lp_state_req    (ltsm_rdi_if_inst.i_lp_state_req),
             .lp_stallack     (ltsm_rdi_if_inst.i_lp_stallack),
             .lp_clk_ack      (ltsm_rdi_if_inst.i_lp_clk_ack),
             .lp_wake_req     (ltsm_rdi_if_inst.i_lp_wake_req),
             .lp_linkerror    (ltsm_rdi_if_inst.i_lp_linkerror),
             .i_speedreg                            (regfile.i_speedreg),
             .o_speedreg                            (regfile.o_speedreg),
             .i_local_cap                           (regfile.i_local_cap),
             .i_Runtime_Link_Test_status_register   (regfile.i_Runtime_Link_Test_status_register),
             .o_Runtime_Link_Test_status_register   (regfile.o_Runtime_Link_Test_status_register),
             .i_Runtime_Link_Test_Control_register   (regfile.i_Runtime_Link_Test_Control_register),
             .o_Runtime_Link_Test_Control_register   (regfile.o_Runtime_Link_Test_Control_register)
             );

    initial begin

        uvm_config_db#(virtual TX_FSM_SB)::set(null,               "uvm_test_top", "TX_FSM_SB",             tx_fsm_sb_if);
        uvm_config_db#(virtual RX_FSM_SB)::set(null,               "uvm_test_top", "RX_FSM_SB",             rx_fsm_sb_if);
        uvm_config_db#(virtual LTSM_controllers_if)::set(null,     "uvm_test_top", "LTSM_CONTROLLERS_IF",   vif         );
        uvm_config_db#(virtual ltsm_rdi_if)::set(null,    "uvm_test_top", "ltsm_rdi_vif",   ltsm_rdi_if_inst );

        run_test();
    end
endmodule : LTSM_top
