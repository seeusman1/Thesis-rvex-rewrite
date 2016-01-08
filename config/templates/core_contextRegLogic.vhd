-- r-VEX processor
-- Copyright (C) 2008-2015 by TU Delft.
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

-- Copyright (C) 2008-2015 by TU Delft.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library rvex;
use rvex.common_pkg.all;
use rvex.utils_pkg.all;
use rvex.core_pkg.all;
use rvex.core_intIface_pkg.all;
use rvex.core_ctrlRegs_pkg.all;
use rvex.core_trap_pkg.all;

--=============================================================================
-- This entity contains the specifications and logic for the control registers
-- which are specific to a context.
-------------------------------------------------------------------------------
entity core_contextRegLogic is
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
    
    -- Active high synchronous reset input per context. Unlike reset, this is
    -- affected by clkEn, and register implementations may override the reset
    -- behavior.
    ctxtReset                   : in  std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
    
    -- Clock input, registers are rising edge triggered.
    clk                         : in  std_logic;
    
    -- Active high global clock enable input.
    clkEn                       : in  std_logic;
    
    @PORT_DECL
    ---------------------------------------------------------------------------
    -- Interface with the control registers and bus logic
    ---------------------------------------------------------------------------
    -- Global control register address. Only bits 8..0 are used.
    creg2cxreg_addr             : in  rvex_address_array(2**CFG.numContextsLog2-1 downto 0);
    
    -- Origin of the context control register command. '0' for core access, '1'
    -- for debug access.
    creg2cxreg_origin           : in  std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
    
    -- Write command.
    creg2cxreg_writeEnable      : in  std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
    creg2cxreg_writeMask        : in  rvex_mask_array(2**CFG.numContextsLog2-1 downto 0);
    creg2cxreg_writeData        : in  rvex_data_array(2**CFG.numContextsLog2-1 downto 0);
    
    -- Read command and reply.
    creg2cxreg_readEnable       : in  std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
    cxreg2creg_readData         : out rvex_data_array(2**CFG.numContextsLog2-1 downto 0)
    
  );
end core_contextRegLogic;

--=============================================================================
architecture Behavioral of core_contextRegLogic is
--=============================================================================
  
  @REG_DECL
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  gbregs: process (clk) is
    @VAR_DECL
  begin
    if rising_edge(clk) then
      for c in 0 to 2**CFG.numContextsLog2-1 loop
        if reset = '1' then
          @REG_RESET
          cxreg2creg_readData(c) <= (others => '0');
        elsif clkEn = '1' then
          if ctxtReset(c) = '1' then
            @REG_RESET
            cxreg2creg_readData(c) <= (others => '0');
            @RESET_IMPL
          else
            @IMPL
          end if;
        end if;
      end loop;
    end if;
  end process;
  
end Behavioral;

