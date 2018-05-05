library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
--use work.common_pkg.all;
--use work.utils_pkg.all;
--use work.core_pkg.all;
--use work.core_intIface_pkg.all;
--use work.core_pipeline_pkg.all;
--use work.bus_pkg.all;
--use work.cache_pkg.all;


--=============================================================================
entity cache_blockTag_voter is
--=============================================================================
	


  port	(
	  
    ---------------------------------------------------------------------------
    -- Signals that go into cache_blockTag_voter
    ---------------------------------------------------------------------------
    cpuHit_mv					: in std_logic_vector (2 downto 0);
	invalHit_mv					: in std_logic_vector (2 downto 0);
	  
	---------------------------------------------------------------------------
    -- Signals that come out of cache_blockTag_voter
    ---------------------------------------------------------------------------
	cpuHit						: out std_logic;
	invalHit					: out std_logic
	  
  );

end entity cache_blockTag_voter;
	

--=============================================================================
architecture structural of cache_blockTag_voter is
--=============================================================================
	
	
--=============================================================================
begin -- architecture
--=============================================================================		
	
					
	---------------------------------------------------------------------------
    -- PC Majority voter bank for cpuHit
    ---------------------------------------------------------------------------				
				
	cpuHit_voter: entity work.tmr_voter
		port map (
			input_1		=> cpuHit_mv(0),
			--input_1		=> '0',
			input_2		=> cpuHit_mv(1),
			--input_2		=> '0',
			input_3		=> cpuHit_mv(2),
			--input_3		=> '0',
			output		=> cpuHit
			);
		
	---------------------------------------------------------------------------
    -- PC Majority voter bank for invalHit
    ---------------------------------------------------------------------------				
				
	invalHit_voter: entity work.tmr_voter
		port map (
			input_1		=> invalHit_mv(0),
			--input_1		=> '0',
			input_2		=> invalHit_mv(1),
			--input_2		=> '0',
			input_3		=> invalHit_mv(2),
			--input_3		=> '0',
			output		=> invalHit
			);



	
	--tmrvoter2gpreg_readPorts		<= pl2tmrvoter_readPorts;
	--tmrvoter2pl_readPorts			<= gpreg2tmrvoter_readPorts;
	--tmrvoter2gpreg_writePorts		<= pl2tmrvoter_writePorts;


end structural;
			

