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

library unisim;
use unisim.vcomponents.all;

library rvex;
use rvex.common_pkg.all;
use rvex.cache_pkg.all;
use rvex.utils_pkg.all;

--=============================================================================
-- This entity contains all memories needed by the TLB, i.e. the CAMs to go
-- from virtual tag and ASID to TLB entry index, and the regular memories that
-- store information for each entry.
-------------------------------------------------------------------------------
entity cache_tlb_mem is
--=============================================================================
  generic (
    
    -- Configuration.
    CCFG                        : cache_generic_config_type := cache_cfg
    
  );
  port (
    
    ---------------------------------------------------------------------------
    -- System control
    ---------------------------------------------------------------------------
    -- Active high synchronous reset input.
    reset                       : in  std_logic;
    
    -- After reset is deasserted, a state machine ensures that the RAMs are
    -- reset as well. This takes some time. While this reset is in progress,
    -- this signal is asserted high, and accesses are illegal.
    resetting                   : out std_logic;
    
    -- Clock input, registers are rising edge triggered.
    clk                         : in  std_logic;
    
    -- Active high global clock enable input.
    clkEn                       : in  std_logic := '1';
    
    ---------------------------------------------------------------------------
    -- Read port
    ---------------------------------------------------------------------------
    -- Virtual address and ASID to look up, add to the CAM, or remove from the
    -- CAM.
    rcmd_vAddr                  : in  rvex_address_type;
    rcmd_asid                   : in  rvex_data_type;
    
    -- Physical address and other page information associated with the vAddr
    -- and pAddr from the previous cycle, valid only if rrep_valid is asserted
    -- high.
    rrep_valid                  : out std_logic;
    rrep_pAddr                  : out rvex_address_type;
    rrep_global                 : out std_logic;
    rrep_large                  : out std_logic;
    rrep_dirty                  : out std_logic;
    rrep_cacheDisable           : out std_logic;
    rrep_writeThrough           : out std_logic;
    rrep_user                   : out std_logic;
    rrep_writable               : out std_logic;
    
    ---------------------------------------------------------------------------
    -- Update port
    ---------------------------------------------------------------------------
    -- Update operation. This requires precise timing as follows.
    --
    --  - Add entry:
    --     cyc1) update_op "000" (nop)
    --     cyc2) update_op "011" (set bit)
    --    rcmd_vAddr, rcmd_asid, and update_index must be valid in cyc1.
    -- 
    --  - Modify entry:
    --     cyc1) update_op "100" (reverse lookup)
    --     cyc2) update_op "010" (clear bit)
    --     cyc3) update_op "011" (set bit)
    --    rcmd_vAddr, rcmd_asid, and update_index must be valid in cyc1 and
    --    cyc2.
    -- 
    --  - Remove entry:
    --     cyc1) update_op "100" (reverse lookup)
    --     cyc2) update_op "010" (clear bit)
    --    update_index must be valid in cyc1.
    -- 
    --  - Flush:
    --     cyc1) update_op "100" (reverse lookup), index 0
    --     cyc2) update_op "110" (clear bit if match), index 1
    --     cyc3) update_op "110" (clear bit if match), index 2
    --     ...
    --     cycn) update_op "110" (clear bit if match), index n-1
    --     cycm) update_op "110" (clear bit if match), index don't care
    --    (so n+1 cycles, where n is the number of TLB entries)
    --
    -- Specifically, the bits have these functions:
    --   Bit 2: if set, vAddr and asid are ignored and are instead taken from
    --          the reverse lookup memory based on update_index. This memory
    --          is asynchronous.
    --   Bit 1: if set, the CAM one-hot memories will do a modify-write
    --          operation using the value read in the previous cycle and the
    --          (possibly overridden) vAddr and asid from the previous cycle.
    --   Bit 0: may only be set in conjunction with bit 1. If set, the
    --          modify-write operation adds the entry, if cleared, the entry
    --          is removed. This bit is also used as a write enable for the
    --          entry to tag memories.
    update_op                   : in  std_logic_vector(2 downto 0);
    
    -- Entry to modify. Must be valid while update_op is "01" or "10", in which
    -- case the one-hot bit belonging to the entry will be set or cleared
    -- respectively.
    update_index                : in  std_logic_vector(CCFG.tlbDepthLog2-1 downto 0);
    
    -- These bits specify what the tags should be set to when update_op is
    -- "001".
    update_pAddr                : in  rvex_address_type;
    update_global               : in  std_logic;
    update_large                : in  std_logic;
    update_dirty                : in  std_logic;
    update_cacheDisable         : in  std_logic;
    update_writeThrough         : in  std_logic;
    update_user                 : in  std_logic;
    update_writable             : in  std_logic;
    
    -- Flush range configuration. In order for an entry to be flushed, the
    -- virtual address excluding the page offset must be greater than or equal
    -- to flush_vAddrLow and less than or equal to flush_vAddrHigh, and if
    -- flush_asidEnable is high, the ASID must match flush_asid.
    flush_vAddrLow              : in  rvex_address_type;
    flush_vAddrHigh             : in  rvex_address_type;
    flush_asidEnable            : in  std_logic;
    flush_asid                  : in  rvex_data_type
    
  );
end cache_tlb_mem;

--=============================================================================
architecture arch of cache_tlb_mem is
--=============================================================================
  
  -- Update index and virtual address registers to align with the second update
  -- phase (where the old RAM entry and flush match state are known).
  signal update_index_r         : std_logic_vector(CCFG.tlbDepthLog2-1 downto 0);
  signal vAddr_r                : rvex_address_type;
  signal asid_r                 : rvex_data_type;
  
  -- Virtual address and ASID, overridden by the value from the reverse lookup
  -- memory if update_op(2) is high.
  signal cam_vAddr              : rvex_address_type;
  signal cam_asid               : rvex_data_type;
  
  -- Virtual address and ASID from the reverse lookup memory, aligned with the
  -- second phase, to compare against the flush range.
  signal rev_vAddr_r            : rvex_address_type;
  signal rev_asid_r             : rvex_data_type;
  
  -- Update operation for the CAM. This is just update_op(1..0) usually, except
  -- when update_op(2) is set and the entry associated with update_index_r is
  -- not within the specified flush range, in which case update_op(1) is
  -- overridden to zero.
  signal cam_update_op          : std_logic_vector(1 downto 0);
  
  -- Entry index output from the CAMs.
  signal rrep_index             : std_logic_vector(CCFG.tlbDepthLog2-1 downto 0);
  
  -- Local copy of rrep_large, needed to construct the physical address.
  signal rrep_large_l           : std_logic;
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- CAM instantiation
  -----------------------------------------------------------------------------
  cam_inst: entity work.cache_tlb_cams
    generic map (
      CCFG                      => CCFG
    )
    port map (
      
      -- System control.
      reset                     => reset,
      resetting                 => resetting,
      clk                       => clk,
      clkEn                     => clkEn,
      
      -- CAM read port.
      vAddr                     => cam_vAddr,
      asid                      => cam_asid,
      entry_valid               => rrep_valid,
      entry_index               => rrep_index,
      entry_global              => rrep_global,
      entry_large               => rrep_large_l,
      
      -- CAM write port.
      update_op                 => cam_update_op,
      update_index              => update_index,
      update_global             => update_global,
      update_large              => update_large
      
    );
  
  rrep_large <= rrep_large_l;
  
  -----------------------------------------------------------------------------
  -- Phase alignment registers
  -----------------------------------------------------------------------------
  update_index_reg: process (clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        update_index_r <= (others => '0');
        vAddr_r <= (others => '0');
        asid_r <= (others => '0');
      elsif clkEn = '1' then
        update_index_r <= update_index;
        vAddr_r <= rcmd_vAddr;
        asid_r <= rcmd_asid;
      end if;
    end if;
  end process;
  
  -----------------------------------------------------------------------------
  -- Forward lookup memory and physical address construction
  -----------------------------------------------------------------------------
  -- This memory maps from TLB entry to the physical tag and page flags. The
  -- read path is in the critical path.
  fwd_mem: block is
    
    -- Memory width. We store the physical tag and 5 flags (DCWUR).
    constant FLAG_D     : natural := mmuTagSize(CCFG) + 0;
    constant FLAG_C     : natural := mmuTagSize(CCFG) + 1;
    constant FLAG_W     : natural := mmuTagSize(CCFG) + 2;
    constant FLAG_U     : natural := mmuTagSize(CCFG) + 3;
    constant FLAG_R     : natural := mmuTagSize(CCFG) + 4;
    constant RAM_WIDTH  : natural := mmuTagSize(CCFG) + 5;
    
    -- Memory types.
    subtype ram_entry_type is std_logic_vector(RAM_WIDTH-1 downto 0);
    type ram_entry_array is array (natural range <>) of ram_entry_type;
    subtype ram_array is ram_entry_array(0 to 2**CCFG.tlbDepthLog2-1);
    
    -- Memory contents.
    signal mem                  : ram_array;
    attribute ram_style         : string;
    attribute ram_style of mem  : signal is "distributed";
    
    -- Read and write data for the memory.
    signal memrd                : ram_entry_type;
    signal memwr                : ram_entry_type;
    
  begin
    
    -- Set up the write data.
    memwr(mmuTagSize(CCFG)-1 downto 0)
      <= update_pAddr(tagL1Msb(CCFG) downto tagL2Lsb(CCFG));
    memwr(FLAG_D) <= update_dirty;
    memwr(FLAG_C) <= update_cacheDisable;
    memwr(FLAG_W) <= update_writeThrough;
    memwr(FLAG_U) <= update_user;
    memwr(FLAG_R) <= update_writable;
    
    -- Infer the memory.
    ram_proc: process (clk) is
    begin
      if rising_edge(clk) then
        if clkEn = '1' then
          if update_op(0) = '1' then
            mem(to_integer(unsigned(update_index_r))) <= memwr;
          end if;
        end if;
      end if;
    end process;
    
    memrd <= mem(to_integer(unsigned(rrep_index)));
    
    -- Extract the physical address.
    phys_addr_proc: process (memrd, vAddr_r, rrep_large_l) is
      variable pTag : rvex_address_type;
      variable addr : rvex_address_type;
    begin
      pTag(tagL1Msb(CCFG) downto tagL2Lsb(CCFG))
        := memrd(mmuTagSize(CCFG)-1 downto 0);
      
      -- Start with the virtual address.
      addr := vAddr_r;
      
      -- Always override the level 1 tag.
      addr(tagL1Msb(CCFG) downto tagL1Lsb(CCFG))
        := pTag(tagL1Msb(CCFG) downto tagL1Lsb(CCFG));
      
      -- Override the level 2 tag if this is a normal page.
      if rrep_large_l = '0' then
        addr(tagL2Msb(CCFG) downto tagL2Lsb(CCFG))
          := pTag(tagL2Msb(CCFG) downto tagL2Lsb(CCFG));
      end if;
      
      rrep_pAddr <= addr;
    end process;
    
    -- Extract the flags.
    rrep_dirty        <= memrd(FLAG_D);
    rrep_cacheDisable <= memrd(FLAG_C);
    rrep_writeThrough <= memrd(FLAG_W);
    rrep_user         <= memrd(FLAG_U);
    rrep_writable     <= memrd(FLAG_R);
    
  end block;
  
  -----------------------------------------------------------------------------
  -- Reverse lookup memory
  -----------------------------------------------------------------------------
  -- This memory maps from TLB entry to virtual tag and ASID. It's needed for
  -- removing CAM entries and flushing.
  rev_mem: block is
    
    -- Memory width. We store the virtual tag and the ASID.
    constant RAM_WIDTH  : natural := mmuTagSize(CCFG) + mmuAsidSize(CCFG);
    
    -- Memory types.
    subtype ram_entry_type is std_logic_vector(RAM_WIDTH-1 downto 0);
    type ram_entry_array is array (natural range <>) of ram_entry_type;
    subtype ram_array is ram_entry_array(0 to 2**CCFG.tlbDepthLog2-1);
    
    -- Memory contents.
    signal mem                  : ram_array;
    attribute ram_style         : string;
    attribute ram_style of mem  : signal is "distributed";
    
    -- Read and write data for the memory.
    signal memrd                : ram_entry_type;
    signal memwr                : ram_entry_type;
    
  begin
    
    -- Set up the write data.
    memwr(mmuTagSize(CCFG)-1 downto 0)
      <= vAddr_r(tagL1Msb(CCFG) downto tagL2Lsb(CCFG));
    memwr(mmuTagSize(CCFG)+mmuAsidSize(CCFG)-1 downto mmuTagSize(CCFG))
      <= asid_r(mmuAsidSize(CCFG)-1 downto 0);
    
    -- Infer the memory.
    ram_proc: process (clk) is
    begin
      if rising_edge(clk) then
        if clkEn = '1' then
          if update_op(0) = '1' then
            mem(to_integer(unsigned(update_index_r))) <= memwr;
          end if;
        end if;
      end if;
    end process;
    
    memrd <= mem(to_integer(unsigned(update_index)));
    
    -- Extract the virtual address and ASID and override the input signals with
    -- them when update_op(2) is set.
    extract_proc: process (update_op, rcmd_vAddr, rcmd_asid, memrd) is
      variable vAddr_s : rvex_address_type;
      variable asid_s  : rvex_data_type;
    begin
      
      -- Use the inputs by default.
      vAddr_s := rcmd_vAddr;
      asid_s := rcmd_asid;
      
      -- Override with the data from the reverse lookup memory when
      -- update_op(2) is set.
      if update_op(2) = '1' then
        vAddr_s(tagL1Msb(CCFG) downto tagL2Lsb(CCFG)) :=
          memrd(mmuTagSize(CCFG)-1 downto 0);
        asid_s(mmuAsidSize(CCFG)-1 downto 0) :=
          memrd(mmuTagSize(CCFG)+mmuAsidSize(CCFG)-1 downto mmuTagSize(CCFG));
      end if;
      
      cam_vAddr <= vAddr_s;
      cam_asid <= asid_s;
    end process;
    
    -- Store the reverse lookup data for matching with the flush range.
    rev_reg_proc: process (clk) is
    begin
      if rising_edge(clk) then
        if reset = '1' then
          rev_vAddr_r <= (others => '0');
          rev_asid_r  <= (others => '0');
        elsif clkEn = '1' then
          rev_vAddr_r(tagL1Msb(CCFG) downto tagL2Lsb(CCFG)) <=
            memrd(mmuTagSize(CCFG)-1 downto 0);
          rev_asid_r(mmuAsidSize(CCFG)-1 downto 0) <=
            memrd(mmuTagSize(CCFG)+mmuAsidSize(CCFG)-1 downto mmuTagSize(CCFG));
        end if;
      end if;
    end process;
    
  end block;
  
  -----------------------------------------------------------------------------
  -- Flushing logic
  -----------------------------------------------------------------------------
  flush_block: block is
    
    -- Register all the flush range inputs to break the path up a bit for the
    -- synthesis tools.
    signal flush_vAddrLow_r   : rvex_address_type;
    signal flush_vAddrHigh_r  : rvex_address_type;
    signal flush_asidEnable_r : std_logic;
    signal flush_asid_r       : rvex_data_type;
    
    -- This is asserted when the TLB entry that was reverse-lookup'd in the
    -- previous cycle matches the registered flush range.
    signal match              : std_logic;
    
  begin
    
    -- Instantiate the range registers.
    reg_proc: process (clk) is
    begin
      if rising_edge(clk) then
        if reset = '1' then
          flush_vAddrLow_r   <= (others => '0');
          flush_vAddrHigh_r  <= (others => '0');
          flush_asidEnable_r <= '0';
          flush_asid_r       <= (others => '0');
        elsif clkEn = '1' then
          flush_vAddrLow_r   <= flush_vAddrLow;
          flush_vAddrHigh_r  <= flush_vAddrHigh;
          flush_asidEnable_r <= flush_asidEnable;
          flush_asid_r       <= flush_asid;
        end if;
      end if;
    end process;
    
    -- Instantiate the comparators.
    compare_proc: process (
      flush_vAddrLow_r, flush_vAddrHigh_r, flush_asidEnable_r, flush_asid_r,
      rev_vAddr_r, rev_asid_r
    ) is
      
      -- Extracts the tag from an address and converts to unsigned.
      pure function tag_fn(x: rvex_address_type) return unsigned is
      begin
        return unsigned(x(tagL1Msb(CCFG) downto tagL2Lsb(CCFG)));
      end function tag_fn;
      
      -- Extracts the relevant part of the ASID vector and converts to
      -- unsigned.
      pure function asid_fn(x: rvex_data_type) return unsigned is
      begin
        return unsigned(x(mmuAsidSize(CCFG)-1 downto 0));
      end function asid_fn;
      
    begin
      match <= '1';
      
      -- Check the lower virtual address limit.
      if tag_fn(rev_vAddr_r) < tag_fn(flush_vAddrLow_r) then
        match <= '0';
      end if;
      
      -- Check the upper virtual address limit.
      if tag_fn(rev_vAddr_r) > tag_fn(flush_vAddrHigh_r) then
        match <= '0';
      end if;
      
      -- Check the ASID.
      if flush_asidEnable_r = '1' then
        if asid_fn(rev_asid_r) /= asid_fn(flush_asid_r) then
          match <= '0';
        end if;
      end if;
      
    end process;
    
    -- Construct cam_update_op. This is just the two LSBs of update_op unless
    -- we're flushing and the current entry does not match the flush range.
    cam_update_op(0) <= update_op(0);
    cam_update_op(1) <= update_op(1) and not (update_op(2) and not match);
    
  end block;
  
end architecture;
