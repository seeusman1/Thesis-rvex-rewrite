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

-- 6. r-VEX was developed by Stephan Wong, Thijs van As, Fakhar Anjam,
-- Roel Seedorf, Anthony Brandon, Jeroen van Straten. r-VEX is currently
-- maintained by TU Delft (J.S.S.M.Wong@tudelft.nl).

-- Copyright (C) 2008-2014 by TU Delft.

-- Refer to reconfCache_pkg.vhd for configuration constants and most
-- documentation.

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.math_real.ALL;

-- Random signal generator for testbenches.
entity cache_tb_rng is
  generic (
    
    -- Random number generator seed.
    seed        : natural := 1;
    
    -- Reset signal state.
    resetState  : std_logic := '0';
    
    -- Probability that the signal will be high.
    highProb    : real := 0.5
    
  );
  port (
    
    -- Clock input.
    clk         : in  std_logic;
    
    -- Reset input.
    reset       : in  std_logic;
    
    -- Clock enable input.
    clkEn       : in  std_logic;
    
    -- Signal output.
    sig         : out std_logic
    
  );
end cache_tb_rng;

architecture Behavioral of cache_tb_rng is
begin
  
  process is
    variable seed1, seed2 : positive;
    variable rand : real;
  begin
    loop
      seed1 := seed;
      seed2 := 1;
      sig <= resetState;
      loop
        wait until rising_edge(clk) and clkEn = '1';
        exit when reset = '1';
        uniform(seed1, seed2, rand);
        if highProb > rand then
          sig <= '1';
        else
          sig <= '0';
        end if;
      end loop;
    end loop;
  end process;
  
end Behavioral;

