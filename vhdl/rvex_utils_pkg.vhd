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
use IEEE.numeric_std.all;

library work;
use work.rvex_pkg.all;
use work.rvex_pipeline_pkg.all;

--=============================================================================
-- This package contains generic utility functions and procedures used both for
-- logic generation.
-------------------------------------------------------------------------------
package rvex_utils_pkg is
--=============================================================================
  
  -- The methods below are shorthands/wrappers for methods from numeric_std.
  -- Where applicable, they also cancel out some of the warning messages which
  -- numeric_std normally spams around.
  function vect2int(v: std_logic_vector) return integer;
  function vect2uint(v: std_logic_vector) return natural;
  function int2vect(i: integer; bits: natural) return std_logic_vector;
  function uint2vect(n: natural; bits: natural) return std_logic_vector;
  function vect2unsigned(v: std_logic_vector) return unsigned;
  function vect2signed(v: std_logic_vector) return signed;
  
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
  
  -- Determines the indices for a block in a binary tree. See package body for
  -- more information.
  procedure binTreeIndices(
    level       : in  natural;
    blockIndex  : in  natural;
    indexA      : out natural;
    indexB      : out natural
  );
  
  -- Returns true if the bit in value selected by bitIndex is 1.
  function testBit(
    value       : natural;
    bitIndex    : natural
  ) return boolean;
  
  -- Inverts the bit in value selected by bitIndex.
  function flipBit(
    value       : natural;
    bitIndex    : natural
  ) return natural;
  
  -- Returns the minimum value of the two operands.
  function min_nat(
    a           : natural;
    b           : natural
  ) return natural;
  
  -- Returns the maximum value of the two operands.
  function max_nat(
    a           : natural;
    b           : natural
  ) return natural;
  
end rvex_utils_pkg;

--=============================================================================
package body rvex_utils_pkg is
--=============================================================================

  -- The methods below are shorthands/wrappers for methods from numeric_std.
  -- Where applicable, they also cancel out some of the warning messages which
  -- numeric_std normally spams around.
  
  constant NULL_STD_LOGIC_VECTOR : std_logic_vector(-1 downto 0) := (others => '0');
  constant NULL_UNSIGNED         : unsigned        (-1 downto 0) := (others => '0');
  constant NULL_SIGNED           : signed          (-1 downto 0) := (others => '0');
  
  function vect2int(v: std_logic_vector) return integer is
  begin
    if v'length = 0 then
      return 0;
    end if;
    if is_X(v) then
      return 0;
    end if;
    return to_integer(signed(v));
  end vect2int;
  
  function vect2uint(v: std_logic_vector) return natural is
  begin
    if v'length = 0 then
      return 0;
    end if;
    if is_X(v) then
      return 0;
    end if;
    return to_integer(unsigned(v));
  end vect2uint;
  
  function int2vect(i: integer; bits: natural) return std_logic_vector is
  begin
    if bits = 0 then
      return NULL_STD_LOGIC_VECTOR;
    end if;
    return std_logic_vector(to_signed(i, bits));
  end int2vect;
  
  function uint2vect(n: natural; bits: natural) return std_logic_vector is
  begin
    if bits = 0 then
      return NULL_STD_LOGIC_VECTOR;
    end if;
    return std_logic_vector(to_unsigned(n, bits));
  end uint2vect;
  
  function vect2unsigned(v: std_logic_vector) return unsigned is
  begin
    if is_X(v) then
      return to_unsigned(0, v'length);
    end if;
    return unsigned(v);
  end vect2unsigned;
  
  function vect2signed(v: std_logic_vector) return signed is
  begin
    if is_X(v) then
      return to_signed(0, v'length);
    end if;
    return signed(v);
  end vect2signed;
  
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
  
  -- Returns true if the bit in value selected by bitIndex is 1.
  function testBit(
    value       : natural;
    bitIndex    : natural
  ) return boolean is
  begin
    return ((value / 2**bitIndex) mod 2) = 1;
  end testBit;
  
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
  
  -- Returns the minimum value of the two operands.
  function min_nat(
    a           : natural;
    b           : natural
  ) return natural is
  begin
    if a > b then
      return b;
    else
      return a;
    end if;
  end min_nat;
  
  -- Returns the maximum value of the two operands.
  function max_nat(
    a           : natural;
    b           : natural
  ) return natural is
  begin
    if a > b then
      return a;
    else
      return b;
    end if;
  end max_nat;
  
end rvex_utils_pkg;
