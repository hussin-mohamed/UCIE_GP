# ============================================================================
# QuestaSim Makefile for L2B RTL Unit Test
# ============================================================================

# Define Executables (with .exe to avoid MINGW/Windows pathing errors)
VLIB = vlib.exe
VMAP = vmap.exe
VLOG = vlog.exe
VSIM = vsim.exe

# Top-level testbench module name
TB_NAME = tb_ucie_lane_to_byte

# Source Files Mapping
# NOTE: The Package MUST be compiled before the testbench that imports it!
PKG_SRC = b2l_pkg.sv

# RTL Files (Can be compiled together or using a wildcard like rtl/*.sv)
RTL_SRC = rtl/ucie_shift_register.sv \
					rtl/ucie_lane_to_byte_decoder.sv \
					rtl/ucie_mux_2_to_1.sv \
					rtl/ucie_reordering_block.sv \
					rtl/ucie_lane_to_byte.sv

# Testbench File
TB_SRC  = tb_ucie_lane_to_byte.svh

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