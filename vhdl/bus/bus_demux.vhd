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
use rvex.simutils_pkg.all;
use rvex.bus_pkg.all;

--=============================================================================
-- Splits the bus coming from a master up into a number of slave busses, which
-- are selected based upon the address.
-------------------------------------------------------------------------------
entity bus_demux is
--=============================================================================
  generic (
    
    -- Defines the start and end addresses for each slave bus, and implicitely,
    -- the number of slave busses. The start address is inclusive, the end
    -- address is exclusive.
    START_ADDR                  : rvex_address_array;
    END_ADDR                    : rvex_address_array;
    
    -- When the master attempts to access undefined memory, the following 
    -- fault code is returned.
    OOR_FAULT_CODE              : rvex_data_type := (others => '1')
    
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
    -- Incoming bus from the master.
    mst2demux                   : in  bus_mst2slv_type;
    demux2mst                   : out bus_slv2mst_type;
    
    -- Outgoing busses to the slaves.
    demux2slv                   : out bus_mst2slv_array(START_ADDR'range);
    slv2demux                   : in  bus_slv2mst_array(START_ADDR'range)
    
  );
end bus_demux;

--=============================================================================
architecture Behavioral of bus_demux is
--=============================================================================
  
  -- Checks if value lies within the specified range.
  function inRange(
    value     : rvex_address_type;
    startAddr : rvex_address_type;
    endAddr   : rvex_address_type
  ) return boolean is
  begin
    return unsigned(value) >= unsigned(startAddr)
       and unsigned(value) <  unsigned(endAddr);
  end inRange;
  
  -- Checks if a pair of ranges overlaps.
  function overlapping(
    startA    : rvex_address_type;
    endA      : rvex_address_type;
    startB    : rvex_address_type;
    endB      : rvex_address_type
  ) return boolean is
  begin
    return inRange(startB, startA, endA)
        or inRange(startA, startB, endB);
  end overlapping;
  
  -- Checks if any pair of the specified ranges overlap.
  function overlapping(
    startAddr : rvex_address_array;
    endAddr   : rvex_address_array
  ) return boolean is
  begin
    for a in startAddr'low to startAddr'high-1 loop
      for b in a+1 to startAddr'high loop
        if overlapping(startAddr(a), endAddr(a), startAddr(b), endAddr(b)) then
          report integer'image(a) & " " & integer'image(b) severity note;
          return true;
        end if;
      end loop;
    end loop;
    return false;
  end overlapping;
  
  -- Number of slave busses.
  constant NUM_SLAVES           : natural := START_ADDR'length;
  
  -- log2 of the number of slave busses + 1; defines the width of the select
  -- signal for the (de)muxes. The extra option is needed for when an
  -- out-of-range address is requested.
  constant SEL_LOG2             : natural := integer(ceil(log2(real(NUM_SLAVES + 1))));
  
  -- Index of the selected bus, valid while the bus request is valid.
  signal selectRequest          : std_logic_vector(SEL_LOG2-1 downto 0);
  
  -- Index of the selected bus, valid after the bus request (so while the slave
  -- is busy and while the result is valid).
  signal selectResult           : std_logic_vector(SEL_LOG2-1 downto 0);
  
  -- Local signal for the muxed busy flag, as returned to the master.
  signal busy                   : std_logic;
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- Check configuration
  -----------------------------------------------------------------------------
  -- Make sure that the start address and end address arrays have equal ranges.
  assert (START_ADDR'left = END_ADDR'left) and (START_ADDR'right = END_ADDR'right)
    report "The ranges for START_ADDR and END_ADDR must match."
    severity failure;
  
  -- Make sure that there are no overlapping ranges.
  assert not overlapping(START_ADDR, END_ADDR)
    report "Overlapping address ranges are illegal."
    severity failure;
  
  -----------------------------------------------------------------------------
  -- Determine which slave should be accessed
  -----------------------------------------------------------------------------
  select_request_proc: process (mst2demux.address) is
  begin
    
    -- Choose out-of-range by default.
    selectRequest <= uint2vect(NUM_SLAVES, SEL_LOG2);
    
    -- Check if the address is in any of the ranges of the slaves; if so,
    -- select that slave bus instead.
    for i in 0 to NUM_SLAVES-1 loop
      if inRange(
        mst2demux.address,
        START_ADDR(START_ADDR'low + i),
        END_ADDR(END_ADDR'low + i)
      ) then
        selectRequest <= uint2vect(i, SEL_LOG2);
      end if;
    end loop;
    
  end process;
  
  -- Delay the selectRequest signal to align it with the result.
  select_result_proc: process (clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        selectResult <= (others => '0');
      elsif busy = '0' and clkEn = '1' then
        selectResult <= selectRequest;
      end if;
    end if;
  end process;
  
  -----------------------------------------------------------------------------
  -- Perform command demuxing
  -----------------------------------------------------------------------------
  command_demux_gen: for i in 0 to NUM_SLAVES-1 generate
    demux2slv(i) <= bus_gate(mst2demux, vect2uint(selectRequest) = i);
  end generate;
  
  -----------------------------------------------------------------------------
  -- Perform result muxing
  -----------------------------------------------------------------------------
  result_mux_proc: process (slv2demux, selectResult) is
    variable muxed  : bus_slv2mst_type;
  begin
    
    if vect2uint(selectResult) < NUM_SLAVES then
      
      -- Select the result data from the selected slave bus.
      muxed := slv2demux(vect2uint(selectResult));
      
    else
      
      -- Raise the bus fault specified for out-of-range accesses.
      muxed := (
        readData  => OOR_FAULT_CODE,
        fault     => '1',
        busy      => '0'
      );
      
    end if;
    
    -- Drive output signals.
    demux2mst <= muxed;
    busy <= muxed.busy;
    
  end process;
  
end Behavioral;

