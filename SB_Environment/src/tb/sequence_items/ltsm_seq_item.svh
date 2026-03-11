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
// ...
//-----------------------------------------------------------------------------

class ltsm_seq_item extends uvm_sequence_item;

  // Randomizable fields
  rand logic [63:0] data;
  rand logic [15:0] info;
  rand msgtype_t    msgtype;
  rand int unsigned wait_cycles;

  bit valid;
  
  // Protected fields to enforce safe assignment
  protected tx_encoding_t tx_encoding;
  protected rx_encoding_t rx_encoding;
  protected msg_dir_t     dir;
  
  `uvm_object_utils_begin(ltsm_seq_item)
    `uvm_field_int(data,                        UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK)
    `uvm_field_int(info,                        UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK)
    `uvm_field_enum(msgtype_t, msgtype,         UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK)
    `uvm_field_int(valid,                       UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK)
    `uvm_field_enum(tx_encoding_t, tx_encoding, UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK)
    `uvm_field_enum(rx_encoding_t, rx_encoding, UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK)
    `uvm_field_enum(msg_dir_t, dir,             UVM_DEFAULT | UVM_NORECORD | UVM_NOPACK)
  `uvm_object_utils_end

  // Function: new
  extern function new(string name = "");

  // Setters
  extern function void set_tx_encoding(tx_encoding_t _tx_enc);
  extern function void set_rx_encoding(rx_encoding_t _rx_enc);
  
  // Getters
  extern function msg_dir_t     get_dir();
  extern function tx_encoding_t get_tx_encoding();
  extern function rx_encoding_t get_rx_encoding();

  constraint ltsm_c {
    wait_cycles inside {[1:10]};
  }

endclass : ltsm_seq_item

//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

function ltsm_seq_item::new(string name = "");
  super.new(name);
endfunction

function void ltsm_seq_item::set_tx_encoding(tx_encoding_t _tx_enc);
  tx_encoding = _tx_enc;
  rx_encoding = NOP_RX;
  dir         = MSG_FROM_TX;
endfunction : set_tx_encoding

function void ltsm_seq_item::set_rx_encoding(rx_encoding_t _rx_enc);
  rx_encoding = _rx_enc;
  tx_encoding = NOP_TX; 
  dir         = MSG_FROM_RX;
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
