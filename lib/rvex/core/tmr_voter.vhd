library ieee;
use ieee.std_logic_1164.all;

--=============================================================================
entity tmr_voter is
--=============================================================================

	port(

		input_1		: in std_logic;
		input_2		: in std_logic;
		input_3		: in std_logic;
		output		: out std_logic
	);
end tmr_voter;

architecture behavior of tmr_voter is
	
	signal and_1_2		: std_logic;
  	signal and_2_3		: std_logic;
  	signal and_1_3		: std_logic;
  	signal rst			: std_logic;

begin
	
	output	<= (input_1 and input_2) or (input_2 and input_3) or (input_1 and input_3);

end behavior;
