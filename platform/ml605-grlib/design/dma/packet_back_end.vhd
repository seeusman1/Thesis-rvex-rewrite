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

entity dma_back_end_pkt_entity is
  generic (
    BE_REG_RD_PIPELINE            : integer := 0; -- Number of clocks to add to the register read pipeline. Valid values 0-4. >= 1 adds a pipe register to the data mux.
    REG_ADDR_WIDTH                : integer := 13 -- Register BAR is 64KBytes
  );
  port (

    rst_n                         : in  std_logic;
    clk                           : in  std_logic;

    tx_buf_av                     : in  std_logic_vector(0 to 5);
    tx_err_drop                   : in  std_logic;
    tx_cfg_req                    : in  std_logic;
    s_axis_tx_tready              : in  std_logic;
    s_axis_tx_tdata               : out std_logic_vector(0 to XIL_DATA_WIDTH-1);
    s_axis_tx_tstrb               : out std_logic_vector(0 to XIL_STRB_WIDTH-1);
    s_axis_tx_tuser               : out std_logic_vector(0 to 3);
    s_axis_tx_tlast               : out std_logic;
    s_axis_tx_tvalid              : out std_logic;
    tx_cfg_gnt                    : out std_logic;

    m_axis_rx_tdata               : in  std_logic_vector(0 to XIL_DATA_WIDTH-1);
    m_axis_rx_tstrb               : in  std_logic_vector(0 to XIL_STRB_WIDTH-1);
    m_axis_rx_tlast               : in  std_logic;
    m_axis_rx_tvalid              : in  std_logic;
    m_axis_rx_tready              : out std_logic;
    m_axis_rx_tuser               : in  std_logic_vector(0 to 21);
    rx_np_ok                      : out std_logic;
    mgmt_mst_en                   : in  std_logic;
    mgmt_msi_en                   : in  std_logic;
    mgmt_max_payload_size         : in  std_logic_vector(0 to 2);
    mgmt_max_rd_req_size          : in  std_logic_vector(0 to 2);
    mgmt_clk_period_in_ns         : in  std_logic_vector(0 to 7);
    mgmt_version                  : out std_logic_vector(0 to 31);
    mgmt_pcie_version             : in  std_logic_vector(0 to 31);
    mgmt_user_version             : in  std_logic_vector(0 to 31);
    mgmt_cfg_id                   : in  std_logic_vector(0 to 15);
    mgmt_interrupt                : out std_logic;
    user_interrupt                : in  std_logic;

    mgmt_ch_infinite              : in  std_logic;
    mgmt_cd_infinite              : in  std_logic;
    mgmt_ch_credits               : in  std_logic_vector(0 to 7);
    mgmt_cd_credits               : in  std_logic_vector(0 to 11);

    mgmt_adv_cpl_timeout_disable  : out std_logic;
    mgmt_adv_cpl_timeout_value    : out std_logic_vector(0 to 3);
    mgmt_cpl_timeout_disable      : in  std_logic;
    mgmt_cpl_timeout_value        : in  std_logic_vector(0 to 3);

    err_pkt_poison                : out std_logic;
    err_cpl_to_closed_tag         : out std_logic;
    err_cpl_timeout               : out std_logic;
    err_pkt_header                : out std_logic_vector(0 to 127);
    cpl_tag_active                : out std_logic;

    -- Master DWORD Read/Write Interface
    mst_ready                     : out std_logic;
    mst_req                       : in  std_logic;
    mst_type                      : in  std_logic_vector(0 to 6);
    mst_data                      : in  std_logic_vector(0 to 31);
    mst_be                        : in  std_logic_vector(0 to 3);
    mst_addr                      : in  std_logic_vector(0 to 63);
    mst_msgcode                   : in  std_logic_vector(0 to 7);
    mst_rd_data                   : out std_logic_vector(0 to 31);
    mst_status                    : out std_logic_vector(0 to 2);
    mst_done                      : out std_logic;

    -- DMA Card to System Engine #0 User Interface
    c2s0_cfg_constants            : in  std_logic_vector(0 to 63);

    c2s0_desc_req                 : in  std_logic;
    c2s0_desc_ready               : out std_logic;
    c2s0_desc_ptr                 : in  std_logic_vector(0 to 31);
    c2s0_desc_data                : in  std_logic_vector(0 to DESC_WIDTH-1);
    c2s0_desc_abort               : in  std_logic;
    c2s0_desc_abort_ack           : out std_logic;
    c2s0_desc_rst_n               : in  std_logic;

    c2s0_desc_done                : out std_logic;
    c2s0_desc_done_channel        : out std_logic_vector(0 to 7);
    c2s0_desc_done_status         : out std_logic_vector(0 to DESC_STATUS_WIDTH);

    c2s0_cmd_rst_n                : out std_logic;
    c2s0_cmd_req                  : out std_logic;
    c2s0_cmd_ready                : in  std_logic;
    c2s0_cmd_first_chain          : out std_logic;
    c2s0_cmd_last_chain           : out std_logic;
    c2s0_cmd_addr                 : out std_logic_vector(0 to 63);
    c2s0_cmd_bcount               : out std_logic_vector(0 to 31);
    c2s0_cmd_user_control         : out std_logic_vector(0 to 63);
    c2s0_cmd_abort                : out std_logic;
    c2s0_cmd_abort_ack            : in  std_logic;

    c2s0_data_req                 : out std_logic;
    c2s0_data_ready               : in  std_logic;
    c2s0_data_req_remain          : out std_logic_vector(0 to CORE_REMAIN_WIDTH-1);
    c2s0_data_req_last_desc       : out std_logic;
    c2s0_data_addr                : out std_logic_vector(0 to 63);
    c2s0_data_bcount              : out std_logic_vector(0 to 9);
    c2s0_data_stop                : in  std_logic;
    c2s0_data_stop_bcount         : in  std_logic_vector(0 to 9);

    c2s0_data_en                  : out std_logic;
    c2s0_data_remain              : out std_logic_vector(0 to CORE_REMAIN_WIDTH-1);
    c2s0_data_valid               : out std_logic_vector(0 to CORE_REMAIN_WIDTH);
    c2s0_data_first_req           : out std_logic;
    c2s0_data_last_req            : out std_logic;
    c2s0_data_first_desc          : out std_logic;
    c2s0_data_last_desc           : out std_logic;
    c2s0_data_first_chain         : out std_logic;
    c2s0_data_last_chain          : out std_logic;
    c2s0_data_sop                 : in  std_logic;
    c2s0_data_eop                 : in  std_logic;
    c2s0_data_data                : in  std_logic_vector(0 to CORE_DATA_WIDTH);
    c2s0_data_user_status         : in  std_logic_vector(0 to 63);

    -- DMA Card to System Engine #1 User Interface
    c2s1_cfg_constants            : in  std_logic_vector(0 to 63);

    c2s1_desc_req                 : in  std_logic;
    c2s1_desc_ready               : out std_logic;
    c2s1_desc_ptr                 : in  std_logic_vector(0 to 31);
    c2s1_desc_data                : in  std_logic_vector(0 to DESC_WIDTH-1);
    c2s1_desc_abort               : in  std_logic;
    c2s1_desc_abort_ack           : out std_logic;
    c2s1_desc_rst_n               : in  std_logic;

    c2s1_desc_done                : out std_logic;
    c2s1_desc_done_channel        : out std_logic_vector(0 to 7);
    c2s1_desc_done_status         : out std_logic_vector(0 to DESC_STATUS_WIDTH);

    c2s1_cmd_rst_n                : out std_logic;
    c2s1_cmd_req                  : out std_logic;
    c2s1_cmd_ready                : in  std_logic;
    c2s1_cmd_first_chain          : out std_logic;
    c2s1_cmd_last_chain           : out std_logic;
    c2s1_cmd_addr                 : out std_logic_vector(0 to 63);
    c2s1_cmd_bcount               : out std_logic_vector(0 to 31);
    c2s1_cmd_user_control         : out std_logic_vector(0 to 63);
    c2s1_cmd_abort                : out std_logic;
    c2s1_cmd_abort_ack            : in  std_logic;

    c2s1_data_req                 : out std_logic;
    c2s1_data_ready               : in  std_logic;
    c2s1_data_req_remain          : out std_logic_vector(0 to CORE_REMAIN_WIDTH-1);
    c2s1_data_req_last_desc       : out std_logic;
    c2s1_data_addr                : out std_logic_vector(0 to 63);
    c2s1_data_bcount              : out std_logic_vector(0 to 9);
    c2s1_data_stop                : in  std_logic;
    c2s1_data_stop_bcount         : in  std_logic_vector(0 to 9);

    c2s1_data_en                  : out std_logic;
    c2s1_data_remain              : out std_logic_vector(0 to CORE_REMAIN_WIDTH-1);
    c2s1_data_valid               : out std_logic_vector(0 to CORE_REMAIN_WIDTH);
    c2s1_data_first_req           : out std_logic;
    c2s1_data_last_req            : out std_logic;
    c2s1_data_first_desc          : out std_logic;
    c2s1_data_last_desc           : out std_logic;
    c2s1_data_first_chain         : out std_logic;
    c2s1_data_last_chain          : out std_logic;
    c2s1_data_sop                 : in  std_logic;
    c2s1_data_eop                 : in  std_logic;
    c2s1_data_data                : in  std_logic_vector(0 to CORE_DATA_WIDTH);
    c2s1_data_user_status         : in  std_logic_vector(0 to 63);
    -- DMA System to Card Engine #0 User Interface
    s2c0_cfg_constants            : in  std_logic_vector(0 to 63);

    s2c0_desc_req                 : in  std_logic;
    s2c0_desc_ready               : out std_logic;
    s2c0_desc_ptr                 : in  std_logic_vector(0 to 31);
    s2c0_desc_data                : in  std_logic_vector(0 to 255);
    s2c0_desc_abort               : in  std_logic;
    s2c0_desc_abort_ack           : out std_logic;
    s2c0_desc_rst_n               : in  std_logic;

    s2c0_desc_done                : out std_logic;
    s2c0_desc_done_channel        : out std_logic_vector(0 to 7);
    s2c0_desc_done_status         : out std_logic_vector(0 to 159);

    s2c0_cmd_rst_n                : out std_logic;
    s2c0_cmd_req                  : out std_logic;
    s2c0_cmd_ready                : in  std_logic;
    s2c0_cmd_addr                 : out std_logic_vector(0 to 63);
    s2c0_cmd_bcount               : out std_logic_vector(0 to 9);
    s2c0_cmd_user_control         : out std_logic_vector(0 to 63);
    s2c0_cmd_abort                : out std_logic;
    s2c0_cmd_abort_ack            : in  std_logic;
    s2c0_cmd_stop                 : in  std_logic;
    s2c0_cmd_stop_bcount          : in  std_logic_vector(0 to 9);

    s2c0_data_req                 : out std_logic;
    s2c0_data_ready               : in  std_logic;
    s2c0_data_addr                : out std_logic_vector(0 to 63);
    s2c0_data_bcount              : out std_logic_vector(0 to 9);
    s2c0_data_en                  : out std_logic;
    s2c0_data_error               : out std_logic;
    s2c0_data_remain              : out std_logic_vector(0 to CORE_REMAIN_WIDTH-1);
    s2c0_data_valid               : out std_logic_vector(0 to CORE_REMAIN_WIDTH);
    s2c0_data_first_req           : out std_logic;
    s2c0_data_last_req            : out std_logic;
    s2c0_data_first_desc          : out std_logic;
    s2c0_data_last_desc           : out std_logic;
    s2c0_data_first_chain         : out std_logic;
    s2c0_data_last_chain          : out std_logic;
    s2c0_data_data                : out std_logic_vector(0 to CORE_DATA_WIDTH-1);
    s2c0_data_user_control        : out std_logic_vector(0 to 63);

    -- DMA System to Card Engine #1 User Interface
    s2c1_cfg_constants            : in  std_logic_vector(0 to 63);

    s2c1_desc_req                 : in  std_logic;
    s2c1_desc_ready               : out std_logic;
    s2c1_desc_ptr                 : in  std_logic_vector(0 to 31);
    s2c1_desc_data                : in  std_logic_vector(0 to 255);
    s2c1_desc_abort               : in  std_logic;
    s2c1_desc_abort_ack           : out std_logic;
    s2c1_desc_rst_n               : in  std_logic;

    s2c1_desc_done                : out std_logic;
    s2c1_desc_done_channel        : out std_logic_vector(0 to 7);
    s2c1_desc_done_status         : out std_logic_vector(0 to 159);

    s2c1_cmd_rst_n                : out std_logic;
    s2c1_cmd_req                  : out std_logic;
    s2c1_cmd_ready                : in  std_logic;
    s2c1_cmd_addr                 : out std_logic_vector(0 to 63);
    s2c1_cmd_bcount               : out std_logic_vector(0 to 9);
    s2c1_cmd_user_control         : out std_logic_vector(0 to 63);
    s2c1_cmd_abort                : out std_logic;
    s2c1_cmd_abort_ack            : in  std_logic;
    s2c1_cmd_stop                 : in  std_logic;
    s2c1_cmd_stop_bcount          : in  std_logic_vector(0 to 9);

    s2c1_data_req                 : out std_logic;
    s2c1_data_ready               : in  std_logic;
    s2c1_data_addr                : out std_logic_vector(0 to 63);
    s2c1_data_bcount              : out std_logic_vector(0 to 9);
    s2c1_data_en                  : out std_logic;
    s2c1_data_error               : out std_logic;
    s2c1_data_remain              : out std_logic_vector(0 to CORE_REMAIN_WIDTH-1);
    s2c1_data_valid               : out std_logic_vector(0 to CORE_REMAIN_WIDTH);
    s2c1_data_first_req           : out std_logic;
    s2c1_data_last_req            : out std_logic;
    s2c1_data_first_desc          : out std_logic;
    s2c1_data_last_desc           : out std_logic;
    s2c1_data_first_chain         : out std_logic;
    s2c1_data_last_chain          : out std_logic;
    s2c1_data_data                : out std_logic_vector(0 to CORE_DATA_WIDTH-1);
    s2c1_data_user_control        : out std_logic_vector(0 to 63);
    -- Target Write Interface
    targ_wr_req                   : out std_logic;
    targ_wr_core_ready            : out std_logic;
    targ_wr_user_ready            : in  std_logic;
    targ_wr_cs                    : out std_logic_vector(0 to 5);
    targ_wr_start                 : out std_logic;
    targ_wr_addr                  : out std_logic_vector(0 to 31);
    targ_wr_count                 : out std_logic_vector(0 to 12);
    targ_wr_en                    : out std_logic;
    targ_wr_data                  : out std_logic_vector(0 to CORE_DATA_WIDTH-1);
    targ_wr_be                    : out std_logic_vector(0 to CORE_BE_WIDTH-1);

    -- Target Read Interface
    targ_rd_req                   : out std_logic;
    targ_rd_core_ready            : out std_logic;
    targ_rd_user_ready            : in  std_logic;
    targ_rd_cs                    : out std_logic_vector(0 to 5);
    targ_rd_start                 : out std_logic;
    targ_rd_addr                  : out std_logic_vector(0 to 31);
    targ_rd_first_be              : in  std_logic_vector(0 to CORE_BE_WIDTH-1);
    targ_rd_last_be               : out std_logic_vector(0 to CORE_BE_WIDTH-1);
    targ_rd_count                 : out std_logic_vector(0 to 12);
    targ_rd_en                    : out std_logic;
    targ_rd_data                  : in  std_logic_vector(0 to CORE_DATA_WIDTH-1);

    -- Register Interface
    reg_wr_addr                   : out std_logic_vector(0 to REG_ADDR_WIDTH-1);
    reg_wr_en                     : out std_logic;
    reg_wr_be                     : out std_logic_vector(0 to CORE_BE_WIDTH-1);
    reg_wr_data                   : out std_logic_vector(0 to CORE_DATA_WIDTH-1);
    reg_rd_addr                   : out std_logic_vector(0 to REG_ADDR_WIDTH-1);
    reg_rd_be                     : out std_logic_vector(0 to CORE_BE_WIDTH-1);
    reg_rd_data                   : in  std_logic_vector(0 to CORE_DATA_WIDTH-1)

  );
end entity;

architecture behavioral of dma_back_end_pkt_entity is
  
  component dma_back_end_pkt
    generic (
      BE_REG_RD_PIPELINE            : integer := 0;     -- Number of clocks to add to the register read pipeline. Valid values 0-4. >= 1 adds a pipe register to the data mux.
      REG_ADDR_WIDTH                : integer := 13 -- Register BAR is 64KBytes
    );
    port (

      rst_n                         : in  std_logic;
      clk                           : in  std_logic;

      tx_buf_av                     : in  std_logic_vector(0 to 5);
      tx_err_drop                   : in  std_logic;
      tx_cfg_req                    : in  std_logic;
      s_axis_tx_tready              : in  std_logic;
      s_axis_tx_tdata               : out std_logic_vector(0 to XIL_DATA_WIDTH-1);
      s_axis_tx_tstrb               : out std_logic_vector(0 to XIL_STRB_WIDTH-1);
      s_axis_tx_tuser               : out std_logic_vector(0 to 3);
      s_axis_tx_tlast               : out std_logic;
      s_axis_tx_tvalid              : out std_logic;
      tx_cfg_gnt                    : out std_logic;

      m_axis_rx_tdata               : in  std_logic_vector(0 to XIL_DATA_WIDTH-1);
      m_axis_rx_tstrb               : in  std_logic_vector(0 to XIL_STRB_WIDTH-1);
      m_axis_rx_tlast               : in  std_logic;
      m_axis_rx_tvalid              : in  std_logic;
      m_axis_rx_tready              : out std_logic;
      m_axis_rx_tuser               : in  std_logic_vector(0 to 21);
      rx_np_ok                      : out std_logic;
      mgmt_mst_en                   : in  std_logic;
      mgmt_msi_en                   : in  std_logic;
      mgmt_max_payload_size         : in  std_logic_vector(0 to 2);
      mgmt_max_rd_req_size          : in  std_logic_vector(0 to 2);
      mgmt_clk_period_in_ns         : in  std_logic_vector(0 to 7);
      mgmt_version                  : out std_logic_vector(0 to 31);
      mgmt_pcie_version             : in  std_logic_vector(0 to 31);
      mgmt_user_version             : in  std_logic_vector(0 to 31);
      mgmt_cfg_id                   : in  std_logic_vector(0 to 15);
      mgmt_interrupt                : out std_logic;
      user_interrupt                : in  std_logic;

      mgmt_ch_infinite              : in  std_logic;
      mgmt_cd_infinite              : in  std_logic;
      mgmt_ch_credits               : in  std_logic_vector(0 to 7);
      mgmt_cd_credits               : in  std_logic_vector(0 to 11);

      mgmt_adv_cpl_timeout_disable  : out std_logic;
      mgmt_adv_cpl_timeout_value    : out std_logic_vector(0 to 3);
      mgmt_cpl_timeout_disable      : in  std_logic;
      mgmt_cpl_timeout_value        : in  std_logic_vector(0 to 3);

      err_pkt_poison                : out std_logic;
      err_cpl_to_closed_tag         : out std_logic;
      err_cpl_timeout               : out std_logic;
      err_pkt_header                : out std_logic_vector(0 to 127);
      cpl_tag_active                : out std_logic;

      -- Master DWORD Read/Write Interface
      mst_ready                     : out std_logic;
      mst_req                       : in  std_logic;
      mst_type                      : in  std_logic_vector(0 to 6);
      mst_data                      : in  std_logic_vector(0 to 31);
      mst_be                        : in  std_logic_vector(0 to 3);
      mst_addr                      : in  std_logic_vector(0 to 63);
      mst_msgcode                   : in  std_logic_vector(0 to 7);
      mst_rd_data                   : out std_logic_vector(0 to 31);
      mst_status                    : out std_logic_vector(0 to 2);
      mst_done                      : out std_logic;

      -- DMA Card to System Engine #0 User Interface
      c2s0_cfg_constants            : in  std_logic_vector(0 to 63);

      c2s0_desc_req                 : in  std_logic;
      c2s0_desc_ready               : out std_logic;
      c2s0_desc_ptr                 : in  std_logic_vector(0 to 31);
      c2s0_desc_data                : in  std_logic_vector(0 to DESC_WIDTH-1);
      c2s0_desc_abort               : in  std_logic;
      c2s0_desc_abort_ack           : out std_logic;
      c2s0_desc_rst_n               : in  std_logic;

      c2s0_desc_done                : out std_logic;
      c2s0_desc_done_channel        : out std_logic_vector(0 to 7);
      c2s0_desc_done_status         : out std_logic_vector(0 to DESC_STATUS_WIDTH);

      c2s0_cmd_rst_n                : out std_logic;
      c2s0_cmd_req                  : out std_logic;
      c2s0_cmd_ready                : in  std_logic;
      c2s0_cmd_first_chain          : out std_logic;
      c2s0_cmd_last_chain           : out std_logic;
      c2s0_cmd_addr                 : out std_logic_vector(0 to 63);
      c2s0_cmd_bcount               : out std_logic_vector(0 to 31);
      c2s0_cmd_user_control         : out std_logic_vector(0 to 63);
      c2s0_cmd_abort                : out std_logic;
      c2s0_cmd_abort_ack            : in  std_logic;

      c2s0_data_req                 : out std_logic;
      c2s0_data_ready               : in  std_logic;
      c2s0_data_req_remain          : out std_logic_vector(0 to CORE_REMAIN_WIDTH-1);
      c2s0_data_req_last_desc       : out std_logic;
      c2s0_data_addr                : out std_logic_vector(0 to 63);
      c2s0_data_bcount              : out std_logic_vector(0 to 9);
      c2s0_data_stop                : in  std_logic;
      c2s0_data_stop_bcount         : in  std_logic_vector(0 to 9);

      c2s0_data_en                  : out std_logic;
      c2s0_data_remain              : out std_logic_vector(0 to CORE_REMAIN_WIDTH-1);
      c2s0_data_valid               : out std_logic_vector(0 to CORE_REMAIN_WIDTH);
      c2s0_data_first_req           : out std_logic;
      c2s0_data_last_req            : out std_logic;
      c2s0_data_first_desc          : out std_logic;
      c2s0_data_last_desc           : out std_logic;
      c2s0_data_first_chain         : out std_logic;
      c2s0_data_last_chain          : out std_logic;
      c2s0_data_sop                 : in  std_logic;
      c2s0_data_eop                 : in  std_logic;
      c2s0_data_data                : in  std_logic_vector(0 to CORE_DATA_WIDTH);
      c2s0_data_user_status         : in  std_logic_vector(0 to 63);

      -- DMA Card to System Engine #1 User Interface
      c2s1_cfg_constants            : in  std_logic_vector(0 to 63);

      c2s1_desc_req                 : in  std_logic;
      c2s1_desc_ready               : out std_logic;
      c2s1_desc_ptr                 : in  std_logic_vector(0 to 31);
      c2s1_desc_data                : in  std_logic_vector(0 to DESC_WIDTH-1);
      c2s1_desc_abort               : in  std_logic;
      c2s1_desc_abort_ack           : out std_logic;
      c2s1_desc_rst_n               : in  std_logic;

      c2s1_desc_done                : out std_logic;
      c2s1_desc_done_channel        : out std_logic_vector(0 to 7);
      c2s1_desc_done_status         : out std_logic_vector(0 to DESC_STATUS_WIDTH);

      c2s1_cmd_rst_n                : out std_logic;
      c2s1_cmd_req                  : out std_logic;
      c2s1_cmd_ready                : in  std_logic;
      c2s1_cmd_first_chain          : out std_logic;
      c2s1_cmd_last_chain           : out std_logic;
      c2s1_cmd_addr                 : out std_logic_vector(0 to 63);
      c2s1_cmd_bcount               : out std_logic_vector(0 to 31);
      c2s1_cmd_user_control         : out std_logic_vector(0 to 63);
      c2s1_cmd_abort                : out std_logic;
      c2s1_cmd_abort_ack            : in  std_logic;

      c2s1_data_req                 : out std_logic;
      c2s1_data_ready               : in  std_logic;
      c2s1_data_req_remain          : out std_logic_vector(0 to CORE_REMAIN_WIDTH-1);
      c2s1_data_req_last_desc       : out std_logic;
      c2s1_data_addr                : out std_logic_vector(0 to 63);
      c2s1_data_bcount              : out std_logic_vector(0 to 9);
      c2s1_data_stop                : in  std_logic;
      c2s1_data_stop_bcount         : in  std_logic_vector(0 to 9);

      c2s1_data_en                  : out std_logic;
      c2s1_data_remain              : out std_logic_vector(0 to CORE_REMAIN_WIDTH-1);
      c2s1_data_valid               : out std_logic_vector(0 to CORE_REMAIN_WIDTH);
      c2s1_data_first_req           : out std_logic;
      c2s1_data_last_req            : out std_logic;
      c2s1_data_first_desc          : out std_logic;
      c2s1_data_last_desc           : out std_logic;
      c2s1_data_first_chain         : out std_logic;
      c2s1_data_last_chain          : out std_logic;
      c2s1_data_sop                 : in  std_logic;
      c2s1_data_eop                 : in  std_logic;
      c2s1_data_data                : in  std_logic_vector(0 to CORE_DATA_WIDTH);
      c2s1_data_user_status         : in  std_logic_vector(0 to 63);
      -- DMA System to Card Engine #0 User Interface
      s2c0_cfg_constants            : in  std_logic_vector(0 to 63);

      s2c0_desc_req                 : in  std_logic;
      s2c0_desc_ready               : out std_logic;
      s2c0_desc_ptr                 : in  std_logic_vector(0 to 31);
      s2c0_desc_data                : in  std_logic_vector(0 to 255);
      s2c0_desc_abort               : in  std_logic;
      s2c0_desc_abort_ack           : out std_logic;
      s2c0_desc_rst_n               : in  std_logic;

      s2c0_desc_done                : out std_logic;
      s2c0_desc_done_channel        : out std_logic_vector(0 to 7);
      s2c0_desc_done_status         : out std_logic_vector(0 to 159);

      s2c0_cmd_rst_n                : out std_logic;
      s2c0_cmd_req                  : out std_logic;
      s2c0_cmd_ready                : in  std_logic;
      s2c0_cmd_addr                 : out std_logic_vector(0 to 63);
      s2c0_cmd_bcount               : out std_logic_vector(0 to 9);
      s2c0_cmd_user_control         : out std_logic_vector(0 to 63);
      s2c0_cmd_abort                : out std_logic;
      s2c0_cmd_abort_ack            : in  std_logic;
      s2c0_cmd_stop                 : in  std_logic;
      s2c0_cmd_stop_bcount          : in  std_logic_vector(0 to 9);

      s2c0_data_req                 : out std_logic;
      s2c0_data_ready               : in  std_logic;
      s2c0_data_addr                : out std_logic_vector(0 to 63);
      s2c0_data_bcount              : out std_logic_vector(0 to 9);
      s2c0_data_en                  : out std_logic;
      s2c0_data_error               : out std_logic;
      s2c0_data_remain              : out std_logic_vector(0 to CORE_REMAIN_WIDTH-1);
      s2c0_data_valid               : out std_logic_vector(0 to CORE_REMAIN_WIDTH);
      s2c0_data_first_req           : out std_logic;
      s2c0_data_last_req            : out std_logic;
      s2c0_data_first_desc          : out std_logic;
      s2c0_data_last_desc           : out std_logic;
      s2c0_data_first_chain         : out std_logic;
      s2c0_data_last_chain          : out std_logic;
      s2c0_data_data                : out std_logic_vector(0 to CORE_DATA_WIDTH-1);
      s2c0_data_user_control        : out std_logic_vector(0 to 63);

      -- DMA System to Card Engine #1 User Interface
      s2c1_cfg_constants            : in  std_logic_vector(0 to 63);

      s2c1_desc_req                 : in  std_logic;
      s2c1_desc_ready               : out std_logic;
      s2c1_desc_ptr                 : in  std_logic_vector(0 to 31);
      s2c1_desc_data                : in  std_logic_vector(0 to 255);
      s2c1_desc_abort               : in  std_logic;
      s2c1_desc_abort_ack           : out std_logic;
      s2c1_desc_rst_n               : in  std_logic;

      s2c1_desc_done                : out std_logic;
      s2c1_desc_done_channel        : out std_logic_vector(0 to 7);
      s2c1_desc_done_status         : out std_logic_vector(0 to 159);

      s2c1_cmd_rst_n                : out std_logic;
      s2c1_cmd_req                  : out std_logic;
      s2c1_cmd_ready                : in  std_logic;
      s2c1_cmd_addr                 : out std_logic_vector(0 to 63);
      s2c1_cmd_bcount               : out std_logic_vector(0 to 9);
      s2c1_cmd_user_control         : out std_logic_vector(0 to 63);
      s2c1_cmd_abort                : out std_logic;
      s2c1_cmd_abort_ack            : in  std_logic;
      s2c1_cmd_stop                 : in  std_logic;
      s2c1_cmd_stop_bcount          : in  std_logic_vector(0 to 9);

      s2c1_data_req                 : out std_logic;
      s2c1_data_ready               : in  std_logic;
      s2c1_data_addr                : out std_logic_vector(0 to 63);
      s2c1_data_bcount              : out std_logic_vector(0 to 9);
      s2c1_data_en                  : out std_logic;
      s2c1_data_error               : out std_logic;
      s2c1_data_remain              : out std_logic_vector(0 to CORE_REMAIN_WIDTH-1);
      s2c1_data_valid               : out std_logic_vector(0 to CORE_REMAIN_WIDTH);
      s2c1_data_first_req           : out std_logic;
      s2c1_data_last_req            : out std_logic;
      s2c1_data_first_desc          : out std_logic;
      s2c1_data_last_desc           : out std_logic;
      s2c1_data_first_chain         : out std_logic;
      s2c1_data_last_chain          : out std_logic;
      s2c1_data_data                : out std_logic_vector(0 to CORE_DATA_WIDTH-1);
      s2c1_data_user_control        : out std_logic_vector(0 to 63);
      -- Target Write Interface
      targ_wr_req                   : out std_logic;
      targ_wr_core_ready            : out std_logic;
      targ_wr_user_ready            : in  std_logic;
      targ_wr_cs                    : out std_logic_vector(0 to 5);
      targ_wr_start                 : out std_logic;
      targ_wr_addr                  : out std_logic_vector(0 to 31);
      targ_wr_count                 : out std_logic_vector(0 to 12);
      targ_wr_en                    : out std_logic;
      targ_wr_data                  : out std_logic_vector(0 to CORE_DATA_WIDTH-1);
      targ_wr_be                    : out std_logic_vector(0 to CORE_BE_WIDTH-1);

      -- Target Read Interface
      targ_rd_req                   : out std_logic;
      targ_rd_core_ready            : out std_logic;
      targ_rd_user_ready            : in  std_logic;
      targ_rd_cs                    : out std_logic_vector(0 to 5);
      targ_rd_start                 : out std_logic;
      targ_rd_addr                  : out std_logic_vector(0 to 31);
      targ_rd_first_be              : in  std_logic_vector(0 to CORE_BE_WIDTH-1);
      targ_rd_last_be               : out std_logic_vector(0 to CORE_BE_WIDTH-1);
      targ_rd_count                 : out std_logic_vector(0 to 12);
      targ_rd_en                    : out std_logic;
      targ_rd_data                  : in  std_logic_vector(0 to CORE_DATA_WIDTH-1);

      -- Register Interface
      reg_wr_addr                   : out std_logic_vector(0 to REG_ADDR_WIDTH-1);
      reg_wr_en                     : out std_logic;
      reg_wr_be                     : out std_logic_vector(0 to CORE_BE_WIDTH-1);
      reg_wr_data                   : out std_logic_vector(0 to CORE_DATA_WIDTH-1);
      reg_rd_addr                   : out std_logic_vector(0 to REG_ADDR_WIDTH-1);
      reg_rd_be                     : out std_logic_vector(0 to CORE_BE_WIDTH-1);
      reg_rd_data                   : in  std_logic_vector(0 to CORE_DATA_WIDTH-1)

    );
  end component;

begin
  comp: dma_back_end_pkt
    generic map (
      BE_REG_RD_PIPELINE            => BE_REG_RD_PIPELINE,
      REG_ADDR_WIDTH                => REG_ADDR_WIDTH
    )
    port map (

      rst_n                         => rst_n,
      clk                           => clk,

      tx_buf_av                     => tx_buf_av,
      tx_err_drop                   => tx_err_drop,
      tx_cfg_req                    => tx_cfg_req,
      s_axis_tx_tready              => s_axis_tx_tready,
      s_axis_tx_tdata               => s_axis_tx_tdata,
      s_axis_tx_tstrb               => s_axis_tx_tstrb,
      s_axis_tx_tuser               => s_axis_tx_tuser,
      s_axis_tx_tlast               => s_axis_tx_tlast,
      s_axis_tx_tvalid              => s_axis_tx_tvalid,
      tx_cfg_gnt                    => tx_cfg_gnt,

      m_axis_rx_tdata               => m_axis_rx_tdata,
      m_axis_rx_tstrb               => m_axis_rx_tstrb,
      m_axis_rx_tlast               => m_axis_rx_tlast,
      m_axis_rx_tvalid              => m_axis_rx_tvalid,
      m_axis_rx_tready              => m_axis_rx_tready,
      m_axis_rx_tuser               => m_axis_rx_tuser,
      rx_np_ok                      => rx_np_ok,
      mgmt_mst_en                   => mgmt_mst_en,
      mgmt_msi_en                   => mgmt_msi_en,
      mgmt_max_payload_size         => mgmt_max_payload_size,
      mgmt_max_rd_req_size          => mgmt_max_rd_req_size,
      mgmt_clk_period_in_ns         => mgmt_clk_period_in_ns,
      mgmt_version                  => mgmt_version,
      mgmt_pcie_version             => mgmt_pcie_version,
      mgmt_user_version             => mgmt_user_version,
      mgmt_cfg_id                   => mgmt_cfg_id,
      mgmt_interrupt                => mgmt_interrupt,
      user_interrupt                => user_interrupt,

      mgmt_ch_infinite              => mgmt_ch_infinite,
      mgmt_cd_infinite              => mgmt_cd_infinite,
      mgmt_ch_credits               => mgmt_ch_credits,
      mgmt_cd_credits               => mgmt_cd_credits,

      mgmt_adv_cpl_timeout_disable  => mgmt_adv_cpl_timeout_disable,
      mgmt_adv_cpl_timeout_value    => mgmt_adv_cpl_timeout_value,
      mgmt_cpl_timeout_disable      => mgmt_cpl_timeout_disable,
      mgmt_cpl_timeout_value        => mgmt_cpl_timeout_value,

      err_pkt_poison                => err_pkt_poison,
      err_cpl_to_closed_tag         => err_cpl_to_closed_tag,
      err_cpl_timeout               => err_cpl_timeout,
      err_pkt_header                => err_pkt_header,
      cpl_tag_active                => cpl_tag_active,

      -- Master DWORD Read/Write Interface
      mst_ready                     => mst_ready,
      mst_req                       => mst_req,
      mst_type                      => mst_type,
      mst_data                      => mst_data,
      mst_be                        => mst_be,
      mst_addr                      => mst_addr,
      mst_msgcode                   => mst_msgcode,
      mst_rd_data                   => mst_rd_data,
      mst_status                    => mst_status,
      mst_done                      => mst_done,

      -- DMA Card to System Engine #0 User Interface
      c2s0_cfg_constants            => c2s0_cfg_constants,

      c2s0_desc_req                 => c2s0_desc_req,
      c2s0_desc_ready               => c2s0_desc_ready,
      c2s0_desc_ptr                 => c2s0_desc_ptr,
      c2s0_desc_data                => c2s0_desc_data,
      c2s0_desc_abort               => c2s0_desc_abort,
      c2s0_desc_abort_ack           => c2s0_desc_abort_ack,
      c2s0_desc_rst_n               => c2s0_desc_rst_n,

      c2s0_desc_done                => c2s0_desc_done,
      c2s0_desc_done_channel        => c2s0_desc_done_channel,
      c2s0_desc_done_status         => c2s0_desc_done_status,

      c2s0_cmd_rst_n                => c2s0_cmd_rst_n,
      c2s0_cmd_req                  => c2s0_cmd_req,
      c2s0_cmd_ready                => c2s0_cmd_ready,
      c2s0_cmd_first_chain          => c2s0_cmd_first_chain,
      c2s0_cmd_last_chain           => c2s0_cmd_last_chain,
      c2s0_cmd_addr                 => c2s0_cmd_addr,
      c2s0_cmd_bcount               => c2s0_cmd_bcount,
      c2s0_cmd_user_control         => c2s0_cmd_user_control,
      c2s0_cmd_abort                => c2s0_cmd_abort,
      c2s0_cmd_abort_ack            => c2s0_cmd_abort_ack,

      c2s0_data_req                 => c2s0_data_req,
      c2s0_data_ready               => c2s0_data_ready,
      c2s0_data_req_remain          => c2s0_data_req_remain,
      c2s0_data_req_last_desc       => c2s0_data_req_last_desc,
      c2s0_data_addr                => c2s0_data_addr,
      c2s0_data_bcount              => c2s0_data_bcount,
      c2s0_data_stop                => c2s0_data_stop,
      c2s0_data_stop_bcount         => c2s0_data_stop_bcount,

      c2s0_data_en                  => c2s0_data_en,
      c2s0_data_remain              => c2s0_data_remain,
      c2s0_data_valid               => c2s0_data_valid,
      c2s0_data_first_req           => c2s0_data_first_req,
      c2s0_data_last_req            => c2s0_data_last_req,
      c2s0_data_first_desc          => c2s0_data_first_desc,
      c2s0_data_last_desc           => c2s0_data_last_desc,
      c2s0_data_first_chain         => c2s0_data_first_chain,
      c2s0_data_last_chain          => c2s0_data_last_chain,
      c2s0_data_sop                 => c2s0_data_sop,
      c2s0_data_eop                 => c2s0_data_eop,
      c2s0_data_data                => c2s0_data_data,
      c2s0_data_user_status         => c2s0_data_user_status,

      -- DMA Card to System Engine #1 User Interface
      c2s1_cfg_constants            => c2s1_cfg_constants,

      c2s1_desc_req                 => c2s1_desc_req,
      c2s1_desc_ready               => c2s1_desc_ready,
      c2s1_desc_ptr                 => c2s1_desc_ptr,
      c2s1_desc_data                => c2s1_desc_data,
      c2s1_desc_abort               => c2s1_desc_abort,
      c2s1_desc_abort_ack           => c2s1_desc_abort_ack,
      c2s1_desc_rst_n               => c2s1_desc_rst_n,

      c2s1_desc_done                => c2s1_desc_done,
      c2s1_desc_done_channel        => c2s1_desc_done_channel,
      c2s1_desc_done_status         => c2s1_desc_done_status,

      c2s1_cmd_rst_n                => c2s1_cmd_rst_n,
      c2s1_cmd_req                  => c2s1_cmd_req,
      c2s1_cmd_ready                => c2s1_cmd_ready,
      c2s1_cmd_first_chain          => c2s1_cmd_first_chain,
      c2s1_cmd_last_chain           => c2s1_cmd_last_chain,
      c2s1_cmd_addr                 => c2s1_cmd_addr,
      c2s1_cmd_bcount               => c2s1_cmd_bcount,
      c2s1_cmd_user_control         => c2s1_cmd_user_control,
      c2s1_cmd_abort                => c2s1_cmd_abort,
      c2s1_cmd_abort_ack            => c2s1_cmd_abort_ack,

      c2s1_data_req                 => c2s1_data_req,
      c2s1_data_ready               => c2s1_data_ready,
      c2s1_data_req_remain          => c2s1_data_req_remain,
      c2s1_data_req_last_desc       => c2s1_data_req_last_desc,
      c2s1_data_addr                => c2s1_data_addr,
      c2s1_data_bcount              => c2s1_data_bcount,
      c2s1_data_stop                => c2s1_data_stop,
      c2s1_data_stop_bcount         => c2s1_data_stop_bcount,

      c2s1_data_en                  => c2s1_data_en,
      c2s1_data_remain              => c2s1_data_remain,
      c2s1_data_valid               => c2s1_data_valid,
      c2s1_data_first_req           => c2s1_data_first_req,
      c2s1_data_last_req            => c2s1_data_last_req,
      c2s1_data_first_desc          => c2s1_data_first_desc,
      c2s1_data_last_desc           => c2s1_data_last_desc,
      c2s1_data_first_chain         => c2s1_data_first_chain,
      c2s1_data_last_chain          => c2s1_data_last_chain,
      c2s1_data_sop                 => c2s1_data_sop,
      c2s1_data_eop                 => c2s1_data_eop,
      c2s1_data_data                => c2s1_data_data,
      c2s1_data_user_status         => c2s1_data_user_status,
      -- DMA System to Card Engine #0 User Interface
      s2c0_cfg_constants            => s2c0_cfg_constants,

      s2c0_desc_req                 => s2c0_desc_req,
      s2c0_desc_ready               => s2c0_desc_ready,
      s2c0_desc_ptr                 => s2c0_desc_ptr,
      s2c0_desc_data                => s2c0_desc_data,
      s2c0_desc_abort               => s2c0_desc_abort,
      s2c0_desc_abort_ack           => s2c0_desc_abort_ack,
      s2c0_desc_rst_n               => s2c0_desc_rst_n,

      s2c0_desc_done                => s2c0_desc_done,
      s2c0_desc_done_channel        => s2c0_desc_done_channel,
      s2c0_desc_done_status         => s2c0_desc_done_status,

      s2c0_cmd_rst_n                => s2c0_cmd_rst_n,
      s2c0_cmd_req                  => s2c0_cmd_req,
      s2c0_cmd_ready                => s2c0_cmd_ready,
      s2c0_cmd_addr                 => s2c0_cmd_addr,
      s2c0_cmd_bcount               => s2c0_cmd_bcount,
      s2c0_cmd_user_control         => s2c0_cmd_user_control,
      s2c0_cmd_abort                => s2c0_cmd_abort,
      s2c0_cmd_abort_ack            => s2c0_cmd_abort_ack,
      s2c0_cmd_stop                 => s2c0_cmd_stop,
      s2c0_cmd_stop_bcount          => s2c0_cmd_stop_bcount,

      s2c0_data_req                 => s2c0_data_req,
      s2c0_data_ready               => s2c0_data_ready,
      s2c0_data_addr                => s2c0_data_addr,
      s2c0_data_bcount              => s2c0_data_bcount,
      s2c0_data_en                  => s2c0_data_en,
      s2c0_data_error               => s2c0_data_error,
      s2c0_data_remain              => s2c0_data_remain,
      s2c0_data_valid               => s2c0_data_valid,
      s2c0_data_first_req           => s2c0_data_first_req,
      s2c0_data_last_req            => s2c0_data_last_req,
      s2c0_data_first_desc          => s2c0_data_first_desc,
      s2c0_data_last_desc           => s2c0_data_last_desc,
      s2c0_data_first_chain         => s2c0_data_first_chain,
      s2c0_data_last_chain          => s2c0_data_last_chain,
      s2c0_data_data                => s2c0_data_data,
      s2c0_data_user_control        => s2c0_data_user_control,

      -- DMA System to Card Engine #1 User Interface
      s2c1_cfg_constants            => s2c1_cfg_constants,

      s2c1_desc_req                 => s2c1_desc_req,
      s2c1_desc_ready               => s2c1_desc_ready,
      s2c1_desc_ptr                 => s2c1_desc_ptr,
      s2c1_desc_data                => s2c1_desc_data,
      s2c1_desc_abort               => s2c1_desc_abort,
      s2c1_desc_abort_ack           => s2c1_desc_abort_ack,
      s2c1_desc_rst_n               => s2c1_desc_rst_n,

      s2c1_desc_done                => s2c1_desc_done,
      s2c1_desc_done_channel        => s2c1_desc_done_channel,
      s2c1_desc_done_status         => s2c1_desc_done_status,

      s2c1_cmd_rst_n                => s2c1_cmd_rst_n,
      s2c1_cmd_req                  => s2c1_cmd_req,
      s2c1_cmd_ready                => s2c1_cmd_ready,
      s2c1_cmd_addr                 => s2c1_cmd_addr,
      s2c1_cmd_bcount               => s2c1_cmd_bcount,
      s2c1_cmd_user_control         => s2c1_cmd_user_control,
      s2c1_cmd_abort                => s2c1_cmd_abort,
      s2c1_cmd_abort_ack            => s2c1_cmd_abort_ack,
      s2c1_cmd_stop                 => s2c1_cmd_stop,
      s2c1_cmd_stop_bcount          => s2c1_cmd_stop_bcount,

      s2c1_data_req                 => s2c1_data_req,
      s2c1_data_ready               => s2c1_data_ready,
      s2c1_data_addr                => s2c1_data_addr,
      s2c1_data_bcount              => s2c1_data_bcount,
      s2c1_data_en                  => s2c1_data_en,
      s2c1_data_error               => s2c1_data_error,
      s2c1_data_remain              => s2c1_data_remain,
      s2c1_data_valid               => s2c1_data_valid,
      s2c1_data_first_req           => s2c1_data_first_req,
      s2c1_data_last_req            => s2c1_data_last_req,
      s2c1_data_first_desc          => s2c1_data_first_desc,
      s2c1_data_last_desc           => s2c1_data_last_desc,
      s2c1_data_first_chain         => s2c1_data_first_chain,
      s2c1_data_last_chain          => s2c1_data_last_chain,
      s2c1_data_data                => s2c1_data_data,
      s2c1_data_user_control        => s2c1_data_user_control,
      -- Target Write Interface
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

      -- Target Read Interface
      targ_rd_req                   => targ_rd_req,
      targ_rd_core_ready            => targ_rd_core_ready,
      targ_rd_user_ready            => targ_rd_user_ready,
      targ_rd_cs                    => targ_rd_cs,
      targ_rd_start                 => targ_rd_start,
      targ_rd_addr                  => targ_rd_addr,
      targ_rd_first_be              => targ_rd_first_be,
      targ_rd_last_be               => targ_rd_last_be,
      targ_rd_count                 => targ_rd_count,
      targ_rd_en                    => targ_rd_en,
      targ_rd_data                  => targ_rd_data,

      -- Register Interface
      reg_wr_addr                   => reg_wr_addr,
      reg_wr_en                     => reg_wr_en,
      reg_wr_be                     => reg_wr_be,
      reg_wr_data                   => reg_wr_data,
      reg_rd_addr                   => reg_rd_addr,
      reg_rd_be                     => reg_rd_be,
      reg_rd_data                   => reg_rd_data
    );
end architecture;

