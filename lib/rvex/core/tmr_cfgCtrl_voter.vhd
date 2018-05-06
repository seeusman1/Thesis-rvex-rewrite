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
entity tmr_cfgCtrl_voter is
--=============================================================================

  generic (
    
    -- Configuration.
    CFG                         : rvex_generic_config_type 
  );
	
  port	(
	  
   
    ---------------------------------------------------------------------------
    -- Signals that go into tmr_cfgCtrl_voter
    ---------------------------------------------------------------------------

	cfg2cxreg_wakeupAck_mv         : in std_logic_vector (2 downto 0);
    cfg2gbreg_busy_mv              : in std_logic_vector (2 downto 0); 
    cfg2gbreg_error_mv             : in std_logic_vector (2 downto 0); 
    cfg2gbreg_requesterID_mv       : in cfg2gbreg_requesterID_array (2 downto 0);
    cfg2cxplif_active_mv           : in cfg2cxplif_active_array(2 downto 0);
    cfg2cxplif_requestReconfig_mv  : in cfg2cxplif_requestReconfig_array(2 downto 0);
    cfg2any_configWord_mv          : in rvex_data_array (2 downto 0);
    cfg2any_coupled_mv             : in cfg2any_coupled_array(2 downto 0); 
    cfg2any_decouple_mv            : in cfg2any_decouple_array(2 downto 0);
    cfg2any_numGroupsLog2_mv       : in cfg2any_numGroupsLog2_array(2 downto 0); 
    cfg2any_context_mv             : in cfg2any_context_array(2 downto 0);
    cfg2any_active_mv              : in cfg2any_active_array(2 downto 0); 
    cfg2any_lastGroupForCtxt_mv    : in cfg2any_lastGroupForCtxt_array(2 downto 0);
    cfg2any_laneIndex_mv           : in cfg2any_laneIndex_array(2 downto 0);
    cfg2any_pcAddVal_mv            : in cfg2any_pcAddVal_array(2 downto 0);
	tmr_enable_mv				   : in std_logic_vector (2 downto 0); 
	config_signal_mv			   : in config_signal_array (2 downto 0); 
	  
	  
	  
	  
	  
--   type cfg2gbreg_requesterID_array       is array (natural range <>) of std_logic_vector(3 downto 0);
--   type cfg2cxplif_active_array           is array (natural range <>) of std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
--   type cfg2cxplif_requestReconfig_array  is array (natural range <>) of std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
--   type cfg2any_coupled_array             is array (natural range <>) of std_logic_vector(4**CFG.numLaneGroupsLog2-1 downto 0);
--   type cfg2any_decouple_array            is array (natural range <>) of std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
--   type cfg2any_numGroupsLog2_array       is array (natural range <>) of rvex_2bit_array(2**CFG.numLaneGroupsLog2-1 downto 0);
--   type cfg2any_context_array             is array (natural range <>) of rvex_3bit_array(2**CFG.numLaneGroupsLog2-1 downto 0);
--   type cfg2any_active_array              is array (natural range <>) of std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
--   type cfg2any_lastGroupForCtxt_array    is array (natural range <>) of rvex_3bit_array(2**CFG.numContextsLog2-1 downto 0);
--   type cfg2any_laneIndex_array           is array (natural range <>) of rvex_4bit_array(2**CFG.numLanesLog2-1 downto 0);
--   type cfg2any_pcAddVal_array            is array (natural range <>) of rvex_address_array(2**CFG.numLanesLog2-1 downto 0); 
--   type config_signal_array				  is array (natural range <>) of std_logic_vector (3 downto 0) ;
	  
	  
	  
	---------------------------------------------------------------------------
    -- Signals that come out of tmr_cfgCtrl_voter
    ---------------------------------------------------------------------------
	  
	cfg2cxreg_wakeupAck         : out std_logic;
    cfg2gbreg_busy              : out std_logic;
    cfg2gbreg_error             : out std_logic;
    cfg2gbreg_requesterID       : out std_logic_vector(3 downto 0);
    cfg2cxplif_active           : out std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
    cfg2cxplif_requestReconfig  : out std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
    cfg2any_configWord          : out rvex_data_type;
    cfg2any_coupled             : out std_logic_vector(4**CFG.numLaneGroupsLog2-1 downto 0);
    cfg2any_decouple            : out std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    cfg2any_numGroupsLog2       : out rvex_2bit_array(2**CFG.numLaneGroupsLog2-1 downto 0); 
    cfg2any_context             : out rvex_3bit_array(2**CFG.numLaneGroupsLog2-1 downto 0); 
    cfg2any_active              : out std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    cfg2any_lastGroupForCtxt    : out rvex_3bit_array(2**CFG.numContextsLog2-1 downto 0); 
    cfg2any_laneIndex           : out rvex_4bit_array(2**CFG.numLanesLog2-1 downto 0); 
    cfg2any_pcAddVal            : out rvex_address_array(2**CFG.numLanesLog2-1 downto 0); 
	tmr_enable					: out std_logic; 
	config_signal				: out std_logic_vector (3 downto 0) 
	  
	  
	  
  );

end entity tmr_cfgCtrl_voter;
	

--=============================================================================
architecture structural of tmr_cfgCtrl_voter is
--=============================================================================
				
	
--=============================================================================
begin -- architecture
--=============================================================================		
	
	
					
	---------------------------------------------------------------------------
    -- PC Majority voter bank for cfg2cxreg_wakeupAck
    ---------------------------------------------------------------------------				
				
		cfg2cxreg_wakeupAck_voter: entity work.tmr_voter
			port map (
				input_1		=> cfg2cxreg_wakeupAck_mv(0),
				--input_1		=> '0',
				input_2		=> cfg2cxreg_wakeupAck_mv(1),
				--input_2		=> '0',
				input_3		=> cfg2cxreg_wakeupAck_mv(2),
				--input_3		=> '0',
				output		=> cfg2cxreg_wakeupAck
			);
			
	
	---------------------------------------------------------------------------
    -- PC Majority voter bank for cfg2gbreg_busy
    ---------------------------------------------------------------------------				
		
		cfg2gbreg_busy_voter: entity work.tmr_voter
			port map (
				input_1		=> cfg2gbreg_busy_mv(0),
				--input_1		=> '0',
				input_2		=> cfg2gbreg_busy_mv(1),
				--input_2		=> '0',
				input_3		=> cfg2gbreg_busy_mv(2),
				--input_3		=> '0',
				output		=> cfg2gbreg_busy
			);
			

	
	---------------------------------------------------------------------------
    -- PC Majority voter bank for cfg2gbreg_error
    ---------------------------------------------------------------------------				
		
		cfg2gbreg_error_voter: entity work.tmr_voter
			port map (
				input_1		=> cfg2gbreg_error_mv(0),
				--input_1		=> '0',
				input_2		=> cfg2gbreg_error_mv(1),
				--input_2		=> '0',
				input_3		=> cfg2gbreg_error_mv(2),
				--input_3		=> '0',
				output		=> cfg2gbreg_error
			);
			
	
	---------------------------------------------------------------------------
    -- PC Majority voter bank for cfg2gbreg_requesterID
    ---------------------------------------------------------------------------				
		
	cfg2gbreg_requesterID_voterbank: for i in 0 to 3 generate
			cfg2gbreg_requesterID_voter: entity work.tmr_voter
				port map (
					input_1		=> cfg2gbreg_requesterID_mv(0)(i),
					--input_1		=> '0',
					input_2		=> cfg2gbreg_requesterID_mv(1)(i),
					--input_2		=> '0',
					input_3		=> cfg2gbreg_requesterID_mv(2)(i),
					--input_3		=> '0',
					output		=> cfg2gbreg_requesterID(i)
				);
	end generate;
		



			
			
	---------------------------------------------------------------------------
    -- PC Majority voter bank for cfg2cxplif_active
    ---------------------------------------------------------------------------				
		
	cfg2cxplif_active_voterbank: for i in 0 to 2**CFG.numContextsLog2-1 generate
			cfg2cxplif_active_voter: entity work.tmr_voter
				port map (
					input_1		=> cfg2cxplif_active_mv(0)(i),
					--input_1		=> '0',
					input_2		=> cfg2cxplif_active_mv(1)(i),
					--input_2		=> '0',
					input_3		=> cfg2cxplif_active_mv(2)(i),
					--input_3		=> '0',
					output		=> cfg2cxplif_active(i)
				);
	end generate;
		
	
	---------------------------------------------------------------------------
    -- PC Majority voter bank for cfg2cxplif_requestReconfig
    ---------------------------------------------------------------------------				
		
	cfg2cxplif_requestReconfig_voterbank: for i in 0 to 2**CFG.numContextsLog2-1 generate
			cfg2cxplif_requestReconfig_voter: entity work.tmr_voter
				port map (
					input_1		=> cfg2cxplif_requestReconfig_mv(0)(i),
					--input_1		=> '0',
					input_2		=> cfg2cxplif_requestReconfig_mv(1)(i),
					--input_2		=> '0',
					input_3		=> cfg2cxplif_requestReconfig_mv(2)(i),
					--input_3		=> '0',
					output		=> cfg2cxplif_requestReconfig(i)
				);
	end generate;
		
		
			
	---------------------------------------------------------------------------
    -- PC Majority voter bank for cfg2any_configWord
    ---------------------------------------------------------------------------				
		
	cfg2any_configWord_voterbank: for i in 0 to 31 generate
			cfg2any_configWord_voter: entity work.tmr_voter
				port map (
					input_1		=> cfg2any_configWord_mv(0)(i),
					--input_1		=> '0',
					input_2		=> cfg2any_configWord_mv(1)(i),
					--input_2		=> '0',
					input_3		=> cfg2any_configWord_mv(2)(i),
					--input_3		=> '0',
					output		=> cfg2any_configWord(i)
				);
	end generate;
		
		
	
	---------------------------------------------------------------------------
    -- PC Majority voter bank for cfg2any_coupled
    ---------------------------------------------------------------------------				
		
	cfg2any_coupled_voterbank: for i in 0 to 4**CFG.numLaneGroupsLog2-1 generate
			cfg2any_coupled_voter: entity work.tmr_voter
				port map (
					input_1		=> cfg2any_coupled_mv(0)(i),
					--input_1		=> '0',
					input_2		=> cfg2any_coupled_mv(1)(i),
					--input_2		=> '0',
					input_3		=> cfg2any_coupled_mv(2)(i),
					--input_3		=> '0',
					output		=> cfg2any_coupled(i)
				);
	end generate;
		
	
	---------------------------------------------------------------------------
    -- PC Majority voter bank for cfg2any_decouple
    ---------------------------------------------------------------------------			

	cfg2any_decouple_voterbank: for i in 0 to 2**CFG.numLaneGroupsLog2-1 generate
			cfg2any_decouple_voter: entity work.tmr_voter
				port map (
					input_1		=> cfg2any_decouple_mv(0)(i),
					--input_1		=> '0',
					input_2		=> cfg2any_decouple_mv(1)(i),
					--input_2		=> '0',
					input_3		=> cfg2any_decouple_mv(2)(i),
					--input_3		=> '0',
					output		=> cfg2any_decouple(i)
				);
	end generate;
		

			
	---------------------------------------------------------------------------
    -- PC Majority voter bank for cfg2any_numGroupsLog2
    ---------------------------------------------------------------------------				

	cfg2any_numGroupsLog2_voterbank: for i in 0 to 2**CFG.numLaneGroupsLog2-1 generate
		cfg2any_numGroupsLog2_voterarray: for j in 0 to 1 generate
			cfg2any_numGroupsLog2_voter: entity work.tmr_voter
				port map (
					input_1		=> cfg2any_numGroupsLog2_mv(0)(i)(j),
					--input_1		=> '0',
					input_2		=> cfg2any_numGroupsLog2_mv(1)(i)(j),
					--input_2		=> '0',
					input_3		=> cfg2any_numGroupsLog2_mv(2)(i)(j),
					--input_3		=> '0',
					output		=> cfg2any_numGroupsLog2(i)(j)
				);
		end generate;
	end generate;
		
			
								
	---------------------------------------------------------------------------
    -- PC Majority voter bank for cfg2any_context
    ---------------------------------------------------------------------------			

	cfg2any_context_voterbank: for i in 0 to 2**CFG.numLaneGroupsLog2-1 generate
		cfg2any_context_voterarray: for j in 0 to 2 generate
			cfg2any_context_voter: entity work.tmr_voter
				port map (
					input_1		=> cfg2any_context_mv(0)(i)(j),
					--input_1		=> '0',
					input_2		=> cfg2any_context_mv(1)(i)(j),
					--input_2		=> '0',
					input_3		=> cfg2any_context_mv(2)(i)(j),
					--input_3		=> '0',
					output		=> cfg2any_context(i)(j)
				);
		end generate;
	end generate;


			
	---------------------------------------------------------------------------
    -- PC Majority voter bank for cfg2any_active
    ---------------------------------------------------------------------------				
		
	cfg2any_active_voterbank: for i in 0 to 2**CFG.numLaneGroupsLog2-1 generate
			cfg2any_active_voter: entity work.tmr_voter
				port map (
					input_1		=> cfg2any_active_mv(0)(i),
					--input_1		=> '0',
					input_2		=> cfg2any_active_mv(1)(i),
					--input_2		=> '0',
					input_3		=> cfg2any_active_mv(2)(i),
					--input_3		=> '0',
					output		=> cfg2any_active(i)
				);
	end generate;
		


								
	---------------------------------------------------------------------------
    -- PC Majority voter bank for cfg2any_lastGroupForCtxt
    ---------------------------------------------------------------------------			

	cfg2any_lastGroupForCtxt_voterbank: for i in 0 to 2**CFG.numContextsLog2-1 generate
		cfg2any_lastGroupForCtxt_voterarray: for j in 0 to 2 generate
			cfg2any_lastGroupForCtxt_voter: entity work.tmr_voter
				port map (
					input_1		=> cfg2any_lastGroupForCtxt_mv(0)(i)(j),
					--input_1		=> '0',
					input_2		=> cfg2any_lastGroupForCtxt_mv(1)(i)(j),
					--input_2		=> '0',
					input_3		=> cfg2any_lastGroupForCtxt_mv(2)(i)(j),
					--input_3		=> '0',
					output		=> cfg2any_lastGroupForCtxt(i)(j)
				);
		end generate;
	end generate;

		


			
	---------------------------------------------------------------------------
    -- PC Majority voter bank for cfg2any_laneIndex
    ---------------------------------------------------------------------------				
		
	cfg2any_laneIndex_voterbank: for i in 0 to 2**CFG.numLanesLog2-1 generate
		cfg2any_laneIndex_voterarray: for j in 0 to 3 generate
			cfg2any_laneIndex_voter: entity work.tmr_voter
				port map (
					input_1		=> cfg2any_laneIndex_mv(0)(i)(j),
					--input_1		=> '0',
					input_2		=> cfg2any_laneIndex_mv(1)(i)(j),
					--input_2		=> '0',
					input_3		=> cfg2any_laneIndex_mv(2)(i)(j),
					--input_3		=> '0',
					output		=> cfg2any_laneIndex(i)(j)
				);
		end generate;
	end generate;
			

	---------------------------------------------------------------------------
    -- PC Majority voter bank for cfg2any_pcAddVal
    ---------------------------------------------------------------------------				
		
	cfg2any_pcAddVal_voterbank: for i in 0 to 2**CFG.numLanesLog2-1 generate
		cfg2any_pcAddVal_voterarray: for j in 0 to 31 generate
			cfg2any_pcAddVal_voter: entity work.tmr_voter
				port map (
					input_1		=> cfg2any_pcAddVal_mv(0)(i)(j),
					--input_1		=> '0',
					input_2		=> cfg2any_pcAddVal_mv(1)(i)(j),
					--input_2		=> '0',
					input_3		=> cfg2any_pcAddVal_mv(2)(i)(j),
					--input_3		=> '0',
					output		=> cfg2any_pcAddVal(i)(j)
				);
		end generate;
	end generate;
			
			

	---------------------------------------------------------------------------
    -- PC Majority voter bank for tmr_enable
    ---------------------------------------------------------------------------				
		
		tmr_enable_voter: entity work.tmr_voter
			port map (
				input_1		=> tmr_enable_mv(0),
				--input_1		=> '0',
				input_2		=> tmr_enable_mv(1),
				--input_2		=> '0',
				input_3		=> tmr_enable_mv(2),
				--input_3		=> '0',
				output		=> tmr_enable
			);
			

			
	---------------------------------------------------------------------------
    -- PC Majority voter bank for config_signal
    ---------------------------------------------------------------------------				
		
	config_signal_voterbank: for i in 0 to 3 generate
			config_signal_voter: entity work.tmr_voter
				port map (
					input_1		=> config_signal_mv(0)(i),
					--input_1		=> '0',
					input_2		=> config_signal_mv(1)(i),
					--input_2		=> '0',
					input_3		=> config_signal_mv(2)(i),
					--input_3		=> '0',
					output		=> config_signal(i)
				);
	end generate;
		




end structural;
			

