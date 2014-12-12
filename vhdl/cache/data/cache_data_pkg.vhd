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
-- 2^(RDC_NUM_ATOMS_LOG2)
--   = number of cache blocks
--   = number of data bus masters
--   = number of MEM units connections
--   = decouple vector width (bits)
--
-- 2^(RDC_ADDR_SPACE_BLOG2)
--   = width of all address vectors (bits)
--
-- 2^(RIC_BUS_SIZE_BLOG2)
--   = width of all data vectors
--   = width of one cache line
--
--=============================================================================
-- Write-through behavior, read miss behavior and cache coherency
--=============================================================================
-- The following rules should be followed by the cache implementation in order
-- to ensure cache coherency.
--
--  - When a write is performed and one or more cache blocks have the word in
--    storage, the highest indexed cache block must service the write.
--
--  - When a write is performed while none of the cache blocks have the word
--    in storage, the cache block servicing the write will be the first cache
--    block of which the write buffer is ready for a new command, in order to
--    service the request as soon as possible.
--
--  - When the write buffer is or becomes free for multiple cache blocks at
--    the same time, the highest indexed cache block services the write.
--
--  - When a write is serviced, the cache is updated immediately. If the write
--    is not a full word, the cache is to first behave as if there was a read
--    miss in order to retrieve the remaining data. The CPU must be stalled
--    while this read is in progress to ensure conherency, otherwise another
--    cache block might perform a cache update before the cache update for this
--    block finishes, with the old memory data. The memory write access after
--    that however may be buffered.
--
--  - To ensure that a read following a write returns the new value even when
--    multiple cache blocks have the same memory location in storage, of which
--    one may be invalid due to the memory write/invalidation being buffered,
--    the highest indexed cache with a hit must be used for reads.
--
--  - When a memory write is performed on the bus, beit issued by one of the
--    data caches or an external source, all caches receive an invalidate
--    signal. However, when a data cache issues a memory write, it must ignore
--    its own invalidation signal, as it would be stupid to throw away a cache
--    line which was just updated and is known to be valid.
--
--  - The choice of using the highest-indexed cache when there is otherwise no
--    preference is not arbitrary due to cache consistency during configuration
--    switches. When there is a switch from 2x4 to 1x8 for example, the higher
--    indexed core will continue executing its program, which means that the
--    higher indexed caches must take precedence over the lower ones, as cache
--    coherency between independent cores is more relaxed than within a core.

package cache_data_pkg is
  
  --===========================================================================
  -- Configuration constants
  --===========================================================================
  -- Size of the memory address space represented as log2(depthInBytes).
  constant RDC_ADDR_SPACE_BLOG2 : natural := RC_ADDR_SPACE_BLOG2;
  
  -- Number of cache lines (depth) in a single block.
  constant RDC_CACHE_LINES_LOG2 : natural := RC_DCACHE_LINES_LOG2;
  
  -- Data bus size represented as log2(sizeInBytes).
  constant RDC_BUS_SIZE_BLOG2   : natural := RC_BUS_SIZE_BLOG2;
  
  -- log2 of the number of atoms.
  constant RDC_NUM_ATOMS_LOG2   : natural := RC_NUM_ATOMS_LOG2;
  
  --===========================================================================
  -- Configuration constant math
  --===========================================================================
  -- Data bus address width.
  constant RDC_BUS_ADDR_WIDTH   : natural := RDC_ADDR_SPACE_BLOG2;
  
  -- Data bus data width.
  constant RDC_BUS_DATA_WIDTH   : natural := 8*(2**RDC_BUS_SIZE_BLOG2);
  
  -- Data bus bytemask.
  constant RDC_BUS_MASK_WIDTH   : natural := 2**RDC_BUS_SIZE_BLOG2;
  
  -- Number of atoms.
  constant RDC_NUM_ATOMS        : natural := 2**RDC_NUM_ATOMS_LOG2;
  
  -- Cache line width. Fixed to exactly one bus size; set associativity or
  -- more words per line are not supported.
  constant RDC_LINE_WIDTH       : natural := RDC_BUS_DATA_WIDTH;
  
  -- Cache depth.
  constant RDC_CACHE_DEPTH      : natural := 2**RDC_CACHE_LINES_LOG2;
  
  -- LSB of the line offset within the cache for a given address.
  constant RDC_ADDR_OFFSET_LSB  : natural := RDC_BUS_SIZE_BLOG2;
  
  -- Number of bits used to represent the above offset.
  constant RDC_ADDR_OFFSET_SIZE : natural := RDC_CACHE_LINES_LOG2;
  
  -- LSB of the cache tag for a given address.
  constant RDC_ADDR_TAG_LSB     : natural := RDC_ADDR_OFFSET_LSB+RDC_ADDR_OFFSET_SIZE;
  
  -- Number of bits used to represent the cache tag.
  constant RDC_ADDR_TAG_SIZE    : natural := RDC_ADDR_SPACE_BLOG2-RDC_ADDR_TAG_LSB;
  
  --===========================================================================
  -- External interface port record types
  --===========================================================================
  -- Signals from an atom to the cache.
  type reconfDCache_atomIn is record
    
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
    
    -- Memory address to access.
    addr                        : std_logic_vector(RDC_BUS_ADDR_WIDTH-1 downto 0);
    
    -- Memory read enable signal.
    readEnable                  : std_logic;
    
    -- Data for write accesses.
    writeData                   : std_logic_vector(RDC_BUS_DATA_WIDTH-1 downto 0);
    
    -- Active high bytemask for writes.
    writeMask                   : std_logic_vector(RDC_BUS_MASK_WIDTH-1 downto 0);
    
    -- Active high write enable signal.
    writeEnable                 : std_logic;
    
    -- Bypass signal. When high, memory accesses will be forwarded directly to
    -- the memory, without any intervention from the cache.
    bypass                      : std_logic;
    
    -- Stall input from the atoms. This signal determines whether to use the
    -- provided memory access command as input (low) or the previous command
    -- (high). This allows the command to originate from one pipeline stage
    -- earlier than the memory read output, allowing the cache memory to be
    -- synchronous.
    stall                       : std_logic;
    
  end record;
  
  -- Signals from the cache to an atom.
  type reconfDCache_atomOut is record
    
    -- Memory read output to the atom. Valid when stall is low and readEnable
    -- from the highest indexed coupled atom was high in the previous cycle.
    readData                    : std_logic_vector(RDC_BUS_DATA_WIDTH-1 downto 0);
    
    -- Stall output.
    stall                       : std_logic;
    
  end record;
  
  -- Signals from a memory bus interface to the cache.
  type reconfDCache_memIn is record
    
    -- Read data from the bus, expected to be the data at the address
    -- requested in the previous cycle when ready is high.
    data                        : std_logic_vector(RDC_BUS_DATA_WIDTH-1 downto 0);
    
    -- Ready flag, active high.
    ready                       : std_logic;
    
  end record;
  
  -- Signals from the cache to a memory bus interface.
  type reconfDCache_memOut is record
    
    -- Requested byte address, aligned to bus size.
    addr                        : std_logic_vector(RDC_BUS_ADDR_WIDTH-1 downto 0);
    
    -- Bus read enable, active high.
    readEnable                  : std_logic;
    
    -- Bus write data.
    writeData                   : std_logic_vector(RDC_BUS_DATA_WIDTH-1 downto 0);
    
    -- Active high bytemask for bus writes.
    writeMask                   : std_logic_vector(RDC_BUS_MASK_WIDTH-1 downto 0);
    
    -- Active high bus write enable signal.
    writeEnable                 : std_logic;
    
  end record;
  
  -- Array types for the above four records.
  type reconfDCache_atomIn_array
    is array (0 to RDC_NUM_ATOMS-1)
    of reconfDCache_atomIn;
  type reconfDCache_atomOut_array
    is array (0 to RDC_NUM_ATOMS-1)
    of reconfDCache_atomOut;
  type reconfDCache_memIn_array
    is array (0 to RDC_NUM_ATOMS-1)
    of reconfDCache_memIn;
  type reconfDCache_memOut_array
    is array (0 to RDC_NUM_ATOMS-1)
    of reconfDCache_memOut;
  
  -- Cache line invalidation request record.
  type reconfDCache_invalIn is record
    
    -- Active high address invalidation request.
    invalEnable                 : std_logic;
    
    -- Address which is to be invalidated.
    invalAddr                   : std_logic_vector(RDC_BUS_ADDR_WIDTH-1 downto 0);
    
    -- Bit n in this vector will be asserted high when the invalidation
    -- request was triggered by a write from cache block n. In such a case,
    -- that cache block should ignore the write as per the cache coherency
    -- rules specified at the top of reconfDCache_pkg.vhd.
    invalSource                 : std_logic_vector(RDC_NUM_ATOMS-1 downto 0);
    
    -- Active high flush request.
    flush                       : std_logic;
    
  end record;
  
  --===========================================================================
  -- Internal record types
  --===========================================================================
  -- This record is used in the mux/demux stages between the atom inputs and
  -- the cache blocks, as well as in the cache block inputs.
  type RDC_inputMuxDemuxVector is record
    
    -- Decouple bit network, see mux/demux implementation code comments for
    -- more information.
    decouple                    : std_logic;
    
    -- Requested address.
    addr                        : std_logic_vector(RDC_BUS_ADDR_WIDTH-1 downto 0);
    
    -- Read enable signal from the atom, active high.
    readEnable                  : std_logic;
    
    -- This signal is high when the associated cache block must attempt to
    -- update the cache line associated with the previous address due to a
    -- read miss. This is based on the hit output of all coupled cache blocks
    -- and the registered readEnable: when readEnable is high and all hit
    -- signals are low, one of the cache blocks in the set will have
    -- updateEnable pulled high. The cache block selected for updating when
    -- multiple cache blocks are working together is based on the address bits
    -- just above the cache index, but could be determined based on any
    -- replacement policy.
    updateEnable                : std_logic;
    
    -- Data for write accesses.
    writeData                   : std_logic_vector(RDC_BUS_DATA_WIDTH-1 downto 0);
    
    -- Active high bytemask for writes.
    writeMask                   : std_logic_vector(RDC_BUS_MASK_WIDTH-1 downto 0);
    
    -- Write enable signal from the atom, active high.
    writeEnable                 : std_logic;
    
    -- This signal is high when the associated cache block must service the
    -- write requested in the previous cycle. This signal passes through this
    -- network without merging; its value is computed in the output network.
    handleWrite                 : std_logic;
    
    -- When this signal is high, the cache must ignore the command given and
    -- must instead forward it directly to the memory bus. The highest indexed
    -- cache block is always used for bypass accesses.
    bypass                      : std_logic;
    
    -- Combined pipeline stall signal from the atoms.
    stall                       : std_logic;
    
  end record;
  
  -- Input mux/demux record for each atom.
  type RDC_inputMuxDemuxVector_array
    is array (0 to RDC_NUM_ATOMS-1)
    of RDC_inputMuxDemuxVector;
  
  -- Input mux/demux array for each level in the mux/demux logic.
  type RDC_inputMuxDemuxVector_levels
    is array (0 to RDC_NUM_ATOMS_LOG2)
    of RDC_inputMuxDemuxVector_array;
  
  -- This record is used in the mux/demux stages between the cache blocks
  -- and the atom outputs, as well as in the cache block outputs.
  type RDC_outputMuxDemuxVector is record
    
    -- Registered read enable signal from the atom, active high.
    readEnable                  : std_logic;
    
    -- Hit output from the cache.
    hit                         : std_logic;
    
    -- Stall output for writes and bypassed memory accesses.The stall signal
    -- for reads is computed at the end of the output network based on
    -- readEnable and not hit. The final stall signal to the atom is the or
    -- of both.
    writeOrBypassStall          : std_logic;
    
    -- Bypass output from the cache. When this is high for the higher indexed
    -- block, the read data should be taken from that block, regardless of
    -- hit state.
    bypass                      : std_logic;
    
    -- Write servicing priority output for the associated cache block. The
    -- encoding is as follows when writeEnable was high in the previous cycle.
    --   "11" - already servicing the request (to prevent priority switches
    --          while servicing in progress)
    --   "10" - cache hit
    --   "01" - no cache hit, but write buffer is ready
    --   "00" - no cache hit, write buffer is full
    -- The signal should not be used when no write has been requested.
    writePrio                   : std_logic_vector(1 downto 0);
    
    -- Write servicing select signal, determines which cache block should
    -- service the previously requested write, if there is one. The inputs
    -- for the writeSel network should be set to '1'. At the output of the
    -- network, it is guaranteed that only one writeSel bit is active.
    writeSel                    : std_logic;
    
    -- Registered version of the address being requested by the atom. This
    -- signal is only used partially by the read miss replacement policy logic,
    -- most of it will be optimized away.
    addr                        : std_logic_vector(RDC_BUS_ADDR_WIDTH-1 downto 0);
    
    -- Cache data output, valid when hit and readEnable were high in the
    -- previous cycle.
    data                        : std_logic_vector(RDC_BUS_DATA_WIDTH-1 downto 0);
    
  end record;
  
  -- Output mux/demux record for each atom.
  type RDC_outputMuxDemuxVector_array
    is array (0 to RDC_NUM_ATOMS-1)
    of RDC_outputMuxDemuxVector;
  
  -- Output mux/demux array for each level in the mux/demux logic.
  type RDC_outputMuxDemuxVector_levels
    is array (0 to RDC_NUM_ATOMS_LOG2)
    of RDC_outputMuxDemuxVector_array;
  
end cache_data_pkg;

package body cache_data_pkg is
end cache_data_pkg;
