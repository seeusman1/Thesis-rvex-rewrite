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

#ifndef __GRLIB_SERIAL_H__
#define __GRLIB_SERIAL_H__


#define UART_BASE_ADDRESS 	0x80000100

#define CONFIG_SYS_CLK_FREQ	75000000	/* 75MHz */

#define CONFIG_BAUDRATE		115200	

#define CONFIG_SYS_GRLIB_APBUART_SCALER  ((((CONFIG_SYS_CLK_FREQ*10)/(CONFIG_BAUDRATE*8))-5)/10)


int serial_init(void);
void serial_putc(const char c);
void serial_putc_raw(const char c);
void serial_puts(const char *s);
int serial_getc(void);
int serial_tstc(void);
void serial_setbrg(void);

/*
 *  LEON UART Status Registers.
 */

#define LEON_REG_UART_STATUS_DR   0x00000001	/* Data Ready */
#define LEON_REG_UART_STATUS_TSE  0x00000002	/* TX Send Register Empty */
#define LEON_REG_UART_STATUS_THE  0x00000004	/* TX Hold Register Empty */
#define LEON_REG_UART_STATUS_BR   0x00000008	/* Break Error */
#define LEON_REG_UART_STATUS_OE   0x00000010	/* RX Overrun Error */
#define LEON_REG_UART_STATUS_PE   0x00000020	/* RX Parity Error */
#define LEON_REG_UART_STATUS_FE   0x00000040	/* RX Framing Error */
#define LEON_REG_UART_STATUS_THF  0x00000080	/* TX FIFO halffull */
#define LEON_REG_UART_STATUS_RHF  0x00000100	/* RX FIFO halffull */
#define LEON_REG_UART_STATUS_TF   0x00000200	/* TX FIFO full */
#define LEON_REG_UART_STATUS_RF   0x00000400	/* RX FIFO full */
#define LEON_REG_UART_STATUS_ERR  0x00000078	/* Error Mask */

/*
 *  LEON UART Ctrl Registers.
 */

#define LEON_REG_UART_CTRL_RE     0x00000001	/* Receiver enable */
#define LEON_REG_UART_CTRL_TE     0x00000002	/* Transmitter enable */
#define LEON_REG_UART_CTRL_RI     0x00000004	/* Receiver interrupt enable */
#define LEON_REG_UART_CTRL_TI     0x00000008	/* Transmitter interrupt enable */
#define LEON_REG_UART_CTRL_PS     0x00000010	/* Parity select */
#define LEON_REG_UART_CTRL_PE     0x00000020	/* Parity enable */
#define LEON_REG_UART_CTRL_FL     0x00000040	/* Flow control enable */
#define LEON_REG_UART_CTRL_LB     0x00000080	/* Loop Back enable */
#define LEON_REG_UART_CTRL_DBG    (1<<11)	/* Debug Bit used by GRMON */


typedef struct {
	volatile unsigned int data;
	volatile unsigned int status;
	volatile unsigned int ctrl;
	volatile unsigned int scaler;
} ambapp_dev_apbuart;


#endif
