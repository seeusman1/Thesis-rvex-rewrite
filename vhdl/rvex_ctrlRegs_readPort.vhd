-- Insert license here

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.rvex_pkg.all;
use work.rvex_intIface_pkg.all;

--=============================================================================
-- This instantiates an additional synchronous read port for an
-- rvex_ctrlRegs_bank instance.
-------------------------------------------------------------------------------
entity rvex_ctrlRegs_readPort is
--=============================================================================
  generic (
    
    ---------------------------------------------------------------------------
    -- Configuration
    ---------------------------------------------------------------------------
    -- Starting address for the registers.
    OFFSET                      : natural;
    
    -- Number of words.
    NUM_WORDS                   : natural
    
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
    
    ---------------------------------------------------------------------------
    -- Register interface
    ---------------------------------------------------------------------------
    -- Connect this to the creg2logic output of the rvex_ctrlRegs_bank
    -- instance.
    creg2logic                  : in  creg2logic_array(OFFSET to OFFSET + NUM_WORDS - 1);
    
    ---------------------------------------------------------------------------
    -- Read port
    ---------------------------------------------------------------------------
    -- Address for the request.
    addr                        : in  rvex_address_type;
    
    -- Active high read enable signal.
    readEnable                  : in  std_logic;
    
    -- Read data. Will be set to 'Z' when block is not addressed.
    readData                    : out rvex_data_type
    
  );
end rvex_ctrlRegs_readPort;

--=============================================================================
architecture Behavioral of rvex_ctrlRegs_readPort is
--=============================================================================
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -- Process bus reads.
  bus_reads: process (clk) is
    variable a: integer;
  begin
    if rising_edge(clk) then
      if reset = '1' then
        readData <= (others => 'Z');
      elsif clkEn = '1' then
        if readEnable = '1' then
          a := to_integer(unsigned(addr(31 downto 2)));
          if a >= OFFSET and a < OFFSET + NUM_WORDS then
            readData <= creg2logic(a).readData;
          else
            readData <= (others => 'Z');
          end if;
        else
          readData <= (others => 'Z');
        end if;
      end if;
    end if;
  end process;
  
end Behavioral;

