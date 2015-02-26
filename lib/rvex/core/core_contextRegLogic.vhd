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
use rvex.core_ctrlRegs_pkg.all;
use rvex.core_trap_pkg.all;

--=============================================================================
-- This entity contains the specifications and logic for the control registers
-- which are specific to a context.
-------------------------------------------------------------------------------
entity core_contextRegLogic is
--=============================================================================
  generic (
    
    -- Configuration.
    CFG                         : rvex_generic_config_type;
    
    -- Index of the context associated with this logic block/
    CONTEXT_INDEX               : natural
    
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
    -- Interface with the control registers and bus logic
    ---------------------------------------------------------------------------
    -- Interface for the control registers.
    cxreg2creg                  : out cxreg2creg_type;
    creg2cxreg                  : in  creg2cxreg_type;
    
    -- Resets the context control register file. Hardware and bus writes going
    -- on in the same cycle take precedence, allowing the context to reset
    -- directly into debug mode.
    cxreg2creg_reset            : out std_logic;
    
    ---------------------------------------------------------------------------
    -- Run control interface
    ---------------------------------------------------------------------------
    -- Active high context reset input. When high, the context control
    -- registers (including PC, done and break flag) will be reset.
    rctrl2cxreg_reset           : in  std_logic;
    
    -- Active high done output. This is asserted when the context encounters
    -- a stop syllable. Processing a stop signal also sets the BRK control
    -- register, which stops the core. This bit can be reset by issuing a core
    -- reset or by means of the debug interface.
    cxreg2rctrl_done            : out std_logic;
    
    ---------------------------------------------------------------------------
    -- Pipelane interface: misc.
    ---------------------------------------------------------------------------
    -- When high, the context registers must maintain their current value.
    cxplif2cxreg_stall          : in  std_logic;

    -- Idle flag, as reported to the external run control interface. Used for
    -- the performance counters.
    cxplif2cxreg_idle           : in  std_logic;

    -- Syllable committed flag for each lane, used for the performance
    -- counters.
    cxplif2cxreg_sylCommit      : in  rvex_sylStatus_type;
    
    -- NOP flag for each lane with the same timing as sylCommit, used for the
    -- performance counters.
    cxplif2cxreg_sylNop         : in  rvex_sylStatus_type;

    -- Stop flag. When high, the BRK and done flags in the debug control
    -- register should be set.
    cxplif2cxreg_stop           : in  std_logic;
    
    ---------------------------------------------------------------------------
    -- Pipelane interface: branch/link registers
    ---------------------------------------------------------------------------
    -- Write data and enable signal for each branch register.
    cxplif2cxreg_brWriteData    : in  rvex_brRegData_type;
    cxplif2cxreg_brWriteEnable  : in  rvex_brRegData_type;
    
    -- Current state of the branch registers.
    cxreg2cxplif_brReadData     : out rvex_brRegData_type;
    
    -- Write data and enable signal for the link register.
    cxplif2cxreg_linkWriteData  : in  rvex_data_type;
    cxplif2cxreg_linkWriteEnable: in  std_logic;
    
    -- Current state of the link register.
    cxreg2cxplif_linkReadData   : out rvex_data_type;
    
    ---------------------------------------------------------------------------
    -- Pipelane interface: program counter
    ---------------------------------------------------------------------------
    -- Next value for the PC register. This is written when stall is low and
    -- overridePC is not asserted.
    cxplif2cxreg_nextPC         : in  rvex_address_type;

    -- Current value of the PC register.
    cxreg2cxplif_currentPC      : out rvex_address_type;

    -- The overridePC flag is set when the debug bus writes to the context
    -- registers or when the context or processor is reset. This is reset when
    -- overridePC_ack is asserted while stall is low. It indicates to the
    -- branch unit that it should inject a branch to the current PC register
    -- regardless of the current instruction or state.
    cxreg2cxplif_overridePC     : out std_logic;
    cxplif2cxreg_overridePC_ack : in  std_logic;

    ---------------------------------------------------------------------------
    -- Pipelane interface: trap handling
    ---------------------------------------------------------------------------
    -- Current trap handler. When the application has marked that it is not
    -- currently capable of accepting a trap, this is set to the panic handler
    -- register instead.
    cxreg2cxplif_trapHandler    : out rvex_address_type;

    -- Regular trap information. When the trap in trapInfo is active, the trap
    -- information should be stored in the trap cause/arg registers. In
    -- addition, the register hardware should save the current value of the
    -- control register and should clear the ready-for-trap and interrupt-
    -- enable bits, as well as the debug-trap-enable bit if the trap cause maps
    -- to a debug trap.
    cxplif2cxreg_trapInfo       : in  trap_info_type;
    cxplif2cxreg_trapPoint      : in  rvex_address_type;

    -- Connected to the current value of the trap point register. Used by the
    -- branch unit as the return address for the RFI instruction.
    cxreg2cxplif_trapReturn     : out rvex_address_type;

    -- RFI flag. When high, the saved control register value should be restored
    -- and the trap cause field should be set to 0.
    cxplif2cxreg_rfi            : in  std_logic;

    -- Set when the current value of the trap cause register maps to a debug
    -- trap. This is used by the branch unit to disable breakpoints for the
    -- first instruction executed after the debug trap returns.
    cxreg2cxplif_handlingDebugTrap:out std_logic;

    -- Current value of the interrupt-enable flag in the control register.
    cxreg2cxplif_interruptEnable: out std_logic;

    -- Current value of the debug-trap-enable flag in the control register.
    cxreg2cxplif_debugTrapEnable: out std_logic;

    -- Current hardware breakpoint configuration.
    cxreg2cxplif_breakpoints    : out cxreg2pl_breakpoint_info_type;

    ---------------------------------------------------------------------------
    -- Pipelane interface: external debug control signals
    ---------------------------------------------------------------------------
    -- Whether debug traps are to be handled normally or by halting execution
    -- for debugging through the external bebug bus.
    cxreg2cxplif_extDebug       : out std_logic;

    -- External debug trap information. When the trap in exDbgTrapInfo is
    -- active, the trap cause should be stored in the debug control register
    -- and the BRK flag in the debug control register should be set.
    cxplif2cxreg_exDbgTrapInfo  : in  trap_info_type;

    -- BRK flag from the debug control register. When high, the core should
    -- be halted.
    cxreg2cxplif_brk            : out std_logic;

    -- Stepping mode flag from the debug control register. When high,
    -- executing any instruction which has the brkValid flag set should cause
    -- a step trap.
    cxreg2cxplif_stepping       : out std_logic;

    -- Resuming flag. This is set when the BRK flag is cleared by the debug
    -- bus. It is cleared when the resumed bit is high while stall is low.
    -- While high, issued instructions should have the brkValid flag cleared,
    -- so breakpoints and step traps are ignored.
    cxreg2cxplif_resuming       : out std_logic;
    cxplif2cxreg_resuming_ack   : in  std_logic;
    
    ---------------------------------------------------------------------------
    -- Interface with configuration logic
    ---------------------------------------------------------------------------
    -- Each nibble in the data word corresponds to a pipelane group, of which
    -- bit 3 specifies whether the pipelane group should be disabled (high) or
    -- enabled (low) and, if low, bit 2..0 specify the context it should run
    -- on. Bits which are not supported by the core (as specified in the CFG
    -- generic) should be written zero or the request will be ignored (as
    -- specified by the error flag in the global control register file).
    -- The enable signal is active high, and is valid one clkEn'd cycle BEFORE
    -- the data vector is. This is because the enable signal is connected to
    -- the bus write enable signal for the register and the data is connected
    -- to the register output.
    cxreg2cfg_requestData_r     : out rvex_data_type;
    cxreg2cfg_requestEnable     : out std_logic;
    
    ---------------------------------------------------------------------------
    -- Trace control unit interface
    ---------------------------------------------------------------------------
    -- Whether tracing should be enabled or not for each context. Active high.
    cxreg2trace_enable          : out std_logic;
    
    -- Whether trap information should be traced. Active high.
    cxreg2trace_trapEn          : out std_logic;
    
    -- Whether memory operations should be traced. Active high.
    cxreg2trace_memEn           : out std_logic;
    
    -- Whether register writes should be traced. Active high.
    cxreg2trace_regEn           : out std_logic
    
  );
end core_contextRegLogic;

--=============================================================================
architecture Behavioral of core_contextRegLogic is
--=============================================================================
  
  -- Delayed status signals for the performance counters.
  signal cxplif2cxreg_stall_r     : std_logic;
  signal cxplif2cxreg_idle_r      : std_logic;
  signal cxplif2cxreg_sylCommit_r : rvex_sylStatus_type;
  signal cxplif2cxreg_sylNop_r    : rvex_sylStatus_type;
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -- Delay the performance counter increment signals by a cycle to take them
  -- out of the critical paths.
  perf_counter_delay: process (clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        cxplif2cxreg_stall_r      <= '1';
        cxplif2cxreg_idle_r       <= '1';
        cxplif2cxreg_sylCommit_r  <= (others => '0');
        cxplif2cxreg_sylNop_r     <= (others => '0');
      elsif clkEn = '1' then
        cxplif2cxreg_stall_r      <= cxplif2cxreg_stall;
        cxplif2cxreg_idle_r       <= cxplif2cxreg_idle;
        cxplif2cxreg_sylCommit_r  <= cxplif2cxreg_sylCommit;
        cxplif2cxreg_sylNop_r     <= cxplif2cxreg_sylNop;
      end if;
    end if;
  end process;
  
  -- Single process which handles all combinatorial logic for the context
  -- control registers.
  logic: process (
    creg2cxreg, rctrl2cxreg_reset, cxplif2cxreg_stall, cxplif2cxreg_stop,
    cxplif2cxreg_brWriteData, cxplif2cxreg_brWriteEnable, cxplif2cxreg_nextPC,
    cxplif2cxreg_linkWriteData, cxplif2cxreg_linkWriteEnable,
    cxplif2cxreg_overridePC_ack, cxplif2cxreg_trapInfo, cxplif2cxreg_trapPoint,
    cxplif2cxreg_rfi, cxplif2cxreg_exDbgTrapInfo, cxplif2cxreg_resuming_ack,
    cxplif2cxreg_idle_r, cxplif2cxreg_sylCommit_r, cxplif2cxreg_sylNop_r,
    cxplif2cxreg_stall_r
  ) is
    variable l2c  : cxreg2creg_type;
    variable c2l  : creg2cxreg_type;
    variable enteringDebugTrap  : std_logic;
    variable countClear         : std_logic;
    variable bundleCommit       : std_logic;
  begin
    l2c := (others => HW2REG_DEFAULT);
    c2l := creg2cxreg;
    
    -- Determine if we're entering a debug trap (this generates a relatively
    -- large amount of logic because of the table lookup, so we only want to
    -- do it once).
    enteringDebugTrap := cxplif2cxreg_trapInfo.active
      and rvex_isDebugTrap(cxplif2cxreg_trapInfo);
    
    ---------------------------------------------------------------------------
    -- Context control register (CCR) and saved context control register (SCCR)
    ---------------------------------------------------------------------------
    -- 
    --       |-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|
    -- CCR   |     Cause     |    Branch     |                   |b|B|r|R|i|I|
    --       |-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|
    -- SCCR  |      ID       |                                   |b|B|r|R|i|I|
    --       |-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|
    -- 
    -- I      = Interrupt enable flag.
    -- i      = Interrupt disable flag, complement of I.
    --          Writing the following bits to i:I has the following effect.
    --            00 -> no change.
    --            01 -> enable interrupts.
    --            10 -> disable interrupts.
    --            11 -> toggle interrupt enable.
    --          Interrupts are disabled when a trap is entered. This register
    --          is saved in the saved context control register when a trap is
    --          entered and restored when an RFI instruction is encountered.
    -- 
    -- R      = Ready for trap flag.
    -- r      = Not ready for trap flag, complement of R.
    --          Writing the following bits to r:R has the following effect.
    --            00 -> no change.
    --            01 -> set ready for trap.
    --            10 -> clear ready for trap.
    --            11 -> toggle ready for trap.
    --          Ready-for-trap is cleared when a trap is entered. This register
    --          is saved in the saved context control register when a trap is
    --          entered and restored when an RFI instruction is encountered.
    --          The effect of ready-for-trap being cleared is that the trap
    --          handler will be set to the panic trap handler instead of the
    --          regular one. The idea being that this allows the processor to
    --          discern between a trap which it can completely recover from and
    --          traps where it can't recover from because state information is
    --          lost (for example, when a trap occurs while the context is
    --          being stored on the stack at the start of the trap handler).
    -- 
    -- B      = Breakpoint enable flag.
    -- b      = Breakpoint disable flag, complement of B.
    --          Breakpoint-enable is cleared when a *debug* trap is entered.
    --          This register is saved in the saved context control register
    --          when a trap is entered when restored when an RFI instruction is
    --          encountered. While breakpoint-enable is cleared breakpoints are
    --          ignored, unless the external debug flag is set in the debug
    --          control register.
    -- 
    -- Branch = Branch register file. Contains the current state of the branch
    --          registers. Use with caution - there is no forwarding here, and
    --          the memory read is (likely, see also rvex_pipline_pkg) done in
    --          a different stage than the register write. The processor cannot
    --          write to this register for this reason. The debug bus can,
    --          however.
    --
    -- Cause  = Trap cause. Set by to the trap cause by hardware when the trap
    --          handler is called. Reset to 0 by hardware when an RFI
    --          instruction is encountered. Read-write by the debug bus, but
    --          the processor cannot write to this register.
    -- 
    -- ID     = Read only field, tied to the index of this context. The
    --          application can use this field to identify itself.
    
    -- Make the interrupt enable registers.
    creg_makeSetClearFlag(l2c, c2l, CR_CCR, CR_CCR_IEN, CR_CCR_IEN_C, '0',
      clear         => cxplif2cxreg_trapInfo.active and not cxplif2cxreg_stall,
      permissions   => READ_WRITE
    );
    creg_makeSetClearFlag(l2c, c2l, CR_SCCR, CR_CCR_IEN, CR_CCR_IEN_C, '0',
      permissions   => READ_WRITE
    );
    cxreg2cxplif_interruptEnable <= creg_readRegisterBit(l2c, c2l, CR_CCR, CR_CCR_IEN);
    
    -- Make the ready for trap registers.
    creg_makeSetClearFlag(l2c, c2l, CR_CCR, CR_CCR_RFT, CR_CCR_RFT_C, '0',
      clear         => cxplif2cxreg_trapInfo.active and not cxplif2cxreg_stall,
      permissions   => READ_WRITE
    );
    creg_makeSetClearFlag(l2c, c2l, CR_SCCR, CR_CCR_RFT, CR_CCR_RFT_C, '0',
      permissions   => READ_WRITE
    );
    
    -- Make the debug trap/breakpoint enable registers.
    creg_makeSetClearFlag(l2c, c2l, CR_CCR, CR_CCR_BPE, CR_CCR_BPE_C, '0',
      clear         => enteringDebugTrap and not cxplif2cxreg_stall,
      permissions   => READ_WRITE
    );
    creg_makeSetClearFlag(l2c, c2l, CR_SCCR, CR_CCR_BPE, CR_CCR_BPE_C, '0',
      permissions   => READ_WRITE
    );
    cxreg2cxplif_debugTrapEnable <= creg_readRegisterBit(l2c, c2l, CR_CCR, CR_CCR_BPE);
    
    -- Generate the save-restore logic for the flags.
    creg_makeSaveRestoreLogic(l2c, c2l, CR_CCR, CR_SCCR, 5, 0,
      save          => cxplif2cxreg_trapInfo.active and not cxplif2cxreg_stall,
      restore       => cxplif2cxreg_rfi and not cxplif2cxreg_stall
    );
    
    -- Make the branch registers.
    for b in 7 downto 0 loop
      creg_makeNormalRegister(l2c, c2l, CR_CCR, b+16, b+16,
        writeEnable   => (cxplif2cxreg_brWriteEnable(b) and not cxplif2cxreg_stall),
        writeData     => cxplif2cxreg_brWriteData(b downto b),
        permissions   => DEBUG_CAN_WRITE
      );
    end loop;
    cxreg2cxplif_brReadData <= creg_readRegisterVect(l2c, c2l, CR_CCR, 23, 16);
    
    -- Make the cause register.
    creg_makeNormalRegister(l2c, c2l, CR_CCR, 31, 24,
      writeEnable   => (cxplif2cxreg_trapInfo.active and not cxplif2cxreg_stall),
      writeData     => cxplif2cxreg_trapInfo.cause,
      permissions   => DEBUG_CAN_WRITE
    );
    if cxplif2cxreg_rfi = '1' and cxplif2cxreg_stall = '0' then
      creg_writeRegisterVect(l2c, c2l, CR_CCR, 31, 24, "00000000");
    end if;
    cxreg2cxplif_handlingDebugTrap <= TRAP_TABLE(vect2uint(creg_readRegisterVect(l2c, c2l, CR_CCR, 31, 24))).isDebugTrap;
    
    -- Make the ID field.
    creg_makeHardwiredField(l2c, c2l, CR_SCCR, 31, 24, uint2vect(CONTEXT_INDEX, 8));
    
    ---------------------------------------------------------------------------
    -- Link register (LR)
    ---------------------------------------------------------------------------
    -- 
    --       |-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|
    -- LR    |                              LR                               |
    --       |-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|
    --
    -- Contains the current state of the link register. Use with caution -
    -- there is no forwarding here, and the memory read is (likely, see also
    -- rvex_pipline_pkg) done in a different stage than the register write.
    -- The processor cannot write to this register for this reason. The debug
    -- bus can, however.
    
    -- Make the register.
    creg_makeNormalRegister(l2c, c2l, CR_LR, 31, 0,
      writeEnable   => (cxplif2cxreg_linkWriteEnable and not cxplif2cxreg_stall),
      writeData     => cxplif2cxreg_linkWriteData,
      permissions   => DEBUG_CAN_WRITE
    );
    cxreg2cxplif_linkReadData <= creg_readRegisterVect(l2c, c2l, CR_LR, 31, 0);
    
    ---------------------------------------------------------------------------
    -- Program counter register (PC)
    ---------------------------------------------------------------------------
    -- 
    --       |-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|
    -- PC    |                              PC                               |
    --       |-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|
    --
    -- Contains the value of the program counter in the IF+1 stage. It does not
    -- make much sense for the processor to read this register, but the debug
    -- bus can read from it and write to it. When the register is written by
    -- the debug bus, the jump flag in the debug control register is set, to
    -- ensure that the branch unit properly jumps to the new PC.
    
    -- Make the register. The hardware always writes the new PC to this
    -- register while the incoming stall signal is low (this is also forced
    -- low when the context is not connected to any pipelane group). Note that,
    -- when the debug bus writes to the register, stall will also be high due
    -- to the bus claiming logic.
    creg_makeNormalRegister(l2c, c2l, CR_PC, 31, 0,
      resetState    => CFG.resetVectors(CONTEXT_INDEX),
      writeEnable   => (not cxplif2cxreg_stall)
                   and (not creg_readRegisterBit(l2c, c2l, CR_DCR, CR_DCR_JUMP)),
      writeData     => cxplif2cxreg_nextPC,
      permissions   => DEBUG_CAN_WRITE
    );
    cxreg2cxplif_currentPC <= creg_readRegisterVect(l2c, c2l, CR_PC, 31, 0);
    
    ---------------------------------------------------------------------------
    -- Trap handler (TH) and panic handler (PH) registers
    ---------------------------------------------------------------------------
    -- 
    --       |-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|
    -- TH    |                              TH                               |
    --       |-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|
    -- PH    |                              PH                               |
    --       |-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|
    --
    -- The trap handler and panic handler registers contain the addresses of
    -- the respective handlers in instruction memory space. When a trap occurs,
    -- execution will jump to the trap handler if the ready-for-trap bit in the
    -- context control register is set, or the panic handler if the bit is not
    -- set.
    
    -- Make the trap handler register.
    creg_makeNormalRegister(l2c, c2l, CR_TH, 31, 0,
      permissions   => READ_WRITE
    );
    
    -- Make the panic handler register.
    creg_makeNormalRegister(l2c, c2l, CR_PH, 31, 0,
      permissions   => READ_WRITE
    );
    
    -- Output the currently active handler.
    if creg_readRegisterBit(l2c, c2l, CR_CCR, CR_CCR_RFT) = '1' then
      cxreg2cxplif_trapHandler <= creg_readRegisterVect(l2c, c2l, CR_TH, 31, 0);
    else
      cxreg2cxplif_trapHandler <= creg_readRegisterVect(l2c, c2l, CR_PH, 31, 0);
    end if;
    
    ---------------------------------------------------------------------------
    -- Trap point (TP) register
    ---------------------------------------------------------------------------
    -- 
    --       |-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|
    -- TP    |                              TP                               |
    --       |-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|
    --
    -- The trap point register is set when the trap service routine is entered.
    -- It is set to the bundle PC of the instruction which caused the trap.
    -- When RFI is encountered, the branch unit will jump to the address
    -- specified here. For external interrupts, this is the right address; for
    -- traps, it's the right address if the instruction causing the trap should
    -- be reattempted. The processor can change the return address by writing
    -- to this register. The debug bus also has full control over the register.
    
    -- Make the register.
    creg_makeNormalRegister(l2c, c2l, CR_TP, 31, 0,
      writeEnable   => (cxplif2cxreg_trapInfo.active and not cxplif2cxreg_stall),
      writeData     => cxplif2cxreg_trapPoint,
      permissions   => READ_WRITE
    );
    cxreg2cxplif_trapReturn <= creg_readRegisterVect(l2c, c2l, CR_TP, 31, 0);
    
    ---------------------------------------------------------------------------
    -- Trap argument (TA) register
    ---------------------------------------------------------------------------
    -- 
    --       |-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|
    -- TA    |                              TA                               |
    --       |-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|
    --
    -- The trap argument register is set when the trap service routine is
    -- entered. The meaning of the value depends on the trap cause, see also
    -- rvex_trap_pkg.vhd. The register is read only to the processor, but may
    -- be written by the debug bus.
    
    -- Make the register.
    creg_makeNormalRegister(l2c, c2l, CR_TA, 31, 0,
      writeEnable   => (cxplif2cxreg_trapInfo.active and not cxplif2cxreg_stall),
      writeData     => cxplif2cxreg_trapInfo.arg,
      permissions   => DEBUG_CAN_WRITE
    );
    
    ---------------------------------------------------------------------------
    -- Breakpoint registers (BR*)
    ---------------------------------------------------------------------------
    --
    --       |-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|
    -- BR0   |                              BR0                              |
    --       |-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|
    -- BR1   |                              BR1                              |
    --       |-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|
    -- BR2   |                              BR2                              |
    --       |-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|
    -- BR3   |                              BR3                              |
    --       |-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|
    --
    -- These registers contain the hardware breakpoint addresses. Their
    -- function is controlled by the respective br* fields in the debug control
    -- registers. The processor can write to these registers if external debug
    -- is disabled. The debug bus can always write to them. Note however thet
    -- the existence of these registers is controlled by CFG.numBreakpoints;
    -- not all of them (or none) may exist.
    
    -- Generate breakpoint registers.
    cxreg2cxplif_breakpoints.addr <= (others => (others => RVEX_UNDEF));
    for b in 0 to CFG.numBreakpoints - 1 loop
      creg_makeNormalRegister(l2c, c2l, CR_BRK0 + b, 31, 0, permissions => READ_WRITE);
      if creg_readRegisterBit(l2c, c2l, CR_DCR, CR_DCR_EXT_DBG) = '1' then
        creg_setPermissions(l2c, c2l, CR_BRK0 + b, 31, 0, DEBUG_CAN_WRITE);
      end if;
      cxreg2cxplif_breakpoints.addr(b) <= creg_readRegisterVect(l2c, c2l, CR_BRK0 + b, 31, 0);
    end loop;
    
    ---------------------------------------------------------------------------
    -- Debug control register 1 (DCR)
    ---------------------------------------------------------------------------
    -- 
    --       |-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|
    -- DCR   |D|J| |I|E|R|S|B|     Cause     |   |br3|   |br2|   |br1|   |br0|
    --       |-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|
    -- 
    -- br0    = breakpoint control 0.
    -- br1    = breakpoint control 1.
    -- br2    = breakpoint control 2.
    -- br3    = breakpoint control 3.
    --          Breakpoint control registers can only be written to if the
    --          breakpoint is actually implemented in hardware through
    --          CFG.numBreakpoints. The encoding for the breakpoint control
    --          registers is as follows.
    --            00 -> breakpoint disabled.
    --            01 -> PC breakpoint enabled.
    --            10 -> data memory write breakpoint.
    --            11 -> data memory access breakpoint.
    --          These registers can always be written by the debug bus, but can
    --          only be written by the core when the external debug flag is
    --          cleared.
    -- 
    -- Cause  = trap cause field for debug traps handled in external debug
    --          mode. Read only, updated by hardware when BRK is set due to a
    --          debug trap.
    -- 
    -- B      = BRK flag. When set, the context stops running until further
    --          notice. The flag is set in the following conditions.
    --            - The debug bus writes a one to the flag (writing a zero has
    --              no effect).
    --            - A debug trap is encountered while external debug is on.
    --            - A stop instruction is encountered.
    -- 
    -- S      = Step flag. This flag may be set by the debug bus by writing a
    --          one to it, writing a zero has no effect. The processor can also
    --          set this flag, but only if the external debug flag is cleared.
    --          When set, the resume flag is also set and the BRK flag is
    --          cleared. When an instruction is executed while this is set and
    --          resume is cleared (i.e. the second instruction after resuming)
    --          a step debug trap will be triggered. This bit is cleared by
    --          hardware when BRK is set or when a debug trap is entered.
    -- 
    -- R      = Resume flag. This flag may be set the debug bus by writing a
    --          one to it, writing a zero has no effect. The processor has no
    --          write access to this flag. Debug traps generated by
    --          instructions which were fetched while this flag was set are
    --          ignored. This flag is cleared by hardware when the first
    --          instruction is successfully fetched. This behavior allows the
    --          processor to step beyond the breakpoint which caused the
    --          processor to break, and it also naturally permits single
    --          instruction stepping.
    --
    -- E      = External debug flag. This flag may be set by the debug bus by
    --          writing a one to it, writing a zero has no effect. The
    --          processor has no write access to this flag. While enabled,
    --          debug traps are handled by setting the BRK flag instead of
    --          handling the trap normally. The processor is also denied write
    --          access to debug related registers while this is set.
    -- 
    -- I      = Internal debug flag. Complement of the external debug flag.
    --          When the debug bus writes a one to this flag, the external
    --          debug flag is cleared to give the processor control over
    --          debugging again.
    -- 
    -- J      = Jump flag. This bit is set by hardware when the debug bus
    --          writes to the PC register and is cleared when the processor
    --          jumps to it. The flag is read only.
    -- 
    -- D      = Done flag. This bit is set by hardware when a stop instruction
    --          is encountered. It is cleared when a one is written to the
    --          resume or step bits. In addition, when a one is written to this
    --          flag, the control register file for this context is completely
    --          reset, as if the external context reset signal was asserted.
    --          When combined with writing a one to the external debug flag,
    --          the core starts in external debug mode, and when combined with
    --          writing a one to BRK or the step flag, the core will stop
    --          execution immediately. Note that breakpoint information will
    --          have to be reloaded, as those registers will be reset.
    --
    -- In other words, the highest byte in this register may be used as a debug
    -- command register by writing the following codes to it:
    --
    --  0x08------ => Enter external debug mode.
    --  0x09------ => Break; stop execution.
    --  0x0A------ => Step one instruction. Can also be used to stop the core.
    --  0x0C------ => Resume/continue execution.
    --  0x10------ => Transfer debugging control back to the core.
    --  0x80------ => Restart the context.
    --  0x88------ => Restart the context in external debug mode.
    --  0x89------ => Reset the context in external debug mode and stop
    --                execution immediately.
    
    -- Generate breakpoint control registers.
    cxreg2cxplif_breakpoints.cfg <= (others => (others => RVEX_UNDEF));
    for b in 0 to CFG.numBreakpoints - 1 loop
      creg_makeNormalRegister(l2c, c2l, CR_DCR, b*4+1, b*4, permissions => READ_WRITE);
      if creg_readRegisterBit(l2c, c2l, CR_DCR, CR_DCR_EXT_DBG) = '1' then
        creg_setPermissions(l2c, c2l, CR_DCR, b*4+1, b*4, DEBUG_CAN_WRITE);
      end if;
      cxreg2cxplif_breakpoints.cfg(b) <= creg_readRegisterVect(l2c, c2l, CR_DCR, b*4+1, b*4);
    end loop;
    
    -- Generate trap cause register.
    creg_makeNormalRegister(l2c, c2l, CR_DCR, 23, 16, permissions => DEBUG_CAN_WRITE);
    if cxplif2cxreg_exDbgTrapInfo.active = '1' and cxplif2cxreg_stall = '0' then
      creg_writeRegisterVect(l2c, c2l, CR_DCR, 23, 16, cxplif2cxreg_exDbgTrapInfo.cause);
    end if;
    
    -- Generate the BRK flag.
    creg_makeHardwareFlag(l2c, c2l, CR_DCR, CR_DCR_BREAK,
      resetState  => '0',
      set         => (cxplif2cxreg_exDbgTrapInfo.active and not cxplif2cxreg_stall)
                  or (cxplif2cxreg_stop and not cxplif2cxreg_stall)
                  or creg_isBusWritingOneToBit(l2c, c2l, CR_DCR, CR_DCR_BREAK),
      clear       => creg_isBusWritingOneToBit(l2c, c2l, CR_DCR, CR_DCR_STEP)
                  or creg_isBusWritingOneToBit(l2c, c2l, CR_DCR, CR_DCR_RESUME),
      permissions => DEBUG_CAN_WRITE
    );
    cxreg2cxplif_brk <= creg_readRegisterBit(l2c, c2l, CR_DCR, CR_DCR_BREAK);
    
    -- Generate the step flag.
    creg_makeHardwareFlag(l2c, c2l, CR_DCR, CR_DCR_STEP,
      resetState  => '0',
      set         => creg_isBusWritingOneToBit(l2c, c2l, CR_DCR, CR_DCR_STEP),
      clear       => enteringDebugTrap
                  or (cxplif2cxreg_exDbgTrapInfo.active and not cxplif2cxreg_stall)
                  or (cxplif2cxreg_stop and not cxplif2cxreg_stall)
                  or creg_isBusWritingOneToBit(l2c, c2l, CR_DCR, CR_DCR_BREAK),
      permissions => DEBUG_CAN_WRITE
    );
    if creg_readRegisterBit(l2c, c2l, CR_DCR, CR_DCR_EXT_DBG) = '0' then
      creg_setPermissions(l2c, c2l, CR_DCR, CR_DCR_STEP, CR_DCR_STEP, READ_WRITE);
    end if;
    cxreg2cxplif_stepping <= creg_readRegisterBit(l2c, c2l, CR_DCR, CR_DCR_STEP);
    
    -- Generate the resume flag.
    creg_makeHardwareFlag(l2c, c2l, CR_DCR, CR_DCR_RESUME,
      resetState  => '0',
      set         => creg_isBusWritingOneToBit(l2c, c2l, CR_DCR, CR_DCR_STEP)
                  or creg_isBusWritingOneToBit(l2c, c2l, CR_DCR, CR_DCR_RESUME),
      clear       => (cxplif2cxreg_resuming_ack and not cxplif2cxreg_stall),
      permissions => DEBUG_CAN_WRITE
    );
    cxreg2cxplif_resuming <= creg_readRegisterBit(l2c, c2l, CR_DCR, CR_DCR_RESUME);
    
    -- Generate the external/internal debug flag.
    creg_makeSetClearFlag(l2c, c2l, CR_DCR, CR_DCR_EXT_DBG, CR_DCR_INT_DBG,
      resetState  => '0',
      permissions => DEBUG_CAN_WRITE
    );
    cxreg2cxplif_extDebug <= creg_readRegisterBit(l2c, c2l, CR_DCR, CR_DCR_EXT_DBG);
    
    -- Generate the jump flag.
    creg_makeHardwareFlag(l2c, c2l, CR_DCR, CR_DCR_JUMP,
      resetState  => '0',
      set         => creg_isBusWritingToBit(l2c, c2l, CR_PC, 0),
      clear       => (cxplif2cxreg_overridePC_ack and not cxplif2cxreg_stall),
      permissions => DEBUG_CAN_WRITE
    );
    cxreg2cxplif_overridePC <= creg_readRegisterBit(l2c, c2l, CR_DCR, CR_DCR_JUMP);
    
    -- Generate the done flag.
    creg_makeHardwareFlag(l2c, c2l, CR_DCR, CR_DCR_DONE,
      resetState  => '0',
      set         => (cxplif2cxreg_stop and not cxplif2cxreg_stall),
      clear       => creg_isBusWritingOneToBit(l2c, c2l, CR_DCR, CR_DCR_STEP)
                  or creg_isBusWritingOneToBit(l2c, c2l, CR_DCR, CR_DCR_RESUME)
                  or creg_isBusWritingOneToBit(l2c, c2l, CR_DCR, CR_DCR_DONE),
      permissions => DEBUG_CAN_WRITE
    );
    cxreg2rctrl_done <= creg_readRegisterBit(l2c, c2l, CR_DCR, CR_DCR_DONE);
    
    -- Drive the context reset signal.
    cxreg2creg_reset <= creg_isBusWritingOneToBit(l2c, c2l, CR_DCR, CR_DCR_DONE)
                     or rctrl2cxreg_reset;
    
    ---------------------------------------------------------------------------
    -- Debug control register 2 (DCR2)
    ---------------------------------------------------------------------------
    -- 
    --       |-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|
    -- DCR2  |    Result     |               |t|m|r|   *   |e|T|M|R|   *   |E|
    --       |-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|
    --
    -- Result = scratch register, intended to be used for the return value of
    --          main() to indicate success or failure of a test program.
    --
    -- Trace control flags. The uppercase characters represent the current
    -- state, whereas the lowercase flags indicate the capabilities of the
    -- processor.
    -- 
    -- T/t    = Trace trap information.
    -- M/m    = Trace memory/control register operations.
    -- R/r    = Trace register writes.
    -- *      = Reserved bits for 
    -- E/e    = Trace enable.
    
    if CFG.traceEnable then
      
      -- Make the trace control flags.
      creg_makeNormalRegister(l2c, c2l, CR_DCR2, 7, 0,
        resetState    => X"00",
        permissions   => DEBUG_CAN_WRITE
      );
      
      -- Connect the control signals.
      cxreg2trace_enable  <= creg_readRegisterBit(l2c, c2l, CR_DCR2, CR_DCR2_TR_ENA);
      cxreg2trace_trapEn  <= creg_readRegisterBit(l2c, c2l, CR_DCR2, CR_DCR2_TR_TRAP);
      cxreg2trace_memEn   <= creg_readRegisterBit(l2c, c2l, CR_DCR2, CR_DCR2_TR_MEM);
      cxreg2trace_regEn   <= creg_readRegisterBit(l2c, c2l, CR_DCR2, CR_DCR2_TR_REG);
      
      -- Make the trace capability field.
      creg_makeHardwiredField(l2c, c2l, CR_DCR2, 15, 8, "11100001");
      
    end if;
    
    -- Make the result register.
    creg_makeNormalRegister(l2c, c2l, CR_DCR2, 31, 24,
      permissions   => READ_WRITE
    );
    
    ---------------------------------------------------------------------------
    -- Context reconfiguration request register (CRR)
    ---------------------------------------------------------------------------
    -- 
    --       |-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|
    -- CRR   |  CT7  |  CT6  |  CT5  |  CT4  |  CT3  |  CT2  |  CT1  |  CT0  |
    --       |-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|
    --
    -- The CT* fields specify which context should run on the indexed pipelane
    -- group. The value written should be within 0..2**CFG.numContextsLog2-1 OR
    -- it should be 8. When 8, a pipeline group is disabled. The value written
    -- to the field for nonexisting pipelane groups should be 0. When at least
    -- the LSB of the register is written by the processor (the debug bus can
    -- NOT write to this register, it has its own register in the global
    -- register file to request reconfiguration) a reconfiguration request is
    -- sent to the configuration control unit. If all goes well, the rvex will
    -- be reconfigured as requested. There are several rules which need to be
    -- followed for the new configuration to be accepted; there should be some
    -- more documentation on this subject elsewhere... If there isn't, look
    -- through the rvex_cfgCtrl.vhd and rvex_cfgCtrl_tb.vhd files.
    
    -- Set the write permissions on the CCR register.
    creg_makeNormalRegister(l2c, c2l, CR_CRR, 31, 0,
      permissions   => CORE_CAN_WRITE
    );
    
    -- Drive data.
    cxreg2cfg_requestData_r <= creg_readRegisterVect(l2c, c2l, CR_CRR, 31, 0);
    
    -- Drive requestEnable.
    cxreg2cfg_requestEnable <= creg_isBusWritingToBit(l2c, c2l, CR_CRR, 0);
    
    ---------------------------------------------------------------------------
    -- Performance counters (C_*)
    ---------------------------------------------------------------------------
    -- 
    --       |-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|
    -- C_CYC |                         cycle counter                         |
    --       |-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|
    -- C_STALL                         stall counter                         |
    --       |-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|
    -- C_BUN |                   committed bundle counter                    |
    --       |-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|
    -- C_SYL |                  committed syllable counter                   |
    --       |-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|
    -- C_NOP |                     committed NOP counter                     |
    --       |-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|
    --
    -- These registers will increment until they reach 0xFFFFFFFF when certain
    -- events occur. C_CYC will increment every cycle while idle is low.
    -- C_STALL does the same as C_CYC, but only when stall is high. Thus, their
    -- difference can be used to determine the number of active cycles. C_BUN
    -- counts the number of active cycles in which an instruction was
    -- committed, so C_CYC - C_STALL - C_BUN can be used to determine the
    -- number of cycles spent on pipeline flushing. C_SYL behaves almost
    -- exactly the same as C_BUN, but instead of being incremented with 1 every
    -- instruction, this is incremented by the number of syllables which were
    -- committed (which may be dependent on configuration). C_NOP does the same
    -- as C_SYL, but only counts NOP syllables.
    --
    -- When any of the counters are written to, they are reset to 0. The
    -- written value is ignored for all but bit 0 of C_CYC; when that bit is
    -- written 1, all counters are cleared simultaneously.
    
    -- Determine the reset-all-counter flag. We need to assert this while
    -- resetting as well, or ongoing counter updates will override the soft
    -- reset.
    countClear := creg_isBusWritingOneToBit(l2c, c2l, CR_C_CYC, 0)
               or creg_isBusWritingOneToBit(l2c, c2l, CR_DCR, CR_DCR_DONE) -- DCR reset bit
               or rctrl2cxreg_reset;
    
    -- Make the cycle counter.
    creg_makeCounter(l2c, c2l, CR_C_CYC, 31, 0,
      clear         => countClear,
      inc           => not cxplif2cxreg_idle_r,
      permissions   => READ_WRITE
    );
    
    -- Make the stall counter.
    creg_makeCounter(l2c, c2l, CR_C_STALL, 31, 0,
      clear         => countClear,
      inc           => cxplif2cxreg_stall_r and not cxplif2cxreg_idle_r,
      permissions   => READ_WRITE
    );
    
    -- Make the committed bundle counter.
    bundleCommit := '0';
    for i in cxplif2cxreg_sylCommit_r'range loop
      if cxplif2cxreg_sylCommit_r(i) = '1' then
        bundleCommit := '1';
      end if;
    end loop;
    creg_makeCounter(l2c, c2l, CR_C_BUN, 31, 0,
      clear         => countClear,
      inc           => bundleCommit,
      enable        => not cxplif2cxreg_stall_r,
      permissions   => READ_WRITE
    );
    
    -- Make the committed syllable counter.
    creg_makeCounter(l2c, c2l, CR_C_SYL, 31, 0,
      clear         => countClear,
      inc_vect      => cxplif2cxreg_sylCommit_r,
      enable        => not cxplif2cxreg_stall_r,
      permissions   => READ_WRITE
    );
    
    -- Make the committed NOP syllable counter.
    creg_makeCounter(l2c, c2l, CR_C_NOP, 31, 0,
      clear         => countClear,
      inc_vect      => cxplif2cxreg_sylCommit_r and cxplif2cxreg_sylNop_r,
      enable        => not cxplif2cxreg_stall_r,
      permissions   => READ_WRITE
    );
	 
    
    ---------------------------------------------------------------------------
    -- Scratch-pad registers (SCRP*)
    ---------------------------------------------------------------------------
    -- 
    --       |-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|
    -- SCRP  |                           scratch 1                           |
    --       |-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|
    -- SCRP2 |                           scratch 2                           |
    --       |-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|
    -- SCRP3 |                           scratch 3                           |
    --       |-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|
    -- SCRP4 |                           scratch 4                           |
    --       |-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|
    --
    -- Regular register with no effect on processor behavior.
    
    -- Make the registers.
    creg_makeNormalRegister(l2c, c2l, CR_SCRP, 31, 0,
      permissions   => READ_WRITE
    );
    
    creg_makeNormalRegister(l2c, c2l, CR_SCRP2, 31, 0,
      permissions   => READ_WRITE
    );
    
    creg_makeNormalRegister(l2c, c2l, CR_SCRP3, 31, 0,
      permissions   => READ_WRITE
    );
    
    creg_makeNormalRegister(l2c, c2l, CR_SCRP4, 31, 0,
      permissions   => READ_WRITE
    );
    
    ---------------------------------------------------------------------------
    -- Forward control signals
    ---------------------------------------------------------------------------
    cxreg2creg <= l2c;
    
  end process;
  
end Behavioral;

