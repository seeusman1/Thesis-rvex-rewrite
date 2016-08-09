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
-- This is the ASIC side of the off-chip memory bus interconnect. Timing is as
-- follows. Each signal is shown for both the ASIC and FPGA, with delays added
-- (2 characters) based on the direction of the signal, thus taking off-chip
-- propagation delay into account. data marked as ---- means hi-Z, although it
-- is presumed that bus keepers will be enabled at the ASIC and/or the FPGA,
-- so the previous state will be maintained.
--
-- Setup and sample timing is shown above and below the signals. Key for setup:
--        v : change signal value
--        < : change signal value from hi-Z
--        > : disable output
--        . : one of multiple sources is enabling output, but others are still
--            keeping it disabled
--
-- Key for sample:
--        ^ : sample here
--        - : sample here, but value is unused
--   ^ -> ^ : sample at first or second ^ depending on config; beyond the input
--            buffer the timing is always at the second ^
--   - .. - : same as above, but value is unused
-- 
--
-- READ WITHOUT LATENCY CYCLES (1X BUS SPEED):
-- 
--             ____      ____      ____      ____      ____      ____      _
--  fpga clk  /    \____/    \____/    \____/    \____/    \____/    \____/ 
--               ____      ____      ____      ____      ____      ____     
--  asic clk  __/    \____/    \____/    \____/    \____/    \____/    \____
-- 
--     setup  ______________   _______      <  _______>                _____
-- fpga data  _____Idle_____XXX__C1___XX>---<XX__RES__XX>-----------<XX_____
--    sample  ^         ^         ^         -         -         -         ^
-- 
--     setup  __v_________v  _______>   >        _______   .      <  _______
-- asic data  ____Idle____XXX__C1___XX>-------<XX__RES__XX>-------<XX_______
--    sample  . -    - .. -    - .. -    - .. -    ^ -> ^    - .. -    - ..
--                                     __________________
-- fpga /oen  ____________________/XXX/                  \XXX\______________
--                                       __________________       
-- asic /oen  ______________________/XXX/                  \XXX\____________
--            ______________________________________________________________
--  fpga ack  _______Trace_buf_state________///       \\\__Trace_buf_state__
--            ______________________________________________________________
--  asic ack  ________Trace_buf_state_________///       \\\_Trace_buf_state_
--    sample  . -    - .. -    - .. -    - .. -    ^ -> ^    - .. -    - ..
-- 
-- 
-- READ WITH ONE LATENCY CYCLE (1X BUS SPEED):
-- 
--             ____      ____      ____      ____      ____      ____      ____      _
--  fpga clk  /    \____/    \____/    \____/    \____/    \____/    \____/    \____/ 
--               ____      ____      ____      ____      ____      ____      ____     
--  asic clk  __/    \____/    \____/    \____/    \____/    \____/    \____/    \____
-- 
--     setup  ______________   _______                <  _______>                _____
-- fpga data  _____Idle_____XXX__C1___XX>-------------<XX__RES__XX>-----------<XX_____
--    sample  ^         ^         ^         -         -         -         -         ^
-- 
--     setup  __v_________v  _______>   >                  _______   .      <  _______
-- asic data  ____Idle____XXX__C1___XX>-----------------<XX__RES__XX>-------<XX_______
--    sample  . -    - .. -    - .. -    - .. -    - .. -    ^ -> ^    - .. -    - ..
--                                     ____________________________
-- fpga /oen  ____________________/XXX/                            \XXX\______________
--                                       ____________________________       
-- asic /oen  ______________________/XXX/                            \XXX\____________
--    sample  . -    - .. -    - .. -    - .. -    ^ -> ^    ^ -> ^    - .. -    - ..
--            ______________________________             _____________________________
--  fpga ack  _______Trace_buf_state________\\\_______///       \\\__Trace_buf_state__
--            ________________________________             ___________________________
--  asic ack  ________Trace_buf_state_________\\\_______///       \\\_Trace_buf_state_
--    sample  . -    - .. -    - .. -    - .. -    ^ -> ^    ^ -> ^    - .. -    - ..
-- 
-- 
-- INSTRUCTION READ WITH ONE LATENCY CYCLE IN THE MIDDLE (1X BUS SPEED):
-- 
--             ____      ____      ____      ____      ____      ____      ____      ____      ____      ____      ____      ____      ____      ____      _
--  fpga clk  /    \____/    \____/    \____/    \____/    \____/    \____/    \____/    \____/    \____/    \____/    \____/    \____/    \____/    \____/ 
--               ____      ____      ____      ____      ____      ____      ____      ____      ____      ____      ____      ____      ____      ____     
--  asic clk  __/    \____/    \____/    \____/    \____/    \____/    \____/    \____/    \____/    \____/    \____/    \____/    \____/    \____/    \____
--            
-- 
--     setup  ______________   _______      <  _______v  _______v  _______v  _______>         <  _______v  _______v  _______v  _______>                _____
-- fpga data  _____Idle_____XXX__C1___XX>---<XX__R0___XXX__R1___XXX__R2___XXX__R3___XX>-------<XX__R4___XXX__R5___XXX__R6___XXX__R7___XX>-----------<XX_____
--    sample  ^         ^         ^         -         -         -         -         -         -         -         -         -         -         -         ^
-- 
--     setup  __v_________v  _______>   >        _______   _______   _______   _______             _______   _______   _______   _______   .      <  _______
-- asic data  ____Idle____XXX__C1___XX>-------<XX__R0___XXX__R1___XXX__R2___XXX__R3___XX>-------<XX__R4___XXX__R5___XXX__R6___XXX__R7___XX>-------<XX_______
--    sample  . -    - .. -    - .. -    - .. -    ^ -> ^    ^ -> ^    ^ -> ^    ^ -> ^    - .. -    ^ -> ^    ^ -> ^    ^ -> ^    ^ -> ^    - .. -    - ..
--                                     __________________________________________________________________________________________________
-- fpga /oen  ____________________/XXX/                                                                                                  \XXX\______________
--                                       __________________________________________________________________________________________________       
-- asic /oen  ______________________/XXX/                                                                                                  \XXX\____________
--            ______________________________________________________________________             ___________________________________________________________
--  fpga ack  _______Trace_buf_state________///                                     \\\_______///                                     \\\__Trace_buf_state__
--            ________________________________________________________________________             _________________________________________________________
--  asic ack  ________Trace_buf_state_________///                                     \\\_______///                                     \\\_Trace_buf_state_
--    sample  . -    - .. -    - .. -    - .. -    ^ -> ^    ^ -> ^    ^ -> ^    ^ -> ^    ^ -> ^    ^ -> ^    ^ -> ^    ^ -> ^    ^ -> ^    - .. -    - ..
-- 
-- 
-- WRITE WITHOUT LATENCY CYCLES (1X BUS SPEED):
--             ____      ____      ____      ____      ____      ____      _
--  fpga clk  /    \____/    \____/    \____/    \____/    \____/    \____/ 
--               ____      ____      ____      ____      ____      ____     
--  asic clk  __/    \____/    \____/    \____/    \____/    \____/    \____
-- 
--     setup  ______________   _______   _______                       _____
-- fpga data  _____Idle_____XXX__C1___XXX__C2___XX>-----------------<XX_____
--    sample  ^         ^         ^         ^         -         -         ^ 
-- 
--     setup  __v_________v  _______v  _______>                      _______
-- asic data  ____Idle____XXX__C1___XXX__C2___XX>-----------------<XX_______
--    sample  . -    - .. -    - .. -    - .. -    - .. -    - .. -    - .. 
--                                                                          
-- fpga /oen  ______________________________________________________________
--                                                                          
-- asic /oen  ______________________________________________________________
--    sample  . -    - .. -    - .. -    - .. -    - .. -    - .. -    - .. 
--            ______________________________________________________________
--  fpga ack  _______Trace_buf_state________///       \\\__Trace_buf_state__
--            ______________________________________________________________
--  asic ack  ________Trace_buf_state_________///       \\\_Trace_buf_state_
--    sample  . -    - .. -    - .. -    - .. -    ^ -> ^    - .. -    - ..
-- 
-- 
-- WRITE WITH ONE LATENCY CYCLE (1X BUS SPEED):
--             ____      ____      ____      ____      ____      ____      ____      _
--  fpga clk  /    \____/    \____/    \____/    \____/    \____/    \____/    \____/ 
--               ____      ____      ____      ____      ____      ____      ____     
--  asic clk  __/    \____/    \____/    \____/    \____/    \____/    \____/    \____
-- 
--     setup  ______________   _______   _______                                 _____
-- fpga data  _____Idle_____XXX__C1___XXX__C2___XX>---------------------------<XX_____
--    sample  ^         ^         ^         ^         -         -         -         ^ 
-- 
--     setup  __v_________v  _______v  _______>                                _______
-- asic data  ____Idle____XXX__C1___XXX__C2___XX>---------------------------<XX_______
--    sample  . -    - .. -    - .. -    - .. -    - .. -    - .. -    - .. -    - .. 
--                                                                                              
-- fpga /oen  ________________________________________________________________________
--                                                                                    
-- asic /oen  ________________________________________________________________________
--    sample  . -    - .. -    - .. -    - .. -    - .. -    - .. -    - .. -    - .. 
--            ______________________________             _____________________________
--  fpga ack  _______Trace_buf_state________\\\_______///       \\\__Trace_buf_state__
--            ________________________________             ___________________________
--  asic ack  ________Trace_buf_state_________\\\_______///       \\\_Trace_buf_state_
--    sample  . -    - .. -    - .. -    - .. -    ^ -> ^    ^ -> ^    - .. -    - ..
-- 
-- 
-- READ WITHOUT LATENCY CYCLES (1/2X AND 1/4X BUS SPEED):
-- 
--             _    _    _    _    _    _    _    _    _    _    _    _    _
--  fpga clk  / \__/ \__/ \__/ \__/ \__/ \__/ \__/ \__/ \__/ \__/ \__/ \__/ 
--  | 1/2X |     _    _    _    _    _    _    _    _    _    _    _    _   
--  asic clk  __/ \__/ \__/ \__/ \__/ \__/ \__/ \__/ \__/ \__/ \__/ \__/ \__
--                 
--  fpga clk  /\/\_/\/\_/\/\_/\/\_/\/\_/\/\_/\/\_/\/\_/\/\_/\/\_/\/\_/\/\_/\
--  | 1/4X |  
--  asic clk  \_/\/\_/\/\_/\/\_/\/\_/\/\_/\/\_/\/\_/\/\_/\/\_/\/\_/\/\_/\/\_
--            ____   _______   _______   _______   _______   _______   _____
-- fpga sync  ____XXX_______XXX_______XXX_______XXX_______XXX_______XXX_____
--            __   _______   _______   _______   _______   _______   _______
-- asic sync  __XXX_______XXX_______XXX_______XXX_______XXX_______XXX_______
-- 
--     setup  ______________   _______      <  _______>                _____
-- fpga data  _____Idle_____XXX__C1___XX>---<XX__RES__XX>-----------<XX_____
--    sample  ^         ^         ^         -         -         -         ^
-- 
--     setup  __v_________v  _______>   >        _______   .      v  _______
-- asic data  ____Idle____XXX__C1___XX>-------<XX__RES__XX>-------<XX_______
--    sample           -         -         -         ^         -         - 
--                                     __________________
-- fpga /oen  ____________________/XXX/                  \XXX\______________
--                                       __________________       
-- asic /oen  ______________________/XXX/                  \XXX\____________
--            ______________________________________________________________
--  fpga ack  _______Trace_buf_state________///       \\\__Trace_buf_state__
--            ______________________________________________________________
--  asic ack  ________Trace_buf_state_________///       \\\_Trace_buf_state_
--    sample           -         -         -         ^         -         - 
--
-------------------------------------------------------------------------------
entity hsi_asic_mem is
--=============================================================================
  port (
    
    -- Clock/reset signals.
    clk                         : in  std_logic;
    reset                       : in  std_logic;
    
    -- Timing configuration. Controls the bus speed and when setup/sample is
    -- performed. In the diagram below, ! means setup, ? means sample, and |
    -- means setup and sample. Which configuration will work best depends on
    -- the signal integrity and achieved delay matching in the ASIC. It also
    -- depends on the FPGA design.
    --                      _   _   _   _   _
    --                clk _/ \_/ \_/ \_/ \_/ 
    --                    _ _______________ _
    --                syn _X_______________X_
    --            
    -- "00" = 1/4x:        !           ?   !
    -- "01" = 1/2x:        !     ? !     ? !
    -- "10" = 1x rising:   !  ?!  ?!  ?!  ?!
    -- "11" = 1x falling:  ! ? ! ? ! ? ! ? !
    cfg_mem                     : in  std_logic_vector(1 downto 0);
    
    -- External side.
    data_in                     : in  std_logic_vector(31 downto 0);
    data_out                    : out std_logic_vector(31 downto 0);
    data_oen                    : out std_logic;
    oen_n                       : in  std_logic;
    ack                         : in  std_logic;
    
    -- Internal side.
    bus2mem                     : in  bus_mst2slv_type;
    mem2bus                     : out bus_slv2mst_type;
    
    -- Trace interface.
    trace_push                  : in  std_logic;
    trace_data                  : in  std_logic_vector(7 downto 0);
    trace_busy                  : out std_logic
    
  );
end hsi_asic_mem;

--=============================================================================
architecture behavioral of hsi_asic_mem is
--=============================================================================
  
  -- Sync signal, toggles every 4 cycles.
  signal sync                   : std_logic;
  
  -- Strobe signal. This functions as a clock enable for the external interface
  -- logic. It is active high in the last cycle of each bus word transfer.
  signal strobe                 : std_logic;
  
  -- This signal is active high in the first cycle of each bus word transfer.
  signal strobe_first           : std_logic;
  
  -- Registered data input.
  signal data_in_r              : std_logic_vector(31 downto 0);
  signal ack_in_r               : std_logic;
  
  -- Whether the external bus FSM is expecting data or not. If this signal,
  -- strobe_first, and ack_in_r are all high, then data_in_r is valid and the
  -- bus request should be acknowledged.
  signal response_valid_r       : std_logic;
  
  -- High when trace data will be sent to the FPGA in the next cycle.
  signal trace_pull             : std_logic;
  
  -- Current number of bytes in the trace buffer.
  signal trace_count            : std_logic_vector(1 downto 0);
  
  -- Trace buffer shift register.
  signal trace_shreg            : std_logic_vector(23 downto 0);
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- Strobe/sync signal generation
  -----------------------------------------------------------------------------
  -- The sync signal always toggles every 4 clock cycles. The strobe signal is
  -- the (internal) clock enable signal used to decrease the bus clock speed.
  sync_strobe_block: block is
    
    -- Binary counter, increments every cycle.
    signal counter              : std_logic_vector(2 downto 0);
    
  begin
    
    -- Instantiate the counter.
    counter_proc: process (clk) is
    begin
      if rising_edge(clk) then
        if reset = '1' then
          counter <= "000";
        else
          counter <= std_logic_vector(unsigned(counter) + 1);
        end if;
      end if;
    end process;
    
    -- The sync signal is just bit 2 of the counter.
    sync <= counter(2);
    
    -- The strobe signals depend on the mem_cfg signal.
    strobe <= cfg_mem(1) or ((cfg_mem(0) or counter(1)) and counter(0));
    strobe_first <= cfg_mem(1) or ((cfg_mem(0) or not counter(1)) and not counter(0));
    
  end block;
  
  -----------------------------------------------------------------------------
  -- Data input pin logic
  -----------------------------------------------------------------------------
  -- Circuit:
  -- 
  -- clk --o-------------------------------.         
  --       |     .---.                     |
  --       o-----|>r |              .======|=========.
  --       |  .==|d q|==.           |      |         |
  --       |  |  '---'  |   _       |   _  |  .---.  |
  --       |  |  .---.  '==|1\    _ '==|0\ '--|>r |  |
  --       '--+--|>f |     |  |==|0\   |  |===|d q|==o==> internal data
  --          o==|d q|=====|0/   |  |==|1/    '---'                 
  --          |  '---'      ^ .==|1/    ^
  -- pad =====o=============|='   ^     |
  --             ___        |     |     |
  -- cfg1 ------\   \       |     |     |
  --             )   )o-----'     |     |
  --         .--/___/             |     |
  --         |                    |     |
  -- cfg0 ---o--------------------'     |
  -- strobe ----------------------------'
  --
  -- The above circuit is shown for the ack signal. The data signals are
  -- handled similarly, except strobe is replaced with strobe and ack and
  -- oen_n.
  data_in_block: block is
    
    -- Whether the falling or rising edge input register should be used (if
    -- any).
    signal input_mode           : std_logic;
    
    -- Falling-edge registered data input.
    signal data_in_r_if         : std_logic_vector(32 downto 0);
    signal ack_in_r_if          : std_logic;
    signal oen_n_in_r_if        : std_logic;
    
    -- Rising-edge registered data input.
    signal data_in_r_ir         : std_logic_vector(32 downto 0);
    signal ack_in_r_ir          : std_logic;
    signal oen_n_in_r_ir        : std_logic;
    
    -- Multiplexed ack/oen input signal based on mem_cfg.
    signal ack_in_mux           : std_logic;
    signal oen_n_in_mux         : std_logic;
    
  begin
    
    -- Determine whether we should sample on falling instead of rising edges.
    input_mode <= cfg_mem(0) nor cfg_mem(1);
    
    -- ack input mux.
    ack_in_mux_proc: process (
      cfg_mem, input_mode, ack_in_r_if, ack_in_r_ir, ack
    ) is
    begin
      if cfg_mem(0) = '0' then
        if input_mode = '0' then
          ack_in_r <= ack_in_r_if;
        else
          ack_in_r <= ack_in_r_ir;
        end if;
      else
        ack_in_r <= ack;
      end if;
    end process;
    
    -- oen_n input mux.
    oen_n_in_mux_proc: process (
      cfg_mem, input_mode, oen_n_in_r_if, oen_n_in_r_ir, oen_n
    ) is
    begin
      if cfg_mem(0) = '0' then
        if input_mode = '0' then
          oen_n_in_r <= oen_n_in_r_if;
        else
          oen_n_in_r <= oen_n_in_r_ir;
        end if;
      else
        oen_n_in_r <= oen_n;
      end if;
    end process;
    
    -- Instantiate the input registers, which look like this:
    data_in_reg_proc: process (clk) is
    begin
      if falling_edge(clk) then
        
        -- Falling edge data input.
        data_in_r_if <= data_in;
        ack_in_r_if <= ack;
        oen_n_in_r_if <= oen_n;
        
      end if;
      if rising_edge(clk) then
      
        -- Rising edge data input.
        data_in_r_ir <= data_in;
        ack_in_r_ir <= ack;
        oen_n_in_r_ir <= oen_n;
        
        -- ack holding register.
        if strobe = '1' then
          ack_in_r <= ack_in_mux;
        end if;
        
        -- Data holding register. To conserve some power, we only update this
        -- register when we're receiving data (it directly drives potentially
        -- the entire memory bus).
        if strobe = '1' and ack_in_mux = '1' and oen_n_in_mux = '1' then
          if cfg_mem(0) = '0' then
            if input_mode = '0' then
              data_in_r <= data_in_r_if;
            else
              data_in_r <= data_in_r_ir;
            end if;
          else
            data_in_r <= data_in;
          end if;
        end if;
        
      end if;
    end process;
    
  end block;
  
  -----------------------------------------------------------------------------
  -- Data output and FSM
  -----------------------------------------------------------------------------
  -- This section controls the data output. The following encoding is used.
  --
  --  1101-0-  Idle:          00S0000- -------- -------- -------0  S=sync
  --  1101-0-  Trace data A:  00S0100- -------- -------T TTTTTTT0  T=trace data
  --  1101-0-  Trace data B:  00S1000- -------T TTTTTTTT TTTTTTT0  T=trace data
  --  1101-0-  Trace data C:  00S1100T TTTTTTTT TTTTTTTT TTTTTTT0  T=trace data
  --  000010-  Read insn:     00AAAAAA AAAAAAAA AAAAAAAA AAAAA001  A=8-word address
  --  000001-  Read word:     01AAAAAA AAAAAAAA AAAAAAAA AAAAAAAA  A=word address
  --  000000-  Write word 1:  10AAAAAA AAAAAAAA AAAAAAAA AAAAAAAA  A=word address
  --  000001-  Write half 1:  11AAAAAA AAAAAAAA AAAAAAAA AAAAAAAA  A=word address
  --  001--00  Write word 2:  DDDDDDDD DDDDDDDD dddddddd dddddddd  D=hdat, d=ldat
  --  101--10  Write half 2:  -------- ----MMMM dddddddd dddddddd  M=mask, d=ldat
  --  111--11  Write half 2:  -------- ----MMMM DDDDDDDD DDDDDDDD  M=mask, D=hdat
  --  ^^^^^^^
  --  ||||||`- mux bit 0 = wmask(0) nor wmask(1)
  --  |||||`-- mux bit 1 = (wmask != "1111") when writeEnable = '1' else (readEnable and not burst)
  --  ||||`--- mux bit 2 = burst
  --  |||`---- mux bit 3 = readEnable nor writeEnable
  --  ||`----- mux bit 4 = state bit 0
  --  |`------ mux bit 5 = mux bit 0 when mux bit 4 = '1' else mux bit 3
  --  `------- mux bit 6 = mux bit 1 when mux bit 4 = '1' else mux bit 3
  data_out_block: block is
    
    -- Various hand-optimized mux signals, see above.
    signal mux                  : std_logic_vector(6 downto 0);
    
    -- External bus FSM state.
    signal state_r              : std_logic_vector(3 downto 0);
    signal state_next           : std_logic_vector(3 downto 0);
    
    -- Command modes, one-hot encoded. Set for any state except 0. x_r is set
    -- when x is high and cleared when state_rst is high.
    signal state_rst            : std_logic;
    signal state_read           : std_logic;
    signal state_read_r         : std_logic;
    signal state_insn           : std_logic;
    signal state_insn_r         : std_logic;
    signal state_write          : std_logic;
    signal state_write_r        : std_logic;
    
    -- When _r is high, the data output drivers must be disabled, regardless of
    -- the state of oen_n. output_disable sets output_disable_r in the next
    -- cycle, state_rst clears it.
    signal output_disable       : std_logic;
    signal output_disable_r     : std_logic;
    
    -- These signals set/reset response_valid_r (global signal).
    signal response_validate    : std_logic;
    signal response_invalidate  : std_logic;
    
  begin
    
    -- Generate the mux signals.
    mux(0) <= bus2mem.writeMask(0) nor bus2mem.writeMask(1);
    mux(1) <= (bus2mem.writeMask /= "1111") when bus2mem.writeEnable = '1'
              else (bus2mem.readEnable and not bus2mem.flags.burstStart);
    mux(2) <= bus2mem.flags.burstStart;
    mux(3) <= bus2mem.readEnable nor bus2mem.writeEnable;
    mux(4) <= state_r(0);
    mux(5) <= mux(0) when mux(4) = '1' else mux(3);
    mux(6) <= mux(1) when mux(4) = '1' else mux(3);
    
    -- Determine whether we should send trace data in the next bus transfer.
    trace_pull <= (trace_count(0) or trace_count(1))
              and (bus2mem.writeEnable nor bus2mem.readEnable)
              and strobe
              and not busy;
    
    -- Generate the output multiplexers and registers.
    data_out_reg_proc: process (clk) is
    begin
      if rising_edge(clk) then
        if strobe = '1' then
          
          -- Bit 31 and 30.
          if mux(4) = '0' then
            data_out(31) <= bus2mem.writeEnable;
            data_out(30) <= mux(1);
          else
            data_out(31 downto 30) <= bus2mem.writeData(31 downto 30);
          end if;
          
          -- Bit 29..16.
          case mux(6 downto 6) & mux(4 downto 4) is
            when "00" => -- Command.
              data_out(29 downto 16) <= bus2mem.address(31 downto 18);
            when "01" => -- Word data.
              data_out(29 downto 16) <= bus2mem.writeData(29 downto 16);
            when "10" => -- Trace data.
              data_out(29) <= sync;
              if trace_pull = '1' then
                data_out(28 downto 27) <= trace_count;
              else
                data_out(28 downto 27) <= "00";
              end if;
              data_out(26 downto 25) <= "00";
              data_out(24 downto 16) <= trace_shreg(23 downto 15);
            when others => -- Half data.
              data_out(29 downto 20) <= (others => '0');
              data_out(19 downto 16) <= bus2mem.writeMask;
          end case;
          
          -- Bit 15..0.
          case mux(5 downto 4) is
            when "00" => -- Command.
              data_out(15 downto 1) <= bus2mem.address(17 downto 3);
              data_out(0) <= bus2mem.address(2) or mux(2);
            when "01" => -- Lower write data.
              data_out(15 downto 0) <= bus2mem.writeData(15 downto 0);
            when "10" => -- Trace data.
              data_out(15 downto 1) <= trace_shreg(14 downto 0);
              data_out(0) <= '0';
            when others => -- Upper write data.
              data_out(15 downto 0) <= bus2mem.writeData(31 downto 16);
          end case;
          
        end if;
      end if;
    end process;
    
    -- Drive data output enable.
    data_oen <= output_disable_r nor oen_n;
    
    -- FSM registers.
    fsm_reg: process (clk) is
    begin
      if rising_edge(clk) then
        if reset = '1' then
          state_r          <= "0000";
          output_disable_r <= '0';
          state_read_r     <= '0';
          state_insn_r     <= '0';
          state_write_r    <= '0';
          response_valid_r <= '0';
        elsif strobe = '1' and (ack_in_r or not response_valid_r) then
          
          -- State register.
          state_r <= state_next;
          
          -- State flags.
          if state_rst = '1' then
            output_disable_r <= '0';
            state_read_r     <= '0';
            state_insn_r     <= '0';
            state_write_r    <= '0';
          else
            if output_disable = '1' then
              output_disable_r <= '1';
            end if;
            if state_read = '1' then
              state_read_r <= '1';
            end if;
            if state_insn = '1' then
              state_insn_r <= '1';
            end if;
            if state_write = '1' then
              state_write_r <= '1';
            end if;
          end if;
          
          -- Input valid register.
          if response_invalidate = '1' then
            response_valid_r <= '0';
          elsif response_validate = '1' then
            response_valid_r <= '1';
          end if;
          
        end if;
      end if;
    end process;
    
    -- FSM logic.
    fsm_comb: process (
      state_r, state_read_r, state_insn_r, state_write_r,
      ack_in_r, bus2mem
    ) is
    begin
      
      -- Set default control signal values.
      state_next <= std_logic_vector(unsigned(state_r) + 1);
      state_rst <= '0';
      output_disable <= '0';
      state_read <= '0';
      state_insn <= '0';
      state_write <= '0';
      response_validate <= '0';
      response_invalidate <= '0';
      
      if state_r(3) = '0' then
        case state_r(1 downto 0) is
          when "00" => -- bus: previous
            state_read <= bus2mem.readEnable and not bus2mem.flags.burstStart;
            state_insn <= bus2mem.readEnable and bus2mem.flags.burstStart;
            state_write <= bus2mem.writeEnable;
            state_next(0) <= bus2mem.writeEnable or bus2mem.readEnable;
            
          when "01" => -- bus: command 1
            output_disable <= not state_write_r;
            
          when "10" => -- bus: command 2 for write, hi-Z for read
            output_disable <= '1';
          
          when "11" => -- bus: first response (which will have been sampled by
                        -- the time we end up in the next state)
            response_validate <= '1';
            -- Next state:
            --   read:  1111
            --   insn:  1000
            --   write: 1111
            state_next <= (
              3 => '1',
              2 downto 0 => not state_insn_r
            );
          
        end case;
        
      else -- if state_r(3) = '1' then
        
        if state_r(2 downto 0) = "111" then -- bus: hi-Z (last response sampled)
          state_rst <= '1';
          response_invalidate <= '1';
        end if;
        
        -- bus: read response or hi-Z (always a response sampled)
        state_next <= std_logic_vector(unsigned(state_next) + 1);
        
      end if;
      
    end process;
    
  end block;
  
  -----------------------------------------------------------------------------
  -- r-VEX bus interfacing logic
  -----------------------------------------------------------------------------
  rvex_bus_block: block is
    
    -- Acknowledgement and busy signals for the bus.
    signal ack                  : std_logic;
    signal busy                 : std_logic;
    
    -- Whether a the r-VEX bus was requesting something in the previous cycle.
    signal requesting_r         : std_logic;
    
    -- This signal is asserted when the first r-VEX bus request has been ack'd,
    -- but the external bus is still receiving data; i.e. during a burst,
    -- except for the first request.
    signal bursting             : std_logic;
    
  begin
    
    -- Acknowledge the r-VEX bus if:
    ack <= response_valid_r  -- - the input registers contain valid data;
       and ack_in_r          -- - the input registers contain an ack;
       and strobe_first      -- - this is be the first cycle of an external bus
       and (                 --   word transfer;
         (                   -- - and either:
            bus2mem.flags.burstEnable         -- the r-VEX bus is doing a burst
            and not bus2mem.flags.burstStart  -- and this is not the first xfer
         ) or not bursting     -- or the external bus is not bursting
       );
    
    -- The r-VEX bus is busy when there was a request in the previous cycle and
    -- we're not currently acknowledging it.
    busy <= requesting_r and not ack;
    
    -- Infer the requesting_r register.
    requesting_r_proc: process (clk) is
    begin
      if rising_edge(clk) then
        if reset = '1' then
          requesting_r <= '0';
        else
          requesting_r <= bus2mem.readEnable or bus2mem.writeEnable;
        end if;
      end if;
    end process;
    
    -- Detect when an external bus burst is going on (anything but the first
    -- response).
    burst_detect_proc: process (clk) is
    begin
      if rising_edge(clk) then
        if reset = '1' then
          bursting <= '0';
        else
          if response_valid_r = '0' then
            bursting <= '0';
          elsif ack = '1' then
            bursting <= '1';
          end if;
        end if;
      end if;
    end process;
    
    -- Drive the r-VEX bus response.
    rvex_bus_response_proc: process (ack, busy, data_in_r) is
      variable s : bus_slv2mst_type;
    begin
      s := BUS_SLV2MST_IDLE;
      s.readData := data_in_r;
      s.ack := ack;
      s.busy := busy;
      mem2bus <= s;
    end process;
    
  end block;
  
  -----------------------------------------------------------------------------
  -- Trace buffer logic
  -----------------------------------------------------------------------------
  -- Instantiate the trace buffer logic.
  trace_buffer_proc: process (clk) is
  begin
    if rising_edge(clk) then
      if trace_push = '1' and trace_count /= "11" then
        trace_shreg <= trace_shreg(15 downto 0) & trace_data;
        if trace_pull = '1' then
          trace_count <= "01";
        else
          case trace_count is
            when "00"   => trace_count <= "01";
            when "01"   => trace_count <= "10";
            when others => trace_count <= "11";
          end case;
        end if;
      elsif trace_pull = '1' then
        trace_count <= "00";
      end if;
      if reset = '1' then
        trace_count <= "00";
      end if;
    end if;
  end process;
  
  -- Trace buffer busy output to the core.
  trace_busy <= trace_count(0) and trace_count(1);
  
end Behavioral;

