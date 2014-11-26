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
use work.rvex_opcodeBranch_pkg.all;

--=============================================================================
-- This entity contains the optional branch unit for a pipelane.
-------------------------------------------------------------------------------
entity rvex_br is
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
    -- Next operation outputs
    ---------------------------------------------------------------------------
    -- The PC for the current instruction, as chosen by the active branch unit
    -- within the group. The PC is distributed by the context-pipelane
    -- interface block so all coupled pipelanes have it.
    br2imem_PC                  : out rvex_address_array(S_IF to S_IF);
    br2cxplif_PC                : out rvex_address_array(S_IF to S_IF);
    
    -- Whether an instruction fetch is being initiated or not.
    br2imem_fetch               : out std_logic_vector(S_IF to S_IF);
    br2cxplif_limmValid         : out std_logic_vector(S_IF to S_IF);
    
    -- Whether the next instruction is valid and should be committed or not.
    br2cxplif_valid             : out std_logic_vector(S_IF to S_IF);
    
    -- Whether breakpoints are valid in the next instruction or not. This is
    -- low when returning from a debug interrupt.
    br2cxplif_brkValid          : out std_logic_vector(S_IF to S_IF);
    
    -- Whether or not pipeline stages S_IF+1 to S_BR-1 should be invalidated
    -- due to a branch or the core stopping.
    br2imem_cancel              : out std_logic_vector(S_IF+L_IF to S_IF+L_IF);
    br2cxplif_invalUntilBR      : out std_logic_vector(S_BR to S_BR);
    
    ---------------------------------------------------------------------------
    -- Run control signals
    ---------------------------------------------------------------------------
    -- Run bit for this pipelane from the configuration logic.
    cfg2br_run                  : in  std_logic;
    
    -- Active high run signal. This is the combined run signal from the
    -- external run input and the BRK flag in the debug control register.
    cxplif2br_run               : in  std_logic;
    
    ---------------------------------------------------------------------------
    -- Branch control signals from and to pipelane
    ---------------------------------------------------------------------------
    -- PC+1 input for normal program flow.
    pl2br_PC_plusOne_IFP1       : in  rvex_address_array(S_IF+1 to S_IF+1);
    
    -- PC+1 input from branch stage for STOP instruction, which should stop
    -- execution and set the resumption PC to the instruction following the
    -- stop.
    pl2br_PC_plusOne_BR         : in  rvex_address_array(S_BR to S_BR);
    
    -- Link register branch target for RETURN, ICALL and IGOTO.
    pl2br_brTgtLink             : in  rvex_address_array(S_BR to S_BR);
    
    -- PC-relative branch target for other branch instructions.
    pl2br_brTgtRel              : in  rvex_address_array(S_BR to S_BR);
    
    -- Branch operand for conditional branches.
    pl2br_brOp                  : in  std_logic_vector(S_BR to S_BR);
    
    -- Whether a trap is pending in the pipeline somewhere.
    pl2br_trapPending           : in  std_logic_vector(S_BR to S_BR);
    
    -- Trap which should be handled by this instruction, if any, along with
    -- the trap point, and the address of the handler as it was while the
    -- instruction with the trap was being executed.
    pl2br_trapToHandleInfo      : in  trap_info_array(S_BR to S_BR);
    pl2br_trapToHandlePoint     : in  rvex_address_array(S_BR to S_BR);
    pl2br_trapToHandleHandler   : in  rvex_address_array(S_BR to S_BR);
    
    -- Commands the register logic to reset the trap cause to 0 and restore
    -- the control registers which were saved upon trap entry. This is sent to
    -- the pipelane first to delay it until S_MEM to keep the RFI command for
    -- the control registers synchronized with most other register accesses.
    br2pl_rfi                   : out std_logic_vector(S_BR to S_BR);
    
    -- Trap output for unaligned branches.
    br2pl_trap                  : out trap_info_array(S_BR to S_BR);
    
    ---------------------------------------------------------------------------
    -- Branch control signals from and to context registers
    ---------------------------------------------------------------------------
    -- The current value of the context PC register and associated override
    -- flag. When the override flag is set, the branch unit should behave as if
    -- there was a branch to the value in contextPC. This happens when the
    -- debug bus writes to the PC register.
    cxplif2br_contextPC         : in  rvex_address_array(S_IF+1 to S_IF+1);
    cxplif2br_overridePC        : in  std_logic_vector(S_IF+1 to S_IF+1);
    
    -- Trap information for the trap currently handled by the branch unit, if
    -- any. We can commit this in the branch stage already, because it is
    -- guaranteed that there is no instruction valid in S_MEM while a trap is
    -- entered.
    br2cxplif_trapInfo          : out trap_info_array(S_BR to S_BR);
    br2cxplif_trapPoint         : out rvex_address_array(S_BR to S_BR);
    
    -- Debug trap information for externally handled breakpoints. When the
    -- enable bit in the trap information record is high, the BRK bit should
    -- be set to halt the core and the trap information should be stored for
    -- the external debugger.
    br2cxplif_exDbgTrapInfo     : out trap_info_array(S_BR to S_BR);
    
    -- Stop signal, goes high when the branch unit is executing a stop
    -- instruction. When high, the done bit is set and the BRK bit is set to
    -- halt the core.
    br2cxplif_stop              : out std_logic_vector(S_BR to S_BR);
    
    -- Trap handler return address. This is just connected to the current value
    -- of the trap point register.
    cxplif2br_trapReturn        : in  rvex_address_array(S_BR to S_BR);
    
    -- Whether debug traps are to be handled normally or by halting execution
    -- for debugging through the external bebug bus.
    cxplif2br_extDebug          : in  std_logic_vector(S_BR to S_BR)
    
  );
end rvex_br;

--=============================================================================
architecture Behavioral of rvex_br is
--=============================================================================
  
  -- Combined run flag. run_r is delayes by one cycle so the first instruction
  -- after a halt can be detected.
  signal run, run_r             : std_logic;
  
  
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- Generate internal control signals
  -----------------------------------------------------------------------------
  
  -- Combine the incoming run signals.
  run <= cfg2br_run and cxplif2br_run;
  
  -- Generate the register used to delay run with.
  run_reg_gen: process (clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        run_r <= '0';
      elsif clkEn = '1' and stall = '0' then
        run_r <= run;
      end if;
    end if;
  end process;
  
  
end Behavioral;

