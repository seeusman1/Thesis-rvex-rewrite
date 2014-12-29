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
use rvex.cache_intIface_pkg.all;
use rvex.cache_instr_pkg.all;
use rvex.cache_data_pkg.all;

entity cache_arbiter is
  port (
    
    -- Clock input.
    clk                       : in  std_logic;
    
    -- Active high reset input.
    reset                     : in  std_logic;
    
    -- Active high clock enable input.
    clkEn                     : in  std_logic;
    
    -- Instruction cache memory bus.
    arbToICache               : out reconfICache_memIn;
    ICacheToArb               : in  reconfICache_memOut;
    
    -- Data cache memory bus.
    arbToDCache               : out reconfDCache_memIn;
    DCacheToArb               : in  reconfDCache_memOut;
    
    -- Combined memory bus.
    memToArb                  : in  reconfCache_memIn;
    arbToMem                  : out reconfCache_memOut;
    
    -- Invalidation output.
    invalOutput               : out RC_arbiterInvalOutput
    
  );
end cache_arbiter;

architecture Behavioral of cache_arbiter is
  
  -- State machine state/mux selection signals.
  signal selectDCache_next    : std_logic;
  signal selectDCache         : std_logic;
  
  -- Registers for the writeEnable and addr signals from the data cache, to
  -- align them with the ready signal for invalidation.
  signal writeEnable_r        : std_logic;
  signal writeAddr_r          : std_logic_vector(RC_BUS_ADDR_WIDTH-1 downto 0);
  
begin
  
  --===========================================================================
  -- Generate mux/demux logic
  --===========================================================================
  arbToICache.ready <= memToArb.ready and not selectDCache;
  arbToICache.data <= memToArb.data;
  
  arbToDCache.ready <= memToArb.ready and selectDCache;
  arbToDCache.data <= memToArb.data;
  
  arbToMem.addr <= DCacheToArb.addr when selectDCache_next = '1' else ICacheToArb.addr;
  arbToMem.readEnable <= DCacheToArb.readEnable when selectDCache_next = '1' else ICacheToArb.readEnable;
  arbToMem.writeData <= DCacheToArb.writeData;
  arbToMem.writeMask <= DCacheToArb.writeMask;
  arbToMem.writeEnable <= DCacheToArb.writeEnable and selectDCache_next;
  arbToMem.burstEnable <= '0';--ICacheToArb.readEnable and not selectDCache_next; -- Bursts don't seem to work reliably
  
  --===========================================================================
  -- Generate the selection state machine
  --===========================================================================
  select_comb: process (
    memToArb.ready, selectDCache,
    ICacheToArb.readEnable,
    DCacheToArb.readEnable, DCacheToArb.writeEnable
  ) is
    variable iacc, dacc: std_logic;
  begin
    
    -- Determine whether the caches want to do an access.
    iacc := ICacheToArb.readEnable;
    dacc := DCacheToArb.readEnable or DCacheToArb.writeEnable;
    
    -- If the other cache wants to do a bus access and the current one is
    -- either not requesting an access or the previous transfer is done,
    -- switch.
    if selectDCache = '1' then
      if (memToArb.ready = '1' or dacc = '0') and iacc = '1' then
        selectDCache_next <= '0';
      else
        selectDCache_next <= '1';
      end if;
    else
      if (memToArb.ready = '1' or iacc = '0') and dacc = '1' then
        selectDCache_next <= '1';
      else
        selectDCache_next <= '0';
      end if;
    end if;
    
  end process;
  
  select_seq: process (clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        selectDCache <= '0';
      elsif clkEn = '1' then
        selectDCache <= selectDCache_next;
      end if;
    end if;
  end process;
  
  --===========================================================================
  -- Generate invalidation logic
  --===========================================================================
  -- Delay the writeEnable and address signals by one cycle to align them with
  -- the ready signal.
  inval_regs: process (clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        writeEnable_r <= '0';
      elsif clkEn = '1' then
        writeEnable_r <= DCacheToArb.writeEnable;
        writeAddr_r <= DCacheToArb.addr;
      end if;
    end if;
  end process;
  
  -- Generate the invalidation signals.
  invalOutput.addr <= writeAddr_r;
  invalOutput.inval <= writeEnable_r and selectDCache and memToArb.ready;
  
end Behavioral;

