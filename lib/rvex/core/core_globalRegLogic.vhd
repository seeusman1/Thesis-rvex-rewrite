-- This file is generated by the scripts in /config. --

-- r-VEX processor                                                                                   -- GENERATED --
-- Copyright (C) 2008-2015 by TU Delft.
-- All Rights Reserved.

-- THIS IS A LEGAL DOCUMENT, BY USING r-VEX,
-- YOU ARE AGREEING TO THESE TERMS AND CONDITIONS.

-- No portion of this work may be used by any commercial entity, or for any
-- commercial purpose, without the prior, written permission of TU Delft.
-- Nonprofit and noncommercial use is permitted as described below.
                                                                                                     -- GENERATED --
-- 1. r-VEX is provided AS IS, with no warranty of any kind, express
-- or implied. The user of the code accepts full responsibility for the
-- application of the code and the use of any results.

-- 2. Nonprofit and noncommercial use is encouraged. r-VEX may be
-- downloaded, compiled, synthesized, copied, and modified solely for nonprofit,
-- educational, noncommercial research, and noncommercial scholarship
-- purposes provided that this notice in its entirety accompanies all copies.
-- Copies of the modified software can be delivered to persons who use it
-- solely for nonprofit, educational, noncommercial research, and                                    -- GENERATED --
-- noncommercial scholarship purposes provided that this notice in its
-- entirety accompanies all copies.

-- 3. ALL COMMERCIAL USE, AND ALL USE BY FOR PROFIT ENTITIES, IS EXPRESSLY
-- PROHIBITED WITHOUT A LICENSE FROM TU Delft (J.S.S.M.Wong@tudelft.nl).

-- 4. No nonprofit user may place any restrictions on the use of this software,
-- including as modified by the user, by any other authorized user.

-- 5. Noncommercial and nonprofit users may distribute copies of r-VEX                               -- GENERATED --
-- in compiled or binary form as set forth in Section 2, provided that
-- either: (A) it is accompanied by the corresponding machine-readable source
-- code, or (B) it is accompanied by a written offer, with no time limit, to
-- give anyone a machine-readable copy of the corresponding source code in
-- return for reimbursement of the cost of distribution. This written offer
-- must permit verbatim duplication by anyone, or (C) it is distributed by
-- someone who received only the executable form, and is accompanied by a
-- copy of the written offer of source code.

-- 6. r-VEX was developed by Stephan Wong, Thijs van As, Fakhar Anjam,                               -- GENERATED --
-- Roel Seedorf, Anthony Brandon, Jeroen van Straten. r-VEX is currently
-- maintained by TU Delft (J.S.S.M.Wong@tudelft.nl).

-- Copyright (C) 2008-2015 by TU Delft.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library rvex;                                                                                        -- GENERATED --
use rvex.common_pkg.all;
use rvex.utils_pkg.all;
use rvex.core_pkg.all;
use rvex.core_intIface_pkg.all;
use rvex.core_ctrlRegs_pkg.all;
use rvex.core_trap_pkg.all;
use rvex.core_pipeline_pkg.all;

--=============================================================================
-- This entity contains the specifications and logic for the control registers                       -- GENERATED --
-- which are shared between all cores. They are read only to the core, but the
-- debug bus can write to them (depending on specification).
-------------------------------------------------------------------------------
entity core_globalRegLogic is
--=============================================================================
  generic (

    -- Configuration.
    CFG                         : rvex_generic_config_type
                                                                                                     -- GENERATED --
  );
  port (

    ---------------------------------------------------------------------------
    -- System control
    ---------------------------------------------------------------------------
    -- Active high synchronous reset input.
    reset                       : in  std_logic;

    -- Clock input, registers are rising edge triggered.                                             -- GENERATED --
    clk                         : in  std_logic;

    -- Active high global clock enable input.
    clkEn                       : in  std_logic;

    ---------------------------------------------------------------------------
    -- Run control
    ---------------------------------------------------------------------------
    -- Reset output. This can be made high for one cycle by the debug bus
    -- writing a one to the MSB of GSR.                                                              -- GENERATED --
    gbreg2rv_reset              : out std_logic;

    ---------------------------------------------------------------------------
    -- Interface with configuration logic
    ---------------------------------------------------------------------------
    -- Each nibble in the data word corresponds to a pipelane group, of which
    -- bit 3 specifies whether the pipelane group should be disabled (high) or
    -- enabled (low) and, if low, bit 2..0 specify the context it should run
    -- on. Bits which are not supported by the core (as specified in the CFG
    -- generic) should be written zero or the request will be ignored (as                            -- GENERATED --
    -- specified by the error flag in the global control register file). The
    -- enable signal is active high.
    gbreg2cfg_requestData       : out rvex_data_type;
    gbreg2cfg_requestEnable     : out std_logic;

    -- Current configuration, using the same encoding as the request data.
    cfg2gbreg_currentCfg        : in  rvex_data_type;

    -- Configuration busy signal. When set, new configuration requests are not
    -- accepted.                                                                                     -- GENERATED --
    cfg2gbreg_busy              : in  std_logic;

    -- Configuration error signal. This is set when the last configuration
    -- request was erroneous.
    cfg2gbreg_error             : in  std_logic;

    -- When reconfiguration is requested, this field is set to the index of the
    -- context which requested the configuration, or all ones if the source was
    -- the debug bus.
    cfg2gbreg_requesterID       : in  std_logic_vector(3 downto 0);                                  -- GENERATED --

    ---------------------------------------------------------------------------
    -- Interface with memory
    ---------------------------------------------------------------------------
    -- Affinity signal from the memory.
    imem2gbreg_affinity         : in  rvex_data_type;

    ---------------------------------------------------------------------------
    -- Debug bus to global control register interface
    ---------------------------------------------------------------------------                      -- GENERATED --
    -- Global control register address. Only bits 7..0 are used.
    creg2gbreg_dbgAddr          : in  rvex_address_type;

    -- Write command.
    creg2gbreg_dbgWriteEnable   : in  std_logic;
    creg2gbreg_dbgWriteMask     : in  rvex_mask_type;
    creg2gbreg_dbgWriteData     : in  rvex_data_type;

    -- Read command and reply.
    creg2gbreg_dbgReadEnable    : in  std_logic;                                                     -- GENERATED --
    gbreg2creg_dbgReadData      : out rvex_data_type;

    ---------------------------------------------------------------------------
    -- Core to global control register interface
    ---------------------------------------------------------------------------
    -- Global control register address. Only bits 7..0 are used.
    creg2gbreg_coreAddr         : in  rvex_address_array(2**CFG.numLaneGroupsLog2-1 downto 0);

    -- Read command and reply.
    creg2gbreg_coreReadEnable   : in  std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);         -- GENERATED --
    gbreg2creg_coreReadData     : out rvex_data_array(2**CFG.numLaneGroupsLog2-1 downto 0)

  );
end core_globalRegLogic;

--=============================================================================
architecture Behavioral of core_globalRegLogic is
--=============================================================================

  -- Coerces string literal x to an std_logic_vector.                                                -- GENERATED --
  function bitvec_lit(x: std_logic_vector) return std_logic_vector is
  begin
    return x;
  end bitvec_lit;

  -- Coerces string literal x to an unsigned.
  function unsigned_lit(x: unsigned) return unsigned is
  begin
    return x;
  end unsigned_lit;                                                                                  -- GENERATED --

  -- Reduces an std_logic_vector to a single std_logic using OR.
  function vec2bit(x: std_logic_vector) return std_logic is
    variable y : std_logic;
  begin
    y := '0';
    for i in x'range loop
      y := y or x(i);
    end loop;
    return y;                                                                                        -- GENERATED --
  end vec2bit;

  -- Returns an std_logic_vector of size s with bit 0 set to std_logic x and the
  -- rest to '0'.
  function bit2vec(x: std_logic; s: natural) return std_logic_vector is
    variable result: std_logic_vector(s-1 downto 0) := (others => '0');
  begin
    result(0) := x;
    return result;
  end bit2vec;                                                                                       -- GENERATED --

  -- Returns boolean x as an std_logic using positive logic.
  function bool2bit(x: boolean) return std_logic is
  begin
    if x then
      return '1';
    else
      return '0';
    end if;
  end bool2bit;                                                                                      -- GENERATED --

  -- Returns std_logic x as a boolean using positive logic.
  function bit2bool(x: std_logic) return boolean is
  begin
    return x = '1';
  end bit2bool;

  -- Returns 1 for true and 0 for false.
  function bool2int(x: boolean) return natural is
  begin                                                                                              -- GENERATED --
    if x then
      return 1;
    else
      return 0;
    end if;
  end bool2int;

  -- Returns true for nonzero and false for zero.
  function int2bool(x: integer) return boolean is
  begin                                                                                              -- GENERATED --
    return x /= 0;
  end int2bool;

  -- Generated registers.

--=============================================================================
begin -- architecture
--=============================================================================

  gbregs: process (clk) is                                                                           -- GENERATED --

    -- Static variables and constants.
    variable bus_writeData     : rvex_data_type;
    variable bus_writeMaskDbg  : rvex_data_type;
    variable bus_wordAddr      : unsigned(5 downto 0);

    -- Generated variables and constants.

  begin
    if rising_edge(clk) then                                                                         -- GENERATED --

      -- Set readData to 0 by default.
      gbreg2creg_dbgReadData <= (others => '0');
      gbreg2creg_coreReadData <= (others => (others => '0'));

      if reset = '1' then

        -- Reset all registers and ports.
        gbreg2rv_reset <= bool2bit(int2bool(0));
        gbreg2cfg_requestData <= std_logic_vector(to_unsigned(0, 32));                               -- GENERATED --
        gbreg2cfg_requestEnable <= bool2bit(int2bool(0));

      elsif clkEn = '1' then

        -- Setup the bus write command variables which are expected by the
        -- generated code.
        bus_writeData := creg2gbreg_dbgWriteData;
        bus_writeMaskDbg := (
            31 downto 24 => creg2gbreg_dbgWriteEnable and creg2gbreg_dbgWriteMask(3),
            23 downto 16 => creg2gbreg_dbgWriteEnable and creg2gbreg_dbgWriteMask(2),                -- GENERATED --
            15 downto  8 => creg2gbreg_dbgWriteEnable and creg2gbreg_dbgWriteMask(1),
            7 downto  0 => creg2gbreg_dbgWriteEnable and creg2gbreg_dbgWriteMask(0)
        );
        bus_wordAddr := unsigned(creg2gbreg_dbgAddr(7 downto 2));

        -- Generated register implementation code.

        -- Bus read muxes.
        case creg2gbreg_dbgAddr(7 downto 2) is
          when "000000" => gbreg2creg_dbgReadData <= (((((bitvec_lit("0")) & (bitvec_lit("00000000000000000"))) & (bitvec_lit("0"))) & (bitvec_lit("0"))) & (bitvec_lit("0000"))) & (bitvec_lit("00000000")); -- GENERATED --
          when "000001" => gbreg2creg_dbgReadData <= bitvec_lit("00000000000000000000000000000000");
          when "000010" => gbreg2creg_dbgReadData <= bitvec_lit("00000000000000000000000000000000");
          when "000011" => gbreg2creg_dbgReadData <= bitvec_lit("00000000000000000000000000000000");
          when "000100" => gbreg2creg_dbgReadData <= bitvec_lit("00000000000000000000000000000000");
          when "000101" => gbreg2creg_dbgReadData <= bitvec_lit("00000000000000000000000000000000");
          when "101000" => gbreg2creg_dbgReadData <= (bitvec_lit("0000000000000000")) & (bitvec_lit("0000000000000000"));
          when "101001" => gbreg2creg_dbgReadData <= (bitvec_lit("0000000000000000")) & (bitvec_lit("0000000000000000"));
          when "101010" => gbreg2creg_dbgReadData <= (bitvec_lit("0000000000000000")) & (bitvec_lit("0000000000000000"));
          when "101011" => gbreg2creg_dbgReadData <= (bitvec_lit("0000000000000000")) & (bitvec_lit("0000000000000000"));
          when "101100" => gbreg2creg_dbgReadData <= (bitvec_lit("0000000000000000")) & (bitvec_lit("0000000000000000")); -- GENERATED --
          when "101101" => gbreg2creg_dbgReadData <= (bitvec_lit("0000000000000000")) & (bitvec_lit("0000000000000000"));
          when "101110" => gbreg2creg_dbgReadData <= (bitvec_lit("0000000000000000")) & (bitvec_lit("0000000000000000"));
          when "101111" => gbreg2creg_dbgReadData <= (bitvec_lit("0000000000000000")) & (bitvec_lit("0000000000000000"));
          when "110000" => gbreg2creg_dbgReadData <= (((bitvec_lit("00000000")) & (bitvec_lit("00000000"))) & (bitvec_lit("00000000"))) & (bitvec_lit("00000000"));
          when "110001" => gbreg2creg_dbgReadData <= (((bitvec_lit("00000000")) & (bitvec_lit("00000000"))) & (bitvec_lit("00000000"))) & (bitvec_lit("00000000"));
          when "110010" => gbreg2creg_dbgReadData <= (((bitvec_lit("00000000")) & (bitvec_lit("00000000"))) & (bitvec_lit("00000000"))) & (bitvec_lit("00000000"));
          when "110011" => gbreg2creg_dbgReadData <= (((bitvec_lit("00000000")) & (bitvec_lit("00000000"))) & (bitvec_lit("00000000"))) & (bitvec_lit("00000000"));
          when "110100" => gbreg2creg_dbgReadData <= bitvec_lit("00000000000000000000000000000000");
          when "110101" => gbreg2creg_dbgReadData <= (((((((bitvec_lit("0000")) & (bitvec_lit("0000"))) & (bitvec_lit("0000"))) & (bitvec_lit("0000"))) & (bitvec_lit("0000"))) & (bitvec_lit("0000"))) & (bitvec_lit("0000"))) & (bitvec_lit("0000"));
          when "110110" => gbreg2creg_dbgReadData <= bitvec_lit("00000000000000000000000000000000"); -- GENERATED --
          when "110111" => gbreg2creg_dbgReadData <= (((((((bitvec_lit("0000")) & (bitvec_lit("0000"))) & (bitvec_lit("0000"))) & (bitvec_lit("0000"))) & (bitvec_lit("0000"))) & (bitvec_lit("0000"))) & (bitvec_lit("0000"))) & (bitvec_lit("0000"));
          when "111000" => gbreg2creg_dbgReadData <= bitvec_lit("00000000000000000000000000000000");
          when "111001" => gbreg2creg_dbgReadData <= bitvec_lit("00000000000000000000000000000000");
          when "111010" => gbreg2creg_dbgReadData <= ((((((((((bitvec_lit("0000")) & (bitvec_lit("0"))) & (bitvec_lit("000"))) & (bitvec_lit("00000"))) & (bitvec_lit("0"))) & (bitvec_lit("0"))) & (bitvec_lit("0"))) & (bitvec_lit("0000000000000"))) & (bitvec_lit("0"))) & (bitvec_lit("0"))) & (bitvec_lit("0"));
          when "111011" => gbreg2creg_dbgReadData <= ((((bitvec_lit("0000000000000000")) & (bitvec_lit("0000"))) & (bitvec_lit("0000"))) & (bitvec_lit("0000"))) & (bitvec_lit("0000"));
          when "111100" => gbreg2creg_dbgReadData <= (((bitvec_lit("00000000")) & (bitvec_lit("00000000"))) & (bitvec_lit("00000000"))) & (bitvec_lit("00000000"));
          when "111101" => gbreg2creg_dbgReadData <= (((bitvec_lit("00000000")) & (bitvec_lit("00000000"))) & (bitvec_lit("00000000"))) & (bitvec_lit("00000000"));
          when "111110" => gbreg2creg_dbgReadData <= (((bitvec_lit("00000000")) & (bitvec_lit("00000000"))) & (bitvec_lit("00000000"))) & (bitvec_lit("00000000"));
          when "111111" => gbreg2creg_dbgReadData <= (((bitvec_lit("00000000")) & (bitvec_lit("00000000"))) & (bitvec_lit("00000000"))) & (bitvec_lit("00000000"));
          when others => gbreg2creg_dbgReadData <= (others => '0');                                  -- GENERATED --
        end case;
        for laneGroup in 0 to 2**CFG.numLaneGroupsLog2-1 loop
          case creg2gbreg_coreAddr(laneGroup)(7 downto 2) is
            when "000000" => gbreg2creg_coreReadData(laneGroup) <= (((((bitvec_lit("0")) & (bitvec_lit("00000000000000000"))) & (bitvec_lit("0"))) & (bitvec_lit("0"))) & (bitvec_lit("0000"))) & (bitvec_lit("00000000"));
            when "000001" => gbreg2creg_coreReadData(laneGroup) <= bitvec_lit("00000000000000000000000000000000");
            when "000010" => gbreg2creg_coreReadData(laneGroup) <= bitvec_lit("00000000000000000000000000000000");
            when "000011" => gbreg2creg_coreReadData(laneGroup) <= bitvec_lit("00000000000000000000000000000000");
            when "000100" => gbreg2creg_coreReadData(laneGroup) <= bitvec_lit("00000000000000000000000000000000");
            when "000101" => gbreg2creg_coreReadData(laneGroup) <= bitvec_lit("00000000000000000000000000000000");
            when "101000" => gbreg2creg_coreReadData(laneGroup) <= (bitvec_lit("0000000000000000")) & (bitvec_lit("0000000000000000")); -- GENERATED --
            when "101001" => gbreg2creg_coreReadData(laneGroup) <= (bitvec_lit("0000000000000000")) & (bitvec_lit("0000000000000000"));
            when "101010" => gbreg2creg_coreReadData(laneGroup) <= (bitvec_lit("0000000000000000")) & (bitvec_lit("0000000000000000"));
            when "101011" => gbreg2creg_coreReadData(laneGroup) <= (bitvec_lit("0000000000000000")) & (bitvec_lit("0000000000000000"));
            when "101100" => gbreg2creg_coreReadData(laneGroup) <= (bitvec_lit("0000000000000000")) & (bitvec_lit("0000000000000000"));
            when "101101" => gbreg2creg_coreReadData(laneGroup) <= (bitvec_lit("0000000000000000")) & (bitvec_lit("0000000000000000"));
            when "101110" => gbreg2creg_coreReadData(laneGroup) <= (bitvec_lit("0000000000000000")) & (bitvec_lit("0000000000000000"));
            when "101111" => gbreg2creg_coreReadData(laneGroup) <= (bitvec_lit("0000000000000000")) & (bitvec_lit("0000000000000000"));
            when "110000" => gbreg2creg_coreReadData(laneGroup) <= (((bitvec_lit("00000000")) & (bitvec_lit("00000000"))) & (bitvec_lit("00000000"))) & (bitvec_lit("00000000"));
            when "110001" => gbreg2creg_coreReadData(laneGroup) <= (((bitvec_lit("00000000")) & (bitvec_lit("00000000"))) & (bitvec_lit("00000000"))) & (bitvec_lit("00000000"));
            when "110010" => gbreg2creg_coreReadData(laneGroup) <= (((bitvec_lit("00000000")) & (bitvec_lit("00000000"))) & (bitvec_lit("00000000"))) & (bitvec_lit("00000000")); -- GENERATED --
            when "110011" => gbreg2creg_coreReadData(laneGroup) <= (((bitvec_lit("00000000")) & (bitvec_lit("00000000"))) & (bitvec_lit("00000000"))) & (bitvec_lit("00000000"));
            when "110100" => gbreg2creg_coreReadData(laneGroup) <= bitvec_lit("00000000000000000000000000000000");
            when "110101" => gbreg2creg_coreReadData(laneGroup) <= (((((((bitvec_lit("0000")) & (bitvec_lit("0000"))) & (bitvec_lit("0000"))) & (bitvec_lit("0000"))) & (bitvec_lit("0000"))) & (bitvec_lit("0000"))) & (bitvec_lit("0000"))) & (bitvec_lit("0000"));
            when "110110" => gbreg2creg_coreReadData(laneGroup) <= bitvec_lit("00000000000000000000000000000000");
            when "110111" => gbreg2creg_coreReadData(laneGroup) <= (((((((bitvec_lit("0000")) & (bitvec_lit("0000"))) & (bitvec_lit("0000"))) & (bitvec_lit("0000"))) & (bitvec_lit("0000"))) & (bitvec_lit("0000"))) & (bitvec_lit("0000"))) & (bitvec_lit("0000"));
            when "111000" => gbreg2creg_coreReadData(laneGroup) <= bitvec_lit("00000000000000000000000000000000");
            when "111001" => gbreg2creg_coreReadData(laneGroup) <= bitvec_lit("00000000000000000000000000000000");
            when "111010" => gbreg2creg_coreReadData(laneGroup) <= ((((((((((bitvec_lit("0000")) & (bitvec_lit("0"))) & (bitvec_lit("000"))) & (bitvec_lit("00000"))) & (bitvec_lit("0"))) & (bitvec_lit("0"))) & (bitvec_lit("0"))) & (bitvec_lit("0000000000000"))) & (bitvec_lit("0"))) & (bitvec_lit("0"))) & (bitvec_lit("0"));
            when "111011" => gbreg2creg_coreReadData(laneGroup) <= ((((bitvec_lit("0000000000000000")) & (bitvec_lit("0000"))) & (bitvec_lit("0000"))) & (bitvec_lit("0000"))) & (bitvec_lit("0000"));
            when "111100" => gbreg2creg_coreReadData(laneGroup) <= (((bitvec_lit("00000000")) & (bitvec_lit("00000000"))) & (bitvec_lit("00000000"))) & (bitvec_lit("00000000")); -- GENERATED --
            when "111101" => gbreg2creg_coreReadData(laneGroup) <= (((bitvec_lit("00000000")) & (bitvec_lit("00000000"))) & (bitvec_lit("00000000"))) & (bitvec_lit("00000000"));
            when "111110" => gbreg2creg_coreReadData(laneGroup) <= (((bitvec_lit("00000000")) & (bitvec_lit("00000000"))) & (bitvec_lit("00000000"))) & (bitvec_lit("00000000"));
            when "111111" => gbreg2creg_coreReadData(laneGroup) <= (((bitvec_lit("00000000")) & (bitvec_lit("00000000"))) & (bitvec_lit("00000000"))) & (bitvec_lit("00000000"));
            when others => gbreg2creg_coreReadData(laneGroup) <= (others => '0');
          end case;
        end loop;

      end if;
    end if;
  end process;                                                                                       -- GENERATED --

end Behavioral;

