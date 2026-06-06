//=============================================================================
// File       : tx_base_test.sv
// Project    : UCIe 3.0 TX Logical PHY Verification
// Description: Base test — creates tx_env_cfg, parses plusargs, sets up
//              config DB, and instantiates the environment. All other
//              tests extend this class.
//=============================================================================

class tx_base_test extends uvm_test;

  `uvm_component_utils(tx_base_test)

  // Environment and config
  tx_env      env;
  tx_env_cfg  cfg;

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------

  function new(string name = "tx_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // -------------------------------------------------------------------------
  //  Build Phase
  // -------------------------------------------------------------------------

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Create and configure env config
    cfg = tx_env_cfg::type_id::create("cfg");
    cfg.parse_plusargs();

    // Get virtual interfaces from config DB (set by tb_top)
    if (!uvm_config_db#(virtual rdi_if)::get(this, "", "rdi_vif", cfg.rdi_vif))
      `uvm_fatal("BASE_TEST", "Failed to get rdi_vif from config_db")

    if (!uvm_config_db#(virtual ltsm_if)::get(this, "", "ltsm_vif", cfg.ltsm_vif))
      `uvm_fatal("BASE_TEST", "Failed to get ltsm_vif from config_db")

    if (!uvm_config_db#(virtual tx2link_if)::get(this, "", "tx2link_vif", cfg.tx2link_vif))
      `uvm_fatal("BASE_TEST", "Failed to get tx2link_vif from config_db")

    // Publish config for all children
    uvm_config_db#(tx_env_cfg)::set(this, "*", "tx_env_cfg", cfg);

    // Create environment
    env = tx_env::type_id::create("env", this);

    `uvm_info("BASE_TEST", $sformatf("Config: %s", cfg.convert2string()), UVM_LOW)
  endfunction

  // -------------------------------------------------------------------------
  //  End of Elaboration — print topology
  // -------------------------------------------------------------------------

  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
  endfunction

  // -------------------------------------------------------------------------
  //  Report Phase
  // -------------------------------------------------------------------------

  function void report_phase(uvm_phase phase);
    uvm_report_server svr;
    super.report_phase(phase);
    svr = uvm_report_server::get_server();

    if (svr.get_severity_count(UVM_FATAL) + svr.get_severity_count(UVM_ERROR) > 0)
      `uvm_info("BASE_TEST", "*** TEST FAILED ***", UVM_NONE)
    else
      `uvm_info("BASE_TEST", "*** TEST PASSED ***", UVM_NONE)
  endfunction

endclass : tx_base_test
