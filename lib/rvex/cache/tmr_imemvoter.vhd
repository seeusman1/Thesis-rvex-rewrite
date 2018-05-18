
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.common_pkg.all;
use work.utils_pkg.all;
use work.core_pkg.all;
use work.core_trap_pkg.all;
use work.cache_pkg.all;


--=============================================================================
entity tmr_imemvoter is
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
	  
	--signal representing which lanegroup among TMR will access caches  
	mask_signal					: in std_logic_vector (3 downto 0);
	  
	  
    -- Instruction memory interface.
 --   rv2icache_PCs               : in  rvex_address_array(2**RCFG.numLaneGroupsLog2-1 downto 0);
 --   rv2icache_fetch             : in  std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
 --   rv2icache_cancel            : in  std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
 --   icache2rv_instr             : out rvex_syllable_array(2**RCFG.numLanesLog2-1 downto 0);
 --   icache2rv_busFault          : out std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
 --   icache2rv_affinity          : out std_logic_vector(2**RCFG.numLaneGroupsLog2*RCFG.numLaneGroupsLog2-1 downto 0);
	  
	  
	---------------------------------------------------------------------------
    -- Signals that go into IMEM Majority voter
    ---------------------------------------------------------------------------  

    rv2tmr_PCs               	: in rvex_address_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    rv2tmr_fetch             	: in std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    rv2tmr_cancel            	: in std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    icache2tmr_instr            : in rvex_encoded_syllable_array(2**CFG.numLanesLog2-1 downto 0);
    icache2tmr_busFault         : in std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    icache2tmr_affinity         : in std_logic_vector(2**CFG.numLaneGroupsLog2*CFG.numLaneGroupsLog2-1 downto 0);	  
	  
	---------------------------------------------------------------------------
    -- Signals that come out of IMEM Majority voter
    ---------------------------------------------------------------------------  	  
	  
    tmr2icache_PCs              : out rvex_address_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    tmr2icache_fetch            : out std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    tmr2icache_cancel           : out std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    tmr2rv_instr             	: out rvex_encoded_syllable_array(2**CFG.numLanesLog2-1 downto 0);
    tmr2rv_busFault          	: out std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    tmr2rv_affinity          	: out std_logic_vector(2**CFG.numLaneGroupsLog2*CFG.numLaneGroupsLog2-1 downto 0)	  
	  
	  );
end entity tmr_imemvoter;
	
	

--=============================================================================
architecture structural of tmr_imemvoter is
--=============================================================================
		
	--add intermediate signals here, if any
	
	signal start				: std_logic	:= '0';

	--signals for PCs
	signal rv2tmr_PCs_s			: rvex_address_array(2**CFG.numLaneGroupsLog2-1 downto 0);
	signal rv2tmr_PCs_temp		: rvex_address_array(2**CFG.numLaneGroupsLog2-1 downto 0);
	signal rv2tmr_PCs_s_result	: std_logic_vector (31 downto 0) := (others => '0');

	--signals for fetch
	signal rv2tmr_fetch_s			: std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
	signal rv2tmr_fetch_temp		: std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
	signal rv2tmr_fetch_s_result	: std_logic := '0';


	--signals for cancel
	signal rv2tmr_cancel_s		: std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
	signal rv2tmr_cancel_temp		: std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
	signal rv2tmr_cancel_s_result	: std_logic := '0';

	
begin
			
	---------------------------------------------------------------------------
    -- update TMR mode activation signal at rising edge of clock signal
    ---------------------------------------------------------------------------	
	
	stable_start: process(clk)
	begin
		if rising_edge(clk) then
			if (reset = '1') then
				start <= '0';
			else
				start <= start_ft;
			end if;
		end if;
	end process;
	  --start <= start_ft;	
			
	---------------------------------------------------------------------------
    -- Internal signals assignment
    ---------------------------------------------------------------------------					
	activelanes_selection: process(start, config_signal, rv2tmr_PCs, rv2tmr_fetch, rv2tmr_cancel)
		variable index	: integer	:= 0;
	begin
				
		if start = '0' then
			
			--signals for PC
			rv2tmr_PCs_s 				<= rv2tmr_PCs;
			rv2tmr_PCs_temp  			<= (others => (others => '0'));

			--signals for fetch
			rv2tmr_fetch_s 			<= rv2tmr_fetch;
			rv2tmr_fetch_temp  		<= (others => '0');
			

			--signals for cancel
			rv2tmr_cancel_s 			<= rv2tmr_cancel;
			rv2tmr_cancel_temp  		<= (others => '0');


			--index to read only TMR lanegroups value in temp
			index := 0;
		else
			rv2tmr_PCs_s 				<= (others => (others => '0'));
			rv2tmr_PCs_temp  			<= (others => (others => '0'));

			rv2tmr_fetch_s 			<= (others => '0');
			rv2tmr_fetch_temp  		<= (others => '0');

			rv2tmr_cancel_s 			<= (others => '0');
			rv2tmr_cancel_temp  		<= (others => '0');

		
			for i in 0 to 3 loop
				if config_signal(i) = '1' then
					rv2tmr_PCs_temp(index)			<= rv2tmr_PCs(i);
					rv2tmr_fetch_temp(index)			<= rv2tmr_fetch(i);
					rv2tmr_cancel_temp(index)			<= rv2tmr_cancel(i);

					index := index + 1;
				end if;
			end loop;
			index	:= 0;
		end if;
	end process;			
					
			
			
	---------------------------------------------------------------------------
    -- Replication unit for Instruction read and exception from IMEM
    ---------------------------------------------------------------------------			
	replicate_instr: process (start, reset, icache2tmr_instr, config_signal, icache2tmr_busFault, icache2tmr_affinity)
	--variable mask_signal	: std_logic_vector (3 downto 0) := "0001";-- this signal tells which lanegroup will read from Imem before signals pass through rep unit
		
		begin
			
				if (start = '1') then
					for i in 0 to 3 loop
						if config_signal(i) = '1' then
							for j in 0 to 3 loop
								if mask_signal(j) = '1' then
									tmr2rv_instr (2*i) 	<= icache2tmr_instr(2*j);
									tmr2rv_instr (2*i+1)	<= icache2tmr_instr(2*j+1);
					
									tmr2rv_busFault (i) <= icache2tmr_busFault(j);
						
									tmr2rv_affinity (2*i) <= icache2tmr_affinity(2*j);
									tmr2rv_affinity (2*i+1) <= icache2tmr_affinity(2*j+1);
								end if;
							end loop;
						else
							tmr2rv_instr (2*i) 	<= icache2tmr_instr(2*i);
							tmr2rv_instr (2*i+1)  <= icache2tmr_instr(2*i+1);
		
						 	tmr2rv_busFault(i) <= icache2tmr_busFault(i);

							tmr2rv_affinity(2*i) <= icache2tmr_affinity(2*i);
							tmr2rv_affinity(2*i+1) <= icache2tmr_affinity(2*i+1);
						end if;
					end loop;
			else
				tmr2rv_instr <= icache2tmr_instr;
				tmr2rv_busFault <= icache2tmr_busFault;
				tmr2rv_affinity <= icache2tmr_affinity;
			end if;	
		end process;
				
		
	---------------------------------------------------------------------------
    -- Majority voter bank for PC
    ---------------------------------------------------------------------------				
		
	PC_voter: for i in 0 to 31 generate
		pc_voter_bank: entity work.tmr_voter
			port map (
				input_1		=> rv2tmr_PCs_temp(0)(i),
				--input_1		=> '0',
				input_2		=> rv2tmr_PCs_temp(1)(i),
				--input_2		=> '0',
				input_3		=> rv2tmr_PCs_temp(2)(i),
				--input_3		=> '0',
				output		=> rv2tmr_PCs_s_result(i)
			);
	end generate;
			

	---------------------------------------------------------------------------
    -- Majority voter bank fetch
    ---------------------------------------------------------------------------				
		
		fetch_voter: entity work.tmr_voter
			port map (
				input_1		=> rv2tmr_fetch_temp(0),
				--input_1		=> '0',
				input_2		=> rv2tmr_fetch_temp(1),
				--input_2		=> '0',
				input_3		=> rv2tmr_fetch_temp(2),
				--input_3		=> '0',
				output		=> rv2tmr_fetch_s_result
			);
			
			
			
	---------------------------------------------------------------------------
    -- Majority voter bank for cancel
    ---------------------------------------------------------------------------				
		
		cancel_voter: entity work.tmr_voter
			port map (
				input_1		=> rv2tmr_cancel_temp(0),
				--input_1		=> '0',
				input_2		=> rv2tmr_cancel_temp(1),
				--input_2		=> '0',
				input_3		=> rv2tmr_cancel_temp(2),
				--input_3		=> '0',
				output		=> rv2tmr_cancel_s_result
			);
			
			
			
			
	---------------------------------------------------------------------------
    -- Recreate DMEM address value after voter bank
    ---------------------------------------------------------------------------			
		
	addr_result: process (start, config_signal, rv2tmr_PCs_s, rv2tmr_PCs_s_result, rv2tmr_fetch_s, rv2tmr_fetch_s_result, rv2tmr_cancel_s, rv2tmr_cancel_s_result)	
	--variable mask_signal	: std_logic_vector (3 downto 0) := "0001";-- this signal tells which lanegroup will write to Imem after signals pass through mv
	begin
		if start = '0' then
			tmr2icache_PCs			<=	rv2tmr_PCs_s;
			tmr2icache_fetch		<=	rv2tmr_fetch_s;
			tmr2icache_cancel		<=	rv2tmr_cancel_s;

		else
			tmr2icache_PCs			<=	(others => (others => '0'));
			tmr2icache_fetch		<=	(others => '0');
			tmr2icache_cancel		<=	(others => '0');

		
			for i in 0 to 3 loop
				if config_signal(i) = '0' then
					tmr2icache_PCs(i)		<=	rv2tmr_PCs(i);
					tmr2icache_fetch(i)		<= rv2tmr_fetch(i);
					tmr2icache_cancel(i)	<= rv2tmr_cancel(i);
				else
					if mask_signal(i) = '1' then
						tmr2icache_PCs(i)	<=	rv2tmr_PCs_s_result;
						tmr2icache_fetch(i)	<= rv2tmr_fetch_s_result;
						tmr2icache_cancel(i)<= rv2tmr_cancel_s_result;
					end if;
				end if;
			end loop;



		end if;
	end process;				
				

    --tmr2icache_PCs           <= rv2tmr_PCs;
    --tmr2icache_fetch         <= rv2tmr_fetch;
    --tmr2icache_cancel        <= rv2tmr_cancel;
    --tmr2rv_instr             <= icache2tmr_instr;
    --tmr2rv_busFault          <= icache2tmr_busFault;
    --tmr2rv_affinity          <= icache2tmr_affinity;
						
						
end structural;
						
						