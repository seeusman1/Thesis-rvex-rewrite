-------------------------------------------------------------------------------
-- Title      : stdout implementation supporting debugger read
-- Project    : 
-------------------------------------------------------------------------------
-- File       : stdout_db.vhdl
-- Author     : Tommi Zetterman  <tommi.zetterman@nokia.com>
-- Company    : Nokia
-- Created    : 2014-11-27
-- Last update: 2015-10-06
-- Platform   : 
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Triggering stdout causes outgoing lockrq to be asserted
--              for one clock cycle.
-------------------------------------------------------------------------------
-- Copyright (c) 2014 Nokia
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2014-11-27  1.0      zetterma	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;


entity stdout_db is
  generic (
    dataw : integer := 32;
    buffd : integer := 64;
    addrw : integer := 6    
  );
  port (
    t1data : in std_logic_vector(dataw-1 downto 0);
    t1load : in std_logic;
    rstx   : in std_logic;
    glock  : in std_logic;
    clk    : in std_logic;
    -- debugger interface
    db_data   : out std_logic_vector(dataw-1 downto 0);
    -- nof data available in buffer
    db_ndata  : out std_logic_vector(addrw-1 downto 0);
    db_lockrq : out std_logic_vector(0 downto 0);
    db_read   : in std_logic_vector(0 downto 0);
    db_nreset : in std_logic_vector(0 downto 0); -- software reset from debugger
    -- memory interface
    mem_ena   : out std_logic_vector(0 downto 0);
    mem_enb   : out std_logic_vector(0 downto 0);
    mem_wea   : out std_logic_vector(0 downto 0);
    mem_addra : out std_logic_vector(addrw-1 downto 0);
    mem_addrb : out std_logic_vector(addrw-1 downto 0);
    mem_dia   : out std_logic_vector(dataw-1 downto 0);
    mem_dob   : in std_logic_vector(dataw-1 downto 0)    
  );
end stdout_db;

architecture rtl of stdout_db is

  --signal wptr, rptr : integer range 0 to buffd-1 ;
  signal ndata      : unsigned(addrw-1 downto 0);
  signal lockrq     : std_logic;

--  type buff_t is array (integer range <>) of std_logic_vector(dataw-1 downto 0);
--signal buff : buff_t(0 to buffd-1);

--  signal mem_ena   : std_logic;
--  signal mem_enb   : std_logic;
--  signal mem_wea   : std_logic;
  signal addra : unsigned(addrw-1 downto 0);
  signal addrb : unsigned(addrw-1 downto 0);
--  signal mem_dia   : std_logic_vector(dataw-1 downto 0);
--  signal mem_dob   : std_logic_vector(dataw-1 downto 0);
  
begin

  -- moved to top level 
  --simple_dual_one_clock_1: entity work.simple_dual_one_clock
  --  generic map (
  --    addrw => addrw_c,
  --    dataw => dataw)
  --  port map (
  --    clk   => clk,
  --    ena   => mem_ena,
  --    enb   => mem_enb,
  --    wea   => mem_wea,
  --    addra => std_logic_vector(mem_addra),
  --    addrb => std_logic_vector(mem_addrb),
  --    dia   => mem_dia,
  --    dob   => mem_dob);
  
  ------------------------------------------------------------------------------
  -- simple synchronous fifo for stdout data
  proc_stdout : process(clk, rstx)
  begin
    if (rstx = '0') then
      addra <= (others => '1');
      addrb <= (others => '0');
      ndata     <= (others => '0');
      lockrq    <= '0';
      mem_wea(0)   <= '0';
      mem_enb(0)   <= '0';
      mem_ena(0)   <= '0';
    elsif rising_edge(clk) then
      if (db_nreset(0) = '0') then
        addra <= (others => '1');
        addrb <= (others => '0');
        ndata     <= (others => '0');
        lockrq <= '0';
        mem_wea(0)   <= '0';
        mem_enb(0)   <= '0';
        mem_ena(0)   <= '0';
      else
        mem_wea(0)   <= '0';
        mem_enb(0)   <= '1';
        mem_ena(0)   <= '0';
        -- write stdout
        if (glock = '0' and t1load = '1') then
          if (ndata = to_unsigned(buffd-3, addrw)) then
            lockrq <= '1';
          end if;
          mem_dia   <= t1data;
          addra <= addra+1;
          mem_wea(0)   <= '1';
          mem_ena(0)   <= '1';
        end if;
        -- debugger read from stdout
        if (db_read(0) = '1') then
          addrb <= addrb + 1;
          lockrq <= '0';
        end if;
        -- update ndata
        if (glock = '0' and t1load = '1' and db_read(0) = '0') then
          ndata <= ndata + 1;
        elsif ((glock='1' or t1load = '0') and db_read(0) = '1') then
          ndata <= ndata - 1;                   
        end if;
      end if;
    end if;
  end process;
    
  db_ndata  <= std_logic_vector(ndata);
  db_data   <= mem_dob;
  db_lockrq(0) <= lockrq;
  mem_addra <= std_logic_vector(addra);
  mem_addrb <= std_logic_vector(addrb);

end rtl;

