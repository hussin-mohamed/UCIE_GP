module UART_tb ();

	import shared_pkg::*;
	
	// Global Signals
	bit clk;
	bit reset_n;

	// Input Signals
	logic wren;
	logic [DATA_WIDTH-1:0] w_data;
	logic [10:0] divisor;

	// Output Signals
	logic tx, tx_full;

	UART #(
		.DATA_WIDTH(32),
		.FIFO_DEPTH(4),
		.NTICKS(16)
		)UART_inst(
		.clk(clk),
		.reset_n(reset_n),
		.wren(wren),
		.w_data(w_data),
		.divisor(divisor),
		.tx(tx),
		.tx_full(tx_full)
		);

	initial begin
		forever #1 clk = ~clk;
	end

	initial begin
		@(negedge clk);
		reset_n = 1;
		wren	= 1;
		divisor	= 10;
		w_data	= 32'b0101_1111_0000_1010_0011_1110_0001_1101;
		@(negedge clk);
		w_data	= 32'hf9e3_a117;
		@(negedge clk);
		w_data	= 32'h13c5_a27d;
		@(negedge clk);
		w_data	= 32'h27c0_0743;
		@(negedge clk);
		wren 	= 0;
		repeat(60000) @(negedge clk);
		$stop;
	end
endmodule : UART_tb