library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use STD.textio.all;
use work.tta0_globals.all;
use work.tce_util.all;
use work.debugger_if.all;

entity tta0_interconn is

  port (
    clk : in std_logic;
    rstx : in std_logic;
    glock : in std_logic;
    socket_lsu_i1_data : out std_logic_vector(14 downto 0);
    socket_lsu_o1_data0 : in std_logic_vector(31 downto 0);
    socket_lsu_o1_bus_cntrl : in std_logic_vector(2 downto 0);
    socket_lsu_i2_data : out std_logic_vector(31 downto 0);
    socket_RF_i1_data : out std_logic_vector(31 downto 0);
    socket_RF_i1_bus_cntrl : in std_logic_vector(0 downto 0);
    socket_RF_o1_data0 : in std_logic_vector(31 downto 0);
    socket_RF_o1_bus_cntrl : in std_logic_vector(2 downto 0);
    socket_bool_i1_data : out std_logic_vector(0 downto 0);
    socket_bool_o1_data0 : in std_logic_vector(0 downto 0);
    socket_bool_o1_bus_cntrl : in std_logic_vector(2 downto 0);
    socket_gcu_i1_data : out std_logic_vector(IMEMADDRWIDTH-1 downto 0);
    socket_gcu_i2_data : out std_logic_vector(IMEMADDRWIDTH-1 downto 0);
    socket_gcu_o1_data0 : in std_logic_vector(IMEMADDRWIDTH-1 downto 0);
    socket_gcu_o1_bus_cntrl : in std_logic_vector(2 downto 0);
    socket_ALU_i1_data : out std_logic_vector(31 downto 0);
    socket_ALU_i2_data : out std_logic_vector(31 downto 0);
    socket_ALU_o1_data0 : in std_logic_vector(31 downto 0);
    socket_ALU_o1_bus_cntrl : in std_logic_vector(2 downto 0);
    socket_IO_i1_data : out std_logic_vector(7 downto 0);
    socket_IO_i1_bus_cntrl : in std_logic_vector(0 downto 0);
    socket_IMM_rd_data0 : in std_logic_vector(31 downto 0);
    socket_IMM_rd_bus_cntrl : in std_logic_vector(2 downto 0);
    socket_MUL_OUT_data0 : in std_logic_vector(31 downto 0);
    socket_MUL_OUT_bus_cntrl : in std_logic_vector(2 downto 0);
    socket_MUL_IN1_data : out std_logic_vector(31 downto 0);
    socket_MUL_IN2_data : out std_logic_vector(31 downto 0);
    socket_lsu_i2_1_data : out std_logic_vector(31 downto 0);
    socket_lsu_i1_1_data : out std_logic_vector(10 downto 0);
    socket_lsu_o1_1_data0 : in std_logic_vector(31 downto 0);
    socket_lsu_o1_1_bus_cntrl : in std_logic_vector(2 downto 0);
    simm_ALU_GCU_TRIG : in std_logic_vector(3 downto 0);
    simm_cntrl_ALU_GCU_TRIG : in std_logic_vector(0 downto 0);
    simm_PARAM : in std_logic_vector(4 downto 0);
    simm_cntrl_PARAM : in std_logic_vector(0 downto 0);
    simm_LSU_MUL_TRIG : in std_logic_vector(2 downto 0);
    simm_cntrl_LSU_MUL_TRIG : in std_logic_vector(0 downto 0);
    db_bustraces : out std_logic_vector(debreg_data_width_c*debreg_nof_bustraces_c-1 downto 0));

end tta0_interconn;

architecture comb_andor of tta0_interconn is

  signal databus_ALU_GCU_TRIG : std_logic_vector(31 downto 0);
  signal databus_ALU_GCU_TRIG_alt0 : std_logic_vector(31 downto 0);
  signal databus_ALU_GCU_TRIG_alt1 : std_logic_vector(31 downto 0);
  signal databus_ALU_GCU_TRIG_alt2 : std_logic_vector(31 downto 0);
  signal databus_ALU_GCU_TRIG_alt3 : std_logic_vector(31 downto 0);
  signal databus_ALU_GCU_TRIG_alt4 : std_logic_vector(0 downto 0);
  signal databus_ALU_GCU_TRIG_alt5 : std_logic_vector(31 downto 0);
  signal databus_ALU_GCU_TRIG_alt6 : std_logic_vector(31 downto 0);
  signal databus_ALU_GCU_TRIG_alt7 : std_logic_vector(31 downto 0);
  signal databus_ALU_GCU_TRIG_simm : std_logic_vector(3 downto 0);
  signal databus_PARAM : std_logic_vector(31 downto 0);
  signal databus_PARAM_alt0 : std_logic_vector(31 downto 0);
  signal databus_PARAM_alt1 : std_logic_vector(31 downto 0);
  signal databus_PARAM_alt2 : std_logic_vector(31 downto 0);
  signal databus_PARAM_alt3 : std_logic_vector(31 downto 0);
  signal databus_PARAM_alt4 : std_logic_vector(0 downto 0);
  signal databus_PARAM_alt5 : std_logic_vector(31 downto 0);
  signal databus_PARAM_alt6 : std_logic_vector(31 downto 0);
  signal databus_PARAM_alt7 : std_logic_vector(31 downto 0);
  signal databus_PARAM_simm : std_logic_vector(4 downto 0);
  signal databus_LSU_MUL_TRIG : std_logic_vector(31 downto 0);
  signal databus_LSU_MUL_TRIG_alt0 : std_logic_vector(31 downto 0);
  signal databus_LSU_MUL_TRIG_alt1 : std_logic_vector(31 downto 0);
  signal databus_LSU_MUL_TRIG_alt2 : std_logic_vector(31 downto 0);
  signal databus_LSU_MUL_TRIG_alt3 : std_logic_vector(31 downto 0);
  signal databus_LSU_MUL_TRIG_alt4 : std_logic_vector(0 downto 0);
  signal databus_LSU_MUL_TRIG_alt5 : std_logic_vector(31 downto 0);
  signal databus_LSU_MUL_TRIG_alt6 : std_logic_vector(31 downto 0);
  signal databus_LSU_MUL_TRIG_alt7 : std_logic_vector(31 downto 0);
  signal databus_LSU_MUL_TRIG_simm : std_logic_vector(2 downto 0);

  component tta0_input_socket_cons_1
    generic (
      BUSW_0 : integer := 32;
      DATAW : integer := 32);
    port (
      databus0 : in std_logic_vector(BUSW_0-1 downto 0);
      data : out std_logic_vector(DATAW-1 downto 0));
  end component;

  component tta0_output_socket_cons_3_1
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
  end component;

  component tta0_input_socket_cons_2
    generic (
      BUSW_0 : integer := 32;
      BUSW_1 : integer := 32;
      DATAW : integer := 32);
    port (
      databus0 : in std_logic_vector(BUSW_0-1 downto 0);
      databus1 : in std_logic_vector(BUSW_1-1 downto 0);
      data : out std_logic_vector(DATAW-1 downto 0);
      databus_cntrl : in std_logic_vector(0 downto 0));
  end component;

  component tta0_output_socket_cons_1_1
    generic (
      BUSW_0 : integer := 32;
      DATAW_0 : integer := 32);
    port (
      databus0_alt : out std_logic_vector(BUSW_0-1 downto 0);
      data0 : in std_logic_vector(DATAW_0-1 downto 0);
      databus_cntrl : in std_logic_vector(0 downto 0));
  end component;


begin -- comb_andor

  -- Dump the value on the buses into a file once in clock cycle
  -- setting DUMP false will disable dumping

  -- Do not synthesize this process!
  -- pragma synthesis_off
  -- pragma translate_off
  file_output : process

    file regularfileout : text;
    file executionfileout : text;

    variable lineout : line;
    variable start : boolean := true;
    variable cyclecount : integer := 0;
    variable executioncount : integer := 0;

    constant SEPARATOR : string := " | ";
    constant DUMP : boolean := true;
    constant REGULARDUMPFILE : string := "bus.dump";
    constant EXECUTIONDUMPFILE : string := "execbus.dump";

  begin
    if DUMP = true then
      if start = true then
        file_open(regularfileout, REGULARDUMPFILE, write_mode);
        file_open(executionfileout, EXECUTIONDUMPFILE, write_mode);
        start := false;
      end if;

      -- wait until rising edge of clock
      wait on clk until clk = '1' and clk'last_value = '0';
      if (cyclecount > 3) then
        write(lineout, cyclecount-4, right, 12);
        write(lineout, SEPARATOR);
        write(lineout, conv_integer(signed(databus_ALU_GCU_TRIG(31 downto 0))), right, 12);
        write(lineout, SEPARATOR);
        write(lineout, conv_integer(signed(databus_PARAM(31 downto 0))), right, 12);
        write(lineout, SEPARATOR);
        write(lineout, conv_integer(signed(databus_LSU_MUL_TRIG(31 downto 0))), right, 12);
        write(lineout, SEPARATOR);

        writeline(regularfileout, lineout);
        if glock = '0' then
          write(lineout, executioncount, right, 12);
          write(lineout, SEPARATOR);
          write(lineout, conv_integer(signed(databus_ALU_GCU_TRIG(31 downto 0))), right, 12);
          write(lineout, SEPARATOR);
          write(lineout, conv_integer(signed(databus_PARAM(31 downto 0))), right, 12);
          write(lineout, SEPARATOR);
          write(lineout, conv_integer(signed(databus_LSU_MUL_TRIG(31 downto 0))), right, 12);
          write(lineout, SEPARATOR);

          writeline(executionfileout, lineout);
          executioncount := executioncount + 1;
        end if;
      end if;
      cyclecount := cyclecount + 1;
    end if;
  end process file_output;
  -- pragma translate_on
  -- pragma synthesis_on

  db_bustraces <= 
    databus_LSU_MUL_TRIG(31 downto 0) & databus_PARAM(31 downto 0) & databus_ALU_GCU_TRIG(31 downto 0);

  ALU_i1 : tta0_input_socket_cons_1
    generic map (
      BUSW_0 => 32,
      DATAW => 32)
    port map (
      databus0 => databus_ALU_GCU_TRIG,
      data => socket_ALU_i1_data);

  ALU_i2 : tta0_input_socket_cons_1
    generic map (
      BUSW_0 => 32,
      DATAW => 32)
    port map (
      databus0 => databus_PARAM,
      data => socket_ALU_i2_data);

  ALU_o1 : tta0_output_socket_cons_3_1
    generic map (
      BUSW_0 => 32,
      BUSW_1 => 32,
      BUSW_2 => 32,
      DATAW_0 => 32)
    port map (
      databus0_alt => databus_ALU_GCU_TRIG_alt0,
      databus1_alt => databus_PARAM_alt0,
      databus2_alt => databus_LSU_MUL_TRIG_alt0,
      data0 => socket_ALU_o1_data0,
      databus_cntrl => socket_ALU_o1_bus_cntrl);

  IMM_rd : tta0_output_socket_cons_3_1
    generic map (
      BUSW_0 => 32,
      BUSW_1 => 32,
      BUSW_2 => 32,
      DATAW_0 => 32)
    port map (
      databus0_alt => databus_PARAM_alt1,
      databus1_alt => databus_ALU_GCU_TRIG_alt1,
      databus2_alt => databus_LSU_MUL_TRIG_alt1,
      data0 => socket_IMM_rd_data0,
      databus_cntrl => socket_IMM_rd_bus_cntrl);

  IO_i1 : tta0_input_socket_cons_2
    generic map (
      BUSW_0 => 32,
      BUSW_1 => 32,
      DATAW => 8)
    port map (
      databus0 => databus_ALU_GCU_TRIG,
      databus1 => databus_LSU_MUL_TRIG,
      data => socket_IO_i1_data,
      databus_cntrl => socket_IO_i1_bus_cntrl);

  MUL_IN1 : tta0_input_socket_cons_1
    generic map (
      BUSW_0 => 32,
      DATAW => 32)
    port map (
      databus0 => databus_LSU_MUL_TRIG,
      data => socket_MUL_IN1_data);

  MUL_IN2 : tta0_input_socket_cons_1
    generic map (
      BUSW_0 => 32,
      DATAW => 32)
    port map (
      databus0 => databus_PARAM,
      data => socket_MUL_IN2_data);

  MUL_OUT : tta0_output_socket_cons_3_1
    generic map (
      BUSW_0 => 32,
      BUSW_1 => 32,
      BUSW_2 => 32,
      DATAW_0 => 32)
    port map (
      databus0_alt => databus_ALU_GCU_TRIG_alt2,
      databus1_alt => databus_LSU_MUL_TRIG_alt2,
      databus2_alt => databus_PARAM_alt2,
      data0 => socket_MUL_OUT_data0,
      databus_cntrl => socket_MUL_OUT_bus_cntrl);

  RF_i1 : tta0_input_socket_cons_2
    generic map (
      BUSW_0 => 32,
      BUSW_1 => 32,
      DATAW => 32)
    port map (
      databus0 => databus_LSU_MUL_TRIG,
      databus1 => databus_ALU_GCU_TRIG,
      data => socket_RF_i1_data,
      databus_cntrl => socket_RF_i1_bus_cntrl);

  RF_o1 : tta0_output_socket_cons_3_1
    generic map (
      BUSW_0 => 32,
      BUSW_1 => 32,
      BUSW_2 => 32,
      DATAW_0 => 32)
    port map (
      databus0_alt => databus_ALU_GCU_TRIG_alt3,
      databus1_alt => databus_LSU_MUL_TRIG_alt3,
      databus2_alt => databus_PARAM_alt3,
      data0 => socket_RF_o1_data0,
      databus_cntrl => socket_RF_o1_bus_cntrl);

  bool_i1 : tta0_input_socket_cons_1
    generic map (
      BUSW_0 => 32,
      DATAW => 1)
    port map (
      databus0 => databus_LSU_MUL_TRIG,
      data => socket_bool_i1_data);

  bool_o1 : tta0_output_socket_cons_3_1
    generic map (
      BUSW_0 => 1,
      BUSW_1 => 1,
      BUSW_2 => 1,
      DATAW_0 => 1)
    port map (
      databus0_alt => databus_ALU_GCU_TRIG_alt4,
      databus1_alt => databus_PARAM_alt4,
      databus2_alt => databus_LSU_MUL_TRIG_alt4,
      data0 => socket_bool_o1_data0,
      databus_cntrl => socket_bool_o1_bus_cntrl);

  gcu_i1 : tta0_input_socket_cons_1
    generic map (
      BUSW_0 => 32,
      DATAW => IMEMADDRWIDTH)
    port map (
      databus0 => databus_ALU_GCU_TRIG,
      data => socket_gcu_i1_data);

  gcu_i2 : tta0_input_socket_cons_1
    generic map (
      BUSW_0 => 32,
      DATAW => IMEMADDRWIDTH)
    port map (
      databus0 => databus_ALU_GCU_TRIG,
      data => socket_gcu_i2_data);

  gcu_o1 : tta0_output_socket_cons_3_1
    generic map (
      BUSW_0 => 32,
      BUSW_1 => 32,
      BUSW_2 => 32,
      DATAW_0 => IMEMADDRWIDTH)
    port map (
      databus0_alt => databus_ALU_GCU_TRIG_alt5,
      databus1_alt => databus_PARAM_alt5,
      databus2_alt => databus_LSU_MUL_TRIG_alt5,
      data0 => socket_gcu_o1_data0,
      databus_cntrl => socket_gcu_o1_bus_cntrl);

  lsu_i1 : tta0_input_socket_cons_1
    generic map (
      BUSW_0 => 32,
      DATAW => 15)
    port map (
      databus0 => databus_LSU_MUL_TRIG,
      data => socket_lsu_i1_data);

  lsu_i1_1 : tta0_input_socket_cons_1
    generic map (
      BUSW_0 => 32,
      DATAW => 11)
    port map (
      databus0 => databus_LSU_MUL_TRIG,
      data => socket_lsu_i1_1_data);

  lsu_i2 : tta0_input_socket_cons_1
    generic map (
      BUSW_0 => 32,
      DATAW => 32)
    port map (
      databus0 => databus_PARAM,
      data => socket_lsu_i2_data);

  lsu_i2_1 : tta0_input_socket_cons_1
    generic map (
      BUSW_0 => 32,
      DATAW => 32)
    port map (
      databus0 => databus_PARAM,
      data => socket_lsu_i2_1_data);

  lsu_o1 : tta0_output_socket_cons_3_1
    generic map (
      BUSW_0 => 32,
      BUSW_1 => 32,
      BUSW_2 => 32,
      DATAW_0 => 32)
    port map (
      databus0_alt => databus_ALU_GCU_TRIG_alt6,
      databus1_alt => databus_PARAM_alt6,
      databus2_alt => databus_LSU_MUL_TRIG_alt6,
      data0 => socket_lsu_o1_data0,
      databus_cntrl => socket_lsu_o1_bus_cntrl);

  lsu_o1_1 : tta0_output_socket_cons_3_1
    generic map (
      BUSW_0 => 32,
      BUSW_1 => 32,
      BUSW_2 => 32,
      DATAW_0 => 32)
    port map (
      databus0_alt => databus_ALU_GCU_TRIG_alt7,
      databus1_alt => databus_PARAM_alt7,
      databus2_alt => databus_LSU_MUL_TRIG_alt7,
      data0 => socket_lsu_o1_1_data0,
      databus_cntrl => socket_lsu_o1_1_bus_cntrl);

  simm_socket_ALU_GCU_TRIG : tta0_output_socket_cons_1_1
    generic map (
      BUSW_0 => 4,
      DATAW_0 => 4)
    port map (
      databus0_alt => databus_ALU_GCU_TRIG_simm,
      data0 => simm_ALU_GCU_TRIG,
      databus_cntrl => simm_cntrl_ALU_GCU_TRIG);

  simm_socket_PARAM : tta0_output_socket_cons_1_1
    generic map (
      BUSW_0 => 5,
      DATAW_0 => 5)
    port map (
      databus0_alt => databus_PARAM_simm,
      data0 => simm_PARAM,
      databus_cntrl => simm_cntrl_PARAM);

  simm_socket_LSU_MUL_TRIG : tta0_output_socket_cons_1_1
    generic map (
      BUSW_0 => 3,
      DATAW_0 => 3)
    port map (
      databus0_alt => databus_LSU_MUL_TRIG_simm,
      data0 => simm_LSU_MUL_TRIG,
      databus_cntrl => simm_cntrl_LSU_MUL_TRIG);

  databus_ALU_GCU_TRIG <= tce_ext(databus_ALU_GCU_TRIG_alt0, databus_ALU_GCU_TRIG'length) or tce_ext(databus_ALU_GCU_TRIG_alt1, databus_ALU_GCU_TRIG'length) or tce_ext(databus_ALU_GCU_TRIG_alt2, databus_ALU_GCU_TRIG'length) or tce_ext(databus_ALU_GCU_TRIG_alt3, databus_ALU_GCU_TRIG'length) or tce_ext(databus_ALU_GCU_TRIG_alt4, databus_ALU_GCU_TRIG'length) or tce_ext(databus_ALU_GCU_TRIG_alt5, databus_ALU_GCU_TRIG'length) or tce_ext(databus_ALU_GCU_TRIG_alt6, databus_ALU_GCU_TRIG'length) or tce_ext(databus_ALU_GCU_TRIG_alt7, databus_ALU_GCU_TRIG'length) or tce_ext(databus_ALU_GCU_TRIG_simm, databus_ALU_GCU_TRIG'length);
  databus_PARAM <= tce_ext(databus_PARAM_alt0, databus_PARAM'length) or tce_ext(databus_PARAM_alt1, databus_PARAM'length) or tce_ext(databus_PARAM_alt2, databus_PARAM'length) or tce_ext(databus_PARAM_alt3, databus_PARAM'length) or tce_ext(databus_PARAM_alt4, databus_PARAM'length) or tce_ext(databus_PARAM_alt5, databus_PARAM'length) or tce_ext(databus_PARAM_alt6, databus_PARAM'length) or tce_ext(databus_PARAM_alt7, databus_PARAM'length) or tce_ext(databus_PARAM_simm, databus_PARAM'length);
  databus_LSU_MUL_TRIG <= tce_ext(databus_LSU_MUL_TRIG_alt0, databus_LSU_MUL_TRIG'length) or tce_ext(databus_LSU_MUL_TRIG_alt1, databus_LSU_MUL_TRIG'length) or tce_ext(databus_LSU_MUL_TRIG_alt2, databus_LSU_MUL_TRIG'length) or tce_ext(databus_LSU_MUL_TRIG_alt3, databus_LSU_MUL_TRIG'length) or tce_ext(databus_LSU_MUL_TRIG_alt4, databus_LSU_MUL_TRIG'length) or tce_ext(databus_LSU_MUL_TRIG_alt5, databus_LSU_MUL_TRIG'length) or tce_ext(databus_LSU_MUL_TRIG_alt6, databus_LSU_MUL_TRIG'length) or tce_ext(databus_LSU_MUL_TRIG_alt7, databus_LSU_MUL_TRIG'length) or tce_ext(databus_LSU_MUL_TRIG_simm, databus_LSU_MUL_TRIG'length);

end comb_andor;
