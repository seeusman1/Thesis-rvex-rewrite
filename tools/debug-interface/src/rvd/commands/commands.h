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

#ifndef _COMMANDS_H_
#define _COMMANDS_H_

#include "types.h"
#include "entry.h"

/**
 * This macro runs the code specified by contents for each selected context.
 * Magic. Should be used only in functions which return -1 when an error
 * occurs.
 */
#define FOR_EACH_CONTEXT(contents) \
{ \
  value_t value; \
  int ctxt, numContexts; \
  int didAnything = 0; \
  \
  defs_setContext(0); \
  if (evaluate("_NUM_CONTEXTS", &value, "") < 1) { \
    fprintf(stderr, \
      "Error: failed to expand or evaluate _NUM_CONTEXTS. Please define this value\n" \
      "on the command line or by using \"-dall:_NUM_CONTEXTS:<count>\", or specify the\n" \
      "value in a memory map file.\n" \
    ); \
    return -1; \
  } \
  numContexts = value.value; \
  if ((numContexts < 1) || (numContexts > 32)) { \
    fprintf(stderr, \
      "Error: _NUM_CONTEXTS evaluates to %d, which is out of range. rvd supports up\n" \
      "to 32 contexts.\n", \
      numContexts \
    ); \
    return -1; \
  } \
  \
  for (ctxt = 0; ctxt < numContexts; ctxt++) { \
    \
    if (args->contextMask & (1 << ctxt)) { \
      \
      defs_setContext(ctxt); \
      \
      { \
        contents \
      } \
      \
      didAnything = 1; \
      \
    } \
    \
  } \
  \
  if (!didAnything) { \
    fprintf(stderr, \
      "Error: none of the contexts which you have selected are within 0.._NUM_CONTEXTS.\n" \
      "Use \"rvd select\" or the command line to select a different range of contexts.\n" \
    ); \
    return -1; \
  } \
}

/**
 * Executes the "rvd select" command.
 */
int runSelect(commandLineArgs_t *args);

/**
 * Executes "rvd evaluate" and "rvd execute" commands.
 */
int runEvaluate(commandLineArgs_t *args);

/**
 * Executes the "rvd stop" command.
 */
int runStop(commandLineArgs_t *args);

/**
 * Executes the "rvd write" command.
 */
int runWrite(commandLineArgs_t *args);

/**
 * Executes the "rvd read" command.
 */
int runRead(commandLineArgs_t *args);

/**
 * Executes the "rvd fill" command.
 */
int runFill(commandLineArgs_t *args);

/**
 * Executes the "rvd upload" command.
 */
int runUpload(commandLineArgs_t *args);

/**
 * Executes the "rvd download" command.
 */
int runDownload(commandLineArgs_t *args);

/**
 * Executes the "rvd trace" command.
 */
int runTrace(commandLineArgs_t *args);

/**
 * Executes the debug commands (break, step, continue, etc.).
 */
int runDebug(commandLineArgs_t *args);

/**
 * Executes the "rvd gdb" command.
 */
int runGdb(commandLineArgs_t *args);

#endif
