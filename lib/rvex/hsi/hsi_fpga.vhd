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
-- This is the FPGA side of the HSI (high-speed interface) off-chip
-- interconnect. The timing for the data, oen_n, and ack pads is shown at the
-- top of hsi_asic_mem.vhd. The timing for dbgc and dbgr is shown at the top of
-- hsi_asic_dbg.vhd.
-------------------------------------------------------------------------------
entity hsi_fpga is
--=============================================================================
  generic (
    
    -- Reference clock period in ns.
    CLK_REF_PERIOD              : real := 5.0 -- 200 MHz
    
  );
  port (
    
    ---------------------------------------------------------------------------
    -- Pad interface
    ---------------------------------------------------------------------------
    -- Active low reset output to the reset_n pad of the ASIC.
    p_reset_n_do                : out std_logic;
    
    -- Clock output to the clock pads of the ASIC.
    p_clk_do                    : out std_logic;
    
    -- Data bus pin interface.
    p_data_di                   : in  std_logic_vector(31 downto 0);
    p_data_do                   : out std_logic_vector(31 downto 0);
    p_data_tri                  : out std_logic;
    
    -- Active low output enable output to the oen_n pad of the ASIC.
    p_oen_n_do                  : out std_logic;
    
    -- Active high acknowledge output to the ack_n pad of the ASIC.
    p_ack_do                    : out std_logic;
    
    -- Serial debug data command output to the dbgc pad of the ASIC.
    p_dbgc_do                   : out std_logic;
    
    -- Serial debug response input from the dbgr pad of the ASIC.
    p_dbgr_di                   : in  std_logic;
    
    -- Special-function pins connected to the spf pads of the ASIC.
    p_spf_di                    : in  std_logic_vector(7 downto 0);
    p_spf_do                    : out std_logic_vector(7 downto 0);
    p_spf_tri                   : out std_logic_vector(7 downto 0);
    
    ---------------------------------------------------------------------------
    -- Internal signals
    ---------------------------------------------------------------------------
    -- MMCM reference clock. The period for this clock must be specified in the
    -- generics.
    clk_ref                     : in  std_logic;
    
    -- Internal bus clock.
    clk                         : in  std_logic;
    
    -- Active-high FPGA reset.
    reset                       : in  std_logic;
    
    -- Master bus interface.
    asic2fpga_mem               : out bus_mst2slv_type;
    fpga2asic_mem               : in  bus_slv2mst_type;
    
    -- Slave bus interface (8 MB address space needed).
    fpga2asic_ctrl              : in  bus_mst2slv_type;
    asic2fpga_ctrl              : out bus_slv2mst_type;
    
    -- Peripheral interrupt signals, to be forwarded to the ASIC (unless the
    -- spf pins are used for other purposes).
    ext_irq                     : in  std_logic_vector(7 downto 0)
    
  );
end hsi_fpga;

--=============================================================================
architecture Behavioral of hsi_fpga is
--=============================================================================
  
  -- Interface clock and active-high reset.
  signal if_clk                 : std_logic;
  signal if_reset               : std_logic;
  
  -- MMCM access bus.
  signal switch2mmcm            : bus_mst2slv_type;
  signal mmcm2switch            : bus_slv2mst_type;
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- Clock generator
  -----------------------------------------------------------------------------
  clkgen: entity work.hsi_fpga_clkgen
    generic map (
      CLK_REF_PERIOD            => CLK_REF_PERIOD
    )
    port map (
      p_clk_do                  => p_clk_do,
      if_reset                  => if_reset,
      if_clk                    => if_clk,
      clk_ref                   => clk_ref,
      reset                     => reset,
      clk                       => clk,
      bus2mmcm                  => switch2mmcm,
      mmcm2bus                  => mmcm2switch
    );
  
  -----------------------------------------------------------------------------
  -- Bus switch
  -----------------------------------------------------------------------------
  bus_switch entity work.hsi_fpga_switch
    port map (
      reset                     => reset,
      clk                       => clk,
      if_reset                  => if_reset,
      if_clk                    => if_clk,
      switch2busm               => asic2fpga_mem,
      busm2switch               => fpga2asic_mem,
      buss2switch               => fpga2asic_ctrl,
      switch2buss               => asic2fpga_ctrl,
      switch2mmcm               => switch2mmcm,
      mmcm2switch               => mmcm2switch,
      para2switch               => 
      switch2para               => 
      switch2seri               => 
      seri2switch               => 
    );
  
end Behavioral;

