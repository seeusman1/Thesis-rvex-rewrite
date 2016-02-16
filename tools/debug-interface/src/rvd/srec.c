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

#define _GNU_SOURCE
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>

#include "srec.h"

/**
 * States in the srec read FSM.
 */
typedef enum {
  SRS_RECORD,
  SRS_COUNT,
  SRS_ADDRESS,
  SRS_DATA,
  SRS_CHECKSUM,
  SRS_EOL
} srecReadStateEnum_t;

/**
 * srec reader state structure.
 */
typedef struct {
  
  /**
   * Current parser FSM state.
   */
  srecReadStateEnum_t state;
  
  /**
   * Number of address bytes remaining in record.
   */
  int addrRemain;
  
  /**
   * Number of data bytes remaining in record.
   */
  int dataRemain;
  
  /**
   * Number of complete lines read so far.
   */
  int linesRead;
  
  /**
   * Checksum so far.
   */
  unsigned char checksum;
  
  /**
   * Current srec-address-space address.
   */
  uint32_t address;
  
  /**
   * Records the number of bytes read since the last call to
   * srecReadProgressDelta().
   */
  int fileBytesReadDelta;
  
  /**
   * This is set when we've reached the end of the file.
   */
  int isEof;
  
} srecReadState_t;

/**
 * Initializes an srec reader state object. If this returns null, an error
 * occured (which will have been printed). When the file has been read,
 * srecReadFree() must be called on the returned pointer, if non-null.
 */
void *srecReadInit(void) {
  
  void *s;
  s = malloc(sizeof(srecReadState_t));
  if (s) {
    memset(s, 0, sizeof(srecReadState_t));
  }
  return s;
  
}

/**
 * Reads from an srec file. state should be set to the pointer returned by
 * srecReadInit(). f is the file descriptor to read from, buffer is the buffer
 * to read to, and count is the maximum amount of characters to read. address
 * specifies the address corresponding to the start of the buffer in srec
 * address space; if this does not match the current address in the srec, no
 * bytes will be read and 0 is returned. When the end of the file has been
 * reached, 0 is returned as well. If an error occurs, -1 is returned and an
 * error is printed. Otherwise, this returns the number of bytes written to
 * the buffer.
 */
int srecRead(void *state, int f, unsigned char *buffer, int count, uint32_t address) {
  srecReadState_t *s = (srecReadState_t*)state;
  int remain;
  unsigned char readBuf[2];
  unsigned char byte;
  
  remain = count;
  count = 0;
  while (remain) {
    int retval;
    
    // If we're going to be reading data, make sure the expected and actual
    // addresses match.
    if (s->state == SRS_DATA) {
      if (address != s->address) {
        return count;
      }
    }
    
    // Read two characters from the file, except when we're expecting newline
    // characters.
    retval = read(f, readBuf, (s->state == SRS_EOL) ? 1 : 2);
    if ((retval == 1) && (s->state != SRS_EOL)) {
      retval = read(f, readBuf + 1, 1);
    }
    
    // Check for errors and end of file.
    if (retval < 0) {
      perror("Failed to read from srec file");
      return -1;
    } else if (retval == 0) {
      if ((s->state != SRS_RECORD) && (s->state != SRS_EOL)) {
        printf("Warning: unexpected end of file in srec.\n");
      }
      s->isEof = 1;
      return count;
    }
    
    // Update number of bytes read from the file.
    s->fileBytesReadDelta += (s->state == SRS_EOL) ? 1 : 2;
    
    // Combine the two hex characters into a byte.
    switch (s->state) {
      case SRS_RECORD:
        s->checksum = 0;
        if ((readBuf[0] == '\n') || (readBuf[1] == '\n')) {
          printf("Warning: unexpected end of line in srec (line %d).\n", s->linesRead + 1);
          s->linesRead++;
          s->state = SRS_RECORD;
          break;
        }
        if (readBuf[0] != 'S') {
          printf("Warning: srec line did not start with S, skipping record (line %d).\n", s->linesRead + 1);
          s->state = SRS_EOL;
          break;
        }
        switch (readBuf[1]) {
          case '1':
            s->addrRemain = 2;
            s->state = SRS_COUNT;
            break;
          case '2':
            s->addrRemain = 3;
            s->state = SRS_COUNT;
            break;
          case '3':
            s->addrRemain = 4;
            s->state = SRS_COUNT;
            break;
          default:
            // Unknown record.
            s->state = SRS_EOL;
            break;
        }
        
        break;
      
      case SRS_COUNT:
      case SRS_ADDRESS:
      case SRS_DATA:
      case SRS_CHECKSUM:
        
        // Check for unexpected newlines.
        if ((readBuf[0] == '\n') || (readBuf[1] == '\n')) {
          printf("Warning: unexpected end of line in srec (line %d).\n", s->linesRead + 1);
          s->linesRead++;
          s->state = SRS_RECORD;
          break;
        }
        
        // Interpret the two characters read as hex chars.
        if ((readBuf[0] >= '0') && (readBuf[0] <= '9')) {
          byte = readBuf[0] - '0';
        } else if ((readBuf[0] >= 'A') && (readBuf[0] <= 'F')) {
          byte = readBuf[0] - 'A' + 10;
        } else {
          printf("Warning: unexpected character in srec, skipping rest of record (line %d).\n", s->linesRead + 1);
          s->state = SRS_EOL;
          break;
        }
        byte <<= 4;
        if ((readBuf[1] >= '0') && (readBuf[1] <= '9')) {
          byte |= readBuf[1] - '0';
        } else if ((readBuf[1] >= 'A') && (readBuf[1] <= 'F')) {
          byte |= readBuf[1] - 'A' + 10;
        } else {
          printf("Warning: unexpected character in srec, skipping rest of record (line %d).\n", s->linesRead + 1);
          s->state = SRS_EOL;
          break;
        }
        
        // Handle the read byte.
        switch (s->state) {
          case SRS_COUNT:
            s->dataRemain = byte - 1 - s->addrRemain;
            s->state = SRS_ADDRESS;
            s->address = 0;
            break;
            
          case SRS_ADDRESS:
            s->address <<= 8;
            s->address |= byte;
            s->addrRemain--;
            if (!s->addrRemain) {
              s->state = SRS_DATA;
            }
            break;
            
          case SRS_DATA:
            
            // Store the read byte.
            *buffer++ = byte;
            
            // Update the various counters.
            count++;
            remain--;
            address++;
            s->address++;
            s->dataRemain--;
            
            // Go to the next state when we've run out of data bytes in this
            // record.
            if (!s->dataRemain) {
              s->state = SRS_CHECKSUM;
            }
            break;
            
          case SRS_CHECKSUM:
            if ((byte & 0xFF) != ((~(s->checksum)) & 0xFF)) {
              printf("Warning: incorrect checksum, but record was read anyway (line %d).\n", s->linesRead + 1);
            }
            s->state = SRS_EOL;
            break;
            
          default: ;
            
        }
        
        // Update the checksum.
        s->checksum += byte;
        
        break;
        
      case SRS_EOL:
        
        // Ignore everything except a newline.
        if (readBuf[0] == '\n') {
          s->linesRead++;
          s->state = SRS_RECORD;
        }
        break;
        
    }
    
  }
  
  // Return how many data bytes we've read.
  return count;
  
}

/**
 * Returns the number of bytes read from the file (as in, ASCII bytes, not the
 * data bytes described by the file) since the last call to this function. Can
 * be used for progress indication.
 */
int srecReadProgressDelta(void *state) {
  srecReadState_t *s = (srecReadState_t*)state;
  int count = s->fileBytesReadDelta;
  s->fileBytesReadDelta = 0;
  return count;
}

/**
 * Returns nonzero of the end of the file has been reached.
 */
int srecReadEof(void *state) {
  srecReadState_t *s = (srecReadState_t*)state;
  return s->isEof;
}

/**
 * Returns the expected address needed for the next read operation to succeed.
 */
uint32_t srecReadExpectedAddress(void *state) {
  srecReadState_t *s = (srecReadState_t*)state;
  return s->address;
}

/**
 * Frees the state data structure allocated by srecReadInit().
 */
void srecReadFree(void *state) {
  free(state);
}

/**
 * Writes the given string to a file.
 */
static int writeStr(int f, unsigned char *buf) {
  int remain = strlen((const char *)buf);
  while (remain) {
    int count = write(f, buf, remain);
    if (count < 0) {
      perror("Failed to write to file");
      return -1;
    } else if (count == 0) {
      fprintf(stderr, "Failed to write to file");
      return -1;
    }
    remain -= count;
    buf += count;
  }
  return 0;
}

/**
 * Records the number of records written to the s-rec file so far.
 */
static int numDataRecordsWritten;

/**
 * Writes a single S-record to a file.
 */
static int srecWriteRecord(int f, char recType, uint32_t address, const unsigned char *data, int count) {
  
  static unsigned char buf[32];
  int addrSize = 2;
  unsigned char checksum = 0;
  
  // Figure out the address size requirement, and update the record type
  // accordingly.
  if (address & 0xFF000000) {
    addrSize = 4;
  } else if (address & 0xFFFF0000) {
    addrSize = 3;
  }
  switch (recType) {
    case '1':
    case '2':
    case '3':
      recType = '1' + (addrSize - 2);
      break;
    case '5':
    case '6':
      recType = '5' + (addrSize - 2);
      break;
    case '7':
    case '8':
    case '9':
      recType = '9' - (addrSize - 2);
      break;
  }
  
  // Write s-record header.
  sprintf((char *)buf, "S%c%02X%0*X", recType, count+addrSize+1, addrSize*2, address);
  if (writeStr(f, buf) < 0) {
    return -1;
  }
  
  // Update checksum to reflect header.
  checksum += count+addrSize+1;
  while (addrSize) {
    checksum += address;
    address >>= 8;
    addrSize--;
  }
  
  // Write the data.
  while (count) {
    sprintf((char *)buf, "%02hhX", *data);
    if (writeStr(f, buf) < 0) {
      return -1;
    }
    checksum += *data;
    data++;
    count--;
  }
  
  // Write the checksum and newline.
  checksum = ~checksum;
  sprintf((char *)buf, "%02hhX\r\n", checksum);
  if (writeStr(f, buf) < 0) {
    return -1;
  }
  
  return 0;
}

/**
 * Writes an srec file header.
 */
int srecWriteHeader(int f) {
  
  // Reset number of data records written.
  numDataRecordsWritten = 0;
  
  // Write header record.
  if (srecWriteRecord(f, '0', 0, (const unsigned char*)"rvex dump", 10) < 0) {
    return -1;
  }
  
  return 0;
}

/**
 * Writes the given buffer, starting at the given address, to an srec output
 * file.
 */
int srecWrite(int f, unsigned char *buffer, int count, uint32_t address) {
  
  // Don't write more than 16 bytes at once (that's the amount of bytes most
  // srec outputters tend to use).
  if (count > 16) {
    count = 16;
  }
  
  // Write data record.
  if (srecWriteRecord(f, '1', address, buffer, count) < 0) {
    return -1;
  }
  
  // Increment record count.
  numDataRecordsWritten++;
  
  // Return number of bytes written.
  return count;
}

/**
 * Writes an srec file footer.
 */
int srecWriteFooter(int f) {
  
  // Write record count record.
  if (srecWriteRecord(f, '5', numDataRecordsWritten, 0, 0) < 0) {
    return -1;
  }
  
  // Write termination record.
  if (srecWriteRecord(f, '7', 0, 0, 0) < 0) {
    return -1;
  }
  
  return 0;
}

