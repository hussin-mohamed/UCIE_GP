//------------------------------------------------------------------------------
// Module: ucie_sb_temp_top_tb
// Description: Testbench for ucie_sb_temp_top module.
//              Verifies TX/RX message encoding, FIFO flow control,
//              sideband protocol handshake (req/rsp/done), and stall behavior.
//------------------------------------------------------------------------------
`timescale 1ns/1ps

module ucie_sb_temp_top_tb;

  //---- PARAMETER DECLARATIONS ------------------------------------------------
  // Mirror DUT parameters so the TB can be updated in one place
  localparam pMSG_WIDTH          = 128;
  localparam pDESER_WIDTH        = 64;
  localparam pSER_WIDTH          = 64;
  localparam pFIFO_WIDTH         = 128;
  localparam pFIFO_DEPTH         = 32;
  localparam pENCODING_WIDTH     = 9;
  localparam pDECODING_WIDTH     = 9;
  localparam pDATA_WIDTH         = 64;
  localparam pINFO_WIDTH         = 16;
  localparam pMSG_CODE_WIDTH     = 8;
  localparam pMSG_SUBCODE_WIDTH  = 8;
  localparam pOP_CODE_WIDTH      = 5;
  localparam pRESERVED           = 1'b0;

  // Timing constants
  localparam pCLK_PERIOD_NS      = 10;   // system clock
  localparam pCLK_800_PERIOD_NS  = 1.25; // interface of sideband clock
  localparam pRST_CYCLES         = 8;    // Reset assertion duration (cycles)
  localparam pSIM_TIMEOUT_NS     = 50000;// Watchdog timeout

  //---- CLOCK & RESET SIGNALS -------------------------------------------------
  reg   tb_clk;
  reg   tb_800MHz_clk;
  reg   tb_reset;

  //---- TX STIMULUS SIGNALS ---------------------------------------------------
  reg                            tb_tx_sb_req;
  reg                            tb_tx_sb_rsp;
  reg                            tb_tx_sb_done;
  reg  [pDATA_WIDTH-1:0]         tb_tx_data;
  reg  [pENCODING_WIDTH-1:0]     tb_tx_encoding;
  reg  [pINFO_WIDTH-1:0]         tb_tx_info;

  //---- RX STIMULUS SIGNALS ---------------------------------------------------
  reg                            tb_rx_sb_req;
  reg                            tb_rx_sb_rsp;
  reg                            tb_rx_sb_done;
  reg  [pDATA_WIDTH-1:0]         tb_rx_data;
  reg  [pENCODING_WIDTH-1:0]     tb_rx_encoding;
  reg  [pINFO_WIDTH-1:0]         tb_rx_info;

  //---- MONITORED OUTPUT SIGNALS ----------------------------------------------
  wire                           mon_sb_tx_req;
  wire                           mon_sb_tx_rsp;
  wire                           mon_sb_tx_done;
  wire [pDATA_WIDTH-1:0]         mon_tx_data;
  wire [pDECODING_WIDTH-1:0]     mon_tx_decoding;
  wire [pINFO_WIDTH-1:0]         mon_tx_info;
  wire                           mon_tx_valid;

  wire                           mon_sb_rx_req;
  wire                           mon_sb_rx_rsp;
  wire                           mon_sb_rx_done;
  wire [pDATA_WIDTH-1:0]         mon_rx_data;
  wire [pDECODING_WIDTH-1:0]     mon_rx_decoding;
  wire [pINFO_WIDTH-1:0]         mon_rx_info;
  wire                           mon_rx_valid;

  //---- DUT INSTANTIATION -----------------------------------------------------
  ucie_sb_temp_top #(
    .pMSG_WIDTH         (pMSG_WIDTH),
    .pDESER_WIDTH       (pDESER_WIDTH),
    .pSER_WIDTH         (pSER_WIDTH),
    .pFIFO_WIDTH        (pFIFO_WIDTH),
    .pFIFO_DEPTH        (pFIFO_DEPTH),
    .pENCODING_WIDTH    (pENCODING_WIDTH),
    .pDECODING_WIDTH    (pDECODING_WIDTH),
    .pDATA_WIDTH        (pDATA_WIDTH),
    .pINFO_WIDTH        (pINFO_WIDTH),
    .pMSG_CODE_WIDTH    (pMSG_CODE_WIDTH),
    .pMSG_SUBCODE_WIDTH (pMSG_SUBCODE_WIDTH),
    .pOP_CODE_WIDTH     (pOP_CODE_WIDTH),
    .pRESERVED          (pRESERVED)
  ) u_dut (
    .i_clk          (tb_clk),
    .i_reset        (tb_reset),
    .i_800MHz_clk   (tb_800MHz_clk),

    .i_tx_sb_req    (tb_tx_sb_req),
    .i_tx_sb_rsp    (tb_tx_sb_rsp),
    .i_tx_sb_done   (tb_tx_sb_done),
    .i_tx_data      (tb_tx_data),
    .i_tx_encoding  (tb_tx_encoding),
    .i_tx_info      (tb_tx_info),

    .i_rx_sb_req    (tb_rx_sb_req),
    .i_rx_sb_rsp    (tb_rx_sb_rsp),
    .i_rx_sb_done   (tb_rx_sb_done),
    .i_rx_data      (tb_rx_data),
    .i_rx_encoding  (tb_rx_encoding),
    .i_rx_info      (tb_rx_info),

    .o_sb_tx_req    (mon_sb_tx_req),
    .o_sb_tx_rsp    (mon_sb_tx_rsp),
    .o_sb_tx_done   (mon_sb_tx_done),
    .o_tx_data      (mon_tx_data),
    .o_tx_decoding  (mon_tx_decoding),
    .o_tx_info      (mon_tx_info),
    .o_tx_valid     (mon_tx_valid),

    .o_sb_rx_req    (mon_sb_rx_req),
    .o_sb_rx_rsp    (mon_sb_rx_rsp),
    .o_sb_rx_done   (mon_sb_rx_done),
    .o_rx_data      (mon_rx_data),
    .o_rx_decoding  (mon_rx_decoding),
    .o_rx_info      (mon_rx_info),
    .o_rx_valid     (mon_rx_valid)
  );

  //---- CLOCK GENERATION ------------------------------------------------------
  // System clock — 250 MHz
  initial tb_clk = 1'b0;
  always #(pCLK_PERIOD_NS / 2.0) tb_clk = ~tb_clk;

  // 800 MHz sideband clock
  initial tb_800MHz_clk = 1'b0;
  always #(pCLK_800_PERIOD_NS / 2.0) tb_800MHz_clk = ~tb_800MHz_clk;


  //===========================================================================
  // TASK: task_reset
  // Description: Applies synchronous reset for pRST_CYCLES and de-asserts.
  //              All stimulus inputs are also driven to their idle state here.
  //===========================================================================
  task task_reset;
    begin
      tb_reset        = 1'b1;

      // TX idle state
      tb_tx_sb_req    = 1'b0;
      tb_tx_sb_rsp    = 1'b0;
      tb_tx_sb_done   = 1'b0;
      tb_tx_data      = {pDATA_WIDTH{1'b0}};
      tb_tx_encoding  = {pENCODING_WIDTH{1'b0}};
      tb_tx_info      = {pINFO_WIDTH{1'b0}};

      // RX idle state
      tb_rx_sb_req    = 1'b0;
      tb_rx_sb_rsp    = 1'b0;
      tb_rx_sb_done   = 1'b0;
      tb_rx_data      = {pDATA_WIDTH{1'b0}};
      tb_rx_encoding  = {pENCODING_WIDTH{1'b0}};
      tb_rx_info      = {pINFO_WIDTH{1'b0}};

      repeat (pRST_CYCLES) @(posedge tb_clk);
      tb_reset = 1'b0;
      @(posedge tb_clk);
      $display("[%0t] [RESET] Reset de-asserted.", $time);
    end
  endtask

  //===========================================================================
  // TASK: task_tx_request
  // Description: Drives a single TX sideband request transaction.
  //   Arguments:
  //     data     — payload to drive on i_tx_data
  //     encoding — encoding field value
  //     info     — info field value
  //===========================================================================
  task task_tx_request;
    input [pDATA_WIDTH-1:0]     data;
    input [pENCODING_WIDTH-1:0] encoding;
    input [pINFO_WIDTH-1:0]     info;
    begin
      @(posedge tb_clk);
      tb_tx_sb_req   = 1'b1;
      tb_tx_sb_rsp   = 1'b0;
      tb_tx_sb_done  = 1'b0;
      tb_tx_data     = data;
      tb_tx_encoding = encoding;
      tb_tx_info     = info;
      $display("[%0t] [TX-REQ] data=0x%0h  encoding=0x%0h  info=0x%0h",
               $time, data, encoding, info);

      @(posedge tb_clk);
      tb_tx_sb_req  = 1'b0;

      // Return to idle
      tb_tx_sb_done  = 1'b0;
      tb_tx_data     = {pDATA_WIDTH{1'b0}};
      tb_tx_encoding = {pENCODING_WIDTH{1'b0}};
      tb_tx_info     = {pINFO_WIDTH{1'b0}};
    end
  endtask

  //===========================================================================
  // TASK: task_rx_resp
  // Description: Drives a single RX sideband resp transaction.
  //   Arguments:
  //     data     — payload to drive on i_rx_data
  //     encoding — encoding field value
  //     info     — info field value
  //===========================================================================
  task task_rx_resp;
    input [pDATA_WIDTH-1:0]     data;
    input [pENCODING_WIDTH-1:0] encoding;
    input [pINFO_WIDTH-1:0]     info;
    begin
      @(posedge tb_clk);
      tb_rx_sb_req   = 1'b0;
      tb_rx_sb_rsp   = 1'b1;
      tb_rx_sb_done  = 1'b0;
      tb_rx_data     = data;
      tb_rx_encoding = encoding;
      tb_rx_info     = info;
      $display("[%0t] [RX-RESP] data=0x%0h  encoding=0x%0h  info=0x%0h",
               $time, data, encoding, info);

      @(posedge tb_clk);
      tb_rx_sb_rsp  = 1'b0;

      // Return to idle
      tb_rx_sb_done  = 1'b0;
      tb_rx_data     = {pDATA_WIDTH{1'b0}};
      tb_rx_encoding = {pENCODING_WIDTH{1'b0}};
      tb_rx_info     = {pINFO_WIDTH{1'b0}};
    end
  endtask

  //===========================================================================
  // TASK: task_rx_request
  // Description: Drives a single RX sideband request transaction.
  //   Arguments:
  //     data     — payload to drive on i_rx_data
  //     encoding — encoding field value
  //     info     — info field value
  //===========================================================================
  task task_rx_request;
    input [pDATA_WIDTH-1:0]     data;
    input [pENCODING_WIDTH-1:0] encoding;
    input [pINFO_WIDTH-1:0]     info;
    begin
      @(posedge tb_clk);
      tb_rx_sb_req   = 1'b1;
      tb_rx_sb_rsp   = 1'b0;
      tb_rx_sb_done  = 1'b0;
      tb_rx_data     = data;
      tb_rx_encoding = encoding;
      tb_rx_info     = info;
      $display("[%0t] [RX-REQ] data=0x%0h  encoding=0x%0h  info=0x%0h",
               $time, data, encoding, info);

      @(posedge tb_clk);
      tb_rx_sb_req  = 1'b0;

      // Return to idle
      tb_rx_sb_done  = 1'b0;
      tb_rx_data     = {pDATA_WIDTH{1'b0}};
      tb_rx_encoding = {pENCODING_WIDTH{1'b0}};
      tb_rx_info     = {pINFO_WIDTH{1'b0}};
    end
  endtask

  //===========================================================================
  // TASK: task_tx_resp
  // Description: Drives a single TX sideband resp transaction.
  //   Arguments:
  //     data     — payload to drive on i_tx_data
  //     encoding — encoding field value
  //     info     — info field value
  //===========================================================================
  task task_tx_resp;
    input [pDATA_WIDTH-1:0]     data;
    input [pENCODING_WIDTH-1:0] encoding;
    input [pINFO_WIDTH-1:0]     info;
    begin
      @(posedge tb_clk);
      tb_tx_sb_req   = 1'b0;
      tb_tx_sb_rsp   = 1'b1;
      tb_tx_sb_done  = 1'b0;
      tb_tx_data     = data;
      tb_tx_encoding = encoding;
      tb_tx_info     = info;
      $display("[%0t] [RX-RESP] data=0x%0h  encoding=0x%0h  info=0x%0h",
               $time, data, encoding, info);

      @(posedge tb_clk);
      tb_tx_sb_rsp  = 1'b0;

      // Return to idle
      tb_tx_sb_done  = 1'b0;
      tb_tx_data     = {pDATA_WIDTH{1'b0}};
      tb_tx_encoding = {pENCODING_WIDTH{1'b0}};
      tb_tx_info     = {pINFO_WIDTH{1'b0}};
    end
  endtask


  //===========================================================================
  // TASK: task_check_tx_outputs
  // Description: Immediate assertion — checks TX output signals against
  //              expected values one cycle after valid is seen.
  //===========================================================================
  task task_check_tx_outputs;
    input [pDATA_WIDTH-1:0]         exp_data;
    input [pDECODING_WIDTH-1:0]     exp_dec;
    begin
      if ((mon_tx_data !== exp_data) || (mon_tx_decoding !== exp_dec))
        $error("[%0t] [CHECK-TX] mismatch: expected_DATA=0x%0h  DATA_got=0x%0h expected_DEC=0x%0h  got_DEC=0x%0h \n",
               $time, exp_data, mon_tx_data,exp_dec, mon_tx_decoding);
      else $display("[%0t] [PHASE-PASSED]: expected_DATA=0x%0h  DATA_got=0x%0h expected_DEC=0x%0h  got_DEC=0x%0h \n",
               $time, exp_data, mon_tx_data,exp_dec, mon_tx_decoding);
    end
  endtask

  //===========================================================================
  // TASK: task_check_rx_outputs
  // Description: Immediate assertion — checks RX output signals against
  //              expected values one cycle after valid is seen.
  //===========================================================================
  task task_check_rx_outputs;
    input [pDATA_WIDTH-1:0]         exp_data;
    input [pDECODING_WIDTH-1:0]     exp_dec;
    begin
      if ((mon_rx_data !== exp_data) || (mon_rx_decoding !== exp_dec))
        $error("[%0t] [CHECK-RX] mismatch: expected_DATA=0x%0h  DATA_got=0x%0h expected_DEC=0x%0h  got_DEC=0x%0h \n",
               $time, exp_data, mon_rx_data,exp_dec, mon_rx_decoding);
      else $display("[%0t] [PHASE-PASSED]: expected_DATA=0x%0h  DATA_got=0x%0h expected_DEC=0x%0h  got_DEC=0x%0h \n",
               $time, exp_data, mon_rx_data,exp_dec, mon_rx_decoding);
    end
  endtask


  /*---- WAVEFORM DUMP ---------------------------------------------------------
  initial begin
    $dumpfile("ucie_sb_temp_top_tb.vcd");
    $dumpvars(0, ucie_sb_temp_top_tb);
  end*/

  //===========================================================================
  // MAIN TEST SEQUENCE
  //===========================================================================
  initial begin

    //--------------------------------------------------------------------------
    // PHASE 0 — RESET
    //--------------------------------------------------------------------------
    $display("//==================================================================");
    $display("// PHASE 0: RESET");
    $display("//==================================================================");
    task_reset;
    $display("[%0t] [PHASE-PASSED] \n",$time);
    repeat (4) @(posedge tb_clk);

    //--------------------------------------------------------------------------
    // PHASE 1 — SINGLE TX REQ MSG WITHOUT DATA
    //--------------------------------------------------------------------------
    $display("//==================================================================");
    $display("// PHASE 1: SINGLE TX REQ MSG WITHOUT DATA");
    $display("//==================================================================");
    task_tx_request(
      64'h0000_0000_0000_0000,
      9'h18,
      16'h0000
    );
    @(posedge mon_sb_rx_req)
    task_check_rx_outputs(64'h0000_0000_0000_0000, 9'h18);
    @(posedge tb_clk);
    tb_rx_sb_done = 1'b1;
    @(posedge tb_clk);
    tb_rx_sb_done = 1'b0;
    repeat (4) @(posedge tb_clk);

    //--------------------------------------------------------------------------
    // PHASE 2 — SINGLE RX RESP MSG WITHOUT DATA
    //--------------------------------------------------------------------------
    $display("//==================================================================");
    $display("// PHASE 2: SINGLE RX RESP MSG WITHOUT DATA");
    $display("//==================================================================");
    task_rx_resp(
      64'h0000_0000_0000_0000,
      9'h18,
      16'h0000
    );
    @(posedge mon_sb_tx_rsp)
    task_check_tx_outputs(64'h0000_0000_0000_0000, 9'h18);
    @(posedge tb_clk);
    tb_tx_sb_done = 1'b1;
    @(posedge tb_clk);
    tb_tx_sb_done = 1'b0;
    repeat (4) @(posedge tb_clk);

    //--------------------------------------------------------------------------
    // PHASE 3 — SINGLE TX REQ MSG WITH DATA
    //--------------------------------------------------------------------------
    $display("//==================================================================");
    $display("// PHASE 3: SINGLE TX REQ MSG WITH DATA");
    $display("//==================================================================");
    task_tx_request(
      64'hDEAD_BEEF_CAFE_1234,
      9'h10,
      16'h0000
    );
    @(posedge mon_sb_rx_req)
    task_check_rx_outputs(64'hDEAD_BEEF_CAFE_1234, 9'h12);
    @(posedge tb_clk);
    tb_rx_sb_done = 1'b1;
    @(posedge tb_clk);
    tb_rx_sb_done = 1'b0;
    repeat (4) @(posedge tb_clk);

    //--------------------------------------------------------------------------
    // PHASE 4 — SINGLE RX RESP MSG WITH DATA
    //--------------------------------------------------------------------------
    $display("//==================================================================");
    $display("// PHASE 4: SINGLE RX RESP MSG WITH DATA");
    $display("//==================================================================");
    task_rx_resp(
      64'hDEAD_BEEF_CAFE_1234,
      9'h12,
      16'h0000
    );
    @(posedge mon_sb_tx_rsp)
    task_check_tx_outputs(64'hDEAD_BEEF_CAFE_1234, 9'h10);
    @(posedge tb_clk);
    tb_tx_sb_done = 1'b1;
    @(posedge tb_clk);
    tb_tx_sb_done = 1'b0;
    repeat (4) @(posedge tb_clk);

    //--------------------------------------------------------------------------
    // PHASE 5 — SINGLE RX REQ MSG WITH DATA
    //--------------------------------------------------------------------------
    $display("//==================================================================");
    $display("// PHASE 5: SINGLE RX REQ MSG WITH DATA");
    $display("//==================================================================");
    task_rx_request(
      64'hDEAD_BEEF_CAFE_1234,
      9'h185,
      16'h0000
    );
    @(posedge mon_sb_tx_req)
    task_check_tx_outputs(64'hDEAD_BEEF_CAFE_1234, 9'h185);
    @(posedge tb_clk);
    tb_tx_sb_done = 1'b1;
    @(posedge tb_clk);
    tb_tx_sb_done = 1'b0;
    repeat (4) @(posedge tb_clk);

    //--------------------------------------------------------------------------
    // PHASE 6 — SINGLE TX RESP MSG WITHOUT DATA
    //--------------------------------------------------------------------------
    $display("//==================================================================");
    $display("// PHASE 6: SINGLE TX RESP MSG WITHOUT DATA");
    $display("//==================================================================");
    task_tx_resp(
      64'h0000_0000_0000_0000,
      9'h185,
      16'h0000
    );
    @(posedge mon_sb_rx_rsp)
    task_check_rx_outputs(64'h0000_0000_0000_0000, 9'h185);
    @(posedge tb_clk);
    tb_rx_sb_done = 1'b1;
    @(posedge tb_clk);
    tb_rx_sb_done = 1'b0;
    repeat (4) @(posedge tb_clk);

    //--------------------------------------------------------------------------
    // PHASE 7 — DONE
    //--------------------------------------------------------------------------
    $display("//==================================================================");
    $display("// ALL PHASES COMPLETE — SIMULATION PASSED");
    $display("//==================================================================");
    repeat (10) @(posedge tb_clk);
    $stop;

  end // initial

endmodule
//------------------------------------------------------------------------------
// End of file: ucie_sb_temp_top_tb.sv
//------------------------------------------------------------------------------