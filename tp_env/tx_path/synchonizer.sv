module synchonizer #(
    parameter width = 2
) (
    input i_clk,input [width-1:0] data_in,
    output logic [width-1:0] data_out
);
    logic [width-1:0] sync_1;
    always_ff @(posedge i_clk) begin
        sync_1 <= data_in;
        data_out <= sync_1;
    end
endmodule
