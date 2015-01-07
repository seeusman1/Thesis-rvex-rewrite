/*
 * Program to test GRLIB APBUART
 *
 *
 */

#include "grlib_serial.h"
//#include "uart.c"

void printregs();
int bs1 = 1;
int bs2 = 2;
int bs3 = 3;

extern int* __DATA_START;
extern waitctr1, waitctr2;
int main()
{

	char inputchar, c;
	int i,j;
	int status = 0;
	char string[12];
	int haschar;
	
	int ctr1[12];
	int ctr2[12];

	int *dptr = (int*)(&__DATA_START);

	int* reset_reg = (int*) 0x80000500;
	int* intlevel = (int*)0x80000200;
	int* intmask = (int*)0x80000240;

	int* intforce = (int*)0x80000208;
	
	int* VCR = (int*)0xFFFFF000;
	int* APB_VCR = (int*)0x80001000;


	*intmask = 0xFFFE;
	*intlevel = 0;

	dptr[10] = 0x88888888;
	dptr[11] +=1 ; //increment value in memory everytime program is run

//	*intforce = swap(0x08);

	serial_init();
	//leon3_apbuart->ctrl = swap((LEON_REG_UART_CTRL_RE | LEON_REG_UART_CTRL_TE));

	serial_setbrg();
	

/*
	serial_putc('l');
	tohex(string, sizeof(long long));
	serial_puts(string);

	serial_putc('\n');
	serial_putc('d');
	tohex(string, sizeof(double));
	serial_puts(string);

	dptr[12] += 1;
*/
	
	serial_puts("tested GRLIB APBUART, now entering echo mode...\n");


while(1)
{
	c = serial_getc();
	serial_putc(c);
}

}



