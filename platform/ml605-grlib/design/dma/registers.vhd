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
    reg_rd_data             : out std_logic_vector(0 to CORE_DATA_WIDTH-1);

    ---------------------------------------------------------------------------
    -- Run control interfaces
    ---------------------------------------------------------------------------
    rctrl_clk               : in  std_logic;
    rctrl2rv                : out rvex_rctrl2rv_array(NO_CONTEXTS*NO_RVEX-1 downto 0);
    rv2rctrl                : in  rvex_rv2rctrl_array(NO_CONTEXTS*NO_RVEX-1 downto 0)
  );
end entity;

architecture behavioral of registers is
  constant REG_IFACE_VERSION : integer := 1;

  -- Registers are 64-bit. With a maximum of 8 contexts per processor we support 8 processor instances
  type reg_array is array(natural range <>) of std_logic_vector(0 to CORE_DATA_WIDTH-1);
  type addr_reg_array is array(natural range <>) of rvex_address_array(0 to 8*8-1);

  --TODO: Generate an error if CORE_DATA_WIDTH != 64
  --TODO: Generate an error if CFG.numContextsLog > 8 or NO_RVEX > 8

  signal read_data   : std_logic_vector(0 to CORE_DATA_WIDTH-1);
  signal rd_data_out : std_logic_vector(0 to CORE_DATA_WIDTH-1);

  signal run         : reg_array(0 to 2); -- dma2rvex
  signal idle        : reg_array(0 to 2); -- rvex2dma
  signal done        : reg_array(0 to 2); -- rvex2dma
  signal reset_ctxt  : reg_array(0 to 2); -- dma2rvex
  signal resetVect   : addr_reg_array(0 to 2); -- dma2rvex

  signal irq         : reg_array(0 to 2);
  --signal irqAck       : std_logic_vector(0 to CORE_DATA_WIDTH-1);
  signal irqID       : addr_reg_array(0 to 2);

  function apply_write_mask(orig_data, wr_data, mask: std_logic_vector(0 to CORE_DATA_WIDTH-1))
                            return std_logic_vector is
  begin
    return (orig_data AND NOT mask) OR (wr_data AND mask);
  end apply_write_mask;

  function apply_write_mask_32(orig_data, wr_data, mask: std_logic_vector(0 to 31))
                               return std_logic_vector is
  begin
    return (orig_data AND NOT mask) OR (wr_data AND mask);
  end apply_write_mask_32;

begin

  -- NB. We assume that all accesses are 64-bit, so ignore *_be
  handle_reg_write: process(reg_wr_addr, reg_wr_en, reg_wr_data, reg_wr_be) is
    variable mask : std_logic_vector(0 to CORE_DATA_WIDTH-1);
    variable cur_vec : integer;
  begin
    for i in 0 to 7 loop
      mask(i*8 to i*8+7) := (others => reg_wr_be(i));
    end loop;

    run(0) <= run(1);
    reset_ctxt(0) <= reset_ctxt(1);
    resetVect(0) <= resetVect(1);

    if reg_wr_en = '1' then
      case vect2uint(reg_wr_addr) is
        when 16#9000#/8 => run(0)        <= apply_write_mask(run(0), reg_wr_data, mask);
        when 16#9018#/8 => reset_ctxt(0) <= apply_write_mask(reset_ctxt(0), reg_wr_data, mask);
        when others =>
          if vect2uint(reg_wr_addr) >= 16#9200#/8 and vect2uint(reg_wr_addr) < 16#9400#/8 then
            cur_vec := vect2uint(reg_wr_addr(REG_ADDR_WIDTH-6 to REG_ADDR_WIDTH-1));
            resetVect(0)(cur_vec) <=
                  apply_write_mask_32(resetVect(0)(cur_vec), reg_wr_data(32 to 63), mask(32 to 63));
          end if;
      end case;
    end if;
  end process;

  handle_reg_read: process(reg_rd_addr, run(1), idle(2), done(2), reset_ctxt(1)) is
  begin
    case vect2uint(reg_rd_addr) is
      -- Interface version
      when 16#8000#/8 => read_data <= uint2vect(REG_IFACE_VERSION, 64);
      -- Card configuration, top 32-bits is the amount of processors, lower 32-bits is the
      -- amount of contexts per processor
      when 16#8008#/8 => read_data <= uint2vect(NO_RVEX, 32) & uint2vect(NO_CONTEXTS, 32);
      when 16#9000#/8 => read_data <= run(1);
      when 16#9008#/8 => read_data <= idle(2);
      when 16#9010#/8 => read_data <= done(2);
      when 16#9018#/8 => read_data <= reset_ctxt(1);
      when others =>
        if vect2uint(reg_rd_addr) >= 16#9200#/8 and vect2uint(reg_rd_addr) < 16#9400#/8 then
          read_data(0 to 31) <= (others => '0');
          read_data(32 to 63) <= resetVect(1)(vect2uint(reg_rd_addr(REG_ADDR_WIDTH-6 to REG_ADDR_WIDTH-1)));
        else
          read_data <= (others => '0');
        end if;
    end case;
  end process;
  
  transition_rvex2dma_reg_clk: process(reset, reg_clk) is
  begin
    if reset = '1' then
      -- dma2rvex
      run(1)       <= (others => '0');
      reset_ctxt(1)     <= (others => '0');
      resetVect(1) <= (others => (others => '0'));

      -- rvex2dma
      idle(2)      <= (others => '0');
      done(2)      <= (others => '0');

      -- register interface
      rd_data_out  <= (others => '0');
    elsif rising_edge(reg_clk) then
      -- dma2rvex
      run(1)       <= run(0);
      reset_ctxt(1)     <= reset_ctxt(0);
      resetVect(1) <= resetVect(0);

      -- rvex2dma
      idle(2)      <= idle(1);
      done(2)      <= done(1);

      -- register interface
      rd_data_out  <= read_data;
    end if;
  end process;

  transition_rctrl_clk: process(reset, rctrl_clk) is
  begin
    if reset = '1' then
      -- dma2rvex
      run(2)       <= (others => '0');
      reset_ctxt(2)     <= (others => '0');
      resetVect(2) <= (others => (others => '0'));

      -- rvex2dma
      idle(1)      <= (others => '0');
      done(1)      <= (others => '0');
    elsif rising_edge(rctrl_clk) then
      -- dma2rvex
      run(2)       <= run(1);
      reset_ctxt(2)     <= reset_ctxt(1);
      resetVect(2) <= resetVect(1);

      -- rvex2dma
      idle(1)      <= idle(0);
      done(1)      <= done(0);
    end if;
  end process;

  reg_rd_data <= rd_data_out;

  rctrl_rvex_gen: for i in 0 to NO_RVEX-1 generate
    rctrl_context_gen: for j in 0 to NO_CONTEXTS-1 generate
      -- index the cores and contexts from the LSB first
      rctrl2rv(i*NO_CONTEXTS+j).run       <= run(2)       (63-(i*8 + j));
      rctrl2rv(i*NO_CONTEXTS+j).reset     <= reset_ctxt(2)(63-(i*8 + j));
      rctrl2rv(i*NO_CONTEXTS+j).resetVect <= resetVect(2) (i*8 + j);

      rctrl2rv(i*NO_CONTEXTS+j).irq       <= '0';
      rctrl2rv(i*NO_CONTEXTS+j).irqID     <= (others => '0');

      idle(0)(63-(i*8 + j)) <= rv2rctrl(i*NO_CONTEXTS+j).idle;
      done(0)(63-(i*8 + j)) <= rv2rctrl(i*NO_CONTEXTS+j).done;
    end generate;
  end generate;

  -- Define unconnected lines
  idle(0)(0 to CORE_DATA_WIDTH-NO_RVEX*NO_CONTEXTS-1) <= (others => '0');
  done(0)(0 to CORE_DATA_WIDTH-NO_RVEX*NO_CONTEXTS-1) <= (others => '0');

end behavioral;
