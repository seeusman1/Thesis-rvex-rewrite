library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--vsim -t ps -novopt -L unisim rvex.saboteur_tb

entity saboteur_tb is 
end saboteur_tb;

architecture test of saboteur_tb is


	constant Time_delta	: time	:= 100 ns;

	
	signal	reset		: std_logic	:='0';
	signal	clk			: std_logic	:='0';
	signal	start_ft	: std_logic	:='1';
	signal	saboteur	: std_logic;
	--signal count		: std_logic_vector(31 downto 0);






begin

	sabotr	: entity work.saboteur
		port map( reset 	=> reset,
				 clk		=> clk,
				 start_ft	=> start_ft,
				 saboteur	=> saboteur
				 --count1		=> count
		);
	
	
	process is
	begin
		
		
	
		clk <= not clk;

		wait for Time_delta;
	
	end process;
		
	process is
	begin
		
		wait for 500 us;
		start_ft	<= not start_ft;
		--reset	<= not reset;
	end process;

end architecture test;