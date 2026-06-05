module UCIe_phy #(
    parameter int pNUM_LANES = 16,
    parameter int pDATA_RDI_WIDTH = 2048,
    parameter int pDATA_WIDTH = 64,
    parameter int NBYTES = 256
) (
    input                                   i_clk_32,
    input                                   i_clk_24,
    input                                   i_clk_16,
    input                                   i_clk_12,
    input                                   i_clk_8,
    input                                   i_clk_4,
    input                                   i_clk_sb_800_m,
    input                                   i_clk_sb_100_m,
    input                                   i_reset,
    input                                   i_pll_stable,
    input                                   i_supply_stable,
    input                                   i_clk_p,
    input                                   i_clk_n,
    input                                   i_track,
    input                                   i_valid,
    input        [     pNUM_LANES-1:0]      i_data_in,
    input                                   i_rx_sb_clk,
    input                                   i_rx_sb_data,
    input        [                3:0]      i_lp_state_req,
    input                                   i_lp_linkerror,
    input                                   i_lp_stallack,
    input                                   i_lp_clk_ack,
    input                                   i_lp_irdy,
    input                                   i_lp_valid,
    input        [         NBYTES-1:0][7:0] i_lp_data,
    input                                   i_lp_wake_req,
    output logic [                3:0]      o_pl_state_sts,
    output logic                            o_pl_inband_pres,
    output logic                            o_pl_error,
    output logic                            o_pl_cerror,
    output logic                            o_pl_nferror,
    output logic                            o_pl_trainerror,
    output logic                            o_pl_phyinrecenter,
    output logic                            o_pl_stallreq,
    output logic                            o_pl_max_speedmode,
    output logic [                2:0]      o_pl_speedmode,
    output logic [                2:0]      o_pl_lnk_cfg,
    output logic                            o_pl_clk_req,
    output logic                            o_pl_wake_ack,
    output logic                            o_pl_trdy,
    output logic                            o_pl_valid,
    output logic                            o_tx_sb_data,
    output logic                            o_tx_sb_clk,
    output logic [pDATA_RDI_WIDTH-1:0]      o_pl_data,
    output logic                            o_data_out        [pNUM_LANES-1:0],
    output logic                            o_clk_p,
    output logic                            o_clk_n,
    output logic                            o_track,
    output logic                            o_valid
);
  wire  clk_mb_f;  // full rate clock used in mainband
  wire  clk_mb_h;  // half rate clock used in mainband
  wire  clk_l;  // Logical clock used in mainband & LTSM
  logic sb_ready;
  logic sb_ready_reg;
  bit   t1_ms;
  logic   reset_sb;
  logic   reset_sb_reg;
  PLL_model PLL (
      .i_sel(LTSM_controllers_vif.o_speedreg),
      .i_reset(LTSM_controllers_vif.i_reset),
      .i_clk_32(i_clk_32),
      .i_clk_24(i_clk_24),
      .i_clk_16(i_clk_16),
      .i_clk_12(i_clk_12),
      .i_clk_8(i_clk_8),
      .i_clk_4(i_clk_4),
      .o_clk_s(clk_mb_f),
      .o_clk_h(clk_mb_h),
      .o_clk_l(clk_l)
    , .o_sim_cycles_8(LTSM_controllers_vif.i_sim_cycles_8)
    , .o_sim_cycles_4(LTSM_controllers_vif.i_sim_cycles_4)
    , .o_sim_cycles_1(LTSM_controllers_vif.i_sim_cycles_1)
    , .o_sim_cycles_1_us(LTSM_controllers_vif.i_sim_cycles_1_us)
    , .o_sim_cycles_2_us(LTSM_controllers_vif.i_sim_cycles_2_us)
  );

  // interfaces

  // LTSM interfaces
  ltsm_rdi_if ltsm_rdi_if_inst (.clk(clk_l));
  TX_FSM_SB tx_fsm_sb_if (clk_l);
  RX_FSM_SB rx_fsm_sb_if (clk_l);
  LTSM_controllers_if LTSM_controllers_vif (clk_l);

  // side band interfaces

  sb_reset_intf reset_intf (
      .clk(i_clk_sb_100_m)
      // , .reset(i_reset)
  );

  // LTSM control interface
  sb_ltsm_ctrl_bfm ltsm_ctrl_bfm (
      .clk(i_clk_sb_100_m),
      .clk_800(clk_l)
      , .reset(reset_sb)
      , .o_sb_ready(sb_ready)
  );

  // TX path interface
  sb_tx_bfm tx_bfm (
      .clk(i_clk_sb_100_m)
      , .reset(reset_sb)
      , .o_sb_ready(sb_ready)
  );

  // RX path interface
  sb_rx_bfm rx_bfm (
      .clk(i_clk_sb_100_m)
      , .reset(reset_sb)
      , .o_sb_ready(sb_ready)
  );

  // D2D Adapter interface (RDI)
  sb_rdi_bfm rdi_bfm (
      .clk(i_clk_sb_100_m)
      , .reset(reset_sb)
      , .o_sb_ready(sb_ready)
  );

  // Physical link interface
  sb_phylink_bfm phylink_bfm (
      .clk(i_clk_sb_100_m)
      , .clk_800MHz(i_clk_sb_800_m)
      , .reset(reset_sb)
      , .o_sb_ready(sb_ready)
  );

  rp_reset_intf rp_reset_intf_inst (
      .clk(clk_l)
      // , .reset(i_reset)
  );

  // D2D Adapter interface (RDI)
  rp_rdi_bfm rp_rdi_bfm_inst (
        .clk  (clk_l)
      , .reset(i_reset)
  );

  // LTSM controller interface
  rp_ltsmc_bfm rp_ltsmc_bfm_inst (
        .clk  (clk_l)
      , .reset(i_reset)
  );

  // Physical link interface
  rp_rmblink_bfm rp_rmblink_bfm_inst (
      .clk(clk_l)
      , .reset(i_reset)
      , .i_hclk(clk_mb_h)
      , .i_dclk(clk_mb_f)
  );

  rdi_if #(
      .NBYTES(256)
  ) rdi_intf (
      .clk(clk_l),
      .rst(i_reset)
  );

  ltsm_if ltsm_intf (
      .clk(clk_l),
      .rst(i_reset)
  );

  tx2link_if tx2link_intf (
      .clk(clk_l),
      .ui_clk(clk_mb_f),
      .rst(i_reset)
  );

  // interface connections

  always_comb begin
    phylink_bfm.tms = ltsm_ctrl_bfm.tms;
    phylink_bfm.timeout = ltsm_ctrl_bfm.timeout;
    phylink_bfm.start = ltsm_ctrl_bfm.i_sb_init_start;


    LTSM_controllers_vif.i_clk = clk_l;
    ltsm_rdi_if_inst.i_reset = LTSM_controllers_vif.i_reset;
    tx_fsm_sb_if.i_reset = LTSM_controllers_vif.i_reset;
    rx_fsm_sb_if.i_reset = LTSM_controllers_vif.i_reset;

    LTSM_controllers_vif.i_pll_stable = i_pll_stable;
    LTSM_controllers_vif.i_supply_stable = i_supply_stable;
    LTSM_controllers_vif.i_reset = i_reset;

    ltsm_rdi_if_inst.i_lp_state_req = i_lp_state_req;
    ltsm_rdi_if_inst.i_lp_linkerror = i_lp_linkerror;
    ltsm_rdi_if_inst.i_lp_stallack = i_lp_stallack;
    ltsm_rdi_if_inst.i_lp_clk_ack = i_lp_clk_ack;
    ltsm_rdi_if_inst.i_lp_wake_req = i_lp_wake_req;
    o_pl_state_sts = ltsm_rdi_if_inst.o_pl_state_sts;
    o_pl_inband_pres = ltsm_rdi_if_inst.o_pl_inband_pres;
    o_pl_error = ltsm_rdi_if_inst.o_pl_error;
    o_pl_cerror = ltsm_rdi_if_inst.o_pl_cerror;
    o_pl_nferror = ltsm_rdi_if_inst.o_pl_nferror;
    o_pl_trainerror = ltsm_rdi_if_inst.o_pl_trainerror;
    o_pl_phyinrecenter = ltsm_rdi_if_inst.o_pl_phyinrecenter;
    o_pl_stallreq = ltsm_rdi_if_inst.o_pl_stallreq;
    o_pl_max_speedmode = ltsm_rdi_if_inst.o_pl_max_speedmode;
    o_pl_speedmode = ltsm_rdi_if_inst.o_pl_speedmode;
    o_pl_lnk_cfg = ltsm_rdi_if_inst.o_pl_lnk_cfg;
    o_pl_clk_req = ltsm_rdi_if_inst.o_pl_clk_req;
    o_pl_wake_ack = ltsm_rdi_if_inst.o_pl_wake_ack;

    LTSM_controllers_vif.o_rx_encoding = rx_fsm_sb_if.o_rx_encoding;
    LTSM_controllers_vif.o_tx_encoding = tx_fsm_sb_if.o_tx_encoding;

    tx_bfm.i_tx_encoding = tx_fsm_sb_if.o_tx_encoding;
    tx_bfm.i_tx_data = tx_fsm_sb_if.o_tx_data;
    tx_bfm.i_tx_info = tx_fsm_sb_if.o_tx_info;
    tx_bfm.i_tx_sb_req = tx_fsm_sb_if.o_tx_sb_req;
    tx_bfm.i_tx_sb_rsp = tx_fsm_sb_if.o_tx_sb_rsp;

    // tx_fsm_sb_if.i_sb_tx_done = tx_bfm.o_sb_tx_done;

    rx_bfm.i_rx_encoding = rx_fsm_sb_if.o_rx_encoding;
    rx_bfm.i_rx_data = rx_fsm_sb_if.o_rx_data;
    rx_bfm.i_rx_info = rx_fsm_sb_if.o_rx_info;
    rx_bfm.i_rx_sb_req = rx_fsm_sb_if.o_rx_sb_req;
    rx_bfm.i_rx_sb_rsp = rx_fsm_sb_if.o_rx_sb_rsp;

    // rx_fsm_sb_if.i_sb_rx_done = rx_bfm.o_sb_rx_done;

    ltsm_ctrl_bfm.i_sb_init_start = LTSM_controllers_vif.o_sbinit_start;
    LTSM_controllers_vif.i_sb_ready = sb_ready | sb_ready_reg;

    o_tx_sb_data = phylink_bfm.o_tx_sb_data;
    o_tx_sb_clk = phylink_bfm.o_tx_sb_clk;
    phylink_bfm.i_rx_sb_data = i_rx_sb_data;
    phylink_bfm.i_rx_sb_clk = i_rx_sb_clk;

    o_data_out = tx2link_intf.tx_data;
    o_valid = tx2link_intf.tx_valid;
    o_track = tx2link_intf.tx_track;
    o_clk_p = tx2link_intf.tx_clkp;
    o_clk_n = tx2link_intf.tx_clkn;

    rdi_intf.lp_data = i_lp_data;
    rdi_intf.lp_irdy = i_lp_irdy;
    rdi_intf.lp_valid = i_lp_valid;
    o_pl_trdy = rdi_intf.pl_trdy;

    ltsm_intf.tx_encoding = tx_defs_pkg::ltsm_encoding_e'(LTSM_controllers_vif.o_tx_encoding);
    ltsm_intf.lane_map = LTSM_controllers_vif.o_lane_map_tx;
    LTSM_controllers_vif.i_tx_done = ltsm_intf.tx_done;

    rp_rmblink_bfm_inst.i_rx_encoding = rp_ltsmc_bfm_inst.i_rx_encoding;
    rp_rmblink_bfm_inst.i_clk_p = i_clk_p;
    rp_rmblink_bfm_inst.i_clk_n = i_clk_n;
    rp_rmblink_bfm_inst.i_track = i_track;
    rp_rmblink_bfm_inst.i_data = i_data_in;
    rp_rmblink_bfm_inst.i_valid = i_valid;

    o_pl_data = rp_rdi_bfm_inst.pl_data;
    o_pl_valid = rp_rdi_bfm_inst.pl_valid;

    LTSM_controllers_vif.i_rx_done = rp_ltsmc_bfm_inst.o_rx_done;
    LTSM_controllers_vif.i_rx_data_results = rp_ltsmc_bfm_inst.o_rx_data_results;
    LTSM_controllers_vif.i_clk_results = rp_ltsmc_bfm_inst.o_clk_result;
    LTSM_controllers_vif.i_rx_valid_results = rp_ltsmc_bfm_inst.o_valid_result;
    rp_ltsmc_bfm_inst.i_rx_encoding = rp_shared_pkg::rx_encoding_t'(LTSM_controllers_vif.o_rx_encoding);
    rp_ltsmc_bfm_inst.i_lane_map_code = rp_shared_pkg::lane_map_code_t'(LTSM_controllers_vif.o_lane_map_rx);
    rp_ltsmc_bfm_inst.i_error_threshold = 1;
    rp_ltsmc_bfm_inst.i_half_rate = 1;
  end


  valid_decoder decoder_rx (
      .i_clk(clk_l),
      .i_valid(rx_bfm.o_rx_valid),
      .i_encoding(rx_bfm.o_rx_decoding),
      .i_req(rx_bfm.o_sb_rx_req),
      .i_rsp(rx_bfm.o_sb_rx_rsp),
      .i_data(rx_bfm.o_rx_data),
      .i_info(rx_bfm.o_rx_info),
      .i_done(rx_fsm_sb_if.o_rx_sb_done),
      .o_decoding(rx_fsm_sb_if.i_rx_decoding),
      .o_data(rx_fsm_sb_if.i_rx_data),
      .o_info(rx_fsm_sb_if.i_rx_info),
      .o_req(rx_fsm_sb_if.i_sb_rx_req),
      .o_rsp(rx_fsm_sb_if.i_sb_rx_rsp),
      .o_done(rx_bfm.i_rx_sb_done)
  );

  valid_decoder decoder_tx (
      .i_clk(clk_l),
      .i_valid(tx_bfm.o_tx_valid),
      .i_encoding(tx_bfm.o_tx_decoding),
      .i_req(tx_bfm.o_sb_tx_req),
      .i_rsp(tx_bfm.o_sb_tx_rsp),
      .i_data(tx_bfm.o_tx_data),
      .i_info(tx_bfm.o_tx_info),
      .i_done(tx_fsm_sb_if.o_tx_sb_done),
      .o_decoding(tx_fsm_sb_if.i_tx_decoding),
      .o_data(tx_fsm_sb_if.i_tx_data),
      .o_info(tx_fsm_sb_if.i_tx_info),
      .o_req(tx_fsm_sb_if.i_sb_tx_req),
      .o_rsp(tx_fsm_sb_if.i_sb_tx_rsp),
      .o_done(tx_bfm.i_tx_sb_done)
  );

  always_ff @(posedge clk_l or posedge i_reset) begin
    if (i_reset) begin
      ltsm_ctrl_bfm.i_timer_1ms <= 0;
    end else begin
      if (!ltsm_ctrl_bfm.i_timer_1ms) begin
        ltsm_ctrl_bfm.i_timer_1ms <= t1_ms;
      end else begin
        ltsm_ctrl_bfm.i_timer_1ms <= 0;
      end
    end
  end
  always @(posedge i_clk_sb_100_m) begin
    sb_ready_reg <= sb_ready;
  end
  assign LTSM_controllers_vif.i_Runtime_Link_Test_status_register  = 0;
  assign LTSM_controllers_vif.i_Runtime_Link_Test_Control_register = 0;

  assign reset_sb_reg = (tx_fsm_sb_if.o_tx_encoding == 0) ? 1'b1 : 1'b0; // add reset condition for sb if needed);
  // top instantiation of all blocks
  toggle_sync sync_rx(
    .i_clk(clk_l),
    .i_reset(i_reset),
    .i_cnt(rx_bfm.o_sb_rx_done),
    .o_cnt(rx_fsm_sb_if.i_sb_rx_done)
  );

  toggle_sync sync_tx(
    .i_clk(clk_l),
    .i_reset(i_reset),
    .i_cnt(tx_bfm.o_sb_tx_done),
    .o_cnt(tx_fsm_sb_if.i_sb_tx_done)
  );

  toggle_sync sync_rst(
    .i_clk(clk_l),
    .i_reset(i_reset),
    .i_cnt(reset_sb_reg),
    .o_cnt(reset_sb)
  );

  ucie_LTSM LTSM (
      .i_clk(clk_l),
      .i_tx_decoding(tx_fsm_sb_if.i_tx_decoding),
      .o_tx_encoding(tx_fsm_sb_if.o_tx_encoding),
      .i_tx_data(tx_fsm_sb_if.i_tx_data),
      .o_tx_data(tx_fsm_sb_if.o_tx_data),
      .i_sb_tx_req(tx_fsm_sb_if.i_sb_tx_req),
      .i_sb_tx_rsp(tx_fsm_sb_if.i_sb_tx_rsp),
      .i_sb_tx_done(tx_fsm_sb_if.i_sb_tx_done),
      .o_tx_sb_req(tx_fsm_sb_if.o_tx_sb_req),
      .o_tx_sb_rsp(tx_fsm_sb_if.o_tx_sb_rsp),
      .o_tx_sb_done(tx_fsm_sb_if.o_tx_sb_done),
      .i_rx_decoding(rx_fsm_sb_if.i_rx_decoding),
      .o_rx_encoding(rx_fsm_sb_if.o_rx_encoding),
      .i_rx_data(rx_fsm_sb_if.i_rx_data),
      .o_rx_data(rx_fsm_sb_if.o_rx_data),
      .i_tx_info(tx_fsm_sb_if.i_tx_info),
      .i_rx_info(rx_fsm_sb_if.i_rx_info),
      .o_tx_info(tx_fsm_sb_if.o_tx_info),
      .o_rx_info(rx_fsm_sb_if.o_rx_info),
      .i_sb_rx_req(rx_fsm_sb_if.i_sb_rx_req),
      .i_sb_rx_rsp(rx_fsm_sb_if.i_sb_rx_rsp),
      .i_sb_rx_done(rx_fsm_sb_if.i_sb_rx_done),
      .o_rx_sb_req(rx_fsm_sb_if.o_rx_sb_req),
      .o_rx_sb_rsp(rx_fsm_sb_if.o_rx_sb_rsp),
      .o_rx_sb_done(rx_fsm_sb_if.o_rx_sb_done),
      .i_supply_stable(LTSM_controllers_vif.i_supply_stable),
      .i_pll_stable(LTSM_controllers_vif.i_pll_stable),
      .i_rx_error(LTSM_controllers_vif.i_rx_error),
      .i_rx_done(LTSM_controllers_vif.i_rx_done),
      .i_tx_done(LTSM_controllers_vif.i_tx_done),
      .i_rx_valid_results(LTSM_controllers_vif.i_rx_valid_results),
      .i_rx_data_results(LTSM_controllers_vif.i_rx_data_results),
      .i_rx_clk_results(LTSM_controllers_vif.i_clk_results),
      .o_sb_init_start(LTSM_controllers_vif.o_sbinit_start),
      .i_sb_ready(LTSM_controllers_vif.i_sb_ready),
      .o_timer1ms(t1_ms),
      .i_reset(LTSM_controllers_vif.i_reset),
      //.i_par_check_done  (LTSM_controllers_vif.i_par_check_done), // needs to be fixed in the verification model and sequences 
      .i_sb_cur_msg_done(LTSM_controllers_vif.i_sb_cur_msg_done),
      .o_lane_map_tx(LTSM_controllers_vif.o_lane_map_tx),
      .o_lane_map_rx(LTSM_controllers_vif.o_lane_map_rx),
      .o_pl_state_sts(ltsm_rdi_if_inst.o_pl_state_sts),
      .o_pl_inband_pres(ltsm_rdi_if_inst.o_pl_inband_pres),
      .o_pl_phyinrecenter(ltsm_rdi_if_inst.o_pl_phyinrecenter),
      .o_pl_stallreq(ltsm_rdi_if_inst.o_pl_stallreq),
      .o_pl_clk_req(ltsm_rdi_if_inst.o_pl_clk_req),
      .o_pl_wake_ack(ltsm_rdi_if_inst.o_pl_wake_ack),
      .o_pl_lnk_cfg(ltsm_rdi_if_inst.o_pl_lnk_cfg),
      .o_pl_speedmode(ltsm_rdi_if_inst.o_pl_speedmode),
      .o_pl_max_speedmode(ltsm_rdi_if_inst.o_pl_max_speedmode),
      .o_pl_error(ltsm_rdi_if_inst.o_pl_error),
      .o_pl_trainerror(ltsm_rdi_if_inst.o_pl_trainerror),
      .o_pl_cerror(ltsm_rdi_if_inst.o_pl_cerror),
      .o_pl_nferror(ltsm_rdi_if_inst.o_pl_nferror),
      .i_lp_state_req(ltsm_rdi_if_inst.i_lp_state_req),
      .i_lp_stallack(ltsm_rdi_if_inst.i_lp_stallack),
      .i_lp_clk_ack(ltsm_rdi_if_inst.i_lp_clk_ack),
      .i_lp_wake_req(ltsm_rdi_if_inst.i_lp_wake_req),
      .i_lp_linkerror(ltsm_rdi_if_inst.i_lp_linkerror),
      .i_speedreg(LTSM_controllers_vif.i_speedreg),
      .o_speedreg(LTSM_controllers_vif.o_speedreg),
      //.i_local_cap                           (LTSM_controllers_vif.i_local_cap),
      .i_Runtime_Link_Test_status_register     (LTSM_controllers_vif.i_Runtime_Link_Test_status_register),
      .o_Runtime_Link_Test_status_register     (LTSM_controllers_vif.o_Runtime_Link_Test_status_register),
      .i_Runtime_Link_Test_Control_register    (LTSM_controllers_vif.i_Runtime_Link_Test_Control_register),
      .o_Runtime_Link_Test_Control_register    (LTSM_controllers_vif.o_Runtime_Link_Test_Control_register)
  );

  ucie_sb_top sideband (
      // Clock and reset
        .i_clk       (i_clk_sb_100_m)
      , .i_reset     (reset_sb)
      , .i_800MHz_clk(i_clk_sb_800_m)

      // TX path signals
      , .i_tx_sb_req  (tx_bfm.i_tx_sb_req)
      , .i_tx_sb_rsp  (tx_bfm.i_tx_sb_rsp)
      , .i_tx_sb_done (tx_bfm.i_tx_sb_done)
      , .i_tx_encoding(tx_bfm.i_tx_encoding)
      , .i_tx_data    (tx_bfm.i_tx_data)
      , .i_tx_info    (tx_bfm.i_tx_info)
      , .o_sb_tx_req  (tx_bfm.o_sb_tx_req)
      , .o_sb_tx_rsp  (tx_bfm.o_sb_tx_rsp)
      , .o_sb_tx_done (tx_bfm.o_sb_tx_done)
      , .o_tx_decoding(tx_bfm.o_tx_decoding)
      , .o_tx_data    (tx_bfm.o_tx_data)
      , .o_tx_info    (tx_bfm.o_tx_info)
      , .o_tx_valid   (tx_bfm.o_tx_valid)

      // RX path signals
      , .i_rx_sb_req  (rx_bfm.i_rx_sb_req)
      , .i_rx_sb_rsp  (rx_bfm.i_rx_sb_rsp)
      , .i_rx_sb_done (rx_bfm.i_rx_sb_done)
      , .i_rx_encoding(rx_bfm.i_rx_encoding)
      , .i_rx_data    (rx_bfm.i_rx_data)
      , .i_rx_info    (rx_bfm.i_rx_info)
      , .o_sb_rx_req  (rx_bfm.o_sb_rx_req)
      , .o_sb_rx_rsp  (rx_bfm.o_sb_rx_rsp)
      , .o_sb_rx_done (rx_bfm.o_sb_rx_done)
      , .o_rx_decoding(rx_bfm.o_rx_decoding)
      , .o_rx_data    (rx_bfm.o_rx_data)
      , .o_rx_info    (rx_bfm.o_rx_info)
      , .o_rx_valid   (rx_bfm.o_rx_valid)

      // LTSM control signals
      , .i_sb_init_start(ltsm_ctrl_bfm.i_sb_init_start)
      , .i_timer_1ms    (ltsm_ctrl_bfm.i_timer_1ms)
      , .o_sb_ready     (sb_ready)

      // Physical link interface
      , .i_rx_sb_data     (phylink_bfm.i_rx_sb_data)
      , .i_rx_sb_clk      (phylink_bfm.i_rx_sb_clk)
      , .o_tx_sb_data     (phylink_bfm.o_tx_sb_data)
      , .o_tx_sb_clk      (phylink_bfm.o_tx_sb_clk)
      , .o_sb_cur_msg_done(LTSM_controllers_vif.i_sb_cur_msg_done)
  );

  tx_dut_rtl_wrapper #(
      .NBYTES(NBYTES),
      .DATA_WIDTH(pDATA_WIDTH),
      .LANES_NUMBER(pNUM_LANES)
  ) dut_rtl (
      .clk(clk_l),
      .ui_clk(clk_mb_f),
      .rst(i_reset),

      // RDI
      .lp_data (rdi_intf.lp_data),
      .lp_valid(rdi_intf.lp_valid),
      .lp_irdy (rdi_intf.lp_irdy),
      .pl_trdy (rdi_intf.pl_trdy),

      // LTSM
      .tx_encoding(ltsm_intf.tx_encoding),
      .lane_map(ltsm_intf.lane_map),
      .pll_stable(ltsm_intf.pll_stable),
      .supply_stable(ltsm_intf.supply_stable),
      .tx_done(ltsm_intf.tx_done),

      // TX2LINK
      .tx_data (tx2link_intf.tx_data),
      .tx_clkp (tx2link_intf.tx_clkp),
      .tx_clkn (tx2link_intf.tx_clkn),
      .tx_valid(tx2link_intf.tx_valid),
      .tx_track(tx2link_intf.tx_track)
  );

  rx_path dut (
      // Clocks & resets
      .i_clk_l(clk_l),
      .i_clk_p(rp_rmblink_bfm_inst.i_clk_p),
      .i_clk_n(rp_rmblink_bfm_inst.i_clk_n),
      .i_hclk (clk_mb_h),
      .i_dclk (clk_mb_f),
      .i_track(rp_rmblink_bfm_inst.i_track),
      .i_reset(i_reset),

      // Data inputs
      .i_lanes   (rp_rmblink_bfm_inst.i_data),
      .i_valid   (rp_rmblink_bfm_inst.i_valid),
      .i_halfrate(rp_ltsmc_bfm_inst.i_half_rate),

      // Configuration
      .i_rx_encoding    (rp_ltsmc_bfm_inst.i_rx_encoding),
      .i_lane_map_code  (rp_ltsmc_bfm_inst.i_lane_map_code),
      .i_error_threshold(rp_ltsmc_bfm_inst.i_error_threshold),

      // Outputs
      .o_pl_data        (rp_rdi_bfm_inst.pl_data),
      .o_pl_valid       (rp_rdi_bfm_inst.pl_valid),
      .o_rx_done        (rp_ltsmc_bfm_inst.o_rx_done),
      .o_rx_data_results(rp_ltsmc_bfm_inst.o_rx_data_results),
      .o_rx_error       (LTSM_controllers_vif.i_rx_error),
      .o_clk_results    (rp_ltsmc_bfm_inst.o_clk_result),
      .o_valid_results  (rp_ltsmc_bfm_inst.o_valid_result)
  );

endmodule
