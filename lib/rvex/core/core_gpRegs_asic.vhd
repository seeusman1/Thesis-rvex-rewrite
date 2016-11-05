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
-- BUF: non-inverting buffer
--=============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity BUF is
  port (
    A   : in  std_logic;
    Z   : out std_logic
  );
end BUF;

architecture behavioral of BUF is
begin
  Z <= A;
end behavioral;

--=============================================================================
-- BUFT: non-inverting buffer with enable
--=============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity BUFT is
  port (
    A   : in    std_logic;
    E   : in    std_logic;
    Z   : inout std_logic
  );
end BUFT;

architecture behavioral of BUFT is
begin
  Z <= A when E = '1' else 'Z' when E = '0' else 'X';
end behavioral;

--=============================================================================
-- INV: inverter
--=============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity INV is
  port (
    A   : in  std_logic;
    Z   : out std_logic
  );
end INV;

architecture behavioral of INV is
begin
  Z <= not A;
end behavioral;

--=============================================================================
-- AN2: 2-input AND gate
--=============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity AN2 is
  port (
    A   : in  std_logic;
    B   : in  std_logic;
    Z   : out std_logic
  );
end AN2;

architecture behavioral of AN2 is
begin
  Z <= A and B;
end behavioral;

--=============================================================================
-- AN3: 3-input AND gate
--=============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity AN3 is
  port (
    A   : in  std_logic;
    B   : in  std_logic;
    C   : in  std_logic;
    Z   : out std_logic
  );
end AN3;

architecture behavioral of AN3 is
begin
  Z <= A and B and C;
end behavioral;

--=============================================================================
-- ND2: 2-input NAND gate
--=============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity ND2 is
  port (
    A   : in  std_logic;
    B   : in  std_logic;
    Z   : out std_logic
  );
end ND2;

architecture behavioral of ND2 is
begin
  Z <= A nand B;
end behavioral;

--=============================================================================
-- ND4: 4-input NAND gate
--=============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity ND4 is
  port (
    A   : in  std_logic;
    B   : in  std_logic;
    C   : in  std_logic;
    D   : in  std_logic;
    Z   : out std_logic
  );
end ND4;

architecture behavioral of ND4 is
begin
  Z <= not (A and B and C and D);
end behavioral;

--=============================================================================
-- NR3: 3-input NOR gate
--=============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity NR3 is
  port (
    A   : in  std_logic;
    B   : in  std_logic;
    C   : in  std_logic;
    Z   : out std_logic
  );
end NR3;

architecture behavioral of NR3 is
begin
  Z <= not (A or B or C);
end behavioral;

--=============================================================================
-- NR4: 4-input NOR gate
--=============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity NR4 is
  port (
    A   : in  std_logic;
    B   : in  std_logic;
    C   : in  std_logic;
    D   : in  std_logic;
    Z   : out std_logic
  );
end NR4;

architecture behavioral of NR4 is
begin
  Z <= not (A or B or C or D);
end behavioral;

--=============================================================================
-- AOI22
--=============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity AOI22 is
  port (
    A1  : in  std_logic;
    A2  : in  std_logic;
    B1  : in  std_logic;
    B2  : in  std_logic;
    Z   : out std_logic
  );
end AOI22;

architecture behavioral of AOI22 is
begin
  Z <= not ((A1 and A2) or (B1 and B2));
end behavioral;

--=============================================================================
-- DFEQ: positive edge-triggered D flipflop with active-high enable
--=============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity DFEQ is
  port (
    D   : in  std_logic;
    E   : in  std_logic;
    CK  : in  std_logic;
    Q   : out std_logic
  );
end DFEQ;

architecture behavioral of DFEQ is
begin
  proc: process (CK) is
  begin
    if rising_edge(CK) then
      if E = '1' then
        Q <= D;
      end if;
    end if;
  end process;
end behavioral;

--=============================================================================
-- Library for the above components
--=============================================================================
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package asic_primitives is
  
  component BUF is
    port (
      A   : in  std_logic;
      Z   : out std_logic
    );
  end component BUF;
  
  component BUFT is
    port (
      A   : in    std_logic;
      E   : in    std_logic;
      Z   : inout std_logic
    );
  end component BUFT;
  
  component INV is
    port (
      A   : in  std_logic;
      Z   : out std_logic
    );
  end component INV;
  
  component AN2 is
    port (
      A   : in  std_logic;
      B   : in  std_logic;
      Z   : out std_logic
    );
  end component AN2;
  
  component AN3 is
    port (
      A   : in  std_logic;
      B   : in  std_logic;
      C   : in  std_logic;
      Z   : out std_logic
    );
  end component AN3;
  
  component ND2 is
    port (
      A   : in  std_logic;
      B   : in  std_logic;
      Z   : out std_logic
    );
  end component ND2;
  
  component ND4 is
    port (
      A   : in  std_logic;
      B   : in  std_logic;
      C   : in  std_logic;
      D   : in  std_logic;
      Z   : out std_logic
    );
  end component ND4;
  
  component NR3 is
    port (
      A   : in  std_logic;
      B   : in  std_logic;
      C   : in  std_logic;
      Z   : out std_logic
    );
  end component NR3;
  
  component NR4 is
    port (
      A   : in  std_logic;
      B   : in  std_logic;
      C   : in  std_logic;
      D   : in  std_logic;
      Z   : out std_logic
    );
  end component NR4;
  
  component AOI22 is
    port (
      A1  : in  std_logic;
      A2  : in  std_logic;
      B1  : in  std_logic;
      B2  : in  std_logic;
      Z   : out std_logic
    );
  end component AOI22;
  
  component DFEQ is
    port (
      D   : in  std_logic;
      E   : in  std_logic;
      CK  : in  std_logic;
      Q   : out std_logic
    );
  end component DFEQ;
  
end package asic_primitives;

--=============================================================================
-- Type package used by the structural stuff.
--=============================================================================
library ieee;
use ieee.std_logic_1164.all;

package asic_types is
  
  subtype bitvec2 is std_logic_vector(1 downto 0);
  subtype bitvec3 is std_logic_vector(2 downto 0);
  subtype bitvec4 is std_logic_vector(3 downto 0);
  subtype bitvec5 is std_logic_vector(4 downto 0);
  subtype bitvec6 is std_logic_vector(5 downto 0);
  subtype bitvec7 is std_logic_vector(6 downto 0);
  subtype bitvec8 is std_logic_vector(7 downto 0);
  subtype bitvec16 is std_logic_vector(15 downto 0);
  subtype bitvec32 is std_logic_vector(31 downto 0);
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
  type bitvec64_array is array (natural range <>) of bitvec64;
  type bitvec128_array is array (natural range <>) of bitvec128;
  
  subtype bitvec3_vec2 is bitvec3_array(1 downto 0);
  type bitvec3_vec2_array is array (natural range <>) of bitvec3_vec2;
  
end asic_types;

package body asic_types is
end asic_types;

--=============================================================================
-- Level 1 address decoder. Maps "disabled" to address zero and one-hot encodes
-- the first 4 bits of the address.
--=============================================================================
library ieee;
use ieee.std_logic_1164.all;

library rvex;
use rvex.asic_primitives.all;
use rvex.asic_types.all;

entity dec_lvl1 is
  port (
    in_address    : in  bitvec7;
    in_enable     : in  std_logic;
    l2_address    : out bitvec3_vec2;
    l2_enable     : out bitvec16
  );
end dec_lvl1;

architecture structural of dec_lvl1 is
  signal decode         : bitvec4;
  signal decode_buf     : bitvec4;
  signal decode_inv     : bitvec4;
begin
  
  -- Handle the lower half of the register address bits. These are used to
  -- select between the 8x32 blocks. The address is zeroed to select the
  -- nonexistent $r0.0 if the port is disabled.
  addr_sel_0:  AN2 port map (in_enable, in_address(0), decode(0));
  addr_sel_1:  AN2 port map (in_enable, in_address(1), decode(1));
  addr_sel_2:  AN2 port map (in_enable, in_address(2), decode(2));
  
  -- Handle the context selection bit. This bit is a little special, because it
  -- has near zero switching activity: it only switches during a
  -- reconfiguration, or possibly when a debug bus access is performed. We use
  -- it to select which half of the 8x32 blocks to use, and set things up to
  -- minimize switching activity as much as possible in the disabled 8x32
  -- blocks. Note that we don't have to (or even want to) zero this bit if the
  -- port is disabled; this bit just selects which $r0.0 to access, and the
  -- enable signal does have lots of switching activity.
  decode(3) <= in_address(6);
  
  -- Generate the one-hot decoder that generates the enable signal for each
  -- 8x32 block.
  dec_buf_0: BUF port map (decode(0), decode_buf(0));
  dec_inv_0: INV port map (decode(0), decode_inv(0));
  dec_buf_1: BUF port map (decode(1), decode_buf(1));
  dec_inv_1: INV port map (decode(1), decode_inv(1));
  dec_buf_2: BUF port map (decode(2), decode_buf(2));
  dec_inv_2: INV port map (decode(2), decode_inv(2));
  dec_buf_3: BUF port map (decode(3), decode_buf(3));
  dec_inv_3: INV port map (decode(3), decode_inv(3));
  
  -- Enables for context 0 register blocks:
  dec_out_0: NR4 port map (decode_buf(0), decode_buf(1), decode_buf(2), decode_buf(3), l2_enable(0));
  dec_out_1: NR4 port map (decode_inv(0), decode_buf(1), decode_buf(2), decode_buf(3), l2_enable(1));
  dec_out_2: NR4 port map (decode_buf(0), decode_inv(1), decode_buf(2), decode_buf(3), l2_enable(2));
  dec_out_3: NR4 port map (decode_inv(0), decode_inv(1), decode_buf(2), decode_buf(3), l2_enable(3));
  dec_out_4: NR4 port map (decode_buf(0), decode_buf(1), decode_inv(2), decode_buf(3), l2_enable(4));
  dec_out_5: NR4 port map (decode_inv(0), decode_buf(1), decode_inv(2), decode_buf(3), l2_enable(5));
  dec_out_6: NR4 port map (decode_buf(0), decode_inv(1), decode_inv(2), decode_buf(3), l2_enable(6));
  dec_out_7: NR4 port map (decode_inv(0), decode_inv(1), decode_inv(2), decode_buf(3), l2_enable(7));
  
  -- Enables for context 1 register blocks:
  dec_out_8: NR4 port map (decode_buf(0), decode_buf(1), decode_buf(2), decode_inv(3), l2_enable(8));
  dec_out_9: NR4 port map (decode_inv(0), decode_buf(1), decode_buf(2), decode_inv(3), l2_enable(9));
  dec_out_A: NR4 port map (decode_buf(0), decode_inv(1), decode_buf(2), decode_inv(3), l2_enable(10));
  dec_out_B: NR4 port map (decode_inv(0), decode_inv(1), decode_buf(2), decode_inv(3), l2_enable(11));
  dec_out_C: NR4 port map (decode_buf(0), decode_buf(1), decode_inv(2), decode_inv(3), l2_enable(12));
  dec_out_D: NR4 port map (decode_inv(0), decode_buf(1), decode_inv(2), decode_inv(3), l2_enable(13));
  dec_out_E: NR4 port map (decode_buf(0), decode_inv(1), decode_inv(2), decode_inv(3), l2_enable(14));
  dec_out_F: NR4 port map (decode_inv(0), decode_inv(1), decode_inv(2), decode_inv(3), l2_enable(15));
  
  -- Handle the upper half of the address bits. These address the registers
  -- within the 8x32 blocks. They are zeroed when the block is disabled, either
  -- through the port enable signal, or by means of reconfiguration.
  addr_sel_3l: AN3 port map (in_enable, in_address(3), decode_inv(3), l2_address(0)(0));
  addr_sel_3h: AN3 port map (in_enable, in_address(3), decode_buf(3), l2_address(1)(0));
  addr_sel_4l: AN3 port map (in_enable, in_address(4), decode_inv(3), l2_address(0)(1));
  addr_sel_4h: AN3 port map (in_enable, in_address(4), decode_buf(3), l2_address(1)(1));
  addr_sel_5l: AN3 port map (in_enable, in_address(5), decode_inv(3), l2_address(0)(2));
  addr_sel_5h: AN3 port map (in_enable, in_address(5), decode_buf(3), l2_address(1)(2));
  
end structural;

--=============================================================================
-- Level 2 address decoder for the read path.
--=============================================================================
library ieee;
use ieee.std_logic_1164.all;

library rvex;
use rvex.asic_primitives.all;
use rvex.asic_types.all;

entity dec_lvl2_r is
  port (
    l2_address    : in  bitvec3;
    dec_enable    : out bitvec8
  );
end dec_lvl2_r;

architecture structural of dec_lvl2_r is
  signal decode_buf : bitvec3;
  signal decode_inv : bitvec3;
begin
  
  -- Generate the one-hot decoder.
  dec_buf_0: BUF port map (l2_address(0), decode_buf(0));
  dec_inv_0: INV port map (l2_address(0), decode_inv(0));
  dec_buf_1: BUF port map (l2_address(1), decode_buf(1));
  dec_inv_1: INV port map (l2_address(1), decode_inv(1));
  dec_buf_2: BUF port map (l2_address(2), decode_buf(2));
  dec_inv_2: INV port map (l2_address(2), decode_inv(2));
  
  dec_out_0: NR3 port map (decode_buf(0), decode_buf(1), decode_buf(2), dec_enable(0));
  dec_out_1: NR3 port map (decode_inv(0), decode_buf(1), decode_buf(2), dec_enable(1));
  dec_out_2: NR3 port map (decode_buf(0), decode_inv(1), decode_buf(2), dec_enable(2));
  dec_out_3: NR3 port map (decode_inv(0), decode_inv(1), decode_buf(2), dec_enable(3));
  dec_out_4: NR3 port map (decode_buf(0), decode_buf(1), decode_inv(2), dec_enable(4));
  dec_out_5: NR3 port map (decode_inv(0), decode_buf(1), decode_inv(2), dec_enable(5));
  dec_out_6: NR3 port map (decode_buf(0), decode_inv(1), decode_inv(2), dec_enable(6));
  dec_out_7: NR3 port map (decode_inv(0), decode_inv(1), decode_inv(2), dec_enable(7));
  
end structural;

--=============================================================================
-- Level 2 address decoder for the write path.
--=============================================================================
library ieee;
use ieee.std_logic_1164.all;

library rvex;
use rvex.asic_primitives.all;
use rvex.asic_types.all;

entity dec_lvl2_w is
  port (
    l2_enable     : in  std_logic;
    l2_address    : in  bitvec3;
    dec_enable    : out bitvec8
  );
end dec_lvl2_w;

architecture structural of dec_lvl2_w is
  signal decode_buf   : bitvec3;
  signal decode_inv   : bitvec4;
begin
  
  -- Generate the one-hot decoder.
  dec_buf_0: BUF port map (l2_address(0), decode_buf(0));
  dec_inv_0: INV port map (l2_address(0), decode_inv(0));
  dec_buf_1: BUF port map (l2_address(1), decode_buf(1));
  dec_inv_1: INV port map (l2_address(1), decode_inv(1));
  dec_buf_2: BUF port map (l2_address(2), decode_buf(2));
  dec_inv_2: INV port map (l2_address(2), decode_inv(2));
  dec_inv_3: INV port map (l2_enable,     decode_inv(3));
  
  dec_out_0: NR4 port map (decode_buf(0), decode_buf(1), decode_buf(2), decode_inv(3), dec_enable(0));
  dec_out_1: NR4 port map (decode_inv(0), decode_buf(1), decode_buf(2), decode_inv(3), dec_enable(1));
  dec_out_2: NR4 port map (decode_buf(0), decode_inv(1), decode_buf(2), decode_inv(3), dec_enable(2));
  dec_out_3: NR4 port map (decode_inv(0), decode_inv(1), decode_buf(2), decode_inv(3), dec_enable(3));
  dec_out_4: NR4 port map (decode_buf(0), decode_buf(1), decode_inv(2), decode_inv(3), dec_enable(4));
  dec_out_5: NR4 port map (decode_inv(0), decode_buf(1), decode_inv(2), decode_inv(3), dec_enable(5));
  dec_out_6: NR4 port map (decode_buf(0), decode_inv(1), decode_inv(2), decode_inv(3), dec_enable(6));
  dec_out_7: NR4 port map (decode_inv(0), decode_inv(1), decode_inv(2), decode_inv(3), dec_enable(7));
  
end structural;

--=============================================================================
-- The 1-bit memory cell, repeated 126x32 times, with 8 write ports and 16 read
-- ports.
--=============================================================================
library ieee;
use ieee.std_logic_1164.all;

library rvex;
use rvex.asic_primitives.all;
use rvex.asic_types.all;

entity reg1 is
  port (
    clk           : in    std_logic;
    write_enables : in    bitvec8;
    write_enable  : in    std_logic;
    write_datas   : in    bitvec8;
    read_enables  : in    bitvec16;
    read_datas    : inout bitvec16
  );
end reg1;

architecture structural of reg1 is
  signal din4 : bitvec4;
  signal din  : std_logic;
  signal dout : std_logic;
begin
  
  -- Use wired-or to merge the read data.
  din_0: AOI22 port map (write_datas(0), write_enables(0), write_datas(1), write_enables(1), din4(0));
  din_1: AOI22 port map (write_datas(2), write_enables(2), write_datas(3), write_enables(3), din4(1));
  din_2: AOI22 port map (write_datas(4), write_enables(4), write_datas(5), write_enables(5), din4(2));
  din_3: AOI22 port map (write_datas(6), write_enables(6), write_datas(7), write_enables(7), din4(3));
  din_x: ND4   port map (din4(0), din4(1), din4(2), din4(3), din);
  
  -- Instantiate the memory element.
  mem:   DFEQ  port map (din, write_enable, clk, dout);
  
  -- Instantiate the output buffers.
  buf_gen: for i in read_datas'range generate
    buf_x: BUFT port map (dout, read_enables(i), read_datas(i));
  end generate;
  
end structural;

--=============================================================================
-- One of the 126 32-bit general-purpose registers.
--=============================================================================
library ieee;
use ieee.std_logic_1164.all;

library rvex;
use rvex.asic_primitives.all;
use rvex.asic_types.all;

entity reg32 is
  port (
    clk           : in    std_logic;
    write_enables : in    bitvec8;
    write_datas   : in    bitvec32_array(7 downto 0);
    read_enables  : in    bitvec16;
    read_datas    : inout bitvec32_array(15 downto 0)
  );
end reg32;

architecture structural of reg32 is
  signal write_enable2  : bitvec2;
  signal write_enable   : std_logic;
begin
  
  -- Generate an 8-wide or gate for the write enable signals.
  wen_0: NR4 port map (write_enables(0), write_enables(1), write_enables(2), write_enables(3), write_enable2(0));
  wen_1: NR4 port map (write_enables(4), write_enables(5), write_enables(6), write_enables(7), write_enable2(1));
  wen_x: ND2 port map (write_enable2(0), write_enable2(1), write_enable);
  
  -- Generate the bit registers.
  bit_gen: for i in 31 downto 0 generate
    signal write_datas_x  : bitvec8;
    signal read_datas_x   : bitvec16;
  begin
    
    -- Unpack the 2D write data array.
    wdata_unpack_gen: for j in write_enables'range generate
      write_datas_x(j) <= write_datas(j)(i);
    end generate;
    
    -- Instantiate the register.
    reg_x: entity work.reg1
      port map (
        clk           => clk,
        write_enables => write_enables,
        write_enable  => write_enable,
        write_datas   => write_datas_x,
        read_enables  => read_enables,
        read_datas    => read_datas_x
      );
    
    -- Pack the 2D read data array.
    rdata_pack_gen: for j in read_enables'range generate
      read_datas(j)(i) <= read_datas_x(j);
    end generate;
    
  end generate;
  
  -- Test for multiple simultaneous writes to the same register. This behaves
  -- differently in the ASIC register file than in the FPGA one.
  --pragma translate_off
  process (clk) is
    variable cnt: natural;
  begin
    if rising_edge(clk) then
      cnt := 0;
      for prt in 0 to 7 loop
        if write_enables(prt) = '1' then
          cnt := cnt + 1;
        end if;
      end loop;
      assert cnt <= 1
        report "Multiple simultaneous writes to gpreg were merged using bitwise or."
        severity warning;
    end if;
  end process;
  --pragma translate_on
  
end structural;

--=============================================================================
-- A block of eight 32-bit registers with 8 write ports and 16 read ports.
--=============================================================================
library ieee;
use ieee.std_logic_1164.all;

library rvex;
use rvex.asic_primitives.all;
use rvex.asic_types.all;

entity reg8x32 is
  generic (
    FIRST_BLK       : boolean
  );
  port (
    clk             : in    std_logic;
    
    -- Write address, enable, and data for each write port.
    write_addresses : in    bitvec3_array(7 downto 0);
    write_enables   : in    bitvec8;
    write_datas     : in    bitvec32_array(7 downto 0);
    
    -- Read address, enable, and tri-stated data for each write port.
    read_addresses  : in    bitvec3_array(15 downto 0);
    read_enables    : in    bitvec16;
    read_datas      : inout bitvec32_array(15 downto 0)
    
  );
end reg8x32;

architecture structural of reg8x32 is
  signal write_enables_local  : bitvec8_array(7 downto 0);
  signal read_enables_local   : bitvec16_array(7 downto 0);
  signal read_datas_local     : bitvec32_array(15 downto 0);
begin
  
  -- Generate the level-2 write port decoders.
  write_dec_gen: for prt in 7 downto 0 generate
    signal write_enables_local_x  : bitvec8;
  begin
    
    -- Generate the decoder.
    write_dec_x: entity work.dec_lvl2_w
      port map (
        l2_enable   => write_enables(prt),
        l2_address  => write_addresses(prt),
        dec_enable  => write_enables_local_x
      );
    
    -- Pack the write enable signals.
    pack_gen: for reg in 7 downto 0 generate
      write_enables_local(reg)(prt) <= write_enables_local_x(reg);
    end generate;
    
  end generate;
  
  -- Generate the level-2 read port decoders.
  read_dec_gen: for prt in 15 downto 0 generate
    signal read_enables_local_x : bitvec8;
  begin
    
    -- Generate the decoder.
    read_dec_x: entity work.dec_lvl2_r
      port map (
        l2_address  => read_addresses(prt),
        dec_enable  => read_enables_local_x
      );
    
    -- Pack the level-2 read enable signals.
    pack_gen: for reg in 7 downto 0 generate
      read_enables_local(reg)(prt) <= read_enables_local_x(reg);
    end generate;
    
  end generate;
  
  -- Generate the registers.
  reg_gen: for reg in 7 downto 0 generate
    
    -- Don't generate anything for $r0.0. All "disabled" accesses are remapped
    -- to $r0.0, so from an energy perspective not instantiating a register
    -- here should help. It doesn't matter for functionality.
    reg_zero: if FIRST_BLK and reg = 0 generate
      
      -- We still want to generate the tri-state buffers here, to prevent the
      -- local data busses from floating. The input is connected to the output
      -- to essentially form a tiny latch to keep the bus at the previous value.
      -- If BUFT is a pass gate rather than an actual buffer, either a buffer
      -- should be added to generate the feedback network, or the input should
      -- be tied to Vss or Vdd instead.
      read_buf_prt_gen: for prt in 15 downto 0 generate
        read_buf_bit_gen: for bt in 31 downto 0 generate
          read_buf_x: BUFT port map (read_datas_local(prt)(bt), read_enables_local(reg)(prt), read_datas_local(prt)(bt));
        end generate;
      end generate;
      
    end generate;
    
    -- Generate normal registers for all others.
    normal_reg: if not (FIRST_BLK and reg = 0) generate
      reg_inst: entity work.reg32
        port map (
          clk           => clk,
          write_enables => write_enables_local(reg),
          write_datas   => write_datas,
          read_enables  => read_enables_local(reg),
          read_datas    => read_datas_local
        );
    end generate;
    
  end generate;
  
  -- Generate the tri-state read data output buffers for the level-1
  -- multiplexer busses.
  read_buf_prt_gen: for prt in 15 downto 0 generate
    read_buf_bit_gen: for bt in 31 downto 0 generate
      read_buf_x: BUFT port map (read_datas_local(prt)(bt), read_enables(prt), read_datas(prt)(bt));
    end generate;
  end generate;
  
end structural;

--=============================================================================
-- A block of 126 32-bit registers with 8 write ports and 16 read ports; i.e.
-- the complete register file for an 8-way, 2-context r-VEX.
--=============================================================================
library ieee;
use ieee.std_logic_1164.all;

library rvex;
use rvex.asic_primitives.all;
use rvex.asic_types.all;

entity reg126x32 is
  port (
    clk             : in  std_logic;
    
    -- Write address, enable, and data for each write port.
    write_addresses : in  bitvec7_array(7 downto 0);
    write_enables   : in  bitvec8;
    write_datas     : in  bitvec32_array(7 downto 0);
    
    -- Read address, enable, and data for each write port.
    read_addresses  : in  bitvec7_array(15 downto 0);
    read_enables    : in  bitvec16;
    read_datas      : out bitvec32_array(15 downto 0)
    
  );
end reg126x32;

architecture structural of reg126x32 is
  signal write_addresses_local  : bitvec3_vec2_array(7 downto 0);
  signal write_enables_local    : bitvec16_array(7 downto 0);
  signal read_addresses_local   : bitvec3_vec2_array(15 downto 0);
  signal read_enables_local     : bitvec16_array(15 downto 0);
  signal read_datas_local       : bitvec32_array(15 downto 0);
begin
  
  -- Generate the level-1 write address decoders.
  write_dec_lvl1_gen: for prt in 7 downto 0 generate
    write_dec_lvl1_x: entity work.dec_lvl1
      port map (
        in_address  => write_addresses(prt),
        in_enable   => write_enables(prt),
        l2_address  => write_addresses_local(prt),
        l2_enable   => write_enables_local(prt)
      );
  end generate;
  
  -- Generate the level-1 read address decoders.
  read_dec_lvl1_gen: for prt in 15 downto 0 generate
    read_dec_lvl1_x: entity work.dec_lvl1
      port map (
        in_address  => read_addresses(prt),
        in_enable   => read_enables(prt),
        l2_address  => read_addresses_local(prt),
        l2_enable   => read_enables_local(prt)
      );
  end generate;
  
  -- Generate the register blocks.
  blk_gen: for blk in 15 downto 0 generate
    constant first_blk        : boolean := (blk mod 8) = 0;
    signal write_addresses_x  : bitvec3_array(7 downto 0);
    signal write_enables_x    : bitvec8;
    signal read_addresses_x   : bitvec3_array(15 downto 0);
    signal read_enables_x     : bitvec16;
  begin
    
    -- Unpack the control signals.
    unpack_write_gen: for prt in 7 downto 0 generate
      write_addresses_x(prt) <= write_addresses_local(prt)(blk/8);
      write_enables_x(prt)   <= write_enables_local(prt)(blk);
    end generate;
    unpack_read_gen: for prt in 15 downto 0 generate
      read_addresses_x(prt)  <= read_addresses_local(prt)(blk/8);
      read_enables_x(prt)    <= read_enables_local(prt)(blk);
    end generate;
    
    -- Generate the register block.
    blk_x: entity work.reg8x32
      generic map (
        FIRST_BLK       => first_blk
      )
      port map (
        clk             => clk,
        write_addresses => write_addresses_x,
        write_enables   => write_enables_x,
        write_datas     => write_datas,
        read_addresses  => read_addresses_x,
        read_enables    => read_enables_x,
        read_datas      => read_datas_local
      );
    
  end generate;
  
  -- Buffer the read data outputs.
  read_buf_prt_gen: for prt in 15 downto 0 generate
    read_buf_bit_gen: for bt in 31 downto 0 generate
      read_buf_x: BUF port map (read_datas_local(prt)(bt), read_datas(prt)(bt));
    end generate;
  end generate;
  
end structural;

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
use rvex.asic_types.all;
-- pragma translate_off
use rvex.simUtils_pkg.all;
-- pragma translate_on

--=============================================================================
entity core_gpRegs_asic is
--=============================================================================
  generic (
    
    -- log2 of the number of registers to instantiate. MUST BE 7.
    NUM_REGS_LOG2               : natural := 7;
    
    -- Number of write ports to instantiate. MUST BE 8.
    NUM_WRITE_PORTS             : natural := 8;
    
    -- Number of read ports to instantiate. MUST BE 16.
    NUM_READ_PORTS              : natural := 16;
    
    -- Where to place the register(s) in the read path. If there is one
    -- register, then the memory is read-before-write for READ_DATA_REG or
    -- write-before read for READ_CMD_REG. Placing the register in the read
    -- command is probably better because it gets rid of a forwarding stage, is
    -- probably better power-wise due to reduced hazards in the read address.
    -- Timing might be worse because the command is readily available while the
    -- result goes through the ALU before the next register, but the register
    -- read happens simultaneously to forwarding, so unless forwarding is faster
    -- than the register read it probably doesn't matter anyway.
    READ_CMD_REG                : boolean := true;
    READ_DATA_REG               : boolean := false
    
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
    
    ---------------------------------------------------------------------------
    -- Write ports
    ---------------------------------------------------------------------------
    -- Write enables are active high, and gated by clkEn. Only the lower
    -- NUM_REGS_LOG2 bits of the addresses are used.
    writeEnable                 : in  std_logic_vector(NUM_WRITE_PORTS-1 downto 0);
    writeAddr                   : in  rvex_address_array(NUM_WRITE_PORTS-1 downto 0);
    writeData                   : in  rvex_data_array(NUM_WRITE_PORTS-1 downto 0);
    
    ---------------------------------------------------------------------------
    -- Read ports
    ---------------------------------------------------------------------------
    -- Only the lower NUM_REGS_LOG2 bits of the address are used.
    readEnable                  : in  std_logic_vector(NUM_READ_PORTS-1 downto 0) := (others => '1');
    readAddr                    : in  rvex_address_array(NUM_READ_PORTS-1 downto 0);
    readData                    : out rvex_data_array(NUM_READ_PORTS-1 downto 0)
    
  );
end core_gpRegs_asic;

--=============================================================================
architecture Behavioral of core_gpRegs_asic is
--=============================================================================
  
  -- Same as writeAddr and readAddr, but packed correctly.
  signal write_addresses        : bitvec7_array(7 downto 0);
  signal write_enables          : bitvec8;
  signal write_datas            : bitvec32_array(7 downto 0);
  signal read_addresses         : bitvec7_array(15 downto 0);
  signal read_enables           : bitvec16;
  signal read_datas             : bitvec32_array(15 downto 0);
  
--=============================================================================
begin -- architecture
--=============================================================================

  -- Make sure that the generics are correct (they're really only there because
  -- the core expects them there).
  assert NUM_REGS_LOG2 = 7
    report "The ASIC register file implementation is hand-optimized for 2 contexts."
    severity failure;
  
  assert NUM_WRITE_PORTS = 8
    report "The ASIC register file implementation is hand-optimized for 8 lanes."
    severity failure;
  
  assert NUM_READ_PORTS = 16
    report "The ASIC register file implementation is hand-optimized for 8 lanes."
    severity failure;
  
  -- Pack the write control signals properly.
  process (writeAddr, writeEnable) is
  begin
    for prt in 7 downto 0 loop
      write_addresses(prt) <= writeAddr(prt)(6 downto 0);
      write_enables(prt) <= writeEnable(prt) and clkEn;
      write_datas(prt) <= writeData(prt);
    end loop;
  end process;
  
  -- Pack the read control signals properly.
  cmd_reg_gen: if READ_CMD_REG generate
    process (clk) is
    begin
      if rising_edge(clk) then
        if clkEn = '1' then
          for prt in 15 downto 0 loop
            read_addresses(prt) <= readAddr(prt)(6 downto 0);
            read_enables(prt) <= readEnable(prt);
          end loop;
        end if;
      end if;
    end process;
  end generate;
  no_cmd_reg_gen: if not READ_CMD_REG generate
    process (readAddr, readEnable)
    begin
      for prt in 15 downto 0 loop
        read_addresses(prt) <= readAddr(prt)(6 downto 0);
        read_enables(prt) <= readEnable(prt);
      end loop;
    end process;
  end generate;
  
  -- Instantiate the unit.
  gpregs: entity rvex.reg126x32
    port map (
      clk             => clk,
      write_addresses => write_addresses,
      write_enables   => write_enables,
      write_datas     => write_datas,
      read_addresses  => read_addresses,
      read_enables    => read_enables,
      read_datas      => read_datas
    );
  
  -- Simulate correct behavior of the general purpose registers to check
  -- correctness.
  -- pragma translate_off
  -- Describe the RAM.
  check_block: block is
    signal ram  : bitvec32_array(0 to 127) := (others => (others => 'U'));
  begin
    check_proc: process (clk) is
      variable wval : bitvec32;
      variable wen  : boolean;
      variable addr : natural;
      variable rval : bitvec32;
      variable cval : bitvec32;
    begin
      if rising_edge(clk) then
        
        -- Handle/check the previous (combinatorial) reads.
        for prt in 0 to 15 loop
          if read_enables(prt) = '1' then
            addr := to_integer(unsigned(read_addresses(prt)));
            next when addr mod 64 = 0;
            rval := read_datas(prt);
            cval := ram(addr);
            assert rval = cval
              report "Register file check error in previous cycle:" &
              " port=" & integer'image(prt) & " addr=" & integer'image(addr) &
              " correct=" & rvs_hex(cval) & " read=" & rvs_hex(rval)
              severity warning;
          end if;
        end loop;
        
        -- Handle writes.
        for reg in 1 to 127 loop
          
          -- Can't write to $r0.0.
          next when reg mod 64 = 0;
          
          -- Arbitrate using or().
          wval := (others => '0');
          wen := false;
          for prt in 0 to 7 loop
            if to_integer(unsigned(write_addresses(prt))) = reg then
              if write_enables(prt) = '1' then
                wval := wval or write_datas(prt);
                wen := true;
              end if;
            end if;
          end loop;
          
          -- Handle the write.
          if wen then
            ram(reg) <= wval;
          end if;
          
        end loop;
        
      end if;
    end process;
  end block;
  -- pragma translate_on
  
  -- Unpack the read data signal.
  data_reg_gen: if READ_DATA_REG generate
    process (clk) is
    begin
      if rising_edge(clk) then
        if clkEn = '1' then
          for prt in 15 downto 0 loop
            readData(prt) <= read_datas(prt);
          end loop;
        end if;
      end if;
    end process;
  end generate;
  no_data_reg_gen: if not READ_DATA_REG generate
    process (read_datas) is
    begin
      for prt in 15 downto 0 loop
        readData(prt) <= read_datas(prt);
      end loop;
    end process;
  end generate;
  
end Behavioral;

