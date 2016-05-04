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

-- 7. The MMU was developed by Jens Johansen.

-- Copyright (C) 2008-2016 by TU Delft.

library std;
use std.textio.all;

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use ieee.std_logic_textio.all;


-- The CAM is build out of blocks of BRAM which are 2^10 deep and 32 wide.
entity mmu_cam_ram is
  port (

    clk                         : in  std_logic;

    -- signals used for both reads and writes
    in_data                     : in  std_logic_vector(9 downto 0);
        
    -- read signals
    read_out_addr               : out std_logic_vector(31 downto 0);

    -- write signals 
    write_en                    : in  std_logic;
    write_in_addr               : in  std_logic_vector(31 downto 0)
    
  );
end entity; -- CAM


architecture behavioural of mmu_cam_ram is
  
  constant CAM_RAM_WIDTH        : integer := 32;
  constant CAM_RAM_DEPTH_LOG2   : integer := 10;
  constant CAM_RAM_DEPTH        : integer := 2**CAM_RAM_DEPTH_LOG2;
  
  type RAM_block_t is array (CAM_RAM_DEPTH-1 downto 0) of std_logic_vector(CAM_RAM_WIDTH-1 downto 0);

  constant RAM_BLOCK_INIT       : RAM_block_t := (others => (others => '0'));

  signal CAM_mem                : RAM_block_t := RAM_BLOCK_INIT;

begin


  mem_proc : process( clk, in_data, write_en, write_in_addr )
  begin

    if rising_edge(clk) then

      if write_en = '1' then

        CAM_mem(to_integer(unsigned(in_data))) <= write_in_addr;
        
      end if;

      read_out_addr <= CAM_mem(to_integer(unsigned(in_data)));
      
    end if;
    
  end process; -- mem_proc

end architecture;
