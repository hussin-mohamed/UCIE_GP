/***********************************************************************
 * Author : Amr El Batarny
 * File   : shared_pkg.sv
 * Brief  : Simple Baud Rate Gnerator.
 **********************************************************************/

module baud_rate_gen (
	input  logic clk, reset_n,
	input  logic [10:0] divisor,
	output logic tick
);

	logic [10:0] count_reg;
	logic [10:0] count_next;

	// Counter
	always_ff @(posedge clk, negedge reset_n)
		if (!reset_n)
			count_reg <= 0;
		else
			count_reg <= count_next;

	// Next Count Value Logic
	assign count_next = (count_reg == divisor)? 0 : count_reg + 1;

	// Output Tick Logic
	assign tick = (count_reg == 0)? 1'b1 : 1'b0;
endmodule : baud_rate_gen