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

library work;
use work.common_pkg.all;
use work.core_pkg.all;
use work.cache_pkg.all;

--=============================================================================
-- This entity infers the block RAMs which store the cache lines for a data
-- cache block.
-------------------------------------------------------------------------------
entity cache_data_blockData is
--=============================================================================
  generic (
    
    -- Core configuration. Must be equal to the configuration presented to the
    -- rvex core connected to the cache.
    RCFG                        : rvex_generic_config_type := rvex_cfg;
    
    -- Cache configuration.
    CCFG                        : cache_generic_config_type := cache_cfg
    
  );
  port (
    
    -- Clock input.
    clk                         : in  std_logic;
    
    -- Active high enable input.
    enable                      : in  std_logic;
    
    -- CPU address input.
    cpuAddr                     : in  rvex_address_type;
    
    -- Read data output.
    --readData                    : out rvex_data_type;
	readData                    : out rvex_encoded_datacache_data_type;
    
    -- Active high write enable input.
    writeEnable                 : in  std_logic;
    
    -- Write data input.
    --writeData                   : in  rvex_data_type;
	writeData                   : in  rvex_encoded_datacache_data_type;
    
    -- Write byte mask input.
    writeMask                   : in  rvex_mask_type;
	
	-- Double Error Detection  
	ded							: out std_logic
    
  );
end cache_data_blockData;

--=============================================================================
architecture Behavioral of cache_data_blockData is
--=============================================================================
  
  -- Declare XST RAM extraction hints.
  attribute ram_extract       : string;
  attribute ram_style         : string;
  
  -- Cache data memory.
  --subtype ram_data_type is rvex_data_array(0 to 2**CCFG.dataCacheLinesLog2-1);
  subtype ram_data_type is rvex_encoded_datacache_data_array(0 to 2**CCFG.dataCacheLinesLog2-1);
  signal ram_data             : ram_data_type := (others => (others => 'X'));
  
  -- Hints for XST to implement the data memory in block RAMs.
  attribute ram_extract of ram_data : signal is "yes";
  attribute ram_style   of ram_data : signal is "block";
  
  -- CPU address/PC signals.
  signal cpuOffset            : std_logic_vector(dcacheOffsetSize(RCFG, CCFG)-1 downto 0);
  
  -- Individual write enable signals for each byte.
  signal byteWriteEnable      : rvex_mask_type;

  --
  signal ded_array				: std_logic_vector(3 downto 0) := (others => '0');
  --signal ded					: std_logic := '0';


  --Encoded signals
  signal writeData_encoded	: rvex_encoded_datacache_data_type := (others => 'X');
  signal readData_encoded	: rvex_encoded_datacache_data_type := (others => 'X');
--=============================================================================
begin -- architecture
--=============================================================================
  
  -- Extract the offset from the CPU address.
  cpuOffset <= cpuAddr(
    dcacheOffsetLSB(RCFG, CCFG) + dcacheOffsetSize(RCFG, CCFG) - 1
    downto dcacheOffsetLSB(RCFG, CCFG)
  );
  
  -- Construct the byte write enable signal.
  byte_we_proc: process (writeEnable, writeMask) is
  begin
    for i in 0 to 3 loop
      byteWriteEnable(i) <= writeEnable and writeMask(i);
    end loop;
  end process;
  
  -- Instantiate the data memory.
  ram_data_proc: process (clk) is
  begin
    if rising_edge(clk) then
      if enable = '1' then
        for i in 0 to 3 loop
          if byteWriteEnable(i) = '1' then

            ram_data(to_integer(unsigned(cpuOffset)))(13*i+12 downto 13*i) <=
              writeData_encoded(13*i+12 downto 13*i);
         --   ram_data(to_integer(unsigned(cpuOffset)))(8*i+7+16 downto 8*i+16) <=
         --     writeData_encoded(8*i+7+16 downto 8*i+16);
         --   ram_data(to_integer(unsigned(cpuOffset)))(15 downto 0) <= (others => '0');

            readData_encoded(13*i+12 downto 13*i) <=
              writeData_encoded(13*i+12 downto 13*i);
         --   readData_encoded(8*i+7+16 downto 8*i+16) <=
         --     writeData_encoded(8*i+7+16 downto 8*i+16);
		 --   readData_encoded(15 downto 0) <= (others => '0'); -- padded additional zeros
          else

            readData_encoded(13*i+12 downto 13*i) <=
              ram_data(to_integer(unsigned(cpuOffset)))(13*i+12 downto 13*i);
         --   readData_encoded(8*i+7+16 downto 8*i+16) <=
         --     ram_data(to_integer(unsigned(cpuOffset)))(8*i+7+16 downto 8*i+16);
         --   readData_encoded(15 downto 0) <= (others => '0'); -- padded additional zeros
		  ded_array(i)		<= bit8_ded(ram_data(to_integer(unsigned(cpuOffset)))(13*i+12 downto 13*i));
          end if;
        end loop;
		ded <= ded_array(0) or ded_array(1) or ded_array(2) or ded_array(3);
      end if;
    end if;
  end process;
		
		
		  
--  ECC_encoderbank: for i in 0 to 3 generate
--	ecc_encoder: entity work.ecc_encoder_8
--		port map (
--					input		=> writeData(8*i + 7  downto 8*i),
--					output		=> writeData_encoded(12*i + 11 downto 12*i)
--				);
--  end generate;		
												   
--  ECC_decoderbank: for i in 0 to 3 generate
--	ecc_decoder: entity work.ecc_decoder_8
--		port map (
--					input		=> readData_encoded(12*i + 11 downto 12*i),
--					output		=> readData(8*i + 7 downto 8*i)
--				);
--  end generate;	
		
		
		
 readData  <= readData_encoded;
 writeData_encoded <= writeData;
		
		
  
end Behavioral;

