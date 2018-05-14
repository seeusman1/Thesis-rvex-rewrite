 library ieee;
 use ieee.std_logic_1164.all;
 use ieee.numeric_std.all;

--vsim -t ps -novopt -L unisim rvex.ecc_encoder_8_tb

 entity ecc_encoder_8_tb is
 end ecc_encoder_8_tb;
	 
 architecture behavior of ecc_encoder_8_tb is
	 component ecc_encoder_8 is
	 	port (
	 			input			: in std_logic_vector (7 downto 0);
	 			output	 		: out std_logic_vector (11 downto 0);
				parity_encoder	: out std_logic_vector (3 downto 0) -- for simulation only. remove later
	 	);
	 end component;
	 
	signal input_encoder :	std_logic_vector (7 downto 0);
	signal output_encoder 	: std_logic_vector (11 downto 0);
	signal 	parity_encoder		: std_logic_vector (3 downto 0);

 begin
	 
	 dut_en	: ecc_encoder_8 port map (
		 			input => input_encoder,
		 			output=> output_encoder,
		 			parity_encoder => parity_encoder
		 		);
		 
		 
	process
		 begin
			 wait for 20 ns;
			 input_encoder <= X"11";
		 	
		 	wait for 20 ns;
		 	input_encoder <= X"77";
		 
		 	wait for 20 ns;
		 	input_encoder <= X"AA";

		 	wait for 20 ns;
		 	input_encoder <= X"55";

			wait;

	end process;
end behavior;
		 		