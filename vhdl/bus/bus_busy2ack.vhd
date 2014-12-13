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
-- This entity converts between the two bus formats specified in bus_pkg.
-------------------------------------------------------------------------------
entity bus_busy2ack is
--=============================================================================
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
    -- Master bus, with standard timing (based on busy signal).
    mst2conv                    : in  bus_mst2slv_type;
    conv2mst                    : out bus_slv2mst_type;
    
    -- Slave bus, with alternate timing (based on keeping the request up until
    -- ack is returned).
    conv2slv                    : out bus_mst2slv_alt_type;
    slv2conv                    : in  bus_slv2mst_alt_type
    
  );
end bus_busy2ack;

--=============================================================================
architecture Behavioral of bus_busy2ack is
--=============================================================================
  
  -- Holding register for bus requests for while busy is high/ack has not been
  -- returned yet.
  signal mst2conv_r             : bus_mst2slv_type;
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -- Generate a holding register for the request. This is used in place of the
  -- combinatorial signal from the master while busy is high/ack is low.
  request_holding_reg: process (clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        mst2conv_r <= BUS_MST2SLV_IDLE;
      elsif slv2conv.ack = '1' and clkEn = '1' then
        mst2conv_r <= mst2conv;
      end if;
    end if;
  end process;
  
  -- Select between the combinatorial signal and the holding register.
  conv2slv <= bus_mst2slv_alt_type(mst2conv) when slv2conv.ack = '1'
    else bus_mst2slv_alt_type(mst2conv_r);
  
  -- Forward the result from the slave.
  conv2mst.readData <= slv2conv.readData;
  conv2mst.fault <= slv2conv.fault;
  
  -- Determine busy signal.
  conv2mst.busy <= bus_requesting(mst2conv_r) and not slv2conv.ack;
  
end Behavioral;

