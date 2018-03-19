library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.common_pkg.all;
use work.utils_pkg.all;
use work.core_pkg.all;
use work.core_intIface_pkg.all;
--use work.core_trap_pkg.all;
use work.core_pipeline_pkg.all;
--use work.core_ctrlRegs_pkg.all;



--=============================================================================
entity ecc_gpreg is
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
	--start_ft					: in std_logic;
	  
	--signal representing active pipelane groups for fault tolerance mode
	--config_signal				: in std_logic_vector (3 downto 0); 
	   
    ---------------------------------------------------------------------------
    -- Signals that go into GPREG ECC encoder
    ---------------------------------------------------------------------------
    
	writeData_raw	            : in rvex_data_array(2**CFG.numLanesLog2-1 downto 0);
    readData_encoded           	: in rvex_encoded_data_array(2*2**CFG.numLanesLog2-1 downto 0); --readData_comb
	  
	---------------------------------------------------------------------------
    -- Signals that come out of GPREG ECC decoder
    ---------------------------------------------------------------------------

	writeData_encoded	        : out rvex_encoded_data_array(2**CFG.numLanesLog2-1 downto 0);
    readData_decoded           	: out rvex_data_array(2*2**CFG.numLanesLog2-1 downto 0) --readData_comb	  
	  
  );

end entity ecc_gpreg;
	

--=============================================================================
architecture structural of ecc_gpreg is
--=============================================================================
	
	
--=============================================================================
begin -- architecture
--=============================================================================		
	
	---------------------------------------------------------------------------
    -- Adding Delay before GPREG voter starts after fault tolerance is requested
    ---------------------------------------------------------------------------					

--	delay_regsiter: process (clk, start_ft)
--	begin
--		if rising_edge (clk) then
--			if (reset = '1') then
--				start_array <= (others => '0');
--			else
--				start_array(0) <= start_ft;
--			end if;
				
--		end if;
--	end process;			
					
	---------------------------------------------------------------------------
    --  Encoder Bank
    ---------------------------------------------------------------------------				
				
		encoder_bank: for i in 0 to 2**CFG.numLanesLog2-1 generate
			encoder_bit32: entity work.ecc_encoder
				port map (
					input		=> writeData_raw(i),
					output		=> writeData_encoded(i)
				);
		end generate;
	
	---------------------------------------------------------------------------
    -- Decoder Bank
    ---------------------------------------------------------------------------				
		
		decoder_bank: for i in 0 to 2*2**CFG.numLanesLog2-1 generate
			decoder_bit32: entity work.ecc_decoder
				port map (
					input		=> readData_encoded(i),
					output		=> readData_decoded(i)
				);
		end generate;

				
	--writeData_encoded			<= "000000" & writeData_raw;
	--readData_decoded			<= "000000" & readData_encoded;


end structural;
			

