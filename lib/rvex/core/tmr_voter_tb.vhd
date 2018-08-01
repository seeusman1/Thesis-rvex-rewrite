library ieee;
use ieee.std_logic_1164.all;

entity tmr_voter_tb is 
end tmr_voter_tb;

architecture test of tmr_voter_tb is


	constant Time_delta	: time	:= 100 ns;

	
	signal	in_1		: std_logic	:='0';
	signal	in_2		: std_logic	:='0';
	signal	in_3		: std_logic	:='0';
	signal	tmr_out		: std_logic;
	signal error_corrected : std_logic := '0';


	component tmr_voter_modified is
		port(
		input_1		: in std_logic;
		input_2		: in std_logic;
		input_3		: in std_logic;
		output		: out std_logic;
		error_corrected : out std_logic
		);
	end component tmr_voter_modified;



begin

	voter	: tmr_voter_modified
		port map( input_1 		=> in_1,
			  input_2 	  		=> in_2,
			  input_3 	  		=> in_3,
			  output 	  		=> tmr_out,
			  error_corrected	=> error_corrected
		);
	
	
	process is
	begin
		
		in_1 <= '0';
		in_2 <= '0';
		in_3 <= '0';
	
		wait for Time_delta;
		
		in_1 <= '0';
		in_2 <= '0';
		in_3 <= '1';

		wait for Time_delta;

		in_1 <= '0';
		in_2 <= '1';
		in_3 <= '0';

		wait for Time_delta;
			
		in_1 <= '0';
		in_2 <= '1';
		in_3 <= '1';

		wait for Time_delta;
			
		in_1 <= '1';
		in_2 <= '0';
		in_3 <= '0';

		wait for Time_delta;
			
		in_1 <= '1';
		in_2 <= '0';
		in_3 <= '1';

		wait for Time_delta;
			
		in_1 <= '1';
		in_2 <= '1';
		in_3 <= '0';

		wait for Time_delta;
			
		in_1 <= '1';
		in_2 <= '1';
		in_3 <= '1';

		wait for Time_delta;
		
	
	end process;

end architecture test;