//=============================================================================
// File       : ltsm_monitor.sv
// Project    : UCIe 3.0 TX Logical PHY Verification
// Description: LTSM monitor — detects encoding changes on the LTSM
//              interface and broadcasts state transitions via analysis
//              port. This is the central hub for cross-agent reactivity:
//              the RDI sequence and egress monitor both subscribe to
//              this port via TLM analysis FIFOs.
//=============================================================================

class ltsm_monitor extends uvm_monitor;

  `uvm_component_utils(ltsm_monitor)

  // Virtual interface handle
  virtual ltsm_if ltsm_vif;

  // Analysis port — broadcasts every encoding change
  uvm_analysis_port #(ltsm_seq_item) ap;

  // Track previous encoding to detect changes
  ltsm_encoding_e prev_encoding;

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------

  function new(string name = "ltsm_monitor", uvm_component parent = null);
    super.new(name, parent);
    prev_encoding = RESET;
  endfunction

  // -------------------------------------------------------------------------
  //  Build Phase
  // -------------------------------------------------------------------------

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
    if (!uvm_config_db#(virtual ltsm_if)::get(this, "", "ltsm_vif", ltsm_vif))
      `uvm_fatal("LTSM_MON", "Failed to get ltsm_vif from config_db")
  endfunction

  // -------------------------------------------------------------------------
  //  Run Phase — detect and broadcast encoding transitions
  // -------------------------------------------------------------------------

  task run_phase(uvm_phase phase);
    ltsm_seq_item txn;

    // Wait for reset de-assertion
    @(negedge ltsm_vif.rst);

    // Broadcast the initial RESET state
    txn = ltsm_seq_item::type_id::create("ltsm_mon_txn");
    txn.encoding       = RESET;
    txn.lane_map        = ltsm_vif.lane_map;
    ap.write(txn);

    forever begin
      @(posedge ltsm_vif.clk);

      // Detect any change on tx_encoding
        txn = ltsm_seq_item::type_id::create("ltsm_mon_txn");
        txn.encoding          = ltsm_encoding_e'(ltsm_vif.tx_encoding);
        txn.lane_map          = ltsm_vif.lane_map;

        // `uvm_info("LTSM_MON", $sformatf("State transition: %s -> %s (lane_map=3'b%03b)",
        //           prev_encoding.name(), txn.encoding.name(), txn.lane_map), UVM_MEDIUM)

        ap.write(txn);
        prev_encoding = ltsm_encoding_e'(ltsm_vif.tx_encoding);
      end
  endtask

endclass : ltsm_monitor
