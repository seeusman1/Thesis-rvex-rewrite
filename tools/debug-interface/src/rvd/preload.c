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

#include <stdio.h>
#include <inttypes.h>
#include <stdlib.h>

#include "preload.h"
#include "rvsrvInterface.h"

/**
 * Current preload buffer pointer.
 */
static unsigned char *preloadBuffer = 0;

/**
 * Number of bytes in the current preload buffer.
 */
static int preloadSize = 0;

/**
 * Starting address/offset for the preload buffer.
 */
static uint32_t preloadAddress = 0;

/**
 * Preloads at most 4096 bytes, replacing the old preload buffer. Preloading
 * zero bytes effectively invalidates the preload buffer. Returns 1 when
 * successful, 0 when a bus error occured, or -1 when a fatal error occured.
 * In the latter case, an error will be printed to stderr. If a bus error
 * occured and fault is not null, *faultCode will be set to the bus fault.
 * Only the last bus access is checked for fault conditions.
 */
int preload_load(
  uint32_t address,
  int size,
  uint32_t *faultCode
) {
  
  // Check the size.
  if ((size > 4096) || (size < 0)) {
    fprintf(stderr, "Error: cannot preload more than 4096 bytes at a time.\n");
    return -1;
  }
  
  // Free the previous preload buffer, if there is one.
  if (preloadBuffer) {
    free(preloadBuffer);
  }
  
  if (size) {
    
    // Allocate a new preload buffer of the requested size.
    preloadBuffer = (unsigned char *)malloc(size);
    if (!preloadBuffer) {
      perror("Failed to allocate preload buffer");
      return -1;
    }
    preloadSize = size;
    preloadAddress = address;
    
    // Perform a bulk read to load the preload buffer.
    return rvsrv_readBulk(address, preloadBuffer, size, faultCode);
    
  } else {
    
    // Invalidate the preload buffer.
    preloadBuffer = 0;
    preloadSize = 0;
    preloadAddress = 0;
    
  }
  
  return 1;
}

/**
 * Reads a single byte, halfword or word from the preload buffer. Returns 1
 * when successful, 0 if the value was not preloaded, or -1 when a fatal error
 * occured. In the latter case, an error will be printed to stderr.
 */
int preload_read(
  uint32_t address,
  uint32_t *value,
  int size
) {
  
  // Fail if the preload buffer does not contain the requested memory.
  if (address < preloadAddress) {
    return 0;
  }
  if (address + size > preloadAddress + preloadSize) {
    return 0;
  }
  
  // Load the value from the preload buffer.
  *value = preloadBuffer[address - preloadAddress];
  if (size >= 2) {
    *value <<= 8;
    *value |= preloadBuffer[address - preloadAddress + 1];
  }
  if (size >= 3) {
    *value <<= 8;
    *value |= preloadBuffer[address - preloadAddress + 2];
  }
  if (size >= 4) {
    *value <<= 8;
    *value |= preloadBuffer[address - preloadAddress + 3];
  }
  
  // Done.
  return 1;
}

/**
 * Frees any memory used by the preload buffer.
 */
void preload_free(void) {
  
  // Free the preload buffer, if there is one.
  if (preloadBuffer) {
    free(preloadBuffer);
    preloadBuffer = 0;
    preloadSize = 0;
    preloadAddress = 0;
  }
  
}
