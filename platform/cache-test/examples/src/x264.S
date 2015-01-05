 ## Target: VEX 1 cluster (big endian)
.comment ""
.comment "Copyright (C) 1990-2010 Hewlett-Packard Company"
.comment "VEX C compiler version 3.43 (20110131 release)"
.comment ""
.comment "-dir /home/jeroen/rvex/rvex-rewrite/tools/vex-3.43 -O2 -fno-xnop -fexpand-div -fmm=pipe_1_8_fw.mm -S"
.sversion 3.43
.rta 2
.section .bss
.align 32
.section .data
.align 32
.equ _?1TEMPLATEPACKET.15, 0x0
 ## Begin sim_putc
.section .text
.proc
.entry caller, sp=$r0.1, rl=$l0.0, asize=0, arg($r0.3:u32)
sim_putc:
.trace 1
	      ## auto_size == 0
	c0    sxtb $r0.3 = $r0.3   ## bblock 0, line 5,  t0(SI8),  t13
;;								## 0
.return ret()
	c0    stb 0xdeb00000[$r0.0] = $r0.3   ## bblock 0, line 6, 0(I32), t0(SI8)
	c0    return $r0.1 = $r0.1, (0x0), $l0.0   ## bblock 0, line 7,  t2,  ?2.1?2auto_size(I32),  t1
;;								## 1
.endp
.section .bss
.section .data
.section .data
.section .text
.equ ?2.1?2auto_size, 0x0
 ## End sim_putc
.equ _?1TEMPLATEPACKET.16, 0x0
 ## Begin sim_puts
.section .text
.proc
.entry caller, sp=$r0.1, rl=$l0.0, asize=0, arg($r0.3:u32)
sim_puts:
.trace 3
	      ## auto_size == 0
	c0    mov $r0.2 = $r0.3   ## t17
;;								## 0
.trace 1
L0?3:
	c0    ldb $r0.3 = 0[$r0.2]   ## bblock 1, line 10, t1(SI8), t17
;;								## 0
;;								## 1
	c0    cmpne $b0.0 = $r0.3, $r0.0   ## bblock 1, line 10,  t36(I1),  t1(SI8),  0(SI32)
;;								## 2
	c0    brf $b0.0, L1?3   ## bblock 1, line 10,  t36(I1)
;;								## 3
	c0    stb 0xdeb00000[$r0.0] = $r0.3   ## bblock 3, line 10, 0(I32), t1(SI8)
;;								## 4
	c0    ldb $r0.3 = 1[$r0.2]   ## bblock 3, line 10-1, t22(SI8), t17
;;								## 5
;;								## 6
	c0    cmpne $b0.0 = $r0.3, $r0.0   ## bblock 3, line 10-1,  t37(I1),  t22(SI8),  0(SI32)
;;								## 7
	c0    brf $b0.0, L1?3   ## bblock 3, line 10-1,  t37(I1)
;;								## 8
	c0    stb 0xdeb00000[$r0.0] = $r0.3   ## bblock 11, line 10-1, 0(I32), t22(SI8)
;;								## 9
	c0    ldb $r0.3 = 2[$r0.2]   ## bblock 11, line 10-2, t20(SI8), t17
;;								## 10
;;								## 11
	c0    cmpne $b0.0 = $r0.3, $r0.0   ## bblock 11, line 10-2,  t39(I1),  t20(SI8),  0(SI32)
;;								## 12
	c0    brf $b0.0, L1?3   ## bblock 11, line 10-2,  t39(I1)
;;								## 13
	c0    stb 0xdeb00000[$r0.0] = $r0.3   ## bblock 8, line 10-2, 0(I32), t20(SI8)
;;								## 14
	c0    ldb $r0.3 = 3[$r0.2]   ## bblock 8, line 10-3, t19(SI8), t17
	c0    add $r0.2 = $r0.2, 4   ## [spec] bblock 5, line 10-3,  t17,  t17,  4(SI32)
;;								## 15
;;								## 16
	c0    cmpne $b0.0 = $r0.3, $r0.0   ## bblock 8, line 10-3,  t38(I1),  t19(SI8),  0(SI32)
;;								## 17
	c0    brf $b0.0, L1?3   ## bblock 8, line 10-3,  t38(I1)
;;								## 18
	c0    stb 0xdeb00000[$r0.0] = $r0.3   ## bblock 5, line 10-3, 0(I32), t19(SI8)
	c0    goto L0?3 ## goto
;;								## 19
.trace 4
L1?3:
.return ret()
	c0    return $r0.1 = $r0.1, (0x0), $l0.0   ## bblock 2, line 11,  t6,  ?2.2?2auto_size(I32),  t5
;;								## 0
.endp
.section .bss
.section .data
.section .data
.section .text
.equ ?2.2?2auto_size, 0x0
 ## End sim_puts
 ## Begin abs
.section .text
.proc
.entry caller, sp=$r0.1, rl=$l0.0, asize=0, arg($r0.3:s32)
abs::
.trace 1
	      ## auto_size == 0
	c0    cmplt $b0.0 = $r0.3, $r0.0   ## bblock 0, line 15,  t17(I1),  t16,  0(SI32)
	c0    sub $r0.2 = $r0.0, $r0.3   ## [spec] bblock 2, line 16,  t2,  0(I32),  t16
;;								## 0
	c0    brf $b0.0, L2?3   ## bblock 0, line 15,  t17(I1)
;;								## 1
.return ret($r0.3:s32)
	c0    return $r0.1 = $r0.1, (0x0), $l0.0   ## bblock 2, line 16,  t5,  ?2.3?2auto_size(I32),  t4
	c0    mov $r0.3 = $r0.2   ## [spec] t2
;;								## 2
.trace 2
L2?3:
.return ret($r0.3:s32)
	c0    return $r0.1 = $r0.1, (0x0), $l0.0   ## bblock 1, line 18,  t5,  ?2.3?2auto_size(I32),  t4
;;								## 0
.endp
.section .bss
.section .data
.section .data
.section .text
.equ ?2.3?2auto_size, 0x0
 ## End abs
.equ _?1TEMPLATEPACKET.7, 0x0
 ## Begin x264_pixel_sad_16x16
.section .text
.proc
.entry caller, sp=$r0.1, rl=$l0.0, asize=-64, arg($r0.3:u32,$r0.4:s32,$r0.5:u32,$r0.6:s32)
x264_pixel_sad_16x16:
.trace 5
	c0    add $r0.1 = $r0.1, (-0x40)
;;								## 0
	c0    stw 0x10[$r0.1] = $l0.0  ## spill ## t34
;;								## 1
	c0    stw 0x14[$r0.1] = $r0.57  ## spill ## t38
;;								## 2
	c0    mov $r0.57 = $r0.0   ## bblock 0, line 24,  t53,  0(SI32)
	c0    stw 0x18[$r0.1] = $r0.58  ## spill ## t39
;;								## 3
	c0    add $r0.58 = $r0.3, 16   ## bblock 0, line 0,  t71,  t49,  16(I32)
	c0    stw 0x1c[$r0.1] = $r0.59  ## spill ## t40
;;								## 4
	c0    add $r0.59 = $r0.5, 16   ## bblock 0, line 0,  t72,  t51,  16(I32)
	c0    stw 0x20[$r0.1] = $r0.60  ## spill ## t41
;;								## 5
	c0    mov $r0.60 = $r0.0   ## bblock 0, line 24,  t55,  0(SI32)
	c0    stw 0x24[$r0.1] = $r0.61  ## spill ## t42
;;								## 6
	c0    stw 0x28[$r0.1] = $r0.62  ## spill ## t43
;;								## 7
	c0    stw 0x2c[$r0.1] = $r0.63  ## spill ## t44
	c0    mov $r0.62 = $r0.4   ## t50
;;								## 8
	c0    mov $r0.63 = $r0.6   ## t52
;;								## 9
.trace 3
L3?3:
	c0    cmplt $b0.0 = $r0.57, 16   ## bblock 1, line 26,  t80(I1),  t53,  16(SI32)
	c0    mov $r0.3 = (_?1STRINGPACKET.1 + 0)   ## addr(_?1STRINGVAR.1)(P32)
;;								## 0
	c0    brf $b0.0, L4?3   ## bblock 1, line 26,  t80(I1)
;;								## 1
.call sim_puts, caller, arg($r0.3:u32), ret()
	c0    call $l0.0 = sim_puts   ## bblock 3, line 28,  raddr(sim_puts)(P32),  addr(_?1STRINGVAR.1)(P32)
;;								## 2
	c0    cmplt $b0.0 = $r0.57, 10   ## bblock 4, line 29,  t81(I1),  t53,  10(SI32)
	c0    mov $r0.2 = 48   ## 48(SI32)
;;								## 3
	c0    slct $r0.2 = $b0.0, $r0.2, 55   ## bblock 4, line 29,  t7,  t81(I1),  48(SI32),  55(SI32)
;;								## 4
	c0    add $r0.2 = $r0.57, $r0.2   ## bblock 4, line 29,  t8,  t53,  t7
;;								## 5
.call sim_putc, caller, arg($r0.3:s32), ret()
	c0    sxtb $r0.3 = $r0.2   ## bblock 4, line 29,  t9(SI8),  t8
	c0    call $l0.0 = sim_putc   ## bblock 4, line 29,  raddr(sim_putc)(P32),  t9(SI8)
;;								## 6
.call sim_puts, caller, arg($r0.3:u32), ret()
	c0    call $l0.0 = sim_puts   ## bblock 5, line 30,  raddr(sim_puts)(P32),  addr(_?1STRINGVAR.2)(P32)
	c0    mov $r0.3 = (_?1STRINGPACKET.2 + 0)   ## addr(_?1STRINGVAR.2)(P32)
;;								## 7
	c0    mov $r0.57 = (~0xf)   ## bblock 6, line 0,  t59,  (~0xf)(I32)
	c0    mov $r0.61 = $r0.57   ## t53
;;								## 8
;;								## 9
.trace 1
L5?3:
	c0    cmplt $b0.0 = $r0.57, $r0.0   ## bblock 7, line 31,  t82(I1),  t59,  0(SI32)
	c0    add $r0.4 = $r0.57, $r0.59   ## [spec] bblock 9, line 33,  t83,  t59,  t72
	c0    add $r0.2 = $r0.57, $r0.58   ## [spec] bblock 9, line 33,  t84,  t59,  t71
;;								## 0
	c0    ldbu.d $r0.2 = 0[$r0.2]   ## [spec] bblock 9, line 33, t24(I8), t84
	c0    brf $b0.0, L6?3   ## bblock 7, line 31,  t82(I1)
;;								## 1
	c0    ldbu $r0.4 = 0[$r0.4]   ## bblock 9, line 33, t20(I8), t83
;;								## 2
;;								## 3
.call abs, caller, arg($r0.3:s32), ret($r0.3:s32)
	c0    sub $r0.3 = $r0.2, $r0.4   ## bblock 9, line 33,  t25,  t24(I8),  t20(I8)
	c0    call $l0.0 = abs   ## bblock 9, line 33,  raddr(abs)(P32),  t25
;;								## 4
	c0    add $r0.60 = $r0.3, $r0.60   ## bblock 10, line 33,  t55,  t16,  t55
	c0    add $r0.57 = $r0.57, 1   ## bblock 10, line 0,  t59,  t59,  1(I32)
	c0    goto L5?3 ## goto
;;								## 5
.trace 4
L6?3:
	c0    add $r0.58 = $r0.62, $r0.58   ## bblock 11, line 0,  t71,  t50,  t71
	c0    add $r0.59 = $r0.63, $r0.59   ## bblock 11, line 0,  t72,  t52,  t72
	c0    add $r0.57 = $r0.61, 1   ## bblock 11, line 26,  t53,  t53,  1(SI32)
	c0    goto L3?3 ## goto
;;								## 0
.trace 6
L4?3:
	c0    mov $r0.3 = $r0.60   ## t55
	c0    ldw $l0.0 = 0x10[$r0.1]  ## restore ## t34
;;								## 0
	c0    ldw $r0.63 = 0x2c[$r0.1]  ## restore ## t44
;;								## 1
	c0    ldw $r0.62 = 0x28[$r0.1]  ## restore ## t43
;;								## 2
	c0    ldw $r0.61 = 0x24[$r0.1]  ## restore ## t42
;;								## 3
	c0    ldw $r0.60 = 0x20[$r0.1]  ## restore ## t41
;;								## 4
	c0    ldw $r0.59 = 0x1c[$r0.1]  ## restore ## t40
;;								## 5
	c0    ldw $r0.58 = 0x18[$r0.1]  ## restore ## t39
;;								## 6
	c0    ldw $r0.57 = 0x14[$r0.1]  ## restore ## t38
;;								## 7
.return ret($r0.3:s32)
	c0    return $r0.1 = $r0.1, (0x40), $l0.0   ## bblock 2, line 38,  t35,  ?2.4?2auto_size(I32),  t34
;;								## 8
.endp
.section .bss
.section .data
_?1STRINGPACKET.1:
    .data1 121
    .data1 32
    .data1 61
    .data1 32
    .data1 0
.skip 3
_?1STRINGPACKET.2:
    .data1 10
    .data1 0
.equ ?2.4?2scratch.0, 0x0
.equ ?2.4?2ras_p, 0x10
.equ ?2.4?2spill_p, 0x14
.section .data
.section .text
.equ ?2.4?2auto_size, 0x40
 ## End x264_pixel_sad_16x16
.equ _?1TEMPLATEPACKET.9, 0x0
 ## Begin x264_pixel_sad_x4_16x16
.section .text
.proc
.entry caller, sp=$r0.1, rl=$l0.0, asize=-64, arg($r0.3:u32,$r0.4:u32,$r0.5:u32,$r0.6:u32,$r0.7:u32,$r0.8:s32,$r0.9:u32)
x264_pixel_sad_x4_16x16:
.trace 1
	c0    add $r0.1 = $r0.1, (-0x40)
;;								## 0
	c0    stw 0x10[$r0.1] = $l0.0  ## spill ## t34
;;								## 1
	c0    stw 0x14[$r0.1] = $r0.7  ## spill ## t56
;;								## 2
	c0    stw 0x18[$r0.1] = $r0.6  ## spill ## t55
;;								## 3
	c0    stw 0x1c[$r0.1] = $r0.5  ## spill ## t54
;;								## 4
	c0    stw 0x20[$r0.1] = $r0.9  ## spill ## t58
;;								## 5
	c0    stw 0x24[$r0.1] = $r0.8  ## spill ## t57
;;								## 6
	c0    stw 0x28[$r0.1] = $r0.4  ## spill ## t53
;;								## 7
	c0    stw 0x2c[$r0.1] = $r0.3  ## spill ## t52
;;								## 8
.call sim_puts, caller, arg($r0.3:u32), ret()
	c0    call $l0.0 = sim_puts   ## bblock 0, line 44,  raddr(sim_puts)(P32),  addr(_?1STRINGVAR.3)(P32)
	c0    mov $r0.3 = (_?1STRINGPACKET.3 + 0)   ## addr(_?1STRINGVAR.3)(P32)
;;								## 9
	c0    mov $r0.4 = 16   ## 16(SI32)
	c0    ldw $r0.6 = 0x24[$r0.1]  ## restore ## t57
;;								## 10
	c0    ldw $r0.5 = 0x28[$r0.1]  ## restore ## t53
;;								## 11
	c0    ldw $r0.3 = 0x2c[$r0.1]  ## restore ## t52
;;								## 12
.call x264_pixel_sad_16x16, caller, arg($r0.3:u32,$r0.4:s32,$r0.5:u32,$r0.6:s32), ret($r0.3:s32)
	c0    call $l0.0 = x264_pixel_sad_16x16   ## bblock 1, line 45,  raddr(x264_pixel_sad_16x16)(P32),  t52,  16(SI32),  t53,  t57
;;								## 13
	c0    ldw $r0.9 = 0x20[$r0.1]  ## restore ## t58
;;								## 14
;;								## 15
	c0    stw 0[$r0.9] = $r0.3   ## bblock 2, line 45, t58, t2
;;
.call sim_puts, caller, arg($r0.3:u32), ret()
	c0    call $l0.0 = sim_puts   ## bblock 2, line 46,  raddr(sim_puts)(P32),  addr(_?1STRINGVAR.4)(P32)
	c0    mov $r0.3 = (_?1STRINGPACKET.4 + 0)   ## addr(_?1STRINGVAR.4)(P32)
;;								## 16
	c0    mov $r0.4 = 16   ## 16(SI32)
	c0    ldw $r0.5 = 0x1c[$r0.1]  ## restore ## t54
;;								## 17
	c0    ldw $r0.6 = 0x24[$r0.1]  ## restore ## t57
;;								## 18
	c0    ldw $r0.3 = 0x2c[$r0.1]  ## restore ## t52
;;								## 19
.call x264_pixel_sad_16x16, caller, arg($r0.3:u32,$r0.4:s32,$r0.5:u32,$r0.6:s32), ret($r0.3:s32)
	c0    call $l0.0 = x264_pixel_sad_16x16   ## bblock 3, line 47,  raddr(x264_pixel_sad_16x16)(P32),  t52,  16(SI32),  t54,  t57
;;								## 20
	c0    ldw $r0.9 = 0x20[$r0.1]  ## restore ## t58
;;								## 21
;;								## 22
	c0    stw 4[$r0.9] = $r0.3   ## bblock 4, line 47, t58, t10
;;
.call sim_puts, caller, arg($r0.3:u32), ret()
	c0    call $l0.0 = sim_puts   ## bblock 4, line 48,  raddr(sim_puts)(P32),  addr(_?1STRINGVAR.5)(P32)
	c0    mov $r0.3 = (_?1STRINGPACKET.5 + 0)   ## addr(_?1STRINGVAR.5)(P32)
;;								## 23
	c0    mov $r0.4 = 16   ## 16(SI32)
	c0    ldw $r0.5 = 0x18[$r0.1]  ## restore ## t55
;;								## 24
	c0    ldw $r0.6 = 0x24[$r0.1]  ## restore ## t57
;;								## 25
	c0    ldw $r0.3 = 0x2c[$r0.1]  ## restore ## t52
;;								## 26
.call x264_pixel_sad_16x16, caller, arg($r0.3:u32,$r0.4:s32,$r0.5:u32,$r0.6:s32), ret($r0.3:s32)
	c0    call $l0.0 = x264_pixel_sad_16x16   ## bblock 5, line 49,  raddr(x264_pixel_sad_16x16)(P32),  t52,  16(SI32),  t55,  t57
;;								## 27
	c0    ldw $r0.9 = 0x20[$r0.1]  ## restore ## t58
;;								## 28
;;								## 29
	c0    stw 8[$r0.9] = $r0.3   ## bblock 6, line 49, t58, t18
;;
.call sim_puts, caller, arg($r0.3:u32), ret()
	c0    call $l0.0 = sim_puts   ## bblock 6, line 50,  raddr(sim_puts)(P32),  addr(_?1STRINGVAR.6)(P32)
	c0    mov $r0.3 = (_?1STRINGPACKET.6 + 0)   ## addr(_?1STRINGVAR.6)(P32)
;;								## 30
	c0    mov $r0.4 = 16   ## 16(SI32)
	c0    ldw $r0.5 = 0x14[$r0.1]  ## restore ## t56
;;								## 31
	c0    ldw $r0.6 = 0x24[$r0.1]  ## restore ## t57
;;								## 32
	c0    ldw $r0.3 = 0x2c[$r0.1]  ## restore ## t52
;;								## 33
.call x264_pixel_sad_16x16, caller, arg($r0.3:u32,$r0.4:s32,$r0.5:u32,$r0.6:s32), ret($r0.3:s32)
	c0    call $l0.0 = x264_pixel_sad_16x16   ## bblock 7, line 51,  raddr(x264_pixel_sad_16x16)(P32),  t52,  16(SI32),  t56,  t57
;;								## 34
	c0    ldw $r0.9 = 0x20[$r0.1]  ## restore ## t58
;;								## 35
;;								## 36
	c0    stw 12[$r0.9] = $r0.3   ## bblock 8, line 51, t58, t26
;;
.call sim_puts, caller, arg($r0.3:u32), ret()
	c0    call $l0.0 = sim_puts   ## bblock 8, line 52,  raddr(sim_puts)(P32),  addr(_?1STRINGVAR.7)(P32)
	c0    mov $r0.3 = (_?1STRINGPACKET.7 + 0)   ## addr(_?1STRINGVAR.7)(P32)
;;								## 37
	c0    ldw $l0.0 = 0x10[$r0.1]  ## restore ## t34
;;								## 38
;;								## 39
.return ret()
	c0    return $r0.1 = $r0.1, (0x40), $l0.0   ## bblock 9, line 53,  t35,  ?2.5?2auto_size(I32),  t34
;;								## 40
.endp
.section .bss
.section .data
.skip 2
_?1STRINGPACKET.3:
    .data1 48
    .data1 37
    .data1 46
    .data1 46
    .data1 46
    .data1 10
    .data1 0
.skip 1
_?1STRINGPACKET.4:
    .data1 50
    .data1 53
    .data1 37
    .data1 46
    .data1 46
    .data1 46
    .data1 10
    .data1 0
_?1STRINGPACKET.5:
    .data1 53
    .data1 48
    .data1 37
    .data1 46
    .data1 46
    .data1 46
    .data1 10
    .data1 0
_?1STRINGPACKET.6:
    .data1 55
    .data1 53
    .data1 37
    .data1 46
    .data1 46
    .data1 46
    .data1 10
    .data1 0
_?1STRINGPACKET.7:
    .data1 49
    .data1 48
    .data1 48
    .data1 37
    .data1 46
    .data1 46
    .data1 46
    .data1 10
    .data1 0
.equ ?2.5?2scratch.0, 0x0
.equ ?2.5?2ras_p, 0x10
.equ ?2.5?2spill_p, 0x14
.section .data
.section .text
.equ ?2.5?2auto_size, 0x40
 ## End x264_pixel_sad_x4_16x16
 ## Begin main
.section .text
.proc
.entry caller, sp=$r0.1, rl=$l0.0, asize=-832, arg()
main::
.trace 1
	c0    add $r0.1 = $r0.1, (-0x340)
	c0    mov $r0.8 = 16   ## 16(SI32)
	c0    mov $r0.4 = (pix0 + 0)   ## addr(pix0?1.0)(P32)
	c0    mov $r0.3 = (fenc + 0)   ## addr(fenc?1.0)(P32)
;;								## 0
	c0    add $r0.5 = $r0.1, 0x10   ## bblock 0, line 91,  t8,  t34,  offset(pix1?1.14)=0x10(P32)
	c0    add $r0.6 = $r0.1, 0x110   ## bblock 0, line 92,  t9,  t34,  offset(pix2?1.14)=0x110(P32)
	c0    add $r0.7 = $r0.1, 0x210   ## bblock 0, line 93,  t10,  t34,  offset(pix3?1.14)=0x210(P32)
	c0    stw 0x320[$r0.1] = $l0.0  ## spill ## t33
;;								## 1
	c0    add $r0.9 = $r0.1, 0x310   ## bblock 0, line 94,  t3,  t34,  offset(scores?1.14)=0x310(P32)
;;								## 2
.call x264_pixel_sad_x4_16x16, caller, arg($r0.3:u32,$r0.4:u32,$r0.5:u32,$r0.6:u32,$r0.7:u32,$r0.8:s32,$r0.9:u32), ret()
	c0    call $l0.0 = x264_pixel_sad_x4_16x16   ## bblock 0, line 98,  raddr(x264_pixel_sad_x4_16x16)(P32),  addr(fenc?1.0)(P32),  addr(pix0?1.0)(P32),  t8,  t9,  t10,  16(SI32),  t3
	c0    stw 0x324[$r0.1] = $r0.9  ## spill ## t3
;;								## 3
	c0    mov $r0.3 = (_?1STRINGPACKET.8 + 0)   ## addr(_?1STRINGVAR.8)(P32)
	c0    mov $r0.2 = 1920   ## 1920(SI32)
	c0    ldw $r0.9 = 0x324[$r0.1]  ## restore ## t3
;;								## 4
;;								## 5
	c0    ldw $r0.9 = 0[$r0.9]   ## bblock 1, line 100, t13, t3
;;								## 6
;;								## 7
	c0    cmpeq $b0.0 = $r0.9, $r0.2   ## bblock 1, line 100,  t45(I1),  t13,  1920(SI32)
;;								## 8
	c0    brf $b0.0, L7?3   ## bblock 1, line 100,  t45(I1)
;;								## 9
.call sim_puts, caller, arg($r0.3:u32), ret()
	c0    call $l0.0 = sim_puts   ## bblock 13, line 101,  raddr(sim_puts)(P32),  addr(_?1STRINGVAR.8)(P32)
;;								## 10
L8?3:
	c0    mov $r0.3 = (_?1STRINGPACKET.10 + 0)   ## addr(_?1STRINGVAR.10)(P32)
	c0    mov $r0.2 = 1920   ## 1920(SI32)
	c0    ldw $r0.9 = 0x324[$r0.1]  ## restore ## t3
;;								## 11
;;								## 12
	c0    ldw $r0.9 = 4[$r0.9]   ## bblock 3, line 105, t18, t3
;;								## 13
;;								## 14
	c0    cmpeq $b0.0 = $r0.9, $r0.2   ## bblock 3, line 105,  t46(I1),  t18,  1920(SI32)
;;								## 15
	c0    brf $b0.0, L9?3   ## bblock 3, line 105,  t46(I1)
;;								## 16
.call sim_puts, caller, arg($r0.3:u32), ret()
	c0    call $l0.0 = sim_puts   ## bblock 12, line 106,  raddr(sim_puts)(P32),  addr(_?1STRINGVAR.10)(P32)
;;								## 17
L10?3:
	c0    mov $r0.3 = (_?1STRINGPACKET.12 + 0)   ## addr(_?1STRINGVAR.12)(P32)
	c0    mov $r0.2 = 1920   ## 1920(SI32)
	c0    ldw $r0.9 = 0x324[$r0.1]  ## restore ## t3
;;								## 18
;;								## 19
	c0    ldw $r0.9 = 8[$r0.9]   ## bblock 5, line 110, t23, t3
;;								## 20
;;								## 21
	c0    cmpeq $b0.0 = $r0.9, $r0.2   ## bblock 5, line 110,  t47(I1),  t23,  1920(SI32)
;;								## 22
	c0    brf $b0.0, L11?3   ## bblock 5, line 110,  t47(I1)
;;								## 23
.call sim_puts, caller, arg($r0.3:u32), ret()
	c0    call $l0.0 = sim_puts   ## bblock 11, line 111,  raddr(sim_puts)(P32),  addr(_?1STRINGVAR.12)(P32)
;;								## 24
L12?3:
	c0    mov $r0.3 = (_?1STRINGPACKET.14 + 0)   ## addr(_?1STRINGVAR.14)(P32)
	c0    mov $r0.2 = 1920   ## 1920(SI32)
	c0    ldw $r0.9 = 0x324[$r0.1]  ## restore ## t3
;;								## 25
;;								## 26
	c0    ldw $r0.9 = 12[$r0.9]   ## bblock 7, line 115, t28, t3
;;								## 27
;;								## 28
	c0    cmpeq $b0.0 = $r0.9, $r0.2   ## bblock 7, line 115,  t48(I1),  t28,  1920(SI32)
;;								## 29
	c0    brf $b0.0, L13?3   ## bblock 7, line 115,  t48(I1)
;;								## 30
.call sim_puts, caller, arg($r0.3:u32), ret()
	c0    call $l0.0 = sim_puts   ## bblock 10, line 116,  raddr(sim_puts)(P32),  addr(_?1STRINGVAR.14)(P32)
;;								## 31
L14?3:
	c0    mov $r0.3 = 1   ## 1(SI32)
	c0    ldw $l0.0 = 0x320[$r0.1]  ## restore ## t33
;;								## 32
;;								## 33
.return ret($r0.3:s32)
	c0    return $r0.1 = $r0.1, (0x340), $l0.0   ## bblock 9, line 121,  t34,  ?2.6?2auto_size(I32),  t33
;;								## 34
.trace 4
L13?3:
.call sim_puts, caller, arg($r0.3:u32), ret()
	c0    call $l0.0 = sim_puts   ## bblock 8, line 118,  raddr(sim_puts)(P32),  addr(_?1STRINGVAR.15)(P32)
	c0    mov $r0.3 = (_?1STRINGPACKET.15 + 0)   ## addr(_?1STRINGVAR.15)(P32)
	      ## goto
;;
	c0    goto L14?3 ## goto
;;								## 0
.trace 3
L11?3:
.call sim_puts, caller, arg($r0.3:u32), ret()
	c0    call $l0.0 = sim_puts   ## bblock 6, line 113,  raddr(sim_puts)(P32),  addr(_?1STRINGVAR.13)(P32)
	c0    mov $r0.3 = (_?1STRINGPACKET.13 + 0)   ## addr(_?1STRINGVAR.13)(P32)
	      ## goto
;;
	c0    goto L12?3 ## goto
;;								## 0
.trace 5
L9?3:
.call sim_puts, caller, arg($r0.3:u32), ret()
	c0    call $l0.0 = sim_puts   ## bblock 4, line 108,  raddr(sim_puts)(P32),  addr(_?1STRINGVAR.11)(P32)
	c0    mov $r0.3 = (_?1STRINGPACKET.11 + 0)   ## addr(_?1STRINGVAR.11)(P32)
	      ## goto
;;
	c0    goto L10?3 ## goto
;;								## 0
.trace 2
L7?3:
.call sim_puts, caller, arg($r0.3:u32), ret()
	c0    call $l0.0 = sim_puts   ## bblock 2, line 103,  raddr(sim_puts)(P32),  addr(_?1STRINGVAR.9)(P32)
	c0    mov $r0.3 = (_?1STRINGPACKET.9 + 0)   ## addr(_?1STRINGVAR.9)(P32)
	      ## goto
;;
	c0    goto L8?3 ## goto
;;								## 0
.endp
.section .bss
.section .data
.skip 3
_?1STRINGPACKET.8:
    .data1 67
    .data1 111
    .data1 109
    .data1 112
    .data1 117
    .data1 116
    .data1 97
    .data1 116
    .data1 105
    .data1 111
    .data1 110
    .data1 32
    .data1 49
    .data1 32
    .data1 99
    .data1 111
    .data1 114
    .data1 114
    .data1 101
    .data1 99
    .data1 116
    .data1 10
    .data1 0
.skip 1
_?1STRINGPACKET.10:
    .data1 67
    .data1 111
    .data1 109
    .data1 112
    .data1 117
    .data1 116
    .data1 97
    .data1 116
    .data1 105
    .data1 111
    .data1 110
    .data1 32
    .data1 50
    .data1 32
    .data1 99
    .data1 111
    .data1 114
    .data1 114
    .data1 101
    .data1 99
    .data1 116
    .data1 10
    .data1 0
.skip 1
_?1STRINGPACKET.12:
    .data1 67
    .data1 111
    .data1 109
    .data1 112
    .data1 117
    .data1 116
    .data1 97
    .data1 116
    .data1 105
    .data1 111
    .data1 110
    .data1 32
    .data1 51
    .data1 32
    .data1 99
    .data1 111
    .data1 114
    .data1 114
    .data1 101
    .data1 99
    .data1 116
    .data1 10
    .data1 0
.skip 1
_?1STRINGPACKET.14:
    .data1 67
    .data1 111
    .data1 109
    .data1 112
    .data1 117
    .data1 116
    .data1 97
    .data1 116
    .data1 105
    .data1 111
    .data1 110
    .data1 32
    .data1 52
    .data1 32
    .data1 99
    .data1 111
    .data1 114
    .data1 114
    .data1 101
    .data1 99
    .data1 116
    .data1 10
    .data1 0
.skip 1
_?1STRINGPACKET.9:
    .data1 67
    .data1 111
    .data1 109
    .data1 112
    .data1 117
    .data1 116
    .data1 97
    .data1 116
    .data1 105
    .data1 111
    .data1 110
    .data1 32
    .data1 49
    .data1 32
    .data1 73
    .data1 78
    .data1 67
    .data1 79
    .data1 82
    .data1 82
    .data1 69
    .data1 67
    .data1 84
    .data1 10
    .data1 0
.skip 3
_?1STRINGPACKET.11:
    .data1 67
    .data1 111
    .data1 109
    .data1 112
    .data1 117
    .data1 116
    .data1 97
    .data1 116
    .data1 105
    .data1 111
    .data1 110
    .data1 32
    .data1 50
    .data1 32
    .data1 73
    .data1 78
    .data1 67
    .data1 79
    .data1 82
    .data1 82
    .data1 69
    .data1 67
    .data1 84
    .data1 10
    .data1 0
.skip 3
_?1STRINGPACKET.13:
    .data1 67
    .data1 111
    .data1 109
    .data1 112
    .data1 117
    .data1 116
    .data1 97
    .data1 116
    .data1 105
    .data1 111
    .data1 110
    .data1 32
    .data1 51
    .data1 32
    .data1 73
    .data1 78
    .data1 67
    .data1 79
    .data1 82
    .data1 82
    .data1 69
    .data1 67
    .data1 84
    .data1 10
    .data1 0
.skip 3
_?1STRINGPACKET.15:
    .data1 67
    .data1 111
    .data1 109
    .data1 112
    .data1 117
    .data1 116
    .data1 97
    .data1 116
    .data1 105
    .data1 111
    .data1 110
    .data1 32
    .data1 52
    .data1 32
    .data1 73
    .data1 78
    .data1 67
    .data1 79
    .data1 82
    .data1 82
    .data1 69
    .data1 67
    .data1 84
    .data1 10
    .data1 0
.equ ?2.6?2scratch.0, 0x0
.equ _?1PACKET.4, 0x10
.equ _?1PACKET.5, 0x110
.equ _?1PACKET.6, 0x210
.equ _?1PACKET.7, 0x310
.equ ?2.6?2ras_p, 0x320
.equ ?2.6?2spill_p, 0x324
.section .data
.section .text
.equ ?2.6?2auto_size, 0x340
 ## End main
.section .bss
pix0::
    .skip 256
.section .data
.skip 3
fenc::
    .data1 0
    .data1 1
    .data1 2
    .data1 3
    .data1 4
    .data1 5
    .data1 6
    .data1 7
    .data1 8
    .data1 9
    .data1 10
    .data1 11
    .data1 12
    .data1 13
    .data1 14
    .data1 15
    .data1 0
    .data1 1
    .data1 2
    .data1 3
    .data1 4
    .data1 5
    .data1 6
    .data1 7
    .data1 8
    .data1 9
    .data1 10
    .data1 11
    .data1 12
    .data1 13
    .data1 14
    .data1 15
    .data1 0
    .data1 1
    .data1 2
    .data1 3
    .data1 4
    .data1 5
    .data1 6
    .data1 7
    .data1 8
    .data1 9
    .data1 10
    .data1 11
    .data1 12
    .data1 13
    .data1 14
    .data1 15
    .data1 0
    .data1 1
    .data1 2
    .data1 3
    .data1 4
    .data1 5
    .data1 6
    .data1 7
    .data1 8
    .data1 9
    .data1 10
    .data1 11
    .data1 12
    .data1 13
    .data1 14
    .data1 15
    .data1 0
    .data1 1
    .data1 2
    .data1 3
    .data1 4
    .data1 5
    .data1 6
    .data1 7
    .data1 8
    .data1 9
    .data1 10
    .data1 11
    .data1 12
    .data1 13
    .data1 14
    .data1 15
    .data1 0
    .data1 1
    .data1 2
    .data1 3
    .data1 4
    .data1 5
    .data1 6
    .data1 7
    .data1 8
    .data1 9
    .data1 10
    .data1 11
    .data1 12
    .data1 13
    .data1 14
    .data1 15
    .data1 0
    .data1 1
    .data1 2
    .data1 3
    .data1 4
    .data1 5
    .data1 6
    .data1 7
    .data1 8
    .data1 9
    .data1 10
    .data1 11
    .data1 12
    .data1 13
    .data1 14
    .data1 15
    .data1 0
    .data1 1
    .data1 2
    .data1 3
    .data1 4
    .data1 5
    .data1 6
    .data1 7
    .data1 8
    .data1 9
    .data1 10
    .data1 11
    .data1 12
    .data1 13
    .data1 14
    .data1 15
    .data1 0
    .data1 1
    .data1 2
    .data1 3
    .data1 4
    .data1 5
    .data1 6
    .data1 7
    .data1 8
    .data1 9
    .data1 10
    .data1 11
    .data1 12
    .data1 13
    .data1 14
    .data1 15
    .data1 0
    .data1 1
    .data1 2
    .data1 3
    .data1 4
    .data1 5
    .data1 6
    .data1 7
    .data1 8
    .data1 9
    .data1 10
    .data1 11
    .data1 12
    .data1 13
    .data1 14
    .data1 15
    .data1 0
    .data1 1
    .data1 2
    .data1 3
    .data1 4
    .data1 5
    .data1 6
    .data1 7
    .data1 8
    .data1 9
    .data1 10
    .data1 11
    .data1 12
    .data1 13
    .data1 14
    .data1 15
    .data1 0
    .data1 1
    .data1 2
    .data1 3
    .data1 4
    .data1 5
    .data1 6
    .data1 7
    .data1 8
    .data1 9
    .data1 10
    .data1 11
    .data1 12
    .data1 13
    .data1 14
    .data1 15
    .data1 0
    .data1 1
    .data1 2
    .data1 3
    .data1 4
    .data1 5
    .data1 6
    .data1 7
    .data1 8
    .data1 9
    .data1 10
    .data1 11
    .data1 12
    .data1 13
    .data1 14
    .data1 15
    .data1 0
    .data1 1
    .data1 2
    .data1 3
    .data1 4
    .data1 5
    .data1 6
    .data1 7
    .data1 8
    .data1 9
    .data1 10
    .data1 11
    .data1 12
    .data1 13
    .data1 14
    .data1 15
    .data1 0
    .data1 1
    .data1 2
    .data1 3
    .data1 4
    .data1 5
    .data1 6
    .data1 7
    .data1 8
    .data1 9
    .data1 10
    .data1 11
    .data1 12
    .data1 13
    .data1 14
    .data1 15
    .data1 0
    .data1 1
    .data1 2
    .data1 3
    .data1 4
    .data1 5
    .data1 6
    .data1 7
    .data1 8
    .data1 9
    .data1 10
    .data1 11
    .data1 12
    .data1 13
    .data1 14
    .data1 15
.section .data
.section .text
.import abs
.type abs,@function
