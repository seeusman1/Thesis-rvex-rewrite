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

#ifndef _TRACE_PARSE_H_
#define _TRACE_PARSE_H_

#include <stdint.h>

/**
 * Decoded trace packet data.
 */
typedef struct {
  
  /**
   * Pipelane index.
   */
  int lane;
  
  /**
   * Program counter information. hasPC masks the validity of pc in a bitwise
   * manner.
   */
  uint32_t hasPC;
  uint32_t pc;
  int hasBranched;
  
  /**
   * Memory trace information. hasMem is set to 0 if there was no memory trace
   * information, 1, 2 or 4 if a write was performed or -1 if a read was
   * performed.
   */
  int hasMem;
  uint32_t memAddr;
  uint32_t memWriteData;
  
  /**
   * General purpose register trace information. hasWrittenGP is set to 0 if
   * no write occured or the register index if a write did occur.
   */
  int hasWrittenGP;
  uint32_t gpWriteData;
  
  /**
   * Link register trace information.
   */
  int hasWrittenLink;
  uint32_t linkWriteData;
  
  /**
   * Branch register trace information. Each bit in hasWrittenBranch and
   * branchWriteData corresponds to one of the 8 branch registers.
   */
  uint8_t hasWrittenBranch;
  uint8_t branchWriteData;
  
  /**
   * Trap trace information.
   */
  int hasTrapped;
  uint32_t trapPoint;
  uint8_t trapCause;
  uint32_t trapArg;
  
  /**
   * Reconfiguration information.
   */
  int hasNewConfiguration;
  uint8_t newConfiguration;
  
  /**
   * Cache trace information.
   */
  uint8_t cacheStatus;
  
  /**
   * Syllable trace information.
   */
  uint8_t hasSyllable;
  uint32_t syllable;
  
} trace_packet_t;

/**
 * Decoded trace information for one context.
 */
typedef struct {
  
  /**
   * Current program counter.
   */
  uint32_t pc;
  
  /**
   * Whether the current program counter is sequential or nonsequential.
   */
  int hasBranched;
  
  /**
   * Trap trace information.
   */
  int hasTrapped;
  uint32_t trapPoint;
  uint8_t trapCause;
  uint32_t trapArg;
  
  /**
   * Reconfiguration information.
   */
  int hasNewConfiguration;
  uint32_t config;
  
  /**
   * Status information from each cache block.
   */
  uint8_t cacheStatus[16];
  
  /**
   * Number of issue slots used.
   */
  int usedSlots;
  
  /**
   * Extended information for each issue slot. Slot 0 through usedSlots-1 are
   * valid. PC, trap and reconfiguration information is present as parsed from
   * the trace packets, but should be ignored in favor of the information in
   * this structure.
   */
  trace_packet_t slot[16];
  
} cycle_data_t;

/**
 * Decodes a cycle's worth of trace data for the given context. data->pc
 * should be 0 and data->config should be set to the initial configuration in
 * the first call to this method. Subsequent calls must be done using the same
 * data buffer, and the contents of the buffer should not be modified
 * externally. Returns 1 if successful, 0 if no more trace data is avalaible or
 * -1 if an error occured, in which case the error is printed to stderr.
 */
int getCycleInfo(
  uint8_t **rawDataPtr,
  int *rawDataRemain,
  int contextToTrace,
  cycle_data_t *data,
  int numLanes,
  int numGroups
);

#endif
