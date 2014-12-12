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

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

library rvex;
use rvex.common_pkg.all;
use rvex.utils_pkg.all;

--=============================================================================
-- This entity serves as a memory arbiter from N R/W ports to M single-cycle
-- latency R/W ports, which may be connected to block RAM resources. Note that
-- this implementation is very much optimized for speed and not for area; it
-- gets big really fast when there's a lot of ports.
-------------------------------------------------------------------------------
entity standalone_arbiter is
--=============================================================================
  generic (
    
    -- Number of masters which need to be arbitrated among the memory ports.
    NUM_MASTERS                 : positive := 4;
    
    -- Number of physical memory ports.
    NUM_PORTS                   : positive := 2
    
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
    -- Master busses
    ---------------------------------------------------------------------------
    -- Master busses. These behave as single cycle busses, as long as the clock
    -- of the masters is gated by clkEn and the stall output from this block.
    bus2arb_address             : in  rvex_address_array(NUM_MASTERS-1 downto 0);
    bus2arb_writeEnable         : in  std_logic_vector(NUM_MASTERS-1 downto 0);
    bus2arb_writeMask           : in  rvex_mask_array(NUM_MASTERS-1 downto 0);
    bus2arb_writeData           : in  rvex_data_array(NUM_MASTERS-1 downto 0);
    bus2arb_readEnable          : in  std_logic_vector(NUM_MASTERS-1 downto 0);
    arb2bus_readData            : out rvex_data_array(NUM_MASTERS-1 downto 0);
    
    -- When high, the bus masters should be clock gated. The commands issued
    -- by the masters must be fixed while a stall is in progress or behavior is
    -- undefined.
    arb2bus_stall               : out std_logic;
    
    ---------------------------------------------------------------------------
    -- Master busses
    ---------------------------------------------------------------------------
    -- Memory busses.
    arb2mem_address             : out rvex_address_array(NUM_PORTS-1 downto 0);
    arb2mem_writeEnable         : out std_logic_vector(NUM_PORTS-1 downto 0);
    arb2mem_writeMask           : out rvex_mask_array(NUM_PORTS-1 downto 0);
    arb2mem_writeData           : out rvex_data_array(NUM_PORTS-1 downto 0);
    arb2mem_readEnable          : out std_logic_vector(NUM_PORTS-1 downto 0);
    mem2arb_readData            : in  rvex_data_array(NUM_PORTS-1 downto 0)
    
  );
end standalone_arbiter;

--=============================================================================
architecture Behavioral of standalone_arbiter is
--=============================================================================
  
  -- The state vector must be able to encode all states in the worst case
  -- scenario, where all masters are active at the same time, and must
  -- sequentially be given access to the memory ports.
  constant STATE_SIZE           : natural := integer(ceil(log2(ceil(real(NUM_MASTERS) / real(NUM_PORTS)))));
  
  -- log2s of the number of masters and ports, used as sizes for the mux
  -- selection signals.
  constant NUM_MASTERS_LOG2     : natural := integer(ceil(log2(real(NUM_MASTERS))));
  constant NUM_PORTS_LOG2       : natural := integer(ceil(log2(real(NUM_PORTS))));
  
  -- Port and bus selection types.
  subtype masterSel_type is std_logic_vector(NUM_MASTERS_LOG2-1 downto 0);
  subtype portSel_type is std_logic_vector(NUM_PORTS_LOG2-1 downto 0);
  type masterSel_array is array (natural range <>) of masterSel_type;
  type portSel_array is array (natural range <>) of portSel_type;
  
  -- Control signal type.
  type ctrlSignals_type is record
    
    -- Next value for the state vector. The state vector is encoded such that
    -- the stall output can be determined by or'ing all signals in the new
    -- state vector.
    newState                    : std_logic_vector(STATE_SIZE-1 downto 0);
    
    -- The master which is given access to a port, for each port.
    selectedMaster              : masterSel_array(NUM_PORTS-1 downto 0);
    
    -- Enable signal for each memory port.
    portEnable                  : std_logic_vector(NUM_PORTS-1 downto 0);
    
    -- The port which will contain the data for the bus in the next cycle.
    selectedPort                : portSel_array(NUM_MASTERS-1 downto 0);
    
    -- Enable signal for each bus, used, in combination with the local
    -- readEnable signal, to enable the read data holding register, and to
    -- bypass the register and let the data pass through directly. This is
    -- valid in the next cycle, due to the latency cycle in the memory.
    masterEnable                : std_logic_vector(NUM_MASTERS-1 downto 0);
    
  end record;
  
  -- Array type for the control signals.
  type ctrlSignals_array is array (natural range <>) of ctrlSignals_type;
  
  -- Number of bits needed as input to the state machine which generates the
  -- control signals. One signal is needed per master bus, representing whether
  -- it desires to access the memory or not. The remainder is needed for the
  -- FSM state.
  constant NUM_FSM_INPUT_BITS   : natural := NUM_MASTERS + STATE_SIZE;
  
  -- Type for the control signal lookup table. The LSBs of the index should
  -- be connected to the FSM state, the MSBs to the access signals from the
  -- ports.
  subtype ctrlSignalLookup_type is ctrlSignals_array(0 to 2**NUM_FSM_INPUT_BITS-1);
  
  -- Returns the highest index within an std_logic_vector which is set, or -1
  -- if the vector is 0.
  pure function getHighestSetIndex(vect: std_logic_vector) return integer is
  begin
    for i in vect'high downto vect'low loop
      if vect(i) = '1' then
        return i;
      end if;
    end loop;
    return -1;
  end getHighestSetIndex;
  
  -- Generates the control signals lookup table.
  pure function ctrlSignalLookup_gen return ctrlSignalLookup_type is
    variable result : ctrlSignalLookup_type;
    variable resIdx : natural;
    variable todo   : std_logic_vector(NUM_MASTERS-1 downto 0);
    variable mstIdx : integer;
  begin
    
    -- Loop over all possible access control signals, represented in the todo
    -- vector within the loop.
    for masters in 0 to 2**NUM_MASTERS-1 loop
      todo := uint2vect(masters, NUM_MASTERS);
      
      -- Loop over the possible states.
      for state in 0 to 2**STATE_SIZE-1 loop
        
        -- Determine the index within the control signal lookup table
        -- associated with this loop iteration.
        resIdx := masters * 2**STATE_SIZE + state;
        
        -- Default for the next state is incrementing the current state. We
        -- override this to 0 when there are no more requests pending.
        if state < 2**STATE_SIZE then
          result(resIdx).newState := uint2vect(state, STATE_SIZE);
        else
          result(resIdx).newState := (others => '0');
        end if;
        
        -- Masters default to having no access over a port.
        result(resIdx).selectedPort := (others => (others => '0'));
        result(resIdx).masterEnable := (others => '0');
        
        -- Schedule the accesses.
        for memPort in 0 to NUM_PORTS-1 loop
          
          -- Pick a master from the list which still needs to be serviced.
          mstIdx := getHighestSetIndex(todo);
          
          if mstIdx /= -1 then
            
            -- Connect the master to the port which we're currently scheduling
            -- for.
            result(resIdx).selectedMaster(memPort)
              := uint2vect(mstIdx, NUM_MASTERS_LOG2);
            result(resIdx).portEnable(memPort) := '1';
            result(resIdx).selectedPort(mstIdx)
              := uint2vect(memPort, NUM_PORTS_LOG2);
            result(resIdx).masterEnable(mstIdx) := '1';
            
          else
            
            -- No more requests to service, don't connect this port.
            result(resIdx).selectedMaster(memPort) := (others => '0');
            result(resIdx).portEnable(memPort) := '0';
            
            -- Next state should be 0, so we get a new set of requests.
            result(resIdx).newState := (others => '0');
            
          end if;
          
        end loop;
        
      end loop;
      
    end loop;
    
    -- Return the constructed table.
    return result;
    
  end ctrlSignalLookup_gen;
  
  -- Control signal lookup table, generated during design elaboration using the
  -- function above.
  constant CTRL_LOOKUP          : ctrlSignalLookup_type := ctrlSignalLookup_gen;
  
  -- Current FSM state.
  signal state                  : std_logic_vector(STATE_SIZE-1 downto 0);
  
  -- Access enable signals for each memory port.
  signal accessEnable           : std_logic_vector(NUM_MASTERS-1 downto 0);
  
  -- Contains the current decoded control signals.
  signal ctrl                   : ctrlSignals_type;
  
  -- These signals determine which memory port currently has read data for the
  -- indexed master. These are the relevant signals from ctrl delayed by one
  -- cycle to account for the read latency of the memory ports. The valid
  -- signal is also and'ed with the read enable signal before being registered.
  signal readDataPort           : portSel_array(NUM_MASTERS-1 downto 0);
  signal readDataValid          : std_logic_vector(NUM_MASTERS-1 downto 0);
  
  -- Read data muxed among the read ports for each master. Valid when
  -- readDataValid is valid.
  signal readDataMux            : rvex_data_array(NUM_MASTERS-1 downto 0);
  
  -- Read data holding register for each master.
  signal readDataHoldingRegs    : rvex_data_array(NUM_MASTERS-1 downto 0);
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- Control register and FSM generation
  -----------------------------------------------------------------------------
  -- Generate the access enable signals.
  accessEnable <= bus2arb_readEnable or bus2arb_writeEnable;
  
  -- Generate the FSM state register and registers for the read data routing
  -- control signals.
  ctrl_regs: process (clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        state <= (others => '0');
        readDataPort <= (others => (others => '0'));
        readDataValid <= (others => '0');
      elsif clkEn = '1' then
        state <= ctrl.newState;
        readDataPort <= ctrl.selectedPort;
        readDataValid <= ctrl.masterEnable and bus2arb_readEnable;
      end if;
    end if;
  end process;
  
  -- Decode the control registers.
  ctrl <= CTRL_LOOKUP(vect2uint(accessEnable & state));
  
  -- Generate the stall signal.
  arb2bus_stall <= '1' when vect2uint(ctrl.newState) /= 0 else '0';
  
  -----------------------------------------------------------------------------
  -- Memory port command muxing
  -----------------------------------------------------------------------------
  -- Connect a bus master to each memory port, or connect nothing for ports
  -- which are not in use.
  command_mux_gen: for memPort in 0 to NUM_PORTS-1 generate
    
    arb2mem_address(memPort)
      <= bus2arb_address(vect2uint(ctrl.selectedMaster(memPort)));
    
    arb2mem_writeEnable(memPort)
      <= bus2arb_writeEnable(vect2uint(ctrl.selectedMaster(memPort)))
      and ctrl.portEnable(memPort);
    
    arb2mem_writeMask(memPort)
      <= bus2arb_writeMask(vect2uint(ctrl.selectedMaster(memPort)));
    
    arb2mem_writeData(memPort)
      <= bus2arb_writeData(vect2uint(ctrl.selectedMaster(memPort)));
    
    arb2mem_readEnable(memPort)
      <= bus2arb_readEnable(vect2uint(ctrl.selectedMaster(memPort)))
      and ctrl.portEnable(memPort);
    
  end generate;
  
  -----------------------------------------------------------------------------
  -- Read data muxing
  -----------------------------------------------------------------------------
  -- Generate the muxes.
  result_mux1_gen: for mstIdx in 0 to NUM_MASTERS-1 generate
    readDataMux(mstIdx) <= mem2arb_readData(vect2uint(readDataPort(mstIdx)));
  end generate;
  
  -- Generate the read data holding registers. These store the read data from
  -- a port while the masters are stalled.
  holding_regs: process (clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        readDataHoldingRegs <= (others => (others => '0'));
      elsif clkEn = '1' then
        for mstIdx in 0 to NUM_MASTERS-1 loop
          if readDataValid(mstIdx) = '1' then
            readDataHoldingRegs(mstIdx) <= readDataMux(mstIdx);
          end if;
        end loop;
      end if;
    end if;
  end process;
  
  -- Mux between the combinatorial signal and the holding register to avoid
  -- adding a cycle delay to the read datapath.
  result_mux2_gen: for mstIdx in 0 to NUM_MASTERS-1 generate
    arb2bus_readData(mstIdx)
      <= readDataMux(mstIdx) when readDataValid(mstIdx) = '1'
      else readDataHoldingRegs(mstIdx);
  end generate;
  
end Behavioral;

