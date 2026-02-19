/***********************************************************************
 * Author : Amr El Batarny
 * File   : APB_controller_scoreboard.svh
 * Brief  : Controller scoreboard for verifying AES output data by
 *          collecting multiple APB read transactions and comparing
 *          the concatenated result.
 * Note   : Documentation comments generated with AI assistance using
 *          the same format found in UVM source code.
 **********************************************************************/

//------------------------------------------------------------------------------
//
// CLASS: APB_controller_scoreboard
//
// The APB_controller_scoreboard class extends scoreboard_base to verify AES
// controller output by collecting four sequential APB read transactions,
// concatenating their data fields, and comparing against the actual output.
// This scoreboard handles the multi-transaction nature of AES data transfer.
//
// Type Parameters:
//   ITEM_IN_T  - Input transaction type (APB read transactions)
//   ITEM_OUT_T - Output transaction type (AES output with concatenated data)
//
//------------------------------------------------------------------------------

class APB_controller_scoreboard #(type ITEM_IN_T, ITEM_OUT_T) extends scoreboard_base #(ITEM_IN_T, ITEM_OUT_T);
    `uvm_component_param_utils(APB_controller_scoreboard #(ITEM_IN_T, ITEM_OUT_T))

    // Expected data to be compared with transaction's data for read operations
    logic [N_AES-1:0] concat_actual, concat_expected;
    logic [DATA_WIDTH-1:0] data [4];
    int MSB, LSB;
    ITEM_IN_T item_in_arr [4];
    

    // Function: new
    //
    // Creates a new APB_controller_scoreboard instance and configures the comparer
    // settings for multi-word AES data comparison.

    extern function new(string name = "APB_controller_scoreboard", uvm_component parent = null);


    // Task: run_phase
    //
    // Continuously collects four APB read transactions in parallel with receiving
    // the AES output transaction, then generates reference and performs comparison.
    // Only READ transactions are collected from the input stream.

    extern virtual task run_phase(uvm_phase phase);


    // Function: get_reference_item
    //
    // Concatenates the data fields from four input transactions to create the
    // expected output transaction for AES data comparison.

    extern function void get_reference_item(input ITEM_IN_T _t_in_arr [4], output ITEM_OUT_T _t_out);

endclass : APB_controller_scoreboard


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- APB_controller_scoreboard
//
//------------------------------------------------------------------------------


// new
// ---

function APB_controller_scoreboard::new(string name = "APB_controller_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    
    // Configure comparer settings
    comparer = new();
    comparer.show_max = 10;            // Show maximum 10 mismatches
    comparer.verbosity = UVM_MEDIUM;   // Verbosity level for comparison messages
    comparer.sev = UVM_INFO;           // Severity for comparison messages (not errors)
    comparer.physical = 1;             // Enable physical comparison
    comparer.abstract = 1;             // Enable abstract comparison
    comparer.check_type = 1;           // Enable type checking
endfunction : new

// run_phase
// ---------

task APB_controller_scoreboard::run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    forever begin
        int i;
        
        fork
            begin // Input transactions thread
                while (i < 4) begin   
                    item_in_copy = ITEM_IN_T::type_id::create("item_in_copy");
                    fifo_in.get(item_in);
                    item_in_copy.copy(item_in);
                    if (item_in_copy.kind != READ) begin
                        continue;
                    end else begin
                        item_in_arr[i] = item_in_copy;
                        i++;
                    end
                end
            end

            begin // Output transactions thread
                fifo_out.get(item_out);
                concat_actual = item_out.data;
                item_out_copy = ITEM_OUT_T::type_id::create("item_out_copy");
                item_out_copy.copy(item_out);
            end
        join

        get_reference_item(item_in_arr, item_ref);

        compare();
    end
endtask : run_phase

// get_reference_item
// ------------------

function void APB_controller_scoreboard::get_reference_item(input ITEM_IN_T _t_in_arr [4], output ITEM_OUT_T _t_out);
    ITEM_OUT_T t_tmp;

    t_tmp = new();

    foreach (_t_in_arr[i]) begin
        data[i] = _t_in_arr[i].data;
    end

    t_tmp.data = {data[3], data[2], data[1], data[0]};

    _t_out = t_tmp;
endfunction : get_reference_item
