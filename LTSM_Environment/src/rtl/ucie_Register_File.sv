module ucie_Register_File (
    input  logic        i_clk,
    input  logic        i_domain_rst,

    // ─────────────────────────────────────────
    // Software Interface
    // ─────────────────────────────────────────
    input  logic [12:0] i_addr,
    input  logic [63:0] i_data_in,
    input  logic        i_write_en,

    // ─────────────────────────────────────────
    // Uncorrectable Error Status (RW1CS)
    // ─────────────────────────────────────────
    input  logic        i_adapter_timeout,
    input  logic        i_receiver_overflow,
    input  logic        i_internal_error,
    input  logic        i_sideband_fatal_error,
    input  logic        i_sideband_non_fatal_error,

    // ─────────────────────────────────────────
    // Correctable Error Status (RW1CS)
    // ─────────────────────────────────────────
    input  logic        i_crc_error,
    input  logic        i_adapter_lsm_retrain,
    input  logic        i_correctable_internal_error,
    input  logic        i_sideband_correctable_error,
    input  logic        i_runtime_link_testing_parity,

    // ─────────────────────────────────────────
    // Header Log 1 (ROS) - HW writes anytime
    // ─────────────────────────────────────────
    input  logic [63:0] i_header_log1_data,
    input  logic        i_header_log1_wen,

    // ─────────────────────────────────────────
    // Header Log 2 (ROS) - HW writes anytime
    // ─────────────────────────────────────────
    input  logic [3:0]  i_adapter_timeout_encoding,
    input  logic [2:0]  i_receiver_overflow_encoding,
    input  logic [2:0]  i_adapter_lsm_response_type,
    input  logic        i_adapter_lsm_id,
    input  logic [3:0]  i_flit_format,
    input  logic [4:0]  i_first_fatal_error_indicator,
    input  logic        i_header_log2_wen,

    // ─────────────────────────────────────────
    // Header Log 2 (RO) - HW continuously updates
    // ─────────────────────────────────────────
    input  logic        i_parameter_exchange_successful,

    // ─────────────────────────────────────────
    // Error and Link Testing Control
    // ─────────────────────────────────────────
    input  logic        i_parity_feature_nak,
    input  logic        i_crc_injection_busy,

    // ─────────────────────────────────────────
    // Runtime Parity Logs (RW1C)
    // ─────────────────────────────────────────
    input  logic [63:0] i_parity_log0_data,
    input  logic        i_parity_log0_set,
    input  logic [63:0] i_parity_log1_data,
    input  logic        i_parity_log1_set,
    input  logic [63:0] i_parity_log2_data,
    input  logic        i_parity_log2_set,
    input  logic [63:0] i_parity_log3_data,
    input  logic        i_parity_log3_set,

    // ─────────────────────────────────────────
    // Capability Logs (RW1C)
    // ─────────────────────────────────────────
    input  logic [63:0] i_adv_adapter_cap_data,
    input  logic        i_adv_adapter_cap_set,
    input  logic [63:0] i_fin_adapter_cap_data,
    input  logic        i_fin_adapter_cap_set,
    input  logic [63:0] i_adv_cxl_cap_data,
    input  logic        i_adv_cxl_cap_set,
    input  logic [63:0] i_fin_cxl_cap_data,
    input  logic        i_fin_cxl_cap_set,
    input  logic [63:0] i_adv_multiproto_cap_data,
    input  logic        i_adv_multiproto_cap_set,
    input  logic [63:0] i_fin_multiproto_cap_data,
    input  logic        i_fin_multiproto_cap_set,
    input  logic [63:0] i_adv_cxl_cap_stack1_data,
    input  logic        i_adv_cxl_cap_stack1_set,
    input  logic [63:0] i_fin_cxl_cap_stack1_data,
    input  logic        i_fin_cxl_cap_stack1_set,

    // ─────────────────────────────────────────
    // PHY Capability (RO) - HW updates anytime
    // ─────────────────────────────────────────
    input  logic        i_phy_cap_terminated_link,
    input  logic        i_phy_cap_txeq_support,
    input  logic [4:0]  i_phy_cap_tx_vswing,
    input  logic [1:0]  i_phy_cap_rx_clk_mode,
    input  logic [1:0]  i_phy_cap_rx_clk_phase,
    input  logic        i_phy_cap_package_type,
    input  logic        i_phy_cap_tcm_support,
    input  logic        i_phy_cap_tarr,

    // ─────────────────────────────────────────
    // PHY Status (RO) - HW continuously updates
    // ─────────────────────────────────────────
    input  logic        i_phy_stat_rx_term,
    input  logic        i_phy_stat_txeq,
    input  logic        i_phy_stat_clk_mode,
    input  logic        i_phy_stat_clk_phase,
    input  logic        i_phy_stat_lane_reversal,
    input  logic [5:0]  i_phy_stat_iq_correction,
    input  logic [3:0]  i_phy_stat_eq_preset,
    input  logic        i_phy_stat_tarr,

    // ─────────────────────────────────────────
    // Error Log 0 (ROS) - HW writes anytime
    // ─────────────────────────────────────────
    input  logic [7:0]  i_errlog0_state_n,
    input  logic        i_errlog0_lane_reversal,
    input  logic        i_errlog0_width_degrade,
    input  logic [7:0]  i_errlog0_state_n1,
    input  logic [7:0]  i_errlog0_state_n2,
    input  logic        i_errlog0_wen,

    // ─────────────────────────────────────────
    // Error Log 1 (ROS + RW1CS)
    // ─────────────────────────────────────────
    input  logic [7:0]  i_errlog1_state_n3,
    input  logic        i_errlog1_wen,
    input  logic        i_state_timeout_occurred,
    input  logic        i_sideband_timeout_occurred,
    input  logic        i_remote_linkerror_received,
    input  logic        i_phy_internal_error,

    // ─────────────────────────────────────────
    // Runtime Link Test Control
    // ─────────────────────────────────────────
    input  logic        i_rlt_start_clear,

    output logic [63:0] o_data_out
);

    // ─────────────────────────────────────────
    // Offset Map
    // ─────────────────────────────────────────
    localparam VENDOR_ID_OFFSET                     = 13'h0000;
    localparam VENDOR_ID_REGISTER_BLOCK_OFFSET      = 13'h0002;
    localparam VENDOR_REGISTER_BLOCK_VERSION_OFFSET = 13'h0004;
    localparam VENDOR_REGISTER_BLOCK_LENGTH_OFFSET  = 13'h0008;
    localparam UNC_ERR_STATUS_OFFSET                = 13'h0010;
    localparam UNC_ERR_MASK_OFFSET                  = 13'h0014;
    localparam COR_ERR_STATUS_OFFSET                = 13'h001C;
    localparam COR_ERR_MASK_OFFSET                  = 13'h0020;
    localparam HEADER_LOG1_OFFSET                   = 13'h0024;
    localparam HEADER_LOG2_OFFSET                   = 13'h002C;
    localparam ERR_LINK_TEST_CTRL_OFFSET            = 13'h0030;
    localparam PARITY_LOG0_OFFSET                   = 13'h0034;
    localparam PARITY_LOG1_OFFSET                   = 13'h003C;
    localparam PARITY_LOG2_OFFSET                   = 13'h0044;
    localparam PARITY_LOG3_OFFSET                   = 13'h004C;
    localparam ADV_ADAPTER_CAP_OFFSET               = 13'h0054;
    localparam FIN_ADAPTER_CAP_OFFSET               = 13'h005C;
    localparam ADV_CXL_CAP_OFFSET                   = 13'h0064;
    localparam FIN_CXL_CAP_OFFSET                   = 13'h006C;
    localparam ADV_MULTIPROTO_CAP_OFFSET            = 13'h0078;
    localparam FIN_MULTIPROTO_CAP_OFFSET            = 13'h0080;
    localparam ADV_CXL_CAP_STACK1_OFFSET            = 13'h0088;
    localparam FIN_CXL_CAP_STACK1_OFFSET            = 13'h0090;
    localparam PHY_CAP_OFFSET                       = 13'h1000;
    localparam PHY_CTRL_OFFSET                      = 13'h1004;
    localparam PHY_STATUS_OFFSET                    = 13'h1008;
    localparam PHY_INIT_DEBUG_OFFSET                = 13'h100C;
    localparam TRAINING_SETUP1_OFFSET               = 13'h1010;
    localparam TRAINING_SETUP2_OFFSET               = 13'h1020;
    localparam TRAINING_SETUP3_OFFSET               = 13'h1030;
    localparam TRAINING_SETUP4_OFFSET               = 13'h1050;
    localparam CLM_MODULE0_OFFSET                   = 13'h1060;
    localparam CLM_MODULE1_OFFSET                   = 13'h1068;
    localparam CLM_MODULE2_OFFSET                   = 13'h1070;
    localparam CLM_MODULE3_OFFSET                   = 13'h1078;
    localparam ERROR_LOG0_OFFSET                    = 13'h1080;
    localparam ERROR_LOG1_OFFSET                    = 13'h1090;
    localparam RLT_CONTROL_OFFSET                   = 13'h1100;

    // ─────────────────────────────────────────
    // Hardwired constants (truly fixed in silicon)
    // ─────────────────────────────────────────
    localparam logic [15:0] Vendor_ID_reg                     = 16'hD2DE;
    localparam logic [15:0] Vendor_ID_Register_Block_reg      = 16'h0000;
    localparam logic [3:0]  Vendor_Register_Block_Version_reg = 4'h0;
    localparam logic [31:0] Vendor_Register_Block_Length_reg  = 32'h00002000;

    // ─────────────────────────────────────────
    // PHY Capability (RO) - HW updates anytime
    // ─────────────────────────────────────────
    logic        PHY_Cap_Terminated_Link_reg;
    logic        PHY_Cap_TXEQ_Support_reg;
    logic [4:0]  PHY_Cap_TX_Vswing_reg;
    logic [1:0]  PHY_Cap_RX_Clk_Mode_reg;
    logic [1:0]  PHY_Cap_RX_Clk_Phase_reg;
    logic        PHY_Cap_Package_Type_reg;
    logic        PHY_Cap_TCM_Support_reg;
    logic        PHY_Cap_TARR_reg;

    // ─────────────────────────────────────────
    // Uncorrectable Error Status (RW1CS)
    // ─────────────────────────────────────────
    logic Adapter_Timeout_reg;
    logic Receiver_Overflow_reg;
    logic Internal_Error_reg;
    logic Sideband_Fatal_Error_reg;
    logic Sideband_Non_Fatal_Error_reg;

    // ─────────────────────────────────────────
    // Uncorrectable Error Mask (RWS)
    // ─────────────────────────────────────────
    logic Adapter_Timeout_mask_reg;
    logic Receiver_Overflow_mask_reg;
    logic Internal_Error_mask_reg;
    logic Sideband_Fatal_Error_mask_reg;
    logic Sideband_Non_Fatal_Error_mask_reg;

    // ─────────────────────────────────────────
    // Correctable Error Status (RW1CS)
    // ─────────────────────────────────────────
    logic CRC_Error_reg;
    logic Adapter_LSM_Retrain_reg;
    logic Correctable_Internal_Error_reg;
    logic Sideband_Correctable_Error_reg;
    logic Runtime_Link_Testing_Parity_reg;

    // ─────────────────────────────────────────
    // Correctable Error Mask (RWS)
    // ─────────────────────────────────────────
    logic CRC_Error_mask_reg;
    logic Adapter_LSM_Retrain_mask_reg;
    logic Correctable_Internal_Error_mask_reg;
    logic Sideband_Correctable_Error_mask_reg;
    logic Runtime_Link_Testing_Parity_mask_reg;

    // ─────────────────────────────────────────
    // Header Log 1 (ROS) - HW writes anytime
    // ─────────────────────────────────────────
    logic [63:0] Header_Log1_reg;

    // ─────────────────────────────────────────
    // Header Log 2 (ROS + RO)
    // ─────────────────────────────────────────
    logic [3:0]  Adapter_Timeout_Encoding_reg;
    logic [2:0]  Receiver_Overflow_Encoding_reg;
    logic [2:0]  Adapter_LSM_Response_Type_reg;
    logic        Adapter_LSM_ID_reg;
    logic [3:0]  Flit_Format_reg;
    logic [4:0]  First_Fatal_Error_Indicator_reg;
    logic        Parameter_Exchange_Successful_reg;

    // ─────────────────────────────────────────
    // Error and Link Testing Control
    // ─────────────────────────────────────────
    logic [3:0]  Remote_Reg_Access_Threshold_reg;
    logic        RT_Link_Test_Tx_En_reg;
    logic        RT_Link_Test_Rx_En_reg;
    logic [2:0]  Num_64B_Inserts_reg;
    logic        Parity_Feature_Nak_reg;
    logic [1:0]  CRC_Injection_Enable_reg;
    logic [1:0]  CRC_Injection_Count_reg;
    logic        CRC_Injection_Busy_reg;

    // ─────────────────────────────────────────
    // Runtime Parity Logs (RW1C)
    // ─────────────────────────────────────────
    logic [63:0] Parity_Log0_reg;
    logic [63:0] Parity_Log1_reg;
    logic [63:0] Parity_Log2_reg;
    logic [63:0] Parity_Log3_reg;

    // ─────────────────────────────────────────
    // Capability Logs (RW1C)
    // ─────────────────────────────────────────
    logic [63:0] Adv_Adapter_Cap_reg;
    logic [63:0] Fin_Adapter_Cap_reg;
    logic [63:0] Adv_CXL_Cap_reg;
    logic [63:0] Fin_CXL_Cap_reg;
    logic [63:0] Adv_MultiProto_Cap_reg;
    logic [63:0] Fin_MultiProto_Cap_reg;
    logic [63:0] Adv_CXL_Cap_Stack1_reg;
    logic [63:0] Fin_CXL_Cap_Stack1_reg;

    // ─────────────────────────────────────────
    // PHY Control (RW)
    // ─────────────────────────────────────────
    logic [2:0]  PHY_Ctrl_Reserved_2_0_reg;
    logic        PHY_Ctrl_RX_Term_Ctrl_reg;
    logic        PHY_Ctrl_TX_EQ_En_reg;
    logic        PHY_Ctrl_RX_Clk_Mode_Sel_reg;
    logic        PHY_Ctrl_RX_Clk_Phase_Sel_reg;
    logic        PHY_Ctrl_Force_x32_Width_reg;
    logic        PHY_Ctrl_Force_x8_Width_reg;
    logic        PHY_Ctrl_Force_IQ_Corr_En_reg;
    logic [5:0]  PHY_Ctrl_Force_IQ_Corr_Param_reg;
    logic        PHY_Ctrl_Force_TX_EQ_Preset_reg;
    logic [3:0]  PHY_Ctrl_Force_TX_EQ_Preset_Set_reg;
    logic        PHY_Ctrl_TARR_reg;

    // ─────────────────────────────────────────
    // PHY Status (RO) - HW continuously updates
    // ─────────────────────────────────────────
    logic        PHY_Stat_RX_Term_reg;
    logic        PHY_Stat_TXEQ_reg;
    logic        PHY_Stat_Clk_Mode_reg;
    logic        PHY_Stat_Clk_Phase_reg;
    logic        PHY_Stat_Lane_Reversal_reg;
    logic [5:0]  PHY_Stat_IQ_Corr_Param_reg;
    logic [3:0]  PHY_Stat_EQ_Preset_reg;
    logic        PHY_Stat_TARR_reg;

    // ─────────────────────────────────────────
    // PHY Init and Debug (RW)
    // ─────────────────────────────────────────
    logic [2:0]  PHY_Init_Ctrl_reg;
    logic        PHY_Init_Resume_Training_reg;

    // ─────────────────────────────────────────
    // Training Setup 1 (RW)
    // ─────────────────────────────────────────
    logic [2:0]   Train1_Data_Pattern_reg;
    logic [2:0]   Train1_Valid_Pattern_reg;
    logic [3:0]   Train1_Clk_Phase_Ctrl_reg;
    logic         Train1_Training_Mode_reg;
    logic [15:0]  Train1_Burst_Count_reg;

    // ─────────────────────────────────────────
    // Training Setup 2 (RW)
    // ─────────────────────────────────────────
    logic [15:0]  Train2_Idle_Count_reg;
    logic [15:0]  Train2_Iterations_reg;

    // ─────────────────────────────────────────
    // Training Setup 3 (RW)
    // ─────────────────────────────────────────
    logic [63:0]  Train3_Lane_Mask_reg;

    // ─────────────────────────────────────────
    // Training Setup 4 (RW)
    // ─────────────────────────────────────────
    logic [3:0]   Train4_Repair_Lane_Mask_reg;
    logic [11:0]  Train4_Max_Err_Per_Lane_reg;
    logic [15:0]  Train4_Max_Err_Aggregate_reg;

    // ─────────────────────────────────────────
    // Current Lane Map Module 0-3 (RW)
    // ─────────────────────────────────────────
    logic [63:0] CLM_Module0_reg;
    logic [63:0] CLM_Module1_reg;
    logic [63:0] CLM_Module2_reg;
    logic [63:0] CLM_Module3_reg;

    // ─────────────────────────────────────────
    // Error Log 0 (ROS) - HW writes anytime
    // ─────────────────────────────────────────
    logic [7:0]  ErrLog0_State_N_reg;
    logic        ErrLog0_Lane_Reversal_reg;
    logic        ErrLog0_Width_Degrade_reg;
    logic [7:0]  ErrLog0_State_N1_reg;
    logic [7:0]  ErrLog0_State_N2_reg;

    // ─────────────────────────────────────────
    // Error Log 1 (ROS + RW1CS)
    // ─────────────────────────────────────────
    logic [7:0]  ErrLog1_State_N3_reg;
    logic        ErrLog1_State_Timeout_reg;
    logic        ErrLog1_Sideband_Timeout_reg;
    logic        ErrLog1_Remote_LinkError_reg;
    logic        ErrLog1_Internal_Error_reg;

    // ─────────────────────────────────────────
    // Runtime Link Test Control (RW)
    // ─────────────────────────────────────────
    logic        RLT_Ctrl_Reserved_0_reg;
    logic        RLT_Ctrl_Reserved_1_reg;
    logic        RLT_Ctrl_Apply_Mod0_reg;
    logic        RLT_Ctrl_Apply_Mod1_reg;
    logic        RLT_Ctrl_Apply_Mod2_reg;
    logic        RLT_Ctrl_Apply_Mod3_reg;
    logic        RLT_Ctrl_Start_reg;
    logic        RLT_Ctrl_Inject_Stuck_reg;
    logic [6:0]  RLT_Ctrl_Mod0_Lane_ID_reg;
    logic [6:0]  RLT_Ctrl_Mod1_Lane_ID_reg;
    logic [6:0]  RLT_Ctrl_Mod2_Lane_ID_reg;
    logic [6:0]  RLT_Ctrl_Mod3_Lane_ID_reg;

    // ═════════════════════════════════════════
    // Sequential Logic
    // ═════════════════════════════════════════
    always_ff @(posedge i_clk or posedge i_domain_rst) begin
        if (i_domain_rst) begin

            // ── PHY Capability (RO) ──
            PHY_Cap_Terminated_Link_reg         <= 1'b0;
            PHY_Cap_TXEQ_Support_reg            <= 1'b0;
            PHY_Cap_TX_Vswing_reg               <= 5'h0;
            PHY_Cap_RX_Clk_Mode_reg             <= 2'b00;
            PHY_Cap_RX_Clk_Phase_reg            <= 2'b00;
            PHY_Cap_Package_Type_reg            <= 1'b0;
            PHY_Cap_TCM_Support_reg             <= 1'b0;
            PHY_Cap_TARR_reg                    <= 1'b0;

            // ── RW1CS Uncorrectable Status ──
            Adapter_Timeout_reg                 <= 1'b0;
            Receiver_Overflow_reg               <= 1'b0;
            Internal_Error_reg                  <= 1'b0;
            Sideband_Fatal_Error_reg            <= 1'b0;
            Sideband_Non_Fatal_Error_reg        <= 1'b0;

            // ── RWS Uncorrectable Mask ──
            Adapter_Timeout_mask_reg            <= 1'b1;
            Receiver_Overflow_mask_reg          <= 1'b1;
            Internal_Error_mask_reg             <= 1'b1;
            Sideband_Fatal_Error_mask_reg       <= 1'b1;
            Sideband_Non_Fatal_Error_mask_reg   <= 1'b1;

            // ── RW1CS Correctable Status ──
            CRC_Error_reg                       <= 1'b0;
            Adapter_LSM_Retrain_reg             <= 1'b0;
            Correctable_Internal_Error_reg      <= 1'b0;
            Sideband_Correctable_Error_reg      <= 1'b0;
            Runtime_Link_Testing_Parity_reg     <= 1'b0;

            // ── RWS Correctable Mask ──
            CRC_Error_mask_reg                  <= 1'b1;
            Adapter_LSM_Retrain_mask_reg        <= 1'b1;
            Correctable_Internal_Error_mask_reg <= 1'b1;
            Sideband_Correctable_Error_mask_reg <= 1'b1;
            Runtime_Link_Testing_Parity_mask_reg<= 1'b1;

            // ── ROS Header Log 1 ──
            Header_Log1_reg                     <= 64'h0;

            // ── ROS/RO Header Log 2 ──
            Adapter_Timeout_Encoding_reg        <= 4'h0;
            Receiver_Overflow_Encoding_reg      <= 3'h0;
            Adapter_LSM_Response_Type_reg       <= 3'h0;
            Adapter_LSM_ID_reg                  <= 1'b0;
            Flit_Format_reg                     <= 4'h0;
            First_Fatal_Error_Indicator_reg     <= 5'h0;
            Parameter_Exchange_Successful_reg   <= 1'b0;

            // ── Error and Link Testing Control ──
            Remote_Reg_Access_Threshold_reg     <= 4'b0100;
            RT_Link_Test_Tx_En_reg              <= 1'b0;
            RT_Link_Test_Rx_En_reg              <= 1'b0;
            Num_64B_Inserts_reg                 <= 3'b000;
            Parity_Feature_Nak_reg              <= 1'b0;
            CRC_Injection_Enable_reg            <= 2'b00;
            CRC_Injection_Count_reg             <= 2'b00;
            CRC_Injection_Busy_reg              <= 1'b0;

            // ── RW1C Parity Logs ──
            Parity_Log0_reg                     <= 64'h0;
            Parity_Log1_reg                     <= 64'h0;
            Parity_Log2_reg                     <= 64'h0;
            Parity_Log3_reg                     <= 64'h0;

            // ── RW1C Capability Logs ──
            Adv_Adapter_Cap_reg                 <= 64'h0;
            Fin_Adapter_Cap_reg                 <= 64'h0;
            Adv_CXL_Cap_reg                     <= 64'h0;
            Fin_CXL_Cap_reg                     <= 64'h0;
            Adv_MultiProto_Cap_reg              <= 64'h0;
            Fin_MultiProto_Cap_reg              <= 64'h0;
            Adv_CXL_Cap_Stack1_reg              <= 64'h0;
            Fin_CXL_Cap_Stack1_reg              <= 64'h0;

            // ── PHY Control (RW) ──
            PHY_Ctrl_Reserved_2_0_reg           <= 3'b000;
            PHY_Ctrl_RX_Term_Ctrl_reg           <= 1'b0;
            PHY_Ctrl_TX_EQ_En_reg               <= 1'b0;
            PHY_Ctrl_RX_Clk_Mode_Sel_reg        <= 1'b0;
            PHY_Ctrl_RX_Clk_Phase_Sel_reg       <= 1'b0;
            PHY_Ctrl_Force_x32_Width_reg        <= 1'b0;
            PHY_Ctrl_Force_x8_Width_reg         <= 1'b0;
            PHY_Ctrl_Force_IQ_Corr_En_reg       <= 1'b0;
            PHY_Ctrl_Force_IQ_Corr_Param_reg    <= 6'h0;
            PHY_Ctrl_Force_TX_EQ_Preset_reg     <= 1'b0;
            PHY_Ctrl_Force_TX_EQ_Preset_Set_reg <= 4'h0;
            PHY_Ctrl_TARR_reg                   <= 1'b0;

            // ── PHY Status (RO) ──
            PHY_Stat_RX_Term_reg                <= 1'b0;
            PHY_Stat_TXEQ_reg                   <= 1'b0;
            PHY_Stat_Clk_Mode_reg               <= 1'b0;
            PHY_Stat_Clk_Phase_reg              <= 1'b0;
            PHY_Stat_Lane_Reversal_reg          <= 1'b0;
            PHY_Stat_IQ_Corr_Param_reg          <= 6'h0;
            PHY_Stat_EQ_Preset_reg              <= 4'h0;
            PHY_Stat_TARR_reg                   <= 1'b0;

            // ── PHY Init and Debug (RW) ──
            PHY_Init_Ctrl_reg                   <= 3'b000;
            PHY_Init_Resume_Training_reg        <= 1'b0;

            // ── Training Setup 1 (RW) ──
            Train1_Data_Pattern_reg             <= 3'b000;
            Train1_Valid_Pattern_reg            <= 3'b000;
            Train1_Clk_Phase_Ctrl_reg          <= 4'h0;
            Train1_Training_Mode_reg           <= 1'b0;
            Train1_Burst_Count_reg             <= 16'h0004;

            // ── Training Setup 2 (RW) ──
            Train2_Idle_Count_reg              <= 16'h0004;
            Train2_Iterations_reg              <= 16'h0004;

            // ── Training Setup 3 (RW) ──
            Train3_Lane_Mask_reg               <= 64'h0;

            // ── Training Setup 4 (RW) ──
            Train4_Repair_Lane_Mask_reg        <= 4'h0;
            Train4_Max_Err_Per_Lane_reg        <= 12'h0;
            Train4_Max_Err_Aggregate_reg       <= 16'h0;

            // ── Current Lane Map (RW) ──
            CLM_Module0_reg                    <= 64'h0;
            CLM_Module1_reg                    <= 64'h0;
            CLM_Module2_reg                    <= 64'h0;
            CLM_Module3_reg                    <= 64'h0;

            // ── Error Log 0 (ROS) ──
            ErrLog0_State_N_reg                <= 8'h0;
                        ErrLog0_Lane_Reversal_reg          <= 1'b0;
            ErrLog0_Width_Degrade_reg          <= 1'b0;
            ErrLog0_State_N1_reg               <= 8'h0;
            ErrLog0_State_N2_reg               <= 8'h0;

            // ── Error Log 1 (ROS + RW1CS) ──
            ErrLog1_State_N3_reg               <= 8'h0;
            ErrLog1_State_Timeout_reg          <= 1'b0;
            ErrLog1_Sideband_Timeout_reg       <= 1'b0;
            ErrLog1_Remote_LinkError_reg       <= 1'b0;
            ErrLog1_Internal_Error_reg         <= 1'b0;

            // ── Runtime Link Test Control (RW) ──
            RLT_Ctrl_Reserved_0_reg            <= 1'b0;
            RLT_Ctrl_Reserved_1_reg            <= 1'b0;
            RLT_Ctrl_Apply_Mod0_reg            <= 1'b0;
            RLT_Ctrl_Apply_Mod1_reg            <= 1'b0;
            RLT_Ctrl_Apply_Mod2_reg            <= 1'b0;
            RLT_Ctrl_Apply_Mod3_reg            <= 1'b0;
            RLT_Ctrl_Start_reg                 <= 1'b0;
            RLT_Ctrl_Inject_Stuck_reg          <= 1'b0;
            RLT_Ctrl_Mod0_Lane_ID_reg          <= 7'h0;
            RLT_Ctrl_Mod1_Lane_ID_reg          <= 7'h0;
            RLT_Ctrl_Mod2_Lane_ID_reg          <= 7'h0;
            RLT_Ctrl_Mod3_Lane_ID_reg          <= 7'h0;

        end else begin

            // ─────────────────────────────────
            // PHY Capability (RO)
            // HW updates anytime, SW cannot write
            // ─────────────────────────────────
            PHY_Cap_Terminated_Link_reg <= i_phy_cap_terminated_link;
            PHY_Cap_TXEQ_Support_reg    <= i_phy_cap_txeq_support;
            PHY_Cap_TX_Vswing_reg       <= i_phy_cap_tx_vswing;
            PHY_Cap_RX_Clk_Mode_reg     <= i_phy_cap_rx_clk_mode;
            PHY_Cap_RX_Clk_Phase_reg    <= i_phy_cap_rx_clk_phase;
            PHY_Cap_Package_Type_reg    <= i_phy_cap_package_type;
            PHY_Cap_TCM_Support_reg     <= i_phy_cap_tcm_support;
            PHY_Cap_TARR_reg            <= i_phy_cap_tarr;

            // ─────────────────────────────────
            // RW1CS Uncorrectable Error Status
            // ─────────────────────────────────
            if (i_adapter_timeout)
                Adapter_Timeout_reg <= 1'b1;
            else if (i_write_en && i_addr == UNC_ERR_STATUS_OFFSET && i_data_in[0])
                Adapter_Timeout_reg <= 1'b0;

            if (i_receiver_overflow)
                Receiver_Overflow_reg <= 1'b1;
            else if (i_write_en && i_addr == UNC_ERR_STATUS_OFFSET && i_data_in[1])
                Receiver_Overflow_reg <= 1'b0;

            if (i_internal_error)
                Internal_Error_reg <= 1'b1;
            else if (i_write_en && i_addr == UNC_ERR_STATUS_OFFSET && i_data_in[2])
                Internal_Error_reg <= 1'b0;

            if (i_sideband_fatal_error)
                Sideband_Fatal_Error_reg <= 1'b1;
            else if (i_write_en && i_addr == UNC_ERR_STATUS_OFFSET && i_data_in[3])
                Sideband_Fatal_Error_reg <= 1'b0;

            if (i_sideband_non_fatal_error)
                Sideband_Non_Fatal_Error_reg <= 1'b1;
            else if (i_write_en && i_addr == UNC_ERR_STATUS_OFFSET && i_data_in[4])
                Sideband_Non_Fatal_Error_reg <= 1'b0;

            // ─────────────────────────────────
            // RWS Uncorrectable Error Mask
            // ─────────────────────────────────
            if (i_write_en && i_addr == UNC_ERR_MASK_OFFSET) begin
                Adapter_Timeout_mask_reg          <= i_data_in[0];
                Receiver_Overflow_mask_reg        <= i_data_in[1];
                Internal_Error_mask_reg           <= i_data_in[2];
                Sideband_Fatal_Error_mask_reg     <= i_data_in[3];
                Sideband_Non_Fatal_Error_mask_reg <= i_data_in[4];
            end

            // ─────────────────────────────────
            // RW1CS Correctable Error Status
            // ─────────────────────────────────
            if (i_crc_error)
                CRC_Error_reg <= 1'b1;
            else if (i_write_en && i_addr == COR_ERR_STATUS_OFFSET && i_data_in[0])
                CRC_Error_reg <= 1'b0;

            if (i_adapter_lsm_retrain)
                Adapter_LSM_Retrain_reg <= 1'b1;
            else if (i_write_en && i_addr == COR_ERR_STATUS_OFFSET && i_data_in[1])
                Adapter_LSM_Retrain_reg <= 1'b0;

            if (i_correctable_internal_error)
                Correctable_Internal_Error_reg <= 1'b1;
            else if (i_write_en && i_addr == COR_ERR_STATUS_OFFSET && i_data_in[2])
                Correctable_Internal_Error_reg <= 1'b0;

            if (i_sideband_correctable_error)
                Sideband_Correctable_Error_reg <= 1'b1;
            else if (i_write_en && i_addr == COR_ERR_STATUS_OFFSET && i_data_in[3])
                Sideband_Correctable_Error_reg <= 1'b0;

            if (i_runtime_link_testing_parity)
                Runtime_Link_Testing_Parity_reg <= 1'b1;
            else if (i_write_en && i_addr == COR_ERR_STATUS_OFFSET && i_data_in[4])
                Runtime_Link_Testing_Parity_reg <= 1'b0;

            // ─────────────────────────────────
            // RWS Correctable Error Mask
            // ─────────────────────────────────
            if (i_write_en && i_addr == COR_ERR_MASK_OFFSET) begin
                CRC_Error_mask_reg                   <= i_data_in[0];
                Adapter_LSM_Retrain_mask_reg         <= i_data_in[1];
                Correctable_Internal_Error_mask_reg  <= i_data_in[2];
                Sideband_Correctable_Error_mask_reg  <= i_data_in[3];
                Runtime_Link_Testing_Parity_mask_reg <= i_data_in[4];
            end

            // ─────────────────────────────────
            // ROS Header Log 1
            // HW writes anytime via i_header_log1_wen
            // ─────────────────────────────────
            if (i_header_log1_wen) //remove
                Header_Log1_reg <= i_header_log1_data;

            // ─────────────────────────────────
            // ROS Header Log 2
            // HW writes anytime via i_header_log2_wen
            // ─────────────────────────────────
            if (i_header_log2_wen) begin
                Adapter_Timeout_Encoding_reg    <= i_adapter_timeout_encoding;
                Receiver_Overflow_Encoding_reg  <= i_receiver_overflow_encoding;
                Adapter_LSM_Response_Type_reg   <= i_adapter_lsm_response_type;
                Adapter_LSM_ID_reg              <= i_adapter_lsm_id;
                Flit_Format_reg                 <= i_flit_format;
                First_Fatal_Error_Indicator_reg <= i_first_fatal_error_indicator;
            end

            // ─────────────────────────────────
            // RO Parameter Exchange Successful
            // HW continuously updates
            // ─────────────────────────────────
            Parameter_Exchange_Successful_reg <= i_parameter_exchange_successful;

            // ─────────────────────────────────
            // RW Error and Link Testing Control
            // ─────────────────────────────────
            if (i_write_en && i_addr == ERR_LINK_TEST_CTRL_OFFSET) begin
                Remote_Reg_Access_Threshold_reg <= i_data_in[3:0];
                RT_Link_Test_Tx_En_reg          <= i_data_in[4];
                RT_Link_Test_Rx_En_reg          <= i_data_in[5];
                Num_64B_Inserts_reg             <= i_data_in[8:6];
                CRC_Injection_Enable_reg        <= i_data_in[14:13];
                CRC_Injection_Count_reg         <= i_data_in[16:15];
            end

            // RW1C Parity Feature Nak
            if (i_parity_feature_nak)
                Parity_Feature_Nak_reg <= 1'b1;
            else if (i_write_en && i_addr == ERR_LINK_TEST_CTRL_OFFSET && i_data_in[9])
                Parity_Feature_Nak_reg <= 1'b0;

            // RO CRC Injection Busy
            CRC_Injection_Busy_reg <= i_crc_injection_busy;

            // ─────────────────────────────────
            // RW1C Runtime Parity Logs
            // ─────────────────────────────────
            if (i_parity_log0_set)
                Parity_Log0_reg <= Parity_Log0_reg | i_parity_log0_data;
            else if (i_write_en && i_addr == PARITY_LOG0_OFFSET)
                Parity_Log0_reg <= Parity_Log0_reg & ~i_data_in;

            if (i_parity_log1_set)
                Parity_Log1_reg <= Parity_Log1_reg | i_parity_log1_data;
            else if (i_write_en && i_addr == PARITY_LOG1_OFFSET)
                Parity_Log1_reg <= Parity_Log1_reg & ~i_data_in;

            if (i_parity_log2_set)
                Parity_Log2_reg <= Parity_Log2_reg | i_parity_log2_data;
            else if (i_write_en && i_addr == PARITY_LOG2_OFFSET)
                Parity_Log2_reg <= Parity_Log2_reg & ~i_data_in;

            if (i_parity_log3_set)
                Parity_Log3_reg <= Parity_Log3_reg | i_parity_log3_data;
            else if (i_write_en && i_addr == PARITY_LOG3_OFFSET)
                Parity_Log3_reg <= Parity_Log3_reg & ~i_data_in;

            // ─────────────────────────────────
            // RW1C Capability Logs
            // ─────────────────────────────────
            if (i_adv_adapter_cap_set)
                Adv_Adapter_Cap_reg <= Adv_Adapter_Cap_reg | i_adv_adapter_cap_data;
            else if (i_write_en && i_addr == ADV_ADAPTER_CAP_OFFSET)
                Adv_Adapter_Cap_reg <= Adv_Adapter_Cap_reg & ~i_data_in;

            if (i_fin_adapter_cap_set)
                Fin_Adapter_Cap_reg <= Fin_Adapter_Cap_reg | i_fin_adapter_cap_data;
            else if (i_write_en && i_addr == FIN_ADAPTER_CAP_OFFSET)
                Fin_Adapter_Cap_reg <= Fin_Adapter_Cap_reg & ~i_data_in;

            if (i_adv_cxl_cap_set)
                Adv_CXL_Cap_reg <= Adv_CXL_Cap_reg | i_adv_cxl_cap_data;
            else if (i_write_en && i_addr == ADV_CXL_CAP_OFFSET)
                Adv_CXL_Cap_reg <= Adv_CXL_Cap_reg & ~i_data_in;

            if (i_fin_cxl_cap_set)
                Fin_CXL_Cap_reg <= Fin_CXL_Cap_reg | i_fin_cxl_cap_data;
            else if (i_write_en && i_addr == FIN_CXL_CAP_OFFSET)
                Fin_CXL_Cap_reg <= Fin_CXL_Cap_reg & ~i_data_in;

            if (i_adv_multiproto_cap_set)
                Adv_MultiProto_Cap_reg <= Adv_MultiProto_Cap_reg | i_adv_multiproto_cap_data;
            else if (i_write_en && i_addr == ADV_MULTIPROTO_CAP_OFFSET)
                Adv_MultiProto_Cap_reg <= Adv_MultiProto_Cap_reg & ~i_data_in;

            if (i_fin_multiproto_cap_set)
                Fin_MultiProto_Cap_reg <= Fin_MultiProto_Cap_reg | i_fin_multiproto_cap_data;
            else if (i_write_en && i_addr == FIN_MULTIPROTO_CAP_OFFSET)
                Fin_MultiProto_Cap_reg <= Fin_MultiProto_Cap_reg & ~i_data_in;

            if (i_adv_cxl_cap_stack1_set)
                Adv_CXL_Cap_Stack1_reg <= Adv_CXL_Cap_Stack1_reg | i_adv_cxl_cap_stack1_data;
            else if (i_write_en && i_addr == ADV_CXL_CAP_STACK1_OFFSET)
                Adv_CXL_Cap_Stack1_reg <= Adv_CXL_Cap_Stack1_reg & ~i_data_in;

            if (i_fin_cxl_cap_stack1_set)
                Fin_CXL_Cap_Stack1_reg <= Fin_CXL_Cap_Stack1_reg | i_fin_cxl_cap_stack1_data;
            else if (i_write_en && i_addr == FIN_CXL_CAP_STACK1_OFFSET)
                Fin_CXL_Cap_Stack1_reg <= Fin_CXL_Cap_Stack1_reg & ~i_data_in;

            // ─────────────────────────────────
            // PHY Control (RW)
            // ─────────────────────────────────
            if (i_write_en && i_addr == PHY_CTRL_OFFSET) begin
                PHY_Ctrl_Reserved_2_0_reg           <= i_data_in[2:0];
                PHY_Ctrl_RX_Term_Ctrl_reg           <= i_data_in[3];
                PHY_Ctrl_TX_EQ_En_reg               <= i_data_in[4];
                PHY_Ctrl_RX_Clk_Mode_Sel_reg        <= i_data_in[5];
                PHY_Ctrl_RX_Clk_Phase_Sel_reg       <= i_data_in[6];
                PHY_Ctrl_Force_x32_Width_reg        <= i_data_in[7];
                PHY_Ctrl_Force_x8_Width_reg         <= i_data_in[8];
                PHY_Ctrl_Force_IQ_Corr_En_reg       <= i_data_in[9];
                PHY_Ctrl_Force_IQ_Corr_Param_reg    <= i_data_in[15:10];
                PHY_Ctrl_Force_TX_EQ_Preset_reg     <= i_data_in[16];
                PHY_Ctrl_Force_TX_EQ_Preset_Set_reg <= i_data_in[20:17];
                PHY_Ctrl_TARR_reg                   <= i_data_in[21];
            end

            // ─────────────────────────────────
            // PHY Status (RO)
            // HW continuously updates, SW cannot write
            // ─────────────────────────────────
            PHY_Stat_RX_Term_reg        <= i_phy_stat_rx_term;
            PHY_Stat_TXEQ_reg          <= i_phy_stat_txeq;
            PHY_Stat_Clk_Mode_reg      <= i_phy_stat_clk_mode;
            PHY_Stat_Clk_Phase_reg     <= i_phy_stat_clk_phase;
            PHY_Stat_Lane_Reversal_reg <= i_phy_stat_lane_reversal;
            PHY_Stat_IQ_Corr_Param_reg <= i_phy_stat_iq_correction;
            PHY_Stat_EQ_Preset_reg     <= i_phy_stat_eq_preset;
            PHY_Stat_TARR_reg          <= i_phy_stat_tarr;

            // ─────────────────────────────────
            // PHY Init and Debug (RW)
            // ─────────────────────────────────
            if (i_write_en && i_addr == PHY_INIT_DEBUG_OFFSET) begin
                PHY_Init_Ctrl_reg            <= i_data_in[2:0];
                PHY_Init_Resume_Training_reg <= i_data_in[5];
            end

            // ─────────────────────────────────
            // Training Setup 1 (RW)
            // ─────────────────────────────────
            if (i_write_en && i_addr == TRAINING_SETUP1_OFFSET) begin
                Train1_Data_Pattern_reg    <= i_data_in[2:0];
                Train1_Valid_Pattern_reg   <= i_data_in[5:3];
                Train1_Clk_Phase_Ctrl_reg  <= i_data_in[9:6];
                Train1_Training_Mode_reg   <= i_data_in[10];
                Train1_Burst_Count_reg     <= i_data_in[26:11];
            end

            // ─────────────────────────────────
            // Training Setup 2 (RW)
            // ─────────────────────────────────
            if (i_write_en && i_addr == TRAINING_SETUP2_OFFSET) begin
                Train2_Idle_Count_reg  <= i_data_in[15:0];
                Train2_Iterations_reg  <= i_data_in[31:16];
            end

            // ─────────────────────────────────
            // Training Setup 3 (RW)
            // ─────────────────────────────────
            if (i_write_en && i_addr == TRAINING_SETUP3_OFFSET)
                Train3_Lane_Mask_reg <= i_data_in;

            // ─────────────────────────────────
            // Training Setup 4 (RW)
            // ─────────────────────────────────
            if (i_write_en && i_addr == TRAINING_SETUP4_OFFSET) begin
                Train4_Repair_Lane_Mask_reg  <= i_data_in[3:0];
                Train4_Max_Err_Per_Lane_reg  <= i_data_in[15:4];
                Train4_Max_Err_Aggregate_reg <= i_data_in[31:16];
            end

            // ─────────────────────────────────
            // Current Lane Map Module 0 (RW)
            // ─────────────────────────────────
            if (i_write_en && i_addr == CLM_MODULE0_OFFSET)
                CLM_Module0_reg <= i_data_in;

            // ─────────────────────────────────
            // Current Lane Map Module 1 (RW)
            // ─────────────────────────────────
            if (i_write_en && i_addr == CLM_MODULE1_OFFSET)
                CLM_Module1_reg <= i_data_in;

            // ─────────────────────────────────
            // Current Lane Map Module 2 (RW)
            // ─────────────────────────────────
            if (i_write_en && i_addr == CLM_MODULE2_OFFSET)
                CLM_Module2_reg <= i_data_in;

            // ─────────────────────────────────
            // Current Lane Map Module 3 (RW)
            // ─────────────────────────────────
            if (i_write_en && i_addr == CLM_MODULE3_OFFSET)
                CLM_Module3_reg <= i_data_in;

            // ─────────────────────────────────
            // Error Log 0 (ROS)
            // HW writes anytime via i_errlog0_wen
            // ─────────────────────────────────
            if (i_errlog0_wen) begin
                ErrLog0_State_N_reg       <= i_errlog0_state_n;
                ErrLog0_Lane_Reversal_reg <= i_errlog0_lane_reversal;
                ErrLog0_Width_Degrade_reg <= i_errlog0_width_degrade;
                ErrLog0_State_N1_reg      <= i_errlog0_state_n1;
                ErrLog0_State_N2_reg      <= i_errlog0_state_n2;
            end

            // ─────────────────────────────────
            // Error Log 1 - ROS: State N-3
            // HW writes anytime via i_errlog1_wen
            // ─────────────────────────────────
            if (i_errlog1_wen)
                ErrLog1_State_N3_reg <= i_errlog1_state_n3;

            // RW1CS - State Timeout Occurred (bit 8)
            if (i_state_timeout_occurred)
                ErrLog1_State_Timeout_reg <= 1'b1;
            else if (i_write_en && i_addr == ERROR_LOG1_OFFSET && i_data_in[8])
                ErrLog1_State_Timeout_reg <= 1'b0;

            // RW1CS - Sideband Timeout Occurred (bit 9)
            if (i_sideband_timeout_occurred)
                ErrLog1_Sideband_Timeout_reg <= 1'b1;
            else if (i_write_en && i_addr == ERROR_LOG1_OFFSET && i_data_in[9])
                ErrLog1_Sideband_Timeout_reg <= 1'b0;

            // RW1CS - Remote LinkError received (bit 10)
            if (i_remote_linkerror_received)
                ErrLog1_Remote_LinkError_reg <= 1'b1;
            else if (i_write_en && i_addr == ERROR_LOG1_OFFSET && i_data_in[10])
                ErrLog1_Remote_LinkError_reg <= 1'b0;

            // RW1CS - Internal Error (bit 11)
            if (i_phy_internal_error)
                ErrLog1_Internal_Error_reg <= 1'b1;
            else if (i_write_en && i_addr == ERROR_LOG1_OFFSET && i_data_in[11])
                ErrLog1_Internal_Error_reg <= 1'b0;

            // ─────────────────────────────────
            // Runtime Link Test Control (RW)
            // HW clears Start bit via i_rlt_start_clear
            // ─────────────────────────────────
            if (i_rlt_start_clear)
                RLT_Ctrl_Start_reg <= 1'b0;
            else if (i_write_en && i_addr == RLT_CONTROL_OFFSET) begin
                RLT_Ctrl_Reserved_0_reg    <= i_data_in[0];
                RLT_Ctrl_Reserved_1_reg    <= i_data_in[1];
                RLT_Ctrl_Apply_Mod0_reg    <= i_data_in[2];
                RLT_Ctrl_Apply_Mod1_reg    <= i_data_in[3];
                RLT_Ctrl_Apply_Mod2_reg    <= i_data_in[4];
                RLT_Ctrl_Apply_Mod3_reg    <= i_data_in[5];
                RLT_Ctrl_Start_reg         <= i_data_in[6];
                RLT_Ctrl_Inject_Stuck_reg  <= i_data_in[7];
                RLT_Ctrl_Mod0_Lane_ID_reg  <= i_data_in[14:8];
                RLT_Ctrl_Mod1_Lane_ID_reg  <= i_data_in[21:15];
                RLT_Ctrl_Mod2_Lane_ID_reg  <= i_data_in[28:22];
                RLT_Ctrl_Mod3_Lane_ID_reg  <= i_data_in[35:29];
            end

        end
    end

    // ═════════════════════════════════════════
    // Read Logic - combinational
    // ═════════════════════════════════════════
    always_comb begin
        case (i_addr)

            VENDOR_ID_OFFSET:
                o_data_out = {48'h0, Vendor_ID_reg};

            VENDOR_ID_REGISTER_BLOCK_OFFSET:
                o_data_out = {48'h0, Vendor_ID_Register_Block_reg};

            VENDOR_REGISTER_BLOCK_VERSION_OFFSET:
                o_data_out = {60'h0, Vendor_Register_Block_Version_reg};

            VENDOR_REGISTER_BLOCK_LENGTH_OFFSET:
                o_data_out = {32'h0, Vendor_Register_Block_Length_reg};

            UNC_ERR_STATUS_OFFSET:
                o_data_out = {59'h0,
                              Sideband_Non_Fatal_Error_reg,
                              Sideband_Fatal_Error_reg,
                              Internal_Error_reg,
                              Receiver_Overflow_reg,
                              Adapter_Timeout_reg};

            UNC_ERR_MASK_OFFSET:
                o_data_out = {59'h0,
                              Sideband_Non_Fatal_Error_mask_reg,
                              Sideband_Fatal_Error_mask_reg,
                              Internal_Error_mask_reg,
                              Receiver_Overflow_mask_reg,
                              Adapter_Timeout_mask_reg};

            COR_ERR_STATUS_OFFSET:
                o_data_out = {59'h0,
                              Runtime_Link_Testing_Parity_reg,
                              Sideband_Correctable_Error_reg,
                              Correctable_Internal_Error_reg,
                              Adapter_LSM_Retrain_reg,
                              CRC_Error_reg};

            COR_ERR_MASK_OFFSET:
                o_data_out = {59'h0,
                              Runtime_Link_Testing_Parity_mask_reg,
                              Sideband_Correctable_Error_mask_reg,
                              Correctable_Internal_Error_mask_reg,
                              Adapter_LSM_Retrain_mask_reg,
                              CRC_Error_mask_reg};

            HEADER_LOG1_OFFSET:
                o_data_out = Header_Log1_reg;

            HEADER_LOG2_OFFSET:
                o_data_out = {32'h0,
                              9'h0,
                              First_Fatal_Error_Indicator_reg,
                              Flit_Format_reg,
                              Parameter_Exchange_Successful_reg,
                              2'h0,
                              Adapter_LSM_ID_reg,
                              Adapter_LSM_Response_Type_reg,
                              Receiver_Overflow_Encoding_reg,
                              Adapter_Timeout_Encoding_reg};

            ERR_LINK_TEST_CTRL_OFFSET:
                o_data_out = {32'h0,
                              14'h0,
                              CRC_Injection_Busy_reg,
                              CRC_Injection_Count_reg,
                              CRC_Injection_Enable_reg,
                              3'h0,
                              Parity_Feature_Nak_reg,
                              Num_64B_Inserts_reg,
                              RT_Link_Test_Rx_En_reg,
                              RT_Link_Test_Tx_En_reg,
                              Remote_Reg_Access_Threshold_reg};

            PARITY_LOG0_OFFSET:        o_data_out = Parity_Log0_reg;
            PARITY_LOG1_OFFSET:        o_data_out = Parity_Log1_reg;
            PARITY_LOG2_OFFSET:        o_data_out = Parity_Log2_reg;
            PARITY_LOG3_OFFSET:        o_data_out = Parity_Log3_reg;

            ADV_ADAPTER_CAP_OFFSET:    o_data_out = Adv_Adapter_Cap_reg;
            FIN_ADAPTER_CAP_OFFSET:    o_data_out = Fin_Adapter_Cap_reg;
            ADV_CXL_CAP_OFFSET:        o_data_out = Adv_CXL_Cap_reg;
            FIN_CXL_CAP_OFFSET:        o_data_out = Fin_CXL_Cap_reg;
            ADV_MULTIPROTO_CAP_OFFSET: o_data_out = Adv_MultiProto_Cap_reg;
            FIN_MULTIPROTO_CAP_OFFSET: o_data_out = Fin_MultiProto_Cap_reg;
            ADV_CXL_CAP_STACK1_OFFSET: o_data_out = Adv_CXL_Cap_Stack1_reg;
            FIN_CXL_CAP_STACK1_OFFSET: o_data_out = Fin_CXL_Cap_Stack1_reg;

            PHY_CAP_OFFSET:
                o_data_out = {32'h0,
                              14'h0,
                              PHY_Cap_TARR_reg,
                              PHY_Cap_TCM_Support_reg,
                              PHY_Cap_Package_Type_reg,
                              PHY_Cap_RX_Clk_Phase_reg,
                              PHY_Cap_RX_Clk_Mode_reg,
                              1'b0,
                              PHY_Cap_TX_Vswing_reg,
                              PHY_Cap_TXEQ_Support_reg,
                              PHY_Cap_Terminated_Link_reg,
                              3'b000};

            PHY_CTRL_OFFSET:
                o_data_out = {32'h0,
                              10'h0,
                              PHY_Ctrl_TARR_reg,
                              PHY_Ctrl_Force_TX_EQ_Preset_Set_reg,
                              PHY_Ctrl_Force_TX_EQ_Preset_reg,
                              PHY_Ctrl_Force_IQ_Corr_Param_reg,
                              PHY_Ctrl_Force_IQ_Corr_En_reg,
                              PHY_Ctrl_Force_x8_Width_reg,
                              PHY_Ctrl_Force_x32_Width_reg,
                              PHY_Ctrl_RX_Clk_Phase_Sel_reg,
                              PHY_Ctrl_RX_Clk_Mode_Sel_reg,
                              PHY_Ctrl_TX_EQ_En_reg,
                              PHY_Ctrl_RX_Term_Ctrl_reg,
                              PHY_Ctrl_Reserved_2_0_reg};

            PHY_STATUS_OFFSET:
                o_data_out = {32'h0,
                              13'h0,
                              PHY_Stat_TARR_reg,
                              PHY_Stat_EQ_Preset_reg,
                              PHY_Stat_IQ_Corr_Param_reg,
                              PHY_Stat_Lane_Reversal_reg,
                              PHY_Stat_Clk_Phase_reg,
                              PHY_Stat_Clk_Mode_reg,
                              PHY_Stat_TXEQ_reg,
                              PHY_Stat_RX_Term_reg,
                              3'b000};

            PHY_INIT_DEBUG_OFFSET:
                o_data_out = {32'h0,
                              26'h0,
                              PHY_Init_Resume_Training_reg,
                              2'b00,
                              PHY_Init_Ctrl_reg};

            TRAINING_SETUP1_OFFSET:
                o_data_out = {32'h0,
                              5'h0,
                              Train1_Burst_Count_reg,
                              Train1_Training_Mode_reg,
                              Train1_Clk_Phase_Ctrl_reg,
                              Train1_Valid_Pattern_reg,
                              Train1_Data_Pattern_reg};

            TRAINING_SETUP2_OFFSET:
                o_data_out = {32'h0,
                              Train2_Iterations_reg,
                              Train2_Idle_Count_reg};

            TRAINING_SETUP3_OFFSET:
                o_data_out = Train3_Lane_Mask_reg;

            TRAINING_SETUP4_OFFSET:
                o_data_out = {32'h0,
                              Train4_Max_Err_Aggregate_reg,
                              Train4_Max_Err_Per_Lane_reg,
                              Train4_Repair_Lane_Mask_reg};

            CLM_MODULE0_OFFSET:    o_data_out = CLM_Module0_reg;
            CLM_MODULE1_OFFSET:    o_data_out = CLM_Module1_reg;
            CLM_MODULE2_OFFSET:    o_data_out = CLM_Module2_reg;
            CLM_MODULE3_OFFSET:    o_data_out = CLM_Module3_reg;

            ERROR_LOG0_OFFSET:
                o_data_out = {32'h0,
                              ErrLog0_State_N2_reg,
                              ErrLog0_State_N1_reg,
                              6'h0,
                              ErrLog0_Width_Degrade_reg,
                              ErrLog0_Lane_Reversal_reg,
                              ErrLog0_State_N_reg};

            ERROR_LOG1_OFFSET:
                o_data_out = {32'h0,
                              20'h0,
                              ErrLog1_Internal_Error_reg,
                              ErrLog1_Remote_LinkError_reg,
                              ErrLog1_Sideband_Timeout_reg,
                              ErrLog1_State_Timeout_reg,
                              ErrLog1_State_N3_reg};

            RLT_CONTROL_OFFSET:
                o_data_out = {28'h0,
                              RLT_Ctrl_Mod3_Lane_ID_reg,
                              RLT_Ctrl_Mod2_Lane_ID_reg,
                              RLT_Ctrl_Mod1_Lane_ID_reg,
                              RLT_Ctrl_Mod0_Lane_ID_reg,
                              RLT_Ctrl_Inject_Stuck_reg,
                              RLT_Ctrl_Start_reg,
                              RLT_Ctrl_Apply_Mod3_reg,
                              RLT_Ctrl_Apply_Mod2_reg,
                              RLT_Ctrl_Apply_Mod1_reg,
                              RLT_Ctrl_Apply_Mod0_reg,
                              RLT_Ctrl_Reserved_1_reg,
                              RLT_Ctrl_Reserved_0_reg};

            default:
                o_data_out = 64'h0;

        endcase
    end

endmodule
            