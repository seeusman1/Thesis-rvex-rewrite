#include "rvex.h"

#if ISSUE == 2
#define ISSUE_2 ;;
#define ISSUE_4 ;;
#elif ISSUE == 4
#define ISSUE_2
#define ISSUE_4 ;;
#else
#define ISSUE_2
#define ISSUE_4
#endif

/*****************************************************************************/
/* ENTRY POINT                                                               */
/*****************************************************************************/
  .section .init
  .proc 
_start::

  /* Load error instruction address. */
  add     $r0.10      = $r0.0, _error
ISSUE_2
  /* Load hardware context ID. */
  ldb     $r0.11      = CR_CID_ADDR[$r0.0]
;;
  /* Set panic handler address. */
  stw     CR_PH_ADDR[$r0.0] = $r0.10
;;
  /* Multiply the context ID by the per-context stack size (chosen manually), */
  /* so each context has its own stack. */
  mpyl    $r0.12      = $r0.11, 0x400
;;
  /* Set trap handler address. */
  stw     CR_TH_ADDR[$r0.0] = $r0.10
;;
  /* Initialize the stack pointer. */
  sub     $r0.1       = __STACK_START, $r0.12
ISSUE_2
  /* Call main. */
  call    $l0.0       = main
;;
  /* Store the return value in the designated scratchpad register. */
  stb     CR_RET_ADDR[$r0.0] = $r0.3
;;
  /* Stop this context. */
  stop
;;
  nop
;;
  nop
;;
  .endp


/*****************************************************************************/
/* ERROR HANDLER                                                             */
/*****************************************************************************/
  .section .text
  .proc
_error::
  /* Load return code -2. */
  add     $r0.10      = $r0.0, -2
;;
  /* Store the return code in the designated scratchpad register. */
  stb     CR_RET_ADDR[$r0.0] = $r0.10
;;
  /* Stop this context. */
  stop
;;
  nop
;;
  nop
;;
  .endp
