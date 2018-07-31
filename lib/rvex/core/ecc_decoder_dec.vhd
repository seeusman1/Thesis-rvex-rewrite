 library ieee;
 use ieee.std_logic_1164.all;
 use ieee.numeric_std.all;
 use ieee.std_logic_unsigned;


 entity ecc_decoder_dec is
	 port (
	 	input				: in std_logic_vector (38 downto 0);
	 	--output	 			: out std_logic_vector (31 downto 0);
		dec					: out std_logic
		--parity_decoder		: out std_logic_vector (5 downto 0) -- for simulation only. remove later
	 );
 end ecc_decoder_dec;
	 
 architecture structural of ecc_decoder_dec is
	 signal check_bits		: std_logic_vector (6 downto 0) := (others => '0');
	 
  	function bit32_checkbits (
	 		input_data			: in std_logic_vector (39 downto 1))
	 		return std_logic_vector is
	 		variable check_bits	: std_logic_vector (7 downto 1);

		begin
			--Check bits computations
			check_bits(1) := input_data(33)  	xor input_data(1)  xor input_data(2)  xor input_data(4)  xor input_data(5)  xor input_data(7)  xor input_data(9)  xor 
								 input_data(11) xor input_data(12) xor input_data(14) xor input_data(16) xor input_data(18) xor input_data(20) xor 
								 input_data(22) xor input_data(24) xor input_data(26) xor input_data(27) xor input_data(29) xor input_data(31); 
			check_bits(2) := input_data(34)  	xor input_data(1)  xor input_data(3)  xor input_data(4)  xor input_data(6)  xor input_data(7)  xor input_data(10) xor
								 input_data(11) xor input_data(13) xor input_data(14) xor input_data(17) xor input_data(18) xor input_data(21) xor
								 input_data(22) xor input_data(25) xor input_data(26) xor input_data(28) xor input_data(29) xor input_data(32); 
			check_bits(3) := input_data(35)  	xor input_data(2)  xor input_data(3)  xor input_data(4)  xor input_data(8)  xor input_data(9)  xor input_data(10) xor
								 input_data(11) xor input_data(15) xor input_data(16) xor input_data(17) xor input_data(18) xor input_data(23) xor
								 input_data(24) xor input_data(25) xor input_data(26) xor input_data(30) xor input_data(31) xor input_data(32); 
			check_bits(4) := input_data(36)  	xor input_data(5)  xor input_data(6)  xor input_data(7)  xor input_data(8)  xor input_data(9)  xor input_data(10) xor 
								 input_data(11) xor input_data(19) xor input_data(20) xor input_data(21) xor input_data(22) xor input_data(23) xor
								 input_data(24) xor input_data(25) xor input_data(26); 
			check_bits(5) := input_data(37)  	xor input_data(12) xor input_data(13) xor input_data(14) xor input_data(15) xor input_data(16) xor input_data(17) xor
								 input_data(18) xor input_data(19) xor input_data(20) xor input_data(21) xor input_data(22) xor input_data(23) xor 
								 input_data(24) xor input_data(25) xor input_data(26); 
			check_bits(6) := input_data(38)  	xor input_data(27) xor input_data(28) xor input_data(29) xor input_data(30) xor input_data(31) xor input_data(32); 

			check_bits(7) := input_data(1)  xor input_data(2)  xor input_data(3)  xor input_data(4)  xor input_data(5)  xor input_data(6)  xor 
								 input_data(7)  xor input_data(8)  xor input_data(9)  xor input_data(10) xor input_data(11) xor input_data(12) xor 
								 input_data(13) xor input_data(14) xor input_data(15) xor input_data(16) xor input_data(17) xor input_data(18) xor
								 input_data(19) xor input_data(20) xor input_data(21) xor input_data(22) xor input_data(23) xor input_data(24) xor 
								 input_data(25) xor input_data(26) xor input_data(27) xor input_data(28) xor input_data(29) xor input_data(30) xor 
								 input_data(31) xor input_data(32) xor input_data(33) xor input_data(34) xor input_data(35) xor input_data(36) xor
								 input_data(37) xor input_data(38) xor input_data(39); 

	 		return std_logic_vector (check_bits);

		end;
	 
	 
	begin 
	 
		check_bits	<= 	 bit32_checkbits(input);
		--parity_decoder <= check_bits; -- for simulation only. remove later
	 
		process (check_bits, input)
			begin
				
				if ((check_bits(5 downto 0) /= "000000") and (check_bits(6) = '0')) then
					dec	<= '1';
				elsif ((check_bits(5 downto 0) = "000000") and (check_bits(6) /= '0')) then
					dec <= '1';
				else
					dec <= '0';
				end if;
		end process;
	 	 
 	end structural;