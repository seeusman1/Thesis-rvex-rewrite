/* Debug interface for standalone r-VEX processor
 * 
 * Copyright (C) 2008-2015 by TU Delft.
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
 * Copyright (C) 2008-2015 by TU Delft.
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>

#include "main.h"
#include "disasParse.h"
#include "traceParse.h"

#define FORMAT_LIKE_XSTSIM

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
    
    // Dump execution information.
    if (d.usedSlots) {
      
      // If this is not a branch, dump all instructions which were implicitely
      // executed.
      if ((!first) && (!d.hasBranched)) {
        while (pc != d.pc) {
          dumpPC(args->outputFile, pc, 0);
          pc += 4;
        }
      } else {
#ifndef FORMAT_LIKE_XSTSIM
        dprintf(args->outputFile, "\n");
#endif
        pc = d.pc;
      }
      first = 0;
      
#ifndef FORMAT_LIKE_XSTSIM
      
      // Dump trap information.
      if (d.hasTrapped) {
        dprintf(
          args->outputFile,
          "# Trap %d occurred at 0x%08X, arg = 0x%08X (%d)\n\n",
          d.trapCause,
          d.trapPoint,
          d.trapArg,
          d.trapArg
        );
      }
      
#endif
      
      // Dump the explicitely executed instructions.
      for (slot = 0; slot < d.usedSlots; slot++) {
        dumpPC(args->outputFile, pc, &(d.slot[slot]));
        pc += 4;
      }
      
    }
    
#ifndef FORMAT_LIKE_XSTSIM
      
    // Dump reconfiguration information.
    if (d.hasNewConfiguration) {
      dprintf(
        args->outputFile,
        "\n# Reconfiguration: new config word is 0x%08X.\n\n",
        d.config
      );
    }
    
#endif
    
  }
  
}

