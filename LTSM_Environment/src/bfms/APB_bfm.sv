/***********************************************************************
 * Author : Amr El Batarny
 * File   : APB_bfm.sv
 * Brief  : Bus Functional Model for AMBA APB Slave Protocol.
 **********************************************************************/

import shared_pkg::*;

interface APB_bfm(
   //--------------------- Clock & Reset ---------------------
	input bit					PCLK,
	input logic					PRESETn,

	//------------------- UART Read Request -------------------
	input logic					req,

   //---------------- APB Slave Internal Ports ---------------
   //----------------- (Used for monitoring) -----------------
   input logic                   PSELx_int,
   input logic [ADDR_WIDTH-1:0]  PADDR_int,
   input logic                   PWRITE_int,
   input logic [NBYTES-1:0]      PSTRB_int,
   input logic [DATA_WIDTH-1:0]  PWDATA_int,
   input logic                   PENABLE_int
);
	
	

	//-------------------- APB Slave Ports --------------------
	logic							PSELx;
	logic [ADDR_WIDTH-1:0]	PADDR;
	logic							PWRITE;
	logic [NBYTES-1:0]		PSTRB;
	logic [DATA_WIDTH-1:0]	PWDATA;
	logic							PENABLE;
	logic [DATA_WIDTH-1:0]	PRDATA;
	logic							PREADY;

	//--------- Starting Address for Reading Operation --------
	logic [ADDR_WIDTH-1:0]		start_addr;

	//--------------------- MUX Selectors ---------------------
	logic 						sel_1, sel_2, sel_3;

	string if_name = "APB_bfm";

	task clear();
		// Clear APB signals
		PENABLE		<= 1'b0;
		PADDR		<= '0;
		PWDATA		<= '0;
		PWRITE		<= 1'b0;
		PSTRB		<= '0;
		start_addr	<= '0;
		sel_1		<= '0;
		sel_2		<= '0;
		sel_3		<= '0;
	endtask

	task write_reg(
		input logic [ADDR_WIDTH-1:0]	addr, 
		input logic [DATA_WIDTH-1:0]	data,
		input logic [NBYTES-1:0]		strobe
	);
		// Setup phase
		PADDR	<= addr;
		PWDATA	<= data;
		PWRITE	<= 1'b1;
		PSELx	<= 1'b1;
		PSTRB	<= strobe;
		
		// Wait for clock edge
		@(posedge PCLK);
		
		// Enable phase
		PENABLE <= 1'b1;
		
		// Wait for completion
		@(posedge PREADY);
		
		// Clear control signals
		PSELx	<= 1'b0;
		PENABLE	<= 1'b0;
	endtask

	task read_reg(
		input  logic [31:0] addr,
		output logic [31:0] data
	);
		// Setup phase
		PADDR	<= addr;
		PWDATA	<= '0;
		PWRITE	<= 1'b0;
		PSELx	<= 1'b1;
		PSTRB	<= '0;
		
		// Wait for clock edge
		@(posedge PCLK);
		
		// Enable phase
		PENABLE <= 1'b1;
		
		// Wait for transfer completion
		@(posedge PCLK);
		
		// Capture read data
		data = PRDATA;
		
		// Clear control signals
		PSELx   <= 1'b0;
		PENABLE <= 1'b0;
	endtask

endinterface : APB_bfm