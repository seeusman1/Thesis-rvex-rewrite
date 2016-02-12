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
#include <errno.h>
#include <string.h>
#include <sys/select.h>

#include "select.h"

/**
 * Contains the set of file descriptors currently registered.
 */
static fd_set registeredDescriptors;

/**
 * Highest numbered file descriptor currently registered. For some reason
 * select() needs to know this.
 */
static int maxRegisteredDescriptor;

/**
 * Contains the set of file descriptors currently ready for reads.
 */
static fd_set readyDescriptors;

/**
 * Initializes the internal state of the select unit.
 */
int select_init(void) {
  
  // Make sure the set of file descriptors is empty to begin with.
  FD_ZERO(&registeredDescriptors);
  maxRegisteredDescriptor = 0;
  
  return 0;
}

/**
 * Registers a file descriptor to be waited on by select_wait().
 */
int select_register(int f) {
  
  // Add the descriptor to the set.
  FD_SET(f, &registeredDescriptors);
  
  // Update the maximum value if necessary.
  if (f > maxRegisteredDescriptor) {
    maxRegisteredDescriptor = f;
  }
  
  return 0;
}

/**
 * Unregisters a file descriptor from the set used by select_wait().
 */
int select_unregister(int f) {
  
  // Remove the descriptor from the set.
  FD_CLR(f, &registeredDescriptors);
  
  return 0;
}

/**
 * Makes the actual call to select. When quick is nonzero, the timeout is set
 * to 1 ms, which is useful for when operations are in progress and we want to
 * check for timeouts. When quick is 0, select_wait blocks until any of the
 * monitored streams are ready.
 */
int select_wait(int quick) {
  struct timeval timeout;
  struct timeval *ptimeout;
  int numReady;
  
  // Configure the timeout such that select returns after at most a ms if quick
  // is set.
  if (quick) {
    timeout.tv_sec = 0;
    timeout.tv_usec = 10000;
    ptimeout = &timeout;
  } else {
    ptimeout = 0;
  }
  
  // Copy the set of monitored descriptors into the set of ready descriptors
  // so select() can freely modify it accordingly without breaking things.
  readyDescriptors = registeredDescriptors;
  
  // Call select.
  if ((numReady = select(maxRegisteredDescriptor + 1, &readyDescriptors, 0, 0, ptimeout)) < 0) {
    perror("Call to select failed");
    return -1;
  }
  
  return numReady;
}

/**
 * Returns whether the given file descriptor is ready for read access in this
 * iteration.
 */
int select_isReady(int f) {
  
  return FD_ISSET(f, &readyDescriptors);
  
}
