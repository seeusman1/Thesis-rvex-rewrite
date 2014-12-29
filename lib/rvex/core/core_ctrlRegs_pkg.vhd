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
use rvex.core_intIface_pkg.all;

--=============================================================================
-- This package contains constants specifying the word addresses of the control
-- registers as accessed from the debug bus or by a memory unit. It also
-- contains methods which generate register logic for several different kinds
-- of registers.
-------------------------------------------------------------------------------
package core_ctrlRegs_pkg is
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- Control register map specification
  -----------------------------------------------------------------------------
  -- NOTE: these constants can be used in the rvex_tb.vhd test case when
  -- properly loaded there. If you add or remove a constant here, add them to
  -- rvex_tb.vhd as well! Registry is done at the end of the file; just search
  -- for one of the constant names if you can't find it.
  
  -- Global (shared) register word addresses. Refer to
  -- rvex_globalRegLogic.vhd for documentation about the registers.
  constant CR_GSR     : natural := 0; -- Global status register.
  constant CR_BCRR    : natural := 1; -- Bus configuration request register.
  constant CR_CC      : natural := 2; -- Current configuration register.
  constant CR_AFF     : natural := 3; -- Cache/memory block affinity register.
  
  -- Context-specific register word addresses. Refer to
  -- rvex_contextRegLogic.vhd for documentation about the registers.
  constant CR_CCR     : natural := CTRL_REG_GLOB_WORDS +  0; -- Context control register.
  constant CR_SCCR    : natural := CTRL_REG_GLOB_WORDS +  1; -- Saved context control register.
  constant CR_LR      : natural := CTRL_REG_GLOB_WORDS +  2; -- Link register.
  constant CR_PC      : natural := CTRL_REG_GLOB_WORDS +  3; -- PC register.
  constant CR_TH      : natural := CTRL_REG_GLOB_WORDS +  4; -- Trap handler register.
  constant CR_PH      : natural := CTRL_REG_GLOB_WORDS +  5; -- Panic handler register.
  constant CR_TP      : natural := CTRL_REG_GLOB_WORDS +  6; -- Trap point/return register.
  constant CR_TA      : natural := CTRL_REG_GLOB_WORDS +  7; -- Trap argument register.
  constant CR_BRK0    : natural := CTRL_REG_GLOB_WORDS +  8; -- Breakpoint 0 register.
  constant CR_BRK1    : natural := CR_BRK0 + 1;              -- Breakpoint 1 register.
  constant CR_BRK2    : natural := CR_BRK0 + 2;              -- Breakpoint 2 register.
  constant CR_BRK3    : natural := CR_BRK0 + 3;              -- Breakpoint 3 register.
  constant CR_DCR     : natural := CTRL_REG_GLOB_WORDS + 12; -- Debug control register.
  constant CR_CRR     : natural := CTRL_REG_GLOB_WORDS + 13; -- Configuration request register.
  
  -- Byte addresses for byte-aligned fields.
  constant CR_TC      : natural := 4*CR_CCR   + 0; -- Trap cause.
  constant CR_BR      : natural := 4*CR_CCR   + 1; -- Branch register file.
  constant CR_CID     : natural := 4*CR_SCCR  + 0; -- Context ID.
  constant CR_DCRF    : natural := 4*CR_DCR   + 0; -- Debug control flags.
  constant CR_DCRC    : natural := 4*CR_DCR   + 1; -- Debug breakpoint cause.
  
  -- Bit indices for CCR.
  constant CR_CCR_IEN     : natural := 0; -- Interrupt enable.
  constant CR_CCR_IEN_C   : natural := 1; -- Interrupt disable.
  constant CR_CCR_RFT     : natural := 2; -- Ready for trap.
  constant CR_CCR_RFT_C   : natural := 3; -- Not ready for trap.
  constant CR_CCR_BPE     : natural := 4; -- Breakpoint enable.
  constant CR_CCR_BPE_C   : natural := 5; -- Breakpoint disable.
  
  -- Bit indices for DCR.
  constant CR_DCR_BREAK   : natural := 24; -- Break flag.
  constant CR_DCR_STEP    : natural := 25; -- Step flag.
  constant CR_DCR_RESUME  : natural := 26; -- Resume flag.
  constant CR_DCR_EXT_DBG : natural := 27; -- External debug flag.
  constant CR_DCR_INT_DBG : natural := 28; -- Internal debug flag.
  constant CR_DCR_JUMP    : natural := 30; -- Jump flag (after bus write to PC).
  constant CR_DCR_DONE    : natural := 31; -- Done flag and (when writing) reset bit.
  
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
    highBit       : in    natural := 31;    -- High bit index of the range which is saved/restored.
    lowBit        : in    natural := 0;     -- Low bit index of the range which is saved/restored.
    resetState    : in    std_logic_vector := ""; -- Reset state for the register.
    writeEnable   : in    std_logic := '0'; -- Write enable bit for hardware writes.
    writeData     : in    std_logic_vector := ""; -- Write data for hardware writes.
    permissions   : in    creg_perm_type    -- Bus/processor permissions.
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
