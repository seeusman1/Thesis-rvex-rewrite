
library ieee;
use ieee.std_logic_1164.all;

--=============================================================================
entity tmr_single_voter is
--=============================================================================

	port(

		input_1		: in std_logic;
		input_2		: in std_logic;
		input_3		: in std_logic;
		output		: out std_logic
	);
end tmr_single_voter;

--=============================================================================
architecture behavior of tmr_single_voter is
--=============================================================================
	


begin
	
	output	<= (input_1 and input_2) or (input_2 and input_3) or (input_1 and input_3);
	
end behavior;
