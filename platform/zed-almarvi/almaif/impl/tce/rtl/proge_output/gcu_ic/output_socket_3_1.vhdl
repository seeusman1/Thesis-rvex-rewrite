library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use work.tce_util.all;

entity tta0_output_socket_cons_3_1 is
  generic (
    BUSW_0 : integer := 32;
    BUSW_1 : integer := 32;
    BUSW_2 : integer := 32;
    DATAW_0 : integer := 32);
  port (
    databus0_alt : out std_logic_vector(BUSW_0-1 downto 0);
    databus1_alt : out std_logic_vector(BUSW_1-1 downto 0);
    databus2_alt : out std_logic_vector(BUSW_2-1 downto 0);
    data0 : in std_logic_vector(DATAW_0-1 downto 0);
    databus_cntrl : in std_logic_vector(2 downto 0));
end tta0_output_socket_cons_3_1;


architecture output_socket_andor of tta0_output_socket_cons_3_1 is

  signal databus_0_temp : std_logic_vector(DATAW_0-1 downto 0);
  signal databus_1_temp : std_logic_vector(DATAW_0-1 downto 0);
  signal databus_2_temp : std_logic_vector(DATAW_0-1 downto 0);
  signal data : std_logic_vector(DATAW_0-1 downto 0);

begin -- output_socket_andor

  data <= data0;

  internal_signal : process(data, databus_cntrl)
  begin -- process internal_signal
    databus_0_temp <= data and tce_sxt(databus_cntrl(0 downto 0), data'length);
    databus_1_temp <= data and tce_sxt(databus_cntrl(1 downto 1), data'length);
    databus_2_temp <= data and tce_sxt(databus_cntrl(2 downto 2), data'length);
  end process internal_signal;

  output : process (databus_0_temp,databus_1_temp,databus_2_temp)
  begin -- process output
    databus0_alt <= tce_ext(databus_0_temp, databus0_alt'length);
    databus1_alt <= tce_ext(databus_1_temp, databus1_alt'length);
    databus2_alt <= tce_ext(databus_2_temp, databus2_alt'length);
  end process output;

end output_socket_andor;
