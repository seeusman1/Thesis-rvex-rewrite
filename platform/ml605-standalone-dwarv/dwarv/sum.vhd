--
-- Delft University of Technology
-- Computer Engineering Laboratory
--
-- Generated code by the DWARV Compiler
--  3.4 (git: 07cf33166767df290210b92593027e99517c538c(Mon Feb 15 17:00:39 2016 +0100))
-- 
-- Developed by Razvan Nane, Vlad-Mihai Sima
-- 
-- Endianess: big  


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;

ENTITY CCU IS
	PORT(  --synchro signals
	    RST      : IN std_logic;
	    CLK      : IN std_logic;
	    START_OP : IN std_logic;
	    END_OP   : OUT std_logic;
	    --param interface 
	    return_DATA_W    : OUT std_logic_vector(31 downto 0);
	    return_DATA_WE   : OUT std_logic_vector(3 downto 0);
	    a_ADDR      : OUT std_logic_vector(9 downto 0);
	    a_DATA_R    : IN std_logic_vector(31 downto 0);
	    a_DATA_W    : OUT std_logic_vector(31 downto 0);
	    a_DATA_WE   : OUT std_logic_vector(3 downto 0);
	    b_DATA_R    : IN std_logic_vector(31 downto 0);
	    c_DATA_R    : IN std_logic_vector(7 downto 0);
	    d_ADDR      : OUT std_logic_vector(9 downto 0);
	    d_DATA_R    : IN std_logic_vector(15 downto 0);
	    d_DATA_W    : OUT std_logic_vector(15 downto 0);
	    d_DATA_WE   : OUT std_logic_vector(1 downto 0);
	    e_ADDR      : OUT std_logic_vector(9 downto 0);
	    e_DATA_R    : IN std_logic_vector(7 downto 0);
	    e_DATA_W    : OUT std_logic_vector(7 downto 0);
	    e_DATA_WE   : OUT std_logic_vector(0 downto 0)
	    );

END ENTITY CCU;

ARCHITECTURE ARCH_sum OF CCU IS

	signal var67: std_logic_vector(31 downto 0);
	signal var68: std_logic_vector(31 downto 0);
	signal var78: std_logic_vector(31 downto 0);
	signal var81: std_logic_vector(31 downto 0);
	signal var84: std_logic_vector(31 downto 0);
	signal var88: std_logic_vector(31 downto 0);
	signal var89: std_logic_vector(31 downto 0);
	signal var91: std_logic_vector(31 downto 0);
	signal var92: std_logic_vector(31 downto 0);
	signal var95: std_logic_vector(31 downto 0);
	signal var97: std_logic_vector(31 downto 0);
	signal var98: std_logic_vector(31 downto 0);

	signal SL_STATE : std_logic_vector(2 downto 0);
	signal SL_EXECUTE : std_logic;
	signal SL_EXEC_END : std_logic;

BEGIN

	START_EXEC: PROCESS(RST, CLK)
	BEGIN
		if(RST = '1') then
			sl_EXECUTE <= '0';
		elsif(CLK'event AND CLK = '1') then
			if(START_OP = '1') then
				sl_EXECUTE <= '1';
			elsif(sl_EXEC_END = '1') then
				sl_EXECUTE <= '0';
			end if;
		end if;
	END PROCESS;

	END_OP <= sl_EXEC_END;

	MAIN: PROCESS(RST, CLK)
	BEGIN
		if(RST = '1') then
			sl_EXEC_END <= '0';
			--sl_STATE <= "110";
			--STATUS(1 downto 0) <= "00";
		elsif(CLK'event AND CLK = '1') then
			if(sl_EXECUTE = '1' or START_OP = '1') then
				--sl_STATE <= sl_NEXT_STATE;
				--STATUS(1 downto 0) <= "01";
				if(sl_STATE = "110") then -- sl_NEXT_STATE changed to sl_STATE
					sl_EXEC_END <= '1';
				else
					sl_EXEC_END <= '0';
				end if;
			else
				sl_EXEC_END <= '0';
				--sl_STATE <= "110";
				--STATUS(1 downto 0) <= "00";
			end if;
		end if;
	END PROCESS;

	STATES: PROCESS (CLK, RST)

		variable CC : std_logic_vector(0 downto 0);

	BEGIN
--	wait until CLK'event AND CLK = '1';
		if(RST = '1') then
			sl_STATE <= (others=>'1'); -- sl_next_state changed to sl_state
		elsif(CLK'event AND CLK = '1') then
		  case sl_STATE is
			when "111" => 
				if start_op = '1' then
					sl_state <=  "000";
				else
					sl_state <=  "111";
				end if;
			when "000" => -- state_s 0
			   if start_op = '1' then
				sl_state <=  "001";  -- state_s 1
			   else
				sl_state <=  "000"; -- state_s 0
			   end if;
			when "001" => -- state_s 1
				sl_state <=  "010"; -- state_s 2
			when "010" => -- state_s 2
				sl_state <=  "011"; -- state_s 3
			when "011" => -- state_s 3
				sl_state <=  "100"; -- state_s 4
			when "100" => -- state_s 4
				sl_state <=  "101"; -- state_s 5
			when "101" => -- state_s 5
				sl_state <=  "110"; -- state_s 6
			when "110" => -- state_s 6
				sl_state <=  "000";
			when others =>
				sl_state <=  "110"; -- state_s 6
		  end case;
		end if;
	END PROCESS;

	EXECUTION: PROCESS (CLK, RST)

		variable v_var67: std_logic_vector(31 downto 0);
		variable v_var69: std_logic_vector(7 downto 0);
		variable v_var70: std_logic_vector(31 downto 0);
		variable v_var71: std_logic_vector(31 downto 0);
		variable v_var78: std_logic_vector(31 downto 0);
		variable v_var81: std_logic_vector(31 downto 0);
		variable v_var83: std_logic_vector(7 downto 0);
		variable v_var87: std_logic_vector(15 downto 0);
		variable v_MEM_TEMP_ADDR: std_logic_vector(17 downto 0);
		variable CC: std_logic_vector(0 downto 0);

	BEGIN
		IF(RST = '1') THEN
			--synthesis translate_off
			a_ADDR <= (others => 'Z');
			a_DATA_WE <= "0000";
			d_ADDR <= (others => 'Z');
			d_DATA_WE <= "00";
			e_ADDR <= (others => 'Z');
			e_DATA_WE <= "0";
			return_DATA_WE <= "0000";
			--synthesis translate_on
		ELSIF(CLK'event AND CLK = '1') THEN
				case sl_STATE is
when "000" => -- state 0
	var67 <= "00000000000000000000000000000000";
	v_var67 := "00000000000000000000000000000000";
	v_var69 := c_DATA_R;
	v_var70 := "00000000000000000000000000000000";
	d_ADDR <= v_var70(10 downto 1);
	v_var71 := "00000000000000000000000000000000";
	var78 <= std_logic_vector(resize(signed(v_var69),32));
	v_var78 := std_logic_vector(resize(signed(v_var69),32));
	a_ADDR    <= v_var67(11 downto 2);
	a_DATA_W  <= v_var78;
	a_DATA_WE <= "1111"; -- 'main.c L:6'
	var81 <= std_logic_vector(signed(resize(unsigned(v_var71),32)) + to_signed(4,32));
	v_var81 := std_logic_vector(signed(resize(unsigned(v_var71),32)) + to_signed(4,32));
	e_ADDR <= v_var81(9 downto 0);
	var68 <= b_DATA_R;
	var91 <= std_logic_vector(resize(signed(v_var69),32));
	d_DATA_WE <= "00";
	e_DATA_WE <= "0";
	return_DATA_WE <= "0000";
when "001" => -- state 1
	a_ADDR <= var67(11 downto 2);
	v_var87 := d_DATA_R;
	var88 <= std_logic_vector(resize(signed(v_var87),32));
	v_var83 := e_DATA_R;
	var84 <= std_logic_vector(resize(signed(v_var83),32));
	a_DATA_WE <= "0000";
	d_DATA_WE <= "00";
	e_DATA_WE <= "0";
	return_DATA_WE <= "0000";
when "010" => -- state 2
	var95 <= a_DATA_R;
	var89 <= std_logic_vector(signed(var84) + signed(var88)); --'main.c L:7'
	a_DATA_WE <= "0000";
	d_DATA_WE <= "00";
	e_DATA_WE <= "0";
	return_DATA_WE <= "0000";
when "011" => -- state 3
	var97 <= std_logic_vector(signed(var95) + signed(var68)); --'main.c L:7'
	var92 <= std_logic_vector(signed(var89) + signed(var91)); --'main.c L:7'
	a_DATA_WE <= "0000";
	d_DATA_WE <= "00";
	e_DATA_WE <= "0";
	return_DATA_WE <= "0000";
when "100" => -- state 4
	var98 <= std_logic_vector(signed(var92) + signed(var97)); --'main.c L:7'
	a_DATA_WE <= "0000";
	d_DATA_WE <= "00";
	e_DATA_WE <= "0";
	return_DATA_WE <= "0000";
when "101" => -- state 5
	return_DATA_W  <= var98(31 downto 0);
	return_DATA_WE <= "1111";
	a_DATA_WE <= "0000";
	d_DATA_WE <= "00";
	e_DATA_WE <= "0";
when others =>
	return_DATA_WE <= "0000";
	a_DATA_WE <= "0000";
	d_DATA_WE <= "00";
	e_DATA_WE <= "0";
			end case;
		END IF;
	END PROCESS;

END ARCHITECTURE ARCH_sum;



