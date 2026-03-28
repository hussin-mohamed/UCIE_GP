vlib work
vlog -f src_files.f -mfcu +cover +define+SIM
vsim -voptargs=+acc -nodpiexports work.baud_gen_tb

add wave -position insertpoint  \
-color red  sim:/baud_gen_tb/clk \
-color red  sim:/baud_gen_tb/reset_n \
-color cyan sim:/baud_gen_tb/divisor \
			sim:/baud_gen_tb/tick

.vcop Action toggleleafnames

run -all