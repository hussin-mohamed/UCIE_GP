//=============================================================================
// File       : ltsm_agent.sv
// Project    : UCIe 3.0 TX Logical PHY Verification
// Description: LTSM agent wrapper — instantiates driver, monitor, sequencer.
//              Always active (the LTSM always drives state to the DUT).
//              Exposes get_sequencer() for sqr_pool registration.
//=============================================================================

class ltsm_agent extends uvm_agent;

  `uvm_component_utils(ltsm_agent)

  // Sub-components
  ltsm_driver     drv;
  ltsm_monitor    mon;
  ltsm_sequencer  sqr;

  // Configuration
  tx_env_cfg      cfg;

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------

  function new(string name = "ltsm_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // -------------------------------------------------------------------------
  //  Build Phase
  // -------------------------------------------------------------------------

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Retrieve environment config
    if (!uvm_config_db#(tx_env_cfg)::get(this, "", "tx_env_cfg", cfg))
      `uvm_fatal("LTSM_AGENT", "Failed to get tx_env_cfg from config_db")

    // Monitor is always instantiated
    mon = ltsm_monitor::type_id::create("mon", this);

    // Driver and sequencer only in active mode
    if (cfg.ltsm_agent_mode == UVM_ACTIVE) begin
      drv = ltsm_driver::type_id::create("drv", this);
      sqr = ltsm_sequencer::type_id::create("sqr", this);
      is_active = UVM_ACTIVE;
    end else begin
      is_active = UVM_PASSIVE;
    end
  endfunction

  // -------------------------------------------------------------------------
  //  Connect Phase
  // -------------------------------------------------------------------------

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    if (is_active == UVM_ACTIVE) begin
      drv.seq_item_port.connect(sqr.seq_item_export);
    end
  endfunction

  // -------------------------------------------------------------------------
  //  Sequencer Container Support
  // -------------------------------------------------------------------------

  function uvm_sequencer_base get_sequencer();
    return sqr;
  endfunction

endclass : ltsm_agent
