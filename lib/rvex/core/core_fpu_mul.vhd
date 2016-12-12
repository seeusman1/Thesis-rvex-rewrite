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


use STD.TEXTIO.all;
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library work;
use work.fixed_float_types.all;
use work.fixed_pkg.all;
use work.float_pkg.all;

use work.rvex.all;

entity core_fpu_mul is
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
    -- Operand inputs
    ---------------------------------------------------------------------------
    -- 32-bit operands
    pl2fmul_opl                 : in  rvex_data_array(S_FMUL to S_FMUL);
    pl2fmul_opr                 : in  rvex_data_array(S_FMUL to S_FMUL);

    ---------------------------------------------------------------------------
    -- Outputs
    ---------------------------------------------------------------------------
    -- 32-bit output
    fmul2pl_result              : out rvex_data_array(S_FMUL+L_FMUL to S_FMUL+L_FMUL)
    );
end entity;


architecture rtl of core_fpu_mul is

  constant busw                 : integer := 32;
  constant ew                   : integer := 8;
  constant mw                   : integer := 23;
  constant guard_bits           : natural := 23;
  
  
  type operationState_type is record

    -- Operands
    --op_l                        : unresolved_float(ew downto -mw);
    --op_r                        : unresolved_float(ew downto -mw);
    op_l                        : std_logic_vector (busw-1 downto 0);
    op_r                        : std_logic_vector (busw-1 downto 0);
    lfract                      : unsigned (mw downto 0);
    rfract                      : unsigned (mw downto 0);
    ltype                       : valid_fpstate;
    rtype                       : valid_fpstate;

    -- Intermediates
    xor_sign                    : std_logic;
    add_exp                     : signed (ew+1 downto 0);
    mul_fract                   : unsigned (2*mw+1 downto 0);

    sel_fract                   : unsigned (mw+1+guard_bits downto 0);
    sticky                      : std_logic;

    -- Results
    result_slv                  : std_logic_vector (busw-1 downto 0);

  end record;
  
  constant operationState_init : operationState_type := (
    op_l                        => (others => '0'),
    op_r                        => (others => '0'),
    lfract                      => (others => '0'),
    rfract                      => (others => '0'),
    ltype                       => nan,
    rtype                       => nan,
    
    xor_sign                    => '0',
    add_exp                     => (others => '0'),
    mul_fract                   => (others => '0'),
    
    sel_fract                   => (others => '0'),
    sticky                      => '0',
    
    result_slv                  => (others => '0')
  );
  
  type operationState_array is array (natural range <>) of operationState_type;
  
  -- Execution phases
  constant P_DEC                : natural := 1; -- DECode inputs, xor sign, add exponents
  constant P_MUL                : natural := 2; -- MULtiply fractions
  constant P_SEL                : natural := 3; -- SELect fractional part
  constant P_NRM                : natural := 4; -- NoRMalize result
  
  constant NUM_PHASES           : natural := P_NRM;
  
  -- Internal phase inputs (si) and outputs (so)
  signal si                     : operationState_array(1 to NUM_PHASES) := (others => operationState_init);
  signal so                     : operationState_array(1 to NUM_PHASES) := (others => operationState_init);

begin

  -----------------------------------------------------------------------------
  -- Check configuration
  -----------------------------------------------------------------------------
  assert (L_FMUL1 = 0) or (L_FMUL1 = 1)
    report "Latency for FPU_mul phase 1 (L_FMUL1) must be set to 0 or 1 in "
         & "pipeline_pkg.vhd."
    severity failure;
  
  assert (L_FMUL2 = 0) or (L_FMUL2 = 1)
    report "Latency for FPU_mul phase 2 (L_FMUL2) must be set to 0 or 1 in "
         & "pipeline_pkg.vhd."
    severity failure;
    
  assert (L_FMUL3 = 0) or (L_FMUL3 = 1)
    report "Latency for FPU_mul phase 3 (L_FMUL3) must be set to 0 or 1 in "
         & "pipeline_pkg.vhd."
    severity failure;
  
  assert L_FMUL = L_FMUL1 + L_FMUL2 + L_FMUL3
    report "Total latency for FPU_mul must match sum of phase latencies."
    severity failure;

  -----------------------------------------------------------------------------
  -- Copy inputs to operation state
  -----------------------------------------------------------------------------
  --si(P_DEC).op_l    <= to_float( pl2fmul_opl(S_FMUL)(ew+mw downto 0), ew, mw );
  --si(P_DEC).op_r    <= to_float( pl2fmul_opr(S_FMUL)(ew+mw downto 0), ew, mw );
  si(P_DEC).op_l    <= pl2fmul_opl(S_FMUL);
  si(P_DEC).op_r    <= pl2fmul_opr(S_FMUL);

  -----------------------------------------------------------------------------
  -- Execute phase 1 (decode)
  -----------------------------------------------------------------------------
  multiply: process (si(P_DEC)) is
  
    variable l, r               : unresolved_float (ew downto -mw);
  
    variable lfptype, rfptype : valid_fpstate;
    variable fractl, fractr   : UNSIGNED (mw downto 0);  -- fractions
    variable exponl, exponr   : SIGNED (ew-1 downto 0);  -- exponents
    variable fp_sign          : STD_ULOGIC;   -- sign of result
    
  begin 
  
    -- Forward by default
    so(P_DEC) <= si(P_DEC);
  
    -- Left and right operands
    l := to_float(si(P_DEC).op_l(ew+mw downto 0), ew, mw);
    r := to_float(si(P_DEC).op_r(ew+mw downto 0), ew, mw);
  
    -- Decode operands
    lfptype := classfp (l, float_check_error);
    rfptype := classfp (r, float_check_error);
    fp_sign := l(l'high) xor r(r'high);     -- figure out the sign

    break_number (
      arg         => l, --lresize,
      fptyp       => lfptype,
      denormalize => float_denormalize,
      fract       => fractl,
      expon       => exponl);
    break_number (
      arg         => r, --rresize,
      fptyp       => rfptype,
      denormalize => float_denormalize,
      fract       => fractr,
      expon       => exponr);

    -- TODO tarvitsevatko muut fpu:t tällaisen?
--    if (rfptype = pos_denormal) then
--      rfptype := pos_zero;
--    elsif (rfptype = neg_denormal) then
--      rfptype := neg_zero;
--    end if;
--    if (lfptype = pos_denormal) then
--      lfptype := pos_zero;
--    elsif (lfptype = neg_denormal) then
--      lfptype := neg_zero;
--    end if;
    
    -- Add the exponents
    so(P_DEC).add_exp  <= resize (exponl, ew+2) + exponr + 1;
    
    -- Outputs
    so(P_DEC).lfract   <= fractl;
    so(P_DEC).rfract   <= fractr;
    so(P_DEC).xor_sign <= fp_sign;
    so(P_DEC).ltype    <= lfptype;
    so(P_DEC).rtype    <= rfptype;

  end process multiply;
  
  -----------------------------------------------------------------------------
  -- Phase 1 to phase 2 forwarding
  -----------------------------------------------------------------------------
  phase_1_to_2_regs: if L_FMUL1 /= 0 generate
    process (clk) is
    begin
      if rising_edge(clk) then
        if reset = '1' then
          si(P_MUL) <= operationState_init;
        elsif clkEn = '1' and stall = '0' then
          si(P_MUL) <= so(P_DEC);
        end if;
      end if;
    end process;
  end generate;
  
  phase_1_to_2_noregs: if L_FMUL1 = 0 generate
    si(P_MUL) <= so(P_DEC);
  end generate;
  
  -----------------------------------------------------------------------------
  -- Execute phase 2 (multiply)
  -----------------------------------------------------------------------------
  multiply_stage2: process (si(P_MUL)) is    
  begin

    -- Forward by default
    so(P_MUL) <= si(P_MUL);

    -- Multiply fractions
    so(P_MUL).mul_fract <= si(P_MUL).lfract * si(P_MUL).rfract;

  end process multiply_stage2;

  -----------------------------------------------------------------------------
  -- Phase 2 to phase 3 forwarding
  -----------------------------------------------------------------------------
  phase_2_to_3_regs: if L_FMUL2 /= 0 generate
    process (clk) is
    begin
      if rising_edge(clk) then
        if reset = '1' then
          si(P_SEL) <= operationState_init;
        elsif clkEn = '1' and stall = '0' then
          si(P_SEL) <= so(P_MUL);
        end if;
      end if;
    end process;
  end generate;
  
  phase_2_to_3_noregs: if L_FMUL2 = 0 generate
    si(P_SEL) <= so(P_MUL);
  end generate;

  -----------------------------------------------------------------------------
  -- Execute phase 3 (select)
  -----------------------------------------------------------------------------
  multiply_stage3: process(si(P_SEL)) is
  
    variable rfract           : UNSIGNED ((2*mw)+1 downto 0);  -- result fraction
    variable sfract           : UNSIGNED (mw + guard_bits + 1 downto 0);  -- result fraction
    variable sticky           : STD_ULOGIC := '0';   -- Holds precision for rounding
    
  begin
  
    -- Forward by default
    so(P_SEL) <= si(P_SEL);
    
    -- Multiply result
		rfract := si(P_SEL).mul_fract;
  
    -- Select fraction and or-reduce remaining bits
    sfract := rfract (rfract'high downto rfract'high - (mw + guard_bits + 1));
    sticky := or_reduce (rfract (rfract'high - (mw + guard_bits + 1) downto 0));
  
    -- Outputs
    so(P_SEL).sel_fract <= sfract;
    so(P_SEL).sticky    <= sticky;

  end process multiply_stage3;
	
  -----------------------------------------------------------------------------
  -- Phase 3 to phase 4 forwarding
  -----------------------------------------------------------------------------
  phase_3_to_4_regs: if L_FMUL3 /= 0 generate
    process (clk) is
    begin
      if rising_edge(clk) then
        if reset = '1' then
          si(P_NRM) <= operationState_init;
        elsif clkEn = '1' and stall = '0' then
          si(P_NRM) <= so(P_SEL);
        end if;
      end if;
    end process;
  end generate;
  
  phase_3_to_4_noregs: if L_FMUL3 = 0 generate
    si(P_NRM) <= so(P_SEL);
  end generate;
  
  -----------------------------------------------------------------------------
  -- Execute phase 4 (normalize)
  -----------------------------------------------------------------------------
  multiply_stage4: process(si(P_NRM)) is
  
    --variable l, r             : unresolved_float (ew downto -mw);
    variable lfptype, rfptype : valid_fpstate;
    variable fpresult         : UNRESOLVED_float (ew downto -mw);
    --variable rfract           : UNSIGNED ((2*mw)+1 downto 0);  -- result fraction
    variable sfract           : UNSIGNED (mw + guard_bits + 1 downto 0);  -- result fraction
    variable rexpon           : SIGNED (ew+1 downto 0);  -- result exponent
    variable fp_sign          : STD_ULOGIC;   -- sign of result
    variable sticky           : STD_ULOGIC := '0';   -- Holds precision for rounding

  begin

    -- Forward by default
    so(P_NRM) <= si(P_NRM);


    sfract  := si(P_NRM).sel_fract;
    rexpon  := si(P_NRM).add_exp;
    fp_sign := si(P_NRM).xor_sign;
    sticky  := si(P_NRM).sticky;
    lfptype := si(P_NRM).ltype;
    rfptype := si(P_NRM).rtype;
    
    
    if (lfptype = isx or rfptype = isx) then
      fpresult := (others => 'X');
      
    elsif ((lfptype = nan or lfptype = quiet_nan or
            rfptype = nan or rfptype = quiet_nan)) then
      -- Return quiet NAN, IEEE754-1985-7.1,1
      fpresult := qnanfp (fraction_width => mw,
                          exponent_width => ew);
                          
    elsif (((lfptype = pos_inf or lfptype = neg_inf) and
            (rfptype = pos_zero or rfptype = neg_zero)) or
           ((rfptype = pos_inf or rfptype = neg_inf) and
            (lfptype = pos_zero or lfptype = neg_zero))) then    -- 0 * inf
      -- Return quiet NAN, IEEE754-1985-7.1,3
      fpresult := qnanfp (fraction_width => mw,
                          exponent_width => ew);
                          
    elsif (lfptype = pos_inf or rfptype = pos_inf
           or lfptype = neg_inf or rfptype = neg_inf) then  -- x * inf = inf
      fpresult := pos_inffp (fraction_width => mw,
                             exponent_width => ew);
      fpresult (ew) := fp_sign;

    else
    
      fpresult := normalize (fract          => sfract,
                             expon          => rexpon,
                             sign           => fp_sign,
                             sticky         => sticky,
                             fraction_width => mw,
                             exponent_width => ew,
                             round_style    => float_round_style,
                             denormalize    => float_denormalize,
                             nguard         => guard_bits);
    end if;
    
    if mw+ew+1 < busw  then
      so(P_NRM).result_slv(busw-1 downto mw+ew+1) <= (others=>'0');
    end if;

    so(P_NRM).result_slv <= to_slv(fpresult);
    
  end process multiply_stage4;

  -----------------------------------------------------------------------------
  -- Copy results to outputs
  -----------------------------------------------------------------------------
  fmul2pl_result(S_FMUL+L_FMUL) <= so(P_NRM).result_slv;

end architecture;


