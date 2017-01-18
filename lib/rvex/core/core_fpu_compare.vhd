-- Copyright (c) 2002-2011 Tampere University of Technology.
--
-- This file is part of TTA-Based Codesign Environment (TCE).
-- 
-- Permission is hereby granted, free of charge, to any person obtaining a
-- copy of this software and associated documentation files (the "Software"),
-- to deal in the Software without restriction, including without limitation
-- the rights to use, copy, modify, merge, publish, distribute, sublicense,
-- and/or sell copies of the Software, and to permit persons to whom the
-- Software is furnished to do so, subject to the following conditions:
-- 
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
-- FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
-- DEALINGS IN THE SOFTWARE.
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

-- Separation between combinatorial part and control part 
-- is copy-pasted from a FU in the included asic hdb,
-- so as to get the control part right.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library rvex;
use rvex.fpu_fixed_pkg.all;
use rvex.fpu_float_pkg.all;
use rvex.fpu_fixed_float_types.all;

use rvex.common_pkg.all;
use rvex.core_intIface_pkg.all;
use rvex.core_pipeline_pkg.all;
use rvex.core_opcode_pkg.all;
use rvex.core_opcodeFpu_pkg.all;

use rvex.utils_pkg.all;

entity core_fpu_compare is
  port (
  
    ---------------------------------------------------------------------------
    -- System control
    ---------------------------------------------------------------------------
    -- Active high synchronous reset input
    reset                       : in  std_logic;
    
    -- Clock input, registers are rising edge triggered
    clk                         : in  std_logic;
    
    -- Active high global clock enable input
    clkEn                       : in  std_logic;
    
    -- Active high stall input for the pipeline
    stall                       : in  std_logic;
  
    ---------------------------------------------------------------------------
    -- Operand and control inputs
    ---------------------------------------------------------------------------
    -- Opcode
    pl2fcmp_opcode              : in  rvex_opcode_array(S_FCMP to S_FCMP);
    
    -- 32-bit operands
    pl2fcmp_opl                 : in  rvex_data_array(S_FCMP to S_FCMP);
    pl2fcmp_opr                 : in  rvex_data_array(S_FCMP to S_FCMP);
    
    ---------------------------------------------------------------------------
    -- Outputs
    ---------------------------------------------------------------------------
    -- 32-bit output
    fcmp2pl_result              : out rvex_data_array(S_FCMP+L_FCMP to S_FCMP+L_FCMP);
    
    -- 1-bit branch output
    fcmp2pl_resultBr            : out std_logic_vector(S_FCMP+L_FCMP to S_FCMP+L_FCMP)
  );
end entity;


architecture rtl of core_fpu_compare is

  constant busw                 : integer := 32;
  constant mw                   : integer := 23;
  constant ew                   : integer := 8;
  

  type operationState_type is record
  
    -- Inputs
    op_l                        : std_logic_vector(busw-1 downto 0);
    op_r                        : std_logic_vector(busw-1 downto 0);
    opcode                      : fpuCmpOp_type;
    
    -- Intermediates
    lsign                       : std_logic;
    rsign                       : std_logic;
    
    labs                        : unsigned(mw+ew-1 downto 0);
    rabs                        : unsigned(mw+ew-1 downto 0);
    
    ltype                       : valid_fpstate;
    rtype                       : valid_fpstate;
    
    eq                          : std_logic;
    gt                          : std_logic;
    
    -- Outputs
    result                      : std_logic;
  
  end record;
  
  constant operationState_init : operationState_type := (
    op_l                        => (others => '0'),
    op_r                        => (others => '0'),
    opcode                      => EQ,
    
    lsign                       => '0',
    rsign                       => '0',
    labs                        => (others => '0'),
    rabs                        => (others => '0'),
    ltype                       => nan,
    rtype                       => nan,
    eq                          => '0',
    gt                          => '0',
    
    result                      => '0'
  );
  
  type operationState_array is array (natural range <>) of operationState_type;
  
  -- Execution phases
  constant P_DEC                : natural := 1; -- DECode inputs
  constant P_CMP                : natural := 2; -- CoMPare
  constant P_RES                : natural := 3; -- generate RESult
  
  constant NUM_PHASES           : natural := P_RES;
  
  -- Internal phase inputs (si) and outputs (so)
  signal si                     : operationState_array(1 to NUM_PHASES) := (others => operationState_init);
  signal so                     : operationState_array(1 to NUM_PHASES) := (others => operationState_init);
  
begin

  -----------------------------------------------------------------------------
  -- Check configuration
  -----------------------------------------------------------------------------
  assert (L_FCMP1 = 0) or (L_FCMP1 = 1)
    report "Latency for FPU_compare phase 1 (L_FCMP1) must be set to 0 or 1 in "
         & "pipeline_pkg.vhd."
    severity failure;
  
  assert (L_FCMP2 = 0) or (L_FCMP2 = 1)
    report "Latency for FPU_compare phase 2 (L_FCMP2) must be set to 0 or 1 in "
         & "pipeline_pkg.vhd."
    severity failure;
  
  assert L_FCMP = L_FCMP1 + L_FCMP2
    report "Total latency for FPU_compare must match sum of phase latencies."
    severity failure;

  -----------------------------------------------------------------------------
  -- Copy inputs to operation state
  -----------------------------------------------------------------------------
  si(P_DEC).op_l   <= pl2fcmp_opl(S_FCMP);
  si(P_DEC).op_r   <= pl2fcmp_opr(S_FCMP);
  si(P_DEC).opcode <= OPCODE_TABLE(vect2uint(pl2fcmp_opcode(S_FCMP))).fpuCtrl.cmpOp;

  -----------------------------------------------------------------------------
  -- Execute phase 1 (decode)
  -----------------------------------------------------------------------------
  phase_decode: process(si(P_DEC))
    
    variable labs, rabs : unsigned(mw+ew-1 downto 0);
    variable l, r : UNRESOLVED_float(ew downto -mw);
    
  begin
  
    -- Forward by default
    so(P_DEC) <= si(P_DEC);
  
    -- Get sign, abs value and type
    labs := unsigned(si(P_DEC).op_l(mw+ew-1 downto 0));
    rabs := unsigned(si(P_DEC).op_r(mw+ew-1 downto 0));
    so(P_DEC).labs <= labs;
    so(P_DEC).rabs <= rabs;
    
    -- handle negative zero
    if labs = 0 then
      so(P_DEC).lsign <= '0';
    else
      so(P_DEC).lsign <= si(P_DEC).op_l(mw+ew);
    end if;
    
    if rabs = 0 then
      so(P_DEC).rsign <= '0';
    else
      so(P_DEC).rsign <= si(P_DEC).op_r(mw+ew);
    end if;

    -- Added: check for NaN
    l := to_float( si(P_DEC).op_l(ew+mw downto 0), ew, mw );
    r := to_float( si(P_DEC).op_r(ew+mw downto 0), ew, mw );
    
    so(P_DEC).ltype <= classfp (l, float_check_error);
    so(P_DEC).rtype <= classfp (r, float_check_error);
    
  end process;
  
  -----------------------------------------------------------------------------
  -- Phase 1 to phase 2 forwarding
  -----------------------------------------------------------------------------
  phase_1_to_2_regs: if L_FCMP1 /= 0 generate
    process (clk) is
    begin
      if rising_edge(clk) then
        if reset = '1' then
          si(P_CMP) <= operationState_init;
        elsif clkEn = '1' and stall = '0' then
          si(P_CMP) <= so(P_DEC);
        end if;
      end if;
    end process;
  end generate;
  
  phase_1_to_2_noregs: if L_FCMP1 = 0 generate
    si(P_CMP) <= so(P_DEC);
  end generate;

  -----------------------------------------------------------------------------
  -- Execute phase 2 (compare)
  -----------------------------------------------------------------------------
  phase_compare: process (si(P_CMP)) is
  
    variable labs, rabs   : unsigned(mw+ew-1 downto 0);
    variable lsign, rsign : std_logic;
    
    variable abseq, absgt : std_logic;
  
  begin
  
    -- Forward by default
    so(P_CMP) <= si(P_CMP);
  
    -- Compare
    labs  := si(P_CMP).labs;
    rabs  := si(P_CMP).rabs;
    lsign := si(P_CMP).lsign;
    rsign := si(P_CMP).rsign;
    
    
    if labs > rabs then
      absgt := '1';
    else
      absgt := '0';
    end if;

    if labs = rabs then
      abseq := '1';
    else
      abseq := '0';
    end if;

    --if( absa = 0 and abseq='1' ) then
    --  so(P_CMP).gt <= '0';
    --  so(P_CMP).eq <= '1';
    --els
    if( lsign = '0' and rsign = '1' ) then
      so(P_CMP).gt <= '1';
      so(P_CMP).eq <= '0';
    elsif( lsign = '1' and rsign = '0' ) then
      so(P_CMP).gt <= '0';
      so(P_CMP).eq <= '0';
    elsif( lsign = '1' and rsign = '1' ) then
      so(P_CMP).gt <= not (absgt or abseq);
      so(P_CMP).eq <= abseq;
    else -- lsign=0, rsign=0
      so(P_CMP).gt <= absgt;
      so(P_CMP).eq <= abseq;
    end if;
  
  end process;

  -----------------------------------------------------------------------------
  -- Phase 2 to phase 3 forwarding
  -----------------------------------------------------------------------------
  phase_2_to_3_regs: if L_FCMP2 /= 0 generate
    process (clk) is
    begin
      if rising_edge(clk) then
        if reset = '1' then
          si(P_RES) <= operationState_init;
        elsif clkEn = '1' and stall = '0' then
          si(P_RES) <= so(P_CMP);
        end if;
      end if;
    end process;
  end generate;
  
  phase_2_to_3_noregs: if L_FCMP2 = 0 generate
    si(P_RES) <= so(P_CMP);
  end generate;

  -----------------------------------------------------------------------------
  -- Execute phase 3 (result)
  -----------------------------------------------------------------------------
  phase_result : process(si(P_RES)) is
  
    variable ltype, rtype : valid_fpstate;
    variable veq, vgt       : std_logic;
  
  begin
  
    -- Forward by default
    so(P_RES) <= si(P_RES);
    
    ltype := si(P_RES).ltype;
    rtype := si(P_RES).rtype;
    veq   := si(P_RES).eq;
    vgt   := si(P_RES).gt;
  
    -- Added: check for NaN
    if (ltype = nan or ltype = quiet_nan or rtype = nan or rtype = quiet_nan) then
      if si(P_RES).opcode = NE then
        so(P_RES).result <= '1';
      else
        so(P_RES).result <= '0';
      end if;
    else
      case si(P_RES).opcode is
        when EQ => so(P_RES).result <= veq;
        when NE => so(P_RES).result <= not veq;
        when LT => so(P_RES).result <= not (veq or vgt);
        when LE => so(P_RES).result <= not vgt;
        when GT => so(P_RES).result <= vgt;
        when GE => so(P_RES).result <= veq or vgt;
        when others  => so(P_RES).result <= '0';
      end case;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- Copy results to outputs
  -----------------------------------------------------------------------------
  fcmp2pl_result(S_FCMP+L_FCMP)   <= (0 => so(P_RES).result, others => '0');
  fcmp2pl_resultBr(S_FCMP+L_FCMP) <= so(P_RES).result;

end architecture;

