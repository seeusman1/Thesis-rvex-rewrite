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
use IEEE.numeric_std.all;

library rvex;
use rvex.common_pkg.all;
--use work.rvex_pkg.all;
use rvex.utils_pkg.all;
use rvex.core_intIface_pkg.all;
use rvex.core_pipeline_pkg.all;

--=============================================================================
-- This package specifies the encoding of the trap cause field and contains
-- various types and records to do with traps.
-------------------------------------------------------------------------------
package core_trap_pkg is
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- Basic types and constants
  -----------------------------------------------------------------------------
  -- Size of the trap cause in bits.
  constant RVEX_TRAP_CAUSE_SIZE : natural := 8;
  
  -- Trap cause type.
  subtype rvex_trap_type is std_logic_vector(RVEX_TRAP_CAUSE_SIZE-1 downto 0);
  type rvex_trap_array is array (natural range <>) of rvex_trap_type;
  
  -----------------------------------------------------------------------------
  -- Trap information type
  -----------------------------------------------------------------------------
  -- This record contains all information needed to trigger or identify a trap.
  type trap_info_type is record
    
    -- Active high flag indicating whether this trap is active.
    active                      : std_logic;
    
    -- Trap cause, using the encoding specified in this package.
    cause                       : rvex_trap_type;
    
    -- Additional information associated with the trap, for example a data
    -- memory address.
    arg                         : rvex_address_type;
    
  end record;
  
  -- Array type.
  type trap_info_array is array (natural range <>) of trap_info_type;
  
  -- Trap information types array'd for every pipeline stage.
  subtype trap_info_stages_type is trap_info_array(S_FIRST to S_LTRP);
  subtype std_logic_stages_type is std_logic_vector(S_FIRST to S_LTRP);
  type trap_info_stages_array is array (natural range <>) of trap_info_stages_type;
  type std_logic_stages_array is array (natural range <>) of std_logic_stages_type;
  
  -- Default value for trap_info_type signals.
  constant TRAP_INFO_NONE       : trap_info_type := (
    active => '0',
    cause  => (others => '0'),
    arg    => (others => '0')
  );
  
  -- Undefined value for trap_info_type signals.
  constant TRAP_INFO_UNDEF      : trap_info_type := (
    active => RVEX_UNDEF,
    cause  => (others => RVEX_UNDEF),
    arg    => (others => RVEX_UNDEF)
  );
  
  -- Merges two trap info records together, giving priority to the second
  -- operand.
  function "&"(l: trap_info_type; r: trap_info_type) return trap_info_type;
  
  -----------------------------------------------------------------------------
  -- Trap cause decoding table entry type
  -----------------------------------------------------------------------------
  -- Each trap cause has a table entry like this which defines the trap.
  type trapTableEntry_type is record
    
    -- Defines how the trap is shown in simulation.
    name                        : string(1 to 50);
    
    -- Defines whether this is a debug trap or not. Debug traps are ignored
    -- while another debug trap is already being executed or when external
    -- debug is on. In the latter case, the core is paused when a debug trap
    -- occurs.
    isDebugTrap                 : std_logic;
    
    -- Defines whether this is an external interrupt trap or not. When set,
    -- the irqAck signal will be asserted for one cycle when the trap is
    -- entered.
    isInterrupt                 : std_logic;
    
  end record;
  
  -- Array type of the above to get a table. The index of this table is the
  -- trap cause.
  type trapTable_type is array (0 to 2**RVEX_TRAP_CAUSE_SIZE-1) of trapTableEntry_type;
  
  --===========================================================================
  -- Trap cause identifiers
  --===========================================================================
  -- Normal operation.
  constant RVEX_TRAP_NONE               : natural := 0;
  
  -- Exceptions.
  constant RVEX_TRAP_INVALID_OP         : natural := 1;
  constant RVEX_TRAP_MISALIGNED_BRANCH  : natural := 2;
  constant RVEX_TRAP_FETCH_FAULT        : natural := 3;
  constant RVEX_TRAP_MISALIGNED_ACCESS  : natural := 4;
  constant RVEX_TRAP_DMEM_FAULT         : natural := 5;
  constant RVEX_TRAP_LIMMH_FAULT        : natural := 6;
  
  -- External interrupt trap.
  constant RVEX_TRAP_EXT_INTERRUPT      : natural := 7;
  
  -- Stop trap.
  constant RVEX_TRAP_STOP               : natural := 8;
  
  -- Debugging traps are positioned at the end of the range. We reserve 8 slots
  -- so the debug trap signal is easy to decode.
  constant RVEX_TRAP_SOFT_DEBUG_0       : natural := 2**RVEX_TRAP_CAUSE_SIZE - 8;
  constant RVEX_TRAP_SOFT_DEBUG_1       : natural := 2**RVEX_TRAP_CAUSE_SIZE - 7;
  constant RVEX_TRAP_SOFT_DEBUG_2       : natural := 2**RVEX_TRAP_CAUSE_SIZE - 6;
  constant RVEX_TRAP_STEP_COMPLETE      : natural := 2**RVEX_TRAP_CAUSE_SIZE - 5;
  constant RVEX_TRAP_HW_BREAKPOINT_0    : natural := 2**RVEX_TRAP_CAUSE_SIZE - 4;
  constant RVEX_TRAP_HW_BREAKPOINT_1    : natural := 2**RVEX_TRAP_CAUSE_SIZE - 3;
  constant RVEX_TRAP_HW_BREAKPOINT_2    : natural := 2**RVEX_TRAP_CAUSE_SIZE - 2;
  constant RVEX_TRAP_HW_BREAKPOINT_3    : natural := 2**RVEX_TRAP_CAUSE_SIZE - 1;
  
  -- Shorthand for converting a natural trap ID to an rvex_trap_type.
  function rvex_trap(t: natural) return rvex_trap_type;
  
  --===========================================================================
  -- Trap cause decoding table
  --===========================================================================
  -- Indexes in this table correspond to the trap identifiers in the previous
  -- section of this file. The name field uses the following replacements.
  --   "%c" --> Trap cause represented as an unsigned integer.
  --   "@"  --> Converts to " at " + trap point represented in hex when known.
  --            When trap point is not specified, the character is removed.
  --   "%x" --> Trap argument represented in hex.
  --   "%d" --> Trap argument represented in signed decimal.
  --   "%u" --> Trap argument represented in unsigned decimal.
  constant TRAP_TABLE : trapTable_type := (
    
    -- Normal operation.
    RVEX_TRAP_NONE => (
      name => "none                                              ",
      isDebugTrap => '0',
      isInterrupt => '0'
    ),
    
    -- Invalid operation. Triggered when an unknown opcode or an opcode using
    -- a functional unit which does not exist in the lane is encountered.
    -- Argument: exact PC for the lane with the invalid opcode.
    RVEX_TRAP_INVALID_OP => (
      name => "trap %c: invalid opcode@                          ",
      isDebugTrap => '0',
      isInterrupt => '0'
    ),
    
    -- Misaligned branch target.
    -- Argument: branch target.
    RVEX_TRAP_MISALIGNED_BRANCH => (
      name => "trap %c: misaligned branch@; target was %x        ",
      isDebugTrap => '0',
      isInterrupt => '0'
    ),
    
    -- Instruction fetch fault.
    -- Argument: PC which was being fetched.
    RVEX_TRAP_FETCH_FAULT => (
      name => "trap %c: instr. fetch fault@; PC was %x           ",
      isDebugTrap => '0',
      isInterrupt => '0'
    ),
    
    -- Misaligned memory access.
    -- Argument: data memory address where access was attempted.
    RVEX_TRAP_MISALIGNED_ACCESS => (
      name => "trap %c: misaligned access@; address was %x       ",
      isDebugTrap => '0',
      isInterrupt => '0'
    ),
    
    -- Data memory fault.
    -- Argument: data memory address where access was attempted.
    RVEX_TRAP_DMEM_FAULT => (
      name => "trap %c: data memory fault@; address was %x       ",
      isDebugTrap => '0',
      isInterrupt => '0'
    ),
    
    -- LIMMH forwarding fault. This occurs when:
    --  - the requested type of forwarding is not supported by the current
    --    configuration (triggered in source lane);
    --  - two LIMMH syllables are attempting to forward to the same lane
    --    (triggered in destination lane);
    --  - the destination lane is not using the immediate value (triggered in
    --    destination lane).
    -- Argument: exact PC for the source or destination lane (see above).
    RVEX_TRAP_LIMMH_FAULT => (
      name => "trap %c: LIMMH forwarding fault@                  ",
      isDebugTrap => '0',
      isInterrupt => '0'
    ),
    
    -- External interrupt.
    -- Argument: interrupt identification.
    RVEX_TRAP_EXT_INTERRUPT => (
      name => "trap %c: external interrupt %d                    ",
      isDebugTrap => '0',
      isInterrupt => '1'
    ),
    
    -- Stop trap.
    -- Argument: unused.
    RVEX_TRAP_STOP => (
      name => "trap %c: stop request 2@, address/PC %x           ",
      isDebugTrap => '1',
      isInterrupt => '0'
    ),
    
    -- Debug traps.
    RVEX_TRAP_SOFT_DEBUG_0 => (
      name => "trap %c: software debug trap 0@, address/PC %x    ",
      isDebugTrap => '1',
      isInterrupt => '0'
    ),
    RVEX_TRAP_SOFT_DEBUG_1 => (
      name => "trap %c: software debug trap 1@, address/PC %x    ",
      isDebugTrap => '1',
      isInterrupt => '0'
    ),
    RVEX_TRAP_SOFT_DEBUG_2 => (
      name => "trap %c: software debug trap 2@, address/PC %x    ",
      isDebugTrap => '1',
      isInterrupt => '0'
    ),
    RVEX_TRAP_STEP_COMPLETE => (
      name => "trap %c: step complete trap@, address/PC %x       ",
      isDebugTrap => '1',
      isInterrupt => '0'
    ),
    RVEX_TRAP_HW_BREAKPOINT_0 => (
      name => "trap %c: hardware breakpoint 0@, address/PC %x    ",
      isDebugTrap => '1',
      isInterrupt => '0'
    ),
    RVEX_TRAP_HW_BREAKPOINT_1 => (
      name => "trap %c: hardware breakpoint 1@, address/PC %x    ",
      isDebugTrap => '1',
      isInterrupt => '0'
    ),
    RVEX_TRAP_HW_BREAKPOINT_2 => (
      name => "trap %c: hardware breakpoint 2@, address/PC %x    ",
      isDebugTrap => '1',
      isInterrupt => '0'
    ),
    RVEX_TRAP_HW_BREAKPOINT_3 => (
      name => "trap %c: hardware breakpoint 3@, address/PC %x    ",
      isDebugTrap => '1',
      isInterrupt => '0'
    ),
    
    -- All other traps are unknown, but are handled appropriately.
    others => (
      name => "trap %c@ (unknown)                                ",
      isDebugTrap => '0',
      isInterrupt => '0'
    )
  );
  
  -- Shorthand for extracting the isDebugTrap signal from an (encoded)
  -- trap_info_type record.
  function rvex_isDebugTrap(t: trap_info_type) return std_logic;
  
  -- Shorthand for extracting the isInterrupt signal from an (encoded)
  -- trap_info_type record.
  function rvex_isInterruptTrap(t: trap_info_type) return std_logic;
  
  -- Returns '1' only when the trap cause is set to RVEX_TRAP_STOP.
  function rvex_isStopTrap(t: trap_info_type) return std_logic;
  
end core_trap_pkg;

--=============================================================================
package body core_trap_pkg is
--=============================================================================

  -- Merges two trap info records together, giving priority to the first
  -- operand.
  function "&"(l: trap_info_type; r: trap_info_type) return trap_info_type is
  begin
    if l.active = '1' then
      return l;
    else
      return r;
    end if;
  end "&";
  
  -- Shorthand for converting a natural trap ID to an rvex_trap_type.
  function rvex_trap(t: natural) return rvex_trap_type is
  begin
    return uint2vect(t, RVEX_TRAP_CAUSE_SIZE);
  end rvex_trap;
  
  -- Shorthand for extracting the isDebugTrap signal from an (encoded)
  -- trap_info_type record.
  function rvex_isDebugTrap(t: trap_info_type) return std_logic is
  begin
    return TRAP_TABLE(vect2uint(t.cause)).isDebugTrap;
  end rvex_isDebugTrap;
  
  -- Shorthand for extracting the isInterrupt signal from an (encoded)
  -- trap_info_type record.
  function rvex_isInterruptTrap(t: trap_info_type) return std_logic is
  begin
    return TRAP_TABLE(vect2uint(t.cause)).isInterrupt;
  end rvex_isInterruptTrap;
  
  -- Returns '1' only when the trap cause is set to RVEX_TRAP_STOP.
  function rvex_isStopTrap(t: trap_info_type) return std_logic is
  begin
    if vect2uint(t.cause) = RVEX_TRAP_STOP then
      return '1';
    else
      return '0';
    end if;
  end rvex_isStopTrap;
  
end core_trap_pkg;
