module ucie_TX_Data_to_Clock_eye_sweep (
    input i_clk,
    input i_reset,
    input [DECODING_WIDTH-1:0] i_xx_decoding,
    input [DATA_WIDTH-1:0] i_xx_data,
    input [7:0] i_xx_sweep_result,
    input i_sb_xx_req,
    input i_sb_xx_rsp,
    input i_sb_xx_done,
    input i_xx_done,
    input done_ack,
    input init,
    input no_retry,
    output logic [DECODING_WIDTH-1:0] o_xx_encoding,
    output logic [DATA_WIDTH-1:0] o_xx_data,
    output logic [INFO_WIDTH-1:0] o_xx_info,
    output logic o_xx_sb_req, 
    output logic o_xx_sb_rsp,
    output logic o_xx_sb_done,
    output logic train_error,
    output logic failed_test,
    output logic done
);

localparam REQ_HANDSHAKE = 3'b000;
localparam LFSR_HANDSHAKE = 3'b001;
localparam DATA_GENERATE = 3'b010;
localparam RESULT_HANDSHAKE = 3'b011;
localparam SWEEP_RESULT_HANDSHAKE = 3'b100;
localparam END_HANDSHAKE = 3'b101;

logic [2:0] CS;
logic [2:0] NS;


always @(posedge i_clk or posedge i_reset) begin
    if (i_reset) begin
        CS <= REQ_HANDSHAKE;
    end else begin
        CS <= NS;
    end
end

always @(posedge i_clk or posedge i_reset) begin
    if (i_reset) begin
        o_xx_sb_done <= 0;;
    end else begin
        if (o_xx_sb_done) begin
            o_xx_sb_done <= 0;
        end else if (i_sb_xx_rsp || i_sb_xx_req) begin
            o_xx_sb_done <= 1;
        end
    end
end

always @(*) begin
    if (init) begin
        case (CS)
            REQ_HANDSHAKE: begin
                o_xx_encoding = 'h180;
                done = 0;

                if (done_ack) o_xx_sb_req = 0;
                else o_xx_sb_req = 1;

                o_xx_info = ERROR_THRESHOLD;

                if (i_sb_xx_rsp && i_xx_decoding == 'h180) NS = LFSR_HANDSHAKE;
                else NS = REQ_HANDSHAKE;
            end 

            LFSR_HANDSHAKE: begin
                o_xx_encoding = 'h181;
                done = 0;

                if (done_ack) o_xx_sb_req = 0;
                else o_xx_sb_req = 1;

                if (i_sb_xx_rsp && i_xx_decoding == 'h181) NS = DATA_GENERATE;
                else NS = LFSR_HANDSHAKE;
            end 

            DATA_GENERATE: begin
                o_xx_encoding = 'h182;
                done = 0;

                if (i_xx_done) NS = RESULT_HANDSHAKE;
                else NS = DATA_GENERATE;
            end 

            RESULT_HANDSHAKE: begin
                o_xx_encoding = 'h183;
                done = 0;

                if (done_ack) o_xx_sb_req = 0;
                else o_xx_sb_req = 1;

                if (i_sb_xx_rsp && i_xx_decoding == 'h183) begin
                    failed_test = !(&i_xx_data);
                    if (failed_test && !no_retry) NS = LFSR_HANDSHAKE;
                    else NS = END_HANDSHAKE;
                end else NS = RESULT_HANDSHAKE;
                
            end 

            END_HANDSHAKE: begin
                o_xx_encoding = 'h184;

                if (done_ack) o_xx_sb_req = 0;
                else o_xx_sb_req = 1;

                if (i_sb_xx_rsp && i_xx_decoding == 'h184) done = 1;
                else done = 0;
            end 
        endcase
    end else begin
        case (CS)
            REQ_HANDSHAKE: begin
                o_xx_encoding = 'h185;
                done = 0;

                if (done_ack) o_xx_sb_rsp = 0;
                else if (i_sb_xx_req) o_xx_sb_rsp = 1;

                if (i_sb_xx_done && i_xx_decoding == 'h185) NS = LFSR_HANDSHAKE;
                else NS = REQ_HANDSHAKE;
            end 
    
            LFSR_HANDSHAKE: begin
                o_xx_encoding = 'h186;
                done = 0;

                if (done_ack) o_xx_sb_req = 0;
                else o_xx_sb_req = 1;

                if (i_sb_xx_rsp && i_xx_decoding == 'h186) NS = DATA_GENERATE;
                else NS = LFSR_HANDSHAKE;
            end 
    
            DATA_GENERATE: begin
                o_xx_encoding = 'h187;
                done = 0;

                if (i_xx_done) NS = RESULT_HANDSHAKE;
                else NS = DATA_GENERATE;
            end
    
            RESULT_HANDSHAKE: begin
                o_xx_encoding = 'h188;
                done = 0;

                if (done_ack) o_xx_sb_req = 0;
                else o_xx_sb_req = 1;

                if (i_sb_xx_rsp && i_xx_decoding == 'h188) begin
                    failed_test = !(&i_xx_data);
                    if (failed_test && !no_retry) NS = LFSR_HANDSHAKE;
                    else NS = SWEEP_RESULT_HANDSHAKE;
                end else NS = RESULT_HANDSHAKE;
            end 

            SWEEP_RESULT_HANDSHAKE: begin
                o_xx_encoding = 'h189;
                done = 0;
                o_xx_data = i_xx_sweep_result;

                if (done_ack) o_xx_sb_req = 0;
                else o_xx_sb_req = 1;

                if (done_ack && i_xx_decoding == 'h189) NS = END_HANDSHAKE;
                else NS = SWEEP_RESULT_HANDSHAKE;
            end 
    
            END_HANDSHAKE: begin
                o_xx_encoding = 'h189;
                o_xx_data = 0;
    
                if (done_ack) o_xx_sb_rsp = 0;
                else if (i_sb_xx_req) o_xx_sb_rsp = 1;
    
                if (i_sb_xx_done && i_xx_decoding == 'h189) done = 1;
                else done = 0;
            end 
            default: 
        endcase
    end
end
    
endmodule