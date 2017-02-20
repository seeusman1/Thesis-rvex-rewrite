-- Multiplies r1 and r2 as single-precision floating-point numbers
-- Dumps results to memory:
-- mem(0) = MPYF r1, r2

-- Delay for a bit to make sure r0.1 and r0.2 are valid, in case forwarding is
-- disabled.
loadnops 64

-- Perform the operations.
load     mpyf r0.10 = r0.1, r0.2
load     nop
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
