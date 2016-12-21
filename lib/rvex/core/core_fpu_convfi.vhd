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

entity core_fpu_convfi is
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
    pl2fcfi_opcode              : in  rvex_opcode_array(S_FCFI to S_FCFI);
    
    -- 32-bit operand
    pl2fcfi_op                  : in  rvex_data_array(S_FCFI to S_FCFI);

    ---------------------------------------------------------------------------
    -- Outputs
    ---------------------------------------------------------------------------
    -- 32-bit output
    fcfi2pl_result              : out rvex_data_array(S_FCFI to S_FCFI)
  
  );
end entity;


architecture rtl of core_fpu_convfi is

  constant busw : integer := 32;
  constant ew   : integer := 8;
  constant mw   : integer := 23;
  constant intw : integer := 32;
  
  type operationState_type is record
  
    -- Inputs
    op                          : std_logic_vector(busw-1 downto 0);
    conv_u                      : std_logic;
    
    -- Outputs
    result                      : std_logic_vector(intw-1 downto 0);
  
  end record;
  
  constant operationState_init : operationState_type := (
    op                          => (others => '0'),
    conv_u                      => '0',
    result                      => (others => '0')
  );
  
  type operationState_array is array (natural range <>) of operationState_type;
  
  -- Execution phases
  constant P_F2I                : natural := 1;
  
  constant NUM_PHASES           : natural := P_F2I;
  
  -- Internal phase inputs (si) and outputs (so)
  signal si                     : operationState_array(1 to NUM_PHASES) := (others => operationState_init);
  signal so                     : operationState_array(1 to NUM_PHASES) := (others => operationState_init);
  
begin

  -----------------------------------------------------------------------------
  -- Copy inputs to operation state
  -----------------------------------------------------------------------------
  si(P_F2I).op     <= pl2fcfi_op(S_FCFI);
  si(P_F2I).conv_u <= OPCODE_TABLE(vect2uint(pl2fcfi_opcode(S_FCFI))).fpuCtrl.unsignedOp;
  
  -----------------------------------------------------------------------------
  -- Execute phase 1 (convert float to int)
  -----------------------------------------------------------------------------
  conv_to_int: process(si(P_F2I)) is
  
    variable op_slv            : std_logic_vector(busw-1 downto 0);
    variable trunc_result_temp : std_logic_vector(intw downto 0);
    variable trunc_result      : std_logic_vector (intw-1 downto 0);
    
  begin
    
    op_slv := si(P_F2I).op;
  
    -- CFIU: output zero for negative inputs
    if( op_slv( op_slv'high ) = '1' and si(P_F2I).conv_u = '1' ) then
      trunc_result_temp := (others=>'0');
    else
      trunc_result_temp := std_logic_vector(to_signed(to_float(op_slv(ew+mw downto 0),ew,mw), intw+1, float_round_style, false));
    end if;
    
    -- Added: correct max/min conversion for signed
    if si(P_F2I).conv_u = '1' then
      trunc_result := trunc_result_temp( intw-1 downto 0 );
    else
      if trunc_result_temp(intw downto intw-1) = "01" then
        trunc_result := ('0', others => '1');
      elsif trunc_result_temp(intw downto intw-1) = "10" then
        trunc_result := ('1', others => '0');
      else
        trunc_result := trunc_result_temp(intw) & trunc_result_temp( intw-2 downto 0 );
      end if;
    end if;
    
    so(P_F2I).result <= trunc_result;
  end process;

  -----------------------------------------------------------------------------
  -- Copy results to outputs
  -----------------------------------------------------------------------------
  fcfi2pl_result(S_FCFI) <= so(P_F2I).result;

end architecture;

