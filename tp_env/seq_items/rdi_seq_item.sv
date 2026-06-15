//=============================================================================
// File       : rdi_seq_item.sv
// Project    : UCIe 3.0 TX Logical PHY Verification
// Description: RDI sequence item representing a single flit transaction.
//              Data is modeled as a dynamic byte array sized by flit_size.
//=============================================================================

class rdi_seq_item extends uvm_sequence_item;

  // -------------------------------------------------------------------------
  //  Per-Run Flit Size (+FLIT_SIZE plusarg)
  // -------------------------------------------------------------------------

  static flit_size_e active_flit_size = FLIT_256;

  // Flit payload as dynamic byte array (sized to active_flit_size)
  rand logic [7:0] data [];

  // Inter-flit delay in clock cycles (gap before this flit)
  rand int unsigned delay;

  logic lp_valid;
  logic lp_irdy;
  logic pl_trdy;

  `ifdef UCIE_SYS_LVL
    // PL State Status: indicates current link/PHY state
    logic [3:0] pl_state_sts;
    bit reset_enb;  // Removed 'static' - each instance should have its own value
  `endif

  // -------------------------------------------------------------------------
  //  UVM Registration (no automation macros — manual do_* methods only)
  // -------------------------------------------------------------------------

  `uvm_object_utils(rdi_seq_item)

  // -------------------------------------------------------------------------
  //  Constraints
  // -------------------------------------------------------------------------

  // Data array size must match the per-run flit size
  constraint c_data_size {
    data.size() == active_flit_size;
  }

  // Reasonable inter-flit delay
  constraint c_delay {
    delay inside {[0:20]};
  }

  // -------------------------------------------------------------------------
  //  Constructor — parses +FLIT_SIZE plusarg
  // -------------------------------------------------------------------------

  function new(string name = "rdi_seq_item");
    string val;
    uvm_cmdline_processor clp;
    super.new(name);

    clp = uvm_cmdline_processor::get_inst();
    if (clp.get_arg_value("+FLIT_SIZE=", val)) begin
      case (val)
        "64":   active_flit_size = FLIT_64;
        "128":  active_flit_size = FLIT_128;
        "256":  active_flit_size = FLIT_256;
        "512":  active_flit_size = FLIT_512;
        default: `uvm_warning("RDI_SEQ_ITEM",
                   $sformatf("Invalid +FLIT_SIZE=%s, using default 256", val))
      endcase
      `uvm_info("RDI_SEQ_ITEM",
        $sformatf("Flit size set to %0s (%0d bytes)", active_flit_size.name(), active_flit_size),
        UVM_LOW)
    end
  endfunction

  // -------------------------------------------------------------------------
  //  Custom Methods
  // -------------------------------------------------------------------------

  // Human-readable string for debug
  function string convert2string();
    string s;
    s = $sformatf("RDI_SEQ_ITEM: flit_size=%0s, data_bytes=%0d, delay=%0d",
                  active_flit_size.name(), data.size(), delay);

    // Show first 8 bytes for brevity
    s = {s, ", data[0:7]={"};
    for (int i = 0; i < 8 && i < data.size(); i++) begin
      if (i > 0) s = {s, ","};
      s = {s, $sformatf("0x%02h", data[i])};
    end
    s = {s, "}"};
    return s;
  endfunction

  function void do_print(uvm_printer printer);
    super.do_print(printer);
    printer.print_string("summary", convert2string());
  endfunction

endclass : rdi_seq_item
