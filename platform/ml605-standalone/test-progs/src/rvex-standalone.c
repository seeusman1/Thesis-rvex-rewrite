#include "rvex.h"
#include "rvex_io.h"

#define UART_BASE 0xF0000000
#define UART_DATA (*((volatile unsigned char *)(UART_BASE)))
#define UART_STAT (*((volatile unsigned char *)(UART_BASE+4)))

/**
 * Prints a character to whatever platform the program is compiled for, if the
 * platform supports an output stream. Prototype conforms to the <stdio.h>
 * method.
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
 * Same as putchar, but prints a null-terminated string. Prototype conforms to
 * the <stdio.h> method.
 */
int puts(const char *str) {
  while (*str) putchar((int)(*str++));
  return 0;
}

/**
 * Prints the string presented to it to the standard output of the platform,
 * and in addition reports success or failure, if supported by the platform.
 */
int rvex_succeed(const char *str) {
  return puts(str);
}
int rvex_fail(const char *str) {
  return puts(str);
}

/**
 * Reads a character from whatever input stream the platform has available,
 * waiting until one is available. Prototype conforms to the <stdio.h> method.
 */
int getchar(void) {
  
  // Wait for the RX data ready flag.
  while (!(UART_STAT & (1 << 3)));
  
  // Read from the UART.
  return UART_DATA;
  
}

