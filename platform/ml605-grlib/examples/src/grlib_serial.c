/* Modified 2013 by Joost Hoozemans
 * Interface for accessing Gaisler AMBA Plug&Play Bus.
 * The AHB bus can be interfaced with a simpler bus -
 * the APB bus, also freely available in GRLIB at
 * www.gaisler.com.
 *
 * (C) Copyright 2007
 * Daniel Hellstrom, Gaisler Research, daniel@gaisler.com.
 *
 * See file CREDITS for list of people who contributed to this
 * project.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston,
 * MA 02111-1307 USA
 *
 */

#include "grlib_serial.h"


ambapp_dev_apbuart *leon3_apbuart = (ambapp_dev_apbuart*)UART_BASE_ADDRESS;


int serial_init(void)
{
	int i;
//	unsigned int tmp;

	/* found apbuart, let's init...
	 *
	 *
	 * Receiver & transmitter enable
	 */


//	leon3_apbuart->scaler = CONFIG_SYS_GRLIB_APBUART_SCALER;

	/* dont set bit 11 (debug bit for GRMON) */
	
	leon3_apbuart->ctrl = LEON_REG_UART_CTRL_RE | LEON_REG_UART_CTRL_TE;
	return 0;
}

void serial_putc(const char c)
{
	if (c == '\n')
		serial_putc_raw('\r');
	if (c == '\r')
		serial_putc_raw('\n');

	serial_putc_raw(c);
}

void serial_putc_raw(const char c)
{
	int j;	
	/* Wait if TX FIFO is full */
	while (leon3_apbuart->status & LEON_REG_UART_STATUS_TF) ;

	/* Send data */
	leon3_apbuart->data = (int)c;


//#ifdef DEBUG 
	/* Wait for data to be sent */
	while (!(leon3_apbuart->status & LEON_REG_UART_STATUS_TSE)) ;
//#endif
}

void serial_puts(const char *s)
{
	while (*s) {
		serial_putc(*s++);
	}
}

int serial_getc(void)
{
	/* Wait for a character to arrive. */
	while (!(leon3_apbuart->status & LEON_REG_UART_STATUS_DR)) ;

	/* read data */
	return leon3_apbuart->data;
}

int serial_tstc(void)
{
	return (leon3_apbuart->status &
			LEON_REG_UART_STATUS_DR);
}

/* set baud rate for uart */
void serial_setbrg(void)
{
	int i;
	leon3_apbuart->scaler = CONFIG_SYS_GRLIB_APBUART_SCALER;
	return;
}


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
