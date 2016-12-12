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
-- This unit represents a chain of "streaming" r-VEX cores. Each r-VEX has
-- separated single-cycle local instruction and data memories. Each r-VEX can
-- also access the data memory of the previous core in the chain. The first
-- r-VEX can either access an external input buffer, or it can access the data
-- memory of the last core if LOOPBACK is enabled. A debug interface is
-- available to provide access to the memories and the core control registers.
-- This interface runs in a different clock domain to allow the r-VEX to be
-- clocked as high as possible. This design is intended for tiny and fast r-VEX
-- cores, and does not support reconfigurable cores due to the portedness of
-- the data memory.
--
-- The memory map as seen from each core is:
--   0x00000000..0x7FFFFFFF => local data memory.
--   0x80000000..0xFFFFFFFF => stream data memory.
--
-- The memory map as seen from the debug bus is controlled by the
-- DEBUG_BUS_MUX_BIT generic (see comments in the entity).
-------------------------------------------------------------------------------
entity rvsys_stream is
--=============================================================================
  generic (
    
    -- r-VEX core configuration.
    CORE_CFG                    : rvex_generic_config_type := RVEX_MINIMAL_CONFIG;
    
    -- Number of cores in the stream.
    NUM_CORES                   : natural := 2;
    
    -- When enabled, the stream input and output bus interfaces are not
    -- connected and are instead internally connected together to form a loop.
    LOOPBACK                    : boolean := false;
    
    -- This is an offset added to the core indices within the stream for the
    -- control registers.
    CORE_ID_OFFS                : natural := 0;
    
    -- Memory sizes for each core.
    DMEM_DEPTH_LOG2             : natural := 12;
    IMEM_DEPTH_LOG2             : natural := 12;
    
    -- Debug bus address mux bit index. This defines how debug bus addresses
    -- are decoded. XX selects whether data memory (0-), instruction memory
    -- (10), or control registers (11) are accessed, while IIIIII selects the
    -- core index.
    --
    --  Addr: -------- IIIIIIXX -------- --------
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
    
    -- Master interface from the first core in the chain, to be connected to
    -- the data source buffer. This is not internally connected if LOOPBACK is
    -- enabled.
    rvs2in                      : out bus_mst2slv_type;
    in2rvs                      : in  bus_slv2mst_type := BUS_SLV2MST_IDLE;
    
    -- Slave interface for the last data memory in the chain, to be used as an
    -- output buffer. This is not internally connected if LOOPBACK is enabled.
    out2rvs                     : in  bus_mst2slv_type := BUS_MST2SLV_IDLE;
    rvs2out                     : out bus_slv2mst_type;
    
    ---------------------------------------------------------------------------
    -- Debug/input-output interface (slow clock)
    ---------------------------------------------------------------------------
    -- Reset/clk/clkEn for the debug bus.
    reset_dbg                   : in  std_logic;
    clk_dbg                     : in  std_logic;
    clkEn_dbg                   : in  std_logic := '1';
    
    -- Debug interface. Operates
    debug2rvs                   : in  bus_mst2slv_type;
    rvs2debug                   : out bus_slv2mst_type
    
  );
end rvsys_stream;

--=============================================================================
architecture Behavioral of rvsys_stream is
--=============================================================================
  
  -- Stream interconnect signals.
  signal backward               : bus_mst2slv_array(NUM_CORES downto 0);
  signal forward                : bus_slv2mst_array(NUM_CORES downto 0);
  
  -- Debug bus signals.
  signal dbg_req                : bus_mst2slv_type;
  signal dbg_res                : bus_slv2mst_type;
  signal dbg_reqs               : bus_mst2slv_array(NUM_CORES-1 downto 0);
  signal dbg_ress               : bus_slv2mst_array(NUM_CORES-1 downto 0);
  
  -- Generate the address decoder configuration for the debug bus.
  function dbg_address_map_f return addrRangeAndMapping_array is
    variable res  : addrRangeAndMapping_array(NUM_CORES-1 downto 0);
  begin
    for core in 0 to NUM_CORES-1 loop
      res(core) := (
        addrRange => (
          low   => int2vect((core+0)*4*2**DEBUG_BUS_MUX_BIT,   32),
          high  => int2vect((core+1)*4*2**DEBUG_BUS_MUX_BIT-1, 32),
          mask  => int2vect(63      *4*2**DEBUG_BUS_MUX_BIT,   32),
          match => "--------------------------------"
        ),
        addrMapping => mapRange(31, 0)
      );
    end loop;
    return res;
  end dbg_address_map_f;
  constant DBG_ADDRESS_MAP    : addrRangeAndMapping_array(NUM_CORES-1 downto 0)
    := dbg_address_map_f;
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- Handle the input/output stream connections
  -----------------------------------------------------------------------------
  no_loopback_gen: if not LOOPBACK generate
  begin
    
    -- Connect to the external input buffer.
    rvs2in <= backward(0);
    forward(0) <= in2rvs;
    
    -- Allow an external interface to connect to the last data buffer.
    backward(NUM_CORES) <= out2rvs;
    rvs2out <= forward(NUM_CORES);
    
  end generate;
  
  loopback_gen: if LOOPBACK generate
  begin
    
    -- Connect the first core to the last core.
    backward(NUM_CORES) <= backward(0);
    forward(0) <= forward(NUM_CORES);
    
  end generate;
  
  -----------------------------------------------------------------------------
  -- Instantiate the cores
  -----------------------------------------------------------------------------
  stream_core_gen: for core in 0 to NUM_CORES-1 generate
  begin
    
    stream_core_x: entity rvex.rvsys_stream_core
      generic map (
        CORE_CFG                => CORE_CFG,
        CORE_ID                 => CORE_ID_OFFS + core,
        DMEM_DEPTH_LOG2         => DMEM_DEPTH_LOG2,
        IMEM_DEPTH_LOG2         => IMEM_DEPTH_LOG2,
        DEBUG_BUS_MUX_BIT       => DEBUG_BUS_MUX_BIT,
        PLATFORM_TAG            => PLATFORM_TAG
      )
      port map (
        
        -- Core interfaces (fast clock).
        reset                   => reset,
        clk                     => clk,
        clkEn                   => clkEn,
        rvsc2prv                => backward(core),
        prv2rvsc                => forward(core),
        nxt2rvsc                => backward(core+1),
        rvsc2nxt                => forward(core+1),
        
        -- Debug/input-output interface (slow clock).
        reset_dbg               => reset_dbg,
        clk_dbg                 => clk_dbg,
        clkEn_dbg               => clkEn_dbg,
        debug2rvsc              => dbg_reqs(core),
        rvsc2debug              => dbg_ress(core)
        
      );
    
  end generate;
  
  -----------------------------------------------------------------------------
  -- Instantiate the debug bus demuxer
  -----------------------------------------------------------------------------
  debug_stage_inst: entity rvex.bus_stage
    port map (
      reset                   => reset_dbg,
      clk                     => clk_dbg,
      clkEn                   => clkEn_dbg,
      mst2stage               => debug2rvs,
      stage2mst               => rvs2debug,
      stage2slv               => dbg_req,
      slv2stage               => dbg_res
    );  
  
  debug_demux_inst: entity rvex.bus_demux
    generic map (
      ADDRESS_MAP             => DBG_ADDRESS_MAP
    )
    port map (
      reset                   => reset_dbg,
      clk                     => clk_dbg,
      clkEn                   => clkEn_dbg,
      mst2demux               => dbg_req,
      demux2mst               => dbg_res,
      demux2slv               => dbg_reqs,
      slv2demux               => dbg_ress
    );
  
end Behavioral;

