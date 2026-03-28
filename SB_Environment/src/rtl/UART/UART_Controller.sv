/***********************************************************************
 * Author : Amr El Batarny
 * File   : APB_Slave.sv
 * Brief  : Implements the APB master stub.
 **********************************************************************/

module UART_Controller #(
	parameter DATA_WIDTH	= 32,
	parameter ADDR_WIDTH	= 32,
	parameter N_AES			= 128
	)(
	// Global Signals
	input	logic					clk,
	input	logic					reset_n,

	input	logic 					start,
	input	logic 					ready,
	input	logic [N_AES-1:0]		in,
	output	logic 					write_uart,
	output	logic [DATA_WIDTH-1:0]	out
	);

	import shared_pkg::*;

	localparam REG0_MSB = N_AES-DATA_WIDTH*3-1;
	localparam REG0_LSB = DATA_WIDTH*0;
	localparam REG1_MSB = N_AES-DATA_WIDTH*2-1;
	localparam REG1_LSB = DATA_WIDTH*1;
	localparam REG2_MSB = N_AES-DATA_WIDTH*1-1;
	localparam REG2_LSB = DATA_WIDTH*2;
	localparam REG3_MSB = N_AES-DATA_WIDTH*0-1;
	localparam REG3_LSB = DATA_WIDTH*3;

	uart_controller_state_e	state_reg, state_next;

	logic 						write_reg,	write_next;
	logic [1:0]					count_reg,	count_next;
	logic [DATA_WIDTH-1:0]		data_reg,	data_next;
	logic [DATA_WIDTH-1:0]		out_reg,	out_next;

	// State and Internals Memory
	always_ff @(posedge clk or negedge reset_n)
		if(!reset_n) begin
			state_reg	<= IDLE_UC;
			write_reg	<= 0;
			count_reg	<= 0;
			data_reg	<= 0;
			out_reg		<= 0;
		end else begin
			state_reg	<= state_next;
			write_reg	<= write_next;
			count_reg	<= count_next;
			data_reg	<= data_next;
			out_reg		<= out_next;
		end

	// Next State Logic
	always_comb
		case(state_reg)
			IDLE_UC:
			begin
				out_next	= out_reg;
				count_next	= 0;
				if(start)
					state_next = WAIT_UC;
				else
					state_next = IDLE_UC;
			end

			WAIT_UC:
			begin
				out_next 	= out_reg;
				count_next	= count_reg;
				if(ready)
					state_next	= PUSH_UC;
				else
					state_next	= WAIT_UC;
			end

			PUSH_UC:
			begin
				out_next	= data_reg;
				if(count_reg == 3) begin
					state_next	= IDLE_UC;
					count_next	= 0;
				end else begin
					state_next	= WAIT_UC;
					count_next	= count_reg + 1;
				end
			end
		endcase

	// data_next Logic
	always_comb
		if(state_reg == WAIT_UC && ready)
			case (count_reg)
				0:	data_next = in[REG0_MSB : REG0_LSB];
				1:	data_next = in[REG1_MSB : REG1_LSB];
				2:	data_next = in[REG2_MSB : REG2_LSB];
				3:	data_next = in[REG3_MSB : REG3_LSB];
			endcase
		else
			data_next = data_reg;


	// write_next Logic
	assign write_next = (state_reg == PUSH_UC)? 1'b1 : 1'b0;

	// Output Logic
	assign out			= out_reg;
	assign write_uart	= write_reg;
endmodule