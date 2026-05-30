# =============================================================================
# File       : sim_only.do
# Description: Simulate only (assumes compile_only.do or run.do was run first).
#
# Usage (from UCIE_top_env/sim):
#   vsim -c -do sim_only.do
#   vsim -c -do "set UVM_TESTNAME ucie_sanity_test; do sim_only.do"
#
# Optional Tcl variables:
#   UVM_TESTNAME  - default: ucie_base_test
# =============================================================================

if {![info exists UVM_TESTNAME]} {
    set UVM_TESTNAME ucie_base_test
}

if {![file exists work/_info]} {
    echo "ERROR: work/ library not found. Run compile_only.do (or run.do) first."
    quit -code 1
}

vmap work work

if {![file exists work/opt_ucie_tb_top]} {
    echo "WARNING: opt_ucie_tb_top not found, running vopt..."
    vopt +acc ucie_tb_top -o opt_ucie_tb_top
}

echo "Running test: $UVM_TESTNAME"

vsim -c opt_ucie_tb_top -classdebug \
    +UVM_TESTNAME=$UVM_TESTNAME -do "run -all; quit"
