

// Packet DMA Top Level
// This module puts NWL delivered dma_backend_core and streaming FIFO together
// to build the packet DMA interface.

// -------------------------------------------------------------------------
//
//  PROJECT: Gen PCI Express Back End with Xilinx Hard Core Interface
//  COMPANY: Northwest Logic, Inc.
//
// ------------------------- CONFIDENTIAL ----------------------------------
//
//                 Copyright 2009 by Northwest Logic, Inc.
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

// -------------------------------------------------------------------------
//
// This module is a top level reference design file containing:
//   * DMA Back-End
//   * Streaming FIFO
//
//  Virtex-6 PCIe-10GDMA-DDR3-XAUI-AXI Targeted Reference Design
//  Version: 1.0
//  Reference: UG
// -------------------------------------------------------------------------

`timescale 1ps / 1ps



// -----------------------
// -- Module Definition --
// -----------------------

module packet_dma #(
  parameter   DATA_WIDTH = 64,
  parameter   REM_WIDTH = 3,
  parameter   BE_WIDTH = 8,
  parameter   ADDR_WIDTH = 12 + (4-REM_WIDTH),
  parameter   FIFO_DADDR_WIDTH = 7 + (4-REM_WIDTH),
  parameter   SUPPORT_64BIT_SYS_ADDR = 1'b1,
  parameter   SUPPORT_64BIT_DESC_ADDR = 1'b1,
  parameter   XIL_DATA_WIDTH          = 64,           // RX/TX interface data width
  parameter   XIL_STRB_WIDTH          = 8             // TSTRB width

)(
  input                               user_reset,
  input                               user_clk,
  input                               user_lnk_up,

  input [7:0]                         clk_period_in_ns,

  input                               user_interrupt,

  // Tx
  input                               s_axis_tx_tready,
  output   [XIL_DATA_WIDTH-1:0]       s_axis_tx_tdata,
  output   [XIL_STRB_WIDTH-1:0]       s_axis_tx_tstrb,
  output   [3:0]                      s_axis_tx_tuser,
  output                              s_axis_tx_tlast,
  output                              s_axis_tx_tvalid,

  output                              tx_cfg_gnt,
  input  [5:0]                        tx_buf_av,
  input                               tx_err_drop,
  input                               tx_cfg_req,

  // Rx
  input  [XIL_DATA_WIDTH-1:0]         m_axis_rx_tdata,
  input  [XIL_STRB_WIDTH-1:0]         m_axis_rx_tstrb,
  input                               m_axis_rx_tlast,
  input                               m_axis_rx_tvalid,
  output                              m_axis_rx_tready,
  input  [21:0]                       m_axis_rx_tuser,
  output                              rx_np_ok,

  input  [11:0]                       fc_cpld,
  input  [7:0]                        fc_cplh,
  input  [11:0]                       fc_npd,
  input  [7:0]                        fc_nph,
  input  [11:0]                       fc_pd,
  input  [7:0]                        fc_ph,
  input  [2:0]                        fc_sel,


  output [31:0]                       cfg_di,
  output [3:0]                        cfg_byte_en,
  output [9:0]                        cfg_dwaddr,
  output                              cfg_wr_en,
  output                              cfg_rd_en,

  output                              cfg_err_cor,
  output                              cfg_err_ur,
  output                              cfg_err_ecrc,
  output reg                          cfg_err_cpl_timeout,
  output                              cfg_err_cpl_abort,
  output reg                          cfg_err_cpl_unexpect,
  output reg                          cfg_err_posted,
  output                              cfg_err_locked,
  output [47:0]                       cfg_err_tlp_cpl_header,
  input                               cfg_err_cpl_rdy,

  output reg                          cfg_interrupt,
  input                               cfg_interrupt_rdy,
  output reg                          cfg_interrupt_assert,
  output reg [7:0]                    cfg_interrupt_di,
  input  [7:0]                        cfg_interrupt_do,
  input  [2:0]                        cfg_interrupt_mmenable,
  input                               cfg_interrupt_msienable,
  input                               cfg_interrupt_msixenable,
  input                               cfg_interrupt_msixfm,

  output reg                          cfg_turnoff_ok,
  input                               cfg_to_turnoff,
  output reg                          cfg_trn_pending,
  output                              cfg_pm_wake,

  input  [7:0]                        cfg_bus_number,
  input  [4:0]                        cfg_device_number,
  input  [2:0]                        cfg_function_number,
  input  [15:0]                       cfg_status,
  input  [15:0]                       cfg_command,
  input  [15:0]                       cfg_dstatus,
  input  [15:0]                       cfg_dcommand,
  input  [15:0]                       cfg_lstatus,
  input  [15:0]                       cfg_lcommand,
  input  [15:0]                       cfg_dcommand2,
  input  [2:0]                        cfg_pcie_link_state,

  //- S2C Engine #0
  output [63:0]                       s2c0_user_control,
  output                              s2c0_sop,
  output                              s2c0_eop,
  output                              s2c0_err,
  output [DATA_WIDTH-1:0]             s2c0_data,
  output [REM_WIDTH-1:0]              s2c0_valid,
  output                              s2c0_src_rdy,
  input                               s2c0_dst_rdy,
  output                              s2c0_abort,
  input                               s2c0_abort_ack,
  output                              s2c0_user_rst_n,
  output                              s2c0_apkt_req,
  input                               s2c0_apkt_ready,
  output [63:0]                       s2c0_apkt_addr,
  output [9:0]                        s2c0_apkt_bcount,
  //- S2C Engine #1
  output [63:0]                       s2c1_user_control,
  output                              s2c1_sop,
  output                              s2c1_eop,
  output                              s2c1_err,
  output [DATA_WIDTH-1:0]             s2c1_data,
  output [REM_WIDTH-1:0]              s2c1_valid,
  output                              s2c1_src_rdy,
  input                               s2c1_dst_rdy,
  output                              s2c1_abort,
  input                               s2c1_abort_ack,
  output                              s2c1_user_rst_n,
  output                              s2c1_apkt_req,
  input                               s2c1_apkt_ready,
  output [63:0]                       s2c1_apkt_addr,
  output [9:0]                        s2c1_apkt_bcount,
  //- C2S Engine #0
  input   [63:0]                      c2s0_user_status,
  input                               c2s0_sop,
  input                               c2s0_eop,
  input [DATA_WIDTH-1:0]              c2s0_data,
  input [REM_WIDTH-1:0]               c2s0_valid,
  input                               c2s0_src_rdy,
  output                              c2s0_dst_rdy,
  output                              c2s0_abort,
  input                               c2s0_abort_ack,
  output                              c2s0_user_rst_n,
  output                              c2s0_apkt_req,
  input                               c2s0_apkt_ready,
  output [63:0]                       c2s0_apkt_addr,
  output [31:0]                       c2s0_apkt_bcount,
  output                              c2s0_apkt_eop,
  //- C2S Engine #1
  input   [63:0]                      c2s1_user_status,
  input                               c2s1_sop,
  input                               c2s1_eop,
  input [DATA_WIDTH-1:0]              c2s1_data,
  input [REM_WIDTH-1:0]               c2s1_valid,
  input                               c2s1_src_rdy,
  output                              c2s1_dst_rdy,
  output                              c2s1_abort,
  input                               c2s1_abort_ack,
  output                              c2s1_user_rst_n, 
  output                              c2s1_apkt_req,
  input                               c2s1_apkt_ready,
  output [63:0]                       c2s1_apkt_addr,
  output [31:0]                       c2s1_apkt_bcount,
  output                              c2s1_apkt_eop,
  // Target interface
  output                              targ_wr_req,
  output                              targ_wr_core_ready,
  input                               targ_wr_user_ready,
  output [5:0]                        targ_wr_cs,
  output                              targ_wr_start,
  output [31:0]                       targ_wr_addr,
  output [12:0]                       targ_wr_count,
  output                              targ_wr_en,
  output [DATA_WIDTH-1:0]             targ_wr_data,
  output [BE_WIDTH-1:0]               targ_wr_be,

  output                              targ_rd_req,
  output                              targ_rd_core_ready,
  input                               targ_rd_user_ready,
  output [5:0]                        targ_rd_cs,
  output                              targ_rd_start,
  output [31:0]                       targ_rd_addr,
  output [12:0]                       targ_rd_count,
  output                              targ_rd_en,
  input  [DATA_WIDTH-1:0]             targ_rd_data,
  output [BE_WIDTH-1:0]               targ_rd_first_be,  
  output [BE_WIDTH-1:0]               targ_rd_last_be,  

  // Register interface
  output [ADDR_WIDTH-1:0]             reg_wr_addr,
  output                              reg_wr_en,
  output [BE_WIDTH-1:0]               reg_wr_be,
  output [DATA_WIDTH-1:0]             reg_wr_data,
  output [ADDR_WIDTH-1:0]             reg_rd_addr,
  output [BE_WIDTH-1:0]               reg_rd_be,
  input  [DATA_WIDTH-1:0]             reg_rd_data
);


`ifdef PACKET_DMA_BYTE_SUPPORT
  wire en_packet_dma_byte_support = 1'b1;
`else
  wire en_packet_dma_byte_support = 1'b0;
`endif

// ----------------
// -- Parameters --
// ----------------

// NUM_LANES indicates the number of PCI Express lanes supported by the core
localparam  NUM_LANES               = 4;
localparam  CORE_DATA_WIDTH         = 64;
localparam  CORE_BE_WIDTH           = 8;
localparam  CORE_REMAIN_WIDTH       = 3;

localparam  REG_ADDR_WIDTH          = 12 + (4 - CORE_REMAIN_WIDTH); // Register address width

localparam  DESC_STATUS_WIDTH       = 160;
localparam  DESC_WIDTH              = 256;

// Sets the size of SRAM DMA Destination Memory; Size in bytes = (2^DMA_DEST_ADDR_WIDTH+4);
//   16 == 1 MByte and allows for doing larger DMA operations for behavioral testing;
//   13 == 128 KBytes is a reasonable size for a design that is targeted to hardware; DMAs
//   which exceed the amount of implemented memory will alias
`ifdef SIMULATION
localparam DMA_DEST_ADDR_WIDTH      = 16; // 1 MByte
`else
localparam DMA_DEST_ADDR_WIDTH      = 13; // 128 KBytes
`endif

// Interrupt State Machine States
localparam  IS_DEASSERTED           = 2'b00;
localparam  IS_ASSERT               = 2'b01;
localparam  IS_ASSERTED             = 2'b10;
localparam  IS_DEASSERT             = 2'b11;

// -------------------
// -- Local Signals --
// -------------------

wire    [63:0]                      c2s0_cfg_constants;

wire                                c2s0_desc_req;
wire                                c2s0_desc_ready;
wire    [31:0]                      c2s0_desc_ptr;
wire    [DESC_WIDTH-1:0]            c2s0_desc_data;
wire                                c2s0_desc_abort;
wire                                c2s0_desc_abort_ack;
wire                                c2s0_desc_rst_n;

wire                                c2s0_desc_done;
wire    [7:0]                       c2s0_desc_done_channel;
wire    [DESC_STATUS_WIDTH-1:0]     c2s0_desc_done_status;

wire                                c2s0_cmd_rst_n;                  
wire                                c2s0_cmd_req;
wire                                c2s0_cmd_ready;
wire                                c2s0_cmd_first_chain;
wire                                c2s0_cmd_last_chain;
wire    [31:0]                      c2s0_cmd_bcount;
wire    [63:0]                      c2s0_cmd_addr;
wire    [63:0]                      c2s0_cmd_user_control;
wire                                c2s0_cmd_abort;
wire                                c2s0_cmd_abort_ack;

wire                                c2s0_data_req;
wire                                c2s0_data_ready;
wire    [CORE_REMAIN_WIDTH-1:0]     c2s0_data_req_remain;
wire                                c2s0_data_req_last_desc;
wire    [63:0]                      c2s0_data_addr;
wire    [9:0]                       c2s0_data_bcount;
wire                                c2s0_data_stop;
wire    [9:0]                       c2s0_data_stop_bcount;

wire                                c2s0_data_en;
wire    [CORE_REMAIN_WIDTH-1:0]     c2s0_data_remain;
wire    [CORE_REMAIN_WIDTH:0]       c2s0_data_valid;
wire                                c2s0_data_first_req;
wire                                c2s0_data_last_req;
wire                                c2s0_data_first_desc;
wire                                c2s0_data_last_desc;
wire                                c2s0_data_first_chain;
wire                                c2s0_data_last_chain;
wire                                c2s0_data_sop;
wire                                c2s0_data_eop;
wire    [CORE_DATA_WIDTH-1:0]       c2s0_data_data;
wire    [63:0]                      c2s0_data_user_status;

wire    [63:0]                      c2s1_cfg_constants;

wire                                c2s1_desc_req;
wire                                c2s1_desc_ready;
wire    [31:0]                      c2s1_desc_ptr;
wire    [DESC_WIDTH-1:0]            c2s1_desc_data;
wire                                c2s1_desc_abort;
wire                                c2s1_desc_abort_ack;
wire                                c2s1_desc_rst_n;

wire                                c2s1_desc_done;
wire    [7:0]                       c2s1_desc_done_channel;
wire    [DESC_STATUS_WIDTH-1:0]     c2s1_desc_done_status;

wire                                c2s1_cmd_rst_n;                  
wire                                c2s1_cmd_req;
wire                                c2s1_cmd_ready;
wire                                c2s1_cmd_first_chain;
wire                                c2s1_cmd_last_chain;
wire    [31:0]                      c2s1_cmd_bcount;
wire    [63:0]                      c2s1_cmd_addr;
wire    [63:0]                      c2s1_cmd_user_control;
wire                                c2s1_cmd_abort;
wire                                c2s1_cmd_abort_ack;

wire                                c2s1_data_req;
wire                                c2s1_data_ready;
wire    [CORE_REMAIN_WIDTH-1:0]     c2s1_data_req_remain;
wire                                c2s1_data_req_last_desc;
wire    [63:0]                      c2s1_data_addr;
wire    [9:0]                       c2s1_data_bcount;
wire                                c2s1_data_stop;
wire    [9:0]                       c2s1_data_stop_bcount;

wire                                c2s1_data_en;
wire    [CORE_REMAIN_WIDTH-1:0]     c2s1_data_remain;
wire    [CORE_REMAIN_WIDTH:0]       c2s1_data_valid;
wire                                c2s1_data_first_req;
wire                                c2s1_data_last_req;
wire                                c2s1_data_first_desc;
wire                                c2s1_data_last_desc;
wire                                c2s1_data_first_chain;
wire                                c2s1_data_last_chain;
wire                                c2s1_data_sop;
wire                                c2s1_data_eop;
wire    [CORE_DATA_WIDTH-1:0]       c2s1_data_data;
wire    [63:0]                      c2s1_data_user_status;
wire    [63:0]                      s2c0_cfg_constants;

wire                                s2c0_desc_req;
wire                                s2c0_desc_ready;
wire    [31:0]                      s2c0_desc_ptr;
wire    [255:0]                     s2c0_desc_data;
wire                                s2c0_desc_abort;
wire                                s2c0_desc_abort_ack;
wire                                s2c0_desc_rst_n;

wire                                s2c0_desc_done;
wire    [7:0]                       s2c0_desc_done_channel;
wire    [159:0]                     s2c0_desc_done_status;

wire                                s2c0_cmd_rst_n;                  
wire                                s2c0_cmd_req;
wire                                s2c0_cmd_ready;
wire    [9:0]                       s2c0_cmd_bcount;
wire    [63:0]                      s2c0_cmd_addr;
wire    [63:0]                      s2c0_cmd_user_control;
wire                                s2c0_cmd_abort;
wire                                s2c0_cmd_abort_ack;
wire                                s2c0_cmd_stop;
wire    [9:0]                       s2c0_cmd_stop_bcount;

wire                                s2c0_data_req;
wire                                s2c0_data_ready;
wire    [63:0]                      s2c0_data_addr;
wire    [9:0]                       s2c0_data_bcount;

wire                                s2c0_data_en;
wire                                s2c0_data_error;
wire    [CORE_REMAIN_WIDTH-1:0]     s2c0_data_remain;
wire    [CORE_REMAIN_WIDTH:0]       s2c0_data_valid;
wire                                s2c0_data_first_req;
wire                                s2c0_data_last_req;
wire                                s2c0_data_first_desc;
wire                                s2c0_data_last_desc;
wire                                s2c0_data_first_chain;
wire                                s2c0_data_last_chain;
wire    [CORE_DATA_WIDTH-1:0]       s2c0_data_data;
wire    [63:0]                      s2c0_data_user_control;

wire    [63:0]                      s2c1_cfg_constants;

wire                                s2c1_desc_req;
wire                                s2c1_desc_ready;
wire    [31:0]                      s2c1_desc_ptr;
wire    [255:0]                     s2c1_desc_data;
wire                                s2c1_desc_abort;
wire                                s2c1_desc_abort_ack;
wire                                s2c1_desc_rst_n;

wire                                s2c1_desc_done;
wire    [7:0]                       s2c1_desc_done_channel;
wire    [159:0]                     s2c1_desc_done_status;

wire                                s2c1_cmd_rst_n;                  
wire                                s2c1_cmd_req;
wire                                s2c1_cmd_ready;
wire    [9:0]                       s2c1_cmd_bcount;
wire    [63:0]                      s2c1_cmd_addr;
wire    [63:0]                      s2c1_cmd_user_control;
wire                                s2c1_cmd_abort;
wire                                s2c1_cmd_abort_ack;
wire                                s2c1_cmd_stop;
wire    [9:0]                       s2c1_cmd_stop_bcount;

wire                                s2c1_data_req;
wire                                s2c1_data_ready;
wire    [63:0]                      s2c1_data_addr;
wire    [9:0]                       s2c1_data_bcount;

wire                                s2c1_data_en;
wire                                s2c1_data_error;
wire    [CORE_REMAIN_WIDTH-1:0]     s2c1_data_remain;
wire    [CORE_REMAIN_WIDTH:0]       s2c1_data_valid;
wire                                s2c1_data_first_req;
wire                                s2c1_data_last_req;
wire                                s2c1_data_first_desc;
wire                                s2c1_data_last_desc;
wire                                s2c1_data_first_chain;
wire                                s2c1_data_last_chain;
wire    [CORE_DATA_WIDTH-1:0]       s2c1_data_data;
wire    [63:0]                      s2c1_data_user_control;

wire    [31:0]                      mgmt_user_version;
wire    [31:0]                      mgmt_pcie_version;
wire    [31:0]                      mgmt_be_version;

// Configuration Interrupts
reg                                 r0_mgmt_interrupt;
reg                                 r1_mgmt_interrupt;
reg                                 r2_mgmt_interrupt;

reg                                 leg_assert;
reg                                 msi_assert;

reg     [1:0]                       istate;

wire                                to_is_assert;
wire                                from_is_assert;

wire                                to_is_deassert;
wire                                from_is_deassert;


reg                                 mgmt_mst_en;
reg                                 mgmt_msi_en;
reg     [2:0]                       mgmt_max_payload_size;
reg     [2:0]                       mgmt_max_rd_req_size;
wire    [7:0]                       mgmt_clk_period_in_ns;
reg     [15:0]                      mgmt_cfg_id;


reg                                 d_mgmt_interrupt;
reg                                 mgmt_interrupt;
wire                                ref_mgmt_interrupt;
wire                                be_mgmt_interrupt;


wire                                mgmt_ch_infinite;
wire                                mgmt_cd_infinite;
wire    [7:0]                       mgmt_ch_credits;
wire    [11:0]                      mgmt_cd_credits;

wire                                mgmt_adv_cpl_timeout_disable;
wire    [3:0]                       mgmt_adv_cpl_timeout_value;
reg                                 mgmt_cpl_timeout_disable;
reg     [3:0]                       mgmt_cpl_timeout_value;

wire                                err_pkt_poison;
wire                                err_cpl_to_closed_tag;
wire                                err_cpl_timeout;
wire    [127:0]                     err_pkt_header;
wire                                cpl_tag_active;

reg                                 d_user_rst_n;
reg                                 user_rst_n;

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// from NWL DMA - xil_pcie_wrapper
// ------------
// Flow Control

// Set to report Receive Buffer Available Space
assign mgmt_ch_infinite = 1'b0;
assign mgmt_cd_infinite = 1'b0;

assign mgmt_ch_credits  = fc_cplh;
assign mgmt_cd_credits  = fc_cpld;



// ------------------------
// Configuration Read/Write

// Ports not used
assign cfg_di                       = 32'h0;
assign cfg_byte_en                  = 4'h0;
assign cfg_dwaddr                   = 10'h0;
assign cfg_wr_en                    = 1'b0;
assign cfg_rd_en                    = 1'b0;



// --------------------
// Configuration Errors

always @(posedge user_clk or posedge user_reset)
begin
    if (user_reset == 1'b1)
    begin
        cfg_err_cpl_timeout         <= 1'b0;
        cfg_err_cpl_unexpect        <= 1'b0;
        cfg_err_posted              <= 1'b0;
    end
    else
    begin
        // Assert cfg_err_posted so message response rather than completion response is used
        cfg_err_cpl_timeout         <=                          err_cpl_timeout;
        cfg_err_cpl_unexpect        <=  err_cpl_to_closed_tag;
        cfg_err_posted              <= (err_cpl_to_closed_tag | err_cpl_timeout);
    end
end

assign cfg_err_cor                  = 1'b0;
assign cfg_err_ur                   = 1'b0;
assign cfg_err_ecrc                 = 1'b0;
assign cfg_err_cpl_abort            = 1'b0;
assign cfg_err_locked               = 1'b0;

// Header for completion error response (unused)
//   If used, the following info should be put here from
//   taken from the error non-posted TLP
//   [47:41] Lower Address
//   [40:29] Byte Count
//   [28:26] TC
//   [25:24] Attr
//   [23:8] Requester ID
//   [7:0] Tag
assign cfg_err_tlp_cpl_header       = 48'h0;



// ------------------------
// Configuration Interrupts

always @(posedge user_clk or posedge user_reset)
begin
    if (user_reset == 1'b1)
    begin
        r0_mgmt_interrupt <= 1'b0;
        r1_mgmt_interrupt <= 1'b0;
        r2_mgmt_interrupt <= 1'b0;

        leg_assert        <= 1'b0;
        msi_assert        <= 1'b0;
    end
    else
    begin
        r0_mgmt_interrupt <=    mgmt_interrupt;
        r1_mgmt_interrupt <= r0_mgmt_interrupt;
        r2_mgmt_interrupt <= r1_mgmt_interrupt;

        leg_assert        <= r1_mgmt_interrupt                      & ~cfg_interrupt_msienable; // Legacy mode
        msi_assert        <= r1_mgmt_interrupt & ~r2_mgmt_interrupt &  cfg_interrupt_msienable; // MSI mode
    end
end

// Keep track of current interrupt status; don't assert
//   new interrupt until previous interrupt has been accepted
always @(posedge user_clk or posedge user_reset)
begin
    if (user_reset == 1'b1)
    begin
        istate <= IS_DEASSERTED;
    end
    else
    begin
        case (istate)

            IS_DEASSERTED   :   if (leg_assert | msi_assert)
                                    istate <= IS_ASSERT;

            IS_ASSERT       :   if (cfg_interrupt_rdy)
                                    istate <= cfg_interrupt_msienable ? IS_DEASSERTED : IS_ASSERTED;

            IS_ASSERTED     :   if (~leg_assert)
                                    istate <= IS_DEASSERT;

            IS_DEASSERT     :   if (cfg_interrupt_rdy)
                                    istate <= IS_DEASSERTED;

        endcase
    end
end

assign to_is_assert     = (istate == IS_DEASSERTED) & (leg_assert | msi_assert);
assign from_is_assert   = (istate == IS_ASSERT    ) & cfg_interrupt_rdy;

assign to_is_deassert   = (istate == IS_ASSERTED  ) & (~leg_assert);
assign from_is_deassert = (istate == IS_DEASSERT  ) & cfg_interrupt_rdy;

always @(posedge user_clk or posedge user_reset)
begin
    if (user_reset == 1'b1)
    begin
        cfg_interrupt_assert <= 1'b0;
        cfg_interrupt        <= 1'b0;
        cfg_interrupt_di     <= 8'h00;
    end
    else
    begin
        if (to_is_assert)
            cfg_interrupt_assert <= 1'b1;
        else if (from_is_assert)
            cfg_interrupt_assert <= 1'b0;

        if (to_is_assert | to_is_deassert)
            cfg_interrupt <= 1'b1;
        else if (from_is_assert | from_is_deassert)
            cfg_interrupt <= 1'b0;

        // Only using 1 MSI message; always using INTA in legacy mode
        cfg_interrupt_di <= cfg_interrupt_msienable ? cfg_interrupt_do : 8'h00;
    end
end



// --------------------
// Configuration Status

always @(posedge user_clk or posedge user_reset)
begin
    if (user_reset == 1'b1)
    begin
        cfg_turnoff_ok              <= 1'b0;
        cfg_trn_pending             <= 1'b0;

        mgmt_mst_en                 <= 1'b0;
        mgmt_msi_en                 <= 1'b0;
        mgmt_max_payload_size       <= 3'b000;
        mgmt_max_rd_req_size        <= 3'b000;
        mgmt_cfg_id                 <= 16'h0;

        mgmt_cpl_timeout_disable    <= 1'b0;
        mgmt_cpl_timeout_value      <= 4'h0;
    end
    else
    begin
        if (cfg_to_turnoff & ~cfg_trn_pending) // Turn off request and no completions pending
            cfg_turnoff_ok <= 1'b1;
        else
            cfg_turnoff_ok <= 1'b0;

        cfg_trn_pending             <= cpl_tag_active;

        mgmt_mst_en                 <= cfg_command[2];
        mgmt_msi_en                 <= cfg_interrupt_msienable; 
        mgmt_max_payload_size       <= cfg_dcommand[ 7: 5];
        mgmt_max_rd_req_size        <= cfg_dcommand[14:12];
        mgmt_cfg_id                 <= {cfg_bus_number, cfg_device_number, cfg_function_number};

        mgmt_cpl_timeout_disable    <= cfg_dcommand2[4];
        mgmt_cpl_timeout_value      <= cfg_dcommand2[3:0];
    end
end

assign mgmt_clk_period_in_ns        = clk_period_in_ns; // 250 MHz

assign cfg_pm_wake                  = 1'b0;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// ---------------------
// Core Revision History

// Append the revision level of this top-level file to the main core revision information

// Version Information
//   Increment when changing top-level core file[31:24]; only revision info added in this file
//   Increment on Major Release/Feature Add[23:16]; passed in from lower level core
//   Increment on Major Bug Fix[15:8]; passed in from lower level core
//   Increment on Minor Bug Fix[7:0]; passed in from lower level core

//assign mgmt_be_version = {8'h01, int_mgmt_be_version};

// -------------------------
// PCI Express Core Instance

//   Upper 16 bits: Xilinx Vendor ID (0x10EE)
//   Lower 16 bits: Xilinx core version
assign mgmt_pcie_version = 32'h10EE_0201;

// ---------------------
// Core Revision History

// Version Information
//   Unused[31:24]
//   Increment on Major Release/Feature Add[23:16]
//   Increment on Major Bug Fix[15:8]
//   Increment on Minor Bug Fix[7:0]

assign mgmt_user_version = 32'h00_01_01_00;

// Version 00.01.00.01 (03/05/09)
//   Introduced mgmt_user_version to track the version of the reference design
//
// Version 00.01.01.00 (05/11/09)
//   Added support for Packet DMA
//

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// from NWL DMA - sdram_dma_ref_design_pkt_xil_axi

// ---------------
// Clock and Reset

// Hold core in reset whenever hard core reset is asserted or link is down
// Also make sure fc_sel is 0, else the credit values passed into the DMA
// will be incorrect. the DMA requires fc_sel should be 3'b0 for atleast 
// 4 clock cyles after reset is 1'b1. In this design the fc_sel is 3'b101 
// initially and 3'b000 after that
assign reset = user_reset | ~user_lnk_up | (|fc_sel);

// Synchronize reset to user_clk
always @(posedge user_clk or posedge reset)
begin
    if (reset == 1)
    begin
        d_user_rst_n  <= 1'b0;
        user_rst_n    <= 1'b0;
    end
    else
    begin
        d_user_rst_n  <= 1'b1;
        user_rst_n    <= d_user_rst_n;
    end
end

assign ref_mgmt_interrupt = 1'b0;

always @(posedge user_clk or negedge user_rst_n)
begin
    if (user_rst_n == 1'b0)
    begin
        d_mgmt_interrupt <= 1'b0;
        mgmt_interrupt   <= 1'b0;
    end
    else
    begin
        d_mgmt_interrupt <= be_mgmt_interrupt | ref_mgmt_interrupt;
        mgmt_interrupt   <= d_mgmt_interrupt;
    end
end
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// -------------------------
// Instantiate DMA Back End


dma_back_end_pkt dma_back_end_pkt (

    .rst_n                          (user_rst_n                 ),
    .clk                            (user_clk                   ),

    .tx_buf_av                      (tx_buf_av                  ),
    .tx_err_drop                    (tx_err_drop                ),
    .tx_cfg_req                     (tx_cfg_req                 ),
    .s_axis_tx_tready               (s_axis_tx_tready           ),
    .s_axis_tx_tdata                (s_axis_tx_tdata            ),
    .s_axis_tx_tstrb                (s_axis_tx_tstrb            ),
    .s_axis_tx_tuser                (s_axis_tx_tuser            ),
    .s_axis_tx_tlast                (s_axis_tx_tlast            ),
    .s_axis_tx_tvalid               (s_axis_tx_tvalid           ),
    .tx_cfg_gnt                     (tx_cfg_gnt                 ),

    .m_axis_rx_tdata                (m_axis_rx_tdata            ),
    .m_axis_rx_tstrb                (m_axis_rx_tstrb            ),
    .m_axis_rx_tlast                (m_axis_rx_tlast            ),
    .m_axis_rx_tvalid               (m_axis_rx_tvalid           ),
    .m_axis_rx_tready               (m_axis_rx_tready           ),
    .m_axis_rx_tuser                (m_axis_rx_tuser            ),
    .rx_np_ok                       (rx_np_ok                   ),

    .mgmt_mst_en                    (mgmt_mst_en                ),
    .mgmt_msi_en                    (mgmt_msi_en                ),
    .mgmt_max_payload_size          (mgmt_max_payload_size      ),
    .mgmt_max_rd_req_size           (mgmt_max_rd_req_size       ),
    .mgmt_clk_period_in_ns          (mgmt_clk_period_in_ns      ),
    .mgmt_version                   (mgmt_be_version            ),
    .mgmt_pcie_version              (mgmt_pcie_version          ),
    .mgmt_user_version              (mgmt_user_version          ),
    .mgmt_cfg_id                    (mgmt_cfg_id                ),
    .mgmt_interrupt                 (be_mgmt_interrupt          ),
    .user_interrupt                 (user_interrupt             ),

    .mgmt_ch_infinite               (mgmt_ch_infinite           ),
    .mgmt_cd_infinite               (mgmt_cd_infinite           ),
    .mgmt_ch_credits                (mgmt_ch_credits            ),
    .mgmt_cd_credits                (mgmt_cd_credits            ),

    .mgmt_adv_cpl_timeout_disable   (mgmt_adv_cpl_timeout_disable),
    .mgmt_adv_cpl_timeout_value     (mgmt_adv_cpl_timeout_value ),
    .mgmt_cpl_timeout_disable       (mgmt_cpl_timeout_disable   ),
    .mgmt_cpl_timeout_value         (mgmt_cpl_timeout_value     ),

    .err_pkt_poison                 (err_pkt_poison             ),
    .err_cpl_to_closed_tag          (err_cpl_to_closed_tag      ),
    .err_cpl_timeout                (err_cpl_timeout            ),
    .err_pkt_header                 (err_pkt_header             ),
    .cpl_tag_active                 (cpl_tag_active             ),

    .mst_ready                      (                           ),
    .mst_rd_data                    (                           ),
    .mst_status                     (                           ),
    .mst_done                       (                           ),
    .mst_req                        (1'b0                       ),
    .mst_type                       (7'h0                       ),
    .mst_data                       (32'h0                      ),
    .mst_be                         (4'h0                       ),
    .mst_addr                       (64'h0                      ),
    .mst_msgcode                    (8'h00                      ),

    .targ_wr_req                    (targ_wr_req                ),
    .targ_wr_core_ready             (targ_wr_core_ready         ),
    .targ_wr_user_ready             (targ_wr_user_ready         ),
    .targ_wr_cs                     (targ_wr_cs                 ),
    .targ_wr_start                  (targ_wr_start              ),
    .targ_wr_addr                   (targ_wr_addr               ),
    .targ_wr_count                  (targ_wr_count              ),
    .targ_wr_en                     (targ_wr_en                 ),
    .targ_wr_data                   (targ_wr_data               ),
    .targ_wr_be                     (targ_wr_be                 ),

    .targ_rd_req                    (targ_rd_req                ),
    .targ_rd_core_ready             (targ_rd_core_ready         ),
    .targ_rd_user_ready             (targ_rd_user_ready         ),
    .targ_rd_cs                     (targ_rd_cs                 ),
    .targ_rd_start                  (targ_rd_start              ),
    .targ_rd_addr                   (targ_rd_addr               ),
    .targ_rd_first_be               (targ_rd_first_be           ),
    .targ_rd_last_be                (targ_rd_last_be            ),
    .targ_rd_count                  (targ_rd_count              ),
    .targ_rd_en                     (targ_rd_en                 ),
    .targ_rd_data                   (targ_rd_data               ),

    .reg_wr_addr                    (reg_wr_addr                ),
    .reg_wr_en                      (reg_wr_en                  ),
    .reg_wr_be                      (reg_wr_be                  ),
    .reg_wr_data                    (reg_wr_data                ),
    .reg_rd_addr                    (reg_rd_addr                ),
    .reg_rd_be                      (reg_rd_be                  ),
    .reg_rd_data                    (reg_rd_data                )
    ,

    .c2s0_cfg_constants             (c2s0_cfg_constants         ),

    .c2s0_desc_req                  (c2s0_desc_req              ),
    .c2s0_desc_ready                (c2s0_desc_ready            ),
    .c2s0_desc_ptr                  (c2s0_desc_ptr              ),
    .c2s0_desc_data                 (c2s0_desc_data             ),
    .c2s0_desc_abort                (c2s0_desc_abort            ),
    .c2s0_desc_abort_ack            (c2s0_desc_abort_ack        ),
    .c2s0_desc_rst_n                (c2s0_desc_rst_n            ),
    .c2s0_desc_done                 (c2s0_desc_done             ),
    .c2s0_desc_done_channel         (c2s0_desc_done_channel     ),
    .c2s0_desc_done_status          (c2s0_desc_done_status      ),

    .c2s0_cmd_rst_n                 (c2s0_cmd_rst_n             ),
    .c2s0_cmd_req                   (c2s0_cmd_req               ),
    .c2s0_cmd_ready                 (c2s0_cmd_ready             ),
    .c2s0_cmd_first_chain           (c2s0_cmd_first_chain       ),
    .c2s0_cmd_last_chain            (c2s0_cmd_last_chain        ),
    .c2s0_cmd_addr                  (c2s0_cmd_addr              ),
    .c2s0_cmd_bcount                (c2s0_cmd_bcount            ),
    .c2s0_cmd_user_control          (c2s0_cmd_user_control      ),
    .c2s0_cmd_abort                 (c2s0_cmd_abort             ),
    .c2s0_cmd_abort_ack             (c2s0_cmd_abort_ack         ),

    .c2s0_data_req                  (c2s0_data_req              ),
    .c2s0_data_ready                (c2s0_data_ready            ),
    .c2s0_data_req_remain           (c2s0_data_req_remain       ),
    .c2s0_data_req_last_desc        (c2s0_data_req_last_desc    ),
    .c2s0_data_addr                 (c2s0_data_addr             ),
    .c2s0_data_bcount               (c2s0_data_bcount           ),
    .c2s0_data_stop                 (c2s0_data_stop             ),
    .c2s0_data_stop_bcount          (c2s0_data_stop_bcount      ),

    .c2s0_data_en                   (c2s0_data_en               ),
    .c2s0_data_remain               (c2s0_data_remain           ),
    .c2s0_data_valid                (c2s0_data_valid            ),
    .c2s0_data_first_req            (c2s0_data_first_req        ),
    .c2s0_data_last_req             (c2s0_data_last_req         ),
    .c2s0_data_first_desc           (c2s0_data_first_desc       ),
    .c2s0_data_last_desc            (c2s0_data_last_desc        ),
    .c2s0_data_first_chain          (c2s0_data_first_chain      ),
    .c2s0_data_last_chain           (c2s0_data_last_chain       ),
    .c2s0_data_sop                  (c2s0_data_sop              ),
    .c2s0_data_eop                  (c2s0_data_eop              ),
    .c2s0_data_data                 (c2s0_data_data             ),
    .c2s0_data_user_status          (c2s0_data_user_status      )
    ,

    .c2s1_cfg_constants             (c2s1_cfg_constants         ),

    .c2s1_desc_req                  (c2s1_desc_req              ),
    .c2s1_desc_ready                (c2s1_desc_ready            ),
    .c2s1_desc_ptr                  (c2s1_desc_ptr              ),
    .c2s1_desc_data                 (c2s1_desc_data             ),
    .c2s1_desc_abort                (c2s1_desc_abort            ),
    .c2s1_desc_abort_ack            (c2s1_desc_abort_ack        ),
    .c2s1_desc_rst_n                (c2s1_desc_rst_n            ),
    .c2s1_desc_done                 (c2s1_desc_done             ),
    .c2s1_desc_done_channel         (c2s1_desc_done_channel     ),
    .c2s1_desc_done_status          (c2s1_desc_done_status      ),

    .c2s1_cmd_rst_n                 (c2s1_cmd_rst_n             ),
    .c2s1_cmd_req                   (c2s1_cmd_req               ),
    .c2s1_cmd_ready                 (c2s1_cmd_ready             ),
    .c2s1_cmd_first_chain           (c2s1_cmd_first_chain       ),
    .c2s1_cmd_last_chain            (c2s1_cmd_last_chain        ),
    .c2s1_cmd_addr                  (c2s1_cmd_addr              ),
    .c2s1_cmd_bcount                (c2s1_cmd_bcount            ),
    .c2s1_cmd_user_control          (c2s1_cmd_user_control      ),
    .c2s1_cmd_abort                 (c2s1_cmd_abort             ),
    .c2s1_cmd_abort_ack             (c2s1_cmd_abort_ack         ),

    .c2s1_data_req                  (c2s1_data_req              ),
    .c2s1_data_ready                (c2s1_data_ready            ),
    .c2s1_data_req_remain           (c2s1_data_req_remain       ),
    .c2s1_data_req_last_desc        (c2s1_data_req_last_desc    ),
    .c2s1_data_addr                 (c2s1_data_addr             ),
    .c2s1_data_bcount               (c2s1_data_bcount           ),
    .c2s1_data_stop                 (c2s1_data_stop             ),
    .c2s1_data_stop_bcount          (c2s1_data_stop_bcount      ),

    .c2s1_data_en                   (c2s1_data_en               ),
    .c2s1_data_remain               (c2s1_data_remain           ),
    .c2s1_data_valid                (c2s1_data_valid            ),
    .c2s1_data_first_req            (c2s1_data_first_req        ),
    .c2s1_data_last_req             (c2s1_data_last_req         ),
    .c2s1_data_first_desc           (c2s1_data_first_desc       ),
    .c2s1_data_last_desc            (c2s1_data_last_desc        ),
    .c2s1_data_first_chain          (c2s1_data_first_chain      ),
    .c2s1_data_last_chain           (c2s1_data_last_chain       ),
    .c2s1_data_sop                  (c2s1_data_sop              ),
    .c2s1_data_eop                  (c2s1_data_eop              ),
    .c2s1_data_data                 (c2s1_data_data             ),
    .c2s1_data_user_status          (c2s1_data_user_status      )
    ,

    .s2c0_cfg_constants             (s2c0_cfg_constants         ),

    .s2c0_desc_req                  (s2c0_desc_req              ),
    .s2c0_desc_ready                (s2c0_desc_ready            ),
    .s2c0_desc_ptr                  (s2c0_desc_ptr              ),
    .s2c0_desc_data                 (s2c0_desc_data             ),
    .s2c0_desc_abort                (s2c0_desc_abort            ),
    .s2c0_desc_abort_ack            (s2c0_desc_abort_ack        ),
    .s2c0_desc_rst_n                (s2c0_desc_rst_n            ),
    .s2c0_desc_done                 (s2c0_desc_done             ),
    .s2c0_desc_done_channel         (s2c0_desc_done_channel     ),
    .s2c0_desc_done_status          (s2c0_desc_done_status      ),

    .s2c0_cmd_rst_n                 (s2c0_cmd_rst_n             ),
    .s2c0_cmd_req                   (s2c0_cmd_req               ),
    .s2c0_cmd_ready                 (s2c0_cmd_ready             ),
    .s2c0_cmd_addr                  (s2c0_cmd_addr              ),
    .s2c0_cmd_bcount                (s2c0_cmd_bcount            ),
    .s2c0_cmd_user_control          (s2c0_cmd_user_control      ),
    .s2c0_cmd_abort                 (s2c0_cmd_abort             ),
    .s2c0_cmd_abort_ack             (s2c0_cmd_abort_ack         ),
    .s2c0_cmd_stop                  (s2c0_cmd_stop              ),
    .s2c0_cmd_stop_bcount           (s2c0_cmd_stop_bcount       ),

    .s2c0_data_req                  (s2c0_data_req              ),
    .s2c0_data_ready                (s2c0_data_ready            ),
    .s2c0_data_addr                 (s2c0_data_addr             ),
    .s2c0_data_bcount               (s2c0_data_bcount           ),

    .s2c0_data_en                   (s2c0_data_en               ),
    .s2c0_data_error                (s2c0_data_error            ),
    .s2c0_data_remain               (s2c0_data_remain           ),
    .s2c0_data_valid                (s2c0_data_valid            ),
    .s2c0_data_first_req            (s2c0_data_first_req        ),
    .s2c0_data_last_req             (s2c0_data_last_req         ),
    .s2c0_data_first_desc           (s2c0_data_first_desc       ),
    .s2c0_data_last_desc            (s2c0_data_last_desc        ),
    .s2c0_data_first_chain          (s2c0_data_first_chain      ),
    .s2c0_data_last_chain           (s2c0_data_last_chain       ),
    .s2c0_data_data                 (s2c0_data_data             ),
    .s2c0_data_user_control         (s2c0_data_user_control     )
    ,

    .s2c1_cfg_constants             (s2c1_cfg_constants         ),

    .s2c1_desc_req                  (s2c1_desc_req              ),
    .s2c1_desc_ready                (s2c1_desc_ready            ),
    .s2c1_desc_ptr                  (s2c1_desc_ptr              ),
    .s2c1_desc_data                 (s2c1_desc_data             ),
    .s2c1_desc_abort                (s2c1_desc_abort            ),
    .s2c1_desc_abort_ack            (s2c1_desc_abort_ack        ),
    .s2c1_desc_rst_n                (s2c1_desc_rst_n            ),
    .s2c1_desc_done                 (s2c1_desc_done             ),
    .s2c1_desc_done_channel         (s2c1_desc_done_channel     ),
    .s2c1_desc_done_status          (s2c1_desc_done_status      ),

    .s2c1_cmd_rst_n                 (s2c1_cmd_rst_n             ),
    .s2c1_cmd_req                   (s2c1_cmd_req               ),
    .s2c1_cmd_ready                 (s2c1_cmd_ready             ),
    .s2c1_cmd_addr                  (s2c1_cmd_addr              ),
    .s2c1_cmd_bcount                (s2c1_cmd_bcount            ),
    .s2c1_cmd_user_control          (s2c1_cmd_user_control      ),
    .s2c1_cmd_abort                 (s2c1_cmd_abort             ),
    .s2c1_cmd_abort_ack             (s2c1_cmd_abort_ack         ),
    .s2c1_cmd_stop                  (s2c1_cmd_stop              ),
    .s2c1_cmd_stop_bcount           (s2c1_cmd_stop_bcount       ),

    .s2c1_data_req                  (s2c1_data_req              ),
    .s2c1_data_ready                (s2c1_data_ready            ),
    .s2c1_data_addr                 (s2c1_data_addr             ),
    .s2c1_data_bcount               (s2c1_data_bcount           ),

    .s2c1_data_en                   (s2c1_data_en               ),
    .s2c1_data_error                (s2c1_data_error            ),
    .s2c1_data_remain               (s2c1_data_remain           ),
    .s2c1_data_valid                (s2c1_data_valid            ),
    .s2c1_data_first_req            (s2c1_data_first_req        ),
    .s2c1_data_last_req             (s2c1_data_last_req         ),
    .s2c1_data_first_desc           (s2c1_data_first_desc       ),
    .s2c1_data_last_desc            (s2c1_data_last_desc        ),
    .s2c1_data_first_chain          (s2c1_data_first_chain      ),
    .s2c1_data_last_chain           (s2c1_data_last_chain       ),
    .s2c1_data_data                 (s2c1_data_data             ),
    .s2c1_data_user_control         (s2c1_data_user_control     )
);

// ----------------------------
// Instantiate Reference Design

//-------------------------------
// Card to System ENGINE - 0

assign c2s0_cfg_constants[    0] = 1'b0;                    // Reserved; was use sequence/continue functionality
assign c2s0_cfg_constants[    1] = SUPPORT_64BIT_SYS_ADDR;  // 1 == Support 32/64-bit system addresses; 0 == 32-bit address support only
assign c2s0_cfg_constants[    2] = SUPPORT_64BIT_DESC_ADDR; // 1 == Support 32/64-bit descriptor pointer system addresses; 0 == 32-bit address support only (Block DMA Only)
assign c2s0_cfg_constants[    3] = 1'b0;                    // Reserved; was enable overlapping of commands
assign c2s0_cfg_constants[ 7: 4] = 4'h0;                    // Reserved
assign c2s0_cfg_constants[14: 8] = 7'h0;                    // Address space implemented on the card for this engine == 2^DMA_DEST_ADDR_WIDTH (Streams don't have addresses so set to 0)
assign c2s0_cfg_constants[   15] = 1'b0;                    // Reserved
assign c2s0_cfg_constants[21:16] = 6'h0;                    // Implemented byte count width; 0 selects maximum supported DMA engine value
assign c2s0_cfg_constants[23:22] = 2'h0;                    // Reserved
assign c2s0_cfg_constants[27:24] = 4'h0;                    // Implemented channel width; 0 == only 1 channel
assign c2s0_cfg_constants[31:28] = 4'h0;                    // Reserved
assign c2s0_cfg_constants[38:32] = 7'd64;                   // Implemented user status width; 64 == max value
assign c2s0_cfg_constants[   39] = 1'b0;                    // Reserved
assign c2s0_cfg_constants[46:40] = 7'h0;                    // Implemented user control width; 0 == not used; not supported for C2S Engines
assign c2s0_cfg_constants[   47] = 1'b0;                    // Reserved
assign c2s0_cfg_constants[63:48] = 16'h0;  

// DMA Direct Control Port is unused
assign c2s0_desc_req   = 1'b0;
assign c2s0_desc_ptr   = 32'h0;
assign c2s0_desc_data  = {DESC_WIDTH{1'b0}};
assign c2s0_desc_abort = 1'b0;
assign c2s0_desc_rst_n = 1'b1;

c2s_pkt_streaming_fifo #(

    .FIFO_ADDR_WIDTH        (FIFO_DADDR_WIDTH           )

) c2s0_c2s_pkt_streaming_fifo 
(

    .rst_n                  (c2s0_cmd_rst_n             ),
    .clk                    (user_clk                   ),

    .cmd_req                (c2s0_cmd_req               ),
    .cmd_ready              (c2s0_cmd_ready             ),
    .cmd_first_chain        (c2s0_cmd_first_chain       ),
    .cmd_last_chain         (c2s0_cmd_last_chain        ),
    .cmd_bcount             (c2s0_cmd_bcount            ),
    .cmd_addr               (c2s0_cmd_addr              ),
    .cmd_user_control       (c2s0_cmd_user_control      ),
    .cmd_abort              (c2s0_cmd_abort             ),
    .cmd_abort_ack          (c2s0_cmd_abort_ack         ),

    .data_req               (c2s0_data_req              ),
    .data_ready             (c2s0_data_ready            ),
    .data_req_remain        (c2s0_data_req_remain       ),
    .data_req_last_desc     (c2s0_data_req_last_desc    ),
    .data_addr              (c2s0_data_addr             ),
    .data_bcount            (c2s0_data_bcount           ),
    .data_stop              (c2s0_data_stop             ),
    .data_stop_bcount       (c2s0_data_stop_bcount      ),
    
    .data_en                (c2s0_data_en               ),
    .data_remain            (c2s0_data_remain           ),
    .data_valid             (c2s0_data_valid            ),
    .data_first_req         (c2s0_data_first_req        ),
    .data_last_req          (c2s0_data_last_req         ),
    .data_first_desc        (c2s0_data_first_desc       ),
    .data_last_desc         (c2s0_data_last_desc        ),
    .data_first_chain       (c2s0_data_first_chain      ),
    .data_last_chain        (c2s0_data_last_chain       ),
    .data_sop               (c2s0_data_sop              ),
    .data_eop               (c2s0_data_eop              ),
    .data_data              (c2s0_data_data             ),
    .data_user_status       (c2s0_data_user_status      ),

    .user_status            (c2s0_user_status           ),
    .sop                    (c2s0_sop                   ),
    .eop                    (c2s0_eop                   ),
    .data                   (c2s0_data                  ),
    .valid                  (c2s0_valid                 ),
    .src_rdy                (c2s0_src_rdy               ),
    .dst_rdy                (c2s0_dst_rdy               ),
    .abort                  (c2s0_abort                 ),
    .abort_ack              (c2s0_abort_ack             ),
    .user_rst_n             (c2s0_user_rst_n            ),

    .apkt_req               (c2s0_apkt_req              ),
    .apkt_ready             (c2s0_apkt_ready            ),
    .apkt_addr              (c2s0_apkt_addr             ),
    .apkt_bcount            (c2s0_apkt_bcount           ),
    .apkt_eop               (c2s0_apkt_eop              )
);

//-------------------------------
// Card to System ENGINE - 1

assign c2s1_cfg_constants[    0] = 1'b0;                    // Reserved; was use sequence/continue functionality
assign c2s1_cfg_constants[    1] = SUPPORT_64BIT_SYS_ADDR;  // 1 == Support 32/64-bit system addresses; 0 == 32-bit address support only
assign c2s1_cfg_constants[    2] = SUPPORT_64BIT_DESC_ADDR; // 1 == Support 32/64-bit descriptor pointer system addresses; 0 == 32-bit address support only (Block DMA Only)
assign c2s1_cfg_constants[    3] = 1'b0;                    // Reserved; was enable overlapping of commands
assign c2s1_cfg_constants[ 7: 4] = 4'h0;                    // Reserved
assign c2s1_cfg_constants[14: 8] = 7'h0;                    // Address space implemented on the card for this engine == 2^DMA_DEST_ADDR_WIDTH (Streams don't have addresses so set to 0)
assign c2s1_cfg_constants[   15] = 1'b0;                    // Reserved
assign c2s1_cfg_constants[21:16] = 6'h0;                    // Implemented byte count width; 0 selects maximum supported DMA engine value
assign c2s1_cfg_constants[23:22] = 2'h0;                    // Reserved
assign c2s1_cfg_constants[27:24] = 4'h0;                    // Implemented channel width; 0 == only 1 channel
assign c2s1_cfg_constants[31:28] = 4'h0;                    // Reserved
assign c2s1_cfg_constants[38:32] = 7'd64;                   // Implemented user status width; 64 == max value
assign c2s1_cfg_constants[   39] = 1'b0;                    // Reserved
assign c2s1_cfg_constants[46:40] = 7'h0;                    // Implemented user control width; 0 == not used; not supported for C2S Engines
assign c2s1_cfg_constants[   47] = 1'b0;                    // Reserved
assign c2s1_cfg_constants[63:48] = 16'h0;                   // Reserved

// DMA Direct Control Port is unused
assign c2s1_desc_req   = 1'b0;
assign c2s1_desc_ptr   = 32'h0;
assign c2s1_desc_data  = {DESC_WIDTH{1'b0}};
assign c2s1_desc_abort = 1'b0;
assign c2s1_desc_rst_n = 1'b1;

c2s_pkt_streaming_fifo #(

    .FIFO_ADDR_WIDTH        (FIFO_DADDR_WIDTH           )

) c2s1_c2s_pkt_streaming_fifo
(

    .rst_n                  (c2s1_cmd_rst_n             ),
    .clk                    (user_clk                   ),

    .cmd_req                (c2s1_cmd_req               ),
    .cmd_ready              (c2s1_cmd_ready             ),
    .cmd_first_chain        (c2s1_cmd_first_chain       ),
    .cmd_last_chain         (c2s1_cmd_last_chain        ),
    .cmd_bcount             (c2s1_cmd_bcount            ),
    .cmd_addr               (c2s1_cmd_addr              ),
    .cmd_user_control       (c2s1_cmd_user_control      ),
    .cmd_abort              (c2s1_cmd_abort             ),
    .cmd_abort_ack          (c2s1_cmd_abort_ack         ),

    .data_req               (c2s1_data_req              ),
    .data_ready             (c2s1_data_ready            ),
    .data_req_remain        (c2s1_data_req_remain       ),
    .data_req_last_desc     (c2s1_data_req_last_desc    ),
    .data_addr              (c2s1_data_addr             ),
    .data_bcount            (c2s1_data_bcount           ),
    .data_stop              (c2s1_data_stop             ),
    .data_stop_bcount       (c2s1_data_stop_bcount      ),
    .data_en                (c2s1_data_en               ),
    .data_remain            (c2s1_data_remain           ),
    .data_valid             (c2s1_data_valid            ),
    .data_first_req         (c2s1_data_first_req        ),
    .data_last_req          (c2s1_data_last_req         ),
    .data_first_desc        (c2s1_data_first_desc       ),
    .data_last_desc         (c2s1_data_last_desc        ),
    .data_first_chain       (c2s1_data_first_chain      ),
    .data_last_chain        (c2s1_data_last_chain       ),
    .data_sop               (c2s1_data_sop              ),
    .data_eop               (c2s1_data_eop              ),
    .data_data              (c2s1_data_data             ),
    .data_user_status       (c2s1_data_user_status      ),

    .user_status            (c2s1_user_status           ),
    .sop                    (c2s1_sop                   ),
    .eop                    (c2s1_eop                   ),
    .data                   (c2s1_data                  ),
    .valid                  (c2s1_valid                 ),
    .src_rdy                (c2s1_src_rdy               ),
    .dst_rdy                (c2s1_dst_rdy               ),
    .abort                  (c2s1_abort                 ),
    .abort_ack              (c2s1_abort_ack             ),
    .user_rst_n             (c2s1_user_rst_n            ),

    .apkt_req               (c2s1_apkt_req              ),
    .apkt_ready             (c2s1_apkt_ready            ),
    .apkt_addr              (c2s1_apkt_addr             ),
    .apkt_bcount            (c2s1_apkt_bcount           ),
    .apkt_eop               (c2s1_apkt_eop              )

);

//-------------------------------
// System to Card ENGINE - 0
assign s2c0_cfg_constants[    0] = 1'b0;                    // Reserved; was use sequence/continue functionality
assign s2c0_cfg_constants[    1] = SUPPORT_64BIT_SYS_ADDR;  // 1 == Support 32/64-bit system addresses; 0 == 32-bit address support only
assign s2c0_cfg_constants[    2] = SUPPORT_64BIT_DESC_ADDR; // 1 == Support 32/64-bit descriptor pointer system addresses; 0 == 32-bit address support only (Block DMA Only)
assign s2c0_cfg_constants[    3] = 1'b0;                    // Reserved; was enable overlapping of commands
assign s2c0_cfg_constants[ 7: 4] = 4'h0;                    // Reserved
assign s2c0_cfg_constants[14: 8] = 7'h0;                    // Address space implemented on the card for this engine == 2^DMA_DEST_ADDR_WIDTH (Streams don't have addresses so set to 0)
assign s2c0_cfg_constants[   15] = 1'b0;                    // Reserved
assign s2c0_cfg_constants[21:16] = 6'h0;                    // Implemented byte count width; 0 selects maximum supported DMA engine value
assign s2c0_cfg_constants[23:22] = 2'h0;                    // Reserved
assign s2c0_cfg_constants[27:24] = 4'h0;                    // Implemented channel width; 0 == only 1 channel
assign s2c0_cfg_constants[31:28] = 4'h0;                    // Reserved
assign s2c0_cfg_constants[38:32] = 7'h0;                    // Implemented user status width; 0 == not used
assign s2c0_cfg_constants[   39] = 1'b0;                    // Reserved
assign s2c0_cfg_constants[46:40] = 7'd64;                   // Implemented user control width; 64 == maximum width
assign s2c0_cfg_constants[   47] = 1'b0;                    // Reserved
assign s2c0_cfg_constants[63:48] = 16'h0;                   // Reserved

// DMA Direct Control Port is unused
assign s2c0_desc_req   = 1'b0;
assign s2c0_desc_ptr   = 32'h0;
assign s2c0_desc_data  = {DESC_WIDTH{1'b0}};
assign s2c0_desc_abort = 1'b0;
assign s2c0_desc_rst_n = 1'b1;

s2c_pkt_streaming_fifo #(

    .FIFO_ADDR_WIDTH        (FIFO_DADDR_WIDTH           )

) s2c0_s2c_pkt_streaming_fifo 
(

    .rst_n                  (s2c0_cmd_rst_n             ),
    .clk                    (user_clk                   ),

    .cmd_req                (s2c0_cmd_req               ),
    .cmd_ready              (s2c0_cmd_ready             ),
    .cmd_bcount             (s2c0_cmd_bcount            ),
    .cmd_addr               (s2c0_cmd_addr              ),
    .cmd_user_control       (s2c0_cmd_user_control      ),
    .cmd_abort              (s2c0_cmd_abort             ),
    .cmd_abort_ack          (s2c0_cmd_abort_ack         ),
    .cmd_stop               (s2c0_cmd_stop              ),
    .cmd_stop_bcount        (s2c0_cmd_stop_bcount       ),

    .data_req               (s2c0_data_req              ),
    .data_ready             (s2c0_data_ready            ),
    .data_addr              (s2c0_data_addr             ),
    .data_bcount            (s2c0_data_bcount           ),
    .data_en                (s2c0_data_en               ),
    .data_error             (s2c0_data_error            ),
    .data_remain            (s2c0_data_remain           ),
    .data_valid             (s2c0_data_valid            ),
    .data_first_req         (s2c0_data_first_req        ),
    .data_last_req          (s2c0_data_last_req         ),
    .data_first_desc        (s2c0_data_first_desc       ),
    .data_last_desc         (s2c0_data_last_desc        ),
    .data_first_chain       (s2c0_data_first_chain      ),
    .data_last_chain        (s2c0_data_last_chain       ),
    .data_data              (s2c0_data_data             ),
    .data_user_control      (s2c0_data_user_control     ),
                                                          
    .user_control           (s2c0_user_control          ),
    .sop                    (s2c0_sop                   ),
    .eop                    (s2c0_eop                   ),
    .err                    (s2c0_err                   ),
    .data                   (s2c0_data                  ),
    .valid                  (s2c0_valid                 ),
    .src_rdy                (s2c0_src_rdy               ),
    .dst_rdy                (s2c0_dst_rdy               ),
    .abort                  (s2c0_abort                 ),
    .abort_ack              (s2c0_abort_ack             ),
    .user_rst_n             (s2c0_user_rst_n            ),
                                                          
    .apkt_req               (s2c0_apkt_req              ),
    .apkt_ready             (s2c0_apkt_ready            ),
    .apkt_addr              (s2c0_apkt_addr             ),
    .apkt_bcount            (s2c0_apkt_bcount           )
                                                          
);

//-------------------------------
// System to Card ENGINE - 1

assign s2c1_cfg_constants[    0] = 1'b0;                    // Reserved; was use sequence/continue functionality
assign s2c1_cfg_constants[    1] = SUPPORT_64BIT_SYS_ADDR;  // 1 == Support 32/64-bit system addresses; 0 == 32-bit address support only
assign s2c1_cfg_constants[    2] = SUPPORT_64BIT_DESC_ADDR; // 1 == Support 32/64-bit descriptor pointer system addresses; 0 == 32-bit address support only (Block DMA Only)
assign s2c1_cfg_constants[    3] = 1'b0;                    // Reserved; was enable overlapping of commands
assign s2c1_cfg_constants[ 7: 4] = 4'h0;                    // Reserved
assign s2c1_cfg_constants[14: 8] = 7'h0;                    // Address space implemented on the card for this engine == 2^DMA_DEST_ADDR_WIDTH (Streams don't have addresses so set to 0)
assign s2c1_cfg_constants[   15] = 1'b0;                    // Reserved
assign s2c1_cfg_constants[21:16] = 6'h0;                    // Implemented byte count width; 0 selects maximum supported DMA engine value
assign s2c1_cfg_constants[23:22] = 2'h0;                    // Reserved
assign s2c1_cfg_constants[27:24] = 4'h0;                    // Implemented channel width; 0 == only 1 channel
assign s2c1_cfg_constants[31:28] = 4'h0;                    // Reserved
assign s2c1_cfg_constants[38:32] = 7'h0;                    // Implemented user status width; 0 == not used
assign s2c1_cfg_constants[   39] = 1'b0;                    // Reserved
assign s2c1_cfg_constants[46:40] = 7'd64;                   // Implemented user control width; 64 == maximum width
assign s2c1_cfg_constants[   47] = 1'b0;                    // Reserved
assign s2c1_cfg_constants[63:48] = 16'h0;                   // Reserved

// DMA Direct Control Port is unused
assign s2c1_desc_req   = 1'b0;
assign s2c1_desc_ptr   = 32'h0;
assign s2c1_desc_data  = {DESC_WIDTH{1'b0}};
assign s2c1_desc_abort = 1'b0;
assign s2c1_desc_rst_n = 1'b1;

s2c_pkt_streaming_fifo #(

    .FIFO_ADDR_WIDTH        (FIFO_DADDR_WIDTH           )

) s2c1_s2c_pkt_streaming_fifo 
(

    .rst_n                  (s2c1_cmd_rst_n             ),
    .clk                    (user_clk                   ),

    .cmd_req                (s2c1_cmd_req               ),
    .cmd_ready              (s2c1_cmd_ready             ),
    .cmd_bcount             (s2c1_cmd_bcount            ),
    .cmd_addr               (s2c1_cmd_addr              ),
    .cmd_user_control       (s2c1_cmd_user_control      ),
    .cmd_abort              (s2c1_cmd_abort             ),
    .cmd_abort_ack          (s2c1_cmd_abort_ack         ),
    .cmd_stop               (s2c1_cmd_stop              ),
    .cmd_stop_bcount        (s2c1_cmd_stop_bcount       ),

    .data_req               (s2c1_data_req              ),
    .data_ready             (s2c1_data_ready            ),
    .data_addr              (s2c1_data_addr             ),
    .data_bcount            (s2c1_data_bcount           ),
    .data_en                (s2c1_data_en               ),
    .data_error             (s2c1_data_error            ),
    .data_remain            (s2c1_data_remain           ),
    .data_valid             (s2c1_data_valid            ),
    .data_first_req         (s2c1_data_first_req        ),
    .data_last_req          (s2c1_data_last_req         ),
    .data_first_desc        (s2c1_data_first_desc       ),
    .data_last_desc         (s2c1_data_last_desc        ),
    .data_first_chain       (s2c1_data_first_chain      ),
    .data_last_chain        (s2c1_data_last_chain       ),
    .data_data              (s2c1_data_data             ),
    .data_user_control      (s2c1_data_user_control     ),
                                                          
    .user_control           (s2c1_user_control          ),
    .sop                    (s2c1_sop                   ),
    .eop                    (s2c1_eop                   ),
    .err                    (s2c1_err                   ),
    .data                   (s2c1_data                  ),
    .valid                  (s2c1_valid                 ),
    .src_rdy                (s2c1_src_rdy               ),
    .dst_rdy                (s2c1_dst_rdy               ),
    .abort                  (s2c1_abort                 ),
    .abort_ack              (s2c1_abort_ack             ),
    .user_rst_n             (s2c1_user_rst_n            ),
                                                          
    .apkt_req               (s2c1_apkt_req              ),
    .apkt_ready             (s2c1_apkt_ready            ),
    .apkt_addr              (s2c1_apkt_addr             ),
    .apkt_bcount            (s2c1_apkt_bcount           )
                                                          
);


endmodule
