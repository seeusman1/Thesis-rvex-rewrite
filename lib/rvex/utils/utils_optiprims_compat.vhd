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

--=============================================================================
-- Optimized primitives compatibility package
--=============================================================================
-- This file contains behavioral versions of the Virtex-6/7 hand-optimized
-- primitives for other synthesis targets.

-------------------------------------------------------------------------------
-- Wide or gate.
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity utils_wideor is
  generic (
    WIDTH     : natural := 32
  );
  port (
    inp       : in  std_logic_vector(WIDTH-1 downto 0);
    outp      : out std_logic;
    
    -- Bit i is high when inp(0..i*6+5) is nonzero.
    outp_int  : out std_logic_vector((WIDTH+5)/6-1 downto 0)
  );
end utils_wideor;

architecture behavioural of utils_wideor is
begin
  
  behav_proc: process (inp) is
    variable flag : std_logic;
  begin
    flag := '0';
    for i in 0 to WIDTH-1 loop
      flag := flag or inp(i);
      if i mod 6 = 5 then
        outp_int(i/6) <= flag;
      end if;
    end loop;
    outp_int((WIDTH+5)/6-1) <= flag;
    outp <= flag;
  end process;
  
end architecture;

-- pragma translate_off

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity utils_wideor_tb is
end utils_wideor_tb;

architecture testbench of utils_wideor_tb is
  constant WIDTH    : natural := 32;
  signal inp        : std_logic_vector(WIDTH-1 downto 0);
  signal outp       : std_logic;
  signal outp_int   : std_logic_vector((WIDTH+5)/6-1 downto 0);
begin
  
  uut: entity work.utils_wideor
    generic map (
      WIDTH     => WIDTH
    )
    port map (
      inp       => inp,
      outp      => outp,
      outp_int  => outp_int
    );
  
  stim_proc: process is
  begin
    inp <= (others => '0');
    wait for 1 ns;
    for i1 in -1 to WIDTH-1 loop
      for i2 in -1 to WIDTH-1 loop
        for i3 in 0 to WIDTH-1 loop
          inp <= (others => '0');
          inp(i3) <= '1';
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

-------------------------------------------------------------------------------
-- Priority decoder implemented using carry logic (if NUM_LOG2 >= 4). The MSB
-- has the highest priority. The decoder will output 0 when none of the inputs
-- are active.
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity utils_priodec is
  generic (
    NUM_LOG2  : natural := 5
  );
  port (
    inp       : in  std_logic_vector(2**NUM_LOG2-1 downto 0);
    outp      : out std_logic_vector(NUM_LOG2-1 downto 0);
    any       : out std_logic
  );
end utils_priodec;

architecture behavioural of utils_priodec is
  signal outl : std_logic_vector(NUM_LOG2-1 downto 0);
begin
  
  behav_proc: process (inp) is
  begin
    outl <= (others => '0');
    for i in 0 to 2**NUM_LOG2-1 loop
      if inp(i) = '1' then
        outl <= std_logic_vector(to_unsigned(i, NUM_LOG2));
      end if;
    end loop;
  end process;
  
  -- Forward the output.
  outp <= outl;
  
  -- Generate the any signal.
  any_block: block is
    signal or_inp : std_logic_vector(NUM_LOG2 downto 0);
  begin
    or_inp(NUM_LOG2 downto 1) <= outl;
    or_inp(0)                 <= inp(0);
    
    any_wideor_inst: entity work.utils_wideor
      generic map (
        WIDTH => NUM_LOG2 + 1
      )
      port map (
        inp                     => or_inp,
        outp                    => any
      );
  end block;
  
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
  signal any        : std_logic;
begin
  
  uut: entity work.utils_priodec
    generic map (
      NUM_LOG2  => NUM_LOG2
    )
    port map (
      inp       => inp,
      outp      => outp,
      any       => any
    );
  
  stim_proc: process is
  begin
    for i1 in -1 to 2**NUM_LOG2-1 loop
      for i2 in -1 to 2**NUM_LOG2-1 loop
        for i3 in 0 to 2**NUM_LOG2-1 loop
          inp <= (others => '0');
          inp(i3) <= '1';
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
    outp      : out std_logic_vector(NUM_LOG2-1 downto 0);
    any       : out std_logic
  );
end utils_priodec_speedtest;

architecture behavioral of utils_priodec_speedtest is
  signal inp_i      : std_logic_vector(2**NUM_LOG2-1 downto 0);
  signal outp_i     : std_logic_vector(NUM_LOG2-1 downto 0);
  signal any_i      : std_logic;
begin
  
  uut: entity work.utils_priodec
    generic map (
      NUM_LOG2  => NUM_LOG2
    )
    port map (
      inp       => inp_i,
      outp      => outp_i,
      any       => any_i
    );
  
  process (clk) is
  begin
    if rising_edge(clk) then
      inp_i <= inp;
      outp <= outp_i;
      any <= any_i;
    end if;
  end process;
  
end architecture;

-------------------------------------------------------------------------------
-- One-hot to binary decoder. The output is undefined if multiple input signals
-- are high. If this is a problem, use utils_priodec.
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity utils_ohdec is
  generic (
    NUM_LOG2  : natural := 5
  );
  port (
    inp       : in  std_logic_vector(2**NUM_LOG2-1 downto 0);
    outp      : out std_logic_vector(NUM_LOG2-1 downto 0);
    any       : out std_logic
  );
end utils_ohdec;

architecture behavioural of utils_ohdec is
  
  -- Returns the i'th number that results in a 1 for bit b.
  pure function conv_idx(
    i : natural;
    b : natural
  ) return natural is
    variable iu : unsigned(31 downto 0);
  begin
    iu := to_unsigned(i, 32);
    iu(31 downto b+1) := iu(30 downto b);
    iu(b) := '1';
    return to_integer(iu);
  end function conv_idx;
  
  signal outl : std_logic_vector(NUM_LOG2-1 downto 0);
  
begin
  
  -- The output bits are computed independently in parallel.
  bit_gen: for b in NUM_LOG2-1 downto 0 generate
    signal inb  : std_logic_vector(2**NUM_LOG2/2-1 downto 0);
  begin
    
    -- Generate a vector with all the input signals that should result in a
    -- high output for this bit.
    connect_gen: for i in 2**NUM_LOG2/2-1 downto 0 generate
    begin
      inb(i) <= inp(conv_idx(i, b));
    end generate;
    
    -- Use wideor to quickly generate the result signal.
    wideor_inst: entity work.utils_wideor
      generic map (
        WIDTH     => 2**NUM_LOG2/2
      )
      port map (
        inp       => inb,
        outp      => outl(b),
        outp_int  => open
      );
    
  end generate;
  
  -- Forward the output.
  outp <= outl;
  
  -- Generate the any signal. We note that the MSB of the output is set if any
  -- of the upper half of the input bits are high, so we only need to check the
  -- lower half and the MSB of the output to get the any signal.
  any_block: block is
    signal or_inp : std_logic_vector(2**NUM_LOG2/2 downto 0);
  begin
    or_inp(2**NUM_LOG2/2)            <= outl(NUM_LOG2-1);
    or_inp(2**NUM_LOG2/2-1 downto 0) <= inp(2**NUM_LOG2/2-1 downto 0);
    
    any_wideor_inst: entity work.utils_wideor
      generic map (
        WIDTH => 2**NUM_LOG2/2 + 1
      )
      port map (
        inp                     => or_inp,
        outp                    => any
      );
  end block;
  
end architecture;

-- pragma translate_off

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity utils_ohdec_tb is
end utils_ohdec_tb;

architecture testbench of utils_ohdec_tb is
  constant NUM_LOG2 : natural := 7;
  signal inp        : std_logic_vector(2**NUM_LOG2-1 downto 0);
  signal outp       : std_logic_vector(NUM_LOG2-1 downto 0);
  signal any        : std_logic;
begin
  
  uut: entity work.utils_ohdec
    generic map (
      NUM_LOG2  => NUM_LOG2
    )
    port map (
      inp       => inp,
      outp      => outp,
      any       => any
    );
  
  stim_proc: process is
  begin
    for i in -1 to 2**NUM_LOG2-1 loop
      if i >= 0 then
        inp <= (i => '1', others => '0');
      else
        inp <= (others => '0');
      end if;
      wait for 1 ns;
    end loop;
  end process;
  
end architecture;

-- pragma translate_on

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity utils_ohdec_speedtest is
  generic (
    NUM_LOG2  : natural := 7
  );
  port (
    clk       : in  std_logic;
    inp       : in  std_logic_vector(2**NUM_LOG2-1 downto 0);
    outp      : out std_logic_vector(NUM_LOG2-1 downto 0);
    any       : out std_logic
  );
end utils_ohdec_speedtest;

architecture behavioral of utils_ohdec_speedtest is
  signal inp_i      : std_logic_vector(2**NUM_LOG2-1 downto 0);
  signal outp_i     : std_logic_vector(NUM_LOG2-1 downto 0);
  signal any_i      : std_logic;
begin
  
  uut: entity work.utils_ohdec
    generic map (
      NUM_LOG2  => NUM_LOG2
    )
    port map (
      inp       => inp_i,
      outp      => outp_i,
      any       => any_i
    );
  
  process (clk) is
  begin
    if rising_edge(clk) then
      inp_i <= inp;
      outp <= outp_i;
      any <= any_i;
    end if;
  end process;
  
end architecture;
