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

--=============================================================================
-- This package specifies the control signal encoding for the FPU.
-------------------------------------------------------------------------------
package core_opcodeFpu_pkg is
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- Enumerations
  -----------------------------------------------------------------------------
  -- Adder unit control signal
  type fpuAddOp_type is (
    ADD,
    SUBTRACT
  );

  -- Compare unit control signal
  type fpuCmpOp_type is
    -- EQual, Not Equal
    EQ,
    NE,

    -- Less Than, Less than or Equal
    LT,
    LE,

    -- Greater Than, Greater than or Equal
    GT,
    GE
  );
  
  -----------------------------------------------------------------------------
  -- FPU control signal record
  -----------------------------------------------------------------------------
  type fpuCtrlSignals_type is record

    -- When this instruction is executed on a lane without the required unit,
    -- an invalid instruction exception will be raised.
    isFAddInstruction           : std_logic;
    isFCompareInstruction       : std_logic;
    isFConvfiInstruction        : std_logic;
    isFConvifInstruction        : std_logic;
    isFMulInstruction           : std_logic;

    -- Adder and compare unit control signals
    addOp                       : fpuAddOp_type;
    cmpOp                       : fpuCmpOp_type;

    -- Whether conversion should be unsigned (high) or signed (low)
    unsignedOp                  : std_logic;
    
  end record;
  
  -- Array type.
  type fpuCtrlSignals_array is array (natural range <>) of fpuCtrlSignals_type;
  
  -- Default value.
  constant FPU_CTRL_NOP         : fpuCtrlSignals_type := (
    isFAddInstruction           => '0',
    isFCompareInstruction       => '0',
    isFConvfiInstruction        => '0',
    isFConvifInstruction        => '0',
    isFMulInstruction           => '0',

    addOp                       => ADD,
    cmpOp                       => EQ,
    unsignedOp                  => '0'
  );
  
end core_opcodeFpu_pkg;

package body core_opcodeFpu_pkg is
end core_opcodeFpu_pkg;
