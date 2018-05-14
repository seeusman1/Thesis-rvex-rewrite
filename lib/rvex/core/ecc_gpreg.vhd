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
    
	writeData	            	: in rvex_data_array(2**CFG.numLanesLog2-1 downto 0);
    readData_encoded           	: in rvex_encoded_data_array(2*2**CFG.numLanesLog2-1 downto 0); --readData_comb
	writeAddr					: in rvex_address_array(2**CFG.numLanesLog2-1 downto 0);
	readAddr					: in rvex_address_array(2*2**CFG.numLanesLog2-1 downto 0);
	  
	---------------------------------------------------------------------------
    -- Signals that come out of GPREG ECC decoder
    ---------------------------------------------------------------------------

	writeData_encoded	        : out rvex_encoded_data_array(2**CFG.numLanesLog2-1 downto 0);
    readData_decoded           	: out rvex_data_array(2*2**CFG.numLanesLog2-1 downto 0); --readData_comb
	writeAddr_encoded			: out rvex_encoded_address_array(2**CFG.numLanesLog2-1 downto 0);
	readAddr_encoded			: out rvex_encoded_address_array(2*2**CFG.numLanesLog2-1 downto 0)
	  
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
    --  Encoder Bank for writeData
    ---------------------------------------------------------------------------				
				
		encoder_writedata_bank: for i in 0 to 2**CFG.numLanesLog2-1 generate
			encoder_writedata_bit32: entity work.ecc_encoder
				port map (
					input		=> writeData(i),
					output		=> writeData_encoded(i)
				);
		end generate;

	---------------------------------------------------------------------------
    --  Encoder Bank for writeAddress
    ---------------------------------------------------------------------------				
				
		encoder_writeadd_bank: for i in 0 to 2**CFG.numLanesLog2-1 generate
			encoder_writeadd_bit32: entity work.ecc_encoder
				port map (
					input		=> writeAddr(i),
					output		=> writeAddr_encoded(i)
				);
		end generate;
				
	---------------------------------------------------------------------------
    --  Encoder Bank for readAddress
    ---------------------------------------------------------------------------				
				
		encoder_readadd_bank: for i in 0 to 2*2**CFG.numLanesLog2-1 generate
			encoder_readadd_bit32: entity work.ecc_encoder
				port map (
					input		=> readAddr(i),
					output		=> readAddr_encoded(i)
				);
		end generate;
				
	---------------------------------------------------------------------------
    -- Decoder Bank for readData
    ---------------------------------------------------------------------------				
		
		decoder_bank: for i in 0 to 2*2**CFG.numLanesLog2-1 generate
			decoder_bit32: entity work.ecc_decoder
				port map (
					input		=> readData_encoded(i),
					output		=> readData_decoded(i)
				);
		end generate;


end structural;
			

