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
-- This entity represents the CAM portion of a TLB block. It supports global
-- and large pages (i.e. CAM entries with don't cares for part of the tag
-- and/or the ASID). This is just the content -> entry portion; the regular
-- memory storing the physical tag, page flags, and reverse lookup virtual tag
-- and ASID is added in the cache_tlb_mem wrapper.
-------------------------------------------------------------------------------
entity cache_tlb_cams is
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
    -- CAM read port
    ---------------------------------------------------------------------------
    -- Virtual address and ASID to look up, add to the CAM, or remove from the
    -- CAM.
    vAddr                       : in  rvex_address_type;
    asid                        : in  rvex_data_type;
    
    -- TLB entry associated with the virtual address and ASID given in the
    -- previous cycle. entry_index, entry_global, and entry_large are undefined
    -- when entry_valid is low.
    entry_valid                 : out std_logic;
    entry_index                 : out std_logic_vector(CCFG.tlbDepthLog2-1 downto 0);
    entry_global                : out std_logic;
    entry_large                 : out std_logic;
    
    ---------------------------------------------------------------------------
    -- CAM write port
    ---------------------------------------------------------------------------
    -- Update operation request, doubling as request enable. This requires
    -- precise timing as follows.
    --
    --  - Write to invalid entry:
    --     cyc1) vAddr/asid from new entry
    --           update_op "00" (nop)
    --     cyc2) update_global/update_large for new entry type
    --           update_op "11" (set bit)
    -- 
    --  - Modify entry:
    --     cyc1) vAddr/asid from previous entry
    --           update_op "00" (nop)
    --     cyc2) vAddr/asid from new entry
    --           update_op "10" (clear bit)
    --     cyc3) update_global/update_large for new entry type
    --           update_op "11" (set bit)
    -- 
    --  - Flush entry:
    --     cyc1) vAddr/asid from previous entry
    --           update_op "00" (nop) or update_op "10" (clear bit) to finish
    --             cyc2 from a preceding flush
    --     cyc2) update_op "10" (clear bit)
    --
    update_op                   : in  std_logic_vector(1 downto 0);
    
    -- Entry to modify. This must be valid the cycle *before* the update_op
    -- signal is set to "10" or "11", i.e. in the same cycle wherein vAddr and
    -- asid must be valid.
    update_index                : in  std_logic_vector(CCFG.tlbDepthLog2-1 downto 0);
    
    -- These bits specify what the large/global bits should be set to when
    -- update_op is "11".
    update_global               : in  std_logic;
    update_large                : in  std_logic
    
  );
end cache_tlb_cams;

--=============================================================================
architecture arch of cache_tlb_cams is
--=============================================================================
  
  -- Update index register to align with the second update phase (where the old
  -- RAM entry and flush match state are known).
  signal update_index_r         : std_logic_vector(CCFG.tlbDepthLog2-1 downto 0);
  
  -- "resetting" outputs for each CAM.
  signal resetting_L1           : std_logic;
  signal resetting_L2           : std_logic;
  signal resetting_ASID         : std_logic;
  
  -- Update operation for the L2 and ASID CAMs. They differ from the L1
  -- operation for large/global pages respectively.
  signal update_op_L2           : std_logic_vector(1 downto 0);
  signal update_op_ASID         : std_logic_vector(1 downto 0);
  
  -- One-hot outputs from the L1, L2, and ASID CAMs.
  signal oh_L1                  : std_logic_vector(2**CCFG.tlbDepthLog2-1 downto 0);
  signal oh_L2                  : std_logic_vector(2**CCFG.tlbDepthLog2-1 downto 0);
  signal oh_ASID                : std_logic_vector(2**CCFG.tlbDepthLog2-1 downto 0);
  
  -- One-hot outputs from the large/global flags.
  signal oh_flag_L              : std_logic_vector(2**CCFG.tlbDepthLog2-1 downto 0);
  signal oh_flag_G              : std_logic_vector(2**CCFG.tlbDepthLog2-1 downto 0);
  
  -- One-hot hit bits for each of the four page types.
  signal oh_N                   : std_logic_vector(2**CCFG.tlbDepthLog2-1 downto 0);
  signal oh_L                   : std_logic_vector(2**CCFG.tlbDepthLog2-1 downto 0);
  signal oh_G                   : std_logic_vector(2**CCFG.tlbDepthLog2-1 downto 0);
  signal oh_LG                  : std_logic_vector(2**CCFG.tlbDepthLog2-1 downto 0);
  
  -- Decoded binary signals for each of the four page types.
  signal bin_N                  : std_logic_vector(CCFG.tlbDepthLog2-1 downto 0);
  signal bin_L                  : std_logic_vector(CCFG.tlbDepthLog2-1 downto 0);
  signal bin_G                  : std_logic_vector(CCFG.tlbDepthLog2-1 downto 0);
  signal bin_LG                 : std_logic_vector(CCFG.tlbDepthLog2-1 downto 0);
  
  -- Hit signals for each of the four page types.
  signal hit_N                  : std_logic;
  signal hit_L                  : std_logic;
  signal hit_G                  : std_logic;
  signal hit_LG                 : std_logic;
  
  -- Page type priority decoder signals.
  signal hits                   : std_logic_vector(3 downto 0);
  signal ptype                  : std_logic_vector(1 downto 0);
  signal hit                    : std_logic;
  
  -- Winning page entry index.
  signal bin                    : std_logic_vector(CCFG.tlbDepthLog2-1 downto 0);
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- Update index phase alignment register
  -----------------------------------------------------------------------------
  update_index_reg: process (clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        update_index_r <= (others => '0');
      elsif clkEn = '1' then
        update_index_r <= update_index;
      end if;
    end if;
  end process;
  
  -----------------------------------------------------------------------------
  -- Instantiate the CAMs
  -----------------------------------------------------------------------------
  -- Level-1 CAM for all pages.
  cam_l1_inst: entity rvex.cache_tlb_cam
    generic map (
      DATA_W                    => mmuL1TagSize(CCFG),
      ADDR_W                    => CCFG.tlbDepthLog2,
      STYLE                     => CCFG.camStyle
    )
    port map (
      
      -- System control.
      reset                     => reset,
      resetting                 => resetting_L1,
      clk                       => clk,
      clkEn                     => clkEn,
      
      -- Read port.
      data                      => vAddr(tagL1Msb(CCFG) downto tagL1Lsb(CCFG)),
      addr_oneHot               => oh_L1,
    
      -- Write port.
      update_op                 => update_op,
      update_addr               => update_index_r
      
    );
  
  -- Determine update operation for the level-2 CAM. This overrides the
  -- operation with no-op when a large page entry is written. It does not
  -- affect clear or flush operations.
  update_op_L2(1) <= update_op(1);
  update_op_L2(0) <= update_op(0) and not update_large;
  
  -- Level-2 CAM for normal-sized pages.
  cam_l2_inst: entity rvex.cache_tlb_cam
    generic map (
      DATA_W                    => mmuL2TagSize(CCFG),
      ADDR_W                    => CCFG.tlbDepthLog2,
      STYLE                     => CCFG.camStyle
    )
    port map (
      
      -- System control.
      reset                     => reset,
      resetting                 => resetting_L2,
      clk                       => clk,
      clkEn                     => clkEn,
      
      -- Read port.
      data                      => vAddr(tagL2Msb(CCFG) downto tagL2Lsb(CCFG)),
      addr_oneHot               => oh_L2,
      
      -- Write port.
      update_op                 => update_op_L2,
      update_addr               => update_index_r
      
    );
  
  -- Determine update operation for the ASID CAM. This overrides the operation
  -- with no-op when a global page entry is written. It does not affect clear
  -- or flush operations.
  update_op_ASID(1) <= update_op(1);
  update_op_ASID(0) <= update_op(0) and not update_global;
  
  -- ASID CAM for non-global pages.
  cam_asid_inst: entity rvex.cache_tlb_cam
    generic map (
      DATA_W                    => mmuAsidSize(CCFG),
      ADDR_W                    => CCFG.tlbDepthLog2,
      STYLE                     => CCFG.camStyle
    )
    port map (
      
      -- System control.
      reset                     => reset,
      resetting                 => resetting_ASID,
      clk                       => clk,
      clkEn                     => clkEn,
      
      -- Read port.
      data                      => asid(mmuAsidSize(CCFG)-1 downto 0),
      addr_oneHot               => oh_ASID,
      
      -- Write port.
      update_op                 => update_op_ASID,
      update_addr               => update_index_r
      
    );
  
  -- Merge and forward the resetting signal.
  resetting <= resetting_L1 or resetting_L2 or resetting_ASID;
  
  -----------------------------------------------------------------------------
  -- Large/global page flag registers
  -----------------------------------------------------------------------------
  flag_reg_proc: process (clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        oh_flag_G <= (others => '0');
        oh_flag_L <= (others => '0');
      elsif clkEn = '1' then
        if update_op(0) = '1' then
          oh_flag_G(to_integer(unsigned(update_index_r))) <= update_global;
          oh_flag_L(to_integer(unsigned(update_index_r))) <= update_large;
        end if;
      end if;
    end if;
  end process;
  
  -----------------------------------------------------------------------------
  -- One-hot decoding logic
  -----------------------------------------------------------------------------
  -- We first need to get the one-hot vector for each page type. This is
  -- critical path stuff, so I really don't want the synthesis tools to mess up
  -- packing these LUTs efficiently. Therefore, they are instantiated directly.
  page_type_lut_gen: for i in 2**CCFG.tlbDepthLog2-1 downto 0 generate
  begin
    
    page_type_lut_ng: lut6_2
      generic map (
        INIT => X"C000C00080808080"
      )                      --        ...............
      port map (             --        :   4:2 LUT   :
        i0 => oh_flag_G(i),  --        :      ____   :
        i1 => oh_L1(i),      --  f_G -i0-----|    \  :
        i2 => oh_L2(i),      --        :   .-|     )-o5- G
        i3 => oh_ASID(i),    --   L1 -i1-o-+-|____/  :
        i4 => '0',           --        : | |  ____   :
        i5 => '1',           --   L2 -i2-+-o-|    \  :
        o5 => oh_G(i),       --        : '---|     )-o6- N
        o6 => oh_N(i)        -- ASID -i3-----|____/  :
      );                     --        :.............:
    
    page_type_lut_llg: lut6_2
      generic map (
        INIT => X"C000C00080808080"
      )                      --        ...............
      port map (             --        :   4:2 LUT   :
        i0 => oh_flag_G(i),  --        :      ____   :
        i1 => oh_L1(i),      --  f_G -i0-----|    \  :
        i2 => oh_flag_L(i),  --        :   .-|     )-o5- LG
        i3 => oh_ASID(i),    --   L1 -i1-o-+-|____/  :
        i4 => '0',           --        : | |  ____   :
        i5 => '1',           --  f_L -i2-+-o-|    \  :
        o5 => oh_LG(i),      --        : '---|     )-o6- L
        o6 => oh_L(i)        -- ASID -i3-----|____/  :
      );                     --        :.............:
    
  end generate;
  
  -- Next, for each page type, we need a one-hot decoder. This is because
  -- different page types can hit simultaneously, for instance when a normal
  -- page overrides a large page or when a local page overrides a global one.
  -- The one-hot to binary convertors use wide or gates (i.e. or gates
  -- explicitly instantiated to use carry logic) to minimize delay. Note that
  -- they are not priority decoders; this only works if there are no false
  -- positives.
  ohdec_N_inst: entity rvex.utils_ohdec
    generic map ( NUM_LOG2 => CCFG.tlbDepthLog2 )
    port map ( inp => oh_N, outp => bin_N, any => hit_N);
  
  ohdec_L_inst: entity rvex.utils_ohdec
    generic map ( NUM_LOG2 => CCFG.tlbDepthLog2 )
    port map ( inp => oh_L, outp => bin_L, any => hit_L);
  
  ohdec_G_inst: entity rvex.utils_ohdec
    generic map ( NUM_LOG2 => CCFG.tlbDepthLog2 )
    port map ( inp => oh_G, outp => bin_G, any => hit_G);
  
  ohdec_LG_inst: entity rvex.utils_ohdec
    generic map ( NUM_LOG2 => CCFG.tlbDepthLog2 )
    port map ( inp => oh_LG, outp => bin_LG, any => hit_LG);
  
  -- To determine which page type wins, we need a priority decoder. The
  -- priorities are as follows:
  hits <= (
    3 => hit_N, -- Highest priority: normal page
    2 => hit_L, --                   large page
    1 => hit_G, --                   global page
    0 => hit_LG -- Lowest priority:  large global page
  );
  -- This allows threads to override any globally defined pages, and
  -- secondarily allows small pages to override large pages.
  type_priodec_inst: entity rvex.utils_priodec
    generic map ( NUM_LOG2 => 2 )
    port map ( inp => hits, outp => ptype, any => hit);
  
  -- Multiplex between the entry indices from each one-hot decoder.
  with ptype select
    bin <= bin_N  when "11",
           bin_L  when "10",
           bin_G  when "01",
           bin_LG when others;
  
  -- Assign the output signals.
  entry_valid  <= hit;
  entry_index  <= bin;
  entry_global <= not ptype(1);
  entry_large  <= not ptype(0);
  
end architecture;
