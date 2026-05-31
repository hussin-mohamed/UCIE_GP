vlib work
vlog ../../../rx_path/LFSR_pattern_generator.sv ../../../rx_path/clk_valid_pattern_detection.sv ../../../rx_path/clk_valid_pattern_detection_tb.sv ../../../rx_path/clock_divider.sv ../../../rx_path/counter_compare.sv ../../../rx_path/demux_1_2.sv ../../../rx_path/deserializer_h.sv ../../../rx_path/deserializer_q.sv ../../../rx_path/fifo.sv ../../../rx_path/lane_id_register.sv ../../../rx_path/mux_2_1.sv ../../../rx_path/per_lane_id_detector.sv ../../../rx_path/per_lane_id_detector_tb.sv ../../../rx_path/per_lane_id_detector_top.svh ../../../rx_path/receivers.sv ../../../rx_path/rx_LFSR.sv ../../../rx_path/rx_LFSR_detection.sv ../../../rx_path/rx_LFSR_tb.svh ../../../rx_path/rx_LFSR_top.sv ../../../rx_path/rx_path.sv ../../../rx_path/synchonizer.sv ../../../rx_path/ucie_lane_to_byte.sv ../../../rx_path/ucie_lane_to_byte_decoder.sv ../../../rx_path/ucie_mux_2_to_1.sv ../../../rx_path/ucie_reordering_block.sv ../../../rx_path/ucie_rx_controller.sv ../../../rx_path/ucie_shift_register.sv +cover +define+SIM
vlog -f src_files.f -mfcu +define+SIM

# Read parameters passed dynamically from the Makefile via environment variables
set TESTNAME    rp_sanity_all_test
set VERBOSITY   UVM_DEBUG
set SEED        67886097
set COV_DB      out/ucdb/2026-05-30_07-59-35_rp_sanity_all_test_run1.ucdb
set COV_TXT     out/reports/text/2026-05-30_07-59-35_rp_sanity_all_test_run1_code_cov.txt
set COV_FUNC_TXT  out/reports/text/2026-05-30_07-59-35_rp_sanity_all_test_run1_func_cov.txt
set COV_FUNC_HTML out/reports/html/2026-05-30_07-59-35_rp_sanity_all_test_run1_func_html
set COV_CODE_HTML out/reports/html/2026-05-30_07-59-35_rp_sanity_all_test_run1_code_html

vsim -voptargs=+acc -nodpiexports work.rp_tb_top -classdebug -uvmcontrol=all -cover \
    +UVM_VERBOSITY=$VERBOSITY \
    +UVM_NO_RELNOTES \
    +UVM_TESTNAME=$TESTNAME \
    +UVM_TIMEOUT=1000000,YES \
    -sv_seed $SEED

set NoQuitOnFinish 1

# ====================================================================
# WAVEFORM GROUPS - RX-Path Verification Environment
# ====================================================================

# 1. Global Clock & Reset
# add wave -group Global_Signals -position insertpoint  \
 -color Gold sim:/rp_tb_top/reset_intf/clk \
 -color Red  sim:/rp_tb_top/reset_intf/reset

# 2. LTSM Control BFM (Configuration & Status)
# add wave -group LTSM_CTRL_BFM -position insertpoint  \
 sim:/rp_tb_top/ltsmc_bfm/i_half_rate \
 -color Cyan  sim:/rp_tb_top/ltsmc_bfm/i_rx_encoding \
 sim:/rp_tb_top/ltsmc_bfm/i_lane_map_code \
 sim:/rp_tb_top/ltsmc_bfm/i_error_threshold \
 -color Magenta sim:/rp_tb_top/ltsmc_bfm/o_rx_done \
 sim:/rp_tb_top/ltsmc_bfm/o_clk_result \
 sim:/rp_tb_top/ltsmc_bfm/o_valid_result \
 sim:/rp_tb_top/ltsmc_bfm/o_rx_data_results

# 3. PHY Link BFM (RX Mainband Link / Serial)
# add wave -group RMBLINK_BFM -position insertpoint  \
 -color Gold  sim:/rp_tb_top/rmblink_bfm/i_clk_p \
 -color Gold  sim:/rp_tb_top/rmblink_bfm/i_clk_n \
 -color Gold  sim:/rp_tb_top/rmblink_bfm/i_hclk \
 -color Gold  sim:/rp_tb_top/rmblink_bfm/i_dclk \
 sim:/rp_tb_top/rmblink_bfm/i_track \
 sim:/rp_tb_top/rmblink_bfm/i_data \
 -color Magenta sim:/rp_tb_top/rmblink_bfm/i_valid

# 4. RDI BFM (Adapter Layer Output)
# add wave -group RDI_BFM -position insertpoint  \
 -color Magenta sim:/rp_tb_top/rdi_bfm/pl_valid \
 sim:/rp_tb_top/rdi_bfm/pl_data

# 5. DUT (RX-Path Top Level Ports & Internal Signals)
# add wave -group RX_PATH_DUT -position insertpoint  \
 sim:/rp_tb_top/dut/*

run 0ns

# 6. Predictor Internal State
# add wave -group PRD_State -position insertpoint \
 -color Cyan sim:/uvm_test_top/env/sb/prd/current_rx_encoding \
 -color Cyan sim:/uvm_test_top/env/sb/prd/previous_rx_encoding \
 -color Cyan sim:/uvm_test_top/env/sb/prd/t_rx_encoding \
 sim:/uvm_test_top/env/sb/prd/current_lane_map_code \
 sim:/uvm_test_top/env/sb/prd/current_error_threshold \
 sim:/uvm_test_top/env/sb/prd/expected_bit \
 sim:/uvm_test_top/env/sb/prd/l2b_iter_cnt \
 sim:/uvm_test_top/env/sb/prd/per_lane_iter_cnt \
 sim:/uvm_test_top/env/sb/prd/lfsr_train_iter_cnt \
 sim:/uvm_test_top/env/sb/prd/is_d2c_valid_train_state

# add wave -group PRD_Data_Output -position insertpoint \
 -color Gold sim:/uvm_test_top/env/sb/prd/rdi_data_buffer \

# add wave -group PRD_LFSR -position insertpoint \
 -color Red   sim:/uvm_test_top/env/sb/prd/lane_error_count \
 -color Magenta sim:/uvm_test_top/env/sb/prd/success_arr \
 sim:/uvm_test_top/env/sb/prd/lfsr_state \
 sim:/uvm_test_top/env/sb/prd/lfsr_last_state \
 -color Gold sim:/uvm_test_top/env/sb/prd/lfsr_in_data \
 -color Gold sim:/uvm_test_top/env/sb/prd/lfsr_out_data 

# add wave -group Assertions -position insertpoint \
 sim:/rp_tb_top/dut/rp_sva_inst/assert_valid_pattern_16_frame \
 sim:/rp_tb_top/dut/rp_sva_inst/assert_valid_pattern_active_frame \
 sim:/rp_tb_top/dut/rp_sva_inst/assert_valid_pattern_result_check \
 sim:/rp_tb_top/dut/rp_sva_inst/assert_clk_p_pattern_frame \
 sim:/rp_tb_top/dut/rp_sva_inst/assert_clk_n_pattern_frame \
 sim:/rp_tb_top/dut/rp_sva_inst/assert_track_pattern_frame \
 sim:/rp_tb_top/dut/rp_sva_inst/assert_clk_pattern_result_check \
 sim:/rp_tb_top/dut/rp_sva_inst/chk_async_reset_zeros \
 sim:/rp_tb_top/dut/rp_sva_inst/chk_async_reset_ones

 add wave -position insertpoint  \
{sim:/rp_tb_top/dut/LFSR/lane_gen[0]/u_LFSR/gen/pLANE_ID_SEED} \
{sim:/rp_tb_top/dut/LFSR/lane_gen[0]/u_LFSR/gen/pDATA_WIDTH} \
{sim:/rp_tb_top/dut/LFSR/lane_gen[0]/u_LFSR/gen/pclk} \
{sim:/rp_tb_top/dut/LFSR/lane_gen[0]/u_LFSR/gen/i_load} \
{sim:/rp_tb_top/dut/LFSR/lane_gen[0]/u_LFSR/gen/pattern} \
{sim:/rp_tb_top/dut/LFSR/lane_gen[0]/u_LFSR/gen/LFSR} \
{sim:/rp_tb_top/dut/LFSR/lane_gen[0]/u_LFSR/gen/next}
  

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

# exit