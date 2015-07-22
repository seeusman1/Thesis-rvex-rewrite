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
    -- All buses run in the same clock domain
    clk                     : in  std_logic;

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

  signal curr_bcnt          : std_logic_vector(0 to 9);
  signal next_bcnt          : std_logic_vector(0 to 9);

  signal curr_data          : std_logic_vector(0 to 63);
  signal next_data          : std_logic_vector(0 to 63);

  signal curr_sop, curr_eop : std_logic;
  signal next_sop, next_eop : std_logic;

--=============================================================================
begin -- architecture
--=============================================================================

  prop_state: process (clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' or user_rst_n = '0' then
        curr_state <= wait_pkt;
        curr_addr  <= (others => '0');
        curr_bcnt  <= (others => '0');
        curr_data  <= (others => '0');
        curr_sop   <= '0';
        curr_eop   <= '0';
      else
        curr_state <= next_state;
        curr_addr  <= next_addr;
        curr_bcnt  <= next_bcnt;
        curr_data  <= next_data;
        curr_sop   <= next_sop;
        curr_eop   <= next_eop;
      end if;
    end if;
  end process;

  handle_cmd: process (curr_addr, curr_state, curr_bcnt, curr_data,
                       curr_sop, curr_eop,
                       apkt_req, apkt_addr, apkt_bcount,
                       src_rdy, data, valid, sop, eop,
                       bus2dma.ack) is
  begin
    -- Make sure that the state only changes when set explicitly
    next_state <= curr_state;
    next_addr  <= curr_addr;
    next_bcnt  <= curr_bcnt;
    next_data  <= curr_data;
    next_sop   <= curr_sop;
    next_eop   <= curr_eop;

    -- We don't handle abort requests
    abort_ack <= '0';

    -- Default values for the dma2bus interface
    dma2bus.flags <= BUS_FLAGS_DEFAULT;
    dma2bus.readEnable <= '0';
    dma2bus.writeEnable <= '0';
    dma2bus.address <= (others => '0');
    -- Always write all 4 bytes for now, as writing less is not supported by
    -- the memory controller
    dma2bus.writeMask <= "1111";

    -- Default values for the outgoing sync signals
    apkt_ready <= '0';
    dst_rdy <= '0';

    case curr_state is
      when wait_pkt =>
        -- Indicate that we are ready for a request
        apkt_ready <= apkt_req;

        if apkt_req = '1' then
          -- Only use the lower 32 bits of the address
          next_addr  <= apkt_addr(32 to 63);
          -- Store the amount of bytes to transfer
          next_bcnt  <= apkt_bcount;
          next_state <= wait_data;
        end if;

      when wait_data =>
        -- Indicate that we are ready for a new double word
        dst_rdy <= '1';

        if src_rdy = '1' then
          -- Store loaded data
          next_data <= data;
          next_sop  <= sop;
          next_eop  <= eop;
          -- New data loaded, continue to writing
          next_state <= write_low;
        end if;

      when write_low =>
        dma2bus.address <= curr_addr;
        -- Transmit the lower word
        dma2bus.writeData( 7 downto  0) <= curr_data(32 to 39);
        dma2bus.writeData(15 downto  8) <= curr_data(40 to 47);
        dma2bus.writeData(23 downto 16) <= curr_data(48 to 55);
        dma2bus.writeData(31 downto 24) <= curr_data(56 to 63);
        dma2bus.writeEnable <= '1';

        if bus2dma.ack = '1' then
          -- Increment the next address to read
          next_addr <= std_logic_vector(vect2unsigned(curr_addr) + 4);

          if vect2unsigned(curr_bcnt) <= 4 then
            -- Done transfering, stop writing
            next_bcnt  <= (others => '0');
            next_state <= wait_pkt;
          else
            -- Start writing the next word, to speed up the transfer
            dma2bus.address <= std_logic_vector(vect2unsigned(curr_addr) + 4);
            dma2bus.writeData <= curr_data(0 to 31);

            -- Decrement the byte count
            next_bcnt  <= std_logic_vector(vect2unsigned(curr_bcnt) - 4);
            next_state <= write_high;
          end if;
        end if;

      when write_high =>
        -- Transmit the upper word
        dma2bus.address <= curr_addr;
        dma2bus.writeData( 7 downto  0) <= curr_data( 0 to  7);
        dma2bus.writeData(15 downto  8) <= curr_data( 8 to 15);
        dma2bus.writeData(23 downto 16) <= curr_data(16 to 23);
        dma2bus.writeData(31 downto 24) <= curr_data(24 to 31);
        dma2bus.writeEnable <= '1';

        if bus2dma.ack = '1' then
          -- Increment the next address to read
          next_addr <= std_logic_vector(vect2unsigned(curr_addr) + 4);
          -- Disable writing
          dma2bus.writeEnable <= '0';

          if vect2unsigned(curr_bcnt) > 4 then
            -- Decrement the byte count
            next_bcnt  <= std_logic_vector(vect2unsigned(curr_bcnt) - 4);
            -- Request the next double word
            next_state <= wait_data;
          else
            -- Reset the byte count
            next_bcnt  <= (others => '0');
            -- Request new packet metadata
            next_state <= wait_pkt;
          end if;
        end if;

    end case;
  end process;

end Behavioral;
