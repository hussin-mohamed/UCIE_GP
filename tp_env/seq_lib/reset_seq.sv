class reset_seq extends uvm_sequence #(rdi_seq_item);

  `uvm_object_utils(reset_seq)

  static int reset_counter;

  function new(string name = "reset_seq");
    super.new(name);
  endfunction

  task body();
    rdi_seq_item req;

    req = rdi_seq_item::type_id::create("req");
    start_item(req);
      req.reset_enb = 1;
    finish_item(req);

  endtask

endclass : reset_seq
