//=============================================================================
// File       : ltsm_driver.sv
// Project    : UCIe 3.0 TX Logical PHY Verification
// Description: LTSM driver. Drives tx_encoding and lane_map, then handles
//              per-state wait rules:
//                RESET             → waits for pll_stable && supply_stable
//                Pattern gen/apply → waits for tx_done
//                Everything else   → waits req.delay clock cycles
//=============================================================================

class ltsm_driver extends uvm_driver #(ltsm_seq_item);

  `uvm_component_utils(ltsm_driver)

  // Virtual interface handle
  virtual ltsm_if ltsm_vif;

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------

  function new(string name = "ltsm_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // -------------------------------------------------------------------------
  //  Build Phase
  // -------------------------------------------------------------------------

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual ltsm_if)::get(this, "", "ltsm_vif", ltsm_vif))
      `uvm_fatal("LTSM_DRV", "Failed to get ltsm_vif from config_db")
  endfunction

  // -------------------------------------------------------------------------
  //  Run Phase — main driving loop
  // -------------------------------------------------------------------------

  task run_phase(uvm_phase phase);
    ltsm_seq_item req;

    // Initialize to RESET encoding
    ltsm_vif.tx_encoding <= RESET;
    ltsm_vif.lane_map    <= LANE_MAP_ALL_FUNCTIONAL;

    // Wait for reset de-assertion
    @(negedge ltsm_vif.rst);
    @(posedge  ltsm_vif.clk);

    forever begin
      seq_item_port.get_next_item(req);

      // Drive the encoding and lane_map
      drive_encoding(req);

      // Transaction complete
      seq_item_port.item_done();
    end
  endtask

  // -------------------------------------------------------------------------
  //  Drive Encoding — apply encoding, then wait per state rules
  // -------------------------------------------------------------------------

  task drive_encoding(ltsm_seq_item req);
    // Drive control signals
    ltsm_vif.tx_encoding <= req.encoding;
    ltsm_vif.lane_map    <= req.lane_map;

    @(posedge ltsm_vif.clk);

    `uvm_info("LTSM_DRV", $sformatf("Driving: %s, lane_map=3'b%03b",
              req.encoding.name(), req.lane_map), UVM_MEDIUM)

    // Wait based on state category
    wait_for_completion(req);
  endtask

  // -------------------------------------------------------------------------
  //  Wait for Completion — state-dependent blocking
  // -------------------------------------------------------------------------

  task wait_for_completion(ltsm_seq_item req);
    case (req.encoding)

      // RESET: wait for PLL and supply to stabilize
      RESET: begin
        `uvm_info("LTSM_DRV", "Waiting for pll_stable && supply_stable...", UVM_MEDIUM)
        wait (ltsm_vif.pll_stable && ltsm_vif.supply_stable);
        @(posedge ltsm_vif.clk);
        `uvm_info("LTSM_DRV", "PLL and supply stable — exiting RESET", UVM_MEDIUM)
      end

      // Pattern gen + apply/reversal states: wait for tx_done
      REPAIRCLK_CLK_PATTERN_GEN,
      REPAIRVAL_VALID_PATTERN_GEN,
      REVERSAL_PER_LANE_ID_GEN,
      D2C_TX_PATTERN_GEN,
      D2C_RX_PATTERN_GEN,
      REVERSAL_APPLY,
      REPAIRMB_APPLY_DEGRADE_HND,
      REPAIR_APPLY_DEGRADE_HND: begin
        `uvm_info("LTSM_DRV", "Waiting for tx_done...", UVM_MEDIUM)
        wait (ltsm_vif.tx_done);
        @(posedge ltsm_vif.clk);
        `uvm_info("LTSM_DRV", "tx_done asserted — operation complete", UVM_MEDIUM)
      end

      // All other states: hold encoding for the random delay then proceed
      default: begin
        if (req.delay > 0) begin
          `uvm_info("LTSM_DRV", $sformatf("Holding encoding for %0d cycles", req.delay), UVM_HIGH)
          repeat (req.delay) @(posedge ltsm_vif.clk);
        end
      end

    endcase
  endtask

endclass : ltsm_driver
