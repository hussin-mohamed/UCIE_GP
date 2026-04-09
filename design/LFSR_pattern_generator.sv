module LFSR_pattern_generator #(
    parameter logic [22:0] pLANE_ID_SEED = 23'h1DBFBC,
    parameter int pDATA_WIDTH = 32
) (
    input pclk,
    input i_load,
    output logic [pDATA_WIDTH-1:0] pattern
);

    // ==================== Internal Signals ====================
    logic [22:0] LFSR;
    logic [22:0] next [pDATA_WIDTH:0];

    // ==================== LFSR Calculation Function ====================
    // Computes the next LFSR state based on feedback taps
    function automatic logic [22:0] cal (input [22:0] s);
        cal = {s[21], s[22]^s[20], s[19:16], s[22]^s[15], 
               s[14:8], s[22]^s[7], s[6:5], s[22]^s[4], 
               s[3:2], s[22]^s[1], s[0], s[22]};
        return cal;
    endfunction

    // ==================== Combinational Logic ====================
    // Generate pDATA_WIDTH parallel LFSR states and extract output pattern
    generate
        assign next[0] = LFSR;
        genvar i;
        for (i = 0; i < pDATA_WIDTH; i++) begin
            // Compute next LFSR state for each bit position
            assign next[i+1] = cal(next[i]);
            // Extract MSB from each state to form output pattern
            assign pattern[pDATA_WIDTH-i-1] = next[i][22];
        end
    endgenerate

    // ==================== Sequential Logic ====================
    // Load seed or advance LFSR on each clock edge
    always @(posedge pclk) begin
        if (i_load) begin
            LFSR <= pLANE_ID_SEED;
        end else begin
            LFSR <= next[pDATA_WIDTH];
        end
    end

endmodule