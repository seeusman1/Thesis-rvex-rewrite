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
use rvex.common_pkg.all;
use rvex.utils_pkg.all;
use rvex.bus_pkg.all;

use work.constants.all;

entity c2s_bus_bridge is
  port (
    ---------------------------------------------------------------------------
    -- System control
    ---------------------------------------------------------------------------
    -- Active high synchronous reset input.
    reset                   : in  std_logic;
    
    -- Clock inputs, registers are rising edge triggered.
    -- We assume that sys_clk runs at an integer multiple of c2s_clk
    c2s_clk                 : in  std_logic;
    sys_clk                 : in  std_logic;
    
    ---------------------------------------------------------------------------
    -- c2s bus, runs in c2s_clk domain
    ---------------------------------------------------------------------------
    sop                     : out std_logic; --
    eop                     : out std_logic; --
    data                    : out std_logic_vector(0 to CORE_DATA_WIDTH-1); --
    valid                   : out std_logic_vector(0 to CORE_REMAIN_WIDTH-1); --
    src_rdy                 : out std_logic; --
    dst_rdy                 : in  std_logic; --
    abort                   : in  std_logic; --
    abort_ack               : out std_logic; --
    user_rst_n              : in  std_logic; --

    apkt_req                : in  std_logic; -- Addressed Packet Interface
    apkt_ready              : out std_logic; --
    apkt_addr               : in  std_logic_vector(0 to 63); --
    apkt_bcount             : in  std_logic_vector(0 to 9); --
    apkt_eop                : in  std_logic;

    ---------------------------------------------------------------------------
    -- Master bus, runs in sys_clk domain
    ---------------------------------------------------------------------------
    bus2dma                 : in  bus_slv2mst_type; --
    dma2bus                 : out bus_mst2slv_type --
  );
end c2s_bus_bridge;


--=============================================================================
architecture Behavioral of c2s_bus_bridge is
--=============================================================================

  type transmit_state is (wait_pkt, read_low, read_high, send_data);

  signal curr_addr          : rvex_address_type;
  signal next_addr          : rvex_address_type;
  signal curr_bcnt          : std_logic_vector(0 to 9);
  signal next_bcnt          : std_logic_vector(0 to 9);

  signal curr_state         : transmit_state;
  signal next_state         : transmit_state;

--=============================================================================
begin -- architecture
--=============================================================================

  if reset = '1' or user_rst_n = '0' then
    sop <= '0';
    eop <= '0';
    data <= (others => '0');
    valid <= "000";
    src_rdy <= '0';
    abort_ack <= '0';
    apkt_ready <= '0';

    dma2bus <= BUS_MST2SLV_IDLE;

    curr_state <= wait_pkt;
    next_state <= wait_pkt;
  else

    apkt_ready <= curr_state = wait_pkt and apkt_req;

    dma2bus.readEnable <= curr_state = read_low or curr_state = read_high;

    case curr_state is
      when wait_pkt =>
        if apkt_req = '1' then
          next_addr <= apkt_addr(0 to 31) + 4;
          dma2bus.address <= apkt_addr(0 to 31);
          next_bcnt <= apkt_bcount;

          sop <= '1';
          valid <= "000";

          if vect2uint(apkt_bcount) <= 4 then
            next_state <= read_low;
          else
            next_state <= read_high;
          end if;
        end if;

      when read_high =>
        if bus2dma.ack = '1' then
          data(32 to 63) <= bus2dma.readData;

          -- Read next data element
          dma2bus.address <= curr_addr;
          next_addr <= uint2vect(vect2uint(curr_addr) + 4, 32);

          -- Correctly handle the last word of a packet
          if vect2uint(curr_bcnt) <= 8 and vect2uint(curr_bcnt) > 4 then
            case vect2uint(curr_bcnt) is
              when 5 => valid <= "101";
              when 6 => valid <= "110";
              when 7 => valid <= "111";
              when 8 => valid <= "000";
              when others => null;
            end case;
            eop <= '1';
          end if;

          next_state <= read_low;
        end if;

      when read_low =>
        if bus2dma.ack = '1' then
          -- Read data
          data(0 to 31) <= bus2dma.readData;

          -- Disable reads
          dma2bus.readEnable <= '0';

          -- Increment address
          next_addr <= uint2vect(vect2uint(curr_addr) + 4, 32);

          -- Handle the last word of a packet
          if vect2uint(curr_bcnt) <= 4 then
            valid <= curr_bcnt(0 to 2);
            eop <= '1';
          end if;

          -- Send data over DMA
          src_rdy <= '1';

          -- State transition
          next_state <= send_data;
        end if;

      when send_data =>
        if dst_rdy = '1' then
          -- Give us the time to request new data
          src_rdy <= '0';

          -- Reset sop signal
          sop <= '0';

          -- Decrement byte count
          -- This may underflow, as we have already determined what state we will go to
          next_bcnt <= uint2vect(vect2uint(curr_bcnt) - 8, 3);

          if vect2uint(curr_bcnt) <= 8 then
            next_state <= read_high;
          else
            next_state <= wait_pkt;
          end if;
        end if;
    end case;

  end if;

  handle_cmd: process (sys_clk) is
  begin
    if rising_edge(sys_clk) then
      if reset = '0' and user_rst_n = '1' then
        if (curr_state /= next_state) then
          curr_state <= next_state;
          curr_addr  <= next_addr;
          curr_bcnt  <= next_bcnt;
        end if;
      end if;
    end if;
  end process;

end Behavioral;
