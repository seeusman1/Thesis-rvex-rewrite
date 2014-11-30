-- insert license here

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.rvex_pkg.all;
use work.rvex_simUtils_pkg.all;

--=============================================================================
-- This package contains simulation/elaboration-only methods for basic
-- assembly and disassembly.
-------------------------------------------------------------------------------
package rvex_simUtils_asDisas_pkg is
--=============================================================================
  
  -- Data types for a line in an assembly file and an assembly program.
  subtype rvsp_assemblyLine_type is string(1 to 70);
  type rvsp_assemblyProgram_type is array (positive range <>) of rvsp_assemblyLine_type;
  
  procedure asAttempt(
    
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
    
  );
  
end rvex_simUtils_asDisas_pkg;

--=============================================================================
package body rvex_simUtils_asDisas_pkg is
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- Returns true if given character is alphabetical
  -----------------------------------------------------------------------------
  function isAlphaChar(c: character) return boolean is
    variable result: boolean;
  begin
    case c is
      when 'a' => result := true; when 'A' => result := true;
      when 'b' => result := true; when 'B' => result := true;
      when 'c' => result := true; when 'C' => result := true;
      when 'd' => result := true; when 'D' => result := true;
      when 'e' => result := true; when 'E' => result := true;
      when 'f' => result := true; when 'F' => result := true;
      when 'g' => result := true; when 'G' => result := true;
      when 'h' => result := true; when 'H' => result := true;
      when 'i' => result := true; when 'I' => result := true;
      when 'j' => result := true; when 'J' => result := true;
      when 'k' => result := true; when 'K' => result := true;
      when 'l' => result := true; when 'L' => result := true;
      when 'm' => result := true; when 'M' => result := true;
      when 'n' => result := true; when 'N' => result := true;
      when 'o' => result := true; when 'O' => result := true;
      when 'p' => result := true; when 'P' => result := true;
      when 'q' => result := true; when 'Q' => result := true;
      when 'r' => result := true; when 'R' => result := true;
      when 's' => result := true; when 'S' => result := true;
      when 't' => result := true; when 'T' => result := true;
      when 'u' => result := true; when 'U' => result := true;
      when 'v' => result := true; when 'V' => result := true;
      when 'w' => result := true; when 'W' => result := true;
      when 'x' => result := true; when 'X' => result := true;
      when 'y' => result := true; when 'Y' => result := true;
      when 'z' => result := true; when 'Z' => result := true;
      when others => result := false;
    end case;
    return result;
  end isAlphaChar;
  
  -----------------------------------------------------------------------------
  -- Returns true if given character is numeric
  -----------------------------------------------------------------------------
  function isNumericChar(c: character) return boolean is
    variable result: boolean;
  begin
    case c is
      when '0' => result := true; when '1' => result := true;
      when '2' => result := true; when '3' => result := true;
      when '4' => result := true; when '5' => result := true;
      when '6' => result := true; when '7' => result := true;
      when '8' => result := true; when '9' => result := true;
      when others => result := false;
    end case;
    return result;
  end isNumericChar;
  
  -----------------------------------------------------------------------------
  -- Returns true if given character is alphanumerical
  -----------------------------------------------------------------------------
  function isAlphaNumericChar(c: character) return boolean is
  begin
    return isAlphaChar(c) or isNumericChar(c);
  end isAlphaNumericChar;
  
  -----------------------------------------------------------------------------
  -- Returns true if given character is a special character
  -----------------------------------------------------------------------------
  function isSpecialChar(c: character) return boolean is
  begin
    return not isAlphaNumericChar(c) and c /= ' ';
  end isSpecialChar;
  
  -----------------------------------------------------------------------------
  -- Converts a character to uppercase
  -----------------------------------------------------------------------------
  function upperChar(
    c: character
  ) return character is
    variable result: character;
  begin
    case c is
      when 'a' => result := 'A';
      when 'b' => result := 'B';
      when 'c' => result := 'C';
      when 'd' => result := 'D';
      when 'e' => result := 'E';
      when 'f' => result := 'F';
      when 'g' => result := 'G';
      when 'h' => result := 'H';
      when 'i' => result := 'I';
      when 'j' => result := 'J';
      when 'k' => result := 'K';
      when 'l' => result := 'L';
      when 'm' => result := 'M';
      when 'n' => result := 'N';
      when 'o' => result := 'O';
      when 'p' => result := 'P';
      when 'q' => result := 'Q';
      when 'r' => result := 'R';
      when 's' => result := 'S';
      when 't' => result := 'T';
      when 'u' => result := 'U';
      when 'v' => result := 'V';
      when 'w' => result := 'W';
      when 'x' => result := 'X';
      when 'y' => result := 'Y';
      when 'z' => result := 'Z';
      when others => result := c;
    end case;
    return result;
  end upperChar;
  
  -----------------------------------------------------------------------------
  -- Converts a character to its numeric value
  -----------------------------------------------------------------------------
  function charToDigitVal(
    c: character
  ) return integer is
    variable result: integer;
  begin
    case c is
      when '0' => result := 0;
      when '1' => result := 1;
      when '2' => result := 2;
      when '3' => result := 3;
      when '4' => result := 4;
      when '5' => result := 5;
      when '6' => result := 6;
      when '7' => result := 7;
      when '8' => result := 8;
      when '9' => result := 9;
      when 'a' => result := 10;
      when 'b' => result := 11;
      when 'c' => result := 12;
      when 'd' => result := 13;
      when 'e' => result := 14;
      when 'f' => result := 15;
      when 'A' => result := 10;
      when 'B' => result := 11;
      when 'C' => result := 12;
      when 'D' => result := 13;
      when 'E' => result := 14;
      when 'F' => result := 15;
      when others => result := -1;
    end case;
    return result;
  end charToDigitVal;
  
  -----------------------------------------------------------------------------
  -- Tests whether two characters match, ignoring case
  -----------------------------------------------------------------------------
  function charsEqual(
    a: character;
    b: character
  ) return boolean is
  begin
    return upperChar(a) = upperChar(b);
  end charsEqual;
  
  -----------------------------------------------------------------------------
  -- Tests whether line contains match at position pos (case insensitive)
  -----------------------------------------------------------------------------
  function matchAt(
    line  : in string;
    pos   : in positive;
    match : in string
  ) return boolean is
    variable posInt: positive;
  begin
    posInt := pos;
    for matchPos in match'range loop
      if posInt > line'length then
        return false;
      end if;
      if not charsEqual(match(matchPos), line(posInt)) then
        return false;
      end if;
      posInt := posInt + 1;
    end loop;
    return true;
  end matchAt;
  
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
    
    -- Test for 0x marker for hexadecimal entry, 0b for binary entry or - for
    -- a negative decimal number.
    if matchAt(line, pos, "0x") then
      radix := 16;
      negative := false;
      pos := pos + 2;
    elsif matchAt(line, pos, "0b") then
      radix := 2;
      negative := false;
      pos := pos + 2;
    elsif matchAt(line, pos, "-") then
      radix := 10;
      negative := true;
      pos := pos + 1;
    else
      radix := 10;
      negative := false;
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
  -- Attempts to assemble the given instruction
  -----------------------------------------------------------------------------
  procedure asAttempt(
    
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
    charsValid := 0;
    error := to_rvs("unknown error");
    
    -- Scan beyond any initial whitespace.
    sourcePos := 1;
    patternPos := 1;
    scanToEndOfWhitespace(source, sourcePos);
    scanToEndOfWhitespace(pattern, patternPos);
    
    -- Scan tokens until one or both of the scanners reach the end of their
    -- respective strings.
    while (sourcePos <= source'length) and (patternPos <= pattern'length) loop
      
      report "scanning token at " & integer'image(sourcePos) severity warning;
      
      -- Scan according to the next token in the pattern.
      if matchAt(pattern, patternPos, "%r1") then -- Bit 22..17 in unsigned decimal.
        patternPos := patternPos + 3;
        scanToEndOfWhitespace(pattern, patternPos);
        scanNumeric(source, sourcePos, val, stepOk);
        if (not stepOk) or (to_integer(val(32 downto 6)) /= 0)  then
          error := to_rvs("unknown register");
          return;
        end if;
        syllable(22 downto 17) := std_logic_vector(val(5 downto 0));
      elsif matchAt(pattern, patternPos, "%r2") then -- Bit 16..11 in unsigned decimal.
        patternPos := patternPos + 3;
        scanToEndOfWhitespace(pattern, patternPos);
        scanNumeric(source, sourcePos, val, stepOk);
        if (not stepOk) or (to_integer(val(32 downto 6)) /= 0)  then
          error := to_rvs("unknown register");
          return;
        end if;
        syllable(16 downto 11) := std_logic_vector(val(5 downto 0));
      elsif matchAt(pattern, patternPos, "%r3") then -- Bit 10..5 in unsigned decimal.
        patternPos := patternPos + 3;
        scanToEndOfWhitespace(pattern, patternPos);
        scanNumeric(source, sourcePos, val, stepOk);
        if (not stepOk) or (to_integer(val(32 downto 6)) /= 0)  then
          error := to_rvs("unknown register");
          return;
        end if;
        syllable(10 downto 5) := std_logic_vector(val(5 downto 0));
      elsif isAlphaChar(pattern(patternPos)) then
        scanAndCompareIdentifier(source, sourcePos, pattern, patternPos, stepOk);
        if not stepOk then
          error := to_rvs("invalid token hello");
          return;
        end if;
      else
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
      
      report "token scanned, now at " & integer'image(sourcePos) severity warning;
      
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
    
  end asAttempt;
  
end rvex_simUtils_asDisas_pkg;
