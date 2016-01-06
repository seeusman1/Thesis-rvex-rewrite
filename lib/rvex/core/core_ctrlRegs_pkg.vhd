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

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library rvex;
use rvex.common_pkg.all;

--=============================================================================
-- This package contains constants specifying the word addresses of the control
-- registers as accessed from the debug bus or by a memory unit. It also
-- contains methods which generate register logic for several different kinds
-- of registers.
-------------------------------------------------------------------------------
package core_ctrlRegs_pkg is
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- Control register geometry
  -----------------------------------------------------------------------------
  -- The control register memory map is coarsely hardcoded in core_ctrlRegs.vhd
  -- as follows.
  --                                    | Core  | Debug |
  --         ___________________________|_______|_______|
  --  0x3FF | Context registers         |  R/W  |  R/W  |
  --  0x200 |___________________________|_______|_______|
  --  0x1FF | General purpose registers |   -   |  R/W  |
  --  0x100 |___________________________|_______|_______|
  --  0x0FF | Global registers          |   R   |  R/W  |
  --  0x000 |___________________________|_______|_______|
  --
  -- There are two ways to access these registers. The first is from the core
  -- itself, by making memory accesses to a contiguous region of memory mapped
  -- to the registers. The region is 1kiB in size and must be aligned to 1kiB
  -- boundaries; other than that, the location is specified by cregStartAddress
  -- in CFG. The second method is the debug bus. Because there is no context
  -- associated with the debug bus, bits 12..10 of the address are used to
  -- specify it. The global registers are mirrored for each context, but should
  -- always be read from context 0. That way, platforms can override those
  -- 256-byte regions with platform-specific registers without wasting address
  -- space. The debug bus can read from and write to everything, but the core
  -- itself has limited access, as shown in the table above.
  --
  -- The core can only access registers belonging to the context it is
  -- currently running internally. If cross-context access is needed, the
  -- memory bus of the rvex must be connected to the debug bus externally.
  --
  -- The registers are fully specified in the :/config/ directory of the
  -- repository.
  
  -- Size of the control register file accessible from the core through data
  -- memory operations.
  constant CRG_SIZE_BLOG2       : natural := 10;
  
  -- ##################### GENERATED FROM HERE ONWARDS ##################### --
  -- Do not remove the above line. It is used as a marker by the generator
  -- scripts.
                                                                                -- GENERATED --
  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  -- Global status register
  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  constant CR_GSR               : std_logic_vector(7 downto 2) := "000000";

  constant CR_GSR_R_H           : natural := 31;
  constant CR_GSR_R_L           : natural := 31;

  constant CR_GSR_E_H           : natural := 13;
  constant CR_GSR_E_L           : natural := 13;                                -- GENERATED --

  constant CR_GSR_B_H           : natural := 12;
  constant CR_GSR_B_L           : natural := 12;

  constant CR_GSR_RID_H         : natural := 11;
  constant CR_GSR_RID_L         : natural := 8;

  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  -- Bus reconfiguration request register
  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  -- GENERATED --
  constant CR_BCRR              : std_logic_vector(7 downto 2) := "000001";

  constant CR_BCRR_BCRR_H       : natural := 31;
  constant CR_BCRR_BCRR_L       : natural := 0;

  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  -- Current configuration register
  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  constant CR_CC                : std_logic_vector(7 downto 2) := "000010";
                                                                                -- GENERATED --
  constant CR_CC_CC_H           : natural := 31;
  constant CR_CC_CC_L           : natural := 0;

  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  -- Cache affinity register
  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  constant CR_AFF               : std_logic_vector(7 downto 2) := "000011";

  constant CR_AFF_AF_H          : natural := 31;
  constant CR_AFF_AF_L          : natural := 0;                                 -- GENERATED --

  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  -- Cycle counter register, low word
  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  constant CR_CNT               : std_logic_vector(7 downto 2) := "000100";

  constant CR_CNT_CNT_H         : natural := 31;
  constant CR_CNT_CNT_L         : natural := 0;

  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  -- GENERATED --
  -- Cycle counter register, high word
  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  constant CR_CNTH              : std_logic_vector(7 downto 2) := "000101";

  constant CR_CNTH_CNTH_H       : natural := 31;
  constant CR_CNTH_CNTH_L       : natural := 0;

  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  -- Long immediate capability register $n$
  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  -- GENERATED --
  constant CR_LIMC7             : std_logic_vector(7 downto 2) := "101000";

  constant CR_LIMC7_BORROW15_H  : natural := 31;
  constant CR_LIMC7_BORROW15_L  : natural := 16;

  constant CR_LIMC7_BORROW14_H  : natural := 15;
  constant CR_LIMC7_BORROW14_L  : natural := 0;

  constant CR_LIMC6             : std_logic_vector(7 downto 2) := "101001";
                                                                                -- GENERATED --
  constant CR_LIMC6_BORROW13_H  : natural := 31;
  constant CR_LIMC6_BORROW13_L  : natural := 16;

  constant CR_LIMC6_BORROW12_H  : natural := 15;
  constant CR_LIMC6_BORROW12_L  : natural := 0;

  constant CR_LIMC5             : std_logic_vector(7 downto 2) := "101010";

  constant CR_LIMC5_BORROW11_H  : natural := 31;
  constant CR_LIMC5_BORROW11_L  : natural := 16;                                -- GENERATED --

  constant CR_LIMC5_BORROW10_H  : natural := 15;
  constant CR_LIMC5_BORROW10_L  : natural := 0;

  constant CR_LIMC4             : std_logic_vector(7 downto 2) := "101011";

  constant CR_LIMC4_BORROW9_H   : natural := 31;
  constant CR_LIMC4_BORROW9_L   : natural := 16;

  constant CR_LIMC4_BORROW8_H   : natural := 15;                                -- GENERATED --
  constant CR_LIMC4_BORROW8_L   : natural := 0;

  constant CR_LIMC3             : std_logic_vector(7 downto 2) := "101100";

  constant CR_LIMC3_BORROW7_H   : natural := 31;
  constant CR_LIMC3_BORROW7_L   : natural := 16;

  constant CR_LIMC3_BORROW6_H   : natural := 15;
  constant CR_LIMC3_BORROW6_L   : natural := 0;
                                                                                -- GENERATED --
  constant CR_LIMC2             : std_logic_vector(7 downto 2) := "101101";

  constant CR_LIMC2_BORROW5_H   : natural := 31;
  constant CR_LIMC2_BORROW5_L   : natural := 16;

  constant CR_LIMC2_BORROW4_H   : natural := 15;
  constant CR_LIMC2_BORROW4_L   : natural := 0;

  constant CR_LIMC1             : std_logic_vector(7 downto 2) := "101110";
                                                                                -- GENERATED --
  constant CR_LIMC1_BORROW3_H   : natural := 31;
  constant CR_LIMC1_BORROW3_L   : natural := 16;

  constant CR_LIMC1_BORROW2_H   : natural := 15;
  constant CR_LIMC1_BORROW2_L   : natural := 0;

  constant CR_LIMC0             : std_logic_vector(7 downto 2) := "101111";

  constant CR_LIMC0_BORROW1_H   : natural := 31;
  constant CR_LIMC0_BORROW1_L   : natural := 16;                                -- GENERATED --

  constant CR_LIMC0_BORROW0_H   : natural := 15;
  constant CR_LIMC0_BORROW0_L   : natural := 0;

  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  -- Syllable index capability register $n$
  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  constant CR_SIC3              : std_logic_vector(7 downto 2) := "110000";

  constant CR_SIC3_SYL15CAP_H   : natural := 31;                                -- GENERATED --
  constant CR_SIC3_SYL15CAP_L   : natural := 24;

  constant CR_SIC3_SYL14CAP_H   : natural := 23;
  constant CR_SIC3_SYL14CAP_L   : natural := 16;

  constant CR_SIC3_SYL13CAP_H   : natural := 15;
  constant CR_SIC3_SYL13CAP_L   : natural := 8;

  constant CR_SIC3_SYL12CAP_H   : natural := 7;
  constant CR_SIC3_SYL12CAP_L   : natural := 0;                                 -- GENERATED --

  constant CR_SIC2              : std_logic_vector(7 downto 2) := "110001";

  constant CR_SIC2_SYL11CAP_H   : natural := 31;
  constant CR_SIC2_SYL11CAP_L   : natural := 24;

  constant CR_SIC2_SYL10CAP_H   : natural := 23;
  constant CR_SIC2_SYL10CAP_L   : natural := 16;

  constant CR_SIC2_SYL9CAP_H    : natural := 15;                                -- GENERATED --
  constant CR_SIC2_SYL9CAP_L    : natural := 8;

  constant CR_SIC2_SYL8CAP_H    : natural := 7;
  constant CR_SIC2_SYL8CAP_L    : natural := 0;

  constant CR_SIC1              : std_logic_vector(7 downto 2) := "110010";

  constant CR_SIC1_SYL7CAP_H    : natural := 31;
  constant CR_SIC1_SYL7CAP_L    : natural := 24;
                                                                                -- GENERATED --
  constant CR_SIC1_SYL6CAP_H    : natural := 23;
  constant CR_SIC1_SYL6CAP_L    : natural := 16;

  constant CR_SIC1_SYL5CAP_H    : natural := 15;
  constant CR_SIC1_SYL5CAP_L    : natural := 8;

  constant CR_SIC1_SYL4CAP_H    : natural := 7;
  constant CR_SIC1_SYL4CAP_L    : natural := 0;

  constant CR_SIC0              : std_logic_vector(7 downto 2) := "110011";     -- GENERATED --

  constant CR_SIC0_SYL3CAP_H    : natural := 31;
  constant CR_SIC0_SYL3CAP_L    : natural := 24;

  constant CR_SIC0_SYL2CAP_H    : natural := 23;
  constant CR_SIC0_SYL2CAP_L    : natural := 16;

  constant CR_SIC0_SYL1CAP_H    : natural := 15;
  constant CR_SIC0_SYL1CAP_L    : natural := 8;
                                                                                -- GENERATED --
  constant CR_SIC0_SYL0CAP_H    : natural := 7;
  constant CR_SIC0_SYL0CAP_L    : natural := 0;

  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  -- General purpose register delay register B
  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  constant CR_GPS1              : std_logic_vector(7 downto 2) := "110100";

  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  -- General purpose register delay register A                                  -- GENERATED --
  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  constant CR_GPS0              : std_logic_vector(7 downto 2) := "110101";

  constant CR_GPS0_MEMAR_H      : natural := 27;
  constant CR_GPS0_MEMAR_L      : natural := 24;

  constant CR_GPS0_MEMDC_H      : natural := 23;
  constant CR_GPS0_MEMDC_L      : natural := 20;

  constant CR_GPS0_MEMDR_H      : natural := 19;                                -- GENERATED --
  constant CR_GPS0_MEMDR_L      : natural := 16;

  constant CR_GPS0_MULC_H       : natural := 15;
  constant CR_GPS0_MULC_L       : natural := 12;

  constant CR_GPS0_MULR_H       : natural := 11;
  constant CR_GPS0_MULR_L       : natural := 8;

  constant CR_GPS0_ALUC_H       : natural := 7;
  constant CR_GPS0_ALUC_L       : natural := 4;                                 -- GENERATED --

  constant CR_GPS0_ALUR_H       : natural := 3;
  constant CR_GPS0_ALUR_L       : natural := 0;

  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  -- Special delay register B
  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  constant CR_SPS1              : std_logic_vector(7 downto 2) := "110110";

  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  -- GENERATED --
  -- Special delay register A
  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  constant CR_SPS0              : std_logic_vector(7 downto 2) := "110111";

  constant CR_SPS0_MEMMC_H      : natural := 31;
  constant CR_SPS0_MEMMC_L      : natural := 28;

  constant CR_SPS0_MEMMR_H      : natural := 27;
  constant CR_SPS0_MEMMR_L      : natural := 24;
                                                                                -- GENERATED --
  constant CR_SPS0_MEMDC_H      : natural := 23;
  constant CR_SPS0_MEMDC_L      : natural := 20;

  constant CR_SPS0_MEMDR_H      : natural := 19;
  constant CR_SPS0_MEMDR_L      : natural := 16;

  constant CR_SPS0_BRC_H        : natural := 15;
  constant CR_SPS0_BRC_L        : natural := 12;

  constant CR_SPS0_BRR_H        : natural := 11;                                -- GENERATED --
  constant CR_SPS0_BRR_L        : natural := 8;

  constant CR_SPS0_ALUC_H       : natural := 7;
  constant CR_SPS0_ALUC_L       : natural := 4;

  constant CR_SPS0_ALUR_H       : natural := 3;
  constant CR_SPS0_ALUR_L       : natural := 0;

  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  -- Extension register 2                                                       -- GENERATED --
  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  constant CR_EXT2              : std_logic_vector(7 downto 2) := "111000";

  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  -- Extension register 1
  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  constant CR_EXT1              : std_logic_vector(7 downto 2) := "111001";

  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  -- Extension register 0                                                       -- GENERATED --
  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  constant CR_EXT0              : std_logic_vector(7 downto 2) := "111010";

  constant CR_EXT0_T_H          : natural := 27;
  constant CR_EXT0_T_L          : natural := 27;

  constant CR_EXT0_BRK_H        : natural := 26;
  constant CR_EXT0_BRK_L        : natural := 24;

  constant CR_EXT0_C_H          : natural := 18;                                -- GENERATED --
  constant CR_EXT0_C_L          : natural := 18;

  constant CR_EXT0_I_H          : natural := 17;
  constant CR_EXT0_I_L          : natural := 17;

  constant CR_EXT0_P_H          : natural := 16;
  constant CR_EXT0_P_L          : natural := 16;

  constant CR_EXT0_O_H          : natural := 2;
  constant CR_EXT0_O_L          : natural := 2;                                 -- GENERATED --

  constant CR_EXT0_L_H          : natural := 1;
  constant CR_EXT0_L_L          : natural := 1;

  constant CR_EXT0_F_H          : natural := 0;
  constant CR_EXT0_F_L          : natural := 0;

  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  -- Design-time configuration register
  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  -- GENERATED --
  constant CR_DCFG              : std_logic_vector(7 downto 2) := "111011";

  constant CR_DCFG_BA_H         : natural := 15;
  constant CR_DCFG_BA_L         : natural := 12;

  constant CR_DCFG_NC_H         : natural := 11;
  constant CR_DCFG_NC_L         : natural := 8;

  constant CR_DCFG_NG_H         : natural := 7;
  constant CR_DCFG_NG_L         : natural := 4;                                 -- GENERATED --

  constant CR_DCFG_NL_H         : natural := 3;
  constant CR_DCFG_NL_L         : natural := 0;

  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  -- Core version register 1
  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  constant CR_CVER1             : std_logic_vector(7 downto 2) := "111100";

  constant CR_CVER1_VER_H       : natural := 31;                                -- GENERATED --
  constant CR_CVER1_VER_L       : natural := 24;

  constant CR_CVER1_CTAG0_H     : natural := 23;
  constant CR_CVER1_CTAG0_L     : natural := 16;

  constant CR_CVER1_CTAG1_H     : natural := 15;
  constant CR_CVER1_CTAG1_L     : natural := 8;

  constant CR_CVER1_CTAG2_H     : natural := 7;
  constant CR_CVER1_CTAG2_L     : natural := 0;                                 -- GENERATED --

  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  -- Core version register 0
  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  constant CR_CVER0             : std_logic_vector(7 downto 2) := "111101";

  constant CR_CVER0_CTAG3_H     : natural := 31;
  constant CR_CVER0_CTAG3_L     : natural := 24;

  constant CR_CVER0_CTAG4_H     : natural := 23;                                -- GENERATED --
  constant CR_CVER0_CTAG4_L     : natural := 16;

  constant CR_CVER0_CTAG5_H     : natural := 15;
  constant CR_CVER0_CTAG5_L     : natural := 8;

  constant CR_CVER0_CTAG6_H     : natural := 7;
  constant CR_CVER0_CTAG6_L     : natural := 0;

  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  -- Platform version register 1                                                -- GENERATED --
  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  constant CR_PVER1             : std_logic_vector(7 downto 2) := "111110";

  constant CR_PVER1_COID_H      : natural := 31;
  constant CR_PVER1_COID_L      : natural := 24;

  constant CR_PVER1_PTAG0_H     : natural := 23;
  constant CR_PVER1_PTAG0_L     : natural := 16;

  constant CR_PVER1_PTAG1_H     : natural := 15;                                -- GENERATED --
  constant CR_PVER1_PTAG1_L     : natural := 8;

  constant CR_PVER1_PTAG2_H     : natural := 7;
  constant CR_PVER1_PTAG2_L     : natural := 0;

  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  -- Platform version register 0
  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  constant CR_PVER0             : std_logic_vector(7 downto 2) := "111111";
                                                                                -- GENERATED --
  constant CR_PVER0_PTAG3_H     : natural := 31;
  constant CR_PVER0_PTAG3_L     : natural := 24;

  constant CR_PVER0_PTAG4_H     : natural := 23;
  constant CR_PVER0_PTAG4_L     : natural := 16;

  constant CR_PVER0_PTAG5_H     : natural := 15;
  constant CR_PVER0_PTAG5_L     : natural := 8;

  constant CR_PVER0_PTAG6_H     : natural := 7;                                 -- GENERATED --
  constant CR_PVER0_PTAG6_L     : natural := 0;

  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  -- Main context control register
  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  constant CR_CCR               : std_logic_vector(8 downto 2) := "0000000";

  constant CR_CCR_CAUSE_H       : natural := 31;
  constant CR_CCR_CAUSE_L       : natural := 24;
                                                                                -- GENERATED --
  constant CR_CCR_BRANCH_H      : natural := 23;
  constant CR_CCR_BRANCH_L      : natural := 16;

  constant CR_CCR_K_H           : natural := 9;
  constant CR_CCR_K_L           : natural := 8;

  constant CR_CCR_C_H           : natural := 7;
  constant CR_CCR_C_L           : natural := 6;

  constant CR_CCR_B_H           : natural := 5;                                 -- GENERATED --
  constant CR_CCR_B_L           : natural := 4;

  constant CR_CCR_R_H           : natural := 3;
  constant CR_CCR_R_L           : natural := 2;

  constant CR_CCR_I_H           : natural := 1;
  constant CR_CCR_I_L           : natural := 0;

  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  -- Saved context control register                                             -- GENERATED --
  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  constant CR_SCCR              : std_logic_vector(8 downto 2) := "0000001";

  constant CR_SCCR_ID_H         : natural := 31;
  constant CR_SCCR_ID_L         : natural := 24;

  constant CR_SCCR_K_H          : natural := 9;
  constant CR_SCCR_K_L          : natural := 8;

  constant CR_SCCR_C_H          : natural := 7;                                 -- GENERATED --
  constant CR_SCCR_C_L          : natural := 6;

  constant CR_SCCR_B_H          : natural := 5;
  constant CR_SCCR_B_L          : natural := 4;

  constant CR_SCCR_R_H          : natural := 3;
  constant CR_SCCR_R_L          : natural := 2;

  constant CR_SCCR_I_H          : natural := 1;
  constant CR_SCCR_I_L          : natural := 0;                                 -- GENERATED --

  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  -- Link register
  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  constant CR_LR                : std_logic_vector(8 downto 2) := "0000010";

  constant CR_LR_LR_H           : natural := 31;
  constant CR_LR_LR_L           : natural := 0;

  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  -- GENERATED --
  -- Program counter
  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  constant CR_PC                : std_logic_vector(8 downto 2) := "0000011";

  constant CR_PC_PC_H           : natural := 31;
  constant CR_PC_PC_L           : natural := 0;

  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  -- Trap handler
  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  -- GENERATED --
  constant CR_TH                : std_logic_vector(8 downto 2) := "0000100";

  constant CR_TH_TH_H           : natural := 31;
  constant CR_TH_TH_L           : natural := 0;

  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  -- Panic handler
  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  constant CR_PH                : std_logic_vector(8 downto 2) := "0000101";
                                                                                -- GENERATED --
  constant CR_PH_PH_H           : natural := 31;
  constant CR_PH_PH_L           : natural := 0;

  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  -- Trap point
  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  constant CR_TP                : std_logic_vector(8 downto 2) := "0000110";

  constant CR_TP_TP_H           : natural := 31;
  constant CR_TP_TP_L           : natural := 0;                                 -- GENERATED --

  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  -- Trap argument
  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  constant CR_TA                : std_logic_vector(8 downto 2) := "0000111";

  constant CR_TA_TA_H           : natural := 31;
  constant CR_TA_TA_L           : natural := 0;

  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  -- GENERATED --
  -- Breakpoint $n$
  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  constant CR_BR0               : std_logic_vector(8 downto 2) := "0001000";

  constant CR_BR0_BR0_H         : natural := 31;
  constant CR_BR0_BR0_L         : natural := 0;

  constant CR_BR1               : std_logic_vector(8 downto 2) := "0001001";

  constant CR_BR1_BR1_H         : natural := 31;                                -- GENERATED --
  constant CR_BR1_BR1_L         : natural := 0;

  constant CR_BR2               : std_logic_vector(8 downto 2) := "0001010";

  constant CR_BR2_BR2_H         : natural := 31;
  constant CR_BR2_BR2_L         : natural := 0;

  constant CR_BR3               : std_logic_vector(8 downto 2) := "0001011";

  constant CR_BR3_BR3_H         : natural := 31;                                -- GENERATED --
  constant CR_BR3_BR3_L         : natural := 0;

  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  -- Debug control register 1
  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  constant CR_DCR               : std_logic_vector(8 downto 2) := "0001100";

  constant CR_DCR_D_H           : natural := 31;
  constant CR_DCR_D_L           : natural := 31;
                                                                                -- GENERATED --
  constant CR_DCR_J_H           : natural := 30;
  constant CR_DCR_J_L           : natural := 30;

  constant CR_DCR_I_H           : natural := 28;
  constant CR_DCR_I_L           : natural := 28;

  constant CR_DCR_E_H           : natural := 27;
  constant CR_DCR_E_L           : natural := 27;

  constant CR_DCR_R_H           : natural := 26;                                -- GENERATED --
  constant CR_DCR_R_L           : natural := 26;

  constant CR_DCR_S_H           : natural := 25;
  constant CR_DCR_S_L           : natural := 25;

  constant CR_DCR_B_H           : natural := 24;
  constant CR_DCR_B_L           : natural := 24;

  constant CR_DCR_CAUSE_H       : natural := 23;
  constant CR_DCR_CAUSE_L       : natural := 16;                                -- GENERATED --

  constant CR_DCR_BR3_H         : natural := 13;
  constant CR_DCR_BR3_L         : natural := 12;

  constant CR_DCR_BR2_H         : natural := 9;
  constant CR_DCR_BR2_L         : natural := 8;

  constant CR_DCR_BR1_H         : natural := 5;
  constant CR_DCR_BR1_L         : natural := 4;
                                                                                -- GENERATED --
  constant CR_DCR_BR0_H         : natural := 1;
  constant CR_DCR_BR0_L         : natural := 0;

  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  -- Debug control register 2
  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  constant CR_DCR2              : std_logic_vector(8 downto 2) := "0001101";

  constant CR_DCR2_RESULT_H     : natural := 31;
  constant CR_DCR2_RESULT_L     : natural := 24;                                -- GENERATED --

  constant CR_DCR2_U_H          : natural := 15;
  constant CR_DCR2_U_L          : natural := 15;

  constant CR_DCR2_N_H          : natural := 14;
  constant CR_DCR2_N_L          : natural := 14;

  constant CR_DCR2_S_H          : natural := 13;
  constant CR_DCR2_S_L          : natural := 13;
                                                                                -- GENERATED --
  constant CR_DCR2_D_H          : natural := 12;
  constant CR_DCR2_D_L          : natural := 12;

  constant CR_DCR2_J_H          : natural := 11;
  constant CR_DCR2_J_L          : natural := 11;

  constant CR_DCR2_F_H          : natural := 8;
  constant CR_DCR2_F_L          : natural := 8;

  constant CR_DCR2_T_H          : natural := 7;                                 -- GENERATED --
  constant CR_DCR2_T_L          : natural := 7;

  constant CR_DCR2_M_H          : natural := 6;
  constant CR_DCR2_M_L          : natural := 6;

  constant CR_DCR2_R_H          : natural := 5;
  constant CR_DCR2_R_L          : natural := 5;

  constant CR_DCR2_C_H          : natural := 4;
  constant CR_DCR2_C_L          : natural := 4;                                 -- GENERATED --

  constant CR_DCR2_I_H          : natural := 3;
  constant CR_DCR2_I_L          : natural := 3;

  constant CR_DCR2_E_H          : natural := 0;
  constant CR_DCR2_E_L          : natural := 0;

  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  -- Context reconfiguration request register
  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  -- GENERATED --
  constant CR_CRR               : std_logic_vector(8 downto 2) := "0010000";

  constant CR_CRR_CRR_H         : natural := 31;
  constant CR_CRR_CRR_L         : natural := 0;

  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  -- Wakeup configuration
  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  constant CR_WCFG              : std_logic_vector(8 downto 2) := "0010010";
                                                                                -- GENERATED --
  constant CR_WCFG_WCFG_H       : natural := 31;
  constant CR_WCFG_WCFG_L       : natural := 0;

  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  -- Sleep and wake-up control register
  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  constant CR_SAWC              : std_logic_vector(8 downto 2) := "0010011";

  constant CR_SAWC_RUN_H        : natural := 7;
  constant CR_SAWC_RUN_L        : natural := 1;                                 -- GENERATED --

  constant CR_SAWC_S_H          : natural := 0;
  constant CR_SAWC_S_L          : natural := 0;

  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  -- Scratchpad register $n$
  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  constant CR_SCRP1             : std_logic_vector(8 downto 2) := "0010100";

  constant CR_SCRP1_SCRP1_H     : natural := 31;                                -- GENERATED --
  constant CR_SCRP1_SCRP1_L     : natural := 0;

  constant CR_SCRP2             : std_logic_vector(8 downto 2) := "0010101";

  constant CR_SCRP2_SCRP2_H     : natural := 31;
  constant CR_SCRP2_SCRP2_L     : natural := 0;

  constant CR_SCRP3             : std_logic_vector(8 downto 2) := "0010110";

  constant CR_SCRP3_SCRP3_H     : natural := 31;                                -- GENERATED --
  constant CR_SCRP3_SCRP3_L     : natural := 0;

  constant CR_SCRP4             : std_logic_vector(8 downto 2) := "0010111";

  constant CR_SCRP4_SCRP4_H     : natural := 31;
  constant CR_SCRP4_SCRP4_L     : natural := 0;

  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  -- Requested software context
  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  -- GENERATED --
  constant CR_RSC               : std_logic_vector(8 downto 2) := "0011000";

  constant CR_RSC_RSC_H         : natural := 31;
  constant CR_RSC_RSC_L         : natural := 0;

  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  -- Current software context
  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  constant CR_CSC               : std_logic_vector(8 downto 2) := "0011001";
                                                                                -- GENERATED --
  constant CR_CSC_CSC_H         : natural := 31;
  constant CR_CSC_CSC_L         : natural := 0;

  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  -- Requested swctxt on hwctxt $n$
  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  constant CR_RSC1              : std_logic_vector(8 downto 2) := "0011010";

  constant CR_RSC1_RSC1_H       : natural := 31;
  constant CR_RSC1_RSC1_L       : natural := 0;                                 -- GENERATED --

  constant CR_RSC2              : std_logic_vector(8 downto 2) := "0011100";

  constant CR_RSC2_RSC2_H       : natural := 31;
  constant CR_RSC2_RSC2_L       : natural := 0;

  constant CR_RSC3              : std_logic_vector(8 downto 2) := "0011110";

  constant CR_RSC3_RSC3_H       : natural := 31;
  constant CR_RSC3_RSC3_L       : natural := 0;                                 -- GENERATED --

  constant CR_RSC4              : std_logic_vector(8 downto 2) := "0100000";

  constant CR_RSC4_RSC4_H       : natural := 31;
  constant CR_RSC4_RSC4_L       : natural := 0;

  constant CR_RSC5              : std_logic_vector(8 downto 2) := "0100010";

  constant CR_RSC5_RSC5_H       : natural := 31;
  constant CR_RSC5_RSC5_L       : natural := 0;                                 -- GENERATED --

  constant CR_RSC6              : std_logic_vector(8 downto 2) := "0100100";

  constant CR_RSC6_RSC6_H       : natural := 31;
  constant CR_RSC6_RSC6_L       : natural := 0;

  constant CR_RSC7              : std_logic_vector(8 downto 2) := "0100110";

  constant CR_RSC7_RSC7_H       : natural := 31;
  constant CR_RSC7_RSC7_L       : natural := 0;                                 -- GENERATED --

  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  -- Current swctxt on hwctxt $n$
  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  constant CR_CSC1              : std_logic_vector(8 downto 2) := "0011011";

  constant CR_CSC1_CSC1_H       : natural := 31;
  constant CR_CSC1_CSC1_L       : natural := 0;

  constant CR_CSC2              : std_logic_vector(8 downto 2) := "0011101";    -- GENERATED --

  constant CR_CSC2_CSC2_H       : natural := 31;
  constant CR_CSC2_CSC2_L       : natural := 0;

  constant CR_CSC3              : std_logic_vector(8 downto 2) := "0011111";

  constant CR_CSC3_CSC3_H       : natural := 31;
  constant CR_CSC3_CSC3_L       : natural := 0;

  constant CR_CSC4              : std_logic_vector(8 downto 2) := "0100001";    -- GENERATED --

  constant CR_CSC4_CSC4_H       : natural := 31;
  constant CR_CSC4_CSC4_L       : natural := 0;

  constant CR_CSC5              : std_logic_vector(8 downto 2) := "0100011";

  constant CR_CSC5_CSC5_H       : natural := 31;
  constant CR_CSC5_CSC5_L       : natural := 0;

  constant CR_CSC6              : std_logic_vector(8 downto 2) := "0100101";    -- GENERATED --

  constant CR_CSC6_CSC6_H       : natural := 31;
  constant CR_CSC6_CSC6_L       : natural := 0;

  constant CR_CSC7              : std_logic_vector(8 downto 2) := "0100111";

  constant CR_CSC7_CSC7_H       : natural := 31;
  constant CR_CSC7_CSC7_L       : natural := 0;

  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  -- GENERATED --
  -- Cycle counter
  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  constant CR_CYC               : std_logic_vector(8 downto 2) := "1000000";

  constant CR_CYC_CYC_H         : natural := 31;
  constant CR_CYC_CYC_L         : natural := 0;

  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  -- Stall cycle counter
  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  -- GENERATED --
  constant CR_STALL             : std_logic_vector(8 downto 2) := "1000010";

  constant CR_STALL_STALL_H     : natural := 31;
  constant CR_STALL_STALL_L     : natural := 0;

  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  -- Committed bundle counter
  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  constant CR_BUN               : std_logic_vector(8 downto 2) := "1000100";
                                                                                -- GENERATED --
  constant CR_BUN_BUN_H         : natural := 31;
  constant CR_BUN_BUN_L         : natural := 0;

  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  -- Committed syllable counter
  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  constant CR_SYL               : std_logic_vector(8 downto 2) := "1000110";

  constant CR_SYL_SYL_H         : natural := 31;
  constant CR_SYL_SYL_L         : natural := 0;                                 -- GENERATED --

  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  -- Committed NOP counter
  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  constant CR_NOP               : std_logic_vector(8 downto 2) := "1001000";

  constant CR_NOP_NOP_H         : natural := 31;
  constant CR_NOP_NOP_L         : natural := 0;

  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  -- GENERATED --
  -- Instruction cache access counter
  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  constant CR_IACC              : std_logic_vector(8 downto 2) := "1001010";

  constant CR_IACC_IACC_H       : natural := 31;
  constant CR_IACC_IACC_L       : natural := 0;

  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  -- Instruction cache miss counter
  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  -- GENERATED --
  constant CR_IMISS             : std_logic_vector(8 downto 2) := "1001100";

  constant CR_IMISS_IMISS_H     : natural := 31;
  constant CR_IMISS_IMISS_L     : natural := 0;

  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  -- Data cache read access counter
  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  constant CR_DRACC             : std_logic_vector(8 downto 2) := "1001110";
                                                                                -- GENERATED --
  constant CR_DRACC_DRACC_H     : natural := 31;
  constant CR_DRACC_DRACC_L     : natural := 0;

  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  -- Data cache read miss counter
  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  constant CR_DRMISS            : std_logic_vector(8 downto 2) := "1010000";

  constant CR_DRMISS_DRMISS_H   : natural := 31;
  constant CR_DRMISS_DRMISS_L   : natural := 0;                                 -- GENERATED --

  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  -- Data cache write access counter
  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  constant CR_DWACC             : std_logic_vector(8 downto 2) := "1010010";

  constant CR_DWACC_DWACC_H     : natural := 31;
  constant CR_DWACC_DWACC_L     : natural := 0;

  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  -- GENERATED --
  -- Data cache write miss counter
  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  constant CR_DWMISS            : std_logic_vector(8 downto 2) := "1010100";

  constant CR_DWMISS_DWMISS_H   : natural := 31;
  constant CR_DWMISS_DWMISS_L   : natural := 0;

  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  -- Data cache bypass counter
  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  -- GENERATED --
  constant CR_DBYPASS           : std_logic_vector(8 downto 2) := "1010110";

  constant CR_DBYPASS_DBYPASS_H : natural := 31;
  constant CR_DBYPASS_DBYPASS_L : natural := 0;

  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  -- Data cache write buffer counter
  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  constant CR_DWBUF             : std_logic_vector(8 downto 2) := "1011000";
                                                                                -- GENERATED --
  constant CR_DWBUF_DWBUF_H     : natural := 31;
  constant CR_DWBUF_DWBUF_L     : natural := 0;

end core_ctrlRegs_pkg;

package body core_ctrlRegs_pkg is
end core_ctrlRegs_pkg;
