/***********************************************************************
 * Author : Amr El Batarny
 * File   : APB_reactive_sequence_2.svh
 * Brief  : Reactive APB sequence with UART path control, performing
 *          register writes then polling for request signal.
 * Note   : Documentation comments generated with AI assistance using
 *          the same format found in UVM source code.
 **********************************************************************/

//------------------------------------------------------------------------------
//
// CLASS: APB_reactive_sequence_2
//
// The APB_reactive_sequence_2 class implements a two-phase sequence with
// UART path control: first writing to all register file locations, then
// switching paths and polling for the request signal to indicate readiness.
//
//------------------------------------------------------------------------------

class APB_reactive_sequence_2 extends APB_sequence_base #(APB_sequence_item_2);
    `uvm_object_utils(APB_reactive_sequence_2)


    // Function: new
    //
    // Creates a new APB_reactive_sequence_2 instance with the given name.

    extern function new(string name = "APB_reactive_sequence_2");


    // Task: body
    //
    // Executes 16 write transactions with UART path control, then switches
    // to APB path while polling the request signal until ready.

    extern task body();

endclass : APB_reactive_sequence_2


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- APB_reactive_sequence_2
//
//------------------------------------------------------------------------------


// new
// ---

function APB_reactive_sequence_2::new(string name = "APB_reactive_sequence_2");
    super.new(name);
endfunction : new

// body
// ----

task APB_reactive_sequence_2::body();
    repeat(16) begin // Span all the register file writing with strobe = 4'b1111
        start_item(req);
        assert(req.randomize());
        req.strobe = 4'b1111;
        req.kind   = WRITE;
        req.regfile_path   = APB_BFM_TO_REGFILE_PATH;
        req.uart_path = AES_TO_UART_PATH;
        finish_item(req);
        get_response(rsp); // discard unneeded response to avoid response queue overflow errors
    end

    // Switch to the AES_TO_REGFILE_PATH path and poll for request == 0
    `uvm_info(get_type_name(), "Polling for request == 0...", UVM_MEDIUM)
    
    while (1) begin
        start_item(req);
        req.regfile_path = AES_TO_REGFILE_PATH;
        req.uart_path = APB_TO_UART_PATH;
        req.kind = NONE;
        finish_item(req);

        // Get response from driver
        get_response(rsp);

        `uvm_info(get_type_name(), $sformatf(
                  "Received response: request=%0d", rsp.request), UVM_DEBUG)

        // Check if request signal is 0
        if (rsp.request == 1) begin
            `uvm_info(get_type_name(), "Request is 0, exiting poll loop", UVM_LOW)
            break;
        end
    end
endtask : body