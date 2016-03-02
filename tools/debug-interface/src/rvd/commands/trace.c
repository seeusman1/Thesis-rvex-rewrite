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

static int flushTraceBuf(uint32_t address) {
  uint32_t numBytes;
  int done = 0;
  while (!done) {
    done = 1;
    switch (rvsrv_readSingle(address, &numBytes, 4)) {
      case 1:
        if (numBytes != 4) {
          done = 0;
        }
        break;
      case 0:
        fprintf(stderr,
          "Error: failed to read from address 0x%08X; bus fault 0x%08X.\n",
          address, numBytes
        );
      default:
        return -1;
    }
    switch (rvsrv_readSingle(address + RVSRV_PAGE_SIZE, &numBytes, 4)) {
      case 1:
        if (numBytes != 4) {
          done = 0;
        }
        break;
      case 0:
        fprintf(stderr,
          "Error: failed to read from address 0x%08X; bus fault 0x%08X.\n",
          address, numBytes
        );
      default:
        return -1;
    }
  }
  return 0;
}

/**
 * Executes the "rvd trace" command.
 */
int runTrace(commandLineArgs_t *args) {
  unsigned char pageBuffer[RVSRV_PAGE_SIZE];
  value_t address = {0, 0};
  uint32_t trace_size;
  int f;
  int first;
  uint32_t traceByteCount;
  int page;
  
  if (isHelp(args) || (args->paramCount < 1) || (args->paramCount > 3)) {
    printf(
      "\n"
      "Command usage:\n"
      "  rvd trace <filename> [level] [condition]\n"
      "\n"
      "WARNING: if the specified file already exists, it will be overwritten.\n"
      "\n"
      "This command uses the hardware trace peripheral (periph_trace.vhd) to trace\n"
      "program execution. The following definitions must be set from the command line\n"
      "or a memory map file for this command to function:\n"
      "\n"
      "  _BREAK      - Should halt the current context when executed (rvd break).\n"
      "  _RESUME     - Should resume execution for the given context when executed\n"
      "              - (rvd continue)\n"
      "  _TRACE_ADDR - Should evaluate to the start address of the trace peripheral.\n"
      "  _TRACE_SIZE - Optional. If defined, it should evaluate to the size of the\n"
      "                trace buffer. The maximum size is %d, which is also the\n"
      "                default value.\n"
      "  _TRACE_CTRL - Should evaluate to the byte address of the trace control\n"
      "                register for the current context.\n"
      "\n"
      "NOTE: the trace peripheral must be configured to use a %d byte buffer, i.e.\n"
      "DEPTH_LOG2B = %d, and _TRACE_ADDR must be aligned to this size, if the debug\n"
      "UART is used for communication.\n"
      "\n"
      "To perform a trace, the following actions are performed:\n"
      "\n"
      " - _BREAK is executed for all selected contexts.\n"
      " - [level] is evaluated and written to _TRACE_CTRL for each selected context.\n"
      "   If level is not specified, 1 is assumed.\n"
      " - The trace buffer is flushed.\n"
      " - _RESUME is executed for all selected contexts.\n"
      " - The trace buffers are read continuously in a loop; the received data is\n"
      "   written to <filename>. If [condition] is specified, it is used as the loop\n"
      "   condition (tracing terminates when it evaluates to 0). Otherwise, tracing\n"
      "   terminates when no more data is available (i.e., the program has finished\n"
      "   executing).\n"
      " - 0 is written to _TRACE_CTRL for each selected context to disable tracing.\n"
      " - The trace buffer is flushed.\n"
      "\n"
      "The trace dump is a binary file, of which the format is specified in\n"
      "core_trace.vhd. Additional processing is required to get a human-readable\n"
      "trace.\n"
      "\n", RVSRV_PAGE_SIZE*2, RVSRV_PAGE_SIZE*2, RVSRV_PAGE_SIZE_LOG2+1
    );
    return 0;
  }
  
  // Halt each selected context and evaluate the trace buffer address. Do the
  // latter for each context and make sure the result is the same for all
  // (which might not be the case in multiprocessor systems).
  printf("Halting execution...\n");
  first = 1;
  FOR_EACH_CONTEXT(
    value_t value;
    if (evaluate("_ALWAYS",     &value, "") < 1) {
      return -1;
    }
    if (evaluate("_BREAK",      &value, "") < 1) {
      return -1;
    }
    
    if (evaluate("_TRACE_ADDR", &value, "") < 1) {
      return -1;
    }
    if ((address.value != value.value) && !first) {
      fprintf(stderr,
        "Error: _TRACE_ADDR does not evaluate to the same address for every selected\n"
        "context.\n"
      );
      return -1;
    }
    address.value = value.value;
    
    if (evaluate("_TRACE_SIZE", &value, "") < 1) {
      value.value = RVSRV_PAGE_SIZE*2;
    }
    if ((trace_size != value.value) && !first) {
      fprintf(stderr,
        "Error: _TRACE_SIZE does not evaluate to the same address for every selected\n"
        "context.\n"
      );
      return -1;
    }
    trace_size = value.value;
    first = 0;
  );
  
  // Compute and check the size of a single trace buffer.
  if ((trace_size >> 1) > RVSRV_PAGE_SIZE) {
    fprintf(stderr,
      "Error: _TRACE_SIZE is too large. Maximum = %d, actual = %d.\n",
      RVSRV_PAGE_SIZE*2, trace_size
    );
    return -1;
  }
  trace_size >>= 1;
  
  // Write to the trace control registers.
  printf("Setting up trace control flags...\n");
  FOR_EACH_CONTEXT(
    value_t value;
    value_t regAddr;
    uint32_t fault;
    if (evaluate("_ALWAYS", &regAddr, "") < 1) {
      return -1;
    }
    if (evaluate("_TRACE_CTRL", &regAddr, "") < 1) {
      return -1;
    }
    if (args->paramCount >= 2) {
      if (evaluate(args->params[1], &value, "") < 1) {
        return -1;
      }
    } else {
      value.value = 1;
    }
    switch (rvsrv_writeSingle(regAddr.value, value.value, 1, &fault)) {
      case 1:
        break;
      case 0:
        fprintf(stderr,
          "Context %d: failed to write 0x%02X to address 0x%08X; bus fault 0x%08X.\n",
          ctxt,
          value.value,
          regAddr.value,
          fault
        );
      default:
        return -1;
    }
    
  );
  
  // Flush the trace buffer. This can be done by reading the two buffers
  // (because when you read one buffer, it resets the other). We then read
  // the counter for the first buffer again and ensure that it's actually
  // reset. This might not be the case if the core is for some reason
  // outputting trace data even though we're expecting it not to be right
  // now.
  printf("Flushing the trace buffer...\n");
  if (flushTraceBuf(address.value) == -1) {
    return -1;
  }
  
  // Resume execution.
  printf("Resuming execution...\n");
  first = 1;
  FOR_EACH_CONTEXT(
    value_t value;
    if (evaluate("_ALWAYS", &value, "") < 1) {
      return -1;
    }
    if (evaluate("_RESUME", &value, "") < 1) {
      return -1;
    }
  );
  
  // Open the file.
  unlink(args->params[0]);
  f = open(args->params[0], O_WRONLY | O_CREAT, 00644);
  if (f < 0) {
    perror("Failed to open file for writing");
    return -1;
  }
  
  // Run the trace.
  traceByteCount = 0;
  printf("0 trace bytes received...\n");
  while (1) {
    
    int bytesRead = 0;
    
    // Read from both trace buffers.
    for (page = 0; page < 2; page++) {
      
      uint32_t fault;
      int retval;
      int remain;
      unsigned char *ptr;
      
      // Perform the bulk read operation.
      retval = rvsrv_readBulk(
        address.value + page*trace_size,
        pageBuffer,
        trace_size,
        &fault
      );
      if (retval < 0) {
        close(f);
        return -1;
      } else if (retval == 0) {
        fprintf(stderr,
          "Error: bus fault 0x%08X occured while reading from trace buffer.\n",
          fault
        );
        close(f);
        return -1;
      }
      
      // Determine how many valid bytes we've received.
      remain = ((int)pageBuffer[2] << 8) + pageBuffer[3];
      if (remain > trace_size) {
        fprintf(stderr,
          "Error: trace buffer returned invalid byte counter value.\n"
        );
        close(f);
        return -1;
      }
      
      // Don't write the first four bytes (they're the byte counter).
      remain -= 4;
      ptr = pageBuffer + 4;
      
      // Remember how many bytes we've read to detect the end of the program.
      bytesRead += remain;
      
      // Write to the file.
      while (remain) {
        int count;
        
        // Write to the file.
        count = write(f, ptr, remain);
        
        // Check for errors.
        if (count < 0) {
          perror("Could not write to output file");
          close(f);
          return -1;
        } else if (count == 0) {
          fprintf(stderr, "Could not write to output file.\n");
          close(f);
          return -1;
        }
        
        // Update counters.
        ptr += count;
        remain -= count;
        
      }
      
    }
    
    // Show that we're doing something.
    traceByteCount += bytesRead;
    printf("\r\033[A%d trace bytes received...\n", traceByteCount);
    
    // Determine if we're done yet.
    if (args->paramCount == 3) {
      
      value_t value;
      
      // Custom condition specified, evaluate it.
      if (evaluate(args->params[2], &value, "") < 1) {
        close(f);
        return -1;
      }
      
      // Break if it evaluated to 0.
      if (!value.value) {
        break;
      }
      
    } else {
      
      // No custom condition, simply break when the buffers were empty this
      // iteration.
      if (!bytesRead) {
        break;
      }
      
    }
    
  }
  
  
  // Close the file.
  close(f);
  
  // Clear the trace control registers.
  printf("Resetting trace control flags...\n");
  FOR_EACH_CONTEXT(
    value_t regAddr;
    uint32_t fault;
    if (evaluate("_ALWAYS", &regAddr, "") < 1) {
      return -1;
    }
    if (evaluate("_TRACE_CTRL", &regAddr, "") < 1) {
      return -1;
    }
    switch (rvsrv_writeSingle(regAddr.value, 0, 1, &fault)) {
      case 1:
        break;
      case 0:
        fprintf(stderr,
          "Context %d: failed to write 0x00 to address 0x%08X; bus fault 0x%08X.\n",
          ctxt,
          regAddr.value,
          fault
        );
      default:
        return -1;
    }
    
  );
  
  // Flush the trace buffer again, to make sure the core can finish writing
  // the trace packet it may be in the middle of.
  printf("Flushing the trace buffer...\n");
  if (flushTraceBuf(address.value) == -1) {
    return -1;
  }
  
  // Print an extra newline after the operation to keep things clean.
  printf("Trace complete.\n");
  printf("\n");
  
  return 0;
  
}

