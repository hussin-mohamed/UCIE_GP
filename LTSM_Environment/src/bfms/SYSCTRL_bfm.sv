/***********************************************************************
 * Author : Amr El Batarny
 * File   : SYSCTRL_bfm.sv
 * Brief  : Bus Functional Model for controlling the system.
 **********************************************************************/

interface SYSCTRL_bfm;
	import shared_pkg::*;

	//--------------------- Clock & Reset ---------------------
	bit 					PCLK;
	logic 					PRESETn;

	//--------------------- UART Output -----------------------
	logic					tx;
	
	string if_name = "SYSCTRL_bfm";

	initial begin
		forever begin
			#1;
			PCLK = ~PCLK;
		end
	end

	task reset();
		// Assert reset and clear signals
		PRESETn		 <= 1'b0;

		// Hold reset for one clock cycle
		@(negedge PCLK);
		
		// Deassert reset
		PRESETn <= 1'b1;
	endtask
endinterface : SYSCTRL_bfm