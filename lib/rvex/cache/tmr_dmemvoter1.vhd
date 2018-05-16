
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.common_pkg.all;
use work.utils_pkg.all;
use work.core_pkg.all;


--=============================================================================
entity tmr_dmemvoter1 is
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
	  
	  
    --rv2dcache_addr              : in  rvex_address_array(2**RCFG.numLaneGroupsLog2-1 downto 0);
    --rv2dcache_readEnable        : in  std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    --rv2dcache_writeData         : in  rvex_data_array(2**RCFG.numLaneGroupsLog2-1 downto 0);
    --rv2dcache_writeMask         : in  rvex_mask_array(2**RCFG.numLaneGroupsLog2-1 downto 0);
    --rv2dcache_writeEnable       : in  std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    --rv2dcache_bypass            : in  std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    --dcache2rv_readData          : out rvex_data_array(2**RCFG.numLaneGroupsLog2-1 downto 0);
    --dcache2rv_busFault          : out std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    --dcache2rv_ifaceFault        : out std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
	  
	    
    ---------------------------------------------------------------------------
    -- Signals that go into DMEM Majority voter
    ---------------------------------------------------------------------------
    -- Data memory addresses from each pipelane group. Note that a section
    -- of the address space 1kiB in size must be mapped to the core control
    -- registers, making that section of the data memory inaccessible.
    -- The start address of this section is configurable with CFG.
    rv2tmr_addr                : in rvex_address_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Active high read enable from each pipelane group. When a bit in this
    -- vector is high, the bit in mem_stallOut is low and the bit in
    -- mem_decouple is high, the data memory must fetch the data at the address
    -- specified by the associated vector in dmem_addr.
    rv2tmr_readEnable          : in std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Write data from the rvex to the DMEM majority voter.
    rv2tmr_writeData           : in rvex_encoded_datacache_data_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Write byte mask from the rvex to the DMEM majority voter, active high.
    rv2tmr_writeMask           : in rvex_mask_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Active write enable from each pipelane group. When a bit in this
    -- vector is high, the bit in mem_stallOut is low and the bit in
    -- mem_decouple is high, the data memory must write the data in
    -- dmem_writeData to the address specified by dmem_addr, respecting the
    -- byte mask specified by dmem_writeMask.
    rv2tmr_writeEnable         : in  std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- (L_MEM clock cycles delay with clkEn high and stallOut low; L_MEM is set
    -- in core_pipeline_pkg.vhd)
    
    -- Data output from data memory to rvex.
    dcache2tmr_readData        : in  rvex_encoded_datacache_data_array(2**CFG.numLaneGroupsLog2-1 downto 0);
	  
    rv2tmr_bypass              : in  std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    dcache2tmr_busFault        : in std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    dcache2tmr_ifaceFault      : in std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
	  
	  
	---------------------------------------------------------------------------
    -- Signals that come out of DMEM Majority voter
    ---------------------------------------------------------------------------
    -- Data memory addresses from each pipelane group. Note that a section
    -- of the address space 1kiB in size must be mapped to the core control
    -- registers, making that section of the data memory inaccessible.
    -- The start address of this section is configurable with CFG.
    tmr2dcache_addr                : out rvex_address_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Active high read enable from each pipelane group. When a bit in this
    -- vector is high, the bit in mem_stallOut is low and the bit in
    -- mem_decouple is high, the data memory must fetch the data at the address
    -- specified by the associated vector in dmem_addr.
    tmr2dcache_readEnable          : out std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Write data from the DMEM majority voter to the data memory.
    tmr2dcache_writeData           : out rvex_encoded_datacache_data_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Write byte mask from the DMEM majority voter to the data memory, active high.
    tmr2dcache_writeMask           : out rvex_mask_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Active write enable from each pipelane group. When a bit in this
    -- vector is high, the bit in mem_stallOut is low and the bit in
    -- mem_decouple is high, the data memory must write the data in
    -- dmem_writeData to the address specified by dmem_addr, respecting the
    -- byte mask specified by dmem_writeMask.
    tmr2dcache_writeEnable         : out std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- (L_MEM clock cycles delay with clkEn high and stallOut low; L_MEM is set
    -- in core_pipeline_pkg.vhd)
    
    -- Data output from data memory to rvex.
    tmr2rv_readData            	  : out  rvex_encoded_datacache_data_array(2**CFG.numLaneGroupsLog2-1 downto 0);
	  
    tmr2dcache_bypass             : out  std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    tmr2rv_busFault               : out std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    tmr2rv_ifaceFault             : out std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0)
    
	  
  );

end entity tmr_dmemvoter1;
	

--=============================================================================
architecture structural of tmr_dmemvoter1 is
--=============================================================================
	
	
	--add signals here
	signal start									: std_logic := '0';
	signal start_array								: std_logic_vector (0 downto 0) := (others => '0');

	-- internal signals for address
	signal rv2tmr_addr_s						: rvex_address_array(2**CFG.numLaneGroupsLog2-1 downto 0);
	signal rv2tmr_addr_temp					: rvex_address_array(2**CFG.numLaneGroupsLog2-1 downto 0);
	signal rv2tmr_addr_s_result				: std_logic_vector (31 downto 0) := (others => '0');


	--internal signals for read enable
	signal rv2tmr_readEnable_s				: std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
	signal rv2tmr_readEnable_temp				: std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
	signal rv2tmr_readEnable_s_result			: std_logic := '0';


	--internal signals for write date
	signal    rv2tmr_writeData_s           	: rvex_encoded_datacache_data_array(2**CFG.numLaneGroupsLog2-1 downto 0);
	signal    rv2tmr_writeData_temp          	: rvex_encoded_datacache_data_array(2**CFG.numLaneGroupsLog2-1 downto 0);
	signal rv2tmr_writeData_s_result			: rvex_encoded_datacache_data_type := (others => '0');

	--internal signals for write mask
	signal	rv2tmr_writeMask_s				: rvex_mask_array(2**CFG.numLaneGroupsLog2-1 downto 0);
	signal	rv2tmr_writeMask_temp				: rvex_mask_array(2**CFG.numLaneGroupsLog2-1 downto 0);
	signal	rv2tmr_writeMask_s_result			: std_logic_vector (3 downto 0) := (others => '0');

	--internal signals for write enable
	signal rv2tmr_writeEnable_s				: std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
	signal rv2tmr_writeEnable_temp			: std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
	signal rv2tmr_writeEnable_s_result		: std_logic := '0';

   --internal signals for rv2tmr_bypass
    signal rv2tmr_bypass_s					: std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
	signal rv2tmr_bypass_temp				: std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    signal rv2tmr_bypass_s_result			: std_logic := '0';
	
--=============================================================================
begin -- architecture
--=============================================================================
		
	
	---------------------------------------------------------------------------
    -- update TMR mode activation signal at rising edge of clock signal
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
    -- internal signals assignment
    ---------------------------------------------------------------------------					
	activelanes_selection: process(start_array, config_signal, rv2tmr_addr, rv2tmr_readEnable, rv2tmr_writeData, rv2tmr_writeMask, rv2tmr_writeEnable, rv2tmr_bypass)
		variable index	: integer	:= 0;
	begin
				
		if start_array(0) = '0' then
			--signals for address
			rv2tmr_addr_s 			<= rv2tmr_addr;
			rv2tmr_addr_temp  		<= (others => (others => '0'));

			--signals for readenable
			rv2tmr_readEnable_s 		<= rv2tmr_readEnable;
			rv2tmr_readEnable_temp 	<=  (others => '0');

			--signals for writedate
			rv2tmr_writeData_s		<= rv2tmr_writeData;
			rv2tmr_writeData_temp		<= (others => (others => '0'));
			
			--signals for writemask
			rv2tmr_writeMask_s		<= rv2tmr_writeMask;
			rv2tmr_writeMask_temp 	<= (others => (others => '0'));

			--signals for writeenable
			rv2tmr_writeEnable_s		<= rv2tmr_writeEnable;
			rv2tmr_writeEnable_temp	<= (others => '0');

			rv2tmr_bypass_s			<= rv2tmr_bypass;
			rv2tmr_bypass_temp		<= (others => '0');
			

			--index to read only active lanegroups value in temp
			index := 0;
		else
			rv2tmr_addr_s 			<= (others => (others => '0'));
			rv2tmr_addr_temp  		<= (others => (others => '0'));

			rv2tmr_readEnable_s 		<= (others => '0');
			rv2tmr_readEnable_temp 	<= (others => '0');		

			rv2tmr_writeData_s		<= (others => (others => '0'));
			rv2tmr_writeData_temp		<= (others => (others => '0'));

			rv2tmr_writeMask_s		<= (others => (others => '0'));
			rv2tmr_writeMask_temp 	<= (others => (others => '0'));

			rv2tmr_writeEnable_s		<= (others => '0');
			rv2tmr_writeEnable_temp	<= (others => '0');

			rv2tmr_bypass_s			<= (others => '0');
			rv2tmr_bypass_temp		<= (others => '0');
		
			for i in 0 to 3 loop
				if config_signal(i) = '1' then
					rv2tmr_addr_temp(index)			<= rv2tmr_addr(i); 
					rv2tmr_readEnable_temp(index)  	<= rv2tmr_readEnable(i);
					rv2tmr_writeData_temp(index)		<= rv2tmr_writeData(i);
					rv2tmr_writeMask_temp(index)		<= rv2tmr_writeMask(i);
					rv2tmr_writeEnable_temp(index)	<= rv2tmr_writeEnable(i);
					rv2tmr_bypass_temp(index)		<= rv2tmr_bypass(i);
					index := index + 1;
				end if;
			end loop;
			index	:= 0;
		end if;
	end process;
					
	---------------------------------------------------------------------------
    -- PC Majority voter bank for DMEM_Address
    ---------------------------------------------------------------------------				
		
	DMEM_Add_voter: for i in 0 to 31 generate
		add_voter_bank: entity work.tmr_voter
			port map (
				input_1		=> rv2tmr_addr_temp(0)(i),
				--input_1		=> '0',
				input_2		=> rv2tmr_addr_temp(1)(i),
				--input_2		=> '0',
				input_3		=> rv2tmr_addr_temp(2)(i),
				--input_3		=> '0',
				output		=> rv2tmr_addr_s_result(i)
			);
	end generate;
	
		
			
	---------------------------------------------------------------------------
    -- PC Majority voter bank for Read Enable
    ---------------------------------------------------------------------------				
		
		Read_Enalbe_voter: entity work.tmr_voter
			port map (
				input_1		=> rv2tmr_readEnable_temp(0),
				--input_1		=> '0',
				input_2		=> rv2tmr_readEnable_temp(1),
				--input_2		=> '0',
				input_3		=> rv2tmr_readEnable_temp(2),
				--input_3		=> '0',
				output		=> rv2tmr_readEnable_s_result
			);
			
	---------------------------------------------------------------------------
    -- PC Majority voter bank for WriteData
    ---------------------------------------------------------------------------				
		
	Write_Data_voter: for i in 0 to 47 generate
		writedata_voter_bank: entity work.tmr_voter
			port map (
				input_1		=> rv2tmr_writeData_temp(0)(i),
				--input_1		=> '0',
				input_2		=> rv2tmr_writeData_temp(1)(i),
				--input_2		=> '0',
				input_3		=> rv2tmr_writeData_temp(2)(i),
				--input_3		=> '0',
				output		=> rv2tmr_writeData_s_result(i)
			);
	end generate;
			
			
			
	---------------------------------------------------------------------------
    -- PC Majority voter bank for WriteMask
    ---------------------------------------------------------------------------				
		
	Write_Mask_voter: for i in 0 to 3 generate
		writemask_voter_bank: entity work.tmr_voter
			port map (
				input_1		=> rv2tmr_writeMask_temp(0)(i),
				--input_1		=> '0',
				input_2		=> rv2tmr_writeMask_temp(1)(i),
				--input_2		=> '0',
				input_3		=> rv2tmr_writeMask_temp(2)(i),
				--input_3		=> '0',
				output		=> rv2tmr_writeMask_s_result(i)
			);
	end generate;

	---------------------------------------------------------------------------
    -- PC Majority voter bank for Write Enable
    ---------------------------------------------------------------------------				
		
		Writer_Enalbe_voter: entity work.tmr_voter
			port map (
				input_1		=> rv2tmr_writeEnable_temp(0),
				--input_1		=> '0',
				input_2		=> rv2tmr_writeEnable_temp(1),
				--input_2		=> '0',
				input_3		=> rv2tmr_writeEnable_temp(2),
				--input_3		=> '0',
				output		=> rv2tmr_writeEnable_s_result
			);
			
	---------------------------------------------------------------------------
    -- PC Majority voter bank for rv2tmr_bypass
    ---------------------------------------------------------------------------				
		
		rv2tmr_bypass_voter: entity work.tmr_voter
			port map (
				input_1		=> rv2tmr_bypass_temp(0),
				--input_1		=> '0',
				input_2		=> rv2tmr_bypass_temp(1),
				--input_2		=> '0',
				input_3		=> rv2tmr_bypass_temp(2),
				--input_3		=> '0',
				output		=> rv2tmr_bypass_s_result
			);
			
	---------------------------------------------------------------------------
    -- Recreate DMEM address value after voter bank
    ---------------------------------------------------------------------------			
		
	addr_result: process (start_array, config_signal, rv2tmr_addr_s, rv2tmr_addr_s_result, rv2tmr_readEnable_s, 
						  	rv2tmr_readEnable_s_result, rv2tmr_writeData_s, rv2tmr_writeData_s_result, 
						  	rv2tmr_writeMask_s, rv2tmr_writeMask_s_result, rv2tmr_writeEnable_s, rv2tmr_writeEnable_s_result, rv2tmr_bypass_s, rv2tmr_bypass_s_result)	
	variable mask_signal	: std_logic_vector (3 downto 0) := "0001";-- this signal tells which lanegroup will write to dmem after signals pass through majority voter
	begin
		if start_array(0) = '0' then
			tmr2dcache_addr				<=	rv2tmr_addr_s;
			tmr2dcache_readEnable 		<= rv2tmr_readEnable_s;
			tmr2dcache_writeData 		<= rv2tmr_writeData_s;
			tmr2dcache_writeMask 		<= rv2tmr_writeMask_s;
			tmr2dcache_writeEnable 		<= rv2tmr_writeEnable_s;
			tmr2dcache_bypass			<= rv2tmr_bypass_s;
		else
			tmr2dcache_addr				<=	(others => (others => '0'));
			tmr2dcache_readEnable		<=	(others => '0');
			tmr2dcache_writeData 		<=	(others => (others => '0'));
			tmr2dcache_writeMask 		<= (others => (others => '0'));
			tmr2dcache_writeEnable 		<= (others => '0');
			tmr2dcache_bypass			<= (others => '0');
		

			for i in 0 to 3 loop
				if config_signal(i) = '0' then
					tmr2dcache_addr(i)			<=	rv2tmr_addr(i);
					tmr2dcache_readEnable(i)	<= rv2tmr_readEnable(i);	
					tmr2dcache_writeData(i)		<= rv2tmr_writeData(i);
					tmr2dcache_writeMask(i) 	<= rv2tmr_writeMask(i);
					tmr2dcache_writeEnable(i) 	<= rv2tmr_writeEnable(i);
					tmr2dcache_bypass(i)		<= rv2tmr_bypass(i);
				else
					if mask_signal(i) = '1' then
						tmr2dcache_addr(i)			<=	rv2tmr_addr_s_result;
						tmr2dcache_readEnable(i)	<= rv2tmr_readEnable_s_result;	
						tmr2dcache_writeData(i)		<= rv2tmr_writeData_s_result;
						tmr2dcache_writeMask(i) 	<= rv2tmr_writeMask_s_result;
						tmr2dcache_writeEnable(i) 	<= rv2tmr_writeEnable_s_result;
						tmr2dcache_bypass(i)		<= rv2tmr_bypass_s_result;
					end if;
				end if;
			end loop;				

				


		end if;
	end process;
			
	---------------------------------------------------------------------------
    -- Replication unit for Data read from DMEM
    ---------------------------------------------------------------------------			

	replicate_read_data: process (start_array, config_signal, dcache2tmr_readData, dcache2tmr_busFault, dcache2tmr_ifaceFault)
	variable mask_signal	: std_logic_vector (3 downto 0) := "0001";-- this signal tells which lanegroup will read from Imem before signals pass through rep unit
		begin
			if (start_array(0) = '0') then
				tmr2rv_readData <= dcache2tmr_readData;
				tmr2rv_busFault <= dcache2tmr_busFault;
				tmr2rv_ifaceFault <= dcache2tmr_ifaceFault;
			else 
					for i in 0 to 3 loop
						if config_signal(i) = '1' then
							for j in 0 to 3 loop
								if mask_signal(j) = '1' then
									tmr2rv_readData (i) <= dcache2tmr_readData(j);
									tmr2rv_busFault (i) <= dcache2tmr_busFault(j);
									tmr2rv_ifaceFault (i) <= dcache2tmr_ifaceFault(j);
								end if;
							end loop;
						else
					    	tmr2rv_readData (i) <= dcache2tmr_readData(i);
							tmr2rv_busFault (i) <= dcache2tmr_busFault(i);
							tmr2rv_ifaceFault (i) <= dcache2tmr_ifaceFault(i);
						end if;
					end loop;
			end if;	
		end process;			
			
			
    --tmr2dcache_addr               <=  rv2tmr_addr;
    --tmr2dcache_readEnable         <=  rv2tmr_readEnable;
    --tmr2dcache_writeData          <=  rv2tmr_writeData;
    --tmr2dcache_writeMask          <=  rv2tmr_writeMask;
    --tmr2dcache_writeEnable        <= rv2tmr_writeEnable;
    --tmr2rv_readData            	  <= dcache2tmr_readData;
    --tmr2dcache_bypass             <= rv2tmr_bypass;
    --tmr2rv_busFault               <= dcache2tmr_busFault;
    --tmr2rv_ifaceFault             <= dcache2tmr_ifaceFault;


end structural;
			








			