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

#include "Bus.h"

#include <stdio.h>

namespace Bus {

/**
 * Called in preparation for the first clock cycle. The return value should
 * be 0 for OK or -1 if the simulator should shut down.
 */
int Bus::init() {
	return 0;
}

/**
 * Runs a clock cycle, reading only from inputs and writing only to outputs.
 * This is called in an OpenMP accelerated loop, so it may be called from
 * any thread.
 */
void Bus::clock() {

	// Clock the dummy slave.
	if (unmapped.request) {
		unmapped.response.state = BSS_FAULT;
		unmapped.response.data = 0;
	}

	return;
}

/**
 * This should propagate the outputs of this entity to the inputs of other
 * entities and, if necessary, perform communication with things outside the
 * simulation. It is only called from the main thread. The return value
 * should be 0 for OK or -1 if the simulator should shut down.
 */
int Bus::synchronize() {

	// Acknowledge all idle requests, nack all non-idle requests.
	for (int i = 0; i < (int)masters.size(); i++) {
		masters[i]->request.ack = masters[i]->request.state == BQS_IDLE;
	}

	// Handle the current transfer.
	if (currentSlave) {

		// Forward the response state to the masters.
		currentResponse.state = currentSlave->response.state;

		// See if the slave is done.
		if (currentResponse.state != BSS_BUSY) {

			// Forward the rest of the response to the masters.
			currentResponse.master = currentSlave->response.master;
			currentResponse.data = currentSlave->response.data;
			currentSnoop.address = currentOrigAddr;
			currentSnoop.mask = currentRequest.mask;

			// Take the request away from the slave, so it doesn't start
			// processing it again.
			currentSlave->request = 0;
			currentSlave = 0;
		}

	} else {

		// Tell the masters that there is no response on the bus right now.
		currentResponse.state = BSS_IDLE;

	}

	// Look for a new bus request if we don't have a transfer right now.
	if (!currentSlave) {

		// Arbitrate in a round robin fashion. If the previous request was a locked
		// or burst request, start looking for requests at the current master,
		// otherwise start at the next one.

		// Do bus arbitration among the masters.
		int locked = 0;
		locked  = currentRequest.state == BQS_BURST_START;
		locked |= currentRequest.state == BQS_BURST_CONT;
		locked |= currentRequest.state == BQS_LOCK;
		if (!locked) {
			int startIdx = currentMasterIdx + 1;
			if (startIdx == (int)masters.size()) {
				startIdx = 0;
			}
			int masterIdx = startIdx;
			do {
				if (masters[masterIdx]->request.state != BQS_IDLE) {
					currentMasterIdx = masterIdx;
					break;
				}
				masterIdx++;
				if (masterIdx == (int)masters.size()) {
					masterIdx = 0;
				}
			} while (masterIdx != startIdx);
		}

		// Handle the current master's request.
		busMaster_t *master = masters[currentMasterIdx];
		if (master->request.state != BQS_IDLE) {

			// We have a request. Store it and acknowledge it.
			master->request.ack = 1;
			currentOrigAddr = master->request.address;
			currentRequest = master->request;

			// Find the slave for this request.
			currentSlave = demux(&currentRequest.address);

			// Forward the transfer to the slave.
			currentSlave->request = &currentRequest;
			currentSlave->response.state = BSS_BUSY;
			currentSlave->response.master = master;

		} else {

			// No request.
			currentRequest.state = BQS_IDLE;

		}

	}

	return 0;
}

/**
 * Same as synchronize, except that it's only called every n cycles.
 */
int Bus::occasional() {
	return 0;
}

/**
 * Called after the last synchronize() call in the simulation.
 */
void Bus::fini() {

}

/**
 * Finds the slave which is mapped to the given address and mutates the
 * address to put it in the slave address space.
 */
busSlave_t *Bus::demux(uint32_t *address) {
	for (int i = 0; i < (int)slaves.size(); i++) {
		int64_t ret = slaves[i].fun(slaves[i].slave, *address, slaves[i].param);
		if (ret >= 0) {
			*address = ret;
			return slaves[i].slave;
		}
	}
	return &unmapped;
}

/**
 * Creates a new bus controller.
 */
Bus::Bus(const char *name) : Entity(name), currentOrigAddr(0),
		currentSlave(0), currentMasterIdx(0)
{
	currentRequest.state = BQS_IDLE;
	currentResponse.state = BSS_IDLE;
	unmapped.request = 0;
	unmapped.response.state = BSS_IDLE;
}

/**
 * Destroys this bus controller.
 */
Bus::~Bus() {
}

/**
 * Adds a master to the bus. May not be called after clock() or
 * synchronize() are called.
 */
void Bus::addMaster(busMaster_t *master) {
	masters.push_back(master);
	master->response = &currentResponse;
	master->snoop = &currentSnoop;
}

/**
 * Adds a slave to the bus. May not be called after clock() or
 * synchronize() are called.
 */
void Bus::addSlave(busSlave_t *slave, busDemuxFunPtr_t demuxFun, void *param) {
	busDemuxEntry_t entry;
	entry.slave = slave;
	entry.fun = demuxFun;
	entry.param = param;
	slaves.push_back(entry);
}


} /* namespace Bus */

