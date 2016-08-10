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

library rvex;
use rvex.common_pkg.all;
use rvex.bus_pkg.all;

entity hsi_asic_dbg_tb is
end hsi_asic_dbg_tb;

architecture behavioral of hsi_asic_dbg_tb is
  signal clk                    : std_logic := '0';
  signal reset                  : std_logic;
  signal cfg_dbg                : std_logic_vector(1 downto 0);
  signal dbgc                   : std_logic;
  signal dbgr                   : std_logic;
  signal dbg2bus                : bus_mst2slv_type;
  signal bus2dbg                : bus_slv2mst_type;
begin

  uut: entity work.hsi_asic_dbg
    port map (
      clk                       => clk,
      reset                     => reset,
      cfg_dbg                   => cfg_dbg,
      dbgc                      => dbgc,
      dbgr                      => dbgr,
      dbg2bus                   => dbg2bus,
      bus2dbg                   => bus2dbg
    );
  
  clk <= not clk after 5 ns;
  
  cfg_dbg <= "00";
  
  process is
  begin
    bus2dbg <= BUS_SLV2MST_IDLE;
    bus2dbg.readData <= (others => 'U');
    wait until dbg2bus.readEnable = '1' or dbg2bus.writeEnable = '1';
    if dbg2bus.readEnable = '1' then
      wait until rising_edge(clk);
      bus2dbg.busy <= '1';
      wait until rising_edge(clk);
      wait until rising_edge(clk);
      bus2dbg.busy <= '0';
      bus2dbg.ack <= '1';
      bus2dbg.readData <= dbg2bus.address;
      bus2dbg.readData(0) <= '1';
      bus2dbg.readData(31) <= '1';
      bus2dbg.readData(30) <= '1';
      bus2dbg.readData(28) <= '1';
      wait until rising_edge(clk);
      bus2dbg.ack <= '0';
      bus2dbg.readData <= (others => 'U');
    else
      wait until rising_edge(clk);
      bus2dbg.busy <= '1';
      wait until rising_edge(clk);
      wait until rising_edge(clk);
      bus2dbg.busy <= '0';
      bus2dbg.ack <= '1';
      wait until rising_edge(clk);
      bus2dbg.ack <= '0';
    end if;
  end process;
  
  process is
    constant test_cmd : std_logic_vector(63 downto 0)
    --  := "0001001111000010010101010101010110000000000000000000000000000000";
    --  --     [    alow    ][   ahigh    ][rd]
    --  := "0000000000000000000000000000000110000000000000000000000000000000";
    --  --                                 [rd]
      := "0001110011111111110000000011110000110010100000000000000000000000";
      --     [             write word               ]
    --  := "0001111001111111110000000001111011111100001100101000000000000000";
    --  --     [    write half high   ][    write half low    ]
    --  := "1111100111111110111110100000000011111101111000001111111110010100";
    --  --  [ write byte 3 ][ write byte 2 ][ write byte 1 ][ write byte 0 ]
    variable period : time;
  begin
    reset <= '1';
    dbgc <= '0';
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    
    case cfg_dbg is
      when "00"   => period := 40 ns;
      when "01"   => period := 20 ns;
      when others => period := 10 ns;
    end case;
    
    reset <= '0';
    wait for 50 ns; -- random
    for i in 1 to 10 loop
      for i in test_cmd'range loop
        if dbgc = '0' and test_cmd(i) = '1' then
          dbgc <= 'L';
          wait for period * 0.25;
          dbgc <= 'H';
          wait for period * 0.25;
          dbgc <= '1';
          wait for period * 0.5;
        elsif dbgc = '1' and test_cmd(i) = '0' then
          dbgc <= 'H';
          wait for period * 0.25;
          dbgc <= 'L';
          wait for period * 0.25;
          dbgc <= '0';
          wait for period * 0.5;
        else
          dbgc <= test_cmd(i);
          wait for period;
        end if;
      end loop;
      wait for 1 ns;
    end loop;
    wait;
  end process;
  
end Behavioral;

