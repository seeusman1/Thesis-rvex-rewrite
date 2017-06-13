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

library work;
use work.common_pkg.all;
use work.utils_pkg.all;
use work.bus_pkg.all;
use work.bus_addrConv_pkg.all;
use work.core_pkg.all;

--=============================================================================
-- This unit represents multiple loopback'd stream chains. See rvsys_stream
-- for more information.
-------------------------------------------------------------------------------
entity rvsys_streams is
--=============================================================================
  generic (
    
    -- r-VEX core configuration.
    CORE_CFG                    : rvex_generic_config_type := RVEX_MINIMAL_CONFIG;
    
    -- Number of cores in each stream chain.
    NUM_CORES_PER_STREAM        : natural := 2;
    
    -- Number of parallel stream chains.
    NUM_STREAMS                 : natural := 2;
    
    -- This is an offset added to the core indices for the control registers.
    CORE_ID_OFFS                : natural := 0;
    
    -- Memory sizes for each core.
    DMEM_DEPTH_LOG2             : natural := 12;
    IMEM_DEPTH_LOG2             : natural := 12;
    
    -- Debug bus address mux bit index. This defines how debug bus addresses
    -- are decoded. XX selects whether data memory (0-), instruction memory
    -- (10), or control registers (11) are accessed. IIIIII selects the core
    -- index within each stream, SSSS selects the stream.
    --
    --  Addr: ----SSSS IIIIIIXX -------- --------
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
end rvsys_streams;

--=============================================================================
architecture Behavioral of rvsys_streams is
--=============================================================================
  
  -- Debug bus signals.
  signal dbg_req                : bus_mst2slv_type;
  signal dbg_res                : bus_slv2mst_type;
  signal dbg_reqs               : bus_mst2slv_array(NUM_STREAMS-1 downto 0);
  signal dbg_ress               : bus_slv2mst_array(NUM_STREAMS-1 downto 0);
  
  -- Generate the address decoder configuration for the debug bus.
  function dbg_address_map_f return addrRangeAndMapping_array is
    variable res  : addrRangeAndMapping_array(NUM_STREAMS-1 downto 0);
  begin
    for stream in 0 to NUM_STREAMS-1 loop
      res(stream) := (
        addrRange => (
          low   => int2vect((stream+0)*64*4*2**DEBUG_BUS_MUX_BIT,   32),
          high  => int2vect((stream+1)*64*4*2**DEBUG_BUS_MUX_BIT-1, 32),
          mask  => int2vect(63        *64*4*2**DEBUG_BUS_MUX_BIT,   32),
          match => "--------------------------------"
        ),
        addrMapping => mapRange(31, 0)
      );
    end loop;
    return res;
  end dbg_address_map_f;
  constant DBG_ADDRESS_MAP    : addrRangeAndMapping_array(NUM_STREAMS-1 downto 0)
    := dbg_address_map_f;
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- Instantiate the stream chains
  -----------------------------------------------------------------------------
  stream_gen: for stream in 0 to NUM_STREAMS-1 generate
  begin
    
    stream_x: entity work.rvsys_stream
      generic map (
        CORE_CFG                => CORE_CFG,
        NUM_CORES               => NUM_CORES_PER_STREAM,
        LOOPBACK                => true,
        CORE_ID_OFFS            => CORE_ID_OFFS + stream * NUM_CORES_PER_STREAM,
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
        
        -- Debug/input-output interface (slow clock).
        reset_dbg               => reset_dbg,
        clk_dbg                 => clk_dbg,
        clkEn_dbg               => clkEn_dbg,
        debug2rvs               => dbg_reqs(stream),
        rvs2debug               => dbg_ress(stream)
        
      );
    
  end generate;
  
  -----------------------------------------------------------------------------
  -- Instantiate the debug bus demuxer
  -----------------------------------------------------------------------------
  debug_stage_inst: entity work.bus_stage
    port map (
      reset                   => reset_dbg,
      clk                     => clk_dbg,
      clkEn                   => clkEn_dbg,
      mst2stage               => debug2rvs,
      stage2mst               => rvs2debug,
      stage2slv               => dbg_req,
      slv2stage               => dbg_res
    );  
  
  debug_demux_inst: entity work.bus_demux
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

