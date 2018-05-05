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
entity cache_instr_blockValid_voter is
--=============================================================================
	


  port	(
	  
	   
    ---------------------------------------------------------------------------
    -- Signals that go into cache_instr_blockValid_voter
    ---------------------------------------------------------------------------
    cpuValid_mv						: in std_logic_vector (2 downto 0);
	  
	---------------------------------------------------------------------------
    -- Signals that come out of cache_instr_blockValid_voter
    ---------------------------------------------------------------------------
	  
	cpuValid						: out std_logic


	  
  );

end entity cache_instr_blockValid_voter;
	

--=============================================================================
architecture structural of cache_instr_blockValid_voter is
--=============================================================================
	
	
--=============================================================================
begin -- architecture
--=============================================================================		
	
					
	---------------------------------------------------------------------------
    -- PC Majority voter bank for update
    ---------------------------------------------------------------------------				
				
	cpuValid_voter: entity work.tmr_voter
		port map (
			input_1		=> cpuValid_mv(0),
			--input_1		=> '0',
			input_2		=> cpuValid_mv(1),
			--input_2		=> '0',
			input_3		=> cpuValid_mv(2),
			--input_3		=> '0',
			output		=> cpuValid
			);


	
	--tmrvoter2gpreg_readPorts		<= pl2tmrvoter_readPorts;
	--tmrvoter2pl_readPorts			<= gpreg2tmrvoter_readPorts;
	--tmrvoter2gpreg_writePorts		<= pl2tmrvoter_writePorts;


end structural;
			

