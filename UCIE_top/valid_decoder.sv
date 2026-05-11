module valid_decoder (
    input i_valid,
    input [8:0] i_encoding,
    input i_req,
    input i_rsp,
    input [63:0] i_data,
    input i_info,
    output logic [8:0] o_decoding,
    output logic [63:0] o_data,
    output logic [7:0] o_info,
    output logic o_req,
    output logic o_rsp
);
    always @(*) begin
        if (i_valid) begin
            o_decoding = i_encoding;
            o_data = i_data;
            o_info = i_info;
            o_req = i_req;
            o_rsp = i_rsp;
        end
        else begin
            o_decoding = 9'b0;
            o_data = 64'b0;
            o_info = 8'b0;
            o_req = 1'b0;
            o_rsp = 1'b0;
        end
    end
endmodule