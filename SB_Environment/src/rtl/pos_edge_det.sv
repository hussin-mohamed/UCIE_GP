module pos_edge_det
	(
	input	logic	sig,
	input	logic	clk,
	output	logic	pe
	);

	logic sig_dly;

	always @ (posedge clk) begin
		sig_dly <= sig;
	end

	assign pe = sig & ~sig_dly;
endmodule