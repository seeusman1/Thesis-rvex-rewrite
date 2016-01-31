/**
 * r-VEX simulator.
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

#ifndef RVSIM_UTILS_DEBUGSERVER_H
#define RVSIM_UTILS_DEBUGSERVER_H

#include "TcpServer.h"
#include <inttypes.h>

#define MAX_DEBUG_COMMAND_SIZE 8448

class DebugServerConnection;

typedef struct {

	/**
	 * Start address.
	 */
	uint32_t address;

	/**
	 * Data buffer.
	 */
	uint32_t *buffer;

	/**
	 * Number of aligned 32-bit words to transfer. buffer starts at a word
	 * alignment point, so buffer is numWords in size.
	 */
	int numWords;

	/**
	 * Byte mask for the first transfer if this is a write.
	 */
	uint8_t firstMask;

	/**
	 * Byte mask for the last transfer if this is a write.
	 */
	uint8_t lastMask;

	/**
	 * The actual number of bytes requested.
	 */
	int numBytes;

	/**
	 * Transfer direction; 0 for read, 1 for write.
	 */
	int direction;

	/**
	 * Transfer type; 0 for bus, 1 for ROM.
	 */
	int type;

	/**
	 * Fault code.
	 */
	uint32_t faultCode;

} pendingAccess_t;

typedef struct {

	/**
	 * Nonzero if this pending bus access if valid, zero if it isn't.
	 */
	int pending;

	/**
	 * Command name.
	 */
	const char *cmdName;

	/**
	 * Command parameters.
	 */
	char *params;

	/**
	 * Buffer to write the reply to.
	 */
	char *replyBuf;

	/**
	 * Size of the reply buffer.
	 */
	int replyBufSize;

	/**
	 * Number of bytes in the reply buffer.
	 */
	int replyBufLength;

	/**
	 * The client connection which issued this command.
	 */
	DebugServerConnection *replyTo;

} pendingCommand_t;

typedef enum {
	AR_ERROR, AR_OK, AR_FAULT
} accessResult_t;

class DebugServer: public TcpServer {
	friend class DebugServerConnection;

private:

	/**
	 * Data buffer for bus and ROM accesses.
	 */
	uint32_t dataBuffer[1026];

	/**
	 * Contains pending command information.
	 */
	pendingCommand_t pendingCommand;

	/**
	 * Contains the pending bus access information between handleAccess() and
	 * finishBusAccess().
	 */
	pendingAccess_t pendingAccess;

protected:

	/**
	 * Allocates the connection structure for the given file descriptor using
	 * new.
	 */
	virtual TcpServerConnection *allocConnection(
			struct sockaddr_in *addr, int desc);

	/**
	 * Returns whether updating client connections is currently allowed. We
	 * prevent this when a transfer is in progress, so we don't have our command
	 * overwritten.
	 */
	virtual int canUpdateClients();

	/**
	 * Should implement what needs to happen when a bus or ROM access is
	 * requested by one of the clients. When the transfer is complete,
	 * finishBusAccess() must be called.
	 */
	virtual void handleAccess(pendingAccess_t *access) = 0;

	/**
	 * Sends the reply of a pending bus access started by handleBusAccess().
	 */
	void finishBusAccess(accessResult_t result);

	/**
	 * Should implement what needs to happen when a client requests the server
	 * be stopped.
	 */
	virtual void handleStop() = 0;

	/**
	 * Handles incoming commands. Returns 1 if a reply should be sent by the
	 * caller, or 0 if the callee will handle that later.
	 */
	virtual int handleCommand(const char *cmdName, char *params,
			char *replyBuf, int *replyBufLen, DebugServerConnection *replyTo);

public:

	/**
	 * Constructs an rvd debug server.
	 */
	DebugServer(const char *name) : TcpServer(name) {
		pendingCommand.pending = 0;
	};

	/**
	 * Destroys the server.
	 */
	virtual ~DebugServer() {};

};

class DebugServerConnection: TcpServerConnection {
	friend class DebugServer;

private:

	/**
	 * Constructs a TCP server connection class instance.
	 */
	DebugServerConnection(const TcpServer *server,
			const struct sockaddr_in *addr, int desc) :
				TcpServerConnection(server, addr, desc),
				recvCmdCount(0), xmitCmdCount(0) {}

	/**
	 * Destroys the connection object.
	 */
	virtual ~DebugServerConnection() {};

	/**
	 * Receive buffer.
	 */
	char recvBuffer[1024];

	/**
	 * Receive command buffer.
	 */
	char recvCmdBuffer[MAX_DEBUG_COMMAND_SIZE + 1];

	/**
	 * Current number of bytes in recvCmdBuffer.
	 */
	int recvCmdCount;

	/**
	 * Transmit command buffer.
	 */
	char xmitCmdBuffer[MAX_DEBUG_COMMAND_SIZE + 1];

	/**
	 * Current number of bytes in xmitCmdBuffer.
	 */
	int xmitCmdCount;

protected:

	/**
	 * Updates the TCP connection. Returns 0 when successful or -1 when the port
	 * was closed. If -1 is returned, the connection object should be destroyed.
	 */
	virtual int update(void);

};

#endif
