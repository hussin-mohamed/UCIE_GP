module ucie_ltsm_rx_reset #(
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
    input                           i_pll_stable,
    input                           i_supply_stable,
    input                           i_timer_4ms,

    output  [DECODING_WIDTH-1:0] 	o_tx_encoding,
    output  [DATA_WIDTH-1:0] 		o_tx_data,
    output  [INFO_WIDTH-1:0] 		o_tx_info,
    output  						o_tx_sb_req, 
    output 							o_tx_sb_rsp,
    output 						 	o_tx_sb_done,
    output  						train_error,
    output                          done_reset

);

// should be exported to the outer interface ?
logic [3:0] CS;									// current big state (SBINIT)
logic [3:0] NS;									// next big state (MBINIT)
			
logic [2:0] current_substate;					// current substate 
logic [2:0] next_substate;						// next substate

logic done_ack;
logic substates_done;
logic previous_state_done;
logic i_pll_stable_reg;
logic i_supply_stable_reg;
logic i_timer_4ms_reg;

localparam RESET = 4'b0000;
// substates names 


// ToDo : the logic for the start of this state


always @(posedge i_clk or posedge i_reset) begin
    if(CS == RESET) begin 
        case(i_pll_stable, i_supply_stable)
            01: i_supply_stable_reg <= 1;
            10: i_pll_stable_reg <= 1;
            11: begin 
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
    if(CS == RESET) begin 
        if(i_pll_stable_reg && i_supply_stable_reg && i_timer_4ms) begin 
            done_reset = 1;
        end
    end
end 