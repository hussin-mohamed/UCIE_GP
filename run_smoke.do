vlib work
vlog -sv tb/packages/tx_defs_pkg.sv tb/packages/tx_tb_pkg.sv tb/interfaces/*.sv tb/assertions/tx_sva.sv tb/top/tx_tb_top.sv +incdir+tb/packages +incdir+tb/interfaces +incdir+tb/seq_items +incdir+tb/seq_lib +incdir+tb/agents/rdi_agent +incdir+tb/agents/ltsm_agent +incdir+tb/agents/tx2link_agent +incdir+tb/ref_model +incdir+tb/scoreboard +incdir+tb/coverage +incdir+tb/env +incdir+tb/tests
vopt +acc tx_tb_top -o opt_tx_tb_top

# Run vsim without -c to open in GUI, and don't automatically quit
vsim -onfinish stop opt_tx_tb_top +UVM_TESTNAME=tx_smoke_test

# Add waves for the 3 interfaces
add wave -group "RDI Interface" -position insertpoint sim:/tx_tb_top/rdi_intf/*
add wave -group "LTSM Interface" -position insertpoint sim:/tx_tb_top/ltsm_intf/*
add wave -group "TX2LINK Interface" -position insertpoint sim:/tx_tb_top/tx2link_intf/*

# Run simulation
run -all
