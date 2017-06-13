-- r-VEX processor
-- Copyright (C) 2008-2016 by TU Delft.
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

-- Copyright (C) 2008-2016 by TU Delft.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

library rvex;
use rvex.simUtils_pkg.all;

--=============================================================================
-- This testbench does some basic tests on the ML605 toplevel entity.
-------------------------------------------------------------------------------
entity ml605_tb is
end ml605_tb;
--=============================================================================

--=============================================================================
architecture Behavioral of ml605_tb is
--=============================================================================
  
  -- 200 MHz system clock source.
  signal sysclk_p               : std_logic;
  signal sysclk_n               : std_logic;
  
  -- USB-UART bridge.
  signal rx                     : std_logic;
  signal tx                     : std_logic;
  
  -- LEDs/J62.
  signal leds                   : std_logic_vector(7 downto 0);
  
  -- CPU reset button.
  signal resetButton            : std_logic;
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -- Instantiate the unit-under-test.
  uut: entity work.ml605
    generic map (
      -- Baud rate to use for the UART.
      F_BAUD                    => 125000.0,
      
      -- When set, sysclk_p and resetButton are directly fed into the rvex and
      -- UART block as clk and reset. This may be used to speed up simulation
      -- when full syscon accuracy is not needed. When set, F_SYSCLK is used to
      -- configure the baud rate of the UART; it is ignored otherwise.
      DIRECT_RESET_AND_CLOCK    => true,
      F_SYSCLK                  => 1000000.0,
      
      -- Register consistency check configuration (see core.vhd).
      RCC_RECORD                => "",
      RCC_CHECK                 => "",
      RCC_CTXT                  => 0
    )
    port map (
      
      -- 200 MHz system clock source.
      sysclk_p                  => sysclk_p,
      sysclk_n                  => sysclk_n,
      
      -- USB-UART bridge.
      rx                        => rx,
      tx                        => tx,
      
      -- LEDs/J62.
      leds                      => leds,
      
      -- CPU reset button.
      resetButton               => resetButton
      
    );
  
  -- Generate the 200 MHz differential system clock.
--  sys_clk_proc: process is
--  begin
--    sysclk_p <= '1';
--    sysclk_n <= '0';
--    wait for 2.5 ns;
--    sysclk_p <= '0';
--    sysclk_n <= '1';
--    wait for 2.5 ns;
--  end process;
  
  -- Generate a 1 MHz direct clock for simulation.
  sys_clk_proc: process is
  begin
    sysclk_p <= '1';
    wait for 500 ns;
    sysclk_p <= '0';
    wait for 500 ns;
  end process;
  
  -- Reset for a bit when starting.
  reset_button_proc: process is
  begin
    resetButton <= '1';
    wait until rising_edge(sysclk_p);
    wait until rising_edge(sysclk_p);
    wait until rising_edge(sysclk_p);
    wait until rising_edge(sysclk_p);
    resetButton <= '0';
    wait;
  end process;
  
  -----------------------------------------------------------------------------
  -- Stimulus-generating UART.
  -----------------------------------------------------------------------------
  stim_uart: block is
    
    signal reset                  : std_logic;
    signal clk                    : std_logic;
    signal raw_rx_data            : std_logic_vector(7 downto 0);
    signal raw_rx_frameError      : std_logic;
    signal raw_rx_strobe          : std_logic;
    signal raw_tx_data            : std_logic_vector(7 downto 0);
    signal raw_tx_strobe          : std_logic;
    signal raw_tx_busy            : std_logic;
    
  begin
    
    -- Generate clock.
    process is
    begin
      clk <= '1';
      wait for 500 ns;
      clk <= '0';
      wait for 500 ns;
    end process;
    
    -- Report bytes sent by the unit-under-test.
    --process is
    --begin
    --  loop
    --    wait until rising_edge(clk) and raw_rx_strobe = '1';
    --    wait for 1 ns;
    --    dumpStdOut("                                 Receive " & rvs_hex(raw_rx_data));
    --  end loop;
    --end process;
    
    -- Generate raw UART to communicate with the unit under test.
    uart_inst: entity rvex.utils_uart
      generic map (
        F_CLK                     => 1000000.0,
        F_BAUD                    => 125000.0,--115200.0,--125000.0,
        ENABLE_TX                 => true,
        ENABLE_RX                 => true
      )
      port map (
        reset                     => reset,
        clk                       => clk,
        clkEn                     => '1',
        
        rx                        => tx,
        rx_data                   => raw_rx_data,
        rx_frameError             => raw_rx_frameError,
        rx_strobe                 => raw_rx_strobe,
        
        tx                        => rx,
        tx_data                   => raw_tx_data,
        tx_strobe                 => raw_tx_strobe,
        tx_busy                   => raw_tx_busy
      );
    
    -- Generate stimuli.
    process is
      procedure transmit(data: std_logic_vector) is
      begin
        dumpStdOut("Transmit " & rvs_hex(data));
        wait until rising_edge(clk) and raw_tx_busy = '0';
        raw_tx_strobe <= '1';
        raw_tx_data <= data;
        wait until rising_edge(clk);
        raw_tx_strobe <= '0';
        raw_tx_data <= (others => 'U');
      end transmit;
    begin
      reset <= '1';
      raw_tx_strobe <= '0';
      raw_tx_data <= (others => 'U');
      wait until rising_edge(clk);
      wait until rising_edge(clk);
      reset <= '0';
      wait until rising_edge(clk);
      wait for 10 us;
      wait until rising_edge(clk);
      
      -- CRC computation: http://www.zorc.breitbandkatze.de/crc.html
      -- order = 8
      -- poly = 07
      -- initial = 00, direct
      -- final xor = 00
      -- no reverse options
      
--      -- Transmit some random user stuff.
--      transmit(X"03");
--      transmit(X"55");
--      transmit(X"AA");
--      transmit(X"FF");
--      
--      -- Set the bulk write page to 1 (0x00001000..0x00001FFF).
--      transmit(X"FD");
--      transmit(X"A2");
--      transmit(X"00");
--      transmit(X"00");
--      transmit(X"10");
--      transmit(X"A3"); -- %A2%00%00%10
--      --transmit(X"FE");
--      
--      -- Send bulk write command to index 100 (0x-----AF0)
--      transmit(X"FD");
--      transmit(X"B3");
--      transmit(X"64");
--      transmit(X"DE");
--      transmit(X"AD");
--      transmit(X"BE");
--      transmit(X"EF");
--      transmit(X"DE");
--      transmit(X"AD");
--      transmit(X"C0");
--      transmit(X"DE");
--      transmit(X"01");
--      transmit(X"02");
--      transmit(X"03");
--      transmit(X"04");
--      transmit(X"72"); -- %B3%64%DE%AD%BE%EF%DE%AD%C0%DE%01%02%03%04
--      --transmit(X"FE");
--      
--      -- Send bulk read command for address 0x00001AF0..0x00001AFC
--      transmit(X"FD");
--      transmit(X"C4");
--      transmit(X"00");
--      transmit(X"00");
--      transmit(X"1A");
--      transmit(X"F0");
--      transmit(X"FC"); -- Escape
--      transmit(X"03"); -- 0xFC
--      transmit(X"F5"); -- %C4%00%00%1A%F0%FC
--      transmit(X"FE");
--      
--      -- Send bulk read commands for address 0x00001AF0..0x00001B0C to get packet loss
--      for i in 0 to 5 loop
--        transmit(X"FD");
--        transmit(X"C5");
--        transmit(X"00");
--        transmit(X"00");
--        transmit(X"1A");
--        transmit(X"F0");
--        transmit(X"0C"); -- 0xFC
--        transmit(X"02"); -- %C5%00%00%1A%F0%0C
--      end loop;
--      transmit(X"FE");
      
      wait;
    end process;
    
  end block;
  
end Behavioral;

