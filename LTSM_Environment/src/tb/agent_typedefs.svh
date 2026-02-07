/***********************************************************************
 * Author : Amr El Batarny
 * File   : agent_typedefs.svh
 * Brief  : Shared file encapsulating agent and agent config defined
 *          types.
 **********************************************************************/

event start_monitoring_aes_out;

// Forward declarations needed for typedefs
typedef class agent;
typedef class agent_config;
typedef class APB_driver_1;
typedef class APB_driver_2;
typedef class APB_monitor;
typedef class APB_sequencer;
typedef class APB_sequence_item_1;
typedef class APB_sequence_item_2;
typedef class APB_controller_sequence_item;
typedef class APB_controller_monitor;
typedef class SYSCTRL_sequencer;
typedef class SYSCTRL_driver;
typedef class SYSCTRL_monitor;
typedef class SYSCTRL_sequence_item;
typedef class AES_sequence_item;
typedef class dummy_driver;
typedef class AES_monitor;

typedef agent #(
.CFG_NAME("SYSCTRL_AGT_CFG"),
.AGT_NAME("SYSCTRL_agent"),
.INTF_T(virtual SYSCTRL_bfm),
.SEQR_T(SYSCTRL_sequencer),
.DRVR_T(SYSCTRL_driver),
.MNTR_T(SYSCTRL_monitor),
.ITEM_T(SYSCTRL_sequence_item)
) sysctrl_agt_type;

typedef agent #(
.CFG_NAME("APB_AGT_CFG_1"),
.AGT_NAME("APB_agent_1"),
.INTF_T(virtual APB_bfm),
.SEQR_T(APB_sequencer #(APB_sequence_item_1)),
.DRVR_T(APB_driver_1 #(virtual APB_bfm)),
.MNTR_T(APB_monitor #(APB_sequence_item_1, virtual APB_bfm)),
.ITEM_T(APB_sequence_item_1)
) apb_agt_1_type;

typedef agent #(
.CFG_NAME("APB_AGT_CFG_2"),
.AGT_NAME("APB_agent_2"),
.INTF_T(virtual APB_bfm),
.SEQR_T(APB_sequencer #(APB_sequence_item_2)),
.DRVR_T(APB_driver_2 #(virtual APB_bfm)),
.MNTR_T(APB_monitor #(APB_sequence_item_2, virtual APB_bfm)),
.ITEM_T(APB_sequence_item_2)
) apb_agt_2_type;

typedef agent #(
.CFG_NAME("APB_CTRL_OUT_AGT_CFG_1"),
.AGT_NAME("APB_controller_agent_1"),
.INTF_T(virtual APB_controller_if),
.SEQR_T(APB_sequencer #(APB_controller_sequence_item)),
.DRVR_T(dummy_driver #(APB_controller_sequence_item, virtual APB_controller_if)),
.MNTR_T(APB_controller_monitor),
.ITEM_T(APB_controller_sequence_item)
) apb_controller_agt_1_type;

typedef agent #(
.CFG_NAME("APB_CTRL_OUT_AGT_CFG_2"),
.AGT_NAME("APB_controller_agent_2"),
.INTF_T(virtual APB_controller_if),
.SEQR_T(APB_sequencer #(APB_controller_sequence_item)),
.DRVR_T(dummy_driver #(APB_controller_sequence_item, virtual APB_controller_if)),
.MNTR_T(APB_controller_monitor),
.ITEM_T(APB_controller_sequence_item)
) apb_controller_agt_2_type;

typedef agent #(
.CFG_NAME("AES_OUT_AGT_CFG"),
.AGT_NAME("AES_agent"),
.INTF_T(virtual AES_if),
.SEQR_T(APB_sequencer #(AES_sequence_item)),
.DRVR_T(dummy_driver #(AES_sequence_item, virtual AES_if)),
.MNTR_T(AES_monitor),
.ITEM_T(AES_sequence_item)
) aes_agt_type;

typedef agent_config #(.INTF_T(virtual SYSCTRL_bfm))        sysctrl_cfg_type;
typedef agent_config #(.INTF_T(virtual APB_bfm))            apb_cfg_1_type;
typedef agent_config #(.INTF_T(virtual APB_bfm))            apb_cfg_2_type;
typedef agent_config #(.INTF_T(virtual APB_controller_if))  apb_controller_cfg_type;
typedef agent_config #(.INTF_T(virtual AES_if))             aes_cfg_type;