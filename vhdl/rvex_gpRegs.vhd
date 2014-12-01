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
use work.rvex_intIface_pkg.all;

--=============================================================================
-- This entity contains the general purpose register file and associated
-- forwarding logic.
-------------------------------------------------------------------------------
entity rvex_gpRegs is
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
    
    -- Active high stall signal for each lane group.
    stall                       : in  std_logic_vector(CFG.numLaneGroupsLog2-1 downto 0);

    -----------------------------------------------------------------------------
    -- Decoded configuration signals
    -----------------------------------------------------------------------------
    -- Specifies the context associated with the indexed pipelane group.
    cfg2any_context             : in  rvex_3bit_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -----------------------------------------------------------------------------
    -- Read and write ports
    -----------------------------------------------------------------------------
    -- Read ports. There's two for each lane. The read value is provided for all
    -- lanes which receive forwarding information.
    pl2gpreg_readPorts           : in  pl2gpreg_readPort_array(2*2**CFG.numLanesLog2-1 downto 0);
    gpreg2pl_readPorts           : out gpreg2pl_readPort_array(2*2**CFG.numLanesLog2-1 downto 0);
    
    -- Write ports and forwarding information. There's one write port for each
    -- lane.
    pl2gpreg_writePorts          : in  pl2gpreg_writePort_array(2**CFG.numLanesLog2-1 downto 0);
    
    ---------------------------------------------------------------------------
    -- Debug interface
    ---------------------------------------------------------------------------
    -- When claim is high (and stall is high, which will always be the case)
    -- one of the processor ports should be connected to the port below. stall
    -- will always stay high one cycle longer than claim, so any read command
    -- which the processor was requesting will be requested again so the output
    -- is valid when stall is released again.
    
    -- When high, connect the bus to the general purpose register file.
    creg2gpreg_claim            : in  std_logic;
    
    -- Register address and context.
    creg2gpreg_addr             : in  rvex_gpRegAddr_type;
    creg2gpreg_ctxt             : in  std_logic_vector(CFG.numContextsLog2-1 downto 0);
    
    -- Write command.
    creg2gpreg_writeEnable      : in  std_logic;
    creg2gpreg_writeData        : in  rvex_data_type;
    
    -- Read data returned one cycle after the claim.
    gpreg2creg_readData         : out rvex_data_type
    
  );
end rvex_gpRegs;

--=============================================================================
architecture Behavioral of rvex_gpRegs is
--=============================================================================
  
--=============================================================================
begin -- architecture
--=============================================================================
  
end Behavioral;

