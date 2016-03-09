-- Copyright (c) 2016 Tampere University of Technology
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
-----------------------------------------------------------------------------
-- Title      : Example ALMARVI interface TTA 
-- Project    : 
-------------------------------------------------------------------------------
-- File       : tta-accel-rtl.vhdl
-- Author     : Viitanen Timo (Tampere University of Technology)  <timo.2.viitanen@tut.fi>
-- Company    : 
-- Created    : 2016-01-27
-- Last update: 2016-01-27
-- Platform   : 
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2015 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2016-01-27  1.0      viitanet	Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.tta0_globals.all;
use work.tta0_params.all;
use work.tta0_imem_mau.all;
use work.debugger_if.all;

use work.misc.all;

architecture rtl of tta_accel is

  constant dataw_c      : integer := 32;  -- one memory bank

  -- Round up instruction word width to next multiple of 8
  constant imem_dataw_c : integer := ((IMEMDATAWIDTH+7)/8)*8;
  
  signal tta0_busy                : std_logic;
  signal tta0_imem_en_x           : std_logic;
  signal tta0_imem_addr           : std_logic_vector(IMEMADDRWIDTH-1 downto 0);
  signal tta0_imem_data           : std_logic_vector(IMEMDATAWIDTH-1 downto 0);
  signal tta0_pc_init             : std_logic_vector(IMEMADDRWIDTH-1 downto 0);
  signal tta0_fu_stdout_db_data   : std_logic_vector(fu_stdout_dataw-1 downto 0);
  signal tta0_fu_stdout_db_ndata  : std_logic_vector(fu_stdout_addrw-1 downto 0);
  signal tta0_fu_stdout_db_lockrq : std_logic_vector(0 downto 0);
  signal tta0_fu_stdout_db_read   : std_logic_vector(0 downto 0);
  signal tta0_fu_stdout_db_nreset : std_logic_vector(0 downto 0);
  signal tta0_fu_LSU_addr        : std_logic_vector((fu_LSU_addrw-2)-1 downto 0);
  signal tta0_fu_LSU_en_x          : std_logic_vector(0 downto 0);
  signal tta0_fu_LSU_we_x          : std_logic_vector(0 downto 0);
  signal tta0_fu_LSU_en          : std_logic_vector(0 downto 0);
  signal tta0_fu_LSU_we          : std_logic_vector(0 downto 0);
  signal tta0_fu_LSU_bena        : std_logic_vector(fu_LSU_dataw/8-1 downto 0);
  signal tta0_fu_LSU_wr_mask_x   : std_logic_vector(fu_LSU_dataw-1 downto 0);
  signal tta0_fu_LSU_rd_data     : std_logic_vector(fu_LSU_dataw-1 downto 0);
  signal tta0_fu_LSU_wr_data     : std_logic_vector(fu_LSU_dataw-1 downto 0);
  signal tta0_fu_LSU_PARAM_addr        : std_logic_vector((fu_LSU_PARAM_addrw-2)-1 downto 0);
  signal tta0_fu_LSU_PARAM_en_x          : std_logic_vector(0 downto 0);
  signal tta0_fu_LSU_PARAM_we_x          : std_logic_vector(0 downto 0);
  signal tta0_fu_LSU_PARAM_en          : std_logic_vector(0 downto 0);
  signal tta0_fu_LSU_PARAM_we          : std_logic_vector(0 downto 0);
  signal tta0_fu_LSU_PARAM_bena        : std_logic_vector(fu_LSU_PARAM_dataw/8-1 downto 0);
  signal tta0_fu_LSU_PARAM_wr_mask_x   : std_logic_vector(fu_LSU_PARAM_dataw-1 downto 0);
  signal tta0_fu_LSU_PARAM_rd_data     : std_logic_vector(fu_LSU_PARAM_dataw-1 downto 0);
  signal tta0_fu_LSU_PARAM_wr_data     : std_logic_vector(fu_LSU_PARAM_dataw-1 downto 0);
  signal tta0_db_pc_start         : std_logic_vector(IMEMADDRWIDTH-1 downto 0);
  signal tta0_db_pc               : std_logic_vector(IMEMADDRWIDTH-1 downto 0);
  signal tta0_db_bustraces        : std_logic_vector(debreg_data_width_c*debreg_nof_bustraces_c-1 downto 0);
  signal tta0_db_instr            : std_logic_vector(IMEMWIDTHINMAUS*IMEMMAUWIDTH-1 downto 0);
  signal tta0_db_lockcnt          : std_logic_vector(debreg_data_width_c-1 downto 0);
  signal tta0_db_cyclecnt         : std_logic_vector(debreg_data_width_c-1 downto 0);
  signal tta0_db_bp_ena           : std_logic_vector(1+debreg_nof_breakpoints_c-1 downto 0);
  signal tta0_db_bp0              : std_logic_vector(debreg_data_width_c-1 downto 0);
  signal tta0_db_bp4_1            : std_logic_vector(debreg_nof_breakpoints_pc_c*IMEMADDRWIDTH-1 downto 0);
  signal tta0_db_bp_hit           : std_logic_vector(2+debreg_nof_breakpoints_c-1 downto 0);
  signal tta0_db_tta_continue     : std_logic;
  signal tta0_db_tta_nreset       : std_logic;
  signal tta0_db_tta_forcebreak   : std_logic;
  signal tta0_db_tta_stdoutbreak  : std_logic;

  -- stdout beffer memory interface
  signal tta0_fu_stdout_mem_ena   : std_logic_vector(0 downto 0);
  signal tta0_fu_stdout_mem_enb   : std_logic_vector(0 downto 0);
  signal tta0_fu_stdout_mem_wea   : std_logic_vector(0 downto 0);
  signal tta0_fu_stdout_mem_addra : std_logic_vector(fu_stdout_addrw-1 downto 0);
  signal tta0_fu_stdout_mem_addrb : std_logic_vector(fu_stdout_addrw-1 downto 0);
  signal tta0_fu_stdout_mem_dia   : std_logic_vector(fu_stdout_dataw-1 downto 0);
  signal tta0_fu_stdout_mem_dob   : std_logic_vector(fu_stdout_dataw-1 downto 0);

  signal dbg_wen_fpga       : std_logic;
  signal dbg_ren_fpga       : std_logic;
  signal dbg_addr_fpga      : std_logic_vector(debreg_addr_width_c-1 downto 0);
  signal dbg_din_fpga       : std_logic_vector(debreg_data_width_c-1 downto 0);
  signal dbg_dout_fpga      : std_logic_vector(debreg_data_width_c-1 downto 0);
  signal dbg_dv_fpga        : std_logic;
  signal dbg_pc_start       : std_logic_vector(debreg_pc_width_c-1 downto 0);
  signal dbg_pc             : std_logic_vector(debreg_pc_width_c-1 downto 0);
  signal dbg_bustraces      : std_logic_vector(debreg_nof_bustraces_c *
                                          debreg_data_width_c-1 downto 0);
  signal dbg_lockcnt        : std_logic_vector(debreg_data_width_c-1 downto 0);
  signal dbg_cyclecnt       : std_logic_vector(debreg_data_width_c-1 downto 0);
  signal dbg_flags          : std_logic_vector(debreg_data_width_c-1 downto 0);
  signal dbg_bp_ena         : std_logic_vector(1+debreg_nof_breakpoints_c-1
                                               downto 0);
  signal dbg_bp0            : std_logic_vector(debreg_data_width_c-1 downto 0);
  signal dbg_bp4_1          : std_logic_vector((debreg_nof_breakpoints_c-1) *
                                          debreg_pc_width_c - 1 downto 0);
  signal dbg_bp_hit         : std_logic_vector(2+debreg_nof_breakpoints_c-1
                                               downto 0);
  signal dbg_tta_continue   : std_logic;
  signal dbg_tta_nreset     : std_logic;
  signal dbg_tta_forcebreak : std_logic;
  signal dbg_irq            : std_logic;
  signal dbg_busy           : std_logic;
  signal dbg_imem_page      : std_logic_vector(debreg_data_width_c-1 downto 0);
  signal dbg_imem_mask      : std_logic_vector(debreg_data_width_c-1 downto 0);
  signal dbg_dmem_page      : std_logic_vector(debreg_data_width_c-1 downto 0);
  signal dbg_dmem_mask      : std_logic_vector(debreg_data_width_c-1 downto 0);
  signal dbg_icache_invalidate : std_logic;
  signal dbg_dcache_invalidate : std_logic;
  signal dbg_axi_burst_cnt     : std_logic_vector(3*32-1 downto 0);
  signal dbg_axi_err_cnt       : std_logic_vector(3*32-1 downto 0);
  signal dbg_db_stdout_d       : std_logic_vector(fu_stdout_dataw-1 downto 0);
  signal dbg_db_stdout_n       : std_logic_vector(fu_stdout_addrw-1 downto 0);
  signal dbg_db_stdout_read    : std_logic;
  
  -- shared memory
  signal dmem_rdata :  std_logic_vector(31 downto 0);
  signal dmem_wdata :  std_logic_vector(31 downto 0);
  signal dmem_wstrb :  std_logic_vector(32/8-1 downto 0);
  signal dmem_addr  :  std_logic_vector(fu_LSU_addrw-2-1 downto 0);
  signal dmem_cs    :  std_logic;
  signal dmem_we    :  std_logic;
  -- parameter memory
  signal pmem_rdata :  std_logic_vector(31 downto 0);
  signal pmem_wdata :  std_logic_vector(31 downto 0);
  signal pmem_wstrb :  std_logic_vector(32/8-1 downto 0);
  signal pmem_addr  :  std_logic_vector(fu_LSU_PARAM_addrw-2-1 downto 0);
  signal pmem_cs    :  std_logic;
  signal pmem_we    :  std_logic;
  -- instruction memory
  signal imem_rdata  :  std_logic_vector(imem_dataw_c-1 downto 0);
  signal imem_wdata  :  std_logic_vector(64-1 downto 0);
  signal imem_wstrb  :  std_logic_vector(64/8-1 downto 0);
  signal imem_addr   :  std_logic_vector(IMEMADDRWIDTH-1 downto 0);
  signal imem_en     :  std_logic;
  signal imem_we     :  std_logic;
  -- std buffer memory
  signal stdout_mem_ena   :  std_logic;
  signal stdout_mem_enb   :  std_logic;
  signal stdout_mem_wea   :  std_logic;
  signal stdout_mem_addra :  std_logic_vector(fu_stdout_addrw-1 downto 0);
  signal stdout_mem_addrb :  std_logic_vector(fu_stdout_addrw-1 downto 0);
  signal stdout_mem_dia   :  std_logic_vector(fu_stdout_dataw-1 downto 0);
  signal stdout_mem_dob   : std_logic_vector(fu_stdout_dataw-1 downto 0); 

  signal io_active : std_logic;
  signal io_active_delay : std_logic;
  signal io_target_memory : std_logic_vector(1 downto 0);
  signal io_target_memory_delay : std_logic_vector(1 downto 0);
  constant IO_CTRL : std_logic_vector(1 downto 0) := "00";
  constant IO_IMEM : std_logic_vector(1 downto 0) := "01";
  constant IO_DMEM : std_logic_vector(1 downto 0) := "10";
  constant IO_PMEM : std_logic_vector(1 downto 0) := "11";
  signal saved_tta_dmem_addr : std_logic_vector((fu_LSU_addrw-2)-1 downto 0);
  signal saved_tta_dmem_bena :  std_logic_vector(32/8-1 downto 0);
  signal saved_tta_dmem_wdata : std_logic_vector(31 downto 0);
  signal saved_tta_dmem_we : std_logic;
  signal saved_tta_dmem_cs : std_logic;
  signal saved_tta_pmem_addr : std_logic_vector((fu_LSU_PARAM_addrw-2)-1 downto 0);
  signal saved_tta_pmem_bena :  std_logic_vector(32/8-1 downto 0);
  signal saved_tta_pmem_wdata : std_logic_vector(31 downto 0);
  signal saved_tta_pmem_we : std_logic;
  signal saved_tta_pmem_cs : std_logic;
  signal lock_tta_dmem, lock_tta_pmem, lock_tta, tta_locked : std_logic;

begin

  -----------------------------------------------------------------------------
  -- tta0
  -----------------------------------------------------------------------------
  tta0_1: entity work.tta0
    port map (
      clk                 => clk,
      rstx                => nreset,
      busy                => tta0_busy,
      imem_en_x           => tta0_imem_en_x,
      imem_addr           => tta0_imem_addr,
      imem_data           => tta0_imem_data,
      pc_init             => tta0_pc_init,
      fu_stdout_db_ndata  => tta0_fu_stdout_db_ndata,
      fu_stdout_db_lockrq => tta0_fu_stdout_db_lockrq,
      fu_stdout_db_read   => tta0_fu_stdout_db_read,
      fu_stdout_db_nreset => tta0_fu_stdout_db_nreset,
      fu_stdout_db_data   => tta0_fu_stdout_db_data,
      fu_LSU_data_in      => tta0_fu_LSU_rd_data,
      fu_LSU_data_out     => tta0_fu_LSU_wr_data,
      fu_LSU_addr         => tta0_fu_LSU_addr,
      fu_LSU_mem_en_x     => tta0_fu_LSU_en_x,
      fu_LSU_wr_en_x      => tta0_fu_LSU_we_x,
      fu_LSU_wr_mask_x    => tta0_fu_LSU_wr_mask_x,
      fu_LSU_PARAM_data_in      => tta0_fu_LSU_PARAM_rd_data,
      fu_LSU_PARAM_data_out     => tta0_fu_LSU_PARAM_wr_data,
      fu_LSU_PARAM_addr         => tta0_fu_LSU_PARAM_addr,
      fu_LSU_PARAM_mem_en_x     => tta0_fu_LSU_PARAM_en_x,
      fu_LSU_PARAM_wr_en_x      => tta0_fu_LSU_PARAM_we_x,
      fu_LSU_PARAM_wr_mask_x    => tta0_fu_LSU_PARAM_wr_mask_x,
      fu_STDOUT_mem_ena         => tta0_fu_STDOUT_mem_ena,
      fu_STDOUT_mem_enb         => tta0_fu_STDOUT_mem_enb,
      fu_STDOUT_mem_wea         => tta0_fu_STDOUT_mem_wea,
      fu_STDOUT_mem_addra       => tta0_fu_STDOUT_mem_addra,
      fu_STDOUT_mem_addrb       => tta0_fu_STDOUT_mem_addrb,
      fu_STDOUT_mem_dia         => tta0_fu_STDOUT_mem_dia,
      fu_STDOUT_mem_dob         => tta0_fu_STDOUT_mem_dob,
      db_pc_start         => tta0_db_pc_start,
      db_pc               => tta0_db_pc,
      db_bustraces        => tta0_db_bustraces,
      db_instr            => tta0_db_instr,
      db_lockcnt          => tta0_db_lockcnt,
      db_cyclecnt         => tta0_db_cyclecnt,
      db_bp_ena           => tta0_db_bp_ena,
      db_bp0              => tta0_db_bp0,
      db_bp4_1            => tta0_db_bp4_1,
      db_bp_hit           => tta0_db_bp_hit,
      db_tta_continue     => tta0_db_tta_continue,
      db_tta_nreset       => tta0_db_tta_nreset,
      db_tta_forcebreak   => tta0_db_tta_forcebreak,
      db_tta_stdoutbreak  => tta0_db_tta_stdoutbreak);

  tta0_fu_LSU_en <= not tta0_fu_LSU_en_x;
  tta0_fu_LSU_we <= not tta0_fu_LSU_we_x;
  dmem_bitmask : for i in 0 to fu_LSU_dataw/8-1 generate
    tta0_fu_LSU_bena(i) <= not tta0_fu_LSU_wr_mask_x(i*8);
  end generate;

  tta0_fu_LSU_PARAM_en <= not tta0_fu_LSU_PARAM_en_x;
  tta0_fu_LSU_PARAM_we <= not tta0_fu_LSU_PARAM_we_x;
  pmem_bitmask : for i in 0 to fu_LSU_PARAM_dataw/8-1 generate
    tta0_fu_LSU_PARAM_bena(i) <= not tta0_fu_LSU_PARAM_wr_mask_x(i*8);
  end generate;

  -- stdout buffer memory interface
  stdout_mem_ena   <= tta0_fu_stdout_mem_ena(0);
  stdout_mem_enb   <= tta0_fu_stdout_mem_enb(0);                         
  stdout_mem_wea   <= tta0_fu_stdout_mem_wea(0);
  stdout_mem_addra <= tta0_fu_stdout_mem_addra;
  stdout_mem_addrb <= tta0_fu_stdout_mem_addrb;
  stdout_mem_dia   <= tta0_fu_stdout_mem_dia;
  tta0_fu_stdout_mem_dob <= stdout_mem_dob;

--  tta0_fu_LSUP_rd_data     <= pmem0_1_rdata & pmem0_0_rdata;
  tta0_fu_LSU_rd_data      <= dmem_rdata;
  tta0_fu_LSU_PARAM_rd_data <= pmem_rdata;
  tta0_imem_data           <= imem_rdata(tta0_imem_data'range);
  tta0_fu_stdout_db_read(0) <= dbg_db_stdout_read;
  tta0_pc_init             <= dbg_pc_start;
  tta0_busy                <= '0';  -- no memory blocking
  tta0_fu_stdout_db_nreset(0) <= dbg_tta_nreset;
  tta0_db_pc_start         <= dbg_pc_start;
  tta0_db_bp_ena           <= dbg_bp_ena;
  tta0_db_bp0              <= dbg_bp0;
  tta0_db_bp4_1            <= dbg_bp4_1;
  tta0_db_tta_continue     <= dbg_tta_continue;
  tta0_db_tta_nreset       <= dbg_tta_nreset;
  tta0_db_tta_forcebreak   <= dbg_tta_forcebreak;
  tta0_db_tta_stdoutbreak  <= tta0_fu_stdout_db_lockrq(0);
  

  ------------------------------------------------------------------------------
  -- Debugger
  ------------------------------------------------------------------------------
  debugger_1: entity work.debugger
    generic map (
      data_width_g    => debreg_data_width_c,
      addr_width_g    => debreg_addr_width_c,
      nof_bustraces_g => debreg_nof_bustraces_c,
      stdout_dataw_g  => fu_stdout_dataw, 
      stdout_addrw_g  => fu_stdout_addrw,
      use_cdc_g       => false
      )
    port map (
      nreset            => nreset,
      clk_fpga          => clk,
      wen_fpga          => dbg_wen_fpga,
      ren_fpga          => dbg_ren_fpga,
      addr_fpga         => dbg_addr_fpga,
      din_fpga          => dbg_din_fpga,
      dout_fpga         => dbg_dout_fpga,
      dv_fpga           => dbg_dv_fpga,
      clk_tta           => clk,
      pc_start          => dbg_pc_start,
      pc                => dbg_pc,
      bustraces         => dbg_bustraces,
      lockcnt           => dbg_lockcnt,
      cyclecnt          => dbg_cyclecnt,
      flags             => dbg_flags,
      bp_ena            => dbg_bp_ena,
      bp0               => dbg_bp0,
      bp4_1             => dbg_bp4_1,
      bp_hit            => dbg_bp_hit,
      tta_continue      => dbg_tta_continue,
      tta_nreset        => dbg_tta_nreset,
      tta_forcebreak    => dbg_tta_forcebreak,
      irq               => dbg_irq,
      busy              => dbg_busy,
      imem_page         => dbg_imem_page,
      imem_mask         => dbg_imem_mask,
      dmem_page         => dbg_dmem_page,
      dmem_mask         => dbg_dmem_mask,
      icache_invalidate => dbg_icache_invalidate,
      dcache_invalidate => dbg_dcache_invalidate,
      axi_burst_cnt     => dbg_axi_burst_cnt,
      axi_err_cnt       => dbg_axi_err_cnt,
      -- stdout
      db_stdout_d       => dbg_db_stdout_d,
      db_stdout_n       => dbg_db_stdout_n,
      db_stdout_read    => dbg_db_stdout_read
      );

  dbg_pc            <= tta0_db_pc;
  dbg_bustraces     <= tta0_db_bustraces;
  dbg_lockcnt       <= tta0_db_lockcnt;
  dbg_cyclecnt      <= tta0_db_cyclecnt;
  dbg_flags         <= (others => '0');
  dbg_bp_hit        <= tta0_db_bp_hit;
  dbg_axi_burst_cnt <= (others => '0');
  dbg_db_stdout_d   <= tta0_fu_stdout_db_data;  
  dbg_db_stdout_n   <= tta0_fu_stdout_db_ndata;
  
  dbg_axi_err_cnt <= (others => '0');


  ------------------------------------------------------------------------------
  -- Data memory
  ------------------------------------------------------------------------------
  dmem : entity work.blockram_be
    generic map (
      addrw => fu_LSU_addrw-2,
      dataw => dataw_c)
    port map (
      clk  => clk,
      we   => dmem_we,
      en   => dmem_cs,
      addr => dmem_addr,
      di   => dmem_wdata,
      do   => dmem_rdata,
      bena => dmem_wstrb);


  ------------------------------------------------------------------------------
  -- Parameter memory
  ------------------------------------------------------------------------------
  pmem : entity work.blockram_be
    generic map (
      addrw => fu_LSU_PARAM_addrw-2,
      dataw => dataw_c)
    port map (
      clk  => clk,
      we   => pmem_we,
      en   => pmem_cs,
      addr => pmem_addr,
      di   => pmem_wdata,
      do   => pmem_rdata,
      bena => pmem_wstrb);


  ------------------------------------------------------------------------------
  -- Instruction memory
  ------------------------------------------------------------------------------
  imem : entity work.blockram_be
    generic map (
      addrw => IMEMADDRWIDTH,
      dataw => imem_dataw_c)
    port map (
      clk  => clk,
      we   => imem_we,
      en   => imem_en,
      addr => imem_addr,
      di   => imem_wdata(imem_dataw_c-1 downto 0),
      do   => imem_rdata,
      bena => imem_wstrb(imem_dataw_c/8-1 downto 0)
    );


  ------------------------------------------------------------------------------
  -- Text output buffer
  ------------------------------------------------------------------------------
  stdout_buff_mem : entity work.simple_dual_one_clock
    generic map (
      addrw => fu_stdout_addrw,
      dataw => fu_stdout_dataw)
    port map (
      clk   => clk,
      ena   => stdout_mem_ena,
      enb   => stdout_mem_enb,
      wea   => stdout_mem_wea,
      addra => stdout_mem_addra,
      addrb => stdout_mem_addrb,
      dia   => stdout_mem_dia,
      dob   => stdout_mem_dob);
                                                 

  ------------------------------------------------------------------------------
  -- Memory arbitration between IO and TTA
  ------------------------------------------------------------------------------
  io_target_memory <= io_addr(io_addrw_g-1 downto io_addrw_g-2);
  io_active <= io_wr_en or io_rd_en;
  
  io_regs : process(clk, nreset) is
  begin
    if (nreset = '0') then
      io_active_delay <= '0';
      io_target_memory_delay <= "00";
      tta_locked <= '0';
    elsif (rising_edge(clk)) then
      io_active_delay <= io_active;
      io_target_memory_delay <= io_target_memory;
      tta_locked <= lock_tta;
    end if;
  end process;
  lock_tta <= lock_tta_dmem or lock_tta_pmem;

  dbg_io_interface : process(io_target_memory, io_active, io_rd_en, io_wr_en) is
  begin 
    dbg_ren_fpga <= '1';
    dbg_wen_fpga <= '1';
    if    io_target_memory = IO_CTRL and io_active = '1' then
      -- debugger read
      if (io_rd_en = '1') then
        dbg_ren_fpga <= '0';
      end if;
      -- debugger write
      if (io_wr_en = '1') then
        dbg_wen_fpga <= '0';
      end if;
    end if;
  end process;
  dbg_addr_fpga <= io_addr(debreg_addr_width_c-1 downto 0);
  dbg_din_fpga <= io_wr_data;

  -- Dmem & Pmem interfaces are designed to always give single-cycle access to the AXI I/O.
  -- -> In case of access conflict, TTA stalls (via lock_tta signal), and the TTA's memory request is
  --    saved (saved_tta_dmem_*) and retried before resuming execution.
  -- TODO: multi-cycle AXI access in case of conflict would make a simpler example implementation..

  dmem_io_interface : process(io_target_memory, io_active, io_wr_en, io_rd_en, io_addr,
                              saved_tta_dmem_addr, tta0_fu_LSU_we, tta0_fu_LSU_en, tta0_fu_LSU_addr,
                              tta0_fu_LSU_wr_data, tta0_fu_LSU_bena, tta_locked) is
  begin 
    lock_tta_dmem <= '0';

    if io_target_memory = IO_DMEM and io_active = '1' then
      if tta0_fu_LSU_en = "1" then
        lock_tta_dmem <= '1';
      end if;
      dmem_we <= io_wr_en;
      dmem_cs <= io_wr_en or io_rd_en;
      dmem_addr <= io_addr(fu_LSU_addrw-2-1 downto 0);
      dmem_wdata <= io_wr_data;
      dmem_wstrb <= io_wr_mask;
    elsif tta_locked ='1' then
      dmem_we <= saved_tta_dmem_we;
      dmem_cs <= saved_tta_dmem_cs;
      dmem_addr <= saved_tta_dmem_addr;
      dmem_wdata <= saved_tta_dmem_wdata;
      dmem_wstrb <= saved_tta_dmem_bena;
    else
      dmem_we <= tta0_fu_LSU_we(0);
      dmem_cs <= tta0_fu_LSU_en(0);
      dmem_addr <= tta0_fu_LSU_addr;
      dmem_wdata <= tta0_fu_LSU_wr_data;
      dmem_wstrb <= tta0_fu_LSU_bena;
    end if;
  end process;

  dmem_io_interface_regs : process(clk, nreset) is
  begin
    if (nreset = '0') then
      saved_tta_dmem_addr <= (others=>'0');
      saved_tta_dmem_wdata <= (others=>'0');
      saved_tta_dmem_bena <= (others=>'0');
      saved_tta_dmem_we <= '0';
      saved_tta_dmem_cs <= '0';
    elsif (rising_edge(clk)) then
      if tta0_fu_LSU_en = "1" and lock_tta = '1' then
        saved_tta_dmem_addr <= tta0_fu_LSU_addr;
        saved_tta_dmem_wdata <= tta0_fu_LSU_wr_data;
        saved_tta_dmem_bena <= tta0_fu_LSU_bena;
        saved_tta_dmem_we <= tta0_fu_LSU_we(0);
        saved_tta_dmem_cs <= tta0_fu_LSU_en(0);
      end if;
    end if;
  end process;

  pmem_io_interface : process(io_target_memory, io_active, io_wr_en, io_rd_en, io_addr,
                              saved_tta_pmem_addr, tta0_fu_LSU_PARAM_we, tta0_fu_LSU_PARAM_en, tta0_fu_LSU_PARAM_addr,
                              tta0_fu_LSU_PARAM_wr_data, tta0_fu_LSU_PARAM_bena, tta_locked) is
  begin 
    lock_tta_pmem <= '0';

    if io_target_memory = IO_PMEM and io_active = '1' then
      if tta0_fu_LSU_PARAM_en = "1" then
        lock_tta_pmem <= '1';
      end if;
      pmem_we <= io_wr_en;
      pmem_cs <= io_wr_en or io_rd_en;
      pmem_addr <= io_addr(fu_LSU_PARAM_addrw-2-1 downto 0);
      pmem_wdata <= io_wr_data;
      pmem_wstrb <= io_wr_mask;
    elsif tta_locked ='1' then
      pmem_we <= saved_tta_pmem_we;
      pmem_cs <= saved_tta_pmem_cs;
      pmem_addr <= saved_tta_pmem_addr;
      pmem_wdata <= saved_tta_pmem_wdata;
      pmem_wstrb <= saved_tta_pmem_bena;
    else
      pmem_we <= tta0_fu_LSU_PARAM_we(0);
      pmem_cs <= tta0_fu_LSU_PARAM_en(0);
      pmem_addr <= tta0_fu_LSU_PARAM_addr;
      pmem_wdata <= tta0_fu_LSU_PARAM_wr_data;
      pmem_wstrb <= tta0_fu_LSU_PARAM_bena;
    end if;
  end process;

  pmem_io_interface_regs : process(clk, nreset) is
  begin
    if (nreset = '0') then
      saved_tta_pmem_addr <= (others=>'0');
      saved_tta_pmem_wdata <= (others=>'0');
      saved_tta_pmem_bena <= (others=>'0');
      saved_tta_pmem_we <= '0';
      saved_tta_pmem_cs <= '0';
    elsif (rising_edge(clk)) then
      if tta0_fu_LSU_PARAM_en = "1" and lock_tta = '1' then
        saved_tta_pmem_addr <= tta0_fu_LSU_PARAM_addr;
        saved_tta_pmem_wdata <= tta0_fu_LSU_PARAM_wr_data;
        saved_tta_pmem_bena <= tta0_fu_LSU_PARAM_bena;
        saved_tta_pmem_we <= tta0_fu_LSU_PARAM_we(0);
        saved_tta_pmem_cs <= tta0_fu_LSU_PARAM_en(0);
      end if;
    end if;
  end process;

  imem_io_interface : process(io_target_memory, io_active, io_addr, tta0_imem_addr) is
  begin 
    imem_wstrb <= (others=>'0');

    if io_target_memory = IO_IMEM and io_wr_en = '1' then
      imem_addr <= io_addr(IMEMADDRWIDTH downto 1);
      imem_we <= '1';

      --TODO allow other instruction widths than 33..64
      if io_addr(0) = '0' then
        imem_wstrb(3 downto 0) <= io_wr_mask;
      else
        imem_wstrb(7 downto 4) <= io_wr_mask;
      end if;
    else
      imem_addr <= tta0_imem_addr;
      imem_we <= '0';
    end if;
  end process;
  imem_en <= '1';
  imem_wdata(31 downto 0) <= io_wr_data;
  imem_wdata(63 downto 32) <= io_wr_data;

  io_read_result : process(io_target_memory_delay, dbg_dout_fpga, dmem_rdata, pmem_rdata) is
  begin
    if    io_target_memory_delay = IO_CTRL then
      io_rd_data <= dbg_dout_fpga;
    elsif io_target_memory_delay = IO_DMEM then
      io_rd_data <= dmem_rdata;
    elsif io_target_memory_delay = IO_PMEM then
      io_rd_data <= pmem_rdata;
    else  -- IO_IMEM
      -- Write-only IMEM
      io_rd_data <= (others=>'0');
    end if;
  end process;
  
end architecture rtl;


