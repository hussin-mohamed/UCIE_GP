vlib work
vlog -f src_files.f -mfcu +cover +define+SIM
vsim -voptargs=+acc -nodpiexports work.UART_tb

add wave -position insertpoint  \
-color red  sim:/UART_tb/clk \
-color red  sim:/UART_tb/reset_n \
-color cyan sim:/UART_tb/wren \
sim:/UART_tb/w_data \
sim:/UART_tb/divisor \
-color gold sim:/UART_tb/tx \
-color gold sim:/UART_tb/tx_full

add wave -position insertpoint  \
sim:/UART_tb/UART_inst/din_tx \
sim:/UART_tb/UART_inst/rden_fifo \
sim:/UART_tb/UART_inst/empty_fifo \
sim:/UART_tb/UART_inst/tx_start \
sim:/UART_tb/UART_inst/tick

add wave -position insertpoint  \
sim:/UART_tb/UART_inst/FIFO_inst/clk_a \
sim:/UART_tb/UART_inst/FIFO_inst/clk_b \
sim:/UART_tb/UART_inst/FIFO_inst/reset_n \
-radix binary sim:/UART_tb/UART_inst/FIFO_inst/din_a \
sim:/UART_tb/UART_inst/FIFO_inst/wen_a \
sim:/UART_tb/UART_inst/FIFO_inst/ren_b \
sim:/UART_tb/UART_inst/FIFO_inst/dout_b \
sim:/UART_tb/UART_inst/FIFO_inst/full \
sim:/UART_tb/UART_inst/FIFO_inst/empty \
sim:/UART_tb/UART_inst/FIFO_inst/wr_ptr \
sim:/UART_tb/UART_inst/FIFO_inst/rd_ptr \
sim:/UART_tb/UART_inst/FIFO_inst/fifo

add wave -position insertpoint  \
sim:/UART_tb/UART_inst/transmitter_inst/clk \
sim:/UART_tb/UART_inst/transmitter_inst/reset_n \
sim:/UART_tb/UART_inst/transmitter_inst/tx_start \
-radix binary sim:/UART_tb/UART_inst/transmitter_inst/data_in \
sim:/UART_tb/UART_inst/transmitter_inst/tick \
-color gold sim:/UART_tb/UART_inst/transmitter_inst/tx_next \
-color gold sim:/UART_tb/UART_inst/transmitter_inst/tx \
-radix binary sim:/UART_tb/UART_inst/transmitter_inst/data_reg \
sim:/UART_tb/UART_inst/transmitter_inst/tx_done \
sim:/UART_tb/UART_inst/transmitter_inst/state_reg \
sim:/UART_tb/UART_inst/transmitter_inst/state_next \
-radix unsigned sim:/UART_tb/UART_inst/transmitter_inst/tcount_reg \
-radix unsigned sim:/UART_tb/UART_inst/transmitter_inst/tcount_next \
-radix unsigned sim:/UART_tb/UART_inst/transmitter_inst/dcount_reg \
-radix unsigned sim:/UART_tb/UART_inst/transmitter_inst/dcount_next

.vcop Action toggleleafnames

run -all