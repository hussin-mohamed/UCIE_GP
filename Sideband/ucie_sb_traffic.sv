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
  ,input  wire                  i_traffic_msg_ready
  ,output reg [pMSG_WIDTH-1:0]  o_sb_msg_out
  ,output reg                   o_tx_traffic_fifo_rd_en
  ,output reg                   o_traffic_tx_fifo_wr_en
  ,output reg                   o_rx_traffic_fifo_rd_en
  ,output reg                   o_traffic_rx_fifo_wr_en
  ,output reg [pMSG_WIDTH-1:0]  o_traffic_tx_fifo_msg
  ,output reg [pMSG_WIDTH-1:0]  o_traffic_rx_fifo_msg
  ,output wire                  o_msg_ready
  ,output reg                   o_stall_traffic
);

  //---- SIGNAL DECLARATIONS --------------------------------------------------- 
  localparam tx_empty_rx_empty = 2'd0;
  localparam tx_empty_rx_n_empty = 2'd1;
  localparam tx_n_empty_rx_empty = 2'd2;
  localparam tx_n_empty_rx_n_empty = 2'd3;

  
  reg [1:0] flag_rd_on; // bit 0: read from tx_traffic_fifo, bit 1: read from rx_traffic_fifo
  reg  tx_rd_first;
  wire [7:0] msg_code;
  wire [7:0] msg_subcode;
  

  //---- SEQUENTIAL PROCESSES --------------------------------------------------

always @(posedge i_clk or posedge i_reset) 
  begin: tx_rx_msg_out_proc
    if (i_reset) begin
        o_sb_msg_out <= {pMSG_WIDTH{1'b0}};
        o_tx_traffic_fifo_rd_en <= 1'b0;
        o_rx_traffic_fifo_rd_en <= 1'b0;
        tx_rd_first <= 1'b0;
    end
    else begin 
    if (!i_stall_traffic && !o_msg_ready) begin 
        o_tx_traffic_fifo_rd_en <= 1'b0;
        o_rx_traffic_fifo_rd_en <= 1'b0;

    case ({!i_tx_traffic_fifo_empty,!i_rx_traffic_fifo_empty})
        tx_empty_rx_empty: begin 
            o_sb_msg_out <= {pMSG_WIDTH{1'b0}}; 
            o_tx_traffic_fifo_rd_en <= 1'b0;
            o_rx_traffic_fifo_rd_en <= 1'b0;
            end
        tx_n_empty_rx_empty: begin 
            o_sb_msg_out <= i_tx_traffic_fifo_msg; 
            o_tx_traffic_fifo_rd_en <= 1'b1;
            o_rx_traffic_fifo_rd_en <= 1'b0;
            end
        tx_empty_rx_n_empty: begin 
            o_sb_msg_out <= i_rx_traffic_fifo_msg; 
            o_rx_traffic_fifo_rd_en <= 1'b1;   
            o_tx_traffic_fifo_rd_en <= 1'b0; 
            end
        tx_n_empty_rx_n_empty: begin 
            if (tx_rd_first) begin
                o_sb_msg_out <= i_rx_traffic_fifo_msg; 
                o_tx_traffic_fifo_rd_en <= 1'b0; 
                o_rx_traffic_fifo_rd_en <= 1'b1;   
                tx_rd_first <= 1'b0;
            end
            else begin
                o_sb_msg_out <= i_tx_traffic_fifo_msg; 
                o_tx_traffic_fifo_rd_en <= 1'b1;
                o_rx_traffic_fifo_rd_en <= 1'b0;
                tx_rd_first <= 1'b1;
            end
            end
        default: begin 
            o_sb_msg_out <= {pMSG_WIDTH{1'b0}}; 
            o_tx_traffic_fifo_rd_en <= 1'b0;
            o_rx_traffic_fifo_rd_en <= 1'b0;
            end
    endcase
    end
    else begin
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
        o_stall_traffic <= 1'b0;
        end
        else begin 
          if ((!i_traffic_tx_fifo_full || !i_traffic_rx_fifo_full) && i_traffic_msg_ready) begin
          // write logic
            if (((msg_code [3:0] == 4'hA) && ({msg_code, msg_subcode} != {8'h8A,8'h0A}) && ({msg_code, msg_subcode} != {8'h8A,8'h0D})) 
                || ({msg_code, msg_subcode} == {8'h85,8'h0A}) || ({msg_code, msg_subcode} == {8'h85,8'h0D}) ) 
            begin
               o_traffic_tx_fifo_msg <= i_sb_msg_in;
               o_traffic_tx_fifo_wr_en <= 1'b1;
               o_traffic_rx_fifo_msg <= {pMSG_WIDTH{1'b0}};
               o_traffic_rx_fifo_wr_en <= 1'b0;
               o_stall_traffic <= 1'b0;
            end
            else if (((msg_code [3:0] == 4'h5) && ({msg_code, msg_subcode} != {8'h85,8'h0A}) && ({msg_code, msg_subcode} != {8'h85,8'h0D})) 
                || ({msg_code, msg_subcode} == {8'h8A,8'h0A})
                || ({msg_code, msg_subcode} == {8'h91,8'h00})
                || ({msg_code, msg_subcode} == {8'h81,8'h0C})
                || ({msg_code, msg_subcode} == {8'h8A,8'h0D}))
            begin
               o_traffic_rx_fifo_msg <= i_sb_msg_in;
               o_traffic_rx_fifo_wr_en <= 1'b1;
               o_traffic_tx_fifo_msg <= {pMSG_WIDTH{1'b0}};
               o_traffic_tx_fifo_wr_en <= 1'b0; 
                o_stall_traffic <= 1'b0;
            end
            else begin
               o_traffic_tx_fifo_msg <= {pMSG_WIDTH{1'b0}};
               o_traffic_tx_fifo_wr_en <= 1'b0;
               o_traffic_rx_fifo_msg <= {pMSG_WIDTH{1'b0}};
               o_traffic_rx_fifo_wr_en <= 1'b0;
               o_stall_traffic <= 1'b0; // Do not stall the traffic for non-traffic messages 
            end
        end
        else if (!i_traffic_msg_ready)begin
               o_traffic_tx_fifo_msg <= {pMSG_WIDTH{1'b0}};
               o_traffic_tx_fifo_wr_en <= 1'b0;
               o_traffic_rx_fifo_msg <= {pMSG_WIDTH{1'b0}};
               o_traffic_rx_fifo_wr_en <= 1'b0;
               o_stall_traffic <= 1'b0; // Do not stall the traffic when message is not ready, just do not write to FIFOs
        end
        else begin
               o_traffic_tx_fifo_msg <= o_traffic_tx_fifo_msg;
               o_traffic_tx_fifo_wr_en <= 1'b0;
               o_traffic_rx_fifo_msg <= o_traffic_rx_fifo_msg;
               o_traffic_rx_fifo_wr_en <= 1'b0;
               o_stall_traffic <= 1'b1; // Stall the traffic when FIFOs are full and message is ready, to prevent loss of messages that are ready to be written to FIFOs
        end
   end 
   end // tx_rx_wr_msg_proc

  //---- COMBINATIONAL LOGIC ---------------------------------------------------
   assign msg_code = i_sb_msg_in[117:110];
   assign msg_subcode = i_sb_msg_in[71:64];
   assign o_msg_ready = ((o_tx_traffic_fifo_rd_en || o_rx_traffic_fifo_rd_en) && !i_stall_traffic) 
          || i_stall_traffic; // Message is ready when we are reading from either FIFO and traffic is not stalled



endmodule