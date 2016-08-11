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
use rvex.rvsys_standalone_pkg.all;
use rvex.core_pkg.all;
use rvex.cache_pkg.all;

--=============================================================================
-- This is the toplevel file for synthesizing a basic rvex platform on a Xilinx
-- ML605 Virtex-6 evaluation board.
-------------------------------------------------------------------------------
entity ml605 is
--=============================================================================
  generic (
    
    -- Clock division value. The internal clock will be 1000 MHz divided by this
    -- number. Ignored when DIRECT_RESET_AND_CLOCK is set.
    DIV_VAL                     : natural := 10; -- 100 MHz
    
    -- Baud rate to use for the UART.
    F_BAUD                      : real := 115200.0;
    
    -- When set, sysclk_p and resetButton are directly fed into the rvex and
    -- UART block as clk and reset. This may be used to speed up simulation
    -- when full syscon accuracy is not needed. When set, F_SYSCLK is used to
    -- configure the baud rate of the UART; it is ignored otherwise.
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
  
  -- Buffered system clock (200 MHz).
  signal sysclk                 : std_logic;
  
  -- Determine the internal clock frequency.
  constant F_CLK                : real := 1000000000.0 / real(DIV_VAL);
  
  -- System control block outputs.
  signal reset                  : std_logic;
  signal clk                    : std_logic;
  
  -- Alternate clock domain system control signals.
  signal alt_reset              : std_logic;
  signal alt_clk                : std_logic;
  
  -- Debug UART address map.
  constant DEBUG_ADDRESS_MAP    : addrRangeAndMapping_array(0 to 1) := (
    
    -- Memory residing in the alternate clock domain for testing.
    0 => addrRangeAndMap(
      match => "0-------------------------------"
    ),
    
    -- MMCM.
    1 => addrRangeAndMap(
      match => "1-------------------------------"
    )
    
  );
  
  -- Debug bus from the UART.
  signal uart2dbg               : bus_mst2slv_type;
  signal dbg2uart               : bus_slv2mst_type;
  
  -- Debug bus to cross-clock bridge.
  signal dbg2xclk               : bus_mst2slv_type;
  signal xclk2dbg               : bus_slv2mst_type;
  
  -- Cross-clock bridge to memory, residing in the alternate clock domain.
  signal xclk2mem               : bus_mst2slv_type;
  signal mem2xclk               : bus_slv2mst_type;
  
  -- Debug bus to MMCM bridge.
  signal dbg2mmcm               : bus_mst2slv_type;
  signal mmcm2dbg               : bus_slv2mst_type;
  
  -- LEDs blinking at a frequency of ~.5 Hz when given an input of 100 MHz.
  signal clk_led                : std_logic;
  signal alt_clk_led            : std_logic;
  
--=============================================================================
begin -- architecture
--=============================================================================
  
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
  
  -----------------------------------------------------------------------------
  -- Debug UART
  -----------------------------------------------------------------------------
  uart: entity rvex.periph_uart
    generic map (
      F_CLK                     => F_CLK,
      F_BAUD                    => F_BAUD
    )
    port map (
      
      -- System control.
      reset                     => reset,
      clk                       => clk,
      clkEn                     => '1',
      
      -- UART pins.
      rx                        => rx,
      tx                        => tx,
      
      -- Slave bus.
      bus2uart                  => BUS_MST2SLV_IDLE,
      uart2bus                  => open,
      irq                       => open,
      
      -- Debug interface.
      uart2dbg_bus              => uart2dbg,
      dbg2uart_bus              => dbg2uart
      
    );
  
  -----------------------------------------------------------------------------
  -- Bus logic
  -----------------------------------------------------------------------------
  dbg_bus_demux: entity rvex.bus_demux
    generic map (
      ADDRESS_MAP               => DEBUG_ADDRESS_MAP
    )
    port map (
      
      -- System control.
      reset                     => reset,
      clk                       => clk,
      clkEn                     => '1',
      
      -- Busses.
      mst2demux                 => uart2dbg,
      demux2mst                 => dbg2uart,
      demux2slv(0)              => dbg2xclk,
      demux2slv(1)              => dbg2mmcm,
      slv2demux(0)              => xclk2dbg,
      slv2demux(1)              => mmcm2dbg
      
    );
  
  cross_clock_bus: entity rvex.bus_crossClock
    port map (
      
      -- Sync logic reset.
      reset                     => reset,
      
      -- Master bus.
      mst_reset                 => reset,
      mst_clk                   => clk,
      mst2crclk                 => dbg2xclk,
      crclk2mst                 => xclk2dbg,
      
      -- Slave bus.
      slv_reset                 => alt_reset,
      slv_clk                   => alt_clk,
      crclk2slv                 => xclk2mem,
      slv2crclk                 => mem2xclk
      
    );
  
  test_memory: entity rvex.bus_ramBlock
    generic map (
      DEPTH_LOG2B               => 16
    )
    port map (
      reset                     => alt_reset,
      clk                       => alt_clk,
      clkEn                     => '1',
      mst2mem_portA             => xclk2mem,
      mem2mst_portA             => mem2xclk,
      mst2mem_portB             => BUS_MST2SLV_IDLE,
      mem2mst_portB             => open
    );
  
  -----------------------------------------------------------------------------
  -- System control
  -----------------------------------------------------------------------------
  sys_ctrl_block: block is
    
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
    
    -- Instantiate clock manipulation/distribution primitive.
    mmcm_inst : MMCM_BASE
      generic map (
        
        -- Input clock is at 200 MHz.
        CLKIN1_PERIOD     => 1000000000.0 / F_SYSCLK,--ns
        
        -- Divide input clock by 4 and multiply it by 20. This should get us
        -- a VCO frequency of 1000 MHz, within the 600-1200 MHz worst case
        -- operating limits.
        DIVCLK_DIVIDE     => 4,
        CLKFBOUT_MULT_F   => 20.0,
        
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
    
  end block;
  
  -----------------------------------------------------------------------------
  -- Alternate system control
  -----------------------------------------------------------------------------
  alt_sys_ctrl_block: block is
    
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
    
    -- Instantiate the MMCM.
    mmcm_inst: entity rvex.utils_clkgen
      generic map (
        CLKIN_PERIOD            => 1000000000.0 / F_SYSCLK,--ns
        INITIAL_POWERDOWN       => '0',
        INITIAL_RESET           => '0',
        VCO_DIVIDE              => 10, -- 20 MHz
        VCO_MULT                => 50, -- 1000 MHz
        CLKOUT0_DIVIDE          => 5   -- 200 MHz
      )
      port map (
        reset                   => reset,
        clk                     => clk,
        clkEn                   => '1',
        bus2clkgen              => dbg2mmcm,
        clkgen2bus              => mmcm2dbg,
        clk_ref                 => sysclk,
        clk_fbi                 => mmcm_fb,
        clk_fbo                 => mmcm_fb,
        locked                  => mmcm_locked,
        clk_o0                  => clk_local
      );
    
    -- Buffer the local clock.
    clk_buffer: BUFG
      port map (
        I => clk_local,
        O => alt_clk
      );
    
    -- Reset generation.
    reset_gen: process (alt_clk, reset, mmcm_locked) is
    begin
      if reset = '1' or mmcm_locked = '0' then
        reset_count <= (others => '0');
        alt_reset <= '1';
      elsif rising_edge(alt_clk) then
        if reset_count = "1111111" then
          alt_reset <= '0';
        else
          reset_count <= reset_count + 1;
          alt_reset <= '1';
        end if;
      end if;
    end process;
    
  end block;
  
  -----------------------------------------------------------------------------
  -- LED outputs
  -----------------------------------------------------------------------------
  clk_led_block: block is
    signal counter : unsigned(26 downto 0);
  begin
    clk_led_proc: process (clk) is
    begin
      if rising_edge(clk) then
        if reset = '1' then
          counter <= (others => '0');
          clk_led <= '0';
        elsif counter(26) = '1' and counter(25) = '1' then
          counter <= (others => '0');
          clk_led <= not clk_led;
        else
          counter <= counter + 1;
        end if;
      end if;
    end process;
  end block;
  
  alt_clk_led_block: block is
    signal counter : unsigned(26 downto 0);
  begin
    alt_clk_led_proc: process (alt_clk) is
    begin
      if rising_edge(alt_clk) then
        if reset = '1' then
          counter <= (others => '0');
          alt_clk_led <= '0';
        elsif counter(26) = '1' and counter(25) = '1' then
          counter <= (others => '0');
          alt_clk_led <= not alt_clk_led;
        else
          counter <= counter + 1;
        end if;
      end if;
    end process;
  end block;
  
  leds <= (
    0 => reset,
    1 => clk_led,
    2 => alt_reset,
    3 => alt_clk_led,
    4 => dbg2uart.busy,
    7 downto 5 => '0'
  );
  
end Behavioral;

