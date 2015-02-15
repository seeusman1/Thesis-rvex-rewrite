-- r-VEX processor
-- Copyright (C) 2008-2015 by TU Delft.
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

-- Copyright (C) 2008-2015 by TU Delft.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library rvex;
use rvex.common_pkg.all;
use rvex.utils_pkg.all;
use rvex.core_pkg.all;
use rvex.core_intIface_pkg.all;
use rvex.core_pipeline_pkg.all;
use rvex.core_trap_pkg.all;

--=============================================================================
-- This entity contains the general purpose register file and associated
-- forwarding logic.
-------------------------------------------------------------------------------
entity core_instructionBuffer is
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
    -- log2 of the number of coupled pipelane groups for each pipelane group.
    cfg2any_numGroupsLog2       : in  rvex_2bit_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- The lane index within the coupled groups for each lane.
    cfg2any_laneIndex           : in  rvex_4bit_array(2**CFG.numLanesLog2-1 downto 0);
    
    ---------------------------------------------------------------------------
    -- Instruction memory interface
    ---------------------------------------------------------------------------
    -- Fetch addresses from each pipelane group.
    ibuf2imem_PCs               : out rvex_address_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Active high instruction fetch enable signal. When a bit in this vector
    -- is high, stall is low and the bit in mem_decouple is high, the
    -- instruction memory must fetch the instruction pointed to by the
    -- associated vector in PCs.
    ibuf2imem_fetch             : out std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Combinatorial cancel signal, valid one cycle after PCs and fetch,
    -- regardless of memory stalls. This will go high when a branch is detected
    -- by the next pipeline stage and the previously requested instruction is
    -- not going to be executed. In this case, the instruction memory may
    -- choose not to complete the request if that is faster somehow (a cache 
    -- may choose to cancel line validation if a miss occured to allow the core
    -- to continue earlier). Note that this signal can be safely ignored for
    -- proper operation, it's just a hint which may be used to speed things up.
    ibuf2imem_cancel            : out std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Fetched instruction.
    imem2ibuf_instr             : in  rvex_syllable_array(2**CFG.numLanesLog2-1 downto 0);
    
    -- Exception input from the instruction memory. When active, instr is
    -- assumed to be invalid and the specified trap is thrown.
    imem2ibuf_exception         : in  trap_info_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    ---------------------------------------------------------------------------
    -- Pipelane interface
    ---------------------------------------------------------------------------
    -- Potentially misaligned PC addresses for each group, to be accounted for
    -- by the instruction buffer.
    cxplif2ibuf_PCs             : in  rvex_address_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Properly aligned addresses for each group which need to be fetched. This
    -- is the value of PCs rounded down when branch is high or rounded up when
    -- branch is low.
    cxplif2ibuf_fetchPCs        : in  rvex_address_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Whether the current fetch is nonconsequitive w.r.t. the previous fetch.
    cxplif2ibuf_branch          : in  std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Fetch enable signal from the pipelane groups.
    cxplif2ibuf_fetch           : in  std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Cancel signal from the pipelane groups. This is intended to go high
    -- combinatorially when the previously requested instruction is not going
    -- to be used, for instance due to a branch. This is a bit broken though,
    -- because a memory operation affecting the branch signal which is used
    -- to determine whether to branch may not be valid immediately, and may
    -- thus cancel a fetch even if the branch is not going to be taken after
    -- all. Thus, we're ignoring this and outputting '0' for ibuf2imem_cancel
    -- until further notice.
    cxplif2ibuf_cancel          : in  std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Fetched instruction.
    ibuf2pl_instr               : out rvex_syllable_array(2**CFG.numLanesLog2-1 downto 0);
    
    -- Exception output. When active, instr is invalid and a trap should be
    -- issued.
    ibuf2pl_exception           : out trap_info_array(2**CFG.numLaneGroupsLog2-1 downto 0)
    
  );
end core_instructionBuffer;

--=============================================================================
architecture Behavioral of core_instructionBuffer is
--=============================================================================
  
  -- Size if the instruction mux.
  constant MUX_SIZE_LOG2        : natural := CFG.numLanesLog2 - CFG.bundleAlignLog2;
  
  -- Mux selection signal type.
  subtype mux_type is std_logic_vector(MUX_SIZE_LOG2-1 downto 0);
  type mux_array is array (natural range <>) of mux_type;
  
  -- Mux selection control signal for each lane.
  signal mux                    : mux_array(2**CFG.numLanesLog2-1 downto 0);
  
  -- Instruction buffer load enable control signal for each lane group.
  signal instrBufEna            : std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
  
  -- Instruction buffer register.
  signal instrBuf               : rvex_syllable_array(2**CFG.numLanesLog2-1 downto 0);
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -- Ensure that L_IF (the instruction fetch latency as seen by the pipelanes)
  -- is set to 1; the actual memory latency (L_IF_MEM) is hidden from the
  -- pipelanes here.
  assert L_IF = 1
    report "L_IF must be set to 1 in core_pipeline_pkg.vhd when the "
         & "instruction buffer is used."
    severity failure;
  
  -----------------------------------------------------------------------------
  -- Instruction buffer register
  -----------------------------------------------------------------------------
  -- This register holds the previously fetched instruction.
  instr_buf_proc: process (clk) is
    variable laneGroup: natural;
  begin
    if rising_edge(clk) then
      if clkEn = '1' then
        for lane in 0 to 2**CFG.numLanesLog2-1 loop
          laneGroup := lane2group(lane, CFG);
          if stall(laneGroup) = '0' and instrBufEna(laneGroup) = '1' then
            instrBuf(lane) <= imem2ibuf_instr(lane);
          end if;
        end loop;
      end if;
      
      -- Not having a reset here might make the register a bit smaller. We'll
      -- want to ensure that its value is never used after a reset before the
      -- register is loaded however. So in simulation, reset it with undefined.
      -- pragma translate_off
      if reset = '1' then
        instrBuf <= (others => (others => RVEX_UNDEF));
      end if;
      -- pragma translate_on
      
    end if;
  end process;
  
  -----------------------------------------------------------------------------
  -- Instruction mux
  -----------------------------------------------------------------------------
  -- The instruction mux behaves somewhat like a shifter. As an example, for
  -- the finest granularity in 8-way mode, the mux options look like this:
  --
  -- mux    | 001     010     011     100     101     110     111     000
  -- -------+----------------------------------------------------------------
  -- Lane 0 | buf(1)  buf(2)  buf(3)  buf(4)  buf(5)  buf(6)  buf(7)  mem(0)
  -- Lane 1 | buf(2)  buf(3)  buf(4)  buf(5)  buf(6)  buf(7)  mem(0)  mem(1)
  -- Lane 2 | buf(3)  buf(4)  buf(5)  buf(6)  buf(7)  mem(0)  mem(1)  mem(2)
  -- Lane 3 | buf(4)  buf(5)  buf(6)  buf(7)  mem(0)  mem(1)  mem(2)  mem(3)
  -- Lane 4 | buf(5)  buf(6)  buf(7)  mem(0)  mem(1)  mem(2)  mem(3)  mem(4)
  -- Lane 5 | buf(6)  buf(7)  mem(0)  mem(1)  mem(2)  mem(3)  mem(4)  mem(5)
  -- Lane 6 | buf(7)  mem(0)  mem(1)  mem(2)  mem(3)  mem(4)  mem(5)  mem(6)
  -- Lane 7 | mem(0)  mem(1)  mem(2)  mem(3)  mem(4)  mem(5)  mem(6)  mem(7)
  --
  instr_mux_proc: process (mux, instrBuf, imem2ibuf_instr) is
    variable index  : unsigned(CFG.numLanesLog2 downto 0);
  begin
    for lane in 0 to 2**CFG.numLanesLog2-1 loop
      
      -- Determine the index from the lane index and mux signal.
      index(CFG.numLanesLog2-1 downto CFG.bundleAlignLog2)
        := unsigned(mux(lane));
      if unsigned(mux(lane)) = 0 then
        index(CFG.numLanesLog2) := '1';
      else
        index(CFG.numLanesLog2) := '1';
      end if;
      index := index + to_unsigned(lane, CFG.numLanesLog2+1);
      
      -- Perform the muxing.
      if index(CFG.numLanesLog2) = '1' then
        ibuf2pl_instr(lane) <= imem2ibuf_instr(
          to_integer(index(CFG.numLanesLog2-1 downto 0))
        );
      else
        instrBuf(lane) <= imem2ibuf_instr(
          to_integer(index(CFG.numLanesLog2-1 downto 0))
        );
      end if;
      
    end loop;
  end process;
  
  
  
end Behavioral;

