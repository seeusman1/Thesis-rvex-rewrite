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
    -- Global configuration.
    CFG                         : rvex_generic_config_type;
    
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
    
    -- Number of coupled lane groups.
    cfg2pl_numGroupsLog2        : in  rvex_2bit_type;
    
    -- Run bit for this pipelane from the configuration logic.
    cfg2br_run                  : in  std_logic;
    
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
    cxplif2br_run               : in  std_logic;
    
    -- Active high idle output.
    pl2cxplif_idle              : out std_logic;
    
    ---------------------------------------------------------------------------
    -- Next operation routing interface
    ---------------------------------------------------------------------------
    -- The PC for the current instruction, as chosen by the active branch unit
    -- within the group. The PC is distributed by the context-pipelane
    -- interface block so all coupled pipelanes have it.
    br2cxplif_PC                : out rvex_address_array(S_IF to S_IF);
    cxplif2pl_PC                : in  rvex_address_array(S_IF to S_IF);
    
    -- Same as PC, but with the index of the lane within the group of coupled
    -- lanes added to it, to get the exact address of the syllable which is
    -- processed by this lane. This should only be used by the VHDL simulation.
    cxplif2pl_lanePC            : in  rvex_address_array(S_IF to S_IF);
    
    -- Whether an instruction fetch is being initiated or not.
    br2cxplif_limmValid         : out std_logic_vector(S_IF to S_IF);
    cxplif2pl_limmValid         : in  std_logic_vector(S_IF to S_IF);
    
    -- Whether the next instruction is valid and should be committed or not.
    br2cxplif_valid             : out std_logic_vector(S_IF to S_IF);
    cxplif2pl_valid             : in  std_logic_vector(S_IF to S_IF);
    
    -- Whether breakpoints are valid in the next instruction or not. This is
    -- low when returning from a debug interrupt.
    br2cxplif_brkValid          : out std_logic_vector(S_IF to S_IF);
    cxplif2pl_brkValid          : in  std_logic_vector(S_IF to S_IF);
    
    -- Whether or not pipeline stages S_IF+1 to S_BR-1 should be invalidated
    -- due to a branch or the core stopping.
    br2cxplif_invalUntilBR      : out std_logic_vector(S_BR to S_BR);
    cxplif2pl_invalUntilBR      : in  std_logic_vector(S_BR to S_BR);
    
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
    -- Special register interface
    ---------------------------------------------------------------------------
    -- The current value of the context PC register and associated override
    -- flag. When the override flag is set, the branch unit should behave as if
    -- there was a branch to the value in contextPC. This happens when the
    -- debug bus writes to the PC register.
    cxplif2br_contextPC         : in  rvex_address_array(S_IF+1 to S_IF+1);
    cxplif2br_overridePC        : in  std_logic_vector(S_IF+1 to S_IF+1);
    
    -- Current trap handler. When the application has marked that it is not
    -- currently capable of accepting a trap, this is set to the panic handler
    -- register instead.
    cxplif2pl_trapHandler       : in  rvex_address_array(S_MEM+1 to S_MEM+1);
    
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
    
    -- Commands the register logic to reset the trap cause to 0 and restore
    -- the control registers which were saved upon trap entry.
    pl2cxplif_rfi               : out std_logic_vector(S_MEM to S_MEM);
    
    -- Whether debug traps are to be handled normally or by halting execution
    -- for debugging through the external bebug bus.
    cxplif2br_extDebug          : in  std_logic_vector(S_BR to S_BR);
    
    -- Set when the current value of the trap cause register maps to a debug
    -- trap.
    cxplif2br_handlingDebugTrap : in  std_logic_vector(S_BR to S_BR);
    
    -- Current value of the debug trap enable bit in the control register.
    cxplif2pl_debugTrapEnable   : in  std_logic_vector(S_MEM+1 to S_MEM+1);
    
    -- Current breakpoint information.
    cxplif2brku_breakpoints     : in  cxreg2pl_breakpoint_info_array(S_BRK to S_BRK);
    
    -- Current value of the stepping flag in the debug control register. When
    -- high, a step trap must be triggered if there is no other trap and
    -- breakpoints are enabled.
    cxplif2brku_stepping        : in  cxreg2pl_breakpoint_info_array(S_BRK to S_BRK);
    
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
    trap2pl_trapPending         : in  std_logic_vector(S_TRAP to S_TRAP);
    
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
    
    -- Computed branch targets, for lanes which have a branch unit.
    brTgtLink                   : rvex_address_type;
    brTgtRel                    : rvex_address_type;
    
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
    
    -- TODO
    
    -- Datapath signals.
    dp                          : datapathState_type;
    
  end record;
  
  -- Initialization value for the state variable. This is assigned to all stage
  -- registers upon reset, and is always assigned to the input of the first
  -- stage.
  constant SYLLABLE_STATE_DEFAULT : syllableState_type := (
    dp                          => DATAPATH_STATE_DEFAULT
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
  -- Pipelane <-> branch unit interconnect. Refer to branch unit entity for
  -- more information about the signals.
  signal pl2br_opcode           : rvex_opcode_array(S_BR to S_BR);
  signal pl2br_PC_plusOne_IFP1  : rvex_address_array(S_IF+1 to S_IF+1);
  signal pl2br_PC_plusOne_BR    : rvex_address_array(S_BR to S_BR);
  signal pl2br_brTgtLink        : rvex_address_array(S_BR to S_BR);
  signal pl2br_brTgtRel         : rvex_address_array(S_BR to S_BR);
  signal pl2br_opBr             : std_logic_vector(S_BR to S_BR);
  signal pl2br_trapPending      : std_logic_vector(S_BR to S_BR);
  signal pl2br_trapToHandleInfo : trap_info_array(S_BR to S_BR);
  signal pl2br_trapToHandlePoint: rvex_address_array(S_BR to S_BR);
  signal pl2br_trapToHandleHandler:rvex_address_array(S_BR to S_BR);
  signal br2pl_rfi              : std_logic_vector(S_BR to S_BR);
  signal br2pl_trap             : trap_info_array(S_BR to S_BR);
  
  -- Pipelane <-> ALU interconnect. Refer to ALU entity for more information
  -- about the signals.
  signal pl2alu_opcode          : rvex_opcode_array(S_ALU to S_ALU);
  signal pl2alu_op1             : rvex_data_array(S_ALU to S_ALU);
  signal pl2alu_op2             : rvex_data_array(S_ALU to S_ALU);
  signal pl2alu_opBr            : std_logic_vector(S_ALU to S_ALU);
  signal alu2pl_resultAdd       : rvex_data_array(S_ALU+L_ALU1 to S_ALU+L_ALU1);
  signal alu2pl_result          : rvex_data_array(S_ALU+L_ALU1+L_ALU2 to S_ALU+L_ALU1+L_ALU2);
  signal alu2pl_resultBr        : std_logic_vector(S_ALU+L_ALU1+L_ALU2 to S_ALU+L_ALU1+L_ALU2);
  
  -- Pipelane <-> multiply unit interconnect. Refer to multiply unit entity for
  -- more information about the signals.
  signal pl2mulu_opcode         : rvex_opcode_array(S_MUL to S_MUL);
  signal pl2mulu_op1            : rvex_data_array(S_MUL to S_MUL);
  signal pl2mulu_op2            : rvex_data_array(S_MUL to S_MUL);
  signal mulu2pl_result         : rvex_data_array(S_MUL+L_MUL to S_MUL+L_MUL);
  
  -- Pipelane <-> memory unit interconnect. Refer to memory unit entity for
  -- more information about the signals.
  signal pl2memu_opcode         : rvex_opcode_array(S_MEM to S_MEM);
  signal pl2memu_opAddr         : rvex_address_array(S_MEM to S_MEM);
  signal pl2memu_opData         : rvex_data_array(S_MEM to S_MEM);
  signal memu2pl_trap           : rvex_trap_array(S_MEM to S_MEM);
  signal memu2pl_result         : rvex_data_array(S_MEM+L_MEM to S_MEM+L_MEM);
  
  -- Pipelane <-> breakpoint unit interconnect. Refer to the breakpoint unit
  -- entity for more information about the signals.
  signal pl2brku_ignoreBreakpoint:std_logic_vector(S_BRK to S_BRK);
  signal pl2brku_opcode         : rvex_opcode_array(S_BRK to S_BRK);
  signal pl2brku_opAddr         : rvex_address_array(S_BRK to S_BRK);
  signal pl2brku_PC_bundle      : rvex_address_array(S_BRK to S_BRK);
  signal brku2pl_trap           : trap_info_array(S_BRK+L_BRK to S_BRK+L_BRK);
  
--=============================================================================
begin -- architecture
--=============================================================================
  
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
    cfg2pl_decouple, cxplif2pl_irq,
    
    -- Next operation routing interface.
    cxplif2pl_PC, cxplif2pl_lanePC, cxplif2pl_limmValid, cxplif2pl_valid,
    cxplif2pl_brkValid, cxplif2pl_invalUntilBR,
    
    -- Memory interface.
    imem2pl_syllable, imem2pl_exception, dmsw2pl_exception,
    
    -- Register file interface.
    gpreg2pl_readPortA, gpreg2pl_readPortB, cxplif2pl_brLinkReadPort,
    
    -- Special register interface.
    cxplif2pl_trapHandler, cxplif2pl_debugTrapEnable,
    
    -- Long immediate routing interface.
    limm2pl_enable, limm2pl_data, limm2pl_error,
    
    -- Trap routing interface.
    trap2pl_trapToHandle, trap2pl_trapPending, trap2pl_disable, trap2pl_flush,
    
    
    -- Signals from functional units
    --------------------------------
    -- Signals from the branch unit.
    br2pl_rfi, br2pl_trap,
    
    -- Signals from the ALU.
    alu2pl_resultAdd, alu2pl_result, alu2pl_resultBr,
    
    -- Signals from the multiplier.
    mulu2pl_result,
    
    -- Signals from the memory unit.
    memu2pl_result,
    
    -- Signals from the breakpoint unit.
    brku2pl_trap
    
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
  -- Instantiate functional blocks
  --===========================================================================
  -- Instantiate the branch unit, if there should be one.
  br_gen: if HAS_BR generate
    br: entity work.rvex_br
      generic map (
        CFG                             => CFG
      )
      port map (
        
        -- System control.
        reset                           => reset,
        clk                             => clk,
        clkEn                           => clkEn,
        stall                           => stall,
        
        -- Next operation outputs to IMEM.
        br2imem_PC(S_IF)                => br2imem_PC(S_IF),
        br2imem_fetch(S_IF)             => br2imem_fetch(S_IF),
        br2imem_cancel(S_IF+L_IF)       => br2imem_cancel(S_IF+L_IF),
        
        -- Next operation outputs to coupled pipelanes and the context
        -- registers.
        br2cxplif_PC(S_IF)              => br2cxplif_PC(S_IF),
        br2cxplif_limmValid(S_IF)       => br2cxplif_limmValid(S_IF),
        br2cxplif_valid(S_IF)           => br2cxplif_valid(S_IF),
        br2cxplif_brkValid(S_IF)        => br2cxplif_brkValid(S_IF),
        br2cxplif_invalUntilBR(S_BR)    => br2cxplif_invalUntilBR(S_BR),
        
        -- Run control signals.
        cfg2br_run                      => cfg2br_run,
        cxplif2br_run                   => cxplif2br_run,
        
        -- Branch control signals from and to pipelane.
        pl2br_opcode(S_BR)              => pl2br_opcode(S_BR),
        pl2br_PC_plusOne_IFP1(S_IF+1)   => pl2br_PC_plusOne_IFP1(S_IF+1),
        pl2br_PC_plusOne_BR(S_BR)       => pl2br_PC_plusOne_BR(S_BR),
        pl2br_brTgtLink(S_BR)           => pl2br_brTgtLink(S_BR),
        pl2br_brTgtRel(S_BR)            => pl2br_brTgtRel(S_BR),
        pl2br_opBr(S_BR)                => pl2br_opBr(S_BR),
        pl2br_trapPending(S_BR)         => pl2br_trapPending(S_BR),
        pl2br_trapToHandleInfo(S_BR)    => pl2br_trapToHandleInfo(S_BR),
        pl2br_trapToHandlePoint(S_BR)   => pl2br_trapToHandlePoint(S_BR),
        pl2br_trapToHandleHandler(S_BR) => pl2br_trapToHandleHandler(S_BR),
        br2pl_rfi(S_BR)                 => br2pl_rfi(S_BR),
        br2pl_trap(S_BR)                => br2pl_trap(S_BR),
        
        -- Branch control signals from and to context registers.
        cxplif2br_contextPC(S_IF+1)     => cxplif2br_contextPC(S_IF+1),
        cxplif2br_overridePC(S_IF+1)    => cxplif2br_overridePC(S_IF+1),
        br2cxplif_trapInfo(S_BR)        => br2cxplif_trapInfo(S_BR),
        br2cxplif_trapPoint(S_BR)       => br2cxplif_trapPoint(S_BR),
        br2cxplif_exDbgTrapInfo(S_BR)   => br2cxplif_exDbgTrapInfo(S_BR),
        br2cxplif_stop(S_BR)            => br2cxplif_stop(S_BR),
        cxplif2br_trapReturn(S_BR)      => cxplif2br_trapReturn(S_BR),
        cxplif2br_handlingDebugTrap(S_BR)=>cxplif2br_handlingDebugTrap(S_BR),
        cxplif2br_extDebug(S_BR)        => cxplif2br_extDebug(S_BR)
        
      );
  end generate;
  no_br_gen: if not HAS_BR generate
    
    -- Set the branch unit outputs which are going to this pipelane to
    -- undefined.
    br2pl_rfi(S_BR) <= RVEX_UNDEF;
    br2pl_trap(S_BR) <= TRAP_INFO_NONE;
    
    -- Set branch unit outputs going to the instruction memory to hi-Z, so they
    -- can be easily merged with the signals from the other pipelanes in the
    -- group.
    br2imem_PC(S_IF)                    <= (others => 'Z');
    br2imem_fetch(S_IF)                 <= 'Z';
    br2imem_cancel(S_IF+L_IF)           <= 'Z';
    
    -- Set the signals going to the context-pipelane interface to undefined.
    br2cxplif_PC(S_IF)                  <= (others => RVEX_UNDEF);
    br2cxplif_limmValid(S_IF)           <= RVEX_UNDEF;
    br2cxplif_valid(S_IF)               <= RVEX_UNDEF;
    br2cxplif_brkValid(S_IF)            <= RVEX_UNDEF;
    br2cxplif_invalUntilBR(S_BR)        <= RVEX_UNDEF;
    br2cxplif_trapInfo(S_BR)            <= TRAP_INFO_NONE;
    br2cxplif_trapPoint(S_BR)           <= (others => RVEX_UNDEF);
    br2cxplif_exDbgTrapInfo(S_BR)       <= TRAP_INFO_NONE;
    br2cxplif_stop(S_BR)                <= RVEX_UNDEF;
    
  end generate;
  
  -- Instantiate the ALU.
  alu: entity work.rvex_alu
    generic map (
      CFG                               => CFG
    )
    port map (
      
      -- System control.
      reset                             => reset,
      clk                               => clk,
      clkEn                             => clkEn,
      stall                             => stall,
      
      -- Operand and control inputs.
      pl2alu_opcode(S_ALU)              => pl2alu_opcode(S_ALU),
      pl2alu_op1(S_ALU)                 => pl2alu_op1(S_ALU),
      pl2alu_op2(S_ALU)                 => pl2alu_op2(S_ALU),
      pl2alu_opBr(S_ALU)                => pl2alu_opBr(S_ALU),
      
      -- Outputs.
      alu2pl_resultAdd(S_ALU+L_ALU1)    => alu2pl_resultAdd(S_ALU+L_ALU1),
      alu2pl_result(S_ALU+L_ALU)        => alu2pl_result(S_ALU+L_ALU),
      alu2pl_resultBr(S_ALU+L_ALU)      => alu2pl_resultBr(S_ALU+L_ALU)
      
    );
  
  -- Instantiate the multiplier, if there should be one.
  mulu_gen: if HAS_MUL generate
    mulu: entity work.rvex_mulu
      generic map (
        CFG                             => CFG
      )
      port map (
        
        -- System control.
        reset                           => reset,
        clk                             => clk,
        clkEn                           => clkEn,
        stall                           => stall,
        
        -- Operand and control inputs.
        pl2mulu_opcode(S_MUL)           => pl2mulu_opcode(S_MUL),
        pl2mulu_op1(S_MUL)              => pl2mulu_op1(S_MUL),
        pl2mulu_op2(S_MUL)              => pl2mulu_op2(S_MUL),
        
        -- Outputs.
        mulu2pl_result(S_MUL+L_MUL)     => mulu2pl_result(S_MUL+L_MUL)
        
      );
  end generate;
  no_mulu_gen: if not HAS_MUL generate
    
    -- Set multiplier unit outputs to undefined.
    mulu2pl_result(S_MUL+L_MUL) <= (others => RVEX_UNDEF);
    
  end generate;
  
  -- Instantiate the memory unit, if there should be one.
  memu_gen: if HAS_MEM generate
    memu: entity work.rvex_memu
      generic map (
        CFG                             => CFG
      )
      port map (
        
        -- System control.
        reset                           => reset,
        clk                             => clk,
        clkEn                           => clkEn,
        stall                           => stall,
        
        -- Pipelane interface.
        pl2memu_opcode(S_MEM)           => pl2memu_opcode(S_MEM),
        pl2memu_opAddr(S_MEM)           => pl2memu_opAddr(S_MEM),
        pl2memu_opData(S_MEM)           => pl2memu_opData(S_MEM),
        memu2pl_trap(S_MEM)             => memu2pl_trap(S_MEM),
        memu2pl_result(S_MEM+L_MEM)     => memu2pl_result(S_MEM+L_MEM),
        
        -- Memory interface.
        memu2dmsw_addr(S_MEM)           => memu2dmsw_addr(S_MEM),
        memu2dmsw_writeData(S_MEM)      => memu2dmsw_writeData(S_MEM),
        memu2dmsw_writeMask(S_MEM)      => memu2dmsw_writeMask(S_MEM),
        memu2dmsw_writeEnable(S_MEM)    => memu2dmsw_writeEnable(S_MEM),
        memu2dmsw_readEnable(S_MEM)     => memu2dmsw_readEnable(S_MEM),
        dmsw2memu_readData(S_MEM+L_MEM) => dmsw2memu_readData(S_MEM+L_MEM)
        
      );
  end generate;
  no_memu_gen: if not HAS_MEM generate
    
    -- Set the memory unit result going to this pipelane to undefined and set
    -- the trap output to no trap.
    memu2pl_trap(S_MEM)           <= TRAP_INFO_NONE;
    memu2pl_result(S_MEM+L_MEM)   <= (others => RVEX_UNDEF);
    
    -- Set the outputs going to the rest of the processor to hi-Z, so they can
    -- be easily merged with the signals coming from the pipelane in the group
    -- which does have a memory unit.
    memu2dmsw_addr(S_MEM)         <= (others => 'Z');
    memu2dmsw_writeData(S_MEM)    <= (others => 'Z');
    memu2dmsw_writeMask(S_MEM)    <= (others => 'Z');
    memu2dmsw_writeEnable(S_MEM)  <= 'Z';
    memu2dmsw_readEnable(S_MEM)   <= 'Z';
    
  end generate;
  
  -- Instantiate breakpoint unit, if there should be one.
  brku_gen: if HAS_BRK generate
    brku: entity work.rvex_brku
      generic map (
        CFG                             => CFG
      )
      port map (
        
        -- System control.
        reset                           => reset,
        clk                             => clk,
        clkEn                           => clkEn,
        stall                           => stall,
        
        -- Pipelane interface
        pl2brku_ignoreBreakpoint(S_BRK) => pl2brku_ignoreBreakpoint(S_BRK),
        pl2brku_opcode(S_BRK)           => pl2brku_opcode(S_BRK),
        pl2brku_opAddr(S_BRK)           => pl2brku_opAddr(S_BRK),
        pl2brku_PC_bundle(S_BRK)        => pl2brku_PC_bundle(S_BRK),
        brku2pl_trap(S_BRK+L_BRK)       => brku2pl_trap(S_BRK+L_BRK),
        
        -- Breakpoint information
        cxplif2brku_breakpoints(S_BRK)  => cxplif2brku_breakpoints(S_BRK),
        cxplif2brku_stepping(S_BRK)     => cxplif2brku_stepping(S_BRK)
        
      );
  end generate;
  no_brku_gen: if not HAS_BRK generate
    
    -- Drive the trap output with the no-trap signal.
    brku2pl_trap(S_BRK+L_BRK) <= TRAP_INFO_NONE;
    
  end generate;
  
end Behavioral;

