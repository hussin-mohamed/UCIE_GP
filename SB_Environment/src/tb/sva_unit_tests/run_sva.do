# ====================================================================
# File: run_sva.do
# Description: Compile and run SVAUnit tests safely on Modern Linux
# ====================================================================

if {![info exists env(SVAUNIT_HOME)]} {
    echo "ERROR: SVAUNIT_HOME environment variable is not set."
    quit
}
set SVAUNIT_HOME $env(SVAUNIT_HOME)

set WORK_DIR /tmp/$env(USER)_sva_work
if {[file exists $WORK_DIR]} {
    vdel -lib $WORK_DIR -all
}
vlib $WORK_DIR
vmap work $WORK_DIR

# --- Compile SystemVerilog AND C++ DPI Code ---
echo "--- Compiling SystemVerilog Design and Testbench ---"
# Added -mfcu to merge compilation scopes so the UVM Factory can see the test class!
vlog -mfcu -ccflags "-fPIC" -sv -timescale "1ns/1ns" \
  +incdir+$SVAUNIT_HOME/sv \
  $SVAUNIT_HOME/sv/svaunit_vpi_api.cpp \
  $SVAUNIT_HOME/sv/svaunit_pkg.sv \
  $SVAUNIT_HOME/sv/svaunit_vpi_interface.sv \
  *.sv \

# --- Load Simulation ---
echo "--- Loading Simulation ---"
vsim -assertdebug -ldflags "-B/usr/bin/" -voptargs="-assertdebug +acc=npr" tb_top +UVM_TESTNAME=real_pat_gen_test +UVM_TIMEOUT=50000000ns,YES

set NoQuitOnFinish 1

# --- Setup Waveforms ---
add wave -position insertpoint sim:/tb_top/dut_if/*
add wave -position insertpoint sim:/tb_top/dut_if/ap_pat_gen
add wave -position insertpoint sim:/tb_top/dut_if/ap_pat_low
add wave -position insertpoint sim:/tb_top/dut_if/ap_clk_gen
add wave -position insertpoint sim:/tb_top/dut_if/ap_clk_low
add wave -position insertpoint sim:/tb_top/dut_if/chk_async_reset
add wave -radix unsigned -position insertpoint sim:/tb_top/dut_if/tms
# add wave -position insertpoint sim:/tb_top/dut_if/ap_ready_after_det
.vcop Action toggleleafnames

# --- Run Simulation ---
echo "--- Running Simulation ---"
run -all
wave zoom full