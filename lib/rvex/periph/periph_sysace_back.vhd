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

library unisim;
use unisim.vcomponents.all;

--=============================================================================
-- This component of the system ACE peripheral handles interfacing with the
-- off-chip controller, up to and including the register read/write timing. It
-- exposes a register read/write interface with busy/ack handshaking like the
-- r-VEX bus.
-------------------------------------------------------------------------------
entity periph_sysace_back is
--=============================================================================
  port (
    
    -- Synchronous reset.
    reset33                     : in    std_logic;
    
    -- System ACE clock.
    clk33                       : in    std_logic;
    
    -- System ACE interface (pads).
    sysace_d                    : inout std_logic_vector(7 downto 0);
    sysace_a                    : out   std_logic_vector(6 downto 0);
    sysace_brdy                 : in    std_logic;
    sysace_ce                   : out   std_logic;
    sysace_oe                   : out   std_logic;
    sysace_we                   : out   std_logic;
    
    -- Register access request port. This uses the same timing/handshake scheme
    -- as the r-VEX bus.
    reg_address                 : in    std_logic_vector(6 downto 0);
    reg_readEnable              : in    std_logic;
    reg_readData                : out   std_logic_vector(7 downto 0);
    reg_writeEnable             : in    std_logic;
    reg_writeData               : in    std_logic_vector(7 downto 0);
    reg_busy                    : out   std_logic;
    reg_ack                     : out   std_logic
    
  );
end periph_sysace_back;

--=============================================================================
architecture behavioral of periph_sysace_back is
--=============================================================================
  
  -- Buffered pin signals.
  signal sysace_d_i             : std_logic_vector(7 downto 0);
  signal sysace_d_o             : std_logic_vector(7 downto 0);
  signal sysace_d_e             : std_logic;
  signal sysace_a_o             : std_logic_vector(6 downto 0);
  signal sysace_brdy_i          : std_logic;
  signal sysace_ce_o            : std_logic;
  signal sysace_oe_o            : std_logic;
  signal sysace_we_o            : std_logic;
  
  -- Registered buffered pin signals.
  signal sysace_d_ir            : std_logic_vector(7 downto 0);
  signal sysace_d_or            : std_logic_vector(7 downto 0);
  signal sysace_d_er            : std_logic;
  signal sysace_a_or            : std_logic_vector(6 downto 0);
  signal sysace_brdy_ir         : std_logic;
  signal sysace_ce_or           : std_logic;
  signal sysace_oe_or           : std_logic;
  signal sysace_we_or           : std_logic;
  
  -- State machine state.
  type fsm_type is (idle, rc0, rc1, wc0, end0, end1);
  signal state, state_next      : fsm_type;
  signal ack_next               : std_logic;
  
--=============================================================================
begin
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- Instantiate pad primitives
  -----------------------------------------------------------------------------
  sysace_d_p7: iobuf port map (IO=>sysace_d(7), I=>sysace_d_o(7), O=>sysace_d_i(7), T=>sysace_d_e);
  sysace_d_p6: iobuf port map (IO=>sysace_d(6), I=>sysace_d_o(6), O=>sysace_d_i(6), T=>sysace_d_e);
  sysace_d_p5: iobuf port map (IO=>sysace_d(5), I=>sysace_d_o(5), O=>sysace_d_i(5), T=>sysace_d_e);
  sysace_d_p4: iobuf port map (IO=>sysace_d(4), I=>sysace_d_o(4), O=>sysace_d_i(4), T=>sysace_d_e);
  sysace_d_p3: iobuf port map (IO=>sysace_d(3), I=>sysace_d_o(3), O=>sysace_d_i(3), T=>sysace_d_e);
  sysace_d_p2: iobuf port map (IO=>sysace_d(2), I=>sysace_d_o(2), O=>sysace_d_i(2), T=>sysace_d_e);
  sysace_d_p1: iobuf port map (IO=>sysace_d(1), I=>sysace_d_o(1), O=>sysace_d_i(1), T=>sysace_d_e);
  sysace_d_p0: iobuf port map (IO=>sysace_d(0), I=>sysace_d_o(0), O=>sysace_d_i(0), T=>sysace_d_e);
  sysace_a_p6: obuf port map (O=>sysace_a(6), I=>sysace_a_o(6));
  sysace_a_p5: obuf port map (O=>sysace_a(5), I=>sysace_a_o(5));
  sysace_a_p4: obuf port map (O=>sysace_a(4), I=>sysace_a_o(4));
  sysace_a_p3: obuf port map (O=>sysace_a(3), I=>sysace_a_o(3));
  sysace_a_p2: obuf port map (O=>sysace_a(2), I=>sysace_a_o(2));
  sysace_a_p1: obuf port map (O=>sysace_a(1), I=>sysace_a_o(1));
  sysace_a_p0: obuf port map (O=>sysace_a(0), I=>sysace_a_o(0));
  sysace_brdy_p: ibuf port map (I=>sysace_brdy, O=>sysace_brdy_i);
  sysace_ce_p: obuf port map (O=>sysace_ce, I=>sysace_ce_o);
  sysace_oe_p: obuf port map (O=>sysace_oe, I=>sysace_oe_o);
  sysace_we_p: obuf port map (O=>sysace_we, I=>sysace_we_o);
  
  -----------------------------------------------------------------------------
  -- Infer pad registers
  -----------------------------------------------------------------------------
  -- These registers should be merged into the FPGA pad units, thereby
  -- guaranteeing correct timing.
  process (clk33) is
  begin
    if rising_edge(clk33) then
      sysace_d_ir <= sysace_d_i;
      sysace_d_o <= sysace_d_or;
      sysace_d_e <= sysace_d_er;
      sysace_a_o <= sysace_a_or;
      sysace_brdy_ir <= sysace_brdy_i;
      sysace_ce_o <= sysace_ce_or;
      sysace_oe_o <= sysace_oe_or;
      sysace_we_o <= sysace_we_or;
    end if;
  end process;
  
  -----------------------------------------------------------------------------
  -- Register timing diagrams
  -----------------------------------------------------------------------------
  -- The timing for accessing registers is as follows.
  -- 
  -- Read:
  -- 
  --     |============================================|
  --     | idle   | rc0    | rc1    | end0   | end1   |
  --     |============================================|
  -- ar  |-valid--------------------------------------|
  -- a   |????????|-valid-----------------------------|
  -- cer |__________________________,-----------------|
  -- ce  |--------.__________________________,--------|
  -- wer |--------------------------------------------|
  -- we  |--------------------------------------------|
  -- oer |-----------------.________,-----------------|
  -- oe  |--------------------------.________,--------|
  -- d   |zzzzzzzzzzzzzzzzzzzzzzzzzz|-valid--|zzzzzzzz|
  -- dir |???????????????????????????????????|-valid--|
  -- di  |??????????????????????????|-valid--|????????|
  -- dor |????????????????????????????????????????????|
  -- do  |????????????????????????????????????????????|
  -- der |--------------------------------------------|
  -- de  |--------------------------------------------|
  -- ackn|___________________________________,--------|
  --                                             ^
  --                                             |
  --                          ack_next is only asserted if the buffer
  -- Write:                  was not accessed or the buffer was ready.
  --
  --     |===================================|
  --     | idle   | wc0    | end0   | end1   |
  --     |===================================|
  -- ar  |-valid-----------------------------|
  -- a   |????????|-valid--------------------|
  -- cer |_________________,-----------------|
  -- ce  |--------._________________,--------|
  -- wer |--------.________,-----------------|
  -- we  |-----------------.________,--------|
  -- oer |-----------------------------------|
  -- oe  |-----------------------------------|
  -- d   |zzzzzzzzzzzzzzzzz|-valid--|zzzzzzzz|
  -- dir |???????????????????????????????????|
  -- di  |???????????????????????????????????|
  -- dor |-valid-----------------------------|
  -- do  |????????|-valid--------------------|
  -- der |--------.________,-----------------|
  -- de  |-----------------.________,--------|
  -- ackn|__________________________,--------|
  --                                    ^
  --                                    |
  --                 ack_next is only asserted if the buffer
  --                was not accessed or the buffer was ready.
  -- 
  -----------------------------------------------------------------------------
  -- Register timing logic/FSM
  -----------------------------------------------------------------------------
  -- Forward write data and address directly.
  sysace_d_or <= reg_writeData;
  sysace_a_or <= reg_address;
  
  -- The combinatorial part of the state machine.
  fsm_comb: process (
    state, reg_readEnable, reg_writeEnable, reg_address, sysace_brdy_ir
  ) is
  begin
    
    -- Default outputs.
    sysace_d_er  <= '1';
    sysace_ce_or <= '1';
    sysace_we_or <= '1';
    sysace_oe_or <= '1';
    ack_next     <= '0';
    state_next   <= idle;
    
    case state is
      
      when idle =>
        
        -- If there is a pending request for a normal register or the buffer
        -- while it is ready, start a read/write cycle.
        if reg_address(6) = '0' or sysace_brdy_ir = '1' then
          if reg_writeEnable = '1' then
            sysace_ce_or <= '0';
            state_next   <= wc0;
          elsif reg_readEnable = '1' then
            sysace_ce_or <= '0';
            state_next   <= rc0;
          end if;
        end if;
      
      when rc0 =>
        sysace_ce_or <= '0';
        state_next   <= rc1;
      
      when rc1 =>
        sysace_ce_or <= '0';
        sysace_oe_or <= '0';
        state_next   <= end0;
      
      when wc0 =>
        sysace_d_er  <= '0';
        sysace_ce_or <= '0';
        sysace_we_or <= '0';
        state_next   <= end0;
        
      when end0 =>
        state_next   <= end1;
        
      when end1 =>
        
        -- Acknowledge if this was not a data buffer access or if the buffer
        -- was ready.
        if reg_address(6) = '0' or sysace_brdy_ir = '1' then
          ack_next <= '1';
        end if;
      
    end case;
  end process;
  
  -- Instantiate the state machine registers.
  fsm_reg: process (clk33) is
  begin
    if rising_edge(clk33) then
      if reset33 = '1' then
        state <= idle;
        reg_ack <= '0';
        reg_busy <= '0';
        reg_readData <= (others => '0');
      else
        state <= state_next;
        
        -- Create the ack signal.
        reg_ack <= ack_next;
        
        -- Create the busy signal.
        if ack_next = '1' then
          reg_busy <= '0';
        elsif reg_readEnable = '1' or reg_writeEnable = '1' then
          reg_busy <= '1';
        end if;
        
        -- Register the read data when we're acking.
        if ack_next = '1' then
          reg_readData <= sysace_d_ir;
        end if;
        
      end if;
    end if;
  end process;
  
  
end behavioral;

