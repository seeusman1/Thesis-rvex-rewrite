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
#include <unistd.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <netinet/tcp.h>

#include "tcpserv.h"
#include "select.h"

/**
 * Tries to open a TCP server socket at the given port. Returns null if
 * something goes wrong. Otherwise, returns a pointer to the newly allocated
 * server state structure.
 */
tcpServer_t *tcpServer_open(int port, const char *access, tcpServer_extraData onAlloc, tcpServer_extraData onFree) {
  tcpServer_t *server;
  struct sockaddr_in addr;
  int i;
  printf("Trying to open TCP server socket at port %d for %s access...\n", port, access);
  
  // Try to allocate memory for the server structure.
  server = (tcpServer_t*)malloc(sizeof(tcpServer_t));
  if (!server) {
    perror("Failed to allocate server memory structure");
    return 0;
  }
  memset((void*)server, 0, sizeof(tcpServer_t));
  server->clients = (tcpClient_t**)malloc(sizeof(tcpClient_t*) * 4);
  if (!server->clients) {
    perror("Failed to allocate server memory structure");
    tcpServer_close(&server);
    return 0;
  }
  memset((void*)server->clients, 0, sizeof(tcpClient_t*) * 4);
  server->capacity = 4;
  server->access = access;
  server->onAlloc = onAlloc;
  server->onFree = onFree;
  
  // Create the socket.
  server->listenDesc = socket(AF_INET, SOCK_STREAM, 0);
  if (server->listenDesc < 0) {
    perror("Failed to open socket");
    tcpServer_close(&server);
    return 0;
  }
  
  // Try to use SO_REUSEADDR to force binding to a port even if it's still in
  // TIME_WAIT.
  i = 1;
  setsockopt(server->listenDesc, SOL_SOCKET, SO_REUSEADDR, &i, sizeof(int));
  
  // Setup the socket address structure which we want to bind the socket to.
  memset((void*)&addr, 0, sizeof(addr));
  addr.sin_family = AF_INET;
  addr.sin_addr.s_addr = INADDR_ANY;
  addr.sin_port = htons(port);
  
  // Bind the socket to the requested port.
  if (bind(server->listenDesc, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
    perror("Failed to bind socket to port");
    printf("Maybe the server is already running?\n");
    tcpServer_close(&server);
    return 0;
  }
  
  // Start listening.
  if (listen(server->listenDesc, 5) < 0) {
    perror("Failed to start listening");
    tcpServer_close(&server);
    return 0;
  }
  
  // Register the listen descriptor with the select wrapper.
  if (select_register(server->listenDesc) < 0) {
    tcpServer_close(&server);
    return 0;
  }
  
  // Done.
  printf("Now listening on port %d.\n", port);
  return server;
  
}

/**
 * Tries to close the server specified by server, deallocates all memory, and
 * sets the pointer to the server structure to null.
 */
void tcpServer_close(tcpServer_t **server) {
  int i;
  
  // If an already deallocated server is specified, don't do anything.
  if (!server || !*server) {
    return;
  }
  
  // Close all open connections.
  for (i = 0; i < (*server)->capacity; i++) {
    tcpClient_t *client = (*server)->clients[i];
    if (client) {
      if (client->clientDesc > 0) {
        select_unregister(client->clientDesc);
        close(client->clientDesc);
        printf("Client ID %d forcefully closed (%s access).\n", i, (*server)->access);
      }
      if ((*server)->onFree) {
        (*server)->onFree(&(client->extraData));
      }
      free(client);
    }
  }
  
  // Close the listening socket.
  if ((*server)->listenDesc > 0) {
    select_unregister((*server)->listenDesc);
    close((*server)->listenDesc);
    printf("Server for %s access closed.\n", (*server)->access);
  }
  
  // Free the server state structure and set the pointer to it to null.
  if (server) free((*server)->clients);
  free(*server);
  *server = 0;
  
}

/**
 * Updates the server after a call to select_wait(). Accepts new incoming
 * connections and reads data from clients into our buffer where applicable.
 */
int tcpServer_update(tcpServer_t *server) {
  int i;
  
  // Accept new connections if necessary.
  if (select_isReady(server->listenDesc)) {
    struct sockaddr_in addr;
    unsigned int addrSize = sizeof(addr);
    int clientDesc;
    int f;
    uint32_t haddr;
    
    // Accept the incoming connection.
    clientDesc = accept(server->listenDesc, (struct sockaddr *)&addr, &addrSize);
    if (clientDesc < 0) {
      perror("Failed to accept incoming connection");
      return -1;
    }
    
    // Find an empty spot for the pointer to the client structure.
    f = -1;
    for (i = 0; i < server->capacity; i++) {
      if (!server->clients[i]) {
        f = i;
        break;
      }
    }
    
    // All spots are filled, so double capacity to make more spots.
    if (f == -1) {
      server->clients = (tcpClient_t**)realloc((void*)server->clients, sizeof(tcpClient_t*) * server->capacity * 2);
      if (!server->clients) {
        perror("Failed to reallocate memory");
        close(clientDesc);
        return -1;
      }
      memset((void*)(server->clients + server->capacity), 0, sizeof(tcpClient_t*) * server->capacity);
      f = server->capacity;
      server->capacity *= 2;
    }
    
    // Allocate memory for the client state.
    server->clients[f] = (tcpClient_t*)malloc(sizeof(tcpClient_t));
    if (!server->clients[f]) {
      perror("Failed to allocate memory for client state");
      close(clientDesc);
      return -1;
    }
    server->clients[f]->extraData = 0;
    if (server->onAlloc) {
      if (server->onAlloc(&(server->clients[f]->extraData)) < 0) {
        free(server->clients[f]);
        close(clientDesc);
        return -1;
      }
    }
    
    // Initialize the client state.
    server->clients[f]->clientDesc = clientDesc;
    server->clients[f]->rxBufSize = 0;
    server->clients[f]->rxBufPtr = 0;
    server->clients[f]->txBufSize = 0;
    
    // Register the new client with select_wait().
    if (select_register(clientDesc) < 0) {
      return -1;
    }
    
    // Report that we have a new connection.
    haddr = ntohl(addr.sin_addr.s_addr);
    printf(
      "Accepted connection from %d.%d.%d.%d for %s access, local ID = %d.\n",
      (haddr >> 24), (haddr >> 16) & 0xFF, (haddr >> 8) & 0xFF, haddr & 0xFF,
      server->access, f
    );
    
  }
  
  // Read from clients where applicable.
  for (i = 0; i < server->capacity; i++) {
    tcpClient_t *client = server->clients[i];
    
    // Skip nonexistant clients.
    if ((!client) || (client->clientDesc < 0)) {
      continue;
    }
    
    // Skip clients which are not ready or still have data in their buffer.
    if ((!select_isReady(client->clientDesc)) || (client->rxBufPtr < client->rxBufSize)) {
      continue;
    }
    
    // Reset the (fully drained) buffer.
    client->rxBufPtr = 0;
    
    // Read into the buffer.
    client->rxBufSize = read(client->clientDesc, (void*)client->rxBuffer, TCP_BUFFER_SIZE);
    if (client->rxBufSize < 0) {
      perror("Failed to read from client");
      return -1;
    }
    
    // Check if the client closed the connection.
    if (client->rxBufSize == 0) {
      
      // Close our end of the port and unregister it.
      close(client->clientDesc);
      select_unregister(client->clientDesc);
      
      // Free the client state memory structure.
      if (server->onFree) {
        server->onFree(&(client->extraData));
      }
      free(client);
      client = 0;
      server->clients[i] = 0;
      
      // Report that the client closed the connection.
      printf("Client ID %d closed connection (%s access).\n", i, server->access);
      
    } else {
      
      // We have a filled buffer, so we should unregister from the select call
      // because we can't handle any further reads until the buffer is
      // depleted.
      select_unregister(client->clientDesc);
      
    }
    
  }
  
  return 0;
  
}

/**
 * Used for iterating over client IDs which resolve to established connections.
 * Initialize by calling with clientID -1. This will return -1 when there are
 * no further clients.
 */
int tcpServer_nextClient(tcpServer_t *server, int clientID) {
  
  while (1) {
    
    // Try the next client ID.
    clientID++;
    
    // Return -1 to stop iterating if we have reached end of existing client
    // IDs.
    if (clientID >= server->capacity) {
      return -1;
    }
    
    // Return this client ID if it resolves to a connected client.
    if ((server->clients[clientID]) && (server->clients[clientID]->clientDesc >= 0)) {
      return clientID;
    }
    
  }
  
}

/**
 * Pulls a byte from the receive buffer for the specified client. Returns -1 if
 * there are no bytes available, or the received byte otherwise.
 */
int tcpServer_receive(tcpServer_t *server, int clientID) {
  
  // Make sure this client exists and is connected.
  if ((clientID >= server->capacity) || (clientID < 0)) {
    return -1;
  }
  if ((!server->clients[clientID]) || (server->clients[clientID]->clientDesc < 0)) {
    return -1;
  }
  
  // Make sure there is data available.
  if (server->clients[clientID]->rxBufPtr >= server->clients[clientID]->rxBufSize) {
    return -1;
  }
  
  // If the buffer contains exactly one byte, re-register with select_wait().
  if (server->clients[clientID]->rxBufPtr == server->clients[clientID]->rxBufSize - 1) {
    if (select_register(server->clients[clientID]->clientDesc) < 0) {
      return -1;
    }
  }
  
  // Pop the byte.
  return server->clients[clientID]->rxBuffer[server->clients[clientID]->rxBufPtr++];
  
}

/**
 * Returns the extra data structure for the given client, or null if there is
 * none.
 */
void *tcpServer_getExtraData(tcpServer_t *server, int clientID) {
  
  // Make sure this client exists and is connected.
  if ((clientID >= server->capacity) || (clientID < 0)) {
    return 0;
  }
  if ((!server->clients[clientID]) || (server->clients[clientID]->clientDesc < 0)) {
    return 0;
  }
  
  return server->clients[clientID]->extraData;
  
}

/**
 * Sends byte b to the connection at index id.
 */
int tcpServer_send(tcpServer_t *server, int clientID, int b) {
  
  // Make sure this client exists and is connected.
  if ((clientID >= server->capacity) || (clientID < 0)) {
    return -1;
  }
  if ((!server->clients[clientID]) || (server->clients[clientID]->clientDesc < 0)) {
    return -1;
  }
  
  // If the tx buffer is full, flush first.
  if (server->clients[clientID]->txBufSize >= TCP_BUFFER_SIZE) {
    if (tcpServer_flushClient(server, clientID) < 0) {
      return -1;
    }
  }
  
  // Append the byte to the buffer.
  server->clients[clientID]->txBuffer[server->clients[clientID]->txBufSize++] = b;
  
  return 0;
}

/**
 * Broadcasts byte b to all connected clients.
 */
int tcpServer_broadcast(tcpServer_t *server, int b) {
  int clientID;
  
  for (clientID = tcpServer_nextClient(server, -1); clientID >= 0; clientID = tcpServer_nextClient(server, clientID)) {
    if (tcpServer_send(server, clientID, b) < 0) {
      return -1;
    }
  }
  
  return 0;
}

/**
 * Sends null-terminated string s to the connection at index clientID.
 */
int tcpServer_sendStr(tcpServer_t *server, int clientID, const unsigned char *s) {
  
  // Make sure this client exists and is connected.
  if ((clientID >= server->capacity) || (clientID < 0)) {
    return -1;
  }
  if ((!server->clients[clientID]) || (server->clients[clientID]->clientDesc < 0)) {
    return -1;
  }
  
  while (*s) {
    
    // If the tx buffer is full, flush.
    if (server->clients[clientID]->txBufSize >= TCP_BUFFER_SIZE) {
      if (tcpServer_flushClient(server, clientID) < 0) {
        return -1;
      }
    }
    
    // Append the next byte to the buffer.
    server->clients[clientID]->txBuffer[server->clients[clientID]->txBufSize++] = *s++;
    
  }
  
  return 0;
}

/**
 * Broadcasts null-terminated string s to all connected clients.
 */
int tcpServer_broadcastStr(tcpServer_t *server, const unsigned char *s) {
  int clientID;
  
  for (clientID = tcpServer_nextClient(server, -1); clientID >= 0; clientID = tcpServer_nextClient(server, clientID)) {
    if (tcpServer_sendStr(server, clientID, s) < 0) {
      return -1;
    }
  }
  
  return 0;
}

/**
 * Flushes the write buffer for the specified client.
 */
int tcpServer_flushClient(tcpServer_t *server, int clientID) {
  tcpClient_t *client;
  int idx;
  
  // Make sure this client exists and is connected. If it isn't, that's fine;
  // it just means there's nothing to flush.
  if ((clientID >= server->capacity) || (clientID < 0)) {
    return 0;
  }
  client = server->clients[clientID];
  if ((!client) || (client->clientDesc < 0)) {
    return 0;
  }

  // Enable TCP_NODELAY to significantly increase local transmission speed
  int flag = 1;
  setsockopt(client->clientDesc, IPPROTO_TCP, TCP_NODELAY, (char *) &flag, sizeof(int));
  
  idx = 0;
  while (idx < client->txBufSize) {
    int num;
    
    // Write as much as possible to the socket.
    num = write(client->clientDesc, client->txBuffer + idx, client->txBufSize - idx);
    if (num < 0) {
      return -1;
    }
    
    // Keep track of how much we've sent already.
    idx += num;
    
  }
  
  // Reset the buffer.
  client->txBufSize = 0;

  // Disable TCP_NODELAY
  flag = 0;
  setsockopt(client->clientDesc, IPPROTO_TCP, TCP_NODELAY, (char *) &flag, sizeof(int));
  
  return 0;
}

/**
 * Write all buffered data to the clients.
 */
int tcpServer_flush(tcpServer_t *server) {
  int clientID;
  
  for (clientID = 0; clientID < server->capacity; clientID++) {
    if (tcpServer_flushClient(server, clientID) < 0) {
      return -1;
    }
  }
  
  return 0;
}


