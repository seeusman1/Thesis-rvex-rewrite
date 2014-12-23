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

#include "readFile.h"

/**
 * Reads a whole file into memory. If size is set to null, the resuling buffer
 * will be a null terminated string; otherwise, *size will be set to the number
 * of bytes in the buffer. Returns null if some error occurs. If silent is
 * zero, an error message will be printed in this case. The resulting buffer
 * should be freed by the caller.
 */
char *readFile(const char *filename, int *size, int silent) {
  int f;
  off_t fileSize;
  char *buffer;
  char *ptr;
  int remain;
  
  // Open the file.
  f = open(filename, O_RDONLY);
  if (f < 0) {
    if (!silent) {
      perror("Failed to open file for reading");
      printf("The filename was %s\n", filename);
    }
    return 0;
  }
  
  // Determine the filesize by seeking.
  fileSize = lseek(f, 0, SEEK_END);
  if (fileSize == (off_t)-1) {
    if (!silent) {
      perror("Could not seek to end of file to determine size");
      printf("The filename was %s\n", filename);
    }
    close(f);
    return 0;
  }
  if (lseek(f, 0, SEEK_SET) == (off_t)-1) {
    if (!silent) {
      perror("Could not seek to start of file");
      printf("The filename was %s\n", filename);
    }
    close(f);
    return 0;
  }
  
  // Allocate a buffer the size of the file, or the size of the file plus one
  // if a null-terminated string was requested.
  buffer = (char*)malloc(fileSize + (size ? 0 : 1));
  if (!buffer) {
    if (!silent) {
      perror("Failed to allocate memory to read file");
      printf("The filename was %s\n", filename);
    }
    close(f);
    return 0;
  }
  
  // Read the file into the buffer.
  ptr = buffer;
  remain = fileSize;
  while (remain) {
    int count = read(f, ptr, remain);
    if (count < 1) {
      if (!silent) {
        perror("Failed to read from file");
        printf("The filename was %s\n", filename);
      }
      close(f);
      free(buffer);
      return 0;
    }
    remain -= count;
    ptr += count;
  }
  
  // Close the file.
  close(f);
  
  // Null terminate/return size and return the buffer.
  if (!size) {
    buffer[fileSize] = 0;
  } else {
    *size = fileSize;
  }
  return buffer;
}

