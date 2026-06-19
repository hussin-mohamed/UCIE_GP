set COV_DB      $env(COV_DB_NAME)
set COV_TXT     $env(COV_TXT_NAME)
set COV_FUNC_TXT  $env(COV_FUNC_TXT_NAME)
set COV_FUNC_HTML $env(COV_FUNC_HTML)
set COV_CODE_HTML $env(COV_CODE_HTML)

# Exclude the assertion module from code coverage
coverage exclude -du sb_sva

# ==============================================================================
# UCIe 3.0 Sideband Verification - Coverage Exclusions
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

# ------------------------------------------------------------------------------
# 8. Unreachable FSM Default Case Branches
# Reason: All states of 2-bit state variables are explicitly handled, so default
#         branches are logically dead code.
# ------------------------------------------------------------------------------
coverage exclude -srcfile ../../../Sideband/ucie_sideband_traffic_fifo.sv -line 104-109
coverage exclude -srcfile ../../../Sideband/ucie_sideband_ser.sv -line 70
coverage exclude -srcfile ../../../Sideband/ucie_sideband_fifo_traffic.sv -line 79
coverage exclude -srcfile ../../../Sideband/ucie_sb_traffic.sv -line 95-99
coverage exclude -srcfile ../../../Sideband/ucie_sideband_tx_msg_enc_dec.sv -line 1217-1224
coverage exclude -srcfile ../../../Sideband/ucie_sideband_rx_msg_enc_dec.sv -line 1236-1243

# ------------------------------------------------------------------------------
# 9. Gated Clock Domains / Inactive Clock Logic
# Reason: Sideband receiver clock is disabled once initialization is done,
#         preventing the negedge clear branch from ever executing.
# ------------------------------------------------------------------------------
coverage exclude -srcfile ../../../Sideband/ucie_sb_rx_path.sv -line 48-51

# ------------------------------------------------------------------------------
# 10. Logically Preempted or Redundant Conditions
# Reason: These conditions are guaranteed to evaluate to a specific value
#         due to preceding logic or protocols.
# ------------------------------------------------------------------------------
coverage exclude -srcfile ../../../Sideband/ucie_sb_tx_path.sv -line 62
coverage exclude -srcfile ../../../Sideband/ucie_sb_traffic.sv -line 131
coverage exclude -srcfile ../../../Sideband/ucie_sb_traffic.sv -line 82-87

coverage exclude -srcfile ../../../Sideband/ucie_sb_rx_path.sv -line 35


# ------------------------------------------------------------------------------
# 11. FIFO Full & Backpressure / Flow Control (Unreachable)
# Reason: The sideband interface operates without flow control/credits, and
#         LTSM protocol constraints prevent queue build-up.
# ------------------------------------------------------------------------------
coverage exclude -srcfile ../../../Sideband/ucie_sideband_fifo.sv -line 63
coverage exclude -srcfile ../../../Sideband/ucie_sideband_fifo.sv -line 80
coverage exclude -srcfile ../../../Sideband/ucie_sideband_fifo_FWFT.sv -line 41
coverage exclude -srcfile ../../../Sideband/ucie_sideband_fifo_FWFT.sv -line 55
coverage exclude -srcfile ../../../Sideband/ucie_sideband_fifo_FWFT.sv -line 70
coverage exclude -srcfile ../../../Sideband/ucie_sideband_fifo_FWFT.sv -line 86
coverage exclude -srcfile ../../../Sideband/ucie_sideband_fifo_FWFT.sv -line 96
coverage exclude -srcfile ../../../Sideband/ucie_sideband_traffic_fifo.sv -line 54-59
coverage exclude -srcfile ../../../Sideband/ucie_sideband_traffic_fifo.sv -line 74-79
coverage exclude -srcfile ../../../Sideband/ucie_sideband_traffic_fifo.sv -line 88-103
coverage exclude -srcfile ../../../Sideband/ucie_sb_traffic.sv -line 119
coverage exclude -srcfile ../../../Sideband/ucie_sb_traffic.sv -line 158-164
coverage exclude -srcfile ../../../Sideband/ucie_sideband_tx_msg_enc_dec.sv -line 702
coverage exclude -srcfile ../../../Sideband/ucie_sideband_rx_msg_enc_dec.sv -line 735


# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# 12. Constant Ports & Signals (Toggle Exclusions)
# Reason: Hardcoded IDs / constants that never change value.
# ------------------------------------------------------------------------------
coverage exclude -togglenode dec_dstid -du ucie_sideband_tx_msg_enc_dec
coverage exclude -togglenode dec_srcid -du ucie_sideband_tx_msg_enc_dec
coverage exclude -togglenode enc_dstid -du ucie_sideband_tx_msg_enc_dec
coverage exclude -togglenode enc_srcid -du ucie_sideband_tx_msg_enc_dec
coverage exclude -togglenode dec_dstid -du ucie_sideband_rx_msg_enc_dec
coverage exclude -togglenode dec_srcid -du ucie_sideband_rx_msg_enc_dec
coverage exclude -togglenode enc_dstid -du ucie_sideband_rx_msg_enc_dec
coverage exclude -togglenode enc_srcid -du ucie_sideband_rx_msg_enc_dec

# ------------------------------------------------------------------------------
# 13. Additional CDC Synchronizer & Handshake Gaps (Logically Unreachable)
# Reason: These are standard synchronizers or handshakes where certain states
#         or inputs cannot toggle or be evaluated in specific configurations.
# ------------------------------------------------------------------------------
coverage exclude -srcfile ../../../Sideband/Toggle_sync.sv -line 27
coverage exclude -srcfile ../../../Sideband/ucie_sideband_traffic_fifo.sv -line 64 -allfalse
coverage exclude -srcfile ../../../Sideband/ucie_sideband_traffic_fifo.sv -line 67
coverage exclude -srcfile ../../../Sideband/ucie_sideband_ser.sv -line 81 -allfalse
coverage exclude -srcfile ../../../Sideband/ucie_sideband_ser.sv -line 83
coverage exclude -srcfile ../../../Sideband/ucie_sideband_fifo_traffic.sv -line 40

coverage exclude -du ucie_sideband_fifo_traffic -ftrans state ST_WAIT_M2->ST_IDLE
coverage exclude -du ucie_sideband_fifo_traffic -ftrans state ST_CAP_M2->ST_IDLE

coverage exclude -srcfile ../../../Sideband/ucie_sideband_deser.sv -line 65
coverage exclude -srcfile ../../../Sideband/ucie_sb_traffic.sv -line 59
coverage exclude -srcfile ../../../Sideband/ucie_sb_traffic.sv -line 120
coverage exclude -srcfile ../../../Sideband/ucie_sideband_tx_msg_enc_dec.sv -line 295
coverage exclude -srcfile ../../../Sideband/ucie_sideband_rx_msg_enc_dec.sv -line 322

# ------------------------------------------------------------------------------
# 14. Additional FIFO Full, Stall, and Count Toggles (Unreachable)
# Reason: The FIFOs never saturate, so o_full is always 0 and count bits never 
#         reach higher levels. Gated/unused backpressure signals stay 0.
# ------------------------------------------------------------------------------
coverage exclude -togglenode o_full -du ucie_sideband_fifo
coverage exclude -togglenode o_full -du ucie_sideband_fifo_FWFT
coverage exclude -togglenode i_fifo_full -du ucie_sideband_traffic_fifo
coverage exclude -togglenode i_fifo_full -du ucie_sideband_deser
coverage exclude -togglenode i_stall_traffic -du ucie_sideband_fifo_traffic
coverage exclude -togglenode i_stall_traffic -du ucie_sb_traffic
coverage exclude -togglenode o_stall_traffic -du ucie_sb_traffic
coverage exclude -togglenode count -du ucie_sideband_fifo_FWFT

# ------------------------------------------------------------------------------
# 15. Message Field Constant Padding Toggle Exclusions (Design-wide)
# Reason: Hardcoded message bits, reserved fields, and subcode padding that
#         never toggle throughout all message-carrying modules.
# ------------------------------------------------------------------------------
coverage exclude -togglenode i_sb_msg\[127:117\] -du ucie_sideband_traffic_fifo
coverage exclude -togglenode i_sb_msg\[109:100\] -du ucie_sideband_traffic_fifo
coverage exclude -togglenode i_sb_msg\[98:97\]   -du ucie_sideband_traffic_fifo
coverage exclude -togglenode i_sb_msg\[93:88\]   -du ucie_sideband_traffic_fifo
coverage exclude -togglenode i_sb_msg\[71:69\]   -du ucie_sideband_traffic_fifo

coverage exclude -togglenode i_sb_msg\[127:117\] -du ucie_sideband_out
coverage exclude -togglenode i_sb_msg\[109:100\] -du ucie_sideband_out
coverage exclude -togglenode i_sb_msg\[98:97\]   -du ucie_sideband_out
coverage exclude -togglenode i_sb_msg\[93:88\]   -du ucie_sideband_out
coverage exclude -togglenode i_sb_msg\[71:69\]   -du ucie_sideband_out

coverage exclude -togglenode i_rx_traffic_fifo_msg\[127:117\] -du ucie_sb_traffic
coverage exclude -togglenode i_rx_traffic_fifo_msg\[109:100\] -du ucie_sb_traffic
coverage exclude -togglenode i_rx_traffic_fifo_msg\[98:97\]   -du ucie_sb_traffic
coverage exclude -togglenode i_rx_traffic_fifo_msg\[93:88\]   -du ucie_sb_traffic
coverage exclude -togglenode i_rx_traffic_fifo_msg\[71:69\]   -du ucie_sb_traffic

coverage exclude -togglenode i_tx_traffic_fifo_msg\[127:117\] -du ucie_sb_traffic
coverage exclude -togglenode i_tx_traffic_fifo_msg\[109:100\] -du ucie_sb_traffic
coverage exclude -togglenode i_tx_traffic_fifo_msg\[98:97\]   -du ucie_sb_traffic
coverage exclude -togglenode i_tx_traffic_fifo_msg\[93:88\]   -du ucie_sb_traffic
coverage exclude -togglenode i_tx_traffic_fifo_msg\[71:69\]   -du ucie_sb_traffic

coverage exclude -togglenode o_sb_msg_out\[127:117\] -du ucie_sb_traffic
coverage exclude -togglenode o_sb_msg_out\[109:100\] -du ucie_sb_traffic
coverage exclude -togglenode o_sb_msg_out\[98:97\]   -du ucie_sb_traffic
coverage exclude -togglenode o_sb_msg_out\[93:88\]   -du ucie_sb_traffic
coverage exclude -togglenode o_sb_msg_out\[71:69\]   -du ucie_sb_traffic

coverage exclude -togglenode o_traffic_rx_fifo_msg\[127:117\] -du ucie_sb_traffic
coverage exclude -togglenode o_traffic_rx_fifo_msg\[109:100\] -du ucie_sb_traffic
coverage exclude -togglenode o_traffic_rx_fifo_msg\[98:97\]   -du ucie_sb_traffic
coverage exclude -togglenode o_traffic_rx_fifo_msg\[93:88\]   -du ucie_sb_traffic
coverage exclude -togglenode o_traffic_rx_fifo_msg\[71:69\]   -du ucie_sb_traffic

coverage exclude -togglenode o_traffic_tx_fifo_msg\[127:117\] -du ucie_sb_traffic
coverage exclude -togglenode o_traffic_tx_fifo_msg\[109:100\] -du ucie_sb_traffic
coverage exclude -togglenode o_traffic_tx_fifo_msg\[98:97\]   -du ucie_sb_traffic
coverage exclude -togglenode o_traffic_tx_fifo_msg\[93:88\]   -du ucie_sb_traffic
coverage exclude -togglenode o_traffic_tx_fifo_msg\[71:69\]   -du ucie_sb_traffic


coverage exclude -togglenode i_data_in\[127:117\] -du ucie_sideband_fifo_FWFT
coverage exclude -togglenode i_data_in\[109:100\] -du ucie_sideband_fifo_FWFT
coverage exclude -togglenode i_data_in\[98:97\]   -du ucie_sideband_fifo_FWFT
coverage exclude -togglenode i_data_in\[93:88\]   -du ucie_sideband_fifo_FWFT
coverage exclude -togglenode i_data_in\[71:69\]   -du ucie_sideband_fifo_FWFT

coverage exclude -togglenode o_data_out\[127:117\] -du ucie_sideband_fifo_FWFT
coverage exclude -togglenode o_data_out\[109:100\] -du ucie_sideband_fifo_FWFT
coverage exclude -togglenode o_data_out\[98:97\]   -du ucie_sideband_fifo_FWFT
coverage exclude -togglenode o_data_out\[93:88\]   -du ucie_sideband_fifo_FWFT
coverage exclude -togglenode o_data_out\[71:69\]   -du ucie_sideband_fifo_FWFT

coverage exclude -togglenode i_traffic_tx_fifo_msg_in\[127:117\] -du ucie_sideband_tx_msg
coverage exclude -togglenode i_traffic_tx_fifo_msg_in\[109:100\] -du ucie_sideband_tx_msg
coverage exclude -togglenode i_traffic_tx_fifo_msg_in\[98:97\]   -du ucie_sideband_tx_msg
coverage exclude -togglenode i_traffic_tx_fifo_msg_in\[93:88\]   -du ucie_sideband_tx_msg
coverage exclude -togglenode i_traffic_tx_fifo_msg_in\[71:69\]   -du ucie_sideband_tx_msg

coverage exclude -togglenode o_tx_traffic_fifo_msg_out\[127:117\] -du ucie_sideband_tx_msg
coverage exclude -togglenode o_tx_traffic_fifo_msg_out\[109:100\] -du ucie_sideband_tx_msg
coverage exclude -togglenode o_tx_traffic_fifo_msg_out\[98:97\]   -du ucie_sideband_tx_msg
coverage exclude -togglenode o_tx_traffic_fifo_msg_out\[93:88\]   -du ucie_sideband_tx_msg
coverage exclude -togglenode o_tx_traffic_fifo_msg_out\[71:69\]   -du ucie_sideband_tx_msg

coverage exclude -togglenode traffic_tx_fifo_msg\[127:117\] -du ucie_sideband_tx_msg
coverage exclude -togglenode traffic_tx_fifo_msg\[109:100\] -du ucie_sideband_tx_msg
coverage exclude -togglenode traffic_tx_fifo_msg\[98:97\]   -du ucie_sideband_tx_msg
coverage exclude -togglenode traffic_tx_fifo_msg\[93:88\]   -du ucie_sideband_tx_msg
coverage exclude -togglenode traffic_tx_fifo_msg\[71:69\]   -du ucie_sideband_tx_msg

coverage exclude -togglenode tx_traffic_fifo_msg\[127:117\] -du ucie_sideband_tx_msg
coverage exclude -togglenode tx_traffic_fifo_msg\[109:100\] -du ucie_sideband_tx_msg
coverage exclude -togglenode tx_traffic_fifo_msg\[98:97\]   -du ucie_sideband_tx_msg
coverage exclude -togglenode tx_traffic_fifo_msg\[93:88\]   -du ucie_sideband_tx_msg
coverage exclude -togglenode tx_traffic_fifo_msg\[71:69\]   -du ucie_sideband_tx_msg

coverage exclude -togglenode i_traffic_rx_fifo_msg_in\[127:117\] -du ucie_sideband_rx_msg
coverage exclude -togglenode i_traffic_rx_fifo_msg_in\[109:100\] -du ucie_sideband_rx_msg
coverage exclude -togglenode i_traffic_rx_fifo_msg_in\[98:97\]   -du ucie_sideband_rx_msg
coverage exclude -togglenode i_traffic_rx_fifo_msg_in\[93:88\]   -du ucie_sideband_rx_msg
coverage exclude -togglenode i_traffic_rx_fifo_msg_in\[71:69\]   -du ucie_sideband_rx_msg

coverage exclude -togglenode o_rx_traffic_fifo_msg_out\[127:117\] -du ucie_sideband_rx_msg
coverage exclude -togglenode o_rx_traffic_fifo_msg_out\[109:100\] -du ucie_sideband_rx_msg
coverage exclude -togglenode o_rx_traffic_fifo_msg_out\[98:97\]   -du ucie_sideband_rx_msg
coverage exclude -togglenode o_rx_traffic_fifo_msg_out\[93:88\]   -du ucie_sideband_rx_msg
coverage exclude -togglenode o_rx_traffic_fifo_msg_out\[71:69\]   -du ucie_sideband_rx_msg

coverage exclude -togglenode traffic_rx_fifo_msg\[127:117\] -du ucie_sideband_rx_msg
coverage exclude -togglenode traffic_rx_fifo_msg\[109:100\] -du ucie_sideband_rx_msg
coverage exclude -togglenode traffic_rx_fifo_msg\[98:97\]   -du ucie_sideband_rx_msg
coverage exclude -togglenode traffic_rx_fifo_msg\[93:88\]   -du ucie_sideband_rx_msg
coverage exclude -togglenode traffic_rx_fifo_msg\[71:69\]   -du ucie_sideband_rx_msg

coverage exclude -togglenode rx_traffic_fifo_msg\[127:117\] -du ucie_sideband_rx_msg
coverage exclude -togglenode rx_traffic_fifo_msg\[109:100\] -du ucie_sideband_rx_msg
coverage exclude -togglenode rx_traffic_fifo_msg\[98:97\]   -du ucie_sideband_rx_msg
coverage exclude -togglenode rx_traffic_fifo_msg\[93:88\]   -du ucie_sideband_rx_msg
coverage exclude -togglenode rx_traffic_fifo_msg\[71:69\]   -du ucie_sideband_rx_msg

coverage exclude -togglenode msg_tx\[127:117\] -du ucie_sb_top
coverage exclude -togglenode msg_tx\[109:100\] -du ucie_sb_top
coverage exclude -togglenode msg_tx\[98:97\]   -du ucie_sb_top
coverage exclude -togglenode msg_tx\[93:88\]   -du ucie_sb_top
coverage exclude -togglenode msg_tx\[71:69\]   -du ucie_sb_top

coverage exclude -togglenode rx_traffic_fifo_msg\[127:117\] -du ucie_sb_top
coverage exclude -togglenode rx_traffic_fifo_msg\[109:100\] -du ucie_sb_top
coverage exclude -togglenode rx_traffic_fifo_msg\[98:97\]   -du ucie_sb_top
coverage exclude -togglenode rx_traffic_fifo_msg\[93:88\]   -du ucie_sb_top
coverage exclude -togglenode rx_traffic_fifo_msg\[71:69\]   -du ucie_sb_top

coverage exclude -togglenode traffic_rx_fifo_msg\[127:117\] -du ucie_sb_top
coverage exclude -togglenode traffic_rx_fifo_msg\[109:100\] -du ucie_sb_top
coverage exclude -togglenode traffic_rx_fifo_msg\[98:97\]   -du ucie_sb_top
coverage exclude -togglenode traffic_rx_fifo_msg\[93:88\]   -du ucie_sb_top
coverage exclude -togglenode traffic_rx_fifo_msg\[71:69\]   -du ucie_sb_top

coverage exclude -togglenode traffic_tx_fifo_msg\[127:117\] -du ucie_sb_top
coverage exclude -togglenode traffic_tx_fifo_msg\[109:100\] -du ucie_sb_top
coverage exclude -togglenode traffic_tx_fifo_msg\[98:97\]   -du ucie_sb_top
coverage exclude -togglenode traffic_tx_fifo_msg\[93:88\]   -du ucie_sb_top
coverage exclude -togglenode traffic_tx_fifo_msg\[71:69\]   -du ucie_sb_top

coverage exclude -togglenode tx_traffic_fifo_msg\[127:117\] -du ucie_sb_top
coverage exclude -togglenode tx_traffic_fifo_msg\[109:100\] -du ucie_sb_top
coverage exclude -togglenode tx_traffic_fifo_msg\[98:97\]   -du ucie_sb_top
coverage exclude -togglenode tx_traffic_fifo_msg\[93:88\]   -du ucie_sb_top
coverage exclude -togglenode tx_traffic_fifo_msg\[71:69\]   -du ucie_sb_top

coverage exclude -togglenode i_msg_in\[127:117\] -du ucie_sideband_tx_msg_enc_dec
coverage exclude -togglenode i_msg_in\[109:100\] -du ucie_sideband_tx_msg_enc_dec
coverage exclude -togglenode i_msg_in\[98:97\]   -du ucie_sideband_tx_msg_enc_dec
coverage exclude -togglenode i_msg_in\[93:88\]   -du ucie_sideband_tx_msg_enc_dec
coverage exclude -togglenode i_msg_in\[71:69\]   -du ucie_sideband_tx_msg_enc_dec

coverage exclude -togglenode i_msg_in\[127:117\] -du ucie_sideband_rx_msg_enc_dec
coverage exclude -togglenode i_msg_in\[109:100\] -du ucie_sideband_rx_msg_enc_dec
coverage exclude -togglenode i_msg_in\[98:97\]   -du ucie_sideband_rx_msg_enc_dec
coverage exclude -togglenode i_msg_in\[93:88\]   -du ucie_sideband_rx_msg_enc_dec
coverage exclude -togglenode i_msg_in\[71:69\]   -du ucie_sideband_rx_msg_enc_dec

coverage exclude -togglenode dec_op_code -du ucie_sideband_tx_msg_enc_dec
coverage exclude -togglenode enc_msg_subcode -du ucie_sideband_tx_msg_enc_dec
coverage exclude -togglenode enc_op_code -du ucie_sideband_tx_msg_enc_dec
coverage exclude -togglenode dec_op_code -du ucie_sideband_rx_msg_enc_dec
coverage exclude -togglenode enc_msg_subcode -du ucie_sideband_rx_msg_enc_dec
coverage exclude -togglenode enc_op_code -du ucie_sideband_rx_msg_enc_dec

# ------------------------------------------------------------------------------
# 16. Additional RX/TX Msg Encoder/Decoder Toggles (Unreachable/Constant Padding)
# Reason: Excludes constant padding and unused subcode/opcode bits in RX and TX
#         message encoder/decoder modules.
# ------------------------------------------------------------------------------
coverage exclude -togglenode o_msg_out\[127:117\] -du ucie_sideband_rx_msg_enc_dec
coverage exclude -togglenode o_msg_out\[109:100\] -du ucie_sideband_rx_msg_enc_dec
coverage exclude -togglenode o_msg_out\[98:97\]   -du ucie_sideband_rx_msg_enc_dec
coverage exclude -togglenode o_msg_out\[93:88\]   -du ucie_sideband_rx_msg_enc_dec
coverage exclude -togglenode o_msg_out\[71:69\]   -du ucie_sideband_rx_msg_enc_dec
coverage exclude -togglenode dec_msg_subcode -du ucie_sideband_rx_msg_enc_dec
coverage exclude -togglenode dec_msg_subcode -du ucie_sideband_tx_msg_enc_dec
coverage exclude -togglenode o_msg_out\[71:69\]   -du ucie_sideband_tx_msg_enc_dec

# Coverage Save settings (Using unique DB name)
run -all
coverage save $COV_DB

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