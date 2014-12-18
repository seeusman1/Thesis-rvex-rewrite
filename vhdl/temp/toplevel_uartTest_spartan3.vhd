library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library rvex;
use rvex.common_pkg.all;
use rvex.utils_pkg.all;
use rvex.simUtils_pkg.all;
use rvex.bus_pkg.all;

entity toplevel_uartTest_spartan3 is
  port (
    reset   : in  std_logic;
    clk     : in  std_logic;
    rx      : in  std_logic;
    tx      : out std_logic
  );
end toplevel_uartTest_spartan3;

architecture behavioral of toplevel_uartTest_spartan3 is
  signal uart2dbg_bus           : bus_mst2slv_type;
  signal dbg2uart_bus           : bus_slv2mst_type;
begin
  
  -- Instantiate unit under test.
  uut: entity rvex.periph_UART
    generic map (
      F_CLK                     => 50000000.0,
      F_BAUD                    => 115200.0
    )
    port map (
      
      -- System control.
      reset                     => reset,
      clk                       => clk,
      clkEn                     => '1',
      
      -- UART pins.
      rx                        => rx,
      tx                        => tx,
      
      -- Slave bus.
      bus2uart                  => BUS_MST2SLV_IDLE,
      uart2bus                  => open,
      irq                       => open,
      
      -- Debug interface.
      uart2dbg_bus              => uart2dbg_bus,
      dbg2uart_bus              => dbg2uart_bus
      
    );
  
  -- Instantiate a memory for the unit under test to access.
  memory_inst: entity work.bus_ramBlock_singlePort_spartan3
    generic map (
      DEPTH_LOG2B               => 10
    )
    port map (
      
      -- System control.
      reset                     => reset,
      clk                       => clk,
      clkEn                     => '1',
      
      -- Memory port.
      mst2mem_port              => uart2dbg_bus,
      mem2mst_port              => dbg2uart_bus
      
    );
  
end behavioral;

