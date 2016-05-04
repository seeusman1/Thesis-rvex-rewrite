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
use IEEE.MATH_REAL.ALL;
library work;
use work.MMU_pkg.all;



entity tb_CAM is
end entity ; -- tb_CAM

architecture arch of tb_CAM is



	constant CAM_NUM_ENTRIES 						: natural := 64;	
	constant PAGE_NUM_WIDTH 					    : natural := 18;


	signal clk 										: std_logic := '1';
	signal reset 									: std_logic := '1';
	signal in_data 									: std_logic_vector(PAGE_NUM_WIDTH-1 downto 0);
	signal read_out_addr 							: std_logic_vector(CAM_NUM_ENTRIES-1 downto 0);
	signal modify_en 								: std_logic := '0';
	signal modify_add_remove						: std_logic := '0';
	signal modify_in_addr 							: std_logic_vector(CAM_NUM_ENTRIES-1 downto 0);


begin

	UUT : entity work.CAM
	generic map(
		CAM_NUM_ENTRIES 							=> CAM_NUM_ENTRIES,
		CAM_WIDTH                                   => PAGE_NUM_WIDTH
	)
	port map(
		clk 										=> clk,
		reset 										=> reset,
		in_data 									=> in_data,
		read_out_addr 								=> read_out_addr,
		modify_en 									=> modify_en,
		modify_add_remove							=> modify_add_remove,
		modify_in_addr 								=> modify_in_addr
	);


	clk <= not clk after 10 ns;
	reset <= '1', '0' after 30 ns;
	
	modify_en <= '1', '0' after 100 ns, '1' after 200 ns, '0' after 220 ns, '1' after 300 ns, '0' after 320 ns, '1' after 400 ns, '0' after 420 ns;
	modify_add_remove <= '1', '0' after 300 ns, '1' after 400 ns;

	modify_in_addr <= 	(CAM_NUM_ENTRIES-1 downto 2 => '0') & "01",
			 			(CAM_NUM_ENTRIES-1 downto 2 => '0') & "10" after 200 ns,
			 			(CAM_NUM_ENTRIES-1 downto 3 => '0') & "100" after 400 ns;

	in_data <= 	(others => '0'),
				(PAGE_NUM_WIDTH-1 downto 2 => '0') & "01" after 200 ns;



end architecture ; -- arch