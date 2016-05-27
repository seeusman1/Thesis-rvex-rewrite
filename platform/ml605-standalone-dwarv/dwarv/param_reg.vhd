--
-- Delft University of Technology
-- Computer Engineering Laboratory
--

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;

--=============================================================================
-- This entity implements the memory-mapped storage for a scalar input
-- parameter or the return value.
-------------------------------------------------------------------------------
entity param_reg is
--=============================================================================
  generic (
    
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
    
    -- Accelerator interface.
	  acc_data_r                  : out std_logic_vector(8*2**ACC_WIDTH_LOG2B-1 downto 0);
	  acc_data_w                  : in  std_logic_vector(8*2**ACC_WIDTH_LOG2B-1 downto 0) := (others => '0');
	  acc_data_we                 : in  std_logic_vector(2**ACC_WIDTH_LOG2B-1 downto 0) := (others => '0');
    
    -- Bus interface.
    bus_ena                     : in  std_logic := '0';
    bus_addr                    : in  std_logic_vector(ACC_WIDTH_LOG2B-1 downto 0) := (others => '0');
	  bus_data_r                  : out std_logic_vector(8*2**BUS_WIDTH_LOG2B-1 downto 0);
	  bus_data_w                  : in  std_logic_vector(8*2**BUS_WIDTH_LOG2B-1 downto 0) := (others => '0');
	  bus_data_we                 : in  std_logic_vector(2**BUS_WIDTH_LOG2B-1 downto 0) := (others => '0')
    
  );
end param_reg;

--=============================================================================
architecture Behavioral of param_reg is
--=============================================================================
  
  -- Data register.
  signal data                   : std_logic_vector(8*2**ACC_WIDTH_LOG2B-1 downto 0);
  
  -- Bus control signals.
  signal bus_data_w_reg         : std_logic_vector(8*2**ACC_WIDTH_LOG2B-1 downto 0);
  signal bus_data_we_reg        : std_logic_vector(2**ACC_WIDTH_LOG2B-1 downto 0);
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- Data register
  -----------------------------------------------------------------------------
  reg: process (reset, clk) is
  begin
    if reset = '1' then
      data <= (others => '0');
    elsif rising_edge(clk) then
      for b in 2**ACC_WIDTH_LOG2B-1 downto 0 loop
        if acc_data_we(b) = '1' then
          data(b*8+7 downto b*8) <= acc_data_w(b*8+7 downto b*8);
        elsif bus_data_we_reg(b) = '1' then
          data(b*8+7 downto b*8) <= bus_data_w_reg(b*8+7 downto b*8);
        end if;
      end loop;
    end if;
  end process;
  
  acc_data_r <= data;
  
  -----------------------------------------------------------------------------
  -- Handle bus accesses
  -----------------------------------------------------------------------------
  -- Handle the read path.
  read_path: process (reset, clk) is
    variable i                  : natural;
  begin
    if reset = '1' then
      bus_data_r <= (others => '0');
    elsif rising_edge(clk) then
      if bus_ena = '0' then
        
        -- Disabled: output zero.
        bus_data_r <= (others => '0');
        
      elsif ACC_WIDTH_LOG2B <= BUS_WIDTH_LOG2B then
        
        -- Register smaller or equal then the bus width: the data should be
        -- aligned to the MSBs so the data is at the expected byte/halfword
        -- address in big endian.
        bus_data_r <= (others => '0');
        bus_data_r(bus_data_r'length-1 downto
                   bus_data_r'length-8*2**ACC_WIDTH_LOG2B) <= data;
        
      else
        
        -- Select the desired part of the register.
        i := to_integer(unsigned(bus_addr(ACC_WIDTH_LOG2B-1 downto BUS_WIDTH_LOG2B)));
        bus_data_r <= data(bus_data_r'length*i + bus_data_r'length-1 downto
                           bus_data_r'length*i);
        
      end if;
    end if;
  end process;
  
  -- Handle the write enable path.
  write_enable_path: process (bus_ena, bus_addr, bus_data_we) is
    variable mask               : std_logic_vector(2**BUS_WIDTH_LOG2B-1 downto 0);
  begin
    if bus_ena = '0' then
      
      -- Disabled: don't write anything.
      bus_data_we_reg <= (others => '0');
      
    elsif ACC_WIDTH_LOG2B <= BUS_WIDTH_LOG2B then
      
      -- Register smaller or equal then the bus width: the data should be
      -- aligned to the MSBs so the data is at the expected byte/halfword
      -- address in big endian.
      bus_data_we_reg <= bus_data_we(bus_data_we'length-1 downto
                                     bus_data_we'length-2**ACC_WIDTH_LOG2B);
    else
      
      -- Register size is an integer multiple of the bus width.
      for i in 0 to 2**(ACC_WIDTH_LOG2B - BUS_WIDTH_LOG2B)-1 loop
        if i = to_integer(unsigned(bus_addr(ACC_WIDTH_LOG2B-1 downto BUS_WIDTH_LOG2B))) then
          mask := bus_data_we;
        else
          mask := (others => '0');
        end if;
        bus_data_we_reg(bus_data_we'length*i + bus_data_we'length-1 downto
                        bus_data_we'length*i) <= mask;
      end loop;
      
    end if;
  end process;
  
  -- Handle write data.
  write_data_path: process (bus_data_w) is
  begin
    if ACC_WIDTH_LOG2B <= BUS_WIDTH_LOG2B then
      
      -- Register smaller or equal then the bus width: the data should be
      -- aligned to the MSBs so the data is at the expected byte/halfword
      -- address in big endian.
      bus_data_w_reg <= bus_data_w(bus_data_w'length-1 downto
                                   bus_data_w'length-8*2**ACC_WIDTH_LOG2B);
    else
      
      -- Register size is an integer multiple of the bus width: just duplicate
      -- the bus data.
      for i in 0 to 2**(ACC_WIDTH_LOG2B - BUS_WIDTH_LOG2B)-1 loop
        bus_data_w_reg(bus_data_w'length*i + bus_data_w'length-1 downto
                       bus_data_w'length*i) <= bus_data_w;
      end loop;
      
    end if;
  end process;
  
end Behavioral;

