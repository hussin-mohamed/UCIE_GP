//=============================================================================
// File       : rdi_monitor.sv
// Project    : UCIe 3.0 TX Logical PHY Verification
// Description: RDI monitor — passively samples flit transactions on the
//              RDI interface. Broadcasts complete flit items via analysis
//              port to the predictor and coverage collector.
//=============================================================================

class rdi_monitor extends uvm_monitor;

  `uvm_component_utils(rdi_monitor)

  // Virtual interface handle
  virtual rdi_if rdi_vif;
  virtual ltsm_if ltsm_vif;

  int count;
  logic [2:0] lp_valid;

  // Analysis port — broadcasts complete flit transactions
  uvm_analysis_port #(rdi_seq_item) ap;

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------

  function new(string name = "rdi_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // -------------------------------------------------------------------------
  //  Build Phase
  // -------------------------------------------------------------------------

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
    if (!uvm_config_db#(virtual rdi_if)::get(this, "", "rdi_vif", rdi_vif))
      `uvm_fatal("RDI_MON", "Failed to get rdi_vif from config_db")
    if (!uvm_config_db#(virtual ltsm_if)::get(this, "", "ltsm_vif", ltsm_vif))
      `uvm_fatal("LTSM_MON", "Failed to get ltsm_vif from config_db")
  endfunction

  // -------------------------------------------------------------------------
  //  Run Phase — sample flit transactions
  // -------------------------------------------------------------------------

  task run_phase(uvm_phase phase);
    rdi_seq_item txn;

    // Wait for reset de-assertion
    @(negedge rdi_vif.rst);

    forever begin
      @(posedge rdi_vif.clk);

      // Detect a valid flit transfer: valid & irdy & trdy all high
      if ((rdi_vif.lp_valid && rdi_vif.lp_irdy && rdi_vif.pl_trdy)) begin
        
        if (ltsm_vif.lane_map == LANE_MAP_ALL_FUNCTIONAL) begin
          count = 2;
        end else begin
          count = 4;
        end

        repeat (count) begin
          txn = rdi_seq_item::type_id::create("rdi_mon_txn");

          // Sample the data from interface
          sample_flit(txn);
          txn.lp_valid = rdi_vif.lp_valid;
          txn.lp_irdy = rdi_vif.lp_irdy;
          txn.pl_trdy = rdi_vif.pl_trdy;

          `uvm_info("RDI_MON", $sformatf("Collected Flit [%0d bytes]",
            rdi_seq_item::active_flit_size), UVM_HIGH)

          // Broadcast to subscribers (predictor, coverage)
          ap.write(txn);

          @(posedge rdi_vif.clk);
        end
        
      end
    end
  endtask

  // -------------------------------------------------------------------------
  //  Sample Flit — extract byte data from the 2D interface array
  // -------------------------------------------------------------------------

  task sample_flit(rdi_seq_item txn);
    // // Determine flit size from configuration
    // // For monitoring, we sample all NBYTES worth of data
    // txn.flit_size = FLIT_256;  // Default — overridden by env_cfg if needed
    // txn.data = new[DEFAULT_NBYTES];

    // for (int i = 0; i < DEFAULT_NBYTES; i++) begin
    //   txn.data[i] = rdi_vif.lp_data[i];
    // end

    txn.data = new[rdi_seq_item::active_flit_size];
    for(int i = 0; i < rdi_seq_item::active_flit_size; i++) begin
      txn.data[i] = rdi_vif.lp_data[i];
    end
  endtask

endclass : rdi_monitor
