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

-- Refer to reconfICache_pkg.vhd for configuration constants and most
-- documentation.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library rvex;
use rvex.cache_instr_pkg.all;

entity cache_instr_missCtrl is
  port (
    
    -- Clock input.
    clk                       : in  std_logic;
    
    -- Active high reset input.
    reset                     : in  std_logic;
    
    -- Active high clock enable input for the CPU domain.
    clkEnCPU                  : in  std_logic;
    
    -- Active high clock enable input for the bus domain.
    clkEnBus                  : in  std_logic;
    
    -- CPU address/PC input.
    cpuAddr                   : in  std_logic_vector(RIC_PC_WIDTH-1 downto 0);
    
    -- Update enable signal from the mux/demux logic signalling that the
    -- cache line which contains cpuAddr should be refreshed. While an
    -- update is in progress, cpuAddr is assumed to be stable. Governed by 
    -- the clkEnCPU clock gate signal.
    updateEnable              : in  std_logic;
    
    -- Signals that the line fetch is complete and that the data in line is
    -- to be written to the data memory. Governed by the clkEnCPU clock gate
    -- signal.
    done                      : out std_logic;
    
    -- Cache line data output, valid when done is high.
    line                      : out std_logic_vector(RIC_LINE_WIDTH-1 downto 0);
    
    -- Connections to the memory bus. Governed by clkEnBus.
    memToCache                : in  reconfICache_memIn;
    cacheToMem                : out reconfICache_memOut
    
  );
end cache_instr_missCtrl;

architecture Behavioral of cache_instr_missCtrl is
  
  -- Current state.
  signal state                : integer range 0 to RIC_BUS_PER_LINE+1;
  
  -- When set, advances to the next state.
  signal advance              : std_logic;
  
  -- When set, returns to idle state.
  signal resetState           : std_logic;
  
  -- Next state.
  signal state_next           : integer range 0 to RIC_BUS_PER_LINE+1;
  
  -- State names.
  constant IDLE_STATE         : integer := 0;
  constant REQ_N_STATE        : integer := RIC_BUS_PER_LINE;
  constant WAIT_STATE         : integer := RIC_BUS_PER_LINE+1;
  
  -- Line buffer registers.
  signal line_buffer          : std_logic_vector(RIC_LINE_WIDTH-1 downto 0);
  
begin
  
  --===========================================================================
  -- FSM documentation
  --===========================================================================
  -- This component implements the following FSM to handle cache line retrieval
  -- over the memory bus, taking sycnhronization of the two clock gate domains
  -- into consideration. This allows the CPU to be stopped for debugging
  -- without the bus being affected somehow, for example.
  --
  --       reset
  --         v                   | idle state, waiting for commands. Part 0 of
  --     .-------.               | the line is already requested when advance
  -- .-->| idle  | - - - - - - - | is high, but the FSM passes through req_0
  -- |   '-------'               | regardless of the done output to save on
  -- |       | clkEnCPU          | logic resources.
  -- |       v & updateEnable      
  -- |   .-------.               | Requesting cache line part 0 on the memory
  -- |   | req_0 | - - - - - - - | bus, i.e. readEnable is high. When advance
  -- |   '-------'               | is high, the read data is stored in r0.
  -- |       | clkEnBus
  -- |       v & mem.ready
  -- |      ...  - - - - - - - - | Same behavior as req_0 for next parts.
  -- |       | clkEnBus
  -- |       v & mem.ready
  -- |   .-------.               | Same behavior as req_0, but now when advance
  -- |`--| req_n | - - - - - - - | is high done is also asserted. line is set
  -- | * '-------'               | to r0..rn-1 & mem.data.
  -- |       | clkEnBus
  -- |       | & mem.ready       * clkEnBus & ready & clkEnCpu
  -- |       v & !clkEnCpu
  -- |   .-------.               
  -- |   | wait  | - - - - - - - | done is asserted, line is set to r0..rn.
  -- |   '-------'
  -- |       | clkEnCpu
  -- '-------'
  -- 
  -- advance is used to go to the next state, resetState is used to return to
  -- the idle state.
  
  --===========================================================================
  -- FSM control
  --===========================================================================
  fsm_ctrl: process(clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        state <= 0;
      else
        state <= state_next;
      end if;
    end if;
  end process;
  
  --===========================================================================
  -- FSM state decoding
  --===========================================================================
  -- Determine the values for the advance and resetState signals.
  fsm_decode_1: process (
    state, clkEnCPU, clkEnBus, updateEnable, memToCache.ready
  ) is
  begin
    
    -- Do nothing by default.
    advance <= '0';
    resetState <= '0';
    
    -- Figure out what to do next.
    if state = IDLE_STATE then
      if clkEnCPU = '1' and updateEnable = '1' then
        advance <= '1';
      end if;
    elsif state = WAIT_STATE then
      if clkEnCPU = '1' then
        resetState <= '1';
      end if;
    else
      if clkEnBus = '1' and memToCache.ready = '1' then
        if clkEnCPU = '1' and state = REQ_N_STATE then
          resetState <= '1';
        else
          advance <= '1';
        end if;
      end if;
    end if;
  end process;
  
  -- Determine the next state based on the advance and resetState signals.
  state_next <= IDLE_STATE when resetState = '1' else
                state + 1  when advance = '1' else
                state;
  
  -- Determine the memory bus address and whether we should request a read.
  cacheToMem.addr(RIC_PC_WIDTH-1 downto RIC_ADDR_OFFSET_LSB)
    <= cpuAddr(RIC_PC_WIDTH-1 downto RIC_ADDR_OFFSET_LSB);
  cacheToMem.addr(RIC_BUS_SIZE_BLOG2-1 downto 0)
    <= (others => '0');
  det_mem_bus_access: process (state_next) is
  begin
    if state_next < 1 or state_next > RIC_BUS_PER_LINE then
      -- No bus access.
      cacheToMem.readEnable <= '0';
      cacheToMem.addr(RIC_ADDR_OFFSET_LSB-1 downto RIC_BUS_SIZE_BLOG2)
        <= (others => '0');
    else
      -- Request the next part.
      cacheToMem.readEnable <= '1';
      cacheToMem.addr(RIC_ADDR_OFFSET_LSB-1 downto RIC_BUS_SIZE_BLOG2)
        <= std_logic_vector(to_unsigned(state_next-1, RIC_ADDR_OFFSET_LSB-RIC_BUS_SIZE_BLOG2));
    end if;
  end process;
  
  -- Generate the done signal.
  done <= '1' when state_next = WAIT_STATE or resetState = '1' else '0';
  
  -- Instantiate the line buffer registers.
  line_buf_reg_gen: for i in 0 to RIC_BUS_PER_LINE-1 generate
    line_buf_reg_n: process (clk) is
    begin
      if rising_edge(clk) then
        if state = i + 1 then
          line_buffer((i+1)*RIC_BUS_DATA_WIDTH-1 downto i*RIC_BUS_DATA_WIDTH)
            <= memToCache.data;
        end if;
      end if;
    end process;
  end generate;
  
  -- Forward the cache line to the cache memory.
  line_buf_forward_a: if RIC_BUS_PER_LINE > 1 generate
    line(RIC_LINE_WIDTH-RIC_BUS_DATA_WIDTH-1 downto 0)
      <= line_buffer(RIC_LINE_WIDTH-RIC_BUS_DATA_WIDTH-1 downto 0);
  end generate;
  
  line(RIC_LINE_WIDTH-1 downto RIC_LINE_WIDTH-RIC_BUS_DATA_WIDTH) <=
    memToCache.data when state = WAIT_STATE - 1 else
    line_buffer(RIC_LINE_WIDTH-1 downto RIC_LINE_WIDTH-RIC_BUS_DATA_WIDTH);
    
end Behavioral;

