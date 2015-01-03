-- r-VEX processor
-- Copyright (C) 2008-2015 by TU Delft.
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

-- Copyright (C) 2008-2015 by TU Delft.

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
use rvex.standalone_pkg.all;
use rvex.core_pkg.all;

--=============================================================================
-- This is the toplevel file for synthesizing a basic rvex platform on a Xilinx
-- ML605 Virtex-6 evaluation board.
-------------------------------------------------------------------------------
entity ml605 is
--=============================================================================
  generic (
    
    -- Clock division value. The internal clock will be 750 MHz divided by this
    -- number. Ignored when DIRECT_RESET_AND_CLOCK is set.
    DIV_VAL                     : natural := 24;
    
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
end ml605;

--=============================================================================
architecture Behavioral of ml605 is
--=============================================================================
  
  -- This determines the internal clock frequency.
  function f_clk_fn return real is
  begin
    if DIRECT_RESET_AND_CLOCK then
      return F_SYSCLK;
    else
      return 750000000.0 / real(DIV_VAL);
    end if;
  end f_clk_fn;
  
  -- Determine the internal clock frequency.
  constant F_CLK                : real := f_clk_fn;
  
  -- System control block outputs.
  signal reset                  : std_logic;
  signal clk                    : std_logic;
  signal clkEn                  : std_logic;
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- Basic rvex standalone system
  -----------------------------------------------------------------------------
  rvex_standalone: block is
    
    signal rvsa2bus               : bus_mst2slv_type;
    signal bus2rvsa               : bus_slv2mst_type;
    signal debug2rvsa             : bus_mst2slv_type;
    signal rvsa2debug             : bus_slv2mst_type;
    
  begin
    
    rvex_inst: entity rvex.standalone
      generic map (
        
        -- Configuration.
        CFG                       => rvex_sa_cfg(
          imemDepthLog2B          => 16,
          dmemDepthLog2B          => 16
        )
        
      )
      port map (
        
        -- System control.
        reset                     => reset,
        clk                       => clk,
        clkEn                     => clkEn,
        
        -- Bus interfaces.
        rvsa2bus                  => rvsa2bus,
        bus2rvsa                  => bus2rvsa,
        debug2rvsa                => debug2rvsa,
        rvsa2debug                => rvsa2debug
        
      );
    
    uart: entity rvex.periph_uart
      generic map (
        F_CLK                     => F_CLK,
        F_BAUD                    => F_BAUD
      )
      port map (
        
        -- System control.
        reset                     => reset,
        clk                       => clk,
        clkEn                     => clkEn,
        
        -- UART pins.
        rx                        => rx,
        tx                        => tx,
        
        -- Slave bus.
        bus2uart                  => rvsa2bus,
        uart2bus                  => bus2rvsa,
        irq                       => open,
        
        -- Debug interface.
        uart2dbg_bus              => debug2rvsa,
        dbg2uart_bus              => rvsa2debug
        
      );
    
    leds <= (others => '0');
    
  end block;
  
  -----------------------------------------------------------------------------
  -- System control
  -----------------------------------------------------------------------------
  sys_ctrl_block: if not DIRECT_RESET_AND_CLOCK generate
    
    -- Buffered system clock (200 MHz).
    signal sysclk               : std_logic;
    
    -- Unbuffered generated clock.
    signal clk_local            : std_logic;
    
    -- MMCM signals.
    signal mmcm_fb              : std_logic;
    signal mmcm_reset           : std_logic;
    signal mmcm_locked          : std_logic;
    
    -- Reset counter. This counts 128 clock pulses after resetButton goes low
    -- and mmcm_locked goes high, before releasing the internal reset signal.
    signal reset_count          : unsigned(6 downto 0);
    
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
        
        -- Divide input clock by 4 and multiply it by 15. This should get us
        -- a VCO frequency of 750 MHz, nicely within the 600-1200 MHz worst
        -- case operating limits.
        DIVCLK_DIVIDE     => 4,
        CLKFBOUT_MULT_F   => 15.0,
        
        -- Divide the VCO clock by the specified amount to get the internal
        -- clock.
        CLKOUT1_DIVIDE    => DIV_VAL
      )
      port map (
        
        -- Clock input.
        CLKIN1            => sysclk,
        
        -- We use clock output 1 for the internal clock (we only need one).
        CLKOUT1           => clk_local,
        
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
    
    -- Buffer the local clock.
    clk_buffer: BUFG
      port map (
        I => clk_local,
        O => clk
      );
    
    -- Reset generation.
    reset_gen: process (clk, resetButton, mmcm_locked) is
    begin
      if resetButton = '1' or mmcm_locked = '0' then
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
    
    -- Clock enable generation.
    clkEn <= '1';
    
  end generate;
  
  -- Dummy syscon block for simulation.
  sys_ctrl_block_dummy: if DIRECT_RESET_AND_CLOCK generate
  begin
    clk <= sysclk_p;
    reset <= resetButton;
    clkEn <= '1';
  end generate;
  
end Behavioral;

