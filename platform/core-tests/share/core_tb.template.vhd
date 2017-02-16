-- r-VEX processor
-- Copyright (C) 2008-2016 by TU Delft.
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

-- Copyright (C) 2008-2016 by TU Delft.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

library std;
use std.textio.all;

library rvex;
use rvex.common_pkg.all;
use rvex.utils_pkg.all;
use rvex.simUtils_pkg.all;
use rvex.simUtils_mem_pkg.all;
use rvex.simUtils_scanner_pkg.all;
use rvex.core_pkg.all;
use rvex.core_asDisas_pkg.all;
use rvex.core_intIface_pkg.all;
use rvex.core_ctrlRegs_pkg.all;

library work;
use work.core_cfg.all;

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
-- *.inc file
-------------------------------------------------------------------------------
-- These files may be included by *.test files, so potentially big chunks of
-- assembly or memory initialization code can be shared.
-- 
-------------------------------------------------------------------------------
-- Valid *.test/*.inc file commands
-------------------------------------------------------------------------------
-- name <name>
--   Sets the name of the test case. This is shown in simulation and in all
--   related simulation report statements. When name is not set, it defaults to
--   the filename.
-- 
-- inc <filename>
--   Includes an *.inc file.
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
--    - faddLanes
--    - fcompareLanes
--    - fconvfiLanes
--    - fconvifLanes
--    - fmultiplyLanes
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
-- loadnops <count>
--   Loads <count> nops, as if "load nop" was run <count> times.
--
-- loadsrec <filename>
--   Loads the given srec file into the instruction memory, offset by the
--   current load pointer. Note that the load pointer will NOT auto-increment.
-- 
-- fillnops <ptr>
--   Same as at, but inserts NOPs from the current loading pointer up to <ptr>.
-- 
-- reset
--   Resets the entire processor. Takes one cycle to complete.
-- 
-- wait <cycles> [
--     write <<group>|*> [<ptr> [exclusive] [<value> [exclusive]]] 
--   | read <<group>|*> [<ptr> [exclusive]]
--   | idle <context>
--   | done <context>
--   | irqHandled <context>
-- ]
--   Waits for <cycles> cycles, unless the specified condition occurs. If no
--   condition is specified, wait always succeeds; otherwise, the cycle count
--   works as a timeout and wait only succeeds if the condition occurs within
--   the set amount of time, after which it will return immediately. The
--   exclusive markers for the memory write and read conditions specifies that
--   a write/read to an address or value other than what is specified should
--   cause the wait to fail.
--   
-- write <dmem|imem|dbg> <word|half|byte> <ptr> <value>
-- read  <dmem|imem|dbg> <word|half|byte> <ptr> <expected>
--   Set memory at <ptr> to <value> or check that the value at that location is
--   <expected>. <ptr> may be specified as a numerical value, or as a CR_*
--   register index (see also rvex_ctrlRegs_pkg).
--   
-- srec  <dmem|imem> <offset> <filename>
--   Loads the specified srec file into the selected memory at the specified
--   offset.
-- 
-- rctrl <ctxt> irq [<id>]
--   Assert irq pin for context <ctxt> with irqID set to <id>, or 0 if not
--   specified. The irq pin is released automatically when irqAck goes high.
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
-- rctrl <ctxt> check <idle|done|irq> <low|high>
--   Ensures that the given context is (not) idle/done, fails otherwise.
-- 
-- (TODO FROM HERE ONWARDS)
-- 
-- fault <set|clear> <imem|dmem> <ptr>
--   Marks the given memory location as faulty or clears the marking. When a
--   fauly memory location is accessed, the fault signal to the rvex will be
--   asserted.
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
entity core_tb is
end core_tb;
-------------------------------------------------------------------------------
architecture Behavioral of core_tb is
--=============================================================================
  
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
  signal stim2mem_srecEnable    : std_logic;
  
  -- Selects between accessing the instruction memory (high) and the data
  -- memory (low). Ignored for clear operations.
  signal stim2mem_select        : std_logic;
  constant IMEM_SELECT          : std_logic := '1';
  constant DMEM_SELECT          : std_logic := '0';
  
  -- Address to operate on. Ignored for clear operations.
  signal stim2mem_addr          : rvex_address_type;
  
  -- Filename for srec file loading.
  shared variable stim2mem_filename : line;
  
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
  uut: entity rvex.core
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
      imem2rv_busFault          => imem2rv_fault,
      
      -- Data memory interface.
      rv2dmem_addr              => rv2dmem_addr,
      rv2dmem_readEnable        => rv2dmem_readEnable,
      rv2dmem_writeData         => rv2dmem_writeData,
      rv2dmem_writeMask         => rv2dmem_writeMask,
      rv2dmem_writeEnable       => rv2dmem_writeEnable,
      dmem2rv_readData          => dmem2rv_readData,
      dmem2rv_busFault          => dmem2rv_fault,
      
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
  mem_block: block is
    
    -- Signals from memory to rvex, before the stall signal is applied: when
    -- stall is high, the signals to the core are overwritten with 'U'.
    signal imem2rv_instr_comb     : rvex_syllable_array(2**CFG.numLanesLog2-1 downto 0);
    signal imem2rv_fault_comb     : std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    signal dmem2rv_readData_comb  : rvex_data_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    signal dmem2rv_fault_comb     : std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
  
  begin
    
    -- Generate some random stall signal. This does not have much to do with
    -- the memory requests, but this does not really matter for testing; the
    -- core should behave sanely regardless of the stalling source.
    mem_stall_proc: process is
      variable seed1, seed2       : positive;
      variable r                  : real;
    begin
      loop
        uniform(seed1, seed2, r);
        if r < MEM_STALL_PROBABILITY then
          mem2rv_stallIn <= (others => '1');
        else
          mem2rv_stallIn <= (others => '0');
        end if;
        wait until rising_edge(clk) and clkEn = '1';
      end loop;
    end process;
    
    -- Connect the outputs from the memory model to the core. When stall is
    -- high, the outputs may not be valid in a real situation (because the
    -- memory might be what's causing the stall), so in that case we override
    -- the outputs with undefined.
    mem_undef_when_stall_proc: process (
      imem2rv_instr_comb, imem2rv_fault_comb,
      dmem2rv_readData_comb, dmem2rv_fault_comb,
      mem2rv_stallIn
    ) is
    begin
      for lane in 0 to 2**CFG.numLanesLog2-1 loop
        if mem2rv_stallIn(lane2group(lane, cfg)) = '0' then
          imem2rv_instr(lane) <= imem2rv_instr_comb(lane);
        else
          imem2rv_instr(lane) <= (others => RVEX_UNDEF);
        end if;
      end loop;
      for laneGroup in 0 to 2**CFG.numLaneGroupsLog2-1 loop
        if mem2rv_stallIn(laneGroup) = '0' then
          imem2rv_fault(laneGroup)    <= imem2rv_fault_comb(laneGroup);
          dmem2rv_readData(laneGroup) <= dmem2rv_readData_comb(laneGroup);
          dmem2rv_fault(laneGroup)    <= dmem2rv_fault_comb(laneGroup);
        else
          imem2rv_fault(laneGroup)    <= RVEX_UNDEF;
          dmem2rv_readData(laneGroup) <= (others => RVEX_UNDEF);
          dmem2rv_fault(laneGroup)    <= RVEX_UNDEF;
        end if;
      end loop;
    end process;
    
    -- Model the memory as a simple single-cycle-access memory.
    mem_model: process (
      
      -- Synchronization with the read/write ports of the rvex instance.
      clk,
      
      -- Synchronization with the test case runner program.
      stim2mem_clearEnable, stim2mem_writeEnable, stim2mem_readEnable,
      stim2mem_faultEnable, stim2mem_srecEnable
      
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
      variable fault              : std_logic;
      variable flags              : rvex_data_type;
      variable result             : rvex_data_type;
      
    begin
      
      -- Handle bus commands from the rvex.
      if rising_edge(clk) then
        if reset = '1' then
          mem2rv_blockReconfig <= (others => '0'); -- TODO, signal is not handled yet.
          imem2rv_instr_comb <= (others => (others => RVEX_UNDEF));
          imem2rv_affinity <= (others => '0');
          imem2rv_fault_comb <= (others => '0');
          dmem2rv_readData_comb <= (others => (others => RVEX_UNDEF));
          dmem2rv_fault_comb <= (others => '0');
        elsif clkEn = '1' then
          
          -- Determine the active bundle program counter and fetch for each
          -- lane group.
          for laneGroup in 2**CFG.numLaneGroupsLog2-1 downto 0 loop
            lanePCs(group2firstLane(laneGroup, CFG)) := rv2imem_PCs(laneGroup);
            fetch(group2firstLane(laneGroup, CFG)) := rv2imem_fetch(laneGroup);
          end loop;
          
          -- Go through the lanes within the lane groups in increasing order
          -- and increment by 4 for each coupled lane.
          for lane in 1 to 2**CFG.numLanesLog2-1 loop
            if lane2group(lane, CFG) = lane2group(lane-1, CFG) then
              lanePCs(lane) := std_logic_vector(vect2unsigned(lanePCs(lane-1)) + 4);
              fetch(lane) := fetch(lane-1);
            end if;
          end loop;
          
          -- Handle instruction memory access for each lane.
          fault := '0';
          for lane in 0 to 2**CFG.numLanesLog2-1 loop
            
            -- If fetch is high and the group is not stalled, return the
            -- syllable at the decoded PC and load the fault signal from the
            -- flag memory.
            if (fetch(lane) = '1') and (rv2mem_stallOut(lane2group(lane, CFG)) = '0') then
              rvmem_read(imem, lanePCs(lane), result);
              imem2rv_instr_comb(lane) <= result;
              rvmem_read(fmem, lanePCs(lane), result);
              fault := fault or result(FLAG_IM_FAULT_BIT);
            end if;
            
            -- Forward fault signal if this is the last lane in a coupled
            -- group.
            if lane = lane2lastLane(lane, CFG) then
              if rv2mem_decouple(lane2group(lane, CFG)) = '1' then
                imem2rv_fault_comb(lane2group(lane, CFG)) <= fault;
                fault := '0';
              else
                imem2rv_fault_comb(lane2group(lane, CFG)) <= '0';
              end if;
            end if;
            
          end loop;
          
          -- Handle data memory access for each lane group.
          for laneGroup in 0 to 2**CFG.numLaneGroupsLog2-1 loop
            
            -- Only handle commands when the group is not stalled.
            if rv2mem_stallOut(laneGroup) = '0' then
              if rv2dmem_writeEnable(laneGroup) = '1' then
                
                -- Handle writes. Only perform the write if we do not return a
                -- fault.
                rvmem_read(fmem, rv2dmem_addr(laneGroup), result);
                fault := result(FLAG_DM_FAULT_BIT);
                if fault = '0' then
                  rvmem_write(
                    mem   => dmem,
                    addr  => rv2dmem_addr(laneGroup),
                    value => rv2dmem_writeData(laneGroup),
                    mask  => rv2dmem_writeMask(laneGroup)
                  );
                end if;
                dmem2rv_fault_comb(laneGroup) <= fault;
                
              elsif rv2dmem_readEnable(laneGroup) = '1' then
                
                -- Handle reads.
                rvmem_read(fmem, rv2dmem_addr(laneGroup), result);
                dmem2rv_fault_comb(laneGroup)    <= result(FLAG_DM_FAULT_BIT);
                rvmem_read(dmem, rv2dmem_addr(laneGroup), result);
                dmem2rv_readData_comb(laneGroup) <= result;
                
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
          rvmem_read(
            mem   => imem, -- Instruction memory.
            addr  => stim2mem_addr,
            value => result
          );
        else
          rvmem_read(
            mem   => dmem, -- Data memory.
            addr  => stim2mem_addr,
            value => result
          );
        end if;
        mem2stim_readData <= result;
        
      elsif rising_edge(stim2mem_faultEnable) then
        
        -- Read the current value of the flags.
        rvmem_read(
          mem   => fmem,
          addr  => stim2mem_addr,
          value => flags
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
        
      elsif rising_edge(stim2mem_srecEnable) then
        
        -- Handle s-record file loads.
        if stim2mem_filename /= null then
          if stim2mem_select = IMEM_SELECT then
            rvmem_loadSRec(
              mem     => imem,
              fname   => stim2mem_filename.all,
              offset  => stim2mem_addr
            );
          else
            rvmem_loadSRec(
              mem     => dmem,
              fname   => stim2mem_filename.all,
              offset  => stim2mem_addr
            );
          end if;
        end if;
        
      end if;
      
    end process;
    
  end block;
  
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
    
    -- List of integer constants for immediates in the assembly code.
    variable intConstsCore: scan_intConsts_type;
    
    -- List of integer constants for immediates in debug bus addresses.
    variable intConstsDbg : scan_intConsts_type;
    
    -- Forward declaration for handleFile, which is called recursively.
    procedure handleFile(
      fnameIn : in    string;
      testRes : inout testCommandResult_type
    );
    
    -- Shorthand for handleFile, when the results of the last tests are not
    -- needed.
    procedure handleFile(
      fnameIn : in  string
    ) is
      variable dummy  : testCommandResult_type;
    begin
      handleFile(fnameIn, dummy);
    end handleFile;
    
    ---------------------------------------------------------------------------
    -- Generates a number of clock cycles
    ---------------------------------------------------------------------------
    procedure cycles(
      count     : in natural;
      clkEnProb : in real := 0.5
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
        wait for 4990 ps;
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        wait for 10 ps;
        
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
        actVal := to_signed(2**CFG.numLanesLog2, 33);
      elsif matchStr(token.all, "numLaneGroups") then
        actVal := to_signed(2**CFG.numLaneGroupsLog2, 33);
      elsif matchStr(token.all, "numContexts") then
        actVal := to_signed(2**CFG.numContextsLog2, 33);
      elsif matchStr(token.all, "genBundleSize") then
        actVal := to_signed(2**CFG.genBundleSizeLog2, 33);
      elsif matchStr(token.all, "bundleAlign") then
        actVal := to_signed(2**CFG.bundleAlignLog2, 33);
      elsif matchStr(token.all, "multiplierLanes") then
        actVal := to_signed(CFG.multiplierLanes, 33);
      elsif matchStr(token.all, "memLaneRevIndex") then
        actVal := to_signed(CFG.memLaneRevIndex, 33);
      elsif matchStr(token.all, "branchLaneRevIndex") then
        actVal := to_signed(0, 33);
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
        consts    => intConstsCore,
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
      wait for 1 ps; -- Prevent iteration limit problems.
      
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
    -- Executes a 'loadsrec' command
    ---------------------------------------------------------------------------
    -- loadsrec <filename>
    procedure executeLoadSrec(
      l       : in    string;
      pos     : inout positive;
      path    : in    string;
      result  : out   testCommandResult_type
    ) is
    begin
      
      -- Determine the filename.
      if stim2mem_filename /= null then
        deallocate(stim2mem_filename);
        stim2mem_filename := null;
      end if;
      stim2mem_filename := new string(1 to l'length + path'length + 1 - pos);
      stim2mem_filename.all := path & l(pos to l'length);
      
      -- Command the memory process to load the selected file.
      stim2mem_srecEnable <= '1';
      stim2mem_select <= IMEM_SELECT;
      stim2mem_addr <= loadPtr;
      wait for 0 ns;
      stim2mem_srecEnable <= '0';
      wait for 0 ns;
      
      -- Clean up.
      deallocate(stim2mem_filename);
      stim2mem_filename := null;
      
      -- Everything is OK.
      result := TCCR_CONTINUE;
      
    end executeLoadSrec;
    
    ---------------------------------------------------------------------------
    -- Executes a 'loadnops' command
    ---------------------------------------------------------------------------
    -- loadnops <count>
    procedure executeLoadNops(
      l       : in    string;
      pos     : inout positive;
      result  : out   testCommandResult_type
    ) is
      variable syllable : rvex_syllable_type;
      variable error    : rvex_string_builder_type;
      variable count    : signed(32 downto 0);
      variable ok       : boolean;
    begin
      
      -- Scan the count.
      scanNumeric(l, pos, count, ok);
      if not ok then
        report "Error parsing test case 'loadnops' command: '" & l & "'. "
             & "Aborting."
          severity warning;
        result := TCCR_ABORT;
        return;
      end if;
      
      -- Assemble a NOP instruction.
      assembleLine(
        source    => "nop",
        line      => curLineNr,
        consts    => intConstsCore,
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
      while count > 0 loop
        
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
        
        -- Decrement the counter.
        count := count - 1;
        
      end loop;
      
      -- Everything is OK.
      result := TCCR_CONTINUE;
      
    end executeLoadNops;
    
    ---------------------------------------------------------------------------
    -- Executes a 'fillnops' command
    ---------------------------------------------------------------------------
    -- fillnops <ptr>
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
        consts    => intConstsCore,
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
    -- Executes a 'wait' command
    ---------------------------------------------------------------------------
    -- wait <cycles> [
    --     write <<group>|*> [<ptr> [exclusive] [<value> [exclusive]]] 
    --   | read <<group>|*> [<ptr> [exclusive]]
    --   | idle <context>
    --   | done <context>
    --   | irqHandled <context>
    -- ]
    procedure executeWait(
      l       : in    string;
      pos     : inout positive;
      result  : out   testCommandResult_type
    ) is
      variable token      : line;
      variable val        : signed(32 downto 0);
      variable ok         : boolean;
      variable pos2       : positive;
      
      -- Type of wait instruction.
      type waitType_type is (
        WAIT_NORMAL, WAIT_WRITE, WAIT_READ, WAIT_IDLE, WAIT_DONE, WAIT_IRQ
      );
      variable waitType   : waitType_type;
      
      -- Wait parameters.
      variable ctxtGrp    : natural;
      variable ctxtGrpMax : natural;
      variable addr       : rvex_address_type;
      variable addrEx     : boolean;
      variable value      : rvex_data_type;
      variable valueEx    : boolean;
      
      -- Number of cycles remaining.
      variable cycleCnt   : integer;
      
    begin
      
      -- Scan the number of cycles.
      scanNumeric(l, pos, val, ok);
      if not ok then
        report "Error parsing test case 'wait' command: '" & l & "'. "
             & "Aborting."
          severity warning;
        result := TCCR_ABORT;
        return;
      end if;
      cycleCnt := to_integer(val);
      
      -- Parse the "write" or "read" tokens if they exist.
      if pos > l'length then
        waitType := WAIT_NORMAL;
        ok := true;
      else
        scanToken(l, pos, token);
        if token = null then
          ok := false;
        elsif matchStr(token.all, "write") then
          waitType := WAIT_WRITE;
          ok := true;
        elsif matchStr(token.all, "read") then
          waitType := WAIT_READ;
          ok := true;
        elsif matchStr(token.all, "idle") then
          waitType := WAIT_IDLE;
          ok := true;
        elsif matchStr(token.all, "done") then
          waitType := WAIT_DONE;
          ok := true;
        elsif matchStr(token.all, "irqHandled") then
          waitType := WAIT_IRQ;
          ok := true;
        else
          ok := false;
        end if;
      end if;
      if not ok then
        report "Error parsing test case 'wait' command: '" & l & "'. "
             & "Aborting."
          severity warning;
        result := TCCR_ABORT;
        return;
      end if;
      
      -- Parse the context/group index for 'wait' commands with parameters.
      if waitType /= WAIT_NORMAL then
        if (waitType = WAIT_WRITE or waitType = WAIT_READ) and pos <= l'length and l(pos) = '*' then
          pos := pos + 1;
          scanToEndOfWhitespace(l, pos);
          ctxtGrp := 0;
          ctxtGrpMax := 2**CFG.numLaneGroupsLog2-1;
        else
          scanNumeric(l, pos, val, ok);
          if not ok then
            report "Error parsing test case 'wait' command: '" & l & "'. "
                 & "Context/group specified expected. Aborting."
              severity warning;
            result := TCCR_ABORT;
            return;
          end if;
          ctxtGrp := to_integer(val);
          ctxtGrpMax := ctxtGrp;
        end if;
      end if;
      
      -- Make sure ctxtGrp is within range.
      if waitType = WAIT_WRITE or waitType = WAIT_READ then
        if ctxtGrp >= 2**CFG.numLaneGroupsLog2 then
          report "Error parsing test case 'wait' command: '" & l & "'. "
               & "Lane group " & integer'image(ctxtGrp) & " is out of range. "
               & "Aborting."
            severity warning;
          result := TCCR_ABORT;
          return;
        end if;
      elsif waitType = WAIT_IDLE or waitType = WAIT_DONE or waitType = WAIT_IRQ then
        if ctxtGrp >= 2**CFG.numContextsLog2 then
          report "Error parsing test case 'wait' command: '" & l & "'. "
               & "Context " & integer'image(ctxtGrp) & " is out of range. "
               & "Aborting."
            severity warning;
          result := TCCR_ABORT;
          return;
        end if;
      end if;
      
      -- Default to not caring about address or data.
      addr := (others => '-');
      value := (others => '-');
      addrEx := false;
      valueEx := false;
      
      -- Parse the optional pointer and exclusive marker for "write" or "read"
      -- waits.
      if waitType = WAIT_WRITE or waitType = WAIT_READ then
        
        -- Scan the address.
        if pos <= l'length then
          scanNumeric(l, pos, val, ok);
          if not ok then
            report "Error parsing test case 'wait' command: '" & l & "'. "
                 & "Aborting."
              severity warning;
            result := TCCR_ABORT;
            return;
          end if;
          addr := std_logic_vector(val(31 downto 0));
        end if;
        
        -- Scan optional exclusive marker.
        if pos <= l'length then
          pos2 := pos;
          scanToken(l, pos2, token);
          if token = null then
            report "Error parsing test case 'wait' command: '" & l & "'. "
                 & "Aborting."
              severity warning;
            result := TCCR_ABORT;
            return;
          end if;
          if matchStr(token.all, "exclusive") then
            addrEx := true;
            pos := pos2;
          end if;
        end if;
        
      end if;
      
      -- Parse the optional expected write value for "write" waits.
      if waitType = WAIT_WRITE then
        
        -- Scan the value.
        if pos <= l'length then
          scanNumeric(l, pos, val, ok);
          if not ok then
            report "Error parsing test case 'wait' command: '" & l & "'. "
                 & "Aborting."
              severity warning;
            result := TCCR_ABORT;
            return;
          end if;
          value := std_logic_vector(val(31 downto 0));
        end if;
        
        -- Scan optional exclusive marker.
        if pos <= l'length then
          pos2 := pos;
          scanToken(l, pos2, token);
          if token = null then
            report "Error parsing test case 'wait' command: '" & l & "'. "
                 & "Aborting."
              severity warning;
            result := TCCR_ABORT;
            return;
          end if;
          if matchStr(token.all, "exclusive") then
            valueEx := true;
            pos := pos2;
          end if;
        end if;
        
      end if;
      
      -- We should be at the end of the line now.
      if pos <= l'length then
        report "Error parsing test case 'wait' command: '" & l & "'. "
             & "Garbage at end of line. Aborting."
          severity warning;
        result := TCCR_ABORT;
        return;
      end if;
      
      -- Actually handle the command.
      while cycleCnt > 0 loop
        
        -- Make a cycle pass.
        cycles(1);
        
        -- Test for conditions, if specified.
        if waitType = WAIT_WRITE then
          for laneGroup in ctxtGrp to ctxtGrpMax loop
            if rv2mem_stallOut(laneGroup) = '0'
              and rv2dmem_writeEnable(laneGroup) = '1'
              and rv2dmem_writeMask(laneGroup) = "1111"
            then
              if std_match(rv2dmem_addr(laneGroup), addr) then
                if std_match(rv2dmem_writeData(laneGroup), value) then
                  
                  -- Expected write encountered.
                  result := TCCR_CONTINUE;
                  return;
                  
                elsif valueEx then
                  
                  -- Incorrect value written in exclusive mode, fail.
                  report "Expected processor to write " & rvs_hex(value)
                       & " to " & rvs_hex(addr) & ", but it wrote "
                       & rvs_hex(rv2dmem_writeData(laneGroup)) & "."
                    severity warning;
                  result := TCCR_FAIL;
                  return;
                  
                end if;
              elsif addrEx or valueEx then
                
                -- Incorrect address written in exclusive mode, fail.
                report "Expected processor to write to " & rvs_hex(addr)
                     & " but it wrote to " & rvs_hex(rv2dmem_addr(laneGroup))
                     & "."
                  severity warning;
                result := TCCR_FAIL;
                return;
                
              end if;
            end if;
          end loop;
        elsif waitType = WAIT_READ then
          for laneGroup in ctxtGrp to ctxtGrpMax loop
            if rv2mem_stallOut(laneGroup) = '0'
              and rv2dmem_readEnable(laneGroup) = '1'
            then
              if std_match(rv2dmem_addr(laneGroup), addr) then
                  
                -- Expected read encountered.
                result := TCCR_CONTINUE;
                return;
                  
              elsif addrEx or valueEx then
                
                -- Incorrect address read in exclusive mode, fail.
                report "Expected processor to read from " & rvs_hex(addr)
                     & " but it read from " & rvs_hex(rv2dmem_addr(laneGroup))
                     & "."
                  severity warning;
                result := TCCR_FAIL;
                return;
                
              end if;
            end if;
          end loop;
        elsif waitType = WAIT_IDLE then
          if rv2rctrl_idle(ctxtGrp) = '1' then
            result := TCCR_CONTINUE;
            return;
          end if;
        elsif waitType = WAIT_DONE then
          if rv2rctrl_done(ctxtGrp) = '1' then
            result := TCCR_CONTINUE;
            return;
          end if;
        elsif waitType = WAIT_IRQ then
          if rctrl2rv_irq(ctxtGrp) = '0' then
            result := TCCR_CONTINUE;
            return;
          end if;
        end if;
        
        -- Decrement counter.
        cycleCnt := cycleCnt - 1;
        
      end loop;
      
      if waitType = WAIT_NORMAL then
        
        -- Normal wait, everything is OK.
        result := TCCR_CONTINUE;
        
      else
        
        -- Timeout.
        report "Timeout occured while waiting for '" & l & "'."
          severity warning;
        result := TCCR_FAIL;
        
      end if;
      
    end executeWait;
    
    ---------------------------------------------------------------------------
    -- Executes a read/write command
    ---------------------------------------------------------------------------
    -- write <dmem|imem|dbg> <word|half|byte> <ptr> <value>
    -- read  <dmem|imem|dbg> <word|half|byte> <ptr> <expected>
    procedure executeReadWrite(
      l       : in    string;
      pos     : inout positive;
      isRead  : in    boolean;
      result  : out   testCommandResult_type
    ) is
      variable token      : line;
      variable val        : signed(32 downto 0);
      variable ok         : boolean;
      variable pos2       : positive;
      
      -- Memory to access.
      type memoryType_type is (MEM_DMEM, MEM_IMEM, MEM_DBG);
      variable memType    : memoryType_type;
      
      -- Size of the access.
      type accessSize_type is (MEM_WORD, MEM_HALF, MEM_BYTE);
      variable accessSize : accessSize_type;
      
      -- Address and data.
      variable addr       : rvex_address_type;
      variable mask       : rvex_mask_type;
      variable value      : rvex_data_type;
      variable writeValue : rvex_data_type;
      variable readVal    : rvex_data_type;
      
    begin
      
      -- Parse the memory selection token.
      scanToken(l, pos, token);
      if token = null then
        report "Error parsing test case 'read' or 'write' command: '" & l
             & "'. Aborting."
          severity warning;
        result := TCCR_ABORT;
        return;
      elsif matchStr(token.all, "dmem") then memType := MEM_DMEM;
      elsif matchStr(token.all, "imem") then memType := MEM_IMEM;
      elsif matchStr(token.all, "dbg" ) then memType := MEM_DBG;
      else
        report "Error parsing test case 'read' or 'write' command: '" & l
             & "'. Aborting."
          severity warning;
        result := TCCR_ABORT;
        return;
      end if;
      
      -- Parse the access size token.
      scanToken(l, pos, token);
      if token = null then
        report "Error parsing test case 'read' or 'write' command: '" & l
             & "'. Aborting."
          severity warning;
        result := TCCR_ABORT;
        return;
      elsif matchStr(token.all, "word") then accessSize := MEM_WORD;
      elsif matchStr(token.all, "half") then accessSize := MEM_HALF;
      elsif matchStr(token.all, "byte") then accessSize := MEM_BYTE;
      else
        report "Error parsing test case 'read' or 'write' command: '" & l
             & "'. Aborting."
          severity warning;
        result := TCCR_ABORT;
        return;
      end if;
      
      -- Parse the pointer.
      scanNumeric(l, pos, intConstsDbg, val, ok);
      if not ok then
        report "Error parsing test case 'read' or 'write' command: '" & l
             & "'. Aborting."
          severity warning;
        result := TCCR_ABORT;
        return;
      end if;
      addr := std_logic_vector(val(31 downto 0));
      
      -- Parse the expected value/value to write.
      scanNumeric(l, pos, intConstsDbg, val, ok);
      if not ok then
        report "Error parsing test case 'read' or 'write' command: '" & l
             & "'. Aborting."
          severity warning;
        result := TCCR_ABORT;
        return;
      end if;
      value := std_logic_vector(val(31 downto 0));
      
      -- We should be at the end of the line now.
      if pos <= l'length then
        report "Error parsing test case 'read' or 'write' command: '" & l
             & "'. Garbage at end of line. Aborting."
          severity warning;
        result := TCCR_ABORT;
        return;
      end if;
      
      -- Decode given address and access size into word address and mask.
      if accessSize = MEM_WORD then
        writeValue := value;
        mask := "1111";
      elsif accessSize = MEM_HALF then
        writeValue := value(15 downto 0) & value(15 downto 0);
        if addr(1) = '0' then
          mask := "1100";
        else
          mask := "0011";
        end if;
      else
        writeValue := value(7 downto 0) & value(7 downto 0)
                    & value(7 downto 0) & value(7 downto 0);
        if addr(1 downto 0) = "00" then
          mask := "1000";
        elsif addr(1 downto 0) = "01" then
          mask := "0100";
        elsif addr(1 downto 0) = "10" then
          mask := "0010";
        else
          mask := "0001";
        end if;
      end if;
      
      -- Actually handle the command.
      if memType = MEM_DMEM or memType = MEM_IMEM then
        stim2mem_addr <= addr(31 downto 2) & "00";
        if memType = MEM_DMEM then
          stim2mem_select <= DMEM_SELECT;
        else
          stim2mem_select <= IMEM_SELECT;
        end if;
        if isRead then
          stim2mem_readEnable <= '1';
          stim2mem_writeEnable <= '0';
          stim2mem_writeMask <= (others => '0');
          stim2mem_writeData <= (others => '0');
        else
          stim2mem_readEnable <= '0';
          stim2mem_writeEnable <= '1';
          stim2mem_writeMask <= mask;
          stim2mem_writeData <= writeValue;
        end if;
        wait for 0 ns;
        stim2mem_readEnable <= '0';
        stim2mem_writeEnable <= '0';
        stim2mem_writeMask <= (others => '0');
        stim2mem_writeData <= (others => '0');
        wait for 0 ns;
        readVal := mem2stim_readData;
      else
        dbg2rv_addr <= addr(31 downto 2) & "00";
        if isRead then
          dbg2rv_readEnable <= '1';
          dbg2rv_writeEnable <= '0';
          dbg2rv_writeMask <= (others => '0');
          dbg2rv_writeData <= (others => '0');
        else
          dbg2rv_readEnable <= '0';
          dbg2rv_writeEnable <= '1';
          dbg2rv_writeMask <= mask;
          dbg2rv_writeData <= writeValue;
        end if;
        cycles(1);
        dbg2rv_readEnable <= '0';
        dbg2rv_writeEnable <= '0';
        dbg2rv_writeMask <= (others => '0');
        dbg2rv_writeData <= (others => '0');
        readVal := rv2dbg_readData;
      end if;
      
      -- Test the read result, respecting non-word accesses.
      if isRead then
        if accessSize = MEM_HALF then
          if addr(1) = '0' then
            readVal := X"0000" & readVal(31 downto 16);
          else
            readVal := X"0000" & readVal(15 downto 0);
          end if;
        elsif accessSize = MEM_BYTE then
          if addr(1 downto 0) = "00" then
            readVal := X"000000" & readVal(31 downto 24);
          elsif addr(1 downto 0) = "01" then
            readVal := X"000000" & readVal(23 downto 16);
          elsif addr(1 downto 0) = "10" then
            readVal := X"000000" & readVal(15 downto 8);
          else
            readVal := X"000000" & readVal(7 downto 0);
          end if;
        end if;
        if readVal /= value then
          report "Did not read the expected value for 'read' command '" & l
               & "'; actual value was " & rvs_hex(readVal, 8) & "."
            severity warning;
          result := TCCR_FAIL;
          return;
        end if;
      end if;
      
      -- Command handled.
      result := TCCR_CONTINUE;
      
    end executeReadWrite;
    
    ---------------------------------------------------------------------------
    -- Executes an 'srec' command
    ---------------------------------------------------------------------------
    -- srec <imem|dmem> <offset> <filename>
    procedure executeSrec(
      l       : in    string;
      pos     : inout positive;
      path    : in    string;
      result  : out   testCommandResult_type
    ) is
      variable token      : line;
      variable val        : signed(32 downto 0);
      variable ok         : boolean;
      variable pos2       : positive;
      
      -- Memory to access.
      type memoryType_type is (MEM_DMEM, MEM_IMEM);
      variable memType    : memoryType_type;
      
      -- Offset for srec addresses.
      variable offset     : rvex_address_type;
      
    begin
      
      -- Parse the memory selection token.
      scanToken(l, pos, token);
      if token = null then
        report "Error parsing test case 'srec' command: '" & l
             & "'. Expecting dmem or imem. Aborting."
          severity warning;
        result := TCCR_ABORT;
        return;
      elsif matchStr(token.all, "dmem") then memType := MEM_DMEM;
      elsif matchStr(token.all, "imem") then memType := MEM_IMEM;
      else
        report "Error parsing test case 'srec' command: '" & l
             & "'. Expecting dmem or imem. Aborting."
          severity warning;
        result := TCCR_ABORT;
        return;
      end if;
      
      -- Parse the offset.
      scanNumeric(l, pos, val, ok);
      if not ok then
        report "Error parsing test case 'srec' command: '" & l
             & "'. Expecting offset. Aborting."
          severity warning;
        result := TCCR_ABORT;
        return;
      end if;
      offset := std_logic_vector(val(31 downto 0));
      
      -- Determine the filename.
      if stim2mem_filename /= null then
        deallocate(stim2mem_filename);
        stim2mem_filename := null;
      end if;
      stim2mem_filename := new string(1 to l'length + path'length + 1 - pos);
      stim2mem_filename.all := path & l(pos to l'length);
      
      -- Command the memory process to load the selected file.
      stim2mem_srecEnable <= '1';
      if memType = MEM_DMEM then
        stim2mem_select <= DMEM_SELECT;
      else
        stim2mem_select <= IMEM_SELECT;
      end if;
      stim2mem_addr <= offset;
      wait for 0 ns;
      stim2mem_srecEnable <= '0';
      wait for 0 ns;
      
      -- Clean up.
      deallocate(stim2mem_filename);
      stim2mem_filename := null;
      
      -- Everything is OK.
      result := TCCR_CONTINUE;
      
    end executeSrec;
    
    ---------------------------------------------------------------------------
    -- Executes an 'rctrl' command
    ---------------------------------------------------------------------------
    -- rctrl <ctxt> irq [<id>]
    -- rctrl <ctxt> reset
    -- rctrl <ctxt> halt
    -- rctrl <ctxt> run
    -- rctrl <ctxt> check <idle|done|irq> <low|high>
    procedure executeRctrl(
      l       : in    string;
      pos     : inout positive;
      result  : out   testCommandResult_type
    ) is
      variable token      : line;
      variable val        : signed(32 downto 0);
      variable ok         : boolean;
      
      -- Context to access.
      variable ctxt       : natural;
      
      -- Type of run control command.
      type rctrlType_type is (
        RC_IRQ, RC_RESET, RC_HALT, RC_RUN,
        RC_CHECK_IDLE, RC_CHECK_DONE, RC_CHECK_IRQ
      );
      variable rctrlType   : rctrlType_type;
      
      -- Parameter. This is the interrupt ID for RC_IRQ and 0 or 1 for the
      -- check commands.
      variable param      : signed(32 downto 0);
      
    begin
      
      -- Parse the context to access.
      scanNumeric(l, pos, val, ok);
      if not ok then
        report "Error parsing test case 'rctrl' command: '" & l
             & "'. Context ID expected. Aborting."
          severity warning;
        result := TCCR_ABORT;
        return;
      end if;
      if val < 0 or val >= 2**CFG.numContextsLog2 then
        report "Error parsing test case 'rctrl' command: '" & l
             & "'. Context ID is out of range. Aborting."
          severity warning;
        result := TCCR_ABORT;
        return;
      end if;
      ctxt := to_integer(val);
      
      -- Parse the command type token.
      scanToken(l, pos, token);
      if token = null then
        report "Error parsing test case 'rctrl' command: '" & l
             & "'. Command type expected. Aborting."
          severity warning;
        result := TCCR_ABORT;
        return;
      elsif matchStr(token.all, "irq") then
        rctrlType := RC_IRQ;
        
        -- Scan the interrupt ID.
        scanNumeric(l, pos, val, ok);
        if ok then
          param := val;
        else
          param := (others => '0');
        end if;
        
      elsif matchStr(token.all, "reset") then rctrlType := RC_RESET;
      elsif matchStr(token.all, "halt" ) then rctrlType := RC_HALT;
      elsif matchStr(token.all, "run" ) then rctrlType := RC_RUN;
      elsif matchStr(token.all, "check" ) then
        
        -- Scan signal name.
        scanToken(l, pos, token);
        if token = null then
          report "Error parsing test case 'rctrl' command: '" & l
               & "'. Signal name expected. Aborting."
            severity warning;
          result := TCCR_ABORT;
          return;
        elsif matchStr(token.all, "idle") then rctrlType := RC_CHECK_IDLE;
        elsif matchStr(token.all, "done") then rctrlType := RC_CHECK_DONE;
        elsif matchStr(token.all, "irq" ) then rctrlType := RC_CHECK_IRQ;
        else
          report "Error parsing test case 'rctrl' command: '" & l
               & "'. Unknown signal name '" & token.all & "'. Aborting."
            severity warning;
          result := TCCR_ABORT;
          return;
        end if;
        
        -- Scan expected signal state.
        scanToken(l, pos, token);
        if token = null then
          report "Error parsing test case 'rctrl' command: '" & l
               & "'. Expected low or high. Aborting."
            severity warning;
          result := TCCR_ABORT;
          return;
        elsif matchStr(token.all, "low") then param := (others => '0');
        elsif matchStr(token.all, "high") then param := (0 => '1', others => '0');
        else
          report "Error parsing test case 'rctrl' command: '" & l
               & "'. Expected low or high. Aborting."
            severity warning;
          result := TCCR_ABORT;
          return;
        end if;
        
      else
        report "Error parsing test case 'rctrl' command: '" & l
             & "'. Unknown command type. Aborting."
          severity warning;
        result := TCCR_ABORT;
        return;
      end if;
      
      -- We should be at the end of the line now.
      if pos <= l'length then
        report "Error parsing test case 'rctrl' command: '" & l
             & "'. Garbage at end of line. Aborting."
          severity warning;
        result := TCCR_ABORT;
        return;
      end if;
      
      -- Actually handle the command.
      case rctrlType is
        
        when RC_IRQ =>
          
          -- Give the interrupt command to the controller process.
          stim2irq_enable <= '1';
          stim2irq_ctxt   <= ctxt;
          stim2irq_id     <= std_logic_vector(param(31 downto 0));
          wait for 0 ns;
          stim2irq_enable <= '0';
          wait for 0 ns;
          
        when RC_RESET =>
          
          -- Give the context reset command.
          rctrl2rv_reset(ctxt) <= '1';
          cycles(1);
          rctrl2rv_reset(ctxt) <= '0';
          
        when RC_HALT =>
          
          -- Stop a context.
          rctrl2rv_run(ctxt) <= '0';
          
        when RC_RUN =>
          
          -- Resume a context.
          rctrl2rv_run(ctxt) <= '1';
          
        when RC_CHECK_IDLE =>
          
          -- Check idle output.
          if rv2rctrl_idle(ctxt) /= std_logic(param(0)) then
            report "Processor is not in expected state for 'rctrl' command '"
                 & l & "'; actual value was "
                 & rvs_bin_no0b("" & rv2rctrl_idle(ctxt), 1) & "."
              severity warning;
            result := TCCR_FAIL;
            return;
          end if;
          
        when RC_CHECK_DONE =>
          
          -- Check done output.
          if rv2rctrl_done(ctxt) /= std_logic(param(0)) then
            report "Processor is not in expected state for 'rctrl' command '"
                 & l & "'; actual value was "
                 & rvs_bin_no0b("" & rv2rctrl_done(ctxt), 1) & "."
              severity warning;
            result := TCCR_FAIL;
            return;
          end if;
          
        when RC_CHECK_IRQ =>
          
          -- Check IRQ signal.
          if rctrl2rv_irq(ctxt) /= std_logic(param(0)) then
            report "Processor is not in expected state for 'rctrl' command '"
                 & l & "'; actual value was "
                 & rvs_bin_no0b("" & rctrl2rv_irq(ctxt), 1) & "."
              severity warning;
            result := TCCR_FAIL;
            return;
          end if;
          
      end case;
      
      -- Command handled.
      result := TCCR_CONTINUE;
      
    end executeRctrl;
    
    ---------------------------------------------------------------------------
    -- Executes a line in a test case file
    ---------------------------------------------------------------------------
    procedure executeLine(
      l       : in  string;
      path    : in  string;
      result  : out testCommandResult_type
    ) is
      variable pos    : positive;
      variable token  : line;
      variable res    : testCommandResult_type;
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
      elsif matchStr(token.all, "loadnops") then
        executeLoadNops(l, pos, result);
      elsif matchStr(token.all, "loadsrec") then
        executeLoadSrec(l, pos, path, result);
      elsif matchStr(token.all, "fillnops") then
        executeFillNops(l, pos, result);
      elsif matchStr(token.all, "reset") then
        if pos <= l'length then
          report "Garbage at end of line in test case file. Aborting."
            severity warning;
          result := TCCR_ABORT;
        end if;
        reset <= '1';
        cycles(1);
        reset <= '0';
      elsif matchStr(token.all, "wait") then
        executeWait(l, pos, result);
      elsif matchStr(token.all, "read") then
        executeReadWrite(l, pos, true, result);
      elsif matchStr(token.all, "write") then
        executeReadWrite(l, pos, false, result);
      elsif matchStr(token.all, "srec") then
        executeSrec(l, pos, path, result);
      elsif matchStr(token.all, "rctrl") then
        executeRctrl(l, pos, result);
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
      elsif matchStr(token.all, "inc") then
        handleFile(path & l(pos to l'length), res);
        result := res;
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
      fnameIn : in    string;
      testRes : inout testCommandResult_type
    ) is
      
      -- Input filename, normalized so character 1 is actually at position 1.
      variable fname  : string(1 to fnameIn'length);
      
      -- File handle for the input file.
      file     f      : text;
      
      -- File opening result.
      variable status : file_open_status;
      
      -- This is set to the path of the input file name, up to and including
      -- the last (back)slash.
      variable path   : rvex_string_builder_type;
      
      -- File type specification. Determined based on the filename.
      type testFileType_type is (TF_SUITE, TF_TEST, TF_TEST_INC);
      variable ftype  : testFileType_type;
      
      -- Line manipulation variables.
      variable l, l2  : line;
      variable lstart : natural;
      variable lend   : natural;
      
      -- Current line number.
      variable lNr    : natural;
      
    begin
      fname := fnameIn;
      
      -- Determine the file type.
      for i in fname'length downto 1 loop
        if fname(i) = '.' then
          if fname(i to fname'length) = ".suite" then
            ftype := TF_SUITE;
          elsif fname(i to fname'length) = ".test" then
            ftype := TF_TEST;
          elsif fname(i to fname'length) = ".inc" then
            ftype := TF_TEST_INC;
          else
            report "Unknown file extension for " & fname & ". Should be .suite, "
                 & ".test or .inc. Skipping file."
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
      
      -- Report that we've loaded a file. Don't report include files because
      -- spam.
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
        lstart := 1;
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
        if ftype = TF_TEST or ftype = TF_TEST_INC then
          executeLine(
            l       => l.all,
            path    => rvs2str(path),
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
    
    ---------------------------------------------------------------------------
    -- Registers a control register with the integer constant registry
    ---------------------------------------------------------------------------
    procedure registerCtrlReg(
      name    : string;
      byteIdx : natural
    ) is
    begin
      
      -- Register the address of the control register as seen from the core.
      registerConstant(
        consts  => intConstsCore,
        str     => name,
        val     => 
          resize(signed(CFG.cregStartAddress), 33)
          + to_signed(byteIdx, 33)
      );
      
      -- Register the address of the control register as seen from the debug
      -- bus.
      registerConstant(
        consts  => intConstsDbg,
        str     => name,
        val     => to_signed(byteIdx, 33)
      );
      
    end registerCtrlReg;
    
    ---------------------------------------------------------------------------
    -- Registers a control register value with the integer constant registry
    ---------------------------------------------------------------------------
    procedure registerCtrlRegVal(
      name    : string;
      val     : natural
    ) is
    begin
      
      -- Register the address of the control register as seen from the core.
      registerConstant(
        consts  => intConstsCore,
        str     => name,
        val     => to_signed(val, 33)
      );
      
      -- Register the address of the control register as seen from the debug
      -- bus.
      registerConstant(
        consts  => intConstsDbg,
        str     => name,
        val     => to_signed(val, 33)
      );
      
    end registerCtrlRegVal;
    
  --===========================================================================
  begin
  --===========================================================================
    
    -- Set initial values.
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
    stim2mem_srecEnable     <= '0';
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
    
    -- Synchronize such that the rising edges occur aligned to 10 ns
    -- boundaries, and send a couple clocks to reset.
    wait for 10 ns;
    wait for 10 ps;
    cycles(2);
    
    -- Clear reset state.
    reset <= '0';
    
    -- Register control register addresses. This section is generated from the
    -- config directory in the root of the repository.
    @REGISTER_DEFINITIONS
    
    -- Enable/disable interrupts.
    registerCtrlRegVal("CR_CCR_IEN",          CR_CCR_I_L);
    registerCtrlRegVal("CR_CCR_IEN_C",        CR_CCR_I_H);
    
    -- Enable/disable ready-for-trap.
    registerCtrlRegVal("CR_CCR_RFT",          CR_CCR_R_L);
    registerCtrlRegVal("CR_CCR_RFT_C",        CR_CCR_R_H);
    
    -- Debug commands.
    registerCtrlRegVal("CR_DCRC_DBG_EXT",     16#08#); -- Enter external debug mode.
    registerCtrlRegVal("CR_DCRC_BREAK",       16#09#); -- Break; stop execution.
    registerCtrlRegVal("CR_DCRC_STEP",        16#0A#); -- Step one instruction. Can also be used to stop the core.
    registerCtrlRegVal("CR_DCRC_RESUME",      16#0C#); -- Resume/continue execution.
    registerCtrlRegVal("CR_DCRC_DBG_INT",     16#10#); -- Transfer debugging control back to the core.
    registerCtrlRegVal("CR_DCRC_RESET",       16#80#); -- Restart the context.
    registerCtrlRegVal("CR_DCRC_RESET_DBG",   16#88#); -- Restart the context in external debug mode.
    registerCtrlRegVal("CR_DCRC_RESET_BREAK", 16#89#); -- Restart the context in external debug mode and break.
    
    -- Handle the root file.
    handleFile(ROOT_FILE);
    
    -- Show the results.
    wait until rising_edge(sync);
    report "Test suite complete: "
         & integer'image(testCount) & " test(s) run of which "
         & integer'image(failedTests) & " failed; "
         & integer'image(abortedTests) & " test case(s) aborted due to "
         & "simulation errors or incompatible CFG vector."
      severity failure;
    
    wait;
    
  end process;
  
end Behavioral;

