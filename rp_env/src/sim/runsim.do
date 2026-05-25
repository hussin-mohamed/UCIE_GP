vlib work
 vlog ../../../rx_path/LFSR_pattern_generator.sv ../../../rx_path/clk_valid_pattern_detection.sv ../../../rx_path/clk_valid_pattern_detection_tb.sv ../../../rx_path/clock_divider.sv ../../../rx_path/counter_compare.sv ../../../rx_path/demux_1_2.sv ../../../rx_path/deserializer_h.sv ../../../rx_path/deserializer_q.sv ../../../rx_path/fifo.sv ../../../rx_path/lane_id_register.sv ../../../rx_path/mux_2_1.sv ../../../rx_path/per_lane_id_detector.sv ../../../rx_path/per_lane_id_detector_tb.sv ../../../rx_path/per_lane_id_detector_top.svh ../../../rx_path/receivers.sv ../../../rx_path/rx_LFSR.sv ../../../rx_path/rx_LFSR_detection.sv ../../../rx_path/rx_LFSR_tb.svh ../../../rx_path/rx_LFSR_top.sv ../../../rx_path/rx_path.sv ../../../rx_path/synchonizer.sv ../../../rx_path/ucie_lane_to_byte.sv ../../../rx_path/ucie_lane_to_byte_decoder.sv ../../../rx_path/ucie_mux_2_to_1.sv ../../../rx_path/ucie_reordering_block.sv ../../../rx_path/ucie_rx_controller.sv ../../../rx_path/ucie_shift_register.sv +cover +define+SIM
vlog -f src_files.f -mfcu +define+SIM

# Read parameters passed dynamically from the Makefile via environment variables
set TESTNAME    $env(TEST_NAME)
set VERBOSITY   $env(UVM_VERB)
set SEED        $env(SIM_SEED)
set COV_DB      $env(COV_DB_NAME)
set COV_TXT     $env(COV_TXT_NAME)
set COV_FUNC_TXT  $env(COV_FUNC_TXT_NAME)
set COV_FUNC_HTML $env(COV_FUNC_HTML)
set COV_CODE_HTML $env(COV_CODE_HTML)

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
add wave -group Global_Signals -position insertpoint  \
  sim:/rp_tb_top/reset_intf/clk \
  sim:/rp_tb_top/reset_intf/reset

# 2. LTSM Control BFM (Configuration & Status)
add wave -group LTSM_CTRL_BFM -position insertpoint  \
  sim:/rp_tb_top/ltsmc_bfm/i_half_rate \
  sim:/rp_tb_top/ltsmc_bfm/i_rx_encoding \
  sim:/rp_tb_top/ltsmc_bfm/i_lane_map_code \
  sim:/rp_tb_top/ltsmc_bfm/i_error_threshold \
  sim:/rp_tb_top/ltsmc_bfm/o_rx_done \
  sim:/rp_tb_top/ltsmc_bfm/o_clk_result \
  sim:/rp_tb_top/ltsmc_bfm/o_valid_result \
  sim:/rp_tb_top/ltsmc_bfm/o_rx_data_results

# 3. PHY Link BFM (RX Mainband Link / Serial)
add wave -group RMBLINK_BFM -position insertpoint  \
  sim:/rp_tb_top/rmblink_bfm/i_clk_p \
  sim:/rp_tb_top/rmblink_bfm/i_clk_n \
  sim:/rp_tb_top/rmblink_bfm/i_hclk \
  sim:/rp_tb_top/rmblink_bfm/i_dclk \
  sim:/rp_tb_top/rmblink_bfm/i_track \
  sim:/rp_tb_top/rmblink_bfm/i_data \
  sim:/rp_tb_top/rmblink_bfm/i_valid

# 4. RDI BFM (Adapter Layer Output)
add wave -group RDI_BFM -position insertpoint  \
  sim:/rp_tb_top/rdi_bfm/pl_valid \
  sim:/rp_tb_top/rdi_bfm/pl_data

# 5. DUT (RX-Path Top Level Ports & Internal Signals)
add wave -group RX_PATH_DUT -position insertpoint  \
  sim:/rp_tb_top/dut/*

# ====================================================================

.vcop Action toggleleafnames
wave zoom range 0ns 500ns

# Exclude the assertion module from code coverage
coverage exclude -du rp_sva

# Coverage Save settings (Using unique DB name)
coverage save $COV_DB -onexit
run -all
quit -sim

# ── Text: Code coverage - RTL only ───────────────────────────────────────────
vcover report $COV_DB \
    -details -annotate -code bcefst \
    -output $COV_TXT

# ── Text: Functional coverage ─────────────────────────────────────────────────
vcover report $COV_DB \
    -details -cvg -directive \
    -output $COV_FUNC_TXT

# ── HTML: Code coverage - RTL only ───────────────────────────────────────────
vcover report $COV_DB \
    -html \
    -output $COV_CODE_HTML \
    -code bcefst \
    -annotate \
    -details

# ── HTML: Functional coverage ─────────────────────────────────────────────────
vcover report $COV_DB \
    -html \
    -output $COV_FUNC_HTML \
    -cvg \
    -details

exit