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

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.math_real.all;
library rvex;
use rvex.cache_pkg.all;


entity cache_mmu_cam is
  generic (
    CCFG                        : cache_generic_config_type := cache_cfg
  );
  port (
    
    clk                         : in  std_logic;
    reset                       : in  std_logic;

    -- this port returns the address where the output data can be found
    read_out_addr_normal        : out std_logic_vector(2**CCFG.tlbDepthLog2-1 downto 0);
    
    -- this is used to match a tag for large pages. This means with the L2 tag as 'dont care' 
    read_out_addr_large         : out std_logic_vector(2**CCFG.tlbDepthLog2-1 downto 0);
    
    -- this is used to match a tag for a global page. This means with the ASID as 'dont care'     
    read_out_addr_global        : out std_logic_vector(2**CCFG.tlbDepthLog2-1 downto 0);
    
    -- this is used to match a tag for a large and global page. This means with the ASID as 'dont care'         
    read_out_addr_large_global  : out std_logic_vector(2**CCFG.tlbDepthLog2-1 downto 0);

    -- read write modify ports.
    -- modify_in_address is registered when modify enable are high
    modify_en                   : in  std_logic;
    modify_add_remove           : in  std_logic; -- 1 for adding, 0 for removing
    modify_in_addr              : in  std_logic_vector(2**CCFG.tlbDepthLog2-1 downto 0);

    -- ports used for both read and read/write modify
    in_data                     : in  std_logic_vector(CCFG.asidBitWidth + mmuTagSize(CCFG)-1 downto 0)

  );
end entity cache_mmu_cam;


architecture arch of cache_mmu_cam is

  constant CAM_NUM_ENTRIES      : natural := 2**CCFG.tlbDepthLog2;

  constant CAM_BLOCK_DATA_WIDTH : natural := 10;
  constant CAM_BLOCK_ADDR_WIDTH : natural := 32;
  constant NUM_ASID_CAM_BLOCKS  : natural := integer(ceil(real(CCFG.asidBitWidth) / real(CAM_BLOCK_DATA_WIDTH)));
  constant NUM_L1_TAG_CAM_BLOCKS: natural := integer(ceil(real(mmuLargePageTagSize(CCFG)) / real(CAM_BLOCK_DATA_WIDTH)));
  constant NUM_L2_TAG_CAM_BLOCKS: natural := integer(ceil(real(mmuTagSize(CCFG) - mmuLargePageTagSize(CCFG)) / real(CAM_BLOCK_DATA_WIDTH)));
  constant NUM_CAM_BLOCKS       : natural := NUM_ASID_CAM_BLOCKS + NUM_L1_TAG_CAM_BLOCKS + NUM_L2_TAG_CAM_BLOCKS;
  constant CAM_ASID_DATA_PAD_LEN: natural := NUM_ASID_CAM_BLOCKS   * CAM_BLOCK_DATA_WIDTH - CCFG.asidBitWidth;
  constant CAM_L1_DATA_PAD_LEN  : natural := NUM_L1_TAG_CAM_BLOCKS * CAM_BLOCK_DATA_WIDTH - mmuLargePageTagSize(CCFG);
  constant CAM_L2_DATA_PAD_LEN  : natural := NUM_L2_TAG_CAM_BLOCKS * CAM_BLOCK_DATA_WIDTH - (mmuTagSize(CCFG) - mmuLargePageTagSize(CCFG));
  constant CAM_BLOCKS_DEPTH     : natural := integer(ceil(real(2**CCFG.tlbDepthLog2) / real(CAM_BLOCK_ADDR_WIDTH)));
  constant CAM_ADDR_WIDTH       : natural := CAM_BLOCK_ADDR_WIDTH * CAM_BLOCKS_DEPTH;
  constant CAM_ADDR_PAD_LEN     : natural := CAM_ADDR_WIDTH - 2**CCFG.tlbDepthLog2;
  
  
  type t_state is (read, mod_add, mod_rem);
  type t_address_vector is array (natural range<>) of std_logic_vector(CAM_ADDR_WIDTH-1 downto 0);
  type t_cam_reg is record
    state                       : t_state;
    modify_in_addr              : std_logic_vector(CAM_ADDR_WIDTH-1 downto 0);
    modify_in_data              : std_logic_vector(CCFG.asidBitWidth + mmuTagSize(CCFG)-1 downto 0);
  end record;
  
  constant R_INIT               : t_cam_reg := (
    state                       => read,
    modify_in_addr              => (others => '0'),
    modify_in_data              => (others => '0')
  );

  signal r                      : t_cam_reg := R_INIT;
  signal r_in                   : t_cam_reg := R_INIT;
  
  signal write_en               : std_logic;    

  signal in_data_asid           : std_logic_vector(NUM_ASID_CAM_BLOCKS   * CAM_BLOCK_DATA_WIDTH - 1 downto 0);
  signal in_data_L1             : std_logic_vector(NUM_L1_TAG_CAM_BLOCKS * CAM_BLOCK_DATA_WIDTH - 1 downto 0);
  signal in_data_L2             : std_logic_vector(NUM_L2_TAG_CAM_BLOCKS * CAM_BLOCK_DATA_WIDTH - 1 downto 0);
  
  signal read_out_addr_asid     : t_address_vector(NUM_ASID_CAM_BLOCKS-1   downto 0);
  signal read_out_addr_L1       : t_address_vector(NUM_L1_TAG_CAM_BLOCKS-1 downto 0);
  signal read_out_addr_L2       : t_address_vector(NUM_L2_TAG_CAM_BLOCKS-1 downto 0);

  signal write_in_addr_asid     : t_address_vector(NUM_ASID_CAM_BLOCKS-1   downto 0);
  signal write_in_addr_L1       : t_address_vector(NUM_L1_TAG_CAM_BLOCKS-1 downto 0);
  signal write_in_addr_L2       : t_address_vector(NUM_L2_TAG_CAM_BLOCKS-1 downto 0);
  

begin  
  
  CAM_gen: for i in 0 to CAM_BLOCKS_DEPTH-1 generate
    asid_CAM_gen: for j in 0 to NUM_ASID_CAM_BLOCKS-1 generate
      asid_CAM_n : entity work.cache_mmu_cam_ram
      port map (
        clk                     => clk,
        in_data                 => in_data_asid((j+1)*CAM_BLOCK_DATA_WIDTH-1 downto j*CAM_BLOCK_DATA_WIDTH),
        read_out_addr           => read_out_addr_asid(j)((i+1)*CAM_BLOCK_ADDR_WIDTH-1 downto i*CAM_BLOCK_ADDR_WIDTH),
        write_en                => write_en,
        write_in_addr           => write_in_addr_asid(j)((i+1)*CAM_BLOCK_ADDR_WIDTH-1 downto i*CAM_BLOCK_ADDR_WIDTH)
      );       
    end generate;
    
    L1_tag_CAM_gen: for j in 0 to NUM_L1_TAG_CAM_BLOCKS-1 generate
      L1_tag_CAM_n : entity work.cache_mmu_cam_ram
      port map (
        clk                     => clk,
        in_data                 => in_data_L1((j+1)*CAM_BLOCK_DATA_WIDTH-1 downto j*CAM_BLOCK_DATA_WIDTH),
        read_out_addr           => read_out_addr_L1(j)((i+1)*CAM_BLOCK_ADDR_WIDTH-1 downto i*CAM_BLOCK_ADDR_WIDTH),
        write_en                => write_en,
        write_in_addr           => write_in_addr_L1(j)((i+1)*CAM_BLOCK_ADDR_WIDTH-1 downto i*CAM_BLOCK_ADDR_WIDTH)
      );       
    end generate;   
    
    L2_tag_CAM_gen: for j in 0 to NUM_L2_TAG_CAM_BLOCKS-1 generate
      L2_tag_CAM_n : entity work.cache_mmu_cam_ram
      port map (
        clk                     => clk,
        in_data                 => in_data_L2((j+1)*CAM_BLOCK_DATA_WIDTH-1 downto j*CAM_BLOCK_DATA_WIDTH),
        read_out_addr           => read_out_addr_L2(j)((i+1)*CAM_BLOCK_ADDR_WIDTH-1 downto i*CAM_BLOCK_ADDR_WIDTH),
        write_en                => write_en,
        write_in_addr           => write_in_addr_L2(j)((i+1)*CAM_BLOCK_ADDR_WIDTH-1 downto i*CAM_BLOCK_ADDR_WIDTH)
      );
    end generate;       
  end generate;
  
  
  -- CAM read output process
  -- the address output of the CAM is the bitwise AND of the CAM blocks address outputs
  addr_output_proc : process (
    read_out_addr_asid, read_out_addr_L1, read_out_addr_L2
  ) is
    variable v_read_out_addr_asid : std_logic_vector(CAM_ADDR_WIDTH-1 downto 0);
    variable v_read_out_addr_L1   : std_logic_vector(CAM_ADDR_WIDTH-1 downto 0);
    variable v_read_out_addr_L2   : std_logic_vector(CAM_ADDR_WIDTH-1 downto 0);
  begin
  
    v_read_out_addr_asid := read_out_addr_asid(0);
    for i in 1 to NUM_ASID_CAM_BLOCKS-1 loop
      v_read_out_addr_asid := v_read_out_addr_asid and read_out_addr_asid(i);
    end loop;

    v_read_out_addr_L1 := read_out_addr_L1(0);
    for i in 1 to NUM_L1_TAG_CAM_BLOCKS-1 loop
      v_read_out_addr_L1 := v_read_out_addr_L1 and read_out_addr_L1(i);
    end loop;
    
    v_read_out_addr_L2 := read_out_addr_L2(0);
    for i in 1 to NUM_L2_TAG_CAM_BLOCKS-1 loop
      v_read_out_addr_L2 := v_read_out_addr_L2 and read_out_addr_L2(i);
    end loop;

    read_out_addr_large_global <= v_read_out_addr_L1(2**CCFG.tlbDepthLog2-1 downto 0);
    
    read_out_addr_global       <= v_read_out_addr_L1(2**CCFG.tlbDepthLog2-1 downto 0) 
                                  and v_read_out_addr_L2(2**CCFG.tlbDepthLog2-1 downto 0);
    
    read_out_addr_large        <= v_read_out_addr_asid (2**CCFG.tlbDepthLog2-1 downto 0)
                                  and v_read_out_addr_L1 (2**CCFG.tlbDepthLog2-1 downto 0);
    
    read_out_addr_normal       <= v_read_out_addr_asid (2**CCFG.tlbDepthLog2-1 downto 0)
                                  and v_read_out_addr_L1(2**CCFG.tlbDepthLog2-1 downto 0)
                                  and v_read_out_addr_L2(2**CCFG.tlbDepthLog2-1 downto 0);
    
  end process; -- addr_out_proc


  -- CAM modify state machine process
  -- modifying the data in the CAM is a read write modify operation
  CAM_mod_proc : process (
    r, in_data, modify_en, modify_add_remove, modify_in_addr, 
    read_out_addr_asid, read_out_addr_L1, read_out_addr_L2
  ) is
  begin

    -- signal default values
    r_in <= r;
    write_en <= '0';
    
    
    -- connect the right parts of the CAM input to the right CAM blocks
    -- the connections below are for modifying, using the latched modify input data
    -- when reading, these are overruled
    -- 
    --           --------------------------
    -- in_data:  | ASID | L1 Tag | L2 Tag |
    --           --------------------------  
    if CAM_ASID_DATA_PAD_LEN > 0 then
      in_data_asid <= (CAM_ASID_DATA_PAD_LEN-1 downto 0 => '0')
                    & r.modify_in_data(in_data'length-1 downto mmuTagSize(CCFG));
    else 
      in_data_asid <= r.modify_in_data(in_data'length-1 downto mmuTagSize(CCFG));
    end if;
    if CAM_L1_DATA_PAD_LEN > 0 then
      in_data_L1   <= (CAM_L1_DATA_PAD_LEN-1   downto 0 => '0')
                    & r.modify_in_data(mmuTagSize(CCFG)-1 downto mmuTagSize(CCFG) - mmuLargePageTagSize(CCFG));
    else
      in_data_L1   <= r.modify_in_data(mmuTagSize(CCFG)-1 downto mmuTagSize(CCFG) - mmuLargePageTagSize(CCFG));        
    end if;
    if CAM_L2_DATA_PAD_LEN > 0 then
      in_data_L2   <= (CAM_L2_DATA_PAD_LEN-1   downto 0 => '0')
                    & r.modify_in_data(mmuTagSize(CCFG) - mmuLargePageTagSize(CCFG) - 1 downto 0);
    else 
      in_data_L2   <= r.modify_in_data(mmuTagSize(CCFG) - mmuLargePageTagSize(CCFG) - 1 downto 0);
    end if;
    
    
    case( r.state ) is
    
      when read =>
      
        -- connect the read input data to the right CAM blocks
        if CAM_ASID_DATA_PAD_LEN > 0 then
          in_data_asid <= (CAM_ASID_DATA_PAD_LEN-1 downto 0 => '0')
                        & in_data(in_data'length-1 downto mmuTagSize(CCFG));
        else 
          in_data_asid <= in_data(in_data'length-1 downto mmuTagSize(CCFG));
        end if;
        if CAM_L1_DATA_PAD_LEN > 0 then
          in_data_L1   <= (CAM_L1_DATA_PAD_LEN-1   downto 0 => '0')
                        & in_data(mmuTagSize(CCFG)-1 downto mmuTagSize(CCFG) - mmuLargePageTagSize(CCFG));
        else
          in_data_L1   <= in_data(mmuTagSize(CCFG)-1 downto mmuTagSize(CCFG) - mmuLargePageTagSize(CCFG));        
        end if;
        if CAM_L2_DATA_PAD_LEN > 0 then
          in_data_L2   <= (CAM_L2_DATA_PAD_LEN-1   downto 0 => '0')
                        & in_data(mmuTagSize(CCFG) - mmuLargePageTagSize(CCFG) - 1 downto 0);
        else 
          in_data_L2   <= in_data(mmuTagSize(CCFG) - mmuLargePageTagSize(CCFG) - 1 downto 0);
        end if;
        
        
        if modify_en = '1' then        
        
          -- register modify input
          if CAM_ADDR_PAD_LEN > 0 then
            r_in.modify_in_addr <= (CAM_ADDR_PAD_LEN-1 downto 0 => '0') & modify_in_addr;
          else
            r_in.modify_in_addr <= modify_in_addr;
          end if;
          
          r_in.modify_in_data  <= in_data;
            
          if modify_add_remove = '1' then
            r_in.state <= mod_add;
          else
            r_in.state <= mod_rem;
          end if;          
        end if;
      
      when mod_add =>

      -- add a bit to the cam entry
      for i in 0 to NUM_ASID_CAM_BLOCKS-1 loop
        write_in_addr_asid(i) <= read_out_addr_asid(i) or r.modify_in_addr;
      end loop; 
      for i in 0 to NUM_L1_TAG_CAM_BLOCKS-1 loop
        write_in_addr_L1(i)   <= read_out_addr_L1(i)   or r.modify_in_addr;
      end loop;
      for i in 0 to NUM_L2_TAG_CAM_BLOCKS-1 loop
        write_in_addr_L2(i)   <= read_out_addr_L2(i)   or r.modify_in_addr;
      end loop;
      
      write_en <= '1';
      r_in.state <= read;
      
    when mod_rem =>

      -- remove a bit from the CAM entry
      for i in 0 to NUM_ASID_CAM_BLOCKS-1 loop
        write_in_addr_asid(i) <= read_out_addr_asid(i) and not r.modify_in_addr;
      end loop; 
      for i in 0 to NUM_L1_TAG_CAM_BLOCKS-1 loop
        write_in_addr_L1(i)   <= read_out_addr_L1(i)   and not r.modify_in_addr;
      end loop; 
      for i in 0 to NUM_L2_TAG_CAM_BLOCKS-1 loop
        write_in_addr_L2(i)   <= read_out_addr_L2(i)   and not r.modify_in_addr;
      end loop; 
      
      write_en <= '1';
      r_in.state <= read;
    
    end case;
  end process; -- CAM_mod_proc


  -- register process
  reg_process : process( clk )
  begin
    if rising_edge(clk) then
      if reset = '1' then
        r <= R_INIT;
      else
        r <= r_in;  
      end if;  
    end if;
  end process; -- reg_process


end architecture; -- arch
