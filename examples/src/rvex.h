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

// Converts a global control register offset to its physical address.
#define CREG_GLOB_ADDR(offs) (CREG_BASE + (offs))

// Converts a context control register offset to its physical address.
#define CREG_ADDR_CTXT(offs) (CREG_BASE + (offs) + 0x200)

// Stub definitions for any register type.
#define CREG_UINT32_R(addr)  (*(const volatile unsigned int*)(addr))
#define CREG_INT32_R(addr)   (*(const volatile          int*)(addr))
#define CREG_UINT32_RW(addr) (*(      volatile unsigned int*)(addr))
#define CREG_INT32_RW(addr)  (*(      volatile          int*)(addr))
#define CREG_UINT16_R(addr)  (*(const volatile unsigned short*)(addr))
#define CREG_INT16_R(addr)   (*(const volatile          short*)(addr))
#define CREG_UINT16_RW(addr) (*(      volatile unsigned short*)(addr))
#define CREG_INT16_RW(addr)  (*(      volatile          short*)(addr))
#define CREG_UINT8_R(addr)   (*(const volatile unsigned char*)(addr))
#define CREG_INT8_R(addr)    (*(const volatile          char*)(addr))
#define CREG_UINT8_RW(addr)  (*(      volatile unsigned char*)(addr))
#define CREG_INT8_RW(addr)   (*(      volatile          char*)(addr))

//-----------------------------------------------------------------------------
// Global (shared) registers. Refer to lib/rvex/core/core_globalRegLogic.vhd
// for up-to-date documentation about the registers.
//-----------------------------------------------------------------------------

// Global status register.
#define CR_GSR_ADDR             CREG_GLOB_ADDR(0x000)
#define CR_GSR                  CREG_UINT32_R(CR_GSR_ADDR)

// Bus configuration request register (intended for debug bus only).
#define CR_BCRR_ADDR            CREG_GLOB_ADDR(0x004)
#define CR_BCRR                 CREG_UINT32_R(CR_BCRR_ADDR)

// Current configuration register.
#define CR_CC_ADDR              CREG_GLOB_ADDR(0x008)
#define CR_CC                   CREG_UINT32_R(CR_CC_ADDR)

// Cache/memory block affinity register.
#define CR_AFF_ADDR             CREG_GLOB_ADDR(0x00C)
#define CR_AFF                  CREG_UINT32_R(CR_AFF_ADDR)

// Cache control register
#define CR_CACHE_ADDR			CREG_GLOB_ADDR(0x800)
#define CR_CACHE                CREG_UINT32_RW(CR_CACHE_ADDR)

// Cycle counter.
#define CR_CNT_ADDR             CREG_GLOB_ADDR(0x010)
#define CR_CNT                  CREG_UINT32_R(CR_CNT_ADDR)

//Processor version register
#define CR_PVR_ADDR				CREG_GLOB_ADDR(0x014)
#define CR_PVR					CREG_UINT32_R(CR_PVR_ADDR)

//Cache sizes register
#define CR_CSR_ADDR				CREG_GLOB_ADDR(0x018)
#define CR_CSR					CREG_UINT32_R(CR_CSR_ADDR)

//Global scratch register
#define CR_GSCR_ADDR			CREG_GLOB_ADDR(0x01C)
#define CR_GSCR					CREG_UINT32_RW(CR_GSCR_ADDR)

//Global scratch register
#define CR_GSCR2_ADDR			CREG_GLOB_ADDR(0x020)
#define CR_GSCR2				CREG_UINT32_RW(CR_GSCR2_ADDR)

//Global scratch register
#define CR_GSCR3_ADDR			CREG_GLOB_ADDR(0x024)
#define CR_GSCR3				CREG_UINT32_RW(CR_GSCR3_ADDR)

//Global scratch register
#define CR_GSCR4_ADDR			CREG_GLOB_ADDR(0x028)
#define CR_GSCR4				CREG_UINT32_RW(CR_GSCR4_ADDR)


//-----------------------------------------------------------------------------
// Context-specific registers. Refer to lib/rvex/core/core_contextRegLogic.vhd
// for up-to-date documentation about the registers.
//-----------------------------------------------------------------------------

// Context control register.
#define CR_CCR_ADDR             CREG_ADDR_CTXT(0x00)
#define CR_CCR                  CREG_UINT32_RW(CR_CCR_ADDR)

// Saved context control register (stores state before entering trap, restored
// when trap returns).
#define CR_SCCR_ADDR            CREG_ADDR_CTXT(0x04)
#define CR_SCCR                 CREG_UINT32_RW(CR_SCCR_ADDR)

// Interrupt enable/disable bits in (S)CCR.
#define CR_CCR_IEN              (1 << 0)
#define CR_CCR_IEN_C            (1 << 1)

// Ready-for-trap enable/disable bits in (S)CCR.
#define CR_CCR_RFT              (1 << 2)
#define CR_CCR_RFT_C            (1 << 3)

// Breakpoint enable/disable bits in (S)CCR (for self-hosted debug mode).
#define CR_CCR_BPE              (1 << 4)
#define CR_CCR_BPE_C            (1 << 5)

// Kernel mode enable/disable bits in (S)CCR
#define CR_CCR_KME              (1 << 8)
#define CR_CCR_KME_C            (1 << 9)

// Shorthand notation for enabling/disabling interrupts/traps (in CCR).
#define ENABLE_IRQ              (CR_CCR = CR_CCR_IEN)
#define DISABLE_IRQ             (CR_CCR = CR_CCR_IEN_C)
#define ENABLE_TRAPS            (CR_CCR = CR_CCR_RFT)
#define DISABLE_TRAPS           (CR_CCR = CR_CCR_RFT_C)

// Link register, branch registers and PC (intended for debug bus only).
#define CR_LR_ADDR              CREG_ADDR_CTXT(0x08)
#define CR_LR                   CREG_UINT32_R(CR_LR_ADDR)
#define CR_BR_ADDR              CREG_ADDR_CTXT(0x01)
#define CR_BR                   CREG_UINT8_R(CR_BR_ADDR)
#define CR_PC_ADDR              CREG_ADDR_CTXT(0x0C)
#define CR_PC                   CREG_UINT32_R(CR_PC_ADDR)

// Trap handler and panic handler (panic handler is used when a trap occurs
// while the ready-for-trap flag is cleared, like a double trap).
#define CR_TH_ADDR              CREG_ADDR_CTXT(0x10)
#define CR_TH                   CREG_UINT32_RW(CR_TH_ADDR)
#define CR_PH_ADDR              CREG_ADDR_CTXT(0x14)
#define CR_PH                   CREG_UINT32_RW(CR_PH_ADDR)

// Trap cause, trap point and trap argument. Trap point doubles as the trap
// return address and is thus writable.
#define CR_TC_ADDR              CREG_ADDR_CTXT(0x00)
#define CR_TC                   CREG_UINT8_R(CR_TC_ADDR)
#define CR_TP_ADDR              CREG_ADDR_CTXT(0x18)
#define CR_TP                   CREG_UINT32_RW(CR_TP_ADDR)
#define CR_TA_ADDR              CREG_ADDR_CTXT(0x1C)
#define CR_TA                   CREG_UINT32_R(CR_TA_ADDR)

// Complete debug control registers. Writable only when external debug is
// deactivated.
#define CR_DCR_ADDR             CREG_ADDR_CTXT(0x30)
#define CR_DCR2_ADDR            CREG_ADDR_CTXT(0x34)
#define CR_DCR                  CREG_UINT32_RW(CR_DCR_ADDR)
#define CR_DCR2                 CREG_UINT32_RW(CR_DCR2_ADDR)

// Breakpoint addresses. Writable only when external debug is deactivated.
#define CR_BRK_ADDR(i)          CREG_ADDR_CTXT(0x20 + i*4)
#define CR_BRK_ADDR0            CR_BRK_ADDR(0)
#define CR_BRK_ADDR1            CR_BRK_ADDR(1)
#define CR_BRK_ADDR2            CR_BRK_ADDR(2)
#define CR_BRK_ADDR3            CR_BRK_ADDR(3)
#define CR_BRK(i)               CREG_UINT32_RW(CR_BRK_ADDR(i))
#define CR_BRK0                 CR_BRK(0)
#define CR_BRK1                 CR_BRK(1)
#define CR_BRK2                 CR_BRK(2)
#define CR_BRK3                 CR_BRK(3)

// Breakpoint control bits. Writable only when external debug is deactivated.
#define CR_DCR_BRK_ADDR         CREG_ADDR_CTXT(0x32)
#define CR_DCR_BRK              CREG_UINT16_RW(CR_DCR_BRK)

// Flags for CR_DCR_BRK. These can be or'd together to enable multiple
// breakpoints at a time.
#define CR_DCR_BRK_DISABLE(i)   (0 << (i*4))
#define CR_DCR_BRK_FETCH(i)     (1 << (i*4))
#define CR_DCR_BRK_READ(i)      (2 << (i*4))
#define CR_DCR_BRK_ACCESS(i)    (3 << (i*4))

// Debug control flags register. Writable only when external debug is
// deactivated.
#define CR_DCR_FLAGS_ADDR       CREG_ADDR_CTXT(0x30)
#define CR_DCR_FLAGS            CREG_UINT16_RW(CR_DCR_FLAGS_ADDR)

// Flag bit index for CR_DCR_FLAGS indicating that only a single instruction
// should be executed after leaving the trap handler.
#define CR_DCR_FLAGS_STEP       1

// Reconfiguration request register.
#define CR_CRR_ADDR             CREG_ADDR_CTXT(0x38)
#define CR_CRR                  CREG_UINT32_RW(CR_CRR_ADDR)

// Context ID register (returns the index starting from zero of the context
// which the application is running in).
#define CR_CID_ADDR             CREG_ADDR_CTXT(0x04)
#define CR_CID                  CREG_UINT8_R(CR_CID_ADDR)

// Scratch-pad registers. No hardware function, just places to store words in.
// RET is intended to be used for the main() return value to test for success
// or failure of a program.
#define CR_SCRP_ADDR            CREG_ADDR_CTXT(0x58)
#define CR_SCRP2_ADDR           CREG_ADDR_CTXT(0x5C)
#define CR_SCRP3_ADDR           CREG_ADDR_CTXT(0x60)
#define CR_SCRP4_ADDR           CREG_ADDR_CTXT(0x64)
#define CR_RET_ADDR             CREG_ADDR_CTXT(0x34)
#define CR_SCRP                 CREG_UINT32_RW(CR_SCRP_ADDR)
#define CR_SCRP2                CREG_UINT32_RW(CR_SCRP2_ADDR)
#define CR_SCRP3                CREG_UINT32_RW(CR_SCRP3_ADDR)
#define CR_SCRP4                CREG_UINT32_RW(CR_SCRP4_ADDR)
#define CR_RET                  CREG_INT8_RW(CR_RET_ADDR)

// Context cycle counter. Increments whenever a context is non-idle. Writing 0
// to it clears the counter, writing 1 clears all context counters
// simultaneously.
#define CR_C_CYC_ADDR           CREG_ADDR_CTXT(0x3C)
#define CR_C_CYC                CREG_UINT32_RW(CR_C_CYC_ADDR)

// Upper 32 bits of cycle counter.
#define CR_C_CYCH_ADDR          CREG_ADDR_CTXT(0x40)
#define CR_C_CYCH               CREG_UINT32_RW(CR_C_CYCH_ADDR)

// Saved upper 32 bits of cycle counter. The upper 32 bits of the cycle counter
// are saved to this register whenever the lower 32 bits are read.
#define CR_C_CYCHS_ADDR         CREG_ADDR_CTXT(0x44)
#define CR_C_CYCHS              CREG_UINT32_RW(CR_C_CYCHS_ADDR)

// Context stall cycle counter, counts cycles wherein the context is non-idle
// and stalled. Writing to the register clears it.
#define CR_C_STALL_ADDR         CREG_ADDR_CTXT(0x48)
#define CR_C_STALL              CREG_UINT32_RW(CR_C_STALL_ADDR)

// Committed bundle counter. Writing to the register clears it.
#define CR_C_BUN_ADDR           CREG_ADDR_CTXT(0x4C)
#define CR_C_BUN                CREG_UINT32_RW(CR_C_BUN_ADDR)

// Committed syllable counter. Writing to the register clears it.
#define CR_C_SYL_ADDR           CREG_ADDR_CTXT(0x50)
#define CR_C_SYL                CREG_UINT32_RW(CR_C_SYL_ADDR)

// Committed NOP syllable counter. Writing to the register clears it.
#define CR_C_NOP_ADDR           CREG_ADDR_CTXT(0x54)
#define CR_C_NOP                CREG_UINT32_RW(CR_C_NOP_ADDR)

//Instruction cache access counter.
#define CR_C_IACC_ADDR			CREG_ADDR_CTXT(0x58)
#define CR_C_IACC				CREG_UINT32_RW(CR_C_IACC_ADDR)

//Instruction cache miss counter.
#define CR_C_IMISS_ADDR			CREG_ADDR_CTXT(0x5C)
#define CR_C_IMISS				CREG_UINT32_RW(CR_C_IMISS_ADDR)

//Data cache read access counter
#define CR_C_DRACC_ADDR			CREG_ADDR_CTXT(0x60)
#define CR_C_DRACC				CREG_UINT32_RW(CR_C_DRACC_ADDR)

//Data cache read miss counter
#define CR_C_DRMISS_ADDR		CREG_ADDR_CTXT(0x64)
#define CR_C_DRMISS				CREG_UINT32_RW(CR_C_DRMISS_ADDR)

//Data cache write access counter
#define CR_C_DWACC_ADDR			CREG_ADDR_CTXT(0x68)
#define CR_C_DWACC				CREG_UINT32_RW(CR_C_DWACC_ADDR)

//Data cache write miss counter
#define CR_C_DWMISS_ADDR		CREG_ADDR_CTXT(0x6C)
#define CR_C_DWMISS				CREG_UINT32_RW(CR_C_DWMISS_ADDR)

//Data cache bypassed access counter
#define CR_C_DBYPASS_ADDR		CREG_ADDR_CTXT(0x70)
#define CR_C_DBYPASS			CREG_UINT32_RW(CR_C_DBYPASS_ADDR)

//Data cache accesses with buffered write counter
#define CR_C_DWBUF_ADDR			CREG_ADDR_CTXT(0x74)
#define CR_C_DWBUF				CREG_UINT32_RW(CR_C_DWBUF_ADDR)


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
