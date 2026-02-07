import shared_pkg::*;

// APB_Controller_if.sv
interface AES_if (
    input         PCLK,
    input         PRESETn,
    input         AES_done,
    input [127:0] AES_in,
    input [127:0] AES_out
);
    string if_name = "AES_if";
endinterface : AES_if
