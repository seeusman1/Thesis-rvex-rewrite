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

library rvex;
use rvex.cache_pkg.all;

--=============================================================================
-- Definitions
--=============================================================================
-- Atom: a maximal set of inseperable pipelanes. For the current design, with
--   4 cores of 2 pipelanes being the configuration with the greatest number
--   of independent cores, an atom would be 2 pipelanes.
--
--=============================================================================
-- Identities for configuration constants
--=============================================================================
-- 2^(RIC_ATOM_SIZE_BLOG2 + RIC_NUM_ATOMS_LOG2)
--   = total instruction vector size when all pipelanes are working together
--     (bytes)
--   = cache line width (bytes)
--
-- 2^(RIC_ATOM_SIZE_BLOG2 + RIC_NUM_ATOMS_LOG2 + RIC_CACHE_LINES_LOG2)
--   = total size of a single cache block (bytes)
--
-- 2^(RIC_NUM_ATOMS_LOG2)
--   = number of cache blocks
--   = number of data bus masters
--   = number of output instruction vectors
--   = number of PC inputs
--   = decouple vector width (bits)
--
-- 2^(RIC_ATOM_SIZE_BLOG2)
--   = output instruction vector width (bytes)
--
-- 2^(RIC_ADDR_SPACE_BLOG2)
--   = input PC vector width (bits)
--   = output data bus read address width (bits)
--
-- 2^(RIC_BUS_SIZE_BLOG2)
--   = input data bus read data width (bytes)
--
-- 2^(RIC_ATOM_SIZE_BLOG2 + RIC_NUM_ATOMS_LOG2 - RIC_BUS_SIZE_BLOG2)
--   = number of full data bus widths in a cache line, must be >= 1.

package cache_instr_pkg is
  
  --===========================================================================
  -- Configuration constants
  --===========================================================================
  -- Size of the PC address space represented as log2(depthInBytes).
  constant RIC_ADDR_SPACE_BLOG2 : natural := RC_ADDR_SPACE_BLOG2;
  
  -- Combined instruction size for an atom represented as log2(sizeInBytes).
  constant RIC_ATOM_SIZE_BLOG2  : natural := RC_INSTR_SIZE_BLOG2;
  
  -- Number of cache lines (depth) in a single block.
  constant RIC_CACHE_LINES_LOG2 : natural := RC_ICACHE_LINES_LOG2;
  
  -- Data bus size represented as log2(sizeInBytes).
  constant RIC_BUS_SIZE_BLOG2   : natural := RC_BUS_SIZE_BLOG2;
  
  -- log2 of the number of atoms.
  constant RIC_NUM_ATOMS_LOG2   : natural := RC_NUM_ATOMS_LOG2;
  
  --===========================================================================
  -- Configuration constant math
  --===========================================================================
  -- PC width.
  constant RIC_PC_WIDTH         : natural := RIC_ADDR_SPACE_BLOG2;
  
  -- Data bus address width.
  constant RIC_BUS_ADDR_WIDTH   : natural := RIC_ADDR_SPACE_BLOG2;
  
  -- Data bus data width.
  constant RIC_BUS_DATA_WIDTH   : natural := 8*(2**RIC_BUS_SIZE_BLOG2);
  
  -- Number of bus accesses needed per cache line.
  constant RIC_BUS_PER_LINE     : natural := 2**(RIC_ATOM_SIZE_BLOG2 + RIC_NUM_ATOMS_LOG2 - RIC_BUS_SIZE_BLOG2);
  
  -- Instruction width for an atom.
  constant RIC_ATOM_INSTR_WIDTH : natural := 8*(2**RIC_ATOM_SIZE_BLOG2);
  
  -- Number of atoms.
  constant RIC_NUM_ATOMS        : natural := 2**RIC_NUM_ATOMS_LOG2;
  
  -- Cache line width.
  constant RIC_LINE_WIDTH       : natural := 8*(2**(RIC_ATOM_SIZE_BLOG2+RIC_NUM_ATOMS_LOG2));
  
  -- Cache depth.
  constant RIC_CACHE_DEPTH      : natural := 2**RIC_CACHE_LINES_LOG2;
  
  -- LSB of the line offset within the cache for a given address.
  constant RIC_ADDR_OFFSET_LSB  : natural := RIC_ATOM_SIZE_BLOG2+RIC_NUM_ATOMS_LOG2;
  
  -- Number of bits used to represent the above offset.
  constant RIC_ADDR_OFFSET_SIZE : natural := RIC_CACHE_LINES_LOG2;
  
  -- LSB of the cache tag for a given address.
  constant RIC_ADDR_TAG_LSB     : natural := RIC_ADDR_OFFSET_LSB+RIC_ADDR_OFFSET_SIZE;
  
  -- Number of bits used to represent the cache tag.
  constant RIC_ADDR_TAG_SIZE    : natural := RIC_ADDR_SPACE_BLOG2-RIC_ADDR_TAG_LSB;
  
  --===========================================================================
  -- External interface port record types
  --===========================================================================
  -- Signals from an atom to the cache.
  type reconfICache_atomIn is record
    
    -- PC input from the atom.
    PC                          : std_logic_vector(RIC_PC_WIDTH-1 downto 0);
    
    -- This bit determines whether this atom is currently configured to be a
    -- master (high) or a slave (low). When an atom is a slave, its PC and
    -- readEnable signals are ignored and are taken from the next higher
    -- indexed atom with decouple driven high, and the instruction placed on
    -- the output will be part of the wide instruction of the master atom.
    -- The following rules should be followed with respect to these signals.
    --  - The decouple bit for the highest indexed atom must be driven high.
    --  - A decouple bit may not have transition while one or both of the
    --    associated atoms are requesting a read (readEnable is high), were
    --    requesting a read in the previous cycle, or are waiting for a cache
    --    miss (stall output is high). In order for such a situation to occur
    --    as soon as possible, the pipelanes should finish their current
    --    instructions (i.e. wait for all stalls to clear) and then drive
    --    readEnable low and gate their clock. When all associated pipelanes
    --    have had readEnable low for two cycles, the decouple bit may toggle.
    decouple                    : std_logic;
    
    -- Instruction read enable. This should be high in order for the cache to
    -- start fetching an instruction from memory or cache, and will thus be
    -- high unless something else is stalling the core (for example the
    -- synchronization block for configuration changes discussed above).
    readEnable                  : std_logic;
    
    -- Stall input from the atoms. This signal determines whether to use the
    -- provided PC as input (low) or the previous PC (high). This allows the
    -- PC to originate from one pipeline stage earlier than the instruction
    -- output, allowing the cache memory to be synchronous.
    stall                       : std_logic;
    
  end record;
  
  -- Signals from the cache to an atom.
  type reconfICache_atomOut is record
    
    -- Instruction output to the atom. Valid when stall is low and readEnable
    -- from the highest indexed coupled atom was high in the previous cycle.
    instr                       : std_logic_vector(RIC_ATOM_INSTR_WIDTH-1 downto 0);
    
    -- Stall output. If readEnable from the highest indexed coupled atom is
    -- low, this is always low.
    stall                       : std_logic;
    
  end record;
  
  -- Signals from a memory bus interface to the cache.
  type reconfICache_memIn is record
    
    -- Read data from the bus, expected to be the data at the read address
    -- requested in the previous cycle when ready is high.
    data                        : std_logic_vector(RIC_BUS_DATA_WIDTH-1 downto 0);
    
    -- Ready flag, active high.
    ready                       : std_logic;
    
  end record;
  
  -- Signals from the cache to a memory bus interface.
  type reconfICache_memOut is record
    
    -- Requested byte address, aligned to bus size.
    addr                        : std_logic_vector(RIC_BUS_ADDR_WIDTH-1 downto 0);
    
    -- Bus read enable, active high.
    readEnable                  : std_logic;
    
  end record;
  
  -- Array types for the above four records.
  type reconfICache_atomIn_array
    is array (0 to RIC_NUM_ATOMS-1)
    of reconfICache_atomIn;
  type reconfICache_atomOut_array
    is array (0 to RIC_NUM_ATOMS-1)
    of reconfICache_atomOut;
  type reconfICache_memIn_array
    is array (0 to RIC_NUM_ATOMS-1)
    of reconfICache_memIn;
  type reconfICache_memOut_array
    is array (0 to RIC_NUM_ATOMS-1)
    of reconfICache_memOut;
  
  -- Cache line invalidation request record.
  type reconfICache_invalIn is record
    
    -- Active high address invalidation request.
    invalEnable                 : std_logic;
    
    -- Address which is to be invalidated.
    invalAddr                   : std_logic_vector(RIC_BUS_ADDR_WIDTH-1 downto 0);
    
    -- Active high flush request.
    flush                       : std_logic;
    
  end record;
  
  --===========================================================================
  -- Internal record types
  --===========================================================================
  -- This record is used in the mux/demux stages between the atom inputs and
  -- the cache blocks, as well as in the cache block inputs.
  type RIC_inputMuxDemuxVector is record
    
    -- Read enable signal from the atom, active high.
    readEnable                  : std_logic;
    
    -- Requested address/PC.
    PC                          : std_logic_vector(RIC_PC_WIDTH-1 downto 0);
    
    -- This signal is high when the associated cache block must attempt to
    -- update the cache line associated with the PC. This is based on the
    -- hit output of all coupled cache blocks and the registered readEnable:
    -- when readEnable is high and all hit signals are low, one of the cache
    -- blocks in the set will have updateEnable pulled high. The cache block
    -- selected for updating when multiple cache blocks are working together
    -- is based on the PC bits just above the cache index, but could be
    -- determined based on any replacement policy.
    updateEnable                : std_logic;
    
    -- Decouple bit network, see mux/demux implementation code comments for
    -- more information.
    decouple                    : std_logic;
    
    -- Combined pipeline stall signal from the atoms.
    stall                       : std_logic;
    
  end record;
  
  -- Input mux/demux record for each atom.
  type RIC_inputMuxDemuxVector_array
    is array (0 to RIC_NUM_ATOMS-1)
    of RIC_inputMuxDemuxVector;
  
  -- Input mux/demux array for each level in the mux/demux logic.
  type RIC_inputMuxDemuxVector_levels
    is array (0 to RIC_NUM_ATOMS_LOG2)
    of RIC_inputMuxDemuxVector_array;
  
  -- This record is used in the mux/demux stages between the cache blocks
  -- and the atom outputs, as well as in the cache block outputs.
  type RIC_outputMuxDemuxVector is record
    
    -- Registered read enable signal from the atom, active high.
    readEnable                  : std_logic;
    
    -- Hit output from the cache.
    hit                         : std_logic;
    
    -- The stall output for an atom is equal to readEnable and not hit for the
    -- last level of the muxing/demuxing logic.
    
    -- Registered version of the PC being requested by the atom if readEnable
    -- was active in the previous cycle. Only the low bits which index within
    -- a cache line are used so the rest will be optimized away during
    -- synthesis, but the rest is also handy for debugging in the simulation.
    PC                          : std_logic_vector(RIC_PC_WIDTH-1 downto 0);
    
    -- Cache line data, valid when hit and readEnable were high in the previous
    -- cycle.
    line                        : std_logic_vector(RIC_LINE_WIDTH-1 downto 0);
    
  end record;
  
  -- Output mux/demux record for each atom.
  type RIC_outputMuxDemuxVector_array
    is array (0 to RIC_NUM_ATOMS-1)
    of RIC_outputMuxDemuxVector;
  
  -- Output mux/demux array for each level in the mux/demux logic.
  type RIC_outputMuxDemuxVector_levels
    is array (0 to RIC_NUM_ATOMS_LOG2)
    of RIC_outputMuxDemuxVector_array;
  
end cache_instr_pkg;

package body cache_instr_pkg is
end cache_instr_pkg;
