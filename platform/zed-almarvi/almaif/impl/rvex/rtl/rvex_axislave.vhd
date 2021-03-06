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
use work.bus_addrConv_pkg.all;
use work.core_pkg.all;
use work.cache_pkg.all;
use work.rvsys_standalone_pkg.all;

--=============================================================================
-- This unit wraps the rvex core as an accelerator with its own local block RAM
-- memories, accessible through an AXI4 slave interface. The interface complies
-- with the ALMARVI accelerator interface specification.
-------------------------------------------------------------------------------
entity rvex_axislave is
--=============================================================================
  generic (
    
    -- Width of the AXI address ports. Must be equal to
    -- 2 + max(
    --   12 + NUM_CONTEXTS_LOG2,
    --   IMEM_DEPTH_LOG2,
    --   DMEM_DEPTH_LOG2,
    --   PMEM_DEPTH_LOG2
    -- )
    AXI_ADDRW_G                 : integer := 17;
    
    -- 2-log of the number of bytes in the instruction memory.
    IMEM_DEPTH_LOG2             : integer := 15;
    
    -- 2-log of the number of bytes in the data memory.
    DMEM_DEPTH_LOG2             : integer := 15;
    
    -- 2-log of the number of bytes in the parameter memory.
    PMEM_DEPTH_LOG2             : integer := 15;
    
    -- Identifier for the core within the platform, used by the control
    -- registers (0..255).
    CORE_ID                     : integer := 0;
    
    -- 2-log of the number of r-VEX lanes (1..4).
    NUM_LANES_LOG2              : integer := 2;
    
    -- 2-log of the number of r-VEX lane groups (0..NUM_LANES_LOG2-1).
    NUM_GROUPS_LOG2             : integer := 1;
    
    -- 2-log of the number of r-VEX hardware contexts (0..2).
    NUM_CONTEXTS_LOG2           : integer := 1;
    
    -- 2-log of the number of issue slots in a filled generic binary bundle
    -- (NUM_LANES_LOG2..3).
    GEN_BUNDLE_SIZE_LOG2        : integer := 2;
    
    -- 2-log of the alignment requirement of a bundle (1..NUM_LANES_LOG2). If
    -- this is less than NUM_LANES_LOG2, the stop-bit system will be enabled.
    -- This will automatically disable the limmhFromPreviousPair logic.
    BUNDLE_ALIGN_LOG2           : integer := 1;
    
    -- Number of breakpoints supported by the core (0..4).
    NUM_BREAKPOINTS             : integer := 4;
    
    -- Enable trace unit (1) or disable trace unit (0).
    TRACE_ENABLE                : boolean := false;
    
    -- Number of bytes in each performance counter (0..7).
    PERF_COUNTER_SIZE           : integer := 4
    
  );
  port (
  
    -- Clock and reset.
    s_axi_aclk                  : in  std_logic;
    s_axi_aresetn               : in  std_logic;
    
    -- Read address channel.
    s_axi_araddr                : in  std_logic_vector(axi_addrw_g-1 downto 0);
    s_axi_arvalid               : in  std_logic;
    s_axi_arready               : out std_logic;
    
    -- Read data channel.
    s_axi_rdata                 : out std_logic_vector(31 downto 0);
    s_axi_rresp                 : out std_logic_vector(1 downto 0);
    s_axi_rvalid                : out std_logic;
    s_axi_rready                : in  std_logic;
    
    -- Write address channel.
    s_axi_awaddr                : in  std_logic_vector(axi_addrw_g-1 downto 0);
    s_axi_awvalid               : in  std_logic;
    s_axi_awready               : out std_logic;
    
    -- Write data channel.
    s_axi_wdata                 : in  std_logic_vector(31 downto 0);
    s_axi_wstrb                 : in  std_logic_vector(3 downto 0);
    s_axi_wvalid                : in  std_logic;
    s_axi_wready                : out std_logic;
    
    -- Write response channel.
    s_axi_bresp                 : out std_logic_vector(1 downto 0);
    s_axi_bvalid                : out std_logic;
    s_axi_bready                : in  std_logic
    
  );
end rvex_axislave;

--=============================================================================
architecture Behavioral of rvex_axislave is
--=============================================================================
  
  --  _________                                  ___________
  -- /   AXI   \                                / r-VEX dbg \
  -- CTRL: 00... \                            / Trace: 00...
  -- IMEM: 01...  }--[ALMARVI/r-VEX bridge]--/  IMEM:  01...
  -- DMEM: 10... /                           \  DMEM:  10...
  -- PMEM: 11... >------[dual port BRAM]      \ Debug: 11...
  --                           |
  --   Mapped to upper half of r-VEX 32-bit address space,
  --              lower half is mapped to DMEM
  --
  -- AXI address space:
  --   00 ii00 ----------    1 kiB ALMARVI interface for core/context i
  --   00 ii01 ----------    1 kiB r-VEX registers for context i
  --   00 --1- ----------    2 kiB trace buffer
  --   01 ---- ----------    2**IMEM_DEPTH_LOG2 byte instruction memory
  --   10 ---- ----------    2**DMEM_DEPTH_LOG2 byte data memory
  --   11 ---- ----------    2**PMEM_DEPTH_LOG2 byte parameter memory
  --
  -- r-VEX instruction address space:
  --   0x00000000..0xFFFFFFFF  Instruction memory
  --
  -- r-VEX data address space:
  --   0x00000000..0x7FFFFFFF  Data memory
  --   0x80000000..0xFFFFFBFF  Paremeter memory
  --   0xFFFFFC00..0xFFFFFFFF  Control registers
  
  -- Returns an address map definition with the upper two bits of the AXI
  -- address set to section.
  function mapSection(
    section : std_logic_vector
  ) return addrRangeAndMapping_type is
    variable match : rvex_address_type;
  begin
    match := (others => '-');
    match(AXI_ADDRW_G-1 downto AXI_ADDRW_G-2) := section;
    return addrRangeAndMap(match => match);
  end mapSection;
  
  -- System control signals.
  signal areset                 : std_logic;
  signal reset                  : std_logic;
  
  -- AXI to PMEM/others demux.
  signal axi2demux              : bus_mst2slv_type;
  signal demux2axi              : bus_slv2mst_type;
  
  -- Demux to ALMARVI/r-VEX bridge.
  signal demux2almarvi          : bus_mst2slv_type;
  signal almarvi2demux          : bus_slv2mst_type;
  
  -- ALMARVI/r-VEX bridge bus to r-VEX.
  signal almarvi2rvex           : bus_mst2slv_type;
  signal rvex2almarvi           : bus_slv2mst_type;
  
  -- Demux to PMEM.
  signal demux2pmem             : bus_mst2slv_type;
  signal pmem2demux             : bus_slv2mst_type;
  
  -- r-VEX to pmem.
  signal rvex2pmem              : bus_mst2slv_type;
  signal pmem2rvex              : bus_slv2mst_type;
  
  -- Run control signals.
  signal rvex_resetVect         : rvex_address_array(2**NUM_CONTEXTS_LOG2-1 downto 0);
  
  -- Construct r-VEX configuration in a forward-compatible way.
  function CORE_CFG return rvex_generic_config_type is
    variable c : rvex_generic_config_type;
  begin
    c := RVEX_DEFAULT_CONFIG;
    c.numLanesLog2          := NUM_LANES_LOG2;
    c.numLaneGroupsLog2     := NUM_GROUPS_LOG2;
    c.numContextsLog2       := NUM_CONTEXTS_LOG2;
    c.genBundleSizeLog2     := GEN_BUNDLE_SIZE_LOG2;
    c.bundleAlignLog2       := BUNDLE_ALIGN_LOG2;
    c.multiplierLanes       := 2#11111111#;
    c.memLaneRevIndex       := 1;
    c.numBreakpoints        := NUM_BREAKPOINTS;
    c.forwarding            := true;
    c.limmhFromNeighbor     := true;
    c.limmhFromPreviousPair := false;
    c.reg63isLink           := false;
    c.cregStartAddress      := X"FFFFFC00";
    c.resetVectors          := (others => (others => '0'));
    c.unifiedStall          := true;
    c.gpRegImpl             := RVEX_GPREG_IMPL_MEM;
    c.traceEnable           := TRACE_ENABLE;
    c.perfCountSize         := PERF_COUNTER_SIZE;
    c.cachePerfCountEnable  := false;
    return c;
  end CORE_CFG;
  
  function SYS_CFG return rvex_sa_generic_config_type is
    variable c : rvex_sa_generic_config_type;
  begin
    c := RVEX_SA_DEFAULT_CONFIG;
    c.core              := CORE_CFG;
    c.cache_enable      := false;
    c.cache_config      := CACHE_DEFAULT_CONFIG;
    c.cache_bypassRange := addrRange(match => "--------------------------------");
    c.imemDepthLog2B    := IMEM_DEPTH_LOG2;
    c.dmemDepthLog2B    := DMEM_DEPTH_LOG2;
    c.traceDepthLog2B   := 11; -- Fixed to 2 kiB
    c.debugBusMap_imem  := mapSection("01");
    c.debugBusMap_dmem  := mapSection("10");
    c.debugBusMap_rvex  := mapSection("11");
    c.debugBusMap_trace := mapSection("00");
    c.debugBusMap_mutex := true;
    c.rvexDataMap_dmem  := addrRangeAndMap(match => "0-------------------------------");
    c.rvexDataMap_bus   := addrRangeAndMap(match => "1-------------------------------");
    return c;
  end SYS_CFG;
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- Generate reset signals
  -----------------------------------------------------------------------------
  areset <= not s_axi_aresetn;
  sync_reset_proc: process (s_axi_aclk) is
  begin
    if rising_edge(s_axi_aclk) then
      reset <= areset;
    end if;
  end process;
  
  -----------------------------------------------------------------------------
  -- Instantiate AXI to r-VEX bus bridge
  -----------------------------------------------------------------------------
  axi_bridge_inst: entity work.axi_bridge
    generic map (
      AXI_ADDRW_G               => AXI_ADDRW_G
    )
    port map (
    
      -- System control.
      areset                    => areset,
      reset                     => reset,
      clk                       => s_axi_aclk,
      
      -- AXI read address channel.
      s_axi_araddr              => s_axi_araddr,
      s_axi_arvalid             => s_axi_arvalid,
      s_axi_arready             => s_axi_arready,
      
      -- AXI read data channel.
      s_axi_rdata               => s_axi_rdata,
      s_axi_rresp               => s_axi_rresp,
      s_axi_rvalid              => s_axi_rvalid,
      s_axi_rready              => s_axi_rready,
      
      -- AXI write address channel.
      s_axi_awaddr              => s_axi_awaddr,
      s_axi_awvalid             => s_axi_awvalid,
      s_axi_awready             => s_axi_awready,
      
      -- AXI write data channel.
      s_axi_wdata               => s_axi_wdata,
      s_axi_wstrb               => s_axi_wstrb,
      s_axi_wvalid              => s_axi_wvalid,
      s_axi_wready              => s_axi_wready,
      
      -- AXI write response channel.
      s_axi_bresp               => s_axi_bresp,
      s_axi_bvalid              => s_axi_bvalid,
      s_axi_bready              => s_axi_bready,
      
      -- r-VEX bus master.
      bridge2bus                => axi2demux,
      bus2bridge                => demux2axi
      
    );
  
  -----------------------------------------------------------------------------
  -- AXI bus demux
  -----------------------------------------------------------------------------
  demux_inst: entity work.bus_demux
    generic map (
      ADDRESS_MAP(1)            => mapSection("11"), -- PMEM
      ADDRESS_MAP(0)            => mapSection("--")  -- Others (highest indexed
    )                                                -- matching slave is used)
    port map (
      
      -- System control.
      reset                     => reset,
      clk                       => s_axi_aclk,
      clkEn                     => '1',
      
      -- Incoming bus from the master.
      mst2demux                 => axi2demux,
      demux2mst                 => demux2axi,
      
      -- Outgoing busses to the slaves.
      demux2slv(1)              => demux2pmem,
      demux2slv(0)              => demux2almarvi,
      slv2demux(1)              => pmem2demux,
      slv2demux(0)              => almarvi2demux
      
    );
  
  -----------------------------------------------------------------------------
  -- Instantiate ALMARVI/r-VEX bridge
  -----------------------------------------------------------------------------
  almarvi_inst: entity work.almarvi_iface
    generic map (
      AXI_ADDRW_G               => AXI_ADDRW_G,
      IMEM_DEPTH_LOG2           => IMEM_DEPTH_LOG2,
      DMEM_DEPTH_LOG2           => DMEM_DEPTH_LOG2,
      PMEM_DEPTH_LOG2           => PMEM_DEPTH_LOG2,
      NUM_CONTEXTS_LOG2         => NUM_CONTEXTS_LOG2,
      NUM_BREAKPOINTS           => NUM_BREAKPOINTS
    )
    port map (
    
      -- System control.
      reset                     => reset,
      clk                       => s_axi_aclk,
      clkEn                     => '1',
      
      -- Bus to the AXI bridge.
      axi2almarvi               => demux2almarvi,
      almarvi2axi               => almarvi2demux,
      
      -- Bus to the r-VEX.
      almarvi2rvex              => almarvi2rvex,
      rvex2almarvi              => rvex2almarvi,
      
      -- r-VEX run control signals.
      rvex_resetVect            => rvex_resetVect
      
    );
  
  -----------------------------------------------------------------------------
  -- Instantiate parameter memory
  -----------------------------------------------------------------------------
  pmem_inst: entity work.bus_ramBlock
    generic map (
      DEPTH_LOG2B               => DMEM_DEPTH_LOG2
    )
    port map (
      
      -- System control.
      reset                     => reset,
      clk                       => s_axi_aclk,
      clkEn                     => '1',
      
      -- Memory port A.
      mst2mem_portA             => demux2pmem,
      mem2mst_portA             => pmem2demux,
      
      -- Memory port B.
      mst2mem_portB             => rvex2pmem,
      mem2mst_portB             => pmem2rvex
      
    );  
  
  -----------------------------------------------------------------------------
  -- Instantiate the r-VEX standalone platform
  -----------------------------------------------------------------------------
  rvsys_inst: entity work.rvsys_standalone
    generic map (
      -- Normally, these are set using the setter functions. These are broken
      -- in Vivado though (unspecified things will just become X)
      CFG                       => SYS_CFG,
      CORE_ID                   => CORE_ID,
      PLATFORM_TAG              => X"414C4D41525649" -- "ALMARVI" in ASCII
    )
    port map (
      
      -- System control.
      reset                     => reset,
      clk                       => s_axi_aclk,
      clkEn                     => '1',
    
      -- Run control interface.
      rctrl2rvsa_resetVect      => rvex_resetVect,
    
      -- Master interface, unused.
      rvsa2bus                  => rvex2pmem,
      bus2rvsa                  => pmem2rvex,
      
      -- Debug interface.
      debug2rvsa                => almarvi2rvex,
      rvsa2debug                => rvex2almarvi
      
    );
  
end Behavioral;

