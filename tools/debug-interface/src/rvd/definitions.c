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
#include <stdlib.h>
#include <ctype.h>
#include <string.h>

#include "definitions.h"

/**
 * Number of bins in the hash table.
 */
#define NUM_BINS 256

/**
 * Determines the bin for a given string using the (public domain) sbdm hash
 * function.
 */
static int getBin(const unsigned char *str) {
  uint32_t hash = 0;
  int c;
  
  while ((c = *str++)) {
    hash = c + (hash << 6) + (hash << 16) - hash;
  }
  
  return hash % NUM_BINS;
}

/**
 * Hash table entry structure.
 */
typedef struct _tableEntry_t {
  
  /**
   * Context mask.
   */
  contextMask_t mask;
  
  /**
   * Name of this definition.
   */
  char *def;
  
  /**
   * Expansion for this definition.
   */
  char *expansion;
  
  /**
   * Next entry in the linked list of definitions.
   */
  struct _tableEntry_t *next;
  
} tableEntry_t;

/**
 * Hash table bins, pointing to tableEntry_t linked lists.
 */
static tableEntry_t *bins[NUM_BINS] = {0};

/**
 * The current context used to expand definitions with.
 */
static int currentContext = 0;

/**
 * Allocates a copy of the given null-terminated string. Prints an error and
 * returns null if malloc fails.
 */
char *copyString(const char *str) {
  char *newStr = 0;
  int size = strlen(str) + 1;
  newStr = (char*)malloc(size);
  if (!newStr) {
    perror("Failed to copy string");
    return 0;
  }
  memcpy(newStr, str, size);
  return newStr;
}

/**
 * Registers an expansion. Returns 1 if an existing expansion was overridden, o
 * if a new expansion was registered or -1 if a fatal error occured.
 */
int defs_register(contextMask_t mask, const char *def, const char *expansion) {
  int bin = getBin((const unsigned char *)def);
  tableEntry_t *ptr;
  
  // See if there is a perfect match for this definition somewhere already; if
  // so, overwrite it.
  ptr = bins[bin];
  while (ptr) {
    if ((ptr->mask == mask) && !strcmp(def, ptr->def)) {
      
      // Found a perfect match. Override the expansion.
      free(ptr->expansion);
      ptr->expansion = copyString(expansion);
      if (!ptr->expansion) {
        return -1;
      } else {
        return 1;
      }
      
    }
    ptr = ptr->next;
  }
  
  // Create a new expansion record.
  ptr = (tableEntry_t*)malloc(sizeof(tableEntry_t));
  if (!ptr) {
    perror("Failed to allocate memory for definition record");
    return -1;
  }
  ptr->mask = mask;
  ptr->def = copyString(def);
  if (!ptr->def) {
    free(ptr);
    return -1;
  }
  ptr->expansion = copyString(expansion);
  if (!ptr->expansion) {
    free(ptr->def);
    free(ptr);
    return -1;
  }
  
  // Insert the new record at the start of the linked list.
  ptr->next = bins[bin];
  bins[bin] = ptr;
  
  return 0;
}

/**
 * Registers an expansion locally, i.e., using the current context.
 */
int defs_registerLocal(const char *def, const char *expansion) {
  return defs_register(1 << currentContext, def, expansion);
}

/**
 * Expands the given definition, or returns null if the definition is not
 * known.
 */
const char *defs_expand(const char *def) {
  int bin = getBin((const unsigned char *)def);
  tableEntry_t *ptr;
  
  ptr = bins[bin];
  while (ptr) {
    if ((ptr->mask & (1 << currentContext)) && !strcmp(def, ptr->def)) {
      
      // Found a match.
      return ptr->expansion;
      
    }
    ptr = ptr->next;
  }
  
  // No match found.
  return 0;
  
}

/**
 * Sets the context used to expand definitions.
 */
void defs_setContext(int context) {
  static char curContextDef[8];
  sprintf(curContextDef, "%d", context);
  defs_register((1 << context), "_CUR_CONTEXT", curContextDef);
  
  currentContext = context;
}

/**
 * Frees all dynamically allocated memory for the definition hashmap.
 */
void defs_free(void) {
  int bin;
  tableEntry_t *entry;
  
  for (bin = 0; bin < NUM_BINS; bin++) {
    entry = bins[bin];
    bins[bin] = 0;
    
    while (entry) {
      tableEntry_t *next;
      
      // Free the strings in the entry.
      free(entry->def);
      free(entry->expansion);
      
      // Remember the pointer to the next entry.
      next = entry->next;
      
      // Free the entry itself.
      free(entry);
      
      // Go to the next entry.
      entry = next;
      
    }
    
  }
}