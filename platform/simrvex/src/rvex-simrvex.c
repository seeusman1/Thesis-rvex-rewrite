
/* We prefer to use stderr to avoid mixing with trace output */
#define SIM_WRITE_FD 2


//needs a 12 bytes sized char array, returns a string repres. of the supplied val.
void tohex(char* s, int val)
{
	int i;
	char tmp;
	int nibble;
	s[0] = '0';
	s[1] = 'x';
//	s[10] = '\n';
	s[10] = '\0';
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


/**
 * Prints a character to whatever platform the program is compiled for, if the
 * platform supports an output stream. Prototype conforms to the <stdio.h>
 * method.
 */
int putchar(int character){
	sim_write(SIM_WRITE_FD, &character, 1);
	return 0;
}

/**
 * Same as putchar, but prints a null-terminated string. Prototype conforms to
 * the <stdio.h> method.
 */
int puts(const char *str) {
	int len = 0;
	const char* orig = str;
	while(*str++) len++;
	sim_write(SIM_WRITE_FD, orig, len);
}

int puthex(int val)
{
	char str[12];
	tohex(str, val);
	return puts(str);
}

/**
 * Prints the string presented to it to the standard output of the platform,
 * and in addition reports success or failure, if supported by the platform.
 */
int rvex_succeed(const char *str) {
//#if 0
  puts("success: ");
  puts(str);
//#endif
  return 0;
}

int rvex_fail(const char *str) {
//#if 0
  puts("failure: ");
  puts(str);
//#endif
  return 0;
}

/**
 * Reads a character from whatever input stream the platform has available,
 * waiting until one is available. Prototype conforms to the <stdio.h> method.
 */
int getchar(void) {
  while (1) ;
  return 0;
}

int stop(int exit_code)
{
	_stop();
}
