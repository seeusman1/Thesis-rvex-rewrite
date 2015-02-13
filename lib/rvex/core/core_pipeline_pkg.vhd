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

--=============================================================================
-- This package configures the pipeline used by the rvex.
-------------------------------------------------------------------------------
package core_pipeline_pkg is
--=============================================================================
  
  -----------------------------------------------------------------------------
  -- Pipeline diagram
  -----------------------------------------------------------------------------
  -- The figure below shows the pipeline diagram and forwarding logic of the
  -- rvex processor. Pipeline flushing due to exceptions and limmh forwarding
  -- is not shown. Timing within the stages is approximate.
  --
  -- . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
  --
  --              clk        clk        clk        clk        clk
  --    :----S1----:----S2----:----S3----:----S4----:----S5----:----S6----:
  --    :    .---------..----.:      .-------..---------.   .-----.       :
  --    :    |  IMEM   ||Btgt|:      |  ALU  ||  DMEM   |   |Reg. |       :
  --    :    '---------''----':      '-------''---------'   |write|       :
  --    :    .----.:       .-----.   .------------------.   '-----'       :
  --    :    |PC+1|:       |Reg. |   |   :   MUL    :   |      :          :
  --    :    '----':       |read |   '------------------'      :          :
  --    :          :       '-----'       :    .---. :          :          :
  --    :          :    .-..-.:          :    |BRK| :          :          :
  --    :          :    |s||l|:          :    '---' :          :          :
  --    :          :    |t||i|:          :          :          :          :
  --    :          :    |o||m|:          :          :          :          :
  --    :          :    |p||m|:          :          :          :          :
  --    :          :    '-''-':          :          :          :          :
  --    '----S1----'----S2----'----S3----'----S4----'----S5----'----S6----'
  --         ^           |      |   ^        |          |          |*
  --         |           v      v   |        v          v          v
  --        .--------------------. .--------------------------------.
  --        |    Branch unit     | |General purpose reg. forwarding |
  --        '--------------------' '--------------------------------'
  --     ----S1---- ----S2---- ----S3---- ----S4---- ----S5---- ----S6----
  --                         ^    ^         |          |      |
  --                         |    |         v          v      |
  --                         |   .----------------------.     |
  --                         |   |Branch & link forward.|     |
  --                         |   '----------------------'     |
  --                         |                                |
  --                         '--------------------------------'
  --                                  Trap forwarding
  --
  -- * The register file is implemented using dual port RAM blocks. These
  --   blocks do not have consistent read-while-write behavior between the two
  --   ports. By extending the forwarding logic by one stage, such accesses are
  --   prevented (at least, their result is ignored).
  --
  -----------------------------------------------------------------------------
  -- Pipeline definitions
  -----------------------------------------------------------------------------
  -- It should be possible to change what happens in which pipeline stage
  -- without breaking things, as long as the order is not changed and block
  -- latencies and dependencies are respected. Kind request to keep the diagram
  -- above up-to-date!
  --
  -- The S_<block> definitions map to the first stage of a block. The L_<block>
  -- definitions determine the latency of a block, i.e., how many stages later
  -- the results of a block are expected to be valid.

  -- The first pipeline stage.
  -- Requirements:
  --  - S_FIRST = 1
  constant S_FIRST  : natural := 1;
  
  -- Instruction fetch block stage and latency. The latency should be set to 1,
  -- as the instruction buffer will hide the fetch latency from the pipelanes.
  -- Requirements:
  --  - S_IF >= 1
  --  - L_IF = 1
  constant S_IF     : natural := 1;
  constant L_IF     : natural := 1;
  
  -- Actual instruction memory latency, used by the instruction buffer.
  --  - L_IF_MEM >= 1
  constant L_IF_MEM : natural := 1;
  
  -- PC+1 block stage. This is a combinatorial block built into
  -- rvex_pipelane.vhd, so there is no latency.
  -- Requirements:
  --  - S_PCP1 = 1 or 2
  constant S_PCP1   : natural := 1;
  
  -- Branch target adder stage. This is the adder which adds PC+1 to the
  -- instruction immediate. This is a combinatorial block build into
  -- rvex_pipelane.vhd, so there is no latency.
  -- Requirements:
  --  - S_BTGT >= S_PCP1
  --  - S_BTGT >= S_IF + L_IF
  constant S_BTGT   : natural := 2;
  
  -- Stage in which stop bit propagation is performed. This is the process in
  -- which lanes following a lane with a syllable with stop bit set are
  -- invalidated.
  -- Requirements:
  --  - S_STOP = S_IF + L_IF
  constant S_STOP   : natural := 2;
  
  -- Long immediate forwarding block stage.
  -- Requirements:
  --  - S_LIMM >= S_STOP
  constant S_LIMM   : natural := 2;
  
  -- Stage which trap information from the last stage is forwarded to.
  -- Requirements:
  --  - S_TRAP >= 1
  constant S_TRAP   : natural := 2;
  
  -- General purpose register file read access.
  -- Requirements:
  --  - S_RD >= S_IF + L_IF
  --  - L_RD = 1 (unless register file code is changed)
  constant S_RD     : natural := 2;
  constant L_RD     : natural := 1;
  
  -- Special register (branch and link) read access. Muxing between the branch
  -- registers is done combinatorially in rvex_pipelane.vhd, otherwise this is
  -- essentially no-op and just copying the values of the registers into the
  -- pipeline.
  -- Requirements:
  --  - S_SRD >= S_IF + L_IF
  constant S_SRD    : natural := 3;
  
  -- General purpose register file forwarding configuration. This sets up to
  -- which stage the forwarding logic can override the value from the register
  -- (the first stage where it does this is S_RD + L_RD).
  -- Requirements:
  --  - S_FW >= S_RD + L_RD
  constant S_FW     : natural := 3;
  
  -- Special register (branch and link) forwarding configuration. This sets up
  -- to which stage the forwarding logic can override the value from the
  -- register (the first stage where it does this is S_SRD).
  -- Requirements:
  --  - S_SFW >= S_SRD
  constant S_SFW    : natural := 3;
  
  -- Branch determination stage.
  -- Requirement:
  --  - S_BR >= max(S_BTGT, S_SRD, S_PCP1)
  --  - S_BR > S_TRAP
  constant S_BR     : natural := 3;
  
  -- ALU stage and configuration. L_ALU1 determines whether there are registers
  -- between the muxing and decoding of the opcode and the adder/logic units,
  -- L_ALU2 determines whether there are registers between the adder/logic
  -- units and output muxing logic.
  -- Requirements:
  --  - S_ALU >= max(S_LIMM, S_RD + L_RD, S_SRD)
  --  - 0 <= L_ALU1 <= 1
  --  - 0 <= L_ALU2 <= 1
  constant S_ALU    : natural := 3;
  constant L_ALU1   : natural := 0;
  constant L_ALU2   : natural := 1;
  constant L_ALU    : natural := L_ALU1 + L_ALU2;
  
  -- Multiplier stage and latency. Pragmas are used to get XST to balance the
  -- pipeline around the multiplier. XST can absorb up to 2 registers before
  -- and up to two registers after the multiplication (not sure if the total
  -- it can absorb is also two, but it probably is). The latency before the
  -- multiplication is set by L_MUL1, the latency after the multiplication is
  -- set to L_MUL2. Latencies of more than 2 cycles are supported by the code,
  -- but probably won't do you any good timing-wise.
  -- Requirements:
  --  - S_MUL >= max(S_LIMM, S_RD + L_RD)
  constant S_MUL    : natural := 3;
  constant L_MUL1   : natural := 1;
  constant L_MUL2   : natural := 1;
  constant L_MUL    : natural := L_MUL1 + L_MUL2;
  
  -- Data memory access stage and latency. The latency value should be set to
  -- the latency of the data memory. Note that the latency for the control
  -- register interface is hardcoded to 1.
  -- Requirements:
  --  - S_MEM >= max(S_RD + L_RD, S_ALU + L_ALU1)
  --  - L_MEM >= 1 (because of the control registers)
  constant S_MEM    : natural := 4;
  constant L_MEM    : natural := 1;
  
  -- Breakpoint unit stage and latency.
  -- Requirements:
  --  - S_BRK >= S_ALU + L_ALU1
  --  - L_BRK = 0
  constant S_BRK    : natural := 4;
  constant L_BRK    : natural := 0;
  
  -- General purpose register file write access. The latency specifies how
  -- many stages after a value is written it can be read again. Due to lack
  -- of read-after-write forwarding in dual port block RAMs, this latency is
  -- 1. The latency is used by the forwarding logic.
  -- Requirements:
  --  - S_WB >= max(S_ALU + L_ALU, S_MUL + L_MUL, S_MEM + L_MEM)
  constant S_WB     : natural := 5;
  constant L_WB     : natural := 1;
  
  -- Special register write access.
  -- Requirements:
  --  - S_SWB >= max(S_ALU + L_ALU)
  constant S_SWB    : natural := 5;
  
  -- Last stage which can cause a trap. Traps are forwarded from this stage to
  -- S_TRAP.
  -- Requirements:
  --  - S_LTRP >= max(S_* + L_*), for all * in the set of blocks which cause
  --    traps
  constant S_LTRP   : natural := 5;
  
  -- Last stage.
  -- Requirements:
  --  - S_LAST >= max(S_* + L_*), for all * in the set of blocks
  constant S_LAST   : natural := 6;
  
end core_pipeline_pkg;

package body core_pipeline_pkg is
end core_pipeline_pkg;
