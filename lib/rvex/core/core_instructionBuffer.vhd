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
  
  
  --***************************************************************************
  -- THIS UNIT IS TODO: PLACEHOLDER IMPLEMENTATION FOLLOWS.
  --***************************************************************************
  placeholder: block is
    signal error, error_r       : std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
  begin
  
    -- We don't support non-unit instruction fetch latency yet.
    assert L_IF_MEM = 1
      report "Instruction memory with non-unit latency is not yet supported "
           & "by the instruction buffer."
      severity failure;
    
    placeholder_regs: process (clk) is
    begin
      if rising_edge(clk) then
        if reset = '1' then
          error_r <= (others => '0');
        elsif clkEn = '1' then
          for laneGroup in 0 to 2**CFG.numLaneGroupsLog2-1 loop
            if stall(laneGroup) = '0' then
              error_r(laneGroup) <= error(laneGroup);
            end if;
          end loop;
        end if;
      end if;
    end process;
    
    placeholder_comb: process (
      cfg2any_numGroupsLog2, cfg2any_laneIndex,
      cxplif2ibuf_PCs, cxplif2ibuf_fetch, cxplif2ibuf_cancel,
      imem2ibuf_instr, imem2ibuf_exception,
      error_r
    ) is
      variable error_v      : std_logic;
      variable fixedBits    : natural;
      variable ignoredBits  : natural;
    begin
      
      -- Forward trivially.
      ibuf2imem_PCs     <= cxplif2ibuf_PCs;
      ibuf2imem_fetch   <= cxplif2ibuf_fetch;
      ibuf2imem_cancel  <= cxplif2ibuf_cancel;
      ibuf2pl_instr     <= imem2ibuf_instr;
      ibuf2pl_exception <= imem2ibuf_exception;
      
      -- The cancel signal is broken (see entity description), so disable it.
      ibuf2imem_cancel  <= (others => '0');
      
      -- Check for alignment and fix PCs for all groups.
      for laneGroup in 0 to 2**CFG.numLaneGroupsLog2-1 loop
      
        -- Check for fetched PC alignment constraints and ensure they're met;
        -- if not, we can't service the request, being but a placeholder.
        error_v := '0';
        
        -- Determine the number of bits of the bundle PC which should be zero
        -- if we're to be able to handle it.
        fixedBits := SYLLABLE_SIZE_LOG2B
                   + (CFG.numLanesLog2 - CFG.numLaneGroupsLog2)
                   + vect2uint(cfg2any_numGroupsLog2(laneGroup));
        
        -- Determine the number of PC bits which should be ignored in the
        -- check, because they're only used internally for RFI branches,
        -- which may be misaligned, but are handled in the pipelanes.
        ignoredBits := SYLLABLE_SIZE_LOG2B
                     + CFG.bundleAlignLog2;
        
        -- Check for alignment.
        for i in 0 to SYLLABLE_SIZE_LOG2B + CFG.numLanesLog2-1 loop
          if i < fixedBits and i >= ignoredBits then
            if cxplif2ibuf_PCs(laneGroup)(i) /= '0' then
              error_v := '1';
            end if;
          end if;
        end loop;
        
        -- Override the fixed bits of the output PC according to its
        -- specification.
        ibuf2imem_PCs(laneGroup)(SYLLABLE_SIZE_LOG2B-1 downto 0) <= (others => '0');
        ibuf2imem_PCs(laneGroup)(fixedBits-1 downto SYLLABLE_SIZE_LOG2B)
          <= cfg2any_laneIndex(group2firstLane(laneGroup, CFG))(
            fixedBits-SYLLABLE_SIZE_LOG2B-1 downto 0
          );
        
        -- Output the error state for the register.
        error(laneGroup) <= error_v;
        
        -- Issue a trap if there was a request fault in the previous cycle.
        if error_r(laneGroup) = '1' then
          ibuf2pl_exception(laneGroup) <= (
            active => '1',
            cause  => rvex_trap(RVEX_TRAP_FETCH_FAULT),
            arg    => X"00000000"
          );
        end if;
        
      end loop;
      
    end process;
    
  end block;
  
end Behavioral;

