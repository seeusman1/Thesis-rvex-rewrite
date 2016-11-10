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
-- ND2B1: 2-input NAND gate with one inverted input
--=============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity ND2B1 is
  port (
    NA  : in  std_logic;
    B   : in  std_logic;
    Z   : out std_logic
  );
end ND2B1;

architecture behavioral of ND2B1 is
begin
  Z <= (not NA) nand B;
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
-- OR2: 2-input OR gate
--=============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity OR2 is
  port (
    A   : in  std_logic;
    B   : in  std_logic;
    Z   : out std_logic
  );
end OR2;

architecture behavioral of OR2 is
begin
  Z <= A or B;
end behavioral;

--=============================================================================
-- OR6: 6-input OR gate
--=============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity OR6 is
  port (
    A   : in  std_logic;
    B   : in  std_logic;
    C   : in  std_logic;
    D   : in  std_logic;
    E   : in  std_logic;
    F   : in  std_logic;
    Z   : out std_logic
  );
end OR6;

architecture behavioral of OR6 is
begin
  Z <= A or B or C or D or E or F;
end behavioral;

--=============================================================================
-- NR2: 2-input NOR gate
--=============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity NR2 is
  port (
    A   : in  std_logic;
    B   : in  std_logic;
    Z   : out std_logic
  );
end NR2;

architecture behavioral of NR2 is
begin
  Z <= not (A or B);
end behavioral;

--=============================================================================
-- NR2B1: 2-input NOR gate with one inverted input
--=============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity NR2B1 is
  port (
    NA  : in  std_logic;
    B   : in  std_logic;
    Z   : out std_logic
  );
end NR2B1;

architecture behavioral of NR2B1 is
begin
  Z <= not ((not NA) or B);
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
-- XOR2: 2-input XOR gate
--=============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity XOR2 is
  port (
    A   : in  std_logic;
    B   : in  std_logic;
    Z   : out std_logic
  );
end XOR2;

architecture behavioral of XOR2 is
begin
  Z <= A xor B;
end behavioral;

--=============================================================================
-- AO21
--=============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity AO21 is
  port (
    A1  : in  std_logic;
    A2  : in  std_logic;
    B   : in  std_logic;
    Z   : out std_logic
  );
end AO21;

architecture behavioral of AO21 is
begin
  Z <= (A1 and A2) or B;
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
-- MUX2: 2-input multiplexer.
--=============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity MUX2 is
  port (
    S   : in  std_logic;
    A   : in  std_logic;
    B   : in  std_logic;
    Z   : out std_logic
  );
end MUX2;

architecture behavioral of MUX2 is
begin
  Z <= A when S = '0' else B when S = '1' else 'X';
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
  
  component ND2 is
    port (
      A   : in  std_logic;
      B   : in  std_logic;
      Z   : out std_logic
    );
  end component ND2;
  
  component ND2B1 is
    port (
      NA  : in  std_logic;
      B   : in  std_logic;
      Z   : out std_logic
    );
  end component ND2B1;
  
  component ND4 is
    port (
      A   : in  std_logic;
      B   : in  std_logic;
      C   : in  std_logic;
      D   : in  std_logic;
      Z   : out std_logic
    );
  end component ND4;
  
  component OR2 is
    port (
      A   : in  std_logic;
      B   : in  std_logic;
      Z   : out std_logic
    );
  end component OR2;
  
  component OR6 is
    port (
      A   : in  std_logic;
      B   : in  std_logic;
      C   : in  std_logic;
      D   : in  std_logic;
      E   : in  std_logic;
      F   : in  std_logic;
      Z   : out std_logic
    );
  end component OR6;
  
  component NR2 is
    port (
      A   : in  std_logic;
      B   : in  std_logic;
      Z   : out std_logic
    );
  end component NR2;
  
  component NR2B1 is
    port (
      NA  : in  std_logic;
      B   : in  std_logic;
      Z   : out std_logic
    );
  end component NR2B1;
  
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
  
  component XOR2 is
    port (
      A   : in  std_logic;
      B   : in  std_logic;
      Z   : out std_logic
    );
  end component XOR2;
  
  component AO21 is
    port (
      A1  : in  std_logic;
      A2  : in  std_logic;
      B   : in  std_logic;
      Z   : out std_logic
    );
  end component AO21;
  
  component AOI22 is
    port (
      A1  : in  std_logic;
      A2  : in  std_logic;
      B1  : in  std_logic;
      B2  : in  std_logic;
      Z   : out std_logic
    );
  end component AOI22;
  
  component MUX2 is
    port (
      S   : in  std_logic;
      A   : in  std_logic;
      B   : in  std_logic;
      Z   : out std_logic
    );
  end component MUX2;
  
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
  
  subtype bitvec3_vec4 is bitvec3_array(3 downto 0);
  type bitvec3_vec4_array is array (natural range <>) of bitvec3_vec4;
  
  subtype bitvec8_vec4 is bitvec8_array(3 downto 0);
  type bitvec8_vec4_array is array (natural range <>) of bitvec8_vec4;
  
  subtype bitvec32_vec16 is bitvec32_array(15 downto 0);
  type bitvec32_vec16_array is array (natural range <>) of bitvec32_vec16;
  
end asic_types;

package body asic_types is
end asic_types;

--=============================================================================
-- Level 1 address decoder for the read path. Inserts registers into the
-- address to prevent switching activity when enable is deasserted and to make
-- a synchronous read port as the core expects.
--=============================================================================
library ieee;
use ieee.std_logic_1164.all;

library rvex;
use rvex.asic_primitives.all;
use rvex.asic_types.all;

entity dec_lvl1 is
  generic (
    writePort       : boolean;
    numContextsLog2 : natural := 1
  );
  port (
    in_address      : in  std_logic_vector(numContextsLog2+5 downto 0);
    in_enable       : in  std_logic := '1';
    l2_address      : out bitvec3_vec4;
    l2_enable       : out bitvec8_vec4
  );
end dec_lvl1;

architecture structural of dec_lvl1 is
  signal decode         : bitvec3;
  signal decode_buf     : bitvec3;
  signal decode_inv     : bitvec3;
  signal select_inv     : std_logic_vector(2**numContextsLog2-1 downto 0);
begin
  
  -- Handle the lower half of the register address bits. These are used to
  -- select between the 8x32 blocks. For write ports, the address is zeroed
  -- to select the nonexistent $r0.0 if the port is disabled.
  read_port_gen: if not writePort generate
    decode(2 downto 0) <= in_address(2 downto 0);
  end generate;
  write_port_gen: if writePort generate
    addr_sel_0: AN2 port map (A=>in_enable, B=>in_address(0), Z=>decode(0));
    addr_sel_1: AN2 port map (A=>in_enable, B=>in_address(1), Z=>decode(1));
    addr_sel_2: AN2 port map (A=>in_enable, B=>in_address(2), Z=>decode(2));
  end generate;
  
  -- Generate the input signals for the one-hot decoder that generates the
  -- enable signal for each 8x32 block.
  dec_buf_0: BUF port map (A=>decode(0), Z=>decode_buf(0));
  dec_inv_0: INV port map (A=>decode(0), Z=>decode_inv(0));
  dec_buf_1: BUF port map (A=>decode(1), Z=>decode_buf(1));
  dec_inv_1: INV port map (A=>decode(1), Z=>decode_inv(1));
  dec_buf_2: BUF port map (A=>decode(2), Z=>decode_buf(2));
  dec_inv_2: INV port map (A=>decode(2), Z=>decode_inv(2));
  
  -- Handle the context selection bits. These bits are a little special, because
  -- they have near zero switching activity: they only switch during a
  -- reconfiguration, or possibly when a debug bus access is performed. We use
  -- it to select which of the 8x32 blocks to use, and set things up to
  -- minimize switching activity as much as possible in the disabled 8x32
  -- blocks.
  num_ctxts_eq1: if numContextsLog2 = 0 generate
    
    -- Generate the enable signals for the 8x32 blocks.
    dec_out_0: NR3 port map (A=>decode_buf(0), B=>decode_buf(1), C=>decode_buf(2), Z=>l2_enable(0)(0));
    dec_out_1: NR3 port map (A=>decode_inv(0), B=>decode_buf(1), C=>decode_buf(2), Z=>l2_enable(0)(1));
    dec_out_2: NR3 port map (A=>decode_buf(0), B=>decode_inv(1), C=>decode_buf(2), Z=>l2_enable(0)(2));
    dec_out_3: NR3 port map (A=>decode_inv(0), B=>decode_inv(1), C=>decode_buf(2), Z=>l2_enable(0)(3));
    dec_out_4: NR3 port map (A=>decode_buf(0), B=>decode_buf(1), C=>decode_inv(2), Z=>l2_enable(0)(4));
    dec_out_5: NR3 port map (A=>decode_inv(0), B=>decode_buf(1), C=>decode_inv(2), Z=>l2_enable(0)(5));
    dec_out_6: NR3 port map (A=>decode_buf(0), B=>decode_inv(1), C=>decode_inv(2), Z=>l2_enable(0)(6));
    dec_out_7: NR3 port map (A=>decode_inv(0), B=>decode_inv(1), C=>decode_inv(2), Z=>l2_enable(0)(7));
    
    -- Forward the address signals. We need to force these to $r0.0 when the
    -- port is disabled for write ports.
    read_port_gen: if not writePort generate
      l2_address(0)(2 downto 0) <= in_address(5 downto 3);
    end generate;
    write_port_gen: if writePort generate
      addr_sel_3: AN2 port map (A=>in_address(3), B=>in_enable, Z=>l2_address(0)(0));
      addr_sel_4: AN2 port map (A=>in_address(4), B=>in_enable, Z=>l2_address(0)(1));
      addr_sel_5: AN2 port map (A=>in_address(5), B=>in_enable, Z=>l2_address(0)(2));
    end generate;
    
  end generate;
  
  num_ctxts_eq2: if numContextsLog2 = 1 generate
    
    -- Active-low context selection signals.
    select_inv_0: BUF port map (A=>in_address(6), Z=>select_inv(0));
    select_inv_1: INV port map (A=>in_address(6), Z=>select_inv(1));
    
  end generate;
  
  num_ctxts_eq4: if numContextsLog2 = 2 generate
    
    -- Active-low context selection signals.
    select_inv_0: OR2   port map (A =>in_address(6), B=>in_address(7), Z=>select_inv(0));
    select_inv_1: ND2B1 port map (NA=>in_address(7), B=>in_address(6), Z=>select_inv(1));
    select_inv_2: ND2B1 port map (NA=>in_address(6), B=>in_address(7), Z=>select_inv(2));
    select_inv_3: ND2   port map (A =>in_address(6), B=>in_address(7), Z=>select_inv(3));
    
  end generate;
  
  num_ctxts_gt1: if numContextsLog2 > 0 generate
    
    -- Generate the enable and address signals for each context.
    dec_out_gen: for ctxt in 0 to 2**numContextsLog2-1 generate
      
      -- Generate the enable signals for the 8x32 blocks.
      dec_out_0: NR4 port map (A=>decode_buf(0), B=>decode_buf(1), C=>decode_buf(2), D=>select_inv(ctxt), Z=>l2_enable(ctxt)(0));
      dec_out_1: NR4 port map (A=>decode_inv(0), B=>decode_buf(1), C=>decode_buf(2), D=>select_inv(ctxt), Z=>l2_enable(ctxt)(1));
      dec_out_2: NR4 port map (A=>decode_buf(0), B=>decode_inv(1), C=>decode_buf(2), D=>select_inv(ctxt), Z=>l2_enable(ctxt)(2));
      dec_out_3: NR4 port map (A=>decode_inv(0), B=>decode_inv(1), C=>decode_buf(2), D=>select_inv(ctxt), Z=>l2_enable(ctxt)(3));
      dec_out_4: NR4 port map (A=>decode_buf(0), B=>decode_buf(1), C=>decode_inv(2), D=>select_inv(ctxt), Z=>l2_enable(ctxt)(4));
      dec_out_5: NR4 port map (A=>decode_inv(0), B=>decode_buf(1), C=>decode_inv(2), D=>select_inv(ctxt), Z=>l2_enable(ctxt)(5));
      dec_out_6: NR4 port map (A=>decode_buf(0), B=>decode_inv(1), C=>decode_inv(2), D=>select_inv(ctxt), Z=>l2_enable(ctxt)(6));
      dec_out_7: NR4 port map (A=>decode_inv(0), B=>decode_inv(1), C=>decode_inv(2), D=>select_inv(ctxt), Z=>l2_enable(ctxt)(7));
      
      -- Forward the address signals. We need to force these to $r0.0 for
      -- deselected contexts to save power, and for write ports also when the
      -- port is disabled. For read ports, the address should be registered.
      read_port_gen: if not writePort generate
        addr_sel_3: NR2B1 port map (NA=>in_address(3), B=>select_inv(ctxt), Z=>l2_address(ctxt)(0));
        addr_sel_4: NR2B1 port map (NA=>in_address(4), B=>select_inv(ctxt), Z=>l2_address(ctxt)(1));
        addr_sel_5: NR2B1 port map (NA=>in_address(5), B=>select_inv(ctxt), Z=>l2_address(ctxt)(2));
      end generate;
      write_port_gen: if writePort generate
        signal enable : std_logic;
      begin
        enable_sig: NR2B1 port map (NA=>in_enable, B=>select_inv(ctxt), Z=>enable);
        addr_sel_3: AN2 port map (A=>enable, B=>in_address(3), Z=>l2_address(ctxt)(0));
        addr_sel_4: AN2 port map (A=>enable, B=>in_address(4), Z=>l2_address(ctxt)(1));
        addr_sel_5: AN2 port map (A=>enable, B=>in_address(5), Z=>l2_address(ctxt)(2));
      end generate;
      
    end generate;
    
  end generate;
  
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
  dec_buf_0: BUF port map (A=>l2_address(0), Z=>decode_buf(0));
  dec_inv_0: INV port map (A=>l2_address(0), Z=>decode_inv(0));
  dec_buf_1: BUF port map (A=>l2_address(1), Z=>decode_buf(1));
  dec_inv_1: INV port map (A=>l2_address(1), Z=>decode_inv(1));
  dec_buf_2: BUF port map (A=>l2_address(2), Z=>decode_buf(2));
  dec_inv_2: INV port map (A=>l2_address(2), Z=>decode_inv(2));
  
  dec_out_0: NR3 port map (A=>decode_buf(0), B=>decode_buf(1), C=>decode_buf(2), Z=>dec_enable(0));
  dec_out_1: NR3 port map (A=>decode_inv(0), B=>decode_buf(1), C=>decode_buf(2), Z=>dec_enable(1));
  dec_out_2: NR3 port map (A=>decode_buf(0), B=>decode_inv(1), C=>decode_buf(2), Z=>dec_enable(2));
  dec_out_3: NR3 port map (A=>decode_inv(0), B=>decode_inv(1), C=>decode_buf(2), Z=>dec_enable(3));
  dec_out_4: NR3 port map (A=>decode_buf(0), B=>decode_buf(1), C=>decode_inv(2), Z=>dec_enable(4));
  dec_out_5: NR3 port map (A=>decode_inv(0), B=>decode_buf(1), C=>decode_inv(2), Z=>dec_enable(5));
  dec_out_6: NR3 port map (A=>decode_buf(0), B=>decode_inv(1), C=>decode_inv(2), Z=>dec_enable(6));
  dec_out_7: NR3 port map (A=>decode_inv(0), B=>decode_inv(1), C=>decode_inv(2), Z=>dec_enable(7));
  
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
  dec_buf_0: BUF port map (A=>l2_address(0), Z=>decode_buf(0));
  dec_inv_0: INV port map (A=>l2_address(0), Z=>decode_inv(0));
  dec_buf_1: BUF port map (A=>l2_address(1), Z=>decode_buf(1));
  dec_inv_1: INV port map (A=>l2_address(1), Z=>decode_inv(1));
  dec_buf_2: BUF port map (A=>l2_address(2), Z=>decode_buf(2));
  dec_inv_2: INV port map (A=>l2_address(2), Z=>decode_inv(2));
  dec_inv_3: INV port map (A=>l2_enable,     Z=>decode_inv(3));
  
  dec_out_0: NR4 port map (A=>decode_buf(0), B=>decode_buf(1), C=>decode_buf(2), D=>decode_inv(3), Z=>dec_enable(0));
  dec_out_1: NR4 port map (A=>decode_inv(0), B=>decode_buf(1), C=>decode_buf(2), D=>decode_inv(3), Z=>dec_enable(1));
  dec_out_2: NR4 port map (A=>decode_buf(0), B=>decode_inv(1), C=>decode_buf(2), D=>decode_inv(3), Z=>dec_enable(2));
  dec_out_3: NR4 port map (A=>decode_inv(0), B=>decode_inv(1), C=>decode_buf(2), D=>decode_inv(3), Z=>dec_enable(3));
  dec_out_4: NR4 port map (A=>decode_buf(0), B=>decode_buf(1), C=>decode_inv(2), D=>decode_inv(3), Z=>dec_enable(4));
  dec_out_5: NR4 port map (A=>decode_inv(0), B=>decode_buf(1), C=>decode_inv(2), D=>decode_inv(3), Z=>dec_enable(5));
  dec_out_6: NR4 port map (A=>decode_buf(0), B=>decode_inv(1), C=>decode_inv(2), D=>decode_inv(3), Z=>dec_enable(6));
  dec_out_7: NR4 port map (A=>decode_inv(0), B=>decode_inv(1), C=>decode_inv(2), D=>decode_inv(3), Z=>dec_enable(7));
  
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
  din_0: AOI22 port map (A1=>write_datas(0), A2=>write_enables(0), B1=>write_datas(1), B2=>write_enables(1), Z=>din4(0));
  din_1: AOI22 port map (A1=>write_datas(2), A2=>write_enables(2), B1=>write_datas(3), B2=>write_enables(3), Z=>din4(1));
  din_2: AOI22 port map (A1=>write_datas(4), A2=>write_enables(4), B1=>write_datas(5), B2=>write_enables(5), Z=>din4(2));
  din_3: AOI22 port map (A1=>write_datas(6), A2=>write_enables(6), B1=>write_datas(7), B2=>write_enables(7), Z=>din4(3));
  din_x: ND4   port map (A=>din4(0), B=>din4(1), C=>din4(2), D=>din4(3), Z=>din);
  
  -- Instantiate the memory element.
  mem:   DFEQ  port map (D=>din, E=>write_enable, CK=>clk, Q=>dout);
  
  -- Instantiate the output buffers.
  buf_gen: for i in read_datas'range generate
    buf_x: BUFT port map (E=>read_enables(i), A=>dout, Z=>read_datas(i));
  end generate;
  
end structural;

--=============================================================================
-- One of the 32-bit general-purpose registers.
--=============================================================================
library ieee;
use ieee.std_logic_1164.all;

library rvex;
use rvex.asic_primitives.all;
use rvex.asic_types.all;
-- pragma translate_off
use rvex.simUtils_pkg.all;
-- pragma translate_on

entity reg32 is
  port (
    clk           : in    std_logic;
    write_enables : in    bitvec8;
    write_datas   : in    bitvec32_array(7 downto 0);
    read_enables  : in    bitvec16;
    read_datas    : inout bitvec32_vec16
  );
end reg32;

architecture structural of reg32 is
  signal write_enable4  : bitvec4;
  signal write_enable   : std_logic;
begin
  
  -- Generate an 8-wide or gate for the write enable signals.
  wen_0: NR2 port map (A=>write_enables(0), B=>write_enables(1), Z=>write_enable4(0));
  wen_1: NR2 port map (A=>write_enables(2), B=>write_enables(3), Z=>write_enable4(1));
  wen_2: NR2 port map (A=>write_enables(4), B=>write_enables(5), Z=>write_enable4(2));
  wen_3: NR2 port map (A=>write_enables(6), B=>write_enables(7), Z=>write_enable4(3));
  wen_x: ND4 port map (A=>write_enable4(0), B=>write_enable4(1), C=>write_enable4(2), D=>write_enable4(3), Z=>write_enable);
  
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
    read_datas      : inout bitvec32_vec16
    
  );
end reg8x32;

architecture structural of reg8x32 is
  signal write_enables_local  : bitvec8_array(7 downto 0);
  signal read_enables_local   : bitvec16_array(7 downto 0);
  signal read_datas_local     : bitvec32_vec16;
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
          --read_buf_x: BUFT port map (E=>read_enables_local(reg)(prt), A=>read_datas_local(prt)(bt), Z=>read_datas_local(prt)(bt));
          read_buf_x: BUFT port map (E=>read_enables_local(reg)(prt), A=>'0', Z=>read_datas_local(prt)(bt));
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
      read_buf_x: BUFT port map (E=>read_enables(prt), A=>read_datas_local(prt)(bt), Z=>read_datas(prt)(bt));
    end generate;
  end generate;
  
end structural;

--=============================================================================
-- A block of the number of contexts times 63 32-bit registers with 8 write
-- ports and 16 read ports; i.e. the complete register file for an 8-way,
-- n-context r-VEX.
--=============================================================================
library ieee;
use ieee.std_logic_1164.all;

library rvex;
use rvex.asic_primitives.all;
use rvex.asic_types.all;

entity gpregfile is
  generic (
    numContextsLog2 : natural
  );
  port (
    clk             : in    std_logic;
    
    -- Write address, enable, and data for each write port.
    write_addresses : in    bitvec8_array(7 downto 0);
    write_enables   : in    bitvec8;
    write_datas     : in    bitvec32_array(7 downto 0);
    
    -- Read address, enable, and data for each read port.
    read_addresses  : in    bitvec8_array(15 downto 0);
    read_datas      : inout bitvec32_vec16
    
  );
end gpregfile;

architecture structural of gpregfile is
  signal write_addresses_local  : bitvec3_vec4_array(7 downto 0);
  signal write_enables_local    : bitvec8_vec4_array(7 downto 0);
  signal read_addresses_local   : bitvec3_vec4_array(15 downto 0);
  signal read_enables_local     : bitvec8_vec4_array(15 downto 0);
begin
  
  -- Generate the level-1 write address decoders.
  write_dec_lvl1_gen: for prt in 7 downto 0 generate
    write_dec_lvl1_x: entity work.dec_lvl1
      generic map (
        writePort       => true,
        numContextsLog2 => numContextsLog2
      )
      port map (
        in_address      => write_addresses(prt)(numContextsLog2+5 downto 0),
        in_enable       => write_enables(prt),
        l2_address      => write_addresses_local(prt),
        l2_enable       => write_enables_local(prt)
      );
  end generate;
  
  -- Generate the level-1 read address decoders.
  read_dec_lvl1_gen: for prt in 15 downto 0 generate
    read_dec_lvl1_x: entity work.dec_lvl1
      generic map (
        writePort       => false,
        numContextsLog2 => numContextsLog2
      )
      port map (
        in_address      => read_addresses(prt)(numContextsLog2+5 downto 0),
        l2_address      => read_addresses_local(prt),
        l2_enable       => read_enables_local(prt)
      );
  end generate;
  
  -- Generate the register blocks.
  blk_gen: for blk in 8*2**numContextsLog2-1 downto 0 generate
    constant first_blk        : boolean := (blk mod 8) = 0;
    signal write_addresses_x  : bitvec3_array(7 downto 0);
    signal write_enables_x    : bitvec8;
    signal read_addresses_x   : bitvec3_array(15 downto 0);
    signal read_enables_x     : bitvec16;
  begin
    
    -- Unpack the control signals.
    unpack_write_gen: for prt in 7 downto 0 generate
      write_addresses_x(prt) <= write_addresses_local(prt)(blk/8);
      write_enables_x(prt)   <= write_enables_local(prt)(blk/8)(blk mod 8);
    end generate;
    unpack_read_gen: for prt in 15 downto 0 generate
      read_addresses_x(prt)  <= read_addresses_local(prt)(blk/8);
      read_enables_x(prt)    <= read_enables_local(prt)(blk/8)(blk mod 8);
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
        read_datas      => read_datas
      );
    
  end generate;
  
end structural;

--=============================================================================
-- An address compare block for a forwarding cell.
--=============================================================================
library ieee;
use ieee.std_logic_1164.all;

library rvex;
use rvex.asic_primitives.all;
use rvex.asic_types.all;

entity fwd_match is
  port (
    
    -- Coupled bit from the configuration controller.
    coupled         : in  std_logic;
    
    -- Forward address and enable from the data source.
    fwd_address     : in  bitvec6;
    fwd_enable      : in  std_logic;
    
    -- Read address to compare with.
    read_address    : in  bitvec6;
    
    -- Whether a match is detected.
    match           : out std_logic
    
  );
end fwd_match;

architecture structural of fwd_match is
  signal address_neq_b  : bitvec6;
  signal address_neq    : std_logic;
  signal disable        : std_logic;
begin
  
  -- Compare the addresses with XOR gates.
  addr_bit_gen: for i in 5 downto 0 generate
    addr_bit_x: XOR2 port map (A=>fwd_address(i), B=>read_address(i), Z=>address_neq_b(i));
  end generate;
  
  -- Detect if all address bits match.
  addr_match_inst: OR6 port map (A=>address_neq_b(0), B=>address_neq_b(1),
    C=>address_neq_b(2), D=>address_neq_b(3), E=>address_neq_b(4),
    F=>address_neq_b(5), Z=>address_neq);
  
  -- Combine the enable and coupled signals.
  disable_inst: ND2 port map (A=>fwd_enable, B=>coupled, Z=>disable);
  
  -- Combine the address match signal and the disable signal.
  match_inst: NR2 port map (A=>disable, B=>address_neq, Z=>match);
  
end structural;

--=============================================================================
-- The arbitration logic for a single bit's worth of forwarding, from 8
-- forwarding ports to one 
--=============================================================================
library ieee;
use ieee.std_logic_1164.all;

library rvex;
use rvex.asic_primitives.all;
use rvex.asic_types.all;

entity fwd_arb is
  port (
    fwd_match     : in  bitvec8;
    fwd_match_any : in  std_logic;
    fwd_datas     : in  bitvec8;
    read_data_in  : in  std_logic;
    read_data_out : out std_logic
  );
end fwd_arb;

architecture structural of fwd_arb is
  signal fwd_data4  : bitvec4;
  signal fwd_data   : std_logic;
begin
  
  -- Use wired-or to merge the read data.
  din_0: AOI22 port map (A1=>fwd_datas(0), A2=>fwd_match(0), B1=>fwd_datas(1), B2=>fwd_match(1), Z=>fwd_data4(0));
  din_1: AOI22 port map (A1=>fwd_datas(2), A2=>fwd_match(2), B1=>fwd_datas(3), B2=>fwd_match(3), Z=>fwd_data4(1));
  din_2: AOI22 port map (A1=>fwd_datas(4), A2=>fwd_match(4), B1=>fwd_datas(5), B2=>fwd_match(5), Z=>fwd_data4(2));
  din_3: AOI22 port map (A1=>fwd_datas(6), A2=>fwd_match(6), B1=>fwd_datas(7), B2=>fwd_match(7), Z=>fwd_data4(3));
  din_x: ND4   port map (A=>fwd_data4(0), B=>fwd_data4(1), C=>fwd_data4(2), D=>fwd_data4(3), Z=>fwd_data);
  
  -- Multiplex between the forwarded data and the data from the next stage/
  -- register file.
  mux_inst: MUX2 port map (S=>fwd_match_any, A=>read_data_in, B=>fwd_data, Z=>read_data_out);
  
end structural;

--=============================================================================
-- A forwarding cell, from 8 forward ports, 1 stage, to 1 read port.
--=============================================================================
library ieee;
use ieee.std_logic_1164.all;

library rvex;
use rvex.asic_primitives.all;
use rvex.asic_types.all;

entity fwd1x8to1 is
  port (
    
    -- Coupled bits from the configuration controller.
    coupled         : in  bitvec4;
    
    -- Forward address, enable, and data for each write port.
    fwd_addresses   : in  bitvec6_array(7 downto 0);
    fwd_enables     : in  bitvec8;
    fwd_datas       : in  bitvec32_array(7 downto 0);
    
    -- Read address to compare with.
    read_address    : in  bitvec6;
    
    -- Data input from the next stage or the register file.
    read_datas_in   : in  bitvec32;
    
    -- Forwarded data output.
    read_datas_out  : out bitvec32
    
  );
end fwd1x8to1;

architecture structural of fwd1x8to1 is
  signal match      : bitvec8;
  signal match_any4 : bitvec4;
  signal match_any  : std_logic;
begin
  
  -- Determine for each write port if forwarding from that port is enabled and
  -- if there is an address match.
  match_gen: for prt in 0 to 7 generate
    match_x: entity rvex.fwd_match
      port map (
        coupled       => coupled(prt/2),
        fwd_address   => fwd_addresses(prt),
        fwd_enable    => fwd_enables(prt),
        read_address  => read_address,
        match         => match(prt)
      );
  end generate;
  
  -- Generate an 8-wide or gate for the match signals.
  match_0: NR2 port map (A=>match(0), B=>match(1), Z=>match_any4(0));
  match_1: NR2 port map (A=>match(2), B=>match(3), Z=>match_any4(1));
  match_2: NR2 port map (A=>match(4), B=>match(5), Z=>match_any4(2));
  match_3: NR2 port map (A=>match(6), B=>match(7), Z=>match_any4(3));
  match_x: ND4 port map (A=>match_any4(0), B=>match_any4(1), C=>match_any4(2), D=>match_any4(3), Z=>match_any);
  
  -- Generate the arbiter for each bit.
  bit_gen: for i in 31 downto 0 generate
    signal fwd_datas_x  : bitvec8;
  begin
    
    -- Unpack the 2D forward data array.
    fwd_unpack_gen: for j in fwd_enables'range generate
      fwd_datas_x(j) <= fwd_datas(j)(i);
    end generate;
    
    fwd_arb_x: entity rvex.fwd_arb
      port map (
        fwd_match     => match,
        fwd_match_any => match_any,
        fwd_datas     => fwd_datas_x,
        read_data_in  => read_datas_in(i),
        read_data_out => read_datas_out(i)
      );
    
  end generate;
  
end structural;

--=============================================================================
-- A complete forwarding stage for an 8-way r-VEX.
--=============================================================================
library ieee;
use ieee.std_logic_1164.all;

library rvex;
use rvex.asic_primitives.all;
use rvex.asic_types.all;

entity fwd1x8to16 is
  port (
    
    -- Coupled bits from the configuration controller.
    coupled         : in  bitvec16;
    
    -- Forward address, enable, and data for each write port.
    fwd_addresses   : in  bitvec6_array(7 downto 0);
    fwd_enables     : in  bitvec8;
    fwd_datas       : in  bitvec32_array(7 downto 0);
    
    -- Read address to compare with.
    read_addresses  : in  bitvec8_array(15 downto 0);
    
    -- Data input from the next stage or the register file.
    read_datas_in   : in  bitvec32_vec16;
    
    -- Forwarded data output.
    read_datas_out  : out bitvec32_vec16
    
  );
end fwd1x8to16;

architecture structural of fwd1x8to16 is
begin
  port_gen: for i in 0 to 15 generate
    constant grp : natural := i / 4;
  begin
    port_x: entity rvex.fwd1x8to1
      port map (
        coupled         => coupled(grp*4+3 downto grp*4),
        fwd_addresses   => fwd_addresses,
        fwd_enables     => fwd_enables,
        fwd_datas       => fwd_datas,
        read_address    => read_addresses(i)(5 downto 0),
        read_datas_in   => read_datas_in(i),
        read_datas_out  => read_datas_out(i)
      );
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
use rvex.core_pkg.all;
use rvex.core_intIface_pkg.all;
use rvex.core_pipeline_pkg.all;
use rvex.asic_primitives.all;
use rvex.asic_types.all;
-- pragma translate_off
use rvex.simUtils_pkg.all;
-- pragma translate_on

--=============================================================================
entity core_gpRegs_asic is
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
end core_gpRegs_asic;

--=============================================================================
architecture Behavioral of core_gpRegs_asic is
--=============================================================================
  
  -- Combined clkEn/stall signal for each lane group.
  signal stall_buf      : bitvec4;
  
  -- Read addresses.
  signal read_addresses : bitvec8_array(15 downto 0);
  
  -- Read data.
  signal read_datas     : bitvec32_vec16_array(S_WB+1 downto S_RD+L_RD+1);
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -- Make sure that our assumptions about the core configuration parameters are
  -- correct.
  assert CFG.numLanesLog2 = 3
    report "The ASIC register file implementation is hand-optimized for 8 " &
    "lanes." severity failure;
  
  assert CFG.numLaneGroupsLog2 = 2
    report "The ASIC register file implementation is hand-optimized for 4 " &
    "lane groups." severity failure;
  
  assert L_WB = 0
    report "The register file writeback latency should be set to 0 for the " &
    "ASIC implementation." severity warning;
  
  assert L_RD = 1
    report "The ASIC implementation of the register file requires that L_RD " &
    "= 1." severity failure;
  
  assert S_RD+L_RD = S_FW
    report "Only one set of forwarding destinations is supported by the " &
    "ASIC register file implementation." severity failure;
  
  -- Buffer the stall signal and merge it with clkEn to reduce the fanout of
  -- those signals.
  stall_buf_gen: for grp in 0 to 3 generate
    stall_buf_x: ND2B1 port map (NA=>stall(grp), B=>clkEn, Z=>stall_buf(grp));
  end generate;
  
  -- Instantiate the read address logic. Unlike the FPGA register file, the
  -- ASIC implementation uses the signals from S_RD for the register file
  -- itself as well as the forwarding logic. This allows registers to be
  -- instantiated outside of the pipelane for the forwarding as well. These
  -- registers are only enabled when the port readEnable is high, stall is low,
  -- and clkEn is high, thus reducing read port switching activity to zero when
  -- any of those signals is inactive to save power.
  read_addr_port_gen: for prt in 1 to 15 generate
    constant grp  : natural := prt/4;
    signal ena    : std_logic;
  begin
    
    -- Generate the enable signal for this port.
    ena_inst: NR2B1 port map (NA=>pl2gpreg_readPorts(prt).readEnable(S_RD),
      B=>stall_buf(grp), Z=>ena);
    
    -- Generate the register for each address bit.
    addr_reg_gen: for i in 5 downto 0 generate
      addr_reg_inst: DFEQ port map (D => pl2gpreg_readPorts(prt).addr(S_RD)(i),
        E => ena, CK=>clk, Q=>read_addresses(prt)(i));
    end generate;
    
    -- The context inputs do not need registers, because they only change
    -- during reconfiguration, and reconfigurations never occur accross read
    -- accesses, because affected lanes must be idle for a reconfiguration to
    -- be committed.
    multi_ctxt_gen: if CFG.numContextsLog2 > 0 generate
      read_addresses(prt)(5+CFG.numContextsLog2 downto 6)
        <= cfg2any_context(grp)(CFG.numContextsLog2-1 downto 0);
    end generate;
    
  end generate;
  
  -- Port 0 is a bit different, because the debug bus can override it.
  read_addr_port_0: block is
    signal ena1, ena  : std_logic;
    signal addr       : std_logic_vector(CFG.numContextsLog2+5 downto 0);
  begin
    
    -- Generate the enable signal for this port.
    ena1_inst: NR2B1 port map (NA=>pl2gpreg_readPorts(0).readEnable(S_RD), B=>stall_buf(0), Z=>ena1);
    ena_inst: OR2 port map (A=>ena1, B=>creg2gpreg_claim, Z=>ena);
    
    -- Select the address bits.
    addr_select_gen: for i in 0 to 5 generate
      addr_mux_x: MUX2 port map (
        S => creg2gpreg_claim,
        A => pl2gpreg_readPorts(0).addr(S_RD)(i),
        B => creg2gpreg_addr(i),
        Z => addr(i)
      );
    end generate;
    
    -- Select the context bits.
    ctxt_select_gen: for i in 0 to CFG.numContextsLog2-1 generate
      addr_mux_x: MUX2 port map (
        S => creg2gpreg_claim,
        A => cfg2any_context(0)(i),
        B => creg2gpreg_ctxt(i),
        Z => addr(6+i)
      );
    end generate;
    
    -- Generate the register for each address and context bit.
    addr_reg_gen: for i in addr'range generate
      addr_reg_inst: DFEQ port map (D=>addr(i), E=>ena, CK=>clk, Q=>read_addresses(0)(i));
    end generate;
    
  end block;
  
  -- Instantiate and connect the register file.
  regfile_block: block is
    signal write_addresses  : bitvec8_array(7 downto 0);
    signal write_enables    : bitvec8;
    signal write_datas      : bitvec32_array(7 downto 0);
  begin
    
    -- Connect write ports 1 through 7. The enable signal is asserted only when
    -- the port enable signal is high, clkEn is high, and stall is low.
    write_connect_gen: for prt in 1 to 7 generate
      constant grp  : natural := prt/2;
    begin
      
      -- Generate the write enable signal for this port.
      ena_inst: NR2B1 port map (NA=>pl2gpreg_writePorts(prt).writeEnable(S_WB),
        B=>stall_buf(grp), Z=>write_enables(prt));
      
      -- Connect the address bits.
      write_addresses(prt)(5 downto 0) <= pl2gpreg_writePorts(prt).addr(S_WB);
      
      -- Connect the context bits.
      multi_ctxt_gen: if CFG.numContextsLog2 > 0 generate
        write_addresses(prt)(5+CFG.numContextsLog2 downto 6)
          <= cfg2any_context(grp)(CFG.numContextsLog2-1 downto 0);
      end generate;
      
      -- Connect the data bits.
      write_datas(prt) <= pl2gpreg_writePorts(prt).data(S_WB);
      
    end generate;
    
    -- Connect write port 0. This port can be overridden by the debug bus, so
    -- it works a little different than the others.
    write_connect_0: block is
      signal ena1 : std_logic;
    begin
      
      -- Generate the write enable signal for this port.
      ena1_inst: NR2B1 port map (NA=>pl2gpreg_writePorts(0).writeEnable(S_WB),
        B=>stall_buf(0), Z=>ena1);
      ena_inst: AO21 port map (A1=>creg2gpreg_claim, A2=>creg2gpreg_writeEnable,
        B=>ena1, Z=>write_enables(0));
      
      -- Select the address bits.
      addr_select_gen: for i in 0 to 5 generate
        addr_mux_x: MUX2 port map (
          S => creg2gpreg_claim,
          A => pl2gpreg_writePorts(0).addr(S_WB)(i),
          B => creg2gpreg_addr(i),
          Z => write_addresses(0)(i)
        );
      end generate;
      
      -- Select the context bits.
      ctxt_select_gen: for i in 0 to CFG.numContextsLog2-1 generate
        addr_mux_x: MUX2 port map (
          S => creg2gpreg_claim,
          A => cfg2any_context(0)(i),
          B => creg2gpreg_ctxt(i),
          Z => write_addresses(0)(6+i)
        );
      end generate;
      
      -- Select the data bits.
      addr_reg_gen: for i in 31 downto 0 generate
        addr_mux_x: MUX2 port map (
          S => creg2gpreg_claim,
          A => pl2gpreg_writePorts(0).data(S_WB)(i),
          B => creg2gpreg_writeData(i),
          Z => write_datas(0)(i)
        );
      end generate;
      
    end block;
    
    -- Instantiate the register file.
    regfile_inst: entity rvex.gpregfile
      generic map (
        numContextsLog2 => CFG.numContextsLog2
      )
      port map (
        clk             => clk,
        write_addresses => write_addresses,
        write_enables   => write_enables,
        write_datas     => write_datas,
        read_addresses  => read_addresses,
        read_datas      => read_datas(S_WB+1)
      );
    
  end block;
  
  -- Generate the forwarding logic.
  fwd_gen: for stage in S_RD+L_RD+1 to S_WB generate
    signal fwd_addresses  : bitvec6_array(7 downto 0);
    signal fwd_enables    : bitvec8;
    signal fwd_datas      : bitvec32_array(7 downto 0);
  begin
    
    -- Connect the forwarding ports.
    write_connect_gen: for prt in 0 to 7 generate
    begin
      
      -- Connect the forward enable bits.
      fwd_enables(prt) <= pl2gpreg_writePorts(prt).forwardEnable(stage);
      
      -- Connect the address bits.
      fwd_addresses(prt) <= pl2gpreg_writePorts(prt).addr(stage);
      
      -- Connect the data bits.
      fwd_datas(prt) <= pl2gpreg_writePorts(prt).data(stage);
      
    end generate;
    
    -- Instantiate the forwarding logic for this stage.
    fwd_inst: entity rvex.fwd1x8to16
      port map (
        coupled         => cfg2any_coupled,
        fwd_addresses   => fwd_addresses,
        fwd_enables     => fwd_enables,
        fwd_datas       => fwd_datas,
        read_addresses  => read_addresses,
        read_datas_in   => read_datas(stage+1),
        read_datas_out  => read_datas(stage)
      );
    
  end generate;
  
  -- Connect the read data output.
  read_data_gen: for prt in 0 to 15 generate
    gpreg2pl_readPorts(prt).data(S_RD+L_RD) <= read_datas(S_RD+L_RD+1)(prt);
    gpreg2pl_readPorts(prt).valid(S_RD+L_RD) <= '1';
  end generate;
  
  gpreg2creg_readData <= read_datas(S_WB+1)(0);
  
end Behavioral;

