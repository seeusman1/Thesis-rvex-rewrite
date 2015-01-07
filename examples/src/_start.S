


	.section .text
	.proc 
_start::
	c0	mov  $r0.1 = __STACK_START 
/*	c0	mov  $r0.1 = 0x100000    /*  either use __STACK_START or some manually chosen value for stack pointer  */
;;
	c0 add 	$r0.21 = $r0.0, __BSS_START
	c0 add  $r0.22 = $r0.0, __BSS_END
;;
	c0	cmpleu 	$b0.0 = $r0.22, $r0.21
;;
;;
	c0 	br 		$b0.0, 2f
;;
1:
	c0	stw 	0x0[$r0.21] = $r0.0
;;
	c0 	cmpge 	$b0.0 = $r0.21, $r0.22
	c0	add 	$r0.21 = $r0.21, 0x4
;;
;;
	c0	brf 	$b0.0, 1b
;;
2:
	c0	call $l0.0 = main
;;
	c0	stop 
;;
	c0	nop
;;
	c0	nop
;;
	.endp
