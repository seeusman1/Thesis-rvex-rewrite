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

library work;
use work.opcode_pkg_orig.all;

entity mul_orig is
  port (
    clk        : in  std_logic;         -- system clock
    clk_enable : in  std_logic;
    reset      : in  std_logic;         -- system reset
    mulop      : in  std_logic_vector(7 downto 0);    -- operation
    src1       : in  std_logic_vector(31 downto 0);   -- operand 1
    src2       : in  std_logic_vector(31 downto 0);   -- operand 2
    result     : out std_logic_vector(31 downto 0));  -- result of operation

  attribute mult_style        : string;  -- xilinx attribute to enable balanced pipelined design
  --attribute mult_style of mul: entity is "pipe_lut";
  attribute mult_style of mul_orig : entity is "pipe_block";

end entity mul_orig;


architecture behavioural of mul_orig is

  signal s1 : signed (32 downto 0) := (others => '0');
  signal s2 : signed (16 downto 0) := (others => '0');

  signal temp1      : std_logic_vector (49 downto 0) := (others => '0');
  signal result_shl : std_logic_vector (31 downto 0) := (others => '0');
  signal result_shr16 : std_logic_vector (31 downto 0) := (others => '0');
  signal result_shr32 : std_logic_vector (31 downto 0) := (others => '0');

  signal mux_select   : std_logic := '1';
  signal mux_select_r : std_logic;
  signal mux_selectr16 : std_logic := '0';
  signal mux_selectr32 : std_logic := '0';
  signal mux_selectr16_r : std_logic;
  signal mux_selectr32_r : std_logic;

begin
  source_selection : process(clk)
  begin
    if rising_edge(clk) then
      if (reset = '1') then
        mux_select <= '1';
        s1         <= (others => '0');
        s2         <= (others => '0');
      elsif clk_enable = '1' then
        mux_selectr16 <= '0';
        mux_selectr32 <= '0';
        if (std_match(mulop, MUL_MPYLL))then
          mux_select <= '1';
          s1         <= resize(signed(src1(15 downto 0)), 33);
          s2         <= resize(signed(src2(15 downto 0)), 17);
        elsif (std_match(mulop, MUL_MPYLLU))then
          mux_select <= '1';
          s1         <= signed('0' & x"0000" & src1(15 downto 0));
          s2         <= signed('0' & src2(15 downto 0));
        elsif (std_match(mulop, MUL_MPYLH))then
          mux_select <= '1';
          s1         <= resize(signed(src1(15 downto 0)), 33);
          s2         <= resize(signed(src2(31 downto 16)), 17);
        elsif (std_match(mulop, MUL_MPYLHU))then
          mux_select <= '1';
          s1         <= signed('0' & x"0000" & src1(15 downto 0));
          s2         <= signed('0' & src2(31 downto 16));
        elsif (std_match(mulop, MUL_MPYHH))then
          mux_select <= '1';
          s1         <= resize(signed(src1(31 downto 16)), 33);
          s2         <= resize(signed(src2(31 downto 16)), 17);
        elsif (std_match(mulop, MUL_MPYHHU))then
          mux_select <= '1';
          s1         <= signed('0' & x"0000" & src1(31 downto 16));
          s2         <= signed('0' & src2(31 downto 16));
        elsif (std_match(mulop, MUL_MPYL))then
          mux_select <= '1';
          s1         <= resize(signed(src1), 33);
          s2         <= resize(signed(src2(15 downto 0)), 17);
        elsif (std_match(mulop, MUL_MPYLU))then
          mux_select <= '1';
          s1         <= signed('0' & src1);
          s2         <= signed('0' & src2(15 downto 0));
        elsif (std_match(mulop, MUL_MPYH))then
          mux_select <= '1';
          s1         <= resize(signed(src1), 33);
          s2         <= resize(signed(src2(31 downto 16)), 17);
        elsif (std_match(mulop, MUL_MPYHU))then
          mux_select <= '1';
          s1         <= signed('0' & src1);
          s2         <= signed('0' & src2(31 downto 16));
        elsif (std_match(mulop, MUL_MPYHS))then
          mux_select <= '0';
          s1         <= resize(signed(src1), 33);
          s2         <= resize(signed(src2(31 downto 16)), 17);
        elsif (std_match(mulop, MUL_MPYHHS))then
          mux_select <= '0';
          mux_selectr16 <= '1';
          s1         <= resize(signed(src1), 33);
          s2         <= resize(signed(src2(31 downto 16)), 17);
        elsif (std_match(mulop, MUL_MPYLHUS))then
          mux_select <= '0';
          mux_selectr32 <= '1';
          s1         <= resize(signed(src1), 33);
          s2         <= signed('0' & src2(15 downto 0));
        else                            -- if not MUL_OP
          mux_select <= '1';
          s1         <= (others => '0');
          s2         <= (others => '0');
        end if;
      end if;
    end if;
  end process source_selection;

  result_shl <= std_logic_vector(shift_left(unsigned(temp1(31 downto 0)), 16));  -- MUL_MPYHS
  result_shr16 <= std_logic_vector(unsigned(temp1(47 downto 16)));  -- MUL_MPYHHS
  result_shr32 <= std_logic_vector(resize(signed(temp1(47 downto 32)), 32));  -- MUL_MPYLHUS
  result     <= temp1(31 downto 0)  when mux_select_r = '1' else 
                result_shr16        when mux_selectr16_r = '1' else
                result_shr32        when mux_selectr32_r = '1' else 
                result_shl;

  MUX1_32bit_2to1 : process(clk)
  begin
    if rising_edge(clk) then
      if clk_enable = '1' then
        temp1        <= std_logic_vector(s1 * s2);
        mux_select_r <= mux_select;
        mux_selectr16_r <= mux_selectr16;
        mux_selectr32_r <= mux_selectr32;
      end if;
    end if;
  end process MUX1_32bit_2to1;

end architecture behavioural;
