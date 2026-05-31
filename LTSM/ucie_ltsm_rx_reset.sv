`define SIM
module ucie_ltsm_rx_reset #(
    parameter DECODING_WIDTH = 9
) (
    input                               i_clk,
    input                               i_reset,
    input                               init_train_en,      
    input                               i_pll_stable,
    input                               i_supply_stable,
    input                               i_timer_4ms,
    input   [3:0]                       i_current_state,
    output  logic [DECODING_WIDTH-1:0]  o_rx_encoding,      
    output  logic                       o_done_reset_rx     
);

    // -------------------------------------------------------------------------
    // Local parameters
    // -------------------------------------------------------------------------
    localparam logic [3:0] RESET = 4'b0000;

    // -------------------------------------------------------------------------
    // Internal signals — latch exit conditions independently
    // -------------------------------------------------------------------------
    logic i_pll_stable_reg;
    logic i_supply_stable_reg;
    logic i_timer_4ms_reg;

    // -------------------------------------------------------------------------
    // Latch registers — set when condition arrives, clear on reset or state leave
    // -------------------------------------------------------------------------
    always_ff @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            i_supply_stable_reg <= 0;
            i_pll_stable_reg    <= 0;
            i_timer_4ms_reg     <= 0;
        end
        else if (i_current_state != RESET) begin
            i_supply_stable_reg <= 0;
            i_pll_stable_reg    <= 0;
            i_timer_4ms_reg     <= 0;
        end
        else if (i_current_state == RESET) begin
            case ({i_pll_stable, i_supply_stable})
                2'b01: i_supply_stable_reg <= 1;
                2'b10: i_pll_stable_reg    <= 1;
                2'b11: begin
                    i_pll_stable_reg    <= 1;
                    i_supply_stable_reg <= 1;
                end
                default: ; // 2'b00 — nothing to latch
            endcase
            // Latch the timer when it pulses high
            if (i_timer_4ms)
                i_timer_4ms_reg <= 1;
        end
    end

    // -------------------------------------------------------------------------
    // Output combinational logic
    // -------------------------------------------------------------------------
    always_comb begin
        o_rx_encoding   = 9'h00;
        o_done_reset_rx = 0;

        if (i_current_state == RESET) begin
            o_rx_encoding = 9'h00;
            if (i_pll_stable_reg && i_supply_stable_reg && i_timer_4ms_reg)
                o_done_reset_rx = 1;
        end
    end

    // =========================================================================
    // Assertions
    // =========================================================================
    /*
`ifdef SIM

    // --------------------------------------------------------------------------
    // Encoding is 0x00 whenever in RESET state
    // --------------------------------------------------------------------------
    property output_encoding;
        @(posedge i_clk) disable iff (i_reset)
        i_current_state == RESET |-> o_rx_encoding == 9'h00;
    endproperty

    // --------------------------------------------------------------------------
    // Done asserts when all three latch registers are high
    // --------------------------------------------------------------------------
    property reset_done;
        @(posedge i_clk) disable iff (i_reset)
        (i_pll_stable_reg && i_supply_stable_reg && i_timer_4ms_reg)
        |-> o_done_reset_rx;
    endproperty

    // --------------------------------------------------------------------------
    // All latch registers clear the cycle after leaving RESET state
    // --------------------------------------------------------------------------
    property regs_clear_outside_reset;
        @(posedge i_clk) disable iff (i_reset)
        i_current_state != RESET
        |=> (!i_pll_stable_reg && !i_supply_stable_reg && !i_timer_4ms_reg);
    endproperty
    REGS_CLEAR_OUTSIDE_RESET : assert property (regs_clear_outside_reset)
        else $error("ASSERT FAIL [REGS_CLEAR_OUTSIDE_RESET]: latches not cleared outside RESET");

    // --------------------------------------------------------------------------
    // Done never asserts outside RESET state
    // --------------------------------------------------------------------------
    property done_only_in_reset;
        @(posedge i_clk) disable iff (i_reset)
        i_current_state != RESET |-> !o_done_reset_rx;
    endproperty
    DONE_ONLY_IN_RESET : assert property (done_only_in_reset)
        else $error("ASSERT FAIL [DONE_ONLY_IN_RESET]: done asserted outside RESET state");

`endif
*/

endmodule