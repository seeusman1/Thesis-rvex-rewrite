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
use rvex.utils_pkg.all;
use rvex.core_pkg.all;
use rvex.core_intIface_pkg.all;
use rvex.core_trap_pkg.all;

-- pragma translate_off
use rvex.simUtils_pkg.all;
-- pragma translate_on


  -----------------------------------------------------------------------------
  -- Processor overview and naming conventions
  -----------------------------------------------------------------------------
  -- The figure below shows how the rvex core is organized. The abbreviations
  -- used are keyed below.
  -- 
  -- . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
  --
  --          .---------------------------------------------------.
  --          | rv                                                |
  --          | .---------------------------------------.         |
  --          | | pls (pipelanes)                       |         |
  --          | |  .=================================.  | .-----. |
  --          | |  | pl (pipelane)                   |  | |gpreg| |
  --          | |  |  - . .---.  - - .  - - .  - - . |  | |.===.| |
  --          | |  | |br  |alu| |mulu  |memu  |brku  |<-+>||fwd|| |
  --          | |  |  - ' '---'  - - '  - - '  - - ' |  | |'==='| |
  --          | |  '================================='  | '-----' |
  --          | |    ^           ^        ^       ^     |    ^    |
  --          | |    v           |        |       |     |    |    |
  --          | | .------.       v        v       v     |    |    |
  --  imem <--+-+>|cxplif|     .====.   .----.  .----.  |    |    |
  --          | | |.===. |     |dmsw|   |trap|  |limm|  |    |    |
  --          | | ||fwd| |     '===='   '----'  '----'  |    |    |
  -- rctrl <--+-+>|'===' |      ^  ^                    |    |    |
  --          | | '------'      |  '--------------------+----+----+--> dmem
  --          | |    ^          |                       |    |    |
  --          | '----+----------+-----------------------'    |    |
  --          |      |          |                            |    |
  --          |      |          |  .-------------------------'    |
  --          |      v          v  v                              |
  -- rctrl    |   .=====.      .----.      .-----.      .-----.   |
  -- reset <--+-->|cxreg|<---->|creg|<---->|gbreg|<---->|     |<--+--> mem
  -- and done |   '====='      '----'      '-----'      | cfg |   |
  --          |      |            ^           ^   ...<--|     |   |
  --          |      '------------+-----------+-------->|     |   |
  --          |                   |           |         '-----'   |--> sim
  --          '-------------------+-----------+-------------------'
  --                              |           |
  --                              v           |
  --                             dbg    imem affinity
  --
  -- . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
  --
  -- The abbreviations for the blocks used in the diagram are the following.
  -- 
  --  - rv     = RVex processor             @ core.vhd
  --  - pls    = PipeLaneS                  @ core_pipelanes.vhd
  --  - pl     = PipeLane                   @ core_pipelane.vhd
  --  - br     = BRanch unit                @ core_branch.vhd
  --  - alu    = Arith. Logic Unit          @ core_alu.vhd
  --  - memu   = MEMory Unit                @ core_memu.vhd
  --  - mulu   = MULtiply Unit              @ core_mulu.vhd
  --  - brku   = BReaKpoint Unit            @ core_breakpoint.vhd
  --  - gpreg  = General Purpose REGisters  @ core_gpRegs.vhd
  --  - fwd    = ForWarDing logic           @ core_forward.vhd
  --  - cxplif = ConteXt-PipeLane InterFace @ core_contextPipelaneIFace.vhd
  --  - dmsw   = Data Memory SWitch         @ core_dmemSwitch.vhd
  --  - trap   = TRAP routing               @ core_trapRouting.vhd
  --  - limm   = Long IMMediate routing     @ core_limmRouting.vhd
  --  - cxreg  = ConteXt REGister logic     @ core_contextRegLogic.vhd
  --  - creg   = Control REGisters          @ core_ctrlRegs.vhd
  --  - gbreg  = GloBal REGister logic      @ core_globalRegLogic.vhd
  --  - cfg    = ConFiGuration control      @ core_cfgCtrl.vhd
  --  - mem    = interface common to instruction and data MEMory/cache
  --  - imem   = Instruction MEMory/cache
  --  - dmem   = Data MEMory/cache
  --  - dbg    = DeBuG bus interface
  --  - rctrl  = Run ConTRoL
  --  - sim    = vhdl SIMulation only
  --
  -- The pipelane (pl), ALU and multiplier blocks are instantiated for each
  -- pipelane (although the multiplier can be disabled for selected pipelanes
  -- through design-time configuration). The memory unit (memu), breakpoint
  -- unit (brku), branch unit (br) and data memory switch blocks are
  -- instantiated for each pipelane *group*. The context register logic (cxreg)
  -- block is instantiated for each context. Blocks which are instantiated
  -- multiple times are shown with double (=====) lines in the block diagram,
  -- blocks which are instantiated optionally are shown with dashed ( - - )
  -- lines.
  --
  -- Some blocks have subblocks which are not shown in this block diagram.
  -- The entity names and filenames for these blocks are of the form
  -- core_<block>_<subblock>.vhd. In general, _ is used as a hierarchy
  -- separator in the code, whereas camelCase is used to indicate word
  -- boundaries.
  --
  -- Most signal names have the form <source>2<dest>_<name>, where source and
  -- dest are the block abbreviations of the source and destination blocks
  -- respectively. In addition, "any" is used as destination for the
  -- configuration control signals shared between a large number of blocks, as
  -- indicated by the ellipsis in the block diagram.
  --
  -- Pipeline related signals are array-indexed by their pipeline stage index
  -- using increasing ranges wherever possible. Also, in the pipelines
  -- themselves, every state signal which passes through a pipeline register is
  -- generally duplicated for every pipeline stage. This simplifies the
  -- pipeline register code, makes things more readable, and makes debugging
  -- the core in VHDL simulation much simpler. A downside is that it is not
  -- trivial to see just how many registers are actually used. Also, it is of
  -- vital importance for the area usage of the processor that the synthesizer
  -- properly culls unused registers.
  --
  -----------------------------------------------------------------------------
  -- VHDL packages
  -----------------------------------------------------------------------------
  -- The following VHDL packages are used within the processor. Only core_pkg
  -- and the generic common_pkg is necessary to instantiate the core.
  --
  --  - core_pkg
  --      -> Contains data types used in the toplevel interface description of
  --         the rvex processor and the component specification for the
  --         toplevel block.
  --
  --  - core_intIface_pkg
  --      -> Contains data types and constants used throughout the core, in
  --         addition to those in core_pkg.
  --
  --  - core_pipeline_pkg
  --      -> Contains constants which specify what should happen in which
  --         pipeline stage. In theory, it should be possible to change this
  --         without modifying code to change timing characteristics, but not
  --         everything is tested and it's relatively easy to break things
  --         here.
  --
  --  - core_opcode_pkg, core_opcodeAlu_pkg, core_opcodeMultiplier_pkg,
  --    core_opcodeDatapath_pkg, core_opcodeBranch_pkg, core_opcodeMemory_pkg
  --      -> Contains a constant table of all decoding signals based on the
  --         opcode field of a syllable, as well as disassembly information for
  --         simulation. In theory, there should be no other mappings from
  --         opcode to functionality elsewhere in the code. Control signals for
  --         the various functional units are specified in core_opcode_pkg as
  --         constants, which are defined in the core_opcode*_pkg packages, in
  --         order to keep the line count sane.
  --
  --  - core_trap_pkg
  --      -> Similar to core_opcode_pkg, this packages contains a decoding
  --         table for trap causes.
  --
  --  - core_utils_pkg
  --      -> Contains utility methods which are useful for logic generation.
  --
  --  - core_asDisas_pkg
  --      -> Contains simulation-only assembly and pretty-printing related
  --         methods.

--=============================================================================
-- This is the toplevel entity for the rvex core.
-------------------------------------------------------------------------------
entity core is
--=============================================================================
  generic (
    
    -- Configuration.
    CFG                         : rvex_generic_config_type := rvex_cfg
    
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
    clkEn                       : in  std_logic := '1';
    
    ---------------------------------------------------------------------------
    -- VHDL simulation debug information
    ---------------------------------------------------------------------------
    -- pragma translate_off
    
    -- Describes the current state of the processor, aligned with the last
    -- pipeline stage. Only generated when GEN_VHDL_SIM_INFO in
    -- rvex_intIface_pkg is true. You don't need to connect anything to this
    -- (and with such a complicated config-dependent array size you don't want
    -- to either); just leave it open but add it to the simulation trace if
    -- you want to see what the processor is doing.
    rv2sim                      : out rvex_string_array(1 to 2*2**CFG.numLanesLog2+2**CFG.numLaneGroupsLog2+2**CFG.numContextsLog2);
    
    -- pragma translate_on
    
    ---------------------------------------------------------------------------
    -- Run control interface
    ---------------------------------------------------------------------------
    -- External interrupt request signal, active high.
    rctrl2rv_irq                : in  std_logic_vector(2**CFG.numContextsLog2-1 downto 0) := (others => '0');
    
    -- External interrupt identification. Guaranteed to be loaded in the trap
    -- argument register in the same clkEn'd cycle where irqAck is high.
    rctrl2rv_irqID              : in  rvex_address_array(2**CFG.numContextsLog2-1 downto 0) := (others => (others => '0'));
    
    -- External interrupt acknowledge signal, active high. Goes high for one
    -- clkEn'abled cycle.
    rv2rctrl_irqAck             : out std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
    
    -- Active high run signal. When released, the context will stop running as
    -- soon as possible.
    rctrl2rv_run                : in  std_logic_vector(2**CFG.numContextsLog2-1 downto 0) := (others => '1');
    
    -- Active high idle output. This is asserted when the core is no longer
    -- doing anything.
    rv2rctrl_idle               : out std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
    
    -- Active high context reset input. When high, the context control
    -- registers (including PC, done and break flag) will be reset.
    rctrl2rv_reset              : in  std_logic_vector(2**CFG.numContextsLog2-1 downto 0) := (others => '0');
    
    -- Active high done output. This is asserted when the context encounters
    -- a stop syllable. Processing a stop signal also sets the BRK control
    -- register, which stops the core. This bit can be reset by issuing a core
    -- reset or by means of the debug interface.
    rv2rctrl_done               : out std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
    
    ---------------------------------------------------------------------------
    -- Common memory interface
    ---------------------------------------------------------------------------
    -- Decouple vector to the instruction and data memory/caches. This vector
    -- works as follows. Each pipelane group has a bit in the vector. When this
    -- bit is low, the pipelane group is a slave to the first higher-indexed
    -- group which has a high decouple bit. In such a case, the following
    -- interfacing rules apply:
    --  - The signals from the rvex to the data memory from all groups with
    --    decouple set low may be ignored; only the highest indexed pipelane
    --    group in a core issues commands to the data memory.
    --  - All groups will issue instruction memory read commands regardless of
    --    decouple state. However, coupled groups will always make aligned
    --    accesses. In other words, you could for example only use the PC from
    --    the lowest indexed pipelane group just make wider memory accesses to
    --    deliver all the syllables.
    --  - The memories must provide equal stall and blockReconfig signals to
    --    coupled pipelane groups or behavior will be undefined.
    --  - The memories must provide equal stall signals to coupled pipelane
    --    groups or behavior will be undefined.
    -- The rvex core will follow the following rules:
    --  - Pipelane groups working together are properly aligned (see also the
    --    config control signal documentation) and the highest indexed debouple
    --    bit is always high. For example, for an rvex with 8 lanes and 4
    --    pipelane groups, the only decouple outputs generated under normal
    --    conditions are "1111", "1110", "1011", "1010" and "1000".
    --  - The decouple outputs will not split or merge two groups when either
    --    group is asserting the blockReconfig signal.
    rv2mem_decouple             : out std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Active high reconfiguration block input from the instruction and data
    -- memories. When this is low, associated lanes may not be reconfigured.
    -- The processor assumes that this signal will go low eventually when no
    -- fetch/read/write requests are made by associated lanes.
    mem2rv_blockReconfig        : in  std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0) := (others => '0');
    
    -- Stall inputs from the instruction and data memories. When a bit in this
    -- vector is high, the associated pipelane group will stall. Equal stall
    -- signals must be provided to coupled pipelane groups (see also the
    -- mem_decouple signal documentation).
    mem2rv_stallIn              : in  std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0) := (others => '0');
    
    -- Stall outputs to the instruction and data memories. When a bit in this
    -- vector is high, the associated pipelane group will not register data
    -- from the memories on the next rising clock edge, and the memories should
    -- ignore any commands given. The stall output is guaranteed to be high if
    -- the stall input is high, but the rvex may pull the stall output high for
    -- reasons other than memory stalls as well.
    rv2mem_stallOut             : out std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    ---------------------------------------------------------------------------
    -- Instruction memory interface
    ---------------------------------------------------------------------------
    -- Program counters from each pipelane group.
    rv2imem_PCs                 : out rvex_address_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Active high instruction fetch enable signal. When a bit in this vector
    -- is high, the bit in mem_stallOut is low and the bit in mem_decouple is
    -- high, the instruction memory must fetch the instruction pointed to by
    -- the associated vector in imem_pcs.
    rv2imem_fetch               : out std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Combinatorial cancel signal, valid one cycle after rv2imem_PCs and
    -- rv2imem_fetch, regardless of memory stalls. This will go high when a
    -- branch is detected by the next pipeline stage and the previously
    -- requested instruction is not going to be executed. In this case, the
    -- instruction memory may choose not to complete the request if that is
    -- faster somehow (a cache may choose to cancel line validation if a miss
    -- occured to allow the core to continue earlier). Note that this signal
    -- can be safely ignored for proper operation, it's just a hint which may
    -- be used to speed things up.
    rv2imem_cancel              : out std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- (L_IF clock cycles delay with clkEn high and stallOut low; L_IF is set
    -- in rvex_pipeline_pkg.vhd)
    
    -- Fetched instruction, from instruction memory to the rvex.
    imem2rv_instr               : in  rvex_syllable_array(2**CFG.numLanesLog2-1 downto 0);
    
    -- Cache block affinity data from cache. This should be set to cache block
    -- index which serviced the request. This is just a hint for the processor
    -- (when a core splits, the affinity values are used to determine which
    -- lane the context which was running should be run on for maximum cache
    -- locality).
    imem2rv_affinity            : in  std_logic_vector(2**CFG.numLaneGroupsLog2*CFG.numLaneGroupsLog2-1 downto 0) := (others => '1');
    
    -- Active high fault signal from the instruction memory. When high,
    -- imem2rv_instr is assumed to be invalid and an exception will be thrown.
    imem2rv_fault               : in  std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0) := (others => '0');
    
    ---------------------------------------------------------------------------
    -- Data memory interface
    ---------------------------------------------------------------------------
    -- Data memory addresses from each pipelane group. Note that a section
    -- of the address space 128 bytes in size must be mapped to the core
    -- control registers, making that section of the data memory inaccessible.
    -- The start address of this section is configurable with CFG.
    rv2dmem_addr                : out rvex_address_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Active high read enable from each pipelane group. When a bit in this
    -- vector is high, the bit in mem_stallOut is low and the bit in
    -- mem_decouple is high, the data memory must fetch the data at the address
    -- specified by the associated vector in dmem_addr.
    rv2dmem_readEnable          : out std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Write data from the rvex to the data memory.
    rv2dmem_writeData           : out rvex_data_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Write byte mask from the rvex to the data memory, active high.
    rv2dmem_writeMask           : out rvex_mask_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Active write enable from each pipelane group. When a bit in this
    -- vector is high, the bit in mem_stallOut is low and the bit in
    -- mem_decouple is high, the data memory must write the data in
    -- dmem_writeData to the address specified by dmem_addr, respecting the
    -- byte mask specified by dmem_writeMask.
    rv2dmem_writeEnable         : out std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- (L_MEM clock cycles delay with clkEn high and stallOut low; L_MEM is set
    -- in rvex_pipeline_pkg.vhd)
    
    -- Data output from data memory to rvex.
    dmem2rv_readData            : in  rvex_data_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Active high fault signal from the data memory. When high,
    -- dmem2rv_readData is assumed to be invalid and an exception will be
    -- thrown.
    dmem2rv_fault               : in  std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0) := (others => '0');
    
    ---------------------------------------------------------------------------
    -- Control/debug bus interface
    ---------------------------------------------------------------------------
    -- The control/debug bus interface may be used to access the core control
    -- registers for debugging. All cores are forcibly stalled when a read or
    -- write is requested here, such that addressing logic may be reused.
    
    -- Address for the request. Only the 8 LSB are currently used.
    dbg2rv_addr                 : in  rvex_address_type := (others => '0');
    
    -- Active high read enable signal.
    dbg2rv_readEnable           : in  std_logic := '0';
    
    -- Active high write enable signal.
    dbg2rv_writeEnable          : in  std_logic := '0';
    
    -- Active high byte write mask signal.
    dbg2rv_writeMask            : in  rvex_mask_type := (others => '1');
    
    -- Write data.
    dbg2rv_writeData            : in  rvex_data_type := (others => '0');
    
    -- (one clock cycle delay with clkEn high)
    
    -- Read data.
    rv2dbg_readData             : out rvex_data_type
    
  );
end core;

--=============================================================================
architecture Behavioral of core is
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- Decoded configuration signals
  -----------------------------------------------------------------------------
  -- Diagonal block matrix of n*n size, where n is the number of pipelane
  -- groups. C_i,j is high when pipelane groups i and j are coupled/share a
  -- context, or low when they don't.
  signal cfg2any_coupled              : std_logic_vector(4**CFG.numLaneGroupsLog2-1 downto 0);
  
  -- Decouple vector. This is just another way to look at the coupled matrix.
  -- The vector is assigned such that dec_i = not C_i,i+1. The MSB in the
  -- vector is always high. This representation is useful because the bits
  -- can also be regarded as master/slave bits: when the decouple bit for
  -- a group is high, it is a master, otherwise it is a slave. Slaves answer
  -- to the next higher indexed master group.
  signal cfg2any_decouple             : std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
  
  -- log2 of the number of coupled pipelane groups for each pipelane group.
  signal cfg2any_numGroupsLog2        : rvex_2bit_array(2**CFG.numLaneGroupsLog2-1 downto 0);
  
  -- Specifies the context associated with the indexed pipelane group.
  signal cfg2any_context              : rvex_3bit_array(2**CFG.numLaneGroupsLog2-1 downto 0);
  
  -- Last pipelane group associated with each context.
  signal cfg2any_lastGroupForCtxt     : rvex_3bit_array(2**CFG.numContextsLog2-1 downto 0);
  
  -----------------------------------------------------------------------------
  -- Internal signals
  -----------------------------------------------------------------------------
  -- Reset signal from the global control registers.
  signal gbreg2rv_reset               : std_logic;
  
  -- Internal reset signal, asserted when either the external reset signal or
  -- the signal from the global control registers is asserted.
  signal reset_s                      : std_logic;
  
  -- Stall signal for each pipelane group.
  signal stall                        : std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
  
  -- Debug bus access stall signals. For every debug bus access, the rvex core
  -- is stalled for two cycles. This is done to allow the debug bus to make use
  -- of the existing bus networks by claiming the bus from one of the
  -- pipelanes.
  signal debugBusStall                : std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
  
  -- Extended memory exception trap information. These are decoded from the
  -- fault flags coming from the memory into a trap information record which
  -- the processor knows how to deal with.
  signal imem2pl_exception            : trap_info_array(2**CFG.numLaneGroupsLog2-1 downto 0);
  signal dmem2dmsw_exception          : trap_info_array(2**CFG.numLaneGroupsLog2-1 downto 0);
  
  -----------------------------------------------------------------------------
  -- Interconnect signals
  -----------------------------------------------------------------------------
  -- For all the signals below: refer to the entity description of their source
  -- or destination block for documentation.
  
  -- Pipelane <-> configuration control signals.
  signal cfg2cxplif_run               : std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
  signal cxplif2cfg_blockReconfig     : std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
  
  -- Data memory switch <-> control register signals.
  signal dmsw2creg_addr               : rvex_address_array(2**CFG.numLaneGroupsLog2-1 downto 0);
  signal dmsw2creg_writeData          : rvex_data_array(2**CFG.numLaneGroupsLog2-1 downto 0);
  signal dmsw2creg_writeMask          : rvex_mask_array(2**CFG.numLaneGroupsLog2-1 downto 0);
  signal dmsw2creg_writeEnable        : std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
  signal dmsw2creg_readEnable         : std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
  signal creg2dmsw_readData           : rvex_data_array(2**CFG.numLaneGroupsLog2-1 downto 0);
  
  -- Pipelane <-> general purpose register file signals.
  signal pl2gpreg_readPorts           : pl2gpreg_readPort_array(2*2**CFG.numLanesLog2-1 downto 0);
  signal gpreg2pl_readPorts           : gpreg2pl_readPort_array(2*2**CFG.numLanesLog2-1 downto 0);
  signal pl2gpreg_writePorts          : pl2gpreg_writePort_array(2**CFG.numLanesLog2-1 downto 0);
  
  -- Control registers <-> general purpose register file signals.
  signal creg2gpreg_claim             : std_logic;
  signal creg2gpreg_addr              : rvex_gpRegAddr_type;
  signal creg2gpreg_ctxt              : std_logic_vector(CFG.numContextsLog2-1 downto 0);
  signal creg2gpreg_writeEnable       : std_logic;
  signal creg2gpreg_writeData         : rvex_data_type;
  signal gpreg2creg_readData          : rvex_data_type;
  
  -- Control registers <-> global control register logic signals.
  signal gbreg2creg                   : gbreg2creg_type;
  signal creg2gbreg                   : creg2gbreg_type;
  signal gbreg2creg_context           : std_logic_vector(CFG.numContextsLog2-1 downto 0);
  signal gbreg2creg_gpregBank         : std_logic;
  
  -- Control registers <-> context control register logic signals.
  signal cxreg2creg                   : cxreg2creg_array(2**CFG.numContextsLog2-1 downto 0);
  signal creg2cxreg                   : creg2cxreg_array(2**CFG.numContextsLog2-1 downto 0);
  signal cxreg2creg_reset             : std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
  
  -- Context register <-> context-pipelane interface signals.
  signal cxplif2cxreg_brWriteData     : rvex_brRegData_array(2**CFG.numContextsLog2-1 downto 0);
  signal cxplif2cxreg_brWriteEnable   : rvex_brRegData_array(2**CFG.numContextsLog2-1 downto 0);
  signal cxreg2cxplif_brReadData      : rvex_brRegData_array(2**CFG.numContextsLog2-1 downto 0);
  signal cxplif2cxreg_linkWriteData   : rvex_data_array(2**CFG.numContextsLog2-1 downto 0);
  signal cxplif2cxreg_linkWriteEnable : std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
  signal cxreg2cxplif_linkReadData    : rvex_data_array(2**CFG.numContextsLog2-1 downto 0);
  signal cxplif2cxreg_stall           : std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
  signal cxplif2cxreg_idle            : std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
  signal cxplif2cxreg_sylCommit       : rvex_sylStatus_array(2**CFG.numContextsLog2-1 downto 0);
  signal cxplif2cxreg_sylNop          : rvex_sylStatus_array(2**CFG.numContextsLog2-1 downto 0);
  signal cxplif2cxreg_stop            : std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
  signal cxplif2cxreg_nextPC          : rvex_address_array(2**CFG.numContextsLog2-1 downto 0);
  signal cxreg2cxplif_currentPC       : rvex_address_array(2**CFG.numContextsLog2-1 downto 0);
  signal cxreg2cxplif_overridePC      : std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
  signal cxplif2cxreg_overridePC_ack  : std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
  signal cxreg2cxplif_trapHandler     : rvex_address_array(2**CFG.numContextsLog2-1 downto 0);
  signal cxplif2cxreg_trapInfo        : trap_info_array(2**CFG.numContextsLog2-1 downto 0);
  signal cxplif2cxreg_trapPoint       : rvex_address_array(2**CFG.numContextsLog2-1 downto 0);
  signal cxreg2cxplif_trapReturn      : rvex_address_array(2**CFG.numContextsLog2-1 downto 0);
  signal cxplif2cxreg_rfi             : std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
  signal cxreg2cxplif_handlingDebugTrap:std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
  signal cxreg2cxplif_interruptEnable : std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
  signal cxreg2cxplif_debugTrapEnable : std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
  signal cxreg2cxplif_breakpoints     : cxreg2pl_breakpoint_info_array(2**CFG.numContextsLog2-1 downto 0);
  signal cxreg2cxplif_extDebug        : std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
  signal cxplif2cxreg_exDbgTrapInfo   : trap_info_array(2**CFG.numContextsLog2-1 downto 0);
  signal cxreg2cxplif_brk             : std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
  signal cxreg2cxplif_stepping        : std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
  signal cxreg2cxplif_resuming        : std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
  signal cxplif2cxreg_resuming_ack    : std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
  
  -- Context register logic <-> configuration control signals.
  signal cxreg2cfg_requestData_r      : rvex_data_array(2**CFG.numContextsLog2-1 downto 0);
  signal cxreg2cfg_requestEnable      : std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
  
  -- Global register logic <-> configuration control signals.
  signal gbreg2cfg_requestData_r      : rvex_data_type;
  signal gbreg2cfg_requestEnable      : std_logic;
  signal cfg2gbreg_currentCfg         : rvex_data_type;
  signal cfg2gbreg_busy               : std_logic;
  signal cfg2gbreg_error              : std_logic;
  signal cfg2gbreg_requesterID        : std_logic_vector(3 downto 0);
  
  -----------------------------------------------------------------------------
  -- Simulation-only signals
  -----------------------------------------------------------------------------
  -- pragma translate_off
  signal pl2sim_instr                 : rvex_string_builder_array(2**CFG.numLanesLog2-1 downto 0);
  signal pl2sim_op                    : rvex_string_builder_array(2**CFG.numLanesLog2-1 downto 0);
  signal br2sim                       : rvex_string_builder_array(2**CFG.numLanesLog2-1 downto 0);
  -- pragma translate_on
    
--=============================================================================
begin -- architecture
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- Generate reset and stalling logic
  -----------------------------------------------------------------------------
  -- Combine the reset signals.
  reset_s <= reset or gbreg2rv_reset;
  
  -- Generate the stall signals.
  stall_gen: process (mem2rv_stallIn, debugBusStall) is
    variable s : std_logic;
  begin
    if CFG.unifiedStall then
      s := '0';
      for laneGroup in 0 to 2**CFG.numLaneGroupsLog2-1 loop
        s := s or mem2rv_stallIn(laneGroup) or debugBusStall(laneGroup);
      end loop;
      stall <= (others => s);
    else
      stall <= mem2rv_stallIn or debugBusStall;
    end if;
  end process;
  
  -- Forward the internal stall signal to the memory.
  rv2mem_stallOut <= stall;
  
  -----------------------------------------------------------------------------
  -- Decode memory faults
  -----------------------------------------------------------------------------
  -- Drive the trap information vectors to the pipelanes based on the fault
  -- flags from the memories.
  mem_trap_info_gen: for laneGroup in 2**CFG.numLaneGroupsLog2-1 downto 0 generate
    
    -- There is only one instruction memory fault. Note that the arg parameter
    -- will be overwritten by the PC of the bundle which was being fetched in
    -- the pipelane.
    imem2pl_exception(laneGroup) <= (
      active => imem2rv_fault(laneGroup),
      cause  => rvex_trap(RVEX_TRAP_FETCH_FAULT),
      arg    => (others => '0')
    );
    
    -- There is only one data memory fault. Note that the arg parameter will be
    -- overwritten by the address which was being accessed in the pipelane.
    dmem2dmsw_exception(laneGroup) <= (
      active => dmem2rv_fault(laneGroup),
      cause  => rvex_trap(RVEX_TRAP_DMEM_FAULT),
      arg    => (others => '0')
    );
    
  end generate;
  
  -----------------------------------------------------------------------------
  -- Instantiate the pipelanes
  -----------------------------------------------------------------------------
  pls_inst: entity rvex.core_pipelanes
    generic map (
      CFG                           => CFG
    )
    port map (
      
      -- System control.
      reset                         => reset_s,
      clk                           => clk,
      clkEn                         => clkEn,
      stall                         => stall,
      
      -- VHDL simulation debug information.
      -- pragma translate_off
      pl2sim_instr                  => pl2sim_instr,
      pl2sim_op                     => pl2sim_op,
      br2sim                        => br2sim,
      -- pragma translate_on
      
      -- Decoded configuration signals.
      cfg2any_coupled               => cfg2any_coupled,
      cfg2any_decouple              => cfg2any_decouple,
      cfg2any_numGroupsLog2         => cfg2any_numGroupsLog2,
      cfg2any_context               => cfg2any_context,
      cfg2any_lastGroupForCtxt      => cfg2any_lastGroupForCtxt,
      
      -- Configuration signals.
      cfg2cxplif_run                => cfg2cxplif_run,
      cxplif2cfg_blockReconfig      => cxplif2cfg_blockReconfig,
      
      -- External run control signals.
      rctrl2cxplif_irq              => rctrl2rv_irq,
      rctrl2cxplif_irqID            => rctrl2rv_irqID,
      cxplif2rctrl_irqAck           => rv2rctrl_irqAck,
      rctrl2cxplif_run              => rctrl2rv_run,
      cxplif2rctrl_idle             => rv2rctrl_idle,
      
      -- Instruction memory interface.
      cxplif2imem_PCs               => rv2imem_PCs,
      cxplif2imem_fetch             => rv2imem_fetch,
      cxplif2imem_cancel            => rv2imem_cancel,
      imem2pl_instr                 => imem2rv_instr,
      imem2pl_exception             => imem2pl_exception,
      
      -- Data memory interface.
      dmsw2dmem_addr                => rv2dmem_addr,
      dmsw2dmem_writeData           => rv2dmem_writeData,
      dmsw2dmem_writeMask           => rv2dmem_writeMask,
      dmsw2dmem_writeEnable         => rv2dmem_writeEnable,
      dmsw2dmem_readEnable          => rv2dmem_readEnable,
      dmem2dmsw_readData            => dmem2rv_readData,
      dmem2dmsw_exception           => dmem2dmsw_exception,
      
      -- Control register interface.
      dmsw2creg_addr                => dmsw2creg_addr,
      dmsw2creg_writeData           => dmsw2creg_writeData,
      dmsw2creg_writeMask           => dmsw2creg_writeMask,
      dmsw2creg_writeEnable         => dmsw2creg_writeEnable,
      dmsw2creg_readEnable          => dmsw2creg_readEnable,
      creg2dmsw_readData            => creg2dmsw_readData,
      
      -- Register file interface.
      pl2gpreg_readPorts            => pl2gpreg_readPorts,
      gpreg2pl_readPorts            => gpreg2pl_readPorts,
      pl2gpreg_writePorts           => pl2gpreg_writePorts,
      cxplif2cxreg_brWriteData      => cxplif2cxreg_brWriteData,
      cxplif2cxreg_brWriteEnable    => cxplif2cxreg_brWriteEnable,
      cxreg2cxplif_brReadData       => cxreg2cxplif_brReadData,
      cxplif2cxreg_linkWriteData    => cxplif2cxreg_linkWriteData,
      cxplif2cxreg_linkWriteEnable  => cxplif2cxreg_linkWriteEnable,
      cxreg2cxplif_linkReadData     => cxreg2cxplif_linkReadData,
      
      -- Special context register interface.
      cxplif2cxreg_stall            => cxplif2cxreg_stall,
      cxplif2cxreg_idle             => cxplif2cxreg_idle,
      cxplif2cxreg_sylCommit        => cxplif2cxreg_sylCommit,
      cxplif2cxreg_sylNop           => cxplif2cxreg_sylNop,
      cxplif2cxreg_stop             => cxplif2cxreg_stop,
      cxplif2cxreg_nextPC           => cxplif2cxreg_nextPC,
      cxreg2cxplif_currentPC        => cxreg2cxplif_currentPC,
      cxreg2cxplif_overridePC       => cxreg2cxplif_overridePC,
      cxplif2cxreg_overridePC_ack   => cxplif2cxreg_overridePC_ack,
      cxreg2cxplif_trapHandler      => cxreg2cxplif_trapHandler,
      cxplif2cxreg_trapInfo         => cxplif2cxreg_trapInfo,
      cxplif2cxreg_trapPoint        => cxplif2cxreg_trapPoint,
      cxreg2cxplif_trapReturn       => cxreg2cxplif_trapReturn,
      cxplif2cxreg_rfi              => cxplif2cxreg_rfi,
      cxreg2cxplif_handlingDebugTrap=> cxreg2cxplif_handlingDebugTrap,
      cxreg2cxplif_interruptEnable  => cxreg2cxplif_interruptEnable,
      cxreg2cxplif_debugTrapEnable  => cxreg2cxplif_debugTrapEnable,
      cxreg2cxplif_breakpoints      => cxreg2cxplif_breakpoints,
      cxreg2cxplif_extDebug         => cxreg2cxplif_extDebug,
      cxplif2cxreg_exDbgTrapInfo    => cxplif2cxreg_exDbgTrapInfo,
      cxreg2cxplif_brk              => cxreg2cxplif_brk,
      cxreg2cxplif_stepping         => cxreg2cxplif_stepping,
      cxreg2cxplif_resuming         => cxreg2cxplif_resuming,
      cxplif2cxreg_resuming_ack     => cxplif2cxreg_resuming_ack
      
    );
  
  -----------------------------------------------------------------------------
  -- Instantiate the general purpose register file
  -----------------------------------------------------------------------------
  gpreg_inst: entity rvex.core_gpRegs
    generic map (
      CFG                           => CFG
    )
    port map (
      
      -- System control.
      reset                         => reset_s,
      clk                           => clk,
      clkEn                         => clkEn,
      stall                         => stall,

      -- Decoded configuration signals.
      cfg2any_coupled               => cfg2any_coupled,
      cfg2any_context               => cfg2any_context,
      
      -- Read and write ports.
      pl2gpreg_readPorts            => pl2gpreg_readPorts,
      gpreg2pl_readPorts            => gpreg2pl_readPorts,
      pl2gpreg_writePorts           => pl2gpreg_writePorts,
      
      -- Debug interface.
      creg2gpreg_claim              => creg2gpreg_claim,
      creg2gpreg_addr               => creg2gpreg_addr,
      creg2gpreg_ctxt               => creg2gpreg_ctxt,
      creg2gpreg_writeEnable        => creg2gpreg_writeEnable,
      creg2gpreg_writeData          => creg2gpreg_writeData,
      gpreg2creg_readData           => gpreg2creg_readData
      
    );
  
  -----------------------------------------------------------------------------
  -- Instantiate the control registers
  -----------------------------------------------------------------------------
  creg_inst: entity rvex.core_ctrlRegs
    generic map (
      CFG                           => CFG
    )
    port map (
      
      -- System control.
      reset                         => reset_s,
      clk                           => clk,
      clkEn                         => clkEn,
      stallIn                       => stall,
      stallOut                      => debugBusStall,
      
      -- Decoded configuration signals.
      cfg2any_context               => cfg2any_context,
      
      -- Core bus interfaces.
      dmsw2creg_addr                => dmsw2creg_addr,
      dmsw2creg_writeEnable         => dmsw2creg_writeEnable,
      dmsw2creg_writeMask           => dmsw2creg_writeMask,
      dmsw2creg_writeData           => dmsw2creg_writeData,
      dmsw2creg_readEnable          => dmsw2creg_readEnable,
      creg2dmsw_readData            => creg2dmsw_readData,
      
      -- Debug bus interface.
      dbg2creg_addr                 => dbg2rv_addr,
      dbg2creg_writeEnable          => dbg2rv_writeEnable,
      dbg2creg_writeMask            => dbg2rv_writeMask,
      dbg2creg_writeData            => dbg2rv_writeData,
      dbg2creg_readEnable           => dbg2rv_readEnable,
      creg2dbg_readData             => rv2dbg_readData,
      
      -- General purpose register file interface.
      creg2gpreg_claim              => creg2gpreg_claim,
      creg2gpreg_addr               => creg2gpreg_addr,
      creg2gpreg_ctxt               => creg2gpreg_ctxt,
      creg2gpreg_writeEnable        => creg2gpreg_writeEnable,
      creg2gpreg_writeData          => creg2gpreg_writeData,
      gpreg2creg_readData           => gpreg2creg_readData,
      
      -- Global register logic interface.
      gbreg2creg                    => gbreg2creg,
      creg2gbreg                    => creg2gbreg,
      gbreg2creg_context            => gbreg2creg_context,
      gbreg2creg_gpregBank          => gbreg2creg_gpregBank,
      
      -- Context register logic interface.
      cxreg2creg                    => cxreg2creg,
      creg2cxreg                    => creg2cxreg,
      cxreg2creg_reset              => cxreg2creg_reset
      
    );
  
  -----------------------------------------------------------------------------
  -- Instantiate the context-based control register logic
  -----------------------------------------------------------------------------
  cxreg_gen: for ctxt in 2**CFG.numContextsLog2-1 downto 0 generate
    cxreg_inst: entity rvex.core_contextRegLogic
      generic map (
        CFG                         => CFG,
        CONTEXT_INDEX               => ctxt
      )
      port map (
        
        -- System control.
        reset                       => reset_s,
        clk                         => clk,
        clkEn                       => clkEn,
        
        -- Interface with the control registers and bus logic.
        cxreg2creg                  => cxreg2creg(ctxt),
        creg2cxreg                  => creg2cxreg(ctxt),
        cxreg2creg_reset            => cxreg2creg_reset(ctxt),
        
        -- Run control interface.
        rctrl2cxreg_reset           => rctrl2rv_reset(ctxt),
        cxreg2rctrl_done            => rv2rctrl_done(ctxt),
        
        -- Pipelane interface.
        cxplif2cxreg_stall          => cxplif2cxreg_stall(ctxt),
        cxplif2cxreg_idle           => cxplif2cxreg_idle(ctxt),
        cxplif2cxreg_sylCommit      => cxplif2cxreg_sylCommit(ctxt),
        cxplif2cxreg_sylNop         => cxplif2cxreg_sylNop(ctxt),
        cxplif2cxreg_stop           => cxplif2cxreg_stop(ctxt),
        cxplif2cxreg_brWriteData    => cxplif2cxreg_brWriteData(ctxt),
        cxplif2cxreg_brWriteEnable  => cxplif2cxreg_brWriteEnable(ctxt),
        cxreg2cxplif_brReadData     => cxreg2cxplif_brReadData(ctxt),
        cxplif2cxreg_linkWriteData  => cxplif2cxreg_linkWriteData(ctxt),
        cxplif2cxreg_linkWriteEnable=> cxplif2cxreg_linkWriteEnable(ctxt),
        cxreg2cxplif_linkReadData   => cxreg2cxplif_linkReadData(ctxt),
        cxplif2cxreg_nextPC         => cxplif2cxreg_nextPC(ctxt),
        cxreg2cxplif_currentPC      => cxreg2cxplif_currentPC(ctxt),
        cxreg2cxplif_overridePC     => cxreg2cxplif_overridePC(ctxt),
        cxplif2cxreg_overridePC_ack => cxplif2cxreg_overridePC_ack(ctxt),
        cxreg2cxplif_trapHandler    => cxreg2cxplif_trapHandler(ctxt),
        cxplif2cxreg_trapInfo       => cxplif2cxreg_trapInfo(ctxt),
        cxplif2cxreg_trapPoint      => cxplif2cxreg_trapPoint(ctxt),
        cxreg2cxplif_trapReturn     => cxreg2cxplif_trapReturn(ctxt),
        cxplif2cxreg_rfi            => cxplif2cxreg_rfi(ctxt),
        cxreg2cxplif_handlingDebugTrap=>cxreg2cxplif_handlingDebugTrap(ctxt),
        cxreg2cxplif_interruptEnable=> cxreg2cxplif_interruptEnable(ctxt),
        cxreg2cxplif_debugTrapEnable=> cxreg2cxplif_debugTrapEnable(ctxt),
        cxreg2cxplif_breakpoints    => cxreg2cxplif_breakpoints(ctxt),
        cxreg2cxplif_extDebug       => cxreg2cxplif_extDebug(ctxt),
        cxplif2cxreg_exDbgTrapInfo  => cxplif2cxreg_exDbgTrapInfo(ctxt),
        cxreg2cxplif_brk            => cxreg2cxplif_brk(ctxt),
        cxreg2cxplif_stepping       => cxreg2cxplif_stepping(ctxt),
        cxreg2cxplif_resuming       => cxreg2cxplif_resuming(ctxt),
        cxplif2cxreg_resuming_ack   => cxplif2cxreg_resuming_ack(ctxt),
        
        -- Interface with configuration logic.
        cxreg2cfg_requestData_r     => cxreg2cfg_requestData_r(ctxt),
        cxreg2cfg_requestEnable     => cxreg2cfg_requestEnable(ctxt)
        
      );
  end generate;
  
  -----------------------------------------------------------------------------
  -- Instantiate the global (common to all contexts) control register logic
  -----------------------------------------------------------------------------
  gbreg_inst: entity rvex.core_globalRegLogic
    generic map (
      CFG                           => CFG
    )
    port map (
      
      -- System control.
      resetIn                       => reset_s,
      resetOut                      => gbreg2rv_reset,
      clk                           => clk,
      clkEn                         => clkEn,
      
      -- Interface with the control registers and bus logic.
      gbreg2creg                    => gbreg2creg,
      creg2gbreg                    => creg2gbreg,
      gbreg2creg_context            => gbreg2creg_context,
      gbreg2creg_gpregBank          => gbreg2creg_gpregBank,
      
      -- Interface with configuration logic.
      gbreg2cfg_requestData_r       => gbreg2cfg_requestData_r,
      gbreg2cfg_requestEnable       => gbreg2cfg_requestEnable,
      cfg2gbreg_currentCfg          => cfg2gbreg_currentCfg,
      cfg2gbreg_busy                => cfg2gbreg_busy,
      cfg2gbreg_error               => cfg2gbreg_error,
      cfg2gbreg_requesterID         => cfg2gbreg_requesterID,
      
      -- Interface with memory
      imem2gbreg_affinity           => imem2rv_affinity
      
    );
  
  -----------------------------------------------------------------------------
  -- Instantiate configuration logic
  -----------------------------------------------------------------------------
  cfg_inst: entity rvex.core_cfgCtrl
    generic map (
      CFG                           => CFG
    )
    port map (
      
      -- System control.
      reset                         => reset_s,
      clk                           => clk,
      clkEn                         => clkEn,
      
      -- Configuration request inputs.
      cxreg2cfg_requestData_r       => cxreg2cfg_requestData_r,
      cxreg2cfg_requestEnable       => cxreg2cfg_requestEnable,
      gbreg2cfg_requestData_r       => gbreg2cfg_requestData_r,
      gbreg2cfg_requestEnable       => gbreg2cfg_requestEnable,
      
      -- Configuration status outputs.
      cfg2gbreg_currentCfg          => cfg2gbreg_currentCfg,
      cfg2gbreg_busy                => cfg2gbreg_busy,
      cfg2gbreg_error               => cfg2gbreg_error,
      cfg2gbreg_requesterID         => cfg2gbreg_requesterID,
      
      -- Branch unit interface (through context-pipelane interface).
      cfg2cxplif_run                => cfg2cxplif_run,
      cxplif2cfg_blockReconfig      => cxplif2cfg_blockReconfig,
      
      -- Memory interface.
      mem2cfg_blockReconfig         => mem2rv_blockReconfig,
      
      -- Decoded configuration control signals
      cfg2any_coupled               => cfg2any_coupled,
      cfg2any_decouple              => cfg2any_decouple,
      cfg2any_numGroupsLog2         => cfg2any_numGroupsLog2,
      cfg2any_context               => cfg2any_context,
      cfg2any_lastGroupForCtxt      => cfg2any_lastGroupForCtxt
      
    );
  
  -- Connect the external decouple signal to the decouple signal from the
  -- configuration logic.
  rv2mem_decouple <= cfg2any_decouple;
  
  -----------------------------------------------------------------------------
  -- Generate simulation information
  -----------------------------------------------------------------------------
  -- pragma translate_off
  sim_info_gen: if GEN_VHDL_SIM_INFO generate
    sim_info: process (
      pl2sim_instr, pl2sim_op, br2sim, cfg2gbreg_currentCfg, cfg2any_context,
      cxreg2cxplif_currentPC
    ) is
      
      -- Number of lines in the string list shown in simulation.
      constant NUM_LINES          : natural :=
        2*2**CFG.numLanesLog2+2**CFG.numLaneGroupsLog2+2**CFG.numContextsLog2;
      
      type bool_array is array(natural range <>) of boolean;
      
      variable sb                 : rvex_string_builder_type;
      variable line               : positive;
      variable curContext         : integer;
      variable prevContext        : integer;
      variable processedContexts  : bool_array(2**CFG.numContextsLog2-1 downto 0);
      
    begin
      
      -- This doesn't work like this; if the simulation is very slow look into
      -- this some more.
      ---- To speed up simulation, wait for all incoming signals to become
      ---- stable before continuing, so we're not potentially doing the string
      ---- manipulation more than once per cycle due to delta-delay signal
      ---- propagation.
      --wait until pl2sim_instr'stable and pl2sim_op'stable and br2sim'stable
      --   and cfg2br_run'stable and cfg2any_context'stable
      --   and cxreg2cxplif_currentPC'stable;
      
      -- Add information about all active lanes/contexts to the simulation.
      line := 1;
      prevContext := -1;
      processedContexts := (others => false);
      for lane in 0 to 2**CFG.numLanesLog2-1 loop
        
        -- Ignore lanes which aren't active.
        if cfg2gbreg_currentCfg(lane2group(lane, CFG)*4+3) = '1' then
          prevContext := -1;
          next;
        end if;
        
        -- Figure out the context running on the current lane.
        curContext := vect2uint(cfg2any_context(lane2group(lane, CFG)));
        
        -- If this lane is operating in a different context than the previous
        -- lane, inject a line of whitespace and a line with context
        -- information.
        if curContext /= prevContext then
          
          -- Inject a line of whitespace if this isn't the first line.
          if line /= 1 then
            rvs_clear(sb);
            rv2sim(line) <= rvs2sim(sb);
            line := line + 1;
          end if;
          
          -- Pretty-print context information.
          rvs_clear(sb);
          rvs_append(sb, "Ctxt " & integer'image(curContext) & ": ");
          rvs_append(sb, br2sim(
            group2lastLane(
              vect2uint(cfg2any_lastGroupForCtxt(curContext)), CFG
            ) - CFG.branchLaneRevIndex
          ));
          rv2sim(line) <= rvs2sim(sb);
          line := line + 1;
          
        end if;
        
        -- Print lane instruction information.
        rvs_clear(sb);
        rvs_append(sb, " '- Ln" & integer'image(lane) & ": ");
        rvs_append(sb, pl2sim_instr(lane));
        rv2sim(line) <= rvs2sim(sb);
        line := line + 1;
        
        -- Print lane operation information.
        rvs_clear(sb);
        rvs_append(sb, "      '- ");
        rvs_append(sb, pl2sim_op(lane));
        rv2sim(line) <= rvs2sim(sb);
        line := line + 1;
        
        -- Store the fact that information for the context belonging to this
        -- lane has been added to the simulation information.
        processedContexts(curContext) := true;
        
        -- Store the context belonging to this lane for the next loop
        -- iteration.
        prevContext := curContext;
        
      end loop;
      
      -- Inject a line of whitespace.
      if line /= 1 then
        rvs_clear(sb);
        rv2sim(line) <= rvs2sim(sb);
        line := line + 1;
      end if;
      
      -- Add the current PCs for all non-active contexts to simulation.
      for ctxt in 0 to 2**CFG.numContextsLog2-1 loop
        if processedContexts(ctxt) = false then
        
          -- Pretty-print halted context information.
          rvs_clear(sb);
          rvs_append(sb, "Ctxt " & integer'image(ctxt) & ": halted at PC=");
          rvs_append(sb, rvs_hex(cxreg2cxplif_currentPC(ctxt), 8));
          rv2sim(line) <= rvs2sim(sb);
          line := line + 1;
          
        end if;
      end loop;
      
      -- Finish by writing an empty string to all lines which we're not
      -- currently using.
      rvs_clear(sb);
      while line <= NUM_LINES loop
        rv2sim(line) <= rvs2sim(sb);
        line := line + 1;
      end loop;
      
    end process;
  end generate;
  -- pragma translate_on
  
end Behavioral;

