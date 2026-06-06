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
  ,output reg [pSER_WIDTH-1:0]  o_traffic_ser_fifo
);

  //---- SIGNAL DECLARATIONS ---------------------------------------------------
  localparam ST_IDLE    = 2'd0;
  localparam ST_WR_MSG  = 2'd1;
  localparam ST_DATA_MSG = 2'd2;
  localparam ST_WAIT_FULL = 2'd3;
  reg [1:0] state;
  reg       con_full; // Indicates when full deasseted continues from which state


  //---- SEQUENTIAL PROCESSES --------------------------------------------------
  always @(posedge i_clk or posedge i_reset) 
  begin: traffic_msg_proc
    if (i_reset) begin
      o_traffic_ser_fifo <= {pSER_WIDTH{1'b0}};
      o_stall_traffic <= 1'b0;
      o_fifo_wr_en    <= 1'b0;
      con_full <= 1'b0;
      state           <= ST_IDLE;
    end 
    else begin
      // Default assignments
      o_fifo_wr_en    <= 1'b0; // Only pulse for 1 cycle when writing to FIFO
      o_stall_traffic <= 1'b0; // Only stall for 1 cycle when needed

      if (i_traffic_ready) begin
        case (state)
         ST_IDLE: begin
          if (!i_fifo_full) begin          
                o_traffic_ser_fifo <= {i_sb_msg [95:64],i_sb_msg [127:96]};
                o_stall_traffic <= 1'b1;
                o_fifo_wr_en <= 1'b1; // write the message into the FIFO
                state <= ST_WR_MSG;
          end
          else begin
            o_stall_traffic <= 1'b1; // Stall until there is space in the FIFO
            o_fifo_wr_en <= 1'b0;
            con_full <= 1'b0;
            state <= ST_WAIT_FULL;
          end
         end


         ST_WR_MSG: begin
          if (i_sb_msg [100:96] == 5'b10010 ) begin // msg without data payload
             state <= ST_IDLE;
           end
           else if (i_sb_msg [100:96] == 5'b11011) begin // msg with data payload
            if (!i_fifo_full) begin
             o_traffic_ser_fifo <= {i_sb_msg [31:0],i_sb_msg [63:32]};
             o_stall_traffic <= 1'b1; // stall traffic until the data payload is sent out
             o_fifo_wr_en <= 1'b1; // write the message into the FIFO
            state <= ST_DATA_MSG;
            end
            else begin
              o_stall_traffic <= 1'b1; // Stall until there is space in the FIFO
              o_fifo_wr_en <= 1'b0;
              con_full <= 1'b1;
              state <= ST_WAIT_FULL;
            end
         end
         end

         ST_DATA_MSG: begin
            state <= ST_IDLE;
         end 


          ST_WAIT_FULL: begin
            if (!i_fifo_full) begin
              if (con_full) begin
                o_traffic_ser_fifo <= {i_sb_msg [31:0],i_sb_msg [63:32]};
                o_stall_traffic <= 1'b1; // stall traffic until the data payload is sent out
                o_fifo_wr_en <= 1'b1; // write the message into the FIFO
                state <= ST_DATA_MSG;
              end
              else begin
                o_traffic_ser_fifo <= {i_sb_msg [95:64],i_sb_msg [127:96]};
                o_stall_traffic <= 1'b1;
                o_fifo_wr_en <= 1'b1; // write the message into the FIFO
                state <= ST_WR_MSG;
              end
            end
          end
          default: begin
            o_traffic_ser_fifo <= {i_sb_msg [31:0],i_sb_msg [63:32]};
            o_stall_traffic <= 1'b0;
            o_fifo_wr_en <= 1'b0;
            state <= ST_IDLE;
          end
        endcase
      end
  end
  end // traffic_msg_proc

endmodule