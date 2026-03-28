/***********************************************************************
 * Author : Amr El Batarny
 * File   : APB_Master.sv
 * Brief  : APB bus master controller implementing setup-access cycles.
 **********************************************************************/

module APB_Master #(
	//----------------- Parameter Definitions -----------------
	parameter DATA_WIDTH	= 32,
	parameter ADDR_WIDTH	= 32,
	parameter NBYTES		= DATA_WIDTH/8
	)(
	//--------------------- Clock & Reset ---------------------
	input  logic					PCLK,
	input  logic					PRESETn,

	//-------------------- APB Interface ----------------------
	output logic					PSELx,
	output logic					PENABLE,
	output logic					PWRITE,
	output logic [NBYTES-1:0]		PSTRB,
	output logic [ADDR_WIDTH-1:0]	PADDR,
	output logic [DATA_WIDTH-1:0]	PWDATA,
	input  logic [DATA_WIDTH-1:0]	PRDATA,
	input  logic					PREADY,

	//------------------- Transaction Inputs ------------------
	input  logic [ADDR_WIDTH-1:0]	addr,
	input  logic					transfer,
	input  logic					write,
	input  logic [NBYTES-1:0]		byte_strobe,
	input  logic [DATA_WIDTH-1:0]	wdata,

	//------------------ Transaction Outputs ------------------
	output logic [DATA_WIDTH-1:0]	rdata,
	output logic					transfer_done
	);

	//---------------- Shared Types and Imports ---------------
	import shared_pkg::*;

	//---------------- Internal State Variables ---------------
	apb_master_state_e state_reg, state_next;

	//---------------------- Assignments ----------------------
	assign rdata	= PRDATA;

	//------------------- Transfer Done Flag ------------------
	always_ff @(posedge PCLK)
		transfer_done <= PREADY;
	
	//--------------------- State Memory ----------------------
	always_ff @(posedge PCLK or negedge PRESETn) begin
        if (~PRESETn) begin
            state_reg <= IDLE_M;
        end else begin
            state_reg <= state_next;
        end
    end

    //--------------- Next State and APB Control --------------
    always_comb begin
    	case(state_reg)
    		IDLE_M:
    		begin
    			PSELx		= 1'b0;
    			PENABLE		= 1'b0;
    			PADDR		= '0;
				PWDATA		= '0;
    			if(transfer)
    				state_next = SETUP_M;
    			else
    				state_next = IDLE_M;
    		end
    		
    		SETUP_M:
    		begin
    			PSELx		= 1'b1;
				PENABLE		= 1'b0;
				PADDR		= addr;
				PWDATA		= wdata;
				state_next = ACCESS_M;
			end

			ACCESS_M:
			begin
				PSELx		= 1'b1;
				PENABLE		= 1'b1;
				PADDR		= addr;
				PWDATA		= wdata;
				if(PREADY)
					state_next = IDLE_M;
				else
					state_next = ACCESS_M;
			end
			
			default:
				state_next = IDLE_M;
    	endcase
    end

	//--------------- Write and Strobe Control ----------------
	always_comb begin
		if ((state_reg == SETUP_M || state_reg == ACCESS_M) && (write)) begin
			PWRITE	= 1'b1;
			PSTRB	= byte_strobe;
		end else begin
			PWRITE	= 1'b0;
			PSTRB	= 0;
		end
	end
endmodule