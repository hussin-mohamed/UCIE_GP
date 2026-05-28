//=============================================================================
// File       : tx_predictor.sv
// Project    : UCIe 3.0 TX Logical PHY Verification
// Description: Golden predictor — controller model only. Takes LTSM encoding
//              + lane_map and produces expected egress output. Receives
//              transactions from both RDI and LTSM monitors.
//
//              Datapath function stubs (LFSR, B2L, lane repair) define
//              clean interfaces for the collaborator to plug in their
//              implementations.
//=============================================================================

  import tx_controller_modelling_pkg::*;
  import B2L_modelling_pkg::*;
  import LFSR_modelling_pkg::*;
  import per_lane_id_modelling_pkg::*;

  class tx_predictor;

    static task  predict (
      ref tx_controller_state_t controller_state,
      input  logic        i_reset,
      input  logic [8:0]  i_tx_encoding,
      input  logic [2:0]  i_lane_map_code,
      input  logic        i_disable,
      input  logic [7:0]  i_lp_data [0:NBYTES-1],
      output logic [B2L_modelling_pkg::DATA_WIDTH-1:0] o_lane [0:B2L_modelling_pkg::LANES_NUMBER-1]
    );

      logic        o_tx_lfsr_enable;
      logic        o_tx_lfsr_load;
      logic        o_tx_lfsr_train;
      // Pattern controls
      logic        o_data_pattern_type;   // 1=LFSR, 0=per-lane-id
      logic [1:0]  o_pattern_type;        // see PAT_* localparams
      // Datapath controls
      logic        o_per_lane_id_gen_enable;
      logic        o_tx_reverse;
      logic        o_tx_done;
      // AFE tri-state enables
      logic        mb_clk_p_en;
      logic        mb_clk_n_en;
      logic        mb_valid_en;
      logic        mb_track_en;
      logic [15:0] mb_lanes_en;
      // RDI interface
      logic        o_pl_trdy;
      logic        o_b2l_enable;
      logic        o_data_sent;

      logic [B2L_modelling_pkg::DATA_WIDTH-1:0] o_lane_b2l [0:B2L_modelling_pkg::LANES_NUMBER-1];
      logic [B2L_modelling_pkg::DATA_WIDTH-1:0] o_lane_lfsr [0:B2L_modelling_pkg::LANES_NUMBER-1];
      logic [B2L_modelling_pkg::DATA_WIDTH-1:0] o_lane_per_lane_id [0:B2L_modelling_pkg::LANES_NUMBER-1];

    tx_controller_modelling(
      controller_state,
      i_reset,
      i_tx_encoding,
      i_lane_map_code,
      o_tx_lfsr_enable,
      o_tx_lfsr_load,
      o_tx_lfsr_train,
      o_per_lane_id_gen_enable,
      o_b2l_enable,
      o_tx_reverse,
      o_tx_done
    );

    B2L_modelling (
      i_lane_map_code,
      i_reset,
      o_b2l_enable,
      i_disable,
      i_lp_data,
      o_lane_b2l,
      o_data_sent
    );

    LFSR_modelling(
      o_lane_b2l,
      o_tx_lfsr_enable,
      i_disable,
      o_tx_lfsr_load,
      o_tx_lfsr_train,
      o_lane_lfsr
    );

    per_lane_id_modelling(
      i_reset,
      o_per_lane_id_gen_enable,
      o_lane_per_lane_id
    );

    if (o_per_lane_id_gen_enable) begin
      o_lane = o_lane_per_lane_id;
    end else if (o_tx_lfsr_enable) begin
      o_lane = o_lane_lfsr;
    end else begin
      o_lane = '{default:0};
    end

    endtask

  endclass : tx_predictor
