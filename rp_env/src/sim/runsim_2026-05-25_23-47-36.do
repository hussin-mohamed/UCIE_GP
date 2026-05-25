vlib work
 vlog ../../../rx_path/LFSR_pattern_generator.sv ../../../rx_path/clk_valid_pattern_detection.sv ../../../rx_path/clk_valid_pattern_detection_tb.sv ../../../rx_path/clock_divider.sv ../../../rx_path/counter_compare.sv ../../../rx_path/demux_1_2.sv ../../../rx_path/deserializer_h.sv ../../../rx_path/deserializer_q.sv ../../../rx_path/fifo.sv ../../../rx_path/lane_id_register.sv ../../../rx_path/mux_2_1.sv ../../../rx_path/per_lane_id_detector.sv ../../../rx_path/per_lane_id_detector_tb.sv ../../../rx_path/per_lane_id_detector_top.svh ../../../rx_path/receivers.sv ../../../rx_path/rx_LFSR.sv ../../../rx_path/rx_LFSR_detection.sv ../../../rx_path/rx_LFSR_tb.svh ../../../rx_path/rx_LFSR_top.sv ../../../rx_path/rx_path.sv ../../../rx_path/synchonizer.sv ../../../rx_path/ucie_lane_to_byte.sv ../../../rx_path/ucie_lane_to_byte_decoder.sv ../../../rx_path/ucie_mux_2_to_1.sv ../../../rx_path/ucie_reordering_block.sv ../../../rx_path/ucie_rx_controller.sv ../../../rx_path/ucie_shift_register.sv +cover +define+SIM
vlog -f src_files.f -mfcu +define+SIM

# Read parameters passed dynamically from the Makefile via environment variables
set TESTNAME    rp_test_base
set VERBOSITY   UVM_HIGH
set SEED        random
set COV_DB      out/ucdb/2026-05-25_23-47-36_rp_test_base_run1.ucdb
set COV_TXT     out/reports/text/2026-05-25_23-47-36_rp_test_base_run1_code_cov.txt
set COV_FUNC_TXT  out/reports/text/2026-05-25_23-47-36_rp_test_base_run1_func_cov.txt
set COV_FUNC_HTML out/reports/html/2026-05-25_23-47-36_rp_test_base_run1_func_html
set COV_CODE_HTML out/reports/html/2026-05-25_23-47-36_rp_test_base_run1_code_html

vsim -voptargs=+acc -nodpiexports work.rp_tb_top -classdebug -uvmcontrol=all -cover \
    +UVM_VERBOSITY=$VERBOSITY \
    +UVM_NO_RELNOTES \
    +UVM_TESTNAME=$TESTNAME \
    +UVM_TIMEOUT=100000,YES \
    -sv_seed $SEED

set NoQuitOnFinish 1

# ====================================================================
# WAVEFORM GROUPS - RX-Path Verification Environment
# ====================================================================

# 1. Global Clock & Reset
# add wave -group Global_Signals -position insertpoint  \
  sim:/rp_tb_top/reset_intf/clk \
  sim:/rp_tb_top/reset_intf/reset \
  sim:/rp_tb_top/rmblink_bfm/clk_800MHz

# 2. LTSM Control BFM
# add wave -group LTSM_CTRL -position insertpoint  \
  sim:/rp_tb_top/ltsmc_bfm/i_sb_init_start \
  sim:/rp_tb_top/ltsmc_bfm/i_timer_1ms \
  sim:/rp_tb_top/ltsmc_bfm/o_sb_ready \
  sim:/rp_tb_top/ltsmc_bfm/timeout \
  sim:/rp_tb_top/ltsmc_bfm/tms

# 3. PHY Link BFM (Serial MDI)
# add wave -group PHY_LINK_MDI -position insertpoint  \
  sim:/rp_tb_top/rmblink_bfm/i_rx_sb_data \
  sim:/rp_tb_top/rmblink_bfm/i_rx_sb_clk \
  sim:/rp_tb_top/rmblink_bfm/o_tx_sb_data \
  sim:/rp_tb_top/rmblink_bfm/o_tx_sb_clk \
  sim:/rp_tb_top/rmblink_bfm/pat_detected

# add wave -group u_tx_msg_enc_dec -position insertpoint  \
  sim:/rp_tb_top/dut/u_tx_msg/u_tx_msg_enc_dec/*

# 4. SVA Assertions (bound inside DUT)
# add wave -group SVAs -position insertpoint  \
  sim:/rp_tb_top/dut/sva_inst/ap_pat_gen \
  sim:/rp_tb_top/dut/sva_inst/ap_pat_low \
  sim:/rp_tb_top/dut/sva_inst/ap_clk_gen \
  sim:/rp_tb_top/dut/sva_inst/ap_clk_low \
  sim:/rp_tb_top/dut/sva_inst/chk_async_reset \
  sim:/rp_tb_top/dut/sva_inst/chk_no_clk_glitch \
  sim:/rp_tb_top/dut/sva_inst/pat_detected \
  sim:/rp_tb_top/dut/sva_inst/timeout \
  sim:/rp_tb_top/dut/sva_inst/tms

# 4. RDI BFM (Adapter <-> SB)
# add wave -group RDI_ADAPTER -position insertpoint  \
#   sim:/rp_tb_top/rdi_bfm/i_lp_cfg_vld \
#   sim:/rp_tb_top/rdi_bfm/i_lp_cfg_crd \
#   sim:/rp_tb_top/rdi_bfm/i_lp_cfg \
#   sim:/rp_tb_top/rdi_bfm/o_pl_cfg_vld \
#   sim:/rp_tb_top/rdi_bfm/o_pl_cfg_crd \
#   sim:/rp_tb_top/rdi_bfm/o_pl_cfg

# 5. TX Path BFM (TX <-> SB)
# add wave -group TX_PATH -position insertpoint  \
  sim:/rp_tb_top/tx_bfm/i_tx_sb_req \
  sim:/rp_tb_top/tx_bfm/i_tx_sb_rsp \
  sim:/rp_tb_top/tx_bfm/i_tx_sb_done \
  sim:/rp_tb_top/tx_bfm/i_tx_encoding \
  sim:/rp_tb_top/tx_bfm/i_tx_data \
  sim:/rp_tb_top/tx_bfm/i_tx_info \
  sim:/rp_tb_top/tx_bfm/o_sb_tx_req \
  sim:/rp_tb_top/tx_bfm/o_sb_tx_rsp \
  sim:/rp_tb_top/tx_bfm/o_sb_tx_done \
  sim:/rp_tb_top/tx_bfm/o_tx_decoding \
  sim:/rp_tb_top/tx_bfm/o_tx_data \
  sim:/rp_tb_top/tx_bfm/o_tx_info \
  sim:/rp_tb_top/tx_bfm/o_tx_valid

# 6. RX Path BFM (RX <-> SB)
# add wave -group RX_PATH -position insertpoint  \
  sim:/rp_tb_top/rx_bfm/i_rx_sb_req \
  sim:/rp_tb_top/rx_bfm/i_rx_sb_rsp \
  sim:/rp_tb_top/rx_bfm/i_rx_sb_done \
  sim:/rp_tb_top/rx_bfm/i_rx_encoding \
  sim:/rp_tb_top/rx_bfm/i_rx_data \
  sim:/rp_tb_top/rx_bfm/i_rx_info \
  sim:/rp_tb_top/rx_bfm/o_sb_rx_req \
  sim:/rp_tb_top/rx_bfm/o_sb_rx_rsp \
  sim:/rp_tb_top/rx_bfm/o_sb_rx_done \
  sim:/rp_tb_top/rx_bfm/o_rx_decoding \
  sim:/rp_tb_top/rx_bfm/o_rx_data \
  sim:/rp_tb_top/rx_bfm/o_rx_info \
  sim:/rp_tb_top/rx_bfm/o_rx_valid

# ====================================================================

# .vcop Action toggleleafnames
# wave zoom range 0ns 500ns

# Exclude the assertion module from code coverage
coverage exclude -du rp_sva

# Coverage Save settings (Using unique DB name)
# coverage save $COV_DB -onexit
run -all
# quit -sim

# ── Text: Code coverage - RTL only ───────────────────────────────────────────
# vcover report $COV_DB \
    -details -annotate -code bcefst \
    -output $COV_TXT

# ── Text: Functional coverage ─────────────────────────────────────────────────
# vcover report $COV_DB \
    -details -cvg -directive \
    -output $COV_FUNC_TXT

# ── HTML: Code coverage - RTL only ───────────────────────────────────────────
# vcover report $COV_DB \
    -html \
    -output $COV_CODE_HTML \
    -code bcefst \
    -annotate \
    -details

# ── HTML: Functional coverage ─────────────────────────────────────────────────
# vcover report $COV_DB \
    -html \
    -output $COV_FUNC_HTML \
    -cvg \
    -details

exit