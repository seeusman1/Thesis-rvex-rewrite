library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use work.tce_util.all;

entity tta0_output_socket_cons_1_1 is
  generic (
    BUSW_0 : integer := 32;
    DATAW_0 : integer := 32);
  port (
    databus0_alt : out std_logic_vector(BUSW_0-1 downto 0);
    data0 : in std_logic_vector(DATAW_0-1 downto 0);
    databus_cntrl : in std_logic_vector(0 downto 0));
end tta0_output_socket_cons_1_1;


architecture output_socket_andor of tta0_output_socket_cons_1_1 is

  signal databus_0_temp : std_logic_vector(DATAW_0-1 downto 0);
  signal data : std_logic_vector(DATAW_0-1 downto 0);

begin -- output_socket_andor

  data <= data0;

  internal_signal : process(data, databus_cntrl)
  begin -- process internal_signal
    databus_0_temp <= data and tce_sxt(databus_cntrl(0 downto 0), data'length);
  end process internal_signal;

  output : process (databus_0_temp)
  begin -- process output
    databus0_alt <= tce_ext(databus_0_temp, databus0_alt'length);
  end process output;

end output_socket_andor;
