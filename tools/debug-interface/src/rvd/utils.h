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

#ifndef _UTILS_H_
#define _UTILS_H_

#include <stdint.h>

/**
 * Type used to record the iteration state for iterating over pages within an
 * address range.
 */
typedef struct {
  
  /**
   * Size of a page. MUST be a power of 2.
   */
  uint32_t pageSize;
  
  /**
   * Number of bytes remaining.
   */
  int remain;
  
  /**
   * Next address.
   */
  uint32_t address;
  
  /**
   * Base address for the current page.
   */
  uint32_t base;
  
  /**
   * Start offset within the current page.
   */
  uint32_t startOffs;
  
  /**
   * Stop offset within the current page + 1.
   */
  uint32_t stopOffs;
  
  /**
   * Number of bytes valid in the current page.
   */
  uint32_t numBytes;
  
} iterPage_t;

/**
 * Initializes page iteration. iterPage() should be called before anything else
 * after this initialization.
 */
iterPage_t iterPageInit(uint32_t start, int count, uint32_t pageSize);

/**
 * Iterates to the next page, or returns 0 when done.
 */
int iterPage(iterPage_t *i);

/**
 * Hexdump printing modes. The first three are used to properly print a hexdump
 * with multiple identical lines skipped, which makes reading dumps of sparse
 * data a bit less tedious. HEXDUMP_NO_SKIPPING can be used to force all lines
 * to be dumped.
 */
#define HEXDUMP_PROLOGUE     0
#define HEXDUMP_CONTENT      1
#define HEXDUMP_EPILOGUE     2
#define HEXDUMP_NO_SKIPPING  3

/**
 * Hex-dumps the given buffer to stdout.
 */
void hexdump(uint32_t address, unsigned char *buffer, int byteCount, int fault, int position);

/**
 * Draws a progress bar.
 */
void progressBar(char *prefix, int progress, int max, int isFirstCall, int isByteCount);

#endif
