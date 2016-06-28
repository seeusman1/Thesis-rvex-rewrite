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

-- 7. The MMU was created by Jens Johansen.

-- Copyright (C) 2008-2016 by TU Delft.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library rvex;
use rvex.common_pkg.all;
use rvex.utils_pkg.all;
use rvex.core_pkg.all;
use rvex.cache_pkg.all;
use rvex.bus_pkg.all;

--=============================================================================
-- This entity serves as the table walker for the r-VEX memory management unit.
-- The table format is roughly equivalent to x86-32. Major
-- differences/pitfalls:
--
--  - The r-VEX has an additional flag for executable pages, similar to the NX
--    bit in x86 with PAE or above. This bit must be explicitly enabled through
--    a control register though, so by default this bit can be used by the OS.
--
--  - The C and W flags work somewhat differently. First of all, the table
--    walker always bypasses the cache (because we only have a L1 cache), thus
--    the flags in the page directory are don't for page table base pointer
--    entries. Secondly, the memory types are somewhat different in general:
--
--      C W |
--     -----+---------------------------------------------------------------
--      0 0 | write-back (if supported): local data without auto. coherency
--      0 1 | write-through: shared data
--      1 - | uncacheable: peripherals
--
--    The big difference is that x86 is coherent in all modes!
--
--  - The r-VEX has design-time configurable page sizes. They are the same as
--    x86-32 by default only.
--
-- The page directory and table entries have the following formats:
--
-- |-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-| ----------
-- |        Large page ptag        ::::::::::::|X|G|1|D|A|C|W|U|R|1|
-- |-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|    Page
-- |        Page table base        ::::::::::::|X|-|0|-|A|-|-|U|R|1| directory
-- |-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|  entries
-- |                              -                              |0|
-- |-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-| ----------
-- |        Normal page ptag       ::::::::::::|X|G|-|D|A|C|W|U|R|1|    Page
-- |-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|   table
-- |                              -                              |0|  entries
-- |-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-| ----------
--                                              | | | | | | | | | |
-- Entry flag documentation:                    X G S D A C W U R P
--  - P: present. If 0, the rest of the entry   | | | | | | | | | '-> Present
--    is ignored by the table walker.           | | | | | | | | '-> wRitable
--  - R: writable. If 0, the page is            | | | | | | | '-> User
--    read-only; if 1, it is read-write. If     | | | | | | '-> Write-through
--    rv2mmu_writeProtect is low, this is only  | | | | | '-> Cache disable
--    enforced in user mode; if it is high,     | | | | '-> Accessed
--    kernel writes to read-only pages also     | | | '-> Dirty
--    result in a fault.                        | | '-> page Size
--  - U: user/kernel. If 0, the page can only   | '-> Global
--    be accessed in kernel mode; if 1, it      '-> eXecutable
--    must use write-through. Contrary to
--    x86-32 though, the cache is NOT necessarily coherent in write-back mode.
--    This is intended to be used for local data.
--  - C: cache disable. If 0, the cache is enabled; if 1, the cache is
--    bypassed. The latter is intended for peripherals.
--  - A: accessed. If 0, this bit is set when it was accessed by the table
--    walker, and the access did not result in a page fault.
--  - D: dirty. If 0, this bit is set when a write to the page is requested,
--    and this write did not result in a page fault.
--  - S: page size. Used to distinguish between a large page and a page table
--    in the page directory.
--  - G: global. If rv2mmu_globalPageEnable is high, this bit selects between
--    normal pages (0) and global pages (1). The difference is that the ASID
--    match in the TLB is disabled for global pages. If rv2mmu_globalPageEnable
--    is low (default), the bit is freely usable by the operating system.
--  - X: executable. If rv2mmu_executableEnable is high, this bit determines
--    whether this page is executable (1) or not (0). That is, if a non
--    executable page is accessed by the instruction port, a protection trap is
--    generated. If rv2mmu_writeProtect is low (default), the bit is freely
--    usable by the operating system.
--
-- The tag area that is actually used depends on the page sizes:
--  - Large page ptag uses 32 - 2**largePageSizeLog2 bits
--  - Page table base uses 30 - 2**(largePageSizeLog2-pageSizeLog2) bits
--  - Normal page ptag uses 32 - 2**pageSizeLog2 bits
-- They are MSB-aligned. Unused bits are freely usable by the OS. The table
-- sizes are:
--  - Page directory: 2**(32-largePageSizeLog2) 32-bit words
--  - Page table: 2**(largePageSizeLog2-pageSizeLog2) 32-bit words
-- With the default settings (page size 4 kiB and large page size 4 MiB) the
-- layout equals x86-32.
-------------------------------------------------------------------------------
entity cache_tw is
--=============================================================================
  generic (
    
    -- Configuration.
    RCFG                        : rvex_generic_config_type := rvex_cfg;
    CCFG                        : cache_generic_config_type := cache_cfg
    
  );
  port (

    ---------------------------------------------------------------------------
    -- System control
    ---------------------------------------------------------------------------
    -- Active high synchronous reset input.
    reset                       : in  std_logic;
    
    -- Clock input, registers are rising edge triggered.
    clk                         : in  std_logic;
    
    -- Active high global clock enable input.
    clkEn                       : in  std_logic;
    
    ---------------------------------------------------------------------------
    -- Control register values
    ---------------------------------------------------------------------------
    -- This signal specifies the page table pointer for each lane group.
    rv2tw_pageTablePtr          : in  rvex_address_array(2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    -- This signal represents the current privilege level of each lane group.
    -- It is high for kernel mode and low for application mode.
    rv2tw_kernelMode            : in  std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    -- This signal controls whether a trap is to be generated when a write to a
    -- clean page is attempted.
    rv2tw_writeToCleanEna       : in  std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    -- This signal controls whether kernel threads can write to read-only
    -- pages. This is the case when this signal is low.
    rv2tw_writeProtect          : in  std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    -- This signal specifies whether the global page bit in the page table is
    -- enabled or ignored.
    rv2tw_globalPageEna         : in  std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    -- This signal specifies whether the executable page bit in the page table
    -- is enabled or ignored.
    rv2tw_execPageEna           : in  std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    ---------------------------------------------------------------------------
    -- TLB interconnect
    ---------------------------------------------------------------------------
    -- For all the following signals, the lower half of the indices should be
    -- connected to the data TLBs, and the upper half should be connected to
    -- the instruction TLBs.
    
    -- This signal is raised when a table walk is requested by a TLB. This may
    -- be due to a miss or it may be to mark a page as dirty. The request
    -- signal may only be lowered on a rising clock edge while ack or nack is
    -- high.
    tlb2tw_request              : in  std_logic_vector(2*2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    -- The virtual address which requires translation. This must be kept
    -- stable by the TLB while it is asserting the request signal.
    tlb2tw_vaddr                : in  rvex_address_array(2*2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    -- Whether the data request is a read or a write. This must be kept stable
    -- by the TLB while it is asserting the request signal.
    dtlb2tw_write               : in  std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    -- Complete is asserted when the table walker finishes the request. Unless
    -- there is a second request, the TLB should release its request signal in
    -- the next cycle. While complete is high, the signals below are valid.
    -- There should be at least one cycle between complete being asserted and
    -- the stall signal to the core being released due to the trap output
    -- registers.
    tw2tlb_complete             : out std_logic_vector(2*2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    -- This signal is asserted while complete is high if a fault occured, and
    -- the TLB should thus not be updated.
    tw2tlb_fault                : out std_logic;
    
    -- Translated (physical) address for the TLB for which complete is
    -- asserted.
    tw2tlb_paddr                : out rvex_address_type;
    
    -- Page flags to be stored in the TLB for which complete is asserted.
    tw2tlb_flagGlobal           : out std_logic;
    tw2tlb_flagSize             : out std_logic;
    tw2tlb_flagDirty            : out std_logic;
    tw2tlb_flagCacheDisable     : out std_logic;
    tw2tlb_flagWriteThrough     : out std_logic;
    tw2tlb_flagUser             : out std_logic;
    tw2tlb_flagWritable         : out std_logic;
    
    ---------------------------------------------------------------------------
    -- Fault signals
    ---------------------------------------------------------------------------
    -- Combined stall signal from the r-VEX. This represents the actual stall
    -- signal. The fault signals should (still) be valid when this signal is
    -- deasserted (there may be other sources causing a stall).
    rv2tw_stallOut              : in  std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    -- Instruction page fault. Generated when an instruction fetch tries to
    -- access unmapped memory.
    tw2rv_iPageFault            : out std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    -- Instruction kernel space violation. Generated when an instruction fetch
    -- from user mode tries to access a kernel-only page.
    tw2rv_iKernelAccVio         : out std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    -- Instruction access violation. Generated when an instruction fetch tries
    -- to access a non-executable page.
    tw2rv_iExecAccVio           : out std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    -- Data page fault. Generated when a data access tries to access unmapped
    -- memory.
    tw2rv_dPageFault            : out std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    -- Data kernel space violation. Generated when a data access from user mode
    -- tries to access a kernel-only page.
    tw2rv_dKernelAccVio         : out std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    -- Data write access violation. Generated when a write to read-only memory
    -- is attempted. This is always illegal in user mode; in kernel mode it is
    -- only considered illegal if rv2tw_writeProtect is low.
    tw2rv_dWriteAccVio          : out std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    -- Data write to clean page. Generated when a write to a clean page is
    -- attempted while rv2tw_writeToCleanEna is high.
    tw2rv_dWriteToClean         : out std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
    
    ---------------------------------------------------------------------------
    -- Memory access bus
    ---------------------------------------------------------------------------
    tw2bus_bus                  : out bus_mst2slv_type;
    bus2tw_bus                  : in  bus_slv2mst_type
    
  );
end cache_tw;

--=============================================================================
architecture behavioural of cache_tw is
--=============================================================================
  
  -- Enumeration type of all possible fault states.
  type fault_type is (
    FAULT_NONE,   -- No fault.
    FAULT_IPAGE,  -- Instruction page fault.
    FAULT_IKERN,  -- Instruction kernel access violation.
    FAULT_IEXEC,  -- Instruction execute access violaton.
    FAULT_DPAGE,  -- Data page fault.
    FAULT_DKERN,  -- Data kernel access violation.
    FAULT_DWRITE, -- Data write access violation.
    FAULT_DWTC    -- Data write to clean page trap.
  );
  
  -- TLB that the table walker is currently or was last servicing. The MSB is
  -- used to differentiate between the data (0) and instruction (1) TLBs.
  signal tw_block               : std_logic_vector(RCFG.numLaneGroupsLog2 downto 0);
  signal tw_block_next          : std_logic_vector(RCFG.numLaneGroupsLog2 downto 0);
  
  -- Table walker handshake signals.
  signal tw_start               : std_logic;
  signal tw_busy                : std_logic;
  signal tw_complete            : std_logic;
  signal tw_fault               : fault_type;
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- Request arbitration logic
  -----------------------------------------------------------------------------
  request_arbiter: block is
    
    -- Instruction/data request signals from the selected block.
    signal ireq                 : std_logic;
    signal dreq                 : std_logic;
    
    -- Selection signal between the instruction and data TLBs.
    signal idsel                : std_logic;
    
  begin
    
    -- Round-robin arbiter between the blocks. This does not yet differentiate
    -- between instruction and data blocks.
    block_arbiter: if RCFG.numLaneGroupsLog2 > 0 generate
      
      -- Block selection types.
      subtype select_type is std_logic_vector(RCFG.numLaneGroupsLog2-1 downto 0);
      type select_array is array (natural range <>) of select_type;
      
      -- Number of bits needed for the input to the scheduling lookup table. One
      -- signal is needed per block, representing whether it requires a table
      -- walk or not. The remainder is needed to identify the block which was
      -- last serviced by the table walker.
      constant NUM_SCHED_INPUT_BITS : natural := 2**RCFG.numLaneGroupsLog2 + RCFG.numLaneGroupsLog2;
      
      -- Type for the scheduling lookup table. The LSBs of the index should
      -- be connected to the previous value of the output of this lookup table,
      -- the MSBs to the request signals from the blocks.
      subtype schedLookup_type is select_array(0 to 2**NUM_SCHED_INPUT_BITS-1);
      
      -- Returns the next index, starting at idx + 1, for which vect is high.
      -- Scanning for indices wraps around. When the vector is completely zero,
      -- this returns idx.
      pure function getNextSetIndex(idx: natural; vect: std_logic_vector) return natural is
        variable nidx : natural;
      begin
        for i in 0 to vect'length-1 loop
          nidx := (i + idx + 1) mod vect'length + vect'low;
          if vect(nidx) = '1' then
            return nidx;
          end if;
        end loop;
        return idx;
      end getNextSetIndex;
      
      -- Generates the control signals lookup table.
      pure function schedLookup_gen return schedLookup_type is
        variable result     : schedLookup_type;
        variable requesting : std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
        variable resIdx     : natural;
        variable mstIdx     : natural;
      begin
        
        -- Loop over all possible access control signals, represented in the
        -- requesting vector within the loop.
        for masters in 0 to 2**(2**RCFG.numLaneGroupsLog2)-1 loop
          requesting := uint2vect(masters, 2**RCFG.numLaneGroupsLog2);
          
          -- Loop over the possibilities for the previous master which had access
          -- to the slave.
          for prevMaster in 0 to 2**RCFG.numLaneGroupsLog2-1 loop
            
            -- Determine the index within the control signal lookup table
            -- associated with this loop iteration.
            resIdx := masters * 2**RCFG.numLaneGroupsLog2 + prevMaster;
            
            -- If prevMaster is out of range, simply return master 0.
            if prevMaster >= 2**RCFG.numLaneGroupsLog2 then
              result(resIdx) := (others => '0');
              next;
            end if;
            
            -- Call getNextSetIndex to determine which masters should get control
            -- over the slave next.
            mstIdx := getNextSetIndex(prevMaster, requesting);
            result(resIdx) := uint2vect(mstIdx, RCFG.numLaneGroupsLog2);
            
          end loop;
          
        end loop;
        
        -- Return the constructed table.
        return result;
        
      end schedLookup_gen;
      
      -- Control signal lookup table, generated during design elaboration using the
      -- function above.
      constant SCHED_LOOKUP     : schedLookup_type := schedLookup_gen;
      
      -- Merged instruction/data request signals.
      signal blockRequests      : std_logic_vector(2**RCFG.numLaneGroupsLog2-1 downto 0);
      
      -- The currently selected block.
      signal blockSelect        : select_type;
      
      -- The group that is to be selected next.
      signal blockSelect_next   : select_type;
      
    begin
      
      -- Merge the instruction/data request signals.
      blockRequests <= tlb2tw_request(2**RCFG.numLaneGroupsLog2-1 downto 0) or
        tlb2tw_request(2*2**RCFG.numLaneGroupsLog2-1 downto 2**RCFG.numLaneGroupsLog2);
      
      -- Use the lookup table generated above to select the next block when the
      -- table walker is not busy and there is no instruction translation
      -- pending. The latter is there to get the table walker to finish handling
      -- lane groups which it started handling.
      arb_comb: process (tw_busy, blockRequests, blockSelect) is
      begin
        if tw_busy = '0' and idsel = '0' then
          blockSelect_next <= SCHED_LOOKUP(vect2uint(blockRequests & blockSelect));
        else
          blockSelect_next <= blockSelect;
        end if;
      end process;
      
      -- Store the currently selected block.
      arb_reg: process (clk) is
      begin
        if rising_edge(clk) then
          if reset = '1' then
            blockSelect <= (others => '0');
          elsif clkEn = '1' then
            blockSelect <= blockSelect_next;
          end if;
        end if;
      end process;
      
      -- Copy the block select bits.
      tw_block(RCFG.numLaneGroupsLog2-1 downto 0) <= blockSelect;
      tw_block_next(RCFG.numLaneGroupsLog2-1 downto 0) <= blockSelect_next;
      
      -- Multiplex between the data and instruction request bits. This needs to
      -- be done using the select signal for the next cycle, as that signal is
      -- based on the current request signal state instead of that of the
      -- previous cycle.
      dreq <= tlb2tw_request(vect2uint(blockSelect_next));
      ireq <= tlb2tw_request(2**RCFG.numLaneGroupsLog2 + vect2uint(blockSelect_next));
      
    end generate;
    
    -- If there's only one block, we don't need an inter-block arbiter. We do
    -- need to connect the dreq and ireq signals though.
    no_block_arbiter: if RCFG.numLaneGroupsLog2 = 0 generate
      
      dreq <= tlb2tw_request(0);
      ireq <= tlb2tw_request(1);
      
    end generate;
    
    -- If an instruction request is pending, select the instruction request
    -- in the next cycle. Otherwise select the data request, if any. Because
    -- it is illegal to deassert a request until the request has been
    -- processed, we just need to register the instruction request signal to
    -- get the selection.
    idsel_reg: process (clk) is
    begin
      if rising_edge(clk) then
        if reset = '1' then
          idsel <= '0';
        elsif clkEn = '1' then
          idsel <= ireq;
        end if;
      end if;
    end process;
    
    -- Copy the instruction/data select bit.
    tw_block(RCFG.numLaneGroupsLog2) <= idsel;
    tw_block_next(RCFG.numLaneGroupsLog2) <= ireq;
    
    -- Start the table walker in the next cycle if there is a new request.
    tw_start <= (ireq or dreq) and not tw_busy;
    
  end block;
  
  -----------------------------------------------------------------------------
  -- Request arbitration logic
  -----------------------------------------------------------------------------
  table_walker: block is
    
    -- Table walker state machine states.
    type tw_state_type is (
      TWS_IDLE,     -- Idle state, waiting for a new table walk request. Also
                      -- (implicitly) handles arbitration and multiplexing
                      -- between the various TLBs.
      TWS_PDE_REQ,  -- First cycle of the page directory entry bus request.
      TWS_PDE_WAIT, -- Wait cycles and bus result registration for the PDE.
      TWS_PDE_PROC, -- Processing the PDE entry.
      TWS_PTE_REQ,  -- First cycle of the page table entry bus request.
      TWS_PTE_WAIT, -- Wait cycles and bus result registration for the PTE.
      TWS_PTE_PROC, -- Processing the PTE entry.
      TWS_UPT_REQ,  -- First cycle of the page table entry dirty/accessed
                      -- flag update request.
      TWS_UPT_WAIT, -- Wait cycles for the PTE update.
      TWS_UPD_REQ,  -- First cycle of the page directory entry dirty/accessed
                      -- flag update request.
      TWS_UPD_WAIT  -- Wait cycles for the PDE update.
    );
    
    -- Table walker state.
    signal tw_state               : tw_state_type;
    signal tw_state_next          : tw_state_type;
    
    -- Write enable signal for the table walker state register.
    signal tw_state_we            : std_logic;
    
    -- Control fields registered in the cycle in which tw_start is asserted.
    signal tw_pageTableBase       : rvex_address_type;
    signal tw_vAddr               : rvex_address_type;
    signal tw_writeAccess         : std_logic;
    signal tw_fetchAccess         : std_logic;
    signal tw_kernelMode          : std_logic;
    signal tw_writeToCleanEna     : std_logic;
    signal tw_writeProtect        : std_logic;
    signal tw_globalPageEna       : std_logic;
    signal tw_execPageEna         : std_logic;
    
    -- Page directory entry pointer and retrieved data.
    signal tw_pdePtr              : rvex_address_type;
    signal tw_pdeData             : rvex_data_type;
    signal tw_pdeData_we          : std_logic;
    signal tw_pdeNewFlags         : rvex_byte_type;
    
    -- Page table entry pointer and retrieved data.
    signal tw_ptePtr              : rvex_address_type;
    signal tw_pteData             : rvex_data_type;
    signal tw_pteData_we          : std_logic;
    signal tw_pteNewFlags         : rvex_byte_type;
    
    -- Internal copies of some of the flag outputs, because we read these in
    -- order to incrementally update them.
    signal tw2tlb_flagDirty_i     : std_logic;
    signal tw2tlb_flagUser_i      : std_logic;
    signal tw2tlb_flagWritable_i  : std_logic;
    
  begin
    
    -- Instantiate the table walker state registers.
    tw_state_reg: process (clk) is
    begin
      if rising_edge(clk) then
        if reset = '1' then
          tw_state                <= TWS_IDLE;
          tw_pageTableBase        <= (others => '0');
          tw_vAddr                <= (others => '0');
          tw_writeAccess          <= '0';
          tw_fetchAccess          <= '0';
          tw_kernelMode           <= '0';
          tw_writeToCleanEna      <= '0';
          tw_writeProtect         <= '0';
          tw_globalPageEna        <= '0';
          tw_execPageEna          <= '0';
          tw_pdeData              <= (others => '0');
          tw_pteData              <= (others => '0');
          tw2tlb_paddr            <= (others => '0');
          tw2tlb_flagGlobal       <= '0';
          tw2tlb_flagSize         <= '1';
          tw2tlb_flagDirty_i      <= '0';
          tw2tlb_flagCacheDisable <= '0';
          tw2tlb_flagWriteThrough <= '1';
          tw2tlb_flagUser_i       <= '1';
          tw2tlb_flagWritable_i   <= '1';
        elsif clkEn = '1' then
          
          -- State machine state.
          if tw_state_we = '1' then
            tw_state <= tw_state_next;
          end if;
          
          -- First cycle registers, along with the multiplexers between the TLB
          -- request sources.
          if tw_start = '1' then
            tw_vAddr              <= tlb2tw_vaddr(vect2uint(tw_block_next));
            tw2tlb_paddr          <= tlb2tw_vaddr(vect2uint(tw_block_next));
            tw_fetchAccess        <= tw_block_next(RCFG.numLaneGroupsLog2);
            
            if RCFG.numLaneGroupsLog2 = 0 then
              tw_pageTableBase    <= rv2tw_pageTablePtr(0);
              tw_writeAccess      <= dtlb2tw_write(0) and not tw_block_next(0);
              tw2tlb_flagDirty_i  <= dtlb2tw_write(0) and not tw_block_next(0);
              tw_kernelMode       <= rv2tw_kernelMode(0);
              tw_writeToCleanEna  <= rv2tw_writeToCleanEna(0);
              tw_writeProtect     <= rv2tw_writeProtect(0);
              tw_globalPageEna    <= rv2tw_globalPageEna(0);
              tw_execPageEna      <= rv2tw_execPageEna(0);
            else
              tw_pageTableBase    <= rv2tw_pageTablePtr(vect2uint(
                                     tw_block_next(RCFG.numLaneGroupsLog2-1 downto 0)));
              tw_writeAccess      <= dtlb2tw_write(vect2uint(
                                     tw_block_next(RCFG.numLaneGroupsLog2-1 downto 0)))
                                     and not tw_block_next(RCFG.numLaneGroupsLog2);
              tw2tlb_flagDirty_i  <= dtlb2tw_write(vect2uint(
                                     tw_block_next(RCFG.numLaneGroupsLog2-1 downto 0)))
                                     and not tw_block_next(RCFG.numLaneGroupsLog2);
              tw_kernelMode       <= rv2tw_kernelMode(vect2uint(
                                     tw_block_next(RCFG.numLaneGroupsLog2-1 downto 0)));
              tw_writeToCleanEna  <= rv2tw_writeToCleanEna(vect2uint(
                                     tw_block_next(RCFG.numLaneGroupsLog2-1 downto 0)));
              tw_writeProtect     <= rv2tw_writeProtect(vect2uint(
                                     tw_block_next(RCFG.numLaneGroupsLog2-1 downto 0)));
              tw_globalPageEna    <= rv2tw_globalPageEna(vect2uint(
                                     tw_block_next(RCFG.numLaneGroupsLog2-1 downto 0)));
              tw_execPageEna      <= rv2tw_execPageEna(vect2uint(
                                     tw_block_next(RCFG.numLaneGroupsLog2-1 downto 0)));
            end if;
            
            -- Reset the page flag registers. Note that the dirty flag is not
            -- reset; it is initialized to whether this is a write access. If
            -- it is, the page either is already marked dirty or will be marked
            -- dirty.
            tw2tlb_flagGlobal       <= '0';
            tw2tlb_flagSize         <= '1';
            tw2tlb_flagCacheDisable <= '0';
            tw2tlb_flagWriteThrough <= '1';
            tw2tlb_flagUser_i       <= '1';
            tw2tlb_flagWritable_i   <= '1';
            
          end if;
          
          -- Page directory entry register.
          if tw_pdeData_we = '1' then
            tw_pdeData <= bus2tw_bus.readData;
            
            -- Update the physical address based on the directory entry.
            tw2tlb_paddr(tagL1Msb(CCFG) downto tagL1Lsb(CCFG)) <=
              bus2tw_bus.readData(tagL1Msb(CCFG) downto tagL1Lsb(CCFG));
            
          end if;
          
          -- Page table entry register.
          if tw_pteData_we = '1' then
            tw_pteData <= bus2tw_bus.readData;
            
            -- Update the physical address based on the directory entry.
            tw2tlb_paddr(tagL1Msb(CCFG) downto tagL2Lsb(CCFG)) <=
              bus2tw_bus.readData(tagL1Msb(CCFG) downto tagL2Lsb(CCFG));
            
            -- This must be a small page.
            tw2tlb_flagSize <= '0';
            
          end if;
          
          -- Update the TLB flag outputs based on the directory entry.
          if tw_pdeData_we = '1' or tw_pteData_we = '1' then
            tw2tlb_flagGlobal       <= bus2tw_bus.readData(PFLAG_G) and tw_globalPageEna;
            tw2tlb_flagDirty_i      <= bus2tw_bus.readData(PFLAG_D) or tw2tlb_flagDirty_i;
            tw2tlb_flagCacheDisable <= bus2tw_bus.readData(PFLAG_C);
            tw2tlb_flagWriteThrough <= bus2tw_bus.readData(PFLAG_W);
            tw2tlb_flagUser_i       <= bus2tw_bus.readData(PFLAG_U) and tw2tlb_flagUser_i;
            tw2tlb_flagWritable_i   <= bus2tw_bus.readData(PFLAG_R) and tw2tlb_flagWritable_i;
          end if;
          
        end if;
      end if;
    end process;
    
    -- Connect the internal flag signals to the output ports.
    tw2tlb_flagDirty    <= tw2tlb_flagDirty_i;
    tw2tlb_flagUser     <= tw2tlb_flagUser_i;
    tw2tlb_flagWritable <= tw2tlb_flagWritable_i;
    
    -- Figure out the (physical) address of the desired page directory entry.
    tw_pdePtr(31 downto pageDirSizeLog2B(CCFG)) <=
      tw_pageTableBase(31 downto pageDirSizeLog2B(CCFG));
    tw_pdePtr(pageDirSizeLog2B(CCFG)-1 downto 2) <=
      tw_vAddr(tagL1Msb(CCFG) downto tagL1Lsb(CCFG));
    tw_pdePtr(1 downto 0) <= "00";
    
    -- Figure out the (physical) address of the desired page table entry.
    tw_ptePtr(31 downto pageTableSizeLog2B(CCFG)) <=
      tw_pdeData(31 downto pageTableSizeLog2B(CCFG));
    tw_ptePtr(pageTableSizeLog2B(CCFG)-1 downto 2) <=
      tw_vAddr(tagL2Msb(CCFG) downto tagL2Lsb(CCFG));
    tw_ptePtr(1 downto 0) <= "00";
    
    -- Figure out the updated page directory flags.
    tw_pdeNewFlags <= (
      PFLAG_S => tw_pdeData(PFLAG_S),
      PFLAG_D => tw_pdeData(PFLAG_D) or tw_writeAccess,
      PFLAG_A => '1',
      PFLAG_C => tw_pdeData(PFLAG_C),
      PFLAG_W => tw_pdeData(PFLAG_W),
      PFLAG_U => tw_pdeData(PFLAG_U),
      PFLAG_R => tw_pdeData(PFLAG_R),
      PFLAG_P => tw_pdeData(PFLAG_P)
    );

    -- Figure out the updated page table flags.
    tw_pteNewFlags <= (
      PFLAG_S => tw_pteData(PFLAG_S),
      PFLAG_D => tw_pteData(PFLAG_D) or tw_writeAccess,
      PFLAG_A => '1',
      PFLAG_C => tw_pteData(PFLAG_C),
      PFLAG_W => tw_pteData(PFLAG_W),
      PFLAG_U => tw_pteData(PFLAG_U),
      PFLAG_R => tw_pteData(PFLAG_R),
      PFLAG_P => tw_pteData(PFLAG_P)
    );

    -- Combinatorial logic for the table walker state machine.
    tw_state_comb: process (
      tw_state, tw_start, tw_writeAccess, tw_fetchAccess, tw_kernelMode,
      tw_writeToCleanEna, tw_writeProtect, tw_globalPageEna, tw_execPageEna,
      tw_pdePtr, tw_pdeData, tw_pdeNewFlags, tw_ptePtr, tw_pteData,
      tw_pteNewFlags, bus2tw_bus
    ) is
      
      -- Check for faults based upon the flags in a page directory or page
      -- table entry.
      procedure check_faults (
        constant entry          : in  rvex_data_type;
        variable fault          : out boolean
      ) is
      begin
        fault := false;
        
        if entry(PFLAG_P) = '0' then
          
          -- Page not present: page fault.
          fault := true;
          if tw_fetchAccess = '1' then
            tw_fault <= FAULT_IPAGE;
          else
            tw_fault <= FAULT_DPAGE;
          end if;
          
        elsif entry(PFLAG_U) = '0' and tw_kernelMode = '0' then
          
          -- Kernel page being accessed by user process.
          fault := true;
          if tw_fetchAccess = '1' then
            tw_fault <= FAULT_IKERN;
          else
            tw_fault <= FAULT_DKERN;
          end if;
          
        elsif entry(PFLAG_R) = '0' and tw_writeAccess = '1' and
          (tw_kernelMode = '0' or tw_writeProtect = '1') then
          
          -- Read-only page being written to.
          fault := true;
          tw_fault <= FAULT_DWRITE;
          
        elsif entry(PFLAG_D) = '0' and tw_writeAccess = '1' and
          tw_writeToCleanEna = '1' then
          
          -- Write to clean page.
          fault := true;
          tw_fault <= FAULT_DWTC;
          
        elsif entry(PFLAG_X) = '0' and tw_fetchAccess = '1' and
          tw_execPageEna = '1' then
          
          -- Executing from non-executable page.
          fault := true;
          tw_fault <= FAULT_IEXEC;
          
        end if;
      end check_faults;
      
      variable fault : boolean;
      
    begin
      
      -- Set default values for the signals.
      tw_state_next       <= TWS_IDLE;
      tw_state_we         <= '1';
      tw_busy             <= '1';
      tw_complete         <= '0';
      tw_fault            <= FAULT_NONE;
      tw2bus_bus          <= BUS_MST2SLV_IDLE;
      tw2bus_bus.address  <= tw_pdePtr;
      tw_pdeData_we       <= '0';
      tw_pteData_we       <= '0';
      
      case tw_state is
        
        -- Idle state, waiting for a new table walk request.
        when TWS_IDLE =>
          tw_busy <= '0';
          tw_state_next <= TWS_PDE_REQ;
          tw_state_we <= tw_start;
        
        -- First cycle of the page directory entry bus request.
        when TWS_PDE_REQ =>
          tw2bus_bus.address <= tw_pdePtr;
          tw2bus_bus.readEnable <= '1';
          tw_state_next <= TWS_PDE_WAIT;
        
        -- Wait cycles and bus result registration for the PDE.
        when TWS_PDE_WAIT =>
          tw2bus_bus.address <= tw_pdePtr;
          tw2bus_bus.readEnable <= bus2tw_bus.busy;
          tw_state_next <= TWS_PDE_PROC;
          tw_state_we <= not bus2tw_bus.busy;
          tw_pdeData_we <= not bus2tw_bus.busy;
        
        -- Process the PDE entry.
        when TWS_PDE_PROC =>
          
          -- Generate traps when needed.
          check_faults(tw_pdeData, fault);
          
          -- Figure out what to do next.
          if fault then
            
            -- Trap generated, report error and return to idle.
            tw_complete <= '1';
            tw_state_next <= TWS_IDLE;
            
          elsif tw_pdeData(PFLAG_S) = '0' then
            
            -- Small page. Continue the page walk to the page table.
            tw_state_next <= TWS_PTE_REQ;
            
          elsif (tw_pdeData(PFLAG_D) = '0' and tw_writeAccess = '1')
              or tw_pdeData(PFLAG_A) = '0' then
            
            -- Update the page directory entry flags.
            tw_state_next <= TWS_UPD_REQ;
            
          else
            
            -- Translation complete.
            tw_complete <= '1';
            tw_state_next <= TWS_IDLE;
            
          end if;
          
        -- First cycle of the page table entry bus request.
        when TWS_PTE_REQ =>
          tw2bus_bus.address <= tw_ptePtr;
          tw2bus_bus.readEnable <= '1';
          tw_state_next <= TWS_PTE_WAIT;
        
        -- Wait cycles and bus result registration for the PTE.
        when TWS_PTE_WAIT =>
          tw2bus_bus.address <= tw_ptePtr;
          tw2bus_bus.readEnable <= bus2tw_bus.busy;
          tw_state_next <= TWS_PTE_PROC;
          tw_state_we <= not bus2tw_bus.busy;
          tw_pteData_we <= not bus2tw_bus.busy;
        
        -- Process the PTE entry.
        when TWS_PTE_PROC =>
        
          -- Generate traps when needed.
          check_faults(tw_pteData, fault);
          
          -- Figure out what to do next.
          if fault then
            
            -- Trap generated, report error and return to idle.
            tw_complete <= '1';
            tw_state_next <= TWS_IDLE;
            
          elsif (tw_pdeData(PFLAG_D) = '0' and tw_writeAccess = '1')
             or (tw_pteData(PFLAG_D) = '0' and tw_writeAccess = '1')
             or tw_pdeData(PFLAG_A) = '0' or tw_pteData(PFLAG_A) = '0' then
            
            -- Update the page table and page directory entry flags.
            tw_state_next <= TWS_UPT_REQ;
            
          else
            
            -- Translation complete.
            tw_complete <= '1';
            tw_state_next <= TWS_IDLE;
            
          end if;
        
        -- First cycle of the page table entry dirty/accessed flag update
        -- request.
        when TWS_UPT_REQ =>
          
          tw2bus_bus.address <= tw_ptePtr;
          tw2bus_bus.writeEnable <= bus2tw_bus.busy;
          tw2bus_bus.writeMask <= "0001";
          tw2bus_bus.writeData(7 downto 0) <= tw_pteNewFlags;
          tw_state_next <= TWS_UPT_WAIT;
          
        -- Wait cycles for the PTE update.
        when TWS_UPT_WAIT =>
          
          tw2bus_bus.address <= tw_ptePtr;
          tw2bus_bus.writeEnable <= bus2tw_bus.busy;
          tw2bus_bus.writeMask <= "0001";
          tw2bus_bus.writeData(7 downto 0) <= tw_pteNewFlags;
          tw_state_next <= TWS_UPD_REQ;
          tw_state_we <= not bus2tw_bus.busy;
          
        -- First cycle of the page directory entry dirty/accessed flag update
        -- request.
        when TWS_UPD_REQ =>
        
          tw2bus_bus.address <= tw_pdePtr;
          tw2bus_bus.writeEnable <= bus2tw_bus.busy;
          tw2bus_bus.writeMask <= "0001";
          tw2bus_bus.writeData(7 downto 0) <= tw_pdeNewFlags;
          tw_state_next <= TWS_UPD_WAIT;
          
        -- Wait cycles for the PDE update.
        when TWS_UPD_WAIT =>
          
          tw2bus_bus.address <= tw_pdePtr;
          tw2bus_bus.writeEnable <= bus2tw_bus.busy;
          tw2bus_bus.writeMask <= "0001";
          tw2bus_bus.writeData(7 downto 0) <= tw_pdeNewFlags;
          tw_state_next <= TWS_IDLE;
          tw_state_we <= not bus2tw_bus.busy;
          tw_complete <= not bus2tw_bus.busy;
          
        -- Undefined state.
        when others => null;
        
      end case;
    end process;
    
    -- Connect the TLB fault signal output, indicating that even though the
    -- page walk is complete, the TLB should not be modified and the memory
    -- request should be cancelled.
    tw2tlb_fault <= '0' when tw_fault = FAULT_NONE else '1';
    
    -- Connect the complete output for each TLB.
    complete_output: for i in 0 to 2*2**RCFG.numLaneGroupsLog2-1 generate
      tw2tlb_complete(i) <= tw_complete when vect2uint(tw_block) = i else '0';
    end generate;
    
  end block;

  -----------------------------------------------------------------------------
  -- Fault registers
  -----------------------------------------------------------------------------
  -- If a fault occurs, the fault reporting signals to the core should be
  -- asserted until the next clkEn'd *unstalled* cycle, so we need registers.
  fault_regs: process (clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        tw2rv_iPageFault    <= (others => '0');
        tw2rv_iKernelAccVio <= (others => '0');
        tw2rv_iExecAccVio   <= (others => '0');
        tw2rv_dPageFault    <= (others => '0');
        tw2rv_dKernelAccVio <= (others => '0');
        tw2rv_dWriteAccVio  <= (others => '0');
        tw2rv_dWriteToClean <= (others => '0');
      elsif clkEn = '1' then
        
        -- Release fault signals when the core is unstalled.
        for i in 0 to 2**RCFG.numLaneGroupsLog2-1 loop
          if rv2tw_stallOut(i) = '0' then
            tw2rv_iPageFault(i)    <= '0';
            tw2rv_iKernelAccVio(i) <= '0';
            tw2rv_iExecAccVio(i)   <= '0';
            tw2rv_dPageFault(i)    <= '0';
            tw2rv_dKernelAccVio(i) <= '0';
            tw2rv_dWriteAccVio(i)  <= '0';
            tw2rv_dWriteToClean(i) <= '0';
          end if;
        end loop;
        
        -- Assert fault signals when the table walker completes with a fault.
        if tw_complete = '1' then
          if RCFG.numLaneGroupsLog2 /= 0 then
            for i in 0 to 2**RCFG.numLaneGroupsLog2-1 loop
              if vect2uint(tw_block(RCFG.numLaneGroupsLog2-1 downto 0)) = i then
                case tw_fault is
                  when FAULT_IPAGE  => tw2rv_iPageFault(i)    <= '1';
                  when FAULT_IKERN  => tw2rv_iKernelAccVio(i) <= '1';
                  when FAULT_IEXEC  => tw2rv_iExecAccVio(i)   <= '1';
                  when FAULT_DPAGE  => tw2rv_dPageFault(i)    <= '1';
                  when FAULT_DKERN  => tw2rv_dKernelAccVio(i) <= '1';
                  when FAULT_DWRITE => tw2rv_dWriteAccVio(i)  <= '1';
                  when FAULT_DWTC   => tw2rv_dWriteToClean(i) <= '1';
                  when others => null;
                end case;
              end if;
            end loop;
          else
            case tw_fault is
              when FAULT_IPAGE  => tw2rv_iPageFault    <= "1";
              when FAULT_IKERN  => tw2rv_iKernelAccVio <= "1";
              when FAULT_IEXEC  => tw2rv_iExecAccVio   <= "1";
              when FAULT_DPAGE  => tw2rv_dPageFault    <= "1";
              when FAULT_DKERN  => tw2rv_dKernelAccVio <= "1";
              when FAULT_DWRITE => tw2rv_dWriteAccVio  <= "1";
              when FAULT_DWTC   => tw2rv_dWriteToClean <= "1";
              when others => null;
            end case;
          end if;
        end if;
      end if;
    end if;
  end process;
  
end architecture; -- arch
