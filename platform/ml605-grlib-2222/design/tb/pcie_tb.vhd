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
--
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

use work.constants.all;

-- Wrapper for the Verilog PCIe simulation code
entity xilinx_pcie_tb is
  generic (
    REF_CLK_FREQ                            : integer := 0;          -- 0 - 100 MHz, 1 - 125 MHz,  2 - 250 MHz
    ALLOW_X8_GEN2                           : string := "FALSE";
    PL_FAST_TRAIN                           : string := "FALSE";
    LINK_CAP_MAX_LINK_WIDTH                 : integer := 8;
    DEVICE_ID                               : integer := 16#506F#;
    LINK_CAP_MAX_LINK_SPEED                 : integer := 1;
    LINK_CTRL2_TARGET_LINK_SPEED            : integer := 1;
    DEV_CAP_MAX_PAYLOAD_SUPPORTED           : integer := 1;
    USER_CLK_FREQ                           : integer := 3;
    VC0_TX_LASTPACKET                       : integer := 28;
    VC0_RX_RAM_LIMIT                        : integer := 16#03ff#;
    VC0_CPL_INFINITE                        : string := "TRUE";
    VC0_TOTAL_CREDITS_PD                    : integer := 154;
    VC0_TOTAL_CREDITS_CD                    : integer := 154;
    -- added for simulation
    LINK_CAP_DLL_LINK_ACTIVE_REPORTING_CAP  : string := "TRUE";
    UPCONFIG_CAPABLE                        : string := "TRUE"
  );
  port (
    sys_clk                                 : in  std_logic;
    sys_reset_n                             : in  std_logic;

    pci_exp_rxp                             : in  std_logic_vector(0 to LINK_CAP_MAX_LINK_WIDTH-1);
    pci_exp_txp                             : out std_logic_vector(0 to LINK_CAP_MAX_LINK_WIDTH-1);
    pci_exp_rxn                             : in  std_logic_vector(0 to LINK_CAP_MAX_LINK_WIDTH-1);
    pci_exp_txn                             : out std_logic_vector(0 to LINK_CAP_MAX_LINK_WIDTH-1)
  );
end entity;

architecture behavioral of xilinx_pcie_tb is
  component xilinx_pcie_2_0_rport_v6
    generic (
      REF_CLK_FREQ                            : integer := 0;          -- 0 - 100 MHz, 1 - 125 MHz,  2 - 250 MHz
      ALLOW_X8_GEN2                           : string := "FALSE";
      PL_FAST_TRAIN                           : string := "FALSE";
      LINK_CAP_MAX_LINK_WIDTH                 : integer := 8;
      DEVICE_ID                               : integer := 16#506F#;
      LINK_CAP_MAX_LINK_SPEED                 : integer := 1;
      LINK_CTRL2_TARGET_LINK_SPEED            : integer := 1;
      DEV_CAP_MAX_PAYLOAD_SUPPORTED           : integer := 1;
      USER_CLK_FREQ                           : integer := 3;
      VC0_TX_LASTPACKET                       : integer := 28;
      VC0_RX_RAM_LIMIT                        : integer := 16#03ff#;
      VC0_CPL_INFINITE                        : string := "TRUE";
      VC0_TOTAL_CREDITS_PD                    : integer := 154;
      VC0_TOTAL_CREDITS_CD                    : integer := 154;
      -- added for simulation
      LINK_CAP_DLL_LINK_ACTIVE_REPORTING_CAP  : string := "TRUE";
      UPCONFIG_CAPABLE                        : string := "TRUE"
    );
    port (
      sys_clk                                 : in  std_logic;
      sys_reset_n                             : in  std_logic;

      pci_exp_rxp                             : in  std_logic_vector(0 to LINK_CAP_MAX_LINK_WIDTH-1);
      pci_exp_txp                             : out std_logic_vector(0 to LINK_CAP_MAX_LINK_WIDTH-1);
      pci_exp_rxn                             : in  std_logic_vector(0 to LINK_CAP_MAX_LINK_WIDTH-1);
      pci_exp_txn                             : out std_logic_vector(0 to LINK_CAP_MAX_LINK_WIDTH-1)
    );
  end component;
begin
  comp: xilinx_pcie_2_0_rport_v6
    generic map(
      REF_CLK_FREQ                            => REF_CLK_FREQ,
      ALLOW_X8_GEN2                           => ALLOW_X8_GEN2,
      PL_FAST_TRAIN                           => PL_FAST_TRAIN,
      LINK_CAP_MAX_LINK_WIDTH                 => LINK_CAP_MAX_LINK_WIDTH,
      DEVICE_ID                               => DEVICE_ID,
      LINK_CAP_MAX_LINK_SPEED                 => LINK_CAP_MAX_LINK_SPEED,
      LINK_CTRL2_TARGET_LINK_SPEED            => LINK_CTRL2_TARGET_LINK_SPEED,
      DEV_CAP_MAX_PAYLOAD_SUPPORTED           => DEV_CAP_MAX_PAYLOAD_SUPPORTED,
      USER_CLK_FREQ                           => USER_CLK_FREQ,
      VC0_TX_LASTPACKET                       => VC0_TX_LASTPACKET,
      VC0_RX_RAM_LIMIT                        => VC0_RX_RAM_LIMIT,
      VC0_CPL_INFINITE                        => VC0_CPL_INFINITE,
      VC0_TOTAL_CREDITS_PD                    => VC0_TOTAL_CREDITS_PD,
      VC0_TOTAL_CREDITS_CD                    => VC0_TOTAL_CREDITS_CD,
      -- added for simulation
      LINK_CAP_DLL_LINK_ACTIVE_REPORTING_CAP  => LINK_CAP_DLL_LINK_ACTIVE_REPORTING_CAP,
      UPCONFIG_CAPABLE                        => UPCONFIG_CAPABLE
    )
    port map (
      sys_clk                                 => sys_clk,
      sys_reset_n                             => sys_reset_n,

      pci_exp_rxp                             => pci_exp_rxp,
      pci_exp_txp                             => pci_exp_txp,
      pci_exp_rxn                             => pci_exp_rxn,
      pci_exp_txn                             => pci_exp_txn
    );
end architecture;
