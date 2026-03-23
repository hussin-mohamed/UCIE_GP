module LFSR_pattern_generator #(
    parameter logic [22:0] pLANE_ID_SEED = 23'h1DBFBC,
    parameter int pDATA_WIDTH = 32
) (
    input pclk,i_load,
    output logic [pDATA_WIDTH-1:0] pattern
);
    logic [22:0] LFSR;
    logic [22:0] next [pDATA_WIDTH:0];
    function automatic logic [22:0] cal (input [22:0] s);
        cal={s[21],s[22]^s[20],s[19:16],s[22]^s[15],s[14:8],s[22]^s[7],s[6:5],s[22]^s[4],s[3:2],s[22]^s[1],s[0],s[22]};
        return cal;    
    endfunction

    generate
        assign next[0]=LFSR;
        genvar i;
        for (i =0 ; i<pDATA_WIDTH ;i++  ) begin
            assign next[i+1]=cal(next[i]);
            assign pattern[pDATA_WIDTH-i-1]=next[i][22];
        end
    endgenerate

    always @(posedge pclk ) begin
        if (i_load) begin
            LFSR<=pLANE_ID_SEED;
        end
        else begin
            LFSR<=next[pDATA_WIDTH];
        end
    end
endmodule