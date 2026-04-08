
module LFSR_tb;
    parameter int pDATA_WIDTH = 32; 
    parameter int pNUM_LANES  = 16;

    logic [pNUM_LANES-1:0][pDATA_WIDTH-1:0] o_data_out_rx,i_data_in_tx;
    logic [pNUM_LANES-1:0] o_lane_success;
    bit i_clk,i_reset_n,i_load,i_train;
    bit [pNUM_LANES-1:0] i_enable;
    logic [pNUM_LANES-1:0][pDATA_WIDTH-1:0] scrambled_data;
    logic [15:0] i_error_threshhold;
    int i;

    rx_LFSR_top #(
        .pDATA_WIDTH(pDATA_WIDTH),
        .pNUM_LANES(pNUM_LANES)
    ) dut(
        .o_data_out(o_data_out_rx),
        .o_lane_success(o_lane_success),
        .i_clk(i_clk),
        .i_reset_n(i_reset_n),
        .i_load(i_load),
        .i_train(i_train),
        .i_enable(i_enable),
        .i_data_in(scrambled_data),
        .i_error_threshhold(i_error_threshhold)
    );
    tx_LFSR_top #(
        .pDATA_WIDTH(pDATA_WIDTH),
        .pNUM_LANES(pNUM_LANES)
    ) tx (
        .o_data_out(scrambled_data),
        .i_clk(i_clk),
        .i_load(i_load),
        .i_train(i_train),
        .i_enable(i_enable),
        .i_data_in(i_data_in_tx)
    );
 


initial begin
    forever begin
        #5;
        i_clk = ~i_clk;
    end
end



initial begin
    i_reset_n = 0;
    i_load = 0;
    i_train = 0;
    i_enable = 0;
    i_data_in_tx = 0;
    i_error_threshhold = 16'h0000;
    repeat (2) @(negedge i_clk);
    i_reset_n = 1;
    i_load=1;
    i_enable = 16'hFFFF;
    i_train=1;
    if (o_lane_success) begin
        $display("testpassed");
    end
    else begin
        $display("testfailed");
    end
    @(negedge i_clk);
    i_load=0;
    repeat (10) begin

       @(negedge i_clk); 
       if (o_lane_success) begin
        $display("testpassed");
    end
    else begin
        $display("testfailed");
    end
    end
    i_train=0;
    for (i = 0 ; i < pNUM_LANES ; i = i + 1 ) begin
        i_data_in_tx[i] = 32'hABCD1234;
    end
    @(negedge i_clk);
    repeat (10) begin
       @(negedge i_clk);
    if (o_data_out_rx == i_data_in_tx) begin
        $display("testpassed");
    end
    else begin
        $display("testfailed");
    end 
    end
    $stop;
end

endmodule
