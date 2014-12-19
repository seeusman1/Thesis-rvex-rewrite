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
#include <errno.h>
#include <string.h>
#include <signal.h>

#include "main.h"
#include "serial.h"
#include "daemon.h"
#include "select.h"

/**
 * File descriptor for the serial port.
 */
static int tty = 0;

/**
 * Closes all file descriptors and connections.
 */
static void cleanup(void);

/**
 * Fails gracefully if the parameter is negative.
 */
#define CHECK(f) \
  if ((f) < 0) { \
    cleanup(); \
    return -1; \
  }

/**
 * This contains the file descriptors for a pipe which will be used to handle
 * SIGTERM. The handler for SIGTERM will write a dummy byte to the pipe, which
 * will wake up select(), so we can break out of the main loop cleanly.
 */
static int terminatePipe[] = {0, 0};

/**
 * SIGTERM handler.
 */
static void terminate(int sig) {
  if (!terminatePipe[1] || (write(terminatePipe[1], "", 1) != 1)) {
    perror("Failed to stop gracefully, exiting without cleaning up");
    exit(EXIT_FAILURE);
  }
}

/**
 * Runs the program. First opens the handle to the serial port, then starts
 * listening on the requested TCP ports and starts handling commands.
 */
int run(const commandLineArgs_t *args) {
  
  char buf[256];
  int count;
  
  // Initialize select wrapper state.
  CHECK(select_init());
  
  // Try to open the serial port.
  CHECK(tty = openSerial(args->port, args->baudrate));
  CHECK(select_register(tty));
  
  // Try to open the TCP servers.
  // TODO
  
  // Fork into daemon mode.
  CHECK(daemonize());
  
  // Set up the terminate handler.
  if (pipe(terminatePipe) < 0) {
    perror("Could not create pipe");
    return -1;
  }
  CHECK(select_register(terminatePipe[0]));
  signal(SIGTERM, &terminate);
  
  // Run the main loop for the program, where we poll for incoming data and
  // and handle it if we find some.
  while (1) {
    
    // Wait for things to become ready.
    CHECK(select_wait(0));
    
    // Nothing here yet... TODO
    
    // Check for the terminate signal. Most of the time the call to select
    // just fails with errno=EINTR so we don't even get here, but it's
    // possible for the signal to occur just before the call to select, in
    // which case it would be possible for us to miss the signal and block
    // until the next read, if it weren't for the magic with the pipe. It
    // does mean that, most of the time, you'll see "Call to select failed:
    // Interrupted system call" in the log instead of the message below.
    if (select_isReady(terminatePipe[0])) {
      printf("SIGTERM received, stopping.\n");
      return -1;
    }
    
  }
  
  // Clean up: close open file descriptors and deallocate memory.
  cleanup();
  
  // Success.
  return 0;
  
}

/**
 * Closes all file descriptors and connections.
 */
static void cleanup(void) {
  
  // Close the serial port connection.
  closeSerial(&tty);
  
  // Close the handles to the pipe used for the terminate signal.
  if (terminatePipe[0]) {
    close(terminatePipe[0]);
    terminatePipe[0] = 0;
  }
  if (terminatePipe[1]) {
    close(terminatePipe[1]);
    terminatePipe[1] = 0;
  }
  
}

