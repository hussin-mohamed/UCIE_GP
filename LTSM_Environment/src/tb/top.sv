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
            #1;
            clk=!clk;
        end
    end
   // instantite dut & interfaces
   //assign vif.i_speedreg = ltsm_rdi_if_inst.o_pl_speedmode;
   ltsm_rdi_if ltsm_rdi_if_inst(.clk(clk));
   TX_FSM_SB tx_fsm_sb_if(clk);
   RX_FSM_SB rx_fsm_sb_if(clk);
   LTSM_controllers_if vif(clk);
   assign vif.i_clk = clk;
   assign ltsm_rdi_if_inst.i_reset=vif.i_reset;
   assign tx_fsm_sb_if.i_reset=vif.i_reset;
   assign rx_fsm_sb_if.i_reset=vif.i_reset;
   always_comb begin
    assert (vif.o_speedreg == ltsm_rdi_if_inst.o_pl_speedmode)
        else $error("ASSERTION FAILED: o_speedreg = %0b, o_pl_speedmode = %0b",
                     vif.o_speedreg, ltsm_rdi_if_inst.o_pl_speedmode);
end

   assign vif.o_rx_encoding = rx_fsm_sb_if.o_rx_encoding;
   assign vif.o_tx_encoding = tx_fsm_sb_if.o_tx_encoding;
   ucie_LTSM DUT (.i_clk(clk),
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
             .i_supply_stable   (vif.i_supply_stable),
             .i_pll_stable      (vif.i_pll_stable),
             .i_rx_error        (vif.i_rx_error),
             .i_rx_done         (vif.i_rx_done),
             .i_tx_done         (vif.i_tx_done),
             .i_rx_valid_results       (vif.i_rx_valid_results),
             .i_rx_data_results (vif.i_rx_data_results),
             .i_rx_clk_results     (vif.i_clk_results), // 1st iissue
             .o_sb_init_start    (vif.o_sbinit_start),
             .i_sb_ready        (vif.i_sb_ready),
             //.o_t1_ms           (vif.o_t1_ms),
             .i_reset           (vif.i_reset),
             //.i_par_check_done  (vif.i_par_check_done), // needs to be fixed in the verification model and sequences 
             .i_sb_cur_msg_done (vif.i_sb_cur_msg_done),
             .o_lane_map_tx     (vif.o_lane_map_tx),
             .o_lane_map_rx     (vif.o_lane_map_rx),
             .o_pl_state_sts    (ltsm_rdi_if_inst.o_pl_state_sts),
             .o_pl_inband_pres  (ltsm_rdi_if_inst.o_pl_inband_pres),
             .o_pl_phyinrecenter(ltsm_rdi_if_inst.o_pl_phyinrecenter),
             .o_pl_stallreq     (ltsm_rdi_if_inst.o_pl_stallreq),
             .o_pl_clk_req      (ltsm_rdi_if_inst.o_pl_clk_req),
             .o_pl_wake_ack     (ltsm_rdi_if_inst.o_pl_wake_ack),
             .o_pl_lnk_cfg      (ltsm_rdi_if_inst.o_pl_lnk_cfg),
             .o_pl_speedmode    (ltsm_rdi_if_inst.o_pl_speedmode),
             .o_pl_max_speedmode(ltsm_rdi_if_inst.o_pl_max_speedmode),
             .o_pl_error        (ltsm_rdi_if_inst.o_pl_error),
             .o_pl_trainerror   (ltsm_rdi_if_inst.o_pl_trainerror),
             .o_pl_cerror       (ltsm_rdi_if_inst.o_pl_cerror),
             .o_pl_nferror      (ltsm_rdi_if_inst.o_pl_nferror),
             .i_lp_state_req    (ltsm_rdi_if_inst.i_lp_state_req),
             .i_lp_stallack     (ltsm_rdi_if_inst.i_lp_stallack),
             .i_lp_clk_ack      (ltsm_rdi_if_inst.i_lp_clk_ack),
             .i_lp_wake_req     (ltsm_rdi_if_inst.i_lp_wake_req),
             .i_lp_linkerror    (ltsm_rdi_if_inst.i_lp_linkerror),
             .i_speedreg                            (vif.i_speedreg),
             .o_speedreg                            (vif.o_speedreg),
             //.i_local_cap                           (vif.i_local_cap),
             .i_Runtime_Link_Test_status_register   (vif.i_Runtime_Link_Test_status_register),
             .o_Runtime_Link_Test_status_register   (vif.o_Runtime_Link_Test_status_register),
             .i_Runtime_Link_Test_Control_register   (vif.i_Runtime_Link_Test_Control_register),
             .o_Runtime_Link_Test_Control_register   (vif.o_Runtime_Link_Test_Control_register)
             );

    initial begin

        uvm_config_db#(virtual TX_FSM_SB)::set(null,               "uvm_test_top", "TX_FSM_SB",             tx_fsm_sb_if);
        uvm_config_db#(virtual RX_FSM_SB)::set(null,               "uvm_test_top", "RX_FSM_SB",             rx_fsm_sb_if);
        uvm_config_db#(virtual LTSM_controllers_if)::set(null,     "uvm_test_top", "LTSM_CONTROLLERS_IF",   vif         );
        uvm_config_db#(virtual ltsm_rdi_if)::set(null,    "uvm_test_top", "ltsm_rdi_vif",   ltsm_rdi_if_inst );

        run_test("ACTIVE_test");
    end
endmodule : LTSM_top
