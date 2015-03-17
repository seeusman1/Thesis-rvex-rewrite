-- Performs shift operations on r1 and r2 and dumps them to memory:
-- mem(0)  = SHL      r1, r2
-- mem(4)  = SHR      r1, r2
-- mem(8)  = SHRU     r1, r2

-- Delay for a bit to make sure r0.1 and r0.2 are valid, in case forwarding is
-- disabled.
loadnops  64

-- Perform the operations.
load      shl     r0.10 = r0.1, r0.2
load      shr     r0.11 = r0.1, r0.2
load      shru    r0.12 = r0.1, r0.2
load      nop
load      nop
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

