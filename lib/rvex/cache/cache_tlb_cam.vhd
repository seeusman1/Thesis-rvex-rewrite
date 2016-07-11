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
use rvex.cache_pkg.all;
use rvex.utils_pkg.all;

--=============================================================================
-- This entity represents a content-addressable memory, used by the CAM. It is
-- implemented using block RAMs or distributed RAM. A 10-bit input (data) and
-- a 5-bit output (address) results in one 36kib block RAM. Essentially, the
-- data is used as the address of the RAM, and the associated address is
-- one-hot encoded in the RAM data. When the data needs to be larger than the
-- maximum number of RAM address bits bits, the data is split into multiple
-- parts, each fed to a different RAM. Because the indices are one-hot encoded,
-- the RAM outputs can just be ANDed together. This results in linear resource
-- utilization versus data width instead of exponential. The address is
-- returned still in one-hot format, to allow multiple CAMs to work together.
-- This allows some of those individual CAMs to be conditionally ignored.
-------------------------------------------------------------------------------
entity cache_tlb_cam is
--=============================================================================
  generic (
    
    -- Width of the data that is to be looked up.
    DATA_W                      : natural := 10;
    
    -- Width of the address in bits = the log2 of the number of entries.
    ADDR_W                      : natural := 5;
    
    -- Implementation style.
    STYLE                       : cache_cam_ram_style_type := CRS_DEFAULT
    
  );
  port (
    
    ---------------------------------------------------------------------------
    -- System control
    ---------------------------------------------------------------------------
    -- Clock input, registers are rising edge triggered.
    clk                         : in  std_logic;
    
    -- Active high global clock enable input.
    clkEn                       : in  std_logic;
    
    ---------------------------------------------------------------------------
    -- Read port
    ---------------------------------------------------------------------------
    -- Data input for lookup and modification.
    data                        : in  std_logic_vector(DATA_W-1 downto 0);
    
    -- One-hot encoded address output, valid one clkEn'd cycle after data.
    addr_oneHot                 : out std_logic_vector(2**ADDR_W-1 downto 0);
    
    ---------------------------------------------------------------------------
    -- Write port
    ---------------------------------------------------------------------------
    -- Update operation. The following values are valid:
    --  - "00": no-operation.
    --  - "01": add the mapping from data* to update_addr.
    --  - "10": remove the mapping from data* to update_addr.
    --  - "11": remove the mappings from data to any address.
    -- *data must have been valid and equal in the preceding cycle.
    update_op                   : in  std_logic_vector(1 downto 0);
    
    -- The address to modify.
    update_addr                 : in  std_logic_vector(ADDR_W-1 downto 0)
    
  );
end cache_tlb_cam;

--=============================================================================
architecture arch of cache_tlb_cam is
--=============================================================================
  
  -- Number of data bits per RAM.
  type bpl_table_type is array (cache_cam_ram_style_type) of natural;  
  constant BPL_TABLE            : bpl_table_type := (
    10, -- CRS_DEFAULT
    10, -- CRS_BRAM36
    9,  -- CRS_BRAM18
    5   -- CRS_DISTRIB
  );
  constant BITS_PER_LVL         : natural := BPL_TABLE(STYLE);
  
  -- Compute the number of RAMs needed.
  constant NUM_LVLS             : natural := (DATA_W + BITS_PER_LVL - 1) / BITS_PER_LVL;
  
  -- RAM implementation style.
  pure function resolve_ram_style (
    style : cache_cam_ram_style_type
  ) return string is
  begin
    if style = CRS_DISTRIB then
      return "distributed";
    end if;
    return "block";
  end resolve_ram_style;
  constant RAM_STYLE_STR        : string := resolve_ram_style(STYLE);
  
  -- RAM types.
  subtype ram_entry_type is std_logic_vector(2**ADDR_W-1 downto 0);
  type ram_entry_array is array (natural range <>) of ram_entry_type;
  subtype ram_array is ram_entry_array(0 to 2**BITS_PER_LVL-1);
  
  -- Read CAM address for each level.
  signal camReadAddrOH          : ram_entry_array(NUM_LVLS-1 downto 0);
  
  -- Write enable signal.
  signal writeEnable            : std_logic;
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -- Generate a single write enable signal for the RAMs.
  writeEnable <= update_op(0) or update_op(1);
  
  -- Generate the memories.
  ram_gen: for lvl in 0 to NUM_LVLS-1 generate
    
    -- Memory contents.
    signal mem                  : ram_array;
    attribute ram_style         : string;
    attribute ram_style of mem  : signal is RAM_STYLE_STR;
    
    -- Address for this level (CAM data);
    signal camData              : std_logic_vector(BITS_PER_LVL-1 downto 0);
    
    -- Modified write data (CAM one-hot address).
    signal camWriteAddrOH       : ram_entry_type;
    
  begin
    
    -- Select the data bits for this level.
    camData <= std_logic_vector(
      resize(shift_right(unsigned(data), lvl*BITS_PER_LVL), BITS_PER_LVL));
    
    -- Infer the memory.
    ram_proc: process (clk) is
    begin
      if rising_edge(clk) then
        if clkEn = '1' then
          if writeEnable = '1' then
            mem(to_integer(unsigned(camData))) <= camWriteAddrOH;
          end if;
          camReadAddrOH(lvl) <= mem(to_integer(unsigned(camData)));
        end if;
      end if;
    end process;
    
    -- Generate read-modify-write data.
    rmw_proc: process (camReadAddrOH(lvl), update_op, update_addr) is
    begin
      for i in 2**ADDR_W-1 downto 0 loop
        if to_integer(unsigned(update_addr)) = i then
          case update_op is
            when "01"   => camWriteAddrOH(i) <= '1'; -- add
            when "10"   => camWriteAddrOH(i) <= '0'; -- remove
            when others => camWriteAddrOH(i) <= '0'; -- flush
          end case;
        else
          case update_op is
            when "01"   => camWriteAddrOH(i) <= camReadAddrOH(lvl)(i);
            when "10"   => camWriteAddrOH(i) <= camReadAddrOH(lvl)(i);
            when others => camWriteAddrOH(i) <= '0'; -- flush
          end case;
        end if;
      end loop;
    end process;
    
  end generate;
  
  -- Combine the RAM outputs for each level.
  cam_data_proc: process (data) is
    variable d : ram_entry_type;
  begin
    d := camReadAddrOH(0);
    for lvl in 1 to NUM_LVLS-1 loop
      d := d and camReadAddrOH(lvl);
    end loop;
    addr_oneHot <= d;
  end process;
  
end architecture;
