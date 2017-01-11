//  ------------------------- CONFIDENTIAL ----------------------------------
//
//                 (c) Copyright 2010 by Northwest Logic, Inc.
//
//  All rights reserved.  No part of this source code may be reproduced or
//  transmitted in any form or by any means, electronic or mechanical,
//  including photocopying, recording, or any information storage and
//  retrieval system, without permission in writing from Northest Logic, Inc.
//
//  Further, no use of this source code is permitted in any form or means
//  without a valid, written license agreement with Northwest Logic, Inc.
//
// $Date: 2010-09-21 09:22:50 -0700 (Tue, 21 Sep 2010) $
// $Revision: 14353 $
//
//                         Northwest Logic, Inc.
//                  1100 NW Compton Drive, Suite 100
//                      Beaverton, OR 97006, USA
//
//                       Ph.  +1 503 533 5800
//                       Fax. +1 503 533 5900
//                          www.nwlogic.com
//
//  -------------------------------------------------------------------------

`timescale 1ps / 1ps



// -----------------------
// -- Module Definition --
// -----------------------

module ref_inferred_block_ram (

    wr_clk,
    wr_addr,
    wr_en,
    wr_data,

    rd_clk,
    rd_addr,
    rd_data

);



// ----------------
// -- Parameters --
// ----------------

parameter   ADDR_WIDTH          = 9;                // Set to desired number of address bits
parameter   DATA_WIDTH          = 8;                // Set to desired number of data bits
parameter   FAST_READ           = 0;                // If 1, allows simultaneous read and write
localparam RAMB36_WIDTH = (ADDR_WIDTH == 15) ?  1 :
                          (ADDR_WIDTH == 14) ?  2 :
                          (ADDR_WIDTH == 13) ?  4 :
                          (ADDR_WIDTH == 12) ?  9 :
                          (ADDR_WIDTH == 11) ? 18 :
                                               36 ;

localparam DATA_INC     = (ADDR_WIDTH == 15) ?  1 :
                          (ADDR_WIDTH == 14) ?  2 :
                          (ADDR_WIDTH == 13) ?  4 :
                          (ADDR_WIDTH == 12) ?  8 :
                          (ADDR_WIDTH == 11) ? 16 :
                                               32 ;



// -----------------------
// -- Port Declarations --
// -----------------------

input                           wr_clk;
input   [ADDR_WIDTH-1:0]        wr_addr;
input                           wr_en;
input   [DATA_WIDTH-1:0]        wr_data;

input                           rd_clk;
input   [ADDR_WIDTH-1:0]        rd_addr;
output  [DATA_WIDTH-1:0]        rd_data;



// ----------------
// -- Port Types --
// ----------------

wire                            wr_clk;
wire    [ADDR_WIDTH-1:0]        wr_addr;
wire                            wr_en;
wire    [DATA_WIDTH-1:0]        wr_data;

wire                            rd_clk;
wire    [ADDR_WIDTH-1:0]        rd_addr;
wire    [DATA_WIDTH-1:0]        rd_data;



// ---------------------
// -- Local Variables --
// ---------------------

wire    [511:0]                 wr_data_i;
wire    [511:0]                 rd_data_0;
wire    [15:0]                  wr_addr_i;
wire    [15:0]                  rd_addr_i;

localparam [511:0] ZEROS = 512'h0;

// ---------------
// -- Equations --
// ---------------

assign wr_data_i[511:DATA_WIDTH] = ZEROS[511:DATA_WIDTH];
assign wr_data_i[DATA_WIDTH-1:0] = wr_data;

genvar j;
generate
    if (ADDR_WIDTH <= 10 && DATA_WIDTH <= 18)
    begin
        // address MSB is on bit 13 and goes down from there.
        assign wr_addr_i[15:14] = 2'b00;
        assign rd_addr_i[15:14] = 2'b00;

        assign wr_addr_i[13:0] = {wr_addr, ZEROS[13-ADDR_WIDTH:0]};
        assign rd_addr_i[13:0] = {rd_addr, ZEROS[13-ADDR_WIDTH:0]};

        RAMB18 # (
            .READ_WIDTH_A           (18),
            .READ_WIDTH_B           (18),
            .WRITE_WIDTH_A          (18),
            .WRITE_WIDTH_B          (18),
            .WRITE_MODE_A           ("WRITE_FIRST"),
            .WRITE_MODE_B           ("WRITE_FIRST"),
            .SIM_COLLISION_CHECK    ("NONE"),
            .SIM_MODE               ("FAST")
        ) ramb18_0 (
            .DOA        (                   ),
            .DOB        (rd_data_0[15:0]    ),
            .DOPA       (                   ),
            .DOPB       (rd_data_0[17:16]   ),
            .ADDRA      (wr_addr_i[13:0]    ),
            .ADDRB      (rd_addr_i[13:0]    ),
            .CLKA       (wr_clk             ),
            .CLKB       (rd_clk             ),
            .DIA        (wr_data_i[15:0]    ),
            .DIB        (16'h0              ),
            .DIPA       (wr_data_i[17:16]   ),
            .DIPB       (2'b00              ),
            .ENA        (1'b1               ),
            .ENB        (1'b1               ),
            .REGCEA     (1'b1               ),
            .REGCEB     (1'b1               ),
            .SSRA       (1'b0               ),
            .SSRB       (1'b0               ),
            .WEA        ({2{wr_en}}         ),
            .WEB        (2'b00              )
        );

        assign rd_data = rd_data_0[DATA_WIDTH-1:0];
    end

    else if (ADDR_WIDTH <= 14)
    begin
        // address MSB is on bit 14 and goes down from there.
        assign wr_addr_i[15] = 1'b0;
        assign rd_addr_i[15] = 1'b0;

        assign wr_addr_i[14:0] = {wr_addr, ZEROS[14-ADDR_WIDTH:0]};
        assign rd_addr_i[14:0] = {rd_addr, ZEROS[14-ADDR_WIDTH:0]};

        for (j = 0; j < DATA_WIDTH; j = j + DATA_INC)
        begin : addr_10_14

            wire [31:0]     rd_data_int;
            wire [32:0]             wr_data_int;

            assign wr_data_int = {ZEROS[32:DATA_INC], wr_data_i[j+DATA_INC-1:j]};

            RAMB36 # (
                .READ_WIDTH_A           (RAMB36_WIDTH),
                .READ_WIDTH_B           (RAMB36_WIDTH),
                .WRITE_WIDTH_A          (RAMB36_WIDTH),
                .WRITE_WIDTH_B          (RAMB36_WIDTH),
                .WRITE_MODE_A           ("WRITE_FIRST"),
                .WRITE_MODE_B           ("WRITE_FIRST"),
                .SIM_COLLISION_CHECK    ("NONE" ),
                .SIM_MODE               ("FAST" )
            ) ramb36 (
                .CASCADEOUTLATA         (                               ),
                .CASCADEOUTLATB         (                               ),
                .CASCADEOUTREGA         (                               ),
                .CASCADEOUTREGB         (                               ),
                .DOA                    (                               ),
                .DOB                    (rd_data_int                    ),
                .DOPA                   (                               ),
                .DOPB                   (                               ),
                .ADDRA                  (wr_addr_i                      ),
                .ADDRB                  (rd_addr_i                      ),
                .CASCADEINLATA          (1'b0                           ),
                .CASCADEINLATB          (1'b0                           ),
                .CASCADEINREGA          (1'b0                           ),
                .CASCADEINREGB          (1'b0                           ),
                .CLKA                   (wr_clk                         ),
                .CLKB                   (rd_clk                         ),
                .DIA                    (wr_data_int[31:0]              ),
                .DIB                    (32'h0                          ),
                .DIPA                   (4'h0                           ),
                .DIPB                   (4'h0                           ),
                .ENA                    (1'b1                           ),
                .ENB                    (1'b1                           ),
                .REGCEA                 (1'b1                           ),
                .REGCEB                 (1'b1                           ),
                .SSRA                   (1'b0                           ),
                .SSRB                   (1'b0                           ),
                .WEA                    ({4{wr_en}}                     ),
                .WEB                    (4'h0                           )
            );

            assign rd_data_0[j+DATA_INC-1 : j] = rd_data_int[DATA_INC-1:0];

        end

        assign rd_data = rd_data_0[DATA_WIDTH-1:0];
    end

    else if (ADDR_WIDTH == 15)
    begin
        // address MSB is on 14:0
        assign wr_addr_i = {1'b0,wr_addr};
        assign rd_addr_i = {1'b0,rd_addr};

        for (j = 0; j < DATA_WIDTH; j = j + 1)
        begin : addr_15

            wire            rd_data_l0;
            wire    [31:1]  unused_dl;
            wire    [3:0]   unused_pl;

            RAMB36 # (
                .READ_WIDTH_A           (1          ),
                .READ_WIDTH_B           (1          ),
                .WRITE_WIDTH_A          (1          ),
                .WRITE_WIDTH_B          (1          ),
                .SIM_COLLISION_CHECK    ("NONE" ),
                .SIM_MODE               ("FAST" )
            ) ramb36 (
                .CASCADEOUTLATA         (                           ),
                .CASCADEOUTLATB         (                           ),
                .CASCADEOUTREGA         (                           ),
                .CASCADEOUTREGB         (                           ),
                .DOA                    (                           ),
                .DOB                    ({unused_dl, rd_data_l0}    ),
                .DOPA                   (                           ),
                .DOPB                   (unused_pl                  ),
                .ADDRA                  (wr_addr_i                  ),
                .ADDRB                  (rd_addr_i                  ),
                .CASCADEINLATA          (1'b0                       ),
                .CASCADEINLATB          (1'b0                       ),
                .CASCADEINREGA          (1'b0                       ),
                .CASCADEINREGB          (1'b0                       ),
                .CLKA                   (wr_clk                     ),
                .CLKB                   (rd_clk                     ),
                .DIA                    ({31'h0, wr_data_i[j]}      ),
                .DIB                    (32'h0                      ),
                .DIPA                   (4'h0                       ),
                .DIPB                   (4'h0                       ),
                .ENA                    (1'b1                       ),
                .ENB                    (1'b1                       ),
                .REGCEA                 (1'b1                       ),
                .REGCEB                 (1'b1                       ),
                .SSRA                   (1'b0                       ),
                .SSRB                   (1'b0                       ),
                .WEA                    ({4{wr_en}}                 ),
                .WEB                    (4'h0                       )
            );

            assign rd_data[j] = rd_data_l0;
        end
    end

    else if (ADDR_WIDTH == 16)
    begin
        // Address is on bits [14:0]
        assign wr_addr_i = {1'b0, wr_addr[14:0]};
        assign rd_addr_i = {1'b0, rd_addr[14:0]};

        for (j = 0; j < DATA_WIDTH; j = j + 1)
        begin : addr16
            wire            rd_data_u0;
            wire    [31:1]  unused_du;
            wire    [3:0]   unused_pu;

            wire            rd_data_l0;
            wire    [31:1]  unused_dl;
            wire    [3:0]   unused_pl;

            RAMB36 # (
                .READ_WIDTH_A           (1      ),
                .READ_WIDTH_B           (1      ),
                .WRITE_WIDTH_A          (1      ),
                .WRITE_WIDTH_B          (1      ),
                .SIM_COLLISION_CHECK    ("NONE" ),
                .SIM_MODE               ("FAST" )
            ) ramb36_upper (
                .CASCADEOUTLATA         (                           ),
                .CASCADEOUTLATB         (                           ),
                .CASCADEOUTREGA         (                           ),
                .CASCADEOUTREGB         (                           ),
                .DOA                    (                           ),
                .DOB                    ({unused_du, rd_data_u0}    ),
                .DOPA                   (                           ),
                .DOPB                   (unused_pu                  ),
                .ADDRA                  (wr_addr_i                  ),
                .ADDRB                  (rd_addr_i                  ),
                .CASCADEINLATA          (1'b0                       ),
                .CASCADEINLATB          (1'b0                       ),
                .CASCADEINREGA          (1'b0                       ),
                .CASCADEINREGB          (1'b0                       ),
                .CLKA                   (wr_clk                     ),
                .CLKB                   (rd_clk                     ),
                .DIA                    ({31'h0, wr_data_i[j]}      ),
                .DIB                    (32'h0                      ),
                .DIPA                   (4'h0                       ),
                .DIPB                   (4'h0                       ),
                .ENA                    (1'b1                       ),
                .ENB                    (1'b1                       ),
                .REGCEA                 (1'b1                       ),
                .REGCEB                 (1'b1                       ),
                .SSRA                   (1'b0                       ),
                .SSRB                   (1'b0                       ),
                .WEA                    ({4{(wr_en & wr_addr[15])}} ),
                .WEB                    (4'h0                       )
            );

            RAMB36 # (
                .READ_WIDTH_A           (1      ),
                .READ_WIDTH_B           (1      ),
                .WRITE_WIDTH_A          (1      ),
                .WRITE_WIDTH_B          (1      ),
                .SIM_COLLISION_CHECK    ("NONE" ),
                .SIM_MODE               ("FAST" )
            ) ramb36_lower (
                .CASCADEOUTLATA         (                           ),
                .CASCADEOUTLATB         (                           ),
                .CASCADEOUTREGA         (                           ),
                .CASCADEOUTREGB         (                           ),
                .DOA                    (                           ),
                .DOB                    ({unused_dl, rd_data_l0}    ),
                .DOPA                   (                           ),
                .DOPB                   (unused_pl                  ),
                .ADDRA                  (wr_addr_i                  ),
                .ADDRB                  (rd_addr_i                  ),
                .CASCADEINLATA          (1'b0                       ),
                .CASCADEINLATB          (1'b0                       ),
                .CASCADEINREGA          (1'b0                       ),
                .CASCADEINREGB          (1'b0                       ),
                .CLKA                   (wr_clk                     ),
                .CLKB                   (rd_clk                     ),
                .DIA                    ({31'h0, wr_data_i[j]}      ),
                .DIB                    (32'h0                      ),
                .DIPA                   (4'h0                       ),
                .DIPB                   (4'h0                       ),
                .ENA                    (1'b1                       ),
                .ENB                    (1'b1                       ),
                .REGCEA                 (1'b1                       ),
                .REGCEB                 (1'b1                       ),
                .SSRA                   (1'b0                       ),
                .SSRB                   (1'b0                       ),
                .WEA                    ({4{(wr_en & ~wr_addr[15])}}),
                .WEB                    (4'h0                       )
            );

            assign rd_data_0[j] = rd_addr[15] ? rd_data_u0 : rd_data_l0;
        end

        assign rd_data = rd_data_0[DATA_WIDTH-1:0];
    end

    else
    begin
 `ifdef SIMULATION
        initial begin
            $display("%m : ** ERROR ** : Unsupported RAM parameters: ADDR_WIDTH=%d, DATA_WIDTH=%d", ADDR_WIDTH, DATA_WIDTH);
            $finish;
        end
 `else
        illegal_ram_params illegal_ram_params (
            .clk        (wr_clk)
        );
 `endif
    end
endgenerate
`ifdef SIMULATION
initial $display("%m: RAM Instance using ADDR_WIDTH=%d, DATA_WIDTH=%d, FAST_READ=%d",ADDR_WIDTH,DATA_WIDTH,FAST_READ);
`endif

endmodule
