//------------------------------------------------------------------------------
// Module: ucie_sb_traffic
// Description: ...
//------------------------------------------------------------------------------
module ucie_sb_traffic
#(//---- PARAMETER DECLARATIONS ------------------------------------------------
  parameter pMSG_WIDTH           = 128 // Width of messsage bus
)
(//---- PORT DECLARATIONS -----------------------------------------------------
  input  wire                   i_clk
  ,input  wire                  i_reset
  ,input  wire [pMSG_WIDTH-1:0] i_tx_traffic_fifo_msg
  ,input  wire                  i_tx_traffic_fifo_empty
  ,input  wire                  i_traffic_tx_fifo_full
  ,input  wire                  i_rx_traffic_fifo_empty
  ,input  wire [pMSG_WIDTH-1:0] i_rx_traffic_fifo_msg
  ,input  wire                  i_traffic_rx_fifo_full
  ,input  wire [pMSG_WIDTH-1:0] i_sb_msg_in
  ,input  wire                  i_stall_traffic
  ,output reg [pMSG_WIDTH-1:0]  o_sb_msg_out
  ,output reg                   o_tx_traffic_fifo_rd_en
  ,output reg                   o_traffic_tx_fifo_wr_en
  ,output reg                   o_rx_traffic_fifo_rd_en
  ,output reg                   o_traffic_rx_fifo_wr_en
  ,output reg [pMSG_WIDTH-1:0]  o_traffic_tx_fifo_msg
  ,output reg [pMSG_WIDTH-1:0]  o_traffic_rx_fifo_msg
  ,output reg                   o_msg_ready
);

  //---- SIGNAL DECLARATIONS --------------------------------------------------- 
  reg [1:0] flag_rd_on; // bit 0: read from tx_traffic_fifo, bit 1: read from rx_traffic_fifo
  reg  tx_rd_first;
  wire [7:0] msg_code;
  wire [7:0] msg_subcode;
  

  //---- SEQUENTIAL PROCESSES --------------------------------------------------
   always @(posedge i_clk or posedge i_reset) 
   begin: toggle_proc
     if (i_reset) begin
        flag_rd_on <= 2'b00; 
        tx_rd_first <= 1'b0;
     end
    else begin
        if (i_tx_traffic_fifo_empty && i_rx_traffic_fifo_empty) begin
        flag_rd_on <= 2'b00; // No FIFO has data to read
        tx_rd_first <= 1'b0;
    end
    else if (!i_tx_traffic_fifo_empty && i_rx_traffic_fifo_empty) begin
        flag_rd_on <= 2'b01; // Only TX Traffic FIFO has data to read
        tx_rd_first <= 1'b0;
    end
    else if (i_tx_traffic_fifo_empty && !i_rx_traffic_fifo_empty) begin
        flag_rd_on <= 2'b10; // Only RX Traffic FIFO has data to read
        tx_rd_first <= 1'b0;
    end
    else begin
        if (tx_rd_first) begin
            flag_rd_on <= ~flag_rd_on; // Both FIFOs have data to read, prioritize TX Traffic FIFO
        end
        else begin
            flag_rd_on <= 2'b01;
            tx_rd_first <= 1'b1;
        end
    end
    end
   end // toggle_proc
   
  always @(posedge i_clk or posedge i_reset) 
  begin: tx_rx_msg_out_proc
    if (i_reset) begin
        o_sb_msg_out <= {pMSG_WIDTH{1'b0}};
    end
    else begin 
    if (!i_stall_traffic) begin 
    case (flag_rd_on)
        2'b00: begin 
            o_sb_msg_out <= {pMSG_WIDTH{1'b0}}; 
            o_msg_ready <= 1'b0;
            o_tx_traffic_fifo_rd_en <= 1'b0;
            o_rx_traffic_fifo_rd_en <= 1'b0;
            end
        2'b01: begin 
            o_sb_msg_out <= i_tx_traffic_fifo_msg; 
            o_tx_traffic_fifo_rd_en <= 1'b1;
            o_rx_traffic_fifo_rd_en <= 1'b0;
            o_msg_ready <= 1'b1;
            end
        2'b10: begin 
            o_sb_msg_out <= i_rx_traffic_fifo_msg; 
            o_rx_traffic_fifo_rd_en <= 1'b1;   
            o_tx_traffic_fifo_rd_en <= 1'b0; 
            o_msg_ready <= 1'b1;
            end
        default: begin 
            o_sb_msg_out <= {pMSG_WIDTH{1'b0}}; 
            o_msg_ready <= 1'b0;
            o_tx_traffic_fifo_rd_en <= 1'b0;
            o_rx_traffic_fifo_rd_en <= 1'b0;
            end
    endcase
    end
    else begin
        o_sb_msg_out <= o_sb_msg_out; 
        o_msg_ready <= 1'b1;
        o_tx_traffic_fifo_rd_en <= 1'b0;
        o_rx_traffic_fifo_rd_en <= 1'b0;
    end
    end
   end // tx_rx_msg_out_proc

   always @(posedge i_clk or posedge i_reset) 
   begin: tx_rx_wr_msg_proc
        if (i_reset) begin
        o_traffic_tx_fifo_msg <= {pMSG_WIDTH{1'b0}};
        o_traffic_tx_fifo_wr_en <= 1'b0;
        o_traffic_rx_fifo_msg <= {pMSG_WIDTH{1'b0}};
        o_traffic_rx_fifo_wr_en <= 1'b0;
        end
        else begin 
          if (!i_traffic_tx_fifo_full || !i_traffic_rx_fifo_full) begin
          // write logic
            if (((msg_code [3:0] == 4'hA) && ({msg_code, msg_subcode} != {8'h8A,8'h0A})) 
                || ({msg_code, msg_subcode} == {8'h85,8'h0A})) 
            begin
               o_traffic_tx_fifo_msg <= i_sb_msg_in;
               o_traffic_tx_fifo_wr_en <= 1'b1;
               o_traffic_rx_fifo_msg <= {pMSG_WIDTH{1'b0}};
               o_traffic_rx_fifo_wr_en <= 1'b0;
            end
            else if (((msg_code [3:0] == 4'h5) && ({msg_code, msg_subcode} != {8'h85,8'h0A})) 
                || ({msg_code, msg_subcode} == {8'h8A,8'h0A})
                || ({msg_code, msg_subcode} == {8'h91,8'h00})
                || ({msg_code, msg_subcode} == {8'h81,8'h0C}))
            begin
               o_traffic_rx_fifo_msg <= i_sb_msg_in;
               o_traffic_rx_fifo_wr_en <= 1'b1;
               o_traffic_tx_fifo_msg <= {pMSG_WIDTH{1'b0}};
               o_traffic_tx_fifo_wr_en <= 1'b0; 
            end
            else begin
               o_traffic_tx_fifo_msg <= {pMSG_WIDTH{1'b0}};
               o_traffic_tx_fifo_wr_en <= 1'b0;
               o_traffic_rx_fifo_msg <= {pMSG_WIDTH{1'b0}};
               o_traffic_rx_fifo_wr_en <= 1'b0; 
            end
        end
        end
   end // tx_rx_wr_msg_proc
  
   


  //---- COMBINATIONAL LOGIC ---------------------------------------------------
   assign msg_code = i_sb_msg_in[117:110];
   assign msg_subcode = i_sb_msg_in[71:64];


endmodule