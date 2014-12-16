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
-- This is is part of the debug section of the UART peripheral. It buffers and
-- error-checks incoming debug packets and buffers and transmits outgoing
-- debug packets.
-------------------------------------------------------------------------------
entity periph_UART_packetControl is
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
    -- Interface with the packet handler
    ---------------------------------------------------------------------------
    -- Received packet buffer interface. When pop is high, the next byte in
    -- the buffer is selected. If no more bytes are available, empty is
    -- asserted high instead.
    pkctrl2pkhan_rxData         : out std_logic_vector(7 downto 0);
    pkhan2pkctrl_rxPop          : in  std_logic;
    pkctrl2pkhan_rxEmpty        : out std_logic;
    
    -- When high, the next packet is requested.
    pkctrl2pkhan_rxSwap         : in  std_logic;
    
    -- When high, a packet has been received and is available in the buffer.
    pkhan2pkctrl_rxReady        : out std_logic;
    
    -- Reply packet buffer interface. When push is high, data is pushed into
    -- the buffer, unless the buffer is full (in which was full will have been
    -- asserted high.
    pkhan2pkctrl_txData         : in  std_logic_vector(7 downto 0);
    pkhan2pkctrl_txPush         : in  std_logic;
    pkctrl2pkhan_txFull         : out std_logic;
    
    -- When high, the transmit buffer is reset/cleared.
    pkctrl2pkhan_txReset        : out std_logic;
    
    -- When high, the packet currently in the transmit buffer will be
    -- transmitted.
    pkctrl2pkhan_txSwap         : in  std_logic;
    
    -- When high, the transmit buffer is ready for writing.
    pkhan2pkctrl_txReady        : out std_logic;
    
    ---------------------------------------------------------------------------
    -- Interface with UART stream switch
    ---------------------------------------------------------------------------
    -- When rxStrobe is high, rxData and rxEndPacket are valid. When
    -- rxEndPacket is low, rxData contains a received byte. When rxEndPacket is
    -- high, rxData is invalid, but this rxStrobe marks the end of the packet
    -- which was being received.
    sw2pkctrl_rxData            : in  std_logic_vector(7 downto 0);
    sw2pkctrl_rxEndPacket       : in  std_logic;
    sw2pkctrl_rxStrobe          : in  std_logic;
    
    -- When txRequest is high, the UART switch should send txData. When
    -- txStartPacket is high as well, the UART switch should ensure that it is
    -- clear to the receiver that a new packet has started. When the UART
    -- switch services the request, txAck should be asserted high for one
    -- cycle.
    pkctrl2sw_txData            : out std_logic_vector(7 downto 0);
    pkctrl2sw_txStartPacket     : out std_logic;
    pkctrl2sw_txRequest         : out std_logic;
    sw2pkctrl_txAck             : in  std_logic
    
  );
end periph_UART_packetControl;

--=============================================================================
architecture Behavioral of periph_UART_packetControl is
--=============================================================================
  
  -- CRC polynomial to use for the packets, in MSB-first representation.
  constant CRC_POLYNOMIAL       : natural := 16#07#;
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- Receiver logic
  -----------------------------------------------------------------------------
  rx_block: block is
  begin
  end block;
  
  -----------------------------------------------------------------------------
  -- Transmitter logic
  -----------------------------------------------------------------------------
  tx_block: block is
    
    -- TX buffer busy signal, inverted txReady signal.
    signal pkhan2pkctrl_txBusy  : std_logic;
    
    -- Signals are todo:
    signal bufData              : std_logic_vector(7 downto 0);
    signal bufPop               : std_logic;
    signal bufEmpty             : std_logic;
    signal crc                  : std_logic_vector(7 downto 0);
    signal swap                 : std_logic;
    signal swapping             : std_logic;
    
  begin
    
    -- Instantiate the transmit packet buffer.
    tx_packet_buffer_inst: entity rvex.periph_UART_packetBuffer
      port map (
        
        -- System control.
        reset                   => reset,
        clk                     => clk,
        clkEn                   => clkEn,
        
        -- Buffer write interface.
        src2buf_data            => pkhan2pkctrl_txData,
        src2buf_push            => pkhan2pkctrl_txPush,
        bus2src_full            => pkctrl2pkhan_txFull,
        src2buf_pop             => '0',
        src2buf_reset           => pkctrl2pkhan_txReset,
        src2buf_swap            => pkctrl2pkhan_txSwap,
        bus2src_swapping        => pkhan2pkctrl_txBusy,
        
        -- Buffer read interface.
        buf2sink_data           => bufData,
        sink2buf_pop            => bufPop,
        buf2sink_empty          => bufEmpty,
        sink2buf_swap           => swap,
        bus2sink_swapping       => swapping
        
      );
    
    -- Invert the busy signal to get the ready signal.
    pkhan2pkctrl_txReady <= not pkhan2pkctrl_txBusy;
    
    tx_crc_inst: entity rvex.utils_crc
      generic map (
        CRC_ORDER               => 8,
        POLYNOMIAL              => CRC_POLYNOMIAL
      )
      port map (
        
        -- System control.
        reset                   => reset,
        clk                     => clk,
        clkEn                   => clkEn,
        
        -- CRC interface.
        data                    => bufData,
        update                  => bufPop,
        clear                   => swap,
        crc                     => crc,
        correct                 => open
        
      );
  end block;
  
end Behavioral;

