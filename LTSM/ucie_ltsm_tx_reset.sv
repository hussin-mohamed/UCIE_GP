`define SIM

module ucie_ltsm_tx_reset #(
    parameter DECODING_WIDTH = 9 
) (

    input                               i_clk,
    input                               i_reset,
    input                               i_pll_stable,
    input                               i_supply_stable,
    input                               i_timer_4ms,
    input   [3:0]                       i_current_state,

    output  logic [DECODING_WIDTH-1:0]  o_tx_encoding,
    output  logic                       o_done_reset_tx

);

// Local Parameters for states names
localparam RESET = 4'b0000;


// Internal Signals for latching Exit conditions 
logic i_pll_stable_reg;
logic i_supply_stable_reg;
logic i_timer_4ms_reg;


always @(posedge i_clk or posedge i_reset) begin

    if(i_reset || i_current_state != RESET) begin 
        i_supply_stable_reg <= 0;
        i_pll_stable_reg <= 0;
        i_timer_4ms_reg <= 0;
    end 

    else if(i_current_state == RESET) begin 
        case({i_pll_stable, i_supply_stable})
            2'b01: i_supply_stable_reg <= 1;
            2'b10: i_pll_stable_reg <= 1;
            2'b11: begin 
                i_pll_stable_reg <= 1;
                i_supply_stable_reg <= 1;
            end 
        endcase 

        // latch the timer when reaching 4ms
        if(i_timer_4ms == 1)
            i_timer_4ms_reg <= 1;

    end 
end


always_comb begin 
    //default value for preventing un-wanted latches
    o_tx_encoding = 9'h00;
    o_done_reset_tx = 0;

    if(i_current_state == RESET) begin 
        o_tx_encoding = 9'h00;
        if(i_pll_stable_reg && i_supply_stable_reg && i_timer_4ms_reg) begin 
            o_done_reset_tx = 1;
        end
    end
end 


    // Assertions 

    `ifdef SIM
        property output_encoding;
            @(posedge i_clk) disable iff(i_reset)
            i_current_state == RESET |-> o_tx_encoding == 9'h00;
        endproperty

        OUTPUT_ENCODING_RESET_TX : assert property(output_encoding);


        property reset_done;
            @(posedge i_clk) disable iff(i_reset)
            i_pll_stable_reg && i_supply_stable_reg && i_timer_4ms_reg |-> o_done_reset_tx;
        endproperty

        property regs_clear_outside_reset;
            @(posedge i_clk) disable iff (i_reset)
            i_current_state != RESET |=>
                (!i_pll_stable_reg && !i_supply_stable_reg && !i_timer_4ms_reg);
        endproperty

        REGS_CLEAR_OUTSIDE_RESET : assert property (regs_clear_outside_reset);
    `endif

endmodule