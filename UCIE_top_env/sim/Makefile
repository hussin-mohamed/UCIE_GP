# =============================================================================
# Makefile for UCIE System-Level Simulation Control
# ================================================================
# Variables:
#   TEST      : UVM Test name to run (default: ucie_sanity_test)
#   VERBOSITY : UVM verbosity level (default: UVM_MEDIUM)
#   SEED      : Random seed for simulation (default: random)
#   TIMEOUT   : UVM timeout in ms (default: 100)
#   GUI=1/0   : Enable/disable GUI mode (default: 1)
#   COVERAGE  : Enable/disable coverage (default: 1)
#   RUN_ID    : Run identifier for logs (default: 1)
# ================================================================

# Default settings
GUI       ?= 1
COVERAGE  ?= 0
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
COV_DIR      := out/coverage
DATE         := $(shell date +%Y-%m-%d)
TIME         := $(shell date +%H-%M-%S)

# Unique file paths
LOG_FILE          := $(LOG_DIR)/$(DATE)_$(TIME)_$(TEST)_run$(RUN_ID).log
COV_DB_NAME       := $(COV_DIR)/$(DATE)_$(TIME)_$(TEST)_run$(RUN_ID).ucdb
COV_TXT_NAME      := $(COV_DIR)/$(DATE)_$(TIME)_$(TEST)_run$(RUN_ID)_code.txt
COV_FUNC_TXT_NAME := $(COV_DIR)/$(DATE)_$(TIME)_$(TEST)_run$(RUN_ID)_func.txt
COV_CODE_HTML     := $(COV_DIR)/html_code_$(DATE)_$(TIME)_$(TEST)_run$(RUN_ID)
COV_FUNC_HTML     := $(COV_DIR)/html_func_$(DATE)_$(TIME)_$(TEST)_run$(RUN_ID)

# Questa File names
RUN_DO_FILE  = run.do
TEMP_RUN_DO  = run_$(DATE)_$(TIME).do

# ================================================================
# Targets
# ================================================================
.PHONY: all run compile rerun clean cleanall help mkdirs full

all: run

# =============================================================================
# Full target - Executes compilation followed by simulation
# =============================================================================
full:
	@$(MAKE) compile
	@$(MAKE) run


# Ensure output directories exist (Cross-platform safe)
mkdirs:
	@-mkdir -p $(LOG_DIR) 2>/dev/null || mkdir $(subst /,\,$(LOG_DIR)) >nul 2>&1 || true
	@-mkdir -p $(COV_DIR) 2>/dev/null || mkdir $(subst /,\,$(COV_DIR)) >nul 2>&1 || true
	@-mkdir -p $(WORK_DIR) 2>/dev/null || mkdir $(subst /,\,$(WORK_DIR)) >nul 2>&1 || true

# =============================================================================
# Compile target - Compile and elaborate only
# =============================================================================
compile: mkdirs
	@echo "=========================================="
	@echo "Invoking compile.do (batch)..."
	@echo "=========================================="
	@vsim.exe -c -do compile.do
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
	@echo "Coverage  : $(COVERAGE)"
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
	@sed -i 's/\$$env(ENABLE_COVERAGE)/$(COVERAGE)/g' $(TEMP_RUN_DO)
	@sed -i 's|\$$env(COV_DB_NAME)|$(COV_DB_NAME)|g' $(TEMP_RUN_DO)
	@sed -i 's|\$$env(COV_TXT_NAME)|$(COV_TXT_NAME)|g' $(TEMP_RUN_DO)
	@sed -i 's|\$$env(COV_FUNC_TXT_NAME)|$(COV_FUNC_TXT_NAME)|g' $(TEMP_RUN_DO)
	@sed -i 's|\$$env(COV_CODE_HTML)|$(COV_CODE_HTML)|g' $(TEMP_RUN_DO)
	@sed -i 's|\$$env(COV_FUNC_HTML)|$(COV_FUNC_HTML)|g' $(TEMP_RUN_DO)
	@sed -i 's|__WORK_DIR__|$(WORK_DIR)|g' $(TEMP_RUN_DO)
ifeq ($(GUI),0)
	@echo "→ Disabling GUI (batch mode)..."
	@sed -i 's/^do waves.do/# do waves.do/' $(TEMP_RUN_DO)
endif
	@echo "→ Starting simulation..."
ifeq ($(GUI),0)
	@vsim.exe -c -l $(LOG_FILE) -do "set SKIP_COMPILE_ONCE 1; do $(TEMP_RUN_DO)"
else
	@vsim.exe -gui -l $(LOG_FILE) -do "set SKIP_COMPILE_ONCE 1; do $(TEMP_RUN_DO)"
endif
	@rm -f $(TEMP_RUN_DO)
	@echo "=========================================="
	@echo "Simulation complete!"
	@echo "=========================================="

# =============================================================================
# Rerun target - Fast rerun (no checks, raw speed)
# =============================================================================
rerun: mkdirs
	@echo "=========================================="
	@echo "Fast Rerun (no safety checks)..."
	@echo "Test      : $(TEST)"
	@echo "=========================================="
	@cp $(RUN_DO_FILE) $(TEMP_RUN_DO)
	@echo "→ Injecting variables into run script..."
	@sed -i 's/\$$env(TEST_NAME)/$(TEST)/g' $(TEMP_RUN_DO)
	@sed -i 's/\$$env(UVM_VERB)/$(VERBOSITY)/g' $(TEMP_RUN_DO)
	@sed -i 's/\$$env(SIM_SEED)/$(SEED)/g' $(TEMP_RUN_DO)
	@sed -i 's/\$$env(UVM_TIMEOUT)/$(TIMEOUT)/g' $(TEMP_RUN_DO)
	@sed -i 's/\$$env(ENABLE_COVERAGE)/$(COVERAGE)/g' $(TEMP_RUN_DO)
	@sed -i 's|\$$env(COV_DB_NAME)|$(COV_DB_NAME)|g' $(TEMP_RUN_DO)
	@sed -i 's|\$$env(COV_TXT_NAME)|$(COV_TXT_NAME)|g' $(TEMP_RUN_DO)
	@sed -i 's|\$$env(COV_FUNC_TXT_NAME)|$(COV_FUNC_TXT_NAME)|g' $(TEMP_RUN_DO)
	@sed -i 's|\$$env(COV_CODE_HTML)|$(COV_CODE_HTML)|g' $(TEMP_RUN_DO)
	@sed -i 's|\$$env(COV_FUNC_HTML)|$(COV_FUNC_HTML)|g' $(TEMP_RUN_DO)
	@sed -i 's|__WORK_DIR__|$(WORK_DIR)|g' $(TEMP_RUN_DO)
	@sed -i 's/check_for_opt_image/# check_for_opt_image/' $(TEMP_RUN_DO)
ifeq ($(GUI),0)
	@echo "→ Disabling GUI (batch mode)..."
	@sed -i 's/^do waves.do/# do waves.do/' $(TEMP_RUN_DO)
endif
	@echo "→ Starting simulation..."
ifeq ($(GUI),0)
	@vsim.exe -c -l $(LOG_FILE) -do "set SKIP_COMPILE_ONCE 1; do $(TEMP_RUN_DO)"
else
	@vsim.exe -gui -l $(LOG_FILE) -do "set SKIP_COMPILE_ONCE 1; do $(TEMP_RUN_DO)"
endif
	@rm -f $(TEMP_RUN_DO)

# =============================================================================
# Clean targets
# =============================================================================
clean:
	@echo "=========================================="
	@echo "Cleaning simulation artifacts..."
	@rm -rf wlf* vsim* *.stacktrace tr_db*
	@rm -rf modelsim.ini_new
	@rm -rf certe_dump.xml
	@rm -f transcript vsim.wlf modelsim.ini run_*.do vsim_stacktrace.vstf
	@pkill -9 vsim.exe 2>/dev/null || true
	@echo "→ Removed simulator artifacts (Work/Logs/Cov preserved)"
	@echo "=========================================="

cleanall:
	@echo "=========================================="
	@echo "Cleaning ALL artifacts..."
	@rm -rf wlf* vsim* *.stacktrace tr_db*
	@rm -rf modelsim.ini_new
	@rm -rf certe_dump.xml
	@rm -f transcript vsim.wlf modelsim.ini run_*.do vsim_stacktrace.vstf
	@rm -rf $(WORK_DIR) out/
	@pkill -9 vsim.exe 2>/dev/null || true
	@echo "→ Removed everything including work library, logs, and coverage"
	@echo "=========================================="

help:
	@echo "=========================================="
	@echo "UCIE System-Level Simulation Makefile"
	@echo "=========================================="
	@echo ""
	@echo "TARGETS:"
	@echo "  make full         - Compile the design and then run the simulation"
	@echo "  make [run]        - Compile (if needed) and run simulation (default)"
	@echo "  make compile      - Compile and elaborate only (produces opt_ucie_tb_top)"
	@echo "  make run          - Run simulation (checks opt image exists)"
	@echo "  make rerun        - Fast rerun (no checks, skips validation)"
	@echo "  make clean        - Remove simulator artifacts (keeps work & logs)"
	@echo "  make cleanall     - Remove ALL files including work/ and logs"
	@echo "  make help         - Display this help message"
	@echo ""
	@echo "VARIABLES:"
	@echo "  TEST              - UVM test name (Default: ucie_sanity_test)"
	@echo "  VERBOSITY         - UVM verbosity (Default: UVM_MEDIUM)"
	@echo "  SEED              - Random seed (Default: random)"
	@echo "  TIMEOUT           - UVM timeout in ms (Default: 100)"
	@echo "  GUI=1/0           - Enable/disable GUI (Default: 1)"
	@echo "  RUN_ID            - Run identifier for logs (Default: 1)"
	@echo ""
	@echo "USAGE EXAMPLES:"
	@echo "  make"
	@echo "  make GUI=0"
	@echo "  make TEST=ucie_error_test GUI=0 VERBOSITY=UVM_HIGH"
	@echo "  make compile && make run TEST=ucie_loopback_test"
	@echo "  make rerun TEST=ucie_sanity_test SEED=12345"
	@echo "=========================================="