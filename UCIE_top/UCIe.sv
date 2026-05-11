module UCIe_phy #(
    parameter int pNUM_LANES  = 16,
    parameter int pDATA_RDI_WIDTH   = 2048
)(
    input                       i_clk_32, // connected
    input                       i_clk_24, // connected
    input                       i_clk_16, // connected
    input                       i_clk_12, // connected
    input                       i_clk_8, // connected
    input                       i_clk_4, // connected
    input                       i_clk_sb_800_m, // connected
    input                       i_clk_sb_100_m, // connected
    input                       i_reset, // connected
    input                       i_pll_stable, // connected
    input                       i_supply_stable, // connected
    input                       i_clk_p,
    input                       i_clk_n,
    input                       i_track,
    input                       i_valid,
    input  [pNUM_LANES-1:0]     i_data_in,
    input                       i_rx_sb_clk, // connected
    input                       i_rx_sb_data, // connected
    input  [3:0]                i_lp_state_req,   // connected   
    input                       i_lp_linkerror,   // connected  
    input                       i_lp_stallack,     // connected 
    input                       i_lp_clk_ack,    // connected
    input                       i_lp_irdy,
    input                       i_lp_valid,
    input [pDATA_RDI_WIDTH-1:0] i_lp_data,       
    input                       i_lp_wake_req,  // connected
    output  [3:0]               o_pl_state_sts,   // connected   
    output                      o_pl_inband_pres,    // connected
    output                      o_pl_error,          // connected
    output                      o_pl_cerror,         // connected
    output                      o_pl_nferror,        // connected
    output                      o_pl_trainerror,     // connected
    output                      o_pl_phyinrecenter,  // connected
    output                      o_pl_stallreq,       // connected
    output                      o_pl_max_speedmode,  // connected
    output  [2:0]               o_pl_speedmode,       // connected      
    output  [2:0]               o_pl_lnk_cfg,        // connected
    output                      o_pl_clk_req,       // connected 
    output                      o_pl_wake_ack,     // connected
    output                      o_pl_trdy,
    output                      o_tx_sb_data, // connected
    output                      o_tx_sb_clk, // connected
    output [pDATA_RDI_WIDTH-1:0]o_pl_data,
    output [pNUM_LANES-1:0]     o_data_out,
    output                      o_clk_p,
    output                      o_clk_n,
    output                      o_track,
    output                      o_valid       
);
    wire clk_mb_f; // full rate clock used in mainband
    wire clk_mb_h; // half rate clock used in mainband
    wire clk_l;     // Logical clock used in mainband & LTSM
    logic sb_ready;
    PLL_model PLL(
        .i_sel(LTSM_controllers_vif.i_speedreg),
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
    );
    // LTSM interfaces
   ltsm_rdi_if ltsm_rdi_if_inst(.clk(clk_l));
   TX_FSM_SB tx_fsm_sb_if(clk_l);
   RX_FSM_SB rx_fsm_sb_if(clk_l);
   LTSM_controllers_if LTSM_controllers_vif(clk_l);

   // side band interfaces

   sb_reset_intf reset_intf(
     .clk(i_clk_sb_100_m)
    ,.reset(i_reset)
  );

  // LTSM control interface
  sb_ltsm_ctrl_bfm ltsm_ctrl_bfm(
     .clk(i_clk_sb_100_m)
    ,.reset(i_reset)
    ,.o_sb_ready(sb_ready)
  );
  
  // TX path interface
  sb_tx_bfm tx_bfm(
     .clk(i_clk_sb_100_m)
    ,.reset(i_reset)
    ,.o_sb_ready(sb_ready)
  );
  
  // RX path interface
  sb_rx_bfm    rx_bfm(
     .clk(i_clk_sb_100_m)
    ,.reset(i_reset)
    ,.o_sb_ready(sb_ready)
  );
  
  // D2D Adapter interface (RDI)
  sb_rdi_bfm        rdi_bfm(
     .clk(i_clk_sb_100_m)
    ,.reset(i_reset)
    ,.o_sb_ready(sb_ready)
  );
  
  // Physical link interface
  sb_phylink_bfm   phylink_bfm(
     .clk(i_clk_sb_100_m)
    ,.clk_800MHz(i_clk_sb_100_m)
    ,.reset(i_reset)
    ,.o_sb_ready(sb_ready)
  );

    // interface connections

    assign phylink_bfm.tms     = ltsm_ctrl_bfm.tms;
    assign phylink_bfm.timeout = ltsm_ctrl_bfm.timeout;
    assign phylink_bfm.start   = ltsm_ctrl_bfm.i_sb_init_start;


    assign LTSM_controllers_vif.i_clk = clk_l;
    assign ltsm_rdi_if_inst.i_reset=LTSM_controllers_vif.i_reset;
    assign tx_fsm_sb_if.i_reset=LTSM_controllers_vif.i_reset;
    assign rx_fsm_sb_if.i_reset=LTSM_controllers_vif.i_reset;

    assign LTSM_controllers_vif.i_pll_stable = i_pll_stable;
    assign LTSM_controllers_vif.i_supply_stable = i_supply_stable;
    assign LTSM_controllers_vif.i_reset = i_reset;

    assign ltsm_rdi_if_inst.i_lp_state_req = i_lp_state_req;
    assign ltsm_rdi_if_inst.i_lp_linkerror = i_lp_linkerror;
    assign ltsm_rdi_if_inst.i_lp_stallack = i_lp_stallack;
    assign ltsm_rdi_if_inst.i_lp_clk_ack = i_lp_clk_ack;
    assign ltsm_rdi_if_inst.i_lp_wake_req = i_lp_wake_req;
    assign o_pl_state_sts = ltsm_rdi_if_inst.o_pl_state_sts;
    assign o_pl_inband_pres = ltsm_rdi_if_inst.o_pl_inband_pres;
    assign o_pl_error = ltsm_rdi_if_inst.o_pl_error;
    assign o_pl_cerror = ltsm_rdi_if_inst.o_pl_cerror;
    assign o_pl_nferror = ltsm_rdi_if_inst.o_pl_nferror;
    assign o_pl_trainerror = ltsm_rdi_if_inst.o_pl_trainerror;
    assign o_pl_phyinrecenter = ltsm_rdi_if_inst.o_pl_phyinrecenter;
    assign o_pl_stallreq = ltsm_rdi_if_inst.o_pl_stallreq;
    assign o_pl_max_speedmode = ltsm_rdi_if_inst.o_pl_max_speedmode;
    assign o_pl_speedmode = ltsm_rdi_if_inst.o_pl_speedmode;
    assign o_pl_lnk_cfg = ltsm_rdi_if_inst.o_pl_lnk_cfg;
    assign o_pl_clk_req = ltsm_rdi_if_inst.o_pl_clk_req;
    assign o_pl_wake_ack = ltsm_rdi_if_inst.o_pl_wake_ack;

   

   assign LTSM_controllers_vif.o_rx_encoding = rx_fsm_sb_if.o_rx_encoding;
   assign LTSM_controllers_vif.o_tx_encoding = tx_fsm_sb_if.o_tx_encoding;

    assign tx_bfm.i_tx_encoding = tx_fsm_sb_if.o_tx_encoding;
    assign tx_bfm.i_tx_data = tx_fsm_sb_if.o_tx_data;
    assign tx_bfm.i_tx_info = tx_fsm_sb_if.o_tx_info;
    assign tx_bfm.i_sb_tx_req = tx_fsm_sb_if.o_tx_sb_req;
    assign tx_bfm.i_sb_tx_rsp = tx_fsm_sb_if.o_tx_sb_rsp;

    assign tx_fsm_sb_if.i_sb_tx_done = tx_bfm.o_sb_tx_done;

    assign rx_bfm.i_rx_encoding = rx_fsm_sb_if.o_rx_encoding;
    assign rx_bfm.i_rx_data = rx_fsm_sb_if.o_rx_data;
    assign rx_bfm.i_rx_info = rx_fsm_sb_if.o_rx_info;
    assign rx_bfm.i_sb_rx_req = rx_fsm_sb_if.o_rx_sb_req;
    assign rx_bfm.i_sb_rx_rsp = rx_fsm_sb_if.o_rx_sb_rsp;

    assign rx_fsm_sb_if.i_sb_rx_done = rx_bfm.o_sb_rx_done;

    assign ltsm_ctrl_bfm.i_sb_init_start = LTSM_controllers_vif.o_sb_init_start;
    assign sb_ready = LTSM_controllers_vif.i_sb_ready;

    assign o_tx_sb_data = phylink_bfm.o_tx_sb_data;
    assign o_tx_sb_clk = phylink_bfm.o_tx_sb_clk;
    assign phylink_bfm.i_rx_sb_data = i_rx_sb_data;
    assign phylink_bfm.i_rx_sb_clk = i_rx_sb_clk;

    valid_decoder decoder_rx
    (
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
        .o_done(rx_fsm_sb_if.i_sb_rx_done)
    );

    valid_decoder decoder_tx
    (
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
        .o_done(tx_fsm_sb_if.i_sb_tx_done)
    );

   // top instantiation of all blocks
   ucie_LTSM LTSM (.i_clk(clk_l),
             .i_tx_decoding         (tx_fsm_sb_if.i_tx_decoding),
             .o_tx_encoding         (tx_fsm_sb_if.o_tx_encoding),
             .i_tx_data             (tx_fsm_sb_if.i_tx_data),
             .o_tx_data             (tx_fsm_sb_if.o_tx_data),
             .i_sb_tx_req           (tx_fsm_sb_if.i_sb_tx_req),
             .i_sb_tx_rsp           (tx_fsm_sb_if.i_sb_tx_rsp),
             .i_sb_tx_done          (tx_fsm_sb_if.i_sb_tx_done),
             .o_tx_sb_req           (tx_fsm_sb_if.o_tx_sb_req),
             .o_tx_sb_rsp           (tx_fsm_sb_if.o_tx_sb_rsp),
             .o_tx_sb_done          (tx_fsm_sb_if.o_tx_sb_done),
             .i_rx_decoding         (rx_fsm_sb_if.i_rx_decoding),
             .o_rx_encoding         (rx_fsm_sb_if.o_rx_encoding),
             .i_rx_data             (rx_fsm_sb_if.i_rx_data),
             .o_rx_data             (rx_fsm_sb_if.o_rx_data),
             .i_tx_info             (tx_fsm_sb_if.i_tx_info),
             .i_rx_info             (rx_fsm_sb_if.i_rx_info),
             .o_tx_info             (tx_fsm_sb_if.o_tx_info),
             .o_rx_info             (rx_fsm_sb_if.o_rx_info),
             .i_sb_rx_req           (rx_fsm_sb_if.i_sb_rx_req),
             .i_sb_rx_rsp           (rx_fsm_sb_if.i_sb_rx_rsp),
             .i_sb_rx_done          (rx_fsm_sb_if.i_sb_rx_done),
             .o_rx_sb_req           (rx_fsm_sb_if.o_rx_sb_req),
             .o_rx_sb_rsp           (rx_fsm_sb_if.o_rx_sb_rsp),
             .o_rx_sb_done          (rx_fsm_sb_if.o_rx_sb_done),
             .i_supply_stable   (LTSM_controllers_vif.i_supply_stable),
             .i_pll_stable      (LTSM_controllers_vif.i_pll_stable),
             .i_rx_error        (LTSM_controllers_vif.i_rx_error),
             .i_rx_done         (LTSM_controllers_vif.i_rx_done),
             .i_tx_done         (LTSM_controllers_vif.i_tx_done),
             .i_rx_valid_results       (LTSM_controllers_vif.i_rx_valid_results),
             .i_rx_data_results (LTSM_controllers_vif.i_rx_data_results),
             .i_rx_clk_results     (LTSM_controllers_vif.i_clk_results), // 1st iissue
             .o_sb_init_start    (LTSM_controllers_vif.o_sbinit_start),
             .i_sb_ready        (LTSM_controllers_vif.i_sb_ready),
             //.o_t1_ms           (LTSM_controllers_vif.o_t1_ms),
             .i_reset           (LTSM_controllers_vif.i_reset),
             //.i_par_check_done  (LTSM_controllers_vif.i_par_check_done), // needs to be fixed in the verification model and sequences 
             .i_sb_cur_msg_done (LTSM_controllers_vif.i_sb_cur_msg_done),
             .o_lane_map_tx     (LTSM_controllers_vif.o_lane_map_tx),
             .o_lane_map_rx     (LTSM_controllers_vif.o_lane_map_rx),
             .o_pl_state_sts    (ltsm_rdi_if_inst.o_pl_state_sts),
             .o_pl_inband_pres  (ltsm_rdi_if_inst.o_pl_inband_pres),
             .o_pl_phyinrecenter(ltsm_rdi_if_inst.o_pl_phyinrecenter),
             .o_pl_stallreq     (ltsm_rdi_if_inst.o_pl_stallreq),
             .o_pl_clk_req      (ltsm_rdi_if_inst.o_pl_clk_req),
             .o_pl_wake_ack     (ltsm_rdi_if_inst.o_pl_wake_ack),
             .o_pl_lnk_cfg      (ltsm_rdi_if_inst.o_pl_lnk_cfg),
             .o_pl_speedmode    (ltsm_rdi_if_inst.o_pl_speedmode),
             .o_pl_max_speedmode(ltsm_rdi_if_inst.o_pl_max_speedmode),
             .o_pl_error        (ltsm_rdi_if_inst.o_pl_error),
             .o_pl_trainerror   (ltsm_rdi_if_inst.o_pl_trainerror),
             .o_pl_cerror       (ltsm_rdi_if_inst.o_pl_cerror),
             .o_pl_nferror      (ltsm_rdi_if_inst.o_pl_nferror),
             .i_lp_state_req    (ltsm_rdi_if_inst.i_lp_state_req),
             .i_lp_stallack     (ltsm_rdi_if_inst.i_lp_stallack),
             .i_lp_clk_ack      (ltsm_rdi_if_inst.i_lp_clk_ack),
             .i_lp_wake_req     (ltsm_rdi_if_inst.i_lp_wake_req),
             .i_lp_linkerror    (ltsm_rdi_if_inst.i_lp_linkerror),
             .i_speedreg                            (LTSM_controllers_vif.i_speedreg),
             .o_speedreg                            (LTSM_controllers_vif.o_speedreg),
             //.i_local_cap                           (LTSM_controllers_vif.i_local_cap),
             .i_Runtime_Link_Test_status_register   (LTSM_controllers_vif.i_Runtime_Link_Test_status_register),
             .o_Runtime_Link_Test_status_register   (LTSM_controllers_vif.o_Runtime_Link_Test_status_register),
             .i_Runtime_Link_Test_Control_register   (LTSM_controllers_vif.i_Runtime_Link_Test_Control_register),
             .o_Runtime_Link_Test_Control_register   (LTSM_controllers_vif.o_Runtime_Link_Test_Control_register).
             .o_timer1ms (ltsm_ctrl_bfm.i_timer_1ms)
             );

    ucie_sb_top #(
            .pFIFO_DEPTH(TX_FIFO_SIZE)
    )
    sideband
    (
            // Clock and reset
            .i_clk                 (i_clk_sb_100_m)
            ,.i_reset              (reset_wire)
            ,.i_800MHz_clk         (clk_800MHz)

            // TX path signals
            ,.i_tx_sb_req          (tx_bfm.i_tx_sb_req)
            ,.i_tx_sb_rsp          (tx_bfm.i_tx_sb_rsp)
            ,.i_tx_sb_done         (tx_bfm.i_tx_sb_done)
            ,.i_tx_encoding        (tx_bfm.i_tx_encoding)
            ,.i_tx_data            (tx_bfm.i_tx_data)
            ,.i_tx_info            (tx_bfm.i_tx_info)
            ,.o_sb_tx_req          (tx_bfm.o_sb_tx_req)
            ,.o_sb_tx_rsp          (tx_bfm.o_sb_tx_rsp)
            ,.o_sb_tx_done         (tx_bfm.o_sb_tx_done)
            ,.o_tx_decoding        (tx_bfm.o_tx_decoding)
            ,.o_tx_data            (tx_bfm.o_tx_data)
            ,.o_tx_info            (tx_bfm.o_tx_info)
            ,.o_tx_valid           (tx_bfm.o_tx_valid)

            // RX path signals
            ,.i_rx_sb_req          (rx_bfm.i_rx_sb_req)
            ,.i_rx_sb_rsp          (rx_bfm.i_rx_sb_rsp)
            ,.i_rx_sb_done         (rx_bfm.i_rx_sb_done)
            ,.i_rx_encoding        (rx_bfm.i_rx_encoding)
            ,.i_rx_data            (rx_bfm.i_rx_data)
            ,.i_rx_info            (rx_bfm.i_rx_info)
            ,.o_sb_rx_req          (rx_bfm.o_sb_rx_req)
            ,.o_sb_rx_rsp          (rx_bfm.o_sb_rx_rsp)
            ,.o_sb_rx_done         (rx_bfm.o_sb_rx_done)
            ,.o_rx_decoding        (rx_bfm.o_rx_decoding)
            ,.o_rx_data            (rx_bfm.o_rx_data)
            ,.o_rx_info            (rx_bfm.o_rx_info)
            ,.o_rx_valid           (rx_bfm.o_rx_valid)

            // LTSM control signals
            ,.i_sb_init_start      (ltsm_ctrl_bfm.i_sb_init_start)
            ,.i_timer_1ms          (ltsm_ctrl_bfm.i_timer_1ms)
            ,.o_sb_ready           (sb_ready)

            // Physical link interface
            ,.i_rx_sb_data         (phylink_bfm.i_rx_sb_data)
            ,.i_rx_sb_clk          (phylink_bfm.i_rx_sb_clk)
            ,.o_tx_sb_data         (phylink_bfm.o_tx_sb_data)
            ,.o_tx_sb_clk          (phylink_bfm.o_tx_sb_clk)
    );
endmodule