-- r-VEX processor
-- Copyright (C) 2008-2014 by TU Delft.
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

-- 6. r-VEX was developed by Stephan Wong, Thijs van As, Fakhar Anjam, Roel Seedorf,
-- Anthony Brandon. r-VEX is currently maintained by TU Delft (J.S.S.M.Wong@tudelft.nl).

-- Copyright (C) 2008-2014 by TU Delft.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.rvex_pkg.all;
use work.rvex_intIface_pkg.all;

--=============================================================================
-- This instantiates a bunch of fully hardware controlled registers which have
-- a bus interface to them. Used by rvex_ctrlRegs.vhd.
-------------------------------------------------------------------------------
entity rvex_ctrlRegs_bank is
--=============================================================================
  generic (
    
    ---------------------------------------------------------------------------
    -- Configuration
    ---------------------------------------------------------------------------
    -- Starting address for the registers.
    OFFSET                      : natural;
    
    -- Number of words.
    NUM_WORDS                   : natural
    
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
    -- Bus interface
    ---------------------------------------------------------------------------
    -- Address for the request.
    addr                        : in  rvex_address_type;
    
    -- Active high read enable signal.
    readEnable                  : in  std_logic;
    
    -- Active high write enable signal.
    writeEnable                 : in  std_logic;
    
    -- Active high byte write mask signal.
    writeMask                   : in  rvex_mask_type;
    
    -- Write data.
    writeData                   : in  rvex_data_type;
    
    -- Origin of the request, used to select which write permission to use.
    -- Set low for core access, high for external debug bus access.
    origin                      : in  std_logic;
    
    -- (one clock cycle delay with clkEn high)
    
    -- Read data.
    readData                    : out rvex_data_type;
    
    ---------------------------------------------------------------------------
    -- Hardware interface
    ---------------------------------------------------------------------------
    -- Refer to the documentation for hw2bit_type and bit2hw_type types in
    -- rvex_ctrlRegs_pkg.vhd for more information.
    
    -- Interface for the global registers.
    logic2creg                  : in  logic2creg_array(OFFSET to OFFSET + NUM_WORDS - 1);
    creg2logic                  : out creg2logic_array(OFFSET to OFFSET + NUM_WORDS - 1)
    
  );
end rvex_ctrlRegs_bank;

--=============================================================================
architecture Behavioral of rvex_ctrlRegs_bank is
--=============================================================================
  
  -- Registers.
  signal r                      : rvex_data_array(OFFSET to OFFSET + NUM_WORDS - 1);
  
  -- Register data with combinatorial hardware override taken into
  -- consideration.
  signal rOvr                   : rvex_data_array(OFFSET to OFFSET + NUM_WORDS - 1);
  
  -- Decoded bus write enable signal for all bits in the register file.
  signal bw                     : rvex_data_array(OFFSET to OFFSET + NUM_WORDS - 1);
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -- Combinatorial write decoding.
  bus_write_decode: process (
    addr, writeEnable, writeMask, origin,
    logic2creg
  ) is
  begin
    
    -- See if the bus wants to write.
    if writeEnable = '1' then
    
      -- The bus wants to write, loop over all registers to find out what it
      -- wants to write.
      for a in OFFSET to OFFSET + NUM_WORDS - 1 loop
        if to_integer(unsigned(addr(31 downto 2))) = a then
          
          -- This address is addressed. Loop over the bytes to process byte
          -- mask.
          for i in 0 to 3 loop
            
            if writeMask(i) = '1' then
              
              -- Byte is in bytemask, write if we have permission.
              if origin = '0' then
                bw(a)(i*8+7 downto i*8) <= logic2creg(a).coreCanWrite(i*8+7 downto i*8);
              else
                bw(a)(i*8+7 downto i*8) <= logic2creg(a).dbgBusCanWrite(i*8+7 downto i*8);
              end if;
              
            else
              
              -- Byte is not in bytemask, no write here.
              bw(a)(i*8+7 downto i*8) <= (others => '0');
              
            end if;
            
          end loop;
          
        else
          
          -- This address is not addressed, no write here.
          bw(a) <= (others => '0');
          
        end if;
      end loop;
    
    else
      
      -- The bus is not writing.
      bw <= (others => (others => '0'));
      
    end if;
    
  end process;
  
  -- Synchronous write process.
  write_process: process (clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        
        -- Reset everything to the appropriate values.
        for a in OFFSET to OFFSET + NUM_WORDS - 1 loop
          r(a) <= logic2creg(a).resetValue;
        end loop;
        
      elsif clkEn = '1' then
        for a in OFFSET to OFFSET + NUM_WORDS - 1 loop
          for i in 0 to 31 loop
            
            -- Perform the write. Hardware takes precedence over bus.
            if logic2creg(a).writeEnable(i) = '1' then
              
              -- Hardware write.
              r(a)(i) <= logic2creg(a).writeData(i);
              
            elsif bw(a)(i) = '1' then
              
              -- Bus write.
              r(a)(i) <= writeData(i);
              
            end if;
            
          end loop;
        end loop;
      end if;
    end if;
  end process;
  
  -- Process combinatorial hardware overrides.
  override: process (r, logic2creg) is
  begin
    for a in OFFSET to OFFSET + NUM_WORDS - 1 loop
      for i in 0 to 31 loop
        if logic2creg(a).overrideEnable(i) = '1' then
          rOvr(a)(i) <= logic2creg(a).overrideData(i);
        else
          rOvr(a)(i) <= r(a)(i);
        end if;
      end loop;
    end loop;
  end process;
  
  -- Connect outputs to hardware.
  hw_outputs: process (
    rOvr, r, bw, writeData, readEnable, addr
  ) is
  begin
    for a in OFFSET to OFFSET + NUM_WORDS - 1 loop
      for i in 0 to 31 loop
        creg2logic(a).readData <= rOvr(a);
        creg2logic(a).readDataRaw <= r(a);
        creg2logic(a).busWrite <= bw(a);
        creg2logic(a).busWriteData <= writeData;
        if to_integer(unsigned(addr(31 downto 2))) = a then
          creg2logic(a).busRead <= readEnable;
        else
          creg2logic(a).busRead <= '0';
        end if;
      end loop;
    end loop;
  end process;
  
  -- Process bus reads.
  bus_reads: process (clk) is
    variable a: integer;
  begin
    if rising_edge(clk) then
      if reset = '1' then
        readData <= (others => RVEX_UNDEF);
      elsif clkEn = '1' then
        if readEnable = '1' then
          a := to_integer(unsigned(addr(31 downto 2)));
          if a >= OFFSET and a < OFFSET + NUM_WORDS then
            readData <= rOvr(a);
          else
            readData <= (others => RVEX_UNDEF);
          end if;
        else
          readData <= (others => RVEX_UNDEF);
        end if;
      end if;
    end if;
  end process;
  
end Behavioral;

