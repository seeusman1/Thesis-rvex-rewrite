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

library rvex;
use rvex.common_pkg.all;
use rvex.utils_pkg.all;
use rvex.core_pkg.all;
use rvex.core_intIface_pkg.all;

--=============================================================================
-- This unit combines the performance counter increment sources according to
-- the current performance counter configuration. This unit is only
-- instantiated if the configurable performance counters are enabled.
-------------------------------------------------------------------------------
entity core_perfCntCtrl is
--=============================================================================
  generic (
    
    -- Configuration.
    CFG                         : rvex_generic_config_type := rvex_cfg
    
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
    clkEn                       : in  std_logic := '1';
    
    ---------------------------------------------------------------------------
    -- Count sources
    ---------------------------------------------------------------------------
    -- Stall signal for each pipelane group.
    stall                       : in  std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Stall signal from the trace unit. Trace unit stalls are not counted for
    -- most performance counters to keep results somewhat similar to the normal
    -- case while tracing.
    traceStall                  : in  std_logic;
    
    -- Whether the reconfiguration controller is requesting each context to
    -- stop in order to commit a new configuration.
    cfg2pcc_reconfigRequest     : out std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
    
    -- Whether the reconfiguration controller is about to commit a new
    -- configuration. This is active for exactly one clkEn'd cycle.
    cfg2pcc_reconfigCommit      : out std_logic;
    
    -- Increment signals for the 16 selectable external count sources. The
    -- first index refers to the count source channel, the second index refers
    -- to the lane group where the signal originates from. If multiple lane
    -- groups that are selected with the performance counter mask have their
    -- increment signal high at the same time, the counter will increment by
    -- the amount of signals that are high (i.e., the performance counters can 
    -- increment by more than one per cycle). If the core has less than 8 lane
    -- groups, the upper indices of each performance counter input are ignored
    -- and should be optimized away.
    cntsrc2pcc_incrementPerfCnt : in  rvex_byte_array(0 to 15);
    
    ---------------------------------------------------------------------------
    -- Masking information
    ---------------------------------------------------------------------------
    -- This signal is high for lane groups that are last in a set of coupled
    -- groups.
    cfg2any_decouple            : out std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Specifies the context associated with the indexed pipelane group.
    cfg2any_context             : out rvex_3bit_array(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- Specifies whether the indexed pipeline group is active.
    cfg2any_active              : out std_logic_vector(2**CFG.numLaneGroupsLog2-1 downto 0);
    
    -- The log2 of the number of lane groups assigned to each context. Only
    -- valid when the context is active.
    cfg2any_numGrpsPerCtxtLog2  : in  rvex_2bit_array(2**CFG.numContextsLog2-1 downto 0);
    
    -- Whether a context is currently assigned to any lane groups.
    cfg2any_ctxtActive          : in  std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
    
    -- Break flag (CR_DCR.B) for each context.
    cxreg2pcc_brk               : in  std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
    
    -- Indicates whether a context is running in kernel mode (high) or user
    -- mode (low).
    cxreg2pcc_kernelMode        : in  std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
    
    ---------------------------------------------------------------------------
    -- Interface with the actual performance counters
    ---------------------------------------------------------------------------
    -- Configuration and carry out for each performance counter.
    cxreg2pcc_counter_cfg       : in  cxreg2pcc_counter_cfg_array(2**CFG.numContextsLog2-1 downto 0);
    
    -- Increment value for each performance counter.
    pcc2cxreg_counter_inc       : out pcc2cxreg_counter_inc_array(2**CFG.numContextsLog2-1 downto 0)
    
  );
end core_perfCntCtrl;

--=============================================================================
architecture Behavioral of core_perfCntCtrl is
--=============================================================================
  
  -- Number of bits needed for the increment value for each lane.
  constant NUM_INC_BITS : natural := max_nat(CFG.numLanesLog2, CFG.numContextsLog2)+1;
  
  -- Number of increment-by-one inputs needed per counter.
  constant NUM_INC      : natural := 2**(NUM_INC_BITS-1);
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -- Generate the logic for each context.
  ctxt_gen: for ctxt in 0 to 2**CFG.numContextsLog2-1 generate
  begin
    
    -- Generate the logic for each counter.
    cntr_gen: for cntr in 0 to MAX_CFG_PERF_CNTS-1 generate
      
      -- Increment signal for each lane.
      signal inc                : std_logic_vector(NUM_INC-1 downto 0);
      
      -- Masking mode. When low, the indices of inc refer to contexts. When
      -- high, they refer to lanes.
      signal mask_mode          : std_logic;
      
      -- When high, deselected lanes/contexts (due to the current
      -- configuration) should not be counted. When low, they should be.
      signal mask_inactive      : std_logic;
      
      -- When high, lanes/contexts for which the CR_DCR.B flag is set should
      -- not be counted. When low, they should be.
      signal mask_break         : std_logic;
      
      -- Enables/disables counting altogether for various sources.
      signal count_enable_self  : std_logic;
      signal count_enable_other : std_logic;
      signal count_enable_first : std_logic;
      
      -- The selected mask signal.
      signal mask               : std_logic_vector(NUM_INC-1 downto 0);
      
      -- Masked increment signal.
      signal inc_masked         : std_logic_vector(NUM_INC-1 downto 0);
      
    begin
      
      -- Drive the increment signals.
      inc_proc: process (
        cxreg2pcc_counter_cfg, cfg2any_decouple, traceStall, stall,
        cfg2pcc_reconfigRequest, cfg2pcc_reconfigCommit,
        cntsrc2pcc_incrementPerfCnt
      ) is
        variable cntsrc : rvex_byte_type;
      begin
        inc <= (others => '0');
        mask_mode <= '0';
        mask_inactive <= '1';
        mask_break <= '1';
        if cxreg2pcc_counter_cfg(ctxt).src_major(cntr) = '0' then
          
          -- Multiplex between the internal count sources.
          case cxreg2pcc_counter_cfg(ctxt).src_minor(cntr) is
            
            -- Cycle counters + counters disabled.
            when "0000" | "0001" | "0010" | "0011" =>
              
              -- Select lane mode.
              mask_mode <= '1';
              
              -- Mask inactive and halted contexts.
              mask_inactive <= '1';
              mask_break <= '1';
              
              -- Supply a count source for every first lane in each lane group
              -- for which decouple is set.
              if traceStall = '0' then
                for grp in 2**CFG.numLaneGroupsLog2-1 downto 0 loop
                  if cfg2any_decouple(grp) = '1' then
                    if (
                      (cxreg2pcc_counter_cfg(ctxt).mask(cntr)(0) = '1' and stall(grp) = '0')
                        or
                      (cxreg2pcc_counter_cfg(ctxt).mask(cntr)(1) = '1' and stall(grp) = '1')
                    ) then
                      inc(group2firstLane(grp, CFG)) <= '1';
                    end if;
                  end if;
                end loop;
              end if;
            
            -- Interrupt pending. Does not count trace stalls or delays due to
            -- the B flag in DCR, but it DOES count delays due to the context
            -- not being active.
            when "0100" =>
              
              -- TODO
              null;
              
            when "0101" => -- Committed useful syllables.
              
              -- TODO
              null;
              
            when "0110" => -- Committed bundles.
              
              -- TODO
              null;
              
            when "0111" => -- Committed syllables with stop bit set.
              
              -- TODO
              null;
              
            when "1000" => -- Committed taken branch instructions.
              
              -- TODO
              null;
              
            when "1001" => -- Committed branch instructions.
              
              -- TODO
              null;
              
            when "1010" => -- Interrupt pending.
              
              -- TODO
              null;
              
            when "1011" => -- Interrupt accepted.
              
              -- TODO
              null;
              
            when "1100" => -- Reconfiguration pending.
              
              -- TODO
              null;
              
            when "1101" => -- Reconfiguration accepted.
              
              -- TODO
              null;
              
            when "1110" => -- Breakpoint hit.
              
              -- TODO
              null;
              
            when "1111" => -- Carry out/always increment regardless of mask.
              
              -- Always count.
              count_enable_first <= '1';
              
              -- If this is the first counter, count unconditionally.
              -- Otherwise, count if the previous counter overflows.
              if cntr = 0 then
                inc(0) <= '1';
              else
                inc(0) <= cxreg2pcc_counter_cfg(ctxt).carry_out(cntr-1);
              end if;
            
            when others => -- Counter disabled.
              null;
            
          end case;
          
        else
        
          -- Select lane mode.
          mask_mode <= '1';
          
          -- Mask inactive and halted contexts.
          mask_inactive <= '1';
          mask_break <= '1';
          
          -- Multiplex between the external count sources.
          cntsrc := cntsrc2pcc_incrementPerfCnt(vect2uint(
            cxreg2pcc_counter_cfg(ctxt).src_minor(cntr)));
          
          -- Connect the increment signals correctly.
          for grp in 2**CFG.numLaneGroupsLog2-1 downto 0 loop
            inc(group2firstLane(grp, CFG)) <= cntsrc(grp);
          end loop;
          
        end if;
      end process;
      
      -- Determine the count-enable signal based on the mask configuration.
      count_enable_proc: process (
        cxreg2pcc_counter_cfg, cfg2any_ctxtActive, cfg2any_numGrpsPerCtxtLog2,
        cxreg2pcc_kernelMode
      ) is
        variable numLanesLog2 : integer;
      begin
        
        -- Determine the number of lanes associated with this context (only
        -- valid if the context is active).
        numLanesLog2 := vect2int(cfg2any_numGrpsPerCtxtLog2(ctxt))
                     + (CFG.numLanesLog2 - CFG.numLaneGroupsLog2);
        
        -- Decode count_enable_self (the enable bit for our context) and
        -- count_enable_other (the enable bit for other active contexts).
        count_enable_self <= '0';
        count_enable_other <= '0';
        case cxreg2pcc_counter_cfg(ctxt).mask(cntr) is
          
          when "000" => -- Count only in 2-way mode.
            if numLanesLog2 = 1 then
              count_enable_self <= cfg2any_ctxtActive(ctxt);
            end if;
            
          when "001" => -- Count only in 4-way mode.
            if numLanesLog2 = 2 then
              count_enable_self <= cfg2any_ctxtActive(ctxt);
            end if;
            
          when "010" => -- Count only in 8-way mode.
            if numLanesLog2 = 3 then
              count_enable_self <= cfg2any_ctxtActive(ctxt);
            end if;
            
          when "011" => -- Run configuration does not matter.
            count_enable_self <= '1';
            
          when "100" => -- Count only in user mode.
            if cxreg2pcc_kernelMode(ctxt) = '0' then
              count_enable_self <= '1';
            end if;
            
          when "101" => -- Count only in kernel mode.
            if cxreg2pcc_kernelMode(ctxt) = '1' then
              count_enable_self <= '1';
            end if;
            
          when others => -- Count all active contexts.
            count_enable_self <= '1';
            count_enable_other <= '1';
          
        end case;
        
        -- Decode count_enable_first. This overrides the mask for context/lane
        -- 0 to passthrough unconditionally. It is used for the unconditional
        -- +1 count source. Unlike the total cycle counter in "any" mode, this
        -- count source also counts when all lane groups are disabled/the core
        -- is sleeping.
        count_enable_first <= '0';
        if cxreg2pcc_counter_cfg(ctxt).src_major = '0' then
          if cxreg2pcc_counter_cfg(ctxt).mask(cntr) = "1111" then
            count_enable_first <= '1';
          end if;
        end if;
        
      end process;
      
      -- Determine the mask signal.
      mask_lane_proc: process (
        count_enable_self, count_enable_other, count_enable_all, mask_mode,
        mask_inactive, mask_break, cfg2any_ctxtActive, cfg2any_context,
        cfg2any_active, cxreg2pcc_brk
      ) is
        variable ctxtActive : std_logic_vector(2**CFG.numContextsLog2-1 downto 0);
        variable mask_v     : std_logic_vector(NUM_INC-1 downto 0);
      begin
        
        -- Select all contexts/lanes if count_enable_other is high.
        mask_v := (others => count_enable_other);
        
        -- Determine which contexts to mask out because they are inactive.
        ctxtActive <= (others => '1');
        if mask_inactive = '1' then
          ctxtActive := ctxtActive and cfg2any_ctxtActive;
        end if;
        if mask_break = '1' then
          ctxtActive := ctxtActive and not cxreg2pcc_brk;
        end if;
        
        -- Select between context and lane mode. In context mode (low), the
        -- indices of the inc vector are context numbers; in lane mode (high),
        -- they are lane numbers.
        if mask_mode = '0' then
          
          -- Select our context iff count_enable_self is high.
          mask_v(ctxt) := count_enable_self;
          
          -- Deselect inactive contexts.
          mask_v(2**CFG.numContextsLog2-1 downto 0)
            := mask_v(2**CFG.numContextsLog2-1 downto 0) and ctxtActive;
          
        else
          
          -- Select lanes mapped to our context iff count_enable_self is high.
          for lane in 2**CFG.numLanesLog2-1 downto 0 loop
            if vect2uint(cfg2any_context(lane2group(lane, CFG))) = ctxt then
              mask_v(lane) := count_enable_self;
            end if;
          end loop;
          
          -- Deselect inactive lanes.
          for lane in 2**CFG.numLanesLog2-1 downto 0 loop
            if ctxtActive(lane2group(lane, CFG)) = '0' then
              mask_v(lane) := '0';
            end if;
          end loop;
          
        end if;
        
        -- Select the first lane/context unconditionally if count_enable_first
        -- is high.
        mask_v(0) := mask_v(0) or count_enable_first;
        
        -- Use the current selection as the context mask.
        mask <= mask_v;
        
      end process;
      
      -- Mask the increment signal.
      inc_masked <= inc and mask;
      
      -- Add the +1 signals together to get the final value to add.
      add_val_proc: process (
        inc_masked, cxreg2pcc_counter_cfg
      ) is
        variable add_val : unsigned(NUM_INC_BITS-1 downto 0);
      begin
        add_val := (others => '0');
        
        -- The combining mode is sum() or max()/or() based on the mask
        -- configuration.
        if cxreg2pcc_counter_cfg(ctxt).mask(cntr) = "110" then
          
          -- Add one if any signal is high (max/or).
          for i in inc_masked'range loop
            if inc_masked(i) = '1' then
              add_val := (0 => '1', others => '0');
            end if;
          end loop;
          
        else
          
          -- Add one for every signal that is high (sum).
          for i in inc_masked'range loop
            if inc_masked(i) = '1' then
              add_val := add_val + 1;
            end if;
          end loop;
          
        end if;
        
        -- Drive the output signal.
        pcc2cxreg_counter_inc(ctxt).inc(cntr) <= std_logic_vector(resize(add_val, 8));
        
      end process;
      
    end generate;
    
  end generate;
  
end Behavioral;

