UCIe TX Path Verification Environment Details

=============================================================================
1. Architecture & Components
=============================================================================

The TX logical physical layer module (tx_path.sv) handles high-bandwidth parallel flit data, logical-to-physical lane routing, clock domain crossing, and serialization.

Internal Blocks:
* TX Controller (tx_controller.sv): An FSM-based block that processes LTSM state encodings to coordinate resets, training patterns, byte-to-lane mapping, and driver enables.
* Byte-to-Lane Mapper (ucie_byte_to_lane.sv): Maps the 2048-bit incoming logical flit data onto individual active physical lanes (up to 16 lanes). It includes shift registers (ucie_shift_register_b2l.sv) to buffer bytes and adapt widths according to active lane widths.
* Per-Lane ID Generator (per_lane_id_generator_top.svh): Generates unique identification vectors for each lane during the lane reversal state to check mapping alignment at the receiver.
* TX LFSR Scrambler (tx_LFSR_top.sv): Generates pseudo-random binary sequence (PRBS) data patterns for link training, compliance patterns, or active scrambler modes.
* Multiplexer (mux_2_1.sv): Selects between lane ID patterns and normal/scrambled flit data.
* Lane Reversal Mux (reversal.sv): Swaps physical lane mappings dynamically to support logical-to-physical lane reversal.
* Per-Lane FIFO (fifo.sv): Dual-clock rate-matching buffers that bridge the link logic clock domain (i_clk_l) and the fast serializer data clock domain (i_dclk).
* Serializer (serializer.sv): Serializes 64-bit parallel data from each lane FIFO into a single-bit serial stream.
* Clock & Valid Pattern Generator (clk_valid_pattern_generation.sv): Generates forwarded clocks (o_clk_p and o_clk_n), tracking (o_track), and valid (o_valid) signals based on the active state and clock rate mode (full/half-rate).
* Output Driver (driver.sv): Tristates and drives out physical lanes, clocks, and valid pins based on FSM control.

Inputs & Outputs:
* Inputs: 2048-bit logical data (i_lp_data), valid/ready handshakes (i_lp_valid, i_lp_irdy), 9-bit state encoding (i_tx_encoding), 3-bit lane width code (i_lane_map_code), and rate controls (i_halfrate).
* Outputs: 16 physical data lanes (o_data_out), differential clocks (o_clk_p, o_clk_n), valid/track (o_valid, o_track), and protocol-side ready (o_pl_trdy).

=============================================================================
2. Verification Environment UVM Hierarchy
=============================================================================

The verification environment is fully structured using UVM 1.2. The structural hierarchy is organized as follows:

uvm_test_top (e.g., tx_smoke_test, which inherits from tx_base_test)
  |
  +-- tx_env (env)
        |
        +-- tx_env_cfg (cfg) [Environment Configuration Object]
        |
        +-- rdi_agent (rdi_agt) [Active UVM Agent for RDI logical interface]
        |     |
        |     +-- rdi_sequencer (sqr)
        |     +-- rdi_driver (drv)
        |     +-- rdi_monitor (mon)
        |
        +-- ltsm_agent (ltsm_agt) [Active UVM Agent for LTSM control interface]
        |     |
        |     +-- ltsm_sequencer (sqr)
        |     +-- ltsm_driver (drv)
        |     +-- ltsm_monitor (mon)
        |
        +-- tx2link_agent (tx2link_agt) [Passive UVM Agent for physical side monitoring]
        |     |
        |     +-- tx2link_monitor (mon)
        |
        +-- tx_scoreboard (scoreboard) [Data Integrity Checker]
        |     |
        |     +-- uvm_tlm_analysis_fifo #(tx2link_item) actual_fifo
        |     +-- uvm_tlm_analysis_fifo #(rdi_seq_item) rdi_fifo
        |     +-- uvm_tlm_analysis_fifo #(ltsm_seq_item) ltsm_fifo
        |
        +-- tx_coverage (coverage) [Functional Coverage Collector]
        |
        +-- uvm_tlm_analysis_fifo #(ltsm_seq_item) ltsm_to_rdi_fifo [Reactive Cross-Agent FIFO]

Component Roles in the Hierarchy:

* tx_env_cfg: An environment configuration object containing virtual interface handles (rdi_vif, ltsm_vif, tx2link_vif) and operating mode controls. It determines agent activity (active vs. passive) and parses command-line flags.
* rdi_agent: Drives RDI transactions (flit data, valid, ready handshakes) into the DUT. The driver (rdi_driver.sv) monitors the physical layer's ready feedback (pl_trdy) and throttles input transmission dynamically.
* ltsm_agent: Drives LTSM FSM inputs (tx_encoding, lane_map). The driver (ltsm_driver.sv) implements state-dependent delay rules (e.g. waiting for pll_stable/supply_stable, or blocking until tx_done asserts during training patterns).
* tx2link_agent: Passive-only agent that captures actual physical signaling outputs on the fast serial clock domain. Its monitor (tx2link_monitor.sv) uses the current LTSM state to group sampled serial streams into multi-cycle parallel chunks.
* tx_scoreboard: Compares observed physical transactions against behavioral predictions. It integrates the tx_predictor reference model which simulates the internal FSM controller, byte-to-lane mapping (B2L_modelling.sv), LFSR scrambling, and lane reversal. It verifies matches using element-wise checks and supports high-impedance state validation.
* tx_coverage: Subscribes to transaction streams to collect functional coverage metrics.

=============================================================================
3. TLM Interconnections and Data Flows
=============================================================================

Communication between components is handled via UVM TLM 1.0 analysis ports and FIFOs.

* LTSM Monitor to Scoreboard & Coverage:
  - ltsm_agt.mon.ap.connect(scoreboard.ltsm_fifo.analysis_export)
  - ltsm_agt.mon.ap.connect(coverage.ltsm_imp)
  - These connections broadcast state transitions to update the predictor model and log functional coverage.

* Reactive Cross-Agent Flow:
  - ltsm_agt.mon.ap.connect(ltsm_to_rdi_fifo.analysis_export)
  - During virtual sequences, the RDI sequence blocks on ltsm_to_rdi_fifo. It waits to read the ACTIVE state before initiating flit generation, preventing logical traffic from starting prior to link calibration.

* State-Aware Physical Monitoring:
  - ltsm_agt.mon.ap.connect(tx2link_agt.mon.ltsm_state_fifo.analysis_export)
  - The physical monitor uses the state updates to adjust its serial sampling duration (e.g. knowing when a lane ID or data flit transaction is active).

* Scoreboard Main Verification Inputs:
  - tx2link_agt.mon.ap.connect(scoreboard.actual_fifo.analysis_export)
  - rdi_agt.mon.ap.connect(scoreboard.rdi_fifo.analysis_export)
  - These ports feed observed RDI input flits and corresponding link outputs into the scoreboard for comparison.

=============================================================================
4. UVM Phase Execution Flow
=============================================================================

1. Build Phase:
   - Config DB reads the global environment configuration (tx_env_cfg).
   - Config DB retrieves virtual interfaces (rdi_if, ltsm_if, tx2link_if) and propagates them down to agents.
   - Instantiates agents, scoreboard, coverage, and analysis FIFOs.

2. Connect Phase:
   - Hooks up analysis ports from monitors to analysis exports on the scoreboard, coverage block, and TLM FIFOs.
   - Sequencers are registered in the global sqr_pool sequencer pool, allowing virtual sequences to access them without tight component coupling.

3. End of Elaboration Phase:
   - Prints the UVM environment topology tree using uvm_top.print_topology() to verify correct hierarchy construction.

4. Run Phase:
   - Starts virtual sequences (e.g. tx_virtual_seq) to run parallel stimulus.
   - The test raises objections, runs the sequences (which drive LTSM training, wait for ACTIVE, and send RDI flits), waits for scoreboard processing, and drops objections.

5. Report Phase:
   - Scoreboard dumps transaction match/mismatch statistics.
   - Coverage collector reports functional coverage summaries.

=============================================================================
5. Test Scenarios and Sequences
=============================================================================

* Base Test (tx_base_test.sv):
  Sets up the general environment. It checks command-line plusargs (such as +ITER=X) to scale simulation runtime.

* Smoke Test (tx_smoke_test.sv):
  Executes the virtual sequence (tx_virtual_seq.sv) to run a complete link initialization path:
  RESET -> SBINIT -> PARAM -> CAL -> REPAIRCLK -> REPAIRVAL -> REVERSAL -> REPAIRMB -> Training -> LINKINIT -> ACTIVE.
  Once ACTIVE is reached, it verifies the logical-to-physical transfer of 10 flits.

* LTSM Base Sequence (ltsm_base_seq.sv):
  Selects targeted training state groups defined in ltsm_seq_item.sv:
  - GROUP_HAPPY_PATH: A full sequential walk through the training state tree.
  - GROUP_PATTERN_GEN: Focuses on states requiring physical training patterns.
  - GROUP_TRAIN_ERROR: Excercises error-handling states (TRAINERROR).
  - GROUP_TRISTATE: Exercises states where physical link outputs must remain high-impedance.
  - GROUP_ACTIVE: Exercises LINKINIT, ACTIVE, and low-power states (L1, EXIT_HS).
  Can be configured to walk sequentially or generate randomized transitions.

* RDI Base Sequence (rdi_base_seq.sv):
  Waits for the FSM to transition to the ACTIVE state (read reactive FIFO or polled interface), then generates logical flits.

* Reset Sequence (reset_seq.sv):
  Asserts the reset control flag (reset_enb) in the sequence item to command the driver to reset RDI logic and wait for stabilizing delays.

=============================================================================
6. Verification Metrics & Functional Coverage
=============================================================================

Functional coverage is implemented in tx_coverage.sv to track the following coverage metrics:

1. State Coverage (cp_encoding):
   Traces the coverage of all 9-bit LTSM encoding states (SBINIT, MBINIT, Training, Active, and D2C states) to ensure no state is left unvisited.

2. Lane Mapping Coverage (cp_lane_map):
   Verifies that different active lane maps are tested (LANE_MAP_ALL_FUNCTIONAL, LANE_MAP_LANES_0_TO_7, and LANE_MAP_LANES_8_TO_15).

3. Cross Coverage (cx_encoding_x_lane_map):
   Crosses the active FSM states with the lane maps. Focuses on repair states (REPAIRMB and REPAIR) to ensure degradation features are validated for all degradation options.

4. Transition Coverage (cp_transitions):
   Ensures that sequences of states are hit:
   - Happy path training flows (e.g., RESET to SBINIT, SBINIT to PARAM, CAL to REPAIRCLK, etc.).
   - Entry/exit paths to the shared Data-to-Clock (D2C) training FSM.
   - Any-state transitions into training errors (TRAINERROR) and subsequent recovery transitions from TRAINERROR back to RESET.

=============================================================================
7. Exclusive Sequence Scenarios & Flows
=============================================================================

This section lists and describes every stimulus sequence and verification scenario in the TX environment exclusively, detailing their execution flows, configurations, and handshakes:

1. LTSM Base Sequence (ltsm_base_seq.sv):
   - Scope: Stimulates and traverses the training state machine of the logical physical layer.
   - Execution Flow: 
     - Retrieves an ordered array of target states for the active group using the static helper method.
     - If in sequential mode (is_random is 0), it steps through each state in the happy-path array sequentially, randomizing transition delays and lane maps.
     - If in random mode (is_random is 1), it randomizes states constrained inside the current group.
     - Drives these states to the ltsm_driver by executing start_item and finish_item.

2. RDI Base Sequence (rdi_base_seq.sv):
   - Scope: Generates and streams user logical data flits onto the raw RDI interface.
   - Execution Flow:
     - Blocks and waits for the FSM to transition to the ACTIVE state (read from ltsm_state_fifo or polled via pl_state_sts).
     - Loops up to the command-line iteration count (+ITER plusarg) to generate flit data.
     - Inside the loop, it performs a non-blocking check to ensure the state has not transitioned out of ACTIVE. If it has left ACTIVE, it halts transmission.
     - Randomizes RDI payload data byte streams and drives them via start_item and finish_item to the rdi_driver.

3. Reset Sequence (reset_seq.sv):
   - Scope: Asserts system-wide reset sequences on the logical interfaces.
   - Execution Flow:
     - Instantiates an RDI item with reset_enb enabled.
     - Executes the item, signaling the RDI driver to assert the RDI interface reset line for a duration of 100 ns, flushing internal rate-matching buffers and status registers.

4. TX Virtual Sequence (tx_virtual_seq.sv):
   - Scope: The top-level virtual sequence coordinating the concurrent execution of RDI and LTSM streams.
   - Execution Flow:
     - Queries the global sequencer pool (sqr_pool) to retrieve handles for rdi_sqr and ltsm_sqr sequencers.
     - Instantiates child sequences: ltsm_base_seq (ltsm_seq) and rdi_base_seq (rdi_seq).
     - Links the cross-agent analysis FIFO (ltsm_state_fifo) into rdi_seq to enable reactive ACTIVE-state gating.
     - Uses a parallel fork-join block to launch ltsm_seq and rdi_seq concurrently on their respective sequencers.

5. Test base Setup (tx_base_test.sv):
   - Scope: Pre-test build phase scenario.
   - Execution Flow: Builds tx_env_cfg, reads command line parameters, queries virtual interfaces from the config database, sets configurations recursively, and constructs the environment.

6. Smoke Test Scenario (tx_smoke_test.sv):
   - Scope: Execution verification flow.
   - Execution Flow: Raises the phase objection, instantiates tx_virtual_seq, wires its reactive FIFO, starts it, waits for 1000 logic clock cycles of drain time, and drops the phase objection to finish the test.

