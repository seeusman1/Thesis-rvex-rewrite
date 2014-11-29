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
use IEEE.numeric_std.all;
use IEEE.math_real.all;

library work;
use work.rvex_pkg.all;
use work.rvex_pipeline_pkg.all;
use work.rvex_opcode_pkg.all;
use work.rvex_opcodeMultiplier_pkg.all;

entity mul_cmp_tb is
end entity mul_cmp_tb;

architecture behavioural of mul_cmp_tb is
  
  -- Control signals.
  signal reset                  : std_logic;
  signal clk                    : std_logic;
  
  -- Opcode to test.
  signal mnemonic               : string(1 to 50);
  signal opcode                 : std_logic_vector(7 downto 0);
  
  -- Input operands.
  signal op1                    : std_logic_vector(31 downto 0);
  signal op2                    : std_logic_vector(31 downto 0);
  
  -- Outputs.
  signal resultOld              : std_logic_vector(31 downto 0);
  signal resultNew              : std_logic_vector(31 downto 0);
  
  -- Whether the current result is correct ('1') or not ('X').
  signal correct                : std_logic;
  
  -- Sync signal. Strobes every 10 ns. Used to align things nicely in the
  -- simulation.
  signal sync                   : std_logic;
  
  -- Number of tests run.
  signal testCount              : unsigned(31 downto 0);
  
begin
  
  -- Instantiate the old multiplier.
  uut_old: entity work.mul_orig
    port map (
      clk                         => clk,
      clk_enable                  => '1',
      reset                       => reset,
      mulop                       => opcode,
      src1                        => op1,
      src2                        => op2,
      result                      => resultOld
    );
  
  -- Instantiate the new multiplier.
  uut_new: entity work.rvex_mulu
    generic map (
      CFG => RVEX_DEFAULT_CONFIG
    )
    port map (
      reset                       => reset,
      clk                         => clk,
      clkEn                       => '1',
      stall                       => '0',
      
      pl2mulu_opcode(S_MUL)       => opcode,
      pl2mulu_op1(S_MUL)          => op1,
      pl2mulu_op2(S_MUL)          => op2,
      mulu2pl_result(S_MUL+L_MUL) => resultNew
    );
  
  -- Generate sync signal.
  sync_gen: process is
  begin
    sync <= '1';
    wait for 1 ps;
    sync <= '0';
    wait for 9999 ps;
  end process;
  
  -- Generate stimuli.
  stim: process is
    
    -- Seed values for random operand generation.
    variable seed1, seed2 : positive;
    
    -- Random number.
    variable rand         : real;
    variable int_rand     : integer;
    
    -- Sends clock pulses and verifies that the results match.
    procedure test is
    begin
      wait for 1 ps;
      clk <= '1';
      wait for 1 ps;
      clk <= '0';
      wait for 1 ps;
      clk <= '1';
      wait for 1 ps;
      clk <= '0';
      if resultOld /= resultNew then
        report "Inconsistency found!" severity warning;
        correct <= 'X';
        wait until rising_edge(sync);
      else
        correct <= '1';
      end if;
    end procedure;
    
    -- Tests all opcodes for the current inputs.
    procedure testAll is
      variable oldAluValid      : boolean;
    begin
      for i in 0 to 255 loop
        if OPCODE_TABLE(i).multiplierCtrl.isMultiplyInstruction = '1' then
          mnemonic <= OPCODE_TABLE(i).syntax_reg;
          opcode <= std_logic_vector(to_unsigned(i, 8));
          test;
        end if;
      end loop;
      wait until rising_edge(sync);
    end procedure;
    
  begin
    testCount <= (others => '0');
    reset <= '1';
    correct <= '1';
    wait for 1 ps;
    clk <= '1';
    wait for 1 ps;
    clk <= '0';
    reset <= '0';
    loop
      
      -- Generate random integer operands.
      uniform(seed1, seed2, rand);
      int_rand := integer(trunc(rand*65536.0));
      op1(15 downto 0) <= std_logic_vector(to_unsigned(int_rand, 16));
      uniform(seed1, seed2, rand);
      int_rand := integer(trunc(rand*65536.0));
      op1(31 downto 16) <= std_logic_vector(to_unsigned(int_rand, 16));
      uniform(seed1, seed2, rand);
      int_rand := integer(trunc(rand*65536.0));
      op2(15 downto 0) <= std_logic_vector(to_unsigned(int_rand, 16));
      uniform(seed1, seed2, rand);
      int_rand := integer(trunc(rand*65536.0));
      op2(31 downto 16) <= std_logic_vector(to_unsigned(int_rand, 16));
      
      -- Run the test.
      testAll;
      
      -- Increment test counter.
      testCount <= testCount + 1;
      
    end loop;
    
  end process;
  
end architecture behavioural;
