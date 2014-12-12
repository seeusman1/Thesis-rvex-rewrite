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
use rvex.cache_pkg.all;

-- This is not intended to be synthesizable.
entity cache_tb_mockAtom is
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
    cacheToAtom             : in  reconfCache_atomOut;
    atomToCache             : out reconfCache_atomIn;
    
    -- Configuration vector, these are just the decoule bits.
    configVector            : in  std_logic_vector(RC_NUM_ATOMS-1 downto 0);
    
    -- Requests the atom to finish what it's doing to prepare for
    -- reconfiguration.
    requestReconfig         : in  std_logic;
    
    -- Acknowledge signal for requestReconfig.
    reconfigReady           : out std_logic;
    
    -- Simulation eye candy signal: this is the program counter of the
    -- currently executed instruction if this is a master atom or Z otherwise.
    simPC                   : out std_logic_vector(RC_BUS_ADDR_WIDTH-1 downto 0);
    
    -- Simulation eye candy signal: this is the currently executed instruction
    -- if there is one, Z otherwise.
    simInstr                : out std_logic_vector(RC_ATOM_INSTR_WIDTH-1 downto 0);
    
    -- Simulation eye candy signal: this is the read data from the memory if a
    -- read was performed, Z otherwise.
    simReadResult           : out std_logic_vector(RC_BUS_DATA_WIDTH-1 downto 0)
    
  );
end cache_tb_mockAtom;

architecture Behavioral of cache_tb_mockAtom is
  
  -- Number of bytes to increment the PC with every cycle.
  signal pc_increment       : natural;
  
  -- Our own decouple bit.
  signal decouple           : std_logic;
  
  -- Pipeline stall signal.
  signal stall              : std_logic;
  
  -- Random external stall signal.
  signal randomStall        : std_logic;
  
  -- Instantiate a dumbed-down pipeline.
  constant NUM_PIPE_STAGES  : natural := 3;
  type instrState_type is record
    jumpToResetVect         : std_logic;
    active                  : std_logic;
    pc                      : std_logic_vector(RC_BUS_ADDR_WIDTH-1 downto 0);
    instr                   : std_logic_vector(RC_ATOM_INSTR_WIDTH-1 downto 0);
    readDataValid           : std_logic;
    readData                : std_logic_vector(RC_BUS_DATA_WIDTH-1 downto 0);
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
      pc_inc_v := 2**RC_INSTR_SIZE_BLOG2;
      while p >= 0 loop
        exit when configVector(p) = '1';
        pc_inc_v := pc_inc_v + 2**RC_INSTR_SIZE_BLOG2;
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
  bus_clk_en_gen: entity rvex.cache_tb_rng
    generic map (
      seed        => 3,
      resetState  => '0',
      highProb    => 0.3
    )
    port map (
      clk         => clk,
      reset       => reset,
      clkEn       => clkEn,
      sig         => randomStall
    );
  
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
          instr             => (others => '0'),
          readDataValid     => '0',
          readData          => (others => '0')
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
  atomToCache.fetch <= so(0).active;
  
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
    
    -- Decode instruction (give the data cache something to do).
    atomToCache.addr              <= (others => '0');
    atomToCache.readEnable        <= '0';
    atomToCache.writeData         <= (others => '0');
    atomToCache.writeMask         <= (others => '0');
    atomToCache.writeEnable       <= '0';
    atomToCache.bypass            <= '0';
    case cacheToAtom.instr is
      -- Try read-write-read (basic cache consistency check).
      when X"00000023" =>
        atomToCache.addr          <= X"00000108"; -- expect 0x00000042
        atomToCache.readEnable    <= '1';
        so(1).readDataValid       <= '1';
      when X"00000027" =>
        atomToCache.addr          <= X"00000108";
        atomToCache.writeData     <= X"33AAAAAA";
        atomToCache.writeMask     <= "1000";
        atomToCache.writeEnable   <= '1';
      when X"0000002B" =>
        atomToCache.addr          <= X"00000108"; -- expect 0x33000042
        atomToCache.readEnable    <= '1';
        so(1).readDataValid       <= '1';
      
      -- Try two writes quickly after each other (write buffer check).
      -- This is for after the config switch to 2x2.
      when X"00000011" =>
        atomToCache.addr          <= X"00000200";
        atomToCache.writeData     <= X"01234567";
        atomToCache.writeMask     <= "1111";
        atomToCache.writeEnable   <= '1';
      when X"00000013" =>
        atomToCache.addr          <= X"00000204";
        atomToCache.writeData     <= X"89ABCDEF";
        atomToCache.writeMask     <= "1111";
        atomToCache.writeEnable   <= '1';
      when X"00000015" =>
        atomToCache.addr          <= X"00000200"; -- expect 0x01234567
        atomToCache.readEnable    <= '1';
        so(1).readDataValid       <= '1';
      when X"00000017" =>
        atomToCache.addr          <= X"00000204"; -- expect 0x89ABCDEF
        atomToCache.readEnable    <= '1';
        so(1).readDataValid       <= '1';
      
      -- The following reads occur while the other core is writing to
      -- 0x00000200. At some point, the value should update to 01234567.
      when X"00000067" =>
        atomToCache.addr          <= X"00000200";
        atomToCache.readEnable    <= '1';
        so(1).readDataValid       <= '1';
      when X"00000069" =>
        atomToCache.addr          <= X"00000200";
        atomToCache.readEnable    <= '1';
        so(1).readDataValid       <= '1';
      when X"0000006B" =>
        atomToCache.addr          <= X"00000200";
        atomToCache.readEnable    <= '1';
        so(1).readDataValid       <= '1';
      when X"0000006D" =>
        atomToCache.addr          <= X"00000200";
        atomToCache.readEnable    <= '1';
        so(1).readDataValid       <= '1';
      when X"0000006F" =>
        atomToCache.addr          <= X"00000200";
        atomToCache.readEnable    <= '1';
        so(1).readDataValid       <= '1';
      when X"00000071" =>
        atomToCache.addr          <= X"00000200";
        atomToCache.readEnable    <= '1';
        so(1).readDataValid       <= '1';
      when X"00000073" =>
        atomToCache.addr          <= X"00000200";
        atomToCache.readEnable    <= '1';
        so(1).readDataValid       <= '1';
      when X"00000075" =>
        atomToCache.addr          <= X"00000200";
        atomToCache.readEnable    <= '1';
        so(1).readDataValid       <= '1';
      when X"00000077" =>
        atomToCache.addr          <= X"00000200";
        atomToCache.readEnable    <= '1';
        so(1).readDataValid       <= '1';
      when X"00000079" =>
        atomToCache.addr          <= X"00000200"; -- expect 01234567
        atomToCache.readEnable    <= '1';
        so(1).readDataValid       <= '1';
      
      -- Test bypass write.
      when X"0000007B" =>
        atomToCache.addr          <= X"00000208";
        atomToCache.writeData     <= X"33333333";
        atomToCache.writeMask     <= "1010";
        atomToCache.writeEnable   <= '1';
        atomToCache.bypass        <= '1';
      
      -- Test bypass read.
      when X"0000007D" =>
        atomToCache.addr          <= X"00000208"; -- expect 33003382
        atomToCache.readEnable    <= '1';
        atomToCache.bypass        <= '1';
        so(1).readDataValid       <= '1';
        
      when others =>
        null;
    end case;
    
  end process;
  
  --===========================================================================
  -- Pipeline stage 2 computation (store memory result): si(2) -> so(2)
  --===========================================================================
  stage_2: process (
    si(2), cacheToAtom.readData
  ) is
  begin
    
    -- Forward by default.
    so(2) <= si(2);
    
    -- Copy the data we've fetched into the pipeline.
    so(2).readData <= cacheToAtom.readData;
    
  end process;
  
  --===========================================================================
  -- Pipeline stage 3 computation (simulation eye candy): si(3) -> ...
  --===========================================================================
  stage_3: process (
    si(3), decouple, stall, clkEn
  ) is
  begin
    if si(3).active = '1' and stall = '0' and clkEn = '1' then
      simInstr <= si(3).instr;
      if decouple = '1' then
        simPC <= si(3).pc;
      else
        simPC <= (others => 'Z');
      end if;
      if si(3).readDataValid = '1' then
        simReadResult <= si(3).readData;
      else
        simReadResult <= (others => 'Z');
      end if;
    else
      simInstr <= (others => 'Z');
      simPC <= (others => 'Z');
      simReadResult <= (others => 'Z');
    end if;
  end process;
  
end Behavioral;
