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
use work.rvex_pipeline_pkg.all;
use work.rvex_trap_pkg.all;
use work.rvex_opcode_pkg.all;
use work.rvex_opcodeMemory_pkg.all;

--=============================================================================
-- This entity contains the optional hardware breakpoint unit for a pipelane.
-------------------------------------------------------------------------------
entity rvex_brku is
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
    
    -- Active high stall input for the pipeline.
    stall                       : in  std_logic;
    
    ---------------------------------------------------------------------------
    -- Pipelane interface
    ---------------------------------------------------------------------------
    -- When high, breakpoints should be ignored this cycle.
    pl2brku_ignoreBreakpoint    : in  std_logic_vector(S_BRK to S_BRK);
    
    -- Opcode.
    pl2brku_opcode              : in  rvex_opcode_array(S_BRK to S_BRK);
    
    -- Address operand for the memory for access/write breakpoints.
    pl2brku_opAddr              : in  rvex_address_array(S_BRK to S_BRK);
    
    -- Current (bundle) PC for instruction breakpoints.
    pl2brku_PC_bundle           : in  rvex_address_array(S_BRK to S_BRK);
    
    -- (Debug) trap output.
    brku2pl_trap                : out trap_info_array(S_BRK+L_BRK to S_BRK+L_BRK);
    
    ---------------------------------------------------------------------------
    -- Debugging control signals
    ---------------------------------------------------------------------------
    -- Current breakpoint information.
    cxplif2brku_breakpoints     : in  cxreg2pl_breakpoint_info_array(S_BRK to S_BRK);
    
    -- Current value of the stepping flag in the debug control register. When
    -- high, a step trap must be triggered if there is no other trap and
    -- breakpoints are enabled.
    cxplif2brku_stepping        : in  cxreg2pl_breakpoint_info_array(S_BRK to S_BRK)
    
  );
end rvex_brku;

--=============================================================================
architecture Behavioral of rvex_brku is
--=============================================================================
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -- Make sure that the pipeline configuration correctly specifies that the
  -- breakpoint unit is combinatorial.
  -- pragma translate_off
  process is
  begin
    if L_BRK /= 0 then
      report "Pipeline configuration: breakpoint unit latency (L_BRK) must be set to 0." severity failure;
    end if;
    wait;
  end process;
  -- pragma translate_on
  
end Behavioral;

