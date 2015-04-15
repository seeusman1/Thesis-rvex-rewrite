-- r-VEX processor
-- Copyright (C) 2008-2015 by TU Delft.
-- All Rights Reserved.

-- THIS IS A LEGAL DOCUMENT, BY USING r-VEX,
-- YOU ARE AGREEING TO THESE TERMS AND CONDITIONS.

-- No portion of this work may be used by any commercial entity, or for any
-- commercial purpose, without the prior, written permission of TU Delft.
-- Nonprofit and noncommercial use is permitted as described below.

-- 1. r-VEX is provided AS IS, with no warranty of any kind, express
-- or implied. The user of the code accepts full responsibility for the
-- application of the code and the use of any results.

-- 2. Nonprofit and noncommercial use is encouraged. r-VEX may be
-- downloaded, compiled, synthesized, copied, and modified solely for nonprofit,
-- educational, noncommercial research, and noncommercial scholarship
-- purposes provided that this notice in its entirety accompanies all copies.
-- Copies of the modified software can be delivered to persons who use it
-- solely for nonprofit, educational, noncommercial research, and
-- noncommercial scholarship purposes provided that this notice in its
-- entirety accompanies all copies.

-- 3. ALL COMMERCIAL USE, AND ALL USE BY FOR PROFIT ENTITIES, IS EXPRESSLY
-- PROHIBITED WITHOUT A LICENSE FROM TU Delft (J.S.S.M.Wong@tudelft.nl).
--
-- 4. No nonprofit user may place any restrictions on the use of this software,
-- including as modified by the user, by any other authorized user.

-- 5. Noncommercial and nonprofit users may distribute copies of r-VEX
-- in compiled or binary form as set forth in Section 2, provided that
-- either: (A) it is accompanied by the corresponding machine-readable source
-- code, or (B) it is accompanied by a written offer, with no time limit, to
-- give anyone a machine-readable copy of the corresponding source code in
-- return for reimbursement of the cost of distribution. This written offer
-- must permit verbatim duplication by anyone, or (C) it is distributed by
-- someone who received only the executable form, and is accompanied by a
-- copy of the written offer of source code.

-- 6. r-VEX was developed by Stephan Wong, Thijs van As, Fakhar Anjam,
-- Roel Seedorf, Anthony Brandon, Jeroen van Straten. r-VEX is currently
-- maintained by TU Delft (J.S.S.M.Wong@tudelft.nl).

-- Copyright (C) 2008-2015 by TU Delft.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_misc.all;
use IEEE.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library rvex;
use rvex.common_pkg.all;
use rvex.utils_pkg.all;
use rvex.bus_pkg.all;
use rvex.rvsys_grlib_pkg.all;

use work.constants.all;

entity dma is
  generic (
    NO_OF_LANES             : integer := 4
  );
  port (
    ---------------------------------------------------------------------------
    -- System control
    ---------------------------------------------------------------------------
    -- Active high synchronous reset input.
    reset                   : in  std_logic;

    ---------------------------------------------------------------------------
    -- PCIe signals
    ---------------------------------------------------------------------------
    pcie_txp                : out std_logic_vector(NO_OF_LANES-1 downto 0);
    pcie_txn                : out std_logic_vector(NO_OF_LANES-1 downto 0);
    pcie_rxp                : in  std_logic_vector(NO_OF_LANES-1 downto 0);
    pcie_rxn                : in  std_logic_vector(NO_OF_LANES-1 downto 0);

    pcie_clk_p              : in  std_logic;
    pcie_clk_n              : in  std_logic;

    -- PCI Express slot PERST# reset signal
    perst_n                 : in  std_logic;

    ---------------------------------------------------------------------------
    -- r-VEX bus signals
    ---------------------------------------------------------------------------
    -- The bus clock. We assume that it is related to the PCIe clock.
    bus_clk                 : in std_logic;

    bus2dma_c2s             : in  bus_slv2mst_type;
    dma2bus_c2s             : out bus_mst2slv_type;
    bus2dma_s2c             : in  bus_slv2mst_type;
    dma2bus_s2c             : out bus_mst2slv_type
  );
end entity;

architecture behavioral of dma is
  -- Driving clock of the PCIe interface
  signal pcie_ref_clk              : std_logic;
  -- Clock from the PCIe interface
  signal user_clk                  : std_logic;
  -- PCIe reset
  signal perst_n_c                 : std_logic;
  signal perst_c                   : std_logic;

  signal targ_wr_req               : std_logic;
  signal targ_wr_core_ready        : std_logic;
  signal targ_wr_user_ready        : std_logic;
  signal targ_wr_cs                : std_logic_vector(0 to 5);
  signal targ_wr_start             : std_logic;
  signal targ_wr_addr              : std_logic_vector(0 to 31);
  signal targ_wr_count             : std_logic_vector(0 to 12);
  signal targ_wr_en                : std_logic;
  signal targ_wr_data              : std_logic_vector(0 to CORE_DATA_WIDTH-1);
  signal targ_wr_be                : std_logic_vector(0 to CORE_BE_WIDTH-1);

  signal targ_rd_req               : std_logic;
  signal targ_rd_core_ready        : std_logic;
  signal targ_rd_user_ready        : std_logic;
  signal targ_rd_cs                : std_logic_vector(0 to 5);
  signal targ_rd_start             : std_logic;
  signal targ_rd_addr              : std_logic_vector(0 to 31);
  signal targ_rd_count             : std_logic_vector(0 to 12);
  signal targ_rd_en                : std_logic;
  signal targ_rd_data              : std_logic_vector(0 to CORE_DATA_WIDTH-1);
  signal targ_rd_first_be          : std_logic_vector(0 to CORE_BE_WIDTH-1);  
  signal targ_rd_last_be           : std_logic_vector(0 to CORE_BE_WIDTH-1);  

  signal reg_wr_addr               : std_logic_vector(0 to REG_ADDR_WIDTH-1);
  signal reg_wr_en                 : std_logic;
  signal reg_wr_be                 : std_logic_vector(0 to CORE_BE_WIDTH-1);
  signal reg_wr_data               : std_logic_vector(0 to CORE_DATA_WIDTH-1);
  signal reg_rd_addr               : std_logic_vector(0 to REG_ADDR_WIDTH-1);
  signal reg_rd_be                 : std_logic_vector(0 to CORE_BE_WIDTH-1);
  signal reg_rd_data               : std_logic_vector(0 to CORE_DATA_WIDTH-1);

  signal s2c0_user_control         : std_logic_vector(0 to 63);      
  signal s2c0_sop                  : std_logic;              
  signal s2c0_eop                  : std_logic;              
  signal s2c0_err                  : std_logic;
  signal s2c0_data                 : std_logic_vector(0 to CORE_DATA_WIDTH-1);             
  signal s2c0_data_valid           : std_logic_vector(0 to CORE_REMAIN_WIDTH-1);
  signal s2c0_src_rdy              : std_logic;          
  signal s2c0_dst_rdy              : std_logic;          
  signal s2c0_abort                : std_logic;            
  signal s2c0_abort_ack            : std_logic; 
  signal s2c0_user_rst_n           : std_logic;

  signal s2c0_apkt_req             : std_logic;
  signal s2c0_apkt_ready           : std_logic;
  signal s2c0_apkt_addr            : std_logic_vector(0 to 63);
  signal s2c0_apkt_bcount          : std_logic_vector(0 to 9);

  signal c2s0_user_status          : std_logic_vector(0 to 63);      
  signal c2s0_sop                  : std_logic;              
  signal c2s0_eop                  : std_logic;              
  signal c2s0_data                 : std_logic_vector(0 to CORE_DATA_WIDTH-1);             
  signal c2s0_data_valid           : std_logic_vector(0 to CORE_REMAIN_WIDTH-1);
  signal c2s0_src_rdy              : std_logic;          
  signal c2s0_dst_rdy              : std_logic;          
  signal c2s0_abort                : std_logic;            
  signal c2s0_abort_ack            : std_logic; 
  signal c2s0_user_rst_n           : std_logic;

  signal c2s0_apkt_req             : std_logic;
  signal c2s0_apkt_ready           : std_logic;
  signal c2s0_apkt_addr            : std_logic_vector(0 to 63);
  signal c2s0_apkt_bcount          : std_logic_vector(0 to 31);
  signal c2s0_apkt_eop             : std_logic;

  signal s2c1_user_control         : std_logic_vector(0 to 63);      
  signal s2c1_sop                  : std_logic;              
  signal s2c1_eop                  : std_logic;              
  signal s2c1_err                  : std_logic;
  signal s2c1_data                 : std_logic_vector(0 to CORE_DATA_WIDTH-1);             
  signal s2c1_data_valid           : std_logic_vector(0 to CORE_REMAIN_WIDTH-1);
  signal s2c1_src_rdy              : std_logic;          
  signal s2c1_dst_rdy              : std_logic;          
  signal s2c1_abort                : std_logic;            
  signal s2c1_abort_ack            : std_logic;   
  signal s2c1_user_rst_n           : std_logic;

  signal s2c1_apkt_req             : std_logic;
  signal s2c1_apkt_ready           : std_logic;
  signal s2c1_apkt_addr            : std_logic_vector(0 to 63);
  signal s2c1_apkt_bcount          : std_logic_vector(0 to 9);

  signal c2s1_user_status          : std_logic_vector(0 to 63);      
  signal c2s1_sop                  : std_logic;              
  signal c2s1_eop                  : std_logic;              
  signal c2s1_data                 : std_logic_vector(0 to CORE_DATA_WIDTH-1);             
  signal c2s1_data_valid           : std_logic_vector(0 to CORE_REMAIN_WIDTH-1);
  signal c2s1_src_rdy              : std_logic;          
  signal c2s1_dst_rdy              : std_logic;          
  signal c2s1_abort                : std_logic;            
  signal c2s1_abort_ack            : std_logic; 
  signal c2s1_user_rst_n           : std_logic;

  signal c2s1_apkt_req             : std_logic;
  signal c2s1_apkt_ready           : std_logic;
  signal c2s1_apkt_addr            : std_logic_vector(0 to 63);
  signal c2s1_apkt_bcount          : std_logic_vector(0 to 31);
  signal c2s1_apkt_eop             : std_logic;


  -- -------------------
  -- -- Local Signals --
  -- -------------------

  -- Xilinx Hard Core Instantiation

  signal user_reset                : std_logic;
  signal user_lnk_up               : std_logic;
  signal user_reset_c              : std_logic;
  signal user_lnk_up_c             : std_logic;

  signal tx_buf_av                 : std_logic_vector(0 to 5);
  signal tx_err_drop               : std_logic;
  signal tx_cfg_req                : std_logic;
  signal s_axis_tx_tready          : std_logic;
  signal s_axis_tx_tdata           : std_logic_vector(0 to XIL_DATA_WIDTH-1);
  signal s_axis_tx_tstrb           : std_logic_vector(0 to XIL_STRB_WIDTH-1);
  signal s_axis_tx_tuser           : std_logic_vector(0 to 3);
  signal s_axis_tx_tlast           : std_logic;
  signal s_axis_tx_tvalid          : std_logic;
  signal tx_cfg_gnt                : std_logic;

  signal m_axis_rx_tdata           : std_logic_vector(0 to XIL_DATA_WIDTH-1);
  signal m_axis_rx_tstrb           : std_logic_vector(0 to XIL_STRB_WIDTH-1);
  signal m_axis_rx_tlast           : std_logic;
  signal m_axis_rx_tvalid          : std_logic;
  signal m_axis_rx_tready          : std_logic;
  signal m_axis_rx_tuser           : std_logic_vector(0 to 21);
  signal rx_np_ok                  : std_logic;

  signal fc_cpld                   : std_logic_vector(0 to 11);
  signal fc_cplh                   : std_logic_vector(0 to 7);
  signal fc_npd                    : std_logic_vector(0 to 11);
  signal fc_nph                    : std_logic_vector(0 to 7);
  signal fc_pd                     : std_logic_vector(0 to 11);
  signal fc_ph                     : std_logic_vector(0 to 7);
  signal fc_sel                    : std_logic_vector(0 to 2);

  signal cfg_do                    : std_logic_vector(0 to 31);
  signal cfg_rd_wr_done            : std_logic;
  signal cfg_di                    : std_logic_vector(0 to 31);
  signal cfg_byte_en               : std_logic_vector(0 to 3);
  signal cfg_dwaddr                : std_logic_vector(0 to 9);
  signal cfg_wr_en                 : std_logic;
  signal cfg_rd_en                 : std_logic;
    
  signal cfg_err_cor               : std_logic;
  signal cfg_err_ur                : std_logic;
  signal cfg_err_ecrc              : std_logic;
  signal cfg_err_cpl_timeout       : std_logic;
  signal cfg_err_cpl_abort         : std_logic;
  signal cfg_err_cpl_unexpect      : std_logic;
  signal cfg_err_posted            : std_logic;
  signal cfg_err_locked            : std_logic;
  signal cfg_err_tlp_cpl_header    : std_logic_vector(0 to 47);
  signal cfg_err_cpl_rdy           : std_logic;

  signal cfg_interrupt             : std_logic;
  signal cfg_interrupt_rdy         : std_logic;
  signal cfg_interrupt_assert      : std_logic;
  signal cfg_interrupt_di          : std_logic_vector(0 to 7);
  signal cfg_interrupt_do          : std_logic_vector(0 to 7);
  signal cfg_interrupt_mmenable    : std_logic_vector(0 to 2);
  signal cfg_interrupt_msienable   : std_logic;
  signal cfg_interrupt_msixenable  : std_logic;
  signal cfg_interrupt_msixfm      : std_logic;

  signal cfg_turnoff_ok            : std_logic;
  signal cfg_to_turnoff            : std_logic;
  signal cfg_trn_pending           : std_logic;
  signal cfg_pm_wake               : std_logic;

  signal cfg_bus_number            : std_logic_vector(0 to 7);
  signal cfg_device_number         : std_logic_vector(0 to 4);
  signal cfg_function_number       : std_logic_vector(0 to 2);
  signal cfg_status                : std_logic_vector(0 to 15);
  signal cfg_command               : std_logic_vector(0 to 15);
  signal cfg_dstatus               : std_logic_vector(0 to 15);
  signal cfg_dcommand              : std_logic_vector(0 to 15);
  signal cfg_lstatus               : std_logic_vector(0 to 15);
  signal cfg_lcommand              : std_logic_vector(0 to 15);
  signal cfg_dcommand2             : std_logic_vector(0 to 15);
  signal cfg_pcie_link_state       : std_logic_vector(0 to 2);
  signal cfg_dsn                   : std_logic_vector(0 to 63);

  signal pl_initial_link_width     : std_logic_vector(0 to 2);
  signal pl_lane_reversal_mode     : std_logic_vector(0 to 1);
  signal pl_link_gen2_capable      : std_logic;
  signal pl_link_partner_gen2_supported : std_logic;
  signal pl_link_upcfg_capable     : std_logic;
  signal pl_ltssm_state            : std_logic_vector(0 to 5);
  signal pl_received_hot_rst       : std_logic;
  signal pl_sel_link_rate          : std_logic;
  signal pl_sel_link_width         : std_logic_vector(0 to 1);
  signal pl_directed_link_auton    : std_logic;
  signal pl_directed_link_change   : std_logic_vector(0 to 1);
  signal pl_directed_link_speed    : std_logic;
  signal pl_directed_link_width    : std_logic_vector(0 to 1);
  signal pl_upstream_prefer_deemph : std_logic;

begin

  -- ---------------
  -- Clock and Reset
  -- ---------------

  -- PCIe Reference Clock Input buffer
  pcie_refclk_ibuf : IBUFDS_GTXE1
    port map (
      I     => pcie_clk_p,
      IB    => pcie_clk_n,
      O     => pcie_ref_clk,
      CEB   => '1',
      ODIV2 => open
    );

  -- PCIe PERST# input buffer
  perst_n_ibuf : IBUF
    port map(
      I     => perst_n,
      O     => perst_n_c
    );
  perst_c <= perst_n_c;

  -- Register to improve timing
  user_lnk_up_int_i : FDCP 
    generic map (
      INIT   => '1'
    )
    port map(
      Q      => user_lnk_up,
      D      => user_lnk_up_c,
      C      => user_clk,
      CLR    => '0',
      PRE    => '0'
    );

  -- Register to improve timing
  user_reset_i : FDCP
    generic map(
      INIT   => '1'
    )
    port map(
      Q      => user_reset,
      D      => user_reset_c,
      C      => user_clk,
      CLR    => '0',
      PRE    => '0'
    );

  --+++++++++++++++++++++++++++++++++++++++++++++++++++

  -- -------------------------
  -- PCI Express Interface
  -- -------------------------

  pcie_coregen: entity work.pcie_v2_5
    generic map (
      -- pragma translate_off
      PL_FAST_TRAIN                                => TRUE, -- Default is FALSE
      -- pragma translate_on

      BAR0                                         => X"FFFF0000", -- bar0; 64 KByte registers
      BAR1                                         => X"FFFFE000", -- bar1; 8K Byte internal SRAM
      BAR2                                         => X"FFFFFE00", -- bar2; 8K Byte internal SRAM
      BAR3                                         => X"00000000",
      BAR4                                         => X"00000000",
      BAR5                                         => X"00000000",

      CLASS_CODE                                   => X"07_80_00",

      DEV_CAP_MAX_PAYLOAD_SUPPORTED                => 2,
      LINK_CAP_MAX_LINK_WIDTH                      => X"4",--NO_OF_LANES,
      LTSSM_MAX_LINK_WIDTH                         => X"4",--NO_OF_LANES,
      DEVICE_ID                                    => X"6024",
      VENDOR_ID                                    => X"10EE",

      SUBSYSTEM_ID                                 => X"0007",
      SUBSYSTEM_VENDOR_ID                          => X"10EE",

      REVISION_ID                                  => X"04",


      UPCONFIG_CAPABLE                             => TRUE,
      LINK_CAP_MAX_LINK_SPEED                      => X"1",
      LINK_CTRL2_TARGET_LINK_SPEED                 => X"1",
      USER_CLK_FREQ                                => 2
    )
    port map (
      ---------------------------------------------------------
      -- 1. PCI Express (pci_exp) Interface
      ---------------------------------------------------------

      -- Tx
      pci_exp_txp                               => pcie_txp,
      pci_exp_txn                               => pcie_txn,

      -- Rx
      pci_exp_rxp                               => pcie_rxp,
      pci_exp_rxn                               => pcie_rxn,

      ---------------------------------------------------------
      -- 2. Transaction (TRN) Interface
      ---------------------------------------------------------

      -- Common
      user_clk_out                              => user_clk,
      user_reset_out                            => user_reset_c,
      user_lnk_up                               => user_lnk_up_c,

      -- Tx
      tx_buf_av                                 => tx_buf_av,
      tx_err_drop                               => tx_err_drop,
      tx_cfg_req                                => tx_cfg_req,
      s_axis_tx_tready                          => s_axis_tx_tready,
      s_axis_tx_tdata                           => s_axis_tx_tdata,
      s_axis_tx_tkeep                           => s_axis_tx_tstrb,
      s_axis_tx_tuser                           => s_axis_tx_tuser,
      s_axis_tx_tlast                           => s_axis_tx_tlast,
      s_axis_tx_tvalid                          => s_axis_tx_tvalid,

      tx_cfg_gnt                                => tx_cfg_gnt,

      -- Rx
      m_axis_rx_tdata                           => m_axis_rx_tdata,
      m_axis_rx_tkeep                           => m_axis_rx_tstrb,
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
      cfg_pmcsr_pme_en                          => open,
      cfg_pmcsr_pme_status                      => open,
      cfg_pmcsr_powerstate                      => open,

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

      sys_clk                                   => pcie_ref_clk,
      sys_reset                                 => perst_c
    );

  --+++++++++++++++++++++++++++++++++++++++++++++++++
  --  Taken from xil_pcie_wrapper.v - SR

  -- ---------------------------------
  -- Physical Layer Control and Status

  pl_directed_link_change      <= "00";
  pl_directed_link_width       <= "00";
  pl_directed_link_speed       <= '0';
  pl_directed_link_auton       <= '0';
  pl_upstream_prefer_deemph    <= '1';

  -- -------------------------------
  -- Device Serial Number Capability

  cfg_dsn                      <= uint2vect(DEVICE_SN, 64);

  --+++++++++++++++++++++++++++++++++++++++++++++++++++

  -- -------------------------
  -- Packet DMA Instance
  -- -------------------------
  packet_dma_inst : entity work.packet_dma_entity 
    generic map (
      XIL_DATA_WIDTH                 => 64,
      XIL_STRB_WIDTH                 => 8
    )
    port map (
      user_reset                     => user_reset,
      user_clk                       => user_clk,
      user_lnk_up                    => user_lnk_up,
      clk_period_in_ns               => uint2vect(8, 8), -- 8 is 125 MHz, use 125 MHz for x4 GEN1, 250 MHz for x8 GEN1 and GEN2

      user_interrupt                 => '0',

      -- Tx
      s_axis_tx_tready               => s_axis_tx_tready, -- I 
      s_axis_tx_tdata                => s_axis_tx_tdata, -- O [XIL_DATA_WIDTH-1:0]
      s_axis_tx_tstrb                => s_axis_tx_tstrb, -- O [XIL_STRB_WIDTH-1:0]
      s_axis_tx_tuser                => s_axis_tx_tuser, -- O [3:0]
      s_axis_tx_tlast                => s_axis_tx_tlast, -- O
      s_axis_tx_tvalid               => s_axis_tx_tvalid, -- O
      tx_cfg_gnt                     => tx_cfg_gnt, -- O
      tx_cfg_req                     => tx_cfg_req, -- I
      tx_buf_av                      => tx_buf_av, -- I
      tx_err_drop                    => tx_err_drop, -- I

      -- Rx
      m_axis_rx_tdata                => m_axis_rx_tdata, -- I  [XIL_DATA_WIDTH-1:0]
      m_axis_rx_tstrb                => m_axis_rx_tstrb, -- I  [XIL_STRB_WIDTH-1:0]
      m_axis_rx_tlast                => m_axis_rx_tlast, -- I
      m_axis_rx_tvalid               => m_axis_rx_tvalid, -- I
      m_axis_rx_tready               => m_axis_rx_tready, -- O  
      m_axis_rx_tuser                => m_axis_rx_tuser, -- I  [21:0]
      rx_np_ok                       => rx_np_ok, -- O

      -- Flow Control
      fc_cpld                        => fc_cpld, -- I [11:0]
      fc_cplh                        => fc_cplh, -- I [7:0] 
      fc_npd                         => fc_npd, -- I [11:0]
      fc_nph                         => fc_nph, -- I [7:0] 
      fc_pd                          => fc_pd, -- I [11:0]
      fc_ph                          => fc_ph, -- I [7:0] 
      fc_sel                         => fc_sel, -- I [2:0] 
      
      cfg_di                         => cfg_di, -- O [31:0]
      cfg_byte_en                    => cfg_byte_en, -- O
      cfg_dwaddr                     => cfg_dwaddr, -- O
      cfg_wr_en                      => cfg_wr_en, -- O
      cfg_rd_en                      => cfg_rd_en, -- O

      cfg_err_cor                    => cfg_err_cor, -- O
      cfg_err_ur                     => cfg_err_ur, -- O
      cfg_err_ecrc                   => cfg_err_ecrc, -- O
      cfg_err_cpl_timeout            => cfg_err_cpl_timeout, -- O
      cfg_err_cpl_abort              => cfg_err_cpl_abort, -- O
      cfg_err_cpl_unexpect           => cfg_err_cpl_unexpect, -- O
      cfg_err_posted                 => cfg_err_posted, -- O
      cfg_err_locked                 => cfg_err_locked, -- O
      cfg_err_tlp_cpl_header         => cfg_err_tlp_cpl_header, -- O [47:0]
      cfg_err_cpl_rdy                => cfg_err_cpl_rdy, -- I

      cfg_interrupt                  => cfg_interrupt, -- O
      cfg_interrupt_rdy              => cfg_interrupt_rdy, -- I
      cfg_interrupt_assert           => cfg_interrupt_assert, -- O
      cfg_interrupt_di               => cfg_interrupt_di, -- O [7:0]
      cfg_interrupt_do               => cfg_interrupt_do, -- I [7:0]
      cfg_interrupt_mmenable         => cfg_interrupt_mmenable, -- I [2:0]
      cfg_interrupt_msienable        => cfg_interrupt_msienable, -- I 
      cfg_interrupt_msixenable       => cfg_interrupt_msixenable, -- I
      cfg_interrupt_msixfm           => cfg_interrupt_msixfm, -- I

      cfg_turnoff_ok                 => cfg_turnoff_ok, -- O
      cfg_to_turnoff                 => cfg_to_turnoff, -- I
      cfg_trn_pending                => cfg_trn_pending, -- O
      cfg_pm_wake                    => cfg_pm_wake, -- O

      cfg_bus_number                 => cfg_bus_number, -- I [7:0]
      cfg_device_number              => cfg_device_number, -- I [4:0]
      cfg_function_number            => cfg_function_number, -- I [2:0]
      cfg_status                     => cfg_status, -- I [15:0]
      cfg_command                    => cfg_command, -- I [15:0]
      cfg_dstatus                    => cfg_dstatus, -- I [15:0]
      cfg_dcommand                   => cfg_dcommand, -- I [15:0]
      cfg_lstatus                    => cfg_lstatus, -- I [15:0]
      cfg_lcommand                   => cfg_lcommand, -- I [15:0]
      cfg_dcommand2                  => cfg_dcommand2, -- I [15:0]
      cfg_pcie_link_state            => cfg_pcie_link_state, -- I [2:0]

      s2c0_user_control              => s2c0_user_control,
      s2c0_sop                       => s2c0_sop,
      s2c0_eop                       => s2c0_eop,
      s2c0_err                       => s2c0_err,
      s2c0_data                      => s2c0_data,
      s2c0_valid                     => s2c0_data_valid,
      s2c0_src_rdy                   => s2c0_src_rdy,
      s2c0_dst_rdy                   => s2c0_dst_rdy,
      s2c0_abort                     => s2c0_abort,
      s2c0_abort_ack                 => s2c0_abort_ack,
      s2c0_user_rst_n                => s2c0_user_rst_n,
      s2c0_apkt_req                  => s2c0_apkt_req,
      s2c0_apkt_ready                => s2c0_apkt_ready,
      s2c0_apkt_addr                 => s2c0_apkt_addr,
      s2c0_apkt_bcount               => s2c0_apkt_bcount,

      s2c1_user_control              => s2c1_user_control,
      s2c1_sop                       => s2c1_sop,
      s2c1_eop                       => s2c1_eop,
      s2c1_err                       => s2c1_err,
      s2c1_data                      => s2c1_data,
      s2c1_valid                     => s2c1_data_valid,
      s2c1_src_rdy                   => s2c1_src_rdy,
      s2c1_dst_rdy                   => s2c1_dst_rdy,
      s2c1_abort                     => s2c1_abort,
      s2c1_abort_ack                 => s2c1_abort_ack,
      s2c1_user_rst_n                => s2c1_user_rst_n,
      s2c1_apkt_req                  => s2c1_apkt_req,
      s2c1_apkt_ready                => s2c1_apkt_ready,
      s2c1_apkt_addr                 => s2c1_apkt_addr,
      s2c1_apkt_bcount               => s2c1_apkt_bcount,

      c2s0_user_status               => c2s0_user_status,
      c2s0_sop                       => c2s0_sop,
      c2s0_eop                       => c2s0_eop,
      c2s0_data                      => c2s0_data,
      c2s0_valid                     => c2s0_data_valid,
      c2s0_src_rdy                   => c2s0_src_rdy,
      c2s0_dst_rdy                   => c2s0_dst_rdy,
      c2s0_abort                     => c2s0_abort,
      c2s0_abort_ack                 => c2s0_abort_ack,
      c2s0_user_rst_n                => c2s0_user_rst_n,
      c2s0_apkt_req                  => c2s0_apkt_req,
      c2s0_apkt_ready                => c2s0_apkt_ready,
      c2s0_apkt_addr                 => c2s0_apkt_addr,
      c2s0_apkt_bcount               => c2s0_apkt_bcount,
      c2s0_apkt_eop                  => c2s0_apkt_eop,

      c2s1_user_status               => c2s1_user_status,
      c2s1_sop                       => c2s1_sop,
      c2s1_eop                       => c2s1_eop,
      c2s1_data                      => c2s1_data,
      c2s1_valid                     => c2s1_data_valid,
      c2s1_src_rdy                   => c2s1_src_rdy,
      c2s1_dst_rdy                   => c2s1_dst_rdy,
      c2s1_abort                     => c2s1_abort,
      c2s1_abort_ack                 => c2s1_abort_ack,
      c2s1_user_rst_n                => c2s1_user_rst_n,    
      c2s1_apkt_req                  => c2s1_apkt_req,
      c2s1_apkt_ready                => c2s1_apkt_ready,
      c2s1_apkt_addr                 => c2s1_apkt_addr,
      c2s1_apkt_bcount               => c2s1_apkt_bcount,
      c2s1_apkt_eop                  => c2s1_apkt_eop,

      targ_wr_req                    => targ_wr_req,
      targ_wr_core_ready             => targ_wr_core_ready,
      targ_wr_user_ready             => targ_wr_user_ready,
      targ_wr_cs                     => targ_wr_cs,
      targ_wr_start                  => targ_wr_start,
      targ_wr_addr                   => targ_wr_addr,
      targ_wr_count                  => targ_wr_count,
      targ_wr_en                     => targ_wr_en,
      targ_wr_data                   => targ_wr_data,
      targ_wr_be                     => targ_wr_be,

      targ_rd_req                    => targ_rd_req,
      targ_rd_core_ready             => targ_rd_core_ready,
      targ_rd_user_ready             => targ_rd_user_ready,
      targ_rd_cs                     => targ_rd_cs,
      targ_rd_start                  => targ_rd_start,
      targ_rd_addr                   => targ_rd_addr,
      targ_rd_count                  => targ_rd_count,
      targ_rd_en                     => targ_rd_en,
      targ_rd_data                   => targ_rd_data,
      targ_rd_first_be               => targ_rd_first_be,
      targ_rd_last_be                => targ_rd_last_be,

      reg_wr_addr                    => reg_wr_addr,
      reg_wr_en                      => reg_wr_en,
      reg_wr_be                      => reg_wr_be,
      reg_wr_data                    => reg_wr_data,
      reg_rd_addr                    => reg_rd_addr,
      reg_rd_be                      => reg_rd_be,
      reg_rd_data                    => reg_rd_data
  );

  -- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- c2s to r-VEX bus
  c2s_to_bus: entity work.c2s_bus_bridge
    port map (
      reset                   => reset,
      sys_clk                 => pcie_ref_clk,
      c2s_clk                 => bus_clk,
      
      -- c2s bus
      sop                     => c2s0_sop,
      eop                     => c2s0_eop,
      data                    => c2s0_data,
      valid                   => c2s0_data_valid,
      src_rdy                 => c2s0_src_rdy,
      dst_rdy                 => c2s0_dst_rdy,
      abort                   => c2s0_abort,
      abort_ack               => c2s0_abort_ack,
      user_rst_n              => c2s0_user_rst_n,

      apkt_req                => c2s0_apkt_req,
      apkt_ready              => c2s0_apkt_ready,
      apkt_addr               => c2s0_apkt_addr,
      apkt_bcount             => c2s0_apkt_bcount,
      apkt_eop                => c2s0_apkt_eop,

      -- Master bus
      bus2dma                 => bus2dma_c2s,
      dma2bus                 => dma2bus_c2s
    );

  -- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- s2c to r-VEX bus
  s2c_to_bus: entity work.s2c_bus_bridge
    port map (
      reset                   => reset,
      sys_clk                 => pcie_ref_clk,
      s2c_clk                 => bus_clk,
      
      -- s2c bus
      sop                     => s2c0_sop,
      eop                     => s2c0_eop,
      err                     => s2c0_err,
      data                    => s2c0_data,
      valid                   => s2c0_data_valid,
      src_rdy                 => s2c0_src_rdy,
      dst_rdy                 => s2c0_dst_rdy,
      abort                   => s2c0_abort,
      abort_ack               => s2c0_abort_ack,
      user_rst_n              => s2c0_user_rst_n,

      apkt_req                => s2c0_apkt_req,
      apkt_ready              => s2c0_apkt_ready,
      apkt_addr               => s2c0_apkt_addr,
      apkt_bcount             => s2c0_apkt_bcount,

      -- Master bus
      bus2dma                 => bus2dma_s2c,
      dma2bus                 => dma2bus_s2c
    );

end architecture;
