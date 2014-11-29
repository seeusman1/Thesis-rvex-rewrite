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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package opcode_pkg_orig is

  --------------------------------------------------------------------------------
  -- Opcodes
  --------------------------------------------------------------------------------
  constant LOGIC_OP : std_logic_vector(7 downto 0) := "010-----";  -- LOGIC operation
  constant MUL_OP   : std_logic_vector(7 downto 0) := "0000----";  -- MUL operation
  constant CTRL_OP  : std_logic_vector(7 downto 0) := "00100---";  -- CTRL operation
  constant MEM_OP   : std_logic_vector(7 downto 0) := "00010---";  -- MEM operation

  constant STOP : std_logic_vector(7 downto 0) := "00101000";  -- STOP operation
  constant NOP  : std_logic_vector(7 downto 0) := "01100000";  -- No operation

  -- ALU opcodes (integer arithmetic operations)
  constant ALU_ADD    : std_logic_vector(7 downto 0) := "01100010";  -- Add
  constant ALU_AND    : std_logic_vector(7 downto 0) := "01100011";  -- Bitwise AND
  constant ALU_ANDC   : std_logic_vector(7 downto 0) := "01100100";  -- Bitwise complement and AND
  constant ALU_MAX    : std_logic_vector(7 downto 0) := "01100101";  -- Maximum signed
  constant ALU_MAXU   : std_logic_vector(7 downto 0) := "01100110";  -- Maximum unsigned
  constant ALU_MIN    : std_logic_vector(7 downto 0) := "01100111";  -- Minimum signed
  constant ALU_MINU   : std_logic_vector(7 downto 0) := "01101000";  -- Minimum unsigned
  constant ALU_OR     : std_logic_vector(7 downto 0) := "01101001";  -- Bitwise OR
  constant ALU_ORC    : std_logic_vector(7 downto 0) := "01101010";  -- Bitwise complement and OR
  constant ALU_SH1ADD : std_logic_vector(7 downto 0) := "01101011";  -- Shift left 1 and add
  constant ALU_SH2ADD : std_logic_vector(7 downto 0) := "01101100";  -- Shift left 2 and add
  constant ALU_SH3ADD : std_logic_vector(7 downto 0) := "01101101";  -- Shift left 3 and add
  constant ALU_SH4ADD : std_logic_vector(7 downto 0) := "01101110";  -- Shift left 4 and add
  constant ALU_SHL    : std_logic_vector(7 downto 0) := "01101111";  -- Shift left

  constant ALU_SHR  : std_logic_vector(7 downto 0) := "00011000";  -- Shift right signed
  constant ALU_SHRU : std_logic_vector(7 downto 0) := "00011001";  -- Shift right unsigned
  constant ALU_SUB  : std_logic_vector(7 downto 0) := "00011010";  -- Subtract
  constant ALU_SXTB : std_logic_vector(7 downto 0) := "00011011";  -- Sign extend byte
  constant ALU_SXTH : std_logic_vector(7 downto 0) := "00011100";  -- Sign extend half word
  constant ALU_ZXTB : std_logic_vector(7 downto 0) := "00011101";  -- Zero extend byte
  constant ALU_ZXTH : std_logic_vector(7 downto 0) := "00011110";  -- Zero extend half word
  constant ALU_XOR  : std_logic_vector(7 downto 0) := "00011111";  -- Bitwise XOR

  constant ALU_SBIT  : std_logic_vector(7 downto 0) := "00101100";  -- some sort of bit set
  constant ALU_SBITF : std_logic_vector(7 downto 0) := "00101101";  -- some other sort of bit set

  -- ALU opcodes (logical and select operations)
  --
  -- This block of operation can operate on a GR register or a BR registers as target.
  -- See syllable_layout.txt for more information
  constant ALU_CMPEQ  : std_logic_vector(7 downto 0) := "0100000-";  -- Compare: equal
  constant ALU_CMPGE  : std_logic_vector(7 downto 0) := "0100001-";  -- Compare: greater equal signed
  constant ALU_CMPGEU : std_logic_vector(7 downto 0) := "0100010-";  -- Compare: greater equal unsigned
  constant ALU_CMPGT  : std_logic_vector(7 downto 0) := "0100011-";  -- Compare: greater signed
  constant ALU_CMPGTU : std_logic_vector(7 downto 0) := "0100100-";  -- Compare: greater unsigned
  constant ALU_CMPLE  : std_logic_vector(7 downto 0) := "0100101-";  -- Compare: less than equal signed
  constant ALU_CMPLEU : std_logic_vector(7 downto 0) := "0100110-";  -- Compare: less than equal unsigned
  constant ALU_CMPLT  : std_logic_vector(7 downto 0) := "0100111-";  -- Compare: less than signed
  constant ALU_CMPLTU : std_logic_vector(7 downto 0) := "0101000-";  -- Compare: less than unsigned
  constant ALU_CMPNE  : std_logic_vector(7 downto 0) := "0101001-";  -- Compare: not equal
  constant ALU_NANDL  : std_logic_vector(7 downto 0) := "0101010-";  -- Logical NAND
  constant ALU_NORL   : std_logic_vector(7 downto 0) := "0101011-";  -- Logical NOR
  constant ALU_ORL    : std_logic_vector(7 downto 0) := "0101100-";  -- Logical OR
  constant ALU_ANDL   : std_logic_vector(7 downto 0) := "0101101-";  -- Logical AND
  constant ALU_TBIT   : std_logic_vector(7 downto 0) := "0101110-";  -- some sort of bit test
  constant ALU_TBITF  : std_logic_vector(7 downto 0) := "0101111-";  -- some other sort of bit test

  -- ALU opcodes (BR usage, see doc/syllable_layout.txt)
  constant ALU_ADDCG : std_logic_vector(7 downto 0) := "01111---";  -- Add with carry and generate carry.
  constant ALU_DIVS  : std_logic_vector(7 downto 0) := "01110---";  -- Division step with carry and generate carry
  constant ALU_SLCT  : std_logic_vector(7 downto 0) := "00111---";  -- Select s1 on true condition. (exception: opcode starts with 0)
  constant ALU_SLCTF : std_logic_vector(7 downto 0) := "00110---";  -- Select s1 on false condition. (exception: opcode starts with 0)

  -- Multiplier opcodes
  constant MUL_MPYLL  : std_logic_vector(7 downto 0) := "00000000";  -- Multiply signed low 16 x low 16 bits
  constant MUL_MPYLLU : std_logic_vector(7 downto 0) := "00000001";  -- Multiply unsigned low 16 x low 16 bits
  constant MUL_MPYLH  : std_logic_vector(7 downto 0) := "00000010";  -- Multiply signed low 16 (s1) x high 16 (s2) bits
  constant MUL_MPYLHU : std_logic_vector(7 downto 0) := "00000011";  -- Multiply unsigned low 16 (s1) x high 16 (s2) bits
  constant MUL_MPYHH  : std_logic_vector(7 downto 0) := "00000100";  -- Multiply signed high 16 x high 16 bits
  constant MUL_MPYHHU : std_logic_vector(7 downto 0) := "00000101";  -- Multiply unsigned high 16 x high 16 bits
  constant MUL_MPYL   : std_logic_vector(7 downto 0) := "00000110";  -- Multiply signed low 16 (s2) x 32 (s1) bits
  constant MUL_MPYLU  : std_logic_vector(7 downto 0) := "00000111";  -- Multiply unsigned low 16 (s2) x 32 (s1) bits
  constant MUL_MPYH   : std_logic_vector(7 downto 0) := "00001000";  -- Multiply signed high 16 (s2) x 32 (s1) bits
  constant MUL_MPYHU  : std_logic_vector(7 downto 0) := "00001001";  -- Multiply unsigned high 16 (s2) x 32 (s1) bits
  constant MUL_MPYHS  : std_logic_vector(7 downto 0) := "00001010";  -- Multiply signed high 16 (s2) x 32 (s1) bits, shift left 16

--ST200 addition:
  constant CLZ		    : std_logic_vector(7 downto 0) := "10010001";
  constant MUL_MPYLHUS  : std_logic_vector(7 downto 0) := "10010010";  -- Multiply signed low 16 (s2) x 32 (s1) bits, shift right 32
  constant MUL_MPYHHS   : std_logic_vector(7 downto 0) := "10010011";  -- Multiply signed high 16 (s2) x 32 (s1) bits, shift right 16

  constant LINK_MOVE_TO   : std_logic_vector(7 downto 0) := "00001011";
  constant LINK_MOVE_FROM : std_logic_vector(7 downto 0) := "00001100";
  constant LINK_LOAD      : std_logic_vector(7 downto 0) := "00001101";
  constant LINK_STORE     : std_logic_vector(7 downto 0) := "00001110";
  

  -- Control opcodes
  --
  -- NOTE: igoto and icall are overloaded by goto and call, as mentioned on the VEX forum at
  -- http://www.vliw.org/vex/viewtopic.php?t=52
  constant CTRL_GOTO   : std_logic_vector(7 downto 0) := "00100000";  -- Unconditional relative jump
  constant CTRL_IGOTO  : std_logic_vector(7 downto 0) := "00100001";  -- Unconditional absolute indirect jump to link register
  constant CTRL_CALL   : std_logic_vector(7 downto 0) := "00100010";  -- Unconditional relative call
  constant CTRL_ICALL  : std_logic_vector(7 downto 0) := "00100011";  -- Unconditional absolute indirect call to link register
  constant CTRL_BR     : std_logic_vector(7 downto 0) := "00100100";  -- Conditional relative branch on true condition
  constant CTRL_BRF    : std_logic_vector(7 downto 0) := "00100101";  -- Conditional relative branch on false condition
  constant CTRL_RETURN : std_logic_vector(7 downto 0) := "00100110";  -- Pop stack frame and goto link register
  constant CTRL_RFI    : std_logic_vector(7 downto 0) := "00100111";  -- Return from interrupt

  constant TRAP		   : std_logic_vector(7 downto 0) := "10010000";

--processor ctrl reg (now, only interrupts. might be expanded in the future)
  constant VCR_WRITE      : std_logic_vector(7 downto 0) := "00101110";
  constant VCR_READ       : std_logic_vector(7 downto 0) := "00101111";
  
  
  -- Inter-cluster opcodes
  --
  -- NOTE: These opcodes aren't used in the current r-VEX implementation,
  --       because it has only one cluster. The opcode definitions are
  --       here for possible future use.
  --
  constant INTR_SEND : std_logic_vector(7 downto 0) := "00101010";  -- Send s1 to the path identified by im
  constant INTR_RECV : std_logic_vector(7 downto 0) := "00101011";  -- Assigns the value from the path identified by im to t

  -- Memory opcodes
  constant MEM_LDW  : std_logic_vector(7 downto 0) := "00010000";  -- Load word
  constant MEM_LDH  : std_logic_vector(7 downto 0) := "00010001";  -- Load halfword signed
  constant MEM_LDHU : std_logic_vector(7 downto 0) := "00010010";  -- Load halfword unsigned
  constant MEM_LDB  : std_logic_vector(7 downto 0) := "00010011";  -- Load byte signed
  constant MEM_LDBU : std_logic_vector(7 downto 0) := "00010100";  -- Load byte unsigned
  constant MEM_STW  : std_logic_vector(7 downto 0) := "00010101";  -- Store word
  constant MEM_STH  : std_logic_vector(7 downto 0) := "00010110";  -- Store halfword
  constant MEM_STB  : std_logic_vector(7 downto 0) := "00010111";  -- Store byte


  -- Syllable is preceding syllable with high part of long immediate
  constant SYL_FOLLOW : std_logic_vector(7 downto 0) := "1000----";
  
  -- Returns the assembly command format for the given syllable. Things like
  -- register numbers and immediate values use replace sequences, see the
  -- function body for more information.
  function get_instr_syntax (
    syllable : std_logic_vector(31 downto 0))
    return string;
  
  -- Expands an unconstrained string to a string of 100 characters by
  -- appending spaces.
  function expand_string (
    input : string)
    return string;
  
  -- Returns the assembly mnemonic for the given opcode
  -- (= syllable(31 downto 24)). This actually just calls get_instr_syntax
  -- and returns what it outputs before the first space.
  function get_mnemonic (
    opcode : std_logic_vector(7 downto 0))
    return string;

end opcode_pkg_orig;

package body opcode_pkg_orig is
  
  function get_instr_syntax (
    syllable : std_logic_vector(31 downto 0))
    return string is
  begin
    -- Use the the following replace sequences:
    --   "%r1" --> Bit 22..17 in unsigned decimal.
    --   "%r2" --> Bit 16..11 in unsigned decimal.
    --   "%r3" --> Bit 10..5 in unsigned decimal.
    --   "%id" --> immediate, respecting long immediates. Displays the
    --             immediate both in signed decimal form.
    --   "%iu" --> Same as above, but in unsigned decimal form.
    --   "%ih" --> Same as above, but in hex form.
    --   "%i1" --> Bit 27..25 in unsigned decimal for LIMMH target lane.
    --   "%i2" --> Bit 24..02 in hex for LIMMH.
    --   "%b1" --> Bit 26..24 in unsigned decimal.
    --   "%b2" --> Bit 19..17 in unsigned decimal.
    --   "%b3" --> Bit 4..2 in unsigned decimal.
    --   "%bi" --> Bit 23..5 in unsigned decimal (rfi/return stack offset).
    --   "%bt" --> Next PC + bit 23..5 in hex (branch target).
    --   "#"   --> Cluster ID.
    --
    -- For get_mnemonic() to work, the correct mnemonic must be returned
    -- when bit 23 is a '-', so any unknown instructions due to that bit
    -- should not be in the else or others blocks.
    if std_match(syllable(31 downto 24), STOP) then
      return "stop";
    elsif std_match(syllable(31 downto 24), NOP) then
      return "nop";
    elsif std_match(syllable(31 downto 24), ALU_ADD) then
      if syllable(23) = '0' then
        return "add r#.%r1 = r#.%r2, r#.%r3";
      else
        return "add r#.%r1 = r#.%r2, %id";
      end if;
    elsif std_match(syllable(31 downto 24), ALU_AND) then
      if syllable(23) = '0' then
        return "and r#.%r1 = r#.%r2, r#.%r3";
      else
        return "and r#.%r1 = r#.%r2, %ih";
      end if;
    elsif std_match(syllable(31 downto 24), ALU_ANDC) then
      if syllable(23) = '0' then
        return "andc r#.%r1 = r#.%r2, r#.%r3";
      else
        return "andc r#.%r1 = r#.%r2, %ih";
      end if;
    elsif std_match(syllable(31 downto 24), ALU_MAX) then
      if syllable(23) = '0' then
        return "max r#.%r1 = r#.%r2, r#.%r3";
      else
        return "max r#.%r1 = r#.%r2, %id";
      end if;
    elsif std_match(syllable(31 downto 24), ALU_MAXU) then
      if syllable(23) = '0' then
        return "maxu r#.%r1 = r#.%r2, r#.%r3";
      else
        return "maxu r#.%r1 = r#.%r2, %iu";
      end if;
    elsif std_match(syllable(31 downto 24), ALU_MIN) then
      if syllable(23) = '0' then
        return "min r#.%r1 = r#.%r2, r#.%r3";
      else
        return "min r#.%r1 = r#.%r2, %id";
      end if;
    elsif std_match(syllable(31 downto 24), ALU_MINU) then
      if syllable(23) = '0' then
        return "minu r#.%r1 = r#.%r2, r#.%r3";
      else
        return "minu r#.%r1 = r#.%r2, %iu";
      end if;
    elsif std_match(syllable(31 downto 24), ALU_OR) then
      if syllable(23) = '0' then
        return "or r#.%r1 = r#.%r2, r#.%r3";
      else
        return "or r#.%r1 = r#.%r2, %ih";
      end if;
    elsif std_match(syllable(31 downto 24), ALU_ORC) then
      if syllable(23) = '0' then
        return "orc r#.%r1 = r#.%r2, r#.%r3";
      else
        return "orc r#.%r1 = r#.%r2, %ih";
      end if;
    elsif std_match(syllable(31 downto 24), ALU_SH1ADD) then
      if syllable(23) = '0' then
        return "sh1add r#.%r1 = r#.%r2, r#.%r3";
      else
        return "sh1add r#.%r1 = r#.%r2, %id";
      end if;
    elsif std_match(syllable(31 downto 24), ALU_SH2ADD) then
      if syllable(23) = '0' then
        return "sh2add r#.%r1 = r#.%r2, r#.%r3";
      else
        return "sh2add r#.%r1 = r#.%r2, %id";
      end if;
    elsif std_match(syllable(31 downto 24), ALU_SH3ADD) then
      if syllable(23) = '0' then
        return "sh3add r#.%r1 = r#.%r2, r#.%r3";
      else
        return "sh3add r#.%r1 = r#.%r2, %id";
      end if;
    elsif std_match(syllable(31 downto 24), ALU_SH4ADD) then
      if syllable(23) = '0' then
        return "sh4add r#.%r1 = r#.%r2, r#.%r3";
      else
        return "sh4add r#.%r1 = r#.%r2, %id";
      end if;
    elsif std_match(syllable(31 downto 24), ALU_SHL) then
      if syllable(23) = '0' then
        return "shl r#.%r1 = r#.%r2, r#.%r3";
      else
        return "shl r#.%r1 = r#.%r2, %iu";
      end if;
    elsif std_match(syllable(31 downto 24), ALU_SHR) then
      if syllable(23) = '0' then
        return "shr r#.%r1 = r#.%r2, r#.%r3";
      else
        return "shr r#.%r1 = r#.%r2, %iu";
      end if;
    elsif std_match(syllable(31 downto 24), ALU_SHRU) then
      if syllable(23) = '0' then
        return "shru r#.%r1 = r#.%r2, r#.%r3";
      else
        return "shru r#.%r1 = r#.%r2, %iu";
      end if;
    elsif std_match(syllable(31 downto 24), ALU_SUB) then
      if syllable(23) = '0' then
        return "sub r#.%r1 = r#.%r3, r#.%r2";
      else
        return "sub r#.%r1 = %id, r#.%r2";
      end if;
    elsif std_match(syllable(31 downto 24), ALU_SXTB) then
      if syllable(23) = '1' then
        return "unknown";
      else
        return "sxtb r#.%r1 = r#.%r2";
      end if;
    elsif std_match(syllable(31 downto 24), ALU_SXTH) then
      if syllable(23) = '1' then
        return "unknown";
      else
        return "sxth r#.%r1 = r#.%r2";
      end if;
    elsif std_match(syllable(31 downto 24), ALU_ZXTB) then
      if syllable(23) = '1' then
        return "unknown";
      else
        return "zxtb r#.%r1 = r#.%r2";
      end if;
    elsif std_match(syllable(31 downto 24), ALU_ZXTH) then
      if syllable(23) = '1' then
        return "unknown";
      else
        return "zxth r#.%r1 = r#.%r2";
      end if;
    elsif std_match(syllable(31 downto 24), ALU_XOR) then
      if syllable(23) = '0' then
        return "xor r#.%r1 = r#.%r2, r#.%r3";
      else
        return "xor r#.%r1 = r#.%r2, %ih";
      end if;
    elsif std_match(syllable(31 downto 24), ALU_SBIT) then
      if syllable(23) = '0' then
        return "unknown";
      else
        return "sbit r#.%r1 = r#.%r2, %iu";
      end if;
    elsif std_match(syllable(31 downto 24), ALU_SBITF) then
      if syllable(23) = '0' then
        return "unknown";
      else
        return "sbitf r#.%r1 = r#.%r2, %iu";
      end if;
    elsif std_match(syllable(31 downto 24), ALU_CMPEQ) then
      case syllable(24 downto 23) is
        when "00"   => return "cmpeq r#.%r1 = r#.%r2, r#.%r3";
        when "01"   => return "cmpeq r#.%r1 = r#.%r2, %id (= %ih)";
        when "10"   => return "cmpeq b#.%b2 = r#.%r2, r#.%r3";
        when others => return "cmpeq b#.%b2 = r#.%r2, %id (= %ih)";
      end case;
    elsif std_match(syllable(31 downto 24), ALU_CMPGE) then
      case syllable(24 downto 23) is
        when "00"   => return "cmpge r#.%r1 = r#.%r2, r#.%r3";
        when "01"   => return "cmpge r#.%r1 = r#.%r2, %id";
        when "10"   => return "cmpge b#.%b2 = r#.%r2, r#.%r3";
        when others => return "cmpge b#.%b2 = r#.%r2, %id";
      end case;
    elsif std_match(syllable(31 downto 24), ALU_CMPGEU) then
      case syllable(24 downto 23) is
        when "00"   => return "cmpgeu r#.%r1 = r#.%r2, r#.%r3";
        when "01"   => return "cmpgeu r#.%r1 = r#.%r2, %iu";
        when "10"   => return "cmpgeu b#.%b2 = r#.%r2, r#.%r3";
        when others => return "cmpgeu b#.%b2 = r#.%r2, %iu";
      end case;
    elsif std_match(syllable(31 downto 24), ALU_CMPGT) then
      case syllable(24 downto 23) is
        when "00"   => return "cmpgt r#.%r1 = r#.%r2, r#.%r3";
        when "01"   => return "cmpgt r#.%r1 = r#.%r2, %id";
        when "10"   => return "cmpgt b#.%b2 = r#.%r2, r#.%r3";
        when others => return "cmpgt b#.%b2 = r#.%r2, %id";
      end case;
    elsif std_match(syllable(31 downto 24), ALU_CMPGTU) then
      case syllable(24 downto 23) is
        when "00"   => return "cmpgtu r#.%r1 = r#.%r2, r#.%r3";
        when "01"   => return "cmpgtu r#.%r1 = r#.%r2, %iu";
        when "10"   => return "cmpgtu b#.%b2 = r#.%r2, r#.%r3";
        when others => return "cmpgtu b#.%b2 = r#.%r2, %iu";
      end case;
    elsif std_match(syllable(31 downto 24), ALU_CMPLE) then
      case syllable(24 downto 23) is
        when "00"   => return "cmple r#.%r1 = r#.%r2, r#.%r3";
        when "01"   => return "cmple r#.%r1 = r#.%r2, %id";
        when "10"   => return "cmple b#.%b2 = r#.%r2, r#.%r3";
        when others => return "cmple b#.%b2 = r#.%r2, %id";
      end case;
    elsif std_match(syllable(31 downto 24), ALU_CMPLEU) then
      case syllable(24 downto 23) is
        when "00"   => return "cmpleu r#.%r1 = r#.%r2, r#.%r3";
        when "01"   => return "cmpleu r#.%r1 = r#.%r2, %iu";
        when "10"   => return "cmpleu b#.%b2 = r#.%r2, r#.%r3";
        when others => return "cmpleu b#.%b2 = r#.%r2, %iu";
      end case;
    elsif std_match(syllable(31 downto 24), ALU_CMPLT) then
      case syllable(24 downto 23) is
        when "00"   => return "cmplt r#.%r1 = r#.%r2, r#.%r3";
        when "01"   => return "cmplt r#.%r1 = r#.%r2, %id";
        when "10"   => return "cmplt b#.%b2 = r#.%r2, r#.%r3";
        when others => return "cmplt b#.%b2 = r#.%r2, %id";
      end case;
    elsif std_match(syllable(31 downto 24), ALU_CMPLTU) then
      case syllable(24 downto 23) is
        when "00"   => return "cmpltu r#.%r1 = r#.%r2, r#.%r3";
        when "01"   => return "cmpltu r#.%r1 = r#.%r2, %iu";
        when "10"   => return "cmpltu b#.%b2 = r#.%r2, r#.%r3";
        when others => return "cmpltu b#.%b2 = r#.%r2, %iu";
      end case;
    elsif std_match(syllable(31 downto 24), ALU_CMPNE) then
      case syllable(24 downto 23) is
        when "00"   => return "cmpne r#.%r1 = r#.%r2, r#.%r3";
        when "01"   => return "cmpne r#.%r1 = r#.%r2, %id (= %ih)";
        when "10"   => return "cmpne b#.%b2 = r#.%r2, r#.%r3";
        when others => return "cmpne b#.%b2 = r#.%r2, %id (= %ih)";
      end case;
    elsif std_match(syllable(31 downto 24), ALU_NANDL) then
      case syllable(24 downto 23) is
        when "00"   => return "nandl r#.%r1 = r#.%r2, r#.%r3";
        when "01"   => return "nandl r#.%r1 = r#.%r2, %id";
        when "10"   => return "nandl b#.%b2 = r#.%r2, r#.%r3";
        when others => return "nandl b#.%b2 = r#.%r2, %id";
      end case;
    elsif std_match(syllable(31 downto 24), ALU_NORL) then
      case syllable(24 downto 23) is
        when "00"   => return "norl r#.%r1 = r#.%r2, r#.%r3";
        when "01"   => return "norl r#.%r1 = r#.%r2, %id";
        when "10"   => return "norl b#.%b2 = r#.%r2, r#.%r3";
        when others => return "norl b#.%b2 = r#.%r2, %id";
      end case;
    elsif std_match(syllable(31 downto 24), ALU_ORL) then
      case syllable(24 downto 23) is
        when "00"   => return "orl r#.%r1 = r#.%r2, r#.%r3";
        when "01"   => return "orl r#.%r1 = r#.%r2, %id";
        when "10"   => return "orl b#.%b2 = r#.%r2, r#.%r3";
        when others => return "orl b#.%b2 = r#.%r2, %id";
      end case;
    elsif std_match(syllable(31 downto 24), ALU_ANDL) then
      case syllable(24 downto 23) is
        when "00"   => return "andl r#.%r1 = r#.%r2, r#.%r3";
        when "01"   => return "andl r#.%r1 = r#.%r2, %id";
        when "10"   => return "andl b#.%b2 = r#.%r2, r#.%r3";
        when others => return "andl b#.%b2 = r#.%r2, %id";
      end case;
    elsif std_match(syllable(31 downto 24), ALU_TBIT) then
      case syllable(24 downto 23) is
        when "00"   => return "unknown";
        when "01"   => return "tbit r#.%r1 = r#.%r2, %id";
        when "10"   => return "unknown";
        when others => return "tbit b#.%b2 = r#.%r2, %id";
      end case;
    elsif std_match(syllable(31 downto 24), ALU_TBITF) then
      case syllable(24 downto 23) is
        when "00"   => return "unknown";
        when "01"   => return "tbitf r#.%r1 = r#.%r2, %id";
        when "10"   => return "unknown";
        when others => return "tbitf b#.%b2 = r#.%r2, %id";
      end case;
    elsif std_match(syllable(31 downto 24), ALU_ADDCG) then
      return "addcg r#.%r1, b#.%b3 = b#.%b1, r#.%r2, r#.%r3";
    elsif std_match(syllable(31 downto 24), ALU_DIVS) then
      return "divs r#.%r1, b#.%b3 = b#.%b1, r#.%r2, r#.%r3";
    elsif std_match(syllable(31 downto 24), ALU_SLCT) then
      if syllable(23) = '0' then
        return "slct r#.%r1 = b#.%b1, r#.%r2, r#.%r3";
      else
        return "slct r#.%r1 = b#.%b1, r#.%r2, %id (= %ih)";
      end if;
    elsif std_match(syllable(31 downto 24), ALU_SLCTF) then
      if syllable(23) = '0' then
        return "slctf r#.%r1 = b#.%b1, r#.%r2, r#.%r3";
      else
        return "slctf r#.%r1 = b#.%b1, r#.%r2, %id (= %ih)";
      end if;
    elsif std_match(syllable(31 downto 24), MUL_MPYLL) then
      if syllable(23) = '0' then
        return "mpyll r#.%r1 = r#.%r2, r#.%r3";
      else
        return "mpyll r#.%r1 = r#.%r2, %id (= %ih)";
      end if;
    elsif std_match(syllable(31 downto 24), MUL_MPYLLU) then
      if syllable(23) = '0' then
        return "mpyllu r#.%r1 = r#.%r2, r#.%r3";
      else
        return "mpyllu r#.%r1 = r#.%r2, %iu (= %ih)";
      end if;
    elsif std_match(syllable(31 downto 24), MUL_MPYLH) then
      if syllable(23) = '0' then
        return "mpylh r#.%r1 = r#.%r2, r#.%r3";
      else
        return "mpylh r#.%r1 = r#.%r2, %id (= %ih)";
      end if;
    elsif std_match(syllable(31 downto 24), MUL_MPYLHU) then
      if syllable(23) = '0' then
        return "mpylhu r#.%r1 = r#.%r2, r#.%r3";
      else
        return "mpylhu r#.%r1 = r#.%r2, %iu (= %ih)";
      end if;
    elsif std_match(syllable(31 downto 24), MUL_MPYHH) then
      if syllable(23) = '0' then
        return "mpyhh r#.%r1 = r#.%r2, r#.%r3";
      else
        return "mpyhh r#.%r1 = r#.%r2, %id (= %ih)";
      end if;
    elsif std_match(syllable(31 downto 24), MUL_MPYHHU) then
      if syllable(23) = '0' then
        return "mpyhhu r#.%r1 = r#.%r2, r#.%r3";
      else
        return "mpyhhu r#.%r1 = r#.%r2, %iu (= %ih)";
      end if;
    elsif std_match(syllable(31 downto 24), MUL_MPYL) then
      if syllable(23) = '0' then
        return "mpyl r#.%r1 = r#.%r2, r#.%r3";
      else
        return "mpyl r#.%r1 = r#.%r2, %id (= %ih)";
      end if;
    elsif std_match(syllable(31 downto 24), MUL_MPYLU) then
      if syllable(23) = '0' then
        return "mpylu r#.%r1 = r#.%r2, r#.%r3";
      else
        return "mpylu r#.%r1 = r#.%r2, %iu (= %ih)";
      end if;
    elsif std_match(syllable(31 downto 24), MUL_MPYH) then
      if syllable(23) = '0' then
        return "mpyh r#.%r1 = r#.%r2, r#.%r3";
      else
        return "mpyh r#.%r1 = r#.%r2, %id (= %ih)";
      end if;
    elsif std_match(syllable(31 downto 24), MUL_MPYHU) then
      if syllable(23) = '0' then
        return "mpyhu r#.%r1 = r#.%r2, r#.%r3";
      else
        return "mpyhu r#.%r1 = r#.%r2, %iu (= %ih)";
      end if;
    elsif std_match(syllable(31 downto 24), MUL_MPYHS) then
      if syllable(23) = '0' then
        return "mpyhs r#.%r1 = r#.%r2, r#.%r3";
      else
        return "mpyhs r#.%r1 = r#.%r2, %id (= %ih)";
      end if;
    elsif std_match(syllable(31 downto 24), LINK_MOVE_TO) then
      return "mov"; -- ???
    elsif std_match(syllable(31 downto 24), LINK_MOVE_FROM) then
      return "mov"; -- ???
    elsif std_match(syllable(31 downto 24), LINK_LOAD) then
      if syllable(23) = '0' then
        return "unknown";
      else
        return "ldl l#.0 = %ih[r#.%r2]";
      end if;
    elsif std_match(syllable(31 downto 24), LINK_STORE) then
      if syllable(23) = '0' then
        return "unknown";
      else
        return "stl %ih[r#.%r2] = l#.0";
      end if;
    elsif std_match(syllable(31 downto 24), CTRL_GOTO) then
      return "goto %bt";
    elsif std_match(syllable(31 downto 24), CTRL_IGOTO) then
      return "igoto l#.0";
    elsif std_match(syllable(31 downto 24), CTRL_CALL) then
      return "call l#.0 = %bt";
    elsif std_match(syllable(31 downto 24), CTRL_ICALL) then
      return "icall l#.0";
    elsif std_match(syllable(31 downto 24), CTRL_BR) then
      return "br b#.%b3, %bt";
    elsif std_match(syllable(31 downto 24), CTRL_BRF) then
      return "brf b#.%b3, %bt";
    elsif std_match(syllable(31 downto 24), CTRL_RETURN) then
      return "return r#.1 = r#.1, %bi, l#.0";
    elsif std_match(syllable(31 downto 24), CTRL_RFI) then
      return "rfi r#.1 = r#.1, %bi, l#.0";
    elsif std_match(syllable(31 downto 24), INTR_SEND) then
      return "intr_send";
    elsif std_match(syllable(31 downto 24), INTR_RECV) then
      return "intr_recv";
    elsif std_match(syllable(31 downto 24), MEM_LDW) then
      if syllable(23) = '0' then
        return "unknown";
      else
        return "ldw r#.%r1 = %ih[r#.%r2]";
      end if;
    elsif std_match(syllable(31 downto 24), MEM_LDH) then
      if syllable(23) = '0' then
        return "unknown";
      else
        return "ldh r#.%r1 = %ih[r#.%r2]";
      end if;
    elsif std_match(syllable(31 downto 24), MEM_LDHU) then
      if syllable(23) = '0' then
        return "unknown";
      else
        return "ldhu r#.%r1 = %ih[r#.%r2]";
      end if;
    elsif std_match(syllable(31 downto 24), MEM_LDB) then
      if syllable(23) = '0' then
        return "unknown";
      else
        return "ldb r#.%r1 = %ih[r#.%r2]";
      end if;
    elsif std_match(syllable(31 downto 24), MEM_LDBU) then
      if syllable(23) = '0' then
        return "unknown";
      else
        return "ldbu r#.%r1 = %ih[r#.%r2]";
      end if;
    elsif std_match(syllable(31 downto 24), MEM_STW) then
      if syllable(23) = '0' then
        return "unknown";
      else
        return "stw %ih[r#.%r2] = r#.%r1";
      end if;
    elsif std_match(syllable(31 downto 24), MEM_STH) then
      if syllable(23) = '0' then
        return "unknown";
      else
        return "sth %ih[r#.%r2] = r#.%r1";
      end if;
    elsif std_match(syllable(31 downto 24), MEM_STB) then
      if syllable(23) = '0' then
        return "unknown";
      else
        return "stb %ih[r#.%r2] = r#.%r1";
      end if;
    elsif std_match(syllable(31 downto 24), SYL_FOLLOW) then
      return "limmh %i1, %i2";
    else
      return "unknown";
    end if;
  end get_instr_syntax;

  function expand_string (
    input : string)
    return string
  is
    variable s : string(1 to 100);
  begin
    s := (others => nul);
    if input'high > 100 then
      s := input(1 to 100);
    else
      s(input'range) := input;
    end if;
    return s;
  end expand_string;
  
  function get_mnemonic (
    opcode : std_logic_vector(7 downto 0))
    return string
  is
    variable syntax : string(1 to 100);
  begin
    syntax := expand_string(get_instr_syntax(opcode & "--------" & "--------" & "--------"));
    for i in syntax'range loop
      if (syntax(i) = ' ') or (syntax(i) = NUL) then
        return syntax(1 to i-1);
      end if;
    end loop;
    return syntax;
  end get_mnemonic;
  
end opcode_pkg_orig;
