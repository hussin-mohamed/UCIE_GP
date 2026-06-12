# UCIe 3.0 TX Logical PHY — Verification Environment Specification

---

## 1. Overview

This document describes the UVM-based verification environment for the **TX Logical PHY** of a UCIe 3.0 (Universal Chiplet Interconnect Express) die-to-die link. The TX path is responsible for accepting flit data from the D2D Adapter via the RDI (Raw Die-to-Die Interface), processing it through a datapath pipeline (byte-to-lane mapping, LFSR scrambling, lane reversal), and driving serialized output on 16 physical lanes toward the analog front-end.

The environment verifies the TX Controller logic by driving the full LTSM (Link Training State Machine) encoding sequence — spanning initialization, training, and active data transfer — while injecting flit traffic on the RDI and observing the serialized egress output. A **reactive stimulus** architecture coordinates the three interface agents through TLM analysis FIFOs, ensuring protocol-correct temporal ordering without hard-coded synchronization.

---

## 2. UVM Architecture

### DUT Overview

The figure below shows the top-level testbench module (`tx_tb_top`) and its connectivity to the DUT. Three SystemVerilog interfaces — `rdi_if`, `ltsm_if`, and `tx2link_if` — form the boundary between the verification environment and the TX Logical PHY. The SVA assertion module is bound directly to the DUT outputs.

![DUT Overview](dut_overview_crop.png)

### UVM Architecture

The figure below illustrates the UVM environment (`tx_env`) hierarchy, showing the three agents, TLM analysis connections, and the data flow through the predictor, scoreboard, and coverage collector.

![UVM Architecture](uvm_tx_architecture_2.png)

The environment follows a standard UVM layered architecture with the following key components:

| Component                         | Role                                                               |
| --------------------------------- | ------------------------------------------------------------------ |
| **RDI Agent** (Active)      | Drives flit data into the DUT; reacts to backpressure              |
| **LTSM Agent** (Active)     | Drives LTSM state encodings to control the DUT FSM                 |
| **TX2Link Agent** (Passive) | Monitors serialized egress output from the DUT                     |
| **Model**                   | Reference model — generates expected egress output                |
| **Scoreboard**              | Compares golden predictions against actual observations            |
| **Coverage**                | Collects functional coverage on states, transitions, and lane maps |
| **SVA**                     | SVA module — protocol assertions on DUT-driven signals            |

---

## 3. Packages

Two SystemVerilog packages centralize all definitions and file includes.

### 3.1 `tx_defs_pkg`

The definitions package provides all shared types, parameters, and helper functions used across the environment.

**Parameters:**

- `NUM_LANES = 16` — physical lane count.
- `DEFAULT_NBYTES = 256` — default flit size in bytes.

**Enumerations:**

- `flit_size_e` — supported flit sizes: 64, 128, 256, 512 bytes.
- `ltsm_state_group_e` — TB-level constraint groups: `HAPPY_PATH`, `PATTERN_GEN`, `TRAIN_ERROR`, `TRISTATE`, `ACTIVE`.
- `ltsm_encoding_e` — full 9-bit LTSM FSM encoding covering all states across four sub-FSMs (Initialization, Training, Active, Data-to-Clock Test).

**Lane Map Constants:**

- `LANE_MAP_DEGRADE_NOT_POSSIBLE` (3'b000), `LANE_MAP_LANES_0_TO_7` (3'b001), `LANE_MAP_LANES_8_TO_15` (3'b010), `LANE_MAP_ALL_FUNCTIONAL` (3'b011).

**Helper Functions:**

| Function                   | Description                                                                 |
| -------------------------- | --------------------------------------------------------------------------- |
| `get_fsm_id()`           | Extracts the 2-bit FSM_ID from a 9-bit encoding                             |
| `is_init_fsm()`          | Returns `1` if encoding is in FSM 00 (Initialization)                     |
| `is_train_fsm()`         | Returns `1` if encoding is in FSM 01 (Training)                           |
| `is_active_fsm()`        | Returns `1` if encoding is in FSM 10 (Active)                             |
| `is_d2c_fsm()`           | Returns `1` if encoding is in FSM 11 (D2C Test)                           |
| `is_tristate_state()`    | Returns `1` for states requiring Hi-Z outputs (RESET, SBINIT, PARAM, CAL) |
| `is_active_data()`       | Returns `1` only for the `ACTIVE` encoding                              |
| `is_pattern_gen_state()` | Returns `1` for pattern generation states                                 |
| `uses_lane_map()`        | Returns `1` for REPAIRMB/REPAIR states where lane_map is relevant         |

### 3.2 `tx_tb_pkg`

The testbench package imports UVM and `tx_defs_pkg`, then includes all verification component files in strict dependency order (sequence items → configuration → agents → sequences → reference model → environment → tests). This is the single import point for the entire TB.

---

## 4. Interfaces

Three SystemVerilog interfaces model the DUT boundaries. Each provides dedicated `modport` declarations for driver, monitor, and DUT roles.

### 4.1 RDI Interface (`rdi_if`)

The RDI interface carries flit payloads between the D2D Adapter and the TX Logical PHY using ready/valid handshaking.

| Signal       | Width                 | Direction (TB → DUT) | Description                                                    |
| ------------ | --------------------- | --------------------- | -------------------------------------------------------------- |
| `lp_data`  | `[NBYTES-1:0][7:0]` | Input                 | Flit payload as a 2D byte array                                |
| `lp_valid` | 1-bit                 | Input                 | Asserted when `lp_data` carries a valid flit                 |
| `lp_irdy`  | 1-bit                 | Input                 | Adapter intent-to-send                                         |
| `pl_trdy`  | 1-bit                 | Output                | PHY backpressure — when low, adapter must hold signals stable |

Parameterized by `NBYTES` (default 256). Clocked on the logical clock domain (`clk`).

### 4.2 LTSM Interface (`ltsm_if`)

The LTSM interface bypasses the internal state machine, acting as a direct control vector into the TX Controller.

| Signal            | Width | Direction (TB → DUT) | Description                         |
| ----------------- | ----- | --------------------- | ----------------------------------- |
| `tx_encoding`   | 9-bit | Input                 | Active LTSM state/substate encoding |
| `lane_map`      | 3-bit | Input                 | Width degradation configuration     |
| `pll_stable`    | 1-bit | Output                | PLL lock indicator                  |
| `supply_stable` | 1-bit | Output                | Power supply rails stable           |
| `tx_done`       | 1-bit | Output                | Current operation complete          |

Clocked on the logical clock domain (`clk`).

### 4.3 TX2Link Interface (`tx2link_if`)

The TX-to-Link interface is the final physical output boundary before the analog serial drivers.

| Signal                    | Width      | Direction | Description                          |
| ------------------------- | ---------- | --------- | ------------------------------------ |
| `tx_data`               | 16-bit     | Output    | 16 serial data lanes (1 bit/UI each) |
| `tx_clkp` / `tx_clkn` | 1-bit each | Output    | Forwarded differential clock pair    |
| `tx_valid`              | 1-bit      | Output    | Physical valid lane                  |
| `tx_track`              | 1-bit      | Output    | Training synchronization signal      |

Operates on the fast UI clock domain (`ui_clk`). Half-rate: 1 fast clock = 2 UI. During disabled/reset states, all signals are expected to be Hi-Z.

---

## 5. Agents

The environment contains **three agents** — two active and one passive — each targeting a distinct DUT interface.

### 5.1 RDI Agent (Active)

**Architecture:** Driver + Monitor + Sequencer.

- **Driver (`rdi_driver`):** Implements a **reactive backpressure** model. It drives `lp_data`, `lp_valid`, and `lp_irdy`, then monitors `pl_trdy` at each clock edge. While `pl_trdy` is de-asserted, the driver holds all outputs stable — no data is lost. Once `pl_trdy` re-asserts, the transfer completes and the next flit is requested from the sequencer.
- **Monitor (`rdi_monitor`):** Passively detects completed flit transfers by sampling when `lp_valid && lp_irdy && pl_trdy` are all high simultaneously. Extracts `active_flit_size` bytes from the interface and broadcasts a `rdi_seq_item` via its analysis port.
- **Sequencer:** Standard UVM sequencer parameterized on `rdi_seq_item`.

> **Note:** The RDI agent does **not** check `pl_trdy` correctness — this is a DUT output. The driver only reacts to it for protocol compliance.

### 5.2 LTSM Agent (Active)

**Architecture:** Driver + Monitor + Sequencer.

- **Driver (`ltsm_driver`):** Drives `tx_encoding` and `lane_map`, then applies **state-dependent wait rules**:
  - `RESET` → blocks until `pll_stable && supply_stable` (DUT signals).
  - Pattern generation / apply states → blocks until `tx_done` (DUT signal).
  - All other states → holds for a randomized delay period.
- **Monitor (`ltsm_monitor`):** Detects encoding transitions by comparing the current `tx_encoding` against the previous value each clock cycle. On change, it broadcasts a `ltsm_seq_item` containing the new encoding and lane_map. This monitor is the **central hub for cross-agent reactivity** — both the RDI sequence and the TX2Link monitor subscribe to its analysis port.
- **Sequencer:** Standard UVM sequencer parameterized on `ltsm_seq_item`.

> **Note:** The LTSM agent does **not** verify `pll_stable`, `supply_stable`, or `tx_done` — these are DUT outputs checked by the SVA module.

### 5.3 TX2Link Agent (Passive)

**Architecture:** Monitor only (no driver or sequencer).

- **Monitor (`tx2link_monitor`):** A state-aware assembler that operates on the fast `ui_clk` domain. It receives LTSM state updates via a **TLM analysis FIFO** connected to the LTSM monitor, and uses the current state to determine chunk sizes (number of UI cycles to sample). The monitor is "**blind**" — it samples all 16 data lanes for the chunk duration regardless of state, tagging each chunk with `captured_state` metadata. The scoreboard interprets which lanes carry valid data.

  - Active/Pattern states: 64 fast-clock samples per chunk.
  - Handshake-only states: no output expected (skip).

  Each write to the analysis port contains 64 UI samples × 16 lanes = 128 bytes of lane data, reducing write overhead compared to per-UI transactions.

### 5.4 Reactive Stimulus Flow

Cross-agent coordination uses **TLM analysis FIFOs** rather than hard-coded synchronization:

```
LTSM Monitor ──ap──┬──► ltsm_to_rdi_fifo ──► RDI Sequence (gates flit gen on ACTIVE)
                   ├──► tx2link_monitor.ltsm_state_fifo (determines chunk sizes)
                   ├──► tx_predictor (updates internal state)
                   └──► tx_coverage (samples LTSM covergroups)
```

The RDI sequence blocks on the FIFO until the LTSM enters `ACTIVE`, then generates flits. If the state leaves `ACTIVE`, flit generation halts and the sequence re-waits. This decouples stimulus timing from agent internals.

---

## 6. Environment

### 6.1 `tx_env_cfg`

Centralized configuration object distributed via `uvm_config_db`:

| Field               | Type                        | Description                              |
| ------------------- | --------------------------- | ---------------------------------------- |
| `rdi_vif`         | `virtual rdi_if`          | RDI interface handle                     |
| `ltsm_vif`        | `virtual ltsm_if`         | LTSM interface handle                    |
| `tx2link_vif`     | `virtual tx2link_if`      | TX2Link interface handle                 |
| `rdi_agent_mode`  | `uvm_active_passive_enum` | RDI agent mode (default:`UVM_ACTIVE`)  |
| `ltsm_agent_mode` | `uvm_active_passive_enum` | LTSM agent mode (default:`UVM_ACTIVE`) |

### 6.2 `tx_env`

The top-level environment instantiates all sub-components and wires TLM connections in the connect phase:

1. **LTSM Monitor → `ltsm_to_rdi_fifo`** — cross-agent reactivity for RDI sequence.
2. **LTSM Monitor → `tx2link_monitor.ltsm_state_fifo`** — state-aware chunk assembly.
3. **LTSM Monitor → Predictor** — state tracking for golden model.
4. **LTSM Monitor → Coverage** — LTSM covergroup sampling.
5. **RDI Monitor → Predictor** — flit data for datapath prediction.
6. **RDI Monitor → Coverage** — RDI covergroup sampling.
7. **Predictor → Scoreboard** (`golden_fifo`) — expected egress transactions.
8. **TX2Link Monitor → Scoreboard** (`actual_fifo`) — observed egress transactions.

Active agent sequencers are registered in the global **`sqr_pool`** (sequencer container pattern) for access by virtual sequences without requiring a virtual sequencer component.

---

## 7. Sequence Items

### 7.1 `rdi_seq_item`

Represents a single flit transaction on the RDI interface.

| Field                | Type                   | Description                                        |
| -------------------- | ---------------------- | -------------------------------------------------- |
| `data`             | `rand logic [7:0][]` | Dynamic byte array sized to `active_flit_size`   |
| `delay`            | `rand int unsigned`  | Inter-flit gap in clock cycles (0–20)             |
| `active_flit_size` | `static flit_size_e` | Per-run flit size (set via `+FLIT_SIZE` plusarg) |

### 7.2 `ltsm_seq_item`

Represents a single LTSM state command.

| Field            | Type                     | Description                                            |
| ---------------- | ------------------------ | ------------------------------------------------------ |
| `encoding`     | `rand ltsm_encoding_e` | Target 9-bit LTSM encoding                             |
| `lane_map`     | `rand logic [2:0]`     | Width degradation config (constrained to valid values) |
| `delay`        | `rand int unsigned`    | Inter-state delay in clocks (1–20)                    |
| `active_group` | `ltsm_state_group_e`   | Selects which constraint group is active               |

Includes five mutually-exclusive constraint groups and static ordered state queues per group. The `set_group()` method enables exactly one constraint at a time.

### 7.3 `tx2link_item`

Represents an assembled chunk of serial data from the egress monitor. **Never randomized** — constructed exclusively by the monitor.

| Field              | Type                | Description                              |
| ------------------ | ------------------- | ---------------------------------------- |
| `captured_state` | `ltsm_encoding_e` | LTSM state active during assembly        |
| `ui_count`       | `int unsigned`    | Number of UI cycles in this chunk        |
| `data_lanes`     | `logic [15:0][]`  | Sampled data per UI (16 lanes per entry) |

Implements `do_compare()` with 4-state (`===`) comparison to properly handle Hi-Z values.

---

## 8. Sequences

### 8.1 `ltsm_base_seq`

Drives LTSM state transitions in either **sequential walk** (ordered state list) or **random** (constrained random within group) mode. Control knobs:

- `group` — selects the state group (`GROUP_HAPPY_PATH` by default).
- `is_random` — `0` for ordered walk, `1` for random pick.
- `num_iterations` — overridden by `+ITER` plusarg.

### 8.2 `rdi_base_seq`

A **reactive sequence** that blocks on a TLM FIFO until the LTSM state becomes `ACTIVE`, then generates randomized flits. If the state leaves `ACTIVE`, generation halts and the sequence re-waits. The number of flits per active window is controlled by the `+ITER` plusarg.

### 8.3 `tx_virtual_seq`

Orchestrates both sub-sequences in parallel using `fork`/`join`. Retrieves sequencer handles from the global `sqr_pool` — no virtual sequencer component is needed.

### 8.4 `sqr_pool`

A singleton sequencer container (Cummings/Glasser DVCon pattern) mapping string names to sequencer handles via an associative array. Eliminates the need for virtual sequencer hierarchies.

---

## 9. Functional Coverage

The `tx_coverage` component subscribes to both LTSM and RDI monitor analysis ports.

### 9.1 LTSM Covergroup (`cg_ltsm`)

| Coverpoint / Cross         | Description                                                                             |
| -------------------------- | --------------------------------------------------------------------------------------- |
| `cp_encoding`            | All 9-bit LTSM encodings with bins grouped by phase (Init, Train, Active, D2C)          |
| `cp_lane_map`            | All four lane map configurations                                                        |
| `cx_encoding_x_lane_map` | Cross coverage of encoding × lane_map, with ignore bins for non-degradation states     |
| `cp_transitions`         | Key state transitions: any→TRAINERROR, TRAINERROR→RESET, LINKINIT→ACTIVE, ACTIVE→L1 |

### 9.2 RDI Covergroup (`cg_rdi`)

Currently a placeholder — to be populated with flit size, backpressure, and data pattern coverage bins.

---

## 10. Assertions (SVA)

The `tx_sva` module contains SystemVerilog Assertions that check **only DUT-driven output signals**. The active agents (RDI and LTSM) are intentionally kept free of output-checking logic for the signals driven by the DUT.

### 10.1 Checking Strategy

| Category                                                                         | What is Checked                                                             | Where |
| -------------------------------------------------------------------------------- | --------------------------------------------------------------------------- | ----- |
| **DUT outputs from LTSM** (`pll_stable`, `supply_stable`, `tx_done`) | Checked in (**SVA**)  — not in the LTSM agent                        |       |
| **DUT output from RDI** (`pl_trdy`)                                      | **Not checked** — the RDI driver only reacts to it                   |       |
| **Egress signals** (`tx_clkp/n`, `tx_valid`, `tx_track`)             | Checked in (**SVA**) — offloaded from the passive monitor            |       |
| **Egress data** (`tx_data[15:0]`)                                        | Checked in the (**SVA**) when IDLE or Hi-Z + (**Scoreboard**) |       |

### 10.2 Tri-State Assertions

During RESET, SBINIT, PARAM, and CAL states, all egress outputs must be Hi-Z:

- `assert_data_tristate` — `tx_data === 16'hzzzz`
- `assert_valid_tristate` — `tx_valid === 1'bz`
- `assert_track_tristate` — `tx_track === 1'bz`
- `assert_clk_tristate` — `tx_clkp === 1'bz && tx_clkn === 1'bz`

This offloads idle/tristate checking from the passive agent to hardware assertions.

### 10.3 LTSM Status Assertions

- `assert_pll_stable` — `pll_stable` must assert 1 cycle after entering `RESET`.
- `assert_supply_stable` — `supply_stable` must assert 1 cycle after entering `RESET`.
- `assert_tx_done_valid_state` — `tx_done` may only rise during operation states (pattern gen + apply).

### 10.4 Per-State `tx_done` Timing

| Assertion                         | State                           | Expected Latency        |
| --------------------------------- | ------------------------------- | ----------------------- |
| `assert_tx_done_repairclk`      | `REPAIRCLK_CLK_PATTERN_GEN`   | 128 × 24 = 3072 cycles |
| `assert_tx_done_repairval`      | `REPAIRVAL_VALID_PATTERN_GEN` | 128 × 8 = 1024 cycles  |
| `assert_tx_done_reversal_id`    | `REVERSAL_PER_LANE_ID_GEN`    | 128 × 16 = 2048 cycles |
| `assert_tx_done_d2c_tx`         | `D2C_TX_PATTERN_GEN`          | 128 × 8 = 1024 cycles  |
| `assert_tx_done_d2c_rx`         | `D2C_RX_PATTERN_GEN`          | 4000 cycles             |
| `assert_tx_done_reversal_apply` | `REVERSAL_APPLY`              | 1 cycle                 |
| `assert_tx_done_repairmb`       | `REPAIRMB_APPLY_DEGRADE_HND`  | 1 cycle                 |
| `assert_tx_done_repair`         | `REPAIR_APPLY_DEGRADE_HND`    | 1 cycle                 |

### 10.5 Cover Properties

- `cover_backpressure` — RDI backpressure event during `ACTIVE` state.
- `cover_flit_transfer` — successful flit transfer during `ACTIVE` state.

---

## 11. Reference Model & Scoreboard

### 11.1 Predictor (`tx_predictor`)

The predictor subscribes to both the RDI and LTSM monitors. It maintains internal copies of the current LTSM state and lane map, and produces golden `tx2link_item` transactions by modeling the TX datapath pipeline.

#### TX Datapath Pipeline

The figure below illustrates the datapath blocks inside the predictor and how they interconnect. The TX Controller decodes the current LTSM encoding and asserts enable signals to each downstream block, selecting the active data path through the output multiplexer.

![TX Datapath Pipeline](tx_datapath_pipeline.png)

**Block Descriptions:**

**TX Controller**

- **Central Coordinator:** Acts as the primary router for the output path, dynamically enabling downstream reference models based on the current LTSM state.
- **Decoding Logic:** Utilizes state-based logic to assert targeted enable signals across the modeling environment. For example, during `ACTIVE` state it enables B2L + LFSR (scrambler mode), during `REVERSAL_PER_LANE_ID_GEN` it enables B2L + Per-Lane ID, and during `D2C_TX_PATTERN_GEN` it enables LFSR (pattern generator mode).

**B2L (Byte-to-Lane Mapping)**

- **Byte-to-Lane Mapping:** Distributes the incoming data stream across 16 parallel lanes, allocating exactly 4 bytes per lane.
- **Lane Degradation Support:** Implements protocol-compliant data striping for full x16 operation, seamlessly re-routing data payloads when the link degrades to x8 modes (utilizing either Lanes 0–7 or Lanes 8–15).
- **Protocol Compliance:** Implements the exact lane-mapping tables defined in the protocol specification for data striping.
- **Flow Control & Buffering:** Utilizes a FIFO queue to safely buffer incoming data transactions while the current transmission cycle completes.

**LFSR**

- **Dual-Mode Operation:** Functions as a standalone pattern generator during Link Training states, and switches to a data scrambler during the Active state.
- **Parallel Architecture:** Utilizes a fully unrolled polynomial implementation to calculate and output the next 64 bits of the sequence in a single clock cycle.

**Per-Lane ID Generator**

- **Unique Pattern Synthesis:** Generates protocol-compliant, unique identifier sequences (IDs) for each individual physical lane. Used during the `REVERSAL_PER_LANE_ID_GEN` state for lane identification and reversal detection.

**Reversal**

- **Lane Order Reversal:** Optionally reverses the physical lane ordering (Lane 0 ↔ Lane 15, Lane 1 ↔ Lane 14, etc.) when the reversal result from the REVERSAL state indicates a reversed connection to the link partner.
- **Enable Control:** The TX Controller asserts the reversal enable based on the outcome of the reversal detection phase. When disabled, lanes pass through unchanged.

**Output Mux**

- **Path Selection:** A 2:1 multiplexer controlled by the TX Controller that selects between the Per-Lane ID output (training/reversal detection) and the LFSR output (pattern generation or scrambled active data). The selected output feeds into the Reversal block before reaching the egress interface.

**Datapath pipeline functions:**

| Stage                          | Function                |
| ------------------------------ | ----------------------- |
| 1. Byte-to-Lane Map            | `byte_to_lane_map()`  |
| 2. LFSR Scramble / Pattern Gen | `lfsr_scramble()`     |
| 3. Per-Lane ID Generation      | `per_lane_id_gen()`   |
| 4. Lane Reversal               | `lane_reversal()`     |
| 5. Output Mux Select           | `output_mux_select()` |

### 11.2 Scoreboard (`tx_scoreboard`)

Receives golden items from the predictor and actual items from the TX2Link monitor via two independent TLM analysis FIFOs. Comparison is **event-based** — both FIFOs block until data is available.

Checks performed:

1. **State metadata match** — `captured_state` must agree.
2. **UI count match** — chunk sizes must be equal.
3. **Data comparison** — field-level `compare()` using 4-state logic for Hi-Z correctness.

Reports match/mismatch statistics in `report_phase`.

---

## 12. Configuration & Plusargs

| Plusarg                | Parsed By                           | Default | Description                                       |
| ---------------------- | ----------------------------------- | ------- | ------------------------------------------------- |
| `+FLIT_SIZE=N`       | `rdi_seq_item`                    | 256     | Flit size in bytes (64, 128, 256, 512)            |
| `+ITER=N`            | `rdi_base_seq`, `ltsm_base_seq` | 10      | Number of iterations (flits or state transitions) |
| `+UVM_TESTNAME=name` | UVM core                            | —      | Selects the test class to run                     |

The `tx_env_cfg.parse_plusargs()` method is reserved for future test knobs.

---

## 13. Testbench Top (`tx_tb_top`)

The top module instantiates:

- **Clocks:** `clk` at 100 MHz (logical domain), `ui_clk` at 1 GHz (fast UI domain).
- **Reset:** Active-low, de-asserts after 100 ns.
- **Interfaces:** `rdi_if`, `ltsm_if`, `tx2link_if` — all published to `uvm_config_db`.
- **DUT Stub:** Minimal connectivity (always-ready `pl_trdy`, delayed `pll_stable`/`supply_stable`, pulsed `tx_done`, Hi-Z egress). To be replaced with the actual RTL.
- **SVA Bind:** Commented out; to be enabled upon RTL integration.

---

## 14. File Organization

```
tb/
├── packages/
│   ├── tx_defs_pkg.sv          # Enums, parameters, helper functions
│   └── tx_tb_pkg.sv            # Single-import testbench package
├── interfaces/
│   ├── rdi_if.sv               # RDI interface (parameterized)
│   ├── ltsm_if.sv              # LTSM controller interface
│   └── tx2link_if.sv           # Egress physical interface
├── agents/
│   ├── rdi_agent/              # Active: driver, monitor, sequencer
│   ├── ltsm_agent/             # Active: driver, monitor, sequencer
│   └── tx2link_agent/          # Passive: monitor only
├── seq_items/
│   ├── rdi_seq_item.sv         # Flit transaction
│   ├── ltsm_seq_item.sv        # LTSM state command
│   └── tx2link_item.sv         # Assembled egress chunk
├── seq_lib/
│   ├── sqr_pool.sv             # Sequencer container (singleton)
│   ├── rdi_base_seq.sv         # Reactive RDI sequence
│   ├── ltsm_base_seq.sv        # LTSM state walk sequence
│   └── tx_virtual_seq.sv       # Top-level virtual sequence
├── env/
│   ├── tx_env_cfg.sv           # Centralized configuration
│   └── tx_env.sv               # Top-level UVM environment
├── ref_model/
│   └── tx_predictor.sv         # Golden reference model (with stubs)
├── scoreboard/
│   └── tx_scoreboard.sv        # Golden vs. actual comparison
├── coverage/
│   └── tx_coverage.sv          # Functional coverage collector
├── assertions/
│   └── tx_sva.sv               # SVA protocol assertions
├── tests/
│   ├── tx_base_test.sv         # Base test (config, setup)
│   └── tx_smoke_test.sv        # End-to-end smoke test
└── top/
    └── tx_tb_top.sv            # Top module (clocks, reset, DUT stub)
```
