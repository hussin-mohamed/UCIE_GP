//------------------------------------------------------------------------------
// Module: ucie_sideband_traffic_fifo
// Description: ...
//------------------------------------------------------------------------------
module ucie_sideband_traffic_fifo
#(//---- PARAMETER DECLARATIONS ------------------------------------------------
  parameter pMSG_WIDTH           = 128 // Width of messsage bus
 ,parameter pSER_WIDTH           = 64   // Width of serialized output
)
(//---- PORT DECLARATIONS -----------------------------------------------------
  input   wire                  i_clk
  ,input  wire                  i_reset
  ,input  wire [pMSG_WIDTH-1:0] i_sb_msg
  ,input  wire                  i_fifo_full
  ,input  wire                  i_traffic_ready
  ,output reg                   o_stall_traffic
  ,output reg                   o_fifo_wr_en
  ,output reg [pSER_WIDTH-1:0]  traffic_ser_fifo
);

  //---- SIGNAL DECLARATIONS ---------------------------------------------------
  reg                  con_full;

  //---- SEQUENTIAL PROCESSES --------------------------------------------------
  always @(posedge i_clk or posedge i_reset) 
  begin: traffic_msg_proc
    if (i_reset) begin
      traffic_ser_fifo <= {pSER_WIDTH{1'b0}};
      o_stall_traffic <= 1'b0;
      con_full        <= 1'b0;
      o_fifo_wr_en    <= 1'b0;
    end 
    else begin
      if (!i_fifo_full) begin
      if (!o_stall_traffic && i_traffic_ready) begin   
      if (i_sb_msg [100:96] == 5'b10010 ) begin // msg without data payload
        traffic_ser_fifo <= {i_sb_msg [95:64],i_sb_msg [127:96]};
        o_stall_traffic <= 1'b0;
        o_fifo_wr_en <= 1'b1; // write the message into the FIFO
        con_full <= 1'b0;
      end
      else if (i_sb_msg [100:96] == 5'b11011) begin // msg with data payload
        traffic_ser_fifo <= {i_sb_msg [95:64],i_sb_msg [127:96]};
        o_stall_traffic <= 1'b1; // stall traffic until the data payload is sent out
        o_fifo_wr_en <= 1'b1; // write the message into the FIFO
        con_full <= 1'b1;
      end
      else begin
        traffic_ser_fifo <= {pSER_WIDTH{1'b0}};
        o_stall_traffic <= 1'b0;
        o_fifo_wr_en <= 1'b0;
        con_full <= 1'b0;
      end
      end  
    else if (i_traffic_ready) begin
      if (con_full) begin
      traffic_ser_fifo <= {i_sb_msg [31:0],i_sb_msg [63:32]};
      o_fifo_wr_en <= 1'b1;
      o_stall_traffic <= 1'b0;
      end
      else begin
        if (i_sb_msg [100:96] == 5'b10010) begin // msg without data payload
        traffic_ser_fifo <= {i_sb_msg [95:64],i_sb_msg [127:96]};
        o_stall_traffic <= 1'b0;
        o_fifo_wr_en <= 1'b1; // write the message into the FIFO
        con_full <= 1'b0;
      end
      else if (i_sb_msg [100:96] == 5'b11011) begin // msg with data payload
        traffic_ser_fifo <= {i_sb_msg [95:64],i_sb_msg [127:96]};
        o_stall_traffic <= 1'b1; // stall traffic until the data payload is sent out
        o_fifo_wr_en <= 1'b1; // write the message into the FIFO
        con_full <= 1'b1;
      end
      else begin
        traffic_ser_fifo <= {pSER_WIDTH{1'b0}};
        o_stall_traffic <= 1'b0;
        o_fifo_wr_en <= 1'b0;
        con_full <= 1'b0;
      end
      end
    end
    else begin
      traffic_ser_fifo <= traffic_ser_fifo;
      o_stall_traffic <= o_stall_traffic;
      o_fifo_wr_en <= 1'b0;
      con_full <= con_full;
    end
    end
    else begin
      o_stall_traffic <= 1'b1;
      o_fifo_wr_en    <= 1'b0;
    end
  end
  end // traffic_msg_proc

endmodule