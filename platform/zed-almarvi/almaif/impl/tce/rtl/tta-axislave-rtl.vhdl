-- Copyright (c) 2016 Nokia Research Center
-- 
-- Permission is hereby granted, free of charge, to any person obtaining a
-- copy of this software and associated documentation files (the "Software"),
-- to deal in the Software without restriction, including without limitation
-- the rights to use, copy, modify, merge, publish, distribute, sublicense,
-- and/or sell copies of the Software, and to permit persons to whom the
-- Software is furnished to do so, subject to the following conditions:
-- 
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
-- FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
-- DEALINGS IN THE SOFTWARE.
-------------------------------------------------------------------------------
-- Title      : AXI lite interface to TTA debugger and stream IO
-- Project    : 
-------------------------------------------------------------------------------
-- File       : axi4dbgslave-rtl.vhdl
-- Author     : Tommi Zetterman  <tommi.zetterman@nokia.com>
-- Company    : Nokia Research Center
-- Created    : 2014-06-23
-- Last update: 2015-06-04
-- Platform   : 
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2014 Nokia Research Center
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2014-06-23  1.0      zetterma Created (as axi4dbgslave-rtl.vhdl
-- 2015-01-27  1.1      viitanet Modified into a processor wrapper
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.debugger_if.all;
use work.misc.all;
use work.tta0_globals.all;
use work.tta0_params.all;
use work.tta0_imem_mau.all;

architecture rtl of tta_axislave is

  constant io_dataw_c : integer := 32;
  constant io_addrw_c : integer := 2 + mmax(mmax(IMEMADDRWIDTH+1,debreg_addr_width_c),fu_LSU_addrw-2);

  type state_t is (S_READY, S_WAITWDATA, S_WAITDONE, S_WAITBRESP,
                   S_WAITREAD, S_WAITDV, S_WAITRREADY);
  signal state   : state_t;
  signal wdcount : unsigned(7 downto 0);
  
  signal io_addr    : std_logic_vector(io_addrw_c-1 downto 0);
  signal io_wr_data : std_logic_vector(io_dataw_c-1 downto 0);
  signal io_wr_mask : std_logic_vector(io_dataw_c/8-1 downto 0);
  signal io_rd_data : std_logic_vector(io_dataw_c-1 downto 0);
  signal io_rd_en   : std_logic;
  signal io_wr_en   : std_logic;


begin

  assert axi_addrw_g >= 2 + io_addrw_c
    report "IO address space too small." severity failure;
  
  accel : entity work.tta_accel
    generic map (
      io_addrw_g => io_addrw_c,
      io_dataw_g => io_dataw_c
    )
    port map (
      clk        => clk,
      nreset     => nreset,
      --
      io_addr    => io_addr,
      io_wr_data => io_wr_data,
      io_wr_mask => io_wr_mask,
      io_rd_data => io_rd_data,
      io_rd_en   => io_rd_en,
      io_wr_en   => io_wr_en
    );
  
  sync : process(clk, nreset)
  begin

  if (nreset = '0') then
    s_axi_awready <= '0';
    s_axi_wready  <= '0';
    s_axi_bvalid  <= '0';
    s_axi_arready <= '0';
    s_axi_rdata   <= (others => '0');
    s_axi_rresp   <= (others => '0');
    s_axi_rvalid  <= '0';
    s_axi_bresp   <= (others => '0');
    io_wr_en      <= '1';
    io_rd_en      <= '1';
    io_addr       <= (others => '0');
    io_wr_data    <= (others => '0');
    io_wr_mask    <= (others => '0');
    state         <= S_READY;
    wdcount       <= (others => '0');
  elsif rising_edge(clk) then
    s_axi_arready <= '0';
    s_axi_awready <= '0';
    
    io_wr_en      <= '0';
    io_rd_en      <= '0';
    case state is

      when S_READY =>
        if (s_axi_awvalid = '1') then
          io_addr       <= s_axi_awaddr(io_addrw_c+1 downto 2);
          s_axi_awready <= '1';
          state <= S_WAITWDATA;
        elsif (s_axi_arvalid = '1') then
          io_addr       <= s_axi_araddr(io_addrw_c+1 downto 2);
          --s_axi_arready <= '1';
          io_rd_en      <= '1';
          state <= S_WAITREAD;
        end if;

      when S_WAITWDATA =>
        s_axi_awready <= '0';        
        if (s_axi_wvalid = '1') then
          io_wr_en     <= '1';
          io_wr_data   <= s_axi_wdata;
          io_wr_mask   <= s_axi_wstrb;
          s_axi_wready <= '1';
          state        <= S_WAITDONE;
          wdcount      <= (others => '1');
        end if;
        
      when S_WAITDONE =>
        s_axi_wready   <= '0';
        wdcount        <= wdcount-1;
        s_axi_bresp  <= "00";         -- okay
        s_axi_bvalid <= '1';
        state        <= S_WAITBRESP;

      when S_WAITBRESP =>
        if (s_axi_bready = '1') then
          s_axi_bvalid <= '0';
          state        <= S_READY;
        end if;

      when S_WAITREAD =>
        state <= S_WAITDV;

      when S_WAITDV =>
        s_axi_rdata  <= io_rd_data;
        s_axi_rvalid <= '1';
        s_axi_rresp  <= "00";         --okay
        state <= S_WAITRREADY;
        s_axi_arready <= '1';

      when S_WAITRREADY =>
        if (s_axi_rready = '1') then
          s_axi_rvalid <= '0';
          state <= S_READY;
        end if;

    end case;
  end if;
  end process;
  
                      
end rtl;


