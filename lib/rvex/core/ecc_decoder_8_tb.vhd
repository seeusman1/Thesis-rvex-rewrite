 library ieee;
 use ieee.std_logic_1164.all;
 use ieee.numeric_std.all;

--vsim -t ps -novopt -L unisim rvex.ecc_decoder_8_tb

 entity ecc_decoder_8_tb is
 end ecc_decoder_8_tb;
	 
 architecture behavior of ecc_decoder_8_tb is
	 component ecc_decoder_8 is
	 	port (
	 		input				: in std_logic_vector (11 downto 0);
	 		output	 			: out std_logic_vector (7 downto 0);
			parity_decoder		: out std_logic_vector (3 downto 0) -- for simulation only. remove later
	 );
	 end component;
	 
	 
	signal input_decoder 	:	std_logic_vector (11 downto 0);
	signal output_decoder 	: std_logic_vector (7 downto 0);
	signal parity_decoder		: std_logic_vector (3 downto 0);


 begin
	 
	 dut_dec	: ecc_decoder_8 port map (
		 			input => input_decoder,
		 			output=> output_decoder,
		 			parity_decoder => parity_decoder
		 			);
		 
		 
	process
		 begin
			 wait for 20 ns;
			 input_decoder <= X"A11";
		 	
		 	 wait for 20 ns;
		 	 input_decoder <= X"877";
		 
		 	 wait for 20 ns;
		 	 input_decoder <= X"4AA";

		 	 wait for 20 ns;
		 	 input_decoder <= X"755";

			 wait;

		end process;
end behavior;
		 		