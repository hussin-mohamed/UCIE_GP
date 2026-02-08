module ucie_ltsm_rx_sbinit #(
	parameter DECODING_WIDTH = 9,
	parameter DATA_WIDTH = 64,
	parameter INFO_WIDTH = 16
) (

	input 							i_clk,
	input 							i_reset,
	input 	[DECODING_WIDTH-1:0] 	i_rx_decoding,
    input 	[DATA_WIDTH-1:0] 		i_rx_data,
    input 	[INFO_WIDTH-1:0] 		i_rx_info,
    input 							i_sb_rx_req,
    input 							i_sb_rx_rsp,
    input 							i_sb_rx_done,
    input 							i_rx_done,
    input 							init_train_en,
    input 							o_rx_sb_rsp,
    input 							i_stop,

    output  [DECODING_WIDTH-1:0] 	o_rx_encoding,
    output  [DATA_WIDTH-1:0] 		o_rx_data,
    output  [INFO_WIDTH-1:0] 		o_rx_info,
    output  						o_rx_sb_req, 
    output 							o_rx_sb_rsp,
    output 						 	o_rx_sb_done,
    output  						train_error,
    output 							o_sb_init_start


);

// should be exported to the outer interface ?
logic [3:0] CS;									// current big state (SBINIT)
logic [3:0] NS;									// next big state (MBINIT)
			
logic [2:0] current_substate;					// current substate 
logic [2:0] next_substate;						// next substate

logic done_ack;
logic substates_done;
logic previous_state_done;
logic rsp_sent;
logic [DECODING_WIDTH-1:0] encoding_rsp_sent;
logic [DECODING_WIDTH-1:0] encoding_rsp_received;
logic rsp_sent;
logic rsp_received;

// states names
localparam SBINIT = 4'b0001;
localparam MBINIT = 4'b0010;


// substates names
localparam WAIT_OUT_OF_RESET_MSG 	= 3'b000;
localparam DONE_HANDSHAKE 			= 3'b001;

// ToDo : the logic for the start of this state (end of reset state)


always @(posedge i_clk or posedge i_reset) begin
    if (i_reset) begin
        current_substate <= WAIT_OUT_OF_RESET_MSG;
    end else begin
        current_substate <= next_substate;
    end 
end


always @(posedge i_clk or posedge i_reset) begin
    if (i_reset) done_ack <= 0;
    else if (i_sb_rx_done) begin
        done_ack <= 1;
    end else if (i_sb_rx_rsp) begin
        done_ack <= 0;
    end
end

always @(posedge i_clk or posedge i_reset) begin
    if (i_reset) begin
        rsp_sent <= 0;
        rsp_received <= 0;
        encoding_rsp_sent <= 0;
        encoding_rsp_received <= 0;
    end else begin
        if (previous_state_done) begin
            rsp_sent <= 0;
            rsp_received <= 0;
            encoding_rsp_sent <= 0;
            encoding_rsp_received <= 0;
        end else begin
            if (o_rx_sb_rsp) begin
                rsp_sent <= 1;
                encoding_rsp_sent <= o_rx_encoding;
            end

            if (i_sb_rx_rsp) begin
                rsp_received <= 1;
                encoding_rsp_received <= i_rx_decoding;
            end
        end
        
    end
end

// Core FSM Logic
always_comb begin 
	// add default case for latches
	if(CS == SBINIT && substates_done == 0) begin
		case (current_substate)
			WAIT_OUT_OF_RESET_MSG: begin 
				o_rx_encoding = 9'h08;

				if(i_rx_decoding == 9'h09) begin 
					next_substate = DONE_HANDSHAKE;
				end 
				else begin 
					next_substate = WAIT_OUT_OF_RESET_MSG;
				end 

			end 

			DONE_HANDSHAKE: begin 
				o_rx_encoding = 9'h09;

				if(i_rx_decoding == 9'h09 && i_sb_rx_req) begin
					next_substate = WAIT_OUT_OF_RESET_MSG;
					substates_done = 1;
				end 
				else begin 
					next_substate = DONE_HANDSHAKE;
				end 			

			end 
		
			default: begin 
				o_rx_encoding = 9'h08;
				next_substate = WAIT_OUT_OF_RESET_MSG;
			end 
		endcase
	else begin 
		NS = MBINIT;
	end 
	
end

endmodule