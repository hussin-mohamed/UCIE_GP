// ****************************************************************************
// *                                                                          *
// * Copyright (c) 2014-2015 Synopsys Inc. All rights reserved.               *
// *                                                                          *
// * Synopsys Proprietary and Confidential. This file contains confidential   *
// * information and the trade secrets of Synopsys Inc. Use, disclosure, or   *
// * reproduction is prohibited without the prior express written permission  *
// * of Synopsys, Inc.                                                        *
// *                                                                          *
// * Synopsys, Inc.                                                           *
// * 700 East Middlefield Road                                                *
// * Mountain View, California 94043                                          *
// * (800) 541-7737                                                           *
// *                                                                          *
// ****************************************************************************



//------------------------------------------------------------------------------
//
// CLASS: MBTRAIN_test
//
// The MBTRAIN_test class provides common test infrastructure for the
// LTSM verification environment. It handles environment creation, interface
// configuration retrieval, sequence instantiation, and provides phase-based
// hooks for test execution and reporting.
//
//------------------------------------------------------------------------------

class MBTRAIN_test extends uvm_test;
    `uvm_component_utils(MBTRAIN_test)

    LTSM_env env;
    env_config env_cfg;
    uvm_factory factory;
    // sequences to end mbinit
    initialization_success ready;
    // valvref virtual sequences
    mbtrain_valvref_success vref_success;
    mbtrain_valvref_timeout vref_timeout;
    mbtrain_valvref_trainerror vref_trainerror;
    mbtrain_valvref_looptillerror valvref_looptillerror;
    // datavref virtual sequences
    mbtrain_datavref_success datavref_success;
    mbtrain_datavref_timeout datavref_timeout;
    mbtrain_datavref_trainerror datavref_trainerror;
    mbtrain_datavref_looptillerror datavref_looptillerror;
    // speedidle
    mbtrain_datavref_speedidle_tx datavref_speedidle;
    mbtrain_speedidle_tx_endhandshake speedidle_tx_end;
    mbtrain_speedidle_rx_endhandshake speedidle_rx_end;
    // txselfcal
    mbtrain_txselfcal_calibration_tx speedidle_txselfcal;
    mbtrain_txselfcal_tx_endhandshake txselfcal_tx_end;
    mbtrain_txselfcal_rx_endhandshake txselfcal_rx_end;
    // rxclkcal
    mbtrain_rxclkcal_success rxclkcal_success;
    mbtrain_rxclkcal_timeout rxclkcal_timeout;
    mbtrain_rxclkcal_trainerror rxclkcal_trainerror;
    // valtraincenter
    mbtrain_valtraincenter_success valtraincenter_success;
    mbtrain_valtraincenter_timeout valtraincenter_timeout;
    mbtrain_valtraincenter_trainerror valtraincenter_trainerror;
    // valtrainvref
    mbtrain_valtrainvref_success valtrainvref_success;
    mbtrain_valtrainvref_timeout valtrainvref_timeout;
    mbtrain_valtrainvref_trainerror valtrainvref_trainerror;
    mbtrain_valtrainvref_looptillerror valtrainvref_looptillerror;
    // dtc1
    mbtrain_dtc1_success dtc1_success;
    mbtrain_dtc1_timeout dtc1_timeout;
    mbtrain_dtc1_trainerror dtc1_trainerror;
    // datatrainvref
    mbtrain_datatrainvref_success datatrainvref_success;
    mbtrain_datatrainvref_timeout datatrainvref_timeout;
    mbtrain_datatrainvref_trainerror datatrainvref_trainerror;
    mbtrain_datatrainvref_looptillerror datatrainvref_looptillerror;
    // rxdeskew
    mbtrain_rxdeskew_success rxdeskew_success;
    mbtrain_rxdeskew_timeout rxdeskew_timeout;
    mbtrain_rxdeskew_trainerror rxdeskew_trainerror;
    // dtc2
    mbtrain_dtc2_success dtc2_success;
    mbtrain_dtc2_timeout dtc2_timeout;
    mbtrain_dtc2_trainerror dtc2_trainerror;
    // linkspeed and repair
    mbtrain_linkspeed_speeddegrade_rxinit linkspeed_speeddegrade_rxinit;
    mbtrain_linkspeed_speeddegrade_txinit linkspeed_speeddegrade_txinit;
    mbtrain_linkspeed_repair_trainerror  linkspeed_repair_trainerror;
    mbtrain_linkspeed_repair_fail_8_15   linkspeed_repair_fail_8_15;
    mbtrain_linkspeed_repair_fail_4_15   linkspeed_repair_fail_4_15;
    mbtrain_linkspeed_repair_fail_0_7   linkspeed_repair_fail_0_7;
    mbtrain_linkspeed_repair_fail_0_3_8_15   linkspeed_repair_fail_0_3_8_15;
    mbtrain_linkspeed_phyretrain_lanepossible_rxfail linkspeed_phyretrain_lanepossible_rxfail;
    mbtrain_linkspeed_phyretrain_lanepossible_txfail linkspeed_phyretrain_lanepossible_txfail;
    mbtrain_linkspeed_phyretrain_nolanepossible_rxfail linkspeed_phyretrain_nolanepossible_rxfail;
    mbtrain_linkspeed_phyretrain_nolanepossible_txfail linkspeed_phyretrain_nolanepossible_txfail;
    // needed repair sequences
    mbtrain_repair_txselfcal repair_txselfcal;
    mbtrain_repair_tx_endhandshake repair_tx_endhandshake;
    mbtrain_repair_rx_degrade_8_15 repair_rx_degrade_8_15;
    mbtrain_repair_rx_degrade_0_15 repair_rx_degrade_0_15;
    mbtrain_repair_tx_applydegrade repair_tx_applydegrade;
    mbtrain_repair_rx_starthandshake repair_rx_starthandshake;
    mbtrain_repair_rx_endhandshake repair_rx_endhandshake;
    // tx and rx done
    rx_done done_rx;
    tx_done done_tx;
    // controllers done
    controllers_done done;
    // trainerror sequences
    trainerror_rx_starthandshake error_rx;
    trainerror_tx_rsp error_tx_rsp;
    trainerror_rx_rsp error_rx_rsp;
    trainerror_exitreset exit_to_reset;
    // mbtrain success
    mbtrain_success success;

    

    // sequences to exit phyretrain

    // Function: new
    //
    // Creates a new MBTRAIN_test instance and retrieves factory singleton handle.

    extern function new(string name = "MBTRAIN_test", uvm_component parent = null);


    // Function: build_phase
    //
    // Creates environment and configuration objects, retrieves all virtual interfaces
    // from config_db, and publishes configuration to environment.

    extern function void build_phase(uvm_phase phase);


    // Function: end_of_elaboration_phase
    //
    // Creates virtual sequence instance and prints testbench topology.

    extern function void end_of_elaboration_phase(uvm_phase phase);


    // Function: start_of_simulation_phase
    //
    // Prints test start banner message.

    extern function void start_of_simulation_phase(uvm_phase phase);


    // Task: run_phase
    //
    // Raises objection, starts virtual sequence on environment sequencer,
    // and drops objection upon completion.

    extern task run_phase(uvm_phase phase);


    // Function: final_phase
    //
    // Prints factory configuration and test completion banner.

    extern function void final_phase(uvm_phase phase);

endclass : MBTRAIN_test


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- bridge_test_base
//
//------------------------------------------------------------------------------


// new
// ---

function MBTRAIN_test::new(string name = "MBTRAIN_test", uvm_component parent = null);
    super.new(name, parent);
    factory = uvm_factory::get();
endfunction : new

// build_phase
// -----------

function void MBTRAIN_test::build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info("build_phase", "Building MBTRAIN_test and creating environment", UVM_LOW)
    // sequences to end mbinit
    ready =initialization_success::type_id::create("ready", this);
    // Create all virtual sequences
    // valvref virtual sequences
    vref_success = mbtrain_valvref_success::type_id::create("vref_success", this);
    vref_timeout = mbtrain_valvref_timeout::type_id::create("vref_timeout", this);
    vref_trainerror = mbtrain_valvref_trainerror::type_id::create("vref_trainerror", this);
    valvref_looptillerror = mbtrain_valvref_looptillerror::type_id::create("valvref_looptillerror", this);
    
    // datavref virtual sequences
    datavref_success = mbtrain_datavref_success::type_id::create("datavref_success", this);
    datavref_timeout = mbtrain_datavref_timeout::type_id::create("datavref_timeout", this);
    datavref_trainerror = mbtrain_datavref_trainerror::type_id::create("datavref_trainerror", this);
    datavref_looptillerror = mbtrain_datavref_looptillerror::type_id::create("datavref_looptillerror", this);
    
    // speedidle
    datavref_speedidle = mbtrain_datavref_speedidle_tx::type_id::create("datavref_speedidle", this);
    speedidle_tx_end = mbtrain_speedidle_tx_endhandshake::type_id::create("speedidle_tx_end", this);
    speedidle_rx_end = mbtrain_speedidle_rx_endhandshake::type_id::create("speedidle_rx_end", this);
    
    // txselfcal
    speedidle_txselfcal = mbtrain_txselfcal_calibration_tx::type_id::create("speedidle_txselfcal", this);
    txselfcal_tx_end = mbtrain_txselfcal_tx_endhandshake::type_id::create("txselfcal_tx_end", this);
    txselfcal_rx_end = mbtrain_txselfcal_rx_endhandshake::type_id::create("txselfcal_rx_end", this);
    
    // rxclkcal
    rxclkcal_success = mbtrain_rxclkcal_success::type_id::create("rxclkcal_success", this);
    rxclkcal_timeout = mbtrain_rxclkcal_timeout::type_id::create("rxclkcal_timeout", this);
    rxclkcal_trainerror = mbtrain_rxclkcal_trainerror::type_id::create("rxclkcal_trainerror", this);
    
    // valtraincenter
    valtraincenter_success = mbtrain_valtraincenter_success::type_id::create("valtraincenter_success", this);
    valtraincenter_timeout = mbtrain_valtraincenter_timeout::type_id::create("valtraincenter_timeout", this);
    valtraincenter_trainerror = mbtrain_valtraincenter_trainerror::type_id::create("valtraincenter_trainerror", this);
    
    // valtrainvref
    valtrainvref_success = mbtrain_valtrainvref_success::type_id::create("valtrainvref_success", this);
    valtrainvref_timeout = mbtrain_valtrainvref_timeout::type_id::create("valtrainvref_timeout", this);
    valtrainvref_trainerror = mbtrain_valtrainvref_trainerror::type_id::create("valtrainvref_trainerror", this);
    valtrainvref_looptillerror = mbtrain_valtrainvref_looptillerror::type_id::create("valtrainvref_looptillerror", this);
    
    // dtc1
    dtc1_success = mbtrain_dtc1_success::type_id::create("dtc1_success", this);
    dtc1_timeout = mbtrain_dtc1_timeout::type_id::create("dtc1_timeout", this);
    dtc1_trainerror = mbtrain_dtc1_trainerror::type_id::create("dtc1_trainerror", this);
    
    // datatrainvref
    datatrainvref_success = mbtrain_datatrainvref_success::type_id::create("datatrainvref_success", this);
    datatrainvref_timeout = mbtrain_datatrainvref_timeout::type_id::create("datatrainvref_timeout", this);
    datatrainvref_trainerror = mbtrain_datatrainvref_trainerror::type_id::create("datatrainvref_trainerror", this);
    datatrainvref_looptillerror = mbtrain_datatrainvref_looptillerror::type_id::create("datatrainvref_looptillerror", this);
    
    // rxdeskew
    rxdeskew_success = mbtrain_rxdeskew_success::type_id::create("rxdeskew_success", this);
    rxdeskew_timeout = mbtrain_rxdeskew_timeout::type_id::create("rxdeskew_timeout", this);
    rxdeskew_trainerror = mbtrain_rxdeskew_trainerror::type_id::create("rxdeskew_trainerror", this);
    
    // dtc2
    dtc2_success = mbtrain_dtc2_success::type_id::create("dtc2_success", this);
    dtc2_timeout = mbtrain_dtc2_timeout::type_id::create("dtc2_timeout", this);
    dtc2_trainerror = mbtrain_dtc2_trainerror::type_id::create("dtc2_trainerror", this);
    
    // linkspeed and repair
    linkspeed_speeddegrade_rxinit = mbtrain_linkspeed_speeddegrade_rxinit::type_id::create("linkspeed_speeddegrade_rxinit", this);
    linkspeed_speeddegrade_txinit = mbtrain_linkspeed_speeddegrade_txinit::type_id::create("linkspeed_speeddegrade_txinit", this);
    linkspeed_repair_trainerror = mbtrain_linkspeed_repair_trainerror::type_id::create("linkspeed_repair_trainerror", this);
    linkspeed_repair_fail_8_15 = mbtrain_linkspeed_repair_fail_8_15::type_id::create("linkspeed_repair_fail_8_15", this);
    linkspeed_repair_fail_4_15 = mbtrain_linkspeed_repair_fail_4_15::type_id::create("linkspeed_repair_fail_4_15", this);
    linkspeed_repair_fail_0_7 = mbtrain_linkspeed_repair_fail_0_7::type_id::create("linkspeed_repair_fail_0_7", this);
    linkspeed_repair_fail_0_3_8_15 = mbtrain_linkspeed_repair_fail_0_3_8_15::type_id::create("linkspeed_repair_fail_0_3_8_15", this);
    linkspeed_phyretrain_lanepossible_rxfail = mbtrain_linkspeed_phyretrain_lanepossible_rxfail::type_id::create("linkspeed_phyretrain_lanepossible_rxfail", this);
    linkspeed_phyretrain_lanepossible_txfail = mbtrain_linkspeed_phyretrain_lanepossible_txfail::type_id::create("linkspeed_phyretrain_lanepossible_txfail", this);
    linkspeed_phyretrain_nolanepossible_rxfail = mbtrain_linkspeed_phyretrain_nolanepossible_rxfail::type_id::create("linkspeed_phyretrain_nolanepossible_rxfail", this);
    linkspeed_phyretrain_nolanepossible_txfail = mbtrain_linkspeed_phyretrain_nolanepossible_txfail::type_id::create("linkspeed_phyretrain_nolanepossible_txfail", this);
    
    // needed repair sequences
    repair_txselfcal = mbtrain_repair_txselfcal::type_id::create("repair_txselfcal", this);
    repair_tx_endhandshake = mbtrain_repair_tx_endhandshake::type_id::create("repair_tx_endhandshake", this);
    repair_rx_degrade_8_15 = mbtrain_repair_rx_degrade_8_15::type_id::create("repair_rx_degrade_8_15", this);
    repair_rx_degrade_0_15 = mbtrain_repair_rx_degrade_0_15::type_id::create("repair_rx_degrade_0_15", this);
    repair_tx_applydegrade = mbtrain_repair_tx_applydegrade::type_id::create("repair_tx_applydegrade", this);
    repair_rx_starthandshake = mbtrain_repair_rx_starthandshake::type_id::create("repair_rx_starthandshake", this);
    repair_rx_endhandshake = mbtrain_repair_rx_endhandshake::type_id::create("repair_rx_endhandshake", this);
    
    //tx and rx done
    done_tx=tx_done::type_id::create("done_tx", this);
    done_rx=rx_done::type_id::create("done_rx", this);

    // controllers done
    done= controllers_done::type_id::create("done", this);
    // trainerror sequences
    error_rx = trainerror_rx_starthandshake::type_id::create("error_rx", this);
    error_tx_rsp = trainerror_tx_rsp::type_id::create("error_tx_rsp", this);
    error_rx_rsp = trainerror_rx_rsp::type_id::create("error_rx_rsp", this);
    exit_to_reset = trainerror_exitreset::type_id::create("exit_to_reset", this);

    // mbtrain success
    success = mbtrain_success::type_id::create("success", this);

    // sequences to exit phyretrain


    env = LTSM_env::type_id::create("env", this);
    env_cfg = env_config::type_id::create("env_cfg", this);

    if(!uvm_config_db#(virtual TX_FSM_SB)::get(this, "",       "TX_FSM_SB",        env_cfg.tx_fsm_sb_if))
        `uvm_fatal("build_phase", "TEST - Unable to get the TX_FSM_SB from the uvm_config_db")

    if(!uvm_config_db#(virtual RX_FSM_SB)::get(this, "",       "RX_FSM_SB",        env_cfg.rx_fsm_sb_if))
        `uvm_fatal("build_phase", "TEST - Unable to get the RX_FSM_SB from the uvm_config_db")

    if(!uvm_config_db#(virtual LTSM_controllers_if)::get(this, "", "LTSM_CONTROLLERS_IF", env_cfg.vif))
        `uvm_fatal("build_phase", "TEST - Unable to get the LTSM_CONTROLLERS_IF from the uvm_config_db")

    if(!uvm_config_db#(virtual ltsm_rdi_if)::get(this, "",           "ltsm_rdi_vif",          env_cfg.ltsm_rdi_vif))
        `uvm_fatal("build_phase", "TEST - Unable to get the ltsm_rdi_vif from the uvm_config_db")

    uvm_config_db#(env_config)::set(this, "env", "ENV_CFG", env_cfg);
    `uvm_info("build_phase", "Building MBTRAIN_test and creating environment has finished", UVM_LOW)
endfunction : build_phase

// end_of_elaboration_phase
// -------------------------

function void MBTRAIN_test::end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    `uvm_info("end_of_elaboration_phase", "Creating virtual sequence instances and printing testbench topology", UVM_LOW)
    uvm_top.print_topology(); // Prints entire testbench hierarchy 
endfunction : end_of_elaboration_phase

// start_of_simulation_phase
// --------------------------

function void MBTRAIN_test::start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);
    
    `uvm_info("start_of_simulation_phase", $sformatf("=============== Start of %s ===============", this.get_type_name()), UVM_MEDIUM)
endfunction : start_of_simulation_phase

// run_phase
// ---------

task MBTRAIN_test::run_phase(uvm_phase phase);
    super.run_phase(phase);

    phase.raise_objection(this);
    
    // from reset to mbinit
     ready.start(env.v_seqr);
    // mbtrain sequences

    `uvm_info(get_type_name(), $sformatf("mbrain sequences have started"), UVM_MEDIUM)

    // valvref sequences

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", vref_timeout.get_type_name()), UVM_MEDIUM)
    vref_timeout.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", vref_timeout.get_type_name()), UVM_MEDIUM)

    // from reset to mbinit
     ready.start(env.v_seqr); 

    
    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", vref_trainerror.get_type_name()), UVM_MEDIUM)
    vref_trainerror.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", vref_trainerror.get_type_name()), UVM_MEDIUM)

    // from reset to mbinit
     ready.start(env.v_seqr);

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", valvref_looptillerror.get_type_name()), UVM_MEDIUM)
    valvref_looptillerror.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", valvref_looptillerror.get_type_name()), UVM_MEDIUM)

    // from reset to mbinit
     ready.start(env.v_seqr); 

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", vref_success.get_type_name()), UVM_MEDIUM)
    vref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", vref_success.get_type_name()), UVM_MEDIUM)

    // datavref sequences 
    
    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", datavref_timeout.get_type_name()), UVM_MEDIUM)
    datavref_timeout.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", datavref_timeout.get_type_name()), UVM_MEDIUM)

    // from reset to mbinit
     ready.start(env.v_seqr); 


    // reenter datavref
    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", vref_success.get_type_name()), UVM_MEDIUM)
    vref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", vref_success.get_type_name()), UVM_MEDIUM)
    

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", datavref_trainerror.get_type_name()), UVM_MEDIUM)
    datavref_trainerror.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", datavref_trainerror.get_type_name()), UVM_MEDIUM)

    // from reset to mbinit
     ready.start(env.v_seqr); 


    // reenter datavref
    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", vref_success.get_type_name()), UVM_MEDIUM)
    vref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", vref_success.get_type_name()), UVM_MEDIUM)
    

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", datavref_looptillerror.get_type_name()), UVM_MEDIUM)
    datavref_looptillerror.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", datavref_looptillerror.get_type_name()), UVM_MEDIUM)

    // from reset to mbinit
     ready.start(env.v_seqr); 

    // reenter datavref
    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", vref_success.get_type_name()), UVM_MEDIUM)
    vref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", vref_success.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", datavref_success.get_type_name()), UVM_MEDIUM)
    datavref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", datavref_success.get_type_name()), UVM_MEDIUM)

    // speedidle sequences

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", datavref_speedidle.get_type_name()), UVM_MEDIUM)
    datavref_speedidle.start(env.tx_agent.seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", datavref_speedidle.get_type_name()), UVM_MEDIUM)

    fork
        begin
             `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_tx_end.get_type_name()), UVM_MEDIUM)
             done_tx.start(env.tx_agent.seqr);
             `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_tx_end.get_type_name()), UVM_MEDIUM)
        end
        begin
             `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_rx_end.get_type_name()), UVM_MEDIUM)
             fork
               speedidle_rx_end.start(env.rx_agent.seqr);
               done.start(env.LTSM_ctrl_agt.seqr);
             join
             `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_rx_end.get_type_name()), UVM_MEDIUM)
        end
    join

    // tx selfcal sequences
    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_txselfcal.get_type_name()), UVM_MEDIUM)
    speedidle_txselfcal.start(env.tx_agent.seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_txselfcal.get_type_name()), UVM_MEDIUM)

    fork
        begin
             `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", txselfcal_tx_end.get_type_name()), UVM_MEDIUM)
             done_tx.start(env.tx_agent.seqr);
             `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", txselfcal_tx_end.get_type_name()), UVM_MEDIUM)
        end
        begin
          fork
               begin
                    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", txselfcal_rx_end.get_type_name()), UVM_MEDIUM)
                    txselfcal_rx_end.start(env.rx_agent.seqr);
                    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", txselfcal_rx_end.get_type_name()), UVM_MEDIUM)
               end
               begin
               done.start(env.LTSM_ctrl_agt.seqr);
               end
          join
        end
    join

    // rxclkcal sequences
    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", rxclkcal_timeout.get_type_name()), UVM_MEDIUM)
    rxclkcal_timeout.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", rxclkcal_timeout.get_type_name()), UVM_MEDIUM)

    // from reset to mbinit
     ready.start(env.v_seqr);

    // re enter rxclkcal
    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", vref_success.get_type_name()), UVM_MEDIUM)
    vref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", vref_success.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", datavref_success.get_type_name()), UVM_MEDIUM)
    datavref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", datavref_success.get_type_name()), UVM_MEDIUM)

     `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", datavref_speedidle.get_type_name()), UVM_MEDIUM)
    datavref_speedidle.start(env.tx_agent.seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", datavref_speedidle.get_type_name()), UVM_MEDIUM)

    fork
        begin
             `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_tx_end.get_type_name()), UVM_MEDIUM)
             done_tx.start(env.tx_agent.seqr);
             `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_tx_end.get_type_name()), UVM_MEDIUM)
        end
        begin
             `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_rx_end.get_type_name()), UVM_MEDIUM)
             fork
               speedidle_rx_end.start(env.rx_agent.seqr);
               done.start(env.LTSM_ctrl_agt.seqr);
             join
             `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_rx_end.get_type_name()), UVM_MEDIUM)
        end
    join

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_txselfcal.get_type_name()), UVM_MEDIUM)
    speedidle_txselfcal.start(env.tx_agent.seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_txselfcal.get_type_name()), UVM_MEDIUM)

    fork
        begin
             `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", txselfcal_tx_end.get_type_name()), UVM_MEDIUM)
             done_tx.start(env.tx_agent.seqr);
             `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", txselfcal_tx_end.get_type_name()), UVM_MEDIUM)
        end
        begin
          fork
               begin
                    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", txselfcal_rx_end.get_type_name()), UVM_MEDIUM)
                    txselfcal_rx_end.start(env.rx_agent.seqr);
                    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", txselfcal_rx_end.get_type_name()), UVM_MEDIUM)
               end
               begin
               done.start(env.LTSM_ctrl_agt.seqr);
               end
          join
        end
    join

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", rxclkcal_trainerror.get_type_name()), UVM_MEDIUM)
    rxclkcal_trainerror.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", rxclkcal_trainerror.get_type_name()), UVM_MEDIUM)

    // from reset to mbinit
     ready.start(env.v_seqr);

    // re enter rxclkcal
    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", vref_success.get_type_name()), UVM_MEDIUM)
    vref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", vref_success.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", datavref_success.get_type_name()), UVM_MEDIUM)
    datavref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", datavref_success.get_type_name()), UVM_MEDIUM)

     `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", datavref_speedidle.get_type_name()), UVM_MEDIUM)
    datavref_speedidle.start(env.tx_agent.seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", datavref_speedidle.get_type_name()), UVM_MEDIUM)

    fork
        begin
             `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_tx_end.get_type_name()), UVM_MEDIUM)
             done_tx.start(env.tx_agent.seqr);
             `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_tx_end.get_type_name()), UVM_MEDIUM)
        end
        begin
             `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_rx_end.get_type_name()), UVM_MEDIUM)
             fork
               speedidle_rx_end.start(env.rx_agent.seqr);
               done.start(env.LTSM_ctrl_agt.seqr);
             join
             `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_rx_end.get_type_name()), UVM_MEDIUM)
        end
    join

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_txselfcal.get_type_name()), UVM_MEDIUM)
    speedidle_txselfcal.start(env.tx_agent.seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_txselfcal.get_type_name()), UVM_MEDIUM)

    fork
        begin
             `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", txselfcal_tx_end.get_type_name()), UVM_MEDIUM)
             done_tx.start(env.tx_agent.seqr);
             `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", txselfcal_tx_end.get_type_name()), UVM_MEDIUM)
        end
        begin
          fork
               begin
                    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", txselfcal_rx_end.get_type_name()), UVM_MEDIUM)
                    txselfcal_rx_end.start(env.rx_agent.seqr);
                    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", txselfcal_rx_end.get_type_name()), UVM_MEDIUM)
               end
               begin
               done.start(env.LTSM_ctrl_agt.seqr);
               end
          join
        end
    join

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", rxclkcal_success.get_type_name()), UVM_MEDIUM)
    rxclkcal_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", rxclkcal_success.get_type_name()), UVM_MEDIUM)

    // valtraincenter sequences 

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", valtraincenter_timeout.get_type_name()), UVM_MEDIUM)
    valtraincenter_timeout.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", valtraincenter_timeout.get_type_name()), UVM_MEDIUM)

    // from reset to mbinit
     ready.start(env.v_seqr);

    // re enter valtraincenter
    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", vref_success.get_type_name()), UVM_MEDIUM)
    vref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", vref_success.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", datavref_success.get_type_name()), UVM_MEDIUM)
    datavref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", datavref_success.get_type_name()), UVM_MEDIUM)

     `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", datavref_speedidle.get_type_name()), UVM_MEDIUM)
    datavref_speedidle.start(env.tx_agent.seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", datavref_speedidle.get_type_name()), UVM_MEDIUM)

    fork
        begin
             `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_tx_end.get_type_name()), UVM_MEDIUM)
             done_tx.start(env.tx_agent.seqr);
             `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_tx_end.get_type_name()), UVM_MEDIUM)
        end
        begin
             `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_rx_end.get_type_name()), UVM_MEDIUM)
             fork
               speedidle_rx_end.start(env.rx_agent.seqr);
               done.start(env.LTSM_ctrl_agt.seqr);
             join
             `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_rx_end.get_type_name()), UVM_MEDIUM)
        end
    join

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_txselfcal.get_type_name()), UVM_MEDIUM)
    speedidle_txselfcal.start(env.tx_agent.seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_txselfcal.get_type_name()), UVM_MEDIUM)

    fork
        begin
             `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", txselfcal_tx_end.get_type_name()), UVM_MEDIUM)
             done_tx.start(env.tx_agent.seqr);
             `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", txselfcal_tx_end.get_type_name()), UVM_MEDIUM)
        end
        begin
          fork
               begin
                    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", txselfcal_rx_end.get_type_name()), UVM_MEDIUM)
                    txselfcal_rx_end.start(env.rx_agent.seqr);
                    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", txselfcal_rx_end.get_type_name()), UVM_MEDIUM)
               end
               begin
               done.start(env.LTSM_ctrl_agt.seqr);
               end
          join
        end
    join

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", rxclkcal_success.get_type_name()), UVM_MEDIUM)
    rxclkcal_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", rxclkcal_success.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", valtraincenter_trainerror.get_type_name()), UVM_MEDIUM)
    valtraincenter_trainerror.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", valtraincenter_trainerror.get_type_name()), UVM_MEDIUM)

    // from reset to mbinit
     ready.start(env.v_seqr);

    // re enter valtraincenter
    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", vref_success.get_type_name()), UVM_MEDIUM)
    vref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", vref_success.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", datavref_success.get_type_name()), UVM_MEDIUM)
    datavref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", datavref_success.get_type_name()), UVM_MEDIUM)

     `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", datavref_speedidle.get_type_name()), UVM_MEDIUM)
    datavref_speedidle.start(env.tx_agent.seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", datavref_speedidle.get_type_name()), UVM_MEDIUM)

    fork
        begin
             `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_tx_end.get_type_name()), UVM_MEDIUM)
             done_tx.start(env.tx_agent.seqr);
             `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_tx_end.get_type_name()), UVM_MEDIUM)
        end
        begin
             `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_rx_end.get_type_name()), UVM_MEDIUM)
             fork
               speedidle_rx_end.start(env.rx_agent.seqr);
               done.start(env.LTSM_ctrl_agt.seqr);
             join
             `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_rx_end.get_type_name()), UVM_MEDIUM)
        end
    join

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_txselfcal.get_type_name()), UVM_MEDIUM)
    speedidle_txselfcal.start(env.tx_agent.seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_txselfcal.get_type_name()), UVM_MEDIUM)

    fork
        begin
             `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", txselfcal_tx_end.get_type_name()), UVM_MEDIUM)
             done_tx.start(env.tx_agent.seqr);
             `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", txselfcal_tx_end.get_type_name()), UVM_MEDIUM)
        end
        begin
          fork
               begin
                    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", txselfcal_rx_end.get_type_name()), UVM_MEDIUM)
                    txselfcal_rx_end.start(env.rx_agent.seqr);
                    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", txselfcal_rx_end.get_type_name()), UVM_MEDIUM)
               end
               begin
               done.start(env.LTSM_ctrl_agt.seqr);
               end
          join
        end
    join

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", rxclkcal_success.get_type_name()), UVM_MEDIUM)
    rxclkcal_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", rxclkcal_success.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", valtraincenter_success.get_type_name()), UVM_MEDIUM)
    valtraincenter_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", valtraincenter_success.get_type_name()), UVM_MEDIUM)

    // valtrainvref sequences

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", valtrainvref_timeout.get_type_name()), UVM_MEDIUM)
    valtrainvref_timeout.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", valtrainvref_timeout.get_type_name()), UVM_MEDIUM)

    // from reset to mbinit
     ready.start(env.v_seqr);

    // re enter valtrainvref
    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", vref_success.get_type_name()), UVM_MEDIUM)
    vref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", vref_success.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", datavref_success.get_type_name()), UVM_MEDIUM)
    datavref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", datavref_success.get_type_name()), UVM_MEDIUM)

     `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", datavref_speedidle.get_type_name()), UVM_MEDIUM)
    datavref_speedidle.start(env.tx_agent.seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", datavref_speedidle.get_type_name()), UVM_MEDIUM)

    fork
        begin
             `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_tx_end.get_type_name()), UVM_MEDIUM)
             done_tx.start(env.tx_agent.seqr);
             `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_tx_end.get_type_name()), UVM_MEDIUM)
        end
        begin
             `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_rx_end.get_type_name()), UVM_MEDIUM)
             fork
               speedidle_rx_end.start(env.rx_agent.seqr);
               done.start(env.LTSM_ctrl_agt.seqr);
             join
             `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_rx_end.get_type_name()), UVM_MEDIUM)
        end
    join

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_txselfcal.get_type_name()), UVM_MEDIUM)
    speedidle_txselfcal.start(env.tx_agent.seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_txselfcal.get_type_name()), UVM_MEDIUM)

    fork
        begin
             `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", txselfcal_tx_end.get_type_name()), UVM_MEDIUM)
             done_tx.start(env.tx_agent.seqr);
             `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", txselfcal_tx_end.get_type_name()), UVM_MEDIUM)
        end
        begin
          fork
               begin
                    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", txselfcal_rx_end.get_type_name()), UVM_MEDIUM)
                    txselfcal_rx_end.start(env.rx_agent.seqr);
                    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", txselfcal_rx_end.get_type_name()), UVM_MEDIUM)
               end
               begin
               done.start(env.LTSM_ctrl_agt.seqr);
               end
          join
        end
    join

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", rxclkcal_success.get_type_name()), UVM_MEDIUM)
    rxclkcal_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", rxclkcal_success.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", valtraincenter_success.get_type_name()), UVM_MEDIUM)
    valtraincenter_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", valtraincenter_success.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", valtrainvref_trainerror.get_type_name()), UVM_MEDIUM)
    valtrainvref_trainerror.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", valtrainvref_trainerror.get_type_name()), UVM_MEDIUM)

    // from reset to mbinit
     ready.start(env.v_seqr);

    // re enter valtrainvref
    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", vref_success.get_type_name()), UVM_MEDIUM)
    vref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", vref_success.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", datavref_success.get_type_name()), UVM_MEDIUM)
    datavref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", datavref_success.get_type_name()), UVM_MEDIUM)

     `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", datavref_speedidle.get_type_name()), UVM_MEDIUM)
    datavref_speedidle.start(env.tx_agent.seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", datavref_speedidle.get_type_name()), UVM_MEDIUM)

    fork
        begin
             `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_tx_end.get_type_name()), UVM_MEDIUM)
             done_tx.start(env.tx_agent.seqr);
             `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_tx_end.get_type_name()), UVM_MEDIUM)
        end
        begin
             `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_rx_end.get_type_name()), UVM_MEDIUM)
             fork
               speedidle_rx_end.start(env.rx_agent.seqr);
               done.start(env.LTSM_ctrl_agt.seqr);
             join
             `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_rx_end.get_type_name()), UVM_MEDIUM)
        end
    join

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_txselfcal.get_type_name()), UVM_MEDIUM)
    speedidle_txselfcal.start(env.tx_agent.seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_txselfcal.get_type_name()), UVM_MEDIUM)

    fork
        begin
             `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", txselfcal_tx_end.get_type_name()), UVM_MEDIUM)
             done_tx.start(env.tx_agent.seqr);
             `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", txselfcal_tx_end.get_type_name()), UVM_MEDIUM)
        end
        begin
          fork
               begin
                    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", txselfcal_rx_end.get_type_name()), UVM_MEDIUM)
                    txselfcal_rx_end.start(env.rx_agent.seqr);
                    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", txselfcal_rx_end.get_type_name()), UVM_MEDIUM)
               end
               begin
               done.start(env.LTSM_ctrl_agt.seqr);
               end
          join
        end
    join

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", rxclkcal_success.get_type_name()), UVM_MEDIUM)
    rxclkcal_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", rxclkcal_success.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", valtraincenter_success.get_type_name()), UVM_MEDIUM)
    valtraincenter_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", valtraincenter_success.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", valtrainvref_looptillerror.get_type_name()), UVM_MEDIUM)
    valtrainvref_looptillerror.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", valtrainvref_looptillerror.get_type_name()), UVM_MEDIUM)

    // from reset to mbinit
     ready.start(env.v_seqr);

    // re enter valtrainvref
    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", vref_success.get_type_name()), UVM_MEDIUM)
    vref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", vref_success.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", datavref_success.get_type_name()), UVM_MEDIUM)
    datavref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", datavref_success.get_type_name()), UVM_MEDIUM)

     `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", datavref_speedidle.get_type_name()), UVM_MEDIUM)
    datavref_speedidle.start(env.tx_agent.seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", datavref_speedidle.get_type_name()), UVM_MEDIUM)

    fork
        begin
             `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_tx_end.get_type_name()), UVM_MEDIUM)
             done_tx.start(env.tx_agent.seqr);
             `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_tx_end.get_type_name()), UVM_MEDIUM)
        end
        begin
             `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_rx_end.get_type_name()), UVM_MEDIUM)
             fork
               speedidle_rx_end.start(env.rx_agent.seqr);
               done.start(env.LTSM_ctrl_agt.seqr);
             join
             `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_rx_end.get_type_name()), UVM_MEDIUM)
        end
    join

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_txselfcal.get_type_name()), UVM_MEDIUM)
    speedidle_txselfcal.start(env.tx_agent.seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_txselfcal.get_type_name()), UVM_MEDIUM)

    fork
        begin
             `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", txselfcal_tx_end.get_type_name()), UVM_MEDIUM)
             done_tx.start(env.tx_agent.seqr);
             `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", txselfcal_tx_end.get_type_name()), UVM_MEDIUM)
        end
        begin
          fork
               begin
                    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", txselfcal_rx_end.get_type_name()), UVM_MEDIUM)
                    txselfcal_rx_end.start(env.rx_agent.seqr);
                    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", txselfcal_rx_end.get_type_name()), UVM_MEDIUM)
               end
               begin
               done.start(env.LTSM_ctrl_agt.seqr);
               end
          join
        end
    join

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", rxclkcal_success.get_type_name()), UVM_MEDIUM)
    rxclkcal_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", rxclkcal_success.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", valtraincenter_success.get_type_name()), UVM_MEDIUM)
    valtraincenter_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", valtraincenter_success.get_type_name()), UVM_MEDIUM) 

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", valtrainvref_success.get_type_name()), UVM_MEDIUM)
    valtrainvref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", valtrainvref_success.get_type_name()), UVM_MEDIUM)

    // dtc1 sequences

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", dtc1_timeout.get_type_name()), UVM_MEDIUM)
    dtc1_timeout.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", dtc1_timeout.get_type_name()), UVM_MEDIUM)

    // from reset to mbinit
     ready.start(env.v_seqr);

    // re enter dtc1
    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", vref_success.get_type_name()), UVM_MEDIUM)
    vref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", vref_success.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", datavref_success.get_type_name()), UVM_MEDIUM)
    datavref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", datavref_success.get_type_name()), UVM_MEDIUM)

     `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", datavref_speedidle.get_type_name()), UVM_MEDIUM)
    datavref_speedidle.start(env.tx_agent.seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", datavref_speedidle.get_type_name()), UVM_MEDIUM)

    fork
        begin
             `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_tx_end.get_type_name()), UVM_MEDIUM)
             done_tx.start(env.tx_agent.seqr);
             `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_tx_end.get_type_name()), UVM_MEDIUM)
        end
        begin
             `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_rx_end.get_type_name()), UVM_MEDIUM)
             fork
               speedidle_rx_end.start(env.rx_agent.seqr);
               done.start(env.LTSM_ctrl_agt.seqr);
             join
             `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_rx_end.get_type_name()), UVM_MEDIUM)
        end
    join

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_txselfcal.get_type_name()), UVM_MEDIUM)
    speedidle_txselfcal.start(env.tx_agent.seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_txselfcal.get_type_name()), UVM_MEDIUM)

    fork
        begin
             `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", txselfcal_tx_end.get_type_name()), UVM_MEDIUM)
             done_tx.start(env.tx_agent.seqr);
             `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", txselfcal_tx_end.get_type_name()), UVM_MEDIUM)
        end
        begin
          fork
               begin
                    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", txselfcal_rx_end.get_type_name()), UVM_MEDIUM)
                    txselfcal_rx_end.start(env.rx_agent.seqr);
                    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", txselfcal_rx_end.get_type_name()), UVM_MEDIUM)
               end
               begin
               done.start(env.LTSM_ctrl_agt.seqr);
               end
          join
        end
    join

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", rxclkcal_success.get_type_name()), UVM_MEDIUM)
    rxclkcal_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", rxclkcal_success.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", valtraincenter_success.get_type_name()), UVM_MEDIUM)
    valtraincenter_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", valtraincenter_success.get_type_name()), UVM_MEDIUM) 

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", valtrainvref_success.get_type_name()), UVM_MEDIUM)
    valtrainvref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", valtrainvref_success.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", dtc1_trainerror.get_type_name()), UVM_MEDIUM)
    dtc1_trainerror.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", dtc1_trainerror.get_type_name()), UVM_MEDIUM)

    // from reset to mbinit
     ready.start(env.v_seqr);

    // re enter dtc1
    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", vref_success.get_type_name()), UVM_MEDIUM)
    vref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", vref_success.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", datavref_success.get_type_name()), UVM_MEDIUM)
    datavref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", datavref_success.get_type_name()), UVM_MEDIUM)

     `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", datavref_speedidle.get_type_name()), UVM_MEDIUM)
    datavref_speedidle.start(env.tx_agent.seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", datavref_speedidle.get_type_name()), UVM_MEDIUM)

    fork
        begin
             `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_tx_end.get_type_name()), UVM_MEDIUM)
             done_tx.start(env.tx_agent.seqr);
             `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_tx_end.get_type_name()), UVM_MEDIUM)
        end
        begin
             `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_rx_end.get_type_name()), UVM_MEDIUM)
             fork
               speedidle_rx_end.start(env.rx_agent.seqr);
               done.start(env.LTSM_ctrl_agt.seqr);
             join
             `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_rx_end.get_type_name()), UVM_MEDIUM)
        end
    join

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_txselfcal.get_type_name()), UVM_MEDIUM)
    speedidle_txselfcal.start(env.tx_agent.seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_txselfcal.get_type_name()), UVM_MEDIUM)

    fork
        begin
             `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", txselfcal_tx_end.get_type_name()), UVM_MEDIUM)
             done_tx.start(env.tx_agent.seqr);
             `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", txselfcal_tx_end.get_type_name()), UVM_MEDIUM)
        end
        begin
          fork
               begin
                    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", txselfcal_rx_end.get_type_name()), UVM_MEDIUM)
                    txselfcal_rx_end.start(env.rx_agent.seqr);
                    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", txselfcal_rx_end.get_type_name()), UVM_MEDIUM)
               end
               begin
               done.start(env.LTSM_ctrl_agt.seqr);
               end
          join
        end
    join

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", rxclkcal_success.get_type_name()), UVM_MEDIUM)
    rxclkcal_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", rxclkcal_success.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", valtraincenter_success.get_type_name()), UVM_MEDIUM)
    valtraincenter_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", valtraincenter_success.get_type_name()), UVM_MEDIUM) 

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", valtrainvref_success.get_type_name()), UVM_MEDIUM)
    valtrainvref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", valtrainvref_success.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", dtc1_success.get_type_name()), UVM_MEDIUM)
    dtc1_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", dtc1_success.get_type_name()), UVM_MEDIUM)

    // datatrainvref sequences 

     `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", datatrainvref_timeout.get_type_name()), UVM_MEDIUM)
    datatrainvref_timeout.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", datatrainvref_timeout.get_type_name()), UVM_MEDIUM)

    // from reset to mbinit
     ready.start(env.v_seqr);

    // re enter datatrainvref
    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", vref_success.get_type_name()), UVM_MEDIUM)
    vref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", vref_success.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", datavref_success.get_type_name()), UVM_MEDIUM)
    datavref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", datavref_success.get_type_name()), UVM_MEDIUM)

     `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", datavref_speedidle.get_type_name()), UVM_MEDIUM)
    datavref_speedidle.start(env.tx_agent.seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", datavref_speedidle.get_type_name()), UVM_MEDIUM)

    fork
        begin
             `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_tx_end.get_type_name()), UVM_MEDIUM)
             done_tx.start(env.tx_agent.seqr);
             `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_tx_end.get_type_name()), UVM_MEDIUM)
        end
        begin
             `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_rx_end.get_type_name()), UVM_MEDIUM)
             fork
               speedidle_rx_end.start(env.rx_agent.seqr);
               done.start(env.LTSM_ctrl_agt.seqr);
             join
             `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_rx_end.get_type_name()), UVM_MEDIUM)
        end
    join

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_txselfcal.get_type_name()), UVM_MEDIUM)
    speedidle_txselfcal.start(env.tx_agent.seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_txselfcal.get_type_name()), UVM_MEDIUM)

    fork
        begin
             `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", txselfcal_tx_end.get_type_name()), UVM_MEDIUM)
             done_tx.start(env.tx_agent.seqr);
             `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", txselfcal_tx_end.get_type_name()), UVM_MEDIUM)
        end
        begin
          fork
               begin
                    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", txselfcal_rx_end.get_type_name()), UVM_MEDIUM)
                    txselfcal_rx_end.start(env.rx_agent.seqr);
                    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", txselfcal_rx_end.get_type_name()), UVM_MEDIUM)
               end
               begin
               done.start(env.LTSM_ctrl_agt.seqr);
               end
          join
        end
    join

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", rxclkcal_success.get_type_name()), UVM_MEDIUM)
    rxclkcal_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", rxclkcal_success.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", valtraincenter_success.get_type_name()), UVM_MEDIUM)
    valtraincenter_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", valtraincenter_success.get_type_name()), UVM_MEDIUM) 

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", valtrainvref_success.get_type_name()), UVM_MEDIUM)
    valtrainvref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", valtrainvref_success.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", dtc1_success.get_type_name()), UVM_MEDIUM)
    dtc1_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", dtc1_success.get_type_name()), UVM_MEDIUM)
 

    
    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", datatrainvref_trainerror.get_type_name()), UVM_MEDIUM)
    datatrainvref_trainerror.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", datatrainvref_trainerror.get_type_name()), UVM_MEDIUM)

    // from reset to mbinit
     ready.start(env.v_seqr);

    // re enter datatrainvref
    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", vref_success.get_type_name()), UVM_MEDIUM)
    vref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", vref_success.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", datavref_success.get_type_name()), UVM_MEDIUM)
    datavref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", datavref_success.get_type_name()), UVM_MEDIUM)

     `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", datavref_speedidle.get_type_name()), UVM_MEDIUM)
    datavref_speedidle.start(env.tx_agent.seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", datavref_speedidle.get_type_name()), UVM_MEDIUM)

    fork
        begin
             `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_tx_end.get_type_name()), UVM_MEDIUM)
             done_tx.start(env.tx_agent.seqr);
             `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_tx_end.get_type_name()), UVM_MEDIUM)
        end
        begin
             `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_rx_end.get_type_name()), UVM_MEDIUM)
             fork
               speedidle_rx_end.start(env.rx_agent.seqr);
               done.start(env.LTSM_ctrl_agt.seqr);
             join
             `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_rx_end.get_type_name()), UVM_MEDIUM)
        end
    join

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_txselfcal.get_type_name()), UVM_MEDIUM)
    speedidle_txselfcal.start(env.tx_agent.seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_txselfcal.get_type_name()), UVM_MEDIUM)

    fork
        begin
             `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", txselfcal_tx_end.get_type_name()), UVM_MEDIUM)
             done_tx.start(env.tx_agent.seqr);
             `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", txselfcal_tx_end.get_type_name()), UVM_MEDIUM)
        end
        begin
          fork
               begin
                    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", txselfcal_rx_end.get_type_name()), UVM_MEDIUM)
                    txselfcal_rx_end.start(env.rx_agent.seqr);
                    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", txselfcal_rx_end.get_type_name()), UVM_MEDIUM)
               end
               begin
               done.start(env.LTSM_ctrl_agt.seqr);
               end
          join
        end
    join

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", rxclkcal_success.get_type_name()), UVM_MEDIUM)
    rxclkcal_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", rxclkcal_success.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", valtraincenter_success.get_type_name()), UVM_MEDIUM)
    valtraincenter_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", valtraincenter_success.get_type_name()), UVM_MEDIUM) 

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", valtrainvref_success.get_type_name()), UVM_MEDIUM)
    valtrainvref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", valtrainvref_success.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", dtc1_success.get_type_name()), UVM_MEDIUM)
    dtc1_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", dtc1_success.get_type_name()), UVM_MEDIUM)
 


    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", datatrainvref_looptillerror.get_type_name()), UVM_MEDIUM)
    datatrainvref_looptillerror.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", datatrainvref_looptillerror.get_type_name()), UVM_MEDIUM)

    // from reset to mbinit
     ready.start(env.v_seqr);

    // re enter datatrainvref
    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", vref_success.get_type_name()), UVM_MEDIUM)
    vref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", vref_success.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", datavref_success.get_type_name()), UVM_MEDIUM)
    datavref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", datavref_success.get_type_name()), UVM_MEDIUM)

     `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", datavref_speedidle.get_type_name()), UVM_MEDIUM)
    datavref_speedidle.start(env.tx_agent.seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", datavref_speedidle.get_type_name()), UVM_MEDIUM)

    fork
        begin
             `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_tx_end.get_type_name()), UVM_MEDIUM)
             done_tx.start(env.tx_agent.seqr);
             `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_tx_end.get_type_name()), UVM_MEDIUM)
        end
        begin
             `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_rx_end.get_type_name()), UVM_MEDIUM)
             fork
               speedidle_rx_end.start(env.rx_agent.seqr);
               done.start(env.LTSM_ctrl_agt.seqr);
             join
             `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_rx_end.get_type_name()), UVM_MEDIUM)
        end
    join

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_txselfcal.get_type_name()), UVM_MEDIUM)
    speedidle_txselfcal.start(env.tx_agent.seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_txselfcal.get_type_name()), UVM_MEDIUM)

    fork
        begin
             `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", txselfcal_tx_end.get_type_name()), UVM_MEDIUM)
             done_tx.start(env.tx_agent.seqr);
             `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", txselfcal_tx_end.get_type_name()), UVM_MEDIUM)
        end
        begin
          fork
               begin
                    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", txselfcal_rx_end.get_type_name()), UVM_MEDIUM)
                    txselfcal_rx_end.start(env.rx_agent.seqr);
                    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", txselfcal_rx_end.get_type_name()), UVM_MEDIUM)
               end
               begin
               done.start(env.LTSM_ctrl_agt.seqr);
               end
          join
        end
    join

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", rxclkcal_success.get_type_name()), UVM_MEDIUM)
    rxclkcal_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", rxclkcal_success.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", valtraincenter_success.get_type_name()), UVM_MEDIUM)
    valtraincenter_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", valtraincenter_success.get_type_name()), UVM_MEDIUM) 

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", valtrainvref_success.get_type_name()), UVM_MEDIUM)
    valtrainvref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", valtrainvref_success.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", dtc1_success.get_type_name()), UVM_MEDIUM)
    dtc1_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", dtc1_success.get_type_name()), UVM_MEDIUM)
 
 

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", datatrainvref_success.get_type_name()), UVM_MEDIUM)
    datatrainvref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", datatrainvref_success.get_type_name()), UVM_MEDIUM)

    // rxdeskew sequences

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", rxdeskew_timeout.get_type_name()), UVM_MEDIUM)
    rxdeskew_timeout.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", rxdeskew_timeout.get_type_name()), UVM_MEDIUM)

    // from reset to mbinit
     ready.start(env.v_seqr);

    // re enter rxdeskew
    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", vref_success.get_type_name()), UVM_MEDIUM)
    vref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", vref_success.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", datavref_success.get_type_name()), UVM_MEDIUM)
    datavref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", datavref_success.get_type_name()), UVM_MEDIUM)

     `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", datavref_speedidle.get_type_name()), UVM_MEDIUM)
    datavref_speedidle.start(env.tx_agent.seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", datavref_speedidle.get_type_name()), UVM_MEDIUM)

    fork
        begin
             `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_tx_end.get_type_name()), UVM_MEDIUM)
             done_tx.start(env.tx_agent.seqr);
             `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_tx_end.get_type_name()), UVM_MEDIUM)
        end
        begin
             `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_rx_end.get_type_name()), UVM_MEDIUM)
             fork
               speedidle_rx_end.start(env.rx_agent.seqr);
               done.start(env.LTSM_ctrl_agt.seqr);
             join
             `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_rx_end.get_type_name()), UVM_MEDIUM)
        end
    join

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_txselfcal.get_type_name()), UVM_MEDIUM)
    speedidle_txselfcal.start(env.tx_agent.seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_txselfcal.get_type_name()), UVM_MEDIUM)

    fork
        begin
             `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", txselfcal_tx_end.get_type_name()), UVM_MEDIUM)
             done_tx.start(env.tx_agent.seqr);
             `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", txselfcal_tx_end.get_type_name()), UVM_MEDIUM)
        end
        begin
          fork
               begin
                    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", txselfcal_rx_end.get_type_name()), UVM_MEDIUM)
                    txselfcal_rx_end.start(env.rx_agent.seqr);
                    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", txselfcal_rx_end.get_type_name()), UVM_MEDIUM)
               end
               begin
               done.start(env.LTSM_ctrl_agt.seqr);
               end
          join
        end
    join

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", rxclkcal_success.get_type_name()), UVM_MEDIUM)
    rxclkcal_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", rxclkcal_success.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", valtraincenter_success.get_type_name()), UVM_MEDIUM)
    valtraincenter_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", valtraincenter_success.get_type_name()), UVM_MEDIUM) 

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", valtrainvref_success.get_type_name()), UVM_MEDIUM)
    valtrainvref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", valtrainvref_success.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", dtc1_success.get_type_name()), UVM_MEDIUM)
    dtc1_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", dtc1_success.get_type_name()), UVM_MEDIUM)
 
 

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", datatrainvref_success.get_type_name()), UVM_MEDIUM)
    datatrainvref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", datatrainvref_success.get_type_name()), UVM_MEDIUM)
 

    
    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", rxdeskew_trainerror.get_type_name()), UVM_MEDIUM)
    rxdeskew_trainerror.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", rxdeskew_trainerror.get_type_name()), UVM_MEDIUM)

    // from reset to mbinit
     ready.start(env.v_seqr);

    // re enter rxdeskew
    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", vref_success.get_type_name()), UVM_MEDIUM)
    vref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", vref_success.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", datavref_success.get_type_name()), UVM_MEDIUM)
    datavref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", datavref_success.get_type_name()), UVM_MEDIUM)

     `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", datavref_speedidle.get_type_name()), UVM_MEDIUM)
    datavref_speedidle.start(env.tx_agent.seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", datavref_speedidle.get_type_name()), UVM_MEDIUM)

    fork
        begin
             `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_tx_end.get_type_name()), UVM_MEDIUM)
             done_tx.start(env.tx_agent.seqr);
             `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_tx_end.get_type_name()), UVM_MEDIUM)
        end
        begin
             `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_rx_end.get_type_name()), UVM_MEDIUM)
             fork
               speedidle_rx_end.start(env.rx_agent.seqr);
               done.start(env.LTSM_ctrl_agt.seqr);
             join
             `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_rx_end.get_type_name()), UVM_MEDIUM)
        end
    join

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_txselfcal.get_type_name()), UVM_MEDIUM)
    speedidle_txselfcal.start(env.tx_agent.seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_txselfcal.get_type_name()), UVM_MEDIUM)

    fork
        begin
             `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", txselfcal_tx_end.get_type_name()), UVM_MEDIUM)
             done_tx.start(env.tx_agent.seqr);
             `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", txselfcal_tx_end.get_type_name()), UVM_MEDIUM)
        end
        begin
          fork
               begin
                    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", txselfcal_rx_end.get_type_name()), UVM_MEDIUM)
                    txselfcal_rx_end.start(env.rx_agent.seqr);
                    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", txselfcal_rx_end.get_type_name()), UVM_MEDIUM)
               end
               begin
               done.start(env.LTSM_ctrl_agt.seqr);
               end
          join
        end
    join

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", rxclkcal_success.get_type_name()), UVM_MEDIUM)
    rxclkcal_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", rxclkcal_success.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", valtraincenter_success.get_type_name()), UVM_MEDIUM)
    valtraincenter_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", valtraincenter_success.get_type_name()), UVM_MEDIUM) 

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", valtrainvref_success.get_type_name()), UVM_MEDIUM)
    valtrainvref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", valtrainvref_success.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", dtc1_success.get_type_name()), UVM_MEDIUM)
    dtc1_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", dtc1_success.get_type_name()), UVM_MEDIUM)
 
 

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", datatrainvref_success.get_type_name()), UVM_MEDIUM)
    datatrainvref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", datatrainvref_success.get_type_name()), UVM_MEDIUM)
 


    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", rxdeskew_success.get_type_name()), UVM_MEDIUM)
    rxdeskew_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", rxdeskew_success.get_type_name()), UVM_MEDIUM)


    // dtc2 sequences

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", dtc2_timeout.get_type_name()), UVM_MEDIUM)
    dtc2_timeout.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", dtc2_timeout.get_type_name()), UVM_MEDIUM)

    // from reset to mbinit
     ready.start(env.v_seqr);

    // re enter dtc2
    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", vref_success.get_type_name()), UVM_MEDIUM)
    vref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", vref_success.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", datavref_success.get_type_name()), UVM_MEDIUM)
    datavref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", datavref_success.get_type_name()), UVM_MEDIUM)

     `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", datavref_speedidle.get_type_name()), UVM_MEDIUM)
    datavref_speedidle.start(env.tx_agent.seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", datavref_speedidle.get_type_name()), UVM_MEDIUM)

    fork
        begin
             `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_tx_end.get_type_name()), UVM_MEDIUM)
             done_tx.start(env.tx_agent.seqr);
             `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_tx_end.get_type_name()), UVM_MEDIUM)
        end
        begin
             `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_rx_end.get_type_name()), UVM_MEDIUM)
             fork
               speedidle_rx_end.start(env.rx_agent.seqr);
               done.start(env.LTSM_ctrl_agt.seqr);
             join
             `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_rx_end.get_type_name()), UVM_MEDIUM)
        end
    join

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_txselfcal.get_type_name()), UVM_MEDIUM)
    speedidle_txselfcal.start(env.tx_agent.seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_txselfcal.get_type_name()), UVM_MEDIUM)

    fork
        begin
             `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", txselfcal_tx_end.get_type_name()), UVM_MEDIUM)
             done_tx.start(env.tx_agent.seqr);
             `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", txselfcal_tx_end.get_type_name()), UVM_MEDIUM)
        end
        begin
          fork
               begin
                    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", txselfcal_rx_end.get_type_name()), UVM_MEDIUM)
                    txselfcal_rx_end.start(env.rx_agent.seqr);
                    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", txselfcal_rx_end.get_type_name()), UVM_MEDIUM)
               end
               begin
               done.start(env.LTSM_ctrl_agt.seqr);
               end
          join
        end
    join

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", rxclkcal_success.get_type_name()), UVM_MEDIUM)
    rxclkcal_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", rxclkcal_success.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", valtraincenter_success.get_type_name()), UVM_MEDIUM)
    valtraincenter_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", valtraincenter_success.get_type_name()), UVM_MEDIUM) 

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", valtrainvref_success.get_type_name()), UVM_MEDIUM)
    valtrainvref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", valtrainvref_success.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", dtc1_success.get_type_name()), UVM_MEDIUM)
    dtc1_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", dtc1_success.get_type_name()), UVM_MEDIUM)
 
 

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", datatrainvref_success.get_type_name()), UVM_MEDIUM)
    datatrainvref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", datatrainvref_success.get_type_name()), UVM_MEDIUM)
 


    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", rxdeskew_success.get_type_name()), UVM_MEDIUM)
    rxdeskew_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", rxdeskew_success.get_type_name()), UVM_MEDIUM)

 

    
    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", dtc2_trainerror.get_type_name()), UVM_MEDIUM)
    dtc2_trainerror.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", dtc2_trainerror.get_type_name()), UVM_MEDIUM)

    // from reset to mbinit
     ready.start(env.v_seqr);

    // re enter dtc2
    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", vref_success.get_type_name()), UVM_MEDIUM)
    vref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", vref_success.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", datavref_success.get_type_name()), UVM_MEDIUM)
    datavref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", datavref_success.get_type_name()), UVM_MEDIUM)

     `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", datavref_speedidle.get_type_name()), UVM_MEDIUM)
    datavref_speedidle.start(env.tx_agent.seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", datavref_speedidle.get_type_name()), UVM_MEDIUM)

    fork
        begin
             `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_tx_end.get_type_name()), UVM_MEDIUM)
             done_tx.start(env.tx_agent.seqr);
             `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_tx_end.get_type_name()), UVM_MEDIUM)
        end
        begin
             `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_rx_end.get_type_name()), UVM_MEDIUM)
             fork
               speedidle_rx_end.start(env.rx_agent.seqr);
               done.start(env.LTSM_ctrl_agt.seqr);
             join
             `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_rx_end.get_type_name()), UVM_MEDIUM)
        end
    join

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_txselfcal.get_type_name()), UVM_MEDIUM)
    speedidle_txselfcal.start(env.tx_agent.seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_txselfcal.get_type_name()), UVM_MEDIUM)

    fork
        begin
             `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", txselfcal_tx_end.get_type_name()), UVM_MEDIUM)
             done_tx.start(env.tx_agent.seqr);
             `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", txselfcal_tx_end.get_type_name()), UVM_MEDIUM)
        end
        begin
          fork
               begin
                    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", txselfcal_rx_end.get_type_name()), UVM_MEDIUM)
                    txselfcal_rx_end.start(env.rx_agent.seqr);
                    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", txselfcal_rx_end.get_type_name()), UVM_MEDIUM)
               end
               begin
               done.start(env.LTSM_ctrl_agt.seqr);
               end
          join
        end
    join

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", rxclkcal_success.get_type_name()), UVM_MEDIUM)
    rxclkcal_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", rxclkcal_success.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", valtraincenter_success.get_type_name()), UVM_MEDIUM)
    valtraincenter_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", valtraincenter_success.get_type_name()), UVM_MEDIUM) 

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", valtrainvref_success.get_type_name()), UVM_MEDIUM)
    valtrainvref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", valtrainvref_success.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", dtc1_success.get_type_name()), UVM_MEDIUM)
    dtc1_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", dtc1_success.get_type_name()), UVM_MEDIUM)
 
 

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", datatrainvref_success.get_type_name()), UVM_MEDIUM)
    datatrainvref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", datatrainvref_success.get_type_name()), UVM_MEDIUM)
 


    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", rxdeskew_success.get_type_name()), UVM_MEDIUM)
    rxdeskew_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", rxdeskew_success.get_type_name()), UVM_MEDIUM)

 

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", dtc2_success.get_type_name()), UVM_MEDIUM)
    dtc2_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", dtc2_success.get_type_name()), UVM_MEDIUM)
    
    // uncomment from 1647 to 1987

    // linkspeed to phyretrain sequences
//     `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", linkspeed_phyretrain_lanepossible_rxfail.get_type_name()), UVM_MEDIUM)
//     linkspeed_phyretrain_lanepossible_rxfail.start(env.v_seqr);
//     `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", linkspeed_phyretrain_lanepossible_rxfail.get_type_name()), UVM_MEDIUM)
//     // sequences to exit phyretrain

//     // repair sequences
//     // el rx haygilh degrade b 8 15
//     `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", repair_rx_starthandshake.get_type_name()), UVM_MEDIUM)
//      repair_rx_starthandshake.start(env.rx_agent.seqr);
//      `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", repair_rx_starthandshake.get_type_name()), UVM_MEDIUM)
//      fork
//         begin
//              `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", repair_tx_applydegrade.get_type_name()), UVM_MEDIUM)
//              repair_tx_applydegrade.start(env.tx_agent.seqr);
//              `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", repair_tx_applydegrade.get_type_name()), UVM_MEDIUM)

//              `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", repair_tx_endhandshake.get_type_name()), UVM_MEDIUM)
//              repair_tx_endhandshake.start(env.tx_agent.seqr);
//              `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", repair_tx_endhandshake.get_type_name()), UVM_MEDIUM)
//         end
//         begin
//              `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", repair_rx_degrade_8_15.get_type_name()), UVM_MEDIUM)
//              repair_rx_degrade_8_15.start(env.rx_agent.seqr);
//              `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", repair_rx_degrade_8_15.get_type_name()), UVM_MEDIUM)

//              `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", repair_rx_endhandshake.get_type_name()), UVM_MEDIUM)
//              repair_rx_endhandshake.start(env.rx_agent.seqr);
//              `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", repair_rx_endhandshake.get_type_name()), UVM_MEDIUM)
//         end
//     join
//     repair_txselfcal.start(env.tx_agent.seqr);
     

//     // tx selfcal to linkspeed
//     fork
//         begin
//              `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", txselfcal_tx_end.get_type_name()), UVM_MEDIUM)
//              txselfcal_tx_end.start(env.tx_agent.seqr);
//              done_tx.start(env.tx_agent.seqr);
//              `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", txselfcal_tx_end.get_type_name()), UVM_MEDIUM)
//         end
//         begin
//           fork
//                begin
//                     `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", txselfcal_rx_end.get_type_name()), UVM_MEDIUM)
//                     txselfcal_rx_end.start(env.rx_agent.seqr);
//                     `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", txselfcal_rx_end.get_type_name()), UVM_MEDIUM)
//                end
//                begin
//                done.start(env.LTSM_ctrl_agt.seqr);
//                end
//           join
//         end
//     join

//     `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", rxclkcal_success.get_type_name()), UVM_MEDIUM)
//     rxclkcal_success.start(env.v_seqr);
//     `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", rxclkcal_success.get_type_name()), UVM_MEDIUM)

//     `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", valtraincenter_success.get_type_name()), UVM_MEDIUM)
//     valtraincenter_success.start(env.v_seqr);
//     `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", valtraincenter_success.get_type_name()), UVM_MEDIUM) 

//     `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", valtrainvref_success.get_type_name()), UVM_MEDIUM)
//     valtrainvref_success.start(env.v_seqr);
//     `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", valtrainvref_success.get_type_name()), UVM_MEDIUM)

//     `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", dtc1_success.get_type_name()), UVM_MEDIUM)
//     dtc1_success.start(env.v_seqr);
//     `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", dtc1_success.get_type_name()), UVM_MEDIUM)
 
 

//     `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", datatrainvref_success.get_type_name()), UVM_MEDIUM)
//     datatrainvref_success.start(env.v_seqr);
//     `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", datatrainvref_success.get_type_name()), UVM_MEDIUM)
 


//     `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", rxdeskew_success.get_type_name()), UVM_MEDIUM)
//     rxdeskew_success.start(env.v_seqr);
//     `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", rxdeskew_success.get_type_name()), UVM_MEDIUM)

 

//     `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", dtc2_success.get_type_name()), UVM_MEDIUM)
//     dtc2_success.start(env.v_seqr);
//     `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", dtc2_success.get_type_name()), UVM_MEDIUM)



//     `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", linkspeed_phyretrain_lanepossible_txfail.get_type_name()), UVM_MEDIUM)
//     linkspeed_phyretrain_lanepossible_txfail.start(env.v_seqr);
//     `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", linkspeed_phyretrain_lanepossible_txfail.get_type_name()), UVM_MEDIUM)
//     // sequences to exit phyretrain
//     // repair sequences
//     `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", repair_rx_starthandshake.get_type_name()), UVM_MEDIUM)
//      repair_rx_starthandshake.start(env.rx_agent.seqr);
//      `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", repair_rx_starthandshake.get_type_name()), UVM_MEDIUM)
//      fork
//         begin
//              `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", repair_tx_applydegrade.get_type_name()), UVM_MEDIUM)
//              repair_tx_applydegrade.start(env.tx_agent.seqr);
//              `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", repair_tx_applydegrade.get_type_name()), UVM_MEDIUM)

//              `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", repair_tx_endhandshake.get_type_name()), UVM_MEDIUM)
//              repair_tx_endhandshake.start(env.tx_agent.seqr);
//              `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", repair_tx_endhandshake.get_type_name()), UVM_MEDIUM)
//         end
//         begin
//              `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", repair_rx_degrade_0_15.get_type_name()), UVM_MEDIUM)
//              repair_rx_degrade_0_15.start(env.rx_agent.seqr);
//              `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", repair_rx_degrade_0_15.get_type_name()), UVM_MEDIUM)

//              `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", repair_rx_endhandshake.get_type_name()), UVM_MEDIUM)
//              repair_rx_endhandshake.start(env.rx_agent.seqr);
//              `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", repair_rx_endhandshake.get_type_name()), UVM_MEDIUM)
//         end
//     join
//     repair_txselfcal.start(env.tx_agent.seqr);
     

//     // tx selfcal to linkspeed
//     fork
//         begin
//              `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", txselfcal_tx_end.get_type_name()), UVM_MEDIUM)
//              txselfcal_tx_end.start(env.tx_agent.seqr);
//              done_tx.start(env.tx_agent.seqr);
//              `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", txselfcal_tx_end.get_type_name()), UVM_MEDIUM)
//         end
//         begin
//           fork
//                begin
//                     `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", txselfcal_rx_end.get_type_name()), UVM_MEDIUM)
//                     txselfcal_rx_end.start(env.rx_agent.seqr);
//                     `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", txselfcal_rx_end.get_type_name()), UVM_MEDIUM)
//                end
//                begin
//                done.start(env.LTSM_ctrl_agt.seqr);
//                end
//           join
//         end
//     join

//     `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", rxclkcal_success.get_type_name()), UVM_MEDIUM)
//     rxclkcal_success.start(env.v_seqr);
//     `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", rxclkcal_success.get_type_name()), UVM_MEDIUM)

//     `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", valtraincenter_success.get_type_name()), UVM_MEDIUM)
//     valtraincenter_success.start(env.v_seqr);
//     `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", valtraincenter_success.get_type_name()), UVM_MEDIUM) 

//     `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", valtrainvref_success.get_type_name()), UVM_MEDIUM)
//     valtrainvref_success.start(env.v_seqr);
//     `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", valtrainvref_success.get_type_name()), UVM_MEDIUM)

//     `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", dtc1_success.get_type_name()), UVM_MEDIUM)
//     dtc1_success.start(env.v_seqr);
//     `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", dtc1_success.get_type_name()), UVM_MEDIUM)
 
 

//     `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", datatrainvref_success.get_type_name()), UVM_MEDIUM)
//     datatrainvref_success.start(env.v_seqr);
//     `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", datatrainvref_success.get_type_name()), UVM_MEDIUM)
 


//     `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", rxdeskew_success.get_type_name()), UVM_MEDIUM)
//     rxdeskew_success.start(env.v_seqr);
//     `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", rxdeskew_success.get_type_name()), UVM_MEDIUM)

 

//     `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", dtc2_success.get_type_name()), UVM_MEDIUM)
//     dtc2_success.start(env.v_seqr);
//     `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", dtc2_success.get_type_name()), UVM_MEDIUM)




//     `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", linkspeed_phyretrain_nolanepossible_rxfail.get_type_name()), UVM_MEDIUM)
//     linkspeed_phyretrain_nolanepossible_rxfail.start(env.v_seqr);
//     `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", linkspeed_phyretrain_nolanepossible_rxfail.get_type_name()), UVM_MEDIUM)
//     // sequences to exit phyretrain
    
//     // speedidle to linkspeed
//     fork
//         begin
//              `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_tx_end.get_type_name()), UVM_MEDIUM)
//              speedidle_tx_end.start(env.tx_agent.seqr);
//              done_tx.start(env.tx_agent.seqr);
//              `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_tx_end.get_type_name()), UVM_MEDIUM)
//         end
//         begin
//              `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_rx_end.get_type_name()), UVM_MEDIUM)
//              speedidle_rx_end.start(env.rx_agent.seqr);
//              `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_rx_end.get_type_name()), UVM_MEDIUM)
//         end
//     join

//     `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_txselfcal.get_type_name()), UVM_MEDIUM)
//     speedidle_txselfcal.start(env.tx_agent.seqr);
//     `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_txselfcal.get_type_name()), UVM_MEDIUM)

//     fork
//         begin
//              `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", txselfcal_tx_end.get_type_name()), UVM_MEDIUM)
//              txselfcal_tx_end.start(env.tx_agent.seqr);
//              done_tx.start(env.tx_agent.seqr);
//              `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", txselfcal_tx_end.get_type_name()), UVM_MEDIUM)
//         end
//         begin
//           fork
//                begin
//                     `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", txselfcal_rx_end.get_type_name()), UVM_MEDIUM)
//                     txselfcal_rx_end.start(env.rx_agent.seqr);
//                     `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", txselfcal_rx_end.get_type_name()), UVM_MEDIUM)
//                end
//                begin
//                done.start(env.LTSM_ctrl_agt.seqr);
//                end
//           join
//         end
//     join

//     `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", rxclkcal_success.get_type_name()), UVM_MEDIUM)
//     rxclkcal_success.start(env.v_seqr);
//     `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", rxclkcal_success.get_type_name()), UVM_MEDIUM)

//     `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", valtraincenter_success.get_type_name()), UVM_MEDIUM)
//     valtraincenter_success.start(env.v_seqr);
//     `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", valtraincenter_success.get_type_name()), UVM_MEDIUM) 

//     `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", valtrainvref_success.get_type_name()), UVM_MEDIUM)
//     valtrainvref_success.start(env.v_seqr);
//     `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", valtrainvref_success.get_type_name()), UVM_MEDIUM)

//     `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", dtc1_success.get_type_name()), UVM_MEDIUM)
//     dtc1_success.start(env.v_seqr);
//     `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", dtc1_success.get_type_name()), UVM_MEDIUM)
 
 

//     `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", datatrainvref_success.get_type_name()), UVM_MEDIUM)
//     datatrainvref_success.start(env.v_seqr);
//     `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", datatrainvref_success.get_type_name()), UVM_MEDIUM)
 


//     `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", rxdeskew_success.get_type_name()), UVM_MEDIUM)
//     rxdeskew_success.start(env.v_seqr);
//     `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", rxdeskew_success.get_type_name()), UVM_MEDIUM)

 

//     `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", dtc2_success.get_type_name()), UVM_MEDIUM)
//     dtc2_success.start(env.v_seqr);
//     `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", dtc2_success.get_type_name()), UVM_MEDIUM)




//     `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", linkspeed_phyretrain_nolanepossible_txfail.get_type_name()), UVM_MEDIUM)
//     linkspeed_phyretrain_nolanepossible_txfail.start(env.v_seqr);
//     `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", linkspeed_phyretrain_nolanepossible_txfail.get_type_name()), UVM_MEDIUM)
//     // sequences to exit phyretrain
    
//     // speedidle to linkspeed
//     fork
//         begin
//              `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_tx_end.get_type_name()), UVM_MEDIUM)
//              speedidle_tx_end.start(env.tx_agent.seqr);
//              done_tx.start(env.tx_agent.seqr);
//              `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_tx_end.get_type_name()), UVM_MEDIUM)
//         end
//         begin
//              `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_rx_end.get_type_name()), UVM_MEDIUM)
//              speedidle_rx_end.start(env.rx_agent.seqr);
//              `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_rx_end.get_type_name()), UVM_MEDIUM)
//         end
//     join

//     `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_txselfcal.get_type_name()), UVM_MEDIUM)
//     speedidle_txselfcal.start(env.tx_agent.seqr);
//     `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_txselfcal.get_type_name()), UVM_MEDIUM)

//     fork
//         begin
//              `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", txselfcal_tx_end.get_type_name()), UVM_MEDIUM)
//              txselfcal_tx_end.start(env.tx_agent.seqr);
//              done_tx.start(env.tx_agent.seqr);
//              `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", txselfcal_tx_end.get_type_name()), UVM_MEDIUM)
//         end
//         begin
//           fork
//                begin
//                     `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", txselfcal_rx_end.get_type_name()), UVM_MEDIUM)
//                     txselfcal_rx_end.start(env.rx_agent.seqr);
//                     `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", txselfcal_rx_end.get_type_name()), UVM_MEDIUM)
//                end
//                begin
//                done.start(env.LTSM_ctrl_agt.seqr);
//                end
//           join
//         end
//     join

//     `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", rxclkcal_success.get_type_name()), UVM_MEDIUM)
//     rxclkcal_success.start(env.v_seqr);
//     `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", rxclkcal_success.get_type_name()), UVM_MEDIUM)

//     `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", valtraincenter_success.get_type_name()), UVM_MEDIUM)
//     valtraincenter_success.start(env.v_seqr);
//     `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", valtraincenter_success.get_type_name()), UVM_MEDIUM) 

//     `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", valtrainvref_success.get_type_name()), UVM_MEDIUM)
//     valtrainvref_success.start(env.v_seqr);
//     `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", valtrainvref_success.get_type_name()), UVM_MEDIUM)

//     `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", dtc1_success.get_type_name()), UVM_MEDIUM)
//     dtc1_success.start(env.v_seqr);
//     `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", dtc1_success.get_type_name()), UVM_MEDIUM)
 
 

//     `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", datatrainvref_success.get_type_name()), UVM_MEDIUM)
//     datatrainvref_success.start(env.v_seqr);
//     `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", datatrainvref_success.get_type_name()), UVM_MEDIUM)
 


//     `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", rxdeskew_success.get_type_name()), UVM_MEDIUM)
//     rxdeskew_success.start(env.v_seqr);
//     `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", rxdeskew_success.get_type_name()), UVM_MEDIUM)

 

//     `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", dtc2_success.get_type_name()), UVM_MEDIUM)
//     dtc2_success.start(env.v_seqr);
//     `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", dtc2_success.get_type_name()), UVM_MEDIUM)





    //linkspeed to repair sequences

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", linkspeed_repair_fail_8_15.get_type_name()), UVM_MEDIUM)
    linkspeed_repair_fail_8_15.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", linkspeed_repair_fail_8_15.get_type_name()), UVM_MEDIUM)
    // txslefcal to linkspeed
    

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", rxclkcal_success.get_type_name()), UVM_MEDIUM)
    rxclkcal_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", rxclkcal_success.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", valtraincenter_success.get_type_name()), UVM_MEDIUM)
    valtraincenter_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", valtraincenter_success.get_type_name()), UVM_MEDIUM) 

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", valtrainvref_success.get_type_name()), UVM_MEDIUM)
    valtrainvref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", valtrainvref_success.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", dtc1_success.get_type_name()), UVM_MEDIUM)
    dtc1_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", dtc1_success.get_type_name()), UVM_MEDIUM)
 
 

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", datatrainvref_success.get_type_name()), UVM_MEDIUM)
    datatrainvref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", datatrainvref_success.get_type_name()), UVM_MEDIUM)
 


    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", rxdeskew_success.get_type_name()), UVM_MEDIUM)
    rxdeskew_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", rxdeskew_success.get_type_name()), UVM_MEDIUM)

 

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", dtc2_success.get_type_name()), UVM_MEDIUM)
    dtc2_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", dtc2_success.get_type_name()), UVM_MEDIUM)
    





    
    
    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", linkspeed_repair_fail_0_7.get_type_name()), UVM_MEDIUM)
    linkspeed_repair_fail_0_7.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", linkspeed_repair_fail_0_7.get_type_name()), UVM_MEDIUM)
    // txslefcal to linkspeed


    

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", rxclkcal_success.get_type_name()), UVM_MEDIUM)
    rxclkcal_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", rxclkcal_success.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", valtraincenter_success.get_type_name()), UVM_MEDIUM)
    valtraincenter_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", valtraincenter_success.get_type_name()), UVM_MEDIUM) 

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", valtrainvref_success.get_type_name()), UVM_MEDIUM)
    valtrainvref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", valtrainvref_success.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", dtc1_success.get_type_name()), UVM_MEDIUM)
    dtc1_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", dtc1_success.get_type_name()), UVM_MEDIUM)
 
 

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", datatrainvref_success.get_type_name()), UVM_MEDIUM)
    datatrainvref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", datatrainvref_success.get_type_name()), UVM_MEDIUM)
 


    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", rxdeskew_success.get_type_name()), UVM_MEDIUM)
    rxdeskew_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", rxdeskew_success.get_type_name()), UVM_MEDIUM)

 

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", dtc2_success.get_type_name()), UVM_MEDIUM)
    dtc2_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", dtc2_success.get_type_name()), UVM_MEDIUM)


    
    // linkspeed to speedidle sequences
    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", linkspeed_speeddegrade_rxinit.get_type_name()), UVM_MEDIUM)
    linkspeed_speeddegrade_rxinit.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", linkspeed_speeddegrade_rxinit.get_type_name()), UVM_MEDIUM)
    // speedidle to linkspeed
    fork
        begin
             `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_tx_end.get_type_name()), UVM_MEDIUM)
             done_tx.start(env.tx_agent.seqr);
             `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_tx_end.get_type_name()), UVM_MEDIUM)
        end
        begin
             `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_rx_end.get_type_name()), UVM_MEDIUM)
             fork
               speedidle_rx_end.start(env.rx_agent.seqr);
               done.start(env.LTSM_ctrl_agt.seqr);
             join
             `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_rx_end.get_type_name()), UVM_MEDIUM)
        end
    join

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_txselfcal.get_type_name()), UVM_MEDIUM)
    speedidle_txselfcal.start(env.tx_agent.seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_txselfcal.get_type_name()), UVM_MEDIUM)

    fork
        begin
             `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", txselfcal_tx_end.get_type_name()), UVM_MEDIUM)
             done_tx.start(env.tx_agent.seqr);
             `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", txselfcal_tx_end.get_type_name()), UVM_MEDIUM)
        end
        begin
          fork
               begin
                    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", txselfcal_rx_end.get_type_name()), UVM_MEDIUM)
                    txselfcal_rx_end.start(env.rx_agent.seqr);
                    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", txselfcal_rx_end.get_type_name()), UVM_MEDIUM)
               end
               begin
               done.start(env.LTSM_ctrl_agt.seqr);
               end
          join
        end
    join

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", rxclkcal_success.get_type_name()), UVM_MEDIUM)
    rxclkcal_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", rxclkcal_success.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", valtraincenter_success.get_type_name()), UVM_MEDIUM)
    valtraincenter_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", valtraincenter_success.get_type_name()), UVM_MEDIUM) 

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", valtrainvref_success.get_type_name()), UVM_MEDIUM)
    valtrainvref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", valtrainvref_success.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", dtc1_success.get_type_name()), UVM_MEDIUM)
    dtc1_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", dtc1_success.get_type_name()), UVM_MEDIUM)
 
 

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", datatrainvref_success.get_type_name()), UVM_MEDIUM)
    datatrainvref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", datatrainvref_success.get_type_name()), UVM_MEDIUM)
 


    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", rxdeskew_success.get_type_name()), UVM_MEDIUM)
    rxdeskew_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", rxdeskew_success.get_type_name()), UVM_MEDIUM)

 

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", dtc2_success.get_type_name()), UVM_MEDIUM)
    dtc2_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", dtc2_success.get_type_name()), UVM_MEDIUM)



    repeat(4)begin
    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", linkspeed_speeddegrade_txinit.get_type_name()), UVM_MEDIUM)
    linkspeed_speeddegrade_txinit.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", linkspeed_speeddegrade_txinit.get_type_name()), UVM_MEDIUM)
    // speedidle to linkspeed
    fork
        begin
             `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_tx_end.get_type_name()), UVM_MEDIUM)
             done_tx.start(env.tx_agent.seqr);
             `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_tx_end.get_type_name()), UVM_MEDIUM)
        end
        begin
             `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_rx_end.get_type_name()), UVM_MEDIUM)
             fork
               speedidle_rx_end.start(env.rx_agent.seqr);
               done.start(env.LTSM_ctrl_agt.seqr);
             join
             `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_rx_end.get_type_name()), UVM_MEDIUM)
        end
    join

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_txselfcal.get_type_name()), UVM_MEDIUM)
    speedidle_txselfcal.start(env.tx_agent.seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_txselfcal.get_type_name()), UVM_MEDIUM)

    fork
        begin
             `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", txselfcal_tx_end.get_type_name()), UVM_MEDIUM)
             done_tx.start(env.tx_agent.seqr);
             `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", txselfcal_tx_end.get_type_name()), UVM_MEDIUM)
        end
        begin
          fork
               begin
                    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", txselfcal_rx_end.get_type_name()), UVM_MEDIUM)
                    txselfcal_rx_end.start(env.rx_agent.seqr);
                    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", txselfcal_rx_end.get_type_name()), UVM_MEDIUM)
               end
               begin
               done.start(env.LTSM_ctrl_agt.seqr);
               end
          join
        end
    join

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", rxclkcal_success.get_type_name()), UVM_MEDIUM)
    rxclkcal_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", rxclkcal_success.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", valtraincenter_success.get_type_name()), UVM_MEDIUM)
    valtraincenter_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", valtraincenter_success.get_type_name()), UVM_MEDIUM) 

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", valtrainvref_success.get_type_name()), UVM_MEDIUM)
    valtrainvref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", valtrainvref_success.get_type_name()), UVM_MEDIUM)

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", dtc1_success.get_type_name()), UVM_MEDIUM)
    dtc1_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", dtc1_success.get_type_name()), UVM_MEDIUM)
 
 

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", datatrainvref_success.get_type_name()), UVM_MEDIUM)
    datatrainvref_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", datatrainvref_success.get_type_name()), UVM_MEDIUM)
 


    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", rxdeskew_success.get_type_name()), UVM_MEDIUM)
    rxdeskew_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", rxdeskew_success.get_type_name()), UVM_MEDIUM)

 

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", dtc2_success.get_type_name()), UVM_MEDIUM)
    dtc2_success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", dtc2_success.get_type_name()), UVM_MEDIUM)
    end
    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", linkspeed_speeddegrade_txinit.get_type_name()), UVM_MEDIUM)
    linkspeed_speeddegrade_txinit.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", linkspeed_speeddegrade_txinit.get_type_name()), UVM_MEDIUM)
    // speedidle to linkspeed
    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_tx_end.get_type_name()), UVM_MEDIUM)
             speedidle_tx_end.start(env.LTSM_ctrl_agt.seqr);
     `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_tx_end.get_type_name()), UVM_MEDIUM)
//     fork
//         begin
//              `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_tx_end.get_type_name()), UVM_MEDIUM)
//              speedidle_tx_end.start(env.LTSM_ctrl_agt.seqr);
//              `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_tx_end.get_type_name()), UVM_MEDIUM)
//         end
//         begin
//              `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", speedidle_rx_end.get_type_name()), UVM_MEDIUM)
//              speedidle_rx_end.start(env.rx_agent.seqr);
//              `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", speedidle_rx_end.get_type_name()), UVM_MEDIUM)
//         end
//     join


    error_rx.start(env.rx_agent.seqr);
    fork
        // tx thread
        begin
            error_tx_rsp.start(env.tx_agent.seqr);
        end
        // rx thread
        begin
            error_rx_rsp.start(env.rx_agent.seqr);
        end
    join
    exit_to_reset.start(env.LTSM_ctrl_agt.seqr);

    // from reset to mbinit
     ready.start(env.v_seqr);

    `uvm_info(get_type_name(), $sformatf("Starting sequence: %s", success.get_type_name()), UVM_MEDIUM)
    success.start(env.v_seqr);
    `uvm_info(get_type_name(), $sformatf("Finished sequence: %s", success.get_type_name()), UVM_MEDIUM)
    
    `uvm_info(get_type_name(), $sformatf("mbrain sequences have finished"), UVM_MEDIUM)

    phase.drop_objection(this);
endtask : run_phase

// final_phase
// -----------

function void MBTRAIN_test::final_phase(uvm_phase phase);
    super.final_phase(phase);
    
    factory.print(0);
    `uvm_info("end_of_simulation_phase", $sformatf("=============== End of %s ===============", this.get_type_name()), UVM_MEDIUM)
endfunction : final_phase
