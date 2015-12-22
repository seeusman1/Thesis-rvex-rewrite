-- Performs all available logical operations on r0.1 and r0.2 and dumps the
-- results:
-- mem(0) = (
--   0    => nandl  r1, r2
--   1    => norl   r1, r2
--   2    => orl    r1, r2
--   3    => norl   r1, r2
-- )
-- mem(4)  = nandl  r1, r2
-- mem(8)  = norl   r1, r2
-- mem(12) = orl    r1, r2
-- mem(16) = norl   r1, r2

-- Delay for a bit to make sure r0.1 and r0.2 are valid, in case forwarding is
-- disabled.
loadnops  64

-- Perform the operations.
load      nandl   r0.10 = r0.1, r0.2
load      norl    r0.11 = r0.1, r0.2
load      orl     r0.12 = r0.1, r0.2
load      andl    r0.13 = r0.1, r0.2
load      nandl   b0.0  = r0.1, r0.2
load      norl    b0.1  = r0.1, r0.2
load      orl     b0.2  = r0.1, r0.2
load      andl    b0.3  = r0.1, r0.2 ;;

-- Delay for a bit, in case forwarding is disabled.
loadnops  64

-- Dump the output.
load      nop
load      nop
load      nop
load      nop
load      nop
load      nop
load      stbr 0[r0.0]
load      nop ;;

load      nop
load      nop
load      nop
load      nop
load      nop
load      nop
load      stw 4[r0.0] = r0.10
load      nop ;;

load      nop
load      nop
load      nop
load      nop
load      nop
load      nop
load      stw 8[r0.0] = r0.11
load      nop ;;

load      nop
load      nop
load      nop
load      nop
load      nop
load      nop
load      stw 12[r0.0] = r0.12
load      nop ;;

load      nop
load      nop
load      nop
load      nop
load      nop
load      nop
load      stw 16[r0.0] = r0.13
load      nop ;;

