
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.common_pkg.all;
use work.utils_pkg.all;
use work.core_pkg.all;


--=============================================================================
entity tmr_dmswvoter is
--=============================================================================
	
  generic (
    
    -- Configuration.
    CFG                         : rvex_generic_config_type 
  );


  port	(
	  
	-- Active high synchronous reset input.
    reset                       : in  std_logic;
    
    -- Clock input, registers are rising edge triggered.
    clk                         : in  std_logic;
    
    -- Active high global clock enable input.
    clkEn                       : in  std_logic := '1';
	  
	--Active high fault tolerance enable  
	start_ft					: in std_logic;
	  
	--signal representing active pipelane groups for fault tolerance mode
	config_signal				: in std_logic_vector (3 downto 0); 
	  
	    
    ---------------------------------------------------------------------------
    -- Signals that go into DMSW Majority voter
    ---------------------------------------------------------------------------
    -- Control register address from memory unit, shared between read and write
    -- command. Only bits 9..0 are used.
    dmsw2tmrvoter_addr              : in  rvex_address_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Control register write command from memory unit.
    dmsw2tmrvoter_writeEnable       : in  std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    dmsw2tmrvoter_writeMask         : in  rvex_mask_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    dmsw2tmrvoter_writeData         : in  rvex_data_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Control register read command and result from and to memory unit.
    dmsw2tmrvoter_readEnable        : in  std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    creg2tmrvoter_readData          : in rvex_data_array(2**CFG.numLaneGroupsLog2-1 downto 0);
	  
	  
	---------------------------------------------------------------------------
    -- Signals that come out of DMSW Majority voter
    ---------------------------------------------------------------------------
    -- Control register address from memory unit, shared between read and write
    -- command. Only bits 9..0 are used.
    tmrvoter2creg_addr              : out  rvex_address_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Control register write command from memory unit.
    tmrvoter2creg_writeEnable       : out  std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    tmrvoter2creg_writeMask         : out  rvex_mask_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    tmrvoter2creg_writeData         : out  rvex_data_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Control register read command and result from and to memory unit.
    tmrvoter2creg_readEnable        : out  std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    tmrvoter2dmsw_readData          : out rvex_data_array(2**CFG.numLaneGroupsLog2-1 downto 0)
    
	  
  );

end entity tmr_dmswvoter;
	

--=============================================================================
architecture structural of tmr_dmswvoter is
--=============================================================================
	
	
	--add signals here
	signal start									: std_logic := '0';
	signal start_array								: std_logic_vector (0 downto 0) := (others => '0');

	-- internal signals for address

	signal dmsw2tmrvoter_addr_s						: rvex_address_array(2**CFG.numLaneGroupsLog2-1 downto 0);
	signal dmsw2tmrvoter_addr_temp					: rvex_address_array(2**CFG.numLaneGroupsLog2-1 downto 0);
	signal dmsw2tmrvoter_addr_s_result				: std_logic_vector (31 downto 0) := (others => '0');

	--internal signals for write enable
	signal dmsw2tmrvoter_writeEnable_s				: std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
	signal dmsw2tmrvoter_writeEnable_temp			: std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
	signal dmsw2tmrvoter_writeEnable_s_result		: std_logic := '0';

	--internal signals for write mask
	signal dmsw2tmrvoter_writeMask_s				: rvex_mask_array(2**CFG.numLaneGroupsLog2-1 downto 0);
	signal dmsw2tmrvoter_writeMask_temp				: rvex_mask_array(2**CFG.numLaneGroupsLog2-1 downto 0);
	signal dmsw2tmrvoter_writeMask_s_result			: std_logic_vector (3 downto 0) := (others => '0');

	--internal signals for write data
	signal dmsw2tmrvoter_writeData_s				: rvex_data_array(2**CFG.numLaneGroupsLog2-1 downto 0);
	signal dmsw2tmrvoter_writeData_temp				: rvex_data_array(2**CFG.numLaneGroupsLog2-1 downto 0);
	signal dmsw2tmrvoter_writeData_s_result			: std_logic_vector (31 downto 0) := (others => '0');
		
	--internal signals for read enable
	signal dmsw2tmrvoter_readEnable_s				: std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
	signal dmsw2tmrvoter_readEnable_temp			: std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
	signal dmsw2tmrvoter_readEnable_s_result		: std_logic := '0';
		
	--internal signals for read data
	signal creg2tmrvoter_readData_s					: rvex_data_array(2**CFG.numLaneGroupsLog2-1 downto 0);
	signal creg2tmrvoter_readData_temp				: rvex_data_array(2**CFG.numLaneGroupsLog2-1 downto 0);
	signal creg2tmrvoter_readData_s_result			: std_logic_vector(31 downto 0) := (others => '0');
		



	
--=============================================================================
begin -- architecture
--=============================================================================
		
				
	---------------------------------------------------------------------------
    -- Adding Delay before DMSW voter starts after fault tolerance is requested
    ---------------------------------------------------------------------------					
			
	delay_regsiter: process (clk, start_ft)
	begin
		if rising_edge (clk) then
			if (reset = '1') then
				start_array(0) <= '0';
			else
  		        start_array(0) <= start_ft;
			end if;

		end if;
	end process;
		

	---------------------------------------------------------------------------
    -- Internal signals assignment
    ---------------------------------------------------------------------------					
	activelanes_selection: process(start_array, config_signal, dmsw2tmrvoter_addr, dmsw2tmrvoter_writeEnable, dmsw2tmrvoter_writeMask, 
								   dmsw2tmrvoter_writeData, dmsw2tmrvoter_readEnable, creg2tmrvoter_readData)
		variable index	: integer	:= 0;
	begin
			
		if start_array(0) = '0' then
			--signals for address
			dmsw2tmrvoter_addr_s 			<= dmsw2tmrvoter_addr;
			dmsw2tmrvoter_addr_temp  		<= (others => (others => '0'));

			--signals for writeenable
			dmsw2tmrvoter_writeEnable_s		<= dmsw2tmrvoter_writeEnable;
			dmsw2tmrvoter_writeEnable_temp	<= (others => '0');		

			--signals for writemask
			dmsw2tmrvoter_writeMask_s		<= dmsw2tmrvoter_writeMask;
			dmsw2tmrvoter_writeMask_temp 	<= (others => (others => '0'));

			--signals for writedate
			dmsw2tmrvoter_writeData_s		<= dmsw2tmrvoter_writeData;
			dmsw2tmrvoter_writeData_temp	<= (others => (others => '0'));

			--signals for readenable
			dmsw2tmrvoter_readEnable_s 		<= dmsw2tmrvoter_readEnable;
			dmsw2tmrvoter_readEnable_temp 	<=  (others => '0');

			--signals for readData
			creg2tmrvoter_readData_s		<= creg2tmrvoter_readData;
			creg2tmrvoter_readData_temp		<= (others => (others => '0'));
				


			--index to read only active lanegroups value in temp
			index := 0;
		else
			dmsw2tmrvoter_addr_s 			<= (others => (others => '0'));
			dmsw2tmrvoter_addr_temp  		<= (others => (others => '0'));

			dmsw2tmrvoter_readEnable_s 		<= (others => '0');
			dmsw2tmrvoter_readEnable_temp 	<= (others => '0');		

			dmsw2tmrvoter_writeData_s		<= (others => (others => '0'));
			dmsw2tmrvoter_writeData_temp	<= (others => (others => '0'));

			dmsw2tmrvoter_writeMask_s		<= (others => (others => '0'));
			dmsw2tmrvoter_writeMask_temp 	<= (others => (others => '0'));

			dmsw2tmrvoter_writeEnable_s		<= (others => '0');
			dmsw2tmrvoter_writeEnable_temp	<= (others => '0');

			creg2tmrvoter_readData_s		<= (others => (others => '0'));
			creg2tmrvoter_readData_temp		<= (others => (others => '0'));
		
			for i in 0 to 3 loop
				if config_signal(i) = '1' then
					dmsw2tmrvoter_addr_temp(index)			<= dmsw2tmrvoter_addr(i); 
					dmsw2tmrvoter_readEnable_temp(index)  	<= dmsw2tmrvoter_readEnable(i);
					dmsw2tmrvoter_writeData_temp(index)		<= dmsw2tmrvoter_writeData(i);
					dmsw2tmrvoter_writeMask_temp(index)		<= dmsw2tmrvoter_writeMask(i);
					dmsw2tmrvoter_writeEnable_temp(index)	<= dmsw2tmrvoter_writeEnable(i);
					creg2tmrvoter_readData_temp(index)		<= creg2tmrvoter_readData(i);
					index := index + 1;
				end if;
			end loop;
			index	:= 0;
		end if;
	end process;
					
	---------------------------------------------------------------------------
    -- PC Majority voter bank for DMSW_Address
    ---------------------------------------------------------------------------				
		
	DMSW_Add_voter: for i in 0 to 31 generate
		add_voter_bank: entity work.tmr_voter
			port map (
				input_1		=> dmsw2tmrvoter_addr_temp(0)(i),
				--input_1		=> '0',
				input_2		=> dmsw2tmrvoter_addr_temp(1)(i),
				--input_2		=> '0',
				input_3		=> dmsw2tmrvoter_addr_temp(2)(i),
				--input_3		=> '0',
				output		=> dmsw2tmrvoter_addr_s_result(i)
			);
	end generate;
	
		
			
	---------------------------------------------------------------------------
    -- PC Majority voter bank for Read Enable
    ---------------------------------------------------------------------------				
		
		Read_Enalbe_voter: entity work.tmr_voter
			port map (
				input_1		=> dmsw2tmrvoter_readEnable_temp(0),
				--input_1		=> '0',
				input_2		=> dmsw2tmrvoter_readEnable_temp(1),
				--input_2		=> '0',
				input_3		=> dmsw2tmrvoter_readEnable_temp(2),
				--input_3		=> '0',
				output		=> dmsw2tmrvoter_readEnable_s_result
			);
			
	---------------------------------------------------------------------------
    -- PC Majority voter bank for WriteData
    ---------------------------------------------------------------------------				
		
	Write_Data_voter: for i in 0 to 31 generate
		writedata_voter_bank: entity work.tmr_voter
			port map (
				input_1		=> dmsw2tmrvoter_writeData_temp(0)(i),
				--input_1		=> '0',
				input_2		=> dmsw2tmrvoter_writeData_temp(1)(i),
				--input_2		=> '0',
				input_3		=> dmsw2tmrvoter_writeData_temp(2)(i),
				--input_3		=> '0',
				output		=> dmsw2tmrvoter_writeData_s_result(i)
			);
	end generate;
			
			
			
	---------------------------------------------------------------------------
    -- PC Majority voter bank for WriteMask
    ---------------------------------------------------------------------------				
		
	Write_Mask_voter: for i in 0 to 3 generate
		writemask_voter_bank: entity work.tmr_voter
			port map (
				input_1		=> dmsw2tmrvoter_writeMask_temp(0)(i),
				--input_1		=> '0',
				input_2		=> dmsw2tmrvoter_writeMask_temp(1)(i),
				--input_2		=> '0',
				input_3		=> dmsw2tmrvoter_writeMask_temp(2)(i),
				--input_3		=> '0',
				output		=> dmsw2tmrvoter_writeMask_s_result(i)
			);
	end generate;

	---------------------------------------------------------------------------
    -- PC Majority voter bank for Write Enable
    ---------------------------------------------------------------------------				
		
		Writer_Enalbe_voter: entity work.tmr_voter
			port map (
				input_1		=> dmsw2tmrvoter_writeEnable_temp(0),
				--input_1		=> '0',
				input_2		=> dmsw2tmrvoter_writeEnable_temp(1),
				--input_2		=> '0',
				input_3		=> dmsw2tmrvoter_writeEnable_temp(2),
				--input_3		=> '0',
				output		=> dmsw2tmrvoter_writeEnable_s_result
			);

	---------------------------------------------------------------------------
    -- PC Majority voter bank for ReadData
    ---------------------------------------------------------------------------				
		
	Read_Data_voter: for i in 0 to 31 generate
		readdata_voter_bank: entity work.tmr_voter
			port map (
				input_1		=> creg2tmrvoter_readData_temp(0)(i),
				--input_1		=> '0',
				input_2		=> creg2tmrvoter_readData_temp(1)(i),
				--input_2		=> '0',
				input_3		=> creg2tmrvoter_readData_temp(2)(i),
				--input_3		=> '0',
				output		=> creg2tmrvoter_readData_s_result(i)
			);
	end generate;
			
			
	---------------------------------------------------------------------------
    -- Recreate DMEM address value after voter bank
    ---------------------------------------------------------------------------			
		
	addr_result: process (start_array, config_signal, dmsw2tmrvoter_addr_s, dmsw2tmrvoter_addr_s_result, dmsw2tmrvoter_readEnable_s, 
						  	dmsw2tmrvoter_readEnable_s_result, dmsw2tmrvoter_writeData_s, dmsw2tmrvoter_writeData_s_result, 
						  	dmsw2tmrvoter_writeMask_s, dmsw2tmrvoter_writeMask_s_result, dmsw2tmrvoter_writeEnable_s, dmsw2tmrvoter_writeEnable_s_result,
						 	creg2tmrvoter_readData_s, creg2tmrvoter_readData_s_result)	
	begin
		if start_array(0) = '0' then
			tmrvoter2creg_addr				<=	dmsw2tmrvoter_addr_s;
			tmrvoter2creg_readEnable 		<= dmsw2tmrvoter_readEnable_s;
			tmrvoter2creg_writeData 		<= dmsw2tmrvoter_writeData_s;
			tmrvoter2creg_writeMask 		<= dmsw2tmrvoter_writeMask_s;
			tmrvoter2creg_writeEnable 		<= dmsw2tmrvoter_writeEnable_s;
			tmrvoter2dmsw_readData			<= creg2tmrvoter_readData_s;
		else
			tmrvoter2creg_addr				<=	(others => (others => '0'));
			tmrvoter2creg_readEnable		<=	(others => '0');
			tmrvoter2creg_writeData 		<=	(others => (others => '0'));
			tmrvoter2creg_writeMask 		<= (others => (others => '0'));
			tmrvoter2creg_writeEnable 		<= (others => '0');
			tmrvoter2dmsw_readData			<= (others => (others => '0'));
		
			for i in 0 to 3 loop
				if config_signal(i) = '1' then
					tmrvoter2creg_addr(i)			<=	dmsw2tmrvoter_addr_s_result;
				
					--assert (dmsw2tmrvoter_addr(i) = dmsw2tmrvoter_addr_s_result)
					--assert (dmsw2tmrvoter_addr(i) = X"00000000")
					--		report "dmsw2tmrvoter_addr voter failed" severity note;
					tmrvoter2creg_readEnable(i)		<= dmsw2tmrvoter_readEnable_s_result;
					tmrvoter2creg_writeData(i)		<= dmsw2tmrvoter_writeData_s_result;
					tmrvoter2creg_writeMask(i) 		<= dmsw2tmrvoter_writeMask_s_result;
					tmrvoter2creg_writeEnable(i) 	<= dmsw2tmrvoter_writeEnable_s_result;
					tmrvoter2dmsw_readData(i)		<= creg2tmrvoter_readData_s_result;
				else
					tmrvoter2creg_addr(i)			<=	dmsw2tmrvoter_addr(i);
					tmrvoter2creg_readEnable(i)		<= dmsw2tmrvoter_readEnable(i);
					tmrvoter2creg_writeData(i)		<= dmsw2tmrvoter_writeData(i);
					tmrvoter2creg_writeMask(i) 		<= dmsw2tmrvoter_writeMask(i);
					tmrvoter2creg_writeEnable(i) 	<= dmsw2tmrvoter_writeEnable(i);
					tmrvoter2dmsw_readData(i)		<= creg2tmrvoter_readData(i);					
				end if;
			end loop;				
					
					
		--assert (dmsw2tmrvoter_writeEnable(0) = dmsw2tmrvoter_writeEnable_s_result)
		--		report "dmsw2tmrvoter_writeEnable voter failed" severity note;
		--assert (dmsw2tmrvoter_writeMask(0) = dmsw2tmrvoter_writeMask_s_result)
		--		report "dmsw2tmrvoter_writeMask voter failed" severity note;
		--assert (dmsw2tmrvoter_writeData(0) = dmsw2tmrvoter_writeData_s_result)
		--		report "dmsw2tmrvoter_writeData voter failed" severity note;
		--assert (dmsw2tmrvoter_readEnable(0) = dmsw2tmrvoter_readEnable_s_result)
		--		report "dmsw2tmrvoter_readEnable voter failed" severity note;
		--assert (creg2tmrvoter_readData(0) = creg2tmrvoter_readData_s_result)
		--		report "creg2tmrvoter_readData voter failed" severity note;

		end if;
	end process;
			
		
			
			
--    tmrvoter2creg_addr              <= dmsw2tmrvoter_addr;
--    tmrvoter2creg_writeEnable       <= dmsw2tmrvoter_writeEnable;
--    tmrvoter2creg_writeMask         <= dmsw2tmrvoter_writeMask;
--    tmrvoter2creg_writeData         <= dmsw2tmrvoter_writeData;
--    tmrvoter2creg_readEnable        <= dmsw2tmrvoter_readEnable;
--    tmrvoter2dmsw_readData          <= creg2tmrvoter_readData;




end structural;
			