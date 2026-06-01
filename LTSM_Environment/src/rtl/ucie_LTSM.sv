module ucie_LTSM #(
    parameter DECODING_WIDTH  = 9,      // Width of encoding/decoding signals
    parameter DATA_WIDTH      = 64,     // Width of data bus
    parameter INFO_WIDTH      = 16,     // Width of info/control bus
    parameter SIM_8MS_CYCLES  = 80000,
    parameter CLK_PERIOD_NS   = 1.0,
    parameter ERROR_THRESHOLD = 1       // Threshold for acceptable training errors 
) (
    // -------------------------------------------------------------------------
    // Clock & Reset
    // -------------------------------------------------------------------------
    input logic i_clk,
    input logic i_reset,

    // -------------------------------------------------------------------------
    // RDI � Adapter ? PHY
    // -------------------------------------------------------------------------
    input logic [3:0] i_lp_state_req,     // Adapter request for state change
    input logic       i_lp_linkerror,     // Adapter ? PHY: error requiring link down
    input logic       i_lp_stallack,      // Adapter ? PHY: flits aligned & stalled
    input logic       i_lp_clk_ack,       // Adapter ack of pl_clk_req
    input logic       i_sb_cur_msg_done,
    input logic       i_lp_wake_req,      // Adapter request to remove PHY clock gating

    // -------------------------------------------------------------------------
    // PHY status inputs
    // -------------------------------------------------------------------------
    input logic       i_pll_stable,     // PLL stable indicator
    input logic       i_supply_stable,  // PLL stable indicator
    input logic       i_rx_error,       // RX detected an error
    input logic       i_tx_done,        // TX has finished
    input logic       i_rx_done,        // RX has finished
    input logic [2:0] i_Lane_map_code,

    // -------------------------------------------------------------------------
    // Pattern detection results
    // -------------------------------------------------------------------------
    input logic [63:0] i_rx_data_results,   // Per data-lane detection results
    input logic        i_rx_valid_results,  // Valid-lane detection result
    input logic [ 2:0] i_rx_clk_results,    // Valid-lane detection result

    // -------------------------------------------------------------------------
    // Sideband message decoding (SB ? LTSM)
    // -------------------------------------------------------------------------
    input logic [DECODING_WIDTH-1:0] i_tx_decoding,  // Decoded SB message on TX path
    input logic [DECODING_WIDTH-1:0] i_rx_decoding,  // Decoded SB message on RX path
    input logic [DATA_WIDTH-1:0] i_tx_data,  // Payload of incoming SB message � TX path
    input logic [DATA_WIDTH-1:0] i_rx_data,  // Payload of incoming SB message � RX path
    input logic [INFO_WIDTH-1:0] i_tx_info,  // Info field of incoming SB message � TX path
    input logic [INFO_WIDTH-1:0] i_rx_info,  // Info field of incoming SB message � RX path

    // -------------------------------------------------------------------------
    // Sideband handshake � SB ? LTSM
    // -------------------------------------------------------------------------
    input logic i_sb_tx_req,   // SB ? TX: REQ message received
    input logic i_sb_tx_rsp,   // SB ? TX: RSP message received
    input logic i_sb_rx_req,   // SB ? RX: REQ message received
    input logic i_sb_rx_rsp,   // SB ? RX: RSP message received
    input logic i_sb_tx_done,  // SB has consumed TX message
    input logic i_sb_rx_done,  // SB has consumed RX message

    // -------------------------------------------------------------------------
    // SBINIT
    // -------------------------------------------------------------------------
    input logic i_sb_ready,  // Stop-respond in SBINIT pattern detection

    input [15:0] r_local_cap,
    input [ 2:0] i_speedreg,
    input [36:0] i_Runtime_Link_Test_Control_register,
    input        i_Runtime_Link_Test_status_register,

    // -------------------------------------------------------------------------
    // RDI � PHY ? Adapter
    // -------------------------------------------------------------------------
    output logic [3:0] o_pl_state_sts,      // PHY ? Adapter: interface status
    output logic       o_pl_inband_pres,    // Link trained, ready for Active / Stage 3
    output logic       o_pl_error,          // Recoverable framing error
    output logic       o_pl_cerror,         // Correctable error (no retrain)
    output logic       o_pl_nferror,        // Non-fatal error
    output logic       o_pl_trainerror,     // Fatal training error
    output logic       o_pl_phyinrecenter,  // PHY is training or retraining
    output logic       o_pl_stallreq,       // Request adapter flit-boundary stall
    output logic       o_pl_max_speedmode,  // Negotiated max data rate (0:=32 GT/s, 1:>32)
    output logic [2:0] o_pl_speedmode,      // Current link speed
    output logic [2:0] o_lane_map_tx,       // Current link speed
    output logic [2:0] o_lane_map_rx,       // Current link speed
    output logic [2:0] o_pl_lnk_cfg,        // Current link configuration / width
    output logic       o_pl_clk_req,        // Request to ungate adapter clocks
    output logic       o_pl_wake_ack,       // Ack of lp_wake_req

    // -------------------------------------------------------------------------
    // Sideband message encoding (LTSM ? SB / TX-RX controllers)
    // -------------------------------------------------------------------------
    output logic [DECODING_WIDTH-1:0] o_tx_encoding,  // Outgoing message encoding � TX path
    output logic [DECODING_WIDTH-1:0] o_rx_encoding,  // Outgoing message encoding � RX path
    output logic [    DATA_WIDTH-1:0] o_tx_data,      // Outgoing message payload � TX path
    output logic [    DATA_WIDTH-1:0] o_rx_data,      // Outgoing message payload � RX path
    output logic [    INFO_WIDTH-1:0] o_tx_info,      // Outgoing message info � TX path
    output logic [    INFO_WIDTH-1:0] o_rx_info,      // Outgoing message info � RX path

    // -------------------------------------------------------------------------
    // Sideband handshake � LTSM ? SB
    // -------------------------------------------------------------------------
    output logic o_tx_sb_req,   // TX ? SB: send REQ message
    output logic o_tx_sb_rsp,   // TX ? SB: send RSP message
    output logic o_rx_sb_req,   // RX ? SB: send REQ message
    output logic o_rx_sb_rsp,   // RX ? SB: send RSP message
    output logic o_tx_sb_done,  // TX has consumed SB message
    output logic o_rx_sb_done,  // RX has consumed SB message

    // -------------------------------------------------------------------------
    // SBINIT start trigger
    // -------------------------------------------------------------------------
    output logic o_sb_init_start,  // Initialise SBINIT state

    output logic [ 2:0] o_speedreg,
    output logic [36:0] o_Runtime_Link_Test_Control_register,
    output logic        o_Runtime_Link_Test_status_register
);

  logic w_timer_1ms;
  logic w_timer_4ms;
  logic w_timer_8ms;
  logic w_timer_1us;
  logic w_timer_2us;

  logic w_init_train_en;
  logic w_tx_train_link_init_en;
  logic w_tx_train_phyretrain_en;
  logic w_rx_train_link_init_en;
  logic w_rx_train_phyretrain_en;
  logic w_reset;
  logic [3:0] w_init_current_state;
  logic [3:0] w_active_current_state;

  logic w_rsp_sent;
  logic w_rsp_sent_old;
  logic w_rsp_received;
  logic w_rsp_received_old;
  logic [DECODING_WIDTH-1 : 0] w_encoding_rsp_sent;
  logic [DECODING_WIDTH-1 : 0] w_encoding_rsp_sent_old;
  logic [DECODING_WIDTH-1 : 0] w_encoding_rsp_received;
  logic [DECODING_WIDTH-1 : 0] w_encoding_rsp_received_old;

  logic [DECODING_WIDTH-1 : 0] w_init_tx_encoding;
  logic [DATA_WIDTH-1 : 0] w_init_tx_data;
  logic [INFO_WIDTH-1 : 0] w_init_tx_info;
  logic w_init_tx_sb_req;
  logic w_init_tx_sb_rsp;
  logic w_init_tx_sb_done;

  logic [DECODING_WIDTH-1 : 0] w_init_rx_encoding;
  logic [DATA_WIDTH-1 : 0] w_init_rx_data;
  logic [INFO_WIDTH-1 : 0] w_init_rx_info;
  logic w_init_rx_sb_req;
  logic w_init_rx_sb_rsp;
  logic w_init_rx_sb_done;

  logic [DECODING_WIDTH-1 : 0] w_train_tx_encoding;
  logic [DATA_WIDTH-1 : 0] w_train_tx_data;
  logic [INFO_WIDTH-1 : 0] w_train_tx_info;
  logic w_train_tx_sb_req;
  logic w_train_tx_sb_rsp;
  logic w_train_tx_sb_done;

  logic [DECODING_WIDTH-1 : 0] w_train_rx_encoding;
  logic [DATA_WIDTH-1 : 0] w_train_rx_data;
  logic [INFO_WIDTH-1 : 0] w_train_rx_info;
  logic w_train_rx_sb_req;
  logic w_train_rx_sb_rsp;
  logic w_train_rx_sb_done;
  logic L1_SPEEDIDLE_en;

  logic [DECODING_WIDTH-1 : 0] w_active_tx_encoding;
  logic [DATA_WIDTH-1 : 0] w_active_tx_data;
  logic [INFO_WIDTH-1 : 0] w_active_tx_info;
  logic w_active_tx_sb_req;
  logic w_active_tx_sb_rsp;
  logic w_active_tx_sb_done;

  logic [DECODING_WIDTH-1 : 0] w_active_rx_encoding;
  logic [DATA_WIDTH-1 : 0] w_active_rx_data;
  logic [INFO_WIDTH-1 : 0] w_active_rx_info;
  logic w_active_rx_sb_req;
  logic w_active_rx_sb_rsp;
  logic w_active_rx_sb_done;

  logic w_repair_state_enable;
  logic w_active_error;
  logic w_train_tx_error;
  logic w_train_rx_error;
  logic w_tx_self_cal_state_enable;
  logic w_speed_idle_state_enable;

  logic w_wait_1us_en;

  logic [3:0] w_timer_rx_encoding;

  always @(posedge i_clk or posedge i_reset) begin
    if (i_reset) begin
      w_rsp_sent_old <= 0;
      w_rsp_received_old <= 0;
      w_encoding_rsp_sent_old <= 0;
      w_encoding_rsp_received_old <= 0;
    end else begin
      w_rsp_sent_old <= w_rsp_sent;
      w_rsp_received_old <= w_rsp_received;
      w_encoding_rsp_sent_old <= w_encoding_rsp_sent;
      w_encoding_rsp_received_old <= w_encoding_rsp_received;
    end
  end

  always @(*) begin
    if (o_rx_sb_rsp) begin
      w_rsp_sent = 1;
      w_encoding_rsp_sent = o_rx_encoding;
    end else begin
      w_rsp_sent = w_rsp_sent_old;
      w_encoding_rsp_sent = w_encoding_rsp_sent_old;
    end

    if (i_sb_tx_rsp) begin
      w_rsp_received = 1;
      w_encoding_rsp_received = i_tx_decoding;
    end else begin
      w_rsp_received = w_rsp_received_old;
      w_encoding_rsp_received = w_encoding_rsp_received_old;
    end
  end

  always @(*) begin
    if (i_reset) begin
      o_tx_encoding = w_init_tx_encoding;
      o_tx_data = w_init_tx_data;
      o_rx_data = w_init_rx_data;
      o_tx_info = w_init_tx_info;
      o_rx_info = w_init_rx_info;

      o_tx_sb_req = w_init_tx_sb_req;
      o_rx_sb_req = w_init_rx_sb_req;
      o_tx_sb_rsp = w_init_tx_sb_rsp;
      o_rx_sb_rsp = w_init_rx_sb_rsp;
      o_tx_sb_done = w_init_tx_sb_done;
      o_rx_sb_done = w_init_rx_sb_done;
    end else if (w_rx_train_link_init_en || w_rx_train_phyretrain_en) begin
      o_tx_encoding = w_active_tx_encoding;
      o_tx_data = 0;
      o_rx_data = 0;
      o_tx_info = w_active_tx_info;
      o_rx_info = w_active_rx_info;

      o_tx_sb_req = w_active_tx_sb_req;
      o_rx_sb_req = w_active_rx_sb_req;
      o_tx_sb_rsp = w_active_tx_sb_rsp;
      o_rx_sb_rsp = w_active_rx_sb_rsp;
      o_tx_sb_done = w_active_tx_sb_done;
      o_rx_sb_done = w_active_rx_sb_done;
    end else if (w_init_train_en) begin
      o_tx_encoding = w_train_tx_encoding;
      o_tx_data = w_train_tx_data;
      o_rx_data = w_train_rx_data;
      o_tx_info = w_train_tx_info;
      o_rx_info = w_train_rx_info;

      o_tx_sb_req = w_train_tx_sb_req;
      o_rx_sb_req = w_train_rx_sb_req;
      o_tx_sb_rsp = w_train_tx_sb_rsp;
      o_rx_sb_rsp = w_train_rx_sb_rsp;
      o_tx_sb_done = w_train_tx_sb_done;
      o_rx_sb_done = w_train_rx_sb_done;
    end else begin
      o_tx_encoding = w_init_tx_encoding;
      o_tx_data = w_init_tx_data;
      o_rx_data = w_init_rx_data;
      o_tx_info = w_init_tx_info;
      o_rx_info = w_init_rx_info;

      o_tx_sb_req = w_init_tx_sb_req;
      o_rx_sb_req = w_init_rx_sb_req;
      o_tx_sb_rsp = w_init_tx_sb_rsp;
      o_rx_sb_rsp = w_init_rx_sb_rsp;
      o_tx_sb_done = w_init_tx_sb_done;
      o_rx_sb_done = w_init_rx_sb_done;
    end
  end

  always @(*) begin
    if (i_reset) begin
      o_rx_encoding = w_init_rx_encoding;
    end else if (w_rx_train_link_init_en || w_rx_train_phyretrain_en) begin
      o_rx_encoding = w_active_rx_encoding;
    end else if (w_init_train_en) begin
      o_rx_encoding = w_train_rx_encoding;
    end else begin
      o_rx_encoding = w_init_rx_encoding;
    end
  end

  ucie_timeout_timer #(
      .SIM_8MS_CYCLES(SIM_8MS_CYCLES),
      .DECODING_WIDTH(DECODING_WIDTH),
      .CLK_PERIOD_NS (CLK_PERIOD_NS)
  ) ucie_timeout_timer_inst (
      .i_clk(i_clk),
      .i_reset(i_reset),
      .i_sim(1),
      .wait_1us(w_wait_1us_en),
      .o_rx_encoding(o_rx_encoding),
      .o_timer_1ms(w_timer_1ms),
      .o_timer_4ms(w_timer_4ms),
      .o_timer_8ms(w_timer_8ms),
      .o_timer_1us(w_timer_1us),
      .o_timer_2us(w_timer_2us)
  );

  ucie_ltsm_init_fsm #(
      .DECODING_WIDTH(DECODING_WIDTH),
      .DATA_WIDTH    (DATA_WIDTH),
      .INFO_WIDTH    (INFO_WIDTH)
  ) ucie_ltsm_init_fsm_inst (
      // -------------------------------------------------------------------------
      // Global clock & reset
      // -------------------------------------------------------------------------
      .i_clk  (i_clk),
      .i_reset(i_reset),

      // -------------------------------------------------------------------------
      // TX-side inputs
      // -------------------------------------------------------------------------
      .i_tx_decoding(i_tx_decoding),
      .i_tx_data    (i_tx_data),
      .i_tx_info    (i_tx_info),
      .i_sb_tx_req  (i_sb_tx_req),
      .i_sb_tx_rsp  (i_sb_tx_rsp),
      .i_sb_tx_done (i_sb_tx_done),
      .i_tx_done    (i_tx_done),
      .r_local_cap  (r_local_cap),

      // -------------------------------------------------------------------------
      // RX-side inputs
      // -------------------------------------------------------------------------
      .i_rx_decoding(i_rx_decoding),
      .i_rx_data    (i_rx_data),
      .i_rx_info    (i_rx_info),
      .i_sb_rx_req  (i_sb_rx_req),
      .i_sb_rx_rsp  (i_sb_rx_rsp),
      .i_sb_rx_done (i_sb_rx_done),
      .i_rx_done    (i_rx_done),

      // -------------------------------------------------------------------------
      // RESET sub-FSM specific inputs
      // -------------------------------------------------------------------------
      .i_pll_stable   (i_pll_stable),
      .i_supply_stable(i_supply_stable),
      .i_timer_4ms    (w_timer_4ms),

      // -------------------------------------------------------------------------
      // SBINIT sub-FSM specific inputs
      // -------------------------------------------------------------------------
      .i_sb_ready(i_sb_ready),

      // -------------------------------------------------------------------------
      // REPAIRCLK / REPAIRVAL / REVERSAL pattern-detection results
      // -------------------------------------------------------------------------
      .i_rx_repairclk_pattern_results(i_rx_clk_results),
      .i_rx_repairval_pattern_results(i_rx_valid_results),
      .i_rx_reversal_pattern_results (i_rx_data_results),

      .i_lp_linkerror(i_lp_linkerror),
      .i_sb_cur_msg_done(i_sb_cur_msg_done),

      // -------------------------------------------------------------------------
      // REPAIRMB eye-sweep inputs
      // -------------------------------------------------------------------------
      .i_tx_sweep_result(8'b0),
      .i_rx_sweep_result(8'b0),

      // -------------------------------------------------------------------------
      // 8 ms timeout (shared with TRAIN & ACTIVE FSMs)
      // -------------------------------------------------------------------------
      .o_timer_8ms(w_timer_8ms),

      // -------------------------------------------------------------------------
      // Active-training error
      // -------------------------------------------------------------------------
      .i_train_active_error(w_active_error || w_train_tx_error || w_train_rx_error),

      // -------------------------------------------------------------------------
      // TX output bus
      // -------------------------------------------------------------------------
      .o_tx_encoding(w_init_tx_encoding),
      .o_tx_data    (w_init_tx_data),
      .o_tx_info    (w_init_tx_info),
      .o_tx_sb_req  (w_init_tx_sb_req),
      .o_tx_sb_rsp  (w_init_tx_sb_rsp),
      .o_tx_sb_done (w_init_tx_sb_done),

      // -------------------------------------------------------------------------
      // RX output bus
      // -------------------------------------------------------------------------
      .o_rx_encoding(w_init_rx_encoding),
      .o_rx_data    (w_init_rx_data),
      .o_rx_info    (w_init_rx_info),
      .o_rx_sb_req  (w_init_rx_sb_req),
      .o_rx_sb_rsp  (w_init_rx_sb_rsp),
      .o_rx_sb_done (w_init_rx_sb_done),

      // -------------------------------------------------------------------------
      // Status outputs
      // -------------------------------------------------------------------------
      .o_init_train_en(w_init_train_en),
      .o_sb_init_start(o_sb_init_start),
      .o_current_state(w_init_current_state)
  );

  ucie_LTSM_TX_MBTRAIN #(
      .DECODING_WIDTH (DECODING_WIDTH),  // Width of encoding/decoding signals
      .DATA_WIDTH     (DATA_WIDTH),      // Width of data bus
      .INFO_WIDTH     (INFO_WIDTH),      // Width of info/control bus
      .ERROR_THRESHOLD(ERROR_THRESHOLD)  // Threshold for acceptable training errors
  ) ucie_LTSM_TX_MBTRAIN_inst (
      // Clock and reset
      .i_clk            (i_clk),
      .i_reset          (i_reset),
      .rx_trainerror    (w_train_rx_error),
      // TX interface inputs - data coming from remote RX
      .i_tx_decoding    (i_tx_decoding),     // Decoded command from RX
      .i_tx_data        (i_tx_data),         // Data from RX
      .i_tx_info        (i_tx_info),         // Info/control from RX
      .i_tx_sweep_result(8'b0), // Eye sweep test results


      // Sideband control inputs
      .i_sb_tx_req (i_sb_tx_req),   // Sideband request from RX
      .i_sb_tx_rsp (i_sb_tx_rsp),   // Sideband response from RX
      .i_sb_tx_done(i_sb_tx_done),  // Sideband done from RX
      .i_tx_done   (i_tx_done),     // TX operation complete

      // Training control inputs
      .init_train_en(w_init_train_en),  // Enable training initialization
      .speed_idle_state_enable(w_speed_idle_state_enable),  // Enable training initialization
      .repair_state_enable(w_repair_state_enable),  // Enable training initialization
      .tx_self_cal_state_enable(w_tx_self_cal_state_enable),  // Enable training initialization
      .timeout(w_timer_8ms),  // Training timeout error
      .o_pl_speedmode(o_pl_speedmode),  // Physical layer speed mode
      .i_speedreg(i_speedreg),  // Physical layer speed mode
      .o_speedreg(o_speedreg),  // Physical layer speed mode
      .o_lane_map_tx(o_lane_map_tx),  // Lane map output for TX
      .encoding_rsp_sent(w_encoding_rsp_sent),  // Encoding value when response sent
      .encoding_rsp_received(w_encoding_rsp_received),  // Encoding value when response received
      .rsp_received(w_rsp_received),  // Response sent flag
      .rsp_sent(w_rsp_sent),  // Response sent flag

      // TX interface outputs - data going to remote RX
      .o_tx_encoding(w_train_tx_encoding),  // Encoded command to send
      .o_tx_data    (w_train_tx_data),      // Data to send
      .o_tx_info    (w_train_tx_info),      // Info/control to send
      .failed_test  (w_tx_error),           // Info/control to send
      .L1_SPEEDIDLE_en(L1_SPEEDIDLE_en),

      // Sideband control outputs
      .o_tx_sb_req (w_train_tx_sb_req),  // Sideband request to RX
      .o_tx_sb_rsp (w_train_tx_sb_rsp),  // Sideband response to RX
      .o_tx_sb_done(w_train_tx_sb_done), // Sideband done to RX

      // Status outputs
      .train_error        (w_train_tx_error),         // Training error occurred
      .train_link_init_en (w_tx_train_link_init_en),  // Training is active
      .train_phyretrain_en(w_tx_train_phyretrain_en)  // Training is active
  );

  ucie_LTSM_RX_MBTRAIN #(
      .DECODING_WIDTH (DECODING_WIDTH),  // Width of encoding/decoding signals
      .DATA_WIDTH     (DATA_WIDTH),      // Width of data bus
      .INFO_WIDTH     (INFO_WIDTH),      // Width of info/control bus
      .ERROR_THRESHOLD(ERROR_THRESHOLD)  // Threshold for acceptable training errors
  ) ucie_LTSM_RX_MBTRAIN_inst (
      // Clock and reset
      .i_clk(i_clk),
      .i_reset(i_reset),
      .tx_trainerror(w_train_tx_error),
      // RX interface inputs - data coming from remote TX
      .i_rx_decoding(i_rx_decoding),  // Decoded command from TX
      .i_rx_data(i_rx_data),  // Data from TX
      .i_rx_info(i_rx_info),  // Info/control from TX
      .i_rx_data_results              (i_rx_data_results),    // Results from eye sweep tests (could be multiple signals or a bus of results)
      .i_rx_valid_results             (i_rx_valid_results),    // Results from eye sweep tests (could be multiple signals or a bus of results)
      .i_lane_map(o_lane_map_tx),

      // Sideband control inputs
      .i_sb_rx_req (i_sb_rx_req),   // Sideband request from TX
      .i_sb_rx_rsp (i_sb_rx_rsp),   // Sideband response from TX
      .i_sb_rx_done(i_sb_rx_done),  // Sideband done from TX
      .i_rx_done   (i_rx_done),     // RX operation complete
      .i_tx_done   (i_tx_done),     // TX operation complete
      .i_tx_error  (w_tx_error),    // TX operation complete

      // Training control inputs
      .init_train_en           (w_init_train_en),             // Enable training initialization
      .speed_idle_state_enable (w_speed_idle_state_enable),   // Enable training initialization
      .tx_self_cal_state_enable(w_tx_self_cal_state_enable),  // Enable training initialization
      .timeout                 (w_timer_8ms),                 // Training timeout error
      .o_pl_speedmode          (o_pl_speedmode),              // Physical layer speed mode
      .o_lane_map_rx           (o_lane_map_rx),

      .encoding_rsp_sent    (w_encoding_rsp_sent),      // Encoding value when response sent
      .encoding_rsp_received(w_encoding_rsp_received),  // Encoding value when response received
      .rsp_received         (w_rsp_received),           // Response sent flag
      .rsp_sent             (w_rsp_sent),               // Response sent flag

      // RX interface outputs - data going to remote TX
      .o_rx_encoding(w_train_rx_encoding),  // Encoded command to send
      .o_rx_data    (w_train_rx_data),      // Data to send
      .o_rx_info    (w_train_rx_info),      // Info/control to send

      // Sideband control outputs
      .o_rx_sb_req (w_train_rx_sb_req),  // Sideband request to TX
      .o_rx_sb_rsp (w_train_rx_sb_rsp),  // Sideband response to TX
      .o_rx_sb_done(w_train_rx_sb_done), // Sideband done to TX

      // Status outputs
      .train_error        (w_train_rx_error),         // Training error occurred
      .train_link_init_en (w_rx_train_link_init_en),  // Training is active
      .train_phyretrain_en(w_rx_train_phyretrain_en)  // Training is active
  );

  ucie_ltsm_active_fsm ucie_ltsm_active_fsm_inst (
      .i_clk  (i_clk),
      .i_reset(i_reset),

      // Entry trigger from ucie_ltsm_init_fsm
      .i_train_active_en(w_rx_train_link_init_en),
      .phyretrain_linkspeed_transition(w_rx_train_phyretrain_en),

      .i_tx_info(i_tx_info),
      .i_rx_info(i_rx_info),

      .valid_error(!(&i_rx_valid_results)),

      // RDI interface � from Adapter
      .i_lp_clk_ack  (i_lp_clk_ack),
      .i_lp_wake_req (i_lp_wake_req),
      .i_lp_state_req(i_lp_state_req),
      .i_lp_linkerror(i_lp_linkerror),
      .i_lp_stallack (i_lp_stallack),

      // TX sideband inputs
      .i_tx_decoding(i_tx_decoding),
      .i_sb_tx_req  (i_sb_tx_req),
      .i_sb_tx_rsp  (i_sb_tx_rsp),
      .i_sb_tx_done (i_sb_tx_done),
      .Lane_map_code(o_lane_map_tx),

      // RX sideband inputs
      .i_rx_decoding(i_rx_decoding),
      .i_sb_rx_req(i_sb_rx_req),
      .i_sb_rx_rsp(i_sb_rx_rsp),
      .i_sb_rx_done(i_sb_rx_done),
      .rsp_sent(w_rsp_sent),
      .rsp_received(w_rsp_received),
      .encoding_rsp_received(w_encoding_rsp_received),
      .encoding_rsp_sent(w_encoding_rsp_sent),

      // Shared 8ms timeout
      .o_timer_8ms(w_timer_8ms),
      .i_timer_1us(w_timer_1us),
      .i_timer_2us(w_timer_2us),

      .i_Runtime_Link_Test_Control_register(i_Runtime_Link_Test_Control_register),
      .i_Runtime_Link_Test_status_register (i_Runtime_Link_Test_status_register),

      // TX sideband outputs (muxed)
      .o_tx_encoding(w_active_tx_encoding),
      .o_tx_sb_req  (w_active_tx_sb_req),
      .o_tx_sb_rsp  (w_active_tx_sb_rsp),
      .o_tx_sb_done (w_active_tx_sb_done),

      // RX sideband outputs (muxed)
      .o_rx_encoding(w_active_rx_encoding),
      .o_rx_sb_req  (w_active_rx_sb_req),
      .o_rx_sb_rsp  (w_active_rx_sb_rsp),
      .o_rx_sb_done (w_active_rx_sb_done),

      .o_tx_info(w_active_tx_info),
      .o_rx_info(w_active_rx_info),

      // RDI outputs � to Adapter
      .o_pl_clk_req(o_pl_clk_req),
      .o_pl_inband_pres(o_pl_inband_pres),
      .o_pl_wake_ack(o_pl_wake_ack),
      .o_pl_state_sts(o_pl_state_sts),
      .o_pl_stallreq(o_pl_stallreq),

      .speed_idle_state_enable(w_speed_idle_state_enable),
      .l1_tx_speed_idle_en(L1_SPEEDIDLE_en),
      .repair_state_enable(w_repair_state_enable),
      .tx_self_cal_state_enable(w_tx_self_cal_state_enable),

      // Transition done flags (forwarded from ucie_ltsm_active for external use)
      .o_done_active_linkreset(w_reset),
      .o_done_active_linkerror(w_active_error),

      // Debug
      .o_current_state(w_active_current_state),
      .wait_1us_en(w_wait_1us_en),

      .o_Runtime_Link_Test_Control_register(o_Runtime_Link_Test_Control_register),
      .o_Runtime_Link_Test_status_register (o_Runtime_Link_Test_status_register)
  );

endmodule