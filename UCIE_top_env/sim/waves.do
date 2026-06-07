# =============================================================================
# File       : waves.do
# Description: Pre-configured waveform groups for every interface and the 
#              UCIe top-level.
# =============================================================================

# ---- Top-Level: Clocks, Reset & DUT I/O Ports ----
add wave -noupdate -group {TB Top — Clocks & Reset} \
    /ucie_tb_top/clk_32 \
    /ucie_tb_top/clk_24 \
    /ucie_tb_top/clk_16 \
    /ucie_tb_top/clk_12 \
    /ucie_tb_top/clk_8 \
    /ucie_tb_top/clk_4 \
    /ucie_tb_top/clk_sb_800_m \
    /ucie_tb_top/clk_sb_100_m \
    /ucie_tb_top/reset \
    /ucie_tb_top/pll_stable \
    /ucie_tb_top/supply_stable

# ---- UCIe.sv Top-Level — Internal Clocks & Key Wires ----
add wave -noupdate -group {UCIe PHY — Internal Clocks} \
    /ucie_tb_top/DUT/clk_mb_f \
    /ucie_tb_top/DUT/clk_mb_h \
    /ucie_tb_top/DUT/clk_l \
    /ucie_tb_top/DUT/sb_ready

# ---- UCIe.sv Top-Level — Port I/O ----
add wave -noupdate -group {UCIe PHY — Ports} \
    /ucie_tb_top/DUT/i_clk_32 \
    /ucie_tb_top/DUT/i_clk_16 \
    /ucie_tb_top/DUT/i_clk_8 \
    /ucie_tb_top/DUT/i_reset \
    /ucie_tb_top/DUT/i_pll_stable \
    /ucie_tb_top/DUT/i_supply_stable \
    /ucie_tb_top/DUT/i_clk_p \
    /ucie_tb_top/DUT/i_clk_n \
    /ucie_tb_top/DUT/i_track \
    /ucie_tb_top/DUT/i_valid \
    /ucie_tb_top/DUT/i_data_in \
    /ucie_tb_top/DUT/i_rx_sb_clk \
    /ucie_tb_top/DUT/i_rx_sb_data \
    /ucie_tb_top/DUT/i_lp_state_req \
    /ucie_tb_top/DUT/i_lp_linkerror \
    /ucie_tb_top/DUT/i_lp_stallack \
    /ucie_tb_top/DUT/i_lp_clk_ack \
    /ucie_tb_top/DUT/i_lp_irdy \
    /ucie_tb_top/DUT/i_lp_valid \
    /ucie_tb_top/DUT/i_lp_data \
    /ucie_tb_top/DUT/i_lp_wake_req \
    /ucie_tb_top/DUT/o_pl_state_sts \
    /ucie_tb_top/DUT/o_pl_inband_pres \
    /ucie_tb_top/DUT/o_pl_error \
    /ucie_tb_top/DUT/o_pl_cerror \
    /ucie_tb_top/DUT/o_pl_nferror \
    /ucie_tb_top/DUT/o_pl_trainerror \
    /ucie_tb_top/DUT/o_pl_phyinrecenter \
    /ucie_tb_top/DUT/o_pl_stallreq \
    /ucie_tb_top/DUT/o_pl_speedmode \
    /ucie_tb_top/DUT/o_pl_lnk_cfg \
    /ucie_tb_top/DUT/o_pl_clk_req \
    /ucie_tb_top/DUT/o_pl_wake_ack \
    /ucie_tb_top/DUT/o_pl_trdy \
    /ucie_tb_top/DUT/o_pl_valid \
    /ucie_tb_top/DUT/o_pl_data \
    /ucie_tb_top/DUT/o_data_out \
    /ucie_tb_top/DUT/o_clk_p \
    /ucie_tb_top/DUT/o_clk_n \
    /ucie_tb_top/DUT/o_track \
    /ucie_tb_top/DUT/o_valid \
    /ucie_tb_top/DUT/o_tx_sb_data \
    /ucie_tb_top/DUT/o_tx_sb_clk

# =============================================================================
#  tp_env/interfaces — TX-Path Environment Interfaces
# =============================================================================

# ---- tp_env/interfaces/ltsm_if.sv ----
add wave -noupdate -group {tp_env — ltsm_if} \
    /ucie_tb_top/DUT/ltsm_intf/clk \
    /ucie_tb_top/DUT/ltsm_intf/rst \
    /ucie_tb_top/DUT/ltsm_intf/tx_encoding \
    /ucie_tb_top/DUT/ltsm_intf/lane_map \
    /ucie_tb_top/DUT/ltsm_intf/pll_stable \
    /ucie_tb_top/DUT/ltsm_intf/supply_stable \
    /ucie_tb_top/DUT/ltsm_intf/tx_done

# ---- tp_env/interfaces/rdi_if.sv ----
add wave -noupdate -group {tp_env — rdi_if} \
    /ucie_tb_top/DUT/rdi_intf/clk \
    /ucie_tb_top/DUT/rdi_intf/rst \
    /ucie_tb_top/DUT/rdi_intf/lp_data \
    /ucie_tb_top/DUT/rdi_intf/lp_valid \
    /ucie_tb_top/DUT/rdi_intf/lp_irdy \
    /ucie_tb_top/DUT/rdi_intf/pl_state_sts \
    /ucie_tb_top/DUT/rdi_intf/pl_trdy

# ---- tp_env/interfaces/tx2link_if.sv ----
add wave -noupdate -group {tp_env — tx2link_if} \
    /ucie_tb_top/DUT/tx2link_intf/clk \
    /ucie_tb_top/DUT/tx2link_intf/ui_clk \
    /ucie_tb_top/DUT/tx2link_intf/rst \
    /ucie_tb_top/DUT/tx2link_intf/tx_data \
    /ucie_tb_top/DUT/tx2link_intf/tx_clkp \
    /ucie_tb_top/DUT/tx2link_intf/tx_clkn \
    /ucie_tb_top/DUT/tx2link_intf/tx_valid \
    /ucie_tb_top/DUT/tx2link_intf/tx_track

# =============================================================================
#  LTSM_Environment/src/interfaces — LTSM Environment Interfaces
# =============================================================================

# ---- LTSM_Environment/src/interfaces/ltsm_rdi_if.sv ----
add wave -noupdate -group {LTSM_Environment — ltsm_rdi_if} \
    /ucie_tb_top/DUT/ltsm_rdi_if_inst/clk \
    /ucie_tb_top/DUT/ltsm_rdi_if_inst/i_reset \
    /ucie_tb_top/DUT/ltsm_rdi_if_inst/o_pl_state_sts \
    /ucie_tb_top/DUT/ltsm_rdi_if_inst/o_pl_inband_pres \
    /ucie_tb_top/DUT/ltsm_rdi_if_inst/o_pl_phyinrecenter \
    /ucie_tb_top/DUT/ltsm_rdi_if_inst/o_pl_stallreq \
    /ucie_tb_top/DUT/ltsm_rdi_if_inst/o_pl_clk_req \
    /ucie_tb_top/DUT/ltsm_rdi_if_inst/o_pl_wake_ack \
    /ucie_tb_top/DUT/ltsm_rdi_if_inst/o_pl_lnk_cfg \
    /ucie_tb_top/DUT/ltsm_rdi_if_inst/o_pl_speedmode \
    /ucie_tb_top/DUT/ltsm_rdi_if_inst/o_pl_max_speedmode \
    /ucie_tb_top/DUT/ltsm_rdi_if_inst/o_pl_error \
    /ucie_tb_top/DUT/ltsm_rdi_if_inst/o_pl_trainerror \
    /ucie_tb_top/DUT/ltsm_rdi_if_inst/o_pl_cerror \
    /ucie_tb_top/DUT/ltsm_rdi_if_inst/o_pl_nferror \
    /ucie_tb_top/DUT/ltsm_rdi_if_inst/i_lp_state_req \
    /ucie_tb_top/DUT/ltsm_rdi_if_inst/i_lp_stallack \
    /ucie_tb_top/DUT/ltsm_rdi_if_inst/i_lp_clk_ack \
    /ucie_tb_top/DUT/ltsm_rdi_if_inst/i_lp_wake_req \
    /ucie_tb_top/DUT/ltsm_rdi_if_inst/i_lp_linkerror

# ---- LTSM_Environment/src/interfaces/TX_FSM_SB_if.sv ----
add wave -noupdate -group {LTSM_Environment — TX_FSM_SB} \
    /ucie_tb_top/DUT/tx_fsm_sb_if/clk \
    /ucie_tb_top/DUT/tx_fsm_sb_if/i_reset \
    /ucie_tb_top/DUT/tx_fsm_sb_if/i_tx_decoding \
    /ucie_tb_top/DUT/tx_fsm_sb_if/o_tx_encoding \
    /ucie_tb_top/DUT/tx_fsm_sb_if/i_tx_data \
    /ucie_tb_top/DUT/tx_fsm_sb_if/o_tx_data \
    /ucie_tb_top/DUT/tx_fsm_sb_if/i_tx_info \
    /ucie_tb_top/DUT/tx_fsm_sb_if/o_tx_info \
    /ucie_tb_top/DUT/tx_fsm_sb_if/i_sb_tx_req \
    /ucie_tb_top/DUT/tx_fsm_sb_if/i_sb_tx_rsp \
    /ucie_tb_top/DUT/tx_fsm_sb_if/i_sb_tx_done \
    /ucie_tb_top/DUT/tx_fsm_sb_if/o_tx_sb_req \
    /ucie_tb_top/DUT/tx_fsm_sb_if/o_tx_sb_rsp \
    /ucie_tb_top/DUT/tx_fsm_sb_if/o_tx_sb_done

# ---- LTSM_Environment/src/interfaces/RX_FSM_SB_if.sv ----
add wave -noupdate -group {LTSM_Environment — RX_FSM_SB} \
    /ucie_tb_top/DUT/rx_fsm_sb_if/clk \
    /ucie_tb_top/DUT/rx_fsm_sb_if/i_reset \
    /ucie_tb_top/DUT/rx_fsm_sb_if/i_rx_decoding \
    /ucie_tb_top/DUT/rx_fsm_sb_if/o_rx_encoding \
    /ucie_tb_top/DUT/rx_fsm_sb_if/i_rx_data \
    /ucie_tb_top/DUT/rx_fsm_sb_if/o_rx_data \
    /ucie_tb_top/DUT/rx_fsm_sb_if/i_rx_info \
    /ucie_tb_top/DUT/rx_fsm_sb_if/o_rx_info \
    /ucie_tb_top/DUT/rx_fsm_sb_if/i_sb_rx_req \
    /ucie_tb_top/DUT/rx_fsm_sb_if/i_sb_rx_rsp \
    /ucie_tb_top/DUT/rx_fsm_sb_if/i_sb_rx_done \
    /ucie_tb_top/DUT/rx_fsm_sb_if/o_rx_sb_req \
    /ucie_tb_top/DUT/rx_fsm_sb_if/o_rx_sb_rsp \
    /ucie_tb_top/DUT/rx_fsm_sb_if/o_rx_sb_done

# ---- LTSM_Environment/src/interfaces/TX_RX_controllers_if.sv ----
add wave -noupdate -group {LTSM_Environment — LTSM_controllers_if} \
    /ucie_tb_top/DUT/LTSM_controllers_vif/clk \
    /ucie_tb_top/DUT/LTSM_controllers_vif/i_clk \
    /ucie_tb_top/DUT/LTSM_controllers_vif/i_reset \
    /ucie_tb_top/DUT/LTSM_controllers_vif/i_supply_stable \
    /ucie_tb_top/DUT/LTSM_controllers_vif/i_pll_stable \
    /ucie_tb_top/DUT/LTSM_controllers_vif/i_rx_error \
    /ucie_tb_top/DUT/LTSM_controllers_vif/i_rx_done \
    /ucie_tb_top/DUT/LTSM_controllers_vif/i_tx_done \
    /ucie_tb_top/DUT/LTSM_controllers_vif/i_rx_valid_results \
    /ucie_tb_top/DUT/LTSM_controllers_vif/i_rx_data_results \
    /ucie_tb_top/DUT/LTSM_controllers_vif/i_clk_results \
    /ucie_tb_top/DUT/LTSM_controllers_vif/i_sb_cur_msg_done \
    /ucie_tb_top/DUT/LTSM_controllers_vif/i_sb_ready \
    /ucie_tb_top/DUT/LTSM_controllers_vif/o_sbinit_start \
    /ucie_tb_top/DUT/LTSM_controllers_vif/o_tx_encoding \
    /ucie_tb_top/DUT/LTSM_controllers_vif/o_rx_encoding \
    /ucie_tb_top/DUT/LTSM_controllers_vif/o_lane_map_tx \
    /ucie_tb_top/DUT/LTSM_controllers_vif/o_lane_map_rx \
    /ucie_tb_top/DUT/LTSM_controllers_vif/i_speedreg \
    /ucie_tb_top/DUT/LTSM_controllers_vif/o_speedreg \
    /ucie_tb_top/DUT/LTSM_controllers_vif/i_Runtime_Link_Test_status_register \
    /ucie_tb_top/DUT/LTSM_controllers_vif/o_Runtime_Link_Test_status_register \
    /ucie_tb_top/DUT/LTSM_controllers_vif/i_Runtime_Link_Test_Control_register \
    /ucie_tb_top/DUT/LTSM_controllers_vif/o_Runtime_Link_Test_Control_register

# ---- LTSM_Environment/src/interfaces/regfile_interface.sv ----
add wave -noupdate -group {LTSM_Environment — regfile_interface} \
    /ucie_tb_top/DUT/LTSM_controllers_vif/i_speedreg \
    /ucie_tb_top/DUT/LTSM_controllers_vif/o_speedreg \
    /ucie_tb_top/DUT/LTSM_controllers_vif/i_Runtime_Link_Test_status_register \
    /ucie_tb_top/DUT/LTSM_controllers_vif/o_Runtime_Link_Test_status_register \
    /ucie_tb_top/DUT/LTSM_controllers_vif/i_Runtime_Link_Test_Control_register \
    /ucie_tb_top/DUT/LTSM_controllers_vif/o_Runtime_Link_Test_Control_register

# =============================================================================
#  rp_env/src/bfms — RX-Path Environment BFMs
# =============================================================================

# ---- rp_env/src/bfms/rp_reset_intf.sv ----
add wave -noupdate -group {rp_env — rp_reset_intf} \
    /ucie_tb_top/DUT/rp_reset_intf_inst/clk \
    /ucie_tb_top/DUT/rp_reset_intf_inst/reset

# ---- rp_env/src/bfms/rp_rdi_bfm.sv ----
add wave -noupdate -group {rp_env — rp_rdi_bfm} \
    /ucie_tb_top/DUT/rp_rdi_bfm_inst/clk \
    /ucie_tb_top/DUT/rp_rdi_bfm_inst/reset \
    /ucie_tb_top/DUT/rp_rdi_bfm_inst/pl_data \
    /ucie_tb_top/DUT/rp_rdi_bfm_inst/pl_valid

# ---- rp_env/src/bfms/rp_ltsm_bfm.sv ----
add wave -noupdate -group {rp_env — rp_ltsmc_bfm} \
    /ucie_tb_top/DUT/rp_ltsmc_bfm_inst/clk \
    /ucie_tb_top/DUT/rp_ltsmc_bfm_inst/reset \
    /ucie_tb_top/DUT/rp_ltsmc_bfm_inst/i_lane_map_code \
    /ucie_tb_top/DUT/rp_ltsmc_bfm_inst/i_rx_encoding \
    /ucie_tb_top/DUT/rp_ltsmc_bfm_inst/i_error_threshold \
    /ucie_tb_top/DUT/rp_ltsmc_bfm_inst/i_half_rate \
    /ucie_tb_top/DUT/rp_ltsmc_bfm_inst/o_rx_done \
    /ucie_tb_top/DUT/rp_ltsmc_bfm_inst/o_rx_data_results \
    /ucie_tb_top/DUT/rp_ltsmc_bfm_inst/o_clk_result \
    /ucie_tb_top/DUT/rp_ltsmc_bfm_inst/o_valid_result

# ---- rp_env/src/bfms/rp_rmblink_bfm.sv ----
add wave -noupdate -group {rp_env — rp_rmblink_bfm} \
    /ucie_tb_top/DUT/rp_rmblink_bfm_inst/clk \
    /ucie_tb_top/DUT/rp_rmblink_bfm_inst/i_hclk \
    /ucie_tb_top/DUT/rp_rmblink_bfm_inst/i_dclk \
    /ucie_tb_top/DUT/rp_rmblink_bfm_inst/reset \
    /ucie_tb_top/DUT/rp_rmblink_bfm_inst/i_clk_p \
    /ucie_tb_top/DUT/rp_rmblink_bfm_inst/i_clk_n \
    /ucie_tb_top/DUT/rp_rmblink_bfm_inst/i_track \
    /ucie_tb_top/DUT/rp_rmblink_bfm_inst/i_data \
    /ucie_tb_top/DUT/rp_rmblink_bfm_inst/i_valid \
    /ucie_tb_top/DUT/rp_rmblink_bfm_inst/i_rx_encoding

# =============================================================================
#  sb_env/src/bfms — Sideband Environment BFMs
# =============================================================================

# ---- sb_env/src/bfms/sb_reset_intf.sv ----
add wave -noupdate -group {sb_env — sb_reset_intf} \
    /ucie_tb_top/DUT/reset_intf/clk \
    /ucie_tb_top/DUT/reset_intf/reset

# ---- sb_env/src/bfms/sb_ltsm_ctrl_bfm.sv ----
add wave -noupdate -group {sb_env — sb_ltsm_ctrl_bfm} \
    /ucie_tb_top/DUT/ltsm_ctrl_bfm/clk \
    /ucie_tb_top/DUT/ltsm_ctrl_bfm/reset \
    /ucie_tb_top/DUT/ltsm_ctrl_bfm/o_sb_ready \
    /ucie_tb_top/DUT/ltsm_ctrl_bfm/i_sb_init_start \
    /ucie_tb_top/DUT/ltsm_ctrl_bfm/i_timer_1ms \
    /ucie_tb_top/DUT/ltsm_ctrl_bfm/tms \
    /ucie_tb_top/DUT/ltsm_ctrl_bfm/timeout \
    /ucie_tb_top/DUT/ltsm_ctrl_bfm/timer_en

# ---- sb_env/src/bfms/sb_tx_bfm.sv ----
add wave -noupdate -group {sb_env — sb_tx_bfm} \
    /ucie_tb_top/DUT/tx_bfm/clk \
    /ucie_tb_top/DUT/tx_bfm/reset \
    /ucie_tb_top/DUT/tx_bfm/o_sb_ready \
    /ucie_tb_top/DUT/tx_bfm/i_tx_sb_req \
    /ucie_tb_top/DUT/tx_bfm/i_tx_sb_rsp \
    /ucie_tb_top/DUT/tx_bfm/i_tx_sb_done \
    /ucie_tb_top/DUT/tx_bfm/i_tx_encoding \
    /ucie_tb_top/DUT/tx_bfm/i_tx_data \
    /ucie_tb_top/DUT/tx_bfm/i_tx_info \
    /ucie_tb_top/DUT/tx_bfm/o_sb_tx_req \
    /ucie_tb_top/DUT/tx_bfm/o_sb_tx_rsp \
    /ucie_tb_top/DUT/tx_bfm/o_sb_tx_done \
    /ucie_tb_top/DUT/tx_bfm/o_tx_decoding \
    /ucie_tb_top/DUT/tx_bfm/o_tx_data \
    /ucie_tb_top/DUT/tx_bfm/o_tx_info \
    /ucie_tb_top/DUT/tx_bfm/o_tx_valid

# ---- sb_env/src/bfms/sb_rx_bfm.sv ----
add wave -noupdate -group {sb_env — sb_rx_bfm} \
    /ucie_tb_top/DUT/rx_bfm/clk \
    /ucie_tb_top/DUT/rx_bfm/reset \
    /ucie_tb_top/DUT/rx_bfm/o_sb_ready \
    /ucie_tb_top/DUT/rx_bfm/i_rx_sb_req \
    /ucie_tb_top/DUT/rx_bfm/i_rx_sb_rsp \
    /ucie_tb_top/DUT/rx_bfm/i_rx_sb_done \
    /ucie_tb_top/DUT/rx_bfm/i_rx_encoding \
    /ucie_tb_top/DUT/rx_bfm/i_rx_data \
    /ucie_tb_top/DUT/rx_bfm/i_rx_info \
    /ucie_tb_top/DUT/rx_bfm/o_sb_rx_req \
    /ucie_tb_top/DUT/rx_bfm/o_sb_rx_rsp \
    /ucie_tb_top/DUT/rx_bfm/o_sb_rx_done \
    /ucie_tb_top/DUT/rx_bfm/o_rx_decoding \
    /ucie_tb_top/DUT/rx_bfm/o_rx_data \
    /ucie_tb_top/DUT/rx_bfm/o_rx_info \
    /ucie_tb_top/DUT/rx_bfm/o_rx_valid

run 0ns

# ---- sb_env/src/bfms/sb_phylink_bfm.sv ----
add wave -noupdate -group {sb_env — sb_phylink_bfm} \
    sim:/ucie_tb_top/phylink_bfm/clk \
    sim:/ucie_tb_top/phylink_bfm/clk_800MHz \
    sim:/ucie_tb_top/phylink_bfm/reset
add wave -noupdate -group {sb_env — sb_phylink_bfm} -color Gold \
    sim:/ucie_tb_top/DUT/rp_rmblink_bfm_inst/i_rx_encoding
add wave -noupdate -group {sb_env — sb_phylink_bfm} -color Cyan \
    sim:/uvm_test_top/env/sb_env_i/phylink_agt/drvr/m_op_mode
add wave -noupdate -group {sb_env — sb_phylink_bfm} -color Cyan \
    sim:/uvm_test_top/env/vseqr/msg_ser_status
add wave -noupdate -group {sb_env — sb_phylink_bfm} \
    sim:/ucie_tb_top/phylink_bfm/o_sb_ready \
    sim:/ucie_tb_top/phylink_bfm/i_rx_sb_data \
    sim:/ucie_tb_top/phylink_bfm/i_rx_sb_clk \
    sim:/ucie_tb_top/phylink_bfm/o_tx_sb_data \
    sim:/ucie_tb_top/phylink_bfm/o_tx_sb_clk \
    sim:/ucie_tb_top/phylink_bfm/tms \
    sim:/ucie_tb_top/phylink_bfm/timeout \
    sim:/ucie_tb_top/phylink_bfm/start \
    sim:/ucie_tb_top/phylink_bfm/in_pat_detected \
    sim:/ucie_tb_top/phylink_bfm/out_pat_detected

# ---- sb_env/src/tb/sb_sva.sv ----
add wave -group {sb_env — Assertions} -position insertpoint  \
    sim:/ucie_tb_top/DUT/sideband/sva_inst/ap_pat_gen \
    sim:/ucie_tb_top/DUT/sideband/sva_inst/ap_pat_low \
    sim:/ucie_tb_top/DUT/sideband/sva_inst/ap_clk_gen \
    sim:/ucie_tb_top/DUT/sideband/sva_inst/ap_clk_low \
    sim:/ucie_tb_top/DUT/sideband/sva_inst/chk_async_reset \
    sim:/ucie_tb_top/DUT/sideband/sva_inst/chk_no_clk_glitch \
    sim:/ucie_tb_top/DUT/sideband/sva_inst/pat_detected \
    sim:/ucie_tb_top/DUT/sideband/sva_inst/timeout \
    sim:/ucie_tb_top/DUT/sideband/sva_inst/clk_800MHz \
    sim:/ucie_tb_top/DUT/sideband/sva_inst/i_timer_1ms \
    sim:/ucie_tb_top/DUT/sideband/sva_inst/tms

.vcop Action toggleleafnames

# =============================================================================
#  Final waveform settings
# =============================================================================
WaveRestoreZoom {0 ns} {500 ns}
configure wave -namecolwidth 300
configure wave -valuecolwidth 120
configure wave -timelineunits ns
