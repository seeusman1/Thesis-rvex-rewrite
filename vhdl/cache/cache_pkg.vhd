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

library IEEE;
use IEEE.std_logic_1164.all;

--=============================================================================
-- Definitions
--=============================================================================
-- Atom: a maximal set of inseperable pipelanes. For the current design, with
--   4 cores of 2 pipelanes being the configuration with the greatest number
--   of independent cores, an atom would be 2 pipelanes.

package cache_pkg is
  
  --===========================================================================
  -- Configuration constants
  --===========================================================================
  -- Size of the entire address space represented as log2(depthInBytes). This
  -- is also the expected width of the PC.
  constant RC_ADDR_SPACE_BLOG2  : natural := 32;
  
  -- Bus data size represented as log2(sizeInBytes).
  constant RC_BUS_SIZE_BLOG2    : natural := 2;
  
  -- Number of cache lines in the data cache represented as
  -- log2(numberOfLines). A data cache line has the same size as the bus width.
  constant RC_DCACHE_LINES_LOG2 : natural := 6;
  
  -- Number of cache lines in the instruction cache represented as
  -- log2(numberOfLines). An instruction cache line has the size of a full
  -- rvex instruction.
  constant RC_ICACHE_LINES_LOG2 : natural := 6;
  
  -- Number of "atoms". This is the number of sets of inseperable pipelanes.
  -- Represented as log2(numberOfAtoms).
  constant RC_NUM_ATOMS_LOG2    : natural := 2;
  
  -- Size of an instruction for *a single atom*, represented as
  -- log2(sizeInBytes).
  constant RC_INSTR_SIZE_BLOG2  : natural := 3;
  
  --===========================================================================
  -- Configuration constant math
  --===========================================================================
  -- Data bus address width.
  constant RC_BUS_ADDR_WIDTH    : natural := RC_ADDR_SPACE_BLOG2;
  
  -- Data bus data width.
  constant RC_BUS_DATA_WIDTH    : natural := 8*(2**RC_BUS_SIZE_BLOG2);
  
  -- Data bus bytemask.
  constant RC_BUS_MASK_WIDTH    : natural := 2**RC_BUS_SIZE_BLOG2;
  
  -- Number of atoms.
  constant RC_NUM_ATOMS         : natural := 2**RC_NUM_ATOMS_LOG2;
  
  -- Instruction width for an atom.
  constant RC_ATOM_INSTR_WIDTH  : natural := 8*(2**RC_INSTR_SIZE_BLOG2);
  
  --===========================================================================
  -- External interface port record types
  --===========================================================================
  -- Signals from an atom to the cache.
  type reconfCache_atomIn is record
    
    -- This bit determines whether this atom is currently configured to be a
    -- master (high) or a slave (low). When an atom is a slave, its memory
    -- interface is ignored and replaced with that of the next higher indexed
    -- atom with decouple driven high. The following rules should be followed
    -- with respect to these decouple signals.
    --  - The decouple bit for the highest indexed atom must be driven high.
    --  - A decouple bit may not have transition while one or both of the
    --    associated atoms are accessing the memory or in the middle of a
    --    stall, beit from this cache or elsewhere.
    decouple                    : std_logic;
    
    -- Instruction memory interface. fetch is an active high read enable
    -- signal.
    PC                          : std_logic_vector(RC_BUS_ADDR_WIDTH-1 downto 0);
    fetch                       : std_logic;
    
    -- Data memory interface. All control signals are active high. When the
    -- bypass signal is high, the memory will be accessed directly (i.e. it
    -- will always miss, and the cache will not update).
    addr                        : std_logic_vector(RC_BUS_ADDR_WIDTH-1 downto 0);
    readEnable                  : std_logic;
    writeData                   : std_logic_vector(RC_BUS_DATA_WIDTH-1 downto 0);
    writeMask                   : std_logic_vector(RC_BUS_MASK_WIDTH-1 downto 0);
    writeEnable                 : std_logic;
    bypass                      : std_logic;
    
    -- Stall input. Connect to the final, merged pipeline stall signal used by
    -- the connected atom.
    stall                       : std_logic;
    
  end record;
  
  -- Signals from the cache to an atom.
  type reconfCache_atomOut is record
    
    -- Instruction memory interface.
    instr                       : std_logic_vector(RC_ATOM_INSTR_WIDTH-1 downto 0);
    
    -- Data memory interface.
    readData                    : std_logic_vector(RC_BUS_DATA_WIDTH-1 downto 0);
    
    -- Stall output. When this is high, the processor pipeline should be
    -- halted.
    stall                       : std_logic;
    
  end record;
  
  -- Signals from a memory bus interface to the cache.
  type reconfCache_memIn is record
    
    -- Read data from the bus, expected to be the data at the address
    -- requested in the previous cycle when ready is high.
    data                        : std_logic_vector(RC_BUS_DATA_WIDTH-1 downto 0);
    
    -- Ready flag, active high.
    ready                       : std_logic;
    
  end record;
  
  -- Signals from the cache to a memory bus interface.
  type reconfCache_memOut is record
    
    -- Requested byte address, aligned to bus size.
    addr                        : std_logic_vector(RC_BUS_ADDR_WIDTH-1 downto 0);
    
    -- Bus read enable, active high.
    readEnable                  : std_logic;
    
    -- Bus write data.
    writeData                   : std_logic_vector(RC_BUS_DATA_WIDTH-1 downto 0);
    
    -- Active high bytemask for bus writes.
    writeMask                   : std_logic_vector(RC_BUS_MASK_WIDTH-1 downto 0);
    
    -- Active high bus write enable signal.
    writeEnable                 : std_logic;
    
    -- Active high burst enable signal. This is asserted when the next request
    -- is going to be the same kind of operation on the next address.
    burstEnable                 : std_logic;
    
  end record;
  
  -- Array types for the above four records.
  type reconfCache_atomIn_array
    is array (0 to RC_NUM_ATOMS-1)
    of reconfCache_atomIn;
  type reconfCache_atomOut_array
    is array (0 to RC_NUM_ATOMS-1)
    of reconfCache_atomOut;
  type reconfCache_memIn_array
    is array (0 to RC_NUM_ATOMS-1)
    of reconfCache_memIn;
  type reconfCache_memOut_array
    is array (0 to RC_NUM_ATOMS-1)
    of reconfCache_memOut;
  
  -- Cache invalidation system input.
  type reconfCache_invalIn is record
    
    -- Active high address invalidation request.
    invalEnable                 : std_logic;
    
    -- Address which is to be invalidated.
    invalAddr                   : std_logic_vector(RC_BUS_ADDR_WIDTH-1 downto 0);
    
    -- Active high flush requests. These are not governed by the stall signal,
    -- they always invalidate the entire cache within a clock cycle when
    -- clkEnBus is high.
    flushICache                 : std_logic;
    flushDCache                 : std_logic;
    
  end record;
  
  -- Cache invalidation system output.
  type reconfCache_invalOut is record
    
    -- Active high stall signal, asserted when the invalidation logic is busy.
    -- invalEnable should not be asserted when stall is high.
    stall                       : std_logic;
    
    -- Invalidation error output. An invalidation error occurs when multiple
    -- invalidation sources are requesting cache line invalidation at the same
    -- time. This should never happen in a proper design because all these
    -- sources should be connected to the same bus, but at least for simulation
    -- this signal is useful.
    error                       : std_logic;
    
  end record;
  
end cache_pkg;

package body cache_pkg is
end cache_pkg;
