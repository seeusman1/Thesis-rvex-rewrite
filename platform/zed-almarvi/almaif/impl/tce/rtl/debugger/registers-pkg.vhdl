-------------------------------------------------------------------------------
-- Title      : Debugger register bank definitions
-- Project    :
-------------------------------------------------------------------------------
-- File       : registers-pkg.vhdl
-- Author     : Tommi Zetterman  <tommi.zetterman@nokia.com>
-- Company    : Nokia Research Center
-- Created    : 2013-03-18
-- Last update: 2015-10-06
-- Platform   :
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- Copyright (c) 2013 Nokia Research Center
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2013-03-18  1.0      zetterma Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.debugger_if.all;

package register_pkg is

  -----------------------------------------------------------------------------
  -- program counter width
  constant pc_width_c : integer := debreg_pc_width_c;
  -- status registers
  constant nof_status_registers_c : integer := 13;
  -- single registers
  constant TTA_STATUS       : integer := 0;
  constant TTA_PC           : integer := 1;
  constant TTA_CYCLECNT     : integer := 2;
  constant TTA_LOCKCNT      : integer := 3;
  constant TTA_FLAGS        : integer := 4;
  constant AXI_RD0_BURSTCNT : integer := 5;
  constant AXI_RD1_BURSTCNT : integer := 6;
  constant AXI_WR_BURSTCNT  : integer := 7;
  constant AXI_RD0_ERRCNT   : integer := 8;
  constant AXI_RD1_ERRCNT   : integer := 9;
  constant AXI_WR_ERRCNT    : integer := 10;
  constant TTA_STDOUT_D     : integer := 11;
  constant TTA_STDOUT_N     : integer := 12;

  -- control_registers
  constant control_addresspace_start_c : integer := 2**7;
  constant nof_control_registers_c     : integer := 11;

  constant TTA_DEBUG_CMD  : integer := 0 + control_addresspace_start_c;
  constant TTA_PC_START   : integer := 1 + control_addresspace_start_c;
  constant TTA_DEBUG_BP0  : integer := 2 + control_addresspace_start_c;
  constant TTA_DEBUG_BP1  : integer := 3 + control_addresspace_start_c;
  constant TTA_DEBUG_BP2  : integer := 4 + control_addresspace_start_c;
  --constant TTA_DEBUG_BP3  : integer := 4 + control_addresspace_start_c;
  --constant TTA_DEBUG_BP4  : integer := 5 + control_addresspace_start_c;
  constant TTA_DEBUG_CTRL : integer := 5 + control_addresspace_start_c;
  constant TTA_IRQMASK    : integer := 6 + control_addresspace_start_c;
  constant TTA_IMEM_PAGE  : integer := 7 + control_addresspace_start_c;
  constant TTA_IMEM_MASK  : integer := 8 + control_addresspace_start_c;
  constant TTA_DMEM_PAGE  : integer := 9 + control_addresspace_start_c;
  constant TTA_DMEM_MASK  : integer := 10 + control_addresspace_start_c;

  constant info_addresspace_start_c : integer := 2**7 + 2**6;

  -- info registers space: 0xC0..0xff
  constant TTA_DEVICECLASS      : integer := 0 + info_addresspace_start_c;
  constant TTA_DEVICE_ID        : integer := 1 + info_addresspace_start_c;
  constant TTA_INTERFACE_TYPE   : integer := 2 + info_addresspace_start_c;
  constant TTA_DMEM_SIZE        : integer := 3 + info_addresspace_start_c;
  constant TTA_PMEM_SIZE        : integer := 4 + info_addresspace_start_c;
  constant TTA_IMEM_SIZE        : integer := 5 + info_addresspace_start_c;
  
  -- debugger command bits
  constant DEBUG_CMD_RESET    : integer := 0;
  constant DEBUG_CMD_CONTINUE : integer := 1;
  constant DEBUG_CMD_BREAK    : integer := 2;
  constant DEBUG_CMD_INVALIDATE_ICACHE : integer := 3;
  constant DEBUG_CMD_INVALIDATE_DCACHE : integer := 4;
  -- bus trace registers (placed in address space after status registers)
  constant bustrace_width_c : integer := 32;

  -----------------------------------------------------------------------------
  -- Register definition helper type
  -----------------------------------------------------------------------------
  type regdef_t is
  record
    reg : integer;
    bits : integer;
  end record;
  type registers_t is array (integer range <>) of regdef_t;

  -----------------------------------------------------------------------------
  -- Status register definitions
  -----------------------------------------------------------------------------
  constant status_registers_c : registers_t(0 to nof_status_registers_c-1)
    := ( (reg => TTA_STATUS,       bits => 6),
         (reg => TTA_PC,           bits => pc_width_c),
         (reg => TTA_CYCLECNT,     bits => 32),
         (reg => TTA_LOCKCNT,      bits => 32),
         (reg => TTA_FLAGS,        bits => 32),
         (reg => AXI_RD1_BURSTCNT, bits => 32),
         (reg => AXI_RD0_BURSTCNT, bits => 32),
         (reg => AXI_WR_BURSTCNT,  bits => 32),
         (reg => AXI_RD1_ERRCNT,   bits => 32),
         (reg => AXI_RD0_ERRCNT,   bits => 32),
         (reg => AXI_WR_ERRCNT,    bits => 32),
         (reg => TTA_STDOUT_D,     bits => 8),
         (reg => TTA_STDOUT_N,     bits => debreg_stdout_addrw_c)
   );

  -----------------------------------------------------------------------------
  -- Control register definitions
  -----------------------------------------------------------------------------
  constant control_registers_c : registers_t(control_addresspace_start_c to
                                               control_addresspace_start_c
                                               + nof_control_registers_c-1)
    := ( (reg => TTA_DEBUG_CMD,  bits => 1),  -- continue- and break bits is not registred
         (reg => TTA_PC_START,   bits => pc_width_c),
         (reg => TTA_DEBUG_BP0,  bits => 32),
         (reg => TTA_DEBUG_BP1,  bits => pc_width_c),
         (reg => TTA_DEBUG_BP2,  bits => pc_width_c),
         (reg => TTA_DEBUG_CTRL, bits => 12),
         (reg => TTA_IRQMASK,    bits => 32),
         (reg => TTA_IMEM_PAGE,  bits => 32),
         (reg => TTA_IMEM_MASK,  bits => 32),
         (reg => TTA_DMEM_PAGE,  bits => 32),
         (reg => TTA_DMEM_MASK,  bits => 32)
   );

end register_pkg;
