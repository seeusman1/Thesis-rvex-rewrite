-- r-VEX processor
-- Copyright (C) 2008-2015 by TU Delft.
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

-- Copyright (C) 2008-2015 by TU Delft.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library rvex;
use rvex.common_pkg.all;
use rvex.bus_pkg.all;

library grlib;
use grlib.amba.all;
use grlib.devices.all;
use grlib.stdlib.all;
use grlib.dma2ahb_package.all;

--=============================================================================
-- This entity provides a bridge from a master bus interface as used in the
-- rvex library and a AHB master. Note that it uses an undocumented entity from
-- grlib which might be subject to changes in future grlib versions.
-------------------------------------------------------------------------------
entity bus2ahb is
--=============================================================================
  generic (
    
    -- Generic information as passed to grlib.dma2ahb.
    AHB_MASTER_INDEX            : integer := 0;
    AHB_VENDOR_ID               : integer := VENDOR_TUDELFT;
    AHB_DEVICE_ID               : integer := 0;
    AHB_VERSION                 : integer := 0;
    
    -- rvex bus fault code used to indicate that an AHB bus error occured.
    BUS_ERROR_CODE              : rvex_address_type := (others => '0')
    
  );
  port (
    
    ---------------------------------------------------------------------------
    -- System control
    ---------------------------------------------------------------------------
    -- Active high synchronous reset input.
    reset                       : in  std_logic;
    
    -- Clock input, registers are rising edge triggered.
    clk                         : in  std_logic;
    
    ---------------------------------------------------------------------------
    -- rvex library slave bus interface
    ---------------------------------------------------------------------------
    bus2bridge                  : in  bus_mst2slv_type;
    bridge2bus                  : out bus_slv2mst_type;
    
    ---------------------------------------------------------------------------
    -- AHB master interface
    ---------------------------------------------------------------------------
    bridge2ahb                  : out ahb_mst_out_type;
    ahb2bridge                  : in  ahb_mst_in_type
    
  );
end bus2ahb;

--=============================================================================
architecture Behavioral of bus2ahb is
--=============================================================================
  
  -- Registered and latched versions of the bus command. _r is simply delayed
  -- by one cycle, _l is connected to the combinatorial bus request in the
  -- first cycle of a transfer and then switches to the registered version
  -- while busy is high.
  signal bus2bridge_r           : bus_mst2slv_type;
  signal bus2bridge_l           : bus_mst2slv_type;
  
  -- Local bus result signal.
  signal bridge2bus_s           : bus_slv2mst_type;
  
  -- Interfacing signals for grlib.dma2ahb.
  signal bus2bridge_dma         : dma_in_type;
  signal bridge2bus_dma         : dma_out_type;
  
  -- This is set when the bus was requesting something in the previous cycle.
  -- Used to generate the busy signal.
  signal requesting_r           : std_logic;
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- Bus request translation
  -----------------------------------------------------------------------------
  -- Generate a register which stores the bus request for the ongoing transfer.
  bus_request_reg: process (clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        bus2bridge_r <= BUS_MST2SLV_IDLE;
      else
        bus2bridge_r <= bus2bridge;
      end if;
    end if;
  end process;
  
  -- Switch from the incoming bus request to the registered version of the
  -- request while the bus is busy.
  bus2bridge_l <= bus2bridge_r when bridge2bus_s.busy = '1' else bus2bridge;
  
  -- Convert the bus request into the format expected by the AHB master.
  bus_request_proc: process (bus2bridge_l, reset) is
    variable size               : std_logic_vector(1 downto 0);
    variable index              : std_logic_vector(1 downto 0);
  begin
    
    -- Assign trivial signals and set defaults.
    bus2bridge_dma.reset        <= reset;
    bus2bridge_dma.address      <= bus2bridge_l.address;
    bus2bridge_dma.data         <= bus2bridge_l.writeData;
    bus2bridge_dma.request      <= bus2bridge_l.readEnable or bus2bridge_l.writeEnable;
    bus2bridge_dma.burst        <= bus2bridge_l.flags.burst;
    bus2bridge_dma.beat         <= HINCR4;
    bus2bridge_dma.size         <= HSIZE32;
    bus2bridge_dma.store        <= bus2bridge_l.writeEnable;
    bus2bridge_dma.lock         <= bus2bridge_l.flags.lock;
    
    -- Perform byte mask to size/address translation.
    size := HSIZE32;
    index := "00";
    if bus2bridge_l.writeEnable = '1' then
      case bus2bridge_l.writeMask is
        when "1000" => size := HSIZE8;  index := "00";
        when "0100" => size := HSIZE8;  index := "01";
        when "0010" => size := HSIZE8;  index := "10";
        when "0001" => size := HSIZE8;  index := "11";
        when "1100" => size := HSIZE16; index := "00";
        when "0011" => size := HSIZE16; index := "10";
        when "1111" => size := HSIZE32; index := "00";
        when others => report "Invalid write mask detected." severity warning;
      end case;
    end if;
    bus2bridge_dma.size <= size;
    bus2bridge_dma.address(1 downto 0) <= index;
    
  end process;
  
  -----------------------------------------------------------------------------
  -- Bus result translation
  -----------------------------------------------------------------------------
  -- Delay the requesting signal by one cycle.
  requesting_reg: process (clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        requesting_r <= '0';
      else
        requesting_r <= bus2bridge_dma.request;
      end if;
    end if;
  end process;
  
  -- Determine the bus result.
  bus_result_proc: process (bridge2bus_dma, requesting_r) is
    variable ack  : std_logic;
  begin
    
    -- Set default values.
    bridge2bus_s <= BUS_SLV2MST_IDLE;
    
    -- Handle normal operation.
    bridge2bus_s.readData   <= bridge2bus_dma.data;
    bridge2bus_s.fault      <= '0';
    bridge2bus_s.busy       <= requesting_r and not bridge2bus_dma.okay;
    bridge2bus_s.ack        <= bridge2bus_dma.okay;
    
    -- Handle bus errors.
    if bridge2bus_dma.fault = '1' then
      bridge2bus_s.readData <= BUS_ERROR_CODE;
      bridge2bus_s.fault    <= '1';
      bridge2bus_s.busy     <= '0';
      bridge2bus_s.ack      <= '1';
    end if;
    
  end process;
  
  -- Forward the bus result.
  bridge2bus <= bridge2bus_s;
  
  -----------------------------------------------------------------------------
  -- Instantiate the grlib AHB master
  -----------------------------------------------------------------------------
  -- FIXME: dma2ahb seems to deadlock when a bus error occurs. Need to either
  -- fix dma2ahb, use another master from grlib or make our own AHB master.
  ahb_master_block: block is
    signal hreset_n             : std_ulogic;
    signal hclk                 : std_ulogic;
  begin
    
    -- Convert the clock and reset signals to the right convention.
    hreset_n <= not reset;
    hclk <= clk;
    
    -- Instantiate the grlib AHB master.
    ahb_master_inst: entity grlib.dma2ahb
      generic map (
        hindex                  => AHB_MASTER_INDEX,
        vendorid                => AHB_VENDOR_ID,
        deviceid                => AHB_DEVICE_ID,
        version                 => AHB_VERSION,
        syncrst                 => 1,
        boundary                => 1
      )
      port map (
        HCLK                    => hclk,
        HRESETn                 => hreset_n,
        DMAIn                   => bus2bridge_dma,
        DMAOut                  => bridge2bus_dma,
        AHBIn                   => ahb2bridge,
        AHBOut                  => bridge2ahb
      );
    
  end block;
  
end Behavioral;

