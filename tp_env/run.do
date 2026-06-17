vlib work
vlog -sv -suppress 7033 -l compile.log \
  packages/tx_defs_pkg.sv \
  ref_model/B2L_modelling.sv \
  ref_model/LFSR_modelling.sv \
  ref_model/per_lane_id_modelling.sv \
  ref_model/reversal_modelling.sv \
  ref_model/TX_controller_modelling.sv \
  interfaces/*.sv \
  packages/tx_tb_pkg.sv \
  tx_path/synchonizer.sv \
  tx_path/ucie_mux_4_to_1.sv \
  tx_path/ucie_shift_register_b2l.sv \
  tx_path/ucie_byte_to_lane_decoder.sv \
  tx_path/lane_id_register.sv \
  tx_path/mux_2_1.sv \
  tx_path/reversal.sv \
  tx_path/clock_divider.sv \
  tx_path/LFSR_pattern_generator.sv \
  tx_path/tx_LFSR.sv \
  tx_path/tx_LFSR_top.sv \
  tx_path/fifo.sv \
  tx_path/serializer.sv \
  tx_path/empty_decoder.sv \
  tx_path/pattern_generation_decoder.sv \
  tx_path/clk_valid_pattern_generation.sv \
  tx_path/drivers.sv \
  tx_path/ucie_byte_to_lane.sv \
  tx_path/tx_controller.sv \
  tx_path/tx_path.sv \
  tx_path/per_lane_id_generator_top.svh \
  assertions/tx_sva.sv \
  top/tx_dut_rtl_wrapper.sv \
  top/tx_tb_top.sv \
  +incdir+tx_path \
  +incdir+packages \
  +incdir+interfaces \
  +incdir+seq_items \
  +incdir+seq_lib \
  +incdir+agents/rdi_agent \
  +incdir+agents/ltsm_agent \
  +incdir+agents/tx2link_agent \
  +incdir+ref_model \
  +incdir+scoreboard \
  +incdir+coverage \
  +incdir+env \
  +incdir+tests
vopt +acc tx_tb_top -o opt_tx_tb_top
vsim -suppress 7033 opt_tx_tb_top -classdebug -l log.log -c +UVM_TESTNAME=tx_smoke_test
# Add waves for the 3 interfaces
add wave -group "RDI Interface" -position insertpoint sim:/tx_tb_top/rdi_intf/*
add wave -group "LTSM Interface" -position insertpoint sim:/tx_tb_top/ltsm_intf/*
add wave -group "TX2LINK Interface" -position insertpoint  \
sim:/tx_tb_top/tx2link_intf/clk \
sim:/tx_tb_top/tx2link_intf/rst \
sim:/tx_tb_top/tx2link_intf/tx_clkn \
sim:/tx_tb_top/tx2link_intf/tx_clkp \
sim:/tx_tb_top/tx2link_intf/tx_data \
sim:/tx_tb_top/tx2link_intf/tx_track \
sim:/tx_tb_top/tx2link_intf/tx_valid \
sim:/tx_tb_top/tx2link_intf/ui_clk

add wave -position insertpoint  \
sim:/tx_tb_top/dut_rtl/tx_path_dut/done_result \
sim:/tx_tb_top/dut_rtl/tx_path_dut/empty_result \
sim:/tx_tb_top/dut_rtl/tx_path_dut/no_data \
sim:/tx_tb_top/dut_rtl/tx_path_dut/pattern_type_sync

add wave /tx_tb_top/sva_inst/clkp_assertion
add wave /tx_tb_top/sva_inst/clkn_assertion /tx_tb_top/sva_inst/valid_assertion

# Run simulation
run

add wave -position insertpoint  \
sim:/@tx_scoreboard@1
add wave -position insertpoint  \
sim:/@tx2link_monitor@1
add wave -position insertpoint  \
sim:/@rdi_monitor@1

add wave -position insertpoint  \
sim:/tx_tb_top/sva_inst/counter

run -all