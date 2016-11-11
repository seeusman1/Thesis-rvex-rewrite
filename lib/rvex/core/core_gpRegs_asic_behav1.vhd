-- r-VEX processor
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

-- Copyright (C) 2008-2016 by TU Delft.

--=============================================================================
-- Type package.
--=============================================================================
library ieee;
use ieee.std_logic_1164.all;

package core_gpRegs_asic_behav1_types is
  
  subtype bitvec2 is std_logic_vector(1 downto 0);
  subtype bitvec3 is std_logic_vector(2 downto 0);
  subtype bitvec4 is std_logic_vector(3 downto 0);
  subtype bitvec5 is std_logic_vector(4 downto 0);
  subtype bitvec6 is std_logic_vector(5 downto 0);
  subtype bitvec7 is std_logic_vector(6 downto 0);
  subtype bitvec8 is std_logic_vector(7 downto 0);
  subtype bitvec16 is std_logic_vector(15 downto 0);
  subtype bitvec32 is std_logic_vector(31 downto 0);
  subtype bitvec63 is std_logic_vector(63 downto 1);
  subtype bitvec64 is std_logic_vector(63 downto 0);
  subtype bitvec128 is std_logic_vector(127 downto 0);
  
  type bitvec2_array is array (natural range <>) of bitvec2;
  type bitvec3_array is array (natural range <>) of bitvec3;
  type bitvec4_array is array (natural range <>) of bitvec4;
  type bitvec5_array is array (natural range <>) of bitvec5;
  type bitvec6_array is array (natural range <>) of bitvec6;
  type bitvec7_array is array (natural range <>) of bitvec7;
  type bitvec8_array is array (natural range <>) of bitvec8;
  type bitvec16_array is array (natural range <>) of bitvec16;
  type bitvec32_array is array (natural range <>) of bitvec32;
  type bitvec63_array is array (natural range <>) of bitvec63;
  type bitvec64_array is array (natural range <>) of bitvec64;
  type bitvec128_array is array (natural range <>) of bitvec128;
  
  -- Read port types.
  subtype bitvec6_vec16 is bitvec6_array(15 downto 0);
  subtype bitvec32_vec16 is bitvec32_array(15 downto 0);
  type bitvec6_vec16_array is array (natural range <>) of bitvec6_vec16;
  type bitvec32_vec16_array is array (natural range <>) of bitvec32_vec16;
  
  -- Write port types.
  subtype bitvec6_vec8 is bitvec6_array(7 downto 0);
  subtype bitvec32_vec8 is bitvec32_array(7 downto 0);
  type bitvec6_vec8_array is array (natural range <>) of bitvec6_vec8;
  type bitvec32_vec8_array is array (natural range <>) of bitvec32_vec8;
  
end core_gpRegs_asic_behav1_types;

package body core_gpRegs_asic_behav1_types is
end core_gpRegs_asic_behav1_types;

--=============================================================================
-- Read port logic.
--=============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library rvex;
use rvex.core_pkg.all;
use rvex.core_gpRegs_asic_behav1_types.all;

entity core_gpRegs_asic_behav1_readPort is
  generic (
    CFG                         : rvex_generic_config_type;
    DBG_OVR                     : boolean
  );
  port (
    clk                         : in  std_logic;
    stall                       : in  std_logic;
    
    -- Read port command.
    prt_enable                  : in  std_logic;
    prt_addr                    : in  bitvec6;
    prt_ctxt                    : in  bitvec3;
    
    -- Debug bus override port command. Only used when DBG_OVR is set.
    dbg_enable                  : in  std_logic;
    dbg_addr                    : in  bitvec6;
    dbg_ctxt                    : in  bitvec3;
    
    -- Gated addresses for each context.
    reg_addr                    : out bitvec6_array(2**CFG.numContextsLog2-1 downto 0);
    
    -- Non-gated addresses for the forwarding logic.
    fwd_addr                    : out bitvec6
    
  );
end core_gpRegs_asic_behav1_readPort;

architecture behavioral of core_gpRegs_asic_behav1_readPort is
  signal addr                   : bitvec6;
  signal ctxt                   : bitvec3;
begin
  
  -- Handle ports that allow debug bus accesses.
  with_debug_override_gen: if DBG_OVR generate
    reg_proc: process (clk) is
    begin
      if rising_edge(clk) then
        if dbg_enable = '1' then
          addr <= dbg_addr;
          ctxt <= dbg_ctxt;
        elsif prt_enable = '1' and stall = '0' then
          addr <= prt_addr;
          ctxt <= prt_ctxt;
        end if;
      end if;
    end process;
  end generate;
  
  -- Handle ports that do not allow debug bus accesses.
  without_debug_override_gen: if not DBG_OVR generate
    reg_proc: process (clk) is
    begin
      if rising_edge(clk) then
        if prt_enable = '1' and stall = '0' then
          addr <= prt_addr;
        end if;
      end if;
    end process;
    
    -- The context bits never change during a read, so they don't need to be
    -- registered.
    ctxt <= prt_ctxt;
    
  end generate;
  
  -- Drive the forwarding address outputs.
  fwd_addr <= addr;
  
  -- Drive the register file address outputs.
  addr_reg_proc: process (addr, ctxt) is
  begin
    if CFG.numContextsLog2 = 0 then
      reg_addr(0) <= addr;
    else
      for c in 0 to 2**CFG.numContextsLog2-1 loop
        if to_integer(unsigned(ctxt(CFG.numContextsLog2-1 downto 0))) = c then
          reg_addr(c) <= addr;
        else
          reg_addr(c) <= "000000";
        end if;
      end loop;
    end if;
  end process;
  
end behavioral;

--=============================================================================
-- Write port logic.
--=============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library rvex;
use rvex.core_pkg.all;
use rvex.core_gpRegs_asic_behav1_types.all;

entity core_gpRegs_asic_behav1_writePort is
  generic (
    CFG                         : rvex_generic_config_type;
    DBG_OVR                     : boolean;
    
    -- Enables/disables placing AND gates in the logic paths for write
    -- data/address to the individual context blocks. This increases area but
    -- should decrease power, as switching activity for the disabled
    -- context/port pairs is nullified.
    GATE_DATA                   : boolean := true;
    GATE_ADDR                   : boolean := true;
    
    -- Enables/disables placing latches in the logic path for write
    -- data/address, preventing switching activity for cycles where no write is
    -- performed. These latches are inferred once for all contexts, and are
    -- thus placed before the AND gates (if enabled).
    LATCH_DATA                  : boolean := true;
    LATCH_ADDR                  : boolean := true
    
  );
  port (
    stall                       : in  std_logic;
    
    -- Read port command.
    prt_enable                  : in  std_logic;
    prt_addr                    : in  bitvec6;
    prt_ctxt                    : in  bitvec3;
    prt_data                    : in  bitvec32;
    
    -- Debug bus override port command. Only used when DBG_OVR is set.
    dbg_enable                  : in  std_logic;
    dbg_addr                    : in  bitvec6;
    dbg_ctxt                    : in  bitvec3;
    dbg_data                    : in  bitvec32;
    
    -- Gated addresses and enables for each context.
    reg_enable                  : out std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
    reg_addr                    : out bitvec6_array(2**CFG.numContextsLog2-1 downto 0);
    reg_data                    : out bitvec32_array(2**CFG.numContextsLog2-1 downto 0)
    
  );
end core_gpRegs_asic_behav1_writePort;

architecture behavioral of core_gpRegs_asic_behav1_writePort is
  signal enable                 : std_logic;
  signal addr, addr_l           : bitvec6;
  signal ctxt                   : bitvec3;
  signal data, data_l           : bitvec32;
begin
  
  -- Handle ports that allow debug bus accesses.
  dbg_ovr_proc: process (
    dbg_enable, dbg_addr, dbg_ctxt, dbg_data,
    prt_enable, prt_addr, prt_ctxt, prt_data, stall
  ) is
  begin
    if DBG_OVR and dbg_enable = '1' then
      enable <= '1';
      addr   <= dbg_addr;
      ctxt   <= dbg_ctxt;
      data   <= dbg_data;
    else
      enable <= prt_enable and not stall;
      addr   <= prt_addr;
      ctxt   <= prt_ctxt;
      data   <= prt_data;
    end if;
  end process;
  
  -- Infer the addr/data latches, if specified.
  addr_latch_proc: process (enable, addr) is
  begin
    if enable = '1' or not LATCH_ADDR then
      addr_l <= addr;
    end if;
  end process;
  data_latch_proc: process (enable, data) is
  begin
    if enable = '1' or not LATCH_DATA then
      data_l <= data;
    end if;
  end process;
  
  -- Drive the register file address outputs.
  addr_reg_proc: process (enable, addr_l, ctxt, data_l) is
  begin
    if CFG.numContextsLog2 = 0 then
      reg_enable(0) <= enable;
      reg_addr(0) <= addr_l;
      reg_data(0) <= data_l;
    else
      for c in 0 to 2**CFG.numContextsLog2-1 loop
        reg_enable(c) <= enable;
        reg_addr(c) <= addr_l;
        reg_data(c) <= data_l;
        if to_integer(unsigned(ctxt(CFG.numContextsLog2-1 downto 0))) /= c then
          reg_enable(c) <= '0';
          if GATE_ADDR then
            reg_addr(c) <= "000000";
          end if;
          if GATE_DATA then
            reg_data(c) <= X"00000000";
          end if;
        end if;
      end loop;
    end if;
  end process;
  
end behavioral;

--=============================================================================
-- 3-bit address decoder for a single context and port.
--=============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library rvex;
use rvex.core_pkg.all;
use rvex.core_gpRegs_asic_behav1_types.all;

entity core_gpRegs_asic_behav1_decoder3 is
  port (
    enable                      : in  std_logic;
    addr                        : in  bitvec3;
    decoded                     : out bitvec8
  );
end core_gpRegs_asic_behav1_decoder3;

architecture behavioral of core_gpRegs_asic_behav1_decoder3 is
begin
  decoder_proc: process (enable, addr) is
  begin
    for i in 0 to 7 loop
      if to_integer(unsigned(addr)) = i then
        decoded(i) <= enable;
      else
        decoded(i) <= '0';
      end if;
    end loop;
  end process;
end behavioral;

--=============================================================================
-- 6-bit address decoder for a single context and port.
--=============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library rvex;
use rvex.core_pkg.all;
use rvex.core_gpRegs_asic_behav1_types.all;

entity core_gpRegs_asic_behav1_decoder6 is
  port (
    enable                      : in  std_logic;
    addr                        : in  bitvec6;
    decoded                     : out bitvec64
  );
end core_gpRegs_asic_behav1_decoder6;

architecture behavioral of core_gpRegs_asic_behav1_decoder6 is
  signal intermediate           : bitvec8;
  
  -- These attributes should tell synopsis to not optimize accross these
  -- signals.
  attribute DONT_TOUCH_NETWORK : boolean;
  attribute DONT_TOUCH_NETWORK of intermediate : signal is true;
  
begin
  
  -- Try to hint to the synthesizer that it can implement such a decoder in a
  -- nicely uniform way using two levels. Here's level 1. Note that it gets the
  -- LSBs instead of the MSBs. My gut feeling says that this will be more
  -- energy efficient, as the LSBs are more likely to switch than the MSBs if a
  -- program does not need many registers. By doing it this way, the 3 MSBs
  -- have to be routed all over the register file to get the the level 2
  -- decoders, while the 3 LSBs only have to go to the level 1 decoder. The
  -- intermediate signals don't have to go everywhere, and will also switch
  -- less often than the 3 LSBs of the address, so this seems win-win to me.
  lvl1: entity rvex.core_gpRegs_asic_behav1_decoder3
    port map (
      enable  => enable,
      addr    => addr(2 downto 0),
      decoded => intermediate
    );
  
  -- And here's level 2.
  lvl2_gen: for i in 0 to 7 generate
    signal decoded_local  : bitvec8;
  begin
    lvl2_x: entity rvex.core_gpRegs_asic_behav1_decoder3
      port map (
        enable  => intermediate(i),
        addr    => addr(5 downto 3),
        decoded => decoded_local
      );
    
    -- To make signal naming sane, interleave the enable signals to negate the
    -- effect of using the LSBs for decoding first.
    output_gen: for j in 0 to 7 generate
      decoded(i + j*8) <= decoded_local(j);
    end generate;
    
  end generate;
  
end behavioral;

--=============================================================================
-- Read port multiplexer for a single context and port.
--=============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library rvex;
use rvex.core_pkg.all;
use rvex.core_gpRegs_asic_behav1_types.all;

entity core_gpRegs_asic_behav1_readMux is
  port (
    enables                     : in  bitvec64;
    datas                       : in  bitvec32_array(1 to 63);
    data                        : out bitvec32
  );
end core_gpRegs_asic_behav1_readMux;

architecture behavioral of core_gpRegs_asic_behav1_readMux is
  signal lvl1   : bitvec32_array(31 downto 0);
  signal lvl2   : bitvec32_array(7 downto 0);
  signal lvl3   : bitvec32_array(1 downto 0);
  
  -- These attributes should tell synopsis to not optimize accross these
  -- signals.
  attribute DONT_TOUCH_NETWORK : boolean;
  attribute DONT_TOUCH_NETWORK of lvl1, lvl2, lvl3 : signal is true;
  
begin
  
  -- Try to get the synthesizer to make a uniform multiplexer. The intended
  -- cells are:
  --   In   -> lvl1: AOI22 (2:1, A=2.52) or ND2 (1:1, A=1.44) for $r0.0
  --   lvl1 -> lvl2: ND4 (4:1, A=2.52)
  --   lvl2 -> lvl3: NR4 (4:1, A=2.52)
  --   lvl3 -> lvl3: ND2 (2:1, A=1.44)
  -- Area = 31*AOI22 + 1*ND2  + 8*ND4  + 2*NR4  + 1*ND2
  --      = 31*2.52  + 1*1.44 + 8*2.52 + 2*2.52 + 1*1.44
  --      = 106.2 um^2 (per bit, minimum size)
  
  lvl1_proc: process (enables, datas) is
    variable a, b : bitvec32;
  begin
    for i in 0 to 31 loop
      if enables(i*2+1) = '1' then
        a := datas(i*2+1);
      else
        a := X"00000000";
      end if;
      if i > 0 then
        if enables(i*2) = '1' then
          b := datas(i*2);
        else
          b := X"00000000";
        end if;
        a := a or b;
      end if;
      lvl1(i) <= not a;
    end loop;
  end process;
  
  lvl2_proc: process (lvl1) is
  begin
    for i in 0 to 7 loop
      lvl2(i) <= not (lvl1(i*4+0) and lvl1(i*4+1) and lvl1(i*4+2) and lvl1(i*4+3));
    end loop;
  end process;
  
  lvl3_proc: process (lvl2) is
  begin
    for i in 0 to 1 loop
      lvl3(i) <= not (lvl2(i*4+0) or lvl2(i*4+1) or lvl2(i*4+2) or lvl2(i*4+3));
    end loop;
  end process;
  
  data <= lvl3(0) nand lvl3(1);
  
end behavioral;

--=============================================================================
-- Register file for a single context.
--=============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library rvex;
use rvex.core_pkg.all;
use rvex.core_gpRegs_asic_behav1_types.all;

entity core_gpRegs_asic_behav1_regFile is
  generic (
    CFG                         : rvex_generic_config_type
  );
  port (
    clk                         : in  std_logic;
    readAddr                    : in  bitvec6_vec16;
    readData                    : out bitvec32_vec16;
    writeEnable                 : in  bitvec8;
    writeAddr                   : in  bitvec6_vec8;
    writeData                   : in  bitvec32_vec8
  );
end core_gpRegs_asic_behav1_regFile;

architecture behavioral of core_gpRegs_asic_behav1_regFile is
  
  -- One-hot decoded read and write enable signals.
  signal writeEnable_oh : bitvec64_array(2**CFG.numLanesLog2-1 downto 0);
  
  -- The actual registers.
  signal regs           : bitvec32_array(1 to 63);
  
begin
  
  -- Decode the write addresses and enables.
  write_dec_gen: for prt in 2**CFG.numLanesLog2-1 downto 0 generate
    write_dec_x: entity rvex.core_gpRegs_asic_behav1_decoder6
      port map (
        enable  => writeEnable(prt),
        addr    => writeAddr(prt),
        decoded => writeEnable_oh(prt)
      );
  end generate;
  
  -- Handle writes to the register file using bitwise OR to combine
  -- simultaneous writes.
  reg_write_gen : for addr in 1 to 63 generate
    reg_proc: process (clk) is
      variable wren : std_logic;
      variable data : bitvec32;
    begin
      if rising_edge(clk) then
        wren := '0';
        data := X"00000000";
        for prt in 0 to 2**CFG.numLanesLog2-1 loop
          if writeEnable_oh(prt)(addr) = '1' then
            wren := '1';
            data := data or writeData(prt);
          end if;
        end loop;
        if wren = '1' then
          regs(addr) <= data;
        end if;
      end if;
    end process;
  end generate;
  
  -- Generate the read ports.
  read_dec_gen: for prt in 2*2**CFG.numLanesLog2-1 downto 0 generate
    signal readEnable_oh  : bitvec64;
  begin
    
    -- Decode the read addresses.
    read_dec_x: entity rvex.core_gpRegs_asic_behav1_decoder6
      port map (
        enable  => '1',
        addr    => readAddr(prt),
        decoded => readEnable_oh
      );
    
    -- Instantiate the read port multiplexers.
    read_mux_x: entity rvex.core_gpRegs_asic_behav1_readMux
      port map (
        enables => readEnable_oh,
        datas   => regs,
        data    => readData(prt)
      );
    
  end generate;
  
end behavioral;

--=============================================================================
-- Forwarding logic for a single pipeline stage.
--=============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library rvex;
use rvex.core_pkg.all;
use rvex.core_gpRegs_asic_behav1_types.all;

entity core_gpRegs_asic_behav1_fwdStage is
  generic (
    CFG                         : rvex_generic_config_type
  );
  port (
    coupled                     : in  std_logic_vector(4**CFG.numLaneGroupsLog2-1 downto 0);
    fwd_enable                  : in  bitvec8;
    fwd_addr                    : in  bitvec6_vec8;
    fwd_data                    : in  bitvec32_vec8;
    read_addr                   : in  bitvec6_vec16;
    read_data_in                : in  bitvec32_vec16;
    read_data_out               : out bitvec32_vec16
  );
end core_gpRegs_asic_behav1_fwdStage;

architecture behavioral of core_gpRegs_asic_behav1_fwdStage is
begin
  
  -- Generate the same logic for every read port.
  read_port_gen: for rprt in 0 to 2*2**CFG.numLanesLog2-1 generate
    signal match      : bitvec8;
    signal any_match  : std_logic;
  begin
    
    -- Instantiate the address matching and decoupling logic for each
    -- read/write port pair.
    match_proc: process (coupled, fwd_enable, fwd_addr, read_addr) is
      variable match_v      : std_logic;
      variable any_match_v  : std_logic;
    begin
      any_match_v := '0';
      for wprt in 0 to 2**CFG.numLanesLog2-1 loop
        if fwd_addr(wprt) = read_addr(rprt) then
          match_v := fwd_enable(wprt) and coupled(
            lane2group(wprt, CFG) * 2**CFG.numLaneGroupsLog2 +
            lane2group(rprt/2, CFG)
          );
        else
          match_v := '0';
        end if;
        match(wprt) <= match_v;
        
        -- Keep track of whether there is any match at all. This determines
        -- whether we need to override the data from the next stage or not.
        any_match_v := any_match_v or match_v;
      end loop;
      any_match <= any_match_v;
    end process;
    
    -- Merge the data from the next stage with the forwarded data from this
    -- stage.
    merge_proc: process (any_match, match, read_data_in, fwd_data) is
      variable x    : bitvec32;
      variable data : bitvec32;
    begin
      
      -- If there is no match, we take the data from the previous stage. We
      -- don't need a full mux for the selection because we know that the
      -- forwarded data from this stage is always zero if no data is forwarded.
      if any_match = '1' then
        data := X"00000000";
      else
        data := read_data_in(rprt);
      end if;
      
      -- Merge the matching data signals together using bitwise OR. Under normal
      -- circumstances only zero or one bits of match are active at a time.
      for wprt in 0 to 2**CFG.numLanesLog2-1 loop
        if match(wprt) = '1' then
          x := fwd_data(wprt);
        else
          x := X"00000000";
        end if;
        data := data or x;
      end loop;
      
      -- Assign the output.
      read_data_out(rprt) <= data;
      
    end process;
    
  end generate;
  
end behavioral;

--=============================================================================
-- Adapter for the standard-cell-based general purpose register file for the
-- ASIC.
--=============================================================================
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

library rvex;
use rvex.common_pkg.all;
use rvex.utils_pkg.all;
use rvex.core_pkg.all;
use rvex.core_intIface_pkg.all;
use rvex.core_pipeline_pkg.all;
use rvex.core_gpRegs_asic_behav1_types.all;
-- pragma translate_off
use rvex.simUtils_pkg.all;
-- pragma translate_on

--=============================================================================
entity core_gpRegs_asic_behav1 is
--=============================================================================
  generic (
    
    -- Configuration.
    CFG                         : rvex_generic_config_type
    
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
    clkEn                       : in  std_logic;
    
    -- Active high stall signal for each lane group.
    stall                       : in  std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);

    -----------------------------------------------------------------------------
    -- Decoded configuration signals
    -----------------------------------------------------------------------------
    -- Diagonal block matrix of n*n size, where n is the number of pipelane
    -- groups. C_i,j is high when pipelane groups i and j are coupled/share a
    -- context, or low when they don't.
    cfg2any_coupled             : in  std_logic_vector(4**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Specifies the context associated with the indexed pipelane group.
    cfg2any_context             : in  rvex_3bit_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -----------------------------------------------------------------------------
    -- Read and write ports
    -----------------------------------------------------------------------------
    -- Read ports. There's two for each lane. The read value is provided for all
    -- lanes which receive forwarding information.
    pl2gpreg_readPorts          : in  pl2gpreg_readPort_array(2*2**CFG.numLanesLog2-1 downto 0);
    gpreg2pl_readPorts          : out gpreg2pl_readPort_array(2*2**CFG.numLanesLog2-1 downto 0);
    
    -- Write ports and forwarding information. There's one write port for each
    -- lane.
    pl2gpreg_writePorts         : in  pl2gpreg_writePort_array(2**CFG.numLanesLog2-1 downto 0);
    
    ---------------------------------------------------------------------------
    -- Debug interface
    ---------------------------------------------------------------------------
    -- When claim is high (and stall is high, which will always be the case)
    -- one of the processor ports should be connected to the port below.
    creg2gpreg_claim            : in  std_logic;
    
    -- Register address and context.
    creg2gpreg_addr             : in  rvex_gpRegAddr_type;
    creg2gpreg_ctxt             : in  std_logic_vector(CFG.numContextsLog2-1 downto 0);
    
    -- Write command.
    creg2gpreg_writeEnable      : in  std_logic;
    creg2gpreg_writeData        : in  rvex_data_type;
    
    -- Read data returned one cycle after the claim.
    gpreg2creg_readData         : out rvex_data_type
    
  );
end core_gpRegs_asic_behav1;

--=============================================================================
architecture Behavioral of core_gpRegs_asic_behav1 is
--=============================================================================
  
  -- Combined clkEn/stall signal for each lane group.
  signal stall_buf              : bitvec4;
  
  -- Whether the debug bus override is enabled.
  signal dbg_ctxt               : bitvec3;
  signal dbg_readEnable         : std_logic;
  signal dbg_writeEnable        : std_logic;
  
  -- Register file write port signals.
  signal reg_writeEnable        : bitvec8_array(2**CFG.numContextsLog2-1 downto 0);
  signal reg_writeAddr          : bitvec6_vec8_array(2**CFG.numContextsLog2-1 downto 0);
  signal reg_writeData          : bitvec32_vec8_array(2**CFG.numContextsLog2-1 downto 0);
  
  -- Register file read port signals.
  signal reg_readAddr           : bitvec6_vec16_array(2**CFG.numContextsLog2-1 downto 0);
  signal reg_readData           : bitvec32_vec16_array(2**CFG.numContextsLog2-1 downto 0);
  
  -- Read addresses for the forwarding logic.
  signal fwd_readAddr           : bitvec6_vec16;
  signal fwd_readData           : bitvec32_vec16_array(S_WB+1 downto S_RD+L_RD+1);
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -- Make sure that our assumptions about the core configuration parameters are
  -- correct.
  assert L_WB = 0
    report "The register file writeback latency should be set to 0 for the " &
    "ASIC implementation." severity warning;
  
  assert L_RD = 1
    report "The ASIC implementation of the register file requires that L_RD " &
    "= 1." severity failure;
  
  assert S_RD+L_RD = S_FW
    report "Only one set of forwarding destinations is supported by the " &
    "ASIC register file implementation." severity failure;
  
  assert CFG.numLanesLog2 <= 3
    report "The ASIC implementation of the register file supports at most 8" &
    "lanes." severity failure;
  
  -- Buffer the stall signals and merge them with clkEn.
  stall_buf_proc: process (stall, clkEn) is
  begin
    for grp in 0 to 3 loop
      stall_buf(grp) <= stall(grp) or not clkEn;
    end loop;
  end process;
  
  -- Generate the raw read and write enable signals from the debug bus.
  dbg_readEnable <= creg2gpreg_claim and clkEn and not creg2gpreg_writeEnable;
  dbg_writeEnable <= creg2gpreg_claim and clkEn and creg2gpreg_writeEnable;
  dbg_ctxt(CFG.numContextsLog2-1 downto 0) <= creg2gpreg_ctxt;
  
  -- Instantiate the read port command preprocessing logic.
  read_port_gen: for prt in 2*2**CFG.numLanesLog2-1 downto 0 generate
    signal reg_addr_local   : bitvec6_array(2**CFG.numContextsLog2-1 downto 0);
  begin
    
    -- Instantiate the port.
    read_port_x: entity rvex.core_gpRegs_asic_behav1_readPort
      generic map (
        CFG                     => CFG,
        DBG_OVR                 => prt = 0
      )
      port map (
        clk                     => clk,
        stall                   => stall_buf(lane2group(prt/2, CFG)),
        prt_enable              => pl2gpreg_readPorts(prt).readEnable(S_RD),
        prt_addr                => pl2gpreg_readPorts(prt).addr(S_RD),
        prt_ctxt                => cfg2any_context(lane2group(prt/2, CFG)),
        dbg_enable              => dbg_readEnable,
        dbg_addr                => creg2gpreg_addr,
        dbg_ctxt                => dbg_ctxt,
        reg_addr                => reg_addr_local,
        fwd_addr                => fwd_readAddr(prt)
      );
    
    -- Connect the command signals.
    connect_gen: for ctxt in 2**CFG.numContextsLog2-1 downto 0 generate
      reg_readAddr(ctxt)(prt) <= reg_addr_local(ctxt);
    end generate;
    
  end generate;
  
  -- Instantiate the write port command preprocessing logic.
  write_port_gen: for prt in 2**CFG.numLanesLog2-1 downto 0 generate
    signal reg_enable_local : std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
    signal reg_addr_local   : bitvec6_array(2**CFG.numContextsLog2-1 downto 0);
    signal reg_data_local   : bitvec32_array(2**CFG.numContextsLog2-1 downto 0);
  begin
    
    -- Instantiate the port.
    write_port_x: entity rvex.core_gpRegs_asic_behav1_writePort
      generic map (
        CFG                     => CFG,
        DBG_OVR                 => prt = 0,
        GATE_DATA               => true,
        GATE_ADDR               => true,
        LATCH_DATA              => true,
        LATCH_ADDR              => true
      )
      port map (
        stall                   => stall_buf(lane2group(prt, CFG)),
        prt_enable              => pl2gpreg_writePorts(prt).writeEnable(S_WB),
        prt_addr                => pl2gpreg_writePorts(prt).addr(S_WB),
        prt_ctxt                => cfg2any_context(lane2group(prt, CFG)),
        prt_data                => pl2gpreg_writePorts(prt).data(S_WB),
        dbg_enable              => dbg_writeEnable,
        dbg_addr                => creg2gpreg_addr,
        dbg_ctxt                => dbg_ctxt,
        dbg_data                => creg2gpreg_writeData,
        reg_enable              => reg_enable_local,
        reg_addr                => reg_addr_local,
        reg_data                => reg_data_local
      );
    
    -- Connect the command signals.
    connect_gen: for ctxt in 2**CFG.numContextsLog2-1 downto 0 generate
      reg_writeEnable(ctxt)(prt) <= reg_enable_local(ctxt);
      reg_writeAddr  (ctxt)(prt) <= reg_addr_local(ctxt);
      reg_writeData  (ctxt)(prt) <= reg_data_local(ctxt);
    end generate;
    
  end generate;
  
  -- Instantiate the register file for each context.
  regfile_gen: for ctxt in 2**CFG.numContextsLog2-1 downto 0 generate
    regfile_x: entity rvex.core_gpRegs_asic_behav1_regFile
      generic map (
        CFG                     => CFG
      )
      port map (
        clk                     => clk,
        readAddr                => reg_readAddr(ctxt),
        readData                => reg_readData(ctxt),
        writeEnable             => reg_writeEnable(ctxt),
        writeAddr               => reg_writeAddr(ctxt),
        writeData               => reg_writeData(ctxt)
      );
  end generate;
  
  -- Merge the read data outputs from the contexts.
  data_merge_proc: process (reg_readData) is
    variable data : bitvec32;
  begin
    for prt in 0 to 2*2**CFG.numLanesLog2-1 loop
      data := reg_readData(0)(prt);
      for ctxt in 1 to 2**CFG.numContextsLog2-1 loop
        data := data or reg_readData(ctxt)(prt);
      end loop;
      fwd_readData(S_WB+1)(prt) <= data;
    end loop;
  end process;
  
  -- Connect the debug bus read data output.
  gpreg2creg_readData <= fwd_readData(S_WB+1)(0);
  
  -- Generate the forwarding logic.
  fwd_gen: for stage in S_RD+L_RD+1 to S_WB generate
    signal fwd_enable     : bitvec8;
    signal fwd_addr       : bitvec6_vec8;
    signal fwd_data       : bitvec32_vec8;
  begin
    
    -- Connect the forwarding ports.
    write_connect_gen: for prt in 0 to 2**CFG.numLanesLog2-1 generate
    begin
      fwd_enable(prt) <= pl2gpreg_writePorts(prt).forwardEnable(stage);
      fwd_addr  (prt) <= pl2gpreg_writePorts(prt).addr(stage);
      fwd_data  (prt) <= pl2gpreg_writePorts(prt).data(stage);
    end generate;
    
    -- Instantiate the forwarding logic for this stage.
    fwd_x: entity rvex.core_gpRegs_asic_behav1_fwdStage
      generic map (
        CFG                     => CFG
      )
      port map (
        coupled                 => cfg2any_coupled,
        fwd_enable              => fwd_enable,
        fwd_addr                => fwd_addr,
        fwd_data                => fwd_data,
        read_addr               => fwd_readAddr,
        read_data_in            => fwd_readData(stage+1),
        read_data_out           => fwd_readData(stage)
      );
    
  end generate;
  
  -- Connect the read data output.
  read_data_gen: for prt in 0 to 15 generate
    gpreg2pl_readPorts(prt).data(S_RD+L_RD) <= fwd_readData(S_RD+L_RD+1)(prt);
    gpreg2pl_readPorts(prt).valid(S_RD+L_RD) <= '1';
  end generate;
  
end Behavioral;

