library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--vsim -t ps -novopt -L unisim rvex.saboteur_tb

entity saboteur_tb is 
end saboteur_tb;

architecture test of saboteur_tb is


	constant Time_delta	: time	:= 20 ns;

	
	signal	reset			: std_logic	:='0';
	signal	clk				: std_logic	:='0';
	signal	start_ft		: std_logic	:='1';
	--signal	saboteur	: std_logic;
    signal input			: std_logic_vector(31 downto 0) := (others => '0');
    signal mask_signal		: std_logic_vector(31 downto 0) := (others => '0');
    signal saboteur_out		: std_logic_vector(31 downto 0);
    signal fault_inserted 	: std_logic := '0';






begin

	sabotr	: entity work.saboteur
		port map( reset 	=> reset,
				 clk		=> clk,
				 start_ft	=> start_ft,
				 input		=> input,
				 mask_signal => mask_signal,
				 saboteur_out => saboteur_out,
				 fault_inserted => fault_inserted
		);
	
	
	process is
	begin
	
		clk <= not clk;

		wait for Time_delta;
	
	end process;
		
	process is
	begin
		
		wait for 10 ns;
		--start_ft	<= not start_ft;
		--reset	<= not reset;
		
	input <= X"AAAAAAAA" ;
	mask_signal <= X"FFFFFFFF";
		
		
	end process;

end architecture test;