UCIe System-Level Verification Environment Details

=============================================================================
1. Architecture & Top-Level Bindings
=============================================================================

System-level verification is conducted using the top testbench file ucie_tb_top.sv, which connects the full physical layer design to active and passive verification components.

DUT Wrapper (UCIe_phy):
The top-level design module (UCIe_phy) wraps and integrates all logical physical layer blocks, including:
* PLL model (PLL_model): Simulates phase-locked loops for generating logical clock (clk_l), half-rate clock (clk_mb_h), and full-rate clock (clk_mb_f).
* LTSM State Machine (ucie_LTSM): Processes control states, training steps, and link handshakes.
* Sideband Block (ucie_sb_top): Handles sideband packet transmissions, command mapping, and registers.
* TX Path Block (tx_dut_rtl_wrapper): Performs TX logical byte-to-lane mapping, rate buffering, and serialization.
* RX Path Block (rx_path): Performs RX physical signal recovery, valid pattern checks, deserialization, and byte-to-lane reassembly.
Inside the DUT wrapper, the TX logical output lanes are connected back-to-back with the RX mainband inputs, allowing full loopback data testing.

Interface Bindings and Connections:
The top testbench (ucie_tb_top.sv) instantiates and registers the following interfaces in the UVM configuration database:
* rp_rmblink_bfm_inst: Drives simulated RX physical mainband inputs (i_clk_p, i_clk_n, i_track, i_valid, i_data_in) into the DUT.
* phylink_bfm: Simulates the sideband physical channel (i_rx_sb_clk, i_rx_sb_data, o_tx_sb_data, o_tx_sb_clk).
* tx2link_intf: Passive interface that monitors the physical TX outputs (o_data_out lanes, clocks, track, valid) from the DUT.
* rdi_intf: Drives logical RDI inputs (lp_irdy, lp_valid, lp_data) into the TX path and monitors RDI backpressure (pl_trdy).
* ltsm_rdi_if_inst: Drives the LTSM logical interface signals (i_lp_state_req, i_lp_linkerror, i_lp_stallack, i_lp_clk_ack, i_lp_wake_req, and reads o_pl_state_sts).
* rp_rdi_bfm_inst: Monitored passive interface capturing logical RDI output data (o_pl_data, o_pl_valid) reassembled by the RX path.
* rp_ltsmc_bfm_inst: Connects to the RX control interface to feed state encodings and capture completion statuses.

Sideband Assertions Binding:
System-level temporal checks for the sideband protocol are integrated by binding a sideband assertions block (sb_sva) directly to the ucie_sb_top instance inside the DUT using the statement:
bind ucie_sb_top sb_sva sva_inst ( ... );
This binds physical sideband lines, control registers, request flags, and command packets to check sideband initialization and message transmission.

=============================================================================
2. Verification Environment UVM Hierarchy
=============================================================================

The top-level system environment is ucie_env.sv. Its structural hierarchy is organized as follows:

uvm_test_top (e.g., ucie_sanity_test, which inherits from ucie_base_test)
  |
  +-- ucie_env (env)
        |
        +-- ucie_env_cfg (m_cfg) [System Environment Configuration Object]
        |     |
        |     +-- LTSM_pkg::env_config (ltsm_cfg)
        |     +-- sb_pkg::env_config (sb_cfg)
        |     +-- rp_pkg::env_config (rp_cfg)
        |     +-- tx_tb_pkg::tx_env_cfg (tx_cfg)
        |
        +-- ucie_vseqr (vseqr) [Master Virtual Sequencer Object]
        |     |
        |     +-- sb_pkg::sb_pred_link2ltsm (prd_link2ltsm) [Sideband RX Predictor]
        |     +-- sb_pkg::sb_pred_ltsm2link (prd_ltsm2link) [Sideband TX Predictor]
        |     +-- uvm_tlm_analysis_fifo #(sb_pkg::ltsm_seq_item) tx_fifo
        |     +-- uvm_tlm_analysis_fifo #(sb_pkg::ltsm_seq_item) rx_fifo
        |     +-- uvm_tlm_analysis_fifo #(sb_pkg::phylink_seq_item) link_fifo
        |
        +-- LTSM_pkg::LTSM_env (ltsm_env_i) [LTSM Verification Sub-Environment]
        |     |
        |     +-- ltsm_rdi_agent [Active: drives RDI control state handshakes]
        |     +-- tx_fsm_sb_agent [Passive: monitors TX status]
        |     +-- rx_fsm_sb_agent [Passive: monitors RX status]
        |     +-- LTSM_controllers_agent [Passive: monitors controller flags]
        |
        +-- sb_pkg::sb_env (sb_env_i) [Sideband Verification Sub-Environment]
        |     |
        |     +-- phylink_agent [Active: drives sideband physical interfaces]
        |     +-- ltsm_ctrl_agent [Passive]
        |     +-- tx_agent [Passive]
        |     +-- rx_agent [Passive]
        |     +-- rdi_agent [Passive]
        |
        +-- rp_pkg::rp_env (rp_env_i) [RX-Path Verification Sub-Environment]
        |     |
        |     +-- rmblink_agent [Active: drives physical rx input lanes and clocks]
        |     +-- rdi_agent [Passive]
        |     +-- ltsmc_agent [Passive]
        |
        +-- tx_tb_pkg::tx_env (tx_env_i) [TX-Path Verification Sub-Environment]
              |
              +-- rdi_agent [Active: drives logical tx inputs and handshakes]
              +-- ltsm_agent [Passive]

Sub-Environments and Operating Modes:
* LTSM Environment: Configured with ltsm_rdi_agent in UVM_ACTIVE mode to drive adapter state requests, while other monitoring agents are set to UVM_PASSIVE.
* Sideband Environment: Configured with the physical link agent (phylink_agent) in UVM_ACTIVE mode to stimulate sideband serial lines, while internal controllers are passive.
* RX-Path Environment: Configured with the rmblink_agent in UVM_ACTIVE mode to drive physical wires (lanes, valid, clocks, track), while logical checkers remain passive.
* TX-Path Environment: Configured with the logical RDI agent in UVM_ACTIVE mode to send logical flits, while training checkers are passive.

=============================================================================
3. TLM Interconnections & Connections
=============================================================================

The master virtual sequencer (ucie_vseqr.sv) acts as the connection hub for coordination.

* Child Sequencer Routing (Connect Phase):
  - vseqr.ltsm_rdi_seqr   = ltsm_env_i.rdi_agt.seqr;
  - vseqr.sb_phylink_seqr = sb_env_i.phylink_agt.seqr;
  - vseqr.rp_rmblink_seqr = rp_env_i.rmblink_agt.seqr;
  - vseqr.tx_rdi_seqr     = tx_env_i.rdi_agt.get_sequencer();

* Sideband Reactive Prediction Pipeline:
  - sb_env_i.phylink_agt.out_ap.connect(vseqr.axp_in)
  - vseqr.axp_in.connect(vseqr.prd_link2ltsm.analysis_export)
  - When the physical sideband receiver captures a packet, it streams the transaction to the predictor (prd_link2ltsm).
  - The predictor resolves the sideband message type and pushes it to rx_fifo (for messages going from the DUT's TX to the testbench RX) or tx_fifo (for messages going from the DUT's RX to the testbench TX).
  - Virtual sequences read these FIFOs to process sideband requests reactively.

=============================================================================
4. UVM Phase Execution Flow
=============================================================================

1. Build Phase:
   - Retrieves the top system config (ucie_env_cfg).
   - Factory builds the master virtual sequencer (ucie_vseqr) and instantiates its internal sideband predictors.
   - Sets sub-configurations (ltsm_cfg, sb_cfg, rp_cfg, tx_cfg) to define active/passive agents.
   - Instantiates sub-environments.

2. Connect Phase:
   - Wires child sequencer references to the virtual sequencer handles.
   - Connects the sideband monitor port to the virtual sequencer's predictors.
   - Wires predictor outputs to the internal reactive FIFOs (tx_fifo, rx_fifo).

3. End of Elaboration Phase:
   - Instantiates the virtual sequence base (ucie_vseq_base.sv) and prints the testbench topology tree.

4. Run Phase (main_phase):
   - Launches virtual sequences on the master sequencer.
   - Monitors the physical reset line. If a reset is hit (m_cfg.sb_cfg.phylink_bfm_drive.reset goes high), the base test triggers a phase jump:
     phase.jump(uvm_pre_reset_phase::get());
     This resets state trackers, flushes analysis FIFOs, and restarts training.

5. Final Phase:
   - Prints factory overrides and ends simulation.

=============================================================================
5. Exclusive System-Level Sequence Scenarios
=============================================================================

This section describes every system-level sequence in the UCIE_top_env seq_lib directory, explaining their configurations and operations exclusively:

1. Master Virtual Sequence Base (ucie_vseq_base.sv):
   - Scope: The base class for all system virtual sequences.
   - Execution Flow: 
     - Instantiates all child sequences (active_phylink_seq, sbinit_phylink_seq, sbinit_phylink_random_seq, rmblink_clk_seq, rmblink_valid_seq, rmblink_lfsr_seq, active_rx_seq, active_tx_seq, rmblink_PerLaneID_seq) and virtual sequences.
     - Spawns a background thread in pre_body() that continuously polls link_fifo and drives physical sideband serial streams using active_phylink_seq.
     - Implements send_sb_msg() and send_sb_msg_blocking() helper tasks to feed predicted transactions from the LTSM model to the link.

2. Sideband Bringup Virtual Sequence (ucie_sbinit_vseq.sv):
   - Scope: Directs Sideband Initialization (SBINIT) testing.
   - Execution Flow: Coordinates starting the sideband initialization sequences to check that the sideband link achieves sb_ready status.

3. RX Sideband Bringup Virtual Sequence (ucie_sbinit_bringup_rx_vseq.sv):
   - Scope: Coordinates the sideband initialization from the RX perspective.
   - Execution Flow: Monitors the RX state machine, handles wake handshakes, and validates sideband message receptions.

4. TX Sideband Bringup Virtual Sequence (ucie_sbinit_bringup_tx_vseq.sv):
   - Scope: Coordinates sideband initialization from the TX perspective.
   - Execution Flow: Drives initialization commands from the TX sideband controller.

5. Mainband Initialization Bringup Virtual Sequence (ucie_mbinit_bringup_vseq.sv):
   - Scope: Coordinates the happy-path mainband initialization.
   - Execution Flow:
     - Starts sideband initialization.
     - Employs handshakes to step through PARAM config and CAL calibration.
     - Triggers REPAIRCLK stage, executing rmblink_clk_seq (TEST_CLK_IDEAL_ALL) to verify positive/negative clocks.
     - Triggers REPAIRVAL stage, executing rmblink_valid_seq (TEST_IDEAL_ALL_0F) to verify physical valid pins.
     - Triggers REVERSAL stage, executing rmblink_PerLaneID_seq to check physical lane reordering.
     - Triggers REPAIRMB stage, invoking the TX D2C virtual sequence to run Data-to-Clock eye sweeps, degrade lanes if needed, and confirm end response.

6. Mainband Calibration Failure Virtual Sequence (ucie_mbinit_fail_vseq.sv):
   - Scope: Verifies FSM timeout and calibration failures.
   - Execution Flow: Drives invalid configurations during PARAM config or CAL done handshakes and checks if the DUT transitions to TRAINERROR.

7. Mainband Vref Valid Calibration Virtual Sequence (ucie_mbtrain_valverf_vseq.sv):
   - Scope: Drives valid lane Vref sweeps.
   - Execution Flow: Triggers Vref sweeps on valid pins and checks detection success.

8. Mainband Vref Data Calibration Virtual Sequence (ucie_mbtrain_dataverf_vseq.sv):
   - Scope: Drives data lane Vref sweeps.
   - Execution Flow: Triggers Vref sweeps on data pins.

9. Speed Change Virtual Sequence (ucie_mbtrain_speedidle_vseq.sv):
   - Scope: Coordinates clock frequency transitions.
   - Execution Flow: Commands clock divider registers to switch mainband rates.

10. TX Self-Calibration Virtual Sequence (ucie_mbtrain_txselfcal_vseq.sv):
    - Scope: Initiates internal TX calibration.
    - Execution Flow: Commands the FSM to enter txselfcal and checks completion.

11. RX Clock Calibration Virtual Sequence (ucie_mbtrain_rxclkcal_vseq.sv):
    - Scope: Performs clock shifting operations.
    - Execution Flow: Shifts the recovered RX clock phase.

12. Valid Centering Virtual Sequence (ucie_mbtrain_valtraincenter_vseq.sv):
    - Scope: Centering valid eye.
    - Execution Flow: Drives training sequences to position the sample clock inside the valid pattern.

13. Valid Verification Virtual Sequence (ucie_mbtrain_valtrainverf_vseq.sv):
    - Scope: Validates valid pin setup.
    - Execution Flow: Asserts training checks on the valid lane.

14. Data Centering DTC1 Virtual Sequence (ucie_mbtrain_DTC1_vseq.sv):
    - Scope: Data train centering 1.
    - Execution Flow: Runs eye sweeps to find the center of the data lanes.

15. Data Vref Training Virtual Sequence (ucie_mbtrain_datatrainvref_vseq.sv):
    - Scope: Calibrates Vref levels on data lines.
    - Execution Flow: Sweeps Vref settings while checking LFSR descrambler error rates.

16. RX Deskew Virtual Sequence (ucie_mbtrain_rxdskew_vseq.sv):
    - Scope: Resolves data-to-clock skews.
    - Execution Flow: Adjusts per-lane delays to align data edges.

17. Data Centering DTC2 Virtual Sequence (ucie_mbtrain_DTC2_vseq.sv):
    - Scope: Data train centering 2.
    - Execution Flow: Fine-tunes the sample phase on the data lanes.

18. Link Speed Virtual Sequence (ucie_mbtrain_linkspeed_vseq.sv):
    - Scope: Asserts link speed and width checks.
    - Execution Flow: Negotiates width degradation (x16 to x8/x4) or frequency adjustments.

19. Training Error Virtual Sequence (ucie_trainerror_vseq.sv):
    - Scope: Checks training error recovery.
    - Execution Flow: Walks the FSM into TRAINERROR and triggers a reset.

20. RX Data-to-Clock Eye Sweep Virtual Sequence (ucie_RX_D2C_vseq.sv):
    - Scope: Coordinates RX-initiated DTC checks.
    - Execution Flow: Executes sweeps from the RX side to calibrate clock alignment.

21. TX Data-to-Clock Eye Sweep Virtual Sequence (ucie_TX_D2c_vseq.sv):
    - Scope: Coordinates TX-initiated DTC checks.
    - Execution Flow: Drives serial training streams from the TX sideband.

22. Train till DTC1 Virtual Sequence (ucie_mbtrain_till_DTC1_vseq.sv):
    - Scope: Intermediate test sequence.
    - Execution Flow: Walks bringup up to DTC1 and stops.

23. Train till DTC2 Virtual Sequence (ucie_mbtrain_till_DTC2_vseq.sv):
    - Scope: Intermediate test sequence.
    - Execution Flow: Walks bringup up to DTC2.

24. Train till Data Train Vref Virtual Sequence (ucie_mbtrain_till_datatrainvref_vseq.sv):
    - Scope: Intermediate test sequence.
    - Execution Flow: Walks bringup up to data train Vref.

25. Train till Valid Train Center Virtual Sequence (ucie_mbtrain_till_valtraincenter_vseq.sv):
    - Scope: Intermediate test sequence.
    - Execution Flow: Walks bringup up to valid train center.

26. Train till Valid Train Vref Virtual Sequence (ucie_mbtrain_till_valtrainvref_vseq.sv):
    - Scope: Intermediate test sequence.
    - Execution Flow: Walks bringup up to valid train Vref.

27. Master Training Virtual Sequence (ucie_mbtrain_vseq.sv):
    - Scope: Links and runs all training sequences sequentially.
    - Execution Flow: Runs bringing up through all training substates up to LINKSPEED.

28. Train till RX Clock Calibration (ucie_vvref_till_rxcal_vseq.sv):
    - Scope: Targeted sequence walking FSM up to rxclkcal.
    - Execution Flow: Runs init up to rxclkcal to check phase shifts.

29. Sideband Physical Link Sequence (active_phylink_sequence.sv):
    - Scope: Physical sideband stimulus driver.
    - Execution Flow: Receives packets from link_fifo and drives them onto the sideband wires.

=============================================================================
6. Exclusive Test Verification Scenarios
=============================================================================

This section lists and describes every test case in the UCIE_top_env tests directory:

1. Base Test (ucie_base_test.sv):
   - Scope: Master class for all system-level tests.
   - Execution Flow: Instantiates the configuration block (ucie_env_cfg), sets virtual interface mappings, registers them in the config DB, creates the ucie_env environment, and handles pre_reset phase jumps on reset.

2. Sanity Test (ucie_sanity_test.sv):
   - Scope: Walks through the full happy-path training and active flit transfers.
   - Execution Flow:
     - Sets virtual sequence override to ucie_mbinit_bringup_vseq.
     - Runs the complete initialization.
     - Enters ACTIVE and launches active_tx_seq (RDI flits) and active_rx_seq (physical lanes) concurrently to verify loopback data.

3. Sideband Initialization Test (ucie_sbinit_test.sv):
   - Scope: Focuses on sideband bringup checks.
   - Execution Flow: Overrides base virtual sequence with ucie_sbinit_vseq to verify that Sideband reach sb_ready status.

4. Mainband Initialization Fail Test (ucie_mbinit_fail_test.sv):
   - Scope: Verifies state machine behavior on link check failures.
   - Execution Flow: Overrides virtual sequence with ucie_mbinit_fail_vseq. Drives invalid config responses and checks that the LTSM enters the error recovery state.

5. Mainband Training from Valid Center to DTC2 (ucie_mbtrain_from_valtraincenter_to_DTC2_test.sv):
   - Scope: Targeted test verification for valid eye centering.
   - Execution Flow: Overrides virtual sequence with ucie_mbtrain_from_valtraincenter_to_DTC2_vseq. Runs bringup from valid centering up to DTC2.

6. Link Speed Negotiation Test (ucie_mbtrain_linkspeed_test.sv):
   - Scope: Verifies speed and lane map degradation configurations.
   - Execution Flow: Overrides virtual sequence with ucie_mbtrain_linkspeed_cases_vseq to test LinkSpeed transitions.

7. Train till RX Calibration Test (ucie_vvref_till_rxcal_vseq_test.sv):
   - Scope: Targeted verification up to RX clock calibration.
   - Execution Flow: Overrides sequence with ucie_vvref_till_rxcal_vseq to verify eye parameters up to clock shift.
