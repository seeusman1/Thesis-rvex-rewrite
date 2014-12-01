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

--=============================================================================
-- This entity contains the control registers as accessed from the debug bus
-- or by the core. This is setup in a very generic way to make it easy to add,
-- remove or change registers or mappings; see rvex_ctrlRegs_pkg.vhd. The only
-- restrictions to the map are the following.
--  - The total size is 64 words or 256 bytes.
--  - The upper half of the memory is mapped to general purpose register file
--    access for debugging.
--  - The first part of the lower half of the memory is common to all cores.
--    Only the bus may write to these registers, the cores can only read.
--  - While the control registers support halfword/byte accesses, the general
--    purpose register file does not. Sub-word writes are ignored there.
-------------------------------------------------------------------------------
entity rvex_ctrlRegs is
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
    
    -- Active high stall signals from each context/core.
    stallIn                     : in  std_logic_vector(CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Active high stall signals to each context/core, active when a debug bus
    -- access is in progress.
    stallOut                    : out std_logic_vector(CFG.numLaneGroupsLog2-1 downto 0);
    
    -----------------------------------------------------------------------------
    -- Decoded configuration signals
    -----------------------------------------------------------------------------
    -- Specifies the context associated with the indexed pipelane group.
    cfg2any_context             : in  rvex_3bit_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Last pipelane group associated with each context.
    cfg2any_lastGroupForCtxt    : in  rvex_3bit_array(2**CFG.numContextsLog2-1 downto 0);
    
    ---------------------------------------------------------------------------
    -- Core bus interfaces
    ---------------------------------------------------------------------------
    -- Control register address from memory unit, shared between read and write
    -- command. Only bit 6..0 are used.
    dmsw2creg_addr              : out rvex_address_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Control register write command from memory unit.
    dmsw2creg_writeEnable       : out std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    dmsw2creg_writeMask         : out rvex_mask_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    dmsw2creg_writeData         : out rvex_data_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Control register read command and result from and to memory unit.
    dmsw2creg_readEnable        : out std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    creg2dmsw_readData          : in  rvex_data_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    ---------------------------------------------------------------------------
    -- Debug bus interface
    ---------------------------------------------------------------------------
    -- Control register address from debug bus, shared between read and write
    -- command. Only bit 7..0 are used.
    dbg2creg_addr                 : in  rvex_address_type;
    
    -- Control register write command from debug bus.
    dbg2creg_writeEnable          : in  std_logic;
    dbg2creg_writeMask            : in  rvex_mask_type;
    dbg2creg_writeData            : in  rvex_data_type;
    
    -- Control register read command and result from and to debug bus.
    dbg2creg_readEnable           : in  std_logic;
    creg2dbg_readData             : out rvex_data_type;
    
    ---------------------------------------------------------------------------
    -- General purpose register file interface
    ---------------------------------------------------------------------------
    -- This should be connected to one of the general purpose register file
    -- read and write ports when creg2gpreg_claim is high. This unit will
    -- ensure that everything is stalled when this signal is asserted. It will
    -- keep stall high one cycle longer than claim, so any interrupted read
    -- commands will be issued again, so claiming the bus does not affect the
    -- core.
    
    -- When high, connect the bus to the general purpose register file.
    creg2gpreg_claim            : out std_logic;
    
    -- Register address and context.
    creg2gpreg_addr             : out rvex_gpRegAddr_type;
    creg2gpreg_ctxt             : out std_logic_vector(CFG.numContextsLog2-1 downto 0);
    
    -- Write command.
    creg2gpreg_writeEnable      : out std_logic;
    creg2gpreg_writeData        : out rvex_data_type;
    
    -- Read data returned one cycle after the claim.
    gpreg2creg_readData         : in  rvex_data_type;
    
    ---------------------------------------------------------------------------
    -- Global register logic interface
    ---------------------------------------------------------------------------
    -- Interface for the global register logic.
    gbreg2creg                  : in  gbreg2creg_type;
    creg2gbreg                  : out creg2gbreg_type;
    
    -- Context selection for the debug bus.
    gbreg2creg_context          : in  std_logic_vector(CFG.numContextsLog2-1 downto 0);
    
    -- Bank selection bit for general purpose register access from the debug
    -- bus.
    gbreg2creg_gpregBank        : in  std_logic;
    
    ---------------------------------------------------------------------------
    -- Context register logic interface
    ---------------------------------------------------------------------------
    -- Interface for the context register logic.
    cxreg2creg                  : in  cxreg2creg_array(2**CFG.numContextsLog2-1 downto 0);
    creg2cxreg                  : out creg2cxreg_array(2**CFG.numContextsLog2-1 downto 0)
    
  );
end rvex_ctrlRegs;

--=============================================================================
architecture Behavioral of rvex_ctrlRegs is
--=============================================================================
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  assert CTRL_REG_TOTAL_WORDS = 64 and CTRL_REG_SIZE_BLOG2 = 7
    report "Size of the control register file is hardcoded to 64 words in the "
         & "control register code, but configuration specifies otherwise."
    severity failure;
  
  assert CTRL_REG_GLOB_WORDS <= CTRL_REG_TOTAL_WORDS
    report "Cannot have more words in the global portion of the control "
         & "registers than there are in the whole file."
    severity failure;
  
end Behavioral;

