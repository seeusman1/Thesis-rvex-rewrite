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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--=============================================================================
-- This component of the system ACE peripheral sequences the register accesses
-- needed to read or write a 512-byte sector from or to the CompactFlash card.
-------------------------------------------------------------------------------
entity periph_sysace_front is
--=============================================================================
  port (
    
    -- Synchronous reset.
    reset33                     : in  std_logic;
    
    -- System ACE clock.
    clk33                       : in  std_logic;
    
    -- Register access request port. This uses the same timing/handshake scheme
    -- as the r-VEX bus.
    reg_address                 : out std_logic_vector(6 downto 0);
    reg_readEnable              : out std_logic;
    reg_readData                : in  std_logic_vector(7 downto 0);
    reg_writeEnable             : out std_logic;
    reg_writeData               : out std_logic_vector(7 downto 0);
    reg_busy                    : in  std_logic;
    reg_ack                     : in  std_logic;
    
    -- Buffer interface. This should be connected to a 512x8 bit RAM.
    buf_address                 : out std_logic_vector(8 downto 0);
    buf_readEnable              : out std_logic;
    buf_readData                : in  std_logic_vector(7 downto 0);
    buf_writeEnable             : out std_logic;
    buf_writeData               : out std_logic_vector(7 downto 0);
    
    -- Command interface. ack is asserted during the last cycle of the access.
    -- The request signal must go low the cycle after the ack. The request
    -- signal and sector should remain stable throughout the whole command.
    cmd_sector                  : in  std_logic_vector(27 downto 0);
    cmd_read                    : in  std_logic;
    cmd_write                   : in  std_logic;
    cmd_ack                     : out std_logic
    
  );
end periph_sysace_front;

--=============================================================================
architecture behavioral of periph_sysace_front is
--=============================================================================

  -- State machine state.
  type state_type is (
    idle, request_lock, wait_lock,
    set_sector_0, set_sector_1, set_sector_2, set_sector_3,
    set_sector_count, set_command, reset_cfg_ctrl,
    copy, release_lock
  );
  signal state, state_next      : state_type;
  
  -- Current buffer copy address.
  signal copy_addr              : std_logic_vector(8 downto 0);
  signal copy_addr_inc          : std_logic;
  signal copy_addr_reset        : std_logic;
  
--=============================================================================
begin
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- Instantiate the combinatorial part of the FSM
  -----------------------------------------------------------------------------
  fsm_comb: process (
    reg_readData, reg_ack,
    buf_readData,
    cmd_sector, cmd_read, cmd_write,
    state, copy_addr
  ) is
  begin
    
    -- Defaults for the backend command interface.
    reg_address     <= (others => '0');
    reg_readEnable  <= '0';
    reg_writeEnable <= '0';
    reg_writeData   <= buf_readData;
    
    -- Defaults for the buffer command interface.
    buf_address     <= copy_addr;
    buf_readEnable  <= '0';
    buf_writeEnable <= '0';
    buf_writeData   <= reg_readData;
    
    -- Defaults for our command interface.
    cmd_ack <= '0';
    
    -- Defaults for the next state.
    state_next <= state;
    copy_addr_inc <= '0';
    copy_addr_reset <= '0';
    
    case state is
      
      -------------------------------------------------------------------------
      when idle => -- Wait for the next task.
      -------------------------------------------------------------------------
        if cmd_read = '1' or cmd_write = '1' then
          state_next <= request_lock;
        end if;
      
      -------------------------------------------------------------------------
      when request_lock => -- Requests CF lock for the MPU interface.
      -------------------------------------------------------------------------
        reg_address <= "0011000";
        reg_writeData <= "00000010";
        if reg_ack = '0' then
          reg_writeEnable <= '1';
        else
          state_next <= wait_lock;
        end if;
      
      -------------------------------------------------------------------------
      when wait_lock => -- Waits until the MPU receives control over the CF
                        -- interface. This can potentially take a long time.
      -------------------------------------------------------------------------
        reg_address <= "0000100";
        if reg_ack = '0' then
          reg_readEnable <= '1';
        elsif reg_readData(1) = '1' then
          state_next <= set_sector_0;
        end if;
      
      -------------------------------------------------------------------------
      when set_sector_0 => -- Sets bit 7..0 of the sector address.
      -------------------------------------------------------------------------
        reg_address <= "0010000";
        reg_writeData <= cmd_sector(7 downto 0);
        if reg_ack = '0' then
          reg_writeEnable <= '1';
        else
          state_next <= set_sector_1;
        end if;
      
      -------------------------------------------------------------------------
      when set_sector_1 => -- Sets bit 15..8 of the sector address.
      -------------------------------------------------------------------------
        reg_address <= "0010001";
        reg_writeData <= cmd_sector(15 downto 8);
        if reg_ack = '0' then
          reg_writeEnable <= '1';
        else
          state_next <= set_sector_2;
        end if;
      
      -------------------------------------------------------------------------
      when set_sector_2 => -- Sets bit 23..16 of the sector address.
      -------------------------------------------------------------------------
        reg_address <= "0010010";
        reg_writeData <= cmd_sector(23 downto 16);
        if reg_ack = '0' then
          reg_writeEnable <= '1';
        else
          state_next <= set_sector_3;
        end if;
      
      -------------------------------------------------------------------------
      when set_sector_3 => -- Sets bit 27..24 of the sector address.
      -------------------------------------------------------------------------
        reg_address <= "0010011";
        reg_writeData <= "0000" & cmd_sector(27 downto 24);
        if reg_ack = '0' then
          reg_writeEnable <= '1';
        else
          state_next <= set_sector_count;
        end if;
      
      -------------------------------------------------------------------------
      when set_sector_count => -- Sets the sector count to 1 (hardcoded).
      -------------------------------------------------------------------------
        reg_address <= "0010100";
        reg_writeData <= "00000001";
        if reg_ack = '0' then
          reg_writeEnable <= '1';
        else
          state_next <= set_command;
        end if;
      
      -------------------------------------------------------------------------
      when set_command => -- Sets the command register to read or write sector.
      -------------------------------------------------------------------------
        reg_address <= "0010101";
        if cmd_read = '1' then
          reg_writeData <= "00000011";
        else
          reg_writeData <= "00000100";
        end if;
        if reg_ack = '0' then
          reg_writeEnable <= '1';
        else
          state_next <= reset_cfg_ctrl;
        end if;
      
      -------------------------------------------------------------------------
      when reset_cfg_ctrl => -- Resets the configuration controller. According
                             -- to the manual this is needed, don't ask me why.
      -------------------------------------------------------------------------
        reg_address <= "0011000";
        reg_writeData <= "10000010";
        if reg_ack = '0' then
          reg_writeEnable <= '1';
        else
          state_next <= copy;
          copy_addr_reset <= '1';
        end if;
      
      -------------------------------------------------------------------------
      when copy => -- Copy from the System ACE buffer to the sector buffer or
                   -- vice versa, byte by byte.
      -------------------------------------------------------------------------
        reg_address <= "100000" & copy_addr(0);
        buf_readEnable <= cmd_write;
        if reg_ack = '0' then
          reg_writeEnable <= cmd_write;
          reg_readEnable <= cmd_read;
        else
          buf_writeEnable <= cmd_read;
          copy_addr_inc <= '1';
          if copy_addr = "111111111" then
            state_next <= release_lock;
          end if;
        end if;
        
      -------------------------------------------------------------------------
      when release_lock => -- Releases the MPU lock on the CompactFlash card.
      -------------------------------------------------------------------------
        reg_address <= "0011000";
        reg_writeData <= "00000000";
        if reg_ack = '0' then
          reg_writeEnable <= '1';
        else
          cmd_ack <= '1';
          state_next <= idle;
        end if;
      
    end case;
    
  end process;
  
  -----------------------------------------------------------------------------
  -- Instantiate the FSM registers
  -----------------------------------------------------------------------------
  fsm_regs: process (clk33) is
  begin
    if rising_edge(clk33) then
      if reset33 = '1' then
        state <= idle;
        copy_addr <= (others => '0');
      else
        state <= state_next;
        if copy_addr_reset = '1' then
          copy_addr <= (others => '0');
        elsif copy_addr_inc = '1' then
          copy_addr <= std_logic_vector(unsigned(copy_addr) + 1);
        end if;
      end if;
    end if;
  end process;
  
end behavioral;

