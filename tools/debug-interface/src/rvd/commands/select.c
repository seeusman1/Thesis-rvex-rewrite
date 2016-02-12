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
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>

#include "main.h"
#include "parser.h"
#include "types.h"
#include "utils.h"
#include "srec.h"
#include "rvsrvInterface.h"
#include "commands.h"

/**
 * Executes the "rvd select" command.
 */
int runSelect(commandLineArgs_t *args) {
  
  int f;
  contextMask_t dummyMask;
  const char *ptr;
  int remain;
  
  if (isHelp(args) || (args->paramCount != 1)) {
    printf(
      "\n"
      "Command usage:\n"
      "  rvd select <contexts>\n"
      "\n"
      "This command will set which rvex contexts will be addressed by future commands,\n"
      "which do not have a context explicitely specified through either the specific\n"
      "command, or the -c or --context command line parameters.\n"
      "\n"
      "<contexts> may be specified in any of the following ways (like any other context\n"
      "mask in rvd).\n"
      "\n"
      "  <int>         A single context is selected.\n"
      "  <int>..<int>  The specified context range is selected. The range specification\n"
      "                is inclusive; e.g. 0..3 specifies 4 contexts.\n"
      "  all           Context 0 up to _NUM_CONTEXTS are selected.\n"
      "\n"
      "The intended use for the contexts is to allow you to easily access multiple rvex\n"
      "processors/contexts, without needing to swap out the memory map file or having\n"
      "different definition names for each context. Technically you could define a\n"
      "completely different memory map for a different context though.\n"
      "\n"
      "When more than one context is selected, most rvd commands will simply execute\n"
      "sequentially for each context in the range. You can use this behavior to, for\n"
      "example, soft reset all contexts or stop execution of all contexts at roughly\n"
      "the same time.\n"
      "\n"
    );
    return 0;
  }
  
  // Syntax-check the context selection.
  if (parseMask(args->params[0], &dummyMask, "") < 1) {
    return -1;
  }
  
  // Write to the .rvd-context file.
  unlink(".rvd-context");
  f = open(".rvd-context", O_WRONLY | O_CREAT, 00644);
  if (f < 0) {
    perror("Could not open .rvd-context for writing");
    return -1;
  }
  ptr = args->params[0];
  remain = strlen(ptr);
  while (remain) {
    int count = write(f, ptr, remain);
    if (count < 1) {
      perror("Could not write to .rvd-context");
      close(f);
      return -1;
    }
    ptr += count;
    remain -= count;
  }
  close(f);
  
  // Give some feedback on success.
  printf("Updated context selection.\n");
  
  return 0;
  
}

