library ieee;
use ieee.std_logic_1164.all;

use work.tta0_globals.all;
use work.tce_util.all;
use work.tta0_params.all;

package debugger_if is

  constant debreg_data_width_c : integer := 32;
  constant debreg_addr_width_c : integer := 8;
  constant debreg_nof_bustraces_c : integer := 3;
  constant debreg_inswidth_c : integer := IMEMDATAWIDTH;
  constant debreg_nof_breakpoints_c : integer := 3;
  constant debreg_nof_breakpoints_pc_c : integer := 2;
  constant debreg_pc_width_c : integer := IMEMADDRWIDTH;
  constant debreg_stdout_addrw_c : integer := 10;  -- 1024 words
  
  -- TTA INFO

  -- Pad instruction to next power-of-two
  constant debinfo_imem_dataw_bytes   : integer := bit_width(IMEMDATAWIDTH)-3;
  constant debinfo_imem_addrw         : integer := IMEMADDRWIDTH + debinfo_imem_dataw_bytes;
  constant debinfo_dmem_addrw         : integer := fu_LSU_addrw;
  constant debinfo_pmem_addrw         : integer := fu_LSU_PARAM_addrw;

  constant debinfo_deviceclass_c      : integer := 16#774#;
  constant debinfo_device_id_c        : integer := 16#12345678#;
  constant debinfo_interface_type_c   : integer := 16#0#;
  --constant debinfo_dmem_start_c       : integer := 16#41040000#;
  constant debinfo_dmem_size_c        : integer := 2**debinfo_dmem_addrw;
  --constant debinfo_pmem_start_c       : integer := 16#41040000#;
  constant debinfo_pmem_size_c        : integer := 2**debinfo_pmem_addrw;
  --constant debinfo_imem_start_c       : integer := 16#41000000#;
  constant debinfo_imem_size_c        : integer := 2**debinfo_imem_addrw;
  
end debugger_if;
