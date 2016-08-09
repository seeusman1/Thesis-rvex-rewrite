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
-- This is the ASIC side of the off-chip debug bus interconnect. It differs
-- from the memory bus in that this interconnect is serial while the other is
-- parallel, and that the FPGA is the master on this bus, whereas the ASIC is
-- the master on the memory bus.
--
-- Like the memory bus, setup/sample timing is reconfigurable. The options are
-- shown as documentation for the cfg_dbg input pin. The start of a message in
-- either direction is signalled by making the line high for one bus cycle (the
-- lines are idle low). The commands and responses are then as follows (with
-- the high start bit included):
-- 
-- Commands (dbgc):
--  - Set low address:
--    | 1 | 0 | 0 |A11|A10|A9 |A8 |A7 |A6 |A5 |A4 |A3 |A2 | 0 |
-- 
--  - Set high address:
--    | 1 | 0 | 1 |A21|A20|A19|A18|A17|A16|A15|A14|A13|A12| 0 |
-- 
--  - Read:
--    | 1 | 1 | 0 | 0 |
--    Replies with a read response when ready, then auto-increments the low
--    address.
-- 
--  - Write:
--    | 1 | 1 | 1 |S1 |S0 |A1 |A0 |[D31..D16][D15..D8][D7..D0]| 0 |
--    Data bits are only sent when the corresponding mask bit is set. Replies
--    with a write response when ready, then auto-increments the low address
--    if A1 and A0 are both high. The correspondence between A1, A0, S1, S0
--    and the mask bits are:
--      
--      | S1 | S0 | A1 | A0 | Write mask |
--      +----+----+----+----+------------+
--      | 0  | 0  | 1  | 1  | 1111       |
--      | 1  | 0  | 0  | 1  | 1100       |
--      | 1  | 0  | 1  | 1  | 0011       |
--      | 1  | 1  | 0  | 0  | 1000       |
--      | 1  | 1  | 0  | 1  | 0100       |
--      | 1  | 1  | 1  | 0  | 0010       |
--      | 1  | 1  | 1  | 1  | 0001       |
--
--    The behavior for unspecified values is undefined.
-- 
-- The responses are:
--  - Read response:
--    | 1 | 0 |D31|...|D0 | 0 |
-- 
--  - Write response:
--    | 1 | 1 | 0 |
-- 
-- Note that it is illegal to send a command while a read or write is in
-- progress.
-------------------------------------------------------------------------------
entity hsi_asic_dbg is
--=============================================================================
  port (
    
    -- Clock/reset signals.
    clk                         : in  std_logic;
    reset                       : in  std_logic;
    
    -- Timing configuration for dbgc.
    --
    -- cfg_dbg | start bit rising edge -> first sample | sample period
    -- --------+---------------------------------------+--------------
    -- "00"    | 5.5 to 6.0 cycles                     | 4 cycles
    -- "01"    | 2.5 to 3.0 cycles                     | 2 cycles
    -- "10"    | 1.5 to 2.0 cycles                     | 1 cycle
    -- "11"    | 1.0 to 1.5 cycles                     | 1 cycle
    --
    cfg_dbg                     : in  std_logic_vector(1 downto 0);
    
    -- External side.
    dbgc                        : in  std_logic;
    dbgr                        : out std_logic;
    
    -- Internal side.
    dbg2bus                     : out bus_mst2slv_type;
    bus2dbg                     : in  bus_slv2mst_type
    
  );
end hsi_asic_dbg;

--=============================================================================
architecture behavioral of hsi_asic_dbg is
--=============================================================================
  
  -- Synchronized debug command bits. dbgc_s is valid when dbgc_s_valid is
  -- high.
  signal dbgc_s                 : std_logic;
  signal dbgc_s_valid           : std_logic;
  
  -- This signal is high when the last bit of the current command is expected
  -- next (and while dbgc_s_valid is high for the last bit).
  signal dbgc_last              : std_logic;
  
  -- Request strobe signals from the command receiving logic.
  signal request_read           : std_logic;
  signal request_write          : std_logic;
  
  -- Bus request parameters from the command receiving logic. These remain
  -- stable while the request is in progress.
  signal request_address        : std_logic_vector(31 downto 0);
  signal request_writeData      : std_logic_vector(31 downto 0);
  signal request_writeMask      : std_logic_vector(3 downto 0);
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- Input synchronization logic
  -----------------------------------------------------------------------------
  -- This block handles the bit timing of the dbgc input.
  input_sync_block: block is
    
    -- Rising-edge and falling-edge samples of dbgc.
    signal dbgc_rise            : std_logic;
    signal dbgc_fall            : std_logic;
    signal dbgc_fall_i          : std_logic;
    
    -- Register which determines whether to use the rising or falling edge
    -- register for the payload bit samples.
    signal edge_next, edge_r    : std_logic;
    
    -- State. Zero when not receiving, nonzero when receiving. When state is
    -- "001", a bit is to be sampled. In states above one, state simply counts
    -- down.
    signal state_next, state_r  : std_logic_vector(2 downto 0);
    
  begin
    
    -- Infer the DDR input registers for dbgc and the state registers for the
    -- synchronization logic.
    input_reg_proc: process (clk) is
    begin
      if falling_edge(clk) then
        dbgc_fall_i <= dbgc;
      end if;
      if rising_edge(clk) then
        dbgc_rise <= dbgc;
        dbgc_fall <= dbgc_fall_i;
        edge_r <= edge_next;
        if reset = '1' then
          state_r <= "000";
        else
          state_r <= state_next;
        end if;
      end if;
    end process;
    
    -- Detect the start bit, and determine when and how to sample the remainder
    -- of the bits based on the configuration and the detected timing of the
    -- start bit.
    input_sync_logic_comb: process (
      state_r, dbgc_fall, dbgc_rise, cfg_dbg, dbgc_last, edge_r
    ) is
    begin
      dbgc_s_valid <= '0';
      edge_next <= edge_r;
      
      case state_r is
        when "000" => -- Not currently receiving; detect incoming start bits.
          
          if dbgc_fall = '1' then
            
            -- Determine when to sample the first data bit.
            case cfg_dbg is
              
              when "00" => -- 1/4x bus speed.
                --             now
                --         __   v__    __    __    __    __    __    __    __   
                -- clk  __/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \__
                --           _____________________   _____________________   ___
                -- dbgc __///                     XXX_____________________XXX___
                --                                            |      
                edge_next <= '1';
                state_next <= "110";
              
              when "01" => -- 1/2x bus speed.
                --             now
                --         __   v__    __    __    __    __    __    __    __   
                -- clk  __/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \__
                --           _________   _________   _________   _________   ___
                -- dbgc __///         XXX_________XXX_________XXX_________XXX___
                --                          |           |           |
                edge_next <= '1';
                state_next <= "011";
              
              when "10" => -- 1x bus speed, mode A.
                --             now
                --         __   v__    __    __    __    __    __    __    __   
                -- clk  __/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \__
                --           ___   ___   ___   ___   ___   ___   ___   ___   ___
                -- dbgc __///   XXX___XXX___XXX___XXX___XXX___XXX___XXX___XXX___
                --                    |     |     |     |     |     |     |     
                edge_next <= '1';
                state_next <= "010";
              
              when others => -- 1x bus speed, mode B.
                --             now
                --         __   v__    __    __    __    __    __    __    __   
                -- clk  __/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \__
                --           ___   ___   ___   ___   ___   ___   ___   ___   ___
                -- dbgc __///   XXX___XXX___XXX___XXX___XXX___XXX___XXX___XXX___
                --                 ^->|  ^->|  ^->|  ^->|  ^->|  ^->|  ^->|  ^->
                edge_next <= '0';
                state_next <= "010";
              
            end case;
          elsif dbgc_rise = '1' then
            
            -- Determine when to sample the first data bit.
            case cfg_dbg is

              when "00" => -- 1/4x bus speed.
                --             now
                --         __   v__    __    __    __    __    __    __    __   
                -- clk  __/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \__
                --              _____________________   _____________________   
                -- dbgc _____///                     XXX_____________________XXX
                --                                               ^->|   
                edge_next <= '0';
                state_next <= "111";
              
              when "01" => -- 1/2x bus speed.
                --             now
                --         __   v__    __    __    __    __    __    __    __   
                -- clk  __/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \__
                --              _________   _________   _________   _________   
                -- dbgc _____///         XXX_________XXX_________XXX_________XXX
                --                             ^->|        ^->|        ^->|
                edge_next <= '0';
                state_next <= "100";

              when "10" => -- 1x bus speed, mode A.
                --             now
                --         __   v__    __    __    __    __    __    __    __   
                -- clk  __/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \__
                --              ___   ___   ___   ___   ___   ___   ___   ___   
                -- dbgc _____///   XXX___XXX___XXX___XXX___XXX___XXX___XXX___XXX
                --                       ^->|  ^->|  ^->|  ^->|  ^->|  ^->|  ^->   
                edge_next <= '0';
                state_next <= "011";

              when others => -- 1x bus speed, mode B.
                --             now
                --         __   v__    __    __    __    __    __    __    __   
                -- clk  __/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \__
                --              ___   ___   ___   ___   ___   ___   ___   ___   
                -- dbgc _____///   XXX___XXX___XXX___XXX___XXX___XXX___XXX___XXX
                --                    |     |     |     |     |     |     |     
                edge_next <= '1';
                state_next <= "010";
                
            end case;
          else
            
            -- No start bit detected, bus is idle.
            edge_next <= '0';
            state_next <= "000";
            
          end if;
        
        when "001" => -- A data bit is present on the input.
          
          -- Send the bit to the parallelization logic.
          dbgc_s_valid <= '1';
          
          -- Update the state depending on whether more bits are expected and
          -- the bitrate.
          if dbgc_last = '1' then
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
        dbgc_s <= dbgc_rise;
      else
        dbgc_s <= dbgc_fall;
      end if;
      
    end process;
    
  end block;
  
  -----------------------------------------------------------------------------
  -- Input command logic
  -----------------------------------------------------------------------------
  input_cmd_block: block is
    
    -- Receiver state. Encoding:
    --   --000000: receiving first mode bit
    --   --011-1-: receiving stop bit
    --   0-000001: receiving second mode bit (first was 0)
    --   0001CCCC: receiving low address bit C next
    --   00011001: receiving last low address bit next
    --   0101CCCC: receiving high address bit C next
    --   01011001: receiving last high address bit next (last)
    --   1-000001: receiving second mode bit (first was 1)
    --   11010000: receiving mask 3
    --   11010001: receiving mask 2
    --   11010010: receiving mask 1
    --   11010011: receiving mask 0
    --   11100BBB: receiving bit 7-B of byte 3
    --   11101BBB: receiving bit 7-B of byte 2
    --   11110BBB: receiving bit 7-B of byte 1
    --   11111BBB: receiving bit 7-B of byte 0
    signal state_next, state_r  : std_logic_vector(7 downto 0);
    
    -- Address parts.
    signal alow_next, alow_r    : std_logic_vector(9 downto 0);
    signal ahigh_next, ahigh_r  : std_logic_vector(9 downto 0);
    
    -- Write mode (S1:S0:A1:A0 when shifting completes).
    signal wmode_next, wmode_r  : std_logic_vector(3 downto 0);
    
    -- Write data.
    signal wdata_next, wdata_r  : std_logic_vector(31 downto 0);
    
    -- Intermediate signals for the write mask decoder.
    signal mask_high            : std_logic;
    signal mask_low             : std_logic;
    signal mask_odd             : std_logic;
    signal mask_even            : std_logic;
    
  begin
    
    -- Infer the state registers.
    state_reg_proc: process (clk) is
    begin
      if rising_edge(clk) then
        if dbgc_s_valid = '1' then
          state_r <= state_next;
          alow_r  <= alow_next;
          ahigh_r <= ahigh_next;
          wmode_r <= wmode_next;
          wdata_r <= wdata_next;
        end if;
        if reset = '1' then
          state_r <= (others => '0');
          alow_r  <= (others => '0');
          ahigh_r <= (others => '0');
        end if;
      end if;
    end process;
    
    -- Infer the state machine logic.
    state_logic_proc: process (
      state_r, alow_r, ahigh_r, wmode_r, wdata_r, dbgc_s, dbgc_s_valid
    ) is
    begin
      
      -- Increment the state by default.
      state_next(5 downto 0) <= std_logic_vector(unsigned(state_r(5 downto 0)) + 1);
      
      -- Bit 7 and 6 of the state are the mode bits. The adder should never
      -- carry over to here.
      state_next(7 downto 6) <= state_r(7 downto 6);
      
      -- Set other default states.
      alow_next <= alow_r;
      ahigh_next <= ahigh_r;
      wmode_next <= wmode_r;
      wdata_next <= wdata_r;
      dbgc_last <= '0';
      request_read <= '0';
      request_write <= '0';
      
      if state_r(5) = '0' then -- state "--0-----"
        if state_r(4) = '0' then -- state "--00----"
          if state_r(0) = '0' then -- state "--00---0"
            
            -- Receiving the first mode bit.
            state_next(7) <= dbgc_s;
            
          else -- state "--00---1"
            
            -- Receiving the second mode bit.
            state_next(6) <= dbgc_s;
            
            if state_r(7) = '0' then
              
              -- Address command.
              state_next(5 downto 0) <= "010000";
              
            elsif dbgc_s = '0' then
              
              -- Read command.
              state_next(5 downto 0) <= "011111";
              
            else
              
              -- Write command.
              state_next(5 downto 0) <= "010000";
              
            end if;
            
          end if;
        else -- state "--01----"
          if state_r(3) = '1' and state_r(1) = '1' then -- state "--011-1-"
            
            -- Receiving stop bit.
            dbgc_last <= '1';
            state_next(5 downto 0) <= "000000";
            
            if state_r(7) = '1' then
              
              -- Handle the received command.
              request_read <= dbgc_s_valid and not state_r(6);
              request_write <= dbgc_s_valid and state_r(6);
              
            end if;
            
          elsif state_r(7) = '0' then -- state "0-01----"
            if state_r(6) = '0' then -- state "0001----"
              
              -- Receiving low address bits.
              alow_next(9 downto 1) <= alow_r(8 downto 0);
              alow_next(0) <= dbgc_s;
              
            else -- state "0101----"
              
              -- Receiving high address bits.
              ahigh_next(9 downto 1) <= ahigh_r(8 downto 0);
              ahigh_next(0) <= dbgc_s;
              
            end if;
          else -- state "1-01----"
            
            -- Receiving mask bits.
            wmode_next(3 downto 1) <= wmode_r(2 downto 0);
            wmode_next(0) <= dbgc_s;
            
            if state_r(1 downto 0) = "11" then
              
              -- Receiving the last mask bit.
              state_next(5) <= '1';
              state_next(4 downto 3) <= wmode_r(2 downto 1); -- Byte counter*.
              state_next(2 downto 0) <= "000";               -- Bit counter
              
              -- *The byte counter in the state is initialized with S1:S0,
              -- directly determining how many bytes are expected. Note that
              -- the wmode shift register has not completely shifted left yet
              -- (it will from the next cycle onwards). Therefore, we need to
              -- use bit 2:1 instead of bit 3:2, where S1:S0 would normally be.
              
            end if;
          end if;
        end if;
      else -- state "--1-----"
        
        -- Receiving write data.
        wdata_next(31 downto 1) <= wdata_r(30 downto 0);
        wdata_next(0) <= dbgc_s;
        
        if wmode_r(3) = '1' then
          
          -- We're receiving at most a halfword. So let's shift the incoming
          -- data into the high halfword and low halfword parts of the shift
          -- register simultaneously. That way we can directly use the write
          -- data shift register contents as r-VEX bus write data, without
          -- needing any wide multiplexers.
          wdata_next(16) <= dbgc_s;
          
          if wmode_r(2) = '1' then
            
            -- Receiving only a byte; perform the same trick as explained
            -- above.
            wdata_next(8) <= dbgc_s;
            wdata_next(24) <= dbgc_s;
            
          end if;
        end if;
        if state_r(4 downto 0) = "11111" then
          
          -- Receiving the last write data bit; expecting the stop bit next.
          state_next(5 downto 0) <= "011111";
          
        end if;
      end if;
    end process;
    
    -- Connect the address and write data.
    request_address <= "0000000000" & ahigh_r & alow_r & "00";
    request_writeData <= wdata_r;
    
    -- Decode the write mask.
    mask_high <= (not wmode_r(3)) or wmode_r(1);
    mask_low  <= (not wmode_r(3)) or not wmode_r(1);
    mask_odd  <= (not wmode_r(2)) or wmode_r(0);
    mask_even <= (not wmode_r(2)) or not wmode_r(0);
    request_writeMask(3) <= mask_low and mask_even;
    request_writeMask(2) <= mask_low and mask_odd;
    request_writeMask(1) <= mask_high and mask_even;
    request_writeMask(0) <= mask_high and mask_odd;
    
  end block;
  
end Behavioral;

