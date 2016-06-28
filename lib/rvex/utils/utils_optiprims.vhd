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
use IEEE.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

--=============================================================================
-- Optimized primitives
--=============================================================================
-- This file contains some primitives that are not adequatly optimized by
-- the FPGA synthesis tools (priority multiplexers, priority decoders, etc.).
-- They use primitives, so they only work for Virtex 6 and Virtex 7 FPGAs.

-------------------------------------------------------------------------------
-- Priority decoder implemented using carry logic (if NUM_LOG2 >= 4). The MSB
-- has the highest priority. The decoder will output 0 when none of the inputs
-- are active.
-------------------------------------------------------------------------------
entity utils_priodec is
  generic (
    NUM_LOG2  : natural := 5
  );
  port (
    inp       : in  std_logic_vector(2**NUM_LOG2-1 downto 0);
    outp      : out std_logic_vector(NUM_LOG2-1 downto 0)
  );
end utils_priodec;

architecture behavioural of utils_priodec is
begin
  
  -- Generate a carry4-based instantiation for priority decoders which have
  -- at least 16 inputs. Otherwise just use whatever the behavioral description
  -- produces.
  large_gen: if NUM_LOG2 >= 4 generate
    
    -- The output bits are computed independently in parallel.
    bit_gen: for b in NUM_LOG2-1 downto 0 generate
      signal cy : std_logic_vector(2**NUM_LOG2/16 downto 0);
    begin
      cy(0) <= '0';
      
      -- Infer the carry chain 4 bits at a time, because the carry4 block is
      -- 4 bits long.
      chain_gen: for c in 2**NUM_LOG2/16-1 downto 0 generate
        signal o5, o6, co : std_logic_vector(3 downto 0);
      begin
        
        -- We don't need to generate the earlier parts of the chains if they
        -- can only ever output 0.
        significant_gen: if c*16+15 >= 2**b generate
        begin
          
          -- Infer a LUT for each carry chain bit.
          lut_gen: for d in 3 downto 0 generate
            
            -- This function generates the LUT data for the LUT below.
            pure function lut_data(
              index : natural;
              bi    : natural
            ) return bit_vector is
              variable i      : natural;
              variable x      : bit_vector(3 downto 0);
              variable retval : bit_vector(63 downto 0);
            begin
              
              -- Figure out which bit value we need to inject for each input.
              for k in 0 to 3 loop
                i := c*16 + d*4 + k;
                if (i / 2**b) mod 2 = 1 then
                  x(k) := '1';
                else
                  x(k) := '0';
                end if;
              end loop;
              
              retval := (
                -- O6 output: whether or not to pass through the incoming data.
                47 downto 33 => '0', -- One of the inputs is active.
                32 => '1',           -- None of the inputs are active.
                
                -- O5 output: data to inject into the carry network.
                15 downto 8 => x(3), -- Input 3 has priority.
                7 downto 4 => x(2),  -- Input 2 has priority.
                3 downto 2 => x(1),  -- Input 1 has priority.
                1 => x(0),           -- Input 0 has priority.
                0 => '0',            -- None of the inputs are active.
                
                others => '0'
              );
              
              return retval;
            end lut_data;
            
          begin
          
            -- Generate a LUT which combines 4 inputs to 1 output bit at once
            -- to drive one bit of the carry network.
            lut_inst: lut6_2
              generic map (
                INIT => lut_data(c*16 + d*4, b)
              )
              port map (
                i0 => inp(c*16 + d*4 + 0),
                i1 => inp(c*16 + d*4 + 1),
                i2 => inp(c*16 + d*4 + 2),
                i3 => inp(c*16 + d*4 + 3),
                i4 => '0',
                i5 => '1',
                o5 => o5(d),
                o6 => o6(d)
              );
            
            -- The attempt below at inferring this LUT failed. How retarded are
            -- these tools?
            --lut_proc: process (inp) is
            --  variable i : natural;
            --begin
            --  o5(d) <= '0';
            --  o6(d) <= '1';
            --  for i in c*16 + d*4 to c*16 + d*4 + 3 loop
            --    if inp(i) = '1' then
            --      if (i / 2**b) mod 2 = 1 then
            --        o5(d) <= '1';
            --      else
            --        o5(d) <= '0';
            --      end if;
            --      o6(d) <= '0';
            --    end if;
            --  end loop;
            --end process;
            
          end generate;
          
          -- Instantiate the carry4 primitive, which is what this is all about.
          carry4_inst: carry4
            port map (
              ci => cy(c),
              di => o5,
              s  => o6,
              co => co
            );
          
          cy(c+1) <= co(3);
        
        end generate;
        
        insignificant_gen: if c*16+15 < 2**b generate
          cy(c+1) <= '0';
        end generate;
        
      end generate;
      
      -- The carry out is the desired output bit.
      outp(b) <= cy(2**NUM_LOG2/16);
      
    end generate;
  end generate;
  
  -- Use a standard behavioral specification for small decoders.
  small_gen: if NUM_LOG2 < 4 generate
    
    behav_proc: process (inp) is
    begin
      outp <= (others => '0');
      for i in 0 to 2**NUM_LOG2-1 loop
        if inp(i) = '1' then
          outp <= std_logic_vector(to_unsigned(i, NUM_LOG2));
        end if;
      end loop;
    end process;
    
  end generate;

end architecture;

-- pragma translate_off

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity utils_priodec_tb is
end utils_priodec_tb;

architecture testbench of utils_priodec_tb is
  constant NUM_LOG2 : natural := 7;
  signal inp        : std_logic_vector(2**NUM_LOG2-1 downto 0);
  signal outp       : std_logic_vector(NUM_LOG2-1 downto 0);
begin
  
  uut: entity work.utils_priodec
    generic map (
      NUM_LOG2  => NUM_LOG2
    )
    port map (
      inp       => inp,
      outp      => outp
    );
  
  stim_proc: process is
  begin
    for i1 in -1 to 2**NUM_LOG2-1 loop
      for i2 in -1 to 2**NUM_LOG2-1 loop
        for i3 in 0 to 2**NUM_LOG2-1 loop
          inp <= (i3 => '1', others => '0');
          if i2 >= 0 then
            inp(i2) <= '1';
          end if;
          if i1 >= 0 then
            inp(i1) <= '1';
          end if;
          wait for 1 ns;
        end loop;
      end loop;
    end loop;
  end process;
  
end architecture;

-- pragma translate_on

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity utils_priodec_speedtest is
  generic (
    NUM_LOG2  : natural := 7
  );
  port (
    clk       : in  std_logic;
    inp       : in  std_logic_vector(2**NUM_LOG2-1 downto 0);
    outp      : out std_logic_vector(NUM_LOG2-1 downto 0)
  );
end utils_priodec_speedtest;

architecture behavioral of utils_priodec_speedtest is
  signal inp_i      : std_logic_vector(2**NUM_LOG2-1 downto 0);
  signal outp_i     : std_logic_vector(NUM_LOG2-1 downto 0);
begin
  
  uut: entity work.utils_priodec
    generic map (
      NUM_LOG2  => NUM_LOG2
    )
    port map (
      inp       => inp_i,
      outp      => outp_i
    );
  
  process (clk) is
  begin
    if rising_edge(clk) then
      inp_i <= inp;
      outp <= outp_i;
    end if;
  end process;
  
end architecture;
