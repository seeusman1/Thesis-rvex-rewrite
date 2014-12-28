#include "_basic_io.h"

#define UART_BASE 0xF0000000
#define UART_DATA (*((volatile unsigned char *)(UART_BASE)))
#define UART_STAT (*((volatile unsigned char *)(UART_BASE+4)))

/**
 * Prints a character to the UART. Prototype conforms to the <stdio.h> method.
 */
int putchar(int character) {
  unsigned char c = character;
  
  // Wait for the TX data FIFO ready flag.
  while (!(UART_STAT & (1 << 1)));
  
  // Write to the UART.
  UART_DATA = c;
  
  return 0;
}

/**
 * Prints a string to the UART. Prototype conforms to the <stdio.h> method.
 */
int puts(const char *str) {
  while (*str) putchar((int)(*str++));
  return 0;
}

/**
 * Reads a character from the UART, waiting until one is available. Prototype
 * conforms to the <stdio.h> method.
 */
int getchar(void) {
  
  // Wait for the RX data ready flag.
  while (!(UART_STAT & (1 << 3)));
  
  // Read from the UART.
  return UART_DATA;
  
}

