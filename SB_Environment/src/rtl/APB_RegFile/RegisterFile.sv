/***********************************************************************
 * Author : Amr El Batarny
 * File   : RegisterFile.sv
 * Brief  : Defines the register file containing all APB-accessible
 *          registers.
 **********************************************************************/

module RegisterFile #(
	parameter DATA_WIDTH	= 32,
	parameter ADDR_WIDTH	= 32,
	parameter NBYTES		= DATA_WIDTH/8
	)(
	input wire 							clk,
	input wire 							rst_n,
	input wire [ADDR_WIDTH-1 : 0]		addr,
	input wire							read_en,
	input wire							write_en,
	input wire [NBYTES-1:0]				byte_strobe,
	input wire [DATA_WIDTH-1 : 0]		wdata,
	output reg [DATA_WIDTH-1 : 0]		rdata
	);

	// Registers
	reg [DATA_WIDTH-1:0] SYS_STATUS_REG;
	reg [DATA_WIDTH-1:0] INT_CTRL_REG;
	reg [DATA_WIDTH-1:0] DEV_ID_REG;
	reg [DATA_WIDTH-1:0] MEM_CTRL_REG;
	reg [DATA_WIDTH-1:0] TEMP_SENSOR_REG;
	reg [DATA_WIDTH-1:0] ADC_CTRL_REG;
	reg [DATA_WIDTH-1:0] DBG_CTRL_REG;
	reg [DATA_WIDTH-1:0] GPIO_DATA_REG;
	reg [DATA_WIDTH-1:0] DAC_OUTPUT_REG;
	reg [DATA_WIDTH-1:0] VOLTAGE_CTRL_REG;
	reg [DATA_WIDTH-1:0] CLK_CONFIG_REG;
	reg [DATA_WIDTH-1:0] TIMER_COUNT_REG;
	reg [DATA_WIDTH-1:0] INPUT_DATA_REG;
	reg [DATA_WIDTH-1:0] OUTPUT_DATA_REG;
	reg [DATA_WIDTH-1:0] DMA_CTRL_REG;
	reg [DATA_WIDTH-1:0] SYS_CTRL_REG;

	wire [DATA_WIDTH-1:0] mask;
	genvar i;
	generate
		for (i = 0; i < NBYTES; i = i + 1) begin
			// replicate byte_strobe[i] across 8 bits
			assign mask[(i+1)*8-1 -: 8] = {8{byte_strobe[i]}};
		end
	endgenerate


	always @(posedge clk or negedge rst_n) begin
		if(~rst_n)
			rdata <= 0;
		else begin
			if(write_en)
				case (addr)
					32'h0000_0000: SYS_STATUS_REG	<= (SYS_STATUS_REG		&	~mask) | (wdata & mask);
					32'h0000_0004: INT_CTRL_REG		<= (INT_CTRL_REG		&	~mask) | (wdata & mask);
					32'h0000_0008: DEV_ID_REG		<= (DEV_ID_REG			&	~mask) | (wdata & mask);
					32'h0000_000c: MEM_CTRL_REG		<= (MEM_CTRL_REG		&	~mask) | (wdata & mask);
					32'h0000_0010: TEMP_SENSOR_REG	<= (TEMP_SENSOR_REG		&	~mask) | (wdata & mask);
					32'h0000_0014: ADC_CTRL_REG		<= (ADC_CTRL_REG		&	~mask) | (wdata & mask);
					32'h0000_0018: DBG_CTRL_REG		<= (DBG_CTRL_REG		&	~mask) | (wdata & mask);
					32'h0000_001c: GPIO_DATA_REG	<= (GPIO_DATA_REG		&	~mask) | (wdata & mask);
					32'h0000_0020: DAC_OUTPUT_REG	<= (DAC_OUTPUT_REG		&	~mask) | (wdata & mask);
					32'h0000_0024: VOLTAGE_CTRL_REG	<= (VOLTAGE_CTRL_REG	&	~mask) | (wdata & mask);
					32'h0000_0028: CLK_CONFIG_REG	<= (CLK_CONFIG_REG		&	~mask) | (wdata & mask);
					32'h0000_002c: TIMER_COUNT_REG	<= (TIMER_COUNT_REG		&	~mask) | (wdata & mask);
					32'h0000_0030: INPUT_DATA_REG	<= (INPUT_DATA_REG		&	~mask) | (wdata & mask);
					32'h0000_0034: OUTPUT_DATA_REG	<= (OUTPUT_DATA_REG		&	~mask) | (wdata & mask);
					32'h0000_0038: DMA_CTRL_REG		<= (DMA_CTRL_REG		&	~mask) | (wdata & mask);
					32'h0000_003c: SYS_CTRL_REG		<= (SYS_CTRL_REG		&	~mask) | (wdata & mask);
				endcase
			if(read_en)
				case (addr)
					32'h0000_0000: rdata <= SYS_STATUS_REG;
					32'h0000_0004: rdata <= INT_CTRL_REG;
					32'h0000_0008: rdata <= DEV_ID_REG;
					32'h0000_000c: rdata <= MEM_CTRL_REG;
					32'h0000_0010: rdata <= TEMP_SENSOR_REG;
					32'h0000_0014: rdata <= ADC_CTRL_REG;
					32'h0000_0018: rdata <= DBG_CTRL_REG;
					32'h0000_001c: rdata <= GPIO_DATA_REG;
					32'h0000_0020: rdata <= DAC_OUTPUT_REG;
					32'h0000_0024: rdata <= VOLTAGE_CTRL_REG;
					32'h0000_0028: rdata <= CLK_CONFIG_REG;
					32'h0000_002c: rdata <= TIMER_COUNT_REG;
					32'h0000_0030: rdata <= INPUT_DATA_REG;
					32'h0000_0034: rdata <= OUTPUT_DATA_REG;
					32'h0000_0038: rdata <= DMA_CTRL_REG;
					32'h0000_003c: rdata <= SYS_CTRL_REG;
				endcase
        end
	end
endmodule