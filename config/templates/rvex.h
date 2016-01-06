#ifndef _RVEX_H_
#define _RVEX_H_

/*****************************************************************************/
/* Core control registers                                                    */
/*****************************************************************************/

// If CREG_BASE is not overruled by a definition passed to the compiler on the
// command line, default to the rvex core default.
#ifndef CREG_BASE
#define CREG_BASE 0xFFFFFC00
#endif

// Stub definitions for any register type.
#define CREG_UINT32_R(addr)     (*(const volatile unsigned int*)(addr))
#define CREG_INT32_R(addr)      (*(const volatile          int*)(addr))
#define CREG_UINT32_RW(addr)    (*(      volatile unsigned int*)(addr))
#define CREG_INT32_RW(addr)     (*(      volatile          int*)(addr))
#define CREG_UINT16_R(addr)     (*(const volatile unsigned short*)(addr))
#define CREG_INT16_R(addr)      (*(const volatile          short*)(addr))
#define CREG_UINT16_RW(addr)    (*(      volatile unsigned short*)(addr))
#define CREG_INT16_RW(addr)     (*(      volatile          short*)(addr))
#define CREG_UINT8_R(addr)      (*(const volatile unsigned char*)(addr))
#define CREG_INT8_R(addr)       (*(const volatile          char*)(addr))
#define CREG_UINT8_RW(addr)     (*(      volatile unsigned char*)(addr))
#define CREG_INT8_RW(addr)      (*(      volatile          char*)(addr))

@CREGS

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Backwards-compatibility/convenience definitions
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

// This section can be changed in config/interpreter/rvex_h.py if necessary.

// Interrupt enable/disable bits in (S)CCR.
#define CR_CCR_IEN                      (1 << CR_CCR_I_BIT)
#define CR_CCR_IEN_C                    (2 << CR_CCR_I_BIT)

// Ready-for-trap enable/disable bits in (S)CCR.
#define CR_CCR_RFT                      (1 << CR_CCR_R_BIT)
#define CR_CCR_RFT_C                    (2 << CR_CCR_R_BIT)

// Breakpoint enable/disable bits in (S)CCR (for self-hosted debug mode).
#define CR_CCR_BPE                      (1 << CR_CCR_B_BIT)
#define CR_CCR_BPE_C                    (2 << CR_CCR_B_BIT)

// Context-switch enable/disable bits in (S)CCR
#define CR_CCR_CSW                      (1 << CR_CCR_C_BIT)
#define CR_CCR_CSW_C                    (2 << CR_CCR_C_BIT)

// Kernel mode enable/disable bits in (S)CCR
#define CR_CCR_KME                      (1 << CR_CCR_K_BIT)
#define CR_CCR_KME_C                    (2 << CR_CCR_K_BIT)

// Shorthand notation for enabling/disabling interrupts/traps (in CCR).
#define ENABLE_IRQ                      (CR_CCR = CR_CCR_IEN)
#define DISABLE_IRQ                     (CR_CCR = CR_CCR_IEN_C)
#define ENABLE_TRAPS                    (CR_CCR = CR_CCR_RFT)
#define DISABLE_TRAPS                   (CR_CCR = CR_CCR_RFT_C)
#define ENABLE_CTXT_SWITCH              (CR_CCR = CR_CCR_CSW)
#define DISABLE_CTXT_SWITCH             (CR_CCR = CR_CCR_CSW_C)

// Deprecated definitions for the first scratchpad register.
#define CR_SCRP_ADDR                    CR_SCRP1_ADDR
#define CR_SCRP                         CR_SCRP1


/*****************************************************************************/
/* Trap cause definitions                                                    */
/*****************************************************************************/

@TRAPS

#endif
