module ucie_ltsm_rx_mbinit #(
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
    input 	[DATA_WIDTH-1:0]		i_pattern_detection_results,

    output  [DECODING_WIDTH-1:0] 	o_rx_encoding,
    output  [DATA_WIDTH-1:0] 		o_rx_data,
    output  [INFO_WIDTH-1:0] 		o_rx_info,
    output  						o_rx_sb_req, 
    output 							o_rx_sb_rsp,
    output 						 	o_rx_sb_done,
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
logic [DATA_WIDTH-1:0] i_rx_data_reg;
logic [DATA_WIDTH-1:0] i_pattern_detection_results_reg;


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
    else if (i_sb_rx_done) begin
        done_ack <= 1;
    end else if (i_sb_rx_rsp) begin // shouldn't we here raise the done_ack
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


always_comb begin 
	if(CS == PARAM && current_substate == 1) begin 

end 


always_comb begin
    count = 4'd0; 
    
    if(i_sb_rx_rsp && i_rx_decoding == 9'h33) begin 
	    for (int i = 0; i < 15; i++) begin
	        count = count + i_rx_data[i]; 
	    end
	end
end

always_comb begin 
	case(CS) 
		// u need to form the message 
		PARAM: begin 
			case(current_substate)
			0:	// Output State Encoding
				o_rx_encoding = 9'h10;
	            

	            // Next State Logic
				if(i_sb_rx_req && i_rx_decoding == 9'h10) begin 
					NS = PARAM;
					o_rx_sb_rsp = 1;
					i_rx_data_reg = i_rx_data;
					next_substate = 1;
				end 
				else begin 
					NS = PARAM;
					next_substate = 0;
				end

			1:	// Output State Encoding
				o_rx_encoding = 9'h11;
	            
	            // rx Sending RESP Handshake
	            if (done_ack) begin 
	            	o_rx_sb_req = 0;
	            end
	            else begin 
	            	o_rx_sb_rsp = 1;
	            end 

	            // parameters checking logic
	            // read the parameters from the register 
	            // compare each field in the register with the i_rx_data_reg
	            // assign the new outputs in the o_rx_data 
	            // send the resp

	            // Next State Logic
				if(i_sb_rx_done && i_rx_decoding == 9'h11) begin 
					NS = CAL;
					substates_done = 1;
					next_substate = 0;
				end 
				else begin 
					NS = PARAM;
					next_substate = 1;
				end

			endcase

		end 

		CAL: begin 
			// Output State Encoding
			o_rx_encoding = 9'h18;

			// Next State Logic
			// wait till u get a req then send the resp
			if(i_sb_rx_req && i_rx_decoding == 9'h18) begin 
				NS = REPAIRCLK;
				o_rx_sb_rsp = 1;
			end 
			else begin 
				NS = CAL;
			end 
		end 

		REPAIRCLK: begin 
			case(current_substate) 
				0: begin 
					o_rx_encoding = 9'h20;

					// Next State Logic
					if(i_sb_rx_req && i_rx_decoding == 9'h20) begin 
						NS = REPAIRCLK;
						o_rx_sb_rsp = 1;
						next_substate = 1;
					end 
					else begin 
						NS = REPAIRCLK;
						next_substate = 0;
					end 

				end 

				1: begin 
					// Output State Encoding
					o_rx_encoding = 9'h21;


					// Next State Logic
					if(i_rx_done) begin 
						NS = REPAIRCLK;
						next_substate = 2;
						i_pattern_detection_results_reg = i_pattern_detection_results;
					end 
					else if (i_sb_rx_req && i_rx_decoding = 9'h22) begin 
						o_rx_sb_rsp = 1;
						NS = REPAIRCLK;
						next_substate = 3;
						i_pattern_detection_results_reg = i_pattern_detection_results;
					end 
					else begin 
						NS = REPAIRCLK;
						next_substate = 1;
					end 

				end 

				2: begin 
					// Output State Encoding
					o_rx_encoding = 9'h22;

		            // rx Sending REQ Handshake
		            if (done_ack) begin 
		            	o_rx_sb_req = 0;
		            end
		            else begin 
		            	o_rx_sb_req = 1;
		            end

					// Next State Logic
					if(i_sb_rx_req && i_rx_decoding = 9'h22) begin 
						NS = REPAIRCLK;
 						next_substate = 3;
					end 
					else begin 
						NS = REPAIRCLK;
						next_substate = 2;
					end 
				end 

				3: begin 
					// Output State Encoding
					o_rx_encoding = 9'h23;

		            o_rx_info[3:0] = i_pattern_detection_results_reg;
		            o_rx_sb_rsp = 1;

					// Next State Logic
					if(i_sb_rx_done && i_rx_decoding == 9'h23) begin 
						NS = REPAIRCLK;
						substates_done = 0;
						next_substate = 4;
					end 
					else begin 
						NS = REPAIRCLK;
						substates_done = 0;
						next_substate = 3;
					end 
				end 

				4: begin 
					// Output State Encoding
					o_rx_encoding = 9'h24;


					// Next State Logic
					if (i_sb_rx_req && i_rx_decoding = 9'h24) begin 
						o_rx_sb_rsp = 1;
						NS = REPAIRVAL;
						next_substate = 0;
						substates_done = 1;
					end 
					else begin 
						NS = REPAIRCLK;
						next_substate = 4;
					end 

				end 

			endcase
		end 

		REPAIRVAL: begin 
			case(current_substate) 
				0: begin 
					o_rx_encoding = 9'h28;


					// Next State Logic
					if(i_sb_rx_req && i_rx_decoding == 9'h28) begin 
						NS = REPAIRVAL;
						o_rx_sb_rsp = 1;
						next_substate = 1;
					end 
					else begin 
						NS = REPAIRVAL;
						next_substate = 0;
					end 

				end 

				1: begin 
					// Output State Encoding
					o_rx_encoding = 9'h29;


					// Next State Logic
					if(i_rx_done) begin 
						NS = REPAIRVAL;
						next_substate = 2;
						i_pattern_detection_results_reg = i_pattern_detection_results;
					end 
					else if (i_sb_rx_req && i_rx_decoding = 9'h2A) begin 
						o_rx_sb_rsp = 1;
						NS = REPAIRCLK;
						next_substate = 3;
						i_pattern_detection_results_reg = i_pattern_detection_results;
					end 
					else begin 
						NS = REPAIRVAL;
						next_substate = 1;
					end 

				end 

				2: begin 
					// Output State Encoding
					o_rx_encoding = 9'h2A;


					// Next State Logic
					if(i_sb_rx_req && i_rx_decoding = 9'h2A) begin 
						NS = REPAIRVAL;
 						next_substate = 3;
					end 
					else begin 
						NS = REPAIRVAL;
						next_substate = 2;
					end 
				end 

				3: begin 
					// Output State Encoding
					o_rx_encoding = 9'h2B;

		            o_rx_info[1:0] = i_pattern_detection_results_reg;
		            o_rx_sb_rsp = 1;

					// Next State Logic
					if(i_sb_rx_done && i_rx_decoding == 9'h2B) begin 
						NS = REPAIRVAL;
						substates_done = 4;
						next_substate = 0;
					end 
					else begin 
						NS = REPAIRVAL;
						substates_done = 0;
						next_substate = 3;
					end 

				end 

				4: begin 
					// Output State Encoding
					o_rx_encoding = 9'h2C;

					// Next State Logic
					if (i_sb_rx_req && i_rx_decoding = 9'h2C) begin 
						o_rx_sb_rsp = 1;
						NS = REVERSAL;
						next_substate = 0;
						substates_done = 1;
					end 
					else begin 
						NS = REPAIRVAL;
						next_substate = 4;
					end 
			endcase

		end 

		REVERSAL: begin 
			case(current_substate) 
				0: begin 
					o_rx_encoding = 9'h30;


					// Next State Logic
					if(i_sb_rx_req && i_rx_decoding == 9'h30) begin 
						NS = REVERSAL;
						o_rx_sb_rsp = 1;
						next_substate = 1;
					end 
					else begin 
						NS = REVERSAL;
						next_substate = 0;
					end 

				end 

				1: begin 
					// Output State Encoding
					o_rx_encoding = 9'h31;


					// Next State Logic
					if(i_sb_rx_req && i_rx_decoding == 9'h31) begin 
						NS = REVERSAL;
						o_rx_sb_rsp = 1;
						next_substate = 2;
					end 
					else begin 
						NS = REVERSAL;
						next_substate = 0;
					end 

				end 

				2: begin 
					// Output State Encoding
					o_rx_encoding = 9'h32;

					// Next State Logic
					if(i_rx_done) begin 
						NS = REVERSAL;
						next_substate = 3;  // wait for req state (need to be added)
						i_pattern_detection_results_reg = i_pattern_detection_results;
					end 
					else if (i_sb_rx_req && i_rx_decoding = 9'h32) begin 
						o_rx_sb_rsp = 1;
						NS = REVERSAL;
						next_substate = 4; 
						i_pattern_detection_results_reg = i_pattern_detection_results;
					end 
					else begin 
						NS = REVERSAL;
						next_substate = 1;
					end 

				end 

				3: begin 
					// Output State Encoding
					o_rx_encoding = 9'h35;  // wait for req state (need to be added)


					// Next State Logic
					if(i_sb_rx_req && i_rx_decoding == 9'h35) begin 
						NS = REVERSAL;
						substates_done = 0;
						next_substate = 4;
					end 
					else begin 
						NS = REVERSAL;
						substates_done = 0;
						next_substate = 3;
					end 

				end 

				4: begin 
					// Output State Encoding
					o_rx_encoding = 9'h33;

		            // need further processing
		            o_rx_info = i_pattern_detection_results_reg;
		            o_rx_data = i_pattern_detection_results_reg;
		            o_rx_sb_rsp = 1;

					// Next State Logic
					if(i_sb_rx_done && i_rx_decoding == 9'h33) begin 
						if(count <= 8)
						NS = REVERSAL;
						substates_done = 0;
						next_substate = 1;
					end 
					else begin 
						NS = REVERSAL;
						substates_done = 0;
						next_substate = 5;
					end 

				5: begin 
					// Output State Encoding
					o_rx_encoding = 9'h34;  // wait for req state (need to be added)


					// Next State Logic
					if(i_sb_rx_req && i_rx_decoding == 9'h34) begin 
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
					o_rx_encoding = 9'h38;

					// Next State Logic
					if(i_sb_rx_req && i_rx_decoding == 9'h38) begin 
						NS = REPAIRMB;
						o_rx_sb_rsp = 1;
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
					o_rx_encoding = 9'h31;

					// according to the result of the test
					// calculate the lane logic map bits
					extracted_lane_map = ;

				end 

				2: begin 
					// Output State Encoding
					o_rx_encoding = 9'h3A;

					// Next State Logic
					if(i_sb_rx_req && i_rx_decoding == 9'h3A) begin 
						o_rx_info = extracted_lane_map;
						if(extracted_lane_map == lane_map) begin 
							NS = REPAIRMB;
							next_substate = 4;
						end 
						else begin 
							NS = REPAIRMB;
							next_substate = 3; // data to clock point test again
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
					o_rx_encoding = 9'h3B;


					// Next State Logic
					if(i_rx_done) begin 
						NS = REVERSAL;
						substates_done = 0;
						next_substate = 4;
					end 
					else begin 
						NS = REPAIRVAL;
						substates_done = 0;
						next_substate = 3;
					end 

				4: begin 
					o_rx_encoding = 9'h3C;

		            o_rx_sb_rsp = 1

					// Next State Logic
					if(i_sb_rx_done && i_rx_decoding == 9'h3C) begin 
						NS = REPAIRMB;
						next_substate = 5;
					end 
					else begin 
						NS = REPAIRMB;
						next_substate = 4;
					end 
				end 

				5: begin 
					o_rx_encoding = 9'h3D;
		            

					// Next State Logic
					if(i_sb_rx_req && i_rx_decoding == 9'h3D) begin 
						NS = REPAIRMB;
						o_rx_sb_rsp = 1
						substates_done = 1;
						next_substate = 0;
					end 
					else begin 
						NS = REPAIRMB;
						substates_done = 0;
						o_rx_sb_rsp = 1;
						next_substate = 5;
					end 
				end 
			endcase
		end

	endcase
end

		

endmodule