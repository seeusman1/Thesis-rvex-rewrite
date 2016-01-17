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

library rvex;
use rvex.core_intIface_pkg.all;
use rvex.core_opcodeDatapath_pkg.all;
use rvex.core_opcodeAlu_pkg.all;
use rvex.core_opcodeBranch_pkg.all;
use rvex.core_opcodeMemory_pkg.all;
use rvex.core_opcodeMultiplier_pkg.all;

--=============================================================================
-- This package specifies basic decoding signals for all opcodes. In theory,
-- when you want to implement a new instruction which makes use of existing
-- logic in the pipelanes, you only need to change things here and in the
-- rvex_opcode<unit>_pkg associated with the unit you want to change. If you
-- also need new control signals, you'll obviously have to change the code of
-- the functional unit as well.
-------------------------------------------------------------------------------
package core_opcode_pkg is
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- Opcode table entry type
  -----------------------------------------------------------------------------
  -- Constrained string type for syntax specifications.
  subtype syllable_syntax_type is string(1 to 50);
  
  -- Each opcode has a table entry like this which defines the behavior of the
  -- instruction.
  type opcodeTableEntry_type is record
    
    -- Instruction name/syntax for disassembly in VHDL simulation. Syntax_reg
    -- is for syllables with bit 23 cleared, syntax_imm is for syllables with
    -- bit 23 set. See also the documentation just below the =Opcode decoding
    -- table= header.
    syntax_reg                  : syllable_syntax_type;
    syntax_imm                  : syllable_syntax_type;
    
    -- Instruction valid. When this is low, attempting to execute this
    -- instruction raises an invalid instruction exception. This is indexed
    -- by bit 23 of the syllable, which determines whether operand 2 is a
    -- register or an immediate.
    valid                       : std_logic_vector(1 downto 0);
    
    -- Control signals for datapath.
    datapathCtrl                : datapathCtrlSignals_type;
    
    -- Control signals for the ALU.
    aluCtrl                     : aluCtrlSignals_type;
    
    -- Control signals for the branch unit.
    branchCtrl                  : branchCtrlSignals_type;
    
    -- Control signals for the memory unit.
    memoryCtrl                  : memoryCtrlSignals_type;
    
    -- Control signals for the multiplier unit.
    multiplierCtrl              : multiplierCtrlSignals_type;
    
  end record;
  
  -- Array type of the above to get a table. The index of this table is the
  -- opcode (the MSB of the syllable).
  type opcodeTable_type is array (0 to 2**rvex_opcode_type'LENGTH-1) of opcodeTableEntry_type;
  
  --===========================================================================
  -- Opcode decoding table
  --===========================================================================
  -- This table specifies how all instructions are decoded. It is generated by
  -- the scripts in the config directory.
  --
  -- Indexes in this table correspond to syllable bit 31 downto 24. The syntax
  -- formatter makes the following replacements when decoding the instruction.
  --   "%r1" --> Bit 22..17 in unsigned decimal.
  --   "%r2" --> Bit 16..11 in unsigned decimal.
  --   "%r3" --> Bit 10..5 in unsigned decimal.
  --   "%id" --> immediate, respecting long immediates. Displays the immediate
  --             in signed decimal form.
  --   "%iu" --> Same as above, but in unsigned decimal form.
  --   "%ih" --> Same as above, but in hex form.
  --   "%i1" --> Bit 27..25 in unsigned decimal for LIMMH target lane.
  --   "%i2" --> Bit 24..02 in hex for LIMMH.
  --   "%b1" --> Bit 26..24 in unsigned decimal.
  --   "%b2" --> Bit 19..17 in unsigned decimal.
  --   "%b3" --> Bit 4..2 in unsigned decimal.
  --   "%bi" --> Bit 23..5 in signed decimal (rfi/return stack offset).
  --   "%bt" --> Next PC + bit 23..5 in hex (branch target).
  --   "#"   --> Cluster identifier (maps to 0).
  --
  -- ##################### GENERATED FROM HERE ONWARDS ##################### --
  -- Do not remove the above line. It is used as a marker by the generator
  -- scripts.
                                                                                                     -- GENERATED --
  -----------------------------------------------------------------------------
  -- Undefined entries
  -----------------------------------------------------------------------------
  constant opcodeTableEntry_default : opcodeTableEntry_type := (
    syntax_reg => "unknown                                           ",
    syntax_imm => "unknown                                           ",
    valid => "00", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
    op1LinkReg => '0', gpRegWE => '0', brFmt => '0', isNOP => '1',
    funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
    brRegWE => '0', isLIMMH => '0', isTrap => '0'), aluCtrl => (compare => '0',                      -- GENERATED --
    bitwiseOp => BITW_OR, op1Mux => EXTEND32, op2Mux => ZERO, shiftLeft => '0',
    intResultMux => BITWISE, brResultMux => PASS, unsignedOp => '0',
    divs => '0', opBrMux => PASS), branchCtrl => (isBranchInstruction => '0',
    stop => '0', branchIfFalse => '0', branchToLink => '0', link => '0',
    branchIfTrue => '0', RFI => '0'), memoryCtrl => (isMemoryInstruction => '0',
    unsignedOp => '0', readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
    writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
    op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
    op2sel => LOW_HALF, isMultiplyInstruction => '0')
  );                                                                                                 -- GENERATED --

  constant OPCODE_TABLE : opcodeTable_type := (

    ---------------------------------------------------------------------------
    -- ALU arithmetic instructions
    ---------------------------------------------------------------------------
    98 => (
      syntax_reg => "add r#.%r1 = r#.%r2, r#.%r3                       ",
      syntax_imm => "add r#.%r1 = r#.%r2, %ih                          ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',                             -- GENERATED --
      op1LinkReg => '0', gpRegWE => '1', brFmt => '1', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_AND, op1Mux => EXTEND32,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => ADDER,
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => FALSE),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',                                  -- GENERATED --
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    107 => (
      syntax_reg => "sh1add r#.%r1 = r#.%r2, r#.%r3                    ",
      syntax_imm => "sh1add r#.%r1 = r#.%r2, %ih                       ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '1', brFmt => '1', isNOP => '0',                                 -- GENERATED --
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_AND, op1Mux => SHL1,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => ADDER,
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => FALSE),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,                                        -- GENERATED --
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    108 => (
      syntax_reg => "sh2add r#.%r1 = r#.%r2, r#.%r3                    ",
      syntax_imm => "sh2add r#.%r1 = r#.%r2, %ih                       ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '1', brFmt => '1', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',                       -- GENERATED --
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_AND, op1Mux => SHL2,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => ADDER,
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => FALSE),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',                                    -- GENERATED --
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    109 => (
      syntax_reg => "sh3add r#.%r1 = r#.%r2, r#.%r3                    ",
      syntax_imm => "sh3add r#.%r1 = r#.%r2, %ih                       ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '1', brFmt => '1', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),                                                -- GENERATED --
      aluCtrl => (compare => '0', bitwiseOp => BITW_AND, op1Mux => SHL3,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => ADDER,
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => FALSE),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,                                     -- GENERATED --
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    110 => (
      syntax_reg => "sh4add r#.%r1 = r#.%r2, r#.%r3                    ",
      syntax_imm => "sh4add r#.%r1 = r#.%r2, %ih                       ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '1', brFmt => '1', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_AND, op1Mux => SHL4,                             -- GENERATED --
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => ADDER,
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => FALSE),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')                                              -- GENERATED --
    ),
    26 => (
      syntax_reg => "sub r#.%r1 = r#.%r3, r#.%r2                       ",
      syntax_imm => "sub r#.%r1 = %ih, r#.%r2                          ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '1', brFmt => '1', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_AND, op1Mux => EXTEND32INV,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => ADDER,                                   -- GENERATED --
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => TRUE),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),                                                                                               -- GENERATED --
    120 to 127 => (
      syntax_reg => "addcg r#.%r1, b#.%b3 = b#.%b1, r#.%r2, r#.%r3     ",
      syntax_imm => "unknown                                           ",
      valid => "01", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '1', brFmt => '1', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '1', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_AND, op1Mux => EXTEND32,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => ADDER,
      brResultMux => CARRY_OUT, unsignedOp => '1', divs => '0',                                      -- GENERATED --
      opBrMux => PASS), branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    112 to 119 => (                                                                                  -- GENERATED --
      syntax_reg => "divs r#.%r1, b#.%b3 = b#.%b1, r#.%r2, r#.%r3      ",
      syntax_imm => "unknown                                           ",
      valid => "01", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '1', brFmt => '1', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '1', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_AND, op1Mux => SHL1,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => ADDER,
      brResultMux => DIVS, unsignedOp => '0', divs => '1', opBrMux => PASS),
      branchCtrl => (isBranchInstruction => '0', stop => '0',                                        -- GENERATED --
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),

    ---------------------------------------------------------------------------                      -- GENERATED --
    -- ALU barrel shifter instructions
    ---------------------------------------------------------------------------
    111 => (
      syntax_reg => "shl r#.%r1 = r#.%r2, r#.%r3                       ",
      syntax_imm => "shl r#.%r1 = r#.%r2, %ih                          ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '1', brFmt => '1', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_AND, op1Mux => EXTEND32,                         -- GENERATED --
      op2Mux => EXTEND32, shiftLeft => '1', intResultMux => SHIFTER,
      brResultMux => PASS, unsignedOp => '1', divs => '0', opBrMux => FALSE),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')                                              -- GENERATED --
    ),
    24 => (
      syntax_reg => "shr r#.%r1 = r#.%r2, r#.%r3                       ",
      syntax_imm => "shr r#.%r1 = r#.%r2, %ih                          ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '1', brFmt => '1', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_AND, op1Mux => EXTEND32,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => SHIFTER,                                 -- GENERATED --
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => FALSE),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),                                                                                               -- GENERATED --
    25 => (
      syntax_reg => "shru r#.%r1 = r#.%r2, r#.%r3                      ",
      syntax_imm => "shru r#.%r1 = r#.%r2, %ih                         ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '1', brFmt => '1', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_AND, op1Mux => EXTEND32,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => SHIFTER,
      brResultMux => PASS, unsignedOp => '1', divs => '0', opBrMux => FALSE),                        -- GENERATED --
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
                                                                                                     -- GENERATED --
    ---------------------------------------------------------------------------
    -- ALU bitwise instructions
    ---------------------------------------------------------------------------
    99 => (
      syntax_reg => "and r#.%r1 = r#.%r2, r#.%r3                       ",
      syntax_imm => "and r#.%r1 = r#.%r2, %ih                          ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '1', brFmt => '1', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),                                                -- GENERATED --
      aluCtrl => (compare => '0', bitwiseOp => BITW_AND, op1Mux => EXTEND32,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => BITWISE,
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => FALSE),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,                                     -- GENERATED --
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    100 => (
      syntax_reg => "andc r#.%r1 = r#.%r2, r#.%r3                      ",
      syntax_imm => "andc r#.%r1 = r#.%r2, %ih                         ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '1', brFmt => '1', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_AND, op1Mux => EXTEND32INV,                      -- GENERATED --
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => BITWISE,
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => FALSE),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')                                              -- GENERATED --
    ),
    105 => (
      syntax_reg => "or r#.%r1 = r#.%r2, r#.%r3                        ",
      syntax_imm => "or r#.%r1 = r#.%r2, %ih                           ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '1', brFmt => '1', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_OR, op1Mux => EXTEND32,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => BITWISE,                                 -- GENERATED --
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => FALSE),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),                                                                                               -- GENERATED --
    106 => (
      syntax_reg => "orc r#.%r1 = r#.%r2, r#.%r3                       ",
      syntax_imm => "orc r#.%r1 = r#.%r2, %ih                          ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '1', brFmt => '1', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_OR, op1Mux => EXTEND32INV,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => BITWISE,
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => FALSE),                        -- GENERATED --
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    31 => (                                                                                          -- GENERATED --
      syntax_reg => "xor r#.%r1 = r#.%r2, r#.%r3                       ",
      syntax_imm => "xor r#.%r1 = r#.%r2, %ih                          ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '1', brFmt => '1', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_XOR, op1Mux => EXTEND32,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => BITWISE,
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => FALSE),
      branchCtrl => (isBranchInstruction => '0', stop => '0',                                        -- GENERATED --
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),

    ---------------------------------------------------------------------------                      -- GENERATED --
    -- ALU single-bit instructions
    ---------------------------------------------------------------------------
    44 => (
      syntax_reg => "sbit r#.%r1 = r#.%r2, r#.%r3                      ",
      syntax_imm => "sbit r#.%r1 = r#.%r2, %ih                         ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '1', brFmt => '1', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => SET_BIT, op1Mux => EXTEND32,                          -- GENERATED --
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => BITWISE,
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => TRUE),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')                                              -- GENERATED --
    ),
    45 => (
      syntax_reg => "sbitf r#.%r1 = r#.%r2, r#.%r3                     ",
      syntax_imm => "sbitf r#.%r1 = r#.%r2, %ih                        ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '1', brFmt => '1', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => SET_BIT, op1Mux => EXTEND32,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => BITWISE,                                 -- GENERATED --
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => FALSE),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),                                                                                               -- GENERATED --
    92 => (
      syntax_reg => "tbit r#.%r1 = r#.%r2, r#.%r3                      ",
      syntax_imm => "tbit r#.%r1 = r#.%r2, %ih                         ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '1', brFmt => '1', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_AND, op1Mux => EXTEND32,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => BOOL,
      brResultMux => TBIT, unsignedOp => '0', divs => '0', opBrMux => FALSE),                        -- GENERATED --
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    93 => (                                                                                          -- GENERATED --
      syntax_reg => "tbit b#.%b2 = r#.%r2, r#.%r3                      ",
      syntax_imm => "tbit b#.%b2 = r#.%r2, %ih                         ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '0', brFmt => '0', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '1', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_AND, op1Mux => EXTEND32,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => BOOL,
      brResultMux => TBIT, unsignedOp => '0', divs => '0', opBrMux => FALSE),
      branchCtrl => (isBranchInstruction => '0', stop => '0',                                        -- GENERATED --
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    94 => (
      syntax_reg => "tbitf r#.%r1 = r#.%r2, r#.%r3                     ",                            -- GENERATED --
      syntax_imm => "tbitf r#.%r1 = r#.%r2, %ih                        ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '1', brFmt => '1', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_AND, op1Mux => EXTEND32,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => BOOL,
      brResultMux => TBITF, unsignedOp => '0', divs => '0', opBrMux => FALSE),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',                                        -- GENERATED --
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    95 => (
      syntax_reg => "tbitf b#.%b2 = r#.%r2, r#.%r3                     ",
      syntax_imm => "tbitf b#.%b2 = r#.%r2, %ih                        ",                            -- GENERATED --
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '0', brFmt => '0', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '1', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_AND, op1Mux => EXTEND32,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => BOOL,
      brResultMux => TBITF, unsignedOp => '0', divs => '0', opBrMux => FALSE),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),                                                              -- GENERATED --
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),

    ---------------------------------------------------------------------------
    -- ALU boolean instructions
    ---------------------------------------------------------------------------                      -- GENERATED --
    90 => (
      syntax_reg => "andl r#.%r1 = r#.%r2, r#.%r3                      ",
      syntax_imm => "andl r#.%r1 = r#.%r2, %ih                         ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '1', brFmt => '1', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_AND, op1Mux => EXTEND32,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => BOOL,
      brResultMux => LOGIC_AND, unsignedOp => '0', divs => '0',                                      -- GENERATED --
      opBrMux => FALSE), branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    91 => (                                                                                          -- GENERATED --
      syntax_reg => "andl b#.%b2 = r#.%r2, r#.%r3                      ",
      syntax_imm => "andl b#.%b2 = r#.%r2, %ih                         ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '0', brFmt => '0', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '1', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_AND, op1Mux => EXTEND32,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => BOOL,
      brResultMux => LOGIC_AND, unsignedOp => '0', divs => '0',
      opBrMux => FALSE), branchCtrl => (isBranchInstruction => '0', stop => '0',                     -- GENERATED --
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    88 => (
      syntax_reg => "orl r#.%r1 = r#.%r2, r#.%r3                       ",                            -- GENERATED --
      syntax_imm => "orl r#.%r1 = r#.%r2, %ih                          ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '1', brFmt => '1', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_AND, op1Mux => EXTEND32,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => BOOL,
      brResultMux => LOGIC_OR, unsignedOp => '0', divs => '0',
      opBrMux => FALSE), branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',                                        -- GENERATED --
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    89 => (
      syntax_reg => "orl b#.%b2 = r#.%r2, r#.%r3                       ",
      syntax_imm => "orl b#.%b2 = r#.%r2, %ih                          ",                            -- GENERATED --
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '0', brFmt => '0', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '1', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_AND, op1Mux => EXTEND32,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => BOOL,
      brResultMux => LOGIC_OR, unsignedOp => '0', divs => '0',
      opBrMux => FALSE), branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),                                                              -- GENERATED --
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    84 => (
      syntax_reg => "nandl r#.%r1 = r#.%r2, r#.%r3                     ",
      syntax_imm => "nandl r#.%r1 = r#.%r2, %ih                        ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',                             -- GENERATED --
      op1LinkReg => '0', gpRegWE => '1', brFmt => '1', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_AND, op1Mux => EXTEND32,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => BOOL,
      brResultMux => LOGIC_NAND, unsignedOp => '0', divs => '0',
      opBrMux => FALSE), branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',                                  -- GENERATED --
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    85 => (
      syntax_reg => "nandl b#.%b2 = r#.%r2, r#.%r3                     ",
      syntax_imm => "nandl b#.%b2 = r#.%r2, %ih                        ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '0', brFmt => '0', isNOP => '0',                                 -- GENERATED --
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '1', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_AND, op1Mux => EXTEND32,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => BOOL,
      brResultMux => LOGIC_NAND, unsignedOp => '0', divs => '0',
      opBrMux => FALSE), branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,                                        -- GENERATED --
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    86 => (
      syntax_reg => "norl r#.%r1 = r#.%r2, r#.%r3                      ",
      syntax_imm => "norl r#.%r1 = r#.%r2, %ih                         ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '1', brFmt => '1', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',                       -- GENERATED --
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_AND, op1Mux => EXTEND32,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => BOOL,
      brResultMux => LOGIC_NOR, unsignedOp => '0', divs => '0',
      opBrMux => FALSE), branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',                                    -- GENERATED --
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    87 => (
      syntax_reg => "norl b#.%b2 = r#.%r2, r#.%r3                      ",
      syntax_imm => "norl b#.%b2 = r#.%r2, %ih                         ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '0', brFmt => '0', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '1', isLIMMH => '0', isTrap => '0'),                                                -- GENERATED --
      aluCtrl => (compare => '0', bitwiseOp => BITW_AND, op1Mux => EXTEND32,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => BOOL,
      brResultMux => LOGIC_NOR, unsignedOp => '0', divs => '0',
      opBrMux => FALSE), branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,                                     -- GENERATED --
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),

    ---------------------------------------------------------------------------
    -- ALU compare instructions
    ---------------------------------------------------------------------------
    64 => (
      syntax_reg => "cmpeq r#.%r1 = r#.%r2, r#.%r3                     ",
      syntax_imm => "cmpeq r#.%r1 = r#.%r2, %ih                        ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',                             -- GENERATED --
      op1LinkReg => '0', gpRegWE => '1', brFmt => '1', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '1', bitwiseOp => BITW_AND, op1Mux => EXTEND32INV,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => BOOL,
      brResultMux => CMP_EQ, unsignedOp => '0', divs => '0', opBrMux => TRUE),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',                                  -- GENERATED --
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    65 => (
      syntax_reg => "cmpeq b#.%b2 = r#.%r2, r#.%r3                     ",
      syntax_imm => "cmpeq b#.%b2 = r#.%r2, %ih                        ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '0', brFmt => '0', isNOP => '0',                                 -- GENERATED --
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '1', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '1', bitwiseOp => BITW_AND, op1Mux => EXTEND32INV,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => BOOL,
      brResultMux => CMP_EQ, unsignedOp => '0', divs => '0', opBrMux => TRUE),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,                                        -- GENERATED --
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    66 => (
      syntax_reg => "cmpge r#.%r1 = r#.%r2, r#.%r3                     ",
      syntax_imm => "cmpge r#.%r1 = r#.%r2, %ih                        ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '1', brFmt => '1', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',                       -- GENERATED --
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '1', bitwiseOp => BITW_AND, op1Mux => EXTEND32INV,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => BOOL,
      brResultMux => CMP_GE, unsignedOp => '0', divs => '0', opBrMux => TRUE),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',                                    -- GENERATED --
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    67 => (
      syntax_reg => "cmpge b#.%b2 = r#.%r2, r#.%r3                     ",
      syntax_imm => "cmpge b#.%b2 = r#.%r2, %ih                        ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '0', brFmt => '0', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '1', isLIMMH => '0', isTrap => '0'),                                                -- GENERATED --
      aluCtrl => (compare => '1', bitwiseOp => BITW_AND, op1Mux => EXTEND32INV,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => BOOL,
      brResultMux => CMP_GE, unsignedOp => '0', divs => '0', opBrMux => TRUE),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,                                     -- GENERATED --
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    68 => (
      syntax_reg => "cmpgeu r#.%r1 = r#.%r2, r#.%r3                    ",
      syntax_imm => "cmpgeu r#.%r1 = r#.%r2, %ih                       ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '1', brFmt => '1', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '1', bitwiseOp => BITW_AND, op1Mux => EXTEND32INV,                      -- GENERATED --
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => BOOL,
      brResultMux => CMP_GE, unsignedOp => '1', divs => '0', opBrMux => TRUE),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')                                              -- GENERATED --
    ),
    69 => (
      syntax_reg => "cmpgeu b#.%b2 = r#.%r2, r#.%r3                    ",
      syntax_imm => "cmpgeu b#.%b2 = r#.%r2, %ih                       ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '0', brFmt => '0', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '1', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '1', bitwiseOp => BITW_AND, op1Mux => EXTEND32INV,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => BOOL,                                    -- GENERATED --
      brResultMux => CMP_GE, unsignedOp => '1', divs => '0', opBrMux => TRUE),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),                                                                                               -- GENERATED --
    70 => (
      syntax_reg => "cmpgt r#.%r1 = r#.%r2, r#.%r3                     ",
      syntax_imm => "cmpgt r#.%r1 = r#.%r2, %ih                        ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '1', brFmt => '1', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '1', bitwiseOp => BITW_AND, op1Mux => EXTEND32INV,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => BOOL,
      brResultMux => CMP_GT, unsignedOp => '0', divs => '0', opBrMux => TRUE),                       -- GENERATED --
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    71 => (                                                                                          -- GENERATED --
      syntax_reg => "cmpgt b#.%b2 = r#.%r2, r#.%r3                     ",
      syntax_imm => "cmpgt b#.%b2 = r#.%r2, %ih                        ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '0', brFmt => '0', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '1', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '1', bitwiseOp => BITW_AND, op1Mux => EXTEND32INV,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => BOOL,
      brResultMux => CMP_GT, unsignedOp => '0', divs => '0', opBrMux => TRUE),
      branchCtrl => (isBranchInstruction => '0', stop => '0',                                        -- GENERATED --
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    72 => (
      syntax_reg => "cmpgtu r#.%r1 = r#.%r2, r#.%r3                    ",                            -- GENERATED --
      syntax_imm => "cmpgtu r#.%r1 = r#.%r2, %ih                       ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '1', brFmt => '1', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '1', bitwiseOp => BITW_AND, op1Mux => EXTEND32INV,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => BOOL,
      brResultMux => CMP_GT, unsignedOp => '1', divs => '0', opBrMux => TRUE),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',                                        -- GENERATED --
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    73 => (
      syntax_reg => "cmpgtu b#.%b2 = r#.%r2, r#.%r3                    ",
      syntax_imm => "cmpgtu b#.%b2 = r#.%r2, %ih                       ",                            -- GENERATED --
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '0', brFmt => '0', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '1', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '1', bitwiseOp => BITW_AND, op1Mux => EXTEND32INV,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => BOOL,
      brResultMux => CMP_GT, unsignedOp => '1', divs => '0', opBrMux => TRUE),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),                                                              -- GENERATED --
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    74 => (
      syntax_reg => "cmple r#.%r1 = r#.%r2, r#.%r3                     ",
      syntax_imm => "cmple r#.%r1 = r#.%r2, %ih                        ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',                             -- GENERATED --
      op1LinkReg => '0', gpRegWE => '1', brFmt => '1', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '1', bitwiseOp => BITW_AND, op1Mux => EXTEND32INV,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => BOOL,
      brResultMux => CMP_LE, unsignedOp => '0', divs => '0', opBrMux => TRUE),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',                                  -- GENERATED --
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    75 => (
      syntax_reg => "cmple b#.%b2 = r#.%r2, r#.%r3                     ",
      syntax_imm => "cmple b#.%b2 = r#.%r2, %ih                        ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '0', brFmt => '0', isNOP => '0',                                 -- GENERATED --
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '1', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '1', bitwiseOp => BITW_AND, op1Mux => EXTEND32INV,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => BOOL,
      brResultMux => CMP_LE, unsignedOp => '0', divs => '0', opBrMux => TRUE),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,                                        -- GENERATED --
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    76 => (
      syntax_reg => "cmpleu r#.%r1 = r#.%r2, r#.%r3                    ",
      syntax_imm => "cmpleu r#.%r1 = r#.%r2, %ih                       ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '1', brFmt => '1', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',                       -- GENERATED --
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '1', bitwiseOp => BITW_AND, op1Mux => EXTEND32INV,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => BOOL,
      brResultMux => CMP_LE, unsignedOp => '1', divs => '0', opBrMux => TRUE),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',                                    -- GENERATED --
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    77 => (
      syntax_reg => "cmpleu b#.%b2 = r#.%r2, r#.%r3                    ",
      syntax_imm => "cmpleu b#.%b2 = r#.%r2, %ih                       ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '0', brFmt => '0', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '1', isLIMMH => '0', isTrap => '0'),                                                -- GENERATED --
      aluCtrl => (compare => '1', bitwiseOp => BITW_AND, op1Mux => EXTEND32INV,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => BOOL,
      brResultMux => CMP_LE, unsignedOp => '1', divs => '0', opBrMux => TRUE),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,                                     -- GENERATED --
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    78 => (
      syntax_reg => "cmplt r#.%r1 = r#.%r2, r#.%r3                     ",
      syntax_imm => "cmplt r#.%r1 = r#.%r2, %ih                        ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '1', brFmt => '1', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '1', bitwiseOp => BITW_AND, op1Mux => EXTEND32INV,                      -- GENERATED --
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => BOOL,
      brResultMux => CMP_LT, unsignedOp => '0', divs => '0', opBrMux => TRUE),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')                                              -- GENERATED --
    ),
    79 => (
      syntax_reg => "cmplt b#.%b2 = r#.%r2, r#.%r3                     ",
      syntax_imm => "cmplt b#.%b2 = r#.%r2, %ih                        ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '0', brFmt => '0', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '1', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '1', bitwiseOp => BITW_AND, op1Mux => EXTEND32INV,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => BOOL,                                    -- GENERATED --
      brResultMux => CMP_LT, unsignedOp => '0', divs => '0', opBrMux => TRUE),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),                                                                                               -- GENERATED --
    80 => (
      syntax_reg => "cmpltu r#.%r1 = r#.%r2, r#.%r3                    ",
      syntax_imm => "cmpltu r#.%r1 = r#.%r2, %ih                       ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '1', brFmt => '1', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '1', bitwiseOp => BITW_AND, op1Mux => EXTEND32INV,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => BOOL,
      brResultMux => CMP_LT, unsignedOp => '1', divs => '0', opBrMux => TRUE),                       -- GENERATED --
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    81 => (                                                                                          -- GENERATED --
      syntax_reg => "cmpltu b#.%b2 = r#.%r2, r#.%r3                    ",
      syntax_imm => "cmpltu b#.%b2 = r#.%r2, %ih                       ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '0', brFmt => '0', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '1', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '1', bitwiseOp => BITW_AND, op1Mux => EXTEND32INV,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => BOOL,
      brResultMux => CMP_LT, unsignedOp => '1', divs => '0', opBrMux => TRUE),
      branchCtrl => (isBranchInstruction => '0', stop => '0',                                        -- GENERATED --
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    82 => (
      syntax_reg => "cmpne r#.%r1 = r#.%r2, r#.%r3                     ",                            -- GENERATED --
      syntax_imm => "cmpne r#.%r1 = r#.%r2, %ih                        ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '1', brFmt => '1', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '1', bitwiseOp => BITW_AND, op1Mux => EXTEND32INV,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => BOOL,
      brResultMux => CMP_NE, unsignedOp => '0', divs => '0', opBrMux => TRUE),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',                                        -- GENERATED --
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    83 => (
      syntax_reg => "cmpne b#.%b2 = r#.%r2, r#.%r3                     ",
      syntax_imm => "cmpne b#.%b2 = r#.%r2, %ih                        ",                            -- GENERATED --
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '0', brFmt => '0', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '1', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '1', bitwiseOp => BITW_AND, op1Mux => EXTEND32INV,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => BOOL,
      brResultMux => CMP_NE, unsignedOp => '0', divs => '0', opBrMux => TRUE),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),                                                              -- GENERATED --
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),

    ---------------------------------------------------------------------------
    -- ALU selection instructions
    ---------------------------------------------------------------------------                      -- GENERATED --
    56 to 63 => (
      syntax_reg => "slct r#.%r1 = b#.%b1, r#.%r2, r#.%r3              ",
      syntax_imm => "slct r#.%r1 = b#.%b1, r#.%r2, %ih                 ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '1', brFmt => '1', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_AND, op1Mux => EXTEND32,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => OP_SEL,
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => PASS),                         -- GENERATED --
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    48 to 55 => (                                                                                    -- GENERATED --
      syntax_reg => "slctf r#.%r1 = b#.%b1, r#.%r2, r#.%r3             ",
      syntax_imm => "slctf r#.%r1 = b#.%b1, r#.%r2, %ih                ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '1', brFmt => '1', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_AND, op1Mux => EXTEND32,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => OP_SEL,
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => INVERT),
      branchCtrl => (isBranchInstruction => '0', stop => '0',                                        -- GENERATED --
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    101 => (
      syntax_reg => "max r#.%r1 = r#.%r2, r#.%r3                       ",                            -- GENERATED --
      syntax_imm => "max r#.%r1 = r#.%r2, %ih                          ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '1', brFmt => '1', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '1', bitwiseOp => BITW_AND, op1Mux => EXTEND32INV,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => OP_SEL,
      brResultMux => CMP_GE, unsignedOp => '0', divs => '0', opBrMux => TRUE),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',                                        -- GENERATED --
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    102 => (
      syntax_reg => "maxu r#.%r1 = r#.%r2, r#.%r3                      ",
      syntax_imm => "maxu r#.%r1 = r#.%r2, %ih                         ",                            -- GENERATED --
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '1', brFmt => '1', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '1', bitwiseOp => BITW_AND, op1Mux => EXTEND32INV,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => OP_SEL,
      brResultMux => CMP_GE, unsignedOp => '1', divs => '0', opBrMux => TRUE),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),                                                              -- GENERATED --
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    103 => (
      syntax_reg => "min r#.%r1 = r#.%r2, r#.%r3                       ",
      syntax_imm => "min r#.%r1 = r#.%r2, %ih                          ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',                             -- GENERATED --
      op1LinkReg => '0', gpRegWE => '1', brFmt => '1', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '1', bitwiseOp => BITW_AND, op1Mux => EXTEND32INV,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => OP_SEL,
      brResultMux => CMP_LE, unsignedOp => '0', divs => '0', opBrMux => TRUE),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',                                  -- GENERATED --
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    104 => (
      syntax_reg => "minu r#.%r1 = r#.%r2, r#.%r3                      ",
      syntax_imm => "minu r#.%r1 = r#.%r2, %ih                         ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '1', brFmt => '1', isNOP => '0',                                 -- GENERATED --
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '1', bitwiseOp => BITW_AND, op1Mux => EXTEND32INV,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => OP_SEL,
      brResultMux => CMP_LE, unsignedOp => '1', divs => '0', opBrMux => TRUE),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,                                        -- GENERATED --
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),

    ---------------------------------------------------------------------------
    -- ALU type conversion instructions
    ---------------------------------------------------------------------------
    27 => (
      syntax_reg => "sxtb r#.%r1 = r#.%r2                              ",                            -- GENERATED --
      syntax_imm => "unknown                                           ",
      valid => "01", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '1', brFmt => '1', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_AND, op1Mux => EXTEND8,
      op2Mux => ZERO, shiftLeft => '0', intResultMux => ADDER,
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => FALSE),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',                                        -- GENERATED --
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    28 => (
      syntax_reg => "sxth r#.%r1 = r#.%r2                              ",
      syntax_imm => "unknown                                           ",                            -- GENERATED --
      valid => "01", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '1', brFmt => '1', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_AND, op1Mux => EXTEND16,
      op2Mux => ZERO, shiftLeft => '0', intResultMux => ADDER,
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => FALSE),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),                                                              -- GENERATED --
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    29 => (
      syntax_reg => "zxtb r#.%r1 = r#.%r2                              ",
      syntax_imm => "unknown                                           ",
      valid => "01", datapathCtrl => (op3LinkReg => '0', stackOp => '0',                             -- GENERATED --
      op1LinkReg => '0', gpRegWE => '1', brFmt => '1', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_AND, op1Mux => EXTEND8,
      op2Mux => ZERO, shiftLeft => '0', intResultMux => ADDER,
      brResultMux => PASS, unsignedOp => '1', divs => '0', opBrMux => FALSE),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',                                  -- GENERATED --
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    30 => (
      syntax_reg => "zxth r#.%r1 = r#.%r2                              ",
      syntax_imm => "unknown                                           ",
      valid => "01", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '1', brFmt => '1', isNOP => '0',                                 -- GENERATED --
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_AND, op1Mux => EXTEND16,
      op2Mux => ZERO, shiftLeft => '0', intResultMux => ADDER,
      brResultMux => PASS, unsignedOp => '1', divs => '0', opBrMux => FALSE),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,                                        -- GENERATED --
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),

    ---------------------------------------------------------------------------
    -- ALU miscellaneous instructions
    ---------------------------------------------------------------------------
    96 => (
      syntax_reg => "nop                                               ",                            -- GENERATED --
      syntax_imm => "nop                                               ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '0', brFmt => '0', isNOP => '1',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_OR, op1Mux => EXTEND32,
      op2Mux => ZERO, shiftLeft => '0', intResultMux => BITWISE,
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => PASS),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',                                        -- GENERATED --
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    145 => (
      syntax_reg => "clz r#.%r1 = r#.%r2                               ",
      syntax_imm => "unknown                                           ",                            -- GENERATED --
      valid => "01", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '1', brFmt => '1', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_AND, op1Mux => EXTEND32,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => CLZ,
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => FALSE),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),                                                              -- GENERATED --
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    11 => (
      syntax_reg => "movtl l#.0 = r#.%r3                               ",
      syntax_imm => "movtl l#.0 = %ih                                  ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',                             -- GENERATED --
      op1LinkReg => '0', gpRegWE => '0', brFmt => '0', isNOP => '0',
      funcSel => ALU, linkWE => '1', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_OR, op1Mux => EXTEND32,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => OP_SEL,
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => FALSE),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',                                  -- GENERATED --
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    12 => (
      syntax_reg => "movfl r#.%r1 = l#.0                               ",
      syntax_imm => "unknown                                           ",
      valid => "01", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '1', gpRegWE => '1', brFmt => '0', isNOP => '0',                                 -- GENERATED --
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_OR, op1Mux => EXTEND32,
      op2Mux => ZERO, shiftLeft => '0', intResultMux => BITWISE,
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => PASS),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,                                        -- GENERATED --
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    144 => (
      syntax_reg => "trap r#.%r2, r#.%r3                               ",
      syntax_imm => "trap r#.%r2, %ih                                  ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '0', brFmt => '0', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',                       -- GENERATED --
      brRegWE => '0', isLIMMH => '0', isTrap => '1'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_OR, op1Mux => EXTEND32,
      op2Mux => ZERO, shiftLeft => '0', intResultMux => BITWISE,
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => PASS),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',                                    -- GENERATED --
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),

    ---------------------------------------------------------------------------
    -- Multiply instructions
    ---------------------------------------------------------------------------
    0 => (
      syntax_reg => "mpyll r#.%r1 = r#.%r2, r#.%r3                     ",
      syntax_imm => "mpyll r#.%r1 = r#.%r2, %ih                        ",                            -- GENERATED --
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '1', brFmt => '0', isNOP => '0',
      funcSel => MUL, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_OR, op1Mux => EXTEND32,
      op2Mux => ZERO, shiftLeft => '0', intResultMux => BITWISE,
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => PASS),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),                                                              -- GENERATED --
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '1')
    ),
    1 => (
      syntax_reg => "mpyllu r#.%r1 = r#.%r2, r#.%r3                    ",
      syntax_imm => "mpyllu r#.%r1 = r#.%r2, %ih                       ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',                             -- GENERATED --
      op1LinkReg => '0', gpRegWE => '1', brFmt => '0', isNOP => '0',
      funcSel => MUL, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_OR, op1Mux => EXTEND32,
      op2Mux => ZERO, shiftLeft => '0', intResultMux => BITWISE,
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => PASS),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',                                  -- GENERATED --
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '1',
      op1unsigned => '1', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '1')
    ),
    2 => (
      syntax_reg => "mpylh r#.%r1 = r#.%r2, r#.%r3                     ",
      syntax_imm => "mpylh r#.%r1 = r#.%r2, %ih                        ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '1', brFmt => '0', isNOP => '0',                                 -- GENERATED --
      funcSel => MUL, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_OR, op1Mux => EXTEND32,
      op2Mux => ZERO, shiftLeft => '0', intResultMux => BITWISE,
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => PASS),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,                                        -- GENERATED --
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => HIGH_HALF, isMultiplyInstruction => '1')
    ),
    3 => (
      syntax_reg => "mpylhu r#.%r1 = r#.%r2, r#.%r3                    ",
      syntax_imm => "mpylhu r#.%r1 = r#.%r2, %ih                       ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '1', brFmt => '0', isNOP => '0',
      funcSel => MUL, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',                       -- GENERATED --
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_OR, op1Mux => EXTEND32,
      op2Mux => ZERO, shiftLeft => '0', intResultMux => BITWISE,
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => PASS),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '1',                                    -- GENERATED --
      op1unsigned => '1', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => HIGH_HALF, isMultiplyInstruction => '1')
    ),
    4 => (
      syntax_reg => "mpyhh r#.%r1 = r#.%r2, r#.%r3                     ",
      syntax_imm => "mpyhh r#.%r1 = r#.%r2, %ih                        ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '1', brFmt => '0', isNOP => '0',
      funcSel => MUL, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),                                                -- GENERATED --
      aluCtrl => (compare => '0', bitwiseOp => BITW_OR, op1Mux => EXTEND32,
      op2Mux => ZERO, shiftLeft => '0', intResultMux => BITWISE,
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => PASS),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => HIGH_HALF,                                    -- GENERATED --
      op2sel => HIGH_HALF, isMultiplyInstruction => '1')
    ),
    5 => (
      syntax_reg => "mpyhhu r#.%r1 = r#.%r2, r#.%r3                    ",
      syntax_imm => "mpyhhu r#.%r1 = r#.%r2, %ih                       ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '1', brFmt => '0', isNOP => '0',
      funcSel => MUL, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_OR, op1Mux => EXTEND32,                          -- GENERATED --
      op2Mux => ZERO, shiftLeft => '0', intResultMux => BITWISE,
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => PASS),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '1',
      op1unsigned => '1', resultSel => PASS, op1sel => HIGH_HALF,
      op2sel => HIGH_HALF, isMultiplyInstruction => '1')                                             -- GENERATED --
    ),
    6 => (
      syntax_reg => "mpyl r#.%r1 = r#.%r2, r#.%r3                      ",
      syntax_imm => "mpyl r#.%r1 = r#.%r2, %ih                         ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '1', brFmt => '0', isNOP => '0',
      funcSel => MUL, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_OR, op1Mux => EXTEND32,
      op2Mux => ZERO, shiftLeft => '0', intResultMux => BITWISE,                                     -- GENERATED --
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => PASS),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => WORD, op2sel => LOW_HALF,
      isMultiplyInstruction => '1')
    ),                                                                                               -- GENERATED --
    7 => (
      syntax_reg => "mpylu r#.%r1 = r#.%r2, r#.%r3                     ",
      syntax_imm => "mpylu r#.%r1 = r#.%r2, %ih                        ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '1', brFmt => '0', isNOP => '0',
      funcSel => MUL, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_OR, op1Mux => EXTEND32,
      op2Mux => ZERO, shiftLeft => '0', intResultMux => BITWISE,
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => PASS),                         -- GENERATED --
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '1',
      op1unsigned => '1', resultSel => PASS, op1sel => WORD, op2sel => LOW_HALF,
      isMultiplyInstruction => '1')
    ),
    8 => (                                                                                           -- GENERATED --
      syntax_reg => "mpyh r#.%r1 = r#.%r2, r#.%r3                      ",
      syntax_imm => "mpyh r#.%r1 = r#.%r2, %ih                         ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '1', brFmt => '0', isNOP => '0',
      funcSel => MUL, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_OR, op1Mux => EXTEND32,
      op2Mux => ZERO, shiftLeft => '0', intResultMux => BITWISE,
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => PASS),
      branchCtrl => (isBranchInstruction => '0', stop => '0',                                        -- GENERATED --
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => WORD,
      op2sel => HIGH_HALF, isMultiplyInstruction => '1')
    ),
    9 => (
      syntax_reg => "mpyhu r#.%r1 = r#.%r2, r#.%r3                     ",                            -- GENERATED --
      syntax_imm => "mpyhu r#.%r1 = r#.%r2, %ih                        ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '1', brFmt => '0', isNOP => '0',
      funcSel => MUL, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_OR, op1Mux => EXTEND32,
      op2Mux => ZERO, shiftLeft => '0', intResultMux => BITWISE,
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => PASS),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',                                        -- GENERATED --
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '1',
      op1unsigned => '1', resultSel => PASS, op1sel => WORD,
      op2sel => HIGH_HALF, isMultiplyInstruction => '1')
    ),
    10 => (
      syntax_reg => "mpyhs r#.%r1 = r#.%r2, r#.%r3                     ",
      syntax_imm => "mpyhs r#.%r1 = r#.%r2, %ih                        ",                            -- GENERATED --
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '1', brFmt => '0', isNOP => '0',
      funcSel => MUL, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_OR, op1Mux => EXTEND32,
      op2Mux => ZERO, shiftLeft => '0', intResultMux => BITWISE,
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => PASS),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),                                                              -- GENERATED --
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => SHL16, op1sel => WORD,
      op2sel => HIGH_HALF, isMultiplyInstruction => '1')
    ),
    146 => (
      syntax_reg => "mpylhus r#.%r1 = r#.%r2, r#.%r3                   ",
      syntax_imm => "mpylhus r#.%r1 = r#.%r2, %ih                      ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',                             -- GENERATED --
      op1LinkReg => '0', gpRegWE => '1', brFmt => '0', isNOP => '0',
      funcSel => MUL, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_OR, op1Mux => EXTEND32,
      op2Mux => ZERO, shiftLeft => '0', intResultMux => BITWISE,
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => PASS),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',                                  -- GENERATED --
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '1',
      op1unsigned => '0', resultSel => SHR32, op1sel => WORD,
      op2sel => LOW_HALF, isMultiplyInstruction => '1')
    ),
    147 => (
      syntax_reg => "mpyhhs r#.%r1 = r#.%r2, r#.%r3                    ",
      syntax_imm => "mpyhhs r#.%r1 = r#.%r2, %ih                       ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '1', brFmt => '0', isNOP => '0',                                 -- GENERATED --
      funcSel => MUL, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_OR, op1Mux => EXTEND32,
      op2Mux => ZERO, shiftLeft => '0', intResultMux => BITWISE,
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => PASS),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,                                        -- GENERATED --
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => SHR16, op1sel => WORD,
      op2sel => HIGH_HALF, isMultiplyInstruction => '1')
    ),

    ---------------------------------------------------------------------------
    -- Memory instructions
    ---------------------------------------------------------------------------
    16 => (
      syntax_reg => "unknown                                           ",                            -- GENERATED --
      syntax_imm => "ldw r#.%r1 = %ih[r#.%r2]                          ",
      valid => "10", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '1', brFmt => '0', isNOP => '0',
      funcSel => MEM, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_AND, op1Mux => EXTEND32,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => ADDER,
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => FALSE),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',                                        -- GENERATED --
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '1', unsignedOp => '0',
      readEnable => '1', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    17 => (
      syntax_reg => "unknown                                           ",
      syntax_imm => "ldh r#.%r1 = %ih[r#.%r2]                          ",                            -- GENERATED --
      valid => "10", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '1', brFmt => '0', isNOP => '0',
      funcSel => MEM, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_AND, op1Mux => EXTEND32,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => ADDER,
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => FALSE),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),                                                              -- GENERATED --
      memoryCtrl => (isMemoryInstruction => '1', unsignedOp => '0',
      readEnable => '1', accessSizeBLog2 => ACCESS_SIZE_HALFWORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    18 => (
      syntax_reg => "unknown                                           ",
      syntax_imm => "ldhu r#.%r1 = %ih[r#.%r2]                         ",
      valid => "10", datapathCtrl => (op3LinkReg => '0', stackOp => '0',                             -- GENERATED --
      op1LinkReg => '0', gpRegWE => '1', brFmt => '0', isNOP => '0',
      funcSel => MEM, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_AND, op1Mux => EXTEND32,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => ADDER,
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => FALSE),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '1', unsignedOp => '1',                                  -- GENERATED --
      readEnable => '1', accessSizeBLog2 => ACCESS_SIZE_HALFWORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    19 => (
      syntax_reg => "unknown                                           ",
      syntax_imm => "ldb r#.%r1 = %ih[r#.%r2]                          ",
      valid => "10", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '1', brFmt => '0', isNOP => '0',                                 -- GENERATED --
      funcSel => MEM, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_AND, op1Mux => EXTEND32,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => ADDER,
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => FALSE),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '1', unsignedOp => '0',
      readEnable => '1', accessSizeBLog2 => ACCESS_SIZE_BYTE,                                        -- GENERATED --
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    20 => (
      syntax_reg => "unknown                                           ",
      syntax_imm => "ldbu r#.%r1 = %ih[r#.%r2]                         ",
      valid => "10", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '1', brFmt => '0', isNOP => '0',
      funcSel => MEM, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',                       -- GENERATED --
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_AND, op1Mux => EXTEND32,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => ADDER,
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => FALSE),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '1', unsignedOp => '1',
      readEnable => '1', accessSizeBLog2 => ACCESS_SIZE_BYTE,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',                                    -- GENERATED --
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    13 => (
      syntax_reg => "unknown                                           ",
      syntax_imm => "ldw l#.0 = %ih[r#.%r2]                            ",
      valid => "10", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '0', brFmt => '0', isNOP => '0',
      funcSel => MEM, linkWE => '1', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),                                                -- GENERATED --
      aluCtrl => (compare => '0', bitwiseOp => BITW_AND, op1Mux => EXTEND32,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => ADDER,
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => FALSE),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '1', unsignedOp => '0',
      readEnable => '1', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,                                     -- GENERATED --
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    46 => (
      syntax_reg => "unknown                                           ",
      syntax_imm => "ldbr %ih[r#.%r2]                                  ",
      valid => "10", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '0', brFmt => '0', isNOP => '0',
      funcSel => MEM, linkWE => '0', allBrRegsWE => '1', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_AND, op1Mux => EXTEND32,                         -- GENERATED --
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => ADDER,
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => FALSE),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '1', unsignedOp => '1',
      readEnable => '1', accessSizeBLog2 => ACCESS_SIZE_BYTE,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')                                              -- GENERATED --
    ),
    21 => (
      syntax_reg => "unknown                                           ",
      syntax_imm => "stw %ih[r#.%r2] = r#.%r1                          ",
      valid => "10", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '0', brFmt => '0', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_AND, op1Mux => EXTEND32,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => ADDER,                                   -- GENERATED --
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => FALSE),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '1', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '1'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),                                                                                               -- GENERATED --
    22 => (
      syntax_reg => "unknown                                           ",
      syntax_imm => "sth %ih[r#.%r2] = r#.%r1                          ",
      valid => "10", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '0', brFmt => '0', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_AND, op1Mux => EXTEND32,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => ADDER,
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => FALSE),                        -- GENERATED --
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '1', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_HALFWORD,
      writeEnable => '1'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    23 => (                                                                                          -- GENERATED --
      syntax_reg => "unknown                                           ",
      syntax_imm => "stb %ih[r#.%r2] = r#.%r1                          ",
      valid => "10", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '0', brFmt => '0', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_AND, op1Mux => EXTEND32,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => ADDER,
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => FALSE),
      branchCtrl => (isBranchInstruction => '0', stop => '0',                                        -- GENERATED --
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '1', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_BYTE,
      writeEnable => '1'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    14 => (
      syntax_reg => "unknown                                           ",                            -- GENERATED --
      syntax_imm => "stw %ih[r#.%r2] = l#.0                            ",
      valid => "10", datapathCtrl => (op3LinkReg => '1', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '0', brFmt => '0', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_AND, op1Mux => EXTEND32,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => ADDER,
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => FALSE),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',                                        -- GENERATED --
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '1', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '1'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    47 => (
      syntax_reg => "unknown                                           ",
      syntax_imm => "stbr %ih[r#.%r2]                                  ",                            -- GENERATED --
      valid => "10", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '0', brFmt => '0', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '1',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_AND, op1Mux => EXTEND32,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => ADDER,
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => FALSE),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),                                                              -- GENERATED --
      memoryCtrl => (isMemoryInstruction => '1', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_BYTE,
      writeEnable => '1'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),

    ---------------------------------------------------------------------------
    -- Branch instructions
    ---------------------------------------------------------------------------                      -- GENERATED --
    32 => (
      syntax_reg => "goto %bt                                          ",
      syntax_imm => "goto %bt                                          ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '0', brFmt => '0', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_OR, op1Mux => EXTEND32,
      op2Mux => ZERO, shiftLeft => '0', intResultMux => BITWISE,
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => PASS),                         -- GENERATED --
      branchCtrl => (isBranchInstruction => '1', stop => '0',
      branchIfFalse => '1', branchToLink => '0', link => '0',
      branchIfTrue => '1', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    33 => (                                                                                          -- GENERATED --
      syntax_reg => "igoto l#.0                                        ",
      syntax_imm => "igoto l#.0                                        ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '0', brFmt => '0', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_OR, op1Mux => EXTEND32,
      op2Mux => ZERO, shiftLeft => '0', intResultMux => BITWISE,
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => PASS),
      branchCtrl => (isBranchInstruction => '1', stop => '0',                                        -- GENERATED --
      branchIfFalse => '1', branchToLink => '1', link => '0',
      branchIfTrue => '1', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    34 => (
      syntax_reg => "call l#.0 = %bt                                   ",                            -- GENERATED --
      syntax_imm => "call l#.0 = %bt                                   ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '0', brFmt => '0', isNOP => '0',
      funcSel => PCP1, linkWE => '1', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_OR, op1Mux => EXTEND32,
      op2Mux => ZERO, shiftLeft => '0', intResultMux => BITWISE,
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => PASS),
      branchCtrl => (isBranchInstruction => '1', stop => '0',
      branchIfFalse => '1', branchToLink => '0', link => '1',                                        -- GENERATED --
      branchIfTrue => '1', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    35 => (
      syntax_reg => "icall l#.0 = l#.0                                 ",
      syntax_imm => "icall l#.0 = l#.0                                 ",                            -- GENERATED --
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '0', brFmt => '0', isNOP => '0',
      funcSel => PCP1, linkWE => '1', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_OR, op1Mux => EXTEND32,
      op2Mux => ZERO, shiftLeft => '0', intResultMux => BITWISE,
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => PASS),
      branchCtrl => (isBranchInstruction => '1', stop => '0',
      branchIfFalse => '1', branchToLink => '1', link => '1',
      branchIfTrue => '1', RFI => '0'),                                                              -- GENERATED --
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    36 => (
      syntax_reg => "br b#.%b3, %bt                                    ",
      syntax_imm => "br b#.%b3, %bt                                    ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',                             -- GENERATED --
      op1LinkReg => '0', gpRegWE => '0', brFmt => '0', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_OR, op1Mux => EXTEND32,
      op2Mux => ZERO, shiftLeft => '0', intResultMux => BITWISE,
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => PASS),
      branchCtrl => (isBranchInstruction => '1', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '1', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',                                  -- GENERATED --
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    37 => (
      syntax_reg => "brf b#.%b3, %bt                                   ",
      syntax_imm => "brf b#.%b3, %bt                                   ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '0', brFmt => '0', isNOP => '0',                                 -- GENERATED --
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_OR, op1Mux => EXTEND32,
      op2Mux => ZERO, shiftLeft => '0', intResultMux => BITWISE,
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => PASS),
      branchCtrl => (isBranchInstruction => '1', stop => '0',
      branchIfFalse => '1', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,                                        -- GENERATED --
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    38 => (
      syntax_reg => "return r#.1 = r#.1, %bi, l#.0                     ",
      syntax_imm => "return r#.1 = r#.1, %bi, l#.0                     ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '1',
      op1LinkReg => '0', gpRegWE => '1', brFmt => '0', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',                       -- GENERATED --
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_AND, op1Mux => EXTEND32,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => ADDER,
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => FALSE),
      branchCtrl => (isBranchInstruction => '1', stop => '0',
      branchIfFalse => '1', branchToLink => '1', link => '0',
      branchIfTrue => '1', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',                                    -- GENERATED --
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    39 => (
      syntax_reg => "rfi r#.1 = r#.1, %bi                              ",
      syntax_imm => "rfi r#.1 = r#.1, %bi                              ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '1',
      op1LinkReg => '0', gpRegWE => '1', brFmt => '0', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),                                                -- GENERATED --
      aluCtrl => (compare => '0', bitwiseOp => BITW_AND, op1Mux => EXTEND32,
      op2Mux => EXTEND32, shiftLeft => '0', intResultMux => ADDER,
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => FALSE),
      branchCtrl => (isBranchInstruction => '1', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '1'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,                                     -- GENERATED --
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    40 => (
      syntax_reg => "stop                                              ",
      syntax_imm => "stop                                              ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '0', brFmt => '0', isNOP => '0',
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '0', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_OR, op1Mux => EXTEND32,                          -- GENERATED --
      op2Mux => ZERO, shiftLeft => '0', intResultMux => BITWISE,
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => PASS),
      branchCtrl => (isBranchInstruction => '1', stop => '1',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')                                              -- GENERATED --
    ),

    ---------------------------------------------------------------------------
    -- Long immediate instructions
    ---------------------------------------------------------------------------
    128 to 143 => (
      syntax_reg => "limmh %i1, %i2                                    ",
      syntax_imm => "limmh %i1, %i2                                    ",
      valid => "11", datapathCtrl => (op3LinkReg => '0', stackOp => '0',
      op1LinkReg => '0', gpRegWE => '0', brFmt => '0', isNOP => '0',                                 -- GENERATED --
      funcSel => ALU, linkWE => '0', allBrRegsWE => '0', op3BranchRegs => '0',
      brRegWE => '0', isLIMMH => '1', isTrap => '0'),
      aluCtrl => (compare => '0', bitwiseOp => BITW_OR, op1Mux => EXTEND32,
      op2Mux => ZERO, shiftLeft => '0', intResultMux => BITWISE,
      brResultMux => PASS, unsignedOp => '0', divs => '0', opBrMux => PASS),
      branchCtrl => (isBranchInstruction => '0', stop => '0',
      branchIfFalse => '0', branchToLink => '0', link => '0',
      branchIfTrue => '0', RFI => '0'),
      memoryCtrl => (isMemoryInstruction => '0', unsignedOp => '0',
      readEnable => '0', accessSizeBLog2 => ACCESS_SIZE_WORD,                                        -- GENERATED --
      writeEnable => '0'), multiplierCtrl => (op2unsigned => '0',
      op1unsigned => '0', resultSel => PASS, op1sel => LOW_HALF,
      op2sel => LOW_HALF, isMultiplyInstruction => '0')
    ),
    others => opcodeTableEntry_default
  );

end core_opcode_pkg;

package body core_opcode_pkg is                                                                      -- GENERATED --
end core_opcode_pkg;
