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
use rvex.core_pkg.all;

--=============================================================================
-- rvex core configuration package for test suite runner.
-------------------------------------------------------------------------------
package core_cfg is
--=============================================================================

  -- Test case or test suite file under test. This will determine what the
  -- testbench will do.
  constant ROOT_FILE            : string := "../tests/index.suite";
  
  -- Core configuration under test. Due to VHDL constraints, this cannot be
  -- changed by the test cases runtime. Instead, you select the configuration
  -- here and the test cases will check if they are compatible with it.
  constant CFG                  : rvex_generic_config_type := rvex_cfg(

    -- log2 of the number of lanes to instantiate.
    numLanesLog2                => 1,
    
    -- log2 of the number of lane groups to instantiate. Each lane group can be
    -- disabled individually to save power, operate on its own, or work
    -- together on a single thread with other lane groups. May not be greater
    -- than 3 (due to configuration register size limits) or numLanesLog2.
    numLaneGroupsLog2           => 0,
    
    -- log2 of the number of hardware contexts in the core. May not be greater
    -- than 3 due to configuration register size limits.
    numContextsLog2             => 0,
    
    -- log2 of the number of syllables in a generic binary bundle. All branch
    -- targets are assumed to be aligned to this, but trap return addresses may
    -- not be. When a trap return address is not aligned to this and
    -- limmhFromPreviousPair is set, then special actions will be taken to
    -- ensure that the relevant syllables preceding the trap point are fetched
    -- before operation resumes.
    genBundleSizeLog2           => 3,
    
    -- Assume (and enforce) that the start addresses of bundles are aligned to
    -- the specified amount of syllables. When this is less than numLanesLog2,
    -- additional logic is instantiated to handle aligning the memory accesses.
    -- The advantage of this is that bundles can be shorter by specifying the
    -- stop bit earlier when ILP is not sufficient to save on memory accesses.
    -- Note that traps are generated when a stop bit is encountered in any
    -- syllable not occuring just before an alignment point.
    bundleAlignLog2             => 1,
    
    -- Defines which lanes have a multiplier. Bit 0 of this number maps to lane
    -- 0, bit 1 to lane 1, etc.
    multiplierLanes             => 2#11111111#,

    -- Defines which lanes have which floating-point units. Bit 0 of these
    -- numbers maps to lane 0, bit 1 to lane 1, etc.
    -- Floating-point add
    faddLanes                   => 2#11111111#,

    -- Floating-point compare
    fcompareLanes               => 2#11111111#,

    -- Floating-point convert-to-int
    fconvfiLanes                => 2#11111111#,

    -- Floating-point convert-to-float
    fconvifLanes                => 2#11111111#,

    -- Floating-point multiply
    fmultiplyLanes              => 2#11111111#,
    
    -- Lane index for the memory unit, counting down from the last lane in each
    -- lane group. So memLaneRevIndex = 0 results in the memory unit being in
    -- the last lane in each group, memLaneRevIndex = 1 results in it being in
    -- the second to last lane, etc.
    memLaneRevIndex             => 1,
    
    -- Lane index for the branch unit, counting down from the last lane in each
    -- lane group. So branchLaneRevIndex = 0 results in the branch unit being
    -- in the last lane in each group, branchLaneRevIndex = 1 results in it
    -- being in the second to last lane, etc.
    branchLaneRevIndex          => 0,
    
    -- Defines how many hardware breakpoints are evaluated. Maximum is 4 due to
    -- the register map only having space for 4.
    numBreakpoints              => 4,
    
    -- Whether or not register forwarding logic should be instantiated. With
    -- forwarding disabled, the core will use less area and might run at higher
    -- frequencies, but much more NOPs are necessary between data-dependent
    -- instructions.
    forwarding                  => 1,
    
    -- When true, syllables can borrow long immediates from the other syllable
    -- in a syllable pair.
    limmhFromNeighbor           => 1,
    
    -- When true, syllables can borrow long immediates from the previous
    -- syllable pair (with the same index within the pair) within a generic
    -- binary bundle.
    limmhFromPreviousPair       => 0,
    
    -- When true, general purpose register 63 maps directly to the link
    -- register. When false, MTL, MFL, STL and LDL must be used to access the
    -- link register.
    reg63isLink                 => 0,
    
    -- Start address in the data address space for the 1kbyte control
    -- register file. Must be aligned to a 1kbyte boundary.
    cregStartAddress            => X"FFFFFC00",
    
    -- Configures the reset address for each context. Should all be set to 0
    -- for the test cases to run correctly.
    resetVectors                => (others => (others => '0')),
    
    -- When true, the stall signals for each group will either be all high or
    -- all low. This depends on the memory architecture; when this is set, the
    -- memory architecture can be made simpler, but cannot make use of the
    -- possible performance gain due to being able to stall only part of the
    -- core.
    unifiedStall                => 0,
    
    -- Whether the trace unit should be instantiated.
    traceEnable                 => 1
    
  );
  
  -- The probability that the mem2rv_stallIn signal will be asserted high to
  -- stall the core.
  constant MEM_STALL_PROBABILITY: real := 0.5;
  
end core_cfg;
