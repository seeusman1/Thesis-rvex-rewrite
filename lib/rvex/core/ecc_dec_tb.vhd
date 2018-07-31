 library ieee;
 use ieee.std_logic_1164.all;
 use ieee.numeric_std.all;

--vsim -t ps -novopt -L unisim rvex.ecc_dec_tb

 entity ecc_dec_tb is
 end ecc_dec_tb;
	 
 architecture behavior of ecc_dec_tb is
	 component ecc_encoder_dec is
		port (
	 		input			: in std_logic_vector (31 downto 0);
	 		output	 		: out std_logic_vector (38 downto 0)
			--parity_encoder	: out std_logic_vector (5 downto 0)
	 		);
	 end component;
	 
	 component ecc_decoder_dec is
		port (
	 		input			: in std_logic_vector (38 downto 0);
			dec				: out std_logic
	 		--output	 		: out std_logic_vector (31 downto 0)
			--parity_decoder	: out std_logic_vector (5 downto 0)
	 		);
	 end component;	 
	 
	 
	signal input_encoder 	:	std_logic_vector (31 downto 0);
	signal output_encoder 	: std_logic_vector (38 downto 0);
	--signal parity_encoder	: std_logic_vector (5 downto 0);
	signal input_decoder 	:	std_logic_vector (38 downto 0);
	signal dec_decoder		: std_logic;
	--signal output_decoder 	: std_logic_vector (31 downto 0);
	--signal parity_decoder	: std_logic_vector (5 downto 0);

 begin
	 
	 dut_en		: ecc_encoder_dec port map (
		 			input 			=> input_encoder,
		 			output			=> output_encoder
		 			--parity_encoder 	=> parity_encoder
		 			);
	
	 input_decoder 		<= output_encoder xor ("011" & X"000000000"); --corrupted two bits
		 
	 dut_dec	: ecc_decoder_dec port map (
		 			input 			=> input_decoder,
		 			dec				=> dec_decoder
		 			--output			=> output_decoder
		 			--parity_decoder 	=> parity_decoder
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

			 wait for 20 ns;
			 input_encoder <= X"22222222";
		 	
		 	 wait for 20 ns;
		 	 input_encoder <= X"12345678";
		 
		 	 wait for 20 ns;
		 	 input_encoder <= X"9ABCDEF0";

		 	 wait for 20 ns;
		 	 input_encoder <= X"99999999";

		 	 wait for 20 ns;
		 	 input_encoder <= X"FFFFFFFF";

			wait;

	end process;
end behavior;
		 		