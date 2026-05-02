//=============================================================================
// File       : rdi_base_seq.sv
// Project    : UCIe 3.0 TX Logical PHY Verification
// Description: RDI base sequence — cross-agent reactive via TLM FIFO.
//              Only generates flit data when the LTSM state is ACTIVE.
//              Backpressure (pl_trdy) is handled transparently by the driver.
//              The FIFO handle is set by the environment before starting.
//=============================================================================

class rdi_base_seq extends uvm_sequence #(rdi_seq_item);

  `uvm_object_utils(rdi_base_seq)

  // TLM FIFO handle for LTSM state monitoring (set by env/vseq)
  uvm_tlm_analysis_fifo #(ltsm_seq_item) ltsm_state_fifo;

  // Number of flits to generate (default 10, overridden by +ITER plusarg)
  int unsigned num_flits = 10;

  // -------------------------------------------------------------------------
  //  Constructor — parses +ITER plusarg
  // -------------------------------------------------------------------------

  function new(string name = "rdi_base_seq");
    string val;
    uvm_cmdline_processor clp;
    super.new(name);

    clp = uvm_cmdline_processor::get_inst();
    if (clp.get_arg_value("+ITER=", val)) begin
      num_flits = val.atoi();
      if (num_flits <= 0) begin
        `uvm_warning("RDI_SEQ",
          $sformatf("Invalid +ITER=%0d, using default 10", num_flits))
        num_flits = 10;
      end
      `uvm_info("RDI_SEQ", $sformatf("Iterations set to %0d flits", num_flits), UVM_LOW)
    end
  endfunction

  // -------------------------------------------------------------------------
  //  Body — wait for ACTIVE state, then generate flits
  // -------------------------------------------------------------------------

  task body();
    rdi_seq_item req;
    ltsm_seq_item ltsm_txn;
    int flit_count = 0;

    if (ltsm_state_fifo == null)
      `uvm_fatal("RDI_SEQ", "ltsm_state_fifo handle is null — must be set before starting")

    // Outer loop — re-enters whenever ACTIVE is reached again
    forever begin

      `uvm_info("RDI_SEQ", "Waiting for ACTIVE state from LTSM...", UVM_LOW)

      // Block until LTSM enters ACTIVE state
      forever begin
        ltsm_state_fifo.get(ltsm_txn);
        if (ltsm_txn.encoding == ACTIVE) begin
          `uvm_info("RDI_SEQ", "ACTIVE state detected — starting flit generation", UVM_LOW)
          break;
        end else begin
          `uvm_info("RDI_SEQ", $sformatf("State %s — not ACTIVE, waiting...",
                    ltsm_txn.encoding.name()), UVM_MEDIUM)
        end
      end

      // Generate flits while in ACTIVE
      for (int i = 0; i < num_flits; i++) begin

        // Non-blocking check: has the state left ACTIVE?
        if (ltsm_state_fifo.try_get(ltsm_txn)) begin
          if (ltsm_txn.encoding != ACTIVE) begin
            `uvm_info("RDI_SEQ", $sformatf("State changed to %s — halting flit gen after %0d flits",
                      ltsm_txn.encoding.name(), i), UVM_LOW)
            break;  // break for-loop → outer forever re-waits for ACTIVE
          end
        end

        req = rdi_seq_item::type_id::create($sformatf("rdi_flit_%0d", flit_count));
        start_item(req);

        if (!req.randomize()) begin
          `uvm_error("RDI_SEQ", "Randomization failed")
        end

        finish_item(req);

        flit_count++;
        `uvm_info("RDI_SEQ", $sformatf("Flit %0d sent: %s",
                  flit_count, req.convert2string()), UVM_MEDIUM)
      end

    end // forever
  endtask

endclass : rdi_base_seq
