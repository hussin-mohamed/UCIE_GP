/***********************************************************************
 * Author : Amr El Batarny
 * File   : MUX.sv
 * Brief  : Generic Multiplexer.
 **********************************************************************/

module MUX #(
	parameter MUX_WIDTH	= 32
	)(
	input  logic 				 sel,
	input  logic [MUX_WIDTH-1:0] ina,
	input  logic [MUX_WIDTH-1:0] inb,
	output logic [MUX_WIDTH-1:0] out
	);

	always_comb begin
		case(sel)
			0: out = ina;
			1: out = inb;
		endcase
	end
endmodule