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

-- Refer to reconfCache_pkg.vhd for configuration constants and most
-- documentation.

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
library grlib;
use grlib.amba.all;
use grlib.stdlib.all;
use grlib.devices.all;
library gaisler;
use gaisler.misc.all;
library rvex;
use rvex.cache_pkg.all;

entity cache_ahbBridge is
  generic (
    
    -- AHB master interface index.
    hindex                    : integer range 0 to NAHBMST-1  := 0;
    
    -- ???
    hirq                      : integer := 0
    
  );
  port (
    
    -- Clock input.
    clk                       : in  std_logic;
    
    -- Active high reset input.
    resetCPU                  : in  std_logic;
    resetBus                  : in  std_logic;
    
    -- Connection to cache.
    bridgeToCache             : out reconfCache_memIn;
    cacheToBridge             : in  reconfCache_memOut;
    
    -- AHB bus interface.
    busToMaster               : in  ahb_mst_in_type;
    masterToBus               : out ahb_mst_out_type
    
  );
end cache_ahbBridge;

architecture Behavioral of cache_ahbBridge is
  
  -- Signal record from and to the grlib DMA interface.
  signal bridgeToMaster       : ahb_dma_in_type;
  signal masterToBridge       : ahb_dma_out_type;
  
  -- Inverted bus reset signal for AHB master.
  signal resetBus_n           : std_logic;
  
  -- Combined CPU/bus reset, delayed by one cycle.
  signal reset_r              : std_logic;
  
  -- When high, bus transfer requests are delayed. This is high during and
  -- just after a reset.
  signal delayTransfer        : std_logic;
  
  -- When high, the bus ready signal is held low. This is high one cycle after
  -- delayTransfer.
  signal delayTransfer_r      : std_logic;

begin
  
  --===========================================================================
  -- Make the vex behave nicely while in reset (because that doesn't mean the
  -- bus is also being reset)
  --===========================================================================
  process (clk) is
  begin
    if rising_edge(clk) then
      reset_r <= resetCPU or resetBus;
      delayTransfer_r <= delayTransfer;
    end if;
  end process;
  
  delayTransfer <= reset_r or resetCPU or resetBus;
  
  --===========================================================================
  -- Connect the cache signals to the AHB master interface (bridge)
  --===========================================================================
  bridgeToMaster.start <= (cacheToBridge.writeEnable or cacheToBridge.readEnable) and not delayTransfer;
  bridgeToMaster.write <= cacheToBridge.writeEnable and not delayTransfer;
  bridgeToMaster.burst <= cacheToBridge.burstEnable and not delayTransfer;
  bridgeToMaster.irq   <= '0';
  bridgeToMaster.busy  <= '0';
  
  bridgeToCache.data   <= ahbreadword(masterToBridge.rdata);
  bridgeToCache.ready  <= masterToBridge.ready and not delayTransfer_r;
  
  -- Apparently, writeData must be delayed by one cycle as it's not considered
  -- to be part of the request and the data is actually placed on the bus in
  -- the cycle where ready is high.
  process (clk) is
  begin
    if rising_edge(clk) then
      bridgeToMaster.wdata <= ahbdrivedata(cacheToBridge.writeData);
    end if;
  end process;
  
  -- Determine the address and size based on mask.
  process (cacheToBridge.addr, cacheToBridge.writeEnable, cacheToBridge.writeMask) is
  begin
    bridgeToMaster.address <= cacheToBridge.addr;
    bridgeToMaster.size    <= HSIZE_WORD;
    if cacheToBridge.writeEnable = '1' then
      case cacheToBridge.writeMask is
        when "1100" =>
          bridgeToMaster.address(1) <= '0';
          bridgeToMaster.address(0) <= '0';
          bridgeToMaster.size       <= HSIZE_HWORD;
        when "0011" =>
          bridgeToMaster.address(1) <= '1';
          bridgeToMaster.address(0) <= '0';
          bridgeToMaster.size       <= HSIZE_HWORD;
        when "1000" =>
          bridgeToMaster.address(1) <= '0';
          bridgeToMaster.address(0) <= '0';
          bridgeToMaster.size       <= HSIZE_BYTE;
        when "0100" =>
          bridgeToMaster.address(1) <= '0';
          bridgeToMaster.address(0) <= '1';
          bridgeToMaster.size       <= HSIZE_BYTE;
        when "0010" =>
          bridgeToMaster.address(1) <= '1';
          bridgeToMaster.address(0) <= '0';
          bridgeToMaster.size       <= HSIZE_BYTE;
        when "0001" =>
          bridgeToMaster.address(1) <= '1';
          bridgeToMaster.address(0) <= '1';
          bridgeToMaster.size       <= HSIZE_BYTE;
        when others =>
          null;
      end case;
    end if;
  end process;
  
  --===========================================================================
  -- Instantiate the AHB bus master
  --===========================================================================
  resetBus_n <= not resetBus;
  
  ahb_master: ahbmst
    generic map (
      hindex  => hindex,
      hirq    => hirq,
      venid   => VENDOR_OPENCORES,
      devid   => 11,
      version => 0,
      chprot  => 3,
      incaddr => 0
    )
    port map (
      clk     => clk,
      rst     => resetBus_n,
      dmai    => bridgeToMaster,
      dmao    => masterToBridge,
      ahbi    => busToMaster,
      ahbo    => masterToBus
    );
  
end Behavioral;

