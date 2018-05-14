 library ieee;
 use ieee.std_logic_1164.all;
 use ieee.numeric_std.all;

--vsim -t ps -novopt -L unisim rvex.ecc_decoder_tb

 entity ecc_decoder_tb is
 end ecc_decoder_tb;
	 
 architecture behavior of ecc_decoder_tb is
	 component ecc_decoder is
		port (
	 		input		: in std_logic_vector (37 downto 0);
	 		output	 	: out std_logic_Vector (31 downto 0);
			parity_decoder		: out std_logic_vector (5 downto 0)
	 		);
	 end component;
	 
	 
	signal clk	: std_logic := '0';
	signal input_decoder 	:	std_logic_vector (37 downto 0);
	signal output_decoder 	: std_logic_vector (31 downto 0);
	signal parity_decoder		: std_logic_vector (5 downto 0);


 begin
	 
	 dut_dec	: ecc_decoder port map (
		 			input => input_decoder,
		 			output=> output_decoder,
		 			parity_decoder => parity_decoder
		 			);
		 
		 
	process
		 begin
			 wait for 20 ns;
			 input_decoder <= "10" & X"411111111";
		 	
		 	 wait for 20 ns;
		 	 input_decoder <= "01" & X"777777777";
		 
		 	 wait for 20 ns;
		 	 input_decoder <= "10" & X"AAAAAAAAA";

		 	 wait for 20 ns;
		 	 input_decoder <= "11" & X"255555555";

			 wait;

		end process;
end behavior;
		 		