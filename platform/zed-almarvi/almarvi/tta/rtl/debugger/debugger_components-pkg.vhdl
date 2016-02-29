library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use work.debugger_if.all;
use work.register_pkg.all;

package debugger_components is

    component debugger
    generic (
      data_width_g    : integer;
      addr_width_g    : integer;
      nof_bustraces_g : integer;
      stdout_dataw_g  : integer;
      stdout_buffd_g  : integer;
      use_cdc_g       : boolean);
    port ( 
      nreset       : in  std_logic;
      clk_fpga     : in  std_logic;
      wen_fpga     : in  std_logic;
      ren_fpga     : in  std_logic;
      addr_fpga    : in  std_logic_vector(addr_width_g-1 downto 0);
      din_fpga     : in  std_logic_vector(data_width_g-1 downto 0);
      dout_fpga    : out std_logic_vector(data_width_g-1 downto 0);
      dv_fpga      : out std_logic;
      clk_tta      : in  std_logic;
      pc_start     : out std_logic_vector(pc_width_c-1 downto 0);
      pc           : in  std_logic_vector(pc_width_c-1 downto 0);
      bustraces    : in  std_logic_vector(nof_bustraces_g*data_width_g-1
                                          downto 0);
      lockcnt      : in  std_logic_vector(data_width_g-1 downto 0);

      cyclecnt     : in  std_logic_vector(data_width_g-1 downto 0);
      flags        : in  std_logic_vector(data_width_g-1 downto 0);
      bp_ena       : out std_logic_vector(5 downto 0);
      bp0          : out std_logic_vector(data_width_g-1 downto 0);
      bp4_1        : out std_logic_vector(4*pc_width_c-1 downto 0);
      bp_hit       : in  std_logic_vector(6 downto 0);
      tta_continue : out std_logic;
      tta_nreset   : out std_logic;
      tta_forcebreak : out std_logic;
      irq          : out std_logic;
      busy         : out std_logic;
      imem_page    : out std_logic_vector(data_width_g-1 downto 0);
      imem_mask    : out std_logic_vector(data_width_g-1 downto 0);
      dmem_page    : out std_logic_vector(data_width_g-1 downto 0);
      dmem_mask    : out std_logic_vector(data_width_g-1 downto 0);
      icache_invalidate : out std_logic;
      dcache_invalidate : out std_logic;
      axi_burst_cnt     : in std_logic_vector(3*32-1 downto 0);
      axi_err_cnt       : in std_logic_vector(3*32-1 downto 0);
      db_stdout_d       : in std_logic_vector(stdout_dataw_g-1 downto 0);
      db_stdout_n       : in std_logic_vector(
                          integer(ceil(log2(real(stdout_buffd_g+1))))-1 downto 0);
      db_stdout_read    : out std_logic
    );
  end component;

  component dbsm
    generic (
      data_width_g : integer;
      pc_width_g   : integer);
    port (
      clk          : in  std_logic;
      nreset       : in  std_logic;
      bp_ena       : in  std_logic_vector(5 downto 0);
      bp0          : in  std_logic_vector(data_width_g-1 downto 0);
      cyclecnt     : in  std_logic_vector(data_width_g-1 downto 0);
      bp4_1        : in  std_logic_vector(4*pc_width_c-1 downto 0);
      pc_next      : in  std_logic_vector(pc_width_c-1 downto 0);
      tta_continue : in  std_logic;
      tta_forcebreak : in std_logic;
      tta_stdoutbreak : in std_logic;
      bp_hit       : out std_logic_vector(6 downto 0);
      bp_lockrq    : out std_logic;
      extlock      : in std_logic
    );
  end component;

end debugger_components;
