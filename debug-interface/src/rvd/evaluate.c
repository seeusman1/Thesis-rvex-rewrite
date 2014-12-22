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

#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>

#include "evaluate.h"

//-----------------------------------------------------------------------------
// Expression scanning
//-----------------------------------------------------------------------------

/**
 * This is set to an error name when an error occurs within one of the scan*()
 * methods.
 */
#define SCAN_ERROR_LEN 255
static char scanError[SCAN_ERROR_LEN+1];

/**
 * Defines an access size.
 */
typedef enum {
  AS_UNDEFINED,
  AS_WORD,
  AS_HALF,
  AS_BYTE
} accessSize_t;

/**
 * Defines a value and associated access size.
 */
typedef struct {
  
  /**
   * Value.
   */
  unsigned long value;
  
  /**
   * Access size.
   */
  accessSize_t size;
  
} value_t;

/**
 * Moves *str forward until **ptr points to a non-whitespace character.
 */
static void scanWhitespace(const char **str) {
  while (isspace(**str)) {
    (*str)++;
  }
}

/**
 * Scans an integer literal. Format may be one of the following:
 *   <decimal>
 *   0<octal>
 *   0x<hex>
 *   0b<binary>
 * Furthermore, it may be optionally suffixed by "w", "h" or "hh" to indicate
 * the access size, or prefixed with - to indicate a negative number. Returns
 * 1 if successful, in which case value will contain the scanned literal and
 * *str will be moved to the next token. If the next token could not be parsed
 * as an integer literal, 0 is returned and *str and value are unaffected.
 */
static int scanLiteral(const char **str, value_t *value) {
  
  const char *ptr = *str;
  int radix = 10;
  value_t v = {0, AS_UNDEFINED};
  
  // We should be seeing a digit now; if not, this is not an integer literal.
  if (!isdigit(*ptr)) {
    return 0;
  }
  
  // Check for radix specifiers.
  if (*ptr == '0') {
    radix = 8;
    ptr++;
    if (*ptr == 'x') {
      radix = 16;
      ptr++;
    } else if (*ptr == 'b') {
      radix = 2;
      ptr++;
    }
  }
  
  // Scan the number.
  while (isxdigit(*ptr)) {
    char c = tolower(*ptr++);
    int digit;
    if ((c >= '0') && (c <= '9')) {
      digit = c - '0';
    } else if ((c >= 'a') && (c <= 'f')) {
      digit = (c - 'a') + 10;
    }
    if (digit >= radix) {
      return 0;
    }
    v.value *= radix;
    v.value += digit;
  }
  
  // Scan the access size specifier.
  v.size = AS_UNDEFINED;
  if (*ptr == 'w') {
    v.size = AS_WORD;
    ptr++;
  } else if (*ptr == 'h') {
    v.size = AS_HALF;
    ptr++;
    if (*ptr == 'h') {
      v.size = AS_BYTE;
      ptr++;
    }
  }
  
  // This should be the end of the token.
  if (isalpha(*ptr) || isdigit(*ptr) || (*ptr == '_')) {
    return 0;
  }
  
  // Successfully scanned the literal.
  *str = ptr;
  *value = v;
  scanWhitespace(str);
  return 1;
  
}

/**
 * Scans a definition name. Returns 1 if successful, in which case *name will
 * contain the scanned definition name and *str will be moved to the next
 * token. *name should be freed by the caller. If the next token could not be
 * parsed as a definition, 0 is returned, *str is unaffected, and *name is not
 * allocated. If 1 is returned but *name is null, malloc failed.
 */
static int scanDefinition(const char **str, char **name) {
  
  const char *start = *str;
  const char *ptr = *str;
  int count = 0;
  
  // Try to scan an identifier.
  while (isalpha(*ptr) || isdigit(*ptr) || (*ptr == '_')) {
    count++;
    ptr++;
  }
  if (!count) {
    return 0;
  }
  
  // Successfully scanned the identifier.
  *str = ptr;
  scanWhitespace(str);
  
  // Allocate a copy of the identifier to return through name.
  *name = (char*)malloc(count + 1);
  if (*name) {
    strncpy(*name, start, count);
    (*name)[count] = 0;
  }
  return 1;
  
}

// Forward declaration to scanExpression for recursive calls.
static int scanExpression(const char **str, char **name, int depth);

/**
 * Scans and evaluates an operand. Returns 0 on failure, in which ase *str and
 * value are unaffected, and scanError is set. Whenever a definition is
 * resolved, depth is decremented in subsequent calls. When depth is zero,
 * definition resolution will result in an error. This prevents hangs on
 * circular definitions.
 * 
 * EBNF:
 *   operand = "-" operand
 *   operand = "~" operand
 *   operand = literal
 *   operand = definition
 *   operand = "(" expression ")"
 */
static int scanOperand(const char **str, value_t *value, int depth) {
  
}

/**
 * Scans and evaluates an expression. Returns 0 on failure, in which ase *str
 * and value are unaffected, and scanError is set.
 * 
 * Note that there is no operator precedence and all operators are right
 * associative; spam brackets!
 * 
 * EBNF:
 *   expression = operand "+" expression
 *   expression = operand "-" expression
 *   expression = operand "<<" expression
 *   expression = operand ">>" expression
 *   expression = operand "&" expression
 *   expression = operand "|" expression
 *   expression = operand "^" expression
 *   expression = operand
 */
static int scanExpression(const char **str, char **name, int depth) {
}


