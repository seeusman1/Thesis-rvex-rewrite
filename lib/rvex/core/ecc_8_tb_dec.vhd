 library ieee;
 use ieee.std_logic_1164.all;
 use ieee.numeric_std.all;

--vsim -t ps -novopt -L unisim rvex.ecc_8_dec_tb

 entity ecc_8_dec_tb is
 end ecc_8_dec_tb;
	 
 architecture behavior of ecc_8_dec_tb is
	 component ecc_encoder_8_dec is
	 	port (
	 			input			: in std_logic_vector (7 downto 0);
	 			output	 		: out std_logic_vector (12 downto 0)
				--parity_encoder	: out std_logic_vector (3 downto 0) -- for simulation only. remove later
	 	);
	 end component;
	 
	 component ecc_decoder_8_dec is
	 	port (
	 		input				: in std_logic_vector (12 downto 0);
			dec					: out std_logic
	 		--output	 			: out std_logic_vector (7 downto 0);
			--parity_decoder		: out std_logic_vector (3 downto 0) -- for simulation only. remove later
	 	);
	 end component;	 
	 
	 
	signal input_encoder 	:	std_logic_vector (7 downto 0);
	signal output_encoder 	: 	std_logic_vector (12 downto 0);
	--signal parity_encoder	: 	std_logic_vector (3 downto 0);
	signal input_decoder 	:	std_logic_vector (12 downto 0);
	--signal output_decoder 	: 	std_logic_vector (7 downto 0);
	--signal parity_decoder	: 	std_logic_vector (3 downto 0);
	signal dec_decoder		: std_logic;

 begin
	 
	 dut_en		: ecc_encoder_8_dec port map (
		 			input 			=> input_encoder,
		 			output			=> output_encoder
		 			--parity_encoder 	=> parity_encoder
		 			);
	
	 --input_decoder 		<= output_encoder xor "1000000000001"; --corrupt two bits
		 input_decoder 		<= output_encoder and "1111111111100";
		 
	 dut_dec	: ecc_decoder_8_dec port map (
		 			input 			=> input_decoder,
		 			dec				=> dec_decoder
		 			--output			=> output_decoder,
		 			--parity_decoder 	=> parity_decoder
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

			 wait for 20 ns;
			 input_encoder <= X"22";
		 	
		 	 wait for 20 ns;
		 	 input_encoder <= X"12";
		 
		 	 wait for 20 ns;
		 	 input_encoder <= X"9A";

		 	 wait for 20 ns;
		 	 input_encoder <= X"99";

		 	 wait for 20 ns;
		 	 input_encoder <= X"FF";

		 	 wait for 20 ns;
		 	 input_encoder <= X"00";


	end process;
end behavior;
		 		