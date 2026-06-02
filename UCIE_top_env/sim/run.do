# =============================================================================
# File       : run.do
# Description: Run simulation (assumes compile was done via Makefile)
#
# This script is called by the Makefile with environment variables set.
# Do NOT call this directly - use 'make run' instead.
# =============================================================================

# Read parameters from environment (set by Makefile)
set TEST_NAME      $env(TEST_NAME)
set UVM_VERB       $env(UVM_VERB)
set SIM_SEED       $env(SIM_SEED)
set UVM_TIMEOUT    $env(UVM_TIMEOUT)
set WORK_DIR       "__WORK_DIR__"

# Validate required parameters
if {![info exists TEST_NAME]} {
    puts "ERROR: TEST_NAME not set. Use via Makefile: 'make run TEST=...'"
    quit -code 1
}

# Check for opt image existence (skip this check for 'make rerun')
proc check_for_opt_image {} {
    global WORK_DIR
    set opt_path "$WORK_DIR/opt_ucie_tb_top"
    if {![file exists $opt_path]} {
        puts "ERROR: opt_ucie_tb_top not found at $opt_path"
        puts "Please run 'make compile' first."
        quit -code 1
    }
}

check_for_opt_image

# Map work library
vmap work $WORK_DIR

puts "=========================================="
puts "Starting UCIE System-Level Simulation"
puts "=========================================="
puts "Test      : $TEST_NAME"
puts "Verbosity : $UVM_VERB"
puts "Seed      : $SIM_SEED"
puts "Timeout   : $UVM_TIMEOUT ms"
puts "Work Dir  : $WORK_DIR"
puts "=========================================="

# Launch simulation
vsim $WORK_DIR/opt_ucie_tb_top -classdebug \
    +UVM_TESTNAME=$TEST_NAME \
    +UVM_VERBOSITY=$UVM_VERB \
    +UVM_NO_RELNOTES \
    +UVM_TIMEOUT=$UVM_TIMEOUT,YES \
    -sv_seed $SIM_SEED

# Configure wave display if in GUI mode (waves.do included below)
# This line will be commented out by sed when GUI=0
do waves.do

# Run simulation
run -all

# When GUI mode, keep simulation running. In batch mode, quit automatically.
# (vsim -c automatically exits after run -all completes)
