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

library unimacro;
use unimacro.vcomponents.all;

library work;
use work.common_pkg.all;

--=============================================================================
-- This component of the system ACE peripheral instantiates the block RAM that
-- serves as a sector buffer. It implicitly also serves as a cross-clock domain
-- bridge for the sector data.
-------------------------------------------------------------------------------
entity periph_sysace_buf is
--=============================================================================
  port (
    
    -- Interface for the front-end.
    clk33                       : in  std_logic;
    buf_address                 : in  std_logic_vector(8 downto 0);
    buf_readEnable              : in  std_logic;
    buf_readData                : out std_logic_vector(7 downto 0);
    buf_writeEnable             : in  std_logic;
    buf_writeData               : in  std_logic_vector(7 downto 0);
    
    -- Interface for the bus.
    clk                         : in  std_logic;
    bus_address                 : in  std_logic_vector(8 downto 2);
    bus_readEnable              : in  std_logic;
    bus_readData                : out rvex_data_type;
    bus_writeEnable             : in  std_logic;
    bus_writeMask               : in  rvex_mask_type;
    bus_writeData               : in  rvex_data_type
    
  );
end periph_sysace_buf;

--=============================================================================
architecture behavioral of periph_sysace_buf is
--=============================================================================
  
  -- Back-end access port intermediate signals.
  signal buf_ena                : std_logic;
  signal buf_we                 : std_logic_vector(0 downto 0);
  signal buf_address_int        : std_logic_vector(11 downto 0);
  
  -- Bus access port intermediate signals.
  signal bus_ena                : std_logic;
  signal bus_we                 : std_logic_vector(3 downto 0);
  signal bus_address_int        : std_logic_vector(9 downto 0);
  
--=============================================================================
begin
--=============================================================================
  
  -- Construct back-end access port intermediate signals.
  buf_ena <= buf_readEnable or buf_writeEnable;
  buf_we <= (others => buf_writeEnable);
  buf_address_int <= "000" & buf_address(8 downto 2)
    & (0 => not buf_address(1)) & (0 => not buf_address(0));
  
  -- Construct bus access port intermediate signals.
  bus_ena <= bus_readEnable or bus_writeEnable;
  bus_we <= bus_writeMask and (3 downto 0 => bus_writeEnable);
  bus_address_int <= "000" & bus_address;
  
  -- Instantiate the dual-port RAM block using a unimacro.
  ram_inst : BRAM_TDP_MACRO
    generic map (
      BRAM_SIZE => "36Kb",
      DEVICE => "VIRTEX6",
      INIT_FILE => "NONE",
      READ_WIDTH_A => 8,
      READ_WIDTH_B => 32,
      SIM_COLLISION_CHECK => "NONE",
      WRITE_MODE_A => "WRITE_FIRST",
      WRITE_MODE_B => "WRITE_FIRST",
      WRITE_WIDTH_A => 8,
      WRITE_WIDTH_B => 32
    )
    port map (
      
      -- Front-end access port.
      CLKA  => clk33,
      RSTA  => '0',
      ADDRA => buf_address_int,
      ENA   => buf_ena,
      DOA   => buf_readData,
      WEA   => buf_we,
      DIA   => buf_writeData,
      
      -- Bus access port.
      CLKB  => clk,
      RSTB  => '0',
      ADDRB => bus_address_int,
      ENB   => bus_ena,
      DOB   => bus_readData,
      WEB   => bus_we,
      DIB   => bus_writeData,
      
      -- Unused but need to be assigned for some reason.
      REGCEA => '1',
      REGCEB => '1'
      
   );
  
end behavioral;

