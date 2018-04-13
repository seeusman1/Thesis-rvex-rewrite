 library ieee;
 use ieee.std_logic_1164.all;
 use ieee.numeric_std.all;
 use ieee.std_logic_unsigned;


 entity ecc_decoder_8 is
	 port (
	 	input				: in std_logic_vector (11 downto 0);
	 	output	 			: out std_logic_vector (7 downto 0);
		parity_decoder		: out std_logic_vector (3 downto 0) -- for simulation only. remove later
	 );
 end ecc_decoder_8;
	 
 architecture structural of ecc_decoder_8 is
	 signal check_bits		: std_logic_vector (3 downto 0) := (others => '0');
	 
  	function bit8_checkbits (
	 		input_data			: in std_logic_vector (12 downto 1))
	 		return std_logic_vector is
	 		variable check_bits	: std_logic_vector (4 downto 1);

		begin
			--Check bits computations
			check_bits(1) := input_data(9)  	xor input_data(1)  xor input_data(2)  xor input_data(4)  xor input_data(5)  xor input_data(7); 
			check_bits(2) := input_data(10)  	xor input_data(1)  xor input_data(3)  xor input_data(4)  xor input_data(6)  xor input_data(7); 
			check_bits(3) := input_data(11)  	xor input_data(2)  xor input_data(3)  xor input_data(4)  xor input_data(8); 
			check_bits(4) := input_data(12)  	xor input_data(5)  xor input_data(6)  xor input_data(7)  xor input_data(8); 
 
	 		return std_logic_vector (check_bits);

		end;
	 
	 
	begin 
	 
		check_bits	<= 	 bit8_checkbits(input);
		parity_decoder <= check_bits; -- for simulation only. remove later
	 
		process (check_bits, input) is
	  	 variable corrupted_bit_index : integer;
	  	 variable temp		: std_logic_vector (15 downto 0);
			begin
				if check_bits = "0000" then
					output 					<=		input (7 downto 0);

				else
					temp(2 downto 1) 		:= input(9 downto 8); --parity bits
					temp(3)		  			:= input(0);
					temp(4)		  			:= input(10); --parity bit
					temp(7 downto 5) 		:= input(3 downto 1);
					temp(8)		  			:= input(11); --parity bit
					temp(12 downto 9)		:= input (7 downto 4);

					corrupted_bit_index		:= to_integer(unsigned(check_bits)) ; --Corrupted bit index
					temp(corrupted_bit_index):= not temp(corrupted_bit_index); --fixed corrupted bit


					output (0) 				<= temp(3);
					output (3 downto 1) 	<= temp(7 downto 5);
					output (7 downto 4) 	<= temp (12 downto 9);
	
				
				end if;
		end process; 
	 	 
 end structural;