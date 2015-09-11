// -------------------------------------------------------------------------
//
//  PROJECT: PCI Express Core
//  COMPANY: Northwest Logic, Inc.
//
// ------------------------- CONFIDENTIAL ----------------------------------
//
//                 Copyright 2010 by Northwest Logic, Inc.
//
//  All rights reserved.  No part of this source code may be reproduced or
//  transmitted in any form or by any means, electronic or mechanical,
//  including photocopying, recording, or any information storage and
//  retrieval system, without permission in writing from Northest Logic, Inc.
//
//  Further, no use of this source code is permitted in any form or means
//  without a valid, written license agreement with Northwest Logic, Inc.
//
//                         Northwest Logic, Inc.
//                  1100 NW Compton Drive, Suite 100
//                      Beaverton, OR 97006, USA
//
//                       Ph.  +1 503 533 5800
//                       Fax. +1 503 533 5900
//                          www.nwlogic.com
//
// -------------------------------------------------------------------------

`timescale 1ps / 1ps



// -----------------------
// -- Module Definition --
// -----------------------

module dma_back_end_pkt (

    rst_n,
    clk,

    tx_buf_av,
    tx_err_drop,
    tx_cfg_req,
    s_axis_tx_tready,
    s_axis_tx_tdata,
    s_axis_tx_tstrb,
    s_axis_tx_tuser,
    s_axis_tx_tlast,
    s_axis_tx_tvalid,
    tx_cfg_gnt,

    m_axis_rx_tdata,
    m_axis_rx_tstrb,
    m_axis_rx_tlast,
    m_axis_rx_tvalid,
    m_axis_rx_tready,
    m_axis_rx_tuser,
    rx_np_ok,
    mgmt_mst_en,
    mgmt_msi_en,
    mgmt_max_payload_size,
    mgmt_max_rd_req_size,
    mgmt_clk_period_in_ns,
    mgmt_version,
    mgmt_pcie_version,
    mgmt_user_version,
    mgmt_cfg_id,
    mgmt_interrupt,
    user_interrupt,

    mgmt_ch_infinite,
    mgmt_cd_infinite,
    mgmt_ch_credits,
    mgmt_cd_credits,

    mgmt_adv_cpl_timeout_disable,
    mgmt_adv_cpl_timeout_value,
    mgmt_cpl_timeout_disable,
    mgmt_cpl_timeout_value,

    err_pkt_poison,
    err_cpl_to_closed_tag,
    err_cpl_timeout,
    err_pkt_header,
    cpl_tag_active,

    // Master DWORD Read/Write Interface
    mst_ready,
    mst_req,
    mst_type,
    mst_data,
    mst_be,
    mst_addr,
    mst_msgcode,
    mst_rd_data,
    mst_status,
    mst_done,

    // DMA Card to System Engine #0 User Interface
    c2s0_cfg_constants,

    c2s0_desc_req,
    c2s0_desc_ready,
    c2s0_desc_ptr,
    c2s0_desc_data,
    c2s0_desc_abort,
    c2s0_desc_abort_ack,
    c2s0_desc_rst_n,

    c2s0_desc_done,
    c2s0_desc_done_channel,
    c2s0_desc_done_status,

    c2s0_cmd_rst_n,
    c2s0_cmd_req,
    c2s0_cmd_ready,
    c2s0_cmd_first_chain,
    c2s0_cmd_last_chain,
    c2s0_cmd_addr,
    c2s0_cmd_bcount,
    c2s0_cmd_user_control,
    c2s0_cmd_abort,
    c2s0_cmd_abort_ack,

    c2s0_data_req,
    c2s0_data_ready,
    c2s0_data_req_remain,
    c2s0_data_req_last_desc,
    c2s0_data_addr,
    c2s0_data_bcount,
    c2s0_data_stop,
    c2s0_data_stop_bcount,

    c2s0_data_en,
    c2s0_data_remain,
    c2s0_data_valid,
    c2s0_data_first_req,
    c2s0_data_last_req,
    c2s0_data_first_desc,
    c2s0_data_last_desc,
    c2s0_data_first_chain,
    c2s0_data_last_chain,
    c2s0_data_sop,
    c2s0_data_eop,
    c2s0_data_data,
    c2s0_data_user_status,

    // DMA Card to System Engine #1 User Interface
    c2s1_cfg_constants,

    c2s1_desc_req,
    c2s1_desc_ready,
    c2s1_desc_ptr,
    c2s1_desc_data,
    c2s1_desc_abort,
    c2s1_desc_abort_ack,
    c2s1_desc_rst_n,

    c2s1_desc_done,
    c2s1_desc_done_channel,
    c2s1_desc_done_status,

    c2s1_cmd_rst_n,
    c2s1_cmd_req,
    c2s1_cmd_ready,
    c2s1_cmd_first_chain,
    c2s1_cmd_last_chain,
    c2s1_cmd_addr,
    c2s1_cmd_bcount,
    c2s1_cmd_user_control,
    c2s1_cmd_abort,
    c2s1_cmd_abort_ack,

    c2s1_data_req,
    c2s1_data_ready,
    c2s1_data_req_remain,
    c2s1_data_req_last_desc,
    c2s1_data_addr,
    c2s1_data_bcount,
    c2s1_data_stop,
    c2s1_data_stop_bcount,

    c2s1_data_en,
    c2s1_data_remain,
    c2s1_data_valid,
    c2s1_data_first_req,
    c2s1_data_last_req,
    c2s1_data_first_desc,
    c2s1_data_last_desc,
    c2s1_data_first_chain,
    c2s1_data_last_chain,
    c2s1_data_sop,
    c2s1_data_eop,
    c2s1_data_data,
    c2s1_data_user_status,
    // DMA System to Card Engine #0 User Interface
    s2c0_cfg_constants,

    s2c0_desc_req,
    s2c0_desc_ready,
    s2c0_desc_ptr,
    s2c0_desc_data,
    s2c0_desc_abort,
    s2c0_desc_abort_ack,
    s2c0_desc_rst_n,

    s2c0_desc_done,
    s2c0_desc_done_channel,
    s2c0_desc_done_status,

    s2c0_cmd_rst_n,
    s2c0_cmd_req,
    s2c0_cmd_ready,
    s2c0_cmd_addr,
    s2c0_cmd_bcount,
    s2c0_cmd_user_control,
    s2c0_cmd_abort,
    s2c0_cmd_abort_ack,
    s2c0_cmd_stop,
    s2c0_cmd_stop_bcount,

    s2c0_data_req,
    s2c0_data_ready,
    s2c0_data_addr,
    s2c0_data_bcount,
    s2c0_data_en,
    s2c0_data_error,
    s2c0_data_remain,
    s2c0_data_valid,
    s2c0_data_first_req,
    s2c0_data_last_req,
    s2c0_data_first_desc,
    s2c0_data_last_desc,
    s2c0_data_first_chain,
    s2c0_data_last_chain,
    s2c0_data_data,
    s2c0_data_user_control,

    // DMA System to Card Engine #1 User Interface
    s2c1_cfg_constants,

    s2c1_desc_req,
    s2c1_desc_ready,
    s2c1_desc_ptr,
    s2c1_desc_data,
    s2c1_desc_abort,
    s2c1_desc_abort_ack,
    s2c1_desc_rst_n,

    s2c1_desc_done,
    s2c1_desc_done_channel,
    s2c1_desc_done_status,

    s2c1_cmd_rst_n,
    s2c1_cmd_req,
    s2c1_cmd_ready,
    s2c1_cmd_addr,
    s2c1_cmd_bcount,
    s2c1_cmd_user_control,
    s2c1_cmd_abort,
    s2c1_cmd_abort_ack,
    s2c1_cmd_stop,
    s2c1_cmd_stop_bcount,

    s2c1_data_req,
    s2c1_data_ready,
    s2c1_data_addr,
    s2c1_data_bcount,
    s2c1_data_en,
    s2c1_data_error,
    s2c1_data_remain,
    s2c1_data_valid,
    s2c1_data_first_req,
    s2c1_data_last_req,
    s2c1_data_first_desc,
    s2c1_data_last_desc,
    s2c1_data_first_chain,
    s2c1_data_last_chain,
    s2c1_data_data,
    s2c1_data_user_control,
    // Target Write Interface
    targ_wr_req,
    targ_wr_core_ready,
    targ_wr_user_ready,
    targ_wr_cs,
    targ_wr_start,
    targ_wr_addr,
    targ_wr_count,
    targ_wr_en,
    targ_wr_data,
    targ_wr_be,

    // Target Read Interface
    targ_rd_req,
    targ_rd_core_ready,
    targ_rd_user_ready,
    targ_rd_cs,
    targ_rd_start,
    targ_rd_addr,
    targ_rd_first_be,
    targ_rd_last_be,
    targ_rd_count,
    targ_rd_en,
    targ_rd_data,

    // Register Interface
    reg_wr_addr,
    reg_wr_en,
    reg_wr_be,
    reg_wr_data,
    reg_rd_addr,
    reg_rd_be,
    reg_rd_data

);



// ----------------
// -- Parameters --
// ----------------

parameter   BE_REG_RD_PIPELINE      = 0;     // Number of clocks to add to the register read pipeline. Valid values 0-4. >= 1 adds a pipe register to the data mux.

// Note: None of the following localparam values are intended to be modified by the user
localparam  CORE_DATA_WIDTH         = 64;    // Width of input and output data
localparam  CORE_BE_WIDTH           = 8;     // Width of input and output K
localparam  CORE_REMAIN_WIDTH       = 3;     // 2^CORE_REMAIN_WIDTH represents the number of bytes in CORE_DATA_WIDTH

localparam  XIL_DATA_WIDTH          = CORE_DATA_WIDTH;
localparam  XIL_STRB_WIDTH          = CORE_BE_WIDTH;

localparam  RQ_TAG_WIDTH            = 3;                        // Number of tag bits implemented by the S2C DMA Engine Reorder Queues
localparam  TAG_WIDTH               = RQ_TAG_WIDTH + 1;         // Number of tags bits implemented by Completion Monitor
localparam  NUM_TAGS                = (1 << RQ_TAG_WIDTH) + 2;  // Number of tags implemented by Completion Monitor; must be 2^RQ_TAG_WIDTH+2

parameter   REG_ADDR_WIDTH          = 13; // Register BAR is 64KBytes
localparam  CARD_ADDR_WIDTH         = 64;   // Maximum DMA Card address width
localparam  BYTE_COUNT_WIDTH        = 13;
localparam  DESC_ADDR_WIDTH         = 64;   // Maximum Descriptor Pointer address width

localparam  DESC_STATUS_WIDTH       = 160;

localparam  DESC_WIDTH              = 256;

// Register byte addresses 0x1FFF-0x0000 are reserved for up to 32 System to Card DMA Register Blocks;
//   Each Register Block is 256 bytes; the first Register Block must be placed at 0x0000; subsequent
//   Register Blocks are placed every 256 bytes; software can determine the number of present
//   Register Blocks by reading the Capabilities register at all of the possible locations
// reg_wr_addr and reg_rd_addr are CORE_DATA_WIDTH addresses rather than byte addresses;
//   define the Register Block offsets in terms of CORE_DATA_WIDTH
localparam  REG_BASE_ADDR_S2C0_0    = 32'h00;
localparam  REG_BASE_ADDR_S2C1_0    = 32'h20;
localparam  REG_BASE_ADDR_S2C2_0    = 32'h40;
localparam  REG_BASE_ADDR_S2C3_0    = 32'h60;

// Register byte addresses 0x3FFF-0x2000 are reserved for up to 32 Card to System DMA Register Blocks;
//   Each Register Block is 256 bytes; the first Register Block must be placed at 0x2000; subsequent
//   Register Blocks are placed every 256 bytes; software can determine the number of present
//   Register Blocks by reading the Capabilities register at all of the possible locations
// reg_wr_addr and reg_rd_addr are CORE_DATA_WIDTH addresses rather than byte addresses;
//   define the Register Block offsets in terms of CORE_DATA_WIDTH
localparam  REG_BASE_ADDR_C2S0_0    = 32'h400;
localparam  REG_BASE_ADDR_C2S1_0    = 32'h420;
localparam  REG_BASE_ADDR_C2S2_0    = 32'h440;
localparam  REG_BASE_ADDR_C2S3_0    = 32'h460;
localparam  REG_BASE_ADDR_C2S4_0    = 32'h480;
localparam  REG_BASE_ADDR_C2S5_0    = 32'h4A0;

// The DMA Common Register Block is at 0x4000 offset into BAR0
localparam  REG_BASE_ADDR_COMMON    = 32'h800;

// User Registers are located at BAR0: Byte Address 0x8000 and above
localparam  REG_BASE_ADDR_USER      = 32'h1000;



// ----------------------
// -- Port Definitions --
// ----------------------

input                               rst_n;
input                               clk;

input   [5:0]                       tx_buf_av;
input                               tx_err_drop;
input                               tx_cfg_req;
input                               s_axis_tx_tready;
output  [XIL_DATA_WIDTH-1:0]        s_axis_tx_tdata;
output  [XIL_STRB_WIDTH-1:0]        s_axis_tx_tstrb;
output  [3:0]                       s_axis_tx_tuser;
output                              s_axis_tx_tlast;
output                              s_axis_tx_tvalid;
output                              tx_cfg_gnt;

input   [XIL_DATA_WIDTH-1:0]        m_axis_rx_tdata;
input   [XIL_STRB_WIDTH-1:0]        m_axis_rx_tstrb;
input                               m_axis_rx_tlast;
input                               m_axis_rx_tvalid;
output                              m_axis_rx_tready;
input   [21:0]                      m_axis_rx_tuser;
output                              rx_np_ok;
input                               mgmt_mst_en;
input                               mgmt_msi_en;
input   [2:0]                       mgmt_max_payload_size;
input   [2:0]                       mgmt_max_rd_req_size;
input   [7:0]                       mgmt_clk_period_in_ns;
output  [31:0]                      mgmt_version;
input   [31:0]                      mgmt_pcie_version;
input   [31:0]                      mgmt_user_version;
input   [15:0]                      mgmt_cfg_id;
output                              mgmt_interrupt;
input                               user_interrupt;

input                               mgmt_ch_infinite;
input                               mgmt_cd_infinite;
input   [7:0]                       mgmt_ch_credits;
input   [11:0]                      mgmt_cd_credits;

output                              mgmt_adv_cpl_timeout_disable;
output  [3:0]                       mgmt_adv_cpl_timeout_value;
input                               mgmt_cpl_timeout_disable;
input   [3:0]                       mgmt_cpl_timeout_value;

output                              err_pkt_poison;
output                              err_cpl_to_closed_tag;
output                              err_cpl_timeout;
output  [127:0]                     err_pkt_header;
output                              cpl_tag_active;

output                              mst_ready;
input                               mst_req;
input   [6:0]                       mst_type;
input   [31:0]                      mst_data;
input   [3:0]                       mst_be;
input   [63:0]                      mst_addr;
input   [7:0]                       mst_msgcode;
output  [31:0]                      mst_rd_data;
output  [2:0]                       mst_status;
output                              mst_done;

input   [63:0]                      c2s0_cfg_constants;

input                               c2s0_desc_req;
output                              c2s0_desc_ready;
input   [31:0]                      c2s0_desc_ptr;
input   [DESC_WIDTH-1:0]            c2s0_desc_data;
input                               c2s0_desc_abort;
output                              c2s0_desc_abort_ack;
input                               c2s0_desc_rst_n;

output                              c2s0_desc_done;
output  [7:0]                       c2s0_desc_done_channel;
output  [DESC_STATUS_WIDTH-1:0]     c2s0_desc_done_status;

output                              c2s0_cmd_rst_n;
output                              c2s0_cmd_req;
input                               c2s0_cmd_ready;
output                              c2s0_cmd_first_chain;
output                              c2s0_cmd_last_chain;
output  [63:0]                      c2s0_cmd_addr;
output  [31:0]                      c2s0_cmd_bcount;
output  [63:0]                      c2s0_cmd_user_control;
output                              c2s0_cmd_abort;
input                               c2s0_cmd_abort_ack;

output                              c2s0_data_req;
input                               c2s0_data_ready;
output  [CORE_REMAIN_WIDTH-1:0]     c2s0_data_req_remain;
output                              c2s0_data_req_last_desc;
output  [63:0]                      c2s0_data_addr;
output  [9:0]                       c2s0_data_bcount;
input                               c2s0_data_stop;
input   [9:0]                       c2s0_data_stop_bcount;

output                              c2s0_data_en;
output  [CORE_REMAIN_WIDTH-1:0]     c2s0_data_remain;
output  [CORE_REMAIN_WIDTH:0]       c2s0_data_valid;
output                              c2s0_data_first_req;
output                              c2s0_data_last_req;
output                              c2s0_data_first_desc;
output                              c2s0_data_last_desc;
output                              c2s0_data_first_chain;
output                              c2s0_data_last_chain;
input                               c2s0_data_sop;
input                               c2s0_data_eop;
input   [CORE_DATA_WIDTH-1:0]       c2s0_data_data;
input   [63:0]                      c2s0_data_user_status;

input   [63:0]                      c2s1_cfg_constants;

input                               c2s1_desc_req;
output                              c2s1_desc_ready;
input   [31:0]                      c2s1_desc_ptr;
input   [DESC_WIDTH-1:0]            c2s1_desc_data;
input                               c2s1_desc_abort;
output                              c2s1_desc_abort_ack;
input                               c2s1_desc_rst_n;

output                              c2s1_desc_done;
output  [7:0]                       c2s1_desc_done_channel;
output  [DESC_STATUS_WIDTH-1:0]     c2s1_desc_done_status;

output                              c2s1_cmd_rst_n;
output                              c2s1_cmd_req;
input                               c2s1_cmd_ready;
output                              c2s1_cmd_first_chain;
output                              c2s1_cmd_last_chain;
output  [63:0]                      c2s1_cmd_addr;
output  [31:0]                      c2s1_cmd_bcount;
output  [63:0]                      c2s1_cmd_user_control;
output                              c2s1_cmd_abort;
input                               c2s1_cmd_abort_ack;

output                              c2s1_data_req;
input                               c2s1_data_ready;
output  [CORE_REMAIN_WIDTH-1:0]     c2s1_data_req_remain;
output                              c2s1_data_req_last_desc;
output  [63:0]                      c2s1_data_addr;
output  [9:0]                       c2s1_data_bcount;
input                               c2s1_data_stop;
input   [9:0]                       c2s1_data_stop_bcount;

output                              c2s1_data_en;
output  [CORE_REMAIN_WIDTH-1:0]     c2s1_data_remain;
output  [CORE_REMAIN_WIDTH:0]       c2s1_data_valid;
output                              c2s1_data_first_req;
output                              c2s1_data_last_req;
output                              c2s1_data_first_desc;
output                              c2s1_data_last_desc;
output                              c2s1_data_first_chain;
output                              c2s1_data_last_chain;
input                               c2s1_data_sop;
input                               c2s1_data_eop;
input   [CORE_DATA_WIDTH-1:0]       c2s1_data_data;
input   [63:0]                      c2s1_data_user_status;
input   [63:0]                      s2c0_cfg_constants;

input                               s2c0_desc_req;
output                              s2c0_desc_ready;
input   [31:0]                      s2c0_desc_ptr;
input   [255:0]                     s2c0_desc_data;
input                               s2c0_desc_abort;
output                              s2c0_desc_abort_ack;
input                               s2c0_desc_rst_n;

output                              s2c0_desc_done;
output  [7:0]                       s2c0_desc_done_channel;
output  [159:0]                     s2c0_desc_done_status;

output                              s2c0_cmd_rst_n;
output                              s2c0_cmd_req;
input                               s2c0_cmd_ready;
output  [63:0]                      s2c0_cmd_addr;
output  [9:0]                       s2c0_cmd_bcount;
output  [63:0]                      s2c0_cmd_user_control;
output                              s2c0_cmd_abort;
input                               s2c0_cmd_abort_ack;
input                               s2c0_cmd_stop;
input   [9:0]                       s2c0_cmd_stop_bcount;

output                              s2c0_data_req;
input                               s2c0_data_ready;
output  [63:0]                      s2c0_data_addr;
output  [9:0]                       s2c0_data_bcount;
output                              s2c0_data_en;
output                              s2c0_data_error;
output  [CORE_REMAIN_WIDTH-1:0]     s2c0_data_remain;
output  [CORE_REMAIN_WIDTH:0]       s2c0_data_valid;
output                              s2c0_data_first_req;
output                              s2c0_data_last_req;
output                              s2c0_data_first_desc;
output                              s2c0_data_last_desc;
output                              s2c0_data_first_chain;
output                              s2c0_data_last_chain;
output  [CORE_DATA_WIDTH-1:0]       s2c0_data_data;
output  [63:0]                      s2c0_data_user_control;

input   [63:0]                      s2c1_cfg_constants;

input                               s2c1_desc_req;
output                              s2c1_desc_ready;
input   [31:0]                      s2c1_desc_ptr;
input   [255:0]                     s2c1_desc_data;
input                               s2c1_desc_abort;
output                              s2c1_desc_abort_ack;
input                               s2c1_desc_rst_n;

output                              s2c1_desc_done;
output  [7:0]                       s2c1_desc_done_channel;
output  [159:0]                     s2c1_desc_done_status;

output                              s2c1_cmd_rst_n;
output                              s2c1_cmd_req;
input                               s2c1_cmd_ready;
output  [63:0]                      s2c1_cmd_addr;
output  [9:0]                       s2c1_cmd_bcount;
output  [63:0]                      s2c1_cmd_user_control;
output                              s2c1_cmd_abort;
input                               s2c1_cmd_abort_ack;
input                               s2c1_cmd_stop;
input   [9:0]                       s2c1_cmd_stop_bcount;

output                              s2c1_data_req;
input                               s2c1_data_ready;
output  [63:0]                      s2c1_data_addr;
output  [9:0]                       s2c1_data_bcount;
output                              s2c1_data_en;
output                              s2c1_data_error;
output  [CORE_REMAIN_WIDTH-1:0]     s2c1_data_remain;
output  [CORE_REMAIN_WIDTH:0]       s2c1_data_valid;
output                              s2c1_data_first_req;
output                              s2c1_data_last_req;
output                              s2c1_data_first_desc;
output                              s2c1_data_last_desc;
output                              s2c1_data_first_chain;
output                              s2c1_data_last_chain;
output  [CORE_DATA_WIDTH-1:0]       s2c1_data_data;
output  [63:0]                      s2c1_data_user_control;
output                              targ_wr_req;
output                              targ_wr_core_ready;
input                               targ_wr_user_ready;
output  [5:0]                       targ_wr_cs;
output                              targ_wr_start;
output  [31:0]                      targ_wr_addr;
output  [12:0]                      targ_wr_count;
output                              targ_wr_en;
output  [CORE_DATA_WIDTH-1:0]       targ_wr_data;
output  [CORE_BE_WIDTH-1:0]         targ_wr_be;

output                              targ_rd_req;
output                              targ_rd_core_ready;
input                               targ_rd_user_ready;
output  [5:0]                       targ_rd_cs;
output                              targ_rd_start;
output  [31:0]                      targ_rd_addr;
output  [CORE_BE_WIDTH-1:0]         targ_rd_first_be;
output  [CORE_BE_WIDTH-1:0]         targ_rd_last_be;
output  [12:0]                      targ_rd_count;
output                              targ_rd_en;
input   [CORE_DATA_WIDTH-1:0]       targ_rd_data;

output  [REG_ADDR_WIDTH-1:0]        reg_wr_addr;
output                              reg_wr_en;
output  [CORE_BE_WIDTH-1:0]         reg_wr_be;
output  [CORE_DATA_WIDTH-1:0]       reg_wr_data;
output  [REG_ADDR_WIDTH-1:0]        reg_rd_addr;
output  [CORE_BE_WIDTH-1:0]         reg_rd_be;
input   [CORE_DATA_WIDTH-1:0]       reg_rd_data;
endmodule
