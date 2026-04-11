//------------------------------------------------------------------------------
// Module: ucie_sideband_rx_msg_enc_dec
// Description: ...
//------------------------------------------------------------------------------
module ucie_sideband_rx_msg_enc_dec
#(//---- PARAMETER DECLARATIONS ------------------------------------------------
  parameter  pENCODING_WIDTH      = 9   // Width of Encoding field
  ,parameter pDECODING_WIDTH      = 9   // Width of Decoding field
  ,parameter pDATA_WIDTH          = 64  // Width of data bus
  ,parameter pINFO_WIDTH          = 16  // Width of info field
  ,parameter pMSG_CODE_WIDTH      = 8   // Width of message code field
  ,parameter pMSG_SUBCODE_WIDTH   = 8   // Width of message subcode field
  ,parameter pOP_CODE_WIDTH       = 5   // Width of operation code field
  ,parameter pRESERVED            = 0   // Reserved bits
  ,parameter pMSG_WIDTH           = 128 // Width of messsage bus
)
(//---- PORT DECLARATIONS -----------------------------------------------------
  input  wire                   i_clk
  ,input  wire                  i_reset
  ,input  wire                  i_req
  ,input  wire                  i_resp
  ,input  wire                  i_done
  ,input  wire [pDATA_WIDTH-1:0] i_data_in
  ,input  wire [pENCODING_WIDTH-1:0] i_encoding
  ,input  wire [pINFO_WIDTH-1:0] i_info_in
  ,input  wire [pMSG_WIDTH-1:0] i_msg_in
  ,input  wire                  i_full
  ,input  wire                  i_empty
  ,output reg                   o_req
  ,output reg                   o_resp
  ,output reg                   o_done
  ,output reg  [pDATA_WIDTH-1:0] o_data_out
  ,output reg  [pDECODING_WIDTH-1:0] o_decoding
  ,output reg  [pINFO_WIDTH-1:0] o_info_out
  ,output reg  [pMSG_WIDTH-1:0] o_msg_out
  ,output reg                  o_enc_ready
  ,output wire                 o_dec_ready
  ,output reg                  o_valid
);

  //---- SIGNAL DECLARATIONS ---------------------------------------------------
  
  reg  [pMSG_CODE_WIDTH-1:0] enc_msg_code;
  reg  [pMSG_SUBCODE_WIDTH-1:0] enc_msg_subcode;
  reg  [pOP_CODE_WIDTH-1:0] enc_op_code;
  reg  [2:0] enc_srcid;
  reg  [2:0] enc_dstid;
  reg  enc_dp;
  reg  enc_cp;

  wire  [pMSG_CODE_WIDTH-1:0] dec_msg_code;
  wire  [pMSG_SUBCODE_WIDTH-1:0] dec_msg_subcode;
  wire  [pOP_CODE_WIDTH-1:0] dec_op_code;
  wire  [2:0] dec_srcid;
  wire  [2:0] dec_dstid;
  wire  dec_dp;
  wire  dec_cp;
  reg  stall_flag;

  wire  dec_valid;
  wire  [pINFO_WIDTH-1:0] o_info_out_w;
  wire  [pDATA_WIDTH-1:0] o_data_out_w;
  reg  dec_req;
  reg  dec_resp;
  reg  [pDECODING_WIDTH-1:0] dec_decoding;

  
  //---- SEQUENTIAL PROCESSES --------------------------------------------------

  /// Encoding Process
  // ---- ENCODING DEFINITIONS ------------------------------------------------
  typedef enum logic [pENCODING_WIDTH-1:0] {
    // ========== SBINIT Messages ==========
    SBINIT_DONE_RESP                      = 'h9,
    
    // ========== MBINIT.PARAM Messages ==========
    MBINIT_PARAM_DONE_RESP                = 'h12,
    
    // ========== MBINIT.CAL Messages ==========
    MBINIT_CAL_DONE_RESP                  = 'h18,
    
    // ========== MBINIT.REPAIRCLK Messages ==========
    MBINIT_REPAIRCLK_INIT_RESP            = 'h20,
    MBINIT_REPAIRCLK_RES_RESP             = 'h23,
    MBINIT_REPAIRCLK_DONE_RESP            = 'h24,
    
    // ========== MBINIT.REPAIRVAL Messages ==========
    MBINIT_REPAIRVAL_INIT_RESP            = 'h28,
    MBINIT_REPAIRVAL_RES_RESP             = 'h2B,
    MBINIT_REPAIRVAL_DONE_RESP            = 'h2C,
    
    // ========== MBINIT.REVERSALMB Messages ==========
    MBINIT_REVERSALMB_INIT_RESP           = 'h30,
    MBINIT_REVERSALMB_CLR_ERR_RESP        = 'h31,
    MBINIT_REVERSALMB_RESULT_RESP         = 'h33,
    MBINIT_REVERSALMB_DONE_RESP           = 'h34,
    
    // ========== MBINIT.REPAIRMB Messages ==========
    MBINIT_REPAIRMB_START_RESP            = 'h38,
    MBINIT_REPAIRMB_APPLY_DEGRADE_RESP    = 'h3C,
    MBINIT_REPAIRMB_END_RESP              = 'h3D,
    
    // ========== MBTRAIN.VALVREF Messages ==========
    MBTRAIN_VALVREF_START_RESP            = 'h80,
    MBTRAIN_VALVREF_END_RESP              = 'h82,
    
    // ========== MBTRAIN.DATAVREF Messages ==========
    MBTRAIN_DATAVREF_START_RESP           = 'h88,
    MBTRAIN_DATAVREF_END_RESP             = 'h8A,
    
    // ========== MBTRAIN.SPEEDIDLE Messages ==========
    MBTRAIN_SPEEDIDLE_DONE_RESP           = 'hCA,
    
    // ========== MBTRAIN.TXSELFCAL Messages ==========
    MBTRAIN_TXSELFCAL_DONE_RESP           = 'hD0,
    
    // ========== MBTRAIN.RXCLKCAL Messages ==========
    MBTRAIN_RXCLKCAL_START_RESP           = 'h98,
    MBTRAIN_RXCLKCAL_DONE_RESP            = 'h9A,
    
    // ========== MBTRAIN.VALTRAINCENTER Messages ==========
    MBTRAIN_VALTRAINCENTER_START_RESP     = 'hA0,
    MBTRAIN_VALTRAINCENTER_DONE_RESP      = 'hA2,
    
    // ========== MBTRAIN.VALTRAINVREF Messages ==========
    MBTRAIN_VALTRAINVREF_START_RESP       = 'hE8,
    MBTRAIN_VALTRAINVREF_DONE_RESP        = 'hEA,
    
    // ========== MBTRAIN.DATATRAINCENTER1 Messages ==========
    MBTRAIN_DATATRAINCENTER1_START_RESP   = 'h90,
    MBTRAIN_DATATRAINCENTER1_END_RESP     = 'h92,
    
    // ========== MBTRAIN.DATATRAINVREF Messages ==========
    MBTRAIN_DATATRAINVREF_START_RESP      = 'hF0,
    MBTRAIN_DATATRAINVREF_END_RESP        = 'hF2,
    
    // ========== MBTRAIN.RXDESKEW Messages ==========
    MBTRAIN_RXDESKEW_START_RESP           = 'hA8,
    MBTRAIN_RXDESKEW_END_RESP             = 'hAC,
    
    // ========== MBTRAIN.DATATRAINCENTER2 Messages ==========
    MBTRAIN_DATATRAINCENTER2_START_RESP   = 'hB0,
    MBTRAIN_DATATRAINCENTER2_END_RESP     = 'hB2,
    
    // ========== MBTRAIN.LINKSPEED Messages ==========
    MBTRAIN_LINKSPEED_START_RESP          = 'hB8,
    MBTRAIN_LINKSPEED_ERROR_RESP          = 'hBF,
    MBTRAIN_LINKSPEED_EXIT_REPAIR_RESP    = 'hBD,
    MBTRAIN_LINKSPEED_EXIT_SPEED_DEGRADE_RESP = 'hBB,
    MBTRAIN_LINKSPEED_DONE_RESP           = 'hBE,
    MBTRAIN_LINKSPEED_EXIT_PHY_RETRAIN_RESP = 'hBC,
    
    // ========== MBTRAIN.REPAIR Messages ==========
    MBTRAIN_REPAIR_INIT_RESP              = 'hC0,
    MBTRAIN_REPAIR_END_RESP               = 'hC2,
    MBTRAIN_REPAIR_APPLY_DEGRADE_RESP     = 'hC1,
    
    // ========== PHYRETRAIN Messages ==========
    PHYRETRAIN_RETRAIN_START_RESP         = 'hDA,
    
    // ========== TRAINERROR Messages ==========
    TRAINERROR_ENTRY_RESP                 = 'h40,

    // ========== TX INIT D to C Messages ==========
    TX_INIT_DTC_START_RESP                = 'h180,
    TX_INIT_DTC_LFSR_CLR_ERR_RESP         = 'h181,
    TX_INIT_DTC_RESULTS_RESP              = 'h183,
    TX_INIT_DTC_END_RESP                  = 'h184,

    // ========== RX INIT D to C Messages ==========
    RX_INIT_DTC_START_REQ                 = 'h188,
    RX_INIT_DTC_LFSR_CLR_ERR_RESP         = 'h189,
    RX_INIT_DTC_RESULTS_RESP               = 'h18B,
    RX_INIT_DTC_END_RESP                   = 'h18D

  } encoding_r;


// ========== Decoding Enum ==========
typedef enum logic [pDECODING_WIDTH-1:0] {
  // ========== SBINIT Messages ==========
  SBINIT_OUT_OF_RESET_REQ            = 'h8,
  SBINIT_DONE_REQ                    = 'h9,

  // ========== MBINIT.PARAM Messages ==========
  MBINIT_PARAM_DONE_REQ              = 'h12,

  // ========== MBINIT.CAL Messages ==========
  MBINIT_CAL_DONE_REQ                = 'h18,

  // ========== MBINIT.REPAIRCLK Messages ==========
  MBINIT_REPAIRCLK_INIT_REQ          = 'h20,
  MBINIT_REPAIRCLK_RESULT_REQ        = 'h23,
  MBINIT_REPAIRCLK_DONE_REQ          = 'h24,

  // ========== MBINIT.REPAIRVAL Messages ==========
  MBINIT_REPAIRVAL_INIT_REQ          = 'h28,
  MBINIT_REPAIRVAL_RESULT_REQ        = 'h2B,
  MBINIT_REPAIRVAL_DONE_REQ          = 'h2C,

  // ========== MBINIT.REVERSALMB Messages ==========
  MBINIT_REVERSALMB_INIT_REQ         = 'h30,
  MBINIT_REVERSALMB_CLR_ERR_REQ      = 'h31,
  MBINIT_REVERSALMB_RESULT_REQ       = 'h33,
  MBINIT_REVERSALMB_DONE_REQ         = 'h34,

  // ========== MBINIT.REPAIRMB Messages ==========
  MBINIT_REPAIRMB_START_REQ          = 'h38,
  MBINIT_REPAIRMB_APPDEG_REQ         = 'h3C,
  MBINIT_REPAIRMB_END_REQ            = 'h3D,

  // ========== MBTRAIN.VALVREF Messages ==========
  MBTRAIN_VALVREF_START_REQ          = 'h80,
  MBTRAIN_VALVREF_END_REQ            = 'h82,

  // ========== MBTRAIN.DATAVREF Messages ==========
  MBTRAIN_DATAVREF_START_REQ         = 'h88,
  MBTRAIN_DATAVREF_END_REQ           = 'h8A,

  // ========== MBTRAIN.SPEEDIDLE Messages ==========
  MBTRAIN_SPEEDIDLE_DONE_REQ         = 'hCA,

  // ========== MBTRAIN.TXSELFCAL Messages ==========
  MBTRAIN_TXSELFCAL_DONE_REQ         = 'hD0,

  // ========== MBTRAIN.RXCLKCAL Messages ==========
  MBTRAIN_RXCLKCAL_START_REQ         = 'h98,
  MBTRAIN_RXCLKCAL_DONE_REQ          = 'h9A,

  // ========== MBTRAIN.VALTRAINCENTER Messages ==========
  MBTRAIN_VALTRAINCENTER_START_REQ   = 'hA0,
  MBTRAIN_VALTRAINCENTER_DONE_REQ    = 'hA2,

  // ========== MBTRAIN.VALTRAINVREF Messages ==========
  MBTRAIN_VALTRAINVREF_START_REQ     = 'hE8,
  MBTRAIN_VALTRAINVREF_DONE_REQ      = 'hEA,

  // ========== MBTRAIN.DATATRAINCENTER1 Messages ==========
  MBTRAIN_DATATRAINCENTER1_START_REQ = 'h90,
  MBTRAIN_DATATRAINCENTER1_END_REQ   = 'h92,

  // ========== MBTRAIN.DATATRAINVREF Messages ==========
  MBTRAIN_DATATRAINVREF_START_REQ    = 'hF0,
  MBTRAIN_DATATRAINVREF_END_REQ      = 'hF2,

  // ========== MBTRAIN.RXDESKEW Messages ==========
  MBTRAIN_RXDESKEW_START_REQ         = 'hA8,
  MBTRAIN_RXDESKEW_END_REQ           = 'hAC,

  // ========== MBTRAIN.DATATRAINCENTER2 Messages ==========
  MBTRAIN_DATATRAINCENTER2_START_REQ = 'hB0,
  MBTRAIN_DATATRAINCENTER2_END_REQ   = 'hB2,

  // ========== MBTRAIN.LINKSPEED Messages ==========
  MBTRAIN_LINKSPEED_START_REQ        = 'hB8,
  MBTRAIN_LINKSPEED_ERROR_REQ        = 'hBF,
  MBTRAIN_LINKSPEED_EXIT_REPAIR_REQ  = 'hBD,
  MBTRAIN_LINKSPEED_EXIT_DEGRADE_REQ = 'hBB,
  MBTRAIN_LINKSPEED_DONE_REQ         = 'hBE,
  MBTRAIN_LINKSPEED_EXIT_PHYRETRAIN_REQ = 'hBC,

  // ========== MBTRAIN.REPAIR Messages ==========
  MBTRAIN_REPAIR_INIT_REQ            = 'hC0,
  MBTRAIN_REPAIR_APPDEG_REQ          = 'hC3,
  MBTRAIN_REPAIR_END_REQ             = 'hC4,

  // ========== PHYRETRAIN Messages ==========
  PHYRETRAIN_START_REQ               = 'hDA,

  // ========== TRAINERROR Messages ==========
  TRAINERROR_ENTRY_REQ               = 'h40,

  // ========== TX INIT D to C Messages ==========
  TX_INIT_DTC_START_REQ              = 'h180,
  TX_INIT_DTC_LFSR_CLR_ERR_REQ       = 'h181,
  TX_INIT_DTC_RESULTS_REQ            = 'h183,
  TX_INIT_DTC_END_REQ                = 'h184,

  // ========== RX INIT D to C Messages ==========
  RX_INIT_DTC_START_RESP             = 'h188,
  RX_INIT_DTC_LFSR_CLR_ERR_REQ       = 'h189,
  RX_INIT_DTC_RESULTS_REQ            = 'h18B,
  RX_INIT_DTC_SWEEP_DONE_RESULTS_REQ = 'h18C,
  RX_INIT_DTC_END_REQ                = 'h18D,
  

  DEFAULT                            = {pDECODING_WIDTH{1'b0}}
} decoding_r;



  //---- SEQUENTIAL PROCESSES --------------------------------------------------
  //Decoding process
  always @(posedge i_clk or posedge i_reset) begin
    if (i_reset) begin
      o_req           <= 1'b0;
      o_resp          <= 1'b0;
      o_info_out      <= {pINFO_WIDTH{1'b0}};
      o_data_out      <= {pDATA_WIDTH{1'b0}};
      o_decoding      <= {pDECODING_WIDTH{1'b0}};
      o_valid         <= 1'b0;
      stall_flag      <= 1'b0;
    end
    else begin
    if (!i_empty && !stall_flag) begin
      o_valid         <= dec_valid; // Valid message
      o_info_out      <= o_info_out_w; // Extract info field from input message
      o_data_out      <= o_data_out_w; // Extract data field from input message
      o_req           <= dec_req;
      o_resp          <= dec_resp;
      o_decoding      <= dec_decoding;
      stall_flag      <= 1'b1; // Mark that first message has been processed
    end
    else if (stall_flag)begin
      o_req           <= o_req;
      o_resp          <= o_resp;
      o_info_out      <= o_info_out;
      o_data_out      <= o_data_out;
      o_decoding      <= o_decoding;
      o_valid         <= o_valid;
    end
    else begin
      o_req           <= 1'b0;
      o_resp          <= 1'b0;
      o_info_out      <= {pINFO_WIDTH{1'b0}};
      o_data_out      <= {pDATA_WIDTH{1'b0}};
      o_decoding      <= {pDECODING_WIDTH{1'b0}};
      o_valid         <= 1'b0;
    end
    if (i_done) begin
      stall_flag      <= 1'b0; // Clear stall flag on done signal
      o_req           <= 1'b0;
      o_resp          <= 1'b0;
      o_info_out      <= {pINFO_WIDTH{1'b0}};
      o_data_out      <= {pDATA_WIDTH{1'b0}};
      o_decoding      <= {pDECODING_WIDTH{1'b0}};
      o_valid         <= 1'b0;
    end
    end
  end // Decoding_proc


  //---- COMBINATIONAL LOGIC ---------------------------------------------------
// --- Combinational parity and field extraction ---
assign dec_msg_code    = i_msg_in[117:110];
assign dec_msg_subcode = i_msg_in[71:64];
assign dec_op_code     = i_msg_in[100:96];
assign dec_srcid       = i_msg_in[127:125];
assign dec_dstid       = i_msg_in[90:88];
assign dec_dp          = ^{i_msg_in[63:0]};
assign dec_cp          = ^{{i_msg_in[127:96], i_msg_in[93:64]}};

assign dec_valid       = (dec_cp == i_msg_in[94]) &&
                         (dec_dp == i_msg_in[95]) &&
                         (dec_srcid == 3'b010) &&
                         (dec_dstid == 3'b110);

assign o_dec_ready = !i_empty && !stall_flag;
assign o_info_out_w = i_msg_in[87:72];
assign o_data_out_w = i_msg_in[63:0];

// --- Combinational case decode ---
always @(*) begin
  dec_req      = 1'b0;
  dec_resp     = 1'b0;
  dec_decoding = DEFAULT;

  case ({dec_msg_code, dec_msg_subcode, dec_op_code})

  // ========== SBINIT Messages ==========
    {8'h91, 8'h00, 5'b10010}: begin  // SBINIT out of Reset
      dec_req      = 1'b1;
      dec_resp     = 1'b0;
      dec_decoding = SBINIT_OUT_OF_RESET_REQ;
    end
    {8'h95, 8'h01, 5'b10010}: begin  // SBINIT done req
      dec_req      = 1'b1;
      dec_resp     = 1'b0;
      dec_decoding = SBINIT_DONE_REQ;
    end
  // ========== MBINIT.PARAM Messages ==========
    {8'hA5, 8'h00, 5'b11011}: begin  // MBINIT.PARAM Done req
      dec_req      = 1'b1;
      dec_resp     = 1'b0;
      dec_decoding = MBINIT_PARAM_DONE_REQ;
    end

  // ========== MBINIT.CAL Messages ==========
    {8'hA5, 8'h02, 5'b10010}: begin  // MBINIT.CAL Done req
      dec_req      = 1'b1;
      dec_resp     = 1'b0;
      dec_decoding = MBINIT_CAL_DONE_REQ;
    end

  // ========== MBINIT.REPAIRCLK Messages ==========
    {8'hA5, 8'h03, 5'b10010}: begin  // MBINIT.REPAIRCLK init req
      dec_req      = 1'b1;
      dec_resp     = 1'b0;
      dec_decoding = MBINIT_REPAIRCLK_INIT_REQ;
    end
    {8'hA5, 8'h04, 5'b10010}: begin  // MBINIT.REPAIRCLK result req
      dec_req      = 1'b1;
      dec_resp     = 1'b0;
      dec_decoding = MBINIT_REPAIRCLK_RESULT_REQ;
    end
    {8'hA5, 8'h08, 5'b10010}: begin  // MBINIT.REPAIRCLK done req
      dec_req      = 1'b1;
      dec_resp     = 1'b0;
      dec_decoding = MBINIT_REPAIRCLK_DONE_REQ;
    end

  // ========== MBINIT.REPAIRVAL Messages ==========
    {8'hA5, 8'h09, 5'b10010}: begin  // MBINIT.REPAIRVAL init req
      dec_req      = 1'b1;
      dec_resp     = 1'b0;
      dec_decoding = MBINIT_REPAIRVAL_INIT_REQ;
    end
    {8'hA5, 8'h0A, 5'b10010}: begin  // MBINIT.REPAIRVAL result req
      dec_req      = 1'b1;
      dec_resp     = 1'b0;
      dec_decoding = MBINIT_REPAIRVAL_RESULT_REQ;
    end
    {8'hA5, 8'h0C, 5'b10010}: begin  // MBINIT.REPAIRVAL done req
      dec_req      = 1'b1;
      dec_resp     = 1'b0;
      dec_decoding = MBINIT_REPAIRVAL_DONE_REQ;
    end

  // ========== MBINIT.REVERSALMB Messages ==========
    {8'hA5, 8'h0D, 5'b10010}: begin  // MBINIT.REVERSALMB init req
      dec_req      = 1'b1;
      dec_resp     = 1'b0;
      dec_decoding = MBINIT_REVERSALMB_INIT_REQ;
    end
    {8'hA5, 8'h0E, 5'b10010}: begin  // MBINIT.REVERSALMB clear error req
      dec_req      = 1'b1;
      dec_resp     = 1'b0;
      dec_decoding = MBINIT_REVERSALMB_CLR_ERR_REQ;
    end
    {8'hA5, 8'h0F, 5'b11011}: begin  // MBINIT.REVERSALMB result req
      dec_req      = 1'b1;
      dec_resp     = 1'b0;
      dec_decoding = MBINIT_REVERSALMB_RESULT_REQ;
    end
    {8'hA5, 8'h10, 5'b10010}: begin  // MBINIT.REVERSALMB done req
      dec_req      = 1'b1;
      dec_resp     = 1'b0;
      dec_decoding = MBINIT_REVERSALMB_DONE_REQ;
    end

  // ========== MBINIT.REPAIRMB Messages ==========
    {8'hA5, 8'h11, 5'b10010}: begin  // MBINIT.REPAIRMB start req
      dec_req      = 1'b1;
      dec_resp     = 1'b0;
      dec_decoding = MBINIT_REPAIRMB_START_REQ;
    end
    {8'hA5, 8'h14, 5'b10010}: begin  // MBINIT.REPAIRMB apply degrade req
      dec_req      = 1'b1;
      dec_resp     = 1'b0;
      dec_decoding = MBINIT_REPAIRMB_APPDEG_REQ;
    end
    {8'hA5, 8'h13, 5'b10010}: begin  // MBINIT.REPAIRMB end req
      dec_req      = 1'b1;
      dec_resp     = 1'b0;
      dec_decoding = MBINIT_REPAIRMB_END_REQ;
    end

  // ========== MBTRAIN.VALVREF Messages ==========
    {8'hB5, 8'h00, 5'b10010}: begin  // MBTRAIN.VALVREF start req
      dec_req      = 1'b1;
      dec_resp     = 1'b0;
      dec_decoding = MBTRAIN_VALVREF_START_REQ;
    end
    {8'hB5, 8'h01, 5'b10010}: begin  // MBTRAIN.VALVREF end req
      dec_req      = 1'b1;
      dec_resp     = 1'b0;
      dec_decoding = MBTRAIN_VALVREF_END_REQ;
    end

  // ========== MBTRAIN.DATAVREF Messages ==========
    {8'hB5, 8'h02, 5'b10010}: begin  // MBTRAIN.DATAVREF start req
      dec_req      = 1'b1;
      dec_resp     = 1'b0;
      dec_decoding = MBTRAIN_DATAVREF_START_REQ;
    end
    {8'hB5, 8'h03, 5'b10010}: begin  // MBTRAIN.DATAVREF end req
      dec_req      = 1'b1;
      dec_resp     = 1'b0;
      dec_decoding = MBTRAIN_DATAVREF_END_REQ;
    end

  // ========== MBTRAIN.SPEEDIDLE Messages ==========
    {8'hB5, 8'h04, 5'b10010}: begin  // MBTRAIN.SPEEDIDLE done req
      dec_req      = 1'b1;
      dec_resp     = 1'b0;
      dec_decoding = MBTRAIN_SPEEDIDLE_DONE_REQ;
    end

  // ========== MBTRAIN.TXSELFCAL Messages ==========
    {8'hB5, 8'h05, 5'b10010}: begin  // MBTRAIN.TXSELFCAL Done req
      dec_req      = 1'b1;
      dec_resp     = 1'b0;
      dec_decoding = MBTRAIN_TXSELFCAL_DONE_REQ;
    end

  // ========== MBTRAIN.RXCLKCAL Messages ==========
    {8'hB5, 8'h06, 5'b10010}: begin  // MBTRAIN.RXCLKCAL start req
      dec_req      = 1'b1;
      dec_resp     = 1'b0;
      dec_decoding = MBTRAIN_RXCLKCAL_START_REQ;
    end
    {8'hB5, 8'h07, 5'b10010}: begin  // MBTRAIN.RXCLKCAL done req
      dec_req      = 1'b1;
      dec_resp     = 1'b0;
      dec_decoding = MBTRAIN_RXCLKCAL_DONE_REQ;
    end

  // ========== MBTRAIN.VALTRAINCENTER Messages ==========
    {8'hB5, 8'h08, 5'b10010}: begin  // MBTRAIN.VALTRAINCENTER start req
      dec_req      = 1'b1;
      dec_resp     = 1'b0;
      dec_decoding = MBTRAIN_VALTRAINCENTER_START_REQ;
    end
    {8'hB5, 8'h09, 5'b10010}: begin  // MBTRAIN.VALTRAINCENTER done req
      dec_req      = 1'b1;
      dec_resp     = 1'b0;
      dec_decoding = MBTRAIN_VALTRAINCENTER_DONE_REQ;
    end

  // ========== MBTRAIN.VALTRAINVREF Messages ==========
    {8'hB5, 8'h0A, 5'b10010}: begin  // MBTRAIN.VALTRAINVREF start req
      dec_req      = 1'b1;
      dec_resp     = 1'b0;
      dec_decoding = MBTRAIN_VALTRAINVREF_START_REQ;
    end
    {8'hB5, 8'h0B, 5'b10010}: begin  // MBTRAIN.VALTRAINVREF done req
      dec_req      = 1'b1;
      dec_resp     = 1'b0;
      dec_decoding = MBTRAIN_VALTRAINVREF_DONE_REQ;
    end

  // ========== MBTRAIN.DATATRAINCENTER1 Messages ==========
    {8'hB5, 8'h0C, 5'b10010}: begin  // MBTRAIN.DATATRAINCENTER1 start req
      dec_req      = 1'b1;
      dec_resp     = 1'b0;
      dec_decoding = MBTRAIN_DATATRAINCENTER1_START_REQ;
    end
    {8'hB5, 8'h0D, 5'b10010}: begin  // MBTRAIN.DATATRAINCENTER1 end req
      dec_req      = 1'b1;
      dec_resp     = 1'b0;
      dec_decoding = MBTRAIN_DATATRAINCENTER1_END_REQ;
    end

  // ========== MBTRAIN.DATATRAINVREF Messages ==========
    {8'hB5, 8'h0E, 5'b10010}: begin  // MBTRAIN.DATATRAINVREF start req
      dec_req      = 1'b1;
      dec_resp     = 1'b0;
      dec_decoding = MBTRAIN_DATATRAINVREF_START_REQ;
    end
    {8'hB5, 8'h0F, 5'b10010}: begin  // MBTRAIN.DATATRAINVREF end req
      dec_req      = 1'b1;
      dec_resp     = 1'b0;
      dec_decoding = MBTRAIN_DATATRAINVREF_END_REQ;
    end

  // ========== MBTRAIN.RXDESKEW Messages ==========
    {8'hB5, 8'h11, 5'b10010}: begin  // MBTRAIN.RXDESKEW start req
      dec_req      = 1'b1;
      dec_resp     = 1'b0;
      dec_decoding = MBTRAIN_RXDESKEW_START_REQ;
    end
    {8'hB5, 8'h12, 5'b10010}: begin  // MBTRAIN.RXDESKEW end req
      dec_req      = 1'b1;
      dec_resp     = 1'b0;
      dec_decoding = MBTRAIN_RXDESKEW_END_REQ;
    end

  // ========== MBTRAIN.DATATRAINCENTER2 Messages ==========
    {8'hB5, 8'h13, 5'b10010}: begin  // MBTRAIN.DATATRAINCENTER2 start req
      dec_req      = 1'b1;
      dec_resp     = 1'b0;
      dec_decoding = MBTRAIN_DATATRAINCENTER2_START_REQ;
    end
    {8'hB5, 8'h14, 5'b10010}: begin  // MBTRAIN.DATATRAINCENTER2 end req
      dec_req      = 1'b1;
      dec_resp     = 1'b0;
      dec_decoding = MBTRAIN_DATATRAINCENTER2_END_REQ;
    end

  // ========== MBTRAIN.LINKSPEED Messages ==========
    {8'hB5, 8'h15, 5'b10010}: begin  // MBTRAIN.LINKSPEED start req
      dec_req      = 1'b1;
      dec_resp     = 1'b0;
      dec_decoding = MBTRAIN_LINKSPEED_START_REQ;
    end
    {8'hB5, 8'h16, 5'b10010}: begin  // MBTRAIN.LINKSPEED error req
      dec_req      = 1'b1;
      dec_resp     = 1'b0;
      dec_decoding = MBTRAIN_LINKSPEED_ERROR_REQ;
    end
    {8'hB5, 8'h17, 5'b10010}: begin  // MBTRAIN.LINKSPEED exit to repair req
      dec_req      = 1'b1;
      dec_resp     = 1'b0;
      dec_decoding = MBTRAIN_LINKSPEED_EXIT_REPAIR_REQ;
    end
    {8'hB5, 8'h18, 5'b10010}: begin  // MBTRAIN.LINKSPEED exit to speed degrade req
      dec_req      = 1'b1;
      dec_resp     = 1'b0;
      dec_decoding = MBTRAIN_LINKSPEED_EXIT_DEGRADE_REQ;
    end
    {8'hB5, 8'h19, 5'b10010}: begin  // MBTRAIN.LINKSPEED done req
      dec_req      = 1'b1;
      dec_resp     = 1'b0;
      dec_decoding = MBTRAIN_LINKSPEED_DONE_REQ;
    end
    {8'hB5, 8'h1F, 5'b10010}: begin  // MBTRAIN.LINKSPEED exit to phy retrain req
      dec_req      = 1'b1;
      dec_resp     = 1'b0;
      dec_decoding = MBTRAIN_LINKSPEED_EXIT_PHYRETRAIN_REQ;
    end

  // ========== MBTRAIN.REPAIR Messages ==========
    {8'hB5, 8'h1B, 5'b10010}: begin  // MBTRAIN.REPAIR init req
      dec_req      = 1'b1;
      dec_resp     = 1'b0;
      dec_decoding = MBTRAIN_REPAIR_INIT_REQ;
    end
    {8'hB5, 8'h1E, 5'b10010}: begin  // MBTRAIN.REPAIR Apply degrade req
      dec_req      = 1'b1;
      dec_resp     = 1'b0;
      dec_decoding = MBTRAIN_REPAIR_APPDEG_REQ;
    end
    {8'hB5, 8'h1D, 5'b10010}: begin  // MBTRAIN.REPAIR end req
      dec_req      = 1'b1;
      dec_resp     = 1'b0;
      dec_decoding = MBTRAIN_REPAIR_END_REQ;
    end

  // ========== PHYRETRAIN Messages ==========
    {8'hC5, 8'h01, 5'b10010}: begin  // PHYRETRAIN.retrain start req
      dec_req      = 1'b1;
      dec_resp     = 1'b0;
      dec_decoding = PHYRETRAIN_START_REQ;
    end

  // ========== TRAINERROR Messages ==========
    {8'hE5, 8'h00, 5'b10010}: begin  // TRAINERROR Entry req
      dec_req      = 1'b1;
      dec_resp     = 1'b0;
      dec_decoding = TRAINERROR_ENTRY_REQ;
    end

  // ========== TX INIT D to C Messages ==========
    {8'h85, 8'h05, 5'b11011}: begin  // Start Tx Init D to C eye sweep req
      dec_req      = 1'b1;
      dec_resp     = 1'b0;
      dec_decoding = TX_INIT_DTC_START_REQ;
    end
    {8'h85, 8'h02, 5'b10010}: begin  // LFSR_clear_error req
      dec_req      = 1'b1;
      dec_resp     = 1'b0;
      dec_decoding = TX_INIT_DTC_LFSR_CLR_ERR_REQ;
    end
    {8'h85, 8'h03, 5'b10010}: begin  // Tx Init D to C results req
      dec_req      = 1'b1;
      dec_resp     = 1'b0;
      dec_decoding = TX_INIT_DTC_RESULTS_REQ;
    end
    {8'h85, 8'h06, 5'b10010}: begin  // End Tx Init D to C eye sweep req
      dec_req      = 1'b1;
      dec_resp     = 1'b0;
      dec_decoding = TX_INIT_DTC_END_REQ;
    end

  // ========== RX INIT D to C Messages ==========
    {8'h8A, 8'h0A, 5'b10010}: begin  // Start Rx Init D to C eye sweep resp
      dec_req      = 1'b0;
      dec_resp     = 1'b1;
      dec_decoding = RX_INIT_DTC_START_RESP;
    end
    
    {8'h85, 8'h0B, 5'b10010}: begin  // Rx Init D to C results req
      dec_req      = 1'b1;
      dec_resp     = 1'b0;
      dec_decoding = RX_INIT_DTC_RESULTS_REQ;
    end
    {8'h81, 8'h0C, 5'b11011}: begin  //Rx Init D to C sweep done with results req
      dec_req      = 1'b1;
      dec_resp     = 1'b0;
      dec_decoding = RX_INIT_DTC_SWEEP_DONE_RESULTS_REQ;
    end
    {8'h85, 8'h0D, 5'b10010}: begin  // End Rx Init D to C eye sweep req
      dec_req      = 1'b1;
      dec_resp     = 1'b0;
      dec_decoding = RX_INIT_DTC_END_REQ;
    end

    default: begin
      dec_req      = 1'b0;
      dec_resp     = 1'b0;
      dec_decoding = DEFAULT;
    end
  endcase
end

  // Combinational Encoding Process
  always @(*) 
  begin: Encoding_proc
    // Default values
    enc_msg_code    = {pMSG_CODE_WIDTH{1'b0}};
    enc_msg_subcode = {pMSG_SUBCODE_WIDTH{1'b0}};
    enc_op_code     = 'b10101; // Default Operation message code
    enc_srcid       = 3'b010; // Physical Layer source ID
    enc_dstid       = 3'b110; // Remote Die Physical Layer destination ID
    enc_dp          = 1'b0; // Data Parity (even parity over all data bits)
    enc_cp          = 1'b0; // Control Parity (even parity over header fields)
    o_msg_out       = {pMSG_WIDTH{1'b0}}; // Construct message
    o_enc_ready     = 1'b0;
    o_done          = 1'b0;

    if (!i_reset) begin
      if ((i_req || i_resp) && !i_full) begin
        case (encoding_r'(i_encoding))
          
          // ========== SBINIT Messages ==========
          SBINIT_DONE_RESP: begin
            enc_msg_code    = 'h9A; // SBINIT done resp message code
            enc_msg_subcode = 'h01; // SBINIT done resp message subcode
            enc_op_code     = 'b10010; // No Data Operation message code
            enc_srcid       = 3'b010; // Physical Layer source ID
            enc_dstid       = 3'b110; // Remote Die Physical Layer destination ID
            enc_dp          = 1'b0; // Data Parity (even parity over all data bits)
          end

          // ========== MBINIT.PARAM Messages ==========
          MBINIT_PARAM_DONE_RESP: begin
            enc_msg_code    = 'hAA; // MBINIT.PARAM done resp message code
            enc_msg_subcode = 'h00; // MBINIT.PARAM done resp message subcode
            enc_op_code     = 'b11011; // Data Operation message code
            enc_srcid       = 3'b010; // Physical Layer destination ID 
            enc_dstid       = 3'b110; // Remote Die Physical Layer source ID
            enc_dp          = ^i_data_in; // Data Parity (even parity over all data bits)
          end

          // ========== MBINIT.CAL Messages ==========
          MBINIT_CAL_DONE_RESP: begin
            enc_msg_code    = 'hAA; // MBINIT.CAL Done resp message code
            enc_msg_subcode = 'h02; // MBINIT.CAL Done resp message subcode
            enc_op_code     = 'b10010; // No Data Operation message code
            enc_srcid       = 3'b010; // Physical Layer source ID
            enc_dstid       = 3'b110; // Remote Die Physical Layer destination ID
            enc_dp          = 1'b0; // Data Parity (even parity over all data bits)
          end

          // ========== MBINIT.REPAIRCLK Messages ==========
          MBINIT_REPAIRCLK_INIT_RESP: begin
            enc_msg_code    = 'hAA; // MBINIT.REPAIRCLK init resp message code
            enc_msg_subcode = 'h03; // MBINIT.REPAIRCLK init resp message subcode
            enc_op_code     = 'b10010; // No Data Operation message code
            enc_srcid       = 3'b010; // Physical Layer source ID
            enc_dstid       = 3'b110; // Remote Die Physical Layer destination ID
            enc_dp          = 1'b0; // Data Parity (even parity over all data bits)
          end
          MBINIT_REPAIRCLK_RES_RESP: begin
            enc_msg_code    = 'hAA; // MBINIT.REPAIRCLK result resp message code
            enc_msg_subcode = 'h04; // MBINIT.REPAIRCLK result resp message subcode
            enc_op_code     = 'b10010; // No Data Operation message code
            enc_srcid       = 3'b010; // Physical Layer source ID
            enc_dstid       = 3'b110; // Remote Die Physical Layer destination ID
            enc_dp          = 1'b0; // Data Parity (even parity over all data bits)
          end
          MBINIT_REPAIRCLK_DONE_RESP: begin
            enc_msg_code    = 'hAA; // MBINIT.REPAIRCLK done resp message code
            enc_msg_subcode = 'h08; // MBINIT.REPAIRCLK done resp message subcode
            enc_op_code     = 'b10010; // No Data Operation message code
            enc_srcid       = 3'b010; // Physical Layer source ID
            enc_dstid       = 3'b110; // Remote Die Physical Layer destination ID
            enc_dp          = 1'b0; // Data Parity (even parity over all data bits)
          end

          // ========== MBINIT.REPAIRVAL Messages ==========
          MBINIT_REPAIRVAL_INIT_RESP: begin
            enc_msg_code    = 'hAA; // MBINIT.REPAIRVAL init resp message code
            enc_msg_subcode = 'h09; // MBINIT.REPAIRVAL init resp message subcode
            enc_op_code     = 'b10010; // No Data Operation message code
            enc_srcid       = 3'b010; // Physical Layer source ID
            enc_dstid       = 3'b110; // Remote Die Physical Layer destination ID
            enc_dp          = 1'b0; // Data Parity (even parity over all data bits)
          end
          MBINIT_REPAIRVAL_RES_RESP: begin
            enc_msg_code    = 'hAA; // MBINIT.REPAIRVAL result resp message code
            enc_msg_subcode = 'h0A; // MBINIT.REPAIRVAL result resp message subcode
            enc_op_code     = 'b10010; // No Data Operation message code
            enc_srcid       = 3'b010; // Physical Layer source ID
            enc_dstid       = 3'b110; // Remote Die Physical Layer destination ID
            enc_dp          = 1'b0; // Data Parity (even parity over all data bits)
          end
          MBINIT_REPAIRVAL_DONE_RESP: begin
            enc_msg_code    = 'hAA; // MBINIT.REPAIRVAL done resp message code
            enc_msg_subcode = 'h0C; // MBINIT.REPAIRVAL done resp message subcode
            enc_op_code     = 'b10010; // No Data Operation message code
            enc_srcid       = 3'b010; // Physical Layer source ID
            enc_dstid       = 3'b110; // Remote Die Physical Layer destination ID
            enc_dp          = 1'b0; // Data Parity (even parity over all data bits)
          end

          // ========== MBINIT.REVERSALMB Messages ==========
          MBINIT_REVERSALMB_INIT_RESP: begin
            enc_msg_code    = 'hAA; // MBINIT.REVERSALMB init resp message code
            enc_msg_subcode = 'h0D; // MBINIT.REVERSALMB init resp message subcode
            enc_op_code     = 'b10010; // No Data Operation message code
            enc_srcid       = 3'b010; // Physical Layer source ID
            enc_dstid       = 3'b110; // Remote Die Physical Layer destination ID
            enc_dp          = 1'b0; // Data Parity (even parity over all data bits)
          end
          MBINIT_REVERSALMB_CLR_ERR_RESP: begin
            enc_msg_code    = 'hAA; // MBINIT.REVERSALMB clear error resp message code
            enc_msg_subcode = 'h0E; // MBINIT.REVERSALMB clear error resp message subcode
            enc_op_code     = 'b10010; // No Data Operation message code
            enc_srcid       = 3'b010; // Physical Layer source ID
            enc_dstid       = 3'b110; // Remote Die Physical Layer destination ID
            enc_dp          = 1'b0; // Data Parity (even parity over all data bits)
          end
          MBINIT_REVERSALMB_RESULT_RESP: begin
            enc_msg_code    = 'hAA; // MBINIT.REVERSALMB result resp message code
            enc_msg_subcode = 'h0F; // MBINIT.REVERSALMB result resp message subcode
            enc_op_code     = 'b11011; // Data Operation message code
            enc_srcid       = 3'b010; // Physical Layer source ID
            enc_dstid       = 3'b110; // Remote Die Physical Layer destination ID
            enc_dp          = ^i_data_in; // Data Parity (even parity over all data bits)
          end
          MBINIT_REVERSALMB_DONE_RESP: begin
            enc_msg_code    = 'hAA; // MBINIT.REVERSALMB done resp message code
            enc_msg_subcode = 'h10; // MBINIT.REVERSALMB done resp message subcode
            enc_op_code     = 'b10010; // No Data Operation message code
            enc_srcid       = 3'b010; // Physical Layer source ID
            enc_dstid       = 3'b110; // Remote Die Physical Layer destination ID
            enc_dp          = 1'b0; // Data Parity (even parity over all data bits)
          end

          // ========== MBINIT.REPAIRMB Messages ==========
          MBINIT_REPAIRMB_START_RESP: begin
            enc_msg_code    = 'hAA; // MBINIT.REPAIRMB start resp message code
            enc_msg_subcode = 'h11; // MBINIT.REPAIRMB start resp message subcode
            enc_op_code     = 'b10010; // No Data Operation message code
            enc_srcid       = 3'b010; // Physical Layer source ID
            enc_dstid       = 3'b110; // Remote Die Physical Layer destination ID
            enc_dp          = 1'b0; // Data Parity (even parity over all data bits)
          end
          MBINIT_REPAIRMB_APPLY_DEGRADE_RESP: begin
            enc_msg_code    = 'hAA; // MBINIT.REPAIRMB apply degrade resp message code
            enc_msg_subcode = 'h14; // MBINIT.REPAIRMB apply degrade resp message subcode
            enc_op_code     = 'b10010; // No Data Operation message code
            enc_srcid       = 3'b010; // Physical Layer source ID
            enc_dstid       = 3'b110; // Remote Die Physical Layer destination ID
            enc_dp          = 1'b0; // Data Parity (even parity over all data bits)
          end
          MBINIT_REPAIRMB_END_RESP: begin
            enc_msg_code    = 'hAA; // MBINIT.REPAIRMB end resp message code
            enc_msg_subcode = 'h13; // MBINIT.REPAIRMB end resp message subcode
            enc_op_code     = 'b10010; // No Data Operation message code
            enc_srcid       = 3'b010; // Physical Layer source ID
            enc_dstid       = 3'b110; // Remote Die Physical Layer destination ID
            enc_dp          = 1'b0; // Data Parity (even parity over all data bits)
          end
          
          // ========== MBTRAIN.VALVREF Messages ==========
          MBTRAIN_VALVREF_START_RESP: begin
            enc_msg_code    = 'hBA; // (MBTRAIN.VALVREF start resp) message code
            enc_msg_subcode = 'h00; // (MBTRAIN.VALVREF start resp) message subcode
            enc_op_code     = 'b10010; // No Data Operation message code
            enc_srcid       = 3'b010; // Physical Layer source ID
            enc_dstid       = 3'b110; // Remote Die Physical Layer destination ID
            enc_dp          = 1'b0; // Data Parity (even parity over all data bits)
          end
          MBTRAIN_VALVREF_END_RESP: begin
            enc_msg_code    = 'hBA; // (MBTRAIN.VALVREF end resp) message code
            enc_msg_subcode = 'h01; // (MBTRAIN.VALVREF end resp) message subcode
            enc_op_code     = 'b10010; // No Data Operation message code
            enc_srcid       = 3'b010; // Physical Layer source ID
            enc_dstid       = 3'b110; // Remote Die Physical Layer destination ID
            enc_dp          = 1'b0; // Data Parity (even parity over all data bits)
          end

          // ========== MBTRAIN.DATAVREF Messages ==========
          MBTRAIN_DATAVREF_START_RESP: begin
            enc_msg_code    = 'hBA; // (MBTRAIN.DATAVREF start resp) message code
            enc_msg_subcode = 'h02; // (MBTRAIN.DATAVREF start resp) message subcode
            enc_op_code     = 'b10010; // No Data Operation message code
            enc_srcid       = 3'b010; // Physical Layer source ID
            enc_dstid       = 3'b110; // Remote Die Physical Layer destination ID
            enc_dp          = 1'b0; // Data Parity (even parity over all data bits)
          end
          MBTRAIN_DATAVREF_END_RESP: begin
            enc_msg_code    = 'hBA; // (MBTRAIN.DATAVREF end resp) message code
            enc_msg_subcode = 'h03; // (MBTRAIN.DATAVREF end resp) message subcode
            enc_op_code     = 'b10010; // No Data Operation message code
            enc_srcid       = 3'b010; // Physical Layer source ID
            enc_dstid       = 3'b110; // Remote Die Physical Layer destination ID
            enc_dp          = 1'b0; // Data Parity (even parity over all data bits)
          end

          // ========== MBTRAIN.SPEEDIDLE Messages ==========
          MBTRAIN_SPEEDIDLE_DONE_RESP: begin
            enc_msg_code    = 'hBA; // (MBTRAIN.SPEEDIDLE done resp) message code
            enc_msg_subcode = 'h04; // (MBTRAIN.SPEEDIDLE done resp) message subcode
            enc_op_code     = 'b10010; // No Data Operation message code
            enc_srcid       = 3'b010; // Physical Layer source ID
            enc_dstid       = 3'b110; // Remote Die Physical Layer destination ID
            enc_dp          = 1'b0; // Data Parity (even parity over all data bits)
          end

          // ========== MBTRAIN.TXSELFCAL Messages ==========
          MBTRAIN_TXSELFCAL_DONE_RESP: begin
            enc_msg_code    = 'hBA; // (MBTRAIN.TXSELFCAL Done resp) message code
            enc_msg_subcode = 'h05; // (MBTRAIN.TXSELFCAL Done resp) message subcode
            enc_op_code     = 'b10010; // No Data Operation message code
            enc_srcid       = 3'b010; // Physical Layer source ID
            enc_dstid       = 3'b110; // Remote Die Physical Layer destination ID
            enc_dp          = 1'b0; // Data Parity (even parity over all data bits)
          end

          // ========== MBTRAIN.RXCLKCAL Messages ==========
          MBTRAIN_RXCLKCAL_START_RESP: begin
            enc_msg_code    = 'hBA; // (MBTRAIN.RXCLKCAL start resp) message code
            enc_msg_subcode = 'h06; // (MBTRAIN.RXCLKCAL start resp) message subcode
            enc_op_code     = 'b10010; // No Data Operation message code
            enc_srcid       = 3'b010; // Physical Layer source ID
            enc_dstid       = 3'b110; // Remote Die Physical Layer destination ID
            enc_dp          = 1'b0; // Data Parity (even parity over all data bits)
          end
          MBTRAIN_RXCLKCAL_DONE_RESP: begin
            enc_msg_code    = 'hBA; // (MBTRAIN.RXCLKCAL done resp) message code
            enc_msg_subcode = 'h07; // (MBTRAIN.RXCLKCAL done resp) message subcode
            enc_op_code     = 'b10010; // No Data Operation message code
            enc_srcid       = 3'b010; // Physical Layer source ID
            enc_dstid       = 3'b110; // Remote Die Physical Layer destination ID
            enc_dp          = 1'b0; // Data Parity (even parity over all data bits)
          end

          // ========== MBTRAIN.VALTRAINCENTER Messages ==========
          MBTRAIN_VALTRAINCENTER_START_RESP: begin
            enc_msg_code    = 'hBA; // (MBTRAIN.VALTRAINCENTER start resp) message code
            enc_msg_subcode = 'h08; // (MBTRAIN.VALTRAINCENTER start resp) message subcode
            enc_op_code     = 'b10010; // No Data Operation message code
            enc_srcid       = 3'b010; // Physical Layer source ID
            enc_dstid       = 3'b110; // Remote Die Physical Layer destination ID
            enc_dp          = 1'b0; // Data Parity (even parity over all data bits)
          end
          MBTRAIN_VALTRAINCENTER_DONE_RESP: begin
            enc_msg_code    = 'hBA; // (MBTRAIN.VALTRAINCENTER done resp) message code
            enc_msg_subcode = 'h09; // (MBTRAIN.VALTRAINCENTER done resp) message subcode
            enc_op_code     = 'b10010; // No Data Operation message code
            enc_srcid       = 3'b010; // Physical Layer source ID
            enc_dstid       = 3'b110; // Remote Die Physical Layer destination ID
            enc_dp          = 1'b0; // Data Parity (even parity over all data bits)
          end

          // ========== MBTRAIN.VALTRAINVREF Messages ==========
          MBTRAIN_VALTRAINVREF_START_RESP: begin
            enc_msg_code    = 'hBA; // (MBTRAIN.VALTRAINVREF start resp) message code
            enc_msg_subcode = 'h0A; // (MBTRAIN.VALTRAINVREF start resp) message subcode
            enc_op_code     = 'b10010; // No Data Operation message code
            enc_srcid       = 3'b010; // Physical Layer source ID
            enc_dstid       = 3'b110; // Remote Die Physical Layer destination ID
            enc_dp          = 1'b0; // Data Parity (even parity over all data bits)
          end
          MBTRAIN_VALTRAINVREF_DONE_RESP: begin
            enc_msg_code    = 'hBA; // (MBTRAIN.VALTRAINVREF done resp) message code
            enc_msg_subcode = 'h0B; // (MBTRAIN.VALTRAINVREF done resp) message subcode
            enc_op_code     = 'b10010; // No Data Operation message code
            enc_srcid       = 3'b010; // Physical Layer source ID
            enc_dstid       = 3'b110; // Remote Die Physical Layer destination ID
            enc_dp          = 1'b0; // Data Parity (even parity over all data bits)
          end

          // ========== MBTRAIN.DATATRAINCENTER1 Messages ==========
          MBTRAIN_DATATRAINCENTER1_START_RESP: begin
            enc_msg_code    = 'hBA; // (MBTRAIN.DATATRAINCENTER1 start resp) message code
            enc_msg_subcode = 'h0C; // (MBTRAIN.DATATRAINCENTER1 start resp) message subcode
            enc_op_code     = 'b10010; // No Data Operation message code
            enc_srcid       = 3'b010; // Physical Layer source ID
            enc_dstid       = 3'b110; // Remote Die Physical Layer destination ID
            enc_dp          = 1'b0; // Data Parity (even parity over all data bits)
          end
          MBTRAIN_DATATRAINCENTER1_END_RESP: begin
            enc_msg_code    = 'hBA; // (MBTRAIN.DATATRAINCENTER1 end resp) message code
            enc_msg_subcode = 'h0D; // (MBTRAIN.DATATRAINCENTER1 end resp) message subcode
            enc_op_code     = 'b10010; // No Data Operation message code
            enc_srcid       = 3'b010; // Physical Layer source ID
            enc_dstid       = 3'b110; // Remote Die Physical Layer destination ID
            enc_dp          = 1'b0; // Data Parity (even parity over all data bits)
          end

          // ========== MBTRAIN.DATATRAINVREF Messages ==========
          MBTRAIN_DATATRAINVREF_START_RESP: begin
            enc_msg_code    = 'hBA; // (MBTRAIN.DATATRAINVREF start resp) message code
            enc_msg_subcode = 'h0E; // (MBTRAIN.DATATRAINVREF start resp) message subcode
            enc_op_code     = 'b10010; // No Data Operation message code
            enc_srcid       = 3'b010; // Physical Layer source ID
            enc_dstid       = 3'b110; // Remote Die Physical Layer destination ID
            enc_dp          = 1'b0; // Data Parity (even parity over all data bits)
          end
          MBTRAIN_DATATRAINVREF_END_RESP: begin
            enc_msg_code    = 'hB5; // (MBTRAIN.DATATRAINVREF end req) message code
            enc_msg_subcode = 'h10; // (MBTRAIN.DATATRAINVREF end req) message subcode
            enc_op_code     = 'b10010; // No Data Operation message code
            enc_srcid       = 3'b010; // Physical Layer source ID
            enc_dstid       = 3'b110; // Remote Die Physical Layer destination ID
            enc_dp          = 1'b0; // Data Parity (even parity over all data bits)
          end

          // ========== MBTRAIN.RXDESKEW Messages ==========
          MBTRAIN_RXDESKEW_START_RESP: begin
            enc_msg_code    = 'hBA; // (MBTRAIN.RXDESKEW start resp) message code
            enc_msg_subcode = 'h11; // (MBTRAIN.RXDESKEW start resp) message subcode
            enc_op_code     = 'b10010; // No Data Operation message code
            enc_srcid       = 3'b010; // Physical Layer source ID
            enc_dstid       = 3'b110; // Remote Die Physical Layer destination ID
            enc_dp          = 1'b0; // Data Parity (even parity over all data bits)
          end
          MBTRAIN_RXDESKEW_END_RESP: begin
            enc_msg_code    = 'hBA; // (MBTRAIN.RXDESKEW end resp) message code
            enc_msg_subcode = 'h12; // (MBTRAIN.RXDESKEW end resp) message subcode
            enc_op_code     = 'b10010; // No Data Operation message code
            enc_srcid       = 3'b010; // Physical Layer source ID
            enc_dstid       = 3'b110; // Remote Die Physical Layer destination ID
            enc_dp          = 1'b0; // Data Parity (even parity over all data bits)
          end

          // ========== MBTRAIN.DATATRAINCENTER2 Messages ==========
          MBTRAIN_DATATRAINCENTER2_START_RESP: begin
            enc_msg_code    = 'hBA; // (MBTRAIN.DATATRAINCENTER2 start resp) message code
            enc_msg_subcode = 'h13; // (MBTRAIN.DATATRAINCENTER2 start resp) message subcode
            enc_op_code     = 'b10010; // No Data Operation message code
            enc_srcid       = 3'b010; // Physical Layer source ID
            enc_dstid       = 3'b110; // Remote Die Physical Layer destination ID
            enc_dp          = 1'b0; // Data Parity (even parity over all data bits)
          end
          MBTRAIN_DATATRAINCENTER2_END_RESP: begin
            enc_msg_code    = 'hBA; // (MBTRAIN.DATATRAINCENTER2 end resp) message code
            enc_msg_subcode = 'h14; // (MBTRAIN.DATATRAINCENTER2 end resp) message subcode
            enc_op_code     = 'b10010; // No Data Operation message code
            enc_srcid       = 3'b010; // Physical Layer source ID
            enc_dstid       = 3'b110; // Remote Die Physical Layer destination ID
            enc_dp          = 1'b0; // Data Parity (even parity over all data bits)
          end

          // ========== MBTRAIN.LINKSPEED Messages ==========
          MBTRAIN_LINKSPEED_START_RESP: begin
            enc_msg_code    = 'hBA; // (MBTRAIN.LINKSPEED start resp) message code
            enc_msg_subcode = 'h15; // (MBTRAIN.LINKSPEED start resp) message subcode
            enc_op_code     = 'b10010; // No Data Operation message code
            enc_srcid       = 3'b010; // Physical Layer source ID
            enc_dstid       = 3'b110; // Remote Die Physical Layer destination ID
            enc_dp          = 1'b0; // Data Parity (even parity over all data bits)
          end
          MBTRAIN_LINKSPEED_ERROR_RESP: begin
            enc_msg_code    = 'hBA; // (MBTRAIN.LINKSPEED error resp) message code
            enc_msg_subcode = 'h16; // (MBTRAIN.LINKSPEED error resp) message subcode
            enc_op_code     = 'b10010; // No Data Operation message code
            enc_srcid       = 3'b010; // Physical Layer source ID
            enc_dstid       = 3'b110; // Remote Die Physical Layer destination ID
            enc_dp          = 1'b0; // Data Parity (even parity over all data bits)
          end
          MBTRAIN_LINKSPEED_EXIT_REPAIR_RESP: begin
            enc_msg_code    = 'hBA; // (MBTRAIN.LINKSPEED exit to repair resp) message code
            enc_msg_subcode = 'h17; // (MBTRAIN.LINKSPEED exit to repair resp) message subcode
            enc_op_code     = 'b10010; // No Data Operation message code
            enc_srcid       = 3'b010; // Physical Layer source ID
            enc_dstid       = 3'b110; // Remote Die Physical Layer destination ID
            enc_dp          = 1'b0; // Data Parity (even parity over all data bits)
          end
          MBTRAIN_LINKSPEED_EXIT_SPEED_DEGRADE_RESP: begin
            enc_msg_code    = 'hBA; // (MBTRAIN.LINKSPEED exit to speed degrade resp) message code
            enc_msg_subcode = 'h18; // (MBTRAIN.LINKSPEED exit to speed degrade resp) message subcode
            enc_op_code     = 'b10010; // No Data Operation message code
            enc_srcid       = 3'b010; // Physical Layer source ID
            enc_dstid       = 3'b110; // Remote Die Physical Layer destination ID
            enc_dp          = 1'b0; // Data Parity (even parity over all data bits)
          end
          MBTRAIN_LINKSPEED_DONE_RESP: begin
            enc_msg_code    = 'hBA; // (MBTRAIN.LINKSPEED done resp) message code
            enc_msg_subcode = 'h19; // (MBTRAIN.LINKSPEED done resp) message subcode
            enc_op_code     = 'b10010; // No Data Operation message code
            enc_srcid       = 3'b010; // Physical Layer source ID
            enc_dstid       = 3'b110; // Remote Die Physical Layer destination ID
            enc_dp          = 1'b0; // Data Parity (even parity over all data bits)
          end
          MBTRAIN_LINKSPEED_EXIT_PHY_RETRAIN_RESP: begin
            enc_msg_code    = 'hBA; // (MBTRAIN.LINKSPEED exit to phy retrain resp) message code
            enc_msg_subcode = 'h1F; // (MBTRAIN.LINKSPEED exit to phy retrain resp) message subcode
            enc_op_code     = 'b10010; // No Data Operation message code
            enc_srcid       = 3'b010; // Physical Layer source ID
            enc_dstid       = 3'b110; // Remote Die Physical Layer destination ID
            enc_dp          = 1'b0; // Data Parity (even parity over all data bits)
          end

          // ========== MBTRAIN.REPAIR Messages ==========
          MBTRAIN_REPAIR_INIT_RESP: begin
            enc_msg_code    = 'hBA; // (MBTRAIN.REPAIR init resp) message code
            enc_msg_subcode = 'h1B; // (MBTRAIN.REPAIR init resp) message subcode
            enc_op_code     = 'b10010; // No Data Operation message code
            enc_srcid       = 3'b010; // Physical Layer source ID
            enc_dstid       = 3'b110; // Remote Die Physical Layer destination ID
            enc_dp          = 1'b0; // Data Parity (even parity over all data bits)
          end
          MBTRAIN_REPAIR_END_RESP: begin
            enc_msg_code    = 'hBA; // (MBTRAIN.REPAIR end resp) message code
            enc_msg_subcode = 'h1D; // (MBTRAIN.REPAIR end resp) message subcode
            enc_op_code     = 'b10010; // No Data Operation message code
            enc_srcid       = 3'b010; // Physical Layer source ID
            enc_dstid       = 3'b110; // Remote Die Physical Layer destination ID
            enc_dp          = 1'b0; // Data Parity (even parity over all data bits)
          end
          MBTRAIN_REPAIR_APPLY_DEGRADE_RESP: begin
            enc_msg_code    = 'hBA; // (MBTRAIN.REPAIR Apply degrade resp) message code
            enc_msg_subcode = 'h1E; // (MBTRAIN.REPAIR Apply degrade resp) message subcode
            enc_op_code     = 'b10010; // No Data Operation message code
            enc_srcid       = 3'b010; // Physical Layer source ID
            enc_dstid       = 3'b110; // Remote Die Physical Layer destination ID
            enc_dp          = 1'b0; // Data Parity (even parity over all data bits)
          end

          // ========== PHYRETRAIN Messages ==========
          PHYRETRAIN_RETRAIN_START_RESP: begin
            enc_msg_code    = 'hCA; // PHYRETRAIN.retrain start resp message code
            enc_msg_subcode = 'h01; // PHYRETRAIN.retrain start resp message subcode
            enc_op_code     = 'b10010; // No Data Operation message code
            enc_srcid       = 3'b010; // Physical Layer source ID
            enc_dstid       = 3'b110; // Remote Die Physical Layer destination ID
            enc_dp          = 1'b0; // Data Parity (even parity over all data bits)
          end

          // ========== TRAINERROR Messages ==========
          TRAINERROR_ENTRY_RESP: begin
            enc_msg_code    = 'hEA; // TRAINERROR Entry resp message code
            enc_msg_subcode = 'h00; // TRAINERROR Entry resp message subcode
            enc_op_code     = 'b10010; // No Data Operation message code
            enc_srcid       = 3'b010; // Physical Layer source ID
            enc_dstid       = 3'b110; // Remote Die Physical Layer destination ID
            enc_dp          = 1'b0; // Data Parity (even parity over all data bits)
          end

          // ========== TX INIT D to C Messages ==========
          TX_INIT_DTC_START_RESP: begin
            enc_msg_code    = 'h8A; // Start Tx Init D to C eye sweep resp message code
            enc_msg_subcode = 'h05; // Start Tx Init D to C eye sweep resp message subcode
            enc_op_code     = 'b10010; // NO Data Operation message code
            enc_srcid       = 3'b010; // Physical Layer source ID
            enc_dstid       = 3'b110; // Remote Die Physical Layer destination ID
            enc_dp          = 1'b0;   // Data Parity (even parity over all data bits)
          end
          TX_INIT_DTC_LFSR_CLR_ERR_RESP: begin
            enc_msg_code    = 'h8A; // LFSR_clear_error resp message code
            enc_msg_subcode = 'h02; // LFSR_clear_error resp message subcode
            enc_op_code     = 'b10010; // No Data Operation message code
            enc_srcid       = 3'b010; // Physical Layer source ID
            enc_dstid       = 3'b110; // Remote Die Physical Layer destination ID
            enc_dp          = 1'b0; // Data Parity (even parity over all data bits)
          end
          TX_INIT_DTC_RESULTS_RESP: begin
            enc_msg_code    = 'h8A; // Tx Init D to C results resp message code
            enc_msg_subcode = 'h03; // Tx Init D to C results resp message subcode
            enc_op_code     = 'b11011; // Data Operation message code
            enc_srcid       = 3'b010; // Physical Layer source ID
            enc_dstid       = 3'b110; // Remote Die Physical Layer destination ID
            enc_dp          = ^i_data_in; // Data Parity (even parity over all data bits)
          end
          TX_INIT_DTC_END_RESP: begin
            enc_msg_code    = 'h8A; // End Tx Init D to C eye sweep resp message code
            enc_msg_subcode = 'h06; // End Tx Init D to C eye sweep resp message subcode
            enc_op_code     = 'b10010; // No Data Operation message code
            enc_srcid       = 3'b010; // Physical Layer source ID
            enc_dstid       = 3'b110; // Remote Die Physical Layer destination ID
            enc_dp          = 1'b0; // Data Parity (even parity over all data bits)
          end

          // ========== RX INIT D to C Messages ==========
          RX_INIT_DTC_START_REQ: begin
            enc_msg_code    = 'h85; // Start Rx Init D to C eye sweep req message code
            enc_msg_subcode = 'h0A; // Start Rx Init D to C eye sweep req message subcode
            enc_op_code     = 'b11011; // Data Operation message code
            enc_srcid       = 3'b010; // Physical Layer source ID
            enc_dstid       = 3'b110; // Remote Die Physical Layer destination ID
            enc_dp          = ^i_data_in; // Data Parity (even parity over all data bits)
          end
          RX_INIT_DTC_LFSR_CLR_ERR_RESP: begin
            enc_msg_code    = 'h8A; // LFSR_clear_error resp message code
            enc_msg_subcode = 'h02; // LFSR_clear_error resp message subcode
            enc_op_code     = 'b10010; // No Data Operation message code
            enc_srcid       = 3'b010; // Physical Layer source ID
            enc_dstid       = 3'b110; // Remote Die Physical Layer destination ID
            enc_dp          = 1'b0; // Data Parity (even parity over all data bits)
          end
          RX_INIT_DTC_RESULTS_RESP: begin
            enc_msg_code    = 'h8A; // Rx Init D to C results resp message code
            enc_msg_subcode = 'h0B; // Rx Init D to C results resp message subcode
            enc_op_code     = 'b11011; // Data Operation message code
            enc_srcid       = 3'b010; // Physical Layer source ID
            enc_dstid       = 3'b110; // Remote Die Physical Layer destination ID
            enc_dp          = ^i_data_in; // Data Parity (even parity over all data bits)
          end
          RX_INIT_DTC_END_RESP: begin
            enc_msg_code    = 'h8A; // End Rx Init D to C eye sweep resp message code
            enc_msg_subcode = 'h0D; // End Rx Init D to C eye sweep resp message subcode
            enc_op_code     = 'b10010; // No Data Operation message code
            enc_srcid       = 3'b010; // Physical Layer source ID
            enc_dstid       = 3'b110; // Remote Die Physical Layer destination ID
            enc_dp          = 1'b0; // Data Parity (even parity over all data bits)
          end

          default: begin
            enc_msg_code    = {pMSG_CODE_WIDTH{1'b0}}; // Default message code
            enc_msg_subcode = {pMSG_SUBCODE_WIDTH{1'b0}}; // Default message subcode
            enc_op_code     = 'b10101; // Default Operation message code
            enc_srcid       = 3'b010; // Physical Layer source ID
            enc_dstid       = 3'b110; // Remote Die Physical Layer destination ID
            enc_dp          = 1'b0; // Data Parity (even parity over all data bits)
          end
        endcase

        // Control Parity and Message Construction (calculated once at the end)
        enc_cp      = ^{enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,1'b0,{3{pRESERVED}},
                        enc_dstid,i_info_in,enc_msg_subcode}; // Control Parity (even parity over header fields)
        o_msg_out   = {enc_srcid,{2{pRESERVED}},{5{pRESERVED}},enc_msg_code,{9{pRESERVED}},enc_op_code,enc_dp,enc_cp,{3{pRESERVED}},
                        enc_dstid,i_info_in,enc_msg_subcode,i_data_in}; // Construct message
        o_enc_ready = 1'b1;
        o_done      = 1'b1;
      end
    end
  end // Encoding_proc

 
endmodule