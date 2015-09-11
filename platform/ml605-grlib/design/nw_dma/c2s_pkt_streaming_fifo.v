// -------------------------------------------------------------------------
//
//  PROJECT: PCI Express Core
//  COMPANY: Northwest Logic, Inc.
//
// ------------------------- CONFIDENTIAL ----------------------------------
//
//                 Copyright 2008-2009 Northwest Logic, Inc.
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

module c2s_pkt_streaming_fifo (

    rst_n,                  // Asynchronous active low reset
    clk,                    // Posedge Clock

    cmd_req,                // Card to System DMA Engine: User Command Interface
    cmd_ready,              //   Get user's permission to issue a non-posted request of specified size/address
    cmd_first_chain,        //
    cmd_last_chain,         //
    cmd_bcount,             //
    cmd_addr,               //
    cmd_user_control,       //
    cmd_abort,              //
    cmd_abort_ack,          //

    data_req,               // User Data Interface - Command Portion
    data_ready,             //
    data_req_remain,        //
    data_req_last_desc,     //
    data_addr,              //
    data_bcount,            //
    data_stop,              //
    data_stop_bcount,       //

    data_en,                // User Data Interface - Data Portion
    data_remain,            //
    data_valid,             //
    data_first_req,         //
    data_last_req,          //
    data_first_desc,        //
    data_last_desc,         //
    data_first_chain,       //
    data_last_chain,        //
    data_sop,               //
    data_eop,               //
    data_data,              //
    data_user_status,       //

    user_status,            // Card to System Packet Streaming Interface
    sop,                    //
    eop,                    //
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
    apkt_bcount,
    apkt_eop

);



// ----------------
// -- Parameters --
// ----------------

// NOTE: Only values which are parameters are intended to be modified from their default values
localparam  CORE_DATA_WIDTH         = 64;   // Width of input and output data
localparam  CORE_REMAIN_WIDTH       = 3;    // 2^CORE_REMAIN_WIDTH represents the number of bytes in CORE_DATA_WIDTH

localparam  USER_STATUS_WIDTH       = 64;

// Data FIFO
parameter   FIFO_ADDR_WIDTH         = 7 + (4 - CORE_REMAIN_WIDTH);  // Address width of data FIFO; Want 2 KBytes minimum
localparam  FIFO_NUM_WORDS          = 1 << FIFO_ADDR_WIDTH;         // Number of words in the FIFO
localparam  FIFO_DATA_WIDTH         = CORE_DATA_WIDTH + USER_STATUS_WIDTH + CORE_REMAIN_WIDTH + 3;

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
input                               cmd_first_chain;
input                               cmd_last_chain;
input   [31:0]                      cmd_bcount;
input   [63:0]                      cmd_addr;
input   [63:0]                      cmd_user_control;
input                               cmd_abort;
output                              cmd_abort_ack;

input                               data_req;
output                              data_ready;
input   [CORE_REMAIN_WIDTH-1:0]     data_req_remain;
input                               data_req_last_desc;
input   [63:0]                      data_addr;
input   [9:0]                       data_bcount;
output                              data_stop;
output  [9:0]                       data_stop_bcount;

input                               data_en;
input   [CORE_REMAIN_WIDTH-1:0]     data_remain;
input   [CORE_REMAIN_WIDTH:0]       data_valid;
input                               data_first_req;
input                               data_last_req;
input                               data_first_desc;
input                               data_last_desc;
input                               data_first_chain;
input                               data_last_chain;
output                              data_sop;
output                              data_eop;
output  [CORE_DATA_WIDTH-1:0]       data_data;
output  [USER_STATUS_WIDTH-1:0]     data_user_status;

input   [USER_STATUS_WIDTH-1:0]     user_status;
input                               sop;
input                               eop;
input   [CORE_DATA_WIDTH-1:0]       data;
input   [CORE_REMAIN_WIDTH-1:0]     valid;
input                               src_rdy;
output                              dst_rdy;
output                              abort;
input                               abort_ack;
output                              user_rst_n;

output                              apkt_req;
input                               apkt_ready;
output  [63:0]                      apkt_addr;
output  [31:0]                      apkt_bcount;
output                              apkt_eop;


// ----------------
// -- Port Types --
// ----------------

wire                                rst_n;
wire                                clk;

wire                                cmd_req;
wire                                cmd_ready;
wire                                cmd_first_chain;
wire                                cmd_last_chain;
wire    [31:0]                      cmd_bcount;
wire    [63:0]                      cmd_addr;
wire    [63:0]                      cmd_user_control;
wire                                cmd_abort;
reg                                 cmd_abort_ack;

wire                                data_req;
reg                                 data_ready;
wire    [CORE_REMAIN_WIDTH-1:0]     data_req_remain;
wire                                data_req_last_desc;
wire    [63:0]                      data_addr;
wire    [9:0]                       data_bcount;
reg                                 data_stop;
reg     [9:0]                       data_stop_bcount;

wire                                data_en;
wire    [CORE_REMAIN_WIDTH-1:0]     data_remain;
wire    [CORE_REMAIN_WIDTH:0]       data_valid;
wire                                data_first_req;
wire                                data_last_req;
wire                                data_first_desc;
wire                                data_last_desc;
wire                                data_first_chain;
wire                                data_last_chain;
reg                                 data_sop;
reg                                 data_eop;
reg     [CORE_DATA_WIDTH-1:0]       data_data;
reg     [USER_STATUS_WIDTH-1:0]     data_user_status;

wire    [USER_STATUS_WIDTH-1:0]     user_status;
wire                                sop;
wire                                eop;
wire    [CORE_DATA_WIDTH-1:0]       data;
wire    [CORE_REMAIN_WIDTH-1:0]     valid;
wire                                src_rdy;
reg                                 dst_rdy;
reg                                 abort;
wire                                abort_ack;
wire                                user_rst_n;

reg                                 apkt_req;
wire                                apkt_ready;
reg     [63:0]                      apkt_addr;
reg     [31:0]                      apkt_bcount;
reg                                 apkt_eop;


// -------------------
// -- Local Signals --
// -------------------

// Pipeline Reset
reg                                             r5_dma_rst_n;
reg                                             r6_dma_rst_n;
reg                                             r7_dma_rst_n;
reg                                             r8_dma_rst_n;

// Handle Aborts
wire                                            c_u_flush;

reg                                             d_flush;

reg                                             reset_timer1;
reg     [TIMER1_WIDTH-1:0]                      timer1;
reg                                             timer1_tc;

reg                                             reset_timer2;
reg     [TIMER2_WIDTH-1:0]                      timer2;
reg                                             timer2_tc;

reg                                             reset_timer3;
reg     [TIMER3_WIDTH-1:0]                      timer3;
reg                                             timer3_tc;

reg     [TIMER3_WIDTH-2:0]                      int_rst_ctr;
reg                                             d_int_rst_n;

(* equivalent_register_removal = "no" *)
reg                                             int0_rst_n;
(* equivalent_register_removal = "no" *)
reg                                             int1_rst_n;
(* equivalent_register_removal = "no" *)
reg                                             int2_rst_n;
(* equivalent_register_removal = "no" *)
reg                                             int3_rst_n;
(* equivalent_register_removal = "no" *)
reg                                             int4_rst_n;
(* equivalent_register_removal = "no" *)
reg                                             int5_rst_n;

reg     [4:0]                                   abort_state;

reg                                             in_pkt;

wire                                            int_src_rdy;
wire                                            int_eop;
wire                                            int_sop;

// Instantiate RAM for FIFO
wire    [FIFO_DATA_WIDTH-1:0]                   rd_data;

// Write side of FIFO
wire                                            wr_en;
wire                                            wr_en_eop;
wire    [FIFO_DATA_WIDTH-1:0]                   wr_data;
wire                                            all_valid;
wire    [CORE_REMAIN_WIDTH:0]                   wr_valid;

reg     [FIFO_ADDR_WIDTH-1:0]                   wr_addr;

reg     [FIFO_ADDR_WIDTH:0]                     wr_level;
reg                                             c_wr_full;

reg     [1:0]                                   wr_eop_req_level;
reg                                             c_wr_eop_req_full;

reg     [1:0]                                   wr_eop_level;
reg                                             c_wr_eop_full;

reg                                             int_dst_rdy;

// Read side of FIFO
wire    [FIFO_ADDR_WIDTH-1:0]                   c_rd_addr;
wire    [FIFO_ADDR_WIDTH-1:0]                   c_rd_addr_plus1;
reg     [FIFO_ADDR_WIDTH-1:0]                   rd_addr;
reg     [FIFO_ADDR_WIDTH-1:0]                   rd_addr_plus1;

reg                                             r_data_en;

reg                                             r_wr_en;
reg                                             r_wr_en_eop;
reg     [CORE_REMAIN_WIDTH:0]                   r_wr_valid;

reg     [1:0]                                   rd_primary_eop_seen_ctr;
reg     [FIFO_ADDR_WIDTH+CORE_REMAIN_WIDTH:0]   rd_primary_level;
reg     [FIFO_ADDR_WIDTH+CORE_REMAIN_WIDTH:0]   rd_backup_level;
reg     [FIFO_ADDR_WIDTH:0]                     rd_level;
reg                                             rd_empty;

reg                                             rd_primary_eop_seen;
reg                                             rd_level_has_bcount;
reg                                             rd_level_eq_bcount;
reg                                             rd_level_eq0;
reg     [9:0]                                   rd_primary_stop_level;
reg                                             rd_req_last_desc;

// Respond to DMA Engine Data Requests
reg     [2:0]                                   state;

reg                                             final_pkt_req;
reg     [9:0]                                   r_data_bcount;
reg     [9:0]                                   rd_adv_inc;

wire    [FIFO_ADDR_WIDTH+CORE_REMAIN_WIDTH:0]   sized_rd_adv_inc;

wire                                            rd_sop;
wire                                            rd_eop;
wire    [CORE_REMAIN_WIDTH:0]                   rd_val;
wire    [USER_STATUS_WIDTH-1:0]                 rd_ust;
wire    [CORE_DATA_WIDTH-1:0]                   rd_dat;

`ifdef PACKET_DMA_BYTE_SUPPORT
// RAM Output Stage
wire                                            rd_en;
reg                                             rd_en_eop;

reg                                             out_empty;
reg                                             out_sop;
reg                                             out_eop;
reg    [CORE_REMAIN_WIDTH:0]                    out_val;
reg    [USER_STATUS_WIDTH-1:0]                  out_ust;
reg    [CORE_DATA_WIDTH-1:0]                    out_dat;

// Handle sub-CORE_DATA_WIDTH misalignments
wire                                            need_data;
wire                                            out_en;

wire    [CORE_REMAIN_WIDTH:0]                   c_next_sav_bcnt_out_en;
wire    [CORE_REMAIN_WIDTH:0]                   c_next_sav_bcnt_out_en_n;
wire    [CORE_REMAIN_WIDTH:0]                   c_next_sav_bcnt;

wire                                            c_data_eop;

reg     [CORE_REMAIN_WIDTH-1:0]                 sav_bcnt;
reg     [CORE_REMAIN_WIDTH-1:0]                 sav_bcnt_mux;

reg                                             hold_out_eop;
reg     [CORE_DATA_WIDTH-9:0]                   out_sav;

reg     [(CORE_DATA_WIDTH*2)-9:0]               c_data_data;
`else
// RAM Output Stage
wire                                            rd_en;
reg                                             rd_en_eop;
`endif

// Addressed Pcket Interface
wire                                apkt_wr_en;
wire    [3:0]                       apkt_wr_level;
wire    [96:0]                      apkt_wr_data;
wire                                apkt_full;
wire                                apkt_rd_en;
wire    [96:0]                      apkt_rd_data;
wire    [3:0]                       apkt_rd_level;
wire                                apkt_empty;


// ---------------
// -- Equations --
// ---------------

assign  apkt_wr_data = {cmd_last_chain, cmd_bcount, cmd_addr};

assign  cmd_ready   = ~apkt_full;
assign  apkt_wr_en  = cmd_req & cmd_ready;
assign  apkt_rd_en  = (apkt_ready | ~apkt_req) & ~apkt_empty;

ref_sc_fifo_shallow_ram #(
    .DATA_WIDTH     (97             ),
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
        apkt_bcount <= 32'h0;
        apkt_eop    <= 1'b0;
        apkt_req    <= 1'b0;
    end
    else begin
        if (apkt_rd_en) begin
            apkt_addr   <= apkt_rd_data[63:0];
            apkt_bcount <= apkt_rd_data[95:64];
            apkt_eop    <= apkt_rd_data[96];
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

// When in this state, continue to flush user data if necessary
assign c_u_flush = (abort_state == ABORT_WAIT);

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
        int4_rst_n    <= 1'b0;
        int5_rst_n    <= 1'b0;
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
        reset_timer1 <= data_en | (src_rdy & int_dst_rdy) | (abort_state != ABORT_DATA);

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
        reset_timer2 <= data_en | (src_rdy & int_dst_rdy) | // Data Transfer
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
        int4_rst_n <= d_int_rst_n;
        int5_rst_n <= d_int_rst_n;
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

// Keep track of when the user interface is busy receiving a packet
always @(posedge clk or negedge int0_rst_n)
begin
    if (int0_rst_n == 1'b0)
    begin
        in_pkt <= 1'b0;
    end
    else
    begin
        if (int_sop & ~int_eop & int_src_rdy & int_dst_rdy)
            in_pkt <= 1'b1;
        else if (int_eop & int_src_rdy & int_dst_rdy)
            in_pkt <= 1'b0;
    end
end

// Force user-provided src_rdy, eop, and sop signals active (for use inside this module)
//   when flushing outstanding DMA operations due to an abort request
assign int_src_rdy = d_flush | src_rdy;
assign int_eop     = d_flush ? 1'b1    : eop; // Force eop active when flushing
assign int_sop     = d_flush ? ~in_pkt : sop; // Force sop active when flushing unless already in a packet from before



// ------------------------
// Instantiate RAM for FIFO

// Read enable is always asserted, so the rd_data output depends exclusively on rd_addr
ref_inferred_block_ram #(

    .ADDR_WIDTH (FIFO_ADDR_WIDTH    ),
    .DATA_WIDTH (FIFO_DATA_WIDTH    )

) fifo_ram (

    .wr_clk     (clk                ),
    .wr_addr    (wr_addr            ),
    .wr_en      (wr_en              ),
    .wr_data    (wr_data            ),

    .rd_clk     (clk                ),
    .rd_addr    (c_rd_addr          ),
    .rd_data    (rd_data            )

);



// ------------------
// Write side of FIFO

assign wr_en     = int_src_rdy & int_dst_rdy;
assign wr_en_eop = int_src_rdy & int_dst_rdy & int_eop;
assign wr_data   = {int_sop, int_eop, wr_valid, user_status, data};

assign all_valid = (valid == {CORE_REMAIN_WIDTH{1'b0}});
assign wr_valid  = {all_valid, valid};

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

always @(posedge clk or negedge int0_rst_n)
begin
    if (int0_rst_n == 1'b0)
        wr_level <= {(FIFO_ADDR_WIDTH+1){1'b0}};
    else
    begin
        case ({wr_en, rd_en})
            2'b01   : wr_level <= wr_level - {{FIFO_ADDR_WIDTH{1'b0}}, 1'b1};
            2'b10   : wr_level <= wr_level + {{FIFO_ADDR_WIDTH{1'b0}}, 1'b1};
            default : wr_level <= wr_level;
        endcase
    end
end

always @*
begin
    case ({wr_en, rd_en})
        2'b01   : c_wr_full = 1'b0;
        2'b10   : c_wr_full = (wr_level == (FIFO_NUM_WORDS - 1));
        default : c_wr_full = (wr_level == FIFO_NUM_WORDS);
    endcase
end

// This module can hold packet data from up to two different packets;
//   track # of packets that have some data in the FIFO using data strobes
always @(posedge clk or negedge int0_rst_n)
begin
    if (int0_rst_n == 1'b0)
        wr_eop_level <= 2'h0;
    else
    begin
        case ({wr_en_eop, rd_en_eop})
            2'b01   : wr_eop_level <= wr_eop_level - 2'h1;
            2'b10   : wr_eop_level <= wr_eop_level + 2'h1;
            default : wr_eop_level <= wr_eop_level;
        endcase
    end
end

always @*
begin
    case ({wr_en_eop, rd_en_eop})
        2'b01   : c_wr_eop_full = 1'b0;
        2'b10   : c_wr_eop_full = (wr_eop_level == 2'h1);
        default : c_wr_eop_full = (wr_eop_level == 2'h2);
    endcase
end

// This module can hold packet data from up to two different packets;
//   track # of packets that have some data in the FIFO using data requests;
//   need to cover case where a packet ends exactly on a request boundary
//   and thus all data could transfer (and assert rd_en_eop) before the request
//   portion of packet ends; the request portion of the packet ends on the next
//   data_req that is stopped with data_stop and data_stop_bcount == 0
always @(posedge clk or negedge int0_rst_n)
begin
    if (int0_rst_n == 1'b0)
        wr_eop_req_level <= 2'h0;
    else
    begin
        case ({wr_en_eop, final_pkt_req})
            2'b01   : wr_eop_req_level <= wr_eop_req_level - 2'h1;
            2'b10   : wr_eop_req_level <= wr_eop_req_level + 2'h1;
            default : wr_eop_req_level <= wr_eop_req_level;
        endcase
    end
end

always @*
begin
    case ({wr_en_eop, final_pkt_req})
        2'b01   : c_wr_eop_req_full = 1'b0;
        2'b10   : c_wr_eop_req_full = (wr_eop_req_level == 2'h1);
        default : c_wr_eop_req_full = (wr_eop_req_level == 2'h2);
    endcase
end

always @(posedge clk or negedge int0_rst_n)
begin
    if (int0_rst_n == 1'b0)
    begin
        int_dst_rdy <= 1'b0;
        dst_rdy     <= 1'b0;
    end
    else
    begin
        // int_dst_rdy is asserted when the FIFO can accept packet data;
        //   this is the ready used in this module
        int_dst_rdy <= (~c_wr_full & ~c_wr_eop_full & ~c_wr_eop_req_full);

        // dst_rdy is asserted when the FIFO can accept packet data;
        //   when an abort condition has occurred; dst_rdy is forced
        //   high by c_u_flush to allow user data to be consumed;
        //   this is the ready output from this module for user use
        dst_rdy     <= (~c_wr_full & ~c_wr_eop_full & ~c_wr_eop_req_full) | c_u_flush;
    end
end



// -------------------
//  Read side of FIFO

// Use look-ahead address for RAM to reduce FIFO read data latency
assign c_rd_addr       = rd_en ? rd_addr_plus1 : rd_addr;
assign c_rd_addr_plus1 = rd_en ? (rd_addr_plus1 + {{(FIFO_ADDR_WIDTH-1){1'b0}}, 1'b1}) : rd_addr_plus1;

always @(posedge clk or negedge int1_rst_n)
begin
    if (int1_rst_n == 1'b0)
    begin
        rd_addr       <= {FIFO_ADDR_WIDTH{1'b0}};
        rd_addr_plus1 <= {{(FIFO_ADDR_WIDTH-1){1'b0}}, 1'b1};
    end
    else
    begin
        rd_addr       <= c_rd_addr;
        rd_addr_plus1 <= c_rd_addr_plus1;
    end
end

always @(posedge clk or negedge int1_rst_n)
begin
    if (int1_rst_n == 1'b0)
    begin
        r_data_en               <= 1'b0;

        r_wr_en                 <= 1'b0;
        r_wr_en_eop             <= 1'b0;
        r_wr_valid              <= {(CORE_REMAIN_WIDTH+1){1'b0}};

        rd_primary_eop_seen_ctr <= 2'h0;

        rd_primary_level        <= {(FIFO_ADDR_WIDTH+CORE_REMAIN_WIDTH+1){1'b0}};
        rd_backup_level         <= {(FIFO_ADDR_WIDTH+CORE_REMAIN_WIDTH+1){1'b0}};

        rd_level                <= {(FIFO_ADDR_WIDTH+1){1'b0}};
        rd_empty                <= 1'b1;
    end
    else
    begin
        // Delay to same timing as rd_dat, rd_sop, rd_eop coming from FIFO read port
        r_data_en   <= data_en;

        // Delay wr_en for read level computations until data can be read from the latency 1 RAM
        r_wr_en     <= wr_en;
        r_wr_en_eop <= wr_en_eop;

        // Timing optimization: make r_wr_valid == 0 when r_wr_en would be 0 so
        //   it is not necessary to generate and use r_wr_en
        if (wr_en)
            r_wr_valid <= wr_valid;
        else
            r_wr_valid <= {(CORE_REMAIN_WIDTH+1){1'b0}};

        // This signal tells consumption logic that no more data is expected for
        //   the current packet, so any requests that arrive exceeding rd_primary_level
        //   should be terminated short; this signal must be set with the same timing
        //   as the increasing of rd_primary_level and rd_backup_level
        case ({r_wr_en_eop, final_pkt_req})
            2'b10   : rd_primary_eop_seen_ctr <= rd_primary_eop_seen_ctr + 2'h1;
            2'b01   : rd_primary_eop_seen_ctr <= rd_primary_eop_seen_ctr - 2'h1;
            default : rd_primary_eop_seen_ctr <= rd_primary_eop_seen_ctr;
        endcase

        // Timing optimization: sized_rd_adv_inc already is 0 when rd_adv_en is 0
        //                      r_wr_valid       already is 0 when r_wr_en is 0
        if (final_pkt_req) // After a packet's last request is granted, switch to rd_backup_level
            rd_primary_level <= (rd_backup_level - sized_rd_adv_inc) + {{FIFO_ADDR_WIDTH{1'b0}}, r_wr_valid};
        else
        begin
            if (rd_primary_eop_seen_ctr == 2'h0) // Don't continue to add to primary level once a full packet is present
                rd_primary_level <= (rd_primary_level - sized_rd_adv_inc) + {{FIFO_ADDR_WIDTH{1'b0}}, r_wr_valid};
            else
                rd_primary_level <= (rd_primary_level - sized_rd_adv_inc);
        end

        // Timing optimization: sized_rd_adv_inc already is 0 when rd_adv_en is 0
        //                      r_wr_valid       already is 0 when r_wr_en is 0
        rd_backup_level <= (rd_backup_level - sized_rd_adv_inc) + {{FIFO_ADDR_WIDTH{1'b0}}, r_wr_valid};

        // Keep level for data output
        case ({r_wr_en, rd_en})
            2'b10   : rd_level <= rd_level + {{FIFO_ADDR_WIDTH{1'b0}}, 1'b1};
            2'b01   : rd_level <= rd_level - {{FIFO_ADDR_WIDTH{1'b0}}, 1'b1};
            default : rd_level <= rd_level;
        endcase

        case ({r_wr_en, rd_en})
            2'b10   : rd_empty <= 1'b0;
            2'b01   : rd_empty <= (rd_level == {{FIFO_ADDR_WIDTH{1'b0}}, 1'b1});
            default : rd_empty <= (rd_level == {(FIFO_ADDR_WIDTH+1){1'b0}});
        endcase
    end
end

// These signals must have the same timing as they are checked at the
//   same time to determine whether we need to assert data_ready or data_stop
//   and whether this is the last request for the packet.
always @(posedge clk or negedge int1_rst_n)
begin
    if (int1_rst_n == 1'b0)
    begin
        rd_primary_eop_seen   <= 1'b0;
        rd_level_has_bcount   <= 1'b0;
        rd_level_eq_bcount    <= 1'b0;
        rd_level_eq0          <= 1'b0;
        rd_primary_stop_level <= 10'h0;
        rd_req_last_desc      <= 1'b0;
    end
    else
    begin
        rd_primary_eop_seen   <= (rd_primary_eop_seen_ctr != 2'h0);
        rd_level_has_bcount   <= (rd_primary_level >= {{((FIFO_ADDR_WIDTH+CORE_REMAIN_WIDTH)-9){1'b0}}, data_bcount});
        rd_level_eq_bcount    <= (rd_primary_level == {{((FIFO_ADDR_WIDTH+CORE_REMAIN_WIDTH)-9){1'b0}}, data_bcount});
        rd_level_eq0          <= (rd_primary_level == {(FIFO_ADDR_WIDTH+CORE_REMAIN_WIDTH+1){1'b0}});
        rd_primary_stop_level <= rd_primary_level[9:0];
        rd_req_last_desc      <= data_req_last_desc;
    end
end



// -----------------------------------
// Respond to DMA Engine Data Requests

// Note 3 clocks are used to respond to data requests to
//   improve route speed; the delay in asserting data_ready or
//   data_stop should not affect throughput for typical size
//   max-payload size packets
always @(posedge clk or negedge int2_rst_n)
begin
    if (int2_rst_n == 1'b0)
    begin
        state <= DATA_IDLE;
    end
    else
    begin
        case (state)

            // Compute data_count from data_bcount
            DATA_IDLE :
                if (data_req)
                    state <= DATA_CHCK;

            // Check if FIFO has the required data
            DATA_CHCK :
                if (rd_level_has_bcount | rd_primary_eop_seen)
                    state <= DATA_RESP;

            // Assert data_ready or data_stop
            DATA_RESP :
                state <= DATA_IDLE;

            default :
                state <= DATA_IDLE;

        endcase
    end
end

always @(posedge clk or negedge int2_rst_n)
begin
    if (int2_rst_n == 1'b0)
    begin
        data_ready       <= 1'b0;
        data_stop        <= 1'b0;
        data_stop_bcount <= 10'h0;

        final_pkt_req    <= 1'b0;

        r_data_bcount    <= 10'h0;

        rd_adv_inc       <= 10'h0;
    end
    else
    begin
        // Assert data_ready if we have the requested data or
        //   data_stop and data_stop_bcount == current FIFO level in bytes if we don't have the data and eof occurred
        data_ready    <= (state == DATA_CHCK) &  rd_level_has_bcount;
        data_stop     <= (state == DATA_CHCK) & ~rd_level_has_bcount & rd_primary_eop_seen;

        if ((state == DATA_CHCK) & ~rd_level_has_bcount & rd_primary_eop_seen)
            data_stop_bcount <= rd_primary_stop_level;
        else
            data_stop_bcount <= 10'h0;

        // Precompute condition where we will assert data_ready or data_stop to finish the current packet
        final_pkt_req <= ((state == DATA_CHCK) &  rd_level_eq_bcount  & rd_primary_eop_seen & rd_req_last_desc) | // data_ready finish and DMA Engine knows its the last request in the Descriptor
                         ((state == DATA_CHCK) & ~rd_level_has_bcount & rd_primary_eop_seen & rd_level_eq0    );  // data_stop with no additional data finish

        // Delay data_bcount to same timing as DATA_CHCK & rd_level_has_bcount
        r_data_bcount <= data_bcount;

        // Increment by the amount of data taken from the FIFO; zero when rd_adv_en == ((state == DATA_CHCK) & rd_level_has_bcount) == 0
        rd_adv_inc <= ((state == DATA_CHCK) & rd_level_has_bcount) ? r_data_bcount : 10'h0;
    end
end

assign sized_rd_adv_inc = {{((FIFO_ADDR_WIDTH+CORE_REMAIN_WIDTH)-9){1'b0}}, rd_adv_inc};

assign rd_sop = rd_data[(CORE_DATA_WIDTH+USER_STATUS_WIDTH+CORE_REMAIN_WIDTH)+2                                  ];
assign rd_eop = rd_data[(CORE_DATA_WIDTH+USER_STATUS_WIDTH+CORE_REMAIN_WIDTH)+1                                  ];
assign rd_val = rd_data[(CORE_DATA_WIDTH+USER_STATUS_WIDTH+CORE_REMAIN_WIDTH)  :CORE_DATA_WIDTH+USER_STATUS_WIDTH];
assign rd_ust = rd_data[(CORE_DATA_WIDTH+USER_STATUS_WIDTH)-1                  :CORE_DATA_WIDTH                  ];
assign rd_dat = rd_data[ CORE_DATA_WIDTH                   -1                  :0                                ];



`ifdef PACKET_DMA_BYTE_SUPPORT
// ----------------
// RAM Output Stage

// Data is read out of FIFO into holding register to improve timing
assign rd_en = ~rd_empty & (out_en | out_empty);

// Assert at end of packet to free control space to
//   track a new packet in the FIFO
always @(posedge clk or negedge int3_rst_n)
begin
    if (int3_rst_n == 1'b0)
        rd_en_eop <= 1'b0;
    else
        // Don't free packet until the final byte in the packet has
        //   been comitted for transfer on PCI Express
        rd_en_eop <= r_data_en & data_eop;
end

always @(posedge clk or negedge int3_rst_n)
begin
    if (int3_rst_n == 1'b0)
    begin
        out_empty <= 1'b1;
        out_sop   <= 1'b0;
        out_eop   <= 1'b0;
        out_val   <= {(CORE_REMAIN_WIDTH+1){1'b0}};
        out_ust   <= {USER_STATUS_WIDTH{1'b0}};
        out_dat   <= {CORE_DATA_WIDTH{1'b0}};
    end
    else
    begin
        if (rd_en)
        begin
            out_empty <= 1'b0;
            out_sop   <= rd_sop;
            out_eop   <= rd_eop;
        end
        else if (out_en)
        begin
            out_empty <= 1'b1;
            out_sop   <= 1'b0;
            out_eop   <= 1'b0;
        end

        if (rd_en)
        begin
            out_val <= rd_val;
            out_ust <= rd_ust;
            out_dat <= rd_dat;
        end
    end
end



// ----------------------------------------
// Handle sub-CORE_DATA_WIDTH misalignments

assign need_data = (data_valid > {1'b0, sav_bcnt}); // Check if we need more data to satisfy the request
assign out_en    = data_en & need_data;

// Compute next sav_bcnt both with and without out_en asserting
assign c_next_sav_bcnt_out_en   = ({1'b0, sav_bcnt} + out_val) - data_valid; // With read
assign c_next_sav_bcnt_out_en_n =  {1'b0, sav_bcnt}            - data_valid; // Without read
assign c_next_sav_bcnt          = need_data ? c_next_sav_bcnt_out_en : c_next_sav_bcnt_out_en_n;

assign c_data_eop = (data_en &  need_data & out_eop      & (c_next_sav_bcnt_out_en   == {(CORE_REMAIN_WIDTH+1){1'b0}})) | // Read from FIFO this clock and all data transferred the same clock
                    (data_en & ~need_data & hold_out_eop & (c_next_sav_bcnt_out_en_n == {(CORE_REMAIN_WIDTH+1){1'b0}}));  // EOP was read and not transferred before and now is transferring final data byte

always @(posedge clk or negedge int4_rst_n)
begin
    if (int4_rst_n == 1'b0)
    begin
        sav_bcnt         <= {CORE_REMAIN_WIDTH{1'b0}};
        sav_bcnt_mux     <= {CORE_REMAIN_WIDTH{1'b0}};

        data_sop         <= 1'b0;
        data_eop         <= 1'b0;
        data_data        <= {CORE_DATA_WIDTH{1'b0}};

        data_user_status <= {USER_STATUS_WIDTH{1'b0}};
        hold_out_eop     <= 1'b0;

        out_sav          <= {(CORE_DATA_WIDTH-8){1'b0}};
    end
    else
    begin
        if (data_en)
        begin
            if (c_data_eop) // Zero when outputting eop since data is not saved accross packet boundaries
                sav_bcnt <= {CORE_REMAIN_WIDTH{1'b0}};
            else
                sav_bcnt <= c_next_sav_bcnt[CORE_REMAIN_WIDTH-1:0];
        end

        // Identical copy for fanout reduction
        if (data_en)
        begin
            if (c_data_eop) // Zero when outputting eop since data is not saved accross packet boundaries
                sav_bcnt_mux <= {CORE_REMAIN_WIDTH{1'b0}};
            else
                sav_bcnt_mux <= c_next_sav_bcnt[CORE_REMAIN_WIDTH-1:0];
        end

        data_sop  <= out_sop & out_en;   // Output when transferring the first byte of a packet
        data_eop  <= c_data_eop;         // Output when transferring the last byte of a packet
        data_data <= c_data_data[CORE_DATA_WIDTH-1:0];

        // Assert when reading eop from FIFO and Hold through transfer of data_eop
        if (out_en & out_eop)
            data_user_status <= out_ust;
        else if (r_data_en & data_eop)
            data_user_status <= {USER_STATUS_WIDTH{1'b0}};

        // Need to hold eop condition until the last byte of data in the packet transfers
        if (data_en & need_data & out_eop & (c_next_sav_bcnt_out_en != {(CORE_REMAIN_WIDTH+1){1'b0}}))
            hold_out_eop <= 1'b1;
        else if (r_data_en & data_eop)
            hold_out_eop <= 1'b0;

        // Save the CORE_DATA_WIDTH-8 bytes above the data that transfered
        //   since this data may need to be pre-pended to future data
        if (data_en)
        begin
            case (data_remain[2:0])
                3'h0 : out_sav <= c_data_data[119:64];
                3'h1 : out_sav <= c_data_data[111:56];
                3'h2 : out_sav <= c_data_data[103:48];
                3'h3 : out_sav <= c_data_data[ 95:40];
                3'h4 : out_sav <= c_data_data[ 87:32];
                3'h5 : out_sav <= c_data_data[ 79:24];
                3'h6 : out_sav <= c_data_data[ 71:16];
                3'h7 : out_sav <= c_data_data[ 63: 8];
            endcase
        end
    end
end

// Aggregate saved data and new data according to how much data was saved
always @*
begin
    case (sav_bcnt_mux[2:0])
        3'h0 : c_data_data = { 56'h0, out_dat[63:0]              };
        3'h1 : c_data_data = { 48'h0, out_dat[63:0], out_sav[ 7:0]};
        3'h2 : c_data_data = { 40'h0, out_dat[63:0], out_sav[15:0]};
        3'h3 : c_data_data = { 32'h0, out_dat[63:0], out_sav[23:0]};
        3'h4 : c_data_data = { 24'h0, out_dat[63:0], out_sav[31:0]};
        3'h5 : c_data_data = { 16'h0, out_dat[63:0], out_sav[39:0]};
        3'h6 : c_data_data = {  8'h0, out_dat[63:0], out_sav[47:0]};
        3'h7 : c_data_data = {        out_dat[63:0], out_sav[55:0]};
    endcase
end
`else
// ----------------
// RAM Output Stage

// Data request data transfers
assign rd_en = data_en;

always @(posedge clk or negedge int3_rst_n)
begin
    if (int3_rst_n == 1'b0)
        rd_en_eop <= 1'b0;
    else
        rd_en_eop <= r_data_en & data_eop;
end

always @(posedge clk or negedge int4_rst_n)
begin
    if (int4_rst_n == 1'b0)
    begin
        data_sop         <= 1'b0;
        data_eop         <= 1'b0;
        data_user_status <= 64'h0;
        data_data        <= {CORE_DATA_WIDTH{1'b0}};
    end
    else
    begin
        data_sop         <= rd_sop;
        data_eop         <= rd_eop;
        data_user_status <= rd_ust;
        data_data        <= rd_dat;
    end
end
`endif



endmodule
