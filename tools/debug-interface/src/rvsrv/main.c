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
#include <errno.h>
#include <string.h>
#include <signal.h>
#include <unistd.h>
#include <time.h>

#include "main.h"
#include "serial.h"
#include "daemon.h"
#include "parseReadWrite.h"
#include "rvex_iface.h"
#include "select.h"
#include "tcpserv.h"

#include "pcie/pcie.h"
#include "mmio/mmio.h"
#include "uart/uart.h"

/**
 * TCP server for sending data to and receiving data from the application code
 * running on the rvex platform.
 */
tcpServer_t *appServer;

/**
 * TCP server for debug requests.
 */
tcpServer_t *debugServer;

/**
 * Interface to the rVEX device.
 */
static rvex_iface_t rvexIface;


//-----------------------------------------------------------------------------
// Signal handling
//-----------------------------------------------------------------------------

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
  printf("SIGTERM received, stopping.\n");
  if (!terminatePipe[1] || (write(terminatePipe[1], "", 1) != 1)) {
    perror("Failed to stop gracefully, exiting without cleaning up");
    exit(EXIT_FAILURE);
  }
}


//-----------------------------------------------------------------------------
// Debug server command handling
//-----------------------------------------------------------------------------

/**
 * Maximum size of a debug command. Set to 8k plus a little extra so a write
 * command can write a full 4kbyte page at once.
 */
#define MAX_DEBUG_COMMAND_SIZE 8448

/**
 * Extra data structure for receiving debug commands.
 */
typedef struct {
  
  /**
   * Command buffer.
   */
  unsigned char commandBuf[MAX_DEBUG_COMMAND_SIZE];
  
  /**
   * Number of bytes currently in the buffer.
   */
  int numBytes;
  
} debugServerClientData_t;

/**
 * Allocates extra data for debug server command handling.
 */
static int debugServerExtraDataAlloc(void **extra) {
  if (extra) {
    *extra = malloc(sizeof(debugServerClientData_t));
    if (!*extra) {
      return -1;
    }
    ((debugServerClientData_t*)(*extra))->numBytes = 0;
  }
  return 0;
}

/**
 * Deallocates extra data for debug server command handling.
 */
static int debugServerExtraDataFree(void **extra) {
  if (extra && *extra) {
    free(*extra);
    *extra = 0;
  }
  return 0;
}

/**
 * Returns 1 if command starts with the specified text and is either followed
 * by a comma or null, or 0 otherwise.
 */
static int checkCommand(const unsigned char *command, const unsigned char *text) {
  
  while (*text) {
    if (*command++ != *text++) {
      return 0;
    }
  }
  
  return (*command == 0) || (*command == ',');
}

/**
 * Handles a server command. firstTime should be set to 1 the first time
 * handleCommand is called for a specific command, and 0 thereafter. Return
 * values:
 *  -1 = An error occured.
 *   0 = Command is being processed, not done yet.
 *   1 = Command processing complete, stop the server.
 *   2 = Command processing complete, fetch the next command.
 */
static int handleCommand(unsigned char *command, int clientID, int firstTime) {
  unsigned char *ptr;
  
  if (checkCommand(command, (const unsigned char *)"Stop")) {
    
    // Stop server command.
    if (tcpServer_sendStr(debugServer, clientID, (const unsigned char *)"OK, Stop;\n") < 0) {
      return -1;
    }
    printf("Client ID %d (debug access) requested the server to stop.\n", clientID);
    return 1;
    
  } else if (checkCommand(command, (const unsigned char *)"Read") || checkCommand(command, (const unsigned char *)"Write")) {

    struct parse_rw_result res;
    unsigned char *syntax_error;
    
    // Parse read/write command.
    int err = parseReadWrite(command, &res, &syntax_error);
    if (err == 0) {
      // Perform the write or read.
      if (res.is_write) {
        err = rvexIface.write(res.address, res.buffer, res.buf_size, clientID);
        free(res.buffer);
      } else {
        err = rvexIface.read(res.address, res.buf_size, clientID);
      }
      if (err < 0) {
        return -1;
      }
    } else if (err == 1) {
      tcpServer_sendStr(debugServer, clientID, syntax_error);
      free(syntax_error);
    } else {
      return -1;
    }
    
    return 2;
    
  }
  
  // Unknown command.
  if (tcpServer_sendStr(debugServer, clientID, (const unsigned char *)"Error, ") < 0) {
    return -1;
  }
  ptr = command;
  while ((*ptr) && (*ptr != ',')) {
    if (tcpServer_send(debugServer, clientID, *ptr++) < 0) {
      return -1;
    }
  }
  if (tcpServer_sendStr(debugServer, clientID, (const unsigned char *)", UnknownCommand;\n") < 0) {
    return -1;
  }
  return 2;
  
}

/**
 * Retrieves and handles debug commands. Returns values:
 *  -1 = An error occured.
 *   0 = Everything is OK.
 *   1 = Stop command received, stop the server.
 */
static int handleDebugServer(void) {
  static unsigned char *currentCommand = 0;
  static int currentClient = 0;
  
  // If we were handling a command, continue doing so.
  if (currentCommand) {
    int retval;
    
    retval = handleCommand(currentCommand, currentClient, 0);
    if (retval < 0) {
      
      // Error while processing the command.
      return -1;
      
    } else if (retval == 0) {
      
      // Command did not complete yet.
      return 0;
      
    } else if (retval == 1) {
      
      // Received stop server command.
      return 1;
      
    }
    
    // Command handling complete.
    currentCommand = 0;
    
  }
  
  // If we're not handling a command right now, try to get one.
  if (!currentCommand) {
    int clientID;
    
    // Loop over all connected clients.
    for (clientID = tcpServer_nextClient(debugServer, -1); clientID >= 0; clientID = tcpServer_nextClient(debugServer, clientID)) {
      debugServerClientData_t *extra;
      int d;
      
      // Found a client to retrieve stuff from. Get the pointer to the
      // packet buffer.
      extra = tcpServer_getExtraData(debugServer, clientID);
      if (!extra) {
        continue;
      }
      
      // Receive bytes from the client, process them, and stick them in
      // the command buffer.
      while ((d = tcpServer_receive(debugServer, clientID)) >= 0) {
        
        // Check if the buffer is full.
        if (extra->numBytes >= MAX_DEBUG_COMMAND_SIZE) {
          
          // Buffer is full; ignore everything except for the semicolon
          // delimiter character.
          if (d == ';') {
            
            // Send an error message.
            tcpServer_sendStr(debugServer, clientID, (const unsigned char *)"Error, PacketBufferOverrun;\n");
            
            // Reset the buffer.
            extra->numBytes = 0;
            
          }
          
        } else {
          
          // There is space left in the buffer, handle the byte.
          if (d == ';') {
            int retval;
            
            // Delimiter character: we've received a full command.
            // Null-terminate the command.
            extra->commandBuf[extra->numBytes] = 0;
            
            // Reset the buffer.
            extra->numBytes = 0;
            
            // Call handleCommand for the first time.
            retval = handleCommand(extra->commandBuf, clientID, 1);
            if (retval < 0) {
              
              // Error while processing the command.
              return -1;
              
            } else if (retval == 0) {
              
              // Command did not complete yet. Remember that we're working on
              // a command and return.
              currentCommand = extra->commandBuf;
              currentClient = clientID;
              return 0;
              
            } else if (retval == 1) {
              
              // Received stop server command.
              return 1;
              
            }
            
          } else if ((d == ',') || ((d >= 'a') && (d <= 'z')) || ((d >= 'A') && (d <= 'Z')) || ((d >= '0') && (d <= '9'))) {
            
            // Normal character, add it to the buffer.
            extra->commandBuf[extra->numBytes++] = d;
            
          } else {
            
            // Ignore everything else.
            
          }
          
        }
        
      }
      
    }
    
  }
  
  return 0;
  
}


//-----------------------------------------------------------------------------
// Application server command handling
//-----------------------------------------------------------------------------

/**
 * Forwards data received from the application TCP server to the rvex
 * application, and broadcasts data from the rvex application to all clients
 * connected to the application TCP server.
 */
static int handleApplicationData(int tty) {
  int clientID;
  int d;
  
  // Loop over all connected clients.
  for (clientID = tcpServer_nextClient(appServer, -1); clientID >= 0; clientID = tcpServer_nextClient(appServer, clientID)) {
    
    // Receive bytes from the client and stick them in the application serial
    // TX buffer.
    while ((d = tcpServer_receive(appServer, clientID)) >= 0) {
      if (serial_appSend(tty, d) < 0) {
        return -1;
      }
    }
  }
  
  // Broadcast bytes from the application serial RX buffer.
  while ((d = serial_appReceive(tty)) >= 0) {
    if (tcpServer_broadcast(appServer, d) < 0) {
      return -1;
    }
  }
  
  return 0;
}

//-----------------------------------------------------------------------------
// Main program loop
//-----------------------------------------------------------------------------

/**
 * Closes all file descriptors and connections.
 */
static void cleanup(int *tty) {
  
  // Free memory used by the debug command queues.
  if(rvexIface.free) {
    rvexIface.free();
  }
  
  // Close the serial port connection.
  if (*tty >= 0) {
    serial_close(tty);
  }
  
  // Close TCP servers.
  tcpServer_close(&appServer);
  tcpServer_close(&debugServer);
  
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

/**
 * Fails gracefully if the parameter is 0.
 */
#define CHECK_FALSE(f) \
  if (!(f)) { \
    cleanup(&tty); \
    return -1; \
  }

/**
 * Fails gracefully if the parameter is negative.
 */
#define CHECK(f) CHECK_FALSE((f) >= 0)

/**
 * Fails gracefully if the parameter is null.
 */
#define CHECKNULL(f) CHECK_FALSE(f)

/**
 * Runs the program. First opens the handle to the serial port, then starts
 * listening on the requested TCP ports and starts handling commands.
 */
int run(const commandLineArgs_t *args) {
  int tty;
  int busy;
  int terminated;
  int supposed_to_have_tty;
  time_t now = 0;
  time_t last_reconnect_attempt = 0;
  
  // Initialize select wrapper state.
  CHECK(select_init());
  
  // Try to open the serial port.
  tty = serial_open(args->port, args->baudrate);
  // Only fail when we are not using PCIe or mmio communication.
  CHECK_FALSE(tty >= 0 || args->pcieCdev || args->mmioFile);
  supposed_to_have_tty = tty != 0;

  // Try to initalize the rvex interface.
  if (args->pcieCdev) {
    CHECK(init_pcie_iface(args->pcieCdev, &rvexIface));
  } else if (args->mmioFile) {
    CHECK(init_mmio_iface(args->mmioFile, args->mmioOffset, args->mmioLength, &rvexIface));
  } else {
    CHECK(init_uart_iface(tty, &rvexIface));
  }
  
  // Try to open the TCP servers.
  CHECKNULL(appServer = tcpServer_open(
    args->appPort,
    "application",
    0,
    0
  ));
  CHECKNULL(debugServer = tcpServer_open(
    args->debugPort,
    "debug",
    &debugServerExtraDataAlloc,
    &debugServerExtraDataFree
  ));
  
  // Fork into daemon mode if foreground is not set.
  if (!args->foreground) {
    CHECK(daemonize(args->debugPort));
  }
  
  // Set up the terminate handler.
  if (pipe(terminatePipe) < 0) {
    perror("Could not create pipe");
    return -1;
  }
  CHECK(select_register(terminatePipe[0]));
  signal(SIGTERM, &terminate);
  
  // Run the main loop for the program, where we poll for incoming data and
  // and handle it if we find some.
  busy = 0;
  terminated = 0;
  while (!terminated) {
    int retval;
    
    // Wait for things to become ready.
    CHECK(select_wait(busy));
    busy = 0;
    
    // Update the serial port (perform reads into our buffer).
    if (tty >= 0) {
      if (serial_update(tty) == -1) {
        
        // USB serial port connection lost. Close the port file immediately.
        serial_close(&tty);
        
        // Terminate if we shouldn't try to reconnect.
        if (args->noReconnect) {
          terminated = 1;
        }
        
      }
    } else if (supposed_to_have_tty) {
      
      // Try to reopen the USB serial port at most every few seconds if we lost
      // the connection.
      time(&now);
      if (last_reconnect_attempt + 5 < now) {
        printf("Trying to reopen serial port...\n");
        tty = serial_open(args->port, args->baudrate);
      }
      last_reconnect_attempt = now;
      
    }
    
    // Update the TCP servers (accept incoming connections, perform reads into
    // our buffer).
    tcpServer_update(appServer);
    tcpServer_update(debugServer);
    
    // Handle debug server incoming data.
    CHECK(retval = handleDebugServer());
    if (retval == 1) {
      terminated = 1;
    }
    
    // Handle debug command issue and replies.
    CHECK(busy = rvexIface.update());
    
    if (tty >= 0) {
      // Handle application data.
      CHECK(handleApplicationData(tty));
    
      // Flush the serial port (write pending data to the serial port).
      serial_flush(tty);
    }
    
    // Flush the TCP servers (write pending data to the sockets).
    tcpServer_flush(appServer);
    tcpServer_flush(debugServer);
    
    // Check for the terminate signal. Most of the time the call to select
    // just fails with errno=EINTR so we don't even get here, but it's
    // possible for the signal to occur just before the call to select, in
    // which case it would be possible for us to miss the signal and block
    // until the next read, if it weren't for the magic with the pipe.
    if (select_isReady(terminatePipe[0])) {
      terminated = 1;
    }
    
  }
  
  // Clean up: close open file descriptors and deallocate memory.
  cleanup(&tty);
  
  // Success.
  return 0;
  
}

