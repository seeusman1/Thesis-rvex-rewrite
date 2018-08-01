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
	
  port	(
	  
	-- Active high synchronous reset input.
    reset                       : in  std_logic;
    
    -- Clock input
    clk                         : in  std_logic;
	  
	-- Active high fault tolerance enable  
	start_ft					: in std_logic;
	   
	-- Input Data to be corrupted  
	input						: in std_logic_Vector (31 downto 0);
	  
	-- Mask signal indicating location of error insertion  
	mask_signal					: in std_logic_vector (31 downto 0);
	  
    -- Output of Saboteur
	saboteur_out						  : out std_logic_vector(31 downto 0);
	  
	-- Indicates when fault is inserted 
	fault_inserted						  : out std_logic
	  
  );

end entity saboteur;
	

--=============================================================================
architecture structural of saboteur is
--=============================================================================

	signal start										: std_logic := '0';
	signal limit_flag									: std_logic := '0';
	signal count										: std_logic_vector (31 downto 0) := (others => '0');
	constant count_limit								: integer	:= 100;
   signal saboteur										: std_logic := '0';
	

--=============================================================================
begin -- architecture
--=============================================================================		
	

	-- Counter
	counter: process (clk) is
	begin
		if rising_edge (clk) then
			if reset = '1' then
				count	  	 <= (others => '0');
				saboteur	 <= '0';
			elsif start_ft='1'  then
				if (limit_flag = '1') then
					count 	 <= (others => '0');
					saboteur <= '1';
				else 
					count	 <= count + 1;
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
				
			
	saboteur_output: process (input, mask_signal, saboteur) is
	begin
		if saboteur = '0' then
			saboteur_out <= input;
		    fault_inserted <= '0';
		else
			saboteur_out <= input xor mask_signal;
			fault_inserted <= '1';
		end if;
	end process;
			
			
end structural;
			

