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












--=============================================================================
-- READ ME PLEASE
--=============================================================================
-- 
-- If you just want a broad idea of what the rvex pipeline looks like, you're
-- probably better off looking at the following two diagrams instead of
-- reading this file:
--  - the pipeline diagram in rvex_pipeline_pkg.vhd
--  - the datapath diagram in rvex_opcodeDatapath_pkg,vhd
-- 
-- If you want to tweak the timing of the pipeline, there's also no need to
-- understand this file - just go to rvex_pipeline_pkg.vhd and adjust the
-- timing there. There's assertions in all relevant files which make sure you
-- can't really do anything wrong there accidentally without
-- simulation/synthesis complaining.
-- 
-- If you're looking for specifics or want to modify the datapath, though,
-- you're in the right place, so read on. This section is here to hopefully
-- give you a starting point in comprehending what's going on here, so you
-- don't have to start at zero in an almost 2kLOC (at the time of writing)
-- VHDL file.
-- 
-- Note that it's by design that it's large: it's not large because it's
-- complicated, but because of the following reasons:
--
--  - I wanted as much of the documentation needed to understand a single file
--    to be in that file itself. Having to ctrl+f for signal names or functions
--    in a bunch of files is, in my opinion, worse than only having to do it in
--    a single file.
--
--  - I wanted the pipeline to be described in chronological order. And not
--    just by strategically moving bits of code around to make it look that way
--    (because that's just going to break over time) but I wanted it to
--    actually be functional. The only real way to do that in VHDL that I know
--    of is to put everything in a single process. Which is obviously going to
--    be big.
-- 
--  - Most people (me included) find pipelines a difficult concept to grasp,
--    and especially to debug. So I wanted a way to somewhat abstract away from
--    that somehow, without greatly affecting the final synthesis result, in
--    such a way that it's easy to debug and hard to do wrong. Part of what I
--    did to accomplish this as best I could is to have almost* all the
--    pipeline registers in one place, for which the most logical place of
--    course is this file.
-- 
-- * Almost all, because functional units can still have local pipeline
-- registers. It made sense to allow this, as you can't exactly model the
-- entire memory in the pipeline of course.
-- 
-- Theory of operation
-- -------------------
-- All operations in the pipeline are modelled as sequential operations on
-- an execution state vector in a single process, wherein the execution state
-- vector is simply a variable. Because it is a variable, it should be
-- modified for each execution phase/functional unit in chronological order,
-- or things won't make sense or work anymore.
-- 
-- In stead of somehow inserting pipeline stages in the state vector in the
-- middle of the process, the process models the execution of an instruction as
-- if all execution phases/functional units were combinatorial. In fact, for
-- as far as the pipeline logic is concerned, they can be. Which is exactly
-- what we want, because then we don't have to think about the pipeline
-- anymore. But if everything is (seemingly) combinatorial, how can there be
-- pipeline stages?
--
-- Let's say we have a simplified datapath with three execution phases, which,
-- if there were no pipeline stages, would be spread out over a singla clock
-- cycle as follows.
--
--         clk                                                  clk
--          :                                                    :
--          : .------------------------. .---------. .---------. :
--          : |        Phase 1         | | Phase 2 | | Phase 3 | :
--          : '------------------------' '---------' '---------' :
-- 
-- Now let's say we want to pipeline this by injecting a stage between phases
-- 1 and 2. We can do this by duplicating the execution state vector,
-- performing phase 1 on the first execution state vector (stage 1) and phases
-- 2 and 3 on the second state vector (stage 2), like this.
-- 
--                      clk                          clk
--                       :                            :
--                       : .------------------------. :
--               Stage 1 : |        Phase 1         | :
--                       : '------------------------' :
--                       :                            :
--                       : .---------. .---------.    :
--               Stage 2 : | Phase 2 | | Phase 3 |    :
--                       : '---------' '---------'    :
-- 
-- Now observe that if we connect the output execution state vector output
-- from stage 1 to the input for stage 2 through a register, we get the
-- pipeline we wanted.
-- 
--      clk                          clk                          clk
--       :                            :                            :
--       : .------------------------. : .---------. .---------.    :
--       : |        Phase 1         | : | Phase 2 | | Phase 3 |    :
--       : '------------------------' : '---------' '---------'    :
-- 
-- Note that to do this, all we had to do was connect a phase to a different
-- stage - no logic had to be changed. We can do this arbitrarily as long as
-- later phases execute in either the same stage or a later stage than the
-- phases it depends on. So this is exactly how the pipeline is modelled.
-- 
-- The execution state vector and all pipeline-related input/output signals
-- are indexed by the stage they belong to. These stages are named S_* and
-- are defined in rvex_pipeline_pkg.vhd. In addition to these, the L_*
-- constants (defined in the same file) define the latency from input signal
-- to output signal for some blocks. When this happens, we just connect the
-- inputs of the block to the execution state vector belonging to its first
-- stage, and connect its outputs to the state vector belonging to its first
-- stage plus its latency.
-- 
-- In a nutshell, as long as we don't connect signals belonging to different
-- stages together without having a good reason (i.e. forwarding), we can
-- model any pipeline as an easy to comprehend combinatorial process.
-- 
-- Obviously, in order to keep everything simple like we want, we're
-- essentially requesting registers for EVERYTHING in the execution state
-- vector between every two stages, while a great amount of these registers
-- are not actually used. The nice thing about synthesis tools though, is that
-- one of their prime optimizations is finding components which only have their
-- inputs or only their have outputs connected to anything, and removing those
-- components from the design. Thus, synthesis tools won't actually instantiate
-- all these unused things. They may, however, generate a very large stream of
-- "unused register" or "unconnected signal" warnings.
-- 
-- They are still visible in simulation though. While this probably makes
-- simulation a little slower, actually makes comprehending what's going on
-- that much easier. When you want to debug an execution phase in a certain
-- stage, you just look up the state vector signal for that stage in simulation
-- (you'll want "si" for the input of the stage and "so" for the output) and
-- you instantly have everything in one place, all aligned to the same clock 
-- cycle.
-- 
-- Where to go from here
-- ---------------------
-- The two most important parts in this file are the specification and
-- documentation of the execution state vector and the process which describes
-- the operations on it. You can quickly find the start of these sections by
-- searching for "Pipeline signals" or "Generate pipeline logic" respectively,
-- or you can scroll all the way to the end of the file to get to the end of
-- the pipeline logic process.
-- 
--=============================================================================









library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.rvex_pkg.all;
use work.rvex_intIface_pkg.all;
use work.rvex_utils_pkg.all;
use work.rvex_pipeline_pkg.all;
use work.rvex_trap_pkg.all;
use work.rvex_opcode_pkg.all;
use work.rvex_opcodeDatapath_pkg.all;

-- pragma translate_off
use work.rvex_simUtils_pkg.all;
use work.rvex_simUtils_asDisas_pkg.all;
use work.rvex_opcodeMemory_pkg.all;
-- pragma translate_on

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
    -- VHDL simulation debug information
    ---------------------------------------------------------------------------
    -- pragma translate_off
    
    -- String with commit information, exact PC, disassembly and trap info for
    -- the last instruction in the pipeline.
    pl2sim_instr                : out rvex_string_builder_type;
    
    -- String with register write and data memory access information for the
    -- last instruction in the pipeline.
    pl2sim_op                   : out rvex_string_builder_type;
    
    -- String with branch information for the last instruction, if the branch
    -- unit is active.
    br2sim                      : out rvex_string_builder_type;
    
    -- pragma translate_on
    
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
    
    -- Active high reconfiguration block bit. When high, reconfiguration is
    -- not permitted. This is essentially an active low idle flag.
    pl2cxplif_blockReconfig     : out std_logic;
    
    -- External interrupt request signal, active high. This is already masked
    -- by the interrupt enable bit in the control register.
    cxplif2pl_irq               : in  std_logic_vector(S_MEM+1 to S_MEM+1);
    
    -- External interrupt identification. Guaranteed to be loaded in the trap
    -- argument register in the same clkEn'd cycle where irqAck is high.
    cxplif2br_irqID             : in  rvex_address_array(S_BR to S_BR);
    
    -- External interrupt acknowledge signal, active high. and'ed with the
    -- stall input, so it goes high for exactly one clkEn'abled cycle.
    br2cxplif_irqAck            : out std_logic_vector(S_BR to S_BR);
    
    -- Active high run signal. This is the combined run signal from the
    -- external run input, the BRK flag in the debug control register and the
    -- run bit from the configuration logic.
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
    
    -- Current value of the debug trap enable bit in the control register, or'd
    -- with the current value of the external debug flag.
    cxplif2pl_debugTrapEnable   : in  std_logic_vector(S_MEM+1 to S_MEM+1);
    
    -- Current breakpoint information.
    cxplif2brku_breakpoints     : in  cxreg2pl_breakpoint_info_array(S_BRK to S_BRK);
    
    -- Current value of the stepping flag in the debug control register. When
    -- high, a step trap must be triggered if there is no other trap and
    -- breakpoints are enabled.
    cxplif2brku_stepping        : in  std_logic_vector(S_BRK to S_BRK);
    
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
  
  --===========================================================================
  -- Pipeline signals
  --===========================================================================
  -- This section defines the syllable state type and contains the signal
  -- declarations for the pipeline registers.
  
  -----------------------------------------------------------------------------
  -- Datapath state record
  -----------------------------------------------------------------------------
  -- For additional information about the datapath, refer to the schematics in
  -- rvex_opcodeDatapath_pkg.vhd.
  type datapathState_type is record
    
    -- Control signals decoded from opcode.
    c                           : datapathCtrlSignals_type;
    
    -- Register selection and read value for general purpose register read
    -- port A. read1lo is set to the link register read value in stead of
    -- read1 when CFG.reg63isLink is set and src1 is set to rx.63.
    src1                        : rvex_gpRegAddr_type;
    read1                       : rvex_data_type;
    read1lo                     : rvex_data_type;
    
    -- Register selection and read value for general purpose register read
    -- port B. read2lo is set to the link register read value in stead of
    -- read2 when CFG.reg63isLink is set and src2 is set to rx.63.
    src2                        : rvex_gpRegAddr_type;
    read2                       : rvex_data_type;
    read2lo                     : rvex_data_type;
    
    -- Register selection and read value for branch register.
    srcBr                       : rvex_brRegAddr_type;
    readBr                      : std_logic;
    
    -- Read value for link register.
    readLink                    : rvex_address_type;
    
    -- Immediate value for arithmetic operations. This is LIMMH extended in
    -- the LIMMH stage.
    imm                         : rvex_data_type;
    
    -- Use-immediate control signal. This is tied to syllable bit 23.
    useImm                      : std_logic;
    
    -- Demuxed operands. op1 and op2 go to the arithmetic units. op3 is the
    -- write value for a memory operations, where op1 + op2 (resAdd) is the
    -- address.
    op1                         : rvex_data_type;
    op2                         : rvex_data_type;
    op3                         : rvex_data_type;
    opBr                        : std_logic;
    
    -- Results from the functional units.
    resALU                      : rvex_data_type;
    resAdd                      : rvex_address_type;
    resMul                      : rvex_data_type;
    resMem                      : rvex_data_type;
    
    -- Destination register and value for general purpose register file and
    -- link register. resValid controls whether the result should be stored
    -- in and forwarded by the general purpose register file, resLinkValid
    -- has the same function for the link register.
    dest                        : rvex_gpRegAddr_type;
    res                         : rvex_data_type;
    resValid                    : std_logic;
    resLinkValid                : std_logic;
    
    -- Copies of the datapath control signals for the general purpose and
    -- link register write enables, but taking CFG.reg63isLink into account.
    -- When CFG.reg63isLink is set, c.gpRegWE is high, and dest is rx.63 then
    -- gpRegWE_lo is forced low and linkWE_lo is forced high.
    gpRegWE_lo                  : std_logic;
    linkWE_lo                   : std_logic;
    
    -- Destination register and value for branch register file. resBrValid
    -- controls whether resBr should be stored and forwarded.
    destBr                      : rvex_brRegAddr_type;
    resBr                       : rvex_brRegData_type;
    resBrValid                  : rvex_brRegData_type;
    
  end record;
  
  -- Default/initialization value for datapath state.
  constant DATAPATH_STATE_DEFAULT : datapathState_type := (
    c                           => DP_CTRL_NOP,
    readBr                      => RVEX_UNDEF,
    useImm                      => RVEX_UNDEF,
    opBr                        => RVEX_UNDEF,
    resValid                    => '0',
    resLinkValid                => '0',
    gpRegWE_lo                  => RVEX_UNDEF,
    linkWE_lo                   => RVEX_UNDEF,
    resBrValid                  => (others => '0'),
    others                      => (others => RVEX_UNDEF)
  );
  
  -----------------------------------------------------------------------------
  -- Branch/next PC logic state record
  -----------------------------------------------------------------------------
  -- Most signals in here are only valid for lanes with a branch unit.
  type branchState_type is record
    
    -- PC for the next bundle.
    PC_plusOne                  : rvex_address_type;
    
    -- Immediate branch offset from the syllable.
    branchOffset                : rvex_address_type;
    
    -- PC-relative branch target.
    relativeTarget              : rvex_address_type;
    
    -- Link register branch target.
    linkTarget                  : rvex_address_type;
    
    -- This goes high when a trap is pending handling by the branch unit, which
    -- disables instruction fetching.
    trapPending                 : std_logic;
    
    -- Information about the trap which should be handled by the branch unit.
    trapInfo                    : trap_info_type;
    trapPoint                   : rvex_address_type;
    trapHandler                 : rvex_address_type;
    
    -- Return-from-interrupt control signal. This should be forwarded to the
    -- control registers in the S_MEM stage.
    RFI                         : std_logic;
    
    -- pragma translate_off
      -- Simulation information from branch unit.
      br2sim                    : rvex_string_builder_type;
    -- pragma translate_on
    
  end record;
  
  -- Default/initialization value for branch state.
  constant BRANCH_STATE_DEFAULT : branchState_type := (
    trapPending                 => RVEX_UNDEF,
    trapInfo                    => TRAP_INFO_UNDEF,
    RFI                         => RVEX_UNDEF,
    -- pragma translate_off
      br2sim                    => to_rvs("no info"),
    -- pragma translate_on
    others                      => (others => RVEX_UNDEF)
  );
  
  -----------------------------------------------------------------------------
  -- Trap logic state record
  -----------------------------------------------------------------------------
  type trapState_type is record
    
    -- Highest priority trap. Debug traps are merged only after the debug
    -- enable trap bit is valid.
    trap                        : trap_info_type;
    
    -- Highest priority debug trap, before the debug trap enable control
    -- register value is valid.
    debugTrap                   : trap_info_type;
    
    -- Trap handler for the current trap, loaded in the S_MEM+1 stage, when the
    -- latest values written to the control registers by the core are valid.
    trapHandler                 : rvex_address_type;
    
  end record;
  
  -- Default/initialization value for trap state.
  constant TRAP_STATE_DEFAULT : trapState_type := (
    trap                        => TRAP_INFO_NONE,
    debugTrap                   => TRAP_INFO_NONE,
    trapHandler                 => (others => RVEX_UNDEF)
  );
  
  -----------------------------------------------------------------------------
  -- Combined syllable state record
  -----------------------------------------------------------------------------
  -- State variable for the execution of a single syllable. This is used for
  -- the pipeline registers.
  type syllableState_type is record
    
    -- Syllable from instruction memory and its address.
    syllable                    : rvex_syllable_type;
    lanePC                      : rvex_address_type;
    
    -- Current PC for the bundle which is being executed.
    PC                          : rvex_address_type;
    
    -- Opcode portion of the syllable.
    opcode                      : rvex_opcode_type;
    
    -- Whether this instruction is valid and should be committed. May be
    -- disabled throughout the pipeline due to flushing.
    valid                       : std_logic;
    
    -- Whether long immediates are valid. This may be high while valid is not,
    -- to indicate that possible long immediates for the next instruction
    -- should be loaded, but nothing else.
    limmValid                   : std_logic;
    
    -- When low, breakpoints are disabled for this instruction. This is the
    -- case for the first instruction processed after returning from a debug
    -- trap handler or after resuming the core by clearing the BRK flag.
    brkValid                    : std_logic;
    
    -- Datapath signals.
    dp                          : datapathState_type;
    
    -- Branch/next PC related signals.
    br                          : branchState_type;
    
    -- Trap-related signals.
    tr                          : trapState_type;
    
    -- pragma translate_off
      -- Whether a memory access was requested or not.
      memRequested              : boolean;
      
      -- Whether an exception related to the memory access occured.
      memError                  : boolean;
      
      -- Whether a general purpose register, branch register or link register
      -- write was requested.
      gpRegWriteRequested       : std_logic;
      brRegWriteRequested       : rvex_brRegData_type;
      linkRegWriteRequested     : std_logic;
    -- pragma translate_on
    
  end record;
  
  -- Initialization value for the state variable. This is assigned to all stage
  -- registers upon reset, and is always assigned to the input of the first
  -- stage.
  constant SYLLABLE_STATE_DEFAULT : syllableState_type := (
    valid                       => '0',
    limmValid                   => '0',
    brkValid                    => '0',
    dp                          => DATAPATH_STATE_DEFAULT,
    br                          => BRANCH_STATE_DEFAULT,
    tr                          => TRAP_STATE_DEFAULT,
    -- pragma translate_off
      memRequested              => false,
      memError                  => false,
      gpRegWriteRequested       => '0',
      brRegWriteRequested       => (others => '0'),
      linkRegWriteRequested     => '0',
    -- pragma translate_on
    others                      => (others => RVEX_UNDEF)
  );
  
  -- Array type for syllable state.
  type syllableState_array is array(natural range <>) of syllableState_type;
  
  -- Pipeline register signals. si is the input of the combinatorial stage and
  -- thus the outputs of the registers, so is the output of the combinatorial
  -- stage and the input of the stage registers.
  signal si                     : syllableState_array(S_FIRST to S_LAST);
  signal so                     : syllableState_array(S_FIRST to S_LAST);
  
  --===========================================================================
  -- Signals between the pipeline and the functional units
  --===========================================================================
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
  -- pragma translate_off
  signal br2pl_sim              : rvex_string_builder_array(S_IF to S_IF);
  -- pragma translate_on
  
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
  signal pl2memu_valid          : std_logic_vector(S_MEM to S_MEM);
  signal pl2memu_opcode         : rvex_opcode_array(S_MEM to S_MEM);
  signal pl2memu_opAddr         : rvex_address_array(S_MEM to S_MEM);
  signal pl2memu_opData         : rvex_data_array(S_MEM to S_MEM);
  signal memu2pl_trap           : trap_info_array(S_MEM to S_MEM);
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
  -- Check configuration
  --===========================================================================
  assert S_FIRST = 1
    report "First stage must be set to 1."
    severity failure;
  
  -- Check instruction fetch and decode configuration.
  assert S_IF >= 1
    report "Instruction fetch cannot be scheduled before the first stage."
    severity failure;
  
  assert S_LIMM >= S_IF + L_IF
    report "Immediate forwarding cannot be scheduled before the instruction "
         & "fetch result is valid."
    severity failure;
  
  -- Check general purpose register file read access and forwarding
  -- configuration.
  assert S_RD >= S_IF + L_IF
    report "General purpose register read cannot be done before the "
         & "instruction fetch result is valid."
    severity failure;
  
  assert S_FW >= S_RD + L_RD
    report "The last stage for which general purpose register forwarding "
         & "occurs may not take place before the general purpose register "
         & "read result is valid. If you wish to disable forwarding, do so "
         & "using the CFG generic."
    severity failure;
  
  -- Check special (branch and link) register file read access and forwarding
  -- configuration.
  assert S_SRD >= S_IF + L_IF
    report "Special register read cannot be done before the instruction "
         & "fetch result is valid."
    severity failure;
  
  assert S_SFW >= S_SRD
    report "The last stage for which special register forwarding occurs may "
         & "not take place before the special register read result is valid. "
         & "If you wish to disable forwarding, do so using the CFG generic."
    severity failure;
  
  -- Check branch/next PC determination logic configuration.
  assert (S_TRAP >= 1) or not HAS_BR
    report "Trap information can not be forwarded to a cycle before the "
         & "pipeline starts."
    severity failure;
  
  assert (S_BR > S_TRAP) or not HAS_BR
    report "Branch determination cannot be done before the stage which traps "
         & "are forwarded to or in the same stage."
    severity failure;
  
  assert (S_PCP1 = 1) or (S_PCP1 = 2) or not HAS_BR
    report "PC + 1 computation must be scheduled at the end of the first "
         & "stage or at the beginning of the second."
    severity failure;
  
  assert (S_BTGT >= S_PCP1) or not HAS_BR
    report "PC-relative branch target computation must happen after PC + 1 "
         & "has been determined."
    severity failure;
  
  assert (S_BR >= S_BTGT) or not HAS_BR
    report "Branch determination cannot be done before the relative branch "
         & "target has been computed."
    severity failure;
  
  assert (S_BR >= S_SRD) or not HAS_BR
    report "Branch determination cannot be done before the special registers "
         & "have been read."
    severity failure;
  
  -- Check ALU dependencies.
  assert S_ALU >= S_LIMM
    report "ALU cannot be scheduled before long immediates have been "
         & "processed."
    severity failure;
  
  assert S_ALU >= S_RD + L_RD
    report "ALU cannot be scheduled before the general purpose registers have "
         & "been read."
    severity failure;
  
  assert S_ALU >= S_SRD
    report "ALU cannot be scheduled before the special registers have been "
         & "read."
    severity failure;
  
  -- Check multiply unit dependencies.
  assert (S_MUL >= S_LIMM) or not HAS_MUL
    report "Multiplication cannot be scheduled before long immediates have "
         & "been processed."
    severity failure;
  
  assert (S_MUL >= S_RD + L_RD) or not HAS_MUL
    report "Multiplication cannot be scheduled before the general purpose "
         & "registers have been read."
    severity failure;
  
  -- Check memory unit dependencies.
  assert (S_MEM >= S_RD + L_RD) or not HAS_MEM
    report "Memory command cannot be issued before the general purpose "
         & "registers have been read."
    severity failure;
  
  assert (S_MEM >= S_ALU + L_ALU1) or not HAS_MEM
    report "Memory command cannot be issued before the ALU has completed the "
         & "reg + immediate addition needed for the address."
    severity failure;
  
  -- Check breakpoint unit dependencies.
  assert (S_BRK >= S_ALU + L_ALU1) or not HAS_BRK
    report "Breakpoint unit can not be scheduled before the ALU has completed "
         & "the reg + immediate addition needed for the memory address."
    severity failure;
  
  -- Check general purpose register file writeback dependencies.
  assert S_WB >= S_ALU + L_ALU
    report "General purpose register file writeback cannot be scheduled "
         & "before the ALU result is valid."
    severity failure;
  
  assert (S_WB >= S_MUL + L_MUL) or not HAS_MUL
    report "General purpose register file writeback cannot be scheduled "
         & "before the multiplication result is valid."
    severity failure;
  
  assert (S_WB >= S_MEM + L_MEM) or not HAS_MEM
    report "General purpose register file writeback cannot be scheduled "
         & "before the memory read data is valid."
    severity failure;
  
  -- Check special register writeback dependencies.
  assert S_SWB >= S_ALU + L_ALU
    report "Special register writeback cannot be scheduled before the ALU "
         & "result is valid."
    severity failure;
  
  -- Make sure that no traps occur after the stage configured to have the last
  -- trap. Note that it is sufficient to only check for the memory stage here
  -- only because that stage HAS to be the last one. This does assume that at
  -- least one of the pipelanes has a memory unit; you're on your own if that's
  -- not the case.
  assert S_LTRP >= S_MEM + L_MEM or not HAS_MEM
    report "The memory unit may generate traps, but the stage configured to "
         & "generate the last trap is scheduled before that."
    severity failure;
  
  -- Make sure the last stage is configured correctly. It is sufficient to
  -- check for the branch and writeback stages, because they are dependent on
  -- everything else.
  assert S_LAST >= S_BR
    report "The last stage is configured to take place before branch "
         & "determination."
    severity failure;
  
  assert S_LAST >= S_WB + L_WB
    report "The last stage is configured to take place before the general "
         & "purpose memory write is complete."
    severity failure;
  
  --===========================================================================
  -- Instantiate functional blocks
  --===========================================================================
  -- Instantiate the branch unit, if there should be one.
  br_gen: if HAS_BR generate
    br_inst: entity work.rvex_br
      generic map (
        CFG                             => CFG
      )
      port map (
        
        -- System control.
        reset                           => reset,
        clk                             => clk,
        clkEn                           => clkEn,
        stall                           => stall,
        
        -- Simulation output.
        -- pragma translate_off
        br2pl_sim(S_IF)                 => br2pl_sim(S_IF),
        -- pragma translate_on
        
        -- Configuration inputs.
        cfg2br_numGroupsLog2            => cfg2pl_numGroupsLog2,
        
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
        cxplif2br_irqID(S_BR)           => cxplif2br_irqID(S_BR),
        br2cxplif_irqAck(S_BR)          => br2cxplif_irqAck(S_BR),
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
    br2cxplif_irqAck(S_BR)              <= RVEX_UNDEF;
    br2cxplif_trapInfo(S_BR)            <= TRAP_INFO_UNDEF;
    br2cxplif_trapPoint(S_BR)           <= (others => RVEX_UNDEF);
    br2cxplif_exDbgTrapInfo(S_BR)       <= TRAP_INFO_NONE;
    br2cxplif_stop(S_BR)                <= RVEX_UNDEF;
    
  end generate;
  
  -- Instantiate the ALU.
  alu_inst: entity work.rvex_alu
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
    mulu_inst: entity work.rvex_mulu
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
    memu_inst: entity work.rvex_memu
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
        pl2memu_valid(S_MEM)            => pl2memu_valid(S_MEM),
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
    brku_inst: entity work.rvex_brku
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
    -- Configuration and run control.
    cfg2pl_decouple, cfg2pl_numGroupsLog2, cxplif2pl_irq,
    
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
    memu2pl_result, memu2pl_trap,
    
    -- Signals from the breakpoint unit.
    brku2pl_trap
    
  ) is
    
    -- Instruction state variable between the blocks.
    variable s                  : syllableState_array(S_FIRST to S_LAST);
    
    -- Naturals used locally in various places.
    variable i                  : natural;
    
    -- std_logics used locally in various places.
    variable flag               : std_logic;
    
    -- Whether the pipeline is currently idle.
    variable idle               : std_logic;
    
    -- String builder for debug information.
    -- pragma translate_off
    variable debug              : rvex_string_builder_type;
    -- pragma translate_on
    
  begin
    
    ---------------------------------------------------------------------------
    -- Load the stage inputs
    ---------------------------------------------------------------------------
    s := si;
    
    ---------------------------------------------------------------------------
    -- Handle instruction fetch result and instruction validity signals
    ---------------------------------------------------------------------------
    -- Copy the signals broadcast by the active branch unit into the pipeline.
    s(S_IF).PC        := cxplif2pl_PC(S_IF);
    s(S_IF).lanePC    := cxplif2pl_lanePC(S_IF);
    s(S_IF).valid     := cxplif2pl_valid(S_IF);
    s(S_IF).limmValid := cxplif2pl_limmValid(S_IF);
    s(S_IF).brkValid  := cxplif2pl_brkValid(S_IF);
    
    -- Copy the instruction fetch result into the pipeline.
    s(S_IF+L_IF).syllable := imem2pl_syllable(S_IF+L_IF);
    s(S_IF+L_IF).tr.trap  := s(S_IF+L_IF).tr.trap & imem2pl_exception(S_IF+L_IF);
    
    ---------------------------------------------------------------------------
    -- Perform basic instruction decoding
    ---------------------------------------------------------------------------
    -- Decode opcode.
    s(S_IF+L_IF).opcode   := s(S_IF+L_IF).syllable(rvex_opcode_type'range);
    
    -- Decode branch offset immediate.
    s(S_IF+L_IF).br.branchOffset := (
      31 downto 22 => s(S_IF+L_IF).syllable(23), -- Replicate sign bit.
      others       => '0'                        -- Zeros appended after value.
    );
    s(S_IF+L_IF).br.branchOffset(21 downto 3)
      := s(S_IF+L_IF).syllable(23 downto 5);     -- Actual value.
    
    -- Decode use-immediate control flag.
    s(S_IF+L_IF).dp.useImm
      := s(S_IF+L_IF).syllable(23);
    
    -- Decode arithmetic immediate.
    s(S_IF+L_IF).dp.imm(31 downto 9) := (
      others       => s(S_IF+L_IF).syllable(10)  -- Replicate sign bit.
    );
    s(S_IF+L_IF).dp.imm(8 downto 0)
      := s(S_IF+L_IF).syllable(10 downto 2);     -- Value.
    
    -- Decode datapath control signals. We do this in every stage where the
    -- signal is valid to save a couple registers. The decoding logic won't
    -- actually be replicated for every stage because each control signal is
    -- only used in a single stage.
    for stage in S_IF+L_IF to S_LAST loop
      s(stage).dp.c := OPCODE_TABLE(vect2uint(s(stage).opcode)).datapathCtrl;
    end loop;
    
    -- Determine the general purpose source register for port A.
    if s(S_RD).dp.c.stackOp = '1' then
      s(S_RD).dp.src1 := GPREG_STACK;
    else
      s(S_RD).dp.src1 := s(S_RD).syllable(16 downto 11);
    end if;
    
    -- Determine the general purpose source register for port B.
    if s(S_RD).dp.useImm = '1' then
      s(S_RD).dp.src2 := s(S_RD).syllable(22 downto 17);
    else
      s(S_RD).dp.src2 := s(S_RD).syllable(10 downto  5);
    end if;
    
    -- Determine the branch source register.
    if s(S_SRD).dp.c.brFmt = '1' then
      s(S_SRD).dp.srcBr := s(S_SRD).syllable(26 downto 24);
    else
      s(S_SRD).dp.srcBr := s(S_SRD).syllable( 4 downto  2);
    end if;
    
    -- Determine the general purpose destination register.
    if s(S_RD).dp.c.stackOp = '1' then
      s(S_RD).dp.dest := GPREG_STACK;
    else
      s(S_RD).dp.dest := s(S_RD).syllable(22 downto 17);
    end if;
    
    -- Determine whether we should write to the general purpose register file
    -- or the link register.
    if CFG.reg63isLink and (s(S_RD).dp.dest = GPREG_LINK) then
      s(S_RD).dp.gpRegWE_lo := '0';
      s(S_RD).dp.linkWE_lo  := s(S_RD).dp.c.gpRegWE or s(S_RD).dp.c.linkWE;
    else
      s(S_RD).dp.gpRegWE_lo := s(S_RD).dp.c.gpRegWE;
      s(S_RD).dp.linkWE_lo  := s(S_RD).dp.c.linkWE;
    end if;
    
    -- Determine the branch destination register.
    if s(S_SRD).dp.c.brFmt = '1' then
      s(S_SRD).dp.destBr := s(S_SRD).syllable( 4 downto  2);
    else
      s(S_SRD).dp.destBr := s(S_SRD).syllable(19 downto 17);
    end if;
    
    ---------------------------------------------------------------------------
    -- Test for illegal instructions
    ---------------------------------------------------------------------------
    -- Figure out if the opcode is known or not.
    if s(S_IF+L_IF).dp.useImm = '1' then
      flag
        := OPCODE_TABLE(vect2uint(s(S_IF+L_IF).opcode)).valid(1);
    else
      flag
        := OPCODE_TABLE(vect2uint(s(S_IF+L_IF).opcode)).valid(0);
    end if;
    
    -- If we don't have a branch unit, make sure this is not a branch
    -- operation.
    if (not HAS_BR) or cfg2pl_decouple = '0' then
      if OPCODE_TABLE(vect2uint(s(S_IF+L_IF).opcode)).branchCtrl.isBranchInstruction = '1' then
        flag := '1';
      end if;
    end if;
    
    -- If we don't have a memory unit, make sure this is not a memory
    -- operation.
    if (not HAS_MEM) or cfg2pl_decouple = '0' then
      if OPCODE_TABLE(vect2uint(s(S_IF+L_IF).opcode)).memoryCtrl.isMemoryInstruction = '1' then
        flag := '1';
      end if;
    end if;
    
    -- If we don't have a multiplier, make sure this is not a multiply
    -- operation.
    if not HAS_MUL then
      if OPCODE_TABLE(vect2uint(s(S_IF+L_IF).opcode)).multiplierCtrl.isMultiplyInstruction = '1' then
        flag := '1';
      end if;
    end if;
    
    -- Append the illegal opcode exception to the trap listing if our flag is
    -- set.
    if flag = '1' and s(S_IF+L_IF).valid = '1' then
      s(S_IF+L_IF).tr.trap := s(S_IF+L_IF).tr.trap & (
        active => '1',
        cause  => rvex_trap(RVEX_TRAP_INVALID_OP),
        arg    => s(S_IF+L_IF).lanePC
      );
    end if;
    
    ---------------------------------------------------------------------------
    -- Perform LIMMH forwarding
    ---------------------------------------------------------------------------
    -- Forward control signals to the LIMMH routing unit.
    pl2limm_valid(S_LIMM)  <= s(S_LIMM).limmValid;
    pl2limm_enable(S_LIMM) <= s(S_LIMM).dp.c.isLIMMH;
    pl2limm_target(S_LIMM) <= s(S_LIMM).syllable(25);
    pl2limm_data(S_LIMM)   <= s(S_LIMM).syllable(rvex_limmh_type'range);
    
    -- Use the flag as LIMMH error flag.
    flag := limm2pl_error(S_LIMM);
    
    -- Append forwarded data returned by the routing unit to our lane.
    if limm2pl_enable(S_LIMM) = '1' then
      s(S_LIMM).dp.imm(rvex_limmh_type'range) := limm2pl_data(S_LIMM);
      
      -- Trigger the LIMMH trap when we're receiving a long immediate but are
      -- not using it.
      if s(S_LIMM).dp.useImm = '0' then
        flag := '1';
      end if;
      
    end if;
    
    -- Trigger a LIMMH trap if the error flag is set.
    if flag = '1' then
      s(S_LIMM).tr.trap := s(S_LIMM).tr.trap & (
        active => '1',
        cause  => rvex_trap(RVEX_TRAP_LIMMH_FAULT),
        arg    => s(S_LIMM).lanePC
      );
    end if;
    
    ---------------------------------------------------------------------------
    -- Handle register reads
    ---------------------------------------------------------------------------
    -- Drive the general purpose register addresses for each forwarded stage.
    for stage in S_RD to S_FW loop
      pl2gpreg_readPortA.addr(stage) <= s(stage).dp.src1;
      pl2gpreg_readPortB.addr(stage) <= s(stage).dp.src2;
    end loop;
    
    -- Copy the read values into the pipeline for each forwarded stage. Only
    -- copy the value when it is valid, retain the previous value when it isn't
    -- (necessary for forwarding logic). When the ZERO register is selected,
    -- override the value from the register file with zero.
    for stage in S_RD+L_RD to S_FW loop
      
      -- Read port A.
      if s(stage).dp.src1 = GPREG_ZERO then
        s(stage).dp.read1 := (others => '0');
      else
        if gpreg2pl_readPortA.valid(stage) = '1' then
          s(stage).dp.read1 := gpreg2pl_readPortA.data(stage);
        end if;
      end if;
      
      -- Read port B.
      if s(stage).dp.src2 = GPREG_ZERO then
        s(stage).dp.read2 := (others => '0');
      else
        if gpreg2pl_readPortB.valid(stage) = '1' then
          s(stage).dp.read2 := gpreg2pl_readPortB.data(stage);
        end if;
      end if;
      
    end loop;
    
    -- Copy the branch and link register read data into the pipeline for each
    -- forwarded stage.
    for stage in S_SRD to S_SFW loop
      
      -- Branch register.
      s(stage).dp.readBr
        := cxplif2pl_brLinkReadPort.brData(stage)(
          vect2uint(s(stage).dp.srcBr)
        );
      
      -- Link register.
      s(stage).dp.readLink
        := cxplif2pl_brLinkReadPort.linkData(stage);
      
    end loop;
    
    ---------------------------------------------------------------------------
    -- Instantiate operand selection logic
    ---------------------------------------------------------------------------
    -- Select the integer operands to use.
    for stage in min_nat(S_RD+L_RD, S_SRD) to max_nat(S_FW, S_SFW) loop
      
      -- Select read1lo and read2lo. This is just read1 and read2 respectively,
      -- but overridden by the link register when CFG.reg63isLink is set and
      -- register 63 is selected.
      if CFG.reg63isLink and s(stage).dp.src1 = GPREG_LINK then
        s(stage).dp.read1lo := s(stage).dp.readLink;
      else
        s(stage).dp.read1lo := s(stage).dp.read1;
      end if;
      
      if CFG.reg63isLink and s(stage).dp.src2 = GPREG_LINK then
        s(stage).dp.read2lo := s(stage).dp.readLink;
      else
        s(stage).dp.read2lo := s(stage).dp.read2;
      end if;
      
      -- Select operand 1.
      if s(stage).dp.c.op1LinkReg = '1' then
        s(stage).dp.op1 := s(stage).dp.readLink;
      else
        s(stage).dp.op1 := s(stage).dp.read1lo;
      end if;
      
      -- Select operand 2. When using the branch offset, shift right by 3
      -- because the 3 LSB of the branch offset are tied to 0 and we want to
      -- be able to update the stack pointer byte-oriented.
      if s(stage).dp.c.stackOp = '1' then
        s(stage).dp.op2(28 downto 0) := s(stage).br.branchOffset(31 downto 3);
        s(stage).dp.op2(31 downto 29) := (others => s(stage).br.branchOffset(31));
      elsif s(stage).dp.useImm = '1' then
        s(stage).dp.op2 := s(stage).dp.imm;
      else
        s(stage).dp.op2 := s(stage).dp.read2lo;
      end if;
      
      -- Select operand 3 (memory write data, in which case op1 and op2 are
      -- added to get the address).
      if s(stage).dp.c.op3LinkReg = '1' then
        s(stage).dp.op3 := s(stage).dp.readLink;
      else
        s(stage).dp.op3 := s(stage).dp.read2lo;
      end if;
      
    end loop;
    
    -- Select the branch operands to use.
    for stage in S_SRD to S_SFW loop
      
      -- There is no muxing here, just copy the value read from the branch
      -- register file.
      s(stage).dp.opBr := s(stage).dp.readBr;
      
    end loop;
    
    ---------------------------------------------------------------------------
    -- Determine PC + 1 and PC-relative branch target.
    ---------------------------------------------------------------------------
    if HAS_BR then
      
      -- Determine the logarithm of what needs to be added to the PC and what
      -- the PC needs to be aligned to.
      i := SYLLABLE_SIZE_LOG2B                         -- Instr. size per lane.
         + (CFG.numLanesLog2 - CFG.numLaneGroupsLog2)  -- Lanes per group.
         + vect2uint(cfg2pl_numGroupsLog2);            -- Number of coupled groups.
      
      -- Perform the addition.
      s(S_PCP1).br.PC_plusOne := std_logic_vector(
        vect2unsigned(s(S_PCP1).PC)
        + to_unsigned(2**i, rvex_address_type'length)
      );
      
      -- Align the new PC.
      s(S_PCP1).br.PC_plusOne(i-1 downto 0) := (others => '0');
      
      -- Add branch offset to PC + 1 to get the relative branch target.
      s(S_BTGT).br.relativeTarget := std_logic_vector(
        vect2unsigned(s(S_BTGT).br.PC_plusOne)
        + unsigned(s(S_BTGT).br.branchOffset)
      );
      
    end if;
    
    ---------------------------------------------------------------------------
    -- Handle trap forwarding
    ---------------------------------------------------------------------------
    if HAS_BR then
      
      -- Copy the merged and forwarded trap information from the trap routing
      -- unit into the pipeline.
      s(S_TRAP).br.trapInfo     := trap2pl_trapToHandle(S_TRAP);
      s(S_TRAP).br.trapPending  := trap2pl_trapPending(S_TRAP);
      
      -- Forward the trap point and handler ourselves.
      s(S_TRAP).br.trapPoint    := s(S_LTRP).PC;
      s(S_TRAP).br.trapHandler  := s(S_LTRP).tr.trapHandler;
      
    end if;
    
    ---------------------------------------------------------------------------
    -- Connect pipeline to branch unit
    ---------------------------------------------------------------------------
    if HAS_BR then
      
      -- Load link target from the link register read data.
      s(S_BR).br.linkTarget := s(S_BR).dp.readLink;
      
      -- Drive branch unit data and control signals.
      pl2br_opcode(S_BR)              <= s(S_BR).opcode;
      pl2br_PC_plusOne_IFP1(S_IF+1)   <= s(S_IF+1).br.PC_plusOne;
      pl2br_PC_plusOne_BR(S_BR)       <= s(S_BR).br.PC_plusOne;
      pl2br_brTgtLink(S_BR)           <= s(S_BR).br.linkTarget;
      pl2br_brTgtRel(S_BR)            <= s(S_BR).br.relativeTarget;
      pl2br_opBr(S_BR)                <= s(S_BR).dp.opBr;
      pl2br_trapPending(S_BR)         <= s(S_BR).br.trapPending;
      pl2br_trapToHandleInfo(S_BR)    <= s(S_BR).br.trapInfo;
      pl2br_trapToHandlePoint(S_BR)   <= s(S_BR).br.trapPoint;
      pl2br_trapToHandleHandler(S_BR) <= s(S_BR).br.trapHandler;
      
      -- Copy the RFI flag into the pipeline and send it to the control
      -- registers in the memory phase.
      s(S_BR).br.RFI := br2pl_rfi(S_BR);
      pl2cxplif_rfi(S_MEM) <= s(S_MEM).br.RFI;
      
      -- Copy the trap output from the branch unit into the pipeline.
      s(S_BR).tr.trap := s(S_BR).tr.trap & br2pl_trap(S_BR);
      
    end if;
    
    ---------------------------------------------------------------------------
    -- Connect pipeline to ALU and optionally select PC+1 as integer result
    ---------------------------------------------------------------------------
    -- Drive ALU inputs.
    pl2alu_opcode(S_ALU)  <= s(S_ALU).opcode;
    pl2alu_op1(S_ALU)     <= s(S_ALU).dp.op1;
    pl2alu_op2(S_ALU)     <= s(S_ALU).dp.op2;
    pl2alu_opBr(S_ALU)    <= s(S_ALU).dp.opBr;
      
    -- Copy ALU integer outputs into pipeline.
    s(S_ALU+L_ALU1).dp.resAdd     := alu2pl_resultAdd(S_ALU+L_ALU1);
    s(S_ALU+L_ALU).dp.resALU      := alu2pl_result(S_ALU+L_ALU);
    
    -- Set the result and result valid bit if the ALU result is selected.
    if s(S_ALU+L_ALU).dp.c.funcSel = ALU then
      s(S_ALU+L_ALU).dp.res := s(S_ALU+L_ALU).dp.resALU;
      s(S_ALU+L_ALU).dp.resValid := s(S_ALU+L_ALU).dp.gpRegWE_lo;
      s(S_ALU+L_ALU).dp.resLinkValid := s(S_ALU+L_ALU).dp.linkWE_lo;
    end if;
    
    -- Copy ALU branch outputs into pipeline.
    i := vect2uint(s(S_ALU+L_ALU).dp.destBr);
    s(S_ALU+L_ALU).dp.resBr(i) := alu2pl_resultBr(S_ALU+L_ALU);
    s(S_ALU+L_ALU).dp.resBrValid(i) := s(S_ALU+L_ALU).dp.c.brRegWE;
    
    -- Set the result to PC+1 and the result valid bit to 1 when PC+1 is
    -- selected.
    if s(S_ALU+L_ALU).dp.c.funcSel = PCP1 then
      s(S_ALU+L_ALU).dp.res := s(S_ALU+L_ALU).br.PC_plusOne;
      s(S_ALU+L_ALU).dp.resValid := s(S_ALU+L_ALU).dp.gpRegWE_lo;
      s(S_ALU+L_ALU).dp.resLinkValid := s(S_ALU+L_ALU).dp.linkWE_lo;
    end if;
    
    ---------------------------------------------------------------------------
    -- Connect pipeline to multiplication unit
    ---------------------------------------------------------------------------
    if HAS_MUL then
      
      -- Drive multiplication unit inputs.
      pl2mulu_opcode(S_MUL) <= s(S_MUL).opcode;
      pl2mulu_op1(S_MUL)    <= s(S_MUL).dp.op1;
      pl2mulu_op2(S_MUL)    <= s(S_MUL).dp.op2;
      
      -- Copy multiplication unit output into pipeline.
      s(S_MUL+L_MUL).dp.resMul      := mulu2pl_result(S_MUL+L_MUL);
      
      -- Set the result and result valid bit if the MUL result is selected.
      if s(S_MUL+L_MUL).dp.c.funcSel = MUL then
        s(S_MUL+L_MUL).dp.res := s(S_MUL+L_MUL).dp.resMul;
        s(S_MUL+L_MUL).dp.resValid := s(S_MUL+L_MUL).dp.gpRegWE_lo;
        s(S_MUL+L_MUL).dp.resLinkValid := s(S_MUL+L_MUL).dp.linkWE_lo;
      end if;
      
    end if;
    
    ---------------------------------------------------------------------------
    -- Connect pipeline to memory unit result
    ---------------------------------------------------------------------------
    if HAS_MEM then
      
      -- Copy the result into the pipeline.
      s(S_MEM+L_MEM).dp.resMem := memu2pl_result(S_MEM+L_MEM);
      
      -- Set the result and result valid bit if the memory unit result is
      -- selected.
      if s(S_MEM+L_MEM).dp.c.funcSel = MEM then
        s(S_MEM+L_MEM).dp.res := s(S_MEM+L_MEM).dp.resMem;
        s(S_MEM+L_MEM).dp.resValid := s(S_MEM+L_MEM).dp.gpRegWE_lo;
        s(S_MEM+L_MEM).dp.resLinkValid := s(S_MEM+L_MEM).dp.linkWE_lo;
      end if;
      
      -- Copy the memory unit trap output into the pipeline.
      s(S_MEM).tr.trap
        := s(S_MEM).tr.trap & memu2pl_trap(S_MEM);
      
      -- Copy the data memory/cache trap output into the pipeline.
      s(S_MEM+L_MEM).tr.trap
        := s(S_MEM+L_MEM).tr.trap & dmsw2pl_exception(S_MEM+L_MEM);
      
    end if;
    
    ---------------------------------------------------------------------------
    -- Connect pipeline to breakpoint unit
    ---------------------------------------------------------------------------
    if HAS_BRK then
      
      -- Drive breakpoint unit inputs.
      pl2brku_ignoreBreakpoint(S_BRK) <= not s(S_BRK).brkValid;
      pl2brku_opcode(S_BRK)           <= s(S_BRK).opcode;
      pl2brku_opAddr(S_BRK)           <= s(S_BRK).dp.resAdd;
      pl2brku_PC_bundle(S_BRK)        <= s(S_BRK).PC;
      
      -- Copy the debug trap into the pipeline.
      s(S_BRK+L_BRK).tr.debugTrap :=
        s(S_BRK+L_BRK).tr.debugTrap & brku2pl_trap(S_BRK+L_BRK);
      
    end if;
    
    ---------------------------------------------------------------------------
    -- Handle soft trap instruction
    ---------------------------------------------------------------------------
    if s(S_BRK).dp.c.isTrap = '1' then
      
      -- Trigger a normal or debug trap depending on the trap cause (op2).
      if TRAP_TABLE(vect2uint(s(S_BRK).dp.op2(rvex_trap_type'range))).isDebugTrap = '1' then
        
        s(S_BRK).tr.debugTrap := s(S_BRK).tr.debugTrap & (
          active => '1',
          cause  => s(S_BRK).dp.op2(rvex_trap_type'range),
          arg    => s(S_BRK).dp.op1
        );
        
      else
        
        s(S_BRK).tr.trap := s(S_BRK).tr.trap & (
          active => '1',
          cause  => s(S_BRK).dp.op2(rvex_trap_type'range),
          arg    => s(S_BRK).dp.op1
        );
        
      end if;
      
    end if;
    
    ---------------------------------------------------------------------------
    -- Handle traps and instantiate invalidation logic related stuff
    ---------------------------------------------------------------------------
    -- Merge the debug traps with the regular traps, giving priority to the
    -- debug traps, if debug traps are enabled.
    if cxplif2pl_debugTrapEnable(S_MEM+1) = '1' then
      s(S_MEM+1).tr.trap := s(S_MEM+1).tr.debugTrap & s(S_MEM+1).tr.trap;
    end if;
    
    -- Append external interrupt trap in S_MEM+1 stage.
    if cxplif2pl_irq(S_MEM+1) = '1' then
      s(S_MEM+1).tr.trap := s(S_MEM+1).tr.trap & (
        active => '1',
        cause  => rvex_trap(RVEX_TRAP_EXT_INTERRUPT),
        arg    => (others => '0') -- Argument is set in the exact cycle where
      );                          -- the trap handler is entered.
    end if;
    
    -- Copy the current trap handler into the pipeline stage where it is valid,
    -- so it is properly forwarded to the branch unit.
    s(S_MEM+1).tr.trapHandler := cxplif2pl_trapHandler(S_MEM+1);
    
    -- Connect with the trap routing logic.
    for stage in S_FIRST to S_LTRP loop
      
      -- Forward the currently active trap to the trap routing logic.
      pl2trap_trap(stage) <= s(stage).tr.trap;
      
      -- Disable the current trap when a later pipeline stage overrides it
      -- (because it belongs to an earlier instruction).
      if trap2pl_disable(stage) = '1' then
        s(stage).tr.trap.active := '0';
      end if;
      
      -- Invalidate the current instruction when this or a later pipeline stage
      -- is trapped.
      if trap2pl_flush(stage) = '1' then
        s(stage).valid := '0';
      end if;
      
    end loop;
    
    -- Flush S_IF+1 through S_BR-1 when the branch unit takes a branch.
    if cxplif2pl_invalUntilBR(S_BR) = '1' then
      for stage in S_IF+1 to S_BR-1 loop
        s(stage).valid := '0';
      end loop;
    end if;
    
    -- Determine whether the pipeline is idle. Default to yes.
    idle := '1';
    
    -- The pipeline is not idle when there is a valid fetch somewhere in it.
    for stage in S_FIRST to S_LAST loop
      if s(stage).limmValid = '1' then
        idle := '0';
      end if;
    end loop;
    
    -- The pipeline is also not idle when a trap is pending.
    for stage in S_TRAP to S_BR loop
      if (s(stage).br.trapPending = '1') or (s(stage).br.trapInfo.active = '1') then
        idle := '0';
      end if;
    end loop;
    
    -- Drive idle output signals.
    pl2cxplif_blockReconfig <= not idle;
    pl2cxplif_idle          <= idle;
    
    ---------------------------------------------------------------------------
    -- Connect pipeline to memory unit command
    ---------------------------------------------------------------------------
    -- This must be done after trap handling because the memory operation
    -- should not be issued when a trap is detected in this stage. inb4
    -- critical path here.
    if HAS_MEM then
      
      pl2memu_valid(S_MEM)  <= s(S_MEM).valid;
      pl2memu_opcode(S_MEM) <= s(S_MEM).opcode;
      pl2memu_opAddr(S_MEM) <= s(S_MEM).dp.resAdd;
      pl2memu_opData(S_MEM) <= s(S_MEM).dp.op3;
      
    end if;
    
    ---------------------------------------------------------------------------
    -- Handle register writes and forwarding
    ---------------------------------------------------------------------------
    -- Drive the general purpose register data and forward enable signals.
    for stage in S_FIRST to S_WB+L_WB loop
      
      pl2gpreg_writePort.addr(stage)
        <= s(stage).dp.dest;
      
      pl2gpreg_writePort.data(stage)
        <= s(stage).dp.res;
      
      pl2gpreg_writePort.forwardEnable(stage)
        <= s(stage).dp.resValid;
      
    end loop;
    
    -- Drive the branch and link data and forward enable signals.
    for stage in S_FIRST to S_SWB loop
      
      pl2cxplif_brLinkWritePort.brData(stage)
        <= s(stage).dp.resBr;
      
      pl2cxplif_brLinkWritePort.linkData(stage)
        <= s(stage).dp.res;
      
      pl2cxplif_brLinkWritePort.brForwardEnable(stage)
        <= s(stage).dp.resBrValid;
      
      pl2cxplif_brLinkWritePort.linkForwardEnable(stage)
        <= s(stage).dp.resLinkValid;
      
    end loop;
    
    -- Drive the write enable signals.
    pl2gpreg_writePort.writeEnable(S_WB)
      <= s(S_WB).dp.resValid and s(S_WB).valid;
    
    for b in rvex_brRegData_type'range loop
      pl2cxplif_brLinkWritePort.brWriteEnable(S_SWB)(b)
        <= s(S_SWB).dp.resBrValid(b) and s(S_SWB).valid;
    end loop;
    
    pl2cxplif_brLinkWritePort.linkWriteEnable(S_SWB)
      <= s(S_SWB).dp.resLinkValid and s(S_SWB).valid;
    
    ---------------------------------------------------------------------------
    -- Generate VHDL simulation information
    ---------------------------------------------------------------------------
    -- pragma translate_off
    if GEN_VHDL_SIM_INFO then
      
      -- Copy branch unit information input pipeline and forward it in the last
      -- pipeline stage.
      if HAS_BR then
        s(S_IF).br.br2sim := br2pl_sim(S_IF);
      end if;
      br2sim <= s(S_LAST).br.br2sim;
      
      
      -- Generate instruction debug information
      -- --------------------------------------
      rvs_clear(debug);
      
      -- Display commit/trap information.
      if idle = '1' then
        rvs_append(debug, "idle; ");
      end if;
      if (s(S_LAST).valid = '1')
        or ((s(S_LAST).limmValid = '1') and (s(S_LAST).dp.c.isLIMMH = '1'))
      then
        rvs_append(debug, "committing ");
        if s(S_LAST).brkValid = '0' then
          rvs_append(debug, "(no brkpts) ");
        end if;
      elsif s(S_LAST).tr.trap.active = '1' then
        rvs_append(debug, prettyPrintTrap(s(S_LAST).tr.trap));
        rvs_append(debug, " occurred at ");
      else
        rvs_append(debug, "ignoring ");
      end if;
      
      -- Display PC for the current syllable.
      rvs_append(debug, rvs_hex(s(S_LAST).lanePC, 8));
      rvs_append(debug, " = ");
      
      -- Append disassembly.
      if HAS_BR then
        rvs_append(debug, disassemble(
          syllable    => s(S_LAST).syllable,
          limmh       => s(S_LAST).dp.imm,
          PC_plusOne  => s(S_LAST).br.PC_plusOne
        ));
      else
        rvs_append(debug, disassemble(
          syllable    => s(S_LAST).syllable,
          limmh       => s(S_LAST).dp.imm
        ));
      end if;
      
      -- Forward debug information.
      pl2sim_instr <= debug;
      
      
      -- Generate register/dmem access debug information
      -- -----------------------------------------------
      rvs_clear(debug);
      
      -- Use the general purpose flag to store whether we've written anything
      -- here yet.
      flag := '0';
      
      -- Save whether we're doing a memory access and whether it was
      -- successful or not.
      s(S_MEM).memRequested := s(S_MEM).valid = '1';
      if memu2pl_trap(S_MEM).active = '1' then
        s(S_MEM).memError := true;
      end if;
      if dmsw2pl_exception(S_MEM+L_MEM).active = '1' then
        s(S_MEM+L_MEM).memError := true;
      end if;
      
      -- Display memory operation, if one was performed.
      if s(S_LAST).memRequested then
        
        if OPCODE_TABLE(vect2uint(s(S_LAST).opcode)).memoryCtrl.writeEnable = '1' then
          rvs_append(debug, "mem(");
          rvs_append(debug, rvs_hex(s(S_LAST).dp.resAdd, 8));
          rvs_append(debug, ") := ");
          case OPCODE_TABLE(vect2uint(s(S_LAST).opcode)).memoryCtrl.accessSizeBLog2 is
            
            when ACCESS_SIZE_BYTE =>
              rvs_append(debug, rvs_hex(s(S_LAST).dp.op3(7 downto 0), 2));
              
            when ACCESS_SIZE_HALFWORD =>
              rvs_append(debug, rvs_hex(s(S_LAST).dp.op3(15 downto 0), 4));
            
            when others =>
              rvs_append(debug, rvs_hex(s(S_LAST).dp.op3, 8));
            
          end case;
        else
          rvs_append(debug, "read mem(");
          rvs_append(debug, rvs_hex(s(S_LAST).dp.resAdd, 8));
          rvs_append(debug, ")");
        end if;
        if s(S_LAST).memError then
          rvs_append(debug, " -> error");
        end if;
        
        -- We've written stuff to the debug information string.
        flag := '1';
        
      end if;
      
      -- Save whether we're writing to a general purpose register.
      s(S_WB).gpRegWriteRequested
        := s(S_WB).dp.resValid and s(S_WB).valid;
      
      -- Display information about the general purpose register write.
      if s(S_WB).gpRegWriteRequested = '1' then
        if flag = '0' then
          flag := '1';
        else
          rvs_append(debug, "; ");
        end if;
        rvs_append(debug, "r0." & integer'image(vect2uint(s(S_LAST).dp.dest)) & " := ");
        rvs_append(debug, rvs_hex(s(S_LAST).dp.res, 8));
      end if;
      
      -- Save whether we're writing to the link register.
      s(S_SWB).linkRegWriteRequested
        := s(S_SWB).dp.resLinkValid and s(S_SWB).valid;
      
      -- Display information about the link register write.
      if s(S_WB).linkRegWriteRequested = '1' then
        if flag = '0' then
          flag := '1';
        else
          rvs_append(debug, "; ");
        end if;
        rvs_append(debug, "l0.0 := ");
        rvs_append(debug, rvs_hex(s(S_LAST).dp.res, 8));
      end if;
      
      -- Show link register operations.
      for b in rvex_brRegData_type'range loop
        
        -- Save whether we're writing to this link register.
        s(S_SWB).brRegWriteRequested(b)
          := s(S_SWB).dp.resBrValid(b) and s(S_SWB).valid;
        
        -- Display information about the link register write.
        if s(S_WB).brRegWriteRequested(b) = '1' then
          if flag = '0' then
            flag := '1';
          else
            rvs_append(debug, "; ");
          end if;
          rvs_append(debug, "b0." & integer'image(b) & " := ");
          if s(S_LAST).dp.resBr(b) = '1' then
            rvs_append(debug, "1");
          else
            rvs_append(debug, "0");
          end if;
        end if;
        
      end loop;
      
      -- Make sure we display something if we haven't done so already.
      if flag = '0' then
        rvs_append(debug, "no ops performed");
      end if;
      
      -- Forward debug information.
      pl2sim_op <= debug;
      
    end if;
    -- pragma translate_on
    
    ---------------------------------------------------------------------------
    -- Drive stage outputs
    ---------------------------------------------------------------------------
    so <= s;
    
  end process;
  
end Behavioral;

