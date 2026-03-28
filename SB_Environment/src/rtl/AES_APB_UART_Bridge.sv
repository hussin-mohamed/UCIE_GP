/***********************************************************************
 * Author : Amr El Batarny
 * File   : AES_APB_UART_Bridge.sv
 * Brief  : APB-to-UART bridge with AES encryption.
 **********************************************************************/

module AES_APB_UART_Bridge #(
    //----------------- Parameter Definitions -----------------
    parameter DATA_WIDTH    = 32,
    parameter ADDR_WIDTH    = 32,
    parameter NBYTES        = DATA_WIDTH/8,
    parameter N_AES         = 128,
    parameter Nr_AES        = 10,
    parameter Nk_AES        = 4,
    parameter KEY_AES       = 128'h2b7e151628aed2a6abf7158809cf4f3c,
    parameter AES_LATENCY   = 5,
    parameter FIFO_DEPTH    = 20,
    parameter NTICKS        = 16
    )(
    //--------------------- Clock & Reset ---------------------
    input   logic                   PCLK,
    input   logic                   PRESETn,

    //--------------------- MUX Selectors ---------------------
    input   logic                   sel_1, sel_2, sel_3,

    //--------- Starting Address for Writing Operation --------
    input   logic [ADDR_WIDTH-1:0]  start_addr_1,   start_addr_2,
    
    //-------------------- APB Slave Ports --------------------
    input   logic                   PSELx_1,    PSELx_2,
    input   logic [ADDR_WIDTH-1:0]  PADDR_1,    PADDR_2,
    input   logic                   PWRITE_1,   PWRITE_2,
    input   logic [NBYTES-1:0]      PSTRB_1,    PSTRB_2,
    input   logic [DATA_WIDTH-1:0]  PWDATA_1,   PWDATA_2,
    input   logic                   PENABLE_1,  PENABLE_2,
    output  logic [DATA_WIDTH-1:0]  PRDATA_1,   PRDATA_2,
    output  logic                   PREADY_1,   PREADY_2,

    //--------------------- UART Output -----------------------
    output  logic                   tx,         req
    );

    //---------------------------------------------------------
    //------------- Localparam Widths and Indeces -------------
    //---------------------------------------------------------
    localparam MUX1_WIDTH   = ADDR_WIDTH + DATA_WIDTH + NBYTES + 3;
    localparam MUX2_WIDTH   = N_AES + 1;
    localparam PSELX_BIT    = MUX1_WIDTH - 1;
    localparam PADDR_MSB    = PSELX_BIT - 1;
    localparam PADDR_LSB    = PADDR_MSB - (ADDR_WIDTH - 1);
    localparam PWDATA_MSB   = PADDR_LSB - 1;
    localparam PWDATA_LSB   = PWDATA_MSB - (DATA_WIDTH - 1);
    localparam PWRITE_BIT   = PWDATA_LSB - 1;
    localparam PSTRB_MSB    = PWRITE_BIT - 1;
    localparam PSTRB_LSB    = PSTRB_MSB - (NBYTES - 1);
    localparam PENABLE_BIT  = PSTRB_LSB - 1;

    //---------------------------------------------------------
    //------------------- Internal Signals --------------------
    //---------------------------------------------------------
    // APB Slave Interface Signals
    logic                   PSELx_s1,   PSELx_s2;
    logic [ADDR_WIDTH-1:0]  PADDR_s1,   PADDR_s2;
    logic                   PWRITE_s1,  PWRITE_s2;
    logic [NBYTES-1:0]      PSTRB_s1,   PSTRB_s2;
    logic [DATA_WIDTH-1:0]  PWDATA_s1,  PWDATA_s2;
    logic                   PENABLE_s1, PENABLE_s2;
    logic [DATA_WIDTH-1:0]  PRDATA_s1,  PRDATA_s2;
    logic                   PREADY_s1,  PREADY_s2;

    // APB Master Interface Signals
    logic                   PSELx_m1,   PSELx_m2;
    logic [ADDR_WIDTH-1:0]  PADDR_m1,   PADDR_m2;
    logic                   PWRITE_m1,  PWRITE_m2;
    logic [NBYTES-1:0]      PSTRB_m1,   PSTRB_m2;
    logic [DATA_WIDTH-1:0]  PWDATA_m1,  PWDATA_m2;
    logic                   PENABLE_m1, PENABLE_m2;
    logic [DATA_WIDTH-1:0]  PRDATA_m1,  PRDATA_m2;
    logic                   PREADY_m1,  PREADY_m2;

    // APB Controller Interface
    logic                   start_1,        start_2;
    logic                   valid_1,        valid_2;
    logic [ADDR_WIDTH-1:0]  addr_1,         addr_2;
    logic                   transfer_1,     transfer_2;
    logic                   write_1,        write_2;
    logic [NBYTES-1:0]      byte_strobe_1,  byte_strobe_2;
    logic [DATA_WIDTH-1:0]  rdata_1,        rdata_2, wdata_1, wdata_2;
    logic [N_AES-1:0]       concat_out_1,   concat_out_2;
    logic                   concat_done_1,  concat_done_2;
    logic                   done_1,         done_2;

    // UART Controller Interface
    logic                   start_uart;
    logic                   ready_uart;
    logic [N_AES-1:0]       uart_in;
    logic                   write_uart;
    logic [DATA_WIDTH-1:0]  uc_out;
    logic                   tx_full;

    logic [10:0] divisor;
    assign divisor = 2;

    // AES Encryption Output And Its Delayed Version
    logic                   AES_done, AES_done_reg;
    logic [N_AES-1:0]       AES_out, AES_out_reg;

    // Shift registers for delaying signals
    logic [AES_LATENCY-1:0] AES_done_delay;
    logic [N_AES-1:0]       AES_out_delay [AES_LATENCY-1:0];

    // MUX Signals
    logic [MUX1_WIDTH-1:0]  ina_mux1, inb_mux1, out_mux1;
    logic [MUX2_WIDTH-1:0]  ina_mux2, inb_mux2, out_mux2;
    logic [MUX1_WIDTH-1:0]  ina_mux3, inb_mux3, out_mux3;

    // Counter
    logic [5:0] count;

    //---------------------------------------------------------
    //---------------------- Assignments ----------------------
    //---------------------------------------------------------
    assign PREADY_1 = PREADY_s1;
    assign PREADY_2 = PREADY_s2;
    assign AES_done = concat_done_1;

    // MUX1 selects between external and APB_1 master
    assign ina_mux1     = {PSELx_1, PADDR_1, PWDATA_1, PWRITE_1, PSTRB_1, PENABLE_1};
    assign inb_mux1     = {PSELx_m1, PADDR_m1, PWDATA_m1, PWRITE_m1, PSTRB_m1, PENABLE_m1};
    assign PSELx_s1     = out_mux1[PSELX_BIT];
    assign PADDR_s1     = out_mux1[PADDR_MSB:PADDR_LSB];
    assign PWDATA_s1    = out_mux1[PWDATA_MSB:PWDATA_LSB];
    assign PWRITE_s1    = out_mux1[PWRITE_BIT];
    assign PSTRB_s1     = out_mux1[PSTRB_MSB:PSTRB_LSB];
    assign PENABLE_s1   = out_mux1[PENABLE_BIT];

    // MUX2 selects AES output and concatenated data from APB_2 controller
    assign ina_mux2     = {AES_done_reg, AES_out_reg};
    assign inb_mux2     = {concat_done_2, concat_out_2};
    assign start_uart   = out_mux2[MUX2_WIDTH-1];
    assign uart_in      = out_mux2[MUX2_WIDTH-2:0];

    // MUX3 selects between external and APB_2 master
    assign ina_mux3     = {PSELx_2, PADDR_2, PWDATA_2, PWRITE_2, PSTRB_2, PENABLE_2};
    assign inb_mux3     = {PSELx_m2, PADDR_m2, PWDATA_m2, PWRITE_m2, PSTRB_m2, PENABLE_m2};
    assign PSELx_s2     = out_mux3[PSELX_BIT];
    assign PADDR_s2     = out_mux3[PADDR_MSB:PADDR_LSB];
    assign PWDATA_s2    = out_mux3[PWDATA_MSB:PWDATA_LSB];
    assign PWRITE_s2    = out_mux3[PWRITE_BIT];
    assign PSTRB_s2     = out_mux3[PSTRB_MSB:PSTRB_LSB];
    assign PENABLE_s2   = out_mux3[PENABLE_BIT];

    assign PRDATA_m1    = PRDATA_s1;
    assign PREADY_m1    = PREADY_s1;
    assign PRDATA_m2    = PRDATA_s2;
    assign PREADY_m2    = PREADY_s2;

    assign PRDATA_1     = rdata_1;
    assign PRDATA_2     = rdata_2;
    assign wdata_1      = 0;
    assign wdata_2      = 0;

    assign ready_uart   = !tx_full;

    // Sending request to request new entries from the processor
    always_ff @(posedge PCLK or negedge PRESETn) begin
        if(~PRESETn) begin
            count <= 0;
            req   <= 0;
        end else begin
            if(UART_inst.rden_fifo) begin
                count <= count + 1;
            end

            if(count == 16) begin
                req <= 1;
                count <= 0;
            end else begin
                req <= 0;
            end
        end
    end

    // Shift register logic
    always_ff @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            AES_done_delay <= '0;
            for (int i = 0; i < AES_LATENCY; i++) begin
                AES_out_delay[i] <= '0;
            end
        end else begin
            // Shift in new values
            AES_done_delay <= {AES_done_delay[AES_LATENCY-2:0], AES_done};
            AES_out_delay[0] <= AES_out;
            for (int i = 1; i < AES_LATENCY; i++) begin
                AES_out_delay[i] <= AES_out_delay[i-1];
            end
        end
    end

    // Output the delayed values
    assign AES_done_reg = AES_done_delay[AES_LATENCY-1];
    assign AES_out_reg  = AES_out_delay[AES_LATENCY-1];


    //---------------------------------------------------------
    //----------------- Module Instantiations -----------------
    //---------------------------------------------------------
    // APB MUXes
    MUX #(.MUX_WIDTH(MUX1_WIDTH))MUX_inst_1(.sel(sel_1), .ina(ina_mux1), .inb(inb_mux1), .out(out_mux1));
    MUX #(.MUX_WIDTH(MUX2_WIDTH))MUX_inst_2(.sel(sel_2), .ina(ina_mux2), .inb(inb_mux2), .out(out_mux2));
    MUX #(.MUX_WIDTH(MUX1_WIDTH))MUX_inst_3(.sel(sel_3), .ina(ina_mux3), .inb(inb_mux3), .out(out_mux3));

    // UART Transmitter
    UART #(.DATA_WIDTH(DATA_WIDTH), .FIFO_DEPTH(FIFO_DEPTH), .NTICKS(NTICKS))
    UART_inst(
        .clk(PCLK), .reset_n(PRESETn), .wren(write_uart),
        .w_data(uc_out), .divisor(divisor), .tx(tx), .tx_full(tx_full)
    );
    // UART Controller
    UART_Controller #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH), .N_AES(N_AES) )
    UART_Controller_inst(
        .clk(PCLK), .reset_n(PRESETn), .start(start_uart),
        .ready(ready_uart), .in(uart_in), .write_uart(write_uart),
        .out(uc_out)
    );

    // AES Encryption Core
    AES_Encrypt #(.N(N_AES), .Nr(Nr_AES), .Nk(Nk_AES))
    AES_Encrypt_inst(.in(concat_out_1), .key(KEY_AES), .out(AES_out));

    // Edge Detectors for Start Signals
    pos_edge_det pos_edge_det_inst_1(.sig(sel_1), .clk(PCLK), .pe(start_1));
    pos_edge_det pos_edge_det_inst_2(.sig(sel_3), .clk(PCLK), .pe(start_2));

    // APB Controllers
    APB_Controller #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH), .NBYTES(NBYTES), .N_AES(N_AES))
    APB_Controller_inst_1(
        .PCLK(PCLK), .PRESETn(PRESETn), .start(start_1), .start_addr(start_addr_1),
        .valid(done_1), .addr(addr_1), .transfer(transfer_1), .write(write_1),
        .byte_strobe(byte_strobe_1), .rdata(rdata_1), .concat_out(concat_out_1), .concat_done(concat_done_1)
    );
    APB_Controller #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH), .NBYTES(NBYTES), .N_AES(N_AES)
        )APB_Controller_inst_2(
        .PCLK(PCLK), .PRESETn(PRESETn), .start(start_2), .start_addr(start_addr_2),
        .valid(done_2), .addr(addr_2), .transfer(transfer_2), .write(write_2),
        .byte_strobe(byte_strobe_2), .rdata(rdata_2), .concat_out(concat_out_2), .concat_done(concat_done_2)
    );

    // APB Masters
    APB_Master #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH), .NBYTES(NBYTES))
    APB_Master_inst_1(
        .PCLK(PCLK), .PRESETn(PRESETn), .PSELx(PSELx_m1), .PENABLE(PENABLE_m1),
        .PWRITE(PWRITE_m1), .PSTRB(PSTRB_m1), .PADDR(PADDR_m1), .PWDATA(PWDATA_m1),
        .PRDATA(PRDATA_m1), .PREADY(PREADY_m1), .addr(addr_1), .transfer(transfer_1), .write(write_1),
        .byte_strobe(byte_strobe_1), .wdata(wdata_1), .rdata(rdata_1), .transfer_done(done_1)
    );
    APB_Master #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH), .NBYTES(NBYTES))
    APB_Master_inst_2(
        .PCLK(PCLK), .PRESETn(PRESETn), .PSELx(PSELx_m2), .PENABLE(PENABLE_m2),
        .PWRITE(PWRITE_m2), .PSTRB(PSTRB_m2), .PADDR(PADDR_m2), .PWDATA(PWDATA_m2),
        .PRDATA(PRDATA_m2), .PREADY(PREADY_m2), .addr(addr_2), .transfer(transfer_2), .write(write_2),
        .byte_strobe(byte_strobe_2), .wdata(wdata_2), .rdata(rdata_2), .transfer_done(done_2)
    );

    // APB Register File Wrappers (Slaves)
    APB_RegFile_Wrapper #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH), .NBYTES(NBYTES))
    APB_RegFile_Wrapper_inst_1(
        .PCLK(PCLK), .PRESETn(PRESETn), .PSELx(PSELx_s1), .PADDR(PADDR_s1),
        .PWRITE(PWRITE_s1), .PSTRB(PSTRB_s1), .PWDATA(PWDATA_s1), .PENABLE(PENABLE_s1),
        .PRDATA(PRDATA_s1),.PREADY(PREADY_s1)
    );
    APB_RegFile_Wrapper #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH), .NBYTES(NBYTES))
    APB_RegFile_Wrapper_inst_2(
        .PCLK(PCLK),.PRESETn(PRESETn), .PSELx(PSELx_s2),.PADDR(PADDR_s2),
        .PWRITE(PWRITE_s2), .PSTRB(PSTRB_s2), .PWDATA(PWDATA_s2), .PENABLE(PENABLE_s2),
        .PRDATA(PRDATA_s2), .PREADY(PREADY_s2)
    );
endmodule