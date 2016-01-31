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

#include "DebugPort.h"

#include <stdio.h>

namespace Periph {

/**
 * Called in preparation for the first clock cycle. The return value should
	 * be 0 for OK or -1 if the simulator should shut down.
 */
int DebugPort::init() {
	return DebugServer::open(tcpPort);
}

/**
 * Runs a clock cycle, reading only from inputs and writing only to outputs.
 * This is called in an OpenMP accelerated loop, so it may be called from
 * any thread.
 */
void DebugPort::clock() {
	if (pending) {

		// Handle requests.
		if (request.ack) {
			if (requestCounter < pending->numWords) {

				// Handle burst bus behavior.
				if (requestCounter < 2) {
					request.state = Bus::BQS_BURST_START;
				} else {
					request.state = Bus::BQS_BURST_CONT;
				}

				// Set the address.
				request.address = pending->address + requestCounter*4;

				// Determine the direction and bytemask, and if it's a write,
				// set the data.
				if (pending->direction) {
					if (requestCounter == 0) {
						request.mask = pending->firstMask;
					} else if (requestCounter == pending->numWords - 1) {
						request.mask = pending->lastMask;
					} else {
						request.mask = 0xF;
					}
					request.data = pending->buffer[requestCounter];
				} else {
					request.mask = 0;
				}

				// Increment the request counter.
				requestCounter++;

			} else {

				// No request pending.
				request.state = Bus::BQS_IDLE;

			}
		}

		// Handle responses.
		if (response->master == (Bus::busMaster_t*)this) {
			if (response->state == Bus::BSS_OK) {

				// Save the response if this is a read.
				if (!pending->direction) {
					pending->buffer[responseCounter] = response->data;
				}

				// Increment the response counter.
				responseCounter++;

				// If we've had enough responses, reply to the debug client.
				if (responseCounter == pending->numWords) {
					finishBusAccess(AR_OK);
					pending = 0;
				}

			} else if (response->state == Bus::BSS_FAULT) {

				// Handle bus faults.
				pending->faultCode = response->data;
				finishBusAccess(AR_FAULT);
				pending = 0;

			}
		}

	} else {

		// No request pending.
		request.state = Bus::BQS_IDLE;

	}
}

/**
 * This should propagate the outputs of this entity to the inputs of other
 * entities and, if necessary, perform communication with things outside the
 * simulation. It is only called from the main thread. The return value
 * should be 0 for OK or -1 if the simulator should shut down.
 */
int DebugPort::synchronize() {
	return stopped ? -1 : 0;
}

/**
 * Same as synchronize, except that it's only called every n cycles.
 */
int DebugPort::occasional() {
	return DebugServer::update();
}

/**
 * Called after the last synchronize() call in the simulation.
 */
void DebugPort::fini() {
}

/**
 * Called when a debug client wants to access the bus or ROM.
 */
void DebugPort::handleAccess(pendingAccess_t *access) {
	if (access->type) {

		// ROM access is not supported.
		finishBusAccess(AR_ERROR);

	} else {

		// Pend the transfer.
		pending = access;
		requestCounter = 0;
		responseCounter = 0;


		/*for (int i = 0; i < access->numWords; i++) {
			uint32_t *d = &(test[(i + access->address/4) & 7]);

			if (access->direction) {

				// Write.
				uint8_t mask = 0xF;
				if (i == 0) {
					mask = access->firstMask;
				} else if (i == access->numWords - 1) {
					mask = access->lastMask;
				}
				if (mask == 0xF) {
					*d = access->buffer[i];
				} else {
					uint32_t bitmask = 0;
					if (mask & 1) bitmask |= 0x000000FF;
					if (mask & 2) bitmask |= 0x0000FF00;
					if (mask & 4) bitmask |= 0x00FF0000;
					if (mask & 8) bitmask |= 0xFF000000;
					*d &= ~bitmask;
					*d |= access->buffer[i] & bitmask;
				}

			} else {

				// Read.
				access->buffer[i] = *d;

			}

		}

		finishBusAccess(AR_OK);*/

	}
}

/**
 * Called when a debug client wants to stop the simulation.
 */
void DebugPort::handleStop() {
	stopped = 1;
}

/**
 * Constructs a debug port.
 */
DebugPort::DebugPort(const char *name, int tcpPort):
		Entity(name),
		DebugServer(name),
		tcpPort(tcpPort)
{
}

/**
 * Destroys the debug port.
 */
DebugPort::~DebugPort() {
}

} /* namespace Periph */
