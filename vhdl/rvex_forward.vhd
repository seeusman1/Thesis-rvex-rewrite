-- Insert license here

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

library work;
use work.rvex_pkg.all;
use work.rvex_ctrlRegs_pkg.all;

--=============================================================================
-- This entity controls forwarding for a register file. The unit is completely
-- combinatorial.
-------------------------------------------------------------------------------
entity rvex_forward is
--=============================================================================
  generic (
    
    ---------------------------------------------------------------------------
    -- Configuration
    ---------------------------------------------------------------------------
    -- Enables or disables forwarding. When forwarding is disabled, the read
    -- values from the registers are passed through combinatorially.
    ENABLE_FORWARDING           : boolean := true;
    
    -- Data width for the register file being forwarded.
    DATA_WIDTH                  : natural := 32;
    
    -- Address width (log2 of the depth) of the register file being forwarded.
    ADDRESS_WIDTH               : natural := 6;
    
    -- Number of register write ports in total.
    NUM_LANES                   : natural := 8;
    
    -- Number of pipeline stages to forward.
    NUM_STAGES_TO_FORWARD       : natural := 2
    
  );
  port (
    
    ---------------------------------------------------------------------------
    -- Register read connections
    ---------------------------------------------------------------------------
    -- Read address as was requested from the register file.
    readAddress                 : in  std_logic_vector(ADDRESS_WIDTH-1 downto 0);
    
    -- Read data from the register file.
    readDataIn                  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    
    -- Read data output with forwarding.
    readDataOut                 : out std_logic_vector(DATA_WIDTH-1 downto 0);
    
    ---------------------------------------------------------------------------
    -- Queued write signals
    ---------------------------------------------------------------------------
    -- Lower indexed ports take precedence and should thus be connected to
    -- earlier pipeline stages.
    
    -- Write address from each pipelane/stage combo.
    writeAddresses              : in  std_logic_vector(NUM_LANES*NUM_STAGES_TO_FORWARD*ADDRESS_WIDTH-1 downto 0);
    
    -- Write data from each pipelane/stage combo.
    writeDatas                  : in  std_logic_vector(NUM_LANES*NUM_STAGES_TO_FORWARD*DATA_WIDTH-1 downto 0);
    
    -- Write enable input signal from each pipelane/stage combo.
    writeEnables                : in  std_logic_vector(NUM_LANES*NUM_STAGES_TO_FORWARD-1 downto 0);
    
    -- Coupled input for each write port from the configuration logic. Bit n
    -- in this should be set when the lane corrosponding to write port n is
    -- using the same context as the read port. It essentially gates the
    -- writeEnable signals for each stage when low.
    coupled                     : in  std_logic_vector(NUM_LANES-1 downto 0)
    
  );
end rvex_forward;

--=============================================================================
architecture Behavioral of rvex_forward is
--=============================================================================
  
  -- Compute the width of the priority encoder output.
  constant NUM_MATCH_UNITS_LOG2 : integer := integer(ceil(log2(real(NUM_LANES*NUM_STAGES_TO_FORWARD))));
  
  -- Address-matches-and-write-is-enabled signals for each write port.
  signal match                  : std_logic_vector(NUM_LANES*NUM_STAGES_TO_FORWARD-1 downto 0);
  
  -- Output from the priority encoder among the match signals. This is set to
  -- the lowest index in match which is high, or 0 if none are high.
  signal firstMatch             : std_logic_vector(NUM_MATCH_UNITS_LOG2-1 downto 0);
  
  -- High when any of the match signals is high. Determines whether something
  -- should be forwarded or not.
  signal anyMatch               : std_logic;
  
--=============================================================================
begin -- architecture
--=============================================================================
  
  forwarding_enabled: if ENABLE_FORWARDING generate
  
    ---------------------------------------------------------------------------
    -- Address matching
    ---------------------------------------------------------------------------
    match_gen: for i in 0 to NUM_LANES*NUM_STAGES_TO_FORWARD-1 generate
      signal a                  : std_logic_vector(ADDRESS_WIDTH+1 downto 0);
      signal b                  : std_logic_vector(ADDRESS_WIDTH+1 downto 0);
    begin
      
      a(ADDRESS_WIDTH-1 downto 0) <=
        readAddress;
      
      b(ADDRESS_WIDTH-1 downto 0) <=
        writeAddresses(ADDRESS_WIDTH*i+ADDRESS_WIDTH-1 downto ADDRESS_WIDTH*i);
      
      -- Add the enable signals to the address matching comparator, because we
      -- would like to use the carry chains for this instead of inferring a LUT
      -- after the comparison for the and gate.
      a(ADDRESS_WIDTH) <= '1';
      b(ADDRESS_WIDTH) <= writeEnables(i);
      
      a(ADDRESS_WIDTH+1) <= '1';
      b(ADDRESS_WIDTH+1) <= coupled(i mod NUM_LANES);
      
      match(i) <= '1' when a = b else '0';
      
    end generate;
    
    ---------------------------------------------------------------------------
    -- Priority encoder
    ---------------------------------------------------------------------------
    -- Infer a priority encoder using some high level code and hope that the
    -- synthesizer knows how to deal with it efficiently (this seems to
    -- generate three levels of LUTs for a 16:4 priority encoder, which is also
    -- the minimum I can come up with from looking are the hardwired slice
    -- logic for a Virtex 6). Also generate the anyMatch signal while we're at
    -- it.
    priority_encoder: process (match) is
    begin
      firstMatch <= (others => '0');
      anyMatch <= '0';
      
      -- Last signal assignment has priority in VHDL, so loop in descending
      -- order.
      for i in NUM_LANES*NUM_STAGES_TO_FORWARD-1 downto 0 loop
        if match(i) = '1' then
          firstMatch <= std_logic_vector(to_unsigned(i, NUM_MATCH_UNITS_LOG2));
          anyMatch <= '1';
        end if;
      end loop;
      
    end process;
    
    ---------------------------------------------------------------------------
    -- Output mux
    ---------------------------------------------------------------------------
    -- Infer the output mux using high-level code.
    output_mux: process (anyMatch, firstMatch, readDataIn, writeDatas) is
      variable sel              : integer;
    begin
      
      -- Select the regular register read by default.
      readDataOut <= readDataIn;
      
      -- If anyMatch is high, perform forwarding.
      if anyMatch = '1' then
        sel := to_integer(unsigned(firstMatch));
        
        -- This should always be true, but it might not always be for as far as
        -- VHDL is concerned.
        if sel < NUM_LANES*NUM_STAGES_TO_FORWARD then
          readDataOut <= writeDatas(DATA_WIDTH*sel+DATA_WIDTH-1 downto DATA_WIDTH*sel);
        end if;
      end if;
      
    end process;
    
  end generate forwarding_enabled;
  
  -----------------------------------------------------------------------------
  -- Handle forwarding-logic-disabled case
  -----------------------------------------------------------------------------
  forwarding_disabled: if not ENABLE_FORWARDING generate
    
    -- Simply forward the register read.
    readDataOut <= readDataIn;
    
  end generate forwarding_disabled;
  
end Behavioral;

