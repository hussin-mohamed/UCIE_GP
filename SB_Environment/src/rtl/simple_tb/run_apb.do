vlib work
vlog -f src_files.f -mfcu +define+SIM 
vsim -voptargs=+acc -nodpiexports work.APB_tb

# AES Bridge clock & reset
add wave -group Global_Signals -position insertpoint  \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/PCLK \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/PRESETn

# APB_1 input signals
add wave -group APB_1 -position insertpoint  \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/PSELx_1 \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/PADDR_1 \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/PWRITE_1 \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/PSTRB_1 \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/PWDATA_1 \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/PENABLE_1 \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/PRDATA_1 \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/PREADY_1

# APB_2 input signals
add wave -group APB_2 -position insertpoint  \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/PSELx_2 \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/PADDR_2 \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/PWRITE_2 \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/PSTRB_2 \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/PWDATA_2 \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/PENABLE_2 \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/PRDATA_2 \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/PREADY_2

# MUX_inst_1 (APB1 external vs master)
add wave -group MUX_1 -position insertpoint  \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/MUX_inst_1/sel \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/MUX_inst_1/ina \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/MUX_inst_1/inb \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/MUX_inst_1/out

# pos_edge_det_inst_1 & _inst_2 (start detectors)
add wave -group Edge_Detectors -position insertpoint  \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/pos_edge_det_inst_1/sig \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/pos_edge_det_inst_1/pe \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/pos_edge_det_inst_2/sig \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/pos_edge_det_inst_2/pe

# add wave -group APB_Controller_1_if -position insertpoint  \
#     sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Controller_inst_1/apb_ctrl_if_1/*

# APB_Controller_inst_1
add wave -group APB_Controller_1 -position insertpoint  \
	sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Controller_inst_1/PCLK \
	sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Controller_inst_1/PRESETn \
	sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Controller_inst_1/start \
	sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Controller_inst_1/start_addr \
	sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Controller_inst_1/valid
add wave -group APB_Controller_1 -color cyan -position insertpoint  \
	sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Controller_inst_1/state_next \
	sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Controller_inst_1/state_reg
add wave -group APB_Controller_1 -position insertpoint  \
	sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Controller_inst_1/addr \
	sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Controller_inst_1/transfer \
	sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Controller_inst_1/write \
	sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Controller_inst_1/byte_strobe \
	sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Controller_inst_1/rdata \
	sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Controller_inst_1/concat_out \
	sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Controller_inst_1/concat_done

# APB_Master_inst_1
add wave -group APB_Master_1 -position insertpoint  \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Master_inst_1/addr \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Master_inst_1/transfer \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Master_inst_1/write \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Master_inst_1/byte_strobe \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Master_inst_1/wdata \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Master_inst_1/rdata
add wave -group APB_Master_1 -color cyan -position insertpoint  \
	sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Master_inst_1/state_next \
	sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Master_inst_1/state_reg
add wave -group APB_Master_1 -position insertpoint  \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Master_inst_1/PSELx \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Master_inst_1/PENABLE \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Master_inst_1/PWRITE \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Master_inst_1/PSTRB \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Master_inst_1/PADDR \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Master_inst_1/PWDATA \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Master_inst_1/PRDATA \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Master_inst_1/PREADY \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Master_inst_1/transfer_done

# APB_RegFile_Wrapper_inst_1 (slave 1)
add wave -group APB_RegFile_Wrapper_1 -position insertpoint  \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_1/PSELx \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_1/PADDR \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_1/PWRITE \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_1/PSTRB \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_1/PWDATA \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_1/PENABLE \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_1/PRDATA \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_1/PREADY

# AES_Encrypt_inst
add wave -group AES -position  insertpoint  \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/AES_Encrypt_inst/in \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/AES_Encrypt_inst/key \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/AES_Encrypt_inst/out

# MUX_inst_2 (AES vs concat)
add wave -group MUX_2 -position  insertpoint  \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/MUX_inst_2/sel \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/MUX_inst_2/ina \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/MUX_inst_2/inb \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/MUX_inst_2/out

 # UART_Controller_inst
add wave -group UART_Controller -position  insertpoint  \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/UART_Controller_inst/clk \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/UART_Controller_inst/reset_n \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/UART_Controller_inst/start \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/UART_Controller_inst/ready \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/UART_Controller_inst/in \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/UART_Controller_inst/write_uart \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/UART_Controller_inst/out

# UART_inst (transmitter)
add wave -group UART -position  insertpoint  \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/UART_inst/clk \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/UART_inst/reset_n \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/UART_inst/fifo_inst/empty \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/UART_inst/transmitter_inst/tx_start \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/UART_inst/transmitter_inst/state_next \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/UART_inst/transmitter_inst/state_reg \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/UART_inst/transmitter_inst/data_in \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/UART_inst/transmitter_inst/tx_next \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/UART_inst/transmitter_inst/tx_reg \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/UART_inst/wren \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/UART_inst/w_data \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/UART_inst/tx_full \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/UART_inst/transmitter_inst/dcount_reg \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/UART_inst/tx \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/UART_inst/transmitter_inst/tx_done \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/count \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/req \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/UART_inst/fifo_inst/r_file_unit/memory

# MUX_inst_3 (APB2 external vs master)
add wave -group MUX_3 -position insertpoint  \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/MUX_inst_3/sel \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/MUX_inst_3/ina \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/MUX_inst_3/inb \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/MUX_inst_3/out

# APB_Controller_inst_2 (channel 2)
add wave -group APB_Controller_2 -position insertpoint  \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Controller_inst_2/PCLK \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Controller_inst_2/PRESETn \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Controller_inst_2/start \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Controller_inst_2/start_addr \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Controller_inst_2/valid \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Controller_inst_2/addr \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Controller_inst_2/transfer \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Controller_inst_2/write \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Controller_inst_2/byte_strobe \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Controller_inst_2/rdata \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Controller_inst_2/concat_out \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Controller_inst_2/concat_done

# APB_Master_inst_2
add wave -group APB_Master_2 -position insertpoint  \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Master_inst_2/PSELx \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Master_inst_2/PENABLE \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Master_inst_2/PWRITE \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Master_inst_2/PSTRB \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Master_inst_2/PADDR \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Master_inst_2/PWDATA \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Master_inst_2/PRDATA \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Master_inst_2/PREADY \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Master_inst_2/addr \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Master_inst_2/transfer \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Master_inst_2/write \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Master_inst_2/byte_strobe \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Master_inst_2/wdata \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Master_inst_2/rdata \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_Master_inst_2/transfer_done

# Register
add wave -group Registers -position insertpoint  \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_1/RegisterFile_inst/SYS_STATUS_REG \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_1/RegisterFile_inst/INT_CTRL_REG \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_1/RegisterFile_inst/DEV_ID_REG \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_1/RegisterFile_inst/MEM_CTRL_REG \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_1/RegisterFile_inst/TEMP_SENSOR_REG \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_1/RegisterFile_inst/ADC_CTRL_REG \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_1/RegisterFile_inst/DBG_CTRL_REG \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_1/RegisterFile_inst/GPIO_DATA_REG \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_1/RegisterFile_inst/DAC_OUTPUT_REG \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_1/RegisterFile_inst/VOLTAGE_CTRL_REG \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_1/RegisterFile_inst/CLK_CONFIG_REG \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_1/RegisterFile_inst/TIMER_COUNT_REG \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_1/RegisterFile_inst/INPUT_DATA_REG \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_1/RegisterFile_inst/OUTPUT_DATA_REG \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_1/RegisterFile_inst/DMA_CTRL_REG \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_1/RegisterFile_inst/SYS_CTRL_REG

# APB_RegFile_Wrapper_inst_2 (slave 2)
add wave -group APB_RegFile_Wrapper_2 -position insertpoint  \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_2/PSELx \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_2/PADDR \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_2/PWRITE \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_2/PSTRB \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_2/PWDATA \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_2/PENABLE \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_2/PRDATA \
    sim:/APB_tb/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_2/PREADY


.vcop Action toggleleafnames
run -all
wave zoom range 0ns 26ns