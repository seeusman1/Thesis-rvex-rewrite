library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity pcie_v2_5_wrap is
  generic (
    PCIE_DRP_ENABLE                              : boolean := FALSE;
    ALLOW_X8_GEN2                                : string  := "FALSE";
    BAR0                                         : bit_vector := X"FFFFFF80";
    BAR1                                         : bit_vector := X"FFFFF800";
    BAR2                                         : bit_vector := X"FFFFFF80";
    BAR3                                         : bit_vector := X"00000000";
    BAR4                                         : bit_vector := X"00000000";
    BAR5                                         : bit_vector := X"00000000";

    CARDBUS_CIS_POINTER                          : bit_vector := X"00000000";
    CLASS_CODE                                   : bit_vector := X"078000";
    CMD_INTX_IMPLEMENTED                         : string     := "TRUE";
    CPL_TIMEOUT_DISABLE_SUPPORTED                : string     := "FALSE";
    CPL_TIMEOUT_RANGES_SUPPORTED                 : bit_vector := X"2";

    DEV_CAP_ENDPOINT_L0S_LATENCY                 : integer    := 7;
    DEV_CAP_ENDPOINT_L1_LATENCY                  : integer    := 7;
    DEV_CAP_EXT_TAG_SUPPORTED                    : string     := "FALSE";
    DEV_CAP_MAX_PAYLOAD_SUPPORTED                : integer    := 2;
    DEV_CAP_PHANTOM_FUNCTIONS_SUPPORT            : integer    := 0;
    DEVICE_ID                                    : bit_vector := X"6024";

    DISABLE_LANE_REVERSAL                        : string     := "TRUE";
    DISABLE_SCRAMBLING                           : string     := "FALSE";
    DSN_BASE_PTR                                 : bit_vector := X"0";
    DSN_CAP_NEXTPTR                              : bit_vector := X"000";
    DSN_CAP_ON                                   : string     := "FALSE";

    ENABLE_MSG_ROUTE                             : bit_vector := "00000000000";
    ENABLE_RX_TD_ECRC_TRIM                       : string     := "FALSE";
    EXPANSION_ROM                                : bit_vector := X"00000000";
    EXT_CFG_CAP_PTR                              : bit_vector := X"3F";
    EXT_CFG_XP_CAP_PTR                           : bit_vector := X"3FF";
    HEADER_TYPE                                  : bit_vector := X"00";
    INTERRUPT_PIN                                : bit_vector := X"1";

    LINK_CAP_DLL_LINK_ACTIVE_REPORTING_CAP       : string     := "FALSE";
    LINK_CAP_LINK_BANDWIDTH_NOTIFICATION_CAP     : string     := "FALSE";
    LINK_CAP_MAX_LINK_SPEED                      : bit_vector := X"2";
    LINK_CAP_MAX_LINK_WIDTH                      : bit_vector := X"04";
    LINK_CAP_MAX_LINK_WIDTH_int                  : integer    := 4;
    LINK_CAP_SURPRISE_DOWN_ERROR_CAPABLE         : string     := "FALSE";

    LINK_CTRL2_DEEMPHASIS                        : string     := "FALSE";
    LINK_CTRL2_HW_AUTONOMOUS_SPEED_DISABLE       : string     := "FALSE";
    LINK_CTRL2_TARGET_LINK_SPEED                 : bit_vector := X"2";
    LINK_STATUS_SLOT_CLOCK_CONFIG                : string     := "TRUE";

    LL_ACK_TIMEOUT                               : bit_vector := X"0000";
    LL_ACK_TIMEOUT_EN                            : string     := "FALSE";
    LL_ACK_TIMEOUT_FUNC                          : integer    := 0;
    LL_REPLAY_TIMEOUT                            : bit_vector := X"0026";
    LL_REPLAY_TIMEOUT_EN                         : string     := "TRUE";
    LL_REPLAY_TIMEOUT_FUNC                       : integer    := 1;

    LTSSM_MAX_LINK_WIDTH                         : bit_vector := X"04";
    MSI_CAP_MULTIMSGCAP                          : integer    := 0;
    MSI_CAP_MULTIMSG_EXTENSION                   : integer    := 0;
    MSI_CAP_ON                                   : string     := "TRUE";
    MSI_CAP_PER_VECTOR_MASKING_CAPABLE           : string     := "FALSE";
    MSI_CAP_64_BIT_ADDR_CAPABLE                  : string     := "TRUE";

    MSIX_CAP_ON                                  : string     := "FALSE";
    MSIX_CAP_PBA_BIR                             : integer    := 0;
    MSIX_CAP_PBA_OFFSET                          : bit_vector := X"0";
    MSIX_CAP_TABLE_BIR                           : integer    := 0;
    MSIX_CAP_TABLE_OFFSET                        : bit_vector := X"0";
    MSIX_CAP_TABLE_SIZE                          : bit_vector := X"0";

    PCIE_CAP_DEVICE_PORT_TYPE                    : bit_vector := X"0";
    PCIE_CAP_INT_MSG_NUM                         : bit_vector := X"1";
    PCIE_CAP_NEXTPTR                             : bit_vector := X"00";
    PIPE_PIPELINE_STAGES                         : integer    := 0;                -- 0 - 0 stages; 1 - 1 stage; 2 - 2 stages

    PM_CAP_DSI                                   : string     := "FALSE";
    PM_CAP_D1SUPPORT                             : string     := "FALSE";
    PM_CAP_D2SUPPORT                             : string     := "FALSE";
    PM_CAP_NEXTPTR                               : bit_vector := X"48";
    PM_CAP_PMESUPPORT                            : bit_vector := X"0F";
    PM_CSR_NOSOFTRST                             : string     := "TRUE";

    PM_DATA_SCALE0                               : bit_vector := X"0";
    PM_DATA_SCALE1                               : bit_vector := X"0";
    PM_DATA_SCALE2                               : bit_vector := X"0";
    PM_DATA_SCALE3                               : bit_vector := X"0";
    PM_DATA_SCALE4                               : bit_vector := X"0";
    PM_DATA_SCALE5                               : bit_vector := X"0";
    PM_DATA_SCALE6                               : bit_vector := X"0";
    PM_DATA_SCALE7                               : bit_vector := X"0";

    PM_DATA0                                     : bit_vector := X"00";
    PM_DATA1                                     : bit_vector := X"00";
    PM_DATA2                                     : bit_vector := X"00";
    PM_DATA3                                     : bit_vector := X"00";
    PM_DATA4                                     : bit_vector := X"00";
    PM_DATA5                                     : bit_vector := X"00";
    PM_DATA6                                     : bit_vector := X"00";
    PM_DATA7                                     : bit_vector := X"00";

    REF_CLK_FREQ                                 : integer    := 2;                        -- 0 - 100 MHz; 1 - 125 MHz; 2 - 250 MHz
    REVISION_ID                                  : bit_vector := X"00";
    SPARE_BIT0                                   : integer    := 0;
    SUBSYSTEM_ID                                 : bit_vector := X"0007";
    SUBSYSTEM_VENDOR_ID                          : bit_vector := X"10EE";

    TL_RX_RAM_RADDR_LATENCY                      : integer    := 0;
    TL_RX_RAM_RDATA_LATENCY                      : integer    := 2;
    TL_RX_RAM_WRITE_LATENCY                      : integer    := 0;
    TL_TX_RAM_RADDR_LATENCY                      : integer    := 0;
    TL_TX_RAM_RDATA_LATENCY                      : integer    := 2;
    TL_TX_RAM_WRITE_LATENCY                      : integer    := 0;

    UPCONFIG_CAPABLE                             : string     := "TRUE";
    USER_CLK_FREQ                                : integer    := 3;
    VC_BASE_PTR                                  : bit_vector := X"0";
    VC_CAP_NEXTPTR                               : bit_vector := X"000";
    VC_CAP_ON                                    : string     := "FALSE";
    VC_CAP_REJECT_SNOOP_TRANSACTIONS             : string     := "FALSE";

    VC0_CPL_INFINITE                             : string     := "TRUE";
    VC0_RX_RAM_LIMIT                             : bit_vector := X"7FF";
    VC0_TOTAL_CREDITS_CD                         : integer    := 308;
    VC0_TOTAL_CREDITS_CH                         : integer    := 36;
    VC0_TOTAL_CREDITS_NPH                        : integer    := 12;
    VC0_TOTAL_CREDITS_PD                         : integer    := 308;
    VC0_TOTAL_CREDITS_PH                         : integer    := 32;
    VC0_TX_LASTPACKET                            : integer    := 29;

    VENDOR_ID                                    : bit_vector := X"10EE";
    VSEC_BASE_PTR                                : bit_vector := X"0";
    VSEC_CAP_NEXTPTR                             : bit_vector := X"000";
    VSEC_CAP_ON                                  : string     := "FALSE";

    AER_BASE_PTR                                 : bit_vector := X"128";
    AER_CAP_ECRC_CHECK_CAPABLE                   : string     := "FALSE";
    AER_CAP_ECRC_GEN_CAPABLE                     : string     := "FALSE";
    AER_CAP_ID                                   : bit_vector := X"0001";
    AER_CAP_INT_MSG_NUM_MSI                      : bit_vector := X"0a";
    AER_CAP_INT_MSG_NUM_MSIX                     : bit_vector := X"15";
    AER_CAP_NEXTPTR                              : bit_vector := X"160";
    AER_CAP_ON                                   : string     := "FALSE";
    AER_CAP_PERMIT_ROOTERR_UPDATE                : string     := "TRUE";
    AER_CAP_VERSION                              : bit_vector := X"1";

    CAPABILITIES_PTR                             : bit_vector := X"40";
    CRM_MODULE_RSTS                              : bit_vector := X"00";
    DEV_CAP_ENABLE_SLOT_PWR_LIMIT_SCALE          : string     := "TRUE";
    DEV_CAP_ENABLE_SLOT_PWR_LIMIT_VALUE          : string     := "TRUE";
    DEV_CAP_FUNCTION_LEVEL_RESET_CAPABLE         : string     := "FALSE";
    DEV_CAP_ROLE_BASED_ERROR                     : string     := "TRUE";
    DEV_CAP_RSVD_14_12                           : integer    := 0;
    DEV_CAP_RSVD_17_16                           : integer    := 0;
    DEV_CAP_RSVD_31_29                           : integer    := 0;
    DEV_CONTROL_AUX_POWER_SUPPORTED              : string     := "FALSE";

    DISABLE_ASPM_L1_TIMER                        : string     := "FALSE";
    DISABLE_BAR_FILTERING                        : string     := "FALSE";
    DISABLE_ID_CHECK                             : string     := "FALSE";
    DISABLE_RX_TC_FILTER                         : string     := "FALSE";
    DNSTREAM_LINK_NUM                            : bit_vector := X"00";

    DSN_CAP_ID                                   : bit_vector := X"0003";
    DSN_CAP_VERSION                              : bit_vector := X"1";
    ENTER_RVRY_EI_L0                             : string     := "TRUE";
    INFER_EI                                     : bit_vector := X"0c";
    IS_SWITCH                                    : string     := "FALSE";

    LAST_CONFIG_DWORD                            : bit_vector := X"3FF";
    LINK_CAP_ASPM_SUPPORT                        : integer    := 1;
    LINK_CAP_CLOCK_POWER_MANAGEMENT              : string     := "FALSE";
    LINK_CAP_L0S_EXIT_LATENCY_COMCLK_GEN1        : integer    := 7;
    LINK_CAP_L0S_EXIT_LATENCY_COMCLK_GEN2        : integer    := 7;
    LINK_CAP_L0S_EXIT_LATENCY_GEN1               : integer    := 7;
    LINK_CAP_L0S_EXIT_LATENCY_GEN2               : integer    := 7;
    LINK_CAP_L1_EXIT_LATENCY_COMCLK_GEN1         : integer    := 7;
    LINK_CAP_L1_EXIT_LATENCY_COMCLK_GEN2         : integer    := 7;
    LINK_CAP_L1_EXIT_LATENCY_GEN1                : integer    := 7;
    LINK_CAP_L1_EXIT_LATENCY_GEN2                : integer    := 7;
    LINK_CAP_RSVD_23_22                          : integer    := 0;
    LINK_CONTROL_RCB                             : integer    := 0;

    MSI_BASE_PTR                                 : bit_vector := X"48";
    MSI_CAP_ID                                   : bit_vector := X"05";
    MSI_CAP_NEXTPTR                              : bit_vector := X"60";
    MSIX_BASE_PTR                                : bit_vector := X"9c";
    MSIX_CAP_ID                                  : bit_vector := X"11";
    MSIX_CAP_NEXTPTR                             : bit_vector := X"00";
    N_FTS_COMCLK_GEN1                            : integer    := 255;
    N_FTS_COMCLK_GEN2                            : integer    := 254;
    N_FTS_GEN1                                   : integer    := 255;
    N_FTS_GEN2                                   : integer    := 255;

    PCIE_BASE_PTR                                : bit_vector := X"60";
    PCIE_CAP_CAPABILITY_ID                       : bit_vector := X"10";
    PCIE_CAP_CAPABILITY_VERSION                  : bit_vector := X"2";
    PCIE_CAP_ON                                  : string     := "TRUE";
    PCIE_CAP_RSVD_15_14                          : integer    := 0;
    PCIE_CAP_SLOT_IMPLEMENTED                    : string     := "FALSE";
    PCIE_REVISION                                : integer    := 2;
    PGL0_LANE                                    : integer    := 0;
    PGL1_LANE                                    : integer    := 1;
    PGL2_LANE                                    : integer    := 2;
    PGL3_LANE                                    : integer    := 3;
    PGL4_LANE                                    : integer    := 4;
    PGL5_LANE                                    : integer    := 5;
    PGL6_LANE                                    : integer    := 6;
    PGL7_LANE                                    : integer    := 7;
    PL_AUTO_CONFIG                               : integer    := 0;
    PL_FAST_TRAIN                                : string     := "FALSE";

    PM_BASE_PTR                                  : bit_vector := X"40";
    PM_CAP_AUXCURRENT                            : integer    := 0;
    PM_CAP_ID                                    : bit_vector := X"01";
    PM_CAP_ON                                    : string     := "TRUE";
    PM_CAP_PME_CLOCK                             : string     := "FALSE";
    PM_CAP_RSVD_04                               : integer    := 0;
    PM_CAP_VERSION                               : integer    := 3;
    PM_CSR_BPCCEN                                : string     := "FALSE";
    PM_CSR_B2B3                                  : string     := "FALSE";

    RECRC_CHK                                    : integer    := 0;
    RECRC_CHK_TRIM                               : string     := "FALSE";
    ROOT_CAP_CRS_SW_VISIBILITY                   : string     := "FALSE";
    SELECT_DLL_IF                                : string     := "FALSE";
    SLOT_CAP_ATT_BUTTON_PRESENT                  : string     := "FALSE";
    SLOT_CAP_ATT_INDICATOR_PRESENT               : string     := "FALSE";
    SLOT_CAP_ELEC_INTERLOCK_PRESENT              : string     := "FALSE";
    SLOT_CAP_HOTPLUG_CAPABLE                     : string     := "FALSE";
    SLOT_CAP_HOTPLUG_SURPRISE                    : string     := "FALSE";
    SLOT_CAP_MRL_SENSOR_PRESENT                  : string     := "FALSE";
    SLOT_CAP_NO_CMD_COMPLETED_SUPPORT            : string     := "FALSE";
    SLOT_CAP_PHYSICAL_SLOT_NUM                   : bit_vector := X"0000";
    SLOT_CAP_POWER_CONTROLLER_PRESENT            : string     := "FALSE";
    SLOT_CAP_POWER_INDICATOR_PRESENT             : string     := "FALSE";
    SLOT_CAP_SLOT_POWER_LIMIT_SCALE              : integer    := 0;
    SLOT_CAP_SLOT_POWER_LIMIT_VALUE              : bit_vector := X"00";
    SPARE_BIT1                                   : integer    := 0;
    SPARE_BIT2                                   : integer    := 0;
    SPARE_BIT3                                   : integer    := 0;
    SPARE_BIT4                                   : integer    := 0;
    SPARE_BIT5                                   : integer    := 0;
    SPARE_BIT6                                   : integer    := 0;
    SPARE_BIT7                                   : integer    := 0;
    SPARE_BIT8                                   : integer    := 0;
    SPARE_BYTE0                                  : bit_vector := X"00";
    SPARE_BYTE1                                  : bit_vector := X"00";
    SPARE_BYTE2                                  : bit_vector := X"00";
    SPARE_BYTE3                                  : bit_vector := X"00";
    SPARE_WORD0                                  : bit_vector := X"00000000";
    SPARE_WORD1                                  : bit_vector := X"00000000";
    SPARE_WORD2                                  : bit_vector := X"00000000";
    SPARE_WORD3                                  : bit_vector := X"00000000";

    TL_RBYPASS                                   : string     := "FALSE";
    TL_TFC_DISABLE                               : string     := "FALSE";
    TL_TX_CHECKS_DISABLE                         : string     := "FALSE";
    EXIT_LOOPBACK_ON_EI                          : string     := "TRUE";
    UPSTREAM_FACING                              : string     := "TRUE";
    UR_INV_REQ                                   : string     := "TRUE";

    VC_CAP_ID                                    : bit_vector := X"0002";
    VC_CAP_VERSION                               : bit_vector := X"1";
    VSEC_CAP_HDR_ID                              : bit_vector := X"1234";
    VSEC_CAP_HDR_LENGTH                          : bit_vector := X"018";
    VSEC_CAP_HDR_REVISION                        : bit_vector := X"1";
    VSEC_CAP_ID                                  : bit_vector := X"000b";
    VSEC_CAP_IS_LINK_VISIBLE                     : string     := "TRUE";
    VSEC_CAP_VERSION                             : bit_vector := X"1"
  );
  port (
    ---------------------------------------------------------
    -- 1. PCI Express (pci_exp) Interface
    ---------------------------------------------------------

    -- Tx
    pci_exp_txp                               : out std_logic_vector((LINK_CAP_MAX_LINK_WIDTH_int - 1) downto 0);
    pci_exp_txn                               : out std_logic_vector((LINK_CAP_MAX_LINK_WIDTH_int - 1) downto 0);

    -- Rx
    pci_exp_rxp                               : in std_logic_vector((LINK_CAP_MAX_LINK_WIDTH_int - 1) downto 0);
    pci_exp_rxn                               : in std_logic_vector((LINK_CAP_MAX_LINK_WIDTH_int - 1) downto 0);

    ---------------------------------------------------------
    -- 2. Transaction (TRN) Interface
    ---------------------------------------------------------

    -- Common
    user_clk_out                              : out std_logic;
    user_reset_out                            : out std_logic;
    user_lnk_up                               : out std_logic;

    -- Tx
    tx_buf_av                                 : out std_logic_vector(5 downto 0);
    tx_err_drop                               : out std_logic;
    tx_cfg_req                                : out std_logic;
    s_axis_tx_tready                          : out std_logic;
    s_axis_tx_tdata                           : in std_logic_vector(63 downto 0);
    s_axis_tx_tkeep                           : in std_logic_vector(7 downto 0);
    s_axis_tx_tuser                           : in std_logic_vector(3 downto 0);
    s_axis_tx_tlast                           : in std_logic;
    s_axis_tx_tvalid                          : in std_logic;

    tx_cfg_gnt                                : in std_logic;

    -- Rx
    m_axis_rx_tdata                           : out std_logic_vector(63 downto 0);
    m_axis_rx_tkeep                           : out std_logic_vector(7 downto 0);
    m_axis_rx_tlast                           : out std_logic;
    m_axis_rx_tvalid                          : out std_logic;
    m_axis_rx_tuser                           : out std_logic_vector(21 downto 0);
    m_axis_rx_tready                          : in std_logic;
    rx_np_ok                                  : in std_logic;

    -- Flow Control
    fc_cpld                                   : out std_logic_vector(11 downto 0);
    fc_cplh                                   : out std_logic_vector(7 downto 0);
    fc_npd                                    : out std_logic_vector(11 downto 0);
    fc_nph                                    : out std_logic_vector(7 downto 0);
    fc_pd                                     : out std_logic_vector(11 downto 0);
    fc_ph                                     : out std_logic_vector(7 downto 0);
    fc_sel                                    : in std_logic_vector(2 downto 0);

    ---------------------------------------------------------
    -- 3. Configuration (CFG) Interface
    ---------------------------------------------------------

    cfg_do                                    : out std_logic_vector(31 downto 0);
    cfg_rd_wr_done                            : out std_logic;
    cfg_di                                    : in std_logic_vector(31 downto 0);
    cfg_byte_en                               : in std_logic_vector(3 downto 0);
    cfg_dwaddr                                : in std_logic_vector(9 downto 0);
    cfg_wr_en                                 : in std_logic;
    cfg_rd_en                                 : in std_logic;

    cfg_err_cor                               : in std_logic;
    cfg_err_ur                                : in std_logic;
    cfg_err_ecrc                              : in std_logic;
    cfg_err_cpl_timeout                       : in std_logic;
    cfg_err_cpl_abort                         : in std_logic;
    cfg_err_cpl_unexpect                      : in std_logic;
    cfg_err_posted                            : in std_logic;
    cfg_err_locked                            : in std_logic;
    cfg_err_tlp_cpl_header                    : in std_logic_vector(47 downto 0);
    cfg_err_cpl_rdy                           : out std_logic;
    cfg_interrupt                             : in std_logic;
    cfg_interrupt_rdy                         : out std_logic;
    cfg_interrupt_assert                      : in std_logic;
    cfg_interrupt_di                          : in std_logic_vector(7 downto 0);
    cfg_interrupt_do                          : out std_logic_vector(7 downto 0);
    cfg_interrupt_mmenable                    : out std_logic_vector(2 downto 0);
    cfg_interrupt_msienable                   : out std_logic;
    cfg_interrupt_msixenable                  : out std_logic;
    cfg_interrupt_msixfm                      : out std_logic;
    cfg_turnoff_ok                            : in std_logic;
    cfg_to_turnoff                            : out std_logic;
    cfg_trn_pending                           : in std_logic;
    cfg_pm_wake                               : in std_logic;
    cfg_bus_number                            : out std_logic_vector(7 downto 0);
    cfg_device_number                         : out std_logic_vector(4 downto 0);
    cfg_function_number                       : out std_logic_vector(2 downto 0);
    cfg_status                                : out std_logic_vector(15 downto 0);
    cfg_command                               : out std_logic_vector(15 downto 0);
    cfg_dstatus                               : out std_logic_vector(15 downto 0);
    cfg_dcommand                              : out std_logic_vector(15 downto 0);
    cfg_lstatus                               : out std_logic_vector(15 downto 0);
    cfg_lcommand                              : out std_logic_vector(15 downto 0);
    cfg_dcommand2                             : out std_logic_vector(15 downto 0);
    cfg_pcie_link_state                       : out std_logic_vector(2 downto 0);
    cfg_dsn                                   : in std_logic_vector(63 downto 0);
    cfg_pmcsr_pme_en                          : out std_logic;
    cfg_pmcsr_pme_status                      : out std_logic;
    cfg_pmcsr_powerstate                      : out std_logic_vector(1 downto 0);

    ---------------------------------------------------------
    -- 4. Physical Layer Control and Status (PL) Interface
    ---------------------------------------------------------

    pl_initial_link_width                     : out std_logic_vector(2 downto 0);
    pl_lane_reversal_mode                     : out std_logic_vector(1 downto 0);
    pl_link_gen2_capable                      : out std_logic;
    pl_link_partner_gen2_supported            : out std_logic;
    pl_link_upcfg_capable                     : out std_logic;
    pl_ltssm_state                            : out std_logic_vector(5 downto 0);
    pl_received_hot_rst                       : out std_logic;
    pl_sel_link_rate                          : out std_logic;
    pl_sel_link_width                         : out std_logic_vector(1 downto 0);
    pl_directed_link_auton                    : in std_logic;
    pl_directed_link_change                   : in std_logic_vector(1 downto 0);
    pl_directed_link_speed                    : in std_logic;
    pl_directed_link_width                    : in std_logic_vector(1 downto 0);
    pl_upstream_prefer_deemph                 : in std_logic;

    ---------------------------------------------------------
    -- 5. System  (SYS) Interface
    ---------------------------------------------------------

    sys_clk                                   : in std_logic;
    sys_reset                                 : in std_logic
  );
end pcie_v2_5_wrap;


architecture behavioral of pcie_v2_5_wrap is

  component pcie_v2_5
    generic (
      PCIE_DRP_ENABLE                              : boolean := FALSE;
      ALLOW_X8_GEN2                                : string  := "FALSE";
      BAR0                                         : bit_vector := X"FFFFFF80";
      BAR1                                         : bit_vector := X"FFFFF800";
      BAR2                                         : bit_vector := X"FFFFFF80";
      BAR3                                         : bit_vector := X"00000000";
      BAR4                                         : bit_vector := X"00000000";
      BAR5                                         : bit_vector := X"00000000";

      CARDBUS_CIS_POINTER                          : bit_vector := X"00000000";
      CLASS_CODE                                   : bit_vector := X"078000";
      CMD_INTX_IMPLEMENTED                         : string     := "TRUE";
      CPL_TIMEOUT_DISABLE_SUPPORTED                : string     := "FALSE";
      CPL_TIMEOUT_RANGES_SUPPORTED                 : bit_vector := X"2";

      DEV_CAP_ENDPOINT_L0S_LATENCY                 : integer    := 7;
      DEV_CAP_ENDPOINT_L1_LATENCY                  : integer    := 7;
      DEV_CAP_EXT_TAG_SUPPORTED                    : string     := "FALSE";
      DEV_CAP_MAX_PAYLOAD_SUPPORTED                : integer    := 2;
      DEV_CAP_PHANTOM_FUNCTIONS_SUPPORT            : integer    := 0;
      DEVICE_ID                                    : bit_vector := X"6024";

      DISABLE_LANE_REVERSAL                        : string     := "TRUE";
      DISABLE_SCRAMBLING                           : string     := "FALSE";
      DSN_BASE_PTR                                 : bit_vector := X"0";
      DSN_CAP_NEXTPTR                              : bit_vector := X"000";
      DSN_CAP_ON                                   : string     := "FALSE";

      ENABLE_MSG_ROUTE                             : bit_vector := "00000000000";
      ENABLE_RX_TD_ECRC_TRIM                       : string     := "FALSE";
      EXPANSION_ROM                                : bit_vector := X"00000000";
      EXT_CFG_CAP_PTR                              : bit_vector := X"3F";
      EXT_CFG_XP_CAP_PTR                           : bit_vector := X"3FF";
      HEADER_TYPE                                  : bit_vector := X"00";
      INTERRUPT_PIN                                : bit_vector := X"1";

      LINK_CAP_DLL_LINK_ACTIVE_REPORTING_CAP       : string     := "FALSE";
      LINK_CAP_LINK_BANDWIDTH_NOTIFICATION_CAP     : string     := "FALSE";
      LINK_CAP_MAX_LINK_SPEED                      : bit_vector := X"2";
      LINK_CAP_MAX_LINK_WIDTH                      : bit_vector := X"04";
      LINK_CAP_SURPRISE_DOWN_ERROR_CAPABLE         : string     := "FALSE";

      LINK_CTRL2_DEEMPHASIS                        : string     := "FALSE";
      LINK_CTRL2_HW_AUTONOMOUS_SPEED_DISABLE       : string     := "FALSE";
      LINK_CTRL2_TARGET_LINK_SPEED                 : bit_vector := X"2";
      LINK_STATUS_SLOT_CLOCK_CONFIG                : string     := "TRUE";

      LL_ACK_TIMEOUT                               : bit_vector := X"0000";
      LL_ACK_TIMEOUT_EN                            : string     := "FALSE";
      LL_ACK_TIMEOUT_FUNC                          : integer    := 0;
      LL_REPLAY_TIMEOUT                            : bit_vector := X"0026";
      LL_REPLAY_TIMEOUT_EN                         : string     := "TRUE";
      LL_REPLAY_TIMEOUT_FUNC                       : integer    := 1;

      LTSSM_MAX_LINK_WIDTH                         : bit_vector := X"04";
      MSI_CAP_MULTIMSGCAP                          : integer    := 0;
      MSI_CAP_MULTIMSG_EXTENSION                   : integer    := 0;
      MSI_CAP_ON                                   : string     := "TRUE";
      MSI_CAP_PER_VECTOR_MASKING_CAPABLE           : string     := "FALSE";
      MSI_CAP_64_BIT_ADDR_CAPABLE                  : string     := "TRUE";

      MSIX_CAP_ON                                  : string     := "FALSE";
      MSIX_CAP_PBA_BIR                             : integer    := 0;
      MSIX_CAP_PBA_OFFSET                          : bit_vector := X"0";
      MSIX_CAP_TABLE_BIR                           : integer    := 0;
      MSIX_CAP_TABLE_OFFSET                        : bit_vector := X"0";
      MSIX_CAP_TABLE_SIZE                          : bit_vector := X"0";

      PCIE_CAP_DEVICE_PORT_TYPE                    : bit_vector := X"0";
      PCIE_CAP_INT_MSG_NUM                         : bit_vector := X"1";
      PCIE_CAP_NEXTPTR                             : bit_vector := X"00";
      PIPE_PIPELINE_STAGES                         : integer    := 0;                -- 0 - 0 stages; 1 - 1 stage; 2 - 2 stages

      PM_CAP_DSI                                   : string     := "FALSE";
      PM_CAP_D1SUPPORT                             : string     := "FALSE";
      PM_CAP_D2SUPPORT                             : string     := "FALSE";
      PM_CAP_NEXTPTR                               : bit_vector := X"48";
      PM_CAP_PMESUPPORT                            : bit_vector := X"0F";
      PM_CSR_NOSOFTRST                             : string     := "TRUE";

      PM_DATA_SCALE0                               : bit_vector := X"0";
      PM_DATA_SCALE1                               : bit_vector := X"0";
      PM_DATA_SCALE2                               : bit_vector := X"0";
      PM_DATA_SCALE3                               : bit_vector := X"0";
      PM_DATA_SCALE4                               : bit_vector := X"0";
      PM_DATA_SCALE5                               : bit_vector := X"0";
      PM_DATA_SCALE6                               : bit_vector := X"0";
      PM_DATA_SCALE7                               : bit_vector := X"0";

      PM_DATA0                                     : bit_vector := X"00";
      PM_DATA1                                     : bit_vector := X"00";
      PM_DATA2                                     : bit_vector := X"00";
      PM_DATA3                                     : bit_vector := X"00";
      PM_DATA4                                     : bit_vector := X"00";
      PM_DATA5                                     : bit_vector := X"00";
      PM_DATA6                                     : bit_vector := X"00";
      PM_DATA7                                     : bit_vector := X"00";

      REF_CLK_FREQ                                 : integer    := 2;                        -- 0 - 100 MHz; 1 - 125 MHz; 2 - 250 MHz
      REVISION_ID                                  : bit_vector := X"00";
      SPARE_BIT0                                   : integer    := 0;
      SUBSYSTEM_ID                                 : bit_vector := X"0007";
      SUBSYSTEM_VENDOR_ID                          : bit_vector := X"10EE";

      TL_RX_RAM_RADDR_LATENCY                      : integer    := 0;
      TL_RX_RAM_RDATA_LATENCY                      : integer    := 2;
      TL_RX_RAM_WRITE_LATENCY                      : integer    := 0;
      TL_TX_RAM_RADDR_LATENCY                      : integer    := 0;
      TL_TX_RAM_RDATA_LATENCY                      : integer    := 2;
      TL_TX_RAM_WRITE_LATENCY                      : integer    := 0;

      UPCONFIG_CAPABLE                             : string     := "TRUE";
      USER_CLK_FREQ                                : integer    := 3;
      VC_BASE_PTR                                  : bit_vector := X"0";
      VC_CAP_NEXTPTR                               : bit_vector := X"000";
      VC_CAP_ON                                    : string     := "FALSE";
      VC_CAP_REJECT_SNOOP_TRANSACTIONS             : string     := "FALSE";

      VC0_CPL_INFINITE                             : string     := "TRUE";
      VC0_RX_RAM_LIMIT                             : bit_vector := X"7FF";
      VC0_TOTAL_CREDITS_CD                         : integer    := 308;
      VC0_TOTAL_CREDITS_CH                         : integer    := 36;
      VC0_TOTAL_CREDITS_NPH                        : integer    := 12;
      VC0_TOTAL_CREDITS_PD                         : integer    := 308;
      VC0_TOTAL_CREDITS_PH                         : integer    := 32;
      VC0_TX_LASTPACKET                            : integer    := 29;

      VENDOR_ID                                    : bit_vector := X"10EE";
      VSEC_BASE_PTR                                : bit_vector := X"0";
      VSEC_CAP_NEXTPTR                             : bit_vector := X"000";
      VSEC_CAP_ON                                  : string     := "FALSE";

      AER_BASE_PTR                                 : bit_vector := X"128";
      AER_CAP_ECRC_CHECK_CAPABLE                   : string     := "FALSE";
      AER_CAP_ECRC_GEN_CAPABLE                     : string     := "FALSE";
      AER_CAP_ID                                   : bit_vector := X"0001";
      AER_CAP_INT_MSG_NUM_MSI                      : bit_vector := X"0a";
      AER_CAP_INT_MSG_NUM_MSIX                     : bit_vector := X"15";
      AER_CAP_NEXTPTR                              : bit_vector := X"160";
      AER_CAP_ON                                   : string     := "FALSE";
      AER_CAP_PERMIT_ROOTERR_UPDATE                : string     := "TRUE";
      AER_CAP_VERSION                              : bit_vector := X"1";

      CAPABILITIES_PTR                             : bit_vector := X"40";
      CRM_MODULE_RSTS                              : bit_vector := X"00";
      DEV_CAP_ENABLE_SLOT_PWR_LIMIT_SCALE          : string     := "TRUE";
      DEV_CAP_ENABLE_SLOT_PWR_LIMIT_VALUE          : string     := "TRUE";
      DEV_CAP_FUNCTION_LEVEL_RESET_CAPABLE         : string     := "FALSE";
      DEV_CAP_ROLE_BASED_ERROR                     : string     := "TRUE";
      DEV_CAP_RSVD_14_12                           : integer    := 0;
      DEV_CAP_RSVD_17_16                           : integer    := 0;
      DEV_CAP_RSVD_31_29                           : integer    := 0;
      DEV_CONTROL_AUX_POWER_SUPPORTED              : string     := "FALSE";

      DISABLE_ASPM_L1_TIMER                        : string     := "FALSE";
      DISABLE_BAR_FILTERING                        : string     := "FALSE";
      DISABLE_ID_CHECK                             : string     := "FALSE";
      DISABLE_RX_TC_FILTER                         : string     := "FALSE";
      DNSTREAM_LINK_NUM                            : bit_vector := X"00";

      DSN_CAP_ID                                   : bit_vector := X"0003";
      DSN_CAP_VERSION                              : bit_vector := X"1";
      ENTER_RVRY_EI_L0                             : string     := "TRUE";
      INFER_EI                                     : bit_vector := X"0c";
      IS_SWITCH                                    : string     := "FALSE";

      LAST_CONFIG_DWORD                            : bit_vector := X"3FF";
      LINK_CAP_ASPM_SUPPORT                        : integer    := 1;
      LINK_CAP_CLOCK_POWER_MANAGEMENT              : string     := "FALSE";
      LINK_CAP_L0S_EXIT_LATENCY_COMCLK_GEN1        : integer    := 7;
      LINK_CAP_L0S_EXIT_LATENCY_COMCLK_GEN2        : integer    := 7;
      LINK_CAP_L0S_EXIT_LATENCY_GEN1               : integer    := 7;
      LINK_CAP_L0S_EXIT_LATENCY_GEN2               : integer    := 7;
      LINK_CAP_L1_EXIT_LATENCY_COMCLK_GEN1         : integer    := 7;
      LINK_CAP_L1_EXIT_LATENCY_COMCLK_GEN2         : integer    := 7;
      LINK_CAP_L1_EXIT_LATENCY_GEN1                : integer    := 7;
      LINK_CAP_L1_EXIT_LATENCY_GEN2                : integer    := 7;
      LINK_CAP_RSVD_23_22                          : integer    := 0;
      LINK_CONTROL_RCB                             : integer    := 0;

      MSI_BASE_PTR                                 : bit_vector := X"48";
      MSI_CAP_ID                                   : bit_vector := X"05";
      MSI_CAP_NEXTPTR                              : bit_vector := X"60";
      MSIX_BASE_PTR                                : bit_vector := X"9c";
      MSIX_CAP_ID                                  : bit_vector := X"11";
      MSIX_CAP_NEXTPTR                             : bit_vector := X"00";
      N_FTS_COMCLK_GEN1                            : integer    := 255;
      N_FTS_COMCLK_GEN2                            : integer    := 254;
      N_FTS_GEN1                                   : integer    := 255;
      N_FTS_GEN2                                   : integer    := 255;

      PCIE_BASE_PTR                                : bit_vector := X"60";
      PCIE_CAP_CAPABILITY_ID                       : bit_vector := X"10";
      PCIE_CAP_CAPABILITY_VERSION                  : bit_vector := X"2";
      PCIE_CAP_ON                                  : string     := "TRUE";
      PCIE_CAP_RSVD_15_14                          : integer    := 0;
      PCIE_CAP_SLOT_IMPLEMENTED                    : string     := "FALSE";
      PCIE_REVISION                                : integer    := 2;
      PGL0_LANE                                    : integer    := 0;
      PGL1_LANE                                    : integer    := 1;
      PGL2_LANE                                    : integer    := 2;
      PGL3_LANE                                    : integer    := 3;
      PGL4_LANE                                    : integer    := 4;
      PGL5_LANE                                    : integer    := 5;
      PGL6_LANE                                    : integer    := 6;
      PGL7_LANE                                    : integer    := 7;
      PL_AUTO_CONFIG                               : integer    := 0;
      PL_FAST_TRAIN                                : string     := "FALSE";

      PM_BASE_PTR                                  : bit_vector := X"40";
      PM_CAP_AUXCURRENT                            : integer    := 0;
      PM_CAP_ID                                    : bit_vector := X"01";
      PM_CAP_ON                                    : string     := "TRUE";
      PM_CAP_PME_CLOCK                             : string     := "FALSE";
      PM_CAP_RSVD_04                               : integer    := 0;
      PM_CAP_VERSION                               : integer    := 3;
      PM_CSR_BPCCEN                                : string     := "FALSE";
      PM_CSR_B2B3                                  : string     := "FALSE";

      RECRC_CHK                                    : integer    := 0;
      RECRC_CHK_TRIM                               : string     := "FALSE";
      ROOT_CAP_CRS_SW_VISIBILITY                   : string     := "FALSE";
      SELECT_DLL_IF                                : string     := "FALSE";
      SLOT_CAP_ATT_BUTTON_PRESENT                  : string     := "FALSE";
      SLOT_CAP_ATT_INDICATOR_PRESENT               : string     := "FALSE";
      SLOT_CAP_ELEC_INTERLOCK_PRESENT              : string     := "FALSE";
      SLOT_CAP_HOTPLUG_CAPABLE                     : string     := "FALSE";
      SLOT_CAP_HOTPLUG_SURPRISE                    : string     := "FALSE";
      SLOT_CAP_MRL_SENSOR_PRESENT                  : string     := "FALSE";
      SLOT_CAP_NO_CMD_COMPLETED_SUPPORT            : string     := "FALSE";
      SLOT_CAP_PHYSICAL_SLOT_NUM                   : bit_vector := X"0000";
      SLOT_CAP_POWER_CONTROLLER_PRESENT            : string     := "FALSE";
      SLOT_CAP_POWER_INDICATOR_PRESENT             : string     := "FALSE";
      SLOT_CAP_SLOT_POWER_LIMIT_SCALE              : integer    := 0;
      SLOT_CAP_SLOT_POWER_LIMIT_VALUE              : bit_vector := X"00";
      SPARE_BIT1                                   : integer    := 0;
      SPARE_BIT2                                   : integer    := 0;
      SPARE_BIT3                                   : integer    := 0;
      SPARE_BIT4                                   : integer    := 0;
      SPARE_BIT5                                   : integer    := 0;
      SPARE_BIT6                                   : integer    := 0;
      SPARE_BIT7                                   : integer    := 0;
      SPARE_BIT8                                   : integer    := 0;
      SPARE_BYTE0                                  : bit_vector := X"00";
      SPARE_BYTE1                                  : bit_vector := X"00";
      SPARE_BYTE2                                  : bit_vector := X"00";
      SPARE_BYTE3                                  : bit_vector := X"00";
      SPARE_WORD0                                  : bit_vector := X"00000000";
      SPARE_WORD1                                  : bit_vector := X"00000000";
      SPARE_WORD2                                  : bit_vector := X"00000000";
      SPARE_WORD3                                  : bit_vector := X"00000000";

      TL_RBYPASS                                   : string     := "FALSE";
      TL_TFC_DISABLE                               : string     := "FALSE";
      TL_TX_CHECKS_DISABLE                         : string     := "FALSE";
      EXIT_LOOPBACK_ON_EI                          : string     := "TRUE";
      UPSTREAM_FACING                              : string     := "TRUE";
      UR_INV_REQ                                   : string     := "TRUE";

      VC_CAP_ID                                    : bit_vector := X"0002";
      VC_CAP_VERSION                               : bit_vector := X"1";
      VSEC_CAP_HDR_ID                              : bit_vector := X"1234";
      VSEC_CAP_HDR_LENGTH                          : bit_vector := X"018";
      VSEC_CAP_HDR_REVISION                        : bit_vector := X"1";
      VSEC_CAP_ID                                  : bit_vector := X"000b";
      VSEC_CAP_IS_LINK_VISIBLE                     : string     := "TRUE";
      VSEC_CAP_VERSION                             : bit_vector := X"1"
    );
    port (
      ---------------------------------------------------------
      -- 1. PCI Express (pci_exp) Interface
      ---------------------------------------------------------

      -- Tx
      pci_exp_txp                               : out std_logic_vector((LINK_CAP_MAX_LINK_WIDTH_int - 1) downto 0);
      pci_exp_txn                               : out std_logic_vector((LINK_CAP_MAX_LINK_WIDTH_int - 1) downto 0);

      -- Rx
      pci_exp_rxp                               : in std_logic_vector((LINK_CAP_MAX_LINK_WIDTH_int - 1) downto 0);
      pci_exp_rxn                               : in std_logic_vector((LINK_CAP_MAX_LINK_WIDTH_int - 1) downto 0);

      ---------------------------------------------------------
      -- 2. Transaction (TRN) Interface
      ---------------------------------------------------------

      -- Common
      user_clk_out                              : out std_logic;
      user_reset_out                            : out std_logic;
      user_lnk_up                               : out std_logic;

      -- Tx
      tx_buf_av                                 : out std_logic_vector(5 downto 0);
      tx_err_drop                               : out std_logic;
      tx_cfg_req                                : out std_logic;
      s_axis_tx_tready                          : out std_logic;
      s_axis_tx_tdata                           : in std_logic_vector(63 downto 0);
      s_axis_tx_tkeep                           : in std_logic_vector(7 downto 0);
      s_axis_tx_tuser                           : in std_logic_vector(3 downto 0);
      s_axis_tx_tlast                           : in std_logic;
      s_axis_tx_tvalid                          : in std_logic;

      tx_cfg_gnt                                : in std_logic;

      -- Rx
      m_axis_rx_tdata                           : out std_logic_vector(63 downto 0);
      m_axis_rx_tkeep                           : out std_logic_vector(7 downto 0);
      m_axis_rx_tlast                           : out std_logic;
      m_axis_rx_tvalid                          : out std_logic;
      m_axis_rx_tuser                           : out std_logic_vector(21 downto 0);
      m_axis_rx_tready                          : in std_logic;
      rx_np_ok                                  : in std_logic;

      -- Flow Control
      fc_cpld                                   : out std_logic_vector(11 downto 0);
      fc_cplh                                   : out std_logic_vector(7 downto 0);
      fc_npd                                    : out std_logic_vector(11 downto 0);
      fc_nph                                    : out std_logic_vector(7 downto 0);
      fc_pd                                     : out std_logic_vector(11 downto 0);
      fc_ph                                     : out std_logic_vector(7 downto 0);
      fc_sel                                    : in std_logic_vector(2 downto 0);

      ---------------------------------------------------------
      -- 3. Configuration (CFG) Interface
      ---------------------------------------------------------

      cfg_do                                    : out std_logic_vector(31 downto 0);
      cfg_rd_wr_done                            : out std_logic;
      cfg_di                                    : in std_logic_vector(31 downto 0);
      cfg_byte_en                               : in std_logic_vector(3 downto 0);
      cfg_dwaddr                                : in std_logic_vector(9 downto 0);
      cfg_wr_en                                 : in std_logic;
      cfg_rd_en                                 : in std_logic;

      cfg_err_cor                               : in std_logic;
      cfg_err_ur                                : in std_logic;
      cfg_err_ecrc                              : in std_logic;
      cfg_err_cpl_timeout                       : in std_logic;
      cfg_err_cpl_abort                         : in std_logic;
      cfg_err_cpl_unexpect                      : in std_logic;
      cfg_err_posted                            : in std_logic;
      cfg_err_locked                            : in std_logic;
      cfg_err_tlp_cpl_header                    : in std_logic_vector(47 downto 0);
      cfg_err_cpl_rdy                           : out std_logic;
      cfg_interrupt                             : in std_logic;
      cfg_interrupt_rdy                         : out std_logic;
      cfg_interrupt_assert                      : in std_logic;
      cfg_interrupt_di                          : in std_logic_vector(7 downto 0);
      cfg_interrupt_do                          : out std_logic_vector(7 downto 0);
      cfg_interrupt_mmenable                    : out std_logic_vector(2 downto 0);
      cfg_interrupt_msienable                   : out std_logic;
      cfg_interrupt_msixenable                  : out std_logic;
      cfg_interrupt_msixfm                      : out std_logic;
      cfg_turnoff_ok                            : in std_logic;
      cfg_to_turnoff                            : out std_logic;
      cfg_trn_pending                           : in std_logic;
      cfg_pm_wake                               : in std_logic;
      cfg_bus_number                            : out std_logic_vector(7 downto 0);
      cfg_device_number                         : out std_logic_vector(4 downto 0);
      cfg_function_number                       : out std_logic_vector(2 downto 0);
      cfg_status                                : out std_logic_vector(15 downto 0);
      cfg_command                               : out std_logic_vector(15 downto 0);
      cfg_dstatus                               : out std_logic_vector(15 downto 0);
      cfg_dcommand                              : out std_logic_vector(15 downto 0);
      cfg_lstatus                               : out std_logic_vector(15 downto 0);
      cfg_lcommand                              : out std_logic_vector(15 downto 0);
      cfg_dcommand2                             : out std_logic_vector(15 downto 0);
      cfg_pcie_link_state                       : out std_logic_vector(2 downto 0);
      cfg_dsn                                   : in std_logic_vector(63 downto 0);
      cfg_pmcsr_pme_en                          : out std_logic;
      cfg_pmcsr_pme_status                      : out std_logic;
      cfg_pmcsr_powerstate                      : out std_logic_vector(1 downto 0);

      ---------------------------------------------------------
      -- 4. Physical Layer Control and Status (PL) Interface
      ---------------------------------------------------------

      pl_initial_link_width                     : out std_logic_vector(2 downto 0);
      pl_lane_reversal_mode                     : out std_logic_vector(1 downto 0);
      pl_link_gen2_capable                      : out std_logic;
      pl_link_partner_gen2_supported            : out std_logic;
      pl_link_upcfg_capable                     : out std_logic;
      pl_ltssm_state                            : out std_logic_vector(5 downto 0);
      pl_received_hot_rst                       : out std_logic;
      pl_sel_link_rate                          : out std_logic;
      pl_sel_link_width                         : out std_logic_vector(1 downto 0);
      pl_directed_link_auton                    : in std_logic;
      pl_directed_link_change                   : in std_logic_vector(1 downto 0);
      pl_directed_link_speed                    : in std_logic;
      pl_directed_link_width                    : in std_logic_vector(1 downto 0);
      pl_upstream_prefer_deemph                 : in std_logic;

      ---------------------------------------------------------
      -- 5. System  (SYS) Interface
      ---------------------------------------------------------

      sys_clk                                   : in std_logic;
      sys_reset                                 : in std_logic
    );
  end component;

begin
  comp: pcie_v2_5
    generic map (
      PCIE_DRP_ENABLE                              => PCIE_DRP_ENABLE,
      ALLOW_X8_GEN2                                => ALLOW_X8_GEN2,
      BAR0                                         => BAR0,
      BAR1                                         => BAR1,
      BAR2                                         => BAR2,
      BAR3                                         => BAR3,
      BAR4                                         => BAR4,
      BAR5                                         => BAR5,

      CARDBUS_CIS_POINTER                          => CARDBUS_CIS_POINTER,
      CLASS_CODE                                   => CLASS_CODE,
      CMD_INTX_IMPLEMENTED                         => CMD_INTX_IMPLEMENTED,
      CPL_TIMEOUT_DISABLE_SUPPORTED                => CPL_TIMEOUT_DISABLE_SUPPORTED,
      CPL_TIMEOUT_RANGES_SUPPORTED                 => CPL_TIMEOUT_RANGES_SUPPORTED,

      DEV_CAP_ENDPOINT_L0S_LATENCY                 => DEV_CAP_ENDPOINT_L0S_LATENCY,
      DEV_CAP_ENDPOINT_L1_LATENCY                  => DEV_CAP_ENDPOINT_L1_LATENCY,
      DEV_CAP_EXT_TAG_SUPPORTED                    => DEV_CAP_EXT_TAG_SUPPORTED,
      DEV_CAP_MAX_PAYLOAD_SUPPORTED                => DEV_CAP_MAX_PAYLOAD_SUPPORTED,
      DEV_CAP_PHANTOM_FUNCTIONS_SUPPORT            => DEV_CAP_PHANTOM_FUNCTIONS_SUPPORT,
      DEVICE_ID                                    => DEVICE_ID,

      DISABLE_LANE_REVERSAL                        => DISABLE_LANE_REVERSAL,
      DISABLE_SCRAMBLING                           => DISABLE_SCRAMBLING,
      DSN_BASE_PTR                                 => DSN_BASE_PTR,
      DSN_CAP_NEXTPTR                              => DSN_CAP_NEXTPTR,
      DSN_CAP_ON                                   => DSN_CAP_ON,

      ENABLE_MSG_ROUTE                             => ENABLE_MSG_ROUTE,
      ENABLE_RX_TD_ECRC_TRIM                       => ENABLE_RX_TD_ECRC_TRIM,
      EXPANSION_ROM                                => EXPANSION_ROM,
      EXT_CFG_CAP_PTR                              => EXT_CFG_CAP_PTR,
      EXT_CFG_XP_CAP_PTR                           => EXT_CFG_XP_CAP_PTR,
      HEADER_TYPE                                  => HEADER_TYPE,
      INTERRUPT_PIN                                => INTERRUPT_PIN,

      LINK_CAP_DLL_LINK_ACTIVE_REPORTING_CAP       => LINK_CAP_DLL_LINK_ACTIVE_REPORTING_CAP,
      LINK_CAP_LINK_BANDWIDTH_NOTIFICATION_CAP     => LINK_CAP_LINK_BANDWIDTH_NOTIFICATION_CAP,
      LINK_CAP_MAX_LINK_SPEED                      => LINK_CAP_MAX_LINK_SPEED,
      LINK_CAP_MAX_LINK_WIDTH                      => LINK_CAP_MAX_LINK_WIDTH,
      LINK_CAP_SURPRISE_DOWN_ERROR_CAPABLE         => LINK_CAP_SURPRISE_DOWN_ERROR_CAPABLE,

      LINK_CTRL2_DEEMPHASIS                        => LINK_CTRL2_DEEMPHASIS,
      LINK_CTRL2_HW_AUTONOMOUS_SPEED_DISABLE       => LINK_CTRL2_HW_AUTONOMOUS_SPEED_DISABLE,
      LINK_CTRL2_TARGET_LINK_SPEED                 => LINK_CTRL2_TARGET_LINK_SPEED,
      LINK_STATUS_SLOT_CLOCK_CONFIG                => LINK_STATUS_SLOT_CLOCK_CONFIG,

      LL_ACK_TIMEOUT                               => LL_ACK_TIMEOUT,
      LL_ACK_TIMEOUT_EN                            => LL_ACK_TIMEOUT_EN,
      LL_ACK_TIMEOUT_FUNC                          => LL_ACK_TIMEOUT_FUNC,
      LL_REPLAY_TIMEOUT                            => LL_REPLAY_TIMEOUT,
      LL_REPLAY_TIMEOUT_EN                         => LL_REPLAY_TIMEOUT_EN,
      LL_REPLAY_TIMEOUT_FUNC                       => LL_REPLAY_TIMEOUT_FUNC,

      LTSSM_MAX_LINK_WIDTH                         => LTSSM_MAX_LINK_WIDTH,
      MSI_CAP_MULTIMSGCAP                          => MSI_CAP_MULTIMSGCAP,
      MSI_CAP_MULTIMSG_EXTENSION                   => MSI_CAP_MULTIMSG_EXTENSION,
      MSI_CAP_ON                                   => MSI_CAP_ON,
      MSI_CAP_PER_VECTOR_MASKING_CAPABLE           => MSI_CAP_PER_VECTOR_MASKING_CAPABLE,
      MSI_CAP_64_BIT_ADDR_CAPABLE                  => MSI_CAP_64_BIT_ADDR_CAPABLE,

      MSIX_CAP_ON                                  => MSIX_CAP_ON,
      MSIX_CAP_PBA_BIR                             => MSIX_CAP_PBA_BIR,
      MSIX_CAP_PBA_OFFSET                          => MSIX_CAP_PBA_OFFSET,
      MSIX_CAP_TABLE_BIR                           => MSIX_CAP_TABLE_BIR,
      MSIX_CAP_TABLE_OFFSET                        => MSIX_CAP_TABLE_OFFSET,
      MSIX_CAP_TABLE_SIZE                          => MSIX_CAP_TABLE_SIZE,

      PCIE_CAP_DEVICE_PORT_TYPE                    => PCIE_CAP_DEVICE_PORT_TYPE,
      PCIE_CAP_INT_MSG_NUM                         => PCIE_CAP_INT_MSG_NUM,
      PCIE_CAP_NEXTPTR                             => PCIE_CAP_NEXTPTR,
      PIPE_PIPELINE_STAGES                         => PIPE_PIPELINE_STAGES,

      PM_CAP_DSI                                   => PM_CAP_DSI,
      PM_CAP_D1SUPPORT                             => PM_CAP_D1SUPPORT,
      PM_CAP_D2SUPPORT                             => PM_CAP_D2SUPPORT,
      PM_CAP_NEXTPTR                               => PM_CAP_NEXTPTR,
      PM_CAP_PMESUPPORT                            => PM_CAP_PMESUPPORT,
      PM_CSR_NOSOFTRST                             => PM_CSR_NOSOFTRST,

      PM_DATA_SCALE0                               => PM_DATA_SCALE0,
      PM_DATA_SCALE1                               => PM_DATA_SCALE1,
      PM_DATA_SCALE2                               => PM_DATA_SCALE2,
      PM_DATA_SCALE3                               => PM_DATA_SCALE3,
      PM_DATA_SCALE4                               => PM_DATA_SCALE4,
      PM_DATA_SCALE5                               => PM_DATA_SCALE5,
      PM_DATA_SCALE6                               => PM_DATA_SCALE6,
      PM_DATA_SCALE7                               => PM_DATA_SCALE7,

      PM_DATA0                                     => PM_DATA0,
      PM_DATA1                                     => PM_DATA1,
      PM_DATA2                                     => PM_DATA2,
      PM_DATA3                                     => PM_DATA3,
      PM_DATA4                                     => PM_DATA4,
      PM_DATA5                                     => PM_DATA5,
      PM_DATA6                                     => PM_DATA6,
      PM_DATA7                                     => PM_DATA7,

      REF_CLK_FREQ                                 => REF_CLK_FREQ,
      REVISION_ID                                  => REVISION_ID,
      SPARE_BIT0                                   => SPARE_BIT0,
      SUBSYSTEM_ID                                 => SUBSYSTEM_ID,
      SUBSYSTEM_VENDOR_ID                          => SUBSYSTEM_VENDOR_ID,

      TL_RX_RAM_RADDR_LATENCY                      => TL_RX_RAM_RADDR_LATENCY,
      TL_RX_RAM_RDATA_LATENCY                      => TL_RX_RAM_RDATA_LATENCY,
      TL_RX_RAM_WRITE_LATENCY                      => TL_RX_RAM_WRITE_LATENCY,
      TL_TX_RAM_RADDR_LATENCY                      => TL_TX_RAM_RADDR_LATENCY,
      TL_TX_RAM_RDATA_LATENCY                      => TL_TX_RAM_RDATA_LATENCY,
      TL_TX_RAM_WRITE_LATENCY                      => TL_TX_RAM_WRITE_LATENCY,

      UPCONFIG_CAPABLE                             => UPCONFIG_CAPABLE,
      USER_CLK_FREQ                                => USER_CLK_FREQ,
      VC_BASE_PTR                                  => VC_BASE_PTR,
      VC_CAP_NEXTPTR                               => VC_CAP_NEXTPTR,
      VC_CAP_ON                                    => VC_CAP_ON,
      VC_CAP_REJECT_SNOOP_TRANSACTIONS             => VC_CAP_REJECT_SNOOP_TRANSACTIONS,

      VC0_CPL_INFINITE                             => VC0_CPL_INFINITE,
      VC0_RX_RAM_LIMIT                             => VC0_RX_RAM_LIMIT,
      VC0_TOTAL_CREDITS_CD                         => VC0_TOTAL_CREDITS_CD,
      VC0_TOTAL_CREDITS_CH                         => VC0_TOTAL_CREDITS_CH,
      VC0_TOTAL_CREDITS_NPH                        => VC0_TOTAL_CREDITS_NPH,
      VC0_TOTAL_CREDITS_PD                         => VC0_TOTAL_CREDITS_PD,
      VC0_TOTAL_CREDITS_PH                         => VC0_TOTAL_CREDITS_PH,
      VC0_TX_LASTPACKET                            => VC0_TX_LASTPACKET,

      VENDOR_ID                                    => VENDOR_ID,
      VSEC_BASE_PTR                                => VSEC_BASE_PTR,
      VSEC_CAP_NEXTPTR                             => VSEC_CAP_NEXTPTR,
      VSEC_CAP_ON                                  => VSEC_CAP_ON,

      AER_BASE_PTR                                 => AER_BASE_PTR,
      AER_CAP_ECRC_CHECK_CAPABLE                   => AER_CAP_ECRC_CHECK_CAPABLE,
      AER_CAP_ECRC_GEN_CAPABLE                     => AER_CAP_ECRC_GEN_CAPABLE,
      AER_CAP_ID                                   => AER_CAP_ID,
      AER_CAP_INT_MSG_NUM_MSI                      => AER_CAP_INT_MSG_NUM_MSI,
      AER_CAP_INT_MSG_NUM_MSIX                     => AER_CAP_INT_MSG_NUM_MSIX,
      AER_CAP_NEXTPTR                              => AER_CAP_NEXTPTR,
      AER_CAP_ON                                   => AER_CAP_ON,
      AER_CAP_PERMIT_ROOTERR_UPDATE                => AER_CAP_PERMIT_ROOTERR_UPDATE,
      AER_CAP_VERSION                              => AER_CAP_VERSION,

      CAPABILITIES_PTR                             => CAPABILITIES_PTR,
      CRM_MODULE_RSTS                              => CRM_MODULE_RSTS,
      DEV_CAP_ENABLE_SLOT_PWR_LIMIT_SCALE          => DEV_CAP_ENABLE_SLOT_PWR_LIMIT_SCALE,
      DEV_CAP_ENABLE_SLOT_PWR_LIMIT_VALUE          => DEV_CAP_ENABLE_SLOT_PWR_LIMIT_VALUE,
      DEV_CAP_FUNCTION_LEVEL_RESET_CAPABLE         => DEV_CAP_FUNCTION_LEVEL_RESET_CAPABLE,
      DEV_CAP_ROLE_BASED_ERROR                     => DEV_CAP_ROLE_BASED_ERROR,
      DEV_CAP_RSVD_14_12                           => DEV_CAP_RSVD_14_12,
      DEV_CAP_RSVD_17_16                           => DEV_CAP_RSVD_17_16,
      DEV_CAP_RSVD_31_29                           => DEV_CAP_RSVD_31_29,
      DEV_CONTROL_AUX_POWER_SUPPORTED              => DEV_CONTROL_AUX_POWER_SUPPORTED,

      DISABLE_ASPM_L1_TIMER                        => DISABLE_ASPM_L1_TIMER,
      DISABLE_BAR_FILTERING                        => DISABLE_BAR_FILTERING,
      DISABLE_ID_CHECK                             => DISABLE_ID_CHECK,
      DISABLE_RX_TC_FILTER                         => DISABLE_RX_TC_FILTER,
      DNSTREAM_LINK_NUM                            => DNSTREAM_LINK_NUM,

      DSN_CAP_ID                                   => DSN_CAP_ID,
      DSN_CAP_VERSION                              => DSN_CAP_VERSION,
      ENTER_RVRY_EI_L0                             => ENTER_RVRY_EI_L0,
      INFER_EI                                     => INFER_EI,
      IS_SWITCH                                    => IS_SWITCH,

      LAST_CONFIG_DWORD                            => LAST_CONFIG_DWORD,
      LINK_CAP_ASPM_SUPPORT                        => LINK_CAP_ASPM_SUPPORT,
      LINK_CAP_CLOCK_POWER_MANAGEMENT              => LINK_CAP_CLOCK_POWER_MANAGEMENT,
      LINK_CAP_L0S_EXIT_LATENCY_COMCLK_GEN1        => LINK_CAP_L0S_EXIT_LATENCY_COMCLK_GEN1,
      LINK_CAP_L0S_EXIT_LATENCY_COMCLK_GEN2        => LINK_CAP_L0S_EXIT_LATENCY_COMCLK_GEN2,
      LINK_CAP_L0S_EXIT_LATENCY_GEN1               => LINK_CAP_L0S_EXIT_LATENCY_GEN1,
      LINK_CAP_L0S_EXIT_LATENCY_GEN2               => LINK_CAP_L0S_EXIT_LATENCY_GEN2,
      LINK_CAP_L1_EXIT_LATENCY_COMCLK_GEN1         => LINK_CAP_L1_EXIT_LATENCY_COMCLK_GEN1,
      LINK_CAP_L1_EXIT_LATENCY_COMCLK_GEN2         => LINK_CAP_L1_EXIT_LATENCY_COMCLK_GEN2,
      LINK_CAP_L1_EXIT_LATENCY_GEN1                => LINK_CAP_L1_EXIT_LATENCY_GEN1,
      LINK_CAP_L1_EXIT_LATENCY_GEN2                => LINK_CAP_L1_EXIT_LATENCY_GEN2,
      LINK_CAP_RSVD_23_22                          => LINK_CAP_RSVD_23_22,
      LINK_CONTROL_RCB                             => LINK_CONTROL_RCB,

      MSI_BASE_PTR                                 => MSI_BASE_PTR,
      MSI_CAP_ID                                   => MSI_CAP_ID,
      MSI_CAP_NEXTPTR                              => MSI_CAP_NEXTPTR,
      MSIX_BASE_PTR                                => MSIX_BASE_PTR,
      MSIX_CAP_ID                                  => MSIX_CAP_ID,
      MSIX_CAP_NEXTPTR                             => MSIX_CAP_NEXTPTR,
      N_FTS_COMCLK_GEN1                            => N_FTS_COMCLK_GEN1,
      N_FTS_COMCLK_GEN2                            => N_FTS_COMCLK_GEN2,
      N_FTS_GEN1                                   => N_FTS_GEN1,
      N_FTS_GEN2                                   => N_FTS_GEN2,

      PCIE_BASE_PTR                                => PCIE_BASE_PTR,
      PCIE_CAP_CAPABILITY_ID                       => PCIE_CAP_CAPABILITY_ID,
      PCIE_CAP_CAPABILITY_VERSION                  => PCIE_CAP_CAPABILITY_VERSION,
      PCIE_CAP_ON                                  => PCIE_CAP_ON,
      PCIE_CAP_RSVD_15_14                          => PCIE_CAP_RSVD_15_14,
      PCIE_CAP_SLOT_IMPLEMENTED                    => PCIE_CAP_SLOT_IMPLEMENTED,
      PCIE_REVISION                                => PCIE_REVISION,
      PGL0_LANE                                    => PGL0_LANE,
      PGL1_LANE                                    => PGL1_LANE,
      PGL2_LANE                                    => PGL2_LANE,
      PGL3_LANE                                    => PGL3_LANE,
      PGL4_LANE                                    => PGL4_LANE,
      PGL5_LANE                                    => PGL5_LANE,
      PGL6_LANE                                    => PGL6_LANE,
      PGL7_LANE                                    => PGL7_LANE,
      PL_AUTO_CONFIG                               => PL_AUTO_CONFIG,
      PL_FAST_TRAIN                                => PL_FAST_TRAIN,

      PM_BASE_PTR                                  => PM_BASE_PTR,
      PM_CAP_AUXCURRENT                            => PM_CAP_AUXCURRENT,
      PM_CAP_ID                                    => PM_CAP_ID,
      PM_CAP_ON                                    => PM_CAP_ON,
      PM_CAP_PME_CLOCK                             => PM_CAP_PME_CLOCK,
      PM_CAP_RSVD_04                               => PM_CAP_RSVD_04,
      PM_CAP_VERSION                               => PM_CAP_VERSION,
      PM_CSR_BPCCEN                                => PM_CSR_BPCCEN,
      PM_CSR_B2B3                                  => PM_CSR_B2B3,

      RECRC_CHK                                    => RECRC_CHK,
      RECRC_CHK_TRIM                               => RECRC_CHK_TRIM,
      ROOT_CAP_CRS_SW_VISIBILITY                   => ROOT_CAP_CRS_SW_VISIBILITY,
      SELECT_DLL_IF                                => SELECT_DLL_IF,
      SLOT_CAP_ATT_BUTTON_PRESENT                  => SLOT_CAP_ATT_BUTTON_PRESENT,
      SLOT_CAP_ATT_INDICATOR_PRESENT               => SLOT_CAP_ATT_INDICATOR_PRESENT,
      SLOT_CAP_ELEC_INTERLOCK_PRESENT              => SLOT_CAP_ELEC_INTERLOCK_PRESENT,
      SLOT_CAP_HOTPLUG_CAPABLE                     => SLOT_CAP_HOTPLUG_CAPABLE,
      SLOT_CAP_HOTPLUG_SURPRISE                    => SLOT_CAP_HOTPLUG_SURPRISE,
      SLOT_CAP_MRL_SENSOR_PRESENT                  => SLOT_CAP_MRL_SENSOR_PRESENT,
      SLOT_CAP_NO_CMD_COMPLETED_SUPPORT            => SLOT_CAP_NO_CMD_COMPLETED_SUPPORT,
      SLOT_CAP_PHYSICAL_SLOT_NUM                   => SLOT_CAP_PHYSICAL_SLOT_NUM,
      SLOT_CAP_POWER_CONTROLLER_PRESENT            => SLOT_CAP_POWER_CONTROLLER_PRESENT,
      SLOT_CAP_POWER_INDICATOR_PRESENT             => SLOT_CAP_POWER_INDICATOR_PRESENT,
      SLOT_CAP_SLOT_POWER_LIMIT_SCALE              => SLOT_CAP_SLOT_POWER_LIMIT_SCALE,
      SLOT_CAP_SLOT_POWER_LIMIT_VALUE              => SLOT_CAP_SLOT_POWER_LIMIT_VALUE,
      SPARE_BIT1                                   => SPARE_BIT1,
      SPARE_BIT2                                   => SPARE_BIT2,
      SPARE_BIT3                                   => SPARE_BIT3,
      SPARE_BIT4                                   => SPARE_BIT4,
      SPARE_BIT5                                   => SPARE_BIT5,
      SPARE_BIT6                                   => SPARE_BIT6,
      SPARE_BIT7                                   => SPARE_BIT7,
      SPARE_BIT8                                   => SPARE_BIT8,
      SPARE_BYTE0                                  => SPARE_BYTE0,
      SPARE_BYTE1                                  => SPARE_BYTE1,
      SPARE_BYTE2                                  => SPARE_BYTE2,
      SPARE_BYTE3                                  => SPARE_BYTE3,
      SPARE_WORD0                                  => SPARE_WORD0,
      SPARE_WORD1                                  => SPARE_WORD1,
      SPARE_WORD2                                  => SPARE_WORD2,
      SPARE_WORD3                                  => SPARE_WORD3,

      TL_RBYPASS                                   => TL_RBYPASS,
      TL_TFC_DISABLE                               => TL_TFC_DISABLE,
      TL_TX_CHECKS_DISABLE                         => TL_TX_CHECKS_DISABLE,
      EXIT_LOOPBACK_ON_EI                          => EXIT_LOOPBACK_ON_EI,
      UPSTREAM_FACING                              => UPSTREAM_FACING,
      UR_INV_REQ                                   => UR_INV_REQ,

      VC_CAP_ID                                    => VC_CAP_ID,
      VC_CAP_VERSION                               => VC_CAP_VERSION,
      VSEC_CAP_HDR_ID                              => VSEC_CAP_HDR_ID,
      VSEC_CAP_HDR_LENGTH                          => VSEC_CAP_HDR_LENGTH,
      VSEC_CAP_HDR_REVISION                        => VSEC_CAP_HDR_REVISION,
      VSEC_CAP_ID                                  => VSEC_CAP_ID,
      VSEC_CAP_IS_LINK_VISIBLE                     => VSEC_CAP_IS_LINK_VISIBLE,
      VSEC_CAP_VERSION                             => VSEC_CAP_VERSION
    )
    port map (
      ---------------------------------------------------------
      -- 1. PCI Express (pci_exp) Interface
      ---------------------------------------------------------

      -- Tx
      pci_exp_txp                               => pci_exp_txp,
      pci_exp_txn                               => pci_exp_txn,

      -- Rx
      pci_exp_rxp                               => pci_exp_rxp,
      pci_exp_rxn                               => pci_exp_rxn,

      ---------------------------------------------------------
      -- 2. Transaction (TRN) Interface
      ---------------------------------------------------------

      -- Common
      user_clk_out                              => user_clk_out,
      user_reset_out                            => user_reset_out,
      user_lnk_up                               => user_lnk_up,

      -- Tx
      tx_buf_av                                 => tx_buf_av,
      tx_err_drop                               => tx_err_drop,
      tx_cfg_req                                => tx_cfg_req,
      s_axis_tx_tready                          => s_axis_tx_tready,
      s_axis_tx_tdata                           => s_axis_tx_tdata,
      s_axis_tx_tkeep                           => s_axis_tx_tkeep,
      s_axis_tx_tuser                           => s_axis_tx_tuser,
      s_axis_tx_tlast                           => s_axis_tx_tlast,
      s_axis_tx_tvalid                          => s_axis_tx_tvalid,

      tx_cfg_gnt                                => tx_cfg_gnt,

      -- Rx
      m_axis_rx_tdata                           => m_axis_rx_tdata,
      m_axis_rx_tkeep                           => m_axis_rx_tkeep,
      m_axis_rx_tlast                           => m_axis_rx_tlast,
      m_axis_rx_tvalid                          => m_axis_rx_tvalid,
      m_axis_rx_tuser                           => m_axis_rx_tuser,
      m_axis_rx_tready                          => m_axis_rx_tready,
      rx_np_ok                                  => rx_np_ok,

      -- Flow Control
      fc_cpld                                   => fc_cpld,
      fc_cplh                                   => fc_cplh,
      fc_npd                                    => fc_npd,
      fc_nph                                    => fc_nph,
      fc_pd                                     => fc_pd,
      fc_ph                                     => fc_ph,
      fc_sel                                    => fc_sel,

      ---------------------------------------------------------
      -- 3. Configuration (CFG) Interface
      ---------------------------------------------------------

      cfg_do                                    => cfg_do,
      cfg_rd_wr_done                            => cfg_rd_wr_done,
      cfg_di                                    => cfg_di,
      cfg_byte_en                               => cfg_byte_en,
      cfg_dwaddr                                => cfg_dwaddr,
      cfg_wr_en                                 => cfg_wr_en,
      cfg_rd_en                                 => cfg_rd_en,

      cfg_err_cor                               => cfg_err_cor,
      cfg_err_ur                                => cfg_err_ur,
      cfg_err_ecrc                              => cfg_err_ecrc,
      cfg_err_cpl_timeout                       => cfg_err_cpl_timeout,
      cfg_err_cpl_abort                         => cfg_err_cpl_abort,
      cfg_err_cpl_unexpect                      => cfg_err_cpl_unexpect,
      cfg_err_posted                            => cfg_err_posted,
      cfg_err_locked                            => cfg_err_locked,
      cfg_err_tlp_cpl_header                    => cfg_err_tlp_cpl_header,
      cfg_err_cpl_rdy                           => cfg_err_cpl_rdy,
      cfg_interrupt                             => cfg_interrupt,
      cfg_interrupt_rdy                         => cfg_interrupt_rdy,
      cfg_interrupt_assert                      => cfg_interrupt_assert,
      cfg_interrupt_di                          => cfg_interrupt_di,
      cfg_interrupt_do                          => cfg_interrupt_do,
      cfg_interrupt_mmenable                    => cfg_interrupt_mmenable,
      cfg_interrupt_msienable                   => cfg_interrupt_msienable,
      cfg_interrupt_msixenable                  => cfg_interrupt_msixenable,
      cfg_interrupt_msixfm                      => cfg_interrupt_msixfm,
      cfg_turnoff_ok                            => cfg_turnoff_ok,
      cfg_to_turnoff                            => cfg_to_turnoff,
      cfg_trn_pending                           => cfg_trn_pending,
      cfg_pm_wake                               => cfg_pm_wake,
      cfg_bus_number                            => cfg_bus_number,
      cfg_device_number                         => cfg_device_number,
      cfg_function_number                       => cfg_function_number,
      cfg_status                                => cfg_status,
      cfg_command                               => cfg_command,
      cfg_dstatus                               => cfg_dstatus,
      cfg_dcommand                              => cfg_dcommand,
      cfg_lstatus                               => cfg_lstatus,
      cfg_lcommand                              => cfg_lcommand,
      cfg_dcommand2                             => cfg_dcommand2,
      cfg_pcie_link_state                       => cfg_pcie_link_state,
      cfg_dsn                                   => cfg_dsn,
      cfg_pmcsr_pme_en                          => cfg_pmcsr_pme_en,
      cfg_pmcsr_pme_status                      => cfg_pmcsr_pme_status,
      cfg_pmcsr_powerstate                      => cfg_pmcsr_powerstate,

      ---------------------------------------------------------
      -- 4. Physical Layer Control and Status (PL) Interface
      ---------------------------------------------------------

      pl_initial_link_width                     => pl_initial_link_width,
      pl_lane_reversal_mode                     => pl_lane_reversal_mode,
      pl_link_gen2_capable                      => pl_link_gen2_capable,
      pl_link_partner_gen2_supported            => pl_link_partner_gen2_supported,
      pl_link_upcfg_capable                     => pl_link_upcfg_capable,
      pl_ltssm_state                            => pl_ltssm_state,
      pl_received_hot_rst                       => pl_received_hot_rst,
      pl_sel_link_rate                          => pl_sel_link_rate,
      pl_sel_link_width                         => pl_sel_link_width,
      pl_directed_link_auton                    => pl_directed_link_auton,
      pl_directed_link_change                   => pl_directed_link_change,
      pl_directed_link_speed                    => pl_directed_link_speed,
      pl_directed_link_width                    => pl_directed_link_width,
      pl_upstream_prefer_deemph                 => pl_upstream_prefer_deemph,

      ---------------------------------------------------------
      -- 5. System  (SYS) Interface
      ---------------------------------------------------------

      sys_clk                                   => sys_clk,
      sys_reset                                 => sys_reset
    );

end architecture;
