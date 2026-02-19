// ****************************************************************************
// *                                                                          *
// * Copyright (c) 2014-2015 Synopsys Inc. All rights reserved.               *
// *                                                                          *
// * Synopsys Proprietary and Confidential. This file contains confidential   *
// * information and the trade secrets of Synopsys Inc. Use, disclosure, or   *
// * reproduction is prohibited without the prior express written permission  *
// * of Synopsys, Inc.                                                        *
// *                                                                          *
// * Synopsys, Inc.                                                           *
// * 700 East Middlefield Road                                                *
// * Mountain View, California 94043                                          *
// * (800) 541-7737                                                           *
// *                                                                          *
// ****************************************************************************

package shared_pkg;
    parameter DATA_WIDTH    = 32;
    parameter ADDR_WIDTH    = 32;
    parameter NBYTES        = DATA_WIDTH/8;
    parameter CLOCK_RATE    = 0.5; // GHz
    parameter CLOCK_PERIOD  = 1/0.5; // ns
    parameter BAUD_RATE     = 9600; //bps
    parameter DIVISOR       = (1/(16*BAUD_RATE*CLOCK_PERIOD)); //Counter's final value
    parameter N_AES         = 128;
    parameter Nr_AES        = 10;
    parameter Nk_AES        = 4;
    parameter KEY_AES       = 128'h2B7E151628AED2A6ABF7158809CF4F3C;
    parameter AES_LATENCY   = 5;

    // APB Slave FSM states type using onehot encoding
    typedef enum logic [1:0] {
    IDLE_S      = 2'b01,
    ACCESS_S    = 2'b10} apb_slave_state_e;

    // APB Master FSM states type using onehot encoding
    typedef enum logic [2:0] {
    IDLE_M      = 3'b001,
    SETUP_M     = 3'b010,
    ACCESS_M    = 3'b100} apb_master_state_e;

    // APB Controller FSM states type using onehot encoding
    typedef enum logic [3:0] {
    IDLE_C      = 4'b0001,
    READ_C      = 4'b0010,
    SHIFT_C     = 4'b0100,
    DELAY_C     = 4'b1000} apb_controller_state_e;

    // UART Controller FSM states type using onehot encoding
    typedef enum logic [2:0] {
    IDLE_UC     = 3'b001,
    WAIT_UC     = 3'b010,
    PUSH_UC     = 3'b100} uart_controller_state_e;

    // UART TX FSM states type using onehot encoding
    typedef enum logic [3:0] {
    IDLE_U  = 4'b0001,
    START_U = 4'b0010,
    DATA_U  = 4'b0100,
    STOP_U  = 4'b1000} uart_state_e;

    // Transaction type
    typedef enum logic [1:0] {
    NONE    = 2'b00,
    READ    = 2'b01,
    WRITE   = 2'b10
    } type_e;

    // Data Path type
    typedef enum logic {
    APB_BFM_TO_REGFILE_PATH = 1'b0,
    AES_TO_REGFILE_PATH = 1'b1
    } regfile_path_e;

    typedef enum logic {
    APB_TO_UART_PATH    = 1'b0,
    AES_TO_UART_PATH    = 1'b1
    } uart_path_e;
endpackage : shared_pkg
