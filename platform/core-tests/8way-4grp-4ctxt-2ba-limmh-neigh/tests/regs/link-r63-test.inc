-- Tests link/r0.63 sharing logic.

-- 0x000
load    add r0.63 = r0.0, 0
load    movtl l0.0 = r0.0
load    add r0.33 = r0.0, 33
load    nop ;;

-- 0x010
load    add r0.63 = r0.0, 42
load    nop ;;

-- Give the write to r0.63/link time to commit.
fillnops 0x100

-- 0x100
load    stw 0[r0.0] = l0.0 -- Should be 42 when r0.63 = link, 0 otherwise.
load    movtl l0.0 = r0.33 ;;

-- Give the write to r0.63/link time to commit.
fillnops 0x200

-- 0x200
load    stw 0[r0.0] = r0.63 -- Should be 33 when r0.63 = link, 42 otherwise.
load    stop ;;

