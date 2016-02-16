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
#include <string.h>

#include "main.h"
#include "types.h"
#include "commands.h"
#include "parser.h"
#include "definitions.h"
#include "../gdb/gdb-main.h"

/**
 * Executes the "rvd gdb" or "rvd gdb-debug" command.
 */
int runGdb(commandLineArgs_t *args) {
  int selectedContext = -1;
  value_t v;
  
  if (isHelp(args) || (args->paramCount < 1)) {
    printf(
      "\n"
      "Command usage:\n"
      "  rvd gdb -- <gdb> [params [...]]\n"
      "\n"
      "This command will, in essence, run gdb to debug the target. It will do so by\n"
      "starting a TCP server on a free port listening to RSP debug commands, and then\n"
      "running gdb as a child process, using the command line after the -- separator.\n"
      "\n"
      "Only one context can be debugged at a time using a single instance of gdb (i.e.\n"
      "asynchronous/multiprocess debugging with gdb is not supported at this time). In\n"
      "theory, if multiple contexts need to be debugged at the same time, you can just\n"
      "call \"rvd gdb\" in different terminals at the same time for different contexts.\n"
      "\n"
      "The following definitions must be set from the command line or a memory map file\n"
      "for this command to function:\n"
      "\n"
      "  _BREAK       - Stop execution.\n"
      "  _RESUME      - Resume execution.\n"
      "  _RESET       - Reset processor in stopped state.\n"
      "  _STEP        - Resume execution in single-stepping mode.\n"
      "  _WAIT        - Should wait for the target to be halted. The value returned must\n"
      "                 identify the reason for halting:\n"
      "                   0x0xx - program termination with exit code xx\n"
      "                   0x1xx - watchpoint xx\n"
      "                   0x200 - (software) breakpoint\n"
      "                   0x201 - single step trap\n"
      "                   0x202 - no trap (_BREAK set manually)\n"
      "  _RELEASE     - Relinquish debugging control over the target.\n"
      "  _GDB_ADDR_R  - Should transform an address as seen from the core to a debug bus\n"
      "                 address for reading. The address to transform is _GDB_ADDR.\n"
      "  _GDB_ADDR_W  - Same as _GDB_ADDR_W, but for writing memory.\n"
      "  _GDB_REG_R   - Should return the size and current value of register\n"
      "                 _GDB_REG_INDEX, which is defined internally prior to executing\n"
      "                 _GDB_REG_R. The register index specified must correspond with the\n"
      "                 indices used by gdb.\n"
      "  _GDB_REG_W   - Same as _GDB_REG_R, but should write instead. _GDB_REG_VALUE is\n"
      "                 set to the value which is to be written prior to executing\n"
      "                 _GDB_REG_W along with the register index (_GDB_REG_INDEX).\n"
      "  _GDB_REG_JMP - Set the program counter to _GDB_REG_VALUE.\n"
      "  _GDB_REG_NUM - Should return the number of registers known to gdb.\n"
      "  _GDB_REG_PRE - This is executed before all the registers gdb is aware of are\n"
      "                 read in bulk. This should be a preload command for performance.\n"
      "  _GDB_SOFTBRK - This should return a valid debug trap syllable for the core.\n"
      "                 When setting a breakpoint, the syllable at the breakpoint address\n"
      "                 will be overwritten with this. The original syllable and the\n"
      "                 address can be accessed using _GDB_SOFTBRK_SYL and\n"
      "                 _GDB_SOFTBRK_ADDR respectively, should the soft breakpoint\n"
      "                 syllable depend on these values.\n"
      "  _GDB_HARDBRK - This should set or remove a hardware break/watchpoint, depending\n"
      "                 on _GDB_HARDBRK_TYPE and _GDB_HARDBRK_INDEX. _GDB_HARDBRK_TYPE\n"
      "                 will have one of the following values:\n"
      "                   0 - clear this watchpoint.\n"
      "                   1 - set breakpoint.\n"
      "                   2 - set write watchpoint.\n"
      "                   3 - set read watchpoint.\n"
      "                   4 - set access watchpoint.\n"
      "                 The address for the watchpoint is loaded into _GDB_HARDBRK_ADDR.\n"
      "                 If successful, 1 should be returned. If the hardware cannot\n"
      "                 handle the request, 0 should be returned.\n"
      "\n"
      "_STATE is overwritten to null to prevent status information dumps.\n"
      "\n"
    );
    return 0;
  }
  
  // Crash if multiple contexts are selected. This has the side effect of
  // properly defining _CUR_CONTEXT in case only one context is selected (as is
  // required), so we don't have to worry about contexts after this.
  FOR_EACH_CONTEXT(
    if (selectedContext != -1) {
      fprintf(stderr,
        "You have multiple contexts selected. This is not currently supported for gdb\n"
        "debugging. Please use \"rvd select\" or the -c or --context command line\n"
        "parameter to select a single context and try again.\n"
      );
      return -1;
    }
    selectedContext = ctxt;
  );
  
  // Overwrite _STATE to null to prevent unwanted status information dumps.
  if (defs_register(0xFFFFFFFF, "_STATE", "0") < 0) {
    return -1;
  }
  
  // Evaluate the _BREAK command to stop execution.
  if (evaluate("_BREAK", &v, "") < 1) {
    return -1;
  }
  
  // Defer the complicated stuff to the C sources in ../gdb/.
  return gdb_main(args->params, args->paramCount, !strcmp(args->command, "gdb-debug"));
  
}

