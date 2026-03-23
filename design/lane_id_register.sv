module lane_id_register
#(
    parameter pLANE_ID_PATTERN = 8'b0000_0000  ,
    parameter pDATA_WIDTH = 32 
)   
 (
    output [pDATA_WIDTH-1:0] pattern
);
    assign pattern={2{4'b1010,pLANE_ID_PATTERN,4'b1010}};
    
endmodule