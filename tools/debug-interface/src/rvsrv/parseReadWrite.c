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

#include "parseReadWrite.h"

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

/**
 * Returns 1 only if command[startPos-..] equals match. If it matches, pos will
 * be incremented by the size of match.
 */
static int matchAt(const unsigned char *str, const unsigned char *match, int *pos) {
  int len = 0;
  str += *pos;
  while (*match) {
    if (*match++ != *str++) {
      return 0;
    }
    len++;
  }
  *pos += len;
  return 1;
}

/**
 * Converts a hexadecimal ASCII character to its value, or returns -1 if the
 * character is not hexadecimal.
 */
static int charVal(unsigned char c) {
  if ((c >= '0') && (c <= '9')) return c - '0';
  if ((c >= 'A') && (c <= 'F')) return (c - 'A') + 10;
  if ((c >= 'a') && (c <= 'f')) return (c - 'a') + 10;
  return -1;
}

/**
 * Formats a syntax error message.
 *
 * After returning, error_str will point to a malloced string containing the
 * error message to be send to the client. Freeing this memory should be done
 * by the caller.
 *
 * Returns -1 in case of error and 1 otherwise.
 */
static int syntaxError(unsigned char *command, unsigned char **error_str) {
  static const char *start_str = "Error, ";
  static const char *end_str = ", Syntax;\n";
  size_t start_str_len = strlen(start_str);
  size_t end_str_len = strlen(end_str);
  size_t cmd_len = strchr((char*)command, 'r') - (char*)command;

  size_t len = start_str_len + cmd_len + end_str_len + 1;

  *error_str = malloc(len);
  if (!*error_str) {
    return -1;
  }

  memcpy(*error_str, start_str, start_str_len);

  memcpy(*error_str+start_str_len, command, cmd_len);

  memcpy(*error_str+start_str_len+cmd_len, end_str, end_str_len);

  (*error_str)[len] = 0;
  
  return 1;
}

/**
 * Tries to parse a Read or Write command sent by a TCP client connected to
 * the debug server. command should be a null-terminated string of one of the
 * following formats:
 * 
 *   Read,<1-8 hex chars: address>,<1-.. decimal chars: count>
 *   Write,<1-8 hex chars: address>,<1-.. decimal chars: count>,<2*count hex chars: data>
 *
 * At most 4096 bytes may be read or written at once. In case of an error one
 * of the following syntax error strings will be generated:
 *
 *   Error, Syntax, <1-.. decimal chars: character index in command>
 *   Error, InvalidBufSize
 *
 * When the message has been successfully parsed and it is a write message,
 * res->buffer contains a malloc'ed region of memory of size res->buf_size. This
 * memory should be freed by the caller.
 *
 * In case of a syntax error, syntax_error will point to a malloced string
 * containing the error message to be send to the client. Freeing this memory
 * should be done by the caller.
 *
 * Returns -1 in case of unexpected error, 0 when the message was successfully
 * parsed and 1 in case of a syntax error.
 */
int parseReadWrite(unsigned char *command, struct parse_rw_result *res,
    unsigned char **syntax_error) {
  int scanPos = 0;
  int i, j;

  // Initialize syntax_error in case we return with error code but without a
  // syntax error to transmit.
  *syntax_error = NULL;
  
  // Make sure there's a comma in here somewhere. If not, we should return a
  // syntax error instead of dying in the next test.
  if (!strchr((char *)command, ',')) {
    return syntaxError(command, syntax_error);
  }
  
  // Scan the "Read," or "Write,".
  if (matchAt(command, (const unsigned char *)"Read,", &scanPos)) {
    res->is_write = 0;
  } else if (matchAt(command, (const unsigned char *)"Write,", &scanPos)) {
    res->is_write = 1;
  } else {
    printf("handleReadWrite() was called with a command other than Read or Write.\nThis should never happen.\n");
    return -1;
  }
  
  res->address = 0;
  // Scan the address.
  for (i = 0; i < 8; i++) {
    
    // Stop if we encounter a comma.
    if (command[scanPos] == ',') {
      break;
    }
    
    // Read the next hex character.
    j = charVal(command[scanPos]);
    if (j < 0) {
      return syntaxError(command, syntax_error);
    }
    scanPos++;
    
    // Shift it into the address.
    res->address <<= 4;
    res->address |= j;
    
  }
  
  // We must see a comma here.
  if (command[scanPos] != ',') {
    return syntaxError(command, syntax_error);
  }
  scanPos++;
  
  res->buf_size = 0;
  // Scan the count.
  for (i = 0; i < 4; i++) {
    
    // Stop if we encounter a comma or null.
    if ((command[scanPos] == ',') || (command[scanPos] == 0)) {
      break;
    }
    
    // Read the next decimal character.
    j = charVal(command[scanPos]);
    if ((j < 0) || (j > 9)) {
      return syntaxError(command, syntax_error);
    }
    scanPos++;
    
    // Shift it into the address.
    res->buf_size *= 10;
    res->buf_size += j;
    
  }
  
  // Make sure the count is within range.
  if ((res->buf_size < 1) || (res->buf_size > 4096)) {
    const char *err_str;
    if (res->is_write) {
      err_str = "Error, Write, InvalidBufSize;\n";
    } else {
      err_str = "Error, Read, InvalidBufSize;\n";
    }
    size_t len = strlen(err_str);

    *syntax_error = malloc(len);
    if (!*syntax_error) {
      return -1;
    }

    memcpy(*syntax_error, err_str, len);
    return 1;
  }
  
  // We should be at the end of the string for read commands, or we should have
  // another comma for write commands.
  if (command[scanPos] != (res->is_write ? ',' : 0)) {
    return syntaxError(command, syntax_error);
  }
  scanPos++;
  
  if (!res->is_write) {
    res->buffer = NULL;
  } else {
    // If this is a write command, read the supplied data into the buffer.

    // Allocate the data buffer.
    res->buffer = (unsigned char*)malloc(res->buf_size);
    if (!res->buffer) {
      perror("parseReadWrite: Failed to allocate memory to service debug write command");
      return -1;
    }

    // Read the supplied data into the buffer.
    for (i = 0; i < res->buf_size; i++) {
      
      res->buffer[i] = 0;
      
      // Read the next hex character.
      j = charVal(command[scanPos]);
      if (j < 0) {
        free(res->buffer);
        return syntaxError(command, syntax_error);
      }
      scanPos++;
      
      res->buffer[i] = j << 4;
      
      // Read the next hex character.
      j = charVal(command[scanPos]);
      if (j < 0) {
        free(res->buffer);
        return syntaxError(command, syntax_error);
      }
      scanPos++;
      
      res->buffer[i] |= j;
      
    }
    
    // We should be at the end of the command now.
    if (command[scanPos] != 0) {
      free(res->buffer);
      return syntaxError(command, syntax_error);
    }
    scanPos++;
  }

  return 0;
}
