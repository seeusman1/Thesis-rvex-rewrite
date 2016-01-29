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

#ifndef HOST_RVSRV_TCPSERVER_H
#define HOST_RVSRV_TCPSERVER_H

#include <list>
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <netinet/tcp.h>

using namespace std;

class TcpServerConnection;

class TcpServer {
private:

	/**
	 * Name of the server for log messages.
	 */
	const char *name;

	/**
	 * The port we're listening on.
	 */
	int port;

	/**
	 * List of active client connections.
	 */
	list<TcpServerConnection*> connections;

	/**
	 * File descriptor for listening for incoming connections.
	 */
	int listenDesc;

protected:

	/**
	 * Allocates the connection structure for the given file descriptor using
	 * new.
	 */
	virtual TcpServerConnection *allocConnection(
			struct sockaddr_in *addr, int desc);

public:

	/**
	 * Constructs a TCP server class instance.
	 */
	TcpServer(const char *name);

	/**
	 * Opens the server on the specified TCP port. Returns 0 when successful or
	 * -1 when an error occured. In this case, an error message will have been
	 * printed to stderr. The server object should be destroyed after an error
	 * to free up resources.
	 */
	int open(int port);

	/**
	 * Updates the TCP connection. Returns 0 when successful or -1 when an
	 * error occured and the server was closed. In this case, an error message
	 * will have been printed to stderr. The server object should be destroyed
	 * after an error to free up resources.
	 */
	int update(void);

	/**
	 * Closes and destroys a TCP server.
	 */
	virtual ~TcpServer();

	/**
	 * Reads from any connection. Returns the number of bytes actually read or
	 * 0 if an error occurred. If connection is nonzero, the pointer to the
	 * connection which was read from is put there, and a new reference to the
	 * connection is claimed. If If block is set, the function will not return
	 * until all requested bytes have been read, no connections have any unread
	 * data, or an error occured.
	 */
	int receiveAny(char *buffer, int buflen, TcpServerConnection **connection,
			int block);

	/**
	 * Writes the given data to all clients. This is a blocking call.
	 */
	void broadcast(const char *buffer, int buflen);

	/**
	 * Returns the name of the server.
	 */
	const char *getName() const;

	/**
	 * Returns the port of the server.
	 */
	int getPort() const;

};

class TcpServerConnection {
	friend class TcpServer;

private:

	/**
	 * Reference counter;
	 */
	int refcount;

	/**
	 * Link to the TCP server which this connection belongs to.
	 */
	const TcpServer *server;

	/**
	 * Remote address.
	 */
	const struct sockaddr_in addr;

	/**
	 * File descriptor for the port.
	 */
	int desc;

protected:

	/**
	 * Constructs a TCP server connection class instance.
	 */
	TcpServerConnection(const TcpServer *server,
			const struct sockaddr_in *addr, int desc);

	/**
	 * Destroys the connection object.
	 */
	virtual ~TcpServerConnection();

	/**
	 * Updates the TCP connection. Returns 0 when successful or -1 when the port
	 * was closed. If -1 is returned, the connection object should be destroyed.
	 */
	virtual int update(void);

public:

	/**
	 * Reads from this connection. Returns the number of bytes actually read or
	 * 0 if an error occurred or no data was available. If block is set, the
	 * function will not return until all requested bytes have been read, the
	 * port was closed, or an error occured.
	 */
	int receive(char *buffer, int buflen, int block);

	/**
	 * Writes to this connection. Returns the number of bytes actually written
	 * or 0 if an error occurred. If block is set, the function will not return
	 * until all bytes have been sent, the port was closed, or an error occured.
	 * The port will be flushed after this call.
	 */
	int transmit(const char *buffer, int buflen, int block);

	/**
	 * Closes the connection from our end and releases a reference.
	 */
	void close_conn();

	/**
	 * Claims a reference.
	 */
	TcpServerConnection *claim();

	/**
	 * Releases a reference.
	 */
	TcpServerConnection *release();

	/**
	 * Returns the TCP server associated with this connection. Returns 0 if the
	 * connection is no longer open.
	 */
	const TcpServer *getServer() const;

	/**
	 * Returns the remote address.
	 */
	const struct sockaddr_in *getAddr() const;

};

#endif
