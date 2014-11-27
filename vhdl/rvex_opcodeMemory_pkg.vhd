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
use work.rvex_intIface_pkg.all;

--=============================================================================
-- This package specifies the control signal encoding for the memory unit.
-------------------------------------------------------------------------------
package rvex_opcodeMemory_pkg is
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- Memory unit control signals
  -----------------------------------------------------------------------------
  type memoryCtrlSignals_type is record
    
    -- When this instruction is executed on a lane without a memory unit, an
    -- invalid instruction exception will be raised.
    isMemoryInstruction         : std_logic;
    
    -- This is high when this is a memory read instruction.
    readEnable                  : std_logic;
    
    -- This is high when this is a memory write instruction.
    writeEnable                 : std_logic;
    
    -- When high, sub-word reads are zero extended instead of sign extended.
    unsignedOp                  : std_logic;
    
    -- Access size: 00 for byte, 01 for halfword, 10 for word. 11 is reserved.
    accessSizeBLog2             : std_logic_vector(1 downto 0);
    
  end record;
  
  -- Access size definitions.
  constant ACCESS_SIZE_BYTE     : std_logic_vector(1 downto 0) := "00";
  constant ACCESS_SIZE_HALFWORD : std_logic_vector(1 downto 0) := "01";
  constant ACCESS_SIZE_WORD     : std_logic_vector(1 downto 0) := "10";
  
  -- Array type.
  type memoryCtrlSignals_array is array (natural range <>) of memoryCtrlSignals_type;
  
  --===========================================================================
  -- Control signal specifications
  --===========================================================================
  
  -- Non-memory instruction.
  constant MEMORY_CTRL_NOP      : memoryCtrlSignals_type := (
    accessSizeBLog2             => ACCESS_SIZE_WORD,
    others                      => '0'
  );
  
  -----------------------------------------------------------------------------
  -- Read instructions
  -----------------------------------------------------------------------------
  -- 32-bit read.
  constant MEMORY_CTRL_LOAD32   : memoryCtrlSignals_type := (
    isMemoryInstruction         => '1',
    readEnable                  => '1',
    accessSizeBLog2             => ACCESS_SIZE_WORD,
    others                      => '0'
  );
  
  -- 16-bit signed read.
  constant MEMORY_CTRL_LOAD16S  : memoryCtrlSignals_type := (
    isMemoryInstruction         => '1',
    readEnable                  => '1',
    accessSizeBLog2             => ACCESS_SIZE_HALFWORD,
    others                      => '0'
  );
  
  -- 16-bit unsigned read.
  constant MEMORY_CTRL_LOAD16U  : memoryCtrlSignals_type := (
    isMemoryInstruction         => '1',
    readEnable                  => '1',
    unsignedOp                  => '1',
    accessSizeBLog2             => ACCESS_SIZE_HALFWORD,
    others                      => '0'
  );
  
  -- 8-bit signed read.
  constant MEMORY_CTRL_LOAD8S   : memoryCtrlSignals_type := (
    isMemoryInstruction         => '1',
    readEnable                  => '1',
    accessSizeBLog2             => ACCESS_SIZE_BYTE,
    others                      => '0'
  );
  
  -- 8-bit unsigned read.
  constant MEMORY_CTRL_LOAD8U   : memoryCtrlSignals_type := (
    isMemoryInstruction         => '1',
    readEnable                  => '1',
    unsignedOp                  => '1',
    accessSizeBLog2             => ACCESS_SIZE_BYTE,
    others                      => '0'
  );
  
  -----------------------------------------------------------------------------
  -- Write instructions
  -----------------------------------------------------------------------------
  -- 32-bit read.
  constant MEMORY_CTRL_STORE32  : memoryCtrlSignals_type := (
    isMemoryInstruction         => '1',
    writeEnable                 => '1',
    accessSizeBLog2             => ACCESS_SIZE_WORD,
    others                      => '0'
  );
  
  -- 16-bit read.
  constant MEMORY_CTRL_STORE16  : memoryCtrlSignals_type := (
    isMemoryInstruction         => '1',
    writeEnable                 => '1',
    accessSizeBLog2             => ACCESS_SIZE_HALFWORD,
    others                      => '0'
  );
  
  -- 8-bit read.
  constant MEMORY_CTRL_STORE8   : memoryCtrlSignals_type := (
    isMemoryInstruction         => '1',
    writeEnable                 => '1',
    accessSizeBLog2             => ACCESS_SIZE_BYTE,
    others                      => '0'
  );
  
end rvex_opcodeMemory_pkg;

package body rvex_opcodeMemory_pkg is
end rvex_opcodeMemory_pkg;
