-- r-VEX processor MMU
-- Copyright (C) 2008-2016 by TU Delft.
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

-- 6. r-VEX was developed by Stephan Wong, Thijs van As, Fakhar Anjam,
-- Roel Seedorf, Anthony Brandon, Jeroen van Straten. r-VEX is currently
-- maintained by TU Delft (J.S.S.M.Wong@tudelft.nl).

-- 7. The MMU was developed by Jens Johansen.

-- Copyright (C) 2008-2016 by TU Delft.

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library rvex;
use rvex.common_pkg.all;
use rvex.core_pkg.all;
use rvex.core_trap_pkg.all;
use rvex.cache_pkg.all;
use rvex.bus_pkg.all;


entity cache_mmu is
  generic (
    RCFG                        : rvex_generic_config_type := rvex_cfg;
    CCFG                        : cache_generic_config_type := cache_cfg
  );
  port (

    -- Clock input.
    clk                         : in  std_logic;
    
    -- Active high reset input.
    reset                       : in  std_logic;
    
    -- Active high CPU interface clock enable input.
    clkEnCPU                    : in  std_logic;
    
    -- control registers input
    rv2mmu_pageTablePointers    : in  rvex_address_array(2**RCFG.numLaneGroupsLog2-1 downto 0);
    rv2mmu_addressSpaceID       : in  rvex_address_array(2**RCFG.numLaneGroupsLog2-1 downto 0);
    rv2mmu_configWord           : in  rvex_data_type;
    rv2mmu_enable               : in  std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    rv2mmu_kernelMode           : in  std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    rv2mmu_bypass               : in  std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    rv2mmu_writeToCleanTrapEn   : in  std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    rv2mmu_tlbDirection         : in  rvex_byte_array(2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    -- signals coming from the rvex pipelane groups
    rv2mem_stallOut             : in  std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    rv2dmem_readEnable          : in  std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    rv2dmem_writeEnable         : in  std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    rv2imem_fetch               : in  std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    rv2mmu_decouple             : in  std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    rv2mmu_PCsVtags             : in  std_logic_vector(2**RCFG.numLaneGroupsLog2 * mmutagSize(CCFG)-1 downto 0);
    rv2mmu_dataVtags            : in  std_logic_vector(2**RCFG.numLaneGroupsLog2 * mmutagSize(CCFG)-1 downto 0);
    
    -- rvex tlb flush interface
    rv2mmu_flush                : in  std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    rv2mmu_flushMode            : in  rvex_flushMode_array(2**RCFG.numLaneGroupsLog2-1 downto 0); 
    rv2mmu_flushAsid            : in  rvex_data_array(2**RCFG.numLaneGroupsLog2-1 downto 0);  
    rv2mmu_flushLowRange        : in  rvex_data_array(2**RCFG.numLaneGroupsLog2-1 downto 0); 
    rv2mmu_flushHighRange       : in  rvex_data_array(2**RCFG.numLaneGroupsLog2-1 downto 0); 
    
    -- signals from the mmu to the rVEX
    mem2rv_stall                : out std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    mmu2rv_trap                 : out std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    mmu2rv_trapStatus           : out rvex_data_array(2**RCFG.numLaneGroupsLog2-1 downto 0);      

    -- signals from the mmu to the cache
    mmu2icache_stall            : out std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    mmu2dcache_stall            : out std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    mmu2cache_PCsPtags          : out std_logic_vector(2**RCFG.numLaneGroupsLog2 * mmutagSize(CCFG)-1 downto 0);
    mmu2cache_dataPtags         : out std_logic_vector(2**RCFG.numLaneGroupsLog2 * mmutagSize(CCFG)-1 downto 0);
    mmu2dcache_bypass           : out std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    -- signals from the cache to the rvex routed through the mmu
    cache2rv_stall              : in  std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    -- performance counters 
    mmu2rv_itlb_misses          : out rvex_data_type;
    mmu2rv_dtlb_misses          : out rvex_data_type;
    mmu2rv_mmmu_stall_cycles    : out rvex_data_type;

    -- signals between the mmu and the memory (page table access)
    mmu2mem                     : out bus_mst2slv_type;
    mem2mmu                     : in  bus_slv2mst_type     
    
  );
end cache_mmu;


architecture structural of cache_mmu is

  type asid_array_type    is array (2**RCFG.numLaneGroupsLog2-1 downto 0)
                          of std_logic_vector(mmuAsidSize(CCFG)-1 downto 0);
  type tag_array_type     is array (2**RCFG.numLaneGroupsLog2-1 downto 0)
                          of std_logic_vector(mmutagSize(CCFG)-1 downto 0);
  type integer_array_type is array (2**RCFG.numLaneGroupsLog2-1 downto 0)
                          of integer;
    
  type inNetworkEdge_type is record
    
    decouple                    : std_logic;
    bypass                      : std_logic;
    flush                       : std_logic;

    readEnable                  : std_logic;
    writeEnable                 : std_logic;
    data_Vtag                   : std_logic_vector(mmutagSize(CCFG)-1 downto 0);
    
  end record;
  
  -- Input routing network array types.
  type inNetworkLevel_type is array (0 to 2**RCFG.numLaneGroupsLog2-1) of inNetworkEdge_type;
  type inNetworkLevels_type is array (0 to RCFG.numLaneGroupsLog2) of inNetworkLevel_type;
  
  type outNetworkEdge_type is record
        
    stall_rv_data               : std_logic;
    stall_cache_data            : std_logic;
    stall_rv_inst               : std_logic;
    stall_cache_inst            : std_logic;
    trap                        : std_logic;
    trapCode                    : natural;
    trapInfo                    : natural;

    data_miss                   : std_logic;
    cache_bypass                : std_logic;
    data_Ptag                   : std_logic_vector(mmutagSize(CCFG)-1 downto 0);
    data_tlb_done               : std_logic;
    data_tlb_update             : std_logic;
    
  end record;
  
  -- Output routing network array types.
  type outNetworkLevel_type is array (0 to 2**RCFG.numLaneGroupsLog2-1) of outNetworkEdge_type;
  type outNetworkLevels_type is array (0 to RCFG.numLaneGroupsLog2) of outNetworkLevel_type;
  
  -- Output routing network signals.
  signal outNetwork             : outNetworkLevels_type;
  
  -- Input routing network signals.
  signal inNetwork              : inNetworkLevels_type;

  -- signals from the tlb to the table walk hardware 
  signal tlb2tw_inst_miss               : std_logic_vector(2**RCFG.numLaneGroupsLog2  -1 downto 0);
  signal tlb2tw_data_miss               : std_logic_vector(2**RCFG.numLaneGroupsLog2  -1 downto 0);
  signal tlb2tw_dirty                   : std_logic_vector(2**RCFG.numLaneGroupsLog2 - 1 downto 0);
  signal tw2tlb_dirtyAck                : std_logic_vector(2**RCFG.numLaneGroupsLog2 - 1 downto 0);
  signal tw_inst_miss                   : std_logic_vector(2**RCFG.numLaneGroupsLog2 - 1 downto 0);
  signal tw_data_miss                   : std_logic_vector(2**RCFG.numLaneGroupsLog2 - 1 downto 0);
  signal tw_data_Vtag                   : std_logic_vector(mmutagSize(CCFG)-1 downto 0);
  
  -- signals from the table walk hardware to the tlb
  signal tw2tlb_inst_ready              : std_logic_vector(2**RCFG.numLaneGroupsLog2 - 1 downto 0);
  signal tw2tlb_data_ready              : std_logic_vector(2**RCFG.numLaneGroupsLog2 - 1 downto 0);
  signal tw2tlb_pte                     : rvex_data_type;        
  
  -- signals used to connect the tlbs to the correct slices of the (collapsed) tag arrays
  signal inst_Vtag                      : tag_array_type;
  signal inst_Vtag_r                    : tag_array_type;
  signal inst_Vtag_stall                : tag_array_type;
  signal inst_read_Ptag                 : tag_array_type;
  signal data_Vtag                      : tag_array_type;
  signal data_Vtag_r                    : tag_array_type;
  signal data_Vtag_stall                : tag_array_type;
  signal data_read_Ptag                 : tag_array_type;
  signal readEnable_r                   : std_logic_vector(2**RCFG.numLaneGroupsLog2 - 1 downto 0);
  signal writeEnable_r                  : std_logic_vector(2**RCFG.numLaneGroupsLog2 - 1 downto 0);
  signal fetch_r                        : std_logic_vector(2**RCFG.numLaneGroupsLog2 - 1 downto 0); 
  signal bypass_r                       : std_logic_vector(2**RCFG.numLaneGroupsLog2 - 1 downto 0);
  signal readEnable_stall               : std_logic_vector(2**RCFG.numLaneGroupsLog2 - 1 downto 0);
  signal writeEnable_stall              : std_logic_vector(2**RCFG.numLaneGroupsLog2 - 1 downto 0);
  signal fetch_stall                    : std_logic_vector(2**RCFG.numLaneGroupsLog2 - 1 downto 0);
  signal bypass_stall                   : std_logic_vector(2**RCFG.numLaneGroupsLog2 - 1 downto 0); 
              
  -- tlb bypass signals
  signal inst_tlb_bypass                : std_logic_vector(2**RCFG.numLaneGroupsLog2 - 1 downto 0);
  signal data_tlb_bypass                : std_logic_vector(2**RCFG.numLaneGroupsLog2 - 1 downto 0);
  
  -- mmu signals per lane 
  signal rv2mmu_laneEnable              : std_logic_vector(2**RCFG.numLaneGroupsLog2 - 1 downto 0);
  signal rv2mmu_lanePageTablePointers   : rvex_address_array(2**RCFG.numLaneGroupsLog2-1 downto 0);
  signal rv2mmu_laneAddressSpaceID      : asid_array_type;
  signal rv2mmu_laneWriteToCleanTrapEn  : std_logic_vector(2**RCFG.numLaneGroupsLog2 - 1 downto 0);
  
  -- stall stable Vtags for the table walk
  signal rv2tw_PCsVtags                 : std_logic_vector(2**RCFG.numLaneGroupsLog2 * mmutagSize(CCFG)-1 downto 0);
  signal rv2tw_dataVtags                : std_logic_vector(2**RCFG.numLaneGroupsLog2 * mmutagSize(CCFG)-1 downto 0);
  
  -- traps
  signal mmu2rv_fetchPageFault          : std_logic_vector(2**RCFG.numLaneGroupsLog2 - 1 downto 0);
  signal mmu2rv_dataPageFault           : std_logic_vector(2**RCFG.numLaneGroupsLog2 - 1 downto 0);
  signal mmu2rv_writeToCleanPage        : std_logic_vector(2**RCFG.numLaneGroupsLog2 - 1 downto 0);
  signal mmu2rv_writeAccessViolation    : std_logic_vector(2**RCFG.numLaneGroupsLog2 - 1 downto 0);
  signal mmu2rv_kernelSpaceViolation    : std_logic_vector(2*2**RCFG.numLaneGroupsLog2 - 1 downto 0);
  
  -- mmu internal stall signals
  signal inst_tlb_done                  : std_logic_vector(2**RCFG.numLaneGroupsLog2 - 1 downto 0);
  signal data_stall_r                   : std_logic_vector(2**RCFG.numLaneGroupsLog2 - 1 downto 0) := (others => '0');
  signal inst_stall_r                   : std_logic_vector(2**RCFG.numLaneGroupsLog2 - 1 downto 0) := (others => '0');
  signal flush_busy                     : std_logic_vector(2*2**RCFG.numLaneGroupsLog2 - 1 downto 0);
  signal mmu2cache_stall_r              : std_logic_vector(2**RCFG.numLaneGroupsLog2 - 1 downto 0);
  signal mmu2cache_stall_r2             : std_logic_vector(2**RCFG.numLaneGroupsLog2 - 1 downto 0);
  
  -- flushing
  signal rv2mmu_flush_r                 : std_logic_vector(2**RCFG.numLaneGroupsLog2 - 1 downto 0) := (others => '0');    
  signal flushing                       : std_logic := '0';   
  signal flush_active                   : integer range 0 to 2**RCFG.numLaneGroupsLog2 - 1;
  signal flush_stall                    : std_logic;
  signal tlb_flush                      : std_logic;
  signal tlb_flushMode                  : rvex_flushMode_type; 
  signal tlb_flushAsid                  : rvex_data_type;  
  signal tlb_flushLowRange              : rvex_data_type; 
  signal tlb_flushHighRange             : rvex_data_type; 
  
  -- data tlb update round robin
  signal tlb_update_state               : std_logic_vector(RCFG.numLaneGroupsLog2 - 1 downto 0);
  
  -- signals for perforance counters 
  signal tw_inst_miss_r                 : std_logic_vector(2**RCFG.numLaneGroupsLog2 - 1 downto 0);
  signal tw_data_miss_r                 : std_logic_vector(2**RCFG.numLaneGroupsLog2 - 1 downto 0);
  signal inst_miss_count                : integer;
  signal data_miss_count                : integer;
  signal mmu_stall_count                : integer;
  signal inst_misses                    : integer range 0 to 2**RCFG.numLaneGroupsLog2;
  signal data_misses                    : integer range 0 to 2**RCFG.numLaneGroupsLog2;
  signal mem2rv_stall_inc               : std_logic_vector(2**RCFG.numLaneGroupsLog2 - 1 downto 0);
    
    
begin

  perf_counters_reg: process(clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        tw_inst_miss_r <= (others => '0');
        tw_data_miss_r <= (others => '0');
        inst_miss_count <= 0;
        data_miss_count <= 0;
        mmu_stall_count <= 0;      
      else
        tw_inst_miss_r <= tw_inst_miss;
        tw_data_miss_r <= tw_data_miss;
        
        inst_miss_count <= inst_miss_count + inst_misses;
        data_miss_count <= data_miss_count + data_misses;      
        if mem2rv_stall_inc(0) = '1' then
          mmu_stall_count <= mmu_stall_count + 1;
        end if;
      end if;
    end if; 
  end process;
    
  perf_counters_count: process(tw_inst_miss, tw_data_miss, tw_inst_miss_r, tw_data_miss_r) is
    variable v_inst_misses : integer range 0 to 2**RCFG.numLaneGroupsLog2;
    variable v_data_misses : integer range 0 to 2**RCFG.numLaneGroupsLog2;
  begin
    v_inst_misses := 0;
    v_data_misses := 0;
    for i in 0 to 2**RCFG.numLaneGroupsLog2 - 1 loop   
      if tw_inst_miss_r(i) = '0' and tw_inst_miss(i) = '1' then
        v_inst_misses := 1; -- v_inst_misses+1;
      end if;
      if tw_data_miss_r(i) = '0' and tw_data_miss(i) = '1' then
        v_data_misses := v_data_misses+1;
      end if;            
    end loop;
    inst_misses <= v_inst_misses;
    data_misses <= v_data_misses;
  end process;
  
  mmu2rv_itlb_misses <= std_logic_vector(to_unsigned(inst_miss_count, rvex_data_type'length));
  mmu2rv_dtlb_misses <= std_logic_vector(to_unsigned(data_miss_count, rvex_data_type'length));
  mmu2rv_mmmu_stall_cycles <= std_logic_vector(to_unsigned(mmu_stall_count, rvex_data_type'length));

    
  tlb_update_sel: process(clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        tlb_update_state <= (RCFG.numLaneGroupsLog2 - 1 downto 0 => '0');
      elsif not (tw2tlb_data_ready = (2**RCFG.numLaneGroupsLog2 - 1 downto 0 => '0')) then
        tlb_update_state <= std_logic_vector(unsigned(tlb_update_state) + 1);
      else
        tlb_update_state <= tlb_update_state;      
      end if;      
    end if;
  end process;

  -- When a context issues a flush command, all the TLBs need to perform the
  -- flush to ensure coherence. When one of the lanes issues a flush, it is
  -- latched here and ditributed to all TLBs. In the worst case all contexts
  -- issue a flush in the same cycle. The flush parameters are stable since 
  -- flushing stall the core. The flush pulse does need to be latched however.
  flush_select: process (
    clk, rv2mmu_flush, rv2mmu_flush_r, flushing, rv2mmu_flushMode,
    rv2mmu_flushAsid, rv2mmu_flushLowRange, rv2mmu_flushHighRange,
    flush_active
  ) is
    -- this is a variable so that a new flush can start in the same cycle as another ends
    variable v_flushing : std_logic; 
  begin
        
    v_flushing := flushing;
        
    if rising_edge(clk) then
    
      -- latch the flush commands           
      if reset = '1' then 
        rv2mmu_flush_r <= (2**RCFG.numLaneGroupsLog2 - 1 downto 0 => '0');
      else
        rv2mmu_flush_r <= rv2mmu_flush_r or rv2mmu_flush;
      end if;
      
      -- wait for an active flush to complete
      if flush_busy = (2*2**RCFG.numLaneGroupsLog2 - 1 downto 0 => '0') then
        v_flushing := '0';           
        rv2mmu_flush_r(flush_active) <= '0'; -- remove this contexts flush from the list     
      end if;
  
      -- initiate a new flush
      tlb_flush <= '0';
      if v_flushing = '0' then
        for i in 0 to 2**RCFG.numLaneGroupsLog2-1 loop
          if rv2mmu_flush_r(i) = '1' then    
            v_flushing         := '1';
            flush_active       <= i;
            rv2mmu_flush_r(i)  <= '0';
            tlb_flush          <= '1';
            exit;
          end if;
        end loop;  
      end if;
    end if;
    
    -- stall the core when a flush is issued and not yet completed
    if not rv2mmu_flush_r = (2**RCFG.numLaneGroupsLog2 - 1 => '0') or v_flushing = '1' then
      flush_stall <= '1';
    else
      flush_stall <= '0';
    end if;
    
    tlb_flushMode      <= rv2mmu_flushMode(flush_active);
    tlb_flushAsid      <= rv2mmu_flushAsid(flush_active);
    tlb_flushLowRange  <= rv2mmu_flushLowRange(flush_active);
    tlb_flushHighRange <= rv2mmu_flushHighRange(flush_active);
    
    flushing <= v_flushing;
  end process;


  -- Because VHDL 97 does not support unconstrained 2D arrays, the tag inputs
  -- for the different lanesgroups are collapsed into a one dimensional array.
  -- In this process the correct slices are extracted for each TLB.
  get_slices: process(rv2mmu_PCsVtags, rv2mmu_dataVtags, inst_read_Ptag, data_read_Ptag, rv2mem_stallOut)
  begin
    tw_data_Vtag <= (others => '0');
    for i in 0 to 2**RCFG.numLaneGroupsLog2-1 loop
      mmu2cache_PCsPtags  ((i+1)*mmutagSize(CCFG)-1 downto i*mmutagSize(CCFG)) <= inst_read_Ptag(i);
      inst_Vtag(i) <= rv2mmu_PCsVtags ((i+1)*mmutagSize(CCFG)-1 downto i*mmutagSize(CCFG));
      data_Vtag(i) <= rv2mmu_dataVtags((i+1)*mmutagSize(CCFG)-1 downto i*mmutagSize(CCFG));
    end loop;
  end process;
  
  
  -- Memory request to the cache must be kept stable during a core stall.
  -- TODO: figure out why instruction access can do without
  register_Vtags: process (
    clk, reset, rv2dmem_readEnable, rv2dmem_writeEnable, rv2imem_fetch,
    rv2mem_stallOut, readEnable_r, writeEnable_r, fetch_r, data_Vtag, inst_Vtag,
    data_Vtag_r, inst_Vtag_r, rv2mmu_bypass, bypass_r
  ) is
  begin 
    for i in 0 to 2**RCFG.numLaneGroupsLog2-1 loop
  
      -- Register the Vtag while the core is running 
      if rising_edge(clk) then
        if reset = '1' then
          readEnable_r(i)     <= '0';
          writeEnable_r(i)    <= '0';
          fetch_r(i)          <= '0';     
          bypass_r(i)         <= '0';              
        elsif rv2mem_stallOut(i) = '0' then
          data_Vtag_r(i)      <= data_Vtag(i);
          inst_Vtag_r(i)      <= inst_Vtag(i);
          readEnable_r(i)     <= rv2dmem_readEnable(i);
          writeEnable_r(i)    <= rv2dmem_writeEnable(i);
          fetch_r(i)          <= rv2imem_fetch(i);
          bypass_r(i)         <= rv2mmu_bypass(i);
        end if;
      end if;
      
      -- If the core stalls, use the Vtag from the last cycle before the stall
      if rv2mem_stallOut(i) = '1' then
        data_Vtag_stall(i)      <= data_Vtag_r(i);
        inst_Vtag_stall(i)      <= inst_Vtag_r(i);
        readEnable_stall(i)     <= readEnable_r(i);
        writeEnable_stall(i)    <= writeEnable_r(i);
        fetch_stall(i)          <= fetch_r(i);
        bypass_stall(i)         <= bypass_r(i);
      else
        data_Vtag_stall(i)      <= data_Vtag(i);
        inst_Vtag_stall(i)      <= inst_Vtag(i);
        readEnable_stall(i)     <= rv2dmem_readEnable(i);
        writeEnable_stall(i)    <= rv2dmem_writeEnable(i);
        fetch_stall(i)          <= rv2imem_fetch(i);
        bypass_stall(i)         <= rv2mmu_bypass(i);
      end if;
      
    end loop;
  end process;
  
  
  collapse: process(data_Vtag_stall, inst_Vtag_stall) is
  begin
    for i in 0 to 2**RCFG.numLaneGroupsLog2-1 loop
      rv2tw_PCsVtags ((i+1)*mmutagSize(CCFG)-1 downto i*mmutagSize(CCFG)) <= inst_Vtag_stall(i);
      rv2tw_dataVtags((i+1)*mmutagSize(CCFG)-1 downto i*mmutagSize(CCFG)) <= data_Vtag_stall(i);
    end loop;
  end process;
  
  -- Register the combined pagefault signal for two cycles to stall the cache a
  -- bit when a pagefault occurs.
  pagefault_reg: process (clk) is
  begin
    if rising_edge(clk) then 
      for i in 0 to 2**RCFG.numLaneGroupsLog2-1 loop 
        if reset = '1' then
          mmu2cache_stall_r(i)  <= '0';
          mmu2cache_stall_r2(i) <= '0';
        elsif (mmu2rv_dataPageFault(i) or mmu2rv_fetchPageFault(i)) = '1' then
          mmu2cache_stall_r(i)  <= '1';
          mmu2cache_stall_r2(i) <= '1';
        else 
          mmu2cache_stall_r2(i) <= mmu2cache_stall_r(i);
          mmu2cache_stall_r(i)  <= '0';
        end if;                
      end loop;
    end if;
  end process;
  
  
  -- When a TLB miss or mark-as-dirty request occurs the cache and core must be
  -- stalled until a table walk is performed. Therefore the stall signal is
  -- registered until the TW succeeds or fails (pagefault). Because a miss or
  -- mark-dirty request are never active at the same time, the same mechnism is 
  -- used for both.
  stall_reg: process (clk) is
  begin
    if rising_edge(clk) then   
      for i in 0 to 2**RCFG.numLaneGroupsLog2-1 loop     
        if reset = '1' then 
          data_stall_r(i) <= '0';   
          inst_stall_r(i) <= '0';
        else
          if (((
            outNetwork(RCFG.numLaneGroupsLog2)(i).trap
            or outNetwork(RCFG.numLaneGroupsLog2)(i).data_tlb_done
            or tw2tlb_dirtyAck(i)
          ) = '1') or rv2mmu_laneEnable(i) = '0') then
            data_stall_r(i) <= '0'; 
          elsif ((tlb2tw_data_miss(i) or tlb2tw_dirty(i)) = '1') then
            data_stall_r(i) <= '1';
          end if;
          if (((outNetwork(RCFG.numLaneGroupsLog2)(i).trap or inst_tlb_done(i)) = '1') or rv2mmu_laneEnable(i) = '0') then
            inst_stall_r(i) <= '0'; 
          elsif (tlb2tw_inst_miss(i) = '1') then
            inst_stall_r(i) <= '1'; 
          end if;
        end if;                
      end loop;   
    end if; 
  end process;
    
    
  -- Some of the signals from the core are indexed by context. Depending on
  -- which context runs on which core the lane signals are determined/
  mux_ctxt_to_lane: process (
    rv2mmu_configWord, rv2mmu_enable, rv2mmu_pageTablePointers,
    rv2mmu_addressSpaceID, rv2mmu_writeToCleanTrapEn, rv2mmu_flush,
    rv2mmu_flushMode, rv2mmu_flushAsid, rv2mmu_flushLowRange,
    rv2mmu_flushHighRange
  ) is
    variable lane_context_index : integer; 
  begin 
    
    for i in 0 to 2**RCFG.numLaneGroupsLog2-1 loop
      
      lane_context_index := to_integer(unsigned( rv2mmu_configWord( i*4+3 downto i*4 ) )); 
      
      if lane_context_index < 2**RCFG.numContextsLog2 then
        rv2mmu_laneEnable(i)            <= rv2mmu_enable(lane_context_index);
        rv2mmu_lanePageTablePointers(i) <= rv2mmu_pageTablePointers(lane_context_index);
        rv2mmu_laneAddressSpaceID(i)    <= rv2mmu_addressSpaceID(lane_context_index)(mmuAsidSize(CCFG)-1 downto 0);
        rv2mmu_laneWriteToCleanTrapEn(i)<= rv2mmu_writeToCleanTrapEn(lane_context_index);
      else
        rv2mmu_laneEnable(i)            <= '0';
        rv2mmu_lanePageTablePointers(i) <= (others => '0');
        rv2mmu_laneAddressSpaceID(i)    <= (others => '0');
        rv2mmu_laneWriteToCleanTrapEn(i)<= '0';
      end if;            
      
    end loop;
  end process;
  
  -- Connect the inputs of the input routing network.
  in_network_input_gen : for i in 0 to 2**RCFG.numLaneGroupsLog2-1 generate
    
    inNetwork(0)(i).decouple       <= rv2mmu_decouple(i);
    inNetwork(0)(i).bypass         <= bypass_stall(i);
    inNetwork(0)(i).readEnable     <= readEnable_stall(i);
    inNetwork(0)(i).writeEnable    <= writeEnable_stall(i);
    inNetwork(0)(i).data_Vtag      <= data_Vtag_stall(i);
    
  end generate;
  
  in_network_logic_gen_b: for lvl in 0 to RCFG.numLaneGroupsLog2 - 1 generate
    in_network_logic: process (inNetwork(lvl), outNetwork(lvl)) is
      variable inLo, inHi       : inNetworkEdge_type;
      variable outLo, outHi     : inNetworkEdge_type;
      variable ind              : unsigned(RCFG.numLaneGroupsLog2-2 downto 0);
      variable indLo, indHi     : unsigned(RCFG.numLaneGroupsLog2-1 downto 0);  
    begin
      for i in 0 to (2**RCFG.numLaneGroupsLog2 / 2) - 1 loop
      
        -- Decode i into an unsigned so we can play around with the bits.
        ind := to_unsigned(i, RCFG.numLaneGroupsLog2-1);
        
        -- Determine the lo and hi indices.
        for j in 0 to RCFG.numLaneGroupsLog2 - 1 loop
          if j < lvl then
            indLo(j) := ind(j);
            indHi(j) := ind(j);
          elsif j = lvl then
            indLo(j) := '0';
            indHi(j) := '1';
          else
            indLo(j) := ind(j-1);
            indHi(j) := ind(j-1);
          end if;
        end loop;
  
        -- Read the input signals into variables for shorthand notation.
        inLo := inNetwork(lvl)(to_integer(indLo));
        inHi := inNetwork(lvl)(to_integer(indHi));
  
        -- Passthrough by default.
        outLo := inLo;
        outHi := inHi;
  
        -- Overwrite lo decouple output to hi decouple input to generate the
        -- decouple network.
        outLo.decouple  := inHi.decouple;
    
        -- If the lo decouple input is low, perform magic to make cache
        -- blocks work together.
        if inLo.decouple = '0' then
          if ((inHi.readEnable or inHi.writeEnable) = '1') then
            outLo.readEnable  := inHi.readEnable;
            outLo.writeEnable := inHi.writeEnable;
            outLo.bypass      := inHi.bypass;
            outLo.data_Vtag   := inHi.data_Vtag;
            if ((inLo.readEnable or inLo.readEnable) = '1') then 
              outLo.readEnable  := '0';
              outLo.writeEnable := '0';
              outHi.readEnable  := '0';
              outHi.writeEnable := '0';
            end if;
          else    
            outHi.readEnable  := inLo.readEnable;
            outHi.writeEnable := inLo.writeEnable;
            outHi.bypass      := inLo.bypass;   
            outHi.data_Vtag   := inLo.data_Vtag;                                              
          end if;    
        end if;
  
        -- Assign the output signals.
        inNetwork(lvl+1)(to_integer(indLo)) <= outLo;
        inNetwork(lvl+1)(to_integer(indHi)) <= outHi;
    
      end loop; -- i
    end process;
  end generate; -- lvl
  
  
  -- Connect the outputs of the input routing network.
  in_network_output_gen: for i in 0 to 2**RCFG.numLaneGroupsLog2-1 generate
    -- Generate the tlb bypass signals. 
    -- the tlb is bypassed when it is disabled or when the lane operates in kernel mode.
    --data_tlb_bypass(i) <= not rv2mmu_laneEnable(i) or bypass_stall(i)
    data_tlb_bypass(i) <= not rv2mmu_laneEnable(i)
                          or inNetwork(RCFG.numLaneGroupsLog2)(i).bypass
                          or not (
                            inNetwork(RCFG.numLaneGroupsLog2)(i).readEnable
                            or inNetwork(RCFG.numLaneGroupsLog2)(i).writeEnable
                          );
    
    inst_tlb_bypass(i) <= not rv2mmu_laneEnable(i) or not fetch_stall(i);
  end generate;
  
  -- connect the inputs of the output routing network
  out_network_input_gen: for i in 0 to 2**RCFG.numLaneGroupsLog2-1 generate
    
    outNetwork(0)(i).stall_rv_inst      <= inst_stall_r(i) 
                                        or tlb2tw_inst_miss(i)
                                        or flush_stall
                                        or tlb2tw_dirty(i);
    
    outNetwork(0)(i).stall_rv_data      <= data_stall_r(i)
                                        or outNetwork(0)(i).data_miss
                                        or flush_stall;
    
    outNetwork(0)(i).stall_cache_inst   <= inst_stall_r(i)
                                        or tlb2tw_inst_miss(i)
                                        or flush_stall
                                        or tlb2tw_dirty(i)
                                        or mmu2cache_stall_r2(i);
    
    outNetwork(0)(i).stall_cache_data   <= data_stall_r(i)
                                        or outNetwork(0)(i).data_miss
                                        or flush_stall
                                        or mmu2cache_stall_r2(i);                
    
    outNetwork(0)(i).trap               <= mmu2rv_dataPageFault(i)
                                        or mmu2rv_fetchPageFault(i)
                                        or (
                                          mmu2rv_writeToCleanPage(i)
                                          and rv2mmu_laneWriteToCleanTrapEn(i)
                                        )
                                        or mmu2rv_writeAccessViolation(i)
                                        or mmu2rv_kernelSpaceViolation(2*i)
                                        or mmu2rv_kernelSpaceViolation(2*i+1);
  
  end generate;
  
  -----------------------------------------------------------------------------
  -- Generate the output routing network
  -----------------------------------------------------------------------------
  out_network_logic_gen : if RCFG.numLaneGroupsLog2 > 0 generate

    -- The code below generates the same structure as the input routing network
    -- code, so you can refer to the ASCII picture there.
    out_network_logic_gen_b : for lvl in 0 to RCFG.numLaneGroupsLog2 - 1 generate
      out_network_logic : process (outNetwork(lvl), inNetwork(lvl)) is
          variable inLo, inHi       : outNetworkEdge_type;
          variable outLo, outHi     : outNetworkEdge_type;
          variable ind              : unsigned(RCFG.numLaneGroupsLog2-2 downto 0);
          variable indLo, indHi     : unsigned(RCFG.numLaneGroupsLog2-1 downto 0);
      begin
          for i in 0 to (2**RCFG.numLaneGroupsLog2 / 2) - 1 loop

            -- Decode i into an unsigned so we can play around with the bits.
            ind := to_unsigned(i, RCFG.numLaneGroupsLog2-1);

            -- Determine the lo and hi indices.
            for j in 0 to RCFG.numLaneGroupsLog2 - 1 loop
              if j < lvl then
                indLo(j) := ind(j);
                indHi(j) := ind(j);
              elsif j = lvl then
                indLo(j) := '0';
                indHi(j) := '1';
              else
                indLo(j) := ind(j-1);
                indHi(j) := ind(j-1);
              end if;
            end loop;

            -- Read the input signals into variables for shorthand notation.
            inLo := outNetwork(lvl)(to_integer(indLo));
            inHi := outNetwork(lvl)(to_integer(indHi));

            -- Passthrough by default.
            outLo := inLo;
            outHi := inHi;
    
            -- If the input network lo decouple input is low, perform magic
            -- to make cache blocks work together. Note the lack of a register
            -- here even though we're crossing a pipeline stage. This should not
            -- be necessary due to the preconditions placed on the decouple
            -- inputs: in all cases when a decouple signal switches, behavior
            -- is unaffected due to all readEnables and stalls being low.
            if inNetwork(lvl)(to_integer(indLo)).decouple = '0' then
    
              outLo.stall_rv_inst      := inLo.stall_rv_inst or inHi.stall_rv_inst;
              outHi.stall_rv_inst      := inLo.stall_rv_inst or inHi.stall_rv_inst;
              outLo.stall_cache_inst   := inLo.stall_cache_inst or inHi.stall_cache_inst;
              outHi.stall_cache_inst   := inLo.stall_cache_inst or inHi.stall_cache_inst;
              

              outLo.stall_cache_data   := inLo.stall_cache_data or inHi.stall_cache_data;
              outHi.stall_cache_data   := inLo.stall_cache_data or inHi.stall_cache_data;
              
              outLo.trap               := inLo.trap or inHi.trap;
              outHi.trap               := inLo.trap or inHi.trap;
              
              -- data tlb updates are only required if all TLBs miss
              if ((inLo.data_miss and inHi.data_miss) = '0') then
                outLo.data_miss := '0';
                outHi.data_miss := '0';
              else 
                outLo.data_miss := not tlb_update_state(lvl);
                outHi.data_miss := tlb_update_state(lvl);
              end if;
              
              -- distribute the tlb updated signal. If one coupled data tlb is
              -- updated, the system can continue
              if (inLo.data_tlb_done or inHi.data_tlb_done) = '1' then
                outLo.data_tlb_done := '1';
                outHi.data_tlb_done := '1';
              end if;
              
              -- trap codes. No precedence, just do one first then the other
              if not (inHi.trapCode = RVEX_TRAP_NONE) then
                outLo.trapCode  := inHi.trapCode;
                outHi.trapCode  := inHi.trapCode;            
              else 
                outLo.trapCode  := inLo.trapCode;
                outHi.trapCode  := inLo.trapCode;                                                    
              end if;
              
              if (inHi.stall_rv_data = '0') then                        
                outLo.stall_rv_data     := inHi.stall_rv_data;
                outHi.stall_rv_data     := inHi.stall_rv_data;
                outLo.stall_cache_data  := inHi.stall_cache_data;
                outHi.stall_cache_data  := inHi.stall_cache_data;
                outLo.data_Ptag         := inHi.data_Ptag;
                outHi.data_Ptag         := inHi.data_Ptag;
                outLo.cache_bypass      := inHi.cache_bypass;
                outHi.cache_bypass      := inHi.cache_bypass;                           
              else
                outLo.stall_rv_data     := inLo.stall_rv_data;
                outHi.stall_rv_data     := inLo.stall_rv_data;
                outLo.stall_cache_data  := inLo.stall_cache_data;
                outHi.stall_cache_data  := inLo.stall_cache_data; 
                outLo.data_Ptag         := inLo.data_Ptag;
                outHi.data_Ptag         := inLo.data_Ptag;          
                outLo.cache_bypass      := inLo.cache_bypass;
                outHi.cache_bypass      := inLo.cache_bypass;                                         
              end if;                           
            end if;

            -- Assign the output signals.
            outNetwork(lvl+1)(to_integer(indLo)) <= outLo;
            outNetwork(lvl+1)(to_integer(indHi)) <= outHi;

        end loop; -- i
      end process;
    end generate; -- lvl
  end generate;
  
  
  -----------------------------------------------------------------------------
  -- Connect the outputs from the output network to the lane groups
  -----------------------------------------------------------------------------
  a: process (
    data_stall_r, inst_stall_r, tlb2tw_dirty, mmu2cache_stall_r2,
    mmu2rv_dataPageFault, mmu2rv_fetchPageFault,  mmu2rv_writeToCleanPage,
    rv2mmu_laneWriteToCleanTrapEn, tw2tlb_dirtyAck, flush_busy,
    mmu2rv_writeAccessViolation, mmu2rv_kernelSpaceViolation, outNetwork,
    cache2rv_stall
  ) is
  begin
    out_network_output_gen : for i in 0 to 2**RCFG.numLaneGroupsLog2-1 loop
  
      mem2rv_stall(i)                     <= (outNetwork(RCFG.numLaneGroupsLog2)(i).stall_rv_data 
                                          or outNetwork(RCFG.numLaneGroupsLog2)(i).stall_rv_inst 
                                          or cache2rv_stall(i)) 
                                          and not outNetwork(RCFG.numLaneGroupsLog2)(i).trap;
                                          
      mem2rv_stall_inc(i)                 <= outNetwork(RCFG.numLaneGroupsLog2)(i).stall_rv_data 
                                          or outNetwork(RCFG.numLaneGroupsLog2)(i).stall_rv_inst;
                                          
      mmu2icache_stall(i)                 <= outNetwork(RCFG.numLaneGroupsLog2)(i).stall_cache_inst;
      mmu2dcache_stall(i)                 <= outNetwork(RCFG.numLaneGroupsLog2)(i).stall_cache_data;
      mmu2rv_trap(i)                      <= outNetwork(0)(i).trap;

      -- check the trap signals coming from the tlb's
      if mmu2rv_dataPageFault(i) = '1' then
          mmu2rv_trapStatus(i)(7 downto 0) <= std_logic_vector(to_unsigned(RVEX_TRAP_DMEM_PAGE_FAULT, 8));
      elsif mmu2rv_fetchPageFault(i) = '1' then
          mmu2rv_trapStatus(i)(7 downto 0) <= std_logic_vector(to_unsigned(RVEX_TRAP_IMEM_PAGE_FAULT, 8));
      elsif (mmu2rv_kernelSpaceViolation(2*i) or mmu2rv_kernelSpaceViolation(2*i+1)) = '1' then
          mmu2rv_trapStatus(i)(7 downto 0) <= std_logic_vector(to_unsigned(RVEX_TRAP_KERNEL_SPACE_VIO, 8));
      elsif mmu2rv_writeAccessViolation(i) = '1' then
          mmu2rv_trapStatus(i)(7 downto 0) <= std_logic_vector(to_unsigned(RVEX_TRAP_WRITE_ACCESS_VIO, 8));
      elsif (mmu2rv_writeToCleanPage(i) and rv2mmu_laneWriteToCleanTrapEn(i)) = '1' then
          mmu2rv_trapStatus(i)(7 downto 0) <= std_logic_vector(to_unsigned(RVEX_TRAP_WRITE_TO_CLEAN_PAGE, 8));
      else
          mmu2rv_trapStatus(i)(7 downto 0) <= std_logic_vector(to_unsigned(RVEX_TRAP_NONE, 8));
      end if; 
      mmu2rv_trapStatus(i)(rvex_data_type'length-1 downto 8)  <= (others => '0');
      
      -- connect the Ptags 
      mmu2cache_dataPtags ((i+1)*mmutagSize(CCFG)-1 downto i*mmutagSize(CCFG))
        <= outNetwork(RCFG.numLaneGroupsLog2)(i).data_Ptag;
      
      -- connect cache bypass signal
      mmu2dcache_bypass(i)                <= outNetwork(RCFG.numLaneGroupsLog2)(i).cache_bypass;
      
    end loop;
  end process;
  
    
  -- Generate the intruction tlb's (one per langroup).
  g_instruction_tlbs : for i in 0 to 2**RCFG.numLaneGroupsLog2-1 generate
    itlb_n : entity work.cache_mmu_tlb
    generic map(
      CCFG                   => CCFG
    )
    port map(
      clk                       => clk, 
      reset                     => reset,
      bypass                    => inst_tlb_bypass(i),
      VTag                      => inst_Vtag_stall(i),
      rw                        => '0', 
      read_Ptag                 => inst_read_Ptag(i),
      read_asid                 => rv2mmu_laneAddressSpaceID(i),
      read_miss                 => tlb2tw_inst_miss(i),
      kernel_space_violation    => mmu2rv_kernelSpaceViolation(2*i),
      write_enable              => tw2tlb_inst_ready(i),
      write_pte                 => tw2tlb_pte,
      write_done                => inst_tlb_done(i),
      flush                     => tlb_flush,
      flushMode                 => tlb_flushMode, 
      flushAsid                 => tlb_flushAsid, 
      flushLowRange             => tlb_flushLowRange, 
      flushHighRange            => tlb_flushHighRange,
      flush_busy                => flush_busy(2*i),
      cache_bypass              => open
    );
  end generate ; 
  
  -- generate the data tlb's (one per langroup).
  g_data_tlbs : for i in 0 to 2**RCFG.numLaneGroupsLog2-1 generate
    dtlb_n : entity work.cache_mmu_tlb
    generic map(
      CCFG                   => CCFG
    )
    port map(
      clk                       => clk,
      reset                     => reset,
      -- bypass                   => inNetwork(RCFG.numLaneGroupsLog2)(i).bypass,
      bypass                    => data_tlb_bypass(i),
      VTag                      => inNetwork(RCFG.numLaneGroupsLog2)(i).data_Vtag,
      rw                        => inNetwork(RCFG.numLaneGroupsLog2)(i).writeEnable,
      read_Ptag                 => outNetwork(0)(i).data_Ptag,
      read_asid                 => rv2mmu_laneAddressSpaceID(i),            
      read_miss                 => outNetwork(0)(i).data_miss,
      dirty                     => tlb2tw_dirty(i),
      dirty_ack                 => tw2tlb_dirtyAck(i),
      kernel_space_violation    => mmu2rv_kernelSpaceViolation(2*i+1),
      write_access_violation    => mmu2rv_writeAccessViolation(i),
      write_enable              => tw2tlb_data_ready(i),
      write_pte                 => tw2tlb_pte,
      write_done                => outNetwork(0)(i).data_tlb_done,
      flush                     => tlb_flush,
      flushMode                 => tlb_flushMode, 
      flushAsid                 => tlb_flushAsid, 
      flushLowRange             => tlb_flushLowRange, 
      flushHighRange            => tlb_flushHighRange,
      flush_busy                => flush_busy(2*i+1),
      cache_bypass              => outNetwork(0)(i).cache_bypass
    );
  end generate;
  
  
  -- generate the table walk hardware. There is only one instance since it needs memory access and
  -- multiple table walks are not possible at the same time. 
  tw : entity work.cache_mmu_table_walk
  generic map(
    RCFG                        => RCFG,
    CCFG                     => CCFG
  )
  port map(
    clk                         => clk,
    reset                       => reset,
    mmu2rv_fetchPageFault       => mmu2rv_fetchPageFault,
    mmu2rv_dataPageFault        => mmu2rv_dataPageFault,
    mmu2rv_writeToClean         => mmu2rv_writeToCleanPage,
    rv2mmu_configWord           => rv2mmu_configWord,
    rv2mmu_tlbDirection         => rv2mmu_tlbDirection,
    rv2mmu_lanePageTablePointers=> rv2mmu_lanePageTablePointers,
    rv2mmu_PCsVtags             => rv2tw_PCsVtags,
    rv2mmu_dataVtags            => rv2tw_dataVtags,    
    rv2mmu_readEnable           => readEnable_stall,
    rv2mmu_writeEnable          => writeEnable_stall,
    tlb2tw_inst_miss            => tw_inst_miss,
    tlb2tw_data_miss            => tw_data_miss,
    tw2tlb_inst_ready           => tw2tlb_inst_ready,
    tw2tlb_data_ready           => tw2tlb_data_ready,
    tw2tlb_pte                  => tw2tlb_pte,
    tlb2tw_dirty                => tlb2tw_dirty,
    tw2tlb_dirtyAck             => tw2tlb_dirtyAck,
    tw2mem                      => mmu2mem,
    mem2tw                      => mem2mmu
  );
  
  tw_inst_miss <= tlb2tw_inst_miss and rv2mmu_laneEnable;
  tw_data_miss <= tlb2tw_data_miss and rv2mmu_laneEnable;
  
  
  tlb_direction: process(outNetwork, rv2mmu_configWord, rv2mmu_tlbDirection) is
    variable v_request_context   : integer range 0 to 2**RCFG.numContextsLog2-1;
    variable v_request_direction : integer range 0 to 2**rvex_byte_type'length-1;
  begin

    tlb2tw_data_miss <= (2**RCFG.numLaneGroupsLog2 - 1 downto 0 => '0');
    
    for i in 0 to 2**RCFG.numLaneGroupsLog2 - 1 loop
      if outNetwork(RCFG.numLaneGroupsLog2)(i).data_miss = '1' then
        v_request_context   := to_integer(unsigned(rv2mmu_configWord((i + 1) * 4 - 1 downto i * 4)));
        v_request_direction := to_integer(unsigned(rv2mmu_tlbDirection(v_request_context)));
        if v_request_direction < 2**RCFG.numLanesLog2 then
          if to_integer(unsigned(rv2mmu_configWord((v_request_direction + 1) * 4 - 1 downto v_request_direction * 4))) = v_request_context then
            tlb2tw_data_miss(v_request_direction) <= '1';
          else
            tlb2tw_data_miss(i) <= '1';
          end if;
        else
          tlb2tw_data_miss(i) <= '1';
        end if;    
      end if;
    end loop;
  end process;

end architecture; 

