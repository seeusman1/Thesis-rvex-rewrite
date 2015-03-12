-- Adds r1 and r2 using all available add instructions (save for ADDCG, which
-- is tested by performing a division) and dumps the results to memory:
-- mem(0)  = ADD      r1, r2
-- mem(4)  = SH1ADD   r1, r2
-- mem(8)  = SH2ADD   r1, r2
-- mem(12) = SH3ADD   r1, r2
-- mem(16) = SH4ADD   r1, r2
-- mem(20) = SUB      r1, r2

-- Delay for a bit to make sure r0.1 and r0.2 are valid, in case forwarding is
-- disabled.
loadnops  64

-- Perform the operations.
load      add     r0.10 = r0.1, r0.2
load      sh1add  r0.11 = r0.1, r0.2
load      sh2add  r0.12 = r0.1, r0.2
load      sh3add  r0.13 = r0.1, r0.2
load      sh4add  r0.14 = r0.1, r0.2
load      sub     r0.15 = r0.2, r0.1 -- operands are swapped in syntax
load      nop
load      nop ;;

-- Delay for a bit, in case forwarding is disabled.
loadnops  64

-- Dump the output.
load      nop
load      nop
load      nop
load      nop
load      nop
load      nop
load      stw 0[r0.0] = r0.10
load      nop ;;

load      nop
load      nop
load      nop
load      nop
load      nop
load      nop
load      stw 4[r0.0] = r0.11
load      nop ;;

load      nop
load      nop
load      nop
load      nop
load      nop
load      nop
load      stw 8[r0.0] = r0.12
load      nop ;;

load      nop
load      nop
load      nop
load      nop
load      nop
load      nop
load      stw 12[r0.0] = r0.13
load      nop ;;

load      nop
load      nop
load      nop
load      nop
load      nop
load      nop
load      stw 16[r0.0] = r0.14
load      nop ;;

load      nop
load      nop
load      nop
load      nop
load      nop
load      nop
load      stw 20[r0.0] = r0.15
load      nop ;;

