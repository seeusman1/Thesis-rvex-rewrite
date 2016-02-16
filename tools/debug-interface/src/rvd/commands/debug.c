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
#include <string.h>

#include "commands.h"
#include "entry.h"
#include "types.h"
#include "main.h"
#include "definitions.h"
#include "parser.h"

/**
 * Executes the debug commands (break, step, continue, etc.).
 */
int runDebug(commandLineArgs_t *args) {
  const char *expr;
  
  if (isHelp(args) || (args->paramCount != 0)) {
    printf(
      "\n"
      "Command usage:\n"
      "  rvd break      rvd b        rvd execute \"_BREAK\"\n"
      "  rvd step       rvd s        rvd execute \"_STEP\"\n"
      "  rvd resume                  rvd execute \"_RESUME\"\n"
      "  rvd continue   rvd c        rvd execute \"_RESUME\"\n"
      "  rvd release                 rvd execute \"_RELEASE\"\n"
      "  rvd reset      rvd rst      rvd execute \"_RESET\"\n"
      "  rvd state      rvd ?        rvd execute \"_STATE\"\n"
      "\n"
      "The commands listed above can be used for debugging. They're just shorthand\n"
      "notations for calling certain execute commands, as shown in the list above: all\n"
      "the commands in each line are synonyms. To make use of these debugging commands,\n"
      "the definitions used must be defined in a loaded memory map file.\n"
      "\n"
    );
    return 0;
  }
  
  // Decode the expression to execute.
  if (
    (!strcmp(args->command, "break")) ||
    (!strcmp(args->command, "b"))
  ) {
    expr = "_BREAK";
  } else if (
    (!strcmp(args->command, "step")) ||
    (!strcmp(args->command, "s"))
  ) {
    expr = "_STEP";
  } else if (
    (!strcmp(args->command, "resume")) ||
    (!strcmp(args->command, "continue")) ||
    (!strcmp(args->command, "c"))
  ) {
    expr = "_RESUME";
  } else if (
    (!strcmp(args->command, "release"))
  ) {
    expr = "_RELEASE";
  } else if (
    (!strcmp(args->command, "reset")) ||
    (!strcmp(args->command, "rst"))
  ) {
    expr = "_RESET";
  } else if (
    (!strcmp(args->command, "state")) ||
    (!strcmp(args->command, "?"))
  ) {
    expr = "_STATE";
  } else {
    fprintf(stderr, "An unknown error occured.\n");
    return -1;
  }
  
  // Execute the expression.
  FOR_EACH_CONTEXT(
    value_t dummyValue;
    
    if (evaluate("_ALWAYS", &dummyValue, "") < 1) {
      return -1;
    }
    
    if (evaluate(expr, &dummyValue, "") < 1) {
      return -1;
    }
    
  );
  
  return 0;
  
}

