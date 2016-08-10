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


--=============================================================================
-- This unit handles bit synchronization of the serial debug link. It is used
-- for the receiver in the ASIC as well as the FPGA.
-------------------------------------------------------------------------------
entity hsi_dbg_sync is
--=============================================================================
  port (
    
    -- Clock/reset signals.
    clk                         : in  std_logic;
    reset                       : in  std_logic;
    
    -- Timing configuration for dbgx.
    --
    -- cfg_dbg | start bit rising edge -> first sample | sample period
    -- --------+---------------------------------------+--------------
    -- "00"    | 5.5 to 6.0 cycles                     | 4 cycles
    -- "01"    | 2.5 to 3.0 cycles                     | 2 cycles
    -- "10"    | 1.5 to 2.0 cycles                     | 1 cycle
    -- "11"    | 1.0 to 1.5 cycles                     | 1 cycle
    --
    cfg_dbg                     : in  std_logic_vector(1 downto 0);
    
    -- Pin input.
    dbgx                        : in  std_logic;
    
    -- Delay calibration pattern output. This is just the output of the input
    -- register.
    cal_dbgx_in                 : out std_logic;
    
    -- Synchronized output.
    dbgx_s                      : out std_logic;
    dbgx_s_valid                : out std_logic;
    
    -- This should be asserted when the stop bit of the current command is
    -- expected next (and while dbgx_s_valid is high for the stop bit).
    dbgx_last                   : in  std_logic
    
  );
end hsi_dbg_sync;

--=============================================================================
architecture behavioral of hsi_dbg_sync is
--=============================================================================
  
  -- Rising-edge and falling-edge samples of dbgx.
  signal dbgx_rise            : std_logic;
  signal dbgx_fall            : std_logic;
  signal dbgx_fall_i          : std_logic;
  
  -- Register which determines whether to use the rising or falling edge
  -- register for the payload bit samples.
  signal edge_next, edge_r    : std_logic;
  
  -- State. Zero when not receiving, nonzero when receiving. When state is
  -- "001", a bit is to be sampled. In states above one, state simply counts
  -- down.
  signal state_next, state_r  : std_logic_vector(2 downto 0);
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -- Infer the DDR input registers for dbgx and the state registers for the
  -- synchronization logic.
  input_reg_proc: process (clk) is
  begin
    if falling_edge(clk) then
      dbgx_fall_i <= dbgx;
    end if;
    if rising_edge(clk) then
      dbgx_rise <= dbgx;
      dbgx_fall <= dbgx_fall_i;
      edge_r <= edge_next;
      if reset = '1' then
        state_r <= "000";
      else
        state_r <= state_next;
      end if;
    end if;
  end process;
  
  -- Forward delay calibration pattern data.
  cal_dbgx_in <= dbgx_rise;
  
  -- Detect the start bit, and determine when and how to sample the remainder
  -- of the bits based on the configuration and the detected timing of the
  -- start bit.
  input_sync_logic_comb: process (
    state_r, dbgx_fall, dbgx_rise, cfg_dbg, dbgx_last, edge_r
  ) is
  begin
    dbgx_s_valid <= '0';
    edge_next <= edge_r;
    
    case state_r is
      when "000" => -- Not currently receiving; detect incoming start bits.
        
        if to_x01(dbgx_fall) /= '0' then
          
          -- Determine when to sample the first data bit.
          case cfg_dbg is
            
            when "00" => -- 1/4x bus speed.
              --             now
              --         __   v__    __    __    __    __    __    __    __   
              -- clk  __/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \__
              --           _____________________   _____________________   ___
              -- dbgx __///                     XXX_____________________XXX___
              --                                            |      
              edge_next <= '1';
              state_next <= "101";
            
            when "01" => -- 1/2x bus speed.
              --             now
              --         __   v__    __    __    __    __    __    __    __   
              -- clk  __/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \__
              --           _________   _________   _________   _________   ___
              -- dbgx __///         XXX_________XXX_________XXX_________XXX___
              --                          |           |           |
              edge_next <= '1';
              state_next <= "010";
            
            when "10" => -- 1x bus speed, mode A.
              --             now
              --         __   v__    __    __    __    __    __    __    __   
              -- clk  __/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \__
              --           ___   ___   ___   ___   ___   ___   ___   ___   ___
              -- dbgx __///   XXX___XXX___XXX___XXX___XXX___XXX___XXX___XXX___
              --                    |     |     |     |     |     |     |     
              edge_next <= '1';
              state_next <= "001";
            
            when others => -- 1x bus speed, mode B.
              --             now
              --         __   v__    __    __    __    __    __    __    __   
              -- clk  __/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \__
              --           ___   ___   ___   ___   ___   ___   ___   ___   ___
              -- dbgx __///   XXX___XXX___XXX___XXX___XXX___XXX___XXX___XXX___
              --                 ^->|  ^->|  ^->|  ^->|  ^->|  ^->|  ^->|  ^->
              edge_next <= '0';
              state_next <= "001";
            
          end case;
        elsif to_x01(dbgx_rise) /= '0' then
          
          -- Determine when to sample the first data bit.
          case cfg_dbg is

            when "00" => -- 1/4x bus speed.
              --             now
              --         __   v__    __    __    __    __    __    __    __   
              -- clk  __/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \__
              --              _____________________   _____________________   
              -- dbgx _____///                     XXX_____________________XXX
              --                                               ^->|   
              edge_next <= '0';
              state_next <= "110";
            
            when "01" => -- 1/2x bus speed.
              --             now
              --         __   v__    __    __    __    __    __    __    __   
              -- clk  __/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \__
              --              _________   _________   _________   _________   
              -- dbgx _____///         XXX_________XXX_________XXX_________XXX
              --                             ^->|        ^->|        ^->|
              edge_next <= '0';
              state_next <= "011";

            when "10" => -- 1x bus speed, mode A.
              --             now
              --         __   v__    __    __    __    __    __    __    __   
              -- clk  __/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \__
              --              ___   ___   ___   ___   ___   ___   ___   ___   
              -- dbgx _____///   XXX___XXX___XXX___XXX___XXX___XXX___XXX___XXX
              --                       ^->|  ^->|  ^->|  ^->|  ^->|  ^->|  ^->   
              edge_next <= '0';
              state_next <= "010";

            when others => -- 1x bus speed, mode B.
              --             now
              --         __   v__    __    __    __    __    __    __    __   
              -- clk  __/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \__
              --              ___   ___   ___   ___   ___   ___   ___   ___   
              -- dbgx _____///   XXX___XXX___XXX___XXX___XXX___XXX___XXX___XXX
              --                    |     |     |     |     |     |     |     
              edge_next <= '1';
              state_next <= "001";
              
          end case;
        else
          
          -- No start bit detected, bus is idle.
          edge_next <= '0';
          state_next <= "000";
          
        end if;
      
      when "001" => -- A data bit is present on the input.
        
        -- Send the bit to the parallelization logic.
        dbgx_s_valid <= '1';
        
        -- Update the state depending on whether more bits are expected and
        -- the bitrate.
        if dbgx_last = '1' then
          state_next <= "000";
        else
          case cfg_dbg is
            when "00" => -- 1/4x bus speed.
              state_next <= "100";
            when "01" => -- 1/2x bus speed.
              state_next <= "010";
            when others => -- 1x bus speed.
              state_next <= "001";
          end case;
        end if;
        
      when others => -- Count down until we need to sample the next data bit.
        state_next <= std_logic_vector(unsigned(state_r) - 1);
        
    end case;
    
    -- Multiplex between the sample registers based on timing.
    if edge_r = '1' then
      dbgx_s <= dbgx_rise;
    else
      dbgx_s <= dbgx_fall;
    end if;
    
  end process;
  
end Behavioral;

