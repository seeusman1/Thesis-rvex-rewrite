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
use IEEE.math_real.all;

library std;
use std.textio.all;

library work;
use work.rvex_pkg.all;
use work.rvex_intIface_pkg.all;
use work.rvex_utils_pkg.all;
use work.rvex_simUtils_pkg.all;
use work.rvex_simUtils_scanner_pkg.all;
use work.rvex_simUtils_asDisas_pkg.all;
use work.rvex_simUtils_mem_pkg.all;
use work.rvex_utils_pkg.all;

--=============================================================================
-- This testbench runs test suites for the rvex core. The test suites are
-- defined in a number of files. The file formats are specified below. Note
-- that the file extension is used to determine how a file will be parsed, so
-- they matter.
--
-------------------------------------------------------------------------------
-- *.suite file
-------------------------------------------------------------------------------
-- a *.suite file is just a file listing. The simulation will parse any
-- nonempty line which does not start with -- as a filename relative to the
-- path to index.suite. If it fails to open a file, it will report a warning.
-- When a listed filename end in .suite, it is interpreted as another test
-- suite file.
-- 
-------------------------------------------------------------------------------
-- *.test file
-------------------------------------------------------------------------------
-- These files specify a test case for the processor. Every line which is
-- nonempty or does not start with -- will be parsed as one of the commands
-- below. If parsing fails, the simulation will report a warning. All available
-- commands are listed below. They are case insensitive. Valid numeric data
-- entry methods are listed below that.
-- 
-------------------------------------------------------------------------------
-- Valid *.test file commands
-------------------------------------------------------------------------------
-- name <name>
--   Sets the name of the test case. This is shown in simulation and in all
--   related simulation report statements. When name is not set, it defaults to
--   the filename.
-- 
-- config <key> <value> [<mask>]
--   Fail if the specified key in CFG has a different value. <mask> specifies
--   an optional bitmask (useful in particular for numContexts). Boolean keys
--   should be matched against 0 or 1. Available keys are:
--    - numLanes
--    - numLaneGroups
--    - numContexts
--    - genBundleSize
--    - multiplierLanes
--    - memLaneRevIndex
--    - branchLaneRevIndex
--    - numBreakpoints
--    - forwarding
--    - limmhFromNeighbor
--    - limmhFromPreviousPair
--    - reg63isLink
--    - cregStartAddress
-- 
-- init
--   Initializes the instruction and data memories with all zeros.
-- 
-- at <ptr>
--   Set instruction memory loading pointer to the given value.
-- 
-- load <assembly syllable>
--   Assemble <assembly syllable> and load into instruction memory at the
--   loading pointer, then increment the loading pointer. Assembly syntax is
--   based upon the syntax fields in rvex_opcode_pkg.vhd.
--   
-- loadhex <value>
--   Same as load, but without the assembly step; just loads the given value
--   into the instruction memory.
--   
-- fillnops <ptr>
--   Same as at, but inserts NOPs from the current loading pointer up to <ptr>.
-- 
-- (TODO FROM HERE ONWARDS)
-- 
-- wait <cycles> [memw <ptr> [exclusive] [<value> [exclusive]] | meml <ptr> [exclusive]]
--   Waits for at least <cycles> cycles. If memw or meml is not specified, the
--   wait will succeed, otherwise it will fail unless a memory write or memory
--   load to the specified location occurs within that time. When the expected
--   memory write/load occurs, execution will continue without waiting for the
--   timeout. If "exclusive" is specified after the address, any write/read to
--   ANOTHER address will cause failure. Same logic applies to the value. The
--   checks are insensitive to which memory port requested the operation or to
--   the access size.
--   
-- write [dbg] <word|half|byte> <ptr> <value>
-- read [dbg] <word|half|byte> <ptr> <expected>
--   Set memory at <ptr> to <value> or check that the value at that location is
--   <expected>. If dbg is specified, the debug bus is accessed instead of the
--   data memory, which takes a cycle to complete. <ptr> may be specified as a
--   numerical value, or as a CR_* register index (see also rvex_ctrlRegs_pkg).
--   
-- fault <set|clear> <imem|dmem> <ptr>
--   Marks the given memory location as faulty or clears the marking. When a
--   fauly memory location is accessed, the fault signal to the rvex will be
--   asserted.
-- 
-- rctrl <ctxt> int <id>
--   Assert irq pin for context <ctxt> with irqID set to <id>. The irq pin is
--   released automatically when irqAck goes high.
-- 
-- rctrl <ctxt> reset
--   Resets the specified context. Takes one cycle to complete.
-- 
-- rctrl <ctxt> halt
--   Releases the run flag for the specified context.
-- 
-- rctrl <ctxt> run
--   Asserts the run flag for the specified context.
-- 
-- rctrl <ctxt> chk [not] <idle|done|irq>
--   Ensures that the given context is (not) idle/done, fails otherwise.
-- 
-- reset
--   Resets the entire processor. Takes one cycle to complete.
-- 
-------------------------------------------------------------------------------
-- Numeric data entry
-------------------------------------------------------------------------------
-- Numerical values may be specified as follows:
--  - In decimal.
--  - In hexadecimal, by prefixing the number with 0x.
--  - In binary, by prefixing the number with 0b.
-- 
-------------------------------------------------------------------------------
entity rvex_tb is
end rvex_tb;
-------------------------------------------------------------------------------
architecture Behavioral of rvex_tb is
--=============================================================================
  
  -- Test case or test suite file under test. This will determine what the
  -- testbench will do.
  constant ROOT_FILE            : string := "../tests/index.suite";
  
  -- Core configuration under test. Due to VHDL constraints, this cannot be
  -- changed by the test cases runtime. Instead, you select the configuration
  -- here and the test cases will check if they are compatible with it.
  constant CFG                  : rvex_generic_config_type := (

    -- log2 of the number of lanes to instantiate.
    numLanesLog2                => 3,
    
    -- log2 of the number of lane groups to instantiate. Each lane group can be
    -- disabled individually to save power, operate on its own, or work
    -- together on a single thread with other lane groups. May not be greater
    -- than 3 (due to configuration register size limits) or numLanesLog2.
    numLaneGroupsLog2           => 2,
    
    -- log2 of the number of hardware contexts in the core. May not be greater
    -- than 3 due to configuration register size limits.
    numContextsLog2             => 2,
    
    -- log2 of the number of syllables in a generic binary bundle. All branch
    -- targets are assumed to be aligned to this, but trap return addresses may
    -- not be. When a trap return address is not aligned to this and
    -- limmhFromPreviousPair is set, then special actions will be taken to
    -- ensure that the relevant syllables preceding the trap point are fetched
    -- before operation resumes.
    genBundleSizeLog2           => 3,
    
    -- Defines which lanes have a multiplier. Bit 0 of this number maps to lane
    -- 0, bit 1 to lane 1, etc.
    multiplierLanes             => 2#11111111#,
    
    -- Lane index for the memory unit, counting down from the last lane in each
    -- lane group. So memLaneRevIndex = 0 results in the memory unit being in
    -- the last lane in each group, memLaneRevIndex = 1 results in it being in
    -- the second to last lane, etc.
    memLaneRevIndex             => 1,
    
    -- Lane index for the branch unit, counting down from the last lane in each
    -- lane group. So branchLaneRevIndex = 0 results in the branch unit being
    -- in the last lane in each group, branchLaneRevIndex = 1 results in it
    -- being in the second to last lane, etc.
    branchLaneRevIndex          => 0,
    
    -- Defines how many hardware breakpoints are evaluated. Maximum is 4 due to
    -- the register map only having space for 4.
    numBreakpoints              => 4,
    
    -- Whether or not register forwarding logic should be instantiated. With
    -- forwarding disabled, the core will use less area and might run at higher
    -- frequencies, but much more NOPs are necessary between data-dependent
    -- instructions.
    forwarding                  => true,
    
    -- When true, syllables can borrow long immediates from the other syllable
    -- in a syllable pair.
    limmhFromNeighbor           => true,
    
    -- When true, syllables can borrow long immediates from the previous
    -- syllable pair (with the same index within the pair) within a generic
    -- binary bundle.
    limmhFromPreviousPair       => true,
    
    -- When true, general purpose register 63 maps directly to the link
    -- register. When false, MTL, MFL, STL and LDL must be used to access the
    -- link register.
    reg63isLink                 => false,
    
    -- Start address in the data address space for the 128-byte control
    -- register file. Must be aligned to a 128-byte boundary.
    cregStartAddress            => X"FFFFFF80",
    
    -- Configures the reset address for each context. Should all be set to 0
    -- for the test cases to run correctly.
    resetVectors                => (others => (others => '0'))
    
  );
  
  -- This signal strobes every 100 us, marking the start of a new test case,
  -- keeping the simulation nice and clean.
  signal sync                   : std_logic;
  
  -----------------------------------------------------------------------------
  -- Signals going to and coming from the rvex
  -----------------------------------------------------------------------------
  -- System control.
  signal reset                  : std_logic;
  signal clk                    : std_logic;
  signal clkEn                  : std_logic;
  
  -- Run control interface.
  signal rctrl2rv_irq           : std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
  signal rctrl2rv_irqID         : rvex_address_array(2**CFG.numContextsLog2-1 downto 0);
  signal rv2rctrl_irqAck        : std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
  signal rctrl2rv_run           : std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
  signal rv2rctrl_idle          : std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
  signal rctrl2rv_reset         : std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
  signal rv2rctrl_done          : std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
  
  -- Common memory interface.
  signal rv2mem_decouple        : std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
  signal mem2rv_blockReconfig   : std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
  signal mem2rv_stallIn         : std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
  signal rv2mem_stallOut        : std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
  
  -- Instruction memory interface.
  signal rv2imem_PCs            : rvex_address_array(2**CFG.numLaneGroupsLog2-1 downto 0);
  signal rv2imem_fetch          : std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
  signal rv2imem_cancel         : std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
  signal imem2rv_instr          : rvex_syllable_array(2**CFG.numLanesLog2-1 downto 0);
  signal imem2rv_affinity       : std_logic_vector(2**CFG.numLaneGroupsLog2*CFG.numLaneGroupsLog2-1 downto 0);
  signal imem2rv_fault          : std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
  
  -- Data memory interface.
  signal rv2dmem_addr           : rvex_address_array(2**CFG.numLaneGroupsLog2-1 downto 0);
  signal rv2dmem_readEnable     : std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
  signal rv2dmem_writeData      : rvex_data_array(2**CFG.numLaneGroupsLog2-1 downto 0);
  signal rv2dmem_writeMask      : rvex_mask_array(2**CFG.numLaneGroupsLog2-1 downto 0);
  signal rv2dmem_writeEnable    : std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
  signal dmem2rv_readData       : rvex_data_array(2**CFG.numLaneGroupsLog2-1 downto 0);
  signal dmem2rv_fault          : std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
  
  -- Control/debug bus interface.
  signal dbg2rv_addr            : rvex_address_type;
  signal dbg2rv_readEnable      : std_logic;
  signal dbg2rv_writeEnable     : std_logic;
  signal dbg2rv_writeMask       : rvex_mask_type;
  signal dbg2rv_writeData       : rvex_data_type;
  signal rv2dbg_readData        : rvex_data_type;
  
  -----------------------------------------------------------------------------
  -- Memory <-> test case runner process communication
  -----------------------------------------------------------------------------
  -- The signals below form the communication between the process which handles
  -- the instruction and data memories and the process which handles test case
  -- commands. These signals are clockless, so to speak; they need to all be
  -- assigned in the same simulation cycle and will then be processed in the
  -- next delta delay. It's done like this instead of putting the entire memory
  -- in a signal to prevent excessive copying every cycle internally in the
  -- simulator (because signal assignments are buffered until the next
  -- simulation step), and a shared variable wouldn't work right either due to
  -- the lack of synchronization primitives in VHDL.
  
  -- Operation selection. The operation is performed when the rising edge is
  -- detected on the signal. The fault operation uses bit 0 as well to
  -- determine whether to set or clear the fault flag, as well as the address
  -- and select signals.
  signal stim2mem_clearEnable   : std_logic;
  signal stim2mem_writeEnable   : std_logic;
  signal stim2mem_readEnable    : std_logic;
  signal stim2mem_faultEnable   : std_logic;
  
  -- Selects between accessing the instruction memory (high) and the data
  -- memory (low). Ignored for clear operations.
  signal stim2mem_select        : std_logic;
  constant IMEM_SELECT          : std_logic := '1';
  constant DMEM_SELECT          : std_logic := '0';
  
  -- Address to operate on. Ignored for clear operations.
  signal stim2mem_addr          : rvex_address_type;
  
  -- Write mask and data for write operations.
  signal stim2mem_writeMask     : rvex_mask_type;
  signal stim2mem_writeData     : rvex_data_type;
  
  -- Read data, valid two delta delays after the read command is issued.
  signal mem2stim_readData      : rvex_data_type;
  
  -----------------------------------------------------------------------------
  -- Interrupt controller <-> test case runner process communication
  -----------------------------------------------------------------------------
  -- The signals below form the communication between the process which models
  -- the interrupt controller and the process which handles test case commands.
  -- They work the same way as the memory interface signals. When a rising edge
  -- is detected on the enable signal, the interrupt identified by id is
  -- requested for the given context until the rvex raises the irqAck signal
  -- for one cycle.
  signal stim2irq_enable        : std_logic;
  signal stim2irq_ctxt          : natural;
  signal stim2irq_id            : rvex_data_type;
  
  -----------------------------------------------------------------------------
  -- Simulation state signals
  -----------------------------------------------------------------------------
  -- You probably want to trace these.
  
  -- Name of the current test case.
  signal sim_currentTest        : rvex_string_type;
  
  -- Current execution state information from the rvex.
  signal sim_rvexState          : rvex_string_array(1 to 2*2**CFG.numLanesLog2+2**CFG.numLaneGroupsLog2+2**CFG.numContextsLog2);
  
  -- These signal will strobe for every completed (beit successful or failure)
  -- test case.
  signal sim_complete           : std_logic;
  
  -- These signal will strobe for every failed test case.
  signal sim_failure            : std_logic;
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  --===========================================================================
  -- Instantiate the rvex processor
  --===========================================================================
  uut: entity work.rvex
    generic map (
      CFG                       => CFG
    )
    port map (
      
      -- System control.
      reset                     => reset,
      clk                       => clk,
      clkEn                     => clkEn,
      
      -- VHDL simulation debug information.
      rv2sim                    => sim_rvexState,
      
      -- Run control interface.
      rctrl2rv_irq              => rctrl2rv_irq,
      rctrl2rv_irqID            => rctrl2rv_irqID,
      rv2rctrl_irqAck           => rv2rctrl_irqAck,
      rctrl2rv_run              => rctrl2rv_run,
      rv2rctrl_idle             => rv2rctrl_idle,
      rctrl2rv_reset            => rctrl2rv_reset,
      rv2rctrl_done             => rv2rctrl_done,
      
      -- Common memory interface.
      rv2mem_decouple           => rv2mem_decouple,
      mem2rv_blockReconfig      => mem2rv_blockReconfig,
      mem2rv_stallIn            => mem2rv_stallIn,
      rv2mem_stallOut           => rv2mem_stallOut,
      
      -- Instruction memory interface.
      rv2imem_PCs               => rv2imem_PCs,
      rv2imem_fetch             => rv2imem_fetch,
      rv2imem_cancel            => rv2imem_cancel,
      imem2rv_instr             => imem2rv_instr,
      imem2rv_affinity          => imem2rv_affinity,
      imem2rv_fault             => imem2rv_fault,
      
      -- Data memory interface.
      rv2dmem_addr              => rv2dmem_addr,
      rv2dmem_readEnable        => rv2dmem_readEnable,
      rv2dmem_writeData         => rv2dmem_writeData,
      rv2dmem_writeMask         => rv2dmem_writeMask,
      rv2dmem_writeEnable       => rv2dmem_writeEnable,
      dmem2rv_readData          => dmem2rv_readData,
      dmem2rv_fault             => dmem2rv_fault,
      
      -- Control/debug bus interface.
      dbg2rv_addr               => dbg2rv_addr,
      dbg2rv_readEnable         => dbg2rv_readEnable,
      dbg2rv_writeEnable        => dbg2rv_writeEnable,
      dbg2rv_writeMask          => dbg2rv_writeMask,
      dbg2rv_writeData          => dbg2rv_writeData,
      rv2dbg_readData           => rv2dbg_readData
      
    );
  
  --===========================================================================
  -- Memory modelling
  --===========================================================================
  mem_model: process (
    
    -- Synchronization with the read/write ports of the rvex instance.
    clk,
    
    -- Synchronization with the test case runner program.
    stim2mem_clearEnable, stim2mem_writeEnable, stim2mem_readEnable,
    stim2mem_faultEnable
    
  ) is
    
    -- Memories. imem and dmem are the instruction and data memories. fmem
    -- contains flags for either. Flag bit 0 determines whether accessing an
    -- instruction at that location should return a fault, bit 1 does the
    -- same thing for the data memory.
    variable imem               : rvmem_memoryState_type;
    variable dmem               : rvmem_memoryState_type;
    variable fmem               : rvmem_memoryState_type;
    constant FLAG_IM_FAULT_BIT  : natural := 0;
    constant FLAG_DM_FAULT_BIT  : natural := 1;
    
    -- Locals/shorthands.
    variable lanePCs            : rvex_address_array(2**CFG.numLanesLog2-1 downto 0);
    variable fetch              : std_logic_vector(2**CFG.numLanesLog2-1 downto 0);
    variable revDecouple        : std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    variable fault              : std_logic;
    variable flags              : rvex_data_type;
    
  begin
    
    -- Handle bus commands from the rvex.
    if rising_edge(clk) then
      if reset = '1' then
        mem2rv_blockReconfig <= (others => '0'); -- TODO, signal is not handled yet.
        mem2rv_stallIn <= (others => '0'); -- TODO, signal is not handled yet.
        imem2rv_instr <= (others => (others => RVEX_UNDEF));
        imem2rv_affinity <= (others => '0');
        imem2rv_fault <= (others => '0');
        dmem2rv_readData <= (others => (others => RVEX_UNDEF));
        dmem2rv_fault <= (others => '0');
      elsif clkEn = '1' then
        
        -- Determine the active bundle program counter and fetch for each lane
        -- group.
        for laneGroup in 2**CFG.numLaneGroupsLog2-1 downto 0 loop
          if rv2mem_decouple(laneGroup) = '1' or laneGroup = 2**CFG.numLaneGroupsLog2-1 then
            lanePCs(group2firstLane(laneGroup, CFG)) := rv2imem_PCs(laneGroup);
            fetch(group2firstLane(laneGroup, CFG)) := rv2imem_fetch(laneGroup);
          else
            lanePCs(group2firstLane(laneGroup, CFG)) := lanePCs(group2firstLane(laneGroup+1, CFG));
            fetch(group2firstLane(laneGroup, CFG)) := fetch(group2firstLane(laneGroup+1, CFG));
          end if;
        end loop;
        
        -- Go through the lane groups in increasing order and increment by 4
        -- for each coupled lane.
        revDecouple := rv2mem_decouple(2**CFG.numLaneGroupsLog2-2 downto 0) & "1";
        for lane in 1 to 2**CFG.numLanesLog2-1 loop
          if lane2group(lane, CFG) = lane2group(lane-1, CFG) or revDecouple(lane2group(lane, CFG)) = '0' then
            lanePCs(lane) := std_logic_vector(vect2unsigned(lanePCs(lane-1)) + 4);
            fetch(lane) := fetch(lane-1);
          end if;
        end loop;
        
        -- Handle instruction memory access for each lane.
        fault := '0';
        for lane in 1 to 2**CFG.numLanesLog2-1 loop
          
          -- If fetch is high and the group is not stalled, return the syllable
          -- at the decoded PC and load the fault signal from the flag memory.
          if (fetch(lane) = '1') and (rv2mem_stallOut(lane2group(lane, CFG)) = '0') then
            imem2rv_instr(lane) <= rvmem_read(imem, lanePCs(lane));
            fault := fault or rvmem_read(fmem, lanePCs(lane))(FLAG_IM_FAULT_BIT);
          else
            imem2rv_instr(lane) <= (others => RVEX_UNDEF);
          end if;
          
          -- Forward fault signal if this is the last lane in a coupled group.
          if lane = lane2lastLane(lane, CFG) then
            if rv2mem_decouple(lane2group(lane, CFG)) = '1' then
              imem2rv_fault(lane2group(lane, CFG)) <= fault;
              fault := '0';
            else
              imem2rv_fault(lane2group(lane, CFG)) <= '0';
            end if;
          end if;
          
        end loop;
        
        -- Handle data memory access for each lane group.
        for laneGroup in 1 to 2**CFG.numLaneGroupsLog2-1 loop
          
          -- Default to no fault and invalid returned data.
          dmem2rv_fault(laneGroup) <= '0';
          dmem2rv_readData(laneGroup) <= (others => RVEX_UNDEF);
          
          -- Only handle commands from the last memory unit in a coupled group,
          -- and only when the group is not stalled.
          if (rv2mem_decouple(laneGroup) = '1') and (rv2mem_stallOut(laneGroup) = '0') then
            if rv2dmem_writeEnable(laneGroup) = '1' then
              
              -- Handle writes. Only perform the write if we do not return a
              -- fault.
              fault := rvmem_read(fmem, rv2dmem_addr(laneGroup))(FLAG_DM_FAULT_BIT);
              if fault = '0' then
                rvmem_write(
                  mem   => dmem,
                  addr  => rv2dmem_addr(laneGroup),
                  value => rv2dmem_writeData(laneGroup),
                  mask  => rv2dmem_writeMask(laneGroup)
                );
              end if;
              dmem2rv_fault(laneGroup) <= fault;
              
            elsif rv2dmem_readEnable(laneGroup) = '1' then
              
              -- Handle reads.
              dmem2rv_fault(laneGroup)    <= rvmem_read(fmem, rv2dmem_addr(laneGroup))(FLAG_DM_FAULT_BIT);
              dmem2rv_readData(laneGroup) <= rvmem_read(dmem, rv2dmem_addr(laneGroup));
              
            end if;
          end if;
          
        end loop;
        
      end if;
    end if;
    
    -- Handle test case runner commands.
    if rising_edge(stim2mem_clearEnable) then
      
      -- Clear instruction and data memory.
      rvmem_clear(imem, '0');
      rvmem_clear(dmem, '0');
      rvmem_clear(fmem, '0');
      
    elsif rising_edge(stim2mem_writeEnable) then
      
      -- Handle writes.
      if stim2mem_select = IMEM_SELECT then
        rvmem_write(
          mem   => imem, -- Instruction memory.
          addr  => stim2mem_addr,
          value => stim2mem_writeData,
          mask  => stim2mem_writeMask
        );
      else
        rvmem_write(
          mem   => dmem, -- Data memory.
          addr  => stim2mem_addr,
          value => stim2mem_writeData,
          mask  => stim2mem_writeMask
        );
      end if;
      
    elsif rising_edge(stim2mem_readEnable) then
      
      -- Handle reads.
      if stim2mem_select = IMEM_SELECT then
        mem2stim_readData <= rvmem_read(
          mem   => imem, -- Instruction memory.
          addr  => stim2mem_addr
        );
      else
        mem2stim_readData <= rvmem_read(
          mem   => dmem, -- Data memory.
          addr  => stim2mem_addr
        );
      end if;
      
    elsif rising_edge(stim2mem_faultEnable) then
      
      -- Read the current value of the flags.
      flags := rvmem_read(
        mem   => fmem,
        addr  => stim2mem_addr
      );
      
      -- Set or clear the requested bit.
      if stim2mem_select = IMEM_SELECT then
        flags(FLAG_IM_FAULT_BIT) := stim2mem_writeData(0);
      else
        flags(FLAG_DM_FAULT_BIT) := stim2mem_writeData(0);
      end if;
      
      -- Write the new value to the flag memory.
      rvmem_write(
        mem   => fmem,
        addr  => stim2mem_addr,
        value => flags
      );
      
    end if;
    
  end process;
  
  --===========================================================================
  -- Interrupt controller model
  --===========================================================================
  irq_model: process (
    
    -- Synchronization with the rvex instance.
    clk,
    
    -- Synchronization with the test case runner program.
    stim2irq_enable
    
  ) is
    variable ctxt : natural;
  begin
    
    -- Handle synchronization with the rvex.
    if rising_edge(clk) then
      if reset = '1' then
        rctrl2rv_irq <= (others => '0');
        rctrl2rv_irqID <= (others => (others => RVEX_UNDEF));
      elsif clkEn = '1' then
        for context in 0 to 2**CFG.numContextsLog2-1 loop
          if rv2rctrl_irqAck(context) = '1' then
            rctrl2rv_irq <= (others => '0');
            rctrl2rv_irqID <= (others => (others => RVEX_UNDEF));
          end if;
        end loop;
      end if;
    end if;
    
    -- Handle synchronization with the test case runner.
    if rising_edge(stim2irq_enable) then
      rctrl2rv_irq(stim2irq_ctxt) <= '1';
      rctrl2rv_irqID(stim2irq_ctxt) <= stim2irq_id;
    end if;
    
  end process;  
  
  --===========================================================================
  -- Test case runner
  --===========================================================================
  sync_gen: process is
  begin
    sync <= '0';
    wait for 100 us;
    sync <= '1';
    wait for 0 ns;
  end process;
  test_cases: process is
    
    -- Result code for the test case command running method. Continue means
    -- that the runner should proceed to the next command. Success, fail and
    -- abort mean that the test should be terminated with either success,
    -- failure or unknown respectively. The latter is returned when something
    -- went wrong with the test runner itself and the test cannot be completed.
    type testCommandResult_type is (TCCR_CONTINUE, TCCR_SUCCESS, TCCR_FAIL, TCCR_ABORT);
    
    -- Test success/failed counters.
    variable testCount    : natural := 0;
    variable failedTests  : natural := 0;
    variable abortedTests : natural := 0;
    
    -- Seed variables for random generators.
    variable seed1        : positive := 1;
    variable seed2        : positive := 1;
    
    -- Loading pointer for at, load, loadhex and fillnops.
    variable loadPtr      : rvex_address_type;
    
    -- Current line number in the test case file.
    variable curLineNr    : natural;
    
    ---------------------------------------------------------------------------
    -- Generates a number of clock cycles
    ---------------------------------------------------------------------------
    procedure cycles(
      count     : in natural;
      clkEnProb : in real := 1.0
    ) is
      variable counter  : natural;
      variable r        : real;
    begin
      clkEn <= '1';
      counter := 0;
      while counter < count loop
        
        -- Generate clkEn signal.
        if clkEnProb < 1.0 then
          uniform(seed1, seed2, r);
          if r < clkEnProb then
            clkEn <= '1';
            counter := counter + 1;
          else
            clkEn <= '0';
          end if;
        else
          counter := counter + 1;
        end if;
        
        -- Generate a clock cycle.
        wait for 5 ns;
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        wait for 0 ns;
        
      end loop;
    end cycles;
    
    ---------------------------------------------------------------------------
    -- Executes a 'config' command
    ---------------------------------------------------------------------------
    -- config <key> <value> [<mask>]
    procedure executeConfig(
      l       : in    string;
      pos     : inout positive;
      result  : out   testCommandResult_type
    ) is
      
      -- Token containing the key name.
      variable token  : line;
      
      -- Actual value, requested value and mask.
      variable actVal : signed(32 downto 0);
      variable reqVal : signed(32 downto 0);
      variable mask   : signed(32 downto 0);
      
      -- Local indicating whether numeric parsing was successful.
      variable ok     : boolean;
      
    begin
      
      -- Scan the key token.
      scanToken(l, pos, token);
      if token = null then
        report "Error parsing test case 'config' command: '" & l & "'. "
             & "Aborting."
          severity warning;
        result := TCCR_ABORT;
        return;
      end if;
      
      -- Load the value of the key.
      if matchStr(token.all, "numLanes") then
        actVal := to_signed(2**CFG.numLaneGroupsLog2, 33);
      elsif matchStr(token.all, "numLaneGroups") then
        actVal := to_signed(2**CFG.numLaneGroupsLog2, 33);
      elsif matchStr(token.all, "numContexts") then
        actVal := to_signed(2**CFG.numContextsLog2, 33);
      elsif matchStr(token.all, "genBundleSize") then
        actVal := to_signed(2**CFG.genBundleSizeLog2, 33);
      elsif matchStr(token.all, "multiplierLanes") then
        actVal := to_signed(CFG.multiplierLanes, 33);
      elsif matchStr(token.all, "memLaneRevIndex") then
        actVal := to_signed(CFG.memLaneRevIndex, 33);
      elsif matchStr(token.all, "branchLaneRevIndex") then
        actVal := to_signed(CFG.branchLaneRevIndex, 33);
      elsif matchStr(token.all, "numBreakpoints") then
        actVal := to_signed(CFG.numBreakpoints, 33);
      elsif matchStr(token.all, "forwarding") then
        if CFG.forwarding then
          actVal := to_signed(1, 33);
        else
          actVal := to_signed(0, 33);
        end if;
      elsif matchStr(token.all, "limmhFromNeighbor") then
        if CFG.limmhFromNeighbor then
          actVal := to_signed(1, 33);
        else
          actVal := to_signed(0, 33);
        end if;
      elsif matchStr(token.all, "limmhFromPreviousPair") then
        if CFG.limmhFromPreviousPair then
          actVal := to_signed(1, 33);
        else
          actVal := to_signed(0, 33);
        end if;
      elsif matchStr(token.all, "reg63isLink") then
        if CFG.reg63isLink then
          actVal := to_signed(1, 33);
        else
          actVal := to_signed(0, 33);
        end if;
      elsif matchStr(token.all, "cregStartAddress") then
        actVal := "0" & signed(CFG.cregStartAddress);
      else
        report "Unknown config key: '" & token.all & "'. "
             & "Aborting."
          severity warning;
        result := TCCR_ABORT;
        return;
      end if;
      
      -- Scan the expected/requested value.
      scanNumeric(l, pos, reqVal, ok);
      if not ok then
        report "Error parsing test case 'config' command: '" & l & "'. "
             & "Aborting."
          severity warning;
        result := TCCR_ABORT;
        return;
      end if;
      
      -- Scan the optional bitmask.
      scanNumeric(l, pos, mask, ok);
      if not ok then
        mask := (others => '1');
      end if;
      
      -- Perform the comparison.
      if (actVal and mask) /= (reqVal and mask) then
        report "Test case requires that configuration key '" & token.all
             & "' is set to a different value. Aborting."
          severity warning;
        result := TCCR_ABORT;
        return;
      end if;
      
      -- Everything is OK.
      result := TCCR_CONTINUE;
      
    end executeConfig;
    
    ---------------------------------------------------------------------------
    -- Executes an 'at' command
    ---------------------------------------------------------------------------
    -- at <ptr>
    procedure executeAt(
      l       : in    string;
      pos     : inout positive;
      result  : out   testCommandResult_type
    ) is
      
      -- New value for the loading pointer, as scanNumeric returns it.
      variable newVal : signed(32 downto 0);
      
      -- Local indicating whether numeric parsing was successful.
      variable ok     : boolean;
      
    begin
      
      -- Scan the new pointer.
      scanNumeric(l, pos, newVal, ok);
      if not ok then
        report "Error parsing test case 'at' command: '" & l & "'. "
             & "Aborting."
          severity warning;
        result := TCCR_ABORT;
        return;
      end if;
      
      -- Set the loading pointer.
      loadPtr := std_logic_vector(newVal(31 downto 0));
      
      -- Everything is OK.
      result := TCCR_CONTINUE;
      
    end executeAt;
    
    ---------------------------------------------------------------------------
    -- Executes a 'load' command
    ---------------------------------------------------------------------------
    -- load <assembly syllable>
    procedure executeLoad(
      l       : in    string;
      pos     : inout positive;
      result  : out   testCommandResult_type
    ) is
      variable assembly : string(1 to l'length+1-pos);
      variable syllable : rvex_syllable_type;
      variable ok       : boolean;
      variable error    : rvex_string_builder_type;
    begin
      
      -- Defer to rvex_simUtils_asDisas_pkg.
      assembly := l(pos to l'length);
      assembleLine(
        source    => assembly,
        line      => curLineNr,
        syllable  => syllable,
        ok        => ok,
        error     => error
      );
      
      -- Check for errors.
      if not ok then
        report "Assembly error: " & rvs2str(error) & ". Aborting."
          severity warning;
        result := TCCR_ABORT;
        return;
      end if;
      
      -- Load the word into memory.
      stim2mem_writeEnable <= '1';
      stim2mem_select <= IMEM_SELECT;
      stim2mem_addr <= loadPtr;
      stim2mem_writeMask <= (others => '1');
      stim2mem_writeData <= syllable;
      wait for 0 ns;
      stim2mem_writeEnable <= '0';
      wait for 0 ns;
      
      -- Increment the loading pointer.
      loadPtr := std_logic_vector(vect2unsigned(loadPtr) + 4);
      
      -- Everything is OK.
      result := TCCR_CONTINUE;
      
    end executeLoad;
    
    ---------------------------------------------------------------------------
    -- Executes a 'loadhex' command
    ---------------------------------------------------------------------------
    -- loadhex <value>
    procedure executeLoadHex(
      l       : in    string;
      pos     : inout positive;
      result  : out   testCommandResult_type
    ) is
      variable val    : signed(32 downto 0);
      variable ok     : boolean;
    begin
      
      -- Scan the new pointer.
      scanNumeric(l, pos, val, ok);
      if not ok then
        report "Error parsing test case 'loadhex' command: '" & l & "'. "
             & "Aborting."
          severity warning;
        result := TCCR_ABORT;
        return;
      end if;
      
      -- Load the word into memory.
      stim2mem_writeEnable <= '1';
      stim2mem_select <= IMEM_SELECT;
      stim2mem_addr <= loadPtr;
      stim2mem_writeMask <= (others => '1');
      stim2mem_writeData <= std_logic_vector(val(31 downto 0));
      wait for 0 ns;
      stim2mem_writeEnable <= '0';
      wait for 0 ns;
      
      -- Increment the loading pointer.
      loadPtr := std_logic_vector(vect2unsigned(loadPtr) + 4);
      
      -- Everything is OK.
      result := TCCR_CONTINUE;
      
    end executeLoadHex;
    
    ---------------------------------------------------------------------------
    -- Executes a 'fillnops' command
    ---------------------------------------------------------------------------
    -- load <assembly syllable>
    procedure executeFillNops(
      l       : in    string;
      pos     : inout positive;
      result  : out   testCommandResult_type
    ) is
      variable syllable : rvex_syllable_type;
      variable error    : rvex_string_builder_type;
      variable untilPtr : signed(32 downto 0);
      variable ok       : boolean;
    begin
      
      -- Scan the new pointer.
      scanNumeric(l, pos, untilPtr, ok);
      if not ok then
        report "Error parsing test case 'fillnops' command: '" & l & "'. "
             & "Aborting."
          severity warning;
        result := TCCR_ABORT;
        return;
      end if;
      if "0" & vect2signed(loadPtr) > untilPtr then
        report "Error in 'fillnops' command: load pointer is greater than the "
             & "end pointer. Aborting."
          severity warning;
        result := TCCR_ABORT;
        return;
      end if;
      
      -- Assemble a NOP instruction.
      assembleLine(
        source    => "nop",
        line      => curLineNr,
        syllable  => syllable,
        ok        => ok,
        error     => error
      );
      if not ok then
        report "Could not assembly nop instruction: " & rvs2sim(error) & ". Aborting."
          severity warning;
        result := TCCR_ABORT;
        return;
      end if;
      
      -- Replicate the NOP instruction.
      while "0" & vect2signed(loadPtr) < untilPtr loop
        
        -- Load the NOP.
        stim2mem_writeEnable <= '1';
        stim2mem_select <= IMEM_SELECT;
        stim2mem_addr <= loadPtr;
        stim2mem_writeMask <= (others => '1');
        stim2mem_writeData <= syllable;
        wait for 0 ns;
        stim2mem_writeEnable <= '0';
        wait for 0 ns;
      
        -- Increment the loading pointer.
        loadPtr := std_logic_vector(vect2unsigned(loadPtr) + 4);
        
      end loop;
      
      -- Everything is OK.
      result := TCCR_CONTINUE;
      
    end executeFillNops;
    
    ---------------------------------------------------------------------------
    -- Executes a line in a test case file
    ---------------------------------------------------------------------------
    procedure executeLine(
      l       : in  string;
      result  : out testCommandResult_type
    ) is
      variable pos    : positive;
      variable token  : line;
    begin
      
      -- Set result to continue by default.
      result := TCCR_CONTINUE;
      
      -- Scan the first token.
      pos := 1;
      scanToken(l, pos, token);
      if token = null then
        report "Error parsing test case command: '" & l & "'. "
             & "Aborting."
          severity warning;
        result := TCCR_ABORT;
        return;
      end if;
      
      -- Execute the command.
      if matchStr(token.all, "name") then
        sim_currentTest <= rvs2sim(to_rvs(l(pos to l'length)));
      elsif matchStr(token.all, "config") then
        executeConfig(l, pos, result);
      elsif matchStr(token.all, "at") then
        executeAt(l, pos, result);
      elsif matchStr(token.all, "load") then
        executeLoad(l, pos, result);
      elsif matchStr(token.all, "loadhex") then
        executeLoadHex(l, pos, result);
      elsif matchStr(token.all, "fillnops") then
        executeFillNops(l, pos, result);
      elsif matchStr(token.all, "init") then
        if pos <= l'length then
          report "Garbage at end of line in test case file. Aborting."
            severity warning;
          result := TCCR_ABORT;
        end if;
        stim2mem_clearEnable <= '1';
        wait for 0 ns;
        stim2mem_clearEnable <= '0';
        wait for 0 ns;
        loadPtr := (others => '0');
      else
        -- Unknown command, abort.
        report "Unknown command in test case file: '" & l & "'. "
             & "Aborting."
          severity warning;
        result := TCCR_ABORT;
      end if;
      
    end executeLine;
    
    ---------------------------------------------------------------------------
    -- Runs a test case/test suite
    ---------------------------------------------------------------------------
    procedure handleFile(
      fname   : in  string
    ) is
      
      -- File handle for the input file.
      file     f      : text;
      
      -- File opening result.
      variable status : file_open_status;
      
      -- This is set to the path of the input file name, up to and including
      -- the last (back)slash.
      variable path   : rvex_string_builder_type;
      
      -- File type specification. Determined based on the filename.
      type testFileType_type is (TF_SUITE, TF_TEST);
      variable ftype  : testFileType_type;
      
      -- Line manipulation variables.
      variable l, l2  : line;
      variable lstart : natural;
      variable lend   : natural;
      
      -- Current line number.
      variable lNr    : natural;
      
      -- Test result code.
      variable testRes: testCommandResult_type;
      
    begin
      
      -- Determine the file type.
      for i in fname'length downto 1 loop
        if fname(i) = '.' then
          if fname(i to fname'length) = ".suite" then
            ftype := TF_SUITE;
          elsif fname(i to fname'length) = ".test" then
            ftype := TF_TEST;
          else
            report "Unknown file extension for " & fname & ". Should be .suite or "
                 & ".test. Skipping file."
              severity warning;
            return;
          end if;
          exit;
        end if;
      end loop;
      
      -- Figure out the path to this file.
      path := to_rvs(fname);
      while path.len > 0 loop
        exit when path.s(path.len) = '/' or path.s(path.len) = '\';
        path.len := path.len - 1;
      end loop;
      
      -- Try to open the file.
      file_open(status, f, fname, read_mode);
      if status /= OPEN_OK then
        report "Error opening file " & fname & ": "
            & file_open_status'image(status) & ". Skipping file."
          severity warning;
        return;
      end if;
      
      -- If this is a test case file, do some housekeeping.
      if ftype = TF_TEST then
        
        -- Align to a large time boundary in  simulation time to keep the test
        -- cases easily distinguishable.
        wait until rising_edge(sync);
        
        -- Clear the success and failure signals.
        sim_complete <= '0';
        sim_failure <= '0';
        
        -- Set the name of the test case to the filename until a name command
        -- is executed.
        sim_currentTest <= rvs2sim(to_rvs(fname));
        
      end if;
      
      -- Report that we've loaded a file.
      if ftype = TF_SUITE then
        report "Entering test suite " & fname & "..." severity note;
      elsif ftype = TF_TEST then
        report "Running test case file " & fname & "..." severity note;
      end if;
      
      -- Read the file line by line.
      testRes := TCCR_CONTINUE;
      lNr := 0;
      while not endfile(f) loop
        
        -- Read a line.
        readline(f, l);
        lNr := lNr + 1;
        curLineNr := lNr;
        
        -- Strip comments and whitespace, and skip empty lines.
        for i in 1 to l.all'length loop
          lstart := i;
          exit when not isWhitespaceChar(l.all(i));
        end loop;
        lend := lstart - 1;
        for i in lstart to l.all'length loop
          exit when (i < l.all'length) and l.all(i to i+1) = "--";
          if not isWhitespaceChar(l.all(i)) then
            lend := i;
          end if;
        end loop;
        if lend < lstart then
          next;
        end if;
        l2 := new string(1 to (lend - lstart) + 1);
        l2.all := l.all(lstart to lend);
        deallocate(l);
        l := l2;
        l2 := null;
        
        -- If this is a test suite file, handle the line by interpreting it as
        -- a filename.
        if ftype = TF_SUITE then
          handleFile(rvs2str(path) & l.all);
          next;
        end if;
        
        -- If this is a test case file, defer the line handling to the
        -- appropriate method.
        if ftype = TF_TEST then
          executeLine(
            l       => l.all,
            result  => testRes
          );
          case testRes is
            when TCCR_CONTINUE => next;
            when others        => exit;
          end case;
        end if;
        
        -- Handle unknown file types.
        report "Trying to process " & testFileType_type'image(ftype) & " file, "
             & "but no handler exists. Aborting."
          severity warning;
        exit;
        
      end loop;
      
      -- Wait for a delta delay to make sure signals we assigned are valid (in
      -- particular the name of the test case).
      wait for 0 ns;
      
      if ftype = TF_TEST then
        
        -- Report test case results.
        case testRes is
          
          when TCCR_CONTINUE =>
            testCount := testCount + 1;
            sim_complete <= '1';
            report "Reached end of test case "
                 & rvs2str(sim_currentTest)
                 & ": SUCCESS."
              severity note;
            
          when TCCR_SUCCESS =>
            testCount := testCount + 1;
            sim_complete <= '1';
            report rvs2str(sim_currentTest)
                 & " line " & integer'image(lNr) & ": SUCCESS."
              severity note;
            
          when TCCR_FAIL =>
            testCount := testCount + 1;
            sim_complete <= '1';
            failedTests := failedTests + 1;
            sim_failure <= 'X';
            report rvs2str(sim_currentTest)
                 & " line " & integer'image(lNr) & ": FAILURE."
              severity warning;
            
          when TCCR_ABORT =>
            abortedTests := abortedTests + 1;
            report rvs2str(sim_currentTest)
                 & " line " & integer'image(lNr) & ": ABORT due to "
                 & "aforementioned error in the testbench."
              severity warning;
            
        end case;
        
        -- Generate a few extra clock cycles.
        cycles(20);
        
      end if;
      
      -- Close the file.
      file_close(f);
      
    end handleFile;
    
  --===========================================================================
  begin
  --===========================================================================
    
    -- Set initial values
    reset                   <= '1';
    clkEn                   <= '1';
    rctrl2rv_run            <= (others => '1');
    rctrl2rv_reset          <= (others => '0');
    dbg2rv_addr             <= (others => '0');
    dbg2rv_readEnable       <= '0';
    dbg2rv_writeEnable      <= '0';
    dbg2rv_writeMask        <= (others => '0');
    dbg2rv_writeData        <= (others => '0');
    stim2mem_clearEnable    <= '0';
    stim2mem_writeEnable    <= '0';
    stim2mem_readEnable     <= '0';
    stim2mem_faultEnable    <= '0';
    stim2mem_select         <= '0';
    stim2mem_addr           <= (others => '0');
    stim2mem_writeMask      <= (others => '0');
    stim2mem_writeData      <= (others => '0');
    stim2irq_enable         <= '0';
    stim2irq_ctxt           <= 0;
    stim2irq_id             <= (others => '0');
    sim_currentTest         <= rvs2sim(to_rvs("Initializing..."));
    sim_complete            <= '0';
    sim_failure             <= '0';
    clk                     <= '0';
    
    -- Send a couple clocks to reset.
    wait for 10 ns;
    cycles(2);
    
    -- Clear reset state.
    reset <= '0';
    
    -- Handle the root file.
    handleFile(ROOT_FILE);
    
    -- Show the results.
    wait until rising_edge(sync);
    report "Test suite complete: "
         & integer'image(testCount) & " test(s) run of which "
         & integer'image(failedTests) & " failed; "
         & integer'image(abortedTests) & " test case(s) aborted due to simulation errors."
      severity failure;
    
    wait;
    
  end process;
  
end Behavioral;

