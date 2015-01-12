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

library rvex;
use rvex.common_pkg.all;
use rvex.bus_pkg.all;
use rvex.bus_addrConv_pkg.all;
use rvex.core_pkg.all;
use rvex.cache_pkg.all;
use rvex.rvsys_grlib_pkg.all;

library grlib;
use grlib.amba.all;
use grlib.devices.all;

library gaisler;
use gaisler.leon3.all;

--=============================================================================
-- This entity is designed such that it can be used in place of the LEON3 core
-- from grlib.
-------------------------------------------------------------------------------
entity rvsys_grlib is
--=============================================================================
  generic (
    
    -- Configuration vector.
    CFG                         : rvex_grlib_generic_config_type := rvex_grlib_cfg;
    
    -- AHB master starting index. There will be as many AHB masters as there
    -- are lane groups in the core.
    AHB_MASTER_INDEX_START      : integer range 0 to NAHBMST-1 := 0
    
  );
  port (
    
    ---------------------------------------------------------------------------
    -- System control
    ---------------------------------------------------------------------------
    -- Clock input, registers are rising edge triggered.
    clki                        : in  std_ulogic;
    
    -- Active *low* synchronous reset input.
    rstn                        : in  std_ulogic;
    
    ---------------------------------------------------------------------------
    -- Processor interface
    ---------------------------------------------------------------------------
    -- AHB master interface. This is used for instruction and data access. Each
    -- lane group has its own AHB master.
    ahbmi                       : in  ahb_mst_in_type;
    ahbmo                       : out ahb_mst_out_vector_type(2**CFG.core.numLaneGroupsLog2-1 downto 0);
    
    -- AHB slave input for bus snooping.
    ahbsi                       : in  ahb_slv_in_type;
    
    -- Slave rvex bus, to be connected to an ahb2bus bridge up the hierarchy.
    -- Used to access debug control and status registers for the core, cache
    -- and any other support systems. The register map is as follows.
    --          _____________________________
    --  0x1FFF | Context 7 GP reg 32-63      |
    --  0x1F80 |_____________________________|
    --         |_____________________________|
    --  0x1EFF | Context 7 GP reg 0-31       |
    --  0x1E80 |_____________________________|
    --  0x1E7F | Context 7 ctrl regs         |
    --  0x1E00 |_____________________________|
    --  0x1DFF | (context 1..6 mapped here)  |
    --  0x1200 |_____________________________|
    --  0x11FF | Context 0 GP reg 32-63      |
    --  0x1180 |_____________________________|
    --         |_____________________________|
    --  0x10FF | Context 0 GP reg 0-31       |
    --  0x1080 |_____________________________|
    --  0x107F | Context 0 ctrl regs         |
    --  0x1000 |_____________________________|
    --         |_____________________________| _
    --  0x01FF | Context i GP reg 0-31/32-63 |  \
    --  0x0180 |_____________________________|   \ Context and GP registers are
    --  0x017F | Context i ctrl regs         |   / selected using bank register
    --  0x0100 |_____________________________| _/
    --  0x00FF | Reserved for MMU regs       |
    --  0x0080 |_____________________________|
    --  0x007F | Reserved for cache regs     |
    --  0x0040 |_____________________________|
    --  0x003F | Global regs                 |
    --  0x0000 |_____________________________|
    --
    bus2dgb                     : in  bus_mst2slv_type;
    dbg2bus                     : out bus_slv2mst_type;
    
    -- Interrupt controller interface. This entity handles translation from the
    -- LEON3 interrupt controller to the rvex interrupt control signals. Note
    -- that each rvex context requires its own interrupt controller.
    irqi                        : in  irq_in_vector(0 to 2**CFG.core.numContextsLog2-1);
    irqo                        : out irq_out_vector(0 to 2**CFG.core.numContextsLog2-1)
    
  );
end rvsys_grlib;

--=============================================================================
architecture Behavioral of rvsys_grlib is
--=============================================================================
  
  -- System control signals in the rvex library format.
  signal resetCPU               : std_logic;
  signal resetBus               : std_logic;
  signal clk                    : std_logic;
  signal clkEnCPU               : std_logic;
  signal clkEnBus               : std_logic;
  
  -- Soft reset signal from the APB bus.
  signal dbg_reset              : std_logic;
  
  -- rvex interrupt interface signals.
  signal rctrl2rv_irq           : std_logic_vector(2**CFG.core.numContextsLog2-1 downto 0);
  signal rctrl2rv_irqID         : rvex_address_array(2**CFG.core.numContextsLog2-1 downto 0);
  signal rv2rctrl_irqAck        : std_logic_vector(2**CFG.core.numContextsLog2-1 downto 0);
  
  -- Common cache interface signals.
  signal rv2cache_decouple      : std_logic_vector(2**CFG.core.numLaneGroupsLog2-1 downto 0);
  signal cache2rv_blockReconfig : std_logic_vector(2**CFG.core.numLaneGroupsLog2-1 downto 0);
  signal cache2rv_stallIn       : std_logic_vector(2**CFG.core.numLaneGroupsLog2-1 downto 0);
  signal rv2cache_stallOut      : std_logic_vector(2**CFG.core.numLaneGroupsLog2-1 downto 0);
  
  -- Instruction cache interface signals.
  signal rv2icache_PCs          : rvex_address_array(2**CFG.core.numLaneGroupsLog2-1 downto 0);
  signal rv2icache_fetch        : std_logic_vector(2**CFG.core.numLaneGroupsLog2-1 downto 0);
  signal rv2icache_cancel       : std_logic_vector(2**CFG.core.numLaneGroupsLog2-1 downto 0);
  signal icache2rv_instr        : rvex_syllable_array(2**CFG.core.numLanesLog2-1 downto 0);
  signal icache2rv_affinity     : std_logic_vector(2**CFG.core.numLaneGroupsLog2*CFG.core.numLaneGroupsLog2-1 downto 0);
  
  -- Data cache interface signals.
  signal rv2dcache_addr         : rvex_address_array(2**CFG.core.numLaneGroupsLog2-1 downto 0);
  signal rv2dcache_readEnable   : std_logic_vector(2**CFG.core.numLaneGroupsLog2-1 downto 0);
  signal rv2dcache_writeData    : rvex_data_array(2**CFG.core.numLaneGroupsLog2-1 downto 0);
  signal rv2dcache_writeMask    : rvex_mask_array(2**CFG.core.numLaneGroupsLog2-1 downto 0);
  signal rv2dcache_writeEnable  : std_logic_vector(2**CFG.core.numLaneGroupsLog2-1 downto 0);
  signal rv2dcache_bypass       : std_logic_vector(2**CFG.core.numLaneGroupsLog2-1 downto 0);
  signal dcache2rv_readData     : rvex_data_array(2**CFG.core.numLaneGroupsLog2-1 downto 0);
  
  -- Cache to AHB bus bridge interface signals.
  signal cache2bridge_bus       : bus_mst2slv_array(2**CFG.core.numLaneGroupsLog2-1 downto 0);
  signal bridge2cache_bus       : bus_slv2mst_array(2**CFG.core.numLaneGroupsLog2-1 downto 0);
  
  -- Bus snooper cache invalidation signals.
  signal bus2cache_invalAddr    : rvex_address_type;
  signal bus2cache_invalSource  : std_logic_vector(2**CFG.core.numLaneGroupsLog2-1 downto 0);
  signal bus2cache_invalEnable  : std_logic;
  
  -- Flush control signals.
  signal sc2icache_flush        : std_logic_vector(2**CFG.core.numLaneGroupsLog2-1 downto 0);
  signal sc2dcache_flush        : std_logic_vector(2**CFG.core.numLaneGroupsLog2-1 downto 0);
  
  -- Debug bus demuxer to global control registers.
  signal demux2glob             : bus_mst2slv_type;
  signal glob2demux             : bus_slv2mst_type;
  
  -- Debug bus demuxer to cache control registers.
  signal demux2cache            : bus_mst2slv_type;
  signal cache2demux            : bus_slv2mst_type;
  
  -- Debug bus demuxer to MMU control registers.
  signal demux2mmu              : bus_mst2slv_type;
  signal mmu2demux              : bus_slv2mst_type;
  
  -- Debug bus demuxer to core control registers.
  signal demux2rv               : bus_mst2slv_type;
  signal rv2demux               : bus_slv2mst_type;
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- System control
  -----------------------------------------------------------------------------
  resetCPU  <= dbg_reset or not rstn;
  resetBus  <= not rstn;
  clk       <= clki;
  
  -- clkEnCPU and clkEnBus kinda don't work in this platform because there's no
  -- synchronization between the debug register bus and the registers, and
  -- the bus clk is always enabled because AMBA doesn't have a clock enable. So
  -- they're just tied to '1' here and exist only as a formality.
  clkEnCPU  <= '1';
  clkEnBus  <= '1';
  
  -----------------------------------------------------------------------------
  -- Instantiate the rvex core
  -----------------------------------------------------------------------------
  rvex_block: block is
    
    -- Raw rvex debug bus interface signals.
    signal dbg2rv_addr          : rvex_address_type;
    signal dbg2rv_readEnable    : std_logic;
    signal dbg2rv_writeEnable   : std_logic;
    signal dbg2rv_writeMask     : rvex_mask_type;
    signal dbg2rv_writeData     : rvex_data_type;
    signal rv2dbg_readData      : rvex_data_type;
    
    -- Bus ack register.
    signal ack                  : std_logic;
    
  begin
    
    -- Instantiate the rvex core.
    rvex_inst: entity rvex.core
      generic map (
        CFG                       => CFG.core
      )
      port map (
        
        -- System control.
        reset                     => resetCPU,
        clk                       => clk,
        clkEn                     => clkEnCPU,
        
        -- Run control interface.
        rctrl2rv_irq              => rctrl2rv_irq,
        rctrl2rv_irqID            => rctrl2rv_irqID,
        rv2rctrl_irqAck           => rv2rctrl_irqAck,
        
        -- Common memory interface.
        rv2mem_decouple           => rv2cache_decouple,
        mem2rv_blockReconfig      => cache2rv_blockReconfig,
        mem2rv_stallIn            => cache2rv_stallIn,
        rv2mem_stallOut           => rv2cache_stallOut,
        
        -- Instruction memory interface.
        rv2imem_PCs               => rv2icache_PCs,
        rv2imem_fetch             => rv2icache_fetch,
        rv2imem_cancel            => rv2icache_cancel,
        imem2rv_instr             => icache2rv_instr,
        imem2rv_affinity          => icache2rv_affinity,
        
        -- Data memory interface.
        rv2dmem_addr              => rv2dcache_addr,
        rv2dmem_readEnable        => rv2dcache_readEnable,
        rv2dmem_writeData         => rv2dcache_writeData,
        rv2dmem_writeMask         => rv2dcache_writeMask,
        rv2dmem_writeEnable       => rv2dcache_writeEnable,
        dmem2rv_readData          => dcache2rv_readData,
        
        -- Control/debug bus interface.
        dbg2rv_addr               => dbg2rv_addr,
        dbg2rv_readEnable         => dbg2rv_readEnable,
        dbg2rv_writeEnable        => dbg2rv_writeEnable,
        dbg2rv_writeMask          => dbg2rv_writeMask,
        dbg2rv_writeData          => dbg2rv_writeData,
        rv2dbg_readData           => rv2dbg_readData
        
      );
    
    -- Connect the debug bus.
    dbg2rv_addr         <= demux2rv.address;
    dbg2rv_readEnable   <= demux2rv.readEnable;
    dbg2rv_writeEnable  <= demux2rv.writeEnable;
    dbg2rv_writeMask    <= demux2rv.writeMask;
    dbg2rv_writeData    <= demux2rv.writeData;
    
    -- Generate the bus acknowledge signal.
    ack_reg_proc: process (clk) is
    begin
      if rising_edge(clk) then
        if resetBus = '1' then
          ack <= '0';
        elsif clkEnBus = '1' then
          ack <= demux2rv.readEnable or demux2rv.writeEnable;
        end if;
      end if;
    end process;
    
    -- Drive the bus result signals.
    bus_result_proc: process (rv2dbg_readData, ack) is
    begin
      rv2demux <= BUS_SLV2MST_IDLE;
      rv2demux.ack <= ack;
      rv2demux.readData <= rv2dbg_readData;
    end process;
    
  end block;
  -----------------------------------------------------------------------------
  -- Generate the bypass signals
  -----------------------------------------------------------------------------
  -- When the bypass signal is high, memory accesses bypass the cache. This is
  -- important for peripheral accesses. Because the rvex core does not generate
  -- such a signal, we generate one here based on the address: we assume that
  -- everything in the high 2 GiB memory space is mapped to peripherals and
  -- should not be cached.
  bypass_gen: for laneGroup in 2**CFG.core.numLaneGroupsLog2-1 downto 0 generate
    rv2dcache_bypass(laneGroup) <= rv2dcache_addr(laneGroup)(31);
  end generate;
  
  -----------------------------------------------------------------------------
  -- Instantiate the cache
  -----------------------------------------------------------------------------
  cache_inst: entity rvex.cache
    generic map (
      RCFG                      => CFG.core,
      CCFG                      => CFG.cache
    )
    port map (
      
      -- System control.
      reset                     => resetCPU,
      clk                       => clk,
      clkEnCPU                  => clkEnCPU,
      clkEnBus                  => clkEnBus,
      
      -- Core common memory interface.
      rv2cache_decouple         => rv2cache_decouple,
      cache2rv_blockReconfig    => cache2rv_blockReconfig,
      cache2rv_stallIn          => cache2rv_stallIn,
      rv2cache_stallOut         => rv2cache_stallOut,
      
      -- Core instruction memory interface.
      rv2icache_PCs             => rv2icache_PCs,
      rv2icache_fetch           => rv2icache_fetch,
      rv2icache_cancel          => rv2icache_cancel,
      icache2rv_instr           => icache2rv_instr,
      icache2rv_affinity        => icache2rv_affinity,
      
      -- Core data memory interface.
      rv2dcache_addr            => rv2dcache_addr,
      rv2dcache_readEnable      => rv2dcache_readEnable,
      rv2dcache_writeData       => rv2dcache_writeData,
      rv2dcache_writeMask       => rv2dcache_writeMask,
      rv2dcache_writeEnable     => rv2dcache_writeEnable,
      rv2dcache_bypass          => rv2dcache_bypass,
      dcache2rv_readData        => dcache2rv_readData,
      
      -- Bus master interface.
      cache2bus_bus             => cache2bridge_bus,
      bus2cache_bus             => bridge2cache_bus,
      
      -- Bus snooping interface.
      bus2cache_invalAddr       => bus2cache_invalAddr,
      bus2cache_invalSource     => bus2cache_invalSource,
      bus2cache_invalEnable     => bus2cache_invalEnable,
      
      -- Status and control signals.
      sc2icache_flush           => sc2icache_flush,
      sc2dcache_flush           => sc2dcache_flush
      
    );
  
  -- Instantiate the cache registers.
  cache_control_reg_proc: process (clk) is
    
    -- Assigns signals to their reset/idle/default state.
    procedure defaultState is
    begin
      cache2demux <= BUS_SLV2MST_IDLE;
      sc2icache_flush <= (others => '0');
      sc2dcache_flush <= (others => '0');
    end defaultState;
    
  begin
    if rising_edge(clk) then
      if resetBus = '1' then
        defaultState;
      elsif clkEnBus = '1' then
        defaultState;
        
        -- Acknowledge any bus requests we're given.
        cache2demux.ack <= bus_requesting(demux2cache);
        
        -- Address 0x00 write: instruction cache flush bits.
        if bus_writing(demux2cache, "--------------------------000000") then
          sc2icache_flush <= demux2cache.writeData(
            2**CFG.core.numLaneGroupsLog2 + 23 downto 24
          );
        end if;
        
        -- Address 0x01 write: data cache flush bits.
        if bus_writing(demux2cache, "--------------------------000001") then
          sc2dcache_flush <= demux2cache.writeData(
            2**CFG.core.numLaneGroupsLog2 + 23 downto 24
          );
        end if;
        
      end if;
    end if;
  end process;
  
  -----------------------------------------------------------------------------
  -- Instantiate the AHB bus bridges
  -----------------------------------------------------------------------------
  ahb_bus_bridge_gen: for laneGroup in 2**CFG.core.numLaneGroupsLog2-1 downto 0 generate
    
    ahb_bus_bridge_inst: entity rvex.bus2ahb
      generic map (
        
        -- Generic information as passed to grlib.dma2ahb.
        AHB_MASTER_INDEX        => AHB_MASTER_INDEX_START + laneGroup,
        AHB_VENDOR_ID           => VENDOR_TUDELFT,
        AHB_DEVICE_ID           => TUDELFT_RVEX,
        AHB_VERSION             => 0,
        
        -- rvex bus fault code used to indicate that an AHB bus error occured.
        BUS_ERROR_CODE          => X"00000000",
        
        -- rvex bus fault code used to indicate that an invalid rvex bus
        -- request was issued.
        REQ_ERROR_CODE          => X"00000001"
        
      )
      port map (
        
        -- System control.
        reset                   => resetBus,
        clk                     => clk,
        
        -- rvex library slave bus interface.
        bus2bridge              => cache2bridge_bus(laneGroup),
        bridge2bus              => bridge2cache_bus(laneGroup),
        
        -- AHB master interface.
        bridge2ahb              => ahbmo(laneGroup),
        ahb2bridge              => ahbmi
        
      );
    
  end generate;
  
  -----------------------------------------------------------------------------
  -- Bus snooper
  -----------------------------------------------------------------------------
  ahb_snoop_inst: entity rvex.ahb_snoop
    generic map (
      FIRST_MASTER        => AHB_MASTER_INDEX_START,
      NUM_CACHE_BLOCKS    => 2**CFG.core.numLaneGroupsLog2
    )
    port map (
      
      -- System control.
      reset               => resetBus,
      clk                 => clk,
      
      -- AHB interface.
      ahbsi               => ahbsi,
        
      -- Cache interface.
      invalAddr           => bus2cache_invalAddr,
      invalSource         => bus2cache_invalSource,
      invalEnable         => bus2cache_invalEnable
      
    );
  
  -----------------------------------------------------------------------------
  -- Interrupt controller bridge
  -----------------------------------------------------------------------------
  irq_bridge_gen: for ctxt in 2**CFG.core.numContextsLog2-1 downto 0 generate
    
    -- TODO
    rctrl2rv_irq(ctxt)    <= '0';
    rctrl2rv_irqID(ctxt)  <= (others => '0');
    irqo(ctxt).intack     <= '0';
    irqo(ctxt).irl        <= "0000";
    irqo(ctxt).pwd        <= '0';
    irqo(ctxt).fpen       <= '0';
    irqo(ctxt).idle       <= '1';
    
  end generate;
  
  -----------------------------------------------------------------------------
  -- Global control registers
  -----------------------------------------------------------------------------
  global_control_reg_proc: process (clk) is
    
    -- Assigns signals to their reset/idle/default state.
    procedure defaultState is
    begin
      glob2demux <= BUS_SLV2MST_IDLE;
      dbg_reset <= '0';
    end defaultState;
    
  begin
    if rising_edge(clk) then
      if resetBus = '1' then
        defaultState;
      elsif clkEnBus = '1' then
        defaultState;
        
        -- Acknowledge any bus requests we're given.
        glob2demux.ack <= bus_requesting(demux2glob);
        
        -- Address 0x00 write: reset rvex system.
        if bus_writing(demux2cache, "--------------------------000000") then
          dbg_reset <= '1';
        end if;
        
      end if;
    end if;
  end process;
  
  -----------------------------------------------------------------------------
  -- Debug bus demuxer
  -----------------------------------------------------------------------------
  debug_bus_demux_block: block is
    
    constant ADDR_MAP : addrRangeAndMapping_array(0 to 3) := (
      0 => addrRangeAndMap( -- Global status/ctrl (64 bytes).
        low   => "00000000000000000000000000000000",
        high  => "00000000000000000000000000111111",
        mask  => "00000000000000000001111111111111"
      ),
      1 => addrRangeAndMap( -- Cache status/ctrl (64 bytes).
        low   => "00000000000000000000000001000000",
        high  => "00000000000000000000000001111111",
        mask  => "00000000000000000001111111111111"
      ),
      2 => addrRangeAndMap( -- MMU status/ctrl (128 bytes).
        low   => "00000000000000000000000010000000",
        high  => "00000000000000000000000011111111",
        mask  => "00000000000000000001111111111111"
      ),
      3 => addrRangeAndMap( -- rvex debug interface (at least 256 bytes).
        low   => "00000000000000000000000100000000",
        high  => "00000000000000000001111111111111",
        mask  => "00000000000000000001111111111111"
      )
    );
    
  begin
    
    -- Instantiate the demuxing unit.
    debug_bus_demux_inst: entity rvex.bus_demux
      generic map (
        ADDRESS_MAP       => ADDR_MAP
      )
      port map (
        
        -- System control.
        reset             => resetBus,
        clk               => clk,
        clkEn             => clkEnBus,
        
        -- Busses.
        mst2demux         => bus2dgb,
        demux2mst         => dbg2bus,
        demux2slv(0)      => demux2glob,
        demux2slv(1)      => demux2cache,
        demux2slv(2)      => demux2mmu,
        demux2slv(3)      => demux2rv,
        slv2demux(0)      => glob2demux,
        slv2demux(1)      => cache2demux,
        slv2demux(2)      => mmu2demux,
        slv2demux(3)      => rv2demux
        
      );
    
  end block;
  
  -- Respond with bus faults to the registers reserved for the MMU.
  mmu_control_reg_proc: process (clk) is
    
    -- Assigns signals to their reset/idle/default state.
    procedure defaultState is
    begin
      mmu2demux <= BUS_SLV2MST_IDLE;
    end defaultState;
    
  begin
    if rising_edge(clk) then
      if resetBus = '1' then
        defaultState;
      elsif clkEnBus = '1' then
        defaultState;
        
        -- Return a bus fault for any address.
        mmu2demux.ack <= bus_requesting(demux2mmu);
        mmu2demux.fault <= '1';
        
      end if;
    end if;
  end process;
  
end Behavioral;

