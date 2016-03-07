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

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

library work;
use work.common_pkg.all;
use work.utils_pkg.all;
use work.bus_pkg.all;
use work.core_ctrlRegs_pkg.all;

--=============================================================================
-- This unit interconnects the r-VEX and the AXI bridge such that it complies
-- with the ALMARVI interface specification.
-------------------------------------------------------------------------------
--
-- This unit performs the following mappings:
--
-- First 2 kiB block (LITTLE ENDIAN to be compatible with ALMARVI tools):
--   0x004 Program counter
--     -> CR_PC@0
--   0x008 Cycle count
--     -> CR_CYC@0
--   0x00c Lock cycle count
--     -> CR_STALL@0
--   0x200 Command
--     -> write only:
--         1 - reset  -> assert rvex_reset, assert rvex_run
--         2 - run    -> release rvex_reset, assert rvex_run
--         3 - break* -> release rvex_reset, release rvex_run
--   0x204 Start address (first instruction after reset)
--     -> stored in a register, passed to rvex_resetVect
--   0x300 Device class
--     -> 0x000D31F7
--   0x304 Device ID
--     -> CR_DCFG
--   0x308 Interface type
--     -> 0x00000000
--   0x30c DMEM size
--     -> 2**DMEM_DEPTH_LOG2
--   0x310 IMEM size
--     -> 2**IMEM_DEPTH_LOG2
--   0x314 PMEM size
--     -> 2**PMEM_DEPTH_LOG2
--   0x318 Total size*
--     -> 2**AXI_ADDRW_G
--   others
--     -> 0x00000000
--
-- Everything else (BIG ENDIAN to be compatible with r-VEX tools):
--   -> passthrough
--
-- * not part of the current ALMARVI spec.
--
-------------------------------------------------------------------------------
entity almarvi_iface is
--=============================================================================
  generic (
    
    -- Constants to be stored in the ALMARVI registers.
    AXI_ADDRW_G                 : integer;
    IMEM_DEPTH_LOG2             : integer;
    DMEM_DEPTH_LOG2             : integer;
    PMEM_DEPTH_LOG2             : integer;
    
    -- log2 of the number of r-VEX contexts.
    NUM_CONTEXTS_LOG2           : integer
    
  );
  port (
  
    -- System control.
    reset                       : in  std_logic;
    clk                         : in  std_logic;
    clkEn                       : in  std_logic;
    
    -- Bus to the AXI bridge.
    axi2almarvi                 : in  bus_mst2slv_type;
    almarvi2axi                 : out bus_slv2mst_type;
    
    -- Bus to the r-VEX.
    almarvi2rvex                : out bus_mst2slv_type;
    rvex2almarvi                : in  bus_slv2mst_type;
    
    -- r-VEX run control signals.
    rvex_run                    : out std_logic_vector(2**NUM_CONTEXTS_LOG2-1 downto 0);
    rvex_idle                   : in  std_logic_vector(2**NUM_CONTEXTS_LOG2-1 downto 0);
    rvex_reset                  : out std_logic_vector(2**NUM_CONTEXTS_LOG2-1 downto 0);
    rvex_resetVect              : out rvex_address_array(2**NUM_CONTEXTS_LOG2-1 downto 0);
    rvex_done                   : in  std_logic_vector(2**NUM_CONTEXTS_LOG2-1 downto 0)
    
  );
end almarvi_iface;

--=============================================================================
architecture Behavioral of almarvi_iface is
--=============================================================================
  
  -- Bus result mode register.
  type resultMode_type is (PASSTHROUGH, PASSTHROUGH_SWAP, OVERRIDE_SWAP);
  signal resultMode_d           : resultMode_type;
  signal resultMode_r           : resultMode_type;
  
  -- Bus result override value.
  signal resultOverride_d       : rvex_data_type;
  signal resultOverride_r       : rvex_data_type;
  
  -- Reset vector registers.
  signal rvex_resetVect_d       : rvex_address_array(2**NUM_CONTEXTS_LOG2-1 downto 0);
  signal rvex_resetVect_r       : rvex_address_array(2**NUM_CONTEXTS_LOG2-1 downto 0);
  
  -- Run control triggers.
  signal rvex_run_set           : std_logic_vector(2**NUM_CONTEXTS_LOG2-1 downto 0);
  signal rvex_run_clear         : std_logic_vector(2**NUM_CONTEXTS_LOG2-1 downto 0);
  signal rvex_reset_set         : std_logic_vector(2**NUM_CONTEXTS_LOG2-1 downto 0);
  signal rvex_reset_clear       : std_logic_vector(2**NUM_CONTEXTS_LOG2-1 downto 0);
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -- Instantiate all the registers.
  regs: process (clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        resultMode_r     <= PASSTHROUGH;
        resultOverride_r <= (others => '0');
        rvex_resetVect_r <= (others => (others => '0'));
        rvex_run         <= (others => '1');
        rvex_reset       <= (others => '1');
      elsif clkEn = '1' then
        resultMode_r     <= resultMode_d;
        resultOverride_r <= resultOverride_d;
        rvex_resetVect_r <= rvex_resetVect_d;
        for ctxt in 2**NUM_CONTEXTS_LOG2-1 downto 0 loop
          if rvex_run_set(ctxt) = '1' then
            rvex_run(ctxt) <= '1';
          elsif rvex_run_clear(ctxt) = '1' then
            rvex_run(ctxt) <= '0';
          end if;
          if rvex_reset_set(ctxt) = '1' then
            rvex_reset(ctxt) <= '1';
          elsif rvex_reset_clear(ctxt) = '1' then
            rvex_reset(ctxt) <= '0';
          end if;
        end loop;
      end if;
    end if;
  end process;
  
  -- Instantiate the bus request phase logic.
  request: process (axi2almarvi, rvex_resetVect_r) is
    variable axi2almarvi_swapped: bus_mst2slv_type;
    variable almarvi2rvex_v     : bus_mst2slv_type;
    variable resultMode_v       : resultMode_type;
    variable resultOverride_v   : rvex_data_type;
    variable rvex_resetVect_v   : rvex_address_array(2**NUM_CONTEXTS_LOG2-1 downto 0);
    variable rvex_run_set_v     : std_logic_vector(2**NUM_CONTEXTS_LOG2-1 downto 0);
    variable rvex_run_clear_v   : std_logic_vector(2**NUM_CONTEXTS_LOG2-1 downto 0);
    variable rvex_reset_set_v   : std_logic_vector(2**NUM_CONTEXTS_LOG2-1 downto 0);
    variable rvex_reset_clear_v : std_logic_vector(2**NUM_CONTEXTS_LOG2-1 downto 0);
  begin
    
    -- Set default to passthrough.
    almarvi2rvex_v     := axi2almarvi;
    resultMode_v       := PASSTHROUGH;
    resultOverride_v   := (others => '0');
    
    -- Don't change our state by default.
    rvex_resetVect_v   := rvex_resetVect_r;
    rvex_run_set_v     := (others => '0');
    rvex_run_clear_v   := (others => '0');
    rvex_reset_set_v   := (others => '0');
    rvex_reset_clear_v := (others => '0');
    
    -- Handle the ALMARVI control register block.
    if unsigned(axi2almarvi.address(AXI_ADDRW_G-1 downto 11)) = 0 then
      
      -- Swap the byte order in the request.
      axi2almarvi_swapped := axi2almarvi;
      axi2almarvi_swapped.writeData(31 downto 24) := axi2almarvi.writeData( 7 downto  0);
      axi2almarvi_swapped.writeData(23 downto 16) := axi2almarvi.writeData(15 downto  8);
      axi2almarvi_swapped.writeData(15 downto  8) := axi2almarvi.writeData(23 downto 16);
      axi2almarvi_swapped.writeData( 7 downto  0) := axi2almarvi.writeData(31 downto 24);
      axi2almarvi_swapped.writeMask(3) := axi2almarvi.writeMask(0);
      axi2almarvi_swapped.writeMask(2) := axi2almarvi.writeMask(1);
      axi2almarvi_swapped.writeMask(1) := axi2almarvi.writeMask(2);
      axi2almarvi_swapped.writeMask(0) := axi2almarvi.writeMask(3);
      
      -- Set default to NOP and override to 0.
      almarvi2rvex_v := BUS_MST2SLV_IDLE;
      resultMode_v   := OVERRIDE_SWAP;
      
      -- Handle the registers.
      case axi2almarvi.address(10 downto 2) is
        when "000000001" => -- 0x004 Program counter -> CR_PC@0
          almarvi2rvex_v := axi2almarvi_swapped;
          almarvi2rvex_v.address := std_logic_vector(to_unsigned(4096 + 1024*0 + 4*CR_PC, 32));
          resultMode_v := PASSTHROUGH_SWAP;
          
        when "000000010" => -- 0x008 Cycle count -> CR_CYC@0
          almarvi2rvex_v := axi2almarvi_swapped;
          almarvi2rvex_v.address := std_logic_vector(to_unsigned(4096 + 1024*0 + 4*CR_CYC, 32));
          resultMode_v := PASSTHROUGH_SWAP;
          
        when "000000011" => -- 0x00c Lock cycle count -> CR_STALL@0
          almarvi2rvex_v := axi2almarvi_swapped;
          almarvi2rvex_v.address := std_logic_vector(to_unsigned(4096 + 1024*0 + 4*CR_STALL, 32));
          resultMode_v := PASSTHROUGH_SWAP;
          
        when "010000000" => -- 0x200 Command
          if axi2almarvi_swapped.writeEnable = '1' and axi2almarvi_swapped.writeMask(3) = '1' then
            case axi2almarvi_swapped.writeData(7 downto 0) is
              when "00000001" => -- Reset
                rvex_run_set_v     := (others => '1');
                rvex_reset_set_v   := (others => '1');
                
              when "00000010" => -- Run
                rvex_run_set_v     := (others => '1');
                rvex_reset_clear_v := (others => '1');
                
              when "00000011" => -- Break
                rvex_run_clear_v   := (others => '1');
                rvex_reset_clear_v := (others => '1');
                
              when others => -- Undefined.
                null;
                
            end case;
          end if;
        
        when "010000001" => -- 0x204 Start address
          
          -- Handle reads.
          resultOverride_v := rvex_resetVect_r(0);
          
          -- Handle writes.
          if axi2almarvi_swapped.writeEnable = '1' then
            for ctxt in 2**NUM_CONTEXTS_LOG2-1 downto 0 loop
              if axi2almarvi_swapped.writeMask(3) = '1' then
                rvex_resetVect_v(ctxt)(31 downto 24) := axi2almarvi_swapped.writeData(31 downto 24);
              end if;
              if axi2almarvi_swapped.writeMask(2) = '1' then
                rvex_resetVect_v(ctxt)(23 downto 16) := axi2almarvi_swapped.writeData(23 downto 16);
              end if;
              if axi2almarvi_swapped.writeMask(1) = '1' then
                rvex_resetVect_v(ctxt)(15 downto  8) := axi2almarvi_swapped.writeData(15 downto  8);
              end if;
              if axi2almarvi_swapped.writeMask(0) = '1' then
                rvex_resetVect_v(ctxt)( 7 downto  0) := axi2almarvi_swapped.writeData( 7 downto  0);
              end if;
            end loop;
          end if;
          
        when "011000000" => -- 0x300 Device class -> 0x000D31F7
          resultOverride_v := X"000D31F7";
        
        when "011000001" => -- 0x304 Device ID -> CR_DCFG
          almarvi2rvex_v := axi2almarvi_swapped;
          almarvi2rvex_v.address := std_logic_vector(to_unsigned(4096 + 4*CR_DCFG, 32));
          resultMode_v := PASSTHROUGH_SWAP;
        
        when "011000010" => -- 0x308 Interface type -> 0x00000000
          resultOverride_v := X"00000000";
          
        when "011000011" => -- 0x30c DMEM size -> 2**DMEM_DEPTH_LOG2
          resultOverride_v := std_logic_vector(to_unsigned(2**DMEM_DEPTH_LOG2, 32));
        
        when "011000100" => -- 0x310 IMEM size -> 2**IMEM_DEPTH_LOG2
          resultOverride_v := std_logic_vector(to_unsigned(2**IMEM_DEPTH_LOG2, 32));
        
        when "011000101" => -- 0x314 PMEM size -> 2**PMEM_DEPTH_LOG2
          resultOverride_v := std_logic_vector(to_unsigned(2**PMEM_DEPTH_LOG2, 32));
        
        when "011000110" => -- 0x318 Total size* -> 2**AXI_ADDRW_G
          resultOverride_v := std_logic_vector(to_unsigned(2**AXI_ADDRW_G, 32));
        
        when others => -- others -> 0x00000000
          resultOverride_v := X"00000000";
        
      end case;
      
    end if;
    
    -- Overriding asserts the ack signal, so we should not override the result
    -- if the bus request is idle.
    if bus_requesting(axi2almarvi) = '0' then
      resultMode_v := PASSTHROUGH;
    end if;
    
    -- Drive the output signals.
    almarvi2rvex       <= almarvi2rvex_v;
    resultMode_d       <= resultMode_v;
    resultOverride_d   <= resultOverride_v;
    rvex_resetVect_d   <= rvex_resetVect_v;
    rvex_run_set       <= rvex_run_set_v;
    rvex_run_clear     <= rvex_run_clear_v;
    rvex_reset_set     <= rvex_reset_set_v;
    rvex_reset_clear   <= rvex_reset_clear_v;
    
  end process;
  
  -- Instantiate the bus response phase logic.
  response: process (rvex2almarvi, resultMode_r, resultOverride_r) is
    variable almarvi2axi_v      : bus_slv2mst_type;
    variable swapped            : rvex_data_type;
  begin
    if resultMode_r = OVERRIDE_SWAP then
      almarvi2axi_v := BUS_SLV2MST_IDLE;
      almarvi2axi_v.ack := '1';
      almarvi2axi_v.readData := resultOverride_r;
    else
      almarvi2axi_v := rvex2almarvi;
    end if;
    if resultMode_r /= PASSTHROUGH then
      swapped(31 downto 24)  := almarvi2axi_v.readData( 7 downto  0);
      swapped(23 downto 16)  := almarvi2axi_v.readData(15 downto  8);
      swapped(15 downto  8)  := almarvi2axi_v.readData(23 downto 16);
      swapped( 7 downto  0)  := almarvi2axi_v.readData(31 downto 24);
      almarvi2axi_v.readData := swapped;
    end if;
    almarvi2axi <= almarvi2axi_v;
  end process;
  
end Behavioral;

