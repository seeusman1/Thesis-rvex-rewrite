-- r-VEX processor
-- Copyright (C) 2008-2015 by TU Delft.
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

-- Copyright (C) 2008-2015 by TU Delft.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

library work;
use work.common_pkg.all;
use work.utils_pkg.all;

--=============================================================================
-- This entity instantiates a RAM of configurable depth with a configurable
-- number of read and write ports. When two ports write to the same memory word
-- simultaneously, the highest indexed port wins arbitration.
-------------------------------------------------------------------------------
entity core_gpRegs_simple is
--=============================================================================
  generic (
    
    -- log2 of the number of registers to instantiate.
    NUM_REGS_LOG2               : natural;
    
    -- Number of write ports to instantiate.
    NUM_WRITE_PORTS             : natural;
    
    -- Number of read ports to instantiate.
    NUM_READ_PORTS              : natural
    
  );
  port (
    
    ---------------------------------------------------------------------------
    -- System control
    ---------------------------------------------------------------------------
    -- Active high synchronous reset input.
    reset                       : in  std_logic;
    
    -- Clock input, registers are rising edge triggered.
    clk                         : in  std_logic;
    
    -- Active high global clock enable input.
    clkEn                       : in  std_logic;
    
    ---------------------------------------------------------------------------
    -- Write ports
    ---------------------------------------------------------------------------
    -- Write enables are active high, and gated by clkEn. Only the lower
    -- NUM_REGS_LOG2 bits of the addresses are used.
    writeEnable                 : in  std_logic_vector(NUM_WRITE_PORTS-1 downto 0);
    writeAddr_encoded           : in  rvex_encoded_address_array(NUM_WRITE_PORTS-1 downto 0);
    --writeData                   : in  rvex_data_array(NUM_WRITE_PORTS-1 downto 0);
	writeData                   : in  rvex_encoded_data_array(NUM_WRITE_PORTS-1 downto 0);
    
    ---------------------------------------------------------------------------
    -- Read ports
    ---------------------------------------------------------------------------
    -- Only the lower NUM_REGS_LOG2 bits of the address are used.
    readAddr_encoded            : in  rvex_encoded_address_array(NUM_READ_PORTS-1 downto 0);
    --readData                    : out rvex_data_array(NUM_READ_PORTS-1 downto 0)
	readData                    : out rvex_encoded_data_array(NUM_READ_PORTS-1 downto 0) 
    
  );
end core_gpRegs_simple;


--=============================================================================
architecture Behavioral of core_gpRegs_simple is
--=============================================================================
    
  --signal registers : rvex_data_array(0 to 2**NUM_REGS_LOG2 -1) := (others => (
    --others => '0'));
	signal registers : rvex_encoded_data_array(0 to 2**NUM_REGS_LOG2 -1) := (others => (
    	others => '0')); 

	signal readAddr                    : rvex_address_array(NUM_READ_PORTS-1 downto 0);
    signal writeAddr                   : rvex_address_array(NUM_WRITE_PORTS-1 downto 0);
          
--=============================================================================
begin -- architecture
--=============================================================================
             
  regs_proc : process(clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        registers <= (others => (others => '0'));
      elsif clkEn = '1' then
        for i in 0 to NUM_WRITE_PORTS-1 loop --write
          if writeEnable(i) = '1' then
            registers(to_integer(unsigned(writeAddr(i)))) <= writeData(i);
          end if;
        end loop;
        for j in 0 to NUM_READ_PORTS-1 loop -- read
          readData(j) <= registers(to_integer(unsigned(readAddr(j))));
        end loop;
      end if;
    end if;
  end process;

		
		
	---------------------------------------------------------------------------
    -- Decoder Bank for readAddress
    ---------------------------------------------------------------------------				
		
		decoder_readadd_bank: for i in 0 to NUM_READ_PORTS-1 generate
			decoder_readadd_bit32: entity work.ecc_decoder
				port map (
					input		=> readAddr_encoded(i),
					output		=> readAddr(i)
				);
		end generate;
								 
	---------------------------------------------------------------------------
    -- Decoder Bank for writeAddress
    ---------------------------------------------------------------------------				
		
		decoder_writeadd_bank: for i in 0 to NUM_WRITE_PORTS-1 generate
			decoder_writeadd_bit32: entity work.ecc_decoder
				port map (
					input		=> writeAddr_encoded(i),
					output		=> writeAddr(i)
				);
		end generate;
	
		
		
		
end Behavioral;

