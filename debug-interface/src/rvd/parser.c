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
#include <ctype.h>
#include <string.h>

#include "parser.h"
#include "definitions.h"
#include "rvsrvInterface.h"

/**
 * This is set to an error name when an error occurs within one of the scan*()
 * methods.
 */
#define SCAN_ERROR_LEN 1023
static char scanError[SCAN_ERROR_LEN+1];
static const char *scanErrorPos = 0;

/**
 * Defines an operator.
 */
typedef enum {
  OP_ADD, // +
  OP_SUB, // -
  OP_MUL, // *
  OP_DIV, // /
  OP_MOD, // %
  OP_SHL, // <<
  OP_SHR, // >>
  OP_AND, // &
  OP_OR,  // |
  OP_XOR, // ^
  OP_SEP  // ;
} operator_t;

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
 * Scans an identifier name. Returns 1 if successful, in which case *name will
 * contain the scanned identifier and *str will be moved to the next token.
 * *name should be freed by the caller. If the next token could not be parsed
 * as an identifier, 0 is returned, *str is unaffected, and *name is not
 * allocated. If 1 is returned but *name is null, malloc failed.
 */
static int scanIdentifier(const char **str, char **name) {
  
  const char *start = *str;
  const char *ptr = *str;
  int count = 0;
  
  // The first character of an identifier may not be a digit.
  if (isdigit(*ptr)) {
    return 0;
  }
  
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

/**
 * Scans an operator. Returns 1 if successful, in which case *op will be set
 * to the scanned operator and *str will be moved to the next token. If the
 * next token could not be parsed as an operator, 0 is returned, and *str and
 * *op are unaffected.
 */
static int scanOperator(const char **str, operator_t *op) {
  
  const char *ptr = *str;
  operator_t o;
  int retval;
  
  // Determine which operator to scan.
  switch (*ptr++) {
    case '+': o = OP_ADD; break;
    case '-': o = OP_SUB; break;
    case '*': o = OP_MUL; break;
    case '/': o = OP_DIV; break;
    case '%': o = OP_MOD; break;
    case '<': o = OP_SHL; break;
    case '>': o = OP_SHR; break;
    case '&': o = OP_AND; break;
    case '|': o = OP_OR;  break;
    case '^': o = OP_XOR; break;
    case ';': o = OP_SEP; break;
    default : return 0;
  }
  
  // In the case of SHL and SHR, scan the second character.
  if (o == OP_SHL) {
    if ((*ptr++) != '<') {
      return 0;
    }
  } else if (o == OP_SHR) {
    if ((*ptr++) != '>') {
      return 0;
    }
  }
  
  // Successfully scanned the operator.
  *str = ptr;
  *op = o;
  scanWhitespace(str);
  return 1;
  
}

// Forward declaration to scanExpression for recursive calls.
static int scanExpression(const char **str, value_t *value, int depth);

/**
 * Scans and evaluates an operand. Returns 0 on failure, in which ase *str and
 * value are unaffected, and scanError is set. Whenever a definition is
 * resolved, depth is decremented in subsequent calls. When depth is zero,
 * definition resolution will result in an error. This prevents hangs on
 * circular definitions. Returns -1 if a fatal error occured.
 * 
 * Depth specifies how many definition expansions are still allowed (to avoid
 * hanging on loops). When this is set to -1, definitions are silently not
 * extended at all, useful for syntax checking without evaluation.
 */
static int scanOperand(const char **str, value_t *value, int depth) {
  
  const char *ptr = *str;
  value_t v = {0, AS_UNDEFINED};
  int retval;
  
  if (*ptr == '-') {
    
    // Scan and execute negate operator.
    ptr++;
    scanWhitespace(&ptr);
    if ((retval = scanOperand(&ptr, &v, depth)) < 1) {
      return retval;
    }
    v.value = -v.value;
    
  } else if (*ptr == '~') {
    
    // Scan and execute not operator.
    ptr++;
    scanWhitespace(&ptr);
    if ((retval = scanOperand(&ptr, &v, depth)) < 1) {
      return retval;
    }
    v.value = ~v.value;
    
  } else if (*ptr == '(') {
    
    // Scan open bracket.
    ptr++;
    scanWhitespace(&ptr);
    
    // Scan expression.
    if ((retval = scanExpression(&ptr, &v, depth)) < 1) {
      return retval;
    }
    
    // Scan close bracket.
    if (*ptr != ')') {
      sprintf(scanError, "expected ')'");
      scanErrorPos = ptr;
      return 0;
    }
    ptr++;
    scanWhitespace(&ptr);
    
  } else if (isdigit(*ptr)) {
    
    // Scan integer literal.
    switch (scanLiteral(&ptr, &v)) {
      case 0:
        sprintf(scanError, "invalid integer literal");
        scanErrorPos = ptr;
        return 0;
        
      case 1:
        break;
        
      default:
        return -1;
      
    }
    
  } else {
    const char *defStart = ptr;
    char *name;
    
    // Scan identifier.
    switch (scanIdentifier(&ptr, &name)) {
      case 0:
        sprintf(scanError, "operand expected");
        scanErrorPos = ptr;
        return 0;
        
      case 1:
        break;
        
      default:
        return -1;
      
    }
    
    // Make sure name was properly allocated.
    if (!name) {
      perror("Failed to allocate memory while parsing");
      return -1;
    }
    
    // If the next characters is an open parenthesis, we're dealing with a
    // function. Otherwise, we're dealing with a definition.
    if (*ptr == '(') {
      ptr++;
      scanWhitespace(&ptr);
      
      if ((!strcmp(name, "read")) | (!strcmp(name, "readByte")) | (!strcmp(name, "readHalf")) | (!strcmp(name, "readWord"))) {
        int size;
        unsigned long readVal;
        
        // Scan the address.
        if ((retval = scanExpression(&ptr, &v, depth)) < 1) {
          free(name);
          return retval;
        }
        
        // Scan the close parenthesis.
        if (*ptr != ')') {
          sprintf(scanError, "expected ')'");
          scanErrorPos = ptr;
          free(name);
          return 0;
        }
        ptr++;
        scanWhitespace(&ptr);
        
        // Don't do anything when depth is -1. This is used to just check for
        // syntax errors.
        if (depth != -1) {
          
          // Determine the access size.
          switch (name[4]) {
            case 'B': size = 1; v.size = AS_BYTE; break;
            case 'H': size = 2; v.size = AS_HALF; break;
            default : size = 4; v.size = AS_WORD; break;
          }
          free(name);
          name = 0;
          
          // Perform the access.
          switch (rvsrv_readSingle(v.value, &readVal, size)) {
            case 0:
              sprintf(scanError, "failed to read from address 0x%08X; bus fault 0x%08X", v.value, readVal);
              scanErrorPos = ptr;
              return 0;
              
            case 1:
              break;
              
            default:
              return -1;
              
          }
          
          // Return the read value.
          v.value = readVal;
          
        }
        
      } else if ((!strcmp(name, "write")) || (!strcmp(name, "writeByte")) || (!strcmp(name, "writeHalf")) || (!strcmp(name, "writeWord"))) {
        int size;
        unsigned long fault;
        value_t address;
        
        free(name);
        name = 0;
        
        // Scan the address.
        if ((retval = scanExpression(&ptr, &address, depth)) < 1) {
          return retval;
        }
        
        // Scan the comma.
        if (*ptr != ',') {
          sprintf(scanError, "expected ','");
          scanErrorPos = ptr;
          return 0;
        }
        ptr++;
        scanWhitespace(&ptr);
        
        // Scan the value to write.
        if ((retval = scanExpression(&ptr, &v, depth)) < 1) {
          return retval;
        }
        
        // Scan the close parenthesis.
        if (*ptr != ')') {
          sprintf(scanError, "expected ')'");
          scanErrorPos = ptr;
          return 0;
        }
        ptr++;
        scanWhitespace(&ptr);
        
        // Don't do anything when depth is -1. This is used to just check for
        // syntax errors.
        if (depth != -1) {
          
          // Determine the access size.
          switch (name[5]) {
            case 'B': v.size = AS_BYTE; break;
            case 'H': v.size = AS_HALF; break;
            case 'W': v.size = AS_WORD; break;
          }
          switch (v.size) {
            case AS_BYTE: size = 1; break;
            case AS_HALF: size = 2; break;
            default:      size = 4; break;
          }
          
          // Perform the access.
          switch (rvsrv_writeSingle(address.value, v.value, size, &fault)) {
            case 0:
              sprintf(scanError, "failed to write to address 0x%08X; bus fault 0x%08X", address.value, fault);
              scanErrorPos = ptr;
              return 0;
              
            case 1:
              break;
              
            default:
              return -1;
              
          }
          
        }
        
      } else {
        
        // Unknown function.
        sprintf(scanError, "unknown function \"%s\"", name);
        scanErrorPos = defStart;
        free(name);
        return 0;
        
      }
      
    } else {
      
      // Don't expand when depth is -1. This is used to just check for syntax
      // errors.
      if (depth != -1) {
        
        const char *expanded;
        
        // Expand the definition.
        expanded = defs_expand(name);
        if (!expanded) {
          sprintf(scanError, "\"%s\" is not defined", name);
          scanErrorPos = defStart;
          free(name);
          return 0;
        }
        
        // Break if we've expanded too often (which probably indicates a loop).
        if (!depth) {
          sprintf(scanError, "too many recursive expansions, was about to expand \"%s\"", name);
          scanErrorPos = defStart;
          free(name);
          return 0;
        }
        
        // Evaluate the expansion as an expression.
        if ((retval = scanExpression(&expanded, &v, depth-1)) < 1) {
          
          // Override the error position to where we were when we started scanning
          // our definition, to get the position right in the final formatted error
          // message.
          scanErrorPos = defStart;
          
          free(name);
          return retval;
        }
      
      }
      
    }
    
    free(name);
  }
  
  // Everything's OK, update the inout variables.
  *str = ptr;
  *value = v;
  return 1;
  
}

/**
 * Priority encodes between two given access sizes:
 * AS_WORD > AS_HALF > AS_BYTE > AS_UNDEFINED
 */
static accessSize_t mergeSize(accessSize_t a, accessSize_t b) {
  if (a == AS_WORD) return AS_WORD;
  if (b == AS_WORD) return AS_WORD;
  if (a == AS_HALF) return AS_HALF;
  if (b == AS_HALF) return AS_HALF;
  if (a == AS_BYTE) return AS_BYTE;
  if (b == AS_BYTE) return AS_BYTE;
  return AS_UNDEFINED;
}

/**
 * Scans and evaluates an expression. Returns 0 on failure, in which ase *str
 * and *value are unaffected, and scanError is set. Returns -1 if a fatal error
 * occured.
 * 
 * Note that there is no operator precedence and all operators are right
 * associative; spam brackets!
 * 
 * Depth specifies how many definition expansions are still allowed (to avoid
 * hanging on loops). When this is set to -1, definitions are silently not
 * extended at all, useful for syntax checking without evaluation.
 */
static int scanExpression(const char **str, value_t *value, int depth) {
  
  const char *ptr = *str;
  value_t v = {0, AS_UNDEFINED};
  operator_t op;
  int retval;
  
  // Scan the first operand.
  if ((retval = scanOperand(&ptr, &v, depth)) < 1) {
    return retval;
  }
  
  // Scan the operator. This is allowed to fail, because the operator is
  // optional.
  if ((retval = scanOperator(&ptr, &op)) < 0) {
    return retval;
  }
  
  // If scanning the operator was successful, scan the second operand, which
  // may be an expression.
  if (retval) {
    value_t v2 = {0, AS_UNDEFINED};
    
    if ((retval = scanExpression(&ptr, &v2, depth)) < 1) {
      return retval;
    }
    
    // Execute the operator.
    switch (op) {
      case OP_ADD: v.value +=  v2.value; v.size = mergeSize(v.size, v2.size); break;
      case OP_SUB: v.value -=  v2.value; v.size = mergeSize(v.size, v2.size); break;
      case OP_MUL: v.value *=  v2.value; v.size = mergeSize(v.size, v2.size); break;
      case OP_DIV: v.value /=  v2.value; v.size = mergeSize(v.size, v2.size); break;
      case OP_MOD: v.value %=  v2.value; v.size = mergeSize(v.size, v2.size); break;
      case OP_SHL: v.value <<= v2.value; v.size = mergeSize(v.size, v2.size); break;
      case OP_SHR: v.value >>= v2.value; v.size = mergeSize(v.size, v2.size); break;
      case OP_AND: v.value &=  v2.value; v.size = mergeSize(v.size, v2.size); break;
      case OP_OR:  v.value |=  v2.value; v.size = mergeSize(v.size, v2.size); break;
      case OP_XOR: v.value ^=  v2.value; v.size = mergeSize(v.size, v2.size); break;
      case OP_SEP: v.value =   v2.value; v.size =                   v2.size ; break;
    }
    
  }
  
  // Everything's OK, update the inout variables.
  *str = ptr;
  *value = v;
  return 1;
  
}

/**
 * Scans a context mask. Returns 0 on failure, in which case *str and *mask are
 * unaffected, and scanError is set. Returns -1 is a fatal error occured.
 */
static int scanContextMask(const char **str, contextMask_t *mask) {
  
  const char *ptr = *str;
  value_t v1, v2;
  
  scanWhitespace(&ptr);
  
  if (!str || !mask) {
    return -1;
  }
  
  if (!strncmp(ptr, "all", 3)) {
    
    // Scan the "all" token.
    ptr += 3;
    scanWhitespace(&ptr);
    if (isalpha(*ptr) || isdigit(*ptr) || (*ptr == '_')) {
      sprintf(scanError, "unexpected token");
      scanErrorPos = ptr;
      return 0;
    }
    *mask = 0xFFFFFFFF;
    *str = ptr;
    return 1;
    
  }
  
  // Scan the first (or only) literal.
  switch (scanLiteral(&ptr, &v1)) {
    case 0:
      sprintf(scanError, "expected integer literal or \"all\"");
      scanErrorPos = ptr;
      return 0;
      
    case 1:
      break;
      
    default:
      return -1;
    
  }
  
  // Make sure that v1 is within allowable ranges.
  if ((v1.value < 0) | (v1.value > 31)) {
    sprintf(scanError, "context %d out of range", v1.value);
    scanErrorPos = ptr;
    return 0;
  }
  
  // We should be seeing .. or the end of the string now.
  if (!strncmp(ptr, "..", 2)) {
    ptr += 2;
    scanWhitespace(&ptr);
    
    // Scan the second literal.
    switch (scanLiteral(&ptr, &v2)) {
      case 0:
        sprintf(scanError, "expected integer literal");
        scanErrorPos = ptr;
        return 0;
        
      case 1:
        break;
        
      default:
        return -1;
      
    }
    
    // Make sure that v2 is within allowable ranges.
    if ((v2.value < 0) | (v2.value > 31)) {
      sprintf(scanError, "context %d out of range", v2.value);
      scanErrorPos = ptr;
      return 0;
    }
    
    // Choose v1 and v2 such that v2 is greater than v1.
    if (v2.value < v1.value) {
      unsigned long s = v1.value;
      v1.value = v2.value;
      v2.value = s;
    }
    
  } else {
    
    // Specifying a single context.
    v2 = v1;
    
  }
  
  // Determine the mask with some bit magic.
  *mask = (1 << (v2.value + 1)) - (1 << v1.value);
  *str = ptr;
  return 1;
  
}

/**
 * Syntax checks a definition and, if correct, registers it. Returns 1 if the
 * expansion is syntax correct and the definition was registered, 0 if there
 * was a syntax error or -1 when a fatal error occured.
 */
static int registerDefinition(contextMask_t mask, const char *def, char *expansion, int expLen) {
  char c;
  value_t dummyValue;
  const char *ptr = expansion;
  int retval;
  
  // Replace the end of the expansion with null temporarily.
  c = expansion[expLen];
  expansion[expLen] = 0;
  
  // Syntax-check the expansion. Use -1 for depth so the scan routines won't
  // try to expand definitions; we're just syntax checking.
  retval = scanExpression(&ptr, &dummyValue, -1);
  if (retval < 1) {
    expansion[expLen] = c;
    return retval;
  }
  
  // Register the expansion.
  if (defs_register(mask, def, expansion) < 0) {
    expansion[expLen] = c;
    return -1;
  }
  
  // Success.
  expansion[expLen] = c;
  return 1;
  
}

/**
 * Scans and registers a definition. The definition expension is terminated by
 * null or a '.' only. Returns 0 on failure, in which case *str is unaffected
 * and scanError is set. Returns -1 is a fatal error occured. Returns 2 if
 * scanning was successful, but there was a parse error in the expansion.
 */
static int scanDefinition(char **str) {
  
  char *ptr = *str;
  char *definition = 0;
  char *expansion = 0;
  int expLen;
  int retval;
  contextMask_t mask;
  
  scanWhitespace((const char **)&ptr);
  
  // Scan the context mask.
  retval = scanContextMask((const char **)&ptr, &mask);
  if (retval != 1) {
    return retval;
  }
  
  // Expect and scan colon.
  if (*ptr != ':') {
    sprintf(scanError, "expected ':'");
    scanErrorPos = ptr;
    return 0;
  }
  ptr++;
  scanWhitespace((const char **)&ptr);
  
  // Scan the definition identifier.
  switch (scanIdentifier((const char **)&ptr, &definition)) {
    case 0:
      sprintf(scanError, "identifier expected");
      scanErrorPos = ptr;
      return 0;
      
    case 1:
      break;
      
    default:
      return -1;
    
  }
  
  // Make sure definition was properly allocated.
  if (!definition) {
    perror("Failed to allocate memory while parsing");
    return -1;
  }
  
  // Expect and scan colon.
  if (*ptr != ':') {
    sprintf(scanError, "expected ':'");
    scanErrorPos = ptr;
    free(definition);
    return 0;
  }
  ptr++;
  scanWhitespace((const char **)&ptr);
  
  // Scan until we encounter a '.' or null.
  expansion = ptr;
  expLen = 0;
  while ((*ptr) && (*ptr != '.')) {
    expLen++;
    ptr++;
  }
  
  // Register the expansion.
  retval = registerDefinition(mask, definition, expansion, expLen);
  free(definition);
  if (retval < 0) {
    return retval;
  } else if (retval == 0) {
    *str = ptr;
    return 2;
  }
  
  // Success.
  *str = ptr;
  return 1;
}

/**
 * Dumps the parse error specified by scanError and scanErrorPos for the given
 * command to stderr.
 */
static void printParseError(const char *str) {
  char *beforeScanPos;
  int scanPos;
  
  scanPos = scanErrorPos - str;
  
  // Make a copy of the correct part of the failing expression, so we can null
  // terminate it and print it easily.
  beforeScanPos = (char *)malloc(scanPos + 1);
  if (!beforeScanPos) {
    
    // Fallback if malloc fails...
    fprintf(stderr, scanError);
    return;
    
  }
  memcpy(beforeScanPos, str, scanPos);
  beforeScanPos[scanPos] = 0;
  fprintf(stderr, "%s at \033[1m|\033[0m in: \"%s\033[1m|\033[31m%s\033[0m\".\n", scanError, beforeScanPos, scanErrorPos);
  free(beforeScanPos);
  
}

//-----------------------------------------------------------------------------

/**
 * Evaluates an expression. Returns 1 if successful, 0 on failure, or -1 when
 * a fatal error occurs. An error message is printed upon failure if
 * errorPrefix is non-null.
 */
int evaluate(const char *str, value_t *value, const char *errorPrefix) {
  
  const char *ptr = str;
  
  if (!str || !value) {
    return -1;
  }
  
  // Set a default error so we at least don't segfault due to scanErrorPos
  // not being in str or scanError not being defined.
  scanErrorPos = str;
  sprintf(scanError, "unknown error");
  
  scanWhitespace(&ptr);
  switch (scanExpression(&ptr, value, 256)) {
    case 0:
      
      // Don't print errors when errorPrefix is null.
      if (errorPrefix) {
        
        fprintf(stderr, "Evaluation error%s: ", errorPrefix);
        printParseError(str);
        
      }
      return 0;
      
    case 1:
      if (*ptr) {
        scanErrorPos = ptr;
        sprintf(scanError, "unexpected token");
        
        // Don't print errors when errorPrefix is null.
        if (errorPrefix) {
          
          fprintf(stderr, "Evaluation error%s: ", errorPrefix);
          printParseError(str);
          
        }
        return 0;
      } else {
        return 1;
      }
      
    default:
      return -1;
    
  }
  
}

/**
 * Parses a context mask.
 */
int parseMask(const char *str, contextMask_t *mask, const char *errorPrefix) {
  
  const char *ptr = str;
  
  if (!str || !mask) {
    return -1;
  }
  
  // Set a default error so we at least don't segfault due to scanErrorPos
  // not being in str or scanError not being defined.
  scanErrorPos = str;
  sprintf(scanError, "unknown error");
  
  scanWhitespace(&ptr);
  switch (scanContextMask(&ptr, mask)) {
    case 0:
      
      // Don't print errors when errorPrefix is null.
      if (errorPrefix) {
        
        fprintf(stderr, "Parse error%s: ", errorPrefix);
        printParseError(str);
        
      }
      return 0;
      
    case 1:
      if (*ptr) {
        scanErrorPos = ptr;
        sprintf(scanError, "unexpected token");
        
        // Don't print errors when errorPrefix is null.
        if (errorPrefix) {
          
          fprintf(stderr, "Parse error%s: ", errorPrefix);
          printParseError(str);
          
        }
        return 0;
      } else {
        return 1;
      }
      
    default:
      return -1;
    
  }
  
}

/**
 * Parses and registers the given definition list. Anything between # and \n is
 * interpreted as comment.
 * 
 * EBNF:
 *   start       = { def }
 *   def         = mask, ":", definition, ":", expansion, "."
 *   mask        = ( C integer literal, [ "..", C integer literal ] )
 *               | "all"
 */
int parseDefs(char *str, const char *errorPrefix) {
  
  char *ptr = str;
  const char *lptr;
  int lineNumber = 1;
  int column = 1;
  int inComment = 0;
  int retval;
  int ok = 1;
  
  if (!str) {
    return -1;
  }
  
  // Strip comments.
  ptr = str;
  while (*ptr) {
    switch (*ptr) {
      case '\n': inComment = 0; break;
      case '#' : inComment = 1; break;
    }
    if (inComment) {
      *ptr = ' ';
    }
    *ptr++;
  }
  
  // Scan all the definitions.
  ptr = str;
  lptr = str;
  scanWhitespace((const char **)&ptr);
  while (*ptr) {
    
    // Scan the definition on this line.
    retval = scanDefinition(&ptr);
    if (retval < 0) return -1;
    if (retval != 1) {
      
      // Don't print errors when errorPrefix is null.
      if (errorPrefix) {
        
        // Figure out what line and column we're at for the error message.
        while (lptr != scanErrorPos) {
          if (*lptr == '\n') {
            lineNumber++;
            column = 1;
          } else {
            column++;
          }
          lptr++;
        }
        fprintf(stderr, "Parse error%s on line %d, col %d: %s.\n", errorPrefix, lineNumber, column, scanError);
        
      }
      
      ok = 0;
      
      if (retval == 0) {
        return 0;
      }
    }
    
    if (*ptr == '.') {
      ptr++;
      scanWhitespace((const char **)&ptr);
    } else {
      break;
    }
    
  }
  
  return ok;
}

