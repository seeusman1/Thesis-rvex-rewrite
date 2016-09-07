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
-- This entity contains all the r-VEX bus units needed in the FPGA side of the
-- HSI: cross-clock interconnects, multiplexing, and control registers.
--
-- TODO: the memory bus currently uses a normal clock domain crossing. That is,
-- there is no proper burst support. The clock domain crossing is currently
-- likely slower than the HSI.
-------------------------------------------------------------------------------
entity hsi_fpga_switch is
--=============================================================================
  port (
    
    -- FPGA-side clock domain clock and reset.
    reset                       : in  std_logic;
    clk                         : in  std_logic;
    
    -- ASIC-side/interface clock domain clock and reset.
    if_reset                    : in  std_logic;
    if_clk                      : in  std_logic;
    
    -- Bus master interface.
    switch2busm                 : out bus_mst2slv_type;
    busm2switch                 : in  bus_slv2mst_type;
    
    -- Bus slave interface.
    buss2switch                 : in  bus_mst2slv_type;
    switch2buss                 : out bus_slv2mst_type;
    
    -- MMCM interface.
    switch2mmcm                 : out bus_mst2slv_type;
    mmcm2switch                 : in  bus_slv2mst_type;
    
    -- Parallel interface bus.
    para2switch                 : in  bus_mst2slv_type;
    switch2para                 : out bus_slv2mst_type;
    
    -- Serial interface bus.
    switch2seri                 : out bus_mst2slv_type;
    seri2switch                 : in  bus_slv2mst_type
    
  );
end hsi_fpga_switch;

--=============================================================================
architecture Behavioral of hsi_fpga_switch is
--=============================================================================
  
  -- FPGA clock domain debug address map.
  constant ADDRESS_MAP_FPGA     : addrRangeAndMapping_array(0 to 1) := (
    0 => addrRangeAndMap(match => "--------------------------------"), -- ASIC clock domain.
    1 => addrRangeAndMap(match => "---------11---------------------")  -- MMCM.
  );
  
  -- ASIC clock domain debug address map.
  constant ADDRESS_MAP_ASIC     : addrRangeAndMapping_array(0 to 1) := (
    0 => addrRangeAndMap(match => "--------------------------------"), -- ASIC.
    1 => addrRangeAndMap(match => "---------1----------------------")  -- Control registers.
  );
  
  -- FPGA domain demuxer to cross clock.
  signal dema2xclk              : bus_mst2slv_type;
  signal xclk2dema              : bus_slv2mst_type;
  
  -- Cross clock to ASIC domain demuxer.
  signal xclk2demb              : bus_mst2slv_type;
  signal demb2xclk              : bus_slv2mst_type;
  
  -- Control register access bus.
  signal switch2regs            : bus_mst2slv_type;
  signal regs2switch            : bus_slv2mst_type;
  
  -- TODO: control registers
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -- Instantiate the bus demuxer that selects between the MMCM control
  -- registers and the ASIC clock domain.
  fpga_domain_demux: entity work.bus_demux
    generic map (
      ADDRESS_MAP               => ADDRESS_MAP
    )
    port map (
      reset                     => reset,
      clk                       => clk,
      clkEn                     => '1',
      mst2demux                 => buss2switch,
      demux2mst                 => switch2buss,
      demux2slv(0)              => dema2xclk,
      demux2slv(1)              => switch2mmcm,
      slv2demux(0)              => xclk2dema,
      slv2demux(1)              => mmcm2switch
    );
  
  -- Instantiate the debug clock domain crossing.
  debug_cross_clock: entity work.bus_crossClock
    port map (
      
      -- Master bus.
      mst_reset                 => reset,
      mst_clk                   => clk,
      mst_clkEn                 => '1',
      mst2crclk                 => dema2xclk,
      crclk2mst                 => xclk2dema,
      
      -- Slave bus.
      slv_reset                 => if_reset,
      slv_clk                   => if_clk,
      slv_clkEn                 => '1',
      crclk2slv                 => xlkc2demb,
      slv2crclk                 => demb2xclk
      
    );
  
  -- Instantiate the bus demuxer that selects between the ASIC serial debug
  -- interface registers and the ASIC control.
  asic_domain_demux: entity work.bus_demux
    generic map (
      ADDRESS_MAP               => ADDRESS_MAP
    )
    port map (
      reset                     => reset,
      clk                       => clk,
      clkEn                     => '1',
      mst2demux                 => xlkc2demb,
      demux2mst                 => demb2xclk,
      demux2slv(0)              => switch2seri,
      demux2slv(1)              => switch2regs,
      slv2demux(0)              => seri2switch,
      slv2demux(1)              => regs2switch
    );
  
  -- Instantiate the debug clock domain crossing.
  memory_cross_clock: entity work.bus_crossClock
    port map (
      
      -- Master bus.
      mst_reset                 => if_reset,
      mst_clk                   => if_clk,
      mst_clkEn                 => '1',
      mst2crclk                 => para2switch,
      crclk2mst                 => switch2para,
      
      -- Slave bus.
      slv_reset                 => reset,
      slv_clk                   => clk,
      slv_clkEn                 => '1',
      crclk2slv                 => switch2busm,
      slv2crclk                 => busm2switch
      
    );
  
end Behavioral;

