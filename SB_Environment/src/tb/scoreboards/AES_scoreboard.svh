/***********************************************************************
 * Author : Amr El Batarny
 * File   : AES_scoreboard.svh
 * Brief  : AES scoreboard using DPI-C interface for reference model
 *          comparison of AES encryption operations.
 * Note   : Documentation comments generated with AI assistance using
 *          the same format found in UVM source code.
 **********************************************************************/

// DPI import declaration for the AES encryption C model
import "DPI-C" function void aes_encrypt(
    input byte input_data[16],
    input byte key[16],
    output byte output_data[16],
    input int N,
    input int Nr,
    input int Nk
);

//------------------------------------------------------------------------------
//
// CLASS: AES_scoreboard
//
// The AES_scoreboard class extends scoreboard_base to verify AES encryption
// operations by comparing DUT output against a reference model implemented
// via DPI-C interface. It handles data format conversion between 128-bit
// vectors and byte arrays for the reference model interface.
//
//------------------------------------------------------------------------------

class AES_scoreboard extends scoreboard_base #(APB_controller_sequence_item, AES_sequence_item);
    `uvm_component_utils(AES_scoreboard)

    // Function: new
    //
    // Creates a new AES_scoreboard instance and configures the comparer
    // settings for multi-word AES data comparison.

    extern function new(string name = "AES_scoreboard", uvm_component parent = null);


    // Task: run_phase
    //
    // Collects input and output transactions in parallel, generates reference
    // encryption result via DPI-C call, and performs comparison.

    extern virtual task run_phase(uvm_phase phase);


    // Function: get_reference_item
    //
    // Generates expected AES output by calling the DPI-C reference model with
    // input data and fixed key, performing necessary data format conversions.

    extern function void get_reference_item(input APB_controller_sequence_item _t_in, output AES_sequence_item _t_out);


    // Function: vector2grid
    //
    // Converts a 128-bit vector into a byte array format required by the
    // DPI-C AES reference model interface.

    extern function void vector2grid(input logic [127:0] _in_vector, output byte _out_grid[16]);


    // Function: grid2vector
    //
    // Converts a byte array from the DPI-C AES reference model back into
    // a 128-bit vector format for comparison.

    extern function logic [127:0] grid2vector(input byte _g[16]);

endclass : AES_scoreboard


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- AES_scoreboard
//
//------------------------------------------------------------------------------


// new
// ---

function AES_scoreboard::new(string name = "AES_scoreboard", uvm_component parent = null);
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

task AES_scoreboard::run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    forever begin
        int i;
        
        fork
            begin // Input transactions thread
                item_in_copy = APB_controller_sequence_item::type_id::create("item_in_copy");
                fifo_in.get(item_in);
                item_in_copy.copy(item_in);
            end

            begin // Output transactions thread
                item_out_copy = AES_sequence_item::type_id::create("item_out_copy");
                fifo_out.get(item_out);
                item_out_copy.copy(item_out);
            end
        join

        get_reference_item(item_in_copy, item_ref);

        compare();
    end
endtask : run_phase

// get_reference_item
// ------------------

function void AES_scoreboard::get_reference_item(input APB_controller_sequence_item _t_in, output AES_sequence_item _t_out);
    AES_sequence_item t_tmp;
    byte plaintext[16];
    byte key[16];
    byte ciphertext[16];
    logic [127:0] ciphertext_vector;
    int N = 128;
    int Nr = 10;
    int Nk = 4;

    t_tmp = new();
    t_tmp.data_in = _t_in.data;

    vector2grid(KEY_AES, key);
    vector2grid(_t_in.data, plaintext);
    aes_encrypt(plaintext, key, ciphertext, N, Nr, Nk);
    ciphertext_vector = grid2vector(ciphertext);

    t_tmp.data_out = ciphertext_vector;

    _t_out = t_tmp;
endfunction : get_reference_item

// vector2grid
// -----------

function void AES_scoreboard::vector2grid(
    input  logic [127:0] _in_vector,
    output byte _out_grid[16]
);

    for (int i = 0; i < 16; i++) begin
        _out_grid[i] = _in_vector[127:120];
        _in_vector = {_in_vector[119:0], 8'h00};
    end
    
endfunction : vector2grid


// grid2vector
// -----------

function logic [127:0] AES_scoreboard::grid2vector(input byte _g[16]);
    return {_g[0], _g[1], _g[2], _g[3], _g[4], _g[5], _g[6], _g[7],
            _g[8], _g[9], _g[10], _g[11], _g[12], _g[13], _g[14], _g[15]};
endfunction : grid2vector
