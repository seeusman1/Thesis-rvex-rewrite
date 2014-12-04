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
use work.rvex_simUtils_pkg.all;
use work.rvex_simUtils_asDisas_pkg.all;
use work.rvex_utils_pkg.all;

--=============================================================================
-- This is a test suite for the rvex core.
-------------------------------------------------------------------------------
entity rvex_tb is
end rvex_tb;
-------------------------------------------------------------------------------
architecture Behavioral of rvex_tb is
--=============================================================================
  
  -- Configuration.
  constant CFG                  : rvex_generic_config_type := RVEX_DEFAULT_CONFIG;
  
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
  -- Instruction memory
  -----------------------------------------------------------------------------
  -- Size definition for the instruction memory.
  constant IMEM_DEPTH_LOG2      : natural := 10;
  constant IMEM_DEPTH           : natural := 2**IMEM_DEPTH_LOG2;
  
  -- Current contents of the instruction memory.
  signal imem                   : rvex_syllable_array(0 to IMEM_DEPTH-1);
  
  -- Fault signal for each syllable.
  signal imemFault              : std_logic_vector(0 to IMEM_DEPTH-1);
  
  -- Fault signal when processor is trying to access an instrution which is
  -- out of range (syllable defaults to 0 otherwise).
  signal imemFaultWhenOOR       : std_logic;
  
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
  
  -----------------------------------------------------------------------------
  -- Instantiate the rvex processor
  -----------------------------------------------------------------------------
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
  
  -----------------------------------------------------------------------------
  -- Model the instruction memory
  -----------------------------------------------------------------------------
  imem_model: process (clk) is
    variable lanePCs            : rvex_address_array(2**CFG.numLanesLog2-1 downto 0);
    variable fetch              : std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    variable revDecouple        : std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    variable addr               : natural;
    variable fault              : std_logic;
  begin
    if rising_edge(clk) then
      if reset = '1' then
        imem2rv_instr <= (others => (others => '0'));
        imem2rv_affinity <= (others => '0');
        imem2rv_fault <= (others => '0');
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
            lanePCs(lane) := std_logic_vector(unsigned(lanePCs(lane-1)) + 4);
            fetch(lane) := fetch(lane-1);
          end if;
        end loop;
        
        -- If fetch is high, return the syllable at the decoded PC.
        fault := '0';
        for lane in 1 to 2**CFG.numLanesLog2-1 loop
          if fetch(lane) = '1' then
            addr := to_integer(unsigned(lanePCs(lane)));
            if addr < IMEM_DEPTH then
              imem2rv_instr(lane) <= imem(addr);
              fault := fault or imemFault(addr);
            else
              imem2rv_instr(lane) <= (others => '0');
              fault := fault or imemFaultWhenOOR;
            end if;
          else
            imem2rv_instr(lane) <= (others => 'U');
          end if;
          if lane = lane2lastLane(lane, CFG) then
            if rv2mem_decouple(lane2group(lane, CFG)) = '1' then
              imem2rv_fault(lane2group(lane, CFG)) <= fault;
              fault := '0';
            else
              imem2rv_fault(lane2group(lane, CFG)) <= '0';
            end if;
          end if;
        end loop;
        
      end if;
    end if;
  end process;
  
  -----------------------------------------------------------------------------
  -- Model the data memory
  -----------------------------------------------------------------------------
  -- TODO
  dmem2rv_readData <= (others => (others => '0'));
  dmem2rv_fault <= (others => '0');
  
  -----------------------------------------------------------------------------
  -- Debug bus operations
  -----------------------------------------------------------------------------
  -- TODO
  dbg2rv_addr <= (others => '0');
  dbg2rv_readEnable <= '0';
  dbg2rv_writeEnable <= '0';
  dbg2rv_writeMask <= "1111";
  dbg2rv_writeData <= (others => '0');
  
  -----------------------------------------------------------------------------
  -- Run control operations
  -----------------------------------------------------------------------------
  -- TODO
  rctrl2rv_irq    <= (others => '0');
  rctrl2rv_irqID  <= (others => (others => '0'));
  rctrl2rv_run    <= (others => '1');
  rctrl2rv_reset  <= (others => '0');
  
  -----------------------------------------------------------------------------
  -- Test cases
  -----------------------------------------------------------------------------
  test_cases: process is
    
    -- Return values for functions. The return value is chosen such that you
    -- can add "exit when" in front of them such that the test case will
    -- complete when 
    constant RET_OK             : boolean := false;
    constant RET_COMPLETE       : boolean := true;
    
    -- Set to a NOP syllable by the init method.
    variable SYL_NOP            : rvex_syllable_type;
    
    -- Word address for the next syllable which is assembled.
    variable assemPC            : natural;
    
    -- Insert a number of clock cycles.
    procedure clkCycles(count: integer := 1) is
    begin
      for i in 1 to count loop
        wait for 1 ps;
        clk <= '1';
        wait for 5000 ps;
        clk <= '0';
        wait for 4999 ps;
      end loop;
    end clkCycles;
    
    -- Initializes the test suite.
    procedure init is
      variable ok       : boolean;
      variable error    : rvex_string_builder_type;
    begin
      
      -- Load default system control values.
      reset <= '1';
      clkEn <= '0';
      clkCycles(10);
      
      -- Try to assemble a NOP instruction.
      assembleLine(
        source    => "nop",
        line      => 1,
        syllable  => SYL_NOP,
        ok        => ok,
        error     => error
      );
      
      -- Fail completely if we couldn't even do that.
      assert ok
        report "Could not assemble nop instruction! " & rvs2sim(error)
        severity failure;
      
    end init;
    
    -- Resets the core, instruction memory etc. for a new test case.
    impure function newTest(name: string) return boolean is
    begin
      
      -- Update the current test information.
      sim_currentTest <= rvs2str(to_rvs(name));
      
      -- Reset assembly counter.
      assemPC := 0;
      
      -- Clear the instruction memory.
      imem <= (others => (others => '0'));
      imemFault  <= (others => '1');
      imemFaultWhenOOR  <= '1';
      
      -- Start the core in the next cycle.
      reset <= '0';
      clkEn <= '1';
      
      return RET_OK;
      
    end newTest;
    
    -- Call when a test fails.
    impure function failTest(reason: string) return boolean is
    begin
      
      -- Report the failure in the log.
      report "Test case "
           & '"'
           & rvs2str(rvs_trimTrailingSpacesto_rvs(sim_currentTest))
           & '"'
           & " failed: "
           & reason
        severity warning;
      
      -- Report the failure by strobing sim_failure.
      sim_failure <= '1';
      clkCycles(1);
      sim_failure <= '0';
      
      -- Give the program some more time to crash and burn, which might help in
      -- finding the cause.
      clkCycles(30);
      
      -- Stobe the completed signal and reset the core.
      reset <= '1';
      clkEn <= '0';
      sim_complete <= '1';
      clkCycles(1);
      sim_complete <= '0';
      
      return RET_COMPLETE;
      
    end failTest;
    
    -- Call when a test succeeds.
    impure function succeedTest return boolean is
    begin
      
      -- Report the success in the log.
      report "Test case "
           & '"'
           & rvs2str(rvs_trimTrailingSpacesto_rvs(sim_currentTest))
           & '"'
           & " completed successfully."
        severity note;
      
      -- Stobe the completed signal and reset the core.
      reset <= '1';
      clkEn <= '0';
      sim_complete <= '1';
      clkCycles(1);
      sim_complete <= '0';
      
      return RET_COMPLETE;
      
    end succeedTest;
    
    -- Inserts a syllable into the instruction memory.
    impure function insertIntoImem(syllable: rvex_syllable_type) return boolean is
    begin
      if assemPC >= IMEM_DEPTH then
        return failTest("ran out of instruction memory space while assembling.");
      end if;
      imem(assemPC) <= syllable;
      imemFault(assemPC) <= '0';
      return RET_OK;
    end insertIntoImem;
    
    -- Loads an assembly syllable into the instruction memory. When a syllable
    -- with a stop bit is encountered, NOPs are inserted until the next generic
    -- binary bundle alignment point.
    impure function assem(source: string) return boolean is
      variable syllable : rvex_syllable_type;
      variable ok       : boolean;
      variable error    : rvex_string_builder_type;
    begin
      
      -- Try to assemble.
      assembleLine(
        source    => source,
        line      => assemPC + 1,
        syllable  => syllable,
        ok        => ok,
        error     => error
      );
      
      -- Fail test if assembly failed.
      if not ok then
        return failTest("assembler error: " & rvs2str(source));
      end if;
      
      -- Load into IMEM and increment loading program counter.
      imem(assemPC) := syllable;
      assemPC := assemPC + 1;
      
      -- If the stop bit is set, insert NOPs until a generic binary boundary.
      if syllable(1) = '1' then
        while (assemPC mod 2**CFG.genBundleSizeLog2) /= 0 loop
          imem(assemPC) := SYL_NOP;
          assemPC := assemPC + 1;
        end loop;
      end if;
      
    end assem;
    
  begin
    
    -- Initialize test suite.
    init;
    
    
    for dummy in 0 to 0 loop
      exit when newTest("Hello World!");
      
      -- 0x0000
      exit when assem("add r0.1 = r0.0, 33        ");
      exit when assem("nop                      ;;");
      
      -- 0x0020
      exit when assem("nop                        ");
      exit when assem("add r0.2 = r0.1, r0.1    ;;");
      
      -- 0x0040
      exit when assem("nop                        ");
      exit when assem("nop                        ");
      exit when assem("nop                        ");
      exit when assem("nop                        ");
      exit when assem("nop                        ");
      exit when assem("nop                        ");
      exit when assem("nop                        ");
      exit when assem("stop                     ;;");
      
      -- Start.
      exit when clkCycles(100);
      
      -- Make sure done is high by now.
      if rv2rctrl_done(0) = '0' then
        exit when failTest("Execution did not complete...");
      end if;
      
      exit when succeedTest;
      
    end loop;
    
  end process;
  
end Behavioral;

