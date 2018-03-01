library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.common_pkg.all;
use work.utils_pkg.all;
use work.core_pkg.all;
use work.core_intIface_pkg.all;
--use work.core_trap_pkg.all;
--use work.core_pipeline_pkg.all;
--use work.core_ctrlRegs_pkg.all;


--=============================================================================
entity tmr_gpregvoter is
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
    -- Signals that go into GPREG Majority voter
    ---------------------------------------------------------------------------
    -- Read ports. There's two for each lane. The read value is provided for all
    -- lanes which receive forwarding information.
    pl2tmrvoter_readPorts          	  : in  pl2gpreg_readPort_array(2*2**CFG.numLanesLog2-1 downto 0);
    gpreg2tmrvoter_readPorts          : in gpreg2pl_readPort_array(2*2**CFG.numLanesLog2-1 downto 0);
    
    -- Write ports and forwarding information. There's one write port for each
    -- lane.
    pl2tmrvoter_writePorts            : in  pl2gpreg_writePort_array(2**CFG.numLanesLog2-1 downto 0);
	  
	---------------------------------------------------------------------------
    -- Signals that come out of GPREG Majority voter
    ---------------------------------------------------------------------------
    -- Read ports. There's two for each lane. The read value is provided for all
    -- lanes which receive forwarding information.
    tmrvoter2gpreg_readPorts          : out  pl2gpreg_readPort_array(2*2**CFG.numLanesLog2-1 downto 0);
    tmrvoter2pl_readPorts             : out gpreg2pl_readPort_array(2*2**CFG.numLanesLog2-1 downto 0);
    
    -- Write ports and forwarding information. There's one write port for each
    -- lane.
    tmrvoter2gpreg_writePorts         : out  pl2gpreg_writePort_array(2**CFG.numLanesLog2-1 downto 0)
	  
  );

end entity tmr_gpregvoter;
	

--=============================================================================
architecture structural of tmr_gpregvoter is
--=============================================================================
	
	--add signals here
	signal start									: std_logic := '0';
	signal start_array								: std_logic_vector (2 downto 0) := (others => '0');

	-- internal signals for address
	signal pl2tmrvoter_writePorts_s						: pl2gpreg_writePort_array(2**CFG.numLanesLog2-1 downto 0);
	signal pl2tmrvoter_writePorts_temp					: pl2gpreg_writePort_array(2**CFG.numLanesLog2-1 downto 0);
	signal pl2tmrvoter_writePorts_s_result_even				: pl2gpreg_writePort_type ; --need to assign initial zero values
	signal pl2tmrvoter_writePorts_s_result_odd				: pl2gpreg_writePort_type ; -- // // //


	
--=============================================================================
begin -- architecture
--=============================================================================		
			
	
	
	---------------------------------------------------------------------------
    -- Adding Delay before DMEM voter starts after fault tolerance is requested
    ---------------------------------------------------------------------------					
			
	delay_regsiter: process (clk, start_ft)
	begin
		if rising_edge (clk) then
			if (reset = '1') then
				start_array(2) <= '0';
			else
				start_array(2) <= start_ft;
			end if;
				
			  --start_array (4) <= start_array (5);
			  --start_array (3) <= start_array(4);
			  --start_array (2) <= start_array (3);
			  start_array (1) <= start_array(2);
			  start_array (0) <= start_array(1);

		end if;
	end process;
		
	
	
	---------------------------------------------------------------------------
    -- Internal signals assignment
    ---------------------------------------------------------------------------					
--	activelanes_selection: process(start_array, config_signal, pl2tmrvoter_writePorts)
--		variable index	: integer	:= 0;
--	begin
				
--		if start_array(0) = '0' then

--			pl2tmrvoter_writePorts_s(i) 				<= pl2tmrvoter_writePorts(i);
		
--			pl2tmrvoter_writePorts_temp.addr  			<= (others => '0');
--			pl2tmrvoter_writePorts_temp.data  			<= (others => (others => '0'));
--			pl2tmrvoter_writePorts_temp.writeEnable  	<= (others => (others => '0'));
--			pl2tmrvoter_writePorts_temp.forwardEnable  	<= (others => (others => '0'));

			--index to read only active lanes values in temp
--			index := 0;
--		else
--			pl2tmrvoter_writePorts_s.addr  				<= (others => (others => '0'));
--			pl2tmrvoter_writePorts_s.data  				<= (others => (others => '0'));
--			pl2tmrvoter_writePorts_s.writeEnable  		<= (others => (others => '0'));
--			pl2tmrvoter_writePorts_s.forwardEnable  	<= (others => (others => '0'));
--
--			pl2tmrvoter_writePorts_temp.addr  			<= (others => (others => '0'));
--			pl2tmrvoter_writePorts_temp.data  			<= (others => (others => '0'));
--			pl2tmrvoter_writePorts_temp.writeEnable  	<= (others => (others => '0'));
--			pl2tmrvoter_writePorts_temp.forwardEnable  	<= (others => (others => '0'));


		
--			for i in 0 to 3 loop
--				if config_signal(i) = '1' then
--				
--					pl2tmrvoter_writePorts_temp(index).addr  			<= pl2tmrvoter_writePorts(2*i).addr; 
--					pl2tmrvoter_writePorts_temp(index).data  			<= pl2tmrvoter_writePorts(2*i).data; 
--					pl2tmrvoter_writePorts_temp(index).writeEnable  	<= pl2tmrvoter_writePorts(2*i).writeEnable; 
--					pl2tmrvoter_writePorts_temp(index).forwardEnable  	<= pl2tmrvoter_writePorts(2*i).forwardEnable; 
				
--					pl2tmrvoter_writePorts_temp(index+1).addr  			<= pl2tmrvoter_writePorts(2*i+1).addr; 
--					pl2tmrvoter_writePorts_temp(index+1).data  			<= pl2tmrvoter_writePorts(2*i+1).data; 
--					pl2tmrvoter_writePorts_temp(index+1).writeEnable  	<= pl2tmrvoter_writePorts(2*i+1).writeEnable; 
--					pl2tmrvoter_writePorts_temp(index+1).forwardEnable  <= pl2tmrvoter_writePorts(2*i+1).forwardEnable; 

--					index := index + 1;
--				end if;
--			end loop;
--			index	:= 0;
--		end if;
--	end process;
					
	---------------------------------------------------------------------------
    -- PC Majority voter bank for addr-even
    ---------------------------------------------------------------------------				
		
--	WriteAddr_even_voter: for i in 0 to 5 generate
--		addr_even_voter_bank: entity work.tmr_voter
--			port map (
--				input_1		=> pl2tmrvoter_writePorts_temp(0).addr(i),
--				--input_1		=> '0',
--				input_2		=> pl2tmrvoter_writePorts_temp(2).addr(i),
--				--input_2		=> '0',
--				input_3		=> pl2tmrvoter_writePorts_temp(4).addr(i),
--				--input_3		=> '0',
--				output		=> pl2tmrvoter_writePorts_s_result_even.addr(i)
--			);
--	end generate;
	
	---------------------------------------------------------------------------
    -- PC Majority voter bank for addr-odd
    ---------------------------------------------------------------------------				
		
--	WriteAddr_odd_voter: for i in 0 to 5 generate
--		addr_odd_voter_bank: entity work.tmr_voter
--			port map (
--				input_1		=> pl2tmrvoter_writePorts_temp(1).addr(i),
--				--input_1		=> '0',
--				input_2		=> pl2tmrvoter_writePorts_temp(3).addr(i),
--				--input_2		=> '0',
--				input_3		=> pl2tmrvoter_writePorts_temp(5).addr(i),
--				--input_3		=> '0',
--				output		=> pl2tmrvoter_writePorts_s_result_odd.addr(i)
--			);
--	end generate;

--			pl2tmrvoter_writePorts_s_result_even.addr <= pl2tmrvoter_writePorts(0).addr;
--			pl2tmrvoter_writePorts_s_result_odd.addr  <= pl2tmrvoter_writePorts(1).addr;				
			
			
	---------------------------------------------------------------------------
    -- PC Majority voter bank for data-even
    ---------------------------------------------------------------------------				
		
--	WriteData_even_voter: for i in 0 to 31 generate
--		data_even_voter_bank: entity work.tmr_voter
--			port map (
--				input_1		=> pl2tmrvoter_writePorts_temp(0).data(i),
--				--input_1		=> '0',
--				input_2		=> pl2tmrvoter_writePorts_temp(2).data(i),
--				--input_2		=> '0',
--				input_3		=> pl2tmrvoter_writePorts_temp(4).data(i),
--				--input_3		=> '0',
--				output		=> pl2tmrvoter_writePorts_s_result_even.data(i)
--			);
--	end generate;
	
	---------------------------------------------------------------------------
    -- PC Majority voter bank for data-odd
    ---------------------------------------------------------------------------				
		
--	WriteData_odd_voter: for i in 0 to 31 generate
--		data_odd_voter_bank: entity work.tmr_voter
--			port map (
--				input_1		=> pl2tmrvoter_writePorts_temp(1).data(i),
--				--input_1		=> '0',
--				input_2		=> pl2tmrvoter_writePorts_temp(3).data(i),
--				--input_2		=> '0',
--				input_3		=> pl2tmrvoter_writePorts_temp(5).data(i),
--				--input_3		=> '0',
--				output		=> pl2tmrvoter_writePorts_s_result_odd.data(i)
--			);
--	end generate;

--			pl2tmrvoter_writePorts_s_result_even.data <= pl2tmrvoter_writePorts(0).data;
--			pl2tmrvoter_writePorts_s_result_odd.data  <= pl2tmrvoter_writePorts(1).data;			
			
	---------------------------------------------------------------------------
    -- PC Majority voter bank for writeEnable-even
    ---------------------------------------------------------------------------				
		
--		WriteEnable_even_voter_bank: entity work.tmr_voter
--			port map (
--				input_1		=> pl2tmrvoter_writePorts_temp(0).writeEnable,
--				--input_1		=> '0',
--				input_2		=> pl2tmrvoter_writePorts_temp(2).writeEnable,
--				--input_2		=> '0',
--				input_3		=> pl2tmrvoter_writePorts_temp(4).writeEnable,
--				--input_3		=> '0',
--				output		=> pl2tmrvoter_writePorts_s_result_even.writeEnable
--			);
	
	---------------------------------------------------------------------------
    -- PC Majority voter bank for writeEnable-odd
    ---------------------------------------------------------------------------				
		
--		WriteEnable_odd_voter_bank: entity work.tmr_voter
--			port map (
--				input_1		=> pl2tmrvoter_writePorts_temp(1).writeEnable,
--				--input_1		=> '0',
--				input_2		=> pl2tmrvoter_writePorts_temp(3).writeEnable,
--				--input_2		=> '0',
--				input_3		=> pl2tmrvoter_writePorts_temp(5).writeEnable,
--				--input_3		=> '0',
--				output		=> pl2tmrvoter_writePorts_s_result_odd.writeEnable
--			);
	
--			pl2tmrvoter_writePorts_s_result_even.writeEnable <= pl2tmrvoter_writePorts(0).writeEnable;
--			pl2tmrvoter_writePorts_s_result_odd.writeEnable  <= pl2tmrvoter_writePorts(1).writeEnable;
			
	---------------------------------------------------------------------------
    -- PC Majority voter bank for forwardEnable-even
    ---------------------------------------------------------------------------				
		
--	ForwardEnable_voter: for i in 0 to 31 generate
--		forwardenalbe_bank: entity work.tmr_voter
--			port map (
--				input_1		=> rv2dmemvoter_addr_temp(0)(i),
--				--input_1		=> '0',
--				input_2		=> rv2dmemvoter_addr_temp(1)(i),
--				--input_2		=> '0',
--				input_3		=> rv2dmemvoter_addr_temp(2)(i),
--				--input_3		=> '0',
--				output		=> rv2dmemvoter_addr_s_result(i)
--			);
--	end generate;
	
	---------------------------------------------------------------------------
    -- PC Majority voter bank for forwardEnable-odd
    ---------------------------------------------------------------------------				
		
--	ForwardEnable_voter: for i in 0 to 31 generate
--		forwardenalbe_bank: entity work.tmr_voter
--			port map (
--				input_1		=> rv2dmemvoter_addr_temp(0)(i),
--				--input_1		=> '0',
--				input_2		=> rv2dmemvoter_addr_temp(1)(i),
--				--input_2		=> '0',
--				input_3		=> rv2dmemvoter_addr_temp(2)(i),
--				--input_3		=> '0',
--				output		=> rv2dmemvoter_addr_s_result(i)
--			);
--	end generate;
	
--			pl2tmrvoter_writePorts_s_result_even.forwardEnable <= pl2tmrvoter_writePorts(0).forwardEnable;
--			pl2tmrvoter_writePorts_s_result_odd.forwardEnable  <= pl2tmrvoter_writePorts(1).forwardEnable;
								
	
	---------------------------------------------------------------------------
    -- Recreate DMEM address value after voter bank
    ---------------------------------------------------------------------------			
		
--	addr_result: process (start_array, config_signal, pl2tmrvoter_writePorts_s, pl2tmrvoter_writePorts_s_result_even, pl2tmrvoter_writePorts_s_result_odd)	
--	begin
--		if start_array(0) = '0' then
--			tmrvoter2gpreg_writePorts					<=	pl2tmrvoter_writePorts_s;

--		else

--			tmrvoter2gpreg_writePorts.addr  			<= (others => (others => '0'));
--			tmrvoter2gpreg_writePorts.data  			<= (others => (others => '0'));
--			tmrvoter2gpreg_writePorts.writeEnable  		<= (others => (others => '0'));
--			tmrvoter2gpreg_writePorts.forwardEnable  	<= (others => (others => '0'));
		
		
		--	for i in 0 to 3 loop
		--		if config_signal(i) = '1' then
		--		tmrvoter2gpreg_writePorts(i)			<=	pl2tmrvoter_writePorts_s_result;

		--		end if;
		
		--	end loop;

				

--		tmrvoter2gpreg_writePorts(0).addr				<=	pl2tmrvoter_writePorts_s_result_even.addr;
--		tmrvoter2gpreg_writePorts(0).data				<=	pl2tmrvoter_writePorts_s_result_even.data;
--		tmrvoter2gpreg_writePorts(0).writeEnable		<=	pl2tmrvoter_writePorts_s_result_even.writeEnable;
--		tmrvoter2gpreg_writePorts(0).forwardEnable		<=	pl2tmrvoter_writePorts_s_result_even.forwardEnable;

--		tmrvoter2gpreg_writePorts(1).addr				<=	pl2tmrvoter_writePorts_s_result_odd.addr;
--		tmrvoter2gpreg_writePorts(1).data				<=	pl2tmrvoter_writePorts_s_result_odd.data;
--		tmrvoter2gpreg_writePorts(1).writeEnable		<=	pl2tmrvoter_writePorts_s_result_odd.writeEnable;
--		tmrvoter2gpreg_writePorts(1).forwardEnable		<=	pl2tmrvoter_writePorts_s_result_odd.forwardEnable;



--		end if;
--	end process;
	
	
	
	
	
	tmrvoter2gpreg_readPorts		<= pl2tmrvoter_readPorts;
	tmrvoter2pl_readPorts			<= gpreg2tmrvoter_readPorts;
	tmrvoter2gpreg_writePorts		<= pl2tmrvoter_writePorts;


end structural;
			

