library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;

library work;
use work.common_pkg.all;
use work.utils_pkg.all;
use work.core_pkg.all;
use work.core_intIface_pkg.all;
use work.core_pipeline_pkg.all;


--=============================================================================
entity saboteur is
--=============================================================================
	
 -- generic (
    
    -- Configuration.
 --   CFG                         : rvex_generic_config_type 
 -- );


  port	(
	  
	-- Active high synchronous reset input.
    reset                       : in  std_logic;
    
    -- Clock input, registers are rising edge triggered.
    clk                         : in  std_logic;
    
    -- Active high global clock enable input.
   -- clkEn                       : in  std_logic := '1';
	  
	--Active high fault tolerance enable  
	start_ft					: in std_logic;
	  
	--signal representing active pipelane groups for fault tolerance mode
--	config_signal				: in std_logic_vector (3 downto 0); 
	  

    -- Signals that come out of GPREG Majority voter
	saboteur						  : out std_logic
	--count1							  : out std_logic_vector(31 downto 0)
	  
  );

end entity saboteur;
	

--=============================================================================
architecture structural of saboteur is
--=============================================================================
	
	
	--add signals here
	signal start										: std_logic := '0';
	signal start_array									: std_logic_vector (0 downto 0) := (others => '0');
	signal limit_flag									: std_logic := '0';
	signal count										: std_logic_vector (31 downto 0) := (others => '0');
	constant count_limit								: integer	:= 100 ;
	

--=============================================================================
begin -- architecture
--=============================================================================		
	

	-- Counter
	counter: process (clk) is
	begin
		if rising_edge (clk) then
			if reset = '1' then
				count	   <= (others => '0');
				saboteur	<= '0';
			elsif start_ft='1'  then
				if (limit_flag = '1') then
					count <= (others => '0');
					saboteur <= '1';
				else 
					count	<= count + 1;
					saboteur <= '0';
				end if;
			else
				count <= (others => '0');
				saboteur <= '0';
			end if;
		end if;
	end process;
			
	countlimit: process (start_ft, count) is
	begin
		if start_ft = '1' then
			if count = std_logic_vector(to_unsigned(count_limit, 32)) then
				limit_flag <= '1';
			else
				limit_flag <= '0';
			end if;
		else
			limit_flag <= '0';
		end if;
		
	end process;
		
	--count1 <= count;
end structural;
			

