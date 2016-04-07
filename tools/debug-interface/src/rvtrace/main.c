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
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>

#include "main.h"
#include "disasParse.h"
#include "traceParse.h"

//#define FORMAT_LIKE_XSTSIM

/**
 * Dumps symbol entries, PC and disassembly in an objdump-ish way.
 */
static void dumpPC(int fd, uint32_t pc, trace_packet_t *extraData) {
  
  const char *disas;
  const char *symbols;
  
  // Get disassembly information.
  disasGet(pc, &disas, &symbols);
  
#ifdef FORMAT_LIKE_XSTSIM
  
  // Print disassembly information.
  dprintf(fd, "PC %08X: %s \n", pc, disas + 13);
  
#else
  
  // Print symbol information.
  if (symbols) {
    dprintf(fd, "%08X %s:\n", pc, symbols);
  }
  
  // Print disassembly information.
  dprintf(fd, "%8X: %s\n", pc, disas);
  
  // Print additional information as comments.
  if (extraData) {
    int b;
    
    if (extraData->hasMem == -1) {
      dprintf(
        fd,
        "                      \t#\tload mem(0x%08X)\n",
        extraData->memAddr
      );
    } else if (extraData->hasMem >= 1) {
      dprintf(
        fd,
        "                      \t#\tmem(0x%08X) = 0x%0*X (%d)\n",
        extraData->memAddr,
        extraData->hasMem*2,
        extraData->memWriteData,
        extraData->memWriteData
      );
    }
    if (extraData->hasWrittenGP) {
      dprintf(
        fd,
        "                      \t#\tr0.%d = 0x%08X (%d)\n",
        extraData->hasWrittenGP,
        extraData->gpWriteData,
        extraData->gpWriteData
      );
    }
    if (extraData->hasWrittenLink) {
      dprintf(
        fd,
        "                      \t#\tl0.0 = 0x%08X (%d)\n",
        extraData->linkWriteData,
        extraData->linkWriteData
      );
    }
    for (b = 0; b < 8; b++) {
      if (extraData->hasWrittenBranch & (1 << b)) {
        if (extraData->branchWriteData & (1 << b)) {
          dprintf(
            fd,
            "                      \t#\tb0.%d = true\n",
            b
          );
        } else {
          dprintf(
            fd,
            "                      \t#\tb0.%d = false\n",
            b
          );
        }
      }
    }
    if (extraData->hasSyllable) {
      dprintf(
        fd,
        "                      \t#\tFetched syllable was 0x%08X\n",
        extraData->syllable
      );
    }
  }
  
#endif
  
}

/**
 * Runs the program.
 */
int run(const commandLineArgs_t *args) {
  
  uint8_t *traceDataPtr = args->traceData;
  int traceDataRemain = args->traceDataSize;
  int first = 1;
  uint32_t pc;
  cycle_data_t d;
  
#ifdef FORMAT_LIKE_XSTSIM
  dprintf(args->outputFile, "Hardware trace\n");
#endif
  
  pc = 0;
  d.pc = 0;
  d.config = args->initialCfg;
  
  while (1) {
    
    int slot;
    
    // Get the next cycle's worth of data.
    switch (getCycleInfo(&traceDataPtr, &traceDataRemain, args->context, &d, args->numLanes, args->numLaneGroups)) {
      case 0:
        return 0;
      case -1:
        fprintf(stderr, "Trace data file offset: %d\n", args->traceDataSize - traceDataRemain);
        return -1;
    }
    
    // Dump extrapolated execution information and branch behavior.
    if (d.usedSlots) {
      
      // If this is not a branch, dump all instructions which were implicitely
      // executed.
      if ((!first) && (!d.hasBranched)) {
        //fprintf(stderr, "pc 0x%08x, d.pc 0x%08x\n", pc, d.pc);
        if (d.pc < pc /*|| d.pc > pc + 0x40*/) {// 0x40 is a 16-syllable bundle size, the largest possible configuration
          fprintf(stderr, "Error: new Program Counter (0x%08x) is unexpected (core has not branched)\n", d.pc);
          continue;
        }
        while (pc != d.pc) {
          dumpPC(args->outputFile, pc, 0);
          pc += 4;
        }
      } else {
#ifndef FORMAT_LIKE_XSTSIM
        dprintf(
          args->outputFile,
          "# Branch ===================================================\n"
        );
#endif
        pc = d.pc;
      }
      first = 0;
      
#ifndef FORMAT_LIKE_XSTSIM
      
      // Dump trap information.
      if (d.hasTrapped) {
        dprintf(
          args->outputFile,
          "# Trap =====================================================\n"
          "# Cause: %d\n"
          "# Point: 0x%08X\n"
          "# Arg = 0x%08X (%d)\n",
          d.trapCause,
          d.trapPoint,
          d.trapArg,
          d.trapArg
        );
      }
      
#endif
    
    }
      
#ifndef FORMAT_LIKE_XSTSIM
    
    // Dump instruction cache information.
    for (slot = 0; slot < 16; slot++) {
      if (d.cacheStatus[slot] & 0x80) {
        dprintf(
          args->outputFile,
          "# fetch for next bundle serviced by icache block %d: %s\n",
          slot / (args->numLanes / args->numLaneGroups),
          (d.cacheStatus[slot] & 0x40) ? "miss" : "hit"
        );
      }
    }
    
#endif
    
    // Dump the explicitely executed instructions.
    if (d.usedSlots) {
      for (slot = 0; slot < d.usedSlots; slot++) {
        dumpPC(args->outputFile, pc, &(d.slot[slot]));
        pc += 4;
      }
    }
    
#ifndef FORMAT_LIKE_XSTSIM
    
    // Dump data cache information.
    for (slot = 0; slot < 16; slot++) {
      if (d.cacheStatus[slot] & 0x30) {
        const char *op = "unknown op";
        const char *wbuf = "";
        const char *result = "unknown";
        switch (d.cacheStatus[slot] & 0x38) {
          case 0x10: op = "read"; break;
          case 0x18: op = "bypass read"; break;
          case 0x20: op = "write (full line)"; break;
          case 0x28: op = "bypass write"; break;
          case 0x30: op = "write (partial line)"; break;
          case 0x38: op = "bypass write"; break;
        }
        switch (d.cacheStatus[slot] & 0x0C) {
          case 0x00: result = "hit"; break;
          case 0x04: result = "miss"; break;
          case 0x08: result = "bypass"; break;
          case 0x0C: result = "bypass"; break;
        }
        if (d.cacheStatus[slot] & 0x02) {
          wbuf = " after buffered write was completed";
        }
        if ((d.cacheStatus[slot] & 0x3C) == 0x10) {
          wbuf = ""; // Read hits can be serviced while a write is buffered.
        }
        dprintf(
          args->outputFile,
          "# %s serviced by dcache block %d%s: %s\n",
          op,
          slot / (args->numLanes / args->numLaneGroups),
          wbuf,
          result
        );
      }
    }
    
    // Dump reconfiguration information.
    if (d.hasNewConfiguration) {
      dprintf(
        args->outputFile,
        "# Reconfiguration ==========================================\n"
        "# New config: 0x%08X\n",
        d.config
      );
    }
    
#endif
    
  }
  
}

