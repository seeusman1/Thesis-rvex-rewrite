 // Target: VEX 1 cluster (big endian)
.comment ""
.comment "Copyright (C) 1990-2010 Hewlett-Packard Company"
.comment "VEX C compiler version 3.43 (20110131 release)"
.comment ""
.comment "-dir /data/designs/rvex-rewrite/tools/vex-3.43 -I./src -fno-xnop -fexpand-div -fmm=./pipe_1_8_fw.mm -S"
.sversion 3.43
.rta 2
.section .bss
.align 32
.section .data
.align 32
 // Begin __divuw
.section .text
.proc
.entry caller, sp=$r0.1, rl=$l0.0, asize=0, arg($r0.3:u32,$r0.4:u32)
__divuw::
_i_udiv::
.trace 1
	      // auto_size == 0
	c0    cmplt $r0.2 = $r0.4, $r0.0   // bblock 0, line 21,  t21,  t1,  0(I32)
	c0    cmpgeu $r0.5 = $r0.3, $r0.4   // bblock 0, line 21,  t27,  t0,  t1
	c0    mtb $b0.0 = $r0.0   // 0(I32)
;;								// 0
	c0    shru $r0.4 = $r0.4, $r0.2   // bblock 0, line 21,  t19,  t1,  t21
	c0    shru $r0.3 = $r0.3, $r0.2   // bblock 0, line 21,  t18,  t0,  t21
	c0    mtb $b0.1 = $r0.2   // t21
;;								// 1
	c0    addcg $r0.2, $b0.2 = $r0.3, $r0.3, $b0.0   // bblock 0, line 21,  t18,  t22(I1),  t18,  t18,  0(I32)
;;								// 2
	c0    divs $r0.2, $b0.2 = $r0.0, $r0.4, $b0.2   // bblock 0, line 21,  t20,  t22(I1),  0(I32),  t19,  t22(I1)
	c0    addcg $r0.6, $b0.3 = $r0.2, $r0.2, $b0.0   // bblock 0, line 21,  t18,  t23(I1),  t18,  t18,  0(I32)
;;								// 3
	c0    divs $r0.2, $b0.3 = $r0.2, $r0.4, $b0.3   // bblock 0, line 21,  t20,  t23(I1),  t20,  t19,  t23(I1)
	c0    addcg $r0.7, $b0.2 = $r0.6, $r0.6, $b0.2   // bblock 0, line 21,  t18,  t22(I1),  t18,  t18,  t22(I1)
;;								// 4
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.4, $b0.2   // bblock 0, line 21,  t20,  t22(I1),  t20,  t19,  t22(I1)
	c0    addcg $r0.6, $b0.3 = $r0.7, $r0.7, $b0.3   // bblock 0, line 21,  t18,  t23(I1),  t18,  t18,  t23(I1)
;;								// 5
	c0    divs $r0.2, $b0.3 = $r0.2, $r0.4, $b0.3   // bblock 0, line 21,  t20,  t23(I1),  t20,  t19,  t23(I1)
	c0    addcg $r0.7, $b0.2 = $r0.6, $r0.6, $b0.2   // bblock 0, line 21,  t18,  t22(I1),  t18,  t18,  t22(I1)
;;								// 6
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.4, $b0.2   // bblock 0, line 21,  t20,  t22(I1),  t20,  t19,  t22(I1)
	c0    addcg $r0.6, $b0.3 = $r0.7, $r0.7, $b0.3   // bblock 0, line 21,  t18,  t23(I1),  t18,  t18,  t23(I1)
;;								// 7
	c0    divs $r0.2, $b0.3 = $r0.2, $r0.4, $b0.3   // bblock 0, line 21,  t20,  t23(I1),  t20,  t19,  t23(I1)
	c0    addcg $r0.7, $b0.2 = $r0.6, $r0.6, $b0.2   // bblock 0, line 21,  t18,  t22(I1),  t18,  t18,  t22(I1)
;;								// 8
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.4, $b0.2   // bblock 0, line 21,  t20,  t22(I1),  t20,  t19,  t22(I1)
	c0    addcg $r0.6, $b0.3 = $r0.7, $r0.7, $b0.3   // bblock 0, line 21,  t18,  t23(I1),  t18,  t18,  t23(I1)
;;								// 9
	c0    divs $r0.2, $b0.3 = $r0.2, $r0.4, $b0.3   // bblock 0, line 21,  t20,  t23(I1),  t20,  t19,  t23(I1)
	c0    addcg $r0.7, $b0.2 = $r0.6, $r0.6, $b0.2   // bblock 0, line 21,  t18,  t22(I1),  t18,  t18,  t22(I1)
;;								// 10
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.4, $b0.2   // bblock 0, line 21,  t20,  t22(I1),  t20,  t19,  t22(I1)
	c0    addcg $r0.6, $b0.3 = $r0.7, $r0.7, $b0.3   // bblock 0, line 21,  t18,  t23(I1),  t18,  t18,  t23(I1)
;;								// 11
	c0    divs $r0.2, $b0.3 = $r0.2, $r0.4, $b0.3   // bblock 0, line 21,  t20,  t23(I1),  t20,  t19,  t23(I1)
	c0    addcg $r0.7, $b0.2 = $r0.6, $r0.6, $b0.2   // bblock 0, line 21,  t18,  t22(I1),  t18,  t18,  t22(I1)
;;								// 12
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.4, $b0.2   // bblock 0, line 21,  t20,  t22(I1),  t20,  t19,  t22(I1)
	c0    addcg $r0.6, $b0.3 = $r0.7, $r0.7, $b0.3   // bblock 0, line 21,  t18,  t23(I1),  t18,  t18,  t23(I1)
;;								// 13
	c0    divs $r0.2, $b0.3 = $r0.2, $r0.4, $b0.3   // bblock 0, line 21,  t20,  t23(I1),  t20,  t19,  t23(I1)
	c0    addcg $r0.7, $b0.2 = $r0.6, $r0.6, $b0.2   // bblock 0, line 21,  t18,  t22(I1),  t18,  t18,  t22(I1)
;;								// 14
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.4, $b0.2   // bblock 0, line 21,  t20,  t22(I1),  t20,  t19,  t22(I1)
	c0    addcg $r0.6, $b0.3 = $r0.7, $r0.7, $b0.3   // bblock 0, line 21,  t18,  t23(I1),  t18,  t18,  t23(I1)
;;								// 15
	c0    divs $r0.2, $b0.3 = $r0.2, $r0.4, $b0.3   // bblock 0, line 21,  t20,  t23(I1),  t20,  t19,  t23(I1)
	c0    addcg $r0.7, $b0.2 = $r0.6, $r0.6, $b0.2   // bblock 0, line 21,  t18,  t22(I1),  t18,  t18,  t22(I1)
;;								// 16
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.4, $b0.2   // bblock 0, line 21,  t20,  t22(I1),  t20,  t19,  t22(I1)
	c0    addcg $r0.6, $b0.3 = $r0.7, $r0.7, $b0.3   // bblock 0, line 21,  t18,  t23(I1),  t18,  t18,  t23(I1)
;;								// 17
	c0    divs $r0.2, $b0.3 = $r0.2, $r0.4, $b0.3   // bblock 0, line 21,  t20,  t23(I1),  t20,  t19,  t23(I1)
	c0    addcg $r0.7, $b0.2 = $r0.6, $r0.6, $b0.2   // bblock 0, line 21,  t18,  t22(I1),  t18,  t18,  t22(I1)
;;								// 18
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.4, $b0.2   // bblock 0, line 21,  t20,  t22(I1),  t20,  t19,  t22(I1)
	c0    addcg $r0.6, $b0.3 = $r0.7, $r0.7, $b0.3   // bblock 0, line 21,  t18,  t23(I1),  t18,  t18,  t23(I1)
;;								// 19
	c0    divs $r0.2, $b0.3 = $r0.2, $r0.4, $b0.3   // bblock 0, line 21,  t20,  t23(I1),  t20,  t19,  t23(I1)
	c0    addcg $r0.7, $b0.2 = $r0.6, $r0.6, $b0.2   // bblock 0, line 21,  t18,  t22(I1),  t18,  t18,  t22(I1)
;;								// 20
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.4, $b0.2   // bblock 0, line 21,  t20,  t22(I1),  t20,  t19,  t22(I1)
	c0    addcg $r0.6, $b0.3 = $r0.7, $r0.7, $b0.3   // bblock 0, line 21,  t18,  t23(I1),  t18,  t18,  t23(I1)
;;								// 21
	c0    divs $r0.2, $b0.3 = $r0.2, $r0.4, $b0.3   // bblock 0, line 21,  t20,  t23(I1),  t20,  t19,  t23(I1)
	c0    addcg $r0.7, $b0.2 = $r0.6, $r0.6, $b0.2   // bblock 0, line 21,  t18,  t22(I1),  t18,  t18,  t22(I1)
;;								// 22
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.4, $b0.2   // bblock 0, line 21,  t20,  t22(I1),  t20,  t19,  t22(I1)
	c0    addcg $r0.6, $b0.3 = $r0.7, $r0.7, $b0.3   // bblock 0, line 21,  t18,  t23(I1),  t18,  t18,  t23(I1)
;;								// 23
	c0    divs $r0.2, $b0.3 = $r0.2, $r0.4, $b0.3   // bblock 0, line 21,  t20,  t23(I1),  t20,  t19,  t23(I1)
	c0    addcg $r0.7, $b0.2 = $r0.6, $r0.6, $b0.2   // bblock 0, line 21,  t18,  t22(I1),  t18,  t18,  t22(I1)
;;								// 24
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.4, $b0.2   // bblock 0, line 21,  t20,  t22(I1),  t20,  t19,  t22(I1)
	c0    addcg $r0.6, $b0.3 = $r0.7, $r0.7, $b0.3   // bblock 0, line 21,  t18,  t23(I1),  t18,  t18,  t23(I1)
;;								// 25
	c0    divs $r0.2, $b0.3 = $r0.2, $r0.4, $b0.3   // bblock 0, line 21,  t20,  t23(I1),  t20,  t19,  t23(I1)
	c0    addcg $r0.7, $b0.2 = $r0.6, $r0.6, $b0.2   // bblock 0, line 21,  t18,  t22(I1),  t18,  t18,  t22(I1)
;;								// 26
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.4, $b0.2   // bblock 0, line 21,  t20,  t22(I1),  t20,  t19,  t22(I1)
	c0    addcg $r0.6, $b0.3 = $r0.7, $r0.7, $b0.3   // bblock 0, line 21,  t18,  t23(I1),  t18,  t18,  t23(I1)
;;								// 27
	c0    divs $r0.2, $b0.3 = $r0.2, $r0.4, $b0.3   // bblock 0, line 21,  t20,  t23(I1),  t20,  t19,  t23(I1)
	c0    addcg $r0.7, $b0.2 = $r0.6, $r0.6, $b0.2   // bblock 0, line 21,  t18,  t22(I1),  t18,  t18,  t22(I1)
;;								// 28
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.4, $b0.2   // bblock 0, line 21,  t20,  t22(I1),  t20,  t19,  t22(I1)
	c0    addcg $r0.6, $b0.3 = $r0.7, $r0.7, $b0.3   // bblock 0, line 21,  t18,  t23(I1),  t18,  t18,  t23(I1)
;;								// 29
	c0    divs $r0.2, $b0.3 = $r0.2, $r0.4, $b0.3   // bblock 0, line 21,  t20,  t23(I1),  t20,  t19,  t23(I1)
	c0    addcg $r0.7, $b0.2 = $r0.6, $r0.6, $b0.2   // bblock 0, line 21,  t18,  t22(I1),  t18,  t18,  t22(I1)
;;								// 30
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.4, $b0.2   // bblock 0, line 21,  t20,  t22(I1),  t20,  t19,  t22(I1)
	c0    addcg $r0.6, $b0.3 = $r0.7, $r0.7, $b0.3   // bblock 0, line 21,  t18,  t23(I1),  t18,  t18,  t23(I1)
;;								// 31
	c0    divs $r0.2, $b0.3 = $r0.2, $r0.4, $b0.3   // bblock 0, line 21,  t20,  t23(I1),  t20,  t19,  t23(I1)
	c0    addcg $r0.7, $b0.2 = $r0.6, $r0.6, $b0.2   // bblock 0, line 21,  t18,  t22(I1),  t18,  t18,  t22(I1)
;;								// 32
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.4, $b0.2   // bblock 0, line 21,  t20,  t22(I1),  t20,  t19,  t22(I1)
	c0    addcg $r0.6, $b0.3 = $r0.7, $r0.7, $b0.3   // bblock 0, line 21,  t18,  t23(I1),  t18,  t18,  t23(I1)
;;								// 33
	c0    divs $r0.2, $b0.3 = $r0.2, $r0.4, $b0.3   // bblock 0, line 21,  t20,  t23(I1),  t20,  t19,  t23(I1)
	c0    addcg $r0.7, $b0.2 = $r0.6, $r0.6, $b0.2   // bblock 0, line 21,  t18,  t22(I1),  t18,  t18,  t22(I1)
;;								// 34
	c0    addcg $r0.4, $b0.3 = $r0.7, $r0.7, $b0.3   // bblock 0, line 21,  t18,  t23(I1),  t18,  t18,  t23(I1)
	c0    cmpge $r0.2 = $r0.2, $r0.0   // bblock 0, line 21,  t24,  t20,  0(I32)
;;								// 35
	c0    orc $r0.4 = $r0.4, $r0.0   // bblock 0, line 21,  t25,  t18,  0(I32)
;;								// 36
	c0    sh1add $r0.4 = $r0.4, $r0.2   // bblock 0, line 21,  t26,  t25,  t24
;;								// 37
.return ret($r0.3:s32)
	c0    slct $r0.3 = $b0.1, $r0.5, $r0.4   // bblock 0, line 21,  t2,  t21,  t27,  t26
	c0    return $r0.1 = $r0.1, (0x0), $l0.0   // bblock 0, line 21,  t4,  ?2.3?2auto_size(I32),  t3
;;								// 38
.endp
.section .bss
.section .data
.section .data
.section .text
.equ ?2.3?2auto_size, 0x0
 // End __divuw
 // Begin __divw
.section .text
.proc
.entry caller, sp=$r0.1, rl=$l0.0, asize=0, arg($r0.3:s32,$r0.4:s32)
__divw::
_i_div::
.trace 1
	      // auto_size == 0
	c0    cmplt $r0.6 = $r0.4, $r0.0   // bblock 0, line 31,  t21,  t1,  0(I32)
	c0    sub $r0.7 = $r0.0, $r0.4   // bblock 0, line 31,  t19,  0(I32),  t1
	c0    cmplt $r0.2 = $r0.3, $r0.0   // bblock 0, line 31,  t23,  t0,  0(I32)
	c0    sub $r0.5 = $r0.0, $r0.3   // bblock 0, line 31,  t18,  0(I32),  t0
	c0    mtb $b0.0 = $r0.0   // 0(I32)
;;								// 0
	c0    cmpeq $b0.3 = $r0.6, $r0.2   // bblock 0, line 31,  t30,  t21,  t23
	c0    mtb $b0.1 = $r0.2   // t23
	c0    mtb $b0.2 = $r0.6   // t21
;;								// 1
	c0    slct $r0.7 = $b0.2, $r0.7, $r0.4   // bblock 0, line 31,  t22,  t21,  t19,  t1
	c0    slct $r0.5 = $b0.1, $r0.5, $r0.3   // bblock 0, line 31,  t24,  t23,  t18,  t0
;;								// 2
	c0    addcg $r0.2, $b0.1 = $r0.5, $r0.5, $b0.0   // bblock 0, line 31,  t24,  t25(I1),  t24,  t24,  0(I32)
;;								// 3
	c0    divs $r0.2, $b0.1 = $r0.0, $r0.7, $b0.1   // bblock 0, line 31,  t20,  t25(I1),  0(I32),  t22,  t25(I1)
	c0    addcg $r0.5, $b0.2 = $r0.2, $r0.2, $b0.0   // bblock 0, line 31,  t24,  t26(I1),  t24,  t24,  0(I32)
;;								// 4
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.7, $b0.2   // bblock 0, line 31,  t20,  t26(I1),  t20,  t22,  t26(I1)
	c0    addcg $r0.4, $b0.1 = $r0.5, $r0.5, $b0.1   // bblock 0, line 31,  t24,  t25(I1),  t24,  t24,  t25(I1)
;;								// 5
	c0    divs $r0.2, $b0.1 = $r0.2, $r0.7, $b0.1   // bblock 0, line 31,  t20,  t25(I1),  t20,  t22,  t25(I1)
	c0    addcg $r0.5, $b0.2 = $r0.4, $r0.4, $b0.2   // bblock 0, line 31,  t24,  t26(I1),  t24,  t24,  t26(I1)
;;								// 6
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.7, $b0.2   // bblock 0, line 31,  t20,  t26(I1),  t20,  t22,  t26(I1)
	c0    addcg $r0.4, $b0.1 = $r0.5, $r0.5, $b0.1   // bblock 0, line 31,  t24,  t25(I1),  t24,  t24,  t25(I1)
;;								// 7
	c0    divs $r0.2, $b0.1 = $r0.2, $r0.7, $b0.1   // bblock 0, line 31,  t20,  t25(I1),  t20,  t22,  t25(I1)
	c0    addcg $r0.5, $b0.2 = $r0.4, $r0.4, $b0.2   // bblock 0, line 31,  t24,  t26(I1),  t24,  t24,  t26(I1)
;;								// 8
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.7, $b0.2   // bblock 0, line 31,  t20,  t26(I1),  t20,  t22,  t26(I1)
	c0    addcg $r0.4, $b0.1 = $r0.5, $r0.5, $b0.1   // bblock 0, line 31,  t24,  t25(I1),  t24,  t24,  t25(I1)
;;								// 9
	c0    divs $r0.2, $b0.1 = $r0.2, $r0.7, $b0.1   // bblock 0, line 31,  t20,  t25(I1),  t20,  t22,  t25(I1)
	c0    addcg $r0.5, $b0.2 = $r0.4, $r0.4, $b0.2   // bblock 0, line 31,  t24,  t26(I1),  t24,  t24,  t26(I1)
;;								// 10
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.7, $b0.2   // bblock 0, line 31,  t20,  t26(I1),  t20,  t22,  t26(I1)
	c0    addcg $r0.4, $b0.1 = $r0.5, $r0.5, $b0.1   // bblock 0, line 31,  t24,  t25(I1),  t24,  t24,  t25(I1)
;;								// 11
	c0    divs $r0.2, $b0.1 = $r0.2, $r0.7, $b0.1   // bblock 0, line 31,  t20,  t25(I1),  t20,  t22,  t25(I1)
	c0    addcg $r0.5, $b0.2 = $r0.4, $r0.4, $b0.2   // bblock 0, line 31,  t24,  t26(I1),  t24,  t24,  t26(I1)
;;								// 12
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.7, $b0.2   // bblock 0, line 31,  t20,  t26(I1),  t20,  t22,  t26(I1)
	c0    addcg $r0.4, $b0.1 = $r0.5, $r0.5, $b0.1   // bblock 0, line 31,  t24,  t25(I1),  t24,  t24,  t25(I1)
;;								// 13
	c0    divs $r0.2, $b0.1 = $r0.2, $r0.7, $b0.1   // bblock 0, line 31,  t20,  t25(I1),  t20,  t22,  t25(I1)
	c0    addcg $r0.5, $b0.2 = $r0.4, $r0.4, $b0.2   // bblock 0, line 31,  t24,  t26(I1),  t24,  t24,  t26(I1)
;;								// 14
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.7, $b0.2   // bblock 0, line 31,  t20,  t26(I1),  t20,  t22,  t26(I1)
	c0    addcg $r0.4, $b0.1 = $r0.5, $r0.5, $b0.1   // bblock 0, line 31,  t24,  t25(I1),  t24,  t24,  t25(I1)
;;								// 15
	c0    divs $r0.2, $b0.1 = $r0.2, $r0.7, $b0.1   // bblock 0, line 31,  t20,  t25(I1),  t20,  t22,  t25(I1)
	c0    addcg $r0.5, $b0.2 = $r0.4, $r0.4, $b0.2   // bblock 0, line 31,  t24,  t26(I1),  t24,  t24,  t26(I1)
;;								// 16
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.7, $b0.2   // bblock 0, line 31,  t20,  t26(I1),  t20,  t22,  t26(I1)
	c0    addcg $r0.4, $b0.1 = $r0.5, $r0.5, $b0.1   // bblock 0, line 31,  t24,  t25(I1),  t24,  t24,  t25(I1)
;;								// 17
	c0    divs $r0.2, $b0.1 = $r0.2, $r0.7, $b0.1   // bblock 0, line 31,  t20,  t25(I1),  t20,  t22,  t25(I1)
	c0    addcg $r0.5, $b0.2 = $r0.4, $r0.4, $b0.2   // bblock 0, line 31,  t24,  t26(I1),  t24,  t24,  t26(I1)
;;								// 18
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.7, $b0.2   // bblock 0, line 31,  t20,  t26(I1),  t20,  t22,  t26(I1)
	c0    addcg $r0.4, $b0.1 = $r0.5, $r0.5, $b0.1   // bblock 0, line 31,  t24,  t25(I1),  t24,  t24,  t25(I1)
;;								// 19
	c0    divs $r0.2, $b0.1 = $r0.2, $r0.7, $b0.1   // bblock 0, line 31,  t20,  t25(I1),  t20,  t22,  t25(I1)
	c0    addcg $r0.5, $b0.2 = $r0.4, $r0.4, $b0.2   // bblock 0, line 31,  t24,  t26(I1),  t24,  t24,  t26(I1)
;;								// 20
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.7, $b0.2   // bblock 0, line 31,  t20,  t26(I1),  t20,  t22,  t26(I1)
	c0    addcg $r0.4, $b0.1 = $r0.5, $r0.5, $b0.1   // bblock 0, line 31,  t24,  t25(I1),  t24,  t24,  t25(I1)
;;								// 21
	c0    divs $r0.2, $b0.1 = $r0.2, $r0.7, $b0.1   // bblock 0, line 31,  t20,  t25(I1),  t20,  t22,  t25(I1)
	c0    addcg $r0.5, $b0.2 = $r0.4, $r0.4, $b0.2   // bblock 0, line 31,  t24,  t26(I1),  t24,  t24,  t26(I1)
;;								// 22
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.7, $b0.2   // bblock 0, line 31,  t20,  t26(I1),  t20,  t22,  t26(I1)
	c0    addcg $r0.4, $b0.1 = $r0.5, $r0.5, $b0.1   // bblock 0, line 31,  t24,  t25(I1),  t24,  t24,  t25(I1)
;;								// 23
	c0    divs $r0.2, $b0.1 = $r0.2, $r0.7, $b0.1   // bblock 0, line 31,  t20,  t25(I1),  t20,  t22,  t25(I1)
	c0    addcg $r0.5, $b0.2 = $r0.4, $r0.4, $b0.2   // bblock 0, line 31,  t24,  t26(I1),  t24,  t24,  t26(I1)
;;								// 24
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.7, $b0.2   // bblock 0, line 31,  t20,  t26(I1),  t20,  t22,  t26(I1)
	c0    addcg $r0.4, $b0.1 = $r0.5, $r0.5, $b0.1   // bblock 0, line 31,  t24,  t25(I1),  t24,  t24,  t25(I1)
;;								// 25
	c0    divs $r0.2, $b0.1 = $r0.2, $r0.7, $b0.1   // bblock 0, line 31,  t20,  t25(I1),  t20,  t22,  t25(I1)
	c0    addcg $r0.5, $b0.2 = $r0.4, $r0.4, $b0.2   // bblock 0, line 31,  t24,  t26(I1),  t24,  t24,  t26(I1)
;;								// 26
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.7, $b0.2   // bblock 0, line 31,  t20,  t26(I1),  t20,  t22,  t26(I1)
	c0    addcg $r0.4, $b0.1 = $r0.5, $r0.5, $b0.1   // bblock 0, line 31,  t24,  t25(I1),  t24,  t24,  t25(I1)
;;								// 27
	c0    divs $r0.2, $b0.1 = $r0.2, $r0.7, $b0.1   // bblock 0, line 31,  t20,  t25(I1),  t20,  t22,  t25(I1)
	c0    addcg $r0.5, $b0.2 = $r0.4, $r0.4, $b0.2   // bblock 0, line 31,  t24,  t26(I1),  t24,  t24,  t26(I1)
;;								// 28
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.7, $b0.2   // bblock 0, line 31,  t20,  t26(I1),  t20,  t22,  t26(I1)
	c0    addcg $r0.4, $b0.1 = $r0.5, $r0.5, $b0.1   // bblock 0, line 31,  t24,  t25(I1),  t24,  t24,  t25(I1)
;;								// 29
	c0    divs $r0.2, $b0.1 = $r0.2, $r0.7, $b0.1   // bblock 0, line 31,  t20,  t25(I1),  t20,  t22,  t25(I1)
	c0    addcg $r0.5, $b0.2 = $r0.4, $r0.4, $b0.2   // bblock 0, line 31,  t24,  t26(I1),  t24,  t24,  t26(I1)
;;								// 30
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.7, $b0.2   // bblock 0, line 31,  t20,  t26(I1),  t20,  t22,  t26(I1)
	c0    addcg $r0.4, $b0.1 = $r0.5, $r0.5, $b0.1   // bblock 0, line 31,  t24,  t25(I1),  t24,  t24,  t25(I1)
;;								// 31
	c0    divs $r0.2, $b0.1 = $r0.2, $r0.7, $b0.1   // bblock 0, line 31,  t20,  t25(I1),  t20,  t22,  t25(I1)
	c0    addcg $r0.5, $b0.2 = $r0.4, $r0.4, $b0.2   // bblock 0, line 31,  t24,  t26(I1),  t24,  t24,  t26(I1)
;;								// 32
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.7, $b0.2   // bblock 0, line 31,  t20,  t26(I1),  t20,  t22,  t26(I1)
	c0    addcg $r0.4, $b0.1 = $r0.5, $r0.5, $b0.1   // bblock 0, line 31,  t24,  t25(I1),  t24,  t24,  t25(I1)
;;								// 33
	c0    divs $r0.2, $b0.1 = $r0.2, $r0.7, $b0.1   // bblock 0, line 31,  t20,  t25(I1),  t20,  t22,  t25(I1)
	c0    addcg $r0.5, $b0.2 = $r0.4, $r0.4, $b0.2   // bblock 0, line 31,  t24,  t26(I1),  t24,  t24,  t26(I1)
;;								// 34
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.7, $b0.2   // bblock 0, line 31,  t20,  t26(I1),  t20,  t22,  t26(I1)
	c0    addcg $r0.4, $b0.1 = $r0.5, $r0.5, $b0.1   // bblock 0, line 31,  t24,  t25(I1),  t24,  t24,  t25(I1)
;;								// 35
	c0    addcg $r0.5, $b0.2 = $r0.4, $r0.4, $b0.2   // bblock 0, line 31,  t24,  t26(I1),  t24,  t24,  t26(I1)
	c0    cmpge $r0.2 = $r0.2, $r0.0   // bblock 0, line 31,  t27,  t20,  0(I32)
;;								// 36
	c0    orc $r0.5 = $r0.5, $r0.0   // bblock 0, line 31,  t28,  t24,  0(I32)
;;								// 37
	c0    sh1add $r0.5 = $r0.5, $r0.2   // bblock 0, line 31,  t29,  t28,  t27
;;								// 38
	c0    sub $r0.2 = $r0.0, $r0.5   // bblock 0, line 31,  t31,  0(I32),  t29
;;								// 39
.return ret($r0.3:s32)
	c0    slct $r0.3 = $b0.3, $r0.5, $r0.2   // bblock 0, line 31,  t2,  t30,  t29,  t31
	c0    return $r0.1 = $r0.1, (0x0), $l0.0   // bblock 0, line 31,  t4,  ?2.5?2auto_size(I32),  t3
;;								// 40
.endp
.section .bss
.section .data
.section .data
.section .text
.equ ?2.5?2auto_size, 0x0
 // End __divw
 // Begin __moduw
.section .text
.proc
.entry caller, sp=$r0.1, rl=$l0.0, asize=0, arg($r0.3:u32,$r0.4:u32)
__moduw::
.trace 1
	      // auto_size == 0
	c0    cmplt $r0.2 = $r0.4, $r0.0   // bblock 0, line 41,  t21,  t1,  0(I32)
	c0    cmpgeu $b0.1 = $r0.3, $r0.4   // bblock 0, line 41,  t27,  t0,  t1
	c0    sub $r0.5 = $r0.3, $r0.4   // bblock 0, line 41,  t28,  t0,  t1
	c0    mtb $b0.0 = $r0.0   // 0(I32)
;;								// 0
	c0    shru $r0.4 = $r0.4, $r0.2   // bblock 0, line 41,  t19,  t1,  t21
	c0    shru $r0.6 = $r0.3, $r0.2   // bblock 0, line 41,  t18,  t0,  t21
	c0    slct $r0.5 = $b0.1, $r0.5, $r0.3   // bblock 0, line 41,  t29,  t27,  t28,  t0
	c0    mtb $b0.1 = $r0.2   // t21
;;								// 1
	c0    addcg $r0.2, $b0.2 = $r0.6, $r0.6, $b0.0   // bblock 0, line 41,  t18,  t22(I1),  t18,  t18,  0(I32)
;;								// 2
	c0    divs $r0.6, $b0.2 = $r0.0, $r0.4, $b0.2   // bblock 0, line 41,  t20,  t22(I1),  0(I32),  t19,  t22(I1)
	c0    addcg $r0.7, $b0.3 = $r0.2, $r0.2, $b0.0   // bblock 0, line 41,  t18,  t23(I1),  t18,  t18,  0(I32)
;;								// 3
	c0    divs $r0.6, $b0.3 = $r0.6, $r0.4, $b0.3   // bblock 0, line 41,  t20,  t23(I1),  t20,  t19,  t23(I1)
	c0    addcg $r0.2, $b0.2 = $r0.7, $r0.7, $b0.2   // bblock 0, line 41,  t18,  t22(I1),  t18,  t18,  t22(I1)
;;								// 4
	c0    divs $r0.6, $b0.2 = $r0.6, $r0.4, $b0.2   // bblock 0, line 41,  t20,  t22(I1),  t20,  t19,  t22(I1)
	c0    addcg $r0.7, $b0.3 = $r0.2, $r0.2, $b0.3   // bblock 0, line 41,  t18,  t23(I1),  t18,  t18,  t23(I1)
;;								// 5
	c0    divs $r0.6, $b0.3 = $r0.6, $r0.4, $b0.3   // bblock 0, line 41,  t20,  t23(I1),  t20,  t19,  t23(I1)
	c0    addcg $r0.2, $b0.2 = $r0.7, $r0.7, $b0.2   // bblock 0, line 41,  t18,  t22(I1),  t18,  t18,  t22(I1)
;;								// 6
	c0    divs $r0.6, $b0.2 = $r0.6, $r0.4, $b0.2   // bblock 0, line 41,  t20,  t22(I1),  t20,  t19,  t22(I1)
	c0    addcg $r0.7, $b0.3 = $r0.2, $r0.2, $b0.3   // bblock 0, line 41,  t18,  t23(I1),  t18,  t18,  t23(I1)
;;								// 7
	c0    divs $r0.6, $b0.3 = $r0.6, $r0.4, $b0.3   // bblock 0, line 41,  t20,  t23(I1),  t20,  t19,  t23(I1)
	c0    addcg $r0.2, $b0.2 = $r0.7, $r0.7, $b0.2   // bblock 0, line 41,  t18,  t22(I1),  t18,  t18,  t22(I1)
;;								// 8
	c0    divs $r0.6, $b0.2 = $r0.6, $r0.4, $b0.2   // bblock 0, line 41,  t20,  t22(I1),  t20,  t19,  t22(I1)
	c0    addcg $r0.7, $b0.3 = $r0.2, $r0.2, $b0.3   // bblock 0, line 41,  t18,  t23(I1),  t18,  t18,  t23(I1)
;;								// 9
	c0    divs $r0.6, $b0.3 = $r0.6, $r0.4, $b0.3   // bblock 0, line 41,  t20,  t23(I1),  t20,  t19,  t23(I1)
	c0    addcg $r0.2, $b0.2 = $r0.7, $r0.7, $b0.2   // bblock 0, line 41,  t18,  t22(I1),  t18,  t18,  t22(I1)
;;								// 10
	c0    divs $r0.6, $b0.2 = $r0.6, $r0.4, $b0.2   // bblock 0, line 41,  t20,  t22(I1),  t20,  t19,  t22(I1)
	c0    addcg $r0.7, $b0.3 = $r0.2, $r0.2, $b0.3   // bblock 0, line 41,  t18,  t23(I1),  t18,  t18,  t23(I1)
;;								// 11
	c0    divs $r0.6, $b0.3 = $r0.6, $r0.4, $b0.3   // bblock 0, line 41,  t20,  t23(I1),  t20,  t19,  t23(I1)
	c0    addcg $r0.2, $b0.2 = $r0.7, $r0.7, $b0.2   // bblock 0, line 41,  t18,  t22(I1),  t18,  t18,  t22(I1)
;;								// 12
	c0    divs $r0.6, $b0.2 = $r0.6, $r0.4, $b0.2   // bblock 0, line 41,  t20,  t22(I1),  t20,  t19,  t22(I1)
	c0    addcg $r0.7, $b0.3 = $r0.2, $r0.2, $b0.3   // bblock 0, line 41,  t18,  t23(I1),  t18,  t18,  t23(I1)
;;								// 13
	c0    divs $r0.6, $b0.3 = $r0.6, $r0.4, $b0.3   // bblock 0, line 41,  t20,  t23(I1),  t20,  t19,  t23(I1)
	c0    addcg $r0.2, $b0.2 = $r0.7, $r0.7, $b0.2   // bblock 0, line 41,  t18,  t22(I1),  t18,  t18,  t22(I1)
;;								// 14
	c0    divs $r0.6, $b0.2 = $r0.6, $r0.4, $b0.2   // bblock 0, line 41,  t20,  t22(I1),  t20,  t19,  t22(I1)
	c0    addcg $r0.7, $b0.3 = $r0.2, $r0.2, $b0.3   // bblock 0, line 41,  t18,  t23(I1),  t18,  t18,  t23(I1)
;;								// 15
	c0    divs $r0.6, $b0.3 = $r0.6, $r0.4, $b0.3   // bblock 0, line 41,  t20,  t23(I1),  t20,  t19,  t23(I1)
	c0    addcg $r0.2, $b0.2 = $r0.7, $r0.7, $b0.2   // bblock 0, line 41,  t18,  t22(I1),  t18,  t18,  t22(I1)
;;								// 16
	c0    divs $r0.6, $b0.2 = $r0.6, $r0.4, $b0.2   // bblock 0, line 41,  t20,  t22(I1),  t20,  t19,  t22(I1)
	c0    addcg $r0.7, $b0.3 = $r0.2, $r0.2, $b0.3   // bblock 0, line 41,  t18,  t23(I1),  t18,  t18,  t23(I1)
;;								// 17
	c0    divs $r0.6, $b0.3 = $r0.6, $r0.4, $b0.3   // bblock 0, line 41,  t20,  t23(I1),  t20,  t19,  t23(I1)
	c0    addcg $r0.2, $b0.2 = $r0.7, $r0.7, $b0.2   // bblock 0, line 41,  t18,  t22(I1),  t18,  t18,  t22(I1)
;;								// 18
	c0    divs $r0.6, $b0.2 = $r0.6, $r0.4, $b0.2   // bblock 0, line 41,  t20,  t22(I1),  t20,  t19,  t22(I1)
	c0    addcg $r0.7, $b0.3 = $r0.2, $r0.2, $b0.3   // bblock 0, line 41,  t18,  t23(I1),  t18,  t18,  t23(I1)
;;								// 19
	c0    divs $r0.6, $b0.3 = $r0.6, $r0.4, $b0.3   // bblock 0, line 41,  t20,  t23(I1),  t20,  t19,  t23(I1)
	c0    addcg $r0.2, $b0.2 = $r0.7, $r0.7, $b0.2   // bblock 0, line 41,  t18,  t22(I1),  t18,  t18,  t22(I1)
;;								// 20
	c0    divs $r0.6, $b0.2 = $r0.6, $r0.4, $b0.2   // bblock 0, line 41,  t20,  t22(I1),  t20,  t19,  t22(I1)
	c0    addcg $r0.7, $b0.3 = $r0.2, $r0.2, $b0.3   // bblock 0, line 41,  t18,  t23(I1),  t18,  t18,  t23(I1)
;;								// 21
	c0    divs $r0.6, $b0.3 = $r0.6, $r0.4, $b0.3   // bblock 0, line 41,  t20,  t23(I1),  t20,  t19,  t23(I1)
	c0    addcg $r0.2, $b0.2 = $r0.7, $r0.7, $b0.2   // bblock 0, line 41,  t18,  t22(I1),  t18,  t18,  t22(I1)
;;								// 22
	c0    divs $r0.6, $b0.2 = $r0.6, $r0.4, $b0.2   // bblock 0, line 41,  t20,  t22(I1),  t20,  t19,  t22(I1)
	c0    addcg $r0.7, $b0.3 = $r0.2, $r0.2, $b0.3   // bblock 0, line 41,  t18,  t23(I1),  t18,  t18,  t23(I1)
;;								// 23
	c0    divs $r0.6, $b0.3 = $r0.6, $r0.4, $b0.3   // bblock 0, line 41,  t20,  t23(I1),  t20,  t19,  t23(I1)
	c0    addcg $r0.2, $b0.2 = $r0.7, $r0.7, $b0.2   // bblock 0, line 41,  t18,  t22(I1),  t18,  t18,  t22(I1)
;;								// 24
	c0    divs $r0.6, $b0.2 = $r0.6, $r0.4, $b0.2   // bblock 0, line 41,  t20,  t22(I1),  t20,  t19,  t22(I1)
	c0    addcg $r0.7, $b0.3 = $r0.2, $r0.2, $b0.3   // bblock 0, line 41,  t18,  t23(I1),  t18,  t18,  t23(I1)
;;								// 25
	c0    divs $r0.6, $b0.3 = $r0.6, $r0.4, $b0.3   // bblock 0, line 41,  t20,  t23(I1),  t20,  t19,  t23(I1)
	c0    addcg $r0.2, $b0.2 = $r0.7, $r0.7, $b0.2   // bblock 0, line 41,  t18,  t22(I1),  t18,  t18,  t22(I1)
;;								// 26
	c0    divs $r0.6, $b0.2 = $r0.6, $r0.4, $b0.2   // bblock 0, line 41,  t20,  t22(I1),  t20,  t19,  t22(I1)
	c0    addcg $r0.7, $b0.3 = $r0.2, $r0.2, $b0.3   // bblock 0, line 41,  t18,  t23(I1),  t18,  t18,  t23(I1)
;;								// 27
	c0    divs $r0.6, $b0.3 = $r0.6, $r0.4, $b0.3   // bblock 0, line 41,  t20,  t23(I1),  t20,  t19,  t23(I1)
	c0    addcg $r0.2, $b0.2 = $r0.7, $r0.7, $b0.2   // bblock 0, line 41,  t18,  t22(I1),  t18,  t18,  t22(I1)
;;								// 28
	c0    divs $r0.6, $b0.2 = $r0.6, $r0.4, $b0.2   // bblock 0, line 41,  t20,  t22(I1),  t20,  t19,  t22(I1)
	c0    addcg $r0.7, $b0.3 = $r0.2, $r0.2, $b0.3   // bblock 0, line 41,  t18,  t23(I1),  t18,  t18,  t23(I1)
;;								// 29
	c0    divs $r0.6, $b0.3 = $r0.6, $r0.4, $b0.3   // bblock 0, line 41,  t20,  t23(I1),  t20,  t19,  t23(I1)
	c0    addcg $r0.2, $b0.2 = $r0.7, $r0.7, $b0.2   // bblock 0, line 41,  t18,  t22(I1),  t18,  t18,  t22(I1)
;;								// 30
	c0    divs $r0.6, $b0.2 = $r0.6, $r0.4, $b0.2   // bblock 0, line 41,  t20,  t22(I1),  t20,  t19,  t22(I1)
	c0    addcg $r0.7, $b0.3 = $r0.2, $r0.2, $b0.3   // bblock 0, line 41,  t18,  t23(I1),  t18,  t18,  t23(I1)
;;								// 31
	c0    divs $r0.6, $b0.3 = $r0.6, $r0.4, $b0.3   // bblock 0, line 41,  t20,  t23(I1),  t20,  t19,  t23(I1)
	c0    addcg $r0.2, $b0.2 = $r0.7, $r0.7, $b0.2   // bblock 0, line 41,  t18,  t22(I1),  t18,  t18,  t22(I1)
;;								// 32
	c0    divs $r0.6, $b0.2 = $r0.6, $r0.4, $b0.2   // bblock 0, line 41,  t20,  t22(I1),  t20,  t19,  t22(I1)
	c0    addcg $r0.7, $b0.3 = $r0.2, $r0.2, $b0.3   // bblock 0, line 41,  t18,  t23(I1),  t18,  t18,  t23(I1)
;;								// 33
	c0    divs $r0.6, $b0.3 = $r0.6, $r0.4, $b0.3   // bblock 0, line 41,  t20,  t23(I1),  t20,  t19,  t23(I1)
;;								// 34
	c0    cmpge $b0.0 = $r0.6, $r0.0   // bblock 0, line 41,  t24,  t20,  0(I32)
	c0    add $r0.4 = $r0.6, $r0.4   // bblock 0, line 41,  t25,  t20,  t19
;;								// 35
	c0    slct $r0.6 = $b0.0, $r0.6, $r0.4   // bblock 0, line 41,  t26,  t24,  t20,  t25
;;								// 36
.return ret($r0.3:s32)
	c0    slct $r0.3 = $b0.1, $r0.5, $r0.6   // bblock 0, line 41,  t2,  t21,  t29,  t26
	c0    return $r0.1 = $r0.1, (0x0), $l0.0   // bblock 0, line 41,  t4,  ?2.7?2auto_size(I32),  t3
;;								// 37
.endp
.section .bss
.section .data
.section .data
.section .text
.equ ?2.7?2auto_size, 0x0
 // End __moduw
 // Begin __modw
.section .text
.proc
.entry caller, sp=$r0.1, rl=$l0.0, asize=0, arg($r0.3:s32,$r0.4:s32)
__modw::
.trace 1
	      // auto_size == 0
	c0    cmplt $b0.2 = $r0.4, $r0.0   // bblock 0, line 51,  t21,  t1,  0(I32)
	c0    sub $r0.5 = $r0.0, $r0.4   // bblock 0, line 51,  t19,  0(I32),  t1
	c0    cmplt $b0.0 = $r0.3, $r0.0   // bblock 0, line 51,  t23,  t0,  0(I32)
	c0    sub $r0.2 = $r0.0, $r0.3   // bblock 0, line 51,  t18,  0(I32),  t0
	c0    mtb $b0.1 = $r0.0   // 0(I32)
;;								// 0
	c0    slct $r0.5 = $b0.2, $r0.5, $r0.4   // bblock 0, line 51,  t22,  t21,  t19,  t1
	c0    slct $r0.2 = $b0.0, $r0.2, $r0.3   // bblock 0, line 51,  t24,  t23,  t18,  t0
;;								// 1
	c0    addcg $r0.4, $b0.2 = $r0.2, $r0.2, $b0.1   // bblock 0, line 51,  t24,  t25(I1),  t24,  t24,  0(I32)
;;								// 2
	c0    divs $r0.2, $b0.2 = $r0.0, $r0.5, $b0.2   // bblock 0, line 51,  t20,  t25(I1),  0(I32),  t22,  t25(I1)
	c0    addcg $r0.6, $b0.3 = $r0.4, $r0.4, $b0.1   // bblock 0, line 51,  t24,  t26(I1),  t24,  t24,  0(I32)
;;								// 3
	c0    divs $r0.2, $b0.3 = $r0.2, $r0.5, $b0.3   // bblock 0, line 51,  t20,  t26(I1),  t20,  t22,  t26(I1)
	c0    addcg $r0.4, $b0.2 = $r0.6, $r0.6, $b0.2   // bblock 0, line 51,  t24,  t25(I1),  t24,  t24,  t25(I1)
;;								// 4
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.5, $b0.2   // bblock 0, line 51,  t20,  t25(I1),  t20,  t22,  t25(I1)
	c0    addcg $r0.6, $b0.3 = $r0.4, $r0.4, $b0.3   // bblock 0, line 51,  t24,  t26(I1),  t24,  t24,  t26(I1)
;;								// 5
	c0    divs $r0.2, $b0.3 = $r0.2, $r0.5, $b0.3   // bblock 0, line 51,  t20,  t26(I1),  t20,  t22,  t26(I1)
	c0    addcg $r0.4, $b0.2 = $r0.6, $r0.6, $b0.2   // bblock 0, line 51,  t24,  t25(I1),  t24,  t24,  t25(I1)
;;								// 6
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.5, $b0.2   // bblock 0, line 51,  t20,  t25(I1),  t20,  t22,  t25(I1)
	c0    addcg $r0.6, $b0.3 = $r0.4, $r0.4, $b0.3   // bblock 0, line 51,  t24,  t26(I1),  t24,  t24,  t26(I1)
;;								// 7
	c0    divs $r0.2, $b0.3 = $r0.2, $r0.5, $b0.3   // bblock 0, line 51,  t20,  t26(I1),  t20,  t22,  t26(I1)
	c0    addcg $r0.4, $b0.2 = $r0.6, $r0.6, $b0.2   // bblock 0, line 51,  t24,  t25(I1),  t24,  t24,  t25(I1)
;;								// 8
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.5, $b0.2   // bblock 0, line 51,  t20,  t25(I1),  t20,  t22,  t25(I1)
	c0    addcg $r0.6, $b0.3 = $r0.4, $r0.4, $b0.3   // bblock 0, line 51,  t24,  t26(I1),  t24,  t24,  t26(I1)
;;								// 9
	c0    divs $r0.2, $b0.3 = $r0.2, $r0.5, $b0.3   // bblock 0, line 51,  t20,  t26(I1),  t20,  t22,  t26(I1)
	c0    addcg $r0.4, $b0.2 = $r0.6, $r0.6, $b0.2   // bblock 0, line 51,  t24,  t25(I1),  t24,  t24,  t25(I1)
;;								// 10
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.5, $b0.2   // bblock 0, line 51,  t20,  t25(I1),  t20,  t22,  t25(I1)
	c0    addcg $r0.6, $b0.3 = $r0.4, $r0.4, $b0.3   // bblock 0, line 51,  t24,  t26(I1),  t24,  t24,  t26(I1)
;;								// 11
	c0    divs $r0.2, $b0.3 = $r0.2, $r0.5, $b0.3   // bblock 0, line 51,  t20,  t26(I1),  t20,  t22,  t26(I1)
	c0    addcg $r0.4, $b0.2 = $r0.6, $r0.6, $b0.2   // bblock 0, line 51,  t24,  t25(I1),  t24,  t24,  t25(I1)
;;								// 12
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.5, $b0.2   // bblock 0, line 51,  t20,  t25(I1),  t20,  t22,  t25(I1)
	c0    addcg $r0.6, $b0.3 = $r0.4, $r0.4, $b0.3   // bblock 0, line 51,  t24,  t26(I1),  t24,  t24,  t26(I1)
;;								// 13
	c0    divs $r0.2, $b0.3 = $r0.2, $r0.5, $b0.3   // bblock 0, line 51,  t20,  t26(I1),  t20,  t22,  t26(I1)
	c0    addcg $r0.4, $b0.2 = $r0.6, $r0.6, $b0.2   // bblock 0, line 51,  t24,  t25(I1),  t24,  t24,  t25(I1)
;;								// 14
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.5, $b0.2   // bblock 0, line 51,  t20,  t25(I1),  t20,  t22,  t25(I1)
	c0    addcg $r0.6, $b0.3 = $r0.4, $r0.4, $b0.3   // bblock 0, line 51,  t24,  t26(I1),  t24,  t24,  t26(I1)
;;								// 15
	c0    divs $r0.2, $b0.3 = $r0.2, $r0.5, $b0.3   // bblock 0, line 51,  t20,  t26(I1),  t20,  t22,  t26(I1)
	c0    addcg $r0.4, $b0.2 = $r0.6, $r0.6, $b0.2   // bblock 0, line 51,  t24,  t25(I1),  t24,  t24,  t25(I1)
;;								// 16
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.5, $b0.2   // bblock 0, line 51,  t20,  t25(I1),  t20,  t22,  t25(I1)
	c0    addcg $r0.6, $b0.3 = $r0.4, $r0.4, $b0.3   // bblock 0, line 51,  t24,  t26(I1),  t24,  t24,  t26(I1)
;;								// 17
	c0    divs $r0.2, $b0.3 = $r0.2, $r0.5, $b0.3   // bblock 0, line 51,  t20,  t26(I1),  t20,  t22,  t26(I1)
	c0    addcg $r0.4, $b0.2 = $r0.6, $r0.6, $b0.2   // bblock 0, line 51,  t24,  t25(I1),  t24,  t24,  t25(I1)
;;								// 18
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.5, $b0.2   // bblock 0, line 51,  t20,  t25(I1),  t20,  t22,  t25(I1)
	c0    addcg $r0.6, $b0.3 = $r0.4, $r0.4, $b0.3   // bblock 0, line 51,  t24,  t26(I1),  t24,  t24,  t26(I1)
;;								// 19
	c0    divs $r0.2, $b0.3 = $r0.2, $r0.5, $b0.3   // bblock 0, line 51,  t20,  t26(I1),  t20,  t22,  t26(I1)
	c0    addcg $r0.4, $b0.2 = $r0.6, $r0.6, $b0.2   // bblock 0, line 51,  t24,  t25(I1),  t24,  t24,  t25(I1)
;;								// 20
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.5, $b0.2   // bblock 0, line 51,  t20,  t25(I1),  t20,  t22,  t25(I1)
	c0    addcg $r0.6, $b0.3 = $r0.4, $r0.4, $b0.3   // bblock 0, line 51,  t24,  t26(I1),  t24,  t24,  t26(I1)
;;								// 21
	c0    divs $r0.2, $b0.3 = $r0.2, $r0.5, $b0.3   // bblock 0, line 51,  t20,  t26(I1),  t20,  t22,  t26(I1)
	c0    addcg $r0.4, $b0.2 = $r0.6, $r0.6, $b0.2   // bblock 0, line 51,  t24,  t25(I1),  t24,  t24,  t25(I1)
;;								// 22
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.5, $b0.2   // bblock 0, line 51,  t20,  t25(I1),  t20,  t22,  t25(I1)
	c0    addcg $r0.6, $b0.3 = $r0.4, $r0.4, $b0.3   // bblock 0, line 51,  t24,  t26(I1),  t24,  t24,  t26(I1)
;;								// 23
	c0    divs $r0.2, $b0.3 = $r0.2, $r0.5, $b0.3   // bblock 0, line 51,  t20,  t26(I1),  t20,  t22,  t26(I1)
	c0    addcg $r0.4, $b0.2 = $r0.6, $r0.6, $b0.2   // bblock 0, line 51,  t24,  t25(I1),  t24,  t24,  t25(I1)
;;								// 24
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.5, $b0.2   // bblock 0, line 51,  t20,  t25(I1),  t20,  t22,  t25(I1)
	c0    addcg $r0.6, $b0.3 = $r0.4, $r0.4, $b0.3   // bblock 0, line 51,  t24,  t26(I1),  t24,  t24,  t26(I1)
;;								// 25
	c0    divs $r0.2, $b0.3 = $r0.2, $r0.5, $b0.3   // bblock 0, line 51,  t20,  t26(I1),  t20,  t22,  t26(I1)
	c0    addcg $r0.4, $b0.2 = $r0.6, $r0.6, $b0.2   // bblock 0, line 51,  t24,  t25(I1),  t24,  t24,  t25(I1)
;;								// 26
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.5, $b0.2   // bblock 0, line 51,  t20,  t25(I1),  t20,  t22,  t25(I1)
	c0    addcg $r0.6, $b0.3 = $r0.4, $r0.4, $b0.3   // bblock 0, line 51,  t24,  t26(I1),  t24,  t24,  t26(I1)
;;								// 27
	c0    divs $r0.2, $b0.3 = $r0.2, $r0.5, $b0.3   // bblock 0, line 51,  t20,  t26(I1),  t20,  t22,  t26(I1)
	c0    addcg $r0.4, $b0.2 = $r0.6, $r0.6, $b0.2   // bblock 0, line 51,  t24,  t25(I1),  t24,  t24,  t25(I1)
;;								// 28
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.5, $b0.2   // bblock 0, line 51,  t20,  t25(I1),  t20,  t22,  t25(I1)
	c0    addcg $r0.6, $b0.3 = $r0.4, $r0.4, $b0.3   // bblock 0, line 51,  t24,  t26(I1),  t24,  t24,  t26(I1)
;;								// 29
	c0    divs $r0.2, $b0.3 = $r0.2, $r0.5, $b0.3   // bblock 0, line 51,  t20,  t26(I1),  t20,  t22,  t26(I1)
	c0    addcg $r0.4, $b0.2 = $r0.6, $r0.6, $b0.2   // bblock 0, line 51,  t24,  t25(I1),  t24,  t24,  t25(I1)
;;								// 30
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.5, $b0.2   // bblock 0, line 51,  t20,  t25(I1),  t20,  t22,  t25(I1)
	c0    addcg $r0.6, $b0.3 = $r0.4, $r0.4, $b0.3   // bblock 0, line 51,  t24,  t26(I1),  t24,  t24,  t26(I1)
;;								// 31
	c0    divs $r0.2, $b0.3 = $r0.2, $r0.5, $b0.3   // bblock 0, line 51,  t20,  t26(I1),  t20,  t22,  t26(I1)
	c0    addcg $r0.4, $b0.2 = $r0.6, $r0.6, $b0.2   // bblock 0, line 51,  t24,  t25(I1),  t24,  t24,  t25(I1)
;;								// 32
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.5, $b0.2   // bblock 0, line 51,  t20,  t25(I1),  t20,  t22,  t25(I1)
	c0    addcg $r0.6, $b0.3 = $r0.4, $r0.4, $b0.3   // bblock 0, line 51,  t24,  t26(I1),  t24,  t24,  t26(I1)
;;								// 33
	c0    divs $r0.2, $b0.3 = $r0.2, $r0.5, $b0.3   // bblock 0, line 51,  t20,  t26(I1),  t20,  t22,  t26(I1)
;;								// 34
	c0    cmpge $b0.1 = $r0.2, $r0.0   // bblock 0, line 51,  t27,  t20,  0(I32)
	c0    add $r0.5 = $r0.2, $r0.5   // bblock 0, line 51,  t28,  t20,  t22
;;								// 35
	c0    slct $r0.2 = $b0.1, $r0.2, $r0.5   // bblock 0, line 51,  t29,  t27,  t20,  t28
;;								// 36
	c0    sub $r0.4 = $r0.0, $r0.2   // bblock 0, line 51,  t30,  0(I32),  t29
;;								// 37
.return ret($r0.3:s32)
	c0    slct $r0.3 = $b0.0, $r0.4, $r0.2   // bblock 0, line 51,  t2,  t23,  t30,  t29
	c0    return $r0.1 = $r0.1, (0x0), $l0.0   // bblock 0, line 51,  t4,  ?2.9?2auto_size(I32),  t3
;;								// 38
.endp
.section .bss
.section .data
.section .data
.section .text
.equ ?2.9?2auto_size, 0x0
 // End __modw
 // Begin _i_rem
.section .text
.proc
.entry caller, sp=$r0.1, rl=$l0.0, asize=0, arg($r0.3:s32,$r0.4:s32)
_i_rem::
.trace 1
	      // auto_size == 0
	c0    cmplt $b0.2 = $r0.4, $r0.0   // bblock 0, line 61,  t21,  t1,  0(I32)
	c0    sub $r0.5 = $r0.0, $r0.4   // bblock 0, line 61,  t19,  0(I32),  t1
	c0    cmplt $b0.0 = $r0.3, $r0.0   // bblock 0, line 61,  t23,  t0,  0(I32)
	c0    sub $r0.2 = $r0.0, $r0.3   // bblock 0, line 61,  t18,  0(I32),  t0
	c0    mtb $b0.1 = $r0.0   // 0(I32)
;;								// 0
	c0    slct $r0.5 = $b0.2, $r0.5, $r0.4   // bblock 0, line 61,  t22,  t21,  t19,  t1
	c0    slct $r0.2 = $b0.0, $r0.2, $r0.3   // bblock 0, line 61,  t24,  t23,  t18,  t0
;;								// 1
	c0    addcg $r0.4, $b0.2 = $r0.2, $r0.2, $b0.1   // bblock 0, line 61,  t24,  t25(I1),  t24,  t24,  0(I32)
;;								// 2
	c0    divs $r0.2, $b0.2 = $r0.0, $r0.5, $b0.2   // bblock 0, line 61,  t20,  t25(I1),  0(I32),  t22,  t25(I1)
	c0    addcg $r0.6, $b0.3 = $r0.4, $r0.4, $b0.1   // bblock 0, line 61,  t24,  t26(I1),  t24,  t24,  0(I32)
;;								// 3
	c0    divs $r0.2, $b0.3 = $r0.2, $r0.5, $b0.3   // bblock 0, line 61,  t20,  t26(I1),  t20,  t22,  t26(I1)
	c0    addcg $r0.4, $b0.2 = $r0.6, $r0.6, $b0.2   // bblock 0, line 61,  t24,  t25(I1),  t24,  t24,  t25(I1)
;;								// 4
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.5, $b0.2   // bblock 0, line 61,  t20,  t25(I1),  t20,  t22,  t25(I1)
	c0    addcg $r0.6, $b0.3 = $r0.4, $r0.4, $b0.3   // bblock 0, line 61,  t24,  t26(I1),  t24,  t24,  t26(I1)
;;								// 5
	c0    divs $r0.2, $b0.3 = $r0.2, $r0.5, $b0.3   // bblock 0, line 61,  t20,  t26(I1),  t20,  t22,  t26(I1)
	c0    addcg $r0.4, $b0.2 = $r0.6, $r0.6, $b0.2   // bblock 0, line 61,  t24,  t25(I1),  t24,  t24,  t25(I1)
;;								// 6
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.5, $b0.2   // bblock 0, line 61,  t20,  t25(I1),  t20,  t22,  t25(I1)
	c0    addcg $r0.6, $b0.3 = $r0.4, $r0.4, $b0.3   // bblock 0, line 61,  t24,  t26(I1),  t24,  t24,  t26(I1)
;;								// 7
	c0    divs $r0.2, $b0.3 = $r0.2, $r0.5, $b0.3   // bblock 0, line 61,  t20,  t26(I1),  t20,  t22,  t26(I1)
	c0    addcg $r0.4, $b0.2 = $r0.6, $r0.6, $b0.2   // bblock 0, line 61,  t24,  t25(I1),  t24,  t24,  t25(I1)
;;								// 8
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.5, $b0.2   // bblock 0, line 61,  t20,  t25(I1),  t20,  t22,  t25(I1)
	c0    addcg $r0.6, $b0.3 = $r0.4, $r0.4, $b0.3   // bblock 0, line 61,  t24,  t26(I1),  t24,  t24,  t26(I1)
;;								// 9
	c0    divs $r0.2, $b0.3 = $r0.2, $r0.5, $b0.3   // bblock 0, line 61,  t20,  t26(I1),  t20,  t22,  t26(I1)
	c0    addcg $r0.4, $b0.2 = $r0.6, $r0.6, $b0.2   // bblock 0, line 61,  t24,  t25(I1),  t24,  t24,  t25(I1)
;;								// 10
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.5, $b0.2   // bblock 0, line 61,  t20,  t25(I1),  t20,  t22,  t25(I1)
	c0    addcg $r0.6, $b0.3 = $r0.4, $r0.4, $b0.3   // bblock 0, line 61,  t24,  t26(I1),  t24,  t24,  t26(I1)
;;								// 11
	c0    divs $r0.2, $b0.3 = $r0.2, $r0.5, $b0.3   // bblock 0, line 61,  t20,  t26(I1),  t20,  t22,  t26(I1)
	c0    addcg $r0.4, $b0.2 = $r0.6, $r0.6, $b0.2   // bblock 0, line 61,  t24,  t25(I1),  t24,  t24,  t25(I1)
;;								// 12
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.5, $b0.2   // bblock 0, line 61,  t20,  t25(I1),  t20,  t22,  t25(I1)
	c0    addcg $r0.6, $b0.3 = $r0.4, $r0.4, $b0.3   // bblock 0, line 61,  t24,  t26(I1),  t24,  t24,  t26(I1)
;;								// 13
	c0    divs $r0.2, $b0.3 = $r0.2, $r0.5, $b0.3   // bblock 0, line 61,  t20,  t26(I1),  t20,  t22,  t26(I1)
	c0    addcg $r0.4, $b0.2 = $r0.6, $r0.6, $b0.2   // bblock 0, line 61,  t24,  t25(I1),  t24,  t24,  t25(I1)
;;								// 14
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.5, $b0.2   // bblock 0, line 61,  t20,  t25(I1),  t20,  t22,  t25(I1)
	c0    addcg $r0.6, $b0.3 = $r0.4, $r0.4, $b0.3   // bblock 0, line 61,  t24,  t26(I1),  t24,  t24,  t26(I1)
;;								// 15
	c0    divs $r0.2, $b0.3 = $r0.2, $r0.5, $b0.3   // bblock 0, line 61,  t20,  t26(I1),  t20,  t22,  t26(I1)
	c0    addcg $r0.4, $b0.2 = $r0.6, $r0.6, $b0.2   // bblock 0, line 61,  t24,  t25(I1),  t24,  t24,  t25(I1)
;;								// 16
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.5, $b0.2   // bblock 0, line 61,  t20,  t25(I1),  t20,  t22,  t25(I1)
	c0    addcg $r0.6, $b0.3 = $r0.4, $r0.4, $b0.3   // bblock 0, line 61,  t24,  t26(I1),  t24,  t24,  t26(I1)
;;								// 17
	c0    divs $r0.2, $b0.3 = $r0.2, $r0.5, $b0.3   // bblock 0, line 61,  t20,  t26(I1),  t20,  t22,  t26(I1)
	c0    addcg $r0.4, $b0.2 = $r0.6, $r0.6, $b0.2   // bblock 0, line 61,  t24,  t25(I1),  t24,  t24,  t25(I1)
;;								// 18
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.5, $b0.2   // bblock 0, line 61,  t20,  t25(I1),  t20,  t22,  t25(I1)
	c0    addcg $r0.6, $b0.3 = $r0.4, $r0.4, $b0.3   // bblock 0, line 61,  t24,  t26(I1),  t24,  t24,  t26(I1)
;;								// 19
	c0    divs $r0.2, $b0.3 = $r0.2, $r0.5, $b0.3   // bblock 0, line 61,  t20,  t26(I1),  t20,  t22,  t26(I1)
	c0    addcg $r0.4, $b0.2 = $r0.6, $r0.6, $b0.2   // bblock 0, line 61,  t24,  t25(I1),  t24,  t24,  t25(I1)
;;								// 20
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.5, $b0.2   // bblock 0, line 61,  t20,  t25(I1),  t20,  t22,  t25(I1)
	c0    addcg $r0.6, $b0.3 = $r0.4, $r0.4, $b0.3   // bblock 0, line 61,  t24,  t26(I1),  t24,  t24,  t26(I1)
;;								// 21
	c0    divs $r0.2, $b0.3 = $r0.2, $r0.5, $b0.3   // bblock 0, line 61,  t20,  t26(I1),  t20,  t22,  t26(I1)
	c0    addcg $r0.4, $b0.2 = $r0.6, $r0.6, $b0.2   // bblock 0, line 61,  t24,  t25(I1),  t24,  t24,  t25(I1)
;;								// 22
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.5, $b0.2   // bblock 0, line 61,  t20,  t25(I1),  t20,  t22,  t25(I1)
	c0    addcg $r0.6, $b0.3 = $r0.4, $r0.4, $b0.3   // bblock 0, line 61,  t24,  t26(I1),  t24,  t24,  t26(I1)
;;								// 23
	c0    divs $r0.2, $b0.3 = $r0.2, $r0.5, $b0.3   // bblock 0, line 61,  t20,  t26(I1),  t20,  t22,  t26(I1)
	c0    addcg $r0.4, $b0.2 = $r0.6, $r0.6, $b0.2   // bblock 0, line 61,  t24,  t25(I1),  t24,  t24,  t25(I1)
;;								// 24
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.5, $b0.2   // bblock 0, line 61,  t20,  t25(I1),  t20,  t22,  t25(I1)
	c0    addcg $r0.6, $b0.3 = $r0.4, $r0.4, $b0.3   // bblock 0, line 61,  t24,  t26(I1),  t24,  t24,  t26(I1)
;;								// 25
	c0    divs $r0.2, $b0.3 = $r0.2, $r0.5, $b0.3   // bblock 0, line 61,  t20,  t26(I1),  t20,  t22,  t26(I1)
	c0    addcg $r0.4, $b0.2 = $r0.6, $r0.6, $b0.2   // bblock 0, line 61,  t24,  t25(I1),  t24,  t24,  t25(I1)
;;								// 26
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.5, $b0.2   // bblock 0, line 61,  t20,  t25(I1),  t20,  t22,  t25(I1)
	c0    addcg $r0.6, $b0.3 = $r0.4, $r0.4, $b0.3   // bblock 0, line 61,  t24,  t26(I1),  t24,  t24,  t26(I1)
;;								// 27
	c0    divs $r0.2, $b0.3 = $r0.2, $r0.5, $b0.3   // bblock 0, line 61,  t20,  t26(I1),  t20,  t22,  t26(I1)
	c0    addcg $r0.4, $b0.2 = $r0.6, $r0.6, $b0.2   // bblock 0, line 61,  t24,  t25(I1),  t24,  t24,  t25(I1)
;;								// 28
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.5, $b0.2   // bblock 0, line 61,  t20,  t25(I1),  t20,  t22,  t25(I1)
	c0    addcg $r0.6, $b0.3 = $r0.4, $r0.4, $b0.3   // bblock 0, line 61,  t24,  t26(I1),  t24,  t24,  t26(I1)
;;								// 29
	c0    divs $r0.2, $b0.3 = $r0.2, $r0.5, $b0.3   // bblock 0, line 61,  t20,  t26(I1),  t20,  t22,  t26(I1)
	c0    addcg $r0.4, $b0.2 = $r0.6, $r0.6, $b0.2   // bblock 0, line 61,  t24,  t25(I1),  t24,  t24,  t25(I1)
;;								// 30
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.5, $b0.2   // bblock 0, line 61,  t20,  t25(I1),  t20,  t22,  t25(I1)
	c0    addcg $r0.6, $b0.3 = $r0.4, $r0.4, $b0.3   // bblock 0, line 61,  t24,  t26(I1),  t24,  t24,  t26(I1)
;;								// 31
	c0    divs $r0.2, $b0.3 = $r0.2, $r0.5, $b0.3   // bblock 0, line 61,  t20,  t26(I1),  t20,  t22,  t26(I1)
	c0    addcg $r0.4, $b0.2 = $r0.6, $r0.6, $b0.2   // bblock 0, line 61,  t24,  t25(I1),  t24,  t24,  t25(I1)
;;								// 32
	c0    divs $r0.2, $b0.2 = $r0.2, $r0.5, $b0.2   // bblock 0, line 61,  t20,  t25(I1),  t20,  t22,  t25(I1)
	c0    addcg $r0.6, $b0.3 = $r0.4, $r0.4, $b0.3   // bblock 0, line 61,  t24,  t26(I1),  t24,  t24,  t26(I1)
;;								// 33
	c0    divs $r0.2, $b0.3 = $r0.2, $r0.5, $b0.3   // bblock 0, line 61,  t20,  t26(I1),  t20,  t22,  t26(I1)
;;								// 34
	c0    cmpge $b0.1 = $r0.2, $r0.0   // bblock 0, line 61,  t27,  t20,  0(I32)
	c0    add $r0.5 = $r0.2, $r0.5   // bblock 0, line 61,  t28,  t20,  t22
;;								// 35
	c0    slct $r0.2 = $b0.1, $r0.2, $r0.5   // bblock 0, line 61,  t29,  t27,  t20,  t28
;;								// 36
	c0    sub $r0.4 = $r0.0, $r0.2   // bblock 0, line 61,  t30,  0(I32),  t29
;;								// 37
.return ret($r0.3:s32)
	c0    slct $r0.3 = $b0.0, $r0.4, $r0.2   // bblock 0, line 61,  t2,  t23,  t30,  t29
	c0    return $r0.1 = $r0.1, (0x0), $l0.0   // bblock 0, line 61,  t4,  ?2.11?2auto_size(I32),  t3
;;								// 38
.endp
.section .bss
.section .data
.section .data
.section .text
.equ ?2.11?2auto_size, 0x0
 // End _i_rem
 // Begin _i_urem
.section .text
.proc
.entry caller, sp=$r0.1, rl=$l0.0, asize=0, arg($r0.3:u32,$r0.4:u32)
_i_urem::
.trace 1
	      // auto_size == 0
	c0    cmplt $r0.2 = $r0.4, $r0.0   // bblock 0, line 66,  t21,  t1,  0(I32)
	c0    cmpgeu $b0.1 = $r0.3, $r0.4   // bblock 0, line 66,  t27,  t0,  t1
	c0    sub $r0.5 = $r0.3, $r0.4   // bblock 0, line 66,  t28,  t0,  t1
	c0    mtb $b0.0 = $r0.0   // 0(I32)
;;								// 0
	c0    shru $r0.4 = $r0.4, $r0.2   // bblock 0, line 66,  t19,  t1,  t21
	c0    shru $r0.6 = $r0.3, $r0.2   // bblock 0, line 66,  t18,  t0,  t21
	c0    slct $r0.5 = $b0.1, $r0.5, $r0.3   // bblock 0, line 66,  t29,  t27,  t28,  t0
	c0    mtb $b0.1 = $r0.2   // t21
;;								// 1
	c0    addcg $r0.2, $b0.2 = $r0.6, $r0.6, $b0.0   // bblock 0, line 66,  t18,  t22(I1),  t18,  t18,  0(I32)
;;								// 2
	c0    divs $r0.6, $b0.2 = $r0.0, $r0.4, $b0.2   // bblock 0, line 66,  t20,  t22(I1),  0(I32),  t19,  t22(I1)
	c0    addcg $r0.7, $b0.3 = $r0.2, $r0.2, $b0.0   // bblock 0, line 66,  t18,  t23(I1),  t18,  t18,  0(I32)
;;								// 3
	c0    divs $r0.6, $b0.3 = $r0.6, $r0.4, $b0.3   // bblock 0, line 66,  t20,  t23(I1),  t20,  t19,  t23(I1)
	c0    addcg $r0.2, $b0.2 = $r0.7, $r0.7, $b0.2   // bblock 0, line 66,  t18,  t22(I1),  t18,  t18,  t22(I1)
;;								// 4
	c0    divs $r0.6, $b0.2 = $r0.6, $r0.4, $b0.2   // bblock 0, line 66,  t20,  t22(I1),  t20,  t19,  t22(I1)
	c0    addcg $r0.7, $b0.3 = $r0.2, $r0.2, $b0.3   // bblock 0, line 66,  t18,  t23(I1),  t18,  t18,  t23(I1)
;;								// 5
	c0    divs $r0.6, $b0.3 = $r0.6, $r0.4, $b0.3   // bblock 0, line 66,  t20,  t23(I1),  t20,  t19,  t23(I1)
	c0    addcg $r0.2, $b0.2 = $r0.7, $r0.7, $b0.2   // bblock 0, line 66,  t18,  t22(I1),  t18,  t18,  t22(I1)
;;								// 6
	c0    divs $r0.6, $b0.2 = $r0.6, $r0.4, $b0.2   // bblock 0, line 66,  t20,  t22(I1),  t20,  t19,  t22(I1)
	c0    addcg $r0.7, $b0.3 = $r0.2, $r0.2, $b0.3   // bblock 0, line 66,  t18,  t23(I1),  t18,  t18,  t23(I1)
;;								// 7
	c0    divs $r0.6, $b0.3 = $r0.6, $r0.4, $b0.3   // bblock 0, line 66,  t20,  t23(I1),  t20,  t19,  t23(I1)
	c0    addcg $r0.2, $b0.2 = $r0.7, $r0.7, $b0.2   // bblock 0, line 66,  t18,  t22(I1),  t18,  t18,  t22(I1)
;;								// 8
	c0    divs $r0.6, $b0.2 = $r0.6, $r0.4, $b0.2   // bblock 0, line 66,  t20,  t22(I1),  t20,  t19,  t22(I1)
	c0    addcg $r0.7, $b0.3 = $r0.2, $r0.2, $b0.3   // bblock 0, line 66,  t18,  t23(I1),  t18,  t18,  t23(I1)
;;								// 9
	c0    divs $r0.6, $b0.3 = $r0.6, $r0.4, $b0.3   // bblock 0, line 66,  t20,  t23(I1),  t20,  t19,  t23(I1)
	c0    addcg $r0.2, $b0.2 = $r0.7, $r0.7, $b0.2   // bblock 0, line 66,  t18,  t22(I1),  t18,  t18,  t22(I1)
;;								// 10
	c0    divs $r0.6, $b0.2 = $r0.6, $r0.4, $b0.2   // bblock 0, line 66,  t20,  t22(I1),  t20,  t19,  t22(I1)
	c0    addcg $r0.7, $b0.3 = $r0.2, $r0.2, $b0.3   // bblock 0, line 66,  t18,  t23(I1),  t18,  t18,  t23(I1)
;;								// 11
	c0    divs $r0.6, $b0.3 = $r0.6, $r0.4, $b0.3   // bblock 0, line 66,  t20,  t23(I1),  t20,  t19,  t23(I1)
	c0    addcg $r0.2, $b0.2 = $r0.7, $r0.7, $b0.2   // bblock 0, line 66,  t18,  t22(I1),  t18,  t18,  t22(I1)
;;								// 12
	c0    divs $r0.6, $b0.2 = $r0.6, $r0.4, $b0.2   // bblock 0, line 66,  t20,  t22(I1),  t20,  t19,  t22(I1)
	c0    addcg $r0.7, $b0.3 = $r0.2, $r0.2, $b0.3   // bblock 0, line 66,  t18,  t23(I1),  t18,  t18,  t23(I1)
;;								// 13
	c0    divs $r0.6, $b0.3 = $r0.6, $r0.4, $b0.3   // bblock 0, line 66,  t20,  t23(I1),  t20,  t19,  t23(I1)
	c0    addcg $r0.2, $b0.2 = $r0.7, $r0.7, $b0.2   // bblock 0, line 66,  t18,  t22(I1),  t18,  t18,  t22(I1)
;;								// 14
	c0    divs $r0.6, $b0.2 = $r0.6, $r0.4, $b0.2   // bblock 0, line 66,  t20,  t22(I1),  t20,  t19,  t22(I1)
	c0    addcg $r0.7, $b0.3 = $r0.2, $r0.2, $b0.3   // bblock 0, line 66,  t18,  t23(I1),  t18,  t18,  t23(I1)
;;								// 15
	c0    divs $r0.6, $b0.3 = $r0.6, $r0.4, $b0.3   // bblock 0, line 66,  t20,  t23(I1),  t20,  t19,  t23(I1)
	c0    addcg $r0.2, $b0.2 = $r0.7, $r0.7, $b0.2   // bblock 0, line 66,  t18,  t22(I1),  t18,  t18,  t22(I1)
;;								// 16
	c0    divs $r0.6, $b0.2 = $r0.6, $r0.4, $b0.2   // bblock 0, line 66,  t20,  t22(I1),  t20,  t19,  t22(I1)
	c0    addcg $r0.7, $b0.3 = $r0.2, $r0.2, $b0.3   // bblock 0, line 66,  t18,  t23(I1),  t18,  t18,  t23(I1)
;;								// 17
	c0    divs $r0.6, $b0.3 = $r0.6, $r0.4, $b0.3   // bblock 0, line 66,  t20,  t23(I1),  t20,  t19,  t23(I1)
	c0    addcg $r0.2, $b0.2 = $r0.7, $r0.7, $b0.2   // bblock 0, line 66,  t18,  t22(I1),  t18,  t18,  t22(I1)
;;								// 18
	c0    divs $r0.6, $b0.2 = $r0.6, $r0.4, $b0.2   // bblock 0, line 66,  t20,  t22(I1),  t20,  t19,  t22(I1)
	c0    addcg $r0.7, $b0.3 = $r0.2, $r0.2, $b0.3   // bblock 0, line 66,  t18,  t23(I1),  t18,  t18,  t23(I1)
;;								// 19
	c0    divs $r0.6, $b0.3 = $r0.6, $r0.4, $b0.3   // bblock 0, line 66,  t20,  t23(I1),  t20,  t19,  t23(I1)
	c0    addcg $r0.2, $b0.2 = $r0.7, $r0.7, $b0.2   // bblock 0, line 66,  t18,  t22(I1),  t18,  t18,  t22(I1)
;;								// 20
	c0    divs $r0.6, $b0.2 = $r0.6, $r0.4, $b0.2   // bblock 0, line 66,  t20,  t22(I1),  t20,  t19,  t22(I1)
	c0    addcg $r0.7, $b0.3 = $r0.2, $r0.2, $b0.3   // bblock 0, line 66,  t18,  t23(I1),  t18,  t18,  t23(I1)
;;								// 21
	c0    divs $r0.6, $b0.3 = $r0.6, $r0.4, $b0.3   // bblock 0, line 66,  t20,  t23(I1),  t20,  t19,  t23(I1)
	c0    addcg $r0.2, $b0.2 = $r0.7, $r0.7, $b0.2   // bblock 0, line 66,  t18,  t22(I1),  t18,  t18,  t22(I1)
;;								// 22
	c0    divs $r0.6, $b0.2 = $r0.6, $r0.4, $b0.2   // bblock 0, line 66,  t20,  t22(I1),  t20,  t19,  t22(I1)
	c0    addcg $r0.7, $b0.3 = $r0.2, $r0.2, $b0.3   // bblock 0, line 66,  t18,  t23(I1),  t18,  t18,  t23(I1)
;;								// 23
	c0    divs $r0.6, $b0.3 = $r0.6, $r0.4, $b0.3   // bblock 0, line 66,  t20,  t23(I1),  t20,  t19,  t23(I1)
	c0    addcg $r0.2, $b0.2 = $r0.7, $r0.7, $b0.2   // bblock 0, line 66,  t18,  t22(I1),  t18,  t18,  t22(I1)
;;								// 24
	c0    divs $r0.6, $b0.2 = $r0.6, $r0.4, $b0.2   // bblock 0, line 66,  t20,  t22(I1),  t20,  t19,  t22(I1)
	c0    addcg $r0.7, $b0.3 = $r0.2, $r0.2, $b0.3   // bblock 0, line 66,  t18,  t23(I1),  t18,  t18,  t23(I1)
;;								// 25
	c0    divs $r0.6, $b0.3 = $r0.6, $r0.4, $b0.3   // bblock 0, line 66,  t20,  t23(I1),  t20,  t19,  t23(I1)
	c0    addcg $r0.2, $b0.2 = $r0.7, $r0.7, $b0.2   // bblock 0, line 66,  t18,  t22(I1),  t18,  t18,  t22(I1)
;;								// 26
	c0    divs $r0.6, $b0.2 = $r0.6, $r0.4, $b0.2   // bblock 0, line 66,  t20,  t22(I1),  t20,  t19,  t22(I1)
	c0    addcg $r0.7, $b0.3 = $r0.2, $r0.2, $b0.3   // bblock 0, line 66,  t18,  t23(I1),  t18,  t18,  t23(I1)
;;								// 27
	c0    divs $r0.6, $b0.3 = $r0.6, $r0.4, $b0.3   // bblock 0, line 66,  t20,  t23(I1),  t20,  t19,  t23(I1)
	c0    addcg $r0.2, $b0.2 = $r0.7, $r0.7, $b0.2   // bblock 0, line 66,  t18,  t22(I1),  t18,  t18,  t22(I1)
;;								// 28
	c0    divs $r0.6, $b0.2 = $r0.6, $r0.4, $b0.2   // bblock 0, line 66,  t20,  t22(I1),  t20,  t19,  t22(I1)
	c0    addcg $r0.7, $b0.3 = $r0.2, $r0.2, $b0.3   // bblock 0, line 66,  t18,  t23(I1),  t18,  t18,  t23(I1)
;;								// 29
	c0    divs $r0.6, $b0.3 = $r0.6, $r0.4, $b0.3   // bblock 0, line 66,  t20,  t23(I1),  t20,  t19,  t23(I1)
	c0    addcg $r0.2, $b0.2 = $r0.7, $r0.7, $b0.2   // bblock 0, line 66,  t18,  t22(I1),  t18,  t18,  t22(I1)
;;								// 30
	c0    divs $r0.6, $b0.2 = $r0.6, $r0.4, $b0.2   // bblock 0, line 66,  t20,  t22(I1),  t20,  t19,  t22(I1)
	c0    addcg $r0.7, $b0.3 = $r0.2, $r0.2, $b0.3   // bblock 0, line 66,  t18,  t23(I1),  t18,  t18,  t23(I1)
;;								// 31
	c0    divs $r0.6, $b0.3 = $r0.6, $r0.4, $b0.3   // bblock 0, line 66,  t20,  t23(I1),  t20,  t19,  t23(I1)
	c0    addcg $r0.2, $b0.2 = $r0.7, $r0.7, $b0.2   // bblock 0, line 66,  t18,  t22(I1),  t18,  t18,  t22(I1)
;;								// 32
	c0    divs $r0.6, $b0.2 = $r0.6, $r0.4, $b0.2   // bblock 0, line 66,  t20,  t22(I1),  t20,  t19,  t22(I1)
	c0    addcg $r0.7, $b0.3 = $r0.2, $r0.2, $b0.3   // bblock 0, line 66,  t18,  t23(I1),  t18,  t18,  t23(I1)
;;								// 33
	c0    divs $r0.6, $b0.3 = $r0.6, $r0.4, $b0.3   // bblock 0, line 66,  t20,  t23(I1),  t20,  t19,  t23(I1)
;;								// 34
	c0    cmpge $b0.0 = $r0.6, $r0.0   // bblock 0, line 66,  t24,  t20,  0(I32)
	c0    add $r0.4 = $r0.6, $r0.4   // bblock 0, line 66,  t25,  t20,  t19
;;								// 35
	c0    slct $r0.6 = $b0.0, $r0.6, $r0.4   // bblock 0, line 66,  t26,  t24,  t20,  t25
;;								// 36
.return ret($r0.3:s32)
	c0    slct $r0.3 = $b0.1, $r0.5, $r0.6   // bblock 0, line 66,  t2,  t21,  t29,  t26
	c0    return $r0.1 = $r0.1, (0x0), $l0.0   // bblock 0, line 66,  t4,  ?2.12?2auto_size(I32),  t3
;;								// 37
.endp
.section .bss
.section .data
.section .data
.section .text
.equ ?2.12?2auto_size, 0x0
 // End _i_urem
 
 
//64-bit operations

.text
.proc
__modul::	
c0	clz	$r0.7 = $r0.4			// r20 = lzcnt(ah)
c0	clz	$r0.8 = $r0.6			// r21 = lzcnt(bh)
c0	clz	$r0.9 = $r0.3			// r22 = lzcnt(al)
c0	clz	$r0.10 = $r0.5			// r23 = lzcnt(bl)
	;;
c0	cmpeq	$b0.0  = $r0.7, 32		// b0  = (ah == 0)
c0	cmpeq	$b0.1  = $r0.8, 32		// b1  = (bh == 0)
c0	cmpleu	$r0.11 = $r0.6, $r0.4		// r24 = (bh <= ah)
c0	cmpeq	$b0.2  = $r0.6, $r0.4		// b2  = (bh == ah)
	;;
c0	add	$r0.9 = $r0.9, 32		// r22 = lzcnt(al) + 32
c0	add	$r0.10 = $r0.10, 32		// r23 = lzcnt(bl) + 32
c0	cmpleu	$r0.12 = $r0.5, $r0.3		// r25 = (bl <= al)
c0	add	$r0.18 = $r0.0, 1		// initialize the loop counter k = 1
	;; 
c0	slct	$r0.7 = $b0.0, $r0.9, $r0.7	// r20 = lzcntl(a)
c0	slct	$r0.8 = $b0.1, $r0.10, $r0.8	// r21 = lzcntl(b)
c0	slct	$r0.9 = $b0.2, $r0.12, $r0.11	// r22 = (b <= a)
c0	shru	$r0.10 = $r0.4, 1		// r23 = ah >> 1
	;;
c0	mtb	$b0.3  = $r0.9			// b3  = (b <= a) 
c0	shl	$r0.11 = $r0.4, 31		// r24 = ah << 31
c0	shru	$r0.12 = $r0.3, 1		// r25 = al >> 1
c0	add	$r0.13 = $r0.3, 0		// r26 = al (save initial divident)
	;;
c0	add	$r0.14 = $r0.4, 0		// r27 = ah (save initial divident)
c0	or	$r0.11 = $r0.11, $r0.12		// r24 = (ah << 31) | (al >> 1)
c0	add	$r0.8 = $r0.8, -1		// r19 = lzcnt(b) - 1
c0	add	$r0.3 = $r0.0, 0		// r16 = ql = 0 initialize the quotient
	;;
c0	add	$r0.4 = $r0.0, 0		// r17 = qh = 0 initialize the quotient
c0	sub	$r0.7 = $r0.8, $r0.7		// r20 = l = lzcnt(b) - 1 - lzcnt(a)
c0	cmpeq	$b0.1  = $r0.0, 0		// initialize branch condition
	;;
c0	cmpgt	$b0.0  = $r0.7, 0		// b0 = (lzcnt(b) - 1 - lzcnt(a)) > 0
c0	add	$r0.8 = $r0.7, 1		// r21 = l + 1
c0	shl	$r0.9 = $r0.6, $r0.7		// r22 = bh << l
c0	sub	$r0.15 = 32, $r0.7		// r28 = 32 - l
	;; 
c0	cmpgeu	$b0.2  = $r0.7, 32		// b2 = (l >= 32)
c0	shl	$r0.16 = $r0.5, $r0.7		// r29 = bl << l
c0	shru	$r0.15 = $r0.5, $r0.15		// r28 = bl >> (32 - l)
c0	sub	$r0.17 = $r0.0, $r0.15		// r30 = l - 32
	;; 
c0	brf	$b0.3, .Loop_end_modul		// if (b <= a) skip the loop
c0	or	$r0.17 = $r0.9, $r0.15		// r30 = (bh << l) | (bl >> (32 - l))
c0	shl	$r0.15 = $r0.5, $r0.17		// r28 = bl << (l - 32)
c0	slct	$r0.7 = $b0.0, $r0.8, $r0.18	// if (b0) k = l + 1
	;;
c0	slct	$r0.16 = $b0.2, $r0.15, $r0.17	// r28_29 = b << l
c0	slct	$r0.15 = $b0.2, $r0.0, $r0.16   // 
c0	add	$r0.8 = $r0.7, 1		// r21 = k + 1
	;;
c0	slct	$r0.5 = $b0.0, $r0.15, $r0.5	// if (b0) b <<= l
c0	slct	$r0.6 = $b0.0, $r0.16, $r0.6	// 
	;;
c0	cmpleu	$r0.10 = $r0.6, $r0.10		// r23 = (bh <= (a >> 1)h)
c0	cmpleu	$r0.11 = $r0.5, $r0.11		// r24 = (bl <= (a >> 1)l)
c0	cmpeq	$b0.0  = $r0.6, $r0.10		// b0  = (bh == (a >> 1)h)
c0	shl	$r0.9 = $r0.6, 1		// r22 = bh << 1
	;;
c0	slct	$r0.10 = $b0.0, $r0.11, $r0.10	// r23 = (b <= (a >> 1)) 
c0	shl	$r0.11 = $r0.5, 1		// r24 = bl << 1
c0	shru	$r0.12 = $r0.5, 31		// r25 = bl >> 31
	;;
c0	mtb	$b0.0  = $r0.10			// b0  = (b <= (a >> 1))
c0	or	$r0.10 = $r0.9, $r0.12		// r23 = (bh << 1) | (bl >> 31)
c0	add	$r0.18 = $r0.0, 1		// r31 = i = 1 initialize the loop index
	;; 
c0	slct	$r0.17 = $b0.0, $r0.8, $r0.7	// if (b0) k += 1
c0	slct	$r0.5 = $b0.0, $r0.11, $r0.5	// if (b0) b <<= 1
c0	slct	$r0.6 = $b0.0, $r0.10, $r0.6	// 
	;;
.Loop_begin_modul:
c0	cmpeq	$b0.2  = $r0.14, $r0.6		// b2  = (rh == bh)
c0	cmpgeu	$r0.7 = $r0.14, $r0.6		// r20 = (rh >= bh)
c0	cmpgeu	$r0.8 = $r0.13, $r0.5		// r21 = (rl >= bl)
c0	add	$r0.18 = $r0.18, 1		// increment the loop index: i += 1
	;;
c0	cmpleu	$b0.1  = $r0.18, $r0.17		// b1  = (i <= k)
c0	slct	$r0.9 = $b0.2, $r0.8, $r0.7  // r22 = (r >= b)
c0	shl	$r0.12 = $r0.3, 1		// r25 =  (q << 1)l
c0	shl	$r0.4 = $r0.4, 1		// r17 = qh <<= 1
	;;
c0	shru	$r0.7 = $r0.3, 31		// r20 = ql >> 31
c0	mtb	$b0.0  = $r0.9			// b0  = (r >= b)
c0	sub	$r0.8 = $r0.13, $r0.5		// r21 = (r - b)l
c0	cmpltu	$b0.2  = $r0.13, $r0.5		// b2  = (rl < bl)
	;;
c0	addcg	$r0.10, $b0.5 = $r0.6, $r0.0, $b0.2	// if (b2) r23 = bh + 1
c0	shru	$r0.6 = $r0.6, 1		// bh >>= 1
c0	shru	$r0.9 = $r0.5, 1		// r22 = bl >> 1
c0	shl	$r0.11 = $r0.6, 31		// r24 = bh << 31
	;; 
c0	or	$r0.4 = $r0.4, $r0.7		// r17 = (q << 1)h
c0	or	$r0.5 = $r0.9, $r0.11		// r18 = (b >> 1)l
c0	sub	$r0.10 = $r0.14, $r0.10		// r23 = (r - b)h
	;; 
c0	br	$b0.1, .Loop_begin_modul		// if (b1) loop
c0	addcg	$r0.3, $b0.5 = $r0.12, $r0.0, $b0.0	// if (b0) ql = r25 + 1
c0	slct	$r0.13 = $b0.0, $r0.8, $r0.13	// if (b0) r -= b
c0	slct	$r0.14 = $b0.0, $r0.10, $r0.14	// 
	;; 
.Loop_end_modul:
c0	add	$r0.3 = $r0.13, $r0.0			// r16 = reml
c0	add	$r0.4 = $r0.14, $r0.0			// r16 = remh
c0	return	$l0.0
	;; 
.endp

.text
.proc
__divul::	
c0	clz	$r0.7 = $r0.4			// r20 = lzcnt(ah)
c0	clz	$r0.8 = $r0.6			// r21 = lzcnt(bh)
c0	clz	$r0.9 = $r0.3			// r22 = lzcnt(al)
c0	clz	$r0.10 = $r0.5			// r23 = lzcnt(bl)
	;;
c0	cmpeq	$b0.0  = $r0.7, 32		// b0  = (ah == 0)
c0	cmpeq	$b0.1  = $r0.8, 32		// b1  = (bh == 0)
c0	cmpleu	$r0.11 = $r0.6, $r0.4		// r24 = (bh <= ah)
c0	cmpeq	$b0.2  = $r0.6, $r0.4		// b2  = (bh == ah)
	;;
c0	add	$r0.9 = $r0.9, 32		// r22 = lzcnt(al) + 32
c0	add	$r0.10 = $r0.10, 32		// r23 = lzcnt(bl) + 32
c0	cmpleu	$r0.12 = $r0.5, $r0.3		// r25 = (bl <= al)
c0	add	$r0.18 = $r0.0, 1		// initialize the loop counter k = 1
	;; 
c0	slct	$r0.7 = $b0.0, $r0.9, $r0.7	// r20 = lzcntl(a)
c0	slct	$r0.8 = $b0.1, $r0.10, $r0.8	// r21 = lzcntl(b)
c0	slct	$r0.9 = $b0.2, $r0.12, $r0.11	// r22 = (b <= a)
c0	shru	$r0.10 = $r0.4, 1		// r23 = ah >> 1
	;;
c0	mtb	$b0.3  = $r0.9			// b3  = (b <= a) 
c0	shl	$r0.11 = $r0.4, 31		// r24 = ah << 31
c0	shru	$r0.12 = $r0.3, 1		// r25 = al >> 1
c0	add	$r0.13 = $r0.3, 0		// r26 = al (save initial divident)
	;;
c0	add	$r0.14 = $r0.4, 0		// r27 = ah (save initial divident)
c0	or	$r0.11 = $r0.11, $r0.12		// r24 = (ah << 31) | (al >> 1)
c0	add	$r0.8 = $r0.8, -1		// r19 = lzcnt(b) - 1
c0	add	$r0.3 = $r0.0, 0		// r16 = ql = 0 initialize the quotient
	;;
c0	add	$r0.4 = $r0.0, 0		// r17 = qh = 0 initialize the quotient
c0	sub	$r0.7 = $r0.8, $r0.7		// r20 = l = lzcnt(b) - 1 - lzcnt(a)
c0	cmpeq	$b0.1  = $r0.0, 0		// initialize branch condition
	;;
c0	cmpgt	$b0.0  = $r0.7, 0		// b0 = (lzcnt(b) - 1 - lzcnt(a)) > 0
c0	add	$r0.8 = $r0.7, 1		// r21 = l + 1
c0	shl	$r0.9 = $r0.6, $r0.7		// r22 = bh << l
c0	sub	$r0.15 = 32, $r0.7		// r28 = 32 - l
	;; 
c0	cmpgeu	$b0.2  = $r0.7, 32		// b2 = (l >= 32)
c0	shl	$r0.16 = $r0.5, $r0.7		// r29 = bl << l
c0	shru	$r0.15 = $r0.5, $r0.15		// r28 = bl >> (32 - l)
c0	sub	$r0.17 = $r0.0, $r0.15		// r30 = l - 32
	;; 
c0	brf	$b0.3, .Loop_end_divul		// if (b <= a) skip the loop
c0	or	$r0.17 = $r0.9, $r0.15		// r30 = (bh << l) | (bl >> (32 - l))
c0	shl	$r0.15 = $r0.5, $r0.17		// r28 = bl << (l - 32)
c0	slct	$r0.7 = $b0.0, $r0.8, $r0.18	// if (b0) k = l + 1
	;;
c0	slct	$r0.16 = $b0.2, $r0.15, $r0.17	// r28_29 = b << l
c0	slct	$r0.15 = $b0.2, $r0.0, $r0.16   // 
c0	add	$r0.8 = $r0.7, 1		// r21 = k + 1
	;;
c0	slct	$r0.5 = $b0.0, $r0.15, $r0.5	// if (b0) b <<= l
c0	slct	$r0.6 = $b0.0, $r0.16, $r0.6	// 
	;;
c0	cmpleu	$r0.10 = $r0.6, $r0.10		// r23 = (bh <= (a >> 1)h)
c0	cmpleu	$r0.11 = $r0.5, $r0.11		// r24 = (bl <= (a >> 1)l)
c0	cmpeq	$b0.0  = $r0.6, $r0.10		// b0  = (bh == (a >> 1)h)
c0	shl	$r0.9 = $r0.6, 1		// r22 = bh << 1
	;;
c0	slct	$r0.10 = $b0.0, $r0.11, $r0.10	// r23 = (b <= (a >> 1)) 
c0	shl	$r0.11 = $r0.5, 1		// r24 = bl << 1
c0	shru	$r0.12 = $r0.5, 31		// r25 = bl >> 31
	;;
c0	mtb	$b0.0  = $r0.10			// b0  = (b <= (a >> 1))
c0	or	$r0.10 = $r0.9, $r0.12		// r23 = (bh << 1) | (bl >> 31)
c0	add	$r0.18 = $r0.0, 1		// r31 = i = 1 initialize the loop index
	;; 
c0	slct	$r0.17 = $b0.0, $r0.8, $r0.7	// if (b0) k += 1
c0	slct	$r0.5 = $b0.0, $r0.11, $r0.5	// if (b0) b <<= 1
c0	slct	$r0.6 = $b0.0, $r0.10, $r0.6	// 
	;;

.Loop_begin_divul:
c0	cmpeq	$b0.2  = $r0.14, $r0.6		// b2  = (rh == bh)
c0	cmpgeu	$r0.7 = $r0.14, $r0.6		// r20 = (rh >= bh)
c0	cmpgeu	$r0.8 = $r0.13, $r0.5		// r21 = (rl >= bl)
c0	add	$r0.18 = $r0.18, 1		// increment the loop index: i += 1
	;;
c0	cmpleu	$b0.1  = $r0.18, $r0.17		// b1  = (i <= k)
c0	slct	$r0.9 = $b0.2, $r0.8, $r0.7  // r22 = (r >= b)
c0	shl	$r0.12 = $r0.3, 1		// r25 =  (q << 1)l
c0	shl	$r0.4 = $r0.4, 1		// r17 = qh <<= 1
	;;
c0	shru	$r0.7 = $r0.3, 31		// r20 = ql >> 31
c0	mtb	$b0.0  = $r0.9			// b0  = (r >= b)
c0	sub	$r0.8 = $r0.13, $r0.5		// r21 = (r - b)l
c0	cmpltu	$b0.2  = $r0.13, $r0.5		// b2  = (rl < bl)
	;;
c0	addcg	$r0.10, $b0.5 = $r0.6, $r0.0, $b0.2	// if (b2) r23 = bh + 1
c0	shru	$r0.6 = $r0.6, 1		// bh >>= 1
c0	shru	$r0.9 = $r0.5, 1		// r22 = bl >> 1
c0	shl	$r0.11 = $r0.6, 31		// r24 = bh << 31
	;; 
c0	or	$r0.4 = $r0.4, $r0.7		// r17 = (q << 1)h
c0	or	$r0.5 = $r0.9, $r0.11		// r18 = (b >> 1)l
c0	sub	$r0.10 = $r0.14, $r0.10		// r23 = (r - b)h
	;; 
c0	br	$b0.1, .Loop_begin_divul		// if (b1) loop
c0	addcg	$r0.3, $b0.5 = $r0.12, $r0.0, $b0.0	// if (b0) ql = r25 + 1
c0	slct	$r0.13 = $b0.0, $r0.8, $r0.13	// if (b0) r -= b
c0	slct	$r0.14 = $b0.0, $r0.10, $r0.14	// 
	;; 
.Loop_end_divul:
c0	add	$r0.3 = $r0.3, 0
c0	add	$r0.4 = $r0.4, 0
c0	return	$l0.0
	;; 
.endp

.text
.proc
__divl::	
c0	add	$r0.27 = $r0.0, 1		// r40 = 1
c0	mtb	$b0.6  = $r0.0			// unset b6
c0	orc	$r0.17 = $r0.3, $r0.0		// r30 = ~al
 c0	orc	$r0.19 = $r0.5, $r0.0		// r32 = ~bl
	;; 
c0	addcg	$r0.17, $b0.6 = $r0.17, $r0.27, $b0.6	// r30 = (~a + 1)l
c0	addcg	$r0.19, $b0.7 = $r0.19, $r0.27, $b0.6	// r32 = (~b + 1)l
c0	orc	$r0.18 = $r0.4, $r0.0			// r31 = ~ah
c0	orc	$r0.20 = $r0.6, $r0.0			// r33 = ~bh
	;; 
c0	addcg	$r0.18, $b0.6 = $r0.18, $r0.0, $b0.6	// r31 = (~a + 1)h
c0	addcg	$r0.20, $b0.7 = $r0.20, $r0.0, $b0.7	// r33 = (~b + 1)h
c0	cmplt	$b0.4  = $r0.4, 0			// b4  = (a < 0)
c0	cmplt	$b0.5  = $r0.6, 0			// b5  = (b < 0)
	;;
c0	slct	$r0.3 = $b0.4, $r0.17, $r0.3	// r16 = (abs(a))l
c0	slct	$r0.4 = $b0.4, $r0.18, $r0.4	// r17 = (abs(a))h
c0	slct	$r0.5 = $b0.5, $r0.19, $r0.5	// r18 = (abs(b))l
c0	slct	$r0.6 = $b0.5, $r0.20, $r0.6	// r19 = (abs(b))h
	;; 
c0	clz	$r0.7 = $r0.4			// r20 = lzcnt(ah)
c0	clz	$r0.8 = $r0.6			// r21 = lzcnt(bh)
c0	clz	$r0.9 = $r0.3			// r22 = lzcnt(al)
c0	clz	$r0.10 = $r0.5			// r23 = lzcnt(bl)
	;;
c0	cmpeq	$b0.0  = $r0.7, 32		// b0  = (ah == 0)
c0	cmpeq	$b0.1  = $r0.8, 32		// b1  = (bh == 0)
c0	cmpleu	$r0.11 = $r0.6, $r0.4		// r24 = (bh <= ah)
c0	cmpeq	$b0.2  = $r0.6, $r0.4		// b2  = (bh == ah)
	;;
c0	add	$r0.9 = $r0.9, 32		// r22 = lzcnt(al) + 32
c0	add	$r0.10 = $r0.10, 32		// r23 = lzcnt(bl) + 32
c0	cmpleu	$r0.12 = $r0.5, $r0.3		// r25 = (bl <= al)
c0	add	$r0.18 = $r0.0, 1		// initialize the loop counter k = 1
	;; 
c0	slct	$r0.7 = $b0.0, $r0.9, $r0.7	// r20 = lzcntl(a)
c0	slct	$r0.8 = $b0.1, $r0.10, $r0.8	// r21 = lzcntl(b)
c0	slct	$r0.9 = $b0.2, $r0.12, $r0.11	// r22 = (b <= a)
c0	shru	$r0.10 = $r0.4, 1		// r23 = ah >> 1
	;;
c0	mtb	$b0.3  = $r0.9			// b3  = (b <= a) 
c0	shl	$r0.11 = $r0.4, 31		// r24 = ah << 31
c0	shru	$r0.12 = $r0.3, 1		// r25 = al >> 1
c0	add	$r0.13 = $r0.3, 0		// r26 = al (save initial divident)
	;;
c0	add	$r0.14 = $r0.4, 0		// r27 = ah (save initial divident)
c0	or	$r0.11 = $r0.11, $r0.12		// r24 = (ah << 31) | (al >> 1)
c0	add	$r0.8 = $r0.8, -1		// r19 = lzcnt(b) - 1
c0	add	$r0.3 = $r0.0, 0		// r16 = ql = 0 initialize the quotient
	;;
c0	add	$r0.4 = $r0.0, 0		// r17 = qh = 0 initialize the quotient
c0	sub	$r0.7 = $r0.8, $r0.7		// r20 = l = lzcnt(b) - 1 - lzcnt(a)
c0	cmpeq	$b0.1  = $r0.0, 0		// initialize branch condition
c0	slct	$r0.19 = $b0.4, $r0.27, 0	// r32 = (a < 0)
	;;
c0	cmpgt	$b0.0  = $r0.7, 0		// b0 = (lzcnt(b) - 1 - lzcnt(a)) > 0
c0	add	$r0.8 = $r0.7, 1		// r21 = l + 1
c0	shl	$r0.9 = $r0.6, $r0.7		// r22 = bh << l
c0	sub	$r0.15 = 32, $r0.7		// r28 = 32 - l
	;; 
c0	cmpgeu	$b0.2  = $r0.7, 32		// b2 = (l >= 32)
c0	shl	$r0.16 = $r0.5, $r0.7		// r29 = bl << l
c0	shru	$r0.15 = $r0.5, $r0.15		// r28 = bl >> (32 - l)
c0	sub	$r0.17 = $r0.0, $r0.15		// r30 = l - 32
	;; 
c0	brf	$b0.3, .Loop_end_divl		// if (b <= a) skip the loop
c0	or	$r0.17 = $r0.9, $r0.15		// r30 = (bh << l) | (bl >> (32 - l))
c0	shl	$r0.15 = $r0.5, $r0.17		// r28 = bl << (l - 32)
c0	slct	$r0.7 = $b0.0, $r0.8, $r0.18	// if (b0) k = l + 1
	;;
c0	slct	$r0.16 = $b0.2, $r0.15, $r0.17	// r28_29 = b << l
c0	slct	$r0.15 = $b0.2, $r0.0, $r0.16   // 
c0	add	$r0.8 = $r0.7, 1		// r21 = k + 1
c0	slct	$r0.20 = $b0.5, $r0.27, 0	// r33 = (b < 0)
	;;
c0	slct	$r0.5 = $b0.0, $r0.15, $r0.5	// if (b0) b <<= l
c0	slct	$r0.6 = $b0.0, $r0.16, $r0.6	// 
c0	cmpne	$b0.4  = $r0.19, $r0.20		// b4 = (a < 0) != (b < 0) (condition of negative result)
	;;
c0	cmpleu	$r0.10 = $r0.6, $r0.10		// r23 = (bh <= (a >> 1)h)
c0	cmpleu	$r0.11 = $r0.5, $r0.11		// r24 = (bl <= (a >> 1)l)
c0	cmpeq	$b0.0  = $r0.6, $r0.10		// b0  = (bh == (a >> 1)h)
c0	shl	$r0.9 = $r0.6, 1		// r22 = bh << 1
	;;
c0	slct	$r0.10 = $b0.0, $r0.11, $r0.10	// r23 = (b <= (a >> 1)) 
c0	shl	$r0.11 = $r0.5, 1		// r24 = bl << 1
c0	shru	$r0.12 = $r0.5, 31		// r25 = bl >> 31
	;;
c0	mtb	$b0.0  = $r0.10			// b0  = (b <= (a >> 1))
c0	or	$r0.10 = $r0.9, $r0.12		// r23 = (bh << 1) | (bl >> 31)
c0	add	$r0.18 = $r0.0, 1		// r31 = i = 1 initialize the loop index
	;; 
c0	slct	$r0.17 = $b0.0, $r0.8, $r0.7	// if (b0) k += 1
c0	slct	$r0.5 = $b0.0, $r0.11, $r0.5	// if (b0) b <<= 1
c0	slct	$r0.6 = $b0.0, $r0.10, $r0.6	// 
	;;
.Loop_begin_divl:
c0	cmpeq	$b0.2  = $r0.14, $r0.6		// b2  = (rh == bh)
c0	cmpgeu	$r0.7 = $r0.14, $r0.6		// r20 = (rh >= bh)
c0	cmpgeu	$r0.8 = $r0.13, $r0.5		// r21 = (rl >= bl)
c0	add	$r0.18 = $r0.18, 1		// increment the loop index: i += 1
	;;
c0	cmpleu	$b0.1  = $r0.18, $r0.17		// b1  = (i <= k)
c0	slct	$r0.9 = $b0.2, $r0.8, $r0.7  // r22 = (r >= b)
c0	shl	$r0.12 = $r0.3, 1		// r25 =  (q << 1)l
c0	shl	$r0.4 = $r0.4, 1		// r17 = qh <<= 1
	;;
c0	shru	$r0.7 = $r0.3, 31		// r20 = ql >> 31
c0	mtb	$b0.0  = $r0.9			// b0  = (r >= b)
c0	sub	$r0.8 = $r0.13, $r0.5		// r21 = (r - b)l
c0	cmpltu	$b0.2  = $r0.13, $r0.5		// b2  = (rl < bl)
	;;
c0	addcg	$r0.10, $b0.5 = $r0.6, $r0.0, $b0.2	// if (b2) r23 = bh + 1
c0	shru	$r0.6 = $r0.6, 1		// bh >>= 1
c0	shru	$r0.9 = $r0.5, 1		// r22 = bl >> 1
c0	shl	$r0.11 = $r0.6, 31		// r24 = bh << 31
	;; 
c0	or	$r0.4 = $r0.4, $r0.7		// r17 = (q << 1)h
c0	or	$r0.5 = $r0.9, $r0.11		// r18 = (b >> 1)l
c0	sub	$r0.10 = $r0.14, $r0.10		// r23 = (r - b)h
	;; 
c0	br	$b0.1, .Loop_begin_divl		// if (b1) loop
c0	addcg	$r0.3, $b0.5 = $r0.12, $r0.0, $b0.0	// if (b0) ql = r25 + 1
c0	slct	$r0.13 = $b0.0, $r0.8, $r0.13	// if (b0) r -= b
c0	slct	$r0.14 = $b0.0, $r0.10, $r0.14	// 
	;; 
.Loop_end_divl:
c0	cmpgtu	$b0.0 = $r0.3, 0		// b0 = (r16 > 0)
c0	sub	$r0.17 = 0, $r0.3		// r30 = (-q)l
c0	sub	$r0.18 = 0, $r0.4		// r31 = -(qh)
c0	sub	$r0.5 = -1, $r0.4		// r31 = -(1 + qh)
	;;
c0	slct	$r0.18 = $b0.0, $r0.5, $r0.18	// if (b0) (-q)h = -(1 + qh) else (-q)h = -(qh)
c0	slct	$r0.3 = $b0.4, $r0.17, $r0.3	// if (b4) negate ql
	;; 
c0	slct	$r0.4 = $b0.4, $r0.18, $r0.4	// if (b4) negate qh
c0	return	$l0.0
	;; 
.endp

.text
.proc
__modl::	
c0	add	$r0.27 = $r0.0, 1		// r40 = 1
c0	mtb	$b0.6  = $r0.0			// unset b6
c0	orc	$r0.17 = $r0.3, $r0.0		// r30 = ~al
c0	orc	$r0.19 = $r0.5, $r0.0		// r32 = ~bl
	;; 
c0	addcg	$r0.17, $b0.6 = $r0.17, $r0.27, $b0.6	// r30 = (~a + 1)l
c0	addcg	$r0.19, $b0.7 = $r0.19, $r0.27, $b0.6	// r32 = (~b + 1)l
c0	orc	$r0.18 = $r0.4, $r0.0			// r31 = ~ah
c0	orc	$r0.20 = $r0.6, $r0.0			// r33 = ~bh
	;; 
c0	addcg	$r0.18, $b0.6 = $r0.18, $r0.0, $b0.6	// r31 = (~a + 1)h
c0	addcg	$r0.20, $b0.7 = $r0.20, $r0.0, $b0.7	// r33 = (~b + 1)h
c0	cmplt	$b0.4  = $r0.4, 0			// b4  = (a < 0)
c0	cmplt	$b0.5  = $r0.6, 0			// b5  = (b < 0)
	;;
c0	slct	$r0.3 = $b0.4, $r0.17, $r0.3	// r16 = (abs(a))l
c0	slct	$r0.4 = $b0.4, $r0.18, $r0.4	// r17 = (abs(a))h
c0	slct	$r0.5 = $b0.5, $r0.19, $r0.5	// r18 = (abs(b))l
c0	slct	$r0.6 = $b0.5, $r0.20, $r0.6	// r19 = (abs(b))h
	;; 
c0	clz	$r0.7 = $r0.4			// r20 = lzcnt(ah)
c0	clz	$r0.8 = $r0.6			// r21 = lzcnt(bh)
c0	clz	$r0.9 = $r0.3			// r22 = lzcnt(al)
c0	clz	$r0.10 = $r0.5			// r23 = lzcnt(bl)
	;;
c0	cmpeq	$b0.0  = $r0.7, 32		// b0  = (ah == 0)
c0	cmpeq	$b0.1  = $r0.8, 32		// b1  = (bh == 0)
c0	cmpleu	$r0.11 = $r0.6, $r0.4		// r24 = (bh <= ah)
c0	cmpeq	$b0.2  = $r0.6, $r0.4		// b2  = (bh == ah)
	;;
c0	add	$r0.9 = $r0.9, 32		// r22 = lzcnt(al) + 32
c0	add	$r0.10 = $r0.10, 32		// r23 = lzcnt(bl) + 32
c0	cmpleu	$r0.12 = $r0.5, $r0.3		// r25 = (bl <= al)
c0	add	$r0.18 = $r0.0, 1		// initialize the loop counter k = 1
	;; 
c0	slct	$r0.7 = $b0.0, $r0.9, $r0.7	// r20 = lzcntl(a)
c0	slct	$r0.8 = $b0.1, $r0.10, $r0.8	// r21 = lzcntl(b)
c0	slct	$r0.9 = $b0.2, $r0.12, $r0.11	// r22 = (b <= a)
c0	shru	$r0.10 = $r0.4, 1		// r23 = ah >> 1
	;;
c0	mtb	$b0.3  = $r0.9			// b3  = (b <= a) 
c0	shl	$r0.11 = $r0.4, 31		// r24 = ah << 31
c0	shru	$r0.12 = $r0.3, 1		// r25 = al >> 1
c0	add	$r0.13 = $r0.3, 0		// r26 = al (save initial divident)
	;;
c0	add	$r0.14 = $r0.4, 0		// r27 = ah (save initial divident)
c0	or	$r0.11 = $r0.11, $r0.12		// r24 = (ah << 31) | (al >> 1)
c0	add	$r0.8 = $r0.8, -1		// r19 = lzcnt(b) - 1
c0	add	$r0.3 = $r0.0, 0		// r16 = ql = 0 initialize the quotient
	;;
c0	add	$r0.4 = $r0.0, 0		// r17 = qh = 0 initialize the quotient
c0	sub	$r0.7 = $r0.8, $r0.7		// r20 = l = lzcnt(b) - 1 - lzcnt(a)
c0	cmpeq	$b0.1  = $r0.0, 0		// initialize branch condition
c0	slct	$r0.19 = $b0.4, $r0.27, 0	// r32 = (a < 0)
	;;
c0	cmpgt	$b0.0  = $r0.7, 0		// b0 = (lzcnt(b) - 1 - lzcnt(a)) > 0
c0	add	$r0.8 = $r0.7, 1		// r21 = l + 1
c0	shl	$r0.9 = $r0.6, $r0.7		// r22 = bh << l
c0	sub	$r0.15 = 32, $r0.7		// r28 = 32 - l
	;; 
c0	cmpgeu	$b0.2  = $r0.7, 32		// b2 = (l >= 32)
c0	shl	$r0.16 = $r0.5, $r0.7		// r29 = bl << l
c0	shru	$r0.15 = $r0.5, $r0.15		// r28 = bl >> (32 - l)
c0	sub	$r0.17 = $r0.0, $r0.15		// r30 = l - 32
	;; 
c0	brf	$b0.3, .Loop_end_modl		// if (b <= a) skip the loop
c0	or	$r0.17 = $r0.9, $r0.15		// r30 = (bh << l) | (bl >> (32 - l))
c0	shl	$r0.15 = $r0.5, $r0.17		// r28 = bl << (l - 32)
c0	slct	$r0.7 = $b0.0, $r0.8, $r0.18	// if (b0) k = l + 1
	;;
c0	slct	$r0.16 = $b0.2, $r0.15, $r0.17	// r28_29 = b << l
c0	slct	$r0.15 = $b0.2, $r0.0, $r0.16   // 
c0	add	$r0.8 = $r0.7, 1		// r21 = k + 1
	;;
c0	slct	$r0.5 = $b0.0, $r0.15, $r0.5	// if (b0) b <<= l
c0	slct	$r0.6 = $b0.0, $r0.16, $r0.6	// 
c0	mtb	$b0.4  = $r0.19			// b4 = (a < 0) (condition of negative result)
	;;
c0	cmpleu	$r0.10 = $r0.6, $r0.10		// r23 = (bh <= (a >> 1)h)
c0	cmpleu	$r0.11 = $r0.5, $r0.11		// r24 = (bl <= (a >> 1)l)
c0	cmpeq	$b0.0  = $r0.6, $r0.10		// b0  = (bh == (a >> 1)h)
c0	shl	$r0.9 = $r0.6, 1		// r22 = bh << 1
	;;
c0	slct	$r0.10 = $b0.0, $r0.11, $r0.10	// r23 = (b <= (a >> 1)) 
c0	shl	$r0.11 = $r0.5, 1		// r24 = bl << 1
c0	shru	$r0.12 = $r0.5, 31		// r25 = bl >> 31
	;;
c0	mtb	$b0.0  = $r0.10			// b0  = (b <= (a >> 1))
c0	or	$r0.10 = $r0.9, $r0.12		// r23 = (bh << 1) | (bl >> 31)
c0	add	$r0.18 = $r0.0, 1		// r31 = i = 1 initialize the loop index
	;; 
c0	slct	$r0.17 = $b0.0, $r0.8, $r0.7	// if (b0) k += 1
c0	slct	$r0.5 = $b0.0, $r0.11, $r0.5	// if (b0) b <<= 1
c0	slct	$r0.6 = $b0.0, $r0.10, $r0.6	// 
	;;
.Loop_begin_modl:
c0	cmpeq	$b0.2  = $r0.14, $r0.6		// b2  = (rh == bh)
c0	cmpgeu	$r0.7 = $r0.14, $r0.6		// r20 = (rh >= bh)
c0	cmpgeu	$r0.8 = $r0.13, $r0.5		// r21 = (rl >= bl)
c0	add	$r0.18 = $r0.18, 1		// increment the loop index: i += 1
	;;
c0	cmpleu	$b0.1  = $r0.18, $r0.17		// b1  = (i <= k)
c0	slct	$r0.9 = $b0.2, $r0.8, $r0.7  // r22 = (r >= b)
c0	shl	$r0.12 = $r0.3, 1		// r25 =  (q << 1)l
c0	shl	$r0.4 = $r0.4, 1		// r17 = qh <<= 1
	;;
c0	shru	$r0.7 = $r0.3, 31		// r20 = ql >> 31
c0	mtb	$b0.0  = $r0.9			// b0  = (r >= b)
c0	sub	$r0.8 = $r0.13, $r0.5		// r21 = (r - b)l
c0	cmpltu	$b0.2  = $r0.13, $r0.5		// b2  = (rl < bl)
	;;
c0	addcg	$r0.10, $b0.5 = $r0.6, $r0.0, $b0.2	// if (b2) r23 = bh + 1
c0	shru	$r0.6 = $r0.6, 1		// bh >>= 1
c0	shru	$r0.9 = $r0.5, 1		// r22 = bl >> 1
c0	shl	$r0.11 = $r0.6, 31		// r24 = bh << 31
	;; 
c0	or	$r0.4 = $r0.4, $r0.7		// r17 = (q << 1)h
c0	or	$r0.5 = $r0.9, $r0.11		// r18 = (b >> 1)l
c0	sub	$r0.10 = $r0.14, $r0.10		// r23 = (r - b)h
	;; 
c0	br	$b0.1, .Loop_begin_modl		// if (b1) loop
c0	addcg	$r0.3, $b0.5 = $r0.12, $r0.0, $b0.0	// if (b0) ql = r25 + 1
c0	slct	$r0.13 = $b0.0, $r0.8, $r0.13	// if (b0) r -= b
c0	slct	$r0.14 = $b0.0, $r0.10, $r0.14	// 
	;; 
.Loop_end_modl:
c0	cmpgtu	$b0.0 = $r0.13, 0		// b0 = (r16 > 0)
c0	sub	$r0.17 = 0, $r0.13		// r30 = (-rem)l
c0	sub	$r0.18 = 0, $r0.14		// r31 = -(remh)
c0	sub	$r0.5 = -1, $r0.14		// r31 = -(1 + remh)
	;;
c0	slct	$r0.18 = $b0.0, $r0.5, $r0.18	// if (b0) (-rem)h = -(1 + remh) else (-rem)h = -(remh)
c0	slct	$r0.3 = $b0.4, $r0.17, $r0.13	// if (b4) negate reml
	;; 
c0	slct	$r0.4 = $b0.4, $r0.18, $r0.14	// if (b4) negate remh
c0	return	$l0.0
	;; 
.endp

