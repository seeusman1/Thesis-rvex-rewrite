#ifndef _RVEX_H_
#define _RVEX_H_

/*****************************************************************************/
/* Platform-specific methods                                                 */
/*****************************************************************************/
// The methods below should be defined in a platform specific source.

/**
 * Prints a character to whatever platform the program is compiled for, if the
 * platform supports an output stream. Prototype conforms to the <stdio.h>
 * method.
 */
int putchar(int character);

/**
 * Same as putchar, but prints a null-terminated string. Prototype conforms to
 * the <stdio.h> method.
 */
int puts(const char *str);

/**
 * Prints the string presented to it to the standard output of the platform,
 * and in addition reports success or failure, if supported by the platform.
 */
int rvex_succeed(const char *str);
int rvex_fail(const char *str);

/**
 * Reads a character from whatever input stream the platform has available,
 * waiting until one is available. Prototype conforms to the <stdio.h> method.
 */
int getchar(void);

/*****************************************************************************/
/* Core control registers                                                    */
/*****************************************************************************/

// If CREG_BASE is not overruled by a definition passed to the compiler on the
// command line, default to the rvex core default.
#ifndef CREG_BASE
#define CREG_BASE 0xFFFFFF80
#endif

// Stub definitions for any register type.
#define CREG_UINT32_R(offs)  (*(const volatile unsigned int*)(CREG_BASE+offs))
#define CREG_INT32_R(offs)   (*(const volatile          int*)(CREG_BASE+offs))
#define CREG_UINT32_RW(offs) (*(      volatile unsigned int*)(CREG_BASE+offs))
#define CREG_INT32_RW(offs)  (*(      volatile          int*)(CREG_BASE+offs))
#define CREG_UINT16_R(offs)  (*(const volatile unsigned short*)(CREG_BASE+offs))
#define CREG_INT16_R(offs)   (*(const volatile          short*)(CREG_BASE+offs))
#define CREG_UINT16_RW(offs) (*(      volatile unsigned short*)(CREG_BASE+offs))
#define CREG_INT16_RW(offs)  (*(      volatile          short*)(CREG_BASE+offs))
#define CREG_UINT8_R(offs)   (*(const volatile unsigned char*)(CREG_BASE+offs))
#define CREG_INT8_R(offs)    (*(const volatile          char*)(CREG_BASE+offs))
#define CREG_UINT8_RW(offs)  (*(      volatile unsigned char*)(CREG_BASE+offs))
#define CREG_INT8_RW(offs)   (*(      volatile          char*)(CREG_BASE+offs))

//-----------------------------------------------------------------------------
// Global (shared) registers. Refer to lib/rvex/core/core_globalRegLogic.vhd
// for up-to-date documentation about the registers.
//-----------------------------------------------------------------------------

// Global status register.
#define CR_GSR                  CREG_UINT32_R(0x00)

// Bus configuration request register (intended for debug bus only).
#define CR_BCRR                 CREG_UINT32_R(0x04)

// Current configuration register.
#define CR_CC                   CREG_UINT32_R(0x08)

// Cache/memory block affinity register.
#define CR_AFF                  CREG_UINT32_R(0x0C)
  
//-----------------------------------------------------------------------------
// Context-specific registers. Refer to lib/rvex/core/core_contextRegLogic.vhd
// for up-to-date documentation about the registers.
//-----------------------------------------------------------------------------

// Context control register.
#define CR_CCR                  CREG_UINT32_RW(0x20)

// Saved context control register (stores state before entering trap, restored
// when trap returns).
#define CR_SCCR                 CREG_UINT32_RW(0x24)

// Interrupt enable/disable bits in (S)CCR.
#define CR_CCR_IEN              1 << 0
#define CR_CCR_IEN_C            1 << 1

// Ready-for-trap enable/disable bits in (S)CCR.
#define CR_CCR_RFT              1 << 2
#define CR_CCR_RFT_C            1 << 3

// Breakpoint enable/disable bits in (S)CCR (for self-hosted debug mode).
#define CR_CCR_BPE              1 << 4
#define CR_CCR_BPE_C            1 << 5

// Shorthand notation for enabling/disabling interrupts/traps (in CCR).
#define ENABLE_IRQ              CR_CCR = CR_CCR_IEN
#define DISABLE_IRQ             CR_CCR = CR_CCR_IEN_C
#define ENABLE_TRAPS            CR_CCR = CR_CCR_RFT
#define DISABLE_TRAPS           CR_CCR = CR_CCR_RFT_C

// Link register, branch registers and PC (intended for debug bus only).
#define CR_LR                   CREG_UINT32_R(0x28)
#define CR_BR                   CREG_UINT8_R(0x21)
#define CR_PC                   CREG_UINT32_R(0x2C)

// Trap handler and panic handler (panic handler is used when a trap occurs
// while the ready-for-trap flag is cleared, like a double trap).
#define CR_TH                   CREG_UINT32_RW(0x30)
#define CR_PH                   CREG_UINT32_RW(0x34)

// Trap cause, trap point and trap argument. Trap point doubles as the trap
// return address and is thus writable.
#define CR_TC                   CREG_UINT8_R(0x20)
#define CR_TP                   CREG_UINT32_RW(0x38)
#define CR_TA                   CREG_UINT32_R(0x3C)

// Complete debug control register. Writable only when external debug is
// deactivated.
#define CR_DCR                  CREG_UINT32_RW(0x50)

// Breakpoint addresses. Writable only when external debug is deactivated.
#define CR_BRK0                 CREG_UINT32_RW(0x40)
#define CR_BRK1                 CREG_UINT32_RW(0x44)
#define CR_BRK2                 CREG_UINT32_RW(0x48)
#define CR_BRK3                 CREG_UINT32_RW(0x4C)
#define CR_BRK(i)               CREG_UINT32_RW(0x40 + i*4)

// Breakpoint control bits. Writable only when external debug is deactivated.
#define CR_DCR_BRK              CREG_UINT16_RW(0x52)

// Flags for CR_DCR_BRK. These can be or'd together to enable multiple
// breakpoints at a time.
#define CR_DCR_BRK_DISABLE(i)   0 << (i*4)
#define CR_DCR_BRK_FETCH(i)     1 << (i*4)
#define CR_DCR_BRK_READ(i)      2 << (i*4)
#define CR_DCR_BRK_ACCESS(i)    3 << (i*4)

// Debug control flags register. Writable only when external debug is
// deactivated.
#define CR_DCR_FLAGS            CREG_UINT16_RW(0x50)

// Flag bit index for CR_DCR_FLAGS indicating that only a single instruction
// should be executed after leaving the trap handler.
#define CR_DCR_FLAGS_STEP       1

// Reconfiguration request register.
#define CR_CRR                  CREG_UINT32_RW(0x54)

// Context ID register (returns the index starting from zero of the context
// which the application is running in).
#define CR_CID                  CREG_UINT8_R(0x24)

/*****************************************************************************/
/* Trap causes                                                               */
/*****************************************************************************/
// These are the codes read from CR_TC. They are defined in
// lib/core/core_trap_pkg.vhd.

// No trap occured.
#define TRAP_NONE               0x00

// Exceptions. Cannot be masked.
#define TRAP_INVALID_OP         0x01
#define TRAP_MISALIGNED_BRANCH  0x02
#define TRAP_FETCH_FAULT        0x03
#define TRAP_MISALIGNED_ACCESS  0x04
#define TRAP_DMEM_FAULT         0x05
#define TRAP_LIMMH_FAULT        0x06

// External interrupt trap. This is masked by the interrupt-enable CCR flag.
// The trap argument specifies the interrupt source, or 0 if there are no
// pending interrupts (which can occur if an interrupt is cleared before the
// handler is entered but after the trap has been generated). Interrupts codes
// are platform specific.
#define TRAP_EXT_INTERRUPT      0x07

// Stop trap. This code is used internally by the stop instruction and should
// never be seen by the trap handler.
#define TRAP_STOP               0x08

// Debug traps. These are masked by the breakpoint enable CCR flag in
// self-hosted debug mode, and won't occur in external debug mode (because
// they'll be forwarded to the debugger instead).
#define TRAP_SOFT_DEBUG_0       0xF8
#define TRAP_SOFT_DEBUG_1       0xF9
#define TRAP_SOFT_DEBUG_2       0xFA
#define TRAP_STEP_COMPLETE      0xFB
#define TRAP_HW_BREAKPOINT_0    0xFC
#define TRAP_HW_BREAKPOINT_1    0xFD
#define TRAP_HW_BREAKPOINT_2    0xFE
#define TRAP_HW_BREAKPOINT_3    0xFF

#endif
