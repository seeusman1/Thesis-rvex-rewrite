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
use rvex.utils_pkg.all;
use rvex.bus_pkg.all;
use rvex.core_pkg.all;
use rvex.cache_pkg.all;

--=============================================================================
-- This is the toplevel entity for the reconfigurable instruction and data
-- cache designed for the rvex core. It also optionally includes the MMU.
-------------------------------------------------------------------------------
entity cache is
--=============================================================================
  generic (
    
    -- Core configuration. Must be equal to the configuration presented to the
    -- rvex core connected to the cache.
    RCFG                        : rvex_generic_config_type := rvex_cfg;
    
    -- Cache configuration.
    CCFG                        : cache_generic_config_type := cache_cfg
    
  );
  port (
    
    ---------------------------------------------------------------------------
    -- System control
    ---------------------------------------------------------------------------
    -- Active high synchronous reset input.
    reset                       : in  std_logic;
    
    -- Clock input, registers are rising edge triggered.
    clk                         : in  std_logic;
    
    -- Active high clock enable input.
    clkEn                       : in  std_logic := '1';
    
    -- Backwards compatibility clkEn signals. These were only ever used in
    -- testbenches. The MMU does not support these.
    clkEnCPU                    : in  std_logic := '1';
    clkEnBus                    : in  std_logic := '1';
    
    ---------------------------------------------------------------------------
    -- r-VEX common interface
    ---------------------------------------------------------------------------
    -- Decouple vector from the r-VEX. This vector works as follows. Each
    -- pipelane group has a bit in the vector. When this bit is low, the
    -- pipelane group is a slave to the first higher-indexed group which has a
    -- high decouple bit. In such a case, the following interfacing rules
    -- apply:
    --  - All groups will issue instruction memory read commands regardless of
    --    decouple state. However, coupled groups will always make aligned
    --    accesses. In other words, you could for example only use the PC from
    --    the lowest indexed pipelane group just make wider memory accesses to
    --    deliver all the syllables.
    --  - The memories must provide equal stall and blockReconfig signals to
    --    coupled pipelane groups or behavior will be undefined.
    --  - The memories must provide equal stall signals to coupled pipelane
    --    groups or behavior will be undefined.
    -- The rvex core will follow the following rules:
    --  - Pipelane groups working together are properly aligned (see also the
    --    config control signal documentation) and the highest indexed debouple
    --    bit is always high. For example, for an rvex with 8 lanes and 4
    --    pipelane groups, the only decouple outputs generated under normal
    --    conditions are "1111", "1110", "1011", "1010" and "1000".
    --  - The decouple outputs will not split or merge two groups when either
    --    group is asserting the blockReconfig signal.
    rv2cache_decouple             : in  std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    -- For each lane group, this signal represents which context it is
    -- connected to. This is only valid when the associated bit in
    -- rv2cache_laneGroupActive is high.
    rv2cache_laneGroupContext     : in  rvex_3bit_array(2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    -- For each lane group, this signal represents whether it is assigned to a
    -- context. When low, the logic associated with the lane group may be
    -- powered down.
    rv2cache_laneGroupActive      : in  std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    -- For each cache/TLB block associated with the indexed lane group, this
    -- signal determines whether cache/TLB updates are allowed. The r-VEX will
    -- ensure that at least one block in a set of coupled blocks will be
    -- enabled at all times. Blocks may be disabled when it is known that a
    -- task will no longer have access to the block in a later configuration,
    -- such that more recent data is directed to other blocks.
    rv2cache_blockUpdateEnable    : in  std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    -- Active high reconfiguration block output. When this is high, associated
    -- lanes may not be reconfigured. This is high when the write buffers of
    -- the associated lanes are filled, as reconfiguring in this case could
    -- lead to cache inconsistency.
    cache2rv_blockReconfig        : out std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    -- Stall output (input from the r-VEX's perspective). When a bit in this
    -- vector is high, the associated pipelane group will stall. Equal stall
    -- signals must be provided to coupled pipelane groups (see also the
    -- mem_decouple signal documentation).
    cache2rv_stallIn              : out std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    -- Combined stall signal from the r-VEX. This represents the actual stall
    -- signal. If a bit in stallIn is high, the respective stallOut signal must
    -- be high, but the reverse is not required.
    rv2cache_stallOut             : in  std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    -- This signal controls whether address translation is active or not.
    rv2cache_mmuEnable            : in  std_logic_vector(2**RCFG.numContextsLog2-1 downto 0);
    
    -- This signal represents the current privilege level of processor. It is
    -- high for kernel mode and low for application mode.
    rv2cache_kernelMode           : in  std_logic_vector(2**RCFG.numContextsLog2-1 downto 0);
    
    -- This signal controls whether a trap is generated when a write to a clean
    -- page is attempted.
    rv2cache_writeToCleanEna      : in  std_logic_vector(2**RCFG.numContextsLog2-1 downto 0);
    
    -- This signal specifies the page table pointer for the current thread.
    rv2cache_pageTablePtr         : in  rvex_address_array(2**RCFG.numContextsLog2-1 downto 0);
    
    -- This signal specifies the address space ID for the current thread.
    rv2cache_asid                 : in  rvex_data_array(2**RCFG.numContextsLog2-1 downto 0);
    
    -- When this signal is high, a TLB flush should be initiated.
    rv2cache_tlbFlushStart        : in  std_logic_vector(2**RCFG.numContextsLog2-1 downto 0);
    
    -- This is high when a TLB cache flush is in progress.
    cache2rv_tlbFlushBusy         : out std_logic_vector(2**RCFG.numContextsLog2-1 downto 0);
    
    -- When rv2cache_tlbFlushAsidEna is high, rv2cache_tlbFlushAsid specifies a
    -- specific ASID that must be flushed during a TLB flush. Entries with
    -- other ASIDs are then unaffected.
    rv2cache_tlbFlushAsidEna      : in  std_logic_vector(2**RCFG.numContextsLog2-1 downto 0);
    rv2cache_tlbFlushAsid         : in  rvex_data_array(2**RCFG.numContextsLog2-1 downto 0);
    
    -- These two signals specify a lower and upper limit for the virtual page
    -- addresses that are to be flushed. Both are inclusive.
    rv2cache_tlbFlushTagLow       : in  rvex_address_array(2**RCFG.numContextsLog2-1 downto 0);
    rv2cache_tlbFlushTagHigh      : in  rvex_address_array(2**RCFG.numContextsLog2-1 downto 0);
    
    ---------------------------------------------------------------------------
    -- r-VEX instruction interface
    ---------------------------------------------------------------------------
    
    -- When this is high, the instruction cache is flushed.
    rv2icache_flushStart          : in  std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    -- This signal is reserved for multicycle instruction cache flushes in the
    -- future. It is currently always low, as a cache flush is single cycle.
    icache2rv_flushBusy           : out std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0) := (others => '0');
    
    --  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
    -- Request phase
    --  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
    
    -- Program counters from each pipelane group.
    rv2icache_PCs                 : in  rvex_address_array(2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    -- Active high instruction fetch enable signal. When a bit in this vector
    -- is high, the bit in mem_stallOut is low and the bit in mem_decouple is
    -- high, the cache will fetch the instruction pointed to by the associated
    -- vector in rv2icache_PCs.
    rv2icache_fetch               : in  std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    -- Combinatorial cancel signal, valid one cycle after rv2icache_PCs and
    -- rv2icache_fetch, regardless of memory stalls. If this is high, a
    -- potential cache miss does not have to be resolved, as the result is not
    -- used.
    rv2icache_cancel              : in  std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    --  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
    -- Response phase: valid one unstalled, clkEn'd clock cycle after the
    -- request
    --  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
    
    -- The fetched instruction.
    icache2rv_instr               : out rvex_syllable_array(2**RCFG.numLanesLog2-1 downto 0);
    
    -- Active high bus fault signals. icache2rv_instr is invalid if the
    -- respective signal is high.
    icache2rv_busFault            : out std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    icache2rv_pageFault           : out std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    icache2rv_kernelAccVio        : out std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    -- Cache block affinity data from cache. This is set to the index of the
    -- block that served the request.
    icache2rv_affinity            : out std_logic_vector(2**RCFG.numLaneGroupsLog2*RCFG.numLaneGroupsLog2-1 downto 0);
    
    -- Trace information. This is high when a fetch was serviced by the block
    -- associated with the indexed lane group.
    icache2rv_access              : out std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    -- Trace information. This is high when the fetch resulted in a miss.
    icache2rv_miss                : out std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    -- Trace information. This is high when an address translation was serviced
    -- by the TLB block associated with the indexed lane group.
    icache2rv_tlbAccess           : out std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    -- Trace information. This is high when the TLB access resulted in a miss.
    icache2rv_tlbMiss             : out std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    -- Trace information. This is high when the MSBs of the physical cache tag
    -- were mispredicted.
    icache2rv_tlbMispredict       : out std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    ---------------------------------------------------------------------------
    -- r-VEX data interface
    ---------------------------------------------------------------------------
    
    -- When this is high, the data cache is flushed.
    rv2dcache_flushStart          : in  std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    -- This signal is reserved for multicycle instruction cache flushes in the
    -- future. It is currently always low, as a cache flush is single cycle.
    dcache2rv_flushBusy           : out std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0) := (others => '0');
    
    --  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
    -- Request phase
    --  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
    
    -- Data memory addresses from each pipelane group.
    rv2dcache_addr                : in  rvex_address_array(2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    -- Active high read enable from each pipelane group. When a bit in this
    -- vector is high, the bit in mem_stallOut is low and the bit in
    -- mem_decouple is high, the data cache will fetch the data at the address
    -- specified by the associated vector in rv2dcache_addr.
    rv2dcache_readEnable          : in  std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    -- Write data from the rvex to the cache.
    rv2dcache_writeData           : in  rvex_data_array(2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    -- Write byte mask from the rvex to the cache, active high.
    rv2dcache_writeMask           : in  rvex_mask_array(2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    -- Active high write enable from each pipelane group. When a bit in this
    -- vector is high, the bit in mem_stallOut is low and the bit in
    -- mem_decouple is high, the data memory must write the data in
    -- dmem_writeData to the address specified by rv2dcache_addr, respecting
    -- the byte mask specified by dmem_writeMask.
    rv2dcache_writeEnable         : in  std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    -- When this is high, the memory access goes straigh to the bus, bypassing
    -- the cache.
    rv2dcache_bypass              : in  std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    --  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
    -- Response phase: valid one unstalled, clkEn'd clock cycle after the
    -- request
    --  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
    
    -- Data output.
    dcache2rv_readData            : out rvex_data_array(2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    -- Active high fault signals from the data memory. When high,
    -- dcache2rv_readData is invalid.
    dcache2rv_ifaceFault          : out std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    dcache2rv_busFault            : out std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    dcache2rv_pageFault           : out std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    dcache2rv_kernelAccVio        : out std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    dcache2rv_writeAccVio         : out std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    dcache2rv_writeToClean        : out std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    -- Trace information. This represents the type of cache access performed by
    -- the block associated with the indexed lane group:
    --   00 - No access.
    --   01 - Read access.
    --   10 - Write access, complete cache line.
    --   11 - Write access, only part of a cache line (update first).
    dcache2rv_accessType          : out rvex_2bit_array(2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    -- Trace information. This is high when the performed data access bypassed
    -- the cache.
    dcache2rv_bypass              : out std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    -- Trace information. This is high when the access resulted in a miss.
    dcache2rv_miss                : out std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    -- Trace information. This is high when the data cache write buffer
    -- was filled when the request was made. If the request would result in
    -- some kind of bus access, this means an extra penalty would be paid.
    dcache2rv_writePending        : out std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    -- Trace information. This is high when an address translation was
    -- serviced by the TLB block associated with the indexed lane group.
    dcache2rv_tlbAccess           : out std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    -- Trace information. This is high when the TLB access resulted in a
    -- miss.
    dcache2rv_tlbMiss             : out std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    -- Trace information. This is high when the MSBs of the physical cache tag
    -- were mispredicted.
    dcache2rv_tlbMispredict       : out std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    ---------------------------------------------------------------------------
    -- Bus master interfaces
    ---------------------------------------------------------------------------
    -- Bus interface for the caches and MMU table walker. The timing of these
    -- signals is governed by clkEnBus. The table walker shares the first bus
    -- master.
    cache2bus_bus               : out bus_mst2slv_array(2**RCFG.numLaneGroupsLog2-1 downto 0);
    bus2cache_bus               : in  bus_slv2mst_array(2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    ---------------------------------------------------------------------------
    -- Status/control interface
    ---------------------------------------------------------------------------
    -- Bus slave interface for the status and control registers.
    bus2cache_ctrl              : in  bus_mst2slv_type;
    cache2bus_ctrl              : out bus_slv2mst_type;
    
    -- Cache flush request signals for each instruction and data cache. These
    -- are mostly here for backwards compatibility. New designs should use the
    -- built-in control registers.
    sc2icache_flush             : in  std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0) := (others => '0');
    sc2dcache_flush             : in  std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0) := (others => '0');
    
    ---------------------------------------------------------------------------
    -- Bus snooping interface
    ---------------------------------------------------------------------------
    -- These signals are optional. They are needed for cache coherency on
    -- multi-processor systems and/or for dynamic cores.
    
    -- Bus address which is to be invalidated when invalEnable is high.
    bus2cache_invalAddr         : in  rvex_address_type := (others => '0');
    
    -- If one of the data caches is causing the invalidation due to a write,
    -- the signal in this vector indexed by that data cache must be high. In
    -- all other cases, these signals should be low.
    bus2cache_invalSource       : in  std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0) := (others => '0');
    
    -- Active high enable signal for line invalidation.
    bus2cache_invalEnable       : in  std_logic := '0'
    
  );
end cache;

--=============================================================================
architecture Behavioral of cache is
--=============================================================================
  
  -- Clock enable compatibility stuff.
  signal clkEn_int              : std_logic;
  signal clkEnCPU_int           : std_logic;
  signal clkEnBus_int           : std_logic;
  
  -- Instruction cache signals.
  signal icache2bus             : bus_mst2slv_array(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal bus2icache             : bus_slv2mst_array(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal icache2rv_blockReconfig: std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal icache2rv_stallIn      : std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal icache2rv_status_access: std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal icache2rv_status_miss  : std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
  
  -- Data cache signals.
  signal dcache2bus             : bus_mst2slv_array(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal bus2dcache             : bus_slv2mst_array(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal dcache2rv_blockReconfig: std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal dcache2rv_stallIn      : std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal dcache2rv_status       : dcache_status_array(2**RCFG.numLaneGroupsLog2-1 downto 0);
  
  -- MMU table walker bus.
  signal mmu2bus                : bus_mst2slv_type;
  signal bus2mmu                : bus_slv2mst_type;
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- MMU sanity checking
  -----------------------------------------------------------------------------
  -- Check if the cache is not too big for the pagesize. Because the MMU turns
  -- the cache into a VIPT cache, cache size divided by the degree of
  -- associativity cannot be larger than the page size.
  assert not CCFG.mmuEnable or (CCFG.dataCacheLinesLog2+2 <= CCFG.pageSizeLog2)
    report "The data cache size per block must be smaller than or equal to " &
           "the page size."
    severity failure;
  
  assert not CCFG.mmuEnable or (CCFG.instrCacheLinesLog2+2+RCFG.numLanesLog2 <= CCFG.pageSizeLog2)
    report "The instruction cache size per block must be smaller than or " &
           "equal to the page size."
    severity failure;
  
  -- Check that the large page size is at least smaller than the regular page
  -- size.
  assert not CCFG.mmuEnable or (CCFG.largePageSizeLog2 >= CCFG.pageSizeLog2)
    report "The size of a large page must be larger or equal to the size of " &
           "a regular page."
    severity failure;
  
  -- Some mmu inefficient configuration warnings.
  assert not CCFG.mmuEnable or (CCFG.tlbDepthLog2 <= 32)
    report "Sizing the tlb larger than 32 leads to increased BRAM " &
           "utilization of the TLB."
    severity note;
  
  assert not CCFG.mmuEnable or (CCFG.asidBitWidth <= 10)
    report "Sizing the asid larger than 10 leads to increased BRAM " &
           "utilization of the TLB."
    severity note;
  
  assert not CCFG.mmuEnable or (CCFG.largePageSizeLog2 - CCFG.pageSizeLog2 <= 10)
    report "The size of a large page is more than 1024 times the size of a " &
           "regular page. This leads to increased BRAM utilization of the TLB."
    severity note;
  
  -- Handle deprecated clkEn interface signals. The separate signals only work
  -- when the MMU is disabled; all new designs should use clkEn.
  clkEnCPU_int <= clkEn and clkEnCPU;
  clkEnBus_int <= clkEn and clkEnBus;
  clkEn_int <= clkEn and clkEnCPU and clkEnBus;
  
  -- Assert false when there is a difference between the merged signals while
  -- the MMU is enabled.
  -- pragma translate_off
  process (clk) is
  begin
    if rising_edge(clk) and CCFG.mmuEnable and (clkEnCPU_int /= clkEnBus_int) then
      assert false
        report "You seem to be using the old clkEnCPU and clkEnBus signals " &
               "with the MMU enabled. This is not supported. Please use " &
               "the combined clkEn signal or disable the MMU."
        severity failure;
    end if;
  end process;
  -- pragma translate_on
  
  -----------------------------------------------------------------------------
  -- Instantiate the instruction cache
  -----------------------------------------------------------------------------
  icache_inst: entity rvex.cache_instr
    generic map (
      RCFG                      => RCFG,
      CCFG                      => CCFG
    )
    port map (
      
      -- System control.
      reset                     => reset,
      clk                       => clk,
      clkEnCPU                  => clkEnCPU_int,
      clkEnBus                  => clkEnBus_int,
      
      -- Core interface.
      rv2icache_decouple        => rv2cache_decouple,
      icache2rv_blockReconfig   => icache2rv_blockReconfig,
      icache2rv_stallIn         => icache2rv_stallIn,
      rv2icache_stallOut        => rv2cache_stallOut,
      rv2icache_PCs             => rv2icache_PCs,
      rv2icache_fetch           => rv2icache_fetch,
      rv2icache_cancel          => rv2icache_cancel,
      icache2rv_instr           => icache2rv_instr,
      icache2rv_affinity        => icache2rv_affinity,
      icache2rv_busFault        => icache2rv_busFault,
      icache2rv_status_access   => icache2rv_status_access,
      icache2rv_status_miss     => icache2rv_status_miss,
      
      -- Bus master interface.
      icache2bus_bus            => icache2bus,
      bus2icache_bus            => bus2icache,
      
      -- Bus snooping interface.
      bus2icache_invalAddr      => bus2cache_invalAddr,
      bus2icache_invalEnable    => bus2cache_invalEnable,
      
      -- Status and control signals.
      sc2icache_flush           => sc2icache_flush
      
    );
  
  -----------------------------------------------------------------------------
  -- Instantiate the data cache
  -----------------------------------------------------------------------------
  dcache_inst: entity rvex.cache_data
    generic map (
      RCFG                      => RCFG,
      CCFG                      => CCFG
    )
    port map (
      
      -- System control.
      reset                     => reset,
      clk                       => clk,
      clkEnCPU                  => clkEnCPU_int,
      clkEnBus                  => clkEnBus_int,
      
      -- Core interface.
      rv2dcache_decouple        => rv2cache_decouple,
      dcache2rv_blockReconfig   => dcache2rv_blockReconfig,
      dcache2rv_stallIn         => dcache2rv_stallIn,
      rv2dcache_stallOut        => rv2cache_stallOut,
      rv2dcache_addr            => rv2dcache_addr,
      rv2dcache_readEnable      => rv2dcache_readEnable,
      rv2dcache_writeData       => rv2dcache_writeData,
      rv2dcache_writeMask       => rv2dcache_writeMask,
      rv2dcache_writeEnable     => rv2dcache_writeEnable,
      rv2dcache_bypass          => rv2dcache_bypass,
      dcache2rv_readData        => dcache2rv_readData,
      dcache2rv_busFault        => dcache2rv_busFault,
      dcache2rv_ifaceFault      => dcache2rv_ifaceFault,
      dcache2rv_status          => dcache2rv_status,
      
      -- Bus master interface.
      dcache2bus_bus            => dcache2bus,
      bus2dcache_bus            => bus2dcache,
      
      -- Bus snooping interface.
      bus2dcache_invalAddr      => bus2cache_invalAddr,
      bus2dcache_invalSource    => bus2cache_invalSource,
      bus2dcache_invalEnable    => bus2cache_invalEnable,
      
      -- Status and control signals.
      sc2dcache_flush           => sc2dcache_flush
      
    );
  
  -----------------------------------------------------------------------------
  -- Merge blockReconfig and stallIn signals
  -----------------------------------------------------------------------------
  cache2rv_blockReconfig  <= icache2rv_blockReconfig or dcache2rv_blockReconfig;
  cache2rv_stallIn        <= icache2rv_stallIn       or dcache2rv_stallIn;
  
  -----------------------------------------------------------------------------
  -- Generate the status output signal
  -----------------------------------------------------------------------------
  status_output_gen: for laneGroup in 2**RCFG.numLaneGroupsLog2-1 downto 0 generate
    
    icache2rv_access(laneGroup)         <= icache2rv_status_access(laneGroup)
      when rv2cache_stallOut(laneGroup) = '0' else '0';
    icache2rv_miss(laneGroup)           <= icache2rv_status_miss(laneGroup)
      when rv2cache_stallOut(laneGroup) = '0' else '0';
    icache2rv_tlbAccess(laneGroup)      <= '0'
      when rv2cache_stallOut(laneGroup) = '0' else '0';
    icache2rv_tlbMiss(laneGroup)        <= '0'
      when rv2cache_stallOut(laneGroup) = '0' else '0';
    icache2rv_tlbMispredict(laneGroup)  <= '0'
      when rv2cache_stallOut(laneGroup) = '0' else '0';
    dcache2rv_accessType(laneGroup)     <= dcache2rv_status(laneGroup).accessType
      when rv2cache_stallOut(laneGroup) = '0' else "00";
    dcache2rv_bypass(laneGroup)         <= dcache2rv_status(laneGroup).bypass
      when rv2cache_stallOut(laneGroup) = '0' else '0';
    dcache2rv_miss(laneGroup)           <= dcache2rv_status(laneGroup).miss
      when rv2cache_stallOut(laneGroup) = '0' else '0';
    dcache2rv_writePending(laneGroup)   <= dcache2rv_status(laneGroup).writePending
      when rv2cache_stallOut(laneGroup) = '0' else '0';
    dcache2rv_tlbAccess(laneGroup)      <= '0'
      when rv2cache_stallOut(laneGroup) = '0' else '0';
    dcache2rv_tlbMiss(laneGroup)        <= '0'
      when rv2cache_stallOut(laneGroup) = '0' else '0';
    dcache2rv_tlbMispredict(laneGroup)  <= '0'
      when rv2cache_stallOut(laneGroup) = '0' else '0';
    
  end generate;
  
  -----------------------------------------------------------------------------
  -- Instantiate the bus arbiters
  -----------------------------------------------------------------------------
  -- Arbitrate between the instruction and data cache accesses. If the MMU is
  -- enabled, the arbiter for lane group 0 is handled separately, as it also
  -- needs to include the table walker bus.
  bus_arbiter_gen: for laneGroup in 2**RCFG.numLaneGroupsLog2-1 downto bool2int(CCFG.mmuEnable) generate
    
    bus_arbiter_inst: entity rvex.bus_arbiter
      generic map (
        NUM_MASTERS             => 2
      )
      port map (
        
        -- System control.
        reset                   => reset,
        clk                     => clk,
        clkEn                   => clkEnBus_int,
        
        -- Master busses.
        mst2arb(1)              => icache2bus(laneGroup),
        mst2arb(0)              => dcache2bus(laneGroup),
        arb2mst(1)              => bus2icache(laneGroup),
        arb2mst(0)              => bus2dcache(laneGroup),
        
        -- Slave bus.
        arb2slv                 => cache2bus_bus(laneGroup),
        slv2arb                 => bus2cache_bus(laneGroup)
        
      );
    
  end generate;
  
  -- Generate the special arbiter for block 0 that includes the table walker
  -- bus if the MMU is enabled.
  bus_arbiter_gen_mmu: if CCFG.mmuEnable generate
  begin
    
    bus_arbiter_inst: entity rvex.bus_arbiter
      generic map (
        NUM_MASTERS             => 3
      )
      port map (
        
        -- System control.
        reset                   => reset,
        clk                     => clk,
        clkEn                   => clkEnBus_int,
        
        -- Master busses.
        mst2arb(2)              => mmu2bus,
        mst2arb(1)              => icache2bus(0),
        mst2arb(0)              => dcache2bus(0),
        arb2mst(2)              => bus2mmu,
        arb2mst(1)              => bus2icache(0),
        arb2mst(0)              => bus2dcache(0),
        
        -- Slave bus.
        arb2slv                 => cache2bus_bus(0),
        slv2arb                 => bus2cache_bus(0)
        
      );
    
  end generate;
  
end Behavioral;

