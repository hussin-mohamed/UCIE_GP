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

//-----------------------------------------------------------------------------
//
// CLASS: ltsm_seq_item
//
// Sideband LTSM sequence item containing transaction data exchanged between
// the TX and RX LTSM-side agents during ACTIVE-mode operation.
//-----------------------------------------------------------------------------

class ltsm_seq_item extends uvm_sequence_item;

  // Enum specifying the type of the current operation of the Sideband (SBINIT/ACTIVE)
  operation_t op_mode;

  // Randomizable fields
  rand logic [63:0] data;
  rand logic [15:0] info;
  rand msgtype_t    msgtype;
  rand int          wait_cycles;

  bit valid;

  // Protected fields to enforce safe assignment
  protected rand tx_encoding_t tx_encoding;
  protected rand rx_encoding_t rx_encoding;
  protected msg_dir_t          dir;

  // Randomized flags for making decision on constraining data and info to hit extreme values or not
  rand bit hit_extremes_data, hit_extremes_info;

  tx_encoding_t tx_encodings_supported[$];
  rx_encoding_t rx_encodings_supported[$];
  
  `uvm_object_utils_begin(ltsm_seq_item)
    `uvm_field_int(data,                        UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK)
    `uvm_field_int(info,                        UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK)
    `uvm_field_enum(msgtype_t, msgtype,         UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK)
    `uvm_field_int(valid,                       UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK)
    `uvm_field_enum(tx_encoding_t, tx_encoding, UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK)
    `uvm_field_enum(rx_encoding_t, rx_encoding, UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK)
    `uvm_field_enum(msg_dir_t, dir,             UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK)
    `uvm_field_int(wait_cycles,                 UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK | UVM_NOCOMPARE)
  `uvm_object_utils_end

  // Function: new
  //
  // Creates a new LTSM sequence item and initializes the supported encoding
  // lists from the shared message tables when needed.
  extern function new(string name = "");

  // Function: set_tx_encoding
  //
  // Selects a TX encoding and updates the item's direction bookkeeping.
  extern function void set_tx_encoding(tx_encoding_t _tx_enc, bit to_tx=0);

  // Function: set_rx_encoding
  //
  // Selects an RX encoding and updates the item's direction bookkeeping.
  extern function void set_rx_encoding(rx_encoding_t _rx_enc, bit to_rx=0);
  
  // Function: get_dir
  //
  // Returns the direction associated with the current item.
  extern function msg_dir_t     get_dir();

  // Function: get_tx_encoding
  //
  // Returns the stored TX encoding.
  extern function tx_encoding_t get_tx_encoding();

  // Function: get_rx_encoding
  //
  // Returns the stored RX encoding.
  extern function rx_encoding_t get_rx_encoding();

  // Function: do_print
  //
  // Extends the default UVM printout with raw values for invalid enums.
  extern virtual function void do_print(uvm_printer printer);

  // Function: set_dir
  //
  // Configures which encoding fields participate in randomization.
  extern function void set_dir(msg_dir_t _dir);

  // Function: post_randomize
  //
  // Finalizes the direction-specific encoding state after randomization.
  extern function void post_randomize();

  constraint ltsm_c {
    wait_cycles inside {[30:35]};
    
    if (get_opcode(tx_encoding, rx_encoding) == MSG_WO_DATA) {
      data == 0;
    } else {
      if (hit_extremes_data) {
        data dist {0:=3, DATA_MAX:=7};
      }
    }
    
    if (hit_extremes_info){
      info dist {0:=3, INFO_MAX:=7};
    }
  }

  constraint c_tx_encoding {
    tx_encoding inside {tx_encodings_supported};
    solve tx_encoding before data;
  }

  constraint c_rx_encoding {
    rx_encoding inside {rx_encodings_supported};
    solve rx_encoding before data;
  }

endclass : ltsm_seq_item

//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// CLASS: ltsm_seq_item
//
// Methods implementation for the LTSM sequence item.
//
//-----------------------------------------------------------------------------

// new
// ---
//
// Initializes the item and lazily populates the supported encoding lists.

function ltsm_seq_item::new(string name = "");
  super.new(name);
  op_mode = ACTIVE;
  if (tx_encodings_supported.size() == 0) begin
    tx_encodings_supported = tx_messages.find_index() with (1);
  end
  if (rx_encodings_supported.size() == 0) begin
    rx_encodings_supported = rx_messages.find_index() with (1);
  end
endfunction

function void ltsm_seq_item::set_tx_encoding(tx_encoding_t _tx_enc, bit to_tx=0);
  tx_encoding = _tx_enc;
  rx_encoding = NOP_RX;
  if (to_tx) begin
    dir = MSG_TO_TX;
  end else begin
    dir = MSG_FROM_TX;
  end
endfunction : set_tx_encoding

function void ltsm_seq_item::set_rx_encoding(rx_encoding_t _rx_enc, bit to_rx=0);
  rx_encoding = _rx_enc;
  tx_encoding = NOP_TX; 
  if (to_rx) begin
    dir = MSG_TO_RX;
  end else begin
    dir = MSG_FROM_RX;
  end
endfunction : set_rx_encoding

function msg_dir_t ltsm_seq_item::get_dir();
  return dir;
endfunction : get_dir

function tx_encoding_t ltsm_seq_item::get_tx_encoding();
  return tx_encoding;
endfunction : get_tx_encoding

function rx_encoding_t ltsm_seq_item::get_rx_encoding();
  return rx_encoding;
endfunction : get_rx_encoding

// do_print
// -------
//
// Prints registered fields and emits raw hex values for invalid enum states.

function void ltsm_seq_item::do_print(uvm_printer printer);
  // Call super to print all the fields registered with `uvm_field_*` macros
  super.do_print(printer);

  // If the enum's name is an empty string, it is an invalid/undefined value.
  // Use printer.print_field(name, value, size_in_bits, radix) to print the raw hex.
  if (msgtype.name() == "") begin
    printer.print_field("msgtype_RAW", msgtype, 2, UVM_HEX);
  end

  if (tx_encoding.name() == "") begin
    printer.print_field("tx_encoding_RAW", tx_encoding, 9, UVM_HEX);
  end

  if (rx_encoding.name() == "") begin
    printer.print_field("rx_encoding_RAW", rx_encoding, 9, UVM_HEX);
  end

  if (dir.name() == "") begin
    printer.print_field("dir_RAW", dir, 2, UVM_HEX);
  end
endfunction : do_print

// set_dir
// -------
//
// Enables the appropriate encoding constraint set for the requested direction.

function void ltsm_seq_item::set_dir(msg_dir_t _dir);
  dir = _dir; 

  if (_dir == MSG_FROM_TX) begin
    tx_encoding.rand_mode(1);
    c_tx_encoding.constraint_mode(1);
    
    rx_encoding.rand_mode(0);
    c_rx_encoding.constraint_mode(0);
    rx_encoding = NOP_RX;
  end else if (_dir == MSG_FROM_RX) begin
    rx_encoding.rand_mode(1);
    c_rx_encoding.constraint_mode(1);
    
    tx_encoding.rand_mode(0);
    c_tx_encoding.constraint_mode(0);
    tx_encoding = NOP_TX;
  end else begin
    `uvm_fatal(get_type_name(), $sformatf("Invalid direction: %s", dir.name()))
  end
endfunction : set_dir


// post_randomize
// --------------
//
// Reapplies the selected direction helper and derives the message type.

function void ltsm_seq_item::post_randomize();
  if (dir == MSG_FROM_TX) begin
    set_tx_encoding(tx_encoding);
  end else if (dir == MSG_FROM_RX) begin
    set_rx_encoding(rx_encoding);
  end

  msgtype = get_msgtype_by_encoding(tx_encoding, rx_encoding);
endfunction : post_randomize
