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
#include "commands.h"
#include "rvsrvInterface.h"
#include "parser.h"
#include "types.h"
#include "utils.h"
#include "srec.h"
#include "definitions.h"

/**
 * Executes the "rvd download" command.
 */
int runDownload(commandLineArgs_t *args) {
  filetype_t ft;
  unsigned char pageBuffer[RVSRV_PAGE_SIZE];
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
      int count = 0;
      
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
  
}

