 library ieee;
 use ieee.std_logic_1164.all;
 use ieee.numeric_std.all;

--vsim -t ps -novopt -L unisim rvex.ecc_encoder_tb

 entity ecc_encoder_tb is
 end ecc_encoder_tb;
	 
 architecture behavior of ecc_encoder_tb is
	 component ecc_encoder is
		port (
	 		input		: in std_logic_vector (31 downto 0);
	 		output	 	: out std_logic_vector (37 downto 0);
			parity_encoder	: out std_logic_vector (5 downto 0)
	 		);
	 end component;
	 
	signal input_encoder :	std_logic_vector (31 downto 0);
	signal output_encoder 	: std_logic_vector (37 downto 0);
	signal 	parity_encoder		: std_logic_vector (5 downto 0);

 begin
	 
	 dut_en	: ecc_encoder port map (
		 		input => input_encoder,
		 		output=> output_encoder,
		 		parity_encoder => parity_encoder
		 		);
		 
		 
	process
		 begin
			 wait for 20 ns;
			 input_encoder <= X"11111111";
		 	
		 	wait for 20 ns;
		 	input_encoder <= X"77777777";
		 
		 	wait for 20 ns;
		 	input_encoder <= X"AAAAAAAA";

		 	wait for 20 ns;
		 	input_encoder <= X"55555555";

			wait;

	end process;
end behavior;
		 		