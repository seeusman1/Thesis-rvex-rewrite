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

  -----------------------------------------------------------------------------
  -- Processor overview and naming conventions
  -----------------------------------------------------------------------------
  -- The figure below shows how the rvex processor is organized. The
  -- abbreviations used are keyed below.
  -- 
  -- . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
  --
  --            .---------------------------------------------------.
  --            | rv                                                |
  --            | .---------------------------------------.         |
  --            | | pls (pipelanes)                       |         |
  --            | |  .=================================.  | .-----. |
  --            | |  | pl (pipelane)                   |  | |gpreg| |
  --            | |  |  - . .---.  - - .  - - .  - - . |  | |.---.| |
  --  imem <----+-+->| |br  |alu| |mulu  |memu  |brku  |<-+>||fwd|| |
  --            | |  |  - ' '---'  - - '  - - '  - - ' |  | |'---'| |
  --            | |  '================================='  | '-----' |
  --            | |    ^             ^       ^      ^     |         |
  --            | |    |             |       |      |     |         |
  --            | |    v             v       v      v     |         |
  --            | | .------.       .====.  .----. .----.  |         |
  --          .-+-+>|cxplif|       |dmsw|  |trap| |limm|  |         |
  --          | | | '------'       '===='  '----' '----'  |         |
  --          | | |    ^            ^  ^                  |         |
  --          | | |    |            |  '------------------+---------+--> dmem
  -- rctrl <-<  | '----+------------+---------------------'         |
  --          | |      v            v                               |
  --          | |   .=====.      .----.      .-----.      .-----.   |
  --          | |   |cxreg|<---->|creg|<---->|gbreg|<---->|     |<--+--> mem
  --          '-+-->|.---.|      '----'      '-----'      | cfg |   |
  --            |   ||fwd||         ^           ^   ...<--|     |   |
  --            |   |'---'|---------+-----------+-------->|     |   |
  --            |   '====='         |           |         '-----'   |
  --            '-------------------+-----------+-------------------'
  --                                |           |
  --                                v           |
  --                               dbg    imem affinity
  --
  -- . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
  --
  -- The abbreviations for the blocks used in the diagram are the following.
  -- 
  --  - rv     = RVex processor             @ rvex.vhd
  --  - pls    = PipeLaneS                  @ rvex_pipelanes.vhd
  --  - pl     = PipeLane                   @ rvex_pipelane.vhd
  --  - br     = BRanch unit                @ rvex_branch.vhd
  --  - alu    = Arith. Logic Unit          @ rvex_alu.vhd
  --  - memu   = MEMory Unit                @ rvex_memu.vhd
  --  - mulu   = MULtiply Unit              @ rvex_mul.vhd
  --  - brku   = BReaKpoint Unit            @ rvex_breakpoint.vhd
  --  - gpreg  = General Purpose REGisters  @ rvex_gpreg.vhd
  --  - fwd    = ForWarDing logic           @ rvex_forward.vhd
  --  - cxplif = ConteXt-PipeLane InterFace @ rvex_contextPipelaneIFace.vhd
  --  - dmsw   = Data Memory SWitch         @ rvex_dmemSwitch.vhd
  --  - trap   = TRAP routing               @ rvex_trapRouting.vhd
  --  - limm   = Long IMMediate routing     @ rvex_limmRouting.vhd
  --  - cxreg  = ConteXt REGister logic     @ rvex_contextRegLogic.vhd
  --  - creg   = Control REGisters          @ rvex_ctrlRegs.vhd
  --  - gbreg  = GloBal REGister logic      @ rvex_globalRegLogic.vhd
  --  - cfg    = ConFiGuration control      @ rvex_cfgCtrl.vhd
  --  - mem    = interface common to instruction and data MEMory/cache
  --  - imem   = Instruction MEMory/cache
  --  - dmem   = Data MEMory/cache
  --  - dbg    = DeBuG bus interface
  --  - rctrl  = Run ConTRoL
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
  -- rvex_<block>_<subblock>.vhd. In general, _ is used as a hierarchy
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
  -- The following VHDL packages are used within the processor. Only rvex_pkg
  -- is necessary to instantiate the core.
  --
  --  - rvex_pkg
  --      -> Contains data types used in the toplevel interface description of
  --         the rvex processor and the component specification for the
  --         toplevel block.
  --
  --  - rvex_intIface_pkg
  --      -> Contains data types and constants used throughout the core, in
  --         addition to those in rvex_pkg.
  --
  --  - rvex_pipeline_pkg
  --      -> Contains constants which specify what should happen in which
  --         pipeline stage. In theory, it should be possible to change this
  --         without modifying code to change timing characteristics, but not
  --         everything is tested and it's relatively easy to break things
  --         here.
  --
  --  - rvex_opcode_pkg, rvex_opcodeAlu_pkg, rvex_opcodeMultiply_pkg,
  --    rvex_opcodeDatapath_pkg, rvex_opcodeBranch_pkg
  --      -> Contains a constant table of all decoding signals based on the
  --         opcode field of a syllable, as well as disassembly information for
  --         simulation. In theory, there should be no other mappings from
  --         opcode to functionality elsewhere in the code. Control signals for
  --         the various functional units are specified in rvex_opcode_pkg as
  --         constants, which are defined in the rvex_opcode*_pkg packages, in
  --         order to keep the line count sane.
  --
  --  - rvex_trap_pkg
  --      -> Similar to rvex_opcode_pkg, this packages contains a decoding
  --         table for trap causes.
  --
  --  - rvex_simUtils_pkg
  --      -> Contains simulation-only utility methods, mostly related to string
  --         manipulation.

--=============================================================================
-- This is the toplevel entity for the rvex core.
-------------------------------------------------------------------------------
entity rvex is
--=============================================================================
  generic (
    
    -- Configuration.
    CFG                         : rvex_generic_config_type := RVEX_DEFAULT_CONFIG
    
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
    -- Run control interface
    ---------------------------------------------------------------------------
    -- External interrupt request signal, active high.
    rctrl2rv_irq                : in  std_logic_vector(2**CFG.numContextsLog2-1 downto 0) := (others => '0');
    
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
    --  - The signals from the rvex to the memories from all groups with
    --    decouple set low must be ignored; only the highest indexed pipelane
    --    group in a core issues commands to the memories.
    --  - When multiple pipelane groups work together, the instruction memory
    --    must provide syllables to all pipelanes in the group, sending the
    --    first syllable of a bundle to the lower indexed pipelane (groups).
    --    For example, when pipelanes 0 through 3 are working together and the
    --    group is requesting the instruction at 0x12345670, the instruction
    --    memory must provide mem(0x12345670) to pipelane 0, mem(0x12345674) to
    --    pipelane 1, mem(0x12345678) to pipelane 2 and mem(0x1234567C) to
    --    pipelane 3.
    --  - There are no such restrictions on the data memory; the data memory
    --    read value is ignored by pipelane groups with decouple set to 0.
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
    --    group is requesting either an instruction or a data memory
    --    read/write, when either group is stalled, or when the blockReconfig
    --    signal is asserted by the memory for either group.
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
    
    -- (L_IF clock cycles delay with clkEn high and stallOut low; L_IF is set
    -- in rvex_pipeline_pkg.vhd)
    
    -- Combinatorial cancel signal, valid one cycle after imem_pcs and
    -- imem_fetch, regardless of memory stalls. This will go high when a branch
    -- is detected by the next pipeline stage and the previously requested
    -- instruction is not going to be executed. In this case, the instruction
    -- memory may choose not to complete the request if that is faster somehow
    -- (a cache may choose to cancel line validation if a miss occured to allow
    -- the core to continue earlier). Note that this signal can be safely
    -- ignored for proper operation, it's just a hint which may be used to
    -- speed things up.
    rv2imem_cancel              : out std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    
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
    -- Data memory addresses from each pipelane group. Note that address
    -- 0xFFFFFF80 and up is remapped to the core control registers internally,
    -- so anything external in that range will be inaccessible.
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
end rvex;

--=============================================================================
architecture Behavioral of rvex is
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
  
  -- Link from any pipelane group to to the first (lowest indexed) coupled
  -- group.
  signal cfg2any_firstGroup           : rvex_3bit_array(2**CFG.numLaneGroupsLog2-1 downto 0);
  
  -- Matrix specifying connections between context and lane group. Indexing is
  -- done using i = laneGroup*numContexts + context.
  signal cfg2any_contextMap           : std_logic_vector(2**CFG.numLaneGroupsLog2*2**CFG.numContextsLog2-1 downto 0);
  
  -- Last pipelane group associated with each context.
  signal cfg2any_lastGroupForCtxt     : rvex_3bit_array(2**CFG.numLaneGroupsLog2-1 downto 0);
  
  -----------------------------------------------------------------------------
  -- Internal signals
  -----------------------------------------------------------------------------
  -- Stall signal for each pipelane group.
  signal stall                        : std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
  
  -- Extended memory exception trap information. These are decoded from the
  -- fault flags coming from the memory into a trap information record which
  -- the processor knows how to deal with.
  signal imem2rv_exception            : trap_info_array(2**CFG.numLaneGroupsLog2-1 downto 0);
  signal dmem2rv_exception            : trap_info_array(2**CFG.numLaneGroupsLog2-1 downto 0);
  
  -----------------------------------------------------------------------------
  -- Interconnect signals
  -----------------------------------------------------------------------------
  -- Pipelane <-> configuration controller interconnect signals.
  signal cfg2pl_run                   : std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
  signal pl2cfg_blockReconfig         : std_logic_vector(2**CFG.numLanesLog2-1 downto 0);
  
  -- Data memory switch <-> control register bus interconnect signals.
  signal dmsw2creg_addr               : rvex_address_array(2**CFG.numLaneGroupsLog2-1 downto 0);
  signal dmsw2creg_writeData          : rvex_data_array(2**CFG.numLaneGroupsLog2-1 downto 0);
  signal dmsw2creg_writeMask          : rvex_mask_array(2**CFG.numLaneGroupsLog2-1 downto 0);
  signal dmsw2creg_writeEnable        : std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
  signal dmsw2creg_readEnable         : std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
  signal creg2dmsw_readData           : rvex_data_array(2**CFG.numLaneGroupsLog2-1 downto 0);
  
  -- Pipelane <-> general purpose register file interconnect signals.
  signal pl2gpreg_readPorts           : pl2gpreg_readPort_array(2*2**CFG.numLanesLog2-1 downto 0);
  signal gpreg2pl_readPorts           : gpreg2pl_readPort_array(2*2**CFG.numLanesLog2-1 downto 0);
  signal pl2gpreg_writePorts          : pl2gpreg_writePort_array(2**CFG.numLanesLog2-1 downto 0);
  
  -- Context register map <-> context to pipelane interface interconnect
  -- signals.
  signal cxreg2cxplif_brLinkReadPort  : cxreg2pl_readPort_array(2**CFG.numContextsLog2-1 downto 0);
  signal cxplif2cxreg_brLinkWritePort : pl2cxreg_writePort_array(2**CFG.numContextsLog2-1 downto 0);
  signal cxplif2cxreg_PC              : rvex_address_array(2**CFG.numContextsLog2-1 downto 0);
  signal cxreg2cxplif_PC              : rvex_address_array(2**CFG.numContextsLog2-1 downto 0);
  signal cxreg2cxplif_overridePC      : std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
  signal cxreg2cxplif_trapHandler     : rvex_address_array(2**CFG.numContextsLog2-1 downto 0);
  signal cxplif2cxreg_trapInfo        : trap_info_array(2**CFG.numContextsLog2-1 downto 0);
  signal cxplif2cxreg_trapPoint       : trap_info_array(2**CFG.numContextsLog2-1 downto 0);
  signal cxplif2cxreg_rfi             : std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
  signal cxplif2cxreg_brk             : trap_info_array(2**CFG.numContextsLog2-1 downto 0);
  signal cxreg2cxplif_brk             : std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
  signal cxreg2cxplif_breakpoints     : cxreg2pl_breakpoint_info_array(2**CFG.numContextsLog2-1 downto 0);
  signal cxreg2cxplif_ignoreBreakpoint: std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- Generate stalling logic
  -----------------------------------------------------------------------------
  -- The rvex core does not generate stall signals on its own, and the memory
  -- is the only external thing which can stall the core.
  stall <= mem2rv_stallIn;
  
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
    imem2rv_exception(laneGroup) <= (
      active => imem2rv_fault(laneGroup),
      cause  => rvex_trap(RVEX_TRAP_FETCH_FAULT),
      arg    => (others => '0')
    );
    
    -- There is only one data memory fault. Note that the arg parameter will be
    -- overwritten by the address which was being accessed in the pipelane.
    dmem2rv_exception(laneGroup) <= (
      active => dmem2rv_fault(laneGroup),
      cause  => rvex_trap(RVEX_TRAP_DMEM_FAULT),
      arg    => (others => '0')
    );
    
  end generate;
  
  -----------------------------------------------------------------------------
  -- Instantiate the pipelanes
  -----------------------------------------------------------------------------
  pipelanes: entity work.rvex_pipelanes
    generic map (
      CFG                         => CFG
    )
    port map (
      
      -- System control.
      reset                       => reset,
      clk                         => clk,
      clkEn                       => clkEn,
      stall                       => stall,
      
      -- Decoded configuration signals.
      cfg2any_coupled             => cfg2any_coupled,
      cfg2any_decouple            => cfg2any_decouple,
      cfg2any_firstGroup          => cfg2any_firstGroup,
      cfg2any_contextMap          => cfg2any_contextMap,
      cfg2any_lastGroupForCtxt    => cfg2any_lastGroupForCtxt,
      
      -- Configuration and run control.
      cfg2pl_run                  => cfg2pl_run,
      pl2cfg_blockReconfig        => pl2cfg_blockReconfig,
      rctrl2cxplif_irq            => rctrl2rv_irq,
      cxplif2rctrl_irqAck         => rv2rctrl_irqAck,
      rctrl2cxplif_run            => rctrl2rv_run,
      cxplif2rctrl_idle           => rv2rctrl_idle,
      
      -- Instruction memory interface.
      br2imem_PCs                 => rv2imem_PCs,
      br2imem_fetch               => rv2imem_fetch,
      br2imem_cancel              => rv2imem_cancel,
      imem2pl_instr               => imem2rv_instr,
      imem2pl_exception           => imem2rv_exception,
      
      -- Data memory interface.
      dmsw2dmem_addr              => rv2dmem_addr,
      dmsw2dmem_writeData         => rv2dmem_writeData,
      dmsw2dmem_writeMask         => rv2dmem_writeMask,
      dmsw2dmem_writeEnable       => rv2dmem_writeEnable,
      dmsw2dmem_readEnable        => rv2dmem_readEnable,
      dmem2dmsw_readData          => dmem2rv_readData,
      dmem2dmsw_exception         => dmem2rv_exception,
      
      -- Control register interface.
      dmsw2creg_addr              => dmsw2creg_addr,
      dmsw2creg_writeData         => dmsw2creg_writeData,
      dmsw2creg_writeMask         => dmsw2creg_writeMask,
      dmsw2creg_writeEnable       => dmsw2creg_writeEnable,
      dmsw2creg_readEnable        => dmsw2creg_readEnable,
      creg2dmsw_readData          => creg2dmsw_readData,
      
      -- General purpose register file interface.
      pl2gpreg_readPorts          => pl2gpreg_readPorts,
      gpreg2pl_readPorts          => gpreg2pl_readPorts,
      pl2gpreg_writePorts         => pl2gpreg_writePorts,
      
      -- Branch/link register file interface.
      cxreg2cxplif_brLinkReadPort => cxreg2cxplif_brLinkReadPort,
      cxplif2cxreg_brLinkWritePort=> cxplif2cxreg_brLinkWritePort,
      
      -- Special context register interface.
      cxplif2cxreg_PC             => cxplif2cxreg_PC,
      cxreg2cxplif_PC             => cxreg2cxplif_PC,
      cxreg2cxplif_overridePC     => cxreg2cxplif_overridePC,
      cxreg2cxplif_trapHandler    => cxreg2cxplif_trapHandler,
      cxplif2cxreg_trapInfo       => cxplif2cxreg_trapInfo,
      cxplif2cxreg_trapPoint      => cxplif2cxreg_trapPoint,
      cxplif2cxreg_rfi            => cxplif2cxreg_rfi,
      cxplif2cxreg_brk            => cxplif2cxreg_brk,
      cxreg2cxplif_brk            => cxreg2cxplif_brk,
      cxreg2cxplif_breakpoints    => cxreg2cxplif_breakpoints,
      cxreg2cxplif_ignoreBreakpoint=>cxreg2cxplif_ignoreBreakpoint
      
    );
  
end Behavioral;

