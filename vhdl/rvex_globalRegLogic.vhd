-- r-VEX processor
-- Copyright (C) 2008-2014 by TU Delft.
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

-- 6. r-VEX was developed by Stephan Wong, Thijs van As, Fakhar Anjam, Roel Seedorf,
-- Anthony Brandon. r-VEX is currently maintained by TU Delft (J.S.S.M.Wong@tudelft.nl).

-- Copyright (C) 2008-2014 by TU Delft.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.rvex_pkg.all;
use work.rvex_intIface_pkg.all;

--=============================================================================
-- This entity contains the specifications and logic for the control registers
-- which are shared between all cores. They are read only to the core, but the
-- debug bus can write to them (depending on specification).
-------------------------------------------------------------------------------
entity rvex_globalRegLogic is
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
    
    ---------------------------------------------------------------------------
    -- Interface with the control registers and bus logic
    ---------------------------------------------------------------------------
    -- Interface for the control registers.
    gbreg2creg                  : out gbreg2creg_type;
    creg2gbreg                  : in  creg2gbreg_type;
    
    -- Context selection for the debug bus.
    gbreg2creg_context          : out std_logic_vector(CFG.numContextsLog2-1 downto 0);
    
    -- Bank selection bit for general purpose register access from the debug
    -- bus.
    gbreg2creg_gpregBank        : out std_logic;
    
    ---------------------------------------------------------------------------
    -- Interface with configuration logic
    ---------------------------------------------------------------------------
    -- Each nibble in the data word corresponds to a pipelane group, of which
    -- bit 3 specifies whether the pipelane group should be disabled (high) or
    -- enabled (low) and, if low, bit 2..0 specify the context it should run
    -- on. Bits which are not supported by the core (as specified in the CFG
    -- generic) should be written zero or the request will be ignored (as
    -- specified by the error flag in the global control register file).
    -- The enable signal is active high, and is valid one clkEn'd cycle BEFORE
    -- the data vector is. This is because the enable signal is connected to
    -- the bus write enable signal for the register and the data is connected
    -- to the register output.
    gbreg2cfg_requestData_r     : out rvex_data_type;
    gbreg2cfg_requestEnable     : out std_logic;
    
    -- Current configuration, using the same encoding as the request data.
    cfg2gbreg_currentCfg        : in  rvex_data_type;
    
    -- Configuration busy signal. When set, new configuration requests are not
    -- accepted.
    cfg2gbreg_busy              : in  std_logic;
    
    -- Configuration error signal. This is set when the last configuration
    -- request was erroneous.
    cfg2gbreg_error             : in  std_logic;
    
    -- When reconfiguration is requested, this field is set to the index of
    -- the context which requested the configuration, or all ones if the source
    -- was the debug bus.
    cfg2gbreg_requesterID       : in  std_logic_vector(3 downto 0);
    
    ---------------------------------------------------------------------------
    -- Interface with memory
    ---------------------------------------------------------------------------
    -- Affinity signal from the memory.
    imem2gbreg_affinity         : in  std_logic_vector(2**CFG.numLaneGroupsLog2*CFG.numLaneGroupsLog2-1 downto 0)
    
  );
end rvex_globalRegLogic;

--=============================================================================
architecture Behavioral of rvex_globalRegLogic is
--=============================================================================
  
--=============================================================================
begin -- architecture
--=============================================================================
  
end Behavioral;

