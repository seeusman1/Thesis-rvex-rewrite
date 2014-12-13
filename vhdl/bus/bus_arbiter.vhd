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

--=============================================================================
-- This entity serves as a bus arbiter between N masters, which will
-- load-balance requests among M slaves. Note that this implementation is very
-- much optimized for speed and not for area; it uses a lookup table for state
-- decoding.
-------------------------------------------------------------------------------
entity bus_arbiter is
--=============================================================================
  generic (
    
    -- Number of bus masters which need to be arbitrated.
    NUM_MASTERS                 : positive
    
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
    -- Busses
    ---------------------------------------------------------------------------
    -- Master busses.
    mst2arb                     : in  bus_mst2slv_array(NUM_MASTERS-1 downto 0);
    arb2mst                     : out bus_slv2mst_array(NUM_MASTERS-1 downto 0);
    
    -- Slave bus(ses).
    arb2slv                     : out bus_mst2slv_type;
    slv2arb                     : in  bus_slv2mst_type
    
  );
end bus_arbiter;

--=============================================================================
architecture Behavioral of bus_arbiter is
--=============================================================================
  
  -- log2s of the number of masters and ports, used as sizes for the mux
  -- selection signals.
  constant NUM_MASTERS_LOG2     : natural := integer(ceil(log2(real(NUM_MASTERS))));
  
  -- Port and bus selection types.
  subtype select_type is std_logic_vector(NUM_MASTERS_LOG2-1 downto 0);
  type select_array is array (natural range <>) of select_type;
  
  -- Number of bits needed for the input to the scheduling lookup table. One
  -- signal is needed per master bus, representing whether it desires to access
  -- the memory or not. The remainder is needed to identify the master which
  -- last had access to the bus.
  constant NUM_SCHED_INPUT_BITS : natural := NUM_MASTERS + NUM_MASTERS_LOG2;
  
  -- Type for the scheduling lookup table. The LSBs of the index should
  -- be connected to the previous value of the output of this lookup table,
  -- the MSBs to the access signals from the ports.
  subtype schedLookup_type is select_array(0 to 2**NUM_SCHED_INPUT_BITS-1);
  
  -- Returns the next index, starting at idx + 1, for which vect is high.
  -- Scanning for indices wraps around. When the vector is completely zero,
  -- this returns idx.
  pure function getNextSetIndex(idx: natural; vect: std_logic_vector) return natural is
    variable nidx : natural;
  begin
    for i in 0 to vect'length-1 loop
      nidx := (i + idx + 1) mod vect'length + vect'low;
      if vect(nidx) = '1' then
        return nidx;
      end if;
    end loop;
    return idx;
  end getNextSetIndex;
  
  -- Generates the control signals lookup table.
  pure function schedLookup_gen return schedLookup_type is
    variable result     : schedLookup_type;
    variable requesting : std_logic_vector(NUM_MASTERS-1 downto 0);
    variable resIdx     : natural;
    variable mstIdx     : natural;
  begin
    
    -- Loop over all possible access control signals, represented in the
    -- requesting vector within the loop.
    for masters in 0 to 2**NUM_MASTERS-1 loop
      requesting := uint2vect(masters, NUM_MASTERS);
      
      -- Loop over the possibilities for the previous master which had access
      -- to the slave.
      for prevMaster in 0 to 2**NUM_MASTERS_LOG2-1 loop
        
        -- Determine the index within the control signal lookup table
        -- associated with this loop iteration.
        resIdx := masters * 2**NUM_MASTERS_LOG2 + prevMaster;
        
        -- If prevMaster is out of range, simply return master 0.
        if prevMaster >= NUM_MASTERS then
          result(resIdx) := (others => '0');
          next;
        end if;
        
        -- Call getNextSetIndex to determine which masters should get control
        -- over the slave next.
        mstIdx := getNextSetIndex(prevMaster, requesting);
        result(resIdx) := uint2vect(mstIdx, NUM_MASTERS_LOG2);
        
      end loop;
      
    end loop;
    
    -- Return the constructed table.
    return result;
    
  end schedLookup_gen;
  
  -- Control signal lookup table, generated during design elaboration using the
  -- function above.
  constant SCHED_LOOKUP         : schedLookup_type := schedLookup_gen;
  
  -- Master bus signals using the alternate bus timing which uses request-ack
  -- handshaking instead of a busy signal, converted from the input bus by
  -- the bus_busy2ack instances.
  signal mst2arb_alt            : bus_mst2slv_alt_array(NUM_MASTERS-1 downto 0);
  signal arb2mst_alt            : bus_slv2mst_alt_array(NUM_MASTERS-1 downto 0);
  
  -- The requesting signal has a signal for each master bus, which is high
  -- when the master is requesting something.
  signal requesting             : std_logic_vector(NUM_MASTERS-1 downto 0);
  
  -- These signals select the currently active master for the request and
  -- result stage respectively (resultSelect is simply requestSelect delayed
  -- by one cycle).
  signal requestSelect          : select_type;
  signal resultSelect           : select_type;
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- Instantiate bus_busy2ack convertors
  -----------------------------------------------------------------------------
  -- These devices will monitor the masters and buffer requests when the master
  -- makes them. They will also raise the busy signal accordingly. Only when we
  -- assert the ack signal will the busy signal be released and the result be
  -- returned.
  busy2ack_convert_gen: for mst in 0 to NUM_MASTERS-1 generate
    busy2ack_convert_inst: entity rvex.bus_busy2ack
      port map (
        
        -- System control.
        reset                   => reset,
        clk                     => clk,
        clkEn                   => clkEn,
        
        -- Busses.
        mst2conv                => mst2arb(mst),
        conv2mst                => arb2mst(mst),
        conv2slv                => mst2arb_alt(mst),
        slv2conv                => arb2mst_alt(mst)
      );
  end generate;
  
  -----------------------------------------------------------------------------
  -- Determine active master
  -----------------------------------------------------------------------------
  -- Generate the requesting signal.
  requesting_gen: for mst in 0 to NUM_MASTERS-1 generate
    requesting(mst) <= bus_requesting(mst2arb_alt(mst));
  end generate;
  
  -- Use the lookup table to select the currently active master in the request
  -- stage.
  requestSelect <= SCHED_LOOKUP(vect2uint(requesting & resultSelect));
  
  -- Register the requestSelect signal when the slave is ready to accept a new
  -- command to get the resultSelect signal.
  process (clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        resultSelect <= (others => '0');
      elsif slv2arb.busy = '0' and clkEn = '1' then
        resultSelect <= requestSelect;
      end if;
    end if;
  end process;
  
  -----------------------------------------------------------------------------
  -- Perform bus muxing
  -----------------------------------------------------------------------------
  -- Mux between the requests from the masters.
  arb2slv <=
    mst2arb_alt(vect2uint(requestSelect))
    when vect2uint(requestSelect) < NUM_MASTERS
    else mst2arb_alt(0);
  
  -- Demux the result.
  result_demux_gen: for mst in 0 to NUM_MASTERS-1 generate
    arb2mst_alt(mst) <= (
      readData  => slv2arb.readData,
      fault     => slv2arb.fault,
      ack       => not slv2arb.busy
    );
  end generate;
  
end Behavioral;

