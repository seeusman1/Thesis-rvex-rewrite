-- Copyright (c) 2002-2009 Tampere University of Technology.
--
-- This file is part of TTA-Based Codesign Environment (TCE).
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
-- Title      : testbench for TTA processor
-- Project    : FlexDSP
-------------------------------------------------------------------------------
-- File       : testbench.vhdl
-- Author     : Jaakko Sertamo  <sertamo@vlad.cs.tut.fi>
-- Company    : TUT/IDCS
-- Created    : 2001-07-13
-- Last update: 2007/04/03
-- Platform   : 
-------------------------------------------------------------------------------
-- Description: Simply resets the processor and triggers execution
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2001-07-13  1.0      sertamo Created
-------------------------------------------------------------------------------
library IEEE;
use IEEE.Std_Logic_1164.all;
use IEEE.numeric_std.all;
use work.tta0_globals.all;
use work.tta0_params.all;
use work.tta0_imem_mau.all;
use work.debugger_if.all;
use work.register_pkg.all;
use work.tce_util.all;
use std.textio.all;
use IEEE.std_logic_textio.all;
use work.misc.all;

entity tta_axislave_tb is
  generic (
    imem_image : string := "fib.img";
    gmem_image : string := "fib_data.img";
    clk_period : time := PERIOD);
end tta_axislave_tb;

architecture testbench of tta_axislave_tb is

  constant core_dbg_addrw : integer := 32;
  constant core_dbg_dataw : integer := 32;

  signal clk : std_logic := '0';
  signal nreset    : std_logic;

  constant io_addrw_c : integer := 2 + mmax(mmax(mmax(IMEMADDRWIDTH+1,debreg_addr_width_c),fu_LSU_addrw-2),fu_LSU_PARAM_addrw-2);
  constant IMEM_OFFSET : integer := 2**(io_addrw_c);
  constant DMEM_OFFSET : integer := (2**(io_addrw_c))*2;
  constant PMEM_OFFSET : integer := (2**(io_addrw_c))*3;

  -- AXI-lite interface
  signal s_axi_awaddr   :  STD_LOGIC_VECTOR (io_addrw_c+2-1 downto 0);
  signal s_axi_awvalid  :  STD_LOGIC;
  signal s_axi_awready  :  STD_LOGIC;
  signal s_axi_wdata    :  STD_LOGIC_VECTOR (31 downto 0);
  signal s_axi_wstrb    :  STD_LOGIC_VECTOR (3 downto 0);
  signal s_axi_wvalid   :  STD_LOGIC;
  signal s_axi_wready   :  STD_LOGIC;
  signal s_axi_bresp    :  STD_LOGIC_VECTOR (2-1 downto 0);
  signal s_axi_bvalid   :  STD_LOGIC;
  signal s_axi_bready   :  STD_LOGIC;
  signal s_axi_araddr   :  STD_LOGIC_VECTOR (io_addrw_c+2-1 downto 0);
  signal s_axi_arvalid  :  STD_LOGIC;
  signal s_axi_arready  :  STD_LOGIC;
  signal s_axi_rdata    :  STD_LOGIC_VECTOR (31 downto 0);
  signal s_axi_rresp    :  STD_LOGIC_VECTOR (2-1 downto 0);
  signal s_axi_rvalid   :  STD_LOGIC;
  signal s_axi_rready   :  STD_LOGIC;

    
begin

  clk <= not clk after PERIOD/2;

  dut : entity work.tta_axislave
    generic map (
      axi_addrw_g => io_addrw_c+2
      )
    port map (
      clk            => clk,
      nreset         => nreset,
      s_axi_awaddr  => s_axi_awaddr,
      s_axi_awvalid => s_axi_awvalid,
      s_axi_awready => s_axi_awready,
      s_axi_wdata   => s_axi_wdata,
      s_axi_wstrb   => s_axi_wstrb,
      s_axi_wvalid  => s_axi_wvalid,
      s_axi_wready  => s_axi_wready,
      s_axi_bresp   => s_axi_bresp,
      s_axi_bvalid  => s_axi_bvalid,
      s_axi_bready  => s_axi_bready,
      s_axi_araddr  => s_axi_araddr,
      s_axi_arvalid => s_axi_arvalid,
      s_axi_arready => s_axi_arready,
      s_axi_rdata   => s_axi_rdata,
      s_axi_rresp   => s_axi_rresp,
      s_axi_rvalid  => s_axi_rvalid,
      s_axi_rready  => s_axi_rready
      );


  run_test : process

    procedure axi_write (address : in integer;
                         value : in std_logic_vector(core_dbg_dataw - 1 downto 0)) is

      variable addr_vec : std_logic_vector(core_dbg_addrw - 1 downto 0)
        := std_logic_vector(to_unsigned(address, core_dbg_addrw));

    begin

      s_axi_awvalid <= '1';
      s_axi_awaddr <= tce_ext(addr_vec, io_addrw_c+2);

      while s_axi_awready = '0' loop
        wait until rising_edge(clk);
      end loop;
      s_axi_awvalid <= '0';
      s_axi_wvalid <= '1';
      s_axi_wdata <= value;
      while s_axi_wready = '0' loop
        wait until rising_edge(clk);
      end loop;
      s_axi_wvalid <= '0';
      wait until rising_edge(clk);

      s_axi_wvalid <= '0';
      s_axi_awvalid <= '0';

    end procedure axi_write;

    procedure dbg_command (command : in integer) is
      variable cmdreg : std_logic_vector(core_dbg_dataw - 1 downto 0) := (others => '0');
    begin
      cmdreg(command) := '1';
      axi_write(TTA_DEBUG_CMD*4, cmdreg);
    end procedure dbg_command;

    procedure axi_read (constant address : in integer;
                        variable value : out std_logic_vector(core_dbg_dataw - 1 downto 0)) is

      variable addr_vec : std_logic_vector(core_dbg_addrw - 1 downto 0)
        := std_logic_vector(to_unsigned(address, core_dbg_addrw));

    begin

      s_axi_arvalid <= '1';
      s_axi_araddr <= tce_ext(addr_vec, io_addrw_c+2);
      while s_axi_arready = '0' loop
        wait until rising_edge(clk);
      end loop;
      s_axi_arvalid <= '0';
      --s_axi_awvalid <= '0';

      while s_axi_rvalid = '0' loop
        wait until rising_edge(clk);
      end loop;
      value := s_axi_rdata;
      wait until rising_edge(clk);

    end procedure axi_read;
-- 
    
    type imem_slv_array is array (natural range <>) of
      std_logic_vector (IMEMDATAWIDTH-1 downto 0);
    variable imem_r : imem_slv_array (0 to 2**IMEMADDRWIDTH-1);
    variable imem_word : std_logic_vector(IMEMDATAWIDTH-1 downto 0);
    --type gmem_slv_array is array (natural range <>) of
    --  std_logic_vector (IMEMDATAWIDTH-1 downto 0);
    --signal gmem_r : imem_slv_array (0 to 2**IMEMADDRWIDTH-1);
    variable gmem_word_from_file : std_logic_vector(IMEMDATAWIDTH-1 downto 0);
    variable i : integer;
    variable good : boolean;
    file mem_init              : text;
    variable line_in           : line;
    variable value : std_logic_vector(31 downto 0);
  begin
      nreset <= '0';
      
      s_axi_wvalid <= '0';
      s_axi_arvalid <= '0';
      s_axi_awvalid <= '0';
      s_axi_rready <= '1';
      s_axi_bready <= '1';
      s_axi_wstrb <= (others=>'1');


      wait until rising_edge(clk);
      wait until rising_edge(clk);

      nreset <= '1';

      wait until rising_edge(clk);
      wait until rising_edge(clk);
      wait until rising_edge(clk);

      i := 0;
      file_open(mem_init, imem_image, read_mode);
      while (not endfile(mem_init) and i < imem_r'length) loop
        readline(mem_init, line_in);
        read(line_in, imem_word, good);
        assert good
          report "Read error in memory initialization file"
          severity failure;

        axi_write(i*8   + IMEM_OFFSET, imem_word(31 downto 0));
        axi_write(i*8+4 + IMEM_OFFSET, tce_ext(imem_word(imem_word'high downto 32), 32));

        i        := i+1;
      end loop;

      assert (not good)
        report "Memory initialization succesful"
        severity note;

    -- Zero-initialize parameter memory
    for i in 0 to 2**(fu_LSU_PARAM_addrw-2)-1 loop
      axi_write(PMEM_OFFSET+i*4, (others=>'0'));
    end loop;

    axi_read(TTA_CYCLECNT*4, value);
    axi_read(TTA_DEVICECLASS*4, value);
    axi_read(TTA_DEVICE_ID*4, value);
    axi_read(TTA_INTERFACE_TYPE*4, value);
    axi_read(TTA_DMEM_SIZE*4, value);
    assert False report "DMEM size: " & integer'image(to_integer(unsigned(value))) severity Note;
    axi_read(TTA_PMEM_SIZE*4, value);
    assert False report "PMEM size: " & integer'image(to_integer(unsigned(value))) severity Note;
    axi_read(TTA_IMEM_SIZE*4, value);
    assert False report "IMEM size: " & integer'image(to_integer(unsigned(value))) severity Note;

    -- Lift softreset
    dbg_command(DEBUG_CMD_CONTINUE);

    value := (others=>'0');
    while value(0) = '0' loop
      -- Generate some dmem traffic to test whether access conflicts work...
      axi_read(DMEM_OFFSET+0, value);
      axi_read(DMEM_OFFSET+0, value);
      axi_read(DMEM_OFFSET+0, value);

      -- Poll program completion
      axi_read(PMEM_OFFSET+4, value);
    end loop;

    axi_read(TTA_CYCLECNT*4, value);

    assert False report "Cycle count: " & integer'image(to_integer(unsigned(value))) severity Note;

    assert False report "Simulation complete." severity failure;

    wait;
  end process;
  
end testbench;

