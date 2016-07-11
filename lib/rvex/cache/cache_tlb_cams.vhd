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
use rvex.cache_pkg.all;
use rvex.utils_pkg.all;

--=============================================================================
-- This entity represents the CAM portion of a TLB block. It supports global
-- and large pages (i.e. CAM entries with don't cares for part of the tag
-- and/or the ASID).
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
    
    -- Clock input, registers are rising edge triggered.
    clk                         : in  std_logic;
    
    -- Active high global clock enable input.
    clkEn                       : in  std_logic;
    
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
    --     cyc0) vAddr/asid from new entry
    --           update_op "00" (nop)
    --     cyc1) vAddr/asid from new entry
    --           update_op "01" (set bit)
    -- 
    --  - Modify entry:
    --     cyc1) vAddr/asid from previous entry
    --           update_op "00" (nop)
    --     cyc2) vAddr/asid from previous entry
    --           update_op "10" (clear bit)
    --     cyc3) vAddr/asid from new entry
    --           update_op "00" (nop)
    --     cyc4) vAddr/asid from new entry
    --           update_op "01" (set bit)
    -- 
    --  - Flush entry:
    --     cyc1) vAddr/asid from previous entry
    --           update_op "00" (nop)
    --     cyc2) vAddr/asid from previous entry
    --           update_op "10" (clear bit)
    -- 
    --  - Flush all:
    --     cyc1..numEntries) vAddr/asid from previous entry
    --           update_op "11" (clear all)
    update_op                   : in  std_logic_vector(1 downto 0);
    
    -- Entry to modify. Must be valid while update_op is "01" or "10", in which
    -- case the one-hot bit belonging to the entry will be set or cleared
    -- respectively.
    update_index                : in  std_logic_vector(CCFG.tlbDepthLog2-1 downto 0);
    
    -- These bits specify what the large/global bits should be set to when
    -- update_op is "01".
    update_global               : in  std_logic;
    update_large                : in  std_logic
    
  );
end cache_tlb_cams;

--=============================================================================
architecture arch of cache_tlb_cams is
--=============================================================================
  
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
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- Instantiate the CAMs
  -----------------------------------------------------------------------------
  -- Level-1 CAM for all pages.
  cam_l1_inst: entity rvex.cache_tlb_cam
    generic map (
      DATA_W                    => mmuL1TagSize(CCFG),
      ADDR_W                    => CCFG.tlbDepthLog2,
      STYLE                     => CRS_DEFAULT
    )
    port map (
      
      -- System control.
      clk                       => clk,
      clkEn                     => clkEn,
      
      -- Read port.
      data                      => vAddr(tagL1Msb(CCFG) downto tagL1Lsb(CCFG)),
      addr_oneHot               => oh_L1,
    
      -- Write port.
      update_op                 => update_op,
      update_addr               => update_index
      
    );
  
  -- Level-2 CAM for normal-sized pages.
  cam_l2_inst: entity rvex.cache_tlb_cam
    generic map (
      DATA_W                    => mmuL2TagSize(CCFG),
      ADDR_W                    => CCFG.tlbDepthLog2,
      STYLE                     => CRS_DEFAULT
    )
    port map (
      
      -- System control.
      clk                       => clk,
      clkEn                     => clkEn,
      
      -- Read port.
      data                      => vAddr(tagL2Msb(CCFG) downto tagL2Lsb(CCFG)),
      addr_oneHot               => oh_L2,
      
      -- Write port.
      update_op                 => update_op,
      update_addr               => update_index
      
    );
  
  -- ASID CAM for non-global pages.
  cam_asid_inst: entity rvex.cache_tlb_cam
    generic map (
      DATA_W                    => mmuAsidSize(CCFG),
      ADDR_W                    => CCFG.tlbDepthLog2,
      STYLE                     => CRS_DEFAULT
    )
    port map (
      
      -- System control.
      clk                       => clk,
      clkEn                     => clkEn,
      
      -- Read port.
      data                      => asid(mmuAsidSize(CCFG)-1 downto 0),
      addr_oneHot               => oh_ASID,
      
      -- Write port.
      update_op                 => update_op,
      update_addr               => update_index
      
    );
  
  -----------------------------------------------------------------------------
  -- Instantiate the large and global page flag registers
  -----------------------------------------------------------------------------
  flag_reg_proc: process (clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        oh_flag_G <= (others => '0');
        oh_flag_L <= (others => '0');
      elsif clkEn = '1' then
        if update_index = "01" then
          for i in oh_flag_L'range loop
            if to_integer(unsigned(update_addr)) = i then
              oh_flag_G(i) <= update_global;
              oh_flag_L(i) <= update_large;
            end if;
          end loop;
        end if;
      end if;
    end if;
  end process;
  
  -----------------------------------------------------------------------------
  -- One-hot decoding logic
  -----------------------------------------------------------------------------
  -- We need a one-hot decoder for each page type. This is all critical path
  -- stuff, so we want to do this as efficiently as possible.
  --
  -- We first need to get the one-hot vector for each page type. This is done
  -- as follows:
  --        ...............                ...............
  --        :   5:2 LUT   :                :   5:2 LUT   :
  --        :      ____   :                :      ____   :
  --  f_G --------|    \  :          f_G --------|    \  :
  --        :   .-|     )---- G            :   .-|     )---- LG
  --   L1 ----o-+-|____/  :           L1 ----o-+-|____/  :
  --        : | |  ____   :                : | |  ____   :
  --   L2 ----+-o-|    \  :          f_L ----+-o-|    \  :
  --        : '---|     )---- N            : '---|     )---- L
  -- ASID --------|____/  :         ASID --------|____/  :
  --        :.............:                :.............:
  -- 
  -- The one-hot to binary convertor that follows for each page type is done
  -- making use of the carry networks to make wide or gates.
  
  
  
end architecture;
