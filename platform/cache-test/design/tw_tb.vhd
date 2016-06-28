library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.textio.all;

library rvex;
use rvex.common_pkg.all;
use rvex.utils_pkg.all;
use rvex.simUtils_pkg.all;
use rvex.simUtils_mem_pkg.all;
use rvex.bus_pkg.all;
use rvex.core_pkg.all;
use rvex.cache_pkg.all;

entity tw_tb is
end tw_tb;

--=============================================================================
architecture Behavioral of tw_tb is
--=============================================================================
  
  -- Configuration.
  constant RCFG                 : rvex_generic_config_type := rvex_cfg;
  constant CCFG                 : cache_generic_config_type := cache_cfg;
  
  -- System control.
  signal reset                  : std_logic;
  signal clk                    : std_logic;
  signal clkEn                  : std_logic;
  
  -- Control register values.
  signal rv2tw_pageTablePtr     : rvex_address_array(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal rv2tw_kernelMode       : std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal rv2tw_writeToCleanEna  : std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal rv2tw_writeProtect     : std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal rv2tw_globalPageEna    : std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal rv2tw_execPageEna      : std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
  
  -- TLB interconnect.
  signal tlb2tw_request         : std_logic_vector(2*2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal tlb2tw_vaddr           : rvex_address_array(2*2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal dtlb2tw_write          : std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal tw2tlb_complete        : std_logic_vector(2*2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal tw2tlb_fault           : std_logic;
  signal tw2tlb_paddr           : rvex_address_type;
  signal tw2tlb_flagGlobal      : std_logic;
  signal tw2tlb_flagSize        : std_logic;
  signal tw2tlb_flagDirty       : std_logic;
  signal tw2tlb_flagCacheDisable: std_logic;
  signal tw2tlb_flagWriteThrough: std_logic;
  signal tw2tlb_flagUser        : std_logic;
  signal tw2tlb_flagWritable    : std_logic;
  
  -- Fault signals.
  signal rv2tw_stallOut         : std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal tw2rv_iPageFault       : std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal tw2rv_iKernelAccVio    : std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal tw2rv_iExecAccVio      : std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal tw2rv_dPageFault       : std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal tw2rv_dKernelAccVio    : std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal tw2rv_dWriteAccVio     : std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal tw2rv_dWriteToClean    : std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
  
  -- Memory access bus.
  signal tw2bus_bus             : bus_mst2slv_type;
  signal bus2tw_bus             : bus_slv2mst_type;
  
  -- Testbench signals.
  signal newRequest             : std_logic_vector(2*2**RCFG.numLaneGroupsLog2-1 downto 0);
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- System control
  -----------------------------------------------------------------------------
  -- Generate clock.
  clk_proc: process is
  begin
    clk <= '1';
    wait for 5 ns;
    clk <= '0';
    wait for 5 ns;
  end process; 
  
  -- Generate reset.
  reset_proc: process is
  begin
    reset <= '1';
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    reset <= '0';
    wait;
  end process;
  
  -- Generate clock enable.
  clkEn <= '1';
  
  -----------------------------------------------------------------------------
  -- Instantiate the UUT
  -----------------------------------------------------------------------------
  uut: entity rvex.cache_tw
    generic map (
      
      -- Configuration.
      RCFG                      => RCFG,
      CCFG                      => CCFG
      
    )
    port map (

      -- System control.
      reset                     => reset,
      clk                       => clk,
      clkEn                     => clkEn,
      
      -- Control register values.
      rv2tw_pageTablePtr        => rv2tw_pageTablePtr,
      rv2tw_kernelMode          => rv2tw_kernelMode,
      rv2tw_writeToCleanEna     => rv2tw_writeToCleanEna,
      rv2tw_writeProtect        => rv2tw_writeProtect,
      rv2tw_globalPageEna       => rv2tw_globalPageEna,
      rv2tw_execPageEna         => rv2tw_execPageEna,
      
      -- TLB interconnect.
      tlb2tw_request            => tlb2tw_request,
      tlb2tw_vaddr              => tlb2tw_vaddr,
      dtlb2tw_write             => dtlb2tw_write,
      tw2tlb_complete           => tw2tlb_complete,
      tw2tlb_fault              => tw2tlb_fault,
      tw2tlb_paddr              => tw2tlb_paddr,
      tw2tlb_flagGlobal         => tw2tlb_flagGlobal,
      tw2tlb_flagSize           => tw2tlb_flagSize,
      tw2tlb_flagDirty          => tw2tlb_flagDirty,
      tw2tlb_flagCacheDisable   => tw2tlb_flagCacheDisable,
      tw2tlb_flagWriteThrough   => tw2tlb_flagWriteThrough,
      tw2tlb_flagUser           => tw2tlb_flagUser,
      tw2tlb_flagWritable       => tw2tlb_flagWritable,
      
      -- Fault signals.
      rv2tw_stallOut            => rv2tw_stallOut,
      tw2rv_iPageFault          => tw2rv_iPageFault,
      tw2rv_iKernelAccVio       => tw2rv_iKernelAccVio,
      tw2rv_iExecAccVio         => tw2rv_iExecAccVio,
      tw2rv_dPageFault          => tw2rv_dPageFault,
      tw2rv_dKernelAccVio       => tw2rv_dKernelAccVio,
      tw2rv_dWriteAccVio        => tw2rv_dWriteAccVio,
      tw2rv_dWriteToClean       => tw2rv_dWriteToClean,
      
      -- Memory access bus.
      tw2bus_bus                => tw2bus_bus,
      bus2tw_bus                => bus2tw_bus
      
    );
  
  -----------------------------------------------------------------------------
  -- Model the memory
  -----------------------------------------------------------------------------
  mem_proc: process is
    variable mem  : rvmem_memoryState_type;
    variable rdat : rvex_data_type;
  begin
    
    -- Initialize the memory.
    rvmem_clear(mem, '0');
    -- TODO
    
    loop
      wait until rising_edge(clk);
      if reset = '1' then
        bus2tw_bus <= BUS_SLV2MST_IDLE;
        bus2tw_bus.readData <= (others => 'U');
      elsif clkEn = '1' then
        bus2tw_bus <= BUS_SLV2MST_IDLE;
        bus2tw_bus.readData <= (others => 'U');
        
        if tw2bus_bus.readEnable = '1' then
          rvmem_read(mem,
            tw2bus_bus.address,
            rdat
          );
        elsif tw2bus_bus.writeEnable = '1' then
          rvmem_write(mem,
            tw2bus_bus.address,
            tw2bus_bus.writeData,
            tw2bus_bus.writeMask
          );
        end if;
        
        if bus_requesting(tw2bus_bus) = '1' then
          bus2tw_bus.busy <= '1';
          wait until rising_edge(clk);
          bus2tw_bus.busy <= '0';
          bus2tw_bus.ack <= '1';
          bus2tw_bus.readData <= rdat;
        end if;
      end if;
    end loop;
  end process;
  
  -----------------------------------------------------------------------------
  -- Model the stall and request signals
  -----------------------------------------------------------------------------
  req_latch_proc: process (clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        tlb2tw_request <= (others => '0');
      elsif clkEn = '1' then
        tlb2tw_request <= newRequest or (tlb2tw_request and not tw2tlb_complete);
      end if;
    end if;
  end process;
  
  
  request_proc: process is
    variable i: natural;
  begin
    newRequest             <= (others => '0');
    tlb2tw_vaddr           <= (others => (others => '0'));
    rv2tw_pageTablePtr     <= (others => (others => '0'));
    rv2tw_kernelMode       <= (others => '0');
    rv2tw_writeToCleanEna  <= (others => '0');
    rv2tw_writeProtect     <= (others => '0');
    rv2tw_globalPageEna    <= (others => '0');
    rv2tw_execPageEna      <= (others => '0');
    rv2tw_stallOut         <= (others => '0');
    wait until falling_edge(reset);
    wait until rising_edge(clk);
    newRequest <= (others => '1');
    wait until rising_edge(clk);
    newRequest <= (others => '0');
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    --newRequest <= (others => '1');
    wait until rising_edge(clk);
    newRequest <= (others => '0');
    wait;
  end process;
  
end Behavioral;

