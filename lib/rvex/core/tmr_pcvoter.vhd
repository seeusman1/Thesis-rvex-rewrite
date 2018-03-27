
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.common_pkg.all;
use work.utils_pkg.all;
use work.core_pkg.all;

--=============================================================================
entity tmr_pcvoter is
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
	  
	--Program counter value from br to cxplif
    br2pcvoter_PC    			: in rvex_address_array(2**CFG.numLanesLog2-1 downto 0);
	  
	--Program counter value from PC voter to cxplif
    pcvoter2cxplif_PC      		: out rvex_address_array(2**CFG.numLanesLog2-1 downto 0)
	  
  );

end entity tmr_pcvoter;
	

--=============================================================================
architecture structural of tmr_pcvoter is
--=============================================================================
	
	
	--add signals here
	signal start						: std_logic := '0';
	
	signal br2pcvoter_PC_s				: rvex_address_array(2**CFG.numLanesLog2-1 downto 0);
	signal br2pcvoter_PC_s_temp			: rvex_address_array(2**CFG.numLanesLog2-1 downto 0);

	signal br2pcvoter_PC_s_result_even	: std_logic_vector (31 downto 0) := (others => '0');
	signal br2pcvoter_PC_s_result_odd	: std_logic_vector (31 downto 0) := (others => '0');
	
	
	
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
	activelanes_selection: process(start, config_signal, br2pcvoter_PC)
		variable index	: integer	:= 0;
	begin
				
		if start = '0' then
			br2pcvoter_PC_s <= br2pcvoter_PC;
			br2pcvoter_PC_s_temp <= (others => (others => '0'));
			index := 0;
		else
			br2pcvoter_PC_s <= (others => (others => '0'));
			br2pcvoter_PC_s_temp <= (others => (others => '0'));
		
			for i in 0 to 3 loop
				if config_signal(i) = '1' then
					br2pcvoter_PC_s_temp(2*index)	<= br2pcvoter_PC(2*i); 
					br2pcvoter_PC_s_temp(2*index+1)	<= br2pcvoter_PC(2*i+1);
					index := index + 1;
				end if;
			end loop;
			index	:= 0;
		end if;
	end process;
					
	---------------------------------------------------------------------------
    -- PC Majority voter bank between br and cxplif 
    ---------------------------------------------------------------------------				
		
	PCvoter_even: for i in 0 to 31 generate
		ft_voter_bank_even: entity work.tmr_voter
			port map (
				input_1		=> br2pcvoter_PC_s_temp(0)(i),
				--input_1		=> '0',
				input_2		=> br2pcvoter_PC_s_temp(2)(i),
				--input_2		=> '0',
				input_3		=> br2pcvoter_PC_s_temp(4)(i),
				--input_3		=> '0',
				output		=> br2pcvoter_PC_s_result_even(i)
			);
	end generate;
	
			
	PCvoter_odd: for i in 0 to 31 generate
		ft_voter_bank_odd: entity work.tmr_voter
			port map (
				input_1		=> br2pcvoter_PC_s_temp(1)(i),
				--input_1		=> '0',
				input_2		=> br2pcvoter_PC_s_temp(3)(i),
				--input_2		=> '0',
				input_3		=> br2pcvoter_PC_s_temp(5)(i),
				--input_3		=> '0',
				output		=> br2pcvoter_PC_s_result_odd(i)
			);
	end generate;		
			
	
		
	---------------------------------------------------------------------------
    -- Recreate PC value after voter bank
    ---------------------------------------------------------------------------			
		
		
	pc_result: process (start, config_signal, br2pcvoter_PC_s, br2pcvoter_PC_s_result_even, br2pcvoter_PC_s_result_odd)	
	begin
		if start = '0' then
			pcvoter2cxplif_PC	<=	br2pcvoter_PC_s;
		else
			pcvoter2cxplif_PC	<=	(others => (others => '0'));
		
			for i in 0 to 3 loop
				if config_signal(i) = '1' then
					pcvoter2cxplif_PC(2*i)		<=	br2pcvoter_PC_s_result_even;
					pcvoter2cxplif_PC(2*i+1)	<=	br2pcvoter_PC_s_result_odd;
				else
					pcvoter2cxplif_PC(2*i)		<=	br2pcvoter_PC(2*i);
					pcvoter2cxplif_PC(2*i+1)	<=	br2pcvoter_PC(2*i+1);					
				end if;
			end loop;
		end if;
	end process;
			
end structural;