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
use work.core_trap_pkg.all;

--=============================================================================
-- This unit interconnects the r-VEX and the AXI bridge such that it complies
-- with the ALMARVI interface specification.
-------------------------------------------------------------------------------
--
-- This unit performs the following mappings:
--
-- For the first 2kiB part of every 4kiB block in the CTRL section:
--   0x004 Program counter
--     -> CR_PC
--   0x008 Cycle count
--     -> CR_CYC
--   0x00c Lock cycle count
--     -> CR_STALL
--   0x200 Command
--     -> write only reset/run/break command
--   0x204 Start address (first instruction after reset)
--     -> stored in a register, passed to rvex_resetVect
--   0x208 Breakpoint enable
--     -> breakpoint/single stepping control register
--   0x20C Breakpoint 1
--     -> CR_BR0
--   0x210 Breakpoint 2
--     -> CR_BR1
--   0x214 Breakpoint 3
--     -> CR_BR2
--   0x300 Device class
--     -> 0x000D31F7
--   0x304 Device ID
--     -> CR_DCFG
--   0x308 Interface type
--     -> 0x00000000
--   0x30C Core count
--     -> 2**NUM_CONTEXTS_LOG2
--   0x310 CTRL size
--     -> 4096
--   0x314 DMEM size
--     -> 2**DMEM_DEPTH_LOG2
--   0x318 IMEM size
--     -> 2**IMEM_DEPTH_LOG2
--   0x31C PMEM size
--     -> 2**PMEM_DEPTH_LOG2
--   0x320 Debug feature support
--     -> 1
--   0x324 Breakpoint count
--     -> min(3, NUM_BREAKPOINTS)
--   others < 0x400
--     -> 0x00000000
--   others >= 0x400
--     -> passthrough to r-VEX control registers
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
    NUM_CONTEXTS_LOG2           : integer;
    
    -- Number of breakpoints supported by the r-VEX.
    NUM_BREAKPOINTS             : integer
    
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
    rvex_resetVect              : out rvex_address_array(2**NUM_CONTEXTS_LOG2-1 downto 0)
    
  );
end almarvi_iface;

--=============================================================================
architecture Behavioral of almarvi_iface is
--=============================================================================
  
  -- Bus result mode register.
  type resultMode_type is (
    
    -- Passes the bus response from the r-VEX directly to AXI for big endian
    -- sections.
    PASS_BE,
    
    -- Passes the bus response from the r-VEX directly to AXI for little endian
    -- sections.
    PASS_LE,
    
    -- Bus response is set to ACK with resultOverride as the data for little
    -- endian sections.
    OVERRIDE_LE,
    
    -- Special mode for the status register. ACK is taken from the r-VEX bus,
    -- which is assumed to have received a read request for DCR. The data from
    -- DCR is transformed to the data format for status.
    STATUS_LE,
    
    -- Special mode for the breakpoint enable register. ACK is taken from the
    -- r-VEX bus, which is assumed to have received a read request for DCR.
    -- The data from DCR is transformed to the data format for status.
    BRK_ENA_LE
    
  );
  signal resultMode_d           : resultMode_type;
  signal resultMode_r           : resultMode_type;
  
  -- Bus result override value.
  signal resultOverride_d       : rvex_data_type;
  signal resultOverride_r       : rvex_data_type;
  
  -- Run control registers.
  signal rvex_resetVect_d       : rvex_address_array(2**NUM_CONTEXTS_LOG2-1 downto 0);
  signal rvex_resetVect_r       : rvex_address_array(2**NUM_CONTEXTS_LOG2-1 downto 0);
  signal rvex_reset_d           : std_logic_vector(2**NUM_CONTEXTS_LOG2-1 downto 0);
  signal rvex_reset_r           : std_logic_vector(2**NUM_CONTEXTS_LOG2-1 downto 0);
  signal rvex_step_d            : std_logic_vector(2**NUM_CONTEXTS_LOG2-1 downto 0);
  signal rvex_step_r            : std_logic_vector(2**NUM_CONTEXTS_LOG2-1 downto 0);
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -- Instantiate all the registers.
  regs: process (clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        resultMode_r     <= PASS_BE;
        resultOverride_r <= (others => '0');
        rvex_resetVect_r <= (others => (others => '0'));
        rvex_reset_r     <= (others => '1');
        rvex_step_r      <= (others => '0');
      elsif clkEn = '1' then
        resultMode_r     <= resultMode_d;
        resultOverride_r <= resultOverride_d;
        rvex_resetVect_r <= rvex_resetVect_d;
        rvex_reset_r     <= rvex_reset_d;
        rvex_step_r      <= rvex_step_d;
      end if;
    end if;
  end process;
  
  -- Forward the reset vectors.
  rvex_resetVect  <= rvex_resetVect_r;
  
  -- Instantiate the bus request phase logic.
  request: process (axi2almarvi, rvex_resetVect_r, rvex_reset_r, rvex_step_r) is
    
    -- Incoming request from AXI.
    variable in_addr            : rvex_address_type;
    variable in_rena            : std_logic;
    variable in_wena            : std_logic;
    variable in_wdatBE          : rvex_address_type;
    variable in_wmaskBE         : rvex_mask_type;
    variable in_wdatLE          : rvex_address_type;
    variable in_wmaskLE         : rvex_mask_type;
    
    -- Outgoing request to r-VEX.
    variable out_addr           : rvex_address_type;
    variable out_rena           : std_logic;
    variable out_wena           : std_logic;
    variable out_wdat           : rvex_address_type;
    variable out_wmask          : rvex_mask_type;
    variable almarvi2rvex_v     : bus_mst2slv_type;
    
    -- Bus result control.
    variable resultMode_v       : resultMode_type;
    variable resultOverride_v   : rvex_data_type;
    
    -- r-VEX run control.
    variable rvex_resetVect_v   : rvex_address_array(2**NUM_CONTEXTS_LOG2-1 downto 0);
    variable rvex_reset_v       : std_logic_vector(2**NUM_CONTEXTS_LOG2-1 downto 0);
    variable rvex_step_v        : std_logic_vector(2**NUM_CONTEXTS_LOG2-1 downto 0);
    
    -- Selected context.
    variable context            : integer range 0 to 2**NUM_CONTEXTS_LOG2-1;
    
  begin
    
    -- Interpret the AXI request both as big and as little endian.
    in_addr    := axi2almarvi.address;
    in_rena    := axi2almarvi.readEnable;
    in_wena    := axi2almarvi.writeEnable;
    in_wdatBE  := axi2almarvi.writeData;
    in_wmaskBE := axi2almarvi.writeMask;
    in_wdatLE  := axi2almarvi.writeData(7  downto  0) &
                  axi2almarvi.writeData(15 downto  8) &
                  axi2almarvi.writeData(23 downto 16) &
                  axi2almarvi.writeData(31 downto 24);
    in_wmaskLE := axi2almarvi.writeMask(0  downto  0) &
                  axi2almarvi.writeMask(1  downto  1) &
                  axi2almarvi.writeMask(2  downto  2) &
                  axi2almarvi.writeMask(3  downto  3);
    
    -- Just pass through the big endian request unless otherwise specified.
    out_addr          := in_addr;
    out_rena          := in_rena;
    out_wena          := in_wena;
    out_wdat          := in_wdatBE;
    out_wmask         := in_wmaskBE;
    resultMode_v      := PASS_BE;
    resultOverride_v  := (others => '0');
    
    -- Don't change run control state unless otherwise specified.
    rvex_resetVect_v  := rvex_resetVect_r;
    rvex_reset_v      := rvex_reset_r;
    rvex_step_v       := rvex_step_r;
    
    -- Handle the different memory sections differently.
    if in_addr(AXI_ADDRW_G-1 downto AXI_ADDRW_G-2) /= "00" then
      
      -- IMEM/DMEM/PMEM sections: passthrough without modification.
      null;
      
    elsif in_addr(11) = '1' then
      
      -- Trace buffer section: passthrough without modification.
      null;
      
    else
      
      -- ALMARVI CTRL/r-VEX section: remap high bits of address to r-VEX debug
      -- bus for the right context.
      
      -- Map context bits accordingly.
      out_addr(11 downto 10) := in_addr(13 downto 12);
      
      -- Select the r-VEX debug bus block.
      out_addr(AXI_ADDRW_G-1 downto AXI_ADDRW_G-2) := "11";
      
      if in_addr(10) = '0' then
        
        -- ALMARVI register interface selected. Disable the bus request and
        -- override the result with 0 (reserved register behavior) unless
        -- otherwise specified. Use little endian interpreted write data.
        out_rena          := '0';
        out_wena          := '0';
        out_wdat          := in_wdatLE;
        out_wmask         := in_wmaskLE;
        resultMode_v      := OVERRIDE_LE;
        resultOverride_v  := (others => '0');
        
        -- Figure out which context is being addressed.
        context := to_integer(unsigned(in_addr(13 downto 12)));
        
        -- Handle the registers.
        case axi2almarvi.address(9 downto 2) is
          when "00000000" => -- 0x000 Status
            out_rena := in_rena;
            out_addr(9 downto 2) := std_logic_vector(to_unsigned(CR_DCR, 8));
            resultMode_v := STATUS_LE;
          
          when "00000001" => -- 0x004 Program counter -> CR_PC
            out_rena := in_rena;
            out_addr(9 downto 2) := std_logic_vector(to_unsigned(CR_PC, 8));
            resultMode_v := PASS_LE;
          
          when "00000010" => -- 0x008 Cycle count -> CR_CYC
            out_rena := in_rena;
            out_addr(9 downto 2) := std_logic_vector(to_unsigned(CR_CYC, 8));
            resultMode_v := PASS_LE;
            
          when "00000011" => -- 0x00C Lock cycle count -> CR_STALL
            out_rena := in_rena;
            out_addr(9 downto 2) := std_logic_vector(to_unsigned(CR_STALL, 8));
            resultMode_v := PASS_LE;
            
          when "10000000" => -- 0x200 Command
            out_addr(9 downto 2) := std_logic_vector(to_unsigned(CR_DCR, 8));
            if in_wena = '1' and in_wmaskLE(0) = '1' then
              case in_wdatLE(7 downto 0) is
                when "00000001" => -- Reset.
                  
                  -- Assert reset. This does not actually keep the r-VEX context
                  -- reset line active, for this has a number of issues (among
                  -- which, not being able to use the debug bus).
                  rvex_reset_v(context) := '1';
                  
                  -- Give the step or resume command by writing to DCR.
                  out_wena := '1';
                  out_wmask := "1000";
                  out_wdat := X"89000000"; -- Reset + break.
                  
                  -- Respect the bus acknowledgement for the write instead of
                  -- generating our own.
                  resultMode_v := PASS_LE;
                  
                when "00000010" => -- Run.
                  
                  -- Release reset.
                  rvex_reset_v(context) := '0';
                  
                  -- Give the step or resume command by writing to DCR.
                  out_wena := '1';
                  out_wmask := "1000";
                  if rvex_step_r(context) = '1' then
                    out_wdat := X"0A000000"; -- Step.
                  else
                    out_wdat := X"0C000000"; -- Resume.
                  end if;
                  
                  -- Respect the bus acknowledgement for the write instead of
                  -- generating our own.
                  resultMode_v := PASS_LE;
                  
                when "00000100" => -- Break.
                  
                  -- Release reset.
                  rvex_reset_v(context) := '0';
                  
                  -- Give the break command by writing to DCR.
                  out_wena := '1';
                  out_wmask := "1000";
                  out_wdat := X"09000000"; -- Break.
                  
                  -- Respect the bus acknowledgement for the write instead of
                  -- generating our own.
                  resultMode_v := PASS_LE;
                  
                when others => -- Unknown command.
                  null;
                  
              end case;
            end if;
          
          when "10000001" => -- 0x204 Start address
            resultOverride_v := rvex_resetVect_r(context);
            if in_wena = '1' then
              if in_wmaskLE(0) = '1' then
                rvex_resetVect_v(context)( 7 downto  0) := in_wdatLE( 7 downto  0);
              end if;
              if in_wmaskLE(1) = '1' then
                rvex_resetVect_v(context)(15 downto  8) := in_wdatLE(15 downto  8);
              end if;
              if in_wmaskLE(2) = '1' then
                rvex_resetVect_v(context)(23 downto 16) := in_wdatLE(23 downto 16);
              end if;
              if in_wmaskLE(3) = '1' then
                rvex_resetVect_v(context)(31 downto 24) := in_wdatLE(31 downto 24);
              end if;
              
              -- If we're in reset mode, we need to update the PC manually when
              -- this is written, because the r-VEX is not actually continuously
              -- reset.
              if rvex_reset_r(context) = '1' then
                out_wena := in_wena;
                out_addr(9 downto 2) := std_logic_vector(to_unsigned(CR_PC, 8));
                resultMode_v := PASS_LE;
              end if;
              
            end if;
            
          when "10000010" => -- 0x208 Breakpoint enable
            
            -- Handle reads and the access in general. resultOverride is used to
            -- store the step mode already, the other bits are taken from the bus
            -- result.
            out_rena := in_rena;
            out_addr(9 downto 2) := std_logic_vector(to_unsigned(CR_DCR, 8));
            resultMode_v := BRK_ENA_LE;
            resultOverride_v(2) := rvex_step_r(context);
            
            -- Handle writes to the breakpoint enable register.
            if in_wena = '1' and in_wmaskLE(0) = '1' then
              
              -- Store whether the core should single step.
              rvex_step_v(context) := in_wdatLE(2);
              
              -- Write to the low halfword of DCR, which contains the breakpoint
              -- configuration.
              out_wena    := '1';
              out_wmask   := "0011";
              out_wdat    := (others => '0');
              out_wdat(0) := in_wdatLE(3); -- Breakpoint 1 enable.
              out_wdat(4) := in_wdatLE(4); -- Breakpoint 2 enable. 
              out_wdat(8) := in_wdatLE(5); -- Breakpoint 3 enable.
              
            end if;
          
          when "10000011" => -- 0x20C Breakpoint 1
            out_rena := in_rena;
            out_wena := in_wena;
            out_addr(9 downto 2) := std_logic_vector(to_unsigned(CR_BR0, 8));
            resultMode_v := PASS_LE;
          
          when "10000100" => -- 0x210 Breakpoint 2
            out_rena := in_rena;
            out_wena := in_wena;
            out_addr(9 downto 2) := std_logic_vector(to_unsigned(CR_BR1, 8));
            resultMode_v := PASS_LE;
          
          when "10000101" => -- 0x214 Breakpoint 3
            out_rena := in_rena;
            out_wena := in_wena;
            out_addr(9 downto 2) := std_logic_vector(to_unsigned(CR_BR2, 8));
            resultMode_v := PASS_LE;
          
          when "11000000" => -- 0x300 Device class -> 0x000D31F7
            resultOverride_v := X"000D31F7";
          
          when "11000001" => -- 0x304 Device ID -> CR_DCFG
            out_rena := in_rena;
            out_addr(9 downto 2) := std_logic_vector(to_unsigned(CR_DCFG, 8));
            resultMode_v := PASS_LE;
          
          when "11000010" => -- 0x308 Interface type -> 0x00000000
            resultOverride_v := X"00000000";
            
          when "11000011" => -- 0x30C Core count -> 2**NUM_CONTEXTS_LOG2
            resultOverride_v := std_logic_vector(to_unsigned(2**NUM_CONTEXTS_LOG2, 32));
            
          when "11000100" => -- 0x310 CTRL size per core -> 4096
            resultOverride_v := std_logic_vector(to_unsigned(4096, 32));
            
          when "11000101" => -- 0x314 DMEM size -> 2**DMEM_DEPTH_LOG2
            resultOverride_v := std_logic_vector(to_unsigned(2**DMEM_DEPTH_LOG2, 32));
          
          when "11000110" => -- 0x318 IMEM size -> 2**IMEM_DEPTH_LOG2
            resultOverride_v := std_logic_vector(to_unsigned(2**IMEM_DEPTH_LOG2, 32));
          
          when "11000111" => -- 0x31C PMEM size -> 2**PMEM_DEPTH_LOG2
            resultOverride_v := std_logic_vector(to_unsigned(2**PMEM_DEPTH_LOG2, 32));
          
          when "11001000" => -- 0x320 Debug feature support -> 1
            resultOverride_v := std_logic_vector(to_unsigned(1, 32));
          
          when "11001001" => -- 0x324 Breakpoint count -> min(3, NUM_BREAKPOINTS)
            if NUM_BREAKPOINTS < 3 then
              resultOverride_v := std_logic_vector(to_unsigned(NUM_BREAKPOINTS, 32));
            else
              resultOverride_v := std_logic_vector(to_unsigned(3, 32));
            end if;
          
          when others => -- others -> 0x00000000
            null;
          
        end case;
      end if;
    end if;
    
    -- If there is no request, the bus return value is don't care, but we can't
    -- ACK it. Since some of the overrides assert ACK, we have to handle this
    -- case. We can just do that by overriding the result mode to anything that
    -- doesn't assert ACK on its own, like the default passthrough mode.
    if in_rena = '0' and in_wena = '0' then
      resultMode_v := PASS_BE;
    end if;
    
    -- Drive the output signals.
    almarvi2rvex_v              := BUS_MST2SLV_IDLE;
    almarvi2rvex_v.address      := out_addr;
    almarvi2rvex_v.readEnable   := out_rena;
    almarvi2rvex_v.writeEnable  := out_wena;
    almarvi2rvex_v.writeData    := out_wdat;
    almarvi2rvex_v.writeMask    := out_wmask;
    almarvi2rvex                <= almarvi2rvex_v;
    resultMode_d                <= resultMode_v;
    resultOverride_d            <= resultOverride_v;
    rvex_resetVect_d            <= rvex_resetVect_v;
    rvex_reset_d                <= rvex_reset_v;
    rvex_step_d                 <= rvex_step_v;
    
  end process;
  
  -- Instantiate the bus response phase logic.
  response: process (rvex2almarvi, resultMode_r, resultOverride_r) is
    variable almarvi2axi_v      : bus_slv2mst_type;
    variable swapped            : rvex_data_type;
  begin
    
    -- Passthrough by default.
    almarvi2axi_v := rvex2almarvi;
    
    -- Handle special result modes.
    case resultMode_r is
      
      when OVERRIDE_LE => -- Override with resultOverride.
        almarvi2axi_v := BUS_SLV2MST_IDLE;
        almarvi2axi_v.ack := '1';
        almarvi2axi_v.readData := resultOverride_r;
      
      when STATUS_LE => -- Encode status register value.
        case to_integer(unsigned(rvex2almarvi.readData(23 downto 16))) is -- Break cause.
          when RVEX_TRAP_STEP_COMPLETE =>
            almarvi2axi_v.readData := X"00000001";
          when RVEX_TRAP_HW_BREAKPOINT_0 =>
            almarvi2axi_v.readData := X"00000002";
          when RVEX_TRAP_HW_BREAKPOINT_1 =>
            almarvi2axi_v.readData := X"00000004";
          when RVEX_TRAP_HW_BREAKPOINT_2 =>
            almarvi2axi_v.readData := X"00000008";
          when 1 => -- Manual break command.
            almarvi2axi_v.readData := X"00000010";
          when others => -- Running, completed or unknown state.
            almarvi2axi_v.readData := X"00000000";
        end case;
        
      when BRK_ENA_LE => -- Encode breakpoint enable register value.
        almarvi2axi_v.readData := resultOverride_r;
        almarvi2axi_v.readData(3) := rvex2almarvi.readData(0); -- Breakpoint 1.
        almarvi2axi_v.readData(4) := rvex2almarvi.readData(4); -- Breakpoint 2.
        almarvi2axi_v.readData(5) := rvex2almarvi.readData(8); -- Breakpoint 3.
        
      when others => -- Passthrough.
        null;
      
    end case;
    
    -- Byteswap the result if it should be returned in little endian.
    if resultMode_r /= PASS_BE then
      swapped(31 downto 24)  := almarvi2axi_v.readData( 7 downto  0);
      swapped(23 downto 16)  := almarvi2axi_v.readData(15 downto  8);
      swapped(15 downto  8)  := almarvi2axi_v.readData(23 downto 16);
      swapped( 7 downto  0)  := almarvi2axi_v.readData(31 downto 24);
      almarvi2axi_v.readData := swapped;
    end if;
    
    -- Drive output signals.
    almarvi2axi <= almarvi2axi_v;
    
  end process;
  
end Behavioral;

