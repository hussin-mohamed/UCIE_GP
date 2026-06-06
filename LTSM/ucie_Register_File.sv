//================================================================================
// Module: ucie_Register_File
// Description: Minimal speed-register file for UCIe LTSM.
//              Holds only the speed-mode register used by TX_MBTRAIN's
//              SPEEDIDLE substate for speed negotiation.
//
//              - o_speedreg reflects the currently stored value (read port).
//              - When i_write_en is asserted, the value of i_speedreg_in is
//                captured on the next rising edge (write port).
//================================================================================

module ucie_Register_File (
    input  logic        i_clk,
    input  logic        i_rst,

    // Speed register write port
    input  logic [2:0]  i_speedreg_in,   // New speed value from LTSM / MBTRAIN

    // Speed register read port
    output logic [2:0]  o_speedreg       // Current speed register value
);

    //==========================================================================
    // Speed Register — RW, resets to max speed (3'h5)
    //==========================================================================
    always_ff @(posedge i_clk or posedge i_rst) begin
        if (i_rst)
            o_speedreg <= 3'h0;          // Default: highest supported speed
        else
            o_speedreg <= i_speedreg_in;
    end

endmodule