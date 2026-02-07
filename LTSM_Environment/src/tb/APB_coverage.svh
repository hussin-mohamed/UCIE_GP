/***********************************************************************
 * Author : Amr El Batarny
 * File   : APB_coverage.svh
 * Brief  : Functional coverage subscriber for APB transactions collecting
 *          coverage on operation types, addresses, and data values.
 * Note   : Documentation comments generated with AI assistance using
 *          the same format found in UVM source code.
 **********************************************************************/

//------------------------------------------------------------------------------
//
// CLASS: APB_coverage
//
// The APB_coverage class extends uvm_subscriber to collect functional coverage
// on APB transactions. It defines covergroups for transaction types, addresses,
// data values, and their cross-coverage combinations.
//
//------------------------------------------------------------------------------

class APB_coverage extends uvm_subscriber #(APB_sequence_item);
    `uvm_component_utils(APB_coverage)  
 
    covergroup APB_cg with function sample(APB_sequence_item item);
        type_cp: coverpoint item.kind{
            bins write = {1};
            bins read  = {0};
        }
        addr_cp: coverpoint item.addr{
            bins aligned_addr[] = {0, 4, 8, 12, 16, 20, 24, 28, 32, 36, 40, 44, 48, 52, 56, 60};
        }
        data_cp: coverpoint item.data{
            bins zero     = {32'h0};
            bins max      = {32'hFFFFFFFF};
            bins typical  = {[32'h1:32'hFFFFFFFE]};
        }
        write_x_data: cross type_cp, data_cp{
            ignore_bins read_nonzero = binsof(type_cp.read) && binsof(data_cp.typical); // Ensures read transactions have data=0 (as per the constraint)
        }
        write_x_addr: cross type_cp, addr_cp;
    endgroup : APB_cg


    // Function: new
    //
    // Creates a new APB_coverage instance and instantiates the covergroup.

    extern function new(string name = "APB_coverage", uvm_component parent = null);


    // Function: write
    //
    // Analysis port write method that samples the covergroup for each received
    // APB transaction.

    extern virtual function void write(APB_sequence_item t);

endclass : APB_coverage


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- APB_coverage
//
//------------------------------------------------------------------------------


// new
// ---

function APB_coverage::new(string name = "APB_coverage", uvm_component parent = null);
    super.new(name, parent);
    APB_cg = new();
endfunction : new

// write
// -----

function void APB_coverage::write(APB_sequence_item t);
    APB_cg.sample(t);
endfunction : write
