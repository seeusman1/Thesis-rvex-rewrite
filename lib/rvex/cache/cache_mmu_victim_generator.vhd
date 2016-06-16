-- r-VEX processor MMU
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

-- 7. The MMU was developed by Jens Johansen.

-- Copyright (C) 2008-2016 by TU Delft.

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.MATH_REAL.ALL;

library rvex;
use rvex.cache_pkg.all;
use rvex.common_pkg.all;


entity cache_mmu_victim_generator is 
  generic (
    CCFG                        : cache_generic_config_type
  );
  port (
    clk                         : in  std_logic;
    reset                       : in  std_logic;
    
    -- array of valid bits. non-valid entries are preferred for replacement
    valid                       : in  std_logic_vector(2**CCFG.TLBDepthLog2-1 downto 0);
    
    -- update victim output
    victim_next                 : in  std_logic;
    
    -- victim output (one-hot encoded)
    victim                      : out std_logic_vector(2**CCFG.TLBDepthLog2-1 downto 0)
  );
  
end entity cache_mmu_victim_generator;


architecture behavioural of cache_mmu_victim_generator is
  
  type r_victim_gen is record
      lfsr                    : std_logic_vector(15 downto 0);
  end record;
  
  constant WIDTHLOG2          : integer := CCFG.TLBDepthLog2;
  constant WIDTH              : integer := 2**WIDTHLOG2;
  constant R_INIT             : r_victim_gen := ( lfsr  => x"BABE" 
                                                  );
                                                  
  signal r, r_in              : r_victim_gen := R_INIT;
  signal update_lfsr          : std_logic;
  signal lfsr_tail            : std_logic_vector(WIDTHLOG2-1 downto 0);
  signal lfsr_oh              : std_logic_vector(WIDTH-1 downto 0);
  
begin

  comb_proc: process(
    r, valid, victim_next, update_lfsr, lfsr_tail, lfsr_oh)
  is
    variable v_lfsr_oh : std_logic_vector(WIDTH-1 downto 0);
  begin
    -- initialize registers
    r_in <= r;
    
    -- initialize signals 
    update_lfsr <= '0';
    victim <= (others => '0');
    
    -- truncate the 16 bit lfsr to the amount of memory locations
    lfsr_tail <= r.lfsr(WIDTHLOG2-1 downto 0);
    
    -- convert lfsr to one-hot 
    v_lfsr_oh := (others => '0');
    for i in 0 to WIDTH-1 loop
      if to_integer(unsigned(lfsr_tail)) = i then
        v_lfsr_oh(i) := '1';
        exit;
      end if;
    end loop;
    lfsr_oh <= v_lfsr_oh;
    
    -- select the first valid entry as victim. 
    -- if all entries are filled, select one randomly and update lfsr.
    if valid /= (valid'length-1 downto 0 => '1') then
      for i in 0 to WIDTH-1 loop
        if valid(i) = '0' then
          victim(i) <= '1';
          exit;
        end if;
      end loop;
    else
      victim <= lfsr_oh;
      update_lfsr <= victim_next;
    end if;
    
    -- update lfsr
    if update_lfsr = '1' then 
      r_in.lfsr <= r.lfsr(14 downto 0) & (r.lfsr(10) xor ( r.lfsr(12) xor ( r.lfsr(13) xor r.lfsr(15) ) ) );
    end if;
    
  end process;
  
  
  reg_proc: process(clk) 
  begin
    if rising_edge(clk) then
      if reset = '1' then
        r <= R_INIT;
      else
        r <= r_in;
      end if;
    end if;
  end process;
  
end architecture;

