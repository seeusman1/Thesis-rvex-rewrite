#include "rvex.h"
#include "platform.h"

/**
 * Prints a character to whatever platform the program is compiled for, if the
 * platform supports an output stream. Prototype conforms to the <stdio.h>
 * method.
 */
int putchar(int character) {
  unsigned char c = character;
  
#ifndef SIM
  // Wait for the TX data FIFO ready flag.
  while (!(UART_STAT & (1 << 1)));
#endif
  
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


//needs a 12 bytes sized char array, returns a string repres. of the supplied val.
void tohex(char* s, int val)
{
	int i;
	char tmp;
	int nibble;
	s[0] = '0';
	s[1] = 'x';
	s[10] = '\n';
//	s[10] = '\0';
	s[11] = '\0';
	for(i = 0; i < 8; i++)
	{
		nibble = val&0xF;
		if (nibble > 9) tmp = 'A'-10+nibble;
		else tmp = '0'+nibble;
		s[9-i] = tmp;
		val = val>>4;
	}
}

