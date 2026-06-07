UCIe RX Path Verification Environment Details

=============================================================================
1. Architecture & Components
=============================================================================

The RX logical physical layer module (rx_path.sv) receives high-speed serialized signals from the physical medium, deserializes them, handles clock domain crossing, checks training alignment, and maps them back to parallel RDI flit data.

Internal Blocks:
* Receivers (receivers.sv): Buffers incoming serialized physical data lanes (i_lanes), forwarding clocks (i_clk_p, i_clk_n), tracking (i_track), and valid (i_valid) based on FSM-driven enable controls.
* Clock & Valid Pattern Detection (clk_valid_pattern_detection.sv): Detects and verifies the forwarding clocks, track, and valid signals on the dclk and hclk domains against compliance patterns.
* Deserializers (deserializer_h.sv / deser_h): Deserializes physical single-bit serial streams from the receiver into parallel 64-bit wide data channels.
* Per-Lane FIFO (fifo.sv): Dual-clock rate-matching buffers that bridge the high-speed data clock write domain (i_dclk) and the logical clock read domain (i_clk_l).
* Demultiplexer (demux_1_2.sv): Directs the rate-matched parallel lane data to either the lane ID detector path or the LFSR training/descrambling paths.
* Per-Lane ID Detector (per_lane_id_detector_top.svh): Detects the unique lane ID patterns received during the reversal check state to verify lane alignment.
* RX LFSR Descrambler/Checker (rx_LFSR_top.sv): Checks LFSR pattern success during training and descrambles data during active logical data flow.
* Lane-to-Byte Mapper (ucie_lane_to_byte.sv): Takes parallel 64-bit streams from active lanes, reorders them, and reassembles them back into the 2048-bit wide logical data interface (o_pl_data, o_pl_valid).
* Synchronizers (synchonizer.sv): Synchronize control signals (like pattern types and detection results) across clock domains (i_clk_l to i_dclk, and vice-versa).
* RX Controller (ucie_rx_controller.sv): An FSM orchestrator running on the logical clock (i_clk_l) domain that handles state machine transitions, triggers pattern detection routines, processes training success/error inputs, and manages resets.

Inputs & Outputs:
* Inputs: Clocks & resets (i_clk_l, i_clk_p, i_clk_n, i_hclk, i_dclk, i_track, i_reset), 16 serialized data lanes (i_lanes), physical valid (i_valid), half-rate control (i_halfrate), 9-bit state encoding (i_rx_encoding), 3-bit lane configuration code (i_lane_map_code), and error thresholds (i_error_threshold).
* Outputs: 2048-bit parallel data flits (o_pl_data), RDI valid output (o_pl_valid), completion status (o_rx_done), metric registers (o_rx_data_results), error flag (o_rx_error), and clock/valid verification metrics (o_clk_results, o_valid_results).

=============================================================================
2. Verification Environment UVM Hierarchy
=============================================================================

The verification environment is fully structured using UVM 1.2. The structural hierarchy is organized as follows:

uvm_test_top (e.g., rp_sanity_all_test, which inherits from rp_test_base)
  |
  +-- rp_env (env)
        |
        +-- env_config (env_cfg) [Environment Configuration Object]
        |
        +-- reset_driver (rst_drvr) [Drives testbench resets under simulation]
        |
        +-- rdi_agent (rdi_agt) [Passive UVM Agent for logical output monitoring]
        |     |
        |     +-- rdi_monitor (mon)
        |
        +-- ltsmc_agent (ltsmc_agt) [Active UVM Agent for LTSM FSM input control]
        |     |
        |     +-- ltsmc_sequencer (seqr)
        |     +-- ltsmc_driver (drv)
        |     +-- ltsmc_monitor (mon)
        |
        +-- rmblink_agent (rmblink_agt) [Active UVM Agent driving physical medium simulation]
        |     |
        |     +-- rmblink_sequencer (seqr)
        |     +-- rmblink_driver (drv)
        |     +-- rmblink_monitor (mon)
        |
        +-- rp_scoreboard (sb) [Data and Handshake Checker]
        |     |
        |     +-- rp_pred (prd) [Reference Predictor Model]
        |     +-- rp_cmp_rdi (cmp_rdi) [RDI Output Data Comparator]
        |     +-- rp_cmp_ltsmc (cmp_ltsmc) [LTSM Result Status Comparator]
        |
        +-- rp_coverage_collector (cvg) [Functional Coverage Collector]
        |
        +-- virtual_sequencer (vseqr) [Virtual Sequencer Coordinator]

Component Roles in the Hierarchy:

* env_config: Holds configuration flags, virtual interfaces, and controls BFM activity parameters (such as enabling active vs passive drivers).
* rdi_agent: Monitored passive agent that collects logical RDI transactions (o_pl_data, o_pl_valid) at the logical interface boundaries to check correct flit reassembly.
* ltsmc_agent: Active agent that feeds FSM controls (rx_encoding, lane_map_code, error_threshold) into the DUT. The driver (ltsmc_driver.svh) manages handshakes and timing.
* rmblink_agent: Drives physical serial data (i_lanes), valid, track, and clocks to simulate the physical medium. Its driver (rmblink_driver.svh) puts data patterns on the link.
* rp_scoreboard: Wrapper scoreboarding block containing the predictor (rp_pred.svh) and comparators (rp_cmp_rdi.svh, rp_cmp_ltsmc.svh).
* rp_pred: Receives stimulus from ltsmc_agent and rmblink_agent. It simulates per-lane ID matching, LFSR scrambling/descrambling, error threshold counts, and lane-to-byte mapping in software to predict expected o_pl_data flits and FSM results (o_rx_data_results).
* rp_coverage_collector: Subscribes to transaction monitors to sample functional coverage metrics.
* virtual_sequencer: Manages sequencer child handles (rdi_seqr, ltsmc_seqr, rmblink_seqr) to run virtual sequences in coordination.

=============================================================================
3. TLM Interconnections and Data Flows
=============================================================================

Communication is handled via standard TLM analysis ports and exports:

* Predictor Inputs (Stimulus):
  - rmblink_agt.in_ap.connect(prd.axp_in_rmblink)
  - ltsmc_agt.in_ap.connect(prd.axp_in_ltsmc)
  - The predictor reads the same physical link inputs and LTSM configurations driven into the DUT.

* Scoreboard Comparators Connections:
  - prd.results_ap_rdi.connect(cmp_rdi.axp_in_exp) [Expected RDI flits]
  - prd.results_ap_ltsmc.connect(cmp_ltsmc.axp_in_exp) [Expected status results]
  - rdi_agt.out_ap.connect(cmp_rdi.axp_out_actual) [Actual RDI outputs]
  - ltsmc_agt.out_ap.connect(cmp_ltsmc.axp_out_actual) [Actual FSM status results]

* Coverage Collector Inputs:
  - rmblink_agt.in_ap.connect(cvg.rmblink_exp)
  - ltsmc_agt.in_ap.connect(cvg.ltsm_exp)

=============================================================================
4. UVM Phase Execution Flow
=============================================================================

1. Build Phase:
   - Fetches configuration object (env_config) and extracts virtual interfaces.
   - Factory builds sub-components (agents, scoreboards, coverage collector, sequencer).
   - Distributes configurations to agents.

2. Connect Phase:
   - Connects agent monitors to the scoreboard and coverage collectors.
   - Wires predictor outputs to comparators.
   - Registers child sequencer handles to the virtual sequencer.

3. End of Elaboration Phase:
   - Instantiates the virtual sequence base and prints testbench topology via uvm_top.print_topology().

4. Run Phase (main_phase):
   - Starts virtual sequences (e.g. rp_active_vseq or rp_sanity_all_vseq) on the virtual sequencer.
   - Handles active reset testing by jumping phases: if a reset is triggered, it calls phase.jump(uvm_pre_reset_phase::get()) to clear tracking logic and re-initialize.

5. Final Phase:
   - Prints factory override status and outputs test summary.

=============================================================================
5. Test Scenarios and Sequences
=============================================================================

* Base Test (rp_test_base.svh):
  Sets up virtual interfaces, runs sequences, and handles phase jump mechanisms for idle and active resets.

* Sanity Clock Test (rp_sanity_clk_test.svh):
  Runs rp_clk_sanity_vseq.svh to verify the DUT's clock-pattern validation checks. It triggers repair clocks, sends training clock signals, and tests error results.

* Sanity Valid Test (rp_sanity_valid_test.svh):
  Runs rp_vaild_sanity_vseq.svh to test valid-signal patterns (seq_8bit_pattern with 11110000 window checks).

* Sanity Per-Lane ID Test (rp_sanity_PerLaneID_test.svh):
  Runs rp_sanity_PerLaneID_vseq.svh to verify logical lane reordering and identification during reversal checks.

* Sanity LFSR Test (rp_sanity_lfsr_test.svh):
  Runs rp_sanity_lfsr_vseq.svh to test LFSR training sequences and error counter validations.

* Active Test (rp_active_test.svh):
  Runs rp_active_vseq.svh to verify data flow, deserialization, rate-matching, and lane-to-byte packing during the ACTIVE state.

* Sanity All Test (rp_sanity_all_test.svh):
  Runs rp_sanity_all_vseq.svh to walk through the entire training flow sequentially.

=============================================================================
6. SystemVerilog Assertions (SVA) Checking (rp_sva.sv)
=============================================================================

The testbench binds a dedicated SVA checker interface (rp_sva.sv) to check temporal handshakes, pattern timings, and reset defaults:

* Valid Pattern checking (assert_valid_pattern_16_frame):
  Asserts that when the FSM is in the valid pattern detection state, a valid 8-bit frame (four 1s followed by four 0s: 11110000) repeats consecutively within the window. If errors exceed the configuration threshold, the test reports a failure.

* Clock and Track pattern checking:
  - assert_clk_p_pattern_frame: Asserts differential clock patterns on positive forwarded clock pins.
  - assert_clk_n_pattern_frame: Asserts clock patterns on negative forwarded clock pins.
  - assert_track_pattern_frame: Asserts tracking signal transitions.

* Result Reporting Assertions:
  Asserts that output results (o_clk_results, o_valid_results) match the internal evaluation results when result-handshakes are initialized.

* Reset State Assertions:
  - chk_async_reset_zeros: Verifies o_pl_data and o_pl_valid are driven to zero during system reset.
  - chk_async_reset_ones: Verifies o_rx_done, o_rx_data_results, o_clk_results, and o_valid_results are driven to one during reset.

=============================================================================
7. Exclusive Sequence Scenarios & Flows
=============================================================================

This section lists and describes every stimulus sequence and verification scenario in the RX environment exclusively, detailing their execution flows, configurations, and handshakes:

1. LTSMC Control Sequence (ltsmc_sequence.svh):
   - Scope: Drives the Link Training and Status State Machine configurations on the control interface of the RX Logical PHY.
   - Execution Flow:
     - Configures the next state type, lane map configurations, error threshold levels, and clock rate mode.
     - If in NEXT mode, it increments the internal pointer index and advances to the next state inside the linear happy-path array.
     - If in CUSTOM mode, it forces the state machine directly to a target FSM state (e.g. jumping to RESET_Reset to clear error count registers).
     - If in TRAVERSE mode, it performs a loop to step through each FSM state sequentially from the current pointer up to a target FSM state.
     - Sends each state transaction to the driver using start_item and finish_item.

2. RMBLink Sanity Clock Sequence (rmblink_sanity_clk_sequence.svh):
   - Scope: Generates forwarding clocks stimulus for physical clocks validation.
   - Execution Flow:
     - Checks the active test mode.
     - Generates differential clock signals on positive (i_clk_p) and negative (i_clk_n) clock pins and tracking (i_track) signals.
     - Tests validation parameters like clock frequency checks and clock track mismatches.

3. RMBLink Sanity Valid Sequence (rmblink_sanity_valid_sequence.svh):
   - Scope: Generates physical valid pattern sequences.
   - Execution Flow:
     - Drives a continuous series of valid pulses (four 1s, four 0s: 11110000) into the physical valid input (i_valid).
     - Can introduce edge offsets or drops to test that the DUT correctly logs valid pattern errors and reports the result.

4. RMBLink Sanity Per-Lane ID Sequence (rmblink_sanity_PerLaneID_sequence.svh):
   - Scope: Drives unique lane ID values on physical wires.
   - Execution Flow:
     - Serializes and drives the specified lane ID format (e.g. 1010 followed by lane number and 1010) on the physical input lanes.
     - Assists in validating logical reordering logic under physical lane reversal conditions.

5. RMBLink Sanity LFSR Sequence (rmblink_sanity_lfsr_sequence.svh):
   - Scope: Drives PRBS training frames over physical lines.
   - Execution Flow:
     - Transmits LFSR compliance patterns across the active physical lanes.
     - Verifies correct locking, training error counts, and success flags.

6. RMBLink Active Sequence (rmblink_active_sequence.svh):
   - Scope: Drives scrambled payload data streams in the active state.
   - Execution Flow:
     - Generates and drives continuous randomized data streams onto the physical serial lanes using LFSR scrambling parameters, simulating active data reception.

7. Base Sequence (rp_sequence_base.svh):
   - Scope: Coordinates child sequencer references.
   - Execution Flow: Asserts standard sequence initialization parameters and checks virtual interfaces.

8. Virtual Sequence Base (virtual_sequence_base.svh):
   - Scope: Virtual sequence parent template.
   - Execution Flow: Checks and casts the virtual sequencer reference and registers local sequencer pointers.

9. RX Clock Sanity Virtual Sequence (rp_clk_sanity_vseq.svh):
   - Scope: Coordinates clock validation tests.
   - Execution Flow:
     - Configures the LTSM sequence to walk to MBINIT_REPAIRCLK_RX_Init_Handshake and wait for repair completion.
     - Commands the FSM to transition back to reset.
     - Initiates rmblink_sanity_clk_sequence.
     - Loops to test the next clock test mode.

10. RX Valid Sanity Virtual Sequence (rp_vaild_sanity_vseq.svh):
    - Scope: Coordinates valid wire checks.
    - Execution Flow: Commands FSM to go to MBINIT_REPAIRVAL_RX_Valid_Pattern_Det and starts rmblink_sanity_valid_sequence in parallel.

11. RX Per-Lane ID Sanity Virtual Sequence (rp_sanity_PerLaneID_vseq.svh):
    - Scope: Coordinates reversal check verification.
    - Execution Flow: Traverses FSM to MBINIT_REVERSAL_RX_Per_Lane_ID_Det and starts rmblink_sanity_PerLaneID_sequence.

12. RX LFSR Sanity Virtual Sequence (rp_sanity_lfsr_vseq.svh):
    - Scope: Coordinates LFSR checking verification.
    - Execution Flow: Walks FSM to Data-to-Clock test states and executes rmblink_sanity_lfsr_sequence.

13. RX Active Virtual Sequence (rp_active_vseq.svh):
    - Scope: Coordinates active data reassembly checks.
    - Execution Flow: Walks FSM up to ACTIVE_RX_Active and starts parallel rmblink_active_sequence payload transmissions.

14. RX Sanity All Virtual Sequence (rp_sanity_all_vseq.svh):
    - Scope: The top-level master sequence walking through the entire training flow.
    - Execution Flow: Executes all training validation blocks (repair clocks, valid pattern checks, per-lane ID reordering, LFSR training, lane width degradation repair, active link initialization, and active flit transfers) sequentially.

