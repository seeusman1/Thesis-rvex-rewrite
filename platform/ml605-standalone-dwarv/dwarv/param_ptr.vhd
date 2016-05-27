--
-- Delft University of Technology
-- Computer Engineering Laboratory
--

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;

--=============================================================================
-- This entity implements the memory-mapped storage for a pointer input
-- parameter.
-------------------------------------------------------------------------------
entity param_ptr is
--=============================================================================
  generic (
    
    -- Size of the memory, specified as log2(byte_count).
    DEPTH_LOG2B                 : natural := 11;
    
    -- Accelerator data access port width in log2(byte_count).
    ACC_WIDTH_LOG2B             : natural := 2;
    
    -- Bus data access port width in log2(byte_count).
    BUS_WIDTH_LOG2B             : natural := 2
    
  );
  port (
    
    -- Active high asynchronous reset input.
    reset                       : in  std_logic;
    
    -- Clock input, registers are rising edge triggered.
    clk                         : in  std_logic;
    
    -- Accelerator interface. Addr to data_r delay is one cycle.
	  acc_addr                    : in  std_logic_vector(DEPTH_LOG2B-1 downto ACC_WIDTH_LOG2B) := (others => '0');
	  acc_data_r                  : out std_logic_vector(8*2**ACC_WIDTH_LOG2B-1 downto 0);
	  acc_data_w                  : in  std_logic_vector(8*2**ACC_WIDTH_LOG2B-1 downto 0) := (others => '0');
	  acc_data_we                 : in  std_logic_vector(2**ACC_WIDTH_LOG2B-1 downto 0) := (others => '0');
    
    -- Bus interface.
    bus_ena                     : in  std_logic := '0';
    bus_addr                    : in  std_logic_vector(DEPTH_LOG2B-1 downto BUS_WIDTH_LOG2B) := (others => '0');
	  bus_data_r                  : out std_logic_vector(8*2**BUS_WIDTH_LOG2B-1 downto 0);
	  bus_data_w                  : in  std_logic_vector(8*2**BUS_WIDTH_LOG2B-1 downto 0) := (others => '0');
	  bus_data_we                 : in  std_logic_vector(2**BUS_WIDTH_LOG2B-1 downto 0) := (others => '0')
    
  );
end param_ptr;

--=============================================================================
architecture Behavioral of param_ptr is
--=============================================================================
  
  -- Computes the maximum of the inputs.
  function max(a, b: integer) return integer is
  begin
    if a > b then
      return a;
    else
      return b;
    end if;
  end;
  
  -- Access size of the block RAM in log2(byte_count).
  constant BRAM_WIDTH_LOG2B     : integer := max(ACC_WIDTH_LOG2B, BUS_WIDTH_LOG2B);
  
  -- RAM array types.
  subtype ram_line_type is std_logic_vector(8*2**BRAM_WIDTH_LOG2B-1 downto 0);
  type ram_line_array is array (natural range <>) of ram_line_type;
  subtype ram_type is ram_line_array(0 to 2**(DEPTH_LOG2B-BRAM_WIDTH_LOG2B)-1);
  
  -- Current contents of the RAM. We need to use a shared variable to allow XST
  -- to recognize a RAM with two write ports.
  shared variable ram           : ram_type := (others => (others => '0'));
  
  -- Block RAM interface signals.
  signal acc_data_r_mem         : std_logic_vector(8*2**BRAM_WIDTH_LOG2B-1 downto 0);
  signal acc_data_w_mem         : std_logic_vector(8*2**BRAM_WIDTH_LOG2B-1 downto 0);
  signal acc_data_we_mem        : std_logic_vector(2**BRAM_WIDTH_LOG2B-1 downto 0);
  signal bus_data_r_mem         : std_logic_vector(8*2**BRAM_WIDTH_LOG2B-1 downto 0);
  signal bus_data_w_mem         : std_logic_vector(8*2**BRAM_WIDTH_LOG2B-1 downto 0);
  signal bus_data_we_mem        : std_logic_vector(2**BRAM_WIDTH_LOG2B-1 downto 0);
  
  -- Bus enable signal delayed by one cycle, to align it with the read data.
  signal bus_ena_r              : std_logic;
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- Block RAM
  -----------------------------------------------------------------------------
  -- Generate the accelerator access port.
  port_A_proc: process (clk) is
    variable addr : natural range 0 to 2**(DEPTH_LOG2B-BRAM_WIDTH_LOG2B)-1;
  begin
    if rising_edge(clk) then
      
      -- Decode address.
      addr := to_integer(unsigned(acc_addr(DEPTH_LOG2B-1 downto BRAM_WIDTH_LOG2B)));
      
      -- Handle writes.
      for b in 0 to 2**BRAM_WIDTH_LOG2B-1 loop
        if acc_data_we_mem(b) = '1' then
          ram(addr)(b*8+7 downto b*8) := acc_data_w_mem(b*8+7 downto b*8);
        end if;
      end loop;
      
      -- Handle reads.
      acc_data_r_mem <= ram(addr);
      
    end if;
  end process;
  
  -- Generate the bus access port.
  port_B_proc: process (clk) is
    variable addr : natural range 0 to 2**(DEPTH_LOG2B-BRAM_WIDTH_LOG2B)-1;
  begin
    if rising_edge(clk) then
      
      -- Decode address.
      addr := to_integer(unsigned(bus_addr(DEPTH_LOG2B-1 downto BRAM_WIDTH_LOG2B)));
      
      -- Handle writes.
      for b in 0 to 2**BRAM_WIDTH_LOG2B-1 loop
        if bus_data_we_mem(b) = '1' then
          ram(addr)(b*8+7 downto b*8) := bus_data_w_mem(b*8+7 downto b*8);
        end if;
      end loop;
      
      -- Handle reads.
      bus_data_r_mem <= ram(addr);
      
    end if;
  end process;
  
  -----------------------------------------------------------------------------
  -- Interfacing logic
  -----------------------------------------------------------------------------
  -- Handle the accelerator access port. We don't need to do any conversion if
  -- it has the same port width as the BRAM, but if it doesn't, we need the
  -- param_ptr_accessport entity to do the conversion.
  acc_direct: if BRAM_WIDTH_LOG2B = ACC_WIDTH_LOG2B generate
  begin
    acc_data_r      <= acc_data_r_mem;
    acc_data_w_mem  <= acc_data_w;
    acc_data_we_mem <= acc_data_we;
  end generate;
  acc_convert: if BRAM_WIDTH_LOG2B > ACC_WIDTH_LOG2B generate
  begin
    acc_converter: entity work.param_ptr_accessport
      generic map (
        DEPTH_LOG2B             => DEPTH_LOG2B,
        EXT_WIDTH_LOG2B         => ACC_WIDTH_LOG2B,
        BRAM_WIDTH_LOG2B        => BRAM_WIDTH_LOG2B
      )
      port map (
        reset                   => reset,
        clk                     => clk,
        ext_addr                => acc_addr,
        ext_data_r              => acc_data_r,
        ext_data_w              => acc_data_w,
        ext_data_we             => acc_data_we,
        bram_data_r             => acc_data_r_mem,
        bram_data_w             => acc_data_w_mem,
        bram_data_we            => acc_data_we_mem
      );
  end generate;
  
  -- Same thing as above, but for the bus side. This also has an enable signal.
  -- When enable is low, the read data for the next cycle must be 0, and writes
  -- should be ignored.
  bus_direct: if BRAM_WIDTH_LOG2B = BUS_WIDTH_LOG2B generate
  begin
    bus_data_r      <= bus_data_r_mem when bus_ena_r = '1' else (others => '0');
    bus_data_w_mem  <= bus_data_w;
    bus_data_we_mem <= bus_data_we when bus_ena = '1' else (others => '0');
  end generate;
  bus_convert: if BRAM_WIDTH_LOG2B > BUS_WIDTH_LOG2B generate
	  signal bus_data_r_int       : std_logic_vector(8*2**BUS_WIDTH_LOG2B-1 downto 0);
	  signal bus_data_we_int      : std_logic_vector(2**BUS_WIDTH_LOG2B-1 downto 0);
  begin
    bus_converter: entity work.param_ptr_accessport
      generic map (
        DEPTH_LOG2B             => DEPTH_LOG2B,
        EXT_WIDTH_LOG2B         => BUS_WIDTH_LOG2B,
        BRAM_WIDTH_LOG2B        => BRAM_WIDTH_LOG2B
      )
      port map (
        reset                   => reset,
        clk                     => clk,
        ext_addr                => bus_addr,
        ext_data_r              => bus_data_r_int,
        ext_data_w              => bus_data_w,
        ext_data_we             => bus_data_we_int,
        bram_data_r             => bus_data_r_mem,
        bram_data_w             => bus_data_w_mem,
        bram_data_we            => bus_data_we_mem
      );
    
    bus_data_we_int <= bus_data_we when bus_ena = '1' else (others => '0');
    bus_data_r <= bus_data_r_int when bus_ena_r = '1' else (others => '0');
  end generate;
  
  -- Delay the bus enable signal by one cycle to align it with the read data.
  bus_ena_reg: process (reset, clk) is
  begin
    if reset = '1' then
      bus_ena_r <= '0';
    elsif rising_edge(clk) then
      bus_ena_r <= bus_ena;
    end if;
  end process;
  
end Behavioral;

