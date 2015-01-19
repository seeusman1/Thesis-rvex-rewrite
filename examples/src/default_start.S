#include "rvex.h"

  .section .text
  .proc 
_start::
  /* Load BSS section start and end. */
  c0  add     $r0.21      = $r0.0, __BSS_START
  c0  add     $r0.22      = $r0.0, __BSS_END
  
  /* Load hardware context ID. */
#ifdef XSTSIM
  c0  add     $r0.11      = $r0.0, $r0.0
#else
  c0  ldb     $r0.11      = CR_CID_ADDR[$r0.0]
#endif
;;
  /* Set r0.23 if the BSS size is 0. */
  c0  cmpleu  $r0.23      = $r0.22, $r0.21
;;
  /* Set b0.0 if the BSS size is 0 or if we're not running in context 0. */
  c0  orl     $b0.0       = $r0.23, $r0.11
  
  /* Multiply the context ID by the per-context stack size (chosen manually), */
  /* so each context has its own stack. */
  c0  mpyl    $r0.12      = $r0.11, 0x1000
;;
  /* Skip BSS init if BSS size is 0 or if we're not context 0. */
  c0  br                    $b0.0, 2f
;;
1:
  /* Write 0 to the current BSS pointer. */
  c0  stw     0x0[$r0.21] = $r0.0
  
  /* Set b0.0 if this was the last word in the BSS section. */
  c0  cmpge   $b0.0       = $r0.21, $r0.22
;;
  /* Increment the BSS pointer. */
  c0  add     $r0.21      = $r0.21, 0x4
  
  /* If this wasn't the last word yet, branch back. */
  c0  brf                   $b0.0, 1b
;;
2:
  /* Initialize the stack pointer. */
  c0  add     $r0.1       = $r0.12, __STACK_START

  /* Call main. */
  c0  call    $l0.0       = main
;;
  /* Stop this context. */
  c0  stop
;;
  c0  nop
;;
  c0  nop
;;
  .endp

