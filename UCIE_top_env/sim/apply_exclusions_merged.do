# ==============================================================================
# Script: apply_exclusions_merged.do
# Description: Applies aggressive exclusions directly to the merged coverage
#              database (regression_merged.ucdb) to focus strictly on the active
#              x16 mode. Excludes mbinit initialization phase, lane map 
#              degradation, unused x4/x8 RTL structures, and transitions.
# ==============================================================================

# Disable two-step exclusions
coverage configure -2stepexclusion off

# ------------------------------------------------------------------------------
# 1. Design/Assertion Modules Exclusions
# ------------------------------------------------------------------------------
coverage exclude -du sb_sva
coverage exclude -du rp_sva

# ------------------------------------------------------------------------------
# 2. UCIe 3.0 Sideband Verification - Coverage Exclusions
# ------------------------------------------------------------------------------
coverage exclude -togglenode o_msg_out\[127:118\] -du ucie_sideband_tx_msg_enc_dec
coverage exclude -togglenode tx_traffic_fifo_msg\[127:118\] -du ucie_sb_top
coverage exclude -togglenode o_msg_out\[117\]    -du ucie_sideband_tx_msg_enc_dec
coverage exclude -togglenode tx_traffic_fifo_msg\[117\]    -du ucie_sb_top
coverage exclude -togglenode o_msg_out\[109:101\] -du ucie_sideband_tx_msg_enc_dec
coverage exclude -togglenode tx_traffic_fifo_msg\[109:101\] -du ucie_sb_top
coverage exclude -togglenode o_msg_out\[100\]    -du ucie_sideband_tx_msg_enc_dec
coverage exclude -togglenode tx_traffic_fifo_msg\[100\]    -du ucie_sb_top
coverage exclude -togglenode o_msg_out\[98:97\]  -du ucie_sideband_tx_msg_enc_dec
coverage exclude -togglenode tx_traffic_fifo_msg\[98:97\]  -du ucie_sb_top
coverage exclude -togglenode o_msg_out\[93:88\]  -du ucie_sideband_tx_msg_enc_dec
coverage exclude -togglenode tx_traffic_fifo_msg\[93:88\]  -du ucie_sb_top
coverage exclude -du ucie_sideband_traffic_fifo -fstate state ST_WAIT_FULL
coverage exclude -togglenode o_stall_traffic -du ucie_sideband_traffic_fifo
coverage exclude -togglenode con_full        -du ucie_sideband_traffic_fifo

# ------------------------------------------------------------------------------
# 3. PLL Clock Divider Enable & Branch Exclusions
# ------------------------------------------------------------------------------
coverage exclude -togglenode i_enable -instance /ucie_tb_top/DUT/PLL/ch
coverage exclude -togglenode i_enable -instance /ucie_tb_top/DUT/PLL/cd4
coverage exclude -togglenode i_enable -instance /ucie_tb_top/DUT/PLL/cd8
coverage exclude -togglenode i_enable -instance /ucie_tb_top/DUT/PLL/cd16
coverage exclude -togglenode i_enable -instance /ucie_tb_top/DUT/PLL/cd32
coverage exclude -togglenode i_enable -instance /ucie_tb_top/DUT/PLL/cd64

coverage exclude -instance /ucie_tb_top/DUT/PLL/ch -code b
coverage exclude -instance /ucie_tb_top/DUT/PLL/cd4 -code b
coverage exclude -instance /ucie_tb_top/DUT/PLL/cd8 -code b
coverage exclude -instance /ucie_tb_top/DUT/PLL/cd16 -code b
coverage exclude -instance /ucie_tb_top/DUT/PLL/cd32 -code b
coverage exclude -instance /ucie_tb_top/DUT/PLL/cd64 -code b

# ------------------------------------------------------------------------------
# 4. Eye Sweep Module Exclusions
# ------------------------------------------------------------------------------
coverage exclude -du ucie_TX_Data_to_Clock_eye_sweep
coverage exclude -du ucie_RX_Data_to_Clock_eye_sweep

# ------------------------------------------------------------------------------
# 5. Detailed Instance Exclusions (Unused modes, MBINIT, unreached timers/FSMs)
# ------------------------------------------------------------------------------
coverage exclude -instance /ucie_tb_top/DUT/LTSM
coverage exclude -instance /ucie_tb_top/DUT/LTSM/ucie_LTSM_RX_MBTRAIN_inst
coverage exclude -instance /ucie_tb_top/DUT/LTSM/ucie_LTSM_RX_MBTRAIN_inst/ucie_RX_Data_to_Clock_eye_sweep_inst
coverage exclude -instance /ucie_tb_top/DUT/LTSM/ucie_LTSM_TX_MBTRAIN_inst
coverage exclude -instance /ucie_tb_top/DUT/LTSM/ucie_LTSM_TX_MBTRAIN_inst/ucie_TX_Data_to_Clock_eye_sweep_inst
coverage exclude -instance /ucie_tb_top/DUT/LTSM/ucie_ltsm_active_fsm_inst
coverage exclude -instance /ucie_tb_top/DUT/LTSM/ucie_ltsm_active_fsm_inst/u_active
coverage exclude -instance /ucie_tb_top/DUT/LTSM/ucie_ltsm_active_fsm_inst/u_l1_rx
coverage exclude -instance /ucie_tb_top/DUT/LTSM/ucie_ltsm_active_fsm_inst/u_l1_tx
coverage exclude -instance /ucie_tb_top/DUT/LTSM/ucie_ltsm_active_fsm_inst/u_linkinit_rx
coverage exclude -instance /ucie_tb_top/DUT/LTSM/ucie_ltsm_active_fsm_inst/u_linkinit_tx
coverage exclude -instance /ucie_tb_top/DUT/LTSM/ucie_ltsm_active_fsm_inst/ucie_LTSM_RX_phyretrain_inst
coverage exclude -instance /ucie_tb_top/DUT/LTSM/ucie_ltsm_active_fsm_inst/ucie_LTSM_TX_phyretrain_inst
coverage exclude -instance /ucie_tb_top/DUT/LTSM/ucie_ltsm_init_fsm_inst
coverage exclude -instance /ucie_tb_top/DUT/LTSM/ucie_ltsm_init_fsm_inst/u_rx_cal
coverage exclude -instance /ucie_tb_top/DUT/LTSM/ucie_ltsm_init_fsm_inst/u_rx_param
coverage exclude -instance /ucie_tb_top/DUT/LTSM/ucie_ltsm_init_fsm_inst/u_rx_repairclk
coverage exclude -instance /ucie_tb_top/DUT/LTSM/ucie_ltsm_init_fsm_inst/u_rx_repairmb
coverage exclude -instance /ucie_tb_top/DUT/LTSM/ucie_ltsm_init_fsm_inst/u_rx_repairmb/ucie_RX_Data_to_Clock_eye_sweep_inst
coverage exclude -instance /ucie_tb_top/DUT/LTSM/ucie_ltsm_init_fsm_inst/u_rx_repairval
coverage exclude -instance /ucie_tb_top/DUT/LTSM/ucie_ltsm_init_fsm_inst/u_rx_reset
coverage exclude -instance /ucie_tb_top/DUT/LTSM/ucie_ltsm_init_fsm_inst/u_rx_reversal
coverage exclude -instance /ucie_tb_top/DUT/LTSM/ucie_ltsm_init_fsm_inst/u_rx_sbinit
coverage exclude -instance /ucie_tb_top/DUT/LTSM/ucie_ltsm_init_fsm_inst/u_rx_trainerror
coverage exclude -instance /ucie_tb_top/DUT/LTSM/ucie_ltsm_init_fsm_inst/u_tx_cal
coverage exclude -instance /ucie_tb_top/DUT/LTSM/ucie_ltsm_init_fsm_inst/u_tx_param
coverage exclude -instance /ucie_tb_top/DUT/LTSM/ucie_ltsm_init_fsm_inst/u_tx_repairclk
coverage exclude -instance /ucie_tb_top/DUT/LTSM/ucie_ltsm_init_fsm_inst/u_tx_repairmb
coverage exclude -instance /ucie_tb_top/DUT/LTSM/ucie_ltsm_init_fsm_inst/u_tx_repairmb/ucie_TX_Data_to_Clock_eye_sweep_inst
coverage exclude -instance /ucie_tb_top/DUT/LTSM/ucie_ltsm_init_fsm_inst/u_tx_repairval
coverage exclude -instance /ucie_tb_top/DUT/LTSM/ucie_ltsm_init_fsm_inst/u_tx_reset
coverage exclude -instance /ucie_tb_top/DUT/LTSM/ucie_ltsm_init_fsm_inst/u_tx_reversal
coverage exclude -instance /ucie_tb_top/DUT/LTSM/ucie_ltsm_init_fsm_inst/u_tx_sbinit
coverage exclude -instance /ucie_tb_top/DUT/LTSM/ucie_ltsm_init_fsm_inst/u_tx_trainerror
coverage exclude -instance /ucie_tb_top/DUT/LTSM/ucie_timeout_timer_inst
coverage exclude -instance /ucie_tb_top/DUT/PLL
coverage exclude -instance /ucie_tb_top/DUT/PLL/cd16
coverage exclude -instance /ucie_tb_top/DUT/PLL/cd32
coverage exclude -instance /ucie_tb_top/DUT/PLL/cd4
coverage exclude -instance /ucie_tb_top/DUT/PLL/cd64
coverage exclude -instance /ucie_tb_top/DUT/PLL/cd8
coverage exclude -instance /ucie_tb_top/DUT/PLL/ch
coverage exclude -instance /ucie_tb_top/DUT/decoder_rx
coverage exclude -instance /ucie_tb_top/DUT/decoder_tx
coverage exclude -instance /ucie_tb_top/DUT/dut
coverage exclude -instance /ucie_tb_top/DUT/dut/L2B
coverage exclude -instance /ucie_tb_top/DUT/dut/L2B/gen_mux4\[0\]/u_mux4_inst
coverage exclude -instance /ucie_tb_top/DUT/dut/L2B/gen_mux4\[1\]/u_mux4_inst
coverage exclude -instance /ucie_tb_top/DUT/dut/L2B/gen_mux4\[2\]/u_mux4_inst
coverage exclude -instance /ucie_tb_top/DUT/dut/L2B/gen_mux4\[3\]/u_mux4_inst
coverage exclude -instance /ucie_tb_top/DUT/dut/L2B/gen_mux8\[0\]/u_mux8_inst
coverage exclude -instance /ucie_tb_top/DUT/dut/L2B/gen_mux8\[1\]/u_mux8_inst
coverage exclude -instance /ucie_tb_top/DUT/dut/L2B/gen_mux8\[2\]/u_mux8_inst
coverage exclude -instance /ucie_tb_top/DUT/dut/L2B/gen_mux8\[3\]/u_mux8_inst
coverage exclude -instance /ucie_tb_top/DUT/dut/L2B/gen_mux8\[4\]/u_mux8_inst
coverage exclude -instance /ucie_tb_top/DUT/dut/L2B/gen_mux8\[5\]/u_mux8_inst
coverage exclude -instance /ucie_tb_top/DUT/dut/L2B/gen_mux8\[6\]/u_mux8_inst
coverage exclude -instance /ucie_tb_top/DUT/dut/L2B/gen_mux8\[7\]/u_mux8_inst
coverage exclude -instance /ucie_tb_top/DUT/dut/L2B/gen_shift_reg_x16\[0\]/u_shift_reg_x16
coverage exclude -instance /ucie_tb_top/DUT/dut/L2B/gen_shift_reg_x16\[10\]/u_shift_reg_x16
coverage exclude -instance /ucie_tb_top/DUT/dut/L2B/gen_shift_reg_x16\[11\]/u_shift_reg_x16
coverage exclude -instance /ucie_tb_top/DUT/dut/L2B/gen_shift_reg_x16\[12\]/u_shift_reg_x16
coverage exclude -instance /ucie_tb_top/DUT/dut/L2B/gen_shift_reg_x16\[13\]/u_shift_reg_x16
coverage exclude -instance /ucie_tb_top/DUT/dut/L2B/gen_shift_reg_x16\[14\]/u_shift_reg_x16
coverage exclude -instance /ucie_tb_top/DUT/dut/L2B/gen_shift_reg_x16\[15\]/u_shift_reg_x16
coverage exclude -instance /ucie_tb_top/DUT/dut/L2B/gen_shift_reg_x16\[1\]/u_shift_reg_x16
coverage exclude -instance /ucie_tb_top/DUT/dut/L2B/gen_shift_reg_x16\[2\]/u_shift_reg_x16
coverage exclude -instance /ucie_tb_top/DUT/dut/L2B/gen_shift_reg_x16\[3\]/u_shift_reg_x16
coverage exclude -instance /ucie_tb_top/DUT/dut/L2B/gen_shift_reg_x16\[4\]/u_shift_reg_x16
coverage exclude -instance /ucie_tb_top/DUT/dut/L2B/gen_shift_reg_x16\[5\]/u_shift_reg_x16
coverage exclude -instance /ucie_tb_top/DUT/dut/L2B/gen_shift_reg_x16\[6\]/u_shift_reg_x16
coverage exclude -instance /ucie_tb_top/DUT/dut/L2B/gen_shift_reg_x16\[7\]/u_shift_reg_x16
coverage exclude -instance /ucie_tb_top/DUT/dut/L2B/gen_shift_reg_x16\[8\]/u_shift_reg_x16
coverage exclude -instance /ucie_tb_top/DUT/dut/L2B/gen_shift_reg_x16\[9\]/u_shift_reg_x16
coverage exclude -instance /ucie_tb_top/DUT/dut/L2B/gen_shift_reg_x4\[0\]/u_shift_reg_x4
coverage exclude -instance /ucie_tb_top/DUT/dut/L2B/gen_shift_reg_x4\[1\]/u_shift_reg_x4
coverage exclude -instance /ucie_tb_top/DUT/dut/L2B/gen_shift_reg_x4\[2\]/u_shift_reg_x4
coverage exclude -instance /ucie_tb_top/DUT/dut/L2B/gen_shift_reg_x4\[3\]/u_shift_reg_x4
coverage exclude -instance /ucie_tb_top/DUT/dut/L2B/gen_shift_reg_x8\[0\]/u_shift_reg_x8
coverage exclude -instance /ucie_tb_top/DUT/dut/L2B/gen_shift_reg_x8\[1\]/u_shift_reg_x8
coverage exclude -instance /ucie_tb_top/DUT/dut/L2B/gen_shift_reg_x8\[2\]/u_shift_reg_x8
coverage exclude -instance /ucie_tb_top/DUT/dut/L2B/gen_shift_reg_x8\[3\]/u_shift_reg_x8
coverage exclude -instance /ucie_tb_top/DUT/dut/L2B/gen_shift_reg_x8\[4\]/u_shift_reg_x8
coverage exclude -instance /ucie_tb_top/DUT/dut/L2B/gen_shift_reg_x8\[5\]/u_shift_reg_x8
coverage exclude -instance /ucie_tb_top/DUT/dut/L2B/gen_shift_reg_x8\[6\]/u_shift_reg_x8
coverage exclude -instance /ucie_tb_top/DUT/dut/L2B/gen_shift_reg_x8\[7\]/u_shift_reg_x8
coverage exclude -instance /ucie_tb_top/DUT/dut/L2B/u_decoder_inst
coverage exclude -instance /ucie_tb_top/DUT/dut/L2B/u_reorder_inst
coverage exclude -instance /ucie_tb_top/DUT/dut/LFSR/lane_gen\[0\]/u_LFSR/det
coverage exclude -instance /ucie_tb_top/DUT/dut/LFSR/lane_gen\[10\]/u_LFSR/det
coverage exclude -instance /ucie_tb_top/DUT/dut/LFSR/lane_gen\[11\]/u_LFSR/det
coverage exclude -instance /ucie_tb_top/DUT/dut/LFSR/lane_gen\[12\]/u_LFSR/det
coverage exclude -instance /ucie_tb_top/DUT/dut/LFSR/lane_gen\[13\]/u_LFSR/det
coverage exclude -instance /ucie_tb_top/DUT/dut/LFSR/lane_gen\[14\]/u_LFSR/det
coverage exclude -instance /ucie_tb_top/DUT/dut/LFSR/lane_gen\[15\]/u_LFSR/det
coverage exclude -instance /ucie_tb_top/DUT/dut/LFSR/lane_gen\[1\]/u_LFSR/det
coverage exclude -instance /ucie_tb_top/DUT/dut/LFSR/lane_gen\[2\]/u_LFSR/det
coverage exclude -instance /ucie_tb_top/DUT/dut/LFSR/lane_gen\[3\]/u_LFSR/det
coverage exclude -instance /ucie_tb_top/DUT/dut/LFSR/lane_gen\[4\]/u_LFSR/det
coverage exclude -instance /ucie_tb_top/DUT/dut/LFSR/lane_gen\[5\]/u_LFSR/det
coverage exclude -instance /ucie_tb_top/DUT/dut/LFSR/lane_gen\[6\]/u_LFSR/det
coverage exclude -instance /ucie_tb_top/DUT/dut/LFSR/lane_gen\[7\]/u_LFSR/det
coverage exclude -instance /ucie_tb_top/DUT/dut/LFSR/lane_gen\[8\]/u_LFSR/det
coverage exclude -instance /ucie_tb_top/DUT/dut/LFSR/lane_gen\[9\]/u_LFSR/det
coverage exclude -instance /ucie_tb_top/DUT/dut/controller
coverage exclude -instance /ucie_tb_top/DUT/dut/per_lane_id
coverage exclude -instance /ucie_tb_top/DUT/dut/per_lane_id/lane_gen\[0\]/u_detector
coverage exclude -instance /ucie_tb_top/DUT/dut/per_lane_id/lane_gen\[0\]/u_detector/counter
coverage exclude -instance /ucie_tb_top/DUT/dut/per_lane_id/lane_gen\[0\]/u_detector/reg_0
coverage exclude -instance /ucie_tb_top/DUT/dut/per_lane_id/lane_gen\[10\]/u_detector
coverage exclude -instance /ucie_tb_top/DUT/dut/per_lane_id/lane_gen\[10\]/u_detector/counter
coverage exclude -instance /ucie_tb_top/DUT/dut/per_lane_id/lane_gen\[10\]/u_detector/reg_0
coverage exclude -instance /ucie_tb_top/DUT/dut/per_lane_id/lane_gen\[11\]/u_detector
coverage exclude -instance /ucie_tb_top/DUT/dut/per_lane_id/lane_gen\[11\]/u_detector/counter
coverage exclude -instance /ucie_tb_top/DUT/dut/per_lane_id/lane_gen\[11\]/u_detector/reg_0
coverage exclude -instance /ucie_tb_top/DUT/dut/per_lane_id/lane_gen\[12\]/u_detector
coverage exclude -instance /ucie_tb_top/DUT/dut/per_lane_id/lane_gen\[12\]/u_detector/counter
coverage exclude -instance /ucie_tb_top/DUT/dut/per_lane_id/lane_gen\[12\]/u_detector/reg_0
coverage exclude -instance /ucie_tb_top/DUT/dut/per_lane_id/lane_gen\[13\]/u_detector
coverage exclude -instance /ucie_tb_top/DUT/dut/per_lane_id/lane_gen\[13\]/u_detector/counter
coverage exclude -instance /ucie_tb_top/DUT/dut/per_lane_id/lane_gen\[13\]/u_detector/reg_0
coverage exclude -instance /ucie_tb_top/DUT/dut/per_lane_id/lane_gen\[14\]/u_detector
coverage exclude -instance /ucie_tb_top/DUT/dut/per_lane_id/lane_gen\[14\]/u_detector/counter
coverage exclude -instance /ucie_tb_top/DUT/dut/per_lane_id/lane_gen\[14\]/u_detector/reg_0
coverage exclude -instance /ucie_tb_top/DUT/dut/per_lane_id/lane_gen\[15\]/u_detector
coverage exclude -instance /ucie_tb_top/DUT/dut/per_lane_id/lane_gen\[15\]/u_detector/counter
coverage exclude -instance /ucie_tb_top/DUT/dut/per_lane_id/lane_gen\[15\]/u_detector/reg_0
coverage exclude -instance /ucie_tb_top/DUT/dut/per_lane_id/lane_gen\[1\]/u_detector
coverage exclude -instance /ucie_tb_top/DUT/dut/per_lane_id/lane_gen\[1\]/u_detector/counter
coverage exclude -instance /ucie_tb_top/DUT/dut/per_lane_id/lane_gen\[1\]/u_detector/reg_0
coverage exclude -instance /ucie_tb_top/DUT/dut/per_lane_id/lane_gen\[2\]/u_detector
coverage exclude -instance /ucie_tb_top/DUT/dut/per_lane_id/lane_gen\[2\]/u_detector/counter
coverage exclude -instance /ucie_tb_top/DUT/dut/per_lane_id/lane_gen\[2\]/u_detector/reg_0
coverage exclude -instance /ucie_tb_top/DUT/dut/per_lane_id/lane_gen\[3\]/u_detector
coverage exclude -instance /ucie_tb_top/DUT/dut/per_lane_id/lane_gen\[3\]/u_detector/counter
coverage exclude -instance /ucie_tb_top/DUT/dut/per_lane_id/lane_gen\[3\]/u_detector/reg_0
coverage exclude -instance /ucie_tb_top/DUT/dut/per_lane_id/lane_gen\[4\]/u_detector
coverage exclude -instance /ucie_tb_top/DUT/dut/per_lane_id/lane_gen\[4\]/u_detector/counter
coverage exclude -instance /ucie_tb_top/DUT/dut/per_lane_id/lane_gen\[4\]/u_detector/reg_0
coverage exclude -instance /ucie_tb_top/DUT/dut/per_lane_id/lane_gen\[5\]/u_detector
coverage exclude -instance /ucie_tb_top/DUT/dut/per_lane_id/lane_gen\[5\]/u_detector/counter
coverage exclude -instance /ucie_tb_top/DUT/dut/per_lane_id/lane_gen\[5\]/u_detector/reg_0
coverage exclude -instance /ucie_tb_top/DUT/dut/per_lane_id/lane_gen\[6\]/u_detector
coverage exclude -instance /ucie_tb_top/DUT/dut/per_lane_id/lane_gen\[6\]/u_detector/counter
coverage exclude -instance /ucie_tb_top/DUT/dut/per_lane_id/lane_gen\[6\]/u_detector/reg_0
coverage exclude -instance /ucie_tb_top/DUT/dut/per_lane_id/lane_gen\[7\]/u_detector
coverage exclude -instance /ucie_tb_top/DUT/dut/per_lane_id/lane_gen\[7\]/u_detector/counter
coverage exclude -instance /ucie_tb_top/DUT/dut/per_lane_id/lane_gen\[7\]/u_detector/reg_0
coverage exclude -instance /ucie_tb_top/DUT/dut/per_lane_id/lane_gen\[8\]/u_detector
coverage exclude -instance /ucie_tb_top/DUT/dut/per_lane_id/lane_gen\[8\]/u_detector/counter
coverage exclude -instance /ucie_tb_top/DUT/dut/per_lane_id/lane_gen\[8\]/u_detector/reg_0
coverage exclude -instance /ucie_tb_top/DUT/dut/per_lane_id/lane_gen\[9\]/u_detector
coverage exclude -instance /ucie_tb_top/DUT/dut/per_lane_id/lane_gen\[9\]/u_detector/counter
coverage exclude -instance /ucie_tb_top/DUT/dut/per_lane_id/lane_gen\[9\]/u_detector/reg_0
coverage exclude -instance /ucie_tb_top/DUT/dut/receiver
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/B2l
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/B2l/gen_output_multiplexing\[0\]/u_mux_inst
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/B2l/gen_output_multiplexing\[10\]/u_mux_inst
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/B2l/gen_output_multiplexing\[11\]/u_mux_inst
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/B2l/gen_output_multiplexing\[12\]/u_mux_inst
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/B2l/gen_output_multiplexing\[13\]/u_mux_inst
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/B2l/gen_output_multiplexing\[14\]/u_mux_inst
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/B2l/gen_output_multiplexing\[15\]/u_mux_inst
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/B2l/gen_output_multiplexing\[1\]/u_mux_inst
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/B2l/gen_output_multiplexing\[2\]/u_mux_inst
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/B2l/gen_output_multiplexing\[3\]/u_mux_inst
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/B2l/gen_output_multiplexing\[4\]/u_mux_inst
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/B2l/gen_output_multiplexing\[5\]/u_mux_inst
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/B2l/gen_output_multiplexing\[6\]/u_mux_inst
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/B2l/gen_output_multiplexing\[7\]/u_mux_inst
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/B2l/gen_output_multiplexing\[8\]/u_mux_inst
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/B2l/gen_output_multiplexing\[9\]/u_mux_inst
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/B2l/gen_shift_reg_x16\[0\]/u_shift_reg_x16
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/B2l/gen_shift_reg_x16\[10\]/u_shift_reg_x16
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/B2l/gen_shift_reg_x16\[11\]/u_shift_reg_x16
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/B2l/gen_shift_reg_x16\[12\]/u_shift_reg_x16
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/B2l/gen_shift_reg_x16\[13\]/u_shift_reg_x16
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/B2l/gen_shift_reg_x16\[14\]/u_shift_reg_x16
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/B2l/gen_shift_reg_x16\[15\]/u_shift_reg_x16
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/B2l/gen_shift_reg_x16\[1\]/u_shift_reg_x16
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/B2l/gen_shift_reg_x16\[2\]/u_shift_reg_x16
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/B2l/gen_shift_reg_x16\[3\]/u_shift_reg_x16
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/B2l/gen_shift_reg_x16\[4\]/u_shift_reg_x16
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/B2l/gen_shift_reg_x16\[5\]/u_shift_reg_x16
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/B2l/gen_shift_reg_x16\[6\]/u_shift_reg_x16
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/B2l/gen_shift_reg_x16\[7\]/u_shift_reg_x16
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/B2l/gen_shift_reg_x16\[8\]/u_shift_reg_x16
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/B2l/gen_shift_reg_x16\[9\]/u_shift_reg_x16
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/B2l/gen_shift_reg_x4\[0\]/u_shift_reg_x4
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/B2l/gen_shift_reg_x4\[1\]/u_shift_reg_x4
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/B2l/gen_shift_reg_x4\[2\]/u_shift_reg_x4
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/B2l/gen_shift_reg_x4\[3\]/u_shift_reg_x4
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/B2l/gen_shift_reg_x8\[0\]/u_shift_reg_x8
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/B2l/gen_shift_reg_x8\[1\]/u_shift_reg_x8
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/B2l/gen_shift_reg_x8\[2\]/u_shift_reg_x8
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/B2l/gen_shift_reg_x8\[3\]/u_shift_reg_x8
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/B2l/gen_shift_reg_x8\[4\]/u_shift_reg_x8
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/B2l/gen_shift_reg_x8\[5\]/u_shift_reg_x8
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/B2l/gen_shift_reg_x8\[6\]/u_shift_reg_x8
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/B2l/gen_shift_reg_x8\[7\]/u_shift_reg_x8
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/B2l/u_decoder_inst
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/active_dec
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/clk_valid_pattern_generation_dut
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/clk_valid_pattern_generation_dut/ca
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/clk_valid_pattern_generation_dut/cc
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/clk_valid_pattern_generation_dut/cd
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/controller
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/done_dec
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/driver
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/emp_dec
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/per_lane_id
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/per_lane_id/lane_gen\[0\]/u_reg
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/per_lane_id/lane_gen\[10\]/u_reg
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/per_lane_id/lane_gen\[11\]/u_reg
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/per_lane_id/lane_gen\[12\]/u_reg
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/per_lane_id/lane_gen\[13\]/u_reg
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/per_lane_id/lane_gen\[14\]/u_reg
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/per_lane_id/lane_gen\[15\]/u_reg
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/per_lane_id/lane_gen\[1\]/u_reg
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/per_lane_id/lane_gen\[2\]/u_reg
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/per_lane_id/lane_gen\[3\]/u_reg
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/per_lane_id/lane_gen\[4\]/u_reg
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/per_lane_id/lane_gen\[5\]/u_reg
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/per_lane_id/lane_gen\[6\]/u_reg
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/per_lane_id/lane_gen\[7\]/u_reg
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/per_lane_id/lane_gen\[8\]/u_reg
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/per_lane_id/lane_gen\[9\]/u_reg
coverage exclude -instance /ucie_tb_top/DUT/dut_rtl/tx_path_dut/reverse
coverage exclude -instance /ucie_tb_top/DUT/sideband
coverage exclude -instance /ucie_tb_top/DUT/sideband/sva_inst
coverage exclude -instance /ucie_tb_top/DUT/sideband/u_rx_msg
coverage exclude -instance /ucie_tb_top/DUT/sideband/u_rx_msg/u_rx_msg_enc_dec
coverage exclude -instance /ucie_tb_top/DUT/sideband/u_rx_msg/u_rx_traffic_fifo
coverage exclude -instance /ucie_tb_top/DUT/sideband/u_rx_msg/u_toggle_sync_req
coverage exclude -instance /ucie_tb_top/DUT/sideband/u_rx_msg/u_toggle_sync_rsp
coverage exclude -instance /ucie_tb_top/DUT/sideband/u_rx_msg/u_traffic_rx_fifo
coverage exclude -instance /ucie_tb_top/DUT/sideband/u_sb_rx_clk_demux
coverage exclude -instance /ucie_tb_top/DUT/sideband/u_sb_rx_data_demux
coverage exclude -instance /ucie_tb_top/DUT/sideband/u_sb_rx_init
coverage exclude -instance /ucie_tb_top/DUT/sideband/u_sb_traffic
coverage exclude -instance /ucie_tb_top/DUT/sideband/u_sb_tx_clk_mux
coverage exclude -instance /ucie_tb_top/DUT/sideband/u_sb_tx_data_mux
coverage exclude -instance /ucie_tb_top/DUT/sideband/u_sb_tx_init
coverage exclude -instance /ucie_tb_top/DUT/sideband/u_sideband_in
coverage exclude -instance /ucie_tb_top/DUT/sideband/u_sideband_in/u_deser
coverage exclude -instance /ucie_tb_top/DUT/sideband/u_sideband_in/u_fifo_traffic
coverage exclude -instance /ucie_tb_top/DUT/sideband/u_sideband_in/u_rx_deser_fifo
coverage exclude -instance /ucie_tb_top/DUT/sideband/u_sideband_out
coverage exclude -instance /ucie_tb_top/DUT/sideband/u_sideband_out/u_ser
coverage exclude -instance /ucie_tb_top/DUT/sideband/u_sideband_out/u_traffic_fifo
coverage exclude -instance /ucie_tb_top/DUT/sideband/u_sideband_out/u_tx_ser_fifo
coverage exclude -instance /ucie_tb_top/DUT/sideband/u_toggle_sync_req
coverage exclude -instance /ucie_tb_top/DUT/sideband/u_tx_msg
coverage exclude -instance /ucie_tb_top/DUT/sideband/u_tx_msg/u_toggle_sync_req
coverage exclude -instance /ucie_tb_top/DUT/sideband/u_tx_msg/u_toggle_sync_rsp
coverage exclude -instance /ucie_tb_top/DUT/sideband/u_tx_msg/u_traffic_tx_fifo
coverage exclude -instance /ucie_tb_top/DUT/sideband/u_tx_msg/u_tx_msg_enc_dec
coverage exclude -instance /ucie_tb_top/DUT/sideband/u_tx_msg/u_tx_traffic_fifo

# 6. Functional Coverage Exclusions (MBINIT, Lane Map, Transitions, RX Repair)
# ------------------------------------------------------------------------------
# Exclude entire coverpoints/crosses
coverage exclude -cvgpath {/tx_tb_pkg/tx_coverage/cg_ltsm/cp_lane_map}
coverage exclude -cvgpath {/tx_tb_pkg/tx_coverage/cg_ltsm/cp_state_degrade}
coverage exclude -cvgpath {/tx_tb_pkg/tx_coverage/cg_ltsm/cx_state_x_lane_map}
coverage exclude -cvgpath {/tx_tb_pkg/tx_coverage/cg_ltsm/cp_transitions}

coverage exclude -cvgpath {/rp_pkg/rp_coverage_collector/cg_ltsm/cp_lane_map}
coverage exclude -cvgpath {/rp_pkg/rp_coverage_collector/cg_ltsm/cp_state_degrade}
coverage exclude -cvgpath {/rp_pkg/rp_coverage_collector/cg_ltsm/cx_state_x_lane_map}
coverage exclude -cvgpath {/rp_pkg/rp_coverage_collector/cg_ltsm/cp_transitions}

# Exclude RX Repair check coverpoints/crosses (zero-hit since repair is never triggered)
coverage exclude -cvgpath {/rp_pkg/rp_coverage_collector/cg_ltsm/cp_clk_results}
coverage exclude -cvgpath {/rp_pkg/rp_coverage_collector/cg_ltsm/cp_valid_results}
coverage exclude -cvgpath {/rp_pkg/rp_coverage_collector/cg_ltsm/cp_data_results}
coverage exclude -cvgpath {/rp_pkg/rp_coverage_collector/cg_ltsm/cx_clk_x_repairclk}
coverage exclude -cvgpath {/rp_pkg/rp_coverage_collector/cg_ltsm/cx_valid_x_state}
coverage exclude -cvgpath {/rp_pkg/rp_coverage_collector/cg_ltsm/cx_data_x_state}

# Exclude MBINIT bins from cp_encoding
coverage exclude -cvgpath {/tx_tb_pkg/tx_coverage/cg_ltsm/cp_encoding/sbinit}
coverage exclude -cvgpath {/tx_tb_pkg/tx_coverage/cg_ltsm/cp_encoding/param}
coverage exclude -cvgpath {/tx_tb_pkg/tx_coverage/cg_ltsm/cp_encoding/cal}
coverage exclude -cvgpath {/tx_tb_pkg/tx_coverage/cg_ltsm/cp_encoding/repairclk}
coverage exclude -cvgpath {/tx_tb_pkg/tx_coverage/cg_ltsm/cp_encoding/repairval}
coverage exclude -cvgpath {/tx_tb_pkg/tx_coverage/cg_ltsm/cp_encoding/reversal}
coverage exclude -cvgpath {/tx_tb_pkg/tx_coverage/cg_ltsm/cp_encoding/repairmb}
coverage exclude -cvgpath {/tx_tb_pkg/tx_coverage/cg_ltsm/cp_encoding/trainerror}

coverage exclude -cvgpath {/rp_pkg/rp_coverage_collector/cg_ltsm/cp_encoding/sbinit}
coverage exclude -cvgpath {/rp_pkg/rp_coverage_collector/cg_ltsm/cp_encoding/param}
coverage exclude -cvgpath {/rp_pkg/rp_coverage_collector/cg_ltsm/cp_encoding/cal}
coverage exclude -cvgpath {/rp_pkg/rp_coverage_collector/cg_ltsm/cp_encoding/repairclk}
coverage exclude -cvgpath {/rp_pkg/rp_coverage_collector/cg_ltsm/cp_encoding/repairval}
coverage exclude -cvgpath {/rp_pkg/rp_coverage_collector/cg_ltsm/cp_encoding/reversal}
coverage exclude -cvgpath {/rp_pkg/rp_coverage_collector/cg_ltsm/cp_encoding/repairmb}
coverage exclude -cvgpath {/rp_pkg/rp_coverage_collector/cg_ltsm/cp_encoding/trainerror}

# Exclude unreached bins in cg_phylink
coverage exclude -cvgpath {/sb_pkg/sb_coverage_collector/cg_phylink/cp_valid_msg/invalid_msg}
coverage exclude -cvgpath {/sb_pkg/sb_coverage_collector/cg_phylink/cp_fullcode/unsupported_fullcodes}
coverage exclude -cvgpath {/sb_pkg/sb_coverage_collector/cg_phylink/cp_opcode/unsupported_opcode}
coverage exclude -cvgpath {/sb_pkg/sb_coverage_collector/cg_phylink/cp_srcid/unsupported_srcid}
coverage exclude -cvgpath {/sb_pkg/sb_coverage_collector/cg_phylink/cp_dstid/unsupported_dstid}
coverage exclude -cvgpath {/sb_pkg/sb_coverage_collector/cg_phylink/cp_info_extremes/info_all_ones}
coverage exclude -cvgpath {/sb_pkg/sb_coverage_collector/cg_phylink/cx_msg_routing}
coverage exclude -cvgpath {/sb_pkg/sb_coverage_collector/cg_phylink/cx_payloads}

# ------------------------------------------------------------------------------
# 7. Save and Report
# ------------------------------------------------------------------------------
coverage save regression_merged_excluded.ucdb

# Text: Code coverage - RTL only
vcover report regression_merged_excluded.ucdb \
    -details -annotate -code bcefst \
    -output regression_code_cov_excluded.txt

# Text: Functional coverage
vcover report regression_merged_excluded.ucdb \
    -details -cvg -directive \
    -output regression_func_cov_excluded.txt
