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

--=============================================================================
-- This package contains type definitions and constants relevant both in the
-- core internally and for the external interface of the core.
-------------------------------------------------------------------------------
package core_pkg is
--=============================================================================
  
  -- rvex core configuration record.
  type rvex_generic_config_type is record
    
    -- log2 of the number of lanes to instantiate.
    numLanesLog2                : natural;
    
    -- log2 of the number of lane groups to instantiate. Each lane group can be
    -- disabled individually to save power, operate on its own, or work
    -- together on a single thread with other lane groups. May not be greater
    -- than 3 (due to configuration register size limits) or numLanesLog2.
    numLaneGroupsLog2           : natural;
    
    -- log2 of the number of hardware contexts in the core. May not be greater
    -- than 3 due to configuration register size limits.
    numContextsLog2             : natural;
    
    -- log2 of the number of syllables in a generic binary bundle. When a
    -- branch address is not aligned to this and limmhFromPreviousPair is set,
    -- then special actions will be taken to ensure that the relevant syllables
    -- preceding the trap point are fetched before operation resumes.
    genBundleSizeLog2           : natural;
    
    -- Assume (and enforce) that the start addresses of bundles are aligned to
    -- the specified amount of syllables. When this is less than numLanesLog2,
    -- additional logic is instantiated to handle aligning the memory accesses.
    -- The advantage of this is that bundles can be shorter by specifying the
    -- stop bit earlier when ILP is not sufficient to save on memory accesses.
    -- Note that traps are generated when a stop bit is encountered in any
    -- syllable not occuring just before an alignment point.
    bundleAlignLog2             : natural;
    
    -- Defines which lanes have a multiplier. Bit 0 of this number maps to lane
    -- 0, bit 1 to lane 1, etc.
    multiplierLanes             : natural;
    
    -- Lane index for the memory unit, counting down from the last lane in each
    -- lane group. So memLaneRevIndex = 0 results in the memory unit being in
    -- the last lane in each group, memLaneRevIndex = 1 results in it being in
    -- the second to last lane, etc.
    memLaneRevIndex             : natural;
    
    -- Defines how many hardware breakpoints are evaluated. Maximum is 4 due to
    -- the register map only having space for 4.
    numBreakpoints              : natural;
    
    -- Whether or not register forwarding logic should be instantiated. With
    -- forwarding disabled, the core will use less area and might run at higher
    -- frequencies, but much more NOPs are necessary between data-dependent
    -- instructions.
    forwarding                  : boolean;
    
    -- EXPERIMENTAL: degree of trap support. traps = 0 means that all trap
    -- support is disabled (that includes interrupts), traps = 1 is reserved for
    -- imprecise traps although it is not yet supported, and traps = 2 (default)
    -- means that traps are completely enabled. Note that the traps = 2
    -- configuration is the properly tested one.
    traps                       : natural;
    
    -- When true, syllables can borrow long immediates from the other syllable
    -- in a syllable pair.
    limmhFromNeighbor           : boolean;
    
    -- When true, syllables can borrow long immediates from the previous
    -- syllable pair (with the same index within the pair) within a generic
    -- binary bundle.
    limmhFromPreviousPair       : boolean;
    
    -- When true, general purpose register 63 maps directly to the link
    -- register. When false, MTL, MFL, STL and LDL must be used to access the
    -- link register.
    reg63isLink                 : boolean;
    
    -- Start address in the data address space for the 1kiB control register
    -- file. Must be aligned to a 1kiB boundary.
    cregStartAddress            : rvex_address_type;
    
    -- Configures the reset address for each context. When less than 8 contexts
    -- are used, the higher indexed values are unused.
    resetVectors                : rvex_address_array(7 downto 0);
    
    -- When true, the stall signals for each group will either be all high or
    -- all low. This depends on the memory architecture; when this is set, the
    -- memory architecture can be made simpler, but cannot make use of the
    -- possible performance gain due to being able to stall only part of the
    -- core.
    unifiedStall                : boolean;
    
    -- General purpose register implementation. Accepted values are:
    --  - RVEX_GPREG_IMPL_MEM (0, default): BRAM + LVT implementation.
    --  - RVEX_GPREG_IMPL_SIMPLE (1): behavioral implementation.
    gpRegImpl                   : natural;

    -- Whether the trace unit should be instantiated.
    traceEnable                 : boolean;
    
    -- Performance counter size in bytes. Only applies to the context-specific
    -- counters. Up to 7 bytes are supported. The default is 4.
    perfCountSize               : natural;
    
    -- Enables or disables the cache performance counters. When enabled, the
    -- number of lane groups must equal the number of contexts, because the
    -- signals from the cache blocks are mapped to the contexts directly. This
    -- is extremely ugly, yes. The cache performance counters should really
    -- just be in the cache.
    cachePerfCountEnable        : boolean;
    
  end record;
  
  -- Values for gpRegImpl.
  constant RVEX_GPREG_IMPL_MEM    : natural := 0;
  constant RVEX_GPREG_IMPL_SIMPLE : natural := 1;
  
  -- Default rvex core configuration.
  constant RVEX_DEFAULT_CONFIG  : rvex_generic_config_type := (
    numLanesLog2                => 3,
    numLaneGroupsLog2           => 2,
    numContextsLog2             => 2,
    genBundleSizeLog2           => 3,
    bundleAlignLog2             => 3,
    multiplierLanes             => 2#11111111#,
    memLaneRevIndex             => 1,
    numBreakpoints              => 4,
    forwarding                  => true,
    traps                       => 2,
    limmhFromNeighbor           => true,
    limmhFromPreviousPair       => true,
    reg63isLink                 => false,
    cregStartAddress            => X"FFFFFC00",
    resetVectors                => (others => (others => '0')),
    unifiedStall                => false,
    gpRegImpl                   => RVEX_GPREG_IMPL_MEM,
    traceEnable                 => false,
    perfCountSize               => 4,
    cachePerfCountEnable        => false
  );
  
  -- Minimal rvex core configuration.
  constant RVEX_MINIMAL_CONFIG  : rvex_generic_config_type := (
    numLanesLog2                => 1,
    numLaneGroupsLog2           => 0,
    numContextsLog2             => 0,
    genBundleSizeLog2           => 3,
    bundleAlignLog2             => 1,
    multiplierLanes             => 2#00#,
    memLaneRevIndex             => 1,
    numBreakpoints              => 0,
    forwarding                  => false,
    traps                       => 0,
    limmhFromNeighbor           => true,
    limmhFromPreviousPair       => false,
    reg63isLink                 => false,
    cregStartAddress            => X"FFFFFC00",
    resetVectors                => (others => (others => '0')),
    unifiedStall                => true,
    gpRegImpl                   => RVEX_GPREG_IMPL_MEM,
    traceEnable                 => false,
    perfCountSize               => 0,
    cachePerfCountEnable        => false
  );
  
  -- Generates a configuration for the rvex core. None of the parameters are
  -- required; just use named associations to set the parameters you want to
  -- affect, the rest of the parameters will take their value from base, which
  -- is itself set to the default configuration if not specified. To set
  -- boolean values, use 1 for true and 0 for false (-1 is used to detect when
  -- a parameter is not specified). By using this method to generate
  -- configurations, code instantiating the rvex core will be forward
  -- compatible when new configuration options are added.
  function rvex_cfg(
    base                        : rvex_generic_config_type := RVEX_DEFAULT_CONFIG;
    numLanesLog2                : integer := -1;
    numLaneGroupsLog2           : integer := -1;
    numContextsLog2             : integer := -1;
    genBundleSizeLog2           : integer := -1;
    bundleAlignLog2             : integer := -1;
    multiplierLanes             : integer := -1;
    memLaneRevIndex             : integer := -1;
    branchLaneRevIndex          : integer := 0; -- No longer supported, must be zero.
    numBreakpoints              : integer := -1;
    forwarding                  : integer := -1;
    traps                       : integer := -1;
    limmhFromNeighbor           : integer := -1;
    limmhFromPreviousPair       : integer := -1;
    reg63isLink                 : integer := -1;
    cregStartAddress            : rvex_address_type := (others => '-');
    resetVectors                : rvex_address_array(7 downto 0) := (others => (others => '-'));
    unifiedStall                : integer := -1;
    gpRegImpl                   : integer := -1;
    traceEnable                 : integer := -1;
    perfCountSize               : integer := -1;
    cachePerfCountEnable        : integer := -1
  ) return rvex_generic_config_type;
  
  -- Converts a lane index to a group index.
  function lane2group (
    lane  : natural;
    CFG   : rvex_generic_config_type
  ) return natural;
  
  -- Converts a lane index to the lane index within the lane group it belongs
  -- to, counting from the first lane.
  function lane2indexInGroup (
    lane  : natural;
    CFG   : rvex_generic_config_type
  ) return natural;
  
  -- Converts a lane index to the lane index within the lane group it belongs
  -- to, counting from the last lane (last lane in group = 0, second to last
  -- lane in group = 1 etc,).
  function lane2indexInGroupRev (
    lane  : natural;
    CFG   : rvex_generic_config_type
  ) return natural;
  
  -- Converts a group index to the first lane index in it.
  function group2firstLane (
    laneGroup : natural;
    CFG       : rvex_generic_config_type
  ) return natural;
  
  -- Converts a group index to the last lane index in it.
  function group2lastLane (
    laneGroup : natural;
    CFG       : rvex_generic_config_type
  ) return natural;
  
  -- Converts a lane index to the index of the first lane in the group.
  function lane2firstLane (
    lane      : natural;
    CFG       : rvex_generic_config_type
  ) return natural;
  
  -- Converts a lane index to the index of the last lane in the group.
  function lane2lastLane (
    lane      : natural;
    CFG       : rvex_generic_config_type
  ) return natural;
  
  -- Returns the alignment requirement for the program counter.
  function cfg2pcAlignLog2 (
    CFG       : rvex_generic_config_type
  ) return natural;
  
  -----------------------------------------------------------------------------
  -- Cache trace output signal record, used for tracing. All these signals are
  -- replicated for each lane group. They are assumed to only be active in
  -- cycles where the CPU is not stalled, so they can be tied into the
  -- performance counters directly.
  type rvex_cacheTrace_type is record
    
    -- This is high when a fetch was performed.
    instr_access                : std_logic;
    
    -- This is high when a fetch was performed which required the cache to be
    -- updated.
    instr_miss                  : std_logic;
    
    -- Type of data memory access:
    --   00 - No access.
    --   01 - Read access.
    --   10 - Write access, complete cache line.
    --   11 - Write access, only part of a cache line (update first).
    data_accessType             : std_logic_vector(1 downto 0);
    
    -- Whether the data memory access bypassed the cache.
    data_bypass                 : std_logic;
    
    -- Whether the requested memory address was initially in the data cache.
    data_miss                   : std_logic;
    
    -- This is set when the data cache write buffer was filled when the request
    -- was made. If the request would result in some kind of bus access, this
    -- means an extra penalty would be paid.
    data_writePending           : std_logic;
    
  end record;
  type rvex_cacheTrace_array is array (natural range <>) of rvex_cacheTrace_type;
  constant RVEX_CACHE_TRACE_IDLE : rvex_cacheTrace_type := (
    instr_access                => '0',
    instr_miss                  => '0',
    data_accessType             => "00",
    data_bypass                 => '0',
    data_miss                   => '0',
    data_writePending           => '0'
  );
  
  -----------------------------------------------------------------------------
  -- Cache status signals. NOTE: if you end up here with error messages you may
  -- be looking for rvex_cacheTrace_type instead. The type was renamed.
  type rvex_cacheStatus_type is record
    
    -- This is high when an instruction cache flush is busy. If flushes are
    -- always single-cycle, this can just always be zero.
    instr_flushBusy             : std_logic;
    
    -- This is high when a data cache flush is busy. If flushes are always
    -- single-cycle, this can just always be zero.
    data_flushBusy              : std_logic;
    
  end record;
  type rvex_cacheStatus_array is array (natural range <>) of rvex_cacheStatus_type;
  constant RVEX_CACHE_STATUS_IDLE : rvex_cacheStatus_type := (
    instr_flushBusy             => '0',
    data_flushBusy              => '0'
  );
  
  -----------------------------------------------------------------------------
  -- Cache control signals.
  type rvex_cacheControl_type is record
    
    -- When this is high, an instruction cache flush should be initiated.
    instr_flushStart            : std_logic;
    
    -- When this is high, a data cache flush should be initiated.
    data_flushStart             : std_logic; 
    
    -- When this is high, all data accesses should bypass the cache.
    data_bypass                 : std_logic;
    
    -- This signal is used to assign a higher update priority to certain
    -- blocks. Each bit represents a block/lane group. Blocks for which the bit
    -- is set should take precedence over the other blocks when a cache miss
    -- occurs. This can be used to potentially decrease the cache penalty due
    -- to reconfiguration if the new configuration is known in advance, by
    -- directing cache updates to blocks that are known to be shared between
    -- the two configurations.
    blockPrio                   : rvex_byte_type;
    
  end record;
  type rvex_cacheControl_array is array (natural range <>) of rvex_cacheControl_type;
  constant RVEX_CACHE_CONTROL_IDLE : rvex_cacheControl_type := (
    instr_flushStart            => '0',
    data_flushStart             => '0',
    data_bypass                 => '0',
    blockPrio                   => (others => '0')
  );
  
  -----------------------------------------------------------------------------
  -- MMU trace information per lane group.
  type rvex_mmuTrace_type is record
    
    -- This is high when this instruction TLB serviced a translation.
    itlb_access                 : std_logic;
    
    -- This is high when this instruction TLB missed.
    itlb_miss                   : std_logic;
    
    -- This is high when this data TLB serviced a translation.
    dtlb_access                 : std_logic;
    
    -- This is high when this data TLB missed.
    dtlb_miss                   : std_logic;
    
  end record;
  type rvex_mmuTrace_array is array (natural range <>) of rvex_mmuTrace_type;
  constant RVEX_MMU_TRACE_IDLE : rvex_mmuTrace_type := (
    itlb_access                 => '0',
    itlb_miss                   => '0',
    dtlb_access                 => '0',
    dtlb_miss                   => '0'
  );
  
  -----------------------------------------------------------------------------
  -- MMU status signals.
  type rvex_mmuStatus_type is record
    
    -- This is high when a TLB cache flush is busy. If flushes are always
    -- single-cycle, this can just always be zero.
    flush_busy                  : std_logic;
    
  end record;
  type rvex_mmuStatus_array is array (natural range <>) of rvex_mmuStatus_type;
  constant RVEX_MMU_STATUS_IDLE : rvex_mmuStatus_type := (
    flush_busy                  => '0'
  );
  
  -----------------------------------------------------------------------------
  -- MMU control signals.
  type rvex_mmuControl_type is record
    
    -- This signal controls whether address translation is active or not.
    enable                      : std_logic;
    
    -- This signal represents the current privilege level of processor. It is
    -- high for kernel mode and low for application mode.
    kernelMode                  : std_logic;
    
    -- This signal controls whether a trap is generated when a write to a clean
    -- page is attempted.
    writeToCleanEna             : std_logic;
    
    -- This signal specifies the page table pointer for the current thread.
    pageTablePtr                : rvex_address_type;
    
    -- This signal specifies the address space ID for the current thread.
    asid                        : rvex_data_type;
    
    -- When this signal is high, a TLB flush should be initiated.
    flush_start                 : std_logic;
    
    -- When flush_asidEna is high, flush_asid specifies a specific ASID that
    -- must be flushed during a TLB flush. Entries with other ASIDs are then
    -- unaffected.
    flush_asid                  : rvex_data_type;
    flush_asidEna               : std_logic;
    
    -- These two signals specify a lower and upper limit for the virtual page
    -- addresses that are to be flushed. Both are inclusive.
    flush_tagLow                : rvex_address_type;
    flush_tagHigh               : rvex_address_type;
    
    -- This signal is used to assign a higher update priority to certain
    -- TLBs. Each bit represents a TLB/lane group. TLBs for which the bit
    -- is set should take precedence over the other TLBs when a TLB miss
    -- occurs. This can be used to potentially decrease the TLB miss penalty
    -- due to reconfiguration if the new configuration is known in advance, by
    -- directing updates to TLBs that are known to be shared between the two
    -- configurations.
    blockPrio                   : rvex_byte_type;
    
  end record;
  type rvex_mmuControl_array is array (natural range <>) of rvex_mmuControl_type;
  constant RVEX_MMU_CONTROL_IDLE : rvex_mmuControl_type := (
    enable                      => '0',
    kernelMode                  => '0',
    writeToCleanEna             => '0',
    pageTablePtr                => (others => '0'),
    asid                        => (others => '0'),
    flush_start                 => '0',
    flush_asid                  => (others => '0'),
    flush_asidEna               => '0',
    flush_tagLow                => (others => '0'),
    flush_tagHigh               => (others => '1'),
    blockPrio                   => (others => '0')
  );
  
  -----------------------------------------------------------------------------
  -- MMU design-time configuration information.
  type rvex_mmuConfig_type is record
    
    -- Determines whether the MMU is instantiated in the system.
    mmuEnable                   : boolean;
    
    -- The log2 of the page size in bytes. It also denotes the number of bits
    -- in the page offset. The page size must be larger than or equal to the
    -- size of a single cache block.
    pageSizeLog2                : natural;
    
    -- The log2 of the size of a large page. If this is more then 1024 times
    -- larger than the size of a regular page
    -- (largePageSizeLog2 > pageSizeLog2+10), it wil lead to an extra BRAM for
    -- each TLB in the system.
    largePageSizeLog2           : natural;
    
    -- The number of bits used for the application space ID. If this is set to
    -- a number larger than 10, it will result in higher BRAM usage.
    asidBitWidth                : natural;
    
  end record;
  type rvex_mmuConfig_array is array (natural range <>) of rvex_mmuConfig_type;
  constant RVEX_MMU_CONFIG_NONE : rvex_mmuConfig_type := (
    mmuEnable                   => false,
    pageSizeLog2                => 12,
    largePageSizeLog2           => 22,
    asidBitWidth                => 10
  );
  
end core_pkg;

package body core_pkg is

  -- Generates a configuration for the rvex core.
  function rvex_cfg(
    base                        : rvex_generic_config_type := RVEX_DEFAULT_CONFIG;
    numLanesLog2                : integer := -1;
    numLaneGroupsLog2           : integer := -1;
    numContextsLog2             : integer := -1;
    genBundleSizeLog2           : integer := -1;
    bundleAlignLog2             : integer := -1;
    multiplierLanes             : integer := -1;
    memLaneRevIndex             : integer := -1;
    branchLaneRevIndex          : integer := 0; -- No longer supported, must be zero.
    numBreakpoints              : integer := -1;
    forwarding                  : integer := -1;
    traps                       : integer := -1;
    limmhFromNeighbor           : integer := -1;
    limmhFromPreviousPair       : integer := -1;
    reg63isLink                 : integer := -1;
    cregStartAddress            : rvex_address_type := (others => '-');
    resetVectors                : rvex_address_array(7 downto 0) := (others => (others => '-'));
    unifiedStall                : integer := -1;
    gpRegImpl                   : integer := -1;
    traceEnable                 : integer := -1;
    perfCountSize               : integer := -1;
    cachePerfCountEnable        : integer := -1
  ) return rvex_generic_config_type is
    variable cfg  : rvex_generic_config_type;
  begin
    
    -- Fail if configurations which are *no longer* supported are requested.
    assert branchLaneRevIndex = 0
      report "CFG.branchLaneRevIndex is no longer supported in this version "
           & "the core. The branch unit now needs to be in the last lane of "
           & "a lane group, due to the way stop bits are handled. The branch "
           & "unit for which the stop bit is set is active, thus it needs to "
           & "be in the last lane."
      severity failure;
    
    cfg := base;
    if numLanesLog2           >= 0 then cfg.numLanesLog2          := numLanesLog2; end if;
    if numLaneGroupsLog2      >= 0 then cfg.numLaneGroupsLog2     := numLaneGroupsLog2; end if;
    if numContextsLog2        >= 0 then cfg.numContextsLog2       := numContextsLog2; end if;
    if genBundleSizeLog2      >= 0 then cfg.genBundleSizeLog2     := genBundleSizeLog2; end if;
    if bundleAlignLog2        >= 0 then cfg.bundleAlignLog2       := bundleAlignLog2; end if;
    if multiplierLanes        >= 0 then cfg.multiplierLanes       := multiplierLanes; end if;
    if memLaneRevIndex        >= 0 then cfg.memLaneRevIndex       := memLaneRevIndex; end if;
    if numBreakpoints         >= 0 then cfg.numBreakpoints        := numBreakpoints; end if;
    if forwarding             >= 0 then cfg.forwarding            := int2bool(forwarding); end if;
    if traps                  >= 0 then cfg.traps                 := traps; end if;
    if limmhFromNeighbor      >= 0 then cfg.limmhFromNeighbor     := int2bool(limmhFromNeighbor); end if;
    if limmhFromPreviousPair  >= 0 then cfg.limmhFromPreviousPair := int2bool(limmhFromPreviousPair); end if;
    if reg63isLink            >= 0 then cfg.reg63isLink           := int2bool(reg63isLink); end if;
    if unifiedStall           >= 0 then cfg.unifiedStall          := int2bool(unifiedStall); end if;
    if gpRegImpl              >= 0 then cfg.gpRegImpl             := gpRegImpl; end if;
    if traceEnable            >= 0 then cfg.traceEnable           := int2bool(traceEnable); end if;
    if perfCountSize          >= 0 then cfg.perfCountSize         := perfCountSize; end if;
    if cachePerfCountEnable   >= 0 then cfg.cachePerfCountEnable  := int2bool(cachePerfCountEnable); end if;
    
    cfg.cregStartAddress := overrideStdLogicVect(cfg.cregStartAddress, cregStartAddress);
    for i in 0 to 7 loop
      cfg.resetVectors(i) := overrideStdLogicVect(cfg.resetVectors(i), resetVectors(i));
    end loop;
    
    return cfg;
  end rvex_cfg;
  
  -- Converts a lane index to a group index.
  function lane2group (
    lane      : natural;
    CFG       : rvex_generic_config_type
  ) return natural is
  begin
    return lane / 2**(CFG.numLanesLog2 - CFG.numLaneGroupsLog2);
  end lane2group;
  
  -- Converts a lane index to the lane index within the lane group it belongs
  -- to, counting from the first lane.
  function lane2indexInGroup (
    lane  : natural;
    CFG   : rvex_generic_config_type
  ) return natural is
  begin
    return lane mod 2**(CFG.numLanesLog2 - CFG.numLaneGroupsLog2);
  end lane2indexInGroup;
  
  -- Converts a lane index to the lane index within the lane group it belongs
  -- to, counting from the last lane (last lane in group = 0, second to last
  -- lane in group = 1 etc,).
  function lane2indexInGroupRev (
    lane  : natural;
    CFG   : rvex_generic_config_type
  ) return natural is
  begin
    return (2**(CFG.numLanesLog2 - CFG.numLaneGroupsLog2) - lane2indexInGroup(lane, CFG)) - 1;
  end lane2indexInGroupRev;
  
  -- Converts a group index to the first lane index in it.
  function group2firstLane (
    laneGroup : natural;
    CFG       : rvex_generic_config_type
  ) return natural is
  begin
    return laneGroup * 2**(CFG.numLanesLog2 - CFG.numLaneGroupsLog2);
  end group2firstLane;
  
  -- Converts a group index to the last lane index in it.
  function group2lastLane (
    laneGroup : natural;
    CFG       : rvex_generic_config_type
  ) return natural is
  begin
    return (laneGroup + 1) * 2**(CFG.numLanesLog2 - CFG.numLaneGroupsLog2) - 1;
  end group2lastLane;
  
  -- Converts a lane index to the index of the first lane in the group.
  function lane2firstLane (
    lane      : natural;
    CFG       : rvex_generic_config_type
  ) return natural is
  begin
    return group2firstLane(lane2group(lane, CFG), CFG);
  end lane2firstLane;
  
  -- Converts a lane index to the index of the last lane in the group.
  function lane2lastLane (
    lane      : natural;
    CFG       : rvex_generic_config_type
  ) return natural is
  begin
    return group2lastLane(lane2group(lane, CFG), CFG);
  end lane2lastLane;
  
  -- Returns the alignment requirement for the program counter.
  function cfg2pcAlignLog2 (
    CFG       : rvex_generic_config_type
  ) return natural is
  begin
    return min_nat(
      CFG.numLanesLog2 - CFG.numLaneGroupsLog2,
      CFG.bundleAlignLog2
    ) + SYLLABLE_SIZE_LOG2B;
  end cfg2pcAlignLog2;
  
end core_pkg;
