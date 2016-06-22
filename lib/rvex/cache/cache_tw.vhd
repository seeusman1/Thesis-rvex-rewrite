-- r-VEX processor MMU
-- Copyright (C) 2008-2016 by TU Delft.
-- All Rights Reserved.

-- THIS IS A LEGAL DOCUMENT, BY USING r-VEX,
-- YOU ARE AGREEING TO THESE TERMS AND CONDITIONS.

-- No portion of this work may be used by any commercial entity, or for any
-- commercial purpose, without the prior, written permission of TU Delft.
-- Nonprofit and noncommercial use is permitted as described below.

-- 1. r-VEX is provided AS IS, with no warranty of any kind, express
-- or implied. The user of the code accepts full responsibility for the
-- application of the code and the use of any results.

-- 2. Nonprofit and noncommercial use is encouraged. r-VEX may be
-- downloaded, compiled, synthesized, copied, and modified solely for nonprofit,
-- educational, noncommercial research, and noncommercial scholarship
-- purposes provided that this notice in its entirety accompanies all copies.
-- Copies of the modified software can be delivered to persons who use it
-- solely for nonprofit, educational, noncommercial research, and
-- noncommercial scholarship purposes provided that this notice in its
-- entirety accompanies all copies.

-- 3. ALL COMMERCIAL USE, AND ALL USE BY FOR PROFIT ENTITIES, IS EXPRESSLY
-- PROHIBITED WITHOUT A LICENSE FROM TU Delft (J.S.S.M.Wong@tudelft.nl).

-- 4. No nonprofit user may place any restrictions on the use of this software,
-- including as modified by the user, by any other authorized user.

-- 5. Noncommercial and nonprofit users may distribute copies of r-VEX
-- in compiled or binary form as set forth in Section 2, provided that
-- either: (A) it is accompanied by the corresponding machine-readable source
-- code, or (B) it is accompanied by a written offer, with no time limit, to
-- give anyone a machine-readable copy of the corresponding source code in
-- return for reimbursement of the cost of distribution. This written offer
-- must permit verbatim duplication by anyone, or (C) it is distributed by
-- someone who received only the executable form, and is accompanied by a
-- copy of the written offer of source code.

-- 6. r-VEX was developed by Stephan Wong, Thijs van As, Fakhar Anjam,
-- Roel Seedorf, Anthony Brandon, Jeroen van Straten. r-VEX is currently
-- maintained by TU Delft (J.S.S.M.Wong@tudelft.nl).

-- 7. The MMU was created by Jens Johansen.

-- Copyright (C) 2008-2016 by TU Delft.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library rvex;
use rvex.common_pkg.all;
use rvex.core_pkg.all;
use rvex.cache_pkg.all;
use rvex.bus_pkg.all;

--=============================================================================
-- This entity serves as the table walker for the r-VEX memory management unit.
-- The table format is roughly equivalent to x86-32. Major
-- differences/pitfalls:
--
--  - The r-VEX has an additional flag for executable pages, similar to the NX
--    bit in x86 with PAE or above. This bit must be explicitly enabled through
--    a control register though, so by default this bit can be used by the OS.
--
--  - The C and W flags work somewhat differently. First of all, the table
--    walker always bypasses the cache (because we only have a L1 cache), thus
--    the flags in the page directory are don't for page table base pointer
--    entries. Secondly, the memory types are somewhat different in general:
--
--      C W |
--     -----+---------------------------------------------------------------
--      0 0 | write-back (if supported): local data without auto. coherency
--      0 1 | write-through: shared data
--      1 - | uncacheable: peripherals
--
--    The big difference is that x86 is coherent in all modes!
--
--  - The r-VEX has design-time configurable page sizes. They are the same as
--    x86-32 by default only.
--
-- The page directory and table entries have the following formats:
--
-- |-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-| ----------
-- |        Large page ptag        ::::::::::::|X|G|1|D|A|C|W|U|R|1|
-- |-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|    Page
-- |        Page table base        ::::::::::::|X|-|0|-|A|-|-|U|R|1| directory
-- |-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|  entries
-- |                              -                              |0|
-- |-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-| ----------
-- |        Normal page ptag       ::::::::::::|X|G|-|D|A|C|W|U|R|1|    Page
-- |-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|   table
-- |                              -                              |0|  entries
-- |-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-|-+-+-+-+-+-+-+-| ----------
--                                              | | | | | | | | | |
-- Entry flag documentation:                    X G S D A C W U R P
--  - P: present. If 0, the rest of the entry   | | | | | | | | | '-> Present
--    is ignored by the table walker.           | | | | | | | | '-> wRitable
--  - R: writable. If 0, the page is            | | | | | | | '-> User
--    read-only; if 1, it is read-write. If     | | | | | | '-> Write-through
--    rv2mmu_writeProtect is low, this is only  | | | | | '-> Cache disable
--    enforced in user mode; if it is high,     | | | | '-> Accessed
--    kernel writes to read-only pages also     | | | '-> Dirty
--    result in a fault.                        | | '-> page Size
--  - U: user/kernel. If 0, the page can only   | '-> Global
--    be accessed in kernel mode; if 1, it      '-> eXecutable
--    must use write-through. Contrary to
--    x86-32 though, the cache is NOT necessarily coherent in write-back mode.
--    This is intended to be used for local data.
--  - C: cache disable. If 0, the cache is enabled; if 1, the cache is
--    bypassed. The latter is intended for peripherals.
--  - A: accessed. If 0, this bit is set when it was accessed by the table
--    walker, and the access did not result in a page fault.
--  - D: dirty. If 0, this bit is set when a write to the page is requested,
--    and this write did not result in a page fault.
--  - S: page size. Used to distinguish between a large page and a page table
--    in the page directory.
--  - G: global. If rv2mmu_globalPageEnable is high, this bit selects between
--    normal pages (0) and global pages (1). The difference is that the ASID
--    match in the TLB is disabled for global pages. If rv2mmu_globalPageEnable
--    is low (default), the bit is freely usable by the operating system.
--  - X: executable. If rv2mmu_executableEnable is high, this bit determines
--    whether this page is executable (1) or not (0). That is, if a non
--    executable page is accessed by the instruction port, a protection trap is
--    generated. If rv2mmu_writeProtect is low (default), the bit is freely
--    usable by the operating system.
--
-- The tag area that is actually used depends on the page sizes:
--  - Large page ptag uses 32 - 2**largePageSizeLog2 bits
--  - Page table base uses 30 - 2**(largePageSizeLog2-pageSizeLog2) bits
--  - Normal page ptag uses 32 - 2**pageSizeLog2 bits
-- They are MSB-aligned. Unused bits are freely usable by the OS. The table
-- sizes are:
--  - Page directory: 2**(32-largePageSizeLog2) 32-bit words
--  - Page table: 2**(largePageSizeLog2-pageSizeLog2) 32-bit words
-- With the default settings (page size 4 kiB and large page size 4 MiB) the
-- layout equals x86-32.
-------------------------------------------------------------------------------
entity cache_tw is
--=============================================================================
  generic (
    
    -- Configuration.
    RCFG                        : rvex_generic_config_type := rvex_cfg;
    CCFG                        : cache_generic_config_type := cache_cfg
    
  );
  port (

    ---------------------------------------------------------------------------
    -- System control
    ---------------------------------------------------------------------------
    -- Active high synchronous reset input.
    reset                       : in  std_logic;
    
    -- Clock input, registers are rising edge triggered.
    clk                         : in  std_logic;
    
    -- Active high global clock enable input.
    clkEn                       : in  std_logic
    
    
    -- TODO
    -- rv2mmu_writeProtect!
    -- rv2mmu_globalPageEnable!
    -- rv2mmu_executableEnable!
    
  );
end cache_tw;

--=============================================================================
architecture behavioural of cache_tw is
--=============================================================================

--=============================================================================
begin -- architecture
--=============================================================================

end architecture; -- arch
