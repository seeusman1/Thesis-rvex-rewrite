library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.common_pkg.all;
use work.utils_pkg.all;
use work.core_pkg.all;
use work.core_intIface_pkg.all;
--use work.core_trap_pkg.all;
use work.core_pipeline_pkg.all;
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
    tmrvoter2gpreg_writePorts         : out  pl2gpreg_writePort_array(2**CFG.numLanesLog2-1 downto 0);
	  
	test_signal						  : out std_logic_vector (3 downto 0) --testing--just to observe signal in simulation
	  
  );

end entity tmr_gpregvoter;
	

--=============================================================================
architecture structural of tmr_gpregvoter is
--=============================================================================
	
	constant zero_init									: pl2gpreg_writePort_type := ( addr => (others => (others => '0')),
														   							   data => (others => (others => '0')),
														   							   writeEnable => (others => '0'),
														   							   forwardEnable => (others => '0')
														  							 );
	
	--add signals here
	signal start										: std_logic := '0';
	signal start_array									: std_logic_vector (16 downto 0) := (others => '0');

	-- internal signals for address
	signal pl2tmrvoter_writePorts_s						: pl2gpreg_writePort_array(2**CFG.numLanesLog2-1 downto 0);
	signal pl2tmrvoter_writePorts_temp					: pl2gpreg_writePort_array(2**CFG.numLanesLog2-1 downto 0);

	signal pl2tmrvoter_writePorts_s_result_even			: pl2gpreg_writePort_type := zero_init; 
	signal pl2tmrvoter_writePorts_s_result_odd			: pl2gpreg_writePort_type := zero_init; 

--	signal d											: std_logic_vector (15 downto 0) := (others => '0');
--	signal r											: std_logic_vector (16 downto 0) := (others => '0');
	
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
				start_array(16) <= start_ft;
			    start_array (15 downto 0) <= start_array (16 downto 1);
			end if;
				
		end if;
		

		
--	shift: process (r)
--	begin
--		for i in 0 to 15 loop
--			d(i) <= r(i+1);
--		end loop;
--	end process;

--	delay: process(clk, start_ft) is
--	begin
--		if rising_edge (clk) then
--			r(16) <= start_ft;		
--			for i in 1 to 15 loop
--				r(i) <= d(i);
--			end loop;
--			start_array(0) <= d(0);
--		end if;
			
			
			
	end process;
			

	test_signal <= start_array (3 downto 0); --testing--just to observe signal in simulation
	
	---------------------------------------------------------------------------
    -- Internal signals assignment
    ---------------------------------------------------------------------------					
	activelanes_selection: process(start_array, config_signal, pl2tmrvoter_writePorts)
		variable index	: integer	:= 0;
	begin
				
		if start_array(0) = '0' then

			pl2tmrvoter_writePorts_s 				<= pl2tmrvoter_writePorts;
			pl2tmrvoter_writePorts_temp 			<= (others => zero_init);		

			--index to read only active lanes values in temp
			index := 0;
		else
			
			pl2tmrvoter_writePorts_s 				<= (others => zero_init);			
			pl2tmrvoter_writePorts_temp 			<= (others => zero_init);

			for i in 0 to 3 loop
				if config_signal(i) = '1' then
				
					pl2tmrvoter_writePorts_temp(2*index).addr  				<= pl2tmrvoter_writePorts(2*i).addr; 
					pl2tmrvoter_writePorts_temp(2*index).data  				<= pl2tmrvoter_writePorts(2*i).data; 
					pl2tmrvoter_writePorts_temp(2*index).writeEnable  		<= pl2tmrvoter_writePorts(2*i).writeEnable; 
					pl2tmrvoter_writePorts_temp(2*index).forwardEnable  	<= pl2tmrvoter_writePorts(2*i).forwardEnable; 
				
					pl2tmrvoter_writePorts_temp(2*index+1).addr  			<= pl2tmrvoter_writePorts(2*i+1).addr; 
					pl2tmrvoter_writePorts_temp(2*index+1).data  			<= pl2tmrvoter_writePorts(2*i+1).data; 
					pl2tmrvoter_writePorts_temp(2*index+1).writeEnable  	<= pl2tmrvoter_writePorts(2*i+1).writeEnable; 
					pl2tmrvoter_writePorts_temp(2*index+1).forwardEnable  	<= pl2tmrvoter_writePorts(2*i+1).forwardEnable; 

					index := index + 1;
				end if;
			end loop;
			index	:= 0;
		end if;
	end process;
					
	---------------------------------------------------------------------------
    -- PC Majority voter bank for addr-even pipelanes
    ---------------------------------------------------------------------------				
				
	WriteAddr_even_voter: for j in S_FIRST to (S_WB+L_WB) generate
		addr_even_voter: for i in 0 to 5 generate
			addr_even_voter_bank: entity work.tmr_voter
				port map (
					input_1		=> pl2tmrvoter_writePorts_temp(0).addr(j)(i),
					--input_1		=> '0',
					input_2		=> pl2tmrvoter_writePorts_temp(2).addr(j)(i),
					--input_2		=> '0',
					input_3		=> pl2tmrvoter_writePorts_temp(4).addr(j)(i),
					--input_3		=> '0',
					output		=> pl2tmrvoter_writePorts_s_result_even.addr(j)(i)
				);
		end generate;
	end generate;
	
	---------------------------------------------------------------------------
    -- PC Majority voter bank for addr-odd pipelanes
    ---------------------------------------------------------------------------				
		
	WriteAddr_odd_voter: for j in S_FIRST to (S_WB+L_WB) generate
		addr_odd_voter: for i in 0 to 5 generate
			addr_odd_voter_bank: entity work.tmr_voter
				port map (
					input_1		=> pl2tmrvoter_writePorts_temp(1).addr(j)(i),
					--input_1		=> '0',
					input_2		=> pl2tmrvoter_writePorts_temp(3).addr(j)(i),
					--input_2		=> '0',
					input_3		=> pl2tmrvoter_writePorts_temp(5).addr(j)(i),
					--input_3		=> '0',
					output		=> pl2tmrvoter_writePorts_s_result_odd.addr(j)(i)
				);
		end generate;
	end generate;
				
				
--				pl2tmrvoter_writePorts_s_result_even.addr <= pl2tmrvoter_writePorts(0).addr;
--				pl2tmrvoter_writePorts_s_result_odd.addr  <= pl2tmrvoter_writePorts(1).addr;
	
	---------------------------------------------------------------------------
    -- PC Majority voter bank for data-even pipelanes
    ---------------------------------------------------------------------------				
		
	WriteData_even_voter: for j in S_FIRST to (S_WB+L_WB) generate
		data_even_voter: for i in 0 to 31 generate
			data_even_voter_bank: entity work.tmr_voter
				port map (
					input_1		=> pl2tmrvoter_writePorts_temp(0).data(j)(i),
					--input_1		=> '0',
					input_2		=> pl2tmrvoter_writePorts_temp(2).data(j)(i),
					--input_2		=> '0',
					input_3		=> pl2tmrvoter_writePorts_temp(4).data(j)(i),
					--input_3		=> '0',
					output		=> pl2tmrvoter_writePorts_s_result_even.data(j)(i)
				);
		end generate;
	end generate;
	
	---------------------------------------------------------------------------
    -- PC Majority voter bank for data-odd pipelanes
    ---------------------------------------------------------------------------				
		
	WriteData_odd_voter: for j in S_FIRST to (S_WB+L_WB) generate
		data_odd_voter: for i in 0 to 31 generate
			data_odd_voter_bank: entity work.tmr_voter
				port map (
					input_1		=> pl2tmrvoter_writePorts_temp(1).data(j)(i),
					--input_1		=> '0',
					input_2		=> pl2tmrvoter_writePorts_temp(3).data(j)(i),
					--input_2		=> '0',
					input_3		=> pl2tmrvoter_writePorts_temp(5).data(j)(i),
					--input_3		=> '0',
					output		=> pl2tmrvoter_writePorts_s_result_odd.data(j)(i)
				);
		end generate;
	end generate;

--			pl2tmrvoter_writePorts_s_result_even.data <= pl2tmrvoter_writePorts(0).data;
--			pl2tmrvoter_writePorts_s_result_odd.data  <= pl2tmrvoter_writePorts(1).data;			
			
	---------------------------------------------------------------------------
    -- PC Majority voter bank for writeEnable-even pipelanes
    ---------------------------------------------------------------------------				
		
		WriteEnable_even_voter_bank: entity work.tmr_voter
			port map (
				input_1		=> pl2tmrvoter_writePorts_temp(0).writeEnable(S_WB),
				--input_1		=> '0',
				input_2		=> pl2tmrvoter_writePorts_temp(2).writeEnable(S_WB),
				--input_2		=> '0',
				input_3		=> pl2tmrvoter_writePorts_temp(4).writeEnable(S_WB),
				--input_3		=> '0',
				output		=> pl2tmrvoter_writePorts_s_result_even.writeEnable(S_WB)
			);
	
	---------------------------------------------------------------------------
    -- PC Majority voter bank for writeEnable-odd pipelanes
    ---------------------------------------------------------------------------				
		
		WriteEnable_odd_voter_bank: entity work.tmr_voter
			port map (
				input_1		=> pl2tmrvoter_writePorts_temp(1).writeEnable(S_WB),
				--input_1		=> '0',
				input_2		=> pl2tmrvoter_writePorts_temp(3).writeEnable(S_WB),
				--input_2		=> '0',
				input_3		=> pl2tmrvoter_writePorts_temp(5).writeEnable(S_WB),
				--input_3		=> '0',
				output		=> pl2tmrvoter_writePorts_s_result_odd.writeEnable(S_WB)
			);
	
--			pl2tmrvoter_writePorts_s_result_even.writeEnable <= pl2tmrvoter_writePorts(0).writeEnable;
--			pl2tmrvoter_writePorts_s_result_odd.writeEnable  <= pl2tmrvoter_writePorts(1).writeEnable;
			
	---------------------------------------------------------------------------
    -- PC Majority voter bank for forwardEnable-even pipelanes
    ---------------------------------------------------------------------------				
		
	ForwardEnable_even_voter: for i in S_FIRST to (S_WB+L_WB) generate
		forwardenalbe_even_bank: entity work.tmr_voter
			port map (
				input_1		=> pl2tmrvoter_writePorts_temp(0).forwardEnable(i),
				--input_1		=> '0',
				input_2		=> pl2tmrvoter_writePorts_temp(2).forwardEnable(i),
				--input_2		=> '0',
				input_3		=> pl2tmrvoter_writePorts_temp(4).forwardEnable(i),
				--input_3		=> '0',
				output		=> pl2tmrvoter_writePorts_s_result_even.forwardEnable(i)
			);
	end generate;
	
	---------------------------------------------------------------------------
    -- PC Majority voter bank for forwardEnable-odd pipelanes
    ---------------------------------------------------------------------------				
		
	ForwardEnable_odd_voter: for i in S_FIRST to (S_WB+L_WB) generate
		forwardenalbe_odd_bank: entity work.tmr_voter
			port map (
				input_1		=> pl2tmrvoter_writePorts_temp(1).forwardEnable(i),
				--input_1		=> '0',
				input_2		=> pl2tmrvoter_writePorts_temp(3).forwardEnable(i),
				--input_2		=> '0',
				input_3		=> pl2tmrvoter_writePorts_temp(5).forwardEnable(i),
				--input_3		=> '0',
				output		=> pl2tmrvoter_writePorts_s_result_odd.forwardEnable(i)
			);
	end generate;
	
--			pl2tmrvoter_writePorts_s_result_even.forwardEnable <= pl2tmrvoter_writePorts(0).forwardEnable;
--			pl2tmrvoter_writePorts_s_result_odd.forwardEnable  <= pl2tmrvoter_writePorts(1).forwardEnable;
								
	
	---------------------------------------------------------------------------
    -- Recreate GPREG signals value after voter bank
    ---------------------------------------------------------------------------			
		
--	addr_result: process (start_array, config_signal, pl2tmrvoter_writePorts_s, pl2tmrvoter_writePorts_s_result_even, pl2tmrvoter_writePorts_s_result_odd, pl2tmrvoter_writePorts)	
--	variable mask_signal	: std_logic_vector (3 downto 0) := "0001";
--		variable delay	: integer	:= 0;
--	begin
--		if start_array(0) = '0' then
--			tmrvoter2gpreg_writePorts					<=	pl2tmrvoter_writePorts_s;
--
--		else
--			--if delay > 2 then 
--				tmrvoter2gpreg_writePorts					<=	(others => zero_init);
--		
--				for i in 0 to 3 loop
--					if config_signal(i) = '1' then
--						if mask_signal(i) = '1' then
--							tmrvoter2gpreg_writePorts(2*i)			<=	pl2tmrvoter_writePorts_s_result_even;
--							tmrvoter2gpreg_writePorts(2*i+1)		<=	pl2tmrvoter_writePorts_s_result_odd;
--						else
--
--							tmrvoter2gpreg_writePorts(2*i)					<=	pl2tmrvoter_writePorts_s_result_even;
--							tmrvoter2gpreg_writePorts(2*i).writeEnable(S_WB)<=	'0';
--
--							tmrvoter2gpreg_writePorts(2*i+1)				<=	pl2tmrvoter_writePorts_s_result_odd;
--							tmrvoter2gpreg_writePorts(2*i+1).writeEnable(S_WB)	<=	'0';
--				
--						end if;
--					else
--						tmrvoter2gpreg_writePorts(2*i)		<=	zero_init;
--						tmrvoter2gpreg_writePorts(2*i+1)	<=	zero_init;
--					end if;
--		
--				end loop;
		
			--else 
			--			tmrvoter2gpreg_writePorts		<= pl2tmrvoter_writePorts;
			--			delay := delay + 1;
			--end if;


--		end if;
--	end process;
	
	
	
	tmrvoter2gpreg_readPorts		<= pl2tmrvoter_readPorts;
	tmrvoter2pl_readPorts			<= gpreg2tmrvoter_readPorts;
	tmrvoter2gpreg_writePorts		<= pl2tmrvoter_writePorts;


end structural;
			

