# Makefile for Simulation Control (Sideband Environment)
# ================================================================
# Variables:
#   SIM      : Simulator to use: 'questa' or 'xcelium' (default: questa)
#   TEST     : UVM Test name to run (default: sb_test_base)
#   VERBOSITY: UVM verbosity level (default: UVM_MEDIUM)
#   SEED     : Random seed for simulation (default: random)
#   GUI=1/0  : Enable/disable GUI mode (default: 1)
#   COVERAGE=1/0 : Enable/disable coverage collection (default: 1)
#
# Examples:
#   make                                      - Run base test in Questa (GUI + Cov)
#   make SIM=xcelium                          - Run base test in Xcelium (GUI + Cov)
#   make SIM=xcelium TEST=sb_error_test GUI=0 - Run error test in Xcelium (Batch)
# ================================================================

# Default settings
SIM       ?= questa
GUI       ?= 1
COVERAGE  ?= 1
TEST      ?= sanity_test
VERBOSITY ?= UVM_MEDIUM
SEED      ?= random

# Export variables so the TCL script (.do file) can read them (Questa flow)
export TEST_NAME = $(TEST)
export UVM_VERB  = $(VERBOSITY)
export SIM_SEED  = $(SEED)

# Explicitly share these variables with Windows executables (WSL Fix)
export WSLENV := $(WSLENV):TEST_NAME/u:UVM_VERB/u:SIM_SEED/u

# Generate date-based filenames
DATE := $(shell date +%Y-%m-%d)
TIME := $(shell date +%H-%M-%S)
LOG_DIR  := log
LOG_FILE := $(LOG_DIR)/$(DATE)_$(TIME)_$(SIM)_$(TEST).log

# Questa File names
DO_FILE = runsim.do
TEMP_DO_FILE = runsim_$(DATE)_$(TIME).do

# Xcelium Argument Building
XRUN_ARGS = -f src_files.f +incdir+../tb -uvm -timescale 1ns/1ns
XRUN_ARGS += +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=$(VERBOSITY) -svseed $(SEED)
XRUN_ARGS += -l $(LOG_FILE)

ifeq ($(GUI),1)
	XRUN_ARGS += -gui -access +rwc
else
	XRUN_ARGS += -access +rwc
endif

ifeq ($(COVERAGE),1)
	XRUN_ARGS += -coverage all -covoverwrite
endif

# Default target
.PHONY: all run clean cleanlog cleanall force-clean help mkdirs lint lint-gui

all: run

# Ensure log directory exists
mkdirs:
	@mkdir -p $(LOG_DIR)

run: mkdirs
	@echo "=========================================="
	@echo "Preparing Sideband Simulation..."
	@echo "Simulator : $(SIM)"
	@echo "Test      : $(TEST)"
	@echo "Verbosity : $(VERBOSITY)"
	@echo "Seed      : $(SEED)"
	@echo "GUI mode  : $(GUI)"
	@echo "Coverage  : $(COVERAGE)"
	@echo "Log file  : $(LOG_FILE)"
	@echo "=========================================="
ifeq ($(SIM),xcelium)
	@echo "→ Starting Xcelium simulation..."
	xrun $(XRUN_ARGS)
else ifeq ($(SIM),questa)
	@cp $(DO_FILE) $(TEMP_DO_FILE)
	
	@echo "→ Injecting variables directly into the script (WSL Fix)..."
	@sed -i 's/\$$env(TEST_NAME)/$(TEST)/g' $(TEMP_DO_FILE)
	@sed -i 's/\$$env(UVM_VERB)/$(VERBOSITY)/g' $(TEMP_DO_FILE)
	@sed -i 's/\$$env(SIM_SEED)/$(SEED)/g' $(TEMP_DO_FILE)

ifeq ($(GUI),0)
	@echo "→ Disabling GUI commands for Questa..."
	@sed -i '/^add wave/s/^/# /' $(TEMP_DO_FILE)
	@sed -i '/^\.vcop Action toggleleafnames/s/^/# /' $(TEMP_DO_FILE)
	@sed -i '/^wave zoom range/s/^/# /' $(TEMP_DO_FILE)
endif
ifeq ($(COVERAGE),0)
	@echo "→ Disabling coverage commands for Questa..."
	@sed -i '/^coverage save/s/^/# /' $(TEMP_DO_FILE)
	@sed -i '/^coverage report/s/^/# /' $(TEMP_DO_FILE)
	@sed -i '/^quit -sim/s/^/# /' $(TEMP_DO_FILE)
	@sed -i '/^vcover report/s/^/# /' $(TEMP_DO_FILE)
endif
	@echo "→ Starting Questa simulation..."
	@echo "=========================================="
ifeq ($(GUI),0)
	@vsim -c -l $(LOG_FILE) -do $(TEMP_DO_FILE)
else
	@vsim -gui -l $(LOG_FILE) -do $(TEMP_DO_FILE)
endif
else
	@echo "ERROR: Invalid simulator chosen ('$(SIM)'). Use SIM=questa or SIM=xcelium."
	@exit 1
endif
	@echo "=========================================="
	@echo "Simulation complete!"
	@echo "Log: $(LOG_FILE)"
	@echo "=========================================="

lint: mkdirs
	@echo "=========================================="
	@echo "Running Cadence HAL UVM Linting via xrun..."
	@echo "=========================================="
	xrun -f src_files.f +incdir+../tb -uvm -hal -timescale 1ns/1ns \
	-halargs "-check off TCLKED,CTLCHR,MAXLEN,NEQPRM,STYVAL,TFARGT" \
	-l $(LOG_DIR)/hal_lint_$(DATE).log
	@echo "=========================================="
	@echo "Linting complete! Report saved to:"
	@echo "$(LOG_DIR)/hal_lint_$(DATE).log"
	@echo "=========================================="

lint-gui:
	@echo "Launching HAL GUI via xrun..."
	xrun -f src_files.f +incdir+../tb -uvm -hal -timescale 1ns/1ns \
	-halargs "-check off TCLKED,CTLCHR,MAXLEN,NEQPRM,STYVAL,TFARGT -gui"

clean:
	@echo "=========================================="
	@echo "Cleaning simulation artifacts..."
	@echo "=========================================="
	@echo "→ Killing any running vsim/xrun processes..."
	@pkill -9 vsim 2>/dev/null || true
	@pkill -9 xrun 2>/dev/null || true
	@pkill -9 xmsim 2>/dev/null || true
	@sleep 0.5
	@echo "→ Attempting to remove work directories..."
	@if [ -d "work/_dpi" ]; then \
		echo "  → Removing DPI files with elevated permissions..."; \
		sudo rm -rf work/_dpi 2>/dev/null || \
		chmod -R 777 work/_dpi 2>/dev/null && rm -rf work/_dpi 2>/dev/null || \
		find work/_dpi -type f -exec sudo rm -f {} \; 2>/dev/null || true; \
	fi
	@sudo rm -rf work/ xcelium.d/ cov_work/ 2>/dev/null || chmod -R 777 work/ xcelium.d/ cov_work/ && rm -rf work/ xcelium.d/ cov_work/ || true
	@[ ! -d "work" ] && echo "  ✓ Removed Questa work/" || echo "  ⚠ Warning: Could not fully remove Questa work/"
	@[ ! -d "xcelium.d" ] && echo "  ✓ Removed Xcelium work (xcelium.d/)" || echo "  ⚠ Warning: Could not fully remove Xcelium work/"
	@rm -f tr_db.log transcript vsim.wlf vsim_stacktrace.vstf && echo "→ Removed Questa logs & DBs" || true
	@rm -f xrun.log xrun.history && echo "→ Removed Xcelium logs & history" || true
	@rm -rf .simvision && echo "→ Removed .simvision directory" || true
	@rm -f certe_dump.xml && echo "→ Removed certe_dump.xml" || true
	@rm -f runsim_*.do && echo "→ Removed dated runsim scripts" || true
	@rm -f *.ucdb *cover_report.txt coverage_rpt.txt && echo "→ Removed coverage reports" || true
	@echo "=========================================="
	@echo "Clean complete!"
	@echo "Note: Log files in log/ are preserved."
	@echo "      Use 'make cleanlog' to remove logs."
	@echo "=========================================="

cleanlog:
	@echo "=========================================="
	@echo "Removing log files..."
	@echo "=========================================="
	@rm -rf $(LOG_DIR)/* && echo "→ Emptying log directory ($(LOG_DIR)/)" || echo "  ⚠ No log files found"
	@echo "=========================================="
	@echo "Log cleanup complete!"
	@echo "=========================================="

cleanall: force-clean

force-clean:
	@echo "=========================================="
	@echo "FORCE CLEANING (with elevated permissions)"
	@echo "=========================================="
	@echo "→ Killing all simulator processes..."
	@sudo pkill -9 vsim 2>/dev/null || pkill -9 vsim 2>/dev/null || true
	@sudo pkill -9 xrun 2>/dev/null || pkill -9 xrun 2>/dev/null || true
	@sudo pkill -9 xmsim 2>/dev/null || pkill -9 xmsim 2>/dev/null || true
	@sleep 1
	@echo "→ Forcefully removing all locked files..."
	@if [ -d "work" ] || [ -d "xcelium.d" ]; then \
		echo "  → Changing permissions..."; \
		sudo chmod -R 777 work/ xcelium.d/ cov_work/ 2>/dev/null || true; \
		echo "  → Removing work directories..."; \
		sudo rm -rf work/ xcelium.d/ cov_work/ .simvision/ 2>/dev/null || true; \
	fi
	@sudo rm -f tr_db.log transcript vsim.wlf vsim_stacktrace.vstf xrun.log xrun.history 2>/dev/null || true
	@sudo rm -f certe_dump.xml runsim_*.do *.ucdb *cover_report.txt coverage_rpt.txt 2>/dev/null || true
	@rm -f tr_db.log transcript vsim.wlf vsim_stacktrace.vstf xrun.log xrun.history 2>/dev/null || true
	@rm -f certe_dump.xml runsim_*.do *.ucdb *cover_report.txt coverage_rpt.txt 2>/dev/null || true
	@[ ! -d "work" ] && [ ! -d "xcelium.d" ] && echo "  ✓ Successfully removed all files" || echo "  ⚠ Some files may still be locked"
	@echo "=========================================="
	@echo "Force clean complete!"
	@echo "=========================================="

help:
	@echo "=========================================="
	@echo "Simulation Makefile (Questa & Xcelium)"
	@echo "=========================================="
	@echo ""
	@echo "TARGETS:"
	@echo "  make [run]       - Run simulation (default target)"
	@echo "  make lint        - Run HAL methodology linting (Batch)"
	@echo "  make lint-gui    - Run HAL methodology linting (GUI)"
	@echo "  make clean       - Remove simulation artifacts (keeps logs)"
	@echo "  make cleanlog    - Remove ONLY log files"
	@echo "  make cleanall    - Force remove ALL files including locks"
	@echo "  make help        - Display this help message"
	@echo ""
	@echo "VARIABLES:"
	@echo "  SIM              - Simulator: 'questa' or 'xcelium' (Default: questa)"
	@echo "  TEST             - UVM test name (Default: sb_test_base)"
	@echo "  VERBOSITY        - UVM verbosity (Default: UVM_MEDIUM)"
	@echo "  SEED             - Random seed (Default: random)"
	@echo "  GUI=1/0          - Enable/disable GUI (Default: 1)"
	@echo "  COVERAGE=1/0     - Enable/disable coverage (Default: 1)"
	@echo ""
	@echo "USAGE EXAMPLES:"
	@echo "  make"
	@echo "  make SIM=xcelium"
	@echo "  make SIM=xcelium TEST=sb_error_test GUI=0"
	@echo "  make SIM=questa TEST=sb_loopback_test VERBOSITY=UVM_HIGH SEED=12345"
	@echo "=========================================="