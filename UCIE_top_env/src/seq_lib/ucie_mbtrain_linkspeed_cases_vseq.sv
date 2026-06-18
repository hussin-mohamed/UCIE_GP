//=============================================================================
// File       : ucie_mbtrain_linkspeed_cases_vseq.sv
// Project    : UCIe 3.0 System-Level Verification
// Description: Master virtual sequence for orchestrating the happy path 
//              across the LTSM, Sideband, RX-Path, and TX-Path agents.
//=============================================================================

class ucie_mbtrain_linkspeed_cases_vseq extends ucie_vseq_base;

  `uvm_object_utils(ucie_mbtrain_linkspeed_cases_vseq)
    int i;
  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "ucie_mbtrain_linkspeed_cases_vseq");
    super.new(name);
  endfunction

  // -------------------------------------------------------------------------
  //  Body Task
  // -------------------------------------------------------------------------
  virtual task body();
  if (TRAINERROR_vseq.trainerr_cnt == 0) begin
    TRAINERROR_vseq.configure(.missing_msg_2get(NORMAL));
    valverf_vseq.configure(
        .D2c_mode(SUCCESS),
        .pattern_mode(PAT_ALL_LANES_VALID),
        .data_mode(VALID_PATTERN),
        .info_mode(CORRECT),
        .message_mode(ALL_LANES_VALID),
        .valid_mode(VALID_CORRECT),
        .missing_msg(IDEAL)
    );

    dataverf_vseq.configure(
        .D2c_mode(SUCCESS),
        .pattern_mode(PAT_ALL_LANES_VALID),
        .data_mode(LFSR_PATTERN),
        .info_mode(CORRECT),
        .message_mode(ALL_LANES_VALID),
        .valid_mode(VALID_CORRECT),
        .missing_msg(IDEAL)
    );

    valtraincenter_vseq.configure(
        .D2c_mode(SUCCESS),
        .pattern_mode(PAT_ALL_LANES_VALID),
        .data_mode(VALID_PATTERN),
        .info_mode(CORRECT),
        .message_mode(ALL_LANES_VALID),
        .valid_mode(VALID_CORRECT),
        .trainerror(NOT_TRAINERROR)
    );

    valtrainverf_vseq.configure(
        .D2c_mode(SUCCESS),
        .pattern_mode(PAT_ALL_LANES_VALID),
        .data_mode(VALID_PATTERN),
        .info_mode(CORRECT),
        .message_mode(ALL_LANES_VALID),
        .valid_mode(VALID_CORRECT),
        .trainerror(NOT_TRAINERROR)
    );
    
    DTC1_vseq.configure(
        .D2c_mode(SUCCESS),
        .pattern_mode(PAT_ALL_LANES_VALID),
        .data_mode(LFSR_PATTERN),
        .info_mode(CORRECT),
        .message_mode(ALL_LANES_VALID),
        .valid_mode(VALID_CORRECT)
    );

    datatrainvref_vseq.configure(
        .D2c_mode(SUCCESS),
        .pattern_mode(PAT_ALL_LANES_VALID),
        .data_mode(LFSR_PATTERN),
        .info_mode(CORRECT),
        .message_mode(ALL_LANES_VALID),
        .valid_mode(VALID_CORRECT)
    );

    DTC2_vseq.configure(
        .D2c_mode(SUCCESS),
        .pattern_mode(PAT_ALL_LANES_VALID),
        .data_mode(LFSR_PATTERN),
        .info_mode(CORRECT),
        .message_mode(ALL_LANES_VALID),
        .valid_mode(VALID_CORRECT)
    );

    LINKSPEED_vseq.configure(
        .linkspeed_dest(TRAINERROR)
        ,.pattern_mode(PAT_ALL_LANES_VALID)
        ,.message_mode(ALL_LANES_VALID)
        ,.speed_idle_entry(CURRENT_DIE)
    );
     mbinit_vseq.start(p_sequencer);
     trainerror_rdi_exit_vseq.start(ltsm_rdi_seqr);
     

    valverf_vseq.start(p_sequencer);
    dataverf_vseq.start(p_sequencer);
    for (i =0 ;i < 7 ; i++ ) begin
        if (i!=6) begin
        LINKSPEED_vseq.configure(
        .linkspeed_dest(TRAINERROR)
        ,.pattern_mode(PAT_ALL_LANES_VALID)
        ,.message_mode(ALL_LANES_VALID)
        ,.speed_idle_entry(CURRENT_DIE)
        );
        speedidle_till_linkspeed();
        end
        else begin
            // hashof el speedidle btet3eml ezay
            TRAINERROR_vseq.start(p_sequencer);
        end
    end
  end

  if (TRAINERROR_vseq.trainerr_cnt == 1)begin
    TRAINERROR_vseq.configure(.missing_msg_2get(NORMAL));
    valverf_vseq.configure(
        .D2c_mode(SUCCESS),
        .pattern_mode(PAT_ALL_LANES_VALID),
        .data_mode(VALID_PATTERN),
        .info_mode(CORRECT),
        .message_mode(ALL_LANES_VALID),
        .valid_mode(VALID_CORRECT),
        .missing_msg(IDEAL)
    );

    dataverf_vseq.configure(
        .D2c_mode(SUCCESS),
        .pattern_mode(PAT_ALL_LANES_VALID),
        .data_mode(LFSR_PATTERN),
        .info_mode(CORRECT),
        .message_mode(ALL_LANES_VALID),
        .valid_mode(VALID_CORRECT),
        .missing_msg(IDEAL)
    );

    valtraincenter_vseq.configure(
        .D2c_mode(SUCCESS),
        .pattern_mode(PAT_ALL_LANES_VALID),
        .data_mode(VALID_PATTERN),
        .info_mode(CORRECT),
        .message_mode(ALL_LANES_VALID),
        .valid_mode(VALID_CORRECT),
        .trainerror(NOT_TRAINERROR)
    );

    valtrainverf_vseq.configure(
        .D2c_mode(SUCCESS),
        .pattern_mode(PAT_ALL_LANES_VALID),
        .data_mode(VALID_PATTERN),
        .info_mode(CORRECT),
        .message_mode(ALL_LANES_VALID),
        .valid_mode(VALID_CORRECT),
        .trainerror(NOT_TRAINERROR)
    );
    
    DTC1_vseq.configure(
        .D2c_mode(SUCCESS),
        .pattern_mode(PAT_ALL_LANES_VALID),
        .data_mode(LFSR_PATTERN),
        .info_mode(CORRECT),
        .message_mode(ALL_LANES_VALID),
        .valid_mode(VALID_CORRECT)
    );

    datatrainvref_vseq.configure(
        .D2c_mode(SUCCESS),
        .pattern_mode(PAT_ALL_LANES_VALID),
        .data_mode(LFSR_PATTERN),
        .info_mode(CORRECT),
        .message_mode(ALL_LANES_VALID),
        .valid_mode(VALID_CORRECT)
    );

    DTC2_vseq.configure(
        .D2c_mode(SUCCESS),
        .pattern_mode(PAT_ALL_LANES_VALID),
        .data_mode(LFSR_PATTERN),
        .info_mode(CORRECT),
        .message_mode(ALL_LANES_VALID),
        .valid_mode(VALID_CORRECT)
    );

    LINKSPEED_vseq.configure(
        .linkspeed_dest(SPEEDIDLE)
        ,.pattern_mode(PAT_ALL_LANES_VALID)
        ,.message_mode(ALL_LANES_VALID)
        ,.speed_idle_entry(CURRENT_DIE)
    );
    mbinit_vseq.start(p_sequencer);
    trainerror_rdi_exit_vseq.start(ltsm_rdi_seqr);

    valverf_vseq.start(p_sequencer);
    dataverf_vseq.start(p_sequencer);
    speedidle_till_linkspeed();

    LINKSPEED_vseq.configure(
        .linkspeed_dest(SPEEDIDLE)
        ,.pattern_mode(PAT_ALL_LANES_VALID)
        ,.message_mode(ALL_LANES_VALID)
        ,.speed_idle_entry(OTHER_DIE)
    );
    speedidle_till_linkspeed();

    LINKSPEED_vseq.configure(
        .linkspeed_dest(REPAIR)
        ,.pattern_mode(PAT_LOWER_8_LANES_VALID)
        ,.message_mode(UPPER_8_LANES_VALID)
        ,.speed_idle_entry(OTHER_DIE)
    );
    repair_vseq.configure(
        .lane_map_code(ALL_LANES)
    );

    speedidle_till_linkspeed();
    repair_vseq.start(p_sequencer);

    
    
    LINKSPEED_vseq.configure(
        .linkspeed_dest(REPAIR)
        ,.pattern_mode(PAT_UPPER_8_LANES_VALID)
        ,.message_mode(LOWER_8_LANES_VALID)
        ,.speed_idle_entry(OTHER_DIE)
    );
    repair_vseq.configure(
        .lane_map_code(LOWER_8_LANES)
    );

    txselfcal_till_linkspeed();
    

    LINKSPEED_vseq.configure(
        .linkspeed_dest(REPAIR)
        ,.pattern_mode(PAT_LOWER_8_LANES_VALID)
        ,.message_mode(UPPER_8_LANES_VALID)
        ,.speed_idle_entry(OTHER_DIE)
    );
    repair_vseq.configure(
        .lane_map_code(UPPER_8_LANES)
    );

    txselfcal_till_linkspeed();

    LINKSPEED_vseq.configure(
        .linkspeed_dest(REPAIR)
        ,.pattern_mode(PAT_LOWER_8_LANES_VALID)
        ,.message_mode(UPPER_8_LANES_VALID)
        ,.speed_idle_entry(OTHER_DIE)
    );
    repair_vseq.configure(
        .lane_map_code(NO_LANES)
    );

    txselfcal_till_linkspeed();
    TRAINERROR_vseq.start(p_sequencer);
  end
  if (TRAINERROR_vseq.trainerr_cnt == 2) begin
    mbinit_vseq.start(p_sequencer);
    trainerror_rdi_exit_vseq.start(ltsm_rdi_seqr);
    train_vseq.start(p_sequencer);
  end


  endtask

  task speedidle_till_linkspeed();
        valtraincenter_vseq.configure(
        .D2c_mode(SUCCESS),
        .pattern_mode(PAT_ALL_LANES_VALID),
        .data_mode(VALID_PATTERN),
        .info_mode(CORRECT),
        .message_mode(ALL_LANES_VALID),
        .valid_mode(VALID_CORRECT),
        .trainerror(NOT_TRAINERROR)
    );

    valtrainverf_vseq.configure(
        .D2c_mode(SUCCESS),
        .pattern_mode(PAT_ALL_LANES_VALID),
        .data_mode(VALID_PATTERN),
        .info_mode(CORRECT),
        .message_mode(ALL_LANES_VALID),
        .valid_mode(VALID_CORRECT),
        .trainerror(NOT_TRAINERROR)
    );
    
    DTC1_vseq.configure(
        .D2c_mode(SUCCESS),
        .pattern_mode(PAT_ALL_LANES_VALID),
        .data_mode(LFSR_PATTERN),
        .info_mode(CORRECT),
        .message_mode(ALL_LANES_VALID),
        .valid_mode(VALID_CORRECT)
    );

    datatrainvref_vseq.configure(
        .D2c_mode(SUCCESS),
        .pattern_mode(PAT_ALL_LANES_VALID),
        .data_mode(LFSR_PATTERN),
        .info_mode(CORRECT),
        .message_mode(ALL_LANES_VALID),
        .valid_mode(VALID_CORRECT)
    );

    DTC2_vseq.configure(
        .D2c_mode(SUCCESS),
        .pattern_mode(PAT_ALL_LANES_VALID),
        .data_mode(LFSR_PATTERN),
        .info_mode(CORRECT),
        .message_mode(ALL_LANES_VALID),
        .valid_mode(VALID_CORRECT)
    );
        speedidle_vseq.start(p_sequencer);
        txselfcal_vseq.start(p_sequencer);
        rxclkcal_vseq.start(p_sequencer);
        valtraincenter_vseq.start(p_sequencer);
        valtrainverf_vseq.start(p_sequencer);
        DTC1_vseq.start(p_sequencer);
        datatrainvref_vseq.start(p_sequencer);
        rxdskew_vseq.start(p_sequencer);
        DTC2_vseq.start(p_sequencer);
        LINKSPEED_vseq.start(p_sequencer);
  endtask
  task txselfcal_till_linkspeed();
  valtraincenter_vseq.configure(
        .D2c_mode(SUCCESS),
        .pattern_mode(PAT_ALL_LANES_VALID),
        .data_mode(VALID_PATTERN),
        .info_mode(CORRECT),
        .message_mode(ALL_LANES_VALID),
        .valid_mode(VALID_CORRECT),
        .trainerror(NOT_TRAINERROR)
    );

    valtrainverf_vseq.configure(
        .D2c_mode(SUCCESS),
        .pattern_mode(PAT_ALL_LANES_VALID),
        .data_mode(VALID_PATTERN),
        .info_mode(CORRECT),
        .message_mode(ALL_LANES_VALID),
        .valid_mode(VALID_CORRECT),
        .trainerror(NOT_TRAINERROR)
    );
    
    DTC1_vseq.configure(
        .D2c_mode(SUCCESS),
        .pattern_mode(PAT_ALL_LANES_VALID),
        .data_mode(LFSR_PATTERN),
        .info_mode(CORRECT),
        .message_mode(ALL_LANES_VALID),
        .valid_mode(VALID_CORRECT)
    );

    datatrainvref_vseq.configure(
        .D2c_mode(SUCCESS),
        .pattern_mode(PAT_ALL_LANES_VALID),
        .data_mode(LFSR_PATTERN),
        .info_mode(CORRECT),
        .message_mode(ALL_LANES_VALID),
        .valid_mode(VALID_CORRECT)
    );

    DTC2_vseq.configure(
        .D2c_mode(SUCCESS),
        .pattern_mode(PAT_ALL_LANES_VALID),
        .data_mode(LFSR_PATTERN),
        .info_mode(CORRECT),
        .message_mode(ALL_LANES_VALID),
        .valid_mode(VALID_CORRECT)
    );
        txselfcal_vseq.start(p_sequencer);
        rxclkcal_vseq.start(p_sequencer);
        valtraincenter_vseq.start(p_sequencer);
        valtrainverf_vseq.start(p_sequencer);
        DTC1_vseq.start(p_sequencer);
        datatrainvref_vseq.start(p_sequencer);
        rxdskew_vseq.start(p_sequencer);
        DTC2_vseq.start(p_sequencer);
        LINKSPEED_vseq.start(p_sequencer);
        repair_vseq.start(p_sequencer);
  endtask
endclass : ucie_mbtrain_linkspeed_cases_vseq
