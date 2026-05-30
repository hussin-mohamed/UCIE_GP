vlog -sv *.sv

vlib work
vsim  -voptargs=+acc work.tb_tx_path
add wave *
add wave -position insertpoint  \
sim:/tb_tx_path/dut/controller/o_tx_lfsr_enable
add wave -position insertpoint  \
sim:/tb_tx_path/dut/controller/o_tx_lfsr_train
add wave -position insertpoint  \
sim:/tb_tx_path/dut/LFSR/o_data_out
add wave -position insertpoint  \
sim:/tb_tx_path/dut/controller/o_tx_lfsr_load
add wave -position insertpoint  \
sim:/tb_tx_path/dut/controller/o_data_pattern_type \
sim:/tb_tx_path/dut/controller/o_pattern_type
run -all

