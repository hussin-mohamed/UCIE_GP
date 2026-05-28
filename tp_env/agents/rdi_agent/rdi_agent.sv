//=============================================================================
// File       : rdi_agent.sv
// Project    : UCIe 3.0 TX Logical PHY Verification
// Description: RDI agent wrapper — instantiates driver, monitor, sequencer.
//              Configurable active/passive. Exposes get_sequencer() method
//              for the sqr_pool sequencer container pattern.
//=============================================================================

class rdi_agent extends uvm_agent;

  `uvm_component_utils(rdi_agent)

  // Sub-components
  rdi_driver     drv;
  rdi_monitor    mon;
  rdi_sequencer  sqr;

  // Configuration
  tx_env_cfg     cfg;

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------

  function new(string name = "rdi_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // -------------------------------------------------------------------------
  //  Build Phase
  // -------------------------------------------------------------------------

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Retrieve environment config
    if (!uvm_config_db#(tx_env_cfg)::get(this, "", "tx_env_cfg", cfg))
      `uvm_fatal("RDI_AGENT", "Failed to get tx_env_cfg from config_db")

    // Monitor is always instantiated
    mon = rdi_monitor::type_id::create("mon", this);

    // Driver and sequencer only in active mode
    if (cfg.rdi_agent_mode == UVM_ACTIVE) begin
      drv = rdi_driver::type_id::create("drv", this);
      sqr = rdi_sequencer::type_id::create("sqr", this);
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

    // Connect driver to sequencer in active mode
    if (is_active == UVM_ACTIVE) begin
      drv.seq_item_port.connect(sqr.seq_item_export);
    end
  endfunction

  // -------------------------------------------------------------------------
  //  Sequencer Container Support
  // -------------------------------------------------------------------------

  // Returns the agent's sequencer handle for sqr_pool registration
  function uvm_sequencer_base get_sequencer();
    return sqr;
  endfunction

endclass : rdi_agent
