# UCIe Sideband Design Block Specification & Slide Notes

This document provides a highly detailed breakdown of the UCIe (Universal Chiplet Interconnect Express) Sideband block design. It is structured slide-by-slide to help you prepare presentation slides.

---

## Slide 1: Title Slide
* **Title:** Architecture and Design of the UCIe Sideband Controller
* **Subtitle:** CDC FIFO Schemes, Serial/Deserial Pipelines, Handshaking, and Packet Encoding/Decoding
* **Audience:** Graduation Project Review Board / Design Team
* **Key Content:**
  * Detailed walk-through of the UCIe Sideband Physical Layer implementation, detailing its Clock Domain Crossing (CDC) FIFO structures, serialization/deserialization logic, SBINIT handshake mechanism, toggle synchronizers, and message parity protection.

---

## Slide 2: Top-Level Block Diagram (`ucie_sb_top`)
* **Design Block:** `ucie_sb_top`
* **Inputs & Outputs:**
  * **System Clocks:** `i_clk` (fabric clock), `i_800MHz_clk` (high-speed line clock), `i_rx_sb_clk` (incoming source-synchronous clock).
  * **System Interface:** Request/Response handshakes (`i_tx_sb_req`, `i_tx_sb_rsp`, `o_sb_tx_req`, `o_sb_tx_rsp`), data and configuration buses.
  * **Physical Pins:** `o_tx_sb_clk`, `o_tx_sb_data` (outputs), `i_rx_sb_clk`, `i_rx_sb_data` (inputs).
* **Core Sub-modules:**
  * **TX Initialization Path (`ucie_sb_tx_path`)**: Generates clock/data patterns for startup training.
  * **RX Initialization Path (`ucie_sb_rx_path`)**: Detects clock/data patterns for lock detection.
  * **Sideband Transmitter Egress (`ucie_sideband_out`)**: Splits 128-bit messages, queues them, and serializes them.
  * **Sideband Receiver Egress (`ucie_sideband_in`)**: Deserializes streams, queues them, and merges them to 128-bit.
  * **Traffic Manager (`ucie_sb_traffic`)**: Dispatches and schedules messages.
  * **Message Formatters (`ucie_sideband_tx_msg`, `ucie_sideband_rx_msg`)**: Implements packet encoding/decoding.

---

## Slide 3: Clock Domain Crossing (FIFO Architecture)
* **Design Challenge:** The sideband logic runs on a slow system clock (`i_clk`), while the physical line interface runs on a high-speed `i_800MHz_clk` clock. Inbound serial data is captured on a separate, intermittent clock (`i_rx_sb_clk`).
* **FIFO Types Used:**
  1. **CDC-Safe Asynchronous FIFO (`ucie_sideband_fifo.sv`):**
     - Instantiated in both `ucie_sideband_out` and `ucie_sideband_in`.
     - **Mechanism:** Dual-clock design. Pointers are converted from binary to **Gray Code** (`bin_ptr_next ^ (bin_ptr_next >> 1)`) before passing across clock domains. 
     - **Why Gray Code?** Gray code changes only one bit at a time, preventing multi-bit transition glitching/metastability when passed through the two-stage synchronizer pipelines (`wr_ptr_gray_sync1/2` and `rd_ptr_gray_sync1/2`).
  2. **Synchronous FWFT FIFO (`ucie_sideband_fifo_FWFT.sv`):**
     - Instantiated in `ucie_sideband_tx_msg` and `ucie_sideband_rx_msg`.
     - **Mechanism:** Uses a single clock for reads and writes. Implements **First-Word Fall-Through (FWFT)** logic:
       $$\text{o\_data\_out} = \text{fifo\_mem}[\text{rd\_ptr}]$$
     - **Why FWFT?** Data falls through to the output port combinationaly, removing the 1-clock read latency of standard FIFOs. This simplifies packet parsing and downstream handshake sequencing.

---

## Slide 4: Sideband Traffic Manager (`ucie_sb_traffic`)
* **Role:** Central message scheduler and router.
* **FIFO Scheduling (Ping-Pong Round Robin):**
  - Evaluates queue status: `!i_tx_traffic_fifo_empty` and `!i_rx_traffic_fifo_empty`.
  - To prevent queue starvation, if both FIFOs are non-empty, it alternates reads using the `tx_rd_first` toggle flag:
    - Iteration 1: Reads from TX FIFO (`o_tx_traffic_fifo_rd_en = 1`, `tx_rd_first <= 1`).
    - Iteration 2: Reads from RX FIFO (`o_rx_traffic_fifo_rd_en = 1`, `tx_rd_first <= 0`).
* **Message Routing Logic:**
  - Evaluates message headers (`srcid` at bit 127:125, `dstid` at bit 90:88, `msg_code` at bit 117:110, `msg_subcode` at bit 71:64).
  - Routes response packets (e.g., matching code `4'hA`) to `o_traffic_tx_fifo`.
  - Routes request packets (e.g., matching code `4'h5`) to `o_traffic_rx_fifo`.
* **Flow Control:**
  - Asserts `o_stall_traffic = 1'b1` when target FIFOs are full, pausing upstream data generation.

---

## Slide 5: Parallel-to-Serial Output Path (`ucie_sideband_out`)
* **Sub-components:**
  * `ucie_sideband_traffic_fifo`: Splits 128-bit sideband messages into 64-bit segments.
    - Swaps high and low 32-bit segments during formatting to match serialization endianness:
      $$\text{o\_traffic\_ser\_fifo} = \{\text{i\_sb\_msg}[95:64], \text{i\_sb\_msg}[127:96]\}$$
    - Stalls traffic during split operations.
  * `ucie_sideband_ser` (Serializer):
    - **FSM States:** `ST_IDLE`, `ST_LOW`, `ST_TX`.
    - **Idle Gap Injection:** When transitioning from `ST_IDLE` or `ST_TX` to serialize a new packet, the FSM enters `ST_LOW` for 32 clock cycles. This forces a 32-UI clock-low period before data starts.
    - **Transmission:** Transitions to `ST_TX` for 64 clock cycles. Shifts `shift_reg` right each cycle and drives `shift_reg[0]` onto `o_tx_sb_data`.
    - **Clock Gating:** Generates `o_tx_sb_clk` using a lookahead clock-gating latch (`clk_en_ff`) active only during `ST_TX`.

---

## Slide 6: Serial-to-Parallel Input Path (`ucie_sideband_in`)
* **Sub-components:**
  * `ucie_sideband_deser` (Deserializer):
    - Captures serial data `i_rx_sb_data` on the **negedge** of the incoming clock `i_rx_sb_clk` to guarantee maximum timing setup/hold margins.
    - When 64 bits are shifted into `shift_reg`, it stores the word and toggles `data_rdy_toggle <= ~data_rdy_toggle`.
  * **CDC Write Pulse Generation:**
    - The `data_rdy_toggle` level transition is passed through a 3-stage synchronizer clocked by the local `i_800MHz_clk` domain.
    - An edge detector generates a single write pulse in the fast clock domain:
      $$\text{write\_pulse} = \text{sync2\_800mhz} \oplus \text{sync3\_800mhz}$$
    - Drives `o_fifo_wr_en = write\_pulse`, loading the deserialized word into the asynchronous CDC FIFO.
  * `ucie_sideband_fifo_traffic`: Reconstructs 128-bit messages. If the opcode is `5'b11011` (message with payload), it waits and combines two 64-bit segments. For `5'b10010` (no payload), it asserts ready after one segment.

---

## Slide 7: Toggle Synchronizer (`toggle_sync`) & Clock Synchronization
* **Role:** Safe cross-domain signaling of single-cycle pulses or toggling signals (like the 1ms timer pulse `i_timer_1ms` or handshakes `i_tx_sb_req`).
* **Design:**
  - Implements a 3-flop pipeline clocked by the target domain:
    ```systemverilog
    sync1 <= i_cnt;
    sync2 <= sync1;
    sync3 <= sync2;
    ```
  - **Edge Detection Logic:**
    $$\text{o\_cnt} = (\text{sync2} \oplus \text{sync3}) \land \text{sync1}$$
  - **Why?** Since pulses are too short to be captured directly by a slower clock domain, they are converted to toggling signals at the source and then reconstructed back into a single-cycle pulse at the target domain using edge detection, avoiding metastability.

---

## Slide 8: Sideband Initialization (SBINIT) Handshake
* **Purpose:** Power-up training sequence to align physical receiver clocks before message traffic begins.
* **Transmitter initialization FSM (`ucie_sb_tx_path`):**
  - **States:** `IDLE` $\rightarrow$ `CYCLING` $\rightarrow$ `EXTRA_ITERS` $\rightarrow$ `DONE`.
  - **Alternation:** Alternates 1ms ON and 1ms OFF periods.
  - **Pattern:** During the 1ms ON period, it sends a 96-UI pattern:
    - 64 UI of alternating clock-like sequence on clock and data.
    - 32 UI of low period.
* **Receiver lock logic (`ucie_sb_rx_path`):**
  - Monitors `i_rx_sb_data` transitions on the negedge of `i_rx_sb_clk`.
  - If it detects 128 consecutive alternating bits (meaning two complete 64-bit training bursts) without failure, it declares lock and asserts `o_done = 1`.
* **Lock Finalization:**
  - When the transmitter receives `i_rx_done = 1`, it completes the current 96-UI iteration and runs exactly 4 extra training iterations (`EXTRA_ITERS`) to ensure receiver stability before asserting `o_stop` (setting `o_sb_ready = 1`).

---

## Slide 9: Packet Field Encodings & Parity Protection
* **Message Width:** 128 bits.
* **Packet Fields:**
  - `srcid` [127:125] (Source ID)
  - `dstid` [90:88] (Destination ID)
  - `msg_code` [117:110] (High-level Command Code)
  - `msg_subcode` [71:64] (Command Sub-code)
  - `op_code` [100:96] (Operation Code: `5'b11011` with payload, `5'b10010` no payload)
  - `info_in` [87:72] (Info field)
  - `data_in` [63:0] (Data payload)
* **Parity Bit Generation & Verification:**
  - **Control Parity (`dec_cp` at bit 94):** XOR parity over control headers:
    $$\text{dec\_cp} = \bigoplus (\text{msg\_in}[127:96], \text{msg\_in}[93:64])$$
  - **Data Parity (`dec\_dp` at bit 95):** XOR parity over data payload:
    $$\text{dec\_dp} = \bigoplus \text{msg\_in}[63:0]$$
  - Parity is computed combinationaly on the RX side. If a mismatch is detected, the message is declared invalid (`dec_valid = 0`), preventing corrupt commands from triggering state machine actions.
