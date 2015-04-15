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
use IEEE.numeric_std.all;

library rvex;
use rvex.bus_pkg.all;
use rvex.common_pkg.all;
use rvex.utils_pkg.all;

use work.constants.all;

entity s2c_bus_bridge is
  port (
    ---------------------------------------------------------------------------
    -- System control
    ---------------------------------------------------------------------------
    -- Active high synchronous reset input.
    reset                   : in  std_logic;
    
    -- Clock inputs, registers are rising edge triggered.
    -- We assume that sys_clk runs at an integer multiple of s2c_clk
    s2c_clk                 : in  std_logic;
    sys_clk                 : in  std_logic;
    
    ---------------------------------------------------------------------------
    -- s2c bus
    ---------------------------------------------------------------------------
    sop                     : in  std_logic; --
    eop                     : in  std_logic; -- TODO: use signal to invalidate packet
    err                     : in  std_logic; --
    data                    : in  std_logic_vector(0 to CORE_DATA_WIDTH-1); --
    valid                   : in  std_logic_vector(0 to CORE_REMAIN_WIDTH-1); --
    src_rdy                 : in  std_logic; --
    dst_rdy                 : out std_logic; --
    abort                   : in  std_logic; --
    abort_ack               : out std_logic; --
    user_rst_n              : in  std_logic; --

    apkt_req                : in  std_logic; -- Addressed Packet Interface
    apkt_ready              : out std_logic; --
    apkt_addr               : in  std_logic_vector(0 to 63); --
    apkt_bcount             : in  std_logic_vector(0 to 9); --

    ---------------------------------------------------------------------------
    -- Master bus
    ---------------------------------------------------------------------------
    bus2dma                 : in  bus_slv2mst_type; --
    dma2bus                 : out bus_mst2slv_type --
  );
end s2c_bus_bridge;


--=============================================================================
architecture Behavioral of s2c_bus_bridge is
--=============================================================================

  type transmit_state is (wait_pkt, wait_data, write_low, write_high);

  signal curr_addr          : rvex_address_type;
  signal next_addr          : rvex_address_type;

  signal curr_state         : transmit_state;
  signal next_state         : transmit_state;

--=============================================================================
begin -- architecture
--=============================================================================

  handle_cmd: process (sys_clk, reset, user_rst_n,
                       next_addr, curr_addr, next_state, curr_state,
                       apkt_req, apkt_addr,
                       data, valid, eop,
                       bus2dma.ack) is
  begin
    if reset = '1' or user_rst_n = '0' then
      dst_rdy <= '0';
      abort_ack <= '0';
      apkt_ready <= '0';

      dma2bus.writeMask <= "1111";
      dma2bus.flags <= BUS_FLAGS_DEFAULT;
      dma2bus.writeEnable <= '0';
      dma2bus.readEnable <= '0';

      curr_state <= wait_pkt;
      next_state <= wait_pkt;

    elsif rising_edge(sys_clk) then
      curr_state <= next_state;
      curr_addr <= next_addr;

    else
      if apkt_req = '1' and curr_state = wait_pkt then
        apkt_ready <= '1';
      else
        apkt_ready <= '0';
      end if;

      if curr_state = write_high then
        dst_rdy <= '1';
      else
        dst_rdy <= '0';
      end if;

      case curr_state is
        when wait_pkt =>
          if apkt_req = '1' then
            next_addr <= apkt_addr(0 to 31);
            next_state <= wait_data;
          end if;

        when wait_data =>
          if src_rdy = '1' then
            dma2bus.address <= curr_addr;
            dma2bus.writeData <= data(0 to 31);
            dma2bus.writeEnable <= '1';

            next_addr <= uint2vect(vect2uint(curr_addr) + 4, 32);

            -- Correctly handle the last word of a packet
            if eop = '1' and vect2uint(valid) <= 4
                  and vect2uint(valid) > 0 then
              case valid is
                when "001" => dma2bus.writeMask <= "0001";
                when "010" => dma2bus.writeMask <= "0011";
                when "011" => dma2bus.writeMask <= "0111";
                when "100" => dma2bus.writeMask <= "1111";
                when others => null;
              end case;
              next_state <= write_high;
            else
              dma2bus.writeMask <= "1111";

              next_state <= write_low;
            end if;
          end if;

        when write_low =>
          if bus2dma.ack = '1' then
            -- Write next data element, writes still enabled
            dma2bus.address <= curr_addr;
            dma2bus.writeData <= data(32 to 63);

            -- Handle the last word of a packet
            if eop = '1' then
              case valid is
                when "101" => dma2bus.writeMask <= "0001";
                when "110" => dma2bus.writeMask <= "0011";
                when "111" => dma2bus.writeMask <= "0111";
                when "000" => dma2bus.writeMask <= "1111";
                when others => null;
              end case;
            else
              dma2bus.writeMask <= "1111";
            end if;

            next_addr <= uint2vect(vect2uint(curr_addr) + 4, 32);
            next_state <= write_high;
          end if;

        when write_high =>
          if bus2dma.ack = '1' then
            dma2bus.writeEnable <= '0';

            if eop = '0' then
              next_state <= wait_data;
            else
              next_state <= wait_pkt;
            end if;
          end if;
      end case;

    end if;
  end process;

end Behavioral;
