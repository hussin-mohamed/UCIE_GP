/***********************************************************************
 * Author : Amr El Batarny
 * File   : APB_Slave.sv
 * Brief  : Implements the APB master stub.
 **********************************************************************/

module APB_Controller #(
	parameter DATA_WIDTH	= 32,
	parameter ADDR_WIDTH	= 32,
	parameter NBYTES		= DATA_WIDTH/8,
	parameter N_AES			= 128
	)(
	// Global Signals
	input	logic					PCLK,
	input	logic					PRESETn,

	// Register File Signals
	input	logic					start,
	input	logic [ADDR_WIDTH-1:0]	start_addr,
	input	logic					valid,
	input	logic [DATA_WIDTH-1:0]	rdata,
	
	// Output to the APB Master
	output  logic [ADDR_WIDTH-1:0]	addr,
	output  logic					transfer,
	output  logic					write,
	output  logic [NBYTES-1:0]		byte_strobe,
	
	// Output to the UART Controller
	output	logic [N_AES-1:0]		concat_out,
	output	logic					concat_done
	);

	import shared_pkg::*;

	apb_controller_state_e	state_reg, state_next;

	logic transfer_tmp;

	logic						done_reg,	done_next;
	logic [3:0]					count_reg,	count_next;
	logic [3:0]					delay_count_reg, delay_count_next;
	logic [N_AES-1:0]			concat_reg,	concat_next;
	logic [DATA_WIDTH-1:0]		data_reg,	data_next;

	pos_edge_det pos_edge_det_inst(.sig(transfer_tmp), .clk(PCLK), .pe(transfer));

	// State and Internals Memory
	always_ff @(posedge PCLK or negedge PRESETn)
		if(!PRESETn) begin
			state_reg	<= IDLE_C;
			count_reg	<= 0;
			concat_reg	<= 0;
			data_reg	<= 0;
			done_reg	<= 0;
			delay_count_reg <= 0;
		end else begin
			state_reg	<= state_next;
			count_reg	<= count_next;
			concat_reg	<= concat_next;
			data_reg	<= data_next;
			done_reg	<= done_next;
			delay_count_reg <= delay_count_next;
		end

	// Next State Logic
	always_comb
		case(state_reg)
			IDLE_C:
			begin
				concat_next = concat_reg;
				count_next	= 0;
				data_next	= data_reg;
				delay_count_next = 0;
				if(start)
					state_next = READ_C;
				else
					state_next = IDLE_C;
			end

			READ_C:
			begin
				delay_count_next = delay_count_reg;
				concat_next = concat_reg;
				count_next	= count_reg;
				if(valid) begin
					data_next	= rdata;
					state_next	= DELAY_C;
				end else begin
					data_next	= data_reg;
					state_next	= READ_C;
				end
			end

			DELAY_C:
			begin
				concat_next = concat_reg;
				count_next	= count_reg;
				data_next	= data_reg;
				if(delay_count_reg == 5) begin
					delay_count_next = 0;
					state_next	= SHIFT_C;
				end else begin
					delay_count_next = delay_count_reg + 1;
					state_next	= DELAY_C;
				end
			end

			SHIFT_C:
			begin
				concat_next = {data_reg, concat_reg[N_AES-1:DATA_WIDTH]};
				data_next	= data_reg;
				delay_count_next = delay_count_reg;
				if(count_reg == 15) begin
					state_next	= IDLE_C;
					count_next	= 0;
				end else begin
					state_next	= READ_C;
					count_next	= count_reg + 1;
				end
			end
		endcase

	assign done_next	= (state_reg == SHIFT_C && (count_reg == 3 || count_reg == 7 || count_reg == 11 || count_reg == 15))? 1'b1 : 1'b0;
	
	// Output Logic
	assign concat_out	= concat_reg;
	assign write		= 1'b0;
	assign byte_strobe	= (state_reg == IDLE_C)? 4'h0 : 4'hF;
	assign addr			= (start_addr + count_reg) << 2;
	assign transfer_tmp	= (state_reg == READ_C)? 1'b1 : 1'b0;
	assign concat_done	= done_reg;
endmodule