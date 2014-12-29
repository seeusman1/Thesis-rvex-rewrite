-- r-VEX processor
-- Copyright (C) 2008-2014 by TU Delft.
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

-- Copyright (C) 2008-2014 by TU Delft.

-- Refer to reconfCache_pkg.vhd for configuration constants and most
-- documentation.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library rvex;
use rvex.cache_pkg.all;
use rvex.cache_intIface_pkg.all;
use rvex.cache_instr_pkg.all;
use rvex.cache_data_pkg.all;

entity cache is
  port (
    
    -- Clock input.
    clk                       : in  std_logic;
    
    -- Active high reset input.
    reset                     : in  std_logic;
    
    -- Active high CPU interface clock enable input.
    clkEnCPU                  : in  std_logic;
    
    -- Active high bus interface clock enable input.
    clkEnBus                  : in  std_logic;
    
    -- Connections to the r-vex cores. Governed by clkEnCPU.
    atomsToCache              : in  reconfCache_atomIn_array;
    cacheToAtoms              : inout reconfCache_atomOut_array; -- i am ugly
    
    -- Connections to the memory bus. Governed by clkEnBus.
    memToCache                : in  reconfCache_memIn_array;
    cacheToMem                : out reconfCache_memOut_array;
    
    -- Cache invalidation connections. Governed by clkEnBus.
    invalToCache              : in  reconfCache_invalIn;
    cacheToInval              : out reconfCache_invalOut
    
  );
end cache;

architecture Behavioral of cache is
  
  -- Interconnect between atoms and caches.
  signal atomsToICache        : reconfICache_atomIn_array;
  signal ICacheToAtoms        : reconfICache_atomOut_array;
  signal atomsToDCache        : reconfDCache_atomIn_array;
  signal DCacheToAtoms        : reconfDCache_atomOut_array;
  
  -- Interconnect between caches and memory bus arbiters.
  signal arbToICache          : reconfICache_memIn_array;
  signal ICacheToArb          : reconfICache_memOut_array;
  signal arbToDCache          : reconfDCache_memIn_array;
  signal DCacheToArb          : reconfDCache_memOut_array;
  
  -- Invalidation interconnect.
  signal arbiterInvalOutputs  : RC_arbiterInvalOutput_array;
  signal invalICache          : reconfICache_invalIn;
  signal invalDCache          : reconfDCache_invalIn;
  
  
  -- Sanity check memory.
  -- pragma translate-off
  type ram_data_type
    is array(0 to 4095)
    of std_logic_vector(RDC_BUS_DATA_WIDTH-1 downto 0);
  shared variable check_data  : ram_data_type := (others => (others => '-'));
  signal check_address_r      : std_logic_vector(31 downto 0);
  signal check_readEnable_r   : std_logic;
  -- pragma translate-on
  
begin
  
  --===========================================================================
  -- Interconnect between atoms and cache
  --===========================================================================
  atom_cache_intercon_gen: for i in 0 to RC_NUM_ATOMS-1 generate
    
    -- Atoms to instruction cache.
    atomsToICache(i).decouple     <= atomsToCache(i).decouple;
    atomsToICache(i).PC           <= atomsToCache(i).PC;
    atomsToICache(i).readEnable   <= atomsToCache(i).fetch;
    atomsToICache(i).stall        <= atomsToCache(i).stall;
    
    -- Atoms to data cache.
    atomsToDCache(i).decouple     <= atomsToCache(i).decouple;
    atomsToDCache(i).addr         <= atomsToCache(i).addr;
    atomsToDCache(i).readEnable   <= atomsToCache(i).readEnable;
    atomsToDCache(i).writeData    <= atomsToCache(i).writeData;
    atomsToDCache(i).writeMask    <= atomsToCache(i).writeMask;
    atomsToDCache(i).writeEnable  <= atomsToCache(i).writeEnable;
    atomsToDCache(i).bypass       <= atomsToCache(i).bypass;
    atomsToDCache(i).stall        <= atomsToCache(i).stall;
    
    -- Caches to atoms.
    cacheToAtoms(i).instr         <= ICacheToAtoms(i).instr;
    cacheToAtoms(i).readData      <= DCacheToAtoms(i).readData;
    cacheToAtoms(i).stall         <= ICacheToAtoms(i).stall or DCacheToAtoms(i).stall;
    
  end generate;
  
  --===========================================================================
  -- Instantiate instruction caches
  --===========================================================================
  instruction_cache: entity rvex.cache_instr
    port map (
      
      -- System control inputs.
      clk                     => clk,
      reset                   => reset,
      clkEnCPU                => clkEnCPU,
      clkEnBus                => clkEnBus,
      
      -- Connections to the atoms. Governed by clkEnCPU.
      atomsToCache            => atomsToICache,
      cacheToAtoms            => ICacheToAtoms,
      
      -- Connections to the memory bus. Governed by clkEnBus.
      memToCache              => arbToICache,
      cacheToMem              => ICacheToArb,
      
      -- Cache line invalidation input. Governed by clkEnBus.
      inval                   => invalICache
      
    );
  
  --===========================================================================
  -- Instantiate data caches
  --===========================================================================
  data_cache: entity rvex.cache_data
    port map (
      
      -- System control inputs.
      clk                     => clk,
      reset                   => reset,
      clkEnCPU                => clkEnCPU,
      clkEnBus                => clkEnBus,
      
      -- Connections to the atoms. Governed by clkEnCPU.
      atomsToCache            => atomsToDCache,
      cacheToAtoms            => DCacheToAtoms,
      
      -- Connections to the memory bus. Governed by clkEnBus.
      memToCache              => arbToDCache,
      cacheToMem              => DCacheToArb,
      
      -- Cache line invalidation input. Governed by clkEnBus.
      inval                   => invalDCache
      
    );
  
  --===========================================================================
  -- Instantiate memory bus arbiters
  --===========================================================================
  mem_arbiter_gen: for i in 0 to RC_NUM_ATOMS-1 generate
    mem_arbiter_n: entity rvex.cache_arbiter
      port map (
        
        -- System control inputs.
        clk                   => clk,
        reset                 => reset,
        clkEn                 => clkEnBus,
        
        -- Instruction cache memory bus.
        arbToICache           => arbToICache(i),
        ICacheToArb           => ICacheToArb(i),
        
        -- Data cache memory bus.
        arbToDCache           => arbToDCache(i),
        DCacheToArb           => DCacheToArb(i),
        
        -- Combined memory bus.
        memToArb              => memToCache(i),
        arbToMem              => cacheToMem(i),
        
        -- Invalidation output.
        invalOutput           => arbiterInvalOutputs(i)
        
      );
  end generate;
  
  --===========================================================================
  -- Instantiate invalidation control unit
  --===========================================================================
  invalidation_controller: entity rvex.cache_invalCtrl
    port map (
      
      -- Inputs from arbiters.
      arbToInvalCtrl          => arbiterInvalOutputs,
      
      -- External invalidation bus.
      extToInvalCtrl          => invalToCache,
      invalCtrlToExt          => cacheToInval,
      
      -- Outputs to instruction and data caches.
      invalICache             => invalICache,
      invalDCache             => invalDCache
      
    );
  
end Behavioral;

