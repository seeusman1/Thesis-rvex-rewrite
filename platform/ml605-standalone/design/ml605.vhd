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

library work;
use work.mem_init_pkg.all;
use work.platform_version_pkg.all;


--=============================================================================
-- This is the toplevel file for synthesizing a basic rvex platform on a Xilinx
-- ML605 Virtex-6 evaluation board.
-------------------------------------------------------------------------------
entity ml605 is
--=============================================================================
  generic (
    
    -- Clock division value. The internal clock will be 750 MHz divided by this
    -- number. Ignored when DIRECT_RESET_AND_CLOCK is set.
    DIV_VAL                     : natural := 20; -- 37.5 MHz
    
    -- Baud rate to use for the UART.
    F_BAUD                      : real := 115200.0;
    
    -- When set, sysclk_p and resetButton are directly fed into the rvex and
    -- UART block as clk and reset. This may be used to speed up simulation
    -- when full syscon accuracy is not needed. When set, F_SYSCLK is used to
    -- configure the baud rate of the UART; it is ignored otherwise.
    DIRECT_RESET_AND_CLOCK      : boolean := false;
    F_SYSCLK                    : real := 200000000.0; -- 200 MHz
    
    -- Register consistency check configuration (see core.vhd).
    RCC_RECORD                  : string := "";
    RCC_CHECK                   : string := "";
    RCC_CTXT                    : natural := 0
    
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
  
  -- Core and standalone system configuration WITHOUT cache.
  constant CFG                  : rvex_sa_generic_config_type := rvex_sa_cfg(
    core => rvex_cfg(
      numLanesLog2              => 3,
      numLaneGroupsLog2         => 2,
      numContextsLog2           => 2,
      traceEnable               => 1
    ),
    core_valid                  => true,
    imemDepthLog2B              => 18, -- 256 kiB (0x00000..0x3FFFF)
    dmemDepthLog2B              => 18
  );
  
  -- Core and standalone system configuration WITH cache.
  --constant CFG                  : rvex_sa_generic_config_type := rvex_sa_cfg(
--    core => rvex_cfg(
--      numLanesLog2              => 3,
--      numLaneGroupsLog2         => 2,
--      numContextsLog2           => 2,
--      traceEnable               => 1
--    ),
--    core_valid                  => true,
--    cache_enable                => 1,
--    cache_config => cache_cfg(
--      instrCacheLinesLog2       => 8, -- 256*32 = 8 kiB per block, 32 kiB total
--      dataCacheLinesLog2        => 8  -- 256*4 = 1 kiB per block, 4 kiB total
--    ),
--    cache_config_valid          => true,
--    dmemDepthLog2B              => 18 -- 256 kiB (0x00000..0x3FFFF)
--  );
  
  -- S-rec file specifying the initial contents for the memories.
  constant SREC_FILENAME        : string := "../test-progs/init.srec";
  
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
    
    constant DEBUG_ADDRESS_MAP    : addrRangeAndMapping_array(0 to 1) := (
      
      -- Standalone platform debug port.
      --   0x10------ = IMEM
      --   0x20------ = DMEM
      --   0x30------ = write only DMEM + IMEM
      --   0xF0------ = core debug port
      0 => addrRangeAndMap(
        match => "----0000------------------------"
      ),
      
      -- RIT timer.
      --   0xF1------ = RIT timer.
      1 => addrRangeAndMap(
        match => "----0001------------------------"
      )
      
    );
    
    -- Peripheral bus.
    signal rvsa2bus               : bus_mst2slv_type;
    signal bus2rvsa               : bus_slv2mst_type;
    
    -- Debug bus from the UART.
    signal uart2dbg               : bus_mst2slv_type;
    signal dbg2uart               : bus_slv2mst_type;
    
    -- Standalone core debug access bus.
    signal dbg2rvsa               : bus_mst2slv_type;
    signal rvsa2dbg               : bus_slv2mst_type;
    
    -- RIT access bus.
    signal dbg2rit                : bus_mst2slv_type;
    signal rit2dbg                : bus_slv2mst_type;
    
    -- Interrupt signals from and to the core.
    signal rctrl2rvsa_irq         : std_logic_vector(2**CFG.core.numContextsLog2-1 downto 0);
    signal rctrl2rvsa_irqID       : rvex_address_array(2**CFG.core.numContextsLog2-1 downto 0);
    signal rvsa2rctrl_irqAck      : std_logic_vector(2**CFG.core.numContextsLog2-1 downto 0);
    
    -- Local transmit signal, so we can also tie it to an LED.
    signal tx_s                   : std_logic;
    
  begin
    
    rvex_inst: entity rvex.rvsys_standalone
      generic map (
        
        -- Configuration.
        CFG                       => CFG,
        
        -- Platform version tag.
        PLATFORM_TAG              => RVEX_PLATFORM_TAG,
        
        -- S-rec file specifying the initial contents for the memories.
        MEM_INIT                  => MEM_INIT,
        
        -- Register consistency check configuration (see core.vhd).
        RCC_RECORD                => RCC_RECORD,
        RCC_CHECK                 => RCC_CHECK,
        RCC_CTXT                  => RCC_CTXT
        
      )
      port map (
        
        -- System control.
        reset                     => reset,
        clk                       => clk,
        clkEn                     => clkEn,
        
        -- Run control interface.
        rctrl2rvsa_irq            => rctrl2rvsa_irq,
        rctrl2rvsa_irqID          => rctrl2rvsa_irqID,
        rvsa2rctrl_irqAck         => rvsa2rctrl_irqAck,
        
        -- Bus interfaces.
        rvsa2bus                  => rvsa2bus,
        bus2rvsa                  => bus2rvsa,
        debug2rvsa                => dbg2rvsa,
        rvsa2debug                => rvsa2dbg
        
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
        tx                        => tx_s,
        
        -- Slave bus.
        bus2uart                  => rvsa2bus,
        uart2bus                  => bus2rvsa,
        irq                       => open,
        
        -- Debug interface.
        uart2dbg_bus              => uart2dbg,
        dbg2uart_bus              => dbg2uart
        
      );
    
    dbg_bus_demux: entity rvex.bus_demux
      generic map (
        ADDRESS_MAP               => DEBUG_ADDRESS_MAP
      )
      port map (
        
        -- System control.
        reset                     => reset,
        clk                       => clk,
        clkEn                     => clkEn,
        
        -- Busses.
        mst2demux                 => uart2dbg,
        demux2mst                 => dbg2uart,
        demux2slv(0)              => dbg2rvsa,
        demux2slv(1)              => dbg2rit,
        slv2demux(0)              => rvsa2dbg,
        slv2demux(1)              => rit2dbg
        
      );
    
    -- Repititive interrupt timer.
    rit_block: block is
      
      -- Interrupt pending and acknowledge flags.
      signal rit_pend             : std_logic;
      signal rit_ack              : std_logic;
      
      -- Current timer and max timer value.
      signal rit_timer            : rvex_data_type;
      signal rit_max              : rvex_data_type;
      
    begin
      
      -- Broadcast the RIT overflow interrupt flag to all contexts as interrupt
      -- ID 1.
      rctrl2rvsa_irq
        <= (others => rit_pend);
      rctrl2rvsa_irqID
        <= (others => X"00000001") when rit_pend = '1' else (others => X"00000000");
      
      -- Combine all the interrupt acknowledge signals into a single ack signal.
      rit_ack_proc: process (rvsa2rctrl_irqAck) is
      begin
        rit_ack <= '0';
        for ctxt in 0 to 2**CFG.core.numContextsLog2-1 loop
          if rvsa2rctrl_irqAck(ctxt) = '1' then
            rit_ack <= '1';
          end if;
        end loop;
      end process;
      
      -- Create the RIT timer.
      rit_regs: process (clk) is
      begin
        if rising_edge(clk) then
          if reset = '1' then
            rit_pend  <= '0';
            rit_timer <= X"00000000";
            rit_max   <= X"0000FFFF";
            rit2dbg   <= BUS_SLV2MST_IDLE;
          elsif clkEn = '1' then
            
            -- Clear the pending flag when we get an acknowledge from a core.
            if rit_ack = '1' then
              rit_pend <= '0';
            end if;
            
            -- Increment the timer, checking for overflows.
            if rit_timer = rit_max then
              rit_timer <= (others => '0');
              rit_pend <= '1';
            else
              rit_timer <= std_logic_vector(unsigned(rit_timer) + 1);
            end if;
            
            -- Handle bus commands.
            rit2dbg <= BUS_SLV2MST_IDLE;
            if dbg2rit.readEnable = '1' then
              if dbg2rit.address(2) = '0' then
                rit2dbg.readData <= rit_timer;
              else
                rit2dbg.readData <= rit_max;
              end if;
              rit2dbg.ack <= '1';
            elsif dbg2rit.writeEnable = '1' then
              if dbg2rit.writeMask = "1111" then
                if dbg2rit.address(2) = '0' then
                  rit_timer <= dbg2rit.writeData;
                else
                  rit_max <= dbg2rit.writeData;
                end if;
              end if;
              rit2dbg.ack <= '1';
            end if;
            
          end if;
        end if;
      end process;
      
    end block;
    
    -- Tie LEDs to useful signals.
    leds <= (
      0 => rx,
      1 => tx_s,
      2 => '0',
      3 => rctrl2rvsa_irq(0),
      4 => '0',
      5 => '0',
      6 => '0',
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

