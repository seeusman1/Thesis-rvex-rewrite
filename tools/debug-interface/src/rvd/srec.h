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

#ifndef _SREC_H_
#define _SREC_H_

#include "types.h"

/**
 * Initializes an srec reader state object. If this returns null, an error
 * occured (which will have been printed). When the file has been read,
 * srecReadFree() must be called on the returned pointer, if non-null.
 */
void *srecReadInit(void);

/**
 * Reads from an srec file. state should be set to the pointer returned by
 * srecReadInit(). f is the file descriptor to read from, buffer is the buffer
 * to read to, and count is the maximum amount of characters to read. address
 * specifies the address corresponding to the start of the buffer in srec
 * address space; if this does not match the current address in the srec, no
 * bytes will be read and 0 is returned. When the end of the file has been
 * reached, 0 is returned as well. If an error occurs, -1 is returned and an
 * error is printed. Otherwise, this returns the number of bytes written to
 * the buffer.
 */
int srecRead(void *state, int f, unsigned char *buffer, int count, uint32_t address);

/**
 * Returns the number of bytes read from the file (as in, ASCII bytes, not the
 * data bytes described by the file) since the last call to this function. Can
 * be used for progress indication.
 */
int srecReadProgressDelta(void *state);

/**
 * Returns nonzero of the end of the file has been reached.
 */
int srecReadEof(void *state);

/**
 * Returns the expected address needed for the next read operation to succeed.
 */
uint32_t srecReadExpectedAddress(void *state);

/**
 * Frees the state data structure allocated by srecReadInit().
 */
void srecReadFree(void *state);

/**
 * Writes an srec file header.
 */
int srecWriteHeader(int f);

/**
 * Writes the given buffer, starting at the given address, to an srec output
 * file.
 */
int srecWrite(int f, unsigned char *buffer, int count, uint32_t address);

/**
 * Writes an srec file footer.
 */
int srecWriteFooter(int f);

#endif
