// ****************************************************************************
// *                                                                          *
// * Copyright (c) 2014-2015 Synopsys Inc. All rights reserved.               *
// *                                                                          *
// * Synopsys Proprietary and Confidential. This file contains confidential   *
// * information and the trade secrets of Synopsys Inc. Use, disclosure, or   *
// * reproduction is prohibited without the prior express written permission  *
// * of Synopsys, Inc.                                                        *
// *                                                                          *
// * Synopsys, Inc.                                                           *
// * 700 East Middlefield Road                                                *
// * Mountain View, California 94043                                          *
// * (800) 541-7737                                                           *
// *                                                                          *
// ****************************************************************************


`define RANDOMIZE_FLAG(FLAG, WEIGHT_1, WEIGHT_0) \
  if (!std::randomize(FLAG) with { \
    FLAG dist {1 := WEIGHT_1, 0 := WEIGHT_0}; \
  }) begin \
    `uvm_error(get_type_name(), $sformatf("Failed to randomize %s", `"FLAG`")) \
  end

`define RANDOMIZE_PARITY_ERRORS(VAR, FORCE_ODD, W1=20, W2=2, W3=1) \
  if (!std::randomize(VAR) with { \
    if (FORCE_ODD) { \
      $countones(VAR) % 2 != 0; \
      $countones(VAR) dist {1:=W1, 3:=W2, [5:$bits(VAR)]:/W3}; \
    } else { \
      $countones(VAR) dist {1:=W1, 2:=W2, [3:$bits(VAR)]:/W3}; \
    } \
  }) begin \
    `uvm_error(get_type_name(), $sformatf("Failed to randomize %s", `"VAR`")) \
  end

//-----------------------------------------------------------------------------
//
// CLASS: phylink_seq_item
//
// Sideband phylink sequence item containing the serialized-link transaction
// fields used by the phylink driver, monitor, and scoreboard paths.
//
//-----------------------------------------------------------------------------

class phylink_seq_item extends uvm_sequence_item;

  // Enum specifying the type of the current operation of the Sideband (SBINIT/ACTIVE)
  operation_t op_mode;

  // Randomizable fields
  logic [63:0]       pattern;           // SBINIT Pattern
  rand int           idle_ui_cnt;       // Low Gap Unit Intervals Count (Used for driving)
  rand int           out_of_rst_ui_cnt; // The delay between the SBINIT starting points of the local and remote dies
  rand int           wait_cycles;
  rand fullcode_t    fullcode;          // Concatenated {MsgCode, MsgSubcode} for Link Training State Machine commands
  opcode_t           opcode;            // Opcode
  srcid_t            srcid;             // Source ID
  dstid_t            dstid;             // Destination ID
  rand logic [15:0]  info;              // Message Information
  logic [63:0]       data;              // Message Data
  logic              cp;                // Control Parity
  logic              dp;                // Data Parity
  logic [8:0]        rsvd1;             // Reserved1: phase0 [13:5]
  logic [4:0]        rsvd2;             // Reserved2: phase0 [26:22]
  logic [1:0]        rsvd3;             // Reserved3: phase0 [28:27]
  logic [2:0]        rsvd4;             // Reserved4: phase1 [29:27]

  // Flag used for response items to inform the sequence that the pattern is detected
  bit out_pat_detected;
  bit in_pat_detected;
  bit timeout_detected;
  bit force_pattern_error;

  rand bit hit_extremes_info;

  `uvm_object_utils_begin(phylink_seq_item)
    `uvm_field_enum (operation_t, op_mode,  UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK)
    `uvm_field_int  (pattern,               UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK | UVM_NOCOMPARE)
    `uvm_field_int  (idle_ui_cnt,           UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK | UVM_NOCOMPARE)
    `uvm_field_int  (out_of_rst_ui_cnt,     UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK | UVM_NOCOMPARE)
    `uvm_field_int  (wait_cycles,           UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK | UVM_NOCOMPARE)
    `uvm_field_enum (fullcode_t,  fullcode, UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK)
    `uvm_field_enum (opcode_t,    opcode,   UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK)
    `uvm_field_enum (srcid_t,     srcid,    UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK)
    `uvm_field_enum (dstid_t,     dstid,    UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK)
    `uvm_field_int  (info,                  UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK)
    `uvm_field_int  (data,                  UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK)
    `uvm_field_int  (cp,                    UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK)
    `uvm_field_int  (dp,                    UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK)
    `uvm_field_int  (rsvd1,                 UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK)
    `uvm_field_int  (rsvd2,                 UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK)
    `uvm_field_int  (rsvd3,                 UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK)
    `uvm_field_int  (rsvd4,                 UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK)
  `uvm_object_utils_end

  // Function: new
  //
  // Creates a new phylink_seq_item instance with the given name.

  extern function new(string name = "");
  
  // Function: do_print
  //
  // Extends the default UVM printout with raw values for invalid enums.

  extern virtual function void do_print(uvm_printer printer);

  // Function: configure_randomization
  //
  // Enables the constraints and rand_mode settings appropriate for SBINIT or
  // ACTIVE operation.

  extern function void configure_randomization(
    operation_t _mode,
    bit         _is_first_iteration=0,
    bit         _force_pattern_error=0
  );

  // Function: post_randomize
  //
  // Finalizes the randomized fields, computes parity, and optionally injects
  // corruption used by negative testing.

  extern function void post_randomize();

  constraint c_idle_cnt {
    idle_ui_cnt inside {[32:200]};
  }

  constraint c_info {
    hit_extremes_info dist {1:=2, 0:=8};

    if (hit_extremes_info){
      info dist {'0:=4, '1:=6};
    }

    solve hit_extremes_info before info;
  }

  constraint c_out_of_rst {
    out_of_rst_ui_cnt inside {[500:2000]};
  }

endclass : phylink_seq_item

//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS: phylink_seq_item
//
//-----------------------------------------------------------------------------

// new
// ---

function phylink_seq_item::new(string name = "");
  super.new(name);
endfunction : new

// do_print
// -------

function void phylink_seq_item::do_print(uvm_printer printer);
  // Call super to print all the fields registered with `uvm_field_*` macros
  super.do_print(printer);

  // If the enum's name is an empty string, it is an invalid/undefined value.
  // Use printer.print_field(name, value, size_in_bits, radix) to print the raw hex.
  if (fullcode.name() == "") begin
    printer.print_field("fullcode_RAW", fullcode, 16, UVM_HEX);
  end

  if (opcode.name() == "") begin
    printer.print_field("opcode_RAW", opcode, 5, UVM_HEX);
  end
endfunction : do_print


// configure_randomization
// -----------------------

function void phylink_seq_item::configure_randomization(
  operation_t _mode,
  bit         _is_first_iteration=0,
  bit         _force_pattern_error=0
);
  op_mode = _mode;
  
  if (op_mode == SBINIT) begin
    fullcode.rand_mode(0);
    idle_ui_cnt.rand_mode(0); idle_ui_cnt = 32;
    c_idle_cnt.constraint_mode(0);
    info.rand_mode(0); info = '0;
    c_info.constraint_mode(0);

    if (_is_first_iteration) begin
      out_of_rst_ui_cnt.rand_mode(1);
      c_out_of_rst.constraint_mode(1);
    end else begin
      out_of_rst_ui_cnt.rand_mode(0); out_of_rst_ui_cnt = 0;
      c_out_of_rst.constraint_mode(0);
    end

    force_pattern_error = _force_pattern_error;
  end else begin // ACTIVE mode
    fullcode.rand_mode(1);
    idle_ui_cnt.rand_mode(1);
    c_idle_cnt.constraint_mode(1);
    info.rand_mode(1);
    c_info.constraint_mode(1);
    
    out_of_rst_ui_cnt.rand_mode(0); out_of_rst_ui_cnt = 0;
    c_out_of_rst.constraint_mode(0);
  end
endfunction : configure_randomization


// post_randomize
// --------------

function void phylink_seq_item::post_randomize();
  message_t  msg;
  bit        inject_pattern_error;
  bit        total_pattern_corruption;
  bit        inject_header_error;
  bit        inject_data_error;
  bit [18:0] rsvd;
  bit [63:0] data_error_inj_map;
  bit [63:0] pat_error_inj_map;
  bit        hit_extremes_data;

  if (op_mode == ACTIVE) begin // ACTIVE mode
    randcase
      90: // An existing message (could be supported or unsupported)
      begin
        if (!get_msg_by_fullcode(fullcode, msg)) begin // If the message is unsupported
          msg = unsupported_messages[fullcode]; // Get an unsupported message
        end
        opcode   = msg.opcode;
        srcid    = msg.srcid;
        dstid    = msg.dstid;
      end

      10: // Totally corrupted message
      begin
        fullcode = fullcode_t'($urandom());
        opcode   = opcode_t'($urandom());
        srcid    = srcid_t'($urandom());
        dstid    = dstid_t'($urandom());
      end
    endcase

    rsvd1 = '0;
    rsvd2 = '0;
    rsvd3 = '0;
    rsvd4 = '0;

    if (opcode == MSG_W_64B_DATA) begin
      // Exercise data-carrying messages with a bias toward extreme payloads.
      `RANDOMIZE_FLAG(hit_extremes_data, 2, 8)
      if (hit_extremes_data) begin
        if (!std::randomize(data) with {
          data dist {'0:=4, '1:=6};
        }) begin
          `uvm_error(get_type_name(), "Failed to randomize data")
        end
      end else begin
        if (!std::randomize(data)) begin
          `uvm_error(get_type_name(), "Failed to randomize data")
        end
      end
    end else begin
      data = 0;
    end

    // Calculate parity before injecting errors
    calculate_parity_by_item(this, cp, dp);

    // Reserved bits are used to inject header corruption without changing the
    // decoded message fields.
    `RANDOMIZE_FLAG(inject_header_error, 3, 7)
    if (inject_header_error) begin
      `RANDOMIZE_PARITY_ERRORS(rsvd, 1)
      rsvd1 = rsvd[18:10];
      rsvd2 = rsvd[9:5];
      rsvd3 = rsvd[4:3];
      rsvd4 = rsvd[2:0];
    end

    // Optional payload corruption is injected after parity has been computed.
    `RANDOMIZE_FLAG(inject_data_error, 3, 7)
    if (inject_data_error) begin
      `RANDOMIZE_PARITY_ERRORS(data_error_inj_map, 1)
      data = data ^ data_error_inj_map;
    end

  end else begin // SBINIT mode
    pattern = `SBINIT_PATTERN;

    // SBINIT intentionally varies the pattern bits to test detector robustness.
    `RANDOMIZE_FLAG(inject_pattern_error, 8, 2)
    if (inject_pattern_error || force_pattern_error) begin
      `RANDOMIZE_FLAG(total_pattern_corruption, 8, 2)
      if (total_pattern_corruption) begin
        if (!std::randomize(pattern) with {
          $countones(pattern) dist {5:=3, 10:=3, 10:=4};
        }) begin
          `uvm_error(get_type_name(), $sformatf("Failed to randomize pattern"))
        end
      end else begin
        `RANDOMIZE_PARITY_ERRORS(pat_error_inj_map, 0, 1, 4, 100)
        pattern = pattern ^ pat_error_inj_map;
      end
    end
  end
endfunction : post_randomize
