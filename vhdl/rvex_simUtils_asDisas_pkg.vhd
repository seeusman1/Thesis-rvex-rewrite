-- insert license here

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.rvex_pkg.all;
use work.rvex_simUtils_pkg.all;
use work.rvex_opcode_pkg.all;

--=============================================================================
-- This package contains simulation/elaboration-only methods for basic
-- assembly and disassembly.
-------------------------------------------------------------------------------
package rvex_simUtils_asDisas_pkg is
--=============================================================================
  
  -- Maximum number of syllables in an assembly file.
  constant RVSP_MAX_SYLLABLES : natural := 1024;
  
  -- Data types for a line in an assembly file and an assembly program.
  subtype rvsp_assemblyLine_type is string(1 to 70);
  type rvsp_assemblyProgram_type is array (natural range <>) of rvsp_assemblyLine_type;
  
  -- Assembler instruction memory output type.
  type rvsp_assembledProgram_type is array (0 to RVSP_MAX_SYLLABLES-1) of rvex_syllable_type;
  
  -- Attempts to assemble a single instruction.
  procedure assembleLine(
    source    : in string;
    line      : in positive;
    syllable  : out rvex_syllable_type;
    ok        : out boolean;
    error     : out rvex_string_builder_type
  );
  
  -- Attempts to assemble a program. errorLevel indicates what type of report
  -- should be made when a parse error occurs. Limitations:
  --  - Empty lines and comments are not allowed.
  --  - Maximum assembled program size is limited to RVSP_MAX_SYLLABLES.
  procedure assemble(
    source      : in  rvsp_assemblyProgram_type;
    imem        : out rvsp_assembledProgram_type;
    ok          : out boolean;
    errorLevel  : in  severity_level := failure
  );
  
  -- Disassembles a syllable. If limmh is defined, any arithmetic immediate is
  -- extended by that value. If PC_plusOne is defined, branch targets are
  -- evaluated.
  function disassemble(
    syllable    : in  rvex_syllable_type;
    limmh       : in  rvex_data_type := (others => 'U');
    PC_plusOne  : in  rvex_address_type := (others => 'U')
  ) return rvex_string_builder_type;
  
end rvex_simUtils_asDisas_pkg;

--=============================================================================
package body rvex_simUtils_asDisas_pkg is
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- Increases pos until it points to the first non-whitespace character
  -- encountered
  -----------------------------------------------------------------------------
  procedure scanToEndOfWhitespace(
    line  : in string;
    pos   : inout positive
  ) is
  begin
    while pos <= line'length loop
      exit when line(pos) /= ' ';
      pos := pos + 1;
    end loop;
  end scanToEndOfWhitespace;
  
  -----------------------------------------------------------------------------
  -- Compares and scans an identifier
  -----------------------------------------------------------------------------
  procedure scanAndCompareIdentifier(
    line1 : in string;
    pos1  : inout positive;
    line2 : in string;
    pos2  : inout positive;
    ok    : out boolean
  ) is
  begin
    
    -- Make sure that an identifier is beginning on both inputs.
    if (not isAlphaChar(line1(pos1))) or (not isAlphaChar(line2(pos2))) then
      ok := false;
      return;
    end if;
    
    -- Scan the identifier.
    while (pos1 <= line1'length) and (pos2 <= line2'length) loop
      
      -- If both lines are no longer alphanumerical, we've successfully
      -- scanned. Trim whitespace off the ends before returning success.
      if (not isAlphaNumericChar(line1(pos1))) and (not isAlphaNumericChar(line2(pos2))) then
        scanToEndOfWhitespace(line1, pos1);
        scanToEndOfWhitespace(line2, pos2);
        ok := true;
        return;
      end if;
      
      -- Fail if the characters are not equal or not alphanumeric.
      if not charsEqual(line1(pos1), line2(pos2)) then
        ok := false;
        return;
      end if;
      
      -- Increment positions.
      pos1 := pos1 + 1;
      pos2 := pos2 + 1;
      
    end loop;
    
    -- One of the strings ended before the other, fail.
    ok := false;
    
  end scanAndCompareIdentifier;
  
  -----------------------------------------------------------------------------
  -- Compares and scans a single special character
  -----------------------------------------------------------------------------
  procedure scanAndCompareSpecial(
    line1 : in string;
    pos1  : inout positive;
    line2 : in string;
    pos2  : inout positive;
    ok    : out boolean
  ) is
  begin
    
    -- Make sure that a special character is present on both lines.
    if (not isSpecialChar(line1(pos1))) or (not isSPecialChar(line2(pos2))) then
      ok := false;
      return;
    end if;
    
    -- Fail if the characters are not equal.
    if line1(pos1) /= line2(pos2) then
      ok := false;
      return;
    end if;
    
    -- Increment scanner positions by one.
    pos1 := pos1 + 1;
    pos2 := pos2 + 1;
    
    -- Read to end of whitespace.
    scanToEndOfWhitespace(line1, pos1);
    scanToEndOfWhitespace(line2, pos2);
    
    -- Success.
    ok := true;
    
  end scanAndCompareSpecial;
  
  -----------------------------------------------------------------------------
  -- Attempts to scan a numeric value (0xHEX and decimal are allowed)
  -----------------------------------------------------------------------------
  procedure scanNumeric(
    line  : in string;
    pos   : inout positive;
    val   : inout signed(32 downto 0);
    ok    : out boolean
  ) is
    variable radix    : natural;
    variable negative : boolean;
    variable charVal  : integer;
  begin
    val := (others => '0');
    ok := false;
    
    -- Test for negative number marker.
    if matchAt(line, pos, "-") then
      radix := 10;
      negative := true;
      pos := pos + 1;
    end if;
    
    -- Skip whitespace between unary minus and number.
    scanToEndOfWhitespace(line, pos);
    
    -- Make sure the previous did not place us at the end of the string.
    if pos > line'length then
      return;
    end if;
    
    -- Test for radix specifiers.
    if matchAt(line, pos, "0x") then
      
      -- Hexadecimal entry.
      radix := 16;
      pos := pos + 2;
      
    elsif matchAt(line, pos, "0b") then
      
      -- Binary entry.
      radix := 2;
      pos := pos + 2;
      
    elsif matchAt(line, pos, "0") then
      
      -- Octal entry.
      radix := 8;
      pos := pos + 1;
      
      -- In this case we've already processed a digit, so the result is valid.
      ok := true;
      
    else
      
      -- Decimal entry.
      radix := 10;
      
    end if;
    
    -- Make sure the previous did not place us at the end of the string.
    if pos > line'length then
      return;
    end if;
    
    -- Scan the remainder of the literal.
    while pos <= line'length loop
      
      -- Break if the current character is not alphanumeric.
      exit when not isAlphaNumericChar(line(pos));
      
      -- Get the value of the current digit.
      charVal := charToDigitVal(line(pos));
      
      -- Make sure the character is valid for the current radix.
      if (charVal = -1) or (charVal >= radix) then
        ok := false;
        return;
      end if;
      
      -- Add the digit to the value.
      val := resize(val * to_signed(radix, 33), 33) + to_signed(charVal, 33);
      
      -- We've processed at least one digit, so this is a valid number unless
      -- there is garbage at the end.
      ok := true;
      
      -- Increase scanner position.
      pos := pos + 1;
      
    end loop;
    
    -- Scan past trailing whitespace.
    scanToEndOfWhitespace(line, pos);
    
    -- Negate result if we started with a dash.
    if negative then
      val := -val;
    end if;
    
  end scanNumeric;
  
  -----------------------------------------------------------------------------
  -- Attempts to assemble the given instruction with the given pattern
  -----------------------------------------------------------------------------
  procedure asAttemptPattern(
    
    -- Line of source code.
    source    : in string;
    
    -- Pattern to match with.
    pattern   : in string;
    
    -- Syllable input/output. Before calling, the opcode and imm select bits
    -- should be set to the values belonging to the pattern.
    syllable  : inout rvex_syllable_type;
    
    -- Whether parsing was successful.
    ok        : out boolean;
    
    -- If parsing was not successful, how far the scanner got before a
    -- discrepency between source and pattern was found.
    charsValid: out natural;
    
    -- String identifying the error if ok is false.
    error     : out rvex_string_builder_type
    
  ) is
    
    -- Scanner positions.
    variable sourcePos      : positive;
    variable patternPos     : positive;
    
    variable val            : signed(32 downto 0);
    variable stepOk         : boolean;
    
  begin
    
    -- Assume parsing failed until we're done.
    ok := false;
    charsValid := 1;
    error := to_rvs("unknown error");
    
    -- Scan beyond any initial whitespace.
    sourcePos := 1;
    patternPos := 1;
    scanToEndOfWhitespace(source, sourcePos);
    scanToEndOfWhitespace(pattern, patternPos);
    
    -- Scan tokens until one or both of the scanners reach the end of their
    -- respective strings.
    while (sourcePos <= source'length) and (patternPos <= pattern'length) loop
      
      -- Scan according to the next token in the pattern.
      if matchAt(pattern, patternPos, "%r1") then
        
        -- General purpose register, stored in bit 22..17.
        patternPos := patternPos + 3;
        scanToEndOfWhitespace(pattern, patternPos);
        scanNumeric(source, sourcePos, val, stepOk);
        if (not stepOk) or (to_integer(val(32 downto 6)) /= 0)  then
          error := to_rvs("unknown register");
          return;
        end if;
        syllable(22 downto 17) := std_logic_vector(val(5 downto 0));
        
      elsif matchAt(pattern, patternPos, "%r2") then
        
        -- General purpose register, stored in bit 16..11.
        patternPos := patternPos + 3;
        scanToEndOfWhitespace(pattern, patternPos);
        scanNumeric(source, sourcePos, val, stepOk);
        if (not stepOk) or (to_integer(val(32 downto 6)) /= 0)  then
          error := to_rvs("unknown register");
          return;
        end if;
        syllable(16 downto 11) := std_logic_vector(val(5 downto 0));
        
      elsif matchAt(pattern, patternPos, "%r3") then
        
        -- General purpose register, stored in bit 10..5.
        patternPos := patternPos + 3;
        scanToEndOfWhitespace(pattern, patternPos);
        scanNumeric(source, sourcePos, val, stepOk);
        if (not stepOk) or (to_integer(val(32 downto 6)) /= 0)  then
          error := to_rvs("unknown register");
          return;
        end if;
        syllable(10 downto 5) := std_logic_vector(val(5 downto 0));
        
      elsif matchAt(pattern, patternPos, "%id")
         or matchAt(pattern, patternPos, "%iu")
         or matchAt(pattern, patternPos, "%ih") then
        
        -- 9-bit low part of the immediate, stored in bit 10..2. We're okay
        -- with immediates being out of range so you can enter the same large
        -- number for the LIMMH and target syllable.
        patternPos := patternPos + 3;
        scanToEndOfWhitespace(pattern, patternPos);
        scanNumeric(source, sourcePos, val, stepOk);
        if not stepOk then
          error := to_rvs("failed to parse immediate numeric");
          return;
        end if;
        syllable(10 downto 2) := std_logic_vector(val(8 downto 0));
        
      elsif matchAt(pattern, patternPos, "%i2") then
        
        -- 23-bit high part of the immediate, stored in bit 24..2, for LIMMH
        -- syllables.
        patternPos := patternPos + 3;
        scanToEndOfWhitespace(pattern, patternPos);
        scanNumeric(source, sourcePos, val, stepOk);
        if not stepOk then
          error := to_rvs("failed to parse long immediate numeric");
          return;
        end if;
        syllable(24 downto 2) := std_logic_vector(val(31 downto 9));
        
      elsif matchAt(pattern, patternPos, "%i1") then
        
        -- Long immediate target lane.
        patternPos := patternPos + 3;
        scanToEndOfWhitespace(pattern, patternPos);
        scanNumeric(source, sourcePos, val, stepOk);
        if (not stepOk) or (to_integer(val(32 downto 3)) /= 0) then
          error := to_rvs("invalid LIMMH target lane");
          return;
        end if;
        syllable(27 downto 25) := std_logic_vector(val(2 downto 0));
        
      elsif matchAt(pattern, patternPos, "%b1") then
        
        -- Branch register, stored in bit 26..24.
        patternPos := patternPos + 3;
        scanToEndOfWhitespace(pattern, patternPos);
        scanNumeric(source, sourcePos, val, stepOk);
        if (not stepOk) or (to_integer(val(32 downto 3)) /= 0)  then
          error := to_rvs("unknown branch register");
          return;
        end if;
        syllable(26 downto 24) := std_logic_vector(val(2 downto 0));
        
      elsif matchAt(pattern, patternPos, "%b2") then
        
        -- Branch register, stored in bit 19..17.
        patternPos := patternPos + 3;
        scanToEndOfWhitespace(pattern, patternPos);
        scanNumeric(source, sourcePos, val, stepOk);
        if (not stepOk) or (to_integer(val(32 downto 3)) /= 0)  then
          error := to_rvs("unknown branch register");
          return;
        end if;
        syllable(19 downto 17) := std_logic_vector(val(2 downto 0));
        
      elsif matchAt(pattern, patternPos, "%b3") then
        
        -- Branch register, stored in bit 4..2.
        patternPos := patternPos + 3;
        scanToEndOfWhitespace(pattern, patternPos);
        scanNumeric(source, sourcePos, val, stepOk);
        if (not stepOk) or (to_integer(val(32 downto 3)) /= 0)  then
          error := to_rvs("unknown branch register");
          return;
        end if;
        syllable(4 downto 2) := std_logic_vector(val(2 downto 0));
        
      elsif matchAt(pattern, patternPos, "%bi") then
        
        -- Stack offset for RETURN and RFI, stored in bit 23..5.
        patternPos := patternPos + 3;
        scanToEndOfWhitespace(pattern, patternPos);
        scanNumeric(source, sourcePos, val, stepOk);
        if not stepOk then
          error := to_rvs("failed to parse stack offset numeric");
          return;
        end if;
        if resolved(std_ulogic_vector(val(32 downto 18))) = 'X' then
          error := to_rvs("stack offset out of range");
          return;
        end if;
        syllable(23 downto 5) := std_logic_vector(val(18 downto 0));
        
      elsif matchAt(pattern, patternPos, "%bt") then
        
        -- Relative branch target, stored in bit 23..5.
        patternPos := patternPos + 3;
        scanToEndOfWhitespace(pattern, patternPos);
        scanNumeric(source, sourcePos, val, stepOk);
        if not stepOk then
          error := to_rvs("failed to parse stack offset numeric");
          return;
        end if;
        if resolved(std_ulogic_vector(val(32 downto 21))) = 'X' then
          error := to_rvs("branch offset out of range");
          return;
        end if;
        if to_integer(val(2 downto 0)) /= 0 then
          error := to_rvs("branch offset not aligned to syllable pair");
          return;
        end if;
        syllable(23 downto 5) := std_logic_vector(val(21 downto 3));
        
      elsif matchAt(pattern, patternPos, "r#")
         or matchAt(pattern, patternPos, "b#") then
        
        -- Match the first character.
        if not charsEqual(source(sourcePos), pattern(patternPos)) then
          error := to_rvs("unknown register");
          return;
        end if;
        
        -- Ignore cluster specifier.
        patternPos := patternPos + 2;
        sourcePos := sourcePos + 2;
        scanToEndOfWhitespace(pattern, patternPos);
        scanToEndOfWhitespace(source, sourcePos);
        
      elsif isAlphaChar(pattern(patternPos)) then
        
        -- Match text literals/identifiers (like the instruction name).
        scanAndCompareIdentifier(source, sourcePos, pattern, patternPos, stepOk);
        if not stepOk then
          error := to_rvs("invalid token");
          return;
        end if;
        
      else
        
        -- Match special characters.
        scanAndCompareSpecial(source, sourcePos, pattern, patternPos, stepOk);
        if not stepOk then
          error := to_rvs("invalid token");
          return;
        end if;
      end if;
      
      -- Detect stop marker.
      if matchAt(source, sourcePos, ";;") then
        sourcePos := sourcePos + 2;
        scanToEndOfWhitespace(source, sourcePos);
        syllable(1) := '1';
      end if;
        
      -- Update number of valid characters in source.
      charsValid := sourcePos;
      
    end loop;
    
    -- If both scanners end up at the end of their respective strings, this is
    -- a match.
    if sourcePos <= source'length then
      error := to_rvs("garbage at end of line");
    elsif patternPos <= pattern'length then
      error := to_rvs("incomplete syllable");
    else
      ok := true;
    end if;
    
  end asAttemptPattern;
  
  -----------------------------------------------------------------------------
  -- Attempts to assemble an instruction with all patterns in the opcode list
  -----------------------------------------------------------------------------
  procedure assembleLine(
    
    -- Line of source code.
    source    : in string;
    
    -- Line number for the error message.
    line      : in positive;
    
    -- Syllable output if OK.
    syllable  : out rvex_syllable_type;
    
    -- Whether parsing was successful.
    ok        : out boolean;
    
    -- String identifying the error if ok is false.
    error     : out rvex_string_builder_type
    
  ) is
    
    variable tempSyllable       : rvex_syllable_type;
    variable bestMatchSyllable  : rvex_syllable_type;
    variable tempOK             : boolean;
    variable tempCharsValid     : natural;
    variable bestMatchCharsValid: integer;
    variable tempError          : rvex_string_builder_type;
    variable bestMatchError     : rvex_string_builder_type;
    variable errorBuilder       : rvex_string_builder_type;
    
  begin
    
    -- Set bestCharsValid to -1 so pattern-matching with any possible
    -- instruction will at least override this.
    bestMatchCharsValid := -1;
    
    -- Loop over all opcodes.
    for opcode in 0 to 255 loop
      
      -- Try the syllable using a register for operand 2.
      if OPCODE_TABLE(opcode).valid(0) = '1' then
        tempSyllable := (others => '0');
        tempSyllable(31 downto 24) := std_logic_vector(to_unsigned(opcode, 8));
        asAttemptPattern(
          source, OPCODE_TABLE(opcode).syntax_reg, tempSyllable,
          tempOK, tempCharsValid, tempError
        );
        if tempOK then
          
          -- Complete match, return it greedily.
          syllable := tempSyllable;
          ok := true;
          return;
          
        elsif tempCharsValid > bestMatchCharsValid then
          
          -- Incomplete match, but it's better than what we've found so far.
          bestMatchSyllable := tempSyllable;
          bestMatchCharsValid := tempCharsValid;
          bestMatchError := tempError;
          
        end if;
      end if;
      
      -- Try the syllable using an immediate.
      if OPCODE_TABLE(opcode).valid(1) = '1' then
        tempSyllable := (others => '0');
        tempSyllable(31 downto 24) := std_logic_vector(to_unsigned(opcode, 8));
        tempSyllable(23) := '1';
        asAttemptPattern(
          source, OPCODE_TABLE(opcode).syntax_imm, tempSyllable,
          tempOK, tempCharsValid, tempError
        );
        if tempOK then
          
          -- Complete match, return it greedily.
          syllable := tempSyllable;
          ok := true;
          return;
          
        elsif tempCharsValid > bestMatchCharsValid then
          
          -- Incomplete match, but it's better than what we've found so far.
          bestMatchSyllable := tempSyllable;
          bestMatchCharsValid := tempCharsValid;
          bestMatchError := tempError;
          
        end if;
      end if;
      
    end loop;
    
    -- No match found. Try to return a sensible error.
    rvs_clear(errorBuilder);
    errorBuilder
      := errorBuilder & "Failed to parse line " & integer'image(line) & ": "
       & bestMatchError & " at " & source(1 to bestMatchCharsValid-1) & "<here>"
       & source(bestMatchCharsValid to source'length);
    error := errorBuilder;
    ok := false;
    return;
    
  end assembleLine;
  
  -----------------------------------------------------------------------------
  -- Assembles a program
  -----------------------------------------------------------------------------
  procedure assemble(
    source      : in  rvsp_assemblyProgram_type;
    imem        : out rvsp_assembledProgram_type;
    ok          : out boolean;
    errorLevel  : in  severity_level := failure
  ) is
    variable okTemp : boolean;
    variable error  : rvex_string_builder_type;
  begin
    
    -- Not done yet, set OK to false until we are.
    ok := false;
    
    -- Make sure the source isn't too large.
    if source'length > RVSP_MAX_SYLLABLES then
      report "Source size is greater than RVSP_MAX_SYLLABLES. Please increase "
           & "that number of you need bigger programs." severity errorLevel;
      return;
    end if;
    
    -- Assemble line by line.
    for line in source'range loop
      
      -- Attempt to assemble.
      assembleLine(
        source    => source(line),
        line      => line + 1,
        syllable  => imem(line),
        ok        => okTemp,
        error     => error
      );
      
      -- Check for errors.
      if not okTemp then
        report rvs2str(error) severity errorLevel;
        return;
      end if;
      
    end loop;
    
    -- Done, set OK to true.
    ok := true;
    
  end assemble;
  
  -----------------------------------------------------------------------------
  -- Disassembles a syllable
  -----------------------------------------------------------------------------
  function disassemble(
    syllable    : in  rvex_syllable_type;
    limmh       : in  rvex_data_type := (others => 'U');
    PC_plusOne  : in  rvex_address_type := (others => 'U')
  ) return rvex_string_builder_type is
    
    -- Syntax specification for the given opcode and immediate switch.
    variable syntax       : syllable_syntax_type;
    variable pos          : positive;
    variable disassembly  : rvex_string_builder_type;
    variable imm          : std_logic_vector(8 downto 0);
    variable branchOff    : rvex_address_type;
    
  begin
    
    -- Look up the syntax specification for this syllable.
    if syllable(23) = '0' then
      syntax := OPCODE_TABLE(to_integer(unsigned(syllable(31 downto 24)))).syntax_reg;
    else
      syntax := OPCODE_TABLE(to_integer(unsigned(syllable(31 downto 24)))).syntax_imm;
    end if;
    
    -- Loop through the syntax and perform replacements as we go.
    rvs_clear(disassembly);
    pos := 1;
    while pos <= syntax'length loop
      
      -- Handle replace sequences.
      if syntax(pos) = '%' then
        if matchAt(syntax, pos+1, "r1") then
          
          -- "%r1" --> Bit 22..17 in unsigned decimal.
          pos := pos + 3;
          rvs_append(disassembly, rvs_uint(syllable(22 downto 17)));
          next;
          
        elsif matchAt(syntax, pos+1, "r2") then
          
          -- "%r2" --> Bit 16..11 in unsigned decimal.
          pos := pos + 3;
          rvs_append(disassembly, rvs_uint(syllable(16 downto 11)));
          next;
          
        elsif matchAt(syntax, pos+1, "r3") then
          
          -- "%r3" --> Bit 10..5 in unsigned decimal.
          pos := pos + 3;
          rvs_append(disassembly, rvs_uint(syllable(10 downto 5)));
          next;
          
        elsif matchAt(syntax, pos+1, "id") then
          
          -- "%id" --> immediate, respecting long immediates. Displays the immediate
          --           in signed decimal form.
          pos := pos + 3;
          imm := syllable(10 downto 2);
          if limmh(31) /= 'U' then
            rvs_append(disassembly, rvs_int(limmh(31 downto 9) & imm));
          else
            rvs_append(disassembly, rvs_int(imm));
          end if;
          next;
          
        elsif matchAt(syntax, pos+1, "iu") then
          
          -- "%iu" --> Same as above, but in unsigned decimal form.
          pos := pos + 3;
          imm := syllable(10 downto 2);
          if limmh(31) /= 'U' then
            rvs_append(disassembly, rvs_uint(limmh(31 downto 9) & imm));
          else
            rvs_append(disassembly, rvs_uint(imm));
          end if;
          next;
          
        elsif matchAt(syntax, pos+1, "ih") then
          
          -- "%ih" --> Same as above, but in hex form.
          pos := pos + 3;
          imm := syllable(10 downto 2);
          if limmh(31) /= 'U' then
            rvs_append(disassembly, rvs_hex(limmh(31 downto 9) & imm));
          else
            rvs_append(disassembly, rvs_hex(imm));
          end if;
          next;
          
        elsif matchAt(syntax, pos+1, "i1") then
          
          -- "%i1" --> Bit 27..25 in unsigned decimal for LIMMH target lane.
          pos := pos + 3;
          rvs_append(disassembly, rvs_uint(syllable(27 downto 25)));
          next;
          
        elsif matchAt(syntax, pos+1, "i2") then
          
          -- "%i2" --> Bit 24..02 in hex for LIMMH.
          pos := pos + 3;
          rvs_append(disassembly, rvs_hex(syllable(24 downto 2) & "000000000"));
          next;
          
        elsif matchAt(syntax, pos+1, "b1") then
          
          -- "%b1" --> Bit 26..24 in unsigned decimal.
          pos := pos + 3;
          rvs_append(disassembly, rvs_uint(syllable(26 downto 24)));
          next;
          
        elsif matchAt(syntax, pos+1, "b2") then
          
          -- "%b2" --> Bit 19..17 in unsigned decimal.
          pos := pos + 3;
          rvs_append(disassembly, rvs_uint(syllable(19 downto 17)));
          next;
          
        elsif matchAt(syntax, pos+1, "b3") then
          
          -- "%b3" --> Bit 4..2 in unsigned decimal.
          pos := pos + 3;
          rvs_append(disassembly, rvs_uint(syllable(4 downto 2)));
          next;
          
        elsif matchAt(syntax, pos+1, "bi") then
          
          -- "%bi" --> Bit 23..5 in signed decimal (rfi/return stack offset).
          pos := pos + 3;
          rvs_append(disassembly, rvs_uint(syllable(23 downto 5)));
          next;
          
        elsif matchAt(syntax, pos+1, "bt") then
          
          -- "%bt" --> Next PC + bit 23..5 in hex (branch target).
          pos := pos + 3;
          branchOff(31 downto 22) := (others => syllable(23));
          branchOff(21 downto 3) := syllable(23 downto 5);
          branchOff(2 downto 0) := (others => '0');
          if PC_plusOne(31) /= 'U' then
            rvs_append(disassembly, '=');
            rvs_append(disassembly, rvs_hex(std_logic_vector(
              signed(PC_plusOne) + signed(branchOff)
            )));
          else
            if syllable(23) = '0' then
              rvs_append(disassembly, '+');
              rvs_append(disassembly, rvs_hex(branchOff(21 downto 0)));
            else
              rvs_append(disassembly, '-');
              rvs_append(disassembly, rvs_hex(std_logic_vector(
                -signed(branchOff(21 downto 0))
              )));
            end if;
          end if;
          next;
          
        end if;
      elsif syntax(pos) = '#' then
        
        -- "#"   --> Cluster specifier (0).
        rvs_append(disassembly, '0');
        pos := pos + 1;
        next;
        
      end if;
      
      -- Handle literal characters.
      rvs_append(disassembly, syntax(pos));
      pos := pos + 1;
      next;
      
    end loop;
    
    -- Remove trailing spaces and return.
    rvs_trimTrailingSpaces(disassembly);
    
    -- Append bundle stop token if stop bit is set.
    if syllable(1) = '1' then
      rvs_append(disassembly, " ;;");
    end if;
    
    return disassembly;
    
  end disassemble;
  
end rvex_simUtils_asDisas_pkg;
