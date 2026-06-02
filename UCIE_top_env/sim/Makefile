# =============================================================================
# Makefile for UCIE System-Level Simulation Control
# ================================================================
# Variables:
#   TEST      : UVM Test name to run (default: ucie_sanity_test)
#   VERBOSITY : UVM verbosity level (default: UVM_MEDIUM)
#   SEED      : Random seed for simulation (default: random)
#   TIMEOUT   : UVM timeout in ms (default: 100)
#   GUI=1/0   : Enable/disable GUI mode (default: 1)
#   RUN_ID    : Run identifier for logs (default: 1)
#
# Examples:
#   make                                    - Run sanity test in Questa (GUI)
#   make GUI=0                              - Run sanity test in batch mode
#   make TEST=ucie_error_test GUI=0         - Run error test in batch
#   make compile                            - Compile and elaborate only
#   make run TEST=ucie_loopback_test        - Run test without recompile
#   make rerun TEST=ucie_loopback_test      - Fast rerun (no checks)
# ================================================================

# Default settings
GUI       ?= 1
TEST      ?= ucie_sanity_test
VERBOSITY ?= UVM_MEDIUM
SEED      ?= random
TIMEOUT   ?= 100
RUN_ID    ?= 1
UCIE_SYS_LEVEL ?= 1

# Export variables so the TCL script (.do file) can read them
export TEST_NAME      = $(TEST)
export UVM_VERB       = $(VERBOSITY)
export SIM_SEED       = $(SEED)
export UVM_TIMEOUT    = $(TIMEOUT)

# ================================================================
# Directory Structure
# ================================================================
WORK_DIR     := ./tmp/ucie_sim_work
LOG_DIR      := out/logs
DATE         := $(shell date +%Y-%m-%d)
TIME         := $(shell date +%H-%M-%S)

# Unique file paths using the new directory structure
LOG_FILE     := $(LOG_DIR)/$(DATE)_$(TIME)_$(TEST)_run$(RUN_ID).log

# Questa File names
RUN_DO_FILE  = run.do
TEMP_RUN_DO  = run_$(DATE)_$(TIME).do

# ================================================================
# Compilation flags
# ================================================================
VLOG_ARGS      = -sv -mfcu -incr +define+UCIE_SYS_LVL=1 -suppress 2583
VLOG_ARGS_BASE = -sv -incr +define+UCIE_SYS_LVL=1

# ================================================================
# Targets
# ================================================================
.PHONY: all run compile rerun clean cleanall help mkdirs

all: run

# Ensure output directories exist
mkdirs:
	@mkdir -p $(LOG_DIR)
	@mkdir -p $(WORK_DIR)

# =============================================================================
# Compile target - Compile and elaborate only
# =============================================================================
compile: mkdirs
	@echo "=========================================="
	@echo "Compiling UCIE System-Level Environment..."
	@echo "Work library: $(WORK_DIR)"
	@echo "=========================================="
	@echo "→ Creating work library in $(WORK_DIR)..."
	@if [ -d "$(WORK_DIR)" ]; then \
		echo "  Work directory already exists, using incremental compilation"; \
	else \
		vlib.exe "$(WORK_DIR)"; \
	fi
	@vmap.exe work "$(WORK_DIR)"
	@echo "→ Compiling LTSM Environment..."
	@vlog.exe $(VLOG_ARGS) +incdir+../../LTSM_Environment/src/tb +incdir+../../LTSM_Environment/src/tb/model \
	    ../../LTSM_Environment/src/tb/shared_ltsm_pkg.svh \
	    ../../LTSM_Environment/src/tb/LTSM_pkg.sv
	@echo "→ Compiling SB Environment..."
	@vlog.exe $(VLOG_ARGS) +incdir+../../SB_Environment/src/tb \
	    ../../SB_Environment/src/tb/sb_shared_pkg.sv \
	    ../../SB_Environment/src/tb/sb_pkg.sv
	@echo "→ Compiling RP Environment..."
	@vlog.exe $(VLOG_ARGS) +incdir+../../rp_env/src/tb \
	    ../../rp_env/src/tb/rp_shared_pkg.sv \
	    ../../rp_env/src/tb/rp_pkg.sv
	@echo "→ Compiling TP Environment..."
	@vlog.exe $(VLOG_ARGS) +incdir+../../tp_env/packages +incdir+../../tp_env/env +incdir+../../tp_env/ref_model \
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
	@echo "→ Compiling DUT Interfaces and BFMs..."
	@vlog.exe $(VLOG_ARGS_BASE) \
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
	@echo "→ Compiling DUT LTSM RTL..."
	@vlog.exe $(VLOG_ARGS) \
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
	@echo "→ Compiling DUT Sideband RTL..."
	@vlog.exe $(VLOG_ARGS) \
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
	@echo "→ Compiling DUT TX Path RTL..."
	@vlog.exe -sv -incr -suppress 2732,7063,2912 \
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
	@echo "→ Compiling DUT RX Path RTL..."
	@vlog.exe $(VLOG_ARGS) \
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
	@echo "→ Compiling Environment Wrappers & Testbench Top..."
	@vlog.exe $(VLOG_ARGS) \
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
	    ../../rx_path/rx_error_decoder.sv \
	    ../../UCIE_top/PLL_model.sv \
	    ../../UCIE_top/valid_decoder.sv \
	    ../../UCIE_top/UCIe.sv \
	    ../../UCIE_top_env/src/tb/ucie_tb_top.sv
	@echo "→ Elaborating optimized design..."
	@vopt.exe +acc ucie_tb_top -o opt_ucie_tb_top
	@echo "=========================================="
	@echo "Compile complete!"
	@echo "Optimized image: $(WORK_DIR)/opt_ucie_tb_top"
	@echo "=========================================="

# =============================================================================
# Run target - Run simulation (checks if opt image exists)
# =============================================================================
run: mkdirs
	@echo "=========================================="
	@echo "Running UCIE System-Level Simulation..."
	@echo "Test      : $(TEST)"
	@echo "Verbosity : $(VERBOSITY)"
	@echo "Seed      : $(SEED)"
	@echo "Timeout   : $(TIMEOUT)ms"
	@echo "GUI mode  : $(GUI)"
	@echo "Log file  : $(LOG_FILE)"
	@echo "=========================================="
	@if [ ! -d "$(WORK_DIR)/opt_ucie_tb_top" ]; then \
		echo "ERROR: opt_ucie_tb_top not found in $(WORK_DIR)"; \
		echo "Please run 'make compile' first."; \
		exit 1; \
	fi
	@cp $(RUN_DO_FILE) $(TEMP_RUN_DO)
	@echo "→ Injecting variables into run script..."
	@sed -i 's/\$$env(TEST_NAME)/$(TEST)/g' $(TEMP_RUN_DO)
	@sed -i 's/\$$env(UVM_VERB)/$(VERBOSITY)/g' $(TEMP_RUN_DO)
	@sed -i 's/\$$env(SIM_SEED)/$(SEED)/g' $(TEMP_RUN_DO)
	@sed -i 's/\$$env(UVM_TIMEOUT)/$(TIMEOUT)/g' $(TEMP_RUN_DO)
	@sed -i 's|__WORK_DIR__|$(WORK_DIR)|g' $(TEMP_RUN_DO)
ifeq ($(GUI),0)
	@echo "→ Disabling GUI (batch mode)..."
	@sed -i 's/^do waves.do/# do waves.do/' $(TEMP_RUN_DO)
endif
	@echo "→ Starting simulation..."
ifeq ($(GUI),0)
	@vsim.exe -c -l $(LOG_FILE) -do $(TEMP_RUN_DO)
else
	@vsim.exe -gui -l $(LOG_FILE) -do $(TEMP_RUN_DO)
endif
	@rm -f $(TEMP_RUN_DO)
	@echo "=========================================="
	@echo "Simulation complete!"
	@echo "Log: $(LOG_FILE)"
	@echo "=========================================="

# =============================================================================
# Rerun target - Fast rerun (no checks, raw speed)
# =============================================================================
rerun: mkdirs
	@echo "=========================================="
	@echo "Fast Rerun (no safety checks)..."
	@echo "Test      : $(TEST)"
	@echo "Verbosity : $(VERBOSITY)"
	@echo "Seed      : $(SEED)"
	@echo "GUI mode  : $(GUI)"
	@echo "=========================================="
	@cp $(RUN_DO_FILE) $(TEMP_RUN_DO)
	@echo "→ Injecting variables into run script..."
	@sed -i 's/\$$env(TEST_NAME)/$(TEST)/g' $(TEMP_RUN_DO)
	@sed -i 's/\$$env(UVM_VERB)/$(VERBOSITY)/g' $(TEMP_RUN_DO)
	@sed -i 's/\$$env(SIM_SEED)/$(SEED)/g' $(TEMP_RUN_DO)
	@sed -i 's/\$$env(UVM_TIMEOUT)/$(TIMEOUT)/g' $(TEMP_RUN_DO)
	@sed -i 's|__WORK_DIR__|$(WORK_DIR)|g' $(TEMP_RUN_DO)
	@sed -i 's/check_for_opt_image/# check_for_opt_image/' $(TEMP_RUN_DO)
ifeq ($(GUI),0)
	@echo "→ Disabling GUI (batch mode)..."
	@sed -i 's/^do waves.do/# do waves.do/' $(TEMP_RUN_DO)
endif
	@echo "→ Starting simulation..."
ifeq ($(GUI),0)
	@vsim.exe -c -l $(LOG_FILE) -do $(TEMP_RUN_DO)
else
	@vsim.exe -gui -l $(LOG_FILE) -do $(TEMP_RUN_DO)
endif
	@rm -f $(TEMP_RUN_DO)
	@echo "=========================================="
	@echo "Rerun complete!"
	@echo "=========================================="

# =============================================================================
# Clean targets
# =============================================================================
clean:
	@echo "=========================================="
	@echo "Cleaning simulation artifacts..."
	@echo "=========================================="
	@rm -rf wlf* vsim.exe* *.stacktrace tr_db*
	@rm -f transcript vsim.exe.wlf
	@rm -f run_*.do
	@rm -f vsim.exe_stacktrace.vstf
	@pkill -9 vsim.exe 2>/dev/null || true
	@echo "→ Removed simulator artifacts"
	@echo "Note: Work library in /tmp and logs in out/ are preserved."
	@echo "      Use 'make cleanall' to remove everything."
	@echo "=========================================="

cleanall:
	@echo "=========================================="
	@echo "Cleaning ALL artifacts..."
	@echo "=========================================="
	@rm -rf wlf* vsim.exe* *.stacktrace tr_db*
	@rm -f transcript vsim.exe.wlf
	@rm -f run_*.do
	@rm -f vsim.exe_stacktrace.vstf
	@rm -rf $(WORK_DIR)
	@rm -rf out/
	@pkill -9 vsim.exe 2>/dev/null || true
	@echo "→ Removed everything including work library and logs"
	@echo "=========================================="

help:
	@echo "=========================================="
	@echo "UCIE System-Level Simulation Makefile"
	@echo "=========================================="
	@echo ""
	@echo "TARGETS:"
	@echo "  make [run]       - Compile (if needed) and run simulation (default)"
	@echo "  make compile     - Compile and elaborate only (produces opt_ucie_tb_top)"
	@echo "  make run         - Run simulation (checks opt image exists)"
	@echo "  make rerun       - Fast rerun (no checks, skips validation)"
	@echo "  make clean       - Remove simulator artifacts (keeps work & logs)"
	@echo "  make cleanall    - Remove ALL files including work/ and logs"
	@echo "  make help        - Display this help message"
	@echo ""
	@echo "VARIABLES:"
	@echo "  TEST             - UVM test name (Default: ucie_sanity_test)"
	@echo "  VERBOSITY        - UVM verbosity (Default: UVM_MEDIUM)"
	@echo "  SEED             - Random seed (Default: random)"
	@echo "  TIMEOUT          - UVM timeout in ms (Default: 100)"
	@echo "  GUI=1/0          - Enable/disable GUI (Default: 1)"
	@echo "  RUN_ID           - Run identifier for logs (Default: 1)"
	@echo ""
	@echo "USAGE EXAMPLES:"
	@echo "  make"
	@echo "  make GUI=0"
	@echo "  make TEST=ucie_error_test GUI=0 VERBOSITY=UVM_HIGH"
	@echo "  make compile && make run TEST=ucie_loopback_test"
	@echo "  make rerun TEST=ucie_sanity_test SEED=12345"
	@echo "=========================================="
