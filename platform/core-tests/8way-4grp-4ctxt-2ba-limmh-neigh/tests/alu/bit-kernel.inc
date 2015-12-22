
-- Perform bit tests and clz.
load    tbit    b0.0 = r0.1, r0.3
load    tbitf   b0.1 = r0.1, r0.3
load    clz     r0.4 = r0.1
load    nop
load    nop
load    nop
load    nop
load    nop ;;

-- Perform sbit and sbitf operations and output tbit(f) results.
load    sbitf   r0.1 = r0.1, r0.3
load    sbit    r0.2 = r0.2, r0.3
load    nop
load    nop
load    nop
load    nop
load    stbr    0[r0.0]
load    nop ;;

-- Go to the next bit, output clz result.
load    add     r0.3 = r0.3, -1
load    nop
load    nop
load    nop
load    nop
load    nop
load    stw     4[r0.0] = r0.4
load    nop ;;

-- Output r0.1 after sbitf.
load    nop
load    nop
load    nop
load    nop
load    nop
load    nop
load    stw     8[r0.0] = r0.1
load    nop ;;

-- Output r0.2 after sbit.
load    nop
load    nop
load    nop
load    nop
load    nop
load    nop
load    stw     12[r0.0] = r0.2
load    nop ;;

