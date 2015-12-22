-- Performs all comparison operations on r1 and r2 and dumps the results to
-- memory as follows:
--
-- mem(0) = (
--   0 => CMPNE
--   1 => CMPGT
--   2 => CMPGE
--   3 => CMPEQ
--   4 => CMPLE
--   5 => CMPLT
-- )
-- mem(4) = CMPNE
-- mem(8) = CMPGT
-- mem(12) = CMPGE
-- mem(16) = CMPEQ
-- mem(20) = CMPLE
-- mem(24) = CMPLT
--
-- mem(0) = (
--   0 => CMPNE
--   1 => CMPGTU
--   2 => CMPGEU
--   3 => CMPEQ
--   4 => CMPLEU
--   5 => CMPLTU
-- )
-- mem(4) = CMPNEU
-- mem(8) = CMPGTU
-- mem(12) = CMPGE
-- mem(16) = CMPEQU
-- mem(20) = CMPLEU
-- mem(24) = CMPLT

-- Delay for a bit to make sure r0.1 and r0.2 are valid, in case forwarding is
-- disabled.
loadnops  64

-- Perform the signed operations with integer results.
load      cmpne   r0.10 = r0.1, r0.2
load      cmpgt   r0.11 = r0.1, r0.2
load      cmpge   r0.12 = r0.1, r0.2
load      cmpeq   r0.13 = r0.1, r0.2
load      cmple   r0.14 = r0.1, r0.2
load      cmplt   r0.15 = r0.1, r0.2
load      nop
load      nop ;;

-- Perform the signed operations with branch results.
load      cmpne   b0.0 = r0.1, r0.2
load      cmpgt   b0.1 = r0.1, r0.2
load      cmpge   b0.2 = r0.1, r0.2
load      cmpeq   b0.3 = r0.1, r0.2
load      cmple   b0.4 = r0.1, r0.2
load      cmplt   b0.5 = r0.1, r0.2
load      nop
load      nop ;;

-- Delay for a bit, in case forwarding is disabled.
loadnops  64

-- Dump signed operation results.
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

load      nop
load      nop
load      nop
load      nop
load      nop
load      nop
load      stw 20[r0.0] = r0.14
load      nop ;;

load      nop
load      nop
load      nop
load      nop
load      nop
load      nop
load      stw 24[r0.0] = r0.15
load      nop ;;

-- Perform the unsigned operations with integer results.
load      cmpne   r0.10 = r0.1, r0.2
load      cmpgtu  r0.11 = r0.1, r0.2
load      cmpgeu  r0.12 = r0.1, r0.2
load      cmpeq   r0.13 = r0.1, r0.2
load      cmpleu  r0.14 = r0.1, r0.2
load      cmpltu  r0.15 = r0.1, r0.2
load      nop
load      nop ;;

-- Perform the unsigned operations with branch results.
load      cmpne   b0.0 = r0.1, r0.2
load      cmpgtu  b0.1 = r0.1, r0.2
load      cmpgeu  b0.2 = r0.1, r0.2
load      cmpeq   b0.3 = r0.1, r0.2
load      cmpleu  b0.4 = r0.1, r0.2
load      cmpltu  b0.5 = r0.1, r0.2
load      nop
load      nop ;;

-- Delay for a bit, in case forwarding is disabled.
loadnops  64

-- Dump unsigned operation results.
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

load      nop
load      nop
load      nop
load      nop
load      nop
load      nop
load      stw 20[r0.0] = r0.14
load      nop ;;

load      nop
load      nop
load      nop
load      nop
load      nop
load      nop
load      stw 24[r0.0] = r0.15
load      nop ;;
