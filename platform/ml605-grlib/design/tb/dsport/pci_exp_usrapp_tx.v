//-----------------------------------------------------------------------------
//
// (c) Copyright 2009 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information of Xilinx, Inc.
// and is protected under U.S. and international copyright and other
// intellectual property laws.
//
// DISCLAIMER
//
// This disclaimer is not a license and does not grant any rights to the
// materials distributed herewith. Except as otherwise provided in a valid
// license issued to you by Xilinx, and to the maximum extent permitted by
// applicable law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND WITH ALL
// FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES AND CONDITIONS, EXPRESS,
// IMPLIED, OR STATUTORY, INCLUDING BUT NOT LIMITED TO WARRANTIES OF
// MERCHANTABILITY, NON-INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE;
// and (2) Xilinx shall not be liable (whether in contract or tort, including
// negligence, or under any other theory of liability) for any loss or damage
// of any kind or nature related to, arising under or in connection with these
// materials, including for any direct, or any indirect, special, incidental,
// or consequential loss or damage (including loss of data, profits, goodwill,
// or any type of loss or damage suffered as a result of any action brought by
// a third party) even if such damage or loss was reasonably foreseeable or
// Xilinx had been advised of the possibility of the same.
//

// CRITICAL APPLICATIONS
//
// Xilinx products are not designed or intended to be fail-safe, or for use in
// any application requiring fail-safe performance, such as life-support or
// safety devices or systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any other
// applications that could lead to death, personal injury, or severe property
// or environmental damage (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and liability of any use of
// Xilinx products in Critical Applications, subject only to applicable laws
// and regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS PART OF THIS FILE
// AT ALL TIMES.
//
//-----------------------------------------------------------------------------
// Project    : Virtex-6 Integrated Block for PCI Express
// File       : pci_exp_usrapp_tx.v
//
//------------------------------------------------------------------------------
`timescale 1ns/1ns

`include "board_common.v"
`include "dut_defines.v"
`include "user_defines.v"
module pci_exp_usrapp_tx                     (

                                               trn_td,
                                               trn_trem_n,
                                               trn_tsof_n,
                                               trn_teof_n,
                                               trn_terrfwd_n,
                                               trn_tsrc_rdy_n,
                                               trn_tsrc_dsc_n,

                                               trn_clk,
                                               trn_reset_n,
                                               trn_lnk_up_n,
                                               trn_tdst_rdy_n,
                                               trn_tdst_dsc_n,
                                               trn_tbuf_av,

                                               speed_change_done_n

                                             );

output [(64 - 1):0]                            trn_td;
output [(8 - 1):0]                             trn_trem_n;
output                                         trn_tsof_n;
output                                         trn_teof_n;
output                                         trn_terrfwd_n;
output                                         trn_tsrc_rdy_n;
output                                         trn_tsrc_dsc_n;

input                                          trn_clk;
input                                          trn_reset_n;
input                                          trn_lnk_up_n;
input                                          trn_tdst_rdy_n;
input                                          trn_tdst_dsc_n;
input  [(6 - 1):0]     trn_tbuf_av;

input                                          speed_change_done_n;

parameter                                      Tcq = 1;
parameter                                      LINK_CAP_MAX_LINK_SPEED = 4'h2;


/* Output Variables */

reg [(64 - 1):0]          trn_td;
reg [(8 - 1):0]           trn_trem_n;
reg                                            trn_tsof_n;
reg                                            trn_teof_n;
reg                                            trn_terrfwd_n;
reg                                            trn_tsrc_rdy_n;
reg                                            trn_tsrc_dsc_n;

/* Local Variables */

integer                                        i, j, k;
reg  [7:0]                                     DATA_STORE [4095:0];
reg  [15:0]                                    COMPLETER_ID_CFG;
reg  [15:0]                                    REQUESTER_ID;
reg  [2:0]                                     DEFAULT_TC;
reg  [7:0]                                     DEFAULT_TAG;
reg  [15:0]                                    VENDOR_ID;

reg  [31:0]                                    P_ADDRESS_MASK;

reg  [31:0]                                    P_READ_DATA; // will store the results of a PCIE read completion
reg                                            p_read_data_valid;
reg  [31:0]                                    temp_register;

// BAR Init variables
//                              0 = disabled;  1 = io mapped;  2 = mem32 mapped;  3 = mem64 mapped


reg             [3:0]           ii;
integer                         jj;


reg             [31:0]          DEV_VEN_ID;  // holds device and vendor id

reg                             cpld_to; // boolean value to indicate if time out has occured while waiting for cpld
reg                             cpld_to_finish; // boolean value to indicate to $finish on cpld_to

reg [5:0] packet_trans_ch0; // number of packet transmitted over channel 0
reg [5:0] packet_trans_ch1; // number of packet transmitted over channel 1
reg [15:0] tag_xaui;
reg [15:0] tag_ch1;
reg        busy;
reg        break_loop = 0;
reg [15:0] cummulative_len = 0;

`include "pci_exp_new_task.v"

initial
begin

   COMPLETER_ID_CFG     = 16'b0000_0001_0000_0000;
   REQUESTER_ID         = 16'b0000_0000_0000_0000;  // ID of root port
   DEFAULT_TC           = 3'b000;
   DEFAULT_TAG          = 8'h00;
   VENDOR_ID            = 16'h10ee;
   tag_xaui             = 16'b0;
   tag_ch1              = 16'b0;
   packet_trans_ch0     = `CH0_S2C_BD_COUNT;
   packet_trans_ch1     = `CH1_S2C_BD_COUNT;
end

initial begin
        // Pre-BAR initialization

        DEV_VEN_ID = (32'h0007 << 16) | (32'h10EE);

        cpld_to = 0;    // By default time out has not occured
        cpld_to_finish = 1; // By default end simulation on time out
end

  reg [255:0] testname;

  initial begin
   $display("==================================================");
   $display(" \t \t START OF SIMULATION \t \t");
   $display("==================================================");
   if ($value$plusargs("TESTNAME=%s", testname))
   begin
    if ((testname == "basic_test") || (testname == "packet_spanning") ||
        (testname == "test_interrupts") || (testname == "disable_dma") ||
        (testname == "break_loop"))
    begin
      if (testname == "test_interrupts")
      begin
        `ifdef CH0
          `ifdef CH1
            $display("[%t] Error: Interrupt testcase works only with one channel active at a time", $time);
            $fdisplay(error_file_ptr,"[%t] Error: This testcase works only with one channel", $time);
            $display("Terminating simulation....");
            $finish;
          `endif
        `endif
      end
      $display(" ********** Running test {%0s} **********", testname);
    end
    else
    begin
      $display("Error! The given testname %s does not match any defined tests.", testname);
      $display("Supported tests are - \n\t basic_test \n\t packet_spanning \n\t test_interrupts \n\t disable_dma \n\t break_loop");
      $display("Terminating simulation....");
      $finish(2);
    end
   end
   else begin
    $display("No testname mentioned, defaulting to basic test...");
    testname = "basic_test";
    $display(" ********** Running test {%0s} **********", testname);
   end
   $display("==================================================");

    // Tx transaction interface signal initialization.
    trn_td     = 0;
    trn_tsof_n = 1;
    trn_teof_n = 1;
    trn_trem_n = 0;
    trn_terrfwd_n = 1;
    trn_tsrc_rdy_n = 1 ;
    trn_tsrc_dsc_n = 1;

    // system configuration
    TSK_SYSTEM_CONFIG;    // - Performs basic PCIe Configuration operations
    TSK_DMA_CONFIG;       // - Discovers DMA engines

    //Test starts here

    if (testname == "basic_test")
      $display("********** Starting basic_test **********");
    else if(testname == "packet_spanning")
    begin
      $display("********** Starting packet_span test **********");
      `ifdef CH0
        TSK_PACKET_SPANNING(`SPAN_COUNT,0);
      `endif
      `ifdef CH1
        TSK_PACKET_SPANNING(`SPAN_COUNT,1);
      `endif
    end
    else if(testname == "test_interrupts")
    begin
      $display("********** Starting interrupt test **********");
      TSK_TEST_INTERRUPTS;
    end
    else if(testname == "disable_dma")
     begin
      $display("********** Starting DMA disable test **********");
      TSK_DMA_DISABLE;
    end
    else if(testname == "break_loop")
     begin
      $display("********** Starting Break Loopback test **********");
      break_loop = 1;
    end
    else begin
      $display("[%t] %m: Error: Unrecognized TESTNAME: %0s", $realtime, testname);
      $finish(2);
    end


 // - Configuring APP-1
 `ifdef CH1
    if (break_loop == 0)
      TSK_CH1_LB_OR_CHEC(`ENABLE_LOOPBACK);
    else
      TSK_CH1_LB_OR_CHEC(`ENABLE_CHECKER);

    TSK_TX_CLK_EAT(50);
    TSK_VFIFO_CONFIG;
 `endif
    // - Application - 0
 `ifdef CH0
    TSK_INIT_DMA(1'b0);  // - DMA initialization and start of operations on APP-0
 `endif
   // - Application - 1
 `ifdef CH1
    TSK_INIT_DMA(1'b1);  // - DMA initialization and start of operations on APP-1
    if (break_loop == 1) begin
      TSK_TX_CLK_EAT(1000);
      // Note the generator/rx path is enabled for a finite time since the DDR3 model
      // cannot hold that much data and will error out.
      TSK_CH1_GEN(`ENABLE_GENERATOR);
      TSK_TX_CLK_EAT(500);
      TSK_CH1_GEN(`DISABLE_GENERATOR);
    end
 `endif

  end

 /************************************************************
 Task : TSK_SYSTEM_INITIALIZATION
 Description : Waits for transaction interface reset and linkup between the Root Port Model and the Endpoint DUT.
 Sends SSPL message.
 This task must be invoked prior to the Endpoint core initialization
 *************************************************************/

  task TSK_SYSTEM_INITIALIZATION;
  begin
    //--------------------------------------------------------------------------
    // Event # 1: Wait for Transaction reset to be de-asserted..
    //--------------------------------------------------------------------------

    wait (trn_reset_n == 1);

    $display("[%t] : Transaction Reset Is De-asserted...", $realtime);


    //--------------------------------------------------------------------------
    // Event # 2: Wait for Transaction link to be asserted..
    //--------------------------------------------------------------------------
    wait (trn_lnk_up_n == 0);

    wait (((LINK_CAP_MAX_LINK_SPEED == 4'h2) && (speed_change_done_n == 1'b0)) || (LINK_CAP_MAX_LINK_SPEED == 4'h1))

    $display("[%t] : Transaction Link Is Up...", $realtime);

       wait(comp.cfg_lstatus[13] ==1);
       #5000;
       $display("[%t] Programming the bus master enable of RP", $time);
       cfg_usrapp.TSK_WRITE_CFG_DW(32'h01, 32'h6);  // programming the bus master enable
       TSK_TX_MESSAGE_DATA(DEFAULT_TAG, 3'b0, 10'b1, 64'h0, 3'b100, 8'b01010000, 32'h0);
       $display("[%t] Set Slot Power Limit Message with data ", $time);
       DEFAULT_TAG = DEFAULT_TAG +1;
       TSK_TX_CLK_EAT(100);
  end
  endtask

    /************************************************************
    Task : TSK_TX_TYPE0_CONFIGURATION_READ
    Inputs : Tag, PCI/PCI-Express Reg Address, First BypeEn
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Type 0 Configuration Read TLP
    *************************************************************/

    task TSK_TX_TYPE0_CONFIGURATION_READ;
        input    [7:0]    tag_;
        input    [11:0]    reg_addr_;
        input    [3:0]    first_dw_be_;
        begin
            if (trn_lnk_up_n) begin

                $display("[%t] : Trn interface is MIA", $realtime);
                $finish(1);

            end

            while (busy == 1'b1) begin
                @(posedge trn_clk);
            end

            busy = 1;

            TSK_TX_SYNCHRONIZE(0, 0);

            trn_td             <= #(Tcq)    {
                                            1'b0,
                                            2'b00,
                                            5'b00100,
                                            1'b0,
                                            3'b000,
                                            4'b0000,
                                            1'b0,
                                            1'b0,
                                            2'b00,
                                            2'b00,
                                            10'b0000000001,  // 32
                                            REQUESTER_ID,
                                            tag_,
                                            4'b0000,
                                            first_dw_be_     // 64
                                            };

            trn_tsof_n         <= #(Tcq)    0;
            trn_teof_n         <= #(Tcq)    1;
            trn_trem_n         <= #(Tcq)    0;
            trn_tsrc_rdy_n     <= #(Tcq)    0 ;

            TSK_TX_SYNCHRONIZE(1, 0);

            trn_td             <= #(Tcq)    {
                                            COMPLETER_ID_CFG,
                                            4'b0000,
                                            reg_addr_[11:2],
                                            2'b00,
                                            32'b0
                                            };

            trn_tsof_n         <= #(Tcq)    1;
            trn_teof_n         <= #(Tcq)    0;
            trn_trem_n         <= #(Tcq)    8'h0F;
            trn_tsrc_rdy_n     <= #(Tcq)    0 ;

            TSK_TX_SYNCHRONIZE(1, 1);

            trn_teof_n         <= #(Tcq)    1;
            trn_trem_n         <= #(Tcq)    0;
            trn_tsrc_rdy_n     <= #(Tcq)    1;
            busy = 0;

        end
    endtask // TSK_TX_TYPE0_CONFIGURATION_READ


    /************************************************************
    Task : TSK_TX_TYPE0_CONFIGURATION_WRITE
    Inputs : Tag, PCI/PCI-Express Reg Address, First BypeEn
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Type 0 Configuration Write TLP
    *************************************************************/

    task TSK_TX_TYPE0_CONFIGURATION_WRITE;
        input    [7:0]    tag_;
        input    [11:0]    reg_addr_;
        input    [31:0]    reg_data_;
        input    [3:0]    first_dw_be_;
        begin
            if (trn_lnk_up_n) begin

                $display("[%t] : Trn interface is MIA", $realtime);
                $finish(1);

            end

            while (busy == 1'b1) begin
                @(posedge trn_clk);
            end

            busy = 1;

            TSK_TX_SYNCHRONIZE(0, 0);

            trn_td             <= #(Tcq)   {
                                           1'b0,
                                           2'b10,
                                           5'b00100,
                                           1'b0,
                                           3'b000,
                                           4'b0000,
                                           1'b0,
                                           1'b0,
                                           2'b00,
                                           2'b00,
                                           10'b0000000001, // 32
                                           REQUESTER_ID,
                                           tag_,
                                           4'b0000,
                                           first_dw_be_    // 64
                                           };

            trn_tsof_n         <= #(Tcq)   0;
            trn_tsrc_rdy_n     <= #(Tcq)   0 ;

            TSK_TX_SYNCHRONIZE(1, 0);

            trn_td             <= #(Tcq)   {
                                           COMPLETER_ID_CFG,
                                           4'b0000,
                                           reg_addr_[11:2],
                                           2'b00,            // 32
                                           reg_data_[7:0],
                                           reg_data_[15:8],
                                           reg_data_[23:16],
                                           reg_data_[31:24]  // 64
                                           };

            trn_tsof_n         <= #(Tcq)   1;
            trn_teof_n         <= #(Tcq)   0;
            trn_trem_n         <= #(Tcq)   8'h00;

            TSK_TX_SYNCHRONIZE(1, 1);

            trn_teof_n         <= #(Tcq)   1;
            trn_trem_n         <= #(Tcq)   0;
            trn_tsrc_rdy_n     <= #(Tcq)   1;
            busy = 0;

        end
    endtask // TSK_TX_TYPE0_CONFIGURATION_WRITE


    /************************************************************
    Task : TSK_TX_MEMORY_READ_32
    Inputs : Tag, Length, Address, Last Byte En, First Byte En
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Memory Read 32 TLP
    *************************************************************/

    task TSK_TX_MEMORY_READ_32;
        input    [7:0]    tag_;
        input    [2:0]    tc_;
        input    [9:0]    len_;
        input    [31:0]    addr_;
        input    [3:0]    last_dw_be_;
        input    [3:0]    first_dw_be_;
        begin
            if (trn_lnk_up_n) begin

                $display("[%t] : Trn interface is MIA", $realtime);
                $finish(1);

            end

            while (busy == 1'b1) begin
                @(posedge trn_clk);
            end

            busy = 1;

            TSK_TX_SYNCHRONIZE(0, 0);

            trn_td             <= #(Tcq)  {
                                          1'b0,
                                          2'b00,
                                          5'b00000,
                                          1'b0,
                                          tc_,
                                          4'b0000,
                                          1'b0,
                                          1'b0,
                                          2'b00,
                                          2'b00,
                                          len_,         // 32
                                          REQUESTER_ID,
                                          tag_,
                                          last_dw_be_,
                                          first_dw_be_  // 64
                                          };
            trn_tsof_n         <= #(Tcq)  0;
            trn_teof_n         <= #(Tcq)  1;
            trn_trem_n         <= #(Tcq)  0;
            trn_tsrc_rdy_n     <= #(Tcq)  0 ;

            TSK_TX_SYNCHRONIZE(1, 0);

            trn_td             <= #(Tcq)  {
                                          addr_[31:2],
                                          2'b00,
                                          32'b0
                                          };

            trn_tsof_n         <= #(Tcq)  1;
            trn_teof_n         <= #(Tcq)  0;
            trn_trem_n         <= #(Tcq)  8'h0F;
            trn_tsrc_rdy_n     <= #(Tcq)  0 ;

            TSK_TX_SYNCHRONIZE(1, 1);

            trn_teof_n         <= #(Tcq)  1;
            trn_trem_n         <= #(Tcq)  0;
            trn_tsrc_rdy_n     <= #(Tcq)  1;
            busy = 0;

        end
    endtask // TSK_TX_MEMORY_READ_32


    /************************************************************
    Task : TSK_TX_MEMORY_WRITE_32
    Inputs : Tag, Length, Address, Last Byte En, First Byte En
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Memory Write 32 TLP
    *************************************************************/

    task TSK_TX_MEMORY_WRITE_32;
        input    [7:0]    tag_;
        input    [2:0]    tc_;
        input    [9:0]    len_;
        input    [31:0]    addr_;
        input    [3:0]    last_dw_be_;
        input    [3:0]    first_dw_be_;
        input        ep_;
        reg    [10:0]    _len;
        integer        _j;
        begin
            if (len_ == 0)

                _len = 1024;

            else

                _len = len_;

            if (trn_lnk_up_n) begin

                $display("[%t] : Trn interface is MIA", $realtime);
                $finish(1);

            end

            while (busy == 1'b1) begin
                @(posedge trn_clk);
            end

            busy = 1;

            TSK_TX_SYNCHRONIZE(0, 0);

            trn_td             <= #(Tcq)  {
                                          1'b0,
                                          2'b10,
                                          5'b00000,
                                          1'b0,
                                          tc_,
                                          4'b0000,
                                          1'b0,
                                          1'b0,
                                          2'b00,
                                          2'b00,
                                          len_,        // 32
                                          REQUESTER_ID,
                                          tag_,
                                          last_dw_be_,
                                          first_dw_be_ // 64
                                          };
            trn_tsof_n         <= #(Tcq)  0;
            trn_teof_n         <= #(Tcq)  1;
            trn_trem_n         <= #(Tcq)  0;
            trn_tsrc_rdy_n     <= #(Tcq)  0 ;

            TSK_TX_SYNCHRONIZE(1, 0);

            trn_td            <= #(Tcq)   {
                                          addr_[31:2],
                                          2'b00,
                                          DATA_STORE[0],
                                          DATA_STORE[1],
                                          DATA_STORE[2],
                                          DATA_STORE[3]
                                          };

            trn_tsof_n         <= #(Tcq)  1;

            if (_len != 1) begin

                for (_j = 4; _j < (_len * 4); _j = _j + 8) begin

                    TSK_TX_SYNCHRONIZE(1, 0);

                    trn_td <= #(Tcq)    {
                                DATA_STORE[_j + 0],
                                DATA_STORE[_j + 1],
                                DATA_STORE[_j + 2],
                                DATA_STORE[_j + 3],
                                DATA_STORE[_j + 4],
                                DATA_STORE[_j + 5],
                                DATA_STORE[_j + 6],
                                DATA_STORE[_j + 7]
                                };


                    if ((_j + 7)  >=  ((_len * 4) - 1)) begin

                        trn_teof_n         <= #(Tcq) 0;
                        if (ep_)
                            trn_terrfwd_n     <= #(Tcq) 0;

                        if (((_len - 1) % 2) == 0)

                            trn_trem_n     <= #(Tcq) 8'h00;

                        else

                            trn_trem_n     <= #(Tcq) 8'h0f;

                    end

                end

            end else begin

                trn_teof_n         <= #(Tcq) 0;
                if (ep_)
                    trn_terrfwd_n     <= #(Tcq) 0;
                trn_trem_n         <= #(Tcq) 8'h00;

            end

            TSK_TX_SYNCHRONIZE(1, 1);

            trn_teof_n         <= #(Tcq) 1;
            trn_terrfwd_n      <= #(Tcq) 1;
            trn_trem_n         <= #(Tcq) 0;
            trn_tsrc_rdy_n     <= #(Tcq) 1;
            busy = 0;

        end
    endtask // TSK_TX_MEMORY_WRITE_32

    /************************************************************
    Task : TSK_TX_COMPLETION
    Inputs : Tag, TC, Length, Completion ID
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Completion TLP
    *************************************************************/

    task TSK_TX_COMPLETION;
        input    [7:0]    tag_;
        input    [2:0]    tc_;
        input    [9:0]    len_;
        input    [2:0]    comp_status_;
        begin

            if (trn_lnk_up_n) begin

                $display("[%t] : Trn interface is MIA", $realtime);
                $finish(1);

            end

            while (busy == 1'b1) begin
                @(posedge trn_clk);
            end

            busy = 1;

            TSK_TX_SYNCHRONIZE(0, 0);

            trn_td             <= #(Tcq)    {
                                            1'b0,
                                            2'b00,
                                            5'b01010,
                                            1'b0,
                                            tc_,
                                            4'b0000,
                                            1'b0,
                                            1'b0,
                                            2'b00,
                                            2'b00,
                                            len_,           // 32
                                            REQUESTER_ID,
                                            comp_status_,
                                            1'b0,
                                            12'b0
                                            };
            trn_tsof_n         <= #(Tcq)    0;
            trn_teof_n         <= #(Tcq)    1;
            trn_trem_n         <= #(Tcq)    0;
               trn_tsrc_rdy_n         <= #(Tcq)    0 ;

            TSK_TX_SYNCHRONIZE(1, 0);

            trn_td            <= #(Tcq)    {
                                COMPLETER_ID_CFG,
                                tag_,
                                8'b00,
                                32'b0
                                };
            trn_tsof_n         <= #(Tcq) 1;
            trn_teof_n         <= #(Tcq) 0;
            trn_trem_n         <= #(Tcq) 8'h0F;

            TSK_TX_SYNCHRONIZE(1, 1);

            trn_teof_n         <= #(Tcq) 1;
            trn_trem_n         <= #(Tcq) 0;
            trn_tsrc_rdy_n     <= #(Tcq) 1;
            busy = 0;

        end
    endtask // TSK_TX_COMPLETION

    /************************************************************
    Task : TSK_TX_COMPLETION_DATA
    Inputs : Tag, TC, Length, Completion ID
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Completion TLP
    *************************************************************/

    task TSK_TX_COMPLETION_DATA;
        input    [7:0]    tag_;
        input    [2:0]    tc_;
        input    [9:0]    len_;
        input    [11:0]   byte_count_;
        input    [6:0]    lower_addr_;
        input    [2:0]    comp_status_;
        input             ep_;
        input    [9:0]    payload_addr;
        input             chnl;

        reg    [10:0]    _len;

        integer          _j;
        begin
            if (len_ == 0)

                _len = 1024;

            else

                _len = len_;

            if (trn_lnk_up_n) begin

                $display("[%t] : Trn interface is MIA", $realtime);
                $finish(1);

            end

         while (busy == 1'b1) begin
                @(posedge trn_clk);
            end

            busy = 1;


            if (chnl == 1) begin
              cummulative_len = cummulative_len + _len*4;
              if (cummulative_len >= 1024)
                  cummulative_len = 0;
              //$display("cummulative_len %h",cummulative_len);
            end

            // Payload data initialization.
            TSK_USR_DATA_SETUP_SEQ(chnl);

            TSK_TX_SYNCHRONIZE(0, 0);

            trn_td             <= #(Tcq)    {
                                            1'b0,
                                            2'b10,
                                            5'b01010,
                                            1'b0,
                                            tc_,
                                            4'b0000,
                                            1'b0,
                                            1'b0,
                                            2'b00,
                                            2'b00,
                                            len_,           // 32
                                            REQUESTER_ID,
                                            comp_status_,
                                            1'b0,
                                            byte_count_    // 64
                                            };
            trn_tsof_n         <= #(Tcq)    0;
            trn_teof_n         <= #(Tcq)    1;
            trn_trem_n         <= #(Tcq)    0;
            trn_tsrc_rdy_n     <= #(Tcq)    0;

            TSK_TX_SYNCHRONIZE(1, 0);

            trn_td            <= #(Tcq)    {
                                COMPLETER_ID_CFG,
                                tag_,
                                1'b0,
                                lower_addr_,
                                DATA_STORE[payload_addr + 0],
                                DATA_STORE[payload_addr + 1],
                                DATA_STORE[payload_addr + 2],
                                DATA_STORE[payload_addr + 3]
                                };
            trn_tsof_n         <= #(Tcq) 1;

            if (_len != 1) begin

                //$display("_len %h",_len);
                //$display("payload_addr %h",payload_addr);

                for (_j = 4; _j < (_len * 4); _j = _j + 8) begin

                    TSK_TX_SYNCHRONIZE(1, 0);

                    trn_td <= #(Tcq)    {
                                DATA_STORE[payload_addr + _j + 0],
                                DATA_STORE[payload_addr + _j + 1],
                                DATA_STORE[payload_addr + _j + 2],
                                DATA_STORE[payload_addr + _j + 3],
                                DATA_STORE[payload_addr + _j + 4],
                                DATA_STORE[payload_addr + _j + 5],
                                DATA_STORE[payload_addr + _j + 6],
                                DATA_STORE[payload_addr + _j + 7]
                                };

                    if ((_j + 7)  >=  ((_len * 4) - 1)) begin

                        trn_teof_n         <= #(Tcq) 0;

                        if (ep_)
                            trn_terrfwd_n     <= #(Tcq) 0;

                        if (((_len - 1) % 2) == 0)

                            trn_trem_n     <= #(Tcq) 8'h00;

                        else

                            trn_trem_n     <= #(Tcq) 8'h0f;

                    end

                end

            end else begin

                trn_teof_n         <= #(Tcq) 0;
                trn_trem_n         <= #(Tcq) 8'h00;

            end

            TSK_TX_SYNCHRONIZE(1, 1);

            trn_teof_n         <= #(Tcq) 1;
            trn_terrfwd_n      <= #(Tcq) 1;
            trn_trem_n         <= #(Tcq) 0;
            trn_tsrc_rdy_n     <= #(Tcq) 1;

            busy = 0;
        end
    endtask // TSK_TX_COMPLETION_DATA

    /************************************************************
    Task : TSK_TX_MESSAGE
    Inputs : Tag, TC, Address, Message Routing, Message Code
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Message TLP
    *************************************************************/

    task TSK_TX_MESSAGE;
        input    [7:0]    tag_;
        input    [2:0]    tc_;
        input    [9:0]    len_;
        input    [63:0]   data_;
        input    [2:0]    message_rtg_;
        input    [7:0]    message_code_;
        begin

            if (trn_lnk_up_n) begin

                $display("[%t] : Trn interface is MIA", $realtime);
                $finish(1);

            end

            while (busy == 1'b1) begin
                @(posedge trn_clk);
            end

            busy = 1;

            TSK_TX_SYNCHRONIZE(0, 0);

            trn_td             <= #(Tcq)    {
                                            1'b0,
                                            2'b01,
                                            {{2'b10}, {message_rtg_}},
                                            1'b0,
                                            tc_,
                                            4'b0000,
                                            1'b0,
                                            1'b0,
                                            2'b00,
                                            2'b00,
                                            10'b0,        // 32
                                            REQUESTER_ID,
                                            tag_,
                                            message_code_ // 64
                                            };

            trn_tsof_n         <= #(Tcq)    0;
            trn_teof_n         <= #(Tcq)    1;
            trn_trem_n         <= #(Tcq)    0;
            trn_tsrc_rdy_n         <= #(Tcq)    0 ;

            TSK_TX_SYNCHRONIZE(1, 0);

            trn_td            <= #(Tcq)    {
                                data_
                                };
            trn_tsof_n         <= #(Tcq) 1;
            trn_teof_n         <= #(Tcq) 0;
            trn_trem_n         <= #(Tcq) 8'h00;

            TSK_TX_SYNCHRONIZE(1, 1);

            trn_teof_n         <= #(Tcq) 1;
            trn_trem_n         <= #(Tcq) 0;
            trn_tsrc_rdy_n         <= #(Tcq) 1;
            busy = 0;
        end
    endtask // TSK_TX_MESSAGE

    /************************************************************
    Task : TSK_TX_MESSAGE_DATA
    Inputs : Tag, TC, Address, Message Routing, Message Code
    Outputs : Transaction Tx Interface Signaling
    Description : Generates a Message Data TLP
    *************************************************************/

    task TSK_TX_MESSAGE_DATA;
        input    [7:0]    tag_;
        input    [2:0]    tc_;
        input    [9:0]    len_;
        input    [63:0]    data_;
        input    [2:0]    message_rtg_;
        input    [7:0]    message_code_;
        input    [31:0]   payload_;
        reg    [10:0]    _len;
        integer     _j;
        begin

            if (len_ == 0)

                _len = 1024;

            else

                _len = len_;

            if (trn_lnk_up_n) begin

                $display("[%t] : Trn interface is MIA", $realtime);
                $finish(1);

            end

            while (busy == 1'b1) begin
                @(posedge trn_clk);
            end

            busy = 1;

            TSK_TX_SYNCHRONIZE(0, 0);

            trn_td             <= #(Tcq)    {
                                            1'b0,
                                            2'b11,
                                            {{2'b10}, {message_rtg_}},
                                            1'b0,
                                            tc_,
                                            4'b0000,
                                            1'b0,
                                            1'b0,
                                            2'b00,
                                            2'b00,
                                            len_,           // 32
                                            REQUESTER_ID,
                                            tag_,
                                            message_code_   // 64
                                            };
            trn_tsof_n         <= #(Tcq)    0;
            trn_teof_n         <= #(Tcq)    1;
            trn_trem_n         <= #(Tcq)    0;
               trn_tsrc_rdy_n         <= #(Tcq)    0 ;

            TSK_TX_SYNCHRONIZE(1, 0);

            trn_td            <= #(Tcq)    {
                                data_
                                };
            trn_tsof_n         <= #(Tcq) 1;
            TSK_TX_SYNCHRONIZE(1, 0);

                  trn_td <= #(Tcq)    {
                                  payload_
                                  };
                  trn_teof_n         <= #(Tcq) 0;
                    if ((_len % 2) == 0)

                        trn_trem_n     <= #(Tcq) 8'h00;
                    else

                        trn_trem_n     <= #(Tcq) 8'h0f;

            TSK_TX_SYNCHRONIZE(1, 1);

            trn_teof_n         <= #(Tcq) 1;
            trn_trem_n         <= #(Tcq) 0;
            trn_tsrc_rdy_n         <= #(Tcq) 1;
            busy = 0;

        end
    endtask // TSK_TX_MESSAGE_DATA


    /************************************************************
    Task : TSK_TX_SYNCHRONIZE
    Inputs : None
    Outputs : None
    Description : Synchronize with tx clock and handshake signals
    *************************************************************/

    task TSK_TX_SYNCHRONIZE;
        input         first_;
        input        last_call_;
        reg last_;
        begin
            if (trn_lnk_up_n) begin

                $display("[%t] : Trn interface is MIA", $realtime);
                $finish(1);

            end

            @(posedge trn_clk);
            if ((trn_tdst_rdy_n == 1'b1) && (first_ == 1'b1)) begin

                while (trn_tdst_rdy_n == 1'b1) begin

                    @(posedge trn_clk);

                end
            end
            if (first_ == 1'b1) begin

                last_ = (trn_trem_n == 8'h00) ? 0 : 1;

                // read data driven into memory
                com_usrapp.TSK_READ_DATA(last_,
                                                  `TX_LOG,
                                                  trn_td,
                                                  trn_trem_n);
            end


            if (last_call_)

                 com_usrapp.TSK_PARSE_FRAME(`TX_LOG);
        end
    endtask // TSK_TX_SYNCHRONIZE


    /************************************************************
    Task : TSK_USR_DATA_SETUP_SEQ
    Inputs : chnl
    Outputs : None
    Description : Populates scratch pad data area with known good data.
    *************************************************************/

    task TSK_USR_DATA_SETUP_SEQ;
    input chnl;

    integer        i_;
    reg [15:0]     length_;
    reg [15:0]     length_ch1_;

    begin

      tag_xaui = chnl0_index;

      length_ = BUFFER_LENGTH_CH0[chnl0_index][15:0] + 'd4;
      length_ch1_ = `MAX_BUFFER_LENGTH_CHNL1;


      if(chnl == 0) begin
        DATA_STORE[0] = length_[7:0];
        DATA_STORE[1] = length_[15:8];
        DATA_STORE[2] = tag_xaui[7:0];
        DATA_STORE[3] = tag_xaui[15:8];
        DATA_STORE[4] = 8'b0000_0000;
        DATA_STORE[5] = 8'b0000_0000;
        DATA_STORE[6] = 8'b0000_0000;
        DATA_STORE[7] = 8'b0000_0000;

        for (i_ = 8; i_ <= 4095; i_ = i_ + 1) begin
          DATA_STORE[i_] = i_;
        end
      end else begin
        //$display("cummulative_len %h",cummulative_len);
        //$display("tag_ch1 %d",tag_ch1);
        DATA_STORE[0] = length_ch1_[7:0];
        DATA_STORE[1] = length_ch1_[15:8];
        DATA_STORE[2] = tag_ch1[7:0];
        DATA_STORE[3] = tag_ch1[15:8];
        DATA_STORE[4] = tag_ch1[7:0];
        DATA_STORE[5] = tag_ch1[15:8];
        DATA_STORE[6] = tag_ch1[7:0];
        DATA_STORE[7] = tag_ch1[15:8];
        for (i_ = 8; i_ <= 4095; i_ = i_ + 2) begin
          DATA_STORE[i_]    = tag_ch1[7:0];
          DATA_STORE[i_+1]  = tag_ch1[15:8];
        end
      end

    tag_ch1  = (chnl == 1 && cummulative_len == 0) ? tag_ch1+1 : tag_ch1;

    end
    endtask // TSK_USR_DATA_SETUP_SEQ

    /************************************************************
    Task : TSK_TX_CLK_EAT
    Inputs : None
    Outputs : None
    Description : Consume clocks.
    *************************************************************/

    task TSK_TX_CLK_EAT;
        input    [31:0]            clock_count;
        integer            i_;
        begin
            for (i_ = 0; i_ < clock_count; i_ = i_ + 1) begin

                @(posedge trn_clk);

            end
        end
    endtask // TSK_TX_CLK_EAT

/************************************************************
  Task : TSK_SET_READ_DATA
  Inputs : Data
  Outputs : None
  Description : Called from common app. Common app hands read
                data to usrapp_tx.
  *************************************************************/

  task TSK_SET_READ_DATA;

    input [3:0] be_;   // not implementing be's yet
    input   [31:0]  data_; // might need to change this to byte
    begin

      P_READ_DATA = data_;
      p_read_data_valid = 1;

    end
  endtask // TSK_SET_READ_DATA


  /************************************************************
  Task : TSK_WAIT_FOR_READ_DATA
  Inputs : None
  Outputs : Read data P_READ_DATA will be valid
  Description : Called from tx app. Common app hands read
                data to usrapp_tx. This task must be executed
                immediately following a call to
                TSK_TX_TYPE0_CONFIGURATION_READ in order for the
                read process to function correctly. Otherwise
                there is a potential race condition with
                p_read_data_valid.
  *************************************************************/

  task TSK_WAIT_FOR_READ_DATA;

                integer j;

    begin
                  j = 10;
                  p_read_data_valid = 0;
                  fork
                   while ((!p_read_data_valid) && (cpld_to == 0)) @(posedge trn_clk);
                   begin // second process
                     while ((j > 0) && (!p_read_data_valid))
                       begin
                         TSK_TX_CLK_EAT(100);
                         j = j - 1;
                       end
                       if (!p_read_data_valid) begin
                        cpld_to = 1;
                        if (cpld_to_finish == 1) begin
                            $display("TIMEOUT ERROR in usrapp_tx:TSK_WAIT_FOR_READ_DATA. Completion data never received.");
                            $finish;
                          end
                        else
                            $display("TIMEOUT WARNING in usrapp_tx:TSK_WAIT_FOR_READ_DATA. Completion data never received.");

                     end
                   end

      join

    end
  endtask // TSK_WAIT_FOR_READ_DATA


   /************************************************************
        Task : TSK_BAR_INIT
        Inputs : None
        Outputs : None
        Description : Scans PCI core's configuration registers.
   *************************************************************/

    task TSK_BAR_INIT;
       begin

        //--------------------------------------------------------------------------
        // Write PCI_MASK to bar's space via PCIe fabric interface to find range
        //--------------------------------------------------------------------------

        P_ADDRESS_MASK          = 32'hffff_ffff;
        DEFAULT_TAG     = 0;
        DEFAULT_TC    = 0;



        $display("[%t] PCIe CFG: BAR0 Programming", $time);
        $fdisplay(tx_file_ptr,"[%t] PCIe CFG: BAR0 Programming", $time);
        $display("[%t] PCIe CFG: Reading BAR0 ", $time);
        TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h10, 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_WAIT_FOR_READ_DATA;

        $display("[%t] PCIe CFG: Programming BAR0 with value = %h ", $time,P_ADDRESS_MASK);
        $fdisplay(tx_file_ptr,"[%t] PCIe CFG: Programming BAR0 with value = %h", $time,P_ADDRESS_MASK);
        TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h10, P_ADDRESS_MASK, 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_CLK_EAT(100);

  // Read BAR0 Range
      $display("[%t] PCIe CFG: Reading BAR0 range", $time);

        TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h10, 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_WAIT_FOR_READ_DATA;

        $display("[%t] PCIe CFG: Programming BAR0 with value = %h ", $time,`DUT_BADDR_LOWER);
        $fdisplay(tx_file_ptr,"[%t] PCIe CFG: Programming BAR0 with value = %h", $time,`DUT_BADDR_LOWER);

        TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h10, `DUT_BADDR_LOWER,  4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_CLK_EAT(100);

        TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h10, 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_WAIT_FOR_READ_DATA;


        $display("[%t] PCIe CFG: BAR2 Programming",$time);
        TSK_TX_TYPE0_CONFIGURATION_WRITE(DEFAULT_TAG, 12'h14, `DUT_BAR2_UPPER, 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_TX_CLK_EAT(100);

  // Read BAR2 Range

        TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h14, 4'hF);
        DEFAULT_TAG = DEFAULT_TAG + 1;
        TSK_WAIT_FOR_READ_DATA;

       end
    endtask // TSK_BAR_INIT

endmodule // pci_exp_usrapp_tx




