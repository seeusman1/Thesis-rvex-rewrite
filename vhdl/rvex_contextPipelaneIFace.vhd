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
use work.rvex_trap_pkg.all;

--=============================================================================
-- This block interfaces between the pipelanes (the branch units in particular)
-- and the context-specific registers other than the general purpose register
-- file.
-------------------------------------------------------------------------------
entity rvex_contextPipelaneIFace is
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
    
    -- Active high stall input for each pipelane group.
    stall                       : in  std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -----------------------------------------------------------------------------
    -- Decoded configuration signals
    -----------------------------------------------------------------------------
    -- Diagonal block matrix of n*n size, where n is the number of pipelane
    -- groups. C_i,j is high when pipelane groups i and j are coupled/share a
    -- context, or low when they don't.
    cfg2any_coupled             : in  std_logic_vector(4**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Matrix specifying connections between context and lane group. Indexing is
    -- done using i = laneGroup*numContexts + context.
    cfg2any_contextMap          : in  std_logic_vector(2**CFG.numLaneGroupsLog2*2**CFG.numContextsLog2-1 downto 0);
    
    -- Last pipelane group associated with each context.
    cfg2any_lastGroupForCtxt    : in  rvex_3bit_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    ---------------------------------------------------------------------------
    -- Pipelane interface
    ---------------------------------------------------------------------------
    -- External interrupt request signal, active high. This is already masked
    -- by the interrupt enable bit in the control register.
    cxplif2pl_irq               : out std_logic_vector(2**CFG.numLanesLog2-1 downto 0);
    
    -- External interrupt acknowledge signal, active high.
    pl2cxplif_irqAck            : in  std_logic_vector(2**CFG.numLanesLog2-1 downto 0);
    
    -- Active high run signal. This is the combined run signal from the
    -- external run input and the BRK flag in the debug control register.
    cxplif2pl_run               : out std_logic_vector(2**CFG.numLanesLog2-1 downto 0);
    
    -- Active high idle output.
    pl2cxplif_idle              : in  std_logic_vector(2**CFG.numLanesLog2-1 downto 0);
    
    -- Branch/link register read ports.
    cxplif2pl_brLinkReadPort    : out cxreg2pl_readPort_array(2**CFG.numLanesLog2-1 downto 0);
    
    -- Branch/link register write ports.
    pl2cxplif_brLinkWritePort   : in  pl2cxreg_writePort_array(2**CFG.numLanesLog2-1 downto 0);
    
    -- Next value for the PC register, only valid for master lanes with a
    -- branch unit.
    br2cxplif_PC                : in  rvex_address_array(2**CFG.numLanesLog2-1 downto 0);
    
    -- PC for the current bundle for each lane, as stored in the context PC
    -- register.
    cxplif2pl_bundlePC          : out rvex_address_array(2**CFG.numLanesLog2-1 downto 0);
    
    -- Exact PC for the syllable for each lane.
    cxplif2pl_lanePC            : out rvex_address_array(2**CFG.numLanesLog2-1 downto 0);
    
    -- When high, the next PC should be set to the current value of the PC
    -- register unconditionally. This is high when the debug bus wrote to the
    -- PC register, and after a (context) reset to ensure that execution starts
    -- at 0.
    cxplif2pl_overridePC        : out std_logic_vector(2**CFG.numLanesLog2-1 downto 0);
    
    -- Current trap handler. When the application has marked that it is not
    -- currently capable of accepting a trap, this is set to the panic handler
    -- register instead.
    cxplif2pl_trapHandler       : out rvex_address_array(2**CFG.numLanesLog2-1 downto 0);
    
    -- Trap information for the trap currently handled by the branch unit, if
    -- any. We can commit this in the branch stage already, because it is
    -- guaranteed that there is no instruction valid in S_MEM while a trap is
    -- entered.
    pl2cxplif_trapInfo          : in  trap_info_array(2**CFG.numLanesLog2-1 downto 0);
    pl2cxplif_trapPoint         : in  trap_info_array(2**CFG.numLanesLog2-1 downto 0);
    
    -- Commands the register logic to reset the trap cause to 0 and restore
    -- the control registers which were saved upon trap entry.
    pl2cxplif_rfi               : in  std_logic_vector(2**CFG.numLanesLog2-1 downto 0);
    
    -- When this (debug) trap is active, BRK must be set and the external debug
    -- cause value should be set to the trap cause.
    br2cxplif_brk               : in  trap_info_array(2**CFG.numLanesLog2-1 downto 0);
    
    -- Current breakpoint information.
    cxplif2brku_breakpoints     : out cxreg2pl_breakpoint_info_array(2**CFG.numLanesLog2-1 downto 0);
    
    -- When high, breakpoints should be disabled for this instruction.
    cxplif2pl_ignoreBreakpoint  : out std_logic_vector(2**CFG.numLanesLog2-1 downto 0);
    
    ---------------------------------------------------------------------------
    -- Run control interface
    ---------------------------------------------------------------------------
    -- External interrupt request signal for each context, active high.
    rctrl2cxplif_irq            : in  std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
    
    -- External interrupt acknowledge signal for each context, active high.
    -- Goes high for exactly one clkEn'abled cycle.
    cxplif2rctrl_irqAck         : out std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
    
    -- Active high run signal.
    rctrl2cxplif_run            : in  std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
    
    -- Active high idle output.
    cxplif2rctrl_idle           : out std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
    
    ---------------------------------------------------------------------------
    -- Context register interface
    ---------------------------------------------------------------------------
    -- Branch/link register read port for each context.
    cxreg2cxplif_brLinkReadPort : in  cxreg2pl_readPort_array(2**CFG.numContextsLog2-1 downto 0);
    
    -- Branch/link register write port for each context.
    cxplif2cxreg_brLinkWritePort: out pl2cxreg_writePort_array(2**CFG.numContextsLog2-1 downto 0);
    
    -- Next and current value for the PC register for each context.
    cxplif2cxreg_PC             : out rvex_address_array(2**CFG.numContextsLog2-1 downto 0);
    cxreg2cxplif_PC             : in  rvex_address_array(2**CFG.numContextsLog2-1 downto 0);
    
    -- When high, the next PC should be set to the current value of the PC
    -- register unconditionally. This is high when the debug bus wrote to the
    -- PC register, and after a (context) reset to ensure that execution starts
    -- at 0.
    cxreg2cxplif_overridePC     : in  std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
    
    -- Current trap handler for each context. When the application has marked
    -- that it is not currently capable of accepting a trap, this is set to the
    -- panic handler register instead.
    cxreg2cxplif_trapHandler    : in  rvex_address_array(2**CFG.numContextsLog2-1 downto 0);
    
    -- Trap information for the trap currently handled by the branch unit
    -- associated with each context, if any, or no trap for contexts which do
    -- not currently have a branch unit assigned to them.
    cxplif2cxreg_trapInfo       : out trap_info_array(2**CFG.numContextsLog2-1 downto 0);
    cxplif2cxreg_trapPoint      : out trap_info_array(2**CFG.numContextsLog2-1 downto 0);
    
    -- Commands the register logic to reset the trap cause to 0 and restore
    -- the control registers which were saved upon trap entry.
    cxplif2cxreg_rfi            : out std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
    
    -- When this (debug) trap is active, BRK must be set and the external debug
    -- cause value should be set to the trap cause.
    cxplif2cxreg_brk            : out trap_info_array(2**CFG.numContextsLog2-1 downto 0);
    
    -- Current value of the BRK bit in the debug control register.
    cxreg2cxplif_brk            : in  std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
    
    -- Current breakpoint information for each context.
    cxreg2cxplif_breakpoints    : in  cxreg2pl_breakpoint_info_array(2**CFG.numContextsLog2-1 downto 0);
    
    -- When high, breakpoints should be disabled for this instruction.
    cxreg2cxplif_ignoreBreakpoint: in  std_logic_vector(2**CFG.numContextsLog2-1 downto 0)
    
  );
end rvex_contextPipelaneIFace;

--=============================================================================
architecture Behavioral of rvex_contextPipelaneIFace is
--=============================================================================
  
--=============================================================================
begin -- architecture
--=============================================================================
  
end Behavioral;

