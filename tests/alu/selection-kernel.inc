-- Adds r1, r2 and b0 to perform the following operations and dump them to
-- memory:
-- mem(0)  = MAX      r1, r2
-- mem(4)  = MAXU     r1, r2
-- mem(8)  = MIN      r1, r2
-- mem(12) = MINU     r1, r2
-- mem(16) = SLCT     b0, r1, r2
-- mem(20) = SLCTF    b0, r1, r2

-- Delay for a bit to make sure r0.1, r0.2 and b0 are valid, in case forwarding
-- is disabled.
loadnops  64

-- Perform the operations.
load      max     r0.10 = r0.1, r0.2
load      maxu    r0.11 = r0.1, r0.2
load      min     r0.12 = r0.1, r0.2
load      minu    r0.13 = r0.1, r0.2
load      slct    r0.14 = b0.0, r0.1, r0.2
load      slctf   r0.15 = b0.0, r0.1, r0.2
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

