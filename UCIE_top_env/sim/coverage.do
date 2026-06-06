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