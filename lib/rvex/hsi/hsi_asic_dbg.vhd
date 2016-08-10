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
    
    -- Delay calibration pattern signals.
    cal_dbgc_in                 : out std_logic;
    cal_dbgr_out                : in  std_logic;
    
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
  
  -- Request signals from the command receiving logic. The argument signals
  -- remain stable after until the next request is made, so they can be tied
  -- directly to the bus, and can also be used in the response phase.
  signal request_enable         : std_logic;
  signal request_write          : std_logic;
  signal request_autoinc        : std_logic;
  signal request_address        : std_logic_vector(31 downto 0);
  signal request_writeData      : std_logic_vector(31 downto 0);
  signal request_writeMask      : std_logic_vector(3 downto 0);
  
  -- Bus response signals. response_readData is only valid while
  -- response_enable is high.
  signal response_enable        : std_logic;
  signal response_readData      : std_logic_vector(31 downto 0);
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- Input synchronization logic
  -----------------------------------------------------------------------------
  -- This block handles the bit timing of the dbgc input.
  input_sync_inst: entity work.hsi_dbg_sync
    port map (
      clk                       => clk,
      reset                     => reset,
      cfg_dbg                   => cfg_dbg,
      dbgx                      => dbgc,
      cal_dbgx_in               => cal_dbgc_in,
      dbgx_s                    => dbgc_s,
      dbgx_s_valid              => dbgc_s_valid,
      dbgx_last                 => dbgc_last
    );
  
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
    
    -- Power-saving latch/register inputs.
    signal request_enable_d     : std_logic;
    signal request_write_d      : std_logic;
    signal request_autoinc_d    : std_logic;
    signal request_writeMask_d  : std_logic_vector(3 downto 0);
    
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
        if response_enable = '1' and request_autoinc = '1' then
          alow_r  <= std_logic_vector(unsigned(alow_r) + 1);
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
      request_enable_d <= '0';
      request_write_d <= '0';
      
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
              request_enable_d <= dbgc_s_valid;
              request_write_d <= state_r(6);
              
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
    
    -- Decode the write mask.
    mask_high <= (not wmode_r(3)) or wmode_r(1);
    mask_low  <= (not wmode_r(3)) or not wmode_r(1);
    mask_odd  <= (not wmode_r(2)) or wmode_r(0);
    mask_even <= (not wmode_r(2)) or not wmode_r(0);
    request_writeMask_d(3) <= mask_low and mask_even;
    request_writeMask_d(2) <= mask_low and mask_odd;
    request_writeMask_d(1) <= mask_high and mask_even;
    request_writeMask_d(0) <= mask_high and mask_odd;
    
    -- Determine whether we should auto-increment the low word address after
    -- this request.
    request_autoinc_d <= request_writeMask_d(0) or not request_write_d;
    
    -- The write data and address from the shift registers could functionally
    -- be connected directly to the bus. However, these signals have a high
    -- level of activity, and the bus signals will probably be decently long.
    -- So to cut back on activity and thus power, we insert latches into the
    -- path, latching when the request is made. To make sure the signals are
    -- stable while the latch is transparent and to prevent hazards in the
    -- request enable signal doing funny stuff, we insert a register for that
    -- signal.
    request_enable_regs: process (clk) is
    begin
      if rising_edge(clk) then
        if reset = '1' then
          request_enable <= '0';
        else
          request_enable <= request_enable_d;
        end if;
        if request_enable_d = '1' then
          request_write <= request_write_d;
          request_autoinc <= request_autoinc_d;
        end if;
      end if;
    end process;
    request_data_latches: process (
      request_enable, ahigh_r, alow_r, request_writeMask_d, wdata_r
    ) is
    begin
      if request_enable = '1' then
        request_address <= "0000000000" & ahigh_r & alow_r & "00";
        request_writeMask <= request_writeMask_d;
        request_writeData <= wdata_r;
      end if;
    end process;
    
  end block;
  
  -----------------------------------------------------------------------------
  -- r-VEX bus logic
  -----------------------------------------------------------------------------
  rvex_bus_block: block is
    
    -- This signal is low while we're doing a request.
    signal requesting_n         : std_logic;
    
  begin
    
    -- Keep requesting while the bus is reporting busy.
    requesting_n <= request_enable nor bus2dbg.busy;
    
    -- Drive the bus master interface. Note by the way that this is done in a
    -- process like this for forward compatibility, in case signals are added
    -- to the bus interface records later.
    bus_drive_proc: process (
      requesting_n, request_write, request_address, request_writeMask,
      request_writeData
    ) is
      variable s : bus_mst2slv_type;
    begin
      s := BUS_MST2SLV_IDLE;
      s.readEnable  := requesting_n nor request_write;
      s.writeEnable := requesting_n nor not request_write;
      s.address     := request_address;
      s.writeMask   := request_writeMask;
      s.writeData   := request_writeData;
      dbg2bus <= s;
    end process;
    
    -- Read the response data.
    response_enable   <= bus2dbg.ack;
    response_readData <= bus2dbg.readData;
    
  end block;
  
  -----------------------------------------------------------------------------
  -- Response logic
  -----------------------------------------------------------------------------
  response_block: block is
    
    -- Read data shift register.
    signal rdata_r              : std_logic_vector(31 downto 0);
    signal rdata_shift          : std_logic;
    
    -- Transmitter state. Encoding:
    --   000000--  Stop bit/idle
    --   011110--  Start bit
    --   011111--  Write enable
    --   100000--  Read data 31
    --   100001--  Read data 30
    --   ::::::::  ::::: ::
    --   111110--  Read data 1
    --   111111--  Read data 0
    -- The LSBs are used to divide the clock down to the bus speed.
    signal state_next, state_r  : std_logic_vector(7 downto 0);
    
  begin
    
    -- Infer the registers.
    reg_proc: process (clk) is
    begin
      if rising_edge(clk) then
        if reset = '1' then
          state_r <= (others => '0');
        else
          state_r <= state_next;
        end if;
        if response_enable = '1' then
          rdata_r <= response_readData;
        elsif state_r(7) = '1' and state_next(1) = '0' and state_next(0) = '0' then
          rdata_r <= rdata_r(30 downto 0) & rdata_r(0 downto 0);
        end if;
      end if;
    end process;
    
    -- Determine the next transmitter state.
    state_logic_proc: process (
      state_r, cfg_dbg, response_enable, request_write
    ) is
      variable state_add        : std_logic_vector(7 downto 0);
    begin
      
      -- Determine how much to add to the state.
      state_add := (
        0 => cfg_dbg(0) nor cfg_dbg(1),
        1 => cfg_dbg(0) and not cfg_dbg(1),
        2 => cfg_dbg(1),
        others => '0'
      );
      
      -- Infer the state adder.
      state_next <= std_logic_vector(unsigned(state_r) + unsigned(state_add));
      
      -- If we're idle, keep the state at zero. We only have to override the
      -- LSBs to do this because the other bits that come from the adder will
      -- always be zero in this case anyway.
      if state_r(7) = '0' and state_r(6) = '0' then
        state_next(2 downto 0) <= "000";
      end if;
      
      -- If a new transfer should be started, the state should be set to
      -- 01111000.
      if response_enable = '1' then
        state_next(6 downto 3) <= "1111";
      end if;
      
      -- If the request we're responding to was a write, we shouldn't sent the
      -- read data. We can do this simply by clamping the MSB of the state down
      -- to zero.
      if request_write = '1' then
        state_next(7) <= '0';
      end if;
      
    end process;
    
    -- Determine the output bit and register it to prevent glitches on the pin.
    output_pin_reg: process (clk) is
    begin
      if rising_edge(clk) then
        if reset = '1' then
          dbgr <= cal_dbgr_out;
        else
          case state_r(7 downto 6) is
            when "00"   => dbgr <= '0';
            when "01"   => dbgr <= request_write or not state_r(2);
            when others => dbgr <= rdata_r(31);
          end case;
        end if;
      end if;
    end process;
    
  end block;
  
end Behavioral;

