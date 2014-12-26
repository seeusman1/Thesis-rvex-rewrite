-- r-VEX processor
-- Copyright (C) 2008-2014 by TU Delft.
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

-- Copyright (C) 2008-2014 by TU Delft.

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

--=============================================================================
-- This is the toplevel file for synthesizing a basic rvex platform on a Xilinx
-- ML605 Virtex-6 evaluation board.
-------------------------------------------------------------------------------
entity ml605 is
--=============================================================================
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
  
  -- Clock division value. The internal clock will be 750 MHz divided by this
  -- number.
  constant DIV_VAL              : natural := 15;
  constant F_CLK                : real := 750000000.0 / real(DIV_VAL);
  
  -- System control block outputs.
  signal reset                  : std_logic;
  signal clk                    : std_logic;
  signal clkEn                  : std_logic;
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- Debug UART/syscon test
  -----------------------------------------------------------------------------
  debugUart: block is
    
    constant addrMap              : addrRangeAndMapping_array(0 to 1) := (
      0 => addrRangeAndMap(match => "----0000------------------------"),
      1 => addrRangeAndMap(match => "----1111------------------------")
    );
    signal uart2dbg_busA          : bus_mst2slv_type;
    signal dbg2uart_busA          : bus_slv2mst_type;
    signal uart2dbg_busB          : bus_mst2slv_type;
    signal dbg2uart_busB          : bus_slv2mst_type;
    signal uart2dbg_busC          : bus_mst2slv_type;
    signal dbg2uart_busC          : bus_slv2mst_type;
    signal tx_s                   : std_logic;
    signal irq                    : std_logic;
    
  begin
    
    -- Instantiate unit under test.
    uut: entity rvex.periph_uart
      generic map (
        F_CLK                     => F_CLK,
        F_BAUD                    => 115200.0
      )
      port map (
        
        -- System control.
        reset                     => reset,
        clk                       => clk,
        clkEn                     => clkEn,
        
        -- UART pins.
        rx                        => rx,
        tx                        => tx_s,
        
        -- Slave bus.
        bus2uart                  => uart2dbg_busC,
        uart2bus                  => dbg2uart_busC,
        irq                       => irq,
        
        -- Debug interface.
        uart2dbg_bus              => uart2dbg_busA,
        dbg2uart_bus              => dbg2uart_busA
        
      );
    
    -- Instantiate the bus demuxer.
    demux_inst: entity rvex.bus_demux
      generic map (
        ADDRESS_MAP               => addrMap,
        OOR_FAULT_CODE            => X"12345678"
      )
      port map (
        
        -- System control.
        reset                     => reset,
        clk                       => clk,
        clkEn                     => clkEn,
        
        -- Busses.
        mst2demux                 => uart2dbg_busA,
        demux2mst                 => dbg2uart_busA,
        demux2slv(0)              => uart2dbg_busB,
        demux2slv(1)              => uart2dbg_busC,
        slv2demux(0)              => dbg2uart_busB,
        slv2demux(1)              => dbg2uart_busC
        
      );
    
    -- Instantiate a memory for the unit under test to access.
    memory_inst: entity rvex.bus_ramBlock_singlePort
      generic map (
        DEPTH_LOG2B               => 10
      )
      port map (
        
        -- System control.
        reset                     => reset,
        clk                       => clk,
        clkEn                     => clkEn,
        
        -- Memory port.
        mst2mem_port              => uart2dbg_busB,
        mem2mst_port              => dbg2uart_busB
        
      );
    
    leds <= (
      7 => not rx,
      6 => not tx_s,
      0 => irq,
      others => '0'
    );
    tx <= tx_s;
  
  end block;
  
  -----------------------------------------------------------------------------
  -- System control
  -----------------------------------------------------------------------------
  sys_ctrl_block: block is
    
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
    
  end block;
  
end Behavioral;

