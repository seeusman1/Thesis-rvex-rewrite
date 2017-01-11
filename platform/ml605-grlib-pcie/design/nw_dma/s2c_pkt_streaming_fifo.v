// -------------------------------------------------------------------------
//
//  PROJECT: PCI Express Core
//  COMPANY: Northwest Logic, Inc.
//
// ------------------------- CONFIDENTIAL ----------------------------------
//
//                 Copyright 2009 Northwest Logic, Inc.
//
//  All rights reserved.  No part of this source code may be reproduced or
//  transmitted in any form or by any means, electronic or mechanical,
//  including photocopying, recording, or any information storage and
//  retrieval system, without permission in writing from Northwest Logic, Inc.
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

// Provides a single clock FIFO to transfer a packet stream between user
//   logic and the DMA Back-End Card to System Local DMA Interface.
//
// Provision is made to end DMA Descriptors early when eop is asserted
//   to mark a packet's end.
//
// Provision is made to transfer sop, eop, and user_status to the DMA Back-End
//   Card to System DMA Engine.  When eop is asserted the value on user_status
//   is passed to the DMA Back-End.  In addition, sop & eop are kept with their
//   associated data words.

`timescale 1ps / 1ps



// -----------------------
// -- Module Definition --
// -----------------------

module s2c_pkt_streaming_fifo (

    rst_n,                  // Asynchronous active low reset
    clk,                    // Posedge Clock

    cmd_req,                // Card to System DMA Engine: User Command Interface
    cmd_ready,              //   Get user's permission to issue a non-posted request of specified size/address
    cmd_addr,               //
    cmd_bcount,             //
    cmd_user_control,       //
    cmd_abort,              //
    cmd_abort_ack,          //
    cmd_stop,               //
    cmd_stop_bcount,        //

    data_req,               // User Data Interface
    data_ready,             //
    data_addr,              //
    data_bcount,            //
    data_en,                //
    data_error,             //
    data_remain,            //
    data_valid,             //
    data_first_req,         //
    data_last_req,          //
    data_first_desc,        //
    data_last_desc,         //
    data_first_chain,       //
    data_last_chain,        //
    data_data,              //
    data_user_control,      //

    user_control,           // Card to System Packet Streaming Interface
    sop,                    //
    eop,                    //
    err,                    //
    data,                   //
    valid,                  //
    src_rdy,                //
    dst_rdy,                //
    abort,                  //
    abort_ack,              //
    user_rst_n,             //

    apkt_req,               // Addressed Packet Interface
    apkt_ready,
    apkt_addr,
    apkt_bcount

);



// ----------------
// -- Parameters --
// ----------------

// NOTE: Only values which are parameters are intended to be modified from their default values
localparam  CORE_DATA_WIDTH         = 64;   // Width of input and output data
localparam  CORE_REMAIN_WIDTH       = 3;    // 2^CORE_REMAIN_WIDTH represents the number of bytes in CORE_DATA_WIDTH

localparam  USER_CONTROL_WIDTH      = 64;

// Data FIFO
parameter   FIFO_ADDR_WIDTH         = 7 + (4 - CORE_REMAIN_WIDTH);          // Address width of data FIFO; Default to 2 KBytes; min 2 KBytes
localparam  FIFO_NUM_WORDS          = 1 << FIFO_ADDR_WIDTH;                 // Number of words in the FIFO

localparam  FIFO_ADDR_BWIDTH        = FIFO_ADDR_WIDTH + CORE_REMAIN_WIDTH;  // 2^FIFO_ADDR_BWIDTH == Number of bytes FIFO can hold
localparam  MAX_RD_REQ_BWIDTH       = 9;                                    // Maximum read request size supported by DMA Back-End == 2^MAX_RD_REQ_BWIDTH
localparam  FIFO_REQ_BITS           = FIFO_ADDR_BWIDTH - MAX_RD_REQ_BWIDTH; // (2^FIFO_REQ_BITS)-1 == Number of (2^MAX_RD_REQ_BWIDTH) byte requests FIFO can hold;
                                                                            //   Need to save 1 (2^MAX_RD_REQ_BWIDTH) byte request worth of space to guarantee
                                                                            //   storage for held over partial data from a previous request

localparam  FIFO_DATA_WIDTH         = 69 + CORE_REMAIN_WIDTH + CORE_DATA_WIDTH;

// Abort state machine timeout counter widths; used when software aborts a DMA before it completes normally
parameter   TIMER1_WIDTH            = 10;   // 2^TIMER1_WIDTH == clocks to wait with no data transfers before assuming interfaces are stuck because one side can't provide/consume data; Minimum 4
parameter   TIMER2_WIDTH            = 8;    // 2^TIMER2_WIDTH == clocks to wait with no data transfers or requests before assuming interfaces are stuck because one side can't provide/consume data; Minimum 4
parameter   TIMER3_WIDTH            = 4;    // 2^(TIMER3_WIDTH-1) == clocks to assert and hold internal reset for after asserting cmd_abort_ack at end of abort process; Minimum 4; also
                                            //   (2^TIMER3_WIDTH) == clocks befor a new cmd_abort will cause re-entry of abort state machine

// Abort State Machine States
localparam  ABORT_IDLE              = 5'b00001;
localparam  ABORT_DATA              = 5'b00010;
localparam  ABORT_FLUSH             = 5'b00100;
localparam  ABORT_WAIT              = 5'b01000;
localparam  ABORT_EXIT              = 5'b10000;

// Data stream state machine states
localparam  DATA_IDLE               = 3'b001;
localparam  DATA_CHCK               = 3'b010;
localparam  DATA_RESP               = 3'b100;



// ----------------------
// -- Port Definitions --
// ----------------------

input                               rst_n;
input                               clk;

input                               cmd_req;
output                              cmd_ready;
input   [63:0]                      cmd_addr;
input   [9:0]                       cmd_bcount;
input   [63:0]                      cmd_user_control;
input                               cmd_abort;
output                              cmd_abort_ack;
output                              cmd_stop;
output  [9:0]                       cmd_stop_bcount;

input                               data_req;
output                              data_ready;
input   [63:0]                      data_addr;
input   [9:0]                       data_bcount;
input                               data_en;
input                               data_error;
input   [CORE_REMAIN_WIDTH-1:0]     data_remain;
input   [CORE_REMAIN_WIDTH:0]       data_valid;
input                               data_first_req;
input                               data_last_req;
input                               data_first_desc;
input                               data_last_desc;
input                               data_first_chain;
input                               data_last_chain;
input   [CORE_DATA_WIDTH-1:0]       data_data;
input   [63:0]                      data_user_control;

output  [63:0]                      user_control;
output                              sop;
output                              eop;
output                              err;
output  [CORE_DATA_WIDTH-1:0]       data;
output  [CORE_REMAIN_WIDTH-1:0]     valid;
output                              src_rdy;
input                               dst_rdy;
output                              abort;
input                               abort_ack;
output                              user_rst_n;

output                              apkt_req;
input                               apkt_ready;
output  [63:0]                      apkt_addr;
output  [9:0]                       apkt_bcount;


// ----------------
// -- Port Types --
// ----------------

wire                                rst_n;
wire                                clk;

wire                                cmd_req;
wire                                cmd_ready;
wire    [63:0]                      cmd_addr;
wire    [9:0]                       cmd_bcount;
wire    [63:0]                      cmd_user_control;
wire                                cmd_abort;
reg                                 cmd_abort_ack;
wire                                cmd_stop;
wire    [9:0]                       cmd_stop_bcount;

wire                                data_req;
wire                                data_ready;
wire    [63:0]                      data_addr;
wire    [9:0]                       data_bcount;
wire                                data_en;
wire                                data_error;
wire    [CORE_REMAIN_WIDTH-1:0]     data_remain;
wire    [CORE_REMAIN_WIDTH:0]       data_valid;
wire                                data_first_req;
wire                                data_last_req;
wire                                data_first_desc;
wire                                data_last_desc;
wire                                data_first_chain;
wire                                data_last_chain;
wire    [CORE_DATA_WIDTH-1:0]       data_data;
wire    [63:0]                      data_user_control;

reg     [63:0]                      user_control;
reg                                 sop;
reg                                 eop;
reg                                 err;
reg     [CORE_DATA_WIDTH-1:0]       data;
reg     [CORE_REMAIN_WIDTH-1:0]     valid;
reg                                 src_rdy;
wire                                dst_rdy;
reg                                 abort;
wire                                abort_ack;
wire                                user_rst_n;

reg                                 apkt_req;
wire                                apkt_ready;
reg     [63:0]                      apkt_addr;
reg     [9:0]                       apkt_bcount;


// -------------------
// -- Local Signals --
// -------------------

// Pipeline Reset
reg                                 r5_dma_rst_n;
reg                                 r6_dma_rst_n;
reg                                 r7_dma_rst_n;
reg                                 r8_dma_rst_n;

// Handle Aborts
reg                                 d_flush;

reg                                 reset_timer1;
reg     [TIMER1_WIDTH-1:0]          timer1;
reg                                 timer1_tc;

reg                                 reset_timer2;
reg     [TIMER2_WIDTH-1:0]          timer2;
reg                                 timer2_tc;

reg                                 reset_timer3;
reg     [TIMER3_WIDTH-1:0]          timer3;
reg                                 timer3_tc;

reg     [TIMER3_WIDTH-2:0]          int_rst_ctr;
reg                                 d_int_rst_n;

(* equivalent_register_removal = "no" *)
reg                                 int0_rst_n;
(* equivalent_register_removal = "no" *)
reg                                 int1_rst_n;
(* equivalent_register_removal = "no" *)
reg                                 int2_rst_n;
(* equivalent_register_removal = "no" *)
reg                                 int3_rst_n;
`ifdef PACKET_DMA_BYTE_SUPPORT
(* equivalent_register_removal = "no" *)
reg                                 int4_rst_n;
(* equivalent_register_removal = "no" *)
reg                                 int5_rst_n;
`endif

reg     [4:0]                       abort_state;

// Instantiate RAM for FIFO
wire                                fifo_in_src_rdy;
wire                                fifo_in_dst_rdy;
wire                                fifo_in_en;
wire    [FIFO_DATA_WIDTH-1:0]       fifo_in_rd_data;

wire                                rd_src_rdy;
wire                                rd_dst_rdy;
wire    [FIFO_DATA_WIDTH-1:0]       rd_data;

// Write side of FIFO - Flow Control
wire                                wr_req_en;
wire                                rd_req_en;

reg     [FIFO_REQ_BITS-1:0]         wr_eop_level;

// Write side of FIFO - Data
wire                                data_sop;
wire                                data_eop;

`ifdef PACKET_DMA_BYTE_SUPPORT
wire    [CORE_REMAIN_WIDTH-1:0]     c_data_save_bcount;
wire    [CORE_REMAIN_WIDTH:0]       c_data_sum;

wire                                c_wr_en_data;
wire                                c_wr_eop;
wire                                c_wr_eop_extra;

wire                                c_wr_en_last;
wire                                c_wr_en_last_extra;

wire                                c_wr_en;

reg                                 r_wr_eop_extra;
reg                                 wr_eop;
reg                                 wr_en;
reg                                 wr_no_xfer;

reg     [CORE_REMAIN_WIDTH-1:0]     wr_valid;

reg                                 r_wr_en_last_extra;

reg                                 wr_sop;
reg                                 wr_last_req;
reg     [USER_CONTROL_WIDTH-1:0]    wr_user_control;

reg                                 xtra_data_error;
reg                                 wr_error;

reg     [CORE_REMAIN_WIDTH-1:0]     data_save_bcount;

reg     [CORE_DATA_WIDTH-1:0]       saved_data;
reg     [CORE_DATA_WIDTH-1:0]       wr_mux_data;
reg     [CORE_DATA_WIDTH-1:0]       c_wr_mux_data;

wire    [FIFO_DATA_WIDTH-1:0]       wr_data;
`else
wire                                wr_en;
wire    [FIFO_DATA_WIDTH-1:0]       wr_data;
`endif

reg     [FIFO_ADDR_WIDTH-1:0]       wr_addr;

//  Read side of FIFO
reg                                 r_wr_en;
reg     [FIFO_ADDR_WIDTH:0]         rd_level;
reg                                 rd_avail;

wire                                rd_en;

wire    [FIFO_ADDR_WIDTH-1:0]       c_rd_addr;
reg     [FIFO_ADDR_WIDTH-1:0]       rd_addr;

wire                                rd_no_xfer;
wire    [CORE_REMAIN_WIDTH-1:0]     rd_valid;
wire                                rd_err;
wire                                rd_last_req;
wire                                rd_sop;
wire                                rd_eop;
wire    [63:0]                      rd_user_control;
wire    [CORE_DATA_WIDTH-1:0]       rd_pkt_data;

(* equivalent_register_removal = "no" *)
reg                                 out_full;
reg                                 end_abort_wait;
(* equivalent_register_removal = "no" *)
reg                                 int_src_rdy;
reg                                 int_err;
reg                                 last_req;
reg                                 int_sop;
reg                                 int_eop;

reg                                 in_pkt;
wire                                in_pkt_exit;

wire                                en;

// Addressed Pcket Interface
reg                                 int_data_ready;
wire                                apkt_wr_en;
wire    [3:0]                       apkt_wr_level;
wire    [73:0]                      apkt_wr_data;
wire                                apkt_full;
wire                                apkt_rd_en;
wire    [73:0]                      apkt_rd_data;
wire    [3:0]                       apkt_rd_level;
wire                                apkt_empty;


// ---------------
// -- Equations --
// ---------------

assign  cmd_ready    = 1'b1;
assign  apkt_wr_data = {data_bcount, data_addr};

assign  data_ready   = ~apkt_full & int_data_ready;
assign  apkt_wr_en  = data_req & data_ready;
assign  apkt_rd_en  = (apkt_ready | ~apkt_req) & ~apkt_empty;

ref_sc_fifo_shallow_ram #(
    .DATA_WIDTH     (74             ),
    .ADDR_WIDTH     (3              ),
    .EN_LOOK_AHEAD  (1              )
) apkt_fifo (
    .rst_n          (rst_n          ),
    .clk            (clk            ),
    .flush          (1'b0           ),
    .wr_en          (apkt_wr_en     ),
    .wr_data        (apkt_wr_data   ),
    .wr_level       (apkt_wr_level  ),
    .wr_full        (apkt_full      ),
    .rd_ack         (apkt_rd_en     ),
    .rd_data        (apkt_rd_data   ),
    .rd_level       (apkt_rd_level  ),
    .rd_empty       (apkt_empty     )
);

always @(posedge clk or negedge rst_n) begin
    if (rst_n == 1'b0) begin
        apkt_addr   <= 64'h0;
        apkt_bcount <= 10'b0;
        apkt_req    <= 1'b0;
    end
    else begin
        if (apkt_rd_en) begin
            apkt_addr   <= apkt_rd_data[63:0];
            apkt_bcount <= apkt_rd_data[73:64];
            apkt_req    <= 1'b1;
        end
        else if (apkt_ready)
            apkt_req <= 1'b0;
    end
end

// --------------
// Pipeline Reset

// rst_n input is delayed 4 of 8 clocks at input to this
//   module; delay an additional 4 clocks to release at
//   the same 8 clock delay time as other logic using
//   this reset tree; take advantage of reset tree to
//   reduce reset fanout
always @(posedge clk or negedge rst_n)
begin
    if (rst_n == 1'b0)
    begin
        r5_dma_rst_n <= 1'b0;
        r6_dma_rst_n <= 1'b0;
        r7_dma_rst_n <= 1'b0;
        r8_dma_rst_n <= 1'b0;
    end
    else
    begin
        r5_dma_rst_n <= 1'b1;
        r6_dma_rst_n <= r5_dma_rst_n;
        r7_dma_rst_n <= r6_dma_rst_n;
        r8_dma_rst_n <= r7_dma_rst_n;
    end
end

// Pass reset through this module; use 6 clock delayed version,
//   so destination can pipeline 2 clocks also
assign user_rst_n = r6_dma_rst_n;



// -------------
// Handle Aborts

always @(posedge clk or negedge r8_dma_rst_n)
begin
    if (r8_dma_rst_n == 1'b0)
    begin
        abort         <= 1'b0;
        d_flush       <= 1'b0;
        cmd_abort_ack <= 1'b0;

        reset_timer1  <= 1'b0;
        timer1        <= {TIMER1_WIDTH{1'b0}};
        timer1_tc     <= 1'b0;

        reset_timer2  <= 1'b0;
        timer2        <= {TIMER2_WIDTH{1'b0}};
        timer2_tc     <= 1'b0;

        reset_timer3  <= 1'b0;
        timer3        <= {TIMER3_WIDTH{1'b0}};
        timer3_tc     <= 1'b0;

        int_rst_ctr   <= {(TIMER3_WIDTH-1){1'b1}};
        d_int_rst_n   <= 1'b0;

        int0_rst_n    <= 1'b0;
        int1_rst_n    <= 1'b0;
        int2_rst_n    <= 1'b0;
        int3_rst_n    <= 1'b0;
`ifdef PACKET_DMA_BYTE_SUPPORT
        int4_rst_n    <= 1'b0;
        int5_rst_n    <= 1'b0;
`endif
    end
    else
    begin
        // Pass abort request to user
        if ((abort_state == ABORT_IDLE) & cmd_abort)
            abort <= 1'b1;
        else if (abort_ack)
            abort <= 1'b0;

        // When in this state, we need to flush user and DMA data
        d_flush <= (abort_state == ABORT_FLUSH);

        // Acknowledge abort when leaving ABORT_WAIT
        cmd_abort_ack <= (abort_state == ABORT_WAIT) & ~abort; // abort_state to ABORT_EXIT

        // Reset timer1 when data transfers to DMA Engine or user;
        //   timer1 counts the number of clocks that occurred with no
        //   data transfers; once timer1 times out, it is assumed
        //   that no more data will transfer; this should be because
        //   either there are not enough DMA Descriptors to consume/provide
        //   the requied amount of user data or there is not enough user data
        //   to consume/provide the required amount of DMA data
        reset_timer1 <= data_en | (int_src_rdy & dst_rdy) | (abort_state != ABORT_DATA);

        if (reset_timer1)
            timer1 <= {TIMER1_WIDTH{1'b0}};
        else
            timer1 <= timer1 + {{(TIMER1_WIDTH-1){1'b0}}, 1'b1};

        if (reset_timer1)
            timer1_tc <= 1'b0;
        else
            timer1_tc <= (timer1 == {TIMER1_WIDTH{1'b1}});

        // Reset timer2 when there are active requests or the user has data
        //   timer2 counts the number of clocks that occurred with no
        //   data transfers and no active requests; once timer2 times out,
        //   it is assumed that all interfaces are idle
        reset_timer2 <= data_en | (int_src_rdy & dst_rdy) | // Data Transfer
                        cmd_req | data_req                | // Command or Data Request
                        (abort_state != ABORT_FLUSH);       // Not in a state where we count

        if (reset_timer2)
            timer2 <= {TIMER2_WIDTH{1'b0}};
        else
            timer2 <= timer2 + {{(TIMER2_WIDTH-1){1'b0}}, 1'b1};

        if (reset_timer2)
            timer2_tc <= 1'b0;
        else
            timer2_tc <= (timer2 == {TIMER2_WIDTH{1'b1}});

        // Reset timer3 when not in ABORT_EXIT state;
        //   timer3 guarantees a minimum amount of time from the assertion of
        //   cmd_abort_ack to being able to re-enter this state machine
        reset_timer3 <= (abort_state != ABORT_EXIT);

        if (reset_timer3)
            timer3 <= {TIMER3_WIDTH{1'b0}};
        else if (timer3 != {TIMER3_WIDTH{1'b1}})
            timer3 <= timer3 + {{(TIMER3_WIDTH-1){1'b0}}, 1'b1};

        if (reset_timer3)
            timer3_tc <= 1'b0;
        else
            timer3_tc <= (timer3 == {TIMER3_WIDTH{1'b1}});

        // Generate internal reset
        if ((abort_state == ABORT_WAIT) & ~abort) // abort_state to ABORT_EXIT
            int_rst_ctr <= {(TIMER3_WIDTH-1){1'b1}};
        else if (int_rst_ctr != {(TIMER3_WIDTH-1){1'b0}})
            int_rst_ctr <= int_rst_ctr - {{(TIMER3_WIDTH-2){1'b0}}, 1'b1};

        d_int_rst_n <= (int_rst_ctr == {(TIMER3_WIDTH-1){1'b0}});

        // Make multiple copies to reduce fanout
        int0_rst_n <= d_int_rst_n;
        int1_rst_n <= d_int_rst_n;
        int2_rst_n <= d_int_rst_n;
        int3_rst_n <= d_int_rst_n;
`ifdef PACKET_DMA_BYTE_SUPPORT
        int4_rst_n <= d_int_rst_n;
        int5_rst_n <= d_int_rst_n;
`endif
    end
end

// Abort State Machine
always @(posedge clk or negedge r8_dma_rst_n)
begin
    if (r8_dma_rst_n == 1'b0)
    begin
        abort_state <= ABORT_IDLE;
    end
    else
    begin
        case (abort_state)

            // This is the normal operational state
            ABORT_IDLE :
                if (cmd_abort) // Abort request
                    abort_state <= ABORT_DATA;

            // Consume available data normally
            ABORT_DATA :
                if (timer1_tc)
                    abort_state <= ABORT_FLUSH;

            // Once here it is assumed that no more real
            //   data will transfer; force the ready
            //   terms on all interfaces to allow the
            //   interfaces to flush their data and
            //   return to IDLE
            ABORT_FLUSH :
                if (timer2_tc)
                    abort_state <= ABORT_WAIT;

            // Don't finish abort process until user has indicated
            //   that they are idle; if user is hung, then the
            //   abort process will hang here; software can tell
            //   that the abort process does not complete and can
            //   force a hard reset to force user logic to the idle
            //   (reset) state
            ABORT_WAIT :
                if (~abort)
                    abort_state <= ABORT_EXIT;

            // Guarantee a minimum amount of time from the assertion of
            //   cmd_abort_ack to being able to re-enter this state machine
            ABORT_EXIT :
                if (timer3_tc)
                    abort_state <= ABORT_IDLE;

            default :
                abort_state <= ABORT_IDLE;

        endcase
    end
end



// ------------------------
// Instantiate RAM for FIFO

// Read enable is always asserted, so the rd_data output depends exclusively on rd_addr
ref_inferred_block_ram #(

    .ADDR_WIDTH     (FIFO_ADDR_WIDTH    ),
    .DATA_WIDTH     (FIFO_DATA_WIDTH    )

) fifo_ram (

    .wr_clk         (clk                ),
    .wr_addr        (wr_addr            ),
    .wr_en          (wr_en              ),
    .wr_data        (wr_data            ),

    .rd_clk         (clk                ),
    .rd_addr        (c_rd_addr          ),
    .rd_data        (fifo_in_rd_data    )

);

assign fifo_in_src_rdy = rd_avail; // RAM has data available
assign fifo_in_en      = fifo_in_src_rdy & fifo_in_dst_rdy;

// Use a small FIFO to reduce complexity of meeting timing with Block RAM
ref_tiny_fifo #(

    .DATA_WIDTH     (FIFO_DATA_WIDTH    )

) ref_tiny_fifo (

    .rst_n          (int0_rst_n         ),
    .clk            (clk                ),

    .in_src_rdy     (fifo_in_src_rdy    ),
    .in_dst_rdy     (fifo_in_dst_rdy    ),
    .in_data        (fifo_in_rd_data    ),

    .out_src_rdy    (rd_src_rdy         ),
    .out_dst_rdy    (rd_dst_rdy         ),
    .out_data       (rd_data            )

);



// ---------------------------------
// Write side of FIFO - Flow Control

// Flow control into FIFO is accomplished with data_req_* ports;
//   Data requests are a maximum size of 512 bytes; track requests
//   knowing each request <= 512 bytes rather than data to simplify
//   tracking flow control for the FIFO
assign wr_req_en = data_req & data_ready;   // Allowing a new <= 512 byte read request to occur
assign rd_req_en = last_req;                // Fully read out all data for a request

// This module can hold packet data from up to two different packets;
//   track # of packets that have some data in the FIFO
always @(posedge clk or negedge int0_rst_n)
begin
    if (int0_rst_n == 1'b0)
        wr_eop_level <= {FIFO_REQ_BITS{1'b0}};
    else
    begin
        case ({wr_req_en, rd_req_en})
            2'b01   : wr_eop_level <= wr_eop_level - {{(FIFO_REQ_BITS-1){1'b0}}, 1'b1};
            2'b10   : wr_eop_level <= wr_eop_level + {{(FIFO_REQ_BITS-1){1'b0}}, 1'b1};
            default : wr_eop_level <= wr_eop_level;
        endcase
    end
end

// This module can hold packet data from up to two different packets;
//   limit the number of packets that have data in the FIFO to 2 or less
always @(posedge clk or negedge int0_rst_n)
begin
    if (int0_rst_n == 1'b0)
        int_data_ready <= 1'b1;
    else
    begin
        if (d_flush)
            int_data_ready <= 1'b1;
        else
        begin
            case ({wr_req_en, rd_req_en})
                2'b01   : int_data_ready <= 1'b1;
                2'b10   : int_data_ready <= ~(wr_eop_level == {{(FIFO_REQ_BITS-1){1'b1}}, 1'b0}); // 1 from full
                default : int_data_ready <= ~(wr_eop_level == {FIFO_REQ_BITS{1'b1}}); // full
            endcase
        end
    end
end

// Not used for S2C DMA
assign cmd_stop        = 1'b0;
assign cmd_stop_bcount = 10'h0;



// -------------------------
// Write side of FIFO - Data

// Rename input signals to more representative names
assign data_sop = data_first_chain;
assign data_eop = data_last_chain;

`ifdef PACKET_DMA_BYTE_SUPPORT
// Get amount of saved data; data not saved accross packet boundaries
assign c_data_save_bcount = data_sop ? {CORE_REMAIN_WIDTH{1'b0}} : data_save_bcount;

// Sum valid data this clock and saved data
assign c_data_sum  = (r_wr_eop_extra ? {(CORE_REMAIN_WIDTH+1){1'b0}} : data_valid) + {1'b0, c_data_save_bcount};

assign c_wr_en_data        =                 data_en &  (data_eop | (c_data_sum >= {1'b1, {CORE_REMAIN_WIDTH{1'b0}}})); // Write a word if its the last in the pkt or as long as there is a full clock of data
assign c_wr_eop            =                 data_en &  (data_eop & (c_data_sum <= {1'b1, {CORE_REMAIN_WIDTH{1'b0}}})); // Ending amount of data can transfer this clock; output eop this clock
assign c_wr_eop_extra      =                 data_en &  (data_eop & (c_data_sum >  {1'b1, {CORE_REMAIN_WIDTH{1'b0}}})); // Ending with more saved data than can transfer this clock; output eop next clock instead of this clock

assign c_wr_en_last        = data_last_req & data_en & ~(data_eop & (c_data_sum >  {1'b1, {CORE_REMAIN_WIDTH{1'b0}}}));
assign c_wr_en_last_extra  = data_last_req & data_en &  (data_eop & (c_data_sum >  {1'b1, {CORE_REMAIN_WIDTH{1'b0}}}));

assign c_wr_en = c_wr_en_data | r_wr_eop_extra;

always @(posedge clk or negedge int4_rst_n)
begin
    if (int4_rst_n == 1'b0)
    begin
        r_wr_eop_extra     <= 1'b0;
        wr_eop             <= 1'b0;
        wr_en              <= 1'b0;
        wr_no_xfer         <= 1'b0;

        wr_valid           <= {CORE_REMAIN_WIDTH{1'b0}};

        r_wr_en_last_extra <= 1'b0;
        wr_last_req        <= 1'b0;

        wr_sop             <= 1'b0;
        wr_user_control    <= {USER_CONTROL_WIDTH{1'b0}};

        xtra_data_error    <= 1'b0;
        wr_error           <= 1'b0;

        data_save_bcount   <= {CORE_REMAIN_WIDTH{1'b0}};
    end
    else
    begin
        // Check for case where an extra enable is needed after end of packet to write out an earlier saved partial word
        r_wr_eop_extra  <=            c_wr_eop_extra;
        wr_eop          <= c_wr_eop | r_wr_eop_extra;

        wr_en           <=  c_wr_en | c_wr_en_last;
        wr_no_xfer      <= ~c_wr_en & c_wr_en_last;

        if (c_data_sum > {1'b1, {CORE_REMAIN_WIDTH{1'b0}}})
            wr_valid <= {CORE_REMAIN_WIDTH{1'b0}};
        else
            wr_valid <= c_data_sum[CORE_REMAIN_WIDTH-1:0];

        r_wr_en_last_extra <= c_wr_en_last_extra;
        wr_last_req        <= c_wr_en_last | r_wr_en_last_extra;

        if (data_en & data_sop)
            wr_sop <= 1'b1;
        else if (wr_en & ~wr_no_xfer)
            wr_sop <= 1'b0;

        if (data_en & data_sop)
            wr_user_control <= data_user_control;

        // Assign any error indicator to the extra enable if one is present
        xtra_data_error <= data_error;
        wr_error        <= r_wr_eop_extra ? xtra_data_error : data_error;

        if (data_en)
        begin
            if (data_sop)
                data_save_bcount <= data_valid[CORE_REMAIN_WIDTH-1:0];
            else
                data_save_bcount <= data_valid[CORE_REMAIN_WIDTH-1:0] + data_save_bcount;
        end
    end
end

always @(posedge clk or negedge int5_rst_n)
begin
    if (int5_rst_n == 1'b0)
    begin
        saved_data         <= {CORE_DATA_WIDTH{1'b0}};
        wr_mux_data        <= {CORE_DATA_WIDTH{1'b0}};
    end
    else
    begin
        // Save data that is unused in the current clock cycle
        if (data_en)
        begin
            if (c_data_sum[3]) // have more than a full word; save portion above CORE_DATA_WIDTH
            begin
                case (c_data_save_bcount[2:0])
                    3'h0 : saved_data <=  64'h0;
                    3'h1 : saved_data <= {56'h0, data_data[63:56]};
                    3'h2 : saved_data <= {48'h0, data_data[63:48]};
                    3'h3 : saved_data <= {40'h0, data_data[63:40]};
                    3'h4 : saved_data <= {32'h0, data_data[63:32]};
                    3'h5 : saved_data <= {24'h0, data_data[63:24]};
                    3'h6 : saved_data <= {16'h0, data_data[63:16]};
                    3'h7 : saved_data <= { 8'h0, data_data[63: 8]};
                endcase
            end
            else // have less than a full word; save all data since none transfers
            begin
                saved_data <= c_wr_mux_data;
            end
        end

        if (data_en | r_wr_eop_extra)
            wr_mux_data <= c_wr_mux_data;
    end
end

always@*
begin
    case (c_data_save_bcount[2:0])
        3'h0 : c_wr_mux_data =  data_data;
        3'h1 : c_wr_mux_data = {data_data[55:0], saved_data[ 7:0]};
        3'h2 : c_wr_mux_data = {data_data[47:0], saved_data[15:0]};
        3'h3 : c_wr_mux_data = {data_data[39:0], saved_data[23:0]};
        3'h4 : c_wr_mux_data = {data_data[31:0], saved_data[31:0]};
        3'h5 : c_wr_mux_data = {data_data[23:0], saved_data[39:0]};
        3'h6 : c_wr_mux_data = {data_data[15:0], saved_data[47:0]};
        3'h7 : c_wr_mux_data = {data_data[ 7:0], saved_data[55:0]};
    endcase
end

// Flow control is done with requests, so just accept data that arrives
assign wr_data = {wr_no_xfer, wr_valid, wr_error, wr_last_req, wr_sop, wr_eop, wr_user_control, wr_mux_data};
`else
// Flow control is done with requests, so just accept data that arrives
assign wr_en   = data_en;
assign wr_data = {1'b0, data_valid[CORE_REMAIN_WIDTH-1:0], data_error, data_last_req, data_sop, data_eop, data_user_control, data_data};
`endif

always @(posedge clk or negedge int0_rst_n)
begin
    if (int0_rst_n == 1'b0)
    begin
        wr_addr <= {FIFO_ADDR_WIDTH{1'b0}};
    end
    else
    begin
        if (wr_en)
            wr_addr <= wr_addr + {{(FIFO_ADDR_WIDTH-1){1'b0}}, 1'b1};
    end
end



// -------------------
//  Read side of FIFO

always @(posedge clk or negedge int1_rst_n)
begin
    if (int1_rst_n == 1'b0)
    begin
        r_wr_en  <= 1'b0;
        rd_level <= {(FIFO_ADDR_WIDTH+1){1'b0}};
        rd_avail <= 1'b0;
    end
    else
    begin
        // Don't let data appear on rd_level until it could be read out of FIFO
        r_wr_en <= wr_en;

        case ({r_wr_en, fifo_in_en})
            2'b01   : rd_level <= rd_level - {{FIFO_ADDR_WIDTH{1'b0}}, 1'b1};
            2'b10   : rd_level <= rd_level + {{FIFO_ADDR_WIDTH{1'b0}}, 1'b1};
            default : rd_level <= rd_level;
        endcase

        case ({r_wr_en, fifo_in_en})
            2'b01   : rd_avail <= (rd_level > {{FIFO_ADDR_WIDTH{1'b0}}, 1'b1});
            2'b10   : rd_avail <= 1'b1;
            default : rd_avail <= (rd_level != {(FIFO_ADDR_WIDTH+1){1'b0}});
        endcase
    end
end

// Use look-ahead address for RAM to reduce FIFO read data latency
assign c_rd_addr = rd_addr + {{(FIFO_ADDR_WIDTH-1){1'b0}}, fifo_in_en};

always @(posedge clk or negedge int1_rst_n)
begin
    if (int1_rst_n == 1'b0)
        rd_addr <= {FIFO_ADDR_WIDTH{1'b0}};
    else
        rd_addr <= c_rd_addr;
end

// Data request data transfers
assign rd_dst_rdy = (~out_full | en);
assign rd_en      = rd_src_rdy & rd_dst_rdy;

assign rd_no_xfer      = rd_data[((CORE_DATA_WIDTH+CORE_REMAIN_WIDTH)+68)];
assign rd_valid        = rd_data[((CORE_DATA_WIDTH+CORE_REMAIN_WIDTH)+67):(CORE_DATA_WIDTH+68)];
assign rd_err          = rd_data[CORE_DATA_WIDTH+67                ];
assign rd_last_req     = rd_data[CORE_DATA_WIDTH+66                ];
assign rd_sop          = rd_data[CORE_DATA_WIDTH+65                ];
assign rd_eop          = rd_data[CORE_DATA_WIDTH+64                ];
assign rd_user_control = rd_data[CORE_DATA_WIDTH+63:CORE_DATA_WIDTH];
assign rd_pkt_data     = rd_data[CORE_DATA_WIDTH- 1:              0];

always @(posedge clk or negedge int2_rst_n)
begin
    if (int2_rst_n == 1'b0)
    begin
        out_full       <= 1'b0;
        end_abort_wait <= 1'b0;
        int_src_rdy    <= 1'b0;
        src_rdy        <= 1'b0;
        valid          <= {CORE_REMAIN_WIDTH{1'b0}};
        int_err        <= 1'b0;
        err            <= 1'b0;
        last_req       <= 1'b0;
        int_sop        <= 1'b0;
        sop            <= 1'b0;
        int_eop        <= 1'b0;
        eop            <= 1'b0;
        user_control   <= 64'h0;
    end
    else
    begin
        if (rd_en & ~rd_no_xfer)
            out_full <= 1'b1;
        else if (en)
            out_full <= 1'b0;

        // Need to clear src_rdy the clock after leaving ABORT_WAIT state
        end_abort_wait <= (abort_state == ABORT_WAIT) & ~abort;

        // Internal src_rdy does not need ABORT_WAIT flush logic
        if (rd_en & ~rd_no_xfer)
            int_src_rdy <= 1'b1;
        else if (en)
            int_src_rdy <= 1'b0;

        // External src_rdy is int_src_rdy plus ABORT_WAIT flush logic
        if ((abort_state == ABORT_WAIT) | (rd_en & ~rd_no_xfer))
            src_rdy <= 1'b1;
        else if (end_abort_wait | en)
            src_rdy <= 1'b0;

        if (rd_en & ~rd_no_xfer & rd_eop)
            valid <= rd_valid[CORE_REMAIN_WIDTH-1:0];
        else if (en)
            valid <= {CORE_REMAIN_WIDTH{1'b0}};

        // Hold error for whole packet;
        //   Internal err does not need ABORT_WAIT flush logic
        if (rd_en & ~rd_no_xfer & rd_sop & rd_err)
            int_err <= 1'b1;
        else if (en & eop)
            int_err <= 1'b0;

        // External err is int_err plus ABORT_WAIT flush logic
        if ((abort_state == ABORT_WAIT) | (rd_en & ~rd_no_xfer & rd_sop & rd_err))
            err <= 1'b1;
        else if (end_abort_wait | (en & eop))
            err <= 1'b0;

        // Pulse for 1 clock when consuming the last FIFO element of a data request
        if (rd_en & rd_last_req) // Reading last data cycle of the request with or without data
            last_req <= 1'b1;
        else
            last_req <= 1'b0;

        if (rd_en & ~rd_no_xfer & rd_sop)
            int_sop <= 1'b1;
        else if (en)
            int_sop <= 1'b0;

        // External sop is int_sop plus ABORT_WAIT flush logic; when flushing don't assert
        //   sop if already transferring a packet
        if (((abort_state == ABORT_WAIT) & (~in_pkt | (in_pkt & in_pkt_exit))) | (rd_en & ~rd_no_xfer & rd_sop))
            sop <= 1'b1;
        else if (end_abort_wait | en)
            sop <= 1'b0;

        // Internal eop does not need ABORT_WAIT flush logic
        if (rd_en & ~rd_no_xfer & rd_eop)
            int_eop <= 1'b1;
        else if (en)
            int_eop <= 1'b0;

        // External eop is int_eop plus ABORT_WAIT flush logic
        if ((abort_state == ABORT_WAIT) | (rd_en & ~rd_no_xfer & rd_eop))
            eop <= 1'b1;
        else if (end_abort_wait | en)
            eop <= 1'b0;

        if (rd_en & ~rd_no_xfer & rd_sop)
            user_control <= rd_user_control;
    end
end

always @(posedge clk or negedge int3_rst_n)
begin
    if (int3_rst_n == 1'b0)
    begin
        data <= {CORE_DATA_WIDTH{1'b0}};
    end
    else
    begin
        // Timing optimization; was "if (rd_en & ~rd_no_xfer)" but data is
        //   irrelevant when rd_no_xfer == 1 since control logic will be
        //   de-asserted
        if (rd_en)
            data <= rd_pkt_data;
    end
end

// Keep track of when the user interface is busy receiving a packet;
//   only used at start of abort case to keep from asserting a double sop
//   before eop
always @(posedge clk or negedge int2_rst_n)
begin
    if (int2_rst_n == 1'b0)
    begin
        in_pkt <= 1'b0;
    end
    else
    begin
        if (sop & ~eop & src_rdy & dst_rdy) // Transferred start and not also end of packet
            in_pkt <= 1'b1;
        else if (eop & src_rdy & dst_rdy)   // Transferred end of packet
            in_pkt <= 1'b0;
    end
end

assign in_pkt_exit = eop & src_rdy & dst_rdy;

assign en = src_rdy & dst_rdy;



endmodule
