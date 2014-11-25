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

--=============================================================================
-- This entity contains all pipeline logic for the entire processor. Everything
-- but the register files and configuration control logic is instantiated in
-- here.
-------------------------------------------------------------------------------
entity rvex_pipelanes is
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
    
    -- Decouple vector. This is just another way to look at the coupled matrix.
    -- The vector is assigned such that dec_i = not C_i,i+1. The MSB in the
    -- vector is always high. This representation is useful because the bits
    -- can also be regarded as master/slave bits: when the decouple bit for
    -- a group is high, it is a master, otherwise it is a slave. Slaves answer
    -- to the next higher indexed master group.
    cfg2any_decouple            : in  std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Link from any pipelane group to to the first (lowest indexed) coupled
    -- group.
    cfg2any_firstGroup          : in  rvex_3bit_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Matrix specifying connections between context and lane group. Indexing is
    -- done using i = laneGroup*numContexts + context.
    cfg2any_contextMap          : in  std_logic_vector(2**CFG.numLaneGroupsLog2*2**CFG.numContextsLog2-1 downto 0);
    
    -- Last pipelane group associated with each context.
    cfg2any_lastGroupForCtxt    : in  rvex_3bit_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    ---------------------------------------------------------------------------
    -- Configuration and run control
    ---------------------------------------------------------------------------
    -- Run bit for each pipelane group from the configuration logic.
    cfg2pl_run                  : in  std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Active high reconfiguration block bit. When high, reconfiguration is
    -- not permitted. This is essentially an active low idle flag.
    pl2cfg_blockReconfig        : out std_logic_vector(2**CFG.numLanesLog2-1 downto 0);
    
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
    -- Instruction memory interface
    ---------------------------------------------------------------------------
    -- Addresses of the syllables to fetch for each group.
    br2imem_PCs                 : out rvex_address_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Active high fetch enable signal for each group.
    br2imem_fetch               : out std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Active high cancel signal for the previous fetch. This is a hint to the
    -- memory/cache that, if it would need to stall the core to fetch the
    -- previously requested opcode, it can stop the fetch and allow the core to
    -- continue.
    br2imem_cancel              : out std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Instruction bundle(s) from the instruction memory.
    imem2pl_instr               : in  rvex_syllable_array(2**CFG.numLanesLog2-1 downto 0);
    
    -- Exception input from instruction memory.
    imem2pl_exception           : in  trap_info_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    ---------------------------------------------------------------------------
    -- Data memory interface
    ---------------------------------------------------------------------------
    -- Data memory address, shared between read and write command.
    dmsw2dmem_addr              : out rvex_address_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Data memory write command.
    dmsw2dmem_writeData         : out rvex_data_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    dmsw2dmem_writeMask         : out rvex_mask_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    dmsw2dmem_writeEnable       : out std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Data memory read command and result.
    dmsw2dmem_readEnable        : out std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    dmem2dmsw_readData          : in  rvex_data_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Exception input from data memory.
    dmem2dmsw_exception         : in  trap_info_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    ---------------------------------------------------------------------------
    -- Control register interface
    ---------------------------------------------------------------------------
    -- Data memory address, shared between read and write command.
    dmsw2creg_addr              : out rvex_address_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Data memory write command.
    dmsw2creg_writeData         : out rvex_data_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    dmsw2creg_writeMask         : out rvex_mask_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    dmsw2creg_writeEnable       : out std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Data memory read command and result.
    dmsw2creg_readEnable        : out std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    creg2dmsw_readData          : in  rvex_data_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    ---------------------------------------------------------------------------
    -- Register file interface
    ---------------------------------------------------------------------------
    -- These signals are array'd outside this entity and contain pipeline
    -- configuration dependent data types, so they need to be put in records.
    -- The signals are documented in rvex_intIface_pkg.vhd, where the types are
    -- defined.
    
    -- General purpose register file read ports.
    pl2gpreg_readPorts          : out pl2gpreg_readPort_array(2*2**CFG.numLanesLog2-1 downto 0);
    gpreg2pl_readPorts          : in  gpreg2pl_readPort_array(2*2**CFG.numLanesLog2-1 downto 0);
    
    -- General purpose register file write ports.
    pl2gpreg_writePorts         : out pl2gpreg_writePort_array(2**CFG.numLanesLog2-1 downto 0);
    
    -- Branch/link register read port for each context.
    cxreg2cxplif_brLinkReadPort : in  cxreg2pl_readPort_array(2**CFG.numContextsLog2-1 downto 0);
    
    -- Branch/link register write port for each context.
    cxplif2cxreg_brLinkWritePort: out pl2cxreg_writePort_array(2**CFG.numContextsLog2-1 downto 0);
    
    ---------------------------------------------------------------------------
    -- Special context register interface
    ---------------------------------------------------------------------------
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
end rvex_pipelanes;

--=============================================================================
architecture Behavioral of rvex_pipelanes is
--=============================================================================
  
  -- Context to pipelane interface <-> pipelane interconnect signals.
  signal cxplif2pl_irq              : std_logic_vector  (2**CFG.numLanesLog2-1 downto 0);
  signal pl2cxplif_irqAck           : std_logic_vector  (2**CFG.numLanesLog2-1 downto 0);
  signal cxplif2pl_run              : std_logic_vector  (2**CFG.numLanesLog2-1 downto 0);
  signal pl2cxplif_idle             : std_logic_vector  (2**CFG.numLanesLog2-1 downto 0);
  signal cxplif2pl_brLinkReadPort   : cxreg2pl_readPort_array(2**CFG.numLanesLog2-1 downto 0);
  signal pl2cxplif_brLinkWritePort  : pl2cxreg_writePort_array(2**CFG.numLanesLog2-1 downto 0);
  signal br2cxplif_PC               : rvex_address_array(2**CFG.numLanesLog2-1 downto 0);
  signal cxplif2pl_bundlePC         : rvex_address_array(2**CFG.numLanesLog2-1 downto 0);
  signal cxplif2pl_lanePC           : rvex_address_array(2**CFG.numLanesLog2-1 downto 0);
  signal cxplif2pl_overridePC       : std_logic_vector  (2**CFG.numLanesLog2-1 downto 0);
  signal cxplif2pl_trapHandler      : rvex_address_array(2**CFG.numLanesLog2-1 downto 0);
  signal pl2cxplif_trapInfo         : trap_info_array   (2**CFG.numLanesLog2-1 downto 0);
  signal pl2cxplif_trapPoint        : trap_info_array   (2**CFG.numLanesLog2-1 downto 0);
  signal pl2cxplif_rfi              : std_logic_vector  (2**CFG.numLanesLog2-1 downto 0);
  signal br2cxplif_brk              : trap_info_array   (2**CFG.numLanesLog2-1 downto 0);
  signal cxplif2brku_breakpoints    : cxreg2pl_breakpoint_info_array(2**CFG.numLanesLog2-1 downto 0);
  signal cxplif2pl_ignoreBreakpoint : std_logic_vector  (2**CFG.numLanesLog2-1 downto 0);
  
  -- Data memory switch <-> pipelane interconnect signals.
  signal memu2dmsw_addr             : rvex_address_array(2**CFG.numLaneGroupsLog2-1 downto 0);
  signal memu2dmsw_writeData        : rvex_data_array   (2**CFG.numLaneGroupsLog2-1 downto 0);
  signal memu2dmsw_writeMask        : rvex_mask_array   (2**CFG.numLaneGroupsLog2-1 downto 0);
  signal memu2dmsw_writeEnable      : std_logic_vector  (2**CFG.numLaneGroupsLog2-1 downto 0);
  signal memu2dmsw_readEnable       : std_logic_vector  (2**CFG.numLaneGroupsLog2-1 downto 0);
  signal dmsw2memu_readData         : rvex_data_array   (2**CFG.numLaneGroupsLog2-1 downto 0);
  signal dmsw2pl_exception          : trap_info_array   (2**CFG.numLaneGroupsLog2-1 downto 0);
  
  -- Long immediate routing <-> pipelane interconnect signals.
  signal pl2limm_valid              : std_logic_vector  (2**CFG.numLanesLog2-1 downto 0);
  signal pl2limm_enable             : std_logic_vector  (2**CFG.numLanesLog2-1 downto 0);
  signal pl2limm_target             : std_logic_vector  (2**CFG.numLanesLog2-1 downto 0);
  signal pl2limm_data               : rvex_limmh_array  (2**CFG.numLanesLog2-1 downto 0);
  signal limm2pl_enable             : std_logic_vector  (2**CFG.numLanesLog2-1 downto 0);
  signal limm2pl_data               : rvex_limmh_array  (2**CFG.numLanesLog2-1 downto 0);
  signal limm2pl_error              : std_logic_vector  (2**CFG.numLanesLog2-1 downto 0);
  
  -- Trap routing <-> pipelane interconnect signals.
  signal pl2trap_trap               : trap_info_stages_array(2**CFG.numLanesLog2-1 downto 0);
  signal trap2pl_trapToHandle       : trap_info_array   (2**CFG.numLanesLog2-1 downto 0);
  signal trap2pl_trapPending        : trap_info_array   (2**CFG.numLanesLog2-1 downto 0);
  signal trap2pl_disable            : std_logic_stages_array(2**CFG.numLanesLog2-1 downto 0);
  signal trap2pl_flush              : std_logic_stages_array(2**CFG.numLanesLog2-1 downto 0);
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- Instantiate the pipelanes
  -----------------------------------------------------------------------------
  gen_lanes: for lane in 2**CFG.numLanesLog2-1 downto 0 generate
    
    -- Number of lanes in a lane group.
    constant LANES_PER_GROUP: natural := 2**(CFG.numLanesLog2 - CFG.numLaneGroupsLog2);
    
    -- Lane group which lane belongs to.
    constant laneGroup: natural := lane / LANES_PER_GROUP;
    
    -- Lane index within the group for lane.
    constant laneIndex: natural := lane mod LANES_PER_GROUP;
    
    -- Lane index counting down from the last lane in the group, such that 0 is
    -- the last lane in the group, 1 is the second to last lane, etc.
    constant laneIndexRev: natural := LANES_PER_GROUP - laneIndex - 1;
    
    -- Whether lane should have a multiplier.
    constant mul: boolean := ((CFG.multiplierLanes / 2**lane) mod 2) = 1;
    
    -- Whether lane should have a memory unit. This is assumed to be the
    -- second-to-last lane in a generic binary bundle, so the second-to-last
    -- lane in each group needs to have a memory unit. In order to somewhat
    -- handle having only 1 lane per group, we always instantiate a memory unit
    -- in that case.
    constant mem: boolean := (laneIndexRev = 1) or (LANES_PER_GROUP = 1);
    
    -- Whether lane should have a breakpoint unit. We instantiate a breakpoint
    -- unit for each lane which has a memory unit if breakpoints are enabled.
    constant brk: boolean := mem and (CFG.numBreakpoints > 0);
    
    -- Whether lane should have a branch unit. Branches should always be in the
    -- last syllable of a generic binary bundle, so the last lane within a
    -- group should have a branch unit.
    constant br: boolean := laneIndexRev = 0;
    
  begin
    
    lane_n: entity work.rvex_pipelane
      generic map (
        
        -- Lane configuration.
        HAS_MUL                         => mul,
        HAS_MEM                         => mem,
        HAS_BRK                         => brk,
        HAS_BR                          => br
        
      )
      port map (
        
        -- System control.
        reset                           => reset,
        clk                             => clk,
        clkEn                           => clkEn,
        stall                           => stall(laneGroup),
        
        -- Configuration and run control.
        cfg2pl_decouple                 => cfg2any_decouple(laneGroup),
        cfg2pl_run                      => cfg2pl_run(laneGroup),
        pl2cfg_blockReconfig            => pl2cfg_blockReconfig(lane),
        cxplif2pl_irq(S_MEM+1)          => cxplif2pl_irq(lane),
        pl2cxplif_irqAck(S_MEM)         => pl2cxplif_irqAck(lane),
        cxplif2pl_run                   => cxplif2pl_run(lane),
        pl2cxplif_idle                  => pl2cxplif_idle(lane),
        
        -- Instruction memory interface.
        br2imem_PC(S_IF)                => br2imem_PCs(laneGroup),
        br2imem_fetch(S_IF)             => br2imem_fetch(laneGroup),
        br2imem_cancel(S_IF+L_IF)       => br2imem_cancel(laneGroup),
        imem2pl_syllable(S_IF+L_IF)     => imem2pl_instr(lane),
        imem2pl_exception(S_IF+L_IF)    => imem2pl_exception(laneGroup),
        
        -- Data memory interface.
        memu2dmsw_addr(S_MEM)           => memu2dmsw_addr(laneGroup),
        memu2dmsw_writeData(S_MEM)      => memu2dmsw_writeData(laneGroup),
        memu2dmsw_writeMask(S_MEM)      => memu2dmsw_writeMask(laneGroup),
        memu2dmsw_writeEnable(S_MEM)    => memu2dmsw_writeEnable(laneGroup),
        memu2dmsw_readEnable(S_MEM)     => memu2dmsw_readEnable(laneGroup),
        dmsw2memu_readData(S_MEM+L_MEM) => dmsw2memu_readData(laneGroup),
        dmsw2pl_exception(S_MEM+L_MEM)  => dmsw2pl_exception(laneGroup),
        
        -- Register file interface.
        pl2gpreg_readPortA              => pl2gpreg_readPorts(lane*2+0),
        gpreg2pl_readPortA              => gpreg2pl_readPorts(lane*2+0),
        pl2gpreg_readPortB              => pl2gpreg_readPorts(lane*2+1),
        gpreg2pl_readPortB              => gpreg2pl_readPorts(lane*2+1),
        pl2gpreg_writePort              => pl2gpreg_writePorts(lane),
        cxplif2pl_brLinkReadPort        => cxplif2pl_brLinkReadPort(lane),
        pl2cxplif_brLinkWritePort       => pl2cxplif_brLinkWritePort(lane),
        
        -- Special context register interface.
        br2cxplif_PC(S_IF)              => br2cxplif_PC(lane),
        cxplif2pl_bundlePC(S_IF+1)      => cxplif2pl_bundlePC(lane),
        cxplif2pl_lanePC(S_IF+1)        => cxplif2pl_lanePC(lane),
        cxplif2pl_overridePC(S_IF+1)    => cxplif2pl_overridePC(lane),
        cxplif2pl_trapHandler(S_MEM+1)  => cxplif2pl_trapHandler(lane),
        pl2cxplif_trapInfo(S_BR)        => pl2cxplif_trapInfo(lane),
        pl2cxplif_trapPoint(S_BR)       => pl2cxplif_trapPoint(lane),
        pl2cxplif_rfi(S_MEM)            => pl2cxplif_rfi(lane),
        br2cxplif_brk(S_BR)             => br2cxplif_brk(lane),
        cxplif2brku_breakpoints         => cxplif2brku_breakpoints(lane),
        cxplif2pl_ignoreBreakpoint(S_IF)=> cxplif2pl_ignoreBreakpoint(lane),
        
        -- Long immediate routing interface.
        pl2limm_valid(S_LIMM)           => pl2limm_valid(lane),
        pl2limm_enable(S_LIMM)          => pl2limm_enable(lane),
        pl2limm_target(S_LIMM)          => pl2limm_target(lane),
        pl2limm_data(S_LIMM)            => pl2limm_data(lane),
        limm2pl_enable(S_LIMM)          => limm2pl_enable(lane),
        limm2pl_data(S_LIMM)            => limm2pl_data(lane),
        limm2pl_error(S_LIMM)           => limm2pl_error(lane),
        
        -- Trap routing interface.
        pl2trap_trap                    => pl2trap_trap(lane),
        trap2pl_trapToHandle(S_TRAP)    => trap2pl_trapToHandle(lane),
        trap2pl_trapPending(S_TRAP)     => trap2pl_trapPending(lane),
        trap2pl_disable                 => trap2pl_disable(lane),
        trap2pl_flush                   => trap2pl_flush(lane)
        
      );
    
  end generate; -- for each lane
  
  -----------------------------------------------------------------------------
  -- Instantiate context to pipelane interface
  -----------------------------------------------------------------------------
  context_pipelane_iface: entity work.rvex_contextPipelaneIFace
    generic map (
      CFG                               => CFG
    )
    port map (
      
      -- System control.
      reset                             => reset,
      clk                               => clk,
      clkEn                             => clkEn,
      stall                             => stall,
      
      -- Decoded configuration signals.
      cfg2any_coupled                   => cfg2any_coupled,
      cfg2any_contextMap                => cfg2any_contextMap,
      cfg2any_lastGroupForCtxt          => cfg2any_lastGroupForCtxt,
      
      -- Pipelane interface.
      cxplif2pl_irq                     => cxplif2pl_irq,
      pl2cxplif_irqAck                  => pl2cxplif_irqAck,
      cxplif2pl_run                     => cxplif2pl_run,
      pl2cxplif_idle                    => pl2cxplif_idle,
      cxplif2pl_brLinkReadPort          => cxplif2pl_brLinkReadPort,
      pl2cxplif_brLinkWritePort         => pl2cxplif_brLinkWritePort,
      br2cxplif_PC                      => br2cxplif_PC,
      cxplif2pl_bundlePC                => cxplif2pl_bundlePC,
      cxplif2pl_lanePC                  => cxplif2pl_lanePC,
      cxplif2pl_overridePC              => cxplif2pl_overridePC,
      cxplif2pl_trapHandler             => cxplif2pl_trapHandler,
      pl2cxplif_trapInfo                => pl2cxplif_trapInfo,
      pl2cxplif_trapPoint               => pl2cxplif_trapPoint,
      pl2cxplif_rfi                     => pl2cxplif_rfi,
      br2cxplif_brk                     => br2cxplif_brk,
      cxplif2brku_breakpoints           => cxplif2brku_breakpoints,
      cxplif2pl_ignoreBreakpoint        => cxplif2pl_ignoreBreakpoint,
      
      -- Run control interface.
      rctrl2cxplif_irq                  => rctrl2cxplif_irq,
      cxplif2rctrl_irqAck               => cxplif2rctrl_irqAck,
      rctrl2cxplif_run                  => rctrl2cxplif_run,
      cxplif2rctrl_idle                 => cxplif2rctrl_idle,
      
      -- Context register interface.
      cxreg2cxplif_brLinkReadPort       => cxreg2cxplif_brLinkReadPort,
      cxplif2cxreg_brLinkWritePort      => cxplif2cxreg_brLinkWritePort,
      cxplif2cxreg_PC                   => cxplif2cxreg_PC,
      cxreg2cxplif_PC                   => cxreg2cxplif_PC,
      cxreg2cxplif_overridePC           => cxreg2cxplif_overridePC,
      cxreg2cxplif_trapHandler          => cxreg2cxplif_trapHandler,
      cxplif2cxreg_trapInfo             => cxplif2cxreg_trapInfo,
      cxplif2cxreg_trapPoint            => cxplif2cxreg_trapPoint,
      cxplif2cxreg_rfi                  => cxplif2cxreg_rfi,
      cxplif2cxreg_brk                  => cxplif2cxreg_brk,
      cxreg2cxplif_brk                  => cxreg2cxplif_brk,
      cxreg2cxplif_breakpoints          => cxreg2cxplif_breakpoints,
      cxreg2cxplif_ignoreBreakpoint     => cxreg2cxplif_ignoreBreakpoint
      
    );
  
    
  -----------------------------------------------------------------------------
  -- Instantiate data memory/control register switches
  -----------------------------------------------------------------------------
  gen_dmem_switches: for laneGroup in 2**CFG.numLaneGroupsLog2-1 downto 0 generate
    
    dmem_switch_n: entity work.rvex_dmemSwitch
      generic map (
        CFG                             => CFG
      )
      port map (
        
        -- System control.
        reset                           => reset,
        clk                             => clk,
        clkEn                           => clkEn,
        stall                           => stall(laneGroup),
        
        ---------------------------------------------------------------------------
        -- Pipelane interface
        ---------------------------------------------------------------------------
        -- Data memory address, shared between read and write command.
        memu2dmsw_addr(S_MEM)           => memu2dmsw_addr(laneGroup),
        
        -- Data memory write command.
        memu2dmsw_writeData(S_MEM)      => memu2dmsw_writeData(laneGroup),
        memu2dmsw_writeMask(S_MEM)      => memu2dmsw_writeMask(laneGroup),
        memu2dmsw_writeEnable(S_MEM)    => memu2dmsw_writeEnable(laneGroup),
        
        -- Data memory read command and result.
        memu2dmsw_readEnable(S_MEM)     => memu2dmsw_readEnable(laneGroup),
        dmsw2memu_readData(S_MEM+L_MEM) => dmsw2memu_readData(laneGroup),
        
        -- Exception input from data memory.
        dmsw2pl_exception(S_MEM+L_MEM)  => dmsw2pl_exception(laneGroup),
        
        ---------------------------------------------------------------------------
        -- Data memory interface
        ---------------------------------------------------------------------------
        -- Data memory address, shared between read and write command.
        dmsw2dmem_addr(S_MEM)           => dmsw2dmem_addr(laneGroup),
        
        -- Data memory write command.
        dmsw2dmem_writeData(S_MEM)      => dmsw2dmem_writeData(laneGroup),
        dmsw2dmem_writeMask(S_MEM)      => dmsw2dmem_writeMask(laneGroup),
        dmsw2dmem_writeEnable(S_MEM)    => dmsw2dmem_writeEnable(laneGroup),
        
        -- Data memory read command and result.
        dmsw2dmem_readEnable(S_MEM)     => dmsw2dmem_readEnable(laneGroup),
        dmem2dmsw_readData(S_MEM+L_MEM) => dmem2dmsw_readData(laneGroup),
        
        -- Exception input from data memory.
        dmem2dmsw_exception(S_MEM+L_MEM)=> dmem2dmsw_exception(laneGroup),
        
        ---------------------------------------------------------------------------
        -- Control register interface
        ---------------------------------------------------------------------------
        -- Data memory address, shared between read and write command.
        dmsw2creg_addr(S_MEM)           => dmsw2creg_addr(laneGroup),
        
        -- Data memory write command.
        dmsw2creg_writeData(S_MEM)      => dmsw2creg_writeData(laneGroup),
        dmsw2creg_writeMask(S_MEM)      => dmsw2creg_writeMask(laneGroup),
        dmsw2creg_writeEnable(S_MEM)    => dmsw2creg_writeEnable(laneGroup),
        
        -- Data memory read command and result. Note that the latency is fixed to
        -- one cycle for the control register read data.
        dmsw2creg_readEnable(S_MEM)     => dmsw2creg_readEnable(laneGroup),
        creg2dmsw_readData(S_MEM+1)     => creg2dmsw_readData(laneGroup)
        
      );
    
  end generate; -- for each lane group
  
  -----------------------------------------------------------------------------
  -- Instantiate LIMM routing network
  -----------------------------------------------------------------------------
  limm_routing: entity work.rvex_limmRouting
    generic map (
      CFG                       => CFG
    )
    port map (
      
      -- System control.
      reset                     => reset,
      clk                       => clk,
      clkEn                     => clkEn,
      stall                     => stall,
      
      -- Decoded configuration signals.
      cfg2any_coupled           => cfg2any_coupled,
      cfg2any_firstGroup        => cfg2any_firstGroup,
      
      -- Pipelane interface.
      pl2limm_valid             => pl2limm_valid,
      pl2limm_enable            => pl2limm_enable,
      pl2limm_target            => pl2limm_target,
      pl2limm_data              => pl2limm_data,
      limm2pl_enable            => limm2pl_enable,
      limm2pl_data              => limm2pl_data,
      limm2pl_error             => limm2pl_error
      
    );
  
  -----------------------------------------------------------------------------
  -- Instantiate trap routing network
  -----------------------------------------------------------------------------
  trap_routing: entity work.rvex_trapRouting
    generic map (
      CFG                       => CFG
    )
    port map (
      
      -- Decoded configuration signals.
      cfg2any_coupled           => cfg2any_coupled,
      
      -- Pipelane interface.
      pl2trap_trap              => pl2trap_trap,
      trap2pl_trapToHandle      => trap2pl_trapToHandle,
      trap2pl_trapPending       => trap2pl_trapPending,
      trap2pl_disable           => trap2pl_disable,
      trap2pl_flush             => trap2pl_flush
      
    );
  
end Behavioral;

