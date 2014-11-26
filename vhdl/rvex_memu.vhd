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
use work.rvex_pipeline_pkg.all;
use work.rvex_opcode_pkg.all;
--use work.rvex_opcodeMemu_pkg.all;

--=============================================================================
-- This entity contains the optional memory unit for a pipelane.
-------------------------------------------------------------------------------
entity rvex_memu is
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
    
    -- Active high stall input for the pipeline.
    stall                       : in  std_logic;
    
    ---------------------------------------------------------------------------
    -- Pipelane interface
    ---------------------------------------------------------------------------
    -- Opcode.
    pl2memu_opcode              : in  rvex_opcode_array(S_MEM to S_MEM);
    
    -- 32-bit operands.
    pl2memu_opAddr              : in  rvex_address_array(S_MEM to S_MEM);
    pl2memu_opData              : in  rvex_data_array(S_MEM to S_MEM);
    
    -- 32-bit output.
    memu2pl_result              : out rvex_data_array(S_MEM+L_MEM to S_MEM+L_MEM);
    
    ---------------------------------------------------------------------------
    -- Memory interface
    ---------------------------------------------------------------------------
    -- Data memory address, shared between read and write command.
    memu2dmsw_addr              : out rvex_address_array(S_MEM to S_MEM);
    
    -- Data memory write command.
    memu2dmsw_writeData         : out rvex_data_array(S_MEM to S_MEM);
    memu2dmsw_writeMask         : out rvex_mask_array(S_MEM to S_MEM);
    memu2dmsw_writeEnable       : out std_logic_vector(S_MEM to S_MEM);
    
    -- Data memory read command and result.
    memu2dmsw_readEnable        : out std_logic_vector(S_MEM to S_MEM);
    dmsw2memu_readData          : in  rvex_data_array(S_MEM+L_MEM to S_MEM+L_MEM)
    
  );
end rvex_memu;

--=============================================================================
architecture Behavioral of rvex_memu is
--=============================================================================
  
--=============================================================================
begin -- architecture
--=============================================================================
  
end Behavioral;

