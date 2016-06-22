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
use IEEE.MATH_REAL.ALL;

library rvex;
use rvex.cache_pkg.all;
use rvex.common_pkg.all;


entity old_mmu_tlb is

  generic (
    
    CCFG                        : cache_generic_config_type
    
  );
  port (

    -- clock input
    clk                         : in  std_logic;
    reset                       : in  std_logic;
    
    -- If this signal is high, the address translation is not done and the Ptag
    -- returned is the same as the Vtag. The tag is still delayed by one cycle
    -- however.
    bypass                      : in  std_logic;
    
    -- The Vtag is the same for reading and writing. This is because when a read
    -- on a certain Vtag misses the same Vtag is then used to write a new
    -- translation into the TLB.
    Vtag                        : in  std_logic_vector(MMUtagSize(CCFG)-1 downto 0);
    
    -- Bit indicating if the request is for a read (0) or a write (1). This is
    -- used to check access rights.
    rw                          : in std_logic := '0';
    
    -- Bit indication wether the access is done in kernel mode (1) or user mode
    -- (0). Also used for access rights.
    kernel_mode                 : in std_logic := '0';
    
    -- The ASID is used to check if a translation in the TLB is relevant for the
    -- currently running process.
    read_asid                   : in  std_logic_vector(mmuAsidSize(CCFG) -1 downto 0);

    -- result output for associatively reading the TLB
    read_Ptag                   : out std_logic_vector(MMUtagSize(CCFG)-1 downto 0);
    read_miss                   : out std_logic;
    
    -- TLB to TW mark dirty request.
    dirty                       : out std_logic;
    dirty_ack                   : in  std_logic := '0';
    
    -- Exceptions.
    kernel_space_violation      : out std_logic;
    write_access_violation      : out std_logic;

    -- Signals for putting entries in the TLB.
    write_enable                : in  std_logic;
    write_pte                   : in  rvex_data_type;
    write_done                  : out std_logic;
    
    -- TLB flush signals.
    flush                       : in  std_logic;
    flushMode                   : in rvex_flushMode_type;
    flushAsid                   : in rvex_data_type;
    flushLowRange               : in rvex_data_type;
    flushHighRange              : in rvex_data_type;
    flush_busy                  : out std_logic;
    
    -- Signals to the cache.
    cache_bypass                : out std_logic
    
  );
end old_mmu_tlb;


architecture behavioural of old_mmu_tlb is

  -- Shorthand notations for stuff from the MMU configuration
  constant TLB_NUM_ENTRIES      : natural := 2**CCFG.TLBDepthLog2;
  constant PAGE_NUM_WIDTH       : natural := MMUtagSize(CCFG);
  constant ASID_WIDTH           : natural := mmuAsidSize(CCFG);
  constant CAM_WIDTH            : natural := PAGE_NUM_WIDTH + ASID_WIDTH;
  
  -- These constants refer to the indices of items in the RAM
  constant VTAG_LSB             : natural := 0;
  constant PTAG_LSB             : natural := PAGE_NUM_WIDTH;
  constant ASID_LSB             : natural := PTAG_LSB + PAGE_NUM_WIDTH;
  constant FLAGS_LSB            : natural := ASID_LSB + ASID_WIDTH;
  constant RAM_WITDH            : natural := FLAGS_LSB + 4;
  constant FLAGS_RW             : natural := FLAGS_LSB + 0;
  constant FLAGS_PROT_LEVEL     : natural := FLAGS_LSB + 1;
  constant FLAGS_CACHEABLE      : natural := FLAGS_LSB + 2;
  constant FLAGS_DIRTY          : natural := FLAGS_LSB + 3;
  
  
  type t_tag_RAM is array (TLB_NUM_ENTRIES-1 downto 0) of std_logic_vector(RAM_WITDH-1 downto 0);
  
  type t_state is (read, remove_from_cam_0, remove_from_cam_1, add_to_cam_0, add_to_cam_1, mark_dirty, flush_tlb);
  type t_page  is (large, normal, large_global, global);
  
  type t_TLB_reg is record
    state                       : t_state;
    valid                       : std_logic_vector(TLB_NUM_ENTRIES-1 downto 0);
    large                       : std_logic_vector(TLB_NUM_ENTRIES-1 downto 0);
    global                      : std_logic_vector(TLB_NUM_ENTRIES-1 downto 0);
    Vtag_d                      : std_logic_vector(PAGE_NUM_WIDTH-1 downto 0);
    asid_d                      : std_logic_vector(ASID_WIDTH-1 downto 0);
    rw_d                        : std_logic;
    kernel_mode_d               : std_logic;
    write_done                  : std_logic;
    bypass_d                    : std_logic;
    clean_up                    : std_logic;
    flush                       : std_logic;
    flushing                    : std_logic;
    flushAddress                : integer range 0 to TLB_NUM_ENTRIES-1;
    write_enable                : std_logic;
    write_pte                   : rvex_data_type;
  end record;

  constant R_INIT               : t_TLB_reg := (
    state                       => read,
    valid                       => (others => '0'),
    large                       => (others => '0'),
    global                      => (others => '0'),
    Vtag_d                      => (others => '0'),
    asid_d                      => (others => '0'),
    rw_d                        => '0',
    kernel_mode_d               => '0',
    write_done                  => '0',
    bypass_d                    => '1',
    clean_up                    => '0',
    flush                       => '0',
    flushing                    => '0',
    flushAddress                => 0,
    write_enable                => '0',
    write_pte                   => (others => '0')
  );

  -- register signals
  signal r, r_in                : t_TLB_reg := R_INIT;
  
  -- RAM signals
  signal RAM                    : t_tag_RAM;
  signal RAM_we                 : std_logic;
  signal RAM_addr               : integer range 0 to TLB_NUM_ENTRIES-1;
  signal RAM_data_in            : std_logic_vector(RAM_WITDH-1 downto 0);
  signal RAM_data_out           : std_logic_vector(RAM_WITDH-1 downto 0);

  -- one hot to binary signals
  signal CONV_oneHot_in         : std_logic_vector(TLB_NUM_ENTRIES-1 downto 0);
  signal CONV_bin_out           : integer range 0 to TLB_NUM_ENTRIES-1;
  signal CONV_hit               : std_logic;

  -- CAM signals
  signal CAM_modify_en                  : std_logic;
  signal CAM_modify_add_remove          : std_logic;
  signal CAM_in_data                    : std_logic_vector(CAM_WIDTH-1 downto 0);
  signal CAM_read_out_addr_normal       : std_logic_vector(TLB_NUM_ENTRIES-1 downto 0);
  signal CAM_read_out_addr_large        : std_logic_vector(TLB_NUM_ENTRIES-1 downto 0);
  signal CAM_read_out_addr_global       : std_logic_vector(TLB_NUM_ENTRIES-1 downto 0);
  signal CAM_read_out_addr_large_global : std_logic_vector(TLB_NUM_ENTRIES-1 downto 0);
  signal CAM_modify_in_addr             : std_logic_vector(TLB_NUM_ENTRIES-1 downto 0);
  
  -- flush state machine signals
  signal flush_asid_match       : std_logic;
  signal flush_tag_match        : std_logic;
  
  -- victim generation
  signal victim                 : std_logic_vector(TLB_NUM_ENTRIES-1 downto 0);
  signal victim_next            : std_logic;
  
  -- debug
  signal flush_asid             : std_logic_vector(ASID_WIDTH-1 downto 0);
  signal flush_tag              : std_logic_vector(PAGE_NUM_WIDTH-1 downto 0);
  
  -- addresses of tlb hits in different categories
  signal large_addr             : std_logic_vector(TLB_NUM_ENTRIES-1 downto 0);
  signal global_addr            : std_logic_vector(TLB_NUM_ENTRIES-1 downto 0);
  signal large_global_addr      : std_logic_vector(TLB_NUM_ENTRIES-1 downto 0);
  
  signal page_type              : t_page;
  
begin

  -- instantiate the content accessable memory (CAM)
  CAM: entity work.old_mmu_cam
  generic map(
    CCFG                        => CCFG
  )
  port map(
    clk                         => clk,
    reset                       => reset,
    in_data                     => CAM_in_data,
    read_out_addr_normal        => CAM_read_out_addr_normal,
    read_out_addr_large         => CAM_read_out_addr_large,
    read_out_addr_global        => CAM_read_out_addr_global,
    read_out_addr_large_global  => CAM_read_out_addr_large_global,
    modify_en                   => CAM_modify_en,
    modify_add_remove           => CAM_modify_add_remove,
    modify_in_addr              => CAM_modify_in_addr
  );
  
  victim_gen: entity work.old_mmu_victim_generator
  generic map(
    CCFG                        => CCFG
  )
  port map(
    clk                         => clk,
    reset                       => reset,
    valid                       => r.valid,
    victim_next                 => victim_next,
    victim                      => victim
  );

  oh2bin : entity work.old_mmu_oh2bin
  generic map(
    WIDTH_LOG2                  => CCFG.TLBDepthLog2
  )
  port map(
    oh_in                       => CONV_oneHot_in,
    bin_out                     => CONV_bin_out,
    hit                         => CONV_hit
  );
  
  
  -- signal that the write to the tlb is complete and the core can continue
  write_done <= r.write_done;
  
  -- mask the CAM different types of hits with the approprate masks.
  -- this is required because the CAM hits for large and global pages are
  -- genrated using 'dont cares' so they can be false positives. masking them
  -- checks if they actually point to large r global tlb entries.
  large_addr        <= CAM_read_out_addr_large  and r.large and r.valid;
  global_addr       <= CAM_read_out_addr_global and r.global and r.valid;
  large_global_addr <= CAM_read_out_addr_large_global and r.large and r.global and r.valid;
  
  -- this process implements the state machine which controls the TLB.
  -- reads from the TLB complete in one cycle while writes take 4 cycles.
  state_proc: process( r, Vtag, read_asid, bypass, write_enable, write_pte, CONV_bin_out, CONV_hit, CAM_read_out_addr_normal,
                        RAM_data_out, rw, dirty_ack, flush, flushMode, flushAsid, flushLowRange, flushHighRange, page_type,
                        flush_asid_match, flush_tag_match, kernel_mode, victim, large_addr, global_addr, large_global_addr)
  begin

    -- register values default values
    r_in <= r;
    
    -- the address to the RAM is converted from one-hot to binary
    RAM_addr <= CONV_bin_out;
    
    -- the RAMs are controlled with the write enable signals. Usually the tw writes to the tlb's ram.
    -- one exception to this is when the tlb updates the dirty flag itself
    -- The tag flags of the PTE retreived by the table walk are stored in the RAM
    RAM_data_in(PTAG_LSB+PAGE_NUM_WIDTH-1 downto PTAG_LSB)
                                  <= r.write_pte(31 downto mmuOffsetSize(CCFG));
    RAM_data_in(FLAGS_RW)         <= r.write_pte(PTE_RW_BIT);
    RAM_data_in(FLAGS_PROT_LEVEL) <= r.write_pte(PTE_PROT_LEVEL_BIT);
    RAM_data_in(FLAGS_CACHEABLE)  <= r.write_pte(PTE_CACHEABLE_BIT);
    RAM_data_in(FLAGS_DIRTY)      <= r.write_pte(PTE_DIRTY_BIT);
    
    -- Other stuff that is stored in the RAM comes from the pipelane
    RAM_data_in(ASID_LSB+ASID_WIDTH-1 downto ASID_LSB) <= read_asid;
    RAM_data_in(VTAG_LSB + PAGE_NUM_WIDTH - 1 downto VTAG_LSB + mmuL2TagSize(CCFG)) <= Vtag(tagL1Msb(CCFG) downto tagL1Lsb(CCFG));
    if(r.write_pte(PTE_LARGE_PAGE_BIT) = '0') then -- when a large page is stored in the tlb, only store the L1 part of the Vtag
      RAM_data_in(VTAG_LSB + mmuL2TagSize(CCFG) - 1 downto VTAG_LSB) <= Vtag(tagL2Msb(CCFG) downto tagL2Lsb(CCFG));
    else
      RAM_data_in(VTAG_LSB + mmuL2TagSize(CCFG) - 1 downto VTAG_LSB) <= (tagL2Msb(CCFG) downto tagL2Lsb(CCFG) => '0');
    end if;

    -- component signals default values
    CAM_modify_en         <= '0';
    CAM_modify_add_remove <= '0';
    CAM_modify_in_addr    <= (others => '0');
    CAM_in_data           <= read_asid & Vtag;
    --CONV_oneHot_in        <= CAM_read_out_addr_normal;
    victim_next           <= '0';
    
    page_type <= normal;
    if large_addr /= (TLB_NUM_ENTRIES-1 downto 0 => '0') then
      CONV_oneHot_in <= large_addr;
      page_type      <= large;
    elsif CAM_read_out_addr_normal /= (TLB_NUM_ENTRIES-1 downto 0 => '0') then
      CONV_oneHot_in <= CAM_read_out_addr_normal;
    elsif large_global_addr /= (TLB_NUM_ENTRIES-1 downto 0 => '0') then
      CONV_oneHot_in <= large_global_addr;
      page_type      <= large_global;
    else
      CONV_oneHot_in <= global_addr;
      page_type      <= global;
    end if;

    -- port default values
    read_miss               <= '0';
    dirty                   <= '0';
    write_access_violation  <= '0';
    kernel_space_violation  <= '0';
    cache_bypass            <= '0';
    read_Ptag               <= (MMUtagSize(CCFG)-1 downto 0 => '0');

    -- RAM default values
    RAM_we <= '0';
    
    -- this port signals the mmu this tlb is busy flushing and cannot service requests.
    flush_busy       <= r.flushing;
    flush_tag_match  <= '0';
    flush_asid_match <= '0';

    -- delay the read request one cycle for miss/hit checking.
    r_in.Vtag_d         <= Vtag;
    r_in.asid_d         <= read_asid;
    r_in.rw_d           <= rw;
    r_in.kernel_mode_d  <= kernel_mode;
    
    -- these registers are needed to break a long path
    r_in.write_enable   <= write_enable;
    r_in.write_pte      <= write_pte;
    
    -- delay the bypass signal for TLB/register output muxing
    r_in.bypass_d <= bypass;
    
    r_in.write_done <= '0';
    
    
    -- if the MMU is bypassed, let the Vtag bypass the TLB but still delay it for one cycle.
    -- if tlb TLB is doing anything besides reading, this is completed before the tlb goes into bypass mode.
    if (r.bypass_d = '1' and r.state = read) then
  
      -- pass the Ptag as Vtag delayed one cycle
      read_Ptag    <= r.Vtag_d;
      
      -- flush the tlb if a flush was requested
      if r.flush = '1' then
        -- stall the mmu
        flush_busy          <= '1';
        r_in.flushing       <= '1';
        r_in.flush          <= '0';
        r_in.flushAddress   <= 0;
        r_in.state          <= flush_tlb;
      end if;
    else
  
      -- output to cache
      cache_bypass  <= not RAM_data_out(FLAGS_CACHEABLE);
      -- the P tag is output to the cache based on the type of page. When a large page is translated only the L1
      -- part is translated and concatenated with the L2 part of the V tag
      if page_type = large or page_type = large_global then
        read_Ptag <= RAM_data_out(PTAG_LSB + PAGE_NUM_WIDTH - 1 downto PTAG_LSB + mmuL2TagSize(CCFG))
                   & r.Vtag_d(tagL2Msb(CCFG) downto tagL2Lsb(CCFG));
      else -- normal page
        read_Ptag <= RAM_data_out(PTAG_LSB + PAGE_NUM_WIDTH - 1 downto PTAG_LSB);
      end if;
      
      
      -- if the MMU is enabled, do a TLB lookup.
      case( r.state ) is

        when read =>

          -- flush the tlb if a flush was requested
          if r.flush = '1' then
            -- stall the mmu
            flush_busy          <= '1';
            r_in.flushing       <= '1';
            r_in.flush          <= '0';
            r_in.flushAddress   <= 0;
            r_in.state          <= flush_tlb;

          -- initiate a write to the TLB.
          elsif r.write_enable = '1' then

            -- convert repacement victims address to binary
            CONV_oneHot_in <= victim;
                
            -- update RAM
            RAM_we <= '1';
            
            -- set the global and large bits
            r_in.large(CONV_bin_out)  <= r.write_pte(PTE_LARGE_PAGE_BIT);
            r_in.global(CONV_bin_out) <= r.write_pte(PTE_GLOBAL_BIT);
                
            -- remove address from victims CAM entry
            CAM_modify_en         <= '1';
            CAM_modify_add_remove <= '0';
            CAM_modify_in_addr    <= victim;
            
            CAM_in_data <= RAM_data_out(ASID_LSB+ASID_WIDTH-1 downto ASID_LSB) &
                            RAM_data_out(VTAG_LSB+PAGE_NUM_WIDTH-1 downto VTAG_LSB);

            -- update state
            r_in.state <= remove_from_cam_0;

          -- Reading from TLB
          else
              
            -- if the TLB lookup misses, assert the miss signal until the table walk hardware
            -- initiates a TLB write to update the missing address translation. The miss stays
            -- high until it is served because the miss stalls the core, thereby maintaining the request.
            if CONV_hit = '0' and not r.write_done = '1' then
              read_miss <= '1';
                
            -- if the CAM returns an address where the translation should be but the Vtags or ASID
            -- don't match or it is invalidated, signal a miss and clean up the CAM
            elsif (r.Vtag_d(tagL1Msb(CCFG) downto tagL1Lsb(CCFG)) /= RAM_data_out(VTAG_LSB + mmuTagSize(CCFG) - 1 downto VTAG_LSB + mmuL2TagSize(CCFG))
                  or (r.large(CONV_bin_out) = '0'
                      and r.Vtag_d(tagL2Msb(CCFG) downto tagL2Lsb(CCFG)) /= RAM_data_out(VTAG_LSB + mmuL2TagSize(CCFG) - 1 downto VTAG_LSB))
                  or (r.global(CONV_bin_out) = '0'
                      and r.asid_d /= RAM_data_out(ASID_LSB+ASID_WIDTH-1 downto ASID_LSB))
                  or r.valid(CONV_bin_out) = '0')
                  and not r.write_done = '1' then
              read_miss <= '1';
                
              -- clean up CAM entry. Remove the address from the requested Vtags entry
              r_in.clean_up         <= '1';
              r_in.state            <= remove_from_cam_0;
              CAM_modify_en         <= '1';
              CAM_modify_add_remove <= '0';
                        
            -- check for kernel space access violation
            elsif r.kernel_mode_d = '0' and RAM_data_out(FLAGS_PROT_LEVEL) = '1' then
              kernel_space_violation <= '1';
                
            -- check for write access violation
            elsif r.rw_d = '1' and RAM_data_out(FLAGS_RW) = '0' then
              write_access_violation <= '1';
                
            --  now check for a write to clean situation
            elsif r.rw_d = '1' and RAM_data_out(FLAGS_DIRTY) = '0' then
            
              -- mark dirty in tlb's ram
              RAM_data_in <= RAM_data_out;
              RAM_data_in(FLAGS_DIRTY) <= '1';
              RAM_we <= '1';
                
              -- request the TW to mark it dirty in the PT
              dirty <= '1';
              r_in.state <= mark_dirty;
            end if;
          end if;
              
      
          when remove_from_cam_0 =>
            -- wait for the CAM read write modify to complete
            if r.clean_up = '1' then
              read_miss        <= '1';
              r_in.clean_up    <= '0';
              r_in.state       <= read;
            else
              r_in.state <= remove_from_cam_1;
            end if;
              
          when remove_from_cam_1 =>

            -- get replacements P. tag
            CONV_oneHot_in <= victim;
            
            -- add address to replacements CAM entry
            CAM_modify_en           <= '1';
            CAM_modify_add_remove   <= '1';
            CAM_modify_in_addr      <= victim;
            CAM_in_data             <= r.asid_d & RAM_data_out(VTAG_LSB+PAGE_NUM_WIDTH-1 downto VTAG_LSB);
            
            -- update state
            r_in.state <= add_to_cam_0;
            
          when add_to_cam_0 =>
        
            -- wait for the CAM read write modify to complete
            r_in.state <= add_to_cam_1;

          when add_to_cam_1 =>
          
            -- mark entry as valid
            CONV_oneHot_in   <= victim;
            r_in.valid(CONV_bin_out) <= '1';

            -- update victim generator
            victim_next <= '1';

            -- signal TLB write done
            r_in.write_done <= '1';
            
            -- update state
            r_in.state <= read;
              
          -- wait for the TW's ack to the mark dirty request
          when mark_dirty =>
            dirty <= '1';
            if dirty_ack = '1' then
              r_in.state <= read;
            end if;
              
          -- flushing the tlb requires stepping through all the entries in the ram and checking them against the flush parameters
          when flush_tlb =>
          
            RAM_addr   <= r.flushAddress;
            flush_asid <= RAM_data_out(ASID_LSB+ASID_WIDTH-1 downto ASID_LSB);
            flush_tag  <= RAM_data_out(VTAG_LSB+PAGE_NUM_WIDTH-1 downto VTAG_LSB);
              
              -- check the ASID if required
            if flushMode(2) = '0' then
              flush_asid_match <= '1';
            elsif RAM_data_out(ASID_LSB+ASID_WIDTH-1 downto ASID_LSB) = flushAsid(ASID_WIDTH-1 downto 0) then
              flush_asid_match <= '1';
            else
              flush_asid_match <= '0';
            end if;
            
            -- check if the tag matches
            if flushMode(0) = '1' then
              if RAM_data_out(VTAG_LSB+PAGE_NUM_WIDTH-1 downto VTAG_LSB) = flushLowRange(PAGE_NUM_WIDTH-1 downto 0) then
                flush_tag_match <= '1';
              else
                flush_tag_match <= '0';
              end if;
                
            -- check if the tag falls in a range
            elsif flushMode(1) = '1' then
              if to_integer(unsigned(RAM_data_out(VTAG_LSB+PAGE_NUM_WIDTH-1 downto VTAG_LSB))) >= to_integer(unsigned(flushLowRange)) and
                to_integer(unsigned(RAM_data_out(VTAG_LSB+PAGE_NUM_WIDTH-1 downto VTAG_LSB))) <= to_integer(unsigned(flushHighRange)) then
                flush_tag_match <= '1';
              else
                flush_tag_match <= '0';
              end if;
            else
                flush_tag_match <= '1';
            end if;
            
            -- invalidate the entry if it matches the flush parameters
            r_in.valid(r.flushAddress) <= not (flush_asid_match and flush_tag_match) and r.valid(r.flushAddress);
              
            -- check if the entire tlb ram is checked
            if r.flushAddress = TLB_NUM_ENTRIES-1 then
              r_in.flushing       <= '0';
              r_in.state          <= read;
            else -- read the next tlb entry from the ram
              r_in.flushAddress   <= r.flushAddress + 1;
            end if;
      end case;
    end if;
    
    -- flush the valid RAM if the flush input is high
    if flush = '1' then
    
      -- flushing everything is easy and can be done atomically
      if flushMode = FLUSH_ALL then
        r_in.valid <= (others => '0');
      else -- other flush modes require a state machine and occupy the tlb for some time, stalling the mmu
        r_in.flush <= '1'; -- latch flush request to be serviced later.
      end if;
    end if;
    
  end process; -- comb_proc


  -- register process
  reg_proc : process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        -- reset state
        r <= R_INIT;
      else
        -- update registers
        r <= r_in;
      end if;
    end if;
  end process; -- reg_proc


  -- process for the tag RAM memories. These are implememted in distributed ram since they need asynchronous reads.
  RAM_proc : process( clk, RAM, RAM_addr )
  begin

    -- asynchronous read
    RAM_data_out <= RAM(RAM_addr);

    -- synchronous write
    if rising_edge(clk) then
      if RAM_we = '1' then
        RAM(RAM_addr) <= RAM_data_in;
      end if;
    end if;
    
  end process; -- RAM_proc

end architecture; -- arch
