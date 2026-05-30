module rx_error_decoder #(
    parameter int pNUM_LANES  = 16
) (
    input  logic [pNUM_LANES-1:0]           i_rx_LFSR_results,
    input  logic [pNUM_LANES-1:0]           i_rx_lane_id_results,
    input  logic [8:0]                      i_rx_encoding,
    input  logic                            i_data_det_type,
    input  logic [2:0]                      i_clk_results,
    input  logic [2:0]                      i_lane_map,
    input  logic                            i_valid_results,
    output logic [63:0]                     o_rx_data_results,
    output logic                            o_rx_error
);
    assign o_rx_data_results [63:16] = '1;
    always @(*) begin
        if (i_data_det_type) begin
            o_rx_data_results[15:0] = i_rx_LFSR_results;
        end
        else begin
            o_rx_data_results[15:0] = i_rx_lane_id_results;
        end
    end
    assign o_rx_error = (&i_clk_results) && (&i_valid_results) && o_rx_data_results[15:0] ;
endmodule