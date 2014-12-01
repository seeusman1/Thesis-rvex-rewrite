-- Insert license here

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.rvex_pkg.all;
use work.rvex_intIface_pkg.all;

--=============================================================================
-- This entity contains the control registers as accessed from the debug bus
-- or by the core. This is setup in a very generic way to make it easy to add,
-- remove or change registers or mappings; see rvex_ctrlRegs_pkg.vhd. The only
-- restrictions to the map are the following.
--  - The total size is 64 words or 256 bytes.
--  - The upper half of the memory is mapped to general purpose register file
--    access for debugging.
--  - The first part of the lower half of the memory is common to all cores.
--    Only the bus may write to these registers, the cores can only read.
--  - While the control registers support halfword/byte accesses, the general
--    purpose register file does not. Sub-word writes are ignored there.
-------------------------------------------------------------------------------
entity rvex_ctrlRegs is
--=============================================================================
  generic (
    
    -- Configuration.
    CFG                         : rvex_generic_config_type
    
  );
  port (
    
    ---------------------------------------------------------------------------
    -- System control
    ---------------------------------------------------------------------------
    -- Active high synchronous reset input.
    reset                       : in  std_logic;
    
    -- Clock input, registers are rising edge triggered.
    clk                         : in  std_logic;
    
    -- Active high global clock enable input.
    clkEn                       : in  std_logic;
    
    -- Active high stall signals from each context/core.
    stallIn                     : in  std_logic_vector(CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Active high stall signals to each context/core, active when a debug bus
    -- access is in progress.
    stallOut                    : out std_logic_vector(CFG.numLaneGroupsLog2-1 downto 0);
    
    ---------------------------------------------------------------------------
    -- Core bus interfaces
    ---------------------------------------------------------------------------
    -- Control register address from memory unit, shared between read and write
    -- command. Only bit 6..0 are used.
    dmsw2creg_addr              : out rvex_address_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Control register write command from memory unit.
    dmsw2creg_writeEnable       : out std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    dmsw2creg_writeMask         : out rvex_mask_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    dmsw2creg_writeData         : out rvex_data_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Control register read command and result from and to memory unit.
    dmsw2creg_readEnable        : out std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    creg2dmsw_readData          : in  rvex_data_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    ---------------------------------------------------------------------------
    -- Debug bus interface
    ---------------------------------------------------------------------------
    -- Control register address from debug bus, shared between read and write
    -- command. Only bit 7..0 are used.
    dbg2creg_addr                 : in  rvex_address_type;
    
    -- Control register write command from debug bus.
    dbg2creg_writeEnable          : in  std_logic;
    dbg2creg_writeMask            : in  rvex_mask_type;
    dbg2creg_writeData            : in  rvex_data_type;
    
    -- Control register read command and result from and to debug bus.
    dbg2creg_readEnable           : in  std_logic;
    creg2dbg_readData             : out rvex_data_type;
    
    ---------------------------------------------------------------------------
    -- General purpose register file interface
    ---------------------------------------------------------------------------
    -- This should be connected to one of the general purpose register file
    -- read and write ports when creg2gpreg_claim is high. This unit will
    -- ensure that everything is stalled when this signal is asserted. The
    -- general purpose register file should ensure though that the read result
    -- going to processor is properly delayed while claim is high in order to
    -- prevent errors while the port is being claimed in the middle of a
    -- transfer.
    
    -- When high, connect the bus to the general purpose register file.
    creg2gpreg_claim            : out std_logic;
    
    -- Register address and context.
    creg2gpreg_addr             : out rvex_gpRegAddr_type;
    creg2gpreg_ctxt             : out std_logic_vector(CFG.numContextsLog2-1 downto 0);
    
    -- Write command.
    creg2gpreg_writeEnable      : out std_logic;
    creg2gpreg_writeData        : out rvex_data_type;
    
    -- Read data returned one cycle after the claim.
    gpreg2creg_readData         : in  rvex_data_type;
    
    ---------------------------------------------------------------------------
    -- Global register logic interface
    ---------------------------------------------------------------------------
    -- Interface for the global registers.
    gbreg2creg                  : in  gbreg2creg_type;
    creg2gbreg                  : out creg2gbreg_type;
    
    -- Context selection for the debug bus.
    gbreg2creg_context          : in  std_logic_vector(CFG.numContextsLog2-1 downto 0);
    
    -- Bank selection bit for general purpose register access from the debug
    -- bus.
    gbreg2creg_gpregBank        : in  std_logic;
    
    ---------------------------------------------------------------------------
    -- Context register logic interface
    ---------------------------------------------------------------------------
    -- Interface for the local registers.
    cxreg2creg                  : in  cxreg2creg_array(2**CFG.numContextsLog2-1 downto 0);
    creg2cxreg                  : out creg2cxreg_array(2**CFG.numContextsLog2-1 downto 0)
    
  );
end rvex_ctrlRegs;

--=============================================================================
architecture Behavioral of rvex_ctrlRegs is
--=============================================================================
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  assert CTRL_REG_TOTAL_WORDS = 64 and CTRL_REG_SIZE_BLOG2 = 7
    report "Size of the control register file is hardcoded to 64 words in the "
         & "control register code, but configuration specifies otherwise."
    severity failure;
  
  assert CTRL_REG_GLOB_WORDS <= CTRL_REG_TOTAL_WORDS
    report "Cannot have more words in the global portion of the control "
         & "registers than there are in the whole file."
    severity failure;
  
end Behavioral;

