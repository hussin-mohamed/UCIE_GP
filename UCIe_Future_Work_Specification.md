# UCIe 3.0 Physical Layer Future Work Specification

This document outlines the detailed future work items and specifications for extending the Universal Chiplet Interconnect Express (UCIe) 3.0 Physical Layer design. The specifications are categorized by the four main functional blocks:
1. **Link Training and Status State Machine (LTSM)**
2. **Sideband (SB) Controller**
3. **Transmitter (TX) Path**
4. **Receiver (RX) Path**

---

## 1. Link Training and Status State Machine (LTSM)

The current LTSM design supports the basic bring-up flow up to `ACTIVE` and transitions to `L1` (low power) or `RETRAIN`. The following major features from the UCIe 3.0 specification should be implemented in future work:

### 1.1 L2 Low Power State Implementation
The current implementation explicitly states that the L2 state is unsupported (e.g., in `ucie_ltsm_active.sv`: `// L2 is not supported by this implementation`).
* **L2 State Transitions**: 
  - Update the active FSM to support entry into `L2` state upon receiving RDI state request `LP_REQ_L2 = 4'b1000`.
  - On entry to L2, the Physical Layer must coordinate with the corresponding RDI state transitions, power down mainband lanes, and hold transmitters low.
* **L2 Sideband Power Down (L2SPD) Support**:
  - Implement L2SPD capability advertisement and negotiation during parameter exchange using bit [4] of the `SBFE` (Sideband Feature Extensions) request/response messages (`{MBINIT.PARAM SBFE req/resp}`).
  - If L2SPD is negotiated, aggressively power down the sideband clock and data receivers.
  - Implement the **Three-Phase L2 Exit Flow** (UCIe Spec §4.5.3.9.1):
    - **Phase 1 (L2 Exit Trigger)**:
      - If an L2 exit trigger (forwarded sideband clock and data held high) is detected on the sideband receiver for at least 100 ns, OR if the local UCIe Module is initiating L2 exit, the local die must power up its PLLs.
      - Once PLLs are stable, the local die must assert the L2 exit trigger on its local sideband transmitter.
      - Hold the trigger for at least 100 ns before transitioning to Phase 2.
    - **Phase 2 (SBINIT)**:
      - Automatically trigger the Sideband Initialization (SBINIT) FSM to align sideband clocks.
    - **Phase 3 (RDI Active Handshake)**:
      - Run the RDI Active handshake to transition back to the `ACTIVE` state.

### 1.2 RDI/FDI Power State & Cross-Product Transitions
* **L2 Cross Product with Retrain on RDI** (UCIe Spec §10.3.5.3):
  - Handle scenarios where the adapter requests a Retrain immediately during L2 exit.
  - Coordinate RDI signals `lp_state_req` and `pl_state_sts` transitions during concurrent power state and retrain negotiations.
* **FDI/RDI State Machine Mapping**:
  - Complete FDI state transitions to match the LTSM (UCIe Spec §10.2.6).

### 1.3 PHYRETRAIN FSM Bug Fixes and Enhancements
* **Design Bug Fix in `ucie_LTSM_TX_phyretrain.sv`**:
  - In the `START_REQ_HANDSHAKE` state, the second `else-if` branch incorrectly checks `i_tx_info[2:0] == 3'b010` (which is duplicate check for speed change) instead of `3'b100` (lane-repair code). This prevents the FSM from transitioning to the `REPAIR` state during retrain. Fix this to check for `3'b100`.
* **Retrain Exit State Resolution** (UCIe Spec Table 4-12):
  - Implement the priority resolution logic in both TX and RX retrain state machines:
    - If local die requests `TXSELFCAL` (001b) and remote requests `REPAIR` (100b), resolve to `REPAIR`.
    - If local die requests `REPAIR` (100b) and remote requests `SPEEDIDLE` (010b), resolve to `SPEEDIDLE` (degrade speed).
    - In general, `SPEEDIDLE` (010b) > `REPAIR` (100b) > `TXSELFCAL` (001b).
  - Check the "Busy" bit and "Repair Required" status from the Runtime Link Test Status Register (Table 4-10) to determine the local retrain request encoding.

### 1.4 TRAINERROR FSM and Error Escalation
* **TRAINERROR Handshake**:
  - Implement full sideband handshake protocol: when transitioning to `TRAINERROR` from any state other than `SBINIT`, send `{TRAINERROR Entry req}` sideband message and wait for `{TRAINERROR Entry resp}`.
  - Implement an 8-ms timer. If no response is received within 8 ms, force transition to `TRAINERROR`.
  - Hold the LTSM in `TRAINERROR` as long as RDI is in `LinkError` (error escalation).

---

## 2. Sideband (SB) Controller

The current Sideband Controller implements basic message serialization/deserialization, Gray-code CDC FIFOs, and a subset of command mappings. Future extensions should implement the following features:

### 2.1 Sideband Performant Mode Operation (PMO)
* **PMO Negotiation**:
  - Support PMO capability exchange via bit [1] of `{MBINIT.PARAM SBFE req/resp}` sideband messages (UCIe Spec Table 7-11).
* **Back-to-Back Transmission**:
  - When PMO is enabled, remove the mandatory 32-UI idle dead-time between 64-UI transfers, enabling continuous back-to-back serialization.
  - Implement backward compatibility on the receiver to handle both PMO (0-UI gap) and non-PMO (32-UI gap) packet flows seamlessly.

### 2.2 Priority Sideband Packet Transfer (PSPT)
* **PSPT Negotiation**:
  - Negotiate PSPT using bit [3] of `{MBINIT.PARAM SBFE req/resp}`. Note that PMO must be supported and enabled to use PSPT.
* **Normal Packet Interruption**:
  - Implement logic in `ucie_sb_traffic` and the serializer to interrupt normal traffic packets at an 8-UI boundary.
  - Insert exactly 8 UI of idle line state, then transmit the 64-UI priority packet (Opcodes `11110b` or `11111b`).
* **Chaining Priority Packets**:
  - Opcode `11110b` indicates that another priority packet follows immediately.
  - Opcode `11111b` indicates the end of the priority chain, allowing the interrupted normal packet to resume.
* **Receiver Assembly Re-synchronization**:
  - Update `ucie_sideband_fifo_traffic` to track interrupted packet offsets and correctly reconstruct the original normal traffic packet.

### 2.3 Management Transport Path (MTP) and Heartbeat Mechanism
* **MTP Opcodes**:
  - Support Management Port Messages (MPM) without data (Opcode `10111b`) and with data (Opcode `11000b`).
* **8-ms Heartbeat Timer** (UCIe Spec §8.2.5.1.3):
  - Implement a receiver timer that restarts on receiving any MPM packet.
  - If the timer times out (no MPM received for 8 ms), de-assert `mp_mgmt_up` after 16 ms, clear `SB_MGMT_UP` in the PHY, and de-assert `mp_mgmt_port_gateway_ready`.
* **4-ms Keep-Alive Transmission**:
  - Implement logic in the transmitter to guarantee sending an MPM at least every 4 ms. If no actual management packets are queued, send a credit return packet with `VC=VC0`, `Resp=0`, and `cr_ret=0`.

### 2.4 Register Access and Completion Support
* **Register Packet Types**:
  - Implement opcodes `00000b` to `01101b` (Register Access Requests: Memory Read/Write, DMS Register Read/Write, Configuration Read/Write for both 32-bit and 64-bit data sizes).
* **Completion Handshake**:
  - Implement completion packet formatting (Opcodes `10000b` (Completion without Data), `10001b` (Completion with 32b Data), `11001b` (Completion with 64b Data)) and tag tracking.

### 2.5 End-to-End (E2E) Flow Control
* **Credit Tracking**:
  - Support the credit bit (`Cr` in packet header) to return credits to the remote die's adapter, preventing buffer overflow on credited sideband message streams.

---

## 3. Transmitter (TX) Path

The TX Path performs serialization and byte-to-lane mapping. Future extensions should integrate:

### 3.1 Runtime Link Testing - Parity Injection Block
* **Parity Periodicity**:
  - Implement a periodic parity injection engine. When `Runtime Link Testing Tx Enable` is set in the `Error and Link Testing Control` register, insert 64*N bytes of parity every 256*256*N bytes of active data.
* **Parity Computation**:
  - Compute a running XOR parity over the transmitted data bytes (excluding parity bytes themselves, but including NOP flits and padding).
  - Bit 0 of parity byte $X$ is computed as:
    $$ParityByte_X[0] = \bigoplus_{k=0}^{256} DataByte_{X + 64 \cdot N \cdot k}$$
  - The remaining 7 bits of the parity byte must be driven to zero.
* **Sideband Coordination**:
  - Exchange `{ParityFeature.Req}` and `{ParityFeature.Ack}` during Retrain or L1 to ensure the remote receiver is prepared for parity injection.

### 3.2 Width Degradation mapping (x8 to x4)
* **Contiguous Gated Lane Mapping**:
  - Implement standard package x8 degraded to x4 mode in `ucie_byte_to_lane.sv`.
  - Ensure that when the lane configuration is degraded to x4, the 2048-bit flits are serialized and distributed only to the designated active lanes (either Lanes 0-3 or Lanes 4-7 based on `i_lane_map_code`), while the other 12 lanes are tri-stated.

### 3.3 Multi-module Configurations
* Support width degradation and lane mapping alignment across multiple modules operating in parallel.

---

## 4. Receiver (RX) Path

The RX Path deserializes data and reassembles flits. Future work includes:

### 4.1 Runtime Link Testing - Parity Checker Block
* **Parity Extraction**:
  - Count incoming bytes in the active state and extract the 64*N parity bytes injected in the data stream.
* **Parity Error Checking & Logging**:
  - Re-compute parity over the received data bytes and compare against the received parity byte bit 0.
  - Log parity errors in the **Runtime Link Testing Parity Log** registers:
    - Log 0 (Offset 34h)
    - Log 1 (Offset 3Ch)
    - Log 2 (Offset 44h)
    - Log 3 (Offset 4Ch)
  - Assert the error flag (`o_rx_error`) and notify the RX controller if error counts exceed the threshold specified in `i_error_threshold`.

### 4.2 Gated Receivers and Gating Controls
* **Receiver Lane Gating**:
  - Re-enable and implement the commented-out `case (i_lane_map)` in `receivers.sv`.
  - Disable and power down AFE receivers on unused lanes when operating in degraded width modes (e.g. power down lanes 4-7 or 0-3 in x4 mode; power down lanes 8-15 or 0-7 in x8 mode) to save static power.

### 4.3 Clock and Track Lane Repair
* Support Clock and Track lane remapping using the redundant clock/track lane `RRDCK_P` for both differential and pseudo-differential clock receiver implementation configurations (UCIe Spec §4.3.4).

### 4.4 Dynamic Clock Gating Postamble
* Support dynamic clock gating after sending a fixed postamble of 16 UI (8 cycles) for half-rate clocking or 32 UI (8 cycles) for quarter-rate clocking when `Valid` goes low, unless free-running clock mode is active.

### 4.5 Runtime Recalibration and Phase Tracking
* Implement continuous phase calibration and tracking (continuous RX Deskew) to track temperature/voltage drifts without interrupting active data transmission.
