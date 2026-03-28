/***********************************************************************
 * Author : Amr El Batarny
 * File   : APB_tb.sv
 **********************************************************************/

module APB_tb ();

	import shared_pkg::*;

	bit [3:0] tx_done_count;

	Bridge_bfm bridge_bfm();
	bind APB_tb.AES_APB_UART_Bridge_inst.APB_Controller_inst_1 APB_Controller_if apb_ctrl_if_1 (.*);
	bind APB_tb.AES_APB_UART_Bridge_inst.APB_Controller_inst_2 APB_Controller_if apb_ctrl_if_2 (.*);

	AES_APB_UART_Bridge AES_APB_UART_Bridge_inst (
	//--------------------- Clock & Reset ---------------------
	.PCLK(bridge_bfm.PCLK),
	.PRESETn(bridge_bfm.PRESETn),

	//--------------------- MUX Selectors ---------------------
	.sel_1(bridge_bfm.sel_1), .sel_2(bridge_bfm.sel_2), .sel_3(bridge_bfm.sel_3),

	//--------- Starting Address for Writing Operation --------
	.start_addr_1(bridge_bfm.start_addr_1), 	.start_addr_2(bridge_bfm.start_addr_2),
	
	//-------------------- APB Slave Ports --------------------
	.PSELx_1(bridge_bfm.apb_bfm_1.PSELx), 		.PSELx_2(bridge_bfm.apb_bfm_2.PSELx),
	.PADDR_1(bridge_bfm.apb_bfm_1.PADDR), 		.PADDR_2(bridge_bfm.apb_bfm_2.PADDR),
	.PWRITE_1(bridge_bfm.apb_bfm_1.PWRITE), 	.PWRITE_2(bridge_bfm.apb_bfm_2.PWRITE),
	.PSTRB_1(bridge_bfm.apb_bfm_1.PSTRB), 		.PSTRB_2(bridge_bfm.apb_bfm_2.PSTRB),
	.PWDATA_1(bridge_bfm.apb_bfm_1.PWDATA), 	.PWDATA_2(bridge_bfm.apb_bfm_2.PWDATA),
	.PENABLE_1(bridge_bfm.apb_bfm_1.PENABLE), 	.PENABLE_2(bridge_bfm.apb_bfm_2.PENABLE),
	.PRDATA_1(bridge_bfm.apb_bfm_1.PRDATA), 	.PRDATA_2(bridge_bfm.apb_bfm_2.PRDATA),
	.PREADY_1(bridge_bfm.apb_bfm_1.PREADY), 	.PREADY_2(bridge_bfm.apb_bfm_2.PREADY),

	//--------------------- UART Output -----------------------
	.tx(bridge_bfm.tx),	.req(bridge_bfm.req)
	);


	initial begin
		initialize_registers();

		bridge_bfm.reset();
		bridge_bfm.sel_1 = 0;
		bridge_bfm.sel_2 = 0;
		bridge_bfm.sel_3 = 0;
		
		
		@(posedge bridge_bfm.PCLK);
		bridge_bfm.sel_1 = 1;
		bridge_bfm.sel_2 = 0;
		bridge_bfm.sel_3 = 0;

		@(negedge AES_APB_UART_Bridge_inst.UART_inst.transmitter_inst.tx_done); tx_done_count++;
		@(negedge AES_APB_UART_Bridge_inst.UART_inst.transmitter_inst.tx_done); tx_done_count++;
		@(negedge AES_APB_UART_Bridge_inst.UART_inst.transmitter_inst.tx_done); tx_done_count++;
		@(negedge AES_APB_UART_Bridge_inst.UART_inst.transmitter_inst.tx_done); tx_done_count++;
		@(negedge AES_APB_UART_Bridge_inst.UART_inst.transmitter_inst.tx_done); tx_done_count++;

		repeat(5000) @(negedge bridge_bfm.PCLK);

		// @(negedge bridge_bfm.PCLK);
		// PRESETn = 1;
		// transfer		= 1;
		// write			= 1;
		// byte_strobe		= 4'hF;
		// addr			= 32'h0000_0000;
		// wdata			= 32'habcd_1234;
		// @(negedge done);
		// addr			= 32'h0000_0004;
		// wdata			= 32'h5678_ef12;
		// @(negedge done);
		// addr			= 32'h0000_0008;
		// wdata			= 32'h8A0D_3562;
		// @(negedge done);
		// addr			= 32'h0000_000C;
		// wdata			= 32'hF2E3_3196;
		// @(negedge done);
		// write			= 0;
		// addr			= 32'h0000_0000;
		// @(negedge done);
		// addr			= 32'h0000_0004;
		// @(negedge done);
		// addr			= 32'h0000_0008;
		// @(negedge done);
		// addr			= 32'h0000_000C;
		// repeat(5) @(negedge bridge_bfm.PCLK);
		$stop;
	end

	function void initialize_registers();
		force AES_APB_UART_Bridge_inst.APB_RegFile_Wrapper_inst_1.RegisterFile_inst.SYS_STATUS_REG		= 32'habcd1234;
		force AES_APB_UART_Bridge_inst.APB_RegFile_Wrapper_inst_1.RegisterFile_inst.INT_CTRL_REG		= 32'hef133213;
		force AES_APB_UART_Bridge_inst.APB_RegFile_Wrapper_inst_1.RegisterFile_inst.DEV_ID_REG			= 32'h43631435;
		force AES_APB_UART_Bridge_inst.APB_RegFile_Wrapper_inst_1.RegisterFile_inst.MEM_CTRL_REG		= 32'h76575474;
		force AES_APB_UART_Bridge_inst.APB_RegFile_Wrapper_inst_1.RegisterFile_inst.TEMP_SENSOR_REG		= 32'h44776474;
		force AES_APB_UART_Bridge_inst.APB_RegFile_Wrapper_inst_1.RegisterFile_inst.ADC_CTRL_REG		= 32'h37674734;
		force AES_APB_UART_Bridge_inst.APB_RegFile_Wrapper_inst_1.RegisterFile_inst.DBG_CTRL_REG		= 32'h36747474;
		force AES_APB_UART_Bridge_inst.APB_RegFile_Wrapper_inst_1.RegisterFile_inst.GPIO_DATA_REG		= 32'h09249898;
		force AES_APB_UART_Bridge_inst.APB_RegFile_Wrapper_inst_1.RegisterFile_inst.DAC_OUTPUT_REG		= 32'h49710384;
		force AES_APB_UART_Bridge_inst.APB_RegFile_Wrapper_inst_1.RegisterFile_inst.VOLTAGE_CTRL_REG	= 32'h09349933;
		force AES_APB_UART_Bridge_inst.APB_RegFile_Wrapper_inst_1.RegisterFile_inst.CLK_CONFIG_REG		= 32'h75288356;
		force AES_APB_UART_Bridge_inst.APB_RegFile_Wrapper_inst_1.RegisterFile_inst.TIMER_COUNT_REG		= 32'h48205749;
		force AES_APB_UART_Bridge_inst.APB_RegFile_Wrapper_inst_1.RegisterFile_inst.INPUT_DATA_REG		= 32'h37512387;
		force AES_APB_UART_Bridge_inst.APB_RegFile_Wrapper_inst_1.RegisterFile_inst.OUTPUT_DATA_REG		= 32'h54809804;
		force AES_APB_UART_Bridge_inst.APB_RegFile_Wrapper_inst_1.RegisterFile_inst.DMA_CTRL_REG		= 32'hf3abfe78;
		force AES_APB_UART_Bridge_inst.APB_RegFile_Wrapper_inst_1.RegisterFile_inst.SYS_CTRL_REG		= 32'ha08d9c8f;
	endfunction : initialize_registers
	
endmodule