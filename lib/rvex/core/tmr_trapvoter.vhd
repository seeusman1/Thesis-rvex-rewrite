
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.common_pkg.all;
use work.utils_pkg.all;
use work.core_pkg.all;
use work.core_intIface_pkg.all;
use work.core_trap_pkg.all;
--use work.core_pipeline_pkg.all;
--use work.core_ctrlRegs_pkg.all;


--=============================================================================
entity tmr_trapvoter is
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
    -- Signals that go into Trap Majority voter
    ---------------------------------------------------------------------------
	  
    -- Indicates whether an exception is active for each pipeline stage and
    -- lane and if so, which.
    pl2tmrvoter_trap                  : in  trap_info_stages_array(2**CFG.numLanesLog2-1 downto 0);
    
    -- Trap information record from the final pipeline stage, combined from all
    -- coupled pipelines.
    trap2tmrvoter_trapToHandle        : in trap_info_array(2**CFG.numLanesLog2-1 downto 0);
    
    -- Whether a trap is in the pipeline somewhere. When this is high,
    -- instruction fetching can be halted to speed things up.
    trap2tmrvoter_trapPending         : in std_logic_vector(2**CFG.numLanesLog2-1 downto 0);
    
    -- Trap disable outputs. When high, any trap caused by the instruction in
    -- the respective stage/lane should be disabled/ignored, which happens when
    -- an earlier instruction in a coupled lane is causing a trap.
    trap2tmrvoter_disable             : in std_logic_stages_array(2**CFG.numLanesLog2-1 downto 0);
    
    -- Stage flushing outputs. When high, the instruction in the respective
    -- stage/lane should no longer be committed/be deactivated.
    trap2tmrvoter_flush               : in std_logic_stages_array(2**CFG.numLanesLog2-1 downto 0);
	  
	  
	---------------------------------------------------------------------------
    -- Signals that come out of Trap Majority voter
    ---------------------------------------------------------------------------

    -- Indicates whether an exception is active for each pipeline stage and
    -- lane and if so, which.
    tmrvoter2trap_trap                : out  trap_info_stages_array(2**CFG.numLanesLog2-1 downto 0);
    
    -- Trap information record from the final pipeline stage, combined from all
    -- coupled pipelines.
    tmrvoter2pl_trapToHandle          : out trap_info_array(2**CFG.numLanesLog2-1 downto 0);
    
    -- Whether a trap is in the pipeline somewhere. When this is high,
    -- instruction fetching can be halted to speed things up.
    tmrvoter2pl_trapPending           : out std_logic_vector(2**CFG.numLanesLog2-1 downto 0);
    
    -- Trap disable outputs. When high, any trap caused by the instruction in
    -- the respective stage/lane should be disabled/ignored, which happens when
    -- an earlier instruction in a coupled lane is causing a trap.
    tmrvoter2pl_disable               : out std_logic_stages_array(2**CFG.numLanesLog2-1 downto 0);
    
    -- Stage flushing outputs. When high, the instruction in the respective
    -- stage/lane should no longer be committed/be deactivated.
    tmrvoter2pl_flush                 : out std_logic_stages_array(2**CFG.numLanesLog2-1 downto 0)
    
	  
  );

end entity tmr_trapvoter;
	

--=============================================================================
architecture structural of tmr_trapvoter is
--=============================================================================
	
	constant zero_init_trap_info_type				: trap_info_type := ( active => '0',
														   				  cause => (others => '0'),
														   				  arg => (others => '0')
														  				);
	
	
	--add signals here
	signal start									: std_logic := '0';
	signal start_array								: std_logic_vector (0 downto 0) := (others => '0');


	--Internal signals for trap
    signal pl2tmrvoter_trap_s                		: trap_info_stages_array(2**CFG.numLanesLog2-1 downto 0);
    signal pl2tmrvoter_trap_temp                	: trap_info_stages_array(2**CFG.numLanesLog2-1 downto 0);
    signal pl2tmrvoter_trap_s_result                : trap_info_stages_type; -- initialize to zeros

	--Internal signals for trapToHandle
    signal trap2tmrvoter_trapToHandle_s        		: trap_info_array(2**CFG.numLanesLog2-1 downto 0);
    signal trap2tmrvoter_trapToHandle_temp        	: trap_info_array(2**CFG.numLanesLog2-1 downto 0);
    signal trap2tmrvoter_trapToHandle_s_result_even : trap_info_type := zero_init_trap_info_type; 
    signal trap2tmrvoter_trapToHandle_s_result_odd  : trap_info_type := zero_init_trap_info_type; 

	--Internal signals for trapPending
    signal trap2tmrvoter_trapPending_s         		: std_logic_vector(2**CFG.numLanesLog2-1 downto 0);
    signal trap2tmrvoter_trapPending_temp         	: std_logic_vector(2**CFG.numLanesLog2-1 downto 0);
    signal trap2tmrvoter_trapPending_s_result_even  : std_logic := '0';
    signal trap2tmrvoter_trapPending_s_result_odd   : std_logic := '0';

	--Internal signals for disable
    signal trap2tmrvoter_disable_s            		: std_logic_stages_array(2**CFG.numLanesLog2-1 downto 0);
    signal trap2tmrvoter_disable_temp            	: std_logic_stages_array(2**CFG.numLanesLog2-1 downto 0);
    signal trap2tmrvoter_disable_s_result           : std_logic_stages_type; -- initialize to zeros

	--Internal signals for flush
    signal trap2tmrvoter_flush_s               		: std_logic_stages_array(2**CFG.numLanesLog2-1 downto 0);
    signal trap2tmrvoter_flush_temp               	: std_logic_stages_array(2**CFG.numLanesLog2-1 downto 0);
    signal trap2tmrvoter_flush_s_result             : std_logic_stages_type; -- initialize to zeros


	
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
				start_array(0) <= '0';
			else
  		        start_array(0) <= start_ft;
			end if;

		end if;
	end process;
		

	---------------------------------------------------------------------------
    -- internal signals assignment
    ---------------------------------------------------------------------------					
	activelanes_selection: process(start_array, config_signal, trap2tmrvoter_trapToHandle, trap2tmrvoter_trapPending)
		variable index	: integer	:= 0;
	begin
				
		if start_array(0) = '0' then
			--signals for trapToHandle
			trap2tmrvoter_trapToHandle_s 			<= trap2tmrvoter_trapToHandle;
			trap2tmrvoter_trapToHandle_temp  		<= (others => zero_init_trap_info_type); 
		
			trap2tmrvoter_trapPending_s				<= trap2tmrvoter_trapPending;
			trap2tmrvoter_trapPending_temp			<= (others => '0');
			

			--index to read only active lanegroups value in temp
			index := 0;
		else
			trap2tmrvoter_trapToHandle_s 			<= (others => zero_init_trap_info_type); 
			trap2tmrvoter_trapToHandle_temp  		<= (others => zero_init_trap_info_type); 

			trap2tmrvoter_trapPending_s				<= (others => '0');
			trap2tmrvoter_trapPending_temp			<= (others => '0');
	
			for i in 0 to 3 loop
				if config_signal(i) = '1' then
					trap2tmrvoter_trapToHandle_temp(2*index)			    <= trap2tmrvoter_trapToHandle(2*i);
					trap2tmrvoter_trapToHandle_temp(2*index+1)			    <= trap2tmrvoter_trapToHandle(2*i+1);

					trap2tmrvoter_trapPending_temp(2*index)					<= trap2tmrvoter_trapPending(2*i);
					trap2tmrvoter_trapPending_temp(2*index+1)				<= trap2tmrvoter_trapPending(2*i+1);

					index := index + 1;
				end if;
			end loop;
			index	:= 0;
		end if;
	end process;
					

	---------------------------------------------------------------------------
    -- PC Majority voter bank for trapToHandle
    ---------------------------------------------------------------------------		
			
	-- PC Majority voter bank for trapToHandle.active-even pipelanes			
	trapToHandle_active_even_voter: entity work.tmr_voter
				port map (
					input_1		=> trap2tmrvoter_trapToHandle_temp(0).active,
					--input_1		=> '0',
					input_2		=> trap2tmrvoter_trapToHandle_temp(2).active,
					--input_2		=> '0',
					input_3		=> trap2tmrvoter_trapToHandle_temp(4).active,
					--input_3		=> '0',
					output		=> trap2tmrvoter_trapToHandle_s_result_even.active
				);

	

    -- PC Majority voter bank for trapToHandle.active-odd pipelanes
	trapToHandle_active_odd_voter: entity work.tmr_voter
				port map (
					input_1		=> trap2tmrvoter_trapToHandle_temp(1).active,
					--input_1		=> '0',
					input_2		=> trap2tmrvoter_trapToHandle_temp(3).active,
					--input_2		=> '0',
					input_3		=> trap2tmrvoter_trapToHandle_temp(5).active,
					--input_3		=> '0',
					output		=> trap2tmrvoter_trapToHandle_s_result_odd.active
				);

		

    -- PC Majority voter bank for trapToHandle.cause-even pipelanes		
	trapToHandle_cause_even_voter: for i in 0 to RVEX_TRAP_CAUSE_SIZE-1 generate
			cause_even_voter_bank: entity work.tmr_voter
				port map (
					input_1		=> trap2tmrvoter_trapToHandle_temp(0).cause(i),
					--input_1		=> '0',
					input_2		=> trap2tmrvoter_trapToHandle_temp(2).cause(i),
					--input_2		=> '0',
					input_3		=> trap2tmrvoter_trapToHandle_temp(4).cause(i),
					--input_3		=> '0',
					output		=> trap2tmrvoter_trapToHandle_s_result_even.cause(i)
				);
	end generate;
	

    -- PC Majority voter bank for trapToHandle.cause-odd pipelanes	
	trapToHandle_cause_odd_voter: for i in 0 to RVEX_TRAP_CAUSE_SIZE-1 generate
			cause_odd_voter_bank: entity work.tmr_voter
				port map (
					input_1		=> trap2tmrvoter_trapToHandle_temp(1).cause(i),
					--input_1		=> '0',
					input_2		=> trap2tmrvoter_trapToHandle_temp(3).cause(i),
					--input_2		=> '0',
					input_3		=> trap2tmrvoter_trapToHandle_temp(5).cause(i),
					--input_3		=> '0',
					output		=> trap2tmrvoter_trapToHandle_s_result_odd.cause(i)
				);
	end generate;
		
					
			

    -- PC Majority voter bank for trapToHandle.arg-even pipelanes			
	trapToHandle_arg_even_voter: for i in 0 to 31 generate
			arg_even_voter_bank: entity work.tmr_voter
				port map (
					input_1		=> trap2tmrvoter_trapToHandle_temp(0).arg(i),
					--input_1		=> '0',
					input_2		=> trap2tmrvoter_trapToHandle_temp(2).arg(i),
					--input_2		=> '0',
					input_3		=> trap2tmrvoter_trapToHandle_temp(4).arg(i),
					--input_3		=> '0',
					output		=> trap2tmrvoter_trapToHandle_s_result_even.arg(i)
				);
	end generate;
	

    -- PC Majority voter bank for trapToHandle.arg-odd pipelanes	
	trapToHandle_arg_odd_voter: for i in 0 to 31 generate
			arg_odd_voter_bank: entity work.tmr_voter
				port map (
					input_1		=> trap2tmrvoter_trapToHandle_temp(1).arg(i),
					--input_1		=> '0',
					input_2		=> trap2tmrvoter_trapToHandle_temp(3).arg(i),
					--input_2		=> '0',
					input_3		=> trap2tmrvoter_trapToHandle_temp(5).arg(i),
					--input_3		=> '0',
					output		=> trap2tmrvoter_trapToHandle_s_result_odd.arg(i)
				);
	end generate;
		

				
	---------------------------------------------------------------------------
    -- PC Majority voter bank for trapPending
    ---------------------------------------------------------------------------	
				
		-- PC Majority voter bank for trapPending-even pipelanes
		trapPending_even_voter: entity work.tmr_voter
			port map (
				input_1		=> trap2tmrvoter_trapPending_temp(0),
				--input_1		=> '0',
				input_2		=> trap2tmrvoter_trapPending_temp(1),
				--input_2		=> '0',
				input_3		=> trap2tmrvoter_trapPending_temp(2),
				--input_3		=> '0',
				output		=> trap2tmrvoter_trapPending_s_result_even
			);
							
		-- PC Majority voter bank for trapPending-odd pipelanes
		trapPending_odd_voter: entity work.tmr_voter
			port map (
				input_1		=> trap2tmrvoter_trapPending_temp(0),
				--input_1		=> '0',
				input_2		=> trap2tmrvoter_trapPending_temp(1),
				--input_2		=> '0',
				input_3		=> trap2tmrvoter_trapPending_temp(2),
				--input_3		=> '0',
				output		=> trap2tmrvoter_trapPending_s_result_odd
			);
				
	---------------------------------------------------------------------------
    -- Recreate trap signals after voter bank
    ---------------------------------------------------------------------------			
		
	addr_result: process (start_array, config_signal, trap2tmrvoter_trapToHandle_s, trap2tmrvoter_trapToHandle_s_result_even, trap2tmrvoter_trapToHandle_s_result_odd,
						 trap2tmrvoter_trapPending_s, trap2tmrvoter_trapPending_s_result_even, trap2tmrvoter_trapPending_s_result_odd)	
	begin
		if start_array(0) = '0' then
			tmrvoter2pl_trapToHandle				<=	trap2tmrvoter_trapToHandle_s;
			tmrvoter2pl_trapPending					<= trap2tmrvoter_trapPending_s;

		else
			tmrvoter2pl_trapToHandle				<=	(others => zero_init_trap_info_type);
			tmrvoter2pl_trapPending					<=  (others => '0');
		
			for i in 0 to 3 loop
				if config_signal(i) = '1' then
				tmrvoter2pl_trapToHandle(2*i)			<=	trap2tmrvoter_trapToHandle_s_result_even;
				tmrvoter2pl_trapToHandle(2*i+1)			<=	trap2tmrvoter_trapToHandle_s_result_odd;

				tmrvoter2pl_trapPending(2*i)			<=  trap2tmrvoter_trapPending_s_result_even;
				tmrvoter2pl_trapPending(2*1+1)			<=  trap2tmrvoter_trapPending_s_result_odd;

				end if;
			end loop;
					

		end if;
	end process;
				
			
			


    tmrvoter2trap_trap               <= pl2tmrvoter_trap;
--    tmrvoter2pl_trapToHandle         <= trap2tmrvoter_trapToHandle;
--    tmrvoter2pl_trapPending          <= trap2tmrvoter_trapPending;
    tmrvoter2pl_disable              <= trap2tmrvoter_disable;
    tmrvoter2pl_flush                <= trap2tmrvoter_flush;


end structural;
				