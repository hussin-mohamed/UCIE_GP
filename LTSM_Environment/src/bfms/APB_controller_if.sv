import shared_pkg::*;

// APB_controller_if.sv
interface APB_controller_if (
   input logic             PCLK,
   input logic             PRESETn,
   input logic [N_AES-1:0] concat_out,
   input logic             concat_done
);
   string if_name = "APB_controller_if";
endinterface : APB_controller_if
