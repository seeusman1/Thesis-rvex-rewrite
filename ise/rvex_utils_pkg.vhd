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

-- 6. r-VEX was developed by Stephan Wong, Thijs van As, Fakhar Anjam, Roel Seedorf,
-- Anthony Brandon. r-VEX is currently maintained by TU Delft (J.S.S.M.Wong@tudelft.nl).

-- Copyright (C) 2008-2014 by TU Delft.

library IEEE;
use IEEE.std_logic_1164.all;

library work;
use work.rvex_pkg.all;
use work.rvex_pipeline_pkg.all;

--=============================================================================
-- This package contains generic utility functions and procedures used both for
-- logic generation.
-------------------------------------------------------------------------------
package rvex_utils_pkg is
--=============================================================================
  
  -- Converts a lane index to a group index.
  function lane2group (
    lane  : natural;
    CFG   : rvex_generic_config_type
  ) return natural;
  
  -- Converts a group index to the first lane index in it.
  function group2firstLane (
    laneGroup : natural;
    CFG       : rvex_generic_config_type
  ) return natural;
  
  -- Converts a lane index to the index of the first lane in the group.
  function lane2firstLane (
    lane      : natural;
    CFG       : rvex_generic_config_type
  ) return natural;
  
  -- Determines the indices for a block in a binary tree. See package body for
  -- more information.
  procedure binTreeIndices(
    level       : in  natural;
    blockIndex  : in  natural;
    indexA      : out natural;
    indexB      : out natural
  );
  
  -- Inverts the bit in value selected by bitIndex.
  function flipBit(
    value       : natural;
    bitIndex    : natural
  ) return natural;
    
end rvex_utils_pkg;

--=============================================================================
package body rvex_utils_pkg is
--=============================================================================

  -- Converts a lane index to a group index.
  function lane2group (
    lane      : natural;
    CFG       : rvex_generic_config_type
  ) return natural is
  begin
    return lane / 2**(CFG.numLanesLog2 - CFG.numLaneGroupsLog2);
  end lane2group;
  
  -- Converts a group index to the first lane index in it.
  function group2firstLane (
    laneGroup : natural;
    CFG       : rvex_generic_config_type
  ) return natural is
  begin
    return laneGroup * 2**(CFG.numLanesLog2 - CFG.numLaneGroupsLog2);
  end group2firstLane;
  
  -- Converts a lane index to the index of the first lane in the group.
  function lane2firstLane (
    lane      : natural;
    CFG       : rvex_generic_config_type
  ) return natural is
  begin
    return group2firstLane(lane2group(lane, CFG), CFG);
  end lane2firstLane;
  
  -- Used to construct a binary tree network for connecting pipelane groups
  -- together which looks like this:
  --                                     indexA, indexB
  --                                           |
  --         ___       ___        ___          v
  --   ---->| 0 |---->| 0 |----->| 0 |-------> 0
  --        |   |     | __|      | __|
  --   ---->|___|----->| 1 |----->| 1 |------> 1
  --         ___      ||   |     || __|
  --   ---->| 1 |---->||   | ----->| 2 |-----> 2
  --        |   |      |   |     ||| __|
  --   ---->|___|----->|___|------->| 3 |----> 3
  --         ___       ___       ||||   |
  --   ---->| 2 |---->| 2 |----->||||   | ---> 4
  --        |   |     | __|       |||   |
  --   ---->|___|----->| 3 |----->|||   | ---> 5
  --         ___      ||   |       ||   |
  --   ---->| 3 |---->||   | ----->||   | ---> 6
  --        |   |      |   |        |   |
  --   ---->|___|----->|___|------->|___|----> 7
  --
  -- level -> 0          1            2
  --
  -- Number in blocks: blockIndex
  --
  -- The method takes level and block as parameters and outputs the indices for
  -- each connection block. The outer loop for level should range from 0 to
  -- log2(numIndices)-1, the inner loop for blockIndex should range from 0 to
  -- numIndices/2-1.
  procedure binTreeIndices(
    level       : in  natural;
    blockIndex  : in  natural;
    indexA      : out natural;
    indexB      : out natural
  ) is
    variable index: natural;
  begin
    index   := (blockIndex / 2**level) * 2 * 2**level
             + (blockIndex mod 2**level);
    indexA  := index;
    indexB  := index + 2**level;
  end procedure;
  
  -- Inverts the bit in value selected by bitIndex.
  function flipBit(
    value       : natural;
    bitIndex    : natural
  ) return natural is
  begin
    return (value / (2*2**bitIndex)) * (2*2**bitIndex) -- The stuff before bitIndex.
         + (value mod (2**bitIndex))                   -- The stuff after bitIndex.
         + (1 - (                                      -- Invert...
             (value / (2**bitIndex)) mod 2             -- ... the value at bitIndex...
           )) * (2**bitIndex);                         -- ... and shift it back to its position.
  end flipBit;
  
end rvex_utils_pkg;
