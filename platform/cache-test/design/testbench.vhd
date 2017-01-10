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

entity testbench is
end testbench;

architecture Behavioral of testbench is
  
  -- Core and cache configuration.
  constant RCFG                 : rvex_generic_config_type := rvex_cfg(
    numLanesLog2                => 3,
    numLaneGroupsLog2           => 2,
    numContextsLog2             => 2,
    traceEnable                 => 1
  );
  constant CCFG                 : cache_generic_config_type := cache_cfg(
    instrCacheLinesLog2         => 8,
    dataCacheLinesLog2          => 8
  );
  constant SREC_FILENAME        : string := "../test-progs/sim.srec";
  
  -- System control signals in the rvex library format.
  signal reset                  : std_logic;
  signal clk                    : std_logic;
  signal clkEnCPU               : std_logic;
  signal clkEnBus               : std_logic;
  
  -- Debug interface signals.
  signal dbg2rv_addr            : rvex_address_type;
  signal dbg2rv_readEnable      : std_logic;
  signal dbg2rv_writeEnable     : std_logic;
  signal dbg2rv_writeMask       : rvex_mask_type;
  signal dbg2rv_writeData       : rvex_data_type;
  signal rv2dbg_readData        : rvex_data_type;
  
  -- Common cache interface signals.
  signal rv2cache_decouple      : std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal cache2rv_blockReconfig : std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal cache2rv_stallIn       : std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal rv2cache_stallOut      : std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal cache2rv_status        : rvex_cacheStatus_array(2**RCFG.numLaneGroupsLog2-1 downto 0);
  
  -- Instruction cache interface signals.
  signal rv2icache_PCs          : rvex_address_array(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal rv2icache_fetch        : std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal rv2icache_cancel       : std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal icache2rv_instr        : rvex_syllable_array(2**RCFG.numLanesLog2-1 downto 0);
  signal icache2rv_busFault     : std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal icache2rv_affinity     : std_logic_vector(2**RCFG.numLaneGroupsLog2*RCFG.numLaneGroupsLog2-1 downto 0);
  
  -- Data cache interface signals.
  signal rv2dcache_addr         : rvex_address_array(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal rv2dcache_readEnable   : std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal rv2dcache_writeData    : rvex_data_array(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal rv2dcache_writeMask    : rvex_mask_array(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal rv2dcache_writeEnable  : std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal rv2dcache_bypass       : std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal dcache2rv_readData     : rvex_data_array(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal dcache2rv_busFault     : std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal dcache2rv_ifaceFault   : std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
  
  -- Cache to arbiter interface signals.
  signal cache2arb_bus          : bus_mst2slv_array(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal arb2cache_bus          : bus_slv2mst_array(2**RCFG.numLaneGroupsLog2-1 downto 0);
  
  -- Arbited bus connected to the memory model.
  signal arb2mem_bus            : bus_mst2slv_type;
  signal mem2arb_bus            : bus_slv2mst_type;
  
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
  
  -- Generate clock enables.
  clkEnCPU  <= '1';
  clkEnBus  <= '1';
  
  -----------------------------------------------------------------------------
  -- Instantiate the rvex core
  -----------------------------------------------------------------------------
  rvex_inst: entity rvex.core
    generic map (
      CFG                       => RCFG
    )
    port map (
      
      -- System control.
      reset                     => reset,
      clk                       => clk,
      clkEn                     => clkEnCPU,
      
      -- Common memory interface.
      rv2mem_decouple           => rv2cache_decouple,
      mem2rv_blockReconfig      => cache2rv_blockReconfig,
      mem2rv_stallIn            => cache2rv_stallIn,
      rv2mem_stallOut           => rv2cache_stallOut,
      mem2rv_cacheStatus        => cache2rv_status,
      
      -- Instruction memory interface.
      rv2imem_PCs               => rv2icache_PCs,
      rv2imem_fetch             => rv2icache_fetch,
      rv2imem_cancel            => rv2icache_cancel,
      imem2rv_instr             => icache2rv_instr,
      imem2rv_affinity          => icache2rv_affinity,
      imem2rv_busFault          => icache2rv_busFault,
      
      -- Data memory interface.
      rv2dmem_addr              => rv2dcache_addr,
      rv2dmem_readEnable        => rv2dcache_readEnable,
      rv2dmem_writeData         => rv2dcache_writeData,
      rv2dmem_writeMask         => rv2dcache_writeMask,
      rv2dmem_writeEnable       => rv2dcache_writeEnable,
      dmem2rv_readData          => dcache2rv_readData,
      dmem2rv_ifaceFault        => dcache2rv_busFault,
      dmem2rv_busFault          => dcache2rv_ifaceFault,
      
      -- Control/debug bus interface.
      dbg2rv_addr               => dbg2rv_addr,
      dbg2rv_readEnable         => dbg2rv_readEnable,
      dbg2rv_writeEnable        => dbg2rv_writeEnable,
      dbg2rv_writeMask          => dbg2rv_writeMask,
      dbg2rv_writeData          => dbg2rv_writeData,
      rv2dbg_readData           => rv2dbg_readData
      
    );
  
  -- We're not using the debug interface.
  dbg2rv_addr         <= (others => '0');
  dbg2rv_readEnable   <= '0';
  dbg2rv_writeEnable  <= '0';
  dbg2rv_writeMask    <= (others => '1');
  dbg2rv_writeData    <= (others => '0');
  
  -----------------------------------------------------------------------------
  -- Test cache integrity
  -----------------------------------------------------------------------------
  test_mem_block: block is
    signal PCs_r                : rvex_address_array(2**RCFG.numLaneGroupsLog2-1 downto 0);
    signal fetch_r              : std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    signal addr_r               : rvex_address_array(2**RCFG.numLaneGroupsLog2-1 downto 0);
    signal readEnable_r         : std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    signal writeData_r          : rvex_data_array(2**RCFG.numLaneGroupsLog2-1 downto 0);
    signal writeMask_r          : rvex_mask_array(2**RCFG.numLaneGroupsLog2-1 downto 0);
    signal writeEnable_r        : std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
  begin
    test_mem_regs: process (clk) is
    begin
      if rising_edge(clk) then
        if reset = '1' then
          PCs_r         <= (others => (others => '0'));
          fetch_r       <= (others => '0');
          addr_r        <= (others => (others => '0'));
          readEnable_r  <= (others => '0');
          writeData_r   <= (others => (others => '0'));
          writeMask_r   <= (others => (others => '0'));
          writeEnable_r <= (others => '0');
        elsif clkEnCPU = '1' then
          for laneGroup in 0 to 2**RCFG.numLaneGroupsLog2-1 loop
            if rv2cache_stallOut(laneGroup) = '0' then
              PCs_r(laneGroup)          <= rv2icache_PCs(laneGroup);
              fetch_r(laneGroup)        <= rv2icache_fetch(laneGroup);
              addr_r(laneGroup)         <= rv2dcache_addr(laneGroup);
              readEnable_r(laneGroup)   <= rv2dcache_readEnable(laneGroup);
              writeData_r(laneGroup)    <= rv2dcache_writeData(laneGroup);
              writeMask_r(laneGroup)    <= rv2dcache_writeMask(laneGroup);
              writeEnable_r(laneGroup)  <= rv2dcache_writeEnable(laneGroup);
            end if;
          end loop;
        end if;
      end if;
    end process;
    
    test_mem_model: process is
      variable mem      : rvmem_memoryState_type;
      variable readData : rvex_data_type;
      variable lane     : natural;
      variable PC       : rvex_address_type;
      variable aff      : std_logic_vector(RCFG.numLaneGroupsLog2-1 downto 0);
    begin
      
      -- Load the srec file into the memory.
      rvmem_clear(mem, '0');
      rvmem_loadSRec(mem, SREC_FILENAME);
      
      -- Check memory results as seen by the core.
      loop
        
        -- Wait for the next clock.
        wait until rising_edge(clk) and clkEnCPU = '1';
        
        -- Loop over all the lane groups.
        for laneGroup in 0 to 2**RCFG.numLaneGroupsLog2-1 loop
          if rv2cache_stallOut(laneGroup) = '0' then
            
            -- Check data access.
            if readEnable_r(laneGroup) = '1' then
              rvmem_read(mem, addr_r(laneGroup), readData);
              if not std_match(readData, dcache2rv_readData(laneGroup)) then
                report "*****ERROR***** Data read from address " & rvs_hex(addr_r(laneGroup))
                     & " should have returned " & rvs_hex(readData)
                     & " but returned " & rvs_hex(dcache2rv_readData(laneGroup))
                  severity warning;
              else
                --report "Data read from address " & rvs_hex(addr_r(laneGroup))
                --     & " correctly returned " & rvs_hex(dcache2rv_readData(laneGroup))
                --  severity note;
              end if;
            elsif writeEnable_r(laneGroup) = '1' then
              rvmem_write(mem, addr_r(laneGroup), writeData_r(laneGroup), writeMask_r(laneGroup));
              --report "Processed write to address " & rvs_hex(addr_r(laneGroup))
              --     & ", value is " & rvs_hex(writeData_r(laneGroup))
              --     & " with mask " & rvs_bin(writeMask_r(laneGroup))
              --  severity note;
            end if;
            
            -- Check instruction access.
            if fetch_r(laneGroup) = '1' and rv2icache_cancel(laneGroup) = '0' then
              aff := icache2rv_affinity(
                laneGroup*RCFG.numLaneGroupsLog2 + RCFG.numLaneGroupsLog2 - 1
                downto
                laneGroup*RCFG.numLaneGroupsLog2
              );
              for laneIndex in 0 to 2**(RCFG.numLanesLog2-RCFG.numLaneGroupsLog2)-1 loop
                lane := group2firstLane(laneGroup, RCFG) + laneIndex;
                PC := std_logic_vector(unsigned(PCs_r(laneGroup)) + laneIndex*4);
                rvmem_read(mem, PC, readData);
                if not std_match(readData, icache2rv_instr(lane)) then
                  report "*****ERROR***** Instruction read from address " & rvs_hex(PC)
                       & " should have returned " & rvs_hex(readData)
                       & " but returned " & rvs_hex(icache2rv_instr(lane))
                       & " from block " & rvs_uint(aff)
                    severity warning;
                else
                  --report "Instruction read from address " & rvs_hex(PC)
                  --     & " correctly returned " & rvs_hex(icache2rv_instr(lane))
                  --     & " from block " & rvs_uint(aff)
                  --  severity note;
                end if;
              end loop;
            end if;
            
          end if;
        end loop;
        
      end loop;
      
    end process;
  end block;
  
  -----------------------------------------------------------------------------
  -- Generate the bypass signals
  -----------------------------------------------------------------------------
  -- When the bypass signal is high, memory accesses bypass the cache. This is
  -- important for peripheral accesses. Because the rvex core does not generate
  -- such a signal, we generate one here based on the address: we assume that
  -- everything in the high 2 GiB memory space is mapped to peripherals and
  -- should not be cached.
  bypass_gen: for laneGroup in 2**RCFG.numLaneGroupsLog2-1 downto 0 generate
    rv2dcache_bypass(laneGroup) <= rv2dcache_addr(laneGroup)(31);
  end generate;
  
  -----------------------------------------------------------------------------
  -- Instantiate the cache
  -----------------------------------------------------------------------------
  cache_inst: entity rvex.cache
    generic map (
      RCFG                      => RCFG,
      CCFG                      => CCFG
    )
    port map (
      
      -- System control.
      reset                     => reset,
      clk                       => clk,
      clkEnCPU                  => clkEnCPU,
      clkEnBus                  => clkEnBus,
      
      -- Core common memory interface.
      rv2cache_decouple         => rv2cache_decouple,
      cache2rv_blockReconfig    => cache2rv_blockReconfig,
      cache2rv_stallIn          => cache2rv_stallIn,
      rv2cache_stallOut         => rv2cache_stallOut,
      cache2rv_status           => cache2rv_status,
      
      -- Core instruction memory interface.
      rv2icache_PCs             => rv2icache_PCs,
      rv2icache_fetch           => rv2icache_fetch,
      rv2icache_cancel          => rv2icache_cancel,
      icache2rv_instr           => icache2rv_instr,
      icache2rv_busFault        => icache2rv_busFault,
      icache2rv_affinity        => icache2rv_affinity,
      
      -- Core data memory interface.
      rv2dcache_addr            => rv2dcache_addr,
      rv2dcache_readEnable      => rv2dcache_readEnable,
      rv2dcache_writeData       => rv2dcache_writeData,
      rv2dcache_writeMask       => rv2dcache_writeMask,
      rv2dcache_writeEnable     => rv2dcache_writeEnable,
      rv2dcache_bypass          => rv2dcache_bypass,
      dcache2rv_readData        => dcache2rv_readData,
      dcache2rv_busFault        => dcache2rv_busFault,
      dcache2rv_ifaceFault      => dcache2rv_ifaceFault,
      
      -- Bus master interface.
      cache2bus_bus             => cache2arb_bus,
      bus2cache_bus             => arb2cache_bus
      
    );
  
  -----------------------------------------------------------------------------
  -- Instantiate the bus arbiter
  -----------------------------------------------------------------------------
  bus_arb: entity rvex.bus_arbiter
    generic map (
      NUM_MASTERS               => 2**RCFG.numLaneGroupsLog2
    )
    port map (
      
      -- System control.
      reset                     => reset,
      clk                       => clk,
      clkEn                     => clkEnBus,
      
      -- Busses.
      mst2arb                   => cache2arb_bus,
      arb2mst                   => arb2cache_bus,
      arb2slv                   => arb2mem_bus,
      slv2arb                   => mem2arb_bus
      
    );
  
  -----------------------------------------------------------------------------
  -- Model the memory accessed by the cache
  -----------------------------------------------------------------------------
  mem_model: process is
    variable mem      : rvmem_memoryState_type;
    variable readData : rvex_data_type;
    variable l        : std.textio.line;
    variable c        : character;
  begin
    
    -- Load the srec file into the memory.
    rvmem_clear(mem, '0');
    rvmem_loadSRec(mem, SREC_FILENAME);
    
    -- Initialize the bus output.
    mem2arb_bus <= BUS_SLV2MST_IDLE;
    
    -- Handle memory requests.
    loop
      
      -- Wait for the next clock.
      wait until rising_edge(clk) and clkEnBus = '1';
      
      -- If we have a request, delay for a random amount of cycles.
      if arb2mem_bus.readEnable = '1' or arb2mem_bus.writeEnable = '1' then
        mem2arb_bus <= BUS_SLV2MST_IDLE;
        mem2arb_bus.busy <= '1';
        
        -- (TODO: this is not random)
        wait until rising_edge(clk) and clkEnBus = '1';
        
      end if;
      
      -- Handle the bus request.
      mem2arb_bus <= BUS_SLV2MST_IDLE;
      if arb2mem_bus.readEnable = '1' then
        rvmem_read(mem, arb2mem_bus.address, readData);
        mem2arb_bus.readData <= readData;
        mem2arb_bus.ack <= '1';
      elsif arb2mem_bus.writeEnable = '1' then
        rvmem_write(mem, arb2mem_bus.address, arb2mem_bus.writeData, arb2mem_bus.writeMask);
        mem2arb_bus.ack <= '1';
        
        -- Handle application debug output.
        if arb2mem_bus.address = X"DEB00000" then
          c := character'val(to_integer(unsigned(arb2mem_bus.writeData(31 downto 24))));
          if c = LF then
            writeline(std.textio.output, l);
          else
            write(l, c);
          end if;
        end if;
        
      end if;
      
      -- Force a bus fault for addresses starting with 0xFF in order to test
      -- cache behavior in such a case.
      if arb2mem_bus.address(31 downto 24) = X"FF" then
        mem2arb_bus.readData <= X"01234567";
        mem2arb_bus.fault <= '1';
      else
        mem2arb_bus.fault <= '0';
      end if;
      
    end loop;
    
  end process;
  
end Behavioral;

