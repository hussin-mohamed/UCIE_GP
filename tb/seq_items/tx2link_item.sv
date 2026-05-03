//=============================================================================
// File       : tx2link_item.sv
// Project    : UCIe 3.0 TX Logical PHY Verification
// Description: TX-to-Link transaction item representing an assembled chunk of
//              serial data sampled from the physical output lanes.
//
//              This item is NEVER randomized — it is constructed exclusively
//              by the egress monitor, which collects serial bits over a
//              state-dependent number of UI cycles and packs them into
//              dynamic arrays.
//
//              Each array index represents one sampled Unit Interval (UI).
//              The scoreboard uses `captured_state` metadata to determine
//              which arrays carry valid payloads and which should be checked
//              for silence (Hi-Z).
//=============================================================================

class tx2link_item extends uvm_sequence_item;

  // -------------------------------------------------------------------------
  //  Metadata (set by egress monitor)
  // -------------------------------------------------------------------------

  // The LTSM state that was active when this chunk was assembled
  ltsm_encoding_e captured_state;

  // Number of UIs (Unit Intervals) in this assembled chunk
  int unsigned ui_count;

  // -------------------------------------------------------------------------
  //  Physical Lane Payloads (Dynamic Arrays)
  //  Each index [i] holds the sampled value at UI cycle i.
  // -------------------------------------------------------------------------

  // 16 data lanes — data_lanes[ui][lane]
  logic [15:0] data_lanes [];

  // -------------------------------------------------------------------------
  //  UVM Registration (no automation macros — manual do_* methods only)
  // -------------------------------------------------------------------------

  `uvm_object_utils(tx2link_item)

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------

  function new(string name = "tx2link_item");
    super.new(name);
  endfunction

  // -------------------------------------------------------------------------
  //  Helper: Initialize arrays to a given chunk size
  // -------------------------------------------------------------------------

  function void init_arrays(int unsigned chunk_size);
    ui_count   = chunk_size;
    data_lanes = new[chunk_size];
  endfunction

  // -------------------------------------------------------------------------
  //  Custom Methods
  // -------------------------------------------------------------------------
  function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    tx2link_item rhs_;
    if (!$cast(rhs_, rhs)) return 0;

    do_compare = super.do_compare(rhs, comparer);
    do_compare &= (captured_state == rhs_.captured_state);
    do_compare &= (ui_count == rhs_.ui_count);

    // Compare data lane arrays element by element
    if (data_lanes.size() != rhs_.data_lanes.size()) return 0;
    foreach (data_lanes[i])
      do_compare &= (data_lanes[i] === rhs_.data_lanes[i]);  // === for Hi-Z compare

  endfunction

  function string convert2string();
    string s;
    s = $sformatf("TX2LINK_ITEM: state=%0s, ui_count=%0d",
                  captured_state.name(), ui_count);

    // Show first 4 UIs of data lanes for brevity
    if (data_lanes.size() > 0) begin
      s = {s, ", data[0:3]={"};
      for (int i = 0; i < 4 && i < data_lanes.size(); i++) begin
        if (i > 0) s = {s, ","};
        if (data_lanes[i] === 16'hzzzz)
          s = {s, "Z"};
        else
          s = {s, $sformatf("16'h%04h", data_lanes[i])};
      end
      s = {s, "}"};
    end
    return s;
  endfunction

  function void do_print(uvm_printer printer);
    super.do_print(printer);
    printer.print_string("summary", convert2string());
  endfunction

endclass : tx2link_item
