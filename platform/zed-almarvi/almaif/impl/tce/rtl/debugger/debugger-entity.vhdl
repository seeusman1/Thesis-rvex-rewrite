-------------------------------------------------------------------------------
-- Title      : debugger
-- Project    : tta
-------------------------------------------------------------------------------
-- File       : debugger-entity.vhdl
-- Author     : Tommi Zetterman  <tommi.zetterman@nokia.com>
-- Company    : Nokia Research Center
-- Created    : 2013-03-19
-- Last update: 2015-10-06
-- Platform   :
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: top level debugger interface
-------------------------------------------------------------------------------
-- Copyright (c) 2013 Nokia Research Center
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2013-03-19  1.0      zetterma	Createddeb
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use work.debugger_if.all;
use work.register_pkg.all;

entity debugger is
  generic (
    data_width_g : integer := 32;
    addr_width_g : integer := 8;
    nof_bustraces_g : integer := 76;
    stdout_dataw_g  : integer := 32;
    stdout_addrw_g  : integer := 4;    
    use_cdc_g       : boolean := true
  );
  port (
    nreset     : in std_logic;
    -- fpga if
    clk_fpga  : in std_logic;
    wen_fpga  : in std_logic;
    ren_fpga  : in std_logic;
    addr_fpga : in std_logic_vector(addr_width_g-1 downto 0);
    din_fpga  : in std_logic_vector(data_width_g-1 downto 0);
    dout_fpga : out std_logic_vector(data_width_g-1 downto 0);
    dv_fpga   : out std_logic;
    -- tta if
    clk_tta   : in std_logic;
    pc_start  : out std_logic_vector(pc_width_c-1 downto 0);
    --   status
    pc        : in std_logic_vector(pc_width_c-1 downto 0);
    bustraces : in std_logic_vector(nof_bustraces_g*data_width_g-1 downto 0);
    lockcnt   : in std_logic_vector(data_width_g-1 downto 0);
    cyclecnt  : in std_logic_vector(data_width_g-1 downto 0);
    flags     : in std_logic_vector(data_width_g-1 downto 0);
    --   dbsm
    bp_ena    : out std_logic_vector(1+debreg_nof_breakpoints_c-1 downto 0);
    bp0       : out std_logic_vector(data_width_g-1 downto 0);
    bp4_1     : out std_logic_vector((debreg_nof_breakpoints_c-1)*pc_width_c-1 downto 0);
    bp_hit    : in std_logic_vector(2+debreg_nof_breakpoints_c-1 downto 0);
    tta_continue : out std_logic;
    tta_nreset   : out std_logic;
    tta_forcebreak : out std_logic;
    -- interrupt line
    irq       : out std_logic;
    -- debugger status
    busy      : out std_logic;
    -- instruction memory page and mask
    imem_page : out std_logic_vector(data_width_g-1 downto 0);
    imem_mask : out std_logic_vector(data_width_g-1 downto 0);
    -- data memory page and mask
    dmem_page : out std_logic_vector(data_width_g-1 downto 0);
    dmem_mask : out std_logic_vector(data_width_g-1 downto 0);
    -- invalidate caches
    icache_invalidate : out std_logic;
    dcache_invalidate : out std_logic;
    -- perf & err counters from cache controllers
    axi_burst_cnt     : in std_logic_vector(3*32-1 downto 0);
    axi_err_cnt       : in std_logic_vector(3*32-1 downto 0);
    -- stdout
    db_stdout_d       : in std_logic_vector(stdout_dataw_g-1 downto 0);
    db_stdout_n       : in std_logic_vector(stdout_addrw_g-1 downto 0);
    db_stdout_read    : out std_logic
    );
  
end debugger;
