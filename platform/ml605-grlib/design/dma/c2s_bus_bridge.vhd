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
    -- All buses run in the same clock domain
    clk                     : in  std_logic;

    ---------------------------------------------------------------------------
    -- c2s bus
    ---------------------------------------------------------------------------
    sop                     : out std_logic;
    eop                     : out std_logic;
    data                    : out std_logic_vector(0 to CORE_DATA_WIDTH-1);
    valid                   : out std_logic_vector(0 to CORE_REMAIN_WIDTH-1);
    src_rdy                 : out std_logic;
    dst_rdy                 : in  std_logic;
    abort                   : in  std_logic;
    abort_ack               : out std_logic;
    user_rst_n              : in  std_logic;

    -- Addressed Packet Interface
    apkt_req                : in  std_logic;
    apkt_ready              : out std_logic;
    apkt_addr               : in  std_logic_vector(0 to 63);
    apkt_bcount             : in  std_logic_vector(0 to 31);
    apkt_eop                : in  std_logic;

    ---------------------------------------------------------------------------
    -- Master bus
    ---------------------------------------------------------------------------
    bus2dma                 : in  bus_slv2mst_type;
    dma2bus                 : out bus_mst2slv_type
  );
end c2s_bus_bridge;


--=============================================================================
architecture Behavioral of c2s_bus_bridge is
--=============================================================================

  type transmit_state is (wait_pkt, read_high, read_low, send_data);

  signal curr_addr          : rvex_address_type;
  signal next_addr          : rvex_address_type;
  signal curr_bcnt          : std_logic_vector(0 to 31);
  signal next_bcnt          : std_logic_vector(0 to 31);

  signal curr_state         : transmit_state;
  signal next_state         : transmit_state;

  signal curr_sop, next_sop : std_logic;

  signal curr_apkt_eop      : std_logic;
  signal next_apkt_eop      : std_logic;

  signal curr_data          : std_logic_vector(0 to CORE_DATA_WIDTH-1);
  signal next_data          : std_logic_vector(0 to CORE_DATA_WIDTH-1);

--=============================================================================
begin -- architecture
--=============================================================================


  proc_clk: process (clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' or user_rst_n = '0' then
        curr_state      <= wait_pkt;
        curr_addr       <= (others => '0');
        curr_bcnt       <= (others => '0');

        curr_data       <= (others => '0');
        curr_sop        <= '0';
        curr_apkt_eop   <= '1';

      else
        curr_state    <= next_state;
        curr_addr     <= next_addr;
        curr_bcnt     <= next_bcnt;

        curr_data     <= next_data;
        curr_sop      <= next_sop;
        curr_apkt_eop <= next_apkt_eop;
      end if;
    end if;
  end process;

  data <= curr_data;

  handle_cmd: process (curr_state, curr_addr, curr_bcnt, curr_sop, curr_data,
                       apkt_req, apkt_addr, apkt_bcount,
                       bus2dma.ack, bus2dma.readData,
                       dst_rdy) is
  begin
    -- Make sure that the state only changes when set explicitly
    next_state      <= curr_state;
    next_addr       <= curr_addr;
    next_bcnt       <= curr_bcnt;

    next_data       <= curr_data;
    next_sop        <= curr_sop;
    next_apkt_eop   <= curr_apkt_eop;

    -- Set the sop signal
    sop <= curr_sop;

    -- We don't handle abort requests
    abort_ack <= '0';

    -- Set the eop signal high in the last double word of the apkt when
    -- apkt_eop is high.
    -- NB. This confuses the testbench, resulting in it only sending two
    -- packets. The PC software requires this behaviour though, and the
    -- testbench is wrong here.
    if vect2unsigned(curr_bcnt) <= 8 then
      eop <= curr_apkt_eop;
    else
      eop <= '0';
    end if;

    -- Default values for the outgoing sync signals
    apkt_ready <= '0';
    src_rdy <= '0';

    -- Default values for the dma2bus interface
    dma2bus.flags <= BUS_FLAGS_DEFAULT;
    dma2bus.writeEnable <= '0';
    dma2bus.readEnable <= '0';
    dma2bus.address <= (others => '0');

    -- sending the last double word of the block
    -- NB: The value of valid doesn't seem to influence what is sent over the
    -- PCIe bus.
    if vect2unsigned(curr_bcnt) <= 8 then
      valid <= curr_bcnt(29 to 31);
    else
      -- send 8 bytes
      valid <= "000";
    end if;


    case curr_state is
      when wait_pkt =>
        -- reset data
        next_data <= (others => '0');

        -- Indicate that we are ready for a request
        apkt_ready <= apkt_req;

        -- Only transition when there is a packet
        if apkt_req = '1' then
          -- Only use the lower 32 bits of the address
          next_addr <= apkt_addr(32 to 63);
          -- Store the amount of bytes to transfer
          next_bcnt <= apkt_bcount;
          -- Indicate that we are starting a new transfer
          -- We start a new transfer the previous transfer was an EOP
          next_sop <= curr_apkt_eop;
          -- Store if this is the last apkt of the packet
          next_apkt_eop <= apkt_eop;
          -- Change to read_low
          next_state <= read_low;
        end if;

      when read_low =>
        -- Read the current address
        dma2bus.address <= curr_addr;
        dma2bus.readEnable <= '1';

        if bus2dma.ack = '1' then
          -- Set the lower word
          next_data(32 to 39) <= bus2dma.readData( 7 downto  0);
          next_data(40 to 47) <= bus2dma.readData(15 downto  8);
          next_data(48 to 55) <= bus2dma.readData(23 downto 16);
          next_data(56 to 63) <= bus2dma.readData(31 downto 24);

          -- Increment the next address to read
          next_addr <= std_logic_vector(vect2unsigned(curr_addr) + 4);

          if vect2unsigned(curr_bcnt) > 4 then
            -- Start reading the next data element, to speed up the transfer
            dma2bus.address <= std_logic_vector(vect2unsigned(curr_addr) + 4);

            next_state <= read_high;
          else
            -- Done transfering, stop reading and send data
            dma2bus.readEnable <= '0';

            next_state <= send_data;
          end if;
        end if;

      when read_high =>
        -- Read the current address
        dma2bus.address <= curr_addr;
        dma2bus.readEnable <= '1';

        if bus2dma.ack = '1' then
          -- Set the upper word
          next_data( 0 to  7) <= bus2dma.readData( 7 downto  0);
          next_data( 8 to 15) <= bus2dma.readData(15 downto  8);
          next_data(16 to 23) <= bus2dma.readData(23 downto 16);
          next_data(24 to 31) <= bus2dma.readData(31 downto 24);

          -- Disable reads
          dma2bus.readEnable <= '0';

          -- Increment address
          next_addr <= std_logic_vector(vect2unsigned(curr_addr) + 4);

          -- State transition
          next_state <= send_data;
        end if;

      when send_data =>
        -- Indicate that the data is valid
        src_rdy <= '1';

        if dst_rdy = '1' then
          -- Reset sop signal
          next_sop <= '0';

          if vect2unsigned(curr_bcnt) > 8 then
            -- Start reading the next double word
            dma2bus.address <= curr_addr;
            dma2bus.readEnable <= '1';

            -- Decrement the byte counter
            next_bcnt <= std_logic_vector(vect2unsigned(curr_bcnt) - 8);
            next_state <= read_low;
          else
            -- Reset the byte counter
            next_bcnt <= (others => '0');
            next_state <= wait_pkt;
          end if;
        end if;
    end case;

  end process;

end Behavioral;
