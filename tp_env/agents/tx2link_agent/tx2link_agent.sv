//=============================================================================
// File       : tx2link_agent.sv
// Project    : UCIe 3.0 TX Logical PHY Verification
// Description: Passive tx2link agent — contains only a monitor (no driver
//              or sequencer). Wraps the tx2link_monitor and exposes its
//              analysis port and LTSM state FIFO for environment wiring.
//=============================================================================

class tx2link_agent extends uvm_agent;

  `uvm_component_utils(tx2link_agent)

  // Sub-components (monitor only — passive agent)
  tx2link_monitor  mon;

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------

  function new(string name = "tx2link_agent", uvm_component parent = null);
    super.new(name, parent);
    is_active = UVM_PASSIVE;
  endfunction

  // -------------------------------------------------------------------------
  //  Build Phase
  // -------------------------------------------------------------------------

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon = tx2link_monitor::type_id::create("mon", this);
  endfunction

endclass : tx2link_agent
