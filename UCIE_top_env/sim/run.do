# =============================================================================
# File       : run.do
# Description: Full flow — compile, optimize, and simulate in one shot.
#              For split flows use compile_only.do then sim_only.do.
#
# Usage (from UCIE_top_env/sim):
#   vsim -c -do "set UCIE_SYS_LVL 1; do run.do"
#   vsim -c -do "set UCIE_SYS_LVL 1; set UVM_TESTNAME ucie_sanity_test; do run.do"
# =============================================================================

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

# 8. Compile DUT TX Path RTL (using lists to handle spaces in paths properly)
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

#set tx_path_files [list \
#    "../../tx_path/clock_divider.sv" \
#    "../../tx_path/clk_valid_pattern_generation.sv" \
#    "../../tx_path/demux_1_2.sv" \
#    "../../tx_path/mux_2_1.sv" \
#    "../../tx_path/fifo.sv" \
#    "../../tx_path/lane_id_register.sv" \
#    "../../tx_path/LFSR_pattern_generator.sv" \
#    "../../tx_path/empty_decoder.sv" \
#    "../../tx_path/pattern_generation_decoder.sv" \
#    "../../tx_path/reversal.sv" \
#    "../../tx_path/serializer.sv" \
#    "../../tx_path/synchonizer.sv" \
#    "../../tx_path/tx_controller.sv" \
#    "../../tx_path/tx_LFSR.sv" \
#    "../../tx_path/tx_LFSR_top.sv" \
#    "../../tx_path/ucie_byte_to_lane_decoder.sv" \
#    "../../tx_path/ucie_shift_register_b2l.sv" \
#    "../../tx_path/ucie_byte_to_lane.sv" \
#    "../../tx_path/ucie_mux_4_to_1.sv" \
#    "../../tx_path/drivers.sv" \
#    "../../tx_path/tx_path.sv" \
#    "../../tp_env/top/tx_dut_rtl_wrapper.sv" \
#    "../../tx_path/per_lane_id_generator_top.svh" \
#]
#vlog {*}$vlog_args {*}$tx_path_files

# 9. Compile DUT RX Path RTL (using lists to handle spaces in paths properly)
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

# 11. Elaboration & Simulation
vopt +acc ucie_tb_top -o opt_ucie_tb_top
vsim -c opt_ucie_tb_top -classdebug +UVM_TESTNAME=$UVM_TESTNAME -do "run -all; quit"
