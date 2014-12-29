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

-- Refer to reconfDCache_pkg.vhd for configuration constants and most
-- documentation.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library rvex;
use rvex.cache_data_pkg.all;

entity cache_data_block is
  generic (
    
    -- Block index, used to determine which of the invalidate source bits
    -- should be used as ignore bit.
    BLOCK_INDEX               : natural := 0
    
  );
  port (
    
    -- Clock input.
    clk                       : in  std_logic;
    
    -- Active high reset input.
    reset                     : in  std_logic;
    
    -- Active high CPU interface clock enable input.
    clkEnCPU                  : in  std_logic;
    
    -- Active high bus interface clock enable input.
    clkEnBus                  : in  std_logic;
    
    -- Signals connecting to the input mux/demux logic. Governed by clkEnCPU.
    input                     : in  RDC_inputMuxDemuxVector;
    output                    : out RDC_outputMuxDemuxVector;
    
    -- Connections to the memory bus. Governed by clkEnBus.
    memToCache                : in  reconfDCache_memIn;
    cacheToMem                : out reconfDCache_memOut;
    
    -- Cache line invalidation input. Governed by clkEnBus.
    inval                     : in  reconfDCache_invalIn
    
  );
end cache_data_block;

architecture Behavioral of cache_data_block is
  
  --===========================================================================
  -- CPU data network signals
  --===========================================================================
  -- Registers for the CPU memory access commands. These store the command from
  -- the CPU whenever the CPU clock is enabled and the CPU is not stalled.
  -- Thus, these command signals are valid after the first cycle of the
  -- command.
  signal cpuAddr_r            : std_logic_vector(RDC_BUS_ADDR_WIDTH-1 downto 0);
  signal readEnable_r         : std_logic;
  signal writeData_r          : std_logic_vector(RDC_BUS_DATA_WIDTH-1 downto 0);
  signal writeMask_r          : std_logic_vector(RDC_BUS_MASK_WIDTH-1 downto 0);
  signal writeEnable_r        : std_logic;
  signal bypass_r             : std_logic;
  
  -- Memory access command from the CPU. This is kept valid throughout the
  -- entire duration of the command, including the first cycle. In the first
  -- cycle (stall is low) the input from the CPU is selected, in later cycles
  -- (stall is high) the value from the command registers is selected because
  -- the CPU will already have prepared its next command by this time.
  signal cpuAddr              : std_logic_vector(RDC_BUS_ADDR_WIDTH-1 downto 0);
  signal readEnable           : std_logic;
  signal writeEnable          : std_logic;
  
  -- Clock gate signal for the data and tag RAM blocks for power saving. This
  -- is pulled low whenever the internal readEnable and writeEnable signals are
  -- low or clkEnCPU is low.
  signal clkEnCPUAndAccess    : std_logic;
  
  -- Signals that the CPU tag matches the stored tag at the addressed offset.
  -- Does NOT take the valid bit in consideration, that's what cpuHitValid
  -- does. This is just the tag comparator output.
  signal cpuHit               : std_logic;
  
  -- Whether the addressed cache line is valid.
  signal cpuValid             : std_logic;
  
  -- Whether the memory addressed by the CPU is valid.
  signal cpuHitValid          : std_logic;
  
  --===========================================================================
  -- Invalidation network signals
  --===========================================================================
  -- Signals that the invalidate tag matches the stored tag at the addressed
  -- offset. This signal is valid in the same pipeline stage as invalAddr_r and
  -- invalEnable_r.
  signal invalHit             : std_logic;
  
  -- Invalidate address register. This stores the invalidation request address
  -- while the tag is being compared.
  signal invalAddr_r          : std_logic_vector(RDC_BUS_ADDR_WIDTH-1 downto 0);
  
  -- Invalidate enable register. This stores the invalidation request enable
  -- while a tag is being compared.
  signal invalEnable_r        : std_logic;
  
  -- When high, signals that the line addressed by invalAddr_r should be
  -- invalidated.
  signal invalidate           : std_logic;
  
  --===========================================================================
  -- Cache memory signals
  --===========================================================================
  -- Active high cache line update signal. When high, updateData must be
  -- written to the cache line selected by cpuAddr respecting the byte mask in
  -- updateMask, the cache tag must be updated and the valid bit must be set.
  signal update               : std_logic;
  
  -- New data for the currently addressed cache line.
  signal updateData           : std_logic_vector(RDC_BUS_DATA_WIDTH-1 downto 0);
  
  -- Byte mask for writing to the currently addressed cache line.
  signal updateMask           : std_logic_vector(RDC_BUS_MASK_WIDTH-1 downto 0);
  
  -- Cache data output.
  signal cacheReadData        : std_logic_vector(RDC_BUS_DATA_WIDTH-1 downto 0);
  
begin
  
  --===========================================================================
  -- CPU (pipeline) logic
  --===========================================================================
  -- Instantiate registers for the incoming memory access command signals. We
  -- need to store these because the CPU is stalled one cycle after the
  -- request is made.
  cpu_regs: process (clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        readEnable_r  <= '0';
        writeEnable_r <= '0';
        bypass_r      <= '0';
      elsif clkEnCPU = '1' and input.stall = '0' then
        cpuAddr_r     <= input.addr;
        readEnable_r  <= input.readEnable;
        writeData_r   <= input.writeData;
        writeMask_r   <= input.writeMask;
        writeEnable_r <= input.writeEnable;
        bypass_r      <= input.bypass;
      end if;
    end if;
  end process;
  
  -- Select either the registers or the combinatorial command signals based on
  -- the stall signal.
  cpuAddr     <= cpuAddr_r     when input.stall = '1' else input.addr;
  readEnable  <= readEnable_r  when input.stall = '1' else input.readEnable;
  writeEnable <= writeEnable_r when input.stall = '1' else input.writeEnable;
  
  -- Forward the contents of the addr, readEnable and bypass registers to the
  -- mux/demux logic. readEnable is used to determine the read stall signal
  -- after merging, addr is used to select which cache block gets to update its
  -- cache when a miss occurs, bypass is used to force the datapath to choose
  -- the highest indexed cache block for the read data.
  output.addr <= cpuAddr_r;
  output.readEnable <= readEnable_r;
  output.bypass <= bypass_r;
  
  -- Determine whether the RAM blocks forming the cache need to be enabled or
  -- not.
  clkEnCPUAndAccess <= (readEnable or writeEnable) and clkEnCPU;
  
  -- Compute whether we have a hit and forward it up the hierarchy.
  cpuHitValid <= cpuHit and cpuValid;
  output.hit <= cpuHitValid;
  
  --===========================================================================
  -- Line invalidation (pipeline) logic
  --===========================================================================
  -- Instantiate registers to store the invalidation request while the tag is
  -- being read and compared.
  inval_regs: process (clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        invalEnable_r <= '0';
      elsif clkEnBus = '1' then
        invalAddr_r <= inval.invalAddr;
        invalEnable_r <= inval.invalEnable
          and not inval.invalSource(BLOCK_INDEX);
        -- ^- Don't invalidate a cache line when this block initiated the
        --    invalidation by writing to the memory. Our cache line is
        --    guaranteed to match the memory written in this case.
      end if;
    end if;
  end process;
  
  -- Determine whether the line addressed by invalAddr_r needs to be
  -- invalidated.
  invalidate <= invalEnable_r and invalHit;
  
  --===========================================================================
  -- Instantiate cache line storage
  --===========================================================================
  data_ram: entity rvex.cache_data_blockData
    port map (
      
      -- Clock input.
      clk                     => clk,
      
      -- Active high enable input.
      enable                  => clkEnCPUAndAccess,
      
      -- CPU address input.
      cpuAddr                 => cpuAddr,
      
      -- Read data output.
      readData                => cacheReadData,
      
      -- Active high write enable input.
      writeEnable             => update,
      
      -- Write data input.
      writeData               => updateData,
      
      -- Write mask input.
      writeMask               => updateMask
      
    );
  
  --===========================================================================
  -- Instantiate cache tag storage and comparators
  --===========================================================================
  tag_ram: entity rvex.cache_data_blockTag
    port map (
      
      -- Clock input.
      clk                     => clk,
      
      -- Active high enable input for CPU signals.
      enableCPU               => clkEnCPUAndAccess,
      
      -- Active high enable input for invalidate signals.
      enableBus               => clkEnBus,
      
      -- CPU address/PC input.
      cpuAddr                 => cpuAddr,
      
      -- Hit output for the CPU, delayed by one cycle with enable high due to
      -- the memory.
      cpuHit                  => cpuHit,
      
      -- Write enable signal to write the CPU tag to the memory.
      writeCpuTag             => update,
      
      -- Invalidate address input.
      invalAddr               => inval.invalAddr,
      
      -- Hit output for the invalidation logic, delayed by one cycle with
      -- enable high due to the memory.
      invalHit                => invalHit
      
    );
  
  --===========================================================================
  -- Instantiate cache line valid bit storage
  --===========================================================================
  valid_ram: entity rvex.cache_data_blockValid
    port map (
      
      -- Clock input.
      clk                     => clk,
      
      -- Active high reset input.
      reset                   => reset,
      
      -- Active high enable input for the CPU domain.
      enableCPU               => clkEnCPUAndAccess,
      
      -- Active high enable input for the bus domain.
      enableBus               => clkEnBus,
      
      -- CPU address input.
      cpuAddr                 => cpuAddr,
      
      -- Valid output for the CPU, delayed by one cycle to synchronize with the
      -- tag memory. Governed by enableCPU.
      cpuValid                => cpuValid,
      
      -- Active high validate input. This synchronously sets the valid bit
      -- addressed by the CPU. Governed by enableCPU.
      validate                => update,
      
      -- Invalidate address input. Governed by enableBus.
      invalAddr               => invalAddr_r,
      
      -- Active high invalidate input. This synchronously resets the valid bit
      -- addressed by invalAddr. Governed by enableBus.
      invalidate              => invalidate,
      
      -- Active high flush input. This synchronously resets all valid bits.
      -- Governed by enableBus.
      flush                   => inval.flush
      
    );
  
  --===========================================================================
  -- Instantiate the controllers
  --===========================================================================
  -- This controller handles read misses and CPU writes to cache and the write
  -- buffer.
  main_controller: entity rvex.cache_data_mainCtrl
    port map (
      
      -- Clock input.
      clk                     => clk,
      
      -- Active high reset input.
      reset                   => reset,
      
      -- Active high clock enable input for the CPU domain.
      clkEnCPU                => clkEnCPU,
      
      -- Active high clock enable input for the bus domain.
      clkEnBus                => clkEnBus,
      
      
      -- CPU address input, delayed by one cycle to sync up with hit.
      addr                    => cpuAddr_r,
      
      -- CPU read enable signal, delayed by one cycle to sync up with hit.
      readEnable              => readEnable_r,
      
      -- CPU read data output. Valid when clkEnCPU is high and stall is low.
      readData                => output.data,
      
      -- CPU write enable signal, delayed by one cycle to sync up with hit.
      writeEnable             => writeEnable_r,
      
      -- CPU write data, delayed by one cycle to sync up with hit.
      writeData               => writeData_r,
      
      -- CPU write data byte mask, delayed by one cycle to sync up with hit.
      writeMask               => writeMask_r,
      
      -- CPU bypass signal, delayed by one cycle to sync up with hit.
      bypass                  => bypass_r,
      
      -- Stall input from the CPU.
      stall                   => input.stall,
      
      -- Stall output signal for write or bypass signals. Read miss stalls are
      -- computed in the mux/demux network.
      writeOrBypassStall      => output.writeOrBypassStall,
      
      
      -- Update enable signal from the mux/demux logic signalling that the cache
      -- line which contains cpuAddr should be refreshed. While an update is in
      -- progress, cpuAddr is assumed to be stable. Governed by the clkEnCPU
      -- clock gate signal.
      updateEnable            => input.updateEnable,
      
      -- Control signal from the mux/demux logic, indicating that this block
      -- should be the one to handle the write request. Synchronized with the
      -- hit signal like everything else.
      handleWrite             => input.handleWrite,
      
      -- Write selection priority. This is used to determine which of the cache
      -- blocks should handle writes by the mux/demux network.
      writePrio               => output.writePrio,
      
      
      -- Whether the cache memory is valid for the word requested by the CPU.
      hit                     => cpuHitValid,
      
      -- Data read from the cache memory.
      cacheReadData           => cacheReadData,
      
      -- Signals that the updateData should be written to the addressed line
      -- in the cache data memory in accordance with updateMask, that the tag
      -- must be updated and that the valid bit must be set.
      update                  => update,
      
      -- Write data for the cache data memory.
      updateData              => updateData,
      
      -- Write data for the cache data memory.
      updateMask              => updateMask,
      
      
      -- Connections to the memory bus. Governed by clkEnBus.
      memToCache              => memToCache,
      cacheToMem              => cacheToMem
      
    );
  
  -- Initialize writeSel to '1' in the output mux/demux network.
  output.writeSel <= '1';
  
end Behavioral;

