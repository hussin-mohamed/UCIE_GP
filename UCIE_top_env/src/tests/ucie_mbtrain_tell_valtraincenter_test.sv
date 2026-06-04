//=============================================================================
// File       : ucie_mbtrain_tell_valtraincenter_test.sv
// Project    : UCIe 3.0 System-Level Verification
// Description: Sanity test that runs the master virtual sequence.
//=============================================================================

class ucie_mbtrain_tell_valtraincenter_test extends ucie_base_test;

  `uvm_component_utils(ucie_mbtrain_tell_valtraincenter_test)
  
  ucie_mbinit_bringup_vseq vseq;
  ucie_mbtrain_tell_valtraincenter_vseq tell_valtraincenter_vseq;

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "ucie_mbtrain_tell_valtraincenter_test", uvm_component parent = null);
    super.new(name, parent);
    uvm_top.set_timeout(100ms, 0);
  endfunction

  virtual function void start_of_simulation_phase(uvm_phase phase);
    vseq = ucie_mbinit_bringup_vseq::type_id::create("vseq");
    tell_valtraincenter_vseq = ucie_mbtrain_tell_valtraincenter_vseq::type_id::create("tell_valtraincenter_vseq");
  endfunction : start_of_simulation_phase

  // -------------------------------------------------------------------------
  //  Run Phase
  // -------------------------------------------------------------------------
  virtual task main_phase(uvm_phase phase);
    fork
      begin
        phase.raise_objection(this);

        vseq.start(env.vseqr);
        tell_valtraincenter_vseq.start(env.vseqr);

        wait (env.sb_env_i.phylink_agt.mntr.txn_in_cnt == vseq.ltsm2link_msg_cnt);

        // Wait a bit to let things settle after sequence finishes
        #1000000ns;

        phase.drop_objection(this);
      end
    join_none


    @(posedge m_cfg.sb_cfg.phylink_bfm_drive.reset);
    @(negedge m_cfg.sb_cfg.phylink_bfm_drive.reset);
    @(posedge m_cfg.sb_cfg.phylink_bfm_drive.reset);
    `uvm_info(get_type_name(), "Starting ACTIVE RESETBase test class for the Sideband testbench, handling environment setup and common test configuration.", UVM_MEDIUM)
    phase.get_objection().set_report_severity_id_override(UVM_WARNING, "OBJTN_CLEAR", UVM_INFO);
    phase.jump(uvm_pre_reset_phase::get());
  endtask

endclass : ucie_mbtrain_tell_valtraincenter_test
