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
#include <unistd.h>
#include <ctype.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <netdb.h>

/**
 * Hostname and port to connect to.
 */
static char *host = 0;
static int port;

/**
 * Socket file descriptor for the connection to rvsrv.
 */
static int rvsrvSocket = -1;

/**
 * Maximum size of a debug packet. Set to 8k plus a little extra so a write
 * command can write a full 4kbyte page at once.
 */
#define MAX_PACKET_LEN 8448

/**
 * Buffer shared between commands and replies.
 */
static char packetBuffer[MAX_PACKET_LEN+1];

/**
 * Tries to connect to the given host and port, if not connected already.
 * Returns -1 and prints an error if something went wrong, otherwise returns
 * 0 to indicate success.
 */
static int rvsrv_connect(void) {
  struct addrinfo hints;
  struct addrinfo *addrInfo;
  struct addrinfo *curAddrInfo;
  int retval;
  
  // Return success if we're already connected.
  if (rvsrvSocket >= 0) {
    return 0;
  }
  
  // Make sure setup has been called.
  if (!host) {
    fprintf(stderr, "Tried to execute a server command before rvsrv_setup() was called; this should never happen.\n");
    return -1;
  }
  
  // Perform IP address parsing/the DNS lookup using getaddrinfo.
  memset(&hints, 0, sizeof hints);
  hints.ai_family = AF_UNSPEC;
  hints.ai_socktype = SOCK_STREAM;
  if ((retval = getaddrinfo(host, 0, &hints, &addrInfo)) != 0) {
    fprintf(stderr, "Failed to connect to rvsrv: %s\n", gai_strerror(retval));
    return -1;
  }
  
  // Try to connect.
  curAddrInfo = addrInfo;
  while (curAddrInfo) {
    struct sockaddr_in *addr = (struct sockaddr_in*)curAddrInfo->ai_addr;
    
    // Make sure we're connecting to the right port.
    addr->sin_port = htons(port);
    
    // Try to open a connection.
    rvsrvSocket = socket(AF_INET, SOCK_STREAM, 0);
    if (rvsrvSocket >= 0) {
      if (connect(rvsrvSocket, (struct sockaddr *)addr, curAddrInfo->ai_addrlen) >= 0) {
        
        // Opened a connection.
        freeaddrinfo(addrInfo);
        return 0;
        
      }
      close(rvsrvSocket);
      rvsrvSocket = -1;
    }
    
    // Try the next connection in the linked list.
    curAddrInfo = curAddrInfo->ai_next;
    
  }
  
  // Failed to connect.
  fprintf(stderr, "Failed to connect to rvsrv. Tried connecting to TCP port %d at these addresses:\n", port);
  curAddrInfo = addrInfo;
  while (curAddrInfo) {
    struct sockaddr_in *addr = (struct sockaddr_in*)curAddrInfo->ai_addr;
    fprintf(stderr, "  %s", inet_ntoa(addr->sin_addr));
    curAddrInfo = curAddrInfo->ai_next;
  }
  fprintf(stderr, "\n");
  freeaddrinfo(addrInfo);
  return -1;
}

/**
 * Sends the null-terminated contents in commandBuf to the server, then replace
 * the buffer contents with the server reply. Returns a pointer to the first
 * parameter of the reply within commandBuf, or null if something went wrong.
 */
static char *transfer(void) {
  int remain;
  char *ptr, *ptr2, *endOfReply;
  static char buf[256];
  static char commandName[256];
  int error;
  
  // Make sure we have a connection.
  if (rvsrv_connect() < 0) {
    return 0;
  }
  
  // Copy the name of the command.
  ptr = packetBuffer;
  ptr2 = commandName;
  remain = 255;
  while ((*ptr) && (*ptr != ',') && (*ptr != ';') && remain) {
    *ptr2++ = *ptr++;
    remain--;
  }
  *ptr2 = 0;
  
  // Send the command to the server.
  ptr = packetBuffer;
  remain = strlen(packetBuffer);
  while (remain) {
    int count = write(rvsrvSocket, ptr, remain);
    if (count < 1) {
      perror("Failed to write to rvsrv socket");
      return 0;
    }
    ptr += count;
    remain -= count;
  }
  
  // Wait for and read the server reply.
  ptr = packetBuffer;
  remain = MAX_PACKET_LEN;
  endOfReply = 0;
  while (1) {
    int count = read(rvsrvSocket, buf, 256);
    int i;
    if (count < 0) {
      perror("Failed to read from rvsrv socket");
      return 0;
    } else if (count == 0) {
      fprintf(stderr,
        "Error: rvsrv seems to have closed the connection while trying to execute the\n"
        "\"%s\" command. It probably crashed...\n",
        commandName
      );
      return 0;
    }
    for (i = 0; i < count; i++) {
      
      char d = buf[i];
      
      // Check if the buffer is full.
      if (!remain) {
        
        // Buffer is full; ignore everything except for the semicolon
        // delimiter character.
        if (d == ';') {
          
          // Display an error message and terminate.
          fprintf(stderr, 
            "Received reply from rvsrv which was too large for the buffer.\n"
          );
          return 0;
          
        }
        
      } else {
        
        // There is space left in the buffer, handle the byte.
        if (d == ';') {
          
          // Delimiter character: we've received the full reply.
          // Null-terminate the reply.
          *ptr = 0;
          endOfReply = ptr;
          
          // Received the full reply.
          break;
          
        } else if ((d == ',') || ((d >= 'a') && (d <= 'z')) || ((d >= 'A') && (d <= 'Z')) || ((d >= '0') && (d <= '9'))) {
          
          // Normal character, add it to the buffer.
          *ptr++ = d;
          remain--;
          
        } else {
          
          // Ignore everything else.
          
        }
        
      }
      
    }
    
    // Stop reading if we've encountered the end of the reply.
    if (endOfReply) {
      break;
    }
    
  }
  
  // Scan the first comma seperated token. This should be "OK" or "Error".
  ptr = strtok(packetBuffer, ",");
  if (!ptr) {
    fprintf(stderr, 
      "Error: received a malformed reply to command \"%s\" from rvsrv.\n",
      commandName
    );
    return 0;
  }
  if (!strcmp(ptr, "OK")) {
    error = 0;
  } else if (!strcmp(ptr, "Error")) {
    error = 1;
  } else {
    fprintf(stderr, 
      "Error: received a malformed reply to command \"%s\" from rvsrv:\n"
      "expected \"OK\" or \"Error\" for the first token, but received \"%s\".\n",
      commandName, ptr
    );
    return 0;
  }
  
  // Scan the second comma seperated token. This should be the command name.
  ptr = strtok(0, ",");
  if (!ptr) {
    fprintf(stderr, 
      "Error: received a malformed reply to command \"%s\" from rvsrv:\n"
      "expected at least two tokens.\n",
      commandName
    );
    return 0;
  }
  if (strcmp(ptr, commandName)) {
    fprintf(stderr, 
      "Error: received a malformed reply to command \"%s\" from rvsrv:\n"
      "expected command name for second token, but received \"%s\".\n",
      commandName, ptr
    );
    return 0;
  }
  
  // Handle error messages from the server by just printing them and returning
  // failure.
  if (error) {
    ptr = strtok(0, ",");
    if (!ptr) {
      fprintf(stderr, 
        "Error: rvsrv replied with an undefined error to command \"%s\".\n",
        commandName
      );
    } else if (!strcmp(ptr, "UnknownCommand")) {
      fprintf(stderr, 
        "Error: rvsrv replied with an unknown command error to command\n"
        "\"%s\". Are you using the right rvsrv version?\n",
        commandName
      );
    } else if (!strcmp(ptr, "Syntax")) {
      fprintf(stderr, 
        "Error: rvsrv replied with a syntax error to command \"%s\".\n"
        "Are you using the right rvsrv version?\n",
        commandName
      );
    } else if (!strcmp(ptr, "CommunicationError")) {
      fprintf(stderr, 
        "Error: rvsrv encountered a communication error with the hardware while\n"
        "executing the \"%s\" command. Please ensure that the hardware\n"
        "is connected and that rvsrv is configured correctly.\n",
        commandName
      );
    } else {
      fprintf(stderr, 
        "rvsrv replied with an \"%s\" error to command \"%s\".\n",
        ptr, commandName
      );
    }
    return 0;
  }
  
  // Success. Return a pointer to the parameters of the command as returned by
  // strtok, or return a pointer to the null-termination character at the end
  // of the string if no parameters were returned.
  ptr = strtok(0, ";");
  if (!ptr) {
    return endOfReply;
  } else {
    return ptr;
  }
  
}

/**
 * Stores the hostname and port to connect to internally. The connection is not
 * made until the first call to one of the read or write methods.
 */
int rvsrv_setup(const char *newHost, int newPort) {
  int size = strlen(newHost) + 1;
  host = (char*)malloc(size);
  if (!host) {
    perror("Failed to allocate memory for host name");
    return -1;
  }
  memcpy(host, newHost, size);
  port = newPort;
  return 0;
}

/**
 * Closes the connection to rvsrv if a connection is open.
 */
void rvsrv_close(void) {
  if (rvsrvSocket >= 0) {
    close(rvsrvSocket);
  }
  free(host);
  host = 0;
}

/**
 * Sends the stop command to the server.
 */
int rvsrv_stopServer(void) {
  sprintf(packetBuffer, "Stop;");
  if (!transfer()) {
    return -1;
  }
  printf("Successfully requested rvsrv to close.\n");
  return 0;
}

/**
 * Executes a read/write command and interprets the rvsrv result. The command
 * should already have been placed in commandBuf by the caller prior to
 * calling. isWrite should be nonzero when a write command was placed in
 * commandBuf and zero when a read command was. *fault will be set to 1 if a
 * bus fault occured or to 0 if not. *readBuf will be allocated to a buffer
 * of appropriate size to store the read result or bus fault code. *readBufSize
 * will be set to this size. *readBuf must be freed by the caller.
 */
static int executeReadWrite(int isWrite, int *fault, unsigned char **readBuf, int *readBufSize) {
  char *ptr;
  unsigned char *bufPtr;
  
  // Indicate that no buffer has been allocated yet and that no bus fault has
  // occured.
  *fault = 0;
  *readBuf = 0;
  *readBufSize = 0;
  
  // Initiate the transfer and the command-agnostic part of the result from
  // rvsrv.
  ptr = transfer();
  if (!ptr) {
    return -1;
  }
  
  // The first parameter token should be "OK" or "Fault".
  ptr = strtok(ptr, ",");
  if (!ptr) {
    fprintf(stderr, 
      "Error: received a malformed reply to command \"%s\" from rvsrv:\n"
      "expected at least three tokens.\n",
      isWrite ? "Write" : "Read"
    );
    return -1;
  }
  if (!strcmp(ptr, "OK")) {
    *fault = 0;
  } else if (!strcmp(ptr, "Fault")) {
    *fault = 1;
  } else {
    fprintf(stderr, 
      "Error: received a malformed reply to command \"%s\" from rvsrv:\n"
      "expected \"OK\" or \"Fault\" for the third token, but received \"%s\".\n",
      isWrite ? "Write" : "Read", ptr
    );
    return -1;
  }
  
  // The second and third result parameter are the address and the number of
  // bytes read/written. We don't need those, so we throw them away.
  ptr = strtok(0, ",");
  if (!ptr) {
    fprintf(stderr, 
      "Error: received a malformed reply to command \"%s\" from rvsrv:\n"
      "expected at least four tokens.\n",
      isWrite ? "Write" : "Read"
    );
    return -1;
  }
  ptr = strtok(0, ",");
  if (!ptr) {
    fprintf(stderr, 
      "Error: received a malformed reply to command \"%s\" from rvsrv:\n"
      "expected at least five tokens.\n",
      isWrite ? "Write" : "Read"
    );
    return -1;
  }  
  
  // The fourth parameter token should be a hex string for reads or writes
  // where a bus fault occured.
  ptr = strtok(0, ",");
  if (!isWrite || *fault) {
    int size;
    
    // We should have a token here.
    if (!ptr) {
      fprintf(stderr, 
        "Error: received a malformed reply to command \"%s\" from rvsrv:\n"
        "expected at least six tokens.\n",
        isWrite ? "Write" : "Read"
      );
      return -1;
    }
    
    // Figure out the size of the token.
    size = strlen(ptr);
    if (size & 1) {
      fprintf(stderr, 
        "Error: received a malformed reply to command \"%s\" from rvsrv:\n"
        "expected data token to contain an even number of characters.\n",
        isWrite ? "Write" : "Read"
      );
      return -1;
    }
    size >>= 1;
    
    // Allocate a buffer large enough to contain the result data.
    bufPtr = (unsigned char *)malloc(size);
    if (!bufPtr) {
      perror("Failed to allocate memory for data returned by rvsrv");
      return -1;
    }
    *readBuf = bufPtr;
    *readBufSize = size;
    
    // Read the hexadecimal data token.
    while (size) {
      if (!sscanf(ptr, "%2hhX", bufPtr)) {
        fprintf(stderr, 
          "Error: received a malformed reply to command \"%s\" from rvsrv:\n"
          "unexpected non-hex character in received data token.\n",
          isWrite ? "Write" : "Read"
        );
      }
      
      ptr += 2;
      bufPtr++;
      size--;
    }
    
    // Move on to the next token.
    ptr = strtok(0, ",");
    
  }
  
  // We should be at the end of the reply now.
  if (ptr) {
    fprintf(stderr, 
      "Error: received a malformed reply to command \"%s\" from rvsrv:\n"
      "unexpected reply token.\n",
      isWrite ? "Write" : "Read"
    );
    return -1;
  }
  
  return 0;
}

/**
 * Reads a single byte, halfword or word from the hardware (size set to 1, 2 or
 * 4 respectively). Returns 1 when successful, 0 when a bus error occured, or
 * -1 when a fatal error occured. In the latter case, an error will be printed
 * to stderr. When a bus error occurs, value is set to the bus fault.
 */
int rvsrv_readSingle(
  uint32_t address,
  uint32_t *value,
  int size
) {
  int fault;
  unsigned char *readBuf;
  int readBufSize;
  
  // Check the size locally before sending the command to rvsrv.
  switch (size) {
    case 1:
    case 2:
    case 4:
      break;
    default:
      fprintf(stderr, "rvsrv_readSingle() was called with incorrect size %d.\n", size);
      return -1;
  }
  
  // Send the command to rvsrv.
  sprintf(packetBuffer, "Read,%08X,%d;", address, size);
  if (executeReadWrite(0, &fault, &readBuf, &readBufSize) < 0) {
    free(readBuf);
    return -1;
  }
  
  // If a bus fault occured, we're getting 4 bytes regardless of how much we
  // read, because that's the size of the bus fault code.
  if (fault) {
    size = 4;
  }
  
  // Make sure we got the expected amount of bytes.
  if (readBufSize != size) {
    fprintf(stderr, 
      "Error: received a malformed reply to command \"Read\" from rvsrv:\n"
      "unexpected amount of bytes returned.\n"
    );
    free(readBuf);
    return -1;
  }
  
  // Set the value output.
  *value = readBuf[0];
  if (size >= 2) {
    *value <<= 8;
    *value |= readBuf[1];
  }
  if (size >= 4) {
    *value <<= 8;
    *value |= readBuf[2];
    *value <<= 8;
    *value |= readBuf[3];
  }
  
  // Free the read buffer.
  free(readBuf);
  
  // Return 1 when the read was successful or 0 when a bus fault occured.
  return !fault;
  
}

/**
 * Reads at most 4096 bytes in a single command. The address does not need to
 * be aligned, but it's slightly faster if it is. Returns 1 when successful,
 * 0 when a bus error occured, or -1 when a fatal error occured. In the latter
 * case, an error will be printed to stderr. If a bus error occured and fault
 * is not null, *faultCode will be set to the bus fault. Only the last bus
 * access is checked for fault conditions.
 */
int rvsrv_readBulk(
  uint32_t address,
  unsigned char *buffer,
  int size,
  uint32_t *faultCode
) {
  int fault;
  unsigned char *readBuf;
  int readBufSize;
  
  // Check the size.
  if (size > 4096) {
    fprintf(stderr,
      "Error: rvsrv_readBulk() called with more than 4096 bytes.\n"
    );
    return -1;
  }
  
  // Send the command to rvsrv.
  sprintf(packetBuffer, "Read,%08X,%d;", address, size);
  if (executeReadWrite(0, &fault, &readBuf, &readBufSize) < 0) {
    free(readBuf);
    return -1;
  }
  
  // Make sure we got the expected amount of bytes.
  if (readBufSize != (fault ? 4 : size)) {
    fprintf(stderr, 
      "Error: received a malformed reply to command \"Write\" from rvsrv:\n"
      "unexpected amount of bytes returned.\n"
    );
    free(readBuf);
    return -1;
  }
  
  if (fault) {
    
    // Set the faultCode output.
    *faultCode = readBuf[0];
    *faultCode <<= 8;
    *faultCode |= readBuf[1];
    *faultCode <<= 8;
    *faultCode |= readBuf[2];
    *faultCode <<= 8;
    *faultCode |= readBuf[3];
    
  } else {
    
    // Copy the read buffer into the specified buffer.
    memcpy(buffer, readBuf, size);
    
  }
  
  // Free the read buffer.
  free(readBuf);
  
  // Return 1 when the read was successful or 0 when a bus fault occured.
  return !fault;
  
}

/**
 * Writes a single byte, halfword or word to the hardware (size set to 1, 2 or
 * 4 respectively). Returns 1 when successful, 0 when a bus error occured, or
 * -1 when a fatal error occured. In the latter case, an error will be printed
 * to stderr. If a bus error occured and fault is not null, *faultCode will be
 * set to the bus fault.
 */
int rvsrv_writeSingle(
  uint32_t address,
  uint32_t value,
  int size,
  uint32_t *faultCode
) {
  
  int fault;
  unsigned char *readBuf;
  int readBufSize;
  
  // Check the size locally before sending the command to rvsrv.
  switch (size) {
    case 1:
      sprintf(packetBuffer, "Write,%08X,%d,%02X;", address, size, value & 0xFF);
      break;
    case 2:
      sprintf(packetBuffer, "Write,%08X,%d,%04X;", address, size, value & 0xFFFF);
      break;
    case 4:
      sprintf(packetBuffer, "Write,%08X,%d,%08X;", address, size, value);
      break;
    default:
      fprintf(stderr, "rvsrv_writeSingle() was called with incorrect size %d.\n", size);
      return -1;
  }
  
  // Send the command to rvsrv.
  if (executeReadWrite(1, &fault, &readBuf, &readBufSize) < 0) {
    free(readBuf);
    return -1;
  }
  
  // Make sure we got the expected amount of bytes.
  if (readBufSize != (fault ? 4 : 0)) {
    fprintf(stderr, 
      "Error: received a malformed reply to command \"Write\" from rvsrv:\n"
      "unexpected amount of bytes returned.\n"
    );
    free(readBuf);
    return -1;
  }
  
  // Set the faultCode output.
  if (fault) {
    *faultCode = readBuf[0];
    *faultCode <<= 8;
    *faultCode |= readBuf[1];
    *faultCode <<= 8;
    *faultCode |= readBuf[2];
    *faultCode <<= 8;
    *faultCode |= readBuf[3];
  }
  
  // Free the read buffer.
  free(readBuf);
  
  // Return 1 when the read was successful or 0 when a bus fault occured.
  return !fault;
  
}

/**
 * Writes at most 4096 bytes in a single command. The address does not need to
 * be aligned, but it's slightly faster if it is. Returns 1 when successful,
 * 0 when a bus error occured, or -1 when a fatal error occured. In the latter
 * case, an error will be printed to stderr. If a bus error occured and fault
 * is not null, *faultCode will be set to the bus fault. Only the last bus
 * access is checked for fault conditions.
 */
int rvsrv_writeBulk(
  uint32_t address,
  unsigned char *buffer,
  int size,
  uint32_t *faultCode
) {
  
  char *ptr;
  int fault;
  int readBufSize;
  unsigned char *readBuf;
  
  // Check the size.
  if (size > 4096) {
    fprintf(stderr,
      "Error: rvsrv_writeBulk() called with more than 4096 bytes.\n"
    );
    return -1;
  }
  
  // Generate the command.
  sprintf(packetBuffer, "Write,%08X,%d,", address, size);
  ptr = packetBuffer + strlen(packetBuffer);
  while (size) {
    sprintf(ptr, "%02hhX", *buffer);
    buffer++;
    ptr += 2;
    size--;
  }
  sprintf(ptr, ";");
  
  // Send the command to rvsrv.
  if (executeReadWrite(1, &fault, &readBuf, &readBufSize) < 0) {
    free(readBuf);
    return -1;
  }
  
  // Make sure we got the expected amount of bytes.
  if (readBufSize != (fault ? 4 : 0)) {
    fprintf(stderr, 
      "Error: received a malformed reply to command \"Write\" from rvsrv:\n"
      "unexpected amount of bytes returned.\n"
    );
    free(readBuf);
    return -1;
  }
  
  // Set the faultCode output.
  if (fault) {
    *faultCode = readBuf[0];
    *faultCode <<= 8;
    *faultCode |= readBuf[1];
    *faultCode <<= 8;
    *faultCode |= readBuf[2];
    *faultCode <<= 8;
    *faultCode |= readBuf[3];
  }
  
  // Free the read buffer.
  free(readBuf);
  
  // Return 1 when the read was successful or 0 when a bus fault occured.
  return !fault;
  
}
