-- insert license here

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--=============================================================================
-- This package contains simulation-only utilities, primarily focussed on
-- string manipulation.
-------------------------------------------------------------------------------
package rvex_simUtils_pkg is
--=============================================================================
  
  -- Global string length for all operations which operate on fixed string
  -- lengths for simplicity.
  constant RVEX_STR_LEN         : positive := 256;
  
  -- Fixed string type.
  subtype rvex_string_type is string(1 to RVEX_STR_LEN);
  type rvex_string_array is array (natural range <>) of rvex_string_type;
  
  -- "String builder" type. This includes an integer with the current string
  -- length to prevent recomputation all the time.
  type rvex_string_builder_type is record
    s: rvex_string_type;
    len: positive range 1 to RVEX_STR_LEN;
  end record;
  type rvex_string_builder_array is array (natural range <>) of rvex_string_builder_type;
  
  -- Clears a string builder.
  procedure rvs_clear(sb: inout rvex_string_builder_type);
  
  -- Converts a VHDL unbounded string to a string builder.
  function to_rvs(input: string) return rvex_string_builder_type;
  
  -- Concatenation operator for two string builders.
  function "&"(L: rvex_string_builder_type; R: rvex_string_builder_type) return rvex_string_builder_type;
  
  -- Concatenation operator for a string builder and a VHDL string.
  function "&"(L: rvex_string_builder_type; R: string) return rvex_string_builder_type;
  
  -- Appends a VHDL string to a string builder.
  procedure rvs_append(sb: inout rvex_string_builder_type; s: string);
  
  -- Converts a nul-terminated fixed length string, VHDL string or string
  -- builder to a whitespace-terminated fixed length string for simulation.
  function rvs2sim(input: rvex_string_builder_type) return rvex_string_type;
  
  -- Converts an unsigned std_logic_vector to a string, representing it in
  -- decimal notation.
  function rvs_uint(value: std_logic_vector) return string;
  
  -- Converts a signed std_logic_vector to a string, representing it in decimal
  -- notation.
  function rvs_int(value: std_logic_vector) return string;
  
  -- Converts an std_logic_vector to a string in hexadecimal notation.
  function rvs_hex(value: std_logic_vector) return string;
  function rvs_hex(value: std_logic_vector; digits: natural) return string;
  
  -- Extracts the range (high downto low) from value, with safeguards to
  -- prevent errors when the range does not (fully) exist in value of when
  -- value has an ascending (x to y) range. Bits which do not exist in value
  -- are substituted with def.
  function rvs_extractStdLogicVectRange(value: std_logic_vector; high: natural; low: natural; def: std_logic) return std_logic_vector;
  
end rvex_simUtils_pkg;

--=============================================================================
package body rvex_simUtils_pkg is
--=============================================================================
  
  -- Clears a string builder.
  procedure rvs_clear(sb: inout rvex_string_builder_type) is
  begin
    sb.len := 0;
  end rvs_clear;
  
  -- Converts a VHDL unbounded string to a string builder.
  function to_rvs(input: string) return rvex_string_builder_type is
    variable result: rvex_string_builder_type;
  begin
    if input'high > RVEX_STR_LEN then
      result.s := input(1 to RVEX_STR_LEN);
      result.len := RVEX_STR_LEN;
    else
      result.s(input'range) := input;
      result.len := input'length;
    end if;
    return result;
  end to_rvs;
  
  -- Concatenation operator for two string builders.
  function "&"(L: rvex_string_builder_type; R: rvex_string_builder_type) return rvex_string_builder_type is
    variable result: rvex_string_builder_type;
  begin
    result.s := L.s;
    if L.len + R.len <= RVEX_STR_LEN then
      result.s(L.len+1 to L.len+R.len) := R.s(1 to R.len);
      result.len := L.len + R.len;
    else
      result.s(L.len+1 to RVEX_STR_LEN) := R.s(1 to RVEX_STR_LEN-L.len);
      result.len := RVEX_STR_LEN;
    end if;
    return result;
  end "&";
  
  -- Concatenation operator for a string builder and a VHDL string.
  function "&"(L: rvex_string_builder_type; R: string) return rvex_string_builder_type is
    variable result: rvex_string_builder_type;
  begin
    result := L;
    rvs_append(result, R);
    return result;
  end "&";
  
  -- Appends a VHDL string to a string builder.
  procedure rvs_append(sb: inout rvex_string_builder_type; s: string) is
  begin
    if sb.len + s'length <= RVEX_STR_LEN then
      sb.s(sb.len+1 to sb.len+s'length) := s;
      sb.len := sb.len + s'length;
    else
      sb.s(sb.len+1 to sb.len+s'length) := s;
      sb.len := sb.len + s'length;
    end if;
  end rvs_append;
  
  -- Converts a nul-terminated fixed length string, VHDL string or string
  -- builder to a whitespace-terminated fixed length string for simulation.
  function rvs2sim(input: rvex_string_builder_type) return rvex_string_type is
    variable result: rvex_string_type;
  begin
    result := (others => ' ');
    result(1 to input.len) := input.s(1 to input.len);
    return result; 
  end rvs2sim;
  
  -- Converts an unsigned std_logic_vector to a string, representing it in
  -- decimal notation.
  function rvs_uint(value: std_logic_vector) return string is
    variable temp : unsigned(value'range);
    variable digit : integer;
    variable s : string(1 to RVEX_STR_LEN);
    variable index : natural;
  begin
    temp := unsigned(value);
    if temp = 0 then
      return "0";
    end if;
    index := RVEX_STR_LEN;
    while temp > 0 loop
      digit := to_integer(temp mod 10);
      temp := temp / 10;
      case digit is
        when 0 => s(index) := '0';
        when 1 => s(index) := '1';
        when 2 => s(index) := '2';
        when 3 => s(index) := '3';
        when 4 => s(index) := '4';
        when 5 => s(index) := '5';
        when 6 => s(index) := '6';
        when 7 => s(index) := '7';
        when 8 => s(index) := '8';
        when 9 => s(index) := '9';
        when others => s(index) := '?';
      end case;
      index := index - 1;
    end loop;
    return s(index+1 to RVEX_STR_LEN);
  end rvs_uint;
  
  -- Converts a signed std_logic_vector to a string, representing it in decimal
  -- notation.
  function rvs_int(value: std_logic_vector) return string is
  begin
    if signed(value) = 0 then
      return "0";
    elsif signed(value) > 0 then
      return rvs_uint(value);
    else
      return "-" & rvs_uint(std_logic_vector(0-unsigned(value)));
    end if;
  end rvs_int;
  
  -- Converts an std_logic_vector to a string in hexadecimal notation.
  function rvs_hex(value: std_logic_vector) return string is
  begin
    return rvs_hex(value, value'high / 4 + 1);
  end rvs_hex;
  function rvs_hex(value: std_logic_vector; digits: natural) return string is
    variable s : string(1 to digits + 2);
    variable temp : std_logic_vector(3 downto 0);
  begin
    s(1 to 2) := "0x";
    for i in 0 to digits-1 loop
      temp := to_X01Z(rvs_extractStdLogicVectRange(value, i*4+3, i*4, '0'));
      case temp is
        when "0000" => s(digits+2-i) := '0';
        when "0001" => s(digits+2-i) := '1';
        when "0010" => s(digits+2-i) := '2';
        when "0011" => s(digits+2-i) := '3';
        when "0100" => s(digits+2-i) := '4';
        when "0101" => s(digits+2-i) := '5';
        when "0110" => s(digits+2-i) := '6';
        when "0111" => s(digits+2-i) := '7';
        when "1000" => s(digits+2-i) := '8';
        when "1001" => s(digits+2-i) := '9';
        when "1010" => s(digits+2-i) := 'A';
        when "1011" => s(digits+2-i) := 'B';
        when "1100" => s(digits+2-i) := 'C';
        when "1101" => s(digits+2-i) := 'D';
        when "1110" => s(digits+2-i) := 'E';
        when "1111" => s(digits+2-i) := 'F';
        when "XXXX" => s(digits+2-i) := 'X';
        when "ZZZZ" => s(digits+2-i) := 'Z';
        when others => s(digits+2-i) := '?';
      end case;
    end loop;
    return s;
  end rvs_hex;
  
  -- Extracts the range (high downto low) from value, with safeguards to
  -- prevent errors when the range does not (fully) exist in value of when
  -- value has an ascending (x to y) range. Bits which do not exist in value
  -- are substituted with def.
  function rvs_extractStdLogicVectRange(value: std_logic_vector; high: natural; low: natural; def: std_logic) return std_logic_vector is
    variable result: std_logic_vector(high downto low);
  begin
    for i in high downto low loop
      if (i < value'low) or (i > value'high) then
        result(i) := def;
      else
        result(i) := value(i);
      end if;
    end loop;
    return result;
  end rvs_extractStdLogicVectRange;
  
end rvex_simUtils_pkg;
