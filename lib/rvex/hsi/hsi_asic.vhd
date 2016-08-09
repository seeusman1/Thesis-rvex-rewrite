-- r-VEX processor
-- Copyright (C) 2008-2016 by TU Delft.
-- All Rights Reserved.

-- THIS IS A LEGAL DOCUMENT, BY USING r-VEX,
-- YOU ARE AGREEING TO THESE TERMS AND CONDITIONS.

-- No portion of this work may be used by any commercial entity, or for any
-- commercial purpose, without the prior, written permission of TU Delft.
-- Nonprofit and noncommercial use is permitted as described below.

-- 1. r-VEX is provided AS IS, with no warranty of any kind, express
-- or implied. The user of the code accepts full responsibility for the
-- application of the code and the use of any results.

-- 2. Nonprofit and noncommercial use is encouraged. r-VEX may be
-- downloaded, compiled, synthesized, copied, and modified solely for nonprofit,
-- educational, noncommercial research, and noncommercial scholarship
-- purposes provided that this notice in its entirety accompanies all copies.
-- Copies of the modified software can be delivered to persons who use it
-- solely for nonprofit, educational, noncommercial research, and
-- noncommercial scholarship purposes provided that this notice in its
-- entirety accompanies all copies.

-- 3. ALL COMMERCIAL USE, AND ALL USE BY FOR PROFIT ENTITIES, IS EXPRESSLY
-- PROHIBITED WITHOUT A LICENSE FROM TU Delft (J.S.S.M.Wong@tudelft.nl).

-- 4. No nonprofit user may place any restrictions on the use of this software,
-- including as modified by the user, by any other authorized user.

-- 5. Noncommercial and nonprofit users may distribute copies of r-VEX
-- in compiled or binary form as set forth in Section 2, provided that
-- either: (A) it is accompanied by the corresponding machine-readable source
-- code, or (B) it is accompanied by a written offer, with no time limit, to
-- give anyone a machine-readable copy of the corresponding source code in
-- return for reimbursement of the cost of distribution. This written offer
-- must permit verbatim duplication by anyone, or (C) it is distributed by
-- someone who received only the executable form, and is accompanied by a
-- copy of the written offer of source code.

-- 6. r-VEX was developed by Stephan Wong, Thijs van As, Fakhar Anjam,
-- Roel Seedorf, Anthony Brandon, Jeroen van Straten. r-VEX is currently
-- maintained by TU Delft (J.S.S.M.Wong@tudelft.nl).

-- Copyright (C) 2008-2016 by TU Delft.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library rvex;
use rvex.common_pkg.all;
use rvex.bus_pkg.all;


--=============================================================================
-- This is the ASIC side of the HSI (high-speed interface) off-chip
-- interconnect. The timing for the data, oen_n, and ack pads is shown at the
-- top of hsi_asic_mem.vhd. The timing for dbgc and dbgr is shown at the top of
-- hsi_asic_dbg.vhd.
-------------------------------------------------------------------------------
entity hsi_asic is
--=============================================================================
  port (
    
    ---------------------------------------------------------------------------
    -- Pad interface
    ---------------------------------------------------------------------------
    -- Active low reset input from the reset_n pad. The schmitt-trigger pad
    -- function should be enabled to minimize the risk of glitches.
    -- Furthermore, the pulldown should always be active to reset the whole
    -- system when the FPGA is being programmed.
    p_reset_n_di                : in  std_logic;
    
    -- Clock input control. In case there are multiple clock input modes (for
    -- instance, differential or single-ended, schmitt-trigger enable/disable,
    -- whatever), these signals allow the mode to be selected. They can be
    -- configured while the ASIC is being reset.
    p_clk_sel                   : out std_logic;
    p_clk_mode0                 : out std_logic;
    p_clk_mode1                 : out std_logic;
    
    -- Data bus pin interface. The schmitt-trigger function should be disabled.
    -- Obviously, the other functions are controlled by the signals below (they
    -- can be set by the FPGA while reset_n is asserted low).
    p_data_di                   : in  std_logic_vector(31 downto 0);
    p_data_do                   : out std_logic_vector(31 downto 0);
    p_data_oe                   : out std_logic;
    p_data_pin2                 : out std_logic;
    p_data_pin1                 : out std_logic;
    p_data_sr                   : out std_logic;
    p_data_pu                   : out std_logic;
    p_data_pd                   : out std_logic;
    
    -- Active low output enable input from the oen_n pad. Schmitt-trigger
    -- should be disabled. The pullup should be enabled when _pu is high.
    p_oen_n_di                  : in  std_logic;
    p_oen_n_pu                  : out std_logic;
    
    -- Active high acknowledge input from the ack_n pad. Schmitt-trigger
    -- should be disabled. The pulldown should be enabled when _pd is high.
    p_ack_di                    : in  std_logic;
    p_ack_pd                    : out std_logic;
    
    -- Serial debug data command input from the dbgc pad. Schmitt-trigger
    -- should be disabled. The pulldown should be enabled when _pd is high.
    p_dbgc_di                   : in  std_logic;
    p_dbgc_pd                   : out std_logic;
    
    -- Serial debug response output to the dbgr pad. Drive strength and slew
    -- rate are to be controlled by the _pin2, _pin1, and _sr signals.
    p_dbgr_do                   : out std_logic;
    p_dbgr_pin2                 : out std_logic;
    p_dbgr_pin1                 : out std_logic;
    p_dbgr_sr                   : out std_logic;
    
    -- Special-function pins. The function of these pins is configured during
    -- a reset. They are intended to be used as interrupt request pins, but
    -- they can be multiplexed to other functions as well. Examples would be
    -- cache behavior signals, bus behavior signals, stall signals, etc.
    p_spf_di                    : in  std_logic_vector(7 downto 0);
    p_spf_do                    : out std_logic_vector(7 downto 0);
    p_spf_oe                    : out std_logic_vector(7 downto 0);
    p_spf_pin2                  : out std_logic;
    p_spf_pin1                  : out std_logic;
    p_spf_sr                    : out std_logic;
    p_spf_pu                    : out std_logic;
    p_spf_pd                    : out std_logic;
    p_spf_smt                   : out std_logic;
    
    -- Alternate pin functions on the rising edge of reset_n:
    --  - data0:  p_clk_sel
    --  - data1:  p_clk_mode1
    --  - data2:  p_clk_mode2
    --  - data3:  <reserved>
    --  - data4:  memory bus mode 0
    --  - data5:  memory bus mode 1
    --  - data6:  p_data_sr
    --  - data7:  p_data_pin1
    --  - data8:  p_data_pin2
    --  - data9:  p_data_pu
    --  - data10: p_data_pd
    --  - data11: debug bus mode 0
    --  - data12: debug bus mode 1
    --  - data13: p_dbgr_sr
    --  - data14: p_dbgr_pin1
    --  - data15: p_dbgr_pin2
    --  - data16: spf pin function 0
    --  - data17: spf pin function 1
    --  - data18: spf pin function 2
    --  - data19: spf pin function 3
    --  - data20: spf pin function 4
    --  - data21: spf pin function 5
    --  - data22: spf pin function 6
    --  - data23: spf pin function 7
    --  - data24: p_spf_sr
    --  - data25: p_spf_pin1
    --  - data26: p_spf_pin2
    --  - data27: p_spf_pu
    --  - data28: p_spf_pd
    --  - data29: p_spf_smt
    --  - data30: <reserved>
    --  - data31: <reserved>
    
    ---------------------------------------------------------------------------
    -- Internal signals
    ---------------------------------------------------------------------------
    -- Clock network. The clock input selection mux and buffers should be
    -- instantiated outside this unit.
    clk                         : in  std_logic;
    
    -- Filtered and synchronized reset signal for the core (active high).
    reset                       : out std_logic;
    
    -- Off-chip memory/peripheral interface bus.
    bus2mem                     : in  bus_mst2slv_type;
    mem2bus                     : out bus_slv2mst_type;
    
    -- Debug interface bus.
    dbg2bus                     : out bus_mst2slv_type;
    bus2dbg                     : in  bus_slv2mst_type;
    
    -- Trace interface.
    trace_push                  : in  std_logic;
    trace_data                  : in  std_logic_vector(7 downto 0);
    trace_busy                  : out std_logic;
    
    -- External interrupt signals, active high.
    ext_irq                     : out std_logic_vector(7 downto 0);
    
    -- Special-function data interface.
    spf_func                    : out std_logic_vector(7 downto 0);
    spf_di                      : out std_logic_vector(7 downto 0);
    spf_do                      : in  std_logic_vector(7 downto 0);
    spf_oe                      : in  std_logic_vector(7 downto 0)
    
  );
end hsi_asic;

--=============================================================================
architecture Behavioral of hsi_asic is
--=============================================================================
  
  -- The reset synchronization/filtering consists of a shift register that
  -- always shifts in a one on the rising edge of a clock cycle, and is
  -- asynchronously reset to zero by the incoming reset signal. This ensures
  -- that reset remains asserted for at least the number of clock edges defined
  -- below.
  constant RESET_FILTER_LENGTH  : natural := 16;
  signal reset_filter           : std_logic_vector(RESET_FILTER_LENGTH downto 0);
  
  -- Local copy of the active-high internal reset signal.
  signal reset_int              : std_logic;
  
  -- Reset configuration registers.
  signal cfg_mem                : std_logic_vector(1 downto 0);
  signal cfg_dbg                : std_logic_vector(1 downto 0);
  signal cfg_spf                : std_logic_vector(7 downto 0);
  signal cfg_spf_irq            : std_logic;
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- Reset filtering
  -----------------------------------------------------------------------------
  -- Instantiate the reset filter shift register.
  reset_filter_proc: process (clk, p_reset_n_di) is
  begin
    if p_reset_n_di = '0' then
      reset_filter <= (others => '0');
    elsif rising_edge(clk_hsi) then
      reset_filter <= "1" & reset_filter(RESET_FILTER_LENGTH downto 1);
    end if;
  end process;
  
  -- Drive the reset signals.
  reset_int <= not reset_filter(0);
  reset <= reset_int;
  
  -- Connect pullup/down enable signals.
  p_oen_n_pu <= p_reset_n_di;
  p_ack_pd   <= p_reset_n_di;
  p_dbgc_pd  <= p_reset_n_di;
  
  -----------------------------------------------------------------------------
  -- Reset configuration registers
  -----------------------------------------------------------------------------
  -- Instantiate the configuration registers. We can't assume that we have a
  -- usable clock during reset, as the configuration affects the clock input
  -- mode, so instead, we use the reset pad itself as a clock signal.
  cfg_reg_proc: process (reset_n) is
  begin
    if rising_edge(reset_n) then
      
      -- Clock configuration registers.
      p_clk_sel   <= p_data_di(0);
      p_clk_mode0 <= p_data_di(1);
      p_clk_mode1 <= p_data_di(2);
      
      -- Memory bus configuration registers.
      cfg_mem     <= p_data_di(5 downto 4);
      p_data_sr   <= p_data_di(6);
      p_data_pin1 <= p_data_di(7);
      p_data_pin2 <= p_data_di(8);
      p_data_pu   <= p_data_di(9);
      p_data_pd   <= p_data_di(10);
      
      -- Debug serial port configuration registers.
      cfg_dbg     <= p_data_di(12 downto 11);
      p_dbgr_sr   <= p_data_di(13);
      p_dbgr_pin1 <= p_data_di(14);
      p_dbgr_pin2 <= p_data_di(15);
      
      -- Special-function pin configuration registers.
      cfg_spf     <= p_data_di(23 downto 16);
      p_spf_sr    <= p_data_di(24);
      p_spf_pin1  <= p_data_di(25);
      p_spf_pin2  <= p_data_di(26);
      p_spf_pu    <= p_data_di(27);
      p_spf_pd    <= p_data_di(28);
      p_spf_smt   <= p_data_di(29);
      
    end if;
  end process;
  
  -----------------------------------------------------------------------------
  -- Parallel data bus (ASIC master)
  -----------------------------------------------------------------------------
  asic_mem_inst: entity work.hsi_asic_mem
    port map (
      clk                       => clk,
      reset                     => reset_int,
      cfg_mem                   => cfg_mem,
      data_in                   => p_data_di,
      data_out                  => p_data_do,
      data_oen                  => p_data_oe,
      oen_n                     => p_oen_n_di,
      ack                       => p_ack_di,
      bus2mem                   => bus2mem,
      mem2bus                   => mem2bus,
      trace_push                => trace_push,
      trace_data                => trace_data,
      trace_busy                => trace_busy
    );
  
  -----------------------------------------------------------------------------
  -- Special-function pins
  -----------------------------------------------------------------------------
  -- Select interrupt input mode when SPF mode is zero.
  cfg_spf_irq <= '1' when cfg_spf = "00000000" else '0';
  
  -- Force external interrupt signals to zero (not asserted) when the special
  -- function pins are not in interrupt mode.
  ext_irq <= p_spf_di when cfg_spf_irq = '1' else "00000000";
  
  -- Connect the special function ports.
  spf_func <= cfg_spf;
  spf_di <= p_spf_di;
  p_spf_do <= p_spf_do;
  p_spf_oe <= p_spf_oe when cfg_spf_irq = '0' else "00000000";
  
end Behavioral;

