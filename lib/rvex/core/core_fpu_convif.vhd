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
-- is copy-pasted from a FU in the included hdb,
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

entity core_fpu_convif is
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
    pl2fcif_opcode              : in  rvex_opcode_array (S_FCIF to S_FCIF);
    
    -- 32-bit operand
    pl2fcif_op                  : in  rvex_data_array(S_FCIF to S_FCIF);

    ---------------------------------------------------------------------------
    -- Outputs
    ---------------------------------------------------------------------------
    -- 32-bit output
    fcif2pl_result              : out rvex_data_array (S_FCIF+L_FCIF to S_FCIF+L_FCIF)
  
  );
end entity;


architecture rtl of core_fpu_convif is

  constant busw : integer := 32;
  constant ew   : integer := 8;
  constant mw   : integer := 23;
  constant intw : integer := 32;  
  
  type operationState_type is record
  
    -- Inputs
    op             : std_logic_vector (busw-1 downto 0);
    conv_u         : std_logic;
    
    -- Intermediates
    op_int         : unsigned (intw downto 0);
    sign           : std_logic;
    exp            : signed (ew-1 downto 0);
    
    -- Outputs
    result         : std_logic_vector (intw-1 downto 0);
  
  end record;
  
  constant operationState_init : operationState_type := (
    op             => (others => '0'),
    conv_u         => '0',
    
    op_int         => (others => '0'),
    sign           => '0',
    exp            => (others => '0'),
    
    result         => (others => '0')
  );
  
  type operationState_array is array (natural range <>) of operationState_type;
  
  -- Execution phases
  constant P_INP                : natural := 1; -- prepare INPuts
  constant P_SHF                : natural := 2; -- SHift Fraction
  constant P_RND                : natural := 3; -- RouND result
  
  constant NUM_PHASES           : natural := P_RND;
  
  -- Internal phase inputs (si) and outputs (so)
  signal si                     : operationState_array(1 to NUM_PHASES) := (others => operationState_init);
  signal so                     : operationState_array(1 to NUM_PHASES) := (others => operationState_init);
  
begin

  -----------------------------------------------------------------------------
  -- Check configuration
  -----------------------------------------------------------------------------
  assert (L_FCIF1 = 0) or (L_FCIF1 = 1)
    report "Latency for FPU_convif phase 1 (L_FCIF1) must be set to 0 or 1 in "
         & "pipeline_pkg.vhd."
    severity failure;
  
  assert (L_FCIF2 = 0) or (L_FCIF2 = 1)
    report "Latency for FPU_convif phase 2 (L_FCIF2) must be set to 0 or 1 in "
         & "pipeline_pkg.vhd."
    severity failure;
  
  assert L_FCIF = L_FCIF1 + L_FCIF2
    report "Total latency for FPU_convif must match sum of phase latencies."
    severity failure;

  -----------------------------------------------------------------------------
  -- Copy inputs to operation state
  -----------------------------------------------------------------------------
  si(P_INP).op     <= pl2fcif_op(S_FCIF);
  si(P_INP).conv_u <= OPCODE_TABLE(vect2uint(pl2fcif_opcode(S_FCIF))).fpuCtrl.unsignedOp;

  -----------------------------------------------------------------------------
  -- Execute phase 1 (input)
  -----------------------------------------------------------------------------
  to_float_conv_stage1 : process(si(P_INP)) is
    variable conv_input : std_logic_vector (intw downto 0);
    variable arg        : SIGNED(intw downto 0);
    variable arg_int    : UNSIGNED(arg'range);  -- Real version of argument
    variable sign       : STD_ULOGIC;         -- sign bit
  begin
    
    -- Forward by default
    so(P_INP) <= si(P_INP);
  
    conv_input(intw-1 downto 0) := si(P_INP).op(intw-1 downto 0);
    
    if si(P_INP).conv_u = '1' then
      conv_input(intw) := '0';
    else
      conv_input(intw) := si(P_INP).op(intw-1);
    end if;
  
    arg := signed( conv_input( intw downto 0 ) );
    -- Normal number (can't be denormal)
    sign := to_X01(arg (arg'high));
    arg_int := UNSIGNED(abs (to_01(arg)));
    
    so(P_INP).sign   <= sign;
    so(P_INP).op_int <= arg_int;
  end process;

  -----------------------------------------------------------------------------
  -- Phase 1 to phase 2 forwarding
  -----------------------------------------------------------------------------
  phase_1_to_2_regs: if L_FCIF1 /= 0 generate
    process (clk) is
    begin
      if rising_edge(clk) then
        if reset = '1' then
          si(P_SHF) <= operationState_init;
        elsif clkEn = '1' and stall = '0' then
          si(P_SHF) <= so(P_INP);
        end if;
      end if;
    end process;
  end generate;
  
  phase_1_to_2_noregs: if L_FCIF1 = 0 generate
    si(P_SHF) <= so(P_INP);
  end generate;

  -----------------------------------------------------------------------------
  -- Execute phase 2 (shift)
  -----------------------------------------------------------------------------
  to_float_conv_stage2 : process(si(P_SHF)) is
    variable arg            : SIGNED(intw downto 0);
    constant round_style    : round_type := float_round_style;
    variable arg_int    : UNSIGNED(arg'range);  -- Real version of argument
    variable argb2      : SIGNED(arg'high/2+1 downto 0);  -- log2 of input
    variable exp        : SIGNED (ew - 1 downto 0);
    variable sign   : STD_ULOGIC;         -- sign bit
  begin
  
    -- Forward by default
    so(P_SHF) <= si(P_SHF);
  
    sign    := si(P_SHF).sign;
    arg_int := si(P_SHF).op_int;
   
    -- Compute Exponent
    argb2 := to_signed(my_find_leftmost(arg_int, '1'), argb2'length);  -- Log2
    
    exp     := SIGNED(resize(argb2, exp'length));
    arg_int := shift_left (arg_int, arg_int'high-to_integer(exp));    
    
    so(P_SHF).exp    <= exp;
    so(P_SHF).sign   <= sign;
    so(P_SHF).op_int <= arg_int;
    
  end process;

  -----------------------------------------------------------------------------
  -- Phase 2 to phase 3 forwarding
  -----------------------------------------------------------------------------
  phase_2_to_3_regs: if L_FCIF2 /= 0 generate
    process (clk) is
    begin
      if rising_edge(clk) then
        if reset = '1' then
          si(P_RND) <= operationState_init;
        elsif clkEn = '1' and stall = '0' then
          si(P_RND) <= so(P_SHF);
        end if;
      end if;
    end process;
  end generate;
  
  phase_2_to_3_noregs: if L_FCIF2 = 0 generate
    si(P_RND) <= so(P_SHF);
  end generate;

  -----------------------------------------------------------------------------
  -- Execute phase 3 (round)
  -----------------------------------------------------------------------------
  to_float_conv_stage3 : process(si(P_RND)) is
    variable arg            : SIGNED(intw downto 0);
    constant round_style    : round_type := float_round_style;
    variable result     : UNRESOLVED_float (ew downto -mw);
    variable arg_int    : UNSIGNED(arg'range);  -- Real version of argument
    variable rexp       : SIGNED (ew - 1 downto 0);
    variable exp        : SIGNED (ew - 1 downto 0);
    -- Signed version of exp.
    variable expon      : UNSIGNED (ew - 1 downto 0);
    -- Unsigned version of exp.
    variable round  : BOOLEAN;
    variable fract  : UNSIGNED (mw-1 downto 0);
    variable rfract : UNSIGNED (mw-1 downto 0);
    variable sign   : STD_ULOGIC;         -- sign bit
    constant remainder_width : INTEGER := intw - mw;
    variable remainder : UNSIGNED( remainder_width-1 downto 0 );
  begin
  
    -- Forward by default
    so(P_RND) <= si(P_RND);
  
    exp     := si(P_RND).exp;
    sign    := si(P_RND).sign;
    arg_int := si(P_RND).op_int;
    
    fract := arg_int (arg_int'high-1 downto (arg_int'high-mw));
    
    round := check_round (
      fract_in    => fract (0),
      sign        => sign,
      remainder   => arg_int((arg_int'high-mw-1)
                             downto 0),
      round_style => round_style);
    if round then
      fp_round(fract_in  => fract,
               expon_in  => exp,
               fract_out => rfract,
               expon_out => rexp);
    else
      rfract := fract;
      rexp   := exp;
    end if;
    
    if (arg_int = 0) then
      result := zerofp (fraction_width => mw,
                        exponent_width => ew);
    else    
      result(ew) := sign;
      expon := UNSIGNED (rexp-1);
      expon(ew-1)            := not expon(ew-1);
      result (ew-1 downto 0) := UNRESOLVED_float(expon);
      result (-1 downto -mw) := UNRESOLVED_float(rfract);
    end if;
    
    so(P_RND).result <= to_slv( result );
  end process to_float_conv_stage3;

  -----------------------------------------------------------------------------
  -- Copy results to outputs
  -----------------------------------------------------------------------------
  fcif2pl_result(S_FCIF+L_FCIF) <= so(P_RND).result;

end architecture;

