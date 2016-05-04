-- r-VEX processor MMU
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

-- 7. The MMU was developed by Jens Johansen.

-- Copyright (C) 2008-2016 by TU Delft.

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library rvex;
use rvex.common_pkg.all;
use rvex.utils_pkg.all;
use rvex.cache_pkg.all;


package mmu_pkg is

  -- constants for the bit position of items in the page table entries
  constant PTE_PRESENT_BIT      : natural := 0;
  constant PTE_RW_BIT           : natural := 1;
  constant PTE_PROT_LEVEL_BIT   : natural := 2;
  constant PTE_GLOBAL_BIT       : natural := 3;
  constant PTE_CACHEABLE_BIT    : natural := 4;
  constant PTE_DIRTY_BIT        : natural := 5;
  constant PTE_ACCESSED_BIT     : natural := 6;
  constant PTE_LARGE_PAGE_BIT   : natural := 7;
    
  -- data type for flush modes
  subtype rvex_flushMode_type   is std_logic_vector(2 downto  0);
  type    rvex_flushMode_array  is array (natural range <>) of rvex_flushMode_type;
  
  -- constants for flush modes
  constant FLUSH_ALL            : rvex_flushMode_type := "000";
  constant FLUSH_TAG            : rvex_flushMode_type := "001";
  constant FLUSH_RANGE          : rvex_flushMode_type := "010";
  constant FLUSH_ALL_ASID       : rvex_flushMode_type := "100";
  constant FLUSH_TAG_ASID       : rvex_flushMode_type := "101";
  constant FLUSH_RANGE_ASID     : rvex_flushMode_type := "110";
  
  type mmu_generic_config_type is record
    
    -- Determines if the mmu is instantiated in the system.
    mmuEnable                   : boolean;
    
    -- The number of entries in a TLB. If this is set to more than 5
    -- (32 entries) it will result  in higher BRAM utilization.
    tlbDepthLog2                : natural;  
    
    -- The log2 of the page size. It also denotes the number of bits in the
    -- page offset.
    pageSizeLog2                : natural;
    
    -- The log2 of the size of a large page. If this is more then 10 times
    -- larger then the size of a regular page, it wil lead to an extra BRAM for
    -- each TLB in the system.
    largePageSizeLog2           : natural;
    
    -- The number of bits used for the application space ID. If this is set to
    -- a number larger than 10, it will result in higher BRAM usage.
    asidBitWidth                : natural;
    
  end record;
  
  
  constant MMU_DEFAULT_CONFIG   : mmu_generic_config_type := (
    mmuEnable                   => True,
    tlbDepthLog2                => 5,
    pageSizeLog2                => 12,
    largePageSizeLog2           => 22,
    asidBitWidth                => 10
  );
  
  -- Generates a configuration for the memory management unit. None of the parameters are
  -- required; just use named associations to set the parameters you want to
  -- affect, the rest of the parameters will take their value from base, which
  -- is itself set to the default configuration if not specified. By using this
  -- method to generate configurations, code instantiating the rvex mmu will
  -- be forward compatible when new configuration options are added.
  function mmu_cfg(
    base                        : mmu_generic_config_type := MMU_DEFAULT_CONFIG;
    CCFG                        : cache_generic_config_type := CACHE_DEFAULT_CONFIG;
    mmuEnable                   : integer := -1;
    tlbDepthLog2                : integer := -1;
    pageSizeLog2                : integer := -1;  
    largePageSizeLog2           : integer := -1;
    asidBitWidth                : integer := -1
  ) return mmu_generic_config_type;
  
  -- returns the number of bits of the address which are used to specify the virtual or physical tag
  function mmuTagSize(
    MMU_CFG                     : mmu_generic_config_type
  ) return natural;   
  
  -- returns the number of bits of the address which are used to specify the virtual or physical tag for a large page
  function mmuLargePageTagSize(
    MMU_CFG                     : mmu_generic_config_type
  ) return natural;  
  
  -- returns the number of bits of the address which are used to specify the virtual or physical tag
  -- of a large page. This is the same as the size of the L1 tag.;
  function mmuL1TagSize(
    MMU_CFG                     : mmu_generic_config_type
  ) return natural;
  
  -- returns the number of bits of the L2 tag
  function mmuL2TagSize(
    MMU_CFG                     : mmu_generic_config_type
  ) return natural;  
  
  -- returns the number of bits used for the page offset ( same as log2(pagesize) )
  function mmuOffsetSize(
    MMU_CFG                     : mmu_generic_config_type
  ) return natural;   
  
  -- returns the number of bits used for the address space ID
  function mmuAsidSize(
    MMU_CFG                     : mmu_generic_config_type
  ) return natural;         
  
  -- returns the MSB of the tag used for the first level of a page table lookup
  function tagL1Msb(
    MMU_CFG                     : mmu_generic_config_type
  ) return natural;     
  
  -- returns the LSB of the tag used for the first level of a page table lookup
  function tagL1Lsb(
    MMU_CFG                     : mmu_generic_config_type
  ) return natural;          
  
  -- returns the MSB of the tag used for the second level of a page table lookup
  function tagL2Msb(
    MMU_CFG                     : mmu_generic_config_type
  ) return natural;     
  
  -- returns the LSB of the tag used for the second level of a page table lookup
  function tagL2Lsb(
    MMU_CFG                     : mmu_generic_config_type
  ) return natural;     

end mmu_pkg;  


package body mmu_pkg is
  
  -- Generates a configuration for the mmu.
  function mmu_cfg(
    base                        : mmu_generic_config_type   := MMU_DEFAULT_CONFIG;
    CCFG                        : cache_generic_config_type := CACHE_DEFAULT_CONFIG;
    mmuEnable                   : integer := -1;
    tlbDepthLog2                : integer := -1;
    pageSizeLog2                : integer := -1;  
    largePageSizeLog2           : integer := -1;
    asidBitWidth                : integer := -1    
  ) return mmu_generic_config_type is
    variable cfg  : mmu_generic_config_type;
  begin    
    cfg := base;
    if mmuEnable            >= 0 then cfg.mmuEnable            := int2bool(mmuEnable);     end if;
    if tlbDepthLog2         >= 0 then cfg.tlbDepthLog2         := tlbDepthLog2;            end if;
    if pageSizeLog2         >= 0 then cfg.pageSizeLog2         := pageSizeLog2;            end if;    
    if largePageSizeLog2    >= 0 then cfg.largePageSizeLog2    := largePageSizeLog2;    end if;
    if asidBitWidth         >= 0 then cfg.asidBitWidth         := asidBitWidth;            end if;
    
    -- check if the cache is not te big for the pagesize. Because the MMU turns the cache into a VIPT cache,
    -- cache size divided by the degree of associativity cannot be larger than the page size.
    assert (CCFG.dataCacheLinesLog2+2 <= cfg.pageSizeLog2) report "The data cache size cannot be larger than the page size" severity failure;
    
    -- check that the large page size is at least smaller than the page size
    assert (cfg.largePageSizeLog2 >= cfg.pageSizeLog2) report "The size of a large page cannot be smaller than a regular page" severity failure;
    
    -- some mmu inefficient configuration warnings
    assert (cfg.tlbDepthLog2 <= 32) report "Sizing the tlb larger than 32 leads to increased BRAM utilization of the TLB" severity warning;
    assert (cfg.asidBitWidth <= 10) report "Sizing the asid larger than 10 leads to increased BRAM utilization of the TLB" severity warning;
    assert (cfg.largePageSizeLog2 - cfg.pageSizeLog2 <= 10) report "The size of a large page is more than 10 times the size of a regular page.\n This leads to increased BRAM utilization of the TLB" severity warning;
      
    return cfg;
  end mmu_cfg;
  
  function mmuTagSize(
    MMU_CFG                      : mmu_generic_config_type
  ) return natural is
  begin
    return 32 - MMU_CFG.pageSizeLog2;
  end mmuTagSize;
  
  
  function mmuLargePageTagSize(
    MMU_CFG                      : mmu_generic_config_type
  ) return natural is
  begin
    return 32 - MMU_CFG.largePageSizeLog2;
  end mmuLargePageTagSize;
  
  
  function mmuL1TagSize(
    MMU_CFG                      : mmu_generic_config_type
  ) return natural is
  begin
    return 32 - MMU_CFG.largePageSizeLog2;
  end mmuL1TagSize;
  
  
  function mmuL2TagSize(
    MMU_CFG                      : mmu_generic_config_type
  ) return natural is
  begin
    return 32 - mmuOffsetSize(MMU_CFG) - mmuL1TagSize(MMU_CFG);
  end mmuL2TagSize;


  function mmuOffsetSize(
    MMU_CFG                      : mmu_generic_config_type
  ) return natural is
  begin
    return MMU_CFG.pageSizeLog2;
  end mmuOffsetSize;
      
  
  function mmuAsidSize(
    MMU_CFG                      : mmu_generic_config_type
  ) return natural is
  begin
    return MMU_CFG. asidBitWidth;
  end mmuAsidSize;
  
  
  function tagL1Msb(
    MMU_CFG                      : mmu_generic_config_type
  ) return natural is
  begin
    return mmuTagSize(MMU_CFG) - 1;
  end tagL1Msb;
  
  
  function tagL1Lsb(
    MMU_CFG                      : mmu_generic_config_type
  ) return natural is
  begin
    return mmuL2TagSize(MMU_CFG);
  end tagL1Lsb;
  
  
  function tagL2Msb(
    MMU_CFG                      : mmu_generic_config_type
  ) return natural is
  begin
    return mmuL2TagSize(MMU_CFG) - 1;
  end tagL2Msb;
  
  
  function tagL2Lsb(
    MMU_CFG                      : mmu_generic_config_type
  ) return natural is
  begin
    return 0;
  end tagL2Lsb;

end mmu_pkg; -- mmu_pkg

