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
use rvex.common_pkg.all;
use rvex.bus_pkg.all;

Library unisim;
use unisim.vcomponents.all;

--=============================================================================
-- Reconfigurable clock generation unit for Virtex 6 FPGAs.
-------------------------------------------------------------------------------
entity utils_clkgen is
--=============================================================================
  generic (
    
    -- MMCM bandwidth mode ("HIGH", "LOW", or "OPTIMIZED").
    BANDWIDTH                   : string := "OPTIMIZED";
    
    -- Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
    CLKIN_PERIOD                : real := 5.0; -- 200 MHz
    
    -- Reference input jitter in UI (0.000-0.999).
    REF_JITTER                  : real := 0.0;
    
    -- Initial MMCM state.
    INITIAL_POWERDOWN           : std_logic := '0';
    INITIAL_RESET               : std_logic := '1';
    
    -- VCO divider (1-80) and multiplier (5-64). The VCO frequency must be
    -- within 600 and 1200 MHz.
    VCO_DIVIDE                  : natural := 10; -- 20 MHz
    VCO_MULT                    : natural := 45; -- 30=600MHz, 60=1200 MHz
    
    -- Initial divide amounts for CLKOUT outputs (1-128).
    CLKOUT0_DIVIDE              : natural := 90;
    CLKOUT1_DIVIDE              : natural := 90;
    CLKOUT2_DIVIDE              : natural := 90;
    CLKOUT3_DIVIDE              : natural := 90;
    CLKOUT4_DIVIDE              : natural := 90;
    CLKOUT5_DIVIDE              : natural := 90;
    CLKOUT6_DIVIDE              : natural := 90;
    
    -- Initial phase offsets for CLKOUT outputs (-360.000-360.000).
    CLKOUT0_PHASE               : real := 0.0;
    CLKOUT1_PHASE               : real := 0.0;
    CLKOUT2_PHASE               : real := 0.0;
    CLKOUT3_PHASE               : real := 0.0;
    CLKOUT4_PHASE               : real := 0.0;
    CLKOUT5_PHASE               : real := 0.0;
    CLKOUT6_PHASE               : real := 0.0;
    
    -- Initial duty cycles for CLKOUT outputs (0.01-0.99).
    CLKOUT0_DUTY_CYCLE          : real := 0.5;
    CLKOUT1_DUTY_CYCLE          : real := 0.5;
    CLKOUT2_DUTY_CYCLE          : real := 0.5;
    CLKOUT3_DUTY_CYCLE          : real := 0.5;
    CLKOUT4_DUTY_CYCLE          : real := 0.5;
    CLKOUT5_DUTY_CYCLE          : real := 0.5;
    CLKOUT6_DUTY_CYCLE          : real := 0.5
    
  );
  port (
    
    -- Active-high reset and clock for the bus interface.
    reset                       : in  std_logic;
    clk                         : in  std_logic;
    clkEn                       : in  std_logic := '1';
    
    -- r-VEX bus interface for the MMCM. Only word accesses are supported;
    -- masked writes have no effect. Requires 512 bytes of address space. The
    -- MMCM registers (see XAPP878 pp. 6) are mapped to word addresses, using
    -- the low halfwords. The MMCM registers are only accessible when the MMCM
    -- is being reset. In addition to the MMCM registers, the following
    -- registers are available:
    --  - 0x000: stat/ctrl
    --     * Bit 31..8: reference clock period in ps
    --     * Bit 5: set if bandwidth is low
    --     * Bit 4: feedback clock stopped
    --     * Bit 3: reference clock stopped
    --     * Bit 2: locked
    --     * Bit 1: power down MMCM (writable)
    --     * Bit 0: reset MMCM (writable)
    --  - 0x004: user register, writable only when MMCM is in reset
    --  - 0x008: user register, writable only when MMCM is in reset
    --  - 0x00C: user register, writable only when MMCM is in reset
    -- The user registers are intended to hold the current clock configuration.
    -- They must be set up by the system that configures the MMCM itself.
    bus2clkgen                  : in  bus_mst2slv_type;
    clkgen2bus                  : out bus_slv2mst_type;
    
    -- Reference clock for the PLL.
    clk_ref                     : in  std_logic;
    
    -- PLL feedback network.
    clk_fbi                     : in  std_logic;
    clk_fbo                     : out std_logic;
    clk_fbob                    : out std_logic;
    
    -- Lock output.
    locked                      : out std_logic;
    
    -- MMCM output clocks.
    clk_o0                      : out std_logic;
    clk_o0b                     : out std_logic;
    clk_o1                      : out std_logic;
    clk_o1b                     : out std_logic;
    clk_o2                      : out std_logic;
    clk_o2b                     : out std_logic;
    clk_o3                      : out std_logic;
    clk_o3b                     : out std_logic;
    clk_o4                      : out std_logic;
    clk_o5                      : out std_logic;
    clk_o6                      : out std_logic
    
  );
end utils_clkgen;

--=============================================================================
architecture Behavioral of utils_clkgen is
--=============================================================================
  
  -- MMCM control inputs.
  signal ctrl_powerdown         : std_logic;
  signal ctrl_reset             : std_logic;
  signal ctrl_reset_asy         : std_logic;
      
  -- MMCM status outputs.
  signal status_fb_stopped      : std_logic;
  signal status_ref_stopped     : std_logic;
  signal status_locked          : std_logic;
  
  -- MMCM dynamic reconfiguration port.
  signal drp_enable             : std_logic;
  signal drp_writeEnable        : std_logic;
  signal drp_address            : std_logic_vector(6 downto 0);
  signal drp_writeData          : std_logic_vector(15 downto 0);
  signal drp_readData           : std_logic_vector(15 downto 0);
  signal drp_ack                : std_logic;
  
  -- User registers.
  signal user1                  : std_logic_vector(31 downto 0);
  signal user2                  : std_logic_vector(31 downto 0);
  signal user3                  : std_logic_vector(31 downto 0);
  
  -- Bus interface state machine.
  type state_type is (S_IDLE, S_MUX, S_WAIT_MMCM, S_PRE_ACK, S_ACK);
  signal state                  : state_type;
  
  -- Bus registers and handshake signals.
  signal bus_address            : std_logic_vector(8 downto 2);
  signal bus_writeData          : std_logic_vector(31 downto 0);
  signal bus_writeEnable        : std_logic;
  signal bus_readData           : std_logic_vector(31 downto 0);
  signal bus_ack                : std_logic;
  signal bus_requesting_r       : std_logic;
  
--=============================================================================
begin
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- MMCM instantiation
  -----------------------------------------------------------------------------
  mmcm_inst : mmcm_adv
    generic map (
      BANDWIDTH                 => BANDWIDTH,
      
      -- Reference clock specification.
      CLKIN1_PERIOD             => CLKIN_PERIOD,
      CLKIN2_PERIOD             => CLKIN_PERIOD,
      REF_JITTER1               => REF_JITTER,
      REF_JITTER2               => REF_JITTER,
      
      -- Initial VCO frequency and phase configuration.
      CLKFBOUT_MULT_F           => real(VCO_MULT),
      CLKFBOUT_PHASE            => 0.0,
      DIVCLK_DIVIDE             => VCO_DIVIDE,
      
      -- Initial output clock specifications.
      CLKOUT0_DIVIDE_F          => real(CLKOUT0_DIVIDE),
      CLKOUT1_DIVIDE            => CLKOUT1_DIVIDE,
      CLKOUT2_DIVIDE            => CLKOUT2_DIVIDE,
      CLKOUT3_DIVIDE            => CLKOUT3_DIVIDE,
      CLKOUT4_DIVIDE            => CLKOUT4_DIVIDE,
      CLKOUT5_DIVIDE            => CLKOUT5_DIVIDE,
      CLKOUT6_DIVIDE            => CLKOUT6_DIVIDE,
      CLKOUT0_PHASE             => CLKOUT0_PHASE,
      CLKOUT1_PHASE             => CLKOUT1_PHASE,
      CLKOUT2_PHASE             => CLKOUT2_PHASE,
      CLKOUT3_PHASE             => CLKOUT3_PHASE,
      CLKOUT4_PHASE             => CLKOUT4_PHASE,
      CLKOUT5_PHASE             => CLKOUT5_PHASE,
      CLKOUT6_PHASE             => CLKOUT6_PHASE,
      CLKOUT0_DUTY_CYCLE        => CLKOUT0_DUTY_CYCLE,
      CLKOUT1_DUTY_CYCLE        => CLKOUT1_DUTY_CYCLE,
      CLKOUT2_DUTY_CYCLE        => CLKOUT2_DUTY_CYCLE,
      CLKOUT3_DUTY_CYCLE        => CLKOUT3_DUTY_CYCLE,
      CLKOUT4_DUTY_CYCLE        => CLKOUT4_DUTY_CYCLE,
      CLKOUT5_DUTY_CYCLE        => CLKOUT5_DUTY_CYCLE,
      CLKOUT6_DUTY_CYCLE        => CLKOUT6_DUTY_CYCLE,
      
      
      -- The following things are not supported by the MMCM in dynamic
      -- reconfiguration mode.
      CLKOUT4_CASCADE           => false,
      CLOCK_HOLD                => false,
      COMPENSATION              => "ZHOLD",
      STARTUP_WAIT              => false,
      CLKFBOUT_USE_FINE_PS      => false,
      CLKOUT0_USE_FINE_PS       => false,
      CLKOUT1_USE_FINE_PS       => false,
      CLKOUT2_USE_FINE_PS       => false,
      CLKOUT3_USE_FINE_PS       => false,
      CLKOUT4_USE_FINE_PS       => false,
      CLKOUT5_USE_FINE_PS       => false,
      CLKOUT6_USE_FINE_PS       => false
      
    )
    port map (
      
      -- Reference clock inputs.
      CLKIN1                    => clk_ref,
      CLKIN2                    => clk_ref,
      CLKINSEL                  => '0',
      
      -- Feedback.
      CLKFBOUT                  => clk_fbo,
      CLKFBOUTB                 => clk_fbob,
      CLKFBIN                   => clk_fbi,
      
      -- Clock outputs.
      CLKOUT0                   => clk_o0,
      CLKOUT0B                  => clk_o0b,
      CLKOUT1                   => clk_o1,
      CLKOUT1B                  => clk_o1b,
      CLKOUT2                   => clk_o2,
      CLKOUT2B                  => clk_o2b,
      CLKOUT3                   => clk_o3,
      CLKOUT3B                  => clk_o3b,
      CLKOUT4                   => clk_o4,
      CLKOUT5                   => clk_o5,
      CLKOUT6                   => clk_o6,
      
      -- Control inputs.
      PWRDWN                    => ctrl_powerdown,
      RST                       => ctrl_reset_asy,
      
      -- Status outputs.
      CLKFBSTOPPED              => status_fb_stopped,
      CLKINSTOPPED              => status_ref_stopped,
      LOCKED                    => status_locked,
      
      -- Reconfiguration port.
      DCLK                      => clk,
      DEN                       => drp_enable,
      DWE                       => drp_writeEnable,
      DADDR                     => drp_address,
      DI                        => drp_writeData,
      DO                        => drp_readData,
      DRDY                      => drp_ack,
      
      -- Dynamic phase shift ports.
      PSCLK                     => clk,
      PSEN                      => '0',
      PSINCDEC                  => '0',
      PSDONE                    => open
      
    );
  
  -- Reset the MMCM immediately when the incoming reset signal is asserted.
  ctrl_reset_asy <= ctrl_reset or reset;
  
  -- Connect the locked output.
  locked <= status_locked;
  
  -----------------------------------------------------------------------------
  -- r-VEX bus
  -----------------------------------------------------------------------------
  -- Instantiate the bus state machine
  bus_fsm_proc: process (clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        state           <= S_IDLE;
        bus_address     <= (others => '0');
        bus_writeData   <= (others => '0');
        bus_writeEnable <= '0';
        bus_ack         <= '0';
        drp_enable      <= '0';
        drp_writeEnable <= '0';
        drp_address     <= (others => '0');
        drp_writeData   <= (others => '0');
        ctrl_powerdown  <= INITIAL_POWERDOWN;
        ctrl_reset      <= INITIAL_RESET;
        user1           <= (others => '0');
        user2           <= (others => '0');
        user3           <= (others => '0');
      else
        bus_ack         <= '0';
        drp_enable      <= '0';
        drp_writeEnable <= '0';
        drp_address     <= (others => '0');
        drp_writeData   <= (others => '0');
        
        case state is
          
          when S_IDLE => -- Wait for bus request.
            if clkEn = '1' and bus_requesting(bus2clkgen) = '1' then
              bus_address     <= bus2clkgen.address(bus_address'range);
              bus_writeData   <= bus2clkgen.writeData;
              bus_writeEnable <= bus2clkgen.writeEnable
                             and bus2clkgen.writeMask(0)
                             and bus2clkgen.writeMask(1)
                             and bus2clkgen.writeMask(2)
                             and bus2clkgen.writeMask(3);
              state <= S_MUX;
            end if;
          
          when S_MUX => -- Determine which register to access.
            if bus_address(8 downto 4) = "00000" then
              
              -- Handle control register access.
              case bus_address(3 downto 2) is
                
                when "00" =>
                  if bus_writeEnable = '1' then
                    ctrl_powerdown <= bus_writeData(1);
                    ctrl_reset <= bus_writeData(0);
                  end if;
                  bus_readData(31 downto 8) <= std_logic_vector(
                    to_unsigned(integer(CLKIN_PERIOD*1000.0), 24));
                  bus_readData(7 downto 6) <= "00";
                  if BANDWIDTH = "LOW" then
                    bus_readData(5) <= '1';
                  else
                    bus_readData(5) <= '0';
                  end if;
                  bus_readData(4) <= status_fb_stopped;
                  bus_readData(3) <= status_ref_stopped;
                  bus_readData(2) <= status_locked;
                  bus_readData(1) <= ctrl_powerdown;
                  bus_readData(0) <= ctrl_reset;
                
                when "01" =>
                  if bus_writeEnable = '1' and ctrl_reset = '1' then
                    user1 <= bus_writeData;
                  end if;
                  bus_readData <= user1;
                
                when "10" =>
                  if bus_writeEnable = '1' and ctrl_reset = '1' then
                    user2 <= bus_writeData;
                  end if;
                  bus_readData <= user2;
                
                when others =>
                  if bus_writeEnable = '1' and ctrl_reset = '1' then
                    user3 <= bus_writeData;
                  end if;
                  bus_readData <= user3;
                
              end case;
              
              -- Acknowledge control register access.
              if clkEn = '1' then
                bus_ack <= '1';
                state <= S_ACK;
              else
                state <= S_PRE_ACK;
              end if;
              
            else
              
              -- Handle MMCM access.
              if ctrl_reset = '0' then
                
                -- Always read zero and ignore writes when the MMCM is not
                -- under reset.
                bus_readData <= (others => '0');
                if clkEn = '1' then
                  bus_ack <= '1';
                  state <= S_ACK;
                else
                  state <= S_PRE_ACK;
                end if;
                
              else
                
                -- Request the MMCM access.
                drp_enable      <= '1';
                drp_writeEnable <= bus_writeEnable;
                drp_address     <= bus_address;
                drp_writeData   <= bus_writeData(15 downto 0);
                
                -- Wait for the DRDY signal from the MMCM.
                state <= S_WAIT_MMCM;
                
              end if;
              
            end if;
          
          when S_WAIT_MMCM => -- Wait for the MMCM to respond.
            if drp_ack = '1' then
              
              -- Received a response from the MMCM.
              bus_readData(31 downto 16) <= (others => '0');
              bus_readData(15 downto 0) <= drp_readData;
              
              -- Acknowledge the r-VEX bus transfer.
              if clkEn = '1' then
                bus_ack <= '1';
                state <= S_ACK;
              else
                state <= S_PRE_ACK;
              end if;
              
            end if;
            
          when S_PRE_ACK => -- Synchronize with clken before acknowledging.
            if clkEn = '1' then
              bus_ack <= '1';
              state <= S_ACK;
            end if;
            
          when others => -- Acknowlede bus transfer.
            if clkEn = '1' then
              state <= S_IDLE;
            else
              bus_ack <= '1';
            end if;
          
        end case;
      end if;
    end if;
  end process;
  
  -- Instantiate the bus-requesting register, used to generate the busy signal.
  bus_requesting_reg_proc: process (clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        bus_requesting_r <= '0';
      elsif clkEn = '1' then
        bus_requesting_r <= bus_requesting(bus2clkgen);
      end if;
    end if;
  end process;
  
  -- Drive the bus response signal.
  bus_response_proc: process (bus_readData, bus_ack, bus_requesting_r) is
    variable s : bus_slv2mst_type;
  begin
    s := BUS_SLV2MST_IDLE;
    s.readData := bus_readData;
    s.ack := bus_ack;
    s.busy := bus_requesting_r and not bus_ack;
    clkgen2bus <= s;
  end process;
  
end Behavioral;

