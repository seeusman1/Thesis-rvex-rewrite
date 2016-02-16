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
 * Executes the "rvd read" command.
 */
int runRead(commandLineArgs_t *args) {
  int size;
  unsigned char pageBuffer[RVSRV_PAGE_SIZE];
  
  if (isHelp(args) || (args->paramCount < 1) || (args->paramCount > 3)) {
    printf(
      "\n"
      "Command usage:\n"
      "  rvd read [size] <address> [count]\n"
      "  rvd r [size] <address> [count]\n"
      "\n"
      "This command will execute a volatile read from the given address, or perform\n"
      "a non-volatile read from the specified address range. Like all commands, it will\n"
      "execute once for every selected context.\n"
      "\n"
      "[size] may be set to one of the following.\n"
      "  \"byte\", \"b\" or \"hh\" - Byte access.\n"
      "  \"half\" or \"h\"       - Halfword access.\n"
      "  \"word\" or \"w\"       - Word access.\n"
      "\n"
      "If [size] is not specified, a word access is assumed. However, it must be\n"
      "specified if [count] is specified as well.\n"
      "\n"
      "[count] may optionally be set to an expression which defines the number of\n"
      "consequitive accesses which are made. When set, the output format will be a\n"
      "hex dump. Also, when more than one word is requested, rvsrv may use faster,\n"
      "non-volatile read commands to perform the requested operation. These may be\n"
      "executed in an arbitrary order and/or more than once if there are transmission\n"
      "errors in the serial port stream, and bus errors will only be detected for the\n"
      "last read.\n"
      "\n"
      "Note: reads from misaligned addresses will NOT generate an error. Instead, rvsrv\n"
      "will ensure that such reads are broken up into the up to two bus accesses\n"
      "necessary to perform the requested operation. This might is usually fine.\n"
      "However, be aware that bus faults are ignored for all bus accesses but the last.\n"
      "\n"
      "This command is synonymous to the read<size>() functions, but is a bit more\n"
      "verbose.\n"
      "\n"
    );
    return 0;
  }
  
  // Evaluate the size, if specified.
  if (args->paramCount > 1) {
    if (!strcmp(args->params[0], "byte")) size = 1; else
    if (!strcmp(args->params[0], "b"))    size = 1; else
    if (!strcmp(args->params[0], "hh"))   size = 1; else
    if (!strcmp(args->params[0], "half")) size = 2; else
    if (!strcmp(args->params[0], "h"))    size = 2; else
    if (!strcmp(args->params[0], "word")) size = 4; else
    if (!strcmp(args->params[0], "w"))    size = 4; else {
      fprintf(stderr,
        "Invalid size specified.\n"
      );
      return -1;
    }
  } else {
    size = 4;
  }
  
  FOR_EACH_CONTEXT(
    
    value_t address;
    value_t dummyValue;
    
    // Execute the _ALWAYS definition.
    if (evaluate("_ALWAYS", &dummyValue, "") < 1) {
      return -1;
    }
    
    // Evaluate the address.
    if (evaluate(args->params[(args->paramCount > 1) ? 1 : 0], &address, "") < 1) {
      return -1;
    }
    
    // Determine if this is a single or bulk read command.
    if (args->paramCount > 2) {
      
      value_t count;
      
      // Bulk read. Evaluate the number of accesses to perform.
      if (evaluate(args->params[2], &count, "") < 1) {
        return -1;
      }
      
      // Don't do anything if count is zero.
      if (count.value == 0) {
        printf("Context %d: requested 0 accesses.\n", ctxt);
      } else {
        
        iterPage_t i;
        int first;
        
        printf("Context %d: dumping 0x%08X..0x%08X...\n\n", ctxt, address.value, address.value + count.value * size - 1);
        
        // Iterate over the rvsrv pages which need to be updated to perform
        // this request. iterPage and iterPageInit will ensure that all pages
        // except for the first and last are aligned.
        i = iterPageInit(address.value, count.value * size, RVSRV_PAGE_SIZE);
        first = 1;
        while (iterPage(&i)) {
          
          uint32_t fault;
          int retval;
          
          // Perform the bulk read operation.
          retval = rvsrv_readBulk(i.address, pageBuffer, i.numBytes, &fault);
          if (retval < 0) {
            return -1;
          } else if (retval == 0) {
            int k;
            for (k = 0; k < RVSRV_PAGE_SIZE / 4; k++) {
              pageBuffer[k*4+0] = fault >> 24;
              pageBuffer[k*4+1] = fault >> 16;
              pageBuffer[k*4+2] = fault >> 8;
              pageBuffer[k*4+3] = fault;
            }
          }
          
          // Dump the data to stdout.
          hexdump(i.address, pageBuffer, i.numBytes, !retval, first ? HEXDUMP_PROLOGUE : HEXDUMP_CONTENT);
          first = 0;
          
        }
        
        // Dump the last line.
        hexdump(0, 0, 0, 0, HEXDUMP_EPILOGUE);
        
        // Print an extra newline at the end of the hex dump.
        printf("\n");
        
      }
      
    } else {
      uint32_t value;
      
      // Perform the access.
      switch (rvsrv_readSingle(address.value, &value, size)) {
        case 0:
          fprintf(stderr,
            "Context %d: failed to read from address 0x%08X; bus fault 0x%08X.\n",
            ctxt,
            address.value,
            value
          );
          break;
          
        case 1:
          printf("Context %d: read 0x%0*X from address 0x%08X.\n",
            ctxt,
            size * 2,
            value,
            address.value
          );
          break;
          
        default:
          return -1;
          
      }
      
    }
    
  );
  
  return 0;
  
}

