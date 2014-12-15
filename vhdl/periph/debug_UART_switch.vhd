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

--=============================================================================
-- This is is part of the UART peripheral. It muxes and demuxes two UART
-- bytestreams (user and debug) by inserting control characters, and escape
-- characters if the values reserved as control characters are to be
-- transmitted. In addition, it provides the means to identify the start and
-- end of a packet within the bytestream.
--
-- The following control characters are used:
-- 
--   Char    Escape       Function
--   0xFE    0xFC 0x01    Switch to user stream, end of preceding debug packet.
--   0xFD    0xFC 0x02    Start debug packet, end of preceding debug packet.
--   0xFC    0xFC 0x03    Escape character.
-- 
-------------------------------------------------------------------------------
entity periph_UART_switch is
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
    -- RX interface
    ---------------------------------------------------------------------------
    -- Interface with the UART receiver. When rxStrobe is high and rxFrameError
    -- is low, rxData contains a valid received byte.
    uart2sw_rxData              : in  std_logic_vector(7 downto 0);
    uart2sw_rxFrameError        : in  std_logic;
    uart2sw_rxStrobe            : in  std_logic;
    
    -- Interface for the user stream. Same format as the stream from the UART,
    -- only frames with errors are filtered out already.
    sw2user_rxData              : out std_logic_vector(7 downto 0);
    sw2user_rxStrobe            : out std_logic;
    
    -- Interface for the debug stream. When rxStrobe is high, rxData and
    -- rxEndPacket are valid. When rxEndPacket is low, rxData contains a
    -- received byte. When rxEndPacket is  high, rxData is invalid, but this
    -- rxStrobe marks the end of the packet which was being received.
    sw2dbg_rxData               : out std_logic_vector(7 downto 0);
    sw2dbg_rxEndPacket          : out std_logic;
    sw2dbg_rxStrobe             : out std_logic;
    
    ---------------------------------------------------------------------------
    -- TX interface
    ---------------------------------------------------------------------------
    -- When strobe is high and busy is low, the data in txData will be
    -- buffered and transmitted. Note that since busy will go high the cycle
    -- after strobe is asserted, it is perfectly legal to keep strobe high
    -- until the busy flag is cleared.
    sw2uart_txData              : out std_logic_vector(7 downto 0);
    sw2uart_txStrobe            : out std_logic;
    uart2sw_txBusy              : in  std_logic;
    
    -- TX interface for the user stream, same format as the stream to the UART.
    user2sw_txData              : in  std_logic_vector(7 downto 0);
    user2sw_txStrobe            : in  std_logic;
    sw2user_txBusy              : out std_logic;
    
    -- When request is high, the UART will transmit txData. When the transfer
    -- completes, txAck will be high for one cycle. When break is high, the
    -- switch logic ensures that a 0xFD character is sent first. The end of
    -- packet markers are inserted automatically when request goes low while
    -- ack is high.
    dbg2sw_txData               : in  std_logic_vector(7 downto 0);
    dbg2sw_txStartPacket        : in  std_logic;
    dbg2sw_txRequest            : in  std_logic;
    sw2dbg_txAck                : out std_logic
    
  );
end periph_UART_switch;

--=============================================================================
architecture Behavioral of periph_UART_switch is
--=============================================================================
  
  -- Special control character definitions. These can be changed to whatever,
  -- as long as the one's complement of a control character does not map to
  -- another control character (this is due to the escape sequence mechanism).
  constant CHAR_USER            : std_logic_vector(7 downto 0) := X"FE";
  constant CHAR_DEBUG           : std_logic_vector(7 downto 0) := X"FD";
  constant CHAR_ESCAPE          : std_logic_vector(7 downto 0) := X"FC";
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- Demux received data
  -----------------------------------------------------------------------------
  rx_logic: block is
    
    -- Currently selected stream.
    signal currentStream        : std_logic;
    constant STREAM_USER        : std_logic := '0';
    constant STREAM_DEBUG       : std_logic := '1';
    
    -- This is set when the last character received was an escape character.
    signal escaping             : std_logic;
    
    -- Received data register.
    signal rxData               : std_logic_vector(7 downto 0);
    
  begin
    
    rx_proc: process (clk) is
    begin
      if rising_edge(clk) then
        if reset = '1' then
          currentStream <= STREAM_USER;
          escaping <= '0';
          rxData <= (others => '0');
          sw2dbg_rxEndPacket <= '0';
          sw2user_rxStrobe <= '0';
          sw2dbg_rxStrobe <= '0';
        elsif clkEn = '1' then
          
          -- Release strobe flags when no data is received.
          sw2user_rxStrobe <= '0';
          sw2dbg_rxStrobe <= '0';
          sw2dbg_rxEndPacket <= '0';
          
          -- Handle incoming data.
          if uart2sw_rxStrobe = '1' and uart2sw_rxFrameError = '0' then
            
            -- Load the data register, taking escape sequences into account.
            if escaping = '1' then
              rxData <= not uart2sw_rxData;
            else
              rxData <= uart2sw_rxData;
            end if;
            escaping <= '0';
            
            -- Handle control characters.
            case uart2sw_rxData is
              
              when CHAR_USER =>
                
                -- Select user stream.
                currentStream <= STREAM_USER;
                
                -- If the previous stream was the debug stream, mark the end of
                -- the packet.
                if currentStream = STREAM_DEBUG then
                  sw2dbg_rxEndPacket <= '1';
                  sw2dbg_rxStrobe <= '1';
                end if;
                
              when CHAR_DEBUG =>
                
                -- Select debug stream.
                currentStream <= STREAM_DEBUG;
                
                -- If the previously selected stream was also the debug stream,
                -- mark the end of the packet.
                if currentStream = STREAM_DEBUG then
                  sw2dbg_rxEndPacket <= '1';
                  sw2dbg_rxStrobe <= '1';
                end if;
                
              when CHAR_ESCAPE =>
                
                -- Set the escaping flag, so the next data byte which is
                -- received is one's complemented.
                escaping <= '1';
                
              when others =>
                
                -- Data has been received. Strobe the currently selected stream.
                if currentStream = STREAM_DEBUG then
                  sw2dbg_rxStrobe <= '1';
                else
                  sw2user_rxStrobe <= '1';
                end if;
              
            end case;
            
          end if;
        end if;
      end if;
    end process;
    
    -- Forward the received data.
    sw2user_rxData <= rxData;
    sw2dbg_rxData <= rxData;
    
  end block;
  
  -----------------------------------------------------------------------------
  -- Mux the to-be-transmitted data
  -----------------------------------------------------------------------------
  tx_logic: block is
    
    -- Current FSM state.
    type state_type is (STATE_USER, STATE_DEBUG, STATE_WAIT);
    signal state                : state_type;
    
    -- User data request holding register.
    signal userData             : std_logic_vector(7 downto 0);
    signal userRequest          : std_logic;
    signal userAck              : std_logic;
    
  begin
    
    -- Generate the TX data holding register for the user stream.
    tx_user_holding_reg: process (clk) is
    begin
      if rising_edge(clk) then
        if reset = '1' then
          userData <= (others => '0');
          userRequest <= '0';
        elsif clkEn = '1' then
          if (userRequest = '0' or userAck = '1') and user2sw_txStrobe = '1' then
            userData <= user2sw_txData;
            userRequest <= '1';
          elsif userAck = '1' then
            userRequest <= '0';
          end if;
        end if;
      end if;
    end process;
    
    -- The busy signal should be high while the holding register is nonempty.
    sw2user_txBusy <= userRequest and not userAck;
    
    
    
  end block;
  
end Behavioral;

