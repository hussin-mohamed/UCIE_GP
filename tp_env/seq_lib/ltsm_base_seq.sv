//=============================================================================
// File       : ltsm_base_seq.sv
// Project    : UCIe 3.0 TX Logical PHY Verification
// Description: Minimal LTSM base sequence. All state group definitions
//              live in ltsm_seq_item. The sequence only selects:
//                - group     : which set of states to drive
//                - is_random : 1 = random pick, 0 = ordered walk (with wrap)
//              The driver handles all handshake rules autonomously.
//=============================================================================

class ltsm_base_seq extends uvm_sequence #(ltsm_seq_item);

  `uvm_object_utils(ltsm_base_seq)

  // ---- Control knobs (set from test/vseq before starting) ----

  // Which state group to use
  ltsm_state_group_e group = GROUP_HAPPY_PATH;

  // 1 = random encoding from group, 0 = sequential walk through group
  rand bit is_random;

  // Number of iterations (0 = auto: full walk for sequential, 10 for random)
  int unsigned num_iterations = 0;

  // -------------------------------------------------------------------------
  //  Constructor — parses +ITER plusarg
  // -------------------------------------------------------------------------

  function new(string name = "ltsm_base_seq");
    string val;
    uvm_cmdline_processor clp;
    super.new(name);

    clp = uvm_cmdline_processor::get_inst();
    if (clp.get_arg_value("+ITER=", val)) begin
      num_iterations = val.atoi();
      if (num_iterations <= 0) begin
        `uvm_warning("LTSM_SEQ",
          $sformatf("Invalid +ITER=%0d, using default", num_iterations))
        num_iterations = 0;
      end
    end
  endfunction

  // -------------------------------------------------------------------------
  //  Body — minimal loop, all logic in seq_item
  // -------------------------------------------------------------------------

  task body();
    ltsm_seq_item       req;
    ltsm_encoding_e     states[$];
    int unsigned        idx = 0;
    int unsigned        count;

    // Get the ordered state list for this group
    ltsm_seq_item::get_group_states(group, states);

    // Resolve iteration count
    count = (num_iterations > 0) ? num_iterations :
            (is_random)          ? 10             : states.size();

    `uvm_info("LTSM_SEQ", $sformatf("Starting: group=%0s, mode=%0s, count=%0d",
              group.name(), is_random ? "RANDOM" : "SEQUENTIAL", count), UVM_LOW)

    for (int i = 0; i < count; i++) begin
      req = ltsm_seq_item::type_id::create($sformatf("ltsm_req_%0d", i));
      req.set_group(group);

      start_item(req);

      if (is_random) begin
        // Random: randomize encoding within group constraint
        if (!req.randomize())
          `uvm_error("LTSM_SEQ", "Randomization failed")
      end else begin
        // Sequential: lock encoding to current index, randomize delay/lane_map
        if (!req.randomize() with { encoding == local::states[local::idx]; })
          `uvm_error("LTSM_SEQ", $sformatf("Randomization failed for state %s",
                     states[idx].name()))

        // Advance index with wrap
        idx = (idx + 1) % states.size();
      end

      finish_item(req);

      `uvm_info("LTSM_SEQ", $sformatf("[%0d/%0d] %s",
                i+1, count, req.convert2string()), UVM_MEDIUM)
    end

    `uvm_info("LTSM_SEQ", $sformatf("Complete: %0d states driven", count), UVM_LOW)
  endtask

endclass : ltsm_base_seq
