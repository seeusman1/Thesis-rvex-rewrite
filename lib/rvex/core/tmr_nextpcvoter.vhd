
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


--=============================================================================
entity tmr_nextpcvoter is
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
	  
	--Program counter value from cxplif to PC voter
    cxplif2nextpcvoter_nextPC    : in rvex_address_array(2**CFG.numContextsLog2-1 downto 0);
	  
	--Program counter value from PC voter to cxreg
    nextpcvoter2cxreg_nextPC      : out rvex_address_array(2**CFG.numContextsLog2-1 downto 0)
	  
  );

end entity tmr_nextpcvoter;
	

--=============================================================================
architecture structural of tmr_nextpcvoter is
--=============================================================================
	
	
	--add signals here
	signal start								: std_logic := '0';
	
	signal cxplif2nextpcvoter_nextPC_s			: rvex_address_array(2**CFG.numContextsLog2-1 downto 0);
	signal cxplif2nextpcvoter_nextPC_s_temp		: rvex_address_array(2**CFG.numContextsLog2-1 downto 0);

	signal cxplif2nextpcvoter_nextPC_s_result	: std_logic_vector (31 downto 0) := (others => '0');
	
	
	
--=============================================================================
begin -- architecture
--=============================================================================
		
	---------------------------------------------------------------------------
    -- stable start at rising edge of clock signal
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
    -- internal signals assignment
    ---------------------------------------------------------------------------					
	activelanes_selection: process(start, config_signal, cxplif2nextpcvoter_nextPC )
		variable index	: integer	:= 0;
	begin
				
		if start = '0' then
			cxplif2nextpcvoter_nextPC_s <= cxplif2nextpcvoter_nextPC;
			cxplif2nextpcvoter_nextPC_s_temp <= (others => (others => '0'));
			index := 0;
		else
			cxplif2nextpcvoter_nextPC_s <= (others => (others => '0'));
			cxplif2nextpcvoter_nextPC_s_temp <= (others => (others => '0'));
		
			for i in 0 to 3 loop
				if config_signal(i) = '1' then
					cxplif2nextpcvoter_nextPC_s_temp(index)	<= cxplif2nextpcvoter_nextPC(i);
					index := index + 1;
				end if;
			end loop;
			index	:= 0;
		end if;
	end process;
					
	---------------------------------------------------------------------------
    -- Next PC Majority voter bank between cxplif and cxreg
    ---------------------------------------------------------------------------				
		
	nextPCvoter: for i in 0 to 31 generate
		ft_voter: entity work.tmr_voter
			port map (
				input_1		=> cxplif2nextpcvoter_nextPC_s_temp(0)(i),
				input_2		=> cxplif2nextpcvoter_nextPC_s_temp(1)(i),
				input_3		=> cxplif2nextpcvoter_nextPC_s_temp(2)(i),
				output		=> cxplif2nextpcvoter_nextPC_s_result(i)
			);
	end generate;
	
		
	---------------------------------------------------------------------------
    -- Recreate next_PC value after voter bank
    ---------------------------------------------------------------------------			
		
		
	nextpc_result: process (start, config_signal, cxplif2nextpcvoter_nextPC_s, cxplif2nextpcvoter_nextPC_s_result)	
	begin
		if start = '0' then
			nextpcvoter2cxreg_nextPC	<=	cxplif2nextpcvoter_nextPC_s;
		else
			nextpcvoter2cxreg_nextPC	<=	(others => (others => '0'));
		
			for i in 0 to 3 loop
				nextpcvoter2cxreg_nextPC(i)	<=	cxplif2nextpcvoter_nextPC_s_result;
			end loop;
		end if;
	end process;
			
end structural;