/***********************************************************************
 * Author : Amr El Batarny
 * File   : APB_RegFile_Wrapper.sv
 * Brief  : Top-level wrapper module connecting the APB slave to the
 *          external environment.
 **********************************************************************/

module APB_RegFile_Wrapper #(
	parameter DATA_WIDTH	= 32,
	parameter ADDR_WIDTH	= 32,
	parameter NBYTES		= DATA_WIDTH/8
	)(
	// Global Signals
	input  logic						PCLK,
	input  logic						PRESETn,

	// APB Signals
	input  logic						PSELx,
	input  logic [ADDR_WIDTH-1:0]		PADDR,
	input  logic						PWRITE,
	input  logic [NBYTES-1:0]			PSTRB,
	input  logic [DATA_WIDTH-1:0]		PWDATA,
	input  logic						PENABLE,
	output logic [DATA_WIDTH-1:0]		PRDATA,
	output logic						PREADY
	);

	// Register File Signals
	logic [ADDR_WIDTH-1:0]	addr;
	logic					write_en;
	logic					read_en;
	logic [NBYTES-1:0]		byte_strobe;
	logic [DATA_WIDTH-1:0]	wdata;
	logic [DATA_WIDTH-1:0]	rdata;

	assign PRDATA = rdata;

	RegisterFile #(
		.DATA_WIDTH(DATA_WIDTH),
		.ADDR_WIDTH(ADDR_WIDTH),
		.NBYTES(NBYTES)
		)RegisterFile_inst(
		.clk(PCLK),
		.rst_n(PRESETn),
		.addr(addr),
		.read_en(read_en),
		.write_en(write_en),
		.byte_strobe(byte_strobe),
		.wdata(wdata),
		.rdata(rdata)
		);
	
	APB_Slave #(
		.DATA_WIDTH(DATA_WIDTH),
		.ADDR_WIDTH(ADDR_WIDTH),
		.NBYTES(NBYTES)
		)APB_Slave_inst(
		.PCLK(PCLK),
		.PRESETn(PRESETn),
		.PSELx(PSELx),
		.PADDR(PADDR),
		.PWRITE(PWRITE),
		.PSTRB(PSTRB),
		.PWDATA(PWDATA),
		.PENABLE(PENABLE),
		.PREADY(PREADY),
		.addr(addr),
		.write_en(write_en),
		.read_en(read_en),
		.byte_strobe(byte_strobe),
		.wdata(wdata)
		);
endmodule