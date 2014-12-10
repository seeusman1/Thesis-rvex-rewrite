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

--=============================================================================
-- This package contains type definitions and constants relevant both in the
-- core internally and for the external interface of the core.
-------------------------------------------------------------------------------
package rvex_pkg is
--=============================================================================
  
  -- log2 of the size of a syllable in bytes.
  constant SYLLABLE_SIZE_LOG2B  : natural := 2;
  
  -- Subtypes for some common datatypes used within the core.
  subtype rvex_address_type     is std_logic_vector(31 downto  0); -- Any bus address or PC.
  subtype rvex_data_type        is std_logic_vector(31 downto  0); -- Any data word.
  subtype rvex_mask_type        is std_logic_vector( 3 downto  0); -- Byte mask for data words.
  subtype rvex_syllable_type    is std_logic_vector(31 downto  0); -- Any syllable.
  
  -- Array types for the above subtypes.
  type rvex_address_array       is array (natural range <>) of rvex_address_type;
  type rvex_data_array          is array (natural range <>) of rvex_data_type;
  type rvex_mask_array          is array (natural range <>) of rvex_mask_type;
  type rvex_syllable_array      is array (natural range <>) of rvex_syllable_type;
  
  -- rvex core configuration record.
  type rvex_generic_config_type is record
    
    -- log2 of the number of lanes to instantiate.
    numLanesLog2                : natural;
    
    -- log2 of the number of lane groups to instantiate. Each lane group can be
    -- disabled individually to save power, operate on its own, or work
    -- together on a single thread with other lane groups. May not be greater
    -- than 3 (due to configuration register size limits) or numLanesLog2.
    numLaneGroupsLog2           : natural;
    
    -- log2 of the number of hardware contexts in the core. May not be greater
    -- than 3 due to configuration register size limits.
    numContextsLog2             : natural;
    
    -- log2 of the number of syllables in a generic binary bundle. All branch
    -- targets are assumed to be aligned to this, but trap return addresses may
    -- not be. When a trap return address is not aligned to this and
    -- limmhFromPreviousPair is set, then special actions will be taken to
    -- ensure that the relevant syllables preceding the trap point are fetched
    -- before operation resumes.
    genBundleSizeLog2           : natural;
    
    -- Defines which lanes have a multiplier. Bit 0 of this number maps to lane
    -- 0, bit 1 to lane 1, etc.
    multiplierLanes             : natural;
    
    -- Lane index for the memory unit, counting down from the last lane in each
    -- lane group. So memLaneRevIndex = 0 results in the memory unit being in
    -- the last lane in each group, memLaneRevIndex = 1 results in it being in
    -- the second to last lane, etc.
    memLaneRevIndex             : natural;
    
    -- Lane index for the branch unit, counting down from the last lane in each
    -- lane group. So branchLaneRevIndex = 0 results in the branch unit being
    -- in the last lane in each group, branchLaneRevIndex = 1 results in it
    -- being in the second to last lane, etc.
    branchLaneRevIndex          : natural;
    
    -- Defines how many hardware breakpoints are evaluated. Maximum is 4 due to
    -- the register map only having space for 4.
    numBreakpoints              : natural;
    
    -- Whether or not register forwarding logic should be instantiated. With
    -- forwarding disabled, the core will use less area and might run at higher
    -- frequencies, but much more NOPs are necessary between data-dependent
    -- instructions.
    forwarding                  : boolean;
    
    -- When true, syllables can borrow long immediates from the other syllable
    -- in a syllable pair.
    limmhFromNeighbor           : boolean;
    
    -- When true, syllables can borrow long immediates from the previous
    -- syllable pair (with the same index within the pair) within a generic
    -- binary bundle.
    limmhFromPreviousPair       : boolean;
    
    -- When true, general purpose register 63 maps directly to the link
    -- register. When false, MTL, MFL, STL and LDL must be used to access the
    -- link register.
    reg63isLink                 : boolean;
    
    -- Start address in the data address space for the 128-byte control
    -- register file. Must be aligned to a 128-byte boundary.
    cregStartAddress            : rvex_address_type;
    
    -- Configures the reset address for each context. When less than 8 contexts
    -- are used, the higher indexed values are unused.
    resetVectors                : rvex_address_array(7 downto 0);
    
    -- When true, the stall signals for each group will either be all high or
    -- all low. This depends on the memory architecture; when this is set, the
    -- memory architecture can be made simpler, but cannot make use of the
    -- possible performance gain due to being able to stall only part of the
    -- core.
    unifiedStall                : boolean;
    
  end record;
  
  -- Default rvex core configuration.
  constant RVEX_DEFAULT_CONFIG  : rvex_generic_config_type := (
    numLanesLog2                => 3,
    numLaneGroupsLog2           => 2,
    numContextsLog2             => 2,
    genBundleSizeLog2           => 3,
    multiplierLanes             => 2#11111111#,
    memLaneRevIndex             => 1,
    branchLaneRevIndex          => 0,
    numBreakpoints              => 4,
    forwarding                  => true,
    limmhFromNeighbor           => true,
    limmhFromPreviousPair       => true,
    reg63isLink                 => false,
    cregStartAddress            => X"FFFFFF80",
    resetVectors                => (others => (others => '0')),
    unifiedStall                => false
  );
  
  -- Minimal rvex core configuration.
  constant RVEX_MINIMAL_CONFIG  : rvex_generic_config_type := (
    numLanesLog2                => 1,
    numLaneGroupsLog2           => 0,
    numContextsLog2             => 0,
    genBundleSizeLog2           => 3,
    multiplierLanes             => 2#00#,
    memLaneRevIndex             => 1,
    branchLaneRevIndex          => 0,
    numBreakpoints              => 0,
    forwarding                  => false,
    limmhFromNeighbor           => true,
    limmhFromPreviousPair       => false,
    reg63isLink                 => false,
    cregStartAddress            => X"FFFFFF80",
    resetVectors                => (others => (others => '0')),
    unifiedStall                => true
  );
  
  -- Component declaration for the rvex processor.
  component rvex is
    generic (
      CFG                         : rvex_generic_config_type := RVEX_DEFAULT_CONFIG
    );
    port (
      
      -- System control.
      reset                       : in  std_logic;
      clk                         : in  std_logic;
      clkEn                       : in  std_logic;
      
      -- Run control interface.
      rctrl2rv_irq                : in  std_logic_vector(2**CFG.numContextsLog2-1 downto 0) := (others => '0');
      rctrl2rv_irqID              : in  rvex_address_array(2**CFG.numContextsLog2-1 downto 0) := (others => (others => '0'));
      rv2rctrl_irqAck             : out std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
      rctrl2rv_run                : in  std_logic_vector(2**CFG.numContextsLog2-1 downto 0) := (others => '1');
      rv2rctrl_idle               : out std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
      rctrl2rv_reset              : in  std_logic_vector(2**CFG.numContextsLog2-1 downto 0) := (others => '0');
      rv2rctrl_done               : out std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
      
      -- Common memory interface.
      rv2mem_decouple             : out std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
      mem2rv_blockReconfig        : in  std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0) := (others => '0');
      mem2rv_stallIn              : in  std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0) := (others => '0');
      rv2mem_stallOut             : out std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
      
      -- Instruction memory interface.
      rv2imem_PCs                 : out rvex_address_array(2**CFG.numLaneGroupsLog2-1 downto 0);
      rv2imem_fetch               : out std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
      rv2imem_cancel              : out std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
      imem2rv_instr               : in  rvex_syllable_array(2**CFG.numLanesLog2-1 downto 0);
      imem2rv_affinity            : in  std_logic_vector(2**CFG.numLaneGroupsLog2*CFG.numLaneGroupsLog2-1 downto 0) := (others => '1');
      imem2rv_fault               : in  std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0) := (others => '0');
      
      -- Data memory interface.
      rv2dmem_addr                : out rvex_address_array(2**CFG.numLaneGroupsLog2-1 downto 0);
      rv2dmem_readEnable          : out std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
      rv2dmem_writeData           : out rvex_data_array(2**CFG.numLaneGroupsLog2-1 downto 0);
      rv2dmem_writeMask           : out rvex_mask_array(2**CFG.numLaneGroupsLog2-1 downto 0);
      rv2dmem_writeEnable         : out std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
      dmem2rv_readData            : in  rvex_data_array(2**CFG.numLaneGroupsLog2-1 downto 0);
      dmem2rv_fault               : in  std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0) := (others => '0');
      
      -- Control/debug bus interface.
      dbg2rv_addr                 : in  rvex_address_type := (others => '0');
      dbg2rv_readEnable           : in  std_logic := '0';
      dbg2rv_writeEnable          : in  std_logic := '0';
      dbg2rv_writeMask            : in  rvex_mask_type := (others => '1');
      dbg2rv_writeData            : in  rvex_data_type := (others => '0');
      rv2dbg_readData             : out rvex_data_type
      
    );
  end component;

end rvex_pkg;

package body rvex_pkg is
end rvex_pkg;
