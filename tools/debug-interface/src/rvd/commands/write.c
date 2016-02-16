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
 * Executes the "rvd write" command.
 */
int runWrite(commandLineArgs_t *args) {
  
  if (isHelp(args) || (args->paramCount != 2)) {
    printf(
      "\n"
      "Command usage:\n"
      "  rvd write <address> <value>\n"
      "  rvd w <address> <value>\n"
      "\n"
      "This command will execute a volatile write to the given address, setting the\n"
      "memory to the given value. Both <address> and <value> may be expressions. The\n"
      "write will be performed for all currently selected contexts (see also\n"
      "\"rvd help select\"). The access size for the write depends on the type\n"
      "information carried by <value>.\n"
      "\n"
      "Examples:\n"
      "  rvd write 0x1234 5   - Writes 0x00000005 to 0x00001234.\n"
      "  rvd write 42 3h      - Writes 0x0003 to 0x0000002A.\n"
      "  rvd write 0x3 3hh    - Writes 0x03 to 0x00000003.\n"
      "\n"
      "Note: writing to misaligned addresses will NOT generate an error. Instead, rvsrv\n"
      "will ensure that such writes are broken up into the up to three bus accesses\n"
      "necessary to perform the requested operation. This might be fine depending on\n"
      "the situation, as the resulting memory will typically hold the intended contents\n"
      "afterwards. However, bus faults are ignored for all bus accesses but the last.\n"
      "\n"
      "This command is synonymous to the write() function, but is a bit more verbose.\n"
      "\n"
    );
    return 0;
  }
  
  FOR_EACH_CONTEXT(
    
    value_t address;
    value_t value;
    int size;
    uint32_t fault;
    value_t dummyValue;
    
    // Execute the _ALWAYS definition.
    if (evaluate("_ALWAYS", &dummyValue, "") < 1) {
      return -1;
    }
    
    // Evaluate the address.
    if (evaluate(args->params[0], &address, "") < 1) {
      return -1;
    }
    
    // Evaluate the data to write.
    if (evaluate(args->params[1], &value, "") < 1) {
      return -1;
    }
    
    // Determine the access size.
    switch (value.size) {
      case AS_BYTE: size = 1; value.value &= 0xFF;   break;
      case AS_HALF: size = 2; value.value &= 0xFFFF; break;
      default:      size = 4;                        break;
    }
    
    // Perform the access.
    switch (rvsrv_writeSingle(address.value, value.value, size, &fault)) {
      case 0:
        fprintf(stderr,
          "Context %d: failed to write 0x%0*X to address 0x%08X; bus fault 0x%08X.\n",
          ctxt,
          size * 2,
          value.value,
          address.value,
          fault
        );
        break;
        
      case 1:
        fprintf(stderr,
          "Context %d: wrote 0x%0*X to address 0x%08X.\n",
          ctxt,
          size * 2,
          value.value,
          address.value
        );
        break;
        
      default:
        return -1;
        
    }
    
  );
  
  return 0;
  
}

