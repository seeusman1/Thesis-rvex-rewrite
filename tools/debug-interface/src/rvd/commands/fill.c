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
 * Executes the "rvd fill" command.
 */
int runFill(commandLineArgs_t *args) {
  unsigned char pageBuffer[RVSRV_PAGE_SIZE];
  
  if (isHelp(args) || (args->paramCount < 2) || (args->paramCount > 3)) {
    printf(
      "\n"
      "Command usage:\n"
      "  rvd fill <startAddress> <byteCount> [value]\n"
      "\n"
      "This command will execute non-volatile writes to the given address range to set\n"
      "all bytes in the range to the specified value. The writes are performed in an\n"
      "arbitrary order and may be performed more than once, if there are transmission\n"
      "errors in the serial stream. Like all commands, it will execute once for every\n"
      "selected context. If value is not specified, 0 is assumed.\n"
      "\n"
    );
    return 0;
  }
  
  FOR_EACH_CONTEXT(
    
    value_t address;
    value_t count;
    value_t value;
    value_t dummyValue;
    
    // Execute the _ALWAYS definition.
    if (evaluate("_ALWAYS", &dummyValue, "") < 1) {
      return -1;
    }
    
    // Evaluate the address.
    if (evaluate(args->params[0], &address, "") < 1) {
      return -1;
    }
    
    // Evaluate the number of bytes to write.
    if (evaluate(args->params[1], &count, "") < 1) {
      return -1;
    }
    
    // Evaluate the value to write.
    if (args->paramCount > 2) {
      if (evaluate(args->params[2], &value, "") < 1) {
        return -1;
      }
    } else {
      value.value = 0;
    }
    
    // Fill the buffer with the given value.
    memset(pageBuffer, value.value, RVSRV_PAGE_SIZE);
    
    // Don't do anything if count is zero.
    if (count.value == 0) {
      printf("Context %d: requested 0 bytes to be written.\n", ctxt);
    } else {
      
      iterPage_t i;
      char prefix[16];
      
      printf(
        "Context %d: writing %02hhX to 0x%08X..0x%08X...\n",
        ctxt,
        pageBuffer[0],
        address.value,
        address.value + count.value - 1
      );
      
      // Start printing the progress bar.
      sprintf(prefix, "0x%08X ", address.value);
      progressBar(prefix, 0, count.value, 1, 1);
      
      // Iterate over the rvsrv pages which need to be updated to perform
      // this request. iterPage and iterPageInit will ensure that all pages
      // except for the first and last are aligned.
      i = iterPageInit(address.value, count.value, RVSRV_PAGE_SIZE);
      while (iterPage(&i)) {
        
        uint32_t fault;
        int retval;
        
        // Perform the bulk write operation.
        retval = rvsrv_writeBulk(i.address, pageBuffer, i.numBytes, &fault);
        if (retval < 0) {
          return -1;
        } else if (retval == 0) {
          
          // Override the previous line in the terminal, which is the
          // progress bar.
          printf(
            "\r\033[AWarning: bus fault 0x%08X occured while writing page 0x%08X..0x%08X.\033[K\n\n",
            fault,
            i.address,
            i.address + i.numBytes - 1
          );
        }
        
        // Update the progress bar.
        sprintf(prefix, "0x%08X ", i.address + i.numBytes - 1);
        progressBar(prefix, (count.value - i.remain) + i.numBytes, count.value, 0, 1);
        
      }
      
      // Print a newline to separate the contexts.
      printf("\n");
      
    }
    
  );
  
  return 0;
  
}

