 library ieee;
 use ieee.std_logic_1164.all;
 use ieee.numeric_std.all;
 use ieee.std_logic_unsigned;


 entity ecc_decoder_8_dec is
	 port (
	 	input				: in std_logic_vector (12 downto 0);
		dec					: out std_logic 
	 	--output	 			: out std_logic_vector (7 downto 0)
		--parity_decoder		: out std_logic_vector (3 downto 0) -- for simulation only. remove later
	 );
 end ecc_decoder_8_dec;
	 
 architecture structural of ecc_decoder_8_dec is
	 signal check_bits		: std_logic_vector (4 downto 0) := (others => '0');
	 
  	function bit8_checkbits (
	 		input_data			: in std_logic_vector (13 downto 1))
	 		return std_logic_vector is
	 		variable check_bits	: std_logic_vector (5 downto 1);

		begin
			--Check bits computations
			check_bits(1) := input_data(9)  	xor input_data(1)  xor input_data(2)  xor input_data(4)  xor input_data(5)  xor input_data(7); 
			check_bits(2) := input_data(10)  	xor input_data(1)  xor input_data(3)  xor input_data(4)  xor input_data(6)  xor input_data(7); 
			check_bits(3) := input_data(11)  	xor input_data(2)  xor input_data(3)  xor input_data(4)  xor input_data(8); 
			check_bits(4) := input_data(12)  	xor input_data(5)  xor input_data(6)  xor input_data(7)  xor input_data(8); 
			check_bits(5) := input_data(1)  xor input_data(2)  xor input_data(3)  xor input_data(4) xor  input_data(5)  xor input_data(6)  xor
							 input_data(7)  xor input_data(8) xor input_data(9)  xor input_data(10)  xor input_data(11)  xor input_data(12) xor
							 input_data(13); --DEC
 
	 		return std_logic_vector (check_bits);

		end;

  	function bit8_ded (
	 		input_data			: in std_logic_vector (13 downto 1))
	 		return std_logic is
			variable ded		: std_logic;
			variable check_bits	: std_logic_vector (5 downto 1);
	 		

		begin
			--variable check_bits	: std_logic_vector (5 downto 1);
			--Check bits computations
			check_bits(1) := input_data(9)  	xor input_data(1)  xor input_data(2)  xor input_data(4)  xor input_data(5)  xor input_data(7); 
			check_bits(2) := input_data(10)  	xor input_data(1)  xor input_data(3)  xor input_data(4)  xor input_data(6)  xor input_data(7); 
			check_bits(3) := input_data(11)  	xor input_data(2)  xor input_data(3)  xor input_data(4)  xor input_data(8); 
			check_bits(4) := input_data(12)  	xor input_data(5)  xor input_data(6)  xor input_data(7)  xor input_data(8); 
			check_bits(5) := input_data(1)  xor input_data(2)  xor input_data(3)  xor input_data(4) xor  input_data(5)  xor input_data(6)  xor
							 input_data(7)  xor input_data(8) xor input_data(9)  xor input_data(10)  xor input_data(11)  xor input_data(12) xor
							 input_data(13); --DEC

			if ((check_bits(3 downto 0) /= "0000") and (check_bits(4) = '0')) then
				ded	:= '1';
			elsif ((check_bits(3 downto 0) = "000000") and (check_bits(4) /= '0')) then
				ded := '1';
			else
				ded := '0';
			end if;
 
	 		return std_logic (ded);

		end;
	 
	 
	begin 
	 
--		check_bits	<= 	 bit8_checkbits(input);

	 
--		process (check_bits, input) is
--	  	 variable corrupted_bit_index : integer;
--	  	 variable temp		: std_logic_vector (15 downto 0);
--			begin
				
--				if ((check_bits(3 downto 0) /= "0000") and (check_bits(4) = '0')) then
--					dec	<= '1';
--				elsif ((check_bits(3 downto 0) = "000000") and (check_bits(4) /= '0')) then
--					dec <= '1';
--				else
--					dec <= '0';
--				end if;

--		end process; 
		
		
		dec <= bit8_ded(input);
	 	 
 end structural;