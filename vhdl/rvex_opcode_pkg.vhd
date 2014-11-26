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
use work.rvex_intIface_pkg.all;
use work.rvex_opcodeDatapath_pkg.all;
use work.rvex_opcodeAlu_pkg.all;
use work.rvex_opcodeBranch_pkg.all;

--=============================================================================
-- This package specifies basic decoding signals for all opcodes. In theory,
-- when you want to implement a new instruction which makes use of existing
-- logic in the pipelanes, you only need to change things here and in the
-- rvex_opcode<unit>_pkg associated with the unit you want to change. If you
-- also need new control signals, you'll obviously have to change the code of
-- the functional unit as well.
-------------------------------------------------------------------------------
package rvex_opcode_pkg is
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- Opcode table entry type
  -----------------------------------------------------------------------------
  -- Each opcode has a table entry like this which defines the behavior of the
  -- instruction.
  type opcodeTableEntry_type is record
    
    -- Instruction name/syntax for disassembly in VHDL simulation. Syntax_reg
    -- is for syllables with bit 23 cleared, syntax_imm is for syllables with
    -- bit 23 set. See also the documentation just below the =Opcode decoding
    -- table= header.
    syntax_reg                  : string(1 to 50);
    syntax_imm                  : string(1 to 50);
    
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
    
  end record;
  
  -- Default values for an opcode table entry.
  constant opcodeTableEntry_default : opcodeTableEntry_type := (
    syntax_reg => "Unknown                                           ",
    syntax_imm => "Unknown                                           ",
    valid => "00",
    datapathCtrl => DP_CTRL_NOP,
    aluCtrl => ALU_CTRL_NOP,
    branchCtrl => BRANCH_CTRL_NOP
  );
  
  -- Array type of the above to get a table. The index of this table is the
  -- opcode (the MSB of the syllable).
  type opcodeTable_type is array (0 to 2**rvex_opcode_type'LENGTH-1) of opcodeTableEntry_type;
  
  --===========================================================================
  -- Opcode decoding table
  --===========================================================================
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
  --   "%bi" --> Bit 23..5 in unsigned decimal (rfi/return stack offset).
  --   "%bt" --> Next PC + bit 23..5 in hex (branch target).
  --   "#"   --> Cluster.
  constant OPCODE_TABLE : opcodeTable_type := (
    
    ---------------------------------------------------------------------------
    -- Special operations
    ---------------------------------------------------------------------------
    -- No operation.
    2#01100000# => (
      syntax_reg => "nop                                               ",
      syntax_imm => "nop                                               ",
      valid => "11",
      datapathCtrl => DP_CTRL_NOP,
      aluCtrl => ALU_CTRL_NOP,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Forward immediate to other syllable.
    2#10000000# to 2#10001111# => (
      syntax_reg => "limmh %i1, %i2                                    ",
      syntax_imm => "limmh %i1, %i2                                    ",
      valid => "11",
      datapathCtrl => DP_CTRL_NOP,
      aluCtrl => ALU_CTRL_NOP,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    ---------------------------------------------------------------------------
    -- ALU operations
    ---------------------------------------------------------------------------
    -- Signed or unsigned 32-bit addition.
    2#01100010# => (
      syntax_reg => "add r#.%r1 = r#.%r2, r#.%r3                       ",
      syntax_imm => "add r#.%r1 = r#.%r2, %id                          ",
      valid => "11",
      datapathCtrl => DP_CTRL_ALU_INT,
      aluCtrl => ALU_CTRL_ADD,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Bitwise AND.
    2#01100011# => (
      syntax_reg => "and r#.%r1 = r#.%r2, r#.%r3                       ",
      syntax_imm => "and r#.%r1 = r#.%r2, %ih                          ",
      valid => "11",
      datapathCtrl => DP_CTRL_ALU_INT,
      aluCtrl => ALU_CTRL_AND,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Bitwise AND, with operand 1 one's-complemented.
    2#01100100# => (
      syntax_reg => "andc r#.%r1 = r#.%r2, r#.%r3                      ",
      syntax_imm => "andc r#.%r1 = r#.%r2, %ih                         ",
      valid => "11",
      datapathCtrl => DP_CTRL_ALU_INT,
      aluCtrl => ALU_CTRL_ANDC,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Computes maximum of the input operands using signed arithmetic.
    2#01100101# => (
      syntax_reg => "max r#.%r1 = r#.%r2, r#.%r3                       ",
      syntax_imm => "max r#.%r1 = r#.%r2, %id                          ",
      valid => "11",
      datapathCtrl => DP_CTRL_ALU_INT,
      aluCtrl => ALU_CTRL_MAX,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Computes maximum of the input operands using unsigned arithmetic.
    2#01100110# => (
      syntax_reg => "maxu r#.%r1 = r#.%r2, r#.%r3                      ",
      syntax_imm => "maxu r#.%r1 = r#.%r2, %iu                         ",
      valid => "11",
      datapathCtrl => DP_CTRL_ALU_INT,
      aluCtrl => ALU_CTRL_MAXU,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Computes minimum of the input operands using signed arithmetic.
    2#01100111# => (
      syntax_reg => "min r#.%r1 = r#.%r2, r#.%r3                       ",
      syntax_imm => "min r#.%r1 = r#.%r2, %id                          ",
      valid => "11",
      datapathCtrl => DP_CTRL_ALU_INT,
      aluCtrl => ALU_CTRL_MIN,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Computes minimum of the input operands using unsigned arithmetic.
    2#01101000# => (
      syntax_reg => "minu r#.%r1 = r#.%r2, r#.%r3                      ",
      syntax_imm => "minu r#.%r1 = r#.%r2, %iu                         ",
      valid => "11",
      datapathCtrl => DP_CTRL_ALU_INT,
      aluCtrl => ALU_CTRL_MINU,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Bitwise OR.
    2#01101001# => (
      syntax_reg => "or r#.%r1 = r#.%r2, r#.%r3                        ",
      syntax_imm => "or r#.%r1 = r#.%r2, %ih                           ",
      valid => "11",
      datapathCtrl => DP_CTRL_ALU_INT,
      aluCtrl => ALU_CTRL_OR,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Bitwise OR, with operand 1 one's complemented.
    2#01101010# => (
      syntax_reg => "orc r#.%r1 = r#.%r2, r#.%r3                       ",
      syntax_imm => "orc r#.%r1 = r#.%r2, %ih                          ",
      valid => "11",
      datapathCtrl => DP_CTRL_ALU_INT,
      aluCtrl => ALU_CTRL_ORC,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- 32 bit addition, operand 1 shifted left by one before adding.
    2#01101011# => (
      syntax_reg => "sh1add r#.%r1 = r#.%r2, r#.%r3                    ",
      syntax_imm => "sh1add r#.%r1 = r#.%r2, %id                       ",
      valid => "11",
      datapathCtrl => DP_CTRL_ALU_INT,
      aluCtrl => ALU_CTRL_SH1ADD,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- 32 bit addition, operand 1 shifted left by two before adding.
    2#01101100# => (
      syntax_reg => "sh2add r#.%r1 = r#.%r2, r#.%r3                    ",
      syntax_imm => "sh2add r#.%r1 = r#.%r2, %id                       ",
      valid => "11",
      datapathCtrl => DP_CTRL_ALU_INT,
      aluCtrl => ALU_CTRL_SH2ADD,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- 32 bit addition, operand 1 shifted left by three before adding.
    2#01101101# => (
      syntax_reg => "sh3add r#.%r1 = r#.%r2, r#.%r3                    ",
      syntax_imm => "sh3add r#.%r1 = r#.%r2, %id                       ",
      valid => "11",
      datapathCtrl => DP_CTRL_ALU_INT,
      aluCtrl => ALU_CTRL_SH3ADD,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- 32 bit addition, operand 2 shifted left by four before adding.
    2#01101110# => (
      syntax_reg => "sh4add r#.%r1 = r#.%r2, r#.%r3                    ",
      syntax_imm => "sh4add r#.%r1 = r#.%r2, %id                       ",
      valid => "11",
      datapathCtrl => DP_CTRL_ALU_INT,
      aluCtrl => ALU_CTRL_SH4ADD,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Arithmetic/logical shift left.
    2#01101111# => (
      syntax_reg => "shl r#.%r1 = r#.%r2, r#.%r3                       ",
      syntax_imm => "shl r#.%r1 = r#.%r2, %iu                          ",
      valid => "11",
      datapathCtrl => DP_CTRL_ALU_INT,
      aluCtrl => ALU_CTRL_SHL,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Signed arithmetic shift right.
    2#00011000# => (
      syntax_reg => "shr r#.%r1 = r#.%r2, r#.%r3                       ",
      syntax_imm => "shr r#.%r1 = r#.%r2, %iu                          ",
      valid => "11",
      datapathCtrl => DP_CTRL_ALU_INT,
      aluCtrl => ALU_CTRL_SHR,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Unsigned arithmetic/logical shift right.
    2#00011001# => (
      syntax_reg => "shru r#.%r1 = r#.%r2, r#.%r3                      ",
      syntax_imm => "shru r#.%r1 = r#.%r2, %iu                         ",
      valid => "11",
      datapathCtrl => DP_CTRL_ALU_INT,
      aluCtrl => ALU_CTRL_SHRU,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Subtract operand 1 from operand 2.
    2#00011010# => (
      syntax_reg => "sub r#.%r1 = r#.%r3, r#.%r2                       ",
      syntax_imm => "sub r#.%r1 = %id, r#.%r2                          ",
      valid => "11",
      datapathCtrl => DP_CTRL_ALU_INT,
      aluCtrl => ALU_CTRL_SUB,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Sign extend operand 1 from byte to word.
    2#00011011# => (
      syntax_reg => "sxtb r#.%r1 = r#.%r2                              ",
      syntax_imm => "unknown                                           ",
      valid => "01",
      datapathCtrl => DP_CTRL_ALU_INT,
      aluCtrl => ALU_CTRL_SXTB,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Sign extend operand 1 from halfword to word.
    2#00011100# => (
      syntax_reg => "sxth r#.%r1 = r#.%r2                              ",
      syntax_imm => "unknown                                           ",
      valid => "01",
      datapathCtrl => DP_CTRL_ALU_INT,
      aluCtrl => ALU_CTRL_SXTH,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Zero extend operand 1 from byte to word.
    2#00011101# => (
      syntax_reg => "zxtb r#.%r1 = r#.%r2                              ",
      syntax_imm => "unknown                                           ",
      valid => "01",
      datapathCtrl => DP_CTRL_ALU_INT,
      aluCtrl => ALU_CTRL_ZXTB,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Zero extend operand 1 from halfword to word.
    2#00011110# => (
      syntax_reg => "zxth r#.%r1 = r#.%r2                              ",
      syntax_imm => "unknown                                           ",
      valid => "01",
      datapathCtrl => DP_CTRL_ALU_INT,
      aluCtrl => ALU_CTRL_ZXTH,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Bitwise XOR.
    2#00011111# => (
      syntax_reg => "xor r#.%r1 = r#.%r2, r#.%r3                       ",
      syntax_imm => "xor r#.%r1 = r#.%r2, %ih                          ",
      valid => "11",
      datapathCtrl => DP_CTRL_ALU_INT,
      aluCtrl => ALU_CTRL_XOR,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Copy operand 1, while setting the bit indexed by the immediate.
    2#00101100# => (
      syntax_reg => "unknown                                           ",
      syntax_imm => "sbit r#.%r1 = r#.%r2, %iu                         ",
      valid => "10",
      datapathCtrl => DP_CTRL_ALU_INT,
      aluCtrl => ALU_CTRL_SBIT,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Copy operand 1, while clearing the bit indexed by the immediate.
    2#00101101# => (
      syntax_reg => "unknown                                           ",
      syntax_imm => "sbitf r#.%r1 = r#.%r2, %iu                        ",
      valid => "10",
      datapathCtrl => DP_CTRL_ALU_INT,
      aluCtrl => ALU_CTRL_SBITF,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Operand 1 == operand 2 -> general purpose register.
    2#01000000# => (
      syntax_reg => "cmpeq r#.%r1 = r#.%r2, r#.%r3                     ",
      syntax_imm => "cmpeq r#.%r1 = r#.%r2, %id (= %ih)                ",
      valid => "11",
      datapathCtrl => DP_CTRL_ALU_INT,
      aluCtrl => ALU_CTRL_CMPEQ,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Operand 1 == operand 2 -> branch register.
    2#01000001# => (
      syntax_reg => "cmpeq b#.%b2 = r#.%r2, r#.%r3                     ",
      syntax_imm => "cmpeq b#.%b2 = r#.%r2, %id (= %ih)                ",
      valid => "11",
      datapathCtrl => DP_CTRL_ALU_BOOL,
      aluCtrl => ALU_CTRL_CMPEQ,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Operand 1 >= operand 2 -> general purpose register.
    2#01000010# => (
      syntax_reg => "cmpge r#.%r1 = r#.%r2, r#.%r3                     ",
      syntax_imm => "cmpge r#.%r1 = r#.%r2, %id                        ",
      valid => "11",
      datapathCtrl => DP_CTRL_ALU_INT,
      aluCtrl => ALU_CTRL_CMPGE,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Operand 1 >= operand 2 -> branch register.
    2#01000011# => (
      syntax_reg => "cmpge b#.%b2 = r#.%r2, r#.%r3                     ",
      syntax_imm => "cmpge b#.%b2 = r#.%r2, %id                        ",
      valid => "11",
      datapathCtrl => DP_CTRL_ALU_BOOL,
      aluCtrl => ALU_CTRL_CMPGE,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Unsigned operand 1 >= operand 2 -> general purpose register.
    2#01000100# => (
      syntax_reg => "cmpgeu r#.%r1 = r#.%r2, r#.%r3                    ",
      syntax_imm => "cmpgeu r#.%r1 = r#.%r2, %iu                       ",
      valid => "11",
      datapathCtrl => DP_CTRL_ALU_INT,
      aluCtrl => ALU_CTRL_CMPGEU,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Unsigned operand 1 >= operand 2 -> branch register.
    2#01000101# => (
      syntax_reg => "cmpgeu b#.%b2 = r#.%r2, r#.%r3                    ",
      syntax_imm => "cmpgeu b#.%b2 = r#.%r2, %iu                       ",
      valid => "11",
      datapathCtrl => DP_CTRL_ALU_BOOL,
      aluCtrl => ALU_CTRL_CMPGEU,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Operand 1 > operand 2 -> general purpose register.
    2#01000110# => (
      syntax_reg => "cmpgt r#.%r1 = r#.%r2, r#.%r3                     ",
      syntax_imm => "cmpgt r#.%r1 = r#.%r2, %id                        ",
      valid => "11",
      datapathCtrl => DP_CTRL_ALU_INT,
      aluCtrl => ALU_CTRL_CMPGT,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Operand 1 > operand 2 -> branch register.
    2#01000111# => (
      syntax_reg => "cmpgt b#.%b2 = r#.%r2, r#.%r3                     ",
      syntax_imm => "cmpgt b#.%b2 = r#.%r2, %id                        ",
      valid => "11",
      datapathCtrl => DP_CTRL_ALU_BOOL,
      aluCtrl => ALU_CTRL_CMPGT,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Unsigned operand 1 > operand 2 -> general purpose register.
    2#01001000# => (
      syntax_reg => "cmpgtu r#.%r1 = r#.%r2, r#.%r3                    ",
      syntax_imm => "cmpgtu r#.%r1 = r#.%r2, %iu                       ",
      valid => "11",
      datapathCtrl => DP_CTRL_ALU_INT,
      aluCtrl => ALU_CTRL_CMPGTU,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Unsigned operand 1 > operand 2 -> branch register.
    2#01001001# => (
      syntax_reg => "cmpgtu b#.%b2 = r#.%r2, r#.%r3                    ",
      syntax_imm => "cmpgtu b#.%b2 = r#.%r2, %iu                       ",
      valid => "11",
      datapathCtrl => DP_CTRL_ALU_BOOL,
      aluCtrl => ALU_CTRL_CMPGTU,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Operand 1 <= operand 2 -> general purpose register.
    2#01001010# => (
      syntax_reg => "cmple r#.%r1 = r#.%r2, r#.%r3                     ",
      syntax_imm => "cmple r#.%r1 = r#.%r2, %id                        ",
      valid => "11",
      datapathCtrl => DP_CTRL_ALU_INT,
      aluCtrl => ALU_CTRL_CMPLE,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Operand 1 <= operand 2 -> branch register.
    2#01001011# => (
      syntax_reg => "cmple b#.%b2 = r#.%r2, r#.%r3                     ",
      syntax_imm => "cmple b#.%b2 = r#.%r2, %id                        ",
      valid => "11",
      datapathCtrl => DP_CTRL_ALU_BOOL,
      aluCtrl => ALU_CTRL_CMPLE,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Unsigned operand 1 <= operand 2 -> general purpose register.
    2#01001100# => (
      syntax_reg => "cmpleu r#.%r1 = r#.%r2, r#.%r3                    ",
      syntax_imm => "cmpleu r#.%r1 = r#.%r2, %iu                       ",
      valid => "11",
      datapathCtrl => DP_CTRL_ALU_INT,
      aluCtrl => ALU_CTRL_CMPLEU,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Unsigned operand 1 <= operand 2 -> branch register.
    2#01001101# => (
      syntax_reg => "cmpleu b#.%b2 = r#.%r2, r#.%r3                    ",
      syntax_imm => "cmpleu b#.%b2 = r#.%r2, %iu                       ",
      valid => "11",
      datapathCtrl => DP_CTRL_ALU_BOOL,
      aluCtrl => ALU_CTRL_CMPLEU,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Operand 1 < operand 2 -> general purpose register.
    2#01001110# => (
      syntax_reg => "cmplt r#.%r1 = r#.%r2, r#.%r3                     ",
      syntax_imm => "cmplt r#.%r1 = r#.%r2, %id                        ",
      valid => "11",
      datapathCtrl => DP_CTRL_ALU_INT,
      aluCtrl => ALU_CTRL_CMPLT,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Operand 1 < operand 2 -> branch register.
    2#01001111# => (
      syntax_reg => "cmplt b#.%b2 = r#.%r2, r#.%r3                     ",
      syntax_imm => "cmplt b#.%b2 = r#.%r2, %id                        ",
      valid => "11",
      datapathCtrl => DP_CTRL_ALU_BOOL,
      aluCtrl => ALU_CTRL_CMPLT,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Unsigned operand 1 < operand 2 -> general purpose register.
    2#01010000# => (
      syntax_reg => "cmpltu r#.%r1 = r#.%r2, r#.%r3                    ",
      syntax_imm => "cmpltu r#.%r1 = r#.%r2, %iu                       ",
      valid => "11",
      datapathCtrl => DP_CTRL_ALU_INT,
      aluCtrl => ALU_CTRL_CMPLTU,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Unsigned operand 1 < operand 2 -> branch register.
    2#01010001# => (
      syntax_reg => "cmpltu b#.%b2 = r#.%r2, r#.%r3                    ",
      syntax_imm => "cmpltu b#.%b2 = r#.%r2, %iu                       ",
      valid => "11",
      datapathCtrl => DP_CTRL_ALU_BOOL,
      aluCtrl => ALU_CTRL_CMPLTU,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Operand 1 != operand 2 -> general purpose register.
    2#01010010# => (
      syntax_reg => "cmpne r#.%r1 = r#.%r2, r#.%r3                     ",
      syntax_imm => "cmpne r#.%r1 = r#.%r2, %id (= %ih)                ",
      valid => "11",
      datapathCtrl => DP_CTRL_ALU_INT,
      aluCtrl => ALU_CTRL_CMPNE,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Operand 1 != operand 2 -> branch register.
    2#01010011# => (
      syntax_reg => "cmpne b#.%b2 = r#.%r2, r#.%r3                     ",
      syntax_imm => "cmpne b#.%b2 = r#.%r2, %id (= %ih)                ",
      valid => "11",
      datapathCtrl => DP_CTRL_ALU_BOOL,
      aluCtrl => ALU_CTRL_CMPNE,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- !(operand1 && operand2) -> general purpose register.
    2#01010100# => (
      syntax_reg => "nandl r#.%r1 = r#.%r2, r#.%r3                     ",
      syntax_imm => "nandl r#.%r1 = r#.%r2, %id                        ",
      valid => "11",
      datapathCtrl => DP_CTRL_ALU_INT,
      aluCtrl => ALU_CTRL_NANDL,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- !(operand1 && operand2) -> branch register.
    2#01010101# => (
      syntax_reg => "nandl b#.%b2 = r#.%r2, r#.%r3                     ",
      syntax_imm => "nandl b#.%b2 = r#.%r2, %id                        ",
      valid => "11",
      datapathCtrl => DP_CTRL_ALU_BOOL,
      aluCtrl => ALU_CTRL_NANDL,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- !(operand1 || operand2) -> general purpose register.
    2#01010110# => (
      syntax_reg => "norl r#.%r1 = r#.%r2, r#.%r3                      ",
      syntax_imm => "norl r#.%r1 = r#.%r2, %id                         ",
      valid => "11",
      datapathCtrl => DP_CTRL_ALU_INT,
      aluCtrl => ALU_CTRL_NORL,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- !(operand1 || operand2) -> branch register.
    2#01010111# => (
      syntax_reg => "norl b#.%b2 = r#.%r2, r#.%r3                      ",
      syntax_imm => "norl b#.%b2 = r#.%r2, %id                         ",
      valid => "11",
      datapathCtrl => DP_CTRL_ALU_BOOL,
      aluCtrl => ALU_CTRL_NORL,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Operand1 || operand2 -> general purpose register.
    2#01011000# => (
      syntax_reg => "orl r#.%r1 = r#.%r2, r#.%r3                       ",
      syntax_imm => "orl r#.%r1 = r#.%r2, %id                          ",
      valid => "11",
      datapathCtrl => DP_CTRL_ALU_INT,
      aluCtrl => ALU_CTRL_ORL,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Operand1 || operand2 -> branch register.
    2#01011001# => (
      syntax_reg => "orl b#.%b2 = r#.%r2, r#.%r3                       ",
      syntax_imm => "orl b#.%b2 = r#.%r2, %id                          ",
      valid => "11",
      datapathCtrl => DP_CTRL_ALU_BOOL,
      aluCtrl => ALU_CTRL_ORL,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Operand1 && operand2 -> general purpose register.
    2#01011010# => (
      syntax_reg => "andl r#.%r1 = r#.%r2, r#.%r3                      ",
      syntax_imm => "andl r#.%r1 = r#.%r2, %id                         ",
      valid => "11",
      datapathCtrl => DP_CTRL_ALU_INT,
      aluCtrl => ALU_CTRL_ANDL,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Operand1 && operand2 -> branch register.
    2#01011011# => (
      syntax_reg => "andl b#.%b2 = r#.%r2, r#.%r3                      ",
      syntax_imm => "andl b#.%b2 = r#.%r2, %id                         ",
      valid => "11",
      datapathCtrl => DP_CTRL_ALU_BOOL,
      aluCtrl => ALU_CTRL_ANDL,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Copies the bit in operand 1 indexed by the immediate to a general
    -- purpose register.
    2#01011100# => (
      syntax_reg => "unknown                                           ",
      syntax_imm => "tbit r#.%r1 = r#.%r2, %id                         ",
      valid => "10",
      datapathCtrl => DP_CTRL_ALU_INT,
      aluCtrl => ALU_CTRL_TBIT,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Copies the bit in operand 1 indexed by the immediate to a branch
    -- register.
    2#01011101# => (
      syntax_reg => "unknown                                           ",
      syntax_imm => "tbit b#.%b2 = r#.%r2, %id                         ",
      valid => "10",
      datapathCtrl => DP_CTRL_ALU_BOOL,
      aluCtrl => ALU_CTRL_TBIT,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Inverts and copies the bit in operand 1 indexed by the immediate
    -- to a general purpose register.
    2#01011110# => (
      syntax_reg => "unknown                                           ",
      syntax_imm => "tbitf r#.%r1 = r#.%r2, %id                        ",
      valid => "10",
      datapathCtrl => DP_CTRL_ALU_INT,
      aluCtrl => ALU_CTRL_TBITF,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Inverts and copies the bit in operand 1 indexed by the immediate
    -- to a branch register.
    2#01011111# => (
      syntax_reg => "unknown                                           ",
      syntax_imm => "tbitf b#.%b2 = r#.%r2, %id                        ",
      valid => "10",
      datapathCtrl => DP_CTRL_ALU_BOOL,
      aluCtrl => ALU_CTRL_TBITF,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- 32-bit addition with carry in and out.
    2#01111000# to 2#01111111# => (
      syntax_reg => "addcg r#.%r1, b#.%b3 = b#.%b1, r#.%r2, r#.%r3     ",
      syntax_imm => "addcg r#.%r1, b#.%b3 = b#.%b1, r#.%r2, r#.%r3     ",
      valid => "11",
      datapathCtrl => DP_CTRL_ALU_BOTH,
      aluCtrl => ALU_CTRL_ADDCG,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Division step:
    --   tmp := op1 << 1 | opBr
    --   result := op1(31) ? (tmp + op2) : (tmp - op2)
    --   branch result := op1(31)
    2#01110000# to 2#01110111# => (
      syntax_reg => "divs r#.%r1, b#.%b3 = b#.%b1, r#.%r2, r#.%r3      ",
      syntax_imm => "divs r#.%r1, b#.%b3 = b#.%b1, r#.%r2, r#.%r3      ",
      valid => "11",
      datapathCtrl => DP_CTRL_ALU_BOTH,
      aluCtrl => ALU_CTRL_DIVS,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Select: opBr ? op1 : op2.
    2#00111000# to 2#00111111# => (
      syntax_reg => "slct r#.%r1 = b#.%b1, r#.%r2, r#.%r3              ",
      syntax_imm => "slct r#.%r1 = b#.%b1, r#.%r2, %id (= %ih)         ",
      valid => "11",
      datapathCtrl => DP_CTRL_ALU_INT,
      aluCtrl => ALU_CTRL_SLCT,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Select: opBr ? op2 : op1.
    2#00110000# to 2#00110111# => (
      syntax_reg => "slctf r#.%r1 = b#.%b1, r#.%r2, r#.%r3             ",
      syntax_imm => "slctf r#.%r1 = b#.%b1, r#.%r2, %id (= %ih)        ",
      valid => "11",
      datapathCtrl => DP_CTRL_ALU_INT,
      aluCtrl => ALU_CTRL_SLCTF,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Count leading zeroes in operand 1.
    2#10010001# => (
      syntax_reg => "clz r#.%r1 = r#.%r2                               ",
      syntax_imm => "unknown                                           ",
      valid => "01",
      datapathCtrl => DP_CTRL_ALU_INT,
      aluCtrl => ALU_CTRL_CLZ,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Copy general purpose register to link register.
    2#00001011# => (
      syntax_reg => "mtl l#.0 = r#.%r2                                 ",
      syntax_imm => "unknown                                           ",
      valid => "01",
      datapathCtrl => DP_CTRL_MTL,
      aluCtrl => ALU_CTRL_FWD_OP1,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Copy link register to general purpose register.
    2#00001100# => (
      syntax_reg => "mfl r#.%r1 = l#.0                                 ",
      syntax_imm => "unknown                                           ",
      valid => "01",
      datapathCtrl => DP_CTRL_MFL,
      aluCtrl => ALU_CTRL_FWD_OP1,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    ---------------------------------------------------------------------------
    -- Branch unit operations
    ---------------------------------------------------------------------------
    -- GOTO: unconditional jump.
    2#00100000# => (
      syntax_reg => "goto %bt                                          ",
      syntax_imm => "goto %bt                                          ",
      valid => "11",
      datapathCtrl => DP_CTRL_BR,
      aluCtrl => ALU_CTRL_NOP,
      branchCtrl => BRANCH_CTRL_GOTO
    ),
    
    -- IGOTO: unconditional jump to link register.
    2#00100001# => (
      syntax_reg => "igoto l#.0                                        ",
      syntax_imm => "igoto l#.0                                        ",
      valid => "11",
      datapathCtrl => DP_CTRL_BR,
      aluCtrl => ALU_CTRL_NOP,
      branchCtrl => BRANCH_CTRL_IGOTO
    ),
    
    -- CALL: unconditional jump and link.
    2#00100010# => (
      syntax_reg => "call l#.0 = %bt                                   ",
      syntax_imm => "call l#.0 = %bt                                   ",
      valid => "11",
      datapathCtrl => DP_CTRL_BR_LINK,
      aluCtrl => ALU_CTRL_NOP,
      branchCtrl => BRANCH_CTRL_CALL
    ),
    
    -- ICALL: unconditional jump to link register and link.
    2#00100011# => (
      syntax_reg => "icall l#.0 = l#.0                                 ",
      syntax_imm => "icall l#.0 = l#.0                                 ",
      valid => "11",
      datapathCtrl => DP_CTRL_BR_LINK,
      aluCtrl => ALU_CTRL_NOP,
      branchCtrl => BRANCH_CTRL_ICALL
    ),
    
    -- BR: branch if true.
    2#00100100# => (
      syntax_reg => "br b#.%b3, %bt                                    ",
      syntax_imm => "br b#.%b3, %bt                                    ",
      valid => "11",
      datapathCtrl => DP_CTRL_BR,
      aluCtrl => ALU_CTRL_NOP,
      branchCtrl => BRANCH_CTRL_BR
    ),
    
    -- BRF: branch if false.
    2#00100101# => (
      syntax_reg => "brf b#.%b3, %bt                                   ",
      syntax_imm => "brf b#.%b3, %bt                                   ",
      valid => "11",
      datapathCtrl => DP_CTRL_BR,
      aluCtrl => ALU_CTRL_NOP,
      branchCtrl => BRANCH_CTRL_BRF
    ),
    
    -- RETURN: return from function call, add immediate to stack pointer.
    2#00100110# => (
      syntax_reg => "return r#.1 = r#.1, %bi, l#.0                     ",
      syntax_imm => "return r#.1 = r#.1, %bi, l#.0                     ",
      valid => "11",
      datapathCtrl => DP_CTRL_BR_SP,
      aluCtrl => ALU_CTRL_ADD,
      branchCtrl => BRANCH_CTRL_IGOTO
    ),
    
    -- RFI: return from trap.
    2#00100111# => (
      syntax_reg => "rfi r#.1 = r#.1, %bi, l#.0                        ",
      syntax_imm => "rfi r#.1 = r#.1, %bi, l#.0                        ",
      valid => "11",
      datapathCtrl => DP_CTRL_BR_SP,
      aluCtrl => ALU_CTRL_NOP,
      branchCtrl => BRANCH_CTRL_RFI
    ),
    
    -- TRAP: software trap.
    2#10010000# => (
      syntax_reg => "trap %iu                                          ",
      syntax_imm => "trap %iu                                          ",
      valid => "11",
      datapathCtrl => DP_CTRL_BR,
      aluCtrl => ALU_CTRL_NOP,
      branchCtrl => BRANCH_CTRL_TRAP
    ),
    
    ---------------------------------------------------------------------------
    -- MUL operations
    ---------------------------------------------------------------------------
    -- TODO: none of these are implemented yet.
    
    -- Multiply signed low 16 x low 16 bits.
    2#00000000# => (
      syntax_reg => "mpyll r#.%r1 = r#.%r2, r#.%r3                     ",
      syntax_imm => "mpyll r#.%r1 = r#.%r2, %id (= %ih)                ",
      valid => "00", -- TODO
      datapathCtrl => DP_CTRL_MUL,
      aluCtrl => ALU_CTRL_NOP,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Multiply unsigned low 16 x low 16 bits.
    2#00000001# => (
      syntax_reg => "mpyllu r#.%r1 = r#.%r2, r#.%r3                    ",
      syntax_imm => "mpyllu r#.%r1 = r#.%r2, %iu (= %ih)               ",
      valid => "00", -- TODO
      datapathCtrl => DP_CTRL_MUL,
      aluCtrl => ALU_CTRL_NOP,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Multiply signed low 16 (s1) x high 16 (s2) bits.
    2#00000010# => (
      syntax_reg => "mpylh r#.%r1 = r#.%r2, r#.%r3                     ",
      syntax_imm => "mpylh r#.%r1 = r#.%r2, %id (= %ih)                ",
      valid => "00", -- TODO
      datapathCtrl => DP_CTRL_MUL,
      aluCtrl => ALU_CTRL_NOP,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Multiply unsigned low 16 (s1) x high 16 (s2) bits.
    2#00000011# => (
      syntax_reg => "mpylhu r#.%r1 = r#.%r2, r#.%r3                    ",
      syntax_imm => "mpylhu r#.%r1 = r#.%r2, %iu (= %ih)               ",
      valid => "00", -- TODO
      datapathCtrl => DP_CTRL_MUL,
      aluCtrl => ALU_CTRL_NOP,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Multiply signed high 16 x high 16 bits.
    2#00000100# => (
      syntax_reg => "mpyhh r#.%r1 = r#.%r2, r#.%r3                     ",
      syntax_imm => "mpyhh r#.%r1 = r#.%r2, %id (= %ih)                ",
      valid => "00", -- TODO
      datapathCtrl => DP_CTRL_MUL,
      aluCtrl => ALU_CTRL_NOP,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Multiply unsigned high 16 x high 16 bits.
    2#00000101# => (
      syntax_reg => "mpyhhu r#.%r1 = r#.%r2, r#.%r3                    ",
      syntax_imm => "mpyhhu r#.%r1 = r#.%r2, %iu (= %ih)               ",
      valid => "00", -- TODO
      datapathCtrl => DP_CTRL_MUL,
      aluCtrl => ALU_CTRL_NOP,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Multiply signed low 16 (s2) x 32 (s1) bits.
    2#00000110# => (
      syntax_reg => "mpyl r#.%r1 = r#.%r2, r#.%r3                      ",
      syntax_imm => "mpyl r#.%r1 = r#.%r2, %id (= %ih)                 ",
      valid => "00", -- TODO
      datapathCtrl => DP_CTRL_MUL,
      aluCtrl => ALU_CTRL_NOP,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Multiply unsigned low 16 (s2) x 32 (s1) bits.
    2#00000111# => (
      syntax_reg => "mpylu r#.%r1 = r#.%r2, r#.%r3                     ",
      syntax_imm => "mpylu r#.%r1 = r#.%r2, %iu (= %ih)                ",
      valid => "00", -- TODO
      datapathCtrl => DP_CTRL_MUL,
      aluCtrl => ALU_CTRL_NOP,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Multiply signed high 16 (s2) x 32 (s1) bits.
    2#00001000# => (
      syntax_reg => "mpyh r#.%r1 = r#.%r2, r#.%r3                      ",
      syntax_imm => "mpyh r#.%r1 = r#.%r2, %id (= %ih)                 ",
      valid => "00", -- TODO
      datapathCtrl => DP_CTRL_MUL,
      aluCtrl => ALU_CTRL_NOP,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Multiply unsigned high 16 (s2) x 32 (s1) bits.
    2#00001001# => (
      syntax_reg => "mpyhu r#.%r1 = r#.%r2, r#.%r3                     ",
      syntax_imm => "mpyhu r#.%r1 = r#.%r2, %iu (= %ih)                ",
      valid => "00", -- TODO
      datapathCtrl => DP_CTRL_MUL,
      aluCtrl => ALU_CTRL_NOP,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Multiply signed high 16 (s2) x 32 (s1) bits, shift left 16.
    2#00001010# => (
      syntax_reg => "mpyhs r#.%r1 = r#.%r2, r#.%r3                     ",
      syntax_imm => "mpyhs r#.%r1 = r#.%r2, %id (= %ih)                ",
      valid => "00", -- TODO
      datapathCtrl => DP_CTRL_MUL,
      aluCtrl => ALU_CTRL_NOP,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Multiply signed low 16 (s2) x 32 (s1) bits, shift right 32.
    2#10010010# => (
      syntax_reg => "mpylhus r#.%r1 = r#.%r2, r#.%r3                   ",
      syntax_imm => "mpylhus r#.%r1 = r#.%r2, %id (= %ih)              ",
      valid => "00", -- TODO
      datapathCtrl => DP_CTRL_MUL,
      aluCtrl => ALU_CTRL_NOP,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Multiply signed high 16 (s2) x 32 (s1) bits, shift right 16.
    2#10010011# => (
      syntax_reg => "mpyhhs r#.%r1 = r#.%r2, r#.%r3                    ",
      syntax_imm => "mpyhhs r#.%r1 = r#.%r2, %id (= %ih)               ",
      valid => "00", -- TODO
      datapathCtrl => DP_CTRL_MUL,
      aluCtrl => ALU_CTRL_NOP,
      branchCtrl => BRANCH_CTRL_NOP
    ),
  
    ---------------------------------------------------------------------------
    -- MEM operations
    ---------------------------------------------------------------------------
    -- TODO: none of these are implemented yet.
    
    -- Load word from memory, send to link register.
    2#00001101# => (
      syntax_reg => "unknown                                           ",
      syntax_imm => "ldl l#.0 = %ih[r#.%r2]                            ",
      valid => "00", -- TODO
      datapathCtrl => DP_CTRL_MEM_LD_LINK,
      aluCtrl => ALU_CTRL_NOP,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Load word from memory.
    2#00010000# => (
      syntax_reg => "unknown                                           ",
      syntax_imm => "ldw r#.%r1 = %ih[r#.%r2]                          ",
      valid => "00", -- TODO
      datapathCtrl => DP_CTRL_MEM_LD_GP,
      aluCtrl => ALU_CTRL_NOP,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Load signed halfword from memory.
    2#00010001# => (
      syntax_reg => "unknown                                           ",
      syntax_imm => "ldh r#.%r1 = %ih[r#.%r2]                          ",
      valid => "00", -- TODO
      datapathCtrl => DP_CTRL_MEM_LD_GP,
      aluCtrl => ALU_CTRL_NOP,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Load unsigned halfword from memory.
    2#00010010# => (
      syntax_reg => "unknown                                           ",
      syntax_imm => "ldhu r#.%r1 = %ih[r#.%r2]                         ",
      valid => "00", -- TODO
      datapathCtrl => DP_CTRL_MEM_LD_GP,
      aluCtrl => ALU_CTRL_NOP,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Load signed byte from memory.
    2#00010011# => (
      syntax_reg => "unknown                                           ",
      syntax_imm => "ldb r#.%r1 = %ih[r#.%r2]                          ",
      valid => "00", -- TODO
      datapathCtrl => DP_CTRL_MEM_LD_GP,
      aluCtrl => ALU_CTRL_NOP,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Load unsigned byte from memory.
    2#00010100# => (
      syntax_reg => "unknown                                           ",
      syntax_imm => "ldbu r#.%r1 = %ih[r#.%r2]                         ",
      valid => "00", -- TODO
      datapathCtrl => DP_CTRL_MEM_LD_GP,
      aluCtrl => ALU_CTRL_NOP,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Store word in memory, from link register.
    2#00001110# => (
      syntax_reg => "unknown                                           ",
      syntax_imm => "stl %ih[r#.%r2] = l#.0                            ",
      valid => "00", -- TODO
      datapathCtrl => DP_CTRL_MEM_ST_LINK,
      aluCtrl => ALU_CTRL_NOP,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Store word in memory.
    2#00010101# => (
      syntax_reg => "unknown                                           ",
      syntax_imm => "stw %ih[r#.%r2] = r#.%r1                          ",
      valid => "00", -- TODO
      datapathCtrl => DP_CTRL_MEM_ST_GP,
      aluCtrl => ALU_CTRL_NOP,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Store halfword in memory.
    2#00010110# => (
      syntax_reg => "unknown                                           ",
      syntax_imm => "sth %ih[r#.%r2] = r#.%r1                          ",
      valid => "00", -- TODO
      datapathCtrl => DP_CTRL_MEM_ST_GP,
      aluCtrl => ALU_CTRL_NOP,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    -- Store byte in memory.
    2#00010111# => (
      syntax_reg => "unknown                                           ",
      syntax_imm => "stb %ih[r#.%r2] = r#.%r1                          ",
      valid => "00", -- TODO
      datapathCtrl => DP_CTRL_MEM_ST_GP,
      aluCtrl => ALU_CTRL_NOP,
      branchCtrl => BRANCH_CTRL_NOP
    ),
    
    ---------------------------------------------------------------------------
    -- Deprecated/not yet implemented instructions
    ---------------------------------------------------------------------------
    --constant INTR_SEND  : std_logic_vector(7 downto 0) := "00101010";
    2#00101010# => opcodeTableEntry_default,
    
    --constant INTR_RECV  : std_logic_vector(7 downto 0) := "00101011";
    2#00101011# => opcodeTableEntry_default,
    
    --constant VCR_WRITE  : std_logic_vector(7 downto 0) := "00101110";
    2#00101110# => opcodeTableEntry_default,
    
    --constant VCR_READ   : std_logic_vector(7 downto 0) := "00101111";
    2#00101111# => opcodeTableEntry_default,
    
    -- All other instructions are invalid.
    others => opcodeTableEntry_default
  );
  
end rvex_opcode_pkg;

package body rvex_opcode_pkg is
end rvex_opcode_pkg;
