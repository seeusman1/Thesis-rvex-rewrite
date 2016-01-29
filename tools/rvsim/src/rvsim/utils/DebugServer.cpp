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
					if (j >= sizeof(xmitCmdBuffer)) {
						j = snprintf(xmitCmdBuffer, sizeof(xmitCmdBuffer),
								"Error,CmdNameOverrun,CmdBufferOverrun;");
					}
					transmit(xmitCmdBuffer, j, 1);

				} else {

					// Handle the command.
					DebugServer *server = (DebugServer*)getServer();
					if (server) {
						xmitCmdCount = sizeof(xmitCmdBuffer);
						server->handleCommand(cmdName, params, xmitCmdBuffer,
								&xmitCmdCount);

						// Transmit the reply.
						transmit(xmitCmdBuffer, xmitCmdCount, 1);

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
void DebugServer::handleCommand(const char *cmdName, char *params,
		char *replyBuf, int *replyBufLen) {
	int replyBufSize = *replyBufLen;
	int rd, wr, ro;

	// Handle the stop command.
	if (!strcmp(cmdName, "Stop")) {
		handleStop();
		*replyBufLen = snprintf(replyBuf, replyBufSize, "OK,Stop;");
		return;
	}

	// Handle read/write/rom commands.
	rd = !strcmp(cmdName, "Read");
	wr = !strcmp(cmdName, "Write");
	ro = !strcmp(cmdName, "ROM");
	if (rd || wr || ro) {

		uint32_t addr, fault;
		int count, ret;

		// Try to scan the address and count.
		if (sscanf(params, "%8X,%d", &addr, &count) < 2) {
			*replyBufLen = snprintf(replyBuf, replyBufSize,
					"Error,%s,SyntaxError;", cmdName);
			return;
		}

		// Return an error if too much data is requested at once.
		if (count > 4096) {
			*replyBufLen = snprintf(replyBuf, replyBufSize,
					"Error,%s,AccessTooLarge;", cmdName);
			return;
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
			if (strlen(params) != count*2) {
				*replyBufLen = snprintf(replyBuf, replyBufSize,
						"Error,%s,DataSizeIncorrect;", cmdName);
				return;
			}

			// Read the data into the buffer.
			for (int i = 0; i < count; i++) {
				if (sscanf(params, "%2hhX", dataBuffer + i) < 1) {
					*replyBufLen = snprintf(replyBuf, replyBufSize,
							"Error,%s,SyntaxError;", cmdName);
					return;
				}
				params += 2;
			}

		}

		// Handle the command.
		if (ro) {
			ret = handleRomAccess(addr, dataBuffer, count);
		} else {
			ret = handleBusAccess(addr, dataBuffer, count, wr, &fault);
		}

		// Handle errors.
		if (ret < 0) {
			*replyBufLen = snprintf(replyBuf, replyBufSize,
					"Error,%s,SimulatorError;", cmdName);
			return;
		}

		// Handle bus faults.
		if (ret > 0) {
			*replyBufLen = snprintf(replyBuf, replyBufSize,
					"OK,%s,Fault,%08X,%d,%08X;", cmdName, addr, count, fault);
			return;
		}

		// Handle normal replies.
		*replyBufLen = snprintf(replyBuf, replyBufSize,
				"OK,%s,OK,%08X,%d;", cmdName, addr, count);

		// Append data to the reply if necessary.
		if (!wr) {
			int c;

			// Replace the command termination character with a comma.
			replyBuf[*replyBufLen-1] = ',';
			replyBuf += *replyBufLen;

			// Append the data.
			for (int i = 0; i < count; i++) {
				snprintf(replyBuf, replyBufSize - *replyBufLen,
						"%02hhX", dataBuffer[i]);
				*replyBufLen += 2;
				replyBuf += 2;
			}

			// Terminate the command again.
			*replyBuf++ = ';';
			*replyBuf++ = 0;
			*replyBufLen += 1;

		}

		return;

	}

	// Unknown command.
	*replyBufLen = snprintf(replyBuf, replyBufSize,
			"Error,%s,UnknownCommand;", cmdName);
	if (*replyBufLen >= replyBufSize) {
		*replyBufLen = snprintf(replyBuf, replyBufSize,
				"Error,CmdNameOverrun,UnknownCommand;");
	}

}


