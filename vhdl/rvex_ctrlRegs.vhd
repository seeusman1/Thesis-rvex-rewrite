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
use work.rvex_utils_pkg.all;
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
    stallIn                     : in  std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Active high stall signals to each context/core, active when a debug bus
    -- access is in progress.
    stallOut                    : out std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -----------------------------------------------------------------------------
    -- Decoded configuration signals
    -----------------------------------------------------------------------------
    -- Specifies the context associated with the indexed pipelane group.
    cfg2any_context             : in  rvex_3bit_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    ---------------------------------------------------------------------------
    -- Core bus interfaces
    ---------------------------------------------------------------------------
    -- Control register address from memory unit, shared between read and write
    -- command. Only bit 6..0 are used.
    dmsw2creg_addr              : in  rvex_address_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Control register write command from memory unit.
    dmsw2creg_writeEnable       : in  std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    dmsw2creg_writeMask         : in  rvex_mask_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    dmsw2creg_writeData         : in  rvex_data_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Control register read command and result from and to memory unit.
    dmsw2creg_readEnable        : in  std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    creg2dmsw_readData          : out rvex_data_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    ---------------------------------------------------------------------------
    -- Debug bus interface
    ---------------------------------------------------------------------------
    -- Control register address from debug bus, shared between read and write
    -- command. Only bit 7..0 are used.
    dbg2creg_addr               : in  rvex_address_type;
    
    -- Control register write command from debug bus.
    dbg2creg_writeEnable        : in  std_logic;
    dbg2creg_writeMask          : in  rvex_mask_type;
    dbg2creg_writeData          : in  rvex_data_type;
    
    -- Control register read command and result from and to debug bus.
    dbg2creg_readEnable         : in  std_logic;
    creg2dbg_readData           : out rvex_data_type;
    
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
    creg2cxreg                  : out creg2cxreg_array(2**CFG.numContextsLog2-1 downto 0);
    
    -- Resets the context control register file. Hardware and bus writes going
    -- on in the same cycle take precedence, allowing the context to reset
    -- directly into debug mode.
    cxreg2creg_reset            : in  std_logic_vector(2**CFG.numContextsLog2-1 downto 0)
    
  );
end rvex_ctrlRegs;

--=============================================================================
architecture Behavioral of rvex_ctrlRegs is
--=============================================================================
  -- 
  -- This architecture has the following bus logic.
  -- 
  -- . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
  --
  --                    .----o----o----o------.
  --                    v    v    v    v      |
  --                  .---..---..---..---. .-----.
  --                  |rpt||rpt||rpt||rpt| |glob.|
  --                  '---''---''---''---' '-----'
  --                    ^    ^    ^    ^      ^
  --                    |    |    |    |      |
  --                    |    |    |    |      v
  --                    |    |    |    |    .-S-.
  --       debug <------+----+----+----+--->M x S<---> gpreg
  --                    |    |    |    |    '-S-'
  --                    v    |    |    |      |
  --                  .-S-.  |    |    |    .-M-.     .----.     .------.
  --      memu 0 <--->M x S<-+----+----+----M m S<--->|    |<--->|ctxt 0|
  --                  '---'  v    |    |    '---'     |    |     '------'
  --                       .-S-.  |    |              |    |     .------.
  --      memu 1 <-------->M x S<-+----+------------->|    |<--->|ctxt 1|
  --                       '---'  |    |              |ctxt|     '------'
  --                            .-S-.  |              | sw.|     .------.
  --      memu 2 <------------->M x s<-+------------->|    |<--->|ctxt 2|
  --                            '---'  |              |    |     '------'
  --                                 .-S-.            |    |     .------.
  --      memu 3 <------------------>M x s<---------->|    |<--->|ctxt 3|
  --                                 '---'            '----'     '------'
  --
  -- . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
  --
  -- x        = rvex_ctrlRegs_busSwitch; the master bus port is marked with an
  --            M, the slave bus ports are marked with an S.
  --
  -- m        = Bus claiming logic in rvex_ctrlRegs.
  --
  -- ctxt sw. = Selection between contexts for each memory bus.
  --
  -- glob     = rvex_ctrlRegs_bank for global registers (common to all cores).
  --
  -- rpt      = rvex_ctrlRegs_readPort; extra read ports for the global
  --            registers, so they can be accessed simultaneously.
  --
  -- ctxt i   = rvex_ctrlRegs_bank with the context-specific registers for
  --            context i.
  --
  
  -- Busses between the global register read ports and the lane groups (through
  -- a bus switch). The *_nc signals are not used, because the contexts cannot
  -- write to the global registers.
  signal grpBus_glob_addr           : rvex_address_array(2**CFG.numLaneGroupsLog2-1 downto 0);
  signal grpBus_glob_addr_raw       : rvex_address_array(2**CFG.numLaneGroupsLog2-1 downto 0);
  signal grpBus_glob_writeEnable_nc : std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
  signal grpBus_glob_writeMask_nc   : rvex_mask_array(2**CFG.numLaneGroupsLog2-1 downto 0);
  signal grpBus_glob_writeData_nc   : rvex_data_array(2**CFG.numLaneGroupsLog2-1 downto 0);
  signal grpBus_glob_readEnable     : std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
  signal grpBus_glob_readData       : rvex_data_array(2**CFG.numLaneGroupsLog2-1 downto 0);
  
  -- Busses between the context bus switching logic and the lane groups
  -- (through a bus switch). Address bits 6..0 are from the memory unit of the
  -- lane group, bits 9..7 are set to the current context.
  signal grpBus_ctxt_addr           : rvex_address_array(2**CFG.numLaneGroupsLog2-1 downto 0);
  signal grpBus_ctxt_addr_raw       : rvex_address_array(2**CFG.numLaneGroupsLog2-1 downto 0);
  signal grpBus_ctxt_writeEnable    : std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
  signal grpBus_ctxt_writeMask      : rvex_mask_array(2**CFG.numLaneGroupsLog2-1 downto 0);
  signal grpBus_ctxt_writeData      : rvex_data_array(2**CFG.numLaneGroupsLog2-1 downto 0);
  signal grpBus_ctxt_readEnable     : std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
  signal grpBus_ctxt_readData       : rvex_data_array(2**CFG.numLaneGroupsLog2-1 downto 0);
  
  -- Busses between the debug bus and the global registers.
  signal dbgBus_glob_addr           : rvex_address_type;
  signal dbgBus_glob_addr_raw       : rvex_address_type;
  signal dbgBus_glob_writeEnable    : std_logic;
  signal dbgBus_glob_writeMask      : rvex_mask_type;
  signal dbgBus_glob_writeData      : rvex_data_type;
  signal dbgBus_glob_readEnable     : std_logic;
  signal dbgBus_glob_readData       : rvex_data_type;
  
  -- Busses between the debug bus and the context switching logic. Address bits
  -- 6..0 are from the debug bus address, bits 9..7 are from the debug bus
  -- context bank input.
  signal dbgBus_ctxt_addr           : rvex_address_type;
  signal dbgBus_ctxt_addr_raw       : rvex_address_type;
  signal dbgBus_ctxt_writeEnable    : std_logic;
  signal dbgBus_ctxt_writeMask      : rvex_mask_type;
  signal dbgBus_ctxt_writeData      : rvex_data_type;
  signal dbgBus_ctxt_readEnable     : std_logic;
  signal dbgBus_ctxt_readData       : rvex_data_type;
  
  -- Busses between the debug bus and the general purpose register file.
  -- Address bits 6..0 are taken from the debug bus address, bit 7 is connected
  -- to the general purpose register bank selection input, and bit 10..8 are
  -- connected to the debug bus context bank input.
  signal dbgBus_gpreg_addr          : rvex_address_type;
  signal dbgBus_gpreg_addr_raw      : rvex_address_type;
  signal dbgBus_gpreg_writeEnable   : std_logic;
  signal dbgBus_gpreg_writeMask     : rvex_mask_type;
  signal dbgBus_gpreg_writeData     : rvex_data_type;
  signal dbgBus_gpreg_readEnable    : std_logic;
  signal dbgBus_gpreg_readData      : rvex_data_type;
  
  -- Debug bus claim signal. When high, the debug bus takes control of the
  -- busses for lane group 0 in order to make use of the existing bus logic
  -- there. While this is going on, the processor is stalled.
  signal dbg_claim                  : std_logic;
  
  -- Claim signal, delayed by one cycle. This also stalls the processor when
  -- high, so any interrupted read requests are re-issued before core
  -- operation is resumed.
  signal dbg_claim_r                : std_logic;
  
  -- Busses between the context bus switching logic and the lane groups, with
  -- potential override from the debug bus (only for group 0, the rest is just
  -- hardwired together). Address bits 6..0 are from the memory unit of the
  -- lane group or the debug bus, bits 9..7 are set to the current context.
  signal grpDbgBus_ctxt_addr        : rvex_address_array(2**CFG.numLaneGroupsLog2-1 downto 0);
  signal grpDbgBus_ctxt_writeEnable : std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
  signal grpDbgBus_ctxt_writeMask   : rvex_mask_array(2**CFG.numLaneGroupsLog2-1 downto 0);
  signal grpDbgBus_ctxt_writeData   : rvex_data_array(2**CFG.numLaneGroupsLog2-1 downto 0);
  signal grpDbgBus_ctxt_readEnable  : std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
  signal grpDbgBus_ctxt_readData    : rvex_data_array(2**CFG.numLaneGroupsLog2-1 downto 0);
  
  -- Busses between the context bus switching logic and the registers. Only
  -- address bits 6..0 are used.
  signal ctxtBus_addr               : rvex_address_array(2**CFG.numContextsLog2-1 downto 0);
  signal ctxtBus_writeEnable        : std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
  signal ctxtBus_writeMask          : rvex_mask_array(2**CFG.numContextsLog2-1 downto 0);
  signal ctxtBus_writeData          : rvex_data_array(2**CFG.numContextsLog2-1 downto 0);
  signal ctxtBus_readEnable         : std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
  signal ctxtBus_readData           : rvex_data_array(2**CFG.numContextsLog2-1 downto 0);
  
  -- Local copy of the global register signal from registers to control logic,
  -- which we need to instantiate the extra read ports.
  signal creg2gbreg_s               : creg2gbreg_type;
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- Check configuration
  -----------------------------------------------------------------------------
  assert CTRL_REG_TOTAL_WORDS = 32 and CTRL_REG_SIZE_BLOG2 = 7
    report "Size of the control register file is hardcoded to 32 words (not "
         & "counting gp. reg access) in the control register code, but "
         & "configuration specifies otherwise."
    severity failure;
  
  assert CTRL_REG_GLOB_WORDS <= CTRL_REG_TOTAL_WORDS
    report "Cannot have more words in the global portion of the control "
         & "registers than there are in the whole file."
    severity failure;
  
  -----------------------------------------------------------------------------
  -- Generate global/context/gpreg bus switch logic
  -----------------------------------------------------------------------------
  -- Instantiate the bus switches selecting between global and context
  -- specific registers for the busses from the cores, and append the context
  -- to the address.
  glob_ctxt_bus_switch_gen: for laneGroup in 2**CFG.numLaneGroupsLog2-1 downto 0 generate
    glob_ctxt_bus_switch_inst: entity work.rvex_ctrlRegs_busSwitch
      generic map (
        NUM_SLAVES                    => 2,
        BOUNDARIES                    => (
          1 => uint2vect(CTRL_REG_GLOB_WORDS * 4, 32),
          others => (others => RVEX_UNDEF)
        ),
        BOUND_MASK                    => X"0000007F"
      )
      port map (
        
        -- System control.
        reset                         => reset,
        clk                           => clk,
        clkEn                         => clkEn,
        
        -- Master bus.
        mstr2sw_addr                  => dmsw2creg_addr(laneGroup),
        mstr2sw_writeEnable           => dmsw2creg_writeEnable(laneGroup),
        mstr2sw_writeMask             => dmsw2creg_writeMask(laneGroup),
        mstr2sw_writeData             => dmsw2creg_writeData(laneGroup),
        mstr2sw_readEnable            => dmsw2creg_readEnable(laneGroup),
        sw2mstr_readData              => creg2dmsw_readData(laneGroup),
        mstr2sw_stall                 => stallIn(laneGroup),
        
        -- Slave busses.
        sw2slave_addr(0)              => grpBus_glob_addr_raw(laneGroup),
        sw2slave_addr(1)              => grpBus_ctxt_addr_raw(laneGroup),
        sw2slave_writeEnable(0)       => grpBus_glob_writeEnable_nc(laneGroup),
        sw2slave_writeEnable(1)       => grpBus_ctxt_writeEnable(laneGroup),
        sw2slave_writeMask(0)         => grpBus_glob_writeMask_nc(laneGroup),
        sw2slave_writeMask(1)         => grpBus_ctxt_writeMask(laneGroup),
        sw2slave_writeData(0)         => grpBus_glob_writeData_nc(laneGroup),
        sw2slave_writeData(1)         => grpBus_ctxt_writeData(laneGroup),
        sw2slave_readEnable(0)        => grpBus_glob_readEnable(laneGroup),
        sw2slave_readEnable(1)        => grpBus_ctxt_readEnable(laneGroup),
        slave2sw_readData(0)          => grpBus_glob_readData(laneGroup),
        slave2sw_readData(1)          => grpBus_ctxt_readData(laneGroup)
        
      );
    
    -- Compile the different parts of the slave addresses.
    grpBus_glob_addr(laneGroup)(6 downto 0)   <= grpBus_glob_addr_raw(laneGroup)(6 downto 0);
    grpBus_glob_addr(laneGroup)(31 downto 7)  <= (others => '0');
    grpBus_ctxt_addr(laneGroup)(6 downto 0)   <= grpBus_ctxt_addr_raw(laneGroup)(6 downto 0);
    grpBus_ctxt_addr(laneGroup)(9 downto 7)   <= cfg2any_context(laneGroup);
    grpBus_ctxt_addr(laneGroup)(31 downto 10) <= (others => '0');
    
  end generate;
  
  -- Instantiate the bus switch for the debug bus.
  debug_bus_switch_inst: entity work.rvex_ctrlRegs_busSwitch
    generic map (
      NUM_SLAVES                    => 3,
      BOUNDARIES                    => (
        1 => uint2vect(CTRL_REG_GLOB_WORDS * 4, 32),
        2 => X"00000080",
        others => (others => RVEX_UNDEF)
      ),
      BOUND_MASK                    => X"000000FF"
    )
    port map (
      
      -- System control.
      reset                         => reset,
      clk                           => clk,
      clkEn                         => clkEn,
      
      -- Master bus.
      mstr2sw_addr                  => dbg2creg_addr,
      mstr2sw_writeEnable           => dbg2creg_writeEnable,
      mstr2sw_writeMask             => dbg2creg_writeMask,
      mstr2sw_writeData             => dbg2creg_writeData,
      mstr2sw_readEnable            => dbg2creg_readEnable,
      sw2mstr_readData              => creg2dbg_readData,
      mstr2sw_stall                 => '0',
      
      -- Slave busses.
      sw2slave_addr(0)              => dbgBus_glob_addr_raw,
      sw2slave_addr(1)              => dbgBus_ctxt_addr_raw,
      sw2slave_addr(2)              => dbgBus_gpreg_addr_raw,
      sw2slave_writeEnable(0)       => dbgBus_glob_writeEnable,
      sw2slave_writeEnable(1)       => dbgBus_ctxt_writeEnable,
      sw2slave_writeEnable(2)       => dbgBus_gpreg_writeEnable,
      sw2slave_writeMask(0)         => dbgBus_glob_writeMask,
      sw2slave_writeMask(1)         => dbgBus_ctxt_writeMask,
      sw2slave_writeMask(2)         => dbgBus_gpreg_writeMask,
      sw2slave_writeData(0)         => dbgBus_glob_writeData,
      sw2slave_writeData(1)         => dbgBus_ctxt_writeData,
      sw2slave_writeData(2)         => dbgBus_gpreg_writeData,
      sw2slave_readEnable(0)        => dbgBus_glob_readEnable,
      sw2slave_readEnable(1)        => dbgBus_ctxt_readEnable,
      sw2slave_readEnable(2)        => dbgBus_gpreg_readEnable,
      slave2sw_readData(0)          => dbgBus_glob_readData,
      slave2sw_readData(1)          => dbgBus_ctxt_readData,
      slave2sw_readData(2)          => dbgBus_gpreg_readData
      
    );
  
  -- Connect the rest of the address bits.
  dbgBus_glob_addr(6 downto 0) <= dbgBus_glob_addr_raw(6 downto 0);
  dbgBus_glob_addr(31 downto 7) <= (others => '0');
  dbgBus_ctxt_addr(6 downto 0) <= dbgBus_ctxt_addr_raw(6 downto 0);
  dbgBus_ctxt_addr(7+CFG.numContextsLog2-1 downto 7) <= gbreg2creg_context;
  dbgBus_ctxt_addr(31 downto 7+CFG.numContextsLog2) <= (others => '0');
  dbgBus_gpreg_addr(6 downto 0) <= dbgBus_gpreg_addr_raw(6 downto 0);
  dbgBus_gpreg_addr(7) <= gbreg2creg_gpregBank;
  dbgBus_gpreg_addr(8+CFG.numContextsLog2-1 downto 8) <= gbreg2creg_context;
  dbgBus_gpreg_addr(31 downto 8+CFG.numContextsLog2) <= (others => '0');
  
  -----------------------------------------------------------------------------
  -- Instantiate the global control registers
  -----------------------------------------------------------------------------
  global_reg_bank: entity work.rvex_ctrlRegs_bank
    generic map (
      OFFSET                    => 0,
      NUM_WORDS                 => CTRL_REG_GLOB_WORDS
    )
    port map (
      
      -- System control.
      reset                     => reset,
      clk                       => clk,
      clkEn                     => clkEn,
      
      -- Bus interface.
      addr                      => dbgBus_glob_addr,
      origin                    => '1', -- Debug bus access.
      writeEnable               => dbgBus_glob_writeEnable,
      writeMask                 => dbgBus_glob_writeMask,
      writeData                 => dbgBus_glob_writeData,
      readEnable                => dbgBus_glob_readEnable,
      readData                  => dbgBus_glob_readData,
      
      -- Hardware interface.
      logic2creg                => gbreg2creg,
      creg2logic                => creg2gbreg_s,
      logic2creg_reset          => '0'
      
    );
  
  -- Forward the local hardware output to the global control register logic.
  creg2gbreg <= creg2gbreg_s;
  
  -- Instantiate the extra read ports for each lane group/memory unit.
  global_reg_bank_port_gen: for laneGroup in 2**CFG.numLaneGroupsLog2-1 downto 0 generate
    global_reg_bank_port: entity work.rvex_ctrlRegs_readPort
      generic map (
        OFFSET                  => 0,
        NUM_WORDS               => CTRL_REG_GLOB_WORDS
      )
      port map (
        
        -- System control.
        reset                   => reset,
        clk                     => clk,
        clkEn                   => clkEn,
        
        -- Register interface.
        creg2logic              => creg2gbreg_s,
        
        -- Read port.
        addr                    => grpBus_glob_addr(laneGroup),
        readEnable              => grpBus_glob_readEnable(laneGroup),
        readData                => grpBus_glob_readData(laneGroup)
        
      );
  end generate;
  
  -----------------------------------------------------------------------------
  -- Generate claim signal and stall output
  -----------------------------------------------------------------------------
  claim_proc: process (
    dbgBus_ctxt_readEnable, dbgBus_ctxt_writeEnable,
    dbgBus_gpreg_readEnable, dbgBus_gpreg_writeEnable, dbgBus_gpreg_writeMask
  ) is
  begin
    
    -- Don't claim when there is no access.
    dbg_claim <= '0';
    
    -- Claim access when the debug bus is trying to access context registers.
    if dbgBus_ctxt_readEnable = '1' or dbgBus_ctxt_writeEnable = '1' then
      dbg_claim <= '1';
    end if;
    
    -- Claim access when the debug bus is trying to access general purpose
    -- registers, but only if it is operating on a full word.
    if dbgBus_gpreg_readEnable = '1' then
      dbg_claim <= '1';
    end if;
    if dbgBus_gpreg_writeEnable = '1' and dbgBus_gpreg_writeMask = "1111" then
      dbg_claim <= '1';
    end if;
    
  end process;
  
  -- Generate the register for the claim signal with which we delay the stall
  -- signal by one cycle.
  claim_reg: process (clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        dbg_claim_r <= '0';
      else
        dbg_claim_r <= dbg_claim;
      end if;
    end if;
  end process;
  
  -- Generate stall output. It might seem as though we only need to stall lane
  -- group 0, but things are not that simple. For example, if lane group 1 is
  -- accessing the same context as the debug bus is simultaneously, bad things
  -- happen. Also, it might not be permissible to only stall a single lane
  -- group based on the current configuration. Since debug bus accesses are
  -- (supposed to be) spurious events, it shouldn't degrade performance too
  -- much if we just stall all lanes two cycles for every debug bus event.
  stallOut <= (others => dbg_claim or dbg_claim_r);
  
  -----------------------------------------------------------------------------
  -- Generate bus claiming logic
  -----------------------------------------------------------------------------
  -- Connect context register bus commands for lane group 0.
  grpDbgBus_ctxt_addr(0)
    <= dbgBus_ctxt_addr         when dbg_claim = '1' else grpBus_ctxt_addr(0);
  
  grpDbgBus_ctxt_writeEnable(0)
    <= dbgBus_ctxt_writeEnable  when dbg_claim = '1' else grpBus_ctxt_writeEnable(0);
  
  grpDbgBus_ctxt_writeMask(0)
    <= dbgBus_ctxt_writeMask    when dbg_claim = '1' else grpBus_ctxt_writeMask(0);
  
  grpDbgBus_ctxt_writeData(0)
    <= dbgBus_ctxt_writeData    when dbg_claim = '1' else grpBus_ctxt_writeData(0);
  
  grpDbgBus_ctxt_readEnable(0)
    <= dbgBus_ctxt_readEnable   when dbg_claim = '1' else grpBus_ctxt_readEnable(0);
  
  -- Connect the rest of the context register bus commands.
  connect_other_groups_gen: if CFG.numLaneGroupsLog2 > 0 generate
    grpDbgBus_ctxt_addr         (2**CFG.numLaneGroupsLog2-1 downto 1)
      <= grpBus_ctxt_addr       (2**CFG.numLaneGroupsLog2-1 downto 1);
    grpDbgBus_ctxt_writeEnable  (2**CFG.numLaneGroupsLog2-1 downto 1)
      <= grpBus_ctxt_writeEnable(2**CFG.numLaneGroupsLog2-1 downto 1);
    grpDbgBus_ctxt_writeMask    (2**CFG.numLaneGroupsLog2-1 downto 1)
      <= grpBus_ctxt_writeMask  (2**CFG.numLaneGroupsLog2-1 downto 1);
    grpDbgBus_ctxt_writeData    (2**CFG.numLaneGroupsLog2-1 downto 1)
      <= grpBus_ctxt_writeData  (2**CFG.numLaneGroupsLog2-1 downto 1);
    grpDbgBus_ctxt_readEnable   (2**CFG.numLaneGroupsLog2-1 downto 1)
      <= grpBus_ctxt_readEnable (2**CFG.numLaneGroupsLog2-1 downto 1);
  end generate;
  
  -- Connect context read data signals.
  grpBus_ctxt_readData <= grpDbgBus_ctxt_readData;
  dbgBus_ctxt_readData <= grpDbgBus_ctxt_readData(0);
  
  -- Connect the general purpose register debug port.
  creg2gpreg_claim        <= dbg_claim;
  creg2gpreg_addr         <= dbgBus_gpreg_addr(7 downto 2);
  creg2gpreg_ctxt         <= dbgBus_gpreg_addr(8+CFG.numContextsLog2-1 downto 8);
  creg2gpreg_writeEnable  <= dbgBus_gpreg_writeEnable
                         and dbgBus_gpreg_writeMask(0) and dbgBus_gpreg_writeMask(1)
                         and dbgBus_gpreg_writeMask(2) and dbgBus_gpreg_writeMask(3);
  creg2gpreg_writeData    <= dbgBus_gpreg_writeData;
  dbgBus_gpreg_readData   <= gpreg2creg_readData;
  
  -----------------------------------------------------------------------------
  -- Instantiate lane group to context bus switch
  -----------------------------------------------------------------------------
  context_lane_switch: entity work.rvex_ctrlRegs_contextLaneSwitch
    generic map (
      CFG                       => CFG
    )
    port map (
      
      -- System control.
      reset                     => reset,
      clk                       => clk,
      clkEn                     => clkEn,
      
      -- Pipelane group bus interfaces.
      plgrp2sw_addr             => grpDbgBus_ctxt_addr,
      plgrp2sw_writeEnable      => grpDbgBus_ctxt_writeEnable,
      plgrp2sw_writeMask        => grpDbgBus_ctxt_writeMask,
      plgrp2sw_writeData        => grpDbgBus_ctxt_writeData,
      plgrp2sw_readEnable       => grpDbgBus_ctxt_readEnable,
      sw2plgrp_readData         => grpDbgBus_ctxt_readData,
      
      -- Context interface.
      sw2ctxt_addr              => ctxtBus_addr,
      sw2ctxt_writeEnable       => ctxtBus_writeEnable,
      sw2ctxt_writeMask         => ctxtBus_writeMask,
      sw2ctxt_writeData         => ctxtBus_writeData,
      sw2ctxt_readEnable        => ctxtBus_readEnable,
      ctxt2sw_readData          => ctxtBus_readData
      
    );
  
  -----------------------------------------------------------------------------
  -- Instantiate the context control registers
  -----------------------------------------------------------------------------
  context_reg_bank_gen: for ctxt in 2**CFG.numContextsLog2-1 downto 0 generate
    context_reg_bank: entity work.rvex_ctrlRegs_bank
      generic map (
        OFFSET                    => CTRL_REG_GLOB_WORDS,
        NUM_WORDS                 => CTRL_REG_TOTAL_WORDS - CTRL_REG_GLOB_WORDS
      )
      port map (
        
        -- System control.
        reset                     => reset,
        clk                       => clk,
        clkEn                     => clkEn,
        
        -- Bus interface.
        addr                      => ctxtBus_addr(ctxt),
        origin                    => dbg_claim,
        writeEnable               => ctxtBus_writeEnable(ctxt),
        writeMask                 => ctxtBus_writeMask(ctxt),
        writeData                 => ctxtBus_writeData(ctxt),
        readEnable                => ctxtBus_readEnable(ctxt),
        readData                  => ctxtBus_readData(ctxt),
        
        -- Hardware interface.
        logic2creg                => cxreg2creg(ctxt),
        creg2logic                => creg2cxreg(ctxt),
        logic2creg_reset          => cxreg2creg_reset(ctxt)
        
      );
  end generate;
  
end Behavioral;

