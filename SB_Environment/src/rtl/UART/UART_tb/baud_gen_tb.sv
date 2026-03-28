module baud_gen_tb ();

	import shared_pkg::*;
	
	bit clk, reset_n;
	logic [10:0] divisor;
	logic tick;

	baud_rate_gen baud_rate_gen_inst(.*);

	initial begin
		forever #1 clk = ~clk;
	end

	initial begin
		@(negedge clk);
		reset_n <= 1;
		divisor	<= 3255;
		repeat(3000) @(negedge clk);
		$stop;
	end
endmodule : baud_gen_tb