
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.common_pkg.all;
use work.utils_pkg.all;
use work.core_pkg.all;
--use work.core_intIface_pkg.all;
--use work.core_trap_pkg.all;
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
    
    -- This signal is asserted high when the debug bus writes a one to the
    -- reset flag in the control registers. In this case, reset is already
    -- asserted internally, so this signal may be ignored. For more complex
    -- systems, the signal may be used to reset support systems as well.
    resetOut                    : out std_logic;
    
    -- Clock input, registers are rising edge triggered.
    clk                         : in  std_logic;
    
    -- Active high global clock enable input.
    clkEn                       : in  std_logic := '1';
	  
	  
	 --Active high fault tolerance enable  
	 start_ft					: in std_logic;
	  
	  --signal representing active pipelane groups for fault tolerance mode
	 config_signal				: in std_logic_vector (3 downto 0);
	  
	  --input instructions to be replicated
	 instr_in					: in rvex_syllable_array(2**CFG.numLanesLog2-1 downto 0);
	  
	  
	  --replicated instructions
	 instr_out					: out rvex_syllable_array(2**CFG.numLanesLog2-1 downto 0)
	  
	  
	  );
end entity tmr_InsRep;
	
	
	
	architecture structural of tmr_InsRep is
		
	--add intermediate signals here, if any
	
	--signal temp 	: std_logic_vector (3 downto 0)	:= "1111";
	--signal st		: std_logic	:= '1';
		
		
	begin
		
	replicate_instr: process (start_ft, reset, instr_in, config_signal)
		
		begin
			
			--if (start_ft = '1' and reset = '0') then
			--	if (start_ft = '1') then
			--	for i in 0 to 3 loop
					--if config_signal(i) = '1' then
			--		if temp(i) = '1' then
			--			instr_out (2*i) <= instr_in(0);
			--			instr_out (2*i + 1) <= instr_in(1);
				
			--		else
						-- NOP instruction for disabled core, NOP instruction's 29th and 30th bit is high
			--		    instr_out (2*i) <= (others => '0');
			--			instr_out (2*i)(30) <= '1';
			--			instr_out (2*i)(29) <= '1';
			--			instr_out (2*i+1) <= (others => '0');
			--			instr_out (2*i+1)(30) <= '1';
			--			instr_out (2*i+1)(29) <= '1';
			--		end if;
			--	end loop;

		--	else
				instr_out <= instr_in;
		--	end if;
				
				
				
				
				
				
		end process;
						
	end structural;
						
						