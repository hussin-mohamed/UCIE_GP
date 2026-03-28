/***********************************************************************
 * Author : Amr El Batarny
 * File   : transmitter.sv
 * Brief  : UART Transmitter Module.
 **********************************************************************/

module transmitter #(
	parameter DATA_WIDTH	= 32,
	parameter NTICKS		= 16
	)(
	// Global Signals
	input  logic clk,
	input  logic reset_n,

	// Input Signals
	input  logic tx_start,
	input  logic [DATA_WIDTH-1:0] data_in,
	input  logic tick,

	// Output Signals
	output logic tx,
	output logic tx_done
	);
	
	import shared_pkg::*;

	localparam DATA_COUNTER_WIDTH = $clog2(DATA_WIDTH);

	logic [3:0]						tcount_reg,		tcount_next; // Tick Counter
	logic [DATA_COUNTER_WIDTH-1:0]	dcount_reg,		dcount_next; // Sampled Data Counter
	logic [DATA_WIDTH-1:0]			data_reg,		data_next; // Data Register
	uart_state_e					state_reg,		state_next; // UART States
	logic							tx_reg,			tx_next; // tx Register
	logic							tx_done_tmp;

	// State Memory as well as Data and Counters Registers
	always_ff @(posedge clk, negedge reset_n)
		if (~reset_n) begin
			tcount_reg	<= 0;
			dcount_reg	<= 0;
			data_reg	<= 0;
			state_reg	<= IDLE_U;
			tx_reg		<= 0;
		end else begin
			tcount_reg	<= tcount_next;
			dcount_reg	<= dcount_next;
			data_reg	<= data_next;
			state_reg	<= state_next;
			tx_reg		<= tx_next;
		end

	// Next State, Registers and Output Logic
	always_comb begin
		tcount_next	= tcount_reg;
		dcount_next	= dcount_reg;
		data_next	= data_reg;
		state_next	= state_reg;
		tx_next		= tx_reg;
		tx_done_tmp	= 1'b0;

		case(state_reg)
			IDLE_U:
			begin
				tx_next = 1'b1;
				if(tx_start) begin
					state_next	= START_U;
					tcount_next	= 0;
					data_next	= data_in;
				end
			end

			START_U:
			begin
				tx_next = 1'b0;
				if(tick) begin
					if(tcount_reg == NTICKS-1) begin
						state_next = DATA_U;
						tcount_next = 0;
						dcount_next = 0;
					end else
						tcount_next = tcount_reg + 1;
				end
			end

			DATA_U:
			begin
				tx_next = data_reg[0];
				if(tick) begin
					if(tcount_reg == NTICKS-1) begin
						tcount_next = 0;
						data_next = data_reg >> 1;
						if(dcount_reg == DATA_WIDTH-1)
							state_next = STOP_U;
						else
							dcount_next	= dcount_reg + 1;
					end else
						tcount_next = tcount_reg + 1;
				end
			end

			STOP_U:
			begin
				tx_next = 1'b1;
				if(tick)
					if(tcount_reg == NTICKS-1) begin
						state_next	= IDLE_U;
						tx_done_tmp	= 1'b1;
					end else
						tcount_next = tcount_reg + 1;
			end
		endcase
	end

	// Output
	assign tx		= tx_reg;
	assign tx_done	= tx_done_tmp;
endmodule : transmitter