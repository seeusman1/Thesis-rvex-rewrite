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
use IEEE.MATH_REAL.all;
library rvex;
use rvex.common_pkg.all;
use rvex.core_pkg.all;
use rvex.cache_pkg.all;
use rvex.bus_pkg.all;


entity old_mmu_table_walk is
  generic (
    RCFG                        : rvex_generic_config_type := rvex_cfg;
    CCFG                        : cache_generic_config_type := cache_cfg
  );
  port (

    clk                         : in  std_logic;
    reset                       : in  std_logic;
    
    -- trap signals
    mmu2rv_fetchPageFault       : out std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    mmu2rv_dataPageFault        : out std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);

    -- control register inputs
    rv2mmu_configWord           : in  rvex_data_type;
    rv2mmu_tlbDirection         : in  rvex_byte_array(2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    -- one page table pointer for every lane
    rv2mmu_lanePageTablePointers: in  rvex_address_array(2**RCFG.numLaneGroupsLog2-1 downto 0);

    -- connection to the lanes
    rv2mmu_PCsVtags             : in  std_logic_vector(2**RCFG.numLaneGroupsLog2 * mmutagSize(CCFG)-1 downto 0);
    rv2mmu_dataVtags            : in  std_logic_vector(2**RCFG.numLaneGroupsLog2 * mmutagSize(CCFG)-1 downto 0);
    rv2mmu_readEnable           : in  std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    rv2mmu_writeEnable          : in  std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
        
    -- connection to the tlb's for tlb misses
    tlb2tw_inst_miss            : in  std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    tlb2tw_data_miss            : in  std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    tw2tlb_inst_ready           : out std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    tw2tlb_data_ready           : out std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    tw2tlb_pte                  : out rvex_data_type;
    
    -- interface to the tlb's for when a page is turned dirty
    tlb2tw_dirty                : in  std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0) := (others => '0');
    tw2tlb_dirtyAck             : out std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    mmu2rv_writeToClean         : out std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);

    -- Slave bus
    tw2mem                      : out bus_mst2slv_type;
    mem2tw                      : in  bus_slv2mst_type
    
  );
end entity old_mmu_table_walk;


architecture behavioural of old_mmu_table_walk is

  type t_state is (idle, address_calc, mem_read_req, mem_read_ack, mem_write);
  type tag_array is array (0 to 2**RCFG.numLaneGroupsLog2-1) of std_logic_vector(mmutagSize(CCFG)-1 downto 0);
  type table_walk_reg is record
    state                       : t_state;
    lane_serviced               : integer range 0 to 2**RCFG.numLaneGroupsLog2-1; -- latch which lane's tlb's miss is serviced
    data_or_PC                  : std_logic; -- latch whether a data or PC tlb miss is serviced. data = '1', PC = '0'
    lookup_address              : std_logic_vector(31 downto 0); -- the address where the next page table access will be done
    lookup_data                 : std_logic_vector(31 downto 0); -- the result of the last page table access
    page_table_level            : integer range 0 to 1; -- the page table level the lookup is at
    pte                         : rvex_data_type;
    dirty                       : std_logic; -- this bit is used to distinguish between miss and mark as dirty requests from the tlb
    request_lane                : integer range 0 to 2**RCFG.numLaneGroupsLog2-1; -- the lane that issued the data read or write
    inst_miss                   : std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
  end record;

  constant R_INIT               : table_walk_reg := (
    state                       => idle,
    lane_serviced               => 0,
    data_or_PC                  => '0',
    lookup_address              => (others => '0'),
    lookup_data                 => (others => '0'),
    page_table_level            => 0,
    pte                         => (others => '0'),
    dirty                       => '0',
    request_lane                => 0,
    inst_miss                   => (others => '0')
  );
  
  signal r, r_in         : table_walk_reg := R_INIT;
  signal Vtag            : std_logic_vector(mmutagSize(CCFG)-1 downto 0);
  signal inst_Vtags      : tag_array;
  signal data_Vtags      : tag_array;
  
begin

  -- set constant bus signals to 0
  tw2mem.writeMask         <= (others => '1');
  tw2mem.flags.burstEnable <= '0';
  tw2mem.flags.burstStart  <= '0';
  tw2mem.flags.lock        <= '0';

      
  split_tag_vector: for i in 0 to 2**RCFG.numLaneGroupsLog2-1 generate
    inst_Vtags(i) <= rv2mmu_PCsVtags((i + 1)  * mmutagSize(CCFG) - 1 downto i * mmutagSize(CCFG));
    data_Vtags(i) <= rv2mmu_dataVtags((i + 1) * mmutagSize(CCFG) - 1 downto i * mmutagSize(CCFG));
  end generate;
  
  -- mux the right tlb's Vtag based on which tlb's request is currently handled
  with r.data_or_PC select Vtag <=
    inst_Vtags(r.lane_serviced) when '0',
    data_Vtags(r.request_lane)  when others;
  
  p_combinatorial : process (
    r, rv2mmu_lanePageTablePointers, Vtag, tlb2tw_data_miss, tlb2tw_inst_miss,
    mem2tw, tlb2tw_dirty, rv2mmu_readEnable, rv2mmu_writeEnable, inst_Vtags
  ) is
    variable page_table_index  : rvex_address_type;
  begin
    r_in                <= r;
    -- default output values
    tw2mem.readEnable       <= '0';
    tw2mem.writeEnable      <= '0';
    mmu2rv_writeToClean     <= (others => '0');
    tw2mem.writeData        <= (others => '0');
    tw2mem.address          <= (others => '0');
    tw2tlb_inst_ready       <= (others => '0');
    tw2tlb_data_ready       <= (others => '0');
    tw2tlb_pte              <= (others => '0');
    mmu2rv_fetchPageFault   <= (others => '0');
    mmu2rv_dataPageFault    <= (others => '0');
    tw2tlb_dirtyAck         <= (others => '0');
            
    case(r.state) is
    
      when idle =>
        r_in.page_table_level   <= 0;
        
        -- check for data misses
        if not (tlb2tw_data_miss = (2**RCFG.numLaneGroupsLog2-1 downto 0 => '0')) then
          for i in 0 to 2**RCFG.numLaneGroupsLog2-1 loop
            -- Let the table walk service only the data tlb in the lane the 
            -- request was issued. this ensures the TA and TC are correct in
            -- case of a pagefault. Later this sould be changed to only hold for
            -- the lane the pagefault was issued. misses should be handled round
            -- robin to balance the load on the tlbs.
            if tlb2tw_data_miss(i) = '1' then
              r_in.lane_serviced      <= i;
              r_in.data_or_PC         <= '1';
              r_in.dirty              <= '0';
              r_in.state              <= address_calc;
              exit;
            end if;
          end loop;
        
        -- check for instruction misses
        elsif not (tlb2tw_inst_miss = (2**RCFG.numLaneGroupsLog2-1 downto 0 => '0')) then
          for i in 0 to 2**RCFG.numLaneGroupsLog2-1 loop
            if tlb2tw_inst_miss(i) = '1' then
              r_in.lane_serviced      <= i;
              r_in.data_or_PC         <= '0';
              r_in.dirty              <= '0';
              r_in.state              <= address_calc;
              exit;
            end if;
          end loop;

        -- check for pages turned dirty (only for data tlb's)
        else
          for i in 0 to 2**RCFG.numLaneGroupsLog2-1 loop
            if tlb2tw_dirty(i) = '1' then
              r_in.lane_serviced      <= i;
              r_in.dirty              <= '1';
              r_in.data_or_PC         <= '1'; -- only data is writable, so an instruction access never turns a page dirty
              r_in.state              <= address_calc;
              exit;
            end if;
          end loop;
        end if;
        
        -- latch some stuff for later use
        for i in 0 to 2**RCFG.numLaneGroupsLog2-1 loop
          if (rv2mmu_readEnable(i) or rv2mmu_writeEnable(i)) = '1' then
            r_in.request_lane <= i;
            exit;
          end if;
        end loop;
        
        r_in.inst_miss <= tlb2tw_inst_miss;
  
      -- lookup address calculation
      when address_calc =>
    
        case r.page_table_level is
                          
          -- add the L1 part of the Vtag to the page table pointer
          when 0 =>
        
            -- zero extend the top half of the Vtag to 32 bits (including the middle bit for uneven tag lengths)
            page_table_index := ((31 - (tagL1Msb(CCFG) - tagL1Lsb(CCFG)) - 3) downto 0 => '0')
                                & VTag(tagL1Msb(CCFG) downto tagL1Lsb(CCFG))
                                & "00";
            r_in.lookup_address <= std_logic_vector(unsigned(rv2mmu_lanePageTablePointers(r.lane_serviced)) +
                                                    unsigned(page_table_index));
                                                    
                  
          -- add the L2 part of the Vtag to the result of the first lookup
          when 1 =>
            -- zero extend the bottom half of the Vtag to 32 bits

            page_table_index := ((31 - (tagL2Msb(CCFG) - tagL2Lsb(CCFG)) - 3) downto 0 => '0')
                                & VTag(tagL2Msb(CCFG) downto tagL2Lsb(CCFG))
                                & "00";
            r_in.lookup_address <= std_logic_vector(unsigned(r.lookup_data) +
                                                      unsigned(page_table_index));
        end case;
        
        r_in.state <= mem_read_req;
    
      -- memory read state
      when mem_read_req =>
        tw2mem.address     <= r.lookup_address;
        tw2mem.readEnable  <= '1';
        r_in.state         <= mem_read_ack;
        
      when mem_read_ack =>
        if mem2tw.ack = '1' then

          -- the page is not in memory. The page table/directory has a unset valid bit. generate a page fault.
          if mem2tw.readData(PTE_PRESENT_BIT) = '0' then
            if r.data_or_PC = '0' then
              mmu2rv_fetchPageFault(r.lane_serviced) <= '1';
            else
              -- the data page fault trap must be generated on the lane that issued the read or write.
              -- this is often not the lane in which the miss is serviced due to tlb direction or distributions.
              mmu2rv_dataPageFault(r.request_lane) <= '1';
            end if;
            r_in.state <= idle;
                
          -- the L1 lookup is complete. If it found a large page send it to the tlb, else do the L2 lookup
          elsif r.page_table_level = 0 and mem2tw.readData(PTE_LARGE_PAGE_BIT) = '0' then
            r_in.lookup_data                <= mem2tw.readData(rvex_data_type'length-1 downto 8) & (7 downto 0 => '0'); -- TODO: make this parametric
            r_in.page_table_level           <= 1;
            r_in.state                      <= address_calc;

          -- this was the last lookup of a mark as dirty request
          elsif r.dirty = '1' and (r.page_table_level = 1 or mem2tw.readData(PTE_LARGE_PAGE_BIT) = '1') then
            r_in.pte <= mem2tw.readData;
            r_in.pte(PTE_DIRTY_BIT) <= '1';
            r_in.state <= mem_write;
            
            -- this was the last lookup (of a valid pte) miss request
          else
            -- return the pte and give the ack to the right tlb
            tw2tlb_pte <= mem2tw.readData;
            if r.data_or_PC = '0' then
                
              -- often multiple coupled instruction tlbs miss at the same time.
              -- check each miss signal and Vtag and service all similar misses at the same time
              for i in 0 to 2**RCFG.numLaneGroupsLog2-1 loop
                if r.inst_miss(i) = '1' and inst_Vtags(i) = Vtag then
                  tw2tlb_inst_ready(i) <= '1';
                end if;
              end loop;
              
            else
              tw2tlb_data_ready(r.lane_serviced) <= '1';
            end if;
            -- check if the accesses bit is zero. if this is the case update the pte.
            if  mem2tw.readData(PTE_ACCESSED_BIT) = '1' then
              r_in.state <= idle;
            else
              r_in.pte <= mem2tw.readData;
              r_in.pte(PTE_ACCESSED_BIT) <= '1';
              r_in.state <= mem_write;
            end if;
          end if;
            
        else -- keep the request valid while the ack is not given yet
          tw2mem.address     <= r.lookup_address;
          tw2mem.readEnable  <= '1';
        end if;
        
      -- write back the pte with updated bit flags (accessed & dirty)
      when mem_write =>
        tw2mem.writeData    <= r.pte;
        tw2mem.address      <= r.lookup_address;
        tw2mem.writeEnable  <= '1';
        if mem2tw.ack = '1' then
          tw2mem.writeEnable  <= '0';
          r_in.state <= idle;
          if r.dirty = '1' then
            tw2tlb_dirtyAck(r.lane_serviced) <= '1';
            mmu2rv_writeToClean(r.lane_serviced) <= '1';
          end if;
        end if;
            
    end case;
    
  end process;

  
  p_register : process(clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        r <= R_INIT;
      else
        r <= r_in;
      end if;
    end if;
  end process;
  

end architecture; -- arch



