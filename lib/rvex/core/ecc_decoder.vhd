 library ieee;
 use ieee.std_logic_1164.all;
 use ieee.numeric_std.all;
 use ieee.std_logic_unsigned;


 entity ecc_decoder is
	 port (
	 	input		: in std_logic_vector (37 downto 0);
	 	output	 	: out std_logic_Vector (31 downto 0);
		parity_decoder		: out std_logic_vector (5 downto 0) -- for simulation only. remove later
	 );
 end ecc_decoder;
	 
 architecture structural of ecc_decoder is
	 signal check_bits	: std_logic_vector (5 downto 0) := (others => '0');
	 
  	function bit32_checkbits (
	 		input_data		: in std_logic_vector (38 downto 1))
	 		return std_logic_vector is
	 		variable check_bits	: std_logic_vector (6 downto 1);

		begin
			--Check bits computations
			check_bits(1) := input_data(33)  	xor input_data(1)  xor input_data(2)  xor input_data(4)  xor input_data(5)  xor input_data(7)  xor input_data(9)  xor 
								 input_data(11) xor input_data(12) xor input_data(14) xor input_data(16) xor input_data(18) xor input_data(20) xor 
								 input_data(22) xor input_data(24) xor input_data(26) xor input_data(27) xor input_data(29) xor input_data(31); --P1
			check_bits(2) := input_data(34)  	xor input_data(1)  xor input_data(3)  xor input_data(4)  xor input_data(6)  xor input_data(7)  xor input_data(10) xor
								 input_data(11) xor input_data(13) xor input_data(14) xor input_data(17) xor input_data(18) xor input_data(21) xor
								 input_data(22) xor input_data(25) xor input_data(26) xor input_data(28) xor input_data(29) xor input_data(32); --P2
			check_bits(3) := input_data(35)  	xor input_data(2)  xor input_data(3)  xor input_data(4)  xor input_data(8)  xor input_data(9)  xor input_data(10) xor
								 input_data(11) xor input_data(15) xor input_data(16) xor input_data(17) xor input_data(18) xor input_data(23) xor
								 input_data(24) xor input_data(25) xor input_data(26) xor input_data(30) xor input_data(31) xor input_data(32); --P4
			check_bits(4) := input_data(36)  	xor input_data(5)  xor input_data(6)  xor input_data(7)  xor input_data(8)  xor input_data(9)  xor input_data(10) xor 
								 input_data(11) xor input_data(19) xor input_data(20) xor input_data(21) xor input_data(22) xor input_data(23) xor
								 input_data(24) xor input_data(25) xor input_data(26); --P8
			check_bits(5) := input_data(37)  	xor input_data(12) xor input_data(13) xor input_data(14) xor input_data(15) xor input_data(16) xor input_data(17) xor
								 input_data(18) xor input_data(19) xor input_data(20) xor input_data(21) xor input_data(22) xor input_data(23) xor 
								 input_data(24) xor input_data(25) xor input_data(26); --P16
			check_bits(6) := input_data(38)  	xor input_data(27) xor input_data(28) xor input_data(29) xor input_data(30) xor input_data(31) xor input_data(32); --P32

	 		return std_logic_vector (check_bits);

		end;
	 
	 
	begin 
	 
		check_bits	<= 	 bit32_checkbits(input);
		--parity_decoder <= bit32_checkbits(input);
		parity_decoder <= check_bits; -- for simulation only. remove later
	 
		process (check_bits, input)
	  	 variable corrupted_bit_index : integer;
	  	 variable temp		: std_logic_vector (38 downto 0);
			begin
				if check_bits = "000000" then
					output 					<=		input (31 downto 0);

				else
					temp(2 downto 1) 		:= input(33 downto 32); --parity bits
					temp(3)		  			:= input(0);
					temp(4)		  			:= input(34); --parity bit
					temp(7 downto 5) 		:= input(3 downto 1);
					temp(8)		  			:= input(35); --parity bit
					temp(15 downto 9)		:= input (10 downto 4);
					temp(16)				:= input(36); --parity bit
					temp(31 downto 17) 		:= input(25 downto 11);
					temp(32)				:= input(37); --parity bit
					temp(38 downto 33) 		:= input(31 downto 26);

					corrupted_bit_index		:= to_integer(unsigned(check_bits)) ; 
					temp(corrupted_bit_index):= not temp(corrupted_bit_index); --fixed corrupted bit


					output (0) 				<= temp(3);
					output (3 downto 1) 	<= temp(7 downto 5);
					output (10 downto 4) 	<= temp (15 downto 9);
					output (25 downto 11) 	<= temp (31 downto 17);
					output (31 downto 26)  	<= temp (38 downto 33);		
				
				end if;
		end process; 
	 	 
 end structural;