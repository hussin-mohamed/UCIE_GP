module bridge_top;
    import shared_pkg::*;
    import uvm_pkg::*;
    import bridge_pkg::*;
    
    `include "uvm_macros.svh"
    
    logic req;

    // Instantiating BFMs
    SYSCTRL_bfm sysctrl_bfm();
    APB_bfm     apb_bfm_1(
        .PCLK(sysctrl_bfm.PCLK),
        .PRESETn(sysctrl_bfm.PRESETn),
        .req(req),
        .PSELx_int(AES_APB_UART_Bridge_inst.PSELx_s1),
        .PADDR_int(AES_APB_UART_Bridge_inst.PADDR_s1),
        .PWRITE_int(AES_APB_UART_Bridge_inst.PWRITE_s1),
        .PSTRB_int(AES_APB_UART_Bridge_inst.PSTRB_s1),
        .PWDATA_int(AES_APB_UART_Bridge_inst.PWDATA_s1),
        .PENABLE_int(AES_APB_UART_Bridge_inst.PENABLE_s1)
    );
    APB_bfm     apb_bfm_2(
        .PCLK(sysctrl_bfm.PCLK),
        .PRESETn(sysctrl_bfm.PRESETn),
        .req(req),
        .PSELx_int(AES_APB_UART_Bridge_inst.PSELx_s2),
        .PADDR_int(AES_APB_UART_Bridge_inst.PADDR_s2),
        .PWRITE_int(AES_APB_UART_Bridge_inst.PWRITE_s2),
        .PSTRB_int(AES_APB_UART_Bridge_inst.PSTRB_s2),
        .PWDATA_int(AES_APB_UART_Bridge_inst.PWDATA_s2),
        .PENABLE_int(AES_APB_UART_Bridge_inst.PENABLE_s2)
    );

    // Binding interfaces to internal modules for monitoring
    bind AES_APB_UART_Bridge_inst                       APB_controller_if  apb_controller_if_1 (
        .PCLK(sysctrl_bfm.PCLK),
        .PRESETn(sysctrl_bfm.PRESETn),
        .concat_out(AES_APB_UART_Bridge_inst.concat_out_1),
        .concat_done(AES_APB_UART_Bridge_inst.concat_done_1)
    );
    bind AES_APB_UART_Bridge_inst                       APB_controller_if  apb_controller_if_2 (
        .PCLK(sysctrl_bfm.PCLK),
        .PRESETn(sysctrl_bfm.PRESETn),
        .concat_out(AES_APB_UART_Bridge_inst.concat_out_2),
        .concat_done(AES_APB_UART_Bridge_inst.concat_done_2)
    );
    bind AES_APB_UART_Bridge_inst                       AES_if             aes_if (
        .PCLK(sysctrl_bfm.PCLK),
        .PRESETn(sysctrl_bfm.PRESETn),
        .AES_done(AES_APB_UART_Bridge_inst.AES_done_reg),
        .AES_in(AES_APB_UART_Bridge_inst.concat_out_1),
        .AES_out(AES_APB_UART_Bridge_inst.AES_out_reg)
    );

    // Instantiating the dut
    AES_APB_UART_Bridge
    AES_APB_UART_Bridge_inst
    (
        //--------------------- Clock & Reset ---------------------
        .PCLK(sysctrl_bfm.PCLK),
        .PRESETn(sysctrl_bfm.PRESETn),

        //--------------------- MUX Selectors ---------------------
        .sel_1(apb_bfm_1.sel_1), .sel_2(apb_bfm_2.sel_2), .sel_3(apb_bfm_2.sel_3),

        //--------- Starting Address for Writing Operation --------
        .start_addr_1(apb_bfm_1.start_addr),    .start_addr_2(apb_bfm_2.start_addr),

        //-------------------- APB Slave Ports --------------------
        .PSELx_1(apb_bfm_1.PSELx),      .PSELx_2(apb_bfm_2.PSELx),
        .PADDR_1(apb_bfm_1.PADDR),      .PADDR_2(apb_bfm_2.PADDR),
        .PWRITE_1(apb_bfm_1.PWRITE),    .PWRITE_2(apb_bfm_2.PWRITE),
        .PSTRB_1(apb_bfm_1.PSTRB),      .PSTRB_2(apb_bfm_2.PSTRB),
        .PWDATA_1(apb_bfm_1.PWDATA),    .PWDATA_2(apb_bfm_2.PWDATA),
        .PENABLE_1(apb_bfm_1.PENABLE),  .PENABLE_2(apb_bfm_2.PENABLE),
        .PRDATA_1(apb_bfm_1.PRDATA),    .PRDATA_2(apb_bfm_2.PRDATA),
        .PREADY_1(apb_bfm_1.PREADY),    .PREADY_2(apb_bfm_2.PREADY),

        //--------------------- UART Output -----------------------
        .tx(sysctrl_bfm.tx),            .req(req)
    );

    initial begin
        uvm_config_db#(virtual SYSCTRL_bfm)::set(null,          "uvm_test_top", "SYSCTRL_BFM",        sysctrl_bfm);
        uvm_config_db#(virtual APB_bfm)::set(null,              "uvm_test_top", "APB_BFM_1",          apb_bfm_1);
        uvm_config_db#(virtual APB_bfm)::set(null,              "uvm_test_top", "APB_BFM_2",          apb_bfm_2);
        uvm_config_db#(virtual AES_if)::set(null,               "uvm_test_top", "AES_IF",             AES_APB_UART_Bridge_inst.aes_if);
        uvm_config_db#(virtual APB_controller_if)::set(null,    "uvm_test_top", "APB_CTRL_OUT_1",     AES_APB_UART_Bridge_inst.apb_controller_if_1);
        uvm_config_db#(virtual APB_controller_if)::set(null,    "uvm_test_top", "APB_CTRL_OUT_2",     AES_APB_UART_Bridge_inst.apb_controller_if_2);
        run_test();
    end
endmodule : bridge_top
