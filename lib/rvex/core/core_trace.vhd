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
use rvex.core_pkg.all;
use rvex.core_intIface_pkg.all;

--=============================================================================
-- This entity contains the optional trace control unit. This unit will
-- compress trace information selected in the context control registers into a
-- bytestream and will ensure that the core is stalled while the trace data is
-- being outputted.
-------------------------------------------------------------------------------
entity core_trace is
--=============================================================================
  generic (
    
    -- Configuration.
    CFG                         : rvex_generic_config_type
    
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
    
    -- Combined stall input.
    stallIn                     : in  std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Stall output. When high, the entire core should stall.
    stallOut                    : out std_logic;
    
    -----------------------------------------------------------------------------
    -- Decoded configuration signals
    -----------------------------------------------------------------------------
    -- Specifies the context associated with the indexed pipelane group.
    cfg2any_context             : in  rvex_3bit_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Specifies whether the indexed pipeline group is active.
    cfg2any_active              : in  std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    ---------------------------------------------------------------------------
    -- Trace control
    ---------------------------------------------------------------------------
    -- Whether tracing should be enabled or not for each context. Active high.
    cxreg2trace_enable          : in  std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
    
    -- Whether trap information should be traced. Active high.
    cxreg2trace_trapEn          : in  std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
    
    -- Whether memory operations should be traced. Active high.
    cxreg2trace_memEn           : in  std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
    
    -- Whether register writes should be traced. Active high.
    cxreg2trace_regEn           : in  std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
    
    ---------------------------------------------------------------------------
    -- Trace raw data input
    ---------------------------------------------------------------------------
    -- Inputs from the pipelanes.
    pl2trace_data               : in  pl2trace_data_array(2**CFG.numLanesLog2-1 downto 0);
    
    ---------------------------------------------------------------------------
    -- Trace output
    ---------------------------------------------------------------------------
    -- When high, data is valid and should be registered.
    trace2trsink_push           : out std_logic;
    
    -- Trace data signal. Valid when push is high.
    trace2trsink_data           : out rvex_byte_type;
    
    -- When high, this is the last byte of this trace packet. This has the same
    -- timing as the data signal.
    trace2trsink_end            : out std_logic;
    
    -- When high while push is high, the trace unit is stalled. While stalled,
    -- push will stay high and data and end will remain stable.
    trsink2trace_busy           : in  std_logic
    
  );
end core_trace;

--=============================================================================
architecture Behavioral of core_trace is
--=============================================================================
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -- TODO
  stallOut            <= '0';
  trace2trsink_push   <= '0';
  trace2trsink_data   <= (others => '0');
  trace2trsink_end    <= '0';
  
  -- *** Header data ***
  --
  -- FLAGS:
  --  - Bit 7: Trap fields valid
  --  - Bit 6: Memory operation fields valid
  --  - Bit 5: General purpose/link register write fields valid
  --  - Bit 4: Branch register field valid
  --  - Bit 3: Reserved for extended flag field validity, should be 0
  --  - Bit 2..0: The context being logged
  --
  -- PC0:
  --  - Bit 7..2: PC(7..2)
  --  - Bit 1..0: number of PC bytes valid
  --
  -- [PC1] if PC0(1..0) >= 1:
  -- [PC2] if PC0(1..0) >= 2:
  -- [PC3] if PC0(1..0) >= 3:
  --  - Bit 7..0: PC
  --
  -- *** Trap fields if FLAGS(7) = 1 ***
  --
  -- [TC]:
  --  - Bit 7..0: trap cause
  --
  -- [TA0] if TC != 0:
  -- [TA1] if TC != 0:
  -- [TA2] if TC != 0:
  -- [TA3] if TC != 0:
  --  - Bit 7..0: trap argument
  --
  -- *** Memory operation fields if FLAGS(6) = 1 or previous MEMFLAGS(7) = 1 ***
  --
  -- [MEMFLAGS]:
  --  - Bit 7: repeat; another memory operation field section will follow if 1.
  --  - Bit 3..0: write mask + validity
  -- 
  -- [MEMADDR0]:
  -- [MEMADDR1]:
  -- [MEMADDR2]:
  -- [MEMADDR3]:
  --  - Bit 7..0: memory address
  --
  -- [MEMDATA0] if MEMFLAGS(0) = 1:
  -- [MEMDATA1] if MEMFLAGS(1) = 1:
  -- [MEMDATA2] if MEMFLAGS(2) = 1:
  -- [MEMDATA3] if MEMFLAGS(3) = 1:
  --  - Bit 7..0: memory data
  --
  -- *** General purpose register write fields if FLAGS(5) = 1 or previous GPWFLAGS(7) = 1 ***
  --
  -- [GPWFLAGS]
  --  - Bit 7: repeat; another general purpose register write field section will follow if 1.
  --  - Bit 5..0: register index; 0 is used for link register
  -- 
  -- [GPWDATA0]:
  -- [GPWDATA1]:
  -- [GPWDATA2]:
  -- [GPWDATA3]:
  --  - Bit 7..0: gpreg/link data
  --
  -- *** Branch register field if FLAGS(4) = 1 ***
  --
  -- [BRWMASK]
  --  - Bit 7..0: 1 if indexed branch register is written, 0 if not
  --
  -- [BRWDATA]
  --  - Bit 7..0: new value for the indexed branch register
  
end Behavioral;

