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
use rvex.utils_pkg.all;
use rvex.bus_pkg.all;
use rvex.bus_addrConv_pkg.all;
use rvex.core_pkg.all;
use rvex.standalone_pkg.all;

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
    
    -- Configuration.
    CFG                         : rvex_sa_generic_config_type := rvex_sa_cfg
    
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
    rctrl2rvsa_irq              : in  std_logic_vector(2**CFG.core.numContextsLog2-1 downto 0) := (others => '0');
    
    -- External interrupt identification. Guaranteed to be loaded in the trap
    -- argument register in the same clkEn'd cycle where irqAck is high.
    rctrl2rvsa_irqID            : in  rvex_address_array(2**CFG.core.numContextsLog2-1 downto 0) := (others => (others => '0'));
    
    -- External interrupt acknowledge signal, active high. Goes high for one
    -- clkEn'abled cycle.
    rvsa2rctrl_irqAck           : out std_logic_vector(2**CFG.core.numContextsLog2-1 downto 0);
    
    -- Active high run signal. When released, the context will stop running as
    -- soon as possible.
    rctrl2rvsa_run              : in  std_logic_vector(2**CFG.core.numContextsLog2-1 downto 0) := (others => '1');
    
    -- Active high idle output. This is asserted when the core is no longer
    -- doing anything.
    rvsa2rctrl_idle             : out std_logic_vector(2**CFG.core.numContextsLog2-1 downto 0);
    
    -- Active high context reset input. When high, the context control
    -- registers (including PC, done and break flag) will be reset.
    rctrl2rvsa_reset            : in  std_logic_vector(2**CFG.core.numContextsLog2-1 downto 0) := (others => '0');
    
    -- Active high done output. This is asserted when the context encounters
    -- a stop syllable. Processing a stop signal also sets the BRK control
    -- register, which stops the core. This bit can be reset by issuing a core
    -- reset or by means of the debug interface.
    rvsa2rctrl_done             : out std_logic_vector(2**CFG.core.numContextsLog2-1 downto 0);
    
    ---------------------------------------------------------------------------
    -- Bus interfaces
    ---------------------------------------------------------------------------
    -- Master interface to whatever bus the rvex is connected to.
    rvsa2bus                    : out bus_mst2slv_type;
    bus2rvsa                    : in  bus_slv2mst_type;
    
    -- Debug interface.
    debug2rvsa                  : in  bus_mst2slv_type;
    rvsa2debug                  : out bus_slv2mst_type
    
  );
end standalone;

--=============================================================================
architecture Behavioral of standalone is
--=============================================================================
  -- 
  -- The diagram below shows the bus network instantiated by this unit.
  -- 
  -- . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
  -- 
  --                  .-------.         *x        .-----.
  --              *x  |  *x   |==========D========| arb |---K-- rvsa2bus
  --    rv2dmem ===A==| demux |  *x  .-----.      '-----'
  --                  |       |===E==|     |
  --                  '-------'      | 2x  |  2x  .------.
  --                  .-------.      | arb |===I==| dmem |
  --                  |       |---F--|     |      '------'
  --                  |       |      '-----'
  -- debug2rvsa ---B--| demux |---G---------------------------- dbg2rv
  --                  |       |      .-------.      .-----.
  --                  |       |---H--| demux |===J==| *x  |  *x  .------.
  --                  '-------'      '-------'      | arb |===L==| imem |
  --    rv2imem ==========C=========================|     |      '------'
  --                     *x                         '-----'
  -- 
  -- . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
  -- 
  -- Bus A:
  signal rvexData_req           : bus_mst2slv_array(2**CFG.core.numLaneGroupsLog2-1 downto 0);
  signal rvexData_res           : bus_slv2mst_array(2**CFG.core.numLaneGroupsLog2-1 downto 0);
  --
  -- Bus B:
  signal debug_req              : bus_mst2slv_type;
  signal debug_res              : bus_slv2mst_type;
  --
  -- Bus C:
  signal rvexInstr_req          : bus_mst2slv_array(2**CFG.core.numLanesLog2-1 downto 0);
  signal rvexInstr_res          : bus_slv2mst_array(2**CFG.core.numLanesLog2-1 downto 0);
  --
  -- Bus D:
  signal rvexDataBus_req        : bus_mst2slv_array(2**CFG.core.numLaneGroupsLog2-1 downto 0);
  signal rvexDataBus_res        : bus_slv2mst_array(2**CFG.core.numLaneGroupsLog2-1 downto 0);
  --
  -- Bus E:
  signal rvexDataMem_req        : bus_mst2slv_array(2**CFG.core.numLaneGroupsLog2-1 downto 0);
  signal rvexDataMem_res        : bus_slv2mst_array(2**CFG.core.numLaneGroupsLog2-1 downto 0);
  --
  -- Bus F:
  signal debugDataMem_req       : bus_mst2slv_type;
  signal debugDataMem_res       : bus_slv2mst_type;
  --
  -- Bus G:
  signal debugRvex_req          : bus_mst2slv_type;
  signal debugRvex_res          : bus_slv2mst_type;
  --
  -- Bus H:
  signal debugInstr_req         : bus_mst2slv_type;
  signal debugInstr_res         : bus_slv2mst_type;
  --
  -- Bus I:
  signal dataMem_req            : bus_mst2slv_array(1 downto 0);
  signal dataMem_res            : bus_slv2mst_array(1 downto 0);
  --
  -- Bus J: this bus is defined locally in the instruction memory instantiation
  -- block.
  --
  -- Bus K:
  signal dataBus_req            : bus_mst2slv_type;
  signal dataBus_res            : bus_slv2mst_type;
  --
  -- Bus L:
  signal instrMem_req           : bus_mst2slv_array(2**CFG.core.numLanesLog2-1 downto 0);
  signal instrMem_res           : bus_slv2mst_array(2**CFG.core.numLanesLog2-1 downto 0);
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- Connect the external busses to internal signals
  -----------------------------------------------------------------------------
  -- (This is just to get the bus naming consistent.)
  rvsa2bus    <= dataBus_req;
  dataBus_res <= bus2rvsa;
  debug_req   <= debug2rvsa;
  rvsa2debug  <= debug_res;
  
  -----------------------------------------------------------------------------
  -- Instantiate the rvex core
  -----------------------------------------------------------------------------
  core: entity rvex.standalone_core
    generic map (
      CFG                       => CFG.core
    )
    port map (
      
      -- System control.
      reset                     => reset,
      clk                       => clk,
      clkEn                     => clkEn,
      
      -- Run control interface.
      rctrl2rvsa_irq            => rctrl2rvsa_irq,
      rctrl2rvsa_irqID          => rctrl2rvsa_irqID,
      rvsa2rctrl_irqAck         => rvsa2rctrl_irqAck,
      rctrl2rvsa_run            => rctrl2rvsa_run,
      rvsa2rctrl_idle           => rvsa2rctrl_idle,
      rctrl2rvsa_reset          => rctrl2rvsa_reset,
      rvsa2rctrl_done           => rvsa2rctrl_done,
      
      -- Instruction memory busses.
      rv2imem                   => rvexInstr_req,
      imem2rv                   => rvexInstr_res,
      
      -- Data memory busses.
      rv2dmem                   => rvexData_req,
      dmem2rv                   => rvexData_res,
      
      -- Debug bus.
      dbg2rv                    => debugRvex_req,
      rv2dbg                    => debugRvex_res
      
    );
  
  -----------------------------------------------------------------------------
  -- Instantiate the debug bus demux unit
  -----------------------------------------------------------------------------
  debug_bus_demux_inst: entity rvex.bus_demux
    generic map (
      ADDRESS_MAP(0)            => CFG.debugBusMap_dmem,
      ADDRESS_MAP(1)            => CFG.debugBusMap_imem,
      ADDRESS_MAP(2)            => CFG.debugBusMap_rvex
    )
    port map (
      reset                     => reset,
      clk                       => clk,
      clkEn                     => clkEn,
      mst2demux                 => debug_req,
      demux2mst                 => debug_res,
      demux2slv(0)              => debugDataMem_req,
      demux2slv(1)              => debugInstr_req,
      demux2slv(2)              => debugRvex_req,
      slv2demux(0)              => debugDataMem_res,
      slv2demux(1)              => debugInstr_res,
      slv2demux(2)              => debugRvex_res
    );
  
  -----------------------------------------------------------------------------
  -- Instantiate connections between the rvex data memory ports and the
  -- external bus
  -----------------------------------------------------------------------------
  ext_bus_block: block is
  begin
    
    -- Instantiate the demuxing blocks.
    data_bus_demux_gen: for laneGroup in 0 to 2**CFG.core.numLaneGroupsLog2-1 generate
      data_bus_demux_inst: entity rvex.bus_demux
        generic map (
          ADDRESS_MAP(0)        => CFG.rvexDataMap_bus,
          ADDRESS_MAP(1)        => CFG.rvexDataMap_dmem
        )
        port map (
          reset                 => reset,
          clk                   => clk,
          clkEn                 => clkEn,
          mst2demux             => rvexData_req(laneGroup),
          demux2mst             => rvexData_res(laneGroup),
          demux2slv(0)          => rvexDataBus_req(laneGroup),
          demux2slv(1)          => rvexDataMem_req(laneGroup),
          slv2demux(0)          => rvexDataBus_res(laneGroup),
          slv2demux(1)          => rvexDataMem_res(laneGroup)
        );
    end generate;
    
    -- Instantiate the arbiter to merge the requests from each lane group into
    -- a single bus.
    data_bus_arbiter: entity rvex.bus_arbiter
      generic map (
        NUM_MASTERS             => 2**CFG.core.numLaneGroupsLog2
      )
      port map (
        reset                   => reset,
        clk                     => clk,
        clkEn                   => clkEn,
        mst2arb                 => rvexDataBus_req,
        arb2mst                 => rvexDataBus_res,
        arb2slv                 => dataBus_req,
        slv2arb                 => dataBus_res
      );
    
  end block;
  
  -----------------------------------------------------------------------------
  -- Instantiate data memory
  -----------------------------------------------------------------------------
  dmem_block: block is
    
    -- First and last data memory bus connected to port A.
    constant SA : natural := 0;
    constant EA : natural := (2**CFG.core.numLaneGroupsLog2 / 2) - 1;
    
    -- First and last data memory bus connected to port B.
    constant SB : natural := EA + 1;
    constant EB : natural := 2**CFG.core.numLaneGroupsLog2-1;
    
  begin
    
    -- Arbiter for port A.
    dmem_arbiter_a: entity rvex.bus_arbiter
      generic map (
        NUM_MASTERS             => (EA - SA) + 2
      )
      port map (
        reset                   => reset,
        clk                     => clk,
        clkEn                   => clkEn,
        mst2arb(EA-SA+1 downto 1)=>rvexDataMem_req(EA downto SA),
        mst2arb(0)              => debugDataMem_req,
        arb2mst(EA-SA+1 downto 1)=>rvexDataMem_res(EA downto SA),
        arb2mst(0)              => debugDataMem_res,
        arb2slv                 => dataMem_req(0),
        slv2arb                 => dataMem_res(0)
      );
    
    -- Arbiter for port B.
    dmem_arbiter_b: entity rvex.bus_arbiter
      generic map (
        NUM_MASTERS             => (EB - SB) + 1
      )
      port map (
        reset                   => reset,
        clk                     => clk,
        clkEn                   => clkEn,
        mst2arb                 => rvexDataMem_req(EB downto SB),
        arb2mst                 => rvexDataMem_res(EB downto SB),
        arb2slv                 => dataMem_req(1),
        slv2arb                 => dataMem_res(1)
      );
    
    -- Instantiate the memory itself.
    dmem_ram: entity rvex.bus_ramBlock
      generic map (
        DEPTH_LOG2B             => CFG.dmemDepthLog2B
      )
      port map (
        reset                   => reset,
        clk                     => clk,
        clkEn                   => clkEn,
        mst2mem_portA           => dataMem_req(0),
        mem2mst_portA           => dataMem_res(0),
        mst2mem_portB           => dataMem_req(1),
        mem2mst_portB           => dataMem_res(1)
      );
    
  end block;
  
  -----------------------------------------------------------------------------
  -- Instantiate instruction memory
  -----------------------------------------------------------------------------
  imem_block: block is
    
    -- Because each memory block has two ports, we always need to instantiate
    -- one block for two lanes.
    constant NUM_BLOCKS         : natural := 2**CFG.core.numLanesLog2 / 2;
    
    -- The rvex will always make accesses aligned to the size of a bundle for
    -- a single lane group. Because of this, not all memory blocks need to hold
    -- the entire instruction memory. INTERLEAVE_LOG2 specifies the log2 of the
    -- factor which the size of each block is divided by. That probably makes
    -- no sense to you, but I don't know how to say it better, so have some
    -- examples. When INTERLEAVE_LOG2 is 1 for example, this means that each
    -- memory block only stores half of the instruction memory; each block
    -- stores one of the halves (duplication may still be necessary). This
    -- value is trivially set to the number of lanes in a group, which would be
    -- correct if there would be one block per lane. However, because a block
    -- is shared between two lanes because of each block having two ports, we
    -- can't set INTERLEAVE_LOG2 higher than or equal to log2(NUM_BLOCKS),
    -- which equals CFG.core.numLanesLog2-1.
    constant INTERLEAVE_LOG2    : natural := min_nat(
      CFG.core.numLanesLog2 - CFG.core.numLaneGroupsLog2,
      CFG.core.numLanesLog2 - 1
    );
    
    -- We need to shift the incoming addresses right by INTERLEAVE_LOG2 for
    -- things to make sense.
    constant BLK_ADDRESS_MAP    : addrMapping_type
      := mapConstant(INTERLEAVE_LOG2, '0')
       & mapRange(31, 2 + INTERLEAVE_LOG2)
       & mapConstant(2, '0');
    
    -- This function generates the memory map table for the debug bus demux
    -- unit.
    function dbg_address_map_f return addrRangeAndMapping_array is
      variable res  : addrRangeAndMapping_array(NUM_BLOCKS-1 downto 0);
    begin
      for blk in 0 to NUM_BLOCKS-1 loop
        res(blk) := addrRangeAndMap;
        
        -- Require that the LSBs of the address map to those memory locations
        -- which are actually stored in this block.
        if INTERLEAVE_LOG2 > 0 then
          res(blk).addrRange.match(2+INTERLEAVE_LOG2-1 downto 2)
            := uint2vect(blk mod 2**INTERLEAVE_LOG2, INTERLEAVE_LOG2);
        end if;
        
      end loop;
      return res;
    end dbg_address_map_f;
    
    constant DBG_ADDRESS_MAP    : addrRangeAndMapping_array(NUM_BLOCKS-1 downto 0)
      := dbg_address_map_f;
    
    -- Debug access bus for each instruction memory block.
    signal debugInstrDmx_req    : bus_mst2slv_array(NUM_BLOCKS-1 downto 0);
    signal debugInstrDmx_res    : bus_slv2mst_array(NUM_BLOCKS-1 downto 0);
    
  begin
    
    -- Instantiate the bus demux which routes debug bus accesses to the
    -- instruction memory to all blocks involved.
    imem_debug_demux_inst: entity rvex.bus_demux
      generic map (
        ADDRESS_MAP             => DBG_ADDRESS_MAP,
        MUTUALLY_EXCLUSIVE      => false
      )
      port map (
        reset                   => reset,
        clk                     => clk,
        clkEn                   => clkEn,
        mst2demux               => debugInstr_req,
        demux2mst               => debugInstr_res,
        demux2slv               => debugInstrDmx_req,
        slv2demux               => debugInstrDmx_res
      );
    
    -- Generate arbitration logic between the instruction busses of the rvex
    -- and the debug bus.
    imem_arbiter_gen: for blk in 0 to NUM_BLOCKS-1 generate
      signal portAreq           : bus_mst2slv_type;
    begin
      
      -- Arbiter for port A to switch between debug bus and rvex.
      imem_arbiter_a: entity rvex.bus_arbiter
        generic map (
          NUM_MASTERS           => 2
        )
        port map (
          reset                 => reset,
          clk                   => clk,
          clkEn                 => clkEn,
          mst2arb(0)            => rvexInstr_req(blk),
          mst2arb(1)            => debugInstrDmx_req(blk),
          arb2mst(0)            => rvexInstr_res(blk),
          arb2mst(1)            => debugInstrDmx_res(blk),
          arb2slv               => portAreq,
          slv2arb               => instrMem_res(blk)
        );
      
      -- Perform address translation on the request for port A. This address
      -- translation shifts the address right by one or more bits, when not all
      -- memory blocks need to hold all the addresses. This is possible because
      -- an instruction memory port of the rvex will always make accesses
      -- aligned to something larger than a word plus some offset.
      instrMem_req(blk) <= applyAddrMap(
        portAreq,
        BLK_ADDRESS_MAP
      );
      
      -- Connect port B without an arbiter, because we only need to be able to
      -- access one of the ports with the debug bus. Still perform the address
      -- transformation though.
      instrMem_req(blk + NUM_BLOCKS) <= applyAddrMap(
        rvexInstr_req(blk + NUM_BLOCKS),
        BLK_ADDRESS_MAP
      );
      
      rvexInstr_res(blk + NUM_BLOCKS) <= instrMem_res(blk + NUM_BLOCKS);
      
    end generate;
      
    -- Instantiate the memory itself.
    imem_ram_gen: for blk in 0 to NUM_BLOCKS-1 generate
      imem_ram_inst: entity rvex.bus_ramBlock
        generic map (
          DEPTH_LOG2B           => CFG.dmemDepthLog2B - INTERLEAVE_LOG2
        )
        port map (
          reset                 => reset,
          clk                   => clk,
          clkEn                 => clkEn,
          mst2mem_portA         => instrMem_req(blk),
          mem2mst_portA         => instrMem_res(blk),
          mst2mem_portB         => instrMem_req(blk + NUM_BLOCKS),
          mem2mst_portB         => instrMem_res(blk + NUM_BLOCKS)
        );
    end generate;
    
  end block;
  
end Behavioral;

