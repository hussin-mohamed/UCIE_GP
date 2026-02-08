module ucie_LTSM_TX_MBTRAIN #(
    parameter DECODING_WIDTH = 9,
    parameter DATA_WIDTH = 64,
    parameter INFO_WIDTH = 16,
    parameter ERROR_THRESHOLD = 0
) (
    input i_clk,
    input i_reset,
    input [DECODING_WIDTH-1:0] i_tx_decoding,
    input [DATA_WIDTH-1:0] i_tx_data,
    input [INFO_WIDTH-1:0] i_tx_info,
    input [7:0] i_tx_sweep_result,
    input i_sb_tx_req,
    input i_sb_tx_rsp,
    input i_sb_tx_done,
    input i_tx_done,
    input init_train_en,
    input timeout,
    input o_rx_sb_rsp,
    input [2:0] o_pl_speedmode,
    output logic [DECODING_WIDTH-1:0] o_tx_encoding,
    output logic [DATA_WIDTH-1:0] o_tx_data,
    output logic [INFO_WIDTH-1:0] o_tx_info,
    output logic o_tx_sb_req, 
    output logic o_tx_sb_rsp,
    output logic o_tx_sb_done,
    output logic train_error,
    output logic train_active_en
);

logic [6:0] CS;
logic [6:0] NS;

localparam VALVREF = 4'b0000;
localparam DATAVREF = 4'b0001;
localparam SPEEDIDLE = 4'b0011;
localparam TXSELFCAL = 4'b0010;
localparam RXCLKCAL = 4'b0110;
localparam VALTRAINCENTER = 4'b0111;
localparam VALTRAINVREF = 4'b0101;
localparam DATATRAINCENTER1 = 4'b0100;
localparam DATATRAINVREF = 4'b1100;
localparam RXDESKEW = 4'b1101;
localparam DATATRAINCENTER2 = 4'b1111;
localparam LINKSPEED = 4'b1110;
localparam REPAIR = 4'b1010;


logic [DECODING_WIDTH-1:0] o_tx_encoding_reg;
logic [DATA_WIDTH-1:0] o_tx_data_reg;
logic [INFO_WIDTH-1:0] o_tx_info_reg;
logic o_tx_sb_req_reg;
logic o_tx_sb_rsp_reg;
logic o_tx_sb_done_reg;
logic train_error_reg;
logic failed_test;

logic [DECODING_WIDTH-1:0] o_tx_encoding_data_to_clock_test;
logic [DATA_WIDTH-1:0] o_tx_data_data_to_clock_test;
logic [INFO_WIDTH-1:0] o_tx_info_data_to_clock_test;
logic o_tx_sb_req_data_to_clock_test;
logic o_tx_sb_rsp_data_to_clock_test;
logic o_tx_sb_done_data_to_clock_test;
logic train_error_data_to_clock_test;
logic failed_test;

logic [2:0] current_substate;
logic [2:0] next_substate;

logic done_ack;
logic clock_to_test_enable;
logic clock_to_test_done;
logic substates_done;
logic previous_state_done;
logic rsp_sent;
logic [DECODING_WIDTH-1:0] encoding_rsp_sent;
logic [DECODING_WIDTH-1:0] encoding_rsp_received;

ucie_TX_Data_to_Clock_eye_sweep ucie_TX_Data_to_Clock_eye_sweep_inst (
    .i_clk(i_clk),
    .i_reset(i_reset || !clock_to_test_enable),
    .i_xx_decoding(i_tx_decoding),
    .i_xx_data(i_tx_data),
    .i_xx_sweep_result(i_xx_sweep_result),
    .i_sb_xx_req(i_sb_tx_req),
    .i_sb_xx_rsp(i_sb_tx_rsp),
    .i_sb_xx_done(i_sb_tx_done),
    .i_xx_done(i_tx_done),
    .done_ack(done_ack),
    .init(init),
    .no_retry(no_retry),
    .o_xx_encoding(o_tx_encoding_data_to_clock_test),
    .o_xx_data(o_tx_data_data_to_clock_test),
    .o_xx_info(o_tx_info_data_to_clock_test),
    .o_xx_sb_req(o_tx_sb_req_data_to_clock_test), 
    .o_xx_sb_rsp(o_tx_sb_rsp_data_to_clock_test),
    .o_xx_sb_done(o_tx_sb_done_data_to_clock_test),
    .train_error(train_error_data_to_clock_test),
    .failed_test(failed_test),
    .done(clock_to_test_done)
);

assign previous_state_done = (!i_reset)? 0 : (rsp_sent & rsp_received);

assign train_error_reg = timeout || train_error_data_to_clock_test || SPEEDIDLE_trainerror;

always @(posedge i_clk or posedge i_reset) begin
    if (i_reset || !init_train_en) begin
        CS <= VALVREF;
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
    end else if (i_sb_tx_rsp) begin
        done_ack <= 0;
    end
end

always @(posedge i_clk or posedge i_reset) begin
    if (i_reset) begin
        o_tx_sb_done <= 0;;
    end else begin
        if (o_tx_sb_done) begin
            o_tx_sb_done <= 0;
        end else if (i_sb_tx_rsp || i_sb_tx_req) begin
            o_tx_sb_done <= 1;
        end
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

always @(*) begin
    if (train_error_reg) begin
        NS = VALVREF;
        substates_done = 0;
    end else begin
        case (CS)
            VALVREF: begin
                if (!substates_done) begin
                    case (current_substate)
                        0: begin
                            o_tx_encoding_reg = 'h80;
                            train_active_en = 0;
                            NS = VALVREF;
                            substates_done = 0;
                            clock_to_test_enable = 0;
                            train_error_data_to_clock_test = 0;
                            SPEEDIDLE_trainerror = 0;

                            if (done_ack) o_tx_sb_req_reg = 0;
                            else o_tx_sb_req_reg = 1;

                            if (i_sb_tx_rsp && i_tx_decoding == 'h80) next_substate = 1;
                            else next_substate = 0;
                        end  

                        1:begin
                            clock_to_test_enable = 1;
                            o_tx_encoding_reg = o_tx_encoding_data_to_clock_test;
                            o_tx_data_reg = o_tx_data_data_to_clock_test;
                            o_tx_info_reg = o_tx_info_data_to_clock_test;
                            o_tx_sb_req_reg = o_tx_sb_req_data_to_clock_test;
                            o_tx_sb_rsp_reg = o_tx_sb_rsp_data_to_clock_test;
                            o_tx_sb_done_reg = o_tx_sb_done_data_to_clock_test;
                            init = 0;
                            no_retry = 0;
                            substates_done = 0;

                            if (clock_to_test_done) next_substate = 1;
                            else next_substate = 0;
                        end

                        2: begin
                            clock_to_test_enable = 0;
                            train_error_data_to_clock_test = 0;

                            o_tx_encoding_reg = 'h82; 
                            NS = VALVREF;

                            if (done_ack) o_tx_sb_req_reg = 0;
                            else o_tx_sb_req_reg = 1;

                            if (i_sb_tx_rsp && i_tx_decoding == 'h82) begin
                                substates_done = 1;
                                next_substate = 0;
                            end else begin
                                substates_done = 0;
                                next_substate = 2;
                            end 
                        end  
                    endcase
                end
                if (previous_state_done && encoding_rsp_sent == 'h82 && encoding_rsp_received == 'h82) begin
                    NS = DATAVREF;
                    substates_done = 0;
                end else begin
                    NS = VALVREF;
                    substates_done = 1;
                end 

            end 

            DATAVREF: begin
                if (!substates_done) begin
                    case (current_substate)
                        0: begin
                            o_tx_encoding_reg = 'hF0;
                            NS = DATAVREF;
                            substates_done = 0;

                            if (done_ack) o_tx_sb_req_reg = 0;
                            else o_tx_sb_req_reg = 1;

                            if (i_sb_tx_rsp && i_tx_decoding == 'hF0) next_substate = 1;
                            else next_substate = 0;
                        end  

                        1: begin
                            clock_to_test_enable = 1;
                            o_tx_encoding_reg = o_tx_encoding_data_to_clock_test;
                            o_tx_data_reg = o_tx_data_data_to_clock_test;
                            o_tx_info_reg = o_tx_info_data_to_clock_test;
                            o_tx_sb_req_reg = o_tx_sb_req_data_to_clock_test;
                            o_tx_sb_rsp_reg = o_tx_sb_rsp_data_to_clock_test;
                            o_tx_sb_done_reg = o_tx_sb_done_data_to_clock_test;
                            init = 0;
                            no_retry = 0;
                            substates_done = 0;

                            if (clock_to_test_done) next_substate = 1;
                            else next_substate = 0;
                        end  

                        2: begin
                            clock_to_test_enable = 0;
                            train_error_data_to_clock_test = 0;

                            o_tx_encoding_reg = 'hF2;
                            NS = DATAVREF; 

                            if (done_ack) o_tx_sb_req_reg = 0;
                            else o_tx_sb_req_reg = 1;

                            if (i_sb_tx_rsp && i_tx_decoding == 'hF2) begin
                                substates_done = 1;
                                next_substate = 0;
                            end else begin
                                substates_done = 0;
                                next_substate = 2;
                            end 
                        end  
                    endcase
                end
               if (previous_state_done && encoding_rsp_sent == 'hF2 && encoding_rsp_received == 'hF2) begin
                    NS = SPEEDIDLE;
                    substates_done = 0;
                end else begin
                    NS = DATAVREF;
                    substates_done = 1;
                end 
            end

            SPEEDIDLE: begin
                if (!substates_done) begin
                    case (current_substate)
                        0: begin
                            o_tx_encoding_reg = 'hC8;
                            NS = SPEEDIDLE;
                            substates_done = 0;

                            if (!o_pl_speedmode) next_substate = 2; 
                            else if (i_tx_done) next_substate = 1;
                            else next_substate = 0;
                        end  

                        1: begin
                            o_tx_encoding_reg = 'hCA; 

                            if (done_ack) o_tx_sb_req_reg = 0;
                            else o_tx_sb_req_reg = 1;
                            NS = SPEEDIDLE;

                            if (i_sb_tx_rsp && i_tx_decoding == 'hCA) begin
                                substates_done = 1;
                                next_substate = 0;
                            end else begin
                                substates_done = 0;
                                next_substate = 1;
                            end 
                        end 

                        2: begin
                            o_tx_encoding_reg = 'hC9; 

                            if (done_ack) o_tx_sb_req_reg = 0;
                            else o_tx_sb_req_reg = 1;
                            NS = SPEEDIDLE;

                            if (i_sb_tx_rsp && i_tx_decoding == 'hC9) begin
                                substates_done = 1;
                                next_substate = 0;
                            end else begin
                                substates_done = 0;
                                next_substate = 2;
                            end 
                        end  
                    endcase
                end
                if (previous_state_done) begin
                    substates_done = 0;
                    if (encoding_rsp_sent == 'hCA && encoding_rsp_received == 'hCA) beg NS = TXSELFCAL;
                    else if (encoding_rsp_sent == 'hC9 && encoding_rsp_received == 'hC9) begin
                        SPEEDIDLE_trainerror = 1;
                    end
                end else begin
                    NS = SPEEDIDLE;
                    substates_done = 1;
                end 
            end

            TXSELFCAL: begin
                if (!substates_done) begin
                    case (current_substate)
                        0: begin
                            o_tx_encoding_reg = 'hD0;
                            NS = TXSELFCAL;
                            substates_done = 0;

                            if (i_tx_done) next_substate = 1;
                            else next_substate = 0;
                        end  

                        1: begin
                            o_tx_encoding_reg = 'hD1; 
                            NS = TXSELFCAL;

                            if (done_ack) o_tx_sb_req_reg = 0;
                            else o_tx_sb_req_reg = 1;

                            if (i_sb_tx_rsp && i_tx_decoding == 'hD1) begin
                                substates_done = 1;
                                next_substate = 0;
                            end else begin
                                substates_done = 0;
                                next_substate = 2;
                            end 
                        end  
                    endcase
                end
                if (previous_state_done && encoding_rsp_sent == 'hD1 && encoding_rsp_received == 'hD1) begin
                    NS = RXCLKCAL;
                end else begin

                end NS = TXSELFCAL;
            end

            RXCLKCAL: begin
                if (!substates_done) begin
                    case (current_substate)
                        0: begin
                            o_tx_encoding_reg = 'h98;
                            NS = RXCLKCAL;
                            substates_done = 0;

                            if (done_ack) o_tx_sb_req_reg = 0;
                            else o_tx_sb_req_reg = 1;

                            if (i_sb_tx_rsp && i_tx_decoding == 'h98) next_substate = 1;
                            else next_substate = 0;
                        end  

                        1: begin
                            o_tx_encoding_reg = 'h9A; 
                            NS = RXCLKCAL;

                            if (done_ack) o_tx_sb_req_reg = 0;
                            else o_tx_sb_req_reg = 1;

                            if (i_sb_tx_rsp && i_tx_decoding == 'h9A) begin
                                substates_done = 1;
                                next_substate = 0;
                            end else begin
                                substates_done = 0;
                                next_substate = 1;
                            end 
                        end  
                    endcase
                end 
                if (previous_state_done && encoding_rsp_sent == 'h9A && encoding_rsp_received == 'h9A) begin
                    NS = VALTRAINCENTER;
                    substates_done = 0;
                end else begin
                    NS = RXCLKCAL;
                    substates_done = 1;
                end 
            end

            VALTRAINCENTER: begin
                if (!substates_done) begin
                    case (current_substate)
                        0: begin
                            o_tx_encoding_reg = 'hA0;
                            NS = VALTRAINCENTER;
                            substates_done = 0;

                            if (done_ack) o_tx_sb_req_reg = 0;
                            else o_tx_sb_req_reg = 1;

                            if (i_sb_tx_rsp && i_tx_decoding == 'hA0) next_substate = 1;
                            else next_substate = 0;
                        end  

                        1: begin
                            clock_to_test_enable = 1;
                            o_tx_encoding_reg = o_tx_encoding_data_to_clock_test;
                            o_tx_data_reg = o_tx_data_data_to_clock_test;
                            o_tx_info_reg = o_tx_info_data_to_clock_test;
                            o_tx_sb_req_reg = o_tx_sb_req_data_to_clock_test;
                            o_tx_sb_rsp_reg = o_tx_sb_rsp_data_to_clock_test;
                            o_tx_sb_done_reg = o_tx_sb_done_data_to_clock_test;
                            init = 0;
                            no_retry = 1;
                            substates_done = 0;

                            if (clock_to_test_done) next_substate = 1;
                            else next_substate = 0;
                        end  

                        2: begin
                            clock_to_test_enable = 0;
                            train_error_data_to_clock_test = 0;

                            o_tx_encoding_reg = 'hA2; 
                            NS = VALTRAINCENTER;

                            if (done_ack) o_tx_sb_req_reg = 0;
                            else o_tx_sb_req_reg = 1;

                            if (i_sb_tx_rsp && i_tx_decoding == 'hA2) begin
                                substates_done = 1;
                                next_substate = 0;
                            end else begin
                                substates_done = 0;
                                next_substate = 2;
                            end 
                        end  
                    endcase
                end
                if (previous_state_done && encoding_rsp_sent == 'hA2 && encoding_rsp_received == 'hA2) begin
                    NS = VALTRAINVREF;
                    substates_done = 0;
                end else begin
                    NS = VALTRAINCENTER;
                    substates_done = 1;
                end 

            end

            VALTRAINVREF: begin
                if (!substates_done) begin
                    case (current_substate)
                        0: begin
                            o_tx_encoding_reg = 'hE8;
                            NS = VALTRAINVREF;
                            substates_done = 0;

                            if (done_ack) o_tx_sb_req_reg = 0;
                            else o_tx_sb_req_reg = 1;

                            if (i_sb_tx_rsp && i_tx_decoding == 'hE8) next_substate = 1;
                            else next_substate = 0;
                        end  

                        1: begin
                            clock_to_test_enable = 1;
                            o_tx_encoding_reg = o_tx_encoding_data_to_clock_test;
                            o_tx_data_reg = o_tx_data_data_to_clock_test;
                            o_tx_info_reg = o_tx_info_data_to_clock_test;
                            o_tx_sb_req_reg = o_tx_sb_req_data_to_clock_test;
                            o_tx_sb_rsp_reg = o_tx_sb_rsp_data_to_clock_test;
                            o_tx_sb_done_reg = o_tx_sb_done_data_to_clock_test;
                            init = 0;
                            no_retry = 0;
                            substates_done = 0;

                            if (clock_to_test_done) next_substate = 1;
                            else next_substate = 0;
                        end  

                        2: begin
                            clock_to_test_enable = 0;
                            train_error_data_to_clock_test = 0;

                            o_tx_encoding_reg = 'hEA; 
                            NS = VALTRAINVREF;

                            if (done_ack) o_tx_sb_req_reg = 0;
                            else o_tx_sb_req_reg = 1;

                            if (i_sb_tx_rsp && i_tx_decoding == 'hEA) begin
                                substates_done = 1;
                                next_substate = 0;
                            end else begin
                                substates_done = 0;
                                next_substate = 2;
                            end 
                        end  
                    endcase
                end 
                if (previous_state_done && encoding_rsp_sent == 'hEA && encoding_rsp_received == 'hEA) begin
                    NS = DATATRAINCENTER1;
                    substates_done = 0;
                end else begin
                    NS = VALTRAINVREF;
                    substates_done = 1;
                end
            end

            DATATRAINCENTER1: begin
                if (!substates_done) begin
                    case (current_substate)
                        0: begin
                            o_tx_encoding_reg = 'h90;
                            NS = DATATRAINCENTER1;
                            substates_done = 0;
                            i_tx_info = ERROR_THRESHOLD;

                            if (done_ack) o_tx_sb_req_reg = 0;
                            else o_tx_sb_req_reg = 1;

                            if (i_sb_tx_rsp && i_tx_decoding == 'h90) next_substate = 1;
                            else next_substate = 0;
                        end  

                        1: begin
                            clock_to_test_enable = 1;
                            o_tx_encoding_reg = o_tx_encoding_data_to_clock_test;
                            o_tx_data_reg = o_tx_data_data_to_clock_test;
                            o_tx_info_reg = o_tx_info_data_to_clock_test;
                            o_tx_sb_req_reg = o_tx_sb_req_data_to_clock_test;
                            o_tx_sb_rsp_reg = o_tx_sb_rsp_data_to_clock_test;
                            o_tx_sb_done_reg = o_tx_sb_done_data_to_clock_test;
                            init = 0;
                            no_retry = 1;
                            substates_done = 0;


                            if (clock_to_test_done) next_substate = 1;
                            else next_substate = 0;
                        end  

                        2: begin
                            clock_to_test_enable = 0;
                            train_error_data_to_clock_test = 0;

                            o_tx_encoditmnuhy
                            ng_reg = 'h92; 
                            NS = DATATRAINCENTER1;

                            if (done_ack) o_tx_sb_req_reg = 0;
                            else o_tx_sb_req_reg = 1;

                            if (i_sb_tx_rsp && i_tx_decoding == 'h92) begin
                                substates_done = 1;
                                next_substate = 0;
                            end else begin
                                substates_done = 0;
                                next_substate = 2;
                            end 
                        end  
                    endcase
                end 
                if (previous_state_done && encoding_rsp_sent == 'h92 && encoding_rsp_received == 'h92) begin
                    NS = DATATRAINVREF;
                    substates_done = 0;
                end else begin
                    NS = DATATRAINCENTER1;
                    substates_done = 1;
                end
            end

            DATATRAINVREF: begin
                if (!substates_done) begin
                    case (current_substate)
                        0: begin
                            o_tx_encoding_reg = 'hF0;
                            NS = DATATRAINVREF;
                            substates_done = 0;

                            if (done_ack) o_tx_sb_req_reg = 0;
                            else o_tx_sb_req_reg = 1;

                            if (i_sb_tx_rsp && i_tx_decoding == 'hF0) next_substate = 1;
                            else next_substate = 0;
                        end  

                        1: begin
                            clock_to_test_enable = 1;
                            o_tx_encoding_reg = o_tx_encoding_data_to_clock_test;
                            o_tx_data_reg = o_tx_data_data_to_clock_test;
                            o_tx_info_reg = o_tx_info_data_to_clock_test;
                            o_tx_sb_req_reg = o_tx_sb_req_data_to_clock_test;
                            o_tx_sb_rsp_reg = o_tx_sb_rsp_data_to_clock_test;
                            o_tx_sb_done_reg = o_tx_sb_done_data_to_clock_test;
                            init = 0;
                            no_retry = 0;
                            substates_done = 0;

                            if (clock_to_test_done) next_substate = 1;
                            else next_substate = 0;
                        end  

                        2: begin
                            clock_to_test_enable = 0;
                            train_error_data_to_clock_test = 0;

                            o_tx_encoding_reg = 'hF2;
                            NS = DATATRAINVREF; 

                            if (done_ack) o_tx_sb_req_reg = 0;
                            else o_tx_sb_req_reg = 1;

                            if (i_sb_tx_rsp && i_tx_decoding == 'hF2) begin
                                substates_done = 1;
                                next_substate = 0;
                            end else begin
                                substates_done = 0;
                                next_substate = 2;
                            end 
                        end  
                    endcase
                end
                if (previous_state_done && encoding_rsp_sent == 'h8A && encoding_rsp_received == 'h8A) begin
                    NS = SPEEDIDLE;
                    substates_done = 0;
                end else begin
                    NS = DATATRAINVREF;
                    substates_done = 1;
                end 
            end

            RXDESKEW: begin
                if (!substates_done) begin
                    case (current_substate)
                        0: begin
                            o_tx_encoding_reg = 'hA8;
                            NS = RXDESKEW;
                            substates_done = 0;

                            if (done_ack) o_tx_sb_req_reg = 0;
                            else o_tx_sb_req_reg = 1;

                            if (i_sb_tx_rsp && i_tx_decoding == 'hA8) next_substate = 1;
                            else next_substate = 0;
                        end  

                        1: begin
                            o_tx_encoding_reg = 'hAC; 
                            NS = RXDESKEW;

                            if (done_ack) o_tx_sb_req_reg = 0;
                            else o_tx_sb_req_reg = 1;

                            if (i_sb_tx_rsp && i_tx_decoding == 'hAC) begin
                                substates_done = 1;
                                next_substate = 0;
                            end else begin
                                substates_done = 0;
                                next_substate = 1;
                            end 
                        end  
                    endcase
                end 
                if (previous_state_done && encoding_rsp_sent == 'hAC && encoding_rsp_received == 'hAC) begin
                    NS = DATATRAINCENTER2;
                    substates_done = 0;
                end else begin
                    NS = RXDESKEW;
                    substates_done = 1;
                end 
            end

            DATATRAINCENTER2: begin
                if (!substates_done) begin
                    case (current_substate)
                        0: begin
                            o_tx_encoding_reg = 'hB0;
                            NS = DATATRAINCENTER2;
                            substates_done = 0;
                            i_tx_info = ERROR_THRESHOLD;

                            if (done_ack) o_tx_sb_req_reg = 0;
                            else o_tx_sb_req_reg = 1;

                            if (i_sb_tx_rsp && i_tx_decoding == 'hB0) next_substate = 1;
                            else next_substate = 0;
                        end  

                        1: begin
                            clock_to_test_enable = 1;
                            o_tx_encoding_reg = o_tx_encoding_data_to_clock_test;
                            o_tx_data_reg = o_tx_data_data_to_clock_test;
                            o_tx_info_reg = o_tx_info_data_to_clock_test;
                            o_tx_sb_req_reg = o_tx_sb_req_data_to_clock_test;
                            o_tx_sb_rsp_reg = o_tx_sb_rsp_data_to_clock_test;
                            o_tx_sb_done_reg = o_tx_sb_done_data_to_clock_test;
                            init = 0;
                            no_retry = 1;
                            substates_done = 0;


                            if (clock_to_test_done) next_substate = 1;
                            else next_substate = 0;
                        end  

                        2: begin
                            clock_to_test_enable = 0;
                            train_error_data_to_clock_test = 0;

                            o_tx_encoditmnuhy
                            ng_reg = 'hB2; 
                            NS = DATATRAINCENTER2;

                            if (done_ack) o_tx_sb_req_reg = 0;
                            else o_tx_sb_req_reg = 1;

                            if (i_sb_tx_rsp && i_tx_decoding == 'hB2) begin
                                substates_done = 1;
                                next_substate = 0;
                            end else begin
                                substates_done = 0;
                                next_substate = 2;
                            end 
                        end  
                    endcase
                end 
                if (previous_state_done && encoding_rsp_sent == 'hB2 && encoding_rsp_received == 'hB2) begin
                    train_active_en = 1;
                    NS = VALVREF;
                    substates_done = 0;
                end else begin  
                    NS = DATATRAINCENTER2;
                    substates_done = 1;
                end
            end
        endcase
    end
end
endmodule