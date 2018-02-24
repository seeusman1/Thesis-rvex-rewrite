
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.common_pkg.all;
use work.utils_pkg.all;
use work.core_pkg.all;
--use work.core_intIface_pkg.all;
use work.core_trap_pkg.all;
--use work.core_pipeline_pkg.all;
--use work.core_ctrlRegs_pkg.all;


entity tmr_InsRep is 
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
    -- Signals that go into IMEM Majority voter
    ---------------------------------------------------------------------------  
		  
	ibuf2tmr_PCs       			: in  rvex_address_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    ibuf2tmr_fetch     			: in std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    ibuf2tmr_cancel    			: in std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
	imem2tmr_instr				: in rvex_syllable_array(2**CFG.numLanesLog2-1 downto 0);  
	imem2tmr_exception			: in trap_info_array(2**CFG.numLaneGroupsLog2-1 downto 0);
	  
	  
	---------------------------------------------------------------------------
    -- Signals that come out of IMEM Majority voter
    ---------------------------------------------------------------------------  
	  
	
	tmr2imem_PCs       			: out rvex_address_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    tmr2imem_fetch     			: out std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    tmr2imem_cancel    			: out std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
	tmr2ibuf_instr				: out rvex_syllable_array(2**CFG.numLanesLog2-1 downto 0);
	tmr2ibuf_exception			: out trap_info_array(2**CFG.numLaneGroupsLog2-1 downto 0)
	  );
end entity tmr_InsRep;
	
	
	
	architecture structural of tmr_InsRep is
		
	--add intermediate signals here, if any
	
	signal start		: std_logic	:= '0';

	--signals for PCs
	signal ibuf2tmr_PCs_s			: rvex_address_array(2**CFG.numLaneGroupsLog2-1 downto 0);
	signal ibuf2tmr_PCs_temp		: rvex_address_array(2**CFG.numLaneGroupsLog2-1 downto 0);
	signal ibuf2tmr_PCs_s_result	: std_logic_vector (31 downto 0) := (others => '0');

	--signals for fetch
	signal ibuf2tmr_fetch_s			: std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
	signal ibuf2tmr_fetch_temp		: std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
	signal ibuf2tmr_fetch_s_result	: std_logic := '0';


	--signals for cancel
	signal ibuf2tmr_cancel_s		: std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
	signal ibuf2tmr_cancel_temp		: std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
	signal ibuf2tmr_cancel_s_result	: std_logic := '0';



		
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
				
			
	---------------------------------------------------------------------------
    -- Internal signals assignment
    ---------------------------------------------------------------------------					
	activelanes_selection: process(start, config_signal, ibuf2tmr_PCs, ibuf2tmr_fetch, ibuf2tmr_cancel)
		variable index	: integer	:= 0;
	begin
				
		if start = '0' then
			
			--signals for PC
			ibuf2tmr_PCs_s 				<= ibuf2tmr_PCs;
			ibuf2tmr_PCs_temp  			<= (others => (others => '0'));

			--signals for fetch
			ibuf2tmr_fetch_s 			<= ibuf2tmr_fetch;
			ibuf2tmr_fetch_temp  		<= (others => '0');
			

			--signals for cancel
			ibuf2tmr_cancel_s 			<= ibuf2tmr_cancel;
			ibuf2tmr_cancel_temp  		<= (others => '0');


			--index to read only active lanegroups value in temp
			index := 0;
		else
			ibuf2tmr_PCs_s 				<= (others => (others => '0'));
			ibuf2tmr_PCs_temp  			<= (others => (others => '0'));

			ibuf2tmr_fetch_s 			<= (others => '0');
			ibuf2tmr_fetch_temp  		<= (others => '0');

			ibuf2tmr_cancel_s 			<= (others => '0');
			ibuf2tmr_cancel_temp  		<= (others => '0');

		
			for i in 0 to 3 loop
				if config_signal(i) = '1' then
					ibuf2tmr_PCs_temp(index)			<= ibuf2tmr_PCs(i);
					ibuf2tmr_fetch_temp(index)			<= ibuf2tmr_fetch(i);
					ibuf2tmr_cancel_temp(index)			<= ibuf2tmr_cancel(i);

					index := index + 1;
				end if;
			end loop;
			index	:= 0;
		end if;
	end process;			
					
			
			
	---------------------------------------------------------------------------
    -- Replication unit for Instruction read from IMEM
    ---------------------------------------------------------------------------			
	replicate_instr: process (start, reset, imem2tmr_instr, config_signal)
		
		begin
			
			--if (start = '1' and reset = '0') then
				if (start = '1') then
					for i in 0 to 3 loop
						if config_signal(i) = '1' then
						--if temp(i) = '1' then
							tmr2ibuf_instr (2*i) <= imem2tmr_instr(0);
							tmr2ibuf_instr (2*i + 1) <= imem2tmr_instr(1);
						else
						-- NOP instruction for disabled core, NOP instruction's 29th and 30th bit is high
					    	tmr2ibuf_instr (2*i) <= (others => '0');
							tmr2ibuf_instr (2*i)(30) <= '1';
							tmr2ibuf_instr (2*i)(29) <= '1';
							tmr2ibuf_instr (2*i+1) <= (others => '0');
							tmr2ibuf_instr (2*i+1)(30) <= '1';
							tmr2ibuf_instr (2*i+1)(29) <= '1';
						end if;
					end loop;
			else
				tmr2ibuf_instr <= imem2tmr_instr;
			end if;	
		end process;
				
				
	---------------------------------------------------------------------------
    -- Replication unit for exception from IMEM
    ---------------------------------------------------------------------------			
	replicate_exception: process (start, reset, imem2tmr_exception, config_signal)
		
		begin
			
			--if (start = '1' and reset = '0') then
				if (start = '1') then
					for i in 0 to 3 loop
						if config_signal(i) = '1' then
						--if temp(i) = '1' then
							tmr2ibuf_exception (i) <= imem2tmr_exception(0);
						else
						-- for disabled core, exception is set to default value
							 tmr2ibuf_exception (i)  <= ( active => '0',
    													  cause  => (others => '0'),
    													  arg    => (others => '0')
  														);
						end if;
					end loop;
			else
				tmr2ibuf_exception <= imem2tmr_exception;
			end if;	
		end process;				

		
	---------------------------------------------------------------------------
    -- Majority voter bank for PC
    ---------------------------------------------------------------------------				
		
	PC_voter: for i in 0 to 31 generate
		pc_voter_bank: entity work.tmr_voter
			port map (
				input_1		=> ibuf2tmr_PCs_temp(0)(i),
				--input_1		=> '0',
				input_2		=> ibuf2tmr_PCs_temp(1)(i),
				--input_2		=> '0',
				input_3		=> ibuf2tmr_PCs_temp(2)(i),
				--input_3		=> '0',
				output		=> ibuf2tmr_PCs_s_result(i)
			);
	end generate;
			

	---------------------------------------------------------------------------
    -- Majority voter bank fetch
    ---------------------------------------------------------------------------				
		
		fetch_voter: entity work.tmr_voter
			port map (
				input_1		=> ibuf2tmr_fetch_temp(0),
				--input_1		=> '0',
				input_2		=> ibuf2tmr_fetch_temp(1),
				--input_2		=> '0',
				input_3		=> ibuf2tmr_fetch_temp(2),
				--input_3		=> '0',
				output		=> ibuf2tmr_fetch_s_result
			);
			
			
			
	---------------------------------------------------------------------------
    -- Majority voter bank for cancel
    ---------------------------------------------------------------------------				
		
		cancel_voter: entity work.tmr_voter
			port map (
				input_1		=> ibuf2tmr_cancel_temp(0),
				--input_1		=> '0',
				input_2		=> ibuf2tmr_cancel_temp(1),
				--input_2		=> '0',
				input_3		=> ibuf2tmr_cancel_temp(2),
				--input_3		=> '0',
				output		=> ibuf2tmr_cancel_s_result
			);
			
			
			
			
	---------------------------------------------------------------------------
    -- Recreate DMEM address value after voter bank
    ---------------------------------------------------------------------------			
		
	addr_result: process (start, config_signal, ibuf2tmr_PCs_s, ibuf2tmr_PCs_s_result, ibuf2tmr_fetch_s, ibuf2tmr_fetch_s_result, ibuf2tmr_cancel_s, ibuf2tmr_cancel_s_result)	
	begin
		if start = '0' then
			tmr2imem_PCs			<=	ibuf2tmr_PCs_s;
			tmr2imem_fetch			<= ibuf2tmr_fetch_s;
			tmr2imem_cancel			<= ibuf2tmr_cancel_s;

		else
			tmr2imem_PCs			<=	(others => (others => '0'));
			tmr2imem_fetch			<= (others => '0');
			tmr2imem_cancel			<= (others => '0');

		
			--for i in 0 to 3 loop
			--	tmr2imem_PCs(i)		<=	ibuf2tmr_PCs_s_result;
			--	tmr2imem_fetch(i)	<= ibuf2tmr_fetch_s_result;
			--	tmr2imem_cancel(i)	<= ibuf2tmr_cancel_s_result;
			--end loop;

				tmr2imem_PCs(0)	  <=	ibuf2tmr_PCs_s_result;
				tmr2imem_fetch(0)	  <= ibuf2tmr_fetch_s_result;
				tmr2imem_cancel(0)  <= ibuf2tmr_cancel_s_result;



		end if;
	end process;				
				
						
		--tmr2imem_PCs       			<= ibuf2tmr_PCs;
    	--tmr2imem_fetch     			<= ibuf2tmr_fetch;
    	--tmr2imem_cancel    			<= ibuf2tmr_cancel;
		--tmr2ibuf_instr				<= imem2tmr_instr;
		--tmr2ibuf_exception			<= imem2tmr_exception;
						
	end structural;
						
						