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

library work;
use work.common_pkg.all;
use work.utils_pkg.all;
use work.bus_pkg.all;
use work.core_pkg.all;
use work.core_ctrlRegs_pkg.all;
use work.cache_pkg.all;

--=============================================================================
-- This unit wraps a single r-VEX core, L1 cache, and interrupt controller. It
-- is intended for single core systems (for multicore, you'd want to share a
-- single interrupt controller).
--
-------------------------------------------------------------------------------
-- Block diagram:
--
--             .---------------.     .---------.     .---------.
-- Memory <----|<0xFFFFC000    |     |         |<----|         |
--         ,-' |     demux     |<-o--| arbiter |  :  |         |
--        , .--|>=0xFFFFC000   |  |  |         |<----|  cache  |
--       :  |  '---------------'  |  '---------'     |         |
--       .-----.   (does not    ` '----------------->|snoop    |     .-------.
--       | reg |  use standard   `.         .------->|flush    |<===>|cache  |
--       '-----' bus components*)  `-..     |        '---------'     |       |
--       :  |  .---------.     .---------------.                     |       |
--        ` '->|low-pri  |     |       bit 13=0|-------------------->|debug  |
--         `.  | arbiter |---->|  demux/flush  |     .---------.     | r-VEX |
--  Debug ---->|hi-pri   |     |       bit 13=1|---->|         |     |       |
--             '---------'- - -'---------------'     | irqctrl |<===>|rctrl  |
--   IRQs ------------------------------------------>|         |     |       |
--                                                   '---------'     |       |
--  Trace <----------------------------------------------------------|trace  |
--                                                                   '-------'
--
-- * This hopefully makes it optimize better, and also avoids the problems with
-- the addrConv package with toolchains that do not fully support std_logic
-- during elaboration.
--
-------------------------------------------------------------------------------
-- Memory map:
--  - 0xFFFFFC00..0xFFFFFFFF: own control register file (only from the core).
--  - 0xFFFFE000..0xFFFFE7FF: interrupt controller registers.
--  - 0xFFFFC000..0xFFFFDFFF: core control register files through the debug
--                            bus. Writes to CR_AFF (which is read-only in the
--                            core) direct cache flushes as shown:
--
--          |-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|
-- CR_AFF(w)|           (unused)            |  Data flush   | Instr. flush  |
--          |-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|
-- 
-------------------------------------------------------------------------------
entity rvsys_sairq is
--=============================================================================
  generic (
    
    -- Core configuration. Must be equal to the configuration presented to the
    -- rvex core connected to the cache.
    RCFG                        : rvex_generic_config_type := rvex_cfg;
    
    -- Cache configuration.
    CCFG                        : cache_generic_config_type := cache_cfg;
    
    -- Number of external interrupts to service. Min 1, max 31. The timer
    -- interrupt is shared with interrupt 1.
    IRQ_NUM_IRQ                 : natural := 9;
    
    -- Number of bits in the timer value. 0 for timer disabled. Min 2, max 32
    -- for an actual timer.
    IRQ_TIMER_BITS              : natural := 32;
    
    -- Enables (1) or disables (0) configurable interrupt priorities. That is,
    -- this controls the existence of the PRIOn registers and a double-width
    -- priority decoder.
    IRQ_CONFIG_PRIO_ENABLE      : natural := 1;
    
    -- Enables (1) or disables (0) interrupt nesting support. That is, this
    -- controls the existence of the LEVELn registers and the interrupt level
    -- comparator.
    IRQ_NESTING_ENABLE          : natural := 1;
    
    -- Enables (1) or disables (0) breakpoint broadcasting (i.e. stopping cores
    -- and/or the timer in response to a breakpoint in another core). That is,
    -- this controls the existence of the BRBROn registers and the broadcasting
    -- logic.
    IRQ_BREAKPOINT_BROADCASTING : natural := 1;
    
    -- Enables (1) or disables (0) configurable reset vectors. That is, this
    -- controls the existence of the RVECTn registers. When disabled, the
    -- reset vector output is always zero for each context.
    IRQ_CONFIG_RVECT_ENABLE     : natural := 1;
    
    -- Enables (1) or disables (0) inserting a register in the interrupt
    -- request path from the controller to the processor. This can be used to
    -- break the critical path if it ends up here or decrease the strain on
    -- the router a bit at the cost of an extra cycle's worth of interrupt
    -- latency.
    IRQ_OUTPUT_REGISTER         : natural := 0;
    
    -- Platform version tag. This is put in the global control registers of the
    -- processor.
    PLATFORM_TAG                : std_logic_vector(55 downto 0) := (others => '0');
    
    -- Register consistency check configuration (see core.vhd).
    RCC_RECORD                  : string := "";
    RCC_CHECK                   : string := "";
    RCC_CTXT                    : natural := 0
    
  );
  port (
    
    -- Active high synchronous reset input.
    reset                       : in  std_logic;
    
    -- Clock input, registers are rising edge triggered.
    clk                         : in  std_logic;
    
    -- Active high global clock enable input.
    clkEn                       : in  std_logic;
    
    -- Memory bus for the cache.
    rv2mem                      : out bus_mst2slv_type;
    mem2rv                      : in  bus_slv2mst_type;
    
    -- Debug bus.
    dbg2rv                      : in  bus_mst2slv_type;
    rv2dbg                      : out bus_slv2mst_type;
    
    -- Interrupt inputs (active high strobe).
    irq2rv                      : in  std_logic_vector(IRQ_NUM_IRQ downto 1) := (others => '0');
    
    -- Trace interface
    rv2trsink_push              : out std_logic;
    rv2trsink_data              : out rvex_byte_type;
    rv2trsink_end               : out std_logic;
    trsink2rv_busy              : in  std_logic := '0'
    
  );
end rvsys_sairq;

--=============================================================================
architecture Behavioral of rvsys_sairq is
--=============================================================================
  
  -- Core common memory interface <-> cache.
  signal rv2cache_decouple      : std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal cache2rv_blockReconfig : std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal cache2rv_stallIn       : std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal rv2cache_stallOut      : std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal cache2rv_status        : rvex_cacheStatus_array(2**RCFG.numLaneGroupsLog2-1 downto 0);
  
  -- Core instruction memory interface <-> cache.
  signal rv2icache_PCs          : rvex_address_array(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal rv2icache_fetch        : std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal rv2icache_cancel       : std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal icache2rv_instr        : rvex_syllable_array(2**RCFG.numLanesLog2-1 downto 0);
  signal icache2rv_affinity     : std_logic_vector(2**RCFG.numLaneGroupsLog2*RCFG.numLaneGroupsLog2-1 downto 0);
  signal icache2rv_busFault     : std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
  
  -- Core data memory interface <-> cache.
  signal rv2dcache_addr         : rvex_address_array(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal rv2dcache_readEnable   : std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal rv2dcache_writeData    : rvex_data_array(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal rv2dcache_writeMask    : rvex_mask_array(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal rv2dcache_writeEnable  : std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal rv2dcache_bypass       : std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal dcache2rv_readData     : rvex_data_array(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal dcache2rv_ifaceFault   : std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal dcache2rv_busFault     : std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
  
  -- Cache to arbiter busses.
  signal cache2arb              : bus_mst2slv_array(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal arb2cache              : bus_slv2mst_array(2**RCFG.numLaneGroupsLog2-1 downto 0);
  
  -- Index of the cache block making the current request on cache2bus_arb.
  signal arb_source             : rvex_data_type;
  
  -- Bus snooping interface.
  signal bus2cache_invalAddr    : rvex_address_type;
  signal bus2cache_invalSource  : std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal bus2cache_invalEnable  : std_logic;
  
  -- Cache flush control signal.
  signal sc2dcache_flush        : std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal sc2icache_flush        : std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
  
  -- Arbiter to interconnect.
  signal arb2icon               : bus_mst2slv_type;
  signal icon2arb               : bus_slv2mst_type;
  
  -- r-VEX control/debug bus interface.
  signal icon2rv_addr           : rvex_address_type;
  signal icon2rv_readEnable     : std_logic;
  signal icon2rv_writeEnable    : std_logic;
  signal icon2rv_writeMask      : rvex_mask_type;
  signal icon2rv_writeData      : rvex_data_type;
  signal rv2icon_readData       : rvex_data_type;
  
  -- Interrupt controller interface.
  signal icon2irq               : bus_mst2slv_type;
  signal irq2icon               : bus_slv2mst_type;
  
  -- Core to interrupt controller interface.
  signal irq2rv_irq             : std_logic_vector(2**RCFG.numContextsLog2-1 downto 0);
  signal irq2rv_irqID           : rvex_address_array(2**RCFG.numContextsLog2-1 downto 0);
  signal rv2irq_irqAck          : std_logic_vector(2**RCFG.numContextsLog2-1 downto 0);
  signal irq2rv_run             : std_logic_vector(2**RCFG.numContextsLog2-1 downto 0);
  signal rv2irq_idle            : std_logic_vector(2**RCFG.numContextsLog2-1 downto 0);
  signal rv2irq_break           : std_logic_vector(2**RCFG.numContextsLog2-1 downto 0);
  signal rv2irq_traceStall      : std_logic;
  signal irq2rv_reset           : std_logic_vector(2**RCFG.numContextsLog2-1 downto 0);
  signal irq2rv_resetVect       : rvex_address_array(2**RCFG.numContextsLog2-1 downto 0);
  signal rv2irq_done            : std_logic_vector(2**RCFG.numContextsLog2-1 downto 0);
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- Instantiate the rvex core
  -----------------------------------------------------------------------------
  core: entity work.core
    generic map (
      CFG                       => RCFG,
      CORE_ID                   => 0,
      PLATFORM_TAG              => PLATFORM_TAG,
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
      rctrl2rv_irq              => irq2rv_irq,
      rctrl2rv_irqID            => irq2rv_irqID,
      rv2rctrl_irqAck           => rv2irq_irqAck,
      rctrl2rv_run              => irq2rv_run,
      rv2rctrl_idle             => rv2irq_idle,
      rv2rctrl_break            => rv2irq_break,
      rv2rctrl_traceStall       => rv2irq_traceStall,
      rctrl2rv_reset            => irq2rv_reset,
      rctrl2rv_resetVect        => irq2rv_resetVect,
      rv2rctrl_done             => rv2irq_done,
      
      -- Common memory interface.
      rv2mem_decouple           => rv2cache_decouple,
      mem2rv_blockReconfig      => cache2rv_blockReconfig,
      mem2rv_stallIn            => cache2rv_stallIn,
      rv2mem_stallOut           => rv2cache_stallOut,
      mem2rv_cacheStatus        => cache2rv_status,
      
      -- Instruction memory interface.
      rv2imem_PCs               => rv2icache_PCs,
      rv2imem_fetch             => rv2icache_fetch,
      rv2imem_cancel            => rv2icache_cancel,
      imem2rv_instr             => icache2rv_instr,
      imem2rv_affinity          => icache2rv_affinity,
      imem2rv_busFault          => icache2rv_busFault,
      
      -- Data memory interface.
      rv2dmem_addr              => rv2dcache_addr,
      rv2dmem_readEnable        => rv2dcache_readEnable,
      rv2dmem_writeData         => rv2dcache_writeData,
      rv2dmem_writeMask         => rv2dcache_writeMask,
      rv2dmem_writeEnable       => rv2dcache_writeEnable,
      dmem2rv_readData          => dcache2rv_readData,
      dmem2rv_busFault          => dcache2rv_busFault,
      dmem2rv_ifaceFault        => dcache2rv_ifaceFault,
      
      -- Control/debug bus interface.
      dbg2rv_addr               => icon2rv_addr,
      dbg2rv_readEnable         => icon2rv_readEnable,
      dbg2rv_writeEnable        => icon2rv_writeEnable,
      dbg2rv_writeMask          => icon2rv_writeMask,
      dbg2rv_writeData          => icon2rv_writeData,
      rv2dbg_readData           => rv2icon_readData,
      
      -- Trace interface.
      rv2trsink_push            => rv2trsink_push,
      rv2trsink_data            => rv2trsink_data,
      rv2trsink_end             => rv2trsink_end,
      trsink2rv_busy            => trsink2rv_busy
      
    );
  
  -- Generate the bypass signal.
  bypass_gen: for laneGroup in 0 to 2**RCFG.numLaneGroupsLog2-1 generate
    rv2dcache_bypass(laneGroup) <= rv2dcache_addr(laneGroup)(31);
  end generate;
  
  -----------------------------------------------------------------------------
  -- Instantiate the cache
  -----------------------------------------------------------------------------
  cache: entity work.cache
    generic map (
      RCFG                      => RCFG,
      CCFG                      => CCFG
    )
    port map (
      
      -- System control.
      reset                     => reset,
      clk                       => clk,
      clkEnCPU                  => clkEn,
      clkEnBus                  => clkEn,
      
      -- Common memory interface.
      rv2cache_decouple         => rv2cache_decouple,
      cache2rv_blockReconfig    => cache2rv_blockReconfig,
      cache2rv_stallIn          => cache2rv_stallIn,
      rv2cache_stallOut         => rv2cache_stallOut,
      cache2rv_status           => cache2rv_status,
      
      -- Instruction memory interface.
      rv2icache_PCs             => rv2icache_PCs,
      rv2icache_fetch           => rv2icache_fetch,
      rv2icache_cancel          => rv2icache_cancel,
      icache2rv_instr           => icache2rv_instr,
      icache2rv_affinity        => icache2rv_affinity,
      icache2rv_busFault        => icache2rv_busFault,
      
      -- Data memory interface.
      rv2dcache_addr            => rv2dcache_addr,
      rv2dcache_readEnable      => rv2dcache_readEnable,
      rv2dcache_writeData       => rv2dcache_writeData,
      rv2dcache_writeMask       => rv2dcache_writeMask,
      rv2dcache_writeEnable     => rv2dcache_writeEnable,
      rv2dcache_bypass          => rv2dcache_bypass,
      dcache2rv_readData        => dcache2rv_readData,
      dcache2rv_ifaceFault      => dcache2rv_ifaceFault,
      dcache2rv_busFault        => dcache2rv_busFault,
      
      -- Bus master interface.
      cache2bus_bus             => cache2arb,
      bus2cache_bus             => arb2cache,
      
      -- Bus snooping interface.
      bus2cache_invalAddr       => bus2cache_invalAddr,
      bus2cache_invalSource     => bus2cache_invalSource,
      bus2cache_invalEnable     => bus2cache_invalEnable,
      
      -- Status and control signals.
      sc2icache_flush           => sc2icache_flush,
      sc2dcache_flush           => sc2dcache_flush
      
    );
  
  -- Snoop the debug bus to generate the cache flush signals. Delay doesn't
  -- matter that much here, so we can register this here (they are high-fanout
  -- nets). Behavior one cycle after reset is don't care.
  flush_regs: process (clk) is
  begin
    if rising_edge(clk) then
      if clkEn = '1' then
        sc2icache_flush <= (others => '0');
        sc2dcache_flush <= (others => '0');
        if icon2rv_addr(9 downto 2) = uint2vect(CR_AFF, 8) then
          if icon2rv_writeEnable = '1' then
            if icon2rv_writeMask(0) = '1' then
              sc2icache_flush <= icon2rv_writeData(2**RCFG.numLaneGroupsLog2-1 downto 0);
            end if;
            if icon2rv_writeMask(1) = '1' then
              sc2dcache_flush <= icon2rv_writeData(2**RCFG.numLaneGroupsLog2+7 downto 8);
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;
  
  -----------------------------------------------------------------------------
  -- Bus access arbiter
  -----------------------------------------------------------------------------
  cache_arbiter: entity work.bus_arbiter
    generic map (
      NUM_MASTERS               => 2**RCFG.numLaneGroupsLog2
    )
    port map (
      
      -- System control.
      reset                     => reset,
      clk                       => clk,
      clkEn                     => clkEn,
      
      -- Master busses.
      mst2arb                   => cache2arb,
      arb2mst                   => arb2cache,
      
      -- Slave bus.
      arb2slv                   => arb2icon,
      slv2arb                   => icon2arb,
      
      -- Index of the master which is making the current bus request.
      arb2slv_source            => arb_source
      
    );
  
  -----------------------------------------------------------------------------
  -- Cache line invalidation (snooping)
  -----------------------------------------------------------------------------
  -- Connect address end enable. Only enable invalidation when the access is in
  -- the lower half of the address space, as the upper half is uncached.
  bus2cache_invalAddr   <= arb2icon.address;
  bus2cache_invalEnable <= arb2icon.writeEnable
                           and not arb2icon.address(31);
  
  -- Decode arb2slv_source to get the bus2cache_invalSource signal.
  inval_source_proc: process (arb_source) is
  begin
    bus2cache_invalSource <= (others => '0');
    for laneGroup in 0 to 2**RCFG.numLaneGroupsLog2-1 loop
      if vect2uint(arb_source) = laneGroup then
        bus2cache_invalSource(laneGroup) <= '1';
      end if;
    end loop;
  end process;
  
  -----------------------------------------------------------------------------
  -- Interrupt controller
  -----------------------------------------------------------------------------
  irq_ctrl: entity work.periph_irq
    generic map (
      BASE_ADDRESS              => X"FFFFE000",
      NUM_CONTEXTS              => 2**RCFG.numContextsLog2,
      NUM_IRQ                   => IRQ_NUM_IRQ,
      TIMER_BITS                => IRQ_TIMER_BITS,
      CONFIG_PRIO_ENABLE        => IRQ_CONFIG_PRIO_ENABLE,
      NESTING_ENABLE            => IRQ_NESTING_ENABLE,
      BREAKPOINT_BROADCASTING   => IRQ_BREAKPOINT_BROADCASTING,
      CONFIG_RVECT_ENABLE       => IRQ_CONFIG_RVECT_ENABLE,
      OUTPUT_REGISTER           => IRQ_OUTPUT_REGISTER
    )
    port map (
      
      -- System control.
      reset                     => reset,
      clk                       => clk,
      clkEn                     => clkEn,
      
      -- r-VEX interface.
      irq2rv_irq                => irq2rv_irq,
      irq2rv_irqID              => irq2rv_irqID,
      rv2irq_irqAck             => rv2irq_irqAck,
      irq2rv_run                => irq2rv_run,
      rv2irq_idle               => rv2irq_idle,
      rv2irq_break              => rv2irq_break,
      rv2irq_traceStall         => rv2irq_traceStall,
      irq2rv_reset              => irq2rv_reset,
      irq2rv_resetVect          => irq2rv_resetVect,
      rv2irq_done               => rv2irq_done,
     
      -- Interrupt inputs.
      periph2irq                => irq2rv,
      
      -- Bus interface.
      bus2irq                   => icon2irq,
      irq2bus                   => irq2icon
      
    );
  
  -----------------------------------------------------------------------------
  -- Bus interconnect
  -----------------------------------------------------------------------------
  -- The block below implements the following:
  --
  --             .-------------.
  --             |  <0xFFFFC000|------------------------------------> rv2mem
  -- arb2icon -->|    demux    |   .---.   .---------.   .-------.
  --             | >=0xFFFFC000|-->|reg|-->|low-pri  |   |  b13=0|--> icon2rv
  --             '-------------'   '---'   | arbiter |-->| demux |
  --   dbg2rv ---------------------------->|hi-pri   |   |  b13=1|--> icon2irq
  --                                       '---------'   '-------'
  icon_block: block is
  begin
    -- TODO
  end block;
  
end Behavioral;

