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

-- 6. r-VEX was developed by Stephan Wong, Thijs van As, Fakhar Anjam,
-- Roel Seedorf, Anthony Brandon, Jeroen van Straten. r-VEX is currently
-- maintained by TU Delft (J.S.S.M.Wong@tudelft.nl).

-- Copyright (C) 2008-2014 by TU Delft.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

library rvex;
use rvex.common_pkg.all;
use rvex.core_pkg.all;

--=============================================================================
-- This is the toplevel for a "standalone" rvex core. A standalone core has
-- its own local instruction memory and data memory. It has one slave bus
-- interface, which may be used to access the instruction memory, data memory
-- and debug interface of the core. It also has one master bus interface, which
-- the core will access when it does a memory operation which is out of the
-- range of the local memory.
-------------------------------------------------------------------------------
entity standalone is
--=============================================================================
  generic (
    
    -- Depth of the instruction memory, represented as the log2 of the number
    -- of bytes.
    IMEM_DEPTH_LOG2B            : positive := 14;
    
    -- Depth of the instruction memory, represented as the log2 of the number
    -- of bytes.
    DMEM_DEPTH_LOG2B            : positive := 14;
    
    -- rvex core configuration.
    CORE_CFG                    : rvex_generic_config_type := RVEX_DEFAULT_CONFIG
    
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
    rctrl2rvsa_irq              : in  std_logic_vector(2**CORE_CFG.numContextsLog2-1 downto 0) := (others => '0');
    
    -- External interrupt identification. Guaranteed to be loaded in the trap
    -- argument register in the same clkEn'd cycle where irqAck is high.
    rctrl2rvsa_irqID            : in  rvex_address_array(2**CORE_CFG.numContextsLog2-1 downto 0) := (others => (others => '0'));
    
    -- External interrupt acknowledge signal, active high. Goes high for one
    -- clkEn'abled cycle.
    rvsa2rctrl_irqAck           : out std_logic_vector(2**CORE_CFG.numContextsLog2-1 downto 0);
    
    -- Active high run signal. When released, the context will stop running as
    -- soon as possible.
    rctrl2rvsa_run              : in  std_logic_vector(2**CORE_CFG.numContextsLog2-1 downto 0) := (others => '1');
    
    -- Active high idle output. This is asserted when the core is no longer
    -- doing anything.
    rvsa2rctrl_idle             : out std_logic_vector(2**CORE_CFG.numContextsLog2-1 downto 0);
    
    -- Active high context reset input. When high, the context control
    -- registers (including PC, done and break flag) will be reset.
    rctrl2rvsa_reset            : in  std_logic_vector(2**CORE_CFG.numContextsLog2-1 downto 0) := (others => '0');
    
    -- Active high done output. This is asserted when the context encounters
    -- a stop syllable. Processing a stop signal also sets the BRK control
    -- register, which stops the core. This bit can be reset by issuing a core
    -- reset or by means of the debug interface.
    rvsa2rctrl_done             : out std_logic_vector(2**CORE_CFG.numContextsLog2-1 downto 0);
    
    ---------------------------------------------------------------------------
    -- Bus interfaces
    ---------------------------------------------------------------------------
    -- Slave bus interface. This bus can access the local memories and the
    -- debug interface of the core. While the busy signal is high, it is
    -- illegal to change the state of the request signals, and the read data
    -- is invalid.
    bus2rvsa_address            : in  std_logic_vector(31 downto 0);
    bus2rvsa_writeEnable        : in  std_logic;
    bus2rvsa_writeMask          : in  std_logic_vector(3 downto 0);
    bus2rvsa_writeData          : in  std_logic_vector(31 downto 0);
    bus2rvsa_readEnable         : in  std_logic;
    rvsa2bus_readData           : out std_logic_vector(31 downto 0);
    rvsa2bus_busy               : out std_logic;
    
    -- Master bus interface, controlled by the rvex core. May be used for
    -- peripheral access.
    rvsa2per_address            : out std_logic_vector(31 downto 0);
    rvsa2per_writeEnable        : out std_logic;
    rvsa2per_writeMask          : out std_logic_vector(3 downto 0);
    rvsa2per_writeData          : out std_logic_vector(31 downto 0);
    rvsa2per_readEnable         : out std_logic;
    per2rvsa_readData           : in  std_logic_vector(31 downto 0);
    per2rvsa_busy               : in  std_logic
    
  );
end standalone;

--=============================================================================
architecture Behavioral of standalone is
--=============================================================================
  
  -- Generate the configuration for the core. We override unifiedStall here
  -- because we require that it is set to 1.
  constant CFG                  : rvex_generic_config_type := rvex_cfg(
    base                        => CORE_CFG,
    unifiedStall                => 1
  );
  
  -- Common memory interface.
  signal mem2rv_stallIn         : std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
  signal rv2mem_stallOut        : std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
  
  -- Instruction memory interface.
  signal rv2imem_PCs            : rvex_address_array(2**CFG.numLaneGroupsLog2-1 downto 0);
  signal rv2imem_fetch          : std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
  signal imem2rv_instr          : rvex_syllable_array(2**CFG.numLanesLog2-1 downto 0);
  
  -- Data memory interface.
  signal rv2dmem_addr           : rvex_address_array(2**CFG.numLaneGroupsLog2-1 downto 0);
  signal rv2dmem_writeEnable    : std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
  signal rv2dmem_writeMask      : rvex_mask_array(2**CFG.numLaneGroupsLog2-1 downto 0);
  signal rv2dmem_writeData      : rvex_data_array(2**CFG.numLaneGroupsLog2-1 downto 0);
  signal rv2dmem_readEnable     : std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
  signal dmem2rv_readData       : rvex_data_array(2**CFG.numLaneGroupsLog2-1 downto 0);
  
  -- Control/debug bus interface.
  signal dbg2rv_addr            : rvex_address_type;
  signal dbg2rv_readEnable      : std_logic;
  signal dbg2rv_writeEnable     : std_logic;
  signal dbg2rv_writeMask       : rvex_mask_type;
  signal dbg2rv_writeData       : rvex_data_type;
  signal rv2dbg_readData        : rvex_data_type;
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- Check configuration
  -----------------------------------------------------------------------------
  assert CORE_CFG.unifiedStall
    report "The standalone memory system requires that the unifiedStall "
         & "configuration signal is set to true. The value from the requested "
         & "configuration vector has been overridden."
    severity warning;
  
  -----------------------------------------------------------------------------
  -- Instantiate the rvex core
  -----------------------------------------------------------------------------
  core: entity rvex.core
    generic map (
      CFG                       => CFG
    )
    port map (
      
      -- System control.
      reset                     => reset,
      clk                       => clk,
      clkEn                     => clkEn,
      
      -- Run control interface.
      rctrl2rv_irq              => rctrl2rvsa_irq,
      rctrl2rv_irqID            => rctrl2rvsa_irqID,
      rv2rctrl_irqAck           => rvsa2rctrl_irqAck,
      rctrl2rv_run              => rctrl2rvsa_run,
      rv2rctrl_idle             => rvsa2rctrl_idle,
      rctrl2rv_reset            => rctrl2rvsa_reset,
      rv2rctrl_done             => rvsa2rctrl_done,
      
      -- Common memory interface.
      mem2rv_stallIn            => mem2rv_stallIn,
      rv2mem_stallOut           => rv2mem_stallOut,
      
      -- Instruction memory interface.
      rv2imem_PCs               => rv2imem_PCs,
      rv2imem_fetch             => rv2imem_fetch,
      imem2rv_instr             => imem2rv_instr,
      
      -- Data memory interface.
      rv2dmem_addr              => rv2dmem_addr,
      rv2dmem_writeEnable       => rv2dmem_writeEnable,
      rv2dmem_writeMask         => rv2dmem_writeMask,
      rv2dmem_writeData         => rv2dmem_writeData,
      rv2dmem_readEnable        => rv2dmem_readEnable,
      dmem2rv_readData          => dmem2rv_readData,
      
      -- Control/debug bus interface.
      dbg2rv_addr               => dbg2rv_addr,
      dbg2rv_readEnable         => dbg2rv_readEnable,
      dbg2rv_writeEnable        => dbg2rv_writeEnable,
      dbg2rv_writeMask          => dbg2rv_writeMask,
      dbg2rv_writeData          => dbg2rv_writeData,
      rv2dbg_readData           => rv2dbg_readData
      
    );
  
end Behavioral;

