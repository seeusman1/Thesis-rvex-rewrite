-- r-VEX processor
-- Copyright (C) 2008-2015 by TU Delft.
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

-- Copyright (C) 2008-2015 by TU Delft.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library rvex;
use rvex.common_pkg.all;
use rvex.core_pkg.all;
use rvex.utils_pkg.all;

library gaisler;
use gaisler.leon3.all;

--=============================================================================
-- This entity is designed such that it can be used in place of the LEON3 core
-- from grlib.
-------------------------------------------------------------------------------
entity irq_rctrl_bridge is
  generic (
    
    -- Configuration vector.
    CFG                         : rvex_generic_config_type := rvex_cfg
    
  );
  port (

    ---------------------------------------------------------------------------
    -- Run control interface
    ---------------------------------------------------------------------------
    rctrl2rv                    : out rvex_rctrl2rv_array(2**CFG.numContextsLog2-1 downto 0);
    rv2rctrl                    : in  rvex_rv2rctrl_array(2**CFG.numContextsLog2-1 downto 0);

    -- Interrupt controller interface. This entity handles translation from the
    -- LEON3 interrupt controller to the rvex interrupt control signals. Note
    -- that each rvex context requires its own interrupt controller.
    irqi                        : in  irq_in_vector(0 to 2**CFG.numContextsLog2-1);
    irqo                        : out irq_out_vector(0 to 2**CFG.numContextsLog2-1)
    
  );
end irq_rctrl_bridge;
    
--=============================================================================
architecture Behavioral of irq_rctrl_bridge is
--=============================================================================
  
  
--=============================================================================
begin -- architecture
--=============================================================================

  -----------------------------------------------------------------------------
  -- Interrupt controller bridge
  -----------------------------------------------------------------------------
  irq_bridge_gen: for ctxt in 2**CFG.numContextsLog2-1 downto 0 generate
    
    -- Because the rvex does not have an interrupt level register, we always
    -- accept any incoming interrupt when the interrupt enable flag is set.
    -- This means interrupts can nest just fine, but it's all or nothing. Note
    -- that the other run control signals are also connected to the interrupt
    -- controller appropriately, except for the run signal. The default
    -- interrupt controller seems to have run hardwired such that only
    -- processor 0 is ever enabled, so it wouldn't make much sense to connect
    -- it.
    rctrl2rv(ctxt).irq        <= '0' when irqi(ctxt).irl = "0000" else '1';
    rctrl2rv(ctxt).irqID      <= X"0000000" & irqi(ctxt).irl;
    rctrl2rv(ctxt).run        <= '1'; --irqi(ctxt).run;
    rctrl2rv(ctxt).reset      <= irqi(ctxt).rst or irqi(ctxt).hrdrst;
    rctrl2rv(ctxt).resetVect  <= irqi(ctxt).rstvec & X"000";
    irqo(ctxt).intack         <= rv2rctrl(ctxt).irqAck;
    irqo(ctxt).irl            <= irqi(ctxt).irl;
    irqo(ctxt).pwd            <= '0';
    irqo(ctxt).fpen           <= '0';
    irqo(ctxt).idle           <= rv2rctrl(ctxt).idle;
    
  end generate;

end Behavioral;

