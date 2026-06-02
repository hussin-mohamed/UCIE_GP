//=============================================================================
// File       : ucie_mbtrain_vseq.sv
// Project    : UCIe 3.0 System-Level Verification
// Description: Master virtual sequence for orchestrating the happy path 
//              across the LTSM, Sideband, RX-Path, and TX-Path agents.
//=============================================================================

class ucie_mbtrain_vseq extends ucie_vseq_base;

  `uvm_object_utils(ucie_mbtrain_vseq)

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "ucie_mbtrain_vseq");
    super.new(name);
  endfunction

  // -------------------------------------------------------------------------
  //  Body Task
  // -------------------------------------------------------------------------
  virtual task body();
    ucie_mbtrain_valverf_vseq.configure(
        .D2c_mode(D2c_mode),
        .pattern_mode(pattern_mode),
        .data_mode(data_mode),
        .info_mode(info_mode),
        .message_mode(message_mode),
        .valid_mode(valid_mode)
    );

    ucie_mbtrain_dataverf_vseq.configure(
        .D2c_mode(D2c_mode),
        .pattern_mode(pattern_mode),
        .data_mode(data_mode),
        .info_mode(info_mode),
        .message_mode(message_mode),
        .valid_mode(valid_mode)
    );

    ucie_mbtrain_speedidle_vseq.configure(
        .D2c_mode(D2c_mode),
        .pattern_mode(pattern_mode),
        .data_mode(data_mode),
        .info_mode(info_mode),
        .message_mode(message_mode),
        .valid_mode(valid_mode)
    );

    ucie_mbtrain_txselfcal_vseq.configure(
        .D2c_mode(D2c_mode),
        .pattern_mode(pattern_mode),
        .data_mode(data_mode),
        .info_mode(info_mode),
        .message_mode(message_mode),
        .valid_mode(valid_mode)
    );

    ucie_mbtrain_rxclkcal_vseq.configure(
        .D2c_mode(D2c_mode),
        .pattern_mode(pattern_mode),
        .data_mode(data_mode),
        .info_mode(info_mode),
        .message_mode(message_mode),
        .valid_mode(valid_mode)
    );

    ucie_mbtrain_valtraincenter_vseq.configure(
        .D2c_mode(D2c_mode),
        .pattern_mode(pattern_mode),
        .data_mode(data_mode),
        .info_mode(info_mode),
        .message_mode(message_mode),
        .valid_mode(valid_mode)
    );
    
    ucie_mbtrain_valtrainverf_vseq.configure(
        .D2c_mode(D2c_mode),
        .pattern_mode(pattern_mode),
        .data_mode(data_mode),
        .info_mode(info_mode),
        .message_mode(message_mode),
        .valid_mode(valid_mode)
    );
    
    ucie_mbtrain_DTC1_vseq.configure(
        .D2c_mode(D2c_mode),
        .pattern_mode(pattern_mode),
        .data_mode(data_mode),
        .info_mode(info_mode),
        .message_mode(message_mode),
        .valid_mode(valid_mode)
    );

    ucie_mbtrain_datatrainvref_vseq.configure(
        .D2c_mode(D2c_mode),
        .pattern_mode(pattern_mode),
        .data_mode(data_mode),
        .info_mode(info_mode),
        .message_mode(message_mode),
        .valid_mode(valid_mode)
    );

    ucie_mbtrain_rxdskew_vseq.configure(
        .D2c_mode(D2c_mode),
        .pattern_mode(pattern_mode),
        .data_mode(data_mode),
        .info_mode(info_mode),
        .message_mode(message_mode),
        .valid_mode(valid_mode)
    );

    ucie_mbtrain_DTC2_vseq.configure(
        .D2c_mode(D2c_mode),
        .pattern_mode(pattern_mode),
        .data_mode(data_mode),
        .info_mode(info_mode),
        .message_mode(message_mode),
        .valid_mode(valid_mode)
    );

    ucie_mbtrain_valverf_vseq.start();
    ucie_mbtrain_dataverf_vseq.start();
    ucie_mbtrain_speedidle_vseq.start();
    ucie_mbtrain_txselfcal_vseq.start();
    ucie_mbtrain_rxclkcal_vseq.start();
    ucie_mbtrain_valtraincenter_vseq.start();
    ucie_mbtrain_valtrainverf_vseq.start();
    ucie_mbtrain_DTC1_vseq.start();
    ucie_mbtrain_datatrainvref_vseq.start();
    ucie_mbtrain_rxdskew_vseq.start();
    ucie_mbtrain_DTC2_vseq.start();
    
  endtask
endclass : ucie_mbtrain_vseq
