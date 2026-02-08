module ucie_ltsm_tx_sbinit #(
	parameter DECODING_WIDTH = 9,
	parameter DATA_WIDTH = 64,
	parameter INFO_WIDTH = 16
) (

	input 							i_clk,
	input 							i_reset,
	input 	[DECODING_WIDTH-1:0] 	i_tx_decoding,
    input 	[DATA_WIDTH-1:0] 		i_tx_data,
    input 	[INFO_WIDTH-1:0] 		i_tx_info,
    input 							i_sb_tx_req,
    input 							i_sb_tx_rsp,
    input 							i_sb_tx_done,
    input 							i_tx_done,
    input 							init_train_en,
    input 							o_rx_sb_rsp,
    input 							i_stop,

    output  [DECODING_WIDTH-1:0] 	o_tx_encoding,
    output  [DATA_WIDTH-1:0] 		o_tx_data,
    output  [INFO_WIDTH-1:0] 		o_tx_info,
    output  						o_tx_sb_req, 
    output 							o_tx_sb_rsp,
    output 						 	o_tx_sb_done,
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
localparam PATTERN_GENERATION 	= 3'b000;
localparam OUT_OF_RESET_MSG 	= 3'b001;
localparam DONE_HANDSHAKE 		= 3'b010;

// ToDo : the logic for the start of this state (end of reset state)


always @(posedge i_clk or posedge i_reset) begin
    if (i_reset) begin
        current_substate <= PATTERN_GENERATION;
    end else begin
        current_substate <= next_substate;
    end 
end


always @(posedge i_clk or posedge i_reset) begin
    if (i_reset) done_ack <= 0;
    else if (i_sb_tx_done) begin
        done_ack <= 1;
    end else if (i_sb_tx_rsp) begin
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
                encoding_rsp_sent <= o_tx_encoding;
            end

            if (i_sb_tx_rsp) begin
                rsp_received <= 1;
                encoding_rsp_received <= i_tx_decoding;
            end
        end
        
    end
end

always_comb begin 
	// add default case for latches
	if(CS == SBINIT && substates_done == 0) begin
		case (current_substate)
			PATTERN_GENERATION: begin 
				o_tx_encoding = 9'h08;
				o_sb_init_start = 1'b1;

				if(i_stop == 1) begin 
					o_sb_init_start = 1'b0;
					next_substate = OUT_OF_RESET_MSG;
				end 
				else begin 
					next_substate = PATTERN_GENERATION;
				end 

			end 

			OUT_OF_RESET_MSG: begin 
				o_tx_encoding = 9'h09;

				if(i_tx_decoding == 9'h09) begin	// no rsp here is coming ??
					next_substate = DONE_HANDSHAKE;
				end 
				else begin 
					next_substate = OUT_OF_RESET_MSG;
				end 			

			end 

			DONE_HANDSHAKE: begin 
				o_tx_encoding = 9'h0A;

	            if (i_sb_tx_rsp && i_tx_decoding == 9'h0A) begin
	                substates_done = 1;
	                next_substate = PATTERN_GENERATION;
	            end else begin
	                substates_done = 0;
	                next_substate = DONE_HANDSHAKE;
	            end 

			end 
		
			default: begin 
				o_tx_encoding = 9'h08;
				o_sb_init_start = 0;
				next_substate = PATTERN_GENERATION;
			end 
		endcase
	else begin 
		NS = MBINIT;
	end 
	
end

endmodule