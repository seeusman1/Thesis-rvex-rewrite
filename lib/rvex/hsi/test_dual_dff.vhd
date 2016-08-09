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

entity test_dff is
  -- Modeled circuit:
  --         .----.
  --      c--|>  Q|--o--q
  -- d--|\   |   _|  |
  --    | |--|D  Q|--+--qn
  -- .--|/   '----'  |
  -- |   '--ce       |
  -- '---------------'
  generic (
    c2d_setup : time := 300 ps; -- Assumed
    c2d_hold  : time := 150 ps; -- Assumed (must be less than c2qn_prop)
    c2qn_prop : time := 198 ps; -- Taken from SAED_EDK90nm (DFFX2)
    c2q_prop  : time := 251 ps; -- Taken from SAED_EDK90nm (DFFX2)
    mux_prop  : time := 253 ps; -- Taken from SAED_EDK90nm (MUX21X2)
    mux_ena   : boolean := false
  );
  port (
    c   : in  std_logic;
    ce  : in  std_logic := '0';
    d   : in  std_logic;
    q   : out std_logic;
    qn  : out std_logic
  );
end test_dff;

architecture behavioral of test_dff is
  signal mux    : std_logic;
  signal c_int  : std_logic;
  signal d_int  : std_logic;
  signal q_int  : std_logic;
  signal qn_int : std_logic;
begin
  
  -- Model the mux.
  mux_gen: if mux_ena generate
    signal mux_int  : std_logic;
  begin
    mux_int <= d when ce = '1' else q_int when ce = '0' else 'U';
    mux <= 'U', mux_int after mux_prop;
  end generate;
  no_mux_gen: if not mux_ena generate
  begin
    mux <= d;
  end generate;
  
  -- Delay the clock signal by the hold time.
  c_int <= c after c2d_hold;
  
  -- Invalidate data signal for setup+hold after each transition.
  d_int <= 'U', mux after c2d_setup + c2d_hold;
  
  -- Instantiate the remainder of the register.
  dff_proc: process (c_int) is
  begin
    if rising_edge(c_int) then
      q_int  <= 'U',     d_int after c2q_prop - c2d_hold;
      qn_int <= 'U', not d_int after c2qn_prop - c2d_hold;
    end if;
  end process;
  
  -- Forward the outputs.
  q <= q_int;
  qn <= qn_int;
  
end behavioral;

--#############################################################################

library IEEE;
use IEEE.std_logic_1164.all;

entity test_sync is
  -- Modeled circuit:          core_clk_rn, core_clk_rr
  --                         .------------.   __
  --               .-----.   |   .-----.  '--|A \_
  -- core_clk--o-->|d  qn|---o-->|d  qn|-----|__/ |strobe
  --           |   |  B  |       |  C  |          |
  --           |   |    c|<--o-->|c    |   .------'
  --           |   '-----'   |   '-----'   |
  --           |             o-------------+----hsi_clk
  --           |   .-----.   |   .-----.   |
  --           o-->|c    |   o-->|c  ce|<--o--> hsi_strobe
  --           |   |  D  |   |   |  E  |   |
  -- core_c2h--+-->|d  qn|---+-->|d  qn|---+--> hsi_c2h
  --           |   '-----'   |   '-----'   |
  --           |   .-----.   |   .-----.   |
  --           '-->|c    |   '-->|c  ce|<--'
  --               |  F  |       |  G  |
  -- core_h2c <----|qn  d|<------|qn  d|<-------hsi_h2c
  --               '-----'       '-----'
  port (
    
    -- Core side (low speed clock).
    core_clk    : in  std_logic;
    core_c2h    : in  std_logic;
    core_h2c    : out std_logic;
    
    
    -- HSI side (high speed clock).
    hsi_clk     : in  std_logic;
    hsi_strobe  : out std_logic;
    hsi_c2h     : out std_logic;
    hsi_h2c     : in  std_logic
    
  );
end test_sync;

architecture behavioral of test_sync is
  signal core_clk_rn  : std_logic;
  signal core_clk_rr  : std_logic;
  signal strobe       : std_logic;
  signal h2c_rn       : std_logic;
  signal c2h_rn       : std_logic;
begin
  
  A: strobe <= 'U', core_clk_rn and core_clk_rr after 214 ps; -- SAED_EDK90nm AND2X2
  B: entity work.test_dff port map (c=>hsi_clk, d=>core_clk, qn=>core_clk_rn);
  C: entity work.test_dff port map (c=>hsi_clk, d=>core_clk_rn, qn=>core_clk_rr);
  D: entity work.test_dff port map (c=>core_clk, d=>core_c2h, qn=>c2h_rn);
  E: entity work.test_dff generic map (mux_ena => true) port map (c=>hsi_clk, ce=>strobe, d=>c2h_rn, qn=>hsi_c2h);
  F: entity work.test_dff port map (c=>core_clk, d=>h2c_rn, qn=>core_h2c);
  G: entity work.test_dff generic map (mux_ena => true) port map (c=>hsi_clk, ce=>strobe, d=>hsi_h2c, qn=>h2c_rn);
  
  hsi_strobe <= strobe;
  
end behavioral;

--#############################################################################

library IEEE;
use IEEE.std_logic_1164.all;

entity test_sync_tb is
end test_sync_tb;

architecture behavioral of test_sync_tb is
  signal core_clk    : std_logic := '0';
  signal core_c2h    : std_logic := '0';
  signal core_h2c    : std_logic := '0';
  signal hsi_clk     : std_logic := '0';
  signal hsi_strobe  : std_logic := '0';
  signal hsi_c2h     : std_logic := '0';
  signal hsi_h2c     : std_logic := '0';
begin
  
  uut: entity work.test_sync
    port map (
      core_clk    => core_clk,
      core_c2h    => core_c2h,
      core_h2c    => core_h2c,
      hsi_clk     => hsi_clk,
      hsi_strobe  => hsi_strobe,
      hsi_c2h     => hsi_c2h,
      hsi_h2c     => hsi_h2c
    );
  
  core_clk_proc: process is
  begin
    -- 199 clock cycles per 4 microseconds.
    for i in 1 to 199 loop
      core_clk <= '1';
      wait for 10050 ps;
      core_clk <= '0';
      wait for 10050 ps;
    end loop;
    -- 20100*199 = 3999900 so we're 100 ps short.
    wait for 100 ps;
  end process;
  
  hsi_clk_proc: process is
  begin
    -- 50 MHz for 4 microseconds (core_clk x1).
    for i in 1 to 200 loop
      hsi_clk <= '1';
      wait for 10000 ps;
      hsi_clk <= '0';
      wait for 10000 ps;
    end loop;
    -- 100 MHz for 4 microseconds (core_clk x2).
    for i in 1 to 400 loop
      hsi_clk <= '1';
      wait for 5000 ps;
      hsi_clk <= '0';
      wait for 5000 ps;
    end loop;
    -- 150 MHz for 4 microseconds (core_clk x3).
    for i in 1 to 200 loop
      hsi_clk <= '1';
      wait for 3333 ps;
      hsi_clk <= '0';
      wait for 3333 ps;
      hsi_clk <= '1';
      wait for 3334 ps;
      hsi_clk <= '0';
      wait for 3333 ps;
      hsi_clk <= '1';
      wait for 3333 ps;
      hsi_clk <= '0';
      wait for 3334 ps;
    end loop;
    -- 200 MHz for 4 microseconds (core_clk x4).
    for i in 1 to 800 loop
      hsi_clk <= '1';
      wait for 2500 ps;
      hsi_clk <= '0';
      wait for 2500 ps;
    end loop;
  end process;
  
  core_stim_proc: process is
  begin
    wait until rising_edge(core_clk);
    core_c2h <= 'U' after 600 ps, '0' after 1000 ps;
    wait until rising_edge(core_clk);
    core_c2h <= 'U' after 600 ps, '0' after 1000 ps;
    wait until rising_edge(core_clk);
    core_c2h <= 'U' after 600 ps, '0' after 1000 ps;
    wait until rising_edge(core_clk);
    core_c2h <= 'U' after 600 ps, '1' after 1000 ps;
  end process;
  
  hsi_stim_proc: process is
  begin
    wait until rising_edge(hsi_clk) and hsi_strobe = '1';
    hsi_h2c <= 'U' after 600 ps, '0' after 1000 ps;
    wait until rising_edge(hsi_clk) and hsi_strobe = '1';
    hsi_h2c <= 'U' after 600 ps, '0' after 1000 ps;
    wait until rising_edge(hsi_clk) and hsi_strobe = '1';
    hsi_h2c <= 'U' after 600 ps, '0' after 1000 ps;
    wait until rising_edge(hsi_clk) and hsi_strobe = '1';
    hsi_h2c <= 'U' after 600 ps, '1' after 1000 ps;
  end process;
  
end behavioral;

