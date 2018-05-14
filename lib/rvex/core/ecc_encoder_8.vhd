 library ieee;
 use ieee.std_logic_1164.all;
 use ieee.numeric_std.all;
 use ieee.std_logic_unsigned;


 entity ecc_encoder_8 is
	 port (
	 		input			: in std_logic_vector (7 downto 0);
	 		output	 		: out std_logic_vector (11 downto 0);
			parity_encoder	: out std_logic_vector (3 downto 0) -- for simulation only. remove later
	 );
 end ecc_encoder_8;
	 
	 
 architecture structural of ecc_encoder_8 is
	 
 	function bit8_encoder (
			 input_data				: in std_logic_vector (8 downto 1))
		 	 return std_logic_vector is
	 		 variable encoded_data	: std_logic_vector (11 downto 0);
		begin
			encoded_data (7 downto 0) := input_data; --input data
		
			--parity bits
			encoded_data (8) := input_data(1)  xor input_data(2)  xor input_data(4)  xor input_data(5)  xor input_data(7); --P1
			encoded_data (9) := input_data(1)  xor input_data(3)  xor input_data(4)  xor input_data(6)  xor input_data(7); --P2
			encoded_data (10) := input_data(2)  xor input_data(3)  xor input_data(4)  xor input_data(8); --P4
			encoded_data (11) := input_data(5)  xor input_data(6)  xor input_data(7)  xor input_data(8); --P8
		 
	 		return std_logic_vector (encoded_data);
		end;
	 

 begin	 
 
	output 		   <= bit8_encoder(input);
	parity_encoder <= bit8_encoder(input)(11 downto 8); -- for simulation only. remove later
				
 end structural;