# Rigorous Thesis Specification: Universal Chiplet Interconnect Express (UCIe) RX-Path UVM Verification Environment

This document provides a highly detailed, academic-grade verification specification of the Universal Chiplet Interconnect Express (UCIe) RX-Path testbench environment. It describes the testbench top-level integration, Bus Functional Models (BFMs), SystemVerilog Assertions (SVA) check suites, UVM agent components, scoreboard predictors/comparators, functional coverage models, and virtual test sequences.

All architectures, task flows, logic structures, and verification scenarios are formatted to facilitate direct LaTeX layout conversion for a graduation thesis.

---

## 1. Verification Architecture Overview

The verification environment is designed to validate the functional correctness of the UCIe RX-Path controller. The primary goal is to ensure the controller correctly handles physical-layer link training, lane deskewing, seed recovery, and descrambling across variable width configurations (x16, degraded x8, degraded x4) and rate modes (Half-Rate, Quad-Rate) before routing data to the Raw Die Interface (RDI).

The verification infrastructure is built as a modular, UVM-compliant SystemVerilog environment consisting of:
*   **Active and Passive Agents**: Encapsulating drivers, monitors, and sequencers for the RDI, LTSM Control, and physical Mainband Link (RMBLINK).
*   **Dual-Clock Bus Functional Models (BFMs)**: Driving and capturing high-speed signals at the interface boundaries.
*   **SystemVerilog Assertion (SVA) Interface**: Checking signal-level timing, sequence constraints, and protocol compliance.
*   **Scoreboard Predictor Subsystem**: Modeling Per-Lane ID matching, LFSR state tracking, and Lane-to-Byte routing logic.
*   **Functional Coverage Collectors**: Tracking state coverage, cross-coverage, and transition coverage.

```
                  ┌──────────────────────────────────────────────────────────┐
                  │                 UVM Virtual Sequencer                    │
                  └──────┬────────────┬─────────────┬────────────────────────┘
                         │            │             │
                         ▼            ▼             ▼
                  ┌────────────┐┌────────────┐┌────────────┐
                  │  RDI Agt   ││ LTSMC Agt  ││RMBLINK Agt │
                  └─────┬──────┘└─────┬──────┘└─────┬──────┘
                        │             │             │
  ┌──────────────┐      │ (Passive)   │ (Active)    │ (Active)
  │  Scoreboard  │      │             │             │
  │ ┌──────────┐ │◄─────┼─────────────┼─────────────┼────────┐
  │ │ Predictor│ │      │             │             │        │
  │ └────┬─────┘ │      │             │             │        │
  │      ▼       │      │             │             │        │
  │ ┌──────────┐ │◄─────┘             ▼             ▼        │
  │ │Comparator│ │             ┌────────────┐┌────────────┐  │ (Monitored Data)
  │ └──────────┘ │             │ LTSMC BFM  ││RMBLINK BFM │  │
  └──────────────┘             └─────┬──────┘└─────┬──────┘  │
                                     │             │         │
                                     ▼             ▼         │
                               ┌────────────────────────┐    │
                               │   UCIe RX-Path DUT     ├────┘
                               └────────────────────────┘
```

---

## 2. Testbench Top-Level Integration (`top.sv`)

The top-level module `top` acts as the physical wrapper for the testbench. It instantiates the DUT, defines the clocking and reset generators, binds the SystemVerilog Assertions, and registers BFM interfaces inside the UVM configuration database (`uvm_config_db`).

### 2.1 Clocking and Reset Generation
The testbench generates a set of synchronous and phase-shifted clocks to simulate multi-die link environments:
*   **Fabric System Clock (`clk`)**: Base fabric clock, typically running at $100 \text{ MHz}$.
*   **LTSM Controller Clock (`i_clk_l`)**: Dedicated clock for the Link Training and Status State Machine.
*   **SerDes Reference Clock (`i_dclk`)**: High-speed double data rate (DDR) line clock ($f_{\text{line}} \approx 800 \text{ MHz}$).
*   ** forwarded physical clocks (`i_clk_p`, `i_clk_n`)**: forward-synchronous clocks representing positive and negative phase tracks driven by the partner transmitter.
*   **Tracking Clock (`i_track`)**: Forwarded phase tracking reference signal.

The clock generator uses precise time delays (e.g. `T_CLK_L = 64ns`, `T_CLK_H = 2ns`, `T_CLK_D = 1ns`) to establish clock phases:
$$\text{Period}(i\_dclk) = 2 \times T\_CLK\_D = 2 \text{ ns} \quad (500 \text{ MHz})$$
$$\text{Period}(i\_hclk) = 2 \times T\_CLK\_H = 4 \text{ ns} \quad (250 \text{ MHz})$$

### 2.2 UVM Configuration DB Registration
BFM interface handles are registered under the global context so they can be retrieved by UVM drivers and monitors:
```systemverilog
initial begin
  uvm_config_db#(virtual rp_reset_intf)::set(null, "uvm_test_top.env", "reset_intf",  reset_intf);
  uvm_config_db#(virtual rp_rdi_bfm)::set(null,    "uvm_test_top.env", "rdi_bfm",     rdi_bfm);
  uvm_config_db#(virtual rp_ltsmc_bfm)::set(null,  "uvm_test_top.env", "ltsmc_bfm",   ltsmc_bfm);
  uvm_config_db#(virtual rp_rmblink_bfm)::set(null,"uvm_test_top.env", "rmblink_bfm", rmblink_bfm);
  uvm_config_db#(virtual rp_rmblink_bfm)::set(null,"uvm_test_top.env", "rmblink_bfm_drive", rmblink_bfm_drive);
end
```

---

## 3. Bus Functional Models (BFMs)

BFMs abstract the physical wire signaling into transaction-level tasks, decoupling UVM drivers and monitors from pin-level clocking details.

### 3.1 RMBLINK BFM (`rp_rmblink_bfm`)
The `rp_rmblink_bfm` simulates the physical Mainband Link (RMBLINK), interfacing the testbench with the receiver's serial lanes. It implements the serialization, deserialization, and clock/valid pattern injection logic.

#### 3.1.1 `serialize_data`
Converts parallel lane payloads and valid indicators into a serial bitstream synchronized to the double-data-rate clock `i_dclk`.

* **Function Prototype**:
  ```systemverilog
  task serialize_data(
      input logic [pDATA_WIDTH-1:0] _data[pNUM_LANES],
      input logic [7:0] _val_stream[],
      input logic _clk_stream_p[],
      input logic _clk_stream_n[],
      input logic _track_stream[],
      input int _idle_ui_cnt
  );
  ```
* **Timing Operations**:
  Data and valid lines are updated on the positive edge of `i_dclk`, while clocks and track lines are updated on the negative edge to ensure maximum setup and hold margin for the receiver:
  
  $$\text{At posedge } i\_dclk: \quad i\_data[L] \leftarrow \text{\_data}[L][b], \quad i\_valid \leftarrow \text{\_val\_stream}\left[\lfloor b/8 \rfloor\right]\left[b \pmod 8\right]$$
  $$\text{At negedge } i\_dclk: \quad i\_clk\_p \leftarrow \text{\_clk\_stream\_p}[b], \quad i\_clk\_n \leftarrow \text{\_clk\_stream\_n}[b], \quad i\_track \leftarrow \text{\_track\_stream}[b]$$
  $$\text{where } L \in [0, \text{pNUM\_LANES}-1], \quad b \in [0, \text{pDATA\_WIDTH}-1]$$

#### 3.1.2 `deserialize_data`
Extracts serial data stream transitions from the receiver physical pins.
* **Function Prototype**:
  ```systemverilog
  task deserialize_data(
      output logic [pDATA_WIDTH-1:0] _data[pNUM_LANES],
      output logic [7:0] _val_stream[]
  );
  ```
* **Sampling Rule**:
  The task blocks until `i_valid` asserts. It then iterates through 64 bits, capturing lane states on alternating positive edges of `i_clk_p` and `i_clk_n` (DDR sampling):
  $$\text{If } b \text{ is even: Sample } i\_data \text{ at posedge } i\_clk\_n$$
  $$\text{If } b \text{ is odd: Sample } i\_data \text{ at posedge } i\_clk\_p$$

#### 3.1.3 `serialize_valid_pattern` & `serialize_clk_pattern`
Drive baseline patterns during early training stages. `serialize_valid_pattern` streams the `11110000` Valid alignment framing over 1024 Unit Intervals (UIs). `serialize_clk_pattern` streams toggling clock streams over 4096 UIs interspersed with idle blocks.

---

## 4. SystemVerilog Assertions (SVA) Checker Interface (`rp_sva`)

The `rp_sva` interface monitors interfaces and uses concurrent assertions to verify protocol rules.

```
Physical Pins ─────►  Helper Edge Generator (valid_sample_pulse)
                             │
                             ▼
                      is_valid_pattern Check (LTSM State Gated)
                             │
                             ▼
                    Concurrent SVA Properties
             ┌───────────────────────┴───────────────────────┐
             ▼                                               ▼
    assert_valid_pattern_16_frame                   assert_clk_p_pattern_frame
    (Checks 16x 11110000 sequences)                 (Checks 16x clk patterns)
```

### 4.1 Helper Signal Generation
Because training patterns are asynchronous and high-speed, the checker generates local strobe indicators:
*   **Valid Sample Pulse (`valid_sample_pulse`)**: Generates a 1-picosecond edge detection pulse on every transition of the physical forwarded clocks (`i_clk_p` and `i_clk_n`):
    ```systemverilog
    always @(posedge i_clk_p or posedge i_clk_n) begin
        valid_sample_pulse = 1'b1;
        #1ps;
        valid_sample_pulse = 1'b0;
    end
    ```
*   **Watchdog Activity Monitor (`pattern_burst_active`)**: Detects when clock toggles have ceased during active tracking. If `i_clk_p` fails to transition within one fabric clock cycle, `pattern_burst_active` is pulled low.

### 4.2 Sequence and Property Definitions
The assertions verify alignment and calibration sequences:

#### 4.2.1 8-bit Valid Pattern Sequence (`seq_8bit_pattern`)
Defines the `11110000` pattern sequence (4 cycles of active valid followed by 4 cycles of inactive valid):
```systemverilog
sequence seq_8bit_pattern;
    i_valid[*4] ##1 (!i_valid)[*4];
endsequence
```

#### 4.2.2 16 Consecutive Sequences (`seq_16_consecutive`)
Valid training requires 16 consecutive repetitions of the 8-bit sequence:
```systemverilog
sequence seq_16_consecutive;
    seq_8bit_pattern[*16];
endsequence
```

#### 4.2.3 32-bit Clock Pattern Sequence (`clk_p_seq_32bit_pattern`)
Verifies clock alignment by ensuring 16 cycles of alternating clock activity followed by 16 cycles of quiet low states:
```systemverilog
sequence clk_p_seq_32bit_pattern;
    (i_clk_p ##1 (!i_clk_p))[*16] ##1 (!i_clk_p)[*16];
endsequence
```

### 4.3 Concurrent Protocol Assertions

#### 4.3.1 Valid Pattern Detection (`valid_detect_16_in_128_window`)
Verifies that during the `MBINIT_REPAIRVAL` phase, the receiver detects a valid alignment framing stream. The property samples on `valid_sample_pulse` and searches for 16 consecutive sequences within a 128-cycle window:
```systemverilog
property valid_detect_16_in_128_window;
    @(posedge i_dclk) disable iff(valid_pattern_detected || (i_rx_encoding != MBINIT_REPAIRVAL_RX_Valid_Pattern_Det))
     ($rose(i_valid)) |=> 
    @(posedge valid_sample_pulse) 
        first_match(first_seq_16_consecutive or ##[0:$] seq_16_consecutive);
endproperty

assert_valid_pattern_16_frame: assert property (valid_detect_16_in_128_window) else begin
    `uvm_info("SVA_VAL", "FAIL: Valid pattern sequence missed!", UVM_HIGH)
end
```

#### 4.3.2 Forwarded Clock Pattern Detection (`clk_p_detect_16_in_128_window`)
Ensures positive forwarded clock patterns match the standard structure during the clock training state:
```systemverilog
property clk_p_detect_16_in_128_window;
    @(negedge i_dclk) disable iff(pattern_detected_clk_p || (i_rx_encoding != MBINIT_REPAIRCLK_RX_Pattern_Detection))
     ($rose(i_clk_p)) |-> 
    first_match(##[0:$] clk_p_seq_16_consecutive);
endproperty
```

---

## 5. Scoreboard and Prediction Subsystem (`rp_scoreboard`, `rp_pred`)

The scoreboard checks the data path by running a transaction-level behavioral model of the RX-Path in parallel with the RTL, comparing the outputs clock-by-clock.

### 5.1 Predictor Architecture (`rp_pred`)
The predictor component (`rp_pred`) monitors input streams (`rmblink_seq_item` and `ltsmc_seq_item`) and calculates expected transactions for the downstream comparators.

```
       Input Transactions 
     (rmblink, ltsmc streams)
               │
               ▼
      [ rp_pred Predictor ]
     ┌────────────────────────┐
     │ 1. Per-Lane ID Match   ├────► Expected LTSMC Output
     │ 2. LFSR Galois Model   ├────► Expected Descrambled Stream
     │ 3. Lane-to-Byte Routing├────► Expected RDI Output
     └────────────────────────┘
```

#### 5.1.1 Per-Lane ID Pattern Matching
During the `MBINIT_REVERSAL` state, the receiver identifies logical lane mappings by checking for unique patterns on each lane. The model simulates this detection:
* **Target Pattern**: Each lane expects a repeating 16-bit word consisting of a header (`4'b1010`), the lane index (8 bits), and a footer (`4'b1010`):
  $$\text{Expected Lane ID}[L] = \{ 4'\text{b1010}, 8'\text{h}(L), 4'\text{b1010} \}$$
* **Lock Criteria**: The predictor processes 16-bit blocks. If a lane matches its target value 16 consecutive times, the corresponding bit in the success vector is set to `1`:
  $$\text{success\_arr}[L] = \begin{cases} 1'b1 & \text{if count}[L] \ge 16 \\ 1'b0 & \text{otherwise} \end{cases}$$

#### 5.1.2 LFSR Pattern Generator & Descrambling Model
The predictor implements a 23-tap Linear Feedback Shift Register (LFSR) model. The LFSR operates in three modes: seed load, training check, and active descrambling.

* **Lanes Seeds ($LANE\_ID$)**: Lanes are initialized with distinct 23-bit seeds:
  
  $$\text{Seeds for } L \in [0, 7]: \quad \text{LANE\_ID}[L] = \begin{cases} 
    23'\text{h1DBFBC} & \text{if } L=0 \\
    23'\text{h0607BB} & \text{if } L=1 \\
    23'\text{h1EC760} & \text{if } L=2 \\
    23'\text{h18C0DB} & \text{if } L=3 \\
    23'\text{h010F12} & \text{if } L=4 \\
    23'\text{h19CFC9} & \text{if } L=5 \\
    23'\text{h0277CE} & \text{if } L=6 \\
    23'\text{h1BB807} & \text{if } L=7 
  \end{cases}$$
  
  For lanes 8 to 15, the seeds repeat:
  $$\text{LANE\_ID}[L] = \text{LANE\_ID}[L \pmod 8]$$

* **LFSR Galois State Transitions (`update_lfsr_state`)**:
  On each bit cycle, if load is inactive, the register shifts right and feeds back transitions at taps 23, 22, 17, 9, 6, 3 (1-indexed, corresponding to indices 2, 5, 8, 16, 21 in 0-indexed logic):
  
  $$\text{For index } j \in [0, 22]:$$
  $$lfsr\_state[i][j] \leftarrow \begin{cases}
    lfsr\_last\_state[i][j-1] \oplus lfsr\_last\_state[i][22] & \text{if } j \in \{2, 5, 8, 16, 21\} \\
    lfsr\_last\_state[i][22] & \text{if } j = 0 \\
    lfsr\_last\_state[i][j-1] & \text{otherwise}
  \end{cases}$$

* **Active Descrambling (`descramble_data`)**:
  During data phase, payload bits are recovered by XORing the received stream with the MSB of the LFSR tracking state:
  $$\text{Descrambled}[i][b] = \text{Scrambled}[i][b] \oplus lfsr\_state[i][22]$$

#### 5.1.3 Lane-to-Byte (L2B) Routing Logic
The Lane-to-Byte module maps the descrambled lane data arrays (`lfsr_out_data`) to the byte-aligned RDI output interface based on `lane_map_code`.

* **Mapping Configurations**:
  Let $M$ represent the lane mapping step, and $S$ represent the starting lane offset:
  
  $$\begin{array}{l|c|c}
    \text{lane\_map\_code} & \text{Start Offset } (S) & \text{Step Size } (M) \\ \hline
    3'\text{b001 (x8 Lower)} & 0 & 8 \\
    3'\text{b010 (x8 Upper)} & 8 & 8 \\
    3'\text{b011 (x16 Full)} & 0 & 16 \\
    3'\text{b100 (x4 Lower)} & 0 & 4 \\
    3'\text{b101 (x4 Upper)} & 4 & 4 
  \end{array}$$

* **Reassembly Equations (`lane2byte`)**:
  Data is gathered over multiple iterations ($l2b\_iter\_cnt$). For each lane index $n \in [0, M-1]$ and byte offset $k \in [0, 7]$ within the 64-bit word:
  
  $$\text{lane\_idx} = S + n$$
  $$\text{data\_byte\_idx} = M \times (8 \times l2b\_iter\_cnt + k) + n$$
  $$\text{rdi\_data\_buffer}[\text{data\_byte\_idx}] \leftarrow \text{lanes}[\text{lane\_idx}][k]$$

Once $l2b\_iter\_cnt$ reaches its maximum, the fully assembled 256-byte transaction is written to the analysis port.

### 5.2 Scoreboard Comparators (`rp_cmp_base`)
The comparators (`rp_cmp_rdi`, `rp_cmp_ltsmc`) extend the base class `rp_cmp_base` to align and verify incoming packets.
* **FIFO Isolation**: Inbound predicted and actual transactions are queued in separate TLM analysis FIFOs (`expfifo`, `outfifo`) to decouple checking from interface sampling.
* **UVM Comparer Integration**:
  The comparison task retrieves items and runs UVM's deep comparison policy, reporting all field differences instead of stopping at the first mismatch:
  ```systemverilog
  comparer = new();
  comparer.show_max = 100; // Output up to 100 field mismatches
  if (!out_tr.compare(exp_tr, comparer)) begin
      `uvm_error(cmp_name, "Transaction Mismatch Detected!")
  end
  ```
* **Phase Flushing**: During `pre_reset_phase`, all pending queue items are flushed to prevent stale transactions from failing subsequent test runs.

---

## 6. UVM Agent Components

Agents encapsulate sequencers, drivers, and monitors to isolate test sequences from interface protocols.

### 6.1 UVM Sequence Items
Transactions are modeled using three specialized UVM sequence items:
1.  **`ltsmc_seq_item`**:
    *   `lane_map_code` (Enum): Selects active width configurations.
    *   `rx_encoding` (Enum): Sets the target RX state.
    *   `error_threshold` (16-bit): Configures the allowed error margin.
    *   `rx_data_results` (64-bit): Success flags for each physical lane.
2.  **`rmblink_seq_item`**:
    *   `val_stream[]` (Array): Valid pattern stream.
    *   `clk_stream_p[]` / `clk_stream_n[]` (Arrays): Dual-phase clock patterns.
    *   `track_stream[]` (Array): Phase tracking reference.
    *   `data[16]` (64-bit Array): Egress lane payloads.
    *   `rp_opmode` (Enum): Operation mode selector (`CLK_PATTERN`, `VAL_PATTERN`, `DATA_PATTERN`, `ACTIVE`).

### 6.2 Drivers and Monitors
*   **Driver Execution (`rmblink_driver`)**:
    The driver reads `rp_opmode` from the sequence item and routes it to the BFM:
    *   If `CLK_PATTERN`: Calls `bfm.serialize_clk_pattern`.
    *   If `VAL_PATTERN`: Calls `bfm.serialize_valid_pattern`.
    *   If `ACTIVE`: Blocks until the receiver enters the active state (`bfm.i_rx_encoding === ACTIVE`), then serializes payload data.
*   **Monitor Execution & Abort Handling (`rmblink_monitor`)**:
    The monitor captures serial link transitions. It waits for active states, then forks the BFM deserialization task. If the receiver state changes before deserialization completes, the fork is terminated to discard the partial packet:
    ```systemverilog
    fork
      begin
        bfm.deserialize_data(item_in.data, item_in.val_stream);
        success = 1;
      end
      begin
        @(bfm.i_rx_encoding); // Abort trigger on state change
      end
    join_any
    disable fork;
    ```

---

## 7. Functional Coverage Models

The `rp_coverage_collector` component uses covergroups to track verification progress.

### 7.1 LTSM State Coverage (`cg_ltsm`)
Tracks state coverage, transitions, and combinations during verification.

#### 7.1.1 State Coverpoint (`cp_encoding`)
Verifies that all states in the initialization, training, active, and eye-sweep phases are visited:
```systemverilog
cp_encoding: coverpoint curr_encoding {
  bins reset = {RESET_Reset};
  bins active = {ACTIVE_RX_Active};
  bins d2c_tx[] = {Data_To_Clock_test_RX_INIT_Handshake_TX_Init,
                   Data_To_Clock_test_RX_LFSR_Clear_Handshake_TX_Init,
                   Data_To_Clock_test_RX_Pattern_Detection_TX_Init,
                   Data_To_Clock_test_RX_Result_Handshake_TX_Init,
                   Data_To_Clock_test_RX_End_Init_Handshake_TX_Init};
  // (Remaining states mapped to corresponding bins)
}
```

#### 7.1.2 Transition Coverpoint (`cp_transitions`)
Verifies the complete handshaking sequence by tracking state transitions:
```systemverilog
cp_transitions: coverpoint curr_state {
  bins reset_to_sbinit = (ST_RESET => ST_SBINIT);
  bins sbinit_to_param = (ST_SBINIT => ST_PARAM);
  bins param_to_cal    = (ST_PARAM => ST_CAL);
  bins linkspeed_to_active = (ST_LINKSPEED => ST_LINKINIT ##1 ST_ACTIVE);
  bins error_recovery  = (ST_TRAINERROR => ST_RESET);
}
```

#### 7.1.3 Cross Coverage (`cx_state_x_lane_map`)
Ensures that all width configurations are tested during degraded operating modes:
```systemverilog
cp_lane_map: coverpoint curr_lane_map {
  bins widths[] = {X8_LOWER_MODE, X8_UPPER_MODE, X16_MODE, X4_LOWER_MODE, X4_UPPER_MODE};
}
cp_state_degrade: coverpoint curr_state {
  bins states = {ST_REPAIRMB, ST_REPAIR};
}
cx_state_x_lane_map: cross cp_state_degrade, cp_lane_map;
```

---

## 8. Test Sequences and Scenario Execution (`rp_sanity_all_vseq`)

The virtual sequence `rp_sanity_all_vseq` controls the verification flow by orchestrating sequences across the RDI, LTSMC, and RMBLINK interfaces.

### 8.1 Scenario Execution Flow
The sequence uses the helper task `execute_scenario` to run test cases under different lane configurations:
```systemverilog
task execute_scenario(
    lane_map_code_t map_code,
    per_lane_scenario_e scen_rev,
    per_lane_scenario_e scen_repmb,
    mixed_lane_mode_e mixed_rev,
    mixed_lane_mode_e mixed_repmb,
    lfsr_scenario_e scen_dvref,
    lfsr_scenario_e scen_dtc1,
    lfsr_scenario_e scen_dtvref,
    lfsr_scenario_e scen_dtc2,
    lfsr_scenario_e scen_linkspeed,
    int iters_perlane,
    int iters_lfsr,
    int iters_active,
    string scen_name,
    clk_test_mode_e clk_test_mode,
    valid_test_mode_e valid_test_mode_init,
    valid_test_mode_e valid_test_mode_vref,
    valid_test_mode_e valid_test_mode_vtc,
    valid_test_mode_e valid_test_mode_vtref
);
```

### 8.2 Execution Sequence
For each scenario, the task executes the following steps:
1.  **Reset**: Drives the LTSM into the `RESET_Reset` state.
2.  **Clock Training (`REPAIRCLK`)**: Drives the LTSM to `MBINIT_REPAIRCLK_RX_Pattern_Detection` and starts `rmblink_clk_seq` using `clk_test_mode`.
3.  **Valid Training (`REPAIRVAL`)**: Drives the LTSM to `MBINIT_REPAIRVAL_RX_Valid_Pattern_Det` and starts `rmblink_valid_seq` using `valid_test_mode_init`.
4.  **Reversal Lane ID Training (`REVERSAL`)**: Drives the LTSM to `MBINIT_REVERSAL_RX_Per_Lane_ID_Det` and starts `rmblink_PerLaneID_seq` using `scen_rev` and `mixed_rev`.
5.  **Payload and Eye Sweep Training**:
    Iterates through the remaining training states (`VALVREF`, `DATAVREF`, `DTC1`, `VALTRAINCENTER`, `VALTRAINVREF`, `DTC2`, `LINKSPEED`), checking LFSR seeds and calibration thresholds against the configurations defined in Section 8.3.

### 8.3 Test Scenario Library
The verification suite runs seven groups of test scenarios:

*   **Group 1: Ideal & Baseline Scenarios**:
    Tests error-free training sequences to verify correct state transitions and data descrambling under nominal conditions.
*   **Group 2: Per-Lane Anomalies**:
    Simulates physical link failures (e.g. `SCENARIO_FAIL_MIDWAY`, `SCENARIO_WRONG_LANE_ID`, `SCENARIO_THRESHOLD_TEASER`) on a subset of lanes to verify that the receiver flags errors correctly.
*   **Group 3: LFSR Scenarios**:
    Injects random bit flips into the scrambled stream to verify the noise margins defined by `error_threshold`.
*   **Group 4: Valid Test Mode Mappings**:
    Injects framing errors (e.g. `TEST_SINGLE_ERROR`, `TEST_MULTI_ERR_ABOVE_THRESH`) during valid pattern training to verify threshold detection and recovery.
*   **Group 5: Clock Test Mode Variations**:
    Tests clock phase offsets and jitter (e.g. `TEST_CLK_INJECT_MIDDLE`, `TEST_CLK_PURE_RANDOM`) to verify the receiver pll locks under non-ideal conditions.
*   **Group 6: Mixed Interactions**:
    Combines clock jitter, lane offsets, and payload errors to verify the controller's robustness.
*   **Group 7: Pure Chaos**:
    Applies heavy randomization across all interfaces to stress-test the controller.
