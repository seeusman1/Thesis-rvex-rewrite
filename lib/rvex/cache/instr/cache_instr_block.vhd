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

entity cache_instr_block is
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
    input                     : in  RIC_inputMuxDemuxVector;
    output                    : out RIC_outputMuxDemuxVector;
    
    -- Connections to the memory bus. Governed by clkEnBus.
    memToCache                : in  reconfICache_memIn;
    cacheToMem                : out reconfICache_memOut;
    
    -- Cache line invalidation input. Governed by clkEnBus.
    inval                     : in  reconfICache_invalIn
    
  );
end cache_instr_block;

architecture Behavioral of cache_instr_block is
  
  --===========================================================================
  -- CPU data network signals
  --===========================================================================
  -- CPU address register. This stores the address from the CPU whenever the
  -- CPU clock is enabled and the CPU is not stalled.
  signal cpuAddr_r            : std_logic_vector(RIC_PC_WIDTH-1 downto 0);
  
  -- Same as cpuAddr_r, but for the incoming readEnable signal.
  signal readEnable_r         : std_logic;
  
  -- CPU address input, which remains valid when the CPU is stalled. During a
  -- stall, the CPU address register is muxed to this signal, otherwise the
  -- CPU address is muxed here directly.
  signal cpuAddr              : std_logic_vector(RIC_PC_WIDTH-1 downto 0);
  
  -- Same as the cpuAddr signal, but for the incoming readEnable signal.
  signal readEnable           : std_logic;
  
  -- Clock gate signal for the data and tag RAM blocks for power saving. This
  -- is pulled low whenever the internal readEnable signal is low or clkEnCPU
  -- is low.
  signal clkEnCPUAndReadEnable: std_logic;
  
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
  signal invalAddr_r          : std_logic_vector(RIC_PC_WIDTH-1 downto 0);
  
  -- Invalidate enable register. This stores the invalidation request enable
  -- while a tag is being compared.
  signal invalEnable_r        : std_logic;
  
  -- When high, signals that the line addressed by invalAddr_r should be
  -- invalidated.
  signal invalidate           : std_logic;
  
  --===========================================================================
  -- Cache line loading signals
  --===========================================================================
  -- Active high cache line update signal. When high, the currently addressed
  -- cache line data should be set to updateData, the cache tag must be
  -- updated and the valid bit should be set.
  signal update               : std_logic;
  
  -- New data for the currently addressed cache line.
  signal updateData           : std_logic_vector(RIC_LINE_WIDTH-1 downto 0);
  
begin
  
  --===========================================================================
  -- CPU (pipeline) logic
  --===========================================================================
  -- Instantiate registers for the incoming readEnable and PC signals. We need
  -- to store these because the CPU is stalled one cycle after the request.
  cpu_regs: process (clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        readEnable_r <= '0';
      elsif clkEnCPU = '1' and input.stall = '0' then
        cpuAddr_r <= input.PC;
        readEnable_r <= input.readEnable;
      end if;
    end if;
  end process;
  
  -- Select either the register or the CPU signal directly based on the stall
  -- signal.
  cpuAddr <= cpuAddr_r when input.stall = '1' else input.PC;
  readEnable <= readEnable_r when input.stall = '1' else input.readEnable;
  
  -- Forward the contents of the PC and readEnable registers to the mux/demux
  -- logic one level up.
  output.PC <= cpuAddr_r;
  output.readEnable <= readEnable_r;
  
  -- Determine whether the RAM blocks forming the cache need to be enabled or
  -- not.
  clkEnCPUAndReadEnable <= readEnable and clkEnCPU;
  
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
        invalEnable_r <= inval.invalEnable;
      end if;
    end if;
  end process;
  
  -- Determine whether the line addressed by invalAddr_r needs to be
  -- invalidated.
  invalidate <= invalEnable_r and invalHit;
  
  --===========================================================================
  -- Instantiate cache line storage
  --===========================================================================
  data_ram: entity rvex.cache_instr_blockData
    port map (
      
      -- Clock input.
      clk                     => clk,
      
      -- Active high enable input.
      enable                  => clkEnCPUAndReadEnable,
      
      -- CPU address input.
      cpuAddr                 => cpuAddr,
      
      -- Read data output.
      readData                => output.line,
      
      -- Active high write enable input.
      writeEnable             => update,
      
      -- Write data input.
      writeData               => updateData
      
    );
  
  --===========================================================================
  -- Instantiate cache tag storage and comparators
  --===========================================================================
  tag_ram: entity rvex.cache_instr_blockTag
    port map (
      
      -- Clock input.
      clk                     => clk,
      
      -- Active high enable input for CPU signals.
      enableCPU               => clkEnCPUAndReadEnable,
      
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
  valid_ram: entity rvex.cache_instr_blockValid
    port map (
      
      -- Clock input.
      clk                     => clk,
      
      -- Active high reset input.
      reset                   => reset,
      
      -- Active high enable input for the CPU domain.
      enableCPU               => clkEnCPUAndReadEnable,
      
      -- Active high enable input for the bus domain.
      enableBus               => clkEnBus,
      
      -- CPU address/PC input.
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
  -- Instantiate the miss resolution controller
  --===========================================================================
  miss_controller: entity rvex.cache_instr_missCtrl
    port map (
      
      -- Clock input.
      clk                     => clk,
      
      -- Active high reset input.
      reset                   => reset,
      
      -- Active high clock enable input for the CPU domain.
      clkEnCPU                => clkEnCPU,
      
      -- Active high clock enable input for the bus domain.
      clkEnBus                => clkEnBus,
      
      -- CPU address/PC input.
      cpuAddr                 => cpuAddr_r,
      
      -- Update enable signal from the mux/demux logic signalling that the
      -- cache line which contains cpuAddr should be refreshed. While an
      -- update is in progress, cpuAddr is assumed to be stable. Governed by 
      -- the clkEnCPU clock gate signal.
      updateEnable            => input.updateEnable,
      
      -- Signals that the line fetch is complete and that the data in line is
      -- to be written to the data memory. Governed by the clkEnCPU clock gate
      -- signal.
      done                    => update,
      
      -- Cache line data output, valid when done is high.
      line                    => updateData,
      
      -- Connections to the memory bus. Governed by clkEnBus.
      memToCache              => memToCache,
      cacheToMem              => cacheToMem
      
    );
  
end Behavioral;

