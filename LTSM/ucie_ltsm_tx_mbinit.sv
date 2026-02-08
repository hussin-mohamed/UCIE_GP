module ucie_ltsm_tx_mbinit #(
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

    output  [DECODING_WIDTH-1:0] 	o_tx_encoding,
    output  [DATA_WIDTH-1:0] 		o_tx_data,
    output  [INFO_WIDTH-1:0] 		o_tx_info,
    output  						o_tx_sb_req, 
    output 							o_tx_sb_rsp,
    output 						 	o_tx_sb_done,
    output  						train_error

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
logic [3:0]  count;			// for counting number of ones (lanes)
logic [2:0] lane_map;	// default is 011 all lanes functional 
logic [2:0] extracted_lane_map;


// states names
localparam PARAM 		= 4'b0010;
localparam CAL 			= 4'b0011;
localparam REPAIRCLK 	= 4'b0100;
localparam REPAIRVAL 	= 4'b0101;
localparam REVERSAL 	= 4'b0110;
localparam REPAIRMB 	= 4'b0111;

// substates names 


// ToDo : the logic for the start of this state


always @(posedge i_clk or posedge i_reset) begin
    if (i_reset) begin
    	CS <= PARAM;
        current_substate <= 0;
    end else begin
    	CS <= NS;
        current_substate <= next_substate;
    end 
end


always @(posedge i_clk or posedge i_reset) begin
    if (i_reset) done_ack <= 0;
    else if (i_sb_tx_done) begin
        done_ack <= 1;
    end else if (i_sb_tx_rsp) begin // shouldn't we here raise the done_ack
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
    count = 4'd0; 
    
    if(i_sb_tx_rsp && i_tx_decoding == 9'h33) begin 
	    for (int i = 0; i < 15; i++) begin
	        count = count + i_tx_data[i]; 
	    end
	end
end

always_comb begin 
	case(CS) 
		// u need to form the message 
		PARAM: begin 
			// Output State Encoding
			o_tx_encoding = 9'h10;
            
            // TX Sending REQ Handshake
            if (done_ack) begin 
            	o_tx_sb_req = 0;
            end
            else begin 
            	o_tx_sb_req = 1;
            end 

            // Next State Logic
			if(i_sb_tx_rsp && i_tx_decoding == 9'h10) begin 
				NS = CAL;
			end 
			else begin 
				NS = PARAM;
			end 

		end 

		CAL: begin 
			// Output State Encoding
			o_tx_encoding = 9'h18;

            // TX Sending REQ Handshake
            if (done_ack) begin 
            	o_tx_sb_req = 0;
            end
            else begin 
            	o_tx_sb_req = 1;
            end 

			// Next State Logic
			if(i_sb_tx_rsp && i_tx_decoding == 9'h18) begin 
				NS = REPAIRCLK;
			end 
			else begin 
				NS = CAL;
			end 
		end 

		REPAIRCLK: begin 
			case(current_substate) 
				0: begin 
					o_tx_encoding = 9'h20;

		            // TX Sending REQ Handshake
		            if (done_ack) begin 
		            	o_tx_sb_req = 0;
		            end
		            else begin 
		            	o_tx_sb_req = 1;
		            end

					// Next State Logic
					if(i_sb_tx_rsp && i_tx_decoding == 9'h20) begin 
						NS = REPAIRCLK;
						next_substate = 1;
					end 
					else begin 
						NS = REPAIRCLK;
						next_substate = 0;
					end 

				end 

				1: begin 
					// Output State Encoding
					o_tx_encoding = 9'h21;

		            // TX Sending REQ Handshake
		            if (done_ack) begin 
		            	o_tx_sb_req = 0;
		            end
		            else begin 
		            	o_tx_sb_req = 1;
		            end

					// Next State Logic
					if(i_tx_done) begin 
						NS = REPAIRCLK;
						next_substate = 2;
					end 
					else begin 
						NS = REPAIRCLK;
						next_substate = 1;
					end 

				end 

				2: begin 
					// Output State Encoding
					o_tx_encoding = 9'h22;

		            // TX Sending REQ Handshake
		            if (done_ack) begin 
		            	o_tx_sb_req = 0;
		            end
		            else begin 
		            	o_tx_sb_req = 1;
		            end

					// Next State Logic
					if(i_sb_tx_rsp && i_tx_decoding == 9'h22) begin 
						if(&i_tx_info[3:0]) begin 
							NS = REPAIRCLK;
							train_error = 1;
							next_substate = 0;
							substates_done = 1;
						end 
						else begin 
							NS = REPAIRCLK;
							train_error = 0;
							next_substate = 3;
							substates_done = 0;
						end 
					end 
					else begin 
						NS = REPAIRCLK;
						next_substate = 2;
					end 
				end 

				3: begin 
					// Output State Encoding
					o_tx_encoding = 9'h23;

		            // TX Sending REQ Handshake
		            if (done_ack) begin 
		            	o_tx_sb_req = 0;
		            end
		            else begin 
		            	o_tx_sb_req = 1;
		            end

					// Next State Logic
					if(i_sb_tx_rsp && i_tx_decoding == 9'h23) begin 
						NS = REPAIRCLK;
						substates_done = 1;
						next_substate = 0;
					end 
					else begin 
						NS = REPAIRCLK;
						substates_done = 0;
						next_substate = 3;
					end 

				end 

			endcase
		end 

		REPAIRVAL: begin 
			case(current_substate) 
				0: begin 
					o_tx_encoding = 9'h28;

		            // TX Sending REQ Handshake
		            if (done_ack) begin 
		            	o_tx_sb_req = 0;
		            end
		            else begin 
		            	o_tx_sb_req = 1;
		            end

					// Next State Logic
					if(i_sb_tx_rsp && i_tx_decoding == 9'h28) begin 
						NS = REPAIRVAL;
						next_substate = 1;
					end 
					else begin 
						NS = REPAIRVAL;
						next_substate = 0;
					end 

				end 

				1: begin 
					// Output State Encoding
					o_tx_encoding = 9'h29;

		            // TX Sending REQ Handshake
		            if (done_ack) begin 
		            	o_tx_sb_req = 0;
		            end
		            else begin 
		            	o_tx_sb_req = 1;
		            end

					// Next State Logic
					if(i_tx_done) begin 
						NS = REPAIRVAL;
						next_substate = 2;
					end 
					else begin 
						NS = REPAIRVAL;
						next_substate = 1;
					end 

				end 

				2: begin 
					// Output State Encoding
					o_tx_encoding = 9'h2A;

		            // TX Sending REQ Handshake
		            if (done_ack) begin 
		            	o_tx_sb_req = 0;
		            end
		            else begin 
		            	o_tx_sb_req = 1;
		            end

					// Next State Logic
					if(i_sb_tx_rsp && i_tx_decoding == 9'h2A) begin 
						if(&i_tx_info[1:0]) begin 
							NS = REPAIRVAL;
							train_error = 1;
							next_substate = 0;
							substates_done = 1;
						end 
						else begin 
							NS = REPAIRVAL;
							train_error = 0;
							next_substate = 3;
							substates_done = 0;
						end 
					end 
					else begin 
						NS = REPAIRVAL;
						next_substate = 2;
					end 
				end 

				3: begin 
					// Output State Encoding
					o_tx_encoding = 9'h2B;

		            // TX Sending REQ Handshake
		            if (done_ack) begin 
		            	o_tx_sb_req = 0;
		            end
		            else begin 
		            	o_tx_sb_req = 1;
		            end

					// Next State Logic
					if(i_sb_tx_rsp && i_tx_decoding == 9'h2B) begin 
						NS = REVERSAL;
						substates_done = 1;
						next_substate = 0;
					end 
					else begin 
						NS = REPAIRVAL;
						substates_done = 0;
						next_substate = 3;
					end 

				end 

			endcase

		end 

		REVERSAL: begin 
			case(current_substate) 
				0: begin 
					o_tx_encoding = 9'h30;

		            // TX Sending REQ Handshake
		            if (done_ack) begin 
		            	o_tx_sb_req = 0;
		            end
		            else begin 
		            	o_tx_sb_req = 1;
		            end

					// Next State Logic
					if(i_sb_tx_rsp && i_tx_decoding == 9'h30) begin 
						NS = REVERSAL;
						next_substate = 1;
					end 
					else begin 
						NS = REVERSAL;
						next_substate = 0;
					end 

				end 

				1: begin 
					// Output State Encoding
					o_tx_encoding = 9'h31;

		            // TX Sending REQ Handshake
		            if (done_ack) begin 
		            	o_tx_sb_req = 0;
		            end
		            else begin 
		            	o_tx_sb_req = 1;
		            end

					// Next State Logic
					if(i_sb_tx_rsp && i_tx_decoding == 9'h31) begin 
						NS = REVERSAL;
						next_substate = 2;
					end 
					else begin 
						NS = REVERSAL;
						next_substate = 1;
					end 

				end 

				2: begin 
					// Output State Encoding
					o_tx_encoding = 9'h32;

		            // TX Sending REQ Handshake
		            if (done_ack) begin 
		            	o_tx_sb_req = 0;
		            end
		            else begin 
		            	o_tx_sb_req = 1;
		            end

					// Next State Logic
					if(i_tx_done) begin 
						NS = REVERSAL;
						next_substate = 3;
					end 
					else begin 
						NS = REVERSAL;
						next_substate = 2;
					end 
				end 

				3: begin 
					// Output State Encoding
					o_tx_encoding = 9'h33;

		            // TX Sending REQ Handshake
		            if (done_ack) begin 
		            	o_tx_sb_req = 0;
		            end
		            else begin 
		            	o_tx_sb_req = 1;
		            end

					// Next State Logic
					if(i_sb_tx_rsp && i_tx_decoding == 9'h33) begin 
						if(count <= 8) begin 
							NS = REVERSAL;
							next_substate = 4;
						end 
					end 
					else begin 
						NS = REPAIRVAL;
						substates_done = 0;
						next_substate = 5;
					end 

				4: begin 
					// Output State Encoding
					o_tx_encoding = 9'h34;

		            // TX Sending REQ Handshake
		            if (done_ack) begin 
		            	o_tx_sb_req = 0;
		            end
		            else begin 
		            	o_tx_sb_req = 1;
		            end

					// Next State Logic
					if(i_tx_done) begin 
						NS = REVERSAL;
						next_substate = 1;
					end 
					else begin 
						NS = REVERSAL;
						next_substate = 4;
					end 

				5: begin 
					// Output State Encoding
					o_tx_encoding = 9'h35;

		            // TX Sending REQ Handshake
		            if (done_ack) begin 
		            	o_tx_sb_req = 0;
		            end
		            else begin 
		            	o_tx_sb_req = 1;
		            end

					// Next State Logic
					if(i_sb_tx_rsp && i_tx_decoding == 9'h33) begin 
						NS = REPAIRMB;
						substates_done = 1;
						next_substate = 0;
					end 
					else begin 
						NS = REVERSAL;
						substates_done = 0;
						next_substate = 5;
					end 
				end 

			endcase

		end 

		REPAIRMB: begin 
			case(current_substate) 
				0: begin 
					o_tx_encoding = 9'h38;

		            // TX Sending REQ Handshake
		            if (done_ack) begin 
		            	o_tx_sb_req = 0;
		            end
		            else begin 
		            	o_tx_sb_req = 1;
		            end

					// Next State Logic
					if(i_sb_tx_rsp && i_tx_decoding == 9'h38) begin 
						NS = REPAIRMB;

						// this should be data to clock point test
						next_substate = 1;
					end 
					else begin 
						NS = REPAIRMB;
						next_substate = 0;
					end 

				end 

				Data to clock point test: begin 
					// Output State Encoding
					o_tx_encoding = 9'h31;

					// according to the result of the test
					// calculate the lane logic map bits
					extracted_lane_map = ;

				end 

				2: begin 
					// Output State Encoding
					o_tx_encoding = 9'h3A;

		            // TX Sending REQ Handshake
		            if (done_ack) begin 
		            	o_tx_sb_req = 0;
		            end
		            else begin 
		            	o_tx_sb_req = 1;
		            	o_tx_info = extracted_lane_map;
		            end

					// Next State Logic
					if(i_sb_tx_rsp && i_tx_decoding == 9'h3A) begin 
						if(extracted_lane_map == lane_map) begin 
							NS = REPAIRMB;
							next_substate = 3;
						end 
						else begin 
							NS = REPAIRMB;
							next_substate = 1; // data to clock point test again
							lane_map = extracted_lane_map;
						end 
					end 
					else begin 
						NS = REPAIRMB;
						next_substate = 2;
					end 
				end 

				3: begin 
					// Output State Encoding
					o_tx_encoding = 9'h3B;

		            // TX Sending REQ Handshake
		            if (done_ack) begin 
		            	o_tx_sb_req = 0;
		            end
		            else begin 
		            	o_tx_sb_req = 1;
		            end

					// Next State Logic
					if(i_sb_tx_rsp && i_tx_decoding == 9'h3B) begin 
						NS = REVERSAL;
						substates_done = 1;
						next_substate = 0;
					end 
					else begin 
						NS = REPAIRVAL;
						substates_done = 0;
						next_substate = 3;
					end 

			endcase
		end

	endcase
end

		

endmodule