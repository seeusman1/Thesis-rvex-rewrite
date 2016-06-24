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
use rvex.core_pkg.all;

--=============================================================================
-- This package contains type definitions and constants for the rvex cache.
-------------------------------------------------------------------------------
package cache_pkg is
--=============================================================================
  
  -- Constants for the bit position of items in the page table entries.
  constant PTE_PRESENT_BIT      : natural := 0;
  constant PTE_RW_BIT           : natural := 1;
  constant PTE_PROT_LEVEL_BIT   : natural := 2;
  constant PTE_GLOBAL_BIT       : natural := 3;
  constant PTE_CACHEABLE_BIT    : natural := 4;
  constant PTE_DIRTY_BIT        : natural := 5;
  constant PTE_ACCESSED_BIT     : natural := 6;
  constant PTE_LARGE_PAGE_BIT   : natural := 7;
  
  -- Data type for flush modes.
  subtype rvex_flushMode_type   is std_logic_vector(2 downto  0);
  type    rvex_flushMode_array  is array (natural range <>) of rvex_flushMode_type;
  
  -- Constants for flush modes.
  constant FLUSH_ALL            : rvex_flushMode_type := "000";
  constant FLUSH_TAG            : rvex_flushMode_type := "001";
  constant FLUSH_RANGE          : rvex_flushMode_type := "010";
  constant FLUSH_ALL_ASID       : rvex_flushMode_type := "100";
  constant FLUSH_TAG_ASID       : rvex_flushMode_type := "101";
  constant FLUSH_RANGE_ASID     : rvex_flushMode_type := "110";
  
  -- Cache/MMU configuration record.
  type cache_generic_config_type is record
    
    -- log2 of the number of cache lines in the instruction cache. An
    -- instruction cache line has the size of a full rvex instruction, so
    -- that's the number of lanes in the core times 32 bits.
    instrCacheLinesLog2         : natural;
    
    -- log2 of the number of cache lines in the data cache. A data cache line
    -- is fixed to 32 bits.
    dataCacheLinesLog2          : natural;
    
    -- Determines whether the MMU is instantiated in the system.
    mmuEnable                   : boolean;
    
    -- The number of entries in a TLB. If this is set to more than 5
    -- (32 entries) it will result in higher BRAM utilization.
    tlbDepthLog2                : natural;  
    
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
  
  -- Default cache/MMU configuration.
  constant CACHE_DEFAULT_CONFIG  : cache_generic_config_type := (
    instrCacheLinesLog2         => 6,
    dataCacheLinesLog2          => 6,
    mmuEnable                   => false,
    tlbDepthLog2                => 5,
    pageSizeLog2                => 12,
    largePageSizeLog2           => 22,
    asidBitWidth                => 10
  );
  
  -- Generates a configuration for the rvex cache. None of the parameters are
  -- required; just use named associations to set the parameters you want to
  -- affect, the rest of the parameters will take their value from base, which
  -- is itself set to the default configuration if not specified. By using this
  -- method to generate configurations, code instantiating the rvex cache will
  -- be forward compatible when new configuration options are added.
  function cache_cfg(
    base                        : cache_generic_config_type := CACHE_DEFAULT_CONFIG;
    instrCacheLinesLog2         : integer := -1;
    dataCacheLinesLog2          : integer := -1;
    mmuEnable                   : integer := -1;
    tlbDepthLog2                : integer := -1;
    pageSizeLog2                : integer := -1;  
    largePageSizeLog2           : integer := -1;
    asidBitWidth                : integer := -1
  ) return cache_generic_config_type;
  
  -- Converts a cache/MMU configuration vector to the r-VEX MMU configuration
  -- generic (used for the version registers).
  function ccfg2mmuConfig(
    cfg                         : cache_generic_config_type
  ) return rvex_mmuConfig_type;
  
  -- Returns the log2 of the number of bytes needed to represent the
  -- instruction for a single lane group.
  function laneGroupInstrSizeBLog2(
    RCFG                        : rvex_generic_config_type;
    CCFG                        : cache_generic_config_type
  ) return natural;
  
  -- Returns the instruction cache line width.
  function icacheLineWidth(
    RCFG                        : rvex_generic_config_type;
    CCFG                        : cache_generic_config_type
  ) return natural;
  
  -- Returns the LSB of the line offset within the instruction cache for a
  -- given address.
  function icacheOffsetLSB(
    RCFG                        : rvex_generic_config_type;
    CCFG                        : cache_generic_config_type
  ) return natural;
  
  -- Returns the number of bits used to represent the line offset within the
  -- instruction cache for a given address.
  function icacheOffsetSize(
    RCFG                        : rvex_generic_config_type;
    CCFG                        : cache_generic_config_type
  ) return natural;
  
  -- Returns the LSB of the instruction cache tag for a given address.
  function icacheTagLSB(
    RCFG                        : rvex_generic_config_type;
    CCFG                        : cache_generic_config_type
  ) return natural;
  
  -- Returns number of bits used to represent the instruction cache tag.
  function icacheTagSize(
    RCFG                        : rvex_generic_config_type;
    CCFG                        : cache_generic_config_type
  ) return natural;
  
  -- Returns the LSB of the line offset within the data cache for a given
  -- address.
  function dcacheOffsetLSB(
    RCFG                        : rvex_generic_config_type;
    CCFG                        : cache_generic_config_type
  ) return natural;
  
  -- Returns the number of bits used to represent the line offset within the
  -- data cache for a given address.
  function dcacheOffsetSize(
    RCFG                        : rvex_generic_config_type;
    CCFG                        : cache_generic_config_type
  ) return natural;
  
  -- Returns the LSB of the data cache tag for a given address.
  function dcacheTagLSB(
    RCFG                        : rvex_generic_config_type;
    CCFG                        : cache_generic_config_type
  ) return natural;
  
  -- Returns number of bits used to represent the data cache tag.
  function dcacheTagSize(
    RCFG                        : rvex_generic_config_type;
    CCFG                        : cache_generic_config_type
  ) return natural;
  
  -- Returns the number of bits of the address which are used to specify the
  -- virtual or physical tag.
  function mmuTagSize(
    CCFG                        : cache_generic_config_type   
  ) return natural;   
  
  -- Returns the number of bits of the address which are used to specify the
  -- virtual or physical tag for a large page.
  function mmuLargePageTagSize(
    CCFG                        : cache_generic_config_type   
  ) return natural;  
  
  -- Returns the number of bits of the address which are used to specify the
  -- virtual or physical tag of a large page. This is the same as the size of
  -- the L1 tag.
  function mmuL1TagSize(
    CCFG                        : cache_generic_config_type   
  ) return natural;
  
  -- Returns the number of bits of the L2 tag.
  function mmuL2TagSize(
    CCFG                        : cache_generic_config_type   
  ) return natural;  
  
  -- Returns the number of bits used for the page offset (same as
  -- log2(pagesize) ).
  function mmuOffsetSize(
    CCFG                        : cache_generic_config_type   
  ) return natural;   
  
  -- Returns the number of bits used for the address space ID.
  function mmuAsidSize(
    CCFG                        : cache_generic_config_type   
  ) return natural;         
  
  -- Returns the MSB of the tag used for the first level of a page table
  -- lookup.
  function tagL1Msb(
    CCFG                        : cache_generic_config_type   
  ) return natural;
  
  -- Returns the LSB of the tag used for the first level of a page table
  -- lookup.
  function tagL1Lsb(
    CCFG                        : cache_generic_config_type   
  ) return natural;          
  
  -- Returns the MSB of the tag used for the second level of a page table
  -- lookup.
  function tagL2Msb(
    CCFG                        : cache_generic_config_type   
  ) return natural;     
  
  -- Returns the LSB of the tag used for the second level of a page table
  -- lookup.
  function tagL2Lsb(
    CCFG                        : cache_generic_config_type   
  ) return natural;     
  
  -- Returns the log2 of the number of bytes in the page directory.
  function pageDirSizeLog2B(
    CCFG                        : cache_generic_config_type   
  ) return natural;   
  
  -- Returns the log2 of the number of bytes in a page table.
  function pageTableSizeLog2B(
    CCFG                        : cache_generic_config_type   
  ) return natural;
  
  -- Flag bit indices for the page directory/table entries.
  constant PFLAG_X : natural := 9; -- eXecutable
  constant PFLAG_G : natural := 8; -- Global
  constant PFLAG_S : natural := 7; -- page Size
  constant PFLAG_D : natural := 6; -- Dirty
  constant PFLAG_A : natural := 5; -- Accessed
  constant PFLAG_C : natural := 4; -- Cache disable
  constant PFLAG_W : natural := 3; -- cache Write-through
  constant PFLAG_U : natural := 2; -- User accessible
  constant PFLAG_R : natural := 1; -- wRitable
  constant PFLAG_P : natural := 0; -- Present
  
  -- Data cache block status record for performance counters/tracing.
  type dcache_status_type is record
    
    -- Type of data memory access:
    --   00 - No access.
    --   01 - Read access.
    --   10 - Write access, complete cache line.
    --   11 - Write access, only part of a cache line (update first).
    accessType                  : std_logic_vector(1 downto 0);
    
    -- Whether the memory access bypassed the cache.
    bypass                      : std_logic;
    
    -- Whether the requested memory address was initially in the cache.
    miss                        : std_logic;
    
    -- This is set when the write buffer was filled when the request was made.
    -- If the request would result in some kind of bus access, this means an
    -- extra penalty would be paid.
    writePending                : std_logic;
    
  end record;
  type dcache_status_array is array (natural range <>) of dcache_status_type;
  
end cache_pkg;

package body cache_pkg is

  -- Generates a configuration for the cache.
  function cache_cfg(
    base                        : cache_generic_config_type := CACHE_DEFAULT_CONFIG;
    instrCacheLinesLog2         : integer := -1;
    dataCacheLinesLog2          : integer := -1;
    mmuEnable                   : integer := -1;
    tlbDepthLog2                : integer := -1;
    pageSizeLog2                : integer := -1;  
    largePageSizeLog2           : integer := -1;
    asidBitWidth                : integer := -1    
  ) return cache_generic_config_type is
    variable cfg  : cache_generic_config_type;
  begin
    cfg := base;
    if instrCacheLinesLog2  >= 0 then cfg.instrCacheLinesLog2 := instrCacheLinesLog2;  end if;
    if dataCacheLinesLog2   >= 0 then cfg.dataCacheLinesLog2  := dataCacheLinesLog2;   end if;
    if mmuEnable            >= 0 then cfg.mmuEnable            := int2bool(mmuEnable); end if;
    if tlbDepthLog2         >= 0 then cfg.tlbDepthLog2         := tlbDepthLog2;        end if;
    if pageSizeLog2         >= 0 then cfg.pageSizeLog2         := pageSizeLog2;        end if;    
    if largePageSizeLog2    >= 0 then cfg.largePageSizeLog2    := largePageSizeLog2;   end if;
    if asidBitWidth         >= 0 then cfg.asidBitWidth         := asidBitWidth;        end if;
    return cfg;
  end cache_cfg;
  
  -- Converts a cache/MMU configuration vector to the r-VEX MMU configuration
  -- generic (used for the version registers).
  function ccfg2mmuConfig(
    cfg                         : cache_generic_config_type
  ) return rvex_mmuConfig_type is
  begin
    return (
      mmuEnable             => cfg.mmuEnable,
      pageSizeLog2          => cfg.pageSizeLog2,
      largePageSizeLog2     => cfg.largePageSizeLog2,
      asidBitWidth          => cfg.asidBitWidth
    );
  end ccfg2mmuConfig;
  
  -- Returns the log2 of the number of bytes needed to represent the
  -- instruction for a single lane group.
  function laneGroupInstrSizeBLog2(
    RCFG                        : rvex_generic_config_type;
    CCFG                        : cache_generic_config_type
  ) return natural is
  begin
    return RCFG.numLanesLog2 - RCFG.numLaneGroupsLog2 + 2;
  end laneGroupInstrSizeBLog2;
  
  -- Returns the instruction cache line width.
  function icacheLineWidth(
    RCFG                        : rvex_generic_config_type;
    CCFG                        : cache_generic_config_type
  ) return natural is
  begin
    return rvex_syllable_type'length * 2**RCFG.numLanesLog2;
  end icacheLineWidth;
  
  -- Returns the LSB of the line offset within the instruction cache for a
  -- given address.
  function icacheOffsetLSB(
    RCFG                        : rvex_generic_config_type;
    CCFG                        : cache_generic_config_type
  ) return natural is
  begin
    return RCFG.numLanesLog2 + 2;
  end icacheOffsetLSB;
  
  -- Returns the number of bits used to represent the line offset within the
  -- instruction cache for a given address.
  function icacheOffsetSize(
    RCFG                        : rvex_generic_config_type;
    CCFG                        : cache_generic_config_type
  ) return natural is
  begin
    return CCFG.instrCacheLinesLog2;
  end icacheOffsetSize;
  
  -- Returns the LSB of the instruction cache tag for a given address.
  function icacheTagLSB(
    RCFG                        : rvex_generic_config_type;
    CCFG                        : cache_generic_config_type
  ) return natural is
  begin
    return icacheOffsetLSB(RCFG, CCFG) + icacheOffsetSize(RCFG, CCFG);
  end icacheTagLSB;
  
  -- Returns number of bits used to represent the instruction cache tag.
  function icacheTagSize(
    RCFG                        : rvex_generic_config_type;
    CCFG                        : cache_generic_config_type
  ) return natural is
  begin
    return rvex_address_type'length - icacheTagLSB(RCFG, CCFG);
  end icacheTagSize;
  
  -- Returns the LSB of the line offset within the data cache for a given
  -- address.
  function dcacheOffsetLSB(
    RCFG                        : rvex_generic_config_type;
    CCFG                        : cache_generic_config_type
  ) return natural is
  begin
    return 2;
  end dcacheOffsetLSB;
  
  -- Returns the number of bits used to represent the line offset within the
  -- data cache for a given address.
  function dcacheOffsetSize(
    RCFG                        : rvex_generic_config_type;
    CCFG                        : cache_generic_config_type
  ) return natural is
  begin
    return CCFG.dataCacheLinesLog2;
  end dcacheOffsetSize;
  
  -- Returns the LSB of the data cache tag for a given address.
  function dcacheTagLSB(
    RCFG                        : rvex_generic_config_type;
    CCFG                        : cache_generic_config_type
  ) return natural is
  begin
    return dcacheOffsetLSB(RCFG, CCFG) + dcacheOffsetSize(RCFG, CCFG);
  end dcacheTagLSB;
  
  -- Returns number of bits used to represent the data cache tag.
  function dcacheTagSize(
    RCFG                        : rvex_generic_config_type;
    CCFG                        : cache_generic_config_type
  ) return natural is
  begin
    return rvex_address_type'length - dcacheTagLSB(RCFG, CCFG);
  end dcacheTagSize;
  
  -- Returns the number of bits of the address which are used to specify the
  -- virtual or physical tag.
  function mmuTagSize(
    CCFG                        : cache_generic_config_type
  ) return natural is
  begin
    return 32 - CCFG.pageSizeLog2;
  end mmuTagSize;
  
  -- Returns the number of bits of the address which are used to specify the
  -- virtual or physical tag for a large page.
  function mmuLargePageTagSize(
    CCFG                        : cache_generic_config_type
  ) return natural is
  begin
    return 32 - CCFG.largePageSizeLog2;
  end mmuLargePageTagSize;
  
  -- Returns the number of bits of the address which are used to specify the
  -- virtual or physical tag of a large page. This is the same as the size of
  -- the L1 tag.
  function mmuL1TagSize(
    CCFG                        : cache_generic_config_type
  ) return natural is
  begin
    return 32 - CCFG.largePageSizeLog2;
  end mmuL1TagSize;
  
  -- Returns the number of bits of the L2 tag.
  function mmuL2TagSize(
    CCFG                        : cache_generic_config_type
  ) return natural is
  begin
    return 32 - mmuOffsetSize(CCFG) - mmuL1TagSize(CCFG);
  end mmuL2TagSize;

  -- Returns the number of bits used for the page offset (same as
  -- log2(pagesize) ).
  function mmuOffsetSize(
    CCFG                        : cache_generic_config_type
  ) return natural is
  begin
    return CCFG.pageSizeLog2;
  end mmuOffsetSize;
      
  -- Returns the number of bits used for the address space ID.
  function mmuAsidSize(
    CCFG                        : cache_generic_config_type
  ) return natural is
  begin
    return CCFG. asidBitWidth;
  end mmuAsidSize;
  
  -- Returns the MSB of the tag used for the first level of a page table
  -- lookup.
  function tagL1Msb(
    CCFG                        : cache_generic_config_type
  ) return natural is
  begin
    return mmuTagSize(CCFG) - 1;
  end tagL1Msb;
  
  -- Returns the LSB of the tag used for the first level of a page table
  -- lookup.
  function tagL1Lsb(
    CCFG                        : cache_generic_config_type
  ) return natural is
  begin
    return mmuL2TagSize(CCFG);
  end tagL1Lsb;
  
  -- Returns the MSB of the tag used for the second level of a page table
  -- lookup.
  function tagL2Msb(
    CCFG                        : cache_generic_config_type
  ) return natural is
  begin
    return mmuL2TagSize(CCFG) - 1;
  end tagL2Msb;
  
  -- Returns the LSB of the tag used for the second level of a page table
  -- lookup.
  function tagL2Lsb(
    CCFG                        : cache_generic_config_type
  ) return natural is
  begin
    return 0;
  end tagL2Lsb;
  
  -- Returns the log2 of the number of bytes in the page directory.
  function pageDirSizeLog2B(
    CCFG                        : cache_generic_config_type   
  ) return natural is
  begin
    return mmuL1TagSize(CCFG) + 2;
  end pageDirSizeLog2B;
  
  -- Returns the log2 of the number of bytes in a page table.
  function pageTableSizeLog2B(
    CCFG                        : cache_generic_config_type   
  ) return natural is
  begin
    return mmuL2TagSize(CCFG) + 2;
  end pageTableSizeLog2B;
  
end cache_pkg;
