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

#ifndef _RVSRV_IFACE_H_
#define _RVSRV_IFACE_H_

#include "types.h"

/**
 * Size of an rvsrv page: the maximum amount of bytes which can be transferred
 * in a single operation.
 */
#define RVSRV_PAGE_SIZE_LOG2 12
#define RVSRV_PAGE_SIZE (1 << (RVSRV_PAGE_SIZE_LOG2))

/**
 * Stores the hostname and port to connect to internally. The connection is not
 * made until the first call to one of the read or write methods.
 */
int rvsrv_setup(const char *host, int port);

/**
 * Closes the connection to rvsrv if a connection is open.
 */
void rvsrv_close(void);

/**
 * Sends the stop command to the server.
 */
int rvsrv_stopServer(void);

/**
 * Reads a single byte, halfword or word from the hardware (size set to 1, 2 or
 * 4 respectively). Returns 1 when successful, 0 when a bus error occured, or
 * -1 when a fatal error occured. In the latter case, an error will be printed
 * to stderr. When a bus error occurs, value is set to the bus fault.
 */
int rvsrv_readSingle(
  uint32_t address,
  uint32_t *value,
  int size
);

/**
 * Reads at most 4096 bytes in a single command. The address does not need to
 * be aligned, but it's slightly faster if it is. Returns 1 when successful,
 * 0 when a bus error occured, or -1 when a fatal error occured. In the latter
 * case, an error will be printed to stderr. If a bus error occured and fault
 * is not null, *faultCode will be set to the bus fault. Only the last bus
 * access is checked for fault conditions.
 */
int rvsrv_readBulk(
  uint32_t address,
  unsigned char *buffer,
  int size,
  uint32_t *faultCode
);

/**
 * Writes a single byte, halfword or word to the hardware (size set to 1, 2 or
 * 4 respectively). Returns 1 when successful, 0 when a bus error occured, or
 * -1 when a fatal error occured. In the latter case, an error will be printed
 * to stderr. If a bus error occured and fault is not null, *faultCode will be
 * set to the bus fault.
 */
int rvsrv_writeSingle(
  uint32_t address,
  uint32_t value,
  int size,
  uint32_t *faultCode
);

/**
 * Writes at most 4096 bytes in a single command. The address does not need to
 * be aligned, but it's slightly faster if it is. Returns 1 when successful,
 * 0 when a bus error occured, or -1 when a fatal error occured. In the latter
 * case, an error will be printed to stderr. If a bus error occured and fault
 * is not null, *faultCode will be set to the bus fault. Only the last bus
 * access is checked for fault conditions.
 */
int rvsrv_writeBulk(
  uint32_t address,
  unsigned char *buffer,
  int size,
  uint32_t *faultCode
);

#endif
