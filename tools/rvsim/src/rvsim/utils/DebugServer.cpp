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

#include "DebugServer.h"

#include <string.h>
#include <cstdint>
#include <cstdio>
#include <cstdlib>

/**
 * Allocates the connection structure for the given file descriptor using
 * new.
 */
TcpServerConnection *DebugServer::allocConnection(
		struct sockaddr_in *addr, int desc)
{
	return new DebugServerConnection(this, addr, desc);
}

/**
 * Returns whether updating client connections is currently allowed. We
 * prevent this when a transfer is in progress, so we don't have our command
 * overwritten.
 */
int DebugServer::canUpdateClients() {
	return !pendingCommand.pending;
}

/**
 * Updates the TCP connection. Returns 0 when successful or -1 when the port
 * was closed. If -1 is returned, the connection object should be destroyed.
 */
int DebugServerConnection::update(void) {
	int count, i, j;
	int overrun;
	char c;
	char *cmdName, *params;

	// Update the parent class first.
	if (TcpServerConnection::update() < 0) {
		return -1;
	}

	while (1) {

		// Try to receive data from the client.
		count = receive(recvBuffer, sizeof(recvBuffer), 0);
		if (!count) {
			break;
		}

		// Handle the received bytes one by one.
		for (i = 0; i < count; i++) {
			c = recvBuffer[i];

			if ((c == ',') ||
				(c >= '0' && c <='9') ||
				(c >= 'a' && c <='z') ||
				(c >= 'A' && c <='Z'))
			{

				// Accepted character. Append to the command buffer if we have
				// room for it.
				if (recvCmdCount < MAX_DEBUG_COMMAND_SIZE) {
					recvCmdBuffer[recvCmdCount] = c;
				}
				recvCmdCount++;

			} else if (c == ';') {

				// Handle buffer overruns.
				overrun = recvCmdCount > MAX_DEBUG_COMMAND_SIZE;
				if (overrun) {
					recvCmdCount = MAX_DEBUG_COMMAND_SIZE;
				}

				// Null-terminate packet.
				recvCmdBuffer[recvCmdCount] = 0;

				// Look for the first comma to separate command name from
				// parameters.
				cmdName = recvCmdBuffer;
				params = recvCmdBuffer + recvCmdCount;

				for (j = 0; j < recvCmdCount; j++) {
					if (recvCmdBuffer[j] == ',') {
						recvCmdBuffer[j] = 0;
						params = recvCmdBuffer + j + 1;
						break;
					}
				}

				if (overrun) {

					// Send an error reply immediately if there was a buffer
					// overrun.
					j = snprintf(xmitCmdBuffer, sizeof(xmitCmdBuffer),
							"Error,%s,CmdBufferOverrun;", cmdName);
					if (j >= (int)sizeof(xmitCmdBuffer)) {
						j = snprintf(xmitCmdBuffer, sizeof(xmitCmdBuffer),
								"Error,CmdNameOverrun,CmdBufferOverrun;");
					}
					transmit(xmitCmdBuffer, j, 1);

				} else {

					// Handle the command.
					DebugServer *server = (DebugServer*)getServer();
					if (server) {
						xmitCmdCount = sizeof(xmitCmdBuffer);
						int ret = server->handleCommand(cmdName, params,
								xmitCmdBuffer, &xmitCmdCount, this);

						// Transmit the reply if the command has been handled.
						if (ret) {
							transmit(xmitCmdBuffer, xmitCmdCount, 1);
						}

					}

				}

				// Reset the receive buffer.
				recvCmdCount = 0;

			}

		}

	}

	return 0;
}

/**
 * Handles incoming commands. This should write a response to xmitCmdBuffer
 * and xmitCmdCount, which will then be sent by the caller.
 */
int DebugServer::handleCommand(const char *cmdName, char *params,
		char *replyBuf, int *replyBufLen, DebugServerConnection *replyTo) {
	int replyBufSize = *replyBufLen;
	int rd, wr, ro;

	// Handle the stop command.
	if (!strcmp(cmdName, "Stop")) {
		handleStop();
		*replyBufLen = snprintf(replyBuf, replyBufSize, "OK,Stop;");
		return 1;
	}

	// Handle read/write/rom commands.
	rd = !strcmp(cmdName, "Read");
	wr = !strcmp(cmdName, "Write");
	ro = !strcmp(cmdName, "ROM");
	if (rd || wr || ro) {

		uint32_t addr;
		int count;

		// Try to scan the address and count.
		if (sscanf(params, "%8X,%d", &addr, &count) < 2) {
			*replyBufLen = snprintf(replyBuf, replyBufSize,
					"Error,%s,SyntaxError;", cmdName);
			return 1;
		}

		// Return an error if too much data is requested at once.
		if (count > 4096) {
			*replyBufLen = snprintf(replyBuf, replyBufSize,
					"Error,%s,AccessTooLarge;", cmdName);
			return 1;
		}

		// Set up the trivial parts of the access structure.
		pendingAccess.address = addr & 0xFFFFFFFC;
		pendingAccess.buffer = dataBuffer;
		pendingAccess.numBytes = count;
		pendingAccess.direction = wr;
		pendingAccess.type = ro;
		pendingAccess.faultCode = 0;

		// Handle misaligned stuff.
		uint32_t start = addr;
		uint32_t end = addr + count;
		pendingAccess.numWords = ((end + 3) / 4) - (start / 4);
		switch (start & 3) {
		case 0: pendingAccess.firstMask = 0xF; break;
		case 1: pendingAccess.firstMask = 0x7; break;
		case 2: pendingAccess.firstMask = 0x3; break;
		case 3: pendingAccess.firstMask = 0x1; break;
		}
		switch (end & 3) {
		case 0: pendingAccess.lastMask = 0xF; break;
		case 1: pendingAccess.lastMask = 0x8; break;
		case 2: pendingAccess.lastMask = 0xC; break;
		case 3: pendingAccess.lastMask = 0xE; break;
		}
		if (pendingAccess.numWords == 1) {
			pendingAccess.firstMask &= pendingAccess.lastMask;
		}

		// Scan the data to be written if this is a write.
		if (wr) {

			// Scan to the start of the data.
			int cc = 0;
			while (*params) {
				if (*params++ == ',') {
					cc++;
					if (cc == 2) {
						break;
					}
				}
			}

			// Return an error if the byte count does not match the data length.
			if ((int)strlen(params) != count*2) {
				*replyBufLen = snprintf(replyBuf, replyBufSize,
						"Error,%s,DataSizeIncorrect;", cmdName);
				return 1;
			}

			// Read the data into the buffer.
			for (int i = 0; i < pendingAccess.numWords; i++) {
				uint8_t mask = 0xF;
				if (i == 0) {
					mask = pendingAccess.firstMask;
				} else if (i == pendingAccess.numWords - 1) {
					mask = pendingAccess.lastMask;
				}
				int sh = 0;
				int charCount = 8;
				const char *fmt = "%08X";
				if (mask != 0xF) {
					if (mask == 0) {
						printf("Something weird happened on line %d in file %s\n.",
								__LINE__, __FILE__);
						exit(1);
					}
					while ((mask & 1) == 0) {
						mask >>= 1;
						sh += 8;
					}
					switch (mask) {
					case 0x1: fmt = "%02X"; charCount = 2; break;
					case 0x3: fmt = "%04X"; charCount = 4; break;
					case 0x7: fmt = "%06X"; charCount = 6; break;
					default:
						printf("Something weird happened on line %d in file %s\n.",
								__LINE__, __FILE__);
						exit(1);
					}
				}
				uint32_t val;
				if (sscanf(params, fmt, &val) < 1) {
					*replyBufLen = snprintf(replyBuf, replyBufSize,
							"Error,%s,SyntaxError;", cmdName);
					return 1;
				}
				dataBuffer[i] = val << sh;
				params += charCount;
			}

		}

		// Handle the command.
		pendingCommand.pending = 1;
		pendingCommand.cmdName = cmdName;
		pendingCommand.params = params;
		pendingCommand.replyBuf = replyBuf;
		pendingCommand.replyBufSize = replyBufSize;
		pendingCommand.replyBufLength = 0;
		pendingCommand.replyTo = (DebugServerConnection*)replyTo->claim();
		handleAccess(&pendingAccess);
		return 0;

	}

	// Unknown command.
	*replyBufLen = snprintf(replyBuf, replyBufSize,
			"Error,%s,UnknownCommand;", cmdName);
	if (*replyBufLen >= replyBufSize) {
		*replyBufLen = snprintf(replyBuf, replyBufSize,
				"Error,CmdNameOverrun,UnknownCommand;");
	}
	return 1;

}

/**
 * Sends the reply of a pending bus access started by handleBusAccess().
 * Refer to handleBusAccess() for more info.
 */
void DebugServer::finishBusAccess(accessResult_t result) {

	if (result == AR_ERROR) {

		// Handle errors.
		pendingCommand.replyBufLength = snprintf(
				pendingCommand.replyBuf, pendingCommand.replyBufSize,
				"Error,%s,SimulatorError;", pendingCommand.cmdName);

	} else if (result == AR_FAULT) {

		// Handle bus faults.
		pendingCommand.replyBufLength = snprintf(
				pendingCommand.replyBuf, pendingCommand.replyBufSize,
				"OK,%s,Fault,%08X,%d,%08X;", pendingCommand.cmdName,
				pendingAccess.address, pendingAccess.numBytes,
				pendingAccess.faultCode);

	} else {

		// Handle normal replies.
		pendingCommand.replyBufLength = snprintf(
				pendingCommand.replyBuf, pendingCommand.replyBufSize,
				"OK,%s,OK,%08X,%d;", pendingCommand.cmdName,
				pendingAccess.address, pendingAccess.numBytes);

		// Append data to the reply if necessary.
		if (!pendingAccess.direction) {

			// Replace the command termination character with a comma.
			char *buf = pendingCommand.replyBuf;
			buf[pendingCommand.replyBufLength-1] = ',';
			buf += pendingCommand.replyBufLength;

			// Append the read data.
			for (int i = 0; i < pendingAccess.numWords; i++) {
				int charCount = 0;
				uint8_t mask = 0xF;
				if (i == 0) {
					mask = pendingAccess.firstMask;
				} else if (i == pendingAccess.numWords - 1) {
					mask = pendingAccess.lastMask;
				}
				uint32_t val = pendingAccess.buffer[i];
				const char *fmt = "%08X";
				if (mask != 0xF) {
					if (mask == 0) {
						printf("Something weird happened on line %d in file %s\n.",
								__LINE__, __FILE__);
						exit(1);
					}
					while ((mask & 1) == 0) {
						mask >>= 1;
						val >>= 8;
					}
					switch (mask) {
					case 0x1: fmt = "%02X"; val &= 0xFF; break;
					case 0x3: fmt = "%04X"; val &= 0xFFFF; break;
					case 0x7: fmt = "%06X"; val &= 0xFFFFFF; break;
					default:
						printf("Something weird happened on line %d in file %s\n.",
								__LINE__, __FILE__);
						exit(1);
					}
				}
				charCount = snprintf(buf,
						pendingCommand.replyBufSize -
							pendingCommand.replyBufLength,
						fmt, val);
				pendingCommand.replyBufLength += charCount;
				buf += charCount;
			}

			// Terminate the command again.
			*buf++ = ';';
			*buf++ = 0;
			pendingCommand.replyBufLength += 1;

		}

	}

	// Transmit the reply.
	pendingCommand.replyTo->transmit(
			pendingCommand.replyBuf, pendingCommand.replyBufLength, 1);

	// Release our reference.
	pendingCommand.replyTo = (DebugServerConnection*)pendingCommand.replyTo->release();
	pendingCommand.pending = 0;

}


