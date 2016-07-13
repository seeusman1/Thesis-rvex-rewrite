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

--#############################################################################
-- NOTE: there are multiple entities/packages in this file.
--#############################################################################

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library rvex;
use rvex.common_pkg.all;

--=============================================================================
-- This package contains generic utility functions and procedures used both for
-- logic generation.
-------------------------------------------------------------------------------
package utils_stage_pkg is
--=============================================================================
  
  -- Connection between
  type utils_stage_x_type is record
    clk     : std_logic;
    clkEn   : std_logic;
    irdy    : std_logic;
    ostl    : std_logic;
    busy_r  : std_logic;
  end record;
  
end utils_stage_pkg;

package body utils_stage_pkg is
end utils_stage_pkg;

--#############################################################################

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.common_pkg.all;
use work.utils_stage_pkg.all;

--=============================================================================
-- This entity serves as the control unit for a pipeline stage.
-------------------------------------------------------------------------------
entity utils_stage_ctrl is
--=============================================================================
  generic (
    
    -- Number of pipeline stages crossed.
    S                           : natural := 1
    
  );
  port (
    
    ---------------------------------------------------------------------------
    -- System control
    ---------------------------------------------------------------------------
    -- Active high synchronous reset input.
    reset                       : in  std_logic := '0';
    
    -- Clock input, registers are rising edge triggered.
    clk                         : in  std_logic;
    
    -- Active high global clock enable input.
    clkEn                       : in  std_logic := '1';
    
    ---------------------------------------------------------------------------
    -- Input handshake
    ---------------------------------------------------------------------------
    -- Input data ready/valid.
    irdy                        : in  std_logic := '1';
    
    -- Input stall.
    istl                        : out std_logic;
    
    ---------------------------------------------------------------------------
    -- Output handshake
    ---------------------------------------------------------------------------
    -- Output data ready/valid.
    ordy                        : out std_logic;
    
    -- Output stall.
    ostl                        : in  std_logic := '0';
    
    ---------------------------------------------------------------------------
    -- Interconnect
    ---------------------------------------------------------------------------
    -- This should be connected to the data buffers for this stage.
    x                           : out utils_stage_x_type
    
  );
end utils_stage_ctrl;

-------------------------------------------------------------------------------
architecture behavioral of utils_stage_ctrl is
-------------------------------------------------------------------------------
  
  -- Busy is high when the input is "ahead" of the output, i.e. there's valid
  -- data in the holding register.
  signal busy_d, busy_r         : std_logic;
  
begin
  
  -- Infer the registers.
  reg_proc: process (clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        busy_r <= '0';
      elsif clkEn = '1' then
        busy_r <= busy_d;
      end if;
    end if;
  end process;
  
  -- Infer the combinatorial logic.
  busy_d <= '0' when ostl = '0'
       else '1' when irdy = '1' and busy_r = '0'
       else busy_r;
  
  -- Connect the outputs.
  istl <= busy_r;
  ordy <= busy_r or irdy;
  
  -- Connect with the data buffers.
  x <= (
    clk     => clk,
    clkEn   => clkEn,
    irdy    => irdy,
    ostl    => ostl,
    busy_r  => busy_r
  );
  
end behavioral;

--#############################################################################

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.common_pkg.all;
use work.utils_pkg.all;
use work.utils_stage_pkg.all;

--=============================================================================
-- This entity serves as an std_logic_vector (or std_logic) data buffer, to be
-- used in conjunction with utils_stage_ctrl.
-------------------------------------------------------------------------------
entity utils_stage_bit is
--=============================================================================
  generic (
    
    -- Number of pipeline stages crossed. Must be equal to the value passed to
    -- the utils_stage_ctrl unit.
    S                           : natural := 1;
    
    -- Width of the data vector.
    W                           : natural := 1
    
  );
  port (
    
    -- This should be connected to the data buffers for this stage.
    x                           : in  utils_stage_x_type;
    
    -- Input data.
    i                           : in  std_logic_vector(W-1 downto 0);
    
    -- Output data.
    o                           : out std_logic_vector(W-1 downto 0)
    
  );
end utils_stage_bit;

-------------------------------------------------------------------------------
architecture behavioral of utils_stage_bit is
-------------------------------------------------------------------------------
  
  -- Copy of i, delayed by one delta-delay in simulation.
  signal d                      : std_logic_vector(W-1 downto 0);
  
  -- Number of input registers.
  constant IN_REG_COUNT         : natural := S + 1;
  
  -- Input register/shift register.
  signal din_r                  : std_logic_vector(W-1 downto 0);
  signal din_d, din_x           : std_logic_vector(IN_REG_COUNT*W-1 downto 0);
  
  -- Output holding register.
  signal dout_d, dout_r         : std_logic_vector(W-1 downto 0);
  
begin
  
  -- We need to do this assignment to prevent delta-delay clock skew in
  -- simulation, because the clk signal is assigned to x.clk in the control
  -- unit.
  d <= i;
  
  -- Infer the registers.
  reg_proc: process (x.clk) is
  begin
    if rising_edge(x.clk) and x.clkEn = '1' then
      din_x <= din_d;
      dout_r <= dout_d;
    end if;
  end process;
  din_r <= din_x(W-1 downto 0);
  
  -- Combinatorial logic.
  din_d  <= d & din_x(IN_REG_COUNT*W-1 downto W) when x.irdy = '1' and x.busy_r = '0'
       else din_x;
  
  dout_d <= din_d(W-1 downto 0) when x.ostl = '0'
       else dout_r;
  
  o <= dout_d;
  
end behavioral;

--#############################################################################





library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library rvex;
use rvex.common_pkg.all;

entity cache_stage is
  generic (
    
    STAGE                       : boolean := true
    
  );
  port (
    
    reset                       : in  std_logic;
    clk                         : in  std_logic;
    clkEn                       : in  std_logic := '1';
    
    din                         : in  std_logic_vector(0 downto 0);
    request                     : in  std_logic;
    busy                        : out std_logic;
    
    dout                        : out std_logic_vector(0 downto 0);
    done                        : out std_logic;
    stall                       : in  std_logic
    
  );
end cache_stage;

architecture Behavioral of cache_stage is
  
  -- Registers.
  signal din_d, din_r           : std_logic_vector(0 downto 0);
  signal dout_d, dout_r         : std_logic_vector(0 downto 0);
  signal busy_d, busy_r         : std_logic;
  
begin
  
  -- Infer the registers.
  reg_proc: process (clk) is
  begin
    if rising_edge(clk) then
      if clkEn = '1' then
        din_r  <= din_d;
        dout_r <= dout_d;
        busy_r <= busy_d;
      end if;
      if reset = '1' then
        -- pragma translate_off
        din_r  <= (others => 'U');
        dout_r <= (others => 'U');
        -- pragma translate_on
        if STAGE then
          busy_r <= '1';
        else
          busy_r <= '0';
        end if;
      end if;
    end if;
  end process;
  
  -- Infer the combinatorial logic.
  din_d  <= din when request = '1' and busy_r = '0'
       else din_r;
       
  dout_d <= din_r when stall = '0' and STAGE
       else din_d when stall = '0' and not STAGE
       else dout_r;
  
  busy_d <= '0' when stall = '0' and not STAGE
       else '1' when request = '1' and busy_r = '0'
       else '0' when stall = '0'
       else busy_r;
  
  -- Connect the outputs.
  busy <= busy_r;
  dout <= dout_d;
  done <= busy_r when STAGE else (busy_r or request);
  
end Behavioral;


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library rvex;
use rvex.common_pkg.all;
use rvex.simUtils_pkg.all;
use work.utils_stage_pkg.all;

entity cache_stage_tb is
end cache_stage_tb;

architecture testbench of cache_stage_tb is
  
  type phase_type is record
    data    : std_logic_vector(3 downto 0);
    done    : std_logic;
    stall   : std_logic;
  end record;
  type phase_array is array (natural range <>) of phase_type;
  
  signal phases : phase_array(0 to 1);
  
  signal clk    : std_logic;
  signal reset  : std_logic;
  
  signal provided : std_logic_vector(3 downto 0);
  signal consumed : std_logic_vector(3 downto 0);
  
begin
  
  clk_proc: process is
  begin
    clk <= '1';
    wait for 5 ns;
    clk <= '0';
    wait for 5 ns;
  end process;
  
  reset_proc: process is
  begin
    reset <= '1';
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    reset <= '0';
    wait;
  end process;
  
  producer: process is
    variable s1   : positive := 33;
    variable s2   : positive := 42;
    variable rnd  : std_logic_vector(1 downto 0);
    variable cnt  : unsigned(31 downto 0);
  begin
    cnt := (others => '0');
    phases(0).data <= (others => 'U');
    phases(0).done <= '0';
    provided <= (others => 'Z');
    wait until reset = '0' and rising_edge(clk);
    loop
      loop
        rvs_randomVect(s1, s2, rnd);
        --exit when true;
        exit when rnd = "00";
        wait until rising_edge(clk);
      end loop;
      phases(0).data <= std_logic_vector(cnt(phases(0).data'range));
      phases(0).done <= '1';
      wait until rising_edge(clk) and phases(0).stall = '0';
      phases(0).data <= (others => 'U');
      phases(0).done <= '0';
      provided <= std_logic_vector(cnt(phases(0).data'range)), (others => 'Z') after 9 ns;
      cnt := cnt + 1;
    end loop;
  end process;
  
  --stage1: entity work.cache_stage
  --  port map (
  --    reset    => reset,
  --    clk      => clk,
  --    din      => phases(0).data,
  --    request  => phases(0).done,
  --    busy     => phases(0).stall,
  --    dout     => phases(1).data,
  --    done     => phases(1).done,
  --    stall    => phases(1).stall
  --  );
  stage_block: block is
    constant  S : natural := 3;
    signal    x : utils_stage_x_type;
  begin
    ctrl: entity work.utils_stage_ctrl
      generic map ( S => S )
      port map (
        reset   => reset,
        clk     => clk,
        irdy    => phases(0).done,
        istl    => phases(0).stall,
        ordy    => phases(1).done,
        ostl    => phases(1).stall,
        x       => x
      );
    
    data: entity work.utils_stage_bit
      generic map ( S => S, W => phases(0).data'length )
      port map ( x => x, i => phases(0).data, o => phases(1).data );
    
  end block;
  
  consumer: process is
    variable s1   : positive := 42;
    variable s2   : positive := 33;
    variable rnd  : std_logic_vector(2 downto 0);
  begin
    phases(1).stall <= '0';
    consumed <= (others => 'Z');
    wait until reset = '0';
    loop
      wait until rising_edge(clk) and phases(1).done = '1';
      consumed <= phases(1).data, (others => 'Z') after 9 ns;
      phases(1).stall <= '1';
      loop
        rvs_randomVect(s1, s2, rnd);
        exit when true;
        exit when rnd = "000";
        wait until rising_edge(clk);
      end loop;
      phases(1).stall <= '0';
    end loop;
  end process;
  
end testbench;

