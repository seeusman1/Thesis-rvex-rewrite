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
    
    -- Core indentifier within the platform. Should be added to the context ID
    -- fields.
    CORE_ID                     : natural
    
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
    -- Global control register address. Only bits 8..0 are used.
    creg2cxreg_addr             : in  rvex_address_array(2**CFG.numContextsLog2-1 downto 0);
    
    -- Origin of the context control register command. '0' for core access, '1'
    -- for debug access.
    creg2cxreg_origin           : in  std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
    
    -- Write command.
    creg2cxreg_writeEnable      : in  std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
    creg2cxreg_writeMask        : in  rvex_mask_array(2**CFG.numContextsLog2-1 downto 0);
    creg2cxreg_writeData        : in  rvex_data_array(2**CFG.numContextsLog2-1 downto 0);
    
    -- Read command and reply.
    creg2cxreg_readEnable       : in  std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
    cxreg2creg_readData         : out rvex_data_array(2**CFG.numContextsLog2-1 downto 0);
    
    ---------------------------------------------------------------------------
    -- Run control interface
    ---------------------------------------------------------------------------
    -- Active high context reset input. When high, the context control
    -- registers (including PC, done and break flag) will be reset.
    rctrl2cxreg_reset           : in  std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
    
    -- Reset vector. When the context or the entire core is reset, the PC
    -- register will be set to this value.
    rctrl2cxreg_resetVect       : in  rvex_address_array(2**CFG.numContextsLog2-1 downto 0);
    
    -- Active high done output. This is asserted when the context encounters
    -- a stop syllable. Processing a stop signal also sets the BRK control
    -- register, which stops the core. This bit can be reset by issuing a core
    -- reset or by means of the debug interface.
    cxreg2rctrl_done            : out std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
    
    ---------------------------------------------------------------------------
    -- Pipelane interface: misc.
    ---------------------------------------------------------------------------
    -- When high, the context registers must maintain their current value.
    cxplif2cxreg_stall          : in  std_logic_vector(2**CFG.numContextsLog2-1 downto 0);

    -- Idle flag, as reported to the external run control interface. Used for
    -- the performance counters.
    cxplif2cxreg_idle           : in  std_logic_vector(2**CFG.numContextsLog2-1 downto 0);

    -- Syllable committed flag for each lane, used for the performance
    -- counters.
    cxplif2cxreg_sylCommit      : in  rvex_sylStatus_array(2**CFG.numContextsLog2-1 downto 0);
    
    -- NOP flag for each lane with the same timing as sylCommit, used for the
    -- performance counters.
    cxplif2cxreg_sylNop         : in  rvex_sylStatus_array(2**CFG.numContextsLog2-1 downto 0);

    -- Stop flag. When high, the BRK and done flags in the debug control
    -- register should be set.
    cxplif2cxreg_stop           : in  std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
    
    ---------------------------------------------------------------------------
    -- Pipelane interface: branch/link registers
    ---------------------------------------------------------------------------
    -- Write data and enable signal for each branch register.
    cxplif2cxreg_brWriteData    : in  rvex_brRegData_array(2**CFG.numContextsLog2-1 downto 0);
    cxplif2cxreg_brWriteEnable  : in  rvex_brRegData_array(2**CFG.numContextsLog2-1 downto 0);
    
    -- Current state of the branch registers.
    cxreg2cxplif_brReadData     : out rvex_brRegData_array(2**CFG.numContextsLog2-1 downto 0);
    
    -- Write data and enable signal for the link register.
    cxplif2cxreg_linkWriteData  : in  rvex_data_array(2**CFG.numContextsLog2-1 downto 0);
    cxplif2cxreg_linkWriteEnable: in  std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
    
    -- Current state of the link register.
    cxreg2cxplif_linkReadData   : out rvex_data_array(2**CFG.numContextsLog2-1 downto 0);
    
    ---------------------------------------------------------------------------
    -- Pipelane interface: program counter
    ---------------------------------------------------------------------------
    -- Next value for the PC register. This is written when stall is low and
    -- overridePC is not asserted.
    cxplif2cxreg_nextPC         : in  rvex_address_array(2**CFG.numContextsLog2-1 downto 0);

    -- Current value of the PC register.
    cxreg2cxplif_currentPC      : out rvex_address_array(2**CFG.numContextsLog2-1 downto 0);

    -- The overridePC flag is set when the debug bus writes to the context
    -- registers or when the context or processor is reset. This is reset when
    -- overridePC_ack is asserted while stall is low. It indicates to the
    -- branch unit that it should inject a branch to the current PC register
    -- regardless of the current instruction or state.
    cxreg2cxplif_overridePC     : out std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
    cxplif2cxreg_overridePC_ack : in  std_logic_vector(2**CFG.numContextsLog2-1 downto 0);

    ---------------------------------------------------------------------------
    -- Pipelane interface: trap handling
    ---------------------------------------------------------------------------
    -- Current trap handler. When the application has marked that it is not
    -- currently capable of accepting a trap, this is set to the panic handler
    -- register instead.
    cxreg2cxplif_trapHandler    : out rvex_address_array(2**CFG.numContextsLog2-1 downto 0);

    -- Regular trap information. When the trap in trapInfo is active, the trap
    -- information should be stored in the trap cause/arg registers. In
    -- addition, the register hardware should save the current value of the
    -- control register and should clear the ready-for-trap and interrupt-
    -- enable bits, as well as the debug-trap-enable bit if the trap cause maps
    -- to a debug trap.
    cxplif2cxreg_trapInfo       : in  trap_info_array(2**CFG.numContextsLog2-1 downto 0);
    cxplif2cxreg_trapPoint      : in  rvex_address_array(2**CFG.numContextsLog2-1 downto 0);

    -- Connected to the current value of the trap point register. Used by the
    -- branch unit as the return address for the RFI instruction.
    cxreg2cxplif_trapReturn     : out rvex_address_array(2**CFG.numContextsLog2-1 downto 0);

    -- RFI flag. When high, the saved control register value should be restored
    -- and the trap cause field should be set to 0.
    cxplif2cxreg_rfi            : in  std_logic_vector(2**CFG.numContextsLog2-1 downto 0);

    -- Set when the current value of the trap cause register maps to a debug
    -- trap. This is used by the branch unit to disable breakpoints for the
    -- first instruction executed after the debug trap returns.
    cxreg2cxplif_handlingDebugTrap:out std_logic_vector(2**CFG.numContextsLog2-1 downto 0);

    -- Current value of the interrupt-enable flag in the control register.
    cxreg2cxplif_interruptEnable: out std_logic_vector(2**CFG.numContextsLog2-1 downto 0);

    -- Current value of the debug-trap-enable flag in the control register.
    cxreg2cxplif_debugTrapEnable: out std_logic_vector(2**CFG.numContextsLog2-1 downto 0);

    -- Current hardware breakpoint configuration.
    cxreg2cxplif_breakpoints    : out cxreg2pl_breakpoint_info_array(2**CFG.numContextsLog2-1 downto 0);

    ---------------------------------------------------------------------------
    -- Pipelane interface: external debug control signals
    ---------------------------------------------------------------------------
    -- Whether debug traps are to be handled normally or by halting execution
    -- for debugging through the external bebug bus.
    cxreg2cxplif_extDebug       : out std_logic_vector(2**CFG.numContextsLog2-1 downto 0);

    -- External debug trap information. When the trap in exDbgTrapInfo is
    -- active, the trap cause should be stored in the debug control register
    -- and the BRK flag in the debug control register should be set.
    cxplif2cxreg_exDbgTrapInfo  : in  trap_info_array(2**CFG.numContextsLog2-1 downto 0);

    -- BRK flag from the debug control register. When high, the core should
    -- be halted.
    cxreg2cxplif_brk            : out std_logic_vector(2**CFG.numContextsLog2-1 downto 0);

    -- Stepping mode flag from the debug control register. When high,
    -- executing any instruction which has the brkValid flag set should cause
    -- a step trap.
    cxreg2cxplif_stepping       : out std_logic_vector(2**CFG.numContextsLog2-1 downto 0);

    -- Resuming flag. This is set when the BRK flag is cleared by the debug
    -- bus. It is cleared when the resumed bit is high while stall is low.
    -- While high, issued instructions should have the brkValid flag cleared,
    -- so breakpoints and step traps are ignored.
    cxreg2cxplif_resuming       : out std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
    cxplif2cxreg_resuming_ack   : in  std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
    
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
    cxreg2cfg_requestData_r     : out rvex_data_array(2**CFG.numContextsLog2-1 downto 0);
    cxreg2cfg_requestEnable     : out std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
    
    ---------------------------------------------------------------------------
    -- Trace control unit interface
    ---------------------------------------------------------------------------
    -- Whether tracing should be enabled or not for each context. Active high.
    cxreg2trace_enable          : out std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
    
    -- Whether trap information should be traced. Active high.
    cxreg2trace_trapEn          : out std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
    
    -- Whether memory operations should be traced. Active high.
    cxreg2trace_memEn           : out std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
    
    -- Whether register writes should be traced. Active high.
    cxreg2trace_regEn           : out std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
    
    -- Whether cache performance information should be traced. Active high.
    cxreg2trace_cacheEn         : out std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
    
    -- Whether instructions (the raw syllables) should be traced. Active high.
    cxreg2trace_instrEn         : out std_logic_vector(2**CFG.numContextsLog2-1 downto 0)
    
  );
end core_contextRegLogic;

--=============================================================================
architecture Behavioral of core_contextRegLogic is
--=============================================================================
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  
end Behavioral;

