# =============================================================================
# File       : compile.do
# Description: Compile and elaborate the UCIE System-Level Environment.
#
# Usage:
#   From Makefile (batch) : called automatically by 'make compile'
#   From QuestaSim GUI    : do compile.do
#
# Work library path is configured via WORK_DIR below.
# Keep it in sync with WORK_DIR in the Makefile if you change it.
# =============================================================================

set WORK_DIR "./tmp/ucie_sim_work"

puts "=========================================="
puts "Compiling UCIE System-Level Environment..."
puts "Work library: $WORK_DIR"
puts "=========================================="

# ---- Work Library Setup -----------------------------------------------
# Use the _info file as the authoritative marker that a valid library exists.
if {![file exists ${WORK_DIR}/_info]} {
    puts "→ Creating work library in $WORK_DIR..."
    file mkdir $WORK_DIR
    vlib $WORK_DIR
} else {
    puts "→ Work library already exists, using incremental compilation"
}
vmap -c
vmap work $WORK_DIR

# ---- LTSM Environment -------------------------------------------------
puts "→ Compiling LTSM Environment..."
vlog -sv -mfcu -incr +define+UCIE_SYS_LVL=1 -suppress 2583 \
    +incdir+../../LTSM_Environment/src/tb \
    +incdir+../../LTSM_Environment/src/tb/model \
    ../../LTSM_Environment/src/tb/shared_ltsm_pkg.svh \
    ../../LTSM_Environment/src/tb/LTSM_pkg.sv

# ---- SB Environment ---------------------------------------------------
puts "→ Compiling SB Environment..."
vlog -sv -mfcu -incr +define+UCIE_SYS_LVL=1 -suppress 2583 \
    +incdir+../../SB_Environment/src/tb \
    ../../SB_Environment/src/tb/sb_sva.sv \
    ../../SB_Environment/src/tb/sb_shared_pkg.sv \
    ../../SB_Environment/src/tb/sb_pkg.sv

# ---- RP Environment ---------------------------------------------------
puts "→ Compiling RP Environment..."
vlog -sv -mfcu -incr +define+UCIE_SYS_LVL=1 -suppress 2583 \
    +incdir+../../rp_env/src/tb \
    ../../rp_env/src/tb/rp_shared_pkg.sv \
    ../../rp_env/src/tb/rp_pkg.sv

# ---- TP Environment ---------------------------------------------------
puts "→ Compiling TP Environment..."
vlog -sv -mfcu -incr +define+UCIE_SYS_LVL=1 -suppress 2583 \
    +incdir+../../tp_env/packages \
    +incdir+../../tp_env/env \
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
    ../../tp_env/packages/tx_defs_pkg.sv \
    ../../tp_env/ref_model/B2L_modelling.sv \
    ../../tp_env/ref_model/LFSR_modelling.sv \
    ../../tp_env/ref_model/TX_controller_modelling.sv \
    ../../tp_env/ref_model/per_lane_id_modelling.sv \
    ../../tp_env/ref_model/reversal_modelling.sv \
    ../../tp_env/packages/tx_tb_pkg.sv

# ---- DUT Interfaces and BFMs ------------------------------------------
puts "→ Compiling DUT Interfaces and BFMs..."
vlog -sv -incr +define+UCIE_SYS_LVL=1 \
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

# ---- DUT LTSM RTL -----------------------------------------------------
puts "→ Compiling DUT LTSM RTL..."
vlog -sv -mfcu -incr +define+UCIE_SYS_LVL=1 +cover -suppress 2583 \
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

# ---- DUT Sideband RTL -------------------------------------------------
puts "→ Compiling DUT Sideband RTL..."
vlog -sv -mfcu -incr +define+UCIE_SYS_LVL=1 +cover -suppress 2583 \
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

# ---- DUT RX Path RTL --------------------------------------------------
puts "→ Compiling DUT RX Path RTL..."
vlog -sv -mfcu -incr +define+UCIE_SYS_LVL=1 +cover -suppress 2583 \
    ../../rx_path/clock_divider.sv \
    ../../rx_path/clk_valid_pattern_detection.sv \
    ../../rx_path/demux_1_2.sv \
    ../../rx_path/mux_2_1.sv \
    ../../rx_path/deserializer_h.sv \
    ../../rx_path/deserializer_q.sv \
    ../../rx_path/fifo.sv \
    ../../rx_path/lane_id_register.sv \
    ../../rx_path/LFSR_pattern_generator.sv \
    ../../rx_path/counter_compare.sv \
    ../../rx_path/per_lane_id_detector.sv \
    ../../rx_path/receivers.sv \
    ../../rx_path/rx_LFSR.sv \
    ../../rx_path/rx_LFSR_detection.sv \
    ../../rx_path/rx_LFSR_top.sv \
    ../../rx_path/synchonizer.sv \
    ../../rx_path/ucie_lane_to_byte.sv \
    ../../rx_path/ucie_lane_to_byte_decoder.sv \
    ../../rx_path/ucie_mux_2_to_1.sv \
    ../../rx_path/ucie_reordering_block.sv \
    ../../rx_path/ucie_rx_controller.sv \
    ../../rx_path/ucie_shift_register.sv \
    ../../rx_path/rx_path.sv \
    ../../rx_path/per_lane_id_detector_top.svh

# ---- DUT TX Path RTL --------------------------------------------------
puts "→ Compiling DUT TX Path RTL..."
vlog -sv -incr +cover -suppress 2732,7063,2912 \
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
    ../../tx_path/per_lane_id_generator_top.svh

vlog -sv -incr -suppress 2732,7063,2912 \
    ../../tp_env/top/tx_dut_rtl_wrapper.sv \

# ---- Environment Wrappers & Testbench Top -----------------------------
puts "→ Compiling Environment Wrappers & Testbench Top..."
vlog -sv -mfcu -incr +define+UCIE_SYS_LVL=1 -suppress 2583 \
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
    ../../UCIE_top_env/src/tb/ucie_pkg.sv

vlog -sv -mfcu -incr +define+UCIE_SYS_LVL=1 -suppress 2583 +cover \
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
    ../../rx_path/rx_error_decoder.sv \
    ../../UCIE_top/PLL_model.sv \
    ../../UCIE_top/valid_decoder.sv \
    ../../UCIE_top/UCIe.sv

vlog -sv -mfcu -incr +define+UCIE_SYS_LVL=1 -suppress 2583 \
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
    ../../UCIE_top_env/src/tb/ucie_tb_top.sv

# ---- Elaboration (vopt) -----------------------------------------------
puts "→ Elaborating optimized design..."
# 1. Dynamically create a Questa coverage filter file
set cov_file [open "cov_filter.txt" w]
# The +tree command tells Questa to recursively include this instance and all its children.
# Because the first rule is an "include" (+), Questa automatically excludes everything else!
puts $cov_file "+tree /ucie_tb_top/DUT"
close $cov_file

# 2. Run vopt using the filter file (-coverf)
vopt +acc ucie_tb_top -o opt_ucie_tb_top

puts "=========================================="
puts "Compile complete!"
puts "Optimized image: $WORK_DIR/opt_ucie_tb_top"
puts "=========================================="

# Auto-quit when invoked from the Makefile (batch mode).
# In GUI mode [batch_mode] returns 0, so the session stays alive.
if {[batch_mode]} {
    quit -f
}
