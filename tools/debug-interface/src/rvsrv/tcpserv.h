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

#ifndef _TCPSERV_H_
#define _TCPSERV_H_

#define TCP_BUFFER_SIZE 1024

/**
 * Called when a client state structure is allocated or deallocated, to allow
 * server-specific data to be created per client connection.
 */
typedef int (*tcpServer_extraData)(void **extra);

/**
 * Represents the state of a client connection to a server.
 */
typedef struct {
  
  /**
   * File descriptor for communicating with the client.
   */
  int clientDesc;
  
  /**
   * Read buffer. When data is available and the buffer is empty, a socket
   * read is performed to fill this as far as possible.
   */
  unsigned char rxBuffer[TCP_BUFFER_SIZE];
  
  /**
   * Number of bytes currently in the read buffer.
   */
  int rxBufSize;
  
  /**
   * Number of bytes in the read buffer which have already been handled.
   */
  int rxBufPtr;
  
  /**
   * Write buffer.
   */
  unsigned char txBuffer[TCP_BUFFER_SIZE];
  
  /**
   * Number of bytes currently in the write buffer.
   */
  int txBufSize;
  
  /**
   * Contains extra data necessary to represent the state for a client.
   */
  void *extraData;
  
} tcpClient_t;

/**
 * TCP server state.
 */
typedef struct {
  
  /**
   * File descriptor for listening for incoming connections.
   */
  int listenDesc;
  
  /**
   * List of clients currently connected to the server.
   */
  tcpClient_t **clients;
  
  /**
   * Number of elements in clients. Not all of these may be in use.
   */
  int capacity;
  
  /**
   * Name for the server, should be either "debug" or "application". Used in
   * log messages.
   */
  const char *access;
  
  /**
   * When not null, this is called when a client state structure is allocated.
   */
  tcpServer_extraData onAlloc;
  
  /**
   * When not null, this is called when a client state structure is freed.
   */
  tcpServer_extraData onFree;
  
} tcpServer_t;

/**
 * Tries to open a TCP server socket at the given port. Returns null if
 * something goes wrong. Otherwise, returns a pointer to the newly allocated
 * server state structure. access should be "debug" or "application". onAlloc
 * and onFree are called when a client state structure is allocated or freed.
 */
tcpServer_t *tcpServer_open(int port, const char *access, tcpServer_extraData onAlloc, tcpServer_extraData onFree);

/**
 * Tries to close the server specified by server, deallocates all memory, and
 * sets the pointer to the server structure to null.
 */
void tcpServer_close(tcpServer_t **server);

/**
 * Updates the server after a call to select_wait(). Accepts new incoming
 * connections and reads data from clients into our buffer where applicable.
 */
int tcpServer_update(tcpServer_t *server);

/**
 * Used for iterating over client IDs which resolve to established connections.
 * Initialize by calling with clientID -1. This will return -1 when there are
 * no further clients.
 */
int tcpServer_nextClient(tcpServer_t *server, int clientID);

/**
 * Pulls a byte from the receive buffer for the specified client. Returns -1 if
 * there are no bytes available, or the received byte otherwise.
 */
int tcpServer_receive(tcpServer_t *server, int clientID);

/**
 * Returns the extra data structure for the given client, or null if there is
 * none.
 */
void *tcpServer_getExtraData(tcpServer_t *server, int clientID);

/**
 * Sends byte b to the connection at index clientID.
 */
int tcpServer_send(tcpServer_t *server, int clientID, int b);

/**
 * Broadcasts byte b to all connected clients.
 */
int tcpServer_broadcast(tcpServer_t *server, int b);

/**
 * Sends null-terminated string s to the connection at index clientID.
 */
int tcpServer_sendStr(tcpServer_t *server, int clientID, const unsigned char *s);

/**
 * Broadcasts null-terminated string s to all connected clients.
 */
int tcpServer_broadcastStr(tcpServer_t *server, const unsigned char *s);

/**
 * Flushes the write buffer for the specified client.
 */
int tcpServer_flushClient(tcpServer_t *server, int clientID);

/**
 * Write all buffered data to the clients.
 */
int tcpServer_flush(tcpServer_t *server);

#endif
