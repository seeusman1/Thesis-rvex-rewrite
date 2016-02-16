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
#include <string.h>
#include <ctype.h>

#include "disasParse.h"
#include "readFile.h"


typedef struct {
  
  // Pointers to subtrees or leaves.
  void *c[1024];
  
} tree_t;

typedef struct {
  
  // Disassembly string.
  char *disas;
  
  // Comma separated list of symbols.
  char *symbols;
  
} leaf_t;


/**
 * Root nodes for the disassembly information tree.
 */
static tree_t root;

/**
 * Returns a pointer to the node at the given PC. If create is zero, null is
 * returned if no information is known about the given PC; if it is nonzero,
 * the node is created. If create is nonzero and an allocation error occurs,
 * null is returned anyway and an error is printed to stderr.
 */
static leaf_t *getNode(uint32_t pc, int create) {
  
  int level;
  tree_t *t = &root;
  
  for (level = 0; level < 3; level++) {
    
    // Determine the requested index within the current level of the tree.
    int index = ((pc >> 22) & 0x3FF);
    
    // See if the node exists.
    if (!(t->c[index])) {
      
      // Node does not exist.
      if (!create) {
        return 0;
      }
      
      // Try to create the node.
      if (level == 2) {
        
        // Create a leaf node.
        t->c[index] = calloc(sizeof(leaf_t), 1);
        
      } else {
        
        // Create a subtree node.
        t->c[index] = calloc(sizeof(tree_t), 1);
        
      }
      
      // Make sure it was created.
      if (!(t->c[index])) {
        perror("Failed to register disassembly information");
        return 0;
      }
      
    }
    
    // Store the pointer to the next subtree or leaf node.
    t = (tree_t*)t->c[index];
    
    // Shift the program counter to make the next index valid.
    pc <<= 10;
    
  }
  
  // Return the node.
  return (leaf_t*)t;
  
}

/**
 * Returns nonzero if the length of the given null terminated string is at
 * least the specified length.
 */
int strlenge(const char *str, int len) {
  while (len--) {
    if (!(*str++)) {
      return 0;
    }
  }
  return 1;
}

/**
 * Parses a line in a disassembly file.
 */
static int parseLine(const char *line, unsigned long int offset) {
  
  int firstDigitScanned;
  int i;
  
  // Ignore lines shorter than 9 characters.
  if (!strlenge(line, 9)) {
    return 0;
  }
  
  // See if the first 8 characters represent a valid hex number.
  firstDigitScanned = 0;
  for (i = 0; i < 8; i++) {
    if ((line[i] == ' ') && !firstDigitScanned) {
      continue;
    }
    if (isxdigit(line[i])) {
      firstDigitScanned = 1;
      continue;
    }
    return 0;
  }
  
  // If the ninth character is a colon, this is a line of disassembly. The
  // hexdump of the instruction starts at index 10, the disassembled
  // instruction starts at 23.
  if (line[8] == ':') {
    
    uint32_t pc;
    leaf_t *l;
    
    // Scan the value of the program counter.
    sscanf(line, "%x", &pc);
    
    // Get the leaf node at this PC.
    l = getNode(pc + offset, 1);
    if (!l) {
      return -1;
    }
    
    // Copy the disassembly string into the leaf.
    if (l->disas) {
      free((void*)l->disas);
    }
    l->disas = (char*)malloc(strlen(line + 10) + 1);
    if (!l->disas) {
      return -1;
    }
    strcpy(l->disas, line + 10);
    
    return 0;
  }
  
  // If the ninth character is a space and the last character is a colon, this
  // is a symbol.
  if (line[8] == ' ') {
    int len = strlen(line);
    if (line[len-1] == ':') {
      
      uint32_t pc;
      leaf_t *l;
      const char *symbol;
      
      // Convert len to the length of the symbol itself. The symbol starts at
      // index 9 and ends one character before the end of the line.
      len -= 10;
      symbol = line + 9;
      
      // Scan the value of the program counter.
      sscanf(line, "%x", &pc);
      
      // Get the leaf node at this PC.
      l = getNode(pc + offset, 1);
      if (!l) {
        return -1;
      }
      
      // Copy the symbol into the leaf.
      if (l->symbols) {
        
        // There are multiple symbols for this PC. Append the new symbol to the
        // list.
        int destLen;
        char *dest;
        destLen = strlen(l->symbols);
        l->symbols = realloc(l->symbols, destLen + 2 + len + 1);
        if (!l->symbols) {
          return -1;
        }
        dest = l->symbols + destLen;
        dest[0] = ',';
        dest[1] = ' ';
        memcpy(dest+2, symbol, len);
        dest[2+len] = 0;
        
      } else {
        
        // This is the first symbol.
        l->symbols = (char*)malloc(len + 1);
        if (!l->symbols) {
          return -1;
        }
        memcpy(l->symbols, symbol, len);
        l->symbols[len] = 0;
        
      }
      
      return 0;
      
    }
  }
  
  return 0;
}

/**
 * This will attempt to load the given disassembly file (objdump -d) into
 * memory and parse it. Prints an error to stderr and returns -1 on failure or
 * returns 0 on success.
 */
int disasLoad(const char *filename, unsigned long int offset) {
  
  char *buf, *ptr;
  
  // Load the file into memory.
  buf = readFile(filename, 0, 0);
  if (!buf) {
    return -1;
  }
  
  // Read the file line by line.
  ptr = strtok(buf, "\n\r");
  while (ptr) {
    if (parseLine(ptr, offset) < 0) {
      free(buf);
      return -1;
    }
    ptr = strtok(0, "\n\r");
  }
  
  // Done.
  free(buf);
  
  return 0;
  
}

/**
 * Returns pointers to disassembly and symbol information for the given program
 * counter. *symbols will be set to null if no symbols are associated with this
 * PC, disas will always be set to a valid string.
 */
void disasGet(uint32_t pc, const char **disas, const char **symbols) {
  
  leaf_t *l;
  
  *disas = "unknown";
  *symbols = 0;
  
  l = getNode(pc, 0);
  if (!l) {
    return;
  }
  if (l->disas) {
    *disas = l->disas;
  }
  if (l->symbols) {
    *symbols = l->symbols;
  }
  
}

/**
 * Frees up memory structures used by the disassembly parsing system.
 */
void disasFree(void) {
  
  int i, j, k;
  
  for (i = 0; i < 1024; i++) {
    tree_t *ti = (tree_t*)(root.c[i]);
    if (ti) {
      for (j = 0; j < 1024; j++) {
        tree_t *tj = (tree_t*)(ti->c[j]);
        if (tj) {
          for (k = 0; k < 1024; k++) {
            leaf_t *l = (leaf_t*)(tj->c[k]);
            if (l) {
              if (l->disas) {
                free((void*)l->disas);
              }
              if (l->symbols) {
                free((void*)l->symbols);
              }
              free(l);
            }
          }
          free(tj);
        }
      }
      free(ti);
      root.c[i] = 0;
    }
  }
  
}

