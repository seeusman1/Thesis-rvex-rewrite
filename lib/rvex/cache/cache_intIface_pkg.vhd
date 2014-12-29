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
use rvex.cache_instr_pkg.all;
use rvex.cache_data_pkg.all;

package cache_intIface_pkg is
  
  --===========================================================================
  -- Internal record types
  --===========================================================================
  -- Output from an instruction/data cache arbiter, signalling when it performs
  -- a write.
  type RC_arbiterInvalOutput is record
    
    -- Active high address invalidation request.
    inval                       : std_logic;
    
    -- Address which is to be invalidated.
    addr                        : std_logic_vector(RC_BUS_ADDR_WIDTH-1 downto 0);
    
  end record;
  
  -- Array type for the above.
  type RC_arbiterInvalOutput_array
    is array (0 to RC_NUM_ATOMS-1)
    of RC_arbiterInvalOutput;
  
  --===========================================================================
  -- Component declarations for internal blocks
  --===========================================================================
  -- Arbiter which connects the memory busses of a data and instruction cache
  -- together.
  component reconfCache_arbiter is
    port (
      
      -- Clock input.
      clk                       : in  std_logic;
      
      -- Active high reset input.
      reset                     : in  std_logic;
      
      -- Active high clock enable input.
      clkEn                     : in  std_logic;
      
      -- Instruction cache memory bus.
      arbToICache               : out reconfICache_memIn;
      ICacheToArb               : in  reconfICache_memOut;
      
      -- Data cache memory bus.
      arbToDCache               : out reconfDCache_memIn;
      DCacheToArb               : in  reconfDCache_memOut;
      
      -- Combined memory bus.
      memToArb                  : in  reconfCache_memIn;
      arbToMem                  : out reconfCache_memOut;
      
      -- Invalidation output.
      invalOutput               : out RC_arbiterInvalOutput
      
    );
  end component;
  
  -- Invalidation control unit which merges all the invalidation inputs
  -- together.
  component reconfCache_invalCtrl is
    port (
      
      -- Inputs from arbiters.
      arbToInvalCtrl            : in  RC_arbiterInvalOutput_array;
      
      -- External invalidation bus.
      extToInvalCtrl            : in  reconfCache_invalIn;
      invalCtrlToExt            : out reconfCache_invalOut;
      
      -- Outputs to instruction and data caches.
      invalICache               : out reconfICache_invalIn;
      invalDCache               : out reconfDCache_invalIn
      
    );
  end component;
  
end cache_intIface_pkg;

package body cache_intIface_pkg is
end cache_intIface_pkg;
