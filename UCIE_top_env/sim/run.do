# =============================================================================
# File       : run.do
# =============================================================================

# Read parameters from environment (injected by Makefile)
set TEST_NAME       $env(TEST_NAME)
set UVM_VERB        $env(UVM_VERB)
set SIM_SEED        $env(SIM_SEED)
set UVM_TIMEOUT     $env(UVM_TIMEOUT)
set ENABLE_COVERAGE $env(ENABLE_COVERAGE)
set WORK_DIR        "__WORK_DIR__"

# Export coverage variables into the local Tcl environment so coverage.do can read them
set env(COV_DB_NAME)       "$env(COV_DB_NAME)"
set env(COV_TXT_NAME)      "$env(COV_TXT_NAME)"
set env(COV_FUNC_TXT_NAME) "$env(COV_FUNC_TXT_NAME)"
set env(COV_CODE_HTML)     "$env(COV_CODE_HTML)"
set env(COV_FUNC_HTML)     "$env(COV_FUNC_HTML)"

# Validate required parameters
if {![info exists TEST_NAME]} {
    puts "ERROR: TEST_NAME not set."
    quit -code 1
}

proc check_for_opt_image {} {
    global WORK_DIR
    set opt_path "$WORK_DIR/opt_ucie_tb_top"
    if {![file exists $opt_path]} {
        puts "ERROR: opt_ucie_tb_top not found at $opt_path"
        quit -code 1
    }
}

check_for_opt_image
vmap work $WORK_DIR

puts "=========================================="
puts "Starting UCIE System-Level Simulation"
puts "=========================================="
puts "Test      : $TEST_NAME"
puts "Coverage  : $ENABLE_COVERAGE"
puts "=========================================="

# -----------------------------------------------------------------------------
# CONDITIONAL COMPILATION BLOCK
# -----------------------------------------------------------------------------
if {[info exists SKIP_COMPILE_ONCE] && $SKIP_COMPILE_ONCE == 1} {
    puts "--- Make already compiled the design. Skipping GUI compilation... ---"
    set SKIP_COMPILE_ONCE 0
} else {
    puts "--- Recompiling from within GUI... ---"
    do compile.do    
}

# -----------------------------------------------------------------------------
# LAUNCH SIMULATION
# -----------------------------------------------------------------------------
if {$ENABLE_COVERAGE == 1} {
    vsim opt_ucie_tb_top -nodpiexports -uvmcontrol=all -classdebug -cover \
        +UVM_TESTNAME=$TEST_NAME \
        +UVM_VERBOSITY=$UVM_VERB \
        +UVM_NO_RELNOTES \
        +UVM_TIMEOUT=$UVM_TIMEOUT,YES \
        -sv_seed $SIM_SEED
} else {
    vsim opt_ucie_tb_top -nodpiexports -uvmcontrol=all -classdebug \
        +UVM_TESTNAME=$TEST_NAME \
        +UVM_VERBOSITY=$UVM_VERB \
        +UVM_NO_RELNOTES \
        +UVM_TIMEOUT=$UVM_TIMEOUT,YES \
        -sv_seed $SIM_SEED
}

# Configure wave display if in GUI mode
do waves.do

# Run simulation or branch to coverage scripts
if {$ENABLE_COVERAGE == 1} {
    do coverage.do
} else {
    run -all
}