# ============================================================================
# QuestaSim Makefile
# ============================================================================

# Define the top-level testbench module name
TB_NAME = tb_lane2byte

# Define the source files. 
# NOTE: If your package is in a separate file, list it FIRST. 
# Example: SRC_FILES = b2l_pkg.sv tb_lane2byte.sv
SRC_FILES = tb_lane2byte.sv

# ============================================================================
# Targets
# ============================================================================

# Default target runs the command-line simulation
all: clean compile sim

# 1. Create the work library
work:
	vlib.exe work
	vmap.exe work work

# 2. Compile the SystemVerilog source files
compile: work
	vlog.exe -sv $(SRC_FILES)

# 3. Run simulation in Command-Line (CLI) mode
# Best for quick pass/fail checks
sim: compile
	vsim.exe -c -voptargs=+acc work.$(TB_NAME) -do "run -all; quit"

# 4. Run simulation in GUI mode
# Opens the Questa window and automatically adds signals to the wave
sim-gui: compile
	vsim.exe -voptargs=+acc work.$(TB_NAME) -do "view wave; add wave -r /*; run -all"

# 5. Clean up compiled libraries and log files
clean:
	rm -rf work transcript vsim.wlf *.log modelsim.ini