--
-- Delft University of Technology
-- Computer Engineering Laboratory
--

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;

--=============================================================================
-- This entity handles translates the size of a block RAM access port to
-- whichever size is required. This is unfortunately necessary when inferring
-- the block RAMs; it's not possible to just infer the desired access port
-- aspect ratios out of the box.
-------------------------------------------------------------------------------
entity param_ptr_accessport is
--=============================================================================
  generic (
    
    -- Size of the memory, specified as log2(byte_count).
    DEPTH_LOG2B                 : natural := 11;
    
    -- Desired access port width, specified as log2(byte_count).
    EXT_WIDTH_LOG2B             : natural := 2;
    
    -- Block RAM access port width, specified as log2(byte_count). Must be
    -- greater than EXT_WIDTH_LOG2B.
    BRAM_WIDTH_LOG2B            : natural := 3
    
  );
  port (
    
    -- Active high asynchronous reset input.
    reset                       : in  std_logic;
    
    -- Clock input, registers are rising edge triggered.
    clk                         : in  std_logic;
    
    -- External interface.
	  ext_addr                    : in  std_logic_vector(DEPTH_LOG2B-1 downto EXT_WIDTH_LOG2B) := (others => '0');
	  ext_data_r                  : out std_logic_vector(8*2**EXT_WIDTH_LOG2B-1 downto 0);
	  ext_data_w                  : in  std_logic_vector(8*2**EXT_WIDTH_LOG2B-1 downto 0) := (others => '0');
	  ext_data_we                 : in  std_logic_vector(2**EXT_WIDTH_LOG2B-1 downto 0) := (others => '0');
    
    -- Block RAM interface.
	  bram_data_r                 : in  std_logic_vector(8*2**BRAM_WIDTH_LOG2B-1 downto 0);
	  bram_data_w                 : out std_logic_vector(8*2**BRAM_WIDTH_LOG2B-1 downto 0) := (others => '0');
	  bram_data_we                : out std_logic_vector(2**BRAM_WIDTH_LOG2B-1 downto 0) := (others => '0')
    
  );
end param_ptr_accessport;

--=============================================================================
architecture Behavioral of param_ptr_accessport is
--=============================================================================
  
  -- Relevant part of the address needed for the read data mux, delayed by one
  -- cycle so it's aligned to the read data.
  signal sel : std_logic_vector(BRAM_WIDTH_LOG2B-EXT_WIDTH_LOG2B-1 downto 0);
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -- Store the relevant LSBs of the address for the next cycle to sync it
  -- with the return data.
  sel_reg: process (reset, clk) is
  begin
    if reset = '1' then
      sel <= (others => '0');
    elsif rising_edge(clk) then
      sel <= ext_addr(BRAM_WIDTH_LOG2B-1 downto EXT_WIDTH_LOG2B);
    end if;
  end process;
  
  -- Multiplex the wider block RAM read data port to the desired read data.
  read_path: process (bram_data_r, sel) is
    variable s  : integer;
  begin
    s := to_integer(unsigned(not sel)) * ext_data_r'length;
    ext_data_r <= bram_data_r(s+ext_data_r'length-1 downto s);
  end process;
  
  -- Handle the write datapath.
  write_path: for i in 0 to 2**(BRAM_WIDTH_LOG2B-EXT_WIDTH_LOG2B)-1 generate
  begin
    bram_data_w((i+1)*ext_data_w'length-1 downto i*ext_data_w'length) <= ext_data_w;
    bram_data_we((i+1)*ext_data_we'length-1 downto i*ext_data_we'length) <= ext_data_we
      when to_integer(unsigned(not sel)) = i else (others => '0');
  end generate;
  
end Behavioral;

