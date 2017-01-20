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

library work;
use work.common_pkg.all;

--=============================================================================
-- This component of the system ACE peripheral manages the sector buffer,
-- giving commands to the front-end controller to load a new sector or write
-- the current data back to the card when the bus interface requires it.
-------------------------------------------------------------------------------
entity periph_sysace_ctrl is
--=============================================================================
  generic (
    
    -- Number of address bits used. This must be the log2 of the compactflash
    -- card size in bytes.
    ADDRESS_BITS                : natural := 29
    
  );
  port (
    
    -- Bus clock domain.
    reset                       : in  std_logic;
    clk                         : in  std_logic;
    clkEn                       : in  std_logic;
    
    -- System ACE clock domain.
    reset33                     : in  std_logic;
    clk33                       : in  std_logic;
    
    -- Interface with front-end.
    cmd_sector                  : out std_logic_vector(27 downto 0);
    cmd_read                    : out std_logic;
    cmd_write                   : out std_logic;
    cmd_ack                     : in  std_logic;
    
    -- Bus signals.
    bus_address                 : in  rvex_address_type;
    bus_readRequest             : in  std_logic;
    bus_writeRequest            : in  std_logic;
    bus_hit                     : out std_logic
    
  );
end periph_sysace_ctrl;

--=============================================================================
architecture behavioral of periph_sysace_ctrl is
--=============================================================================
  
  -- State of the sector buffer.
  signal sector_tag             : std_logic_vector(ADDRESS_BITS-1 downto 9);
  signal sector_valid           : std_logic;
  signal sector_dirty           : std_logic;
  
  -- Sector buffer state update signals.
  signal sector_loaded          : std_logic;
  signal sector_stored          : std_logic;
  
  -- Hit signal; high when sector_tag matches the bus address and the sector
  -- buffer is valid.
  signal hit                    : std_logic;
  
  -- Miss signal; high when the bus is requesting something but hit is low.
  signal miss                   : std_logic;
  
  -- Copy commands to the sysace front-end controller in the bus clock domain.
  signal bcmd_idle              : std_logic;
  signal bcmd_idle_prev         : std_logic;
  signal bcmd_request           : std_logic;
  signal bcmd_direction         : std_logic;
  signal bcmd_sector            : std_logic_vector(27 downto 0);
  
  -- Copy commands to the sysace front-end controller
  signal cmd_enable             : std_logic;
  signal cmd_direction          : std_logic;
  
--=============================================================================
begin
--=============================================================================
  
  -- Generate the tag registers.
  tag_reg_proc: process (clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        sector_tag <= (others => '0');
        sector_valid <= '0';
        sector_dirty <= '0';
      elsif clkEn = '1' then
        if sector_loaded = '1' then
          sector_tag <= bus_address(sector_tag'range);
          sector_valid <= '1';
          sector_dirty <= '0';
        elsif bus_writeRequest = '1' and hit = '1' then
          sector_dirty <= '1';
        elsif sector_stored = '1' then
          sector_dirty <= '0';
        end if;
      end if;
    end if;
  end process;
  
  -- Generate the hit signal.
  hit <= sector_valid when sector_tag = bus_address(sector_tag'range) else '0';
  bus_hit <= hit;
  
  -- Generate the miss signal.
  miss <= (bus_readRequest or bus_writeRequest) and not hit;
  
  -- Generate the tag register update signals.
  sector_loaded <= (not bcmd_direction) and bcmd_idle and not bcmd_idle_prev;
  sector_stored <= bcmd_direction and bcmd_idle and not bcmd_idle_prev;
  
  -- Request a copy command when we've been idle for at least one cycle (this
  -- allows the tag registers time to update based on the ack signal) if we
  -- (still) have a miss.
  bcmd_request <= miss and bcmd_idle and bcmd_idle_prev;
  
  -- If the sector buffer is dirty, we need to write it back to the
  -- compactflash card first.
  bcmd_direction <= sector_dirty;
  
  -- If we're writing back, use the address of the currently buffered sector.
  -- Otherwise, pull the sector containing the address currently requested on
  -- the bus.
  bcmd_sector_proc: process (bcmd_direction, sector_tag, bus_address) is
  begin
    bcmd_sector <= (others => '0');
    if bcmd_direction = '1' then
      bcmd_sector(ADDRESS_BITS-10 downto 0) <= sector_tag;
    else
      bcmd_sector(ADDRESS_BITS-10 downto 0) <= bus_address(sector_tag'range);
    end if;
  end process;
  
  -- Instantiate the command registers and the delayed idle signal.
  sync_regs: process (clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        bcmd_idle_prev <= '1';
        cmd_sector <= (others => '0');
        cmd_direction <= '0';
      elsif clkEn = '1' then
        bcmd_idle_prev <= bcmd_idle;
        if bcmd_request = '1' then
          cmd_sector <= bcmd_sector;
          cmd_direction <= bcmd_direction;
        end if;
      end if;
    end if;
  end process;
  
  -- Instantiate the cross-clock domain synchronization unit.
  ctrl_sync: entity work.utils_sync
    port map (
      reset                     => reset,
      
      -- Bus clock domain.
      a_clk                     => clk,
      a_clkEn                   => clkEn,
      a_inControl               => bcmd_idle,
      a_release                 => bcmd_request,
      
      -- Sysace clock domain.
      b_clk                     => clk33,
      b_clkEn                   => '1',
      b_inControl               => cmd_enable,
      b_release                 => cmd_ack
      
    );
  
  -- Combine the enable and direction signals into the read and write signals.
  cmd_read <= cmd_enable and not cmd_direction;
  cmd_write <= cmd_enable and cmd_direction;
  
end behavioral;

