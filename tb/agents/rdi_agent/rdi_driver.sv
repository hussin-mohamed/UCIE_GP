//=============================================================================
// File       : rdi_driver.sv
// Project    : UCIe 3.0 TX Logical PHY Verification
// Description: Reactive RDI driver. Monitors pl_trdy for backpressure.
//              When pl_trdy is de-asserted, the driver holds lp_data,
//              lp_valid, and lp_irdy stable until pl_trdy re-asserts.
//=============================================================================

class rdi_driver extends uvm_driver #(rdi_seq_item);

  `uvm_component_utils(rdi_driver)

  // Virtual interface handle
  virtual rdi_if rdi_vif;

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------

  function new(string name = "rdi_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // -------------------------------------------------------------------------
  //  Build Phase — get virtual interface
  // -------------------------------------------------------------------------

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual rdi_if)::get(this, "", "rdi_vif", rdi_vif))
      `uvm_fatal("RDI_DRV", "Failed to get rdi_vif from config_db")
  endfunction

  // -------------------------------------------------------------------------
  //  Run Phase — main driving loop
  // -------------------------------------------------------------------------

  task run_phase(uvm_phase phase);
    rdi_seq_item req;

    // Initialize outputs to idle
    rdi_vif.lp_data  <= '0;
    rdi_vif.lp_valid <= 1'b0;
    rdi_vif.lp_irdy  <= 1'b0;

    // Wait for reset de-assertion
    @(posedge rdi_vif.rst_n);
    @(posedge rdi_vif.clk);

    forever begin
      // Get next transaction from sequencer
      seq_item_port.get_next_item(req);

      // Apply inter-flit delay
      if (req.delay > 0) begin
        rdi_vif.lp_valid <= 1'b0;
        rdi_vif.lp_irdy  <= 1'b0;
        repeat (req.delay) @(posedge rdi_vif.clk);
      end

      // Drive the flit
      drive_flit(req);

      // Transaction complete
      seq_item_port.item_done();
    end
  endtask

  // -------------------------------------------------------------------------
  //  Drive Flit Task — handles backpressure reactively
  // -------------------------------------------------------------------------

  task drive_flit(rdi_seq_item req);
    int unsigned bp_cycles = 0;

    // Assert ready and valid, place data
    rdi_vif.lp_irdy  <= 1'b1;
    rdi_vif.lp_valid <= 1'b1;
    rdi_vif.lp_data  <= pack_data(req);

    @(posedge rdi_vif.clk);

    // Wait for pl_trdy — hold data/valid/irdy stable during backpressure
    while (!rdi_vif.pl_trdy) begin
      bp_cycles++;
      // Hold all signals stable (already driven above)
      @(posedge rdi_vif.clk);
    end

    // Transfer accepted (pl_trdy is high)
    // Data was sampled this cycle

    // De-assert after transfer
    rdi_vif.lp_valid <= 1'b0;
    rdi_vif.lp_irdy  <= 1'b0;

    if (bp_cycles > 0)
      `uvm_info("RDI_DRV", $sformatf("Flit driven: size=%0s, stalled %0d cycles on pl_trdy",
                req.active_flit_size.name(), bp_cycles), UVM_HIGH)
    else
      `uvm_info("RDI_DRV", $sformatf("Flit driven: size=%0s, no backpressure",
                req.active_flit_size.name()), UVM_HIGH)
  endtask

  // -------------------------------------------------------------------------
  //  Helper: Pack dynamic byte array into 2D interface data format
  // -------------------------------------------------------------------------

  function logic [DEFAULT_NBYTES-1:0][7:0] pack_data(rdi_seq_item item);
    logic [DEFAULT_NBYTES-1:0][7:0] packed_data = '0;
    foreach (item.data[i]) begin
      if (i < DEFAULT_NBYTES)
        packed_data[i] = item.data[i];
    end
    return packed_data;
  endfunction

endclass : rdi_driver
