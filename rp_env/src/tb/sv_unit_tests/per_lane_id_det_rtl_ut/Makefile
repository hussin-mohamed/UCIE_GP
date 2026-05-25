# ============================================================================
# QuestaSim Makefile for Per-Lane ID Detector RTL Unit Testbench
# ============================================================================

# Define Executables (with .exe to avoid MINGW/Windows pathing errors)
VLIB = vlib.exe
VMAP = vmap.exe
VLOG = vlog.exe
VSIM = vsim.exe

# Top-level testbench module name
TB_NAME = tb_per_lane_id_detector

# Source Files Mapping
# NOTE: The Package MUST be compiled before the testbench that imports it!
PKG_SRC = per_lane_id_detector_pkg.sv

# RTL Files (Can be compiled together or using a wildcard like rtl/*.sv)
RTL_SRC = rtl/counter_compare.sv \
					rtl/lane_id_register.sv \
					rtl/per_lane_id_detector.sv \
					rtl/per_lane_id_detector_top.svh

# Testbench File
TB_SRC  = tb_per_lane_id_detector.svh

# ============================================================================
# Targets
# ============================================================================

# Default target runs the command-line simulation
all: clean compile sim

# 1. Create the work library
work:
	$(VLIB) work
	$(VMAP) work work

# 2. Compile the SystemVerilog source files in order
compile: work
	$(VLOG) -sv $(PKG_SRC)
	$(VLOG) -sv $(RTL_SRC)
	$(VLOG) -sv $(TB_SRC)

# 3. Run simulation in Command-Line (CLI) mode
# Best for quick pass/fail checks
sim: compile
	$(VSIM) -c -voptargs=+acc work.$(TB_NAME) -do "run -all; quit"

# 4. Run simulation in GUI mode
# Opens the Questa window and automatically adds signals to the wave
sim-gui: compile
	$(VSIM) -voptargs=+acc work.$(TB_NAME) -do "view wave; add wave -r /*; run -all"

# 5. Clean up compiled libraries and log files
clean:
	rm -rf work transcript vsim.wlf *.log modelsim.ini