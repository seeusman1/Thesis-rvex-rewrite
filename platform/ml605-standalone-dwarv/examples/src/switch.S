#include "asm_offsets.h"
#include "rvex.h"

/*#define FASTSWITCH*/
/* Use DEFS=FASTSWITCH in makefile */


#ifndef FASTSWITCH

 /*
  * Save state.
  * we dont have user/system modes on VEX so we have to save
  * all the registers always.
  */
.section .text
.proc
.global trap_setup
trap_setup::
	stw -(TRACEREG_SZ-PT_R1)[$r0.1] = $r0.1			/* store sp before modifying */
;;
	add $r0.1 = $r0.1, -TRACEREG_SZ		  /* general registers, PC and lr */
;;
	stw PT_R2[$r0.1] = $r0.2
;;
	stw PT_R3[$r0.1] = $r0.3
;;
	stw PT_R4[$r0.1] = $r0.4
;;
	stw PT_R5[$r0.1] = $r0.5
;;
	stw PT_R6[$r0.1] = $r0.6
;;
	stw PT_R7[$r0.1] = $r0.7
;;
	stw PT_R8[$r0.1] = $r0.8
;;
	stw PT_R9[$r0.1] = $r0.9
;;
	stw PT_R10[$r0.1] = $r0.10
;;
	stw PT_R11[$r0.1] = $r0.11
;;
	stw PT_R12[$r0.1] = $r0.12
;;
	stw PT_R13[$r0.1] = $r0.13
;;
	stw PT_R14[$r0.1] = $r0.14
;;
	stw PT_R15[$r0.1] = $r0.15
;;
	stw PT_R16[$r0.1] = $r0.16
;;
	stw PT_R17[$r0.1] = $r0.17
;;
	stw PT_R18[$r0.1] = $r0.18
;;
	stw PT_R19[$r0.1] = $r0.19
;;
	stw PT_R20[$r0.1] = $r0.20
;;
	stw PT_R21[$r0.1] = $r0.21
;;
	stw PT_R22[$r0.1] = $r0.22
;;
	stw PT_R23[$r0.1] = $r0.23
;;
	stw PT_R24[$r0.1] = $r0.24
;;
	stw PT_R25[$r0.1] = $r0.25
;;
	stw PT_R26[$r0.1] = $r0.26
;;
	stw PT_R27[$r0.1] = $r0.27
;;
	stw PT_R28[$r0.1] = $r0.28
;;
	stw PT_R29[$r0.1] = $r0.29
;;
	stw PT_R30[$r0.1] = $r0.30
;;
	stw PT_R31[$r0.1] = $r0.31
;;
	stw PT_R32[$r0.1] = $r0.32
;;
	stw PT_R33[$r0.1] = $r0.33
;;
	stw PT_R34[$r0.1] = $r0.34
;;
	stw PT_R35[$r0.1] = $r0.35
;;
	stw PT_R36[$r0.1] = $r0.36
;;
	stw PT_R37[$r0.1] = $r0.37
;;
	stw PT_R38[$r0.1] = $r0.38
;;
	stw PT_R39[$r0.1] = $r0.39
;;
	stw PT_R40[$r0.1] = $r0.40
;;
	stw PT_R41[$r0.1] = $r0.41
;;
	stw PT_R42[$r0.1] = $r0.42
;;
	stw PT_R43[$r0.1] = $r0.43
;;
	stw PT_R44[$r0.1] = $r0.44
;;
	stw PT_R45[$r0.1] = $r0.45
;;
	stw PT_R46[$r0.1] = $r0.46
;;
	stw PT_R47[$r0.1] = $r0.47
;;
	stw PT_R48[$r0.1] = $r0.48
;;
	stw PT_R49[$r0.1] = $r0.49
;;
	stw PT_R50[$r0.1] = $r0.50
;;
	stw PT_R51[$r0.1] = $r0.51
;;
	stw PT_R52[$r0.1] = $r0.52
;;
	stw PT_R53[$r0.1] = $r0.53
;;
	stw PT_R54[$r0.1] = $r0.54
;;
	stw PT_R55[$r0.1] = $r0.55
;;
	stw PT_R56[$r0.1] = $r0.56
;;
	stw PT_R57[$r0.1] = $r0.57
;;
	stw PT_R58[$r0.1] = $r0.58
;;
	stw PT_R59[$r0.1] = $r0.59
;;
	stw PT_R60[$r0.1] = $r0.60
;;
	stw PT_R61[$r0.1] = $r0.61
;;
	stw PT_R62[$r0.1] = $r0.62
;;
	ldw $r0.61 = CR_TP_ADDR[$r0.0]		/* Trap Point (PC saved by hardware at trap time) */
;;
	ldw $r0.62 = CR_SCCR_ADDR[$r0.0]
;;
	stw PT_PC[$r0.1] = $r0.61 /* store PC, saved in tmp reg 61 */
;;
	stw PT_CCR[$r0.1] = $r0.62
;;
/* lr is already saved before calling this function */
/* now store branch regs because we can use the GRs now */
	slctf $r0.11 = $b0.0, $r0.0, 1
	slctf $r0.12 = $b0.1, $r0.0, 1
	slctf $r0.13 = $b0.2, $r0.0, 1
	slctf $r0.14 = $b0.3, $r0.0, 1
	slctf $r0.15 = $b0.4, $r0.0, 1
	slctf $r0.16 = $b0.5, $r0.0, 1
	slctf $r0.17 = $b0.6, $r0.0, 1
	slctf $r0.18 = $b0.7, $r0.0, 1
;;
	stb PT_B0[$r0.1] = $r0.11
;;
	stb PT_B1[$r0.1] = $r0.12
;;
	stb PT_B2[$r0.1] = $r0.13
;;
	stb PT_B3[$r0.1] = $r0.14
;;
	stb PT_B4[$r0.1] = $r0.15
;;
	stb PT_B5[$r0.1] = $r0.16
;;
	stb PT_B6[$r0.1] = $r0.17
;;
	stb PT_B7[$r0.1] = $r0.18
;;
	return $r0.1 = $r0.1, 0, $l0.0
;;
;;
.endp



/* restore and return */
.section .text
.proc
.global restore_state_and_return
restore_state_and_return::
	ldb $r0.11 = PT_B0[$r0.1]
;;
	cmpne $b0.0 = $r0.11, $r0.0
	ldb $r0.12 = PT_B1[$r0.1]
;;
	cmpne $b0.1 = $r0.12, $r0.0
	ldb $r0.13 = PT_B2[$r0.1]
;;
	cmpne $b0.2 = $r0.13, $r0.0
	ldb $r0.14 = PT_B3[$r0.1]
;;
	cmpne $b0.3 = $r0.14, $r0.0
	ldb $r0.15 = PT_B4[$r0.1]
;;
	cmpne $b0.4 = $r0.15, $r0.0
	ldb $r0.16 = PT_B5[$r0.1]
;;
	cmpne $b0.5 = $r0.16, $r0.0
	ldb $r0.17 = PT_B6[$r0.1]
;;
	cmpne $b0.6 = $r0.17, $r0.0
	ldb $r0.18 = PT_B7[$r0.1]
;;
	cmpne $b0.7 = $r0.18, $r0.0
/* dont load r1 (sp), the stack is restored just before rfi */
	ldw $r0.2 = PT_R2[$r0.1]
;;
	ldw $r0.3 = PT_R3[$r0.1]
;;
	ldw $r0.4 = PT_R4[$r0.1]
;;
	ldw $r0.5 = PT_R5[$r0.1]
;;
	ldw $r0.6 = PT_R6[$r0.1]
;;
	ldw $r0.7 = PT_R7[$r0.1]
;;
	ldw $r0.8 = PT_R8[$r0.1]
;;
	ldw $r0.9 = PT_R9[$r0.1]
;;
	ldw $r0.10 = PT_R10[$r0.1]
;;
	ldw $r0.11 = PT_R11[$r0.1]
;;
	ldw $r0.12 = PT_R12[$r0.1]
;;
	ldw $r0.13 = PT_R13[$r0.1]
;;
	ldw $r0.14 = PT_R14[$r0.1]
;;
	ldw $r0.15 = PT_R15[$r0.1]
;;
	ldw $r0.16 = PT_R16[$r0.1]
;;
	ldw $r0.17 = PT_R17[$r0.1]
;;
	ldw $r0.18 = PT_R18[$r0.1]
;;
	ldw $r0.19 = PT_R19[$r0.1]
;;
	ldw $r0.20 = PT_R20[$r0.1]
;;
	ldw $r0.21 = PT_R21[$r0.1]
;;
	ldw $r0.22 = PT_R22[$r0.1]
;;
	ldw $r0.23 = PT_R23[$r0.1]
;;
	ldw $r0.24 = PT_R24[$r0.1]
;;
	ldw $r0.25 = PT_R25[$r0.1]
;;
	ldw $r0.26 = PT_R26[$r0.1]
;;
	ldw $r0.27 = PT_R27[$r0.1]
;;
	ldw $r0.28 = PT_R28[$r0.1]
;;
	ldw $r0.29 = PT_R29[$r0.1]
;;
	ldw $r0.30 = PT_R30[$r0.1]
;;
	ldw $r0.31 = PT_R31[$r0.1]
;;
	ldw $r0.32 = PT_R32[$r0.1]
;;
	ldw $r0.33 = PT_R33[$r0.1]
;;
	ldw $r0.34 = PT_R34[$r0.1]
;;
	ldw $r0.35 = PT_R35[$r0.1]
;;
	ldw $r0.36 = PT_R36[$r0.1]
;;
	ldw $r0.37 = PT_R37[$r0.1]
;;
	ldw $r0.38 = PT_R38[$r0.1]
;;
	ldw $r0.39 = PT_R39[$r0.1]
;;
	ldw $r0.40 = PT_R40[$r0.1]
;;
	ldw $r0.41 = PT_R41[$r0.1]
;;
	ldw $r0.42 = PT_R42[$r0.1]
;;
	ldw $r0.43 = PT_R43[$r0.1]
;;
	ldw $r0.44 = PT_R44[$r0.1]
;;
	ldw $r0.45 = PT_R45[$r0.1]
;;
	ldw $r0.46 = PT_R46[$r0.1]
;;
	ldw $r0.47 = PT_R47[$r0.1]
;;
	ldw $r0.48 = PT_R48[$r0.1]
;;
	ldw $r0.49 = PT_R49[$r0.1]
;;
	ldw $r0.50 = PT_R50[$r0.1]
;;
	ldw $r0.51 = PT_R51[$r0.1]
;;
	ldw $r0.52 = PT_R52[$r0.1]
;;
	ldw $r0.53 = PT_R53[$r0.1]
;;
	ldw $r0.54 = PT_R54[$r0.1]
;;
	ldw $r0.55 = PT_R55[$r0.1]
;;
	ldw $r0.56 = PT_R56[$r0.1]
;;
	ldw $r0.57 = PT_R57[$r0.1]
;;
	ldw $r0.58 = PT_R58[$r0.1]
;;
	ldw $r0.59 = PT_R59[$r0.1]
;;
	ldw $r0.60 = PT_R60[$r0.1]
;;
	ldw $r0.61 = PT_PC[$r0.1]
;;
	ldw $r0.62 = PT_CCR[$r0.1]
;;
	stw CR_TP_ADDR[$r0.0] = $r0.61
;;
	stw CR_SCCR_ADDR[$r0.0] = $r0.62
;;
	ldw $r0.61 = PT_R61[$r0.1]
;;
	ldw $r0.62 = PT_R62[$r0.1]
;;
	ldw $l0.0 = PT_LR[$r0.1]
;;
	add $r0.1 = $r0.1, TRACEREG_SZ
;;
	rfi /*$r0.1 = $r0.1, TRACEREG_SZ   <- the assembler doesn't know this is a thing.  */
	    /*                                The hardware does though, but because unused */
	    /*                                bits are set to 0 this will add 0. Just      */
	    /*                                means we need to do the actual addition a    */
	    /*                                bundle earlier.                              */
;;
	.endp

#endif /* not FASTSWITCH */



/*
 * All IRQs end up here. There is a dumb version that saves the entire context to memory, and a smart one that switches the hardware context.
 * write the address of the routine you want to use into the trap handler register.
 *
 */
 
#ifdef FASTSWITCH

 	.section .text
	.proc
	.globl	_smartswitch
_smartswitch::
	/* Free up a register to use for the switch. */
	stw CR_SCRP_ADDR[$r0.0] = $r0.12
;;
	/* Load the current task ID. */
	ldb $r0.12 = CR_CID_ADDR[$r0.0]
;;
;;
	/* Load the new task ID from the task switch list. */
	shl $r0.12 = $r0.12, 2
;;
	ldw $r0.12 = next_task[$r0.12]
;;
;;
	/* Multiply by 0x1111 to get the new configuration word for the context switch. */
	mpyl $r0.12 = $r0.12, 0x1111
;;
;;
	/* Request the context switch. */
	stw CR_CRR_ADDR[$r0.0] = $r0.12
;;
	/* Restore r0.12 from the scratchpad register. There's up to two cycles latency */
	/* in the reconfiguration request, but it doesn't matter if we do this before */
	/* the context switch or after some other context switches back to us again. */
	ldw $r0.12 = CR_SCRP_ADDR[$r0.0]
;;
	/* Wait for the context to have switched for sure before returning.
;;
	/* Return from the trap handler. */
	rfi
;;
;;
.endp


#else

 	.section .text
	.proc
	.globl	_dumbswitch
_dumbswitch::
	nop /* Just to be certain we're reading the link register right */
;;
	/* Push the context of the current task onto its stack. */
	stw -(TRACEREG_SZ-PT_LR)[$r0.1] = $l0.0
;;
	call $l0.0 = trap_setup
;;
	/* Load the current task ID. */
	ldw $r0.11 = current_task_id[$r0.0]
;;
;;
	/* Store the stack pointer of the current task. */
	shl $r0.11 = $r0.11, 2
;;
	stw saved_SPs[$r0.11] = $r0.1
;;
	/* Load the next task ID. */
	ldw $r0.11 = next_task[$r0.11]
;;
;;
	/* Store the new task ID. */
	stw current_task_id[$r0.0] = $r0.11
	
	/* Load the stack pointer of the new task. */
	shl $r0.12 = $r0.11, 2
;;
	ldw $r0.1 = saved_SPs[$r0.12]
;;
	/* Restore and pop the context from the stack of the new task. */
	goto restore_state_and_return
;;
;;
.endp
#endif /* FASTSWITCH */

	
	.section .text
	.proc
task_complete::
	/* Cause a soft trap to jump to the context switch handler as if it were due */
	/* to a timer interrupt. */
	c0 trap 33
;;
	/* We should never really end up here, because even if a the interrupt trap */
	/* handler returns, it will jump back to the trap instruction. Just in case */
	/* though, add a jump back here. */
	c0 goto task_complete
;;
.endp
	 
	 

	
	.section .text
	.proc
all_complete::
	/* Stop execution. */
	c0 stop
;;
	c0 goto all_complete
;;
.endp
	 
	 
