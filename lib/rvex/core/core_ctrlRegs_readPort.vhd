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
use rvex.core_intIface_pkg.all;

--=============================================================================
-- This instantiates an additional synchronous read port for an
-- rvex_ctrlRegs_bank instance.
-------------------------------------------------------------------------------
entity core_ctrlRegs_readPort is
--=============================================================================
  generic (
    
    ---------------------------------------------------------------------------
    -- Configuration
    ---------------------------------------------------------------------------
    -- Starting address for the registers.
    OFFSET                      : natural;
    
    -- Number of words.
    NUM_WORDS                   : natural
    
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
    -- Register interface
    ---------------------------------------------------------------------------
    -- Connect this to the creg2logic output of the rvex_ctrlRegs_bank
    -- instance.
    creg2logic                  : in  creg2logic_array(OFFSET to OFFSET + NUM_WORDS - 1);
    
    ---------------------------------------------------------------------------
    -- Read port
    ---------------------------------------------------------------------------
    -- Address for the request.
    addr                        : in  rvex_address_type;
    
    -- Active high read enable signal.
    readEnable                  : in  std_logic;
    
    -- Read data.
    readData                    : out rvex_data_type
    
  );
end core_ctrlRegs_readPort;

--=============================================================================
architecture Behavioral of core_ctrlRegs_readPort is
--=============================================================================
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -- Process bus reads.
  bus_reads: process (clk) is
    variable a: integer;
  begin
    if rising_edge(clk) then
      if reset = '1' then
        readData <= (others => RVEX_UNDEF);
      elsif clkEn = '1' then
        if readEnable = '1' then
          a := vect2uint(addr(31 downto 2));
          if a >= OFFSET and a < OFFSET + NUM_WORDS then
            readData <= creg2logic(a).readData;
          else
            readData <= (others => RVEX_UNDEF);
          end if;
        else
          readData <= (others => RVEX_UNDEF);
        end if;
      end if;
    end if;
  end process;
  
end Behavioral;

