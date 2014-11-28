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

-- 6. r-VEX was developed by Stephan Wong, Thijs van As, Fakhar Anjam, Roel Seedorf,
-- Anthony Brandon. r-VEX is currently maintained by TU Delft (J.S.S.M.Wong@tudelft.nl).

-- Copyright (C) 2008-2014 by TU Delft.

library IEEE;
use IEEE.std_logic_1164.all;

library work;
use work.rvex_pkg.all;
use work.rvex_pipeline_pkg.all;

--=============================================================================
-- This package contains type definitions and constants relevant only to the
-- core itself. This is used in virtually all entities used in the core, but
-- does not need to be imported by anything using the rvex cores.
-------------------------------------------------------------------------------
package rvex_intIface_pkg is
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- Functions to extract information from configuration
  -----------------------------------------------------------------------------
  -- Converts a lane index to a group index.
  function lane2group (
    lane  : natural;
    CFG   : rvex_generic_config_type
  ) return natural;
  
  -- Converts a group index to the first lane index in it.
  function group2firstLane (
    laneGroup : natural;
    CFG       : rvex_generic_config_type
  ) return natural;
  
  -- Converts a lane index to the index of the first lane in the group.
  function lane2firstLane (
    lane      : natural;
    CFG       : rvex_generic_config_type
  ) return natural;
  
  -----------------------------------------------------------------------------
  -- Utility functions
  -----------------------------------------------------------------------------
  -- Determines the indices for a block in a binary tree. See package body for
  -- more information.
  procedure binTreeIndices(
    level       : in  natural;
    blockIndex  : in  natural;
    indexA      : out natural;
    indexB      : out natural
  );
  
  -----------------------------------------------------------------------------
  -- Common datatypes
  -----------------------------------------------------------------------------
  -- Subtypes for some common datatypes used within the core. These are
  -- prefixed with rvex_ mostly for consistency with the basic types which are
  -- also used in the external interface.
  subtype rvex_opcode_type      is std_logic_vector(31 downto 24); -- Opcode portion of a syllable.
  subtype rvex_gpRegAddr_type   is std_logic_vector( 4 downto  0); -- General purpose register file address (excluding context).
  subtype rvex_brRegAddr_type   is std_logic_vector( 2 downto  0); -- Branch register file address (excluding context).
  subtype rvex_brRegData_type   is std_logic_vector( 7 downto  0); -- Branch register mask (excluding context), i.e., one bit per flag.
  subtype rvex_2bit_type        is std_logic_vector( 1 downto  0); -- Any 2-bit word, used for configuration control.
  subtype rvex_3bit_type        is std_logic_vector( 2 downto  0); -- Any 3-bit word, used for configuration control.
  subtype rvex_limmh_type       is std_logic_vector(31 downto  9); -- The part of a long immediate which is borrowed from another syllable.
  
  -- Array types for the above subtypes.
  type rvex_opcode_array        is array (natural range <>) of rvex_opcode_type;
  type rvex_gpRegAddr_array     is array (natural range <>) of rvex_gpRegAddr_type;
  type rvex_brRegAddr_array     is array (natural range <>) of rvex_brRegAddr_type;
  type rvex_brRegData_array     is array (natural range <>) of rvex_brRegData_type;
  type rvex_2bit_array          is array (natural range <>) of rvex_2bit_type;
  type rvex_3bit_array          is array (natural range <>) of rvex_3bit_type;
  type rvex_limmh_array         is array (natural range <>) of rvex_limmh_type;
  
  -- Throughout the rvex core, std_logic 'U' values are used to indicate values
  -- which are not valid yet. As these kinds of signals should never be used,
  -- this is not a problem for synthesis, and helps discover undefined things
  -- leaking into the datapaths somehow during simulation. This does however
  -- result in metavalue spam from numeric_std. If you would like to prevent
  -- this spam, or have some kind of synthesis tool which does not substitute
  -- 'U' with something real automatically, you can change the value used for
  -- undefined values to '0' here.
  constant RVEX_UNDEF           : std_logic := 'U';
  
  -----------------------------------------------------------------------------
  -- General purpose register file read/write ports
  -----------------------------------------------------------------------------
  -- These records describe the general purpose register file read and write
  -- ports, along with forwarding information. Unlike most other signals in the
  -- design, these need to be placed in records because we need array types for
  -- them and the size of the records themselves depends on pipeline
  -- configuration.
  
  -- General purpose register file read port.
  type pl2gpreg_readPort_type is record
    
    -- Read address for all stages which receive forwarding information.
    addr                        : rvex_gpRegAddr_array(S_RD to S_FW);
    
  end record;

  type gpreg2pl_readPort_type is record
    
    -- Forwarded read data for all stages which forwarding information. Valid
    -- indicates whether the contents of data are meaningful; when valid is
    -- low, the value from the previous pipeline stage should be used.
    data                        : rvex_data_array(S_RD+L_RD to S_FW);
    valid                       : std_logic_vector(S_RD+L_RD to S_FW);
    
  end record;
  
  -- General purpose register file write port.
  type pl2gpreg_writePort_type is record
    
    -- Write address and data for all stages.
    addr                        : rvex_gpRegAddr_array(S_FIRST to S_WB+L_WB);
    data                        : rvex_data_array(S_FIRST to S_WB+L_WB);
    
    -- Whether the data in the WB stage should be committed to the register
    -- file.
    writeEnable                 : std_logic_vector(S_WB to S_WB);
    
    -- Whether the data in the associated stage should be forwarded to earlier
    -- stages. This has essentially the same meaning as writeEnable, although
    -- there are cases, for example when a trap occurs, where writeEnable needs
    -- to go low but forwardEnable is don't care. By making use of this don't
    -- care, the forwarding logic does not need to depend on trap information.
    -- It is very important that this is tied to zero for all stages before the
    -- first stage which actually computes something, because this determines
    -- how large the forwarding logic will become.
    forwardEnable               : std_logic_vector(S_FIRST to S_WB+L_WB);
    
  end record;
  
  -- Array types for the read and write ports.
  type pl2gpreg_readPort_array  is array (natural range <>) of pl2gpreg_readPort_type;
  type gpreg2pl_readPort_array  is array (natural range <>) of gpreg2pl_readPort_type;
  type pl2gpreg_writePort_array is array (natural range <>) of pl2gpreg_writePort_type;
  
  -----------------------------------------------------------------------------
  -- Branch and link register file read/write ports
  -----------------------------------------------------------------------------
  -- These records describe the branch and link register read and write ports
  -- along with forwarding information. Unlike most other signals in the
  -- design, these need to be placed in records because we need array types for
  -- them and the size of the records themselves depends on pipeline
  -- configuration.
  
  -- Branch/link register file read port.
  type cxreg2pl_readPort_type is record
    
    -- Forwarded read data for all stages which forwarding information.
    brData                      : rvex_brRegData_array(S_SRD to S_SFW);
    linkData                    : rvex_address_array(S_SRD to S_SFW);
    
  end record;
  
  -- Branch/link register file write port.
  type pl2cxreg_writePort_type is record
    
    -- Write data for all registers and stages.
    brData                      : rvex_brRegData_array(S_FIRST to S_SWB);
    linkData                    : rvex_address_array(S_FIRST to S_SWB);
    
    -- Whether the data in the SWB stage should be committed to the register
    -- file.
    brWriteEnable               : rvex_brRegData_array(S_SWB to S_SWB);
    linkWriteEnable             : std_logic_vector(S_SWB to S_SWB);
    
    -- Whether the data in the associated stage should be forwarded to earlier
    -- stages. This has essentially the same meaning as writeEnable, although
    -- there are cases, for example when a trap occurs, where writeEnable needs
    -- to go low but forwardEnable is don't care. By making use of this don't
    -- care, the forwarding logic does not need to depend on trap information.
    -- It is very important that this is tied to zero for all stages before the
    -- first stage which actually computes something, because this determines
    -- how large the forwarding logic will become.
    brForwardEnable             : rvex_brRegData_array(S_FIRST to S_SWB);
    linkForwardEnable           : std_logic_vector(S_FIRST to S_SWB);
    
  end record;
  
  -- Array types for the read and write ports.
  type cxreg2pl_readPort_array  is array (natural range <>) of cxreg2pl_readPort_type;
  type pl2cxreg_writePort_array is array (natural range <>) of pl2cxreg_writePort_type;
  
  -----------------------------------------------------------------------------
  -- Breakpoint information record
  -----------------------------------------------------------------------------
  -- This record contains breakpoint information for the BRK unit.
  type cxreg2pl_breakpoint_info_type is record
    
    -- Breakpoint addresses. Depending on generic configuration, only a subset
    -- of these are used.
    addr                        : rvex_address_array(3 downto 0);
    
    -- Configuration for each breakpoint. The encoding is as follows:
    --  - 00 -> breakpoint disabled.
    --  - 01 -> instruction breakpoint.
    --  - 10 -> data write breakpoint.
    --  - 11 -> data access breakpoint.
    cfg                         : rvex_2bit_array(3 downto 0);
    
  end record;
  
  -- Array type for the above.
  type cxreg2pl_breakpoint_info_array is array (natural range <>) of cxreg2pl_breakpoint_info_type;
  
end rvex_intIface_pkg;

package body rvex_intIface_pkg is

  -----------------------------------------------------------------------------
  -- Functions to extract information from configuration
  -----------------------------------------------------------------------------
  -- Converts a lane index to a group index.
  function lane2group (
    lane      : natural;
    CFG       : rvex_generic_config_type
  ) return natural is
  begin
    return lane / 2**(CFG.numLanesLog2 - CFG.numLaneGroupsLog2);
  end lane2group;
  
  -- Converts a group index to the first lane index in it.
  function group2firstLane (
    laneGroup : natural;
    CFG       : rvex_generic_config_type
  ) return natural is
  begin
    return laneGroup * 2**(CFG.numLanesLog2 - CFG.numLaneGroupsLog2);
  end group2firstLane;
  
  -- Converts a lane index to the index of the first lane in the group.
  function lane2firstLane (
    lane      : natural;
    CFG       : rvex_generic_config_type
  ) return natural is
  begin
    return group2firstLane(lane2group(lane, CFG), CFG);
  end lane2firstLane;
  
  -----------------------------------------------------------------------------
  -- Utility functions
  -----------------------------------------------------------------------------
  -- Used to construct a binary tree network for connecting pipelane groups
  -- together which looks like this:
  --                                     indexA, indexB
  --                                           |
  --         ___       ___        ___          v
  --   ---->| 0 |---->| 0 |----->| 0 |-------> 0
  --        |   |     | __|      | __|
  --   ---->|___|----->| 1 |----->| 1 |------> 1
  --         ___      ||   |     || __|
  --   ---->| 1 |---->||   | ----->| 2 |-----> 2
  --        |   |      |   |     ||| __|
  --   ---->|___|----->|___|------->| 3 |----> 3
  --         ___       ___       ||||   |
  --   ---->| 2 |---->| 2 |----->||||   | ---> 4
  --        |   |     | __|       |||   |
  --   ---->|___|----->| 3 |----->|||   | ---> 5
  --         ___      ||   |       ||   |
  --   ---->| 3 |---->||   | ----->||   | ---> 6
  --        |   |      |   |        |   |
  --   ---->|___|----->|___|------->|___|----> 7
  --
  -- level -> 0          1            2
  --
  -- Number in blocks: blockIndex
  --
  -- The method takes level and block as parameters and outputs the indices for
  -- each connection block. The outer loop for level should range from 0 to
  -- log2(numIndices)-1, the inner loop for blockIndex should range from 0 to
  -- numIndices/2-1.
  procedure binTreeIndices(
    level       : in  natural;
    blockIndex  : in  natural;
    indexA      : out natural;
    indexB      : out natural
  ) is
    variable index: natural;
  begin
    index   := (blockIndex / 2**level) * 2 * 2**level
             + (blockIndex mod 2**level);
    indexA  := index;
    indexB  := index + 2**level;
  end procedure;
  
end rvex_intIface_pkg;
