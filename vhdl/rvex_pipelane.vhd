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
use work.rvex_opcodeDatapath_pkg.all;

--=============================================================================
-- This entity contains the pipeline logic and instantiates the functional
-- units for a single lane.
-------------------------------------------------------------------------------
entity rvex_pipelane is
--=============================================================================
  generic (
    
    ---------------------------------------------------------------------------
    -- Configuration
    ---------------------------------------------------------------------------
    -- Determines whether this pipelane has a multiplier or not.
    HAS_MUL                     : boolean;
    
    -- Determines whether this pipelane has a memory unit or not.
    HAS_MEM                     : boolean;
    
    -- Determines whether this pipelane has a breakpoint unit or not.
    HAS_BRK                     : boolean;
    
    -- Determines whether this pipelane interfaces with a branch unit or not.
    HAS_BR                      : boolean
    
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
    
    -- Active high stall input.
    stall                       : in  std_logic;
    
    ---------------------------------------------------------------------------
    -- Configuration and run control
    ---------------------------------------------------------------------------
    -- Configuration bit, connected to the decouple vector. When this is low,
    -- the branch, memory and breakpoint units are disabled, and attempting to
    -- execute a syllable which needs one of these units results in an invalid
    -- opcode exception.
    cfg2pl_decouple             : in  std_logic;
    
    -- Run bit for this pipelane from the configuration logic.
    cfg2pl_run                  : in  std_logic;
    
    -- Active high reconfiguration block bit. When high, reconfiguration is
    -- not permitted. This is essentially an active low idle flag.
    pl2cfg_blockReconfig        : out std_logic;
    
    -- External interrupt request signal, active high. This is already masked
    -- by the interrupt enable bit in the control register.
    cxplif2pl_irq               : in  std_logic_vector(S_MEM+1 to S_MEM+1);
    
    -- External interrupt acknowledge signal, active high. and'ed with the
    -- stall input, so it goes high for exactly one clkEn'abled cycle.
    pl2cxplif_irqAck            : out std_logic_vector(S_MEM to S_MEM);
    
    -- Active high run signal. This is the combined run signal from the
    -- external run input and the BRK flag in the debug control register.
    cxplif2pl_run               : in  std_logic;
    
    -- Active high idle output.
    pl2cxplif_idle              : out std_logic;
    
    ---------------------------------------------------------------------------
    -- Instruction memory interface
    ---------------------------------------------------------------------------
    -- Address of the bundle to fetch.
    br2imem_PC                  : out rvex_address_array(S_IF to S_IF);
    
    -- Active high fetch enable signal.
    br2imem_fetch               : out std_logic_vector(S_IF to S_IF);
    
    -- Active high cancel signal for the previous fetch. This is a hint to the
    -- memory/cache that, if it would need to stall the core to fetch the
    -- previously requested opcode, it can stop the fetch and allow the core to
    -- continue.
    br2imem_cancel              : out std_logic_vector(S_IF+L_IF to S_IF+L_IF);
    
    -- Syllable from the instruction memory.
    imem2pl_syllable            : in  rvex_syllable_array(S_IF+L_IF to S_IF+L_IF);
    
    -- Exception input from instruction memory.
    imem2pl_exception           : in  trap_info_array(S_IF+L_IF to S_IF+L_IF);
    
    ---------------------------------------------------------------------------
    -- Data memory interface
    ---------------------------------------------------------------------------
    -- Data memory address, shared between read and write command.
    memu2dmsw_addr              : out rvex_address_array(S_MEM to S_MEM);
    
    -- Data memory write command.
    memu2dmsw_writeData         : out rvex_data_array(S_MEM to S_MEM);
    memu2dmsw_writeMask         : out rvex_mask_array(S_MEM to S_MEM);
    memu2dmsw_writeEnable       : out std_logic_vector(S_MEM to S_MEM);
    
    -- Data memory read command and result.
    memu2dmsw_readEnable        : out std_logic_vector(S_MEM to S_MEM);
    dmsw2memu_readData          : in  rvex_data_array(S_MEM+L_MEM to S_MEM+L_MEM);
    
    -- Exception input from data memory.
    dmsw2pl_exception           : in  trap_info_array(S_MEM+L_MEM to S_MEM+L_MEM);
    
    ---------------------------------------------------------------------------
    -- Register file interface
    ---------------------------------------------------------------------------
    -- These signals are array'd outside this entity and contain pipeline
    -- configuration dependent data types, so they need to be put in records.
    -- The signals are documented in rvex_intIface_pkg.vhd, where the types are
    -- defined.
    
    -- General purpose register file read port A.
    pl2gpreg_readPortA          : out pl2gpreg_readPort_type;
    gpreg2pl_readPortA          : in  gpreg2pl_readPort_type;
    
    -- General purpose register file read port B.
    pl2gpreg_readPortB          : out pl2gpreg_readPort_type;
    gpreg2pl_readPortB          : in  gpreg2pl_readPort_type;
    
    -- General purpose register file write port.
    pl2gpreg_writePort          : out pl2gpreg_writePort_type;
    
    -- Branch/link register read port.
    cxplif2pl_brLinkReadPort    : in  cxreg2pl_readPort_type;
    
    -- Branch/link register write port.
    pl2cxplif_brLinkWritePort   : out pl2cxreg_writePort_type;
    
    ---------------------------------------------------------------------------
    -- Special context register interface
    ---------------------------------------------------------------------------
    -- Next value for the PC register, only valid for master lanes with a
    -- branch unit.
    br2cxplif_PC                : out rvex_address_array(S_IF to S_IF);
    
    -- PC for the current bundle, as stored in the context PC register.
    cxplif2pl_bundlePC          : in  rvex_address_array(S_IF+1 to S_IF+1);
    
    -- Exact PC for the syllable in this lane. When this PC is lower than the
    -- bundle PC, the syllable should be invalidated. This is necessary to
    -- support branches to PCs which are not aligned to the current amount of
    -- lanes working together. It's also used for the simulation disassembly.
    cxplif2pl_lanePC            : in  rvex_address_array(S_IF+1 to S_IF+1);
    
    -- When high, the next PC should be set to the current value of the PC
    -- register unconditionally. This is high when the debug bus wrote to the
    -- PC register, and after a (context) reset to ensure that execution starts
    -- at 0.
    cxplif2pl_overridePC        : in  std_logic_vector(S_IF+1 to S_IF+1);
    
    -- Current trap handler. When the application has marked that it is not
    -- currently capable of accepting a trap, this is set to the panic handler
    -- register instead.
    cxplif2pl_trapHandler       : in  rvex_address_array(S_MEM+1 to S_MEM+1);
    
    -- Trap information for the trap currently handled by the branch unit, if
    -- any. We can commit this in the branch stage already, because it is
    -- guaranteed that there is no instruction valid in S_MEM while a trap is
    -- entered.
    pl2cxplif_trapInfo          : out trap_info_array(S_BR to S_BR);
    pl2cxplif_trapPoint         : out trap_info_array(S_BR to S_BR);
    
    -- Commands the register logic to reset the trap cause to 0 and restore
    -- the control registers which were saved upon trap entry.
    pl2cxplif_rfi               : out std_logic_vector(S_MEM to S_MEM);
    
    -- When this (debug) trap is active, BRK must be set and the external debug
    -- cause value should be set to the trap cause.
    br2cxplif_brk               : out trap_info_array(S_BR to S_BR);
    
    -- Current breakpoint information.
    cxplif2brku_breakpoints     : in  cxreg2pl_breakpoint_info_type;
    
    -- When high, breakpoints should be disabled for this instruction.
    cxplif2pl_ignoreBreakpoint  : in  std_logic_vector(S_IF to S_IF);
    
    ---------------------------------------------------------------------------
    -- Long immediate routing interface
    ---------------------------------------------------------------------------
    -- LIMMH outputs. Enable is high when this pipelane is executing a LIMMH
    -- instruction, in which case target selects whether the value is intended
    -- for the neighboring pipelane (high) or two pipelanes ahead (low), and
    -- data contains the immediate. Valid is high when the instruction is
    -- valid or when fetchOnly is set; invalid instructions should perform no
    -- operation.
    pl2limm_valid               : out std_logic_vector(S_LIMM to S_LIMM);
    pl2limm_enable              : out std_logic_vector(S_LIMM to S_LIMM);
    pl2limm_target              : out std_logic_vector(S_LIMM to S_LIMM);
    pl2limm_data                : out rvex_limmh_array(S_LIMM to S_LIMM);
    
    -- LIMMH input. When enable is high, the immediate operand used in this
    -- instruction should be extended by the value in data.
    limm2pl_enable              : in  std_logic_vector(S_LIMM to S_LIMM);
    limm2pl_data                : in  rvex_limmh_array(S_LIMM to S_LIMM);
    
    -- LIMMH error. When high, a LIMMH instruction is trying to forward in a
    -- way not supported by the current core configuration.
    limm2pl_error               : in  std_logic_vector(S_LIMM to S_LIMM);
    
    ---------------------------------------------------------------------------
    -- Trap routing interface
    ---------------------------------------------------------------------------
    -- Indicates whether an exception is active for each pipeline stage and if
    -- so, which.
    pl2trap_trap                : out trap_info_stages_type;
    
    -- Trap information record from the final pipeline stage, combined from all
    -- coupled pipelines and forwarded to the stage just before the branch
    -- stage for processing.
    trap2pl_trapToHandle        : in  trap_info_array(S_TRAP to S_TRAP);
    
    -- Whether a trap is in the pipeline somewhere. When this is high,
    -- instruction fetching can be halted to speed things up.
    trap2pl_trapPending         : in  trap_info_array(S_TRAP to S_TRAP);
    
    -- Trap disable input. When high, any trap caused by the instruction in the
    -- respective stage should be disabled/ignored, which happens when an
    -- earlier instruction is causing a trap.
    trap2pl_disable             : in  std_logic_stages_type;
    
    -- Stage flushing inputs from the trap routing logic. When high, the
    -- instruction in the respective pipeline stage should no longer be
    -- committed/be deactivated.
    trap2pl_flush               : in  std_logic_stages_type
    
  );
end rvex_pipelane;

--=============================================================================
architecture Behavioral of rvex_pipelane is
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- Pipeline signals
  -----------------------------------------------------------------------------
  -- Datapath state record.
  type datapathState_type is record
    
    -- Control signals decoded from opcode.
    c                           : datapathCtrlSignals_type;
    
    -- Register selection and read value for general purpose register read
    -- port A.
    src1                        : rvex_gpRegAddr_type;
    read1                       : rvex_data_type;
    
    -- Register selection and read value for general purpose register read
    -- port B.
    src2                        : rvex_gpRegAddr_type;
    read2                       : rvex_data_type;
    
    -- Register selection and read value for branch register.
    srcBr                       : rvex_brRegAddr_type;
    readBr                      : std_logic;
    
    -- Read value for link register.
    readLink                    : rvex_address_type;
    
    -- Immediate values for arithmetic and branch operations. These are LIMMH
    -- extended in the LIMM stage.
    imm                         : rvex_data_type;
    brOff                       : rvex_address_type;
    
    -- Demuxed operands. op1 and op2 go to the arithmetic units. op3 is the write
    -- value for a memory operations, where op1 + op2 (resAdd) is the address.
    op1                         : rvex_data_type;
    op2                         : rvex_data_type;
    op3                         : rvex_data_type;
    opBr                        : std_logic;
    
    -- Computed branch targets, used by the branch unit.
    brTgtLink                   : rvex_address_type;
    brTgtOff                    : rvex_address_type;
    
    -- Results from the functional units.
    resALU                      : rvex_data_type;
    resAdd                      : rvex_address_type;
    resMul                      : rvex_data_type;
    resMem                      : rvex_data_type;
    
    -- Destination register and value for general purpose register file and link
    -- register.
    dest                        : rvex_gpRegAddr_type;
    res                         : rvex_data_type;
    
    -- Destination register and value for branch register file.
    destBr                      : rvex_brRegAddr_type;
    resBr                       : std_logic;
    
  end record;
  
  -- Default/initialization value for datapath.
  constant DATAPATH_STATE_DEFAULT : datapathState_type := (
    c                           => DP_CTRL_NOP,
    readBr                      => RVEX_UNDEF,
    opBr                        => RVEX_UNDEF,
    resBr                       => RVEX_UNDEF,
    others                      => (others => RVEX_UNDEF)
  );
  
  -- State variable for the execution of a single syllable. This is used for
  -- the pipeline registers.
  type syllableState_type is record
    
    -- PC for the bundle currently being executed.
    PC_bundle                   : rvex_address_type;
    
    -- PC for the exact instruction being executed.
    PC_lane                     : rvex_address_type;
    
    -- For lanes with a branch unit, this contains PC+1, i.e. the next
    -- instruction in case no branch occurs.
    PC_plusOne                  : rvex_address_type;
    
    -- Syllable, as received from instruction memory.
    syllable                    : rvex_syllable_type;
    
    -- Datapath signals.
    dp                          : datapathState_type;
    
  end record;
  
  -- Initialization value for the state variable. This is assigned to all stage
  -- registers upon reset, and is always assigned to the input of the first
  -- stage.
  constant SYLLABLE_STATE_DEFAULT : syllableState_type := (
    dp                          => DATAPATH_STATE_DEFAULT,
    others                      => (others => RVEX_UNDEF)
  );
  
  -- Array type for syllable state.
  type syllableState_array is array(natural range <>) of syllableState_type;
  
  -- Pipeline register signals. si is the input of the combinatorial stage and
  -- thus the outputs of the registers, so is the output of the combinatorial
  -- stage and the input of the stage registers.
  signal si                     : syllableState_array(S_FIRST to S_LAST);
  signal so                     : syllableState_array(S_FIRST to S_LAST);
  
  -----------------------------------------------------------------------------
  -- Signals between the pipeline and the functional units
  -----------------------------------------------------------------------------
  -- TODO
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  --===========================================================================
  -- Generate pipeline logic
  --===========================================================================
  comb: process (
    
    -- Stage register inputs
    ------------------------
    si,
    
    -- Signals from external blocks
    -------------------------------
    -- Stall signal is needed for the irqAck signal.
    stall,
    
    -- Configuration and run control.
    cfg2pl_decouple,
    
    -- Run bit for this pipelane from the configuration logic.
    cfg2pl_run, cxplif2pl_irq, cxplif2pl_run,
    
    -- Memory interface.
    imem2pl_syllable, imem2pl_exception, dmsw2pl_exception,
    
    -- Register file interface.
    gpreg2pl_readPortA, gpreg2pl_readPortB, cxplif2pl_brLinkReadPort,
    
    -- Special context register interface.
    cxplif2pl_bundlePC, cxplif2pl_lanePC, cxplif2pl_overridePC,
    cxplif2pl_trapHandler, cxplif2pl_ignoreBreakpoint,
    
    -- Long immediate routing interface.
    limm2pl_enable, limm2pl_data, limm2pl_error,
    
    -- Trap routing interface.
    trap2pl_trapToHandle, trap2pl_trapPending, trap2pl_disable, trap2pl_flush
    
    -- Signals from functional units
    --------------------------------
    -- TODO
    
  ) is
    
    -- Instruction state variable between the blocks.
    variable s                  : syllableState_array(S_FIRST to S_LAST);
    
  begin
    
    ---------------------------------------------------------------------------
    -- Load the stage inputs
    ---------------------------------------------------------------------------
    s := si;
    
    
    
    
    
    ---------------------------------------------------------------------------
    -- Drive stage outputs
    ---------------------------------------------------------------------------
    so <= s;
    
  end process;
    
  --===========================================================================
  -- Instantiate pipeline registers
  --===========================================================================
  regs: process (clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        si(S_FIRST+1 to S_LAST) <= (others => SYLLABLE_STATE_DEFAULT);
      elsif clkEn = '1' and stall = '0' then
        si(S_FIRST+1 to S_LAST) <= so(S_FIRST to S_LAST-1);
      end if;
    end if;
  end process;
  
  -- Always drive the input of the first pipeline stage with the reset state.
  si(S_FIRST) <= SYLLABLE_STATE_DEFAULT;
  
  --===========================================================================
  -- Instantiate functional blocks
  --===========================================================================
  -- TODO
  
end Behavioral;

