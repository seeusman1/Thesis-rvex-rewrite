-- Performs all comparison operations on r1 and r2 and dumps the results to
-- memory as follows:
--
-- mem(0) = (
--   0 => CMPGEF
--   1 => CMPEQF
--   2 => CMPGTF
-- )
-- mem(4)  = CMPGEF
-- mem(8)  = CMPEQF
-- mem(12) = CMPGTF

-- Delay for a bit to make sure r0.1 and r0.2 are valid, in case forwarding is
-- disabled
loadnops  64

-- Perform operations with register results
load      cmpgef r0.10 = r0.1, r0.2
load      cmpeqf r0.11 = r0.1, r0.2
load      cmpgtf r0.12 = r0.1, r0.2
load      nop
load      nop
load      nop
load      nop
load      nop ;;

-- Perform operations with branch results
load      cmpgef b0.0 = r0.1, r0.2
load      cmpeqf b0.1 = r0.1, r0.2
load      cmpgtf b0.2 = r0.1, r0.2
load      nop
load      nop
load      nop
load      nop
load      nop ;;

-- Delay for a bit, in case forwarding is disabled
loadnops  64

-- Dump results
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
