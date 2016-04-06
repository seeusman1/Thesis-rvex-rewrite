-- Performs bitwise operations on r1 and r2 using all available bitwise
-- instructions and dumps the results to memory:
-- mem(0)  = AND      r1, r2
-- mem(4)  = ANDC     r1, r2
-- mem(8)  = OR       r1, r2
-- mem(12) = ORC      r1, r2
-- mem(16) = XOR      r1, r2

-- Delay for a bit to make sure r0.1 and r0.2 are valid, in case forwarding is
-- disabled.
loadnops  64

-- Perform the operations.
load      and     r0.10 = r0.1, r0.2
load      andc    r0.11 = r0.1, r0.2
load      or      r0.12 = r0.1, r0.2
load      orc     r0.13 = r0.1, r0.2
load      xor     r0.14 = r0.1, r0.2
load      nop
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

