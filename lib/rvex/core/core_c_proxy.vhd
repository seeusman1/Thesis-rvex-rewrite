-- r-VEX processor
-- Copyright (C) 2008-2015 by TU Delft.
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

-- Copyright (C) 2008-2015 by TU Delft.

-- pragma translate_off

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library rvex;
use rvex.common_pkg.all;
use rvex.utils_pkg.all;
use rvex.core_pkg.all;
use rvex.core_intIface_pkg.all;
use rvex.simUtils_pkg.all;

--=============================================================================
-- Modelsim FLI C model for the rvex core.
-------------------------------------------------------------------------------
entity core_c_proxy is
--=============================================================================
  generic (
  
    -- Unpacked CFG vector, because generics records are not supported by
    -- FLI...
    CFG_numLanesLog2            : natural;
    CFG_numLaneGroupsLog2       : natural;
    CFG_numContextsLog2         : natural;
    CFG_genBundleSizeLog2       : natural;
    CFG_bundleAlignLog2         : natural;
    CFG_multiplierLanes         : natural;
    CFG_memLaneRevIndex         : natural;
    CFG_numBreakpoints          : natural;
    CFG_forwarding              : boolean;
    CFG_limmhFromNeighbor       : boolean;
    CFG_limmhFromPreviousPair   : boolean;
    CFG_reg63isLink             : boolean;
    CFG_cregStartAddress        : rvex_address_type;
    CFG_resetVector0            : rvex_address_type;
    CFG_resetVector1            : rvex_address_type;
    CFG_resetVector2            : rvex_address_type;
    CFG_resetVector3            : rvex_address_type;
    CFG_resetVector4            : rvex_address_type;
    CFG_resetVector5            : rvex_address_type;
    CFG_resetVector6            : rvex_address_type;
    CFG_resetVector7            : rvex_address_type;
    CFG_unifiedStall            : boolean;
    CFG_traceEnable             : boolean;
    CFG_perfCountSize           : natural;
    CFG_cachePerfCountEnable    : boolean;
    
    -- Normal generics.
    CORE_ID                     : natural := 0;
    PLATFORM_TAG                : std_logic_vector(55 downto 0) := (others => '0')
    
  );
  port (
    
    -- System control.
    reset                       : in  std_logic;
    resetOut                    : out std_logic;
    clk                         : in  std_logic;
    clkEn                       : in  std_logic := '1';
    
    -- VHDL simulation debug information.
    rv2sim                      : out rvex_string_array(1 to 2*2**CFG_numLanesLog2+2**CFG_numLaneGroupsLog2+2**CFG_numContextsLog2);
    
    -- Run control interface.
    rctrl2rv_irq                : in  std_logic_vector(2**CFG_numContextsLog2-1 downto 0);
    rctrl2rv_irqID              : in  rvex_address_array(2**CFG_numContextsLog2-1 downto 0);
    rv2rctrl_irqAck             : out std_logic_vector(2**CFG_numContextsLog2-1 downto 0);
    rctrl2rv_run                : in  std_logic_vector(2**CFG_numContextsLog2-1 downto 0);
    rv2rctrl_idle               : out std_logic_vector(2**CFG_numContextsLog2-1 downto 0);
    rctrl2rv_reset              : in  std_logic_vector(2**CFG_numContextsLog2-1 downto 0);
    rctrl2rv_resetVect          : in  rvex_address_array(2**CFG_numContextsLog2-1 downto 0);
    rv2rctrl_done               : out std_logic_vector(2**CFG_numContextsLog2-1 downto 0);
    
    -- Common memory interface.
    rv2mem_decouple             : out std_logic_vector(2**CFG_numLaneGroupsLog2-1 downto 0);
    mem2rv_blockReconfig        : in  std_logic_vector(2**CFG_numLaneGroupsLog2-1 downto 0);
    mem2rv_stallIn              : in  std_logic_vector(2**CFG_numLaneGroupsLog2-1 downto 0);
    rv2mem_stallOut             : out std_logic_vector(2**CFG_numLaneGroupsLog2-1 downto 0);
    mem2rv_cacheStatus          : in  rvex_cacheStatus_array(2**CFG_numLaneGroupsLog2-1 downto 0);
    
    -- Instruction memory interface.
    rv2imem_PCs                 : out rvex_address_array(2**CFG_numLaneGroupsLog2-1 downto 0);
    rv2imem_fetch               : out std_logic_vector(2**CFG_numLaneGroupsLog2-1 downto 0);
    rv2imem_cancel              : out std_logic_vector(2**CFG_numLaneGroupsLog2-1 downto 0);
    imem2rv_instr               : in  rvex_syllable_array(2**CFG_numLanesLog2-1 downto 0);
    imem2rv_affinity            : in  std_logic_vector(2**CFG_numLaneGroupsLog2*CFG_numLaneGroupsLog2-1 downto 0);
    imem2rv_busFault            : in  std_logic_vector(2**CFG_numLaneGroupsLog2-1 downto 0);
    
    -- Data memory interface.
    rv2dmem_addr                : out rvex_address_array(2**CFG_numLaneGroupsLog2-1 downto 0);
    rv2dmem_readEnable          : out std_logic_vector(2**CFG_numLaneGroupsLog2-1 downto 0);
    rv2dmem_writeData           : out rvex_data_array(2**CFG_numLaneGroupsLog2-1 downto 0);
    rv2dmem_writeMask           : out rvex_mask_array(2**CFG_numLaneGroupsLog2-1 downto 0);
    rv2dmem_writeEnable         : out std_logic_vector(2**CFG_numLaneGroupsLog2-1 downto 0);
    dmem2rv_readData            : in  rvex_data_array(2**CFG_numLaneGroupsLog2-1 downto 0);
    dmem2rv_ifaceFault          : in  std_logic_vector(2**CFG_numLaneGroupsLog2-1 downto 0);
    dmem2rv_busFault            : in  std_logic_vector(2**CFG_numLaneGroupsLog2-1 downto 0);
    
    -- Control/debug bus interface.
    dbg2rv_addr                 : in  rvex_address_type;
    dbg2rv_readEnable           : in  std_logic;
    dbg2rv_writeEnable          : in  std_logic;
    dbg2rv_writeMask            : in  rvex_mask_type;
    dbg2rv_writeData            : in  rvex_data_type;
    rv2dbg_readData             : out rvex_data_type;
    
    -- Trace interface.
    rv2trsink_push              : out std_logic;
    rv2trsink_data              : out rvex_byte_type;
    rv2trsink_end               : out std_logic;
    trsink2rv_busy              : in  std_logic
    
  );
end core_c_proxy;

--=============================================================================
architecture c_model of core_c_proxy is
--=============================================================================
  attribute foreign : string;
  attribute foreign of c_model : architecture is "rvex_core core_c.so";
begin
end;

-- pragma translate_on
