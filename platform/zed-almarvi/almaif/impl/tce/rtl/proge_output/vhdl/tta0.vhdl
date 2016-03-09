library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use work.tce_util.all;
use work.tta0_globals.all;
use work.tta0_imem_mau.all;
use work.debugger_if.all;
use work.tta0_params.all;

entity tta0 is

  generic (
    core_id : integer := 0);

  port (
    clk : in std_logic;
    rstx : in std_logic;
    busy : in std_logic;
    imem_en_x : out std_logic;
    imem_addr : out std_logic_vector(IMEMADDRWIDTH-1 downto 0);
    imem_data : in std_logic_vector(IMEMWIDTHINMAUS*IMEMMAUWIDTH-1 downto 0);
    pc_init : in std_logic_vector(IMEMADDRWIDTH-1 downto 0);
    locked : out std_logic;
    fu_LSU_data_in : in std_logic_vector(fu_LSU_dataw-1 downto 0);
    fu_LSU_data_out : out std_logic_vector(fu_LSU_dataw-1 downto 0);
    fu_LSU_addr : out std_logic_vector(fu_LSU_addrw-2-1 downto 0);
    fu_LSU_mem_en_x : out std_logic_vector(0 downto 0);
    fu_LSU_wr_en_x : out std_logic_vector(0 downto 0);
    fu_LSU_wr_mask_x : out std_logic_vector(fu_LSU_dataw-1 downto 0);
    fu_stdout_db_data : out std_logic_vector(fu_stdout_dataw-1 downto 0);
    fu_stdout_db_ndata : out std_logic_vector(fu_stdout_addrw-1 downto 0);
    fu_stdout_db_lockrq : out std_logic_vector(0 downto 0);
    fu_stdout_db_read : in std_logic_vector(0 downto 0);
    fu_stdout_db_nreset : in std_logic_vector(0 downto 0);
    fu_stdout_mem_ena : out std_logic_vector(0 downto 0);
    fu_stdout_mem_enb : out std_logic_vector(0 downto 0);
    fu_stdout_mem_addra : out std_logic_vector(fu_stdout_addrw-1 downto 0);
    fu_stdout_mem_addrb : out std_logic_vector(fu_stdout_addrw-1 downto 0);
    fu_stdout_mem_dia : out std_logic_vector(fu_stdout_dataw-1 downto 0);
    fu_stdout_mem_dob : in std_logic_vector(fu_stdout_dataw-1 downto 0);
    fu_stdout_mem_wea : out std_logic_vector(0 downto 0);
    fu_LSU_PARAM_data_in : in std_logic_vector(fu_LSU_PARAM_dataw-1 downto 0);
    fu_LSU_PARAM_data_out : out std_logic_vector(fu_LSU_PARAM_dataw-1 downto 0);
    fu_LSU_PARAM_addr : out std_logic_vector(fu_LSU_PARAM_addrw-2-1 downto 0);
    fu_LSU_PARAM_mem_en_x : out std_logic_vector(0 downto 0);
    fu_LSU_PARAM_wr_en_x : out std_logic_vector(0 downto 0);
    fu_LSU_PARAM_wr_mask_x : out std_logic_vector(fu_LSU_PARAM_dataw-1 downto 0);
    db_pc_start : in std_logic_vector(IMEMADDRWIDTH-1 downto 0);
    db_pc : out std_logic_vector(IMEMADDRWIDTH-1 downto 0);
    db_bustraces : out std_logic_vector(debreg_data_width_c*debreg_nof_bustraces_c-1 downto 0);
    db_instr : out std_logic_vector(IMEMWIDTHINMAUS*IMEMMAUWIDTH-1 downto 0);
    db_lockcnt : out std_logic_vector(debreg_data_width_c-1 downto 0);
    db_cyclecnt : out std_logic_vector(debreg_data_width_c-1 downto 0);
    db_bp_ena : in std_logic_vector(1+debreg_nof_breakpoints_c-1 downto 0);
    db_bp0 : in std_logic_vector(debreg_data_width_c-1 downto 0);
    db_bp4_1 : in std_logic_vector(debreg_nof_breakpoints_pc_c*IMEMADDRWIDTH-1 downto 0);
    db_bp_hit : out std_logic_vector(2+debreg_nof_breakpoints_c-1 downto 0);
    db_tta_continue : in std_logic;
    db_tta_nreset : in std_logic;
    db_tta_forcebreak : in std_logic;
    db_tta_stdoutbreak : in std_logic);

end tta0;

architecture structural of tta0 is

  signal datapath_gate_BOOL_wr_load_in_wire : std_logic;
  signal datapath_gate_BOOL_wr_load_out_wire : std_logic;
  signal datapath_gate_BOOL_wr_data_in_wire : std_logic_vector(0 downto 0);
  signal datapath_gate_BOOL_wr_data_out_wire : std_logic_vector(0 downto 0);
  signal datapath_gate_RF_wr_load_in_wire : std_logic;
  signal datapath_gate_RF_wr_load_out_wire : std_logic;
  signal datapath_gate_RF_wr_data_in_wire : std_logic_vector(31 downto 0);
  signal datapath_gate_RF_wr_data_out_wire : std_logic_vector(31 downto 0);
  signal dbsm_1_cyclecnt_wire : std_logic_vector(31 downto 0);
  signal dbsm_1_pc_next_wire : std_logic_vector(IMEMADDRWIDTH-1 downto 0);
  signal dbsm_1_bp_lockrq_wire : std_logic;
  signal decomp_fetch_en_wire : std_logic;
  signal decomp_lock_wire : std_logic;
  signal decomp_fetchblock_wire : std_logic_vector(IMEMWIDTHINMAUS*IMEMMAUWIDTH-1 downto 0);
  signal decomp_instructionword_wire : std_logic_vector(INSTRUCTIONWIDTH-1 downto 0);
  signal decomp_glock_wire : std_logic;
  signal decomp_lock_r_wire : std_logic;
  signal fu_ALU_t1data_wire : std_logic_vector(31 downto 0);
  signal fu_ALU_t1load_wire : std_logic;
  signal fu_ALU_r1data_wire : std_logic_vector(31 downto 0);
  signal fu_ALU_o1data_wire : std_logic_vector(31 downto 0);
  signal fu_ALU_o1load_wire : std_logic;
  signal fu_ALU_t1opcode_wire : std_logic_vector(4 downto 0);
  signal fu_ALU_glock_wire : std_logic;
  signal fu_LSU_PARAM_t1data_wire : std_logic_vector(10 downto 0);
  signal fu_LSU_PARAM_t1load_wire : std_logic;
  signal fu_LSU_PARAM_o1data_wire : std_logic_vector(31 downto 0);
  signal fu_LSU_PARAM_o1load_wire : std_logic;
  signal fu_LSU_PARAM_r1data_wire : std_logic_vector(31 downto 0);
  signal fu_LSU_PARAM_t1opcode_wire : std_logic_vector(2 downto 0);
  signal fu_LSU_PARAM_glock_wire : std_logic;
  signal fu_LSU_t1data_wire : std_logic_vector(14 downto 0);
  signal fu_LSU_t1load_wire : std_logic;
  signal fu_LSU_o1data_wire : std_logic_vector(31 downto 0);
  signal fu_LSU_o1load_wire : std_logic;
  signal fu_LSU_r1data_wire : std_logic_vector(31 downto 0);
  signal fu_LSU_t1opcode_wire : std_logic_vector(2 downto 0);
  signal fu_LSU_glock_wire : std_logic;
  signal fu_mul_t1data_wire : std_logic_vector(31 downto 0);
  signal fu_mul_t1load_wire : std_logic;
  signal fu_mul_o1data_wire : std_logic_vector(31 downto 0);
  signal fu_mul_o1load_wire : std_logic;
  signal fu_mul_r1data_wire : std_logic_vector(31 downto 0);
  signal fu_mul_glock_wire : std_logic;
  signal fu_stdout_t1data_wire : std_logic_vector(7 downto 0);
  signal fu_stdout_t1load_wire : std_logic;
  signal fu_stdout_glock_wire : std_logic;
  signal ic_glock_wire : std_logic;
  signal ic_socket_lsu_i1_data_wire : std_logic_vector(14 downto 0);
  signal ic_socket_lsu_o1_data0_wire : std_logic_vector(31 downto 0);
  signal ic_socket_lsu_o1_bus_cntrl_wire : std_logic_vector(2 downto 0);
  signal ic_socket_lsu_i2_data_wire : std_logic_vector(31 downto 0);
  signal ic_socket_RF_i1_data_wire : std_logic_vector(31 downto 0);
  signal ic_socket_RF_i1_bus_cntrl_wire : std_logic_vector(0 downto 0);
  signal ic_socket_RF_o1_data0_wire : std_logic_vector(31 downto 0);
  signal ic_socket_RF_o1_bus_cntrl_wire : std_logic_vector(2 downto 0);
  signal ic_socket_bool_i1_data_wire : std_logic_vector(0 downto 0);
  signal ic_socket_bool_o1_data0_wire : std_logic_vector(0 downto 0);
  signal ic_socket_bool_o1_bus_cntrl_wire : std_logic_vector(2 downto 0);
  signal ic_socket_gcu_i1_data_wire : std_logic_vector(IMEMADDRWIDTH-1 downto 0);
  signal ic_socket_gcu_i2_data_wire : std_logic_vector(IMEMADDRWIDTH-1 downto 0);
  signal ic_socket_gcu_o1_data0_wire : std_logic_vector(IMEMADDRWIDTH-1 downto 0);
  signal ic_socket_gcu_o1_bus_cntrl_wire : std_logic_vector(2 downto 0);
  signal ic_socket_ALU_i1_data_wire : std_logic_vector(31 downto 0);
  signal ic_socket_ALU_i2_data_wire : std_logic_vector(31 downto 0);
  signal ic_socket_ALU_o1_data0_wire : std_logic_vector(31 downto 0);
  signal ic_socket_ALU_o1_bus_cntrl_wire : std_logic_vector(2 downto 0);
  signal ic_socket_IO_i1_data_wire : std_logic_vector(7 downto 0);
  signal ic_socket_IO_i1_bus_cntrl_wire : std_logic_vector(0 downto 0);
  signal ic_socket_IMM_rd_data0_wire : std_logic_vector(31 downto 0);
  signal ic_socket_IMM_rd_bus_cntrl_wire : std_logic_vector(2 downto 0);
  signal ic_socket_MUL_OUT_data0_wire : std_logic_vector(31 downto 0);
  signal ic_socket_MUL_OUT_bus_cntrl_wire : std_logic_vector(2 downto 0);
  signal ic_socket_MUL_IN1_data_wire : std_logic_vector(31 downto 0);
  signal ic_socket_MUL_IN2_data_wire : std_logic_vector(31 downto 0);
  signal ic_socket_lsu_i2_1_data_wire : std_logic_vector(31 downto 0);
  signal ic_socket_lsu_i1_1_data_wire : std_logic_vector(10 downto 0);
  signal ic_socket_lsu_o1_1_data0_wire : std_logic_vector(31 downto 0);
  signal ic_socket_lsu_o1_1_bus_cntrl_wire : std_logic_vector(2 downto 0);
  signal ic_simm_ALU_GCU_TRIG_wire : std_logic_vector(3 downto 0);
  signal ic_simm_cntrl_ALU_GCU_TRIG_wire : std_logic_vector(0 downto 0);
  signal ic_simm_PARAM_wire : std_logic_vector(4 downto 0);
  signal ic_simm_cntrl_PARAM_wire : std_logic_vector(0 downto 0);
  signal ic_simm_LSU_MUL_TRIG_wire : std_logic_vector(2 downto 0);
  signal ic_simm_cntrl_LSU_MUL_TRIG_wire : std_logic_vector(0 downto 0);
  signal inst_decoder_instructionword_wire : std_logic_vector(INSTRUCTIONWIDTH-1 downto 0);
  signal inst_decoder_pc_load_wire : std_logic;
  signal inst_decoder_ra_load_wire : std_logic;
  signal inst_decoder_pc_opcode_wire : std_logic_vector(0 downto 0);
  signal inst_decoder_lock_wire : std_logic;
  signal inst_decoder_lock_r_wire : std_logic;
  signal inst_decoder_simm_ALU_GCU_TRIG_wire : std_logic_vector(3 downto 0);
  signal inst_decoder_simm_cntrl_ALU_GCU_TRIG_wire : std_logic_vector(0 downto 0);
  signal inst_decoder_simm_PARAM_wire : std_logic_vector(4 downto 0);
  signal inst_decoder_simm_cntrl_PARAM_wire : std_logic_vector(0 downto 0);
  signal inst_decoder_simm_LSU_MUL_TRIG_wire : std_logic_vector(2 downto 0);
  signal inst_decoder_simm_cntrl_LSU_MUL_TRIG_wire : std_logic_vector(0 downto 0);
  signal inst_decoder_socket_lsu_o1_bus_cntrl_wire : std_logic_vector(2 downto 0);
  signal inst_decoder_socket_RF_i1_bus_cntrl_wire : std_logic_vector(0 downto 0);
  signal inst_decoder_socket_RF_o1_bus_cntrl_wire : std_logic_vector(2 downto 0);
  signal inst_decoder_socket_bool_o1_bus_cntrl_wire : std_logic_vector(2 downto 0);
  signal inst_decoder_socket_gcu_o1_bus_cntrl_wire : std_logic_vector(2 downto 0);
  signal inst_decoder_socket_ALU_o1_bus_cntrl_wire : std_logic_vector(2 downto 0);
  signal inst_decoder_socket_IO_i1_bus_cntrl_wire : std_logic_vector(0 downto 0);
  signal inst_decoder_socket_IMM_rd_bus_cntrl_wire : std_logic_vector(2 downto 0);
  signal inst_decoder_socket_MUL_OUT_bus_cntrl_wire : std_logic_vector(2 downto 0);
  signal inst_decoder_socket_lsu_o1_1_bus_cntrl_wire : std_logic_vector(2 downto 0);
  signal inst_decoder_fu_LSU_in1t_load_wire : std_logic;
  signal inst_decoder_fu_LSU_in2_load_wire : std_logic;
  signal inst_decoder_fu_LSU_opc_wire : std_logic_vector(2 downto 0);
  signal inst_decoder_fu_stdout_T_load_wire : std_logic;
  signal inst_decoder_fu_mul_in1t_load_wire : std_logic;
  signal inst_decoder_fu_mul_in2_load_wire : std_logic;
  signal inst_decoder_fu_ALU_in1t_load_wire : std_logic;
  signal inst_decoder_fu_ALU_in2_load_wire : std_logic;
  signal inst_decoder_fu_ALU_opc_wire : std_logic_vector(4 downto 0);
  signal inst_decoder_fu_LSU_PARAM_in1t_load_wire : std_logic;
  signal inst_decoder_fu_LSU_PARAM_in2_load_wire : std_logic;
  signal inst_decoder_fu_LSU_PARAM_opc_wire : std_logic_vector(2 downto 0);
  signal inst_decoder_rf_RF_wr_load_wire : std_logic;
  signal inst_decoder_rf_RF_wr_opc_wire : std_logic_vector(3 downto 0);
  signal inst_decoder_rf_RF_rd_load_wire : std_logic;
  signal inst_decoder_rf_RF_rd_opc_wire : std_logic_vector(3 downto 0);
  signal inst_decoder_rf_BOOL_wr_load_wire : std_logic;
  signal inst_decoder_rf_BOOL_wr_opc_wire : std_logic_vector(0 downto 0);
  signal inst_decoder_rf_BOOL_rd_load_wire : std_logic;
  signal inst_decoder_rf_BOOL_rd_opc_wire : std_logic_vector(0 downto 0);
  signal inst_decoder_iu_IU_1x32_r0_read_load_wire : std_logic;
  signal inst_decoder_iu_IU_1x32_r0_read_opc_wire : std_logic_vector(0 downto 0);
  signal inst_decoder_iu_IU_1x32_write_wire : std_logic_vector(31 downto 0);
  signal inst_decoder_iu_IU_1x32_write_load_wire : std_logic;
  signal inst_decoder_iu_IU_1x32_write_opc_wire : std_logic_vector(0 downto 0);
  signal inst_decoder_rf_guard_BOOL_0_wire : std_logic;
  signal inst_decoder_rf_guard_BOOL_1_wire : std_logic;
  signal inst_decoder_lock_req_wire : std_logic_vector(0 downto 0);
  signal inst_decoder_glock_wire : std_logic_vector(8 downto 0);
  signal inst_fetch_ra_out_wire : std_logic_vector(IMEMADDRWIDTH-1 downto 0);
  signal inst_fetch_ra_in_wire : std_logic_vector(IMEMADDRWIDTH-1 downto 0);
  signal inst_fetch_pc_in_wire : std_logic_vector(IMEMADDRWIDTH-1 downto 0);
  signal inst_fetch_pc_load_wire : std_logic;
  signal inst_fetch_ra_load_wire : std_logic;
  signal inst_fetch_pc_opcode_wire : std_logic_vector(0 downto 0);
  signal inst_fetch_fetch_en_wire : std_logic;
  signal inst_fetch_glock_wire : std_logic;
  signal inst_fetch_fetchblock_wire : std_logic_vector(IMEMWIDTHINMAUS*IMEMMAUWIDTH-1 downto 0);
  signal inst_fetch_db_lockreq_wire : std_logic;
  signal inst_fetch_db_pc_next_wire : std_logic_vector(IMEMADDRWIDTH-1 downto 0);
  signal inst_fetch_db_cyclecnt_wire : std_logic_vector(31 downto 0);
  signal iu_IU_1x32_r1data_wire : std_logic_vector(31 downto 0);
  signal iu_IU_1x32_r1load_wire : std_logic;
  signal iu_IU_1x32_r1opcode_wire : std_logic_vector(0 downto 0);
  signal iu_IU_1x32_t1data_wire : std_logic_vector(31 downto 0);
  signal iu_IU_1x32_t1load_wire : std_logic;
  signal iu_IU_1x32_t1opcode_wire : std_logic_vector(0 downto 0);
  signal iu_IU_1x32_guard_wire : std_logic_vector(0 downto 0);
  signal iu_IU_1x32_glock_wire : std_logic;
  signal rf_BOOL_r1data_wire : std_logic_vector(0 downto 0);
  signal rf_BOOL_r1load_wire : std_logic;
  signal rf_BOOL_r1opcode_wire : std_logic_vector(0 downto 0);
  signal rf_BOOL_t1data_wire : std_logic_vector(0 downto 0);
  signal rf_BOOL_t1load_wire : std_logic;
  signal rf_BOOL_t1opcode_wire : std_logic_vector(0 downto 0);
  signal rf_BOOL_guard_wire : std_logic_vector(1 downto 0);
  signal rf_BOOL_glock_wire : std_logic;
  signal rf_RF_r1data_wire : std_logic_vector(31 downto 0);
  signal rf_RF_r1load_wire : std_logic;
  signal rf_RF_r1opcode_wire : std_logic_vector(3 downto 0);
  signal rf_RF_t1data_wire : std_logic_vector(31 downto 0);
  signal rf_RF_t1load_wire : std_logic;
  signal rf_RF_t1opcode_wire : std_logic_vector(3 downto 0);
  signal rf_RF_guard_wire : std_logic_vector(15 downto 0);
  signal rf_RF_glock_wire : std_logic;
  signal ground_signal : std_logic_vector(15 downto 0);

  component tta0_ifetch
    port (
      clk : in std_logic;
      rstx : in std_logic;
      ra_out : out std_logic_vector(IMEMADDRWIDTH-1 downto 0);
      ra_in : in std_logic_vector(IMEMADDRWIDTH-1 downto 0);
      busy : in std_logic;
      imem_en_x : out std_logic;
      imem_addr : out std_logic_vector(IMEMADDRWIDTH-1 downto 0);
      imem_data : in std_logic_vector(IMEMWIDTHINMAUS*IMEMMAUWIDTH-1 downto 0);
      pc_in : in std_logic_vector(IMEMADDRWIDTH-1 downto 0);
      pc_load : in std_logic;
      ra_load : in std_logic;
      pc_opcode : in std_logic_vector(1-1 downto 0);
      fetch_en : in std_logic;
      glock : out std_logic;
      fetchblock : out std_logic_vector(IMEMWIDTHINMAUS*IMEMMAUWIDTH-1 downto 0);
      pc_init : in std_logic_vector(IMEMADDRWIDTH-1 downto 0);
      db_lockreq : in std_logic;
      db_rstx : in std_logic;
      db_pc : out std_logic_vector(IMEMADDRWIDTH-1 downto 0);
      db_pc_next : out std_logic_vector(IMEMADDRWIDTH-1 downto 0);
      db_cyclecnt : out std_logic_vector(32-1 downto 0);
      db_lockcnt : out std_logic_vector(32-1 downto 0));
  end component;

  component tta0_decompressor
    port (
      fetch_en : out std_logic;
      lock : in std_logic;
      fetchblock : in std_logic_vector(IMEMWIDTHINMAUS*IMEMMAUWIDTH-1 downto 0);
      clk : in std_logic;
      rstx : in std_logic;
      instructionword : out std_logic_vector(INSTRUCTIONWIDTH-1 downto 0);
      glock : out std_logic;
      lock_r : in std_logic);
  end component;

  component tta0_decoder
    port (
      instructionword : in std_logic_vector(INSTRUCTIONWIDTH-1 downto 0);
      pc_load : out std_logic;
      ra_load : out std_logic;
      pc_opcode : out std_logic_vector(1-1 downto 0);
      lock : in std_logic;
      lock_r : out std_logic;
      clk : in std_logic;
      rstx : in std_logic;
      locked : out std_logic;
      simm_ALU_GCU_TRIG : out std_logic_vector(4-1 downto 0);
      simm_cntrl_ALU_GCU_TRIG : out std_logic_vector(1-1 downto 0);
      simm_PARAM : out std_logic_vector(5-1 downto 0);
      simm_cntrl_PARAM : out std_logic_vector(1-1 downto 0);
      simm_LSU_MUL_TRIG : out std_logic_vector(3-1 downto 0);
      simm_cntrl_LSU_MUL_TRIG : out std_logic_vector(1-1 downto 0);
      socket_lsu_o1_bus_cntrl : out std_logic_vector(3-1 downto 0);
      socket_RF_i1_bus_cntrl : out std_logic_vector(1-1 downto 0);
      socket_RF_o1_bus_cntrl : out std_logic_vector(3-1 downto 0);
      socket_bool_o1_bus_cntrl : out std_logic_vector(3-1 downto 0);
      socket_gcu_o1_bus_cntrl : out std_logic_vector(3-1 downto 0);
      socket_ALU_o1_bus_cntrl : out std_logic_vector(3-1 downto 0);
      socket_IO_i1_bus_cntrl : out std_logic_vector(1-1 downto 0);
      socket_IMM_rd_bus_cntrl : out std_logic_vector(3-1 downto 0);
      socket_MUL_OUT_bus_cntrl : out std_logic_vector(3-1 downto 0);
      socket_lsu_o1_1_bus_cntrl : out std_logic_vector(3-1 downto 0);
      fu_LSU_in1t_load : out std_logic;
      fu_LSU_in2_load : out std_logic;
      fu_LSU_opc : out std_logic_vector(3-1 downto 0);
      fu_stdout_T_load : out std_logic;
      fu_mul_in1t_load : out std_logic;
      fu_mul_in2_load : out std_logic;
      fu_ALU_in1t_load : out std_logic;
      fu_ALU_in2_load : out std_logic;
      fu_ALU_opc : out std_logic_vector(5-1 downto 0);
      fu_LSU_PARAM_in1t_load : out std_logic;
      fu_LSU_PARAM_in2_load : out std_logic;
      fu_LSU_PARAM_opc : out std_logic_vector(3-1 downto 0);
      rf_RF_wr_load : out std_logic;
      rf_RF_wr_opc : out std_logic_vector(4-1 downto 0);
      rf_RF_rd_load : out std_logic;
      rf_RF_rd_opc : out std_logic_vector(4-1 downto 0);
      rf_BOOL_wr_load : out std_logic;
      rf_BOOL_wr_opc : out std_logic_vector(1-1 downto 0);
      rf_BOOL_rd_load : out std_logic;
      rf_BOOL_rd_opc : out std_logic_vector(1-1 downto 0);
      iu_IU_1x32_r0_read_load : out std_logic;
      iu_IU_1x32_r0_read_opc : out std_logic_vector(0 downto 0);
      iu_IU_1x32_write : out std_logic_vector(32-1 downto 0);
      iu_IU_1x32_write_load : out std_logic;
      iu_IU_1x32_write_opc : out std_logic_vector(0 downto 0);
      rf_guard_BOOL_0 : in std_logic;
      rf_guard_BOOL_1 : in std_logic;
      lock_req : in std_logic_vector(1-1 downto 0);
      glock : out std_logic_vector(9-1 downto 0);
      db_tta_nreset : in std_logic);
  end component;

  component fu_mul_always_2
    generic (
      dataw : integer;
      busw : integer);
    port (
      t1data : in std_logic_vector(dataw-1 downto 0);
      t1load : in std_logic;
      o1data : in std_logic_vector(dataw-1 downto 0);
      o1load : in std_logic;
      r1data : out std_logic_vector(busw-1 downto 0);
      clk : in std_logic;
      rstx : in std_logic;
      glock : in std_logic);
  end component;

  component fu_ldh_ldhu_ldq_ldqu_ldw_sth_stq_stw_always_3
    generic (
      dataw : integer;
      addrw : integer);
    port (
      t1data : in std_logic_vector(addrw-1 downto 0);
      t1load : in std_logic;
      o1data : in std_logic_vector(dataw-1 downto 0);
      o1load : in std_logic;
      r1data : out std_logic_vector(dataw-1 downto 0);
      t1opcode : in std_logic_vector(3-1 downto 0);
      data_in : in std_logic_vector(dataw-1 downto 0);
      data_out : out std_logic_vector(dataw-1 downto 0);
      addr : out std_logic_vector(addrw-2-1 downto 0);
      mem_en_x : out std_logic_vector(1-1 downto 0);
      wr_en_x : out std_logic_vector(1-1 downto 0);
      wr_mask_x : out std_logic_vector(dataw-1 downto 0);
      clk : in std_logic;
      rstx : in std_logic;
      glock : in std_logic);
  end component;

  component fu_abs_add_and_eq_gt_gtu_ior_max_maxu_min_minu_neg_shl_shl1add_shl2add_shr_shru_sub_sxhw_sxqw_xor_always_1
    generic (
      dataw : integer;
      busw : integer;
      shiftw : integer);
    port (
      t1data : in std_logic_vector(dataw-1 downto 0);
      t1load : in std_logic;
      r1data : out std_logic_vector(busw-1 downto 0);
      o1data : in std_logic_vector(dataw-1 downto 0);
      o1load : in std_logic;
      t1opcode : in std_logic_vector(5-1 downto 0);
      clk : in std_logic;
      rstx : in std_logic;
      glock : in std_logic);
  end component;

  component stdout_db
    generic (
      dataw : integer;
      buffd : integer;
      addrw : integer);
    port (
      t1data : in std_logic_vector(dataw-1 downto 0);
      t1load : in std_logic;
      db_data : out std_logic_vector(dataw-1 downto 0);
      db_ndata : out std_logic_vector(addrw-1 downto 0);
      db_lockrq : out std_logic_vector(1-1 downto 0);
      db_read : in std_logic_vector(1-1 downto 0);
      db_nreset : in std_logic_vector(1-1 downto 0);
      mem_ena : out std_logic_vector(1-1 downto 0);
      mem_enb : out std_logic_vector(1-1 downto 0);
      mem_addra : out std_logic_vector(addrw-1 downto 0);
      mem_addrb : out std_logic_vector(addrw-1 downto 0);
      mem_dia : out std_logic_vector(dataw-1 downto 0);
      mem_dob : in std_logic_vector(dataw-1 downto 0);
      mem_wea : out std_logic_vector(1-1 downto 0);
      clk : in std_logic;
      rstx : in std_logic;
      glock : in std_logic);
  end component;

  component rf_1wr_1rd_always_1_guarded_0
    generic (
      dataw : integer;
      rf_size : integer);
    port (
      r1data : out std_logic_vector(dataw-1 downto 0);
      r1load : in std_logic;
      r1opcode : in std_logic_vector(bit_width(rf_size)-1 downto 0);
      t1data : in std_logic_vector(dataw-1 downto 0);
      t1load : in std_logic;
      t1opcode : in std_logic_vector(bit_width(rf_size)-1 downto 0);
      guard : out std_logic_vector(rf_size-1 downto 0);
      clk : in std_logic;
      rstx : in std_logic;
      glock : in std_logic);
  end component;

  component datapath_gate
    generic (
      dataw : integer);
    port (
      load_in : in std_logic;
      load_out : out std_logic;
      data_in : in std_logic_vector(dataw-1 downto 0);
      data_out : out std_logic_vector(dataw-1 downto 0));
  end component;

  component tta0_interconn
    port (
      clk : in std_logic;
      rstx : in std_logic;
      glock : in std_logic;
      socket_lsu_i1_data : out std_logic_vector(15-1 downto 0);
      socket_lsu_o1_data0 : in std_logic_vector(32-1 downto 0);
      socket_lsu_o1_bus_cntrl : in std_logic_vector(3-1 downto 0);
      socket_lsu_i2_data : out std_logic_vector(32-1 downto 0);
      socket_RF_i1_data : out std_logic_vector(32-1 downto 0);
      socket_RF_i1_bus_cntrl : in std_logic_vector(1-1 downto 0);
      socket_RF_o1_data0 : in std_logic_vector(32-1 downto 0);
      socket_RF_o1_bus_cntrl : in std_logic_vector(3-1 downto 0);
      socket_bool_i1_data : out std_logic_vector(1-1 downto 0);
      socket_bool_o1_data0 : in std_logic_vector(1-1 downto 0);
      socket_bool_o1_bus_cntrl : in std_logic_vector(3-1 downto 0);
      socket_gcu_i1_data : out std_logic_vector(IMEMADDRWIDTH-1 downto 0);
      socket_gcu_i2_data : out std_logic_vector(IMEMADDRWIDTH-1 downto 0);
      socket_gcu_o1_data0 : in std_logic_vector(IMEMADDRWIDTH-1 downto 0);
      socket_gcu_o1_bus_cntrl : in std_logic_vector(3-1 downto 0);
      socket_ALU_i1_data : out std_logic_vector(32-1 downto 0);
      socket_ALU_i2_data : out std_logic_vector(32-1 downto 0);
      socket_ALU_o1_data0 : in std_logic_vector(32-1 downto 0);
      socket_ALU_o1_bus_cntrl : in std_logic_vector(3-1 downto 0);
      socket_IO_i1_data : out std_logic_vector(8-1 downto 0);
      socket_IO_i1_bus_cntrl : in std_logic_vector(1-1 downto 0);
      socket_IMM_rd_data0 : in std_logic_vector(32-1 downto 0);
      socket_IMM_rd_bus_cntrl : in std_logic_vector(3-1 downto 0);
      socket_MUL_OUT_data0 : in std_logic_vector(32-1 downto 0);
      socket_MUL_OUT_bus_cntrl : in std_logic_vector(3-1 downto 0);
      socket_MUL_IN1_data : out std_logic_vector(32-1 downto 0);
      socket_MUL_IN2_data : out std_logic_vector(32-1 downto 0);
      socket_lsu_i2_1_data : out std_logic_vector(32-1 downto 0);
      socket_lsu_i1_1_data : out std_logic_vector(11-1 downto 0);
      socket_lsu_o1_1_data0 : in std_logic_vector(32-1 downto 0);
      socket_lsu_o1_1_bus_cntrl : in std_logic_vector(3-1 downto 0);
      simm_ALU_GCU_TRIG : in std_logic_vector(4-1 downto 0);
      simm_cntrl_ALU_GCU_TRIG : in std_logic_vector(1-1 downto 0);
      simm_PARAM : in std_logic_vector(5-1 downto 0);
      simm_cntrl_PARAM : in std_logic_vector(1-1 downto 0);
      simm_LSU_MUL_TRIG : in std_logic_vector(3-1 downto 0);
      simm_cntrl_LSU_MUL_TRIG : in std_logic_vector(1-1 downto 0);
      db_bustraces : out std_logic_vector(debreg_data_width_c*debreg_nof_bustraces_c-1 downto 0));
  end component;

  component dbsm
    generic (
      data_width_g : integer;
      pc_width_g : integer);
    port (
      clk : in std_logic;
      nreset : in std_logic;
      bp_ena : in std_logic_vector(1+debreg_nof_breakpoints_c-1 downto 0);
      bp0 : in std_logic_vector(data_width_g-1 downto 0);
      cyclecnt : in std_logic_vector(data_width_g-1 downto 0);
      bp4_1 : in std_logic_vector(IMEMADDRWIDTH*2-1 downto 0);
      pc_next : in std_logic_vector(IMEMADDRWIDTH-1 downto 0);
      tta_continue : in std_logic;
      tta_forcebreak : in std_logic;
      tta_stdoutbreak : in std_logic;
      bp_hit : out std_logic_vector(5-1 downto 0);
      extlock : in std_logic;
      bp_lockrq : out std_logic);
  end component;


begin

  ic_socket_gcu_o1_data0_wire <= inst_fetch_ra_out_wire;
  inst_fetch_ra_in_wire <= ic_socket_gcu_i2_data_wire;
  inst_fetch_pc_in_wire <= ic_socket_gcu_i1_data_wire;
  inst_fetch_pc_load_wire <= inst_decoder_pc_load_wire;
  inst_fetch_ra_load_wire <= inst_decoder_ra_load_wire;
  inst_fetch_pc_opcode_wire <= inst_decoder_pc_opcode_wire;
  inst_fetch_fetch_en_wire <= decomp_fetch_en_wire;
  decomp_lock_wire <= inst_fetch_glock_wire;
  decomp_fetchblock_wire <= inst_fetch_fetchblock_wire;
  db_instr <= inst_fetch_fetchblock_wire;
  inst_fetch_db_lockreq_wire <= dbsm_1_bp_lockrq_wire;
  dbsm_1_pc_next_wire <= inst_fetch_db_pc_next_wire;
  db_cyclecnt <= inst_fetch_db_cyclecnt_wire;
  dbsm_1_cyclecnt_wire <= inst_fetch_db_cyclecnt_wire;
  inst_decoder_instructionword_wire <= decomp_instructionword_wire;
  inst_decoder_lock_wire <= decomp_glock_wire;
  decomp_lock_r_wire <= inst_decoder_lock_r_wire;
  ic_simm_ALU_GCU_TRIG_wire <= inst_decoder_simm_ALU_GCU_TRIG_wire;
  ic_simm_cntrl_ALU_GCU_TRIG_wire <= inst_decoder_simm_cntrl_ALU_GCU_TRIG_wire;
  ic_simm_PARAM_wire <= inst_decoder_simm_PARAM_wire;
  ic_simm_cntrl_PARAM_wire <= inst_decoder_simm_cntrl_PARAM_wire;
  ic_simm_LSU_MUL_TRIG_wire <= inst_decoder_simm_LSU_MUL_TRIG_wire;
  ic_simm_cntrl_LSU_MUL_TRIG_wire <= inst_decoder_simm_cntrl_LSU_MUL_TRIG_wire;
  ic_socket_lsu_o1_bus_cntrl_wire <= inst_decoder_socket_lsu_o1_bus_cntrl_wire;
  ic_socket_RF_i1_bus_cntrl_wire <= inst_decoder_socket_RF_i1_bus_cntrl_wire;
  ic_socket_RF_o1_bus_cntrl_wire <= inst_decoder_socket_RF_o1_bus_cntrl_wire;
  ic_socket_bool_o1_bus_cntrl_wire <= inst_decoder_socket_bool_o1_bus_cntrl_wire;
  ic_socket_gcu_o1_bus_cntrl_wire <= inst_decoder_socket_gcu_o1_bus_cntrl_wire;
  ic_socket_ALU_o1_bus_cntrl_wire <= inst_decoder_socket_ALU_o1_bus_cntrl_wire;
  ic_socket_IO_i1_bus_cntrl_wire <= inst_decoder_socket_IO_i1_bus_cntrl_wire;
  ic_socket_IMM_rd_bus_cntrl_wire <= inst_decoder_socket_IMM_rd_bus_cntrl_wire;
  ic_socket_MUL_OUT_bus_cntrl_wire <= inst_decoder_socket_MUL_OUT_bus_cntrl_wire;
  ic_socket_lsu_o1_1_bus_cntrl_wire <= inst_decoder_socket_lsu_o1_1_bus_cntrl_wire;
  fu_LSU_t1load_wire <= inst_decoder_fu_LSU_in1t_load_wire;
  fu_LSU_o1load_wire <= inst_decoder_fu_LSU_in2_load_wire;
  fu_LSU_t1opcode_wire <= inst_decoder_fu_LSU_opc_wire;
  fu_stdout_t1load_wire <= inst_decoder_fu_stdout_T_load_wire;
  fu_mul_t1load_wire <= inst_decoder_fu_mul_in1t_load_wire;
  fu_mul_o1load_wire <= inst_decoder_fu_mul_in2_load_wire;
  fu_ALU_t1load_wire <= inst_decoder_fu_ALU_in1t_load_wire;
  fu_ALU_o1load_wire <= inst_decoder_fu_ALU_in2_load_wire;
  fu_ALU_t1opcode_wire <= inst_decoder_fu_ALU_opc_wire;
  fu_LSU_PARAM_t1load_wire <= inst_decoder_fu_LSU_PARAM_in1t_load_wire;
  fu_LSU_PARAM_o1load_wire <= inst_decoder_fu_LSU_PARAM_in2_load_wire;
  fu_LSU_PARAM_t1opcode_wire <= inst_decoder_fu_LSU_PARAM_opc_wire;
  datapath_gate_RF_wr_load_in_wire <= inst_decoder_rf_RF_wr_load_wire;
  rf_RF_t1opcode_wire <= inst_decoder_rf_RF_wr_opc_wire;
  rf_RF_r1load_wire <= inst_decoder_rf_RF_rd_load_wire;
  rf_RF_r1opcode_wire <= inst_decoder_rf_RF_rd_opc_wire;
  datapath_gate_BOOL_wr_load_in_wire <= inst_decoder_rf_BOOL_wr_load_wire;
  rf_BOOL_t1opcode_wire <= inst_decoder_rf_BOOL_wr_opc_wire;
  rf_BOOL_r1load_wire <= inst_decoder_rf_BOOL_rd_load_wire;
  rf_BOOL_r1opcode_wire <= inst_decoder_rf_BOOL_rd_opc_wire;
  iu_IU_1x32_r1load_wire <= inst_decoder_iu_IU_1x32_r0_read_load_wire;
  iu_IU_1x32_r1opcode_wire <= inst_decoder_iu_IU_1x32_r0_read_opc_wire;
  iu_IU_1x32_t1data_wire <= inst_decoder_iu_IU_1x32_write_wire;
  iu_IU_1x32_t1load_wire <= inst_decoder_iu_IU_1x32_write_load_wire;
  iu_IU_1x32_t1opcode_wire <= inst_decoder_iu_IU_1x32_write_opc_wire;
  inst_decoder_rf_guard_BOOL_0_wire <= rf_BOOL_guard_wire(0);
  inst_decoder_rf_guard_BOOL_1_wire <= rf_BOOL_guard_wire(1);
  inst_decoder_lock_req_wire(0) <= dbsm_1_bp_lockrq_wire;
  fu_LSU_glock_wire <= inst_decoder_glock_wire(0);
  fu_stdout_glock_wire <= inst_decoder_glock_wire(1);
  fu_mul_glock_wire <= inst_decoder_glock_wire(2);
  fu_ALU_glock_wire <= inst_decoder_glock_wire(3);
  fu_LSU_PARAM_glock_wire <= inst_decoder_glock_wire(4);
  rf_RF_glock_wire <= inst_decoder_glock_wire(5);
  rf_BOOL_glock_wire <= inst_decoder_glock_wire(6);
  iu_IU_1x32_glock_wire <= inst_decoder_glock_wire(7);
  ic_glock_wire <= inst_decoder_glock_wire(8);
  fu_mul_t1data_wire <= ic_socket_MUL_IN1_data_wire;
  fu_mul_o1data_wire <= ic_socket_MUL_IN2_data_wire;
  ic_socket_MUL_OUT_data0_wire <= fu_mul_r1data_wire;
  fu_LSU_t1data_wire <= ic_socket_lsu_i1_data_wire;
  fu_LSU_o1data_wire <= ic_socket_lsu_i2_data_wire;
  ic_socket_lsu_o1_data0_wire <= fu_LSU_r1data_wire;
  fu_ALU_t1data_wire <= ic_socket_ALU_i1_data_wire;
  ic_socket_ALU_o1_data0_wire <= fu_ALU_r1data_wire;
  fu_ALU_o1data_wire <= ic_socket_ALU_i2_data_wire;
  fu_stdout_t1data_wire <= ic_socket_IO_i1_data_wire;
  fu_LSU_PARAM_t1data_wire <= ic_socket_lsu_i1_1_data_wire;
  fu_LSU_PARAM_o1data_wire <= ic_socket_lsu_i2_1_data_wire;
  ic_socket_lsu_o1_1_data0_wire <= fu_LSU_PARAM_r1data_wire;
  ic_socket_bool_o1_data0_wire <= rf_BOOL_r1data_wire;
  rf_BOOL_t1data_wire <= datapath_gate_BOOL_wr_data_out_wire;
  rf_BOOL_t1load_wire <= datapath_gate_BOOL_wr_load_out_wire;
  datapath_gate_BOOL_wr_data_in_wire <= ic_socket_bool_i1_data_wire;
  ic_socket_RF_o1_data0_wire <= rf_RF_r1data_wire;
  rf_RF_t1data_wire <= datapath_gate_RF_wr_data_out_wire;
  rf_RF_t1load_wire <= datapath_gate_RF_wr_load_out_wire;
  datapath_gate_RF_wr_data_in_wire <= ic_socket_RF_i1_data_wire;
  ic_socket_IMM_rd_data0_wire <= iu_IU_1x32_r1data_wire;
  ground_signal <= (others => '0');

  inst_fetch : tta0_ifetch
    port map (
      clk => clk,
      rstx => rstx,
      ra_out => inst_fetch_ra_out_wire,
      ra_in => inst_fetch_ra_in_wire,
      busy => busy,
      imem_en_x => imem_en_x,
      imem_addr => imem_addr,
      imem_data => imem_data,
      pc_in => inst_fetch_pc_in_wire,
      pc_load => inst_fetch_pc_load_wire,
      ra_load => inst_fetch_ra_load_wire,
      pc_opcode => inst_fetch_pc_opcode_wire,
      fetch_en => inst_fetch_fetch_en_wire,
      glock => inst_fetch_glock_wire,
      fetchblock => inst_fetch_fetchblock_wire,
      pc_init => pc_init,
      db_lockreq => inst_fetch_db_lockreq_wire,
      db_rstx => db_tta_nreset,
      db_pc => db_pc,
      db_pc_next => inst_fetch_db_pc_next_wire,
      db_cyclecnt => inst_fetch_db_cyclecnt_wire,
      db_lockcnt => db_lockcnt);

  decomp : tta0_decompressor
    port map (
      fetch_en => decomp_fetch_en_wire,
      lock => decomp_lock_wire,
      fetchblock => decomp_fetchblock_wire,
      clk => clk,
      rstx => rstx,
      instructionword => decomp_instructionword_wire,
      glock => decomp_glock_wire,
      lock_r => decomp_lock_r_wire);

  inst_decoder : tta0_decoder
    port map (
      instructionword => inst_decoder_instructionword_wire,
      pc_load => inst_decoder_pc_load_wire,
      ra_load => inst_decoder_ra_load_wire,
      pc_opcode => inst_decoder_pc_opcode_wire,
      lock => inst_decoder_lock_wire,
      lock_r => inst_decoder_lock_r_wire,
      clk => clk,
      rstx => rstx,
      locked => locked,
      simm_ALU_GCU_TRIG => inst_decoder_simm_ALU_GCU_TRIG_wire,
      simm_cntrl_ALU_GCU_TRIG => inst_decoder_simm_cntrl_ALU_GCU_TRIG_wire,
      simm_PARAM => inst_decoder_simm_PARAM_wire,
      simm_cntrl_PARAM => inst_decoder_simm_cntrl_PARAM_wire,
      simm_LSU_MUL_TRIG => inst_decoder_simm_LSU_MUL_TRIG_wire,
      simm_cntrl_LSU_MUL_TRIG => inst_decoder_simm_cntrl_LSU_MUL_TRIG_wire,
      socket_lsu_o1_bus_cntrl => inst_decoder_socket_lsu_o1_bus_cntrl_wire,
      socket_RF_i1_bus_cntrl => inst_decoder_socket_RF_i1_bus_cntrl_wire,
      socket_RF_o1_bus_cntrl => inst_decoder_socket_RF_o1_bus_cntrl_wire,
      socket_bool_o1_bus_cntrl => inst_decoder_socket_bool_o1_bus_cntrl_wire,
      socket_gcu_o1_bus_cntrl => inst_decoder_socket_gcu_o1_bus_cntrl_wire,
      socket_ALU_o1_bus_cntrl => inst_decoder_socket_ALU_o1_bus_cntrl_wire,
      socket_IO_i1_bus_cntrl => inst_decoder_socket_IO_i1_bus_cntrl_wire,
      socket_IMM_rd_bus_cntrl => inst_decoder_socket_IMM_rd_bus_cntrl_wire,
      socket_MUL_OUT_bus_cntrl => inst_decoder_socket_MUL_OUT_bus_cntrl_wire,
      socket_lsu_o1_1_bus_cntrl => inst_decoder_socket_lsu_o1_1_bus_cntrl_wire,
      fu_LSU_in1t_load => inst_decoder_fu_LSU_in1t_load_wire,
      fu_LSU_in2_load => inst_decoder_fu_LSU_in2_load_wire,
      fu_LSU_opc => inst_decoder_fu_LSU_opc_wire,
      fu_stdout_T_load => inst_decoder_fu_stdout_T_load_wire,
      fu_mul_in1t_load => inst_decoder_fu_mul_in1t_load_wire,
      fu_mul_in2_load => inst_decoder_fu_mul_in2_load_wire,
      fu_ALU_in1t_load => inst_decoder_fu_ALU_in1t_load_wire,
      fu_ALU_in2_load => inst_decoder_fu_ALU_in2_load_wire,
      fu_ALU_opc => inst_decoder_fu_ALU_opc_wire,
      fu_LSU_PARAM_in1t_load => inst_decoder_fu_LSU_PARAM_in1t_load_wire,
      fu_LSU_PARAM_in2_load => inst_decoder_fu_LSU_PARAM_in2_load_wire,
      fu_LSU_PARAM_opc => inst_decoder_fu_LSU_PARAM_opc_wire,
      rf_RF_wr_load => inst_decoder_rf_RF_wr_load_wire,
      rf_RF_wr_opc => inst_decoder_rf_RF_wr_opc_wire,
      rf_RF_rd_load => inst_decoder_rf_RF_rd_load_wire,
      rf_RF_rd_opc => inst_decoder_rf_RF_rd_opc_wire,
      rf_BOOL_wr_load => inst_decoder_rf_BOOL_wr_load_wire,
      rf_BOOL_wr_opc => inst_decoder_rf_BOOL_wr_opc_wire,
      rf_BOOL_rd_load => inst_decoder_rf_BOOL_rd_load_wire,
      rf_BOOL_rd_opc => inst_decoder_rf_BOOL_rd_opc_wire,
      iu_IU_1x32_r0_read_load => inst_decoder_iu_IU_1x32_r0_read_load_wire,
      iu_IU_1x32_r0_read_opc => inst_decoder_iu_IU_1x32_r0_read_opc_wire,
      iu_IU_1x32_write => inst_decoder_iu_IU_1x32_write_wire,
      iu_IU_1x32_write_load => inst_decoder_iu_IU_1x32_write_load_wire,
      iu_IU_1x32_write_opc => inst_decoder_iu_IU_1x32_write_opc_wire,
      rf_guard_BOOL_0 => inst_decoder_rf_guard_BOOL_0_wire,
      rf_guard_BOOL_1 => inst_decoder_rf_guard_BOOL_1_wire,
      lock_req => inst_decoder_lock_req_wire,
      glock => inst_decoder_glock_wire,
      db_tta_nreset => db_tta_nreset);

  fu_mul : fu_mul_always_2
    generic map (
      dataw => 32,
      busw => 32)
    port map (
      t1data => fu_mul_t1data_wire,
      t1load => fu_mul_t1load_wire,
      o1data => fu_mul_o1data_wire,
      o1load => fu_mul_o1load_wire,
      r1data => fu_mul_r1data_wire,
      clk => clk,
      rstx => rstx,
      glock => fu_mul_glock_wire);

  fu_LSU : fu_ldh_ldhu_ldq_ldqu_ldw_sth_stq_stw_always_3
    generic map (
      dataw => fu_LSU_dataw,
      addrw => fu_LSU_addrw)
    port map (
      t1data => fu_LSU_t1data_wire,
      t1load => fu_LSU_t1load_wire,
      o1data => fu_LSU_o1data_wire,
      o1load => fu_LSU_o1load_wire,
      r1data => fu_LSU_r1data_wire,
      t1opcode => fu_LSU_t1opcode_wire,
      data_in => fu_LSU_data_in,
      data_out => fu_LSU_data_out,
      addr => fu_LSU_addr,
      mem_en_x => fu_LSU_mem_en_x,
      wr_en_x => fu_LSU_wr_en_x,
      wr_mask_x => fu_LSU_wr_mask_x,
      clk => clk,
      rstx => rstx,
      glock => fu_LSU_glock_wire);

  fu_ALU : fu_abs_add_and_eq_gt_gtu_ior_max_maxu_min_minu_neg_shl_shl1add_shl2add_shr_shru_sub_sxhw_sxqw_xor_always_1
    generic map (
      dataw => 32,
      busw => 32,
      shiftw => 5)
    port map (
      t1data => fu_ALU_t1data_wire,
      t1load => fu_ALU_t1load_wire,
      r1data => fu_ALU_r1data_wire,
      o1data => fu_ALU_o1data_wire,
      o1load => fu_ALU_o1load_wire,
      t1opcode => fu_ALU_t1opcode_wire,
      clk => clk,
      rstx => rstx,
      glock => fu_ALU_glock_wire);

  fu_stdout : stdout_db
    generic map (
      dataw => fu_stdout_dataw,
      buffd => 1024,
      addrw => fu_stdout_addrw)
    port map (
      t1data => fu_stdout_t1data_wire,
      t1load => fu_stdout_t1load_wire,
      db_data => fu_stdout_db_data,
      db_ndata => fu_stdout_db_ndata,
      db_lockrq => fu_stdout_db_lockrq,
      db_read => fu_stdout_db_read,
      db_nreset => fu_stdout_db_nreset,
      mem_ena => fu_stdout_mem_ena,
      mem_enb => fu_stdout_mem_enb,
      mem_addra => fu_stdout_mem_addra,
      mem_addrb => fu_stdout_mem_addrb,
      mem_dia => fu_stdout_mem_dia,
      mem_dob => fu_stdout_mem_dob,
      mem_wea => fu_stdout_mem_wea,
      clk => clk,
      rstx => rstx,
      glock => fu_stdout_glock_wire);

  fu_LSU_PARAM : fu_ldh_ldhu_ldq_ldqu_ldw_sth_stq_stw_always_3
    generic map (
      dataw => fu_LSU_PARAM_dataw,
      addrw => fu_LSU_PARAM_addrw)
    port map (
      t1data => fu_LSU_PARAM_t1data_wire,
      t1load => fu_LSU_PARAM_t1load_wire,
      o1data => fu_LSU_PARAM_o1data_wire,
      o1load => fu_LSU_PARAM_o1load_wire,
      r1data => fu_LSU_PARAM_r1data_wire,
      t1opcode => fu_LSU_PARAM_t1opcode_wire,
      data_in => fu_LSU_PARAM_data_in,
      data_out => fu_LSU_PARAM_data_out,
      addr => fu_LSU_PARAM_addr,
      mem_en_x => fu_LSU_PARAM_mem_en_x,
      wr_en_x => fu_LSU_PARAM_wr_en_x,
      wr_mask_x => fu_LSU_PARAM_wr_mask_x,
      clk => clk,
      rstx => rstx,
      glock => fu_LSU_PARAM_glock_wire);

  rf_BOOL : rf_1wr_1rd_always_1_guarded_0
    generic map (
      dataw => 1,
      rf_size => 2)
    port map (
      r1data => rf_BOOL_r1data_wire,
      r1load => rf_BOOL_r1load_wire,
      r1opcode => rf_BOOL_r1opcode_wire,
      t1data => rf_BOOL_t1data_wire,
      t1load => rf_BOOL_t1load_wire,
      t1opcode => rf_BOOL_t1opcode_wire,
      guard => rf_BOOL_guard_wire,
      clk => clk,
      rstx => rstx,
      glock => rf_BOOL_glock_wire);

  datapath_gate_BOOL_wr : datapath_gate
    generic map (
      dataw => 1)
    port map (
      load_in => datapath_gate_BOOL_wr_load_in_wire,
      load_out => datapath_gate_BOOL_wr_load_out_wire,
      data_in => datapath_gate_BOOL_wr_data_in_wire,
      data_out => datapath_gate_BOOL_wr_data_out_wire);

  rf_RF : rf_1wr_1rd_always_1_guarded_0
    generic map (
      dataw => 32,
      rf_size => 16)
    port map (
      r1data => rf_RF_r1data_wire,
      r1load => rf_RF_r1load_wire,
      r1opcode => rf_RF_r1opcode_wire,
      t1data => rf_RF_t1data_wire,
      t1load => rf_RF_t1load_wire,
      t1opcode => rf_RF_t1opcode_wire,
      guard => rf_RF_guard_wire,
      clk => clk,
      rstx => rstx,
      glock => rf_RF_glock_wire);

  datapath_gate_RF_wr : datapath_gate
    generic map (
      dataw => 32)
    port map (
      load_in => datapath_gate_RF_wr_load_in_wire,
      load_out => datapath_gate_RF_wr_load_out_wire,
      data_in => datapath_gate_RF_wr_data_in_wire,
      data_out => datapath_gate_RF_wr_data_out_wire);

  iu_IU_1x32 : rf_1wr_1rd_always_1_guarded_0
    generic map (
      dataw => 32,
      rf_size => 1)
    port map (
      r1data => iu_IU_1x32_r1data_wire,
      r1load => iu_IU_1x32_r1load_wire,
      r1opcode => iu_IU_1x32_r1opcode_wire,
      t1data => iu_IU_1x32_t1data_wire,
      t1load => iu_IU_1x32_t1load_wire,
      t1opcode => iu_IU_1x32_t1opcode_wire,
      guard => iu_IU_1x32_guard_wire,
      clk => clk,
      rstx => rstx,
      glock => iu_IU_1x32_glock_wire);

  ic : tta0_interconn
    port map (
      clk => clk,
      rstx => rstx,
      glock => ic_glock_wire,
      socket_lsu_i1_data => ic_socket_lsu_i1_data_wire,
      socket_lsu_o1_data0 => ic_socket_lsu_o1_data0_wire,
      socket_lsu_o1_bus_cntrl => ic_socket_lsu_o1_bus_cntrl_wire,
      socket_lsu_i2_data => ic_socket_lsu_i2_data_wire,
      socket_RF_i1_data => ic_socket_RF_i1_data_wire,
      socket_RF_i1_bus_cntrl => ic_socket_RF_i1_bus_cntrl_wire,
      socket_RF_o1_data0 => ic_socket_RF_o1_data0_wire,
      socket_RF_o1_bus_cntrl => ic_socket_RF_o1_bus_cntrl_wire,
      socket_bool_i1_data => ic_socket_bool_i1_data_wire,
      socket_bool_o1_data0 => ic_socket_bool_o1_data0_wire,
      socket_bool_o1_bus_cntrl => ic_socket_bool_o1_bus_cntrl_wire,
      socket_gcu_i1_data => ic_socket_gcu_i1_data_wire,
      socket_gcu_i2_data => ic_socket_gcu_i2_data_wire,
      socket_gcu_o1_data0 => ic_socket_gcu_o1_data0_wire,
      socket_gcu_o1_bus_cntrl => ic_socket_gcu_o1_bus_cntrl_wire,
      socket_ALU_i1_data => ic_socket_ALU_i1_data_wire,
      socket_ALU_i2_data => ic_socket_ALU_i2_data_wire,
      socket_ALU_o1_data0 => ic_socket_ALU_o1_data0_wire,
      socket_ALU_o1_bus_cntrl => ic_socket_ALU_o1_bus_cntrl_wire,
      socket_IO_i1_data => ic_socket_IO_i1_data_wire,
      socket_IO_i1_bus_cntrl => ic_socket_IO_i1_bus_cntrl_wire,
      socket_IMM_rd_data0 => ic_socket_IMM_rd_data0_wire,
      socket_IMM_rd_bus_cntrl => ic_socket_IMM_rd_bus_cntrl_wire,
      socket_MUL_OUT_data0 => ic_socket_MUL_OUT_data0_wire,
      socket_MUL_OUT_bus_cntrl => ic_socket_MUL_OUT_bus_cntrl_wire,
      socket_MUL_IN1_data => ic_socket_MUL_IN1_data_wire,
      socket_MUL_IN2_data => ic_socket_MUL_IN2_data_wire,
      socket_lsu_i2_1_data => ic_socket_lsu_i2_1_data_wire,
      socket_lsu_i1_1_data => ic_socket_lsu_i1_1_data_wire,
      socket_lsu_o1_1_data0 => ic_socket_lsu_o1_1_data0_wire,
      socket_lsu_o1_1_bus_cntrl => ic_socket_lsu_o1_1_bus_cntrl_wire,
      simm_ALU_GCU_TRIG => ic_simm_ALU_GCU_TRIG_wire,
      simm_cntrl_ALU_GCU_TRIG => ic_simm_cntrl_ALU_GCU_TRIG_wire,
      simm_PARAM => ic_simm_PARAM_wire,
      simm_cntrl_PARAM => ic_simm_cntrl_PARAM_wire,
      simm_LSU_MUL_TRIG => ic_simm_LSU_MUL_TRIG_wire,
      simm_cntrl_LSU_MUL_TRIG => ic_simm_cntrl_LSU_MUL_TRIG_wire,
      db_bustraces => db_bustraces);

  dbsm_1 : dbsm
    generic map (
      data_width_g => 32,
      pc_width_g => IMEMADDRWIDTH)
    port map (
      clk => clk,
      nreset => rstx,
      bp_ena => db_bp_ena,
      bp0 => db_bp0,
      cyclecnt => dbsm_1_cyclecnt_wire,
      bp4_1 => db_bp4_1,
      pc_next => dbsm_1_pc_next_wire,
      tta_continue => db_tta_continue,
      tta_forcebreak => db_tta_forcebreak,
      tta_stdoutbreak => db_tta_stdoutbreak,
      bp_hit => db_bp_hit,
      extlock => busy,
      bp_lockrq => dbsm_1_bp_lockrq_wire);

end structural;
