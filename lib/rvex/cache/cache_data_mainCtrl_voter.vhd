library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.common_pkg.all;
--use work.utils_pkg.all;
--use work.core_pkg.all;
--use work.core_intIface_pkg.all;
--use work.core_pipeline_pkg.all;
use work.bus_pkg.all;
use work.cache_pkg.all;


--=============================================================================
entity cache_data_missCtrl_voter is
--=============================================================================
	
--  generic (
    
--    -- Configuration.
--    CFG                         : rvex_generic_config_type 
--  );


  port	(
	  
	  

	  
    ---------------------------------------------------------------------------
    -- Signals that go into cache_data_missCtrl_voter
    ---------------------------------------------------------------------------
    --update_mv						: in std_logic_vector (2 downto 0);
    --updateData_mv					: in updateData_array (2 downto 0);
    --block2route_blockReconfig_mv	: in std_logic_vector (2 downto 0);
    --block2route_busFault_mv			: in std_logic_vector (2 downto 0);
    --icache2bus_bus_mv				: in bus_mst2slv_array(2 downto 0);
	  
    readData_mv                  : in rvex_encoded_datacache_data_array (2 downto 0); 
    blockReconfig_mv             : in std_logic_vector (2 downto 0);
    writeOrBypassStall_mv        : in std_logic_vector (2 downto 0);
    busFault_mv                  : in std_logic_vector (2 downto 0);
	writePrio_mv                 : in two_bit_array (2 downto 0);
	update_mv                    : in std_logic_vector (2 downto 0);
	updateData_mv                : in rvex_encoded_datacache_data_array (2 downto 0);
    updateMask_mv                : in rvex_mask_array(2 downto 0);
    cacheToBus_mv                : in bus_mst2slv_array(2 downto 0); 
    servicedWrite_mv             : in std_logic_vector (2 downto 0);
    writeBuffered_mv             : in std_logic_vector (2 downto 0);
	  
	---------------------------------------------------------------------------
    -- Signals that come out of cache_data_missCtrl_voter
    ---------------------------------------------------------------------------
	  
	--update							: out std_logic;
    --updateData						: out std_logic_vector(303 downto 0);
    --block2route_blockReconfig		: out std_logic;
    --block2route_busFault			: out std_logic;
    --icache2bus_bus					: out bus_mst2slv_type
	  
    readData                    : out rvex_encoded_datacache_data_type; 
    blockReconfig               : out std_logic;
    writeOrBypassStall          : out std_logic;
    busFault                    : out std_logic;
	writePrio                   : out std_logic_vector(1 downto 0);
	update                      : out std_logic;
	updateData                  : out rvex_encoded_datacache_data_type;
    updateMask                  : out rvex_mask_type;
    cacheToBus                  : out bus_mst2slv_type;
    servicedWrite               : out std_logic;
    writeBuffered               : out std_logic

	  
  );

end entity cache_data_missCtrl_voter;
	

--=============================================================================
architecture structural of cache_data_missCtrl_voter is
--=============================================================================
	
	
--=============================================================================
begin -- architecture
--=============================================================================		
	
	
	---------------------------------------------------------------------------
    -- PC Majority voter bank for readData_mv
    ---------------------------------------------------------------------------				
				
	readData_mv_voterbank: for i in 0 to 47 generate
		readData_mv_voter: entity work.tmr_voter
				port map (
					input_1		=> readData_mv(0)(i),
					--input_1		=> '0',
					input_2		=> readData_mv(1)(i),
					--input_2		=> '0',
					input_3		=> readData_mv(2)(i),
					--input_3		=> '0',
					output		=> readData(i)
				);
		end generate;	
		
		

	
					
	---------------------------------------------------------------------------
    -- PC Majority voter bank for blockReconfig_mv
    ---------------------------------------------------------------------------				
				
	blockReconfig_mv_voter: entity work.tmr_voter
		port map (
			input_1		=> blockReconfig_mv(0),
			--input_1		=> '0',
			input_2		=> blockReconfig_mv(1),
			--input_2		=> '0',
			input_3		=> blockReconfig_mv(2),
			--input_3		=> '0',
			output		=> blockReconfig
			);

		
	---------------------------------------------------------------------------
    -- PC Majority voter bank for writeOrBypassStall_mv
    ---------------------------------------------------------------------------				
				
	writeOrBypassStall_mv_voter: entity work.tmr_voter
		port map (
			input_1		=> writeOrBypassStall_mv(0),
			--input_1		=> '0',
			input_2		=> writeOrBypassStall_mv(1),
			--input_2		=> '0',
			input_3		=> writeOrBypassStall_mv(2),
			--input_3		=> '0',
			output		=> writeOrBypassStall
			);

	---------------------------------------------------------------------------
    -- PC Majority voter bank for busFault_mv
    ---------------------------------------------------------------------------				
				
	busFault_mv_voter: entity work.tmr_voter
		port map (
			input_1		=> busFault_mv(0),
			--input_1		=> '0',
			input_2		=> busFault_mv(1),
			--input_2		=> '0',
			input_3		=> busFault_mv(2),
			--input_3		=> '0',
			output		=> busFault
			);


	---------------------------------------------------------------------------
    -- PC Majority voter bank for writePrio_mv
    ---------------------------------------------------------------------------				
				
	writePrio_mv_voterbank: for i in 0 to 1 generate
		writePrio_mv_voter: entity work.tmr_voter
				port map (
					input_1		=> writePrio_mv(0)(i),
					--input_1		=> '0',
					input_2		=> writePrio_mv(1)(i),
					--input_2		=> '0',
					input_3		=> writePrio_mv(2)(i),
					--input_3		=> '0',
					output		=> writePrio(i)
				);
		end generate;	
		
	---------------------------------------------------------------------------
    -- PC Majority voter bank for update_mv
    ---------------------------------------------------------------------------				
				
	update_mv_voter: entity work.tmr_voter
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
    -- PC Majority voter bank for updateData_mv
    ---------------------------------------------------------------------------				
				
	updateData_mv_voterbank: for i in 0 to 47 generate
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
    -- PC Majority voter bank for updateMask_mv
    ---------------------------------------------------------------------------				
				
	updateMask_mv_voterbank: for i in 0 to 3 generate
		updateMask_mv_voter: entity work.tmr_voter
				port map (
					input_1		=> updateMask_mv(0)(i),
					--input_1		=> '0',
					input_2		=> updateMask_mv(1)(i),
					--input_2		=> '0',
					input_3		=> updateMask_mv(2)(i),
					--input_3		=> '0',
					output		=> updateMask(i)
				);
		end generate;	
		
			
	---------------------------------------------------------------------------
    -- PC Majority voter bank for cacheToBus_mv
    ---------------------------------------------------------------------------		
			
	-- PC Majority voter bank for cacheToBus_mv.address		
	cacheToBus_mv_address_voter_bank: for i in 0 to 31 generate
		cacheToBus_mv_address_voter: entity work.tmr_voter
				port map (
					input_1		=> cacheToBus_mv(0).address(i),
					--input_1		=> '0',
					input_2		=> cacheToBus_mv(1).address(i),
					--input_2		=> '0',
					input_3		=> cacheToBus_mv(2).address(i),
					--input_3		=> '0',
					output		=> cacheToBus.address(i)
				);
	end generate;


	-- PC Majority voter bank for cacheToBus_mv.readEnable
	cacheToBus_mv_readEnable_voter: entity work.tmr_voter
				port map (
					input_1		=> cacheToBus_mv(0).readEnable,
					--input_1		=> '0',
					input_2		=> cacheToBus_mv(1).readEnable,
					--input_2		=> '0',
					input_3		=> cacheToBus_mv(2).readEnable,
					--input_3		=> '0',
					output		=> cacheToBus.readEnable
				);


	-- PC Majority voter bank for cacheToBus_mv.writeEnable
	cacheToBus_mv_writeEnable_voter: entity work.tmr_voter
				port map (
					input_1		=> cacheToBus_mv(0).writeEnable,
					--input_1		=> '0',
					input_2		=> cacheToBus_mv(1).writeEnable,
					--input_2		=> '0',
					input_3		=> cacheToBus_mv(2).writeEnable,
					--input_3		=> '0',
					output		=> cacheToBus.writeEnable
				);
	

	-- PC Majority voter bank for cacheToBus_mv.writeMask
	cacheToBus_mv_writeMask_voter_bank: for i in 0 to 3 generate
		cacheToBus_mv_writeMask_voter: entity work.tmr_voter
				port map (
					input_1		=> cacheToBus_mv(0).writeMask(i),
					--input_1		=> '0',
					input_2		=> cacheToBus_mv(1).writeMask(i),
					--input_2		=> '0',
					input_3		=> cacheToBus_mv(2).writeMask(i),
					--input_3		=> '0',
					output		=> cacheToBus.writeMask(i)
				);
	end generate;
		
					
			

	-- PC Majority voter bank for cacheToBus_mv.writeData		
	cacheToBus_mv_writeData_voter_bank: for i in 0 to 31 generate
		cacheToBus_mv_writeData_voter: entity work.tmr_voter
				port map (
					input_1		=> cacheToBus_mv(0).writeData(i),
					--input_1		=> '0',
					input_2		=> cacheToBus_mv(1).writeData(i),
					--input_2		=> '0',
					input_3		=> cacheToBus_mv(2).writeData(i),
					--input_3		=> '0',
					output		=> cacheToBus.writeData(i)
				);
	end generate;
	

	-- PC Majority voter bank for cacheToBus_mv.flags.burstEnable
	cacheToBus_mv_flags_burstEnable_voter: entity work.tmr_voter
				port map (
					input_1		=> cacheToBus_mv(0).flags.burstEnable,
					--input_1		=> '0',
					input_2		=> cacheToBus_mv(1).flags.burstEnable,
					--input_2		=> '0',
					input_3		=> cacheToBus_mv(2).flags.burstEnable,
					--input_3		=> '0',
					output		=> cacheToBus.flags.burstEnable
				);

	-- PC Majority voter bank for cacheToBus_mv.flags.burstStart
	cacheToBus_mv_flags_burstStart_voter: entity work.tmr_voter
				port map (
					input_1		=> cacheToBus_mv(0).flags.burstStart,
					--input_1		=> '0',
					input_2		=> cacheToBus_mv(1).flags.burstStart,
					--input_2		=> '0',
					input_3		=> cacheToBus_mv(2).flags.burstStart,
					--input_3		=> '0',
					output		=> cacheToBus.flags.burstStart
				);

	-- PC Majority voter bank for cacheToBus_mv.flags.lock
	cacheToBus_mv_flags_lock_voter: entity work.tmr_voter
				port map (
					input_1		=> cacheToBus_mv(0).flags.lock,
					--input_1		=> '0',
					input_2		=> cacheToBus_mv(1).flags.lock,
					--input_2		=> '0',
					input_3		=> cacheToBus_mv(2).flags.lock,
					--input_3		=> '0',
					output		=> cacheToBus.flags.lock
				);
		
		
	---------------------------------------------------------------------------
    -- PC Majority voter bank for servicedWrite_mv
    ---------------------------------------------------------------------------				
				
	servicedWrite_mv_voter: entity work.tmr_voter
		port map (
			input_1		=> servicedWrite_mv(0),
			--input_1		=> '0',
			input_2		=> servicedWrite_mv(1),
			--input_2		=> '0',
			input_3		=> servicedWrite_mv(2),
			--input_3		=> '0',
			output		=> servicedWrite
			);
		

	---------------------------------------------------------------------------
    -- PC Majority voter bank for writeBuffered_mv
    ---------------------------------------------------------------------------				
				
	writeBuffered_mv_voter: entity work.tmr_voter
		port map (
			input_1		=> writeBuffered_mv(0),
			--input_1		=> '0',
			input_2		=> writeBuffered_mv(1),
			--input_2		=> '0',
			input_3		=> writeBuffered_mv(2),
			--input_3		=> '0',
			output		=> writeBuffered
			);
		

		
		

	
	--tmrvoter2gpreg_readPorts		<= pl2tmrvoter_readPorts;
	--tmrvoter2pl_readPorts			<= gpreg2tmrvoter_readPorts;
	--tmrvoter2gpreg_writePorts		<= pl2tmrvoter_writePorts;


end structural;
			

