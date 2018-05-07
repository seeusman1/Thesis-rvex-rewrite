library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.common_pkg.all;
use work.utils_pkg.all;
use work.core_pkg.all;
use work.core_intIface_pkg.all;
use work.core_pipeline_pkg.all;


--=============================================================================
entity tmr_gpregvoter1 is
--=============================================================================
	
  generic (
    
    -- log2 of the number of registers to instantiate.
    NUM_REGS_LOG2               : natural;-- := 6;
    
    -- Number of write ports to instantiate.
    NUM_WRITE_PORTS             : natural;-- := 2;
    
    -- Number of read ports to instantiate.
    NUM_READ_PORTS              : natural-- := 2
    
  );

  port	(
	  
	-- Active high synchronous reset input.
    reset                       : in  std_logic;
    
    -- Clock input, registers are rising edge triggered.
    clk                         : in  std_logic;
    
    -- Active high global clock enable input.
    clkEn                       : in  std_logic;
	  
	--Active high fault tolerance enable  
	start_ft					: in std_logic;
	  
	--signal representing active pipelane groups for fault tolerance mode
	config_signal				: in std_logic_vector (3 downto 0); 
	   
	  

  --constant NUM_READ_PORTS         : natural := 2*2**CFG.numLanesLog2;
  --constant NUM_WRITE_PORTS        : natural := 2**CFG.numLanesLog2;
	  
    ---------------------------------------------------------------------------
    -- Signals that go into GPREG Majority voter
    ---------------------------------------------------------------------------
    writeEnable                 : in std_logic_vector(NUM_WRITE_PORTS-1 downto 0);
    writeAddr                   : in rvex_address_array(NUM_WRITE_PORTS-1 downto 0);
    writeData                   : in rvex_data_array(NUM_WRITE_PORTS-1 downto 0);

	  
	---------------------------------------------------------------------------
    -- Signals that come out of GPREG Majority voter
    ---------------------------------------------------------------------------
   tmr_writeEnable              : out std_logic_vector(NUM_WRITE_PORTS-1 downto 0);
   tmr_writeAddr                : out rvex_address_array(NUM_WRITE_PORTS-1 downto 0);
   tmr_writeData                : out rvex_data_array(NUM_WRITE_PORTS-1 downto 0)

	  
  );

end entity tmr_gpregvoter1;
	

--=============================================================================
architecture structural of tmr_gpregvoter1 is
--=============================================================================
	
	--add signals here
	signal start										: std_logic := '0';
	signal start_array									: std_logic_vector (0 downto 0) := (others => '0');


	-- internal signals for writeEnable
    signal writeEnable_s              					: std_logic_vector(NUM_WRITE_PORTS-1 downto 0);
    signal writeEnable_temp              				: std_logic_vector(NUM_WRITE_PORTS-1 downto 0);
	signal writeEnable_result_even						: std_logic := '0';
	signal writeEnable_result_odd						: std_logic := '0';

	--internal signals for writeAddr
    signal writeAddr_s                					: rvex_address_array(NUM_WRITE_PORTS-1 downto 0);
    signal writeAddr_temp              					: rvex_address_array(NUM_WRITE_PORTS-1 downto 0);
	signal writeAddr_result_even						: rvex_address_type := (others => '0');
	signal writeAddr_result_odd							: rvex_address_type := (others => '0');

	--signals for writeData
    signal writeData_s                					: rvex_data_array(NUM_WRITE_PORTS-1 downto 0);
    signal writeData_temp                				: rvex_data_array(NUM_WRITE_PORTS-1 downto 0);
	signal writeData_result_even						: rvex_data_type := (others => '0');
	signal writeData_result_odd							: rvex_data_type := (others => '0');

	--test
	signal test_signal									: std_logic_vector (3 downto 0) := (others => '0');



	
--=============================================================================
begin -- architecture
--=============================================================================	
	
	---------------------------------------------------------------------------
    -- Adding Delay before GPREG voter starts after fault tolerance is requested
    ---------------------------------------------------------------------------					

	delay_regsiter: process (clk, start_ft)
	begin
		if rising_edge (clk) then
			if (reset = '1') then
				start_array <= (others => '0');
			else
				start_array(0) <= start_ft;
			end if;
				
		end if;
	end process;
		
	---------------------------------------------------------------------------
    -- Internal signals assignment
    ---------------------------------------------------------------------------					
	activelanes_selection: process(start_array, config_signal, writeEnable, writeAddr, writeData)
		variable index	: integer	:= 0;
	begin
				
		if start_array(0) = '0' then
			
			--signals for writeEnable
			writeEnable_s 				<= writeEnable;
			writeEnable_temp  			<= (others => '0');

			--signals for writeAddr
			writeAddr_s 			<= writeAddr;
			writeAddr_temp  		<= (others => (others => '0'));
			

			--signals for writeData
			writeData_s 			<= writeData;
			writeData_temp  		<= (others => (others => '0'));


			--index to read only TMR lanegroups value in temp
			index := 0;
		else
			writeEnable_s 				<= (others => '0');
			writeEnable_temp  			<= (others => '0');

			--signals for writeAddr
			writeAddr_s 			<= (others => (others => '0'));
			writeAddr_temp  		<= (others => (others => '0'));
			

			--signals for writeData
			writeData_s 			<= (others => (others => '0'));
			writeData_temp  		<= (others => (others => '0'));

		
			for i in 0 to 3 loop
				if config_signal(i) = '1' then
					writeEnable_temp(2*index)		<= writeEnable(2*i);
					writeEnable_temp(2*index+1)		<= writeEnable(2*i+1);

					writeAddr_temp(2*index)			<= writeAddr(2*i);
					writeAddr_temp(2*index+1)		<= writeAddr(2*i+1);

					writeData_temp(2*index)			<= writeData(2*i);
					writeData_temp(2*index+1)		<= writeData(2*i+1);

					index := index + 1;
				end if;
			end loop;
			index	:= 0;
		end if;
	end process;			
					
					
	---------------------------------------------------------------------------
    -- Majority voter bank for writeEnable-even
    ---------------------------------------------------------------------------				
		
		writeEnable_even_voter: entity work.tmr_voter
			port map (
				input_1		=> writeEnable_temp(0),
				--input_1		=> '0',
				input_2		=> writeEnable_temp(2),
				--input_2		=> '0',
				input_3		=> writeEnable_temp(4),
				--input_3		=> '0',
				output		=> writeEnable_result_even
			);

	---------------------------------------------------------------------------
    -- Majority voter bank for writeEnable-odd
    ---------------------------------------------------------------------------				
		
		writeEnable_odd_voter: entity work.tmr_voter
			port map (
				input_1		=> writeEnable_temp(1),
				--input_1		=> '0',
				input_2		=> writeEnable_temp(3),
				--input_2		=> '0',
				input_3		=> writeEnable_temp(5),
				--input_3		=> '0',
				output		=> writeEnable_result_odd
			);

	---------------------------------------------------------------------------
    -- Majority voter bank for writeAddr-even
    ---------------------------------------------------------------------------				
		
	writeAddr_even_voter: for i in 0 to 31 generate
		writeAddr_even_voter_bank: entity work.tmr_voter
			port map (
				input_1		=> writeAddr_temp(0)(i),
				--input_1		=> '0',
				input_2		=> writeAddr_temp(2)(i),
				--input_2		=> '0',
				input_3		=> writeAddr_temp(4)(i),
				--input_3		=> '0',
				output		=> writeAddr_result_even(i)
			);
	end generate;
			
	---------------------------------------------------------------------------
    -- Majority voter bank for writeAddr-odd
    ---------------------------------------------------------------------------				
		
	writeAddr_odd_voter: for i in 0 to 31 generate
		writeAddr_odd_voter_bank: entity work.tmr_voter
			port map (
				input_1		=> writeAddr_temp(1)(i),
				--input_1		=> '0',
				input_2		=> writeAddr_temp(3)(i),
				--input_2		=> '0',
				input_3		=> writeAddr_temp(5)(i),
				--input_3		=> '0',
				output		=> writeAddr_result_odd(i)
			);
	end generate;
			
	---------------------------------------------------------------------------
    -- Majority voter bank for writeData-even
    ---------------------------------------------------------------------------				
		
	writeData_even_voter: for i in 0 to 31 generate
		writeData_even_voter_voter_bank: entity work.tmr_voter
			port map (
				input_1		=> writeData_temp(0)(i),
				--input_1		=> '0',
				input_2		=> writeData_temp(2)(i),
				--input_2		=> '0',
				input_3		=> writeData_temp(4)(i),
				--input_3		=> '0',
				output		=> writeData_result_even(i)
			);
	end generate;

	---------------------------------------------------------------------------
    -- Majority voter bank for writeData-odd
    ---------------------------------------------------------------------------				
		
	writeData_odd_voter_voter: for i in 0 to 31 generate
		writeData_odd_voter_voter_bank: entity work.tmr_voter
			port map (
				input_1		=> writeData_temp(1)(i),
				--input_1		=> '0',
				input_2		=> writeData_temp(3)(i),
				--input_2		=> '0',
				input_3		=> writeData_temp(5)(i),
				--input_3		=> '0',
				output		=> writeData_result_odd(i)
			);
	end generate;
		
			
	---------------------------------------------------------------------------
    -- Recreate values after voter bank
    ---------------------------------------------------------------------------			
		
	addr_result: process (start_array, config_signal, writeEnable,writeEnable_s, writeEnable_result_even, writeEnable_result_odd, writeAddr, 
						  writeAddr_s, writeAddr_result_even, writeAddr_result_odd, writeData, writeData_s, writeData_result_even, writeData_result_odd)	
	variable mask_signal	: std_logic_vector (3 downto 0) := "0001";-- this signal tells which lanegroup will write to gpreg after signals pass through majority voter
	begin
		if start_array(0) = '0' then
			tmr_writeEnable			<=	writeEnable_s;
			tmr_writeAddr			<=	writeAddr_s;
			tmr_writeData			<=	writeData_s;

		else
			tmr_writeEnable			<=	(others => '0');
			tmr_writeAddr			<=	(others => (others => '0'));
			tmr_writeData			<=	(others => (others => '0'));

		
			for i in 0 to 3 loop
				if config_signal(i) = '1' then
					if mask_signal(i) = '1' then
						tmr_writeEnable(2*i)	<=	writeEnable_result_even;
						tmr_writeEnable(2*i+1)	<=	writeEnable_result_odd;
					else
						tmr_writeEnable(2*i)	<=	'0';
						tmr_writeEnable(2*i+1)	<=	'0';
					end if;
					tmr_writeAddr(2*i)		<= writeAddr_result_even;
					tmr_writeAddr(2*i+1)	<= writeAddr_result_odd;

					tmr_writeData(2*i)		<= writeData_result_even;
					tmr_writeData(2*i+1)	<= writeData_result_odd;
				else
					tmr_writeEnable(2*i)	<=	writeEnable(2*i);
					tmr_writeEnable(2*i+1)	<=	writeEnable(2*i+1);

					tmr_writeAddr(2*i)		<= writeAddr(2*i);
					tmr_writeAddr(2*i+1)	<= writeAddr(2*i+1);

					tmr_writeData(2*i)		<= writeData(2*i);
					tmr_writeData(2*i+1)	<= writeData(2*i+1);
				end if;
			end loop;



		end if;
	end process;				
				
						
--		tmr_writeEnable       	<= writeEnable;
--    	tmr_writeAddr     		<= writeAddr;
--    	tmr_writeData    		<= writeData;

						
end structural;
						
						