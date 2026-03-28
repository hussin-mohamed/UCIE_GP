class bridge_test extends bridge_test_base;
    `uvm_component_utils(bridge_test)

    function new(string name = "bridge_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        factory.set_type_override_by_type(bridge_base_sequence::get_type(), virtual_sequence::get_type());
        super.build_phase(phase);
    endfunction : build_phase
endclass : bridge_test