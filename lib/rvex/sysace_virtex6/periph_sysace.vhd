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

library rvex;
use rvex.common_pkg.all;
use rvex.bus_pkg.all;

--=============================================================================
-- This peripheral allows the usage of the CompactFlash card on the ML605
-- development board through the System ACE controller. It simply memory-maps
-- the contents of the card to the bus; there are no registers controlling the
-- interface. Writes to the memory-mapped region are buffered within a 512-byte
-- sector buffer; only when a different sector is read or written is the new
-- data flushed to the card. Thus, to ensure that all data is written to the
-- card after writing, simply read a dummy value from a different sector after
-- writing the last word.
-------------------------------------------------------------------------------
entity periph_sysace is
--=============================================================================
  generic (
    
    -- Number of address bits used. This must be the log2 of the compactflash
    -- card size in bytes.
    ADDRESS_BITS                : natural := 29
    
  );
  port (
    
    -- Bus clock domain.
    reset                       : in    std_logic;
    clk                         : in    std_logic;
    clkEn                       : in    std_logic;
    
    -- 33 MHz clock domain (system ACE controller).
    reset33                     : in    std_logic;
    clk33                       : in    std_logic;
    
    -- System ACE pads.
    sysace_d                    : inout std_logic_vector(7 downto 0);
    sysace_a                    : out   std_logic_vector(6 downto 0);
    sysace_brdy                 : in    std_logic;
    sysace_ce                   : out   std_logic;
    sysace_oe                   : out   std_logic;
    sysace_we                   : out   std_logic;
    
    -- Busy led output.
    busy_led                    : out   std_logic;
    
    -- Bus interface. This is mapped one-to-one to the compactflash card.
    bus2cf                      : in    bus_mst2slv_type;
    cf2bus                      : out   bus_slv2mst_type
    
  );
end periph_sysace;

--=============================================================================
architecture behavioral of periph_sysace is
--=============================================================================
  
  -- Interface between the back-end and the front-end.
  signal reg_address            : std_logic_vector(6 downto 0);
  signal reg_readEnable         : std_logic;
  signal reg_readData           : std_logic_vector(7 downto 0);
  signal reg_writeEnable        : std_logic;
  signal reg_writeData          : std_logic_vector(7 downto 0);
  signal reg_busy               : std_logic;
  signal reg_ack                : std_logic;
  
  -- Interface between the front-end and the sector buffer.
  signal buf_address            : std_logic_vector(8 downto 0);
  signal buf_readEnable         : std_logic;
  signal buf_readData           : std_logic_vector(7 downto 0);
  signal buf_writeEnable        : std_logic;
  signal buf_writeData          : std_logic_vector(7 downto 0);
  
  -- Sector access command signals.
  signal cmd_sector             : std_logic_vector(27 downto 0);
  signal cmd_read               : std_logic;
  signal cmd_write              : std_logic;
  signal cmd_ack                : std_logic;
  
  -- Bus control signals.
  signal bus_readEnable         : std_logic;
  signal bus_writeEnable        : std_logic;
  signal bus_readData           : rvex_data_type;
  signal bus_requesting_r       : std_logic;
  signal bus_hit                : std_logic;
  signal bus_hit_r              : std_logic;
  
--=============================================================================
begin
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- Instantiate back-end controller
  -----------------------------------------------------------------------------
  -- Instantiate back-end unit. This controls system ACE register access timing
  -- and also blocks sysace buffer accesses when the buffer is not ready.
  sysace_back_inst: entity rvex.periph_sysace_back
    port map (
      
      -- System control.
      reset33                   => reset33,
      clk33                     => clk33,
      
      -- System ACE interface (pads).
      sysace_d                  => sysace_d,
      sysace_a                  => sysace_a,
      sysace_brdy               => sysace_brdy,
      sysace_ce                 => sysace_ce,
      sysace_oe                 => sysace_oe,
      sysace_we                 => sysace_we,
      
      -- Interface with the front-end.
      reg_address               => reg_address,
      reg_readEnable            => reg_readEnable,
      reg_readData              => reg_readData,
      reg_writeEnable           => reg_writeEnable,
      reg_writeData             => reg_writeData,
      reg_busy                  => reg_busy,
      reg_ack                   => reg_ack
      
    );
  
  -----------------------------------------------------------------------------
  -- Instantiate front-end controller
  -----------------------------------------------------------------------------
  -- Instantiate the front-end unit. This controls the register access patterns
  -- needed to read and write sectors from and to the compactflash card.
  sysace_front_inst: entity rvex.periph_sysace_front
    port map (
      
      -- System control.
      reset33                   => reset33,
      clk33                     => clk33,
      
      -- Interface with the front-end.
      reg_address               => reg_address,
      reg_readEnable            => reg_readEnable,
      reg_readData              => reg_readData,
      reg_writeEnable           => reg_writeEnable,
      reg_writeData             => reg_writeData,
      reg_busy                  => reg_busy,
      reg_ack                   => reg_ack,
      
      -- Buffer interface.
      buf_address               => buf_address,
      buf_readEnable            => buf_readEnable,
      buf_readData              => buf_readData,
      buf_writeEnable           => buf_writeEnable,
      buf_writeData             => buf_writeData,
      
      -- Command interface.
      cmd_sector                => cmd_sector,
      cmd_read                  => cmd_read,
      cmd_write                 => cmd_write,
      cmd_ack                   => cmd_ack
      
    );
  
  -----------------------------------------------------------------------------
  -- Instantiate sector buffer
  -----------------------------------------------------------------------------
  -- Instantiate the sector buffer. This provides most of the cross-clock
  -- domain stuff by constructed from a true-dual-port block RAM.
  sysace_buf_inst: entity rvex.periph_sysace_buf
    port map (
      
      -- Interface with the front-end.
      clk33                     => clk33,
      buf_address               => buf_address,
      buf_readEnable            => buf_readEnable,
      buf_readData              => buf_readData,
      buf_writeEnable           => buf_writeEnable,
      buf_writeData             => buf_writeData,
      
      -- Interface with the bus.
      clk                       => clk,
      bus_address               => bus2cf.address(8 downto 2),
      bus_readEnable            => bus_readEnable,
      bus_readData              => bus_readData,
      bus_writeEnable           => bus_writeEnable,
      bus_writeMask             => bus2cf.writeMask,
      bus_writeData             => bus2cf.writeData
      
    );
  
  -----------------------------------------------------------------------------
  -- Instantiate control/sync unit
  -----------------------------------------------------------------------------
  -- Instantiate the sector buffer control unit that handles "cache" misses.
  sysace_ctrl_inst: entity rvex.periph_sysace_ctrl
    generic map (
      ADDRESS_BITS              => ADDRESS_BITS
    )
    port map (
      
      -- Bus clock domain.
      reset                     => reset,
      clk                       => clk,
      clkEn                     => clkEn,
      
      -- System ACE clock domain.
      reset33                   => reset33,
      clk33                     => clk33,
      
      -- Interface with front-end.
      cmd_sector                => cmd_sector,
      cmd_read                  => cmd_read,
      cmd_write                 => cmd_write,
      cmd_ack                   => cmd_ack,
      
      -- Bus signals.
      bus_address               => bus2cf.address,
      bus_readRequest           => bus2cf.readEnable,
      bus_writeRequest          => bus2cf.writeEnable,
      bus_hit                   => bus_hit
      
    );  
  
  -----------------------------------------------------------------------------
  -- Connect the r-VEX bus
  -----------------------------------------------------------------------------
  -- Perform bus accesses only when the correct sector is loaded into the
  -- buffer.
  bus_readEnable <= bus2cf.readEnable and bus_hit;
  bus_writeEnable <= bus2cf.writeEnable and bus_hit;
  
  -- Store whether we received or were handling a bus request in the previous
  -- cycle in order to generate the busy and ack signals.
  bus_req_reg: process (clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        bus_requesting_r <= '0';
        bus_hit_r <= '0';
      elsif clkEn = '1' then
        bus_requesting_r <= bus_requesting(bus2cf);
        bus_hit_r <= bus_hit;
      end if;
    end if;
  end process;
  
  -- Construct the bus response signal.
  bus_response_proc: process (
    bus_readData, bus_requesting_r, bus_hit_r
  ) is
  begin
    cf2bus <= BUS_SLV2MST_IDLE;
    cf2bus.readData <= bus_readData;
    cf2bus.busy <= bus_requesting_r and not bus_hit_r;
    cf2bus.ack <= bus_requesting_r and bus_hit_r;
  end process;
  
  -----------------------------------------------------------------------------
  -- Busy LED output
  -----------------------------------------------------------------------------
  -- Output the busy signal.
  busy_led <= cmd_read or cmd_write;
  
end behavioral;

