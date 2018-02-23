
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
					    	--tmr2ibuf_exception (i) <= (others => '0');
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

				
				
		tmr2imem_PCs       			<= ibuf2tmr_PCs;
    	tmr2imem_fetch     			<= ibuf2tmr_fetch;
    	tmr2imem_cancel    			<= ibuf2tmr_cancel;
		--tmr2ibuf_instr					<= imem2tmr_instr;
		--tmr2ibuf_exception			<= imem2tmr_exception;
						
	end structural;
						
						