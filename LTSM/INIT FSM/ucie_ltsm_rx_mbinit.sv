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
    input 	[3:0] 					i_current_state,

    output  [DECODING_WIDTH-1:0] 	o_rx_encoding,
    output  [DATA_WIDTH-1:0] 		o_rx_data,
    output  [INFO_WIDTH-1:0] 		o_rx_info,
    output  						o_rx_sb_req, 
    output 							o_rx_sb_rsp,
    output 						 	o_rx_sb_done,
    output  						train_error,
    output							o_done_mbinit_param_rx
    output							o_done_mbinit_cal_rx
    output							o_done_mbinit_repairclk_rx
    output							o_done_mbinit_repairval_rx
    output							o_done_mbinit_reversal_rx
    output							o_done_mbinit_repairmb_rx



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
localparam MBINIT_PARAM 		= 4'b0010;
localparam MBINIT_CAL 			= 4'b0011;
localparam MBINIT_REPAIRCLK 	= 4'b0100;
localparam MBINIT_REPAIRVAL 	= 4'b0101;
localparam MBINIT_REVERSAL 		= 4'b0110;
localparam MBINIT_REPAIRMB 		= 4'b0111;

// substates names (param)
localparam WAIT_CONFIG_REQ 	= 3'b000;
localparam CHECK_PARAMETERS = 3'b001;
localparam SEND_RESP 		= 3'b010;	

// (repair clk)
localparam INIT_HANDSHAKE 		= 3'b000;
localparam PATTERN_DETECTION 	= 3'b001;
localparam WAIT_RESULT_REQ 		= 3'b010;
localparam SEND_RESP 			= 3'b011;
localparam DONE_HANDSHAKE 		= 3'b100;

// (repair val)
localparam INIT_HANDSHAKE 		= 3'b000;
localparam PATTERN_DETECTION 	= 3'b001;
localparam WAIT_RESULT_REQ 		= 3'b010;
localparam SEND_RESP 			= 3'b011;
localparam DONE_HANDSHAKE 		= 3'b100;

// (reversal)
localparam INIT_HANDSHAKE 		= 3'b000;
localparam CLEAR_LOG_HANDSHAKE 	= 3'b001;
localparam LANE_ID_DETECTION 	= 3'b010;
localparam RESULT_HANDSHAKE 	= 3'b011;
localparam DONE_HANDSHAKE 		= 3'b100;

// (repairmb)
localparam INIT_HANDSHAKE 		= 3'b000;
localparam DATA_TO_CLOCK_TEST 	= 3'b001;
localparam WAIT_FOR_DEGRADE_REQ = 3'b010;
localparam DEGRADE 				= 3'b011;
localparam SEND_RESP 			= 3'b100;
localparam DONE_HANDSHAKE 		= 3'b101;


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
    end else if (i_sb_rx_req) begin
        done_ack <= 0;
    end
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
	// u need to form the message 
	if(i_current_state == MBINIT_PARAM && substates_done == 0) begin 
		case(current_substate)
			WAIT_CONFIG_REQ:	// Output State Encoding
				o_rx_encoding = 9'h10;
	            
	            // RX Sending RSP Handshake
	            if (done_ack) begin 
	            	o_rx_sb_rsp = 0;
	            end
	            else begin 
	            	o_rx_sb_rsp = 1;
	            end 

	            // Next State Logic
				if(i_sb_rx_req && i_rx_decoding == 9'h10) begin 
					i_rx_data_reg = i_rx_data;
					o_rx_sb_done = 1;
					next_substate = CHECK_PARAMETERS;
				end 
				else begin 
					next_substate = WAIT_CONFIG_REQ;
				end

		CHECK_PARAMETERS:	// Output State Encoding
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
            // send the resp ⚠️

            // Next State Logic
			if(i_sb_rx_done && i_rx_decoding == 9'h11) begin 
				substates_done = 1;
				next_substate = 0;
			end 
			else begin 
				next_substate = 1;
			end

		// we might not need this state 
		SEND_RESP: begin 
			o_rx_encoding = 9'h12;
            
            // Next State Logic
			if(i_sb_rx_req && i_rx_decoding == 9'h12) begin 
				o_rx_sb_rsp = 1;
				i_rx_data_reg = i_rx_data;
				next_substate = 1;
			end 
			else begin 
				next_substate = 0;
			end

		endcase
	end 

	if(i_current_state == MBINIT_CAL && substates_done == 0) begin 
		// Output State Encoding
		o_rx_encoding = 9'h18;

		// Next State Logic
		// wait till u get a req then send the resp
		if(i_sb_rx_req && i_rx_decoding == 9'h18) begin
			o_rx_sb_rsp = 1;
			o_done_mbinit_cal_rx = 1;
		end 
	end 

	if(i_current_state == MBINIT_REPAIRCLK && substates_done == 0) begin 
		case(current_substate) 
			INIT_HANDSHAKE: begin 
				o_rx_encoding = 9'h20;

				// Next State Logic
				if(i_sb_rx_req && i_rx_decoding == 9'h20) begin 
					o_rx_sb_rsp = 1;
					next_substate = PATTERN_DETECTION;
				end 
				else begin 
					next_substate = INIT_HANDSHAKE;
				end 

			end 

			PATTERN_DETECTION: begin 
				// Output State Encoding
				o_rx_encoding = 9'h21;


				// Next State Logic
				if(i_rx_done) begin 
					next_substate = WAIT_RESULT_REQ;
					i_pattern_detection_results_reg = i_pattern_detection_results;
				end 
				else if (i_sb_rx_req && i_rx_decoding = 9'h22) begin 
					o_rx_sb_rsp = 1;
					next_substate = SEND_RESP;
					i_pattern_detection_results_reg = i_pattern_detection_results;
				end 
				else begin 
					next_substate = PATTERN_DETECTION;
				end 

			end 

			WAIT_RESULT_REQ: begin 
				// Output State Encoding
				o_rx_encoding = 9'h22;
				
				// RX Sending RSP Handshake
	            if (done_ack) begin 
	            	o_rx_sb_rsp = 0;
	            end
	            else begin 
	            	o_rx_sb_rsp = 1;
	            end 

				// Next State Logic
				if(i_sb_rx_req && i_rx_decoding = 9'h22) begin 
					next_substate = SEND_RESP;
				end 
				else begin 
					next_substate = WAIT_RESULT_REQ;
				end 
			end 

			SEND_RESP: begin 
				// Output State Encoding
				o_rx_encoding = 9'h23;

	            o_rx_info[3:0] = i_pattern_detection_results_reg;
	            o_rx_sb_rsp = 1;

				// Next State Logic
				if(i_sb_rx_done && i_rx_decoding == 9'h23) begin 
					substates_done = 0;
					next_substate = DONE_HANDSHAKE;
				end 
				else begin 
					substates_done = 0;
					next_substate = SEND_RESP;
				end 
			end 

			DONE_HANDSHAKE: begin 
				// Output State Encoding
				o_rx_encoding = 9'h24;


				// Next State Logic
				if (i_sb_rx_req && i_rx_decoding = 9'h24) begin 
					o_rx_sb_rsp = 1;
					next_substate = INIT_HANDSHAKE;
					substates_done = 1;
					o_done_mbinit_repairclk_rx = 1;
				end 
				else begin 
					next_substate = DONE_HANDSHAKE;
				end 
			end 
		endcase
	end 

	if(i_current_state == MBINIT_REPAIRVAL && substates_done == 0) begin 
		case(current_substate) 
			INIT_HANDSHAKE: begin 
				o_rx_encoding = 9'h28;


				// Next State Logic
				if(i_sb_rx_req && i_rx_decoding == 9'h28) begin 
					o_rx_sb_rsp = 1;
					next_substate = PATTERN_DETECTION;
				end 
				else begin 
					next_substate = INIT_HANDSHAKE;
				end 

			end 

			PATTERN_DETECTION: begin 
				// Output State Encoding
				o_rx_encoding = 9'h29;


				// Next State Logic
				if(i_rx_done) begin 
					next_substate = WAIT_RESULT_REQ;
					i_pattern_detection_results_reg = i_pattern_detection_results;
				end 
				else if (i_sb_rx_req && i_rx_decoding = 9'h2A) begin 
					o_rx_sb_rsp = 1;
					next_substate = SEND_RESP;
					i_pattern_detection_results_reg = i_pattern_detection_results;
				end 
				else begin 
					next_substate = PATTERN_DETECTION;
				end 

			end 

			WAIT_RESULT_REQ: begin 
				// Output State Encoding
				o_rx_encoding = 9'h2A;


				// Next State Logic
				if(i_sb_rx_req && i_rx_decoding = 9'h2A) begin 
					next_substate = SEND_RESP;
				end 
				else begin 
					next_substate = WAIT_RESULT_REQ;
				end 
			end 

			SEND_RESP: begin 
				// Output State Encoding
				o_rx_encoding = 9'h2B;

	            o_rx_info[1:0] = i_pattern_detection_results_reg;
	            o_rx_sb_rsp = 1;

				// Next State Logic
				if(i_sb_rx_done && i_rx_decoding == 9'h2B) begin 
					substates_done = DONE_HANDSHAKE;
					next_substate = 0;
				end 
				else begin 
					substates_done = 0;
					next_substate = SEND_RESP;
				end 

			end 

			DONE_HANDSHAKE: begin 
				// Output State Encoding
				o_rx_encoding = 9'h2C;

				// Next State Logic
				if (i_sb_rx_req && i_rx_decoding = 9'h2C) begin 
					o_rx_sb_rsp = 1;
					next_substate = INIT_HANDSHAKE;
					substates_done = 1;
					o_done_mbinit_repairval_rx = 1;
				end 
				else begin 
					next_substate = DONE_HANDSHAKE;
				end 
		endcase
	end 

	if(i_current_state == MBINIT_REVERSAL && substates_done == 0) begin 
		case(current_substate) 
			INIT_HANDSHAKE: begin 
				o_rx_encoding = 9'h30;


				// Next State Logic
				if(i_sb_rx_req && i_rx_decoding == 9'h30) begin 
					o_rx_sb_rsp = 1;
					next_substate = CLEAR_LOG_HANDSHAKE;
				end 
				else begin 
					next_substate = INIT_HANDSHAKE;
				end 

			end 

			CLEAR_LOG_HANDSHAKE: begin 
				// Output State Encoding
				o_rx_encoding = 9'h31;


				// Next State Logic
				if(i_sb_rx_req && i_rx_decoding == 9'h31) begin 
					o_rx_sb_rsp = 1;
					next_substate = LANE_ID_DETECTION;
				end 
				else begin 
					next_substate = CLEAR_LOG_HANDSHAKE;
				end 

			end 

			LANE_ID_DETECTION: begin 
				// Output State Encoding
				o_rx_encoding = 9'h32;

				// Next State Logic
				if(i_rx_done) begin 
					next_substate = WAIT_RESULT_REQ;  // wait for req state (need to be added)
					i_pattern_detection_results_reg = i_pattern_detection_results;
				end 
				else if (i_sb_rx_req && i_rx_decoding = 9'h32) begin 
					o_rx_sb_rsp = 1;
					next_substate = RESULT_HANDSHAKE; 
					i_pattern_detection_results_reg = i_pattern_detection_results;
				end 
				else begin 
					next_substate = LANE_ID_DETECTION;
				end 

			end 

			WAIT_RESULT_REQ: begin 
				// Output State Encoding
				o_rx_encoding = 9'h35;  // wait for req state (need to be added)


				// Next State Logic
				if(i_sb_rx_req && i_rx_decoding == 9'h35) begin 
					substates_done = 0;
					next_substate = SEND_RESP;
				end 
				else begin 
					substates_done = 0;
					next_substate = WAIT_RESULT_REQ;
				end 

			end 

			SEND_RESP: begin 
				// Output State Encoding
				o_rx_encoding = 9'h33;

	            // need further processing
	            o_rx_info = i_pattern_detection_results_reg;
	            o_rx_data = i_pattern_detection_results_reg;
	            o_rx_sb_rsp = 1;

				// Next State Logic
				if(i_sb_rx_done && i_rx_decoding == 9'h33) begin 
					if(count <= 8)
					substates_done = 0;
					next_substate = SEND_RESP;
				end 
				else begin 
					NS = REVERSAL;
					substates_done = 0;
					next_substate = DONE_HANDSHAKE;
				end 

			DONE_HANDSHAKE: begin 
				// Output State Encoding
				o_rx_encoding = 9'h34;  // wait for req state (need to be added)


				// Next State Logic
				if(i_sb_rx_req && i_rx_decoding == 9'h34) begin 
					substates_done = 1;
					next_substate = INIT_HANDSHAKE;
					o_done_mbinit_reversal_rx = 1;
				end 
				else begin 
					substates_done = 0;
					next_substate = DONE_HANDSHAKE;
				end 
			end 
		endcase
	end 

	if(i_current_state == MBINIT_REPAIRMB && substates_done == 0) begin 
		case(current_substate) 
			INIT_HANDSHAKE: begin 
				o_rx_encoding = 9'h38;

				// Next State Logic
				if(i_sb_rx_req && i_rx_decoding == 9'h38) begin 
					o_rx_sb_rsp = 1;
					// this should be data to clock point test
					next_substate = DATA_TO_CLOCK_TEST;
				end 
				else begin 
					next_substate = INIT_HANDSHAKE;
				end 

			end 

			DATA_TO_CLOCK_TEST: begin 
				// Output State Encoding
				o_rx_encoding = 9'h31;

				// according to the result of the test
				// calculate the lane logic map bits
				extracted_lane_map = ;

			end 

			WAIT_FOR_DEGRADE_REQ: begin 
				// Output State Encoding
				o_rx_encoding = 9'h3A;

				// Next State Logic
				if(i_sb_rx_req && i_rx_decoding == 9'h3A) begin 
					o_rx_info = extracted_lane_map;
					if(extracted_lane_map == lane_map) begin 
						next_substate = SEND_RESP;
					end 
					else begin 
						next_substate = DEGRADE; // data to clock point test again
						lane_map = extracted_lane_map;
					end 
				end 
				else begin 
					next_substate = WAIT_FOR_DEGRADE_REQ;
				end 
			end 

			DEGRADE: begin 
				// Output State Encoding
				o_rx_encoding = 9'h3B;


				// Next State Logic
				if(i_rx_done) begin 
					substates_done = 0;
					next_substate = SEND_RESP;
				end 
				else begin 
					substates_done = 0;
					next_substate = DEGRADE;
				end 

			SEND_RESP: begin 
				o_rx_encoding = 9'h3C;

	            o_rx_sb_rsp = 1

				// Next State Logic
				if(i_sb_rx_done && i_rx_decoding == 9'h3C) begin 
					NS = REPAIRMB;
					next_substate = DONE_HANDSHAKE;
				end 
				else begin 
					NS = REPAIRMB;
					next_substate = SEND_RESP;
				end 
			end 

			DONE_HANDSHAKE: begin 
				o_rx_encoding = 9'h3D;
	            

				// Next State Logic
				if(i_sb_rx_req && i_rx_decoding == 9'h3D) begin 
					o_rx_sb_rsp = 1
					substates_done = 1;
					next_substate = INIT_HANDSHAKE;
					o_done_mbinit_repairmb_rx = 1;
				end 
				else begin 
					substates_done = 0;
					o_rx_sb_rsp = 1;
					next_substate = DONE_HANDSHAKE;
				end 
			end 
		endcase
	end
endcase
end

		

endmodule