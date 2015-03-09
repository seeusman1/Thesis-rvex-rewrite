-- r-VEX processor
-- Copyright (C) 2008-2015 by TU Delft.
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

-- Copyright (C) 2008-2015 by TU Delft.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library rvex;
use rvex.common_pkg.all;

--=============================================================================
-- This package contains constants specifying the word addresses of the control
-- registers as accessed from the debug bus or by a memory unit. It also
-- contains methods which generate register logic for several different kinds
-- of registers.
-------------------------------------------------------------------------------
package core_ctrlRegs_pkg is
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- Control register geometry
  -----------------------------------------------------------------------------
  -- The control register memory map is coarsely hardcoded in core_ctrlRegs.vhd
  -- as follows.
  --                                    | Core  | Debug |
  --         ___________________________|_______|_______|
  --  0x3FF | Context registers         |  R/W  |  R/W  |
  --  0x200 |___________________________|_______|_______|
  --  0x1FF | General purpose registers |   -   |  R/W  |
  --  0x100 |___________________________|_______|_______|
  --  0x0FF | Global registers          |   R   |  R/W  |
  --  0x000 |___________________________|_______|_______|
  --
  -- There are two ways to access these registers. The first is from the core
  -- itself, by making memory accesses to a contiguous region of memory mapped
  -- to the registers. The region is 1kiB in size and must be aligned to 1kiB
  -- boundaries; other than that, the location is specified by cregStartAddress
  -- in CFG. The second method is the debug bus. Because there is no context
  -- associated with the debug bus, bits 12..10 of the address are used to
  -- specify it. The global registers are mirrored for each context. For each
  -- access method, the access level is specified in the table above.
  --
  -- The core can only access registers belonging to the context it is
  -- currently running internally. If cross-context access is needed, the
  -- memory bus of the rvex must be connected to the debug bus externally.
  --
  -- NOTE: the constants below should reflect the map specified above (or more
  -- importantly, what's specified in core_ctrlRegs.vhd). They cannot be
  -- changed unless otherwise specified.
  
  -- Size of the control register file accessible from the core through data
  -- memory operations.
  constant CRG_SIZE_BLOG2       : natural := 10;
  
  -- Total number of words in the control register file.
  constant CRG_SIZE_WORDS       : natural := 2**(CRG_SIZE_BLOG2-2);
  
  -- Word offset and count for the global portion of the control register file.
  -- The specified range must be identical to or a subset of 0..63 inclusive,
  -- but may be changed otherwise.
  constant CRG_GLOB_WORD_OFFSET : natural := 0;
  constant CRG_GLOB_WORD_COUNT  : natural := 5;
  
  -- Word offset and count for the context-specific portion of the control
  -- register file. The specified range must be identical to or a subset of
  -- 128..255 inclusive, but may be changed otherwise.
  constant CRG_CTXT_WORD_OFFSET : natural := 128;
  constant CRG_CTXT_WORD_COUNT  : natural := 24;
  
  -----------------------------------------------------------------------------
  -- Control register map specification
  -----------------------------------------------------------------------------
  -- NOTE: these constants can be used in the core_tb.vhd test case when
  -- properly loaded there. If you add or remove a constant here, add them to
  -- core_tb.vhd as well! Registry is done at the end of the file; just search
  -- for one of the constant names if you can't find it.
  
  -- NOTE: make sure you make room first if you want to add registers. You can
  -- change the sizes of the register files within hardcoded limits by changing
  -- the constants in the previous section.
  
  -- Global (shared) register word addresses. Refer to
  -- rvex_globalRegLogic.vhd for documentation about the registers.
  constant CR_GSR     : natural := CRG_GLOB_WORD_OFFSET +  0; -- Global status register.
  constant CR_BCRR    : natural := CRG_GLOB_WORD_OFFSET +  1; -- Bus configuration request register.
  constant CR_CC      : natural := CRG_GLOB_WORD_OFFSET +  2; -- Current configuration register.
  constant CR_AFF     : natural := CRG_GLOB_WORD_OFFSET +  3; -- Cache/memory block affinity register.
  constant CR_CNT     : natural := CRG_GLOB_WORD_OFFSET +  4; -- CPU cycle counter.
  
  -- Context-specific register word addresses. Refer to
  -- rvex_contextRegLogic.vhd for documentation about the registers.
  constant CR_CCR     : natural := CRG_CTXT_WORD_OFFSET +  0; -- Context control register.
  constant CR_SCCR    : natural := CRG_CTXT_WORD_OFFSET +  1; -- Saved context control register.
  constant CR_LR      : natural := CRG_CTXT_WORD_OFFSET +  2; -- Link register.
  constant CR_PC      : natural := CRG_CTXT_WORD_OFFSET +  3; -- PC register.
  constant CR_TH      : natural := CRG_CTXT_WORD_OFFSET +  4; -- Trap handler register.
  constant CR_PH      : natural := CRG_CTXT_WORD_OFFSET +  5; -- Panic handler register.
  constant CR_TP      : natural := CRG_CTXT_WORD_OFFSET +  6; -- Trap point/return register.
  constant CR_TA      : natural := CRG_CTXT_WORD_OFFSET +  7; -- Trap argument register.
  constant CR_BRK0    : natural := CRG_CTXT_WORD_OFFSET +  8; -- Breakpoint 0 register.
  constant CR_BRK1    : natural := CR_BRK0 + 1;               -- Breakpoint 1 register.
  constant CR_BRK2    : natural := CR_BRK0 + 2;               -- Breakpoint 2 register.
  constant CR_BRK3    : natural := CR_BRK0 + 3;               -- Breakpoint 3 register.
  constant CR_DCR     : natural := CRG_CTXT_WORD_OFFSET + 12; -- Debug control register 1.
  constant CR_DCR2    : natural := CRG_CTXT_WORD_OFFSET + 13; -- Debug control register 2.
  constant CR_CRR     : natural := CRG_CTXT_WORD_OFFSET + 14; -- Configuration request register.
  constant CR_C_CYC   : natural := CRG_CTXT_WORD_OFFSET + 15; -- Non-idle cycle counter.
  constant CR_C_STALL : natural := CRG_CTXT_WORD_OFFSET + 16; -- Non-idle stall counter.
  constant CR_C_BUN   : natural := CRG_CTXT_WORD_OFFSET + 17; -- Committed bundle counter.
  constant CR_C_SYL   : natural := CRG_CTXT_WORD_OFFSET + 18; -- Committed syllable counter.
  constant CR_C_NOP   : natural := CRG_CTXT_WORD_OFFSET + 19; -- Committed NOP counter.
  constant CR_SCRP    : natural := CRG_CTXT_WORD_OFFSET + 20; -- Scratch-pad register 1.
  constant CR_SCRP2   : natural := CRG_CTXT_WORD_OFFSET + 21; -- Scratch-pad register 2.
  constant CR_SCRP3   : natural := CRG_CTXT_WORD_OFFSET + 22; -- Scratch-pad register 3.
  constant CR_SCRP4   : natural := CRG_CTXT_WORD_OFFSET + 23; -- Scratch-pad register 4.
  
  -- Byte addresses for byte-aligned fields.
  constant CR_TC      : natural := 4*CR_CCR   + 0; -- Trap cause.
  constant CR_BR      : natural := 4*CR_CCR   + 1; -- Branch register file.
  constant CR_CID     : natural := 4*CR_SCCR  + 0; -- Context ID.
  constant CR_DCRF    : natural := 4*CR_DCR   + 0; -- Debug control flags.
  constant CR_DCRC    : natural := 4*CR_DCR   + 1; -- Debug breakpoint cause.
  constant CR_RET     : natural := 4*CR_DCR2  + 0; -- main() return value.
  
  -- Bit indices for CCR.
  constant CR_CCR_IEN         : natural := 0; -- Interrupt enable.
  constant CR_CCR_IEN_C       : natural := 1; -- Interrupt disable.
  constant CR_CCR_RFT         : natural := 2; -- Ready for trap.
  constant CR_CCR_RFT_C       : natural := 3; -- Not ready for trap.
  constant CR_CCR_BPE         : natural := 4; -- Breakpoint enable.
  constant CR_CCR_BPE_C       : natural := 5; -- Breakpoint disable.
  
  -- Bit indices for DCR.
  constant CR_DCR_BREAK       : natural := 24; -- Break flag.
  constant CR_DCR_STEP        : natural := 25; -- Step flag.
  constant CR_DCR_RESUME      : natural := 26; -- Resume flag.
  constant CR_DCR_EXT_DBG     : natural := 27; -- External debug flag.
  constant CR_DCR_INT_DBG     : natural := 28; -- Internal debug flag.
  constant CR_DCR_JUMP        : natural := 30; -- Jump flag (after bus write to PC).
  constant CR_DCR_DONE        : natural := 31; -- Done flag and (when writing) reset bit.
  
  -- Bit indices for DCR2.
  constant CR_DCR2_TR_ENA     : natural := 0; -- Trace unit enable flag.
  constant CR_DCR2_TR_INSTR   : natural := 3; -- Trace fetched instructions.
  constant CR_DCR2_TR_CACHE   : natural := 4; -- Trace cache performance information.
  constant CR_DCR2_TR_REG     : natural := 5; -- Trace register writes.
  constant CR_DCR2_TR_MEM     : natural := 6; -- Trace memory accesses.
  constant CR_DCR2_TR_TRAP    : natural := 7; -- Trace trap information.
  
  -- DCR flag command codes (byte-write these to CR_DCRC).
  constant CR_DCRC_DBG_EXT    : natural := 16#08#; -- Enter external debug mode.
  constant CR_DCRC_BREAK      : natural := 16#09#; -- Break; stop execution.
  constant CR_DCRC_STEP       : natural := 16#0A#; -- Step one instruction. Can also be used to stop the core.
  constant CR_DCRC_RESUME     : natural := 16#0C#; -- Resume/continue execution.
  constant CR_DCRC_DBG_INT    : natural := 16#10#; -- Transfer debugging control back to the core.
  constant CR_DCRC_RESET      : natural := 16#80#; -- Restart the context.
  constant CR_DCRC_RESET_DBG  : natural := 16#88#; -- Restart the context in external debug mode.
  constant CR_DCRC_RESET_BREAK: natural := 16#89#; -- Restart the context in external debug mode and break.
  
  -----------------------------------------------------------------------------
  -- Interface between (generic) control register code and logic
  -----------------------------------------------------------------------------
  -- This record contains all the signals going to the generic control register
  -- hardware, defining what the final instantiated register will look like.
  type logic2creg_type is record
    
    -- Combinatorial register override. While overrideEnable is high, bus reads
    -- and the hardware readData signals will always return overrideData. Note
    -- that this can be used to remove a register by tying overrideEnable to
    -- vcc; the optimizer will then remove the register because its output is
    -- unused.
    overrideEnable              : rvex_data_type;
    overrideData                : rvex_data_type;
    
    -- Hardware write access to the register. This always takes precedence over
    -- bus accesses.
    writeEnable                 : rvex_data_type;
    writeData                   : rvex_data_type;
    
    -- Write permissions for the debug bus and the core. When low, writes will
    -- have no effect on the register value.
    dbgBusCanWrite              : rvex_data_type;
    coreCanWrite                : rvex_data_type;
    
    -- Reset value for the register.
    resetValue                  : rvex_data_type;
    
  end record;
  
  -- This record contains all the signals going from a generic control register
  -- to the register logic.
  type creg2logic_type is record
    
    -- Current data as it would be read by the bus.
    readData                    : rvex_data_type;
    
    -- Current data in the register, ignoring combinatorial override.
    readDataRaw                 : rvex_data_type;
    
    -- High when a bus attempts to read the register.
    busRead                     : std_logic;
    
    -- High when a bus attempts to write to the register and has permission to
    -- do so.
    busWrite                    : rvex_data_type;
    
    -- The data which the bus is writing when busWrite is high.
    busWriteData                : rvex_data_type;
    
  end record;
  
  -- Default value for logic2creg_type. This overrides the output of the
  -- register to 0 to completely optimize it away.
  constant HW2REG_DEFAULT       : logic2creg_type := (
    overrideEnable              => (others => '1'),
    overrideData                => (others => '0'),
    writeEnable                 => (others => '0'),
    writeData                   => (others => '0'),
    dbgBusCanWrite              => (others => '0'),
    coreCanWrite                => (others => '0'),
    resetValue                  => (others => '0')
  );
  
  -- Array types for the above.
  type logic2creg_array is array (natural range <>) of logic2creg_type;
  type creg2logic_array is array (natural range <>) of creg2logic_type;
  
  -- Constrained array types for the above for the global and context-specific
  -- parts of the control registers.
  subtype gbreg2creg_type is logic2creg_array(CRG_GLOB_WORD_OFFSET to CRG_GLOB_WORD_OFFSET+CRG_GLOB_WORD_COUNT-1);
  subtype creg2gbreg_type is creg2logic_array(CRG_GLOB_WORD_OFFSET to CRG_GLOB_WORD_OFFSET+CRG_GLOB_WORD_COUNT-1);
  subtype cxreg2creg_type is logic2creg_array(CRG_CTXT_WORD_OFFSET to CRG_CTXT_WORD_OFFSET+CRG_CTXT_WORD_COUNT-1);
  subtype creg2cxreg_type is creg2logic_array(CRG_CTXT_WORD_OFFSET to CRG_CTXT_WORD_OFFSET+CRG_CTXT_WORD_COUNT-1);
  
  -- Array types for the control register access records.
  type cxreg2creg_array is array (natural range <>) of cxreg2creg_type;
  type creg2cxreg_array is array (natural range <>) of creg2cxreg_type;
  
  -----------------------------------------------------------------------------
  -- Control register procedural generation
  -----------------------------------------------------------------------------
  -- Permission type for a register.
  type creg_perm_type is (
    READ_ONLY,       -- The register can only be written by hardware.
    READ_WRITE,      -- The register is completely read/write.
    DEBUG_CAN_WRITE, -- Only the debug bus can write to the register.
    CORE_CAN_WRITE   -- Only the memory unit can write to the register.
  );
  
  -- Sets the permissions on a range of bits in a register.
  procedure creg_setPermissions(
    l2c           : inout logic2creg_array;
    c2l           : inout creg2logic_array;
    wordAddr      : in    natural;          -- Word address of the register.
    highBit       : in    natural := 31;    -- High bit index of the range to affect.
    lowBit        : in    natural := 0;     -- Low bit index of the range to affect.
    permissions   : in    creg_perm_type    -- Bus/processor permissions.
  );
  
  -- Generates a regular register which can be written by hardware and
  -- optionally by the processor through store operations and/or the debug bus.
  procedure creg_makeNormalRegister(
    l2c           : inout logic2creg_array;
    c2l           : inout creg2logic_array;
    wordAddr      : in    natural;          -- Word address of the register.
    highBit       : in    natural := 31;    -- High bit index of the register.
    lowBit        : in    natural := 0;     -- Low bit index of the register.
    resetState    : in    std_logic_vector := ""; -- Reset state for the register.
    writeEnable   : in    std_logic := '0'; -- Write enable bit for hardware writes.
    writeData     : in    std_logic_vector := ""; -- Write data for hardware writes.
    permissions   : in    creg_perm_type    -- Bus/processor permissions.
  );
  
  -- Generates a counter register. The counter reg can be cleared by writing to
  -- it, or using the clear input. The counter will stay at max value rather
  -- than overflowing so overflows can be detected.
  procedure creg_makeCounter(
    l2c           : inout logic2creg_array;
    c2l           : inout creg2logic_array;
    wordAddr      : in    natural;          -- Word address of the register.
    highBit       : in    natural := 31;    -- High bit index of the counter.
    lowBit        : in    natural := 0;     -- Low bit index of the counter.
    clear         : in    std_logic := '0'; -- External clear input.
    inc           : in    std_logic := '0'; -- Single increment bit.
    inc_vect      : in    std_logic_vector := ""; -- Additional increment bits in vector form.
    enable        : in    std_logic := '1'; -- Increment enable bit.
    clamp         : in    boolean := true;  -- Overflow behavior: clamp or modulo.
    permissions   : in    creg_perm_type := READ_WRITE -- Bus/processor permissions (to clear register).
  );
  
  -- Hardwires the specified range to a certain value.
  procedure creg_makeHardwiredField(
    l2c           : inout logic2creg_array;
    c2l           : inout creg2logic_array;
    wordAddr      : in    natural;          -- Word address of the field.
    highBit       : in    natural := 31;    -- High bit index of the field.
    lowBit        : in    natural := 0;     -- Low bit index of the field.
    value         : in    std_logic_vector  -- Value to hardwire the field to.
  );
  
  -- Generates a flag register which can be atomically set, cleared, toggled or
  -- ignored in a single write operation, utilizing 2 bits. The set bit returns
  -- the current state of the flag when read, the clear bit returns the
  -- inverted state. Setting and clearing works by writing the desired states
  -- to the two bits. A no-op write can be done by writing two zeros, and the
  -- flag can be toggled by writing two ones.
  procedure creg_makeSetClearFlag(
    l2c           : inout logic2creg_array;
    c2l           : inout creg2logic_array;
    wordAddr      : in    natural;          -- Word address of the register.
    setBit        : in    natural;          -- Bit index for the set bit.
    clearBit      : in    natural;          -- Bit index for the clear bit.
    resetState    : in    std_logic;        -- Reset state for the set bit.
    set           : in    std_logic := '0'; -- When high, the flag will be set by hardware.
    clear         : in    std_logic := '0'; -- When high, the flag will be cleared by hardware.
    permissions   : in    creg_perm_type    -- Permissions.
  );
  
  -- Generates a flag status register which can only be modified by hardware,
  -- but only uses a single bit in a register.
  procedure creg_makeHardwareFlag(
    l2c           : inout logic2creg_array;
    c2l           : inout creg2logic_array;
    wordAddr      : in    natural;          -- Word address of the register.
    bitIndex      : in    natural;          -- Bit index for the flag.
    resetState    : in    std_logic;        -- Reset state for the flag.
    set           : in    std_logic := '0'; -- When high, the flag will be set by hardware.
    clear         : in    std_logic := '0'; -- When high, the flag will be cleared by hardware.
    permissions   : in    creg_perm_type := READ_ONLY -- Permissions, in case creg_isWritingOneToBit is used later.
  );
  
  -- Generates save/restore logic between two registers. When a "save"
  -- condition occurs, the contents of the active register are copied to the
  -- saved register; when a "restore" condition occurs, the reverse happens.
  procedure creg_makeSaveRestoreLogic(
    l2c           : inout logic2creg_array;
    c2l           : inout creg2logic_array;
    curWordAddr   : in    natural;          -- Word address of the functional register.
    savedWordAddr : in    natural;          -- Word address of the saved register state.
    highBit       : in    natural := 31;    -- High bit index of the range which is saved/restored.
    lowBit        : in    natural := 0;     -- Low bit index of the range which is saved/restored.
    save          : in    std_logic;        -- When high, the contents of cur will be written to saved.
    restore       : in    std_logic         -- When high, the contents of saved will be written to cur.
  );
  
  -- Writes the specified value to the specified register.
  procedure creg_writeRegisterVect(
    l2c           : inout logic2creg_array;
    c2l           : inout creg2logic_array;
    wordAddr      : in    natural;          -- Word address of the register.
    highBit       : in    natural := 31;    -- High bit index of the range to read.
    lowBit        : in    natural := 0;     -- Low bit index of the range to read.
    value         : in    std_logic_vector
  );
  
  -- Returns the current state of a register.
  function creg_readRegisterVect(
    l2c           : in    logic2creg_array;
    c2l           : in    creg2logic_array;
    wordAddr      : in    natural;          -- Word address of the register.
    highBit       : in    natural := 31;    -- High bit index of the range to read.
    lowBit        : in    natural := 0      -- Low bit index of the range to read.
  ) return std_logic_vector;
  
  -- Returns the current state of a single bit in a register.
  function creg_readRegisterBit(
    l2c           : in    logic2creg_array;
    c2l           : in    creg2logic_array;
    wordAddr      : in    natural;          -- Word address of the register.
    bitIndex      : in    natural           -- Bit index of the bit to read.
  ) return std_logic;
  
  -- Returns true if the bus is writing to the selected bit in the selected
  -- word.
  function creg_isBusWritingToBit(
    l2c           : in    logic2creg_array;
    c2l           : in    creg2logic_array;
    wordAddr      : in    natural;          -- Word address of the register.
    bitIndex      : in    natural           -- Bit index of the bit to read.
  ) return std_logic;
  
  -- Returns true if the bus or any hardware before this call is writing a one
  -- to the selected bit in the selected word.
  function creg_isBusWritingOneToBit(
    l2c           : in    logic2creg_array;
    c2l           : in    creg2logic_array;
    wordAddr      : in    natural;          -- Word address of the register.
    bitIndex      : in    natural           -- Bit index of the bit to read.
  ) return std_logic;
  
end core_ctrlRegs_pkg;

--=============================================================================
package body core_ctrlRegs_pkg is
--=============================================================================
  
  -- Sets the permissions on a range of bits in a register.
  procedure creg_setPermissions(
    l2c           : inout logic2creg_array;
    c2l           : inout creg2logic_array;
    wordAddr      : in    natural;          -- Word address of the register.
    highBit       : in    natural := 31;    -- High bit index of the range to affect.
    lowBit        : in    natural := 0;     -- Low bit index of the range to affect.
    permissions   : in    creg_perm_type    -- Bus/processor permissions.
  ) is
  begin
    case permissions is
      
      when READ_ONLY =>
        l2c(wordAddr).dbgBusCanWrite(highBit downto lowBit) := (others => '0');
        l2c(wordAddr).coreCanWrite(highBit downto lowBit) := (others => '0');
        
      when READ_WRITE =>
        l2c(wordAddr).dbgBusCanWrite(highBit downto lowBit) := (others => '1');
        l2c(wordAddr).coreCanWrite(highBit downto lowBit) := (others => '1');
        
      when DEBUG_CAN_WRITE =>
        l2c(wordAddr).dbgBusCanWrite(highBit downto lowBit) := (others => '1');
        l2c(wordAddr).coreCanWrite(highBit downto lowBit) := (others => '0');
        
      when CORE_CAN_WRITE =>
        l2c(wordAddr).dbgBusCanWrite(highBit downto lowBit) := (others => '0');
        l2c(wordAddr).coreCanWrite(highBit downto lowBit) := (others => '1');
        
    end case;
  end creg_setPermissions;
  
  -- Generates a regular register which can be written by hardware and
  -- optionally by the processor through store operations and/or the debug bus.
  procedure creg_makeNormalRegister(
    l2c           : inout logic2creg_array;
    c2l           : inout creg2logic_array;
    wordAddr      : in    natural;          -- Word address of the register.
    highBit       : in    natural := 31;    -- High bit index of the range which is saved/restored.
    lowBit        : in    natural := 0;     -- Low bit index of the range which is saved/restored.
    resetState    : in    std_logic_vector := ""; -- Reset state for the register.
    writeEnable   : in    std_logic := '0'; -- Write enable bit for hardware writes.
    writeData     : in    std_logic_vector := ""; -- Write data for hardware writes.
    permissions   : in    creg_perm_type    -- Bus/processor permissions.
  ) is
  begin
    l2c(wordAddr).overrideEnable(highBit downto lowBit) := (others => '0');
    if writeData /= "" then
      l2c(wordAddr).writeEnable(highBit downto lowBit) := (others => writeEnable);
      l2c(wordAddr).writeData(highBit downto lowBit) := writeData;
    end if;
    if resetState /= "" then
      l2c(wordAddr).resetValue(highBit downto lowBit) := resetState;
    end if;
    creg_setPermissions(l2c, c2l, wordAddr, highBit, lowBit, permissions);
  end creg_makeNormalRegister;
  
  -- Generates a counter register. The counter reg can be cleared by writing to
  -- it, or using the clear input. The counter will stay at max value rather
  -- than overflowing so overflows can be detected.
  procedure creg_makeCounter(
    l2c           : inout logic2creg_array;
    c2l           : inout creg2logic_array;
    wordAddr      : in    natural;          -- Word address of the register.
    highBit       : in    natural := 31;    -- High bit index of the counter.
    lowBit        : in    natural := 0;     -- Low bit index of the counter.
    clear         : in    std_logic := '0'; -- External clear input.
    inc           : in    std_logic := '0'; -- Single increment bit.
    inc_vect      : in    std_logic_vector := ""; -- Additional increment bits in vector form.
    enable        : in    std_logic := '1'; -- Increment enable bit.
    clamp         : in    boolean := true;  -- Overflow behavior: clamp or modulo.
    permissions   : in    creg_perm_type := READ_WRITE -- Bus/processor permissions (to clear register).
  ) is
    constant zero     : std_logic_vector(highBit downto lowBit) := (others => '0');
    variable count    : unsigned(highBit-lowBit+1 downto 0);
    variable add      : unsigned(highBit-lowBit+1 downto 0);
    variable inc_int  : std_logic_vector(inc_vect'length downto 0);
    variable ena      : std_logic;
  begin
    
    -- Make a normal register to begin with.
    creg_makeNormalRegister(l2c, c2l, wordAddr, highBit, lowBit,
      permissions => permissions
    );
    
    -- Update enable signal.
    ena := enable;
    
    -- Determine how much we need to add to the counter.
    add := (0 => inc, others => '0');
    for i in inc_vect'range loop
      if inc_vect(i) = '1' then
        add := add + to_unsigned(1, highBit-lowBit);
      end if;
    end loop;
    
    -- Read the current counter value and perform the addition.
    count := "0" & unsigned(c2l(wordAddr).readData(highBit downto lowBit));
    count := count + add;
    
    -- If there is an overflow and we're configured in clamp mode, overwrite
    -- the value to write with all ones.
    if clamp and count(highBit-lowBit+1) = '1' then
      count(highBit-lowBit downto 0) := (others => '1');
    end if;
    
    -- Handle counter clearing.
    if (c2l(wordAddr).busWrite(highBit downto lowBit) /= zero) or (clear = '1') then
      count(highBit-lowBit downto 0) := (others => '0');
      ena := '1';
    end if;
    
    -- Write the new counter value.
    l2c(wordAddr).writeEnable(highBit downto lowBit) := (others => ena);
    l2c(wordAddr).writeData(highBit downto lowBit) := std_logic_vector(count(highBit-lowBit downto 0));
    
  end creg_makeCounter;
  
  -- Hardwires the specified range to a certain value.
  procedure creg_makeHardwiredField(
    l2c           : inout logic2creg_array;
    c2l           : inout creg2logic_array;
    wordAddr      : in    natural;          -- Word address of the field.
    highBit       : in    natural := 31;    -- High bit index of the field.
    lowBit        : in    natural := 0;     -- Low bit index of the field.
    value         : in    std_logic_vector  -- Value to hardwire the field to.
  ) is
  begin
    l2c(wordAddr).overrideEnable(highBit downto lowBit) := (others => '1');
    l2c(wordAddr).overrideData(highBit downto lowBit) := value;
  end creg_makeHardwiredField;
  
  -- Generates a flag register which can be atomically set, cleared, toggled or
  -- ignored in a single write operation, utilizing 2 bits. The set bit returns
  -- the current state of the flag when read, the clear bit returns the
  -- inverted state. Setting and clearing works by writing the desired states
  -- to the two bits. A no-op write can be done by writing two zeros, and the
  -- flag can be toggled by writing two ones.
  procedure creg_makeSetClearFlag(
    l2c           : inout logic2creg_array;
    c2l           : inout creg2logic_array;
    wordAddr      : in    natural;          -- Word address of the register.
    setBit        : in    natural;          -- Bit index for the set bit.
    clearBit      : in    natural;          -- Bit index for the clear bit.
    resetState    : in    std_logic;        -- Reset state for the set bit.
    set           : in    std_logic := '0'; -- When high, the flag will be set by hardware.
    clear         : in    std_logic := '0'; -- When high, the flag will be cleared by hardware.
    permissions   : in    creg_perm_type    -- Permissions.
  ) is
  begin
    
    -- Override the clear bit output to the complement of the set bit state.
    l2c(wordAddr).overrideEnable(clearBit) := '1';
    l2c(wordAddr).overrideData(clearBit) := not c2l(wordAddr).readData(setBit);
    
    -- Disable override for the set bit.
    l2c(wordAddr).overrideEnable(setBit) := '0';
    
    -- Override bus writes with the proper action taken on the flag.
    if c2l(wordAddr).busWrite(setBit) = '1' or c2l(wordAddr).busWrite(clearBit) = '1' then
      if c2l(wordAddr).busWrite(setBit) = '1' and c2l(wordAddr).busWriteData(setBit) = '1' then
        if c2l(wordAddr).busWrite(clearBit) = '1' and c2l(wordAddr).busWriteData(clearBit) = '1' then
          
          -- Both bits written 1, toggle.
          l2c(wordAddr).writeEnable(setBit) := '1';
          l2c(wordAddr).writeData(setBit) := not c2l(wordAddr).readData(setBit);
          
        else
          
          -- Set bit written 1, set flag.
          l2c(wordAddr).writeEnable(setBit) := '1';
          l2c(wordAddr).writeData(setBit) := '1';
          
        end if;
      else
        if c2l(wordAddr).busWrite(clearBit) = '1' and c2l(wordAddr).busWriteData(clearBit) = '1' then
          
          -- Clear bit written 1, clear flag.
          l2c(wordAddr).writeEnable(setBit) := '1';
          l2c(wordAddr).writeData(setBit) := '0';
          
        else
          
          -- No operation; but we still need to override the bus in order to
          -- not clear the flag.
          l2c(wordAddr).writeEnable(setBit) := '1';
          l2c(wordAddr).writeData(setBit) := c2l(wordAddr).readData(setBit);
          
        end if;
      end if;
    end if;
    
    -- Override the bus write when the hardware wants to set or clear the flag.
    if set = '1' then
      l2c(wordAddr).writeEnable(setBit) := '1';
      l2c(wordAddr).writeData(setBit) := '1';
    end if;
    if clear = '1' then
      l2c(wordAddr).writeEnable(setBit) := '1';
      l2c(wordAddr).writeData(setBit) := '0';
    end if;
    
    -- Set the right permissions on the bits.
    creg_setPermissions(l2c, c2l, wordAddr, setBit, setBit, permissions);
    creg_setPermissions(l2c, c2l, wordAddr, clearBit, clearBit, permissions);
    
  end creg_makeSetClearFlag;
  
  -- Generates a flag status register which can only be modified by hardware,
  -- but only uses a single bit in a register.
  procedure creg_makeHardwareFlag(
    l2c           : inout logic2creg_array;
    c2l           : inout creg2logic_array;
    wordAddr      : in    natural;          -- Word address of the register.
    bitIndex      : in    natural;          -- Bit index for the flag.
    resetState    : in    std_logic;        -- Reset state for the flag.
    set           : in    std_logic := '0'; -- When high, the flag will be set by hardware.
    clear         : in    std_logic := '0'; -- When high, the flag will be cleared by hardware.
    permissions   : in    creg_perm_type := READ_ONLY -- Permissions, in case creg_isWritingOneToBit is used later.
  ) is
  begin
    
    -- Disable override for the bit.
    l2c(wordAddr).overrideEnable(bitIndex) := '0';
    
    -- If the bus is trying to write to the flag, override it. By doing this
    -- we support any value write permissions, so we can still detect a write
    -- and do something manually.
    if c2l(wordAddr).busWrite(bitIndex) = '1' then
      l2c(wordAddr).writeEnable(bitIndex) := '1';
      l2c(wordAddr).writeData(bitIndex) := c2l(wordAddr).readData(bitIndex);
    end if;
    if set = '1' then
      l2c(wordAddr).writeEnable(bitIndex) := '1';
      l2c(wordAddr).writeData(bitIndex) := '1';
    end if;
    if clear = '1' then
      l2c(wordAddr).writeEnable(bitIndex) := '1';
      l2c(wordAddr).writeData(bitIndex) := '0';
    end if;
    
    -- Set bus permissions.
    creg_setPermissions(l2c, c2l, wordAddr, bitIndex, bitIndex, permissions);
    
  end creg_makeHardwareFlag;
  
  -- Generates save/restore logic between two registers. When a "save"
  -- condition occurs, the contents of the active register are copied to the
  -- saved register; when a "restore" condition occurs, the reverse happens.
  procedure creg_makeSaveRestoreLogic(
    l2c           : inout logic2creg_array;
    c2l           : inout creg2logic_array;
    curWordAddr   : in    natural;          -- Word address of the functional register.
    savedWordAddr : in    natural;          -- Word address of the saved register state.
    highBit       : in    natural := 31;    -- High bit index of the range which is saved/restored.
    lowBit        : in    natural := 0;     -- Low bit index of the range which is saved/restored.
    save          : in    std_logic;        -- When high, the contents of cur will be written to saved.
    restore       : in    std_logic         -- When high, the contents of saved will be written to cur.
  ) is
  begin
    if save = '1' then
      l2c(savedWordAddr).writeEnable(highBit downto lowBit) := (others => '1');
      l2c(savedWordAddr).writeData(highBit downto lowBit) := c2l(curWordAddr).readData(highBit downto lowBit);
    end if;
    if restore = '1' then
      l2c(curWordAddr).writeEnable(highBit downto lowBit) := (others => '1');
      l2c(curWordAddr).writeData(highBit downto lowBit) := c2l(savedWordAddr).readData(highBit downto lowBit);
    end if;
  end creg_makeSaveRestoreLogic;
  
  -- Writes the specified value to the specified register.
  procedure creg_writeRegisterVect(
    l2c           : inout logic2creg_array;
    c2l           : inout creg2logic_array;
    wordAddr      : in    natural;          -- Word address of the register.
    highBit       : in    natural := 31;    -- High bit index of the range to read.
    lowBit        : in    natural := 0;     -- Low bit index of the range to read.
    value         : in    std_logic_vector
  ) is
  begin
    l2c(wordAddr).writeEnable(highBit downto lowBit) := (others => '1');
    l2c(wordAddr).writeData(highBit downto lowBit) := value;
  end creg_writeRegisterVect;
  
  -- Returns the current state of a register.
  function creg_readRegisterVect(
    l2c           : in    logic2creg_array;
    c2l           : in    creg2logic_array;
    wordAddr      : in    natural;          -- Word address of the register.
    highBit       : in    natural := 31;    -- High bit index of the range to read.
    lowBit        : in    natural := 0      -- Low bit index of the range to read.
  ) return std_logic_vector is
  begin
    return c2l(wordAddr).readData(highBit downto lowBit);
  end creg_readRegisterVect;
  
  -- Returns the current state of a single bit in a register.
  function creg_readRegisterBit(
    l2c           : in    logic2creg_array;
    c2l           : in    creg2logic_array;
    wordAddr      : in    natural;          -- Word address of the register.
    bitIndex      : in    natural           -- Bit index of the bit to read.
  ) return std_logic is
  begin
    return c2l(wordAddr).readData(bitIndex);
  end creg_readRegisterBit;
  
  -- Returns true if the bus is writing to the selected bit in the selected
  -- word.
  function creg_isBusWritingToBit(
    l2c           : in    logic2creg_array;
    c2l           : in    creg2logic_array;
    wordAddr      : in    natural;          -- Word address of the register.
    bitIndex      : in    natural           -- Bit index of the bit to read.
  ) return std_logic is
    variable result : boolean;
  begin
    if c2l(wordAddr).busWrite(bitIndex) = '1' then
      return '1';
    else
      return '0';
    end if;
  end creg_isBusWritingToBit;
  
  -- Returns true if the bus is writing a one to the selected bit in the
  -- selected word.
  function creg_isBusWritingOneToBit(
    l2c           : in    logic2creg_array;
    c2l           : in    creg2logic_array;
    wordAddr      : in    natural;          -- Word address of the register.
    bitIndex      : in    natural           -- Bit index of the bit to read.
  ) return std_logic is
    variable result : boolean;
  begin
    if c2l(wordAddr).busWrite(bitIndex) = '1' and c2l(wordAddr).busWriteData(bitIndex) = '1' then
      return '1';
    else
      return '0';
    end if;
  end creg_isBusWritingOneToBit;
  
end core_ctrlRegs_pkg;
