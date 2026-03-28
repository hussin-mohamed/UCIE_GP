module fifo
	#(parameter FIFO_DEPTH = 4, FIFO_WIDTH = 32)
	(
		input logic clk, reset,
		input logic wr, rd,
		input logic [FIFO_WIDTH - 1: 0] w_data,
		output logic [FIFO_WIDTH - 1: 0] r_data,
		output logic full, empty
	);

	localparam ADDR_WIDTH = $clog2(FIFO_DEPTH);
	
	// signal declaration
	logic [ADDR_WIDTH - 1: 0] w_addr, r_addr;
	
	// instantiate register file
	reg_file #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(FIFO_WIDTH))
		r_file_unit (.w_en( wr & ~full), .*);

	// instantiate fifo controller
	fifo_ctrl #(.ADDR_WIDTH(ADDR_WIDTH))
		ctrl_unit (.*);                    
endmodule