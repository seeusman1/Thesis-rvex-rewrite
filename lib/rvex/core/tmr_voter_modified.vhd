
library ieee;
use ieee.std_logic_1164.all;

--=============================================================================
entity tmr_voter_modified is
--=============================================================================

	port(

		input_1			: in std_logic;
		input_2			: in std_logic;
		input_3			: in std_logic;
		output			: out std_logic;
		error_corrected : out std_logic
	);
end tmr_voter_modified;

--=============================================================================
architecture behavior of tmr_voter_modified is
--=============================================================================
	
	signal outputs		: std_logic_vector(3 downto 1);
    signal temp_output	: std_logic;

begin
	
	
	first_stage_voters: for i in 1 to 3 generate
		voter: entity work.tmr_single_voter
			port map (
				input_1		=> input_1,
				--input_1		=> '0',
				input_2		=> input_2,
				--input_2		=> '0',
				input_3		=> input_3,
				--input_3		=> '0',
				output		=> outputs(i)
			);
	end generate;	
	
	
	second_stage_voter: entity work.tmr_single_voter
		port map (
				input_1		=> outputs(1),
				--input_1		=> '0',
				input_2		=> outputs(2),
				--input_2		=> '0',
				input_3		=> outputs(3),
				--input_3		=> '0',
				output		=> temp_output
		);
		
	output 			<= temp_output;
	error_corrected	<= (input_1 xor temp_output) or (input_2 xor temp_output) or (input_3 xor temp_output); 

end behavior;
