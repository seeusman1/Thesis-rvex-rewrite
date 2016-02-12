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
#include "definitions.h"

/**
 * Executes "rvd evaluate" and "rvd execute" commands.
 */
int runEvaluate(commandLineArgs_t *args) {
  
  if (isHelp(args) || (args->paramCount != 1)) {
    printf(
      "\n"
      "Command usage:\n"
      "  rvd evaluate <expression>\n"
      "  rvd eval <expression>\n"
      "  rvd execute <expression>\n"
      "  rvd exec <expression>\n"
      "\n"
      "This command will evaluate the given expression for the context(s) selected\n"
      "using \"rvd context\" or the -c or --context command line parameters. The\n"
      "difference between evaluate and execute is that evaluate prints the resulting\n"
      "value to stdout, whereas execute runs silently and relies solely on printf()\n"
      "calls in the evaluated expression for output.\n"
      "\n"
      "Call \"rvd help expressions\" for more information on how expressions work.\n"
      "\n"
    );
    return 0;
  }
  
  FOR_EACH_CONTEXT(
    
    value_t value;
    value_t dummyValue;
    
    // Execute the _ALWAYS definition.
    if (evaluate("_ALWAYS", &dummyValue, "") < 1) {
      return -1;
    }
    
    // Evaluate the given command.
    if (evaluate(args->params[0], &value, "") < 1) {
      return -1;
    }
    
    // Display the result for the evaluate command only.
    if (
      (!strcmp(args->command, "eval")) ||
      (!strcmp(args->command, "evaluate"))
    ) {
      printf("Context %d: ", ctxt);
      switch (value.size) {
        case AS_BYTE:
          printf("0x%02X = %u\n", value.value & 0xFF, value.value & 0xFF);
          break;
          
        case AS_HALF:
          printf("0x%04X = %u\n", value.value & 0xFFFF, value.value & 0xFFFF);
          break;
          
        default:
          printf("0x%08X = %u\n", value.value, value.value);
          break;
          
      }
      
    }
    
  );
  
  return 0;
  
}

