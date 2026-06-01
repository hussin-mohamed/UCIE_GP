# =============================================================================
# File       : waves.do
# Description: Compile, optimize, and simulate in GUI mode with pre-configured
#              waveform groups for every interface and the UCIe top-level.
#
# Usage (from UCIE_top_env/sim):
#   vsim -do "set UCIE_SYS_LVL 1; do waves.do"
#   vsim -do "set UCIE_SYS_LVL 1; set UVM_TESTNAME ucie_sanity_test; do waves.do"
# =============================================================================

# ---- Source the compilation & elaboration flow (reuse run.do logic) ---------
if {![info exists UCIE_SYS_LVL]} {
    set UCIE_SYS_LVL 0
}

if {![info exists UVM_TESTNAME]} {
    set UVM_TESTNAME ucie_base_test
}

# Define compilation flags and system level define macro if requested
set vlog_args [list "-sv" "-mfcu"]
set vlog_args_no_mfcu [list "-sv"]
if {$UCIE_SYS_LVL} {
    lappend vlog_args "+define+UCIE_SYS_LVL"
    lappend vlog_args_no_mfcu "+define+UCIE_SYS_LVL"
    echo "Compiling with +define+UCIE_SYS_LVL"
} else {
    echo "Compiling WITHOUT system-level define"
}

# Create and map work library
vlib work
vmap work work

# 1. Compile LTSM Environment
vlog {*}$vlog_args +incdir+../../LTSM_Environment/src/tb +incdir+../../LTSM_Environment/src/tb/model \
    ../../LTSM_Environment/src/tb/shared_ltsm_pkg.svh \
    ../../LTSM_Environment/src/tb/LTSM_pkg.sv

# 2. Compile SB Environment
vlog {*}$vlog_args +incdir+../../SB_Environment/src/tb \
    ../../SB_Environment/src/tb/sb_shared_pkg.sv \
    ../../SB_Environment/src/tb/sb_pkg.sv

# 3. Compile RP Environment
vlog {*}$vlog_args +incdir+../../rp_env/src/tb \
    ../../rp_env/src/tb/rp_shared_pkg.sv \
    ../../rp_env/src/tb/rp_pkg.sv

# 4. Compile TP Environment
vlog {*}$vlog_args +incdir+../../tp_env/packages +incdir+../../tp_env/env +incdir+../../tp_env/ref_model \
    +incdir+../../tp_env/seq_items +incdir+../../tp_env/agents +incdir+../../tp_env/agents/rdi_agent \
    +incdir+../../tp_env/agents/ltsm_agent +incdir+../../tp_env/agents/tx2link_agent +incdir+../../tp_env/seq_lib \
    +incdir+../../tp_env/scoreboard +incdir+../../tp_env/coverage +incdir+../../tp_env/tests \
    ../../tp_env/packages/tx_defs_pkg.sv \
    ../../tp_env/ref_model/B2L_modelling.sv \
    ../../tp_env/ref_model/LFSR_modelling.sv \
    ../../tp_env/ref_model/TX_controller_modelling.sv \
    ../../tp_env/ref_model/per_lane_id_modelling.sv \
    ../../tp_env/ref_model/reversal_modelling.sv \
    ../../tp_env/packages/tx_tb_pkg.sv

# 5. Compile DUT Interfaces and BFMs
vlog {*}$vlog_args_no_mfcu \
    ../../tp_env/interfaces/ltsm_if.sv \
    ../../LTSM_Environment/src/interfaces/ltsm_rdi_if.sv \
    ../../tp_env/interfaces/rdi_if.sv \
    ../../rp_env/src/bfms/rp_ltsm_bfm.sv \
    ../../rp_env/src/bfms/rp_rdi_bfm.sv \
    ../../rp_env/src/bfms/rp_reset_intf.sv \
    ../../rp_env/src/bfms/rp_rmblink_bfm.sv \
    ../../LTSM_Environment/src/interfaces/RX_FSM_SB_if.sv \
    ../../SB_Environment/src/bfms/sb_ltsm_ctrl_bfm.sv \
    ../../SB_Environment/src/bfms/sb_phylink_bfm.sv \
    ../../SB_Environment/src/bfms/sb_rdi_bfm.sv \
    ../../SB_Environment/src/bfms/sb_reset_intf.sv \
    ../../SB_Environment/src/bfms/sb_rx_bfm.sv \
    ../../SB_Environment/src/bfms/sb_tx_bfm.sv \
    ../../tp_env/interfaces/tx2link_if.sv \
    ../../LTSM_Environment/src/interfaces/TX_FSM_SB_if.sv \
    ../../LTSM_Environment/src/interfaces/TX_RX_controllers_if.sv \
    ../../LTSM_Environment/src/interfaces/regfile_interface.sv

# 6. Compile DUT LTSM RTL
vlog {*}$vlog_args \
    ../../LTSM/ucie_Register_File.sv \
    ../../LTSM/ucie_timeout_timer.sv \
    ../../LTSM/ucie_ltsm_tx_reset.sv \
    ../../LTSM/ucie_ltsm_tx_sbinit.sv \
    ../../LTSM/ucie_ltsm_tx_mbinit_cal.sv \
    ../../LTSM/ucie_ltsm_tx_mbinit_param.sv \
    ../../LTSM/ucie_ltsm_tx_mbinit_reversal.sv \
    ../../LTSM/ucie_ltsm_tx_mbinit_repairclk.sv \
    ../../LTSM/ucie_ltsm_tx_mbinit_repairmb.sv \
    ../../LTSM/ucie_ltsm_tx_mbinit_repairval.sv \
    ../../LTSM/ucie_LTSM_TX_MBTRAIN.sv \
    ../../LTSM/ucie_LTSM_TX_L1.sv \
    ../../LTSM/ucie_LTSM_TX_phyretrain.sv \
    ../../LTSM/ucie_ltsm_tx_trainerror.sv \
    ../../LTSM/ucie_ltsm_rx_reset.sv \
    ../../LTSM/ucie_ltsm_rx_sbinit.sv \
    ../../LTSM/ucie_ltsm_rx_mbinit_cal.sv \
    ../../LTSM/ucie_ltsm_rx_mbinit_param.sv \
    ../../LTSM/ucie_ltsm_rx_mbinit_reversal.sv \
    ../../LTSM/ucie_ltsm_rx_mbinit_repairclk.sv \
    ../../LTSM/ucie_ltsm_rx_mbinit_repairmb.sv \
    ../../LTSM/ucie_ltsm_rx_mbinit_repairval.sv \
    ../../LTSM/ucie_LTSM_RX_MBTRAIN.sv \
    ../../LTSM/ucie_LTSM_RX_L1.sv \
    ../../LTSM/ucie_LTSM_RX_phyretrain.sv \
    ../../LTSM/ucie_ltsm_rx_trainerror.sv \
    ../../LTSM/ucie_ltsm_active_fsm.sv \
    ../../LTSM/ucie_ltsm_active.sv \
    ../../LTSM/ucie_ltsm_linkinit_tx.sv \
    ../../LTSM/ucie_ltsm_linkinit_rx.sv \
    ../../LTSM/ucie_ltsm_init_fsm.sv \
    ../../LTSM/ucie_LTSM.sv \
    ../../LTSM/ucie_RX_Data_to_Clock_eye_sweep.sv \
    ../../LTSM/ucie_TX_Data_to_Clock_eye_sweep.sv

# 7. Compile DUT Sideband RTL
vlog {*}$vlog_args \
    ../../Sideband/Toggle_sync.sv \
    ../../Sideband/ucie_sb_rx_path.sv \
    ../../Sideband/ucie_sb_top.sv \
    ../../Sideband/ucie_sb_traffic.sv \
    ../../Sideband/ucie_sb_tx_path.sv \
    ../../Sideband/ucie_sideband_demux.sv \
    ../../Sideband/ucie_sideband_deser.sv \
    ../../Sideband/ucie_sideband_fifo.sv \
    ../../Sideband/ucie_sideband_fifo_FWFT.sv \
    ../../Sideband/ucie_sideband_fifo_traffic.sv \
    ../../Sideband/ucie_sideband_in.sv \
    ../../Sideband/ucie_sideband_mux.sv \
    ../../Sideband/ucie_sideband_out.sv \
    ../../Sideband/ucie_sideband_rx_msg.sv \
    ../../Sideband/ucie_sideband_rx_msg_enc_dec.sv \
    ../../Sideband/ucie_sideband_ser.sv \
    ../../Sideband/ucie_sideband_traffic_fifo.sv \
    ../../Sideband/ucie_sideband_tx_msg.sv \
    ../../Sideband/ucie_sideband_tx_msg_enc_dec.sv

# 8. Compile DUT TX Path RTL
vlog -sv -suppress 2732,7063,2912 \
  ../../tx_path/synchonizer.sv \
  ../../tx_path/ucie_mux_4_to_1.sv \
  ../../tx_path/ucie_shift_register_b2l.sv \
  ../../tx_path/ucie_byte_to_lane_decoder.sv \
  ../../tx_path/lane_id_register.sv \
  ../../tx_path/mux_2_1.sv \
  ../../tx_path/reversal.sv \
  ../../tx_path/clock_divider.sv \
  ../../tx_path/LFSR_pattern_generator.sv \
  ../../tx_path/tx_LFSR.sv \
  ../../tx_path/tx_LFSR_top.sv \
  ../../tx_path/fifo.sv \
  ../../tx_path/serializer.sv \
  ../../tx_path/empty_decoder.sv \
  ../../tx_path/pattern_generation_decoder.sv \
  ../../tx_path/clk_valid_pattern_generation.sv \
  ../../tx_path/drivers.sv \
  ../../tx_path/ucie_byte_to_lane.sv \
  ../../tx_path/tx_controller.sv \
  ../../tx_path/tx_path.sv \
  ../../tp_env/top/tx_dut_rtl_wrapper.sv \
  ../../tx_path/per_lane_id_generator_top.svh 

# 9. Compile DUT RX Path RTL
set rx_path_files [list \
    "../../rx_path/clock_divider.sv" \
    "../../rx_path/clk_valid_pattern_detection.sv" \
    "../../rx_path/demux_1_2.sv" \
    "../../rx_path/mux_2_1.sv" \
    "../../rx_path/deserializer_h.sv" \
    "../../rx_path/deserializer_q.sv" \
    "../../rx_path/fifo.sv" \
    "../../rx_path/lane_id_register.sv" \
    "../../rx_path/LFSR_pattern_generator.sv" \
    "../../rx_path/counter_compare.sv" \
    "../../rx_path/per_lane_id_detector.sv" \
    "../../rx_path/receivers.sv" \
    "../../rx_path/rx_LFSR.sv" \
    "../../rx_path/rx_LFSR_detection.sv" \
    "../../rx_path/rx_LFSR_top.sv" \
    "../../rx_path/synchonizer.sv" \
    "../../rx_path/ucie_lane_to_byte.sv" \
    "../../rx_path/ucie_lane_to_byte_decoder.sv" \
    "../../rx_path/ucie_mux_2_to_1.sv" \
    "../../rx_path/ucie_reordering_block.sv" \
    "../../rx_path/ucie_rx_controller.sv" \
    "../../rx_path/ucie_shift_register.sv" \
    "../../rx_path/rx_path.sv" \
    "../../rx_path/per_lane_id_detector_top.svh" \
]
vlog {*}$vlog_args {*}$rx_path_files

# 10. Compile Environment Wrappers & Testbench Top
set top_files [list \
    "../../rx_path/rx_error_decoder.sv" \
    "../../UCIE_top/PLL_model.sv" \
    "../../UCIE_top/valid_decoder.sv" \
    "../../UCIE_top/UCIe.sv" \
    "../../UCIE_top_env/src/tb/ucie_tb_top.sv" \
]
vlog {*}$vlog_args \
    +incdir+../../LTSM_Environment/src/tb \
    +incdir+../../SB_Environment/src/tb \
    +incdir+../../rp_env/src/tb \
    +incdir+../../tp_env/packages \
    +incdir+../../tp_env/ref_model \
    +incdir+../../tp_env/seq_items \
    +incdir+../../tp_env/agents \
    +incdir+../../tp_env/agents/rdi_agent \
    +incdir+../../tp_env/agents/ltsm_agent \
    +incdir+../../tp_env/agents/tx2link_agent \
    +incdir+../../tp_env/seq_lib \
    +incdir+../../tp_env/scoreboard \
    +incdir+../../tp_env/coverage \
    +incdir+../../tp_env/tests \
    +incdir+../../UCIE_top_env/src/tb \
    +incdir+../../UCIE_top_env/src/env \
    +incdir+../../UCIE_top_env/src/seq_lib \
    +incdir+../../UCIE_top_env/src/tests \
    ../../UCIE_top_env/src/tb/ucie_pkg.sv \
    {*}$top_files

# 11. Elaboration
vopt +acc ucie_tb_top -o opt_ucie_tb_top

# 12. Launch simulation in GUI mode
vsim opt_ucie_tb_top -classdebug +UVM_TESTNAME=$UVM_TESTNAME +UVM_VERBOSITY=UVM_DEBUG

# =============================================================================
#  WAVEFORM CONFIGURATION — Add all interface signals in organized groups
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
#  SB_Environment/src/bfms — Sideband Environment BFMs
# =============================================================================

# ---- SB_Environment/src/bfms/sb_reset_intf.sv ----
add wave -noupdate -group {SB_Environment — sb_reset_intf} \
    /ucie_tb_top/DUT/reset_intf/clk \
    /ucie_tb_top/DUT/reset_intf/reset

# ---- SB_Environment/src/bfms/sb_ltsm_ctrl_bfm.sv ----
add wave -noupdate -group {SB_Environment — sb_ltsm_ctrl_bfm} \
    /ucie_tb_top/DUT/ltsm_ctrl_bfm/clk \
    /ucie_tb_top/DUT/ltsm_ctrl_bfm/reset \
    /ucie_tb_top/DUT/ltsm_ctrl_bfm/o_sb_ready \
    /ucie_tb_top/DUT/ltsm_ctrl_bfm/i_sb_init_start \
    /ucie_tb_top/DUT/ltsm_ctrl_bfm/i_timer_1ms \
    /ucie_tb_top/DUT/ltsm_ctrl_bfm/tms \
    /ucie_tb_top/DUT/ltsm_ctrl_bfm/timeout \
    /ucie_tb_top/DUT/ltsm_ctrl_bfm/timer_en

# ---- SB_Environment/src/bfms/sb_tx_bfm.sv ----
add wave -noupdate -group {SB_Environment — sb_tx_bfm} \
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

# ---- SB_Environment/src/bfms/sb_rx_bfm.sv ----
add wave -noupdate -group {SB_Environment — sb_rx_bfm} \
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

# ---- SB_Environment/src/bfms/sb_rdi_bfm.sv ----
add wave -noupdate -group {SB_Environment — sb_rdi_bfm} \
    /ucie_tb_top/DUT/rdi_bfm/clk \
    /ucie_tb_top/DUT/rdi_bfm/reset \
    /ucie_tb_top/DUT/rdi_bfm/o_sb_ready \
    /ucie_tb_top/DUT/rdi_bfm/i_lp_cfg_vld \
    /ucie_tb_top/DUT/rdi_bfm/i_lp_cfg_crd \
    /ucie_tb_top/DUT/rdi_bfm/i_lp_cfg \
    /ucie_tb_top/DUT/rdi_bfm/o_pl_cfg_vld \
    /ucie_tb_top/DUT/rdi_bfm/o_pl_cfg_crd \
    /ucie_tb_top/DUT/rdi_bfm/o_pl_cfg

# ---- SB_Environment/src/bfms/sb_phylink_bfm.sv ----
add wave -noupdate -group {SB_Environment — sb_phylink_bfm} \
    /ucie_tb_top/phylink_bfm/clk \
    /ucie_tb_top/phylink_bfm/clk_800MHz \
    /ucie_tb_top/phylink_bfm/reset \
    /ucie_tb_top/phylink_bfm/o_sb_ready \
    /ucie_tb_top/phylink_bfm/i_rx_sb_data \
    /ucie_tb_top/phylink_bfm/i_rx_sb_clk \
    /ucie_tb_top/phylink_bfm/o_tx_sb_data \
    /ucie_tb_top/phylink_bfm/o_tx_sb_clk \
    /ucie_tb_top/phylink_bfm/tms \
    /ucie_tb_top/phylink_bfm/timeout \
    /ucie_tb_top/phylink_bfm/start \
    /ucie_tb_top/phylink_bfm/pat_detected

# =============================================================================
#  Final waveform settings
# =============================================================================
WaveRestoreZoom {0 ns} {500 ns}
configure wave -namecolwidth 300
configure wave -valuecolwidth 120
configure wave -timelineunits ns

# Start simulation
run -all
