/* Debug interface for standalone r-VEX processor
 * 
 * Copyright (C) 2008-2015 by TU Delft.
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
 * Copyright (C) 2008-2015 by TU Delft.
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

/**
 * Enumeration for the supported file types.
 */
typedef enum {
  FT_UNKNOWN, FT_STRAIGHT, FT_SREC
} filetype_t;

/**
 * Converts a filetype mnemonic into a filetype_t.
 */
static filetype_t interpretFiletype(const char *filetype) {
  if (!strcmp(filetype, "srec")) return FT_SREC;
  if (!strcmp(filetype, "s"))    return FT_SREC;
  if (!strcmp(filetype, "bin"))  return FT_STRAIGHT;
  if (!strcmp(filetype, "b"))    return FT_STRAIGHT;
  return FT_UNKNOWN;
}

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
#define RVSRV_PAGE_SIZE_LOG2 12
#define RVSRV_PAGE_SIZE (1 << (RVSRV_PAGE_SIZE_LOG2))

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
    
  // --------------------------------------------------------------------------
  } else if (
    (!strcmp(args->command, "upload")) ||
    (!strcmp(args->command, "up"))
  ) {
    filetype_t ft;
    
    if (isHelp(args) || (args->paramCount < 2) || (args->paramCount > 3)) {
      printf(
        "\n"
        "Command usage:\n"
        "  rvd upload <filetype> <filename> [address]\n"
        "  rvd up <filetype> <filename> [address]\n"
        "\n"
        "This command uploads <filename> to the hardware, parsing the file with the\n"
        "format specified by <filetype>, which must be one of the following.\n"
        "\n"
        " - \"srec\" or \"s\": Motorola S-record file.\n"
        " - \"bin\" or \"b\": straight binary, no format.\n"
        "\n"
        "The optional address parameter specifies where the contents of the file should\n"
        "be written to. For straight binary files, this markes the start address; for\n"
        "S-record files (which have embedded addresses), this address is added to all\n"
        "addresses in the S-record.\n"
        "\n"
        "Like all commands, upload is run for every selected context. The specified\n"
        "is guaranteed to be evaluated exactly once before the file is loaded, allowing\n"
        "it to perform bank selection operations as required.\n"
        "\n"
      );
      return 0;
    }
    
    // Interpret the file type.
    ft = interpretFiletype(args->params[0]);
    if (ft == FT_UNKNOWN) {
      printf("Error: unsupported file type %s.\n", args->params[0]);
    }
    
    FOR_EACH_CONTEXT(
      
      iterPage_t i;
      void *fileReaderState;
      int f;
      int fileSize;
      uint32_t address;
      int totalFileBytes;
      int totalDataBytes;
      char prefix[16];
      value_t dummyValue;
      
      // Execute the _ALWAYS definition.
      if (evaluate("_ALWAYS", &dummyValue, "") < 1) {
        return -1;
      }
      
      // Evaluate the address if it is specified, otherwise set it to 0.
      if (args->paramCount > 2) {
        value_t addressVal;
        if (evaluate(args->params[2], &addressVal, "") < 1) {
          return -1;
        }
        address = addressVal.value;
      } else {
        address = 0;
      }
      
      // Give a little feedback.
      printf("Uploading file to 0x%08X for context %d...\n", address, ctxt);
      
      // Try to open the file.
      f = open(args->params[1], O_RDONLY);
      if (f < 0) {
        perror("Failed to open input file");
      }
      
      // Try to determine the size of the file.
      fileSize = lseek(f, 0, SEEK_END);
      if (fileSize == (off_t)-1) {
        
        // Can't seek, so we don't know the filesize. Maybe it's a stream of
        // some sort - we can still read from the file probably, which is all
        // we need, we just can't draw a normal progress bar now.
        fileSize = 0;
        
      } else if (lseek(f, 0, SEEK_SET) == (off_t)-1) {
        perror("Could not seek back to start of file");
        close(f);
        return -1;
      }
      
      // Initialize counters.
      totalFileBytes = 0;
      totalDataBytes = 0;
      
      // Initialize the file type reader.
      if (ft == FT_SREC) {
        if (!(fileReaderState = srecReadInit())) {
          return -1;
        }
      }
      
      // Start printing the progress bar.
      sprintf(prefix, "0x%08X ", address);
      progressBar(prefix, 0, fileSize, 1, 1);
      
      // Iterate over rvsrv pages starting at the current address. We don't
      // know exactly how much we're going to write, so we just set that to a
      // bogus value and make sure it doesn't run out.
      i = iterPageInit(address, RVSRV_PAGE_SIZE * 2, RVSRV_PAGE_SIZE);
      while (iterPage(&i)) {
        int remain = i.numBytes;
        unsigned char *ptr = pageBuffer;
        int count;
        int retval;
        uint32_t fault;
        i.numBytes = 0;
        i.stopOffs = i.startOffs;
        
        // Make sure the page iterator doesn't run out.
        i.remain = RVSRV_PAGE_SIZE * 2;
        
        // Read into the buffer.
        while (remain) {
          int count;
          
          if (ft == FT_STRAIGHT) {
            
            // Just read straight from the file.
            count = read(f, ptr, remain);
            if (count < 0) {
              perror("Failed to read from input file");
              close(f);
              return -1;
            } else if (count == 0) {
              
              // End of file reached: set remain to the number of bytes which
              // we're about to upload so the page iterator will stop.
              i.remain = i.numBytes;
              break;
              
            }
            
            // Update the bytes read counter.
            totalFileBytes += count;
            
          } else if (ft == FT_SREC) {
            
            // Call the srec read method. 
            count = srecRead(fileReaderState, f, ptr, remain, i.address - address);
            if (count < 0) {
              close(f);
              srecReadFree(fileReaderState);
              return -1;
            } else if (count == 0) {
              
              // If count is zero, it's either because we've reached the end of
              // the file or because a noncontiguous address was encountered.
              // We'll check for the address jump later - either way, we need
              // to stop filling the buffer now.
              break;
              
            }
            
            // Update the bytes read counter.
            totalFileBytes += srecReadProgressDelta(fileReaderState);
            
          }
          
          // Update counters.
          totalDataBytes += count;
          i.numBytes += count;
          i.stopOffs += count;
          remain -= count;
          ptr += count;
          
        }
        
        // If we have bytes available, perform the write.
        if (i.numBytes) {
          
          // Perform the bulk write operation.
          retval = rvsrv_writeBulk(i.address, pageBuffer, i.numBytes, &fault);
          if (retval < 0) {
            close(f);
            if (ft == FT_SREC) {
              srecReadFree(fileReaderState);
            }
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
          
        }
        
        // Update the progress bar.
        sprintf(prefix, "0x%08X ", i.address + i.numBytes - 1);
        progressBar(prefix, totalFileBytes, fileSize, 0, 1);
          
        // See if we need to change the address or if we're at the end of
        // whatever file type we're reading.
        if (ft == FT_SREC) {
          
          // Stop iterating if we're at the end of the file.
          if (srecReadEof(fileReaderState)) {
            i.remain = i.numBytes;
          }
          
          // Change address to whatever the srec wants it to be. Note that the
          // iterate method will add i.numBytes to the address to update it,
          // which we don't want, so we do the reverse operation here.
          i.address = (srecReadExpectedAddress(fileReaderState) + address) - i.numBytes;
          
        }
        
      }
      
      // Free the file type reader state.
      if (ft == FT_SREC) {
        srecReadFree(fileReaderState);
      }
      fileReaderState = 0;
      
      // Finish the progress indicator.
      progressBar(prefix, fileSize, fileSize, 0, 0);
      
      // Show how many bytes we've uploaded and 
      printf("Uploaded %d bytes.\n", totalDataBytes);
      
      // Print a newline to separate the contexts.
      printf("\n");
      
      // Close the file.
      close(f);
      
    );
    
    return 0;
    
  // --------------------------------------------------------------------------
  } else if (
    (!strcmp(args->command, "download")) ||
    (!strcmp(args->command, "dl"))
  ) {
    filetype_t ft;
    int selectedContext = 0;
    int multipleContexts = 0;
    value_t address;
    value_t count;
    int f;
    iterPage_t i;
    char prefix[16];
    value_t dummyValue;
    
    if (isHelp(args) || (args->paramCount != 4)) {
      printf(
        "\n"
        "Command usage:\n"
        "  rvd download <filetype> <filename> <address> <bytecount>\n"
        "  rvd dl <filetype> <filename> <address> <bytecount>\n"
        "\n"
        "WARNING: if the specified file already exists, it will be overwritten.\n"
        "\n"
        "This command downloads the address range specified by <address> and <bytecount>\n"
        "to the file specified by <filename>, using the specified file format. <filetype>\n"
        "can be one of the following values.\n"
        "\n"
        " - \"srec\" or \"s\": Motorola S-record file.\n"
        " - \"bin\" or \"b\": straight binary, no format.\n"
        "\n"
        "Unlike most commands, download cannot be run with multiple contexts selected,\n"
        "as this would just write to the same file multiple times. rvd will display an\n"
        "error if you try to do this.\n"
        "\n"
      );
      return 0;
    }
    
    // Interpret the file type.
    ft = interpretFiletype(args->params[0]);
    if (ft == FT_UNKNOWN) {
      printf("Error: unsupported file type %s.\n", args->params[0]);
    }
    
    // Determine which contexts we should use and crash if multiple contexts are
    // selected.
    FOR_EACH_CONTEXT(
      if (multipleContexts) {
        fprintf(stderr,
          "You have multiple contexts selected; download does not support this. Please use\n"
          "\"rvd select\" or the -c or --context command line parameter to select a single\n"
          "context and try again.\n"
        );
        return -1;
      }
      selectedContext = ctxt;
      multipleContexts = 1;
    );
    
    // Execute the _ALWAYS definition.
    if (evaluate("_ALWAYS", &dummyValue, "") < 1) {
      return -1;
    }
    
    // Evaluate the start address.
    if (evaluate(args->params[2], &address, "") < 1) {
      return -1;
    }
    
    // Evaluate the number of bytes to download.
    if (evaluate(args->params[3], &count, "") < 1) {
      return -1;
    }
    
    // We don't have to do anything if 0 bytes were requested.
    if (!count.value) {
      printf("0 bytes requested, nothing to do.\n");
      return 0;
    }
    
    // Open the file.
    unlink(args->params[1]);
    f = open(args->params[1], O_WRONLY | O_CREAT, 00644);
    if (f < 0) {
      perror("Failed to open file for writing");
      return -1;
    }
    
    // Give some feedback.
    printf(
      "Context %d: downloading 0x%08X..0x%08X to %s...\n",
      selectedContext,
      address.value,
      address.value + count.value - 1,
      args->params[1]
    );
    
    // Start printing the progress bar.
    sprintf(prefix, "0x%08X ", address.value);
    progressBar(prefix, 0, count.value, 1, 1);
    
    // Write header.
    if (ft == FT_SREC) {
      if (srecWriteHeader(f) < 0) {
        close(f);
        return -1;
      }
    }
    
    // Iterate over the rvsrv pages which need to be updated to perform
    // this request. iterPage and iterPageInit will ensure that all pages
    // except for the first and last are aligned.
    i = iterPageInit(address.value, count.value, RVSRV_PAGE_SIZE);
    while (iterPage(&i)) {
      
      uint32_t fault;
      uint32_t curAddress;
      int retval;
      int remain;
      unsigned char *ptr;
      
      // Perform the bulk read operation.
      retval = rvsrv_readBulk(i.address, pageBuffer, i.numBytes, &fault);
      if (retval < 0) {
        close(f);
        return -1;
      } else if (retval == 0) {
        int k;
        printf(
          "\r\033[AWarning: bus fault 0x%08X occured while reading page 0x%08X..0x%08X.\n"
          "Bus fault code will be written to file instead of actual data.\033[K\n\n",
          fault,
          i.address,
          i.address + i.numBytes - 1
        );
        for (k = 0; k < RVSRV_PAGE_SIZE / 4; k++) {
          pageBuffer[k*4+0] = fault >> 24;
          pageBuffer[k*4+1] = fault >> 16;
          pageBuffer[k*4+2] = fault >> 8;
          pageBuffer[k*4+3] = fault;
        }
      }
      
      //hexdump(i.address, pageBuffer, i.numBytes, !retval, first ? HEXDUMP_PROLOGUE : HEXDUMP_CONTENT);
      
      // Call the write method for the selected filetype until all data has
      // been written.
      remain = i.numBytes;
      ptr = pageBuffer;
      curAddress = i.address;
      while (remain) {
        int count;
        
        // Write to the file.
        if (ft == FT_STRAIGHT) {
          count = write(f, ptr, remain);
        } else if (ft == FT_SREC) {
          count = srecWrite(f, ptr, remain, curAddress);
        }
        
        // Check for errors.
        if (count < 0) {
          if (ft == FT_STRAIGHT) {
            perror("Could not write to output file");
          }
          close(f);
          return -1;
        } else if (count == 0) {
          if (ft == FT_STRAIGHT) {
            fprintf(stderr, "Could not write to output file.\n");
          }
          close(f);
          return -1;
        }
        
        // Update counters.
        ptr += count;
        remain -= count;
        curAddress += count;
        
      }
        
      // Update the progress bar.
      sprintf(prefix, "0x%08X ", i.address + i.numBytes - 1);
      progressBar(prefix, (count.value - i.remain) + i.numBytes, count.value, 0, 1);
      
    }
    
    // Write footer.
    if (ft == FT_SREC) {
      if (srecWriteFooter(f) < 0) {
        close(f);
        return -1;
      }
    }
    
    // Print an extra newline after the operation to keep things clean.
    printf("\n");
    
    // Close the file.
    close(f);
    return 0;
    
  // --------------------------------------------------------------------------
  } else if (
    (!strcmp(args->command, "trace"))
  ) {
    value_t address;
    int f;
    int first;
    uint32_t i;
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
        "  _TRACE_CTRL - Should evaluate to the byte address of the trace control\n"
        "                register for the current context.\n"
        "\n"
        "NOTE: the trace peripheral must be configured to use a %d byte buffer, i.e.\n"
        "DEPTH_LOG2B = %d, and _TRACE_ADDR must be aligned to this size.\n"
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
        "\n", RVSRV_PAGE_SIZE*2, RVSRV_PAGE_SIZE_LOG2+1
      );
      return 0;
    }
    
    printf("Initializing trace...\n");
    
    // Halt each selected context and evaluate the trace buffer address. Do the
    // latter for each context and make sure the result is the same for all
    // (which might not be the case in multiprocessor systems).
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
      first = 0;
    );
    
    // Write to the trace control registers.
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
    switch (rvsrv_readSingle(address.value + RVSRV_PAGE_SIZE, &i, 4)) {
      case 1:
        break;
      case 0:
        fprintf(stderr,
          "Error: failed to read from address 0x%08X; bus fault 0x%08X.\n",
          address.value,
          i
        );
      default:
        return -1;
    }
    switch (rvsrv_readSingle(address.value, &i, 4)) {
      case 1:
        break;
      case 0:
        fprintf(stderr,
          "Error: failed to read from address 0x%08X; bus fault 0x%08X.\n",
          address.value,
          i
        );
      default:
        return -1;
    }
    switch (rvsrv_readSingle(address.value + RVSRV_PAGE_SIZE, &i, 4)) {
      case 1:
        if (i != 4) {
          fprintf(stderr,
            "Error: failed to reset trace buffer.\n"
          );
        }
        break;
      case 0:
        fprintf(stderr,
          "Error: failed to read from address 0x%08X; bus fault 0x%08X.\n",
          address.value,
          i
        );
      default:
        return -1;
    }
    
    // Resume execution.
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
          address.value + page*RVSRV_PAGE_SIZE,
          pageBuffer,
          RVSRV_PAGE_SIZE,
          &fault
        );
        if (retval < 0) {
          close(f);
          return -1;
        } else if (retval == 0) {
          int k;
          fprintf(stderr,
            "Error: bus fault 0x%08X occured while reading from trace buffer.\n",
            fault
          );
          close(f);
          return -1;
        }
        
        // Determine how many valid bytes we've received.
        remain = ((int)pageBuffer[2] << 8) + pageBuffer[3];
        if (remain > RVSRV_PAGE_SIZE) {
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
    
    printf("Done. Cleaning up...\n");
    
    // Close the file.
    close(f);
    
    // Clear the trace control registers.
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
    switch (rvsrv_readSingle(address.value + RVSRV_PAGE_SIZE, &i, 4)) {
      case 1:
        break;
      case 0:
        fprintf(stderr,
          "Error: failed to read from address 0x%08X; bus fault 0x%08X.\n",
          address.value,
          i
        );
      default:
        return -1;
    }
    switch (rvsrv_readSingle(address.value, &i, 4)) {
      case 1:
        break;
      case 0:
        fprintf(stderr,
          "Error: failed to read from address 0x%08X; bus fault 0x%08X.\n",
          address.value,
          i
        );
      default:
        return -1;
    }
    
    // Print an extra newline after the operation to keep things clean.
    printf("Trace complete.\n");
    printf("\n");
    
    return 0;
    
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
        "  rvd resume                  rvd execute \"_RESUME\"\n"
        "  rvd continue   rvd c        rvd execute \"_RESUME\"\n"
        "  rvd release                 rvd execute \"_RELEASE\"\n"
        "  rvd reset      rvd rst      rvd execute \"_RESET\"\n"
        "  rvd state      rvs ?        rvd execute \"_STATE\"\n"
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
        "Required definitions\n"
        "--------------------\n"
        "There are a few definitions which should always be defined, either in a memory\n"
        "map file or as a command line parameter. These are the following.\n"
        "\n"
        "  _ALWAYS        This is always executed once before rvd does its first hardware\n"
        "                 access. Can be used to set up banking based on the predefined\n"
        "                 _CUR_CONTEXT definition.\n"
        "\n"
        "  _NUM_CONTEXTS  This defines the number of contexts available. Should expand\n"
        "                 to the same value for all contexts.\n"
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
        "  delay_ms(time)\n"
        "    Delays execution for the specified amount of milliseconds.\n"
        "\n"
      );
      return 0;
    }
  }
  
  // Unknown command.
  fprintf(stderr, "Unknown command %s.\n", args->command);
  return -1;
  
}

