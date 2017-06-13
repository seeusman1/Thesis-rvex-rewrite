-- r-VEX processor
-- Copyright (C) 2008-2016 by TU Delft.
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

-- Copyright (C) 2008-2016 by TU Delft.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.constants.all;

entity packet_dma_entity is
  generic (
    DATA_WIDTH                    : integer := 64;
    REM_WIDTH                     : integer := 3;
    BE_WIDTH                      : integer := 8;
    ADDR_WIDTH                    : integer := 13;--12 + (4-REM_WIDTH);
    FIFO_DADDR_WIDTH              : integer := 8;--7 + (4-REM_WIDTH);
    SUPPORT_64BIT_SYS_ADDR        : std_logic := '1';
    SUPPORT_64BIT_DESC_ADDR       : std_logic := '1';
    XIL_DATA_WIDTH                : integer := 64;           -- RX/TX interface data width
    XIL_STRB_WIDTH                : integer := 8             -- TSTRB width
  );
  port (

    user_reset                    : in  std_logic;
    user_clk                      : in  std_logic;
    user_lnk_up                   : in  std_logic;

    clk_period_in_ns              : in  std_logic_vector(0 to 7);

    user_interrupt                : in  std_logic;

    -- Tx
    s_axis_tx_tready              : in  std_logic;
    s_axis_tx_tdata               : out std_logic_vector(0 to XIL_DATA_WIDTH-1);
    s_axis_tx_tstrb               : out std_logic_vector(0 to XIL_STRB_WIDTH-1);
    s_axis_tx_tuser               : out std_logic_vector(0 to 3);
    s_axis_tx_tlast               : out std_logic;
    s_axis_tx_tvalid              : out std_logic;

    tx_cfg_gnt                    : out std_logic;
    tx_buf_av                     : in  std_logic_vector(0 to 5);
    tx_err_drop                   : in  std_logic;
    tx_cfg_req                    : in  std_logic;

    -- Rx
    m_axis_rx_tdata               : in  std_logic_vector(0 to XIL_DATA_WIDTH-1);
    m_axis_rx_tstrb               : in  std_logic_vector(0 to XIL_STRB_WIDTH-1);
    m_axis_rx_tlast               : in  std_logic;
    m_axis_rx_tvalid              : in  std_logic;
    m_axis_rx_tready              : out std_logic;
    m_axis_rx_tuser               : in  std_logic_vector(0 to 21);
    rx_np_ok                      : out std_logic;

    fc_cpld                       : in  std_logic_vector(0 to 11);
    fc_cplh                       : in  std_logic_vector(0 to 7);
    fc_npd                        : in  std_logic_vector(0 to 11);
    fc_nph                        : in  std_logic_vector(0 to 7);
    fc_pd                         : in  std_logic_vector(0 to 11);
    fc_ph                         : in  std_logic_vector(0 to 7);
    fc_sel                        : in  std_logic_vector(0 to 2);


    cfg_di                        : out std_logic_vector(0 to 31);
    cfg_byte_en                   : out std_logic_vector(0 to 3);
    cfg_dwaddr                    : out std_logic_vector(0 to 9);
    cfg_wr_en                     : out std_logic;
    cfg_rd_en                     : out std_logic;

    cfg_err_cor                   : out std_logic;
    cfg_err_ur                    : out std_logic;
    cfg_err_ecrc                  : out std_logic;
    cfg_err_cpl_timeout           : out std_logic;
    cfg_err_cpl_abort             : out std_logic;
    cfg_err_cpl_unexpect          : out std_logic;
    cfg_err_posted                : out std_logic;
    cfg_err_locked                : out std_logic;
    cfg_err_tlp_cpl_header        : out std_logic_vector(0 to 47);
    cfg_err_cpl_rdy               : in  std_logic;

    cfg_interrupt                 : out std_logic;
    cfg_interrupt_rdy             : in  std_logic;
    cfg_interrupt_assert          : out std_logic;
    cfg_interrupt_di              : out std_logic_vector(0 to 7);
    cfg_interrupt_do              : in  std_logic_vector(0 to 7);
    cfg_interrupt_mmenable        : in  std_logic_vector(0 to 2);
    cfg_interrupt_msienable       : in  std_logic;
    cfg_interrupt_msixenable      : in  std_logic;
    cfg_interrupt_msixfm          : in  std_logic;

    cfg_turnoff_ok                : out std_logic;
    cfg_to_turnoff                : in  std_logic;
    cfg_trn_pending               : out std_logic;
    cfg_pm_wake                   : out std_logic;

    cfg_bus_number                : in  std_logic_vector(0 to 7);
    cfg_device_number             : in  std_logic_vector(0 to 4);
    cfg_function_number           : in  std_logic_vector(0 to 2);
    cfg_status                    : in  std_logic_vector(0 to 15);
    cfg_command                   : in  std_logic_vector(0 to 15);
    cfg_dstatus                   : in  std_logic_vector(0 to 15);
    cfg_dcommand                  : in  std_logic_vector(0 to 15);
    cfg_lstatus                   : in  std_logic_vector(0 to 15);
    cfg_lcommand                  : in  std_logic_vector(0 to 15);
    cfg_dcommand2                 : in  std_logic_vector(0 to 15);
    cfg_pcie_link_state           : in  std_logic_vector(0 to 2);

    --- S2C Engine #0
    s2c0_user_control             : out std_logic_vector(0 to 63);
    s2c0_sop                      : out std_logic;
    s2c0_eop                      : out std_logic;
    s2c0_err                      : out std_logic;
    s2c0_data                     : out std_logic_vector(0 to DATA_WIDTH-1);
    s2c0_valid                    : out std_logic_vector(0 to REM_WIDTH-1);
    s2c0_src_rdy                  : out std_logic;
    s2c0_dst_rdy                  : in  std_logic;
    s2c0_abort                    : out std_logic;
    s2c0_abort_ack                : in  std_logic;
    s2c0_user_rst_n               : out std_logic;
    s2c0_apkt_req                 : out std_logic;
    s2c0_apkt_ready               : in  std_logic;
    s2c0_apkt_addr                : out std_logic_vector(0 to 63);
    s2c0_apkt_bcount              : out std_logic_vector(0 to 9);
    --- S2C Engine #1
    s2c1_user_control             : out std_logic_vector(0 to 63);
    s2c1_sop                      : out std_logic;
    s2c1_eop                      : out std_logic;
    s2c1_err                      : out std_logic;
    s2c1_data                     : out std_logic_vector(0 to DATA_WIDTH-1);
    s2c1_valid                    : out std_logic_vector(0 to REM_WIDTH-1);
    s2c1_src_rdy                  : out std_logic;
    s2c1_dst_rdy                  : in  std_logic;
    s2c1_abort                    : out std_logic;
    s2c1_abort_ack                : in  std_logic;
    s2c1_user_rst_n               : out std_logic;
    s2c1_apkt_req                 : out std_logic;
    s2c1_apkt_ready               : in  std_logic;
    s2c1_apkt_addr                : out std_logic_vector(0 to 63);
    s2c1_apkt_bcount              : out std_logic_vector(0 to 9);
    --- C2S Engine #0
    c2s0_user_status              : in  std_logic_vector(0 to 63);
    c2s0_sop                      : in  std_logic;
    c2s0_eop                      : in  std_logic;
    c2s0_data                     : in  std_logic_vector(0 to DATA_WIDTH-1);
    c2s0_valid                    : in  std_logic_vector(0 to REM_WIDTH-1);
    c2s0_src_rdy                  : in  std_logic;
    c2s0_dst_rdy                  : out std_logic;
    c2s0_abort                    : out std_logic;
    c2s0_abort_ack                : in  std_logic;
    c2s0_user_rst_n               : out std_logic;
    c2s0_apkt_req                 : out std_logic;
    c2s0_apkt_ready               : in  std_logic;
    c2s0_apkt_addr                : out std_logic_vector(0 to 63);
    c2s0_apkt_bcount              : out std_logic_vector(0 to 31);
    c2s0_apkt_eop                 : out std_logic;
    --- C2S Engine #1
    c2s1_user_status              : in  std_logic_vector(0 to 63);
    c2s1_sop                      : in  std_logic;
    c2s1_eop                      : in  std_logic;
    c2s1_data                     : in  std_logic_vector(0 to DATA_WIDTH-1);
    c2s1_valid                    : in  std_logic_vector(0 to REM_WIDTH-1);
    c2s1_src_rdy                  : in  std_logic;
    c2s1_dst_rdy                  : out std_logic;
    c2s1_abort                    : out std_logic;
    c2s1_abort_ack                : in  std_logic;
    c2s1_user_rst_n               : out std_logic;
    c2s1_apkt_req                 : out std_logic;
    c2s1_apkt_ready               : in  std_logic;
    c2s1_apkt_addr                : out std_logic_vector(0 to 63);
    c2s1_apkt_bcount              : out std_logic_vector(0 to 31);
    c2s1_apkt_eop                 : out std_logic;
    -- Target interface
    targ_wr_req                   : out std_logic;
    targ_wr_core_ready            : out std_logic;
    targ_wr_user_ready            : in  std_logic;
    targ_wr_cs                    : out std_logic_vector(0 to 5);
    targ_wr_start                 : out std_logic;
    targ_wr_addr                  : out std_logic_vector(0 to 31);
    targ_wr_count                 : out std_logic_vector(0 to 12);
    targ_wr_en                    : out std_logic;
    targ_wr_data                  : out std_logic_vector(0 to DATA_WIDTH-1);
    targ_wr_be                    : out std_logic_vector(0 to BE_WIDTH-1);

    targ_rd_req                   : out std_logic;
    targ_rd_core_ready            : out std_logic;
    targ_rd_user_ready            : in  std_logic;
    targ_rd_cs                    : out std_logic_vector(0 to 5);
    targ_rd_start                 : out std_logic;
    targ_rd_addr                  : out std_logic_vector(0 to 31);
    targ_rd_count                 : out std_logic_vector(0 to 12);
    targ_rd_en                    : out std_logic;
    targ_rd_data                  : in  std_logic_vector(0 to DATA_WIDTH-1);
    targ_rd_first_be              : out std_logic_vector(0 to BE_WIDTH-1);
    targ_rd_last_be               : out std_logic_vector(0 to BE_WIDTH-1);

    -- Register interface
    reg_wr_addr                   : out std_logic_vector(0 to ADDR_WIDTH-1);
    reg_wr_en                     : out std_logic;
    reg_wr_be                     : out std_logic_vector(0 to BE_WIDTH-1);
    reg_wr_data                   : out std_logic_vector(0 to DATA_WIDTH-1);
    reg_rd_addr                   : out std_logic_vector(0 to ADDR_WIDTH-1);
    reg_rd_be                     : out std_logic_vector(0 to BE_WIDTH-1);
    reg_rd_data                   : in  std_logic_vector(0 to DATA_WIDTH-1)

  );
end entity;

architecture behavioral of packet_dma_entity is
  
  component packet_dma
    generic (
      DATA_WIDTH                    : integer := 64;
      REM_WIDTH                     : integer := 3;
      BE_WIDTH                      : integer := 8;
      ADDR_WIDTH                    : integer := 13;--12 + (4-REM_WIDTH);
      FIFO_DADDR_WIDTH              : integer := 8;--7 + (4-REM_WIDTH);
      SUPPORT_64BIT_SYS_ADDR        : std_logic := '1';
      SUPPORT_64BIT_DESC_ADDR       : std_logic := '1';
      XIL_DATA_WIDTH                : integer := 64;           -- RX/TX interface data width
      XIL_STRB_WIDTH                : integer := 8             -- TSTRB width
    );
    port (

      user_reset                    : in  std_logic;
      user_clk                      : in  std_logic;
      user_lnk_up                   : in  std_logic;

      clk_period_in_ns              : in  std_logic_vector(0 to 7);

      user_interrupt                : in  std_logic;

      -- Tx
      s_axis_tx_tready              : in  std_logic;
      s_axis_tx_tdata               : out std_logic_vector(0 to XIL_DATA_WIDTH-1);
      s_axis_tx_tstrb               : out std_logic_vector(0 to XIL_STRB_WIDTH-1);
      s_axis_tx_tuser               : out std_logic_vector(0 to 3);
      s_axis_tx_tlast               : out std_logic;
      s_axis_tx_tvalid              : out std_logic;

      tx_cfg_gnt                    : out std_logic;
      tx_buf_av                     : in  std_logic_vector(0 to 5);
      tx_err_drop                   : in  std_logic;
      tx_cfg_req                    : in  std_logic;

      -- Rx
      m_axis_rx_tdata               : in  std_logic_vector(0 to XIL_DATA_WIDTH-1);
      m_axis_rx_tstrb               : in  std_logic_vector(0 to XIL_STRB_WIDTH-1);
      m_axis_rx_tlast               : in  std_logic;
      m_axis_rx_tvalid              : in  std_logic;
      m_axis_rx_tready              : out std_logic;
      m_axis_rx_tuser               : in  std_logic_vector(0 to 21);
      rx_np_ok                      : out std_logic;

      fc_cpld                       : in  std_logic_vector(0 to 11);
      fc_cplh                       : in  std_logic_vector(0 to 7);
      fc_npd                        : in  std_logic_vector(0 to 11);
      fc_nph                        : in  std_logic_vector(0 to 7);
      fc_pd                         : in  std_logic_vector(0 to 11);
      fc_ph                         : in  std_logic_vector(0 to 7);
      fc_sel                        : in  std_logic_vector(0 to 2);


      cfg_di                        : out std_logic_vector(0 to 31);
      cfg_byte_en                   : out std_logic_vector(0 to 3);
      cfg_dwaddr                    : out std_logic_vector(0 to 9);
      cfg_wr_en                     : out std_logic;
      cfg_rd_en                     : out std_logic;

      cfg_err_cor                   : out std_logic;
      cfg_err_ur                    : out std_logic;
      cfg_err_ecrc                  : out std_logic;
      cfg_err_cpl_timeout           : out std_logic;
      cfg_err_cpl_abort             : out std_logic;
      cfg_err_cpl_unexpect          : out std_logic;
      cfg_err_posted                : out std_logic;
      cfg_err_locked                : out std_logic;
      cfg_err_tlp_cpl_header        : out std_logic_vector(0 to 47);
      cfg_err_cpl_rdy               : in  std_logic;

      cfg_interrupt                 : out std_logic;
      cfg_interrupt_rdy             : in  std_logic;
      cfg_interrupt_assert          : out std_logic;
      cfg_interrupt_di              : out std_logic_vector(0 to 7);
      cfg_interrupt_do              : in  std_logic_vector(0 to 7);
      cfg_interrupt_mmenable        : in  std_logic_vector(0 to 2);
      cfg_interrupt_msienable       : in  std_logic;
      cfg_interrupt_msixenable      : in  std_logic;
      cfg_interrupt_msixfm          : in  std_logic;

      cfg_turnoff_ok                : out std_logic;
      cfg_to_turnoff                : in  std_logic;
      cfg_trn_pending               : out std_logic;
      cfg_pm_wake                   : out std_logic;

      cfg_bus_number                : in  std_logic_vector(0 to 7);
      cfg_device_number             : in  std_logic_vector(0 to 4);
      cfg_function_number           : in  std_logic_vector(0 to 2);
      cfg_status                    : in  std_logic_vector(0 to 15);
      cfg_command                   : in  std_logic_vector(0 to 15);
      cfg_dstatus                   : in  std_logic_vector(0 to 15);
      cfg_dcommand                  : in  std_logic_vector(0 to 15);
      cfg_lstatus                   : in  std_logic_vector(0 to 15);
      cfg_lcommand                  : in  std_logic_vector(0 to 15);
      cfg_dcommand2                 : in  std_logic_vector(0 to 15);
      cfg_pcie_link_state           : in  std_logic_vector(0 to 2);

      --- S2C Engine #0
      s2c0_user_control             : out std_logic_vector(0 to 63);
      s2c0_sop                      : out std_logic;
      s2c0_eop                      : out std_logic;
      s2c0_err                      : out std_logic;
      s2c0_data                     : out std_logic_vector(0 to DATA_WIDTH-1);
      s2c0_valid                    : out std_logic_vector(0 to REM_WIDTH-1);
      s2c0_src_rdy                  : out std_logic;
      s2c0_dst_rdy                  : in  std_logic;
      s2c0_abort                    : out std_logic;
      s2c0_abort_ack                : in  std_logic;
      s2c0_user_rst_n               : out std_logic;
      s2c0_apkt_req                 : out std_logic;
      s2c0_apkt_ready               : in  std_logic;
      s2c0_apkt_addr                : out std_logic_vector(0 to 63);
      s2c0_apkt_bcount              : out std_logic_vector(0 to 9);
      --- S2C Engine #1
      s2c1_user_control             : out std_logic_vector(0 to 63);
      s2c1_sop                      : out std_logic;
      s2c1_eop                      : out std_logic;
      s2c1_err                      : out std_logic;
      s2c1_data                     : out std_logic_vector(0 to DATA_WIDTH-1);
      s2c1_valid                    : out std_logic_vector(0 to REM_WIDTH-1);
      s2c1_src_rdy                  : out std_logic;
      s2c1_dst_rdy                  : in  std_logic;
      s2c1_abort                    : out std_logic;
      s2c1_abort_ack                : in  std_logic;
      s2c1_user_rst_n               : out std_logic;
      s2c1_apkt_req                 : out std_logic;
      s2c1_apkt_ready               : in  std_logic;
      s2c1_apkt_addr                : out std_logic_vector(0 to 63);
      s2c1_apkt_bcount              : out std_logic_vector(0 to 9);
      --- C2S Engine #0
      c2s0_user_status              : in  std_logic_vector(0 to 63);
      c2s0_sop                      : in  std_logic;
      c2s0_eop                      : in  std_logic;
      c2s0_data                     : in  std_logic_vector(0 to DATA_WIDTH-1);
      c2s0_valid                    : in  std_logic_vector(0 to REM_WIDTH-1);
      c2s0_src_rdy                  : in  std_logic;
      c2s0_dst_rdy                  : out std_logic;
      c2s0_abort                    : out std_logic;
      c2s0_abort_ack                : in  std_logic;
      c2s0_user_rst_n               : out std_logic;
      c2s0_apkt_req                 : out std_logic;
      c2s0_apkt_ready               : in  std_logic;
      c2s0_apkt_addr                : out std_logic_vector(0 to 63);
      c2s0_apkt_bcount              : out std_logic_vector(0 to 31);
      c2s0_apkt_eop                 : out std_logic;
      --- C2S Engine #1
      c2s1_user_status              : in  std_logic_vector(0 to 63);
      c2s1_sop                      : in  std_logic;
      c2s1_eop                      : in  std_logic;
      c2s1_data                     : in  std_logic_vector(0 to DATA_WIDTH-1);
      c2s1_valid                    : in  std_logic_vector(0 to REM_WIDTH-1);
      c2s1_src_rdy                  : in  std_logic;
      c2s1_dst_rdy                  : out std_logic;
      c2s1_abort                    : out std_logic;
      c2s1_abort_ack                : in  std_logic;
      c2s1_user_rst_n               : out std_logic;
      c2s1_apkt_req                 : out std_logic;
      c2s1_apkt_ready               : in  std_logic;
      c2s1_apkt_addr                : out std_logic_vector(0 to 63);
      c2s1_apkt_bcount              : out std_logic_vector(0 to 31);
      c2s1_apkt_eop                 : out std_logic;
      -- Target interface
      targ_wr_req                   : out std_logic;
      targ_wr_core_ready            : out std_logic;
      targ_wr_user_ready            : in  std_logic;
      targ_wr_cs                    : out std_logic_vector(0 to 5);
      targ_wr_start                 : out std_logic;
      targ_wr_addr                  : out std_logic_vector(0 to 31);
      targ_wr_count                 : out std_logic_vector(0 to 12);
      targ_wr_en                    : out std_logic;
      targ_wr_data                  : out std_logic_vector(0 to DATA_WIDTH-1);
      targ_wr_be                    : out std_logic_vector(0 to BE_WIDTH-1);

      targ_rd_req                   : out std_logic;
      targ_rd_core_ready            : out std_logic;
      targ_rd_user_ready            : in  std_logic;
      targ_rd_cs                    : out std_logic_vector(0 to 5);
      targ_rd_start                 : out std_logic;
      targ_rd_addr                  : out std_logic_vector(0 to 31);
      targ_rd_count                 : out std_logic_vector(0 to 12);
      targ_rd_en                    : out std_logic;
      targ_rd_data                  : in  std_logic_vector(0 to DATA_WIDTH-1);
      targ_rd_first_be              : out std_logic_vector(0 to BE_WIDTH-1);
      targ_rd_last_be               : out std_logic_vector(0 to BE_WIDTH-1);

      -- Register interface
      reg_wr_addr                   : out std_logic_vector(0 to ADDR_WIDTH-1);
      reg_wr_en                     : out std_logic;
      reg_wr_be                     : out std_logic_vector(0 to BE_WIDTH-1);
      reg_wr_data                   : out std_logic_vector(0 to DATA_WIDTH-1);
      reg_rd_addr                   : out std_logic_vector(0 to ADDR_WIDTH-1);
      reg_rd_be                     : out std_logic_vector(0 to BE_WIDTH-1);
      reg_rd_data                   : in  std_logic_vector(0 to DATA_WIDTH-1)

    );
  end component;

begin
  comp: packet_dma
    generic map (
      DATA_WIDTH                    => DATA_WIDTH,
      REM_WIDTH                     => REM_WIDTH,
      BE_WIDTH                      => BE_WIDTH,
      ADDR_WIDTH                    => ADDR_WIDTH,
      FIFO_DADDR_WIDTH              => FIFO_DADDR_WIDTH,
      SUPPORT_64BIT_SYS_ADDR        => SUPPORT_64BIT_SYS_ADDR,
      SUPPORT_64BIT_DESC_ADDR       => SUPPORT_64BIT_DESC_ADDR,
      XIL_DATA_WIDTH                => XIL_DATA_WIDTH,
      XIL_STRB_WIDTH                => XIL_STRB_WIDTH
    )
    port map (

      user_reset                    => user_reset,
      user_clk                      => user_clk,
      user_lnk_up                   => user_lnk_up,

      clk_period_in_ns              => clk_period_in_ns,

      user_interrupt                => user_interrupt,

      -- Tx
      s_axis_tx_tready              => s_axis_tx_tready,
      s_axis_tx_tdata               => s_axis_tx_tdata,
      s_axis_tx_tstrb               => s_axis_tx_tstrb,
      s_axis_tx_tuser               => s_axis_tx_tuser,
      s_axis_tx_tlast               => s_axis_tx_tlast,
      s_axis_tx_tvalid              => s_axis_tx_tvalid,

      tx_cfg_gnt                    => tx_cfg_gnt,
      tx_buf_av                     => tx_buf_av,
      tx_err_drop                   => tx_err_drop,
      tx_cfg_req                    => tx_cfg_req,

      -- Rx
      m_axis_rx_tdata               => m_axis_rx_tdata,
      m_axis_rx_tstrb               => m_axis_rx_tstrb,
      m_axis_rx_tlast               => m_axis_rx_tlast,
      m_axis_rx_tvalid              => m_axis_rx_tvalid,
      m_axis_rx_tready              => m_axis_rx_tready,
      m_axis_rx_tuser               => m_axis_rx_tuser,
      rx_np_ok                      => rx_np_ok,

      fc_cpld                       => fc_cpld,
      fc_cplh                       => fc_cplh,
      fc_npd                        => fc_npd,
      fc_nph                        => fc_nph,
      fc_pd                         => fc_pd,
      fc_ph                         => fc_ph,
      fc_sel                        => fc_sel,


      cfg_di                        => cfg_di,
      cfg_byte_en                   => cfg_byte_en,
      cfg_dwaddr                    => cfg_dwaddr,
      cfg_wr_en                     => cfg_wr_en,
      cfg_rd_en                     => cfg_rd_en,

      cfg_err_cor                   => cfg_err_cor,
      cfg_err_ur                    => cfg_err_ur,
      cfg_err_ecrc                  => cfg_err_ecrc,
      cfg_err_cpl_timeout           => cfg_err_cpl_timeout,
      cfg_err_cpl_abort             => cfg_err_cpl_abort,
      cfg_err_cpl_unexpect          => cfg_err_cpl_unexpect,
      cfg_err_posted                => cfg_err_posted,
      cfg_err_locked                => cfg_err_locked,
      cfg_err_tlp_cpl_header        => cfg_err_tlp_cpl_header,
      cfg_err_cpl_rdy               => cfg_err_cpl_rdy,

      cfg_interrupt                 => cfg_interrupt,
      cfg_interrupt_rdy             => cfg_interrupt_rdy,
      cfg_interrupt_assert          => cfg_interrupt_assert,
      cfg_interrupt_di              => cfg_interrupt_di,
      cfg_interrupt_do              => cfg_interrupt_do,
      cfg_interrupt_mmenable        => cfg_interrupt_mmenable,
      cfg_interrupt_msienable       => cfg_interrupt_msienable,
      cfg_interrupt_msixenable      => cfg_interrupt_msixenable,
      cfg_interrupt_msixfm          => cfg_interrupt_msixfm,

      cfg_turnoff_ok                => cfg_turnoff_ok,
      cfg_to_turnoff                => cfg_to_turnoff,
      cfg_trn_pending               => cfg_trn_pending,
      cfg_pm_wake                   => cfg_pm_wake,

      cfg_bus_number                => cfg_bus_number,
      cfg_device_number             => cfg_device_number,
      cfg_function_number           => cfg_function_number,
      cfg_status                    => cfg_status,
      cfg_command                   => cfg_command,
      cfg_dstatus                   => cfg_dstatus,
      cfg_dcommand                  => cfg_dcommand,
      cfg_lstatus                   => cfg_lstatus,
      cfg_lcommand                  => cfg_lcommand,
      cfg_dcommand2                 => cfg_dcommand2,
      cfg_pcie_link_state           => cfg_pcie_link_state,

      --- S2C Engine #0
      s2c0_user_control             => s2c0_user_control,
      s2c0_sop                      => s2c0_sop,
      s2c0_eop                      => s2c0_eop,
      s2c0_err                      => s2c0_err,
      s2c0_data                     => s2c0_data,
      s2c0_valid                    => s2c0_valid,
      s2c0_src_rdy                  => s2c0_src_rdy,
      s2c0_dst_rdy                  => s2c0_dst_rdy,
      s2c0_abort                    => s2c0_abort,
      s2c0_abort_ack                => s2c0_abort_ack,
      s2c0_user_rst_n               => s2c0_user_rst_n,
      s2c0_apkt_req                 => s2c0_apkt_req,
      s2c0_apkt_ready               => s2c0_apkt_ready,
      s2c0_apkt_addr                => s2c0_apkt_addr,
      s2c0_apkt_bcount              => s2c0_apkt_bcount,
      --- S2C Engine #1
      s2c1_user_control             => s2c1_user_control,
      s2c1_sop                      => s2c1_sop,
      s2c1_eop                      => s2c1_eop,
      s2c1_err                      => s2c1_err,
      s2c1_data                     => s2c1_data,
      s2c1_valid                    => s2c1_valid,
      s2c1_src_rdy                  => s2c1_src_rdy,
      s2c1_dst_rdy                  => s2c1_dst_rdy,
      s2c1_abort                    => s2c1_abort,
      s2c1_abort_ack                => s2c1_abort_ack,
      s2c1_user_rst_n               => s2c1_user_rst_n,
      s2c1_apkt_req                 => s2c1_apkt_req,
      s2c1_apkt_ready               => s2c1_apkt_ready,
      s2c1_apkt_addr                => s2c1_apkt_addr,
      s2c1_apkt_bcount              => s2c1_apkt_bcount,
      --- C2S Engine #0
      c2s0_user_status              => c2s0_user_status,
      c2s0_sop                      => c2s0_sop,
      c2s0_eop                      => c2s0_eop,
      c2s0_data                     => c2s0_data,
      c2s0_valid                    => c2s0_valid,
      c2s0_src_rdy                  => c2s0_src_rdy,
      c2s0_dst_rdy                  => c2s0_dst_rdy,
      c2s0_abort                    => c2s0_abort,
      c2s0_abort_ack                => c2s0_abort_ack,
      c2s0_user_rst_n               => c2s0_user_rst_n,
      c2s0_apkt_req                 => c2s0_apkt_req,
      c2s0_apkt_ready               => c2s0_apkt_ready,
      c2s0_apkt_addr                => c2s0_apkt_addr,
      c2s0_apkt_bcount              => c2s0_apkt_bcount,
      c2s0_apkt_eop                 => c2s0_apkt_eop,
      --- C2S Engine #1
      c2s1_user_status              => c2s1_user_status,
      c2s1_sop                      => c2s1_sop,
      c2s1_eop                      => c2s1_eop,
      c2s1_data                     => c2s1_data,
      c2s1_valid                    => c2s1_valid,
      c2s1_src_rdy                  => c2s1_src_rdy,
      c2s1_dst_rdy                  => c2s1_dst_rdy,
      c2s1_abort                    => c2s1_abort,
      c2s1_abort_ack                => c2s1_abort_ack,
      c2s1_user_rst_n               => c2s1_user_rst_n,
      c2s1_apkt_req                 => c2s1_apkt_req,
      c2s1_apkt_ready               => c2s1_apkt_ready,
      c2s1_apkt_addr                => c2s1_apkt_addr,
      c2s1_apkt_bcount              => c2s1_apkt_bcount,
      c2s1_apkt_eop                 => c2s1_apkt_eop,
      -- Target interface
      targ_wr_req                   => targ_wr_req,
      targ_wr_core_ready            => targ_wr_core_ready,
      targ_wr_user_ready            => targ_wr_user_ready,
      targ_wr_cs                    => targ_wr_cs,
      targ_wr_start                 => targ_wr_start,
      targ_wr_addr                  => targ_wr_addr,
      targ_wr_count                 => targ_wr_count,
      targ_wr_en                    => targ_wr_en,
      targ_wr_data                  => targ_wr_data,
      targ_wr_be                    => targ_wr_be,

      targ_rd_req                   => targ_rd_req,
      targ_rd_core_ready            => targ_rd_core_ready,
      targ_rd_user_ready            => targ_rd_user_ready,
      targ_rd_cs                    => targ_rd_cs,
      targ_rd_start                 => targ_rd_start,
      targ_rd_addr                  => targ_rd_addr,
      targ_rd_count                 => targ_rd_count,
      targ_rd_en                    => targ_rd_en,
      targ_rd_data                  => targ_rd_data,
      targ_rd_first_be              => targ_rd_first_be,
      targ_rd_last_be               => targ_rd_last_be,

      -- Register interface
      reg_wr_addr                   => reg_wr_addr,
      reg_wr_en                     => reg_wr_en,
      reg_wr_be                     => reg_wr_be,
      reg_wr_data                   => reg_wr_data,
      reg_rd_addr                   => reg_rd_addr,
      reg_rd_be                     => reg_rd_be,
      reg_rd_data                   => reg_rd_data
    );
end architecture;

