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

#include "rsp-breakpoints.h"
#include "../types.h"
#include "../definitions.h"
#include "../parser.h"
#include "../rvsrvInterface.h"

/**
 * Breakpoint registry type.
 */
typedef struct {
  
  // 1 if the breakpoint is in use, 0 otherwise.
  short active;
  
  // Breakpoint type, same encoding as in gdb_breakpoint().
  short type;
  
  // Addres for the breakpoint.
  uint32_t addr;
  
  // For software breakpoints, this contains the replaced syllable. For
  // hardware breakpoints, this is the breakpoint index.
  uint32_t data;
  
} breakpointReg_t;

/**
 * Maximum number of registered breakpoints.
 */
#define MAX_BREAKPOINTS 1024

/**
 * Breakpoint registry.
 */
static breakpointReg_t breakpointReg[MAX_BREAKPOINTS];
static uint32_t hwBreakpointsInUse = 0;

/**
 * Sets or removes a breakpoint/watchpoint. type must have one of the following
 * values:
 *   0 - set/remove software breakpoint
 *   1 - set/remove hardware breakpoint
 *   2 - set/remove hardware write watchpoint
 *   3 - set/remove hardware read watchpoint
 *   4 - set/remove hardware access watchpoint
 * address is set to the address which the breakpoint should match on. set will
 * be 1 if the breakpoint is to be inserted, or 0 if it is to be removed. Will
 * return -1 and print an error to stderr if an error occurs, 0 if the memory
 * map file reports that the breakpoint is not supported, or 1 if successful.
 */
int gdb_breakpoint(int type, uint32_t addr, int set) {
  int i;
  breakpointReg_t *brkReg;
  uint32_t fault;
  value_t wrAddr, rdAddr, syll, result;
  char strBuf[16];
  
  // Look for an empty breakpoint slot (when setting) or a matching breakpoint
  // (when removing).
  i = 0;
  brkReg = breakpointReg;
  while (i < MAX_BREAKPOINTS) {
    
    // See if this slot matches.
    if (set) {
      if (!(brkReg->active)) {
        int hwSlot = -1;
        
        // If this is a hardware breakpoint, find a free hardware breakpoint
        // slot.
        if (type > 0) {
          int j;
          for (j = 0; j < 32; j++) {
            if (!(hwBreakpointsInUse & (1 << j))) {
              hwSlot = j;
              break;
            }
          }
          if (hwSlot == -1) {
            return 0;
          }
        }
        
        // Update the breakpoint registry.
        brkReg->active = 1;
        brkReg->type = type;
        brkReg->addr = addr;
        if (type > 0) {
          brkReg->data = hwSlot;
          hwBreakpointsInUse |= 1 << hwSlot;
        }
        
        // Register breakpoint in the hardware.
        if (type == 0) {
          
          // Perform read address translation.
          sprintf(strBuf, "0x%08X", addr);
          if (defs_register(0xFFFFFFFF, "_GDB_ADDR", strBuf) < 0) return -1;
          if (evaluate("_GDB_ADDR_R", &rdAddr, "") < 1) return -1;
          
          // Read the original syllable from memory.
          switch (rvsrv_readSingle(rdAddr.value & ~3, &(brkReg->data), 4)) {
            case -1:
              return -1;
            case 0:
              fprintf(stderr, "rvd error: read from 0x%08X failed due to bus error\n", rdAddr.value);
              return 0;
          }
          
          // Perform write address translation and determine what the
          // breakpoint syllable should be.
          sprintf(strBuf, "0x%08X", addr);
          if (defs_register(0xFFFFFFFF, "_GDB_ADDR", strBuf) < 0) return -1;
          if (evaluate("_GDB_ADDR_W", &wrAddr, "") < 1) return -1;
          if (defs_register(0xFFFFFFFF, "_GDB_SOFTBRK_ADDR", strBuf) < 0) return -1;
          sprintf(strBuf, "0x%08X", brkReg->data);
          if (defs_register(0xFFFFFFFF, "_GDB_SOFTBRK_SYL", strBuf) < 0) return -1;
          if (evaluate("_GDB_SOFTBRK", &syll, "") < 1) return -1;
          
          // Write the breakpoint syllable to memory.
          switch (rvsrv_writeSingle(wrAddr.value & ~3, syll.value, 4, &fault)) {
            case -1:
              return -1;
            case 0:
              fprintf(stderr, "rvd error: write to 0x%08X failed due to bus error\n", wrAddr.value);
              return 0;
          }
          
        } else {
          
          // Set the hardware breakpoint.
          sprintf(strBuf, "0x%08X", type);
          if (defs_register(0xFFFFFFFF, "_GDB_HARDBRK_TYPE", strBuf) < 0) return -1;
          sprintf(strBuf, "0x%08X", brkReg->data);
          if (defs_register(0xFFFFFFFF, "_GDB_HARDBRK_INDEX", strBuf) < 0) return -1;
          sprintf(strBuf, "0x%08X", addr);
          if (defs_register(0xFFFFFFFF, "_GDB_HARDBRK_ADDR", strBuf) < 0) return -1;
          if (evaluate("_GDB_HARDBRK", &result, "") < 1) return -1;
          if (result.value) {
            return 1;
          } else {
            return 0;
          }
          
        }
        
        return 1;
        
      }
    } else {
      if ((brkReg->active) && (brkReg->type == type) && (brkReg->addr == addr)) {
        
        // Unregister breakpoint in the hardware.
        if (type == 0) {
          
          // Perform write address translation.
          sprintf(strBuf, "0x%08X", addr);
          if (defs_register(0xFFFFFFFF, "_GDB_ADDR", strBuf) < 0) return -1;
          if (evaluate("_GDB_ADDR_W", &wrAddr, "") < 1) return -1;
          
          // Write the original syllable to memory.
          switch (rvsrv_writeSingle(wrAddr.value & ~3, brkReg->data, 4, &fault)) {
            case -1:
              return -1;
            case 0:
              return 0;
          }
          
        } else {
          
          // Remove the hardware breakpoint.
          if (defs_register(0xFFFFFFFF, "_GDB_HARDBRK_TYPE", "0") < 0) return -1;
          sprintf(strBuf, "0x%08X", brkReg->data);
          if (defs_register(0xFFFFFFFF, "_GDB_HARDBRK_INDEX", strBuf) < 0) return -1;
          sprintf(strBuf, "0x%08X", addr);
          if (defs_register(0xFFFFFFFF, "_GDB_HARDBRK_ADDR", strBuf) < 0) return -1;
          if (evaluate("_GDB_HARDBRK", &result, "") < 1) return -1;
          if (result.value) {
            return 1;
          } else {
            return 0;
          }
          
        }
        
        // Update the breakpoint registry.
        brkReg->active = 0;
        if (type > 0) {
          hwBreakpointsInUse &= ~(1 << brkReg->data);
        }
        
        return 1;
        
      }
    }
    
    // Go to the next slot.
    i++;
    brkReg++;
  }
  
  fprintf(stderr, "rvd error: slot not found\n");
  return 0;
}
