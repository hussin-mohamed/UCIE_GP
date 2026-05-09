//------------------------------------------------------------------------------
// Module: ucie_sideband_fifo_traffic (Synchronous FWFT Fixed)
//------------------------------------------------------------------------------
module ucie_sideband_fifo_traffic
#(//---- PARAMETER DECLARATIONS ------------------------------------------------
  parameter pMSG_WIDTH           = 128, 
  parameter pDESER_WIDTH         = 64   
)
(//---- PORT DECLARATIONS -----------------------------------------------------
  input  wire                    i_clk,
  input  wire                    i_reset,
  input  wire                    i_fifo_empty,
  input  wire [pDESER_WIDTH-1:0] i_traffic_deser_fifo,
  input  wire                    i_stall_traffic,
  output reg                     o_traffic_ready,
  output reg  [pMSG_WIDTH-1:0]   o_sb_msg,
  output reg                     o_fifo_rd_en
);

  //---- STATE MACHINE PARAMETERS ----------------------------------------------
  localparam ST_IDLE    = 2'd0; 
  localparam ST_WAIT_M2 = 2'd1; // Wait 1 cycle for FIFO to output msg 2
  localparam ST_CAP_M2  = 2'd2; // Capture msg 2
  localparam ST_WAIT_NX = 2'd3; // Wait 1 cycle for FIFO to output next message

  reg [1:0] state;

  //---- SEQUENTIAL PROCESSES --------------------------------------------------
  always @(posedge i_clk or posedge i_reset) begin
    if (i_reset) begin
      o_traffic_ready <= 1'b0;
      o_sb_msg        <= {pMSG_WIDTH{1'b0}};
      o_fifo_rd_en    <= 1'b0;
      state           <= ST_IDLE;
    end else begin
      // Default assignments ensure signals only pulse for 1 cycle
      o_fifo_rd_en    <= 1'b0;
      o_traffic_ready <= 1'b0;

      if (!i_stall_traffic) begin
        case (state)
          
          ST_IDLE: begin
            if (!i_fifo_empty) begin

              o_sb_msg <= {i_traffic_deser_fifo[31:0], i_traffic_deser_fifo[63:32], {(pMSG_WIDTH-pDESER_WIDTH){1'b0}}};
              o_fifo_rd_en <= 1'b1; // Pop msg 1

              if (i_traffic_deser_fifo[4:0] == 5'b11011) begin
                // Needs payload. Wait for the FIFO to update.
                state <= ST_WAIT_M2;
              end else if (i_traffic_deser_fifo[4:0] == 5'b10010) begin
                // No payload. Ready goes high at the SAME TIME the msg updates
                o_traffic_ready <= 1'b1;
                state <= ST_WAIT_NX; 
              end
            end
          end

          ST_WAIT_M2: begin
            state <= ST_CAP_M2;
          end

          ST_CAP_M2: begin
            if (!i_fifo_empty) begin
              o_sb_msg <= {o_sb_msg[pMSG_WIDTH-1:pDESER_WIDTH], i_traffic_deser_fifo[63:32], i_traffic_deser_fifo[31:0]};
              o_fifo_rd_en    <= 1'b1; // Pop msg 2
              
              // Assert ready exactly as the full message is formed
              o_traffic_ready <= 1'b1; 
              state           <= ST_WAIT_NX;
            end
          end

          ST_WAIT_NX: begin
            state <= ST_IDLE;
          end

          default: state <= ST_IDLE;
        endcase
      end
    end
  end
endmodule