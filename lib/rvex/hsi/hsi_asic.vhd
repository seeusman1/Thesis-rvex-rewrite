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
-- This is the ASIC side of the HSI (high-speed interface) off-chip
-- interconnect. The timing for the data, oen_n, and ack pads is shown at the
-- top of hsi_asic_mem.vhd. The timing for dbgc and dbgr is shown at the top of
-- hsi_asic_dbg.vhd.
-------------------------------------------------------------------------------
entity hsi_asic is
--=============================================================================
  port (
    
    ---------------------------------------------------------------------------
    -- Pad interface
    ---------------------------------------------------------------------------
    -- Active low reset input from the reset_n pad. The schmitt-trigger pad
    -- function should be enabled to minimize the risk of glitches.
    -- Furthermore, the pulldown should always be active to reset the whole
    -- system when the FPGA is being programmed.
    p_reset_n_di                : in  std_logic;
    
    -- Clock input control. In case there are multiple clock input modes (for
    -- instance, differential or single-ended, schmitt-trigger enable/disable,
    -- whatever), these signals allow the mode to be selected. They can be
    -- configured while the ASIC is being reset.
    p_clk_sel                   : out std_logic;
    p_clk_mode0                 : out std_logic;
    p_clk_mode1                 : out std_logic;
    
    -- Data bus pin interface. The schmitt-trigger function should be disabled.
    -- Obviously, the other functions are controlled by the signals below (they
    -- can be set by the FPGA while reset_n is asserted low).
    p_data_di                   : in  std_logic_vector(31 downto 0);
    p_data_do                   : out std_logic_vector(31 downto 0);
    p_data_oe                   : out std_logic;
    p_data_pin2                 : out std_logic;
    p_data_pin1                 : out std_logic;
    p_data_sr                   : out std_logic;
    p_data_pu                   : out std_logic;
    p_data_pd                   : out std_logic;
    
    -- Active low output enable input from the oen_n pad. Schmitt-trigger
    -- should be disabled. The pullup should be enabled when _pu is high.
    p_oen_n_di                  : in  std_logic;
    p_oen_n_pu                  : out std_logic;
    
    -- Active high acknowledge input from the ack_n pad. Schmitt-trigger
    -- should be disabled. The pulldown should be enabled when _pd is high.
    p_ack_di                    : in  std_logic;
    p_ack_pd                    : out std_logic;
    
    -- Serial debug data command input from the dbgc pad. Schmitt-trigger
    -- should be disabled. The pulldown should be enabled when _pd is high.
    p_dbgc_di                   : in  std_logic;
    p_dbgc_pd                   : out std_logic;
    
    -- Serial debug response output to the dbgr pad. Drive strength and slew
    -- rate are to be controlled by the _pin2, _pin1, and _sr signals.
    p_dbgr_do                   : out std_logic;
    p_dbgr_pin2                 : out std_logic;
    p_dbgr_pin1                 : out std_logic;
    p_dbgr_sr                   : out std_logic;
    
    -- Special-function pins. The function of these pins is configured during
    -- a reset. They are intended to be used as interrupt request pins, but
    -- they can be multiplexed to other functions as well. Examples would be
    -- cache behavior signals, bus behavior signals, stall signals, etc.
    p_spf_di                    : in  std_logic_vector(7 downto 0);
    p_spf_do                    : out std_logic_vector(7 downto 0);
    p_spf_oe                    : out std_logic_vector(7 downto 0);
    p_spf_pin2                  : out std_logic;
    p_spf_pin1                  : out std_logic;
    p_spf_sr                    : out std_logic;
    p_spf_pu                    : out std_logic;
    p_spf_pd                    : out std_logic;
    p_spf_smt                   : out std_logic;
    
    -- Alternate pin functions on the rising edge of reset_n:
    --  - data0:  p_clk_sel
    --  - data1:  p_clk_mode1
    --  - data2:  p_clk_mode2
    --  - data3:  <reserved>
    --  - data4:  memory bus mode 0
    --  - data5:  memory bus mode 1
    --  - data6:  p_data_sr
    --  - data7:  p_data_pin1
    --  - data8:  p_data_pin2
    --  - data9:  p_data_pu
    --  - data10: p_data_pd
    --  - data11: debug bus mode 0
    --  - data12: debug bus mode 1
    --  - data13: p_dbgr_sr
    --  - data14: p_dbgr_pin1
    --  - data15: p_dbgr_pin2
    --  - data16: spf pin function 0
    --  - data17: spf pin function 1
    --  - data18: spf pin function 2
    --  - data19: spf pin function 3
    --  - data20: spf pin function 4
    --  - data21: spf pin function 5
    --  - data22: spf pin function 6
    --  - data23: spf pin function 7
    --  - data24: p_spf_sr
    --  - data25: p_spf_pin1
    --  - data26: p_spf_pin2
    --  - data27: p_spf_pu
    --  - data28: p_spf_pd
    --  - data29: p_spf_smt
    --  - data30: <reserved>
    --  - data31: <reserved>
    
    ---------------------------------------------------------------------------
    -- Internal signals
    ---------------------------------------------------------------------------
    -- Clock network. The clock input selection mux and buffers should be
    -- instantiated outside this unit.
    clk                         : in  std_logic;
    
    -- Filtered and synchronized reset signal for the core (active high).
    reset                       : out std_logic;
    
    -- Off-chip memory/peripheral interface bus.
    bus2mem                     : in  bus_mst2slv_type;
    mem2bus                     : out bus_slv2mst_type;
    
    -- Debug interface bus.
    dbg2bus                     : out bus_mst2slv_type;
    bus2dbg                     : in  bus_slv2mst_type;
    
    -- Trace interface.
    trace_push                  : in  std_logic;
    trace_data                  : in  std_logic_vector(7 downto 0);
    trace_busy                  : out std_logic;
    
    -- External interrupt signals, active high.
    ext_irq                     : out std_logic_vector(7 downto 0);
    
    -- Special-function data interface.
    spf_func                    : out std_logic_vector(7 downto 0);
    spf_di                      : out std_logic_vector(7 downto 0);
    spf_do                      : in  std_logic_vector(7 downto 0);
    spf_oe                      : in  std_logic_vector(7 downto 0)
    
  );
end hsi_asic;

--=============================================================================
architecture Behavioral of hsi_asic is
--=============================================================================
  
  -- The reset synchronization/filtering consists of a shift register that
  -- always shifts in a one on the rising edge of a clock cycle, and is
  -- asynchronously reset to zero by the incoming reset signal. This ensures
  -- that reset remains asserted for at least the number of clock edges defined
  -- below.
  constant RESET_FILTER_LENGTH  : natural := 16;
  signal reset_filter           : std_logic_vector(RESET_FILTER_LENGTH downto 0);
  
  -- Local copy of the active-high internal reset signal.
  signal reset_int              : std_logic;
  
  -- Reset configuration registers.
  signal cfg_mem                : std_logic_vector(1 downto 0);
  signal cfg_dbg                : std_logic_vector(1 downto 0);
  signal cfg_spf                : std_logic_vector(7 downto 0);
  signal cfg_spf_irq            : std_logic;
  
  -- Delay calibration pattern signals.
  signal cal_func               : std_logic_vector(7 downto 0);
  signal cal_data_in            : std_logic_vector(31 downto 0);
  signal cal_data_out           : std_logic_vector(31 downto 0);
  signal cal_ack_in             : std_logic;
  signal cal_dbgc_in            : std_logic;
  signal cal_dbgr_out           : std_logic;
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- Reset filtering
  -----------------------------------------------------------------------------
  -- Instantiate the reset filter shift register.
  reset_filter_proc: process (clk, p_reset_n_di) is
  begin
    if p_reset_n_di = '0' then
      reset_filter <= (others => '0');
    elsif rising_edge(clk) then
      reset_filter <= "1" & reset_filter(RESET_FILTER_LENGTH downto 1);
    end if;
  end process;
  
  -- Drive the reset signals.
  reset <= not reset_filter(0);
  reset_int <= not reset_filter(0);
  
  -- Connect pullup/down enable signals.
  p_oen_n_pu <= p_reset_n_di;
  p_ack_pd   <= p_reset_n_di;
  p_dbgc_pd  <= p_reset_n_di;
  
  -----------------------------------------------------------------------------
  -- Reset configuration registers
  -----------------------------------------------------------------------------
  -- Instantiate the configuration registers. We can't assume that we have a
  -- usable clock during reset, as the configuration affects the clock input
  -- mode, so instead, we use the reset pad itself as a clock signal.
  cfg_reg_proc: process (p_reset_n_di) is
  begin
    if rising_edge(p_reset_n_di) then
      
      -- Clock configuration registers.
      p_clk_sel   <= p_data_di(0);
      p_clk_mode0 <= p_data_di(1);
      p_clk_mode1 <= p_data_di(2);
      
      -- Memory bus configuration registers.
      cfg_mem     <= p_data_di(5 downto 4);
      p_data_sr   <= p_data_di(6);
      p_data_pin1 <= p_data_di(7);
      p_data_pin2 <= p_data_di(8);
      p_data_pu   <= p_data_di(9);
      p_data_pd   <= p_data_di(10);
      
      -- Debug serial port configuration registers.
      cfg_dbg     <= p_data_di(12 downto 11);
      p_dbgr_sr   <= p_data_di(13);
      p_dbgr_pin1 <= p_data_di(14);
      p_dbgr_pin2 <= p_data_di(15);
      
      -- Special-function pin configuration registers.
      cfg_spf     <= p_data_di(23 downto 16);
      p_spf_sr    <= p_data_di(24);
      p_spf_pin1  <= p_data_di(25);
      p_spf_pin2  <= p_data_di(26);
      p_spf_pu    <= p_data_di(27);
      p_spf_pd    <= p_data_di(28);
      p_spf_smt   <= p_data_di(29);
      
    end if;
  end process;
  
  -----------------------------------------------------------------------------
  -- Parallel data bus (ASIC master)
  -----------------------------------------------------------------------------
  asic_mem_inst: entity work.hsi_asic_mem
    port map (
      clk                       => clk,
      reset                     => reset_int,
      cfg_mem                   => cfg_mem,
      data_in                   => p_data_di,
      data_out                  => p_data_do,
      data_oen                  => p_data_oe,
      oen_n                     => p_oen_n_di,
      ack                       => p_ack_di,
      cal_data_in               => cal_data_in,
      cal_data_out              => cal_data_out,
      cal_ack_in                => cal_ack_in,
      bus2mem                   => bus2mem,
      mem2bus                   => mem2bus,
      trace_push                => trace_push,
      trace_data                => trace_data,
      trace_busy                => trace_busy
    );
  
  -----------------------------------------------------------------------------
  -- Serial data bus (FPGA master)
  -----------------------------------------------------------------------------
  asic_dbg_inst: entity work.hsi_asic_dbg
    port map (
      clk                       => clk,
      reset                     => reset_int,
      cfg_dbg                   => cfg_dbg,
      dbgc                      => p_dbgc_di,
      dbgr                      => p_dbgr_do,
      cal_dbgc_in               => cal_dbgc_in,
      cal_dbgr_out              => cal_dbgr_out,
      dbg2bus                   => dbg2bus,
      bus2dbg                   => bus2dbg
    );
  
  -----------------------------------------------------------------------------
  -- Special-function pins
  -----------------------------------------------------------------------------
  spf_block: block is
    signal spf_di_r             : std_logic_vector(7 downto 0);
    signal spf_oe_r             : std_logic_vector(7 downto 0);
  begin
    
    -- Infer the input and output registers for the spf pins.
    process (clk) is
    begin
      if rising_edge(clk) then
        spf_di_r <= p_spf_di;
        p_spf_do <= spf_do;
        spf_oe_r <= spf_oe;
      end if;
    end process;
    
    -- Select interrupt input mode when SPF mode is zero.
    cfg_spf_irq <= '1' when cfg_spf = "00000000" else '0';
    
    -- Force external interrupt signals to zero (not asserted) when the special
    -- function pins are not in interrupt mode.
    ext_irq <= spf_di_r when cfg_spf_irq = '1' else "00000000";
    
    -- Connect the special function ports.
    spf_func <= cfg_spf;
    spf_di <= spf_di_r;
    p_spf_oe <= "00000000" when cfg_spf_irq = '1' or reset_int = '1' else spf_oe_r;
    
    -- Connect the delay calibration function selection to the spf pins.
    cal_func <= spf_di_r;
    
  end block;
  
  -----------------------------------------------------------------------------
  -- Delay calibration pattern interconnect
  -----------------------------------------------------------------------------
  -- The interconnect below is active while reset is asserted. It just
  -- interconnects various inputs to various outputs through their in/out
  -- registers. Using this feature, the FPGA design should in theory be able
  -- to determine the best-case and worst-case timing of all high-performance
  -- ASIC signals in both directions. The FPGA design can then potentially
  -- compensate for differences in delay between the signals. It can also be
  -- used to manually inspect signal integrity/pad performance using a signal
  -- generator and oscilloscope.
  --
  -- Various interconnects are possible for various tests. These are selected
  -- using the spf pins, which are configured as inputs while reset is
  -- asserted. spf5:0 selects the pad under test (Table 1), while spf6:7
  -- determines what the other pads are doing in the meantime (Table 2). oen_n
  -- determines the direction of the data pins, as it always does.
  --
  -- Table 1: internal connections based on spf5:0.
  --  .----------------------------------------.
  --  | spf5:0 | Connections                   |
  --  |--------+-------------------------------|
  --  | 0XXXXX | dataX -> dbgr, dbgc -> dataX  |
  --  | 10---- | ack -> dbgr                   |
  --  | 11---- | dbgc -> dbgr                  |
  --  '----------------------------------------'
  --
  -- Table 2: the function of any output not driven by a connection as
  -- specified in Table 1.
  --  .-------------------------.
  --  | spf7:6 | Logic function |
  --  |--------+----------------|
  --  | 00     | high           |
  --  | 01     | low            |
  --  | 10     | not dbgc       |
  --  | 11     | dbgc           |
  --  '-------------------------'
  --
  -- Note that a clock signal is needed to do these tests. Also, the cfg_mem
  -- configuration parameter is used to select the data input register under
  -- test. The clock configuration and other parameters are loaded on the
  -- rising edge of reset_n, so the following steps need to be followed to use
  -- this feature:
  --
  --  1. Disable any running clocks.
  --  2. Drive oen_n high and reset_n low.
  --  3. Drive the data pins with the desired configuration.
  --  4. Wait sufficiently long for the signals to settle, then send a positive
  --     pulse to reset_n to have the ASIC commit the new configuration. Drive
  --     reset_n low again before continuing.
  --  5. Release the data pins to high-impedance mode.
  --  6. Start the clock signal that matches the new configuration.
  --  7. Perform the desired tests.
  --  8. Drive oen_n high.
  --  9. Drive the data pins with the desired configuration.
  -- 10. Wait sufficiently long for the signals to settle, then assert reset_n
  --     high.
  -- 11. Within 16 clock cycles, release the data and spf pins to
  --     high-impedance and drive oen_n and dbgc low. After these 16 clock
  --     cycles, the internal reset will be released.
  --
  cal_block: block is
    
    -- The logic level for the pins NOT currently selected according to
    -- Table 1 (this performs the function shown in Table 2).
    signal alt_func             : std_logic;
    
  begin
    
    -- Infer the logic function shown in Table 2.
    alt_func <= (cal_func(7) nand cal_dbgc_in) xor cal_func(6);
    
    -- Drive the data pins (if oen_n is low).
    cal_data_out_gen: for i in 0 to 31 generate
    begin
      cal_data_out(i) <= cal_dbgc_in
        when cal_func(5 downto 0) = std_logic_vector(to_unsigned(i, 6))
        else alt_func;
    end generate;
    
    -- Select the data for dbgr.
    dbgr_out_proc: process (
      cal_func, cal_data_in, cal_ack_in, cal_dbgc_in
    ) is
    begin
      if cal_func(5) = '0' then
        case cal_func(4 downto 0) is
          when "00000" => cal_dbgr_out <= cal_data_in(0);
          when "00001" => cal_dbgr_out <= cal_data_in(1);
          when "00010" => cal_dbgr_out <= cal_data_in(2);
          when "00011" => cal_dbgr_out <= cal_data_in(3);
          when "00100" => cal_dbgr_out <= cal_data_in(4);
          when "00101" => cal_dbgr_out <= cal_data_in(5);
          when "00110" => cal_dbgr_out <= cal_data_in(6);
          when "00111" => cal_dbgr_out <= cal_data_in(7);
          
          when "01000" => cal_dbgr_out <= cal_data_in(8);
          when "01001" => cal_dbgr_out <= cal_data_in(9);
          when "01010" => cal_dbgr_out <= cal_data_in(10);
          when "01011" => cal_dbgr_out <= cal_data_in(11);
          when "01100" => cal_dbgr_out <= cal_data_in(12);
          when "01101" => cal_dbgr_out <= cal_data_in(13);
          when "01110" => cal_dbgr_out <= cal_data_in(14);
          when "01111" => cal_dbgr_out <= cal_data_in(15);
          
          when "10000" => cal_dbgr_out <= cal_data_in(16);
          when "10001" => cal_dbgr_out <= cal_data_in(17);
          when "10010" => cal_dbgr_out <= cal_data_in(18);
          when "10011" => cal_dbgr_out <= cal_data_in(19);
          when "10100" => cal_dbgr_out <= cal_data_in(20);
          when "10101" => cal_dbgr_out <= cal_data_in(21);
          when "10110" => cal_dbgr_out <= cal_data_in(22);
          when "10111" => cal_dbgr_out <= cal_data_in(23);
          
          when "11000" => cal_dbgr_out <= cal_data_in(24);
          when "11001" => cal_dbgr_out <= cal_data_in(25);
          when "11010" => cal_dbgr_out <= cal_data_in(26);
          when "11011" => cal_dbgr_out <= cal_data_in(27);
          when "11100" => cal_dbgr_out <= cal_data_in(28);
          when "11101" => cal_dbgr_out <= cal_data_in(29);
          when "11110" => cal_dbgr_out <= cal_data_in(30);
          when others  => cal_dbgr_out <= cal_data_in(31);
        end case;
      else
        if cal_func(4) = '0' then
          cal_dbgr_out <= cal_ack_in;
        else
          cal_dbgr_out <= cal_dbgc_in;
        end if;
      end if;
    end process;
    
  end block;
  
end Behavioral;

