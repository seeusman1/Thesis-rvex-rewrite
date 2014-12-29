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
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library rvex;
use rvex.cache_pkg.all;

entity cache_tb is
end cache_tb;

-- NOTE: RC_NUM_ATOMS must be 4 for this test bench.

architecture Behavioral of cache_tb is
  
  -- Signals connected to the cache under test.
  signal clk                : std_logic;
  signal reset              : std_logic;
  signal clkEnCPU           : std_logic;
  signal clkEnBus           : std_logic;
  signal atomsToCache       : reconfCache_atomIn_array;
  signal cacheToAtoms       : reconfCache_atomOut_array;
  signal memToCache         : reconfCache_memIn_array;
  signal cacheToMem         : reconfCache_memOut_array;
  signal invalToCache       : reconfCache_invalIn;
  signal cacheToInval       : reconfCache_invalOut;  
  
  -- Mockup configuration logic signals.
  signal currentConfig      : std_logic_vector(RC_NUM_ATOMS-1 downto 0);
  signal requestReconfig    : std_logic;
  signal reconfigReady      : std_logic; -- This is modelled as an open collector bus for simplicity.
  
  -- Requested configuration (decouple) vector, can be set by stimulus at the
  -- bottom of the file.
  signal requestedConfig    : std_logic_vector(RC_NUM_ATOMS-1 downto 0);
  
  -- Mockup memory bus.
  signal memToCache_all     : reconfCache_memIn;
  signal cacheToMem_all     : reconfCache_memOut;
  
  -- Mockup memory.
  constant MEM_DEPTH_LOG2   : natural := 9;
  constant MEM_DEPTH        : natural := 2**MEM_DEPTH_LOG2;
  type ram_data_type
    is array(0 to MEM_DEPTH-1)
    of std_logic_vector(RC_BUS_DATA_WIDTH-1 downto 0);
  shared variable ram_data  : ram_data_type := (others => (others => 'X'));
  
  -- Eye candy signals.
  type eyeCandy_atomState_type is record
    pc                      : std_logic_vector(RC_BUS_ADDR_WIDTH-1 downto 0);
    instruction             : std_logic_vector(RC_ATOM_INSTR_WIDTH-1 downto 0);
    readResult              : std_logic_vector(RC_BUS_DATA_WIDTH-1 downto 0);
  end record;
  type eyeCandy_atomState_array is array (0 to RC_NUM_ATOMS-1) of eyeCandy_atomState_type;
  type eyeCandy_type is record
    atoms                   : eyeCandy_atomState_array;
  end record;
  signal eyeCandy           : eyeCandy_type;
  
begin
  
  --===========================================================================
  -- Generate syscon signals
  --===========================================================================
  -- Generate clock signal at 100 MHz.
  clk_proc: process is
  begin
    clk <= '1';
    wait for 5 ns;
    clk <= '0';
    wait for 5 ns;
  end process;
  
  -- Generate reset signal.
  reset_proc: process is
  begin
    reset <= '1';
    wait for 50 ns;
    reset <= '0';
    wait;
  end process;
  
  -- Generate CPU clock enable signal.
  cpu_clk_en_gen: entity rvex.cache_tb_rng
    generic map (
      seed        => 1,
      resetState  => '1',
      highProb    => 0.6
    )
    port map (
      clk         => clk,
      reset       => reset,
      clkEn       => '1',
      sig         => clkEnCPU
    );
  
  -- Generate bus clock enable signal.
  bus_clk_en_gen: entity rvex.cache_tb_rng
    generic map (
      seed        => 2,
      resetState  => '1',
      highProb    => 0.6
    )
    port map (
      clk         => clk,
      reset       => reset,
      clkEn       => '1',
      sig         => clkEnBus
    );
  
  --===========================================================================
  -- Instantiate the cache
  --===========================================================================
  uut: entity rvex.cache
    port map (
      
      -- Clock input.
      clk                     => clk,
      
      -- Active high reset input.
      reset                   => reset,
      
      -- Active high CPU interface clock enable input.
      clkEnCPU                => clkEnCPU,
      
      -- Active high bus interface clock enable input.
      clkEnBus                => clkEnBus,
      
      -- Connections to the atoms. Governed by clkEnCPU.
      atomsToCache            => atomsToCache,
      cacheToAtoms            => cacheToAtoms,
      
      -- Connections to the memory bus. Governed by clkEnBus.
      memToCache              => memToCache,
      cacheToMem              => cacheToMem,
      
      -- Cache invalidation connections. Governed by clkEnBus.
      invalToCache            => invalToCache,
      cacheToInval            => cacheToInval
      
    );
  
  --===========================================================================
  -- Instantiate mockup atoms
  --===========================================================================
  atoms: for i in 0 to RC_NUM_ATOMS-1 generate
    atom_n: entity rvex.cache_tb_mockAtom
      generic map (
        ATOM_INDEX            => i
      )
      port map (
        
        -- Clock input.
        clk                   => clk,
        
        -- Active high reset input.
        reset                 => reset,
        
        -- Active high CPU interface clock enable input.
        clkEn                 => clkEnCPU,
        
        -- Connection to instruction cache.
        cacheToAtom           => cacheToAtoms(i),
        atomToCache           => atomsToCache(i),
        
        -- Configuration vector, these are just the decoule bits.
        configVector          => currentConfig,
        
        -- Requests the atom to finish what it's doing to prepare for
        -- reconfiguration.
        requestReconfig       => requestReconfig,
        
        -- Acknowledge signal for requestReconfig.
        reconfigReady         => reconfigReady,
        
        -- Simulation eye candy signal: this is the program counter of the
        -- currently executed instruction if this is a master atom or Z otherwise.
        simPC                 => eyeCandy.atoms(i).pc,
        
        -- Simulation eye candy signal: this is the currently executed instruction
        -- if there is one, Z otherwise.
        simInstr              => eyeCandy.atoms(i).instruction,
        
        -- Simulation eye candy signal: this is the currently executed instruction
        -- if there is one, Z otherwise.
        simReadResult         => eyeCandy.atoms(i).readResult
        
      );
  end generate;
  
  --===========================================================================
  -- Instantiate mockup configuration logic
  --===========================================================================
  process (clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        currentConfig <= (RC_NUM_ATOMS-1 => '1', others => '0');
        requestReconfig <= '0';
      else
        if currentConfig /= requestedConfig then
          if reconfigReady = '0' then
            requestReconfig <= '1';
          else
            currentConfig <= requestedConfig;
            requestReconfig <= '0';
          end if;
        else
          requestReconfig <= '0';
        end if;
      end if;
    end if;
  end process;
  
  --===========================================================================
  -- Instantiate mockup memory bus
  --===========================================================================
  membus_merge: entity rvex.cache_tb_mockMemBus
    port map (
      clk                   => clk,
      reset                 => reset,
      clkEn                 => clkEnBus,
      arbToCache            => memToCache,
      cacheToArb            => cacheToMem,
      memToArb              => memToCache_all,
      arbToMem              => cacheToMem_all
    );
  
  --===========================================================================
  -- Instantiate mockup memory
  --===========================================================================
  mem_init: process is
  begin
    for i in 0 to MEM_DEPTH - 1 loop
      ram_data(i) := std_logic_vector(to_unsigned(i, RC_BUS_DATA_WIDTH));
    end loop;
    wait;
  end process;
  
  process (clk) is
    variable index: natural;
  begin
    index := to_integer(unsigned(cacheToMem_all.addr(MEM_DEPTH_LOG2 + RC_BUS_SIZE_BLOG2 - 1 downto RC_BUS_SIZE_BLOG2)));
    if rising_edge(clk) then
      if reset = '1' then
        memToCache_all.data <= (others => 'U');
        memToCache_all.ready <= '0';
      elsif clkEnBus = '1' then
        if cacheToMem_all.readEnable = '1' then
          memToCache_all.data <= ram_data(index);
          memToCache_all.ready <= '1';
        elsif cacheToMem_all.writeEnable = '1' then
          for i in 0 to RC_BUS_MASK_WIDTH-1 loop
            if cacheToMem_all.writeMask(i) = '1' then
              ram_data(index)(i*8+7 downto i*8) := cacheToMem_all.writeData(i*8+7 downto i*8);
            end if;
          end loop;
          memToCache_all.data <= (others => 'U');
          memToCache_all.ready <= '1';
        else
          memToCache_all.data <= (others => 'U');
          memToCache_all.ready <= '1';
        end if;
      end if;
    end if;
  end process;
  
  --===========================================================================
  -- Stimulus
  --===========================================================================
  -- Change to your heart's content.
  
  config_stim_proc: process is
  begin
    requestedConfig <= "1000";
    wait for 2 us;
    requestedConfig <= "1010";
    wait;
  end process;
  
  invalToCache.invalEnable <= '0';
  invalToCache.invalAddr <= (others => '0');
  invalToCache.flushICache <= '0';
  invalToCache.flushDCache <= '0';
  
end Behavioral;