library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;
library rvex;
use rvex.common_pkg.all;
use rvex.utils_pkg.all;
use rvex.core_pkg.all;
use rvex.core_intIface_pkg.all;
use rvex.core_trap_pkg.all;
use rvex.core_pipeline_pkg.all;
use rvex.core_ctrlRegs_pkg.all;


entity tmr_dmemvoter_tb is
end entity tmr_dmemvoter_tb;

architecture behavioral of tmr_dmemvoter_tb is

	component tmr_dmemvoter
    generic (
		CFG                         : rvex_generic_config_type
	);
	port(

    reset                       : in  std_logic;
    clk                         : in  std_logic;
    clkEn                       : in  std_logic := '1'; 
	start_ft					: in std_logic;
	config_signal				: in std_logic_vector (3 downto 0); 
	  
    ---------------------------------------------------------------------------
    -- Signals that go into DMEM Majority voter
    ---------------------------------------------------------------------------

    rv2dmemvoter_addr                  : in rvex_address_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    rv2dmemvoter_readEnable            : in std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    rv2dmemvoter_writeData             : in rvex_data_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    rv2dmemvoter_writeMask             : in rvex_mask_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    rv2dmemvoter_writeEnable           : in  std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    dmem2dmemvoter_readData            : in  rvex_data_array(2**CFG.numLaneGroupsLog2-1 downto 0);
	  
	---------------------------------------------------------------------------
    -- Signals that come out of DMEM Majority voter
    ---------------------------------------------------------------------------

    dmemvoter2dmem_addr                : out rvex_address_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    dmemvoter2dmem_readEnable          : out std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    dmemvoter2dmem_writeData           : out rvex_data_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    dmemvoter2dmem_writeMask           : out rvex_mask_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    dmemvoter2dmem_writeEnable         : out std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    dmemvoter2rv_readData       	   : out  rvex_data_array(2**CFG.numLaneGroupsLog2-1 downto 0)
	);

	end component;

    -- rvex generic configuration.

  constant CFG  : rvex_generic_config_type := (
    numLanesLog2                => 3,
    numLaneGroupsLog2           => 2,
    numContextsLog2             => 2,
    genBundleSizeLog2           => 3,
    bundleAlignLog2             => 1,
    multiplierLanes             => 2#11111111#,
    faddLanes                   => 2#11111111#,
    fcompareLanes               => 2#11111111#,
    fconvfiLanes                => 2#11111111#,
    fconvifLanes                => 2#11111111#,
    fmultiplyLanes              => 2#11111111#,
    memLaneRevIndex             => 1,
    numBreakpoints              => 4,
    forwarding                  => true,
    traps                       => 2,
    limmhFromNeighbor           => true,
    limmhFromPreviousPair       => false,
    reg63isLink                 => false,
    cregStartAddress            => X"FFFFFC00",
    resetVectors                => (others => (others => '0')),
    unifiedStall                => true, --testing
    gpRegImpl                   => RVEX_GPREG_IMPL_MEM,
    traceEnable                 => true,
    perfCountSize               => 4,
    cachePerfCountEnable        => false,
    stallInactive               => true,
    enablePowerLatches          => true
  );


	--signal port1				: STD_LOGIC_VECTOR(31 downto 0):= "00000000000000000000000000000000";
	--signal port2				: STD_LOGIC_VECTOR(31 downto 0):= "00000000000000000000000000000000";
	--signal port3				: STD_LOGIC_VECTOR(31 downto 0):= "00000000000000000000000000000000";
	--signal conditions			: STD_LOGIC_VECTOR(2 downto 0);
	--signal out1					: STD_LOGIC_VECTOR(31 downto 0);


	signal reset				: std_logic := '0';
	signal clk					: std_logic := '0';
	signal clkEn				: std_logic := '1';
	signal start_ft				: std_logic := '1';
	signal config_signal		: std_logic_vector (3 downto 0) := "0111"; 

    ---------------------------------------------------------------------------

    signal rv2dmemvoter_addr                  : rvex_address_array(2**CFG.numLaneGroupsLog2-1 downto 0):= (X"00000000", X"10101010", X"11111111", X"00000000");
    signal rv2dmemvoter_readEnable            : std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0) := "0000";
    signal rv2dmemvoter_writeData             : rvex_data_array(2**CFG.numLaneGroupsLog2-1 downto 0) := (others => X"00000000");
    signal rv2dmemvoter_writeMask             : rvex_mask_array(2**CFG.numLaneGroupsLog2-1 downto 0) := (others => "0000");
    signal rv2dmemvoter_writeEnable           : std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0) := "0000";
    signal dmem2dmemvoter_readData            : rvex_data_array(2**CFG.numLaneGroupsLog2-1 downto 0) := (others => X"00000000");
	  

    ---------------------------------------------------------------------------

    signal dmemvoter2dmem_addr                : rvex_address_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    signal dmemvoter2dmem_readEnable          : std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    signal dmemvoter2dmem_writeData           : rvex_data_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    signal dmemvoter2dmem_writeMask           : rvex_mask_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    signal dmemvoter2dmem_writeEnable         : std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    signal dmemvoter2rv_readData       	      : rvex_data_array(2**CFG.numLaneGroupsLog2-1 downto 0);


begin

	voter: tmr_dmemvoter
    generic map (
      CFG => CFG
    )
	port map(

    reset          =>       reset,      
    clk            =>       clk,         
    clkEn          =>       clkEn,        
	start_ft	   =>	    start_ft,		
	config_signal  =>	    config_signal,		 
	  
    ---------------------------------------------------------------------------
    -- Signals that go into DMEM Majority voter
    ---------------------------------------------------------------------------

    rv2dmemvoter_addr 			=>     rv2dmemvoter_addr,            
    rv2dmemvoter_readEnable     =>     rv2dmemvoter_readEnable,
    rv2dmemvoter_writeData      =>     rv2dmemvoter_writeData,
    rv2dmemvoter_writeMask      =>     rv2dmemvoter_writeMask,
    rv2dmemvoter_writeEnable    =>	   rv2dmemvoter_writeEnable,
    dmem2dmemvoter_readData     =>     dmem2dmemvoter_readData,
	  
	---------------------------------------------------------------------------
    -- Signals that come out of DMEM Majority voter
    ---------------------------------------------------------------------------

    dmemvoter2dmem_addr                =>	dmemvoter2dmem_addr,
    dmemvoter2dmem_readEnable          =>	dmemvoter2dmem_readEnable,
    dmemvoter2dmem_writeData           =>	dmemvoter2dmem_writeData,
    dmemvoter2dmem_writeMask           =>	dmemvoter2dmem_writeMask,
    dmemvoter2dmem_writeEnable         =>	dmemvoter2dmem_writeEnable,
    dmemvoter2rv_readData       	   =>	dmemvoter2rv_readData

	);

	-- clock generation
	clk <= not clk after 10 ns;

	-- waveform generation

	WaveGen_Proc : process
	begin

	-- insert signal assignments here

    wait for 30 ns;
    rv2dmemvoter_addr                  <= (X"00000000", X"10101010", X"11111111", X"00000000");
	--port2	<= "11111111111111111111111111111111";
	--port3	<= "11111111111111111111111111111111";

	wait for 30 ns;	 --60 ns
    rv2dmemvoter_addr                  <= (X"10101010", X"FFFF0000", X"11111111", X"0000FFFF");
	--port3	<= "00000000000000000000000000000000";

	wait for 30 ns;  --90 ns
    rv2dmemvoter_addr                  <= (X"11112222", X"00000000", X"11111111", X"77773333");
	--port1	<= "00000000000000000000000000000000";

	--wait for 30 ns;  --120 ns
	 rv2dmemvoter_addr               <= (X"3C3C3C3C", X"00000000", X"11111111", X"AAAAAAAA");
	--port2	<= "00000000000000000000000000000000";

	wait for 30 ns;  --150 ns
	rv2dmemvoter_addr	<= (others => X"00000000");
	--port2	<= "00000000000000000000100000000000";

	
	
end process;

end behavioral;

