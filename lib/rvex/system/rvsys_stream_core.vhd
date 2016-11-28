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

library rvex;
use rvex.common_pkg.all;
use rvex.utils_pkg.all;
use rvex.bus_pkg.all;
use rvex.bus_addrConv_pkg.all;
use rvex.core_pkg.all;

--=============================================================================
-- This unit represents a single "streaming" r-VEX core. The r-VEX has
-- separated single-cycle local instruction and data memories. The second port
-- of the data memory is available for interfacing to another bus, while the
-- r-VEX itself can also address another bus. This allows cores to be
-- daisy-chained together in a stream. A debug interface is available to
-- provide access to the memories and the core control registers. This
-- interface runs in a different clock domain to allow the r-VEX to be clocked
-- as high as possible. This design is intended for tiny and fast r-VEX cores,
-- and does not support reconfigurable cores due to the portedness of the data
-- memory.
--
-- The memory map as seen from the core is:
--   0x00000000..0x7FFFFFFF => local data memory.
--   0x80000000..0xFFFFFFFF => stream data memory.
--
-- The memory map as seen from the debug bus is controlled by the
-- DEBUG_BUS_MUX_BIT generic. This generic selects the bit index to use for
-- the selection between the data memory, instruction memory, and control
-- registers. If this value is 16 (the default), then the address map is as
-- follows:
--   0x00000000..0x0001FFFF => local data memory (max 128k).
--   0x00020000..0x0002FFFF => instruction memory (max 64k).
--   0x00030000..0x0003FFFF => control registers.
-- 
-------------------------------------------------------------------------------
entity rvsys_stream_core is
--=============================================================================
  generic (
    
    -- r-VEX core configuration.
    CORE_CFG                    : rvex_generic_config_type := RVEX_MINIMAL_CONFIG;
    
    -- This is used as the core index register in the global control registers.
    CORE_ID                     : natural := 0;
    
    -- Initial contents for the memories.
    DMEM_INIT                   : rvex_data_array := RVEX_DATA_ARRAY_NULL;
    IMEM_INIT                   : rvex_data_array := RVEX_DATA_ARRAY_NULL;
    
    -- Memory sizes.
    DMEM_DEPTH_LOG2             : natural := 12;
    IMEM_DEPTH_LOG2             : natural := 12;
    
    -- Debug bus address mux bit index. This defines which two bits determine
    -- which of dmem (XX=0-), imem (XX=10), or cregs (XX=11) is accessed, as
    -- follows:
    --
    --  Addr: -------- ------XX -------- --------
    --                        ^
    --    DEBUG_BUS_MUX_BIT --'
    --
    DEBUG_BUS_MUX_BIT           : natural := 16;
    
    -- Platform version tag. This is put in the global control registers of the
    -- processor.
    PLATFORM_TAG                : std_logic_vector(55 downto 0) := (others => '0')
    
  );
  port (
    
    ---------------------------------------------------------------------------
    -- Core interfaces (fast clock)
    ---------------------------------------------------------------------------
    -- Reset/clk/clkEn for the core.
    reset                       : in  std_logic;
    clk                         : in  std_logic;
    clkEn                       : in  std_logic := '1';
    
    -- Master interface to the local memory of the previous processor in the
    -- stream.
    rvsc2prv                    : out bus_mst2slv_type;
    prv2rvsc                    : in  bus_slv2mst_type;
    
    -- Slave interface for the second port of our local memory, to be used by
    -- the next processor in the stream.
    nxt2rvsc                    : in  bus_mst2slv_type;
    rvsc2nxt                    : out bus_slv2mst_type;
    
    ---------------------------------------------------------------------------
    -- Debug/input-output interface (slow clock)
    ---------------------------------------------------------------------------
    -- Reset/clk/clkEn for the debug bus.
    reset_dbg                   : in  std_logic;
    clk_dbg                     : in  std_logic;
    clkEn_dbg                   : in  std_logic;
    
    -- Debug interface. Operates
    debug2rvsc                  : in  bus_mst2slv_type;
    rvsc2debug                  : out bus_slv2mst_type
    
  );
end rvsys_stream_core;

--=============================================================================
architecture Behavioral of rvsys_stream_core is
--=============================================================================
  -- 
  -- The diagram below shows the bus network instantiated by this unit.
  -- NOTE: the cores may have only one lane group.
  -- 
  -- . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
  -- 
  -- 
  --   nxt2rvsc ------------K---------------------------.
  --                           .-------.                |
  --                           |       |--D-------------+------------ rvsc2prv
  --    rv2dmem ------------A--| demux |     .-------.  |  .------.
  --                           |       |--E--|       |  '--|      |
  -- Fast clock                '-------'     |  arb  |     | dmem |
  -- - - - - - - - -.          .-------.     |       |--I--|      |
  -- Slow clock      :         |       |--F--|       |     '------'
  --              .------.     |       |     '-------'
  -- debug2rvsc --| xclk |--B--| demux |--G-------------------------- dbg2rv
  --              '------'     |       |     .-------.     .-----.
  --                 :         |       |--H--| demux |==J==| *x  | *x  .------.
  -- - - - - - - - -`          '-------'     '-------'     | arb |==L==| imem |
  --    rv2imem ===================C=======================|     |     '------'
  --                              *x                       '-----'
  -- 
  -- . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
  --
  -- Bus A:
  signal rvexData_req           : bus_mst2slv_type;
  signal rvexData_res           : bus_slv2mst_type;
  --
  -- Bus B:
  signal debug_req              : bus_mst2slv_type;
  signal debug_res              : bus_slv2mst_type;
  --
  -- Bus C:
  signal rvexInstr_req          : bus_mst2slv_array(2**CORE_CFG.numLanesLog2-1 downto 0);
  signal rvexInstr_res          : bus_slv2mst_array(2**CORE_CFG.numLanesLog2-1 downto 0);
  --
  -- Bus D:
  signal rvexDataPrv_req        : bus_mst2slv_type;
  signal rvexDataPrv_res        : bus_slv2mst_type;
  --
  -- Bus E:
  signal rvexDataMem_req        : bus_mst2slv_type;
  signal rvexDataMem_res        : bus_slv2mst_type;
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
  signal dataMemLocal_req       : bus_mst2slv_type;
  signal dataMemLocal_res       : bus_slv2mst_type;
  --
  -- Bus J: this bus is defined locally in the instruction memory instantiation
  -- block.
  --
  -- Bus K:
  signal dataMemOther_req       : bus_mst2slv_type;
  signal dataMemOther_res       : bus_slv2mst_type;
  --
  -- Bus L:
  signal instrMem_req           : bus_mst2slv_array(2**CORE_CFG.numLanesLog2-1 downto 0);
  signal instrMem_res           : bus_slv2mst_array(2**CORE_CFG.numLanesLog2-1 downto 0);
  
  -- Core address decoder configuration.
  constant CORE_LOCAL           : addrRangeAndMapping_type := (
    addrRange => (
      low   => "00000000000000000000000000000000",
      high  => "01111111111111111111111111111111",
      mask  => "10000000000000000000000000000000",
      match => "--------------------------------"
    ),
    addrMapping => mapRange(31, 0)
  );
  
  constant CORE_REMOTE          : addrRangeAndMapping_type := (
    addrRange => (
      low   => "10000000000000000000000000000000",
      high  => "11111111111111111111111111111111",
      mask  => "10000000000000000000000000000000",
      match => "--------------------------------"
    ),
    addrMapping => mapRange(31, 0)
  );
  
  -- Debug bus address decoder configuration.
  constant DEBUG_BUS_DMEM       : addrRangeAndMapping_type := (
    addrRange => (
      low   => int2vect(0*2**DEBUG_BUS_MUX_BIT,   32),
      high  => int2vect(2*2**DEBUG_BUS_MUX_BIT-1, 32),
      mask  => int2vect(3*2**DEBUG_BUS_MUX_BIT,   32),
      match => "--------------------------------"
    ),
    addrMapping => mapRange(31, 0)
  );
  
  constant DEBUG_BUS_IMEM       : addrRangeAndMapping_type := (
    addrRange => (
      low   => int2vect(2*2**DEBUG_BUS_MUX_BIT,   32),
      high  => int2vect(3*2**DEBUG_BUS_MUX_BIT-1, 32),
      mask  => int2vect(3*2**DEBUG_BUS_MUX_BIT,   32),
      match => "--------------------------------"
    ),
    addrMapping => mapRange(31, 0)
  );
  
  constant DEBUG_BUS_CREG       : addrRangeAndMapping_type := (
    addrRange => (
      low   => int2vect(3*2**DEBUG_BUS_MUX_BIT,   32),
      high  => int2vect(4*2**DEBUG_BUS_MUX_BIT-1, 32),
      mask  => int2vect(3*2**DEBUG_BUS_MUX_BIT,   32),
      match => "--------------------------------"
    ),
    addrMapping => mapRange(31, 0)
  );
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- Connect the external busses to internal signals
  -----------------------------------------------------------------------------
  -- (This is just to get the bus naming consistent.)
  rvsc2prv <= rvexDataPrv_req;
  rvexDataPrv_res <= prv2rvsc;
  
  dataMemOther_req <= nxt2rvsc;
  rvsc2nxt <= dataMemOther_res;
  
  -----------------------------------------------------------------------------
  -- Instantiate the rvex core
  -----------------------------------------------------------------------------
  -- Instantiate the standalone core.
  core: entity rvex.rvsys_standalone_core
    generic map (
      CFG                       => CORE_CFG,
      CORE_ID                   => CORE_ID,
      PLATFORM_TAG              => PLATFORM_TAG
    )
    port map (
      
      -- System control.
      reset                     => reset,
      clk                       => clk,
      clkEn                     => clkEn,
      
      -- Instruction memory busses.
      rv2imem                   => rvexInstr_req,
      imem2rv                   => rvexInstr_res,
      
      -- Data memory busses.
      rv2dmem(0)                => rvexData_req,
      dmem2rv(0)                => rvexData_res,
      
      -- Debug bus.
      dbg2rv                    => debugRvex_req,
      rv2dbg                    => debugRvex_res
      
    );
  
  -----------------------------------------------------------------------------
  -- Instantiate the debug bus logic
  -----------------------------------------------------------------------------
  -- Instantiate the cross-clock domain bridge for the debug bus.
  debug_bus_xclk_inst: entity rvex.bus_crossClock
    port map (
      reset                     => reset_dbg,
      
      -- Master bus.
      mst_clk                   => clk_dbg,
      mst_clkEn                 => clkEn_dbg,
      mst2crclk                 => debug2rvsc,
      crclk2mst                 => rvsc2debug,
      
      -- Slave bus.
      slv_clk                   => clk,
      slv_clkEn                 => clkEn,
      crclk2slv                 => debug_req,
      slv2crclk                 => debug_res
          
    );
  
  -- Instantiate the debug bus demuxer for the case where the instruction
  -- memory is enabled.
  debug_bus_demux_inst: entity rvex.bus_demux
    generic map (
      ADDRESS_MAP(0)            => DEBUG_BUS_IMEM,
      ADDRESS_MAP(1)            => DEBUG_BUS_DMEM,
      ADDRESS_MAP(2)            => DEBUG_BUS_CREG
    )
    port map (
      reset                     => reset,
      clk                       => clk,
      clkEn                     => clkEn,
      mst2demux                 => debug_req,
      demux2mst                 => debug_res,
      demux2slv(0)              => debugInstr_req,
      demux2slv(1)              => debugDataMem_req,
      demux2slv(2)              => debugRvex_req,
      slv2demux(0)              => debugInstr_res,
      slv2demux(1)              => debugDataMem_res,
      slv2demux(2)              => debugRvex_res
    );
    
  -----------------------------------------------------------------------------
  -- Instantiate connections between the rvex data memory ports and the
  -- external bus
  -----------------------------------------------------------------------------
  -- Instantiate the demuxing block.
  data_bus_demux_inst: entity rvex.bus_demux
    generic map (
      ADDRESS_MAP(0)            => CORE_LOCAL,
      ADDRESS_MAP(1)            => CORE_REMOTE
    )
    port map (
      reset                     => reset,
      clk                       => clk,
      clkEn                     => clkEn,
      mst2demux                 => rvexData_req,
      demux2mst                 => rvexData_res,
      demux2slv(0)              => rvexDataMem_req,
      demux2slv(1)              => rvexDataPrv_req,
      slv2demux(0)              => rvexDataMem_res,
      slv2demux(1)              => rvexDataPrv_res
    );
  
  -----------------------------------------------------------------------------
  -- Instantiate data memory
  -----------------------------------------------------------------------------
  -- Arbiter for the local port, switching between the debug bus and the local
  -- processor.
  dmem_arbiter: entity rvex.bus_arbiter
    generic map (
      NUM_MASTERS               => 2
    )
    port map (
      reset                     => reset,
      clk                       => clk,
      clkEn                     => clkEn,
      mst2arb(1)                => rvexDataMem_req,
      mst2arb(0)                => debugDataMem_req,
      arb2mst(1)                => rvexDataMem_res,
      arb2mst(0)                => debugDataMem_res,
      arb2slv                   => dataMemLocal_req,
      slv2arb                   => dataMemLocal_res
    );
  
  -- Instantiate the memory itself.
  dmem_ram: entity rvex.bus_ramBlock
    generic map (
      DEPTH_LOG2B               => DMEM_DEPTH_LOG2,
      MEM_INIT                  => DMEM_INIT
    )
    port map (
      reset                     => reset,
      clk                       => clk,
      clkEn                     => clkEn,
      mst2mem_portA             => dataMemLocal_req,
      mem2mst_portA             => dataMemLocal_res,
      mst2mem_portB             => dataMemOther_req,
      mem2mst_portB             => dataMemOther_res
    );
  
  -----------------------------------------------------------------------------
  -- Instantiate instruction memory
  -----------------------------------------------------------------------------
  imem_gen: block is
    
    -- Because each memory block has two ports, we always need to instantiate
    -- one block for two lanes.
    constant NUM_BLOCKS         : natural := 2**CORE_CFG.numLanesLog2 / 2;
    
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
    -- which equals CORE_CFG.numLanesLog2-1.
    constant INTERLEAVE_LOG2    : natural := min_nat(
      CORE_CFG.numLanesLog2 - CORE_CFG.numLaneGroupsLog2,
      CORE_CFG.numLanesLog2 - 1
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
          DEPTH_LOG2B           => IMEM_DEPTH_LOG2 - INTERLEAVE_LOG2,
          MEM_INIT              => IMEM_INIT,
          MEM_OFFSET            => blk mod 2**INTERLEAVE_LOG2,
          MEM_STRIDE            => 2**INTERLEAVE_LOG2
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

