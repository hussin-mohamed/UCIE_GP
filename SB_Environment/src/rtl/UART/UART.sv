/***********************************************************************
 * Author : Amr El Batarny
 * File   : UART.sv
 * Brief  : UART Top Module.
 **********************************************************************/

module UART #(
	parameter DATA_WIDTH	= 32,
	parameter FIFO_DEPTH	= 4,
	parameter NTICKS		= 16
	)(
	// Global Signals
	input  logic clk,
	input  logic reset_n,

	// Input Signals
	input  logic wren,
	input  logic [DATA_WIDTH-1:0] w_data,
	input  logic [10:0] divisor,

	// Output Signals
	output logic tx, tx_full
	);

	logic [DATA_WIDTH-1:0]	din_tx;
	logic					rden_fifo;
	logic					empty_fifo;
	logic					tx_start;
	logic					tick;

	always_ff @(posedge clk) begin : proc_
		tx_start <= ~empty_fifo;	
	end

	baud_rate_gen baud_rate_gen_inst(
		.clk(clk),
		.reset_n(reset_n),
		.divisor(divisor),
		.tick(tick)
		);

	fifo #(
		.FIFO_WIDTH(DATA_WIDTH),
		.FIFO_DEPTH(FIFO_DEPTH)
		)fifo_inst(
		.clk(clk),
		.reset(!reset_n),
		.wr(wren),
		.rd(rden_fifo),
		.w_data(w_data),
		.r_data(din_tx),
		.full(tx_full),
		.empty(empty_fifo)
		);

	transmitter #(
		.DATA_WIDTH(DATA_WIDTH),
		.NTICKS(NTICKS)
		)transmitter_inst(
		.clk(clk),
		.reset_n(reset_n),
		.tx_start(tx_start),
		.data_in(din_tx),
		.tick(tick),
		.tx(tx),
		.tx_done(rden_fifo)
		);
endmodule : UART