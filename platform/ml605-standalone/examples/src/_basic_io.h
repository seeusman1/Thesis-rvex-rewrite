#ifndef _BASIC_IO_H_
#define _BASIC_IO_H_

/**
 * Prints a character to the UART. Prototype conforms to the <stdio.h> method.
 */
int putchar(int character);

/**
 * Prints a string to the UART. Prototype conforms to the <stdio.h> method.
 */
int puts(const char *str);

/**
 * Reads a character from the UART, waiting until one is available. Prototype
 * conforms to the <stdio.h> method.
 */
int getchar(void);

#endif
