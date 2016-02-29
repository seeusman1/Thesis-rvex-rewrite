-------------------------------------------------------------------------------
-- Title      : Debugger control state machine
-- Project    : tta
-------------------------------------------------------------------------------
-- File       : dbsm-rtl.vhdl
-- Author     : Tommi Zetterman  <tommi.zetterman@nokia.com>
-- Company    : Nokia Research Center
-- Created    : 2013-03-19
-- Last update: 2014-11-28
-- Platform   :
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- Copyright (c) 2013 Nokia Research Center
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2013-03-19  1.0      zetterma	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.register_pkg.all;

architecture rtl of dbsm is
  signal lockrq_bppc : std_logic_vector(1 downto 0);
  signal lockrq_bpcc : std_logic;
  signal lockrq_forcebp : std_logic;
  signal lockrq_stdout  : std_logic;
  signal cyclecnt_next  : unsigned(cyclecnt'range);
begin

  bp_lockrq <= lockrq_stdout or lockrq_bpcc or lockrq_bppc(1) or lockrq_bppc(0) or lockrq_forcebp;
  bp_hit <= lockrq_stdout & lockrq_forcebp & lockrq_bppc & lockrq_bpcc;
  cyclecnt_next <= unsigned(cyclecnt)+1;
  -----------------------------------------------------------------------------
  -- bp#0
  -- assert lockrq when cycle count is hit.
  -- deassert lock when continu
  breakpoint0 : process(clk, nreset)
  begin
    if (nreset = '0') then
      lockrq_bpcc <= '0';
    elsif rising_edge(clk) then
      if (cyclecnt_next = unsigned(bp0) and bp_ena(0) = '1'
          and extlock = '0') then
        lockrq_bpcc <= '1';
      end if;
      if (tta_continue = '1') then
        lockrq_bpcc <= '0';
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- bp#1-#4
  breakpoints1_4 : process(clk, nreset)
  begin
    if (nreset = '0') then
      lockrq_bppc <= (others =>'0');
    elsif rising_edge(clk) then
      for i in 0 to 1 loop
        if (pc_next = bp4_1((i+1)*pc_width_g-1 downto i*pc_width_g)
            and bp_ena(i+1) = '1' and extlock = '0') then
          lockrq_bppc(i) <= '1';
        end if;
      end loop;
      if (tta_continue = '1') then
        lockrq_bppc <= (others => '0');
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- force break
  forcebreak : process(clk, nreset)
  begin
    if (nreset = '0') then
      lockrq_forcebp <= '0';
    elsif rising_edge(clk) then
      if (tta_forcebreak = '1') then
        lockrq_forcebp <= '1';
      end if;
      if (tta_continue = '1') then
        lockrq_forcebp <= '0';
      end if;
    end if;
  end process;

  ------------------------------------------------------------------------------
  -- stdout break
  stdout_proc : process(clk, nreset)
  begin
    if (nreset = '0') then
      lockrq_stdout <= '0';
    elsif rising_edge(clk) then
      if (tta_stdoutbreak = '1' and bp_ena(3) = '1') then
        lockrq_stdout <= '1';
      end if;
      if (tta_continue = '1') then
        lockrq_stdout <= '0';
      end if;
    end if;
  end process;

end rtl;
