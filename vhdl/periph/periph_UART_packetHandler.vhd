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

-- 6. r-VEX was developed by Stephan Wong, Thijs van As, Fakhar Anjam,
-- Roel Seedorf, Anthony Brandon, Jeroen van Straten. r-VEX is currently
-- maintained by TU Delft (J.S.S.M.Wong@tudelft.nl).

-- Copyright (C) 2008-2014 by TU Delft.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

library rvex;
use rvex.common_pkg.all;
use rvex.utils_pkg.all;
use rvex.bus_pkg.all;

--=============================================================================
-- This is is part of the debug section of the UART peripheral. It handles
-- debug packets by initiating the requested bus transfers.
--
-------------------------------------------------------------------------------
-- Packet format
-------------------------------------------------------------------------------
-- Each packet (request and reply) starts with a command byte with the
-- following format.
-- 
-- |-7-|-6-|-5-|-4-|-3-|-2-|-1-|-0-|
-- |   Sequence    |    Command    |
-- |---|---|---|---|---|---|---|---|
-- 
-- The sequence number is not used by the packet handler, and is simply copied
-- into the reply packet. The PC may use this in order to be able to send more
-- than one request before receiving a reply; using the sequence number it will
-- be able to identify which commands (if any) need to be resent.
-- 
-- The command field determines how the device should handle the packet. has
-- the following encoding. This field is also copied into the reply packet
-- unchanged.
-- 
--   0000 => reserved for version information
--   0001 => reserved
--   0010 => reserved
--   0011 => reserved
--   0100 => reserved
--   0101 => reserved
--   0110 => reserved
--   0111 => reserved
--   1000 => reserved
--   1001 => reserved
--   1010 => query current address
--   1011 => set current address
--   1100 => read word(s)
--   1101 => write byte(s)
--   1110 => write halfword(s)
--   1111 => write word(s)
-- 
-- The function of the remainder of the bytes depends on the command code, as
-- follows.
-- 
-- Packet 0000..1001:
--   Payload from computer is ignored, no payload is sent in the reply.
-- 
-- Packet 1010 - query current address:
--   Payload from computer is ignored. The reply payload consists of 4 bytes,
--   containing the current address in big-endian notation.
-- 
-- Packet 1011 - set current address:
--   Payload from computer should be 4 bytes, containing the new address in
--   big-endian notation. The reply payload consists of 4 bytes, echoing the
--   new address.
-- 
-- Packet 1100 - read word(s):
--   Payload from the computer should be 1 byte, specifying the number of words
--   to read. The maximum is 7 due to the size of the packet buffer. The reply
--   payload consists of the bytes as read from the bus. The address is
--   incremented by 4 for every word read.
-- 
-- Packet 1101 - write byte(s):
--   Payload from the computer should be 1 to 30 bytes, specifying the bytes
--   which should be written. The reply consists of 1 byte, specifying the
--   number of bytes written. The address is incremented by 1 for every byte
--   written.
-- 
-- Packet 1110 - write halfwords(s):
--   Payload from the computer should be 2 to 30 bytes, specifying the
--   halfwords which should be written. The reply consists of 1 byte,
--   specifying the number of halfwords written. The address is incremented by
--   2 for every halfword written.
-- 
-- Packet 1111 - write word(s):
--   Payload from the computer should be 4 to 28 bytes, specifying the words
--   which should be written. The reply consists of 1 byte, specifying the
--   number of words written. The address is incremented by 4 for every word
--   written; when not in auto-increment mode, the same word is written
--   multiple times and the address is left unchanged.
-- 
-------------------------------------------------------------------------------
entity periph_UART_packetHandler is
--=============================================================================
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
    -- Interface with packet control
    ---------------------------------------------------------------------------
    -- Received packet buffer interface. When pop is high, the next byte in
    -- the buffer is selected. If no more bytes are available, empty is
    -- asserted high instead.
    pkctrl2pkhan_rxData         : in  std_logic_vector(7 downto 0);
    pkhan2pkctrl_rxPop          : out std_logic;
    pkctrl2pkhan_rxEmpty        : in  std_logic;
    
    -- When high, the next packet is requested.
    pkctrl2pkhan_rxSwap         : out std_logic;
    
    -- When high, a packet has been received and is available in the buffer.
    pkhan2pkctrl_rxReady        : in  std_logic;
    
    -- Reply packet buffer interface. When push is high, data is pushed into
    -- the buffer, unless the buffer is full (in which was full will have been
    -- asserted high.
    pkhan2pkctrl_txData         : out std_logic_vector(7 downto 0);
    pkhan2pkctrl_txPush         : out std_logic;
    pkctrl2pkhan_txFull         : in  std_logic;
    
    -- When high, the transmit buffer is reset/cleared.
    pkctrl2pkhan_txReset        : out std_logic;
    
    -- When high, the packet currently in the transmit buffer will be
    -- transmitted.
    pkctrl2pkhan_txSwap         : out std_logic;
    
    -- When high, the transmit buffer is ready for writing.
    pkhan2pkctrl_txReady        : in  std_logic;
    
    ---------------------------------------------------------------------------
    -- Bus interface
    ---------------------------------------------------------------------------
    -- This is the bus which is controlled by the debug packets.
    pkhan2dbg_bus               : out bus_mst2slv_type;
    dbg2pkhan_bus               : in  bus_slv2mst_type
    
  );
end periph_UART_packetHandler;

--=============================================================================
architecture Behavioral of periph_UART_packetHandler is
--=============================================================================
  
  -- Bus registers, among which the current address.
  signal pkhan2dbg_busRegs      : bus_mst2slv_type;
  
  -- The address is incremented by this value every cycle.
  signal address_inc            : std_logic_vector(2 downto 0);
  
  -- When a bit in this signal is high, the associated byte in the address is
  -- overridden with the currently exposed receive buffer byte.
  signal address_WE             : rvex_mask_type;
  
  -- When a bit in this signal is high, the associated byte in the write data
  -- register is overridden with the currently exposed receive buffer byte, and
  -- the associated write mask bit is set.
  signal writeData_WE           : rvex_mask_type;
  
  -- When high, a write will be issued on the bus.
  signal writeEnable            : std_logic;
  
  -- When high, a read will be issued on the bus.
  signal readEnable             : std_logic;
  
  -- Bus transfer complete signal.
  signal transferComplete       : std_logic;
  
  -- Read data register, valid the cycle after transferComplete is high.
  signal readData               : rvex_data_type;
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- Bus interface
  -----------------------------------------------------------------------------
  bus_inferface_block: block is
  begin
    
    -- Instantiate the bus registers.
    bus_regs: process (clk) is
    begin
      if rising_edge(clk) then
        if reset = '1' then
          pkhan2dbg_busRegs <= BUS_MST2SLV_IDLE;
          readData <= (others => '0');
        elsif clkEn = '1' then
          
          -- Handle bus address.
          pkhan2dbg_busRegs.address <= std_logic_vector(
            vect2unsigned(pkhan2dbg_busRegs.address) + vect2unsigned(address_inc)
          );
          for i in 0 to 3 loop
            if address_WE(i) = '1' then
              pkhan2dbg_busRegs.address(i*8+7 downto i*8) <= pkctrl2pkhan_rxData;
            end if;
          end loop;
          
          -- Handle write requests.
          if transferComplete = '1' then
            pkhan2dbg_busRegs.writeEnable <= '0';
            pkhan2dbg_busRegs.writeMask <= (others => '0');
          elsif writeEnable = '1' then
            pkhan2dbg_busRegs.writeEnable <= '1';
          end if;
          for i in 0 to 3 loop
            if writeData_WE(i) = '1' then
              pkhan2dbg_busRegs.writeMask(i) <= '1';
              pkhan2dbg_busRegs.writeData(i*8+7 downto i*8) <= pkctrl2pkhan_rxData;
            end if;
          end loop;
          
          -- Handle read requests.
          if transferComplete = '1' then
            pkhan2dbg_busRegs.readEnable <= '0';
          elsif readEnable = '1' then
            pkhan2dbg_busRegs.readEnable <= '1';
          end if;
          
          -- Handle read results.
          if transferComplete = '1' then
            readData <= dbg2pkhan_bus.readData;
          end if;
          
        end if;
      end if;
    end process;
    
    -- The transferComplete signal is simply the ack signal from the bus.
    transferComplete <= dbg2pkhan_bus.ack;
    
    -- The readEnable and writeEnable signals will still be active in the cycle
    -- where ack is high; they are cleared only in the cycle after. Thus, we
    -- need to gate the signals from the registers in order to not start the same
    -- transfer again.
    pkhan2dbg_bus <= bus_gate(pkhan2dbg_busRegs, not transferComplete);
    
  end block;
  
  -----------------------------------------------------------------------------
  -- Packet handler state machine
  -----------------------------------------------------------------------------
  packet_handler_fsm: block is
    
    -- FSM state.
    type state_type is (
      
      -- Waits for the packet buffers to vecome ready.
      STATE_WAIT,
      
      -- Decodes the command byte and pushes it into the transmit buffer.
      STATE_DECODE,
      
      -- Sets the current address.
      STATE_SET_ADDRESS_0, STATE_SET_ADDRESS_1,
      STATE_SET_ADDRESS_2, STATE_SET_ADDRESS_3,
      
      -- Reads the count byte from the receive buffer, then moves to the read
      -- states.
      STATE_READ_COUNT,
      
      -- Executes a bus read and waits for completion.
      STATE_READ_EXECUTE,
      
      -- Pushes the read data or address into the transmit buffer.
      STATE_READ_BUFFER_0, STATE_READ_BUFFER_1,
      STATE_READ_BUFFER_2, STATE_READ_BUFFER_3,
      
      -- Pushes the data from the received packet into the writeData register.
      STATE_WRITE_BUFFER_0, STATE_WRITE_BUFFER_1,
      STATE_WRITE_BUFFER_2, STATE_WRITE_BUFFER_3,
      
      -- Executes a bus write and waits for completion.
      STATE_WRITE_EXECUTE,
      
      -- Pushes the number of bytes/halfwords/words written into the packet to
      -- transmit and swaps the buffer.
      STATE_WRITE_COUNT
      
    );
    signal state                : state_type;
    signal state_next           : state_type;
    
    -- Counter, used to store how much accesses we still need to do or have
    -- done.
    signal counter              : std_logic_vector(7 downto 0);
    signal counter_next         : std_logic_vector(7 downto 0);
    
    -- Stores the type of operation (address or data) and the access size.
    type accessSize_type is (AS_WORD, AS_HALF, AS_BYTE, AS_ADDR);
    signal accessSize           : accessSize_type;
    signal accessSize_next      : accessSize_type;
    
    -- Data which should be pushed into the receive buffer. This is either the
    -- current address or the read data register
    signal incomingData         : rvex_data_type;
    
  begin
    
    -- Select what data should be put in the transmit buffer for reads/queries.
    incomingData
      <= pkhan2dbg_busRegs.address when accessSize = AS_ADDR else readData;
    
    -- Instantiate the state registers for the FSM.
    fsm_regs: process (clk) is
    begin
      if rising_edge(clk) then
        if reset = '1' then
          state <= STATE_WAIT;
          counter <= (others => '0');
          accessSize <= AS_WORD;
        elsif clkEn = '1' then
          state <= state_next;
          counter <= counter_next;
          accessSize <= accessSize_next;
        end if;
      end if;
    end process;
    
    -- Combinatorial logic for the FSM.
    fsm_comb: process (
      state, counter, accessSize, incomingData, transferComplete,
      pkctrl2pkhan_rxData, pkctrl2pkhan_rxEmpty, pkhan2pkctrl_rxReady,
      pkctrl2pkhan_txFull, pkhan2pkctrl_txReady, pkhan2dbg_busRegs
    ) is
    begin
      
      -- Load default values.
      state_next            <= state;
      counter_next          <= counter;
      accessSize_next       <= accessSize;
      pkhan2pkctrl_rxPop    <= '0';
      pkctrl2pkhan_rxSwap   <= '0';
      pkhan2pkctrl_txData   <= pkctrl2pkhan_rxData;
      pkhan2pkctrl_txPush   <= '0';
      pkctrl2pkhan_txReset  <= '0';
      pkctrl2pkhan_txSwap   <= '0';
      address_inc           <= (others => '0');
      address_WE            <= (others => '0');
      writeData_WE          <= (others => '0');
      writeEnable           <= '0';
      readEnable            <= '0';
  
      case state is
        
        -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        -- Command-agnostic states
        -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        when STATE_WAIT => 
          
          -- Wait for both receive and transmit buffer to be ready.
          if pkhan2pkctrl_rxReady = '1' and pkhan2pkctrl_txReady = '1' then
            state_next <= STATE_DECODE;
          end if;
          
        when STATE_DECODE =>
          
          -- Decode the command byte.
          case pkctrl2pkhan_rxData(3 downto 0) is
            
            when "1010" => -- Query current address.
              accessSize_next <= AS_ADDR;
              counter_next <= (others => '0');
              state_next <= STATE_READ_BUFFER_0;
              
            when "1011" => -- Set current address.
              accessSize_next <= AS_ADDR;
              counter_next <= (others => '0');
              state_next <= STATE_SET_ADDRESS_0;
              
            when "1100" => -- Read word(s).
              accessSize_next <= AS_WORD;
              state_next <= STATE_READ_COUNT;
              
            when "1101" => -- Write byte(s).
              accessSize_next <= AS_BYTE;
              counter_next <= (others => '0');
              state_next <= STATE_WRITE_BUFFER_0;
              
            when "1110" => -- Write halfword(s).
              accessSize_next <= AS_HALF;
              counter_next <= (others => '0');
              state_next <= STATE_WRITE_BUFFER_0;
              
            when "1111" => -- Write word(s).
              accessSize_next <= AS_WORD;
              counter_next <= (others => '0');
              state_next <= STATE_WRITE_BUFFER_0;
            
            when others => -- Reserved.
              
              -- Handle reserved commands by sending an empty reply packet.
              pkctrl2pkhan_rxSwap <= '1';
              pkctrl2pkhan_txSwap <= '1';
              state_next <= STATE_WAIT;
              
          end case;
          
          -- Copy the command byte into the transmit buffer and pop it.
          pkhan2pkctrl_txData <= pkctrl2pkhan_rxData;
          pkhan2pkctrl_txPush <= '1';
          pkhan2pkctrl_rxPop <= '1';
          
        -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        -- Set-address command states
        -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        when STATE_SET_ADDRESS_0 =>
          
          -- Write address byte 0 and go to the next state.
          address_WE <= "1000";
          pkhan2pkctrl_rxPop <= '1';
          state_next <= STATE_SET_ADDRESS_1;
          
        when STATE_SET_ADDRESS_1 =>
          
          -- Write address byte 1 and go to the next state.
          address_WE <= "0100";
          pkhan2pkctrl_rxPop <= '1';
          state_next <= STATE_SET_ADDRESS_2;
          
        when STATE_SET_ADDRESS_2 =>
          
          -- Write address byte 2 and go to the next state.
          address_WE <= "0010";
          pkhan2pkctrl_rxPop <= '1';
          state_next <= STATE_SET_ADDRESS_3;
          
        when STATE_SET_ADDRESS_3 =>
          
          -- Write address byte 3 and finish the transfer.
          address_WE <= "0001";
          pkhan2pkctrl_rxPop <= '1';
          pkctrl2pkhan_rxSwap <= '1';
          pkctrl2pkhan_txSwap <= '1';
          state_next <= STATE_WAIT;
          
        -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        -- Read word and query address command states
        -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        when STATE_READ_COUNT =>
          
          -- Read the access count from the received packet and pop it.
          counter_next <= pkctrl2pkhan_rxData;
          pkhan2pkctrl_rxPop <= '1';
          
          -- Start the read operation.
          state_next <= STATE_READ_EXECUTE;
          
        when STATE_READ_EXECUTE =>
          
          -- Initiate the read.
          readEnable <= '1';
          
          -- Continue when the read is complete.
          if transferComplete = '1' then
            
            -- Decrement the access count register.
            counter_next <= std_logic_vector(vect2unsigned(counter) - 1);
            
            -- Increment the address by 4 if we did a word read access.
            if accessSize /= AS_ADDR then
              address_inc <= "100";
            end if;
            
            -- Go to the next state.
            state_next <= STATE_READ_BUFFER_0;
            
          end if;
          
        when STATE_READ_BUFFER_0 =>
          
          -- Push byte 0 into the buffer and go to the next state.
          pkhan2pkctrl_txData <= incomingData(31 downto 24);
          pkhan2pkctrl_txPush <= '1';
          state_next <= STATE_READ_BUFFER_1;
          
        when STATE_READ_BUFFER_1 =>
          
          -- Push byte 1 into the buffer and go to the next state.
          pkhan2pkctrl_txData <= incomingData(23 downto 16);
          pkhan2pkctrl_txPush <= '1';
          state_next <= STATE_READ_BUFFER_2;
          
        when STATE_READ_BUFFER_2 =>
          
          -- Push byte 2 into the buffer and go to the next state.
          pkhan2pkctrl_txData <= incomingData(15 downto 8);
          pkhan2pkctrl_txPush <= '1';
          state_next <= STATE_READ_BUFFER_3;
          
        when STATE_READ_BUFFER_3 =>
          
          -- Push byte 3 into the buffer.
          pkhan2pkctrl_txData <= incomingData(7 downto 0);
          pkhan2pkctrl_txPush <= '1';
          
          -- Go to the next state. When the counter is zero, we've done all the
          -- accesses which were requested, so we can transmit the reply and
          -- request a new packet. Otherwise, perform the next access.
          if vect2unsigned(counter) = 0 then
            pkctrl2pkhan_rxSwap <= '1';
            pkctrl2pkhan_txSwap <= '1';
            state_next <= STATE_WAIT;
          else
            state_next <= STATE_READ_EXECUTE;
          end if;
          
        -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        -- Write command states
        -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        when STATE_WRITE_BUFFER_0 =>
          
          -- Pop byte 0 from the buffer and place it into the writeData
          -- register.
          case pkhan2dbg_busRegs.address(1 downto 0) is
            when "00" => writeData_WE <= "1000";
            when "01" => writeData_WE <= "0100";
            when "10" => writeData_WE <= "0010";
            when others => writeData_WE <= "0001";
          end case;
          pkhan2pkctrl_rxPop <= '1';
          
          -- If this is a byte access, execute the write now. Otherwise, buffer
          -- the next byte.
          if accessSize = AS_BYTE then
            state_next <= STATE_WRITE_EXECUTE;
          else
            state_next <= STATE_WRITE_BUFFER_1;
          end if;
          
        when STATE_WRITE_BUFFER_1 =>
          
          -- Pop byte 1 from the buffer and place it into the writeData
          -- register.
          case pkhan2dbg_busRegs.address(1 downto 1) is
            when "0" => writeData_WE <= "0100";
            when others => writeData_WE <= "0001";
          end case;
          pkhan2pkctrl_rxPop <= '1';
          
          -- If this is a halword access, execute the write now. Otherwise,
          -- buffer the next byte.
          if accessSize = AS_HALF then
            state_next <= STATE_WRITE_EXECUTE;
          else
            state_next <= STATE_WRITE_BUFFER_2;
          end if;
          
        when STATE_WRITE_BUFFER_2 =>
          
          -- Pop byte 2 from the buffer, place it into the writeData buffer,
          -- and go to the next state.
          writeData_WE <= "0010";
          pkhan2pkctrl_rxPop <= '1';
          state_next <= STATE_WRITE_BUFFER_3;
          
        when STATE_WRITE_BUFFER_3 =>
          
          -- Pop byte 3 from the buffer, place it into the writeData buffer,
          -- and go to the next state.
          writeData_WE <= "0001";
          pkhan2pkctrl_rxPop <= '1';
          state_next <= STATE_WRITE_EXECUTE;
          
        when STATE_WRITE_EXECUTE =>
          
          -- Initiate the write.
          writeEnable <= '1';
          
          -- Continue when the write is complete.
          if transferComplete = '1' then
            
            -- Increment the access count register.
            counter_next <= std_logic_vector(vect2unsigned(counter) + 1);
            
            -- Increment the address.
            case accessSize is
              when AS_WORD => address_inc <= "100";
              when AS_HALF => address_inc <= "010";
              when AS_BYTE => address_inc <= "001";
              when others  => address_inc <= "000";
            end case;
            
            -- If the receive buffer is empty, finish the command. Otherwise,
            -- buffer the bytes for the next write.
            if pkctrl2pkhan_rxEmpty = '1' then
              state_next <= STATE_WRITE_COUNT;
            else
              state_next <= STATE_WRITE_BUFFER_0;
            end if;
            
          end if;
          
        when STATE_WRITE_COUNT =>
          
          -- Write the count to the transmit buffer and swap.
          pkhan2pkctrl_txData <= counter(7 downto 0);
          pkhan2pkctrl_txPush <= '1';
          pkctrl2pkhan_txSwap <= '1';
          pkctrl2pkhan_rxSwap <= '1';
          state_next <= STATE_WAIT;
        
      end case;
      
    end process;
    
  end block;
  
end Behavioral;

