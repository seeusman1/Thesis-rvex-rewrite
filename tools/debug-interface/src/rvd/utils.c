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
#include <time.h>
#include <ctype.h>

#include "utils.h"

/**
 * Initializes page iteration. iterPage() should be called before anything else
 * after this initialization.
 */
iterPage_t iterPageInit(uint32_t start, int count, uint32_t pageSize) {
  iterPage_t i;
  i.pageSize = pageSize;
  i.remain = count;
  i.address = start;
  i.numBytes = 0;
  return i;
}

/**
 * Iterates to the next page, or returns 0 when done.
 */
int iterPage(iterPage_t *i) {
  i->remain = i->remain - i->numBytes;
  i->address = i->address + i->numBytes;
  i->base = i->address & ~(i->pageSize - 1);
  i->startOffs = i->address - i->base;
  i->stopOffs = i->startOffs + i->remain;
  if (i->stopOffs > i->pageSize) {
    i->stopOffs = i->pageSize;
  }
  i->numBytes = i->stopOffs - i->startOffs;
  return i->numBytes > 0;
}

/**
 * Prints a single line for hexdump.
 */
static void hexdumpLine(uint32_t address, unsigned char *buffer, int startOffs, int stopOffs, int fault, int ellipsis) {
  
  if (ellipsis) {
    
    // Print ellipsis line.
    printf("\033[1;30m|        |:  |      |  |      |  |      |  |      |   |              |");
    
  } else {
    int k;
    
    // Print the address.
    printf("0x%08X:", address);
    
    // Print 16 bytes for each line in hex.
    for (k = 0; k < 16; k++) {
      
      // Print extra space at the start of every group of 4 bytes.
      if (!(k & 0x3)) {
        printf("  ");
      }
      
      // Print each byte. Use .. instead of the byte for bytes which
      // are not part of the address range for alignment.
      if ((k >= startOffs) && (k < stopOffs)) {
        if (fault) {
          printf("\033[1;31m%02hhX", buffer[k]);
        } else if (buffer[k]) {
          printf("\033[0m%02hhX", buffer[k]);
        } else {
          printf("\033[1;30m00");
        }
      } else {
        printf("\033[1;34m..");
      }
      
    }
    
    printf("   ");
    
    // Print 16 bytes for each line as characters.
    for (k = 0; k < 16; k++) {
      
      // Print the ASCII character.
      if ((k >= startOffs) && (k < stopOffs)) {
        if (fault) {
          printf("\033[1;31m.");
        } else if (isprint(buffer[k])) {
          printf("\033[0m%c", buffer[k]);
        } else {
          printf("\033[1;30m.");
        }
      } else {
        printf("\033[1;34m.");
      }
      
    }
    
  }
  
  // Print newline.
  printf("\033[0m\n");
  
}

/**
 * Hex-dumps the given buffer to stdout.
 */
void hexdump(uint32_t address, unsigned char *buffer, int byteCount, int fault, int position) {
  
  iterPage_t j;
  
  // We use this to remember the what the contents of the previous line were.
  // When more than three subsequent lines are identical we suppress the lines
  // in between to not dump a ridiculous amount of stuff for large, sparse data
  // dumps. The last byte in this holds the value of fault, and is set to 0xFF
  // initially to indicate that it is unknown.
  static unsigned char prevLine[17];
  static uint32_t prevAddr;

  // Number of identical lines encountered.
  static int identicalLines = 0;
  
  if (position == HEXDUMP_PROLOGUE) {
    
    // Invalidate prevLine if this is the first call to a sequence of hexdump
    // calls.
    prevLine[16] = 0xFF;
    
  } else if (position == HEXDUMP_EPILOGUE) {
    
    // Print the line we have in memory if necessary.
    if (identicalLines >= 1) {
      
      // Print previous line to end range.
      hexdumpLine(prevAddr, prevLine, 0, 16, prevLine[16], 0);
      
    }
    return;
  }
  
  // Print the data. Use the same iteration logic to nicely print the
  // hex dump of the data line by line.
  j = iterPageInit(address, byteCount, 16);
  while (iterPage(&j)) {
    int sameAsPrevious = 0;
    
    // If we're dumping in no-skip mode, always print the current line.
    if (position == HEXDUMP_NO_SKIPPING) {
      hexdumpLine(j.base, buffer + j.base - address, j.startOffs, j.stopOffs, fault, 0);
      continue;
    }
    
    // Determine if this line is identical to the previous.
    sameAsPrevious = 1;
    if (j.numBytes != 16) {
      sameAsPrevious = 0;
    } else {
      int i;
      for (i = 0; i < 16; i++) {
        if (prevLine[i] != buffer[i + (j.base - address)]) {
          sameAsPrevious = 0;
          break;
        }
      }
      if (prevLine[16] != fault) {
        sameAsPrevious = 0;
      }
    }
    
    // Print stuff.
    if (sameAsPrevious) {
      if (identicalLines < 3) {
        identicalLines++;
      }
      if (identicalLines == 2) {
        
        // Print ellipsis line.
        hexdumpLine(j.base, buffer + j.base - address, j.startOffs, j.stopOffs, fault, 1);
        
      }
      
    } else {
      if (identicalLines >= 1) {
        
        // Print previous line to end range.
        hexdumpLine(j.base - 16, prevLine, 0, 16, prevLine[16], 0);
        
      }
      identicalLines = 0;
      
      // Print current line.
      hexdumpLine(j.base, buffer + j.base - address, j.startOffs, j.stopOffs, fault, 0);
      
    }
      
    // Store the current line for the next line if this is a full line.
    if (j.numBytes == 16) {
      memcpy(prevLine, buffer + j.base - address, 16);
      prevLine[16] = fault;
      prevAddr = j.base;
    }
    
  }
  
}

/**
 * Draws a progress bar.
 */
void progressBar(char *prefix, int progress, int max, int isFirstCall, int isByteCount) {
  int i;
  static time_t start;
  double elapsed;
  double complete;
  
  // Return to the beginning of the previous line to overwrite the previously
  // drawn progress bar if this is not the first time we're drawing it.
  if (!isFirstCall) {
    printf("\r\033[A");
  } else {
    start = time(0);
  }
  
  // Print the prefix, if specified.
  if (prefix) {
    printf("%s", prefix);
  }
  
  // Compute elapsed time.
  elapsed = difftime(time(0), start);
  
  if (max) {
    
    // Draw the progress bar.
    printf("[");
    for (i = 0; i < 30; i++) {
      if ((i * max) / 30 < progress) {
        printf("#");
      } else {
        printf("-");
      }
    }
    printf("]");
    
    // Compute fraction completed.
    complete = ((double)progress) / ((double)max);
    
    // Draw percentage.
    printf(" %.1f%%", complete * 100.0);
    
    // Draw time remaining.
    if ((elapsed > 3.0) && (complete > 0.05)) {
      int sec = (int)(elapsed / complete - elapsed + 0.5);
      int min = sec / 60;
      sec %= 60;
      printf("  %02d:%02d", min, sec);
    }
    
  } else {
    
    // Maximum value unknown, so just draw a rotaty thingy.
    printf("%c", "-\\|/"[((int)elapsed) % 4]);
    
  }
  
  // Clear until end of line and print newline.
  printf("\033[K\n");
  
}