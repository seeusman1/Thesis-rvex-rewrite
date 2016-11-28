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
use IEEE.math_real.all;

library unisim;
use unisim.vcomponents.all;

library rvex;
use rvex.common_pkg.all;
use rvex.utils_pkg.all;
use rvex.simUtils_pkg.all;
use rvex.bus_pkg.all;
use rvex.bus_addrConv_pkg.all;
use rvex.core_pkg.all;

--=============================================================================
-- This is the toplevel file for synthesizing a basic rvex platform on a Xilinx
-- VC707 Virtex-7 evaluation board.
-------------------------------------------------------------------------------
entity vc707 is
--=============================================================================
  generic (
    
    -- Clock division value. Final clock is:
    --   200MHz / VCO_DIV * VCO_MULT / DIV_VAL
    -- VCO is:
    --   200MHz / VCO_DIV * VCO_MULT
    -- VCO must be between 600 MHz and 1200 MHz.
    VCO_DIV                     : natural := 4;
    VCO_MULT                    : real    := 20.0; -- VCO = 1000 MHz
    DIV_VAL_CORE                : natural := 10;   -- 100 MHz
    DIV_VAL_DBG                 : natural := 50;   -- 20 MHz
    
    -- Baud rate to use for the UART.
    F_BAUD                      : real := 115200.0;
    
    -- When set, sysclk_p and resetButton are directly fed into the rvex and
    -- UART block as clk and reset. This may be used to speed up simulation
    -- when full syscon accuracy is not needed. When set, F_SYSCLK is used to
    -- configure the baud rate of the UART; it is ignored otherwise.
    DIRECT_RESET_AND_CLOCK      : boolean := false;
    F_SYSCLK                    : real := 200000000.0 -- 200 MHz
    
  );
  port (
    
    -- 200 MHz system clock source.
    sysclk_p                    : in  std_logic;
    sysclk_n                    : in  std_logic;
    
    -- USB-UART bridge.
    rx                          : in  std_logic;
    tx                          : out std_logic;
    
    -- LEDs/J62.
    leds                        : out std_logic_vector(7 downto 0);
    
    -- CPU reset button.
    resetButton                 : in  std_logic
    
  );
end vc707;

--=============================================================================
architecture Behavioral of vc707 is
--=============================================================================
  
  -- This determines the debug clock frequency.
  function f_clk_dbg_fn return real is
  begin
    if DIRECT_RESET_AND_CLOCK then
      return F_SYSCLK;
    else
      return F_SYSCLK / real(VCO_DIV) * VCO_MULT / real(DIV_VAL_DBG);
    end if;
  end f_clk_dbg_fn;
  
  -- Determine the internal clock frequency.
  constant F_CLK_DBG            : real := f_clk_dbg_fn;
  
  -- System control block outputs.
  signal reset                  : std_logic;
  signal reset_dbg              : std_logic;
  signal clk                    : std_logic;
  signal clk_dbg                : std_logic;
  signal clkEn                  : std_logic;
  signal clkEn_dbg              : std_logic;
  
  -- r-VEX configuration.
  function CORE_CFG return rvex_generic_config_type is
    variable c : rvex_generic_config_type;
  begin
    c := RVEX_DEFAULT_CONFIG;
    c.numLanesLog2          := 1;
    c.numLaneGroupsLog2     := 0;
    c.numContextsLog2       := 0;
    c.bundleAlignLog2       := 1;
    c.limmhFromPreviousPair := false;
    c.traceEnable           := false;
    c.perfCountSize         := 4;
    c.cachePerfCountEnable  := false;
    c.stallInactive         := false;
    c.enablePowerLatches    := false;
    return c;
  end CORE_CFG;
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- Basic standalone streaming system.
  -----------------------------------------------------------------------------
  rvex_stream: block is
    
    -- Debug access bus.
    signal debug2rvs            : bus_mst2slv_type;
    signal rvs2debug            : bus_slv2mst_type;
    
    -- Local transmit signal, so we can also tie it to an LED.
    signal tx_s                 : std_logic;
    
  begin
    
    cores: entity rvex.rvsys_streams
      generic map (
        CORE_CFG                => CORE_CFG,
        NUM_CORES_PER_STREAM    => 2,
        NUM_STREAMS             => 2,
        DMEM_DEPTH_LOG2         => 12,
        IMEM_DEPTH_LOG2         => 12,
        DEBUG_BUS_MUX_BIT       => 16
      )
      port map (
        
        -- Core interfaces (fast clock).
        reset                   => reset,
        clk                     => clk,
        clkEn                   => clkEn,
        
        -- Debug/input-output interface (slow clock).
        reset_dbg               => reset_dbg,
        clk_dbg                 => clk_dbg,
        clkEn_dbg               => clkEn_dbg,
        debug2rvs               => debug2rvs,
        rvs2debug               => rvs2debug
        
      );    
    
    uart: entity rvex.periph_uart
      generic map (
        F_CLK                   => F_CLK_DBG,
        F_BAUD                  => F_BAUD
      )
      port map (
        
        -- System control.
        reset                   => reset_dbg,
        clk                     => clk_dbg,
        clkEn                   => clkEn_dbg,
        
        -- UART pins.
        rx                      => rx,
        tx                      => tx_s,
        
        -- Slave bus.
        bus2uart                => BUS_MST2SLV_IDLE,
        uart2bus                => open,
        irq                     => open,
        
        -- Debug interface.
        uart2dbg_bus            => debug2rvs,
        dbg2uart_bus            => rvs2debug
        
      );
    
    -- Tie LEDs to useful signals.
    leds <= (
      0 => rx,
      1 => tx_s,
      2 => '0',
      3 => '0',
      4 => '0',
      5 => '0',
      6 => reset_dbg,
      7 => reset
    );
    
    tx <= tx_s;
    
  end block;
  
  -----------------------------------------------------------------------------
  -- System control
  -----------------------------------------------------------------------------
  sys_ctrl_block: if not DIRECT_RESET_AND_CLOCK generate
    
    -- Buffered system clock (200 MHz).
    signal sysclk               : std_logic;
    
    -- Unbuffered generated clock.
    signal clk_local            : std_logic;
    signal clk_local_dbg        : std_logic;
    
    -- MMCM signals.
    signal mmcm_fb              : std_logic;
    signal mmcm_reset           : std_logic;
    signal mmcm_locked          : std_logic;
    
    -- Reset counter. This counts 128 clock pulses after resetButton goes low
    -- and mmcm_locked goes high, before releasing the internal reset signal.
    signal reset_count          : unsigned(6 downto 0);
    signal reset_count_dbg      : unsigned(6 downto 0);
    
  begin
    
    -- Instantiate the 200MHz system clock differential input buffer.
    sysclk_ibufgds_inst : IBUFGDS
      generic map (
        IOSTANDARD => "DEFAULT"
      )
      port map (
        I  => sysclk_p,
        IB => sysclk_n,
        O  => sysclk
      );
    
    -- Instantiate clock manipulation/distribution primitive.
    mmcm_inst : MMCM_BASE
      generic map (
        
        -- Input clock is at 200 MHz.
        CLKIN1_PERIOD     => 5.0,--ns
        
        -- These parameters generate the VCO clock. It is
        -- 200 MHz / VCO_DIV * VCO_MULT and needs to be between 600 and
        -- 1200 MHz.
        DIVCLK_DIVIDE     => VCO_DIV,
        CLKFBOUT_MULT_F   => VCO_MULT,
        
        -- Divide the VCO clock by the specified amount to get the internal
        -- clock.
        CLKOUT1_DIVIDE    => DIV_VAL_CORE,
        CLKOUT2_DIVIDE    => DIV_VAL_DBG
      )
      port map (
        
        -- Clock input.
        CLKIN1            => sysclk,
        
        -- We use clock output 1 for the core clock and output 2 for the debug
        -- bus clock.
        CLKOUT1           => clk_local,
        CLKOUT2           => clk_local_dbg,
        
        -- Clock feedback path. We don't care about the phase relationship
        -- between sysclk and clk, so we can just tie these together.
        CLKFBOUT          => mmcm_fb,
        CLKFBIN           => mmcm_fb,
        
        -- Status/control signals.
        RST               => mmcm_reset,
        LOCKED            => mmcm_locked,
        PWRDWN            => '0'
        
      );
    
    -- Reset the MMCM when the reset button is pushed.
    mmcm_reset <= resetButton;
    
    -- Buffer the core clock.
    core_clk_buffer: BUFG
      port map (
        I => clk_local,
        O => clk
      );
    
    -- Buffer the debug bus clock.
    dbg_clk_buffer: BUFG
      port map (
        I => clk_local_dbg,
        O => clk_dbg
      );
    
    -- Reset generation.
    core_reset_gen: process (clk, resetButton, mmcm_locked, reset_dbg) is
    begin
      if  resetButton = '1' or mmcm_locked = '0' or reset_dbg = '1' then
        reset_count <= (others => '0');
        reset <= '1';
      elsif rising_edge(clk) then
        if reset_count = "1111111" then
          reset <= '0';
        else
          reset_count <= reset_count + 1;
          reset <= '1';
        end if;
      end if;
    end process;
    
    dbg_reset_gen: process (clk_dbg, resetButton, mmcm_locked) is
    begin
      if resetButton = '1' or mmcm_locked = '0' then
        reset_count_dbg <= (others => '0');
        reset_dbg <= '1';
      elsif rising_edge(clk_dbg) then
        if reset_count_dbg = "1111111" then
          reset_dbg <= '0';
        else
          reset_count_dbg <= reset_count_dbg + 1;
          reset_dbg <= '1';
        end if;
      end if;
    end process;
    
    -- Clock enable generation.
    clkEn <= '1';
    clkEn_dbg <= '1';
    
  end generate;
  
  -- Dummy syscon block for simulation.
  sys_ctrl_block_dummy: if DIRECT_RESET_AND_CLOCK generate
  begin
    clk <= sysclk_p;
    clk_dbg <= sysclk_p;
    reset <= resetButton;
    reset_dbg <= resetButton;
    clkEn <= '1';
    clkEn_dbg <= '1';
  end generate;
  
end Behavioral;

