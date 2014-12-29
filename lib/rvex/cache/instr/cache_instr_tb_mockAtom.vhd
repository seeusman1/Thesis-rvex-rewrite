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

-- Refer to reconfICache_pkg.vhd for configuration constants and most
-- documentation.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

library rvex;
use rvex.cache_instr_pkg.all;

-- This mockup atom/pipelane pair will simply request instruction after
-- instruction as fast as the cache and clkEn signal will let it. It properly
-- respects the configuration based on the incoming decouple bits.
--
-- This is not intended to be synthesizable.
entity cache_instr_tb_mockAtom is
  generic (
    ATOM_INDEX              : natural := 0
  );
  port (
    
    -- Clock input.
    clk                     : in  std_logic;
    
    -- Active high reset input.
    reset                   : in  std_logic;
    
    -- Active high CPU interface clock enable input.
    clkEn                   : in  std_logic;
    
    -- Connection to instruction cache.
    cacheToAtom             : in  reconfICache_atomOut;
    atomToCache             : out reconfICache_atomIn;
    
    -- Configuration vector, these are just the decoule bits.
    configVector            : in  std_logic_vector(RIC_NUM_ATOMS-1 downto 0);
    
    -- Requests the atom to finish what it's doing to prepare for
    -- reconfiguration.
    requestReconfig         : in  std_logic;
    
    -- Acknowledge signal for requestReconfig.
    reconfigReady           : out std_logic;
    
    -- Simulation eye candy signal: this is the program counter of the
    -- currently executed instruction if this is a master atom or Z otherwise.
    simPC                   : out std_logic_vector(RIC_PC_WIDTH-1 downto 0);
    
    -- Simulation eye candy signal: this is the currently executed instruction
    -- if there is one, Z otherwise.
    simInstr                : out std_logic_vector(RIC_ATOM_INSTR_WIDTH-1 downto 0)
    
  );
end cache_instr_tb_mockAtom;

architecture Behavioral of cache_instr_tb_mockAtom is
  
  -- Number of bytes to increment the PC with every cycle.
  signal pc_increment       : natural;
  
  -- Our own decouple bit.
  signal decouple           : std_logic;
  
  -- Pipeline stall signal.
  signal stall              : std_logic;
  
  -- Random external stall signal.
  signal randomStall        : std_logic;
  
  -- Instantiate a dumbed-down pipeline.
  constant NUM_PIPE_STAGES  : natural := 2;
  type instrState_type is record
    jumpToResetVect         : std_logic;
    active                  : std_logic;
    pc                      : std_logic_vector(RIC_PC_WIDTH-1 downto 0);
    instr                   : std_logic_vector(RIC_ATOM_INSTR_WIDTH-1 downto 0);
  end record;
  type pipeline_type is array (natural range <>) of instrState_type;
  signal si                 : pipeline_type(1 to NUM_PIPE_STAGES);
  signal so                 : pipeline_type(0 to NUM_PIPE_STAGES-1);
  
  -- so(0) -> reg -> si(1) -> s1 processing -> so(1) -> reg -> ...
  --   ^               |
  --   |               v
  --   '------ next pc computation
begin
  
  --===========================================================================
  -- Configuration logic
  --===========================================================================
  process (configVector) is
    variable p              : integer;
    variable pc_inc_v       : integer;
  begin
    if configVector(ATOM_INDEX) = '0' then
      
      -- We're a slave atom.
      decouple <= '0';
      pc_increment <= 0;
      
    else
      
      -- We're a master, count how many slaves we have and use that to
      -- determine by how much we should increment our PC each cycle.
      p := ATOM_INDEX - 1;
      pc_inc_v := 2**RIC_ATOM_SIZE_BLOG2;
      while p >= 0 loop
        exit when configVector(p) = '1';
        pc_inc_v := pc_inc_v + 2**RIC_ATOM_SIZE_BLOG2;
        p := p - 1;
      end loop;
      decouple <= '1';
      pc_increment <= pc_inc_v;
      
    end if;
  end process;
  
  -- Forward the configuration to the cache.
  atomToCache.decouple <= decouple;
  
  -- Allow a configuration change when none of the pipeline stages are active.
  process (si, requestReconfig) is
    variable allow: std_logic;
  begin
    allow := 'H';
    for i in 1 to NUM_PIPE_STAGES loop
      if si(i).active = '1' then
        allow := '0';
      end if;
    end loop;
    if requestReconfig = '0' then
      allow := '0';
    end if;
    reconfigReady <= allow;
  end process;
  
  --===========================================================================
  -- Pipeline management
  --===========================================================================
  
  -- Generate a random external stall signal for testing.
  process (clk) is
    variable seed1, seed2: positive;
    variable rand: real;
  begin
    if rising_edge(clk) then
      uniform(seed1, seed2, rand);
      if rand > 0.7 then
        randomStall <= '1';
      else
        randomStall <= '0';
      end if;
    end if;
  end process;
  
  -- Compute the stall signal.
  stall <= cacheToAtom.stall or randomStall;
  
  -- Output the stall signal to the cache as well.
  atomToCache.stall <= stall;
  
  -- Instantiate the pipeline stage registers.
  pipeline_update_proc: process (clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        si <= (others => (
          jumpToResetVect   => '1',
          active            => '0',
          pc                => (others => '0'),
          instr             => (others => '0')
        ));
      elsif stall = '0' and clkEn = '1' then
        si <= so;
      end if;
    end if;
  end process;
  
  --===========================================================================
  -- Next instruction computation: si(1) -> so(0)
  --===========================================================================
  next_instr: process (
    si(1), requestReconfig, decouple
  ) is
  begin
    
    -- Forward by default.
    so(0) <= si(1);
    
    -- If we're cleared to start a new instruction, figure out its PC and set
    -- active. Otherwise, clear active.
    if requestReconfig = '0' then
      so(0).active <= '1';
      
      -- Only increment our PC if we're actually a master; maintain state if
      -- we're not.
      if decouple = '1' then
        if si(1).jumpToResetVect = '1' then
          so(0).PC <= (others => '0');
          so(0).jumpToResetVect <= '0';
        else
          so(0).PC <= std_logic_vector(unsigned(si(1).PC) + pc_increment);
        end if;
      end if;
      
    else
      so(0).active <= '0';
    end if;
    
  end process;
  
  -- Forward intent to instruction cache.
  atomToCache.PC <= so(0).PC;
  atomToCache.readEnable <= so(0).active;
  
  --===========================================================================
  -- Pipeline stage 1 computation (instruction decode): si(1) -> so(1)
  --===========================================================================
  stage_1: process (
    si(1), cacheToAtom.instr
  ) is
  begin
    
    -- Forward by default.
    so(1) <= si(1);
    
    -- Copy the instruction we've fetched into the pipeline.
    so(1).instr <= cacheToAtom.instr;
    
  end process;
  
  --===========================================================================
  -- Pipeline stage 2 computation (simulation eye candy): si(2) -> ...
  --===========================================================================
  stage_2: process (
    si(2), decouple, stall
  ) is
  begin
    if si(2).active = '1' and stall = '0' then
      simInstr <= si(2).instr;
      if decouple = '1' then
        simPC <= si(2).pc;
      else
        simPC <= (others => 'Z');
      end if;
    else
      simInstr <= (others => 'Z');
      simPC <= (others => 'Z');
    end if;
  end process;

end Behavioral;
