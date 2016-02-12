/* Debug interface for standalone r-VEX processor
 * 
 * Copyright (C) 2008-2016 by TU Delft.
 * All Rights Reserved.
 * 
 * THIS IS A LEGAL DOCUMENT, BY USING r-VEX,
 * YOU ARE AGREEING TO THESE TERMS AND CONDITIONS.
 * 
 * No portion of this work may be used by any commercial entity, or for any
 * commercial purpose, without the prior, written permission of TU Delft.
 * Nonprofit and noncommercial use is permitted as described below.
 * 
 * 1. r-VEX is provided AS IS, with no warranty of any kind, express
 * or implied. The user of the code accepts full responsibility for the
 * application of the code and the use of any results.
 * 
 * 2. Nonprofit and noncommercial use is encouraged. r-VEX may be
 * downloaded, compiled, synthesized, copied, and modified solely for nonprofit,
 * educational, noncommercial research, and noncommercial scholarship
 * purposes provided that this notice in its entirety accompanies all copies.
 * Copies of the modified software can be delivered to persons who use it
 * solely for nonprofit, educational, noncommercial research, and
 * noncommercial scholarship purposes provided that this notice in its
 * entirety accompanies all copies.
 * 
 * 3. ALL COMMERCIAL USE, AND ALL USE BY FOR PROFIT ENTITIES, IS EXPRESSLY
 * PROHIBITED WITHOUT A LICENSE FROM TU Delft (J.S.S.M.Wong@tudelft.nl).
 * 
 * 4. No nonprofit user may place any restrictions on the use of this software,
 * including as modified by the user, by any other authorized user.
 * 
 * 5. Noncommercial and nonprofit users may distribute copies of r-VEX
 * in compiled or binary form as set forth in Section 2, provided that
 * either: (A) it is accompanied by the corresponding machine-readable source
 * code, or (B) it is accompanied by a written offer, with no time limit, to
 * give anyone a machine-readable copy of the corresponding source code in
 * return for reimbursement of the cost of distribution. This written offer
 * must permit verbatim duplication by anyone, or (C) it is distributed by
 * someone who received only the executable form, and is accompanied by a
 * copy of the written offer of source code.
 * 
 * 6. r-VEX was developed by Stephan Wong, Thijs van As, Fakhar Anjam,
 * Roel Seedorf, Anthony Brandon, Jeroen van Straten. r-VEX is currently
 * maintained by TU Delft (J.S.S.M.Wong@tudelft.nl).
 * 
 * Copyright (C) 2008-2016 by TU Delft.
 */

#ifndef _SERIAL_H_
#define _SERIAL_H_

/**
 * Opens a serial port. Negative return values indicate failure as specified
 * by the documentation for open(), positive return values are a file
 * descriptor for the open port. The port is opened in blocking mode.
 */
int serial_open(const char *name, const int baud);

/**
 * Closes a previously opened serial port.
 */
void serial_close(int *port);

/**
 * Updates the serial port after a call to select_wait(). Reads data from the
 * port into our buffer.
 */
int serial_update(int f);

/**
 * Writes all pending data in the transmit buffers to the serial port.
 */
int serial_flush(int f);

/**
 * Returns a byte from the application receive FIFO, or -1 if the FIFO is empty.
 */
int serial_appReceive(int f);

/**
 * Pushes a byte onto the application transmit buffer.
 */
int serial_appSend(int f, int data);

/**
 * Returns a byte from the debug receive FIFO, or -1 if the FIFO is empty. 256
 * is returned as a packet delimiter.
 */
int serial_debugReceive(int f);

/**
 * Pushes a byte onto the debug transmit buffer when data lies between 0 and
 * 255, or pushes a packet delimiter when data is greater than or equal to
 * 256. In the latter case, the serial unit will ensure that at least
 * data-256 bytes are sent before the next packet completes, to give the
 * hardware time to send the reply.
 */
int serial_debugSend(int f, int data);

#endif
