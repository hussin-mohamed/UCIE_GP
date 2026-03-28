/***********************************************************************
 * Author : Amr El Batarny
 * File   : APB_Slave.sv
 * Brief  : Implements the APB slave module with register interface and
 *          control logic.
 **********************************************************************/

module APB_Slave #(
	parameter DATA_WIDTH	= 32,
	parameter ADDR_WIDTH	= 32,
	parameter NBYTES		= DATA_WIDTH/8
	)(
	// Global Signals
	input  logic 					PCLK,
	input  logic 					PRESETn,

	// APB Signals
	input  logic					PSELx,
	input  logic					PENABLE,
	input  logic [ADDR_WIDTH-1:0]	PADDR,
	input  logic [DATA_WIDTH-1:0]	PWDATA,
	input  logic					PWRITE,
	input  logic [NBYTES-1:0]		PSTRB,
	output logic					PREADY,

	// Register File Signals
	output logic [ADDR_WIDTH-1:0]	addr,
	output logic					write_en,
	output logic					read_en,
	output logic [NBYTES-1:0]		byte_strobe,
	output logic [DATA_WIDTH-1:0]	wdata
	);

	import shared_pkg::*;

	apb_slave_state_e current_state, next_state;

	// State Memory
	always_ff @(posedge PCLK or negedge PRESETn) begin
        if (~PRESETn) begin
            current_state <= IDLE_S;
        end else begin
            current_state <= next_state;
        end
    end

    // Next State Logic
    always_comb begin
    	case(current_state)
    		IDLE_S:
    			if(PENABLE && PSELx)
    				next_state = ACCESS_S;
    			else
    				next_state = IDLE_S;
    		
    		ACCESS_S:
				next_state = IDLE_S;

			default:
				next_state = IDLE_S;
    	endcase
    end

    // Output Logic
	always_comb begin
		if(~PRESETn) begin
			PREADY = 1'b0;
		end else begin
			if(current_state == IDLE_S)
				PREADY = 1'b0;
			else if(current_state == ACCESS_S) begin
				addr 		= PADDR;
				write_en	= (PWRITE == 1'b1)? 1'b1 : 1'b0;
				read_en		= ~write_en;
				byte_strobe	= PSTRB;
				wdata		= PWDATA;
				PREADY		= 1'b1;
			end
		end
	end
endmodule