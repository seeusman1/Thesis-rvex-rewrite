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
 * Executes the "rvd upload" command.
 */
int runUpload(commandLineArgs_t *args) {
  filetype_t ft;
  unsigned char pageBuffer[RVSRV_PAGE_SIZE];
  
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
      int retval;
      uint32_t fault;
      i.numBytes = 0;
      i.stopOffs = i.startOffs;
      
      // Make sure the page iterator doesn't run out.
      i.remain = RVSRV_PAGE_SIZE * 2;
      
      // Read into the buffer.
      while (remain) {
        int count = 0;
        
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
  
}

