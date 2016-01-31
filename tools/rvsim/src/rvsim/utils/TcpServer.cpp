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

#include "TcpServer.h"

#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <poll.h>

/**
 * Constructs a TCP server class instance.
 */
TcpServer::TcpServer(const char *name) :
	name(name),
	port(-1),
	listenDesc(-1)
{
}

/**
 * Opens the server on the specified TCP port. Returns 0 when successful or
 * -1 when an error occured. In this case, an error message will have been
 * printed to stderr. The server object should be destroyed after an error
 * to free up resources.
 */
int TcpServer::open(int port) {
	int i;
	struct sockaddr_in addr;

	printf("Trying to open TCP server '%s' socket at port %d...\n", name, port);

	// Create the server socket.
	listenDesc = socket(AF_INET, SOCK_STREAM, 0);
	if (listenDesc < 0) {
		perror("failed to create server socket");
		return -1;
	}

	// Use non-blocking I/O.
	i = fcntl(listenDesc, F_GETFL);
	if (i == -1) {
		perror("failed to read socket mode");
		return -1;
	}
	if (fcntl(listenDesc, F_SETFL, i | O_NONBLOCK) < 0) {
		perror("failed to set socket mode");
		return -1;
	}

	// Try to use SO_REUSEADDR to force binding to a port even if it's still in
	// TIME_WAIT.
	i = 1;
	setsockopt(listenDesc, SOL_SOCKET, SO_REUSEADDR, &i, sizeof(int));

	// Setup the socket address structure which we want to bind the socket to.
	memset((void*)&addr, 0, sizeof(addr));
	addr.sin_family = AF_INET;
	addr.sin_addr.s_addr = INADDR_ANY;
	addr.sin_port = htons(port);

	// Bind the socket to the requested port.
	if (bind(listenDesc, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
		perror("failed to bind socket to port");
		return -1;
	}

	// Start listening.
	if (listen(listenDesc, 5) < 0) {
		perror("failed to start listening");
		return -1;
	}

	// Save the port number.
	this->port = port;
	printf("Now listening on port %d.\n", port);

	return 0;
}

/**
 * Allocates the connection structure for the given file descriptor using
 * new.
 */
TcpServerConnection *TcpServer::allocConnection(
		struct sockaddr_in *addr, int desc)
{
	return new TcpServerConnection(this, addr, desc);
}

/**
 * Updates the TCP connection. Returns 0 when successful or -1 when an
 * error occured and the server was closed. In this case, an error message
 * will have been printed to stderr. The server object should be destroyed
 * after an error to free up resources.
 */
int TcpServer::update(void) {
    struct sockaddr_in addr;
    uint32_t haddr;
    unsigned int addrSize = sizeof(addr);
	int clientDesc, i;
	TcpServerConnection *connection = 0;

    // Look for a new connection.
	clientDesc = accept(listenDesc, (struct sockaddr *)&addr, &addrSize);
	if (clientDesc < 0) {
		if (errno != EAGAIN && errno != EWOULDBLOCK && errno != EINTR) {
			perror("failed to accept incoming connection");
			return -1;
		}
	} else {

		// Print that we've accepted a connection.
	    // Report that we have a new connection.
		haddr = ntohl(addr.sin_addr.s_addr);
		printf("TCP server '%s' accepted connection from %d.%d.%d.%d.\n",
			name, haddr>>24, haddr>>16 & 0xFF, haddr>>8 & 0xFF, haddr & 0xFF);

		// Use non-blocking I/O.
		i = fcntl(clientDesc, F_GETFL);
		if (i == -1) {
			perror("failed to read socket mode");
			return -1;
		}
		if (fcntl(clientDesc, F_SETFL, i | O_NONBLOCK) < 0) {
			perror("failed to set socket mode");
			return -1;
		}

		// Register the new connection.
		try {
			connection = allocConnection(&addr, clientDesc);
			connections.push_back(connection);
		} catch (bad_alloc &e) {
			fprintf(stderr, "Failed to allocate memory for connection.\n");
			close(clientDesc);
			return -1;
		}

	}

	// Update all connections. Erase a connection from the list if it was
	// closed remotely or an error occured.
	for (auto it = connections.begin(); it != connections.end(); it++) {
		if (!canUpdateClients()) {
			break;
		}
		if ((*it)->update() < 0) {

			// Print that we've lost a connection.
			haddr = ntohl((*it)->getAddr()->sin_addr.s_addr);
			printf("TCP server '%s' lost connection to %d.%d.%d.%d.\n",
				name, haddr>>24, haddr>>16 & 0xFF, haddr>>8 & 0xFF, haddr & 0xFF);

			// Release our reference.
			(*it)->close_conn();

			// Remove the connection from the list.
			it = connections.erase(it);

		}
	}

	return 0;
}

/**
 * Closes and destroys a TCP server.
 */
TcpServer::~TcpServer() {

	// Close all connections.
	for (auto it = connections.begin(); it != connections.end(); it++) {
		(*it)->close_conn();
	}
	connections.clear();

	// Close the listening socket.
	if (listenDesc >= 0) {
		close(listenDesc);
		listenDesc = -1;
		port = -1;
		printf("TCP server '%s' closed.\n", name);
	}

}

/**
 * Reads from any connection. Returns the number of bytes actually read or
 * 0 if an error occurred. If connection is nonzero, the pointer to the
 * connection which was read from is put there, and a new reference to the
 * connection is claimed. If If block is set, the function will not return
 * until all requested bytes have been read, no connections have any unread
 * data, or an error occured.
 */
int TcpServer::receiveAny(char *buffer, int buflen,
		TcpServerConnection **connection, int block)
{
	int count;
	for (auto it = connections.begin(); it != connections.end(); it++) {
		count = (*it)->receive(buffer, buflen, 0);
		if (count == 0) {
			continue;
		}
		if (block) {
			buflen -= count;
			buffer += count;
			count += (*it)->receive(buffer, buflen, 1);
		}
		if (connection) {
			*connection = (*it)->claim();
		}
		return count;
	}
	if (connection) {
		*connection = 0;
	}
	return 0;
}

/**
 * Writes the given data to all clients. This is a blocking call.
 */
void TcpServer::broadcast(const char *buffer, int buflen) {
	for (auto it = connections.begin(); it != connections.end(); it++) {
		(*it)->transmit(buffer, buflen, 1);
	}
}

/**
 * Returns the name of the server.
 */
const char *TcpServer::getName() const {
	return name;
}

/**
 * Returns the port of the server.
 */
int TcpServer::getPort() const {
	return port;
}

/**
 * Constructs a TCP server connection class instance.
 */
TcpServerConnection::TcpServerConnection(const TcpServer *server,
		const struct sockaddr_in *addr, int desc) :
	refcount(1),
	server(server),
	addr(*addr),
	desc(desc)
{

	// Send packets immediately, don't buffer.
	int flag = 1;
	setsockopt(desc, IPPROTO_TCP, TCP_NODELAY, (char *) &flag, sizeof(int));

}

/**
 * Destroys the connection object.
 */
TcpServerConnection::~TcpServerConnection() {
}

/**
 * Updates the TCP connection. Returns 0 when successful or -1 when the port
 * was closed. If -1 is returned, the connection object should be destroyed.
 */
int TcpServerConnection::update(void) {
	return (desc < 0) ? -1 : 0;
}

/**
 * Reads from this connection. Returns the number of bytes actually read or
 * 0 if an error occurred or no data was available. If block is set, the
 * function will not return until all requested bytes have been read, the
 * port was closed, or an error occured.
 */
int TcpServerConnection::receive(char *buffer, int buflen, int block) {
	int count = 0;
	int result;
	struct pollfd p;

	// Nothing to do if the connection has already been closed.
	if (desc < 0) {
		return 0;
	}

	while (buflen) {
		result = read(desc, buffer, buflen);
		if (result < 0) {

			// Handle wild interrupts.
			if (errno == EINTR) {
				continue;
			}

			// Handle no data available at this time.
			if (errno == EAGAIN || errno == EWOULDBLOCK) {
				if (block) {

					// Blocking: wait for data to become available.
					p.events = POLLIN;
					p.revents = 0;
					p.fd = desc;
					poll(&p, 1, -1);

					// Try again.
					continue;

				} else {

					// Non-blocking: don't try again, return now.
					return count;

				}
			}

			// Handle actual errors.
			perror("failed to read from port");
			close(desc);
			desc = -1;
			return count;

		} else if (result == 0) {

			// Handle end-of-file, i.e. remote closed connection. Close our own
			// connection in reply and return 0.
			close(desc);
			desc = -1;
			return count;

		}

		// Handle received data.
		count += result;
		buflen -= result;
		buffer += result;

	}

	return count;
}

/**
 * Writes to this connection. Returns the number of bytes actually written
 * or 0 if an error occurred. If block is set, the function will not return
 * until all bytes have been sent, the port was closed, or an error occured.
 * The port will be flushed after this call.
 */
int TcpServerConnection::transmit(const char *buffer, int buflen, int block) {
	int count = 0;
	int result;
	struct pollfd p;

	// Nothing to do if the connection has already been closed.
	if (desc < 0) {
		return 0;
	}

	while (buflen) {
		result = write(desc, buffer, buflen);
		if (result < 0) {

			// Handle wild interrupts.
			if (errno == EINTR) {
				continue;
			}

			// Handle buffer full.
			if (errno == EAGAIN || errno == EWOULDBLOCK) {
				if (block) {

					// Blocking: wait for buffer to become available.
					p.events = POLLOUT;
					p.revents = 0;
					p.fd = desc;
					poll(&p, 1, -1);

					// Try again.
					continue;

				} else {

					// Non-blocking: don't try again, return now.
					return count;

				}
			}

			// Handle actual errors.
			perror("failed to write to port");
			close(desc);
			desc = -1;
			return count;

		} else if (result == 0) {

			// Handle end-of-file, i.e. remote closed connection. Close our own
			// connection in reply and return 0.
			close(desc);
			desc = -1;
			return count;

		}

		// Handle sent data.
		count += result;
		buflen -= result;
		buffer += result;

	}

	return count;
}

/**
 * Closes the connection from our end and releases a reference.
 */
void TcpServerConnection::close_conn() {

	// Close the connection.
	if (desc >= 0) {
		close(desc);
		desc = -1;
	}

	// Server reference is no longer valid.
	server = 0;

	// Release a reference.
	release();

}

/**
 * Claims a reference.
 */
TcpServerConnection *TcpServerConnection::claim() {
	refcount++;
	return this;
}

/**
 * Releases a reference.
 */
TcpServerConnection *TcpServerConnection::release() {
	refcount--;
	if (!refcount) {
		delete this;
	}
	return 0;
}

/**
 * Returns the TCP server associated with this connection. Returns 0 if the
 * connection is no longer open.
 */
const TcpServer *TcpServerConnection::getServer() const {
	return server;
}

/**
 * Returns the remote address.
 */
const struct sockaddr_in *TcpServerConnection::getAddr() const {
	return &addr;
}

