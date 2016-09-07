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
-- This is unit generate the ASIC clock (reconfigurably) and handles the
-- cross-clock synchronization for the busses. The MMCM is accessible from the
-- slave bus given a 512 byte address space.
-------------------------------------------------------------------------------
entity hsi_fpga_clkgen is
--=============================================================================
  generic (
    
    -- Reference clock period in ns.
    CLK_REF_PERIOD              : real := 5.0 -- 200 MHz
    
  );
  port (
    
    -- ASIC clock output.
    p_clk_do                    : out std_logic;
    
    -- Interface clock and reset (same frequency as the ASIC clock).
    if_reset                    : out std_logic;
    if_clk                      : out std_logic;
    
    -- MMCM reference clock. The period for this clock must be specified in the
    -- generics.
    clk_ref                     : in  std_logic;
    
    -- Internal bus clock and reset.
    reset                       : in  std_logic;
    clk                         : in  std_logic;
    
    -- MMCM control bus.
    bus2mmcm                    : in  bus_mst2slv_type;
    mmcm2bus                    : out bus_slv2mst_type
    
  );
end hsi_fpga_clkgen;

--=============================================================================
architecture Behavioral of hsi_fpga_clkgen is
--=============================================================================
  
  -- Local routing for the feedback clock.
  signal clk_fb                 : std_logic;
  
  -- Local routing from the MMCM to the BUFGs.
  signal asic_clk_l             : std_logic;
  signal if_clk_l               : std_logic;
  
  -- BUFG outputs.
  signal asic_clk_i             : std_logic;
  signal if_clk_i               : std_logic;
  
  -- Lock signal from the MMCM.
  signal locked                 : std_logic;
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -- Instantiate the MMCM.
  mmcm_inst: entity work.utils_clkgen
    generic map (
      CLKIN_PERIOD            => CLK_REF_PERIOD,
      VCO_DIVIDE              => 2, -- 1000 MHz VCO
      VCO_MULT                => integer(2 * CLK_REF_PERIOD),
      INITIAL_RESET           => '1',
      CLKOUT0_DIVIDE          => 5, -- 200 MHz ASIC clock (max)
      CLKOUT1_DIVIDE          => 5
    )
    port map (
      
      -- Active-high reset and clock for the bus interface.
      reset                   => reset,
      clk                     => clk,
      bus2clkgen              => bus2mmcm,
      clkgen2bus              => mmcm2bus,
      
      -- MMCM signals.
      clk_ref                 => clk_ref,
      clk_fbi                 => clk_fb,
      clk_fbo                 => clk_fb,
      locked                  => locked,
      clk_o0                  => asic_clk_l,
      clk_o1                  => if_clk_l
      
    );
  
  -- Buffer the local clocks.
  clk_buffer: BUFG
    port map (
      I => asic_clk_l,
      O => asic_clk_i
    );
  
  clk_buffer: BUFG
    port map (
      I => if_clk_l,
      O => if_clk_i
    );
  
  -- Reset generation.
  reset_gen: process (if_clk, reset, locked) is
  begin
    if reset = '1' or locked = '0' then
      reset_count <= (others => '0');
      if_reset_i <= '1';
    elsif rising_edge(if_clk) then
      if reset_count = "1111111" then
        if_reset_i <= '0';
      else
        reset_count <= reset_count + 1;
        if_reset_i <= '1';
      end if;
    end if;
  end process;
  
  -- Connect the output ports.
  p_clk_do  <= asic_clk_i;
  if_clk    <= if_clk_i;
  if_reset  <= if_reset_i;
  
end Behavioral;

