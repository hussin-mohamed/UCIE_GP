vlib work
# vlog ../../../RX-Path/* +cover +define+SIM
vlog -f src_files.f -mfcu +define+SIM

# Read parameters passed dynamically from the Makefile via environment variables
set TESTNAME    rp_test_base
set VERBOSITY   UVM_HIGH
set SEED        random
set COV_DB      out/ucdb/2026-05-25_23-12-41_rp_test_base_run1.ucdb
set COV_TXT     out/reports/text/2026-05-25_23-12-41_rp_test_base_run1_code_cov.txt
set COV_FUNC_TXT  out/reports/text/2026-05-25_23-12-41_rp_test_base_run1_func_cov.txt
set COV_FUNC_HTML out/reports/html/2026-05-25_23-12-41_rp_test_base_run1_func_html
set COV_CODE_HTML out/reports/html/2026-05-25_23-12-41_rp_test_base_run1_code_html

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

# ==============================================================================
# UCIe 3.0 RX-Path Verification - Coverage Exclusions
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Source ID & Upper Reserved Padding (Bits 127:118)
# Reason: Bits [127:125] are hardcoded to 3'b010 (Physical Layer enc_srcid).
#         Bits [124:118] map to pRESERVED padding which is permanently tied to 0.
# ------------------------------------------------------------------------------
coverage exclude -togglenode o_msg_out\[127:118\] -du ucie_sideband_tx_msg_enc_dec
coverage exclude -togglenode tx_traffic_fifo_msg\[127:118\] -du ucie_sb_top

# ------------------------------------------------------------------------------
# 2. Message Code MSB (Bit 117)
# Reason: MSB of the 8-bit enc_msg_code. All valid UCIe message codes supported 
#         by this block fit within the lower 7 bits, keeping this MSB tied to 0.
# ------------------------------------------------------------------------------
coverage exclude -togglenode o_msg_out\[117\]    -du ucie_sideband_tx_msg_enc_dec
coverage exclude -togglenode tx_traffic_fifo_msg\[117\]    -du ucie_sb_top

# ------------------------------------------------------------------------------
# 3. Middle Reserved Padding (Bits 109:101)
# Reason: This block corresponds to pRESERVED header padding. The encoder logic 
#         explicitly ties all of these bits to 0.
# ------------------------------------------------------------------------------
coverage exclude -togglenode o_msg_out\[109:101\] -du ucie_sideband_tx_msg_enc_dec
coverage exclude -togglenode tx_traffic_fifo_msg\[109:101\] -du ucie_sb_top

# ------------------------------------------------------------------------------
# 4. Opcode MSB (Bit 100)
# Reason: MSB of the 5-bit enc_op_code. Valid operation codes generated here 
#         (e.g., 'b10000, 'b10010, 'b10101) always have the MSB set to 1.
# ------------------------------------------------------------------------------
coverage exclude -togglenode o_msg_out\[100\]    -du ucie_sideband_tx_msg_enc_dec
coverage exclude -togglenode tx_traffic_fifo_msg\[100\]    -du ucie_sb_top

# ------------------------------------------------------------------------------
# 5. Hardcoded Header Zeroes (Bits 98:97)
# Reason: In the o_msg_out concatenation, two 1'b0 bits are explicitly hardcoded 
#         immediately following the operation code.
# ------------------------------------------------------------------------------
coverage exclude -togglenode o_msg_out\[98:97\]  -du ucie_sideband_tx_msg_enc_dec
coverage exclude -togglenode tx_traffic_fifo_msg\[98:97\]  -du ucie_sb_top

# ------------------------------------------------------------------------------
# 6. Destination ID & Lower Reserved Padding (Bits 93:88)
# Reason: Bits [90:88] are statically assigned to 3'b110 (Remote Die enc_dstid).
#         Bits [93:91] are pRESERVED padding tied to 0.
# ------------------------------------------------------------------------------
coverage exclude -togglenode o_msg_out\[93:88\]  -du ucie_sideband_tx_msg_enc_dec
coverage exclude -togglenode tx_traffic_fifo_msg\[93:88\]  -du ucie_sb_top

# ------------------------------------------------------------------------------
# 7. TX Traffic FIFO Backpressure / Full Conditions
# Reason: Unreachable state. The LTSM protocol enforces a strict send-and-wait 
#         (ping-pong) mechanism. A new request is never sent until the previous 
#         response is received, making it physically impossible for the 32-depth 
#         TX FIFO to ever fill up and trigger these stall conditions.
# ------------------------------------------------------------------------------
coverage exclude -du ucie_sideband_traffic_fifo -fstate state ST_WAIT_FULL
coverage exclude -togglenode o_stall_traffic -du ucie_sideband_traffic_fifo
coverage exclude -togglenode con_full        -du ucie_sideband_traffic_fifo

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