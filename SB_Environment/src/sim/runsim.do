vlib work
vlog -f src_files.f -mfcu +cover +define+SIM

# Read parameters passed dynamically from the Makefile via environment variables
set TESTNAME $env(TEST_NAME)
set VERBOSITY $env(UVM_VERB)
set SEED $env(SIM_SEED)

vsim -voptargs=+acc work.sb_tb_top -classdebug -uvmcontrol=all -cover \
    +UVM_VERBOSITY=$VERBOSITY \
    +UVM_NO_RELNOTES \
    +UVM_TESTNAME=$TESTNAME \
    -sv_seed $SEED

set NoQuitOnFinish 1

# ====================================================================
# WAVEFORM GROUPS - Sideband Verification Environment
# ====================================================================

# 1. Global Clock & Reset
add wave -group Global_Signals -position insertpoint  \
  sim:/sb_tb_top/reset_intf/clk \
  sim:/sb_tb_top/reset_intf/reset \
  sim:/sb_tb_top/phylink_bfm/clk_ser

# 2. LTSM Control BFM
add wave -group LTSM_CTRL -position insertpoint  \
  sim:/sb_tb_top/ltsm_ctrl_bfm/i_sb_init_start \
  sim:/sb_tb_top/ltsm_ctrl_bfm/i_timer_1ms \
  sim:/sb_tb_top/ltsm_ctrl_bfm/o_sb_ready

# 3. PHY Link BFM (Serial MDI)
add wave -group PHY_LINK_MDI -position insertpoint  \
  sim:/sb_tb_top/phylink_bfm/i_rx_sb_data \
  sim:/sb_tb_top/phylink_bfm/i_rx_sb_clk \
  sim:/sb_tb_top/phylink_bfm/o_tx_sb_data \
  sim:/sb_tb_top/phylink_bfm/o_tx_sb_clk

# 4. RDI BFM (Adapter <-> SB)
add wave -group RDI_ADAPTER -position insertpoint  \
  sim:/sb_tb_top/rdi_bfm/i_lp_cfg_vld \
  sim:/sb_tb_top/rdi_bfm/i_lp_cfg_crd \
  sim:/sb_tb_top/rdi_bfm/i_lp_cfg \
  sim:/sb_tb_top/rdi_bfm/o_pl_cfg_vld \
  sim:/sb_tb_top/rdi_bfm/o_pl_cfg_crd \
  sim:/sb_tb_top/rdi_bfm/o_pl_cfg

# 5. TX Path BFM (TX <-> SB)
add wave -group TX_PATH -position insertpoint  \
  sim:/sb_tb_top/tx_bfm/i_tx_sb_req \
  sim:/sb_tb_top/tx_bfm/i_tx_sb_rsp \
  sim:/sb_tb_top/tx_bfm/i_tx_sb_done \
  sim:/sb_tb_top/tx_bfm/i_tx_encoding \
  sim:/sb_tb_top/tx_bfm/i_tx_data \
  sim:/sb_tb_top/tx_bfm/i_tx_info \
  sim:/sb_tb_top/tx_bfm/o_sb_tx_req \
  sim:/sb_tb_top/tx_bfm/o_sb_tx_rsp \
  sim:/sb_tb_top/tx_bfm/o_sb_tx_done \
  sim:/sb_tb_top/tx_bfm/o_tx_decoding \
  sim:/sb_tb_top/tx_bfm/o_tx_data \
  sim:/sb_tb_top/tx_bfm/o_tx_info \
  sim:/sb_tb_top/tx_bfm/o_tx_valid

# 6. RX Path BFM (RX <-> SB)
add wave -group RX_PATH -position insertpoint  \
  sim:/sb_tb_top/rx_bfm/i_rx_sb_req \
  sim:/sb_tb_top/rx_bfm/i_rx_sb_rsp \
  sim:/sb_tb_top/rx_bfm/i_rx_sb_done \
  sim:/sb_tb_top/rx_bfm/i_rx_encoding \
  sim:/sb_tb_top/rx_bfm/i_rx_data \
  sim:/sb_tb_top/rx_bfm/i_rx_info \
  sim:/sb_tb_top/rx_bfm/o_sb_rx_req \
  sim:/sb_tb_top/rx_bfm/o_sb_rx_rsp \
  sim:/sb_tb_top/rx_bfm/o_sb_rx_done \
  sim:/sb_tb_top/rx_bfm/o_rx_decoding \
  sim:/sb_tb_top/rx_bfm/o_rx_data \
  sim:/sb_tb_top/rx_bfm/o_rx_info \
  sim:/sb_tb_top/rx_bfm/o_rx_valid

# ====================================================================

.vcop Action toggleleafnames
wave zoom range 0ns 500ns

# Coverage Save settings
coverage save sb_env_cov.ucdb -onexit -du sb_tb_top

run -all

# Coverage Reports
coverage report -detail -cvg -directive -comments -output seqcover_report.txt /.
coverage report -detail -cvg -directive -comments -output fcover_report.txt {}

quit -sim
vcover report sb_env_cov.ucdb -details -annotate -all -output coverage_rpt.txt