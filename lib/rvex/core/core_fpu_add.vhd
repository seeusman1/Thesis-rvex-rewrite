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

entity core_fpu_add is
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
    pl2fadd_opcode              : in  rvex_opcode_array(S_FADD to S_FADD);
    
    -- 32-bit operands
    pl2fadd_opl                 : in  rvex_data_array(S_FADD to S_FADD);
    pl2fadd_opr                 : in  rvex_data_array(S_FADD to S_FADD);
    
    ---------------------------------------------------------------------------
    -- Outputs
    ---------------------------------------------------------------------------
    -- 32-bit output
    fadd2pl_result              : out rvex_data_array(S_FADD+L_FADD to S_FADD+L_FADD)
  
  );
end entity;


architecture rtl of core_fpu_add is

  constant busw                 : integer := 32;
  constant mw                   : integer := 23;
  constant ew                   : integer := 8;
  constant guard_bits           : natural := 3;

  
  type operationState_type is record
  
    -- Inputs
    --op_l                        : unresolved_float(ew downto -mw);
    --op_r                        : unresolved_float(ew downto -mw);
    op_l                        : std_logic_vector (busw-1 downto 0);
    op_r                        : std_logic_vector (busw-1 downto 0);
    
    add_sub                     : fpuAddOp_type;
    
    -- Decode phase
    lsign                       : std_logic;
    lexp                        : signed(ew-1 downto 0);
    lfract                      : unsigned(mw+guard_bits+1 downto 0);
    ltype                       : valid_fpstate;
    
    rsign                       : std_logic;
    rexp                        : signed(ew-1 downto 0);
    rfract                      : unsigned(mw+guard_bits+1 downto 0);
    rtype                       : valid_fpstate;
    
    shiftx                      : signed(ew downto 0);
    
    -- Align phase
    cfract                      : unsigned(mw+guard_bits+1 downto 0);
    sfract                      : unsigned(mw+guard_bits+1 downto 0);
    left_right                  : boolean;
    sticky                      : std_logic;
    
    -- Results
    sign                        : std_logic;
    exp                         : signed(ew downto 0);
    fract                       : unsigned(mw+guard_bits+1 downto 0);
    
    result                      : std_logic_vector(busw-1 downto 0);
  
  end record;
  
  constant operationState_init : operationState_type := (
    op_l                        => (others => '0'),
    op_r                        => (others => '0'),
    add_sub                     => ADD,
    
    lsign                       => '0',
    lexp                        => (others => '0'),
    lfract                      => (others => '0'),
    ltype                       => nan,
    rsign                       => '0',
    rexp                        => (others => '0'),
    rfract                      => (others => '0'),
    rtype                       => nan,
    shiftx                      => (others => '0'),
    
    cfract                      => (others => '0'),
    sfract                      => (others => '0'),
    left_right                  => false,
    sticky                      => '0',
    
    sign                        => '0',
    exp                         => (others => '0'),
    fract                       => (others => '0'),
    result                      => (others => '0')
  );
  
  type operationState_array is array (natural range <>) of operationState_type;
  
  
  -- Execution phases
  constant P_DEC                : natural := 1; -- DECode inputs
  constant P_ALN                : natural := 2; -- ALigN inputs
  constant P_ADD                : natural := 3; -- ADD fractions
  constant P_NRM                : natural := 4; -- NoRMalize result
  
  constant NUM_PHASES           : natural := P_NRM;
  
  -- Internal phase inputs (si) and outputs (so)
  signal si                     : operationState_array(1 to NUM_PHASES) := (others => operationState_init);
  signal so                     : operationState_array(1 to NUM_PHASES) := (others => operationState_init);
  
begin

  -----------------------------------------------------------------------------
  -- Check configuration
  -----------------------------------------------------------------------------
  assert (L_FADD1 = 0) or (L_FADD1 = 1)
    report "Latency for FPU_add phase 1 (L_FADD1) must be set to 0 or 1 in "
         & "pipeline_pkg.vhd."
    severity failure;
  
  assert (L_FADD2 = 0) or (L_FADD2 = 1)
    report "Latency for FPU_add phase 2 (L_FADD2) must be set to 0 or 1 in "
         & "pipeline_pkg.vhd."
    severity failure;
    
  assert (L_FADD3 = 0) or (L_FADD3 = 1)
    report "Latency for FPU_add phase 3 (L_FADD3) must be set to 0 or 1 in "
         & "pipeline_pkg.vhd."
    severity failure;
  
  assert L_FADD = L_FADD1 + L_FADD2 + L_FADD3
    report "Total latency for FPU_add must match sum of phase latencies."
    severity failure;

  -----------------------------------------------------------------------------
  -- Copy inputs to operation state
  -----------------------------------------------------------------------------
  --si(P_DEC).op_l    <= to_float( pl2fadd_opl(S_FADD)(ew+mw downto 0), ew, mw );
  --si(P_DEC).op_r    <= to_float( pl2fadd_opr(S_FADD)(ew+mw downto 0), ew, mw );
  si(P_DEC).op_l    <= pl2fadd_opl(S_FADD);
  si(P_DEC).op_r    <= pl2fadd_opr(S_FADD);
  si(P_DEC).add_sub <= OPCODE_TABLE(vect2uint(pl2fadd_opcode(S_FADD))).fpuCtrl.addOp;
  
  -----------------------------------------------------------------------------
  -- Execute phase 1 (decode)
  -----------------------------------------------------------------------------  
  add_phase1 : process (si(P_DEC))
    variable l, r             : UNRESOLVED_float(ew downto -mw);  -- inputs
    variable lfptype, rfptype : valid_fpstate;
    variable fractl, fractr   : UNSIGNED (mw+guard_bits+1 downto 0);  -- fractions
    variable urfract, ulfract : UNSIGNED (mw downto 0);
    variable exponl, exponr   : SIGNED (ew-1 downto 0);  -- exponents
    variable lresize, rresize : UNRESOLVED_float (ew downto -mw);
  begin  -- addition
  
    -- Forward by default
    so(P_DEC) <= si(P_DEC);
    
    -- Decode inputs
    l := to_float(si(P_DEC).op_l(ew+mw downto 0), ew, mw);
    r := to_float(si(P_DEC).op_r(ew+mw downto 0), ew, mw);
    
    if (si(P_DEC).add_sub = SUB) then
      r(r'high) := not r(r'high);
    end if;

    lfptype := classfp(l);
    rfptype := classfp(r);
      
    lresize := resize(arg => to_x01(l));
    rresize := resize(arg => to_x01(r));
    
    break_number (
      arg         => lresize,
      fptyp       => lfptype,
      fract       => ulfract,
      expon       => exponl
    );
    fractl := (others => '0');
    fractl (mw+guard_bits downto guard_bits) := ulfract;
    
    break_number (
      arg         => rresize,
      fptyp       => rfptype,
      fract       => urfract,
      expon       => exponr
    );
    fractr := (others => '0');
    fractr(mw+guard_bits downto guard_bits) := urfract;
		
		-- To next stage
    so(P_DEC).shiftx <= (exponl(ew-1) & exponl) - exponr;
    
    so(P_DEC).lsign  <= l(l'high);
    so(P_DEC).lexp   <= exponl;
    so(P_DEC).lfract <= fractl;
    so(P_DEC).ltype  <= lfptype;
    
    so(P_DEC).rsign  <= r(r'high);
    so(P_DEC).rexp   <= exponr;
    so(P_DEC).rfract <= fractr;
    so(P_DEC).rtype  <= rfptype;
    
  end process;
  
  -----------------------------------------------------------------------------
  -- Phase 1 to phase 2 forwarding
  -----------------------------------------------------------------------------
  phase_1_to_2_regs: if L_FADD1 /= 0 generate
    process (clk) is
    begin
      if rising_edge(clk) then
        if reset = '1' then
          si(P_ALN) <= operationState_init;
        elsif clkEn = '1' and stall = '0' then
          si(P_ALN) <= so(P_DEC);
        end if;
      end if;
    end process;
  end generate;
  
  phase_1_to_2_noregs: if L_FADD1 = 0 generate
    si(P_ALN) <= so(P_DEC);
  end generate;
  
  -----------------------------------------------------------------------------
  -- Execute phase 2 (align)
  -----------------------------------------------------------------------------
  add_phase2 : process(si(P_ALN))
    variable fractl, fractr   : unsigned(mw+guard_bits+1 downto 0);  -- fractions
    variable fractc, fracts   : unsigned(mw+guard_bits+1 downto 0);  -- constant and shifted variables
    variable exponl, exponr   : SIGNED (ew-1 downto 0);  -- exponents
    variable rexpon           : SIGNED (ew downto 0);  -- result exponent
    variable shiftx           : SIGNED (ew downto 0);  -- shift fractions
    variable leftright        : BOOLEAN;      -- left or right used
    variable sticky           : STD_LOGIC;   -- Holds precision for rounding
  begin
    
    -- Forward by default
    so(P_ALN) <= si(P_ALN);
    
    
    shiftx  := si(P_ALN).shiftx;
    
    exponl  := si(P_ALN).lexp;
    fractl  := si(P_ALN).lfract;
    
    exponr  := si(P_ALN).rexp;
    fractr  := si(P_ALN).rfract;
    
    
    fractc := (others=>'0');
    fracts := (others=>'0');
    rexpon := (others=>'0');
    fracts := (others=>'0');
    sticky := '0';
    leftright := False;
    
    if shiftx < -fractl'high then
      rexpon    := exponr(ew-1) & exponr;
      fractc    := fractr;
      fracts    := (others => '0');   -- add zero
      leftright := false;
      sticky    := or_reduce (fractl);
    elsif shiftx < 0 then
      shiftx    := - shiftx;
      fracts    := shift_right (fractl, to_integer(shiftx));
      fractc    := fractr;
      rexpon    := exponr(ew-1) & exponr;
      leftright := false;
      sticky    := smallfract (fractl, to_integer(shiftx));
    elsif shiftx = 0 then
      rexpon := exponl(ew-1) & exponl;
      sticky := '0';
      if fractr > fractl then
        fractc    := fractr;
        fracts    := fractl;
        leftright := false;
      else
        fractc    := fractl;
        fracts    := fractr;
        leftright := true;
      end if;
    elsif shiftx > fractr'high then
      rexpon    := exponl(ew-1) & exponl;
      fracts    := (others => '0');   -- add zero
      fractc    := fractl;
      leftright := true;
      sticky    := or_reduce (fractr);
    elsif shiftx > 0 then
      fracts    := shift_right (fractr, to_integer(shiftx));
      fractc    := fractl;
      rexpon    := exponl(ew-1) & exponl;
      leftright := true;
      sticky    := smallfract (fractr, to_integer(shiftx));
    end if;
    
    -- Outputs
    so(P_ALN).cfract     <= fractc;
    so(P_ALN).sfract     <= fracts;
    so(P_ALN).left_right <= leftright;
    so(P_ALN).exp        <= rexpon;
    so(P_ALN).sticky     <= sticky;
    
  end process;
  
  -----------------------------------------------------------------------------
  -- Phase 2 to phase 3 forwarding
  -----------------------------------------------------------------------------
  phase_2_to_3_regs: if L_FADD2 /= 0 generate
    process (clk) is
    begin
      if rising_edge(clk) then
        if reset = '1' then
          si(P_ADD) <= operationState_init;
        elsif clkEn = '1' and stall = '0' then
          si(P_ADD) <= so(P_ALN);
        end if;
      end if;
    end process;
  end generate;
  
  phase_2_to_3_noregs: if L_FADD2 = 0 generate
    si(P_ADD) <= so(P_ALN);
  end generate;
  
  -----------------------------------------------------------------------------
  -- Execute phase 3 (add)
  -----------------------------------------------------------------------------
  add_phase3 : process(si(P_ADD))
    variable fractc, fracts   : unsigned(mw+guard_bits+1 downto 0);  -- constant and shifted variables
    variable ufract           : unsigned(mw+guard_bits+1 downto 0);
    variable lsign, rsign     : STD_ULOGIC;   -- sign of the output
    variable sign             : STD_ULOGIC;   -- sign of the output
    variable leftright        : BOOLEAN;      -- left or right used
    variable sticky           : STD_ULOGIC;   -- Holds precision for rounding
  begin
  
    -- Forward by default
    so(P_ADD) <= si(P_ADD);
    
  
    fractc    := si(P_ADD).cfract;
    fracts    := si(P_ADD).sfract;
    leftright := si(P_ADD).left_right;
    lsign     := si(P_ADD).lsign;
    rsign     := si(P_ADD).rsign;
    sticky    := si(P_ADD).sticky;
    
    -- Add
    fracts (0) := fracts (0) or sticky;     -- Or the sticky bit into the LSB
    if lsign = rsign then
      ufract := fractc + fracts;
      sign   := lsign; --l(l'high);
    else                              -- signs are different
      ufract := fractc - fracts;      -- always positive result
      if leftright then               -- Figure out which sign to use
        sign := lsign; --l(l'high);
      else
        sign := rsign; --r(r'high);
      end if;
    end if;
    if or_reduce (ufract) = '0' then
      sign := '0';                    -- IEEE 854, 6.3, paragraph 2.
    end if;
    
    -- Outputs
    so(P_ADD).fract <= ufract;
    so(P_ADD).sign  <= sign;
  
  end process;
  
  -----------------------------------------------------------------------------
  -- Phase 3 to phase 4 forwarding
  -----------------------------------------------------------------------------
  phase_3_to_4_regs: if L_FADD3 /= 0 generate
    process (clk) is
    begin
      if rising_edge(clk) then
        if reset = '1' then
          si(P_NRM) <= operationState_init;
        elsif clkEn = '1' and stall = '0' then
          si(P_NRM) <= so(P_ADD);
        end if;
      end if;
    end process;
  end generate;
  
  phase_3_to_4_noregs: if L_FADD3 = 0 generate
    si(P_NRM) <= so(P_ADD);
  end generate;
  
  -----------------------------------------------------------------------------
  -- Execute phase 4 (normalize)
  -----------------------------------------------------------------------------
  ADD_STAGE4 : process(si(P_NRM))
    variable lfptype, rfptype : valid_fpstate;
    variable ufract           : unsigned(mw+guard_bits+1 downto 0);
    variable rexpon           : SIGNED (ew downto 0);  -- result exponent
    variable sign             : STD_ULOGIC;   -- sign of the output
    variable sticky           : STD_ULOGIC;   -- Holds precision for rounding
    variable fpresult         : UNRESOLVED_float (ew downto -mw);
  begin
  
    -- Forward by default
    so(P_NRM) <= si(P_NRM);
  
    -- Normalize
    lfptype := si(P_NRM).ltype;
    rfptype := si(P_NRM).rtype;
    ufract  := si(P_NRM).fract;
    rexpon  := si(P_NRM).exp;
    sign    := si(P_NRM).sign;
    sticky  := si(P_NRM).sticky;
    
    if (lfptype = isx or rfptype = isx) then
      fpresult := (others => 'X');
    elsif (lfptype = nan or lfptype = quiet_nan or
           rfptype = nan or rfptype = quiet_nan)
      -- Return quiet NAN, IEEE754-1985-7.1,1
      or (lfptype = pos_inf and rfptype = neg_inf)
      or (lfptype = neg_inf and rfptype = pos_inf) then
      -- Return quiet NAN, IEEE754-1985-7.1,2
      fpresult := qnanfp;
    elsif (lfptype = pos_inf or rfptype = pos_inf) then   -- x + inf = inf
      fpresult := pos_inffp;
    elsif (lfptype = neg_inf or rfptype = neg_inf) then   -- x - inf = -inf
      fpresult := neg_inffp;
    elsif (lfptype = neg_zero and rfptype = neg_zero) then   -- -0 + -0 = -0
      fpresult := neg_zerofp;
    else
      
    fpresult := normalize (fract          => ufract,
                           expon          => rexpon,
                           sign           => sign,
                           sticky         => sticky);
                           
    end if;
    
    --return fpresult;
    so(P_NRM).result                 <= (others => '0');
    so(P_NRM).result(ew+mw downto 0) <= to_slv(fpresult);
  end process;
  
  -----------------------------------------------------------------------------
  -- Copy results to outputs
  -----------------------------------------------------------------------------
  fadd2pl_result(S_FADD+L_FADD) <= so(P_NRM).result;

end architecture;


