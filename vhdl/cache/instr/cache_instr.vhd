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

-- 6. r-VEX was developed by Stephan Wong, Thijs van As, Fakhar Anjam,
-- Roel Seedorf, Anthony Brandon, Jeroen van Straten. r-VEX is currently
-- maintained by TU Delft (J.S.S.M.Wong@tudelft.nl).

-- Copyright (C) 2008-2014 by TU Delft.

-- Refer to reconfICache_pkg.vhd for configuration constants and most
-- documentation.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library rvex;
use rvex.cache_instr_pkg.all;

entity cache_instr is
  port (
    
    -- Clock input.
    clk                       : in  std_logic;
    
    -- Active high reset input.
    reset                     : in  std_logic;
    
    -- Active high CPU interface clock enable input.
    clkEnCPU                  : in  std_logic;
    
    -- Active high bus interface clock enable input.
    clkEnBus                  : in  std_logic;
    
    -- Connections to the atoms. Governed by clkEnCPU.
    atomsToCache              : in  reconfICache_atomIn_array;
    cacheToAtoms              : out reconfICache_atomOut_array;
    
    -- Connections to the memory bus. Governed by clkEnBus.
    memToCache                : in  reconfICache_memIn_array;
    cacheToMem                : out reconfICache_memOut_array;
    
    -- Cache line invalidation input. Governed by clkEnBus.
    inval                     : in  reconfICache_invalIn
    
  );
end cache_instr;

architecture Behavioral of cache_instr is
  
  -- Input mux/demux signal tree.
  signal inMuxDemux           : RIC_inputMuxDemuxVector_levels;
  
  -- Output mux/demux signal tree.
  signal outMuxDemux          : RIC_outputMuxDemuxVector_levels;
  
begin
  
  --===========================================================================
  -- Connect the inputs of the input mux/demux logic
  --===========================================================================
  inMuxDemux_input_gen : for i in 0 to RIC_NUM_ATOMS-1 generate
    
    -- Read enable signal from the atom, active high.
    inMuxDemux(0)(i).readEnable <= atomsToCache(i).readEnable;
    
    -- Requested address/PC.
    inMuxDemux(0)(i).PC <= atomsToCache(i).PC;
    
    -- This signal is high when the associated cache block must attempt to
    -- update the cache line associated with the PC. This is based on the
    -- hit output of all coupled cache blocks and registered readEnable: when
    -- readEnable is high and all hit signals are low, one of the cache blocks
    -- in the set will have updateEnable pulled high. The cache block selected
    -- for updating when multiple cache blocks are working together is based
    -- on the PC bits just above the cache index in the mux/demux logic, but
    -- any replacement policy could theoretically be used.
    inMuxDemux(0)(i).updateEnable <=
      outMuxDemux(RIC_NUM_ATOMS_LOG2)(i).readEnable
      and not outMuxDemux(RIC_NUM_ATOMS_LOG2)(i).hit;
    
    -- Decouple bit network input, see mux/demux implementation code comments
    -- for more information.
    inMuxDemux(0)(i).decouple <= atomsToCache(i).decouple;
    
    -- Stall network input.
    inMuxDemux(0)(i).stall <= atomsToCache(i).stall;
    
  end generate;
  
  --===========================================================================
  -- Generate the input mux/demux logic
  --===========================================================================
  inMuxDemux_logic_gen : if RIC_NUM_ATOMS_LOG2 > 0 generate
    -- The code below generates approximately a structure like this for
    -- RIC_NUM_ATOMS equal to 8. Each block represents the for loop body.
    -- The horizontal axis of the signals is specified by lvl, the vertical
    -- index is computed for every i in the loop body. The number specified
    -- in the block is the decouple bit used. When the decouple bit is high,
    -- a block passes its inputs to its outputs unchanged save for the
    -- decouple bit network interconnect. When the decouple bit is low, both
    -- outputs are set to the bottom (hi) input and the updateEnable bit is
    -- and'ed based on the PC bit corrosponding to the level. The lo input
    -- decouple bit is used for the muxing of a stage, whereas the hi output
    -- is forwarded to the outputs in order to connect the indices as shown
    -- below.
    --        ___       ___        ___
    --  ---->| 0 |---->| 1 |----->| 3 |------->
    --       |   |     | __|      | __|
    --  ---->|___|----->| 1 |----->| 3 |------>
    --        ___      ||   |     || __|
    --  ---->| 2 |---->||   | ----->| 3 |----->
    --       |   |      |   |     ||| __|
    --  ---->|___|----->|___|------->| 3 |---->
    --        ___       ___       ||||   |
    --  ---->| 4 |---->| 5 |----->||||   | --->
    --       |   |     | __|       |||   |
    --  ---->|___|----->| 5 |----->|||   | --->
    --        ___      ||   |       ||   |
    --  ---->| 6 |---->||   | ----->||   | --->
    --       |   |      |   |        |   |
    --  ---->|___|----->|___|------->|___|---->
    --
    inMuxDemux_logic_gen_b: for lvl in 0 to RIC_NUM_ATOMS_LOG2 - 1 generate
      inMuxDemux_logic: process (inMuxDemux(lvl), outMuxDemux(lvl)) is
        variable inLo, inHi       : RIC_inputMuxDemuxVector;
        variable outLo, outHi     : RIC_inputMuxDemuxVector;
        variable ind              : unsigned(RIC_NUM_ATOMS_LOG2-2 downto 0);
        variable indLo, indHi     : unsigned(RIC_NUM_ATOMS_LOG2-1 downto 0);
      begin
        for i in 0 to (RIC_NUM_ATOMS / 2) - 1 loop
          
          -- Decode i into an unsigned so we can play around with the bits.
          ind := to_unsigned(i, RIC_NUM_ATOMS_LOG2-1);
          
          -- Determine the lo and hi indices.
          for j in 0 to RIC_NUM_ATOMS_LOG2 - 1 loop
            if j < lvl then
              indLo(j) := ind(j);
              indHi(j) := ind(j);
            elsif j = lvl then
              indLo(j) := '0';
              indHi(j) := '1';
            else
              indLo(j) := ind(j-1);
              indHi(j) := ind(j-1);
            end if;
          end loop;
          
          -- Read the input signals into variables for shorthand notation.
          inLo := inMuxDemux(lvl)(to_integer(indLo));
          inHi := inMuxDemux(lvl)(to_integer(indHi));
          
          -- Passthrough by default.
          outLo := inLo;
          outHi := inHi;
          
          -- Overwrite lo decouple output to hi decouple input to generate the
          -- decouple network.
          outLo.decouple := inHi.decouple;
          
          -- If the lo decouple input is low, perform magic to make cache
          -- blocks work together.
          if inLo.decouple = '0' then
            
            -- Hi input is always the master, so ignore the slave inputs and
            -- forward the master inputs to both cache blocks.
            outLo.readEnable  := inHi.readEnable;
            outLo.PC          := inHi.PC;
            
            -- Determine which cache should be updated on a miss based on the
            -- lowest PC bits used for the cache tag. Technically, any
            -- replacement policy may be used here, though. Note that we need
            -- to take this value from the output mux, because updateEnable is
            -- valid one pipelane stage later than the input PC, and the output
            -- mux PC has this attribute.
            if outMuxDemux(lvl)(to_integer(indLo)).PC(RIC_ADDR_TAG_LSB + lvl) = '0' then
              outLo.updateEnable := inHi.updateEnable;
              outHi.updateEnable := '0';
            else
              outLo.updateEnable := '0';
              outHi.updateEnable := inHi.updateEnable;
            end if;
            
            -- Merge the stall signals when two atoms are coupled.
            outLo.stall := inLo.stall or inHi.stall;
            outHi.stall := inLo.stall or inHi.stall;
            
          end if;
          
          -- Assign the output signals.
          inMuxDemux(lvl+1)(to_integer(indLo)) <= outLo;
          inMuxDemux(lvl+1)(to_integer(indHi)) <= outHi;
          
        end loop; -- i
      end process;
    end generate; -- lvl
  end generate;
  
  --===========================================================================
  -- Instantiate the cache blocks
  --===========================================================================
  cache_block_gen : for i in 0 to RIC_NUM_ATOMS-1 generate
    cache_block_n : entity rvex.cache_instr_block
      port map (
        
        -- Clock input.
        clk                   => clk,
        
        -- Active high reset input.
        reset                 => reset,
        
        -- Active high CPU interface clock enable input.
        clkEnCPU              => clkEnCPU,
        
        -- Active high bus interface clock enable input.
        clkEnBus              => clkEnBus,
        
        -- Signals connecting to the input mux/demux logic.
        input                 => inMuxDemux(RIC_NUM_ATOMS_LOG2)(i),
        output                => outMuxDemux(0)(i),
        
        -- Connections to the memory bus.
        memToCache            => memToCache(i),
        cacheToMem            => cacheToMem(i),
        
        -- Cache line invalidation input.
        inval                 => inval
        
      );
  end generate;

  --===========================================================================
  -- Generate the input mux/demux logic
  --===========================================================================
  outMuxDemux_logic_gen : if RIC_NUM_ATOMS_LOG2 > 0 generate
  
    -- The code below generates the same structure as the input mux/demux
    -- code, so you can refer to the ASCII picture there.
    outMuxDemux_logic_gen_b : for lvl in 0 to RIC_NUM_ATOMS_LOG2 - 1 generate
      outMuxDemux_logic: process (outMuxDemux(lvl), inMuxDemux(lvl)) is
        variable inLo, inHi       : RIC_outputMuxDemuxVector;
        variable outLo, outHi     : RIC_outputMuxDemuxVector;
        variable ind              : unsigned(RIC_NUM_ATOMS_LOG2-2 downto 0);
        variable indLo, indHi     : unsigned(RIC_NUM_ATOMS_LOG2-1 downto 0);
      begin
        for i in 0 to (RIC_NUM_ATOMS / 2) - 1 loop
          
          -- Decode i into an unsigned so we can play around with the bits.
          ind := to_unsigned(i, RIC_NUM_ATOMS_LOG2-1);
          
          -- Determine the lo and hi indices.
          for j in 0 to RIC_NUM_ATOMS_LOG2 - 1 loop
            if j < lvl then
              indLo(j) := ind(j);
              indHi(j) := ind(j);
            elsif j = lvl then
              indLo(j) := '0';
              indHi(j) := '1';
            else
              indLo(j) := ind(j-1);
              indHi(j) := ind(j-1);
            end if;
          end loop;
          
          -- Read the input signals into variables for shorthand notation.
          inLo := outMuxDemux(lvl)(to_integer(indLo));
          inHi := outMuxDemux(lvl)(to_integer(indHi));
          
          -- Passthrough by default.
          outLo := inLo;
          outHi := inHi;
          
          -- If the input mux/demux lo decouple input is low, perform magic
          -- to make cache blocks work together. Note the lack of a register
          -- here even though we're crossing a pipeline stage. This should not
          -- be necessary due to the preconditions placed on the decouple
          -- inputs: in all cases when a decouple signal switches, behavior
          -- is unaffected due to all readEnables and stalls being low.
          if inMuxDemux(lvl)(to_integer(indLo)).decouple = '0' then
            
            -- Make both outputs identical and choose their inputs based on
            -- the inLo hit signal.
            if inLo.hit = '1' then
              outHi := inLo;
            else
              outLo := inHi;
            end if;
            
            -- Override the PC output bits related to the offset within the
            -- cache line. Note: if unaligned reads are to become a thing later
            -- on, this needs to become a full blown adder.
            outLo.PC(RIC_ATOM_SIZE_BLOG2 + lvl) := '0';
            outHi.PC(RIC_ATOM_SIZE_BLOG2 + lvl) := '1';
            
          end if;
          
          -- Assign the output signals.
          outMuxDemux(lvl+1)(to_integer(indLo)) <= outLo;
          outMuxDemux(lvl+1)(to_integer(indHi)) <= outHi;
          
        end loop; -- i
      end process;
    end generate; -- lvl
  end generate;
  
  --===========================================================================
  -- Connect the outputs from the output mux/demux logic to the atom outputs
  --===========================================================================
  atom_output_gen : for i in 0 to RIC_NUM_ATOMS-1 generate
    
    -- Instruction output to the atom. Valid when stall is low and readEnable
    -- from the highest indexed coupled atom was high in the previous cycle.
    process (outMuxDemux(RIC_NUM_ATOMS_LOG2)(i)) is
      variable omd            : RIC_outputMuxDemuxVector;
      variable bitOffset      : natural;
    begin
      -- Shorthand for our output mux/demux signal.
      omd := outMuxDemux(RIC_NUM_ATOMS_LOG2)(i);
      
      -- Compute the bit offset within the cache line based upon the PC.
      bitOffset := to_integer(unsigned(omd.PC(
        RIC_ATOM_SIZE_BLOG2+RIC_NUM_ATOMS_LOG2-1 downto RIC_ATOM_SIZE_BLOG2
      ))) * RIC_ATOM_INSTR_WIDTH;
      
      -- Select the instruction based upon the computed offset within the line.
      cacheToAtoms(i).instr
        <= omd.line(bitOffset + RIC_ATOM_INSTR_WIDTH - 1 downto bitOffset);
      
    end process;
    
    -- Stall output. If readEnable from the highest indexed coupled atom is
    -- low, this is always low.
    cacheToAtoms(i).stall <=
      outMuxDemux(RIC_NUM_ATOMS_LOG2)(i).readEnable
      and not outMuxDemux(RIC_NUM_ATOMS_LOG2)(i).hit;
    
  end generate;
  
end Behavioral;

