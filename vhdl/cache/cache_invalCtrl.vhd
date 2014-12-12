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

-- Refer to reconfCache_pkg.vhd for configuration constants and most
-- documentation.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library rvex;
use rvex.cache_pkg.all;
use rvex.cache_intIface_pkg.all;
use rvex.cache_instr_pkg.all;
use rvex.cache_data_pkg.all;

entity cache_invalCtrl is
  port (
    
    -- Inputs from arbiters.
    arbToInvalCtrl            : in  RC_arbiterInvalOutput_array;
    
    -- External invalidation bus.
    extToInvalCtrl            : in  reconfCache_invalIn;
    invalCtrlToExt            : out reconfCache_invalOut;
    
    -- Outputs to instruction and data caches.
    invalICache               : out reconfICache_invalIn;
    invalDCache               : out reconfDCache_invalIn
    
  );
end cache_invalCtrl;

architecture Behavioral of cache_invalCtrl is
  
  -- Merged invalidation signals.
  signal invalEnable          : std_logic;
  signal invalAddr            : std_logic_vector(RC_BUS_ADDR_WIDTH-1 downto 0);
  
begin
  
  -- Connect the flush signals.
  invalICache.flush <= extToInvalCtrl.flushICache;
  invalDCache.flush <= extToInvalCtrl.flushDCache;
  
  -- Connect the invalidation source signals.
  connect_inval_source: for i in 0 to RC_NUM_ATOMS-1 generate
    invalDCache.invalSource(i) <= arbToInvalCtrl(i).inval;
  end generate;
  
  -- Merge all the invalidation inputs together.
  merge_inval_request: process (arbToInvalCtrl, extToInvalCtrl) is
  begin
    invalEnable <= extToInvalCtrl.invalEnable;
    invalAddr <= extToInvalCtrl.invalAddr;
    for i in 0 to RC_NUM_ATOMS-1 loop
      if arbToInvalCtrl(i).inval = '1' then
        invalEnable <= '1';
        invalAddr <= arbToInvalCtrl(i).addr;
      end if;
    end loop;
  end process;
  
  -- Connect the invalidation request outputs for the data and instruction
  -- caches.
  invalICache.invalEnable <= invalEnable;
  invalICache.invalAddr   <= invalAddr;
  invalDCache.invalEnable <= invalEnable;
  invalDCache.invalAddr   <= invalAddr;
  
  -- Generate the stall and error signals.
  gen_status_signals: process (arbToInvalCtrl, extToInvalCtrl) is
    variable numActiveRequests: natural;
  begin
    invalCtrlToExt.stall <= '0';
    invalCtrlToExt.error <= '0';
    numActiveRequests := 0;
    if extToInvalCtrl.invalEnable = '1' then
      numActiveRequests := 1;
    end if;
    for i in 0 to RC_NUM_ATOMS-1 loop
      if arbToInvalCtrl(i).inval = '1' then
        invalCtrlToExt.stall <= '1';
        numActiveRequests := numActiveRequests + 1;
      end if;
    end loop;
    if numActiveRequests > 1 then
      invalCtrlToExt.error <= '1';
    end if;
  end process;
  
end Behavioral;

