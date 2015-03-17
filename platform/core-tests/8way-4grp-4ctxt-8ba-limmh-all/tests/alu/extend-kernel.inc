-- Performs zero/sign extensions on r1 and dumps the results to memory:
-- mem(0)  = SXTB r1
-- mem(4)  = SXTH r1
-- mem(8)  = ZXTB r1
-- mem(12)  = ZXTH r1

-- Delay for a bit to make sure r0.1 and r0.2 are valid, in case forwarding is
-- disabled.
loadnops  64

-- Perform the operations.
load      sxtb    r0.10 = r0.1
load      sxth    r0.11 = r0.1
load      zxtb    r0.12 = r0.1
load      zxth    r0.13 = r0.1
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

load      nop
load      nop
load      nop
load      nop
load      nop
load      nop
load      stw 12[r0.0] = r0.13
load      nop ;;

