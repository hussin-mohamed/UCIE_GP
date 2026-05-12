module lane_id_register
#(
    parameter pLANE_ID_PATTERN = 8'b0000_0000  ,
    parameter pDATA_WIDTH = 64 
)   
 (
    input i_reset,i_clk,
    output logic [pDATA_WIDTH-1:0] pattern
);
    always_ff @( posedge i_clk or posedge i_reset ) begin 
        if (i_reset) begin
            pattern <= {4{4'b1010,pLANE_ID_PATTERN,4'b1010}};
        end
    end    
endmodule