-- r-VEX processor MMU
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

-- 7. The MMU was developed by Jens Johansen.

-- Copyright (C) 2008-2016 by TU Delft.

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
library work;
use work.MMU_pkg.all;


entity tb_TLB is
end entity ; -- tb_TLB

architecture behavioural of tb_TLB is

    constant PAGE_NUM_WIDTH                         : natural := 18;

	signal clk 										: std_logic := '1';
	signal reset 									: std_logic := '1';
	signal read_PTag  								: std_logic_vector(PAGE_NUM_WIDTH-1 downto 0);
	signal read_miss								: std_logic;
	signal read_VTag 								: std_logic_vector(PAGE_NUM_WIDTH-1 downto 0);
	signal write_Enable 							: std_logic;
	signal write_PTag 								: std_logic_vector(PAGE_NUM_WIDTH-1 downto 0);
	signal write_VTag 								: std_logic_vector(PAGE_NUM_WIDTH-1 downto 0);
	signal write_done 								: std_logic;


begin

	UUT : entity work.TLB
	generic map(
	    MMU_CFG                 => MMU_cfg
	)
	port map(
		clk 					=> clk,
		reset 					=> reset,
		read_PTag 				=> read_PTag,
		read_miss				=> read_miss,
		read_VTag 				=> read_VTag,
		write_Enable 			=> write_Enable,
		write_PTag				=> write_PTag,
		write_VTag 				=> write_VTag,
		write_done				=> write_done
	);


	clk <= not clk after 5 ns;
	reset <= '1', '0' after 100 ns;

	write_VTag <= 	std_logic_vector(to_unsigned(11,PAGE_NUM_WIDTH)),
					std_logic_vector(to_unsigned(12,PAGE_NUM_WIDTH)) after 300 ns,
					std_logic_vector(to_unsigned(13,PAGE_NUM_WIDTH)) after 400 ns,
					std_logic_vector(to_unsigned(14,PAGE_NUM_WIDTH)) after 500 ns,
					std_logic_vector(to_unsigned(15,PAGE_NUM_WIDTH)) after 600 ns;


	write_PTag <= 	std_logic_vector(to_unsigned(1,PAGE_NUM_WIDTH)),
					std_logic_vector(to_unsigned(2,PAGE_NUM_WIDTH)) after 300 ns,
					std_logic_vector(to_unsigned(3,PAGE_NUM_WIDTH)) after 400 ns,
					std_logic_vector(to_unsigned(4,PAGE_NUM_WIDTH)) after 500 ns,
					std_logic_vector(to_unsigned(5,PAGE_NUM_WIDTH)) after 600 ns;


	write_Enable <= 	'0',
					 	'1' after 200 ns, '0' after 220 ns,
					 	'1' after 300 ns, '0' after 320 ns,
					 	'1' after 400 ns, '0' after 420 ns,
					 	'1' after 500 ns, '0' after 520 ns,
					 	'1' after 600 ns, '0' after 620 ns;

	read_VTag <= 	std_logic_vector(to_unsigned(11,PAGE_NUM_WIDTH)),
				 	std_logic_vector(to_unsigned(12,PAGE_NUM_WIDTH)) after 750 ns,
				 	std_logic_vector(to_unsigned(13,PAGE_NUM_WIDTH)) after 800 ns,
				 	std_logic_vector(to_unsigned(14,PAGE_NUM_WIDTH)) after 850 ns,
				 	std_logic_vector(to_unsigned(15,PAGE_NUM_WIDTH)) after 900 ns;







end architecture ; -- arch