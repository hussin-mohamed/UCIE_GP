`ifdef SIM
`timescale 1ns/1ps
`endif
 
// =============================================================================
//  Module  : ucie_ltsm_active_fsm
//
//  Purpose : Top-level hierarchical FSM for the "Active" phase of the UCIe
//            link lifecycle.  This FSM runs after ucie_ltsm_init_fsm has
//            asserted o_init_train_en (= i_train_active_en here).
//
//  State sequence:
//    IDLE        — waits for i_train_active_en to be asserted
//    LINKINIT    — RDI bring-up handshake (clk HS, wake HS, sideband msg HS)
//    ACTIVE      — normal link operation; monitors lp_state_req / lp_linkerror
//    ACTIVE_PMNAK— same as ACTIVE but L1 requests are ignored (came from L1
//                  PMNAK path); entered when L1 module returns with pmnak flag
//
//  Placeholder arcs (wired for future sub-module integration):
//    ACTIVE      → L1      : i_done_active_l1 (L1 module, coded separately)
//    ACTIVE      → RETRAIN : i_done_active_retrain (Retrain module, separately)
//    ACTIVE_PMNAK→ RETRAIN : (same; L1 arc silently blocked in active module)
//    L1          → ACTIVE       : i_l1_done
//    L1          → ACTIVE_PMNAK : i_l1_done_pmnak
//    RETRAIN     → LINKINIT     : i_retrain_done (or ACTIVE on success)
//
//  Done-signal latching (same pattern as ucie_ltsm_init_fsm):
//    Each state has independent TX and RX done latches.  Sub-FSMs assert done
//    for one cycle; the latch holds it until both TX and RX are done, then the
//    main state advances.  Latches clear on state exit.
//
//  Output mux:
//    Combinational mux selects active sub-FSM sideband outputs based on
//    current_state.  RDI physical outputs (pl_clk_req, pl_inband_pres,
//    pl_wake_ack) are driven by ucie_ltsm_linkinit_tx during LINKINIT and
//    held at their post-LINKINIT values thereafter.
// =============================================================================

module ucie_ltsm_active_fsm #(
    parameter DECODING_WIDTH = 9,    // Width of encoding/decoding signals
    parameter INFO_WIDTH = 16       // Width of info/control bus
) (
    input  logic        i_clk,
    input  logic        i_reset,

    // Entry trigger from ucie_ltsm_init_fsm
    input  logic        i_train_active_en,
    input  logic        phyretrain_linkspeed_transition,
    input  logic [INFO_WIDTH-1:0] i_tx_info,
    input  logic [INFO_WIDTH-1:0] i_rx_info,

    // RDI interface — from Adapter
    input  logic        valid_error,
    input  logic        i_lp_clk_ack,
    input  logic        i_lp_wake_req,
    input  logic [3:0]  i_lp_state_req,
    input  logic        i_lp_linkerror,
    input  logic        i_lp_stallack,

    // TX sideband inputs
    input  logic [8:0]  i_tx_decoding,
    input  logic        i_sb_tx_req,
    input  logic        i_sb_tx_rsp,
    input  logic        i_sb_tx_done,

    // RX sideband inputs
    input  logic [8:0]  i_rx_decoding,
    input  logic        i_sb_rx_req,
    input  logic        i_sb_rx_rsp,
    input  logic        i_sb_rx_done,
    input [2:0] Lane_map_code,

    // Shared 8ms timeout
    input  logic        o_timer_8ms,

    // L1 1us wait timer
    input  logic        i_timer_1us,                                   // [NEW] fed to RX L1 sub-module
    input  logic        i_timer_2us,                                   // [NEW] fed to RX L1 sub-module

    input [36:0] i_Runtime_Link_Test_Control_register,
    input i_Runtime_Link_Test_status_register,
    input [DECODING_WIDTH-1:0] encoding_rsp_sent,      // Encoding value when response sent
    input [DECODING_WIDTH-1:0] encoding_rsp_received,  // Encoding value when response received
    input rsp_received,               // Response sent flag
    input rsp_sent,                   // Response sent flag

    // TX sideband outputs (muxed)
    output logic [8:0]  o_tx_encoding,
    output logic        o_tx_sb_req,
    output logic        o_tx_sb_rsp,
    output logic        o_tx_sb_done,

    // RX sideband outputs (muxed)
    output logic [8:0]  o_rx_encoding,
    output logic        o_rx_sb_req,
    output logic        o_rx_sb_rsp,
    output logic        o_rx_sb_done,

    output  logic [INFO_WIDTH-1:0] o_tx_info,
    output  logic [INFO_WIDTH-1:0] o_rx_info,


    // RDI outputs — to Adapter
    output logic        o_pl_clk_req,
    output logic        o_pl_inband_pres,
    output logic        o_pl_wake_ack,
    output logic [3:0]  o_pl_state_sts,
    output logic o_pl_stallreq,

    output logic speed_idle_state_enable,
    output logic repair_state_enable,
    output logic tx_self_cal_state_enable,

    // Transition done flags (forwarded from ucie_ltsm_active for external use)
    output logic        o_done_active_linkreset,
    output logic        o_done_active_linkerror,

    // Debug
    output logic [3:0]  o_current_state,
    output logic [36:0] wait_1us_en,
    
    output logic [36:0] o_Runtime_Link_Test_Control_register,
    output logic o_Runtime_Link_Test_status_register
);

    // =========================================================================
    // State encoding
    // =========================================================================
    localparam logic [3:0] IDLE         = 4'b1111; // waiting for i_train_active_en
    localparam logic [3:0] LINKINIT     = 4'b0000;
    localparam logic [3:0] ACTIVE       = 4'b0001;
    localparam logic [3:0] ACTIVE_PMNAK = 4'b0010;
    localparam logic [3:0] L1           = 4'b0011;
    localparam logic [3:0] RETRAIN      = 4'b0100;

    // pl_state_sts encodings (see ucie_ltsm_active for full table)
    localparam logic [3:0] PL_STS_RESET = 4'b0000;

    // =========================================================================
    // State register
    // =========================================================================
    logic [3:0] current_state;
    logic [3:0] next_state;

    always_ff @(posedge i_clk or posedge i_reset) begin
        if (i_reset) current_state <= IDLE;
        else if (!(i_train_active_en || phyretrain_linkspeed_transition)) current_state <= IDLE;
        else current_state <= next_state;
    end

    assign o_current_state = current_state;

    // =========================================================================
    // Done latches — LINKINIT TX and RX
    // (same pattern as ucie_ltsm_init_fsm)
    // =========================================================================
    logic done_tx_linkinit, done_rx_linkinit;
    logic raw_done_tx_linkinit, raw_done_rx_linkinit;

    always_ff @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            done_tx_linkinit <= 1'b0;
            done_rx_linkinit <= 1'b0;
        end else if (!(i_train_active_en || phyretrain_linkspeed_transition)) begin
            done_tx_linkinit <= 1'b0;
            done_rx_linkinit <= 1'b0;
        end else begin
            if (current_state != LINKINIT) done_tx_linkinit <= 1'b0;
            else if (raw_done_tx_linkinit) done_tx_linkinit <= 1'b1;

            if (current_state != LINKINIT) done_rx_linkinit <= 1'b0;
            else if (raw_done_rx_linkinit) done_rx_linkinit <= 1'b1;
        end
    end

    // =========================================================================
    // Done latches — L1 TX and RX active_state_enable              [NEW]
    // Both must assert active_state_enable before FSM exits L1 →
    // ACTIVE_PMNAK.  Same latch pattern as LINKINIT above.
    // =========================================================================
    logic done_tx_l1_active, done_rx_l1_active;
    logic l1_tx_active_en, l1_rx_active_en;
    logic l1_tx_speed_idle_en, l1_rx_speed_idle_en;

    always_ff @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            done_tx_l1_active <= 1'b0;
            done_rx_l1_active <= 1'b0;
        end else if (!(i_train_active_en || phyretrain_linkspeed_transition)) begin
            done_tx_l1_active <= 1'b0;
            done_rx_l1_active <= 1'b0;
        end else begin
            if (current_state != L1) done_tx_l1_active <= 1'b0;
            else if (l1_tx_active_en) done_tx_l1_active <= 1'b1;

            if (current_state != L1) done_rx_l1_active <= 1'b0;
            else if (l1_rx_active_en) done_rx_l1_active <= 1'b1;
        end
    end

    // =========================================================================
    // Next-state logic
    // =========================================================================
    logic raw_done_retrain, raw_done_l1, raw_done_linkreset, raw_done_linkerror;

    always_comb begin

        case (current_state)

            IDLE: begin
                // Wait for init FSM to signal that link training is complete
                if (i_train_active_en) next_state = LINKINIT;
            end

            LINKINIT: begin
                // Advance to ACTIVE once both TX and RX have completed their
                // bring-up handshake (latch ensures one-at-a-time completion is OK)
                if (done_tx_linkinit && done_rx_linkinit)
                    next_state = ACTIVE;
            end

            ACTIVE: begin
                // Priority: LinkError > L1 > Retrain > LinkReset
                if      (raw_done_linkerror)  next_state = IDLE;
                else if (raw_done_l1)         next_state = L1;
                else if (raw_done_retrain || phyretrain_linkspeed_transition)    next_state = RETRAIN;
                else if (raw_done_linkreset)  next_state = LINKINIT;
            end

            ACTIVE_PMNAK: begin
                // Same as ACTIVE but L1 is blocked (active module won't fire done_l1)
                if      (raw_done_linkerror) next_state = ACTIVE_PMNAK;
                else if (raw_done_retrain || phyretrain_linkspeed_transition)   next_state = RETRAIN;
                else if (raw_done_linkreset) next_state = LINKINIT;
            end

            RETRAIN: begin
                if (speed_idle_state_enable || repair_state_enable || tx_self_cal_state_enable) begin
                    next_state = IDLE;
                end
            end

            // ------------------------------------------------------------------
            // L1 — exits to ACTIVE_PMNAK once both TX and RX assert
            // active_state_enable (PMNAK response path), or to IDLE if either
            // side requests speed change (speed_idle_state_enable).
            // ------------------------------------------------------------------
            L1: begin
                if      (l1_tx_speed_idle_en || l1_rx_speed_idle_en)  next_state = IDLE;
                else if (done_tx_l1_active   && done_rx_l1_active)    next_state = ACTIVE_PMNAK;
            end

            default: next_state = IDLE;
        endcase
    end

    // =========================================================================
    // Sub-module: LINKINIT TX
    // =========================================================================
    logic [8:0] linkinit_tx_encoding;
    logic       linkinit_tx_sb_req;
    logic       linkinit_tx_sb_rsp;
    logic       linkinit_tx_sb_done;
    logic       linkinit_tx_pl_clk_req;
    logic       linkinit_tx_pl_inband_pres;
    logic       linkinit_tx_pl_wake_ack;
    logic       linkinit_tx_train_error;

    ucie_ltsm_linkinit_tx u_linkinit_tx (
        .i_clk             (i_clk),
        .i_reset           (i_reset),
        .i_lp_clk_ack      (i_lp_clk_ack),
        .i_lp_wake_req     (i_lp_wake_req),
        .i_lp_state_req    (i_lp_state_req),
        .i_tx_decoding     (i_tx_decoding),
        .i_sb_tx_req       (i_sb_tx_req),
        .i_sb_tx_rsp       (i_sb_tx_rsp),
        .i_sb_tx_done      (i_sb_tx_done),
        .i_current_state   (current_state),
        .o_timer_8ms       (o_timer_8ms),
        .o_tx_encoding     (linkinit_tx_encoding),
        .o_tx_sb_req       (linkinit_tx_sb_req),
        .o_tx_sb_rsp       (linkinit_tx_sb_rsp),
        .o_tx_sb_done      (linkinit_tx_sb_done),
        .o_pl_clk_req      (linkinit_tx_pl_clk_req),
        .o_pl_inband_pres  (linkinit_tx_pl_inband_pres),
        .o_pl_wake_ack     (linkinit_tx_pl_wake_ack),
        .o_train_error     (linkinit_tx_train_error),
        .o_done_linkinit_tx(raw_done_tx_linkinit)
    );

    // =========================================================================
    // Sub-module: LINKINIT RX
    // =========================================================================
    logic [8:0] linkinit_rx_encoding;
    logic       linkinit_rx_sb_req;
    logic       linkinit_rx_sb_rsp;
    logic       linkinit_rx_sb_done;
    logic       linkinit_rx_train_error;

    logic [8:0] active_tx_encoding;
    logic [8:0] active_rx_encoding;

    logic [8:0] retrain_tx_encoding;
    logic [8:0] retrain_rx_encoding;

    logic       retrain_tx_sb_req;
    logic       retrain_tx_sb_rsp;
    logic       retrain_tx_sb_done;
    logic       retrain_tx_train_error;
    logic [INFO_WIDTH-1 : 0]       retrain_tx_info;

    logic       retrain_rx_sb_req;
    logic       retrain_rx_sb_rsp;
    logic       retrain_rx_sb_done;
    logic       retrain_rx_train_error;
    logic [INFO_WIDTH-1 : 0]       retrain_rx_info;

    logic [3:0] retrain_o_pl_state_sts;    // [DECLARED] was used in mux but undeclared
    logic       retrain_o_pl_stallreq;     // [DECLARED] was used in mux but undeclared
    logic       retrain_speed_idle_en;     // [NEW] intermediate; OR'd into speed_idle_state_enable

    ucie_ltsm_linkinit_rx u_linkinit_rx (
        .i_clk             (i_clk),
        .i_reset           (i_reset),
        .i_lp_clk_ack      (i_lp_clk_ack),
        .i_lp_wake_req     (i_lp_wake_req),
        .i_lp_state_req    (i_lp_state_req),
        .i_rx_decoding     (i_rx_decoding),
        .i_sb_rx_req       (i_sb_rx_req),
        .i_sb_rx_rsp       (i_sb_rx_rsp),
        .i_sb_rx_done      (i_sb_rx_done),
        .i_current_state   (current_state),
        .o_timer_8ms       (o_timer_8ms),
        .o_rx_encoding     (linkinit_rx_encoding),
        .o_rx_sb_req       (linkinit_rx_sb_req),
        .o_rx_sb_rsp       (linkinit_rx_sb_rsp),
        .o_rx_sb_done      (linkinit_rx_sb_done),
        .o_train_error     (linkinit_rx_train_error),
        .o_done_linkinit_rx(raw_done_rx_linkinit)
    );

    // =========================================================================
    // Sub-module: ACTIVE (handles both ACTIVE and ACTIVE_PMNAK)
    // =========================================================================
    logic [3:0] active_pl_state_sts;
    logic       active_pl_inband_pres;

    ucie_ltsm_active u_active (
        .i_clk                   (i_clk),
        .i_reset                 (i_reset),
        .i_lp_state_req          (i_lp_state_req),
        .i_lp_linkerror          (i_lp_linkerror),
        .valid_error             (valid_error),
        .i_sb_rx_req             (i_sb_rx_req),
        .o_timer_2us             (i_timer_2us),
        .i_rx_decoding           (i_rx_decoding),
        .i_current_state         (current_state),
        .o_pl_state_sts          (active_pl_state_sts),
        .o_pl_inband_pres        (active_pl_inband_pres),
        .o_tx_sb_encoding        (active_tx_encoding),
        .o_rx_sb_encoding        (active_rx_encoding),
        .o_done_active_retrain   (raw_done_retrain),
        .o_done_active_l1        (raw_done_l1),
        .o_done_active_linkreset (raw_done_linkreset),
        .o_done_active_linkerror (raw_done_linkerror)
    );

    // =========================================================================
    // Sub-module: L1 TX                                        
    // Enabled by raw_done_l1 from the active module.
    // L1_rx_rsp_sent is wired to the RX L1 sideband response output so TX
    // knows when RX has completed its own handshake response.
    // =========================================================================
    logic [8:0] l1_tx_encoding;
    logic [3:0] l1_tx_pl_state_sts;
    logic       l1_tx_sb_req, l1_tx_sb_rsp, l1_tx_sb_done;
    logic [8:0] l1_rx_encoding;
    logic [3:0] l1_rx_pl_state_sts;
    logic       l1_rx_sb_req, l1_rx_sb_rsp, l1_rx_sb_done;

    ucie_LTSM_TX_L1 #(
        .DECODING_WIDTH(9)
    ) u_l1_tx (
        .i_clk                   (i_clk),
        .i_reset                 (i_reset),
        .i_tx_decoding           (i_tx_decoding),
        .i_lp_state_req          (i_lp_state_req),
        .i_sb_tx_req             (i_sb_tx_req),
        .i_sb_tx_rsp             (i_sb_tx_rsp),
        .i_sb_tx_done            (i_sb_tx_done),
        .state_enable            (raw_done_l1),
        .i_rsp_sent                (rsp_sent),
        .i_rsp_received            (rsp_received),
        .i_encoding_rsp_received   (encoding_rsp_received),
        .i_encoding_rsp_sent       (encoding_rsp_sent),
        .o_tx_encoding           (l1_tx_encoding),
        .o_pl_state_sts          (l1_tx_pl_state_sts),
        .o_tx_sb_req             (l1_tx_sb_req),
        .o_tx_sb_rsp             (l1_tx_sb_rsp),
        .o_tx_sb_done            (l1_tx_sb_done),
        .speed_idle_state_enable (l1_tx_speed_idle_en),
        .pmnak_enable     (l1_tx_active_en)
    );

    // =========================================================================
    // Sub-module: L1 RX                                         
    // Enabled by raw_done_l1 from the active module.
    // wait_1us is driven from the top-level 1us timer input.
    // =========================================================================
    ucie_LTSM_rx_L1 #(
        .DECODING_WIDTH(9)
    ) u_l1_rx (
        .i_clk                   (i_clk),
        .i_reset                 (i_reset),
        .i_rx_decoding           (i_rx_decoding),
        .i_lp_state_req          (i_lp_state_req),
        .i_sb_rx_req             (i_sb_rx_req),
        .i_sb_rx_rsp             (i_sb_rx_rsp),
        .i_sb_rx_done            (i_sb_rx_done),
        .state_enable            (raw_done_l1),
        .i_timer_1us             (i_timer_1us),
        .o_rx_encoding           (l1_rx_encoding),
        .o_pl_state_sts          (l1_rx_pl_state_sts),
        .o_rx_sb_req             (l1_rx_sb_req),
        .o_rx_sb_rsp             (l1_rx_sb_rsp),
        .o_rx_sb_done            (l1_rx_sb_done),
        .speed_idle_state_enable (l1_rx_speed_idle_en),
        .wait_1us_en              (wait_1us_en),
        .active_state_enable     (l1_rx_active_en)
    );

    ucie_LTSM_TX_phyretrain #(
        .DECODING_WIDTH(9),    // Width of encoding/decoding signals
        .INFO_WIDTH(16)       // Width of info/control bus
    ) ucie_LTSM_TX_phyretrain_inst (
        .i_clk(i_clk),
        .i_reset(i_reset),
        .i_tx_decoding(i_tx_decoding),
        .i_tx_info(i_tx_info),
        .i_lp_stallack(i_lp_stallack),
        .i_sb_tx_req(i_sb_tx_req),
        .i_sb_tx_rsp(i_sb_tx_rsp),
        .i_sb_tx_done(i_sb_tx_done),
        .state_enable(raw_done_retrain),
        .link_speed_state_enable(phyretrain_linkspeed_transition),
        .Lane_map_code(Lane_map_code),
        .i_Runtime_Link_Test_Control_register(i_Runtime_Link_Test_Control_register),
        .i_Runtime_Link_Test_status_register(i_Runtime_Link_Test_status_register),
        .rsp_sent(rsp_sent),
        .rsp_received(rsp_received),
        .encoding_rsp_received(encoding_rsp_received),
        .encoding_rsp_sent(encoding_rsp_sent),

        .o_tx_encoding(retrain_tx_encoding),
        .o_tx_info(retrain_tx_info),
        .o_pl_state_sts(retrain_o_pl_state_sts),
        .o_pl_stallreq(retrain_o_pl_stallreq),
        .o_tx_sb_req(retrain_tx_sb_req),
        .o_tx_sb_rsp(retrain_tx_sb_rsp),
        .o_tx_sb_done(retrain_tx_sb_done),
        .o_Runtime_Link_Test_Control_register(o_Runtime_Link_Test_Control_register),
        .o_Runtime_Link_Test_status_register(o_Runtime_Link_Test_status_register)
    );

    ucie_LTSM_RX_phyretrain #(
        .DECODING_WIDTH(9),    // Width of encoding/decoding signals
        .INFO_WIDTH(16)       // Width of info/control bus
        ) ucie_LTSM_RX_phyretrain_inst (
        .i_clk(i_clk),
        .i_reset(i_reset),
        .i_rx_decoding(i_rx_decoding),
        .i_rx_info(i_rx_info),
        .i_lp_state_req(i_lp_state_req),
        .i_lp_stallack(i_lp_stallack),
        .i_sb_rx_req(i_sb_rx_req),
        .i_sb_rx_rsp(i_sb_rx_rsp),
        .i_sb_rx_done(i_sb_rx_done),
        .state_enable(raw_done_retrain),
        .link_speed_state_enable(phyretrain_linkspeed_transition),
        .Lane_map_code(Lane_map_code),
        .i_Runtime_Link_Test_Control_register(i_Runtime_Link_Test_Control_register),
        .i_Runtime_Link_Test_status_register(i_Runtime_Link_Test_status_register),
        .rsp_sent(rsp_sent),
        .rsp_received(rsp_received),
        .encoding_rsp_received(encoding_rsp_received),
        .encoding_rsp_sent(encoding_rsp_sent),

        .o_rx_encoding(retrain_rx_encoding),
        .o_rx_info(retrain_rx_info),
        .o_rx_sb_req(retrain_rx_sb_req),
        .o_rx_sb_rsp(retrain_rx_sb_rsp),
        .o_rx_sb_done(retrain_rx_sb_done),
        .speed_idle_state_enable(retrain_speed_idle_en),    // [CHANGED] intermediate
        .repair_state_enable(repair_state_enable),
        .tx_self_cal_state_enable(tx_self_cal_state_enable)
    );

    // =========================================================================
    // speed_idle_state_enable — OR of all sources                    [NEW]
    // Retrain, L1 TX, and L1 RX can each independently request speed-idle.
    // =========================================================================
    assign speed_idle_state_enable = retrain_speed_idle_en
                                   | l1_tx_speed_idle_en
                                   | l1_rx_speed_idle_en;

    // Forward active module done flags to top-level ports
    assign o_done_active_retrain   = raw_done_retrain;
    assign o_done_active_l1        = raw_done_l1;
    assign o_done_active_linkreset = raw_done_linkreset;
    assign o_done_active_linkerror = raw_done_linkerror;

    // =========================================================================
    // Output MUX — select sideband and RDI outputs based on current state
    // =========================================================================
    always_comb begin
        // Safe defaults
        o_tx_encoding    = 9'h000;
        o_tx_sb_req      = 1'b0;
        o_tx_sb_rsp      = 1'b0;
        o_tx_sb_done     = 1'b0;
        o_rx_encoding    = 9'h000;
        o_rx_sb_req      = 1'b0;
        o_rx_sb_rsp      = 1'b0;
        o_rx_sb_done     = 1'b0;
        o_pl_clk_req     = 1'b0;
        o_pl_inband_pres = 1'b0;
        o_pl_wake_ack    = 1'b0;
        o_pl_state_sts   = PL_STS_RESET;

        case (current_state)

            IDLE: begin
                // No sideband traffic; RDI signals at reset defaults
                o_pl_state_sts = PL_STS_RESET;
            end

            LINKINIT: begin
                // TX drives RDI physical outputs (single logical driver per wire)
                o_pl_clk_req     = linkinit_tx_pl_clk_req;
                o_pl_inband_pres = linkinit_tx_pl_inband_pres;
                o_pl_wake_ack    = linkinit_tx_pl_wake_ack;
                o_pl_state_sts   = PL_STS_RESET; // still Reset until LINKINIT done
                // TX sideband
                o_tx_encoding    = linkinit_tx_encoding;
                o_tx_sb_req      = linkinit_tx_sb_req;
                o_tx_sb_rsp      = linkinit_tx_sb_rsp;
                o_tx_sb_done     = linkinit_tx_sb_done;
                // RX sideband
                o_rx_encoding    = linkinit_rx_encoding;
                o_rx_sb_req      = linkinit_rx_sb_req;
                o_rx_sb_rsp      = linkinit_rx_sb_rsp;
                o_rx_sb_done     = linkinit_rx_sb_done;
            end

            ACTIVE, ACTIVE_PMNAK: begin
                // No sideband traffic during normal Active operation.
                // RDI signals held by active module outputs.
                o_pl_inband_pres = active_pl_inband_pres; // stays 1
                o_pl_state_sts   = active_pl_state_sts;   // ACTIVE or PMNAK
                o_tx_encoding    = active_tx_encoding;
                o_rx_encoding    = active_rx_encoding;
            end

            // ------------------------------------------------------------------
            // L1 — drive TX and RX L1 sub-module outputs.              [NEW]
            // pl_state_sts taken from TX L1 (TX and RX agree per spec).
            // ------------------------------------------------------------------
            L1: begin
                o_pl_inband_pres = 1'b1;
                o_pl_state_sts   = l1_tx_pl_state_sts;
                // TX sideband
                o_tx_encoding    = l1_tx_encoding;
                o_tx_sb_req      = l1_tx_sb_req;
                o_tx_sb_rsp      = l1_tx_sb_rsp;
                o_tx_sb_done     = l1_tx_sb_done;
                // RX sideband
                o_rx_encoding    = l1_rx_encoding;
                o_rx_sb_req      = l1_rx_sb_req;
                o_rx_sb_rsp      = l1_rx_sb_rsp;
                o_rx_sb_done     = l1_rx_sb_done;
            end

            RETRAIN: begin
                // Placeholder: Retrain sub-module drives its own outputs.
                o_pl_inband_pres = 1'b1; // keep asserted per spec
                o_pl_state_sts   = retrain_o_pl_state_sts;
                o_pl_stallreq    = retrain_o_pl_stallreq;

                // TX sideband
                o_tx_encoding    = retrain_tx_encoding;
                o_tx_info        = retrain_tx_info;
                o_tx_sb_req      = retrain_tx_sb_req;
                o_tx_sb_rsp      = retrain_tx_sb_rsp;
                o_tx_sb_done     = retrain_tx_sb_done;

                // RX sideband
                o_rx_encoding    = retrain_rx_encoding;
                o_rx_info        = retrain_rx_info;
                o_rx_sb_req      = retrain_rx_sb_req;
                o_rx_sb_rsp      = retrain_rx_sb_rsp;
                o_rx_sb_done     = retrain_rx_sb_done;
            end
        endcase
    end

endmodule