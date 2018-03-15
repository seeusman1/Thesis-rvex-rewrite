 library ieee;
 use ieee.std_logic_1164.all;
 use ieee.numeric_std.all;
 use ieee.std_logic_unsigned;


 entity ecc_encoder is
	 port (
	 	input			: in std_logic_vector (31 downto 0);
	 	output	 		: out std_logic_vector (37 downto 0)
		--parity_encoder	: out std_logic_vector (5 downto 0)
	 );
 end ecc_encoder;
	 
	 
 architecture structural of ecc_encoder is
	 
 	function bit32_encoder (
			 input_data				: in std_logic_vector (32 downto 1))
		 	return std_logic_vector is
	 		variable encoded_data	: std_logic_vector (37 downto 0);
		begin
			encoded_data (31 downto 0) := input_data; --input data
		
			--parity bits
			encoded_data (32) := input_data(1)  xor input_data(2)  xor input_data(4)  xor input_data(5)  xor input_data(7)  xor input_data(9)  xor 
								 input_data(11) xor input_data(12) xor input_data(14) xor input_data(16) xor input_data(18) xor input_data(20) xor 
								 input_data(22) xor input_data(24) xor input_data(26) xor input_data(27) xor input_data(29) xor input_data(31); --P1
			encoded_data (33) := input_data(1)  xor input_data(3)  xor input_data(4)  xor input_data(6)  xor input_data(7)  xor input_data(10) xor
								 input_data(11) xor input_data(13) xor input_data(14) xor input_data(17) xor input_data(18) xor input_data(21) xor
								 input_data(22) xor input_data(25) xor input_data(26) xor input_data(28) xor input_data(29) xor input_data(32); --P2
			encoded_data (34) := input_data(2)  xor input_data(3)  xor input_data(4)  xor input_data(8)  xor input_data(9)  xor input_data(10) xor
								 input_data(11) xor input_data(15) xor input_data(16) xor input_data(17) xor input_data(18) xor input_data(23) xor
								 input_data(24) xor input_data(25) xor input_data(26) xor input_data(30) xor input_data(31) xor input_data(32); --P4
			encoded_data (35) := input_data(5)  xor input_data(6)  xor input_data(7)  xor input_data(8)  xor input_data(9)  xor input_data(10) xor 
								 input_data(11) xor input_data(19) xor input_data(20) xor input_data(21) xor input_data(22) xor input_data(23) xor
								 input_data(24) xor input_data(25) xor input_data(26); --P8
			encoded_data (36) := input_data(12) xor input_data(13) xor input_data(14) xor input_data(15) xor input_data(16) xor input_data(17) xor
								 input_data(18) xor input_data(19) xor input_data(20) xor input_data(21) xor input_data(22) xor input_data(23) xor 
								 input_data(24) xor input_data(25) xor input_data(26); --P16
			encoded_data (37) := input_data(27) xor input_data(28) xor input_data(29) xor input_data(30) xor input_data(31) xor input_data(32); --P32
		 
	 		return std_logic_vector (encoded_data);
		end;
	 

 begin	 
 
	output 		   <= bit32_encoder(input);
	--parity_encoder <= bit32_encoder(input)(37 downto 32); -- for simulation only. remove later
				

 end structural;