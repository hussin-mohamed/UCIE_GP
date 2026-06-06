//=============================================================================
// File       : sqr_pool.sv
// Project    : UCIe 3.0 TX Logical PHY Verification
// Description: Sequencer Container — singleton pool mapping string names
//              to sequencer handles (Cummings/Glasser DVCon pattern).
//              Replaces virtual sequencers with a hierarchically-independent
//              associative array lookup.
//
//              Usage:
//                Environment: sqr_pool::get_global_pool().add("rdi_sqr", h);
//                Sequence:    sqr = sqr_pool::get_global_pool().get("rdi_sqr");
//=============================================================================

class sqr_pool extends uvm_object;

  // Associative array: string name → sequencer handle
  protected uvm_sequencer_base pool [string];

  // Singleton instance
  static protected sqr_pool m_global_pool;

  `uvm_object_utils(sqr_pool)

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------

  function new(string name = "sqr_pool");
    super.new(name);
  endfunction

  // -------------------------------------------------------------------------
  //  Singleton Access
  // -------------------------------------------------------------------------

  static function sqr_pool get_global_pool();
    if (m_global_pool == null)
      m_global_pool = new("global_sqr_pool");
    return m_global_pool;
  endfunction

  // -------------------------------------------------------------------------
  //  Add — register a sequencer with a unique name
  // -------------------------------------------------------------------------

  function void add(string key, uvm_sequencer_base item);
    if (key == "") begin
      `uvm_fatal("SQR_POOL", "Cannot add sequencer with empty name")
    end
    if (pool.exists(key)) begin
      `uvm_fatal("SQR_POOL", $sformatf("Duplicate sequencer name: '%s'", key))
    end
    pool[key] = item;
    `uvm_info("SQR_POOL", $sformatf("Registered sequencer '%s'", key), UVM_MEDIUM)
  endfunction

  // -------------------------------------------------------------------------
  //  Get — retrieve a sequencer by name
  // -------------------------------------------------------------------------

  function uvm_sequencer_base get(string key);
    if (!pool.exists(key)) begin
      `uvm_fatal("SQR_POOL", $sformatf("No sequencer found for name: '%s'", key))
    end
    return pool[key];
  endfunction

  // -------------------------------------------------------------------------
  //  Exists — check if a name is registered
  // -------------------------------------------------------------------------

  function bit exists(string key);
    return pool.exists(key);
  endfunction

endclass : sqr_pool
