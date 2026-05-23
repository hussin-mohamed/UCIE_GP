if [file exists work] {vdel -all -lib work}
vlib work
vlog -sv tb/packages/tx_defs_pkg.sv tb/ref_model/B2L_modelling.sv tb/ref_model/LFSR_modelling.sv tb/ref_model/per_lane_id_modelling.sv tb/ref_model/TX_controller_modelling.sv tb/packages/tx_tb_pkg.sv tb/ref_model/dut_copy/dut_B2L_modelling.sv tb/ref_model/dut_copy/dut_LFSR_modelling.sv tb/ref_model/dut_copy/dut_per_lane_id_modelling.sv tb/ref_model/dut_copy/dut_TX_controller_modelling.sv tb/ref_model/dut_copy/dut_tx_tb_pkg.sv tb/interfaces/*.sv tb/assertions/tx_sva.sv tb/top/model_dut_stub.sv tb/top/tx_tb_top.sv +incdir+tb/packages +incdir+tb/interfaces +incdir+tb/seq_items +incdir+tb/seq_lib +incdir+tb/agents/rdi_agent +incdir+tb/agents/ltsm_agent +incdir+tb/agents/tx2link_agent +incdir+tb/ref_model +incdir+tb/ref_model/dut_copy +incdir+tb/scoreboard +incdir+tb/coverage +incdir+tb/env +incdir+tb/tests -l compile.log
vopt +acc tx_tb_top -o opt_tx_tb_top

# Run vsim without -c to open in GUI, and don't automatically quit
vsim -onfinish stop opt_tx_tb_top +UVM_TESTNAME=tx_smoke_test -classdebug -l log.log

# Add waves for the 3 interfaces
add wave -group "RDI Interface" -position insertpoint sim:/tx_tb_top/rdi_intf/*
add wave -group "LTSM Interface" -position insertpoint sim:/tx_tb_top/ltsm_intf/*
add wave -group "TX2LINK Interface" -position insertpoint sim:/tx_tb_top/tx2link_intf/*
add wave -position insertpoint  \
sim:/LFSR_modelling_pkg::LFSR_modelling/i_data_in \
sim:/LFSR_modelling_pkg::LFSR_modelling/i_enable \
sim:/LFSR_modelling_pkg::LFSR_modelling/i_load \
sim:/LFSR_modelling_pkg::LFSR_modelling/i_train \
sim:/LFSR_modelling_pkg::LFSR_modelling/lfsr_reg \
sim:/LFSR_modelling_pkg::LFSR_modelling/o_data_out

# Run simulation
run

add wave -position insertpoint  \
sim:/@tx_scoreboard@1

run -all
