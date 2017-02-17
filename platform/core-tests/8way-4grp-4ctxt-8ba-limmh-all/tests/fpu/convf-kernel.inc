-- Converts r1 from int to float, and r2 from float to int
-- Dumps results to memory:
-- mem(0) = CONVIF r1
-- mem(4) = CONVFI r2

-- Delay for a bit to make sure r0.1 and r0.2 are valid, in case forwarding is
-- disabled.
loadnops 64

-- Perform the operations.
load     convif r0.10 = r0.1
load     convfi r0.11 = r0.2
load     nop
load     nop
load     nop
load     nop
load     nop
load     nop ;;

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
