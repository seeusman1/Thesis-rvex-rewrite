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

--=============================================================================
-- This package specifies the control signal encoding for the ALU.
-------------------------------------------------------------------------------
package rvex_opcodeAlu_pkg is
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- Enumerations for muxes
  -----------------------------------------------------------------------------
  -- Operand 1 pre-add/logic operation.
  type aluOp1Mux_type is (
    
    -- Sign/zero extend operand from 32 bits (the adder is 33 bits to allow for
    -- unsigned comparisons), 16 bits or 8 bits. Whether to sign or zero extend
    -- is selected based on the unsignedOp control signal.
    EXTEND32,
    EXTEND16,
    EXTEND8,
    
    -- Same as EXTEND32, but also bitwise-complements the output.
    EXTEND32INV,
    
    -- Instead of performing sign extension, shift the operand left by a fixed
    -- number of bits.
    SHL1,
    SHL2,
    SHL3,
    SHL4
    
  );
  
  -- Operand 2 pre-add/logic operation.
  type aluOp2Mux_type is (
    
    -- Sign/zero extend operand from 32 bits (the adder is 33 bits to allow for
    -- unsigned comparisons) Whether to sign or zero extend is selected based
    -- on the unsignedOp control signal.
    EXTEND32,
    
    -- Force the operand to zero for single operand operations.
    ZERO
    
  );
  
  -- Branch register operand operation.
  type aluOpBrMux_type is (
    
    -- Let the branch register operand pass through without modification or
    -- inverted.
    PASS,
    INVERT,
    
    -- Override the branch register operand (like an immediate).
    TRUE,
    FALSE
    
  );
  
  -- ALU bitwise operation unit operation.
  type aluBitwiseOp_type is (
    
    -- The usual bitwise operations.
    BITW_AND,
    BITW_OR,
    BITW_XOR,
    
    -- Set bit operation. This sets the bit indexed by operand 2 to the branch
    -- input value. In addition, this unit will output the original bit in
    -- operand 1 indexed by operand 2.
    SET_BIT
    
  );
  
  -- Branch result selection.
  type aluBrResultMux_type is (
    
    -- Let the output from the branch operand selection mux pass through
    -- without modification. Used in particular for SLCT and SLCTF.
    PASS,
    
    -- Boolean logic operations. These are performed on the complement of the
    -- compare unit outputs. Compare unit 1 must be configured to compare
    -- operand 1 with 0.
    LOGIC_AND,
    LOGIC_NAND,
    LOGIC_OR,
    LOGIC_NOR,
    
    -- Compare operations. These are performed on the carry output of the adder
    -- and the output of compare unit 1, which should be configured to compare
    -- with operand 2.
    CMP_EQ,
    CMP_NE,
    CMP_GT,
    CMP_GE,
    CMP_LT,
    CMP_LE,
    
    -- Adder carry out for ADDCG.
    CARRY_OUT,
    
    -- Bit test flag for TBIT and TBITF.
    TBIT,
    TBITF,
    
    -- Output for DIVS function.
    DIVS
    
  );
  
  -- Integer result selection.
  type aluIntResultMux_type is (
    
    -- Forward the result from the adder unit.
    ADDER,
    
    -- Forward the result from the bitwise operation unit.
    BITWISE,
    
    -- Forward the result from the shift unit.
    SHIFTER,
    
    -- Forward the result from the CLZ unit.
    CLZ,
    
    -- Output either operand 1 unchanged or operand 2 unchanged, based on the
    -- branch output. Used for the SLCT and MIN/MAX operations.
    OP_SEL,
    
    -- Forward the branch output as a 32 bit integer.
    BOOL
    
  );
  
  -----------------------------------------------------------------------------
  -- ALU control signal record
  -----------------------------------------------------------------------------
  type aluCtrlSignals_type is record
    
    -- Pre-add operand modification muxing.
    op1Mux                      : aluOp1Mux_type;
    op2Mux                      : aluOp2Mux_type;
    opBrMux                     : aluOpBrMux_type;
    
    -- Division step select input. When this is set, the behavior of some of
    -- the logic units is altered slightly to perform the division step
    -- operation.
    divs                        : std_logic;
    
    -- Whether this operation is unsigned (high) or signed (low). This controls
    -- whether to zero extend or sign extend when extension is needed.
    unsignedOp                  : std_logic;
    
    -- Selects the bitwise operation to perform.
    bitwiseOp                   : aluBitwiseOp_type;
    
    -- Control signal to the shift unit, to have it shift left instead of
    -- right. It does so by bit-swapping the input and output so the actual
    -- barrel shifter doesn't get duplicated.
    shiftLeft                   : std_logic;
    
    -- Control signal for compare unit 1. When this is high, the unit will
    -- compare operand 1 and operand 2 for CMP operations. When this is low,
    -- the unit will compare operand 1 with 0 for boolean operations.
    compare                     : std_logic;
    
    -- Output muxing.
    intResultMux                : aluIntResultMux_type;
    brResultMux                 : aluBrResultMux_type;
    
    -- Signals only used in simulation, determining which of the two outputs
    -- of the ALU is actually meaningful.
    intResultValid              : boolean;
    brResultValid               : boolean;
    
  end record;
  
  -- Array type.
  type aluCtrlSignals_array is array (natural range <>) of aluCtrlSignals_type;
  
  
  --===========================================================================
  -- ALU control signal specifications
  --===========================================================================
  
  -- Simply forward operand 1 and branch register values.
  constant ALU_CTRL_FWD_OP1     : aluCtrlSignals_type := (
    op1Mux                      => EXTEND32,
    op2Mux                      => ZERO,
    opBrMux                     => PASS,
    divs                        => '0',
    unsignedOp                  => '0',
    bitwiseOp                   => BITW_OR,
    shiftLeft                   => '0',
    compare                     => '0',
    intResultMux                => BITWISE,
    brResultMux                 => PASS,
    intResultValid              => true,
    brResultValid               => true
  );
  
  -- Default values for the branch unit control signals.
  constant ALU_CTRL_NOP         : aluCtrlSignals_type := ALU_CTRL_FWD_OP1;
  
  -----------------------------------------------------------------------------
  -- Adder operations
  -----------------------------------------------------------------------------
  -- 32 bit addition.
  constant ALU_CTRL_ADD         : aluCtrlSignals_type := (
    op1Mux                      => EXTEND32,
    op2Mux                      => EXTEND32,
    opBrMux                     => FALSE,
    divs                        => '0',
    unsignedOp                  => '0',
    bitwiseOp                   => BITW_AND,
    shiftLeft                   => '0',
    compare                     => '0',
    intResultMux                => ADDER,
    brResultMux                 => PASS,
    intResultValid              => true,
    brResultValid               => false
  );
  
  -- 32 bit addition, pre-shift operand 1 by 1 bit.
  constant ALU_CTRL_SH1ADD      : aluCtrlSignals_type := (
    op1Mux                      => SHL1,
    op2Mux                      => EXTEND32,
    opBrMux                     => FALSE,
    divs                        => '0',
    unsignedOp                  => '0',
    bitwiseOp                   => BITW_AND,
    shiftLeft                   => '0',
    compare                     => '0',
    intResultMux                => ADDER,
    brResultMux                 => PASS,
    intResultValid              => true,
    brResultValid               => false
  );
  
  -- 32 bit addition, pre-shift operand 1 by 2 bits.
  constant ALU_CTRL_SH2ADD      : aluCtrlSignals_type := (
    op1Mux                      => SHL2,
    op2Mux                      => EXTEND32,
    opBrMux                     => FALSE,
    divs                        => '0',
    unsignedOp                  => '0',
    bitwiseOp                   => BITW_AND,
    shiftLeft                   => '0',
    compare                     => '0',
    intResultMux                => ADDER,
    brResultMux                 => PASS,
    intResultValid              => true,
    brResultValid               => false
  );
  
  -- 32 bit addition, pre-shift operand 1 by 3 bits.
  constant ALU_CTRL_SH3ADD      : aluCtrlSignals_type := (
    op1Mux                      => SHL3,
    op2Mux                      => EXTEND32,
    opBrMux                     => FALSE,
    divs                        => '0',
    unsignedOp                  => '0',
    bitwiseOp                   => BITW_AND,
    shiftLeft                   => '0',
    compare                     => '0',
    intResultMux                => ADDER,
    brResultMux                 => PASS,
    intResultValid              => true,
    brResultValid               => false
  );
  
  -- 32 bit addition, pre-shift operand 1 by 4 bits.
  constant ALU_CTRL_SH4ADD      : aluCtrlSignals_type := (
    op1Mux                      => SHL4,
    op2Mux                      => EXTEND32,
    opBrMux                     => FALSE,
    divs                        => '0',
    unsignedOp                  => '0',
    bitwiseOp                   => BITW_AND,
    shiftLeft                   => '0',
    compare                     => '0',
    intResultMux                => ADDER,
    brResultMux                 => PASS,
    intResultValid              => true,
    brResultValid               => false
  );
  
  -- 32 bit subtraction (operand2 - operand1).
  constant ALU_CTRL_SUB         : aluCtrlSignals_type := (
    op1Mux                      => EXTEND32INV,
    op2Mux                      => EXTEND32,
    opBrMux                     => TRUE,
    divs                        => '0',
    unsignedOp                  => '0',
    bitwiseOp                   => BITW_AND,
    shiftLeft                   => '0',
    compare                     => '0',
    intResultMux                => ADDER,
    brResultMux                 => PASS,
    intResultValid              => true,
    brResultValid               => false
  );
  
  -- 32 bit addition with carry in and out.
  constant ALU_CTRL_ADDCG       : aluCtrlSignals_type := (
    op1Mux                      => EXTEND32,
    op2Mux                      => EXTEND32,
    opBrMux                     => PASS,
    divs                        => '0',
    unsignedOp                  => '1',
    bitwiseOp                   => BITW_AND,
    shiftLeft                   => '0',
    compare                     => '0',
    intResultMux                => ADDER,
    brResultMux                 => CARRY_OUT,
    intResultValid              => true,
    brResultValid               => true
  );
  
  -- Division step:
  --   tmp := op1 << 1 | opBr
  --   result <= op1(31) ? (tmp + op2) : (tmp - op2)
  --   branch result <= op1(31)
  constant ALU_CTRL_DIVS        : aluCtrlSignals_type := (
    op1Mux                      => SHL1,
    op2Mux                      => EXTEND32,
    opBrMux                     => PASS,
    divs                        => '1',
    unsignedOp                  => '0',
    bitwiseOp                   => BITW_AND,
    shiftLeft                   => '0',
    compare                     => '0',
    intResultMux                => ADDER,
    brResultMux                 => DIVS,
    intResultValid              => true,
    brResultValid               => true
  );
  
  -----------------------------------------------------------------------------
  -- Bitwise operations
  -----------------------------------------------------------------------------
  -- result := op1 & op2
  constant ALU_CTRL_AND         : aluCtrlSignals_type := (
    op1Mux                      => EXTEND32,
    op2Mux                      => EXTEND32,
    opBrMux                     => FALSE,
    divs                        => '0',
    unsignedOp                  => '0',
    bitwiseOp                   => BITW_AND,
    shiftLeft                   => '0',
    compare                     => '0',
    intResultMux                => BITWISE,
    brResultMux                 => PASS,
    intResultValid              => true,
    brResultValid               => false
  );
  
  -- result := ~op1 & op2
  constant ALU_CTRL_ANDC        : aluCtrlSignals_type := (
    op1Mux                      => EXTEND32INV,
    op2Mux                      => EXTEND32,
    opBrMux                     => FALSE,
    divs                        => '0',
    unsignedOp                  => '0',
    bitwiseOp                   => BITW_AND,
    shiftLeft                   => '0',
    compare                     => '0',
    intResultMux                => BITWISE,
    brResultMux                 => PASS,
    intResultValid              => true,
    brResultValid               => false
  );
  
  -- result := op1 | op2
  constant ALU_CTRL_OR          : aluCtrlSignals_type := (
    op1Mux                      => EXTEND32,
    op2Mux                      => EXTEND32,
    opBrMux                     => FALSE,
    divs                        => '0',
    unsignedOp                  => '0',
    bitwiseOp                   => BITW_OR,
    shiftLeft                   => '0',
    compare                     => '0',
    intResultMux                => BITWISE,
    brResultMux                 => PASS,
    intResultValid              => true,
    brResultValid               => false
  );
  
  -- result := ~op1 | op2
  constant ALU_CTRL_ORC         : aluCtrlSignals_type := (
    op1Mux                      => EXTEND32INV,
    op2Mux                      => EXTEND32,
    opBrMux                     => FALSE,
    divs                        => '0',
    unsignedOp                  => '0',
    bitwiseOp                   => BITW_OR,
    shiftLeft                   => '0',
    compare                     => '0',
    intResultMux                => BITWISE,
    brResultMux                 => PASS,
    intResultValid              => true,
    brResultValid               => false
  );
  
  -- result := op1 ^ op2
  constant ALU_CTRL_XOR         : aluCtrlSignals_type := (
    op1Mux                      => EXTEND32,
    op2Mux                      => EXTEND32,
    opBrMux                     => FALSE,
    divs                        => '0',
    unsignedOp                  => '0',
    bitwiseOp                   => BITW_XOR,
    shiftLeft                   => '0',
    compare                     => '0',
    intResultMux                => BITWISE,
    brResultMux                 => PASS,
    intResultValid              => true,
    brResultValid               => false
  );
  
  -- result := op1 | (1 << op2)
  constant ALU_CTRL_SBIT        : aluCtrlSignals_type := (
    op1Mux                      => EXTEND32,
    op2Mux                      => EXTEND32,
    opBrMux                     => TRUE,
    divs                        => '0',
    unsignedOp                  => '0',
    bitwiseOp                   => SET_BIT,
    shiftLeft                   => '0',
    compare                     => '0',
    intResultMux                => BITWISE,
    brResultMux                 => PASS,
    intResultValid              => true,
    brResultValid               => false
  );
  
  -- result := op1 & ~(1 << op2)
  constant ALU_CTRL_SBITF       : aluCtrlSignals_type := (
    op1Mux                      => EXTEND32,
    op2Mux                      => EXTEND32,
    opBrMux                     => FALSE,
    divs                        => '0',
    unsignedOp                  => '0',
    bitwiseOp                   => SET_BIT,
    shiftLeft                   => '0',
    compare                     => '0',
    intResultMux                => BITWISE,
    brResultMux                 => PASS,
    intResultValid              => true,
    brResultValid               => false
  );
  
  -- result := op1 & (1 << op2) != 0
  constant ALU_CTRL_TBIT        : aluCtrlSignals_type := (
    op1Mux                      => EXTEND32,
    op2Mux                      => EXTEND32,
    opBrMux                     => FALSE,
    divs                        => '0',
    unsignedOp                  => '0',
    bitwiseOp                   => BITW_AND,
    shiftLeft                   => '0',
    compare                     => '0',
    intResultMux                => BOOL,
    brResultMux                 => TBIT,
    intResultValid              => true,
    brResultValid               => true
  );
  
  -- result := op1 & (1 << op2) == 0
  constant ALU_CTRL_TBITF       : aluCtrlSignals_type := (
    op1Mux                      => EXTEND32,
    op2Mux                      => EXTEND32,
    opBrMux                     => FALSE,
    divs                        => '0',
    unsignedOp                  => '0',
    bitwiseOp                   => BITW_AND,
    shiftLeft                   => '0',
    compare                     => '0',
    intResultMux                => BOOL,
    brResultMux                 => TBITF,
    intResultValid              => true,
    brResultValid               => true
  );
  
  -----------------------------------------------------------------------------
  -- Boolean logic operations
  -----------------------------------------------------------------------------
  -- result := op1 && op2;
  constant ALU_CTRL_ANDL        : aluCtrlSignals_type := (
    op1Mux                      => EXTEND32,
    op2Mux                      => EXTEND32,
    opBrMux                     => FALSE,
    divs                        => '0',
    unsignedOp                  => '0',
    bitwiseOp                   => BITW_AND,
    shiftLeft                   => '0',
    compare                     => '0',
    intResultMux                => BOOL,
    brResultMux                 => LOGIC_AND,
    intResultValid              => true,
    brResultValid               => true
  );
  
  -- result := op1 || op2;
  constant ALU_CTRL_ORL         : aluCtrlSignals_type := (
    op1Mux                      => EXTEND32,
    op2Mux                      => EXTEND32,
    opBrMux                     => FALSE,
    divs                        => '0',
    unsignedOp                  => '0',
    bitwiseOp                   => BITW_AND,
    shiftLeft                   => '0',
    compare                     => '0',
    intResultMux                => BOOL,
    brResultMux                 => LOGIC_OR,
    intResultValid              => true,
    brResultValid               => true
  );
  
  -- result := !(op1 && op2);
  constant ALU_CTRL_NANDL       : aluCtrlSignals_type := (
    op1Mux                      => EXTEND32,
    op2Mux                      => EXTEND32,
    opBrMux                     => FALSE,
    divs                        => '0',
    unsignedOp                  => '0',
    bitwiseOp                   => BITW_AND,
    shiftLeft                   => '0',
    compare                     => '0',
    intResultMux                => BOOL,
    brResultMux                 => LOGIC_NAND,
    intResultValid              => true,
    brResultValid               => true
  );
  
  -- result := !(op1 || op2);
  constant ALU_CTRL_NORL        : aluCtrlSignals_type := (
    op1Mux                      => EXTEND32,
    op2Mux                      => EXTEND32,
    opBrMux                     => FALSE,
    divs                        => '0',
    unsignedOp                  => '0',
    bitwiseOp                   => BITW_AND,
    shiftLeft                   => '0',
    compare                     => '0',
    intResultMux                => BOOL,
    brResultMux                 => LOGIC_NOR,
    intResultValid              => true,
    brResultValid               => true
  );
  
  -----------------------------------------------------------------------------
  -- Selection operations
  -----------------------------------------------------------------------------
  -- Select maximum value, signed arithmetic.
  constant ALU_CTRL_MAX         : aluCtrlSignals_type := (
    op1Mux                      => EXTEND32INV,
    op2Mux                      => EXTEND32,
    opBrMux                     => TRUE,
    divs                        => '0',
    unsignedOp                  => '0',
    bitwiseOp                   => BITW_AND,
    shiftLeft                   => '0',
    compare                     => '0',
    intResultMux                => OP_SEL,
    brResultMux                 => CMP_GE,
    intResultValid              => true,
    brResultValid               => false
  );
  
  -- Select maximum value, unsigned arithmetic.
  constant ALU_CTRL_MAXU        : aluCtrlSignals_type := (
    op1Mux                      => EXTEND32INV,
    op2Mux                      => EXTEND32,
    opBrMux                     => TRUE,
    divs                        => '0',
    unsignedOp                  => '1',
    bitwiseOp                   => BITW_AND,
    shiftLeft                   => '0',
    compare                     => '0',
    intResultMux                => OP_SEL,
    brResultMux                 => CMP_GE,
    intResultValid              => true,
    brResultValid               => false
  );
  
  -- Select minimum value, signed arithmetic.
  constant ALU_CTRL_MIN         : aluCtrlSignals_type := (
    op1Mux                      => EXTEND32INV,
    op2Mux                      => EXTEND32,
    opBrMux                     => TRUE,
    divs                        => '0',
    unsignedOp                  => '0',
    bitwiseOp                   => BITW_AND,
    shiftLeft                   => '0',
    compare                     => '0',
    intResultMux                => OP_SEL,
    brResultMux                 => CMP_LE,
    intResultValid              => true,
    brResultValid               => false
  );
  
  -- Select minimum value, unsigned arithmetic.
  constant ALU_CTRL_MINU        : aluCtrlSignals_type := (
    op1Mux                      => EXTEND32INV,
    op2Mux                      => EXTEND32,
    opBrMux                     => TRUE,
    divs                        => '0',
    unsignedOp                  => '1',
    bitwiseOp                   => BITW_AND,
    shiftLeft                   => '0',
    compare                     => '0',
    intResultMux                => OP_SEL,
    brResultMux                 => CMP_LE,
    intResultValid              => true,
    brResultValid               => false
  );
  
  -- Select operand1 when branch input is high, operand2 when low.
  constant ALU_CTRL_SLCT        : aluCtrlSignals_type := (
    op1Mux                      => EXTEND32,
    op2Mux                      => EXTEND32,
    opBrMux                     => PASS,
    divs                        => '0',
    unsignedOp                  => '0',
    bitwiseOp                   => BITW_AND,
    shiftLeft                   => '0',
    compare                     => '0',
    intResultMux                => OP_SEL,
    brResultMux                 => PASS,
    intResultValid              => true,
    brResultValid               => false
  );
  
  -- Select operand2 when branch input is high, operand1 when low.
  constant ALU_CTRL_SLCTF       : aluCtrlSignals_type := (
    op1Mux                      => EXTEND32,
    op2Mux                      => EXTEND32,
    opBrMux                     => INVERT,
    divs                        => '0',
    unsignedOp                  => '0',
    bitwiseOp                   => BITW_AND,
    shiftLeft                   => '0',
    compare                     => '0',
    intResultMux                => OP_SEL,
    brResultMux                 => PASS,
    intResultValid              => true,
    brResultValid               => false
  );
  
  -----------------------------------------------------------------------------
  -- Barrel shift operations
  -----------------------------------------------------------------------------
  -- Logical/arithmetic shift left.
  constant ALU_CTRL_SHL         : aluCtrlSignals_type := (
    op1Mux                      => EXTEND32,
    op2Mux                      => EXTEND32,
    opBrMux                     => FALSE,
    divs                        => '0',
    unsignedOp                  => '1',
    bitwiseOp                   => BITW_AND,
    shiftLeft                   => '1',
    compare                     => '0',
    intResultMux                => SHIFTER,
    brResultMux                 => PASS,
    intResultValid              => true,
    brResultValid               => false
  );
  
  -- Signed arithmetic shift right.
  constant ALU_CTRL_SHR         : aluCtrlSignals_type := (
    op1Mux                      => EXTEND32,
    op2Mux                      => EXTEND32,
    opBrMux                     => FALSE,
    divs                        => '0',
    unsignedOp                  => '0',
    bitwiseOp                   => BITW_AND,
    shiftLeft                   => '0',
    compare                     => '0',
    intResultMux                => SHIFTER,
    brResultMux                 => PASS,
    intResultValid              => true,
    brResultValid               => false
  );
  
  -- Unsigned arithmetic/logical shift right.
  constant ALU_CTRL_SHRU        : aluCtrlSignals_type := (
    op1Mux                      => EXTEND32,
    op2Mux                      => EXTEND32,
    opBrMux                     => FALSE,
    divs                        => '0',
    unsignedOp                  => '1',
    bitwiseOp                   => BITW_AND,
    shiftLeft                   => '0',
    compare                     => '0',
    intResultMux                => SHIFTER,
    brResultMux                 => PASS,
    intResultValid              => true,
    brResultValid               => false
  );
  
  -----------------------------------------------------------------------------
  -- Count leading zeros operations
  -----------------------------------------------------------------------------
  -- result := countLeadingZeros(op1)
  constant ALU_CTRL_CLZ         : aluCtrlSignals_type := (
    op1Mux                      => EXTEND32,
    op2Mux                      => EXTEND32,
    opBrMux                     => FALSE,
    divs                        => '0',
    unsignedOp                  => '0',
    bitwiseOp                   => BITW_AND,
    shiftLeft                   => '0',
    compare                     => '0',
    intResultMux                => CLZ,
    brResultMux                 => PASS,
    intResultValid              => true,
    brResultValid               => false
  );
  
  -----------------------------------------------------------------------------
  -- Zero/sign extension operations
  -----------------------------------------------------------------------------
  -- Sign extend byte to word.
  constant ALU_CTRL_SXTB        : aluCtrlSignals_type := (
    op1Mux                      => EXTEND8,
    op2Mux                      => ZERO,
    opBrMux                     => FALSE,
    divs                        => '0',
    unsignedOp                  => '0',
    bitwiseOp                   => BITW_AND,
    shiftLeft                   => '0',
    compare                     => '0',
    intResultMux                => ADDER,
    brResultMux                 => PASS,
    intResultValid              => true,
    brResultValid               => false
  );
  
  -- Sign extend halfword to word.
  constant ALU_CTRL_SXTH        : aluCtrlSignals_type := (
    op1Mux                      => EXTEND16,
    op2Mux                      => ZERO,
    opBrMux                     => FALSE,
    divs                        => '0',
    unsignedOp                  => '0',
    bitwiseOp                   => BITW_AND,
    shiftLeft                   => '0',
    compare                     => '0',
    intResultMux                => ADDER,
    brResultMux                 => PASS,
    intResultValid              => true,
    brResultValid               => false
  );
  
  -- Zero extend byte to word.
  constant ALU_CTRL_ZXTB        : aluCtrlSignals_type := (
    op1Mux                      => EXTEND8,
    op2Mux                      => ZERO,
    opBrMux                     => FALSE,
    divs                        => '0',
    unsignedOp                  => '1',
    bitwiseOp                   => BITW_AND,
    shiftLeft                   => '0',
    compare                     => '0',
    intResultMux                => ADDER,
    brResultMux                 => PASS,
    intResultValid              => true,
    brResultValid               => false
  );
  
  -- Zero extend halfword to word.
  constant ALU_CTRL_ZXTH        : aluCtrlSignals_type := (
    op1Mux                      => EXTEND16,
    op2Mux                      => ZERO,
    opBrMux                     => FALSE,
    divs                        => '0',
    unsignedOp                  => '1',
    bitwiseOp                   => BITW_AND,
    shiftLeft                   => '0',
    compare                     => '0',
    intResultMux                => ADDER,
    brResultMux                 => PASS,
    intResultValid              => true,
    brResultValid               => false
  );
  
  -----------------------------------------------------------------------------
  -- Comparison operations
  -----------------------------------------------------------------------------
  -- result := operand1 == operand2
  constant ALU_CTRL_CMPEQ       : aluCtrlSignals_type := (
    op1Mux                      => EXTEND32INV,
    op2Mux                      => EXTEND32,
    opBrMux                     => TRUE,
    divs                        => '0',
    unsignedOp                  => '0',
    bitwiseOp                   => BITW_AND,
    shiftLeft                   => '0',
    compare                     => '1',
    intResultMux                => BOOL,
    brResultMux                 => CMP_EQ,
    intResultValid              => true,
    brResultValid               => true
  );
  
  -- result := operand1 != operand2
  constant ALU_CTRL_CMPNE       : aluCtrlSignals_type := (
    op1Mux                      => EXTEND32INV,
    op2Mux                      => EXTEND32,
    opBrMux                     => TRUE,
    divs                        => '0',
    unsignedOp                  => '0',
    bitwiseOp                   => BITW_AND,
    shiftLeft                   => '0',
    compare                     => '1',
    intResultMux                => BOOL,
    brResultMux                 => CMP_NE,
    intResultValid              => true,
    brResultValid               => true
  );
  
  -- result := operand1 >= operand2 (signed)
  constant ALU_CTRL_CMPGE       : aluCtrlSignals_type := (
    op1Mux                      => EXTEND32INV,
    op2Mux                      => EXTEND32,
    opBrMux                     => TRUE,
    divs                        => '0',
    unsignedOp                  => '0',
    bitwiseOp                   => BITW_AND,
    shiftLeft                   => '0',
    compare                     => '1',
    intResultMux                => BOOL,
    brResultMux                 => CMP_GE,
    intResultValid              => true,
    brResultValid               => true
  );
  
  -- result := operand1 >= operand2 (unsigned)
  constant ALU_CTRL_CMPGEU      : aluCtrlSignals_type := (
    op1Mux                      => EXTEND32INV,
    op2Mux                      => EXTEND32,
    opBrMux                     => TRUE,
    divs                        => '0',
    unsignedOp                  => '1',
    bitwiseOp                   => BITW_AND,
    shiftLeft                   => '0',
    compare                     => '1',
    intResultMux                => BOOL,
    brResultMux                 => CMP_GE,
    intResultValid              => true,
    brResultValid               => true
  );
  
  -- result := operand1 > operand2 (signed)
  constant ALU_CTRL_CMPGT       : aluCtrlSignals_type := (
    op1Mux                      => EXTEND32INV,
    op2Mux                      => EXTEND32,
    opBrMux                     => TRUE,
    divs                        => '0',
    unsignedOp                  => '0',
    bitwiseOp                   => BITW_AND,
    shiftLeft                   => '0',
    compare                     => '1',
    intResultMux                => BOOL,
    brResultMux                 => CMP_GT,
    intResultValid              => true,
    brResultValid               => true
  );
  
  -- result := operand1 > operand2 (unsigned)
  constant ALU_CTRL_CMPGTU      : aluCtrlSignals_type := (
    op1Mux                      => EXTEND32INV,
    op2Mux                      => EXTEND32,
    opBrMux                     => TRUE,
    divs                        => '0',
    unsignedOp                  => '1',
    bitwiseOp                   => BITW_AND,
    shiftLeft                   => '0',
    compare                     => '1',
    intResultMux                => BOOL,
    brResultMux                 => CMP_GT,
    intResultValid              => true,
    brResultValid               => true
  );
  
  -- result := operand1 <= operand2 (signed)
  constant ALU_CTRL_CMPLE       : aluCtrlSignals_type := (
    op1Mux                      => EXTEND32INV,
    op2Mux                      => EXTEND32,
    opBrMux                     => TRUE,
    divs                        => '0',
    unsignedOp                  => '0',
    bitwiseOp                   => BITW_AND,
    shiftLeft                   => '0',
    compare                     => '1',
    intResultMux                => BOOL,
    brResultMux                 => CMP_LE,
    intResultValid              => true,
    brResultValid               => true
  );
  
  -- result := operand1 <= operand2 (unsigned)
  constant ALU_CTRL_CMPLEU      : aluCtrlSignals_type := (
    op1Mux                      => EXTEND32INV,
    op2Mux                      => EXTEND32,
    opBrMux                     => TRUE,
    divs                        => '0',
    unsignedOp                  => '1',
    bitwiseOp                   => BITW_AND,
    shiftLeft                   => '0',
    compare                     => '1',
    intResultMux                => BOOL,
    brResultMux                 => CMP_LE,
    intResultValid              => true,
    brResultValid               => true
  );
  
  -- result := operand1 < operand2 (signed)
  constant ALU_CTRL_CMPLT       : aluCtrlSignals_type := (
    op1Mux                      => EXTEND32INV,
    op2Mux                      => EXTEND32,
    opBrMux                     => TRUE,
    divs                        => '0',
    unsignedOp                  => '0',
    bitwiseOp                   => BITW_AND,
    shiftLeft                   => '0',
    compare                     => '1',
    intResultMux                => BOOL,
    brResultMux                 => CMP_LT,
    intResultValid              => true,
    brResultValid               => true
  );
  
  -- result := operand1 < operand2 (unsigned)
  constant ALU_CTRL_CMPLTU      : aluCtrlSignals_type := (
    op1Mux                      => EXTEND32INV,
    op2Mux                      => EXTEND32,
    opBrMux                     => TRUE,
    divs                        => '0',
    unsignedOp                  => '1',
    bitwiseOp                   => BITW_AND,
    shiftLeft                   => '0',
    compare                     => '1',
    intResultMux                => BOOL,
    brResultMux                 => CMP_LT,
    intResultValid              => true,
    brResultValid               => true
  );
  
  
end rvex_opcodeAlu_pkg;

package body rvex_opcodeAlu_pkg is
end rvex_opcodeAlu_pkg;
