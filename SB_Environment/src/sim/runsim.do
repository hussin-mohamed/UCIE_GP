vlib work
vlog -f src_files.f -mfcu +cover +define+SIM
vsim -voptargs=+acc work.bridge_top -classdebug -uvmcontrol=all -cover +UVM_VERBOSITY=UVM_MEDIUM +UVM_NO_RELNOTES +UVM_TESTNAME=bridge_test_base
set NoQuitOnFinish 1

# AES Bridge clock & reset
add wave -group Global_Signals -position insertpoint  \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/PCLK \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/PRESETn

# APB_1 input signals
add wave -group APB_1 -position insertpoint  \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/PSELx_1 \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/PADDR_1 \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/PWRITE_1 \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/PSTRB_1 \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/PWDATA_1 \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/PENABLE_1 \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/PRDATA_1 \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/PREADY_1

# APB_2 input signals
add wave -group APB_2 -position insertpoint  \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/PSELx_2 \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/PADDR_2 \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/PWRITE_2 \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/PSTRB_2 \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/PWDATA_2 \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/PENABLE_2 \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/PRDATA_2 \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/PREADY_2

# MUX_inst_1 (APB1 external vs master)
add wave -group MUX_1 -position insertpoint  \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/MUX_inst_1/sel \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/MUX_inst_1/ina \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/MUX_inst_1/inb \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/MUX_inst_1/out

# pos_edge_det_inst_1 & _inst_2 (start detectors)
add wave -group Edge_Detectors -position insertpoint  \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/pos_edge_det_inst_1/sig \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/pos_edge_det_inst_1/pe \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/pos_edge_det_inst_2/sig \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/pos_edge_det_inst_2/pe

# add wave -group APB_Controller_1_if -position insertpoint  \
#     sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Controller_inst_1/apb_ctrl_if_1/*

# APB_Controller_inst_1
add wave -group APB_Controller_1 -position insertpoint  \
	sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Controller_inst_1/PCLK \
	sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Controller_inst_1/PRESETn \
	sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Controller_inst_1/start \
	sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Controller_inst_1/start_addr \
	sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Controller_inst_1/valid
add wave -group APB_Controller_1 -color cyan -position insertpoint  \
	sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Controller_inst_1/state_next \
	sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Controller_inst_1/state_reg
add wave -group APB_Controller_1 -position insertpoint  \
	sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Controller_inst_1/addr \
	sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Controller_inst_1/transfer \
	sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Controller_inst_1/write \
	sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Controller_inst_1/byte_strobe \
	sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Controller_inst_1/rdata \
	sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Controller_inst_1/concat_out \
	sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Controller_inst_1/concat_done

# APB_Master_inst_1
add wave -group APB_Master_1 -position insertpoint  \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Master_inst_1/addr \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Master_inst_1/transfer \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Master_inst_1/write \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Master_inst_1/byte_strobe \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Master_inst_1/wdata \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Master_inst_1/rdata
add wave -group APB_Master_1 -color cyan -position insertpoint  \
	sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Master_inst_1/state_next \
	sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Master_inst_1/state_reg
add wave -group APB_Master_1 -position insertpoint  \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Master_inst_1/PSELx \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Master_inst_1/PENABLE \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Master_inst_1/PWRITE \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Master_inst_1/PSTRB \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Master_inst_1/PADDR \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Master_inst_1/PWDATA \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Master_inst_1/PRDATA \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Master_inst_1/PREADY \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Master_inst_1/transfer_done

# APB_RegFile_Wrapper_inst_1
add wave -group APB_RegFile_Wrapper_1 -position insertpoint  \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_1/PSELx \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_1/PADDR \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_1/PWRITE \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_1/PSTRB \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_1/PWDATA \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_1/PENABLE \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_1/PRDATA \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_1/PREADY \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_1/APB_Slave_inst/next_state \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_1/APB_Slave_inst/current_state \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_1/RegisterFile_inst/* 

# AES_Encrypt_inst
add wave -group AES -position  insertpoint  \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/AES_Encrypt_inst/in \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/AES_Encrypt_inst/key \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/AES_Encrypt_inst/out

# MUX_inst_2 (AES vs concat)
add wave -group MUX_2 -position  insertpoint  \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/MUX_inst_2/sel \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/MUX_inst_2/ina \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/MUX_inst_2/inb \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/MUX_inst_2/out

 # UART_Controller_inst
add wave -group UART_Controller -position  insertpoint  \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/UART_Controller_inst/clk \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/UART_Controller_inst/reset_n \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/UART_Controller_inst/start \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/UART_Controller_inst/ready \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/UART_Controller_inst/in \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/UART_Controller_inst/write_uart \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/UART_Controller_inst/out

# UART_inst (transmitter)
add wave -group UART -position  insertpoint  \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/UART_inst/clk \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/UART_inst/reset_n \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/UART_inst/fifo_inst/empty \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/UART_inst/transmitter_inst/tx_start \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/UART_inst/transmitter_inst/state_next \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/UART_inst/transmitter_inst/state_reg \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/UART_inst/transmitter_inst/data_in \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/UART_inst/transmitter_inst/tx_next \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/UART_inst/transmitter_inst/tx_reg \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/UART_inst/wren \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/UART_inst/w_data \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/UART_inst/tx_full \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/UART_inst/transmitter_inst/dcount_reg \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/UART_inst/tx \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/UART_inst/transmitter_inst/tx_done \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/count \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/req \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/UART_inst/fifo_inst/r_file_unit/memory

# MUX_inst_3 (APB2 external vs master)
add wave -group MUX_3 -position insertpoint  \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/MUX_inst_3/sel \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/MUX_inst_3/ina \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/MUX_inst_3/inb \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/MUX_inst_3/out

# APB_Controller_inst_2 (channel 2)
add wave -group APB_Controller_2 -position insertpoint  \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Controller_inst_2/PCLK \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Controller_inst_2/PRESETn \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Controller_inst_2/start \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Controller_inst_2/start_addr \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Controller_inst_2/valid \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Controller_inst_2/addr \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Controller_inst_2/transfer \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Controller_inst_2/write \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Controller_inst_2/byte_strobe \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Controller_inst_2/rdata \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Controller_inst_2/concat_out \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Controller_inst_2/concat_done

# APB_Master_inst_2
add wave -group APB_Master_2 -position insertpoint  \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Master_inst_2/PSELx \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Master_inst_2/PENABLE \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Master_inst_2/PWRITE \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Master_inst_2/PSTRB \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Master_inst_2/PADDR \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Master_inst_2/PWDATA \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Master_inst_2/PRDATA \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Master_inst_2/PREADY \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Master_inst_2/addr \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Master_inst_2/transfer \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Master_inst_2/write \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Master_inst_2/byte_strobe \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Master_inst_2/wdata \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Master_inst_2/rdata \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_Master_inst_2/transfer_done

# Registers of REGFILE_1
add wave -group Registers_1 -position insertpoint  \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_1/RegisterFile_inst/SYS_STATUS_REG \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_1/RegisterFile_inst/INT_CTRL_REG \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_1/RegisterFile_inst/DEV_ID_REG \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_1/RegisterFile_inst/MEM_CTRL_REG \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_1/RegisterFile_inst/TEMP_SENSOR_REG \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_1/RegisterFile_inst/ADC_CTRL_REG \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_1/RegisterFile_inst/DBG_CTRL_REG \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_1/RegisterFile_inst/GPIO_DATA_REG \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_1/RegisterFile_inst/DAC_OUTPUT_REG \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_1/RegisterFile_inst/VOLTAGE_CTRL_REG \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_1/RegisterFile_inst/CLK_CONFIG_REG \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_1/RegisterFile_inst/TIMER_COUNT_REG \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_1/RegisterFile_inst/INPUT_DATA_REG \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_1/RegisterFile_inst/OUTPUT_DATA_REG \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_1/RegisterFile_inst/DMA_CTRL_REG \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_1/RegisterFile_inst/SYS_CTRL_REG

# Registers of REGFILE_2
add wave -group Registers_2 -position insertpoint  \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_2/RegisterFile_inst/SYS_STATUS_REG \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_2/RegisterFile_inst/INT_CTRL_REG \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_2/RegisterFile_inst/DEV_ID_REG \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_2/RegisterFile_inst/MEM_CTRL_REG \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_2/RegisterFile_inst/TEMP_SENSOR_REG \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_2/RegisterFile_inst/ADC_CTRL_REG \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_2/RegisterFile_inst/DBG_CTRL_REG \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_2/RegisterFile_inst/GPIO_DATA_REG \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_2/RegisterFile_inst/DAC_OUTPUT_REG \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_2/RegisterFile_inst/VOLTAGE_CTRL_REG \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_2/RegisterFile_inst/CLK_CONFIG_REG \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_2/RegisterFile_inst/TIMER_COUNT_REG \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_2/RegisterFile_inst/INPUT_DATA_REG \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_2/RegisterFile_inst/OUTPUT_DATA_REG \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_2/RegisterFile_inst/DMA_CTRL_REG \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_2/RegisterFile_inst/SYS_CTRL_REG

# APB_RegFile_Wrapper_inst_2
add wave -group APB_RegFile_Wrapper_2 -position insertpoint  \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_2/PSELx \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_2/PADDR \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_2/PWRITE \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_2/PSTRB \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_2/PWDATA \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_2/PENABLE \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_2/PRDATA \
    sim:/bridge_top/AES_APB_UART_Bridge_inst/APB_RegFile_Wrapper_inst_2/PREADY

.vcop Action toggleleafnames
wave zoom range 0ns 26ns

coverage save bridge_tb.ucdb -onexit -du AES_APB_UART_Bridge
run -all

coverage report -detail -cvg -directive -comments -output seqcover_report.txt /.
coverage report -detail -cvg -directive -comments -output fcover_report.txt {}
quit -sim
vcover report bridge_tb.ucdb -details -annotate -all -output coverage_rpt.txt
