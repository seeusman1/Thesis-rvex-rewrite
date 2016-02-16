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
#include <unistd.h>
#include <fcntl.h>
#include <signal.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/select.h>
#include <sys/time.h>
#include <netinet/in.h>

#include "gdb-main.h"
#include "rsp-protocol.h"

/**
 * Whether RSP packets should be dumped to stdout.
 */
int gdb_rspDebug = 0;

/**
 * Pipe used to detect gdb process termination through a select call.
 */
static int gdbTermPipe[2] = {0, 0};

/**
 * Command line arguments for gdb, as passed to execv().
 */
static char **gdbArgv = 0;

/**
 * RSP server socket.
 */
static int rspSocket = 0;

/**
 * RSP server-client connection.
 */
int rspConn = 0;

/**
 * Process ID for the gdb child process.
 */
volatile static pid_t gdbPid = 0;

/**
 * Exit status for the gdb child process, or -1 if it hasn't terminated yet.
 */
volatile static int gdbExitStatus = -1;

/**
 * SIGCHLD handler for reaping the gdb process when it terminates.
 */
static void sigchld(int sig) {
  int status;
  
  // Reap the gdb child.
  if (gdbPid) {
    if (waitpid(gdbPid, &status, WNOHANG) > 0) {
      if (WIFEXITED(status)) {
        gdbExitStatus = WEXITSTATUS(status);
        gdbPid = 0;
        
        // Write to the pipe to get select() to return, in order to inform the
        // parent process.
        write(gdbTermPipe[1], "", 1);
      }
    }
  }
  
  // Just to be thorough, reap any other children as well, even though there
  // shouldn't be any, I think.
  while (waitpid((pid_t)(-1), 0, WNOHANG) > 0) {
  }
  
}

/**
 * Allocates the memory structure for the argv list passed to execv().
 */
static char **makeArgv(const char **params, int paramCount, int portNum) {
  int size;
  int p;
  char **argv;
  char **argvPtr;
  char *strPtr;
  
  // Determine how many bytes we need for the data structure.
  size = (paramCount + 2) * sizeof(char*);
  for (p = 0; p < paramCount; p++) {
    size += strlen(params[p]) + 1;
  }
  size += 45; // For the --eval-command=target remote :ddddd parameter.
  
  // Allocate the memory.
  argv = (char **)malloc(size);
  if (!argv) {
    return 0;
  }
  argvPtr = argv;
  strPtr = (char*)(argv + (paramCount + 2));
  
  // Add the first parameter (the executable).
  strcpy(strPtr, params[0]);
  *argvPtr++ = strPtr;
  strPtr += strlen(strPtr) + 1;
  
  // Add the connection parameter.
  sprintf(strPtr, "--eval-command=target extended-remote :%d", portNum);
  *argvPtr++ = strPtr;
  strPtr += strlen(strPtr) + 1;
  
  // Add the remaining parameters.
  for (p = 1; p < paramCount; p++) {
    strcpy(strPtr, params[p]);
    *argvPtr++ = strPtr;
    strPtr += strlen(strPtr) + 1;
  }
  
  // Finish the list with a null pointer.
  *argvPtr = 0;
  
  return argv;
}

/**
 * Main method for the gdb RSP server.
 */
int gdb_main(const char **params, int paramCount, int debug) {
  struct sockaddr_in addr;
  socklen_t addrLen = sizeof(addr);
  struct sigaction sa;
  int portNum;
  int i;
  fd_set selectFileDescs;
  int maxSelectFileDesc;
  struct timeval timeout;
  sigset_t sigSet;
  
  // Load the debug enable global.
  gdb_rspDebug = debug;
  
  // Create RSP server socket.
  rspSocket = socket(AF_INET, SOCK_STREAM, 0);
  if (rspSocket < 0) {
    perror("Failed to create RSP server socket");
    return -1;
  }
  
  // Bind the RSP server socket to any open port.
  memset(&addr, 0, sizeof(addr));
  addr.sin_family = AF_INET;
  addr.sin_addr.s_addr = INADDR_ANY;
  addr.sin_port = htons(0);
  if (bind(rspSocket, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
    perror("Failed to bind RSP server socket");
    return -1;
  }
  
  // Start listening.
  if (listen(rspSocket, 1) < 0) {
    perror("Failed to start listening on RSP socket");
    return -1;
  }
  
  // Figure out which port we're listening on.
  if (getsockname(rspSocket, (struct sockaddr *)&addr, &addrLen) < 0) {
    perror("Failed to determine TCP port for socket");
    return -1;
  }
  portNum = ntohs(addr.sin_port);
  
  // Allocate the argv list for the gdb child process, including the target
  // remote command to connect with us.
  gdbArgv = makeArgv(params, paramCount, portNum);
  if (!gdbArgv) {
    perror("Failed to allocate argv structure for gdb process");
    return -1;
  }
  
  // Create GDB terminate detect pipe.
  if (pipe(gdbTermPipe) == -1) {
    perror("Failed to create internal pipe");
    return -1;
  }
  for (i = 0; i < 2; i++) {
    fcntl(gdbTermPipe[i], F_SETFL, fcntl(gdbTermPipe[i], F_GETFL) | O_NONBLOCK);
  }
  
  // Attach the SIGCHLD handler to detect termination and get the exit code of
  // the gdb child process and reap it.
  sa.sa_handler = &sigchld;
  sigemptyset(&sa.sa_mask);
  sa.sa_flags = SA_RESTART;
  if (sigaction(SIGCHLD, &sa, 0) < 0) {
    perror("Failed to attach SIGCHLD handler");
    return -1;
  }
  
  // Start the GDB child process.
  gdbPid = fork();
  if (gdbPid < 0) {
    perror("Failed to fork to start gdb");
    return -1;
  } else if (gdbPid == 0) {
    execvp(gdbArgv[0], gdbArgv);
    perror("Failed to launch gdb");
    exit(EXIT_FAILURE);
  }
  
  // Block the SIGINT interrupt so gdb handles it instead.
  sigemptyset(&sigSet);
  sigaddset(&sigSet, SIGINT);
  if (sigprocmask(SIG_BLOCK, &sigSet, 0) < 0) {
    perror("Failed to block SIGINT");
    return -1;
  }
  
  // Accept the RSP connection which gdb should request. This is kinda
  // complicated, because we should also handle the cases where the child
  // process exits before accepting or where the child does not connect for
  // some reason.
  while (1) {
    FD_ZERO(&selectFileDescs);
    FD_SET(gdbTermPipe[0], &selectFileDescs);
    FD_SET(rspSocket, &selectFileDescs);
    maxSelectFileDesc = gdbTermPipe[0];
    if (rspSocket > maxSelectFileDesc) {
      maxSelectFileDesc = rspSocket;
    }
    timeout.tv_sec = 3;
    timeout.tv_usec = 0;
    if (select(maxSelectFileDesc + 1, &selectFileDescs, 0, 0, &timeout) < 0) {
      if (errno != EINTR) {
        perror("Select failed");
        return -1;
      }
    } else {
      break;
    }
  }
  if (FD_ISSET(gdbTermPipe[0], &selectFileDescs)) {
    fprintf(stderr, "Error: gdb terminated before opening RSP connection.\n");
    return -1;
  }
  if (!FD_ISSET(rspSocket, &selectFileDescs)) {
    fprintf(stderr, "Error: timeout waiting for gdb to open RSP connection.\n");
    return -1;
  }
  rspConn = accept(rspSocket, 0, 0);
  if (rspConn < 0) {
    perror("Failed to accept incoming connection from gdb");
    return -1;
  }
  
  // Start handling RSP packets.
  while (1) {
    
    // Select between RSP data and gdb termination.
    FD_ZERO(&selectFileDescs);
    FD_SET(gdbTermPipe[0], &selectFileDescs);
    FD_SET(rspConn, &selectFileDescs);
    maxSelectFileDesc = gdbTermPipe[0];
    if (rspConn > maxSelectFileDesc) {
      maxSelectFileDesc = rspConn;
    }
    if (select(maxSelectFileDesc + 1, &selectFileDescs, 0, 0, 0) < 0) {
      if (errno != EINTR) {
        perror("Select failed");
        return -1;
      }
    }
    
    // Check for gdb termination.
    if (FD_ISSET(gdbTermPipe[0], &selectFileDescs)) {
      if (gdbExitStatus == EXIT_SUCCESS) {
        return 0;
      } else {
        return -1;
      }
    }
    
    // Check for incoming RSP data.
    if (FD_ISSET(rspConn, &selectFileDescs)) {
      char rspData[256];
      int rspDataLen;
      
      // Read from the socket.
      while (1) {
        rspDataLen = read(rspConn, rspData, 256);
        if (rspDataLen < 0) {
          perror("Failed to read from RSP socket");
          return -1;
        } else if (rspDataLen == 0) {
          break;
        } else {
          if (rsp_receiveBuf(rspData, rspDataLen) < 0) {
            return -1;
          }
        }
      }
      
    }
    
  }
  
  return 0;
}

/**
 * Cleans up the resources which are used here.
 */
void gdb_cleanup(void) {
  int i;
  struct sigaction sa;
  sigset_t sigSet;
  
  // Unblock SIGINT.
  sigemptyset(&sigSet);
  sigaddset(&sigSet, SIGINT);
  if (sigprocmask(SIG_UNBLOCK, &sigSet, 0) < 0) {
    perror("Failed to unblock SIGINT");
  }
  
  // Remove the SIGINT and SIGCHLD signal handlers.
  sa.sa_handler = SIG_DFL;
  sigemptyset(&sa.sa_mask);
  sa.sa_flags = SA_RESTART;
  if (sigaction(SIGCHLD, &sa, 0) == -1) {
    perror("Failed to detach SIGCHLD handler, things are getting messy");
  }
  
  // Close the RSP connection.
  if (rspConn > 0) {
    close(rspConn);
    rspConn = 0;
  }
  
  // Kill the gdb child process and reap it if it hasn't exited yet.
  if (gdbPid) {
    kill(gdbPid, SIGTERM);
    kill(gdbPid, SIGKILL);
    waitpid(gdbPid, 0, 0);
  }
  
  // Clean up the GDB termination pipe.
  for (i = 0; i < 2; i++) {
    if (gdbTermPipe[i] > 0) {
      close(gdbTermPipe[i]);
      gdbTermPipe[i] = 0;
    }
  }
  
  // Clean up the argv list for the gdb child process.
  if (gdbArgv) {
    free(gdbArgv);
    gdbArgv = 0;
  }
  
  // Close the RSP server socket.
  if (rspSocket > 0) {
    close(rspSocket);
    rspSocket = 0;
  }
  
}
