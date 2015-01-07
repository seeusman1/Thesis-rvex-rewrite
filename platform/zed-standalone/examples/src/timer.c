#include "rvex.h"

// Context ID.
#define CR_CID          (*(volatile unsigned char*)0xFFFFFFA4)

// Context control register and bit indices.
#define CR_CCR          (*(volatile unsigned int*)0xFFFFFFA0)
#define CR_CCR_IEN      0
#define CR_CCR_IEN_C    1
#define CR_CCR_RFT      2
#define CR_CCR_RFT_C    3
#define CR_CCR_BPE      4
#define CR_CCR_BPE_C    5

// Trap and panic handler.
#define CR_TH           (*(volatile unsigned int*)0xFFFFFFB0)
#define CR_PH           (*(volatile unsigned int*)0xFFFFFFB4)

// Trap cause, point and argument.
#define CR_TC           (*(volatile unsigned char*)0xFFFFFFA0)
#define CR_TP           (*(volatile unsigned int*)0xFFFFFFB8)
#define CR_TA           (*(volatile unsigned int*)0xFFFFFFBC)

// Trap codes.
#define RVEX_TRAP_EXT_INTERRUPT   7

// Trap argument codes for interrupts.
#define IRQ_RIT                   1

static void trapHandler(void) {
  switch (CR_TC) {
    case RVEX_TRAP_EXT_INTERRUPT:
      switch (CR_TA) {
        case IRQ_RIT:
          putchar(CR_CID + '0');
        
      }
    
  }
}

static void panicHandler(void) {
  putchar(CR_CID + 'A');
  while (1);
}

int main(void) {
  
  // Setup trap and panic handler.
  CR_TH = (unsigned int)&trapHandler;
  CR_PH = (unsigned int)&panicHandler;
  
  // Enable interrupts.
  CR_CCR = (1 << CR_CCR_RFT) | (1 << CR_CCR_IEN);
  
  while (1);
}
