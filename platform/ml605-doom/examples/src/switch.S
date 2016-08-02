#include "asm_offsets.h"

#define VCR_TRAPS_ENABLED 0x10
#define VCR_DCACHE_BYPASS 0x100


 /*
  * Save state.
  * we dont have user/system modes on VEX so we have to save
  * all the registers always.
  */
.section .text
.proc
.global trap_setup
trap_setup::
	c0 nop 								/* flush to be sure */
;;
	c0 stw -(TRACEREG_SZ-PT_R1)[$r0.1] = $r0.1			/* store sp before modifying */
;;
	c0 add $r0.1 = $r0.1, -TRACEREG_SZ		  /* general registers, PC and lr */
;;
	c0 stw PT_R2[$r0.1] = $r0.2
;;
	c0 stw PT_R3[$r0.1] = $r0.3
;;
	c0 stw PT_R4[$r0.1] = $r0.4
;;
	c0 stw PT_R5[$r0.1] = $r0.5
;;
	c0 stw PT_R6[$r0.1] = $r0.6
;;
	c0 stw PT_R7[$r0.1] = $r0.7
;;
	c0 stw PT_R8[$r0.1] = $r0.8
;;
	c0 stw PT_R9[$r0.1] = $r0.9
;;
	c0 stw PT_R10[$r0.1] = $r0.10
;;
	c0 stw PT_R11[$r0.1] = $r0.11
;;
	c0 stw PT_R12[$r0.1] = $r0.12
;;
	c0 stw PT_R13[$r0.1] = $r0.13
;;
	c0 stw PT_R14[$r0.1] = $r0.14
;;
	c0 stw PT_R15[$r0.1] = $r0.15
;;
	c0 stw PT_R16[$r0.1] = $r0.16
;;
	c0 stw PT_R17[$r0.1] = $r0.17
;;
	c0 stw PT_R18[$r0.1] = $r0.18
;;
	c0 stw PT_R19[$r0.1] = $r0.19
;;
	c0 stw PT_R20[$r0.1] = $r0.20
;;
	c0 stw PT_R21[$r0.1] = $r0.21
;;
	c0 stw PT_R22[$r0.1] = $r0.22
;;
	c0 stw PT_R23[$r0.1] = $r0.23
;;
	c0 stw PT_R24[$r0.1] = $r0.24
;;
	c0 stw PT_R25[$r0.1] = $r0.25
;;
	c0 stw PT_R26[$r0.1] = $r0.26
;;
	c0 stw PT_R27[$r0.1] = $r0.27
;;
	c0 stw PT_R28[$r0.1] = $r0.28
;;
	c0 stw PT_R29[$r0.1] = $r0.29
;;
	c0 stw PT_R30[$r0.1] = $r0.30
;;
	c0 stw PT_R31[$r0.1] = $r0.31
;;
	c0 stw PT_R32[$r0.1] = $r0.32
;;
	c0 stw PT_R33[$r0.1] = $r0.33
;;
	c0 stw PT_R34[$r0.1] = $r0.34
;;
	c0 stw PT_R35[$r0.1] = $r0.35
;;
	c0 stw PT_R36[$r0.1] = $r0.36
;;
	c0 stw PT_R37[$r0.1] = $r0.37
;;
	c0 stw PT_R38[$r0.1] = $r0.38
;;
	c0 stw PT_R39[$r0.1] = $r0.39
;;
	c0 stw PT_R40[$r0.1] = $r0.40
;;
	c0 stw PT_R41[$r0.1] = $r0.41
;;
	c0 stw PT_R42[$r0.1] = $r0.42
;;
	c0 stw PT_R43[$r0.1] = $r0.43
;;
	c0 stw PT_R44[$r0.1] = $r0.44
;;
	c0 stw PT_R45[$r0.1] = $r0.45
;;
	c0 stw PT_R46[$r0.1] = $r0.46
;;
	c0 stw PT_R47[$r0.1] = $r0.47
;;
	c0 stw PT_R48[$r0.1] = $r0.48
;;
	c0 stw PT_R49[$r0.1] = $r0.49
;;
	c0 stw PT_R50[$r0.1] = $r0.50
;;
	c0 stw PT_R51[$r0.1] = $r0.51
;;
	c0 stw PT_R52[$r0.1] = $r0.52
;;
	c0 stw PT_R53[$r0.1] = $r0.53
;;
	c0 stw PT_R54[$r0.1] = $r0.54
;;
	c0 stw PT_R55[$r0.1] = $r0.55
;;
	c0 stw PT_R56[$r0.1] = $r0.56
;;
	c0 stw PT_R57[$r0.1] = $r0.57
;;
	c0 stw PT_R58[$r0.1] = $r0.58
;;
	c0 stw PT_R59[$r0.1] = $r0.59
;;
	c0 stw PT_R60[$r0.1] = $r0.60
;;
	c0 stw PT_R61[$r0.1] = $r0.61
;;
	c0 ldw $r0.61 =0xFFFFF004[$r0.0]		/* PC saved by hardware at trap time */
;;
	c0 stw PT_R62[$r0.1] = $r0.62
;;
	/* lr is already saved before calling this function */
	c0 stw PT_PC[$r0.1] = $r0.61 /* store PC, saved in tmp reg 61 */
;;

	c0 ldw $r0.19 = 0xFFFFF000[$r0.0]
;;
/* now store branch regs because we can use the GRs now */
	c0 slctf $r0.11 = $b0.0, $r0.0, 1
	c0 slctf $r0.12 = $b0.1, $r0.0, 1
	c0 slctf $r0.13 = $b0.2, $r0.0, 1
	c0 slctf $r0.14 = $b0.3, $r0.0, 1
;;
	c0 slctf $r0.15 = $b0.4, $r0.0, 1
	c0 slctf $r0.16 = $b0.5, $r0.0, 1
	c0 slctf $r0.17 = $b0.6, $r0.0, 1
	c0 slctf $r0.18 = $b0.7, $r0.0, 1
;;
	c0 stw PT_VCR[$r0.1] = $r0.19
;;
	c0 stb PT_B0[$r0.1] = $r0.11
;;
	c0 stb PT_B1[$r0.1] = $r0.12
;;
	c0 stb PT_B2[$r0.1] = $r0.13
;;
	c0 stb PT_B3[$r0.1] = $r0.14
;;
	c0 stb PT_B4[$r0.1] = $r0.15
;;
	c0 stb PT_B5[$r0.1] = $r0.16
;;
	c0 stb PT_B6[$r0.1] = $r0.17
;;
	c0 stb PT_B7[$r0.1] = $r0.18
;;
	c0 return $r0.1 = $r0.1, 0, $l0.0
;;
;;
.endp



/* restore and return */
.section .text
.proc
.global restore_state_and_return
restore_state_and_return::
/*
	ldw $r0.11 = 0xFFFFF000[$r0.0]
;;
;;
	or $r0.12 = $r0.11, VCR_DCACHE_BYPASS
;;
	stw 0xFFFFF000[$r0.0] = $r0.12
;;
;; 
;; */ /*wait an extra cycle for the bypass to come into effect */
	c0 ldb $r0.11 = PT_B0[$r0.1]
;;
	c0 cmpne $b0.0 = $r0.11, $r0.0
	c0 ldb $r0.12 = PT_B1[$r0.1]
;;
	c0 cmpne $b0.1 = $r0.12, $r0.0
	c0 ldb $r0.13 = PT_B2[$r0.1]
;;
	c0 cmpne $b0.2 = $r0.13, $r0.0
	c0 ldb $r0.14 = PT_B3[$r0.1]
;;
	c0 cmpne $b0.3 = $r0.14, $r0.0
	c0 ldb $r0.15 = PT_B4[$r0.1]
;;
	c0 cmpne $b0.4 = $r0.15, $r0.0
	c0 ldb $r0.16 = PT_B5[$r0.1]
;;
	c0 cmpne $b0.5 = $r0.16, $r0.0
	c0 ldb $r0.17 = PT_B6[$r0.1]
;;
	c0 cmpne $b0.6 = $r0.17, $r0.0
	c0 ldb $r0.18 = PT_B7[$r0.1]
;;
	c0 cmpne $b0.7 = $r0.18, $r0.0
/* dont load r1 (sp), the stack is popped by the return insn */
	c0 ldw $r0.2 = PT_R2[$r0.1]
;;
	c0 ldw $r0.3 = PT_R3[$r0.1]
;;
	c0 ldw $r0.4 = PT_R4[$r0.1]
;;
	c0 ldw $r0.5 = PT_R5[$r0.1]
;;
	c0 ldw $r0.6 = PT_R6[$r0.1]
;;
	c0 ldw $r0.7 = PT_R7[$r0.1]
;;
	c0 ldw $r0.8 = PT_R8[$r0.1]
;;
	c0 ldw $r0.9 = PT_R9[$r0.1]
;;
	c0 ldw $r0.10 = PT_R10[$r0.1]
;;
	c0 ldw $r0.11 = PT_R11[$r0.1]
;;
	c0 ldw $r0.12 = PT_R12[$r0.1]
;;
	c0 ldw $r0.13 = PT_R13[$r0.1]
;;
	c0 ldw $r0.14 = PT_R14[$r0.1]
;;
	c0 ldw $r0.15 = PT_R15[$r0.1]
;;
	c0 ldw $r0.16 = PT_R16[$r0.1]
;;
	c0 ldw $r0.17 = PT_R17[$r0.1]
;;
	c0 ldw $r0.18 = PT_R18[$r0.1]
;;
	c0 ldw $r0.19 = PT_R19[$r0.1]
;;
	c0 ldw $r0.20 = PT_R20[$r0.1]
;;
	c0 ldw $r0.21 = PT_R21[$r0.1]
;;
	c0 ldw $r0.22 = PT_R22[$r0.1]
;;
	c0 ldw $r0.23 = PT_R23[$r0.1]
;;
	c0 ldw $r0.24 = PT_R24[$r0.1]
;;
	c0 ldw $r0.25 = PT_R25[$r0.1]
;;
	c0 ldw $r0.26 = PT_R26[$r0.1]
;;
	c0 ldw $r0.27 = PT_R27[$r0.1]
;;
	c0 ldw $r0.28 = PT_R28[$r0.1]
;;
	c0 ldw $r0.29 = PT_R29[$r0.1]
;;
	c0 ldw $r0.30 = PT_R30[$r0.1]
;;
	c0 ldw $r0.31 = PT_R31[$r0.1]
;;
	c0 ldw $r0.32 = PT_R32[$r0.1]
;;
	c0 ldw $r0.33 = PT_R33[$r0.1]
;;
	c0 ldw $r0.34 = PT_R34[$r0.1]
;;
	c0 ldw $r0.35 = PT_R35[$r0.1]
;;
	c0 ldw $r0.36 = PT_R36[$r0.1]
;;
	c0 ldw $r0.37 = PT_R37[$r0.1]
;;
	c0 ldw $r0.38 = PT_R38[$r0.1]
;;
	c0 ldw $r0.39 = PT_R39[$r0.1]
;;
	c0 ldw $r0.40 = PT_R40[$r0.1]
;;
	c0 ldw $r0.41 = PT_R41[$r0.1]
;;
	c0 ldw $r0.42 = PT_R42[$r0.1]
;;
	c0 ldw $r0.43 = PT_R43[$r0.1]
;;
	c0 ldw $r0.44 = PT_R44[$r0.1]
;;
	c0 ldw $r0.45 = PT_R45[$r0.1]
;;
	c0 ldw $r0.46 = PT_R46[$r0.1]
;;
	c0 ldw $r0.47 = PT_R47[$r0.1]
;;
	c0 ldw $r0.48 = PT_R48[$r0.1]
;;
	c0 ldw $r0.49 = PT_R49[$r0.1]
;;
	c0 ldw $r0.50 = PT_R50[$r0.1]
;;
	c0 ldw $r0.51 = PT_R51[$r0.1]
;;
	c0 ldw $r0.52 = PT_R52[$r0.1]
;;
	c0 ldw $r0.53 = PT_R53[$r0.1]
;;
	c0 ldw $r0.54 = PT_R54[$r0.1]
;;
	c0 ldw $r0.55 = PT_R55[$r0.1]
;;
	c0 ldw $r0.56 = PT_R56[$r0.1]
;;
	c0 ldw $r0.57 = PT_R57[$r0.1]
;;
	c0 ldw $r0.58 = PT_R58[$r0.1]
;;
	c0 ldw $r0.59 = PT_R59[$r0.1]
;;
	c0 ldw $r0.63 = PT_VCR[$r0.1] /* abusing secret register 63 for this */
;;
	c0 ldw $l0.0 = PT_PC[$r0.1] /* PC (continuation address) */
;;
	c0 ldw $r0.60 = PT_R60[$r0.1]
	c0 or $r0.63 = $r0.63, VCR_TRAPS_ENABLED 
;;
/*	c0 and $r0.63 = $r0.63, ~VCR_DCACHE_BYPASS */ /* enable cache again  */
	c0 ldw $r0.61 = PT_R61[$r0.1]
;;
	c0 ldw $r0.62 = PT_R62[$r0.1]
;;
	c0 stw 0xFFFFF000[$r0.0] = $r0.63 
;;
	c0 return $r0.1 = $r0.1, TRACEREG_SZ, $l0.0 /* this also pops the stack */
	c0 ldw $l0.0 = PT_LR[$r0.1]  /* original lr value TODO: test, change reti to use c1 */
;;
;;
	.endp





/* not implemented yet, just send them to bad_trap_handler */
.global BAD_instruction
BAD_instruction:
.global priv_instruction
priv_instruction:
.global fpu_dis
fpu_dis:
.global mna_handler
mna_handler:
.global fpe_trap_handler
fpe_trap_handler:
.global do_reg_access
do_reg_access:
.global do_cp_disabled
do_cp_disabled:
.global do_bad_flush
do_bad_flush:
.global do_cp_exception
do_cp_exception:
.global do_hw_divzero
do_hw_divzero:
/*
 * received trap for which we do not have a handler;
 * Die...
 */
	.section .text
	.align 4
	.proc
	.global bad_trap_handler
bad_trap_handler::
	c0	add $r0.14 = $r0.0, 0x80000100		/* uart base address */
;;
	c0	add $r0.15 = $r0.0, 0x53535353		/* ascii 'S' */
;;
	c0	stw 0x0[$r0.14] = $r0.15
;;
;;
	.endp
/* fall through to stopvex */


	.section .text
	.align	4
	.proc
	.global stopvex
stopvex::
	c0 stop
;;
;;
	.endp
	


/*
 * All IRQs end up here. int_level is stored in r3 and the old r3 is already on the stack.
 *
 */
 	.section .text
	.align	4
	.proc
	.globl	_switch
_switch::
/*
 * r3 contains the irq type.
 * To call trap_setup, we first need to store the lr.
 * when context is saved, increment intr_count and call process_int
 *
 */
/* H first save the lr so we can call a function */
	c0 stw -(TRACEREG_SZ-PT_LR)[$r0.1] = $l0.0
;;
	c0 call $l0.0 = trap_setup
;;
/*
 * This (writing below SP) is officially not allowed by the VEX runtime architecture,
 * but traps are disabled at this point so it won't do harm (as long as it doesnt overflow)
 * because it wont trigger a page fault (although it wouldnt anyways because we dont have a MMU)
 */



/* save SP, disable running flag, wait for the other core to start and enter idle mode */
	stw 0x8000055c[$r0.0] = $r0.1
;;
	stw 0x80000558[$r0.0] = $r0.0
;;
pollstart:
	mov $r0.30 = 1024
;;
1:
	add $r0.30 = $r0.30, -1
	cmpeq $b0.1 = $r0.30, 0
;;
;;
	brf $b0.1, 1b
;;
	ldw $r0.31 = 0x80000558[$r0.0]
;;
;;
	cmpeq $b0.0 = $r0.31, 0
;;
;;
	br $b0.0, pollstart /* other core hasn't started yet, wait and check again */
;;
	goto idle
;;
;;
	.endp


	.section .text
	.proc
	.global idle
idle::
	ldw $r0.11 = 0xFFFFF000[$r0.0] /* load VCR */
;;
;;
	shr 	$r0.12=$r0.11, 12
;;
	and 	$r0.13=$r0.12, 3  /* r13 = core_id */
;;
	mov $r0.14 = 1
	mov $r0.16 = 3
;;
	shl $r0.15 = $r0.14, $r0.13 /* r15 = this core's running flag */
;;
	xor $r0.17 = $r0.15, $r0.16 /* r16 = the other core's running flag */
;;
/* poll the status flag of the other core. When it is disabled: resume. */
pollstop:
	ldw $r0.21 = 0x80000558[$r0.0]
;;
;;
	cmpeq $b0.0 = $r0.21, $r0.17
;;
;;
	brf $b0.0, resume
	mov $r0.30 = 1024
;;
	/* other core still running, wait a while (to save bus bandwidth) and then check again */
wait:
	add $r0.30 = $r0.30, -1
	cmpeq $b0.1 = $r0.30, 0
;;
;;
	br $b0.1, pollstop
;;
	goto wait
;;

/* load SP, set this core's running flag, enable interrupts and resume */
resume:
	ldw $r0.1 = 0x8000055c[$r0.0]
;;
	ldw $r0.11 = 0xFFFFF000[$r0.0] /* load VCR */
;;
;;
	shr $r0.12=$r0.11, 12
;;
	and $r0.13=$r0.12, 3  /* r13 = core_id */
;;
	mov $r0.14 = 1
;;
	shl $r0.15 = $r0.14, $r0.13 /* r15 = this core's running flag */
;;
	stw 0x80000558[$r0.0] = $r0.15
;;



/* before restoring (which entails enabling interrupts), clear pending interrupts 
 *(otherwise, it will handle a pending switch interrupt) */
	mov $r0.33 = -1
;;
 	stw 0x8000020c[$r0.0] = $r0.33
;;

	goto restore_state_and_return
;;
;;
	.endp
	
