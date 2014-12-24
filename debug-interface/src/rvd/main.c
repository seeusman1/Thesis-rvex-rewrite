/* Debug interface for standalone r-VEX processor
 * 
 * Copyright (C) 2008-2014 by TU Delft.
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
 * Copyright (C) 2008-2014 by TU Delft.
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

/**
 * Returns nonzero if the args specify a help command.
 */
static int isHelp(const commandLineArgs_t *args) {
  if (args->paramCount == 0) {
    return;
  }
  return !strcmp(args->params[0], "help");
}

/**
 * This macro runs the code specified by contents for each selected context.
 * Magic.
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
      "value in a memory map file.\n", \
      numContexts \
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
      "Use \"rvd select\" or the command line to select a different range of contexts.\n", \
      numContexts \
    ); \
    return -1; \
  } \
}

/**
 * Size of an rvsrv page: the maximum amount of bytes which can be transferred
 * in a single operation.
 */
#define RVSRV_PAGE_SIZE 4096

/**
 * Performs the command specified by args.
 */
int run(commandLineArgs_t *args) {
  
  // General purpose buffer capable of holding a memory single rvsrv page.
  static unsigned char pageBuffer[RVSRV_PAGE_SIZE];
  
  // --------------------------------------------------------------------------
  if (
    (!strcmp(args->command, "select"))
  ) {
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
    f = open(".rvd-context", O_WRONLY | O_CREAT);
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
    
  // --------------------------------------------------------------------------
  } else if (
    (!strcmp(args->command, "eval")) ||
    (!strcmp(args->command, "evaluate")) ||
    (!strcmp(args->command, "exec")) ||
    (!strcmp(args->command, "execute"))
  ) {
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
            printf("0x%02lX = %lu\n", value.value & 0xFF, value.value & 0xFF);
            break;
            
          case AS_HALF:
            printf("0x%04lX = %lu\n", value.value & 0xFF, value.value & 0xFF);
            break;
            
          default:
            printf("0x%08lX = %lu\n", value.value, value.value);
            break;
            
        }
        
      }
      
    );
    
    return 0;
    
  // --------------------------------------------------------------------------
  } else if (
    (!strcmp(args->command, "stop"))
  ) {
    if (isHelp(args) || (args->paramCount != 0)) {
      printf(
        "\n"
        "Command usage:\n"
        "  rvd stop\n"
        "\n"
        "This command will simply send the stop command to rvsrv, to shut rvsrv down\n"
        "gracefully.\n"
        "\n"
      );
      return 0;
    }
    
    return rvsrv_stopServer();
    
  // --------------------------------------------------------------------------
  } else if (
    (!strcmp(args->command, "write")) ||
    (!strcmp(args->command, "w"))
  ) {
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
    
  // --------------------------------------------------------------------------
  } else if (
    (!strcmp(args->command, "read")) ||
    (!strcmp(args->command, "r"))
  ) {
    int size;
    
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
          
          printf("Context %d: dumping 0x%08X..0x%08X...\n\n", ctxt, address.value, address.value + count.value * size);
          
          // Iterate over the rvsrv pages which need to be updated to perform
          // this request. iterPage and iterPageInit will ensure that all pages
          // except for the first and last are aligned.
          i = iterPageInit(address.value, count.value * size, RVSRV_PAGE_SIZE);
          first = 1;
          while (iterPage(&i)) {
            
            uint32_t fault;
            int retval;
            
            // We store the contents of the previous line to match against the
            // current. If they're identical, we don't print it to compress the
            // output. The last byte is 1 for OK, 0 for bus fault or 0xFF for
            // unknown.
            unsigned char prevLineContents[17];
            
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
            fprintf(stderr,
              "Context %d: read 0x%0*X from address 0x%08X.\n",
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
    
  // --------------------------------------------------------------------------
  } else if (
    (!strcmp(args->command, "fill"))
  ) {
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
        
        printf(
          "Context %d: writing %02hhX to 0x%08X..0x%08X...\n",
          ctxt,
          pageBuffer[0],
          address.value,
          address.value + count.value
        );
        
        // Start printing the progress bar.
        progressBar("", 0, count.value, 1, 1);
        
        // Iterate over the rvsrv pages which need to be updated to perform
        // this request. iterPage and iterPageInit will ensure that all pages
        // except for the first and last are aligned.
        i = iterPageInit(address.value, count.value, RVSRV_PAGE_SIZE);
        while (iterPage(&i)) {
          
          uint32_t fault;
          int retval;
          
          // We store the contents of the previous line to match against the
          // current. If they're identical, we don't print it to compress the
          // output. The last byte is 1 for OK, 0 for bus fault or 0xFF for
          // unknown.
          unsigned char prevLineContents[17];
          
          // Perform the bulk read operation.
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
          progressBar("", (count.value - i.remain) + i.numBytes, count.value, 0, 1);
          
        }
        
        // Print a newline to separate the contexts.
        printf("\n");
        
      }
      
    );
    
    return 0;
    
  // --------------------------------------------------------------------------
  } else if (
    (!strcmp(args->command, "upload")) ||
    (!strcmp(args->command, "up"))
  ) {
    
    printf("Sorry, not yet implemented :(\n");
    return -1;
    
  // --------------------------------------------------------------------------
  } else if (
    (!strcmp(args->command, "upload")) ||
    (!strcmp(args->command, "up"))
  ) {
    
    printf("Sorry, not yet implemented :(\n");
    return -1;
    
  // --------------------------------------------------------------------------
  } else if (
    (!strcmp(args->command, "break")) ||
    (!strcmp(args->command, "b")) ||
    (!strcmp(args->command, "step")) ||
    (!strcmp(args->command, "s")) ||
    (!strcmp(args->command, "resume")) ||
    (!strcmp(args->command, "continue")) ||
    (!strcmp(args->command, "c")) ||
    (!strcmp(args->command, "release")) ||
    (!strcmp(args->command, "reset")) ||
    (!strcmp(args->command, "rst")) ||
    (!strcmp(args->command, "state")) ||
    (!strcmp(args->command, "?"))
  ) {
    const char *expr;
    
    if (isHelp(args) || (args->paramCount != 0)) {
      printf(
        "\n"
        "Command usage:\n"
        "  rvd break      rvd b        rvd execute \"_BREAK\"\n"
        "  rvd step       rvd s        rvd execute \"_STEP\"\n"
        "  rvd resume     rvd c        rvd execute \"_RESUME\"\n"
        "  rvd release                 rvd execute \"_RELEASE\"\n"
        "  rvd reset      rvd rst      rvd execute \"_RESET\"\n"
        "  rvd state      rvs ?        rvd execute \"_STATE\"\n"
        "\n"
        "This commands listed above can be used for debugging. They're just shorthand\n"
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
      
      if (evaluate(expr, &dummyValue, "") < 1) {
        return -1;
      }
      
    );
    
    return 0;
    
  // --------------------------------------------------------------------------
  } else if (
    (!strcmp(args->command, "expressions"))
  ) {
    // (This is intentionally a help-only "command".)
    if (isHelp(args)) {
      printf(
        "\n"
        "How rvd expressions work\n"
        "------------------------\n"
        "\n"
        "Almost any integer specification in rvd - addresses, values, contexts, etc. -\n"
        "can be specified using expressions. An expression can be as simple as a number\n"
        "or as complex as a small script - it's a basic functional scripting language.\n"
        "\n"
        "Integer literals\n"
        "----------------\n"
        "The most basic construct in an rvd expression is an integer literal. Literals\n"
        "can be specified like in C, meaning that the following things are all allowed.\n"
        "\n"
        "  <decimal>\n"
        "  0<octal>\n"
        "  0x<hexadecimal>\n"
        "  0b<binary>\n"
        "\n"
        "In addition to that, you can explicitely specify the type you want the literal\n"
        "to be by adding one of the following suffixes to the literal.\n"
        "\n"
        "  w   Word      32 bit\n"
        "  h   Halfword  16 bit\n"
        "  hh  Byte      8 bit\n"
        "\n"
        "The type used for a literal does not affect the ranges allowed. Or rather,\n"
        "there is no range checking anywhere, and everything is an unsigned 32-bit\n"
        "integer internally. However, the type is relevant when performing write\n"
        "operations: calling write(0, 0hh) will write a single byte to address 0,\n"
        "whereas write(0, 0w) will write a word to address 0.\n"
        "\n"
        "When no type is specified anywhere in the evaluation of an expression and type\n"
        "information is needed for evaluation, the type defaults to a word. When multiple\n"
        "explicitely specified types are used in an expression, the widest one is used.\n"
        "So, 1 + 1hh will evaluate to a byte with value 2, whereas 1w + 1hh will evaluate\n"
        "to a word.\n"
        "\n"
        "Operators\n"
        "---------\n"
        "rvd supports the following operators.\n"
        "\n"
        "  +   Addition\n"
        "  -   Subtraction or unary negation\n"
        "  *   Multiplication\n"
        "  /   Division\n"
        "  %   Modulo\n"
        "  ==  Equality\n"
        "  !=  Non-equality\n"
        "  <   Less than\n"
        "  <=  Less than or equal\n"
        "  >   Greater than\n"
        "  >=  Greater than or equal\n"
        "  !   Logical not\n"
        "  &&  Logical and\n"
        "  ||  Logical or\n"
        "  ~   Unary one's complement\n"
        "  &   Bitwise and\n"
        "  |   Bitwise or\n"
        "  ^   Bitwise xor\n"
        "  <<  Left shift\n"
        "  >>  Right shift (unsigned)\n"
        "  ;   Sequential\n"
        "\n"
        "With the exception of the sequential operator, all operators behave the same as\n"
        "their C counterparts (applied to uint32_ts) on their own. However, THERE IS\n"
        "NO OPERATOR PRECEDENCE, and ALL OPERATORS ARE RIGHT ASSOCIATIVE. This means\n"
        "that, for example, 2 * 3 + 4 will be interpreted as 2 * (3 + 4) = 14, not\n"
        "(2 * 3) + 4 = 10. You should always use parenthesis when combining operators to\n"
        "make sure it will do what you want it to.\n"
        "\n"
        "The sequential operator will simply evaluate both sides sequentially, and pick\n"
        "the result of the rightmost operator. The second operand of this operator is\n"
        "optional when the operator is followed by a close parenthesis or the end of the\n"
        "parsed string, in which case the first operand result is returned, as if the\n"
        "semicolon was not there.\n"
        "\n"
        "Definitions\n"
        "-----------\n"
        "The definition system is what makes expressions useful. An rvd expression\n"
        "behaves approximately like a C preprocessor definition: when an identifier\n"
        "is encountered in an expression which was previously defined, the defined\n"
        "expansion for the definition is evaluated as if it were an expression. This\n"
        "means that definitions can be used to define constants, as well as functions\n"
        "(without parameters).\n"
        "\n"
        "Definitions can be defined in the following ways.\n"
        "\n"
        " - Through a .map file.\n"
        " - Using the -d or --define command line parameters.\n"
        " - Dynamically within expressions, using the set() or def() functions.\n"
        "\n"
        "The syntax for a definition in a map file or on the command line looks like\n"
        "this:\n"
        "\n"
        "  <contexts>: <name> { <expression> }\n"
        "\n"
        "The <contexts> part specifies for which contexts the definition should be valid.\n"
        "Call \"rvd help select\" for more information; the syntax for <contexts> in the\n"
        "select command parameter is identical.\n"
        "\n"
        "<name> specifies the name for the definition. Names must start with an\n"
        "alphabetical character or an underscore, and may contain any combination of\n"
        "alphanumerical and underscores for the rest of the characters. Names are case\n"
        "sensitive. <expression> may specify any syntactically correct expression.\n"
        "\n"
        "Within .map files, anything between a # (hash) and a newline is a comment.\n"
        "\n"
        "The order in which definitions are defined does not matter, as long as\n"
        "everything is defined when the definition is used in an evaluated expression.\n"
        "This means loops are possible; when a certain number of expansions have been\n"
        "performed, however, parsing will terminate, to prevent hangs in this case.\n"
        "\n"
        "When definitions are defined dynamically using set() or def(), they are bound\n"
        "to the context currently being evaluated. This means that, for all intents and\n"
        "purporses, they behave like variables or dynamically created functions. The\n"
        "difference between set() and def() is that set() evaluates the given expression\n"
        "while set() as part of the set() command (making the definition behave like a\n"
        "variable), whereas def() defers evaluation until the definition is used (like\n"
        "a function).\n"
        "\n"
        "Functions\n"
        "---------\n"
        "In order for expression evaluation to actually do something, a number of\n"
        "built-in functions are made available. These are listed below.\n"
        "\n"
        "  read(address)\n"
        "  readByte(address)\n"
        "  readHalf(address)\n"
        "  readWord(address)\n"
        "    These functions initiate a volatile hardware read, returning the value read.\n"
        "    If any kind of error or a bus fault occurs, evaluation is terminated. read\n"
        "    is simply a synonym for readWord().\n"
        "\n"
        "  write(address, value)\n"
        "  writeByte(address, value)\n"
        "  writeHalf(address, value)\n"
        "  writeWord(address, value)\n"
        "    These functions initiate a volatile hardware write. They return the value\n"
        "    written. If any kind of error or a bus fault occurs, evaluation is\n"
        "    terminated. write() will choose its access size based upon the type attached\n"
        "    to value.\n"
        "\n"
        "  printf(format, ...)\n"
        "    This method wraps part of the C printf method. Refer to C documentation on\n"
        "    how it works. The following specifiers are NOT allowed:\n"
        "      f F e E g G a A c s p n\n"
        "    Also, size modifiers should not be used. printf will always return 0.\n"
        "\n"
        "  def(name, expansion)\n"
        "  set(name, expression)\n"
        "    Defines a definition dynamically. def() will set the expansion to the given\n"
        "    expression without evaluating it, deferring evaluation until the definition\n"
        "    is used. This allows basic procedures to be defined. set() evaluated the\n"
        "    given expression and sets the expansion of the definition to that value.\n"
        "    def() will always return zero, set() will return the value which was set.\n"
        "\n"
        "  if(condition, command-if-true)\n"
        "  if(condition, command-if-true, command-if-false)\n"
        "    Allows conditional evaluation. condition is always evaluated. If it\n"
        "    evaluates to nonzero, command-if-true is evaluated, but command-if-false\n"
        "    (if specified) is not. When condition is evaluates to zero, the opposite\n"
        "    operation is performed. if() will return the result of the executed command,\n"
        "    or 0 if condition evaluated to zero and command-if-false was not specified.\n"
        "\n"
        "  while(condition, command)\n"
        "    Allows looping. While condition evaluates to nonzero, command is evaluated.\n"
        "    Obviously, condition will also be evaluated for every iteration. while()\n"
        "    returns the last evaluated value for command, or 0 if it has not been\n"
        "    evaluated.\n"
        "\n"
      );
      return 0;
    }
  }
  
  // Unknown command.
  fprintf(stderr, "Unknown command %s.\n", args->command);
  return -1;
  
}

