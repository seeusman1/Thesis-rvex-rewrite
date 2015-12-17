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
--
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
use IEEE.std_logic_misc.all;
use IEEE.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library rvex;
use rvex.common_pkg.all;
use rvex.core_pkg.all;
use rvex.utils_pkg.all;

use work.constants.all;

--
-- Register map
--
--  0x8000          | Interface version  |  R  | Version of this register interface.
--  0x8004          | Card configuration |  R  | Build-time configuration of the card
--
--  0x9000          | Run register       | R/W | Indicates if a context should run.
--  0x9008          | Idle register      |  R  | Indicates if a context is idle.
--  0x9010          | Done register      |  R  | Indicates if a context is done executing.
--  0x9018          | Reset register     | R/W | Reset a context.
--  0x9200 - 0x93F8 | Reset vectors      | R/W | The value of the PC of a context when reset.
--
--  0x9800          | Interrupt request  | R/W | Trigger an interrupt on a context.
--  0x9808          | Interrupt ack      |  R  | Acknowledgment of interrupt on context.
--  0x9900 - 0x0AF8 | Interrupt ID's     | R/W | Interrupt identification, loaded in to trap argument register.
--
--  One bit per context, 8 contexts per instance

entity registers is
  generic (
    NO_RVEX                 : integer;
    NO_CONTEXTS             : integer
  );
  port (
    -- Active high reset
    reset                   : in  std_logic;

    ---------------------------------------------------------------------------
    -- DMA Register interface
    ---------------------------------------------------------------------------
    reg_clk                 : in  std_logic;
    reg_wr_addr             : in  std_logic_vector(0 to REG_ADDR_WIDTH-1);
    reg_wr_en               : in  std_logic;
    reg_wr_be               : in  std_logic_vector(0 to CORE_BE_WIDTH-1);
    reg_wr_data             : in  std_logic_vector(0 to CORE_DATA_WIDTH-1);
    reg_rd_addr             : in  std_logic_vector(0 to REG_ADDR_WIDTH-1);
    reg_rd_be               : in  std_logic_vector(0 to CORE_BE_WIDTH-1);
    reg_rd_data             : out std_logic_vector(0 to CORE_DATA_WIDTH-1)
  );
end entity;

architecture behavioral of registers is
  constant REG_IFACE_VERSION : integer := 1;

  --TODO: Generate an error if CORE_DATA_WIDTH != 64
  --TODO: Generate an error if CFG.numContextsLog > 8 or NO_RVEX > 8
  --TODO: Instead of the above maybe give an error if NO_CONTEXTS * NO_RVEX > 64 or something.

  signal read_data   : std_logic_vector(0 to CORE_DATA_WIDTH-1);
  signal rd_data_out : std_logic_vector(0 to CORE_DATA_WIDTH-1);

begin

  handle_reg_read: process(reg_rd_addr) is
  begin
    case vect2uint(reg_rd_addr) is
      -- Interface version
      when 16#8000#/8 => read_data <= uint2vect(REG_IFACE_VERSION, 64);
      -- Card configuration, top 32-bits is the amount of processors, lower 32-bits is the
      -- amount of contexts per processor
      when 16#8008#/8 => read_data <= uint2vect(NO_RVEX, 32) & uint2vect(NO_CONTEXTS, 32);
      when others => read_data <= (others => '0');
    end case;
  end process;
  
  transition_rvex2dma_reg_clk: process(reg_clk) is
  begin
    if rising_edge(reg_clk) then
      if reset = '1' then
        -- register interface
        rd_data_out  <= (others => '0');
      else
        -- register interface
        rd_data_out  <= read_data;
      end if;
    end if;
  end process;

  reg_rd_data <= rd_data_out;

end behavioral;

