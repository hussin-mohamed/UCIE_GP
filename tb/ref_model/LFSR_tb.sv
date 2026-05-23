// module LFSR_tb;

//     import LFSR_modelling_pkg::*;

//     //-------------------------------------------------------------------------
//     // Signal Declarations
//     //-------------------------------------------------------------------------
//     logic [DATA_WIDTH-1:0]      i_data_in;
//     logic                       i_enable;
//     logic                       i_load;
//     logic                       i_train;

//     logic [DATA_WIDTH-1:0]      o_data_out [0:LANES_NUMBER-1];


//     //-------------------------------------------------------------------------
//     // Drive Task
//     // Applies one stimulus vector and calls the golden model
//     //-------------------------------------------------------------------------
//     task automatic drive (
//         input logic [DATA_WIDTH-1:0]  data_in [0:LANES_NUMBER-1],
//         input logic                   enable,
//         input logic                   load,
//         input logic                   train
//     );
//         i_data_in = data_in;
//         i_enable  = enable;
//         i_load    = load;
//         i_train   = train;

//         // Call the golden model
//         LFSR_modelling(i_data_in, i_enable, i_load, i_train, o_data_out);
//     endtask

//     //-------------------------------------------------------------------------
//     // Check Task
//     // Compares o_data_out against an expected array, lane by lane
//     //-------------------------------------------------------------------------
//     task automatic check (
//         input logic [DATA_WIDTH-1:0]  expected [0:LANES_NUMBER-1],
//         input string                  test_name
//     );
//         int pass_count = 0;
//         int fail_count = 0;

//         foreach (o_data_out[i]) begin
//             if (o_data_out[i] !== expected[i]) begin
//                 $error("[FAIL] %s | Lane %02d | Expected: 0x%016h | Got: 0x%016h",
//                         test_name, i, expected[i], o_data_out[i]);
//                 fail_count++;
//             end else begin
//                 $display("[PASS] %s | Lane %02d | 0x%016h", test_name, i, o_data_out[i]);
//                 pass_count++;
//             end
//         end

//         $display("----------------------------------------");
//         $display("%s Summary: %0d PASSED | %0d FAILED", test_name, pass_count, fail_count);
//         $display("----------------------------------------");
//     endtask

//     //-------------------------------------------------------------------------
//     // Print Task
//     // Dumps current o_data_out without expected comparison (useful during
//     // sequence development when expected values aren't known yet)
//     //-------------------------------------------------------------------------
//     task automatic print_output (input string label);
//         $display("\n[%0t] %s", $time, label);
//         foreach (o_data_out[i]) begin
//             $display("  Lane %02d : 0x%016h", i, o_data_out[i]);
//         end
//     endtask

//     //-------------------------------------------------------------------------
//     // Main Test Block — plug your sequences in here
//     //-------------------------------------------------------------------------
//     initial begin
//         // Initialize all inputs
//         $display("\n========== LFSR Golden Model Testbench Start ==========\n");

//         #5;
//         drive(0, 1, 1, 0); // Load state with lane IDs
//         check('{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, "Load State");
//         #5;
//         drive(0, 1, 0, 1); // Load state with lane IDs
//         check('{ 
//         64'hCED8C6539894BD6C,
//         64'h56ACA14C914C57F0,
//         64'h32B42FEF91BC718C,
//         64'h64188EA300F0267C,
//         64'h2465ECACFC0F6D40,
//         64'h407D620FFCFF4B3C,
//         64'hD8090510F527A1A0,
//         64'h9874671F09D8EA9C,
//         64'hCED8C6539894BD6C,
//         64'h56ACA14C914C57F0,
//         64'h32B42FEF91BC718C,
//         64'h64188EA300F0267C,
//         64'h2465ECACFC0F6D40,
//         64'h407D620FFCFF4B3C,
//         64'hD8090510F527A1A0,
//         64'h9874671F09D8EA9C}, "Train Mode");

//         #5;
//         drive(0, 1, 0, 1); // Load state with lane IDs
//         check('{
//         64'h07C34F04C1756A50, 
//         64'h810C3E5D92434F02, 
//         64'h2615FC6D30FE0ED5, 
//         64'hA719C230A2BD41D7, 
//         64'hE89F62CD5586B8CC, 
//         64'h4F86A0FDF73BF91B, 
//         64'hC949D1A4A40DDC49, 
//         64'h86CF715953362552, 
//         64'h07C34F04C1756A50, 
//         64'h810C3E5D92434F02, 
//         64'h2615FC6D30FE0ED5, 
//         64'hA719C230A2BD41D7, 
//         64'hE89F62CD5586B8CC, 
//         64'h4F86A0FDF73BF91B, 
//         64'hC949D1A4A40DDC49, 
//         64'h86CF715953362552}, "Train Mode");

//         #5;
//         drive(0, 1, 1, 0); // Load state with lane IDs
//         check('{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, "Load State");
//         #5;

//         drive(64'hF0F0F0F0F0F0F0F0, 1, 0, 0); // Load state with lane IDs
//         check('{
//         64'h3E2836A368644D9C,
//         64'hA65C51BC61BCA700,
//         64'hC244DF1F614C817C,
//         64'h94E87E53F000D68C,
//         64'hD4951C5C0CFF9DB0,
//         64'hB08D92FF0C0FBBCC,
//         64'h28F9F5E005D75150,
//         64'h688497EFF9281A6C,
//         64'h3E2836A368644D9C,
//         64'hA65C51BC61BCA700,
//         64'hC244DF1F614C817C,
//         64'h94E87E53F000D68C,
//         64'hD4951C5C0CFF9DB0,
//         64'hB08D92FF0C0FBBCC,
//         64'h28F9F5E005D75150,
//         64'h688497EFF9281A6C
//         }, "Scramble Mode");

//         #5;
//         drive(64'hF0F0F0F0F0F0F0F0, 1, 0, 0); // Load state with lane IDs
//         check('{
//         64'hF733BFF431859AA0,
//         64'h71FCCEAD62B3BFF2,
//         64'hD6E50C9DC00EFE25,
//         64'h57E932C0524DB127,
//         64'h186F923DA576483C,
//         64'hBF76500D07CB09EB,
//         64'h39B9215454FD2CB9,
//         64'h763F81A9A3C6D5A2,
//         64'hF733BFF431859AA0,
//         64'h71FCCEAD62B3BFF2,
//         64'hD6E50C9DC00EFE25,
//         64'h57E932C0524DB127,
//         64'h186F923DA576483C,
//         64'hBF76500D07CB09EB,
//         64'h39B9215454FD2CB9,
//         64'h763F81A9A3C6D5A2
//         }, "Scramble Mode");
//         $finish;
//         $display("\n========== Testbench Complete ==========\n");
//         $finish;
//     end

// endmodule