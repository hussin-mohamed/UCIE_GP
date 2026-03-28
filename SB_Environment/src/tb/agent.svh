/***********************************************************************
 * Author : Amr El Batarny
 * File   : agent.svh
 * Brief  : Parameterized UVM agent class providing flexible, reusable
 *          agent infrastructure with configurable active/passive mode.
 * Note   : Documentation comments generated with AI assistance using
 *          the same format found in UVM source code.
 **********************************************************************/

//------------------------------------------------------------------------------
//
// CLASS: agent
//
// The agent class provides a highly parameterized UVM agent implementation
// that can be configured with different sequencers, drivers, and monitors.
// Supports both active and passive operation modes based on configuration.
//
// Type Parameters:
//   CFG_NAME - Configuration object name for config_db lookup
//   AGT_NAME - Default instance name for the agent
//   INTF_T   - Virtual interface type
//   SEQR_T   - Sequencer type
//   DRVR_T   - Driver type
//   MNTR_T   - Monitor type
//   ITEM_T   - Transaction item type
//
//------------------------------------------------------------------------------

class agent #(
    string CFG_NAME = "GENERIC_CFG_NAME",
    string AGT_NAME = "GENERIC_AGENT",
    type INTF_T,
    type SEQR_T,
    type DRVR_T,
    type MNTR_T,
    type ITEM_T
    ) extends uvm_agent;

    INTF_T                      bfm;
    SEQR_T                      seqr;
    DRVR_T                      drvr;
    MNTR_T                      mntr;
    agent_config      #(INTF_T) cfg;
    uvm_analysis_port #(ITEM_T) drvr_ap, mntr_ap;

    // This field determines whether an agent is active or passive.
    uvm_active_passive_enum is_active = UVM_ACTIVE;

    // Provide implementations of virtual methods such as get_type_name and create
    `uvm_component_param_utils_begin(agent #(CFG_NAME, AGT_NAME, INTF_T, SEQR_T, DRVR_T, MNTR_T, ITEM_T))
        `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_DEFAULT)
    `uvm_component_utils_end


    // Function: new
    //
    // Creates a new agent instance with the given name (defaults to AGT_NAME parameter).

    extern function new(string name = AGT_NAME, uvm_component parent = null);


    // Function: build_phase
    //
    // Retrieves agent configuration from config_db and creates monitor. If configured
    // as active agent, also creates driver and sequencer and their analysis ports.

    extern function void build_phase(uvm_phase phase);


    // Function: connect_phase
    //
    // Connects monitor to its interface and analysis port. For active agents,
    // connects driver to sequencer, assigns interface, and connects driver analysis port.

    extern function void connect_phase(uvm_phase phase);

endclass : agent


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- agent
//
//------------------------------------------------------------------------------


// new
// ---

function agent::new(string name = AGT_NAME, uvm_component parent = null);
    super.new(name, parent);
endfunction : new

// build_phase
// -----------

function void agent::build_phase(uvm_phase phase);
    super.build_phase(phase);

    if(!uvm_config_db#(agent_config #(INTF_T))::get(this, "", CFG_NAME, cfg))
        `uvm_fatal("build_phase", $sformatf("AGENT - Unable to get the agent configuration object from the uvm_config_db, CFG_NAME: %s, agent name: %s", CFG_NAME, this.get_full_name()))

    mntr = MNTR_T::type_id::create("mntr", this);

    if (cfg != null) is_active = cfg.is_active;

    if(is_active == UVM_ACTIVE) begin
        drvr = DRVR_T::type_id::create("drvr", this);
        seqr = SEQR_T::type_id::create("seqr", this);
        drvr_ap = new("drvr_ap", this);
    end

    mntr_ap = new("mntr_ap", this);
endfunction : build_phase

// connect_phase
// -------------

function void agent::connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    mntr.ap.connect(mntr_ap);
    mntr.bfm = cfg.bfm;

    if(is_active == UVM_ACTIVE) begin
        drvr.seq_item_port.connect(seqr.seq_item_export);
        drvr.bfm = cfg.bfm;
        drvr.ap.connect(drvr_ap);
    end
endfunction : connect_phase
