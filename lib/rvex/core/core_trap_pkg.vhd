-- This file is generated by the scripts in /config. --

-- r-VEX processor                                                                                   -- GENERATED --
-- Copyright (C) 2008-2016 by TU Delft.
-- All Rights Reserved.

-- THIS IS A LEGAL DOCUMENT, BY USING r-VEX,
-- YOU ARE AGREEING TO THESE TERMS AND CONDITIONS.

-- No portion of this work may be used by any commercial entity, or for any
-- commercial purpose, without the prior, written permission of TU Delft.
-- Nonprofit and noncommercial use is permitted as described below.
                                                                                                     -- GENERATED --
-- 1. r-VEX is provided AS IS, with no warranty of any kind, express
-- or implied. The user of the code accepts full responsibility for the
-- application of the code and the use of any results.

-- 2. Nonprofit and noncommercial use is encouraged. r-VEX may be
-- downloaded, compiled, synthesized, copied, and modified solely for nonprofit,
-- educational, noncommercial research, and noncommercial scholarship
-- purposes provided that this notice in its entirety accompanies all copies.
-- Copies of the modified software can be delivered to persons who use it
-- solely for nonprofit, educational, noncommercial research, and                                    -- GENERATED --
-- noncommercial scholarship purposes provided that this notice in its
-- entirety accompanies all copies.

-- 3. ALL COMMERCIAL USE, AND ALL USE BY FOR PROFIT ENTITIES, IS EXPRESSLY
-- PROHIBITED WITHOUT A LICENSE FROM TU Delft (J.S.S.M.Wong@tudelft.nl).

-- 4. No nonprofit user may place any restrictions on the use of this software,
-- including as modified by the user, by any other authorized user.

-- 5. Noncommercial and nonprofit users may distribute copies of r-VEX                               -- GENERATED --
-- in compiled or binary form as set forth in Section 2, provided that
-- either: (A) it is accompanied by the corresponding machine-readable source
-- code, or (B) it is accompanied by a written offer, with no time limit, to
-- give anyone a machine-readable copy of the corresponding source code in
-- return for reimbursement of the cost of distribution. This written offer
-- must permit verbatim duplication by anyone, or (C) it is distributed by
-- someone who received only the executable form, and is accompanied by a
-- copy of the written offer of source code.

-- 6. r-VEX was developed by Stephan Wong, Thijs van As, Fakhar Anjam,                               -- GENERATED --
-- Roel Seedorf, Anthony Brandon, Jeroen van Straten. r-VEX is currently
-- maintained by TU Delft (J.S.S.M.Wong@tudelft.nl).

-- Copyright (C) 2008-2016 by TU Delft.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library rvex;                                                                                        -- GENERATED --
use rvex.common_pkg.all;
use rvex.utils_pkg.all;
use rvex.core_intIface_pkg.all;
use rvex.core_pipeline_pkg.all;

--=============================================================================
-- This package specifies the encoding of the trap cause field and contains
-- various types and records to do with traps.
-------------------------------------------------------------------------------
package core_trap_pkg is                                                                             -- GENERATED --
--=============================================================================

  -----------------------------------------------------------------------------
  -- Trap information type
  -----------------------------------------------------------------------------
  -- This record contains all information needed to trigger or identify a trap.
  type trap_info_type is record

    -- Active high flag indicating whether this trap is active.
    active                      : std_logic;                                                         -- GENERATED --

    -- Trap cause, using the encoding specified in this package.
    cause                       : rvex_trap_type;

    -- Additional information associated with the trap, for example a data
    -- memory address.
    arg                         : rvex_address_type;

  end record;
                                                                                                     -- GENERATED --
  -- Array type.
  type trap_info_array is array (natural range <>) of trap_info_type;

  -- Trap information types array'd for every pipeline stage.
  subtype trap_info_stages_type is trap_info_array(S_FIRST to S_LTRP);
  subtype std_logic_stages_type is std_logic_vector(S_FIRST to S_LTRP);
  type trap_info_stages_array is array (natural range <>) of trap_info_stages_type;
  type std_logic_stages_array is array (natural range <>) of std_logic_stages_type;

  -- Default value for trap_info_type signals.                                                       -- GENERATED --
  constant TRAP_INFO_NONE       : trap_info_type := (
    active => '0',
    cause  => (others => '0'),
    arg    => (others => '0')
  );

  -- Undefined value for trap_info_type signals.
  constant TRAP_INFO_UNDEF      : trap_info_type := (
    active => RVEX_UNDEF,
    cause  => (others => RVEX_UNDEF),                                                                -- GENERATED --
    arg    => (others => RVEX_UNDEF)
  );

  -- Merges two trap info records together, giving priority to the second
  -- operand.
  function "&"(l: trap_info_type; r: trap_info_type) return trap_info_type;

  -----------------------------------------------------------------------------
  -- Trap cause decoding table entry type
  -----------------------------------------------------------------------------                      -- GENERATED --
  -- Each trap cause has a table entry like this which defines the trap.
  type trapTableEntry_type is record

    -- Defines how the trap is shown in simulation.
    name                        : string(1 to 50);

    -- Defines whether this is a debug trap or not. Debug traps are ignored
    -- while another debug trap is already being executed or when external
    -- debug is on. In the latter case, the core is paused when a debug trap
    -- occurs.                                                                                       -- GENERATED --
    isDebugTrap                 : std_logic;

    -- Defines whether this is an external interrupt trap or not. When set,
    -- the irqAck signal will be asserted for one cycle when the trap is
    -- entered.
    isInterrupt                 : std_logic;

  end record;

  -- Array type of the above to get a table. The index of this table is the                          -- GENERATED --
  -- trap cause.
  type trapTable_type is array (0 to 2**RVEX_TRAP_CAUSE_SIZE-1) of trapTableEntry_type;

  --===========================================================================
  -- Trap cause identifiers
  --===========================================================================
  constant RVEX_TRAP_NONE               : natural := 0;
  constant RVEX_TRAP_INVALID_OP         : natural := 1;
  constant RVEX_TRAP_MISALIGNED_BRANCH  : natural := 2;
  constant RVEX_TRAP_FETCH_FAULT        : natural := 3;                                              -- GENERATED --
  constant RVEX_TRAP_MISALIGNED_ACCESS  : natural := 4;
  constant RVEX_TRAP_DMEM_FAULT         : natural := 5;
  constant RVEX_TRAP_LIMMH_FAULT        : natural := 6;
  constant RVEX_TRAP_EXT_INTERRUPT      : natural := 7;
  constant RVEX_TRAP_STOP               : natural := 8;
  constant RVEX_TRAP_SOFT_CTXT_SWITCH   : natural := 9;
  constant RVEX_TRAP_DMEM_PAGE_FAULT    : natural := 16;
  constant RVEX_TRAP_DMEM_KSPACE_VIO    : natural := 17;
  constant RVEX_TRAP_DMEM_WRITE_VIO     : natural := 18;
  constant RVEX_TRAP_DMEM_WRITE_TO_CLEAN: natural := 19;                                             -- GENERATED --
  constant RVEX_TRAP_IMEM_PAGE_FAULT    : natural := 24;
  constant RVEX_TRAP_IMEM_KSPACE_VIO    : natural := 25;
  constant RVEX_TRAP_IMEM_ACCESS_VIO    : natural := 26;
  constant RVEX_TRAP_SOFT_DEBUG_0       : natural := 248;
  constant RVEX_TRAP_SOFT_DEBUG_1       : natural := 249;
  constant RVEX_TRAP_SOFT_DEBUG_2       : natural := 250;
  constant RVEX_TRAP_STEP_COMPLETE      : natural := 251;
  constant RVEX_TRAP_HW_BREAKPOINT_0    : natural := 252;
  constant RVEX_TRAP_HW_BREAKPOINT_1    : natural := 253;
  constant RVEX_TRAP_HW_BREAKPOINT_2    : natural := 254;                                            -- GENERATED --
  constant RVEX_TRAP_HW_BREAKPOINT_3    : natural := 255;

  -- Shorthand for converting a natural trap ID to an rvex_trap_type.
  function rvex_trap(t: natural) return rvex_trap_type;

  --===========================================================================
  -- Trap cause decoding table
  --===========================================================================
  -- Indexes in this table correspond to the trap identifiers in the previous
  -- section of this file. The name field uses the following replacements.                           -- GENERATED --
  --   "%c" --> Trap cause represented as an unsigned integer.
  --   "@"  --> Converts to " at " + trap point represented in hex when known.
  --            When trap point is not specified, the character is removed.
  --   "%x" --> Trap argument represented in hex.
  --   "%d" --> Trap argument represented in signed decimal.
  --   "%u" --> Trap argument represented in unsigned decimal.
  constant TRAP_TABLE : trapTable_type := (

    RVEX_TRAP_NONE => (
      name => "trap %c: none                                     ",                                  -- GENERATED --
      isDebugTrap => '0',
      isInterrupt => '0'
    ),

    RVEX_TRAP_INVALID_OP => (
      name => "trap %c: invalid opcode in lane %u@               ",
      isDebugTrap => '0',
      isInterrupt => '0'
    ),
                                                                                                     -- GENERATED --
    RVEX_TRAP_MISALIGNED_BRANCH => (
      name => "trap %c: misaligned branch@; target was %x        ",
      isDebugTrap => '0',
      isInterrupt => '0'
    ),

    RVEX_TRAP_FETCH_FAULT => (
      name => "trap %c: instr. bus fault@                        ",
      isDebugTrap => '0',
      isInterrupt => '0'                                                                             -- GENERATED --
    ),

    RVEX_TRAP_MISALIGNED_ACCESS => (
      name => "trap %c: misaligned access@; address was %x       ",
      isDebugTrap => '0',
      isInterrupt => '0'
    ),

    RVEX_TRAP_DMEM_FAULT => (
      name => "trap %c: data bus fault@; address was %x          ",                                  -- GENERATED --
      isDebugTrap => '0',
      isInterrupt => '0'
    ),

    RVEX_TRAP_LIMMH_FAULT => (
      name => "trap %c: LIMMH fwd. fault in lane %u@             ",
      isDebugTrap => '0',
      isInterrupt => '0'
    ),
                                                                                                     -- GENERATED --
    RVEX_TRAP_EXT_INTERRUPT => (
      name => "trap %c: external interrupt %d                    ",
      isDebugTrap => '0',
      isInterrupt => '1'
    ),

    RVEX_TRAP_STOP => (
      name => "trap %c: stop request@                            ",
      isDebugTrap => '1',
      isInterrupt => '0'                                                                             -- GENERATED --
    ),

    RVEX_TRAP_SOFT_CTXT_SWITCH => (
      name => "trap %c: soft ctxt sw. request@                   ",
      isDebugTrap => '0',
      isInterrupt => '0'
    ),

    RVEX_TRAP_DMEM_PAGE_FAULT => (
      name => "trap %c: data page fault@; address was %x         ",                                  -- GENERATED --
      isDebugTrap => '0',
      isInterrupt => '0'
    ),

    RVEX_TRAP_DMEM_KSPACE_VIO => (
      name => "trap %c: kern. acc. vio.@; address was %x         ",
      isDebugTrap => '0',
      isInterrupt => '0'
    ),
                                                                                                     -- GENERATED --
    RVEX_TRAP_DMEM_WRITE_VIO => (
      name => "trap %c: write acc. vio.@; address was %x         ",
      isDebugTrap => '0',
      isInterrupt => '0'
    ),

    RVEX_TRAP_DMEM_WRITE_TO_CLEAN => (
      name => "trap %c: write to clean@; address was %x          ",
      isDebugTrap => '0',
      isInterrupt => '0'                                                                             -- GENERATED --
    ),

    RVEX_TRAP_IMEM_PAGE_FAULT => (
      name => "trap %c: instr. page fault@                       ",
      isDebugTrap => '0',
      isInterrupt => '0'
    ),

    RVEX_TRAP_IMEM_KSPACE_VIO => (
      name => "trap %c: kern. acc. vio.@                         ",                                  -- GENERATED --
      isDebugTrap => '0',
      isInterrupt => '0'
    ),

    RVEX_TRAP_IMEM_ACCESS_VIO => (
      name => "trap %c: write acc. vio.@                         ",
      isDebugTrap => '0',
      isInterrupt => '0'
    ),
                                                                                                     -- GENERATED --
    RVEX_TRAP_SOFT_DEBUG_0 => (
      name => "trap %c: soft debug trap 0@                       ",
      isDebugTrap => '1',
      isInterrupt => '0'
    ),

    RVEX_TRAP_SOFT_DEBUG_1 => (
      name => "trap %c: soft debug trap 1@                       ",
      isDebugTrap => '1',
      isInterrupt => '0'                                                                             -- GENERATED --
    ),

    RVEX_TRAP_SOFT_DEBUG_2 => (
      name => "trap %c: soft debug trap 2@                       ",
      isDebugTrap => '1',
      isInterrupt => '0'
    ),

    RVEX_TRAP_STEP_COMPLETE => (
      name => "trap %c: step complete trap@                      ",                                  -- GENERATED --
      isDebugTrap => '1',
      isInterrupt => '0'
    ),

    RVEX_TRAP_HW_BREAKPOINT_0 => (
      name => "trap %c: breakpoint 0@, address/PC %x             ",
      isDebugTrap => '1',
      isInterrupt => '0'
    ),
                                                                                                     -- GENERATED --
    RVEX_TRAP_HW_BREAKPOINT_1 => (
      name => "trap %c: breakpoint 1@, address/PC %x             ",
      isDebugTrap => '1',
      isInterrupt => '0'
    ),

    RVEX_TRAP_HW_BREAKPOINT_2 => (
      name => "trap %c: breakpoint 2@, address/PC %x             ",
      isDebugTrap => '1',
      isInterrupt => '0'                                                                             -- GENERATED --
    ),

    RVEX_TRAP_HW_BREAKPOINT_3 => (
      name => "trap %c: breakpoint 3@, address/PC %x             ",
      isDebugTrap => '1',
      isInterrupt => '0'
    ),

    others => (
      name => "trap %c@ (unknown)                                ",                                  -- GENERATED --
      isDebugTrap => '0',
      isInterrupt => '0'
    )
  );

  -- Shorthand for extracting the isDebugTrap signal from an (encoded)
  -- trap_info_type record.
  function rvex_isDebugTrap(t: trap_info_type) return std_logic;

  -- Shorthand for extracting the isInterrupt signal from an (encoded)                               -- GENERATED --
  -- trap_info_type record.
  function rvex_isInterruptTrap(t: trap_info_type) return std_logic;

  -- Returns '1' only when the trap cause is set to RVEX_TRAP_STOP.
  function rvex_isStopTrap(t: trap_info_type) return std_logic;

end core_trap_pkg;

--=============================================================================
package body core_trap_pkg is                                                                        -- GENERATED --
--=============================================================================

  -- Merges two trap info records together, giving priority to the first
  -- operand.
  function "&"(l: trap_info_type; r: trap_info_type) return trap_info_type is
  begin
    if l.active = '1' then
      return l;
    else
      return r;                                                                                      -- GENERATED --
    end if;
  end "&";

  -- Shorthand for converting a natural trap ID to an rvex_trap_type.
  function rvex_trap(t: natural) return rvex_trap_type is
  begin
    return uint2vect(t, RVEX_TRAP_CAUSE_SIZE);
  end rvex_trap;

  -- Shorthand for extracting the isDebugTrap signal from an (encoded)                               -- GENERATED --
  -- trap_info_type record.
  function rvex_isDebugTrap(t: trap_info_type) return std_logic is
  begin
    return TRAP_TABLE(vect2uint(t.cause)).isDebugTrap;
  end rvex_isDebugTrap;

  -- Shorthand for extracting the isInterrupt signal from an (encoded)
  -- trap_info_type record.
  function rvex_isInterruptTrap(t: trap_info_type) return std_logic is
  begin                                                                                              -- GENERATED --
    return TRAP_TABLE(vect2uint(t.cause)).isInterrupt;
  end rvex_isInterruptTrap;

  -- Returns '1' only when the trap cause is set to RVEX_TRAP_STOP.
  function rvex_isStopTrap(t: trap_info_type) return std_logic is
  begin
    if vect2uint(t.cause) = RVEX_TRAP_STOP then
      return '1';
    else
      return '0';                                                                                    -- GENERATED --
    end if;
  end rvex_isStopTrap;

end core_trap_pkg;
