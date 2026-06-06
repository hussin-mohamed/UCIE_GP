import shared_ltsm_pkg::*;

class ltsm_mbinit_param_check_rx extends uvm_sequence #(rx_fsm_sb_sequence_item);

  `uvm_object_utils(ltsm_mbinit_param_check_rx)

  function new(string name = "ltsm_mbinit_param_check_rx");
    super.new(name);
  endfunction

  virtual task body();
    rx_fsm_sb_sequence_item tr;
    tr = rx_fsm_sb_sequence_item::type_id::create("tr");
    start_item(tr);
        tr.i_sb_rx_done = 1;
        tr.i_rx_decoding = 9'h11;
    finish_item(tr);
  endtask

endclass
