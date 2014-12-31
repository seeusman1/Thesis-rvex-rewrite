-- r-VEX processor
-- Copyright (C) 2008-2014 by TU Delft.
-- All Rights Reserved.

-- THIS IS A LEGAL DOCUMENT, BY USING r-VEX,
-- YOU ARE AGREEING TO THESE TERMS AND CONDITIONS.

-- No portion of this work may be used by any commercial entity, or for any
-- commercial purpose, without the prior, written permission of TU Delft.
-- Nonprofit and noncommercial use is permitted as described below.

-- 1. r-VEX is provided AS IS, with no warranty of any kind, express
-- or implied. The user of the code accepts full responsibility for the
-- application of the code and the use of any results.

-- 2. Nonprofit and noncommercial use is encouraged. r-VEX may be
-- downloaded, compiled, synthesized, copied, and modified solely for nonprofit,
-- educational, noncommercial research, and noncommercial scholarship
-- purposes provided that this notice in its entirety accompanies all copies.
-- Copies of the modified software can be delivered to persons who use it
-- solely for nonprofit, educational, noncommercial research, and
-- noncommercial scholarship purposes provided that this notice in its
-- entirety accompanies all copies.

-- 3. ALL COMMERCIAL USE, AND ALL USE BY FOR PROFIT ENTITIES, IS EXPRESSLY
-- PROHIBITED WITHOUT A LICENSE FROM TU Delft (J.S.S.M.Wong@tudelft.nl).

-- 4. No nonprofit user may place any restrictions on the use of this software,
-- including as modified by the user, by any other authorized user.

-- 5. Noncommercial and nonprofit users may distribute copies of r-VEX
-- in compiled or binary form as set forth in Section 2, provided that
-- either: (A) it is accompanied by the corresponding machine-readable source
-- code, or (B) it is accompanied by a written offer, with no time limit, to
-- give anyone a machine-readable copy of the corresponding source code in
-- return for reimbursement of the cost of distribution. This written offer
-- must permit verbatim duplication by anyone, or (C) it is distributed by
-- someone who received only the executable form, and is accompanied by a
-- copy of the written offer of source code.

-- 6. r-VEX was developed by Stephan Wong, Thijs van As, Fakhar Anjam, Roel Seedorf,
-- Anthony Brandon. r-VEX is currently maintained by TU Delft (J.S.S.M.Wong@tudelft.nl).

-- Copyright (C) 2008-2014 by TU Delft.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--library work;
--use work.rVEX_pkg.all;
--use work.reconfCache_pkg.all;

library rvex;
use rvex.common_pkg.all;
use rvex.utils_pkg.all;
use rvex.core_pkg.all;
use rvex.cache_pkg.all;


library grlib;
use grlib.amba.all;
use grlib.devices.all;

library techmap;
use techmap.gencomp.all;

--for irqi/irqo
library gaisler;
use gaisler.leon3.all;

entity rovex_system is
  generic (
    CFG         : rvex_generic_config_type := RVEX_DEFAULT_CONFIG;
    hindex      : integer range 0 to NAHBMST-1 := 0;
    --ISSUE_WIDTH : natural                      := 8;
    --FORWARDING  : boolean                      := true;
    pindexglob  : integer                      := 0;
    paddrglob   : integer                      := 0;
    pmaskglob   : integer                      := 16#fff#
    );

  port (
    clk       : in  std_logic;
    reset     : in  std_logic;
    ClkEn     : in  std_logic;
    ahbi      : in  ahb_mst_in_type;
    ahbo      : out ahb_mst_out_vector_type(3 downto 0);
    apbiglob  : in  apb_slv_in_type;
    apboglob  : out apb_slv_out_type;
    irqi      : in  irq_in_vector;
    irqo      : out irq_out_vector
    );
end entity rovex_system;


architecture behavioural of rovex_system is

  constant REVISION : integer := 0;

--TODO should change these
  constant pconfigglob : apb_config_type := (
    0 => ahb_device_reg (VENDOR_GAISLER, GAISLER_GPREG, 0, REVISION, 0),
    1 => apb_iobar(paddrglob, pmaskglob));

  signal clk_half : std_logic := '0';

  signal vex_reset_p  : std_logic;
  signal vex_reset_pn : std_logic;
  signal bus_reset_p  : std_logic;
  signal clk_enable_s : std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
--  signal run_array    : std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
--  signal preempt      : std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0) := (others => '0');

--  signal ita : rvex_address_array(2**CFG.numLaneGroupsLog2-1 downto 0) := (others => (others => '0'));
--  signal tca : rvex_address_array(2**CFG.numLaneGroupsLog2-1 downto 0) := (others => (others => '0'));

--  signal dcache_rdmiss    : std_logic;
--  signal drmiss_count_s   : std_logic_vector(31 downto 0);
--  signal drmiss_reset_s   : std_logic;
--  signal dcache_rdaccess  : std_logic;
--  signal draccess_count_s : std_logic_vector(31 downto 0);
--  signal draccess_reset_s : std_logic;
--  signal dcache_wrmiss    : std_logic;
--  signal dwmiss_count_s   : std_logic_vector(31 downto 0);
--  signal dwmiss_reset_s   : std_logic;
--  signal dcache_wraccess  : std_logic;
--  signal dwaccess_count_s : std_logic_vector(31 downto 0);
--  signal dwaccess_reset_s : std_logic;

--  signal address_dr_s        : rvex_address_array(2**CFG.numLaneGroupsLog2-1 downto 0) := (others => (others => '0'));
--  signal write_en_dm_s       : rvex_mask_array(2**CFG.numLaneGroupsLog2-1 downto 0)      := (others => (others => '0'));
--  signal cache_write_en_s    : rvex_mask_array(2**CFG.numLaneGroupsLog2-1 downto 0)      := (others => (others => '0'));
--  signal cregs_write_en_s    : rvex_mask_array(2**CFG.numLaneGroupsLog2-1 downto 0)      := (others => (others => '0'));
--  signal read_en_s           : std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0)   := (others => '0');
--  signal cache_read_en_s     : std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0)   := (others => '0');
--  signal cregs_read_en_s     : std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0)   := (others => '0');
--  signal dm2rvex_data_s      : rvex_data_array(2**CFG.numLaneGroupsLog2-1 downto 0)        := (others => (others => '0'));
--  signal rvex2dm_data_s      : rvex_data_array(2**CFG.numLaneGroupsLog2-1 downto 0)        := (others => (others => '0'));
--  signal read_data_c         : rvex_data_array(2**CFG.numLaneGroupsLog2-1 downto 0)        := (others => (others => '0'));
--  signal decoded_read_data_s : rvex_data_array(2**CFG.numLaneGroupsLog2-1 downto 0)        := (others => (others => '0'));




  signal done_s         : std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0) := (others => '0');
  signal cycles_s       : rvex_data_array(2**CFG.numLaneGroupsLog2-1 downto 0)      := (others => (others => '0'));
  signal cycles_reset_s : std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);

  --signal mpc     : rvex_address_array(2**CFG.numLaneGroupsLog2-1 downto 0);  -- pc to read instruction of i_mem
  --signal mpc_r   : rvex_address_array(2**CFG.numLaneGroupsLog2-1 downto 0);  -- pc to read instruction of i_mem
  --signal instr_s : instruction_vector_64(2**CFG.numLaneGroupsLog2-1 downto 0) := (others => (others => '0'));  -- instruction from i_mem


  -- Signals for reconfCache.
  signal clkEnCPU           : std_logic;
  signal clkEnBus           : std_logic;
  signal atomsToCache       : reconfCache_atomIn_array;
  signal cacheToAtoms       : reconfCache_atomOut_array;
  signal memToCache         : reconfCache_memIn_array;
  signal cacheToMem         : reconfCache_memOut_array;
  signal invalToCache       : reconfCache_invalIn;
  signal cacheToInval       : reconfCache_invalOut;
  signal cacheDecoupleVect  : std_logic_vector(3 downto 0);




  --TODO: see whether we want to keep using these for every core
  signal debug_halt_s             : std_logic;
  signal debug_register_address_s : std_logic_vector(6 downto 0);
  signal debug_register_value_s   : std_logic_vector(31 downto 0);


  -- APB related signals
  type apb_registers is record
    ctrl          : std_logic_vector(31 downto 0);
    status        : std_logic_vector(31 downto 0);
    dbgctrl		  : std_logic_vector(31 downto 0);
    dbgarg		  : std_logic_vector(31 downto 0);
    dbgretval	  : std_logic_vector(31 downto 0);
    brk1          : std_logic_vector(31 downto 0);
    brk2          : std_logic_vector(31 downto 0);
    brk3          : std_logic_vector(31 downto 0);
    brk4          : std_logic_vector(31 downto 0);
  end record;

  signal apb_reg    : apb_registers;
  signal apb_reg_in : apb_registers;
  
  
  
  --The following signals are taken from standalone_core.vhd:
  
  -- Common memory interface.
    signal rv2mem_decouple        : std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    signal mem2rv_stallIn         : std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    signal rv2mem_stallOut        : std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Instruction memory interface.
    signal rv2imem_PCs            : rvex_address_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    signal rv2imem_fetch          : std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    signal imem2rv_instr          : rvex_syllable_array(2**CFG.numLanesLog2-1 downto 0);
    signal imem2rv_fault          : std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Fault signals from each instruction memory bus, before being merged for
    -- each group.
    signal imemFault              : std_logic_vector(2**CFG.numLanesLog2-1 downto 0);
    
    -- Data memory interface.
    signal rv2dmem_addr           : rvex_address_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    signal rv2dmem_writeEnable    : std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    signal rv2dmem_writeMask      : rvex_mask_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    signal rv2dmem_writeData      : rvex_data_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    signal rv2dmem_readEnable     : std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    signal dmem2rv_readData       : rvex_data_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    signal dmem2rv_fault          : std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Control/debug bus interface.
    signal dbg2rv_addr            : rvex_address_type;
    signal dbg2rv_readEnable      : std_logic;
    signal dbg2rv_writeEnable     : std_logic;
    signal dbg2rv_writeMask       : rvex_mask_type;
    signal dbg2rv_writeData       : rvex_data_type;
    signal rv2dbg_readData        : rvex_data_type;
    
    
    --run control interface
    signal rctrl2rvsa_irq                :  std_logic_vector(2**CFG.numContextsLog2-1 downto 0) := (others => '0');
    signal rctrl2rvsa_irqID              :  rvex_address_array(2**CFG.numContextsLog2-1 downto 0) := (others => (others => '0'));
    signal rvsa2rctrl_irqAck             :  std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
    signal rctrl2rvsa_run                :  std_logic_vector(2**CFG.numContextsLog2-1 downto 0) := (others => '1');
    signal rvsa2rctrl_idle               :  std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
    signal rctrl2rvsa_reset              :  std_logic_vector(2**CFG.numContextsLog2-1 downto 0) := (others => '0');
    signal rvsa2rctrl_done               :  std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
    

  
begin

  -- active high reset for vex
  vex_reset_p  <= not reset or apb_reg.ctrl(0);
  vex_reset_pn <= not vex_reset_p;
  
  -- active high reset for the AHB bus interface
  bus_reset_p  <= vex_reset_p;
  
  --===========================================================================
  -- Instantiate and connect cache
  --===========================================================================
  -- Instantiate the cache itself.
  cache : entity rvex.cache
    port map (
      clk           => clk,
      reset         => vex_reset_p,
      
      -- Active high CPU interface clock enable input.
      clkEnCPU      => clkEnCPU,
      
      -- Active high bus interface clock enable input.
      clkEnBus      => clkEnBus,
      
      -- Connections to the r-vex cores. Governed by clkEnCPU.
      atomsToCache  => atomsToCache,
      cacheToAtoms  => cacheToAtoms,
      
      -- Connections to the memory bus. Governed by clkEnBus.
      memToCache    => memToCache,
      cacheToMem    => cacheToMem,
      
      -- Cache invalidation connections. Governed by clkEnBus.
      invalToCache  => invalToCache,
      cacheToInval  => cacheToInval
      
    );
  
  -- Instantiate the AHB bus masters for the cache blocks.
  cache_bus_iface_gen : for i in 0 to 3 generate
    cache_bus_iface_n : entity rvex.cache_ahbBridge
      generic map (
        hindex        => hindex + i
      )
      port map (
        
        -- Syscon signals.
        clk           => clk,
        resetCPU      => vex_reset_p,
        resetBus      => bus_reset_p,
        
        -- Cache interface.
        bridgeToCache => memToCache(i),
        cacheToBridge => cacheToMem(i), 
        
        -- AHB bus interface.
        busToMaster   => ahbi,
        masterToBus   => ahbo(i)
        
      );
  end generate;
  
  -----------------------------------------------------------------------------
  -- Instantiate the rvex core
  -----------------------------------------------------------------------------
  core: entity rvex.core
    generic map (
      CFG                       => CFG
    )
    port map (
      
      -- System control.
      reset                     => vex_reset_p,
      clk                       => clk,
      clkEn                     => clkEn,
      
      -- Run control interface.
      rctrl2rv_irq              => rctrl2rvsa_irq,
      rctrl2rv_irqID            => rctrl2rvsa_irqID,
      rv2rctrl_irqAck           => rvsa2rctrl_irqAck,
      rctrl2rv_run              => rctrl2rvsa_run,
      rv2rctrl_idle             => rvsa2rctrl_idle,
      rctrl2rv_reset            => rctrl2rvsa_reset,
      rv2rctrl_done             => rvsa2rctrl_done,
      
      -- Common memory interface.
      rv2mem_decouple           => rv2mem_decouple,
      mem2rv_stallIn            => mem2rv_stallIn,
      rv2mem_stallOut           => rv2mem_stallOut,
      
      -- Instruction memory interface.
      rv2imem_PCs               => rv2imem_PCs,
      rv2imem_fetch             => rv2imem_fetch,
      imem2rv_instr             => imem2rv_instr,
      imem2rv_fault             => imem2rv_fault,
      
      -- Data memory interface.
      rv2dmem_addr              => rv2dmem_addr,
      rv2dmem_writeEnable       => rv2dmem_writeEnable,
      rv2dmem_writeMask         => rv2dmem_writeMask,
      rv2dmem_writeData         => rv2dmem_writeData,
      rv2dmem_readEnable        => rv2dmem_readEnable,
      dmem2rv_readData          => dmem2rv_readData,
      dmem2rv_fault             => dmem2rv_fault,
      
      -- Control/debug bus interface.
      dbg2rv_addr               => dbg2rv_addr,
      dbg2rv_readEnable         => dbg2rv_readEnable,
      dbg2rv_writeEnable        => dbg2rv_writeEnable,
      dbg2rv_writeMask          => dbg2rv_writeMask,
      dbg2rv_writeData          => dbg2rv_writeData,
      rv2dbg_readData           => rv2dbg_readData
      
    );
    
    -- Connect cores to cache.
    cache_core_iface_gen : for i in 0 to 3 generate
      
      -- Connect signals from cores to cache.
      atomsToCache(i).decouple    <= rv2mem_decouple(i);
      atomsToCache(i).PC          <= rv2imem_PCs(i);
      atomsToCache(i).fetch       <= rv2imem_fetch(i);
      atomsToCache(i).addr        <= rv2dmem_addr(i);
      atomsToCache(i).readEnable  <= rv2dmem_readEnable(i);
      atomsToCache(i).writeData   <= rv2dmem_writeData(i);
      atomsToCache(i).writeMask   <= rv2dmem_writeMask(i);
      atomsToCache(i).writeEnable <= rv2dmem_writeEnable(i);
      atomsToCache(i).bypass      <= atomsToCache(i).addr(31)
        and (atomsToCache(i).writeEnable or atomsToCache(i).readEnable);
      
      -- There are no other stall signals for the rvex than the cache itself,
      -- so we just feed the stall output directly back into the input.
      atomsToCache(i).stall       <= rv2mem_stallOut(i); --TODO: check for new core (used to be cacheToAtoms(i).stall)
      
      -- Connect signals from cache to core.
      mem2rv_stallIn(i)           <= cacheToAtoms(i).stall;     
      
      dmem2rv_readData(i)         <=  cacheToAtoms(i).readData;
    end generate;
    
    --cache_core_instr_connect_gen : for i in 0 to 7 generate
      --doesnt work
      --imem2rv_instr(i)            <= cacheToAtoms(i/2).instr(((i mod 1)*32)+31 downto ((i mod 1)*32));
    --end generate;
    cache_core_instr_connect_gen : for i in 0 to 3 generate
      imem2rv_instr(i*2)              <= cacheToAtoms(i).instr(31 downto 0);
      imem2rv_instr((i*2)+1)          <= cacheToAtoms(i).instr(63 downto 32);
    end generate;
    
    -- Bus clock is always enabled.
    clkEnBus <= '1';
    
    -- Same for CPU clock.
    clkEnCPU <= '1';
    
    -- TODO: connect invalidation signals to something meaningful.
    invalToCache.invalEnable <= '0';
    invalToCache.invalAddr   <= (others => '0');
    invalToCache.flushICache <= '0';
    invalToCache.flushDCache <= '0';
  
    --Connect some ctrl and status signals to our APB registers
    rctrl2rvsa_run            <= "1111"; --keep em running
    rctrl2rvsa_reset          <= apb_reg.ctrl(3 downto 0);
    


  -- Counts running cycles
  cycle_counter : process(clk)
  begin
    if rising_edge(clk) then
      for i in 0 to 3 loop
        if vex_reset_p = '1' or cycles_reset_s(i) = '1' then
          cycles_s(i) <= (others => '0');
        elsif (mem2rv_StallIn(i) = '0') and (rvsa2rctrl_idle(i) = '1') then
            cycles_s(i) <= std_logic_vector(unsigned(cycles_s(i)) + 1);
        end if;
      end loop;
    end if;
  end process cycle_counter;


  dbg2rv_addr(31 downto 8) <= (others => '0');
  dbg2rv_addr(7 downto 0) <= apbiglob.paddr(7 downto 0);
  dbg2rv_readEnable <= apbiglob.penable and not apbiglob.pwrite;
  dbg2rv_writeEnable <= apbiglob.penable and apbiglob.pwrite;
  dbg2rv_writeMask    <= (others => '1');


  -- APB interface
  apboglob.pirq    <= (others => '0');
  apboglob.pindex  <= pindexglob;
  apboglob.pconfig <= pconfigglob;

  apb_comb : process(apb_reg, apbiglob, cycles_s, done_s, rctrl2rvsa_run)
    variable v : apb_registers;
  begin
    v := apb_reg;

    -- Read register
    apboglob.prdata  <= (others => '0');
    cycles_reset_s   <= "0000";
    if (apbiglob.psel(pindexglob) and apbiglob.penable and not apbiglob.pwrite) = '1' then
      apboglob.prdata <= rv2dbg_readData;
    
      



--Old registers
--      case apbiglob.paddr(6 downto 2) is
--        when "00000" =>
--            apboglob.prdata <= apb_reg.ctrl;
--        when "00001" =>
--            apboglob.prdata <= apb_reg.status;
--        when "00100" =>
--            apboglob.prdata <= cycles_s(0);
--            cycles_reset_s(0) <= '1';
--        when "00101" =>
--            apboglob.prdata <= cycles_s(1);
--            cycles_reset_s(1) <= '1';
--        when "00110" =>
--            apboglob.prdata <= cycles_s(2);
--            cycles_reset_s(2) <= '1';
--        when "00111" =>
--            apboglob.prdata <= cycles_s(3);
--            cycles_reset_s(3) <= '1';
--        when "01000" =>
--            apboglob.prdata <= rv2imem_PCs(0);
--        when "01001" =>
--            apboglob.prdata <= rv2imem_PCs(1);
--        when "01010" =>
--            apboglob.prdata <= rv2imem_PCs(2);
--        when "01011" =>
--            apboglob.prdata <= rv2imem_PCs(3);
--        when others =>
--            apboglob.prdata <= (others => '0');
--      end case;
    end if;

    -- Write registers
    if (apbiglob.psel(pindexglob) and apbiglob.penable and apbiglob.pwrite) = '1' then      
       dbg2rv_writeData    <= apbiglob.pwdata;
--      case apbiglob.paddr(6 downto 2) is
--        when "00000" =>
--          v.ctrl := apbiglob.pwdata;
--        when others =>
--      end case;
    end if;
    
    -- Self resetting CTRL register
    for i in 0 to 3 loop
      if apb_reg.ctrl(i) = '1' then
        v.ctrl(i) := '0';
      end if;
    end loop;

    -- Status Register
    v.status(3 downto 0) := rvsa2rctrl_done;
    v.status(7 downto 4) := rvsa2rctrl_idle;

    apb_reg_in <= v;
  end process;

  -- APB registers
  regs : process (clk)
  begin
    if rising_edge(clk) then
      -- Reset registers
      if reset = '0' then
        apb_reg.ctrl              <= (others => '0');
        apb_reg.status            <= (others => '0');
      else
        apb_reg <= apb_reg_in;
      end if;
    end if;
  end process;

--  reconfig_process: process
--  begin  -- process reconfig_process
--    core_config <= "00";
--    wait for 19230 ns;
--    core_config <= "11";
--    wait;
--  end process reconfig_process;

  --for now we enable 1 core (8-way config)
  --run_array <= apb_reg.ctrl(10 downto 7);
  
  -- What is this even supposed to be doing? I don't get it. Seemingly it's
  -- supposed to synchronize things for reconfiguration within one cycle
  -- because there's no flushing or something, but because its inputs are
  -- based on something which is dependent on the configuration it passes
  -- through all possible configurations in a single cycle in the worst case.
  -- The timing does not like this. Also, the run/stall output from this thing
  -- isn't even used. I've just thrown random registers in the output to
  -- prevent the combinatorial loop/hazards, but this needs to be looked into
  -- better...
  --
  -- Here's the critical path btw.
  -- Paths for end point vex/rvex_1/fetch_combined_1/Fetch_unit_number[1].fetch_1/program_counter_r_25 (SLICE_X121Y110.B6), 10622101738 paths 
  -- -------------------------------------------------------------------------------- 
  -- Slack (setup path):     -1.426ns (requirement - (data path - clock path skew + uncertainty)) 
  --   Source:               vex/cache/instruction_cache/cache_block_gen[1].cache_block_n/tag_ram/Mram_ram_tag (RAM) 
  --   Destination:          vex/rvex_1/fetch_combined_1/Fetch_unit_number[1].fetch_1/program_counter_r_25 (FF) 
  --   Requirement:          26.666ns 
  --   Data Path Delay:      27.668ns (Levels of Logic = 32) 
  --   Clock Path Skew:      -0.351ns (1.462 - 1.813) 
  --   Source Clock:         clkm rising at 0.000ns 
  --   Destination Clock:    clkm rising at 26.666ns 
  --   Clock Uncertainty:    0.073ns 
  --  
  --   Clock Uncertainty:          0.073ns  ((TSJ^2 + DJ^2)^1/2) / 2 + PE 
  --     Total System Jitter (TSJ):  0.070ns 
  --     Discrete Jitter (DJ):       0.127ns 
  --     Phase Error (PE):           0.000ns 
  --  
  --   Maximum Data Path at Slow Process Corner: vex/cache/instruction_cache/cache_block_gen[1].cache_block_n/tag_ram/Mram_ram_tag to vex/rvex_1/fetch_combined_1/Fetch_unit_number[1].fetch_1/program_counter_r_25 
  --     Location             Delay type         Delay(ns)  Physical Resource 
  --                                                        Logical Resource(s) 
  --     -------------------------------------------------  ------------------- 
  --     RAMB36_X7Y14.DOADO15 Trcko_DO              2.073   vex/cache/instruction_cache/cache_block_gen[1].cache_block_n/tag_ram/Mram_ram_tag 
  --                                                        vex/cache/instruction_cache/cache_block_gen[1].cache_block_n/tag_ram/Mram_ram_tag 
  --     SLICE_X141Y69.B4     net (fanout=1)        1.023   vex/cache/instruction_cache/cache_block_gen[1].cache_block_n/tag_ram/cpuTag_mem(15) 
  --     SLICE_X141Y69.CMUX   Topbc                 0.558   vex/cache/data_cache/cache_block_gen[0].cache_block_n/valid_ram/Mmux_cpuOffset[5]_ram_valid[63]_Mux_8_o_133 
  --                                                        vex/cache/instruction_cache/cache_block_gen[1].cache_block_n/tag_ram/Mcompar_cpuHit_lut(5) 
  --                                                        vex/cache/instruction_cache/cache_block_gen[1].cache_block_n/tag_ram/Mcompar_cpuHit_cy(6) 
  --     SLICE_X131Y82.A6     net (fanout=1)        1.045   vex/cache/instruction_cache/cache_block_gen[1].cache_block_n/cpuHit 
  --     SLICE_X131Y82.A      Tilo                  0.068   vex/cache/instruction_cache/outMuxDemux[0][1]_hit 
  --                                                        vex/cache/instruction_cache/cache_block_gen[1].cache_block_n/cpuHitValid1 
  --     SLICE_X112Y96.D5     net (fanout=2)        1.292   vex/cache/instruction_cache/outMuxDemux[0][1]_hit 
  --     SLICE_X112Y96.D      Tilo                  0.068   vex/apb_reg_ctrl(6) 
  --                                                        vex/cache/instruction_cache/Mmux_outMuxDemux[1][0]_hit111 
  --     SLICE_X97Y112.B6     net (fanout=312)      1.401   vex/cache/instruction_cache/outMuxDemux[1][1]_hit 
  --     SLICE_X97Y112.B      Tilo                  0.068   vex/N402 
  --                                                        vex/cache/instruction_cache/Mmux_outMuxDemux[2][0]_PC131 
  --     SLICE_X111Y95.A6     net (fanout=177)      1.296   vex/cache/instruction_cache/outMuxDemux_logic_gen.outMuxDemux_logic_gen_b[1].outMuxDemux_logic.outHi_PC(3) 
  --     SLICE_X111Y95.A      Tilo                  0.068   vex/cache/instruction_cache/cacheToAtoms[3]_instr(33)(161)3 
  --                                                        vex/cache/instruction_cache/cacheToAtoms[3]_instr(33)(161)5 
  --     SLICE_X114Y97.C6     net (fanout=1)        0.428   vex/cacheToAtoms[3]_instr(33) 
  --     SLICE_X114Y97.C      Tilo                  0.068   vex/configuration_control_1/current_offset[0][1]_current_offset[3][1]_OR_3382_o1 
  --                                                        vex/configuration_control_1/current_offset[3][1]_instruction[3][1]_AND_3542_o1 
  --     SLICE_X113Y97.B6     net (fanout=3)        0.242   vex/configuration_control_1/current_offset[3][1]_instruction[3][1]_AND_3542_o 
  --     SLICE_X113Y97.B      Tilo                  0.068   vex/issue_ctrl(0)(0) 
  --                                                        vex/configuration_control_1/current_offset[0][1]_current_offset[3][1]_OR_3368_o 
  --     SLICE_X113Y97.C6     net (fanout=1)        0.228   vex/configuration_control_1/current_offset[0][1]_current_offset[3][1]_OR_3368_o 
  --     SLICE_X113Y97.C      Tilo                  0.068   vex/issue_ctrl(0)(0) 
  --                                                        vex/configuration_control_1/Mmux_next_offset(0)11 
  --     SLICE_X108Y99.C5     net (fanout=48)       0.502   vex/issue_ctrl(0)(0) 
  --     SLICE_X108Y99.C      Tilo                  0.068   vex/cache/instruction_cache/outMuxDemux[1][1]_line(1) 
  --                                                        vex/configuration_control_1/next_offset[1][1]_next_offset[0][1]_not_equal_30_o11 
  --     SLICE_X108Y100.B5    net (fanout=803)      0.417   vex/cacheDecoupleVect(0) 
  --     SLICE_X108Y100.B     Tilo                  0.068   vex/cache/instruction_cache/outMuxDemux[1][0]_line(161) 
  --                                                        vex/cache/instruction_cache/outMuxDemux[1][0]_line(161)1 
  --     SLICE_X108Y100.A6    net (fanout=2)        0.129   vex/cache/instruction_cache/outMuxDemux[1][0]_line(161) 
  --     SLICE_X108Y100.A     Tilo                  0.068   vex/cache/instruction_cache/outMuxDemux[1][0]_line(161) 
  --                                                        vex/cache/instruction_cache/_n1926(161)11 
  --     SLICE_X109Y98.B1     net (fanout=2)        0.613   vex/cache/instruction_cache/_n1926(161)1 
  --     SLICE_X109Y98.B      Tilo                  0.068   vex/cache/instruction_cache/cache_block_gen[3].cache_block_n/miss_controller/line_buffer_87 
  --                                                        vex/cache/instruction_cache/cacheToAtoms[0]_instr(33)(161)1 
  --     SLICE_X109Y98.A6     net (fanout=1)        0.110   vex/cache/instruction_cache/cacheToAtoms[0]_instr(33)(161) 
  --     SLICE_X109Y98.A      Tilo                  0.068   vex/cache/instruction_cache/cache_block_gen[3].cache_block_n/miss_controller/line_buffer_87 
  --                                                        vex/cache/instruction_cache/cacheToAtoms[0]_instr(33)(161)3 
  --     SLICE_X109Y98.C6     net (fanout=4)        0.238   vex/cacheToAtoms[0]_instr(33) 
  --     SLICE_X109Y98.C      Tilo                  0.068   vex/cache/instruction_cache/cache_block_gen[3].cache_block_n/miss_controller/line_buffer_87 
  --                                                        vex/configuration_control_1/current_offset[0][1]_current_offset[3][1]_OR_3389_o 
  --     SLICE_X109Y98.D5     net (fanout=2)        0.316   vex/configuration_control_1/current_offset[0][1]_current_offset[3][1]_OR_3389_o 
  --     SLICE_X109Y98.D      Tilo                  0.068   vex/cache/instruction_cache/cache_block_gen[3].cache_block_n/miss_controller/line_buffer_87 
  --                                                        vex/configuration_control_1/Mmux_next_offset(3)21 
  --     SLICE_X97Y112.A6     net (fanout=44)       1.226   vex/issue_ctrl(3)(1) 
  --     SLICE_X97Y112.A      Tilo                  0.068   vex/N402 
  --                                                        vex/configuration_control_1/next_offset[3][1]_next_offset[2][1]_not_equal_27_o1 
  --     SLICE_X96Y110.C6     net (fanout=416)      0.472   vex/cacheDecoupleVect(2) 
  --     SLICE_X96Y110.C      Tilo                  0.068   vex/cache/instruction_cache/outMuxDemux[2][2]_PC(3) 
  --                                                        vex/cache/instruction_cache/Mmux_outMuxDemux[2][0]_PC111 
  --     SLICE_X95Y111.B4     net (fanout=124)      0.478   vex/cache/instruction_cache/outMuxDemux[2][2]_PC(3) 
  --     SLICE_X95Y111.B      Tilo                  0.068   vex/cache/instruction_cache/outMuxDemux[1][1]_line(123) 
  --                                                        vex/cache/instruction_cache/cacheToAtoms[2]_instr(33)(161)2 
  --     SLICE_X97Y110.B6     net (fanout=1)        0.365   vex/cache/instruction_cache/cacheToAtoms[2]_instr(33)(161)1 
  --     SLICE_X97Y110.B      Tilo                  0.068   vex/cache/instruction_cache/_n1926(101)1 
  --                                                        vex/configuration_control_1/current_offset[2][1]_instruction[2][1]_AND_3537_o1 
  --     SLICE_X100Y113.C6    net (fanout=4)        0.563   vex/configuration_control_1/current_offset[2][1]_instruction[2][1]_AND_3537_o 
  --     SLICE_X100Y113.C     Tilo                  0.068   vex/cache/instruction_cache/outMuxDemux[1][1]_line(92) 
  --                                                        vex/configuration_control_1/current_offset[0][1]_current_offset[3][1]_OR_3375_o3 
  --     SLICE_X100Y115.B6    net (fanout=1)        0.382   vex/configuration_control_1/current_offset[0][1]_current_offset[3][1]_OR_3375_o 
  --     SLICE_X100Y115.B     Tilo                  0.068   vex/configuration_control_1/current_offset_1(0) 
  --                                                        vex/configuration_control_1/Mmux_next_offset(1)11 
  --     SLICE_X100Y115.A6    net (fanout=82)       0.142   vex/issue_ctrl(1)(0) 
  --     SLICE_X100Y115.A     Tilo                  0.068   vex/configuration_control_1/current_offset_1(0) 
  --                                                        vex/configuration_control_1/next_offset[2][1]_next_offset[1][1]_not_equal_29_o1 
  --     SLICE_X85Y142.B6     net (fanout=668)      1.875   vex/cacheDecoupleVect(1) 
  --     SLICE_X85Y142.B      Tilo                  0.068   vex/rvex_1/instr_r(195) 
  --                                                        vex/cache/instruction_cache/cacheToAtoms[3]_instr(3)(3)3 
  --     SLICE_X53Y133.D3     net (fanout=3)        1.870   vex/cacheToAtoms[3]_instr(3) 
  --     SLICE_X53Y133.CMUX   Topdc                 0.348   vex/rvex_1/N794 
  --                                                        vex/rvex_1/pipe_lane_gen[6].pipe_lane_1/decoder_1/Mmux_read_address_b_s(2:0)21_F 
  --                                                        vex/rvex_1/pipe_lane_gen[6].pipe_lane_1/decoder_1/Mmux_read_address_b_s(2:0)21 
  --     SLICE_X48Y134.D5     net (fanout=34)       0.535   vex/rvex_1/read_address_b(6)(1) 
  --     SLICE_X48Y134.D      Tilo                  0.068   vex/rvex_1/br_registers_1/Mmux_read_address[6][4]_read_port_62_OUT(0)_92 
  --                                                        vex/rvex_1/br_registers_1/Mmux_read_address[6][4]_read_port_62_OUT(0)_92 
  --     SLICE_X51Y134.D4     net (fanout=1)        0.520   vex/rvex_1/br_registers_1/Mmux_read_address[6][4]_read_port_62_OUT(0)_92 
  --     SLICE_X51Y134.CMUX   Topdc                 0.348   vex/rvex_1/br_registers_1/Mmux_read_address[6][4]_read_port_62_OUT(0)_7 
  --                                                        vex/rvex_1/br_registers_1/Mmux_read_address[6][4]_read_port_62_OUT(0)_4 
  --                                                        vex/rvex_1/br_registers_1/Mmux_read_address[6][4]_read_port_62_OUT(0)_2_f7 
  --     SLICE_X53Y134.B6     net (fanout=1)        0.368   vex/rvex_1/br_registers_1/read_address[6][4]_read_port_62_OUT(0) 
  --     SLICE_X53Y134.B      Tilo                  0.068   vex/rvex_1/br_registers_1/registers_trst_24LogicTrst 
  --                                                        vex/rvex_1/pipe_lane_gen[6].pipe_lane_1/decoder_1/branch_unit_gen.branch_forwarding_generate.forward_decode_1/Mmux_forward_rb33 
  --     SLICE_X53Y134.A6     net (fanout=1)        0.110   vex/rvex_1/pipe_lane_gen[6].pipe_lane_1/decoder_1/branch_unit_gen.branch_forwarding_generate.forward_decode_1/Mmux_forward_rb32 
  --     SLICE_X53Y134.A      Tilo                  0.068   vex/rvex_1/br_registers_1/registers_trst_24LogicTrst 
  --                                                        vex/rvex_1/pipe_lane_gen[6].pipe_lane_1/decoder_1/branch_unit_gen.branch_forwarding_generate.forward_decode_1/Mmux_forward_rb34 
  --     SLICE_X56Y129.C6     net (fanout=1)        0.567   vex/rvex_1/pipe_lane_gen[6].pipe_lane_1/decoder_1/branch_unit_gen.branch_forwarding_generate.forward_decode_1/Mmux_forward_rb33 
  --     SLICE_X56Y129.C      Tilo                  0.068   vex/rvex_1/pipe_lane_gen[6].pipe_lane_1/decoder_1/operand_b_r 
  --                                                        vex/rvex_1/pipe_lane_gen[6].pipe_lane_1/decoder_1/branch_unit_gen.branch_forwarding_generate.forward_decode_1/Mmux_forward_rb35 
  --     SLICE_X69Y118.A5     net (fanout=2)        1.186   vex/rvex_1/pipe_lane_gen[6].pipe_lane_1/decoder_1/branch_unit_gen.branch_forwarding_generate.forward_decode_1/Mmux_forward_rb34 
  --     SLICE_X69Y118.A      Tilo                  0.068   vex/rvex_1/fetch_combined_1/Fetch_unit_number[2].fetch_1/flush_reg 
  --                                                        vex/rvex_1/pipe_lane_gen[6].pipe_lane_1/decoder_1/branch_unit_gen.branch_unit_1/Mmux_PCSrc11 
  --     SLICE_X116Y109.B5    net (fanout=40)       1.984   vex/rvex_1/PCSrc_s(6) 
  --     SLICE_X116Y109.B     Tilo                  0.068   vex/rvex_1/fetch_combined_1/Fetch_unit_number[1].fetch_1/program_counter_r(11) 
  --                                                        vex/rvex_1/fetch_combined_1/Mmux_PCSrc_s(1)1 
  --     SLICE_X121Y110.B6    net (fanout=33)       0.444   vex/rvex_1/fetch_combined_1/PCSrc_s(1) 
  --     SLICE_X121Y110.CLK   Tas                   0.070   vex/rvex_1/fetch_combined_1/Fetch_unit_number[1].fetch_1/program_counter_r(25) 
  --                                                        vex/rvex_1/fetch_combined_1/Fetch_unit_number[1].fetch_1/Mmux_program_counter_s193 
  --                                                        vex/rvex_1/fetch_combined_1/Fetch_unit_number[1].fetch_1/program_counter_r_25 
  --     -------------------------------------------------  --------------------------- 
  --     Total                                     27.668ns (5.301ns logic, 22.367ns route) 
  --                                                        (19.2% logic, 80.8% route) 
  --
--  configuration_control_1 : entity work.configuration_control
--    port map (
--      clk         => clk,
--      reset       => vex_reset_p,
--      issue_ctrl  => apb_reg.ctrl(6 downto 5),
--      core_enable => apb_reg.ctrl(10 downto 7),
--      instruction => instr_s,
--      offset      => issue_ctrl_n,
--      cache_ctrl  => cacheDecoupleVect_n);
--
--  process (clk) is
--  begin
--    if rising_edge(clk) then
--      if vex_reset_p = '1' then
--        issue_ctrl <= (others => "11");
--        cacheDecoupleVect <= "1000";
--      else
--        issue_ctrl <= issue_ctrl_n;
--        cacheDecoupleVect <= cacheDecoupleVect_n;
--      end if;
--    end if;
--  end process;
  
end architecture behavioural;

