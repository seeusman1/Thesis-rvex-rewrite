library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
--use work.common_pkg.all;
--use work.utils_pkg.all;
--use work.core_pkg.all;
--use work.core_intIface_pkg.all;
--use work.core_pipeline_pkg.all;
use work.bus_pkg.all;
use work.cache_pkg.all;


--=============================================================================
entity cache_instr_missCtrl_voter is
--=============================================================================
	
--  generic (
    
--    -- Configuration.
--    CFG                         : rvex_generic_config_type 
--  );


  port	(
	  
	-- Active high synchronous reset input.
--    reset                       : in  std_logic;
    
    -- Clock input, registers are rising edge triggered.
--    clk                         : in  std_logic;
    
    -- Active high global clock enable input.
--    clkEn                       : in  std_logic := '1';
	  
	--Active high fault tolerance enable  
--	start_ft					: in std_logic;
	  
	--signal representing active pipelane groups for fault tolerance mode
--	config_signal				: in std_logic_vector (3 downto 0); 
	   
    ---------------------------------------------------------------------------
    -- Signals that go into cache_instr_missCtrl_voter
    ---------------------------------------------------------------------------
    update_mv						: in std_logic_vector (2 downto 0);
    updateData_mv					: in updateData_array (2 downto 0);
    block2route_blockReconfig_mv	: in std_logic_vector (2 downto 0);
    block2route_busFault_mv			: in std_logic_vector (2 downto 0);
    icache2bus_bus_mv				: in bus_mst2slv_array(2 downto 0);
	  
	---------------------------------------------------------------------------
    -- Signals that come out of cache_instr_missCtrl_voter
    ---------------------------------------------------------------------------
	  
	update							: out std_logic;
    --updateData						: out std_logic_vector(icacheLineWidth(RCFG, CCFG)-1 downto 0);
    updateData						: out std_logic_vector(311 downto 0);
    block2route_blockReconfig		: out std_logic;
    block2route_busFault			: out std_logic;
    icache2bus_bus					: out bus_mst2slv_type

	  
  );

end entity cache_instr_missCtrl_voter;
	

--=============================================================================
architecture structural of cache_instr_missCtrl_voter is
--=============================================================================
	
	
--=============================================================================
begin -- architecture
--=============================================================================		
	
	---------------------------------------------------------------------------
    -- Adding Delay before GPREG voter starts after fault tolerance is requested
    ---------------------------------------------------------------------------					

--	delay_regsiter: process (clk, start_ft)
--	begin
--		if rising_edge (clk) then
--			if (reset = '1') then
--				start_array <= (others => '0');
--			else
--				start_array(0) <= start_ft;
--			end if;
				
--		end if;
--	end process;	


					
	---------------------------------------------------------------------------
    -- PC Majority voter bank for update
    ---------------------------------------------------------------------------				
				
	update_voter: entity work.tmr_voter
		port map (
			input_1		=> update_mv(0),
			--input_1		=> '0',
			input_2		=> update_mv(1),
			--input_2		=> '0',
			input_3		=> update_mv(2),
			--input_3		=> '0',
			output		=> update
			);

	
	---------------------------------------------------------------------------
    -- PC Majority voter bank for block2route_blockReconfig
    ---------------------------------------------------------------------------				
				
	block2route_blockReconfig_voter: entity work.tmr_voter
		port map (
			input_1		=> block2route_blockReconfig_mv(0),
			--input_1		=> '0',
			input_2		=> block2route_blockReconfig_mv(1),
			--input_2		=> '0',
			input_3		=> block2route_blockReconfig_mv(2),
			--input_3		=> '0',
			output		=> block2route_blockReconfig
			);

	---------------------------------------------------------------------------
    -- PC Majority voter bank for block2route_busFault
    ---------------------------------------------------------------------------				
				
	block2route_busFault_voter: entity work.tmr_voter
		port map (
			input_1		=> block2route_busFault_mv(0),
			--input_1		=> '0',
			input_2		=> block2route_busFault_mv(1),
			--input_2		=> '0',
			input_3		=> block2route_busFault_mv(2),
			--input_3		=> '0',
			output		=> block2route_busFault
			);

	
	---------------------------------------------------------------------------
    -- PC Majority voter bank for updateData_mv
    ---------------------------------------------------------------------------				
				
	updateData_mv_voterbank: for i in 0 to 311 generate
		updateData_mv_voter: entity work.tmr_voter
				port map (
					input_1		=> updateData_mv(0)(i),
					--input_1		=> '0',
					input_2		=> updateData_mv(1)(i),
					--input_2		=> '0',
					input_3		=> updateData_mv(2)(i),
					--input_3		=> '0',
					output		=> updateData(i)
				);
		end generate;	
		
		
			
	---------------------------------------------------------------------------
    -- PC Majority voter bank for icache2bus_bus_mv
    ---------------------------------------------------------------------------		
			
	-- PC Majority voter bank for icache2bus_bus_mv.address		
	icache2bus_bus_mv_address_voter_bank: for i in 0 to 31 generate
		icache2bus_bus_mv_address_voter: entity work.tmr_voter
				port map (
					input_1		=> icache2bus_bus_mv(0).address(i),
					--input_1		=> '0',
					input_2		=> icache2bus_bus_mv(1).address(i),
					--input_2		=> '0',
					input_3		=> icache2bus_bus_mv(2).address(i),
					--input_3		=> '0',
					output		=> icache2bus_bus.address(i)
				);
	end generate;


	-- PC Majority voter bank for icache2bus_bus_mv.readEnable
	icache2bus_bus_mv_readEnable_voter: entity work.tmr_voter
				port map (
					input_1		=> icache2bus_bus_mv(0).readEnable,
					--input_1		=> '0',
					input_2		=> icache2bus_bus_mv(1).readEnable,
					--input_2		=> '0',
					input_3		=> icache2bus_bus_mv(2).readEnable,
					--input_3		=> '0',
					output		=> icache2bus_bus.readEnable
				);


	-- PC Majority voter bank for icache2bus_bus_mv.writeEnable
	icache2bus_bus_mv_writeEnable_voter: entity work.tmr_voter
				port map (
					input_1		=> icache2bus_bus_mv(0).writeEnable,
					--input_1		=> '0',
					input_2		=> icache2bus_bus_mv(1).writeEnable,
					--input_2		=> '0',
					input_3		=> icache2bus_bus_mv(2).writeEnable,
					--input_3		=> '0',
					output		=> icache2bus_bus.writeEnable
				);
	

	-- PC Majority voter bank for icache2bus_bus_mv.writeMask
	icache2bus_bus_mv_writeMask_voter_bank: for i in 0 to 3 generate
		icache2bus_bus_mv_writeMask_voter: entity work.tmr_voter
				port map (
					input_1		=> icache2bus_bus_mv(0).writeMask(i),
					--input_1		=> '0',
					input_2		=> icache2bus_bus_mv(1).writeMask(i),
					--input_2		=> '0',
					input_3		=> icache2bus_bus_mv(2).writeMask(i),
					--input_3		=> '0',
					output		=> icache2bus_bus.writeMask(i)
				);
	end generate;
		
					
			

	-- PC Majority voter bank for icache2bus_bus_mv.writeData		
	icache2bus_bus_mv_writeData_voter_bank: for i in 0 to 31 generate
		icache2bus_bus_mv_writeData_voter: entity work.tmr_voter
				port map (
					input_1		=> icache2bus_bus_mv(0).writeData(i),
					--input_1		=> '0',
					input_2		=> icache2bus_bus_mv(1).writeData(i),
					--input_2		=> '0',
					input_3		=> icache2bus_bus_mv(2).writeData(i),
					--input_3		=> '0',
					output		=> icache2bus_bus.writeData(i)
				);
	end generate;
	

	-- PC Majority voter bank for icache2bus_bus_mv.flags.burstEnable
	icache2bus_bus_mv_flags_burstEnable_voter: entity work.tmr_voter
				port map (
					input_1		=> icache2bus_bus_mv(0).flags.burstEnable,
					--input_1		=> '0',
					input_2		=> icache2bus_bus_mv(1).flags.burstEnable,
					--input_2		=> '0',
					input_3		=> icache2bus_bus_mv(2).flags.burstEnable,
					--input_3		=> '0',
					output		=> icache2bus_bus.flags.burstEnable
				);

	-- PC Majority voter bank for icache2bus_bus_mv.flags.burstStart
	icache2bus_bus_mv_flags_burstStart_voter: entity work.tmr_voter
				port map (
					input_1		=> icache2bus_bus_mv(0).flags.burstStart,
					--input_1		=> '0',
					input_2		=> icache2bus_bus_mv(1).flags.burstStart,
					--input_2		=> '0',
					input_3		=> icache2bus_bus_mv(2).flags.burstStart,
					--input_3		=> '0',
					output		=> icache2bus_bus.flags.burstStart
				);

	-- PC Majority voter bank for icache2bus_bus_mv.flags.lock
	icache2bus_bus_mv_flags_lock_voter: entity work.tmr_voter
				port map (
					input_1		=> icache2bus_bus_mv(0).flags.lock,
					--input_1		=> '0',
					input_2		=> icache2bus_bus_mv(1).flags.lock,
					--input_2		=> '0',
					input_3		=> icache2bus_bus_mv(2).flags.lock,
					--input_3		=> '0',
					output		=> icache2bus_bus.flags.lock
				);
		

	
	--tmrvoter2gpreg_readPorts		<= pl2tmrvoter_readPorts;
	--tmrvoter2pl_readPorts			<= gpreg2tmrvoter_readPorts;
	--tmrvoter2gpreg_writePorts		<= pl2tmrvoter_writePorts;


end structural;
			

