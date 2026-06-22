# UCIe 3.0 Physical Layer — Design & Verification

> **Graduation Project** · Ain Shams University · Department of Electrical & Computer Engineering  
> Developed in partial fulfilment of the requirements for the degree of B.Sc. in Electrical and Computer Engineering (November 2026)

---

## Table of Contents

- [Overview](#overview)
- [Specification Coverage](#specification-coverage)
- [Architecture](#architecture)
  - [Design Blocks](#design-blocks)
  - [Verification Strategy](#verification-strategy)
- [Repository Structure](#repository-structure)
- [Verification Environments](#verification-environments)
  - [TX Path Environment (`tp_env`)](#tx-path-environment-tp_env)
  - [RX Path Environment (`rp_env`)](#rx-path-environment-rp_env)
  - [Sideband Environment (`sb_env`)](#sideband-environment-sb_env)
  - [LTSM Environment (`LTSM_Environment`)](#ltsm-environment-ltsm_environment)
  - [System-Level Environment (`UCIE_top_env`)](#system-level-environment-ucie_top_env)
- [Test Scenarios](#test-scenarios)
- [Functional Coverage](#functional-coverage)
- [Toolchain & Prerequisites](#toolchain--prerequisites)
- [Running Simulations](#running-simulations)
- [Documentation](#documentation)
- [Future Work](#future-work)
- [Contributors](#contributors)
- [License](#license)

---

## Overview

This repository contains the complete RTL design and UVM-based verification environment for the **UCIe 3.0 (Universal Chiplet Interconnect Express) Physical Layer Logical Interface**, targeting advanced die-to-die (D2D) packaging interconnects.

The project implements the full **Physical Layer Logical Interface** as defined in the UCIe 3.0 specification, covering:

- **Transmitter (TX) Path** — parallel-to-serial conversion, byte-to-lane mapping, LFSR scrambling, clock/valid pattern generation, and FSM-controlled output driving.
- **Receiver (RX) Path** — deserialization, clock/valid pattern detection, LFSR descrambling, per-lane ID detection, lane-to-byte mapping, and FSM-controlled bring-up.
- **Sideband (SB) Controller** — serialized 64-UI packet transport, Gray-code CDC FIFOs, and command/response mapping.
- **Link Training and Status State Machine (LTSM)** — the master protocol controller orchestrating SBINIT, MBINIT, all training substates, ACTIVE, and low-power transitions.

The verification infrastructure is built entirely in **SystemVerilog/UVM 1.2**, with dedicated environments at the block level and a fully integrated system-level loopback testbench. SVA checkers are bound at both block and system levels to enforce temporal protocol correctness.

---

## Specification Coverage

| UCIe 3.0 Feature | Status |
|---|---|
| LTSM training FSM (SBINIT → MBINIT → ACTIVE) | ✅ Implemented & Verified |
| TX byte-to-lane mapping (x16 / x8 / x4) | ✅ Implemented & Verified |
| TX LFSR scrambling (PRBS pattern) | ✅ Implemented & Verified |
| TX forwarded clock & valid pattern generation | ✅ Implemented & Verified |
| RX deserialization & clock/valid pattern detection | ✅ Implemented & Verified |
| RX per-lane ID detection (lane reversal) | ✅ Implemented & Verified |
| RX LFSR descrambling | ✅ Implemented & Verified |
| RX lane-to-byte reassembly | ✅ Implemented & Verified |
| Sideband packet serialization/deserialization | ✅ Implemented & Verified |
| Sideband CDC FIFOs (Gray-code) | ✅ Implemented & Verified |
| Full/half-rate clock mode | ✅ Implemented & Verified |
| Lane width degradation (x16 → x8) | ✅ Implemented & Verified |
| Lane reversal repair | ✅ Implemented & Verified |
| Training error recovery (TRAINERROR) | ✅ Implemented & Verified |
| L1 low-power state | ✅ Implemented & Verified |
| L2 low-power state | 🔲 Future Work |
| Runtime link testing (parity injection/checking) | 🔲 Future Work |
| Sideband Performant Mode Operation (PMO) | 🔲 Future Work |
| Priority Sideband Packet Transfer (PSPT) | 🔲 Future Work |
| x8 → x4 width degradation | 🔲 Future Work |

---

## Architecture

### Design Blocks

```
UCIe_phy (Top-Level DUT Wrapper)
├── PLL_model                          — Generates clk_l, clk_mb_h, clk_mb_f
├── ucie_LTSM                          — Master link training state machine
├── ucie_sb_top                        — Sideband controller & packet engine
├── tx_dut_rtl_wrapper (tx_path.sv)
│   ├── tx_controller.sv               — FSM coordinating TX bring-up states
│   ├── ucie_byte_to_lane.sv           — 2048-bit flit → per-lane byte distribution
│   │   └── ucie_shift_register_b2l.sv — Lane-width adaptive shift registers
│   ├── per_lane_id_generator_top.svh  — Lane reversal ID pattern generation
│   ├── tx_LFSR_top.sv                 — PRBS scrambler
│   ├── mux_2_1.sv                     — Lane-ID vs. flit data selector
│   ├── reversal.sv                    — Physical lane reversal mux
│   ├── fifo.sv                        — Dual-clock rate-matching FIFO (clk_l ↔ dclk)
│   ├── serializer.sv                  — 64-bit parallel → 1-bit serial per lane
│   ├── clk_valid_pattern_generation.sv — Forwarded clocks & valid/track outputs
│   └── driver.sv                      — Tristate output driver
└── rx_path.sv
    ├── receivers.sv                   — Buffered physical lane inputs
    ├── clk_valid_pattern_detection.sv — Clock & valid compliance pattern checker
    ├── deserializer_h.sv (deser_h)    — 1-bit serial → 64-bit parallel per lane
    ├── fifo.sv                        — Dual-clock rate-matching FIFO (dclk ↔ clk_l)
    ├── demux_1_2.sv                   — Lane-ID detector vs. LFSR path selector
    ├── per_lane_id_detector_top.svh   — Lane alignment verification
    ├── rx_LFSR_top.sv                 — PRBS checker & descrambler
    ├── ucie_lane_to_byte.sv           — Per-lane 64-bit → 2048-bit flit reassembly
    ├── synchonizer.sv                 — CDC synchronizers (clk_l ↔ dclk)
    └── ucie_rx_controller.sv          — RX FSM orchestrator
```

The **TX output lanes are looped back to the RX mainband inputs** inside `UCIe_phy`, enabling end-to-end loopback verification at the system level.

### Verification Strategy

The verification approach uses a **layered UVM architecture**:

```
System Level  →  UCIE_top_env   (full loopback: TX + RX + SB + LTSM)
Block Level   →  tp_env         (TX path isolation)
              →  rp_env         (RX path isolation)
              →  sb_env         (Sideband isolation)
              →  LTSM_env       (LTSM FSM isolation)
```

Each environment includes constrained-random stimulus, reference predictors, scoreboards, and functional coverage. SystemVerilog Assertions (SVA) checkers are bound at block and system levels for temporal verification of handshakes and pattern sequences.

---

## Repository Structure

```
UCIE_GP/
│
├── tx_path/                    # TX RTL design sources
│   ├── tx_path.sv              # Top-level TX module
│   ├── tx_controller.sv
│   ├── ucie_byte_to_lane.sv
│   ├── serializer.sv
│   ├── clk_valid_pattern_generation.sv
│   └── ...
│
├── rx_path/                    # RX RTL design sources
│   ├── rx_path.sv              # Top-level RX module
│   ├── ucie_rx_controller.sv
│   ├── deserializer_h.sv
│   ├── clk_valid_pattern_detection.sv
│   └── ...
│
├── Sideband/                   # Sideband RTL design sources
│   ├── ucie_sb_top.sv
│   └── ...
│
├── LTSM/                       # LTSM RTL design sources
│   ├── ucie_LTSM.sv
│   └── ...
│
├── UCIE_top/                   # System-level DUT wrapper & testbench top
│   ├── UCIe_phy.sv             # Top-level design integrator
│   └── ucie_tb_top.sv          # System testbench
│
├── tp_env/                     # TX path UVM environment
│   ├── agents/                 # rdi_agent, ltsm_agent, tx2link_agent
│   ├── sequences/              # LTSM, RDI, reset, virtual sequences
│   ├── scoreboard/             # tx_scoreboard, tx_predictor, B2L model
│   ├── coverage/               # tx_coverage.sv
│   └── tests/                  # tx_base_test, tx_smoke_test
│
├── rp_env/                     # RX path UVM environment
│   ├── agents/                 # rdi_agent, ltsmc_agent, rmblink_agent
│   ├── sequences/              # LTSMC, RMBLink, active & sanity sequences
│   ├── scoreboard/             # rp_scoreboard, rp_pred, rp_cmp_rdi
│   ├── coverage/               # rp_coverage_collector.sv
│   ├── sva/                    # rp_sva.sv (bound SVA checker)
│   └── tests/                  # rp_test_base, sanity_clk, sanity_lfsr, active …
│
├── sb_env/                     # Sideband UVM environment
│   └── ...
│
├── LTSM_Environment/           # LTSM UVM environment
│   └── src/
│       └── ...
│
├── UCIE_top_env/               # System-level UVM environment
│   ├── env/                    # ucie_env.sv, ucie_env_cfg.sv, ucie_vseqr.sv
│   ├── seq_lib/                # 29 virtual sequences (mbinit, mbtrain, D2C …)
│   └── tests/                  # 7 system-level test cases
│
├── tx_path_verification_details.md      # Detailed TX environment documentation
├── rx_path_verification_details.md      # Detailed RX environment documentation
├── system_level_verification_details.md # System-level environment documentation
├── UCIe_RXPath_Verification_Env_Detailed_Notes.md
├── UCIe_RX_Verification_Detailed_Notes.md
├── UCIe_Sideband_Design_Detailed_Notes.md
├── UCIe_Future_Work_Specification.md    # Specification for future extensions
│
├── UCIe_3_PHY_Design_and_Verification_GP_Thesis.pdf
├── UCIe_3_PHY_Design_and_Verification_GP_Presentation.pdf
│
└── .gitignore
```

---

## Verification Environments

### TX Path Environment (`tp_env`)

**DUT:** `tx_path.sv` — 2048-bit RDI flit input → 16-lane serialized physical output.

**UVM Hierarchy:**
```
uvm_test_top (tx_smoke_test)
└── tx_env
    ├── tx_env_cfg                  [config object: VIF handles, mode flags]
    ├── rdi_agent      [ACTIVE]     [drives lp_data / lp_valid / lp_irdy]
    ├── ltsm_agent     [ACTIVE]     [drives tx_encoding / lane_map_code]
    ├── tx2link_agent  [PASSIVE]    [monitors physical serial outputs]
    ├── tx_scoreboard               [tx_predictor + element-wise comparison]
    └── tx_coverage                 [functional coverage collector]
```

**Key Features:**
- `tx_predictor` reference model simulates the internal TX FSM, B2L mapper (`B2L_modelling.sv`), LFSR scrambler, and lane reversal in software.
- Reactive cross-agent TLM FIFO gates RDI flit generation until the LTSM reaches `ACTIVE`.
- State-aware physical monitor (`tx2link_monitor`) groups sampled serial streams into multi-cycle parallel chunks based on current LTSM state.
- Hi-Z output validation supported for tristate states.

**Test Scenarios:**

| Test | Description |
|---|---|
| `tx_smoke_test` | Full happy path: RESET → SBINIT → PARAM → CAL → REPAIRCLK → REPAIRVAL → REVERSAL → REPAIRMB → Training → LINKINIT → ACTIVE. Verifies 10 flits end-to-end. |
| LTSM `GROUP_HAPPY_PATH` | Sequential walk through entire training state tree. |
| LTSM `GROUP_PATTERN_GEN` | States requiring physical training patterns. |
| LTSM `GROUP_TRAIN_ERROR` | TRAINERROR entry and recovery to RESET. |
| LTSM `GROUP_TRISTATE` | States where all physical outputs must be Hi-Z. |
| LTSM `GROUP_ACTIVE` | LINKINIT, ACTIVE, L1, EXIT_HS transitions. |

---

### RX Path Environment (`rp_env`)

**DUT:** `rx_path.sv` — 16-lane serialized physical input → 2048-bit RDI flit output.

**UVM Hierarchy:**
```
uvm_test_top (rp_sanity_all_test)
└── rp_env
    ├── env_config                        [VIF handles + mode flags]
    ├── reset_driver                      [drives simulation resets]
    ├── rdi_agent        [PASSIVE]        [monitors o_pl_data / o_pl_valid]
    ├── ltsmc_agent      [ACTIVE]         [drives rx_encoding, lane_map, error_threshold]
    ├── rmblink_agent    [ACTIVE]         [drives i_lanes, i_clk_p/n, i_valid, i_track]
    ├── rp_scoreboard
    │   ├── rp_pred                       [SW predictor: lane-ID, LFSR, L2B, error count]
    │   ├── rp_cmp_rdi                    [expected vs actual RDI flit comparator]
    │   └── rp_cmp_ltsmc                  [expected vs actual FSM result comparator]
    ├── rp_coverage_collector
    └── virtual_sequencer
```

**SVA Checker (`rp_sva.sv`) — bound to DUT:**

| Assertion | What It Checks |
|---|---|
| `assert_valid_pattern_16_frame` | `11110000` frame repeats correctly in REPAIRVAL state |
| `assert_clk_p/n_pattern_frame` | Differential forwarded clock pattern compliance |
| `assert_track_pattern_frame` | Tracking signal transitions |
| `chk_async_reset_zeros` | `o_pl_data` and `o_pl_valid` are zero during reset |
| `chk_async_reset_ones` | `o_rx_done`, result registers are one during reset |

**Test Scenarios:**

| Test | Sequence | Scope |
|---|---|---|
| `rp_sanity_clk_test` | `rp_clk_sanity_vseq` | Clock pattern validation in REPAIRCLK |
| `rp_sanity_valid_test` | `rp_vaild_sanity_vseq` | Valid signal pattern (11110000) |
| `rp_sanity_PerLaneID_test` | `rp_sanity_PerLaneID_vseq` | Lane reversal ID detection |
| `rp_sanity_lfsr_test` | `rp_sanity_lfsr_vseq` | LFSR training patterns & error counts |
| `rp_active_test` | `rp_active_vseq` | Deserialization, CDC, L2B mapping in ACTIVE |
| `rp_sanity_all_test` | `rp_sanity_all_vseq` | Full sequential training walk-through |

---

### Sideband Environment (`sb_env`)

**DUT:** `ucie_sb_top` — sideband serial packet engine including CDC FIFOs, command mapping, and register access.

- `phylink_agent` [ACTIVE] drives the physical sideband serial wires.
- Passive agents monitor internal controller flags, TX/RX status, and RDI sideband state.
- SVA checker (`sb_sva`) is bound directly to `ucie_sb_top` using `bind` statements to check packet-level protocol handshakes and initialization sequences.

---

### LTSM Environment (`LTSM_Environment`)

**DUT:** `ucie_LTSM` — the master link training and status state machine.

- `ltsm_rdi_agent` [ACTIVE] drives adapter-side RDI state requests (`lp_state_req`, `lp_linkerror`, `lp_clk_ack`).
- Passive agents capture TX FSM status, RX FSM status, and controller flags.
- Verifies state sequencing across SBINIT, MBINIT, all training sub-states, ACTIVE, L1, and RETRAIN.

---

### System-Level Environment (`UCIE_top_env`)

**DUT:** `UCIe_phy` — full physical layer with TX ↔ RX loopback, integrated PLL model, LTSM, and sideband.

**UVM Hierarchy:**
```
uvm_test_top (ucie_sanity_test)
└── ucie_env
    ├── ucie_env_cfg          [aggregates ltsm_cfg, sb_cfg, rp_cfg, tx_cfg]
    ├── ucie_vseqr            [master virtual sequencer + SB reactive predictors]
    ├── LTSM_env              [ltsm_rdi_agent ACTIVE + passive TX/RX FSM monitors]
    ├── sb_env                [phylink_agent ACTIVE + passive SB monitors]
    ├── rp_env                [rmblink_agent ACTIVE + passive RDI/LTSMC monitors]
    └── tx_env                [rdi_agent ACTIVE + passive TX monitors]
```

**Sideband Reactive Pipeline:** The sideband physical monitor feeds captured packets into `prd_link2ltsm`/`prd_ltsm2link` predictors, which push resolved sideband messages into `rx_fifo`/`tx_fifo`. Virtual sequences poll these FIFOs to drive protocol-correct sideband responses in real time.

**System-Level Test Cases:**

| Test | Virtual Sequence | Scope |
|---|---|---|
| `ucie_sanity_test` | `ucie_mbinit_bringup_vseq` | Full happy-path bring-up + active loopback data |
| `ucie_sbinit_test` | `ucie_sbinit_vseq` | Sideband initialization (`sb_ready` assertion) |
| `ucie_mbinit_fail_test` | `ucie_mbinit_fail_vseq` | Config failure → TRAINERROR recovery |
| `ucie_mbtrain_from_valtraincenter_to_DTC2_test` | `…vseq` | Valid eye centering through DTC2 |
| `ucie_mbtrain_linkspeed_test` | `ucie_mbtrain_linkspeed_cases_vseq` | Speed/width negotiation (x16 → x8) |
| `ucie_vvref_till_rxcal_vseq_test` | `ucie_vvref_till_rxcal_vseq` | Targeted walk up to RX clock calibration |

---

## Test Scenarios

The project contains over **29 virtual sequences** and **7 system-level tests** covering the following major verification scenarios:

- Happy-path bring-up (SBINIT → MBINIT → REPAIRCLK → REPAIRVAL → REVERSAL → REPAIRMB → Training → LINKINIT → ACTIVE)
- Training error injection and recovery
- Lane degradation (x16 → x8) and repair flows
- Sideband initialization and packet integrity
- Clock and valid pattern compliance
- Per-lane ID detection and lane reversal correction
- LFSR lock, error counting, and descrambling
- Full/half-rate clock mode transitions
- Vref sweeps (valid and data lanes)
- Data-to-clock (D2C) eye sweeps — TX and RX initiated
- RX deskew and clock centering
- Link speed negotiation
- Active loopback data integrity (TX → physical → RX → RDI)
- Low-power L1 entry and exit

---

## Functional Coverage

**TX Path (`tx_coverage.sv`):**

| Coverage Point | Description |
|---|---|
| `cp_encoding` | All 9-bit LTSM state encodings visited |
| `cp_lane_map` | All active lane map configurations exercised (x16, x8 lanes 0–7, x8 lanes 8–15) |
| `cx_encoding_x_lane_map` | Cross coverage of FSM states × lane maps, focused on REPAIRMB and REPAIR states |
| `cp_transitions` | Happy-path state transitions, D2C entry/exit paths, TRAINERROR entry and recovery |

**RX Path (`rp_coverage_collector.sv`):**

Coverage is collected from both `rmblink_agent` and `ltsmc_agent` monitors, tracking physical stimulus patterns, FSM state transitions, error threshold crossings, and lane configuration combinations.

---

## Toolchain & Prerequisites

| Tool | Version | Purpose |
|---|---|---|
| QuestaSim / ModelSim | 2021.1+ | RTL simulation & coverage collection |
| Design Compiler Classic | — | Synthesis (with blackboxed analog stubs) |
| SpyGlass | — | Lint (waivers for `InferLatch`; `always_ff` blocking assignment fixes) |
| SystemVerilog | IEEE 1800-2017 | RTL & verification language |
| UVM | 1.2 | Verification framework |

**Simulator invocation uses UVM packages from the standard UVM 1.2 library.** No external package dependencies beyond what ships with the simulator are required.

---

## Running Simulations

### TX Path Block-Level Simulation

```bash
cd tp_env
# Compile
vlog -sv -work work \
     +incdir+./agents +incdir+./sequences +incdir+./scoreboard +incdir+./coverage \
     -f tx_filelist.f
# Run smoke test
vsim -c tx_smoke_test -do "run -all; quit" \
     +UVM_TESTNAME=tx_smoke_test +ITER=10
```

### RX Path Block-Level Simulation

```bash
cd rp_env
# Compile
vlog -sv -work work \
     +incdir+./agents +incdir+./sequences +incdir+./scoreboard \
     -f rp_filelist.f
# Run sanity-all test
vsim -c rp_sanity_all_test -do "run -all; quit" \
     +UVM_TESTNAME=rp_sanity_all_test
```

### System-Level Simulation

```bash
cd UCIE_top
# Compile full design and system environment
vlog -sv -work work \
     +incdir+../UCIE_top_env +incdir+../tp_env +incdir+../rp_env \
     +incdir+../sb_env +incdir+../LTSM_Environment/src \
     -f ucie_top_filelist.f
# Run full sanity test
vsim -c ucie_sanity_test -do "run -all; quit" \
     +UVM_TESTNAME=ucie_sanity_test
```

**Coverage collection:**
```bash
vsim ... -coverage -do "coverage save -onexit sim.ucdb; run -all; quit"
vcover merge merged.ucdb sim.ucdb
vcover report -html merged.ucdb -output coverage_report/
```

> **Note:** Analog blocks (`clk_valid_pattern_generation`, `clk_valid_pattern_detection`, `deser_h`) are blackboxed during synthesis. Behavioral RTL models are used during simulation. Refer to the `UCIe_Sideband_Design_Detailed_Notes.md` and block-level notes for individual compile commands and waivers.

---

## Documentation

The following documentation files are included in this repository:

| File | Contents |
|---|---|
| [`tx_path_verification_details.md`](tx_path_verification_details.md) | TX UVM hierarchy, TLM connections, phase execution, test scenarios, and coverage details |
| [`rx_path_verification_details.md`](rx_path_verification_details.md) | RX UVM hierarchy, SVA checker details, sequence flows, and test cases |
| [`system_level_verification_details.md`](system_level_verification_details.md) | System-level environment, interface bindings, sideband reactive pipeline, all 29 virtual sequences |
| [`UCIe_RXPath_Verification_Env_Detailed_Notes.md`](UCIe_RXPath_Verification_Env_Detailed_Notes.md) | RX path environment design notes |
| [`UCIe_RX_Verification_Detailed_Notes.md`](UCIe_RX_Verification_Detailed_Notes.md) | RX block verification notes |
| [`UCIe_Sideband_Design_Detailed_Notes.md`](UCIe_Sideband_Design_Detailed_Notes.md) | Sideband design and verification notes |
| [`UCIe_Future_Work_Specification.md`](UCIe_Future_Work_Specification.md) | Detailed specification for planned extensions |
| [`UCIe_3_PHY_Design_and_Verification_GP_Thesis.pdf`](UCIe_3_PHY_Design_and_Verification_GP_Thesis.pdf) | Full graduation project thesis |
| [`UCIe_3_PHY_Design_and_Verification_GP_Presentation.pdf`](UCIe_3_PHY_Design_and_Verification_GP_Presentation.pdf) | Project presentation slides |

---

## Future Work

Planned extensions are fully specified in [`UCIe_Future_Work_Specification.md`](UCIe_Future_Work_Specification.md). Key items include:

**LTSM:**
- L2 low-power state with Three-Phase exit flow (UCIe Spec §4.5.3.9.1)
- L2 Sideband Power Down (L2SPD) negotiation
- PHYRETRAIN FSM bug fix in `ucie_LTSM_TX_phyretrain.sv` (incorrect `3'b010` check → `3'b100`)
- TRAINERROR full sideband handshake with 8-ms timeout

**Sideband:**
- Performant Mode Operation (PMO) — back-to-back 64-UI transfer without dead-time
- Priority Sideband Packet Transfer (PSPT) — packet interruption at 8-UI boundary
- Management Transport Path (MTP) with 4-ms keep-alive and 8-ms heartbeat timer
- Complete Register Access opcodes (Read/Write + Completion packets)
- End-to-End flow control via credit bit

**TX Path:**
- Runtime link testing: parity injection block with periodic XOR parity over 256×N byte windows
- x8 → x4 width degradation lane mapping
- Multi-module configuration support

**RX Path:**
- Runtime link testing: parity checker with log registers (offsets 34h/3Ch/44h/4Ch)
- Gated receiver lane power-down for degraded width modes
- Clock and track lane repair using redundant `RRDCK_P`
- Dynamic clock gating postamble (16 UI half-rate / 32 UI quarter-rate)
- Runtime recalibration and continuous phase tracking (RX Deskew)

---

## Contributors

| Name | Role |
|---|---|
| **Abdelrahman Mohamed** | Digital Verification — TX/RX UVM environments, SVA, coverage closure, synthesis flow |
| **Hussin Mohamed** | Digital Design — RTL implementation of TX path, RX path, Sideband, LTSM |
| *(Additional team members)* | *(System-level integration, LTSM environment, documentation)* |

Graduation project supervised at **Ain Shams University, Faculty of Engineering**, Department of Electrical & Computer Engineering.

---

## License

This project was developed as an academic graduation project at Ain Shams University. The code and documentation are shared for educational and reference purposes. For any use beyond personal study, please contact the repository owner.

---

<p align="center">
  <sub>Built with SystemVerilog · UVM 1.2 · QuestaSim · UCIe 3.0 Specification</sub>
</p>
