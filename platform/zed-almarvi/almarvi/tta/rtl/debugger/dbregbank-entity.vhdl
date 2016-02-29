-------------------------------------------------------------------------------
-- Title      : Debugger register bank
-- Project    : tta debugger
-------------------------------------------------------------------------------
-- File       : dbregbank-entity.vhdl
-- Author     : Tommi Zetterman  <tommi.zetterman@nokia.com>
-- Company    : Nokia Research Center
-- Created    : 2013-03-18
-- Last update: 2015-10-06
-- Platform   :
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- Copyright (c) 2013 Nokia Research Center
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2013-03-18  1.0      zetterma	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use work.register_pkg.all;
use work.debugger_if.all;

entity dbregbank is
  generic (
    data_width_g : integer := 32;
    addr_width_g : integer := 8;
    nof_bustraces_g : integer := 76;
    stdout_dataw_g  : integer := 32;
    stdout_addrw_g  : integer := 4);
  port(
    clk      : in std_logic;
    nreset   : in std_logic;
    -- access from fpga if
    we_if    : in std_logic;
    re_if    : in std_logic;
    addr_if  : in std_logic_vector(addr_width_g-1 downto 0);
    din_if   : in std_logic_vector(data_width_g-1 downto 0);
    dout_if  : out std_logic_vector(data_width_g-1 downto 0);
    -- access from debugger sm

    ---------------------------------------------------------------------------
    -- TTA debugger status registers inputs
    ---------------------------------------------------------------------------
    -- breakpoint hit -status
    bp_hit         : in std_logic_vector(2+debreg_nof_breakpoints_c-1 downto 0);
    -- stddout -status & data
    stdout_pending : in std_logic;
    --
    flags          : in std_logic_vector(data_width_g-1 downto 0);
    -- program counter
    pc             : in std_logic_vector(pc_width_c-1 downto 0);
    -- processor cycle counter
    cycle_cnt      : in std_logic_vector(data_width_g-1 downto 0);
    -- processor lock counter
    lock_cnt       : in std_logic_vector(data_width_g-1 downto 0);
    -- bus trace input
    bustraces      : in std_logic_vector(nof_bustraces_g*bustrace_width_c-1
                                         downto 0);

    ---------------------------------------------------------------------------
    -- TTA control registers outputs
    ---------------------------------------------------------------------------
    -- initial program counter after reset
    pc_start_address : out std_logic_vector(pc_width_c-1 downto 0);
    -- cycle counter -breakpoint
    bp0              : out std_logic_vector(data_width_g-1 downto 0);
    bp0_type         : out std_logic_vector(1 downto 0);
    -- program counter -preakpoints
    bp1              : out std_logic_vector(pc_width_c-1 downto 0);
    bp2              : out std_logic_vector(pc_width_c-1 downto 0);
    bp3              : out std_logic_vector(pc_width_c-1 downto 0);
    bp4              : out std_logic_vector(pc_width_c-1 downto 0);
    -- breakpoint enable
    bp_enable        : out std_logic_vector(1+debreg_nof_breakpoints_c-1 downto 0);
    -- tta force reset
    tta_reset        : out std_logic;
    -- continue (pulse)
    tta_continue     : out std_logic;
    -- break (pulse)
    tta_forcebreak   : out std_logic;
    -- invalidate caches
    icache_invalidate : out std_logic;
    dcache_invalidate : out std_logic;
    -- generated outgoing interrupt
    irq              : out std_logic;
    -- instruction memory page and mask
    imem_page        : out std_logic_vector(data_width_g-1 downto 0);
    imem_mask        : out std_logic_vector(data_width_g-1 downto 0);
    -- data memory page and mask
    dmem_page        : out std_logic_vector(data_width_g-1 downto 0);
    dmem_mask        : out std_logic_vector(data_width_g-1 downto 0);
    -- perf & err counters
    axi_burst_cnt    : in std_logic_vector(3*32-1 downto 0);
    axi_err_cnt      : in std_logic_vector(3*32-1 downto 0);
    -- stdout
    stdout_d         : in std_logic_vector(stdout_dataw_g-1 downto 0);
    stdout_n         : in std_logic_vector(stdout_addrw_g-1 downto 0);
    stdout_read      : out std_logic
  );

end dbregbank;
