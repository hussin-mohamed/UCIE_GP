/***********************************************************************
 * Author : Amr El Batarny
 * File   : APB_scoreboard.sv
 * Brief  : APB-specific scoreboard implementation with register model
 *          for tracking write operations and comparing read results.
 * Note   : Documentation comments generated with AI assistance
 **********************************************************************/

//------------------------------------------------------------------------------
//
// CLASS: APB_scoreboard
//
// The APB_scoreboard class extends scoreboard_base to provide APB protocol-
// specific transaction checking. It maintains an internal register model that
// tracks write operations and generates expected values for read comparisons.
// Supports byte-level write strobes and automatic register dump on mismatch.
//
// Type Parameters:
//   ITEM_IN_T  - Input transaction type (typically APB write transactions)
//   ITEM_OUT_T - Output transaction type (typically APB read transactions)
//
//------------------------------------------------------------------------------

class APB_scoreboard #(type ITEM_IN_T, ITEM_OUT_T) extends scoreboard_base #(ITEM_IN_T, ITEM_OUT_T);
    `uvm_component_param_utils(APB_scoreboard #(ITEM_IN_T, ITEM_OUT_T))

    // Expected data to be compared with transaction's data for read operations
    logic [DATA_WIDTH-1:0] data_expected;
    bit   [DATA_WIDTH-1:0] addr_expected;

    // Registers
    logic [DATA_WIDTH-1:0] SYS_STATUS_REG;
    logic [DATA_WIDTH-1:0] INT_CTRL_REG;
    logic [DATA_WIDTH-1:0] DEV_ID_REG;
    logic [DATA_WIDTH-1:0] MEM_CTRL_REG;
    logic [DATA_WIDTH-1:0] TEMP_SENSOR_REG;
    logic [DATA_WIDTH-1:0] ADC_CTRL_REG;
    logic [DATA_WIDTH-1:0] DBG_CTRL_REG;
    logic [DATA_WIDTH-1:0] GPIO_DATA_REG;
    logic [DATA_WIDTH-1:0] DAC_OUTPUT_REG;
    logic [DATA_WIDTH-1:0] VOLTAGE_CTRL_REG;
    logic [DATA_WIDTH-1:0] CLK_CONFIG_REG;
    logic [DATA_WIDTH-1:0] TIMER_COUNT_REG;
    logic [DATA_WIDTH-1:0] INPUT_DATA_REG;
    logic [DATA_WIDTH-1:0] OUTPUT_DATA_REG;
    logic [DATA_WIDTH-1:0] DMA_CTRL_REG;
    logic [DATA_WIDTH-1:0] SYS_CTRL_REG;


    // Function: new
    //
    // Creates a new APB_scoreboard instance and configures the comparer settings
    // for transaction comparison with appropriate verbosity and display options.

    extern function new(string name = "APB_scoreboard", uvm_component parent = null);


    // Task: run_phase
    //
    // Spawns parallel threads to process input and output transactions. The input
    // thread updates the register model on write operations, while the output thread
    // generates reference items and performs comparisons for read operations.

    extern virtual task run_phase(uvm_phase phase);


    // Function: get_reference_item
    //
    // Generates the expected output transaction by reading from the internal register
    // model at the current expected address and auto-incrementing the address by 4.

    extern function void get_reference_item(input ITEM_IN_T _t_in, output ITEM_OUT_T _t_out);


    // Function: compare
    //
    // Performs transaction comparison using the base class compare method and triggers
    // a register dump if a mismatch is detected for debugging purposes.

    extern virtual function void compare();


    // Function: get_mask
    //
    // Converts the byte strobe signal into a bit-level mask for selective register
    // field updates during write operations.

    extern function logic [DATA_WIDTH-1:0] get_mask(input logic [NBYTES-1:0] strobe);


    // Function: write_reg
    //
    // Updates the internal register model at the specified address using the provided
    // data and byte strobe mask for selective byte-level writes.

    extern function void write_reg(input logic [ADDR_WIDTH-1:0] addr, input logic [DATA_WIDTH-1:0] data, input logic [NBYTES-1:0] strobe);


    // Function: read_reg
    //
    // Returns the current value stored in the internal register model at the
    // specified address for generating expected read data.

    extern function logic [DATA_WIDTH-1:0] read_reg(input logic [ADDR_WIDTH-1:0] addr);


    // Function: print_registers
    //
    // Displays a formatted dump of all registers with their addresses and current
    // values for debugging and analysis.

    extern function void print_registers();

endclass : APB_scoreboard


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// CLASS- APB_scoreboard
//
//------------------------------------------------------------------------------


// new
// ---

function APB_scoreboard::new(string name = "APB_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    
    // Configure comparer settings
    comparer = new();
    comparer.show_max = 10;                    // Show maximum 10 mismatches
    comparer.verbosity = UVM_MEDIUM;           // Verbosity level for comparison messages
    comparer.sev = UVM_INFO;                   // Severity for comparison messages (not errors)
    comparer.physical = 1;                     // Enable physical comparison
    comparer.abstract = 1;                     // Enable abstract comparison
    comparer.check_type = 1;                   // Enable type checking
endfunction : new

// run_phase
// ---------

task APB_scoreboard::run_phase(uvm_phase phase);
    super.run_phase(phase);

    fork
        begin // Input transactions thread
            forever begin
                item_in_copy = ITEM_IN_T::type_id::create("item_in_copy");
                fifo_in.get(item_in);
                item_in_copy.copy(item_in);
                if (item_in_copy.kind == WRITE) begin // Write Operation
                    write_reg(item_in_copy.addr, item_in_copy.data, item_in_copy.strobe);
                end
            end
        end

        begin // Output transactions thread
            repeat (61) begin
                item_out_copy = ITEM_OUT_T::type_id::create("item_out_copy");
                fifo_out.get(item_out);
                item_out_copy.copy(item_out);
                if (item_out_copy.kind == READ) begin // Read Operation

                    get_reference_item(item_out_copy, item_ref);

                    compare();
                end 
            end
        end         
    join   

endtask : run_phase

// get_reference_item
// ------------------

function void APB_scoreboard::get_reference_item(input ITEM_IN_T _t_in, output ITEM_OUT_T _t_out);
    ITEM_OUT_T t_tmp;

    t_tmp = new();

    t_tmp.kind   = READ;
    t_tmp.strobe = 0;
    t_tmp.addr   = addr_expected;
    t_tmp.data   = read_reg(addr_expected);

    addr_expected+=4;

    _t_out = t_tmp;
endfunction : get_reference_item

// compare
// -------

function void APB_scoreboard::compare();
    super.compare();

    if (!match) begin
        print_registers();
    end     
endfunction : compare

// get_mask
// --------

function logic [DATA_WIDTH-1:0] APB_scoreboard::get_mask(input logic [NBYTES-1:0] strobe);
    logic [DATA_WIDTH-1:0] mask;
    for (int i = NBYTES-1; i >= 0; i--) begin
        for (int j = 0; j < 8; j++) begin
            mask[DATA_WIDTH-1-((NBYTES-1-i)*8)-j] = strobe[i];
        end
    end
    return mask;
endfunction : get_mask

// write_reg
// ---------

function void APB_scoreboard::write_reg(input logic [ADDR_WIDTH-1:0] addr, input logic [DATA_WIDTH-1:0] data, input logic [NBYTES-1:0] strobe);
    logic [DATA_WIDTH-1:0] mask;

    mask = get_mask(strobe);

    case (addr)
        32'h0000_0000: SYS_STATUS_REG   = (SYS_STATUS_REG       &   ~mask) | (data & mask);
        32'h0000_0004: INT_CTRL_REG     = (INT_CTRL_REG         &   ~mask) | (data & mask);
        32'h0000_0008: DEV_ID_REG       = (DEV_ID_REG           &   ~mask) | (data & mask);
        32'h0000_000c: MEM_CTRL_REG     = (MEM_CTRL_REG         &   ~mask) | (data & mask);
        32'h0000_0010: TEMP_SENSOR_REG  = (TEMP_SENSOR_REG      &   ~mask) | (data & mask);
        32'h0000_0014: ADC_CTRL_REG     = (ADC_CTRL_REG         &   ~mask) | (data & mask);
        32'h0000_0018: DBG_CTRL_REG     = (DBG_CTRL_REG         &   ~mask) | (data & mask);
        32'h0000_001c: GPIO_DATA_REG    = (GPIO_DATA_REG        &   ~mask) | (data & mask);
        32'h0000_0020: DAC_OUTPUT_REG   = (DAC_OUTPUT_REG       &   ~mask) | (data & mask);
        32'h0000_0024: VOLTAGE_CTRL_REG = (VOLTAGE_CTRL_REG     &   ~mask) | (data & mask);
        32'h0000_0028: CLK_CONFIG_REG   = (CLK_CONFIG_REG       &   ~mask) | (data & mask);
        32'h0000_002c: TIMER_COUNT_REG  = (TIMER_COUNT_REG      &   ~mask) | (data & mask);
        32'h0000_0030: INPUT_DATA_REG   = (INPUT_DATA_REG       &   ~mask) | (data & mask);
        32'h0000_0034: OUTPUT_DATA_REG  = (OUTPUT_DATA_REG      &   ~mask) | (data & mask);
        32'h0000_0038: DMA_CTRL_REG     = (DMA_CTRL_REG         &   ~mask) | (data & mask);
        32'h0000_003c: SYS_CTRL_REG     = (SYS_CTRL_REG         &   ~mask) | (data & mask);
    endcase
endfunction : write_reg

// read_reg
// --------

function logic [DATA_WIDTH-1:0] APB_scoreboard::read_reg(input logic [ADDR_WIDTH-1:0] addr);
    case (addr)
        32'h0000_0000: return SYS_STATUS_REG;
        32'h0000_0004: return INT_CTRL_REG;
        32'h0000_0008: return DEV_ID_REG;
        32'h0000_000c: return MEM_CTRL_REG;
        32'h0000_0010: return TEMP_SENSOR_REG;
        32'h0000_0014: return ADC_CTRL_REG;
        32'h0000_0018: return DBG_CTRL_REG;
        32'h0000_001c: return GPIO_DATA_REG;
        32'h0000_0020: return DAC_OUTPUT_REG;
        32'h0000_0024: return VOLTAGE_CTRL_REG;
        32'h0000_0028: return CLK_CONFIG_REG;
        32'h0000_002c: return TIMER_COUNT_REG;
        32'h0000_0030: return INPUT_DATA_REG;
        32'h0000_0034: return OUTPUT_DATA_REG;
        32'h0000_0038: return DMA_CTRL_REG;
        32'h0000_003c: return SYS_CTRL_REG;
    endcase
endfunction : read_reg

// print_registers
// ---------------

function void APB_scoreboard::print_registers();
    string reg_info;
    
    // Header
    reg_info = {"\n",
                "================================================================================\n",
                "                           REGISTER DUMP                                        \n",
                "================================================================================\n",
                " Register Name          | Address    | Value                                   \n",
                "--------------------------------------------------------------------------------\n"};
    
    // Print each register with its address and value
    reg_info = {reg_info, $sformatf(" SYS_STATUS_REG         | 0x%08h | 0x%08h\n", 32'h0000_0000, SYS_STATUS_REG)};
    reg_info = {reg_info, $sformatf(" INT_CTRL_REG           | 0x%08h | 0x%08h\n", 32'h0000_0004, INT_CTRL_REG)};
    reg_info = {reg_info, $sformatf(" DEV_ID_REG             | 0x%08h | 0x%08h\n", 32'h0000_0008, DEV_ID_REG)};
    reg_info = {reg_info, $sformatf(" MEM_CTRL_REG           | 0x%08h | 0x%08h\n", 32'h0000_000c, MEM_CTRL_REG)};
    reg_info = {reg_info, $sformatf(" TEMP_SENSOR_REG        | 0x%08h | 0x%08h\n", 32'h0000_0010, TEMP_SENSOR_REG)};
    reg_info = {reg_info, $sformatf(" ADC_CTRL_REG           | 0x%08h | 0x%08h\n", 32'h0000_0014, ADC_CTRL_REG)};
    reg_info = {reg_info, $sformatf(" DBG_CTRL_REG           | 0x%08h | 0x%08h\n", 32'h0000_0018, DBG_CTRL_REG)};
    reg_info = {reg_info, $sformatf(" GPIO_DATA_REG          | 0x%08h | 0x%08h\n", 32'h0000_001c, GPIO_DATA_REG)};
    reg_info = {reg_info, $sformatf(" DAC_OUTPUT_REG         | 0x%08h | 0x%08h\n", 32'h0000_0020, DAC_OUTPUT_REG)};
    reg_info = {reg_info, $sformatf(" VOLTAGE_CTRL_REG       | 0x%08h | 0x%08h\n", 32'h0000_0024, VOLTAGE_CTRL_REG)};
    reg_info = {reg_info, $sformatf(" CLK_CONFIG_REG         | 0x%08h | 0x%08h\n", 32'h0000_0028, CLK_CONFIG_REG)};
    reg_info = {reg_info, $sformatf(" TIMER_COUNT_REG        | 0x%08h | 0x%08h\n", 32'h0000_002c, TIMER_COUNT_REG)};
    reg_info = {reg_info, $sformatf(" INPUT_DATA_REG         | 0x%08h | 0x%08h\n", 32'h0000_0030, INPUT_DATA_REG)};
    reg_info = {reg_info, $sformatf(" OUTPUT_DATA_REG        | 0x%08h | 0x%08h\n", 32'h0000_0034, OUTPUT_DATA_REG)};
    reg_info = {reg_info, $sformatf(" DMA_CTRL_REG           | 0x%08h | 0x%08h\n", 32'h0000_0038, DMA_CTRL_REG)};
    reg_info = {reg_info, $sformatf(" SYS_CTRL_REG           | 0x%08h | 0x%08h\n", 32'h0000_003c, SYS_CTRL_REG)};
    
    // Footer
    reg_info = {reg_info, "================================================================================\n"};
    
    // Print using uvm_info
    `uvm_info("REG_DUMP", reg_info, UVM_LOW)
endfunction : print_registers
