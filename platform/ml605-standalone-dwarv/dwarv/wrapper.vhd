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
entity wrapper is
--=============================================================================
  generic (
    
    -- Bus data access port width in log2(byte_count).
    BUS_WIDTH_LOG2B             : natural := 2;
    
    -- Address space in log2(byte_count).
    ADDR_SPACE_LOG2B            : natural := 32
    
  );
  port (
    
    -- Active high asynchronous reset input.
    RST                         : in  std_logic;
    
    -- Clock input, registers are rising edge triggered.
    CLK                         : in  std_logic;
    
    -- Bus interface.
    ADDR                        : in  std_logic_vector(ADDR_SPACE_LOG2B-1 downto BUS_WIDTH_LOG2B);
	  DATA_R                      : out std_logic_vector(8*2**BUS_WIDTH_LOG2B-1 downto 0);
	  DATA_W                      : in  std_logic_vector(8*2**BUS_WIDTH_LOG2B-1 downto 0);
	  DATA_WE                     : in  std_logic_vector(2**BUS_WIDTH_LOG2B-1 downto 0);
    
    -- Interrupt output. This is asserted high for one clock cycle when the
    -- accelerator signals completion.
    IRQ                         : out std_logic
    
  );
end wrapper;

--=============================================================================
architecture Behavioral of wrapper is
--=============================================================================
  
  -- Bus byte address.
  signal ADDR_BYTE              : std_logic_vector(ADDR_SPACE_LOG2B-1 downto 0);
  
  -- Control signals.
	signal START_OP               : std_logic;
	signal END_OP                 : std_logic;
  signal ENA_CTRL               : std_logic;
  signal BUS_R_CTRL             : std_logic_vector(8*2**BUS_WIDTH_LOG2B-1 downto 0);
  
  -- Return value.
  signal return_DATA_W          : std_logic_vector(31 downto 0);
  signal return_DATA_WE         : std_logic_vector(3 downto 0);
  signal return_ENA             : std_logic;
  signal return_BUS_R           : std_logic_vector(8*2**BUS_WIDTH_LOG2B-1 downto 0);
  
  -- Parameter a.
	signal a_ADDR                 : std_logic_vector(9 downto 0);
	signal a_DATA_R               : std_logic_vector(31 downto 0);
	signal a_DATA_W               : std_logic_vector(31 downto 0);
	signal a_DATA_WE              : std_logic_vector(3 downto 0);
  signal a_ENA                  : std_logic;
  signal a_BUS_R                : std_logic_vector(8*2**BUS_WIDTH_LOG2B-1 downto 0);
  
  -- Parameter b.
  signal b_DATA_R               : std_logic_vector(31 downto 0);
  signal b_ENA                  : std_logic;
  signal b_BUS_R                : std_logic_vector(8*2**BUS_WIDTH_LOG2B-1 downto 0);
  
  -- Parameter c.
  signal c_DATA_R               : std_logic_vector(7 downto 0);
  signal c_ENA                  : std_logic;
  signal c_BUS_R                : std_logic_vector(8*2**BUS_WIDTH_LOG2B-1 downto 0);
  
  -- Parameter d.
  signal d_ADDR                 : std_logic_vector(9 downto 0);
  signal d_DATA_R               : std_logic_vector(15 downto 0);
  signal d_DATA_W               : std_logic_vector(15 downto 0);
  signal d_DATA_WE              : std_logic_vector(1 downto 0);
  signal d_ENA                  : std_logic;
  signal d_BUS_R                : std_logic_vector(8*2**BUS_WIDTH_LOG2B-1 downto 0);
  
  -- Parameter e.
  signal e_ADDR                 : std_logic_vector(9 downto 0);
  signal e_DATA_R               : std_logic_vector(7 downto 0);
  signal e_DATA_W               : std_logic_vector(7 downto 0);
  signal e_DATA_WE              : std_logic_vector(0 downto 0);
  signal e_ENA                  : std_logic;
  signal e_BUS_R                : std_logic_vector(8*2**BUS_WIDTH_LOG2B-1 downto 0);
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- Instantiate accelerator
  -----------------------------------------------------------------------------
  accelerator: entity work.CCU
    port map (
	    RST                       => RST,
	    CLK                       => CLK,
	    START_OP                  => START_OP,
	    END_OP                    => END_OP,
	    return_DATA_W             => return_DATA_W,
	    return_DATA_WE            => return_DATA_WE,
	    a_ADDR                    => a_ADDR,
	    a_DATA_R                  => a_DATA_R,
	    a_DATA_W                  => a_DATA_W,
	    a_DATA_WE                 => a_DATA_WE,
	    b_DATA_R                  => b_DATA_R,
	    c_DATA_R                  => c_DATA_R,
	    d_ADDR                    => d_ADDR,
	    d_DATA_R                  => d_DATA_R,
	    d_DATA_W                  => d_DATA_W,
	    d_DATA_WE                 => d_DATA_WE,
	    e_ADDR                    => e_ADDR,
	    e_DATA_R                  => e_DATA_R,
	    e_DATA_W                  => e_DATA_W,
	    e_DATA_WE                 => e_DATA_WE
    );
  
  -----------------------------------------------------------------------------
  -- Get a byte address signal regardless of bus width
  -----------------------------------------------------------------------------
  addr_proc: process (ADDR) is
  begin
    ADDR_BYTE <= (others => '0');
    ADDR_BYTE(ADDR'range) <= ADDR;
  end process;
  
  -----------------------------------------------------------------------------
  -- Control
  -----------------------------------------------------------------------------
  -- Implement the control register. This is a byte register. Writing 1 or 3
  -- starts the accelerator; 1 means interrupt disabled and 3 means enabled.
  -- Reading 0 means not started, reading 1 means started without interrupts,
  -- reading 2 means interrupt pending, reading 3 means started with
  -- interrupts. Write 0 to remove the interrupt pending state.
  controlreg: block is
    signal RUNNING              : std_logic;
    signal IRQ_ENA              : std_logic;
  begin
    
    controlreg_proc: process (RST, CLK) is
    begin
      if RST = '1' then
        RUNNING <= '0';
        IRQ_ENA <= '0';
      elsif rising_edge(CLK) then
        
        -- Clear the running bit when the accelerator signals completion.
        if END_OP = '1' then
          RUNNING <= '0';
        end if;
        
        -- Handle register writes.
        START_OP <= '0';
        if ENA_CTRL = '1' and DATA_WE(DATA_WE'HIGH) = '1' then
          
          -- If a 1 is written to bit 0, start the accelerator.
          if DATA_W(DATA_W'LENGTH-8) = '1' then
            RUNNING <= '1';
            START_OP <= '1';
          end if;
          
          -- Save the value written to bit 1 as the interrupt enable flag.
          IRQ_ENA <= DATA_W(DATA_W'LENGTH-7);
          
        end if;
        
        -- Handle register reads.
        BUS_R_CTRL <= (others => '0');
        if ENA_CTRL = '1' then
          BUS_R_CTRL(BUS_R_CTRL'LENGTH-8) <= RUNNING;
          BUS_R_CTRL(BUS_R_CTRL'LENGTH-7) <= IRQ_ENA;
        end if;
        
      end if;
    end process;
    
    -- The end_op signal already conforms to the irq signal specs. Mask it with
    -- the interrupt enable bit in the control register.
    IRQ <= END_OP and IRQ_ENA;
    
  end block;

  -----------------------------------------------------------------------------
  -- Return value
  -----------------------------------------------------------------------------
  return_reg: entity work.param_reg
    generic map (
      ACC_WIDTH_LOG2B           => 2, -- storage type: 0=byte, 1=short, 2=int etc.
      BUS_WIDTH_LOG2B           => BUS_WIDTH_LOG2B
    )
    port map (
      reset                     => RST,
      clk                       => CLK,
      acc_data_w                => return_DATA_W,
      acc_data_we               => return_DATA_WE,
      bus_ena                   => return_ENA,
      bus_addr                  => ADDR_BYTE(1 downto 0), -- high index is ACC_WIDTH_LOG2B-1
      bus_data_r                => return_BUS_R,
      bus_data_w                => DATA_W,
      bus_data_we               => DATA_WE
    );
  
  -----------------------------------------------------------------------------
  -- Parameter a
  -----------------------------------------------------------------------------
  a_regs: entity work.param_ptr
    generic map (
      DEPTH_LOG2B               => 12, -- number of bytes in the block RAM
      ACC_WIDTH_LOG2B           => 2,  -- access width: 0=byte, 1=short, 2=int etc.
      BUS_WIDTH_LOG2B           => BUS_WIDTH_LOG2B
    )
    port map (
      reset                     => RST,
      clk                       => CLK,
      acc_addr                  => a_ADDR,
      acc_data_r                => a_DATA_R,
      acc_data_w                => a_DATA_W,
      acc_data_we               => a_DATA_WE,
      bus_ena                   => a_ENA,
      bus_addr                  => ADDR(11 downto BUS_WIDTH_LOG2B), -- high index is DEPTH_LOG2B-1
      bus_data_r                => a_BUS_R,
      bus_data_w                => DATA_W,
      bus_data_we               => DATA_WE
    );
  
  -----------------------------------------------------------------------------
  -- Parameter b
  -----------------------------------------------------------------------------
  b_reg: entity work.param_reg
    generic map (
      ACC_WIDTH_LOG2B           => 2, -- storage type: 0=byte, 1=short, 2=int etc.
      BUS_WIDTH_LOG2B           => BUS_WIDTH_LOG2B
    )
    port map (
      reset                     => RST,
      clk                       => CLK,
      acc_data_r                => b_DATA_R,
      bus_ena                   => b_ENA,
      bus_addr                  => ADDR_BYTE(1 downto 0), -- high index is ACC_WIDTH_LOG2B-1
      bus_data_r                => b_BUS_R,
      bus_data_w                => DATA_W,
      bus_data_we               => DATA_WE
    );
  
  -----------------------------------------------------------------------------
  -- Parameter c
  -----------------------------------------------------------------------------
  c_reg: entity work.param_reg
    generic map (
      ACC_WIDTH_LOG2B           => 0, -- storage type: 0=byte, 1=short, 2=int etc.
      BUS_WIDTH_LOG2B           => BUS_WIDTH_LOG2B
    )
    port map (
      reset                     => RST,
      clk                       => CLK,
      acc_data_r                => c_DATA_R,
      bus_ena                   => c_ENA,
      bus_addr                  => ADDR_BYTE(-1 downto 0), -- high index is ACC_WIDTH_LOG2B-1
      bus_data_r                => c_BUS_R,
      bus_data_w                => DATA_W,
      bus_data_we               => DATA_WE
    );
  
  -----------------------------------------------------------------------------
  -- Parameter d
  -----------------------------------------------------------------------------
  d_regs: entity work.param_ptr
    generic map (
      DEPTH_LOG2B               => 11, -- number of bytes in the block RAM
      ACC_WIDTH_LOG2B           => 1,  -- access width: 0=byte, 1=short, 2=int etc.
      BUS_WIDTH_LOG2B           => BUS_WIDTH_LOG2B
    )
    port map (
      reset                     => RST,
      clk                       => CLK,
      acc_addr                  => d_ADDR,
      acc_data_r                => d_DATA_R,
      acc_data_w                => d_DATA_W,
      acc_data_we               => d_DATA_WE,
      bus_ena                   => d_ENA,
      bus_addr                  => ADDR(10 downto BUS_WIDTH_LOG2B), -- high index is DEPTH_LOG2B-1
      bus_data_r                => d_BUS_R,
      bus_data_w                => DATA_W,
      bus_data_we               => DATA_WE
    );
  
  -----------------------------------------------------------------------------
  -- Parameter e
  -----------------------------------------------------------------------------
  e_regs: entity work.param_ptr
    generic map (
      DEPTH_LOG2B               => 10, -- number of bytes in the block RAM
      ACC_WIDTH_LOG2B           => 0,  -- access width: 0=byte, 1=short, 2=int etc.
      BUS_WIDTH_LOG2B           => BUS_WIDTH_LOG2B
    )
    port map (
      reset                     => RST,
      clk                       => CLK,
      acc_addr                  => e_ADDR,
      acc_data_r                => e_DATA_R,
      acc_data_w                => e_DATA_W,
      acc_data_we               => e_DATA_WE,
      bus_ena                   => e_ENA,
      bus_addr                  => ADDR(9 downto BUS_WIDTH_LOG2B), -- high index is DEPTH_LOG2B-1
      bus_data_r                => e_BUS_R,
      bus_data_w                => DATA_W,
      bus_data_we               => DATA_WE
    );
  
  -----------------------------------------------------------------------------
  -- Bus control logic
  -----------------------------------------------------------------------------
  -- Generate the enable signals.
  ENA_CTRL   <= '1' when ADDR(14 downto 12) = "000" else '0'; -- char control register at address 0x0000
  return_ENA <= '1' when ADDR(14 downto 12) = "001" else '0'; -- int return value at address 0x1000
  a_ENA      <= '1' when ADDR(14 downto 12) = "010" else '0'; -- int array parameter a at address 0x2000..0x3000 (1024 entries)
  b_ENA      <= '1' when ADDR(14 downto 12) = "011" else '0'; -- int parameter b at address 0x3000
  c_ENA      <= '1' when ADDR(14 downto 12) = "100" else '0'; -- char parameter c at address 0x4000
  d_ENA      <= '1' when ADDR(14 downto 12) = "101" else '0'; -- short array parameter d at address 0x5000..0x5800 (1024 entries)
  e_ENA      <= '1' when ADDR(14 downto 12) = "110" else '0'; -- char array parameter e at address 0x6000..0x6400 (1024 entries)
                                                              -- (all addresses are mirrored every 0x8000 byte block)
  
  -- Merge the read data. The register/BRAM entities are written such that they
  -- always read as zero when they are disabled, so we can merge the signals
  -- using an or gate.
  DATA_R <= BUS_R_CTRL
         or return_BUS_R
         or a_BUS_R
         or b_BUS_R
         or c_BUS_R
         or d_BUS_R
         or e_BUS_R;
  
end Behavioral;

