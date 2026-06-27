<div align="center">
  <h1 align="center">UCIe 3.0 Logical PHY Design and Verification</h1>
  <p align="center">
    <strong>A comprehensive RTL design and UVM verification of the Universal Chiplet Interconnect Express (UCIe) 3.0 Logical Physical Layer.</strong>
  </p>
  
  [![UVM Verification](https://img.shields.io/badge/Verification-UVM_1.2-brightgreen.svg)](https://accellera.org/downloads/standards/uvm)
  [![Synthesis](https://img.shields.io/badge/Synthesis-14nm_DCC-blue.svg)](#results)
  [![Timing](https://img.shields.io/badge/Timing-Met_@500MHz-success.svg)](#results)
  [![Spec](https://img.shields.io/badge/Specification-UCIe_3.0-orange.svg)](https://www.uciexpress.org/)
</div>

<br />

## 📖 Table of Contents
- [Project Overview](#-project-overview)
- [Team Members & Supervisors](#-team-members--supervisors)
- [System Architecture](#-system-architecture)
  - [LTSM (Link Training State Machine)](#ltsm-link-training-state-machine)
  - [Sideband](#sideband)
  - [TX Path](#tx-path)
  - [RX Path](#rx-path)
- [Verification Methodology](#-verification-methodology)
- [Repository Structure](#-repository-structure)
- [Implementation & Results](#-implementation--results)
- [Documentation & Notes](#-documentation--notes)

<br />

## 🚀 Project Overview

As die sizes approach the reticle limit of lithography equipment, the semiconductor industry is shifting towards multi-die, chiplet-based system architectures. The **Universal Chiplet Interconnect Express (UCIe)** is an open industry standard that defines the interconnect between chiplets within a package, enabling an open chiplet ecosystem.

This repository contains the complete **RTL Design and UVM-based Verification** of the **Logical Layer (Digital Part of the Physical Layer)** for UCIe 3.0. This was developed as a Bachelor's Graduation Project.

### Key Specifications:
- **Lanes:** Parameterized for 16 Mainband Lanes.
- **Data Widths:** 2048-bit RDI (Raw Data Interface) data width and 64-bit mainband data width.
- **Supported Speeds:** Multi-speed operation with 6 reference clocks (32/24/16/12/8/4 GHz).
- **Package Type:** Standard Package (2D) with lane degradation support (x16 to x8 modes), but without full lane repair logic.
- **Clocking:** Internal high-speed full-rate mainband clock (`clk_mb_f`) and logical clock (`clk_l`).

<br />

## 👥 Team Members & Supervisors

**Team Members:**
- Hussien Mohamed Hussien
- Omar Mohamed Araby
- Amr Ayman Batarny
- Abdelrahman Mohamed Ragab
- Youssef Gamal El Deen
- Mahmoud Hussien
- Mahmoud Hesham Abdelmoniem

**Supervisors:**
- Dr. Sameh Ibrahim
- Eng. Kareem Waseem

<br />

## 🏗 System Architecture

The design is modularized into four core parallel datapath and control components, orchestrated by a Top-Level Wrapper (`UCIE_top`).

### LTSM (Link Training State Machine)
The logic brain of the physical layer. Deconstructed into parallel, synchronized paths (`TX_FSM` and `RX_FSM`). 
- **Initialization:** Handles `RESET`, `SBINIT`, `MBINIT`, and `TRAINERROR`.
- **Training:** Orchestrates `MBTRAIN` and `PHYRETRAIN` (Clock, Valid, Data centering, Vref sweeps).
- **Active:** Manages `LINKINIT`, `ACTIVE`, and low-power state `L1`.

### Sideband
A low-speed, highly reliable communication channel running parallel to the main data lanes. Dedicated to link training, configuration, and parameter negotiation without consuming mainband data bandwidth.
- Features cross-clock domain asynchronous FIFOs and synchronous FWFT FIFOs.
- Hardware traffic manager and message formatters with instant parity check validation.

### TX Path
The outgoing Mainband physical layer module. It handles high-bandwidth parallel flit data.
- **Byte-to-Lane (B2L):** Distributes 2048-bit RDI flits across active physical lanes (4 bytes per lane per cycle).
- **LFSR & Serialization:** Scrambles outgoing data or generates PRBS training patterns, then serializes 64-bit parallel data into high-speed serial bitstreams.
- **Clock & Valid Generators:** Generates forwarded clocks (`clk_p`/`clk_n`), tracking, and valid physical signals.

### RX Path
The incoming Mainband traffic receiver and processor.
- **Signal Integrity:** Uses Clock-Valid Detectors and Per-Lane ID Detectors to verify signal integrity, ensuring correct lane mappings during training.
- **Descrambling & Assembly:** RX LFSR per lane descrambles live data. The Lane-to-Byte (L2B) module packs the active 64-bit lanes back into the 2048-bit RDI output.

<br />

## 🛡 Verification Methodology

The verification environment was built from the ground up using **UVM 1.2 (Universal Verification Methodology)**. We adopted a vertically reusable architecture, testing sub-modules independently before combining them into a unified system-level top environment.

- **Block-Level UVM Environments:**
  - `LTSM_Environment`: Verifies all FSM state transitions, timeout mechanisms, and remote handshakes.
  - `sb_env` (Sideband): Validates sideband message transceiver data integrity, encoding/decoding, and concurrency logic. Split predictors and Cummings SNUG 2013 patterns were employed.
  - `tp_env` (TX Path): Predicts physical signal behaviors, LFSR output, and lane degradation configurations.
  - `rp_env` (RX Path): Mirrored architecture from TX Path checking data aggregation and error signaling.

- **System-Level Verification (`UCIE_top_env`):**
  - Achieves **Vertical Reusability** by instantiating block-level UVM agents, predictors, and scoreboards into a master framework.
  - Runs a comprehensive **Sanity Flow (Link Bring-Up Sequence)** that brings the entire connection from physical reset, through sideband initialization, mainband parameter negotiation, clock/data calibration, and finally into the `ACTIVE` state payload streaming.
  - Includes assertions (SVAs) bound directly to inner physical sideband wires and training clocks.

<br />

## 📂 Repository Structure

The repository is organized to separate RTL design blocks from their respective UVM environments:

```text
📁 UCIe_GP/
├── 📁 LTSM/                  # Link Training State Machine RTL
├── 📁 LTSM_Environment/      # UVM Verification Environment for LTSM
├── 📁 Sideband/              # Sideband Path RTL (Transceiver, FIFOs, Traffic Manager)
├── 📁 sb_env/                # UVM Verification Environment for Sideband
├── 📁 tx_path/               # TX Mainband Path RTL (Controller, B2L, LFSR, Serializer)
├── 📁 tp_env/                # UVM Verification Environment for TX Path
├── 📁 rx_path/               # RX Mainband Path RTL (Controller, Detectors, L2B, LFSR)
├── 📁 rp_env/                # UVM Verification Environment for RX Path
├── 📁 UCIE_top/              # Top-Level Integrated RTL Wrapper
├── 📁 UCIE_top_env/          # Full System-Level UVM Integration Environment
└── 📄 *.md                   # Detailed design and verification documentation notes
```

<br />

## 📊 Implementation & Results

### ASIC Synthesis & Timing
- **Technology Node:** Successfully synthesized on **14nm technology node** using Synopsys Design Compiler (DCC).
- **Timing Closure:** Fully met all timing constraints at a **500 MHz logical clock frequency (2.0 ns period)**, successfully supporting the Logical PHY’s maximum target data rate scaling.

### Verification Bug Discoveries
Across the project lifecycle, the UVM framework successfully caught and verified fixes for numerous complex RTL bugs:
- **LTSM:** Fixed 22 bugs including complex `TRAINERROR` deadlock transitions and invalid speed sweeps.
- **Sideband:** Found 10 bugs covering zero-time clock glitches (caught by SVAs), incorrect MSB/LSB swapping, and active reset recovery failures.
- **TX/RX Paths:** Resolved 23 datapath bugs, including lane reversal specification mismatches, serializer bit drops, and premature validation triggers.
- **System Top:** Caught complex clock domain synchronization issues between the slower Sideband clock and the faster LTSM logical clock, as well as remote `TRAINERROR` cross-die state handling.

<br />

## 📚 Documentation & Notes

The repository contains extensive markdown documentation generated during the design and verification phases. Please refer to the following files for deep-dive technical details:
- [`system_level_verification_details.md`](system_level_verification_details.md)
- [`tx_path_verification_details.md`](tx_path_verification_details.md)
- [`rx_path_verification_details.md`](rx_path_verification_details.md)
- [`UCIe_RX_Verification_Detailed_Notes.md`](UCIe_RX_Verification_Detailed_Notes.md)
- [`UCIe_Sideband_Design_Detailed_Notes.md`](UCIe_Sideband_Design_Detailed_Notes.md)
- [`UCIe_Future_Work_Specification.md`](UCIe_Future_Work_Specification.md)
- [`UCIe_3_PHY_Design_and_Verification_GP_Presentation.pdf`](UCIe_3_PHY_Design_and_Verification_GP_Presentation.pdf)
- [`UCIe_3_PHY_Design_and_Verification_GP_Thesis.pdf`](UCIe_3_PHY_Design_and_Verification_GP_Thesis.pdf)

---
*Developed for the Graduation Project Final Discussion - June 2026*
