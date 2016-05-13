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
use rvex.bus_pkg.all;
use rvex.core_pkg.all;
use rvex.cache_pkg.all;

entity cache_mmu is
  generic (
    RCFG                        : rvex_generic_config_type := rvex_cfg;
    CCFG                        : cache_generic_config_type := cache_CFG
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
    clkEn                       : in  std_logic;
    
    ---------------------------------------------------------------------------
    -- Core interface
    ---------------------------------------------------------------------------
    -- Common interface.
    rv2cache_decouple           : in  std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    cache2rv_blockReconfig      : out std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    cache2rv_stallIn            : out std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    rv2cache_stallOut           : in  std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    cache2rv_status             : out rvex_cacheStatus_array(2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    -- MMU control interface.
    rv2mmu_pageTablePtr         : in  rvex_address_array(2**RCFG.numLaneGroupsLog2-1 downto 0) := (others => (others => '0'));
    rv2mmu_addrSpaceID          : in  rvex_address_array(2**RCFG.numLaneGroupsLog2-1 downto 0) := (others => (others => '0'));
    rv2mmu_enable               : in  std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0) := (others => '0');
    rv2mmu_kernelMode           : in  std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0) := (others => '1');
    rv2mmu_wtcTrapEna           : in  std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0) := (others => '0');
    
    -- Instruction memory request.
    rv2icache_PCs               : in  rvex_address_array(2**RCFG.numLaneGroupsLog2-1 downto 0);
    rv2icache_fetch             : in  std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    rv2icache_cancel            : in  std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    -- Instruction memory response: valid one clkEn'd unstalled cycle after the
    -- request.
    icache2rv_instr             : out rvex_syllable_array(2**RCFG.numLanesLog2-1 downto 0);
    icache2rv_affinity          : out std_logic_vector(2**RCFG.numLaneGroupsLog2*RCFG.numLaneGroupsLog2-1 downto 0);
    icache2rv_busFault          : out std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    icache2rv_pageFault         : out std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    icache2rv_kernelAccVio      : out std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    -- Data memory request. Bypass signals that the request will bypass the
    -- cache (not the MMU) regardless of the state of the cacheable page flag.
    -- It's primarily intended for MMUless instantiations.
    rv2dcache_addr              : in  rvex_address_array(2**RCFG.numLaneGroupsLog2-1 downto 0);
    rv2dcache_readEnable        : in  std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    rv2dcache_writeData         : in  rvex_data_array(2**RCFG.numLaneGroupsLog2-1 downto 0);
    rv2dcache_writeMask         : in  rvex_mask_array(2**RCFG.numLaneGroupsLog2-1 downto 0);
    rv2dcache_writeEnable       : in  std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    rv2dcache_bypass            : in  std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0) := (others => '0');
    
    -- Data memory response: valid one clkEn'd unstalled cycle after the
    -- request.
    dcache2rv_readData          : out rvex_data_array(2**RCFG.numLaneGroupsLog2-1 downto 0);
    dcache2rv_busFault          : out std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    dcache2rv_ifaceFault        : out std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    dcache2rv_pageFault         : out std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    dcache2rv_kernelAccVio      : out std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    dcache2rv_writeAccVio       : out std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    dcache2rv_writeToClean      : out std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    ---------------------------------------------------------------------------
    -- Bus master interfaces
    ---------------------------------------------------------------------------
    -- Bus interface for the caches and MMU table walker. The timing of these
    -- signals is governed by clkEnBus.
    cache2bus_mst               : out bus_mst2slv_array(2**RCFG.numLaneGroupsLog2 downto 0);
    bus2cache_mst               : in  bus_slv2mst_array(2**RCFG.numLaneGroupsLog2 downto 0);
    
    ---------------------------------------------------------------------------
    -- Bus slave interface
    ---------------------------------------------------------------------------
    -- Bus slave interface for the status and control registers.
    bus2cache_slv               : in  bus_mst2slv_type;
    cache2bus_slv               : out bus_slv2mst_type;
    
    ---------------------------------------------------------------------------
    -- Bus snooping interface
    ---------------------------------------------------------------------------
    -- These signals are optional. They are needed for cache coherency on
    -- multi-processor systems and/or for dynamic cores. The timing of these
    -- signals is governed by clkEnBus.
    
    -- Bus address which is to be invalidated when invalEnable is high.
    bus2cache_invalAddr         : in  rvex_address_type := (others => '0');
    
    -- If one of the data caches is causing the invalidation due to a write,
    -- the signal in this vector indexed by that data cache must be high. In
    -- all other cases, these signals should be low.
    bus2cache_invalSource       : in  std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0) := (others => '0');
    
    -- Active high enable signal for line invalidation.
    bus2cache_invalEnable       : in  std_logic := '0'
    
  );
end cache_mmu;

architecture structural of cache_mmu is

begin

end architecture; 

