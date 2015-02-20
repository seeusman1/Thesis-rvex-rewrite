/* Debug interface for standalone r-VEX processor
 * 
 * Copyright (C) 2008-2015 by TU Delft.
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
 * Copyright (C) 2008-2015 by TU Delft.
 */

#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <signal.h>
#include <fcntl.h>
#include <unistd.h>

#include "daemon.h"

/**
 * Log file to use.
 */
static const unsigned char *LOG_FILE = "/var/tmp/rvsrv.log";

/**
 * Turns the process into a daemon. stdout and stderr are redirected to
 * /var/tmp/rvsrv.log.
 */
int daemonize(void) {
  pid_t pid;
  int logfile;
  
  // Fork, allowing the parent process to terminate.
  pid = fork();
  if (pid == -1) {
    perror("Failed to fork while daemonizing");
    return -1;
  } else if (pid) {
    exit(EXIT_SUCCESS);
    return 1;
  }
  
  // Start a new session for the daemon.
  if (setsid() < 0) {
    perror("Failed to become session leader while daemonizing");
    return -1;
  }
  
  // Fork again, allowing the parent process to terminate.
  signal(SIGHUP, SIG_IGN);
  pid = fork();
  if (pid == -1) {
    perror("Failed to fork while daemonizing");
    return -1;
  } else if (pid) {
    exit(EXIT_SUCCESS);
    return 1;
  }
  
  // Set the current working directory to the root directory.
  if (chdir("/") == -1) {
    perror("Failed to change working directory to /");
    return -1;
  }
  
  // Set the user file creation mask to zero.
  umask(0);
  
  // Close and reopen standard file descriptors.
  close(STDIN_FILENO);
  if (open("/dev/null",O_RDONLY) == -1) {
    perror("Failed to reopen stdin while daemonizing");
    return -1;
  }
  if (unlink(LOG_FILE)) {
    if (errno != ENOENT) {
      perror("Failed to remove previous log file");
      return -1;
    }
  }
  logfile = open(LOG_FILE, O_RDWR | O_CREAT, 00666);
  if (logfile == -1) {
    perror("Failed to open log file");
    return -1;
  }
  printf("Daemon process running now, moving log output to %s.\n", LOG_FILE);
  dup2(logfile, STDOUT_FILENO);
  dup2(logfile, STDERR_FILENO);
  close(logfile);
  
  // Success.
  printf("rvsrv daemon started successfully.\n");
  return 0;
  
}

