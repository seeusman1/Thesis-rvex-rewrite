library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use work.tta0_globals.all;
use work.tta0_gcu_opcodes.all;
use work.tce_util.all;

entity tta0_decoder is

  port (
    instructionword : in std_logic_vector(INSTRUCTIONWIDTH-1 downto 0);
    pc_load : out std_logic;
    ra_load : out std_logic;
    pc_opcode : out std_logic_vector(0 downto 0);
    lock : in std_logic;
    lock_r : out std_logic;
    clk : in std_logic;
    rstx : in std_logic;
    locked : out std_logic;
    simm_ALU_GCU_TRIG : out std_logic_vector(3 downto 0);
    simm_cntrl_ALU_GCU_TRIG : out std_logic_vector(0 downto 0);
    simm_PARAM : out std_logic_vector(4 downto 0);
    simm_cntrl_PARAM : out std_logic_vector(0 downto 0);
    simm_LSU_MUL_TRIG : out std_logic_vector(2 downto 0);
    simm_cntrl_LSU_MUL_TRIG : out std_logic_vector(0 downto 0);
    socket_lsu_o1_bus_cntrl : out std_logic_vector(2 downto 0);
    socket_RF_i1_bus_cntrl : out std_logic_vector(0 downto 0);
    socket_RF_o1_bus_cntrl : out std_logic_vector(2 downto 0);
    socket_bool_o1_bus_cntrl : out std_logic_vector(2 downto 0);
    socket_gcu_o1_bus_cntrl : out std_logic_vector(2 downto 0);
    socket_ALU_o1_bus_cntrl : out std_logic_vector(2 downto 0);
    socket_IO_i1_bus_cntrl : out std_logic_vector(0 downto 0);
    socket_IMM_rd_bus_cntrl : out std_logic_vector(2 downto 0);
    socket_MUL_OUT_bus_cntrl : out std_logic_vector(2 downto 0);
    socket_lsu_o1_1_bus_cntrl : out std_logic_vector(2 downto 0);
    fu_LSU_in1t_load : out std_logic;
    fu_LSU_in2_load : out std_logic;
    fu_LSU_opc : out std_logic_vector(2 downto 0);
    fu_stdout_T_load : out std_logic;
    fu_mul_in1t_load : out std_logic;
    fu_mul_in2_load : out std_logic;
    fu_ALU_in1t_load : out std_logic;
    fu_ALU_in2_load : out std_logic;
    fu_ALU_opc : out std_logic_vector(4 downto 0);
    fu_LSU_PARAM_in1t_load : out std_logic;
    fu_LSU_PARAM_in2_load : out std_logic;
    fu_LSU_PARAM_opc : out std_logic_vector(2 downto 0);
    rf_RF_wr_load : out std_logic;
    rf_RF_wr_opc : out std_logic_vector(3 downto 0);
    rf_RF_rd_load : out std_logic;
    rf_RF_rd_opc : out std_logic_vector(3 downto 0);
    rf_BOOL_wr_load : out std_logic;
    rf_BOOL_wr_opc : out std_logic_vector(0 downto 0);
    rf_BOOL_rd_load : out std_logic;
    rf_BOOL_rd_opc : out std_logic_vector(0 downto 0);
    iu_IU_1x32_r0_read_load : out std_logic;
    iu_IU_1x32_r0_read_opc : out std_logic_vector(0 downto 0);
    iu_IU_1x32_write : out std_logic_vector(31 downto 0);
    iu_IU_1x32_write_load : out std_logic;
    iu_IU_1x32_write_opc : out std_logic_vector(0 downto 0);
    rf_guard_BOOL_0 : in std_logic;
    rf_guard_BOOL_1 : in std_logic;
    lock_req : in std_logic_vector(0 downto 0);
    glock : out std_logic_vector(8 downto 0);
    db_tta_nreset : in std_logic);

end tta0_decoder;

architecture rtl_andor of tta0_decoder is

  -- signals for source, destination and guard fields
  signal src_ALU_GCU_TRIG : std_logic_vector(5 downto 0);
  signal dst_ALU_GCU_TRIG : std_logic_vector(5 downto 0);
  signal grd_ALU_GCU_TRIG : std_logic_vector(2 downto 0);
  signal src_PARAM : std_logic_vector(5 downto 0);
  signal dst_PARAM : std_logic_vector(2 downto 0);
  signal grd_PARAM : std_logic_vector(2 downto 0);
  signal src_LSU_MUL_TRIG : std_logic_vector(5 downto 0);
  signal dst_LSU_MUL_TRIG : std_logic_vector(5 downto 0);
  signal grd_LSU_MUL_TRIG : std_logic_vector(2 downto 0);

  -- signals for dedicated immediate slots

  -- signal for long immediate tag
  signal limm_tag : std_logic_vector(0 downto 0);

  -- squash signals
  signal squash_ALU_GCU_TRIG : std_logic;
  signal squash_PARAM : std_logic;
  signal squash_LSU_MUL_TRIG : std_logic;

  -- socket control signals
  signal socket_lsu_o1_bus_cntrl_reg : std_logic_vector(2 downto 0);
  signal socket_RF_i1_bus_cntrl_reg : std_logic_vector(0 downto 0);
  signal socket_RF_o1_bus_cntrl_reg : std_logic_vector(2 downto 0);
  signal socket_bool_o1_bus_cntrl_reg : std_logic_vector(2 downto 0);
  signal socket_gcu_o1_bus_cntrl_reg : std_logic_vector(2 downto 0);
  signal socket_ALU_o1_bus_cntrl_reg : std_logic_vector(2 downto 0);
  signal socket_IO_i1_bus_cntrl_reg : std_logic_vector(0 downto 0);
  signal socket_IMM_rd_bus_cntrl_reg : std_logic_vector(2 downto 0);
  signal socket_MUL_OUT_bus_cntrl_reg : std_logic_vector(2 downto 0);
  signal socket_lsu_o1_1_bus_cntrl_reg : std_logic_vector(2 downto 0);
  signal simm_ALU_GCU_TRIG_reg : std_logic_vector(3 downto 0);
  signal simm_cntrl_ALU_GCU_TRIG_reg : std_logic_vector(0 downto 0);
  signal simm_PARAM_reg : std_logic_vector(4 downto 0);
  signal simm_cntrl_PARAM_reg : std_logic_vector(0 downto 0);
  signal simm_LSU_MUL_TRIG_reg : std_logic_vector(2 downto 0);
  signal simm_cntrl_LSU_MUL_TRIG_reg : std_logic_vector(0 downto 0);

  -- FU control signals
  signal fu_LSU_in1t_load_reg : std_logic;
  signal fu_LSU_in2_load_reg : std_logic;
  signal fu_LSU_opc_reg : std_logic_vector(2 downto 0);
  signal fu_stdout_T_load_reg : std_logic;
  signal fu_mul_in1t_load_reg : std_logic;
  signal fu_mul_in2_load_reg : std_logic;
  signal fu_ALU_in1t_load_reg : std_logic;
  signal fu_ALU_in2_load_reg : std_logic;
  signal fu_ALU_opc_reg : std_logic_vector(4 downto 0);
  signal fu_LSU_PARAM_in1t_load_reg : std_logic;
  signal fu_LSU_PARAM_in2_load_reg : std_logic;
  signal fu_LSU_PARAM_opc_reg : std_logic_vector(2 downto 0);
  signal fu_gcu_pc_load_reg : std_logic;
  signal fu_gcu_ra_load_reg : std_logic;
  signal fu_gcu_opc_reg : std_logic_vector(0 downto 0);

  -- RF control signals
  signal rf_RF_wr_load_reg : std_logic;
  signal rf_RF_wr_opc_reg : std_logic_vector(3 downto 0);
  signal rf_RF_rd_load_reg : std_logic;
  signal rf_RF_rd_opc_reg : std_logic_vector(3 downto 0);
  signal rf_BOOL_wr_load_reg : std_logic;
  signal rf_BOOL_wr_opc_reg : std_logic_vector(0 downto 0);
  signal rf_BOOL_rd_load_reg : std_logic;
  signal rf_BOOL_rd_opc_reg : std_logic_vector(0 downto 0);

  signal merged_glock_req : std_logic;
  signal pre_decode_merged_glock : std_logic;
  signal post_decode_merged_glock : std_logic;

  signal decode_fill_lock_reg : std_logic;
begin

  -- dismembering of instruction
  process (instructionword)
  begin --process
    src_ALU_GCU_TRIG <= instructionword(11 downto 6);
    dst_ALU_GCU_TRIG <= instructionword(5 downto 0);
    grd_ALU_GCU_TRIG <= instructionword(14 downto 12);
    src_PARAM <= instructionword(23 downto 18);
    dst_PARAM <= instructionword(17 downto 15);
    grd_PARAM <= instructionword(26 downto 24);
    src_LSU_MUL_TRIG <= instructionword(38 downto 33);
    dst_LSU_MUL_TRIG <= instructionword(32 downto 27);
    grd_LSU_MUL_TRIG <= instructionword(41 downto 39);

    limm_tag <= instructionword(42 downto 42);
  end process;

  -- map control registers to outputs
  fu_LSU_in1t_load <= fu_LSU_in1t_load_reg;
  fu_LSU_in2_load <= fu_LSU_in2_load_reg;
  fu_LSU_opc <= fu_LSU_opc_reg;

  fu_stdout_T_load <= fu_stdout_T_load_reg;

  fu_mul_in1t_load <= fu_mul_in1t_load_reg;
  fu_mul_in2_load <= fu_mul_in2_load_reg;

  fu_ALU_in1t_load <= fu_ALU_in1t_load_reg;
  fu_ALU_in2_load <= fu_ALU_in2_load_reg;
  fu_ALU_opc <= fu_ALU_opc_reg;

  fu_LSU_PARAM_in1t_load <= fu_LSU_PARAM_in1t_load_reg;
  fu_LSU_PARAM_in2_load <= fu_LSU_PARAM_in2_load_reg;
  fu_LSU_PARAM_opc <= fu_LSU_PARAM_opc_reg;

  ra_load <= fu_gcu_ra_load_reg;
  pc_load <= fu_gcu_pc_load_reg;
  pc_opcode <= fu_gcu_opc_reg;
  rf_RF_wr_load <= rf_RF_wr_load_reg;
  rf_RF_wr_opc <= rf_RF_wr_opc_reg;
  rf_RF_rd_load <= rf_RF_rd_load_reg;
  rf_RF_rd_opc <= rf_RF_rd_opc_reg;
  rf_BOOL_wr_load <= rf_BOOL_wr_load_reg;
  rf_BOOL_wr_opc <= rf_BOOL_wr_opc_reg;
  rf_BOOL_rd_load <= rf_BOOL_rd_load_reg;
  rf_BOOL_rd_opc <= rf_BOOL_rd_opc_reg;
  iu_IU_1x32_r0_read_opc <= "0";
  iu_IU_1x32_write_opc <= "0";
  socket_lsu_o1_bus_cntrl <= socket_lsu_o1_bus_cntrl_reg;
  socket_RF_i1_bus_cntrl <= socket_RF_i1_bus_cntrl_reg;
  socket_RF_o1_bus_cntrl <= socket_RF_o1_bus_cntrl_reg;
  socket_bool_o1_bus_cntrl <= socket_bool_o1_bus_cntrl_reg;
  socket_gcu_o1_bus_cntrl <= socket_gcu_o1_bus_cntrl_reg;
  socket_ALU_o1_bus_cntrl <= socket_ALU_o1_bus_cntrl_reg;
  socket_IO_i1_bus_cntrl <= socket_IO_i1_bus_cntrl_reg;
  socket_IMM_rd_bus_cntrl <= socket_IMM_rd_bus_cntrl_reg;
  socket_MUL_OUT_bus_cntrl <= socket_MUL_OUT_bus_cntrl_reg;
  socket_lsu_o1_1_bus_cntrl <= socket_lsu_o1_1_bus_cntrl_reg;
  simm_cntrl_ALU_GCU_TRIG <= simm_cntrl_ALU_GCU_TRIG_reg;
  simm_ALU_GCU_TRIG <= simm_ALU_GCU_TRIG_reg;
  simm_cntrl_PARAM <= simm_cntrl_PARAM_reg;
  simm_PARAM <= simm_PARAM_reg;
  simm_cntrl_LSU_MUL_TRIG <= simm_cntrl_LSU_MUL_TRIG_reg;
  simm_LSU_MUL_TRIG <= simm_LSU_MUL_TRIG_reg;

  -- generate signal squash_ALU_GCU_TRIG
  process (rf_guard_BOOL_0, rf_guard_BOOL_1, grd_ALU_GCU_TRIG, limm_tag)
    variable sel : integer;
  begin --process
    if (conv_integer(unsigned(limm_tag)) = 1) then
      squash_ALU_GCU_TRIG <= '1';
    else
      sel := conv_integer(unsigned(grd_ALU_GCU_TRIG));
      case sel is
        when 1 =>
          squash_ALU_GCU_TRIG <= not rf_guard_BOOL_0;
        when 2 =>
          squash_ALU_GCU_TRIG <= rf_guard_BOOL_0;
        when 3 =>
          squash_ALU_GCU_TRIG <= not rf_guard_BOOL_1;
        when 4 =>
          squash_ALU_GCU_TRIG <= rf_guard_BOOL_1;
        when others =>
          squash_ALU_GCU_TRIG <= '0';
      end case;
    end if;
  end process;

  -- generate signal squash_PARAM
  process (rf_guard_BOOL_0, rf_guard_BOOL_1, grd_PARAM, limm_tag)
    variable sel : integer;
  begin --process
    if (conv_integer(unsigned(limm_tag)) = 1) then
      squash_PARAM <= '1';
    else
      sel := conv_integer(unsigned(grd_PARAM));
      case sel is
        when 1 =>
          squash_PARAM <= not rf_guard_BOOL_0;
        when 2 =>
          squash_PARAM <= rf_guard_BOOL_0;
        when 3 =>
          squash_PARAM <= not rf_guard_BOOL_1;
        when 4 =>
          squash_PARAM <= rf_guard_BOOL_1;
        when others =>
          squash_PARAM <= '0';
      end case;
    end if;
  end process;

  -- generate signal squash_LSU_MUL_TRIG
  process (rf_guard_BOOL_0, rf_guard_BOOL_1, grd_LSU_MUL_TRIG, limm_tag)
    variable sel : integer;
  begin --process
    if (conv_integer(unsigned(limm_tag)) = 1) then
      squash_LSU_MUL_TRIG <= '1';
    else
      sel := conv_integer(unsigned(grd_LSU_MUL_TRIG));
      case sel is
        when 1 =>
          squash_LSU_MUL_TRIG <= not rf_guard_BOOL_0;
        when 2 =>
          squash_LSU_MUL_TRIG <= rf_guard_BOOL_0;
        when 3 =>
          squash_LSU_MUL_TRIG <= not rf_guard_BOOL_1;
        when 4 =>
          squash_LSU_MUL_TRIG <= rf_guard_BOOL_1;
        when others =>
          squash_LSU_MUL_TRIG <= '0';
      end case;
    end if;
  end process;


  --long immediate write process
  process (clk, rstx)
  begin --process
    if (rstx = '0') then
      iu_IU_1x32_write_load <= '0';
      iu_IU_1x32_write <= (others => '0');
    elsif (clk'event and clk = '1') then
      if pre_decode_merged_glock = '0' then
        if (conv_integer(unsigned(limm_tag)) = 0) then
          iu_IU_1x32_write_load <= '0';
          iu_IU_1x32_write(31 downto 0) <= tce_sxt("0", 32);
        else
          iu_IU_1x32_write(31 downto 20) <= tce_ext(instructionword(11 downto 0), 12);
          iu_IU_1x32_write(19 downto 10) <= instructionword(24 downto 15);
          iu_IU_1x32_write(9 downto 0) <= instructionword(36 downto 27);
          iu_IU_1x32_write_load <= '1';
        end if;
      end if;
    end if;
  end process;


  -- main decoding process
  process (clk, rstx)
  begin
    if (rstx = '0') then
      socket_lsu_o1_bus_cntrl_reg <= (others => '0');
      socket_RF_i1_bus_cntrl_reg <= (others => '0');
      socket_RF_o1_bus_cntrl_reg <= (others => '0');
      socket_bool_o1_bus_cntrl_reg <= (others => '0');
      socket_gcu_o1_bus_cntrl_reg <= (others => '0');
      socket_ALU_o1_bus_cntrl_reg <= (others => '0');
      socket_IO_i1_bus_cntrl_reg <= (others => '0');
      socket_IMM_rd_bus_cntrl_reg <= (others => '0');
      socket_MUL_OUT_bus_cntrl_reg <= (others => '0');
      socket_lsu_o1_1_bus_cntrl_reg <= (others => '0');

      simm_cntrl_ALU_GCU_TRIG_reg <= (others => '0');
      simm_ALU_GCU_TRIG_reg <= (others => '0');
      simm_cntrl_PARAM_reg <= (others => '0');
      simm_PARAM_reg <= (others => '0');
      simm_cntrl_LSU_MUL_TRIG_reg <= (others => '0');
      simm_LSU_MUL_TRIG_reg <= (others => '0');

      fu_LSU_opc_reg <= (others => '0');
      fu_LSU_in1t_load_reg <= '0';
      fu_LSU_in2_load_reg <= '0';
      fu_stdout_T_load_reg <= '0';
      fu_mul_in1t_load_reg <= '0';
      fu_mul_in2_load_reg <= '0';
      fu_ALU_opc_reg <= (others => '0');
      fu_ALU_in1t_load_reg <= '0';
      fu_ALU_in2_load_reg <= '0';
      fu_LSU_PARAM_opc_reg <= (others => '0');
      fu_LSU_PARAM_in1t_load_reg <= '0';
      fu_LSU_PARAM_in2_load_reg <= '0';
      fu_gcu_opc_reg <= (others => '0');
      fu_gcu_pc_load_reg <= '0';
      fu_gcu_ra_load_reg <= '0';

      rf_RF_wr_load_reg <= '0';
      rf_RF_wr_opc_reg <= (others => '0');
      rf_RF_rd_load_reg <= '0';
      rf_RF_rd_opc_reg <= (others => '0');
      rf_BOOL_wr_load_reg <= '0';
      rf_BOOL_wr_opc_reg <= (others => '0');
      rf_BOOL_rd_load_reg <= '0';
      rf_BOOL_rd_opc_reg <= (others => '0');

      iu_IU_1x32_r0_read_load <= '0';

    elsif (clk'event and clk = '1') then -- rising clock edge
      if (db_tta_nreset = '0') then
      socket_lsu_o1_bus_cntrl_reg <= (others => '0');
      socket_RF_i1_bus_cntrl_reg <= (others => '0');
      socket_RF_o1_bus_cntrl_reg <= (others => '0');
      socket_bool_o1_bus_cntrl_reg <= (others => '0');
      socket_gcu_o1_bus_cntrl_reg <= (others => '0');
      socket_ALU_o1_bus_cntrl_reg <= (others => '0');
      socket_IO_i1_bus_cntrl_reg <= (others => '0');
      socket_IMM_rd_bus_cntrl_reg <= (others => '0');
      socket_MUL_OUT_bus_cntrl_reg <= (others => '0');
      socket_lsu_o1_1_bus_cntrl_reg <= (others => '0');

      simm_cntrl_ALU_GCU_TRIG_reg <= (others => '0');
      simm_ALU_GCU_TRIG_reg <= (others => '0');
      simm_cntrl_PARAM_reg <= (others => '0');
      simm_PARAM_reg <= (others => '0');
      simm_cntrl_LSU_MUL_TRIG_reg <= (others => '0');
      simm_LSU_MUL_TRIG_reg <= (others => '0');

      fu_LSU_opc_reg <= (others => '0');
      fu_LSU_in1t_load_reg <= '0';
      fu_LSU_in2_load_reg <= '0';
      fu_stdout_T_load_reg <= '0';
      fu_mul_in1t_load_reg <= '0';
      fu_mul_in2_load_reg <= '0';
      fu_ALU_opc_reg <= (others => '0');
      fu_ALU_in1t_load_reg <= '0';
      fu_ALU_in2_load_reg <= '0';
      fu_LSU_PARAM_opc_reg <= (others => '0');
      fu_LSU_PARAM_in1t_load_reg <= '0';
      fu_LSU_PARAM_in2_load_reg <= '0';
      fu_gcu_opc_reg <= (others => '0');
      fu_gcu_pc_load_reg <= '0';
      fu_gcu_ra_load_reg <= '0';

      rf_RF_wr_load_reg <= '0';
      rf_RF_wr_opc_reg <= (others => '0');
      rf_RF_rd_load_reg <= '0';
      rf_RF_rd_opc_reg <= (others => '0');
      rf_BOOL_wr_load_reg <= '0';
      rf_BOOL_wr_opc_reg <= (others => '0');
      rf_BOOL_rd_load_reg <= '0';
      rf_BOOL_rd_opc_reg <= (others => '0');

      iu_IU_1x32_r0_read_load <= '0';
      elsif (pre_decode_merged_glock = '0') then

        --bus control signals for output sockets
        if (squash_ALU_GCU_TRIG = '0' and conv_integer(unsigned(src_ALU_GCU_TRIG(5 downto 2))) = 10) then
          socket_lsu_o1_bus_cntrl_reg(0) <= '1';
        else
          socket_lsu_o1_bus_cntrl_reg(0) <= '0';
        end if;
        if (squash_PARAM = '0' and conv_integer(unsigned(src_PARAM(5 downto 1))) = 26) then
          socket_lsu_o1_bus_cntrl_reg(1) <= '1';
        else
          socket_lsu_o1_bus_cntrl_reg(1) <= '0';
        end if;
        if (squash_LSU_MUL_TRIG = '0' and conv_integer(unsigned(src_LSU_MUL_TRIG(5 downto 0))) = 27) then
          socket_lsu_o1_bus_cntrl_reg(2) <= '1';
        else
          socket_lsu_o1_bus_cntrl_reg(2) <= '0';
        end if;
        if (squash_ALU_GCU_TRIG = '0' and conv_integer(unsigned(src_ALU_GCU_TRIG(5 downto 4))) = 1) then
          socket_RF_o1_bus_cntrl_reg(0) <= '1';
        else
          socket_RF_o1_bus_cntrl_reg(0) <= '0';
        end if;
        if (squash_PARAM = '0' and conv_integer(unsigned(src_PARAM(5 downto 4))) = 2) then
          socket_RF_o1_bus_cntrl_reg(2) <= '1';
        else
          socket_RF_o1_bus_cntrl_reg(2) <= '0';
        end if;
        if (squash_LSU_MUL_TRIG = '0' and conv_integer(unsigned(src_LSU_MUL_TRIG(5 downto 4))) = 0) then
          socket_RF_o1_bus_cntrl_reg(1) <= '1';
        else
          socket_RF_o1_bus_cntrl_reg(1) <= '0';
        end if;
        if (squash_ALU_GCU_TRIG = '0' and conv_integer(unsigned(src_ALU_GCU_TRIG(5 downto 2))) = 8) then
          socket_bool_o1_bus_cntrl_reg(0) <= '1';
        else
          socket_bool_o1_bus_cntrl_reg(0) <= '0';
        end if;
        if (squash_PARAM = '0' and conv_integer(unsigned(src_PARAM(5 downto 1))) = 24) then
          socket_bool_o1_bus_cntrl_reg(1) <= '1';
        else
          socket_bool_o1_bus_cntrl_reg(1) <= '0';
        end if;
        if (squash_LSU_MUL_TRIG = '0' and conv_integer(unsigned(src_LSU_MUL_TRIG(5 downto 1))) = 12) then
          socket_bool_o1_bus_cntrl_reg(2) <= '1';
        else
          socket_bool_o1_bus_cntrl_reg(2) <= '0';
        end if;
        if (squash_ALU_GCU_TRIG = '0' and conv_integer(unsigned(src_ALU_GCU_TRIG(5 downto 2))) = 11) then
          socket_gcu_o1_bus_cntrl_reg(0) <= '1';
        else
          socket_gcu_o1_bus_cntrl_reg(0) <= '0';
        end if;
        if (squash_PARAM = '0' and conv_integer(unsigned(src_PARAM(5 downto 1))) = 27) then
          socket_gcu_o1_bus_cntrl_reg(1) <= '1';
        else
          socket_gcu_o1_bus_cntrl_reg(1) <= '0';
        end if;
        if (squash_LSU_MUL_TRIG = '0' and conv_integer(unsigned(src_LSU_MUL_TRIG(5 downto 0))) = 28) then
          socket_gcu_o1_bus_cntrl_reg(2) <= '1';
        else
          socket_gcu_o1_bus_cntrl_reg(2) <= '0';
        end if;
        if (squash_ALU_GCU_TRIG = '0' and conv_integer(unsigned(src_ALU_GCU_TRIG(5 downto 2))) = 12) then
          socket_ALU_o1_bus_cntrl_reg(0) <= '1';
        else
          socket_ALU_o1_bus_cntrl_reg(0) <= '0';
        end if;
        if (squash_PARAM = '0' and conv_integer(unsigned(src_PARAM(5 downto 1))) = 28) then
          socket_ALU_o1_bus_cntrl_reg(1) <= '1';
        else
          socket_ALU_o1_bus_cntrl_reg(1) <= '0';
        end if;
        if (squash_LSU_MUL_TRIG = '0' and conv_integer(unsigned(src_LSU_MUL_TRIG(5 downto 0))) = 29) then
          socket_ALU_o1_bus_cntrl_reg(2) <= '1';
        else
          socket_ALU_o1_bus_cntrl_reg(2) <= '0';
        end if;
        if (squash_ALU_GCU_TRIG = '0' and conv_integer(unsigned(src_ALU_GCU_TRIG(5 downto 2))) = 13) then
          socket_IMM_rd_bus_cntrl_reg(1) <= '1';
        else
          socket_IMM_rd_bus_cntrl_reg(1) <= '0';
        end if;
        if (squash_PARAM = '0' and conv_integer(unsigned(src_PARAM(5 downto 1))) = 29) then
          socket_IMM_rd_bus_cntrl_reg(0) <= '1';
        else
          socket_IMM_rd_bus_cntrl_reg(0) <= '0';
        end if;
        if (squash_LSU_MUL_TRIG = '0' and conv_integer(unsigned(src_LSU_MUL_TRIG(5 downto 0))) = 30) then
          socket_IMM_rd_bus_cntrl_reg(2) <= '1';
        else
          socket_IMM_rd_bus_cntrl_reg(2) <= '0';
        end if;
        if (squash_ALU_GCU_TRIG = '0' and conv_integer(unsigned(src_ALU_GCU_TRIG(5 downto 2))) = 14) then
          socket_MUL_OUT_bus_cntrl_reg(0) <= '1';
        else
          socket_MUL_OUT_bus_cntrl_reg(0) <= '0';
        end if;
        if (squash_PARAM = '0' and conv_integer(unsigned(src_PARAM(5 downto 1))) = 30) then
          socket_MUL_OUT_bus_cntrl_reg(2) <= '1';
        else
          socket_MUL_OUT_bus_cntrl_reg(2) <= '0';
        end if;
        if (squash_LSU_MUL_TRIG = '0' and conv_integer(unsigned(src_LSU_MUL_TRIG(5 downto 0))) = 31) then
          socket_MUL_OUT_bus_cntrl_reg(1) <= '1';
        else
          socket_MUL_OUT_bus_cntrl_reg(1) <= '0';
        end if;
        if (squash_ALU_GCU_TRIG = '0' and conv_integer(unsigned(src_ALU_GCU_TRIG(5 downto 2))) = 15) then
          socket_lsu_o1_1_bus_cntrl_reg(0) <= '1';
        else
          socket_lsu_o1_1_bus_cntrl_reg(0) <= '0';
        end if;
        if (squash_PARAM = '0' and conv_integer(unsigned(src_PARAM(5 downto 1))) = 31) then
          socket_lsu_o1_1_bus_cntrl_reg(1) <= '1';
        else
          socket_lsu_o1_1_bus_cntrl_reg(1) <= '0';
        end if;
        if (squash_LSU_MUL_TRIG = '0' and conv_integer(unsigned(src_LSU_MUL_TRIG(5 downto 0))) = 32) then
          socket_lsu_o1_1_bus_cntrl_reg(2) <= '1';
        else
          socket_lsu_o1_1_bus_cntrl_reg(2) <= '0';
        end if;

        --bus control signals for short immediate sockets
        if (squash_ALU_GCU_TRIG = '0' and conv_integer(unsigned(src_ALU_GCU_TRIG(5 downto 4))) = 0) then
          simm_cntrl_ALU_GCU_TRIG_reg(0) <= '1';
          simm_ALU_GCU_TRIG_reg <= tce_ext(src_ALU_GCU_TRIG(3 downto 0), simm_ALU_GCU_TRIG_reg'length);
        else
          simm_cntrl_ALU_GCU_TRIG_reg(0) <= '0';
        end if;
        if (squash_PARAM = '0' and conv_integer(unsigned(src_PARAM(5 downto 5))) = 0) then
          simm_cntrl_PARAM_reg(0) <= '1';
          simm_PARAM_reg <= tce_ext(src_PARAM(4 downto 0), simm_PARAM_reg'length);
        else
          simm_cntrl_PARAM_reg(0) <= '0';
        end if;
        if (squash_LSU_MUL_TRIG = '0' and conv_integer(unsigned(src_LSU_MUL_TRIG(5 downto 3))) = 2) then
          simm_cntrl_LSU_MUL_TRIG_reg(0) <= '1';
          simm_LSU_MUL_TRIG_reg <= tce_ext(src_LSU_MUL_TRIG(2 downto 0), simm_LSU_MUL_TRIG_reg'length);
        else
          simm_cntrl_LSU_MUL_TRIG_reg(0) <= '0';
        end if;

        --data control signals for output sockets connected to FUs

        --control signals for RF read ports
        if (squash_ALU_GCU_TRIG = '0' and conv_integer(unsigned(src_ALU_GCU_TRIG(5 downto 4))) = 1 and true) then
          rf_RF_rd_load_reg <= '1';
          rf_RF_rd_opc_reg <= tce_ext(src_ALU_GCU_TRIG(3 downto 0), rf_RF_rd_opc_reg'length);
        elsif (squash_PARAM = '0' and conv_integer(unsigned(src_PARAM(5 downto 4))) = 2 and true) then
          rf_RF_rd_load_reg <= '1';
          rf_RF_rd_opc_reg <= tce_ext(src_PARAM(3 downto 0), rf_RF_rd_opc_reg'length);
        elsif (squash_LSU_MUL_TRIG = '0' and conv_integer(unsigned(src_LSU_MUL_TRIG(5 downto 4))) = 0 and true) then
          rf_RF_rd_load_reg <= '1';
          rf_RF_rd_opc_reg <= tce_ext(src_LSU_MUL_TRIG(3 downto 0), rf_RF_rd_opc_reg'length);
        else
          rf_RF_rd_load_reg <= '0';
        end if;
        if (squash_ALU_GCU_TRIG = '0' and conv_integer(unsigned(src_ALU_GCU_TRIG(5 downto 2))) = 8 and true) then
          rf_BOOL_rd_load_reg <= '1';
          rf_BOOL_rd_opc_reg <= tce_ext(src_ALU_GCU_TRIG(0 downto 0), rf_BOOL_rd_opc_reg'length);
        elsif (squash_PARAM = '0' and conv_integer(unsigned(src_PARAM(5 downto 1))) = 24 and true) then
          rf_BOOL_rd_load_reg <= '1';
          rf_BOOL_rd_opc_reg <= tce_ext(src_PARAM(0 downto 0), rf_BOOL_rd_opc_reg'length);
        elsif (squash_LSU_MUL_TRIG = '0' and conv_integer(unsigned(src_LSU_MUL_TRIG(5 downto 1))) = 12 and true) then
          rf_BOOL_rd_load_reg <= '1';
          rf_BOOL_rd_opc_reg <= tce_ext(src_LSU_MUL_TRIG(0 downto 0), rf_BOOL_rd_opc_reg'length);
        else
          rf_BOOL_rd_load_reg <= '0';
        end if;

        --control signals for IU read ports
        if (squash_ALU_GCU_TRIG = '0' and conv_integer(unsigned(src_ALU_GCU_TRIG(5 downto 2))) = 13) then
          iu_IU_1x32_r0_read_load <= '1';
        elsif (squash_PARAM = '0' and conv_integer(unsigned(src_PARAM(5 downto 1))) = 29) then
          iu_IU_1x32_r0_read_load <= '1';
        elsif (squash_LSU_MUL_TRIG = '0' and conv_integer(unsigned(src_LSU_MUL_TRIG(5 downto 0))) = 30) then
          iu_IU_1x32_r0_read_load <= '1';
        else
          iu_IU_1x32_r0_read_load <= '0';
        end if;

        --control signals for FU inputs
        if (squash_LSU_MUL_TRIG = '0' and conv_integer(unsigned(dst_LSU_MUL_TRIG(5 downto 3))) = 2) then
          fu_LSU_in1t_load_reg <= '1';
          fu_LSU_opc_reg <= dst_LSU_MUL_TRIG(2 downto 0);
        else
          fu_LSU_in1t_load_reg <= '0';
        end if;
        if (squash_PARAM = '0' and conv_integer(unsigned(dst_PARAM(2 downto 0))) = 1) then
          fu_LSU_in2_load_reg <= '1';
        else
          fu_LSU_in2_load_reg <= '0';
        end if;
        if (squash_ALU_GCU_TRIG = '0' and conv_integer(unsigned(dst_ALU_GCU_TRIG(5 downto 2))) = 15) then
          fu_stdout_T_load_reg <= '1';
          socket_IO_i1_bus_cntrl_reg <= conv_std_logic_vector(0, socket_IO_i1_bus_cntrl_reg'length);
        elsif (squash_LSU_MUL_TRIG = '0' and conv_integer(unsigned(dst_LSU_MUL_TRIG(5 downto 2))) = 10) then
          fu_stdout_T_load_reg <= '1';
          socket_IO_i1_bus_cntrl_reg <= conv_std_logic_vector(1, socket_IO_i1_bus_cntrl_reg'length);
        else
          fu_stdout_T_load_reg <= '0';
        end if;
        if (squash_LSU_MUL_TRIG = '0' and conv_integer(unsigned(dst_LSU_MUL_TRIG(5 downto 2))) = 11) then
          fu_mul_in1t_load_reg <= '1';
        else
          fu_mul_in1t_load_reg <= '0';
        end if;
        if (squash_PARAM = '0' and conv_integer(unsigned(dst_PARAM(2 downto 0))) = 3) then
          fu_mul_in2_load_reg <= '1';
        else
          fu_mul_in2_load_reg <= '0';
        end if;
        if (squash_ALU_GCU_TRIG = '0' and conv_integer(unsigned(dst_ALU_GCU_TRIG(5 downto 5))) = 0) then
          fu_ALU_in1t_load_reg <= '1';
          fu_ALU_opc_reg <= dst_ALU_GCU_TRIG(4 downto 0);
        else
          fu_ALU_in1t_load_reg <= '0';
        end if;
        if (squash_PARAM = '0' and conv_integer(unsigned(dst_PARAM(2 downto 0))) = 2) then
          fu_ALU_in2_load_reg <= '1';
        else
          fu_ALU_in2_load_reg <= '0';
        end if;
        if (squash_LSU_MUL_TRIG = '0' and conv_integer(unsigned(dst_LSU_MUL_TRIG(5 downto 3))) = 3) then
          fu_LSU_PARAM_in1t_load_reg <= '1';
          fu_LSU_PARAM_opc_reg <= dst_LSU_MUL_TRIG(2 downto 0);
        else
          fu_LSU_PARAM_in1t_load_reg <= '0';
        end if;
        if (squash_PARAM = '0' and conv_integer(unsigned(dst_PARAM(2 downto 0))) = 4) then
          fu_LSU_PARAM_in2_load_reg <= '1';
        else
          fu_LSU_PARAM_in2_load_reg <= '0';
        end if;
        if (squash_ALU_GCU_TRIG = '0' and conv_integer(unsigned(dst_ALU_GCU_TRIG(5 downto 2))) = 12) then
          fu_gcu_pc_load_reg <= '1';
          fu_gcu_opc_reg <= dst_ALU_GCU_TRIG(0 downto 0);
        else
          fu_gcu_pc_load_reg <= '0';
        end if;
        if (squash_ALU_GCU_TRIG = '0' and conv_integer(unsigned(dst_ALU_GCU_TRIG(5 downto 2))) = 14) then
          fu_gcu_ra_load_reg <= '1';
        else
          fu_gcu_ra_load_reg <= '0';
        end if;

        --control signals for RF inputs
        if (squash_ALU_GCU_TRIG = '0' and conv_integer(unsigned(dst_ALU_GCU_TRIG(5 downto 4))) = 2 and true) then
          rf_RF_wr_load_reg <= '1';
          rf_RF_wr_opc_reg <= dst_ALU_GCU_TRIG(3 downto 0);
          socket_RF_i1_bus_cntrl_reg <= conv_std_logic_vector(1, socket_RF_i1_bus_cntrl_reg'length);
        elsif (squash_LSU_MUL_TRIG = '0' and conv_integer(unsigned(dst_LSU_MUL_TRIG(5 downto 4))) = 0 and true) then
          rf_RF_wr_load_reg <= '1';
          rf_RF_wr_opc_reg <= dst_LSU_MUL_TRIG(3 downto 0);
          socket_RF_i1_bus_cntrl_reg <= conv_std_logic_vector(0, socket_RF_i1_bus_cntrl_reg'length);
        else
          rf_RF_wr_load_reg <= '0';
        end if;
        if (squash_LSU_MUL_TRIG = '0' and conv_integer(unsigned(dst_LSU_MUL_TRIG(5 downto 2))) = 8 and true) then
          rf_BOOL_wr_load_reg <= '1';
          rf_BOOL_wr_opc_reg <= dst_LSU_MUL_TRIG(0 downto 0);
        else
          rf_BOOL_wr_load_reg <= '0';
        end if;
      end if;
    end if;
  end process;

  lock_r <= merged_glock_req;
  merged_glock_req <= lock_req(0);
  pre_decode_merged_glock <= lock or merged_glock_req;
  post_decode_merged_glock <= pre_decode_merged_glock or decode_fill_lock_reg;
  locked <= post_decode_merged_glock;
  glock(0) <= post_decode_merged_glock; -- to LSU
  glock(1) <= post_decode_merged_glock; -- to stdout
  glock(2) <= post_decode_merged_glock; -- to mul
  glock(3) <= post_decode_merged_glock; -- to ALU
  glock(4) <= post_decode_merged_glock; -- to LSU_PARAM
  glock(5) <= post_decode_merged_glock; -- to RF
  glock(6) <= post_decode_merged_glock; -- to BOOL
  glock(7) <= post_decode_merged_glock; -- to IU_1x32
  glock(8) <= post_decode_merged_glock;

  decode_pipeline_fill_lock: process (clk, rstx)
  begin
    if rstx = '0' then
      decode_fill_lock_reg <= '1';
    elsif clk'event and clk = '1' then
      if lock = '0' then
        decode_fill_lock_reg <= '0';
      end if;
    end if;
  end process decode_pipeline_fill_lock;

end rtl_andor;
