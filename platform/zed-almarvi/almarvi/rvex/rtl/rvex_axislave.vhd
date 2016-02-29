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

library work;
use work.common_pkg.all;
use work.utils_pkg.all;
use work.bus_pkg.all;
use work.core_pkg.all;
use work.rvsys_standalone_pkg.all;

--=============================================================================
-- This unit wraps the rvex core as an accelerator with its own local block RAM
-- memories, accessible through an AXI4 slave interface. The interface complies
-- with the ALMARVI accelerator interface specification.
-------------------------------------------------------------------------------
entity rvex_axislave is
--=============================================================================
  generic (
    
    -- Width of the AXI address ports. Must be at least 13+NUM_CONTEXTS_LOG2 to
    -- accomodate the r-VEX control register file, at least 2+IMEM_DEPTH_LOG2
    -- for the instruction memory and at least 2+DMEM_DEPTH_LOG2 for the data
    -- memory.
    AXI_ADDRW_G                 : integer := 17;
    
    -- 2-log of the number of bytes in the instruction memory.
    IMEM_DEPTH_LOG2             : integer := 15;
    
    -- 2-log of the number of bytes in the data memory.
    DMEM_DEPTH_LOG2             : integer := 15;
    
    -- 2-log of the number of r-VEX hardware contexts.
    NUM_CONTEXTS_LOG2           : integer := 1;
    
    -- 2-log of the number of r-VEX lane groups.
    NUM_GROUPS_LOG2             : integer := 1;
    
    -- 2-log of the number of r-VEX lanes.
    NUM_LANES_LOG2              : integer := 2
    
    -- TODO more CFG vect stuff.
    
  );
  port (
  
    -- Clock and reset.
    s_axi_aclk                  : in  std_logic;
    s_axi_aresetn               : in  std_logic;
    
    -- Read address channel.
    s_axi_araddr                : in  std_logic_vector(axi_addrw_g-1 downto 0);
    s_axi_arvalid               : in  std_logic;
    s_axi_arready               : out std_logic;
    
    -- Read data channel.
    s_axi_rdata                 : out std_logic_vector(31 downto 0);
    s_axi_rresp                 : out std_logic_vector(1 downto 0);
    s_axi_rvalid                : out std_logic;
    s_axi_rready                : in  std_logic;
    
    -- Write address channel.
    s_axi_awaddr                : in  std_logic_vector(axi_addrw_g-1 downto 0);
    s_axi_awvalid               : in  std_logic;
    s_axi_awready               : out std_logic;
    
    -- Write data channel.
    s_axi_wdata                 : in  std_logic_vector(31 downto 0);
    s_axi_wstrb                 : in  std_logic_vector(3 downto 0);
    s_axi_wvalid                : in  std_logic;
    s_axi_wready                : out std_logic;
    
    -- Write response channel.
    s_axi_bresp                 : out std_logic_vector(1 downto 0);
    s_axi_bvalid                : out std_logic;
    s_axi_bready                : in  std_logic
    
  );
end rvex_axislave;

--=============================================================================
architecture Behavioral of rvex_axislave is
--=============================================================================
  
  -- System control signals.
  signal areset                 : std_logic;
  signal reset                  : std_logic;
  
  -- AXI to r-VEX bus.
  signal bridge2bus             : bus_mst2slv_type;
  signal bus2bridge             : bus_slv2mst_type;
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- Generate reset signals
  -----------------------------------------------------------------------------
  areset <= not s_axi_aresetn;
  sync_reset_proc: process (s_axi_aclk) is
  begin
    if rising_edge(s_axi_aclk) then
      reset <= areset;
    end if;
  end process;
  
  -----------------------------------------------------------------------------
  -- Instantiate AXI to r-VEX bus bridge
  -----------------------------------------------------------------------------
  axi_bridge_inst: entity work.axi_bridge
    generic map (
      AXI_ADDRW_G               => AXI_ADDRW_G
    )
    port map (
    
      -- System control.
      areset                    => areset,
      reset                     => reset,
      clk                       => s_axi_aclk,
      
      -- AXI read address channel.
      s_axi_araddr              => s_axi_araddr,
      s_axi_arvalid             => s_axi_arvalid,
      s_axi_arready             => s_axi_arready,
      
      -- AXI read data channel.
      s_axi_rdata               => s_axi_rdata,
      s_axi_rresp               => s_axi_rresp,
      s_axi_rvalid              => s_axi_rvalid,
      s_axi_rready              => s_axi_rready,
      
      -- AXI write address channel.
      s_axi_awaddr              => s_axi_awaddr,
      s_axi_awvalid             => s_axi_awvalid,
      s_axi_awready             => s_axi_awready,
      
      -- AXI write data channel.
      s_axi_wdata               => s_axi_wdata,
      s_axi_wstrb               => s_axi_wstrb,
      s_axi_wvalid              => s_axi_wvalid,
      s_axi_wready              => s_axi_wready,
      
      -- AXI write response channel.
      s_axi_bresp               => s_axi_bresp,
      s_axi_bvalid              => s_axi_bvalid,
      s_axi_bready              => s_axi_bready,
      
      -- r-VEX bus master.
      bridge2bus                => bridge2bus,
      bus2bridge                => bus2bridge
      
    );
  
  -----------------------------------------------------------------------------
  -- Test the bridge with a simple memory
  -----------------------------------------------------------------------------
  test_mem: entity work.bus_ramBlock_singlePort
    generic map (
      DEPTH_LOG2B => IMEM_DEPTH_LOG2
    )
    port map (
      reset                     => reset,
      clk                       => s_axi_aclk,
      clkEn                     => '1',
      mst2mem_port              => bridge2bus,
      mem2mst_port              => bus2bridge
    );
  
end Behavioral;

